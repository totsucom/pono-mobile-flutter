import 'package:flutter/cupertino.dart';
import 'package:pono_problem_app/records/user_ref.dart';
import 'package:pono_problem_app/records/user_ref_datastore.dart';
import './user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

// usersコレクションを扱うツール
class UserDatastore {
  static String getCollectionPath() {
    return "users";
  }

  //documentId = FirebaseUser.uid
  static String getDocumentPath(String documentId) {
    return "users/$documentId";
  }

  // userを追加する
  static Future<UserDocument> addUser(String uid, User user) async {
    var completer = new Completer<UserDocument>();
    Map map;

    //トランザクションを開始
    Firestore.instance.runTransaction((Transaction tr) async {
      //同じdisplayNameを探すクエリ
      final query = await Firestore.instance
          .collection(getCollectionPath())
          .where(UserField.displayName, isEqualTo: user.displayName)
          .getDocuments();

      if (query.documents.length != 0)
        throw UserField.displayName + ' は既に使用されています。';

      //新しいUserを書き込み
      final doc =
          Firestore.instance.collection(getCollectionPath()).document(uid);
      map = user.toMap();
      map[UserField.createdAt] = FieldValue.serverTimestamp();
      map[UserField.updatedAt] = FieldValue.serverTimestamp();
      tr.set(doc, map);
    }).then((_) {
      //完了
      completer.complete(UserDocument(uid, User.fromMap(map)));
    }).catchError((err) {
      //失敗
      completer.completeError(err.toString());
    });

    return completer.future;
  }

  // userを更新する
  static Future<UserDocument> updateUser(UserDocument userDoc) async {
    var completer = new Completer<UserDocument>();
    try {
      //トランザクションを開始
      Firestore.instance.runTransaction((Transaction tr) async {
        //displayNameの重複チェック
        QuerySnapshot query = await Firestore.instance
            .collection(getCollectionPath())
            .where(UserField.displayName, isEqualTo: userDoc.data.displayName)
            .getDocuments();

        if (query.documents.length == 0 ||
            (query.documents[0].documentID == userDoc.docId)) {
          //重複してなかったので書き込み
          final doc = Firestore.instance
              .collection(getCollectionPath())
              .document(userDoc.docId);

          //同じdisplayNameの無いときだけ書き込みを行う
          final Map map = userDoc.data.toMap();
          map.remove(UserField.createdAt); //作成日は変更しないので削除しておく
          map[UserField.updatedAt] = FieldValue.serverTimestamp();
          tr.update(doc, map);

          completer.complete(UserDocument(userDoc.docId, User.fromMap(map)));
        } else {
          completer.complete(null);
        }
      });
    } catch (e) {
      debugPrint('UserDatastore.updateUser()で例外 ' + e.toString());
      completer.completeError(e.toString());
    }
    return completer.future;
  }

  // userを取得する
  // userIDが存在しない場合はnullを返す
  static Future<UserDocument> getUser(String uid) async {
    DocumentSnapshot snapshot;
    try {
      snapshot = await Firestore.instance.document(getDocumentPath(uid)).get();
    } catch (e) {
      // TODO
      // ※コレクションが存在しないとき、 .exists で返さず、多くの場合で OFFLINE 例外を
      // 発生してしまう。（ドキュメントでは.existsが正解）
      // https://cloud.google.com/firestore/docs/query-data/get-data?hl=ja
      // そのため、しかたなく例外処理を追加した 2020/9/4
      debugPrint('UserDatastore.getUser()で例外 ' + e.toString());
      return null;
    }
    return (!snapshot.exists)
        ? null
        : new UserDocument(uid, User.fromMap(snapshot.data));
  }

  // displayNameからuserを取得する
  // 存在しない場合はnullを返す
  static Future<UserDocument> getUserFromDisplayName(String displayName) async {
    QuerySnapshot snapshot;
    try {
      snapshot = await Firestore.instance
          .collection(getCollectionPath())
          .where(UserField.displayName, isEqualTo: displayName)
          .getDocuments();
    } catch (e) {
      //例外処理を行っているのは、getUser()の真似
      debugPrint('UserDatastore.getUserFromDisplayName()で例外 ' + e.toString());
      return null;
    }
    return (snapshot.documents.length == 0)
        ? null
        : new UserDocument(snapshot.documents[0].documentID,
            User.fromMap(snapshot.documents[0].data));
  }

  //userを削除する
  static void deleteUser(String userID) {
    Firestore.instance.document(getDocumentPath(userID)).delete();
  }

  // userを取得するストリーム
  static Stream<DocumentSnapshot> getUserStream(String userID) {
    return Firestore.instance.document(getDocumentPath(userID)).snapshots();
  }
}
