import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pono_problem_app/my_auth_notifier.dart';
import 'package:pono_problem_app/records/base_picture.dart';
import 'package:pono_problem_app/records/base_picture_datastore.dart';
import 'package:pono_problem_app/records/user.dart';
import 'package:pono_problem_app/records/user_datastore.dart';
import 'package:pono_problem_app/records/wall.dart';
import 'package:pono_problem_app/records/wall_datastore.dart';
import 'package:pono_problem_app/routes/base_picture_view_route.dart';
import 'package:pono_problem_app/routes/home_route.dart';
import 'package:pono_problem_app/routes/trimming_image_route.dart';
import 'package:pono_problem_app/storage/storage_result.dart';
import 'package:pono_problem_app/utils/formatter.dart';
import 'package:pono_problem_app/utils/my_dialog.dart';
import 'package:pono_problem_app/utils/my_widget.dart';
import 'package:provider/provider.dart';
import '../globals.dart';

class ManageWall extends StatefulWidget {
  ManageWall({Key key}) : super(key: key);

  @override
  _ManageWallState createState() => _ManageWallState();
}

class _ManageWallState extends State<ManageWall> {
  var _scaffoldKey = GlobalKey<ScaffoldState>();

  List<WallDocument> _wallDocs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => afterBuild(context));
  }

  //buildが完了したときに呼び出される
  void afterBuild(context) async {
    WallDatastore.getWalls(false, true).then((wallDocs) {
      setState(() {
        _wallDocs = wallDocs;
      });
    }).catchError((err) {
      _wallDocs = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("manage_wall_routeのbuild()");

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
      key: _scaffoldKey,
      appBar: new AppBar(
        title: Text(
          Wall.baseName + 'の管理',
          style: TextStyle(color: Colors.yellow),
        ),
        centerTitle: true,
        actions: [],
      ),
      body: _buildBody(context),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          //_addNewBasePicture(context, auth);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_wallDocs == null) return MyWidget.loading(context);
    if (_wallDocs.length == 0)
      return MyWidget.empty(context,
          message: Wall.baseName + 'はありません。\n\n＋ ボタンで追加できます。');
    return _buildListView(context, _wallDocs);
    /*
      FutureBuilder<List<WallDocument>>(
      future: WallDatastore.getWalls(false, true),
      builder: (context, AsyncSnapshot<List<WallDocument>> snapshot) {
        //定型文
        if (snapshot == null || (!snapshot.hasData && !snapshot.hasError))
          return MyWidget.loading(context);
        if (snapshot.hasError)
          return MyWidget.error(context, detail: snapshot.error.toString());
        return _buildListView(context, snapshot.data);
      },
    );*/
  }

  Widget _buildListView(BuildContext context, List<WallDocument> wallDocs) {
    return ReorderableListView(
      padding: const EdgeInsets.only(
          top: 0, bottom: kFloatingActionButtonMargin + 32),
      header: ListTile(
        title: Padding(
            padding: EdgeInsets.only(left: 48),
            child: Text(Wall.baseName + 'の' + WallFieldCaption.name)),
        trailing: Padding(
          padding: EdgeInsets.only(right: 4),
          child: Text('無効／有効'),
        ),
      ),
      children:
          wallDocs.map((wallDoc) => _buildListItem(context, wallDoc)).toList(),
      onReorder: (oldIndex, newIndex) {
        debugPrint(oldIndex.toString());
        debugPrint(newIndex.toString());

        //UIを更新
        if (oldIndex < newIndex) newIndex -= 1;
        final WallDocument doc = _wallDocs.removeAt(oldIndex);
        setState(() {
          _wallDocs.insert(newIndex, doc);
        });

        //Firestoreを更新
        Future.delayed(Duration.zero).then((_) async {
          WallDatastore.reorder(
                  _wallDocs.map((wallDoc) => wallDoc.docId).toList(), true)
              .then((value) => null)
              .catchError((err) {
            MyDialog.errorSnackBar(_scaffoldKey, '順番を更新できませんでした');

            //UIを戻す
            final WallDocument doc = _wallDocs.removeAt(newIndex);
            setState(() {
              _wallDocs.insert(oldIndex, doc);
            });
          });
        });
      },
    );
  }

  Widget _buildListItem(BuildContext context, WallDocument wallDoc) {
    return Card(
      elevation: 2.0,
      key: ValueKey(wallDoc.docId), //Key(model.key),
      child: ListTile(
        leading: const Icon(Icons.wallpaper),
        title: Text(wallDoc.data.name),
        trailing: Switch(
          activeColor: Colors.blue,
          value: wallDoc.data.active,
          onChanged: (newValue) {
            setState(() {
              wallDoc.data.active = !wallDoc.data.active;
            });
            WallDatastore.updateWallActivation(wallDoc.docId, newValue, true)
                .then((value) => null)
                .catchError((err) {
              MyDialog.errorSnackBar(_scaffoldKey, '有効／無効を更新できませんでした');

              //UIを戻す
              setState(() {
                wallDoc.data.active = !wallDoc.data.active;
              });
            });
          },
        ),
      ),
    );
  }
}
