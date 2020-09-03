import 'package:flutter/material.dart';
import 'globals.dart';

// テーマ変更用の状態クラス
class MyTheme extends ChangeNotifier {
  ThemeMode current = ThemeMode.light;

  void setDark(bool b) {
    Globals.darkTheme = b;
    current = Globals.darkTheme
        ? ThemeMode.dark //ダーク指定
        : ThemeMode.system; //ダーク指定のない場合はシステム依存
    notifyListeners();
  }
}
