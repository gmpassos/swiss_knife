
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

int getCurrentTimeMillis() {
  return new DateTime.now().millisecondsSinceEpoch ;
}

String dataSizeFormat(int size) {
  if (size < 1024) {
    return "$size bytes" ;
  }
  else if (size < 1024*1024) {
    var s = "${size / 1024} KB";
    var s2 = s.replaceFirstMapped(new RegExp("\\.(\\d\\d)\\d+"), (m) => ".${m[1]}");
    return s2 ;
  }
  else {
    var s = "${size / (1024*1024)} MB";
    var s2 = s.replaceFirstMapped(new RegExp("\\.(\\d\\d)\\d+"), (m) => ".${m[1]}");
    return s2 ;
  }
}

void _initializeDateFormatting() {
  var locale = Intl.defaultLocale;
  if (locale == null || locale.isEmpty) locale = 'en' ;
  initializeDateFormatting(locale, null);
}

String dateFormat_YYYY_MM_dd_HH_mm_ss([int time]) {
  if (time == null) time = getCurrentTimeMillis() ;

  _initializeDateFormatting();

  var date = new DateTime.fromMillisecondsSinceEpoch(time) ;
  var dateFormat = new DateFormat('yyyy-MM-dd HH:mm:ss');
  return dateFormat.format(date) ;
}

String dateFormat_YYYY_MM_dd([int time]) {
  if (time == null) time = getCurrentTimeMillis() ;

  _initializeDateFormatting();

  var date = new DateTime.fromMillisecondsSinceEpoch(time) ;
  var dateFormat = new DateFormat('yyyy-MM-dd');
  return dateFormat.format(date) ;
}

String getDateAmPm([int time]) {
  if (time == null) time = getCurrentTimeMillis() ;

  _initializeDateFormatting();

  var date = new DateTime.fromMillisecondsSinceEpoch(time) ;
  var dateFormat = new DateFormat('jm');
  var s = dateFormat.format(date) ;
  return s.contains("PM") ? 'PM' : 'AM';
}

int getDateHour([int time]) {
  if (time == null) time = getCurrentTimeMillis() ;

  _initializeDateFormatting();

  var date = new DateTime.fromMillisecondsSinceEpoch(time) ;
  var dateFormat = new DateFormat('HH');
  var s = dateFormat.format(date) ;
  return int.parse(s);
}
