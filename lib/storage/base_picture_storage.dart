import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pono_problem_app/records/base_picture.dart';
import 'package:pono_problem_app/storage/storage_result.dart';
import 'package:pono_problem_app/utils/content_type.dart';
import 'package:pono_problem_app/utils/unique.dart';

/*
//Firebase storage内のベース写真を扱う
//BasePictureDatastore経由で使用される
class BasePictureStorage {
  //アップロード時にUI側で調整(ここは定義のみ)
  static const double MAX_WIDTH = 1200;
  static const double MAX_HEIGHT = 1200;

  static String getFolderPath() {
    return "basePictures";
  }

  //アップロード用のユニークなファイルパスを生成
  static getUniqueStoragePath(File file) {
    final fileName = Unique.FileName(file.path);
    return getFolderPath() + '/' + fileName;
  }

  //アップロード
  //filePathにはgetUniqueStoragePath()で取得したパスを渡す
  static Future<StorageResult> upload(File file, String filePath) async {
    var completer = new Completer<StorageResult>();
    try {
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
*/
