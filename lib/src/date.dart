
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:swiss_knife/src/math.dart';

import 'collections.dart';

int getCurrentTimeMillis() {
  return DateTime.now().millisecondsSinceEpoch ;
}

void _initializeDateFormatting() {
  var locale = Intl.defaultLocale;
  if (locale == null || locale.isEmpty) locale = 'en' ;
  initializeDateFormatting(locale, null);
}

String dateFormat_YYYY_MM_dd_HH_mm_ss([int time]) {
  time ??= getCurrentTimeMillis();

  _initializeDateFormatting();

  var date = DateTime.fromMillisecondsSinceEpoch(time) ;
  var dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  return dateFormat.format(date) ;
}

String dateFormat_YYYY_MM_dd([int time]) {
  time ??= getCurrentTimeMillis();

  _initializeDateFormatting();

  var date = DateTime.fromMillisecondsSinceEpoch(time) ;
  var dateFormat = DateFormat('yyyy-MM-dd');
  return dateFormat.format(date) ;
}

DateTime parseDateTime(dynamic v, [DateTime def]) {
  if (v == null) return def ;

  String s ;
  if (v is String) {
    s = v ;
  }
  else {
    s = v.toString() ;
  }

  s = s.trim() ;

  if (s.isEmpty) return def ;

  return DateTime.parse(s) ;
}

List<DateTime> parseDateTimeFromInlineList(dynamic s, [Pattern delimiter = ',', List<DateTime> def]) {
  if (s == null) return def ;
  if (s is DateTime) return [s];
  if (s is List) return s.map( (e) => parseDateTime(e) ).toList() ;
  return parseFromInlineList( s.toString() , delimiter , parseDateTime , def) ;
}

String getDateAmPm([int time]) {
  time ??= getCurrentTimeMillis();

  _initializeDateFormatting();

  var date = DateTime.fromMillisecondsSinceEpoch(time) ;
  var dateFormat = DateFormat('jm');
  var s = dateFormat.format(date) ;
  return s.contains('PM') ? 'PM' : 'AM';
}

int getDateHour([int time]) {
  time ??= getCurrentTimeMillis();

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

    var min = t.toInt() ;
    var sec = ((t-min) * 60).toInt() ;

    return sec > 0 ? '$sig${min} min ${sec} s' : ( '$sig${min} min' ) ;
  }
  else if ( time < ONE_DAY ) {
    var t = time/ONE_HOUR ;

    var hour = t.toInt() ;
    var min = ((t-hour) * 60).toInt() ;

    return min > 0 ? '$sig${hour} h ${min} min' : '$sig${hour} h' ;
  }
  else {
    var t = time/ONE_DAY ;

    var day = t.toInt() ;
    var hour = ((t-day) * 24).toInt() ;

    return hour > 0 ? '$sig${day} d ${hour} h' : '$sig${day} d' ;
  }
}

enum DateTimeWeekDay {
  Monday,
  Tuesday,
  Wednesday,
  Thursday,
  Friday,
  Saturday,
  Sunday
}

int getDateTimeWeekDayIndex( DateTimeWeekDay weekDay ) {
  if (weekDay == null) return null ;

  switch(weekDay) {
    case DateTimeWeekDay.Monday: return 1 ;
    case DateTimeWeekDay.Tuesday: return 2 ;
    case DateTimeWeekDay.Wednesday: return 3 ;
    case DateTimeWeekDay.Thursday: return 4 ;
    case DateTimeWeekDay.Friday: return 5 ;
    case DateTimeWeekDay.Saturday: return 6 ;
    case DateTimeWeekDay.Sunday: return 7 ;
    default: return null ;
  }
}

DateTimeWeekDay getDateTimeWeekDay( int weekDayIndex ) {
  if (weekDayIndex == null) return null ;

  switch (weekDayIndex) {
    case 1: return DateTimeWeekDay.Monday ;
    case 2: return DateTimeWeekDay.Tuesday ;
    case 3: return DateTimeWeekDay.Wednesday ;
    case 4: return DateTimeWeekDay.Thursday ;
    case 5: return DateTimeWeekDay.Friday ;
    case 6: return DateTimeWeekDay.Saturday ;
    case 7: return DateTimeWeekDay.Sunday ;
    default: throw ArgumentError('Invalid DateTime weekDay index. Should be of range 1-7, where Monday is 1 and Sunday is 7 (Monday-to-Sunday week).');
  }
}

DateTimeWeekDay getDateTimeWeekDay_from_ISO_8601_index( int weekDayIndex ) {
  if (weekDayIndex == null) return null ;

  switch (weekDayIndex) {
    case 0: return DateTimeWeekDay.Monday ;
    case 1: return DateTimeWeekDay.Tuesday ;
    case 2: return DateTimeWeekDay.Wednesday ;
    case 3: return DateTimeWeekDay.Thursday ;
    case 4: return DateTimeWeekDay.Friday ;
    case 5: return DateTimeWeekDay.Saturday ;
    case 6: return DateTimeWeekDay.Sunday ;
    default: throw ArgumentError('Invalid ISO 8601 weekDay index. Should be of range 0-6, where Monday is 0 and Sunday is 6 (Monday-to-Sunday week).');
  }
}

DateTime getDateTimeNow() {
  return DateTime.now() ;
}

DateTime getDateTimeDayStart( [DateTime now] ) {
  now ??= DateTime.now() ;
  return DateTime( now.year , now.month , now.day , 0,0,0 , 0,0 ) ;
}

DateTime getDateTimeDayEnd( [DateTime now] ) {
  now ??= DateTime.now() ;
  return DateTime( now.year , now.month , now.day , 23,59,59 , 999, 0 ) ;
}

DateTime getDateTimeYesterday( [DateTime now] ) {
  now ??= DateTime.now() ;
  return getDateTimeDayStart( now.subtract( Duration(days: 1) ) ) ;
}

Pair<DateTime> getDateTimeLastNDays( int nDays, [DateTime now] ) {
  now ??= DateTime.now() ;
  return Pair(
      getDateTimeDayStart( now.subtract( Duration(days: nDays) ) ) ,
      getDateTimeDayEnd( now )
  );
}

Pair<DateTime> getDateTimeThisWeek( [DateTimeWeekDay weekFirstDay, DateTime now] ) {
  now ??= DateTime.now() ;

  var weekStart = getDateTimeWeekStart(weekFirstDay, now) ;
  var weekEnd = getDateTimeWeekEnd(weekFirstDay, now) ;

  return Pair(
      getDateTimeDayStart( weekStart ) ,
      getDateTimeDayEnd( weekEnd )
  ) ;
}

Pair<DateTime> getDateTimeLastWeek( [DateTimeWeekDay weekFirstDay, DateTime now] ) {
  now ??= DateTime.now() ;

  var weekStart = getDateTimeWeekStart(weekFirstDay, now).subtract(Duration(days: 7)) ;
  var weekEnd = getDateTimeWeekEnd(weekFirstDay, weekStart) ;

  return Pair(
      getDateTimeDayStart( weekStart ) ,
      getDateTimeDayEnd( weekEnd )
  ) ;
}

Pair<DateTime> getDateTimeThisMonth( [DateTime now] ) {
  now ??= DateTime.now() ;

  var y = now.year ;
  var m = now.month ;
  return Pair(
      getDateTimeDayStart( DateTime( y , m , 1 , 0 , 0 ,0 , 0,0) ) ,
      getDateTimeDayEnd( DateTime( y , m , getLastDayOfMonth(m, year: y) , 23 , 59 , 59 , 0,0 ) )
  ) ;
}

Pair<DateTime> getDateTimeLastMonth( [DateTime now] ) {
  now ??= DateTime.now() ;

  var prevMonth = getDateTimePreviousMonth(now.month , year: now.year) ;

  var y = prevMonth.year ;
  var m = prevMonth.month ;

  return Pair(
      getDateTimeDayStart( DateTime( y , m , 1 , 0 , 0 ,0 , 0 , 0) ) ,
      getDateTimeDayEnd( DateTime( y , m, getLastDayOfMonth(m, year: y) , 23 , 59 , 59 , 9 , 0) )
  ) ;
}

DateTime getDateTimePreviousMonth(int month, { int year } ) {
  year ??= DateTime.now().year ;
  var cursor = DateTime( year , month , 1 , 0 , 0 , 0 , 0,0 ) ;
  var prev = cursor.subtract( Duration(days: 1) ) ;
  return prev ;
}

int getLastDayOfMonth(int month, {  int year }) {
  year ??= DateTime.now().year ;

  var cursor = DateTime( year , month , 28 , 12 , 0 , 0 ) ;

  while (true) {
    var next = cursor.add( Duration(days: 1) ) ;
    if ( next.month != cursor.month ) {
      return cursor.day ;
    }
    cursor = next ;
  }
}

DateTime getDateTimeWeekStart( [DateTimeWeekDay weekFirstDay , DateTime now] ) {
  weekFirstDay ??= DateTimeWeekDay.Monday ;
  now ??= DateTime.now() ;

  var weekFirstDayIndex = getDateTimeWeekDayIndex(weekFirstDay) ;

  while ( now.weekday != weekFirstDayIndex ) {
    now = now.subtract( Duration(days: 1) ) ;
  }

  return getDateTimeDayStart( now ) ;
}

DateTime getDateTimeWeekEnd( [DateTimeWeekDay weekFirstDay , DateTime now] ) {
  weekFirstDay ??= DateTimeWeekDay.Monday ;
  now ??= DateTime.now() ;

  var weekStart = getDateTimeWeekStart(weekFirstDay, now) ;

  var weekEnd = weekStart.add(Duration(days: 6)).add(Duration(hours: 12)) ;

  return getDateTimeDayEnd(weekEnd) ;
}

enum DateRangeType {
  TODAY,
  YESTERDAY,
  LAST_7_DAYS,
  THIS_WEEK,
  LAST_WEEK,
  LAST_30_DAYS,
  LAST_60_DAYS,
  LAST_90_DAYS,
  LAST_MONTH,
  THIS_MONTH,
}

Pair<DateTime> getDateTimeRange( DateRangeType rangeType , [DateTime now, DateTimeWeekDay weekFirstDay] ) {
  now ??= getDateTimeNow() ;

  var nowStart = getDateTimeDayStart(now) ;
  var nowEnd = getDateTimeDayEnd(now) ;

  switch(rangeType) {
    case DateRangeType.TODAY: return Pair( nowStart, nowEnd ) ;
    case DateRangeType.YESTERDAY: {
      var timeYesterday = getDateTimeYesterday(now);
      return Pair( timeYesterday , getDateTimeDayEnd(timeYesterday) ) ;
    }

    case DateRangeType.LAST_7_DAYS: return getDateTimeLastNDays(6, nowEnd) ;
    case DateRangeType.THIS_WEEK: return getDateTimeThisWeek(weekFirstDay, nowStart) ;
    case DateRangeType.LAST_WEEK: return getDateTimeLastWeek(weekFirstDay, nowStart) ;

    case DateRangeType.LAST_30_DAYS: return getDateTimeLastNDays(29, now) ;
    case DateRangeType.LAST_60_DAYS: return getDateTimeLastNDays(59, now) ;
    case DateRangeType.LAST_90_DAYS: return getDateTimeLastNDays(89, now) ;
    case DateRangeType.LAST_MONTH: return getDateTimeLastMonth(now) ;
    case DateRangeType.THIS_MONTH: return getDateTimeThisMonth(now) ;
    default: throw UnsupportedError("Can't handle: $rangeType") ;
  }

}

