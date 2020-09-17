import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pono_problem_app/records/user.dart';
import 'package:pono_problem_app/records/user_datastore.dart';
import 'dart:ui' as UI;

/*
画面全体ウイジェット
  loading
  error
  empty

スナックバーウイジェット
  successfulSnackBar
  informationSnackBar
  hintSnackBar
  errorSnackBar

取得系ウイジェット
  getCircleAvatar
  getCircleAvatarFromUserID
  getDisplayName
  getImageFuture

*/

class MyWidget {
  // FutureBuilderの待ちなどに
  static Widget loading(BuildContext context,
      {String text = '読み込み中です...。', bool scaffold = false}) {
    final widget = Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
          Container(
              padding: const EdgeInsets.all(16.0),
              width: 64.0,
              height: 64.0,
              child: CircularProgressIndicator()),
          Padding(padding: const EdgeInsets.all(16.0), child: Text(text)),
        ]));
    if (!scaffold) return widget;
    return Scaffold(
      appBar: AppBar(),
      body: widget,
    );
  }

  // FutureBuilderのエラー表示などに
  static Widget error(BuildContext context,
      {String text = 'エラーが発生しました。', String detail, bool scaffold = false}) {
    final widget = Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
          Padding(
              padding: const EdgeInsets.all(16.0),
              child: Icon(Icons.error,
                  size: 64.0, color: Theme.of(context).errorColor)),
          Padding(padding: const EdgeInsets.all(16.0), child: Text(text)),
          if (detail != null)
            Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(detail, style: TextStyle(fontSize: 10)))
        ]));
    if (!scaffold) return widget;
    return Scaffold(
      appBar: AppBar(),
      body: widget,
    );
  }

  // 表示するものが無い場合に
  static Widget empty(BuildContext context,
      {String message = '', bool scaffold = false}) {
    final widget = Center(child: Text(message));
    if (!scaffold) return widget;
    return Scaffold(
      appBar: AppBar(),
      body: widget,
    );
  }

  // 成功ウイジェット。表示まで含める場合は MyDialog.successfulSnackBar（） を使う
  static Widget successfulSnackBar(String text, {int displaySeconds = 10}) {
    return SnackBar(
      content: Row(children: <Widget>[
        Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Icon(Icons.check, color: Colors.greenAccent)),
        Expanded(child: Text(text))
      ]),
      duration: Duration(seconds: displaySeconds),
      action: SnackBarAction(
        label: 'OK',
        onPressed: () {},
      ),
    );
  }

  // 情報ウイジェット。表示まで含める場合は MyDialog.informationSnackBar（） を使う
  static informationSnackBar(String text, {int displaySeconds = 10}) {
    return SnackBar(
      content: Row(children: <Widget>[
        Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Icon(Icons.info_outline, color: Colors.blueAccent)),
        Expanded(child: Text(text))
      ]),
      duration: Duration(seconds: displaySeconds),
      action: SnackBarAction(
        label: 'OK',
        onPressed: () {},
      ),
    );
  }

  // ヒントウイジェット。表示まで含める場合は MyDialog.hintSnackBar（） を使う
  static hintSnackBar(String text, {int displaySeconds = 10}) {
    return SnackBar(
      content: Row(children: <Widget>[
        Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Icon(Icons.lightbulb_outline, color: Colors.yellow)),
        Expanded(child: Text(text))
      ]),
      duration: Duration(seconds: displaySeconds),
      action: SnackBarAction(
        label: 'OK',
        onPressed: () {},
      ),
    );
  }

  // エラーウイジェット。表示まで含める場合は MyDialog.errorSnackBar（） を使う
  static errorSnackBar(String text, {int displaySeconds = 10}) {
    return SnackBar(
      content: Row(children: <Widget>[
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            child: Icon(
              Icons.error,
              color: Colors.redAccent,
            )),
        Expanded(child: Text(text))
      ]),
      duration: Duration(seconds: displaySeconds),
      action: SnackBarAction(
        label: 'OK',
        onPressed: () {},
      ),
    );
  }

  // ユーザーから安全にアバターウィジェットを作成
  static Widget getCircleAvatar(String iconURL) {
    if (iconURL == null || iconURL.length == 0) {
      return CircleAvatar(
        backgroundImage: AssetImage('images/user_image_64.png'),
        backgroundColor: Colors.black12,
      );
    } else {
      return CircleAvatar(
        backgroundImage: CachedNetworkImageProvider(iconURL),
        backgroundColor: Colors.transparent,
      );
    }
  }

  // ユーザーIDから安全にアバターウィジェットを作成
  static Widget getCircleAvatarFromUserID(String userID, [Widget firstWidget]) {
    return FutureBuilder(
        future: UserDatastore.getUser(userID),
        builder: (context, future) {
          if (!future.hasData || future.data == null) {
            return (firstWidget == null) ? Text('') : firstWidget;
          }
          final UserDocument userDoc = future.data;
          return getCircleAvatar(userDoc.data.iconURL);
        });
  }

  // userIDからdisplayNameを取得するFutureBuilderを生成する。
  // 最初にfirstWidget、ロードが完了したらcompleteTextを表示する。
  // completeText内に (displayName) 文字列があれば、それはdisplayNameに置換される。
  static Widget getDisplayName(String userID,
      [Widget firstWidget, String completeText = '{displayName}']) {
    return FutureBuilder(
        future: UserDatastore.getUser(userID),
        builder: (context, future) {
          if (!future.hasData || future.data == null) {
            return (firstWidget == null) ? Text('') : firstWidget;
          }
          final UserDocument userDoc = future.data;
          return Text(completeText.replaceAll(
              '{displayName}', userDoc.data.displayName));
        });
  }

  //FutureBuilder用
  //イメージをURLまたはパスから読み込む
  //関数本体ではなく、関数の返り値を変数に格納して FutureBuilder に渡す。
  //そうしないと何度もダウンロードが発生するので注意
  static Future<UI.Image> getImageFuture({String url, String path}) async {
    var completer = new Completer<UI.Image>();
    if (url != null && url.length > 0) {
      try {
        final bundle = await NetworkAssetBundle(Uri.parse(url)).load(url);
        Uint8List bytes = bundle.buffer.asUint8List();
        UI.Image img = await decodeImageFromList(bytes);
        completer.complete(img);
      } catch (e) {
        completer.completeError(e);
      }
    } else if (path != null && path.length > 0) {
      try {
        Uint8List bytes = await File(path).readAsBytes();
        UI.Image img = await decodeImageFromList(bytes);
        completer.complete(img);
      } catch (e) {
        completer.completeError(e);
      }
    } else {
      completer.completeError('getImageFuture()にパラメータが設定されていません');
    }
    return completer.future;
  }
}
