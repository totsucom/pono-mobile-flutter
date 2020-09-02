import 'dart:ui' as UI;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

enum ActiveEdge { None, LeftEdge, TopEdge, RightEdge, BottomEdge }

class TrimmingPainter {
  //Color toolBarBackgroundColor;
  Color activeKnobColor;
  Color knobColor;
  TrimmingPainter(this.knobColor, this.activeKnobColor);

  //利用可能かどうか
  bool get isReady => (this._images != null);

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

  //イメージの設定または取得
  List<UI.Image> _images;
  List<UI.Image> get images => _images;
  set images(List<UI.Image> newImages) {
    assert(newImages.length == 4);
    _images = newImages;
    _updated = true;
  }

  UI.Image get image => this._images[_rotationIndex];
  int get imageWidth => this._images[_rotationIndex].width;
  int get imageHeight => this._images[_rotationIndex].height;

  //Rotationの設定または取得
  //この値は 0, 90, 180, 270 のいずれか。 -90, 360 も設定可能
  int _rotation = 0;
  int _rotationIndex = 0;
  int get rotation => _rotation;
/*  set rotation(int newValue) {
    if (!this.isReady) return;
    if (newValue == -90)
      newValue = 270;
    else if (newValue == 360) newValue = 0;
    final i = [0, 90, 180, 270].indexOf(newValue);
    if (i >= 0) {
      if (_rotation != newValue) {
        _rotation = newValue;
        _rotationIndex = i;
        _updated = true;
      }
    }
  }
*/
  void rotateLeft() {
    if (--_rotationIndex < 0) _rotationIndex = 3;
    _rotation = _rotationIndex * 90;
    _updated = true;

    var w = _trimLeft;
    _trimLeft = _trimTop;
    _trimTop = _trimRight;
    _trimRight = _trimBottom;
    _trimBottom = w;
  }

  void rotateRight() {
    if (++_rotationIndex > 3) _rotationIndex = 0;
    _rotation = _rotationIndex * 90;
    _updated = true;

    var w = _trimTop;
    _trimTop = _trimLeft;
    _trimLeft = _trimBottom;
    _trimBottom = _trimRight;
    _trimRight = w;
  }

  //画面の中央に座標に相当する、baseImage上の座標
  /*Offset _imagePosition;

  Offset get imagePosition => _imagePosition;

  set imagePosition(Offset newPos) {
    if (_imagePosition != newPos) _updated = true;
    _imagePosition = newPos;
  }*/

  //実際の表示倍率
  //UIクラス(trimming_image_route)側から使用するために、MyPainterクラスから設定される
  //double actualScale = 0.0;

  //キャンバスの大きさ
  //UIクラス(trimming_image_route)側から使用するために、MyPainterクラスから設定される
  Size canvasSize = Size(0, 0);

  //キャンバス上に表示されたツマミの位置
  //UIクラス(trimming_image_route)側から使用するために、MyPainterクラスから設定される
  Offset leftKnob, topKnob, rightKnob, bottomKnob;

  //キャンバス上に表示されたイメージの大きさ
  //UIクラス(trimming_image_route)側から使用するために、MyPainterクラスから設定される
  Size drawSize;

  //操作中のエッジを指定
  ActiveEdge _activeEdge = ActiveEdge.None;
  ActiveEdge get activeEdge => _activeEdge;
  set activeEdge(ActiveEdge newEdge) {
    if (_activeEdge != newEdge) {
      _activeEdge = newEdge;
      _updated = true;
    }
  }

  //トリミングTopの設定または取得 0.0～1.0
  double _trimTop = 0.0;
  double get trimTop => _trimTop;
  set trimTop(double newValue) {
    if (!this.isReady) return;
    final limit = 0.9 - this._trimBottom;
    if (newValue > limit) newValue = limit;
    if (newValue < 0.0) newValue = 0.0;
    if (_trimTop != newValue) {
      _trimTop = newValue;
      _updated = true;
    }
  }

  //トリミングBottomの設定または取得 0.0～1.0
  double _trimBottom = 0.0;
  double get trimBottom => _trimBottom;
  set trimBottom(double newValue) {
    if (!this.isReady) return;
    final limit = 0.9 - this.trimTop;
    if (newValue > limit) newValue = limit;
    if (newValue < 0.0) newValue = 0.0;
    if (_trimBottom != newValue) {
      _trimBottom = newValue;
      _updated = true;
    }
  }

  //トリミングLeftの設定または取得 0.0～1.0
  double _trimLeft = 0.0;
  double get trimLeft => _trimLeft;
  set trimLeft(double newValue) {
    if (!this.isReady) return;
    final limit = 0.9 - this.trimRight;
    if (newValue > limit) newValue = limit;
    if (newValue < 0.0) newValue = 0.0;
    if (_trimLeft != newValue) {
      _trimLeft = newValue;
      _updated = true;
    }
  }

  //トリミングRightの設定または取得 0.0～1.0
  double _trimRight = 0.0;
  double get trimRight => _trimRight;
  set trimRight(double newValue) {
    if (!this.isReady) return;
    final limit = 0.9 - this.trimLeft;
    if (newValue > limit) newValue = limit;
    if (newValue < 0.0) newValue = 0.0;
    if (_trimRight != newValue) {
      _trimRight = newValue;
      _updated = true;
    }
  }

  //キャンバスに対して描画する
  void paint(Canvas canvas, Size canvasSize, double topIgnoreHeight) {
    //キャンバスサイズを記憶
    this.canvasSize = canvasSize;

    if (!this.isReady) return;

    //スケールを決定
    final scaleX = canvasSize.width / this.imageWidth;
    final scaleY = (canvasSize.height - topIgnoreHeight) / this.imageHeight;
    final scale = ((scaleX < scaleY) ? scaleX : scaleY) * 0.9;

    //背景を黒に塗りつぶす
    final paint = Paint();
    //paint.color = Colors.black;
    //canvas.drawRect(Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height), paint);

    //イメージを表示
    final dstWidth = this.imageWidth * scale;
    final dstHeight = this.imageHeight * scale;
    this.drawSize = Size(dstWidth, dstHeight);
    final dstX = (canvasSize.width - dstWidth) / 2.0;
    final dstY = (canvasSize.height - topIgnoreHeight - dstHeight) / 2.0 +
        topIgnoreHeight;
    canvas.drawImageRect(
        this.image,
        Rect.fromLTWH(
            0, 0, this.imageWidth.toDouble(), this.imageHeight.toDouble()),
        Rect.fromLTWH(dstX, dstY, dstWidth, dstHeight),
        paint);

    //全体を暗くする
    paint.color = Color.fromARGB(128, 0, 0, 0);
    canvas.drawRect(
        Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height), paint);

    //トリミングエッジ
    final leftEdge = dstX + dstWidth * this.trimLeft;
    final topEdge = dstY + dstHeight * this.trimTop;
    final rightEdge = dstX + dstWidth * (1.0 - this.trimRight);
    final bottomEdge = dstY + dstHeight * (1.0 - this.trimBottom);

    //トリミングエッジの内側にイメージを再描画（ここは明るくなる）
    canvas.drawImageRect(
        this.image,
        Rect.fromLTRB(
            this.imageWidth.toDouble() * this.trimLeft,
            this.imageHeight.toDouble() * this.trimTop,
            this.imageWidth.toDouble() * (1.0 - this.trimRight),
            this.imageHeight.toDouble() * (1.0 - this.trimBottom)),
        Rect.fromLTRB(leftEdge, topEdge, rightEdge, bottomEdge),
        paint);

    //トリミングエッジのラインを描画
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;

    paint.color = (this.activeEdge == ActiveEdge.LeftEdge)
        ? this.activeKnobColor
        : this.knobColor;
    canvas.drawLine(
        Offset(leftEdge, topEdge), Offset(leftEdge, bottomEdge), paint);

    paint.color = (this.activeEdge == ActiveEdge.TopEdge)
        ? this.activeKnobColor
        : this.knobColor;
    canvas.drawLine(
        Offset(leftEdge, topEdge), Offset(rightEdge, topEdge), paint);

    paint.color = (this.activeEdge == ActiveEdge.RightEdge)
        ? this.activeKnobColor
        : this.knobColor;
    canvas.drawLine(
        Offset(rightEdge, topEdge), Offset(rightEdge, bottomEdge), paint);

    paint.color = (this.activeEdge == ActiveEdge.BottomEdge)
        ? this.activeKnobColor
        : this.knobColor;
    canvas.drawLine(
        Offset(leftEdge, bottomEdge), Offset(rightEdge, bottomEdge), paint);

    //トリミングエッジのツマミを描画
    paint.style = PaintingStyle.fill;

    paint.color = (this.activeEdge == ActiveEdge.LeftEdge)
        ? this.activeKnobColor
        : this.knobColor;
    this.leftKnob = Offset(leftEdge, (bottomEdge + topEdge) / 2);
    canvas.drawCircle(this.leftKnob, 8.0, paint);

    paint.color = (this.activeEdge == ActiveEdge.TopEdge)
        ? this.activeKnobColor
        : this.knobColor;
    this.topKnob = Offset((leftEdge + rightEdge) / 2, topEdge);
    canvas.drawCircle(this.topKnob, 8.0, paint);

    paint.color = (this.activeEdge == ActiveEdge.RightEdge)
        ? this.activeKnobColor
        : this.knobColor;
    this.rightKnob = Offset(rightEdge, (bottomEdge + topEdge) / 2);
    canvas.drawCircle(this.rightKnob, 8.0, paint);

    paint.color = (this.activeEdge == ActiveEdge.BottomEdge)
        ? this.activeKnobColor
        : this.knobColor;
    this.bottomKnob = Offset((leftEdge + rightEdge) / 2, bottomEdge);
    canvas.drawCircle(this.bottomKnob, 8.0, paint);
  }
}
