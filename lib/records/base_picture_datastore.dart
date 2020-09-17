import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:pono_problem_app/storage/storage_result.dart';
import 'package:pono_problem_app/utils/unique.dart';
import './base_picture.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pono_problem_app/utils/content_type.dart';
import 'dart:async';
import 'dart:ui' as UI;

//basePictureコレクションを扱うツール
class BasePictureDatastore {
  //Firestoreのコレクション名を返す
  static String getCollectionPath() {
    return "basePictures";
  }

  //Firestoreのドキュメントパスを返す
  static String getDocumentPath(String documentId) {
    return "basePictures/$documentId";
  }

  //ドキュメントを追加する
  //成功時にBasePictureDocumentを返す
  //exception=false の場合は例外時にnullを返す
  static Future<BasePictureDocument> addBasePicture(
      BasePicture basePicture, bool exception) async {
    var completer = new Completer<BasePictureDocument>();
    try {
      //BasePictureクラスを生成
      var map = basePicture.toMap();
      map[BasePictureField.createdAt] = FieldValue.serverTimestamp(); //作成日を追加する
      final newDoc =
          Firestore.instance.collection(getCollectionPath()).document();

      //FireStoreに追加
      await newDoc.setData(map);

      debugPrint("追加されたベース写真 documentID = " + newDoc.documentID);
      completer.complete(
          BasePictureDocument(newDoc.documentID, BasePicture.fromMap(map)));
    } catch (e) {
      if (exception)
        completer.completeError(e.toString());
      else
        completer.complete(null);
    }
    return completer.future;
  }

  //basePictureを更新する
  //成功時にtrueを返す
  //exception=false の場合は例外時にnullを返す
  static Future<bool> updateBasePicture(
      BasePictureDocument basePictureDoc, bool exception) async {
    var completer = new Completer<bool>();
    try {
      final Map map = basePictureDoc.data.toMap();

      //作成日を削除する
      map.remove(BasePictureField.createdAt);

      //Firestoreのデータをアップデート
      await Firestore.instance
          .document(getDocumentPath(basePictureDoc.docId))
          .updateData(map);
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

  //basePictureを取得する
  //存在しない場合はnullを返す
  //exception=false の場合は例外時にもnullを返す
  static Future<BasePictureDocument> getBasePicture(
      String documentID, bool exception) async {
    var completer = new Completer<BasePictureDocument>();
    try {
      final snapshot =
          await Firestore.instance.document(getDocumentPath(documentID)).get();
      if (!snapshot.exists) return null;
      return BasePictureDocument(
          snapshot.documentID, BasePicture.fromMap(snapshot.data));
    } catch (e) {
      if (exception)
        completer.completeError(e.toString());
      else
        completer.complete(null);
    }
    return completer.future;
  }

  //getBasePictureを監視(listen)するためのスナップショットを返す
  //この関数の返り値の後にlistenをつけてイベントハンドラを書けばいい
  // .listen((DocumentSnapshot documentSnapshot) { ... })
  static Stream<DocumentSnapshot> getBasePictureSnapshot(String documentID) {
    return Firestore.instance.document(getDocumentPath(documentID)).snapshots();
  }

  //StreamBuilder用
  static Stream<QuerySnapshot> getBasePicturesStream(
      {String orderBy = BasePictureField.createdAt, bool descending = true}) {
    return Firestore.instance
        .collection(getCollectionPath())
        .orderBy(orderBy, descending: descending)
        .snapshots();
  }

  //StreamBuilder用
  static Stream<DocumentSnapshot> getBasePictureStream(String documentID) {
    return Firestore.instance.document(getDocumentPath(documentID)).snapshots();
  }

  //basePictureを削除する
  //成功時にtrueを返す
  //exception=false の場合は例外時にもnullを返す
  static Future<bool> deleteBasePicture(
      String documentID, bool exception) async {
    var completer = new Completer<bool>();
    try {
      final basePictureDoc = await getBasePicture(documentID, true);
      final filePath = basePictureDoc.data.picturePath;
      await Firestore.instance.document(getDocumentPath(documentID)).delete();
      await BasePictureStorage.delete(filePath, true);
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

//Firebase storage内のベース写真を扱う
//BasePictureDatastore経由で使用される
class BasePictureStorage {
  static String getFolderPath() {
    return "basePictures";
  }

  //アップロード
  //exception=false の場合は例外時にnullを返す
  static Future<StorageResult> upload(String localPath, bool exception) async {
    var completer = new Completer<StorageResult>();
    try {
      final storagePath = getFolderPath() + '/' + Unique.FileName(localPath);
      final contentType = ContentType.fromPath(localPath);
      final StorageReference ref = FirebaseStorage().ref().child(storagePath);
      final StorageUploadTask uploadTask = ref.putFile(
          File(localPath), StorageMetadata(contentType: contentType));
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
      debugPrint('$pathは${BasePicture.baseName}ファイルではありません');
      if (exception)
        completer.completeError('$pathは${BasePicture.baseName}ファイルではありません');
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
