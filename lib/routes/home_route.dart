import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:pono_problem_app/records/problem.dart';
import 'package:pono_problem_app/records/problem_datastore.dart';
import 'package:pono_problem_app/records/user.dart';
import 'package:pono_problem_app/records/user_datastore.dart';
import 'package:pono_problem_app/utils/menu_item.dart';
import '../globals.dart';
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
  NetworkImage _avatarIcon;
  var _loginMessage = '';

  //appBarのポップアップメニュー
  List<MenuItem<String>> _appBarPopupMenuItems = [
    MenuItem<String>(_HomeAppBarPopupMenuItem.manageBasePicture,
        title: _HomeAppBarPopupMenuItem.manageBasePicture,
        icon: Icon(Icons.image)),
  ];

  @override
  Widget build(BuildContext context) {
    debugPrint("home_routeのbuild()");
    return Scaffold(
      appBar: new AppBar(
        leading: IconButton(
          icon: CircleAvatar(
            backgroundImage: _avatarIcon,
            backgroundColor: Colors.transparent, // 背景色
            radius: 16, // 表示したいサイズの半径を指定
          ),
          //onPressed: /* タップした時の処理 */,
        ),
        title: Text('ホーム'),
        centerTitle: true,
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: _handlePopupMenuSelected,
            itemBuilder: (BuildContext context) =>
                _appBarPopupMenuItems.map((e) => e.toPopupMenuItem()).toList(),
          )
        ],
      ),
      body: Text('デバッグで表示しない'), //_buildBody(context),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.of(context).pushNamed('/edit_problem/select_base_picture');
        },
      ),
    );
  }

  void _handlePopupMenuSelected(String value) {
    switch (value) {
      case _HomeAppBarPopupMenuItem.manageBasePicture:
        Navigator.of(context).pushNamed('/manage_base_picture');
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => afterBuild(context));
  }

  //ホーム画面のbuildが完了したときに呼び出される
  void afterBuild(context) async {
    Globals.loadSettings().then((value) {
      //設定の読み込みが完了してからログイン処理を行う
      loginProcess();
    });
  }

  //ログイン処理
  //必要に応じてログイン画面への遷移やponoユーザーの登録を行う
  void loginProcess() async {
    if (Globals.firebaseUser == null) {
      debugPrint('記憶しているログイン方法 ' + Globals.getLoginMethod().toString());
      if (Globals.getLoginMethod() == LoginMethod.Google) {
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
          Globals.setLoginMethod(Globals.currentLoginMethod);
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
        _loginMessage = 'ようこそ。 ${Globals.ponoUser.displayName} さん';
        _avatarIcon = NetworkImage(Globals.ponoUser.iconURL);
      } else {
        _loginMessage =
            (errorMessage.length == 0) ? 'ログインしていません' : errorMessage;
        _avatarIcon = null;
      }
    });
  }
}
