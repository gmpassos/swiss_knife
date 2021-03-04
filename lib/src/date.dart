import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/date_symbols.dart';
import 'package:intl/intl.dart';
import 'package:swiss_knife/src/math.dart';

import 'collections.dart';

/// Returns the current time in milliseconds since epoch.
int getCurrentTimeMillis() {
  return DateTime.now().millisecondsSinceEpoch;
}

/// Returns [true] if [n] is in range of a Unix epoch time.
///
/// [inMilliseconds] If true check range in milliseconds. Default: [true].
bool isInUnixEpochRange(dynamic value, [bool inMilliseconds]) {
  if (!isInt(value)) return false;
  var n = parseInt(value);

  inMilliseconds ??= true;

  if (inMilliseconds) {
    return n > 946692000000 && n < 32503690800000;
  } else {
    return n > 946692000 && n < 32503690800;
  }
}

void _initializeDateFormatting() {
  var locale = Intl.defaultLocale;
  if (locale == null || locale.isEmpty) locale = 'en';
  initializeDateFormatting(locale, null);
}

String dateFormat_YYYY_MM_dd_HH_mm_ss(
    [int time, String delimiter = '-', String hourDelimiter = ':']) {
  delimiter ??= '-';
  hourDelimiter ??= ':';
  return _dateFormat(
      'yyyy${delimiter}MM${delimiter}dd HH${hourDelimiter}mm${hourDelimiter}ss',
      time);
}

String dateFormat_YYYY_MM_dd_HH_mm(
    [int time, String delimiter = '-', String hourDelimiter = ':']) {
  delimiter ??= '-';
  hourDelimiter ??= ':';
  return _dateFormat(
      'yyyy${delimiter}MM${delimiter}dd HH${hourDelimiter}mm', time);
}

String dateFormat_YYYY_MM_dd_HH([int time, String delimiter = '-']) {
  delimiter ??= '-';
  return _dateFormat('yyyy${delimiter}MM-dd HH', time);
}

String dateFormat_YYYY_MM_dd([int time, String delimiter = '-']) {
  delimiter ??= '-';
  return _dateFormat('yyyy${delimiter}MM${delimiter}dd', time);
}

String dateFormat_YY_MM_dd([int time, String delimiter = '-']) {
  delimiter ??= '-';
  return _dateFormat('yy${delimiter}MM${delimiter}dd', time);
}

String dateFormat_YY_MM([int time, String delimiter = '-']) {
  delimiter ??= '-';
  return _dateFormat('yy${delimiter}MM', time);
}

String dateFormat_YYYY_MM([int time, String delimiter = '-']) {
  delimiter ??= '-';
  return _dateFormat('yyyy${delimiter}MM', time);
}

String _dateFormat(String format, [int time]) {
  time ??= getCurrentTimeMillis();

  _initializeDateFormatting();

  var date = DateTime.fromMillisecondsSinceEpoch(time);
  var dateFormat = DateFormat(format);
  return dateFormat.format(date);
}

/// Parses [date] as [DateTime].
///
/// Can be a [num] (Milliseconds since Epoch).
DateTime parseDateTime(dynamic date, [DateTime def]) {
  if (date == null) return def;

  if (date is DateTime) {
    return date;
  }

  if (date is num) {
    if (date == 0 && def != null) return def;
    return DateTime.fromMillisecondsSinceEpoch(date.toInt());
  }

  String s;
  if (date is String) {
    s = date;
  } else {
    s = date.toString();
  }

  s = s.trim();

  if (s.isEmpty) return def;

  return DateTime.parse(s);
}

/// Converts [o] to a [List<DateTime>].
List<DateTime> parseDateTimeFromInlineList(dynamic o,
    [Pattern delimiter = ',', List<DateTime> def]) {
  if (o == null) return def;
  if (o is DateTime) return [o];
  if (o is List) return o.map((e) => parseDateTime(e)).toList();
  return parseFromInlineList(o.toString(), delimiter, parseDateTime, def);
}

/// Parses [unit] and [amount] to [Duration].
Duration parseDuration(String unit, int amount, [Duration def]) {
  if (unit == null) return def;
  unit = unit.toLowerCase().trim();
  if (unit.isEmpty) return def;

  amount ??= 0;

  switch (unit) {
    case 'year':
    case 'years':
      return Duration(days: amount * 365);

    case 'quarter':
    case 'quarters':
      return Duration(days: amount * 90);

    case 'month':
    case 'months':
      return Duration(days: amount * 30);

    case 'd':
    case 'day':
    case 'days':
      return Duration(days: amount);

    case 'h':
    case 'hr':
    case 'hrs':
    case 'hour':
    case 'hours':
      return Duration(hours: amount);

    case 'min':
    case 'minute':
    case 'minutes':
      return Duration(minutes: amount);

    case 's':
    case 'sec':
    case 'second':
    case 'seconds':
      return Duration(seconds: amount);

    case 'ms':
    case 'millis':
    case 'millisecond':
    case 'milliseconds':
      return Duration(milliseconds: amount);

    case 'µs':
    case 'µsec':
    case 'us':
    case 'usec':
    case 'microsecond':
    case 'microseconds':
      return Duration(microseconds: amount);

    default:
      return def;
  }
}

enum Unit {
  Microseconds,
  Milliseconds,
  Seconds,
  Minutes,
  Hours,
  Days,
  Weeks,
  Months,
  Quarters,
  Years,
}

Unit getUnitByIndex(int index, [Unit def]) {
  if (index == null || index < 0 || index >= Unit.values.length) return def;
  return Unit.values[index];
}

Unit getUnitByName(String name, [Unit def]) {
  if (name == null) return def;
  name = name.toLowerCase().trim();
  if (name.isEmpty) return def;

  switch (name) {
    case 'y':
    case 'year':
    case 'years':
      return Unit.Years;

    case 'q':
    case 'quarter':
    case 'quarters':
      return Unit.Quarters;

    case 'month':
    case 'months':
      return Unit.Months;

    case 'w':
    case 'week':
    case 'weeks':
      return Unit.Weeks;

    case 'd':
    case 'day':
    case 'days':
      return Unit.Days;

    case 'h':
    case 'hr':
    case 'hrs':
    case 'hour':
    case 'hours':
      return Unit.Hours;

    case 'm':
    case 'min':
    case 'minute':
    case 'minutes':
      return Unit.Minutes;

    case 's':
    case 'sec':
    case 'second':
    case 'seconds':
      return Unit.Seconds;

    case 'ms':
    case 'milli':
    case 'millis':
    case 'millisecond':
    case 'milliseconds':
      return Unit.Milliseconds;

    case 'µs':
    case 'µsec':
    case 'us':
    case 'usec':
    case 'micro':
    case 'micros':
    case 'microsecond':
    case 'microseconds':
      return Unit.Microseconds;

    default:
      return def;
  }
}

Unit parseUnit(dynamic unit, [Unit def]) {
  if (unit == null) {
    return def;
  } else if (unit is Unit) {
    return unit;
  } else if (unit is String) {
    return getUnitByName(unit);
  } else if (unit is int) {
    return getUnitByIndex(unit);
  } else {
    return def;
  }
}

int _getUnitMilliseconds(dynamic unit) {
  if (unit == null) return null;

  var unitParsed = parseUnit(unit);

  switch (unitParsed) {
    case Unit.Milliseconds:
      return 1;
    case Unit.Seconds:
      return 1000;
    case Unit.Minutes:
      return 1000 * 60;
    case Unit.Hours:
      return 1000 * 60 * 60;
    case Unit.Days:
      return 1000 * 60 * 60 * 24;
    case Unit.Weeks:
      return 1000 * 60 * 60 * 24 * 7;
    case Unit.Months:
      return 1000 * 60 * 60 * 24 * 30;
    case Unit.Quarters:
      return 1000 * 60 * 60 * 24 * 90;
    case Unit.Years:
      return 1000 * 60 * 60 * 24 * 365;
    default:
      return null;
  }
}

int getUnitAsMilliseconds(dynamic unit, [int amount = 1]) {
  var ms = _getUnitMilliseconds(unit);
  return ms * amount;
}

double getMillisecondsAsUnit(int ms, dynamic unit, [double def]) {
  if (ms == null) return def;
  if (ms == 0) return 0;

  if (unit == null) return def;

  var unitParsed = parseUnit(unit);
  if (unitParsed == null) return def;

  var unitMs = _getUnitMilliseconds(unitParsed);
  var res = ms / unitMs;

  return res;
}

String getDateAmPm([int time]) {
  time ??= getCurrentTimeMillis();

  _initializeDateFormatting();

  var date = DateTime.fromMillisecondsSinceEpoch(time);
  var dateFormat = DateFormat('jm');
  var s = dateFormat.format(date);
  return s.contains('PM') ? 'PM' : 'AM';
}

int getDateHour([int time]) {
  time ??= getCurrentTimeMillis();

  _initializeDateFormatting();

  var date = DateTime.fromMillisecondsSinceEpoch(time);
  var dateFormat = DateFormat('HH');
  var s = dateFormat.format(date);
  return int.parse(s);
}

const int ONE_SECOND = 1000;

const int ONE_MINUTE = ONE_SECOND * 60;

const int ONE_HOUR = ONE_MINUTE * 60;

const int ONE_DAY = ONE_HOUR * 24;

String formatTimeMillis(int time) {
  if (time == null || time == 0) return '0';

  var sig = '';

  if (time < 0) {
    sig = '-';
    time = -time;
  }

  if (time < ONE_SECOND) {
    return '$sig$time ms';
  } else if (time < ONE_MINUTE) {
    var t = time / ONE_SECOND;
    var f = formatDecimal(t);
    return '$sig$f sec';
  } else if (time < ONE_HOUR) {
    var t = time / ONE_MINUTE;

    var min = t.toInt();
    var sec = ((t - min) * 60).toInt();

    return sec > 0 ? '$sig$min min $sec s' : ('$sig$min min');
  } else if (time < ONE_DAY) {
    var t = time / ONE_HOUR;

    var hour = t.toInt();
    var min = ((t - hour) * 60).toInt();

    return min > 0 ? '$sig$hour h $min min' : '$sig$hour h';
  } else {
    var t = time / ONE_DAY;

    var day = t.toInt();
    var hour = ((t - day) * 24).toInt();

    return hour > 0 ? '$sig$day d $hour h' : '$sig$day d';
  }
}

/// Represents a Week day.
enum DateTimeWeekDay {
  Monday,
  Tuesday,
  Wednesday,
  Thursday,
  Friday,
  Saturday,
  Sunday
}

/// Gets index of DateTimeWeekDay, starting from 1 (Monday) to 7 (Sunday), same range as [ DateTime.wednesday ].
int getDateTimeWeekDayIndex(DateTimeWeekDay weekDay) {
  if (weekDay == null) return null;

  switch (weekDay) {
    case DateTimeWeekDay.Monday:
      return 1;
    case DateTimeWeekDay.Tuesday:
      return 2;
    case DateTimeWeekDay.Wednesday:
      return 3;
    case DateTimeWeekDay.Thursday:
      return 4;
    case DateTimeWeekDay.Friday:
      return 5;
    case DateTimeWeekDay.Saturday:
      return 6;
    case DateTimeWeekDay.Sunday:
      return 7;
    default:
      return null;
  }
}

/// Returns enum [DateTimeWeekDay] by [weekDayIndex] (from 1 to 7). See [getDateTimeWeekDayIndex].
DateTimeWeekDay getDateTimeWeekDay(int weekDayIndex) {
  if (weekDayIndex == null) return null;

  switch (weekDayIndex) {
    case 1:
      return DateTimeWeekDay.Monday;
    case 2:
      return DateTimeWeekDay.Tuesday;
    case 3:
      return DateTimeWeekDay.Wednesday;
    case 4:
      return DateTimeWeekDay.Thursday;
    case 5:
      return DateTimeWeekDay.Friday;
    case 6:
      return DateTimeWeekDay.Saturday;
    case 7:
      return DateTimeWeekDay.Sunday;
    default:
      throw ArgumentError(
          'Invalid DateTime weekDay index. Should be of range 1-7, where Monday is 1 and Sunday is 7 (Monday-to-Sunday week).');
  }
}

/// Returns enum [DateTimeWeekDay] using [weekDayIndex] compliant with ISO 8601.
///
/// [weekDayIndex] From 0 (Monday) to 6 (Sunday).
DateTimeWeekDay getDateTimeWeekDay_from_ISO_8601_index(int weekDayIndex) {
  if (weekDayIndex == null) return null;

  switch (weekDayIndex) {
    case 0:
      return DateTimeWeekDay.Monday;
    case 1:
      return DateTimeWeekDay.Tuesday;
    case 2:
      return DateTimeWeekDay.Wednesday;
    case 3:
      return DateTimeWeekDay.Thursday;
    case 4:
      return DateTimeWeekDay.Friday;
    case 5:
      return DateTimeWeekDay.Saturday;
    case 6:
      return DateTimeWeekDay.Sunday;
    default:
      throw ArgumentError(
          'Invalid ISO 8601 weekDay index. Should be of range 0-6, where Monday is 0 and Sunday is 6 (Monday-to-Sunday week).');
  }
}

/// Returns enum [DateTimeWeekDay] by week day name in english
DateTimeWeekDay getDateTimeWeekDayByName(String weekDayName) {
  if (weekDayName == null) return null;
  weekDayName = weekDayName.toLowerCase().trim();
  if (weekDayName.isEmpty) return null;

  switch (weekDayName) {
    case 'monday':
      return DateTimeWeekDay.Monday;
    case 'tuesday':
      return DateTimeWeekDay.Tuesday;
    case 'wednesday':
      return DateTimeWeekDay.Wednesday;
    case 'thursday':
      return DateTimeWeekDay.Thursday;
    case 'friday':
      return DateTimeWeekDay.Friday;
    case 'saturday':
      return DateTimeWeekDay.Saturday;
    case 'sunday':
      return DateTimeWeekDay.Sunday;
    default:
      throw ArgumentError('Invalid DateTime week day name. Should in English.');
  }
}

/// Same as `DateTime.now()`.
DateTime getDateTimeNow() {
  return DateTime.now();
}

/// Returns the start of the day for [time].
///
/// [time] if null uses [ DateTime.now ].
DateTime getDateTimeDayStart([DateTime time]) {
  time ??= DateTime.now();
  return DateTime(time.year, time.month, time.day, 0, 0, 0, 0, 0);
}

/// Returns the end of the day for [time].
///
/// [time] if null uses [ DateTime.now ].
DateTime getDateTimeDayEnd([DateTime time]) {
  time ??= DateTime.now();
  return DateTime(time.year, time.month, time.day, 23, 59, 59, 999, 0);
}

/// Returns the start of yesterday from [time].
///
/// [time] if null uses [ DateTime.now ].
DateTime getDateTimeYesterday([DateTime time]) {
  time ??= DateTime.now();
  return getDateTimeDayStart(time.subtract(Duration(days: 1)));
}

/// Returns start and end of last [nDays] counting from [time].
///
/// [time] if null uses [ DateTime.now ].
Pair<DateTime> getDateTimeLastNDays(int nDays, [DateTime time]) {
  time ??= DateTime.now();
  return Pair(getDateTimeDayStart(time.subtract(Duration(days: nDays))),
      getDateTimeDayEnd(time));
}

/// Returns start and end of this week using [time] as reference.
///
/// [time] if null uses [ DateTime.now ].
Pair<DateTime> getDateTimeThisWeek(
    [DateTimeWeekDay weekFirstDay, DateTime now]) {
  now ??= DateTime.now();

  var weekStart = getDateTimeWeekStart(weekFirstDay, now);
  var weekEnd = getDateTimeWeekEnd(weekFirstDay, now);

  return Pair(getDateTimeDayStart(weekStart), getDateTimeDayEnd(weekEnd));
}

/// Returns start and end of last week, before current week, using [time] as reference.
///
/// [weekFirstDay] the desired first day of week for computation behavior.
/// [time] if null uses [ DateTime.now ].
Pair<DateTime> getDateTimeLastWeek(
    [DateTimeWeekDay weekFirstDay, DateTime time]) {
  time ??= DateTime.now();

  var weekStart =
      getDateTimeWeekStart(weekFirstDay, time).subtract(Duration(days: 7));
  var weekEnd = getDateTimeWeekEnd(weekFirstDay, weekStart);

  return Pair(getDateTimeDayStart(weekStart), getDateTimeDayEnd(weekEnd));
}

/// Returns start and end of this month, using [time] as reference.
///
/// [time] if null uses [ DateTime.now ].
Pair<DateTime> getDateTimeThisMonth([DateTime time]) {
  time ??= DateTime.now();

  var y = time.year;
  var m = time.month;
  return Pair(
      getDateTimeDayStart(DateTime(y, m, 1, 0, 0, 0, 0, 0)),
      getDateTimeDayEnd(
          DateTime(y, m, getLastDayOfMonth(m, year: y), 23, 59, 59, 0, 0)));
}

/// Returns start and end of last month, before current month, using [time] as reference.
///
/// [time] if null uses [ DateTime.now ].
Pair<DateTime> getDateTimeLastMonth([DateTime time]) {
  time ??= DateTime.now();

  var prevMonth = getDateTimePreviousMonth(time.month, year: time.year);

  var y = prevMonth.year;
  var m = prevMonth.month;

  return Pair(
      getDateTimeDayStart(DateTime(y, m, 1, 0, 0, 0, 0, 0)),
      getDateTimeDayEnd(
          DateTime(y, m, getLastDayOfMonth(m, year: y), 23, 59, 59, 9, 0)));
}

/// Returns start of previous month, using as reference [month] and [year].
///
/// [month] from 1 to 12.
/// [year] if null uses year from [ DateTime.now ].
DateTime getDateTimePreviousMonth(int month, {int year}) {
  year ??= DateTime.now().year;
  var cursor = DateTime(year, month, 1, 0, 0, 0, 0, 0);
  var prev = cursor.subtract(Duration(days: 1));
  return prev;
}

/// Returns the last day of [month].
///
/// [month] from 1 to 12.
/// [year] if null uses year from [ DateTime.now ].
int getLastDayOfMonth(int month, {int year}) {
  year ??= DateTime.now().year;

  var cursor = DateTime(year, month, 28, 12, 0, 0);

  while (true) {
    var next = cursor.add(Duration(days: 1));
    if (next.month != cursor.month) {
      return cursor.day;
    }
    cursor = next;
  }
}

/// Returns the start of the week using [time] as reference.
///
/// [weekFirstDay] the desired first day of week for computation behavior.
/// [time] if null uses [ DateTime.now ].
DateTime getDateTimeWeekStart([DateTimeWeekDay weekFirstDay, DateTime time]) {
  weekFirstDay ??= DateTimeWeekDay.Monday;
  time ??= DateTime.now();

  var weekFirstDayIndex = getDateTimeWeekDayIndex(weekFirstDay);

  while (time.weekday != weekFirstDayIndex) {
    time = time.subtract(Duration(days: 1));
  }

  return getDateTimeDayStart(time);
}

/// Returns the end of the week using [time] as reference.
///
/// [weekFirstDay] the desired first day of week for computation behavior.
/// [time] if null uses [ DateTime.now ].
DateTime getDateTimeWeekEnd([DateTimeWeekDay weekFirstDay, DateTime now]) {
  weekFirstDay ??= DateTimeWeekDay.Monday;
  now ??= DateTime.now();

  var weekStart = getDateTimeWeekStart(weekFirstDay, now);

  var weekEnd = weekStart.add(Duration(days: 6)).add(Duration(hours: 12));

  return getDateTimeDayEnd(weekEnd);
}

/// Enum for types of date ranges.
enum DateRangeType {
  /// Today.
  TODAY,

  /// Yesterday.
  YESTERDAY,

  /// Last 7 days.
  LAST_7_DAYS,

  /// Current week.
  THIS_WEEK,

  /// Previous week.
  LAST_WEEK,

  /// Last 30 days.
  LAST_30_DAYS,

  /// Last 60 days.
  LAST_60_DAYS,

  /// Last 90 days.
  LAST_90_DAYS,

  /// Previous month.
  LAST_MONTH,

  /// Current month.
  THIS_MONTH,
}

/// Returns start and end of date range [rangeType].
///
/// [weekFirstDay] the desired first day of week for computation behavior.
/// [time] if null uses [ DateTime.now ].
Pair<DateTime> getDateTimeRange(DateRangeType rangeType,
    [DateTime time, DateTimeWeekDay weekFirstDay]) {
  time ??= getDateTimeNow();

  var nowStart = getDateTimeDayStart(time);
  var nowEnd = getDateTimeDayEnd(time);

  switch (rangeType) {
    case DateRangeType.TODAY:
      return Pair(nowStart, nowEnd);
    case DateRangeType.YESTERDAY:
      {
        var timeYesterday = getDateTimeYesterday(time);
        return Pair(timeYesterday, getDateTimeDayEnd(timeYesterday));
      }

    case DateRangeType.LAST_7_DAYS:
      return getDateTimeLastNDays(6, nowEnd);
    case DateRangeType.THIS_WEEK:
      return getDateTimeThisWeek(weekFirstDay, nowStart);
    case DateRangeType.LAST_WEEK:
      return getDateTimeLastWeek(weekFirstDay, nowStart);

    case DateRangeType.LAST_30_DAYS:
      return getDateTimeLastNDays(29, time);
    case DateRangeType.LAST_60_DAYS:
      return getDateTimeLastNDays(59, time);
    case DateRangeType.LAST_90_DAYS:
      return getDateTimeLastNDays(89, time);
    case DateRangeType.LAST_MONTH:
      return getDateTimeLastMonth(time);
    case DateRangeType.THIS_MONTH:
      return getDateTimeThisMonth(time);
    default:
      throw UnsupportedError("Can't handle: $rangeType");
  }
}

/// Returns the start of a time [unit] using [time] as reference.
///
/// [weekFirstDay] the desired first day of week for computation behavior.
/// [locale] Locale code to use if [weekFirstDay] is null and need to be defined.
DateTime getDateTimeStartOf(DateTime time, dynamic unit,
    {DateTimeWeekDay weekFirstDay, String locale}) {
  var unitParsed = parseUnit(unit);
  if (unitParsed == null) return null;

  switch (unitParsed) {
    case Unit.Years:
      return DateTime(time.year);
    case Unit.Quarters:
      return DateTime(time.year, (time.month ~/ 3) * 3);
    case Unit.Weeks:
      {
        weekFirstDay ??= getWeekFirstDay(locale);
        var dateTimeRange =
            getDateTimeRange(DateRangeType.THIS_WEEK, time, weekFirstDay);
        return dateTimeRange.a;
      }
    case Unit.Months:
      return DateTime(time.year, time.month);
    case Unit.Days:
      return DateTime(time.year, time.month, time.day);
    case Unit.Hours:
      return DateTime(time.year, time.month, time.day, time.hour);
    case Unit.Minutes:
      return DateTime(time.year, time.month, time.day, time.hour, time.minute);
    case Unit.Seconds:
      return DateTime(
          time.year, time.month, time.day, time.hour, time.minute, time.second);
    default:
      break;
  }

  if ('$unit'.toLowerCase().trim() == 'date') {
    return DateTime(time.year, time.month, time.day);
  }

  throw ArgumentError("Can't handle unit: $unit");
}

/// Returns the end of a time [unit] using [time] as reference.
///
/// [weekFirstDay] the desired first day of week for computation behavior.
/// [locale] Locale code to use if [weekFirstDay] is null and need to be defined.
DateTime getDateTimeEndOf(DateTime time, dynamic unit,
    {DateTimeWeekDay weekFirstDay, String locale}) {
  var unitParsed = parseUnit(unit);
  if (unitParsed == null) return null;

  switch (unitParsed) {
    case Unit.Years:
      return DateTime(time.year, 12, 31, 23, 59, 59, 999);
    case Unit.Quarters:
      return getDateTimeThisMonth(getDateTimeStartOf(time, unit)).b;
    case Unit.Weeks:
      {
        weekFirstDay ??= getWeekFirstDay(locale);
        var dateTimeRange =
            getDateTimeRange(DateRangeType.THIS_WEEK, time, weekFirstDay);
        return dateTimeRange.b;
      }
    case Unit.Months:
      return getDateTimeThisMonth(DateTime(time.year, time.month, 1)).b;
    case Unit.Days:
      return DateTime(time.year, time.month, time.day, 23, 59, 59, 999);
    case Unit.Hours:
      return DateTime(time.year, time.month, time.day, time.hour, 59, 59, 999);
    case Unit.Minutes:
      return DateTime(
          time.year, time.month, time.day, time.hour, time.minute, 59, 999);
    case Unit.Seconds:
      return DateTime(time.year, time.month, time.day, time.hour, time.minute,
          time.second, 999);
    default:
      break;
  }

  if ('$unit'.toLowerCase().trim() == 'date') {
    return getDateTimeStartOf(time, unit)
        .add(Duration(hours: 23, minutes: 59, seconds: 59, milliseconds: 999));
  }

  throw ArgumentError("Can't handle unit: $unit");
}

/// Returns the first day of a week as enum [DateTimeWeekDay] for [locale].
///
/// [locale] if null uses system default.
DateTimeWeekDay getWeekFirstDay([String locale]) {
  var dateSymbols = _getLocaleDateSymbols(locale);
  if (dateSymbols == null) return DateTimeWeekDay.Monday;
  var firstdayofweek = dateSymbols.FIRSTDAYOFWEEK;
  var dateTimeWeekDay = getDateTimeWeekDay_from_ISO_8601_index(firstdayofweek);
  assert(dateTimeWeekDay != null);
  return dateTimeWeekDay;
}

DateSymbols _getLocaleDateSymbols([String locale]) {
  locale ??= Intl.defaultLocale ?? 'en_ISO';
  var language = locale.split('_')[0];

  var map = dateTimeSymbolMap();
  DateSymbols dateSymbols = map[locale];
  dateSymbols ??= map[language];

  if (dateSymbols != null) return dateSymbols;

  for (var entry in map.entries) {
    if (entry.key.toString().startsWith(language)) {
      return entry.value;
    }
  }

  return map['en_ISO'];
}
