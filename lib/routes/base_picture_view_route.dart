import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pono_problem_app/records/base_picture.dart';
import 'package:pono_problem_app/records/base_picture_datastore.dart';
import 'package:pono_problem_app/records/user_datastore.dart';
import 'package:pono_problem_app/utils/formatter.dart';
import 'package:pono_problem_app/utils/my_dialog.dart';

//このrouteにpushする場合に渡すパラメータ
class BasePictureViewArgs {
  String documentID;
  GlobalKey<ScaffoldState> scaffoldGlobalKey;
  BasePictureViewArgs(this.documentID, this.scaffoldGlobalKey);
}

class BasePictureView extends StatefulWidget {
  BasePictureView({Key key}) : super(key: key);

  @override
  _BasePictureViewState createState() => _BasePictureViewState();
}

class _BasePictureViewState extends State<BasePictureView> {
  //前画面から渡されたパラメータを保持
  BasePictureViewArgs _arguments;

  var _scaffoldKey = GlobalKey<ScaffoldState>();

  final textEdit = TextEditingController();
  BasePictureDocument basePictureDoc;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => afterBuild(context));
  }

  //buildが完了したときに呼び出される
  void afterBuild(context) async {
    final docID = _arguments.documentID;
    if (docID != null) {
      //ウィジェットと同じスナップショットをlistenして、データの変更(削除)に備える
      BasePictureDatastore.getBasePictureSnapshot(docID)
          .listen((DocumentSnapshot documentSnapshot) {
        if (documentSnapshot.data == null) {
          debugPrint('表示中のBasePictureが削除されました。');

          //表示中のデータが削除されると、streamがnullを返すため、ビルダーで
          //エラーが発生してしまうが、エラーを表示してもしかたないので
          //前画面に戻してしまう。
          Navigator.of(context).pop();
        }
      });
    }
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
      }
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: new AppBar(
        title: Text('${BasePicture.baseName}の詳細'),
        centerTitle: true,
        actions: [
          Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: IconButton(
                icon: Icon(Icons.delete_outline),
                onPressed: () {
                  if (basePictureDoc != null) deleteBasePicture(basePictureDoc);
                },
              )),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final docID = _arguments.documentID;
    if (!(docID is String) || docID == null) {
      return Text('エラー！：このルートにはBasePictureのDocumentIDを渡す必要があります');
    }
    debugPrint("表示するドキュメント " + docID);
    return SingleChildScrollView(
        child: StreamBuilder<DocumentSnapshot>(
      stream: BasePictureDatastore.getBasePictureStream(docID),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: LinearProgressIndicator());
        }
        return _buildView(context, snapshot.data);
      },
    ));
  }

  Widget _buildView(BuildContext context, DocumentSnapshot snapshot) {
    basePictureDoc = BasePictureDocument(
        snapshot.documentID, BasePicture.fromMap(snapshot.data));

    return Column(children: <Widget>[
      Row(children: <Widget>[
        //名前の行
        Expanded(
            flex: 4,
            child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Text(BasePictureFieldCaption.name,
                    textAlign: TextAlign.right))),
        Expanded(
            flex: 6,
            child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Row(children: <Widget>[
                  Text(basePictureDoc.basePicture.name,
                      textAlign: TextAlign.left),
                  IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () {
                        editBasePictureName(context, basePictureDoc);
                      })
                ]))),
      ]),
      Row(children: <Widget>[
        //登録者の行
        Expanded(
            flex: 4,
            child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Text(BasePictureFieldCaption.userID,
                    textAlign: TextAlign.right))),
        Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: UserDatastore.displayNameFutureBuilder(
                  basePictureDoc.basePicture.userID),
            )),
      ]),
      Row(children: <Widget>[
        //登録日の行
        Expanded(
            flex: 4,
            child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Text(BasePictureFieldCaption.createdAt,
                    textAlign: TextAlign.right))),
        Expanded(
            flex: 6,
            child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Text(
                    Formatter.toYMD_HM(basePictureDoc.basePicture.createdAt),
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
                child: Text(basePictureDoc.documentId,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).disabledColor)))),
      ]),
      Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: CachedNetworkImage(
            imageUrl: basePictureDoc.basePicture.pictureURL,
            placeholder: (context, url) =>
                Center(child: CircularProgressIndicator()),
            errorWidget: (context, url, error) => Icon(
              Icons.error,
              color: Theme.of(context).errorColor,
            ),
          )),
    ]);
  }

  Future<void> deleteBasePicture(BasePictureDocument doc) async {
    final result = await MyDialog.selectYesNo(context,
        caption: BasePicture.baseName,
        labelText: 'この${BasePicture.baseName}を削除しますか？');
    if (result == MyDialogResult.Yes) {
      BasePictureDatastore.deleteBasePicture(doc.documentId).then((_) {
        //GlobalKeyは前画面のものを使う。削除したら前画面に戻るため
        MyDialog.successfulSnackBar(_arguments.scaffoldGlobalKey, '削除しました');
      }).catchError((err) {
        MyDialog.errorSnackBar(_scaffoldKey, '削除できませんでした\n' + err.toString());
      });
    }
  }

  Future<void> editBasePictureName(
      BuildContext context, BasePictureDocument doc) async {
    final MyDialogTextResult inputResult = await MyDialog.inputText(context,
        caption: BasePicture.baseName,
        labelText: BasePictureFieldCaption.name,
        initialText: doc.basePicture.name,
        minTextLength: 1,
        maxTextLength: 20);

    if (inputResult != null && inputResult.result == MyDialogResult.OK) {
      //Firestoreのデータを更新
      doc.basePicture.name = inputResult.text; //新しい名前を設定
      BasePictureDatastore.updateBasePicture(doc.documentId, doc.basePicture)
          .then((bool result) {
        //成功
      }).catchError((err) {
        //失敗
        MyDialog.errorSnackBar(_scaffoldKey, '更新できませんでした\n' + err.toString());
      });
    }
  }
}