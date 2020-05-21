
import 'dart:math' as dart_math ;

import 'collections.dart';

/// See dart:math
class Math {

  static double get E => dart_math.e ;

  static double get LN2 => dart_math.ln2 ;
  static double get LN10 => dart_math.ln10 ;

  static double get Log2E => dart_math.log2e ;
  static double get Log10E => dart_math.log10e ;
  static double get PI => dart_math.pi ;

  static double get Sqrt1_2 => dart_math.sqrt1_2 ;

  static double get Sqrt2 => dart_math.sqrt2 ;

  //////
  
  static T min<T extends num>(T a, T b) => dart_math.min(a, b) ;

  static T max<T extends num>(T a, T b) => dart_math.max(a, b) ;

  static double atan2(num a, num b) => dart_math.atan2(a,b) ;

  static num pow(num x, num exponent) => dart_math.pow(x, exponent) ;

  static double sin(num radians) => dart_math.sin(radians);

  static double cos(num radians) => dart_math.cos(radians);

  static double tan(num radians) => dart_math.tan(radians);

  static double acos(num x) => dart_math.acos(x);

  static double asin(num x) => dart_math.asin(x);

  static double atan(num x) => dart_math.atan(x);

  static double sqrt(num x) => dart_math.sqrt(x);

  static double exp(num x) => dart_math.exp(x);

  static double log(num x) => dart_math.log(x);

  static T abs<T extends num>(num a) => a >= 0 ? a : -a ;

  static num ceil(num a) {
    if (a is int) return a ;

    if (a is double) {
      if ( a.isNaN || a.isInfinite ) return a ;
    }

    var n = a.toInt() ;
    if (n == a) return n ;
    return n+1 ;
  }

  static num floor(num a) {
    if (a is int) return a ;

    if (a is double) {
      if ( a.isNaN || a.isInfinite ) return a ;
    }

    var n = a.toInt() ;
    return n ;
  }


  static num round(num a) {
    if (a is int) return a ;

    if (a is double) {
      if ( a.isNaN || a.isInfinite ) return a ;
    }

    var n = a.toInt() ;
    if ( a == n ) return n ;

    var diff = a-n ;
    return (diff >= 0.5)  ? n+1 : n ;
  }

  static final dart_math.Random _RANDOM = dart_math.Random() ;

  static double random() => _RANDOM.nextDouble();

  static bool hasNaN( List<num> ns ) {
    if (ns.isEmpty) return false ;
    for (var n in ns) {
      if ( n.isNaN ) return true ;
    }
    return false ;
  }

  static double mean( List<num> ns ) {
    var total = 0.0 ;
    for (var n in ns) {
      total += n ;
    }
    return total / ns.length ;
  }

  static double standardDeviation( List<num> ns, [num mean]) {
    if (ns.length == 1) {
      return 0.0 ;
    }
    else {
      mean ??= Math.mean(ns);

      var sum = 0.0 ;

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

  static Pair<T> minMax<T extends num>( List<T> ns ) {
    if (ns == null || ns.isEmpty) return null ;

    var min = ns[0] ;
    var max = min ;

    for ( var n in ns ) {
      if (n < min) min = n ;
      if (n > max) max = n ;
    }

    return Pair<T>(min, max) ;
  }

  static T minInList<T extends num>( List<T> ns ) {
    if (ns == null || ns.isEmpty) return null ;

    var min = ns[0] ;

    for ( var n in ns ) {
      if (n < min) min = n ;
    }

    return min ;
  }

  static T maxInList<T extends num>( List<T> ns ) {
    if (ns == null || ns.isEmpty) return null ;

    var max = ns[0] ;

    for ( var n in ns ) {
      if (n > max) max = n ;
    }

    return max ;
  }

}


int parseInt(dynamic v, [int def]) {
  if (v == null) return def ;

  if (v is int) return v ;
  if (v is num) return v.toInt() ;

  String s ;
  if (v is String) {
    s = v ;
  }
  else {
    s = v.toString() ;
  }

  s = s.trim() ;

  if (s.isEmpty) return def ;

  return num.parse(s).toInt() ;
}

double parseDouble(dynamic v, [double def]) {
  if (v == null) return def ;

  if (v is double) return v ;
  if (v is num) return v.toDouble();

  String s ;
  if (v is String) {
    s = v ;
  }
  else {
    s = v.toString() ;
  }

  s = s.trim() ;

  if (s.isEmpty) return def ;

  return double.parse(s) ;
}

num parseNum(dynamic v, [num def]) {
  if (v == null) return def ;

  if (v is num) return v ;

  String s ;
  if (v is String) {
    s = v ;
  }
  else {
    s = v.toString() ;
  }

  s = s.trim() ;

  if (s.isEmpty) return def ;

  return num.parse(s) ;
}

bool parseBool(dynamic v, [bool def]) {
  if (v == null) return def ;

  if (v is bool) return v ;

  String s ;
  if (v is String) {
    s = v ;
  }
  else {
    s = v.toString() ;
  }

  s = s.trim().toLowerCase() ;

  if (s.isEmpty) return def ;

  return s == 'true' || s == 'yes' || s == '1' || s == 'y' || s == 's' || s == 't' ;
}

List<int> parseIntsFromInlineList(dynamic s, [Pattern delimiter = ',', List<int> def]) {
  if (s == null) return def ;
  if (s is int) return [s];
  if (s is List) return s.map( (e) => parseInt(e) ).toList() ;
  return parseFromInlineList( s.toString() , delimiter , parseInt , def) ;
}

List<num> parseNumsFromInlineList(dynamic s, [Pattern delimiter = ',', List<num> def]) {
  if (s == null) return def ;
  if (s is num) return [s];
  if (s is List) return s.map( (e) => parseNum(e) ).toList() ;
  return parseFromInlineList( s.toString() , delimiter , parseNum , def) ;
}

List<double> parseDoublesFromInlineList(dynamic s, [Pattern delimiter = ',', List<double> def]) {
  if (s == null) return def ;
  if (s is double) return [s];
  if (s is List) return s.map( (e) => parseDouble(e) ).toList() ;
  return parseFromInlineList( s.toString() , delimiter , parseDouble , def) ;
}

List<bool> parseBoolsFromInlineList(dynamic s, Pattern delimiter, [List<bool> def]) {
  if (s == null) return def ;
  if (s is bool) return [s];
  if (s is List) return s.map( (e) => parseBool(e) ).toList() ;
  return parseFromInlineList( s.toString() , delimiter , parseBool , def) ;
}

RegExp _REGEXP_SPLIT_COMMA = RegExp(r'\s*,\s*');

List<num> parseNumsFromList(List list) {
  return list.map((e) {
    if (e is dart_math.Point) {
      return [ e.x, e.y ] ;
    }
    else if (e is String) {
      var parts = e.trim().split(_REGEXP_SPLIT_COMMA);
      var nums = parts.map( (e) => parseNum(e) ).toList() ;
      return nums.whereType<num>().toList() ;
    }
    else if ( e is num ) {
      return [e] ;
    }
    else {
      return [null] ;
    }
  }).expand( (e) => e ).toList() ;
}

num parsePercent(dynamic v, [double def]) {
  if (v == null) return null ;

  if (v is num) {
    return v.isNaN || v.isInfinite ? null : v ;
  }

  if (v is String)  {
    var s = v.trim() ;
    if (s.endsWith('%')) {
      s = s.substring(0,s.length-1).trim() ;
      return parseNum(s) ;
    }
    else {
      var n = num.parse(v) ;
      if ( n >= 0 && n <= 1 ) {
        return n * 100 ;
      }
      else {
        return n ;
      }
    }
  }

  return parseNum(v) ;
}

String formatDecimal(dynamic percent, [int precision = 2, String decimalSeparator = '.']) {
  if (percent == null) return null ;

  var p = parseNum(percent) ;
  if (p == null || p == 0 || p.isNaN) return '0' ;

  if (p.isInfinite) return p.isNegative ? '-∞' : '∞' ;

  precision ??= 2 ;
  if (precision <= 0) return p.toInt().toString() ;

  var pStr = p.toString() ;

  var idx = pStr.indexOf('.') ;

  if (idx < 0) return p.toInt().toString() ;

  var integer = pStr.substring(0,idx);
  var decimal = pStr.substring(idx+1);

  if ( decimal.isEmpty || decimal == '0' ) {
    return integer.toString() ;
  }

  if (decimal.length > precision) {
    decimal = decimal.substring(0,precision) ;
  }

  if (decimalSeparator == null || decimalSeparator.isEmpty) decimalSeparator = '.' ;

  return '$integer$decimalSeparator$decimal' ;
}

String formatPercent(dynamic percent, [int precision = 2, bool isRatio]) {
  if (percent == null) return '0%' ;

  var p = parseNum(percent) ;
  if (p == null || p == 0 || p.isNaN) return '0%' ;

  if (p.isInfinite) return p.isNegative ? '-∞%' : '∞%' ;

  isRatio ??= false ;

  if (isRatio) {
    p = p * 100 ;
  }

  precision ??= 2 ;

  if (precision <= 0) return '${p.toInt()}%' ;

  var pStr = p.toString() ;

  var idx = pStr.indexOf('.') ;

  if (idx < 0) return '${p.toInt()}%' ;

  var integer = pStr.substring(0,idx);
  var decimal = pStr.substring(idx+1);

  if ( decimal.isEmpty || decimal == '0' ) {
    return '$integer%' ;
  }

  if (decimal.length > precision) {
    decimal = decimal.substring(0,precision) ;
  }

  return '$integer.$decimal%' ;
}

///////////////////////////////////

final RegExp _REGEXP_int = RegExp(r'^-?\d+$') ;

bool isInt(dynamic value) {
  if (value == null) return false ;
  if (value is int) return true ;
  if (value is num) return value.toInt() == value ;

  var s = value.toString() ;
  return _REGEXP_int.hasMatch(s) ;
}

bool isIntList(dynamic value, [String delimiter = ',']) {
  if (value == null) return false ;
  var s = value.toString() ;
  return RegExp(r'^-?\d+(?:'+ delimiter+ r'-?\d+)+$').hasMatch(s) ;
}

final RegExp _REGEXP_num = RegExp(r'^-?\d+(?:\.\d+)?$') ;

bool isNum(dynamic value) {
  if (value == null) return false ;
  if (value is num) return true ;

  var s = value.toString() ;
  return _REGEXP_num.hasMatch(s) ;
}

bool isNumList(dynamic value, [String delimiter = ',']) {
  if (value == null) return false ;
  var s = value.toString() ;
  return RegExp(r'^-?\d+(?:\.\d+)?(?:'+ delimiter+ r'-?\d+(?:\.\d+)?)+$').hasMatch(s) ;
}

final RegExp _REGEXP_double = RegExp(r'^-?\d+\.\d+$') ;

bool isDouble(dynamic value) {
  if (value == null) return false ;
  if (value is double) return true ;
  if (value is num) return value.toDouble() == value ;

  var s = value.toString() ;
  return _REGEXP_double.hasMatch(s) ;
}

bool isDoubleList(dynamic value, [String delimiter = ',']) {
  if (value == null) return false ;
  var s = value.toString() ;
  return RegExp(r'^-?\d+(?:\.\d+)(?:'+ delimiter+ r'-?\d+(?:\.\d+))+$').hasMatch(s) ;
}

final RegExp _REGEXP_bool = RegExp(r'^(?:true|false|yes|no)$') ;

bool isBool(dynamic value) {
  if (value == null) return false ;
  if (value is bool) return true ;

  var s = value.toString().toLowerCase() ;
  return _REGEXP_bool.hasMatch(s) ;
}

bool isBoolList(dynamic value, [String delimiter = ',']) {
  if (value == null) return false ;
  var s = value.toString().toLowerCase() ;
  return RegExp(r'^(?:true|false|yes|no)(?:'+ delimiter+ r'(?:true|false|yes|no))+$').hasMatch(s) ;
}

///////////////////////////////////

