import 'dart:ui';
import 'package:pono_problem_app/utils/offset_ex.dart';

//※ enumアイテム名でDBに保存するので、名称変更しないこと
enum PrimitiveType {
  RegularHold,
  StartHold,
  StartHold_Hand,
  StartHold_Foot,
  StartHold_LeftHand,
  StartHold_RightHand,
  GoalHold,
  Bote,
  Kante
}

//※ enumアイテム名でDBに保存するので、名称変更しないこと
enum PrimitiveSizeType { XS, S, M, L, XL }

//※ enumアイテム名でDBに保存するので、名称変更しないこと
enum PrimitiveSubItemPosition { Center, Right, Bottom, Left, Top }

//problemのサブコレクションprimitiveのドキュメント
class Primitive {
  PrimitiveType type;
  Offset position; //ベース写真の左上基準
  PrimitiveSizeType sizeType;
  Color color;
  PrimitiveSubItemPosition subItemPosition;

  // コンストラクタ
  Primitive(this.type, this.position, this.sizeType, this.color,
      {this.subItemPosition = PrimitiveSubItemPosition.Center});

  // コンストラクタ
  // FirestoreのMapからインスタンス化
  Primitive.fromMap(Map<String, dynamic> map) {
    this.type = PrimitiveType.values
        .firstWhere((e) => e.toString() == map[PrimitiveField.type]);
    this.position =
        OffsetEx.fromDbString(map[PrimitiveField.position]).toOffset();
    this.sizeType = PrimitiveSizeType.values
        .firstWhere((e) => e.toString() == map[PrimitiveField.sizeType]);
    this.color = Color(map[PrimitiveField.color]);
    this.subItemPosition = PrimitiveSubItemPosition.values
        .firstWhere((e) => e.toString() == map[PrimitiveField.subItemPosition]);
  }

  // Firestore用のMapに変換
  Map<String, dynamic> toMap() {
    return {
      PrimitiveField.type: this.type.toString(),
      PrimitiveField.position: OffsetEx(this.position).toDbString(),
      PrimitiveField.sizeType: this.sizeType.toString(),
      PrimitiveField.color: this.color.value.toString(),
      PrimitiveField.subItemPosition: this.subItemPosition.toString(),
    };
  }
}

//フィールド名のタイピングミスを防ぐ
class PrimitiveField {
  static const type = "type";
  static const position = "position";
  static const sizeType = "sizeType";
  static const color = "color";
  static const subItemPosition = "subItemPosition";
}

//プリミティブとフィールドデータを保持する
class PrimitiveDocument {
  String documentId;
  Primitive primitive;

  PrimitiveDocument(this.documentId, this.primitive);
}
