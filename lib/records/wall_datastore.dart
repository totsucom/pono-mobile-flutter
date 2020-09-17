import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:pono_problem_app/records/wall.dart';
import 'package:pono_problem_app/storage/storage_result.dart';
import 'package:pono_problem_app/utils/unique.dart';
import './base_picture.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pono_problem_app/utils/content_type.dart';
import 'dart:async';
import 'dart:ui' as UI;

//wallsコレクションを扱うツール
class WallDatastore {
  //Firestoreのコレクション名を返す
  static String getCollectionPath() {
    return "walls";
  }

  //Firestoreのドキュメントパスを返す
  static String getDocumentPath(String documentId) {
    return "walls/$documentId";
  }

  //ドキュメントを追加する
  //成功時にWallDocumentを返す
  //exception=false の場合は例外時にnullを返す
  static Future<WallDocument> addWall(
      String name, bool active, bool exception) async {
    var completer = new Completer<WallDocument>();

    //Wallクラスを生成
    final wall = Wall(name, active, 0);
    DocumentReference newDoc;

    //トランザクションを開始
    Firestore.instance.runTransaction((Transaction tr) async {
      //同じnameを探すクエリ
      var query = await Firestore.instance
          .collection(getCollectionPath())
          .where(WallField.name, isEqualTo: name)
          .getDocuments();

      if (query.documents.length != 0) throw WallField.name + ' は既に使用されています。';

      //最も大きなorderを取得するクエリ
      query = await Firestore.instance
          .collection(getCollectionPath())
          .orderBy(WallField.order, descending: true)
          .limit(1)
          .getDocuments();

      //+1 を新しい表示順にする
      wall.order = (query.documents.length == 0)
          ? 1
          : (query.documents[0].data[WallField.order] + 1);

      //FireStoreに追加
      newDoc = Firestore.instance.collection(getCollectionPath()).document();
      tr.set(newDoc, wall.toMap());
    }).then((_) {
      //完了
      completer.complete(WallDocument(newDoc.documentID, wall));
    }).catchError((err) {
      //失敗
      completer.completeError(err.toString());
    });
    return completer.future;
  }

  //wallのactive更新する
  //成功時にtrueを返す
  //exception=false の場合は例外時にnullを返す
  static Future<bool> updateWallActivation(
      String docId, bool active, bool exception) async {
    var completer = new Completer<bool>();
    try {
      //Firestoreのデータをアップデート
      await Firestore.instance
          .document(getDocumentPath(docId))
          .updateData({WallField.active: active});
      completer.complete(true);
      debugPrint("update成功");
    } catch (e) {
      if (exception)
        completer.completeError(e.toString());
      else
        completer.complete(null);
      debugPrint("update失敗 " + e.toString());
    }
    return completer.future;
  }

  //documentIDの順で表示順を再設定する
  //成功時にtrueを返す
  //exception=false の場合は例外時にnullを返す
  static Future<bool> reorder(List<String> documentIDs, bool exception) async {
    var completer = new Completer<bool>();

    //トランザクションを開始
    Firestore.instance.runTransaction((Transaction tr) {
      for (int i = 0; i < documentIDs.length; i++) {
        Firestore.instance
            .document(getDocumentPath(documentIDs[i]))
            .updateData({WallField.order: i + 1});
      }
    }).then((_) {
      //完了
      completer.complete(true);
    }).catchError((err) {
      //失敗
      completer.completeError(err.toString());
    });
    return completer.future;
  }

  //wall一覧を取得する
  //存在しない場合は[]を返す
  //exception=false の場合は例外時にnullを返す
  static Future<List<WallDocument>> getWalls(
      bool activeOnly, bool exception) async {
    var completer = new Completer<List<WallDocument>>();
    try {
      var querySnapshot;
      if (activeOnly)
        querySnapshot = await Firestore.instance
            .collection(getCollectionPath())
            .where(WallField.active, isEqualTo: true)
            .orderBy(WallField.order)
            .getDocuments();
      else
        querySnapshot = await Firestore.instance
            .collection(getCollectionPath())
            .orderBy(WallField.order)
            .getDocuments();
      var walls = <WallDocument>[];
      querySnapshot.documents.forEach((documentSnapshot) {
        walls.add(WallDocument(
            documentSnapshot.documentID, Wall.fromMap(documentSnapshot.data)));
      });
      completer.complete(walls);
    } catch (e) {
      if (exception)
        completer.completeError(e.toString());
      else
        completer.complete(null);
    }
    return completer.future;
  }

  //StreamBuilder用
  static Stream<QuerySnapshot> getWallsStream(
      {String orderBy = WallField.order, bool descending = false}) {
    return Firestore.instance
        .collection(getCollectionPath())
        .orderBy(orderBy, descending: descending)
        .snapshots();
  }
}
