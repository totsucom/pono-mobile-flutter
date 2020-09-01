import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:pono_problem_app/storage/base_picture_storage.dart';
import 'package:pono_problem_app/storage/storage_result.dart';
import 'package:pono_problem_app/utils/unique.dart';
import './base_picture.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pono_problem_app/utils/content_type.dart';
import 'dart:async';

//basePictureコレクションを扱うツール
class BasePictureDatastore {
  //ベース写真の大きさ(ここは定義のみ)
  //アップロード時にUI側で調整
  static const double BASE_PICTURE_MAX_WIDTH = 1200;
  static const double BASE_PICTURE_MAX_HEIGHT = 1200;

  //Firestoreのコレクション名を返す
  static String getCollectionPath() {
    return "basePictures";
  }

  //Firestoreのドキュメントパスを返す
  static String getDocumentPath(String documentId) {
    return "basePictures/${documentId}";
  }

  //ドキュメントを追加する
  //成功時にDocumentIDを返す
  static Future<String> addBasePicture(
      String name, String userID, File file) async {
    var completer = new Completer<String>();
    try {
      //ベース写真をアップロード
      final result = await _BasePictureStorage.upload(file);

      //BasePictureクラスを生成
      var map = BasePicture(name, result.path, userID, pictureURL: result.url)
          .toMap();
      //作成日を追加する
      map[BasePictureField.createdAt] = FieldValue.serverTimestamp();
      final newDoc =
          Firestore.instance.collection(getCollectionPath()).document();

      //FireStoreに追加
      await newDoc.setData(map);

      debugPrint("追加されたベース写真 documentID = " + newDoc.documentID);
      completer.complete(newDoc.documentID);
    } catch (e) {
      completer.completeError(e.toString());
    }

    return completer.future;
  }

/*
  static void addBasePictureT(
      Transaction transaction, BasePicture basePicture) {
    final Map map = basePicture.toMap();
    //作成日を追加する
    map[BasePictureField.createdAt] = FieldValue.serverTimestamp();
    transaction.set(
        Firestore.instance.collection(getCollectionPath()).document(), map);
  }
*/
  //basePictureを更新する
  //成功時にtrue、失敗でnull
  static Future<bool> updateBasePicture(
      String documentID, BasePicture basePicture) async {
    var completer = new Completer<bool>();
    final Map map = basePicture.toMap();

    //更新日を削除する
    map.remove(BasePictureField.createdAt);

    //Firestoreのデータをアップデート
    Firestore.instance
        .document(getDocumentPath(documentID))
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
/*  static Future<DatastoreResult> updateBasePicture(
      String documentID, BasePicture basePicture) async {
    var completer = new Completer<DatastoreResult>();
    final Map map = basePicture.toMap();

    //更新日を削除する
    map.remove(BasePictureField.createdAt);

    //Firestoreのデータをアップデート
    Firestore.instance
        .document(getDocumentPath(documentID))
        .updateData(map)
        .then((_) {
      completer.complete(DatastoreResult(true));
      debugPrint("update成功");
    }).catchError((err) {
      completer.complete(DatastoreResult(false, errorMessage: err.toString()));
      debugPrint("update失敗 " + err.toString());
    });
    return completer.future;
  }*/

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

  /*
  //basePicture[]を取得する
  //存在しない場合はnullではなく[]を返す
  static Future<List<BasePictureDocument>> getBasePictures() async {
    final snapshot =
        await Firestore.instance.collection(getCollectionPath()).getDocuments();
    var basePictureDocs = <BasePictureDocument>[];
    snapshot.documents.forEach((element) {
      if (element.exists) {
        basePictureDocs.add(new BasePictureDocument(
            element.documentID, BasePicture.fromMap(element.data)));
      }
    });
    return basePictureDocs;
  }
*/
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

  /*static Stream<DocumentSnapshot> getBasePictureStream(String documentID) {
    return Firestore.instance.document(getDocumentPath(documentID)).snapshots();
  }*/
  /*static Future<BasePicture> getBasePictureT(Transaction transaction,
      String documentID) async {
    final snapshot = await transaction
        .get(Firestore.instance.document(getDocumentPath(documentID)));
    return snapshot.exists ? BasePicture.fromMap(snapshot.data) : null;
  }*/

  //basePictureを削除する
  //成功でtrue,失敗でnull
  static Future<bool> deleteBasePicture(String documentID) async {
    var completer = new Completer<bool>();

    try {
      final basePictureDoc = await getBasePicture(documentID);
      final filePath = basePictureDoc.basePicture.picturePath;
      await Firestore.instance.document(getDocumentPath(documentID)).delete();
      await _BasePictureStorage.delete(filePath);
      completer.complete(true);
      debugPrint("delete成功");
    } catch (e) {
      completer.completeError(e.toString());
      debugPrint("delete失敗 " + e.toString());
    }
    /*Firestore.instance.document(getDocumentPath(documentID)).delete().then((_) {
      completer.complete(true);
      debugPrint("delete成功");
    }).catchError((err) {
      completer.completeError(err.toString());
      debugPrint("delete失敗 " + err.toString());
    });*/
    return completer.future;
  }
/*  static Future<DatastoreResult> deleteBasePicture(String documentID) async {
    var completer = new Completer<DatastoreResult>();
    Firestore.instance.document(getDocumentPath(documentID)).delete().then((_) {
      completer.complete(DatastoreResult(true));
      debugPrint("delete成功");
    }).catchError((err) {
      completer.complete(DatastoreResult(false, errorMessage: err.toString()));
      debugPrint("delete失敗 " + err.toString());
    });
    return completer.future;
  }*/

}

//Firebase storage内のベース写真を扱う
//BasePictureDatastore経由で使用される
class _BasePictureStorage {
  static String getFolderPath() {
    return "basePictures";
  }

  //アップロード
  static Future<StorageResult> upload(File file) async {
    var completer = new Completer<StorageResult>();
    try {
      final filePath = getFolderPath() + '/' + Unique.FileName(file.path);
      final contentType = ContentType.fromPath(file.path);
      final StorageReference ref = FirebaseStorage().ref().child(filePath);
      final StorageUploadTask uploadTask =
          ref.putFile(file, StorageMetadata(contentType: contentType));
      StorageTaskSnapshot snapshot = await uploadTask.onComplete;
      final downloadURL = await snapshot.ref.getDownloadURL();
      completer.complete(StorageResult(path: filePath, url: downloadURL));
      debugPrint("upload成功");
    } catch (e) {
      completer.completeError(e.toString());
      debugPrint("upload失敗 " + e.toString());
    }
    return completer.future;
  }

  //削除
  static Future<bool> delete(String filePath) {
    var completer = new Completer<bool>();
    if (!filePath.startsWith(getFolderPath())) {
      completer.completeError('${filePath}は${BasePicture.baseName}ファイルではありません');
    } else {
      final StorageReference ref = FirebaseStorage().ref().child(filePath);
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
