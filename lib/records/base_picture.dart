import 'package:cloud_firestore/cloud_firestore.dart';

//クラスの作成に参考にしたページ
//https://qiita.com/sekitaka_1214/items/129f41c2fbb1dc05b5c3

//problemsコレクションのドキュメント
class BasePicture {
  //UIでの表記を統一するために宣言
  static const baseName = "ベース写真";

  String name;
  String pictureURL;
  String picturePath;
  String thumbnailURL;
  String userID;
  DateTime createdAt;

  // コンストラクタ
  BasePicture(this.name, this.picturePath, this.userID,
      {this.pictureURL = '', this.thumbnailURL = ''});

  // コンストラクタ
  // FirestoreのMapからインスタンス化
  BasePicture.fromMap(Map<String, dynamic> map) {
    this.name = map[BasePictureField.name];
    this.pictureURL = map[BasePictureField.pictureURL];
    this.picturePath = map[BasePictureField.picturePath];
    this.thumbnailURL = map[BasePictureField.thumbnailURL];
    this.userID = map[BasePictureField.userID];

    // DartのDateに変換
    final originCreatedAt = map[BasePictureField.createdAt];
    if (originCreatedAt is Timestamp) {
      this.createdAt = originCreatedAt.toDate();
    }
  }

  // Firestore用のMapに変換
  Map<String, dynamic> toMap() {
    return {
      BasePictureField.name: this.name,
      BasePictureField.pictureURL: this.pictureURL,
      BasePictureField.picturePath: this.picturePath,
      BasePictureField.thumbnailURL: this.thumbnailURL,
      BasePictureField.userID: this.userID,
      BasePictureField.createdAt: this.createdAt, // Dateはそのまま渡せる
    };
  }
}

//フィールド名のタイピングミスを防ぐ
class BasePictureField {
  static const name = "name";
  static const pictureURL = "pictureURL";
  static const picturePath = "picturePath";
  static const thumbnailURL = "thumbnailURL";
  static const userID = "userID";
  static const createdAt = "createdAt";
}

//UIでの表記を統一するために宣言
class BasePictureFieldCaption {
  static const name = "名称";
  static const pictureURL = "ベース写真";
  static const picturePath = "ベース写真";
  static const thumbnailURL = "サムネイル";
  static const userID = "登録者";
  static const createdAt = "登録日";
}

//documentIDとフィールドデータを保持する
class BasePictureDocument {
  String documentId;
  BasePicture basePicture;

  BasePictureDocument(this.documentId, this.basePicture);
}
