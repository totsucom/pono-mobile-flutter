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
  var _googleSignInErrorMessage = '';

  _LoginState() : super();

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
            child: ConstrainedBox(
                constraints: BoxConstraints(),
                child: Container(
                    padding: EdgeInsets.all(32.0),
                    child: new Column(children: <Widget>[
                      Container(
                        padding: EdgeInsets.all(8.0),
                        child: Text('PONO課題へのログインには、お使いのAndroidのgooge' +
                            'アカウントが使用されます。\n初めて使用される場合は' +
                            '下記ボタンをタップしてください。'),
                      ),
                      Container(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                        child: RaisedButton(
                            child: Text('現在使用中のgoogleアカウントを使用'),
                            onPressed: () {
                              googleNewSignIn();
                            }),
                      ),
                      Container(
                        padding: EdgeInsets.fromLTRB(16, 4, 16, 16),
                        child: Text(_googleSignInErrorMessage,
                            style: TextStyle(
                              color: Colors.red,
                            )),
                      ),
                      Container(
                        padding: EdgeInsets.all(8.0),
                        child: Text('PONO課題の現在のアカウントやこれまで作成した課題' +
                            'がある場合、これらを引き継いで、両方のデバイスから' +
                            'ログインできるようになります。\n' +
                            '下記から該当するボタンをタップしてください。'),
                      ),
                      Container(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
                        child: RaisedButton(
                            child: Text('AppleIDを入力して引き継ぐ'),
                            onPressed: () {
                              //tryLogin();
                            }),
                      ),
                      Container(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
                        child: RaisedButton(
                            child: Text('別のgoogleアカウントを入力して引き継ぐ'),
                            onPressed: () {
                              //tryLogin();
                            }),
                      ),
                    ])))));
  }

  @override
  void initState() {
    super.initState();
  }

  void googleNewSignIn() async {
    final result = await SignIn.handleGoogleSignIn();
    final FirebaseUser user = result['user'];
    if (user != null) {
      //ログインに成功した場合、呼び出し元のHome画面にユーザーを返す
      Globals.setLoginMethod(LoginMethod.Google);
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
}
