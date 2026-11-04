import 'package:swiss_knife/swiss_knife.dart';
import 'package:test/test.dart';

// All dates are local and far from DST transitions (mid-year, both
// hemispheres), so the expectations don't depend on the machine's timezone.

void main() {
  group('Date format', () {
    final time = DateTime(2024, 7, 15, 13, 5, 9).millisecondsSinceEpoch;

    test('dateFormat_*', () {
      expect(
        dateFormat_YYYY_MM_dd_HH_mm_ss(time),
        equals('2024-07-15 13:05:09'),
      );
      expect(
        dateFormat_YYYY_MM_dd_HH_mm_ss(time, '/', '.'),
        equals('2024/07/15 13.05.09'),
      );
      expect(dateFormat_YYYY_MM_dd_HH_mm(time), equals('2024-07-15 13:05'));
      expect(
        dateFormat_YYYY_MM_dd_HH_mm(time, '/', '.'),
        equals('2024/07/15 13.05'),
      );
      expect(dateFormat_YYYY_MM_dd_HH(time), equals('2024-07-15 13'));
      expect(dateFormat_YYYY_MM_dd_HH(time, '/'), equals('2024/07/15 13'));
      expect(dateFormat_YYYY_MM_dd(time), equals('2024-07-15'));
      expect(dateFormat_YYYY_MM_dd(time, '.'), equals('2024.07.15'));
      expect(dateFormat_YY_MM_dd(time), equals('24-07-15'));
      expect(dateFormat_YY_MM(time), equals('24-07'));
      expect(dateFormat_YYYY_MM(time, '/'), equals('2024/07'));

      // Current time:
      expect(dateFormat_YYYY_MM_dd(), matches(RegExp(r'^\d{4}-\d\d-\d\d$')));
    });

    test('getDateAmPm / getDateHour', () {
      expect(getDateAmPm(time), equals('PM'));
      expect(
        getDateAmPm(DateTime(2024, 7, 15, 9).millisecondsSinceEpoch),
        equals('AM'),
      );
      expect(getDateHour(time), equals(13));
      expect(getDateHour(), inInclusiveRange(0, 23));
      expect(getDateAmPm(), anyOf('AM', 'PM'));
    });

    test('formatTimeMillis', () {
      expect(formatTimeMillis(null), equals('0'));
      expect(formatTimeMillis(0), equals('0'));
      expect(formatTimeMillis(500), equals('500 ms'));
      expect(formatTimeMillis(-500), equals('-500 ms'));
      expect(formatTimeMillis(1500), equals('1.5 sec'));
      expect(formatTimeMillis(oneMinute * 2), equals('2 min'));
      expect(formatTimeMillis(oneMinute * 2 + 30000), equals('2 min 30 s'));
      expect(formatTimeMillis(oneHour * 3), equals('3 h'));
      expect(
        formatTimeMillis(oneHour * 3 + oneMinute * 15),
        equals('3 h 15 min'),
      );
      expect(formatTimeMillis(oneDay * 2), equals('2 d'));
      expect(formatTimeMillis(oneDay * 2 + oneHour * 6), equals('2 d 6 h'));
      expect(formatTimeMillis(-oneDay), equals('-1 d'));
    });
  });

  group('Date parsing', () {
    test('getCurrentTimeMillis / isInUnixEpochRange', () {
      var now = getCurrentTimeMillis();
      expect(isInUnixEpochRange(now), isTrue);
      expect(isInUnixEpochRange(now ~/ 1000, false), isTrue);
      expect(isInUnixEpochRange(now ~/ 1000), isFalse);
      expect(isInUnixEpochRange('$now'), isTrue);
      expect(isInUnixEpochRange(123), isFalse);
      expect(isInUnixEpochRange('abc'), isFalse);
      expect(isInUnixEpochRange(null), isFalse);
    });

    test('parseDateTime', () {
      var d = DateTime(2024, 7, 15, 13, 5, 9);
      var def = DateTime(2000);

      expect(parseDateTime(null), isNull);
      expect(parseDateTime(null, def), equals(def));
      expect(parseDateTime(d), same(d));
      expect(parseDateTime(d.millisecondsSinceEpoch), equals(d));
      expect(parseDateTime(0, def), equals(def));
      expect(parseDateTime(0), equals(DateTime.fromMillisecondsSinceEpoch(0)));
      expect(parseDateTime('2024-07-15 13:05:09'), equals(d));
      expect(parseDateTime('  '), isNull);
      expect(parseDateTime('', def), equals(def));
      expect(
        parseDateTime(StringBuffer('2024-07-15')),
        equals(DateTime(2024, 7, 15)),
      );
      expect(() => parseDateTime('not a date'), throwsFormatException);
    });

    test('parseDateTimeFromInlineList', () {
      var d1 = DateTime(2024, 7, 15);
      var d2 = DateTime(2024, 8, 1);
      var def = [DateTime(2000)];

      expect(parseDateTimeFromInlineList(null), isNull);
      expect(parseDateTimeFromInlineList(null, ',', def), same(def));
      expect(parseDateTimeFromInlineList(d1), equals([d1]));
      expect(
        parseDateTimeFromInlineList(['2024-07-15', d2.millisecondsSinceEpoch]),
        equals([d1, d2]),
      );
      expect(
        parseDateTimeFromInlineList('2024-07-15,2024-08-01'),
        equals([d1, d2]),
      );
      expect(
        parseDateTimeFromInlineList('2024-07-15; 2024-08-01', ';'),
        equals([d1, d2]),
      );
      expect(parseDateTimeFromInlineList('  ', ',', def), same(def));
    });

    test('parseDuration', () {
      expect(parseDuration(null), isNull);
      expect(
        parseDuration('', 1, Duration(seconds: 1)),
        equals(Duration(seconds: 1)),
      );
      expect(parseDuration('unknown', 1), isNull);
      expect(parseDuration('years', 2), equals(Duration(days: 730)));
      expect(parseDuration('quarter', 1), equals(Duration(days: 90)));
      expect(parseDuration('Months', 2), equals(Duration(days: 60)));
      expect(parseDuration('d', 3), equals(Duration(days: 3)));
      expect(parseDuration(' hours ', 4), equals(Duration(hours: 4)));
      expect(parseDuration('min', 5), equals(Duration(minutes: 5)));
      expect(parseDuration('sec', 6), equals(Duration(seconds: 6)));
      expect(parseDuration('ms', 7), equals(Duration(milliseconds: 7)));
      expect(parseDuration('us', 8), equals(Duration(microseconds: 8)));
    });
  });

  group('Unit', () {
    test('getUnitByIndex / getUnitByName / parseUnit', () {
      expect(getUnitByIndex(null), isNull);
      expect(getUnitByIndex(-1, Unit.days), equals(Unit.days));
      expect(getUnitByIndex(Unit.values.length), isNull);
      expect(getUnitByIndex(0), equals(Unit.microseconds));
      expect(getUnitByIndex(9), equals(Unit.years));

      expect(getUnitByName(null, Unit.days), equals(Unit.days));
      expect(getUnitByName(' '), isNull);
      expect(getUnitByName('xyz'), isNull);
      expect(getUnitByName('Y'), equals(Unit.years));
      expect(getUnitByName('q'), equals(Unit.quarters));
      expect(getUnitByName('month'), equals(Unit.months));
      expect(getUnitByName('w'), equals(Unit.weeks));
      expect(getUnitByName('days'), equals(Unit.days));
      expect(getUnitByName('hr'), equals(Unit.hours));
      expect(getUnitByName('m'), equals(Unit.minutes));
      expect(getUnitByName('s'), equals(Unit.seconds));
      expect(getUnitByName('millis'), equals(Unit.milliseconds));
      expect(getUnitByName('micros'), equals(Unit.microseconds));

      expect(parseUnit(null), isNull);
      expect(parseUnit(null, Unit.hours), equals(Unit.hours));
      expect(parseUnit(Unit.weeks), equals(Unit.weeks));
      expect(parseUnit('week'), equals(Unit.weeks));
      expect(parseUnit(5), equals(Unit.days));
      expect(parseUnit(1.5, Unit.days), equals(Unit.days));
    });

    test('getUnitAsMilliseconds / getMillisecondsAsUnit', () {
      expect(getUnitAsMilliseconds(Unit.milliseconds), equals(1));
      expect(getUnitAsMilliseconds('sec', 2), equals(2000));
      expect(getUnitAsMilliseconds('min'), equals(oneMinute));
      expect(getUnitAsMilliseconds('hour'), equals(oneHour));
      expect(getUnitAsMilliseconds('day'), equals(oneDay));
      expect(getUnitAsMilliseconds('week'), equals(oneDay * 7));
      expect(getUnitAsMilliseconds('month'), equals(oneDay * 30));
      expect(getUnitAsMilliseconds('quarter'), equals(oneDay * 90));
      expect(getUnitAsMilliseconds('year'), equals(oneDay * 365));

      expect(getMillisecondsAsUnit(null, 'sec'), isNull);
      expect(getMillisecondsAsUnit(0, 'sec'), equals(0));
      expect(getMillisecondsAsUnit(1000, null, -1), equals(-1));
      expect(getMillisecondsAsUnit(1000, 'xyz', -1), equals(-1));
      expect(getMillisecondsAsUnit(1500, 'sec'), equals(1.5));
      expect(getMillisecondsAsUnit(oneHour * 3, Unit.hours), equals(3));
    });
  });

  group('Week days', () {
    test('index conversions', () {
      expect(getDateTimeWeekDayIndex(null), isNull);
      expect(getDateTimeWeekDay(null), isNull);
      expect(getDateTimeWeekDay_from_ISO_8601_index(null), isNull);

      for (var i = 0; i < DateTimeWeekDay.values.length; ++i) {
        var weekDay = DateTimeWeekDay.values[i];
        expect(getDateTimeWeekDayIndex(weekDay), equals(i + 1));
        expect(getDateTimeWeekDay(i + 1), equals(weekDay));
        expect(getDateTimeWeekDay_from_ISO_8601_index(i), equals(weekDay));
        expect(
          getDateTimeWeekDayByName(weekDay.name.toUpperCase()),
          equals(weekDay),
        );
      }

      // Consistent with `DateTime.weekday`:
      expect(
        getDateTimeWeekDayIndex(DateTimeWeekDay.wednesday),
        equals(DateTime.wednesday),
      );

      expect(() => getDateTimeWeekDay(0), throwsArgumentError);
      expect(() => getDateTimeWeekDay(8), throwsArgumentError);
      expect(
        () => getDateTimeWeekDay_from_ISO_8601_index(7),
        throwsArgumentError,
      );
      expect(getDateTimeWeekDayByName(null), isNull);
      expect(getDateTimeWeekDayByName(' '), isNull);
      expect(() => getDateTimeWeekDayByName('segunda'), throwsArgumentError);
    });

    test('getWeekFirstDay', () {
      expect(getWeekFirstDay('en_US'), equals(DateTimeWeekDay.sunday));
      expect(getWeekFirstDay('en_ISO'), equals(DateTimeWeekDay.monday));
      expect(getWeekFirstDay('de'), equals(DateTimeWeekDay.monday));
      expect(getWeekFirstDay('pt_BR'), equals(DateTimeWeekDay.sunday));
      // Unknown locale falls back to `en_ISO`:
      expect(getWeekFirstDay('xx_YY'), equals(DateTimeWeekDay.monday));
      expect(DateTimeWeekDay.values, contains(getWeekFirstDay()));
    });
  });

  group('Date ranges', () {
    // Wednesday.
    final time = DateTime(2024, 7, 17, 15, 30, 10, 500);

    DateTime start(int y, int m, int d) => DateTime(y, m, d);
    DateTime end(int y, int m, int d) => DateTime(y, m, d, 23, 59, 59, 999);

    test('day start/end and yesterday', () {
      expect(getDateTimeDayStart(time), equals(start(2024, 7, 17)));
      expect(getDateTimeDayEnd(time), equals(end(2024, 7, 17)));
      expect(getDateTimeYesterday(time), equals(start(2024, 7, 16)));
      expect(
        getDateTimeYesterday(DateTime(2024, 7, 1, 10)),
        equals(start(2024, 6, 30)),
      );

      var now = getDateTimeNow();
      expect(getDateTimeDayStart().isAfter(now), isFalse);
      expect(getDateTimeDayEnd().isBefore(now), isFalse);
      expect(getDateTimeYesterday().isBefore(now), isTrue);
    });

    test('getDateTimeLastNDays', () {
      var range = getDateTimeLastNDays(6, time);
      expect(range.a, equals(start(2024, 7, 11)));
      expect(range.b, equals(end(2024, 7, 17)));
    });

    test('weeks', () {
      expect(getDateTimeWeekStart(null, time), equals(start(2024, 7, 15)));
      expect(getDateTimeWeekEnd(null, time), equals(end(2024, 7, 21)));
      expect(
        getDateTimeWeekStart(DateTimeWeekDay.sunday, time),
        equals(start(2024, 7, 14)),
      );
      expect(
        getDateTimeWeekEnd(DateTimeWeekDay.sunday, time),
        equals(end(2024, 7, 20)),
      );

      var thisWeek = getDateTimeThisWeek(DateTimeWeekDay.monday, time);
      expect(thisWeek.a, equals(start(2024, 7, 15)));
      expect(thisWeek.b, equals(end(2024, 7, 21)));

      var lastWeek = getDateTimeLastWeek(DateTimeWeekDay.monday, time);
      expect(lastWeek.a, equals(start(2024, 7, 8)));
      expect(lastWeek.b, equals(end(2024, 7, 14)));
    });

    test('months', () {
      var thisMonth = getDateTimeThisMonth(time);
      expect(thisMonth.a, equals(start(2024, 7, 1)));
      expect(thisMonth.b, equals(end(2024, 7, 31)));

      var lastMonth = getDateTimeLastMonth(time);
      expect(lastMonth.a, equals(start(2024, 6, 1)));
      expect(lastMonth.b, equals(end(2024, 6, 30)));

      var lastMonthJan = getDateTimeLastMonth(DateTime(2024, 1, 10, 12));
      expect(lastMonthJan.a, equals(start(2023, 12, 1)));
      expect(lastMonthJan.b, equals(end(2023, 12, 31)));

      expect(
        getDateTimePreviousMonth(7, year: 2024),
        equals(start(2024, 6, 30)),
      );
      expect(
        getDateTimePreviousMonth(1, year: 2024),
        equals(start(2023, 12, 31)),
      );

      expect(getLastDayOfMonth(2, year: 2024), equals(29));
      expect(getLastDayOfMonth(2, year: 2023), equals(28));
      expect(getLastDayOfMonth(4, year: 2024), equals(30));
      expect(getLastDayOfMonth(12, year: 2024), equals(31));
      expect(getLastDayOfMonth(1), equals(31));
    });

    test('getDateTimeRange', () {
      void check(DateRangeType type, DateTime a, DateTime b) {
        var range = getDateTimeRange(type, time, DateTimeWeekDay.monday);
        expect(range.a, equals(a), reason: '$type start');
        expect(range.b, equals(b), reason: '$type end');
      }

      check(DateRangeType.today, start(2024, 7, 17), end(2024, 7, 17));
      check(DateRangeType.yesterday, start(2024, 7, 16), end(2024, 7, 16));
      check(DateRangeType.last7Days, start(2024, 7, 11), end(2024, 7, 17));
      check(DateRangeType.thisWeek, start(2024, 7, 15), end(2024, 7, 21));
      check(DateRangeType.lastWeek, start(2024, 7, 8), end(2024, 7, 14));
      check(DateRangeType.last30Days, start(2024, 6, 18), end(2024, 7, 17));
      check(DateRangeType.last60Days, start(2024, 5, 19), end(2024, 7, 17));
      check(DateRangeType.last90Days, start(2024, 4, 19), end(2024, 7, 17));
      check(DateRangeType.lastMonth, start(2024, 6, 1), end(2024, 6, 30));
      check(DateRangeType.thisMonth, start(2024, 7, 1), end(2024, 7, 31));

      var today = getDateTimeRange(DateRangeType.today);
      expect(today.a, equals(getDateTimeDayStart()));
    });

    test('getDateTimeStartOf/EndOf: quarters', () {
      void check(int month, DateTime a, DateTime b) {
        var t = DateTime(2024, month, 15, 12);
        expect(
          getDateTimeStartOf(t, Unit.quarters),
          equals(a),
          reason: 'month $month',
        );
        expect(getDateTimeEndOf(t, 'q'), equals(b), reason: 'month $month');
      }

      check(1, start(2024, 1, 1), end(2024, 3, 31));
      check(3, start(2024, 1, 1), end(2024, 3, 31));
      check(4, start(2024, 4, 1), end(2024, 6, 30));
      check(6, start(2024, 4, 1), end(2024, 6, 30));
      check(7, start(2024, 7, 1), end(2024, 9, 30));
      check(9, start(2024, 7, 1), end(2024, 9, 30));
      check(10, start(2024, 10, 1), end(2024, 12, 31));
      check(12, start(2024, 10, 1), end(2024, 12, 31));
    });

    test('getDateTimeStartOf/EndOf: weeks and unknown units', () {
      expect(
        getDateTimeStartOf(time, 'week', weekFirstDay: DateTimeWeekDay.monday),
        equals(start(2024, 7, 15)),
      );
      expect(
        getDateTimeEndOf(
          time,
          Unit.weeks,
          weekFirstDay: DateTimeWeekDay.monday,
        ),
        equals(end(2024, 7, 21)),
      );
      expect(
        getDateTimeStartOf(time, Unit.weeks, locale: 'en_US'),
        equals(start(2024, 7, 14)),
      );
      expect(
        getDateTimeEndOf(time, Unit.weeks, locale: 'en_US'),
        equals(end(2024, 7, 20)),
      );

      expect(getDateTimeStartOf(time, null), isNull);
      expect(getDateTimeEndOf(time, 'xyz'), isNull);
      expect(
        () => getDateTimeStartOf(time, Unit.milliseconds),
        throwsArgumentError,
      );
      expect(
        () => getDateTimeEndOf(time, Unit.microseconds),
        throwsArgumentError,
      );
    });
  });
}
