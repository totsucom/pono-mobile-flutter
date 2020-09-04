import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pono_problem_app/records/user.dart';
import 'package:pono_problem_app/records/user_datastore.dart';
import 'package:provider/provider.dart';

import 'globals.dart';
import 'my_theme.dart';

class Authentication {
  // googleログイン
  static Future<FirebaseUser> handleGoogleAuth(
      {bool silentOnly = false}) async {
    var completer = new Completer<FirebaseUser>();

    debugPrint('handleGoogleAuth() 認証開始');

    final googleSignIn = new GoogleSignIn();
    final auth = FirebaseAuth.instance;

    GoogleSignInAccount googleCurrentUser = googleSignIn.currentUser;
    try {
      if (googleCurrentUser == null) {
        googleCurrentUser = await googleSignIn.signInSilently();
        //debugPrint("サイレントログイン " + ((googleCurrentUser == null) ? '失敗' : '成功'));
      }
      if (googleCurrentUser == null && !silentOnly) {
        googleCurrentUser = await googleSignIn.signIn();
        //debugPrint("ログイン " + ((googleCurrentUser == null) ? '失敗' : '成功'));
      }
      if (googleCurrentUser == null) {
        //debugPrint('googleにログインできませんでした');
        completer.completeError('handleGoogleAuth() 認証失敗1');
        return completer.future;
      }

      //googleユーザーからアクセストークンを取得し、Firebaseユーザーを取得
      GoogleSignInAuthentication googleAuth =
          await googleCurrentUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.getCredential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final FirebaseUser user =
          (await auth.signInWithCredential(credential)).user;

      if (user == null) {
        completer.completeError('handleGoogleAuth() 認証失敗2');
        return completer.future;
      }

      completer.complete(user);
      return completer.future;
    } catch (e) {
      debugPrint("handleGoogleAuth()で例外 " + e.toString());
      completer.completeError(e.toString());
      return completer.future;
    }
  }
}
