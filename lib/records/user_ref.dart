/*
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pono_problem_app/records/user_datastore.dart';

//userReferenceコレクションのドキュメント
class UserRef {
  DocumentReference userRef; // Usersコレクションへの参照
  String userID; // UserのDocumentID
  DateTime createdAt;

  // コンストラクタ
  //UserRef(this.userRef);

  // コンストラクタ
  UserRef.fromUserID(this.userID) {
    this.userRef =
        Firestore.instance.document(UserDatastore.getDocumentPath(userID));
  }

  // コンストラクタ
  // FirestoreのMapからインスタンス化
  UserRef.fromMap(Map<String, dynamic> map) {
    this.userRef = map[UserRefField.userRef] ?? '';
    this.userID = map[UserRefField.userID] ?? '';

    // DartのDateに変換
    final originCreatedAt = map[UserRefField.createdAt];
    if (originCreatedAt is Timestamp) {
      this.createdAt = originCreatedAt.toDate();
    }
  }

  // Firestore用のMapに変換
  Map<String, dynamic> toMap() {
    return {
      UserRefField.userRef: this.userRef,
      UserRefField.userID: this.userID,
      UserRefField.createdAt: this.createdAt, // Dateはそのまま渡せる
    };
  }
}

//フィールド名のタイピングミスを防ぐ
class UserRefField {
  static const userRef = "userRef";
  static const userID = "userID";
  static const createdAt = "createdAt";
}

//userIDとフィールドデータを保持する
class UserRefDocument {
  String docId; // = Firebaseuser.uid
  UserRef data;

  UserRefDocument(this.docId, this.data);
}
*/
