import 'dart:async';
import 'dart:io';
import 'dart:ui' as UI;
import 'package:flutter/cupertino.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pono_problem_app/records/problem.dart';
import 'package:pono_problem_app/storage/storage_result.dart';
import 'package:pono_problem_app/utils/content_type.dart';
import 'package:pono_problem_app/utils/unique.dart';

//Firebase storage内の完了したイメージを扱う
//ProblemDatastore経由で使用される
class ProblemCompletedImageStorage {
  //アップロード時に調整
  static const double MAX_WIDTH = 1200;
  static const double MAX_HEIGHT = 1200;

  static String getFolderPath() {
    return "problemImages/completedImages";
  }

  //アップロード
  static Future<StorageResult> upload(UI.Image image) async {
    var completer = new Completer<StorageResult>();
    try {
      final contentType = ContentType.Jpeg;
      final fileName = Unique.FileName('dummy.jpg');
      final filePath = getFolderPath() + '/' + fileName;
      final StorageReference ref = FirebaseStorage().ref().child(filePath);

      //TODO 型だけ合わせてみたが、うまくいくかわからん
      final data = (await image.toByteData()).buffer.asUint8List();
      final StorageUploadTask uploadTask =
          ref.putData(data, StorageMetadata(contentType: contentType));

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
      completer.completeError('$filePathは${Problem.baseName}のベース写真ファイルではありません');
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
