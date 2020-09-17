import 'dart:ui';
import 'package:pono_problem_app/utils/conv.dart';
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
  Offset position; //(トリム前の)ベース写真の左上基準
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
    this.position = Offset(Conv.toDbl(map[PrimitiveField.positionX]),
        Conv.toDbl(map[PrimitiveField.positionY]));
    this.sizeType = PrimitiveSizeType.values
        .firstWhere((e) => e.toString() == map[PrimitiveField.sizeType]);
    this.color = Conv.stringToUiColor(map[PrimitiveField.color]);
    this.subItemPosition = PrimitiveSubItemPosition.values
        .firstWhere((e) => e.toString() == map[PrimitiveField.subItemPosition]);
  }

  // Firestore用のMapに変換
  Map<String, dynamic> toMap() {
    return {
      PrimitiveField.type: this.type.toString(),
      PrimitiveField.positionX: this.position.dx,
      PrimitiveField.positionY: this.position.dy,
      PrimitiveField.sizeType: this.sizeType.toString(),
      PrimitiveField.color: Conv.uiColorToString(this.color),
      PrimitiveField.subItemPosition: this.subItemPosition.toString(),
    };
  }
}

//フィールド名のタイピングミスを防ぐ
class PrimitiveField {
  static const type = "type";
  static const positionX = "positionX";
  static const positionY = "positionY";
  static const sizeType = "sizeType";
  static const color = "color";
  static const subItemPosition = "subItemPosition";
}

//プリミティブとフィールドデータを保持する
class PrimitiveDocument {
  String docId;
  Primitive data;

  PrimitiveDocument(this.docId, this.data);
}
