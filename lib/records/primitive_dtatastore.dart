import 'package:flutter/cupertino.dart';
import 'package:pono_problem_app/records/primitive.dart';
import 'package:pono_problem_app/records/user_ref.dart';
import 'package:pono_problem_app/records/user_ref_datastore.dart';
import './user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

// primitivesサブコレクションを扱うツール
class PrimitiveDatastore {
  static String getCollectionPath(String problemId) {
    return "problems/$problemId/primitives";
  }

  static String getDocumentPath(String problemId, String documentId) {
    return "problems/$problemId/primitives/$documentId";
  }

  // primitiveを追加する
  //成功時にPrimitiveDocumentを返す
  //exception=false の場合は例外時にnullを返す
  static Future<PrimitiveDocument> addPrimitive(
      String problemId, Primitive primitive, bool exception) async {
    var completer = new Completer<PrimitiveDocument>();
    try {
      final newDoc = Firestore.instance
          .collection(getCollectionPath(problemId))
          .document();

      //FireStoreに追加
      var map = primitive.toMap();
      await newDoc.setData(map);

      debugPrint("追加されたベース写真 documentID = " + newDoc.documentID);
      completer.complete(
          PrimitiveDocument(newDoc.documentID, Primitive.fromMap(map)));
    } catch (e) {
      if (exception)
        completer.completeError(e.toString());
      else
        completer.complete(null);
    }
    return completer.future;
  }

  // primitiveを更新する
  //exception=false の場合は例外時にnullを返す
  static Future<bool> updateUser(
      String problemId, PrimitiveDocument primitiveDoc, bool exception) async {
    var completer = new Completer<bool>();
    try {
      //Firestoreのデータをアップデート
      await Firestore.instance
          .document(getDocumentPath(problemId, primitiveDoc.docId))
          .updateData(primitiveDoc.data.toMap());
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

  // primitiveを取得する
  // exception=false の場合は例外時にnullを返す
  static Future<PrimitiveDocument> getPrimitive(
      String problemId, String documentID, bool exception) async {
    var completer = new Completer<PrimitiveDocument>();
    try {
      final snapshot = await Firestore.instance
          .document(getDocumentPath(problemId, documentID))
          .get();
      if (!snapshot.exists) return null;
      return PrimitiveDocument(
          snapshot.documentID, Primitive.fromMap(snapshot.data));
    } catch (e) {
      if (exception)
        completer.completeError(e.toString());
      else
        completer.complete(null);
    }
    return completer.future;
  }

  // primitiveを削除する
  static Future<bool> deleteUser(
      String problemId, String documentID, bool exception) async {
    var completer = new Completer<bool>();
    try {
      await Firestore.instance
          .document(getDocumentPath(problemId, documentID))
          .delete();
      completer.complete(true);
      debugPrint("delete成功");
    } catch (e) {
      if (exception)
        completer.completeError(e.toString());
      else
        completer.complete(null);
      debugPrint("delete失敗 " + e.toString());
    }
    return completer.future;
  }
}
