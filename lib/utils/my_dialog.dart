import 'package:flutter/material.dart';
import 'my_widget.dart';

/*
ダイアログの表示
  inputText
  selectYesNo
  ok
  selectItem
  checkItems

スナックバーの表示
  successfulSnackBar
  informationSnackBar
  hintSnackBar
  errorSnackBar
*/

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

class MyDialogCheckedItem {
  final String text;
  final String value; //表示には使わない。ユーザー側の値保持
  MyDialogCheckedItem(this.text, {this.value});
}

class MyDialogArrayResult {
  final MyDialogResult result;
  final List list;
  MyDialogArrayResult(this.result, [this.list]);
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
      String okButtonCaption = 'OK',
      String cancelButtonCaption = 'キャンセル',
      int minTextLength = 0,
      int maxTextLength = 1000,
      bool trimText = false,
      bool dismissible = true}) async {
    final textEdit = TextEditingController();
    textEdit.text = initialText;
    final result = await showDialog(
      barrierDismissible: dismissible,
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
      String yesButtonCaption = 'はい',
      String noButtonCaption = 'いいえ',
      bool dismissible = true}) async {
    final result = await showDialog(
      barrierDismissible: dismissible,
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
      String okButtonCaption = 'OK',
      bool dismissible = true}) async {
    final result = await showDialog(
      barrierDismissible: dismissible,
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
      BuildContext context, List<MyDialogItem> items,
      {String caption = '',
      String label = '',
      String cancelButtonCaption = 'キャンセル',
      bool dismissible = true}) async {
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
      barrierDismissible: dismissible,
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

  //項目選択ダイアログ
  //初期選択が必要な場合は、selectedValueに選択したい、itemsのvalue値の配列を渡す
  //アイテムが選択された場合は 返り値.result=MyDialogResult.OK を返し、
  //※返り値(MyDialogArrayResult.list)の形式は returnSelectedValues で変更できる
  //  true(default): listは選択されたアイテムのvalue値を格納する
  //  false: listの長さはitemsの長さと一致。選択されたアイテムはtrue,それ以外はfalseが格納される
  //dismissの場合はnullを返す
  //チェックの結果はOKやキャンセルに関わらず、パラメータの items を直接書き換えるので注意。
  static Future<MyDialogArrayResult> checkItems(
      BuildContext context, List<MyDialogCheckedItem> items,
      {List<String> selectedValue,
      String caption = '',
      String label = '',
      int minCount = 0,
      String okButtonCaption = 'OK',
      String cancelButtonCaption = 'キャンセル',
      bool dismissible = true,
      bool returnSelectedValues = true}) async {
    final ar = <bool>[];
    for (int i = 0; i < items.length; i++) {
      ar.add(
          selectedValue != null && selectedValue.indexOf(items[i].value) >= 0);
    }

    final MyDialogArrayResult result = await showDialog(
        barrierDismissible: dismissible,
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {
              var itemWidgets = <Widget>[
                if (label.length > 0)
                  Padding(padding: const EdgeInsets.all(16), child: Text(label))
              ];

              for (var i = 0; i < items.length; i++) {
                itemWidgets.add(CheckboxListTile(
                  title: Text(items[i].text), //    <-- label
                  value: ar[i],
                  onChanged: (newValue) {
                    setState(() {
                      ar[i] = !ar[i];
                    });
                  },
                ));
              }

              return AlertDialog(
                title: Text(caption),
                content: SingleChildScrollView(
                    child: Column(
                        mainAxisSize: MainAxisSize.min, //ダイアログの、縦に間延び防止
                        children: itemWidgets)),
                actions: <Widget>[
                  FlatButton(
                      child: Text(cancelButtonCaption),
                      onPressed: () {
                        Navigator.of(context)
                            .pop(MyDialogArrayResult(MyDialogResult.Cancel));
                      }),
                  FlatButton(
                      child: Text(okButtonCaption),
                      onPressed: () {
                        int count = 0;
                        ar.forEach((element) {
                          if (element) count++;
                        });
                        if (count >= minCount) {
                          var selectedList;
                          if (returnSelectedValues) {
                            selectedList = <String>[];
                            for (int i = 0; i < items.length; i++) {
                              if (ar[i]) selectedList.add(items[i].value);
                            }
                          } else {
                            selectedList = ar;
                          }
                          Navigator.of(context).pop(MyDialogArrayResult(
                              MyDialogResult.OK, selectedList));
                        }
                      }),
                ],
              );
            },
          );
        });
    return result;
  }

  /*
   * SnackBarは画面下にツールチップのように表示するものです。
   * var _scaffoldKey = GlobalKey<ScaffoldState>();
   * のようにグローバルキーを作成して、Scaffoldのkeyに設定しておきます。
   * 表示する場合は下記のようにします。
   * MyDialog.successfulSnackBar(_scaffoldKey, '削除しました');
   */

  // 成功ウイジェットを表示。ウィジェットだけなら MyWidget.successfulSnackBar（） を使う
  static successfulSnackBar(GlobalKey<ScaffoldState> scaffoldKey, String text,
      {int displaySeconds = 10}) {
    if (scaffoldKey.currentState == null)
      throw 'successfulSnackBar() scaffoldKey.currentStateがnullのため、スナックバーは表示されません！';
    else
      scaffoldKey.currentState.showSnackBar(
          MyWidget.successfulSnackBar(text, displaySeconds: displaySeconds));
  }

  // 情報ウイジェットを表示。ウィジェットだけなら MyWidget.informationSnackBar（） を使う
  static informationSnackBar(GlobalKey<ScaffoldState> scaffoldKey, String text,
      {int displaySeconds = 10}) {
    if (scaffoldKey.currentState == null)
      throw 'informationSnackBar() scaffoldKey.currentStateがnullのため、スナックバーは表示されません！';
    else
      scaffoldKey.currentState.showSnackBar(
          MyWidget.informationSnackBar(text, displaySeconds: displaySeconds));
  }

  // ヒントウイジェットを表示。ウィジェットだけなら MyWidget.hintSnackBar（） を使う
  static hintSnackBar(GlobalKey<ScaffoldState> scaffoldKey, String text,
      {int displaySeconds = 10}) {
    if (scaffoldKey.currentState == null)
      throw 'hintSnackBar() scaffoldKey.currentStateがnullのため、スナックバーは表示されません！';
    else
      scaffoldKey.currentState.showSnackBar(
          MyWidget.hintSnackBar(text, displaySeconds: displaySeconds));
  }

  // ヒントウイジェットを表示。ウィジェットだけなら MyWidget.errorSnackBar（） を使う
  static errorSnackBar(GlobalKey<ScaffoldState> scaffoldKey, String text,
      {int displaySeconds = 10}) {
    if (scaffoldKey.currentState == null)
      throw 'errorSnackBar() scaffoldKey.currentStateがnullのため、スナックバーは表示されません！';
    else
      scaffoldKey.currentState.showSnackBar(
          MyWidget.errorSnackBar(text, displaySeconds: displaySeconds));
  }
}
