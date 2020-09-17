import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pono_problem_app/globals.dart';
import 'package:pono_problem_app/utils/conv.dart';

//wallsコレクションのドキュメント
class Wall {
  //UIでの表記を統一するために宣言
  static const baseName = "ウォール";

  String name;
  bool active;
  int order;

  // コンストラクタ
  Wall(this.name, this.active, this.order);

  // コンストラクタ
  // FirestoreのMapからインスタンス化
  Wall.fromMap(Map<String, dynamic> map) {
    assert(map != null);
    this.name = map[WallField.name] ?? '';
    this.active = map[WallField.active] ?? false;
    this.order = map[WallField.order];
  }

  // Firestore用のMapに変換
  Map<String, dynamic> toMap() {
    return {
      WallField.name: this.name,
      WallField.active: this.active,
      WallField.order: this.order
    };
  }
}

//フィールド名のタイピングミスを防ぐ
class WallField {
  static const name = "name";
  static const active = "active";
  static const order = "order";
}

class WallFieldCaption {
  static const name = "名称";
  static const active = "有効";
  static const order = "表示順";
}

//documentIDとフィールドデータを保持する
class WallDocument {
  String docId;
  Wall data;

  WallDocument(this.docId, this.data);
}
