import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

//ローカルにはインデックスで保存しているので、順番を変更しないこと！
enum LoginMethod { None, Email, Google }

class SignIn {

  //googleログイン
  //home画面から直接呼び出すこともあるので、staticにしている
  static Future<Map> handleGoogleSignIn() async {
    final googleSignIn = new GoogleSignIn();
    final auth = FirebaseAuth.instance;

    GoogleSignInAccount googleCurrentUser = googleSignIn.currentUser;
    try {
      if (googleCurrentUser == null)
        googleCurrentUser = await googleSignIn.signInSilently();
      if (googleCurrentUser == null)
        googleCurrentUser = await googleSignIn.signIn();
      if (googleCurrentUser == null)
        return {'user': null};

      GoogleSignInAuthentication googleAuth = await googleCurrentUser
          .authentication;
      final AuthCredential credential = GoogleAuthProvider.getCredential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final FirebaseUser user = (await auth.signInWithCredential(credential))
          .user;
      print("signed in " + user.displayName);

      return {'user': user};
    } catch (e) {
      return {'user': null, 'exception': e.toString()};
    }
  }

}
