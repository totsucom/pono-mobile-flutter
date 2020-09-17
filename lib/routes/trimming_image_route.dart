import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as UI;
import 'package:pono_problem_app/general/trimming_image_painter.dart';
import 'package:pono_problem_app/utils/my_dialog.dart';
import 'package:pono_problem_app/utils/my_widget.dart';
import 'package:image/image.dart' as image;
import 'package:provider/provider.dart';

import '../my_auth_notifier.dart';

//MyPainterクラスからウィジェットの大きさを取得するために使用する
GlobalKey _toolBarGlobalKey = GlobalKey();

//このrouteにpushする場合に渡すパラメータ
class TrimmingImageArgs {
  final String imageURL;
  final String filePath;
  final image.Image imImage;

  final String title;
  final double initTrimLeft,
      initTrimTop,
      initTrimRight,
      initTrimBottom; //0.0-1.0 それぞれからのエッジからの距離
  final bool enableRotation;
  //List<UI.Image> _cachedImage; //描画毎に無限ダウンロードしてしまうので、キャッシュは必須

  //コンストラクタにはimageURL、filePathまたはuiImageの、いずれかのパラメータを渡す
  //使用しない方にはnullを設定する
  TrimmingImageArgs(
      {this.imageURL,
      this.filePath,
      this.imImage,
      this.title = 'トリミング',
      this.initTrimLeft = 0.0,
      this.initTrimTop = 0.0,
      this.initTrimRight = 0.0,
      this.initTrimBottom = 0.0,
      this.enableRotation = true}) {
    if (imageURL == null && filePath == null && imImage == null) {
      throw Exception('TrimmingImageArgsにイメージを渡す必要があります');
    }
  }

  //UI上の処理だけなので、動作を軽るするのに長辺をMAX_SIZEに縮小する
  static List<List<int>> _prepareImages(
      image.Image baseSizeImage /*Uint8List bytes*/) {
    const MAX_SIZE = 480;

    //Image package を使用

    //Imageインスタンスを作成
    //image.Image baseSizeImage = image.decodeImage(bytes);

    //長辺に合わせてリサイズ
    image.Image resizeImage;
    if (baseSizeImage.width > baseSizeImage.height)
      resizeImage = image.copyResize(baseSizeImage, width: MAX_SIZE);
    else
      resizeImage = image.copyResize(baseSizeImage, height: MAX_SIZE);
    baseSizeImage = null;

    //Exif Orientationに合わせて向きを修正
    image.Image bakedImage = image.bakeOrientation(resizeImage);
    resizeImage = null;

    List<List<int>> list = [image.encodePng(bakedImage, level: 1)];
    for (var angle = 90; angle <= 270; angle += 90) {
      list.add(image.encodePng(image.copyRotate(bakedImage, angle), level: 1));
    }
    return list;
    //return image.encodePng(bakedImage, level: 1);
    //return image.encodeJpg(resizeImage, quality: 60);
    //return image.encodeJpg(resizeImage);
  }

  //イメージをダウンロードして加工するためにFutureBuilderで使用する
  Future<List<UI.Image>> getProcessedImagesFuture() async {
    var completer = new Completer<List<UI.Image>>();

    //パラメータに応じて、元画像データをbyte配列化
    image.Image img;
    if (imageURL != null && imageURL.length > 0) {
      try {
        final bundle =
            await NetworkAssetBundle(Uri.parse(imageURL)).load(imageURL);
        final bytes = bundle.buffer.asUint8List();
        img = image.decodeImage(bytes);
      } catch (e) {
        completer.completeError(e);
      }
    } else if (filePath != null && filePath.length > 0) {
      try {
        final bytes = await File(filePath).readAsBytes();
        img = image.decodeImage(bytes);
      } catch (e) {
        completer.completeError(e);
      }
    } else if (imImage != null) {
      img = imImage;
    } else {
      completer.completeError('TrimmingImageArgs()にパラメータが設定されていません');
    }

    if (img != null) {
      try {
        //この関数は重くUIが止まってしまうので、非同期で実行
        //先に90度ずつ回転させた画像を生成

        List<List<int>> newBytes = await compute(_prepareImages, img);
        final images = <UI.Image>[
          await decodeImageFromList(newBytes[0]),
          await decodeImageFromList(newBytes[1]),
          await decodeImageFromList(newBytes[2]),
          await decodeImageFromList(newBytes[3])
        ];
        completer.complete(images);
        debugPrint('トリミング用画像の準備が整いました');
      } catch (e) {
        completer.completeError(e);
      }
    }
    return completer.future;
  }
}

//このrouteがpopする場合に戻すパラメータ
class TrimmingResult {
  //TrimmingImageArgsで渡されたパラメータ
  final String imageURL;
  final String filePath;

  //処理結果
  final int rotation; //0,90,180,270 (Exif情報のOrientation値は含まない)
  final double trimLeft, trimTop, trimRight, trimBottom; //0.0-1.0 各エッジからの距離

  TrimmingResult(this.imageURL, this.filePath, this.rotation, this.trimLeft,
      this.trimTop, this.trimRight, this.trimBottom);
}

class TrimmingImage extends StatefulWidget {
  TrimmingImage({Key key}) : super(key: key);

  @override
  _TrimmingImageState createState() => _TrimmingImageState();
}

class _TrimmingImageState extends State<TrimmingImage> {
  //前画面から渡されたパラメータを保持
  TrimmingImageArgs _arguments;

  Future<List<UI.Image>> _processedImagesFuture;

  //MyPainterクラスに渡す、描画パラメータを保持
  TrimmingImagePainter _paintArgs;

  //SnackBar表示用
  var _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => afterBuild(context));
  }

  //buildが完了したときに呼び出される
  void afterBuild(context) async {
    MyDialog.hintSnackBar(_scaffoldKey, '画像の高さは壁の高さ程度が適当です');
  }

  @override
  Widget build(BuildContext context) {
    if (_paintArgs == null) {
      _paintArgs = TrimmingImagePainter(
          Theme.of(context).primaryColor, Colors.purpleAccent);
    }

    if (_arguments == null) {
      //前画面から渡されたパラメータを読み込む(initState()内ではエラーになる)
      _arguments = ModalRoute.of(context).settings.arguments;
      if (_arguments == null) {
        throw 'trimming_image_routeにTrimmingImageArgsクラスを渡してください';
      } else {
        _paintArgs.trimLeft = _arguments.initTrimLeft;
        _paintArgs.trimTop = _arguments.initTrimTop;
        _paintArgs.trimRight = _arguments.initTrimRight;
        _paintArgs.trimBottom = _arguments.initTrimBottom;

        //ベース画像の取得を開始する
        _processedImagesFuture = _arguments.getProcessedImagesFuture();
        debugPrint('トリミングイメージの準備を開始します。');
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

    return WillPopScope(
        //WillPopScopeで戻るボタンのタップをキャッチ
        onWillPop: _requestPop,
        child: Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            title: Text(_arguments.title),
            centerTitle: true,
            actions: [
              FlatButton(
                child: Icon(Icons.check,
                    color: Theme.of(context).primaryColorLight),
                onPressed: _trimmingCompleted,
              ),
            ],
          ),
          body: FutureBuilder(
              //イメージのダウンロードを待つ
              future: _processedImagesFuture,
              builder: (BuildContext context, future) {
                if (future == null || (!future.hasData && !future.hasError))
                  return MyWidget.loading(context);
                if (future.hasError)
                  return MyWidget.error(context,
                      detail: future.error.toString());

                if (_paintArgs.images == null) {
                  //ダウンロードしたイメージを描画クラスに渡す
                  _paintArgs.images = future.data;
                }

                return Stack(children: <Widget>[
                  GestureDetector(
                    /* Android(S6 Edge)
               *  タップ時    onPanDown onPanCancel onTap
               *  ドラッグ時  onPanDown onPanSTart onPanUpdate onPanEnd
               */

                    // TapDownイベントを検知
                    //onTapDown: _addPoint,
                    onTap: () {
                      debugPrint("onTap");
                    },
                    onPanDown: (details) {
                      //debugPrint("onPanDown");
                      _selectEdge(details.localPosition);
                    },
                    onPanCancel: () {
                      //debugPrint("onPanCancel");
                      _paintArgs.activeEdge = ActiveEdge.None;
                      if (_paintArgs.isUpdated) setState(() {});
                    },
                    onPanStart: (detail) {
                      debugPrint("onPanStart");
                    },
                    onPanUpdate: (details) {
                      //debugPrint("onPanUpdate");
                      if (_paintArgs.activeEdge != ActiveEdge.None)
                        _moveEdge(details.delta.dx, details.delta.dy);
                    },
                    onPanEnd: (detail) {
                      //debugPrint("onPanEnd");
                      _paintArgs.activeEdge = ActiveEdge.None;
                      if (_paintArgs.isUpdated) setState(() {});
                    },

                    // カスタムペイント
                    child: CustomPaint(
                      painter: MyTrimmingPainter(_paintArgs),
                      // タッチを有効にするため、childが必要
                      child: Center(),
                    ),
                  ),
                  Align(
                      //画面上部のツールバー
                      alignment: Alignment.topCenter,
                      child: Container(
                          padding: const EdgeInsets.only(top: 0, bottom: 0),
                          constraints: BoxConstraints.tightFor(
                              height: (_arguments.enableRotation)
                                  ? 80.0
                                  : 0.0), //ツールバーの高さ
                          child: Row(
                            key: _toolBarGlobalKey,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            //crossAxisAlignment: CrossAxisAlignment.start,
                            children: _generateToolBarItems(),
                          ))),
                ]);
              }),
        ));
  }

  //appBarの戻るボタン "←" がタップされた
  Future<bool> _requestPop() async {
    if (_paintArgs.trimLeft != _arguments.initTrimLeft ||
        _paintArgs.trimTop != _arguments.initTrimTop ||
        _paintArgs.trimRight != _arguments.initTrimRight ||
        _paintArgs.trimBottom != _arguments.initTrimBottom) {
      final result = await MyDialog.selectYesNo(context,
          caption: _arguments.title,
          labelText: '変更したトリミング結果が失われてしまいますが、それでも戻りますか？');
      if (result != MyDialogResult.Yes) {
        return new Future.value(false); //戻らない
      }
    }
    return new Future.value(true); //戻る
  }

  //appBarのチェックボタン "✔" がタップされた
  void _trimmingCompleted() async {
    Navigator.of(context).pop(TrimmingResult(
        _arguments.imageURL, //元画像(ネットワークイメージの場合)
        _arguments.filePath, //元画像(ローカルファイルの場合)
        _paintArgs.rotation, //画像の回転角(0,90,180,270度) このほかに元画像がExifを持っていることがある
        _paintArgs.trimLeft, //トリミング結果 0.0～1.0。各エッジからの距離
        _paintArgs.trimTop,
        _paintArgs.trimRight,
        _paintArgs.trimBottom));
  }

  //タップされたときのエッジ選択処理
  void _selectEdge(Offset touchPos) {
    if (!_paintArgs.isReady || _paintArgs.canvasSize.width <= 0)
      return; //準備ができてない

    double d, distance = 1000.0;
    ActiveEdge edge = ActiveEdge.None;
    d = (_paintArgs.leftKnob - touchPos).distance;
    if (d < distance) {
      distance = d;
      edge = ActiveEdge.LeftEdge;
    }
    d = (_paintArgs.topKnob - touchPos).distance;
    if (d < distance) {
      distance = d;
      edge = ActiveEdge.TopEdge;
    }
    d = (_paintArgs.rightKnob - touchPos).distance;
    if (d < distance) {
      distance = d;
      edge = ActiveEdge.RightEdge;
    }
    d = (_paintArgs.bottomKnob - touchPos).distance;
    if (d < distance) {
      distance = d;
      edge = ActiveEdge.BottomEdge;
    }
    if (distance < 20.0) _paintArgs.activeEdge = edge;
    if (_paintArgs.isUpdated) setState(() {});
  }

  //ドラッグによりベース写真を移動する
  void _moveEdge(double delta_x, double delta_y) {
    if (_paintArgs.drawSize == null) return;
    switch (_paintArgs.activeEdge) {
      case ActiveEdge.LeftEdge:
        _paintArgs.trimLeft += delta_x / _paintArgs.drawSize.width;
        break;
      case ActiveEdge.TopEdge:
        _paintArgs.trimTop += delta_y / _paintArgs.drawSize.height;
        break;
      case ActiveEdge.RightEdge:
        _paintArgs.trimRight -= delta_x / _paintArgs.drawSize.width;
        break;
      case ActiveEdge.BottomEdge:
        _paintArgs.trimBottom -= delta_y / _paintArgs.drawSize.height;
        break;
      default:
    }
    if (_paintArgs.isUpdated) setState(() {});
  }

  //画面上部のツールバーを作成
  List<Widget> _generateToolBarItems() {
    return <Widget>[
      Column(
          //左回転ポップアップメニュー
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.rotate_left, color: Colors.white),
              onPressed: () {
                setState(() {
                  _paintArgs.rotateLeft();
                });
              },
            ),
            Expanded(
                child: Text('左に回転',
                    style: TextStyle(color: Colors.white, fontSize: 12.0)))
          ]),
      Column(
          //右回転ポップアップメニュー
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.rotate_right, color: Colors.white),
              onPressed: () {
                setState(() {
                  _paintArgs.rotateRight();
                });
              },
            ),
            Expanded(
                child: Text('右に回転',
                    style: TextStyle(color: Colors.white, fontSize: 12.0)))
          ]),
    ];
  }
}

class MyTrimmingPainter extends CustomPainter {
  final TrimmingImagePainter _paintArgs;

  MyTrimmingPainter(this._paintArgs);

  @override
  bool shouldRepaint(MyTrimmingPainter oldDelegate) {
    return _paintArgs.isUpdatedAndReset;
  }

  @override
  void paint(Canvas canvas, Size canvasSize) {
    if (_paintArgs == null) return;

    //画面上部のツールバーと画面下のスライダー領域を取得
    final toolBarSize =
        ((_toolBarGlobalKey.currentContext.findRenderObject()) as RenderBox)
            .size;

    //画面上部のツールバーと画面下部のスライダーの背景をクリッピングする
    /*var rect = Rect.fromLTWH(0, toolBarSize.height, size.width,
        size.height - toolBarSize.height - sliderSize.height);
    canvas.clipRect(rect);*/

    //メインの描画
    _paintArgs.paint(canvas, canvasSize, toolBarSize.height);

    //画面上部のツールバーの背景を塗りつぶしてUIが見えるようにする
    final paint = Paint();
    paint.color = Colors.black38;
    canvas.drawRect(
        Rect.fromLTWH(0, 0, canvasSize.width, toolBarSize.height), paint);
  }
}
