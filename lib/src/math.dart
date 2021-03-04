import 'dart:math' as dart_math;

import 'collections.dart';

/// Common mathematical functions and constants.
class Math {
  /// Base of the natural logarithms (Euler's number).
  static double get E => dart_math.e;

  /// Natural logarithm of 2.
  static double get LN2 => dart_math.ln2;

  /// Natural logarithm of 10.
  static double get LN10 => dart_math.ln10;

  /// Base-2 logarithm of [e].
  static double get Log2E => dart_math.log2e;

  /// Base-10 logarithm of [e].
  static double get Log10E => dart_math.log10e;

  /// The PI constant.
  static double get PI => dart_math.pi;

  /// Square root of 1/2.
  static double get Sqrt1_2 => dart_math.sqrt1_2;

  /// Square root of 2.
  static double get Sqrt2 => dart_math.sqrt2;

  /// Returns the lesser of two numbers.
  static T min<T extends num>(T a, T b) => dart_math.min(a, b);

  /// Returns the larger of two numbers.
  static T max<T extends num>(T a, T b) => dart_math.max(a, b);

  static double atan2(num a, num b) => dart_math.atan2(a, b);

  static num pow(num x, num exponent) => dart_math.pow(x, exponent);

  static double sin(num radians) => dart_math.sin(radians);

  static double cos(num radians) => dart_math.cos(radians);

  static double tan(num radians) => dart_math.tan(radians);

  static double acos(num x) => dart_math.acos(x);

  static double asin(num x) => dart_math.asin(x);

  static double atan(num x) => dart_math.atan(x);

  static double sqrt(num x) => dart_math.sqrt(x);

  static double exp(num x) => dart_math.exp(x);

  static double log(num x) => dart_math.log(x);

  /// Returns the Absolute value of [a].
  static T abs<T extends num>(num a) => a >= 0 ? a : -a;

  /// Returns the smallest (closest to negative infinity) value that is greater than or equal to the argument [a] and is equal to a mathematical integer.
  static num ceil(num a) {
    if (a is int) return a;

    if (a is double) {
      if (a.isNaN || a.isInfinite) return a;
    }

    var n = a.toInt();
    if (n == a) return n;
    return n + 1;
  }

  /// Returns the largest (closest to positive infinity) double value that is less than or equal to the argument [a] and is equal to a mathematical integer.
  static num floor(num a) {
    if (a is int) return a;

    if (a is double) {
      if (a.isNaN || a.isInfinite) return a;
    }

    var n = a.toInt();
    return n;
  }

  /// Returns the closest int to the argument [a], with ties rounding to positive infinity.
  static num round(num a) {
    if (a is int) return a;

    if (a is double) {
      if (a.isNaN || a.isInfinite) return a;
    }

    var n = a.toInt();
    if (a == n) return n;

    var diff = a - n;
    return (diff >= 0.5) ? n + 1 : n;
  }

  static final dart_math.Random _RANDOM = dart_math.Random();

  /// Global random generator.
  static double random() => _RANDOM.nextDouble();

  /// If [ns] has a NaN value.
  static bool hasNaN(Iterable<num> ns) {
    if (ns.isEmpty) return false;
    for (var n in ns) {
      if (n.isNaN) return true;
    }
    return false;
  }

  /// Sum value of [ns] entries.
  static double sum(Iterable<num> ns) {
    if (ns.isEmpty) return 0;
    var total = 0.0;
    for (var n in ns) {
      total += n;
    }
    return total;
  }

  /// Subtract in sequence [ns] entries.
  static double subtract(Iterable<num> ns) {
    if (ns.length <= 1) return 0;

    var total;
    for (var n in ns) {
      if (total == null) {
        total = n;
      } else {
        total -= n;
      }
    }

    return total;
  }

  /// Multiply in sequence [ns] entries.
  static double multiply(Iterable<num> ns) {
    if (ns.length <= 1) return 0;

    var total;
    for (var n in ns) {
      if (total == null) {
        total = n;
      } else {
        total *= n;
      }
    }

    return total;
  }

  /// Divide in sequence [ns] entries.
  static double divide(Iterable<num> ns) {
    if (ns.length <= 1) return 0;

    var total;
    for (var n in ns) {
      if (total == null) {
        total = n;
      } else {
        total /= n;
      }
    }

    return total;
  }

  /// Mean value of [ns] entries.
  static double mean(Iterable<num> ns) {
    if (ns.isEmpty) return 0;
    return sum(ns) / ns.length;
  }

  /// Standard deviation of [ns] entries.
  ///
  /// [mean] an already calculated mean for [ns].
  static double standardDeviation(Iterable<num> ns, [num mean]) {
    if (ns.length == 1) {
      return 0.0;
    } else {
      mean ??= Math.mean(ns);

      var sum = 0.0;

      for (var n in ns) {
        double v = (n - mean);
        v *= v;
        sum += v;
      }

      var variation = sum / (ns.length - 1);
      var deviation = Math.sqrt(variation);

      return deviation;
    }
  }

  /// A pair with minimum and maximum value of [ns] entries.
  ///
  /// [comparator] is optional and useful for non [num] [T].
  static Pair<T> minMax<T>(Iterable<T> ns, [Comparator<T> comparator]) {
    if (ns == null || ns.isEmpty) return null;

    if (comparator != null) {
      var min = ns.first;
      var max = min;

      for (var n in ns) {
        if (comparator(n, min) < 0) min = n;
        if (comparator(n, max) > 0) max = n;
      }

      return Pair<T>(min, max);
    } else {
      var min = ns.first as num;
      var max = min;

      for (var n in ns.map((e) => e as num)) {
        if (n < min) min = n;
        if (n > max) max = n;
      }

      return Pair<T>(min as T, max as T);
    }
  }

  /// Minimal value of [ns] entries.
  ///
  /// [comparator] is optional and useful for non [num] [T].
  static T minInList<T>(Iterable<T> ns, [Comparator<T> comparator]) {
    if (ns == null || ns.isEmpty) return null;

    if (comparator != null) {
      var min = ns.first;

      for (var n in ns) {
        if (comparator(n, min) < 0) min = n;
      }

      return min;
    } else {
      var min = ns.first as num;

      for (var n in ns.map((e) => e as num)) {
        if (n < min) min = n;
      }

      return min as T;
    }
  }

  /// Maximum value in [ns] entries.
  ///
  /// [comparator] is optional and useful for non [num] [T].
  static T maxInList<T>(Iterable<T> ns, [Comparator<T> comparator]) {
    if (ns == null || ns.isEmpty) return null;

    if (comparator != null) {
      var max = ns.first;

      for (var n in ns) {
        if (comparator(n, max) > 0) max = n;
      }

      return max;
    } else {
      var max = ns.first as num;

      for (var n in ns.map((e) => e as num)) {
        if (n > max) max = n;
      }

      return max as T;
    }
  }
}

/// Parses [v] to [int].
///
/// [def] The default value if [v] is invalid.
int parseInt(dynamic v, [int def]) {
  if (v == null) return def;

  if (v is int) return v;
  if (v is num) return v.toInt();

  if (v is DateTime) return v.millisecondsSinceEpoch;

  String s;
  if (v is String) {
    s = v;
  } else {
    s = v.toString();
  }

  s = s.trim();

  if (s.isEmpty) return def;

  num n = int.tryParse(s);

  if (n == null) {
    var d = double.tryParse(s);
    if (d != null) {
      return d.toInt();
    }
  }

  return n ?? def;
}

/// Parses [v] to [double].
///
/// [def] The default value if [v] is invalid.
double parseDouble(dynamic v, [double def]) {
  if (v == null) return def;

  if (v is double) return v;
  if (v is num) return v.toDouble();

  String s;
  if (v is String) {
    s = v;
  } else {
    s = v.toString();
  }

  s = s.trim();

  if (s.isEmpty) return def;

  var n = double.tryParse(s);
  return n ?? def;
}

/// Parses [v] to [num].
///
/// [def] The default value if [v] is invalid.
num parseNum(dynamic v, [num def]) {
  if (v == null) return def;

  if (v is num) return v;

  if (v is DateTime) return v.millisecondsSinceEpoch;

  String s;
  if (v is String) {
    s = v;
  } else {
    s = v.toString();
  }

  s = s.trim();

  if (s.isEmpty) return def;

  var n = num.tryParse(s);
  return n ?? def;
}

/// Parses [v] to [bool].
///
/// if [v] is [num]: true when [v > 0]
///
/// if [v] is [String]: true when [v == "true"|"yes"|"ok"|"1"|"y"|"s"|"t"|"+"
///
/// [def] The default value if [v] is invalid.
bool parseBool(dynamic v, [bool def]) {
  if (v == null) return def;

  if (v is bool) return v;

  if (v is num) return v > 0;

  String s;
  if (v is String) {
    s = v;
  } else {
    s = v.toString();
  }

  s = s.trim().toLowerCase();

  if (s.isEmpty) return def;

  return s == 'true' ||
      s == 'yes' ||
      s == 'ok' ||
      s == '1' ||
      s == 'y' ||
      s == 's' ||
      s == 't' ||
      s == '+';
}

/// Parses [s] to a [List<int>].
///
/// [delimiter] pattern for delimiter if [s] is a [String].
/// [def] the default value if [s] is invalid.
List<int> parseIntsFromInlineList(dynamic s,
    [Pattern delimiter = ',', List<int> def]) {
  if (s == null) return def;
  if (s is int) return [s];
  if (s is List) return s.map((e) => parseInt(e)).toList();
  return parseFromInlineList(s.toString(), delimiter, parseInt, def);
}

/// Parses [s] to a [List<num>].
///
/// [delimiter] pattern for delimiter if [s] is a [String].
/// [def] the default value if [s] is invalid.
List<num> parseNumsFromInlineList(dynamic s,
    [Pattern delimiter = ',', List<num> def]) {
  if (s == null) return def;
  if (s is num) return [s];
  if (s is List) return s.map((e) => parseNum(e)).toList();
  return parseFromInlineList(s.toString(), delimiter, parseNum, def);
}

/// Parses [s] to a [List<double>].
///
/// [delimiter] pattern for delimiter if [s] is a [String].
/// [def] the default value if [s] is invalid.
List<double> parseDoublesFromInlineList(dynamic s,
    [Pattern delimiter = ',', List<double> def]) {
  if (s == null) return def;
  if (s is double) return [s];
  if (s is List) return s.map((e) => parseDouble(e)).toList();
  return parseFromInlineList(s.toString(), delimiter, parseDouble, def);
}

/// Parses [s] to a [List<bool>].
///
/// [delimiter] pattern for delimiter if [s] is a [String].
/// [def] the default value if [s] is invalid.
List<bool> parseBoolsFromInlineList(dynamic s, Pattern delimiter,
    [List<bool> def]) {
  if (s == null) return def;
  if (s is bool) return [s];
  if (s is List) return s.map((e) => parseBool(e)).toList();
  return parseFromInlineList(s.toString(), delimiter, parseBool, def);
}

RegExp _REGEXP_SPLIT_COMMA = RegExp(r'\s*,\s*');

/// Parses a generic [list] to a [List<num>].
List<num> parseNumsFromList(List list) {
  return list
      .map((e) {
        if (e is dart_math.Point) {
          return [e.x, e.y];
        } else if (e is String) {
          var parts = e.trim().split(_REGEXP_SPLIT_COMMA);
          var nums = parts.map((e) => parseNum(e)).toList();
          return nums.whereType<num>().toList();
        } else if (e is num) {
          return [e];
        } else {
          return [null];
        }
      })
      .expand((e) => e)
      .toList();
}

/// Parses [v] as a percentage from 0..100.
///
/// [def] the default value if [v] is invalid.
num parsePercent(dynamic v, [double def]) {
  if (v == null) return null;

  if (v is num) {
    return v.isNaN || v.isInfinite ? null : v;
  }

  if (v is String) {
    var s = v.trim();
    if (s.endsWith('%')) {
      s = s.substring(0, s.length - 1).trim();
      return parseNum(s);
    } else {
      var n = num.parse(v);
      if (n >= 0 && n <= 1) {
        return n * 100;
      } else {
        return n;
      }
    }
  }

  return parseNum(v);
}

/// Formats [value] to a decimal value.
///
/// [precision] amount of decimal places.
/// [decimalSeparator] decimal separator, usually `.` or `,`.
String formatDecimal(dynamic value,
    [int precision = 2, String decimalSeparator = '.']) {
  if (value == null) return null;

  var p = parseNum(value);
  if (p == null || p == 0 || p.isNaN) return '0';

  if (p.isInfinite) return p.isNegative ? '-∞' : '∞';

  precision ??= 2;
  if (precision <= 0) return p.toInt().toString();

  var pStr = p.toString();

  var idx = pStr.indexOf('.');

  if (idx < 0) return p.toInt().toString();

  var integer = pStr.substring(0, idx);
  var decimal = pStr.substring(idx + 1);

  if (decimal.isEmpty || decimal == '0') {
    return integer.toString();
  }

  if (decimal.length > precision) {
    decimal = decimal.substring(0, precision);
  }

  if (decimalSeparator == null || decimalSeparator.isEmpty) {
    decimalSeparator = '.';
  }

  return '$integer$decimalSeparator$decimal';
}

/// Formats [percent] as a percentage string like: 0%, 90% or 100%.
///
/// [precision] amount of decimal places.
/// [isRatio] if true the [percent] parameter is in the range 0..1.
String formatPercent(dynamic percent, [int precision = 2, bool isRatio]) {
  if (percent == null) return '0%';

  var p = parseNum(percent);
  if (p == null || p == 0 || p.isNaN) return '0%';

  if (p.isInfinite) return p.isNegative ? '-∞%' : '∞%';

  isRatio ??= false;

  if (isRatio) {
    p = p * 100;
  }

  precision ??= 2;

  if (precision <= 0) return '${p.toInt()}%';

  var pStr = p.toString();

  var idx = pStr.indexOf('.');

  if (idx < 0) return '${p.toInt()}%';

  var integer = pStr.substring(0, idx);
  var decimal = pStr.substring(idx + 1);

  if (decimal.isEmpty || decimal == '0') {
    return '$integer%';
  }

  if (decimal.length > precision) {
    decimal = decimal.substring(0, precision);
  }

  return '$integer.$decimal%';
}

final RegExp _REGEXP_int = RegExp(r'^-?\d+$');

/// Returns true if [value] is [int]. Can be a int as string too.
bool isInt(dynamic value) {
  if (value == null) return false;
  if (value is int) return true;
  if (value is num) return value.toInt() == value;

  var s = value.toString();
  return _REGEXP_int.hasMatch(s);
}

/// Returns [true] if is a list of [int]. Can be a string of int too.
bool isIntList(dynamic value, [String delimiter = ',']) {
  if (value == null) return false;

  if (value is List<int>) return true;

  if (value is Iterable) {
    return listMatchesAll(value, (e) => e is int);
  }

  var s = value.toString();
  return RegExp(r'^-?\d+(?:' + delimiter + r'-?\d+)+$').hasMatch(s);
}

final RegExp _REGEXP_num = RegExp(r'^-?\d+(?:\.\d+)?$');

/// Returns true if [value] is [num]. Can be a num as string too.
bool isNum(dynamic value) {
  if (value == null) return false;
  if (value is num) return true;

  var s = value.toString();
  return _REGEXP_num.hasMatch(s);
}

/// Returns [true] if is a list of [num]. Can be a string of num too.
bool isNumList(dynamic value, [String delimiter = ',']) {
  if (value == null) return false;

  if (value is List<num>) return true;
  if (value is List<int>) return true;
  if (value is List<double>) return true;

  if (value is Iterable) {
    return listMatchesAll(value, (e) => e is num);
  }

  var s = value.toString();
  return RegExp(r'^-?\d+(?:\.\d+)?(?:' + delimiter + r'-?\d+(?:\.\d+)?)+$')
      .hasMatch(s);
}

final RegExp _REGEXP_double = RegExp(r'^(?:-?\d+\.\d+|-?\.\d+)$');

/// Returns true if [value] is [double]. Can be a double as string too.
bool isDouble(dynamic value) {
  if (value == null) return false;
  if (value is double) return true;
  if (value is num) return value.toDouble() == value;

  var s = value.toString();
  return _REGEXP_double.hasMatch(s);
}

/// Returns [true] if is a list of [double]. Can be a string of double too.
bool isDoubleList(dynamic value, [String delimiter = ',']) {
  if (value == null) return false;

  if (value is List<double>) return true;

  if (value is Iterable) {
    return listMatchesAll(value, (e) => e is double);
  }

  var s = value.toString();
  return RegExp(r'^-?\d+(?:\.\d+)(?:' + delimiter + r'-?\d+(?:\.\d+))+$')
      .hasMatch(s);
}

final RegExp _REGEXP_bool = RegExp(r'^(?:true|false|yes|no)$');

/// Returns true if [value] is [bool]. Can be a bool as string too.
bool isBool(dynamic value) {
  if (value == null) return false;
  if (value is bool) return true;

  var s = value.toString().toLowerCase();
  return _REGEXP_bool.hasMatch(s);
}

/// Returns [true] if is a list of [bool]. Can be a string of bool too.
bool isBoolList(dynamic value, [String delimiter = ',']) {
  if (value == null) return false;

  if (value is List<bool>) return true;

  if (value is Iterable) {
    return listMatchesAll(value, (e) => e is bool);
  }

  var s = value.toString().toLowerCase();
  return RegExp(r'^(?:true|false|yes|no)(?:' +
          delimiter +
          r'(?:true|false|yes|no))+$')
      .hasMatch(s);
}

/// Represents a scale with [minimum], [maximum] and [length].
class Scale<T> {
  /// The minimum value of the scale.
  final T minimum;

  /// The maximum value of the scale.
  final T maximum;

  T _length;

  /// The length of the scale: [maximum] - [minimum].
  T get length => _length;

  Scale(this.minimum, this.maximum, [T length]) {
    try {
      length ??= computeLength(maximum, minimum);
    }
    // ignore: empty_catches
    catch (ignore) {}

    _length = length;
  }

  factory Scale.from(Iterable<T> list) {
    if (list == null || list.isEmpty) return null;

    var sorted = list.toList();
    sorted.sort();
    return Scale(sorted[0], sorted[sorted.length - 1]);
  }

  Type valuesType() {
    var t = minimum.runtimeType;
    if (maximum.runtimeType != t) {
      if (minimum is num && maximum is num) {
        if (minimum is double) return minimum.runtimeType;
        if (maximum is double) return maximum.runtimeType;

        if (minimum is int) return minimum.runtimeType;
        if (maximum is int) return maximum.runtimeType;
      }
    }
    return t;
  }

  /// Converts a [value] to [num].
  num toNum(T value) {
    if (value == null) return null;

    if (value is num) {
      return value;
    } else {
      try {
        return parseNum(value);
      } catch (e) {
        throw StateError("Can't convert type to number: $value");
      }
    }
  }

  /// Converts a [value] to [T].
  T toValue(dynamic value) {
    if (value is T) {
      return value;
    } else if (T == num) {
      return parseNum(value) as T;
    } else if (T == int) {
      return parseInt(value) as T;
    } else if (T == double) {
      return parseDouble(value) as T;
    } else if (T == DateTime) {
      if (value is DateTime) return value as T;
      var ms = parseInt(value);
      return DateTime.fromMillisecondsSinceEpoch(ms) as T;
    } else {
      throw StateError("Can't convert type to $T: $value");
    }
  }

  /// Computes the length: [maximum] - [minimum].
  T computeLength(T maximum, T minimum) {
    var max = toNum(maximum);
    var min = toNum(minimum);
    var length = max - min;
    return toValue(length);
  }

  /// Normalizes a [value] to range 0..1.
  double normalize(T value) {
    throw UnimplementedError();
  }

  /// Denormalizes a [value] from range 0..1 to this scale.
  T denormalize(double value) {
    throw UnimplementedError();
  }

  /// Clips [value] in this scale.
  T clip(T value) {
    throw UnimplementedError();
  }

  /// Normalizes a list.
  List<double> normalizeList(Iterable<T> list) {
    return list.map(normalize).toList();
  }

  /// Denormalizes a list.
  List<T> denormalizeList(Iterable<double> list) {
    return list.map(denormalize).toList();
  }

  /// Clips a list.
  List<T> clipList(Iterable<T> list) {
    return list.map(clip).toList();
  }

  /// Same as [minimum] but as a nice number.
  T get minimumNice => minimum;

  /// Same as [maximum] but as a nice number.
  T get maximumNice => maximum;
}

/// Version of [Scale] but for [num] values.
class ScaleNum<N extends num> extends Scale<N> {
  ScaleNum(num minimum, num maximum) : super(minimum, maximum);

  factory ScaleNum.from(Iterable<N> list) {
    if (list == null || list.isEmpty) return null;

    num min = list.first;
    var max = min;

    for (var n in list) {
      if (n < min) {
        min = n;
      }

      if (n > max) {
        max = n;
      }
    }

    return ScaleNum(min, max);
  }

  @override
  N computeLength(N maximum, N minimum) {
    return maximum - minimum;
  }

  @override
  double normalize(num value) {
    var n = (value - minimum) / length;
    return n.toDouble();
  }

  @override
  N denormalize(double valueNormalized) {
    var n = (valueNormalized * length) + minimum;

    var t = valuesType();

    if (t == int) {
      return n.toInt() as N;
    } else if (t == double) {
      return n.toDouble() as N;
    } else {
      return n as N;
    }
  }

  @override
  N clip(N value) {
    if (value < minimum) return minimum;
    if (value > maximum) return maximum;
    return value;
  }

  bool _isNiceNum(num n) {
    if (n == 0 || n == 1 || n == -1) return true;

    if (n < 0) n = -n;

    for (var v = 0; v < 100; v += 5) {
      if (n == v) return true;
    }

    for (var v = 100; v < 1000; v += 10) {
      if (n == v) return true;
    }

    for (var v = 1000; v < 10000; v += 100) {
      if (n == v) return true;
    }

    for (var v = 10000; v < 100000; v += 1000) {
      if (n == v) return true;
    }

    return false;
  }

  int niceTolerance() => length ~/ 20;

  @override
  N get minimumNice {
    if (_isNiceNum(minimum)) return minimum;

    var tolerance = niceTolerance();
    if (tolerance == 0) return minimum;

    return minimum - tolerance;
  }

  @override
  N get maximumNice {
    if (_isNiceNum(maximum)) return maximum;

    var tolerance = niceTolerance();
    if (tolerance == 0) return maximum;

    return maximum + tolerance;
  }
}

/// Clips a number [n] into it's limits, [min] and [max].
///
/// [def] The default value if [n] is null.
N clipNumber<N extends num>(N n, N min, N max, [N def]) {
  n ??= def;
  if (n == null) return null;
  if (n < min) return min;
  if (n > max) return max;
  return n;
}

/// Returns [true] if [n > 0]. If [n] is null returns false.
bool isPositiveNumber(num n) => n != null && n > 0;

/// Returns [true] if [n < 0]. If [n] is null returns false.
bool isNegativeNumber(num n) => n != null && n < 0;
