import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pono_problem_app/records/base_picture.dart';
import 'package:pono_problem_app/records/base_picture_datastore.dart';
import 'package:pono_problem_app/records/user.dart';
import 'package:pono_problem_app/records/user_datastore.dart';
import 'package:pono_problem_app/routes/base_picture_view_route.dart';
import 'package:pono_problem_app/routes/trimming_image_route.dart';
import 'package:pono_problem_app/storage/storage_result.dart';
import 'package:pono_problem_app/utils/formatter.dart';
import 'package:pono_problem_app/utils/my_dialog.dart';
import 'package:pono_problem_app/utils/my_widget.dart';
import '../globals.dart';

//このrouteにpushする場合に渡すパラメータ
class ManageBasePictureArgs {
  GlobalKey<ScaffoldState> homeScaffoldGlobalKey;
  ManageBasePictureArgs(this.homeScaffoldGlobalKey);
}

class ManageBasePicture extends StatefulWidget {
  ManageBasePicture({Key key}) : super(key: key);

  @override
  _ManageBasePictureState createState() => _ManageBasePictureState();
}

class _ManageBasePictureState extends State<ManageBasePicture> {
  //前画面から渡されたパラメータを保持
  ManageBasePictureArgs _arguments;

  var _scaffoldKey = GlobalKey<ScaffoldState>();

  //チェックボックスの表示～削除までの仕組み
  var showDustbin = false;
  var showCheckboxes = false;
  final itemChecks = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => afterBuild(context));
  }

  //buildが完了したときに呼び出される
  void afterBuild(context) async {
    MyDialog.informationSnackBar(
        _scaffoldKey, 'ユーザーが課題を作成する場合に使用できる、ベースの壁写真を登録します。');

    // 各ルートで必要な認証情報の監視
    FirebaseAuth.instance.onAuthStateChanged
        .listen((FirebaseUser firebaseUser) {
      if (firebaseUser == null) {
        // 認証ユーザーが無くなった
        debugPrint('認証ユーザーが無くなったのでホームに強制送還します');
        MyDialog.errorSnackBar(
            _arguments.homeScaffoldGlobalKey, '認証情報が失われました。');
        Navigator.of(context).popUntil(ModalRoute.withName("/"));
      } else if (firebaseUser.uid != Globals.firebaseUser.uid) {
        // 認証ユーザーが変わった
        debugPrint('認証ユーザーが異なるのでホームに強制送還します');
        MyDialog.errorSnackBar(
            _arguments.homeScaffoldGlobalKey, '認証情報に相違が生じました。');
        Navigator.of(context).popUntil(ModalRoute.withName("/"));
      }
    });

    // 管理者ルートで必要なユーザー権限の監視
    UserDatastore.getUserStream(Globals.currentUserID)
        .listen((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.data == null) {
        // ユーザーが削除された
        debugPrint('ユーザーが削除されたのでホームに強制送還します');
        MyDialog.errorSnackBar(
            _arguments.homeScaffoldGlobalKey, 'ユーザーが削除されました。');
        Navigator.of(context).popUntil(ModalRoute.withName("/"));
      } else {
        //管理者属性を再取得する
        Globals.reloadAdmin().then((bool admin) {
          if (!admin) {
            // ユーザーの管理者権限が無い
            debugPrint('ユーザーの管理者権限が失われたのでホームに強制送還します');
            MyDialog.errorSnackBar(
                _arguments.homeScaffoldGlobalKey, '管理者権限が失われました。');
            Navigator.of(context).popUntil(ModalRoute.withName("/"));
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("manage_base_picture_routeのbuild()");

    if (_arguments == null) {
      //前画面から渡されたパラメータを読み込む
      _arguments = ModalRoute.of(context).settings.arguments;
      if (_arguments == null) {
        throw 'ManageBasePictureへのpush()にはパラメータが必要です';
      }
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: new AppBar(
        title: Text(
          BasePicture.baseName + 'の管理',
          style: TextStyle(color: Colors.yellow),
        ),
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
                  if (!showCheckboxes) showDustbin = false;
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
        //定型文
        if (snapshot == null || (!snapshot.hasData && !snapshot.hasError))
          return MyWidget.loading(context);
        if (snapshot.hasError)
          return MyWidget.error(context, snapshot.error.toString());
        return _buildListView(context, snapshot.data.documents);
      },
    );
  }

  Widget _buildListView(BuildContext context, List<DocumentSnapshot> snapshot) {
    final list = snapshot.map((data) => _buildListItem(context, data)).toList();
    if (list.length == 0)
      return Center(
          child: Text(BasePicture.baseName + 'はありません。\n\n＋ ボタンで追加できます。'));

    return ListView(
      padding: const EdgeInsets.only(top: 20.0),
      children: list,
    );
  }

  Widget _buildListItem(BuildContext context, DocumentSnapshot snapshot) {
    final basePictureDoc = new BasePictureDocument(
        snapshot.documentID, BasePicture.fromMap(snapshot.data));
    return Padding(
      key: ValueKey(basePictureDoc.docId),
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
    final dateString = Formatter.toEnnui(basePictureDoc.data.createdAt);
    //DateFormat('yyyy/MM/dd').format(basePictureDoc.basePicture.createdAt);

    if (!itemChecks.containsKey(basePictureDoc.docId)) {
      itemChecks[basePictureDoc.docId] = false;
    }

    debugPrint("_buildListTileの処理 BasePicture.DocumentID = " +
        basePictureDoc.docId.toString());

    Widget leadingWidget;
    if (basePictureDoc.data.thumbnailURL.length == 0) {
      if (basePictureDoc.data.createdAt != null) {
        // ↑ 瞬間nullのパターンが発生するみたい
        final duration =
            DateTime.now().difference(basePictureDoc.data.createdAt);
        if (duration.inMinutes > 2)
          //2分越えてURLが無いのはエラーしかない
          leadingWidget =
              Icon(Icons.error, color: Theme.of(context).errorColor);
      }
      if (leadingWidget == null)
        //CloudFunctuins処理待ち(エラー表示回避)
        leadingWidget = CircularProgressIndicator();
    } else {
      leadingWidget = (basePictureDoc.data.thumbnailURL.length == 0)
          ? CircularProgressIndicator() //CloudFunctuins処理待ち(エラー表示回避)
          : CachedNetworkImage(
              imageUrl: basePictureDoc.data.thumbnailURL,
              placeholder: (context, url) => CircularProgressIndicator(),
              errorWidget: (context, url, error) =>
                  Icon(Icons.error, color: Theme.of(context).errorColor));
    }

    return ListTile(
      leading: leadingWidget,
      /*ThumbnailDatastore.thumbnailStreamBuilder(
          context, basePictureDoc.basePicture.picturePath),*/
      title: Text(basePictureDoc.data.name),
      subtitle: MyWidget.displayNameFutureBuilder(basePictureDoc.data.uid,
          Text(dateString), '${dateString}\nby{displayName}'),
      trailing: Visibility(
        visible: showCheckboxes,
        child: Checkbox(
          value: itemChecks[basePictureDoc.docId],
          onChanged: ((bool newValue) {
            setState(() {
              //チェックボックスにチェックを設定
              itemChecks[basePictureDoc.docId] = newValue;
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
            arguments: BasePictureViewArgs(basePictureDoc.docId, _scaffoldKey));
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
          maxTextLength: 20,
          dismissible: false)
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
    BasePictureDatastore.addBasePicture(BasePicture(
            storageResult.path,
            trimResult.rotation,
            trimResult.trimLeft,
            trimResult.trimTop,
            trimResult.trimRight,
            trimResult.trimBottom,
            inputResult.text))
        .then((BasePictureDocument basePictureDoc) {
      //成功
      MyDialog.successfulSnackBar(
          _scaffoldKey, '追加しました ' + basePictureDoc.docId.toString());
    }).catchError((err) {
      //失敗
      MyDialog.errorSnackBar(_scaffoldKey, '追加できませんでした\n' + err.toString());
    });
  }
}
