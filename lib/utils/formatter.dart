import 'package:intl/intl.dart';

class Formatter {
  static String toYMD(DateTime date) {
    if (date == null) return '';
    return DateFormat('yyyy/MM/dd').format(date);
  }

  static String toYMD_HM(DateTime date) {
    if (date == null) return '';
    return DateFormat('yyyy/MM/dd HH:mm').format(date);
  }

  static String toEnnui(DateTime date) {
    if (date == null) return '';

    final now = DateTime.now();
    final diff = now.difference(date);

    final diffMinutes = diff.inMinutes;
    if (diffMinutes == 0) return 'たった今';
    if (diffMinutes <= 10) return '$diffMinutes分前';
    if (diffMinutes <= 60) return '1時間以内';

    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final diff2 = today.difference(day);
    final diffDays = diff2.inDays;

    if (diffDays == 0) {
      final diffHours = diff.inHours;
      if (diffHours <= 12) return '$diffHours時間前';
      if (diffHours <= 24) return '24時間以内';
    }
    if (diffDays == 1) return '昨日';
    if (diffDays == 2) return 'おととい';

    final lastSunday = today.subtract(new Duration(days: now.weekday));
    if (day.difference(lastSunday).inDays > 0) return '今週';

    final last2Sunday = lastSunday.subtract(new Duration(days: 7));
    if (day.difference(last2Sunday).inDays > 0) return '先週';

    final last3Sunday = lastSunday.subtract(new Duration(days: 14));
    if (day.difference(last3Sunday).inDays > 0) return '先々週';

    final thisMonth1st = DateTime(now.year, now.month, 1);
    if (day.difference(thisMonth1st).inDays >= 0) return '今月';

    final lastMonth1st = DateTime((now.month > 1) ? now.year : now.year - 1,
        (now.month > 1) ? now.month - 1 : 12, 1);
    if (day.difference(lastMonth1st).inDays >= 0) return '先月';

    final last2Month1st = DateTime(
        (lastMonth1st.month > 1) ? lastMonth1st.year : lastMonth1st.year - 1,
        (lastMonth1st.month > 1) ? lastMonth1st.month - 1 : 12,
        1);
    if (day.difference(last2Month1st).inDays >= 0) return '先々月';

    final yrs = today.year - day.year;
    if (yrs == 0) return '今年';
    if (yrs == 1) return '昨年';
    return '$yrs年前';
  }
}
