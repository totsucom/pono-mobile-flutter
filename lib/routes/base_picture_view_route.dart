import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pono_problem_app/records/base_picture.dart';
import 'package:pono_problem_app/records/base_picture_datastore.dart';
import 'package:pono_problem_app/records/user_datastore.dart';
import 'package:pono_problem_app/utils/formatter.dart';
import 'package:pono_problem_app/utils/my_dialog.dart';
import 'package:pono_problem_app/utils/my_document_notifier.dart';
import 'package:pono_problem_app/utils/my_widget.dart';
import 'package:provider/provider.dart';

import '../globals.dart';
import '../my_auth_notifier.dart';
import 'edit_problem_route.dart';
import 'home_route.dart';
import 'manage_base_picture_route.dart';

//このrouteにpushする場合に渡すパラメータ
class BasePictureViewArgs {
  final String documentID;
  BasePictureViewArgs(this.documentID);
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
  void afterBuild(context) async {}

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

    return ChangeNotifierProvider(
        create: (_) => MyDocumentNotifier(
            BasePictureDatastore.getDocumentPath(_arguments.documentID), true),
        child: Consumer<MyDocumentNotifier>(
            builder: (context, MyDocumentNotifier myDocumentNotifier, _) {
          if (myDocumentNotifier.reason == MyDocumentNotifyReason.Deleted) {
            // 表示中のドキュメントが削除されたので前の画面に戻る
            Future.delayed(Duration.zero).then((_) async {
              await MyDialog.ok(context,
                  caption: 'エラー',
                  labelText: '表示中の${BasePicture.baseName}が削除されました',
                  dismissible: false);
              Navigator.of(context).pop();
            });
            return MyWidget.empty(context, scaffold: true);
          }

          // 通常の表示
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
                        if (basePictureDoc != null)
                          deleteBasePicture(basePictureDoc);
                      },
                    )),
              ],
            ),
            body: _buildBody(context),
          );
        }));
  }

  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
        child: FutureBuilder(
            future: BasePictureDatastore.getBasePicture(
                _arguments.documentID, false),
            builder: (context, future) {
              debugPrint('hasData = ' + future.hasData.toString());
              debugPrint('hasError = ' + future.hasError.toString());
              if (future.hasError) {
                return MyWidget.error(context,
                    text: '${BasePicture.baseName}を読み込めませんでした',
                    detail: future.error.toString());
              } else if (!future.hasData) {
                return MyWidget.loading(context);
              }
              return _buildView(context, future.data);
            }));
/*
    final docID = _arguments.documentID;
    if (!(docID is String) || docID == null) {
      return Text('エラー！：このルートにはBasePictureのDocumentIDを渡す必要があります');
    }
    debugPrint("表示するドキュメント " + docID);
    return SingleChildScrollView(
        child: StreamBuilder<DocumentSnapshot>(
      stream: BasePictureDatastore.getBasePictureStream(docID),
      builder: (context, snapshot) {
        //定型文
        if (snapshot == null || (!snapshot.hasData && !snapshot.hasError))
          return MyWidget.loading(context);
        if (snapshot.hasError)
          return MyWidget.error(context, snapshot.error.toString());
        //一応、前のん
        //if (!snapshot.hasData) {
        //  return Center(child: LinearProgressIndicator());
        //}
        return _buildView(context, snapshot.data);
      },
    ));
 */
  }

  Widget _buildView(BuildContext context, BasePictureDocument basePictureDoc) {
    // 第三者がドキュメントを削除したときに、下記のコンストラクタで null 例外が発生する
    // のを*一時的に回避。　※このコードを StreamBuilder の直後の、 .hasData 判定に
    // 置いても防ぐことができない。なんでだろう
    // *一時的に回避というのは、別途リスナーで監視しているため、即座に前画面に pop()
    // するようになっている
    //if (basePictureDoc.data == null) return Text('');

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
                  Text(basePictureDoc.data.name, textAlign: TextAlign.left),
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
                child: Text(BasePictureFieldCaption.uid,
                    textAlign: TextAlign.right))),
        Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: MyWidget.getDisplayName(basePictureDoc.data.uid),
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
                child: Text(Formatter.toYMD_HM(basePictureDoc.data.createdAt),
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
                child: Text(basePictureDoc.docId,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).disabledColor)))),
      ]),
      Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: CachedNetworkImage(
            imageUrl: basePictureDoc.data.pictureURL,
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
      BasePictureDatastore.deleteBasePicture(doc.docId, true).then((_) {
        //GlobalKeyは前画面のものを使う。削除したら前画面に戻るため
        //MyDialog.successfulSnackBar(_arguments.scaffoldGlobalKey, '削除しました');

        //リスナーが検知してくれるので処理しない
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
        initialText: doc.data.name,
        minTextLength: 1,
        maxTextLength: 20);

    if (inputResult != null && inputResult.result == MyDialogResult.OK) {
      //Firestoreのデータを更新
      doc.data.name = inputResult.text; //新しい名前を設定
      BasePictureDatastore.updateBasePicture(doc, true).then((bool result) {
        //成功
      }).catchError((err) {
        //失敗
        MyDialog.errorSnackBar(_scaffoldKey, '更新できませんでした\n' + err.toString());
      });
    }
  }
}
