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
import 'package:pono_problem_app/records/user_ref.dart';
import 'package:pono_problem_app/records/user_ref_datastore.dart';
import 'package:pono_problem_app/routes/edit_account.dart';
import 'package:pono_problem_app/utils/menu_item.dart';
import 'package:pono_problem_app/utils/my_dialog.dart';
import 'package:pono_problem_app/utils/my_widget.dart';
import 'package:provider/provider.dart';
import '../globals.dart';
import '../my_theme.dart';
import '../authentication.dart';
import 'dart:math' as Math;

class _HomeAppBarPopupMenuItem {
  static const manageBasePicture = '壁写真の管理';
}

class Home extends StatefulWidget {
  Home({Key key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  //認証、ログインを管理するストリーム
  final _authSignInStream = StreamController<_AuthSignInResult>();

  final _auth = FirebaseAuth.instance;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _authorizing = false;

  //appBarのポップアップメニュー
  List<MenuItem<String>> _appBarPopupMenuItems = [
    MenuItem<String>(_HomeAppBarPopupMenuItem.manageBasePicture,
        title: _HomeAppBarPopupMenuItem.manageBasePicture,
        icon: Icon(Icons.image)),
  ];

  @override
  void dispose() {
    super.dispose();
    _authSignInStream.close();
  }

  Future<FirebaseUser> _authenticationFuture;

  @override
  void initState() {
    super.initState();
/*
    Future.delayed(Duration.zero).then((_) async {
      Globals.loadSettings().then((_) async {
        debugPrint('設定を読み込みました');

        if (Globals.authMethod == AuthMethod.None) {
          debugPrint('認証方法が設定されていません');

          final items = [
            MyDialogItem('Google', icon: Icon(Icons.gamepad)),
          ];
          MyDialogIntResult res;
          while (true) {
            res = await MyDialog.selectItem(context, setState, items,
                caption: '認証方法の選択', label: 'へいへい');
            if (res.result == MyDialogResult.OK) break;
          }
          switch (res.value) {
            case 1:
              debugPrint('Google認証が選択されました');
              Globals.authMethod = AuthMethod.Google;
              Globals.saveSettings();
          }
        }
        switch (Globals.authMethod) {
          case AuthMethod.Google:
            debugPrint('Google認証を開始します');
            _authenticationFuture = Authentication.google(_auth);
            break;
        }
      });
    });

 */

    WidgetsBinding.instance.addPostFrameCallback((_) => afterBuild(context));
  }

  //ホーム画面のbuildが完了したときに呼び出される
  void afterBuild(context) async {
    //テーマを反映
    Provider.of<MyTheme>(context, listen: false).setDark(Globals.darkTheme);
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("home_routeのbuild()");

    return StreamBuilder(
        stream: _auth.onAuthStateChanged,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            //認証中
            return Scaffold(body: MyWidget.loading(context, '認証中...。'));
          } else if (!snapshot.hasData) {
            //認証できなかったので認証候補を選択
            return Scaffold(body: Text('認証画面を表示'));
          } else {
            FirebaseUser fbUser = snapshot.data;
            debugPrint(
                '認証された FirebaseUser = ${fbUser.uid} ${fbUser.displayName}');

            return StreamBuilder(
                stream: UserRefDatastore.getUserRefStream(fbUser.uid),
                builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                  debugPrint(
                      'snapshot.hasData = ' + snapshot.hasData.toString());
                  debugPrint(
                      'snapshot.hasError = ' + snapshot.hasError.toString());

                  if (!snapshot.hasData) {
                    return Scaffold(
                        body: MyWidget.loading(context, 'ユーザー参照を取得中...。'));
                  } else {
                    if (snapshot.data.data == null) {
                      return Scaffold(
                          body: Column(children: <Widget>[
                        Text('ユーザーなし（参照無し）'),
                        RaisedButton(
                          child: Text('ユーザー追加'),
                          onPressed: () {
                            _addUser(fbUser);
                          },
                        )
                      ]));
                    } else {
                      UserRef userRef = UserRef.fromMap(snapshot.data.data);
                      return StreamBuilder(
                          stream: UserDatastore.getUserStream(userRef.userID),
                          builder: (context,
                              AsyncSnapshot<DocumentSnapshot> snapshot) {
                            if (!snapshot.hasData) {
                              return Scaffold(
                                  body: MyWidget.loading(
                                      context, 'ユーザーを取得中...。'));
                            } else {
                              if (snapshot.data.data == null) {
                                return Scaffold(
                                    body: Column(children: <Widget>[
                                  Text('ユーザーなし（実体無し）'),
                                  RaisedButton(
                                    child: Text('ユーザー追加'),
                                    onPressed: () {
                                      _addUser(fbUser);
                                    },
                                  )
                                ]));
                              } else {
                                User user = User.fromMap(snapshot.data.data);
                                return Scaffold(
                                    body: Text('ユーザー ' + user.displayName));
                              }
                            }
                          });
                    }
                  }
                });
          }
/*
            if (_authorizing == false) {
              //プラットフォームアカウント(Google限定???)で認証できた

            } else {
              //指示された認証ができた（このパターンは予定、未確認）
              _authorizing = false;
            }

            getUserTest2().then((value) {
              debugPrint('userRefの値 ' + value);
            });

            debugPrint('snapshot.data = ' + snapshot.data.toString());
            debugPrint('snapshot.data.displayName = ' + fbUser.displayName);
            debugPrint(
                'snapshot.data.providerId = ' + fbUser.runtimeType.toString());
            return Scaffold(body: Text('認証したよ'));
          }
 */
          //return _buildBody2(context);
        });
  }

  //ユーザーの追加
  _addUser(FirebaseUser fbUser) async {
    //別画面で入力、保存
    final args =
        EditAccountArgs.forNew(fbUser.uid, User.fromFirebaseUser(fbUser));
    Navigator.of(context).pushNamed('/edit_account', arguments: args);
/*
    final name = 'TEST-' + (Math.Random().nextInt(9999).toString());
    UserDatastore.addUser(User(name, '', false)).then((UserDocument userDoc) {
      UserRefDatastore.addUserRef(uid, userDoc.docId)
          .then((UserRefDocument refDoc) {
        debugPrint('ユーザー登録したよ $name');
      }).catchError((err) {
        debugPrint('参照の登録失敗');
      });
    }).catchError((err) {
      debugPrint('ユーザーの登録失敗');
    });
*/
  }

  //テスト
  Future<String> getUserTest2({String uid = 'XBdkoojwHWRciJ7R1h8Q'}) async {
    DocumentSnapshot snapshot;
    try {
      snapshot = await Firestore.instance.document("uids/$uid").get();
    } catch (e) {
      debugPrint('getUserTest()で例外 ' + e.toString());
      return null;
    }
    if (!snapshot.exists) return null;
    DocumentReference ref = snapshot.data['userRef'];
    DocumentSnapshot snapshot2 = await ref.get();
    if (!snapshot2.exists) return null;
    return snapshot2.data['displayName'];
  }

  /*
  Widget _buildBody2(BuildContext context) {
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
        (Globals.ponoUser != null && Globals.ponoUser.data.administrator);

    return StreamBuilder(
        stream: _authSignInStream.stream,
        builder:
            (BuildContext context, AsyncSnapshot<_AuthSignInResult> snapshot) {
          if (snapshot == null || (!snapshot.hasData && !snapshot.hasError)) {
            //処理待ち
            return Scaffold(body: MyWidget.loading(context, '認証／ログイン中です...。'));
          }
          if (snapshot.hasError) {
            //認証ができなかったので、認証方法を選択させる
            return Scaffold(body: _buildWelcome());
          }

          /*
           * 少なくとも認証ができた
           */

          Widget iconButton;
          _AuthSignInResult result = snapshot.data;
          Globals.firebaseUser = result.fbUser;
          Globals.ponoUser = result.appUser;

          if (result.appUser == null) {
            //ログインできていない⇒ユーザー登録画面に移動
            _handleNewAccount();
          } else {
            //appBar左のアバターアイコン
            if (Globals.ponoUser == null) {
              iconButton = Text(''); //ログインしていない
            } else if (Globals.ponoUser.data.iconURL.length == 0) {
              //アバター未設定
              iconButton = IconButton(
                icon: MyWidget.getCircleAvatar(Globals.ponoUser.data.iconURL),
                onPressed: () {
                  _scaffoldKey.currentState.openDrawer();
                },
              );
            } else {
              iconButton = IconButton(
                icon: MyWidget.getCircleAvatar(Globals.ponoUser.data.iconURL),
                onPressed: () {
                  _scaffoldKey.currentState.openDrawer();
                },
              );
            }
          }
          return Scaffold(
              key: _scaffoldKey,
              appBar: new AppBar(
                leading: iconButton,
                title: Text('ホーム'),
                centerTitle: true,
                actions: <Widget>[
                  if (adminMenu)
                    PopupMenuButton<String>(
                        onSelected: _handlePopupMenuSelected,
                        itemBuilder: (BuildContext context) =>
                            _appBarPopupMenuItems
                                .map((e) => e.toPopupMenuItem())
                                .toList()),
                ],
              ),
              drawer: _buildDrawer(context),
              body: Text('なんか'),
              floatingActionButton: floatButton);
        });
  }*/
/*
  //新しいアカウントを作成するために画面遷移する
  void _handleNewAccount() async {
    //build中に移動できないので、タイマーで非同期から実行
    Future.delayed(new Duration(milliseconds: 500)).then((_) async {
      //戻ってきたときに再認証したいので、awaitで待つ
      await Navigator.of(context)
          .pushNamed('/edit_account', arguments: EditAccountArgs(true));

      //streamにnullを設定することで、認証待ち状態(画面)に戻すことができる
      //FutureBuilderではこれができなかった
      _authSignInStream.sink.add(null);

      //最初のログイン処理を開始、結果をStreamBuilderに渡してる
      _initAndQuickSignIn().then((_AuthSignInResult result) {
        _authSignInStream.sink.add(result);
      }).catchError((err) {
        _authSignInStream.sink.addError(err.toString());
      });
    });
  }

 */

/*
  //管理者メニューが選択された
  void _handlePopupMenuSelected(String value) {
    switch (value) {
      case _HomeAppBarPopupMenuItem.manageBasePicture:
        Navigator.of(context).pushNamed('/manage_base_picture');
    }
  }

 */

/*
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
                      //Google認証で再ログイン処理
                      Globals.authMethod = AuthMethod.Google;

                      //2回目のログイン処理を開始、結果をStreamBuilderに渡してる
                      doRegularAuthentication();
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

 */
/*
  void doRegularAuthentication() {
    //streamにnullを設定することで、認証待ち状態(画面)に戻すことができる
    //FutureBuilderではこれができなかった
    _authSignInStream.sink.add(null);

    //2回目のログイン処理を開始、結果をStreamBuilderに渡してる
    _regularAuthentication().then((_AuthSignInResult result) {
      _authSignInStream.sink.add(result);
    }).catchError((err) {
      _authSignInStream.sink.addError(err.toString());
    });
  }
*/
  Widget _buildDrawer(BuildContext context) {
    var _city = '';
    if (Globals.ponoUser == null) return null;

    return Drawer(
      child: ListView(
        children: <Widget>[
          DrawerHeader(
            child: Row(children: <Widget>[
              Container(
                  width: 100,
                  height: 100,
                  child:
                      MyWidget.getCircleAvatar(Globals.ponoUser.data.iconURL)),
              Expanded(
                  child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(Globals.ponoUser.data.displayName,
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
            title: Text('ユーザーアカウント'),
            //onTap: _handleEditAccount,
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

  /*
  //アカウントの編集
  void _handleEditAccount() async {
    final userDoc = await Navigator.of(context)
        .pushNamed('/edit_account', arguments: EditAccountArgs(false));
    if (userDoc != null && userDoc is UserDocument) {
      debugPrint(Globals.ponoUser.data.displayName +
          ' to ' +
          userDoc.data.displayName);
      setState(() {
        Globals.ponoUser = userDoc;
      });
    }
  }
*/
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

  // Globalsパラメータを読み込む
  // Globals.authMethodに従って、クイック認証（画面表示なし）とログインを実行する
  static Future<_AuthSignInResult> _initAndQuickSignIn() async {
    var completer = new Completer<_AuthSignInResult>();

    debugPrint('_initAndQuickSignIn() 開始');

    // 設定を読み込む(ここが唯一)
    if (Globals.authMethod == null) {
      await Globals.loadSettings();
    }

    debugPrint('デバッグ用に 2秒 待つ');
    await new Future.delayed(new Duration(seconds: 2));

    debugPrint('設定された認証タイプ ' + Globals.authMethod.toString());

    if (Globals.authMethod == AuthMethod.None) {
      completer.completeError('認証方法が指定されていません');
      return completer.future;
    }

    /*
     * 認証
     */

    var result = _AuthSignInResult();
    try {
      // 各認証方法で対応
      if (Globals.authMethod == AuthMethod.Google) {
        debugPrint('google認証を実行');
        // サイレント
        result.fbUser = await Authentication.handleGoogleAuth(silentOnly: true);
      }
    } catch (e) {
      debugPrint('認証中の例外: ' + e.toString());
      completer.completeError('認証中の例外: ' + e.toString());
      return completer.future;
    }
    if (result.fbUser == null) {
      debugPrint('認証失敗');
      completer.completeError('認証失敗');
      return completer.future;
    } else {
      debugPrint('認証成功');
    }

    /*
     * ログイン
     */

    try {
      result.appUser = await UserDatastore.getUser(result.fbUser.uid);
    } catch (e) {
      debugPrint('ログイン中の例外: ' + e.toString());
      completer.completeError('ログイン中の例外: ' + e.toString());
      return completer.future;
    }
    if (result.appUser == null) {
      debugPrint('ログイン失敗');
    } else {
      debugPrint('ログイン成功');
    }

    // 認証さえ成功していれば、関数は値を返す
    completer.complete(result);
    return completer.future;
  }

  // Globals.authMethodに従って、認証とログインを実行する
  Future<_AuthSignInResult> _regularAuthentication() async {
    var completer = new Completer<_AuthSignInResult>();

    debugPrint('_regularAuthentication() 開始');

    debugPrint('デバッグ用に 2秒 待つ');
    await new Future.delayed(new Duration(seconds: 2));

    debugPrint('設定された認証タイプ ' + Globals.authMethod.toString());

    if (Globals.authMethod == AuthMethod.None) {
      completer.completeError('認証方法が指定されていません');
      return completer.future;
    }

    /*
     * 認証
     */

    var result = _AuthSignInResult();
    if (Globals.firebaseUser == null) {
      try {
        // 各認証方法で対応
        if (Globals.authMethod == AuthMethod.Google) {
          debugPrint('google認証を実行');
          // 非サイレント
          result.fbUser =
              await Authentication.handleGoogleAuth(silentOnly: false);
        }
      } catch (e) {
        debugPrint('認証中の例外: ' + e.toString());
        completer.completeError('認証中の例外: ' + e.toString());
        return completer.future;
      }
      if (result.fbUser == null) {
        debugPrint('認証失敗');
        completer.completeError('認証失敗');
        return completer.future;
      } else {
        debugPrint('認証成功');
      }
    } else {
      debugPrint('認証をスキップ');
      result.fbUser = Globals.firebaseUser;
    }

    /*
     * ログイン
     */

    try {
      result.appUser = await UserDatastore.getUser(result.fbUser.uid);
    } catch (e) {
      debugPrint('ログイン中の例外: ' + e.toString());
      completer.completeError('ログイン中の例外: ' + e.toString());
      return completer.future;
    }
    if (result.appUser == null) {
      debugPrint('ログイン失敗');
    } else {
      debugPrint('ログイン成功');
    }

    // 認証さえ成功していれば、関数は値を返す
    completer.complete(result);
    return completer.future;
  }
}

class _AuthSignInResult {
  FirebaseUser fbUser;
  UserDocument appUser;
}
