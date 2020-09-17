import 'dart:ui' as UI;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pono_problem_app/general/primitive_ui.dart';

/* TODO
*  updatedの代わりに ChangeNotifier, ChangeNotifierProvider を使うほうがスマートかも
* https://flutter.dev/docs/development/data-and-backend/state-mgmt/simple
* */

class ProblemPainter {
  //抽象的な表示倍率の範囲
  //1.0はベース写真がキャンバスに納まる倍率
  static const DISPLAY_SIZE_MIN = 0.6;
  static const DISPLAY_SIZE_MAX = 2.0;
  static const DISPLAY_SIZE_DIV = 28;

  //利用可能かどうか
  bool get isReady => (this._baseImage != null);

  //再描画する必要があるかどうかのフラグを取得、設定、クリアする
  bool _updated = false;

  bool get isUpdated => _updated;

  //MyPainterクラスで使用する
  bool get isUpdatedAndReset {
    bool b = _updated;
    _updated = false;
    return b;
  }

  //使うことはないかも
  void setUpdate() {
    _updated = true;
  }

  //ベース写真イメージの設定または取得
  UI.Image _baseImage;

  UI.Image get baseImage => _baseImage;

  set baseImage(UI.Image newImage) {
    _baseImage = newImage;
    moveToCenter();
    _updated = true;
  }

  //画面の中央に座標に相当する、baseImage上の座標
  Offset _baseImagePosition;

  Offset get baseImagePosition => _baseImagePosition;

  set baseImagePosition(Offset newPos) {
    if (_baseImagePosition != newPos) _updated = true;
    _baseImagePosition = newPos;
  }

  void moveToCenter() {
    baseImagePosition = Offset(_baseImage.width / 2.0, _baseImage.height / 2.0);
    _updated = true;
  }

  //抽象的な表示スケール
  //1.0はベース写真がキャンバスにちょうど納まる大きさ
  double _displaySize = 1.0;

  double get displaySize => this._displaySize;

  set displaySize(double newSize) {
    assert(newSize >= DISPLAY_SIZE_MIN && newSize <= DISPLAY_SIZE_MAX);
    if (_displaySize != newSize) _updated = true;
    _displaySize = newSize;
  }

  //実際の表示倍率
  //UIクラス(edit_holds_route)側から使用するために、MyPainterクラスから設定される
  double actualScale = 0.0;

  //キャンバスの大きさ
  //UIクラス(edit_holds_route)側から使用するために、MyPainterクラスから設定される
  Size canvasSize = Size(0, 0);

  //選択したプリミティブを描画する（破線を動かす）際に使うラインパターンインデックス
  Animation<int> patternIndex;

  /*int get patternIndex => _patternIndex;

  set patternIndex(int newIndex) {
    //if (_patternIndex != newIndex) _updated = true;
    _patternIndex = newIndex;
  }*/

  //プリミティブ(Primitive)のリスト
  final primitives = <PrimitiveUI>[];

  //プリミティブを追加
  void addPrimitive(PrimitiveUI newPrim, bool select) {
    primitives.add(newPrim);
    if (select) selectedPrimitiveIndex = primitives.length - 1;
    _updated = true;
  }

  //プリミティブを削除
  void removePrimitive(PrimitiveUI prim) {
    var index = primitives.indexOf(prim);
    if (index >= 0) {
      primitives.removeAt(index);
      if (index == selectedPrimitiveIndex) selectedPrimitiveIndex = -1;
      _updated = true;
    }
  }

  //プリミティブを更新（したときに呼び出す）
  void primitiveUpdated() {
    _updated = true;
  }

  //選択中のprimitives[]のインデックス
  int _selectedPrimitiveIndex = -1;

  int get selectedPrimitiveIndex => _selectedPrimitiveIndex;

  set selectedPrimitiveIndex(int newIndex) {
    if (_selectedPrimitiveIndex != newIndex) _updated = true;
    _selectedPrimitiveIndex = newIndex;
    //selectedPrimitiveIndexの値を各プリミティブクラスに反映
    for (var i = 0; i < primitives.length; i++)
      primitives[i].selected = (i == _selectedPrimitiveIndex);
  }

  //選択中のプリミティブ
  PrimitiveUI get selectedPrimitive {
    if (_selectedPrimitiveIndex < 0) return null;
    return primitives[_selectedPrimitiveIndex];
  }

  set selectedPrimitive(PrimitiveUI prim) {
    int newIndex = (prim == null) ? -1 : primitives.indexOf(prim);
    if (_selectedPrimitiveIndex != newIndex) _updated = true;
    selectedPrimitiveIndex = newIndex;
  }

  //キャンバスに対して描画する
  void paint(Canvas canvas, Size canvasSize) {
    //キャンバスサイズを記憶
    this.canvasSize = canvasSize;

    if (!this.isReady) return;

    //スケールを計算
    final double scaleW = canvasSize.width / this.baseImage.width.toDouble();
    final double scaleH = canvasSize.height / this.baseImage.height.toDouble();
    this.actualScale = ((scaleW < scaleH) ? scaleW : scaleH) * this.displaySize;

    //キャンバス上の描画エリア
    final canvasRect = Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height);

    //描画する、ベース写真上のエリア
    final srcWidth = canvasRect.width / this.actualScale;
    final srcHeight = canvasSize.height / this.actualScale;
    final srcX = this.baseImagePosition.dx - srcWidth / 2.0;
    final srcY = this.baseImagePosition.dy - srcHeight / 2.0;

    // TODO
    //キャンバスと描画エリアの重なり具合から、背景色の塗りつぶし処理を低減する

    //背景を黒に塗りつぶす
    final paint = Paint();
    paint.color = Colors.black;
    canvas.drawRect(canvasRect, paint);

    //ベース写真を表示
    canvas.drawImageRect(this.baseImage,
        Rect.fromLTWH(srcX, srcY, srcWidth, srcHeight), canvasRect, paint);

    //プリミティブを描画
    final canvasCenter =
        Offset(canvasSize.width / 2.0, canvasSize.height / 2.0);
    this.primitives.forEach((prim) {
      if (!prim.selected) {
        prim.draw(canvas, canvasCenter, this.baseImagePosition,
            this.actualScale, false);
      }
    });

    //選択されたプリミティブを描画
    final prim = this.selectedPrimitive;
    if (prim != null) {
      prim.draw(canvas, canvasCenter, this.baseImagePosition, this.actualScale,
          true, this.patternIndex.value);
    }
  }
}
