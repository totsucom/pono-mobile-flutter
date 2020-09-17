import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pono_problem_app/records/base_picture.dart';
import 'package:pono_problem_app/records/base_picture_datastore.dart';
import 'package:pono_problem_app/records/problem.dart';
import 'package:pono_problem_app/records/problem_datastore.dart';
import 'package:pono_problem_app/records/user_datastore.dart';
import 'package:pono_problem_app/records/wall.dart';
import 'package:pono_problem_app/records/wall_datastore.dart';
import 'package:pono_problem_app/routes/home_footer.dart';
import 'package:pono_problem_app/storage/storage_result.dart';
import 'package:pono_problem_app/utils/formatter.dart';
import 'package:pono_problem_app/utils/menu_item.dart';
import 'package:pono_problem_app/utils/my_dialog.dart';
import 'package:pono_problem_app/utils/my_document_notifier.dart';
import 'package:pono_problem_app/utils/my_widget.dart';
import 'package:provider/provider.dart';

import '../globals.dart';
import '../my_auth_notifier.dart';
import 'edit_problem_route.dart';
import 'home_route.dart';
import 'manage_base_picture_route.dart';
import 'dart:ui' as UI;

//このrouteにpushする場合に渡すパラメータ
class EditProblemArgs {
  UI.Image baseImage;
  Problem problem;
  List<String> wallIDs;
  EditProblemArgs(this.baseImage, this.problem, this.wallIDs);
}

class EditProblem extends StatefulWidget {
  EditProblem({Key key}) : super(key: key);

  @override
  _EditProblemState createState() => _EditProblemState();
}

class _EditProblemState extends State<EditProblem> {
  //前画面から渡されたパラメータを保持
  EditProblemArgs _arguments;

  StorageResult _baseImageStorageResult;

  var _scaffoldKey = GlobalKey<ScaffoldState>();

  //壁の選択関連
  List<String> _selectedWallIDs;
  String _selectedWallName = '';
  List<MyDialogCheckedItem> wallSelectionDialogItems;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => afterBuild(context));
  }

  //buildが完了したときに呼び出される
  void afterBuild(context) async {
    WallDatastore.getWalls(false, true).then((wallDocs) {
      wallSelectionDialogItems = wallDocs
          .map((wallDoc) =>
              MyDialogCheckedItem(wallDoc.data.name, value: wallDoc.docId))
          .toList();

      String s = '';
      if (_selectedWallIDs != null)
        wallSelectionDialogItems.forEach((item) {
          if (_selectedWallIDs.indexOf(item.value) >= 0) {
            s += item.text;
            s += ' ';
          }
        });

      setState(() {
        _selectedWallName = s;
      });
    }).catchError((err) {
      debugPrint('壁リストを取得できませんでした ' + err.toString());
      //_wallDropDownMenuItems = null;
      // TODO エラー処理
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("base_picture_view_routeのbuild()");

    if (_arguments == null) {
      //前画面から渡されたパラメータを読み込む
      _arguments = ModalRoute.of(context).settings.arguments;
      if (_arguments == null) {
        throw Exception(
            'base_picture_view_routeにBasePictureDocumentクラスを渡してください');
      } else {
        //ベース画像のアップロードを開始する
        ProblemStorage.upload(_arguments.baseImage, true)
            .then((StorageResult result) {
          setState(() {
            //✔ボタンを表示
            _baseImageStorageResult = result;
          });
        }).catchError((err) {
          Future.delayed(Duration.zero).then((_) async {
            await MyDialog.ok(context,
                caption: 'エラー',
                labelText: '申し訳ありません。画像のアップロードに失敗しました！\n' + err.toString(),
                dismissible: false);
            Navigator.of(context).pop();
          });
        });

        _selectedWallIDs =
            (_arguments.wallIDs != null) ? _arguments.wallIDs : [];
        debugPrint('選択中の壁のリスト ' + _selectedWallIDs.toString());
      }
    }

    //認証情報を得る
    final auth = Provider.of<MyAuthNotifier>(context, listen: false);
    String errMsg;
    switch (auth.reason) {
      case MyAuthNotifyReason.FBUserLost:
        errMsg = '認証ユーザーが失われました';
        break;
      case MyAuthNotifyReason.FBUserChanged:
        errMsg = '認証ユーザーが変更されました';
        break;
      case MyAuthNotifyReason.UserDeleted:
        errMsg = 'ユーザーが削除されました';
        break;
      default:
        //念のため
        if (auth.firebaseUser == null) {
          errMsg = '認証ユーザーが失われました';
          break;
        } else if (auth.currentUser == null) {
          errMsg = '認証ユーザーが削除されました';
          break;
        }
    }
    auth.resetReason();
    if (errMsg != null) {
      // エラーがのでダイアログ表示後にホームに戻す
      Future.delayed(Duration.zero).then((_) async {
        await MyDialog.ok(context,
            caption: 'エラー', labelText: errMsg, dismissible: false);
        Navigator.of(context).popUntil(ModalRoute.withName("/"));
      });
      return MyWidget.empty(context, scaffold: true);
    }

    // 通常の表示
    return Scaffold(
      key: _scaffoldKey,
      appBar: new AppBar(
        title: Text('${Problem.baseName}の説明'),
        centerTitle: true,
        actions: [
          if (_baseImageStorageResult != null)
            FlatButton(
              child:
                  Icon(Icons.check, color: Theme.of(context).primaryColorLight),
              onPressed: _saveProblem,
            ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  final _titleTextEdit = TextEditingController();
  int _gradeMenuSelectedValue = 70;
  bool _plusGradeCheckBox = false;
  String _wallSelectedValue = 'A';
  bool _footFreeCheckBox = false;
  final _commentTextEdit = TextEditingController();
  ProblemStatus _saveTypeValue = ProblemStatus.Public;

  //グレードドロップダウンメニュー
  List<MenuItem<int>> _gradeDropDownMenuItems = [
    MenuItem<int>(70, title: '７級'),
    MenuItem<int>(60, title: '６級'),
    MenuItem<int>(50, title: '５級'),
    MenuItem<int>(51, title: '５級＋'),
    MenuItem<int>(40, title: '４級'),
    MenuItem<int>(41, title: '４級＋'),
    MenuItem<int>(30, title: '３級'),
    MenuItem<int>(31, title: '３級＋'),
    MenuItem<int>(20, title: '２級'),
    MenuItem<int>(21, title: '２級＋'),
    MenuItem<int>(10, title: '１級'),
    MenuItem<int>(11, title: '１級＋'),
    MenuItem<int>(-10, title: '初段'),
    MenuItem<int>(-11, title: '初段＋'),
    MenuItem<int>(-20, title: '２段'),
    MenuItem<int>(-21, title: '２段＋'),
  ];

  //保存タイプドロップダウンメニュー
  List<MenuItem<ProblemStatus>> _saveTypeDropDownMenuItems = [
    MenuItem<ProblemStatus>(ProblemStatus.Draft, title: '下書き'),
    MenuItem<ProblemStatus>(ProblemStatus.Private, title: '非公開'),
    MenuItem<ProblemStatus>(ProblemStatus.Public, title: '公開')
  ];

  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(children: <Widget>[
              TextField(
                controller: _titleTextEdit,
                maxLength: 20,
                decoration: InputDecoration(
                    labelText: "${Problem.baseName}のタイトル",
                    hintText: "あったほうがいい..."),
              ),
              TextField(
                controller: _commentTextEdit,
                maxLength: 100,
                decoration:
                    InputDecoration(labelText: "${Problem.baseName}のコメントや説明"),
              ),
              Row(children: <Widget>[
                Flexible(
                    child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('グレード'),
                )),
                Flexible(
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: DropdownButton<int>(
                            icon: Icon(Icons.arrow_drop_down),
                            value: _gradeMenuSelectedValue,
                            //style: TextStyle(fontSize: 20, color: Colors.black),
                            underline: Container(
                              height: 2,
                              color: Colors.grey,
                            ),
                            items: _gradeDropDownMenuItems
                                .map((e) => e.toDropdownMenuItem())
                                .toList(),
                            onChanged: (int newValue) {
                              setState(() {
                                _gradeMenuSelectedValue = newValue;
                              });
                            })))
              ]),
              Row(children: <Widget>[
                Flexible(
                    child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Text(Wall.baseName))),
                Flexible(
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
                        child: Text(
                          _selectedWallName,
                          style:
                              TextStyle(decoration: TextDecoration.underline),
                        ))),
                Flexible(
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              _selectWalls(context);
                            }))),
              ]),
              Row(
                children: <Widget>[
                  Flexible(
                      child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Text('足自由'))),
                  Flexible(
                      child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Checkbox(
                            activeColor: Colors.blue,
                            value: _footFreeCheckBox,
                            onChanged: (_) {
                              setState(() {
                                _footFreeCheckBox = !_footFreeCheckBox;
                              });
                            },
                          ))),
                ],
              ),
              Row(children: <Widget>[
                Flexible(
                    child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Text('保存タイプ'))),
                Flexible(
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: DropdownButton<ProblemStatus>(
                            icon: Icon(Icons.arrow_drop_down),
                            value: _saveTypeValue,
                            //style: TextStyle(fontSize: 20, color: Colors.black),
                            underline: Container(
                              height: 2,
                              color: Colors.grey,
                            ),
                            items: _saveTypeDropDownMenuItems
                                .map((e) => e.toDropdownMenuItem())
                                .toList(),
                            onChanged: (ProblemStatus newValue) {
                              setState(() {
                                _saveTypeValue = newValue;
                              });
                            }))),
              ]),
            ])));
  }

  void _selectWalls(context) async {
    //壁の選択
    MyDialogArrayResult checkedResult = await MyDialog.checkItems(
        context, wallSelectionDialogItems,
        selectedValue: _selectedWallIDs,
        caption: BasePicture.baseName,
        label: '写真に該当する壁を１つ以上選択してください。',
        minCount: 1,
        dismissible: false);

    if (checkedResult == null || checkedResult.result != MyDialogResult.OK) {
      //入力がキャンセルされた
      return;
    }

    _selectedWallIDs = checkedResult.list;
    debugPrint(checkedResult.list.toString());

    String s = '';
    if (_selectedWallIDs != null)
      wallSelectionDialogItems.forEach((item) {
        if (_selectedWallIDs.indexOf(item.value) >= 0) {
          s += item.text;
          s += ' ';
        }
      });

    setState(() {
      _selectedWallName = s;
    });
  }

  void _saveProblem() {
    _arguments.problem.basePicturePath = _baseImageStorageResult.path;
    _arguments.problem.imageRequired = true;
    _arguments.problem.title = _titleTextEdit.text;
    _arguments.problem.grade = _gradeMenuSelectedValue;
    _arguments.problem.gradeOption = _plusGradeCheckBox ? '+' : '';
    _arguments.problem.footFree = _footFreeCheckBox;
    _arguments.problem.comment = _commentTextEdit.text;
    _arguments.problem.status = _saveTypeValue;
    _arguments.problem.wallIDs = _selectedWallIDs;
    assert(_arguments.problem.uid != null);

    ProblemDatastore.addProblem(_arguments.problem, true)
        .then((ProblemDocument problemDoc) {
      //成功
      HomeFooter.snackBarWidgetFromOutside =
          MyWidget.successfulSnackBar('追加しました');
      Navigator.of(context).popUntil(ModalRoute.withName("/"));
    }).catchError((err) {
      //失敗
      MyDialog.errorSnackBar(_scaffoldKey, '追加できませんでした\n' + err.toString());
    });
  }
}
