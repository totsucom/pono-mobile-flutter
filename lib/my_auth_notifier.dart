import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:pono_problem_app/records/user.dart';
import 'package:pono_problem_app/records/user_datastore.dart';

import 'globals.dart';

enum MyAuthNotifyReason {
  None,
  FBUserJoined,
  FBUserChanged,
  FBUserLost,
  UserCreated,
  UserDeleted
}

// 認証や権限監視クラス
class MyAuthNotifier extends ChangeNotifier {
  // Notifyの理由を返す。処理したらresetすること
  MyAuthNotifyReason _reason = MyAuthNotifyReason.None;
  MyAuthNotifyReason get reason => _reason;
  void resetReason() {
    _reason = MyAuthNotifyReason.None;
  }

  // 現在のFirebaseUserを返す
  FirebaseUser _firebaseUser;
  FirebaseUser get firebaseUser => _firebaseUser;

  // 現在のユーザーを返す
  UserDocument _curUserDoc;
  UserDocument get currentUserDocument => _curUserDoc;
  User get currentUser => (_curUserDoc == null) ? null : _curUserDoc.data;
  String get currentUserID => (_curUserDoc == null) ? null : _curUserDoc.docId;

  // 現在のユーザーの管理者権限を返す
  bool _admin = false;
  bool get isCurrentUserAdmin =>
      (_firebaseUser == null || _curUserDoc == null) ? false : _admin;

  StreamSubscription<FirebaseUser> _fbUserStreamSubscription;
  StreamSubscription<DocumentSnapshot> _userDocStreamSubscription;

  MyAuthNotifier() {
    _fbUserStreamSubscription = FirebaseAuth.instance.onAuthStateChanged
        .listen((FirebaseUser firebaseUser) async {
      if (_firebaseUser == null && firebaseUser != null) {
        // ユーザーが認証された
        var results = await Future.wait(<Future>[
          UserDatastore.getUser(firebaseUser.uid),
          _getAdmin(firebaseUser)
        ]);
        _firebaseUser = firebaseUser;
        _curUserDoc = results[0];
        _admin = results[1];
        _reason = MyAuthNotifyReason.FBUserJoined;
        notifyListeners();
        listenUser();
      } else if (_firebaseUser != null && firebaseUser == null) {
        // 認証ユーザーが無くなった
        _firebaseUser = null;
        _curUserDoc = null;
        _admin = false;
        _reason = MyAuthNotifyReason.FBUserLost;
        notifyListeners();
        listenUser();
      } else if (_firebaseUser != null &&
          firebaseUser != null &&
          _firebaseUser.uid != firebaseUser.uid) {
        // 認証ユーザーが変わった
        var results = await Future.wait(<Future>[
          UserDatastore.getUser(firebaseUser.uid),
          _getAdmin(firebaseUser)
        ]);
        _firebaseUser = firebaseUser;
        _curUserDoc = results[0];
        _admin = results[1];
        _reason = MyAuthNotifyReason.FBUserChanged;
        notifyListeners();
        listenUser();
      }
    });
  }

  //Firestore上のUserに対して監視する
  void listenUser() {
    if (_userDocStreamSubscription != null) {
      //前のリスナーを削除
      _userDocStreamSubscription.cancel();
      _userDocStreamSubscription = null;
    }
    if (_firebaseUser == null) return;

    _userDocStreamSubscription = UserDatastore.getUserStream(_firebaseUser.uid)
        .listen((DocumentSnapshot documentSnapshot) {
      if (_curUserDoc != null && documentSnapshot.data == null) {
        // ユーザーが削除された
        _curUserDoc = null;
        _reason = MyAuthNotifyReason.UserDeleted;
        notifyListeners();
      } else if (_curUserDoc == null && documentSnapshot.data != null) {
        // ユーザーが登録された
        _curUserDoc = UserDocument(
            documentSnapshot.documentID, User.fromMap(documentSnapshot.data));
        _reason = MyAuthNotifyReason.UserCreated;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    if (_userDocStreamSubscription != null) _userDocStreamSubscription.cancel();
    if (_fbUserStreamSubscription != null) _fbUserStreamSubscription.cancel();
    super.dispose();
  }

  static Future<bool> _getAdmin(FirebaseUser firebaseUser) async {
    try {
      IdTokenResult result = await firebaseUser.getIdToken(refresh: true);
      return (result.claims['admin'] == true);
    } catch (e) {
      return false;
    }
  }
}
