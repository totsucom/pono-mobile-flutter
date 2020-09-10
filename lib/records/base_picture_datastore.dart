import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:pono_problem_app/storage/storage_result.dart';
import 'package:pono_problem_app/utils/unique.dart';
import './base_picture.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pono_problem_app/utils/content_type.dart';
import 'dart:async';

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
  static Future<BasePictureDocument> addBasePicture(
      BasePicture basePicture) async {
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
      completer.completeError(e.toString());
    }

    return completer.future;
  }

  //basePictureを更新する
  //成功時にtrue、失敗でnull
  static Future<bool> updateBasePicture(
      BasePictureDocument basePictureDoc) async {
    var completer = new Completer<bool>();
    final Map map = basePictureDoc.data.toMap();

    //更新日を削除する
    map.remove(BasePictureField.createdAt);

    //Firestoreのデータをアップデート
    Firestore.instance
        .document(getDocumentPath(basePictureDoc.docId))
        .updateData(map)
        .then((_) {
      completer.complete(true);
      debugPrint("update成功");
    }).catchError((err) {
      completer.completeError(err.toString());
      debugPrint("update失敗 " + err.toString());
    });
    return completer.future;
  }

  //basePictureを取得する
  //存在しない場合はnullを返す
  static Future<BasePictureDocument> getBasePicture(String documentID) async {
    final snapshot =
        await Firestore.instance.document(getDocumentPath(documentID)).get();
    if (!snapshot.exists) return null;
    return BasePictureDocument(
        snapshot.documentID, BasePicture.fromMap(snapshot.data));
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
  //成功でtrue,失敗でnull
  static Future<bool> deleteBasePicture(String documentID) async {
    var completer = new Completer<bool>();

    try {
      final basePictureDoc = await getBasePicture(documentID);
      final filePath = basePictureDoc.data.picturePath;
      await Firestore.instance.document(getDocumentPath(documentID)).delete();
      await BasePictureStorage.delete(filePath);
      completer.complete(true);
      debugPrint("delete成功");
    } catch (e) {
      completer.completeError(e.toString());
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
  static Future<StorageResult> upload(String localPath) async {
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
      completer.completeError(e.toString());
      debugPrint("upload失敗 " + e.toString());
    }
    return completer.future;
  }

  //削除
  static Future<bool> delete(String path) {
    var completer = new Completer<bool>();
    if (!path.startsWith(getFolderPath())) {
      completer.completeError('$pathは${BasePicture.baseName}ファイルではありません');
    } else {
      final StorageReference ref = FirebaseStorage().ref().child(path);
      ref.delete().then((value) {
        completer.complete(true);
        debugPrint('delete成功');
      }).catchError((err) {
        completer.completeError(err);
        debugPrint('delete失敗 ' + err.toString());
      });
    }
    return completer.future;
  }
}
