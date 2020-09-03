import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../globals.dart';
import '../signin.dart';

class Login extends StatefulWidget {
  Login({Key key}) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("login_routeのbuild()");

    return new Scaffold(
        resizeToAvoidBottomPadding: false, //キーボード入力時のBOTTOM OVERFLOWを回避
        appBar: new AppBar(
          automaticallyImplyLeading: false, //ヘッダー左の "←" Navigatorアイコンを隠す
          centerTitle: true,
          title: const Text('はじめてのログイン'),
        ),
        body: SingleChildScrollView(
            child: Center(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
              Flexible(
                // padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: RaisedButton(
                    child: Text('Googleアカウントでログイン'),
                    onPressed: () {
                      //ログイン方法をgoogleにする
                      Globals.loginMethod = LoginMethod.Google;
                      _trySignIn();
                    }),
              ),
              Flexible(
                //padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: RaisedButton(
                    child: Text('AppleIDでログイン'),
                    onPressed: () {
                      //ログイン方法をappleにする
                      //Globals.loginMethod = LoginMethod.Apple;
                      //Navigator.of(context).pop();
                    }),
              ),
            ]))));
  }

  void _trySignIn() async {
    await SignIn.regularSignIn();
    Navigator.of(context).pop();
  }

/*
  void googleNewSignIn() async {
    final result = await SignIn.handleGoogleSignIn();
    final FirebaseUser user = result['user'];
    if (user != null) {
      //ログインに成功した場合、呼び出し元のHome画面にユーザーを返す
      Globals.loginMethod = LoginMethod.Google;
      Navigator.of(context).pop(user);
    } else if (result.containsKey('exception')) {
      setState(() {
        //例外の場合はメッセージをそのまま表示
        _googleSignInErrorMessage = result['exception'];
      });
    } else {
      setState(() {
        _googleSignInErrorMessage = 'ログインできません';
      });
    }
  }
 */
}
