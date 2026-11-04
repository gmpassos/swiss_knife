import 'dart:math' as dart_math;

import 'package:swiss_knife/swiss_knife.dart';
import 'package:test/test.dart';

/// `true` when compiled to JavaScript, where `1.0 is int`.
final bool _isJSNumbers = identical(1, 1.0);

class _ToStr {
  final String s;

  _ToStr(this.s);

  @override
  String toString() => s;
}

class _BadToString {
  @override
  String toString() => throw StateError('no toString');
}

void main() {
  group('Math constants and delegates', () {
    test('constants', () {
      expect(Math.e, closeTo(2.718281828, 1e-9));
      expect(Math.ln2, closeTo(0.693147180, 1e-9));
      expect(Math.ln10, closeTo(2.302585092, 1e-9));
      expect(Math.log2E, closeTo(1.442695040, 1e-9));
      expect(Math.log10E, closeTo(0.434294481, 1e-9));
      expect(Math.pi, closeTo(3.141592653, 1e-9));
      expect(Math.sqrtHalf, closeTo(0.707106781, 1e-9));
      expect(Math.sqrt2, closeTo(1.414213562, 1e-9));
    });

    test('min/max/clamp', () {
      expect(Math.min(3, 5), equals(3));
      expect(Math.max(3, 5), equals(5));
      expect(Math.min(-1.5, 2.5), equals(-1.5));
      expect(Math.clamp(15, 0, 10), equals(10));
      expect(Math.clamp(-5, 0, 10), equals(0));
      expect(Math.clamp(7, 0, 10), equals(7));
    });

    test('trigonometric, pow, sqrt, exp, log', () {
      expect(Math.atan2(1, 1), closeTo(dart_math.pi / 4, 1e-12));
      expect(Math.pow(2, 10), equals(1024));
      expect(Math.pow(4, 0.5), closeTo(2, 1e-12));
      expect(Math.sin(0), equals(0));
      expect(Math.sin(dart_math.pi / 2), closeTo(1, 1e-12));
      expect(Math.cos(0), equals(1));
      expect(Math.tan(dart_math.pi / 4), closeTo(1, 1e-12));
      expect(Math.acos(1), equals(0));
      expect(Math.asin(1), closeTo(dart_math.pi / 2, 1e-12));
      expect(Math.atan(1), closeTo(dart_math.pi / 4, 1e-12));
      expect(Math.sqrt(81), equals(9));
      expect(Math.exp(0), equals(1));
      expect(Math.exp(1), closeTo(dart_math.e, 1e-12));
      expect(Math.log(dart_math.e), closeTo(1, 1e-12));
    });

    test('abs', () {
      expect(Math.abs(-3), equals(3));
      expect(Math.abs(3), equals(3));
      expect(Math.abs(-2.5), equals(2.5));
      expect(Math.abs(0), equals(0));
    });

    test('ceil/floor/round (positive values)', () {
      expect(Math.ceil(3), equals(3));
      expect(Math.ceil(2.0), equals(2));
      expect(Math.ceil(2.3), equals(3));
      expect(Math.ceil(double.nan).isNaN, isTrue);
      expect(Math.ceil(double.infinity), equals(double.infinity));

      expect(Math.floor(3), equals(3));
      expect(Math.floor(2.7), equals(2));
      expect(Math.floor(double.nan).isNaN, isTrue);
      expect(
        Math.floor(double.negativeInfinity),
        equals(double.negativeInfinity),
      );

      expect(Math.round(3), equals(3));
      expect(Math.round(2.0), equals(2));
      expect(Math.round(2.4), equals(2));
      expect(Math.round(2.5), equals(3));
      expect(Math.round(2.6), equals(3));
      expect(Math.round(-2.5), equals(-2));
      expect(Math.round(double.nan).isNaN, isTrue);
      expect(Math.round(double.infinity), equals(double.infinity));
    });

    test('ceil/floor/round (negative values)', () {
      // Regression: these truncated toward zero (ceil(-2.3) was -1,
      // floor(-2.3) was -2 and round(-2.7) was -2).
      expect(Math.ceil(-2.3), equals(-2));
      expect(Math.ceil(-2.0), equals(-2));
      expect(Math.ceil(-0.5), equals(0));
      expect(Math.floor(-2.3), equals(-3));
      expect(Math.floor(-2.0), equals(-2));
      expect(Math.floor(-0.5), equals(-1));
      expect(Math.round(-2.7), equals(-3));
      expect(Math.round(-2.3), equals(-2));
      // Ties round toward positive infinity, as documented.
      expect(Math.round(-2.5), equals(-2));
      expect(Math.round(-0.5), equals(0));
    });

    test('random', () {
      for (var i = 0; i < 20; i++) {
        var r = Math.random();
        expect(r, greaterThanOrEqualTo(0));
        expect(r, lessThan(1));
      }
    });
  });

  group('Math aggregates', () {
    test('hasNaN', () {
      expect(Math.hasNaN([]), isFalse);
      expect(Math.hasNaN([1, 2.5]), isFalse);
      expect(Math.hasNaN([1, double.nan, 3]), isTrue);
    });

    test('sum/subtract/multiply/divide', () {
      expect(Math.sum([]), equals(0));
      expect(Math.sum([1, 2, 3.5]), equals(6.5));

      expect(Math.subtract([]), equals(0));
      expect(Math.subtract([5]), equals(0));
      expect(Math.subtract([10, 3, 2]), equals(5));

      expect(Math.multiply([]), equals(0));
      expect(Math.multiply([5]), equals(0));
      expect(Math.multiply([2, 3, 4]), equals(24));

      expect(Math.divide([]), equals(0));
      expect(Math.divide([5]), equals(0));
      expect(Math.divide([100, 2, 5]), equals(10));
      expect(Math.divide([1, 4]), equals(0.25));
    });

    test('mean/standardDeviation', () {
      expect(Math.mean([]), equals(0));
      expect(Math.mean([1, 2, 3, 4]), equals(2.5));

      expect(Math.standardDeviation([5]), equals(0));

      var ns = [2, 4, 4, 4, 5, 5, 7, 9];
      var expected = dart_math.sqrt(32 / 7);
      expect(Math.standardDeviation(ns), closeTo(expected, 1e-12));
      expect(Math.standardDeviation(ns, 5), closeTo(expected, 1e-12));
      // A different (wrong) mean changes the result:
      expect(
        Math.standardDeviation([1, 3], 0),
        closeTo(dart_math.sqrt(10), 1e-12),
      );
    });

    test('minMax', () {
      expect(Math.minMax<num>(null), isNull);
      expect(Math.minMax<num>([]), isNull);

      var p = Math.minMax<num>([3, -1, 7.5, 2])!;
      expect(p.a, equals(-1));
      expect(p.b, equals(7.5));

      var ps = Math.minMax<String>([
        'b',
        'a',
        'd',
        'c',
      ], (a, b) => a.compareTo(b))!;
      expect(ps.a, equals('a'));
      expect(ps.b, equals('d'));
    });

    test('minInList/maxInList', () {
      expect(Math.minInList<num>(null), isNull);
      expect(Math.minInList<num>([]), isNull);
      expect(Math.maxInList<num>(null), isNull);
      expect(Math.maxInList<num>([]), isNull);

      expect(Math.minInList<num>([3, -1, 7.5, 2]), equals(-1));
      expect(Math.maxInList<num>([3, -1, 7.5, 2]), equals(7.5));

      int cmp(String a, String b) => a.length.compareTo(b.length);

      expect(Math.minInList(['ccc', 'a', 'bb'], cmp), equals('a'));
      expect(Math.maxInList(['ccc', 'a', 'dddd', 'bb'], cmp), equals('dddd'));
    });
  });

  group('parse', () {
    test('parseInt', () {
      expect(parseInt(null), isNull);
      expect(parseInt(null, 7), equals(7));
      expect(parseInt(12), equals(12));
      expect(parseInt(3.9), equals(3));
      expect(parseInt(DateTime.fromMillisecondsSinceEpoch(1234)), equals(1234));
      expect(parseInt(' 42 '), equals(42));
      expect(parseInt('3.7'), equals(3));
      expect(parseInt(''), isNull);
      expect(parseInt('  ', 5), equals(5));
      expect(parseInt('abc', 9), equals(9));
      expect(parseInt(_ToStr(' 77 ')), equals(77));
    });

    test('parseIntList', () {
      expect(parseIntList(null), isNull);
      expect(parseIntList(null, [1]), equals([1]));
      expect(parseIntList(['1', 'x', 2, 3.5]), equals([1, 2, 3]));
      expect(parseIntList([]), equals([]));
      expect(parseIntList([], [7]), equals([7]));
      expect(parseIntList(['x'], [8]), equals([8]));
      expect(parseIntList('1, 2 ,3'), equals([1, 2, 3]));
      expect(parseIntList(''), isNull);
      expect(parseIntList('', [9]), equals([9]));
      expect(parseIntList(5), isNull);
      expect(parseIntList(5, [6]), equals([6]));
    });

    test('parseDouble', () {
      expect(parseDouble(null), isNull);
      expect(parseDouble(null, 1.5), equals(1.5));
      expect(parseDouble(2.5), equals(2.5));
      expect(parseDouble(2), equals(2.0));
      expect(parseDouble(' 3.25 '), equals(3.25));
      expect(parseDouble(''), isNull);
      expect(parseDouble('x', 0.5), equals(0.5));
      expect(parseDouble(_ToStr('4.5')), equals(4.5));
    });

    test('parseNum', () {
      expect(parseNum(null), isNull);
      expect(parseNum(null, 3), equals(3));
      expect(parseNum(5), equals(5));
      expect(parseNum(DateTime.fromMillisecondsSinceEpoch(99)), equals(99));
      expect(parseNum(' 10 '), equals(10));
      expect(parseNum('1.5'), equals(1.5));
      expect(parseNum(''), isNull);
      expect(parseNum('zz', 4), equals(4));
      expect(parseNum(_ToStr('6.5')), equals(6.5));
    });

    test('parseBool', () {
      expect(parseBool(null), isNull);
      expect(parseBool(null, true), isTrue);
      expect(parseBool(false), isFalse);
      expect(parseBool(1), isTrue);
      expect(parseBool(0), isFalse);
      expect(parseBool(-1), isFalse);
      expect(parseBool(''), isNull);
      expect(parseBool(' ', false), isFalse);
      for (var s in [
        'true',
        'YES',
        'ok',
        'on',
        'enabled',
        'active',
        'activated',
        'selected',
        '1',
        'y',
        's',
        't',
        '+',
      ]) {
        expect(parseBool(s), isTrue, reason: s);
      }
      expect(parseBool('no'), isFalse);
      expect(parseBool('false'), isFalse);
      expect(parseBool(_ToStr(' On ')), isTrue);
      expect(parseBool(_ToStr('off')), isFalse);
    });

    test('parse*FromInlineList', () {
      expect(parseIntsFromInlineList(null), isNull);
      expect(parseIntsFromInlineList(null, ',', [1]), equals([1]));
      expect(parseIntsFromInlineList(5), equals([5]));
      expect(parseIntsFromInlineList(['1', null, 2]), equals([1, 2]));
      expect(parseIntsFromInlineList('1;2;3', ';'), equals([1, 2, 3]));

      expect(parseNumsFromInlineList(null), isNull);
      expect(parseNumsFromInlineList(2.5), equals([2.5]));
      expect(parseNumsFromInlineList(['1', 'x', 2.5]), equals([1, 2.5]));
      expect(parseNumsFromInlineList('1,2.5'), equals([1, 2.5]));

      expect(parseDoublesFromInlineList(null), isNull);
      expect(parseDoublesFromInlineList(1.5), equals([1.5]));
      expect(parseDoublesFromInlineList(['1.5', 'x', 2]), equals([1.5, 2.0]));
      expect(parseDoublesFromInlineList('1.5|2.5', '|'), equals([1.5, 2.5]));

      expect(parseBoolsFromInlineList(null, ','), isNull);
      expect(parseBoolsFromInlineList(null, ',', [true]), equals([true]));
      expect(parseBoolsFromInlineList(true, ','), equals([true]));
      expect(
        parseBoolsFromInlineList(['yes', 0, null], ','),
        equals([true, false]),
      );
      expect(parseBoolsFromInlineList('on,off', ','), equals([true, false]));
    });

    test('parseNumsFromList', () {
      expect(
        parseNumsFromList([
          const dart_math.Point(1, 2),
          ' 3 , 4 ',
          5,
          true,
          'x',
        ]),
        equals([1, 2, 3, 4, 5]),
      );
      expect(parseNumsFromList([]), equals([]));
    });

    test('parsePercent', () {
      expect(parsePercent(null), isNull);
      expect(parsePercent(double.nan), isNull);
      expect(parsePercent(double.infinity), isNull);
      expect(parsePercent(42), equals(42));
      expect(parsePercent(' 25 %'), equals(25));
      expect(parsePercent('12.5%'), equals(12.5));
      expect(parsePercent('0.5'), equals(50));
      expect(parsePercent('1'), equals(100));
      expect(parsePercent('0'), equals(0));
      expect(parsePercent('150'), equals(150));
      expect(parsePercent(DateTime.fromMillisecondsSinceEpoch(30)), equals(30));
      expect(() => parsePercent('abc'), throwsFormatException);

      // Regression: the `def` parameter was ignored (null was returned).
      expect(parsePercent(null, 5.0), equals(5.0));
      expect(parsePercent(double.nan, 5.0), equals(5.0));
      expect(parsePercent(double.infinity, 5.0), equals(5.0));
      expect(parsePercent('%', 5.0), equals(5.0));
      expect(parsePercent(' 25 %', 5.0), equals(25));
      expect(parsePercent(42, 5.0), equals(42));
    });
  });

  group('type checks', () {
    test('isInt/isNum/isDouble/isBool', () {
      expect(isInt(null), isFalse);
      expect(isInt(3), isTrue);
      expect(isInt(3.0), isTrue);
      expect(isInt(3.5), isFalse);
      expect(isInt('12'), isTrue);
      expect(isInt('1.2'), isFalse);

      expect(isNum(null), isFalse);
      expect(isNum(1.5), isTrue);
      expect(isNum('1.5'), isTrue);
      expect(isNum('x'), isFalse);

      expect(isDouble(null), isFalse);
      expect(isDouble(1.5), isTrue);
      expect(isDouble('1.5'), isTrue);
      expect(isDouble('2'), isFalse);
      expect(isDouble('x'), isFalse);

      expect(isBool(null), isFalse);
      expect(isBool(true), isTrue);
      expect(isBool('YES'), isTrue);
      expect(isBool('no'), isTrue);
      expect(isBool('maybe'), isFalse);
    });

    test('isIntList', () {
      expect(isIntList(null), isFalse);
      expect(isIntList(<int>[1, 2]), isTrue);
      expect(isIntList(<Object>[1, 2]), isTrue);
      expect(isIntList(<Object>{1, 2}), isTrue);
      expect(isIntList(<Object>[1, 'a']), isFalse);
      expect(isIntList('1,-2,3'), isTrue);
      expect(isIntList('1;2', ';'), isTrue);
      expect(isIntList('1'), isFalse);
      expect(isIntList('1,a'), isFalse);
    });

    test('isNumList', () {
      expect(isNumList(null), isFalse);
      expect(isNumList(<num>[1, 2.5]), isTrue);
      expect(isNumList(<int>[1, 2]), isTrue);
      expect(isNumList(<double>[1.5]), isTrue);
      expect(isNumList(<Object>[1, 2.5]), isTrue);
      expect(isNumList(<Object>[1, 'x']), isFalse);
      expect(isNumList('1,2.5,-3'), isTrue);
      expect(isNumList('1.5'), isFalse);
      expect(isNumList('1,x'), isFalse);
    });

    test('isDoubleList', () {
      expect(isDoubleList(null), isFalse);
      expect(isDoubleList(<double>[1.5]), isTrue);
      expect(isDoubleList(<Object>[1.5, 2.5]), isTrue);
      expect(isDoubleList(<Object>[1.5, 'x']), isFalse);
      expect(isDoubleList('1.5,-2.5'), isTrue);
      expect(isDoubleList('1,2'), isFalse);
    });

    test('isBoolList', () {
      expect(isBoolList(null), isFalse);
      expect(isBoolList(<bool>[true]), isTrue);
      expect(isBoolList(<Object>[true, false]), isTrue);
      expect(isBoolList(<Object>[true, 1]), isFalse);
      expect(isBoolList('true,NO,yes'), isTrue);
      expect(isBoolList('true'), isFalse);
      expect(isBoolList('true,maybe'), isFalse);
    });

    test('clipNumber/isPositiveNumber/isNegativeNumber', () {
      expect(clipNumber<int>(null, 0, 10), isNull);
      expect(clipNumber<int>(null, 0, 10, 5), equals(5));
      expect(clipNumber<int>(-3, 0, 10), equals(0));
      expect(clipNumber<int>(30, 0, 10), equals(10));
      expect(clipNumber<int>(3, 0, 10), equals(3));

      expect(isPositiveNumber(null), isFalse);
      expect(isPositiveNumber(1), isTrue);
      expect(isPositiveNumber(0), isFalse);
      expect(isNegativeNumber(null), isFalse);
      expect(isNegativeNumber(-0.5), isTrue);
      expect(isNegativeNumber(0), isFalse);
    });
  });

  group('Scale', () {
    test('basic num scale', () {
      var s = Scale<num>(1, 5);
      expect(s.minimum, equals(1));
      expect(s.maximum, equals(5));
      expect(s.length, equals(4));
      expect(s.minimumNice, equals(1));
      expect(s.maximumNice, equals(5));
      expect(s.toNum(3), equals(3));
      expect(s.toValue('3'), equals(3));
      expect(s.valuesType(), equals(int));

      expect(() => s.normalize(2), throwsUnimplementedError);
      expect(() => s.denormalize(0.5), throwsUnimplementedError);
      expect(() => s.clip(2), throwsUnimplementedError);
    });

    test('explicit length', () {
      var s = Scale<num>(1, 5, 10);
      expect(s.length, equals(10));
    });

    test('valuesType with mixed num types', () {
      expect(Scale<num>(1.5, 3).valuesType(), equals(double));
      expect(
        Scale<num>(1, 2.5).valuesType(),
        equals(_isJSNumbers ? int : double),
      );
    });

    test('toValue conversions', () {
      var si = Scale<int>(0, 10);
      expect(si.length, equals(10));
      expect(si.toValue('7'), equals(7));
      expect(si.toValue(4.5), equals(4));

      var sd = Scale<double>(0.5, 1.5);
      expect(sd.length, equals(1.0));
      expect(sd.toValue('2'), equals(2.0));
      expect(sd.toValue(2), equals(2.0));
    });

    test('DateTime scale', () {
      var d1 = DateTime.fromMillisecondsSinceEpoch(1000);
      var d2 = DateTime.fromMillisecondsSinceEpoch(5000);
      var s = Scale<DateTime>(d1, d2);
      expect(s.length.millisecondsSinceEpoch, equals(4000));
      expect(s.toNum(d2), equals(5000));
      expect(s.toValue(d1), same(d1));
      expect(s.toValue(250).millisecondsSinceEpoch, equals(250));
      expect(s.toValue('300').millisecondsSinceEpoch, equals(300));
    });

    test('non-computable scales', () {
      expect(() => Scale<String>('a', 'b'), throwsStateError);

      var s = Scale<String>('a', 'b', 'len');
      expect(s.length, equals('len'));
      expect(s.toNum('x'), isNull);
      expect(s.toNum('12'), equals(12));
      expect(() => s.toValue(5), throwsStateError);
      expect(s.toValue('z'), equals('z'));

      var so = Scale<Object>(1, 2);
      expect(so.length, equals(1));
      expect(() => so.toNum(_BadToString()), throwsStateError);
    });

    test('Scale.from', () {
      expect(Scale.from(null), isNull);
      expect(Scale.from([]), isNull);
      var s = Scale.from([5, 1, 3])!;
      expect(s.minimum, equals(1));
      expect(s.maximum, equals(5));
      expect(s.length, equals(4));
    });
  });

  group('ScaleNum', () {
    test('normalize/denormalize/clip', () {
      var s = ScaleNum<int>(0, 10);
      expect(s.length, equals(10));
      expect(s.normalize(5), equals(0.5));
      expect(s.normalize(10), equals(1.0));
      expect(s.denormalize(0.25), equals(2));
      expect(s.denormalize(1.0), equals(10));
      expect(s.clip(-1), equals(0));
      expect(s.clip(11), equals(10));
      expect(s.clip(5), equals(5));

      expect(s.normalizeList([0, 5, 10]), equals([0.0, 0.5, 1.0]));
      expect(s.denormalizeList([0.0, 0.5, 1.0]), equals([0, 5, 10]));
      expect(s.clipList([-5, 5, 15]), equals([0, 5, 10]));

      var sd = ScaleNum<num>(0.5, 10.5);
      expect(sd.length, equals(10));
      expect(sd.denormalize(0.25), equals(3.0));
      expect(sd.denormalize(0.3), closeTo(3.5, 1e-12));
    });

    test('ScaleNum.from', () {
      expect(ScaleNum.from<int>(null), isNull);
      expect(ScaleNum.from<int>([]), isNull);
      var s = ScaleNum.from<int>([4, -2, 9, 3])!;
      expect(s.minimum, equals(-2));
      expect(s.maximum, equals(9));
      expect(s.length, equals(11));
    });

    test('nice numbers', () {
      var s1 = ScaleNum<int>(0, 100);
      expect(s1.niceTolerance(), equals(5));
      expect(s1.minimumNice, equals(0));
      expect(s1.maximumNice, equals(100));

      var s2 = ScaleNum<int>(3, 203);
      expect(s2.niceTolerance(), equals(10));
      expect(s2.minimumNice, equals(-7));
      expect(s2.maximumNice, equals(213));

      var s3 = ScaleNum<int>(3, 13);
      expect(s3.niceTolerance(), equals(0));
      expect(s3.minimumNice, equals(3));
      expect(s3.maximumNice, equals(13));

      var s4 = ScaleNum<int>(-15, 1500);
      expect(s4.minimumNice, equals(-15));
      expect(s4.maximumNice, equals(1500));

      var s5 = ScaleNum<int>(7, 25000);
      expect(s5.niceTolerance(), equals(1249));
      expect(s5.minimumNice, equals(7 - 1249));
      expect(s5.maximumNice, equals(25000));

      var s6 = ScaleNum<int>(-1, 100003);
      expect(s6.niceTolerance(), equals(5000));
      expect(s6.minimumNice, equals(-1));
      expect(s6.maximumNice, equals(105003));

      var s7 = ScaleNum<int>(1, 2);
      expect(s7.minimumNice, equals(1));
      expect(s7.maximumNice, equals(2));
    });
  });

  group('Dimension.subtract', () {
    test('maximumDifferences', () {
      var d = Dimension(800, 600);
      var other = Dimension(700, 400);
      // dw = 100, dh = 200.
      // Regression: the doc says `maximumDifferences` = true returns the
      // maximum difference, but it returned the minimum one (and the default
      // returned the maximum).
      expect(d.subtract(other), equals(100));
      expect(d.subtract(other, false), equals(100));
      expect(d.subtract(other, true), equals(200));
    });
  });
}
