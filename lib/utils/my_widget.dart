import 'package:flutter/material.dart';

class MyWidget {
  //FutureBuilderの待ちなどに
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

  //FutureBuilderのエラー表示などに
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
}
