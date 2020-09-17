import 'dart:async';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pono_problem_app/records/base_picture.dart';
import 'package:pono_problem_app/records/base_picture_datastore.dart';
import 'package:pono_problem_app/records/thumbnail_datastore.dart';
import 'package:pono_problem_app/routes/edit_holds_route.dart';
import 'package:pono_problem_app/utils/menu_item.dart';
import 'package:pono_problem_app/utils/my_dialog.dart';
import 'package:pono_problem_app/utils/my_widget.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as UI;

import '../globals.dart';
import '../my_auth_notifier.dart';
import 'home_route.dart';

class SelectBasePicture extends StatefulWidget {
  SelectBasePicture({Key key}) : super(key: key);

  @override
  _SelectBasePictureState createState() => _SelectBasePictureState();
}

class _SelectBasePictureState extends State<SelectBasePicture> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => afterBuild(context));
  }

  //buildが完了したときに呼び出される
  void afterBuild(context) async {
    /*
    // 各ルートで必要な認証情報の監視
    FirebaseAuth.instance.onAuthStateChanged
        .listen((FirebaseUser firebaseUser) {
      if (firebaseUser == null) {
        // 認証ユーザーが無くなった
        debugPrint('認証ユーザーが無くなったのでホームに強制送還します');
        Home.snackBarWidgetFromOutside = MyWidget.errorSnackBar('認証情報が失われました。');
        Navigator.of(context).popUntil(ModalRoute.withName("/"));
      } else if (firebaseUser.uid != Globals.firebaseUser.uid) {
        // 認証ユーザーが変わった
        debugPrint('認証ユーザーが異なるのでホームに強制送還します');
        Home.snackBarWidgetFromOutside =
            MyWidget.errorSnackBar('認証情報に相違が生じました。');
        Navigator.of(context).popUntil(ModalRoute.withName("/"));
      }
    });
     */
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("select_base_picture_routeのbuild()");

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

    return Scaffold(
      appBar: new AppBar(
        title: Text(BasePicture.baseName + 'を選択'),
        centerTitle: true,
        /*actions: [
          PopupMenuButton<String>(
            onSelected: _handlePopupMenuSelected,
            itemBuilder: (BuildContext context) => _appBarPopupMenuItems
                .map((item) => PopupMenuItem<String>(
                    value: item.title,
                    child:
                        ListTile(leading: item.icon, title: Text(item.title))))
                .toList(),
          )
        ],*/
      ),
      body: _buildBody(context),
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
    final List<Widget> list = List.from([
      _buildGridItem(
          context, Icon(Icons.image, size: 50.0), 'アルバムから選択', 'album'),
      _buildGridItem(
          context, Icon(Icons.camera_alt, size: 50.0), 'カメラで撮影', 'gallery')
    ])
      ..addAll(snapshot
          .map((data) => _buildBasePictureGridItem(context, data))
          .toList());

    return GridView.extent(
      padding: const EdgeInsets.all(4.0),
      maxCrossAxisExtent: 200,
      crossAxisSpacing: 10.0, //縦
      mainAxisSpacing: 10.0, //横
      childAspectRatio: 0.8, //縦長
      shrinkWrap: true,
      children:
          list, //snapshot.map((data) => _buildGridItem(context, data)).toList(),
    );
  }

  Widget _buildBasePictureGridItem(
      BuildContext context, DocumentSnapshot snapshot) {
    final basePictureDoc = new BasePictureDocument(
        snapshot.documentID, BasePicture.fromMap(snapshot.data));

    Widget thumbnailWidget;
    if (basePictureDoc.data.thumbnailURL.length == 0) {
      if (basePictureDoc.data.createdAt != null) {
        // ↑ 瞬間nullのパターンが発生するみたい
        final duration =
            DateTime.now().difference(basePictureDoc.data.createdAt);
        if (duration.inMinutes > 2)
          //2分越えてURLが無いのはエラーしかない
          thumbnailWidget =
              Icon(Icons.error, color: Theme.of(context).errorColor);
      }
      if (thumbnailWidget == null)
        //CloudFunctions処理待ち(エラー表示回避)
        thumbnailWidget = Center(
            child: SizedBox(
                width: 50, height: 50, child: CircularProgressIndicator()));
    } else {
      thumbnailWidget = (basePictureDoc.data.thumbnailURL.length == 0)
          ? Center(
              child: SizedBox(
                  width: 50,
                  height: 50,
                  child:
                      CircularProgressIndicator())) //CloudFunctions処理待ち(エラー表示回避)
          : CachedNetworkImage(
              imageUrl: basePictureDoc.data.thumbnailURL,
              placeholder: (context, url) => Center(
                  child: SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator())),
              errorWidget: (context, url, error) =>
                  Icon(Icons.error, color: Theme.of(context).errorColor));
    }
    return _buildGridItem(
        context, thumbnailWidget, basePictureDoc.data.name, basePictureDoc);
  }

  Widget _buildGridItem(BuildContext context, Widget thumbnail, String text,
      basePictureDocOrType) {
    return GestureDetector(
      child: Container(
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
        child: Column(children: <Widget>[
          Expanded(
              flex: 17,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: thumbnail,
              )),
          Expanded(
            flex: 3,
            child: Text(text),
          )
        ]),
      ),
      /*)*/
      onTap: () {
        _handleSelectedBasePicture(basePictureDocOrType);
      },
    );
  }

  //画面右上のポップアップメニューの処理
  /*void _handlePopupMenuSelected(String value) async {
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
  }*/

  //ベース写真がタップされた
  void _handleSelectedBasePicture(basePictureDocOrType) async {
    if (basePictureDocOrType is String) {
      if (basePictureDocOrType == 'album') {
        //アルバムから選択
        final pickedFile = await ImagePicker().getImage(
            source: ImageSource.gallery,
            //でかすぎると処理が重くなるので適当に制限
            maxWidth: 1200,
            maxHeight: 1200);
        //選択後、ホールド編集に渡す
        if (pickedFile == null || pickedFile.path == null) return;
        Navigator.of(context).pushNamed('/edit_problem/edit_holds',
            arguments: EditHoldsArgs(null, pickedFile.path));
      } else if (basePictureDocOrType == 'gallery') {
        //カメラで撮影
        final pickedFile = await ImagePicker().getImage(
            source: ImageSource.camera,
            //でかすぎると処理が重くなるので適当に制限
            maxWidth: 1200,
            maxHeight: 1200);
        //撮影後、ホールド編集に渡す
        if (pickedFile == null || pickedFile.path == null) return;
        Navigator.of(context).pushNamed('/edit_problem/edit_holds',
            arguments: EditHoldsArgs(null, pickedFile.path));
      }
    } else {
      //basePictureDocOrType = BasePictureDocument
      //登録されたベース写真から選択した
      //ベース写真をホールド編集に渡す
      final basePictureDoc = basePictureDocOrType as BasePictureDocument;
      final url = basePictureDoc.data.pictureURL;
      Navigator.of(context).pushNamed('/edit_problem/edit_holds',
          arguments: EditHoldsArgs(url, null, basePictureDoc.data.wallIDs));
    }
  }
}
