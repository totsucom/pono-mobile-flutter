import 'dart:math';
import 'dart:ui';

class OffsetEx {
  double _x, _y;
  OffsetEx(Offset ofs) {
    _x = ofs.dx;
    _y = ofs.dy;
  }

  Offset toOffset() {
    return Offset(_x, _y);
  }

  //DB読み込み用
  OffsetEx.fromDbString(String str) {
    List<String> ar = str.split(',');
    assert(ar.length == 2);
    _x = double.parse(ar[0]);
    _y = double.parse(ar[1]);
  }

  //DB保存用
  String toDbString() {
    return '${_x},${_y}';
  }

  //Rectの範囲内にあるか
  bool inRect(Rect rect) {
    return (rect.left <= _x &&
        _x <= rect.right &&
        rect.top <= _y &&
        _y <= rect.bottom);
  }

  //座標を回転
  Offset rotate(double radian) {
    final cosr = cos(radian);
    final sinr = sin(radian);
    final x = _x * cosr - _y * sinr;
    final y = _x * sinr + _y * cosr;
    return Offset(x, y);
  }
}
