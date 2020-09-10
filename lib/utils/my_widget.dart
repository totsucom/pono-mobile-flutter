import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pono_problem_app/records/user.dart';
import 'package:pono_problem_app/records/user_datastore.dart';

class MyWidget {
  // FutureBuilderの待ちなどに
  static Widget loading(BuildContext context, [String text = '読み込み中です...。']) {
    return Center(
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
  }

  // FutureBuilderのエラー表示などに
  static Widget error(BuildContext context, String message,
      [String text = 'エラーが発生しました。']) {
    return Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
          Padding(
              padding: const EdgeInsets.all(16.0),
              child: Icon(Icons.error,
                  size: 64.0, color: Theme.of(context).errorColor)),
          Padding(padding: const EdgeInsets.all(16.0), child: Text(text)),
          Padding(padding: const EdgeInsets.all(16.0), child: Text(text))
        ]));
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

  // userIDからdisplayNameを取得するFutureBuilderを生成する。
  // 最初にfirstWidget、ロードが完了したらcompleteTextを表示する。
  // completeText内に (displayName) 文字列があれば、それはdisplayNameに置換される。
  static Widget displayNameFutureBuilder(String userID,
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
}
