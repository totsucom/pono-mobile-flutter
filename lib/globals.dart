import 'package:firebase_auth/firebase_auth.dart';
import 'package:pono_problem_app/records/user.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'my_theme.dart';
import 'authentication.dart';

//※ enumアイテム名で設定に保存するので、名称変更しないこと
enum AuthMethod { None, Google }

class Globals {
  //認証結果
  static FirebaseUser firebaseUser;

  //ログイン結果（ユーザー情報）
  static UserDocument ponoUser;

  //認証方法
  static AuthMethod authMethod = AuthMethod.None;

  //ダークテーマの取得と設定
  static bool darkTheme = false;

  //設定を読み込む
  //アプリの最初に呼び出そう
  static Future<bool> loadSettings() async {
    final _prefs = await SharedPreferences.getInstance();
    assert(_prefs != null);

    authMethod = AuthMethod.values.firstWhere((e) =>
        e.toString() ==
        (_prefs.getString("AuthMethod") ?? AuthMethod.None.toString()));
    darkTheme = _prefs.getBool("DarkTheme") ?? false;

    //TODO デバッグ
    authMethod = AuthMethod.None;

    return true;
  }

  //設定を保存する
  //自動保存されないので注意
  static Future<bool> saveSettings() async {
    /*final _prefs = await SharedPreferences.getInstance();
    assert(_prefs != null);

    _prefs.setString("AuthMethod", authMethod.toString());
    _prefs.setBool("DarkTheme", darkTheme);
    */
    return true;
  }
}
