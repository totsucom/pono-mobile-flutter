import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

//クラスの作成に参考にしたページ
//https://qiita.com/sekitaka_1214/items/129f41c2fbb1dc05b5c3

//usersコレクションのドキュメント
class User {
  static String baseName = 'ユーザー';

  String displayName;
  String iconURL;
  bool administrator;
  DateTime createdAt;

  // コンストラクタ
  User(String displayName, String iconURL, this.administrator) {
    this.displayName = displayName ?? '';
    this.iconURL = iconURL ?? '';
  }

  User clone() {
    var user = User(this.displayName, this.iconURL, this.administrator);
    user.createdAt = this.createdAt;
    return user;
  }

  // コンストラクタ
  // FirestoreのMapからインスタンス化
  User.fromMap(Map<String, dynamic> map) {
    this.displayName = map[UserField.displayName] ?? '';
    this.iconURL = map[UserField.iconURL] ?? '';
    this.administrator = (map[UserField.administrator] ?? 0) == 1;

    // DartのDateに変換
    final originCreatedAt = map[UserField.createdAt];
    if (originCreatedAt is Timestamp) {
      this.createdAt = originCreatedAt.toDate();
    }
  }

  // Firestore用のMapに変換
  Map<String, dynamic> toMap() {
    return {
      UserField.displayName: this.displayName,
      UserField.iconURL: this.iconURL,
      UserField.administrator: this.administrator,
      UserField.createdAt: this.createdAt, // Dateはそのまま渡せる
    };
  }

  Widget getCircleAvatar() {
    if (this.iconURL == null || this.iconURL.length == 0) {
      return CircleAvatar(
        backgroundImage: AssetImage('images/user_image_64.png'),
        backgroundColor: Colors.black12,
      );
    } else {
      return CircleAvatar(
        backgroundImage: NetworkImage(this.iconURL),
        backgroundColor: Colors.transparent,
      );
    }
  }
}

//フィールド名のタイピングミスを防ぐ
class UserField {
  static const displayName = "displayName";
  static const iconURL = "iconURL";
  static const administrator = "administrator";
  static const createdAt = "createdAt";
}

class UserFieldCaption {
  static const displayName = "表示名";
  static const iconURL = "アイコン";
  static const administrator = "管理者";
  static const createdAt = "登録日";
}

//userIDとフィールドデータを保持する
class UserDocument {
  String documentId; // = userID
  User user;

  UserDocument(this.documentId, this.user);

  UserDocument clone() {
    return UserDocument(this.documentId, this.user.clone());
  }

  UserDocument.fromFirebaseUser(FirebaseUser user) {
    this.documentId = user.uid;
    this.user = User(user.displayName, user.photoUrl, false);
  }
}
