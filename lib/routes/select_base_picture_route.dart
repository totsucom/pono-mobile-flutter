import 'dart:async';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pono_problem_app/records/base_picture.dart';
import 'package:pono_problem_app/records/base_picture_datastore.dart';
import 'package:pono_problem_app/records/thumbnail_datastore.dart';
import 'package:pono_problem_app/routes/edit_holds_route.dart';
import 'package:pono_problem_app/utils/menu_item.dart';
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
        return _buildGridView(context, snapshot.data.documents);
      },
    );
  }

  Widget _buildGridView(BuildContext context, List<DocumentSnapshot> snapshot) {
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
      child: _buildTile(context, basePictureDoc),
      /*)*/
    );
  }

  Widget _buildTile(BuildContext context, BasePictureDocument basePictureDoc) {
    Widget thumbnailWidget;
    thumbnailWidget =
        SizedBox(width: 50.0, height: 50.0, child: CircularProgressIndicator());
    /*if (basePictureDoc.basePicture.thumbnailURL.length == 0) {
      if (basePictureDoc.basePicture.createdAt != null) {
        // ↑ 瞬間nullのパターンが発生するみたい
        final duration =
            DateTime.now().difference(basePictureDoc.basePicture.createdAt);
        if (duration.inMinutes > 2)
          //2分越えてURLが無いのはエラーしかない
          thumbnailWidget =
              Icon(Icons.error, color: Theme.of(context).errorColor);
      }
      if (thumbnailWidget == null)
        //CloudFunctuins処理待ち(エラー表示回避)
        thumbnailWidget =
            SizedBox(width: 50, height: 50, child: CircularProgressIndicator());
    } else {
      thumbnailWidget = (basePictureDoc.basePicture.thumbnailURL.length == 0)
          ? SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator()) //CloudFunctuins処理待ち(エラー表示回避)
          : CachedNetworkImage(
              imageUrl: basePictureDoc.basePicture.thumbnailURL,
              placeholder: (context, url) => SizedBox(
                  width: 50, height: 50, child: CircularProgressIndicator()),
              errorWidget: (context, url, error) =>
                  Icon(Icons.error, color: Theme.of(context).errorColor));
    }*/
    return GestureDetector(
      child: Column(children: <Widget>[
        Expanded(
            flex: 8,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: thumbnailWidget,
            )),
        Expanded(
          flex: 2,
          child: Text(basePictureDoc.data.name),
        )
      ]),
      onTap: () {
        _handleSelectedBasePicture(basePictureDoc);
      },
    );
  }

  //画面右上のポップアップメニューの処理
  void _handlePopupMenuSelected(String value) async {
    switch (value) {
      case _SelectBasePictureAppBarPopupMenuItem.selectFromGallery:
        //アルバムから撮影
        final pickedFile = await ImagePicker().getImage(
            source: ImageSource.gallery,
            //でかすぎると処理が重くなるので適当に制限
            maxWidth: 1200,
            maxHeight: 1200);
        if (pickedFile == null || pickedFile.path == null) return;
        Navigator.of(context).pushNamed('/edit_problem/edit_holds',
            arguments: EditHoldsArgs(null, pickedFile.path));
        break;
      case _SelectBasePictureAppBarPopupMenuItem.selectFromCamera:
        //カメラで撮影
        final pickedFile = await ImagePicker().getImage(
            source: ImageSource.camera,
            //でかすぎると処理が重くなるので適当に制限
            maxWidth: 1200,
            maxHeight: 1200);
        if (pickedFile == null || pickedFile.path == null) return;
        Navigator.of(context).pushNamed('/edit_problem/edit_holds',
            arguments: EditHoldsArgs(null, pickedFile.path));
        break;
    }
  }

  //ベース写真がタップされた
  void _handleSelectedBasePicture(BasePictureDocument basePictureDoc) async {
    //ベース写真をホールド編集に渡す
    final url = basePictureDoc.data.pictureURL;
    Navigator.of(context).pushNamed('/edit_problem/edit_holds',
        arguments: EditHoldsArgs(url, null));
  }
}
