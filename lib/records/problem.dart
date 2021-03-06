import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pono_problem_app/records/primitive.dart';
import 'package:pono_problem_app/utils/conv.dart';
import 'package:pono_problem_app/utils/rect_ex.dart';

//※ enumアイテム名でDBに保存するので、名称変更しないこと
enum ProblemStatus {
  None,
  Draft, //下書き
  Private, //非公開の課題
  Public //公開された課題
}

//problemsコレクションのドキュメント
class Problem {
  static const baseName = "課題";

  String basePicturePath;
  //Rect trimRect; //0.0-1.0
  double trimLeft, trimTop, trimRight, trimBottom; //0.0-1.0。各エッジからの距離
  List<Primitive> primitives;
  //String completedImagePath;

  bool imageRequired;
  String completedImageURL;
  String completedImageThumbURL;

  String title;
  int grade;
  String gradeOption;
  List<String> wallIDs;
  bool footFree;
  String comment;

  ProblemStatus status;
  String uid;

  DateTime createdAt;
  DateTime updatedAt;
  DateTime publishedAt;

  // コンストラクタ
  Problem(this.trimLeft, this.trimTop, this.trimRight, this.trimBottom,
      this.primitives, this.uid,
      {this.basePicturePath = '',
      //this.completedImagePath = '',
      this.imageRequired = true,
      this.completedImageURL = '',
      this.completedImageThumbURL = '',
      this.title = '',
      this.grade = 7,
      this.gradeOption = '',
      this.wallIDs,
      this.footFree = false,
      this.comment = '',
      this.status = ProblemStatus.None});

  // コンストラクタ
  // FirestoreのMapからインスタンス化
  Problem.fromMap(Map<String, dynamic> map) {
    this.basePicturePath = map[ProblemField.basePicturePath];
    //this.trimRect = RectEx.fromDbString(map[ProblemField.trimRect]).toRect();
    this.trimLeft = Conv.toDbl(map[ProblemField.trimLeft]);
    this.trimTop = Conv.toDbl(map[ProblemField.trimTop]);
    this.trimRight = Conv.toDbl(map[ProblemField.trimRight]);
    this.trimBottom = Conv.toDbl(map[ProblemField.trimBottom]);
    //this.completedImagePath = map[ProblemField.completedImagePath];

    this.imageRequired = (map[ProblemField.imageRequired] == 1);
    this.completedImageURL = map[ProblemField.completedImageURL];
    this.completedImageThumbURL = map[ProblemField.completedImageThumbURL];

    this.title = map[ProblemField.title];
    this.grade = map[ProblemField.grade];
    this.gradeOption = map[ProblemField.gradeOption];
    this.wallIDs = (map[ProblemField.wallIDs] == null)
        ? <String>[]
        : (map[ProblemField.wallIDs] as List).map((e) => e.toString()).toList();
    this.footFree = map[ProblemField.footFree];
    this.comment = map[ProblemField.comment];

    this.status = ProblemStatus.values
        .firstWhere((e) => e.toString() == map[ProblemField.status]);
    this.uid = map[ProblemField.uid];

    // DartのDateに変換
    final originCreatedAt = map[ProblemField.createdAt];
    if (originCreatedAt is Timestamp) {
      this.createdAt = originCreatedAt.toDate();
    }
    final originUpdatedAt = map[ProblemField.updatedAt];
    if (originUpdatedAt is Timestamp) {
      this.updatedAt = originUpdatedAt.toDate();
    }
    final originPublishedAt = map[ProblemField.publishedAt];
    if (originPublishedAt is Timestamp) {
      this.publishedAt = originPublishedAt.toDate();
    }

    //プリミティブを読み込む
    primitives = [];
    //map[ProblemField.primitives].forEach((map) {
    //  primitives.add(Primitive.fromMap(map));
    //});
  }

  // Firestore用のMapに変換
  Map<String, dynamic> toMap() {
    //プリミティブをmap化
    //final list = primitives.map((e) => e.toMap()).toList();

    return {
      ProblemField.basePicturePath: this.basePicturePath,
      //ProblemField.trimRect: RectEx(this.trimRect).toDbString(),
      ProblemField.trimLeft: this.trimLeft,
      ProblemField.trimTop: this.trimTop,
      ProblemField.trimRight: this.trimRight,
      ProblemField.trimBottom: this.trimBottom,
      //ProblemField.primitives: list,
      //ProblemField.completedImagePath: this.completedImagePath,

      ProblemField.imageRequired: this.imageRequired,
      ProblemField.completedImageURL: this.completedImageURL,
      ProblemField.completedImageThumbURL: this.completedImageThumbURL,

      ProblemField.title: this.title,
      ProblemField.grade: this.grade,
      ProblemField.gradeOption: this.gradeOption,
      ProblemField.wallIDs: this.wallIDs,
      ProblemField.footFree: this.footFree,
      ProblemField.comment: this.comment,

      ProblemField.status: this.status.toString(),
      ProblemField.uid: uid,

      ProblemField.createdAt: this.createdAt, // Dateはそのまま渡せる
      ProblemField.updatedAt: this.updatedAt,
      ProblemField.publishedAt: this.publishedAt
    };
  }
}

//フィールド名のタイピングミスを防ぐ
class ProblemField {
  static const basePicturePath = "basePicturePath";
  //static const primitives = "primitives";
  //static const trimRect = "trimRect";
  static const trimLeft = "trimLeft";
  static const trimTop = "trimTop";
  static const trimRight = "trimRight";
  static const trimBottom = "trimBottom";
  //static const completedImagePath = "completedImagePath";

  static const imageRequired = "imageRequired";
  static const completedImageURL = "completedImageURL";
  static const completedImageThumbURL = "completedImageThumbURL";

  static const title = "title";
  static const grade = "grade";
  static const gradeOption = "gradeOption";
  static const wallIDs = "wallIDs";
  static const footFree = "footFree";
  static const comment = "comment";

  static const status = "status";
  static const uid = "uid";

  static const createdAt = "createdAt";
  static const updatedAt = "updatedAt";
  static const publishedAt = "publishedAt";
}

//documentIDとフィールドデータを保持する
class ProblemDocument {
  String docId;
  Problem data;

  ProblemDocument(this.docId, this.data);
}
