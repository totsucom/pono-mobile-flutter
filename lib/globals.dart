import 'package:firebase_auth/firebase_auth.dart';
import 'package:pono_problem_app/records/user.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'my_theme.dart';
import 'signin.dart';

class Globals {
  //ログイン関連
  static FirebaseUser firebaseUser;
  static LoginMethod currentLoginMethod = LoginMethod.None;
  static UserDocument ponoUser;

  //static SharedPreferences _prefs;

  //ログイン方法の取得と設定
  static LoginMethod _loginMethod = LoginMethod.None;
  static LoginMethod get loginMethod => _loginMethod;
  static set loginMethod(LoginMethod newMethod) {
    _loginMethod = newMethod;
  }

  //ダークテーマの取得と設定
  static bool _darkTheme = false;
  static bool get darkTheme => _darkTheme;
  static set darkTheme(bool newTheme) {
    _darkTheme = newTheme;
  }

  //設定を読み込む
  //アプリの最初に１度だけ呼び出す
  static Future<bool> loadSettings() async {
    final _prefs = await SharedPreferences.getInstance();
    assert(_prefs != null);

    var lm = _prefs.getInt("LoginMethod") ?? LoginMethod.None.index;
    _loginMethod = LoginMethod.values[lm];

    _darkTheme = _prefs.getBool("DarkTheme") ?? false;

    return true;
  }

  static Future<bool> saveSettings() async {
    final _prefs = await SharedPreferences.getInstance();
    assert(_prefs != null);
    _prefs.setInt("LoginMethod", loginMethod.index);
    _prefs.setBool("DarkTheme", darkTheme);
    return true;
  }

/*
  static bool _loaded = false;
  static String _usr;
  static String _pwd;
  static LoginType _loginType = LoginType.None;

  //設定を読み込む
  //アプリの最初に１度だけ呼び出す
  static Future<bool> _loadSettings() async {
    if (_loaded) return false;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _usr = prefs.getString("usr");
    _pwd = prefs.getString("pwd");
    final t = prefs.getInt("logintype");
    _loginType = (t != null) ? LoginType.values[t] : LoginType.None;
    _loaded = true;
    return true;
  }

  //現在のログイン方法を取得する
  static LoginType GetLoginType() {
    final result = _loadSettings();
    return _loginType;
  }

  //現在のログイン方法をリセットする
  //ログインの方法を再選択する場合に使用
  static void ResetLoginType() {
    final result = _loadSettings();
    _loginType = LoginType.None;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt("logintype", LoginType.None.index);
    });
  }

  //ログイン方法を設定する
  //ログイン方法によって、usr,pwdは意味が無くなる
  static void SetLoginType(LoginType t, String usr, String pwd) {
    final result = _loadSettings();
    _loginType = t;
    _usr = usr;
    _pwd = pwd;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString("usr", usr);
      prefs.setString("pwd", pwd);
      prefs.setInt("logintype", t.index);
    });
  }*/
}
