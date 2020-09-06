/*
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
import '../authentication.dart';

class Login extends StatefulWidget {
  Login({Key key}) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  Future<bool> _regularAuthResult;
  final _displayNameTextEdit = TextEditingController();
  var _iconUrl = '';

  @override
  void initState() {
    super.initState();

    //ログイン処理を開始,FutureBuilderで待つ
    _regularAuthResult = _regularAuthentication();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("login_routeのbuild()");
    return Scaffold(
      appBar: new AppBar(
        title: Text('アカウント作成'),
        centerTitle: true,
      ),
      body: FutureBuilder(
          future: _regularAuthResult, //ログイン待ち
          builder: (BuildContext context, future) {
            if (future == null || (!future.hasData && !future.hasError))
              return MyWidget.loading(context, '認証／ログイン中です...。');
            if (future.hasError) {
              //失敗した場合はHomeに強制送還（これでいい？）
              Navigator.of(context).pop();
            }
            if (Globals.ponoUser == null) {
              //失敗した場合はHomeに強制送還（これでいい？）
              Navigator.of(context).pop();
            }
            return _buildBody(context);
          }), //_buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    //この時点で認証は成功。ponoUserにも読み込んだ値か、新規作成した値が入っている

    //アバターアイコン
    Widget icon;
    if (_iconUrl.length == 0) {
      icon = Icon(Icons.person, size: 12);
    } else {
      icon = CircleAvatar(
        backgroundImage: NetworkImage(Globals.ponoUser.data.iconURL),
        backgroundColor: Colors.transparent, // 背景色
        radius: 12, // 表示したいサイズの半径を指定
      );
    }
    return Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
              Text('必要に応じて変更してください。これは後からでも変更できます。'),
              TextField(
                controller: _displayNameTextEdit,
                decoration: InputDecoration(labelText: "表示名"),
              ),
              ListTile(leading: icon)
            ])));
  }

  //レギュラー認証とログイン
  //関数は認証さえできていれば成功を返す
  Future<bool> _regularAuthentication() async {
    var completer = new Completer<bool>();

    debugPrint('デバッグ用に 2秒 待つ');
    await new Future.delayed(new Duration(seconds: 2));

    debugPrint('設定された認証タイプ ' + Globals.authMethod.toString());
    bool login = false;

    try {
      if (Globals.firebaseUser != null) {
        debugPrint('認証済み');
        //認証さえできればtrueを返す
        completer.complete(true);
        login = true;
      } else {
        bool done = false;
        if (Globals.authMethod == AuthMethod.Google) {
          debugPrint('google認証を実行');
          Globals.firebaseUser = await Authentication.handleGoogleAuth();
          done = true;
        }

        if (!done) {
          debugPrint('認証は実施されませんでした');
          completer.completeError('認証は実施されませんでした');
        } else {
          if (Globals.firebaseUser == null) {
            debugPrint('認証失敗');
            completer.completeError('認証失敗');
          } else {
            debugPrint('認証成功');
            //認証さえできればtrueを返す
            completer.complete(true);
            login = true;
          }
        }
      }
    } catch (e) {
      completer.completeError('認証中の例外: ' + e.toString());
      login = false;
      Globals.firebaseUser = null;
      Globals.ponoUser = null;
    }

    if (login) {
      try {
        if (Globals.ponoUser != null &&
            Globals.ponoUser.docId != Globals.firebaseUser.uid) {
          //FirebaseユーザーとPONOユーザーが合致しない場合は、PONOユーザーをクリアする
          Globals.ponoUser = null;
        }

        if (Globals.ponoUser != null) {
          debugPrint('ログイン済み');
        } else {
          Globals.ponoUser =
              await UserDatastore.getUser(Globals.firebaseUser.uid);
          if (Globals.ponoUser == null)
            debugPrint('ログインできません');
          else
            debugPrint('ログインできました');
        }

        //PONOユーザーが存在しない場合は新規作成する
        if (Globals.ponoUser == null) {
          Globals.ponoUser =
              UserDocument.fromFirebaseUser(Globals.firebaseUser);
        }

        //この後アカウント編集に移るので、UIに値を渡しておく
        if (Globals.ponoUser != null) {
          _displayNameTextEdit.text = Globals.ponoUser.data.displayName;
          _iconUrl = Globals.ponoUser.data.iconURL;
        }
      } catch (e) {
        completer.completeError('ログイン中の例外: ' + e.toString());
        Globals.ponoUser = null;
      }
    }
    return completer.future;
  }
}
*/
