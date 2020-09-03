import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pono_problem_app/records/problem.dart';
import 'package:pono_problem_app/records/user.dart';
import 'package:pono_problem_app/records/user_datastore.dart';
import 'package:pono_problem_app/utils/menu_item.dart';
import 'package:pono_problem_app/utils/my_dialog.dart';
import 'package:pono_problem_app/utils/my_widget.dart';
import 'package:provider/provider.dart';
import '../globals.dart';
import '../my_theme.dart';
import '../signin.dart';

class _HomeAppBarPopupMenuItem {
  static const manageBasePicture = '壁写真の管理';
}

class Home extends StatefulWidget {
  Home({Key key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final GlobalKey<ScaffoldState> _drawerKey = GlobalKey<ScaffoldState>();
  Future<UserDocument> _quickLoginResult;
  //NetworkImage _avatarIcon;
  //String _loginMessage = '';

  //appBarのポップアップメニュー
  List<MenuItem<String>> _appBarPopupMenuItems = [
    MenuItem<String>(_HomeAppBarPopupMenuItem.manageBasePicture,
        title: _HomeAppBarPopupMenuItem.manageBasePicture,
        icon: Icon(Icons.image)),
  ];

  @override
  Widget build(BuildContext context) {
    debugPrint("home_routeのbuild()");

    //appBar左のアバターアイコン
    Widget iconButton;
    if (Globals.ponoUser == null) {
      iconButton = Text(''); //ログインしていない
    } else if (Globals.ponoUser.user.iconURL.length == 0) {
      //アバター未設定
      // TODO 未確認
      iconButton = IconButton(
          icon: Icon(Icons.person, size: 12),
          onPressed: () {
            _drawerKey.currentState.openDrawer();
          });
    } else {
      iconButton = IconButton(
          icon: CircleAvatar(
            backgroundImage: NetworkImage(Globals.ponoUser.user.iconURL),
            backgroundColor: Colors.transparent, // 背景色
            radius: 12, // 表示したいサイズの半径を指定
          ),
          onPressed: () {
            _drawerKey.currentState.openDrawer();
          });
    }

    //フローティングボタン
    Widget floatButton = (Globals.ponoUser == null)
        ? null
        : FloatingActionButton(
            child: Icon(Icons.add),
            onPressed: () {
              Navigator.of(context)
                  .pushNamed('/edit_problem/select_base_picture');
            },
          );

    //管理者メニューを表示するか
    bool adminMenu =
        (Globals.ponoUser != null && Globals.ponoUser.user.administrator);

    return Scaffold(
        key: _drawerKey,
        appBar: new AppBar(
          leading: iconButton,
          title: Text('ホーム'),
          centerTitle: true,
          actions: <Widget>[
            if (adminMenu)
              PopupMenuButton<String>(
                  onSelected: _handlePopupMenuSelected,
                  itemBuilder: (BuildContext context) => _appBarPopupMenuItems
                      .map((e) => e.toPopupMenuItem())
                      .toList()),
          ],
        ),
        drawer: _buildDrawer(context),
        body: FutureBuilder(
            future: _quickLoginResult, //クイックログイン待ち
            builder: (BuildContext context, future) {
              if (future == null || (!future.hasData && !future.hasError))
                return MyWidget.loading(context, 'ログイン中です...。');
              if (future.hasError) return _buildWelcome();
              return Text('デバッグで表示しない');
            }), //_buildBody(context),
        floatingActionButton: floatButton);
  }

  //管理者メニューが選択された
  void _handlePopupMenuSelected(String value) {
    switch (value) {
      case _HomeAppBarPopupMenuItem.manageBasePicture:
        Navigator.of(context).pushNamed('/manage_base_picture');
    }
  }

  //ログインできない場合にウェルカム画面
  Widget _buildWelcome() {
    return Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
          Flexible(
              child: Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Text('ようこそ', style: TextStyle(fontSize: 40.0)))),
          Flexible(
              child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  child: Text(
                      '認証方法を選んでください。スマートフォンがAndroidの場合はGoogle、iPoneの場合はAppleIDを選びます。'))),
          Flexible(
              child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: RaisedButton(
                    padding: EdgeInsets.all(20.0),
                    child: Text('Google\n(Android)',
                        style: TextStyle(fontSize: 18.0),
                        textAlign: TextAlign.center),
                    onPressed: () {
                      Globals.loginMethod = LoginMethod.Google;
                      Globals.saveSettings();
                      SignIn.regularSignIn();
                    },
                  ))),
          Flexible(
              child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: RaisedButton(
                    padding: EdgeInsets.all(20.0),
                    child: Text('AppleID\n(iPhone)',
                        style: TextStyle(fontSize: 18.0),
                        textAlign: TextAlign.center),
                    onPressed: () {
                      //TODO
                    },
                  ))),
        ]));
  }

  Widget _buildDrawer(BuildContext context) {
    var _city = '';
    if (Globals.ponoUser == null) return null;

    return Drawer(
      child: ListView(
        children: <Widget>[
          DrawerHeader(
            child: Row(children: <Widget>[
              CircleAvatar(
                backgroundImage: NetworkImage(Globals.ponoUser.user.iconURL),
                backgroundColor: Colors.white, // 背景色
                radius: 50, // 表示したいサイズの半径を指定
              ),
              Expanded(
                  child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(Globals.ponoUser.user.displayName,
                    style: TextStyle(color: Colors.white)),
              ))
            ]),
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
          ),
          ListTile(
            title: Text('ダークテーマを使用する'),
            trailing: Switch(
                value: Globals.darkTheme,
                onChanged: (value) {
                  setState(() {
                    Globals.darkTheme = value;
                  });
                  //テーマを反映
                  Provider.of<MyTheme>(context, listen: false)
                      .setDark(Globals.darkTheme);
                }),
          ),
          ListTile(
            title: Text('Honolulu'),
            onTap: () {
              setState(() => _city = 'Honolulu, HI');
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('Dallas'),
            onTap: () {
              setState(() => _city = 'Dallas, TX');
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('Seattle'),
            onTap: () {
              setState(() => _city = 'Seattle, WA');
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('Tokyo'),
            onTap: () {
              setState(() => _city = 'Tokyo, Japan');
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance.collection('problems').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return LinearProgressIndicator();
        return _buildList(context, snapshot.data.documents);
      },
    );
  }

  Widget _buildList(BuildContext context, List<DocumentSnapshot> snapshot) {
    return ListView(
      padding: const EdgeInsets.only(top: 20.0),
      children: snapshot.map((data) => _buildListItem(context, data)).toList(),
    );
  }

  Widget _buildListItem(BuildContext context, DocumentSnapshot snapshot) {
    final problemDoc = new ProblemDocument(
        snapshot.documentID, Problem.fromMap(snapshot.data));

    return Padding(
      key: ValueKey(problemDoc.documentId),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: ListTile(
          title: Text(problemDoc.problem.title),
          trailing: Text(problemDoc.problem.comment),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    //ログイン処理を開始,FutureBuilderで待つ
    _quickLoginResult = SignIn.initAndQuickSignIn();

    WidgetsBinding.instance.addPostFrameCallback((_) => afterBuild(context));
  }

  //ホーム画面のbuildが完了したときに呼び出される
  void afterBuild(context) async {
    //設定の読み込み
    //Globals.loadSettings().then((value) {
    //テーマを反映
    Provider.of<MyTheme>(context, listen: false).setDark(Globals.darkTheme);

    //ログイン処理
    //loginProcess();
    //});
  }

  Future<bool> loginFutureBuilder2() async {
    var completer = new Completer<bool>();

    return completer.future;
  }

  Future<UserDocument> loginFutureBuilder() async {
    var completer = new Completer<UserDocument>();

    if (Globals.ponoUser == null) {
      try {
        while (Globals.firebaseUser == null) {
          //ログインを試みる。サインアップもここで行われる
          if (Globals.loginMethod == LoginMethod.Google) {
            debugPrint('googleログインを実行します');
            Globals.firebaseUser = await SignIn.handleGoogleSignIn();
          }

          //この時点でログインできてない場合は、ログインの選択肢を選んでもらう
          if (Globals.firebaseUser == null) {
            //現在の選択肢はgoogleのみ
            final items = [
              MyDialogItem('Google', icon: Icon(Icons.lightbulb_outline)),
            ];
            final selectResult = await MyDialog.selectItem(
                context, setState, items,
                caption: '認証方法の選択',
                label: 'iPhoneならApple、AndroidならGoogleから選択することが最も簡単です');

            if (selectResult != null &&
                selectResult.result == MyDialogResult.OK) {
              switch (selectResult.value) {
                case 1:
                  Globals.loginMethod = LoginMethod.Google;
              }
            }
          }
        }

        //PONOユーザーを取得する
        Globals.ponoUser =
            await UserDatastore.getUser(Globals.firebaseUser.uid);

        completer.complete(Globals.ponoUser);
      } catch (e) {
        completer.completeError(e.toString());
      }
    }

    return completer.future;
/*
          debugPrint('はじめてのログイン画面に遷移します');
          var user = await Navigator.of(context).pushNamed('/login');
          Globals.firebaseUser = user; //Globals.firebaseUserに直接代入するとエラー
        }

        Globals.currentLoginMethod = (Globals.firebaseUser != null)
            ? LoginMethod.Google
            : LoginMethod.None;
      } else {
        debugPrint('はじめてのログイン画面に遷移します');
        var user = await Navigator.of(context).pushNamed('/login');
        Globals.firebaseUser = user; //Globals.firebaseUserに直接代入するとエラー
        Globals.currentLoginMethod = (Globals.firebaseUser != null)
            ? LoginMethod.Google
            : LoginMethod.None;
        debugPrint('はじめてのログイン画面からホーム画面に返りました');
      }
    } else {
      //これはないやろなぁ
      debugPrint('既にログインしています ' + Globals.firebaseUser.displayName);
    }*/
  }
/*
  //ログイン処理
  //必要に応じてログイン画面への遷移やponoユーザーの登録を行う
  void loginProcess() async {
    if (Globals.firebaseUser == null) {
      debugPrint('記憶しているログイン方法 ' + Globals.loginMethod.toString());
      if (Globals.loginMethod == LoginMethod.Google) {
        debugPrint('googleログインを実行します');
        var user = (await SignIn.handleGoogleSignIn())['user'];
        Globals.firebaseUser = user; //Globals.firebaseUserに直接代入するとエラー
        Globals.currentLoginMethod = (Globals.firebaseUser != null)
            ? LoginMethod.Google
            : LoginMethod.None;
      } else {
        debugPrint('はじめてのログイン画面に遷移します');
        //awaitでログイン待ち。ユーザーが返される
        var user = await Navigator.of(context).pushNamed('/login');
        Globals.firebaseUser = user; //Globals.firebaseUserに直接代入するとエラー
        Globals.currentLoginMethod = (Globals.firebaseUser != null)
            ? LoginMethod.Google
            : LoginMethod.None;
        debugPrint('はじめてのログイン画面からホーム画面に返りました');
      }
    } else {
      //これはないやろなぁ
      debugPrint('既にログインしています ' + Globals.firebaseUser.displayName);
    }

    if (Globals.firebaseUser == null) {
      debugPrint('ログインできませんでした');
      setLoginStatus();
    } else {
      //ponoユーザーの取得
      final userDoc = await UserDatastore.getUser(Globals.firebaseUser.uid);
      Globals.ponoUser = userDoc.user;

      if (Globals.ponoUser != null) {
        //登録済みponoユーザー
        debugPrint('ログインできました ' + Globals.ponoUser.displayName);
        setLoginStatus();
      } else {
        debugPrint('新規ponoユーザーを登録します ' + Globals.firebaseUser.displayName);

        //Firebaseユーザーからponoユーザーにインポート
        Globals.ponoUser = new User(
            Globals.firebaseUser.displayName, Globals.firebaseUser.photoUrl);

        //エラーハンドリングのため、トランザクションを使用
        //ponoユーザーの新規登録
        Firestore.instance.runTransaction((transaction) async {
          UserDatastore.addUserT(
              transaction, Globals.firebaseUser.uid, Globals.ponoUser);
        }).then((value) {
          debugPrint('新規ユーザー登録が成功しました');
          //次回以降の為に、ログインした方法を記憶
          Globals.loginMethod = Globals.currentLoginMethod;
          setLoginStatus();
        }).catchError((err) {
          debugPrint('新規ユーザー登録で失敗しました！');
          Globals.ponoUser = null; //ユーザー情報を取り消す
          setLoginStatus('ユーザー登録に失敗しました！');
        });
      }
    }
  }

  void setLoginStatus([String errorMessage = '']) {
    setState(() {
      if (Globals.ponoUser != null) {
        this._loginMessage = 'ようこそ。 ${Globals.ponoUser.displayName} さん';
        this._avatarIcon = NetworkImage(Globals.ponoUser.iconURL);
      } else {
        this._loginMessage =
            (errorMessage.length == 0) ? 'ログインしていません' : errorMessage;
        this._avatarIcon = null;
      }
    });
  }
 */
}
