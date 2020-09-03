import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pono_problem_app/records/user.dart';
import 'package:pono_problem_app/records/user_datastore.dart';

import 'globals.dart';

//ローカルにはインデックスで保存しているので、順番を変更しないこと！
enum LoginMethod { None, Email, Google }

class SignIn {
  //ログイン画面を表示しない、バックグラウンドログインを実行する
  //通常はこれで完了
  static Future<UserDocument> initAndQuickSignIn() async {
    var completer = new Completer<UserDocument>();

    //設定を読み込む(ここが唯一)
    if (Globals.loginMethod == null) {
      //何回呼んでもいけるけど...
      await Globals.loadSettings();
    }

    debugPrint('デバッグ用に 2秒 待つ');
    await new Future.delayed(new Duration(seconds: 2));

    try {
      if (Globals.ponoUser != null) {
        debugPrint('ponoUserはnullではありません');
        completer.complete(Globals.ponoUser);
      } else {
        debugPrint('設定されたログインタイプは ' + Globals.loginMethod.toString());

        if (Globals.firebaseUser == null) {
          if (Globals.loginMethod == LoginMethod.Google) {
            debugPrint('googleログインを実行します');
            Globals.firebaseUser =
                await SignIn.handleGoogleSignIn(silentOnly: true);
          }
        }
        if (Globals.firebaseUser == null) {
          debugPrint('ログインできません');
          completer.completeError('ログインできません');
        } else {
          //PONOユーザーを取得する
          Globals.ponoUser =
              await UserDatastore.getUser(Globals.firebaseUser.uid);
          if (Globals.ponoUser == null) {
            debugPrint('ユーザー情報を取得できません');
            completer.completeError('ユーザー情報を取得できません');
          } else {
            debugPrint('ユーザー情報を取得できました');
            completer.complete(Globals.ponoUser);
          }
        }
      }
    } catch (e) {
      completer.completeError('ログインで失敗しました\n' + e.toString());
    }
    return completer.future;
  }

  //はじめてのログイン。予め、Globals.loginMethodを設定しておくこと
  static Future<UserDocument> regularSignIn() async {
    var completer = new Completer<UserDocument>();

    debugPrint('デバッグ用に 2秒 待つ');
    await new Future.delayed(new Duration(seconds: 2));

    try {
      if (Globals.ponoUser != null) {
        debugPrint('ponoUserはnullではありません');
        completer.complete(Globals.ponoUser);
      } else {
        debugPrint('設定されたログインタイプは ' + Globals.loginMethod.toString());

        if (Globals.firebaseUser == null) {
          if (Globals.loginMethod == LoginMethod.Google) {
            debugPrint('googleログインを実行します');
            Globals.firebaseUser =
                await SignIn.handleGoogleSignIn(silentOnly: false);
          }
        }
        if (Globals.firebaseUser == null) {
          debugPrint('ログインできません');
          completer.completeError('ログインできません');
        } else {
          //PONOユーザーを取得する
          Globals.ponoUser =
              await UserDatastore.getUser(Globals.firebaseUser.uid);
          if (Globals.ponoUser == null) {
            debugPrint('ユーザー情報を取得できません');
            completer.completeError('ユーザー情報を取得できません');
          } else {
            debugPrint('ユーザー情報を取得できました');
            completer.complete(Globals.ponoUser);
          }
        }
      }
    } catch (e) {
      completer.completeError('ログインで失敗しました\n' + e.toString());
    }
    return completer.future;
  }

  //googleログイン
  static Future<FirebaseUser> handleGoogleSignIn(
      {bool silentOnly = false}) async {
    var completer = new Completer<FirebaseUser>();

    final googleSignIn = new GoogleSignIn();
    final auth = FirebaseAuth.instance;

    GoogleSignInAccount googleCurrentUser = googleSignIn.currentUser;
    try {
      if (googleCurrentUser == null) {
        googleCurrentUser = await googleSignIn.signInSilently();
        debugPrint("サイレントログイン " + ((googleCurrentUser == null) ? '失敗' : '成功'));
      }
      if (googleCurrentUser == null && !silentOnly) {
        googleCurrentUser = await googleSignIn.signIn();
        debugPrint("ログイン " + ((googleCurrentUser == null) ? '失敗' : '成功'));
      }
      if (googleCurrentUser == null) {
        debugPrint('googleにログインできませんでした');
        completer.completeError('googleにログインできませんでした');
      } else {
        //googleユーザーからアクセストークンを取得し、Firebaseユーザーを取得
        GoogleSignInAuthentication googleAuth =
            await googleCurrentUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.getCredential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final FirebaseUser user =
            (await auth.signInWithCredential(credential)).user;
        completer.complete(user);
      }
    } catch (e) {
      completer.completeError(e.toString());
      debugPrint("googleログイン処理で例外 " + e.toString());
    }

    return completer.future;
  }
}
