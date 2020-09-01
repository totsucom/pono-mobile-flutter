import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:pono_problem_app/records/primitive.dart';
import 'package:pono_problem_app/utils/offset_ex.dart';

//プリミティブを描画するクラス
class PrimitiveUI extends Primitive {
  bool selected = false;

  //コンストラクタ
  PrimitiveUI(PrimitiveType type, Offset position, PrimitiveSizeType sizeType,
      Color color,
      {PrimitiveSubItemPosition subItemPosition =
          PrimitiveSubItemPosition.Center})
      : super(type, position, sizeType, color,
            subItemPosition: subItemPosition);

  //コレクションクラスのPrimitiveからインポート
  PrimitiveUI.fromPrimitive(Primitive p)
      : super(p.type, p.position, p.sizeType, p.color,
            subItemPosition: p.subItemPosition);

  final _dimensions = {
    PrimitiveSizeType.XS: {'radius': 20.0, 'width': 4.0},
    PrimitiveSizeType.S: {'radius': 30.0, 'width': 4.0},
    PrimitiveSizeType.M: {'radius': 40.0, 'width': 4.0},
    PrimitiveSizeType.L: {'radius': 50.0, 'width': 4.0},
    PrimitiveSizeType.XL: {'radius': 60.0, 'width': 4.0},
  };

  final _textInfo = {
    PrimitiveType.StartHold: {'text': 'Ｓ', 'fontSize': 60.0},
    PrimitiveType.StartHold_Hand: {'text': '手', 'fontSize': 60.0},
    PrimitiveType.StartHold_Foot: {'text': '足', 'fontSize': 60.0},
    PrimitiveType.StartHold_RightHand: {'text': '右', 'fontSize': 60.0},
    PrimitiveType.StartHold_LeftHand: {'text': '左', 'fontSize': 60.0},
    PrimitiveType.GoalHold: {'text': 'Ｇ', 'fontSize': 60.0},
    PrimitiveType.Bote: {'text': 'ボテ', 'fontSize': 60.0},
    PrimitiveType.Kante: {'text': 'カンテ', 'fontSize': 60.0},
  };

  //プリミティブの描画範囲をざっくり返す
  Rect getBound(
      Offset canvasCenter, Offset baseImagePosition, double actualScale) {
    //描画座標を計算
    final Offset drawPos = Offset(
        (position.dx - baseImagePosition.dx) * actualScale + canvasCenter.dx,
        (position.dy - baseImagePosition.dy) * actualScale + canvasCenter.dy);

    double radius = _dimensions[sizeType]['radius'] * actualScale;
    return Rect.fromLTWH(
        drawPos.dx - radius, drawPos.dy - radius, radius * 2.0, radius * 2.0);
  }

  //プリミティブを描画する
  void draw(Canvas canvas, Offset canvasCenter, Offset baseImagePosition,
      double actualScale, bool selected,
      [int patternIndex = 0]) {
    //描画座標を計算
    final Offset drawPos = Offset(
        (position.dx - baseImagePosition.dx) * actualScale + canvasCenter.dx,
        (position.dy - baseImagePosition.dy) * actualScale + canvasCenter.dy);

    //描画オプションを設定
    final paint = Paint()
      ..color = this.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _dimensions[sizeType]['width'] * actualScale;
    double radius = _dimensions[sizeType]['radius'] * actualScale;

    //テキストの準備
    TextPainter textPainter;
    if (_textInfo.containsKey(type)) {
      double fontSize = (_textInfo[type]['fontSize'] as double) * actualScale;
      final textSpan = TextSpan(
          style: TextStyle(
            color: this.color,
            fontSize: fontSize,
          ),
          text: _textInfo[type]['text']);
      textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(
        minWidth: 0,
        maxWidth: 300,
      );
    }

    if (type == PrimitiveType.Bote || type == PrimitiveType.Kante) {
      //テキストを書く
      final leftTop = Offset(drawPos.dx - textPainter.width / 2.0,
          drawPos.dy - textPainter.height / 2.0);
      textPainter.paint(canvas, leftTop);

      //線を引く
      Offset p1, p2;
      switch (subItemPosition) {
        case PrimitiveSubItemPosition.Center:
          break;
        case PrimitiveSubItemPosition.Right:
          p1 = leftTop + Offset(textPainter.width, textPainter.height / 2.0);
          p2 = p1 + Offset(radius * 2.0, 0.0);
          break;
        case PrimitiveSubItemPosition.Bottom:
          p1 = leftTop + Offset(textPainter.width / 2.0, textPainter.height);
          p2 = p1 + Offset(0.0, radius * 2.0);
          break;
        case PrimitiveSubItemPosition.Left:
          p1 = leftTop + Offset(0.0, textPainter.height / 2.0);
          p2 = p1 + Offset(-radius * 2.0, 0.0);
          break;
        case PrimitiveSubItemPosition.Top:
          p1 = leftTop + Offset(textPainter.width / 2.0, 0.0);
          p2 = p1 + Offset(0.0, -radius * 2.0);
          break;
      }
      if (p1 != null) {
        //メインの線を引く
        canvas.drawLine(p1, p2, paint);

        //先の矢印かカンテラインを引く
        final ang = (type == PrimitiveType.Bote) ? 0.55 : pi / 2.0;
        final len = (type == PrimitiveType.Bote) ? 10.0 : 20.0;
        var ab = createArrowOffset(p1, p2, allowLength: len, allowAngle: ang);
        canvas.drawLine(ab[0], p2, paint);
        canvas.drawLine(p2, ab[1], paint);
      }

      //選択時は破線で囲む
      if (selected) {
        drawDashedHLine(
            canvas, leftTop, textPainter.width, patternIndex, paint);

        drawDashedVLine(canvas, leftTop + Offset(textPainter.width, 0),
            textPainter.height, patternIndex, paint);

        drawDashedHLine(
            canvas,
            leftTop + Offset(textPainter.width, textPainter.height),
            -textPainter.width,
            patternIndex,
            paint);

        drawDashedVLine(canvas, leftTop + Offset(0, textPainter.height),
            -textPainter.height, patternIndex, paint);
      }
    } else {
      //円を描く
      if (!selected) {
        canvas.drawCircle(drawPos, radius, paint);
      } else {
        drawDashedCircle(canvas, drawPos, radius, patternIndex, paint);
      }

      //テキストを書く
      if (textPainter != null) {
        final leftTop = Offset(drawPos.dx - textPainter.width / 2.0,
            drawPos.dy - textPainter.height / 2.0);
        Offset textPos;
        switch (subItemPosition) {
          case PrimitiveSubItemPosition.Center:
            textPos = leftTop;
            break;
          case PrimitiveSubItemPosition.Right:
            textPos = leftTop + Offset(radius * 2.0, 0.0);
            break;
          case PrimitiveSubItemPosition.Bottom:
            textPos = leftTop + Offset(0.0, radius * 2.0);
            break;
          case PrimitiveSubItemPosition.Left:
            textPos = leftTop + Offset(-radius * 2.0, 0.0);
            break;
          case PrimitiveSubItemPosition.Top:
            textPos = leftTop + Offset(0.0, -radius * 2.0);
            break;
        }
        if (textPos != null) textPainter.paint(canvas, textPos);
      }
    }
  }

  //線の座標から矢印部分の座標を生成する
  static List<Offset> createArrowOffset(Offset p1, Offset p2,
      {double allowLength = 10.0, allowAngle = 0.55}) {
    Offset v = (p1 - p2);
    v = v / v.distance * allowLength;
    return [
      OffsetEx(v).rotate(allowAngle) + p2,
      OffsetEx(v).rotate(-allowAngle) + p2
    ];
  }

  // Canvasには点線描画が実装されていない...

  //破線の円を描く
  static void drawDashedCircle(Canvas canvas, Offset drawPos, double radius,
      int patternIndex, Paint paint) {
    final radStep = pi / 9.0; //単位長さ
    final radLen = radStep * 0.5; //実線の長さ
    var rad = ((patternIndex & 3) / 4.0) * radStep;
    while (rad < pi * 2.0) {
      final p1 = Offset(
          cos(rad) * radius + drawPos.dx, sin(rad) * radius + drawPos.dy);
      final p2 = Offset(cos(rad + radLen) * radius + drawPos.dx,
          sin(rad + radLen) * radius + drawPos.dy);
      canvas.drawLine(p1, p2, paint);
      rad += radStep;
    }
  }

  //水平方向に破線を描く
  static void drawDashedHLine(
      Canvas canvas, Offset p1, double length, int patternIndex, Paint paint) {
    final stepLen = 10.0; //単位長さ
    final solidLen = stepLen * 0.5; //実線の長さ
    var startOffset = ((patternIndex & 3) / 4.0) * stepLen;
    if (length > 0) {
      length -= startOffset;
      var x = p1.dx + startOffset;
      while (length > 0) {
        canvas.drawLine(
            Offset(x, p1.dy),
            Offset(x + ((solidLen < length) ? solidLen : length), p1.dy),
            paint);
        x += stepLen;
        length -= stepLen;
      }
    } else {
      length = -length - startOffset;
      var x = p1.dx - startOffset;
      while (length > 0) {
        canvas.drawLine(
            Offset(x, p1.dy),
            Offset(x - ((solidLen < length) ? solidLen : length), p1.dy),
            paint);
        x -= stepLen;
        length -= stepLen;
      }
    }
  }

  //垂直方向に破線を描く
  static void drawDashedVLine(
      Canvas canvas, Offset p1, double length, int patternIndex, Paint paint) {
    final stepLen = 10.0; //単位長さ
    final solidLen = stepLen * 0.5; //実線の長さ
    var startOffset = ((patternIndex & 3) / 4.0) * stepLen;
    if (length > 0) {
      length -= startOffset;
      var y = p1.dy + startOffset;
      while (length > 0) {
        canvas.drawLine(
            Offset(p1.dx, y),
            Offset(p1.dx, y + ((solidLen < length) ? solidLen : length)),
            paint);
        y += stepLen;
        length -= stepLen;
      }
    } else {
      length = -length - startOffset;
      var y = p1.dy - startOffset;
      while (length > 0) {
        canvas.drawLine(
            Offset(p1.dx, y),
            Offset(p1.dx, y - ((solidLen < length) ? solidLen : length)),
            paint);
        y -= stepLen;
        length -= stepLen;
      }
    }
  }
}
