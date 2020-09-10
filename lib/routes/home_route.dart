import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pono_problem_app/records/base_picture.dart';
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

import 'manage_base_picture_route.dart';

class _HomeAppBarPopupMenuItem {
  static const manageBasePicture = BasePicture.baseName + 'の管理';
}

class Home extends StatefulWidget {
  Home({Key key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _authAppBarTitle = 'PONO課題アプリ';

  //認証、ログインを管理するストリーム
  //final _authSignInStream = StreamController<_AuthSignInResult>();
  final _auth = FirebaseAuth.instance;

  //現在の認証ソース。Noneはデバイス（スマホ）ユーザーでの認証を示す
  AuthMethod _authMethod = AuthMethod.None;

  //ドロワーやスナックバーで使うキー
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  //キーが準備できていないときにスナックバーを一時的に保管
  Widget _waitingSnackBar;

  //appBarのポップアップメニュー
  List<MenuItem<String>> _appBarPopupMenuItems = [
    MenuItem<String>(_HomeAppBarPopupMenuItem.manageBasePicture,
        title: _HomeAppBarPopupMenuItem.manageBasePicture,
        icon: Icon(Icons.image)),
  ];

  @override
  void dispose() {
    super.dispose();
    //_authSignInStream.close();
  }

  Future<FirebaseUser> _authenticationFuture;

  @override
  void initState() {
    super.initState();

    Globals.loadSettings().then((_) {
      if (Globals.authMethod == AuthMethod.Google) {
        // Google認証が指定されているので実行
        debugPrint('Google認証が指定されているので実行');
        _currentAuthMethod = AuthMethod.Google;
        Authentication.handleGoogleAuth();
      }
    });

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

    // Firebaseの認証ストリーム
    return StreamBuilder(
        stream: _auth.onAuthStateChanged,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            //認証中（最初はデフォルトでプラットフォーム認証が行われる）
            return Scaffold(
                appBar: AppBar(
                  title: Text(_authAppBarTitle),
                  centerTitle: true,
                ),
                body: MyWidget.loading(context, '認証中...。'));
          } else if (!snapshot.hasData) {
            // 認証できなかった
            // 通常はここに来ないはず。（Androidを使っている以上、Googleアカウントで
            // サインインしているから。
            return _buildTestAuth(context);
          } else {
            // 認証された
            FirebaseUser fbUser = snapshot.data;
            debugPrint('認証された ' +
                _currentAuthMethod.toString() +
                ' FirebaseUser = ${fbUser.uid} ${fbUser.displayName} ' +
                fbUser.toString());

            // Firestoreのユーザーストリーム
            return StreamBuilder(
                stream: UserDatastore.getUserStream(fbUser.uid),
                builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                  if (!snapshot.hasData) {
                    return Scaffold(
                        appBar: AppBar(
                          title: Text(_authAppBarTitle),
                          centerTitle: true,
                        ),
                        body: MyWidget.loading(context, 'ユーザーを取得中...。'));
                  } else {
                    if (snapshot.data.data == null) {
                      // PONOユーザーの実体が見つからない
                      return _buildNewUserView(context, fbUser);
                    } else {
                      // PONOユーザーの実体が見つかった
                      final User user = User.fromMap(snapshot.data.data);
                      final userDoc =
                          UserDocument(snapshot.data.documentID, user);
                      // ユーザーを記憶する
                      Globals.setCurrentUser(userDoc).then((bool changed) {
                        if (changed) {
                          debugPrint(Globals.isCurrentUserAdmin
                              ? '管理者です'
                              : '管理者ではありません');
                          setState(() {});
                        }
                      }).catchError((err) {});
                      return _buildMainScaffold(context, user);
                    }
                  }
                });
          }
        });
  }

  AuthMethod _currentAuthMethod = AuthMethod.None;

  // 認証ができなかったときに他の認証の選択肢を表示する
  Widget _buildTestAuth(BuildContext context) {
    String msg;
    switch (_currentAuthMethod) {
      case AuthMethod.None:
        msg = 'プラットフォーム認証に失敗しました。';
        break;
      case AuthMethod.Google:
        msg = 'Google認証に失敗しました。';
        break;
    }
    msg += '認証方法を選択してください。';

    return Scaffold(
      appBar: AppBar(
        title: Text(_authAppBarTitle),
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Text(msg),
          RaisedButton(
            child: Text('Google認証'),
            onPressed: () {
              _currentAuthMethod = AuthMethod.Google;
              Authentication.handleGoogleAuth(false, true).then((fbUser) {
                // Google認証が成功したので方法を記憶
                Globals.authMethod = AuthMethod.Google;
                Globals.saveSettings();
              });
            },
          )
        ],
      ),
    );
  }

  Widget _buildNewUserView(BuildContext context, FirebaseUser fbUser) {
    // 本来はアカウント選択用のウイジェットを表示するが、現状は選択肢が無いため
    // アカウント作成ページにジャンプする。

    // ビルド中にジャンプできないので別タスクから
    Future.delayed(Duration.zero).then((_) async {
      final args = EditAccountArgs.forNew(//_scaffoldKey,
          UserDocument(fbUser.uid, User.fromFirebaseUser(fbUser)));

      //アカウント作成画面に移動。スナックバーのウイジェットを受け取る
      final snackBar = await Navigator.of(context)
          .pushNamed('/edit_account', arguments: args);
      if (snackBar is Widget) {
        //スナックバーを表示できるならすぐに表示するが、そうでない場合は一時保管
        debugPrint('edit_accountからスナックバーウィジェットを受け取りました');
        if (_scaffoldKey.currentState != null) {
          debugPrint('スナックバーウィジェットを表示します');
          _scaffoldKey.currentState.showSnackBar(snackBar);
        } else {
          debugPrint('スナックバーウィジェットは一時保管します');
          _waitingSnackBar = snackBar;
        }
      }
    });
    //すぐに移動するのでほとんど表示されない
    return Scaffold(
        appBar: AppBar(
          title: Text(_authAppBarTitle),
          centerTitle: true,
        ),
        body: Text('アカウントを作成します...'));
  }

  Widget _buildMainScaffold(BuildContext context, User user) {
    //スナックバーが待機中であれば表示する
    if (_waitingSnackBar != null) {
      debugPrint('一時保管されたスナックバーウィジェットを表示してみたい');
      Future.delayed(Duration(milliseconds: 100)).then((_) {
        if (_scaffoldKey.currentState != null) {
          _scaffoldKey.currentState.showSnackBar(_waitingSnackBar);
          _waitingSnackBar = null;
        }
      });
    }

    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          leading: GestureDetector(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: MyWidget.getCircleAvatar(user.iconURL),
            ),
            onTap: () {
              _scaffoldKey.currentState.openDrawer();
            },
          ),
          title: Text('ホーム'),
          centerTitle: true,
          actions: <Widget>[
            if (Globals.isCurrentUserAdmin)
              PopupMenuButton<String>(
                  icon: Icon(
                    Icons.vpn_key,
                    color: Colors.yellow,
                  ),
                  onSelected: _handlePopupMenuSelected,
                  itemBuilder: (BuildContext context) => _appBarPopupMenuItems
                      .map((e) => e.toPopupMenuItem())
                      .toList()),
          ],
        ),
        drawer: _buildDrawer(context, user),
        body: Text('なんか'),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () {
            Navigator.of(context)
                .pushNamed('/edit_problem/select_base_picture');
          },
        ));
  }

  //管理者メニューが選択された
  void _handlePopupMenuSelected(String value) {
    switch (value) {
      case _HomeAppBarPopupMenuItem.manageBasePicture:
        Navigator.of(context).pushNamed('/manage_base_picture',
            arguments: ManageBasePictureArgs(_scaffoldKey));
    }
  }

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
  Widget _buildDrawer(BuildContext context, User user) {
    return Drawer(
      child: ListView(
        children: <Widget>[
          DrawerHeader(
            child: Row(children: <Widget>[
              Container(
                  width: 100,
                  height: 100,
                  child: MyWidget.getCircleAvatar(user.iconURL)),
              Expanded(
                  child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                    user.displayName +
                        (Globals.isCurrentUserAdmin ? '\n（管理者）' : ''),
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
            onTap: _handleEditAccount,
          ),
        ],
      ),
    );
  }

  //アカウントの編集
  void _handleEditAccount() async {
    final args = EditAccountArgs.forEdit(//_scaffoldKey,
        UserDocument(Globals.currentUserID, Globals.currentUser));

    //アカウント作成画面に移動。スナックバーのウイジェットを受け取る
    final snackBar =
        await Navigator.of(context).pushNamed('/edit_account', arguments: args);
    if (snackBar is Widget) {
      //_scaffoldKey.currentStateがnullでなかったら表示するようにしていたが、
      //そのパターンでもスナックバーが表示されないことがシミュレーターで見られたので
      //どの場合でも一旦保管して、_buildBodyから表示することにした。
      debugPrint('スナックバーウィジェットは一時保管します');
      _waitingSnackBar = snackBar;
    }
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
/*
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
  */
}

/*
class _AuthSignInResult {
  FirebaseUser fbUser;
  UserDocument appUser;
}
 */
