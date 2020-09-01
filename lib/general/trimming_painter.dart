import 'dart:ui' as UI;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pono_problem_app/general/primitive_ui.dart';

enum ActiveEdge { None, LeftEdge, TopEdge, RightEdge, BottomEdge }

class TrimmingPainter {
  Color toolBarBackgroundColor;
  Color activeKnobColor;
  TrimmingPainter(this.toolBarBackgroundColor, this.activeKnobColor);

  //利用可能かどうか
  bool get isReady => (this._image != null);

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
  UI.Image _image;
  UI.Image get image => _image;
  set image(UI.Image newImage) {
    _image = newImage;
    //_imagePosition = Offset(newImage.width / 2.0, newImage.height / 2.0);
    _updated = true;
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
  double actualScale = 0.0;

  //キャンバスの大きさ
  //UIクラス(trimming_image_route)側から使用するために、MyPainterクラスから設定される
  Size canvasSize = Size(0, 0);

  //キャンバス上に表示されたツマミの位置
  //UIクラス(trimming_image_route)側から使用するために、MyPainterクラスから設定される
  Offset leftKnob, topKnob, rightKnob, bottomKnob;

  //操作中のエッジを指定
  ActiveEdge _activeEdge = ActiveEdge.None;
  ActiveEdge get activeEdge => _activeEdge;
  set activeEdge(ActiveEdge newEdge) {
    if (_activeEdge != newEdge) {
      _activeEdge = newEdge;
      _updated = true;
    }
  }

  //トリミングTopの設定または取得
  double _trimTop = 0.0;
  double get trimTop => _trimTop;
  set trimTop(double newValue) {
    if (!this.isReady) return;
    final limit = _image.height * 0.9 - _trimBottom;
    if (newValue > limit) newValue = limit;
    if (newValue < 0.0) newValue = 0.0;
    if (_trimTop != newValue) {
      _trimTop = newValue;
      _updated = true;
    }
  }

  //トリミングBottomの設定または取得
  double _trimBottom = 0.0;
  double get trimBottom => _trimBottom;
  set trimBottom(double newValue) {
    if (!this.isReady) return;
    final limit = _image.height * 0.9 - _trimTop;
    if (newValue > limit) newValue = limit;
    if (newValue < 0.0) newValue = 0.0;
    if (_trimBottom != newValue) {
      _trimBottom = newValue;
      _updated = true;
    }
  }

  //トリミングLeftの設定または取得
  double _trimLeft = 0.0;
  double get trimLeft => _trimLeft;
  set trimLeft(double newValue) {
    if (!this.isReady) return;
    final limit = _image.width * 0.9 - _trimRight;
    if (newValue > limit) newValue = limit;
    if (newValue < 0.0) newValue = 0.0;
    if (_trimLeft != newValue) {
      _trimLeft = newValue;
      _updated = true;
    }
  }

  //トリミングRightの設定または取得
  double _trimRight = 0.0;
  double get trimRight => _trimRight;
  set trimRight(double newValue) {
    if (!this.isReady) return;
    final limit = _image.width * 0.9 - _trimLeft;
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
    final scale_x = canvasSize.width / this.image.width;
    final scale_y = (canvasSize.height - topIgnoreHeight) / this.image.height;
    this.actualScale = ((scale_x < scale_y) ? scale_x : scale_y) * 0.9;

    //背景を黒に塗りつぶす
    final paint = Paint();
    //paint.color = Colors.black;
    //canvas.drawRect(Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height), paint);

    //イメージを表示
    final dstWidth = this.image.width * this.actualScale;
    final dstHeight = this.image.height * this.actualScale;
    final dstX = (canvasSize.width - dstWidth) / 2.0;
    final dstY = (canvasSize.height - topIgnoreHeight - dstHeight) / 2.0 +
        topIgnoreHeight;
    canvas.drawImageRect(
        this.image,
        Rect.fromLTWH(
            0, 0, this.image.width.toDouble(), this.image.height.toDouble()),
        Rect.fromLTWH(dstX, dstY, dstWidth, dstHeight),
        paint);

    //全体を暗くする
    paint.color = Color.fromARGB(128, 0, 0, 0);
    canvas.drawRect(
        Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height), paint);

    //トリミングエッジ
    final leftEdge = dstX + this.trimLeft * this.actualScale;
    final topEdge = dstY + this.trimTop * this.actualScale;
    final rightEdge = dstX + dstWidth - this.trimRight * this.actualScale;
    final bottomEdge = dstY + dstHeight - this.trimBottom * this.actualScale;

    //トリミングエッジの内側にイメージを再描画（ここは明るくなる）
    canvas.drawImageRect(
        this.image,
        Rect.fromLTRB(
            this.trimLeft,
            this.trimTop,
            this.image.width.toDouble() - this.trimRight,
            this.image.height.toDouble() - this.trimBottom),
        Rect.fromLTRB(leftEdge, topEdge, rightEdge, bottomEdge),
        paint);

    //トリミングエッジのラインを描画
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;

    paint.color = (this.activeEdge == ActiveEdge.LeftEdge)
        ? this.activeKnobColor
        : Colors.grey;
    canvas.drawLine(
        Offset(leftEdge, topEdge), Offset(leftEdge, bottomEdge), paint);

    paint.color = (this.activeEdge == ActiveEdge.TopEdge)
        ? this.activeKnobColor
        : Colors.grey;
    canvas.drawLine(
        Offset(leftEdge, topEdge), Offset(rightEdge, topEdge), paint);

    paint.color = (this.activeEdge == ActiveEdge.RightEdge)
        ? this.activeKnobColor
        : Colors.grey;
    canvas.drawLine(
        Offset(rightEdge, topEdge), Offset(rightEdge, bottomEdge), paint);

    paint.color = (this.activeEdge == ActiveEdge.BottomEdge)
        ? this.activeKnobColor
        : Colors.grey;
    canvas.drawLine(
        Offset(leftEdge, bottomEdge), Offset(rightEdge, bottomEdge), paint);

    //トリミングエッジのツマミを描画
    paint.style = PaintingStyle.fill;

    paint.color = (this.activeEdge == ActiveEdge.LeftEdge)
        ? this.activeKnobColor
        : Colors.white;
    this.leftKnob = Offset(leftEdge, (bottomEdge + topEdge) / 2);
    canvas.drawCircle(this.leftKnob, 8.0, paint);

    paint.color = (this.activeEdge == ActiveEdge.TopEdge)
        ? this.activeKnobColor
        : Colors.white;
    this.topKnob = Offset((leftEdge + rightEdge) / 2, topEdge);
    canvas.drawCircle(this.topKnob, 8.0, paint);

    paint.color = (this.activeEdge == ActiveEdge.RightEdge)
        ? this.activeKnobColor
        : Colors.white;
    this.rightKnob = Offset(rightEdge, (bottomEdge + topEdge) / 2);
    canvas.drawCircle(this.rightKnob, 8.0, paint);

    paint.color = (this.activeEdge == ActiveEdge.BottomEdge)
        ? this.activeKnobColor
        : Colors.white;
    this.bottomKnob = Offset((leftEdge + rightEdge) / 2, bottomEdge);
    canvas.drawCircle(this.bottomKnob, 8.0, paint);
  }
}
