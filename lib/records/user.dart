import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/*
 * users コレクション内の UserドキュメントのIDは登録時に FirebaseUser.uid を使用
 */

//usersコレクションのドキュメント
class User {
  static String baseName = 'ユーザー';

  String displayName;
  String iconURL;
  DateTime createdAt;
  DateTime updatedAt;

  // コンストラクタ
  User(String displayName, String iconURL) {
    this.displayName = displayName ?? '';
    this.iconURL = iconURL ?? '';
  }

  // FirebaseUserからインスタンス化
  User.fromFirebaseUser(FirebaseUser fbUser) {
    this.displayName = fbUser.displayName ?? '';
    this.iconURL = fbUser.photoUrl ?? '';
  }

  // クローンを作成
  User clone() {
    var user = User(this.displayName, this.iconURL);
    user.createdAt = this.createdAt;
    user.updatedAt = this.updatedAt;
    return user;
  }

  // コンストラクタ
  // FirestoreのMapからインスタンス化
  User.fromMap(Map<String, dynamic> map) {
    this.displayName = map[UserField.displayName] ?? '';
    this.iconURL = map[UserField.iconURL] ?? '';

    // DartのDateに変換
    var origin = map[UserField.createdAt];
    if (origin is Timestamp) this.createdAt = origin.toDate();
    origin = map[UserField.updatedAt];
    if (origin is Timestamp) this.updatedAt = origin.toDate();
  }

  // Firestore用のMapに変換
  Map<String, dynamic> toMap() {
    return {
      UserField.displayName: this.displayName,
      UserField.iconURL: this.iconURL,
      UserField.createdAt: this.createdAt, // Dateはそのまま渡せる
      UserField.updatedAt: this.updatedAt, // Dateはそのまま渡せる
    };
  }
}

//フィールド名のタイピングミスを防ぐ
class UserField {
  static const displayName = "displayName";
  static const iconURL = "iconURL";
  static const createdAt = "createdAt";
  static const updatedAt = "updatedAt";
}

class UserFieldCaption {
  static const displayName = "表示名";
  static const iconURL = "アイコン";
  static const createdAt = "登録日";
  static const updatedAt = "更新日";
}

//userIDとフィールドデータを保持する
class UserDocument {
  String docId; // = userID
  User data;

  UserDocument(this.docId, this.data);

  //UserDocument clone() {
  //  return UserDocument(this.docId, this.data.clone());
  //}

}
