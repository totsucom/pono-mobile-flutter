import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pono_problem_app/my_auth_notifier.dart';
import 'package:pono_problem_app/records/user.dart';
import 'package:pono_problem_app/records/user.dart';
import 'package:pono_problem_app/records/user.dart';
import 'package:pono_problem_app/records/user.dart';
import 'package:pono_problem_app/records/user.dart';
import 'package:pono_problem_app/records/user_ref.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'my_theme_notifier.dart';
import 'authentication.dart';

//※ enumアイテム名で設定に保存するので、名称変更しないこと
enum AuthMethod { None, Google }

class Globals {
  //ログイン結果（ユーザー情報）
  //static UserDocument ponoUser;

  //認証方法
  static AuthMethod authMethod = AuthMethod.None;

  //ダークテーマの取得と設定
  static bool darkTheme = false;

  //設定を読み込む
  //アプリの最初に呼び出そう
  static Future<bool> loadSettings() async {
    final _prefs = await SharedPreferences.getInstance();
    assert(_prefs != null);

    authMethod = AuthMethod.values.firstWhere((e) =>
        e.toString() ==
        (_prefs.getString("AuthMethod") ?? AuthMethod.None.toString()));
    darkTheme = _prefs.getBool("DarkTheme") ?? false;

    //TODO デバッグ
    authMethod = AuthMethod.None;

    return true;
  }

  //設定を保存する
  //自動保存されないので注意
  static Future<bool> saveSettings() async {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString("AuthMethod", authMethod.toString());
      prefs.setBool("DarkTheme", darkTheme);
    });
    return true;
  }

  /* 現在のユーザー情報を保持。 ファイル保存はされない */

/*
  static FirebaseUser _firebaseUser;
  static FirebaseUser get firebaseUser => _firebaseUser;

  static UserDocument _curUserDoc;
  static UserDocument get currentUserDocument => _curUserDoc;
  static User get currentUser =>
      (_curUserDoc == null) ? null : _curUserDoc.data;
  static String get currentUserID =>
      (_curUserDoc == null) ? null : _curUserDoc.docId;

  static bool _admin = false;
  static bool get isCurrentUserAdmin =>
      (_firebaseUser == null) ? false : _admin;

  // MyAuthNotifierから設定される
  static setCurrentUser(FirebaseUser fbUser,UserDocument userDoc, bool admin) {
    _firebaseUser=fbUser;
    _curUserDoc=userDoc;
    _admin=admin;
  }
*/
  /*// 認証・ログインが済んだらこれで登録
  // 結果を取得したいときは Globals.isCurrentUserAdmin を参照する。
  // .then(bool changed)
  static Future<bool> setCurrentUser(UserDocument userDoc) {
    var completer = new Completer<bool>();
    FirebaseAuth.instance.currentUser().then((FirebaseUser fbUser) {
      if (fbUser != null && fbUser.uid == userDoc.docId) {
        _firebaseUser = fbUser;
        _curUserDoc = userDoc;
        final prev = _admin;
        fbUser.getIdToken(refresh: true).then((IdTokenResult result) {
          if (result.claims['admin'] == true) _admin = true;
          completer.complete(prev != _admin);
        }).catchError((err) {
          _admin = false;
          completer.complete(prev != _admin);
        });
      } else {
        _firebaseUser = null;
        _curUserDoc = null;
        _admin = false;
        completer.completeError('カレントユーザーは存在しません');
      }
    }).catchError((err) {
      _firebaseUser = null;
      _curUserDoc = null;
      _admin = false;
      completer.completeError('カレントユーザーは存在しません');
    });
    return completer.future;
  }*/

  /*
  // 現在のユーザーのadmin情報を更新する
  // admin属性を持っている場合のみtrueを返す。その他はfalse
  static Future<bool> reloadAdmin() {
    var completer = new Completer<bool>();

    if (_firebaseUser == null) {
      _admin = false;
      completer.complete(false);
    } else {
      _firebaseUser.getIdToken().then((IdTokenResult result) {
        if (result.claims['admin'] == true) {
          _admin = true;
          completer.complete(true);
        } else {
          _admin = false;
          completer.complete(false);
        }
      });
      return completer.future;
    }
  }
   */

}
