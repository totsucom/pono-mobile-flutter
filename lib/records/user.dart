import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

//クラスの作成に参考にしたページ
//https://qiita.com/sekitaka_1214/items/129f41c2fbb1dc05b5c3

/*
 * users コレクション内の UserドキュメントのIDは登録時に Firebaseuser.uid を
 * 使用せず、Firestore による自動生成を行う。
 *
 * Firebaseuser.uid と Usetドキュメントとの関連付けは、別途 userReferences
 * コレクションによって定義される。
 *
 * userReferences コレクション内の UserRefドキュメントのIDは Firebaseuser.uid
 * が割り当てられ、ref フィールドが該当する Userドキュメントを示す。
 * これにより、１つの Userドキュメントに複数の Firebase.uid が関連付けられるようになる。
 */

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

  User.fromFirebaseUser(FirebaseUser fbUser) {
    this.displayName = fbUser.displayName;
    this.iconURL = fbUser.photoUrl ?? '';
    this.administrator = false;
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
    debugPrint('User.toMap() が実行されたE');

    return {
      UserField.displayName: this.displayName,
      UserField.iconURL: this.iconURL,
      UserField.administrator: this.administrator,
      UserField.createdAt: this.createdAt, // Dateはそのまま渡せる
    };
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
  String docId; // = userID
  User data;

  UserDocument(this.docId, this.data);

  //UserDocument clone() {
  //  return UserDocument(this.docId, this.data.clone());
  //}

}
