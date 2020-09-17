//problemsコレクションを扱うツール
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as UI;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:pono_problem_app/records/primitive_dtatastore.dart';
import 'package:pono_problem_app/records/problem.dart';
import 'package:pono_problem_app/storage/storage_result.dart';
import 'package:pono_problem_app/utils/content_type.dart';
import 'package:pono_problem_app/utils/unique.dart';

import 'base_picture.dart';

class ProblemDatastore {
  //Firestoreのコレクション名を返す
  static String getCollectionPath() {
    return "problems";
  }

  //Firestoreのドキュメントパスを返す
  static String getDocumentPath(String documentId) {
    return "problems/$documentId";
  }

  //ドキュメントを追加する
  //成功時にBasePictureDocumentを返す
  //exception=false の場合は例外時にnullを返す
  static Future<ProblemDocument> addProblem(
      Problem problem, bool exception) async {
    var completer = new Completer<ProblemDocument>();
    try {
      var map = problem.toMap();
      map[ProblemField.createdAt] = FieldValue.serverTimestamp(); //作成日を追加する
      map[ProblemField.updatedAt] = FieldValue.serverTimestamp(); //更新日を追加する
      if (problem.status == ProblemStatus.Public)
        map[ProblemField.publishedAt] = FieldValue.serverTimestamp(); //公開日を追加する

      final newDoc =
          Firestore.instance.collection(getCollectionPath()).document();

      //FireStoreに追加
      await newDoc.setData(map);
      debugPrint("追加された課題 documentID = " + newDoc.documentID);
      ProblemDocument newProblem =
          ProblemDocument(newDoc.documentID, Problem.fromMap(map));

      /*
      上記の追加もトランザクションに含めてしまうと、プリミティブの追加時にサーバー側のルールで
      課題のユーザーＩＤをうまく取得できない（トランザクションは取得をさきに済ましておくルールに
      反するからだと思われる）ため、処理を分離した
      */

      Firestore.instance.runTransaction((Transaction tr) async {
        problem.primitives.forEach((primitive) async {
          final newPrimDoc = Firestore.instance
              .collection(
                  PrimitiveDatastore.getCollectionPath(newDoc.documentID))
              .document();
          await tr.set(newPrimDoc, primitive.toMap());
          debugPrint("追加されたプリミティブ documentID = " + newPrimDoc.documentID);
          newProblem.data.primitives.add(primitive);
        });
      }).then((_) {
        debugPrint("トランザクションは成功しました");
        completer.complete(newProblem);
      }).catchError((err) {
        debugPrint("トランザクションは失敗しました " + err.toString());
        ProblemDatastore.deleteProblem(newDoc.documentID, true).then((_) {
          debugPrint('プリミティブの追加に失敗したので課題を削除しました');
        }).catchError((err) {
          debugPrint(
              'プリミティブの追加に失敗したので課題を削除しようとしましたが、それも失敗してしもうた ' + err.toString());
        });
        if (exception)
          completer.completeError(err.toString());
        else
          completer.complete(null);
      });
    } catch (e) {
      if (exception)
        completer.completeError(e.toString());
      else
        completer.complete(null);
    }
    return completer.future;
  }

/*
  //problemを追加する
  //成功時にDocumentIDを返す
  static Future<String> addProblem(Problem problem, UI.Image basePicture, UI.Image completedImage) async {
    var completer = new Completer<String>();
    try {
      final storageResult = await ProblemBasePictureStorage.upload(basePicture);




    var map = problem.toMap();
    //作成日を追加する
    map[ProblemField.createdAt] = FieldValue.serverTimestamp();
    map.remove(ProblemField.updatedAt);
    final newDocument = Firestore.instance.collection(getCollectionPath())
        .document();
    newDocument.setData(map);
    return newDocument.documentID;
  }
  static void addProblemT(Transaction transaction, Problem problem) {
    final Map map = problem.toMap();
    //作成日を追加する
    map[ProblemField.createdAt] = FieldValue.serverTimestamp();
    map.remove(ProblemField.updatedAt);
    transaction.set(
        Firestore.instance.collection(getCollectionPath()).document(), map);
  }

  //userを更新する
  static void updateProblem(String documentID, Problem problem) {
    final Map map = problem.toMap();
    //更新日を変更する
    map[ProblemField.updatedAt] = FieldValue.serverTimestamp();
    map.remove(ProblemField.createdAt);
    Firestore.instance.collection(getCollectionPath()).document(documentID)
        .setData(map);
  }
  static void updateProblemT(Transaction transaction, String documentID,
      Problem problem) {
    final Map map = problem.toMap();
    //更新日を変更する
    map[ProblemField.updatedAt] = FieldValue.serverTimestamp();
    map.remove(ProblemField.createdAt);
    transaction.update(Firestore.instance.collection(getCollectionPath())
        .document(documentID), map);
  }

  //problemを取得する
  //documentIDが存在しない場合はnullを返す
  static Future<Problem> getProblem(String documentID) async {
    final snapshot = await Firestore.instance
        .document(getDocumentPath(documentID)).get();
    return snapshot.exists ? Problem.fromMap(snapshot.data) : null;
  }
  static Future<Problem> getProblemT(Transaction transaction,
      String documentID) async {
    final snapshot = await transaction
        .get(Firestore.instance.document(getDocumentPath(documentID)));
    return snapshot.exists ? Problem.fromMap(snapshot.data) : null;
  }
*/
  //problemを削除する
  static Future<bool> deleteProblem(String documentID, bool exception) async {
    var completer = new Completer<bool>();
    try {
      await Firestore.instance.document(getDocumentPath(documentID)).delete();
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

  //StreamBuilder用
  static Stream<QuerySnapshot> getProblemStream(
      {String orderBy = ProblemField.publishedAt, bool descending = true}) {
    return Firestore.instance
        .collection(getCollectionPath())
        .orderBy(orderBy, descending: descending)
        .snapshots();
  }
}

//Firebase storage内の課題の背景写真を扱う
//ProblemDatastore経由で使用される
class ProblemStorage {
  static String getFolderPath() {
    return "problemImages";
  }

  //アップロード
  //exception=false の場合は例外時にnullを返す
  static Future<StorageResult> upload(UI.Image uiImage, bool exception) async {
    var completer = new Completer<StorageResult>();
    try {
      ByteData bd = await uiImage.toByteData(format: UI.ImageByteFormat.png);
      Uint8List li = bd.buffer.asUint8List();
      final contentType = ContentType.Png;

      final storagePath = getFolderPath() + '/' + Unique.FileName('.png');
      //final contentType = ContentType.fromPath(localPath);
      final StorageReference ref = FirebaseStorage().ref().child(storagePath);
      //final StorageUploadTask uploadTask = ref.putFile(
      //    File(localPath), StorageMetadata(contentType: contentType));
      final StorageUploadTask uploadTask =
          ref.putData(li, StorageMetadata(contentType: contentType));

      StorageTaskSnapshot snapshot = await uploadTask.onComplete;
      final downloadURL = await snapshot.ref.getDownloadURL();
      completer.complete(StorageResult(path: storagePath, url: downloadURL));
      debugPrint("upload成功 " + storagePath + " " + downloadURL);
    } catch (e) {
      if (exception)
        completer.completeError(e.toString());
      else
        completer.complete(null);
      debugPrint("upload失敗 " + e.toString());
    }
    return completer.future;
  }

  //削除
  //exception=false の場合は例外時にnullを返す
  static Future<bool> delete(String path, bool exception) {
    var completer = new Completer<bool>();
    if (!path.startsWith(getFolderPath())) {
      debugPrint(
          '$pathは${Problem.baseName}の${BasePicture.baseName}ファイルではありません');
      if (exception)
        completer.completeError(
            '$pathは${Problem.baseName}の${BasePicture.baseName}ファイルではありません');
      else
        completer.complete(null);
    } else {
      final StorageReference ref = FirebaseStorage().ref().child(path);
      ref.delete().then((value) {
        completer.complete(true);
        debugPrint('delete成功');
      }).catchError((err) {
        if (exception)
          completer.completeError(err);
        else
          completer.complete(null);
        debugPrint('delete失敗 ' + err.toString());
      });
    }
    return completer.future;
  }
}
