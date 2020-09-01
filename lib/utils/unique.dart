import 'package:uuid/uuid.dart';

class Unique {

  //拡張子だけ利用してユニークなファイル名を生成
  static String FileName(String path) {
    var i = path.lastIndexOf('.');
    if (i > 0) {
      //v1()はタイムベースのユニークID
      return Uuid().v1() + path.substring(i);
    } else {
      return Uuid().v1();
    }
  }
}