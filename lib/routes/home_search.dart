import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pono_problem_app/records/problem.dart';
import 'package:pono_problem_app/records/problem_datastore.dart';
import 'package:pono_problem_app/utils/formatter.dart';
import 'package:pono_problem_app/utils/menu_item.dart';
import 'package:pono_problem_app/utils/my_dialog.dart';
import 'package:pono_problem_app/utils/my_document_notifier.dart';
import 'package:pono_problem_app/utils/my_widget.dart';
import 'package:provider/provider.dart';

import '../my_auth_notifier.dart';

class HomeSearch extends StatefulWidget {
  const HomeSearch();

  @override
  _HomeSearchState createState() => _HomeSearchState();
}

class _HomeSearchState extends State<HomeSearch> {
  //グレードドロップダウンメニュー
  List<MenuItem<int>> _gradeDropDownMenuItems = [
    MenuItem<int>(7, title: '７級'),
    MenuItem<int>(6, title: '６級'),
    MenuItem<int>(5, title: '５級'),
    MenuItem<int>(4, title: '４級'),
    MenuItem<int>(3, title: '３級'),
    MenuItem<int>(2, title: '２級'),
    MenuItem<int>(1, title: '１級'),
    MenuItem<int>(-1, title: '初段'),
    MenuItem<int>(-2, title: '２段')
  ];

  int _graneMenuSelectedValue1 = 7;
  int _graneMenuSelectedValue2 = -2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => afterBuild(context));
  }

  //ホーム画面のbuildが完了したときに呼び出される
  void afterBuild(context) async {}

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
            height: 50,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text('グレード')),
                  DropdownButton<int>(
                    icon: Icon(Icons.arrow_drop_down),
                    value: _graneMenuSelectedValue1,
                    //style: TextStyle(fontSize: 20, color: Colors.black),
                    underline: Container(
                      height: 2,
                      color: Colors.grey,
                    ),
                    items: _gradeDropDownMenuItems
                        .map((e) => e.toDropdownMenuItem())
                        .toList(),
                    onChanged: (int newValue) {
                      _graneMenuSelectedValue1 = newValue;
                    },
                  ),
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text('～')),
                  DropdownButton<int>(
                    icon: Icon(Icons.arrow_drop_down),
                    value: _graneMenuSelectedValue2,
                    //style: TextStyle(fontSize: 20, color: Colors.black),
                    underline: Container(
                      height: 2,
                      color: Colors.grey,
                    ),
                    items: _gradeDropDownMenuItems
                        .map((e) => e.toDropdownMenuItem())
                        .toList(),
                    onChanged: (int newValue) {
                      _graneMenuSelectedValue2 = newValue;
                    },
                  ),
                ])),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: ProblemDatastore.getProblemStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return LinearProgressIndicator();
              return _buildGridView(context, snapshot.data.documents);
            },
          ),
        )
      ],
    );
  }

  Widget _buildGridView(BuildContext context, List<DocumentSnapshot> snapshot) {
    return GridView.extent(
      padding: const EdgeInsets.all(4.0),
      maxCrossAxisExtent: 200,
      crossAxisSpacing: 10.0, //縦
      mainAxisSpacing: 10.0, //横
      childAspectRatio: 0.8, //縦長
      shrinkWrap: true,
      children: snapshot
          .map((data) => _buildBasePictureGridItem(context, data))
          .toList(),
    );
  }

  Widget _buildBasePictureGridItem(
      BuildContext context, DocumentSnapshot snapshot) {
    final problemDoc = new ProblemDocument(
        snapshot.documentID, Problem.fromMap(snapshot.data));

    Widget thumbnailWidget;
    if (problemDoc.data.completedImageThumbURL.length == 0) {
      if (problemDoc.data.createdAt != null) {
        // ↑ 瞬間nullのパターンが発生するみたい
        final duration = DateTime.now().difference(problemDoc.data.createdAt);
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
      thumbnailWidget = (problemDoc.data.completedImageThumbURL.length == 0)
          ? Center(
              child: SizedBox(
                  width: 50,
                  height: 50,
                  child:
                      CircularProgressIndicator())) //CloudFunctions処理待ち(エラー表示回避)
          : CachedNetworkImage(
              imageUrl: problemDoc.data.completedImageThumbURL,
              placeholder: (context, url) => Center(
                  child: SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator())),
              errorWidget: (context, url, error) =>
                  Icon(Icons.error, color: Theme.of(context).errorColor));
    }
    return _buildGridItem(context, thumbnailWidget, problemDoc);
  }

  Widget _buildGridItem(
      BuildContext context, Widget thumbnail, ProblemDocument problemDoc) {
    final dateString = (problemDoc.data.publishedAt != null)
        ? ('公開 ' + Formatter.toEnnui(problemDoc.data.publishedAt))
        : ('作成 ' + Formatter.toEnnui(problemDoc.data.createdAt));
    final grade = problemDoc.data.grade;
    final gradeString =
        ((grade > 0) ? (grade.toString() + '級') : ((-grade).toString() + '段')) +
            problemDoc.data.gradeOption;
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
              flex: 8,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: thumbnail,
              )),
          Expanded(
            flex: 1,
            child: Text(problemDoc.data.title),
          ),
          Expanded(
              flex: 1,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Text(gradeString),
                    Text(dateString),
                    Container(
                        height: 20,
                        width: 20,
                        child: MyWidget.getCircleAvatarFromUserID(
                            problemDoc.data.uid))
                  ]))
        ]),
      ),
      /*)*/
      onTap: () {
        //_handleSelectedBasePicture(problemDoc);
      },
    );
  }
}
