import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pono_problem_app/routes/base_picture_view_route.dart';
import 'package:pono_problem_app/routes/edit_account.dart';
import 'package:pono_problem_app/routes/edit_holds_route.dart';
import 'package:pono_problem_app/routes/edit_problem_route.dart';
import 'package:pono_problem_app/routes/home_footer.dart';
import 'package:pono_problem_app/routes/manage_base_picture_route.dart';
import 'package:pono_problem_app/routes/manage_wall_route.dart';
import 'package:pono_problem_app/routes/select_base_picture_route.dart';
import 'package:pono_problem_app/routes/trimming_image_route.dart';
import 'package:provider/provider.dart';
import 'globals.dart';
import 'my_auth_notifier.dart';
import 'my_theme_notifier.dart';
import 'routes/login_route.dart';
import 'routes/home_route.dart';

void main() {
  //スマホの向きは縦方向固定
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp, //縦固定
  ]);

  //intlプラグインの日付設定を日本時間にする
  initializeDateFormatting('ja_JP', null).then((_) => runApp(MyApp()));
  //runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp() : super();

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    //テーマの変更を監視
    //このクラスは Provider.of<MyThemeNotifier>(context, listen:false) で取得可能
    return ChangeNotifierProvider(
        create: (_) => MyThemeNotifier(),
        child: Consumer<MyThemeNotifier>(
            builder: (context, MyThemeNotifier theme, _) {
          //認証の変更を監視
          //このクラスは Provider.of<MyAuthNotifier>(context, listen:false) で取得可能
          return ChangeNotifierProvider(
              create: (_) => MyAuthNotifier(),
              child: Consumer<MyAuthNotifier>(
                  builder: (context, MyAuthNotifier auth, _) {
                return buildMaterialApp(context, theme);
              }));
        }));
  }

  MaterialApp buildMaterialApp(BuildContext context, MyThemeNotifier theme) {
    return MaterialApp(
        theme: ThemeData.light(), // ライト用テーマ
        darkTheme: ThemeData.dark(), // ダーク用テーマ
        themeMode: theme.current, // theme.current, // MyThemeクラスから設定
        title: 'PONO課題プロトタイプ',

        //これにより Navigator に '/' がスタックされた状態でログイン画面が表示される
        //つまりログイン成功時に、ログイン画面から pop() でホーム画面に戻って来られる
        //initialRoute: '/login',
        initialRoute: '/',
        routes: {
          //'/login': (_) => Login(),
          '/': (_) => HomeFooter(),
          '/edit_account': (_) => EditAccount(),
          '/edit_problem/select_base_picture': (_) => SelectBasePicture(),
          '/edit_problem/edit_holds': (_) => EditHolds(),
          '/edit_problem/edit_problem': (_) => EditProblem(),
          '/edit_problem/trimming_image': (_) => TrimmingImage(),
          '/manage_base_picture': (_) => ManageBasePicture(),
          '/manage_base_picture/view': (_) => BasePictureView(),
          '/manage_wall': (_) => ManageWall(),
        });
  }
}
