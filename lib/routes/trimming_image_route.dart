import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as UI;
import 'package:pono_problem_app/general/trimming_painter.dart';
import 'package:pono_problem_app/utils/my_dialog.dart';
import 'package:pono_problem_app/utils/my_widget.dart';
import 'package:image/image.dart' as image;

//MyPainterクラスからウィジェットの大きさを取得するために使用する
GlobalKey _toolBarGlobalKey = GlobalKey();

//このrouteにpushする場合に渡すパラメータ
class TrimmingImageArgs {
  final title;
  final double initTrimLeft, initTrimTop, initTrimRight, initTrimBottom;
  final String imageURL;
  final String filePath;
  List<UI.Image> _cachedImage; //描画毎に無限ダウンロードしてしまうので、キャッシュは必須

  //コンストラクタにはimageURLまたはfilePathの、いずれかのパラメータを渡す
  //使用しない方にはnullを設定する
  TrimmingImageArgs(this.imageURL, this.filePath,
      {this.title = 'トリミング',
      this.initTrimLeft = 0.0,
      this.initTrimTop = 0.0,
      this.initTrimRight = 0.0,
      this.initTrimBottom = 0.0}) {
    if (imageURL == null && filePath == null) {
      throw Exception('TrimmingImageArgsにイメージを渡す必要があります');
    }
  }

  //UI上の処理だけなので、動作を軽るするのに長辺をMAX_SIZEに縮小する
  static List<List<int>> bytesToImageBytes(Uint8List bytes) {
    const MAX_SIZE = 480;

    //Image package を使用

    //Imageインスタンスを作成
    image.Image baseSizeImage = image.decodeImage(bytes);

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

  //イメージをダウンロードするためにFutureBuilderで使用する
  Future<List<UI.Image>> getImageFutureBuilder() async {
    var completer = new Completer<List<UI.Image>>();
    if (_cachedImage != null) {
      completer.complete(_cachedImage);
    } else {
      if (imageURL != null) {
        try {
          final bundle =
              await NetworkAssetBundle(Uri.parse(imageURL)).load(imageURL);
          Uint8List bytes = bundle.buffer.asUint8List();
          //この関数は重くUIが止まってしまうので、非同期で実行
          List<List<int>> newBytes = await compute(bytesToImageBytes, bytes);
          _cachedImage = <UI.Image>[
            await decodeImageFromList(newBytes[0]),
            await decodeImageFromList(newBytes[1]),
            await decodeImageFromList(newBytes[2]),
            await decodeImageFromList(newBytes[3])
          ];
          debugPrint("イメージをダウンロードしました");
          completer.complete(_cachedImage);
        } catch (e) {
          completer.completeError(e);
        }
      } else if (filePath != null) {
        try {
          Uint8List bytes = await File(filePath).readAsBytes();
          //この関数は重くUIが止まってしまうので、非同期で実行
          List<List<int>> newBytes = await compute(bytesToImageBytes, bytes);
          _cachedImage = <UI.Image>[
            await decodeImageFromList(newBytes[0]),
            await decodeImageFromList(newBytes[1]),
            await decodeImageFromList(newBytes[2]),
            await decodeImageFromList(newBytes[3])
          ];
          debugPrint("イメージを読み込みました");
          completer.complete(_cachedImage);
        } catch (e) {
          completer.completeError(e);
        }
      } else {
        completer.completeError('TrimmingImageArgs()にパラメータが設定されていません');
      }
    }
    return completer.future;
  }
}

//このrouteがpopする場合に戻すパラメータ
class TrimmingResult {
  final String imageURL;
  final String filePath;
  final int rotation;
  final double trimLeft, trimTop, trimRight, trimBottom;
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

  //MyPainterクラスに渡す、描画パラメータを保持
  TrimmingPainter _paintArgs;

  //SnackBar表示用
  var _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => afterBuild(context));
  }

  //buildが完了したときに呼び出される
  void afterBuild(context) async {
    MyDialog.hintSnackBar(_scaffoldKey, '画像の高さ≒壁の高さが適当です');
  }

  @override
  Widget build(BuildContext context) {
    if (_paintArgs == null) {
      _paintArgs =
          TrimmingPainter(Theme.of(context).primaryColor, Colors.purpleAccent);
    }

    if (_arguments == null) {
      //前画面から渡されたパラメータを読み込む(initState()内ではエラーになる)
      _arguments = ModalRoute.of(context).settings.arguments;
      if (_arguments == null) {
        throw Exception('trimming_image_routeにTrimmingImageArgsクラスを渡してください');
      } else {
        _paintArgs.trimLeft = _arguments.initTrimLeft;
        _paintArgs.trimTop = _arguments.initTrimTop;
        _paintArgs.trimRight = _arguments.initTrimRight;
        _paintArgs.trimBottom = _arguments.initTrimBottom;
      }
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
              future: _arguments.getImageFutureBuilder(),
              builder: (BuildContext context, future) {
                if (future == null || (!future.hasData && !future.hasError))
                  return MyWidget.loading(context);
                if (future.hasError)
                  return MyWidget.error(context, future.error.toString());

                if (_paintArgs.images == null) {
                  //ダウンロードしたイメージを登録
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
                          constraints:
                              BoxConstraints.tightFor(height: 80.0), //ツールバーの高さ
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
        return new Future.value(false);
      }
    }
    return new Future.value(true);
  }

  //appBarのチェックボタン "✔" がタップされた
  void _trimmingCompleted() async {
    Navigator.of(context).pop(TrimmingResult(
        _arguments.imageURL, //元画像(ネットワークイメージの場合)
        _arguments.filePath, //元画像(ローカルファイルの場合)
        _paintArgs.rotation, //画像の回転角(0,90,180,270度) このほかに元画像がExifを持っていることがある
        _paintArgs.trimLeft, //トリミング結果 0.0～1.0
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
  final TrimmingPainter _paintArgs;

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
