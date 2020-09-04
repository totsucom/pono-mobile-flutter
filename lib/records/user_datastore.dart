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
    return "users/$documentId";
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
  static Future<UserDocument> addUser(String userID, User user) async {
    var completer = new Completer<UserDocument>();
    try {
      Firestore.instance.runTransaction((Transaction tr) async {
        QuerySnapshot query = await Firestore.instance
            .collection(getCollectionPath())
            .where(UserField.displayName, isEqualTo: user.displayName)
            .getDocuments();

        if (query.documents.length == 0 ||
            (query.documents[0].documentID == userID)) {
          final doc = Firestore.instance
              .collection(getCollectionPath())
              .document(userID);

          //同じdisplayNameの無いときだけ書き込みを行う
          final Map map = user.toMap();
          map[UserField.createdAt] = FieldValue.serverTimestamp();
          tr.set(doc, map);

          completer.complete(UserDocument(userID, User.fromMap(map)));
        } else {
          completer.complete(null);
        }
      });
    } catch (e) {
      debugPrint('UserDatastore.addUser()で例外 ' + e.toString());
      completer.completeError(e.toString());
    }
    return completer.future;
  }

  //userを更新する
  static Future<UserDocument> updateUser(String userID, User user) async {
    var completer = new Completer<UserDocument>();
    try {
      Firestore.instance.runTransaction((Transaction tr) async {
        QuerySnapshot query = await Firestore.instance
            .collection(getCollectionPath())
            .where(UserField.displayName, isEqualTo: user.displayName)
            .getDocuments();

        if (query.documents.length == 0 ||
            (query.documents[0].documentID == userID)) {
          final doc = Firestore.instance
              .collection(getCollectionPath())
              .document(userID);

          //同じdisplayNameの無いときだけ書き込みを行う
          final Map map = user.toMap();
          //作成日は変更しないので削除しておく
          map.remove(UserField.createdAt);
          tr.update(doc, map);

          completer.complete(UserDocument(userID, User.fromMap(map)));
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
  /*
      QuerySnapshot snapshot = await tr
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

      tran.get(postRef).then((DocumentSnapshot snap) {
        if (snap.exists)
          tran.update(postRef,
              <String, dynamic>{"likesCount": snap.data['likesCount'] + 1});
      });
    });

    final Map map = user.toMap();
    map[UserField.createdAt] = FieldValue.serverTimestamp();
    Firestore.instance
        .collection(getCollectionPath())
        .document(userID)
        .setData(map);
  }*/

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
  /*static void addUserT(Transaction transaction, String userID, User user) {
    final Map map = user.toMap();
    map[UserField.createdAt] = FieldValue.serverTimestamp();
    transaction.set(
        Firestore.instance.collection(getCollectionPath()).document(userID),
        map);
  }
*/
/*
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
*/
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

  //userIDからdisplayNameを取得するFutureBuilderを生成する。
  //最初にfirstWidget、ロードが完了したらcompleteTextを表示する。
  //completeText内に (displayName) 文字列があれば、それはdisplayNameに置換される。
  static Widget displayNameFutureBuilder(String userID,
      [Widget firstWidget, String completeText = '{displayName}']) {
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
