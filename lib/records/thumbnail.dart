import 'package:cloud_firestore/cloud_firestore.dart';

//クラスの作成に参考にしたページ
//https://qiita.com/sekitaka_1214/items/129f41c2fbb1dc05b5c3

//thumbnailコレクションのドキュメント
//通常、元画像のpathをキーとして、
class Thumbnail {
  String originalPath; //Firebase storageのパス
  String originalURL;
  String thumbnailURL;
  DateTime createdAt;

  // コンストラクタ
  //サムネイルは Firebase FunctionsによってStorageに生成、Firestoreに登録されるので
  //このコンストラクタは出番なし
  Thumbnail(this.originalPath, this.originalURL, this.thumbnailURL);

  // コンストラクタ
  // FirestoreのMapからインスタンス化
  Thumbnail.fromMap(Map<String, dynamic> map) {
    /*いるんか？？？
    if (map != null) {*/
    this.originalPath = map[ThumbnailField.path];
    this.originalURL = map[ThumbnailField.originalURL];
    this.thumbnailURL = map[ThumbnailField.thumbnailURL];
    /*} else {
      this.originalPath = '';
      this.originalURL = '';
      this.thumbnailURL = '';
    }*/

    // DartのDateに変換
    final originCreatedAt = map[ThumbnailField.createdAt];
    if (originCreatedAt is Timestamp) {
      this.createdAt = originCreatedAt.toDate();
    }
  }

  // Firestore用のMapに変換
  Map<String, dynamic> toMap() {
    return {
      ThumbnailField.path: this.originalPath,
      ThumbnailField.originalURL: this.originalURL,
      ThumbnailField.thumbnailURL: this.thumbnailURL,
      ThumbnailField.createdAt: this.createdAt, // Dateはそのまま渡せる
    };
  }
}

//フィールド名のタイピングミスを防ぐ
class ThumbnailField {
  static const path = "path";
  static const originalURL = "originalURL";
  static const thumbnailURL = "thumbnailURL";
  static const createdAt = "createdAt";
}

//userIDとフィールドデータを保持する
class ThumbnailDocument {
  String documentId;
  Thumbnail thumbnail;

  ThumbnailDocument(this.documentId, this.thumbnail);
}
