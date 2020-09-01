import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

enum MyDialogResult { OK, Cancel, Yes, No }

class MyDialogTextResult {
  final MyDialogResult result;
  final String text;
  MyDialogTextResult(this.result, [this.text = '']);
}

class MyDialogIntResult {
  final MyDialogResult result;
  final int value;
  MyDialogIntResult(this.result, [this.value]);
}

class MyDialogItem {
  final Icon icon;
  final String text;
  MyDialogItem(this.text, {this.icon});
}

class MyDialog {
  //テキスト入力ダイアログ
  //dismissの場合はnullを返す
  static Future<MyDialogTextResult> inputText(BuildContext context,
      {String caption = '',
      String labelText = '',
      String hintText = '',
      String initialText = '',
      bool multipleLines = false,
      okButtonCaption = 'OK',
      cancelButtonCaption = 'キャンセル',
      int minTextLength = 0,
      int maxTextLength = 1000,
      bool trimText = false}) async {
    final textEdit = TextEditingController();
    textEdit.text = initialText;
    final result = await showDialog(
      barrierDismissible: true,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(caption),
          content: TextField(
            controller: textEdit,
            decoration: InputDecoration(
              labelText: labelText,
              hintText: hintText,
            ),
            autofocus: true,
            keyboardType:
                (multipleLines) ? TextInputType.multiline : TextInputType.text,
            maxLines: (multipleLines) ? 3 : 1,
            maxLength: maxTextLength,
          ),
          actions: <Widget>[
            FlatButton(
                child: Text(cancelButtonCaption),
                onPressed: () {
                  Navigator.of(context)
                      .pop(MyDialogTextResult(MyDialogResult.Cancel));
                }),
            FlatButton(
              child: Text(okButtonCaption),
              onPressed: () {
                if (trimText) textEdit.text = textEdit.text.trim();
                if (minTextLength >= 0 && textEdit.text.length < minTextLength)
                  return;
                if (maxTextLength >= 0 && textEdit.text.length > maxTextLength)
                  return;
                Navigator.of(context)
                    .pop(MyDialogTextResult(MyDialogResult.OK, textEdit.text));
              },
            ),
          ],
        );
      },
    );
    return result;
  }

  //YesNoダイアログ
  //dismissの場合はnullを返す
  static Future<MyDialogResult> selectYesNo(BuildContext context,
      {String caption = '',
      String labelText = '',
      yesButtonCaption = 'はい',
      noButtonCaption = 'いいえ'}) async {
    final result = await showDialog(
      barrierDismissible: true,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(caption),
          content: Text(labelText),
          actions: <Widget>[
            FlatButton(
                child: Text(noButtonCaption),
                onPressed: () {
                  Navigator.of(context).pop(MyDialogResult.No);
                }),
            FlatButton(
              child: Text(yesButtonCaption),
              onPressed: () {
                Navigator.of(context).pop(MyDialogResult.Yes);
              },
            ),
          ],
        );
      },
    );
    return result;
  }

  //OKダイアログ
  //dismissの場合はnullを返す。そうでない場合は MyDialogResult.OK
  static Future<MyDialogResult> ok(BuildContext context,
      {Icon icon,
      String caption = '',
      String labelText = '',
      okButtonCaption = 'OK'}) async {
    final result = await showDialog(
      barrierDismissible: true,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(children: <Widget>[
            if (icon != null) icon,
            Text(caption),
          ]),
          content: Text(labelText),
          actions: <Widget>[
            FlatButton(
              child: Text(okButtonCaption),
              onPressed: () {
                Navigator.of(context).pop(MyDialogResult.OK);
              },
            ),
          ],
        );
      },
    );
    return result;
  }

  //項目選択ダイアログ
  //アイテムが選択された場合は 返り値.result=MyDialogResult.OK を返し、
  //返り値.value は選択されたアイテムの１から始まるインデックスを返す
  //dismissの場合はnullを返す
  static Future<MyDialogIntResult> selectItem(
      BuildContext context, setState, List<MyDialogItem> items,
      {String caption = '',
      String label = '',
      cancelButtonCaption = 'キャンセル'}) async {
    var itemWidgets = <Widget>[
      if (label.length > 0)
        Padding(padding: const EdgeInsets.all(16), child: Text(label))
    ];

    for (var i = 0; i < items.length; i++) {
      itemWidgets.add(Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
          child: RaisedButton(
            child: Row(children: <Widget>[
              if (items[i].icon != null) items[i].icon,
              Expanded(child: Text(items[i].text))
            ]),
            //color: Colors.orange,
            //textColor: Colors.white,
            onPressed: () {
              Navigator.of(context)
                  .pop(MyDialogIntResult(MyDialogResult.OK, i + 1));
            },
          )));
    }

    final MyDialogIntResult result = await showDialog(
      barrierDismissible: true,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(caption),
          content: Column(
              mainAxisSize: MainAxisSize.min, //ダイアログの、縦に間延び防止
              children: itemWidgets),
          actions: <Widget>[
            FlatButton(
                child: Text(cancelButtonCaption),
                onPressed: () {
                  Navigator.of(context)
                      .pop(MyDialogIntResult(MyDialogResult.Cancel));
                }),
          ],
        );
      },
    );
    return result;
  }
/*
  static Future<MyDialogResult> upload(
      BuildContext context, StorageUploadTask task) async {
    final result = await showDialog(
      barrierDismissible: true,
      context: context,
      builder: (BuildContext context) {
        return StreamBuilder(
            stream: task.events,
            builder: (BuildContext context, snapshot) {
              if (task.isComplete) {
                Navigator.of(context).pop((task.isSuccessful)
                    ? MyDialogResult.OK
                    : MyDialogResult.Cancel); //代用

              }

              if (snapshot.hasData) {
                final StorageTaskEvent event = snapshot.data;
                final StorageTaskSnapshot snap = event.snapshot;
                if (event.type == StorageTaskEventType.success) {
                  Navigator.of(context).pop(MyDialogResult.OK); //代用
                } else if (event.type == StorageTaskEventType.failure) {
                  Navigator.of(context).pop(MyDialogResult.Cancel); //代用
                }
              }
              return SimpleDialog(
                title: Text("アップロードしています"),
                backgroundColor: Colors.transparent,
                children: <Widget>[
                  CircularProgressIndicator(),
                ],
              );
            });
      },
    );
    return result;
  }
 */

  static successfulSnackBar(GlobalKey<ScaffoldState> scaffoldKey, String text) {
    scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Row(children: <Widget>[
        Icon(Icons.check, color: Colors.greenAccent),
        Text(text)
      ]),
      duration: const Duration(seconds: 10),
      action: SnackBarAction(
        label: 'OK',
        onPressed: () {},
      ),
    ));
  }

  static errorSnackBar(GlobalKey<ScaffoldState> scaffoldKey, String text) {
    scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Row(children: <Widget>[
        Icon(
          Icons.error,
          color: Colors.redAccent,
        ),
        Text(text)
      ]),
      duration: const Duration(seconds: 10),
      action: SnackBarAction(
        label: 'OK',
        onPressed: () {},
      ),
    ));
  }
}
