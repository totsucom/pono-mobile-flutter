import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pono_problem_app/records/primitive.dart';
import 'package:pono_problem_app/utils/rect_ex.dart';

//※ enumアイテム名でDBに保存するので、名称変更しないこと
enum ProblemStatus {
  Draft, //下書き
  Private, //非公開の課題
  Published //公開された課題
}

//problemsコレクションのドキュメント
class Problem {
  static const baseName = "課題";

  String basePicturePath;
  Rect trimRect;
  List<Primitive> primitives;
  String completedImagePath;

  bool imageRequired;
  String completedImageURL;
  String completedImageThumbURL;

  String title;
  String grade;
  bool footFree;
  String comment;

  ProblemStatus status;
  String userID;

  DateTime createdAt;
  DateTime updatedAt;
  DateTime publishedAt;

  // コンストラクタ
  Problem(
      this.basePicturePath,
      this.trimRect,
      this.primitives,
      this.completedImagePath,
      this.imageRequired,
      this.completedImageURL,
      this.completedImageThumbURL,
      this.title,
      this.grade,
      this.footFree,
      this.comment,
      this.status,
      this.userID);

  // コンストラクタ
  // FirestoreのMapからインスタンス化
  Problem.fromMap(Map<String, dynamic> map) {
    this.basePicturePath = map[ProblemField.basePicturePath];
    this.trimRect = RectEx.fromDbString(map[ProblemField.trimRect]).toRect();
    this.completedImagePath = map[ProblemField.completedImagePath];

    this.imageRequired = (map[ProblemField.imageRequired] == 1);
    this.completedImageURL = map[ProblemField.completedImageURL];
    this.completedImageThumbURL = map[ProblemField.completedImageThumbURL];

    this.title = map[ProblemField.title];
    this.grade = map[ProblemField.grade];
    this.footFree = (map[ProblemField.footFree] == 1);
    this.comment = map[ProblemField.comment];

    this.status = ProblemStatus.values
        .firstWhere((e) => e.toString() == map[ProblemField.status]);
    this.userID = map[ProblemField.userID];

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
    map[ProblemField.primitives].forEach((map) {
      primitives.add(Primitive.fromMap(map));
    });
  }

  // Firestore用のMapに変換
  Map<String, dynamic> toMap() {
    //プリミティブをmap化
    final list = primitives.map((e) => e.toMap()).toList();

    return {
      ProblemField.basePicturePath: this.basePicturePath,
      ProblemField.trimRect: RectEx(this.trimRect).toDbString(),
      ProblemField.primitives: list,
      ProblemField.completedImagePath: this.completedImagePath,

      ProblemField.imageRequired: this.imageRequired,
      ProblemField.completedImageURL: this.completedImageURL,
      ProblemField.completedImageThumbURL: this.completedImageThumbURL,

      ProblemField.title: this.title,
      ProblemField.grade: this.grade,
      ProblemField.footFree: (this.footFree) ? 1 : 0,
      ProblemField.comment: this.comment,

      ProblemField.status: this.status.toString(),
      ProblemField.userID: userID,

      ProblemField.createdAt: this.createdAt, // Dateはそのまま渡せる
      ProblemField.updatedAt: this.updatedAt,
      ProblemField.publishedAt: this.publishedAt
    };
  }
}

//フィールド名のタイピングミスを防ぐ
class ProblemField {
  static const basePicturePath = "basePicturePath";
  static const primitives = "primitives";
  static const trimRect = "trimRect";
  static const completedImagePath = "completedImagePath";

  static const imageRequired = "imageRequired";
  static const completedImageURL = "completedImageURL";
  static const completedImageThumbURL = "completedImageThumbURL";

  static const title = "title";
  static const grade = "grade";
  static const footFree = "footFree";
  static const comment = "comment";

  static const status = "status";
  static const userID = "userID";

  static const createdAt = "createdAt";
  static const updatedAt = "updatedAt";
  static const publishedAt = "publishedAt";
}

//documentIDとフィールドデータを保持する
class ProblemDocument {
  String documentId;
  Problem problem;

  ProblemDocument(this.documentId, this.problem);
}
