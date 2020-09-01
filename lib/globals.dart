import 'package:firebase_auth/firebase_auth.dart';
import 'package:pono_problem_app/records/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'signin.dart';

class Globals {
  //パブリック
  static FirebaseUser firebaseUser;
  static LoginMethod currentLoginMethod = LoginMethod.None;

  static User ponoUser;


  static const EMPTY_IMAGE = 'https://firebasestorage.googleapis.com/v0/b/pono-a5755.appspot.com/o/images%2Fempty.jpg?alt=media&token=6af7f9d0-bf73-4bd2-9260-b0abf89026a8';


  //プライベート
  static SharedPreferences _prefs;
  static LoginMethod _loginMethod = LoginMethod.None;


  static LoginMethod getLoginMethod() {
    return _loginMethod;
  }

  static setLoginMethod(LoginMethod lm) {
    _loginMethod = lm;
    _prefs.setInt("LoginMethod", lm.index);
  }


  //設定を読み込む
  //アプリの最初に１度だけ呼び出す
  static Future<bool> loadSettings() async {
    _prefs = await SharedPreferences.getInstance();

    var lm = _prefs.getInt("LoginMethod");
    _loginMethod = (lm == null) ? LoginMethod.None : LoginMethod.values[lm];

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
