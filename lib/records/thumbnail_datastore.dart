import 'dart:ffi';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import './thumbnail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

/*
* サムネイルの作成、削除はFunctionsに実装されているため
* ここでは主に取得系のみを実装する
* */

//thumbnailコレクションを扱うツール
class ThumbnailDatastore {
  static String getCollectionPath() {
    return "thumbnails";
  }

  static String getDocumentPath(String documentId) {
    return "thumbnails/${documentId}";
  }

  //thumbnailを取得する
  //存在しない場合はnullを返す
  static Future<ThumbnailDocument> getThumbnail(String picturePath) async {
    final docID = picturePath.replaceAll('\\', ':').replaceAll('/', ':');
    final snapshot =
        await Firestore.instance.document(getDocumentPath(docID)).get();
    return (!snapshot.exists)
        ? null
        : new ThumbnailDocument(
            snapshot.documentID, Thumbnail.fromMap(snapshot.data));
/*
    Firestore.instance.document(getDocumentPath(docID)).get().then((snapshot) {
        return new ThumbnailDocument(snapshot.documentID, Thumbnail.fromMap(snapshot.data));
    }).catchError((){
        throw Error();
    });*/
  }

  //サムネイル画像ウイジェットを返す
  //サムネイルはベース写真登録後に遅れて生成されるので、FutureBuilderではうまくいかない
  static Widget thumbnailStreamBuilder(
      BuildContext context, String picturePath) {
    final docID = picturePath.replaceAll('\\', ':').replaceAll('/', ':');
    return StreamBuilder<DocumentSnapshot>(
      stream: Firestore.instance.document(getDocumentPath(docID)).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data.data == null) // <= nullチェック必要
          return Icon(Icons.sync); //LinearProgressIndicator()だとレイアウトエラーの可能性あり
        final ThumbnailDocument thumbDoc = ThumbnailDocument(
            snapshot.data.documentID, Thumbnail.fromMap(snapshot.data.data));
        return CachedNetworkImage(
          imageUrl: thumbDoc.thumbnail.thumbnailURL,
          placeholder: (context, url) =>
              Icon(Icons.sync), //CircularProgressIndicator()だとレイアウトエラーの可能性あり
          errorWidget: (context, url, error) => Icon(Icons.error),
        );
      },
    );
  }
}
