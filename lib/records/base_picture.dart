import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pono_problem_app/utils/conv.dart';

//クラスの作成に参考にしたページ
//https://qiita.com/sekitaka_1214/items/129f41c2fbb1dc05b5c3

//problemsコレクションのドキュメント
class BasePicture {
  //UIでの表記を統一するために宣言
  static const baseName = "ベース写真";

  //Functionsが登録時にのみ使用する項目
  String originalPath;
  int rotation;
  double trimLeft, trimTop, trimRight, trimBottom;

  //Functionsが入力する
  String pictureURL;
  String picturePath;
  String thumbnailURL;

  String name;
  String userID;
  DateTime createdAt;

  // コンストラクタ
  BasePicture(this.originalPath, this.rotation, this.trimLeft, this.trimTop,
      this.trimRight, this.trimBottom, this.name, this.userID,
      {this.picturePath = '', this.pictureURL = '', this.thumbnailURL = ''}) {
    assert(this.rotation == 0 ||
        this.rotation == 90 ||
        this.rotation == 180 ||
        this.rotation == 270);
    assert(this.trimLeft >= 0.0 && this.trimLeft <= 1.0);
    assert(this.trimTop >= 0.0 && this.trimTop <= 1.0);
    assert(this.trimRight >= 0.0 && this.trimRight <= 1.0);
    assert(this.trimBottom >= 0.0 && this.trimBottom <= 1.0);
  }

  // コンストラクタ
  // FirestoreのMapからインスタンス化
  BasePicture.fromMap(Map<String, dynamic> map) {
    //削除した瞬間など、StreamBuilderで一瞬エラーが表示されるのでnull対応を入れた
    if (map != null) {
      this.originalPath = map[BasePictureField.originalPath] ?? '';
      this.rotation = map[BasePictureField.rotation] ?? 0;
      //toDbl()で整数型の代入やnull代入を回避
      this.trimLeft = Conv.toDbl(map[BasePictureField.trimLeft]);
      this.trimTop = Conv.toDbl(map[BasePictureField.trimTop]);
      this.trimRight = Conv.toDbl(map[BasePictureField.trimRight]);
      this.trimBottom = Conv.toDbl(map[BasePictureField.trimBottom]);

      this.name = map[BasePictureField.name] ?? '';
      this.pictureURL = map[BasePictureField.pictureURL] ?? '';
      this.picturePath = map[BasePictureField.picturePath] ?? '';
      this.thumbnailURL = map[BasePictureField.thumbnailURL] ?? '';
      this.userID = map[BasePictureField.userID] ?? '';

      // DartのDateに変換
      final originCreatedAt = map[BasePictureField.createdAt];
      if (originCreatedAt is Timestamp) {
        this.createdAt = originCreatedAt.toDate();
      }
    } else {
      this.originalPath = '';
      this.rotation = 0;
      this.trimLeft = 0.0;
      this.trimTop = 0.0;
      this.trimRight = 0.0;
      this.trimBottom = 0.0;

      this.name = '';
      this.pictureURL = '';
      this.picturePath = '';
      this.thumbnailURL = '';
      this.userID = '';
    }
  }

  // Firestore用のMapに変換
  Map<String, dynamic> toMap() {
    return {
      BasePictureField.originalPath: this.originalPath,
      BasePictureField.rotation: this.rotation,
      BasePictureField.trimLeft: this.trimLeft,
      BasePictureField.trimTop: this.trimTop,
      BasePictureField.trimRight: this.trimRight,
      BasePictureField.trimBottom: this.trimBottom,

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
  static const originalPath = "originalPath";
  static const rotation = "rotation";
  static const trimLeft = "trimLeft";
  static const trimTop = "trimTop";
  static const trimRight = "trimRight";
  static const trimBottom = "trimBottom";

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
