import 'dart:async';

import 'package:swiss_knife/src/collections.dart';

/// Calls a function with a [delayMs].
///
/// [delayMs] is milliseconds. If null or <= 0 won't have a delay.
Future callAsync(int delayMs, Function() function) {
  if (delayMs == null || delayMs <= 0) {
    return Future.microtask(function);
  }
  return Future.delayed(Duration(milliseconds: delayMs), function);
}

/// Encodes [parameters] as a query string.
String encodeQueryString(Map<String, String> parameters) {
  if (parameters == null || parameters.isEmpty) return '';

  var pairs = [];

  parameters.forEach((key, value) {
    var pair =
        Uri.encodeQueryComponent(key) + '=' + Uri.encodeQueryComponent(value);
    pairs.add(pair);
  });

  var queryString = pairs.join('&');
  return queryString;
}

/// Decodes [queryString] to a [Map<String,String>].
Map<String, String> decodeQueryString(String queryString) {
  if (queryString == null || queryString.isEmpty) return {};

  var pairs = queryString.split('&');

  var parameters = <String, String>{};

  for (var pair in pairs) {
    if (pair.isEmpty) continue;
    var kv = pair.split('=');

    var k = kv[0];
    var v = kv.length > 1 ? kv[1] : '';

    k = Uri.decodeQueryComponent(k);
    v = Uri.decodeQueryComponent(v);

    parameters[k] = v;
  }

  return parameters;
}

/// Formats [s] with initial character to Upper case.
String toUpperCaseInitials(String s) {
  if (s == null || s.isEmpty) return s;
  return s.toLowerCase().replaceAllMapped(
      RegExp(r'(\s|^)(\S)'), (m) => '${m[1]}${m[2].toUpperCase()}');
}

/// Formats [s] with camel case style.
String toCamelCase(String s) {
  return toUpperCaseInitials(s).replaceAll(RegExp(r'\s+'), '');
}

/// Splits [s] using [delimiter] and [limit].
///
/// [delimiter] [Pattern] to use to split [s].
/// [limit] The maximum elements to return.
///
/// Note: Standard Dart split doesn't have [limit] parameter.
List<String> split(String s, Pattern delimiter, [int limit]) {
  if (delimiter == null) {
    return [s];
  } else if (delimiter is String) {
    return _split(s, delimiter, limit);
  } else if (delimiter is RegExp) {
    return _split_RegExp(s, delimiter, limit);
  } else {
    throw ArgumentError('Invalid delimiter type: $delimiter');
  }
}

List<String> _split(String s, String delimiter, int limit) {
  if (limit == null) return s.split(delimiter);
  if (limit == 1) return [s];

  var delimiterSz = delimiter.length;

  if (limit == 2) {
    var idx = s.indexOf(delimiter);
    return idx >= 0
        ? [s.substring(0, idx), s.substring(idx + delimiterSz)]
        : [s];
  }

  if (limit <= 0) limit = s.length;

  var parts = <String>[];

  limit--;

  for (var i = 0; i < limit; i++) {
    var idx = s.indexOf(delimiter);

    if (idx >= 0) {
      var s1 = s.substring(0, idx);
      var s2 = s.substring(idx + delimiterSz);

      parts.add(s1);
      s = s2;
    } else {
      break;
    }
  }

  parts.add(s);
  return parts;
}

List<String> _split_RegExp(String s, RegExp delimiter, int limit) {
  if (limit == null) return s.split(delimiter);
  if (limit == 1) return [s];

  if (limit == 2) {
    var match = delimiter.firstMatch(s);
    if (match == null) return [s];

    var init = s.substring(0, match.start);
    var end = s.substring(match.end);
    return [init, end];
  }

  if (limit <= 0) limit = s.length;

  var parts = <String>[];

  limit--;

  for (var i = 0; i < limit; i++) {
    var match = delimiter.firstMatch(s);

    if (match != null) {
      var s1 = s.substring(0, match.start);
      var s2 = s.substring(match.end);

      parts.add(s1);
      s = s2;
    } else {
      break;
    }
  }

  parts.add(s);
  return parts;
}

class Parameter<A> {
  final A a;

  Parameter(this.a);

  Parameter<A> copy() => Parameter(deepCopy(a));

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Parameter && isEqualsDeep(a, other.a);

  int _hashCode;

  @override
  int get hashCode {
    _hashCode ??= computeHashCode;
    return _hashCode;
  }

  int get computeHashCode => deepHashCode(a);

  @override
  String toString() {
    return 'Parameter{a: $a}';
  }
}

class Parameters2<A, B> extends Parameter<A> {
  final B b;

  Parameters2(A a, this.b) : super(a);

  @override
  Parameters2<A, B> copy() => Parameters2(deepCopy(a), deepCopy(b));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Parameters2 && super == other && isEqualsDeep(b, other.b);

  @override
  int get computeHashCode => super.computeHashCode ^ deepHashCode(b);

  @override
  String toString() {
    return 'Parameters2{a: $a ; b: $b}';
  }
}

class Parameters3<A, B, C> extends Parameters2<A, B> {
  final C c;

  Parameters3(A a, B b, this.c) : super(a, b);

  @override
  Parameters3<A, B, C> copy() =>
      Parameters3(deepCopy(a), deepCopy(b), deepCopy(c));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Parameters3 && super == other && isEqualsDeep(c, other.c);

  @override
  int get computeHashCode => super.computeHashCode ^ deepHashCode(c);

  @override
  String toString() {
    return 'Parameters3{a: $a ; b: $b ; c: $c}';
  }
}

class Parameters4<A, B, C, D> extends Parameters3<A, B, C> {
  final D d;

  Parameters4(A a, B b, C c, this.d) : super(a, b, c);

  @override
  Parameters4<A, B, C, D> copy() =>
      Parameters4(deepCopy(a), deepCopy(b), deepCopy(c), deepCopy(d));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Parameters4 && super == other && isEqualsDeep(d, other.d);

  @override
  int get computeHashCode => super.computeHashCode ^ deepHashCode(d);

  @override
  String toString() {
    return 'Parameters4{a: $a ; b: $b ; c: $c ; d: $d}';
  }
}

/// Caches a value that can be computed.
class CachedComputation<R, T, K> {
  final R Function(T) function;

  final K Function(T) keyGenerator;

  CachedComputation(this.function, [K Function(T) keyGenerator])
      : keyGenerator = keyGenerator ?? ((T value) => deepCopy(value as K));

  final Map<K, R> _cache = {};

  int get cacheSize => _cache.length;

  /// Clears cache.
  void clear() {
    _cache.clear();
  }

  K generateKey(T value) => keyGenerator(value);

  int _computationCount = 0;

  int get computationCount => _computationCount;

  /// Computes and caches value.
  R compute(T value) {
    var key = generateKey(value);

    var prev = _cache[key];
    if (prev != null) return prev;

    ++_computationCount;
    var result = function(value);

    _cache[key] = result;
    return result;
  }
}
