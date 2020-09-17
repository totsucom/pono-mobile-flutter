import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pono_problem_app/records/base_picture.dart';
import 'package:pono_problem_app/records/user.dart';
import 'package:pono_problem_app/records/wall.dart';
import 'package:pono_problem_app/routes/home_search.dart';
import 'package:pono_problem_app/utils/menu_item.dart';
import 'package:pono_problem_app/utils/my_widget.dart';
import 'package:provider/provider.dart';
import 'package:pono_problem_app/routes/edit_account.dart';

import '../authentication.dart';
import '../globals.dart';
import '../my_auth_notifier.dart';
import '../my_theme_notifier.dart';
import 'home_new.dart';

class _HomeAppBarPopupMenuItem {
  static const manageBasePicture = BasePicture.baseName + 'の管理';
  static const manageWall = Wall.baseName + 'の管理';
}

class HomeFooter extends StatefulWidget {
  //他のルートから戻ってきたときに、表示するスナックバー
  //該当ルートがpop（）またはpopUntil()を使用する場合に設定する
  static Widget snackBarWidgetFromOutside;

  const HomeFooter();

  @override
  _HomeFooter createState() => _HomeFooter();
}

class _HomeFooter extends State<HomeFooter> {
  int _selectedIndex = 0;
  final _bottomNavigationBarItems = <BottomNavigationBarItem>[];

  //ドロワーやスナックバーで使うキー
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  AuthMethod _currentAuthMethod = AuthMethod.None;

  final _authAppBarTitle = 'PONO課題アプリ';

  //appBarのポップアップメニュー
  List<MenuItem<String>> _appBarPopupMenuItems = [
    MenuItem<String>(_HomeAppBarPopupMenuItem.manageBasePicture,
        title: _HomeAppBarPopupMenuItem.manageBasePicture,
        icon: Icon(Icons.image)),
    MenuItem<String>(_HomeAppBarPopupMenuItem.manageWall,
        title: _HomeAppBarPopupMenuItem.manageWall,
        icon: Icon(Icons.wallpaper)),
  ];

  // アイコン情報
  static const _footerIcons = [
    Icons.fiber_new,
    Icons.find_in_page,
    Icons.edit,
  ];

  // アイコン文字列
  static const _footerItemNames = [
    '最新',
    '検索',
    'マイ課題',
  ];

  var _routes = [HomeNew(), HomeSearch()];

  @override
  void initState() {
    super.initState();
    _bottomNavigationBarItems.add(_UpdateActiveState(0));
    for (var i = 1; i < _footerItemNames.length; i++) {
      _bottomNavigationBarItems.add(_UpdateDeactiveState(i));
    }
  }

  /// インデックスのアイテムをアクティベートする
  BottomNavigationBarItem _UpdateActiveState(int index) {
    return BottomNavigationBarItem(
        icon: Icon(
          _footerIcons[index],
          color: Colors.black87,
        ),
        title: Text(
          _footerItemNames[index],
          style: TextStyle(
            color: Colors.black87,
          ),
        ));
  }

  /// インデックスのアイテムをディアクティベートする
  BottomNavigationBarItem _UpdateDeactiveState(int index) {
    return BottomNavigationBarItem(
        icon: Icon(
          _footerIcons[index],
          color: Colors.black26,
        ),
        title: Text(
          _footerItemNames[index],
          style: TextStyle(
            color: Colors.black26,
          ),
        ));
  }

  void _onItemTapped(int index) {
    setState(() {
      _bottomNavigationBarItems[_selectedIndex] =
          _UpdateDeactiveState(_selectedIndex);
      _bottomNavigationBarItems[index] = _UpdateActiveState(index);
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("home_footerのbuild()");

    final auth = Provider.of<MyAuthNotifier>(context, listen: false);
    auth.resetReason();
    if (auth.firebaseUser == null) {
      return _buildTestAuth(context);
    } else if (auth.currentUser == null) {
      return _buildNewUserView(context, auth.firebaseUser);
    }
    return _buildMainScaffold(context, auth);
  }

  // 認証ができなかったときに他の認証の選択肢を表示する
  Widget _buildTestAuth(BuildContext context) {
    String msg;
    switch (_currentAuthMethod) {
      case AuthMethod.None:
        msg = 'プラットフォーム認証に失敗しました。';
        break;
      case AuthMethod.Google:
        msg = 'Google認証に失敗しました。';
        break;
    }
    msg += '認証方法を選択してください。';

    return Scaffold(
      appBar: AppBar(
        title: Text(_authAppBarTitle),
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Text(msg),
          RaisedButton(
            child: Text('Google認証'),
            onPressed: () {
              _currentAuthMethod = AuthMethod.Google;
              Authentication.handleGoogleAuth(false, true).then((fbUser) {
                // Google認証が成功したので方法を記憶
                Globals.authMethod = AuthMethod.Google;
                Globals.saveSettings();
              });
            },
          )
        ],
      ),
    );
  }

  Widget _buildNewUserView(BuildContext context, FirebaseUser fbUser) {
    // 本来はアカウント選択用のウイジェットを表示するが、現状は選択肢が無いため
    // アカウント作成ページにジャンプする。

    // ビルド中にジャンプできないので別タスクから
    Future.delayed(Duration.zero).then((_) async {
      final args = EditAccountArgs.forNew(//_scaffoldKey,
          UserDocument(fbUser.uid, User.fromFirebaseUser(fbUser)));

      //アカウント作成画面に移動
      await Navigator.of(context).pushNamed('/edit_account', arguments: args);
      setState(() {});
    });
    //すぐに移動するのでほとんど表示されない
    return Scaffold(
        appBar: AppBar(
          title: Text(_authAppBarTitle),
          centerTitle: true,
        ),
        body: Text('アカウントを作成します...'));
  }

  Widget _buildMainScaffold(BuildContext context, MyAuthNotifier auth) {
    //} User user) {
    //スナックバーが待機中であれば表示する
    if (HomeFooter.snackBarWidgetFromOutside != null) {
      Future.delayed(Duration(milliseconds: 100)).then((_) {
        if (_scaffoldKey.currentState != null) {
          _scaffoldKey.currentState
              .showSnackBar(HomeFooter.snackBarWidgetFromOutside);
          HomeFooter.snackBarWidgetFromOutside = null;
        }
      });
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: GestureDetector(
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(_footerIcons[_selectedIndex]),
          ),
          onTap: () {
            _scaffoldKey.currentState.openDrawer();
          },
        ),
        title: Text(_footerItemNames[_selectedIndex]),
        centerTitle: true,
        actions: <Widget>[
          if (auth.isCurrentUserAdmin)
            PopupMenuButton<String>(
                icon: Icon(
                  Icons.vpn_key,
                  color: Colors.yellow,
                ),
                onSelected: _handlePopupMenuSelected,
                itemBuilder: (BuildContext context) => _appBarPopupMenuItems
                    .map((e) => e.toPopupMenuItem())
                    .toList()),
        ],
      ),
      drawer: _buildDrawer(context, auth),
      body: _routes.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // これを書かないと3つまでしか表示されない
        items: _bottomNavigationBarItems,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          await Navigator.of(context)
              .pushNamed('/edit_problem/select_base_picture');
          setState(() {});
        },
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, MyAuthNotifier auth) {
    return Drawer(
      child: ListView(
        children: <Widget>[
          DrawerHeader(
            child: Row(children: <Widget>[
              Container(
                  width: 100,
                  height: 100,
                  child: MyWidget.getCircleAvatar(auth.currentUser.iconURL)),
              Expanded(
                  child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                    auth.currentUser.displayName +
                        (auth.isCurrentUserAdmin ? '\n（管理者）' : ''),
                    style: TextStyle(color: Colors.white)),
              ))
            ]),
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
          ),
          ListTile(
            title: Text('ダークテーマを使用する'),
            trailing: Switch(
                value: Globals.darkTheme,
                onChanged: (value) {
                  setState(() {
                    Globals.darkTheme = value;
                  });
                  //テーマを反映
                  Provider.of<MyThemeNotifier>(context, listen: false)
                      .setDark(Globals.darkTheme);
                }),
          ),
          ListTile(
            title: Text('ユーザーアカウント'),
            onTap: () {
              _handleEditAccount(auth);
            },
          ),
        ],
      ),
    );
  }

  //管理者メニューが選択された
  void _handlePopupMenuSelected(String value) async {
    switch (value) {
      case _HomeAppBarPopupMenuItem.manageBasePicture:
        await Navigator.of(context).pushNamed('/manage_base_picture');
        setState(() {});
        break;
      case _HomeAppBarPopupMenuItem.manageWall:
        await Navigator.of(context).pushNamed('/manage_wall');
        setState(() {});
    }
  }

  //アカウントの編集
  void _handleEditAccount(MyAuthNotifier auth) async {
    final args = EditAccountArgs.forEdit(auth.currentUserDocument);

    //アカウント作成画面に移動
    await Navigator.of(context).pushNamed('/edit_account', arguments: args);
    setState(() {});
  }
}
