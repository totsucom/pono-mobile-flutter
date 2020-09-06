import 'package:flutter/cupertino.dart';
import './user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

// usersコレクションを扱うツール
class UserDatastore {
  static String getCollectionPath() {
    return "users";
  }

  static String getDocumentPath(String documentId) {
    return "users/$documentId";
  }

  // userを追加する
  // userが存在する場合は上書きしてしまうので、注意すること
  // 履歴 2020/9/5 ドキュメントIDを自動生成に変更。Firebaseuser.uidとUserの関連付け
  // はUserReferenceを用いる
  static Future<UserDocument> addUser(/*String userID,*/ User user) async {
    debugPrint('UserDatastore.addUser() が実行されたぞ');

    var completer = new Completer<UserDocument>();
    try {
      //同じdisplayNameを探すクエリ
      final query = await Firestore.instance
          .collection(getCollectionPath())
          .where(UserField.displayName, isEqualTo: user.displayName)
          .getDocuments();

      //トランザクションを開始
      Firestore.instance.runTransaction((Transaction tr) async {
        if (query.documents.length == 0) {
          //displayNameが重複してなかった

          //新しいUserを書き込み
          final doc = Firestore.instance
              .collection(getCollectionPath())
              .document(); //userID);
          final Map map = user.toMap();
          map[UserField.createdAt] = FieldValue.serverTimestamp();
          tr.set(doc, map);

          //完了
          completer.complete(UserDocument(doc.documentID, User.fromMap(map)));
        } else {
          //失敗
          completer.completeError('表示名が重複しています');
        }
      });
    } catch (e) {
      //失敗（例外）
      debugPrint('UserDatastore.addUser()で例外 ' + e.toString());
      completer.completeError(e.toString());
    }
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
          //作成日は変更しないので削除しておく
          map.remove(UserField.createdAt);
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
  static Future<UserDocument> getUser(String userID) async {
    DocumentSnapshot snapshot;
    try {
      snapshot =
          await Firestore.instance.document(getDocumentPath(userID)).get();
    } catch (e) {
      // ※コレクションが存在しないとき、 .exists で返さず、多くの場合で OFFLINE 例外を
      // 発生してしまう。（ドキュメントでは.existsが正解）
      // https://cloud.google.com/firestore/docs/query-data/get-data?hl=ja
      // そのため、しかたなく例外処理を追加した 2020/9/4
      debugPrint('UserDatastore.getUser()で例外 ' + e.toString());
      return null;
    }
    return (!snapshot.exists)
        ? null
        : new UserDocument(userID, User.fromMap(snapshot.data));
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
