import 'package:cloud_firestore/cloud_firestore.dart';

//クラスの作成に参考にしたページ
//https://qiita.com/sekitaka_1214/items/129f41c2fbb1dc05b5c3

//usersコレクションのドキュメント
class User {
  String displayName;
  String iconURL;
  DateTime createdAt;

  // コンストラクタ
  User(String displayName, String iconURL) {
    this.displayName = displayName;
    this.iconURL = iconURL;
  }

  // コンストラクタ
  // FirestoreのMapからインスタンス化
  User.fromMap(Map<String, dynamic> map) {
    this.displayName = map[UserField.displayName];
    this.iconURL = map[UserField.iconURL];

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
      UserField.createdAt: this.createdAt, // Dateはそのまま渡せる
    };
  }
}

//フィールド名のタイピングミスを防ぐ
class UserField {
  static const displayName = "displayName";
  static const iconURL = "iconURL";
  static const createdAt = "createdAt";
}

class UserFieldCaption {
  static const displayName = "名前";
  static const iconURL = "アイコン";
  static const createdAt = "登録日";
}

//userIDとフィールドデータを保持する
class UserDocument {
  String documentId; // = userID
  User user;

  UserDocument(this.documentId, this.user);
}
