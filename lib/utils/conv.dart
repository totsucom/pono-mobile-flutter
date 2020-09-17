import 'dart:ui' as UI;

class Conv {
  //Firestoreにdoubleで0.0を書き込んでも 0として読み出されるため、
  //double <= int 代入でエラーになる。
  //そういうものを回避
  static toDbl(value, {nullValue = 0.0, errorValue}) {
    if (value == null) return nullValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return errorValue;
  }

  //Cloud Functions側でも読みやすいように、 r,g,b 形式文字列に変換
  static String uiColorToString(UI.Color color) {
    return color.red.toString() +
        ',' +
        color.green.toString() +
        ',' +
        color.blue.toString();
  }

  static UI.Color stringToUiColor(String str) {
    try {
      final ar = str.split(',');
      return UI.Color.fromARGB(
          255, int.parse(ar[0]), int.parse(ar[1]), int.parse(ar[2]));
    } catch (e) {
      return UI.Color.fromARGB(255, 0, 0, 0);
    }
  }
}
