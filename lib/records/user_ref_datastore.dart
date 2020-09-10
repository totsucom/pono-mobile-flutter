/*
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:pono_problem_app/records/user.dart';
import 'package:pono_problem_app/records/user_datastore.dart';
import 'package:pono_problem_app/records/user_ref.dart';
import './user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

//userReferencesコレクションを扱うツール
class UserRefDatastore {
  static String getCollectionPath() {
    return "userReferences";
  }

  static String getDocumentPath(String documentId) {
    return "userReferences/$documentId";
  }

  // UserRefを追加する
  // UserRefが存在する場合は上書きしてしまうので、注意すること
  static Future<UserRefDocument> addUserRef(
      String uidOfFirebase, String userID) async {
    //var completer = new Completer<UserRefDocument>();
    //try {
    final Map map = UserRef.fromUserID(userID).toMap();
    map[UserRefField.createdAt] = FieldValue.serverTimestamp();
    Firestore.instance.document(getDocumentPath(uidOfFirebase)).setData(map);

    return UserRefDocument(uidOfFirebase, UserRef.fromMap(map));


  }

  // UserRefを取得する
  static Future<UserRefDocument> getUserRef(String uidOfFirebase) async {
    final documentSnapshot =
        await Firestore.instance.document(getDocumentPath(uidOfFirebase)).get();
    if (!documentSnapshot.exists) {
      debugPrint('ユーザー参照はヌルでした');
      return null; // nullを返すとFutureBuilderではexistにもerrorにもならないのでいつまでも待ちになる
    } else {
      final userRef = UserRef.fromMap(documentSnapshot.data);
      return UserRefDocument(documentSnapshot.documentID, userRef);
    }
  }

  // UserRefを取得するストリーム
  static Stream<DocumentSnapshot> getUserRefStream(String uidOfFirebase) {
    return Firestore.instance
        .document(getDocumentPath(uidOfFirebase))
        .snapshots();
  }


  // FirebaseUser から User を取得する
  // User が存在しない場合はnullを返す
  static Future<UserDocument> getUser(FirebaseUser firebaseUser) async {
    var completer = new Completer<UserDocument>();
    if (firebaseUser == null || firebaseUser.uid == null) {
      completer.complete(null);
      return completer.future;
    }
    try {
      DocumentSnapshot snapshot = await Firestore.instance
          .document(getDocumentPath(firebaseUser.uid))
          .get();
      if (!snapshot.exists) {
        // Firebase.uid に対応する　UserRef が存在しない
        completer.complete(null);
        return completer.future;
      }
      DocumentReference ref = snapshot.data[UserRefField.userRef];
      snapshot = await ref.get();
      if (!snapshot.exists) {
        // userRef の示す User が存在しない
        completer.complete(null);
        return completer.future;
      }
      completer.complete(
          UserDocument(snapshot.documentID, User.fromMap(snapshot.data)));
    } catch (e) {
      debugPrint('UserRefDatastore.getUser()で例外 ' + e.toString());
      //UserDatastore.getUser()の件があるので、例外でもnullを返す
      completer.complete(null);
    }
    return completer.future;
  }

  // UserRef を削除する
  static void deleteUserRef(String uidOfFirebase) {
    Firestore.instance.document(getDocumentPath(uidOfFirebase)).delete();
  }

  // UserID に対応する UserRef を削除する
  static void deleteUserRefsOf(String userID) {
    String userRef = UserDatastore.getDocumentPath(userID);
    Firestore.instance
        .collection(getCollectionPath())
        .where(UserRefField.userRef, isEqualTo: userRef)
        .getDocuments()
        .then((snapshot) {
      for (DocumentSnapshot ds in snapshot.documents) {
        ds.reference.delete();
      }
    });
  }
}
*/
