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
import 'package:pono_problem_app/records/primitive.dart';
import 'package:pono_problem_app/records/problem.dart';
import 'package:pono_problem_app/storage/problem_completed_image_storage.dart';
import 'package:pono_problem_app/utils/menu_item.dart';
import 'package:pono_problem_app/utils/my_dialog.dart';
import 'package:pono_problem_app/utils/my_widget.dart';
import 'package:pono_problem_app/utils/offset_ex.dart';

//MyPainterクラスからウィジェットの大きさを取得するために使用する
GlobalKey _toolBarGlobalKey = GlobalKey();
GlobalKey _sliderGlobalKey = GlobalKey();

//このrouteにpushする場合に渡すパラメータ
class EditHoldsArgs {
  String _basePictureURL;
  PickedFile _pickedBasePicture;
  UI.Image _cachedImage; //描画毎に無限ダウンロードしてしまうので、キャッシュは必須

  //コンストラクタにはいずれかのパラメータを渡す
  EditHoldsArgs({basePictureURL, pickedBasePicture}) {
    this._basePictureURL = basePictureURL;
    this._pickedBasePicture = pickedBasePicture;
    if (basePictureURL == null && pickedBasePicture == null) {
      throw Exception('edit_holds_routeにベース写真を渡す必要があります');
    }
  }

  //BasePictureをダウンロードするためにFutureBuilderで使用する
  Future<UI.Image> getBaseImageFutureBuilder() async {
    var completer = new Completer<UI.Image>();
    if (_cachedImage != null) {
      completer.complete(_cachedImage);
    } else {
      if (_basePictureURL != null) {
        try {
          final bundle = await NetworkAssetBundle(Uri.parse(_basePictureURL))
              .load(_basePictureURL);
          Uint8List bytes = bundle.buffer.asUint8List();
          _cachedImage = await decodeImageFromList(bytes);
          debugPrint("basePictureをダウンロードしました");
          completer.complete(_cachedImage);
        } catch (e) {
          completer.completeError(e);
        }
      } else if (_pickedBasePicture != null) {
        try {
          Uint8List bytes = await _pickedBasePicture.readAsBytes();
          _cachedImage = await decodeImageFromList(bytes);
          debugPrint("basePictureを読み込みました");
          completer.complete(_cachedImage);
        } catch (e) {
          completer.completeError(e);
        }
      } else {
        completer.completeError('EditHoldsArgs()にパラメータが設定されていません');
      }
    }
    return completer.future;
  }
}

class EditHolds extends StatefulWidget {
  EditHolds({Key key}) : super(key: key);

  @override
  _EditHoldsState createState() => _EditHoldsState();
}

class _EditHoldsState extends State<EditHolds> {
  //前画面から渡されたパラメータを保持
  EditHoldsArgs _arguments;

  //UIウィジェットの現在値を保持
  PrimitiveSizeType _sizeMenuSelectedValue = PrimitiveSizeType.M;
  Color _colorMenuSelectedValue = Colors.redAccent;

  //UIウィジェットのデフォルト値を保持
  PrimitiveSizeType _defaultPrimitiveSizeType = PrimitiveSizeType.M;
  Color _defaultPrimitiveColor = Colors.redAccent;

  //onTap処理のため、onPanDown時の座標を記憶
  Offset _panDowmPosition;

  //MyPainterクラスに渡す、描画パラメータを保持
  final _paintArgs = ProblemPainter();

  Timer _intervalTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => afterBuild(context));
  }

  //buildが完了したときに呼び出される
  void afterBuild(context) {
    //インターバルタイマーを開始する
    _intervalTimer = Timer.periodic(
      Duration(milliseconds: 800),
      (_) {
        //再描画を減らすため、プリミティブが未選択の場合は更新しない
        if (_paintArgs.selectedPrimitiveIndex < 0) return;
        setState(() {
          _paintArgs.patternIndex++;
        });
      },
    );
  }

  @override
  void dispose() {
    //インターバルタイマーを終了させる
    if (_intervalTimer != null) _intervalTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_arguments == null) {
      //前画面から渡されたパラメータを読み込む(initState()内ではエラーになる)
      _arguments = ModalRoute.of(context).settings.arguments;
      if (_arguments == null) {
        throw Exception('edit_holds_routeにEditHoldsArgsクラスを渡してください');
      }
    }

    return WillPopScope(
        //WillPopScopeで戻るボタンのタップをキャッチ
        onWillPop: _requestPop,
        child: Scaffold(
          appBar: AppBar(
            title: Text(Problem.baseName + 'の編集'),
            centerTitle: true,
            actions: [
              FlatButton(
                child: Icon(Icons.check,
                    color: Theme.of(context).primaryColorLight),
                onPressed: _moveToProblemEdit,
              ),
              /*Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Icon(Icons.check),
              ),*/
            ],
          ),
          body: FutureBuilder(
              //ベース写真のダウンロードを待つ
              future: _arguments.getBaseImageFutureBuilder(),
              builder: (BuildContext context, future) {
                if (future == null || (!future.hasData && !future.hasError))
                  return MyWidget.loading(context);
                if (future.hasError)
                  return MyWidget.error(context, future.error.toString());

                if (_paintArgs.baseImage == null) {
                  //ベース写真を登録
                  _paintArgs.baseImage = future.data;
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
                      _selectPrimitive(_panDowmPosition);
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
                      _moveBaseImage(details.delta.dx, details.delta.dy);
                    },
                    onPanEnd: (detail) {
                      debugPrint("onPanEnd");
                    },

                    // カスタムペイント
                    child: CustomPaint(
                      painter: MyHoldsPainter(_paintArgs),
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
                  Align(
                      //画面下部のスライダー
                      alignment: Alignment.bottomCenter,
                      child: Container(
                          key: _sliderGlobalKey,
                          padding: const EdgeInsets.only(top: 0, bottom: 0),
                          constraints:
                              BoxConstraints.tightFor(height: 64.0), //スライダーの高さ
                          child: Row(children: <Widget>[
                            Padding(
                                padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
                                child: Text('表示サイズ')),
                            Expanded(
                                child: Slider(
                              value: _paintArgs.displaySize,
                              min: ProblemPainter.DISPLAY_SIZE_MIN,
                              max: ProblemPainter.DISPLAY_SIZE_MAX,
                              divisions: 20,
                              onChanged: (double newValue) {
                                setState(() {
                                  //表示スケールを更新
                                  _paintArgs.displaySize = newValue;
                                });
                              },
                            ))
                          ])))
                ]);
              }),
        ));
  }

  //appBarの戻るボタン "←" がタップされた
  Future<bool> _requestPop() async {
    if (_paintArgs.primitives.length > 0) {
      final result = await MyDialog.selectYesNo(context,
          caption: Problem.baseName + 'の編集',
          labelText: '編集中の${Problem.baseName}が失われてしまいますが、それでも戻りますか？');
      if (result != MyDialogResult.Yes) {
        return new Future.value(false);
      }
    }
    return new Future.value(true);
  }

  //appBarのチェックボタン "✔" がタップされた
  void _moveToProblemEdit() async {
    //TODO Ｐｒｏｂｌｅｍクラスが無ければ生成、あればプリミティブ一覧を更新
  }

  //タップされたときのプリミティブ選択処理
  int _selectPrimitiveIndexEnnuiOffset = 0; //複数の選択候補があったときにタップ毎に選択対象を変更
  void _selectPrimitive(Offset touchPos) {
    if (!_paintArgs.isReady || _paintArgs.canvasSize.width <= 0)
      return; //準備ができてない

    //タップ位置を含むプリミティブのインデックスを検索
    final canvasCenter = Offset(
        _paintArgs.canvasSize.width / 2.0, _paintArgs.canvasSize.height / 2.0);
    final List<PrimitiveUI> selectablePrimitives = [];
    bool selectedPrimitiveIncluded = false;
    _paintArgs.primitives.forEach((prim) {
      final rect = prim.getBound(
          canvasCenter, _paintArgs.baseImagePosition, _paintArgs.actualScale);
      if (OffsetEx(touchPos).inRect(rect)) {
        if (prim.selected) {
          selectablePrimitives.insert(0, prim); //選択中のアイテムはインデックス0に挿入
          selectedPrimitiveIncluded = true;
        } else {
          selectablePrimitives.add(prim);
        }
      }
    });

    if (selectablePrimitives.length == 0) {
      //選択候補が無い
      _paintArgs.selectedPrimitiveIndex = -1;
      if (_paintArgs.isUpdated) {
        //選択解除
        setState(() {
          //UIのサイズと色をプリミティブ値からデフォルト値に戻す
          _sizeMenuSelectedValue = _defaultPrimitiveSizeType;
          _colorMenuSelectedValue = _defaultPrimitiveColor;
        });
      }
    } else if (selectablePrimitives.length == 1 && selectedPrimitiveIncluded) {
      //選択されたものが再タップされた
      //選択済みを再選択した場合はオプション(テキストや線の位置)を変更
      final prim = selectablePrimitives[0];
      if (prim.type != PrimitiveType.Kante) {
        //オプション値(subItemPosition)を次の値に変更
        prim.subItemPosition = (prim.subItemPosition ==
                PrimitiveSubItemPosition.values.last)
            ? PrimitiveSubItemPosition.values.first
            : PrimitiveSubItemPosition.values[prim.subItemPosition.index + 1];
      } else {
        //カンテの場合は選択できるオプションが制限される（上下は無し）
        final acceptable = [
          PrimitiveSubItemPosition.Center,
          PrimitiveSubItemPosition.Right,
          PrimitiveSubItemPosition.Left
        ];
        do {
          prim.subItemPosition = (prim.subItemPosition ==
                  PrimitiveSubItemPosition.values.last)
              ? PrimitiveSubItemPosition.values.first
              : PrimitiveSubItemPosition.values[prim.subItemPosition.index + 1];
        } while (!acceptable.contains(prim.subItemPosition));
      }
      setState(() {
        _paintArgs.setUpdate();
      });
    } else {
      //複数の選択候補から１つを選択

      //選択中の候補は外す
      if (selectedPrimitiveIncluded) selectablePrimitives.removeAt(0);

      //複数が重なっている場合に再タップで次の候補が選択されるようにインデックスを増やす
      _selectPrimitiveIndexEnnuiOffset++;
      final prim = selectablePrimitives[
          _selectPrimitiveIndexEnnuiOffset % selectablePrimitives.length];
      _paintArgs.selectedPrimitive = prim;
      setState(() {
        //UIのサイズと色にプリミティブ固有値を設定する
        _sizeMenuSelectedValue = prim.sizeType;
        _colorMenuSelectedValue = prim.color;
      });
    }
  }

  //ドラッグによりベース写真を移動する
  void _moveBaseImage(double delta_x, double delta_y) {
    if (!_paintArgs.isReady || _paintArgs.actualScale <= 0.0) return; //準備ができてない

    //新しいベース写真の表示位置を計算
    var x = _paintArgs.baseImagePosition.dx;
    x -= delta_x / _paintArgs.actualScale;
    if (x < 0.0) x = 0.0;
    if (x >= _paintArgs.baseImage.width) x = _paintArgs.baseImage.width - 1.0;

    var y = _paintArgs.baseImagePosition.dy;
    y -= delta_y / _paintArgs.actualScale;
    if (y < 0.0) y = 0.0;
    if (y >= _paintArgs.baseImage.height) y = _paintArgs.baseImage.height - 1.0;

    //差分を計算
    double dx = x - _paintArgs.baseImagePosition.dx;
    double dy = y - _paintArgs.baseImagePosition.dy;
    if (dx == 0.0 && dy == 0.0) return; //変化が無いので処理しない

    _paintArgs.baseImagePosition = Offset(x, y);
    final prim = _paintArgs.selectedPrimitive;
    if (prim != null) {
      //選択中のプリミティブは画面に対して動かさないので、
      //ベース写真の表示位置の変化に対して逆方向に位置を設定
      prim.position += Offset(dx, dy);
    }

    //再描画
    setState(() {});
  }

  //「ホールド」ポップアップメニュー
  List<MenuItem<PrimitiveType>> _holdPopupMenuItems = [
    MenuItem<PrimitiveType>(PrimitiveType.RegularHold,
        title: 'レギュラー', icon: Icon(Icons.image)),
    MenuItem<PrimitiveType>(PrimitiveType.StartHold,
        title: 'スタート', icon: Icon(Icons.image)),
    MenuItem<PrimitiveType>(PrimitiveType.StartHold_Hand,
        title: 'スタート手', icon: Icon(Icons.image)),
    MenuItem<PrimitiveType>(PrimitiveType.StartHold_Foot,
        title: 'スタート足', icon: Icon(Icons.image)),
    MenuItem<PrimitiveType>(PrimitiveType.StartHold_RightHand,
        title: 'スタート右手', icon: Icon(Icons.image)),
    MenuItem<PrimitiveType>(PrimitiveType.StartHold_LeftHand,
        title: 'スタート左手', icon: Icon(Icons.image)),
    MenuItem<PrimitiveType>(PrimitiveType.GoalHold,
        title: 'ゴール', icon: Icon(Icons.image)),
    MenuItem<PrimitiveType>(PrimitiveType.Bote,
        title: 'ボテあり', icon: Icon(Icons.image)),
    MenuItem<PrimitiveType>(PrimitiveType.Kante,
        title: 'カンテあり', icon: Icon(Icons.image)),
  ];

  //「サイズ」ドロップダウンメニュー
  List<MenuItem<PrimitiveSizeType>> _sizeDropDownMenuItems = [
    MenuItem<PrimitiveSizeType>(PrimitiveSizeType.XL, title: '最大'),
    MenuItem<PrimitiveSizeType>(PrimitiveSizeType.L, title: '大'),
    MenuItem<PrimitiveSizeType>(PrimitiveSizeType.M, title: '中'),
    MenuItem<PrimitiveSizeType>(PrimitiveSizeType.S, title: '小'),
    MenuItem<PrimitiveSizeType>(PrimitiveSizeType.XS, title: '最小'),
  ];

  //「色」ドロップダウンメニュー
  List<MenuItem<Color>> _colorDropDownMenuItems = [
    MenuItem<Color>(Colors.redAccent,
        icon: Icon(Icons.stop, color: Colors.redAccent)),
    MenuItem<Color>(Colors.greenAccent,
        icon: Icon(Icons.stop, color: Colors.greenAccent)),
    MenuItem<Color>(Colors.blueAccent,
        icon: Icon(Icons.stop, color: Colors.blueAccent)),
    MenuItem<Color>(Colors.yellowAccent,
        icon: Icon(Icons.stop, color: Colors.yellowAccent)),
    MenuItem<Color>(Colors.purpleAccent,
        icon: Icon(Icons.stop, color: Colors.purpleAccent)),
  ];

  //画面上部のツールバーを作成
  List<Widget> _generateToolBarItems() {
    return <Widget>[
      Column(
          //「ホールド」ポップアップメニュー
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            PopupMenuButton<PrimitiveType>(
              icon: Icon(Icons.panorama_fish_eye),
              itemBuilder: (BuildContext context) {
                return _holdPopupMenuItems
                    .map((e) => e.toPopupMenuItem())
                    .toList();
              },
              onSelected: _newPrimitive,
            ),
            Expanded(child: Text('ホールド', style: TextStyle(fontSize: 12.0)))
          ]),
      Column(
          //「サイズ」ドロップダウンメニュー
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            DropdownButton<PrimitiveSizeType>(
              icon: Icon(Icons.arrow_drop_down),
              value: _sizeMenuSelectedValue,
              //style: TextStyle(fontSize: 20, color: Colors.black),
              underline: Container(
                height: 2,
                color: Colors.grey,
              ),
              items: _sizeDropDownMenuItems
                  .map((e) => e.toDropdownMenuItem())
                  .toList(),
              onChanged: (PrimitiveSizeType newValue) {
                if (_paintArgs.isReady) {
                  if (_paintArgs.selectedPrimitiveIndex < 0) {
                    //未選択時はデフォルト値を変更
                    setState(() {
                      _defaultPrimitiveSizeType = newValue;
                      _sizeMenuSelectedValue = newValue;
                    });
                  } else {
                    //選択時はプリミティブのサイズを変更
                    setState(() {
                      _paintArgs.selectedPrimitive.sizeType = newValue;
                      _paintArgs.primitiveUpdated();
                      _sizeMenuSelectedValue = newValue;
                    });
                  }
                }
              },
            ),
            Expanded(child: Text('サイズ', style: TextStyle(fontSize: 12.0)))
          ]),
      Column(
          //「色」ドロップダウンメニュー
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            DropdownButton<Color>(
              icon: Icon(Icons.arrow_drop_down),
              value: _colorMenuSelectedValue,
              //style: TextStyle(fontSize: 20, color: Colors.black),
              underline: Container(
                height: 2,
                color: Colors.grey,
              ),
              items: _colorDropDownMenuItems
                  .map((e) => e.toDropdownMenuItem())
                  .toList(),
              onChanged: (Color newColor) {
                if (_paintArgs.isReady) {
                  if (_paintArgs.selectedPrimitiveIndex < 0) {
                    //未選択時はデフォルト値を変更
                    setState(() {
                      _defaultPrimitiveColor = newColor;
                      _colorMenuSelectedValue = newColor;
                    });
                  } else {
                    //選択時はプリミティブのサイズを変更
                    setState(() {
                      _paintArgs.selectedPrimitive.color = newColor;
                      _paintArgs.primitiveUpdated();
                      _colorMenuSelectedValue = newColor;
                    });
                  }
                }
              },
            ),
            Expanded(child: Text('色', style: TextStyle(fontSize: 12.0)))
          ]),
      Column(
          //「削除」アイコン
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            IconButton(
                icon: Icon(Icons.delete_outline),
                onPressed: _deleteSelectedPrimitive),
            Expanded(child: Text('削除', style: TextStyle(fontSize: 12.0)))
          ]),
    ];
  }

  //ドロップダウンメニューからプリミティブが選択された
  void _newPrimitive(PrimitiveType primitiveType) {
    //現在の設定からプリミティブを生成、追加
    final primitive = PrimitiveUI(primitiveType, _paintArgs.baseImagePosition,
        _sizeMenuSelectedValue, _colorMenuSelectedValue);
    setState(() {
      _paintArgs.addPrimitive(primitive, true);
    });
  }

  //選択中のプリミティブを削除する
  void _deleteSelectedPrimitive() {
    if (!_paintArgs.isReady || _paintArgs.selectedPrimitiveIndex < 0) return;

    _paintArgs.removePrimitive(_paintArgs.selectedPrimitive);

    //選択解除
    setState(() {
      //UIのサイズと色をプリミティブ値からデフォルト値に戻す
      _sizeMenuSelectedValue = _defaultPrimitiveSizeType;
      _colorMenuSelectedValue = _defaultPrimitiveColor;
    });
  }
}

class MyHoldsPainter extends CustomPainter {
  final ProblemPainter _paintArgs;

  MyHoldsPainter(this._paintArgs);

  @override
  bool shouldRepaint(MyHoldsPainter oldDelegate) {
    return _paintArgs.isUpdatedAndReset;
  }

  @override
  void paint(Canvas canvas, Size canvasSize) {
    if (_paintArgs == null) return;

    //画面上部のツールバーと画面下のスライダー領域を取得
    final toolBarSize =
        ((_toolBarGlobalKey.currentContext.findRenderObject()) as RenderBox)
            .size;
    final sliderSize =
        ((_sliderGlobalKey.currentContext.findRenderObject()) as RenderBox)
            .size;

    //画面上部のツールバーと画面下部のスライダーの背景をクリッピングする
    /*var rect = Rect.fromLTWH(0, toolBarSize.height, size.width,
        size.height - toolBarSize.height - sliderSize.height);
    canvas.clipRect(rect);*/

    //メインの描画
    _paintArgs.paint(canvas, canvasSize);

    //画面上部のツールバーと画面下部のスライダーの背景を半透明で塗りつぶして
    //UIが見えるようにする
    final paint = Paint();
    paint.color = Color.fromARGB(200, 255, 255, 255);
    canvas.drawRect(
        Rect.fromLTWH(0, 0, canvasSize.width, toolBarSize.height), paint);
    canvas.drawRect(
        Rect.fromLTWH(0, canvasSize.height - sliderSize.height,
            canvasSize.width, sliderSize.height),
        paint);
  }
}
