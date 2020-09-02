import 'dart:ui';

class RectEx {
  double _x, _y, _w, _h;
  RectEx(Rect rc) {
    _x = rc.left;
    _y = rc.top;
    _w = rc.width;
    _h = rc.height;
  }

  Rect toRect() {
    return Rect.fromLTWH(_x, _y, _w, _h);
  }

  //DB読み込み用
  RectEx.fromDbString(String str) {
    List<String> ar = str.split(',');
    assert(ar.length == 4);
    _x = double.parse(ar[0]);
    _y = double.parse(ar[1]);
    _w = double.parse(ar[2]);
    _h = double.parse(ar[3]);
  }

  //DB保存用
  String toDbString() {
    return '$_x,$_y,$_w,$_h';
  }
}
