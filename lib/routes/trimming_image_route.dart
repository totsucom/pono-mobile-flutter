import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as UI;
import 'package:image_picker/image_picker.dart';
import 'package:pono_problem_app/general/primitive_ui.dart';
import 'package:pono_problem_app/general/problem_painter.dart';
import 'package:pono_problem_app/general/trimming_painter.dart';
import 'package:pono_problem_app/records/primitive.dart';
import 'package:pono_problem_app/records/problem.dart';
import 'package:pono_problem_app/storage/problem_completed_image_storage.dart';
import 'package:pono_problem_app/utils/menu_item.dart';
import 'package:pono_problem_app/utils/my_dialog.dart';
import 'package:pono_problem_app/utils/my_widget.dart';
import 'package:pono_problem_app/utils/offset_ex.dart';

//MyPainterクラスからウィジェットの大きさを取得するために使用する
GlobalKey _toolBarGlobalKey = GlobalKey();

//このrouteにpushする場合に渡すパラメータ
class TrimmingImageArgs {
  final title;
  final double initTrimLeft, initTrimTop, initTrimRight, initTrimBottom;
  String _imageURL;
  PickedFile _pickedImage;
  UI.Image _cachedImage; //描画毎に無限ダウンロードしてしまうので、キャッシュは必須

  //コンストラクタにはいずれかのパラメータを渡す
  TrimmingImageArgs(
      {imageURL,
      pickedBasePicture,
      this.title = 'トリミング',
      this.initTrimLeft = 0.0,
      this.initTrimTop = 0.0,
      this.initTrimRight = 0.0,
      this.initTrimBottom = 0.0}) {
    this._imageURL = imageURL;
    this._pickedImage = pickedBasePicture;
    if (imageURL == null && pickedBasePicture == null) {
      throw Exception('trimming_image_routeにイメージを渡す必要があります');
    }
  }

  //イメージをダウンロードするためにFutureBuilderで使用する
  Future<UI.Image> getImageFutureBuilder() async {
    var completer = new Completer<UI.Image>();
    if (_cachedImage != null) {
      completer.complete(_cachedImage);
    } else {
      if (_imageURL != null) {
        try {
          final bundle =
              await NetworkAssetBundle(Uri.parse(_imageURL)).load(_imageURL);
          Uint8List bytes = bundle.buffer.asUint8List();
          _cachedImage = await decodeImageFromList(bytes);
          debugPrint("イメージをダウンロードしました");
          completer.complete(_cachedImage);
        } catch (e) {
          completer.completeError(e);
        }
      } else if (_pickedImage != null) {
        try {
          Uint8List bytes = await _pickedImage.readAsBytes();
          _cachedImage = await decodeImageFromList(bytes);
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

class TrimmingImage extends StatefulWidget {
  TrimmingImage({Key key}) : super(key: key);

  @override
  _TrimmingImageState createState() => _TrimmingImageState();
}

class _TrimmingImageState extends State<TrimmingImage> {
  //前画面から渡されたパラメータを保持
  TrimmingImageArgs _arguments;

  //onTap処理のため、onPanDown時の座標を記憶
  Offset _panDowmPosition;

  //MyPainterクラスに渡す、描画パラメータを保持
  TrimmingPainter _paintArgs;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_paintArgs == null) {
      _paintArgs = TrimmingPainter(
          Theme.of(context).bottomAppBarColor, Theme.of(context).primaryColor);
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
          appBar: AppBar(
            title: Text(_arguments.title),
            centerTitle: true,
            actions: [
              FlatButton(
                child: Icon(Icons.check,
                    color: Theme.of(context).primaryColorLight),
                onPressed: _moveToProblemEdit,
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

                if (_paintArgs.image == null) {
                  //ダウンロードしたイメージを登録
                  _paintArgs.image = future.data;
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
                      //debugPrint("onTap");
                      _selectEdge(_panDowmPosition);
                    },
                    onPanDown: (details) {
                      //debugPrint("onPanDown");
                      _panDowmPosition = details.localPosition;
                    },
                    onPanCancel: () {
                      debugPrint("onPanCancel");
                    },
                    onPanStart: (detail) {
                      debugPrint("onPanStart");
                    },
                    onPanUpdate: (details) {
                      //debugPrint("onPanUpdate");
                      _moveEdge(details.delta.dx, details.delta.dy);
                    },
                    onPanEnd: (detail) {
                      debugPrint("onPanEnd");
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
  void _moveToProblemEdit() async {
    //TODO どういう出力形式が必要だろうか?
  }

  //タップされたときのエッジ選択処理
  void _selectEdge(Offset touchPos) {
    if (!_paintArgs.isReady || _paintArgs.canvasSize.width <= 0)
      return; //準備ができてない

    //<TODO> インプリメント
  }

  //ドラッグによりベース写真を移動する
  void _moveEdge(double delta_x, double delta_y) {
    if (!_paintArgs.isReady || _paintArgs.canvasSize.width <= 0)
      return; //準備ができてない

    //<TODO> インプリメント
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
              icon: Icon(Icons.rotate_left),
              onPressed: () {
                //<TODO> インプリメント
              },
            ),
            Expanded(child: Text('左に回転', style: TextStyle(fontSize: 12.0)))
          ]),
      Column(
          //右回転ポップアップメニュー
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.rotate_right),
              onPressed: () {
                //<TODO> インプリメント
              },
            ),
            Expanded(child: Text('右に回転', style: TextStyle(fontSize: 12.0)))
          ]),
    ];
  }
}

class MyTrimmingPainter extends CustomPainter {
  final TrimmingPainter _paintArgs;

  MyTrimmingPainter(this._paintArgs);

  @override
  bool shouldRepaint(MyTrimmingPainter oldDelegate) {
    return true; //_paintArgs.isUpdatedAndReset;
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

    //画面上部のツールバーと画面下部のスライダーの背景を半透明で塗りつぶして
    //UIが見えるようにする
    final paint = Paint();
    paint.color = this._paintArgs.toolBarBackgroundColor;
    canvas.drawRect(
        Rect.fromLTWH(0, 0, canvasSize.width, toolBarSize.height), paint);
  }
}
