import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pono_problem_app/records/user.dart';
import 'package:pono_problem_app/records/user_datastore.dart';
import 'package:pono_problem_app/records/user_ref.dart';
import 'package:pono_problem_app/records/user_ref_datastore.dart';
import 'package:pono_problem_app/routes/trimming_image_route.dart';
import 'package:pono_problem_app/utils/formatter.dart';
import 'package:pono_problem_app/utils/my_dialog.dart';
import 'package:pono_problem_app/utils/my_widget.dart';
import '../globals.dart';

//このrouteにpushする場合に渡すパラメータ
class EditAccountArgs {
  bool newAccount;
  String uidOfFirebaseUser;
  String documentID;
  User user;

  EditAccountArgs.forNew(String uidOfFirebaseUser, User user) {
    newAccount = true;
    this.uidOfFirebaseUser = uidOfFirebaseUser;
    this.user = user;
  }

  EditAccountArgs.forEdit(UserDocument userDoc) {
    newAccount = false;
    user = userDoc.data;
    documentID = userDoc.docId;
  }
}

class EditAccount extends StatefulWidget {
  EditAccount({Key key}) : super(key: key);

  @override
  _EditAccountState createState() => _EditAccountState();
}

class _EditAccountState extends State<EditAccount> {
  EditAccountArgs _arguments;
  String _editName;
  String _editURL;
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
      _editName = _arguments.user.displayName;
      _editURL = _arguments.user.iconURL;
    }

    return WillPopScope(
        //WillPopScopeで戻るボタンのタップをキャッチ
        onWillPop: _requestPop,
        child: Scaffold(
            appBar: new AppBar(
              automaticallyImplyLeading:
                  (!_arguments.newAccount), //新規の場合 ← ボタンを消す
              title: Text((_arguments.newAccount) ? 'アカウントの作成' : 'アカウントの編集'),
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
    final result = await MyDialog.selectYesNo(context,
        caption: (_arguments.newAccount) ? 'アカウントの作成' : 'アカウントの編集',
        labelText: '変更した内容があった場合、それは失われてしまいますが、それでも戻りますか？');
    if (result != MyDialogResult.Yes) {
      return new Future.value(false); //戻らない
    }
    return new Future.value(true); //戻る
  }

  //appBarのチェックボタン "✔" がタップされた
  void _editCompleted() async {
    // 編集された内容でユーザーを作成
    User newUser = _arguments.user.clone();
    newUser.displayName = _editName;
    newUser.iconURL = _editURL;

    try {
      if (_arguments.newAccount) {
        //新規登録
        UserDocument userDoc = await UserDatastore.addUser(newUser);
        UserRefDocument refDoc = await UserRefDatastore.addUserRef(
            _arguments.uidOfFirebaseUser, userDoc.docId);
      } else {
        //更新
        UserDocument userDoc = await UserDatastore.updateUser(
            UserDocument(_arguments.documentID, newUser));
      }
      //前画面に戻る
      Navigator.of(context).pop();
    } catch (e) {
      MyDialog.ok(context,
          icon: Icon(Icons.error, color: Theme.of(context).errorColor),
          caption: 'アカウントの保存',
          labelText: '失敗しました。表示名が他の方と重複しているのかもしれません。');
    }
  }

  Widget _buildView(BuildContext context) {
    return Column(children: <Widget>[
      Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: GestureDetector(
            child: Container(
                height: 100,
                width: 100,
                //color: Colors.yellow,
                child: MyWidget.getCircleAvatar(_editURL)),
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
                  Text(_editName, textAlign: TextAlign.left),
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
                  child: Text(Formatter.toYMD_HM(_arguments.user.createdAt),
                      textAlign: TextAlign.left))),
        ]),
      Row(children: <Widget>[
        //DocumentIDの行（デバッグ）
        Expanded(
            flex: 4,
            child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Text((_arguments.newAccount) ? 'FB.uid' : 'DocumentID',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).disabledColor)))),
        Expanded(
            flex: 6,
            child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Text(
                    (_arguments.newAccount)
                        ? _arguments.uidOfFirebaseUser
                        : _arguments.documentID,
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
    if (_editURL != _arguments.user.iconURL) {
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
        _editURL = '';
      });
    } else /* if (selectResult.value ==4) */ {
      setState(() {
        _editURL = _arguments.user.iconURL;
      });
    }
  }

  //表示名の変更
  Future<void> editDisplayName(BuildContext context) async {
    final MyDialogTextResult inputResult = await MyDialog.inputText(context,
        caption: User.baseName,
        labelText: UserFieldCaption.displayName,
        initialText: _editName,
        minTextLength: 1,
        maxTextLength: 20,
        trimText: true);

    if (inputResult != null && inputResult.result == MyDialogResult.OK) {
      //名前の重複チェック
      var foundUserDoc =
          await UserDatastore.getUserFromDisplayName(inputResult.text);
      _nameDuplicated =
          (foundUserDoc != null && foundUserDoc.docId != _arguments.documentID);

      setState(() {
        _editName = inputResult.text; //新しい名前を設定
      });
    }
  }
}
