import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pono_problem_app/records/base_picture.dart';
import 'package:pono_problem_app/records/base_picture_datastore.dart';
import 'package:pono_problem_app/records/user_datastore.dart';
import 'package:pono_problem_app/routes/base_picture_view_route.dart';
import 'package:pono_problem_app/routes/trimming_image_route.dart';
import 'package:pono_problem_app/storage/storage_result.dart';
import 'package:pono_problem_app/utils/formatter.dart';
import 'package:pono_problem_app/utils/my_dialog.dart';
import 'package:pono_problem_app/utils/my_widget.dart';
import '../globals.dart';

class ManageBasePicture extends StatefulWidget {
  ManageBasePicture({Key key}) : super(key: key);

  @override
  _ManageBasePictureState createState() => _ManageBasePictureState();
}

class _ManageBasePictureState extends State<ManageBasePicture> {
  var _scaffoldKey = GlobalKey<ScaffoldState>();

  //チェックボックスの表示～削除までの仕組み
  var showDustbin = false;
  var showCheckboxes = false;
  final itemChecks = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("manage_base_picture_routeのbuild()");
    return Scaffold(
      key: _scaffoldKey,
      appBar: new AppBar(
        title: Text(BasePicture.baseName + 'の管理'),
        centerTitle: true,
        actions: [
          if (showDustbin)
            Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 2, 4),
                child: IconButton(
                  icon: Icon(Icons.delete_outline),
                  onPressed: (() async {
                    int count = 0;
                    itemChecks.forEach((key, value) {
                      if (value) count++;
                    });
                    final res = await MyDialog.selectYesNo(context,
                        caption: BasePicture.baseName,
                        labelText:
                            '${count}つの${BasePicture.baseName}を削除してよいですか？');
                    if (res == MyDialogResult.Yes) {
                      _deleteSelectedBasePictures();
                    }

                    setState(() {
                      showDustbin = false;
                      showCheckboxes = false;
                    });
                  }),
                )),
          Padding(
              padding: const EdgeInsets.fromLTRB(2, 4, 8, 4),
              child: IconButton(
                icon: Icon(Icons.check_box_outline_blank),
                onPressed: () => setState(() {
                  showCheckboxes = !showCheckboxes;
                  if (showCheckboxes) {
                    itemChecks.forEach((key, value) {
                      itemChecks[key] = false; //チェックをクリアする
                    });
                  }
                }),
              )),
        ],
      ),
      body: _buildBody(context),
      floatingActionButton: Visibility(
        visible: !showCheckboxes,
        child: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () {
            _addNewBasePicture(context);
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: BasePictureDatastore.getBasePicturesStream(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot == null || (!snapshot.hasData && !snapshot.hasError))
          return MyWidget.loading(context);
        if (snapshot.hasError)
          return MyWidget.error(context, snapshot.error.toString());
        return _buildListView(context, snapshot.data.documents);
      },
    );
  }

  Widget _buildListView(BuildContext context, List<DocumentSnapshot> snapshot) {
    return ListView(
      padding: const EdgeInsets.only(top: 20.0),
      children: snapshot.map((data) => _buildListItem(context, data)).toList(),
    );
  }

  Widget _buildListItem(BuildContext context, DocumentSnapshot snapshot) {
    final basePictureDoc = new BasePictureDocument(
        snapshot.documentID, BasePicture.fromMap(snapshot.data));
    return Padding(
      key: ValueKey(basePictureDoc.documentId),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: _buildListTile(context, basePictureDoc),
      ),
    );
  }

  Widget _buildListTile(
      BuildContext context, BasePictureDocument basePictureDoc) {
    final dateString = Formatter.toEnnui(basePictureDoc.basePicture.createdAt);
    //DateFormat('yyyy/MM/dd').format(basePictureDoc.basePicture.createdAt);

    if (!itemChecks.containsKey(basePictureDoc.documentId)) {
      itemChecks[basePictureDoc.documentId] = false;
    }

    debugPrint("_buildListTileの処理 BasePicture.DocumentID = " +
        basePictureDoc.documentId.toString());

    Widget leadingWidget;
    if (basePictureDoc.basePicture.thumbnailURL.length == 0) {
      if (basePictureDoc.basePicture.createdAt != null) {
        // ↑ 瞬間nullのパターンが発生するみたい
        final duration =
            DateTime.now().difference(basePictureDoc.basePicture.createdAt);
        if (duration.inMinutes > 2)
          //2分越えてURLが無いのはエラーしかない
          leadingWidget =
              Icon(Icons.error, color: Theme.of(context).errorColor);
      }
      if (leadingWidget == null)
        //CloudFunctuins処理待ち(エラー表示回避)
        leadingWidget = CircularProgressIndicator();
    } else {
      leadingWidget = (basePictureDoc.basePicture.thumbnailURL.length == 0)
          ? CircularProgressIndicator() //CloudFunctuins処理待ち(エラー表示回避)
          : CachedNetworkImage(
              imageUrl: basePictureDoc.basePicture.thumbnailURL,
              placeholder: (context, url) => CircularProgressIndicator(),
              errorWidget: (context, url, error) =>
                  Icon(Icons.error, color: Theme.of(context).errorColor));
    }

    return ListTile(
      leading: leadingWidget,
      /*ThumbnailDatastore.thumbnailStreamBuilder(
          context, basePictureDoc.basePicture.picturePath),*/
      title: Text(basePictureDoc.basePicture.name),
      subtitle: UserDatastore.displayNameFutureBuilder(
          basePictureDoc.basePicture.userID,
          Text(dateString),
          '${dateString}\nby{displayName}'),
      trailing: Visibility(
        visible: showCheckboxes,
        child: Checkbox(
          value: itemChecks[basePictureDoc.documentId],
          onChanged: ((bool newValue) {
            setState(() {
              //チェックボックスにチェックを設定
              itemChecks[basePictureDoc.documentId] = newValue;
              //チェックが１つでもあればごみ箱を表示
              var checked = newValue;
              if (!checked) {
                for (String key in itemChecks.keys) {
                  if (itemChecks[key]) {
                    checked = true;
                    break;
                  }
                }
              }
              showDustbin = checked;
            });
          }),
        ),
      ),
      onTap: () {
        //DocumentIDをビューワーに渡す
        Navigator.of(context).pushNamed('/manage_base_picture/view',
            arguments:
                BasePictureViewArgs(basePictureDoc.documentId, _scaffoldKey));
      },
    );
  }

  //選択された壁写真を削除する
  void _deleteSelectedBasePictures() {
    var futures = <Future>[];
    itemChecks.forEach((key, value) {
      if (value) {
        debugPrint('BasePictureを削除します ' + key);
        futures.add(BasePictureDatastore.deleteBasePicture(key));
      }
    });
    var futureAll = Future.wait(futures);
    int successCount = 0;
    int failCount = 0;
    String errorMessage = '';
    futureAll.then((value) {
      successCount++;
    }).catchError((err) {
      failCount++;
      if (errorMessage.length == 0) errorMessage = err.toString();
    }).whenComplete(() {
      if (failCount == 0) {
        MyDialog.successfulSnackBar(_scaffoldKey, '削除しました');
      } else {
        if (successCount == 0) {
          MyDialog.errorSnackBar(_scaffoldKey, '削除できませんでした\n' + errorMessage);
        } else {
          MyDialog.errorSnackBar(_scaffoldKey,
              '${successCount}件削除成功、${failCount}件削除できませんでした\n' + errorMessage);
        }
      }
    });
  }

  void _addNewBasePicture(BuildContext context) async {
    final items = [
      MyDialogItem('アルバムから選択', icon: Icon(Icons.image)),
      MyDialogItem('写真を撮る', icon: Icon(Icons.camera_alt)),
    ];

    //選択または撮影のいずれかを選択
    final selectResult = await MyDialog.selectItem(context, setState, items,
        caption: BasePicture.baseName, label: 'どこから取得しますか？');
    if (selectResult == null || selectResult.result != MyDialogResult.OK)
      return;

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
        arguments: TrimmingImageArgs(null, pickedFile.path)) as TrimmingResult;
    if (trimResult == null) {
      File(pickedFile.path).deleteSync();
      return;
    }
/*
    //トリミング
    var croppedFile = await ImageCropper.cropImage(
        sourcePath: pickedFile.path,
        androidUiSettings: AndroidUiSettings(
            toolbarTitle: 'トリミング',
            toolbarColor: Theme.of(context).primaryColor,
            toolbarWidgetColor:
                Theme.of(context).primaryTextTheme.headline6.color,
            //initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false),
        iosUiSettings: IOSUiSettings(
          minimumAspectRatio: 1.0,
        ));
    if (croppedFile == null || croppedFile.path == null) return;
*/

    //名前入力の裏で写真のアップロードを始める
    List<Future> futureList = [
//ベース写真をアップロード
      BasePictureStorage.upload(trimResult.filePath),
      //名前の入力
      MyDialog.inputText(context,
          caption: BasePicture.baseName,
          labelText: BasePictureFieldCaption.name,
          hintText: 'A壁 など',
          minTextLength: 1,
          maxTextLength: 20)
    ];
    final waitResult = await Future.wait(futureList);
    final StorageResult storageResult = waitResult[0];
    final MyDialogTextResult inputResult = waitResult[1];

    //ローカルファイルを削除
    File(pickedFile.path).deleteSync();

    if (inputResult == null || inputResult.result != MyDialogResult.OK) {
      //入力がキャンセルされた
      if (storageResult != null) BasePictureStorage.delete(storageResult.path);
      return;
    }

    if (storageResult == null) {
      //ファイルアップロード失敗
      MyDialog.errorSnackBar(_scaffoldKey, '写真をアップロードできませんでした');
      return;
    }

    //ベース写真の追加
    BasePictureDatastore.addBasePicture(
            storageResult.path,
            trimResult.rotation,
            trimResult.trimLeft,
            trimResult.trimTop,
            trimResult.trimRight,
            trimResult.trimBottom,
            inputResult.text,
            Globals.firebaseUser.uid)
        .then((String documentID) {
      //成功
      MyDialog.successfulSnackBar(_scaffoldKey, '追加しました');
    }).catchError((err) {
      //失敗
      MyDialog.errorSnackBar(_scaffoldKey, '追加できませんでした\n' + err.toString());
    });
  }
}
