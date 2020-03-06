
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:swiss_knife/src/math.dart';

int getCurrentTimeMillis() {
  return DateTime.now().millisecondsSinceEpoch ;
}

void _initializeDateFormatting() {
  var locale = Intl.defaultLocale;
  if (locale == null || locale.isEmpty) locale = 'en' ;
  initializeDateFormatting(locale, null);
}

String dateFormat_YYYY_MM_dd_HH_mm_ss([int time]) {
  if (time == null) time = getCurrentTimeMillis() ;

  _initializeDateFormatting();

  var date = DateTime.fromMillisecondsSinceEpoch(time) ;
  var dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  return dateFormat.format(date) ;
}

String dateFormat_YYYY_MM_dd([int time]) {
  if (time == null) time = getCurrentTimeMillis() ;

  _initializeDateFormatting();

  var date = DateTime.fromMillisecondsSinceEpoch(time) ;
  var dateFormat = DateFormat('yyyy-MM-dd');
  return dateFormat.format(date) ;
}

String getDateAmPm([int time]) {
  if (time == null) time = getCurrentTimeMillis() ;

  _initializeDateFormatting();

  var date = DateTime.fromMillisecondsSinceEpoch(time) ;
  var dateFormat = DateFormat('jm');
  var s = dateFormat.format(date) ;
  return s.contains("PM") ? 'PM' : 'AM';
}

int getDateHour([int time]) {
  if (time == null) time = getCurrentTimeMillis() ;

  _initializeDateFormatting();

  var date = DateTime.fromMillisecondsSinceEpoch(time) ;
  var dateFormat = DateFormat('HH');
  var s = dateFormat.format(date) ;
  return int.parse(s);
}

const int ONE_SECOND = 1000 ;
const int ONE_MINUTE = ONE_SECOND*60 ;
const int ONE_HOUR = ONE_MINUTE*60 ;
const int ONE_DAY = ONE_HOUR*24 ;

String formatTimeMillis(int time) {
  if (time == null || time == 0) return '0' ;

  var sig = '';

  if (time < 0) {
    sig = '-' ;
    time = -time ;
  }

  if ( time < ONE_SECOND) {
    return '$sig$time ms' ;
  }
  else if ( time < ONE_MINUTE ) {
    var t = time/ONE_SECOND ;
    var f = formatDecimal(t) ;
    return '$sig$f sec' ;
  }
  else if ( time < ONE_HOUR ) {
    var t = time/ONE_MINUTE ;
    var f = formatDecimal(t) ;
    return '$sig$f min' ;
  }
  else if ( time < ONE_DAY ) {
    var t = time/ONE_HOUR ;
    var f = formatDecimal(t) ;
    return '$sig$f hr' ;
  }
  else {
    var t = time/ONE_DAY ;
    var f = formatDecimal(t) ;
    return t > 1 ? '$sig$f days' : '$sig$f day' ;
  }
}


