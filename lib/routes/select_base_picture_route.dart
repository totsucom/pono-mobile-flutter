import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pono_problem_app/records/base_picture.dart';
import 'package:pono_problem_app/records/base_picture_datastore.dart';
import 'package:pono_problem_app/records/thumbnail_datastore.dart';
import 'package:pono_problem_app/records/user_datastore.dart';
import 'package:pono_problem_app/routes/base_picture_view_route.dart';
import 'package:pono_problem_app/routes/edit_holds_route.dart';
import 'package:pono_problem_app/storage/base_picture_storage.dart';
import 'package:pono_problem_app/utils/content_type.dart';
import 'package:pono_problem_app/utils/formatter.dart';
import 'package:pono_problem_app/utils/my_dialog.dart';
import 'package:pono_problem_app/utils/menu_item.dart';
import 'package:pono_problem_app/utils/unique.dart';
import '../globals.dart';
import 'dart:ui' as UI;

class _SelectBasePictureAppBarPopupMenuItem {
  static const selectFromGallery = 'アルバムから選択';
  static const selectFromCamera = '写真を撮る';
}

class SelectBasePicture extends StatefulWidget {
  SelectBasePicture({Key key}) : super(key: key);

  @override
  _SelectBasePictureState createState() => _SelectBasePictureState();
}

class _SelectBasePictureState extends State<SelectBasePicture> {
  @override
  void initState() {
    super.initState();
  }

  //appBarのポップアップメニュー
  List<MenuItem<String>> _appBarPopupMenuItems = [
    MenuItem<String>(_SelectBasePictureAppBarPopupMenuItem.selectFromGallery,
        title: _SelectBasePictureAppBarPopupMenuItem.selectFromGallery,
        icon: Icon(Icons.image)),
    MenuItem<String>(_SelectBasePictureAppBarPopupMenuItem.selectFromCamera,
        title: _SelectBasePictureAppBarPopupMenuItem.selectFromCamera,
        icon: Icon(Icons.camera_alt)),
  ];

  @override
  Widget build(BuildContext context) {
    debugPrint("select_base_picture_routeのbuild()");
    return Scaffold(
      appBar: new AppBar(
        title: Text(BasePicture.baseName + 'を選択'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: _handlePopupMenuSelected,
            itemBuilder: (BuildContext context) => _appBarPopupMenuItems
                .map((item) => PopupMenuItem<String>(
                    value: item.title,
                    child:
                        ListTile(leading: item.icon, title: Text(item.title))))
                .toList(),
          )
        ],
      ),
      body: _buildBody(context),
      /*floatingActionButton: Visibility(
        visible: !showCheckboxes,
        child: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () {
            _addNewBasePicture(context);
          },
        ),
      ),*/
    );
  }

  Widget _buildBody(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: BasePictureDatastore.getBasePicturesStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return LinearProgressIndicator();
        return _buildListView(context, snapshot.data.documents);
      },
    );
  }

  Widget _buildListView(BuildContext context, List<DocumentSnapshot> snapshot) {
    return GridView.extent(
      padding: const EdgeInsets.all(4.0),
      maxCrossAxisExtent: 200,
      crossAxisSpacing: 10.0, //縦
      mainAxisSpacing: 10.0, //横
      childAspectRatio: 0.7, //縦長
      shrinkWrap: true,
      children: snapshot.map((data) => _buildGridItem(context, data)).toList(),
    );
  }

  Widget _buildGridItem(BuildContext context, DocumentSnapshot snapshot) {
    final basePictureDoc = new BasePictureDocument(
        snapshot.documentID, BasePicture.fromMap(snapshot.data));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          new BoxShadow(
            color: Colors.grey,
            offset: new Offset(5.0, 5.0),
            blurRadius: 10.0,
          )
        ],
      ),
      child: _buildListTile2(context, basePictureDoc),
      /*)*/
    );
  }

  Widget _buildListTile2(
      BuildContext context, BasePictureDocument basePictureDoc) {
    return GestureDetector(
      child: Column(
          //mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            /*ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 100),
            child:*/
            /*Container(
            height: 150,
            child: ThumbnailDatastore.thumbnailStreamBuilder(
                context, basePictureDoc.basePicture.picturePath),
          ),*/
            //),
            Expanded(
                flex: 8,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  child: ThumbnailDatastore.thumbnailStreamBuilder(
                      context, basePictureDoc.basePicture.picturePath),
                )),
            /*Container(
              margin: EdgeInsets.all(16.0),
              child: Text(basePictureDoc.basePicture.name)),*/
            Expanded(
              flex: 2,
              child: Text(basePictureDoc.basePicture.name),
            )
          ]),
      onTap: () {
        _handleSelectedBasePicture(basePictureDoc);
      },
    );
  }

  Future<UI.Image> decodeImageFromList(Uint8List list) {
    final Completer<UI.Image> completer = Completer<UI.Image>();
    UI.decodeImageFromList(list, completer.complete);
    return completer.future;
  }

  void _handlePopupMenuSelected(String value) async {
    switch (value) {
      case _SelectBasePictureAppBarPopupMenuItem.selectFromGallery:

        //アルバムから撮影
        final pickedFile = await ImagePicker().getImage(
            source: ImageSource.gallery,
            maxWidth: BasePictureDatastore.BASE_PICTURE_MAX_WIDTH,
            maxHeight: BasePictureDatastore.BASE_PICTURE_MAX_HEIGHT);
        if (pickedFile == null || pickedFile.path == null) return;

        /*Uint8List bytes = pickedFile.readAsBytes() as Uint8List;
        if (bytes == null) return;

        UI.Image image = await decodeImageFromList(bytes);*/

        Navigator.of(context).pushNamed('/edit_problem/edit_holds',
            arguments: EditHoldsArgs(pickedBasePicture: pickedFile));
        break;

      case _SelectBasePictureAppBarPopupMenuItem.selectFromCamera:

        //カメラで撮影
        final pickedFile = await ImagePicker().getImage(
            source: ImageSource.camera,
            maxWidth: BasePictureDatastore.BASE_PICTURE_MAX_WIDTH,
            maxHeight: BasePictureDatastore.BASE_PICTURE_MAX_HEIGHT);
        if (pickedFile == null || pickedFile.path == null) return;

        /*Uint8List bytes = await pickedFile.readAsBytes();
        if (bytes == null) return;

        UI.Image image = await decodeImageFromList(bytes);*/

        Navigator.of(context).pushNamed('/edit_problem/edit_holds',
            arguments: EditHoldsArgs(pickedBasePicture: pickedFile));
        break;
    }
  }

  void _handleSelectedBasePicture(BasePictureDocument basePictureDoc) async {
    //ベース写真をホールド編集に渡す

    final url = basePictureDoc.basePicture.pictureURL;
    /*final bundle = await NetworkAssetBundle(Uri.parse(url)).load(url);
    if (bundle == null) return;

    Uint8List bytes = bundle.buffer.asUint8List();
    UI.Image image = await decodeImageFromList(bytes);*/

    Navigator.of(context).pushNamed('/edit_problem/edit_holds',
        arguments: EditHoldsArgs(basePictureURL: url));
  }

  /*
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
        maxWidth: BasePictureStorage.MAX_WIDTH,
        maxHeight: BasePictureStorage.MAX_HEIGHT);
    if (pickedFile == null || pickedFile.path == null) return;

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

    //名前の入力
    final MyDialogTextResult inputResult = await MyDialog.inputText(context,
        caption: BasePicture.baseName,
        labelText: BasePictureFieldCaption.name,
        hintText: 'A壁 など',
        minTextLength: 1,
        maxTextLength: 20);
    if (inputResult == null || inputResult.result != MyDialogResult.OK) return;

    //これ以降はユーザーを待たせないために await しない

    //ベース写真の追加
    BasePictureDatastore.addBasePicture(
            inputResult.text, Globals.firebaseUser.uid, croppedFile)
        .then((String documentID) {
      //成功
      MyDialog.successfulSnackBar(_scaffoldKey, '追加しました');
    }).catchError((err) {
      //失敗
      MyDialog.errorSnackBar(_scaffoldKey, '追加できませんでした\n' + err.toString());
    });
  }
*/
}
