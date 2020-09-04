import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pono_problem_app/records/problem.dart';
import 'package:pono_problem_app/records/user.dart';
import 'package:pono_problem_app/records/user_datastore.dart';
import 'package:pono_problem_app/routes/trimming_image_route.dart';
import 'package:pono_problem_app/utils/formatter.dart';
import 'package:pono_problem_app/utils/menu_item.dart';
import 'package:pono_problem_app/utils/my_dialog.dart';
import 'package:pono_problem_app/utils/my_widget.dart';
import 'package:provider/provider.dart';
import '../globals.dart';
import '../my_theme.dart';
import '../authentication.dart';

//このrouteにpushする場合に渡すパラメータ
class EditAccountArgs {
  //newAccountの場合はGlobals.firebaseUserから新規ユーザーを仮作成し、
  //ユーザーの変更後に保存する
  bool newAccount;
  EditAccountArgs(this.newAccount);
}

// このrouteがpop()でHome画面に戻る場合、次のルールに従うこと
// 1. EditAccountArgs.newAccount == true のとき、Home側で必ずリロードするため、
//   pop()で返す必要は無い。
// 2. EditAccountArgs.newAccount == false　のとき、
// 2-1. データを更新した場合は .pop(UserDocument) を返す。
// 2-2. 更新しなかった場合は何も返さない .pop()

class EditAccount extends StatefulWidget {
  EditAccount({Key key}) : super(key: key);

  @override
  _EditAccountState createState() => _EditAccountState();
}

class _EditAccountState extends State<EditAccount> {
  EditAccountArgs _arguments;
  String _title;
  UserDocument _edit;
  String _originalIconUrl;
  bool _nameDuplicated = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("edit_account_routeのbuild()");
    if (_arguments == null) {
      //前画面から渡されたパラメータを読み込む
      _arguments = ModalRoute.of(context).settings.arguments;
      if (_arguments == null) {
        throw Exception('edit_account_routeにEditAccountArgsクラスを渡してください');
      } else {
        _edit = (_arguments.newAccount)
            ? UserDocument.fromFirebaseUser(Globals.firebaseUser)
            : Globals.ponoUser.clone();
        if (_edit == null || _edit.user == null) {
          throw Exception('編集すべきUserDocumentがnullです');
        } else {
          _title = (_arguments.newAccount) ? 'アカウントの作成' : 'アカウントの編集';
          _originalIconUrl = _edit.user.iconURL;
        }
      }
    }

    return WillPopScope(
        //WillPopScopeで戻るボタンのタップをキャッチ
        onWillPop: _requestPop,
        child: Scaffold(
            appBar: new AppBar(
              automaticallyImplyLeading:
                  (!_arguments.newAccount), //新規の場合backボタンを消す
              title: Text(_title),
              centerTitle: true,
              actions: [
                FlatButton(
                  child: Icon(Icons.check,
                      color: Theme.of(context).primaryColorLight),
                  onPressed: _editCompleted,
                ),
              ],
            ),
            body: Padding(
                padding: EdgeInsets.all(16.0),
                child: SingleChildScrollView(child: _buildView(context)))));
  }

  //appBarの戻るボタン "←" がタップされた
  //新規の場合はここに来ない
  Future<bool> _requestPop() async {
    if (Globals.ponoUser.user.displayName != _edit.user.displayName ||
        Globals.ponoUser.user.iconURL != _edit.user.iconURL) {
      final result = await MyDialog.selectYesNo(context,
          caption: _title, labelText: '変更した内容が失われてしまいますが、それでも戻りますか？');
      if (result != MyDialogResult.Yes) {
        return new Future.value(); //変更なしのため何も返さない
      }
    }
    return new Future.value(); //変更なしのため何も返さない
  }

  //appBarのチェックボタン "✔" がタップされた
  void _editCompleted() async {
    if (_arguments.newAccount) {
      UserDatastore.addUser(_edit.documentId, _edit.user).then((userDoc) {
        if (userDoc != null)
          Navigator.of(context).pop(); // Homeで必ずリロードするので何も返さなくていい
        else
          MyDialog.ok(context,
              icon: Icon(Icons.error, color: Theme.of(context).errorColor),
              caption: 'アカウントの保存',
              labelText: '失敗しました。表示名が他の方と重複しているのかもしれません。');
      }).catchError((err) {
        MyDialog.ok(context,
            icon: Icon(
              Icons.error,
              color: Theme.of(context).errorColor,
            ),
            caption: 'アカウントの保存',
            labelText: 'エラーが発生しました\n' + err.toString());
      });
    } else {
      UserDatastore.updateUser(_edit.documentId, _edit.user).then((userDoc) {
        if (userDoc != null)
          Navigator.of(context).pop(userDoc); // Homeでリビルドが必要
        else
          MyDialog.ok(context,
              icon: Icon(Icons.error, color: Theme.of(context).errorColor),
              caption: 'アカウントの保存',
              labelText: '失敗しました。表示名が他の方と重複しているのかもしれません。');
      }).catchError((err) {
        MyDialog.ok(context,
            icon: Icon(
              Icons.error,
              color: Theme.of(context).errorColor,
            ),
            caption: 'アカウントの保存',
            labelText: 'エラーが発生しました\n' + err.toString());
      });
    }
  }

  Widget _buildView(BuildContext context) {
    //アバターアイコン
    /*Widget icon;
    if (_edit.user.iconURL.length == 0) {
      icon = CircleAvatar(
        backgroundImage: AssetImage('images/user_image_64.png'),
        backgroundColor: Colors.black12, // 背景色
        //Icon(Icons.person_outline, size: 100),
      );
    } else {
      icon = CircleAvatar(
        backgroundImage: NetworkImage(_edit.user.iconURL),
        backgroundColor: Colors.transparent, // 背景色
      );
    }*/

    return Column(children: <Widget>[
      Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: GestureDetector(
            child: Container(
                height: 100,
                width: 100,
                //color: Colors.yellow,
                child: _edit.user.getCircleAvatar()),
            onTap: selectIconSource,
          )),
      Row(children: <Widget>[
        //名前の行
        Expanded(
            flex: 4,
            child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Text(UserFieldCaption.displayName,
                    textAlign: TextAlign.right))),
        Expanded(
            flex: 6,
            child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Row(children: <Widget>[
                  Text(_edit.user.displayName, textAlign: TextAlign.left),
                  IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () {
                        editDisplayName(context);
                      })
                ]))),
      ]),
      if (_nameDuplicated)
        Row(children: <Widget>[
          //名前（エラー）の行
          Expanded(
              flex: 4,
              child: Align(
                  alignment: Alignment.centerRight,
                  child:
                      Icon(Icons.error, color: Theme.of(context).errorColor))),
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Text('同じ名前が使用されています',
                  style: TextStyle(
                      color: Theme.of(context).errorColor, fontSize: 12)),
            ),
          )
        ]),
      if (!_arguments.newAccount)
        Row(children: <Widget>[
          //登録日の行
          Expanded(
              flex: 4,
              child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Text(UserFieldCaption.createdAt,
                      textAlign: TextAlign.right))),
          Expanded(
              flex: 6,
              child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Text(Formatter.toYMD_HM(_edit.user.createdAt),
                      textAlign: TextAlign.left))),
        ]),
      Row(children: <Widget>[
        //DocumentIDの行（デバッグ）
        Expanded(
            flex: 4,
            child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Text('DocumentID',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).disabledColor)))),
        Expanded(
            flex: 6,
            child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Text(_edit.documentId,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).disabledColor)))),
      ]),
    ]);
  }

  void selectIconSource() async {
    var items = [
      MyDialogItem('アルバムから選択', icon: Icon(Icons.image)),
      MyDialogItem('写真を撮る', icon: Icon(Icons.camera_alt)),
      MyDialogItem('削除する', icon: Icon(Icons.delete_outline))
    ];
    if (_originalIconUrl != _edit.user.iconURL) {
      items.add(MyDialogItem('元に戻す', icon: Icon(Icons.undo)));
    }

    //上記メニューから操作を選択
    final selectResult = await MyDialog.selectItem(context, setState, items,
        caption: UserFieldCaption.iconURL, label: 'どこから取得しますか？');
    if (selectResult == null || selectResult.result != MyDialogResult.OK)
      return;

    if (selectResult.value == 1 || selectResult.value == 2) {
      //選択または撮影
      final pickedFile = await ImagePicker().getImage(
          source: (selectResult.value == 1)
              ? ImageSource.gallery
              : ImageSource.camera,
          //重いのでざっくり縮小
          maxWidth: 1200,
          maxHeight: 1200);
      if (pickedFile == null || pickedFile.path == null) return;

      //トリミング
      final trimResult = await Navigator.of(context).pushNamed(
              '/edit_problem/trimming_image',
              arguments: TrimmingImageArgs(null, pickedFile.path))
          as TrimmingResult;
      if (trimResult == null) {
        File(pickedFile.path).deleteSync();
        return;
      }
      //TODO アップロード

    } else if (selectResult.value == 3) {
      setState(() {
        _edit.user.iconURL = '';
      });
    } else /* if (selectResult.value ==4) */ {
      setState(() {
        _edit.user.iconURL = _originalIconUrl;
      });
    }
  }

  //表示名の変更
  Future<void> editDisplayName(BuildContext context) async {
    final MyDialogTextResult inputResult = await MyDialog.inputText(context,
        caption: User.baseName,
        labelText: UserFieldCaption.displayName,
        initialText: _edit.user.displayName,
        minTextLength: 1,
        maxTextLength: 20,
        trimText: true);

    if (inputResult != null && inputResult.result == MyDialogResult.OK) {
      //名前の重複チェック
      var duplicated =
          await UserDatastore.getUserFromDisplayName(inputResult.text);
      _nameDuplicated =
          (duplicated != null && duplicated.documentId != _edit.documentId);

      setState(() {
        _edit.user.displayName = inputResult.text; //新しい名前を設定
      });
    }
  }
}
