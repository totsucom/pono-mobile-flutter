import 'package:flutter/cupertino.dart';

import './user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

//usersコレクションを扱うツール
class UserDatastore {
  static String getCollectionPath() {
    return "users";
  }

  static String getDocumentPath(String documentId) {
    return "users/${documentId}";
  }

  /* documentIDを自動生成する場合
  static String addUser(User user) {
    final newDocument =
    Firestore.instance.collection(getCollectionPath()).document();
    newDocument.setData(user.toMap());
    return newDocument.documentID;
  }*/

  //userを追加する
  //userが存在する場合は上書きしてしまうので、注意すること
  static void addUser(String userID, User user) {
    final Map map = user.toMap();
    map[UserField.createdAt] = FieldValue.serverTimestamp();
    Firestore.instance
        .collection(getCollectionPath())
        .document(userID)
        .setData(map);
  }

  /*static bool addUser2(String userID, User user) {
    final Map map = user.toMap();
    map[UserField.createdAt] = FieldValue.serverTimestamp();
    Firestore.instance.collection(getCollectionPath()).document(userID)
        .setData(map)
    .then((value) {
      return true;
    }).catchError((err) {
      return false;
    });
    //これでは結果を返せない
  }*/
  static void addUserT(Transaction transaction, String userID, User user) {
    final Map map = user.toMap();
    map[UserField.createdAt] = FieldValue.serverTimestamp();
    transaction.set(
        Firestore.instance.collection(getCollectionPath()).document(userID),
        map);
  }

  //userを更新する
  static void updateUser(String userID, User user) {
    var map = user.toMap();
    //作成日は変更しないので削除しておく
    map.remove(UserField.createdAt);
    Firestore.instance
        .collection(getCollectionPath())
        .document(userID)
        .updateData(map);
  }

  //userを取得する
  //userIDが存在しない場合はnullを返す
  static Future<UserDocument> getUser(String userID) async {
    final snapshot =
        await Firestore.instance.document(getDocumentPath(userID)).get();
    return (!snapshot.exists)
        ? null
        : new UserDocument(userID, User.fromMap(snapshot.data));
  }
  /*static Future<User> getUserT(Transaction transaction, String userID) async {
    final snapshot = await transaction
        .get(Firestore.instance.document(getDocumentPath(userID)));
    return snapshot.exists ? User.fromMap(snapshot.data) : null;
  }*/

  //userIDからdisplayNameを取得するFutureBuilderを生成する。
  //最初にfirstWidget、ロードが完了したらcompleteTextを表示する。
  //completeText内に (displayName) 文字列があれば、それはdisplayNameに置換される。
  static Widget displayNameFutureBuilder(String userID,
      [Widget firstWidget = null, String completeText = '{displayName}']) {
    return FutureBuilder(
        future: UserDatastore.getUser(userID),
        builder: (context, future) {
          if (!future.hasData || future.data == null) {
            return (firstWidget == null) ? Text('') : firstWidget;
          }
          final UserDocument userDoc = future.data;
          return Text(completeText.replaceAll(
              '{displayName}', userDoc.user.displayName));
        });
  }

  //userを削除する
  static void deleteUser(String userID) {
    Firestore.instance.document(getDocumentPath(userID)).delete();
  }
}
