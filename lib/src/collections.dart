import 'dart:collection';
import 'dart:math' as dart_math;

import 'date.dart';
import 'math.dart';
import 'utils.dart';
import 'weak_map.dart';

/// Represents a pair with [a] and [b] of type [T].
class Pair<T> {
  final T a;

  final T b;

  Pair(this.a, this.b);

  Pair.fromList(List<T> list)
      : this(list[0], list.length > 1 ? list[1] : list[0]);

  Pair<T> swapAB() {
    return Pair(b, a);
  }

  /// Returns a [Point] with [a] as [dart_math.Point.x] and [b] as [dart_math.Point.y].
  dart_math.Point<num> get asPoint =>
      dart_math.Point<num>(parseNum(a)!, parseNum(b)!);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Pair &&
          runtimeType == other.runtimeType &&
          a == other.a &&
          b == other.b;

  @override
  int get hashCode => a.hashCode ^ b.hashCode;

  /// Returns [true] if [a] not null.
  bool get aNotNull => a != null;

  /// Returns [true] if [b] not null.
  bool get bNotNull => b != null;

  /// Returns [a] as [String].
  String get aAsString => aNotNull ? a.toString() : '';

  /// Returns [b] as [String].
  String get bAsString => bNotNull ? b.toString() : '';

  @override
  String toString() {
    return '[$a, $b]';
  }

  /// Joins [a] and [b] with the [delimiter].
  String join([String delimiter = '']) {
    return '$a$delimiter$b';
  }

  /// Returns as a [MapEntry].
  MapEntry<T, T> get asMapEntry => MapEntry(a, b);

  /// Returns as a List with [a,b].
  List<T> get asList => [a, b];
}

/// Represents a [width] X [height] dimension.
class Dimension implements Comparable<Dimension> {
  /// Extra parsers.
  static Set<Dimension? Function(Object? value)> parsers = {};

  /// Width of the dimension.
  final int width;

  /// Height of the dimension.
  final int height;

  Dimension(this.width, this.height);

  static Dimension? from(Object? dimension) {
    if (dimension == null) return null;
    if (dimension is Dimension) return dimension;
    if (dimension is Pair) {
      var a = parseInt(dimension.a);
      var b = parseInt(dimension.b);
      return a != null && b != null ? Dimension(a, b) : null;
    }

    if (dimension is String) return Dimension.parse(dimension);

    if (dimension is List) {
      if (dimension.length == 2) {
        var w = parseInt(dimension[0]);
        var h = parseInt(dimension[1]);
        return w != null && h != null ? Dimension(w, h) : null;
      } else if (dimension.length == 1) {
        var s = parseString(dimension[0]);
        return Dimension.parse(s);
      }
    }

    if (parsers.isNotEmpty) {
      for (var p in parsers) {
        var o = p(dimension);
        if (o != null) return o;
      }
    }

    return null;
  }

  static final RegExp _regexpNonDigit =
      RegExp(r'\D', multiLine: false, caseSensitive: true);

  /// Parsers [wh] String, trying to split with [delimiter] between 2 numbers
  /// in the string.
  static Dimension? parse(String? wh, [Pattern? delimiter]) {
    if (wh == null) return null;
    delimiter ??= RegExp(r'[\sx,;]+');
    wh = wh.trim();
    if (wh.isEmpty) return null;

    var parts = wh.split(delimiter);
    if (parts.length < 2) return null;

    var params = <String>[];

    for (var i = 1; i < parts.length; ++i) {
      var prev = parts[i - 1].trim();
      var next = parts[i].trim();

      var prevC = prev.isNotEmpty ? prev[prev.length - 1] : '';
      var nextC = next.isNotEmpty ? next[0] : '';

      var prevInt = prevC.isNotEmpty || isInt(prevC);
      var nextInt = nextC.isNotEmpty || isInt(nextC);

      if (prevInt && nextInt) {
        var idxPrev = prev.lastIndexOf(_regexpNonDigit);
        if (idxPrev >= 0) prev = prev.substring(idxPrev + 1);

        var idxNext = next.indexOf(_regexpNonDigit);
        if (idxNext >= 0) next = next.substring(0, idxNext);

        params.add(prev);
        params.add(next);
      }
    }

    if (params.length < 2) return null;

    var pW = params[params.length - 2];
    var pH = params[params.length - 1];

    var w = parseInt(pW);
    var h = parseInt(pH);

    return w != null && h != null ? Dimension(w, h) : null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Dimension && width == other.width && height == other.height;

  @override
  int get hashCode => width.hashCode ^ height.hashCode;

  /// Area of the dimension.
  int get area => width * height;

  /// Returns the difference between `this` and [other], using [width] and [height].
  ///
  /// [maximumDifferences] If true will return the maximum difference,
  /// instead of the minimum difference.
  int subtract(Dimension other, [bool maximumDifferences = false]) {
    var dw = width - other.width;
    var dh = height - other.height;
    var d = maximumDifferences ? Math.min(dw, dh) : Math.max(dw, dh);
    return d;
  }

  /// Compares with [other] [Dimension.area].
  @override
  int compareTo(Dimension other) => area.compareTo(other.area);

  @override
  String toString() {
    return '${width}X$height';
  }
}

/// Returns [true] if [o1] and [o2] are equals.
///
/// [deep] If [true] checks the collections deeply.
bool isEquals(Object? o1, Object? o2, [bool deep = false]) {
  if (deep) {
    return isEqualsDeep(o1, o2);
  } else {
    return o1 == o2;
  }
}

/// Returns [true] if [o1] and [o2] are equals deeply.
bool isEqualsDeep(Object? o1, Object? o2) {
  if (identical(o1, o2)) return true;

  if (o1 is List) {
    if (o2 is List) {
      return isEquivalentList(o1, o2, deep: true);
    }
    return false;
  } else if (o1 is Map) {
    if (o2 is Map) {
      return isEquivalentMap(o1, o2, deep: true);
    }
    return false;
  }

  return o1 == o2;
}

/// Returns [true] if [o1] and [o2] are equals as [String].
/// Uses [String.toString] to check.
bool isEqualsAsString(Object? o1, Object? o2) {
  if (identical(o1, o2)) return true;
  if (o1 == o2) return true;
  if (o1 == null || o2 == null) return false;
  var s1 = o1.toString();
  var s2 = o2.toString();
  return s1 == s2;
}

/// Returns [true] if [l1] and [l2] are equals, including the same position
/// for the elements.
///
/// [sort] If [true] sorts [l1] and [l2] before check.
/// [deep] If [true] checks deeply collections elements.
bool isEquivalentList(List? l1, List? l2,
    {bool sort = false, bool deep = false}) {
  if (l1 == l2) return true;

  if (l1 == null) return false;
  if (l2 == null) return false;

  var length = l1.length;
  if (length != l2.length) return false;

  if (sort) {
    l1.sort();
    l2.sort();
  }

  for (var i = 0; i < length; ++i) {
    var v1 = l1[i];
    var v2 = l2[i];

    if (!isEquals(v1, v2, deep)) return false;
  }

  return true;
}

/// Same as [isEquivalentList] but for [Iterable].
bool isEquivalentIterator(Iterable? it1, Iterable? it2, {bool deep = false}) {
  if (it1 == it2) return true;

  if (it1 == null) return false;
  if (it2 == null) return false;

  var length = it1.length;
  if (length != it2.length) return false;

  for (var i = 0; i < length; i++) {
    var v1 = it1.elementAt(i);
    var v2 = it2.elementAt(i);

    if (!isEquals(v1, v2, deep)) return false;
  }

  return true;
}

/// Returns [true] if [m1] and [m2] are equals.
///
/// [deep] IF [true] checks deeply collections values.
bool isEquivalentMap(Map? m1, Map? m2, {bool deep = false}) {
  if (m1 == m2) return true;

  if (m1 == null) return false;
  if (m2 == null) return false;

  if (m1.length != m2.length) return false;

  var k1 = List.from(m1.keys);
  var k2 = List.from(m2.keys);

  if (!isEquivalentList(k1, k2, sort: true)) return false;

  for (var k in k1) {
    var v1 = m1[k];
    var v2 = m2[k];

    if (!isEquals(v1, v2, deep)) return false;
  }

  return true;
}

/// Returns [true] if both lists, [l1] and [l2],
/// have equals entries in the same order.
bool isEqualsList<T>(List<T>? l1, List<T>? l2) {
  if (identical(l1, l2)) return true;
  if (l1 == null) return false;
  if (l2 == null) return false;

  var length = l1.length;
  if (length != l2.length) return false;

  for (var i = 0; i < length; ++i) {
    var v1 = l1[i];
    var v2 = l2[i];

    if (v1 != v2) return false;
  }

  return true;
}

/// Returns [true] if both sets, [s1] and [s2],
/// have equals entries in the same order.
bool isEqualsSet<T>(Set<T>? s1, Set<T>? s2) {
  if (identical(s1, s2)) return true;
  if (s1 == null) return false;
  if (s2 == null) return false;

  var length = s1.length;
  if (length != s2.length) return false;

  var itr1 = s1.iterator;
  var itr2 = s2.iterator;

  while (itr1.moveNext()) {
    if (!itr2.moveNext()) {
      return false;
    }

    var v1 = itr1.current;
    var v2 = itr2.current;

    if (v1 != v2) return false;
  }

  return true;
}

/// Returns [true] if both iterable, [i1] and [i2],
/// have equals entries in the same order.
bool isEqualsIterable<T>(Iterable<T>? i1, Iterable<T>? i2) {
  if (identical(i1, i2)) return true;
  if (i1 == null) return false;
  if (i2 == null) return false;

  var length = i1.length;
  if (length != i2.length) return false;

  var itr1 = i1.iterator;
  var itr2 = i2.iterator;

  while (itr1.moveNext()) {
    if (!itr2.moveNext()) {
      return false;
    }

    var v1 = itr1.current;
    var v2 = itr2.current;

    if (v1 != v2) return false;
  }

  return true;
}

/// Returns [true] if both maps, [m1] and [m2],
/// have equals entries in the same order.
bool isEqualsMap<K, V>(Map<K, V>? m1, Map<K, V>? m2) {
  if (identical(m1, m2)) return true;
  if (m1 == null) return false;
  if (m2 == null) return false;

  var length = m1.length;
  if (length != m2.length) return false;

  var entries1 = m1.entries;
  var entries2 = m2.entries;

  for (var i = 0; i < length; ++i) {
    var e1 = entries1.elementAt(i);
    var e2 = entries2.elementAt(i);

    if (e1 == e2) continue;

    if (e1.key != e2.key) return false;
    if (e1.value != e2.value) return false;
  }

  return true;
}

/// Returns [true] [element] is equals to [value].
///
/// If [element] is a [List] checks if all entries in the list are equals to
/// [value].
///
/// If [element] is a [Map] checks if all [Map.values] are equals to
/// [value].
///
/// [deep] IF [true] checks deeply collections values.
bool isAllEquals(Object? element, Object? value, [bool deep = false]) {
  if (isEquals(element, value, deep)) {
    return true;
  }

  if (element is List) {
    return isAllEqualsInList(element, value!, deep);
  } else if (element is Map) {
    return isAllEqualsInMap(element, value!, deep);
  }

  return false;
}

/// Returns [true] if [list] elements are all equals to [value].
///
/// [deep] IF [true] checks deeply collections values.
bool isAllEqualsInList(List? list, Object value, [bool deep = false]) {
  if (list == null || list.isEmpty) return false;

  for (var e in list) {
    if (!isEquals(e, value, deep)) {
      return false;
    }
  }

  return true;
}

/// Returns [true] if [map] values are all equals to [value].
///
/// [deep] IF [true] checks deeply collections values.
bool isAllEqualsInMap(Map? map, Object value, [bool deep = false]) {
  if (map == null || map.isEmpty) return false;

  for (var e in map.values) {
    if (!isEquals(e, value, deep)) {
      return false;
    }
  }

  return true;
}

/// Returns [true] if at least ONE [list] element does NOT matches [matcher].
bool listNotMatchesAll<T>(Iterable<T>? list, bool Function(T entry) matcher) {
  if (list == null || list.isEmpty) return false;
  for (var e in list) {
    if (!matcher(e)) return true;
  }
  return false;
}

/// Returns [true] if all [list] elements matches [matcher].
bool listMatchesAll<T>(Iterable<T>? list, bool Function(T entry) matcher) {
  if (list == null || list.isEmpty) return false;
  for (var e in list) {
    if (!matcher(e)) return false;
  }
  return true;
}

/// Returns [true] if any element of [list] matches [matcher].
bool listMatchesAny<T>(Iterable<T>? list, bool Function(T entry) matcher) {
  if (list == null || list.isEmpty) return false;
  for (var e in list) {
    if (matcher(e)) return true;
  }
  return false;
}

/// Returns [true] if all [list] elements are of the same type.
bool isListEntriesAllOfSameType(Iterable? list) {
  if (list == null || list.isEmpty) return false;
  if (list.length == 1) return true;
  var t = list.first.runtimeType;
  return listMatchesAll(list, (e) => e != null && e.runtimeType == t);
}

/// Returns [true] if all [list] elements are of [type].
bool isListEntriesAllOfType(Iterable? list, Type type) {
  if (list == null || list.isEmpty) return false;
  return listMatchesAll(list, (e) => e != null && e.runtimeType == type);
}

/// Returns [true] if all [list] elements are [identical].
bool isListValuesIdentical(List? l1, List? l2) {
  if (l1 == null || l2 == null) return false;
  if (identical(l1, l2)) return true;

  var length = l1.length;
  if (length != l2.length) return false;

  if (length == 0) return true;

  for (var i = 0; i < length; ++i) {
    var v1 = l1[i];
    var v2 = l2[i];

    if (!identical(v1, v2)) return false;
  }

  return true;
}

/// Adds all [values] to [list].
void addAllToList(List list, Object? values) {
  if (values == null) return;

  if (values is List) {
    list.addAll(values);
  } else {
    list.add(values);
  }
}

/// Joins all parameters to a single list.
List joinLists(List? l1,
    [List? l2,
    List? l3,
    List? l4,
    List? l5,
    List? l6,
    List? l7,
    List? l8,
    List? l9]) {
  var l = [];

  if (l1 != null) l.addAll(l1);
  if (l2 != null) l.addAll(l2);
  if (l3 != null) l.addAll(l3);
  if (l4 != null) l.addAll(l4);
  if (l5 != null) l.addAll(l5);
  if (l6 != null) l.addAll(l6);
  if (l7 != null) l.addAll(l7);
  if (l8 != null) l.addAll(l8);
  if (l9 != null) l.addAll(l9);

  return l;
}

/// Copies [list].
List? copyList(List? list) {
  if (list == null) return null;
  return List.from(list);
}

/// Copies [list] as a [List<String>].
List<String>? copyListString(List<String>? list) {
  if (list == null) return null;
  return List<String>.from(list);
}

/// Copies [map].
Map? copyMap(Map? map) {
  if (map == null) return null;
  return Map.from(map);
}

/// Copies [map] as a [Map<String,String>].
Map<String, String>? copyMapString(Map<String, String>? m) {
  if (m == null) return null;
  return Map<String, String>.from(m);
}

/// Gets a [map] entry ignoring key case.
MapEntry<String, V?>? getEntryIgnoreCase<V>(Map<String, V?> map, String? key) {
  if (key == null) return null;
  var val = map[key];
  if (val != null) return MapEntry(key, val);

  var keyLC = key.toLowerCase();

  for (var k in map.keys) {
    if (k.toLowerCase() == keyLC) {
      var value = map[k];
      return MapEntry<String, V?>(k, value);
    }
  }

  return null;
}

/// Gets a [map] value ignoring [key] case.
V? getIgnoreCase<V>(Map<String, V> map, String? key) {
  var entry = getEntryIgnoreCase(map, key);
  return entry?.value;
}

/// Puts a [map] value ignoring [key] case.
V? putIgnoreCase<V>(Map<String, V> map, String key, V value) {
  var entry = getEntryIgnoreCase(map, key);
  if (entry != null) {
    map[entry.key] = value;
    return entry.value;
  } else {
    map[key] = value;
    return null;
  }
}

/// Returns [o] as [Map]. Converts it if needed.
Map? asMap(Object? o) {
  if (o == null) return null;
  if (o is Map) return o;

  var m = {};

  if (o is List) {
    var sz = o.length;

    for (var i = 0; i < sz; i += 2) {
      Object key = o[i];
      Object? val = o[i + 1];
      m[key] = val;
    }
  } else {
    throw StateError("Can't handle type: $o");
  }

  return m;
}

/// Returns [o] as a [List<Map>]. Converts it if needed.
List<Map>? asListOfMap(Object? o) {
  if (o == null) return null;
  if (o is List<Map>) return o;
  if (o is List) {
    return o.map((e) => asMap(e)).whereType<Map>().toList();
  } else if (o is Map) {
    return [o];
  }

  var s = o.toString();
  var map = parseFromInlineMap(
      s, _inlinePropertiesDelimiterPairs, _inlinePropertiesDelimiterKeysValues);
  return [map!];
}

typedef CompareMapEntryFunction<K, V> = int Function(
    MapEntry<K, V> entry1, MapEntry<K, V> entry2);

/// Returns a Map sorted by keys.
Map<K, V?> sortMapEntriesByKey<K, V>(Map<K, V?> map, [bool reversed = false]) =>
    sortMapEntries(
        map, (a, b) => parseComparable(a.key)!.compareTo(b.key), reversed);

/// Returns a Map sorted by keys.
Map<K, V> sortMapEntriesByValue<K, V>(Map<K, V> map, [bool reversed = false]) =>
    sortMapEntries(
        map, (a, b) => parseComparable(a.value)!.compareTo(b.value), reversed);

/// Returns a Map with sorted entries.
Map<K, V> sortMapEntries<K, V>(Map<K, V> map,
    [CompareMapEntryFunction<K, V>? compare, bool reversed = false]) {
  compare ??= (a, b) => parseComparable(a.key)!.compareTo(b.key);

  if (reversed) {
    var compareOriginal = compare;
    compare = (a, b) => compareOriginal(b, a);
  }

  var mapSorted =
      LinkedHashMap<K, V>.fromEntries(map.entries.toList()..sort(compare));

  return mapSorted;
}

/// Returns [true] if [list] values are of type [String].
bool isListOfStrings(Iterable? list) {
  if (list == null || list.isEmpty) return false;

  for (var value in list) {
    if (value is! String) return false;
  }

  return true;
}

/// Returns [o] as a [List<String>]. Converts it if needed.
List<String>? asListOfString(Object? o) {
  if (o == null) return null;
  var l = o as List<Object?>;
  return l.map((e) => e != null ? e.toString() : '').toList();
}

/// Returns [o] as a [Map<String,String>]. Converts it if needed.
Map<String, String>? asMapOfString(Object? o) {
  if (o == null) return null;
  var m = o as Map;
  return m.map((k, v) => MapEntry('$k', '$v'));
}

/// Maps [tree]:
/// - If [tree] is a [Map] to a [Map<String,dynamic].
/// - If [tree] is a [List] to a [List<Map<String,dynamic>].
dynamic asTreeOfKeyString(Object? tree) {
  if (tree == null) return null;

  if (tree is Map) {
    return Map<String, dynamic>.fromEntries(tree.entries.map((e) {
      return MapEntry<String, dynamic>('${e.key}', asTreeOfKeyString(e.value));
    }));
  } else if (tree is List) {
    return tree.map(asTreeOfKeyString).toList();
  } else {
    return tree;
  }
}

final RegExp _toListOfStringsDelimiter = RegExp(r'\s+');

/// Converts [s] to a [List<String>].
/// Converts any collection to a flat list of strings.
List<String> toFlatListOfStrings(Object? s,
    {Pattern? delimiter, bool trim = true, bool ignoreEmpty = true}) {
  if (s == null) {
    return <String>[];
  } else if (s is String) {
    return _toFlatListOfStringsFromString(
        s, delimiter ?? _toListOfStringsDelimiter, trim, ignoreEmpty);
  } else if (s is Iterable) {
    return _toFlatListOfStringsFromIterable(
        s, delimiter ?? _toListOfStringsDelimiter, trim, ignoreEmpty);
  } else {
    return _toFlatListOfStringsFromString(
        '$s', delimiter ?? _toListOfStringsDelimiter, trim, ignoreEmpty);
  }
}

List<String> _toFlatListOfStringsFromString(
    String s, Pattern delimiter, bool trim, bool ignoreEmpty) {
  var list = s.split(delimiter);

  if (trim) {
    trimListOfStrings(list);
  }

  if (ignoreEmpty) {
    list.removeWhere((e) => e.isEmpty);
  }

  return list;
}

List<String> _toFlatListOfStringsFromIterable(
    Iterable s, Pattern delimiter, bool trim, bool ignoreEmpty) {
  var list = <String>[];

  for (var e in s) {
    if (e == null) continue;

    if (e is String) {
      var l2 = _toFlatListOfStringsFromString(e, delimiter, trim, ignoreEmpty);
      list.addAll(l2);
    } else if (e is Iterable) {
      var l2 =
          _toFlatListOfStringsFromIterable(e, delimiter, trim, ignoreEmpty);
      list.addAll(l2);
    } else {
      var l2 =
          _toFlatListOfStringsFromString('$e', delimiter, trim, ignoreEmpty);
      list.addAll(l2);
    }
  }

  if (list.isEmpty) return list;

  if (trim) {
    trimListOfStrings(list);
  }

  if (ignoreEmpty) {
    list.removeWhere((e) => e.isEmpty);
  }

  return list;
}

/// Apply [String.trim] to each [String] of [list].
/// Returns the same [list] instance without change it's length.
List<String> trimListOfStrings(List<String> list) {
  final length = list.length;
  for (var i = 0; i < length; ++i) {
    var e = list[i];
    var e2 = e.trim();
    if (e2.length != e.length) {
      list[i] = e2;
    }
  }
  return list;
}

/// Returns [true] if [list] elements are all of type [String].
bool isListOfString(Iterable? list) {
  if (list == null) return false;
  if (list is List<String>) return true;
  if (list.isEmpty) return false;

  if (listNotMatchesAll(list, (e) => (e is String))) return false;

  return true;
}

/// Returns [true] if [list] elements are all of type [num].
bool isListOfNum(Iterable? list) {
  if (list == null) return false;
  if (list is List<num>) return true;
  if (list.isEmpty) return false;

  if (listNotMatchesAll(list, (e) => (e is num))) return false;

  return true;
}

typedef TypeTester<T> = bool Function(T value);

/// Returns [true] if [list] elements are all of type [T].
bool isListOfType<T>(Iterable? list) {
  if (list == null) return false;
  if (list is List<T>) return true;
  if (list.isEmpty) return false;

  if (listNotMatchesAll(list, (e) => (e is T))) return false;

  return true;
}

/// Returns [true] if [list] elements are all of type [A] or [B].
bool isListOfTypes<A, B>(Iterable? list) {
  if (list == null) return false;
  if (list is List<A>) return true;
  if (list is List<B>) return true;
  if (list.isEmpty) return false;

  if (listNotMatchesAll(list, (e) => (e is A) || (e is B))) {
    return false;
  }

  return true;
}

/// Returns [true] if [list] contains elements of type [T].
bool listContainsType<T>(Iterable? list) {
  if (list == null) return false;
  if (list is List<T>) return true;
  if (list.isEmpty) return false;

  var found = list.firstWhere((l) => l is T, orElse: () => null);

  return found != null;
}

/// Returns [true] if [list] contains all elements of type [entry].
bool listContainsAll(Iterable? list, Iterable? entries) {
  if (entries == null || entries.isEmpty) return false;
  if (list == null || list.isEmpty) return false;
  for (var entry in entries) {
    if (!list.contains(entry)) return false;
  }
  return true;
}

/// Returns [true] if [list] elements are all of type [List].
bool isListOfList(Object? list) {
  if (list == null || list is! List) return false;

  if (list is List<List>) return true;
  if (list.isEmpty) return false;

  if (listNotMatchesAll(list, (e) => (e is List))) return false;

  return true;
}

/// Returns [true] if [list] elements are all of type [List<List>].
bool isListOfListOfList(Object? list) {
  if (list == null || list is! List) return false;

  if (list is List<List<List>>) return true;
  if (list.isEmpty) return false;

  if (listNotMatchesAll(list, (e) => isListOfList(e))) return false;

  return true;
}

/// Returns [true] if [list] elements are all of type [Map].
bool isListOfMap(Object? list) {
  if (list == null || list is! List) return false;

  if (list is List<Map>) return true;
  if (list.isEmpty) return false;

  if (listNotMatchesAll(list, (e) => (e is Map))) return false;

  return true;
}

/// Returns [true] if [list] elements are all equals to [value].
bool isListValuesAllEquals(Object? list, [Object? eqValue]) {
  if (list == null || list is! List) return false;
  if (list.isEmpty) return false;

  eqValue ??= list.first;

  return listMatchesAll(list, (v) => v == eqValue);
}

/// Returns [true] if [list] elements are all equals to value
/// at index [valueIndex].
bool isListOfListValuesAllEquals(Iterable<List>? list,
    {Object? eqValue, int? eqValueIndex}) {
  if (list == null) return false;

  if (list.isEmpty) return false;

  eqValue ??= eqValueIndex != null
      ? list.first[eqValueIndex]
      : list.firstWhere((e) => e.isNotEmpty).first;

  if (eqValueIndex != null) {
    return listMatchesAll(list, (v) => v[eqValueIndex] == eqValue);
  } else {
    return listMatchesAll(list, (v) => v == eqValue);
  }
}

typedef ParserFunction<T, R> = R Function(T value);

/// Parses [s] to a [List<R>], where [R] is the result of [parse].
///
/// [def] The default value if [s] is invalid.
List<R>? parseListOf<T, R>(Object? s, ParserFunction<T, R> parser,
    [List<R>? def]) {
  if (s == null) return def;
  if (s is List) return s.map((e) => parser(e)).toList();
  return [parser(s as T)];
}

/// Parses [s] to a [List<List<R>>], where [R] is the result of [parse].
///
/// [def] The default value if [s] is invalid.
List<List<R>>? parseListOfList<T, R>(Object? s, ParserFunction<T, R> parser,
    [List<List<R>>? def]) {
  if (s == null) return def;
  if (s is List) {
    return s
        .map((e) => parseListOf(e, parser))
        .where((e) => e != null)
        .cast<List<R>>()
        .toList();
  }
  var elem = parseListOf(s, parser);
  return elem != null ? [elem] : null;
}

/// Returns [true] if [map] is [Map<String,String>].
bool isMapOfString(Map? map) {
  if (map == null) return false;
  if (map is Map<String, String>) return true;
  if (map.isEmpty) return false;

  if (listNotMatchesAll(map.keys, (k) => (k is String))) return false;
  if (listNotMatchesAll(map.values, (k) => (k is String))) return false;

  return true;
}

/// Returns [true] if [map] has [String] keys.
bool isMapOfStringKeys(Map? map) {
  if (map == null) return false;
  if (map is Map<String, String>) return true;
  if (map is Map<String, dynamic>) return true;
  if (map.isEmpty) return false;

  if (listNotMatchesAll(map.keys, (k) => (k is String))) return false;

  return true;
}

/// Returns [true] if [map] has [String] keys and [List] values.
bool isMapOfStringKeysAndListValues(Map? map) {
  if (map == null) return false;
  if (map is Map<String, List>) return true;
  if (map is Map<String, List<String>>) return true;
  if (map is Map<String, List<num>>) return true;
  if (map is Map<String, List<dynamic>>) return true;
  if (map.isEmpty) return false;

  if (listNotMatchesAll<MapEntry>(
      map.entries, (e) => (e.key is String) && (e.value is List))) {
    return false;
  }

  return true;
}

/// Returns [true] if [map] has [String] keys and [num] values.
bool isMapOfStringKeysAndNumValues(Map? map) {
  if (map == null) return false;
  if (map is Map<String, num>) return true;
  if (map.isEmpty) return false;

  if (listNotMatchesAll<MapEntry>(
      map.entries, (e) => (e.key is String) && (e.value is num))) {
    return false;
  }

  return true;
}

/// Converts [map] to a `Map<K,V>` ignoring any entry with null key or null value.
///
/// - [forceTypeCast]: if true, will try to cast key as [K] and values as [V].
/// if false, will ignore any entry that can't be cast.
Map<K, V> toNonNullMap<K, V>(Map? map, {bool forceTypeCast = true}) {
  if (map == null || map.isEmpty) {
    return <K, V>{};
  }

  Iterable<MapEntry<K, V>> entries;

  if (forceTypeCast) {
    entries = map.entries
        .where((e) => e.key != null && e.value != null)
        .map((e) => MapEntry(e.key! as K, e.value! as V));
  } else {
    entries = map.entries
        .where((e) => e.key is K && e.value is V)
        .map((e) => MapEntry(e.key! as K, e.value! as V));
  }

  var map2 = Map<K, V>.fromEntries(entries);
  return map2;
}

/// Converts [list] to a `List<T>` ignoring any null element.
///
/// - [forceTypeCast]: if true, will try to cast elements as [T].
/// if false, will ignore any element that can't be cast.
List<T> toNonNullList<T>(List? list, {bool forceTypeCast = true}) {
  if (list == null || list.isEmpty) {
    return <T>[];
  }

  List<T> list2;
  if (forceTypeCast) {
    list2 = list.where((e) => e != null).map((e) => e! as T).toList();
  } else {
    list2 = list.whereType<T>().toList();
  }
  return list2;
}

/// Converts [set] to a `Set<T>` ignoring any null element.
///
/// - [forceTypeCast]: if true, will try to cast elements as [T].
/// if false, will ignore any element that can't be cast.
Set<T> toNonNullSet<T>(Set? set, {bool forceTypeCast = true}) {
  if (set == null || set.isEmpty) {
    return <T>{};
  }

  Set<T> set2;
  if (forceTypeCast) {
    set2 = set.where((e) => e != null).map((e) => e! as T).toSet();
  } else {
    set2 = set.whereType<T>().toSet();
  }
  return set2;
}

/// Finds in [map] a entry that has one of [keys].
///
/// [ignoreCase] If [true] ignores the case of the keys.
MapEntry<K, V?>? findKeyEntry<K, V>(Map? map, List<K>? keys,
    [bool ignoreCase = false]) {
  if (map == null || keys == null || map.isEmpty || keys.isEmpty) return null;

  if (ignoreCase) {
    for (var key in keys) {
      if (map.containsKey(key)) {
        var value = map[key] as V?;
        return MapEntry<K, V?>(key, value);
      }

      var keyLC = key.toString().toLowerCase();

      for (var k in map.keys.whereType<K>()) {
        if (k.toString().toLowerCase() == keyLC) {
          var value = map[k] as V?;
          return MapEntry<K, V?>(k, value);
        }
      }
    }
  } else {
    for (var key in keys) {
      if (map.containsKey(key)) {
        var value = map[key] as V?;
        return MapEntry<K, V?>(key, value);
      }
    }
  }

  return null;
}

/// Finds in [map] a value that has one of [keys].
///
/// [ignoreCase] If [true] ignores the case of the keys.
V? findKeyValue<K, V>(Map? map, List<K>? keys, [bool ignoreCase = false]) {
  var entry = findKeyEntry<K, V>(map, keys, ignoreCase);
  return entry?.value;
}

/// Finds in [map] a value that is in key path [keyPath]
///
/// [keyDelimiter] The key path delimiter.
/// [isValidValue] validates a matching value.
V? findKeyPathValue<V>(Map? map, String? keyPath,
    {String keyDelimiter = '/', bool Function(Object? value)? isValidValue}) {
  if (map == null || map.isEmpty || keyPath == null || keyPath.isEmpty) {
    return null;
  }

  var keys = keyPath.split('/');

  var value = findKeyValue(map, [keys.first], true);
  if (value == null) return null;

  for (var i = 1; i < keys.length; ++i) {
    var k = keys[i];

    if (value is Map) {
      value = findKeyValue(value, [k], true);
      if (value == null) return null;
    } else if (value is List) {
      var idx = parseInt(k);
      if (idx != null) {
        value = value[idx];
      } else {
        return null;
      }
    } else {
      return null;
    }
  }

  if (isValidValue != null) {
    if (isValidValue(value)) {
      return value as V?;
    } else {
      return null;
    }
  } else {
    return value as V?;
  }
}

/// Finds in [map] a key that has one of [keys].
///
/// [ignoreCase] If [true] ignores the case of the keys.
K? findKeyName<K, V>(Map? map, List<K>? keys, [bool ignoreCase = false]) {
  var entry = findKeyEntry(map, keys, ignoreCase);
  return entry?.key;
}

/// Returns [true] if [s] is empty or null.
///
/// [trim] if [true] will trim [s] before check for [String.isEmpty].
bool isEmptyString(String? s, {bool trim = false}) {
  if (s == null) return true;
  if (trim) {
    s = s.trim();
  }
  return s.isEmpty;
}

/// Returns ![isEmptyString].
bool isNotEmptyString(String? s, {bool trim = false}) {
  return !isEmptyString(s, trim: trim);
}

/// If [s] [isEmptyString] will return [def] or [null].
///
/// [def] Default value to return if [s] [isEmptyString].
/// [trim] Passed to [isEmptyString].
String? ensureNotEmptyString(String? s, {bool trim = false, String? def}) {
  if (isEmptyString(s, trim: trim)) {
    return def;
  }
  return s;
}

/// Returns [true] if [o] is empty. Checks for [String], [List], [Map]
/// [Iterable], [Set] or `o.toString()`.
bool isEmptyObject<T>(T? o, {bool trim = false}) {
  if (o == null) return true;

  if (o is String) {
    return trim ? o.trim().isEmpty : o.isEmpty;
  } else if (o is List) {
    return trim ? o.where((e) => e != null).isEmpty : o.isEmpty;
  } else if (o is Map) {
    return trim ? o.entries.where((e) => e.value != null).isEmpty : o.isEmpty;
  } else if (o is Iterable) {
    return trim ? o.where((e) => e != null).isEmpty : o.isEmpty;
  } else if (o is Set) {
    return trim ? o.where((e) => e != null).isEmpty : o.isEmpty;
  } else {
    var s = o.toString();
    return trim ? s.trim().isEmpty : s.isEmpty;
  }
}

/// Returns ![isEmptyObject].
bool isNotEmptyObject<T>(T? value, {bool trim = false}) {
  return !isEmptyObject(value, trim: trim);
}

/// Remove all entries of [list] that are true for [isEmptyObject].
///
/// Returns true if [list.isNotEmpty].
bool removeEmptyEntries(List? list) {
  if (list == null || list.isEmpty) return false;
  list.removeWhere(isEmptyObject);
  return list.isNotEmpty;
}

typedef ValueValidator<V> = bool Function(V? value);

/// Validates [value] and returns [value] or [def].
T? resolveValue<T>(T? value,
    [T? def, ValueValidator valueValidator = isNotEmptyObject]) {
  if (value == null) return def;
  var valid = valueValidator(value);
  return valid ? value : def;
}

typedef StringMapper<T> = T Function(String s);

/// Parses [s] as a inline Map.
///
/// [delimiterPairs] The delimiter for pairs.
/// [delimiterKeyValue] The delimiter for keys and values.
/// [mapperKey] Maps keys to another type.
/// [mapperValue] Maps values to another type.
Map<K, V>? parseFromInlineMap<K, V>(
    String? s, Pattern delimiterPairs, Pattern delimiterKeyValue,
    [StringMapper<K>? mapperKey,
    StringMapper<V>? mapperValue,
    Map<K, V>? def]) {
  if (s == null) return def;
  s = s.trim();
  if (s.isEmpty) return def;

  mapperKey ??= (k) => k as K;
  mapperValue ??= (v) => v as V;

  var pairs = s.split(delimiterPairs);

  var map = <K, V>{};

  for (var pair in pairs) {
    var entry = split(pair, delimiterKeyValue, 2);
    var k = mapperKey(entry[0]);
    var v = mapperValue(entry.length > 1 ? entry[1] : '');
    map[k] = v;
  }

  return map;
}

/// Parses [s] as a inline list.
///
/// [delimiter] Elements delimiter.
/// [mapper] Maps elements to another type.
List<T>? parseFromInlineList<T>(String? s, Pattern delimiter,
    [StringMapper<T>? mapper, List<T>? def]) {
  if (s == null) return def;
  s = s.trim();
  if (s.isEmpty) return def;

  mapper ??= (s) => s as T;

  var parts = s.split(delimiter);

  var list = <T>[];

  for (var n in parts) {
    list.add(mapper(n));
  }

  return list;
}

final RegExp _inlinePropertiesDelimiterPairs = RegExp(r'\s*;\s*');
final RegExp _inlinePropertiesDelimiterKeysValues = RegExp(r'\s*[:=]\s*');

/// Parses an inline properties, like inline CSS, to a [Map<String,String>].
Map<String, String>? parseFromInlineProperties(String s,
    [StringMapper<String>? mapperKey,
    StringMapper<String>? mapperValue,
    Map<String, String>? def]) {
  return parseFromInlineMap(s, _inlinePropertiesDelimiterPairs,
      _inlinePropertiesDelimiterKeysValues, mapperKey, mapperValue, def);
}

/// Parses [v] as [String].
///
/// [def] Default value if [v] is invalid.
String? parseString(Object? v, [String? def]) {
  if (v == null) return def;

  if (v is String) return v;

  var s = v.toString().trim();

  if (s.isEmpty) return def;

  return s;
}

/// Parses [s] as a inline [Map<String,String>].
///
/// [delimiterPairs] Delimiter for pairs.
/// [delimiterKeyValue] Delimiter for keys and values.
/// [def] Default map if [s] is invalid.
Map<String, String>? parseStringFromInlineMap(
    Object? s, Pattern delimiterPairs, Pattern delimiterKeyValue,
    [Map<String, String>? def]) {
  if (s == null) return def;
  if (s is Map) {
    return s.map((k, v) => MapEntry(parseString(k, '')!, parseString(v, '')!));
  }
  return parseFromInlineMap(s.toString(), delimiterPairs, delimiterKeyValue,
      (e) => parseString(e)!, (e) => parseString(e)!, def);
}

/// Parses [s] as inline [List<String>].
///
/// [delimiter] The delimiter of elements.
///
/// [def] The default value if [s] is invalid.
List<String>? parseStringFromInlineList(Object? s,
    [Pattern? delimiter, List<String>? def]) {
  if (s == null) return def;
  if (s is List) return s.map((e) => parseString(e, '')!).toList();
  delimiter ??= RegExp(r'\s*,\s*');
  return parseFromInlineList(
      s.toString(), delimiter, (e) => parseString(e, '')!, def);
}

/// Parses [v] as to a [Comparable] type.
Comparable<T>? parseComparable<T>(Object? v) {
  if (v == null) return null;
  if (v is num) return v as Comparable<T>;

  if (v is String) return v as Comparable<T>;

  return parseString(v) as Comparable<T>?;
}

/// Parses [e] as a [MapEntry<String, String>]
MapEntry<String, String>? parseMapEntryOfStrings<K, V>(Object? e,
    [Pattern? delimiter, MapEntry<String, String>? def]) {
  if (e == null) return def;

  if (e is Map) {
    if (e.isNotEmpty) {
      var elem = e.entries.first;
      if (elem.key == null) return def;
      return MapEntry<String, String>(
          parseString(elem.key, '')!, parseString(elem.value, '')!);
    } else {
      return def;
    }
  } else if (e is List) {
    if (e.isEmpty) return def;
    if (e.length == 1) {
      delimiter ??= RegExp(r'\s*;\s*');
      return parseMapEntryOfStrings(e.first, delimiter, def);
    } else if (e.length == 2) {
      return MapEntry('${e[0]}', '${e[1]}');
    } else {
      var values = e.sublist(1);
      return MapEntry('${e[0]}', values.join(','));
    }
  } else {
    delimiter ??= RegExp(r'\s*[,;:]\s*');
    var s = parseString(e)!;
    var list = split(s, delimiter, 2);
    if (list.length == 2) {
      return MapEntry(list[0], list[1]);
    } else {
      var first = list.first;
      if (first.length < s.length) {
        return MapEntry(first, '');
      } else {
        return def;
      }
    }
  }
}

/// Calculate a hashcode over [o],
/// iterating deeply over sub elements if is a [List] or [Map].
int deepHashCode(Object? o) {
  if (o == null) return 0;

  if (o is List) {
    return deepHashCodeList(o);
  } else if (o is Map) {
    return deepHashCodeMap(o);
  } else {
    return o.hashCode;
  }
}

/// Computes a hash code inspecting deeply [list].
int deepHashCodeList(List? list) {
  if (list == null) return 0;

  var h = 1;

  for (var e in list) {
    h ^= deepHashCode(e);
  }

  return h;
}

/// Computes a hash code inspecting deeply [map].
int deepHashCodeMap(Map? map) {
  if (map == null) return 0;

  var h = 1;

  for (var e in map.entries) {
    h ^= deepHashCode(e.key) ^ deepHashCode(e.value);
  }

  return h;
}

typedef Copier = T? Function<T>(T? o);

/// Deeply copies [o].
///
/// [copier] Copy [Function] for non-primitive types.
T? deepCopy<T>(T? o, {Copier? copier}) {
  if (o == null) return null;
  if (o is String) return o;
  if (o is num) return o;
  if (o is bool) return o;

  if (o is List) return deepCopyList(o, copier: copier) as T?;
  if (o is Map) return deepCopyMap(o, copier: copier) as T?;

  if (copier != null) {
    return copier(o);
  } else {
    return o;
  }
}

/// Deeply copies [list].
///
/// [copier] Copy [Function] for non-primitive types.
List<T>? deepCopyList<T>(List<T>? l, {Copier? copier}) {
  if (l == null) return null;
  if (l.isEmpty) return <T>[];
  return l.map((T e) => deepCopy(e, copier: copier)!).toList();
}

/// Deeply copies [map].
///
/// [copier] Copy [Function] for non-primitive types.
Map<K, V>? deepCopyMap<K, V>(Map<K, V>? map, {Copier? copier}) {
  if (map == null) return null;
  if (map.isEmpty) return <K, V>{};
  return map.map((K k, V v) => MapEntry<K, V>(
      deepCopy(k, copier: copier) as K, deepCopy(v, copier: copier) as V));
}

typedef ValueFilter = bool Function(
    Object? collection, Object? key, Object? value);

typedef ValueReplacer = Object? Function(
    Object? collection, Object? key, Object? value);

/// Replaces values applying [replacer] to values that matches [filter].
Object? deepReplaceValues<T>(
    Object? o, ValueFilter filter, ValueReplacer replacer) {
  if (o == null) return null;

  if (filter(null, null, o)) {
    return replacer(null, null, o);
  } else if (o is List) {
    deepReplaceListValues(o, filter, replacer);
    return o;
  } else if (o is Map) {
    deepReplaceMapValues(o, filter, replacer);
    return o;
  } else if (o is Set) {
    deepReplaceSetValues(o, filter, replacer);
    return o;
  } else {
    return o;
  }
}

/// Replaces values applying [replacer] to values that matches [filter].
void deepReplaceListValues<T>(
    List? list, ValueFilter filter, ValueReplacer replacer) {
  if (list == null || list.isEmpty) return;

  for (var i = 0; i < list.length; ++i) {
    var v = list[i];
    if (filter(list, i, v)) {
      list[i] = replacer(list, i, v);
    } else {
      list[i] = deepReplaceValues(v, filter, replacer);
    }
  }
}

/// Replaces values applying [replacer] to values that matches [filter].
void deepReplaceMapValues<T>(
    Map? map, ValueFilter filter, ValueReplacer replacer) {
  if (map == null || map.isEmpty) return;

  for (var entry in map.entries) {
    var k = entry.key;
    var v = entry.value;
    if (filter(map, k, v)) {
      map[k] = replacer(map, k, v);
    } else {
      map[k] = deepReplaceValues(v, filter, replacer);
    }
  }
}

/// Replaces values applying [replacer] to values that matches [filter].
void deepReplaceSetValues<T>(
    Set? set, ValueFilter filter, ValueReplacer replacer) {
  if (set == null || set.isEmpty) return;

  var entries = set.toList();

  for (var val in entries) {
    Object? val2;
    if (filter(set, null, val)) {
      val2 = replacer(set, null, val);
    } else {
      val2 = deepReplaceValues(val, filter, replacer);
    }

    if (!identical(val, val2)) {
      set.remove(val);
      set.add(val2);
    }
  }
}

/// Catches deeply values that matches [filter].
///
/// Returns a [List] of the matched values
List deepCatchesValues<T>(Object? o, ValueFilter filter, [List? result]) {
  result ??= [];

  if (o == null) return result;

  if (filter(null, null, o)) {
    result.add(o);
  } else if (o is List) {
    deepCatchesListValues(o, filter, result);
  } else if (o is Map) {
    deepCatchesMapValues(o, filter, result);
  } else if (o is Set) {
    deepCatchesSetValues(o, filter, result);
  }

  return result;
}

/// Catches deeply [list] values that matches [filter].
///
/// Returns a [List] of the matched values
List deepCatchesListValues<T>(List? list, ValueFilter filter, [List? result]) {
  result ??= [];

  if (list == null || list.isEmpty) return result;

  for (var i = 0; i < list.length; ++i) {
    var v = list[i];
    if (filter(list, i, v)) {
      result.add(v);
    } else {
      deepCatchesValues(v, filter, result);
    }
  }

  return result;
}

/// Catches deeply [map] values that matches [filter].
///
/// Returns a [List] of the matched values
List deepCatchesMapValues<T>(Map? map, ValueFilter filter, [List? result]) {
  result ??= [];

  if (map == null || map.isEmpty) return result;

  for (var entry in map.entries) {
    var k = entry.key;
    var v = entry.value;
    if (filter(map, k, v)) {
      result.add(v);
    } else {
      deepCatchesValues(v, filter, result);
    }
  }

  return result;
}

/// Catches deeply [set] values that matches [filter].
///
/// Returns a [List] of the matched values
List deepCatchesSetValues<T>(Set? set, ValueFilter filter, [List? result]) {
  result ??= [];

  if (set == null || set.isEmpty) return result;

  for (var val in set) {
    if (filter(set, null, val)) {
      result.add(val);
    } else {
      deepCatchesValues(val, filter, result);
    }
  }

  return result;
}

/// Returns the instance that matches [value] in [set].
T? getSetEntryInstance<T>(Set<T>? set, T? value) {
  if (set == null || value == null) return null;
  if (!set.contains(value)) return null;

  for (var elem in set) {
    if (elem == value) {
      return elem;
    }
  }
  return null;
}

/// A [Map] that delegates to another [_map].
/// Useful to extend [Map] features.
class MapDelegate<K, V> implements Map<K, V> {
  final Map<K, V> _map;

  MapDelegate(this._map);

  Map<K, V> get mainMap => _map;

  @override
  V? operator [](Object? key) => _map[key];

  @override
  void operator []=(K key, value) => _map[key] = value;

  @override
  void addAll(Map<K, V> other) => _map.addAll(other);

  @override
  void addEntries(Iterable<MapEntry<K, V>> newEntries) =>
      _map.addEntries(newEntries);

  @override
  Map<RK, RV> cast<RK, RV>() => _map.cast<RK, RV>();

  @override
  void clear() => _map.clear();

  @override
  bool containsKey(Object? key) => _map.containsKey(key);

  @override
  bool containsValue(Object? value) => _map.containsValue(value);

  @override
  Iterable<MapEntry<K, V>> get entries => _map.entries;

  @override
  void forEach(void Function(K key, V value) f) => _map.forEach(f);

  @override
  bool get isEmpty => _map.isEmpty;

  @override
  bool get isNotEmpty => _map.isNotEmpty;

  @override
  Iterable<K> get keys => _map.keys;

  @override
  int get length => _map.length;

  @override
  Map<K2, V2> map<K2, V2>(MapEntry<K2, V2> Function(K key, V value) f) =>
      _map.map<K2, V2>(f);

  @override
  V putIfAbsent(K key, V Function() ifAbsent) =>
      _map.putIfAbsent(key, ifAbsent);

  @override
  V? remove(Object? key) => _map.remove(key);

  @override
  void removeWhere(bool Function(K key, V value) predicate) =>
      _map.removeWhere(predicate);

  @override
  V update(K key, V Function(V value) update, {V Function()? ifAbsent}) =>
      _map.update(key, update);

  @override
  void updateAll(V Function(K key, V value) update) => _map.updateAll(update);

  @override
  Iterable<V> get values => _map.values;
}

/// A [Map] of properties.
class MapProperties extends MapDelegate<String, dynamic> {
  /// Parses [value] to a valid property [value].
  static Object? parseValue(Object? value) {
    if (isInt(value)) {
      return parseInt(value);
    } else if (isDouble(value)) {
      return parseDouble(value);
    } else if (isNum(value)) {
      return parseNum(value);
    } else if (isBool(value)) {
      return parseBool(value);
    } else if (isIntList(value)) {
      return parseIntsFromInlineList(value, ',');
    } else if (isDoubleList(value)) {
      return parseBoolsFromInlineList(value, ',');
    } else if (isNumList(value)) {
      return parseNumsFromInlineList(value, ',');
    } else if (isBoolList(value)) {
      return parseBoolsFromInlineList(value, ',');
    } else {
      return value;
    }
  }

  /// Parse [stringProperties] to properties values.
  static Map<String, dynamic> parseStringProperties(
      Map<String, String>? stringProperties) {
    if (stringProperties == null || stringProperties.isEmpty) {
      return <String, dynamic>{};
    }
    return stringProperties.map((k, v) => MapEntry(k, parseValue(v)));
  }

  MapProperties() : super({});

  MapProperties.fromProperties(Map<String, dynamic> properties)
      : super(Map<String, dynamic>.from(properties));

  MapProperties.fromStringProperties(Map<String, String> stringProperties)
      : super(parseStringProperties(stringProperties));

  MapProperties.fromMap(Map properties)
      : super(properties
            .map((k, v) => MapEntry(parseString(k, '')!, parseString(v, '')!)));

  /// Gets a property with [key].
  ///
  /// [def] The default value if [key] not found.
  T? getProperty<T>(String key, [T? def]) {
    var val = findKeyValue(_map, [key], true);
    return val != null ? val as T : def;
  }

  /// Finds a property with [keys].
  ///
  /// [def] The default value if [keys] not found.
  T? findProperty<T>(List<String> keys, [T? def]) {
    var val = findKeyValue(_map, keys, true);
    return val != null ? val as T : def;
  }

  /// Gets a property with [key].
  ///
  /// [mapper] Maps the value to [T].
  /// [def] The default value if [key] not found.
  // ignore: use_function_type_syntax_for_parameters
  T? getPropertyAs<T>(String key, T? mapper(Object? v), [T? def]) {
    var val = findKeyValue(_map, [key], true);
    return val != null ? mapper(val) : def;
  }

  /// Finds a property with [keys].
  ///
  /// [mapper] Maps the value to [T].
  /// [def] The default value if [key] not found.
  // ignore: use_function_type_syntax_for_parameters
  T? findPropertyAs<T>(List<String> keys, T? mapper(Object? v), [T? def]) {
    var val = findKeyValue(_map, keys, true);
    return val != null ? mapper(val) : def;
  }

  /// Gets a property with [key]. Returns the value in lower case and trimmed.
  ///
  /// [def] The default value if [key] not found.
  String? getPropertyAsStringTrimLC(String key, [String? def]) {
    var val = getPropertyAsStringTrim(key, def);
    return val?.toLowerCase();
  }

  /// Finds a property with [keys]. Returns the value in lower case and trimmed.
  ///
  /// [def] The default value if [keys] not found.
  String? findPropertyAsStringTrimLC(List<String> keys, [String? def]) {
    var val = findPropertyAsStringTrim(keys, def);
    return val?.toLowerCase();
  }

  /// Gets a property with [key]. Returns the value in upper case and trimmed.
  ///
  /// [def] The default value if [key] not found.
  String? getPropertyAsStringTrimUC(String key, [String? def]) {
    var val = getPropertyAsStringTrim(key, def);
    return val?.toUpperCase();
  }

  /// Finds a property with [keys]. Returns the value in upper case and trimmed.
  ///
  /// [def] The default value if [keys] not found.
  String? findPropertyAsStringTrimUC(List<String> keys, [String? def]) {
    var val = findPropertyAsStringTrim(keys, def);
    return val?.toUpperCase();
  }

  /// Gets a property with [key]. Returns the value trimmed.
  ///
  /// [def] The default value if [key] not found.
  String? getPropertyAsStringTrim(String key, [String? def]) {
    var val = getPropertyAsString(key, def);
    return val?.trim();
  }

  /// Finds a property with [keys]. Returns the value trimmed.
  ///
  /// [def] The default value if [keys] not found.
  String? findPropertyAsStringTrim(List<String> keys, [String? def]) {
    var val = findPropertyAsString(keys, def);
    return val?.trim();
  }

  /// Gets a property with [key]. Returns the value as [String].
  ///
  /// [def] The default value if [key] not found.
  String? getPropertyAsString(String key, [String? def]) =>
      getPropertyAs(key, parseString, def);

  /// Gets a property with [key]. Returns the value as [int].
  ///
  /// [def] The default value if [key] not found.
  int? getPropertyAsInt(String key, [int? def]) =>
      getPropertyAs(key, parseInt, def);

  /// Gets a property with [key]. Returns the value as [double].
  ///
  /// [def] The default value if [key] not found.
  double? getPropertyAsDouble(String key, [double? def]) =>
      getPropertyAs(key, parseDouble, def);

  /// Gets a property with [key]. Returns the value as [num].
  ///
  /// [def] The default value if [key] not found.
  num? getPropertyAsNum(String key, [num? def]) =>
      getPropertyAs(key, parseNum, def);

  /// Gets a property with [key]. Returns the value as [bool].
  ///
  /// [def] The default value if [key] not found.
  bool? getPropertyAsBool(String key, [bool? def]) =>
      getPropertyAs(key, parseBool, def);

  /// Gets a property with [key]. Returns the value as [DateTime].
  ///
  /// [def] The default value if [key] not found.
  DateTime? getPropertyAsDateTime(String key, [DateTime? def]) =>
      getPropertyAs(key, parseDateTime, def);

  /// Finds a property with [keys]. Returns the value as [String].
  ///
  /// [def] The default value if [keys] not found.
  String? findPropertyAsString(List<String> keys, [String? def]) =>
      findPropertyAs(keys, (e) => parseString(e), def);

  /// Finds a property with [keys]. Returns the value as [int].
  ///
  /// [def] The default value if [keys] not found.
  int? findPropertyAsInt(List<String> keys, [int? def]) =>
      findPropertyAs(keys, parseInt, def);

  /// Finds a property with [keys]. Returns the value as [double].
  ///
  /// [def] The default value if [keys] not found.
  double? findPropertyAsDouble(List<String> keys, [double? def]) =>
      findPropertyAs(keys, parseDouble, def);

  /// Finds a property with [keys]. Returns the value as [num].
  ///
  /// [def] The default value if [keys] not found.
  num? findPropertyAsNum(List<String> keys, [num? def]) =>
      findPropertyAs(keys, parseNum, def);

  /// Finds a property with [keys]. Returns the value as [bool].
  ///
  /// [def] The default value if [keys] not found.
  bool? findPropertyAsBool(List<String> keys, [bool? def]) =>
      findPropertyAs(keys, parseBool, def);

  /// Finds a property with [keys]. Returns the value as [DateTime].
  ///
  /// [def] The default value if [keys] not found.
  DateTime? findPropertyAsDateTime(List<String> keys, [DateTime? def]) =>
      findPropertyAs(keys, parseDateTime, def);

  /// Gets a property with [key] as [List<String>].
  ///
  /// [def] The default value if [key] not found.
  List<String>? getPropertyAsStringList(String key, [List<String>? def]) =>
      getPropertyAs(key, (v) => parseStringFromInlineList(v, ',', def), def);

  /// Gets a property with [key] as [List<int>].
  ///
  /// [def] The default value if [key] not found.
  List<int>? getPropertyAsIntList(String key, [List<int>? def]) =>
      getPropertyAs(key, (v) => parseIntsFromInlineList(v, ',', def), def);

  /// Gets a property with [key] as [List<double>].
  ///
  /// [def] The default value if [key] not found.
  List<double>? getPropertyAsDoubleList(String key, [List<double>? def]) =>
      getPropertyAs(key, (v) => parseDoublesFromInlineList(v, ',', def), def);

  /// Gets a property with [key] as [List<num>].
  ///
  /// [def] The default value if [key] not found.
  List<num>? getPropertyAsNumList(String key, [List<num>? def]) =>
      getPropertyAs(key, (v) => parseNumsFromInlineList(v, ',', def), def);

  /// Gets a property with [key] as [List<bool>].
  ///
  /// [def] The default value if [key] not found.
  List<bool>? getPropertyAsBoolList(String key, [List<bool>? def]) =>
      getPropertyAs(key, (v) => parseBoolsFromInlineList(v, ',', def), def);

  /// Gets a property with [key] as [List<DateTime>].
  ///
  /// [def] The default value if [key] not found.
  List<DateTime>? getPropertyAsDateTimeList(String key,
          [List<DateTime>? def]) =>
      getPropertyAs(key, (v) => parseDateTimeFromInlineList(v, ',', def), def);

  /// Finds a property with [keys] as [List<String>].
  ///
  /// [def] The default value if [keys] not found.
  List<String>? findPropertyAsStringList(List<String> keys,
          [List<String>? def]) =>
      findPropertyAs(keys, (v) => parseStringFromInlineList(v, ',', def), def);

  /// Finds a property with [keys] as [List<int>].
  ///
  /// [def] The default value if [keys] not found.
  List<int>? findPropertyAsIntList(List<String> keys, [List<int>? def]) =>
      findPropertyAs(keys, (v) => parseIntsFromInlineList(v, ',', def), def);

  /// Finds a property with [keys] as [List<int>].
  ///
  /// [def] The default value if [keys] not found.
  List<double>? findPropertyAsDoubleList(List<String> keys,
          [List<double>? def]) =>
      findPropertyAs(keys, (v) => parseDoublesFromInlineList(v, ',', def), def);

  /// Finds a property with [keys] as [List<num>].
  ///
  /// [def] The default value if [keys] not found.
  List<num>? findPropertyAsNumList(List<String> keys, [List<num>? def]) =>
      findPropertyAs(keys, (v) => parseNumsFromInlineList(v, ',', def), def);

  /// Finds a property with [keys] as [List<bool>].
  ///
  /// [def] The default value if [keys] not found.
  List<bool>? findPropertyAsBoolList(List<String> keys, [List<bool>? def]) =>
      findPropertyAs(keys, (v) => parseBoolsFromInlineList(v, ',', def), def);

  /// Finds a property with [keys] as [List<DateTime>].
  ///
  /// [def] The default value if [keys] not found.
  List<DateTime>? findPropertyAsDateTimeList(List<String> keys,
          [List<DateTime>? def]) =>
      findPropertyAs(
          keys, (v) => parseDateTimeFromInlineList(v, ',', def), def);

  /// Gets a property with [key] as [List<Map>].
  ///
  /// [def] The default value if [key] not found.
  Map<String, String>? getPropertyAsStringMap(String key,
          [Map<String, String>? def]) =>
      getPropertyAs(
          key, (v) => parseStringFromInlineMap(v, ';', ':', def), def);

  /// Finds a property with [keys] as [List<Map>].
  ///
  /// [def] The default value if [keys] not found.
  Map<String, String>? findPropertyAsStringMap(List<String> keys,
          [Map<String, String>? def]) =>
      findPropertyAs(
          keys, (v) => parseStringFromInlineMap(v, ';', ':', def), def);

  /// Returns this as a [Map<String,dynamic>].
  Map<String, dynamic> toProperties() {
    return Map.from(_map).cast();
  }

  /// Returns this as a [Map<String,String>].
  Map<String, String> toStringProperties() {
    return _map.map((k, v) => MapEntry(k, parseString(v)!));
  }

  /// put property [value] to [key].
  dynamic put(String key, Object? value) {
    var valueStr = toStringValue(value);

    var prev = this[key];
    this[key] = valueStr;
    return prev;
  }

  /// Returns [value] as a [String].
  static String? toStringValue(Object? value, [String? def]) {
    if (value == null) return def;

    String valueStr;

    if (value is String) {
      valueStr = value;
    } else if (value is List) {
      valueStr = value.map((e) => toStringValue(e)).join(',');
    } else if (value is Map) {
      valueStr = value.entries
          .expand((e) => ['${e.key}:${toStringValue(e.value)}'])
          .toList()
          .join(';');
    } else if (value is Iterable) {
      valueStr = value.map(toStringValue).join(',');
    } else if (value is Pair) {
      valueStr = value.join(',');
    } else if (value is MapEntry) {
      valueStr = '${value.key},${value.value}';
    } else {
      valueStr = '$value';
    }

    return valueStr;
  }

  @override
  String toString() {
    var s = '{ \n';

    for (var entry in _map.entries) {
      var key = entry.key;
      var value = entry.value;

      var sKey = '"$key"';

      String sVal;
      if (value == null) {
        sVal = 'null';
      } else if (value is num) {
        sVal = '$value';
      } else if (value is bool) {
        sVal = '$value';
      } else {
        sVal = '"$value"';
      }

      if (s.length > 3) s += ' , ';
      s += '$sKey: $sVal';
    }

    s += ' }';

    return s;
  }
}

/// Groups [interable] entries using [map] to generate a [MapEntry] for
/// each entry, than uses [merge] to group entries of the same group (key).
Map<K, V> groupIterableBy<K, V, I>(
    Iterable<I> iterable,
    MapEntry<K, V> Function(I entry) map,
    V Function(K key, V value1, V value2) merge) {
  if (iterable.isEmpty) return <K, V>{};

  var groups = <K, V>{};

  for (var entry in iterable) {
    var e = map(entry);

    var k = e.key;

    var prev = groups[k];

    if (prev == null) {
      groups[k] = e.value;
    } else {
      var v2 = merge(k, prev, e.value);
      groups[k] = v2;
    }
  }

  return groups;
}

/// Merges all entries of [iterable] using [merge] function.
///
/// [init] The initial value of total.
R? mergeIterable<I, R>(
    Iterable<I> iterable, R Function(R? total, I value) merge,
    [R? init]) {
  if (iterable.isEmpty) return init;

  var total = init;

  for (var entry in iterable) {
    total = merge(total, entry);
  }

  return total;
}

/// Uses [mergeIterable] to sum all [iterable] values.
num sumIterable<I, R>(Iterable<num> iterable, {num init = 0}) =>
    mergeIterable(iterable, (num? total, num value) => total! + value, init)!;

/// Uses [mergeIterable] to find maximum value in [iterable].
num? maxInIterable<I, R>(Iterable<num> iterable) => iterable.isEmpty
    ? null
    : mergeIterable(
        iterable, (num? total, num value) => value > total! ? value : total, 0);

/// Uses [mergeIterable] to find minimum value in [iterable].
num? minInIterable<I, R>(Iterable<num> iterable) => iterable.isEmpty
    ? null
    : mergeIterable(
        iterable,
        (num? total, num value) => value < total! ? value : total,
        iterable.first);

/// Calculate the average value of [iterable].
num? averageIterable<I, R>(Iterable<num> iterable) =>
    iterable.isEmpty ? null : sumIterable(iterable) / iterable.length;

/// A field that can't be null. If a null value is set to it,
/// a default value will be used.
class NNField<T> {
  final T defaultValue;

  /// If [true], [hashCode] will use [deepHashCode] for calculation.
  final bool deepHashcode;

  /// Optional value filter to apply before set.
  final T Function(dynamic value)? filter;

  /// Optional value to apply before get.
  final T Function(T value)? resolver;

  T _value;

  NNField(this.defaultValue,
      {this.deepHashcode = false, this.filter, this.resolver})
      : _value = defaultValue;

  /// The filed value as [T].
  T get value => get();

  set value(Object? value) => set(value);

  /// Returns the current filed [value].
  T get() {
    if (resolver != null) {
      return resolver!(_value);
    }
    return _value;
  }

  /// Sets the field [value].
  ///
  /// If [value] is null uses [defaultValue].
  ///
  /// Applies [filter] if exists and [value] is not null.
  void set<V>(V? value) {
    if (value == null) {
      _value = defaultValue;
    } else {
      if (filter != null) {
        _value = filter!(value) ?? defaultValue;
      } else {
        try {
          _value = value as T;
        } catch (e) {
          if (_value is int) {
            _value = parseInt(value) as T;
          } else if (_value is double) {
            _value = parseDouble(value) as T;
          } else if (_value is num) {
            _value = parseNum(value) as T;
          } else if (_value is bool) {
            _value = parseBool(value) as T;
          } else if (_value is String) {
            _value = parseString(value) as T;
          } else {
            rethrow;
          }
        }
      }
    }
  }

  /// Returns [true] if [other] is equals to [this.value].
  ///
  /// If [other] is a [NNField], compares with [other.value].
  bool equals(Object? other) {
    if (other == null) return false;
    if (other is NNField) {
      return equals(other._value);
    }
    return _value == other;
  }

  /// Same as [equals] method.
  @override
  bool operator ==(Object value) => equals(value);

  @override
  int get hashCode => deepHashcode ? deepHashCode(value) : value.hashCode;

  /// [value] as [String].
  @override
  String toString() => asString;

  String get asString => parseString(_value, '')!;

  /// [value] as [num].
  num? get asNum => parseNum(_value);

  /// [value] as [int].
  int? get asInt => parseInt(_value);

  /// [value] as [double].
  double? get asDouble => parseDouble(_value);

  /// [value] as [bool].
  bool? get asBool => parseBool(_value);

  /// Operator [*], using [asNum] for [this.value] and [parseNum(value)] for parameter.
  num operator *(Object? value) => asNum! * parseNum(value)!;

  /// Operator [/], using [asNum] for [this.value] and [parseNum(value)] for parameter.
  num operator /(Object? value) => asNum! / parseNum(value)!;

  /// Operator [+], using [asNum] for [this.value] and [parseNum(value)] for parameter.
  num operator +(Object? value) => asNum! + parseNum(value)!;

  /// Operator [-], using [asNum] for [this.value] and [parseNum(value)] for parameter.
  num operator -(Object? value) => asNum! - parseNum(value)!;

  /// Operator [^], using [asInt] for [this.value] and [parseInt(value)] for parameter.
  num operator ^(Object? value) => asInt! ^ parseInt(value)!;

  /// Operator [>], using [asNum] for [this.value] and [parseNum(value)] for parameter.
  bool operator >(num value) => asNum! > parseNum(value)!;

  /// Operator [>=], using [asNum] for [this.value] and [parseNum(value)] for parameter.
  bool operator >=(num value) => asNum! >= parseNum(value)!;

  /// Operator [<], using [asNum] for [this.value] and [parseNum(value)] for parameter.
  bool operator <(num value) => asNum! < parseNum(value)!;

  /// Operator [<=], using [asNum] for [this.value] and [parseNum(value)] for parameter.
  bool operator <=(num value) => asNum! <= parseNum(value)!;

  /// Increments: [this.value] + [value]
  num? increment(Object? value) {
    var result = parseNum(_value)! + parseNum(value)!;
    set(result);
    return asNum;
  }

  /// Decrements: [this.value] - [value]
  num? decrement(Object? value) {
    var result = parseNum(_value)! - parseNum(value)!;
    set(result);
    return asNum;
  }

  /// Multiply: [this.value] * [value]
  num? multiply(dynamic value) {
    var result = parseNum(_value)! * parseNum(value)!;
    set(result);
    return asNum;
  }

  /// Divide: [this.value] / [value]
  num? divide(dynamic value) {
    var result = parseNum(_value)! / parseNum(value)!;
    set(result);
    return asNum;
  }
}

/// A simple cache of objects, where is possible to define different
/// instantiators for each key.
class ObjectCache {
  /// Maximum number of cached instances.
  int? maxInstances;

  ObjectCache([this.maxInstances]);

  final Map<String, dynamic> _cacheInstances = {};

  final Map<String, Function()> _cacheInstantiators = {};
  final Map<String, bool Function(Object o)> _cacheValidators = {};

  /// Sets the [instantiator] for [key]
  void setInstantiator<O>(String key, O Function() instantiator) =>
      _cacheInstantiators[key] = instantiator;

  /// Sets the [cacheValidator] for [key]
  void setCacheValidator<O>(
          String key, bool Function(Object o) cacheValidator) =>
      _cacheValidators[key] = cacheValidator;

  /// Defines instantiator and cache-validator for [key].
  void define<O>(String key, O Function() instantiator,
      [bool Function(Object o)? cacheValidator]) {
    _cacheInstantiators[key] = instantiator;
    if (cacheValidator != null) {
      _cacheValidators[key] = cacheValidator;
    }
  }

  /// Remove instantiator and cache-validator for [key].
  void undefine<O>(String key) {
    _cacheInstantiators.remove(key);
    _cacheValidators.remove(key);
  }

  /// Define all keys from [map], where map values can be a instantiator
  /// functions or a list with 2 values
  /// (instantiator and cache-validator functions).
  void defineAll(Map<String, dynamic> map) {
    for (var entry in map.entries) {
      _define(entry.key, entry.value);
    }
  }

  bool _define(String key, value) {
    if (value is Function) {
      define(key, value as Object Function());
      return true;
    } else if (value is List) {
      if (value.length == 1) {
        define(key, value[0]);
        return true;
      } else if (value.length == 2) {
        define(key, value[0], value[1]);
        return true;
      }
    }
    return false;
  }

  /// Returns an object for [key].
  ///
  /// Uses [instantiator] (or pre-defined) to instantiate.
  ///
  /// Uses [cacheValidator] (or pre-defined) to validade already cached instance.
  O? get<O>(String key,
      [O Function()? instantiator, bool Function(Object o)? cacheValidator]) {
    var o = _cacheInstances[key];

    if (o != null) {
      cacheValidator ??= _cacheValidators[key];

      if (cacheValidator != null) {
        var ok = cacheValidator(o);
        if (ok) {
          return o;
        } else {
          _cacheInstances.remove(key);
        }
      } else {
        return o;
      }
    }

    instantiator ??= _cacheInstantiators[key] as O Function()?;
    if (instantiator == null) return null;

    if (maxInstances != null && maxInstances! > 0) {
      var needToRemove = _cacheInstances.length - (maxInstances! - 1);
      disposeInstances(needToRemove);
    }

    o = instantiator();
    _cacheInstances[key] = o;

    return o;
  }

  int disposeInstances(int? amountToRemove) {
    if (amountToRemove == null || amountToRemove < 1) return 0;

    var keys = List.from(_cacheInstances.keys);

    var removed = 0;
    for (var k in keys) {
      _cacheInstances.remove(k);
      removed++;

      if (removed >= amountToRemove) {
        return removed;
      }
    }

    return removed;
  }

  /// Removes [key] instance from cache.
  void disposeInstance(String key) => _cacheInstances.remove(key);

  /// Removes all cached instances, preseving definitions.
  void clearInstances() {
    _cacheInstances.clear();
  }

  /// Clear all cached instances and all definitions.
  void clear() {
    clearInstances();
    _cacheInstantiators.clear();
    _cacheValidators.clear();
  }

  dynamic operator [](String key) => get(key);
}

/// A [Map] that retains entries only while their keys are reachable from [root].
///
/// Internally, this map is backed by a [WeakKeyMap]. Weak references are used
/// to avoid keeping keys alive beyond their natural lifetime, while
/// reachability from [root] defines whether an entry is considered valid.
///
/// Entries whose keys are no longer reachable from the object tree rooted
/// at [root] can be explicitly or automatically purged to prevent memory
/// growth.
///
/// Browser use case: when [root] is a DOM `Node`, values can be safely
/// associated with any `Node` in the DOM tree, and entries are removed once
/// the node is detached from the document.
class TreeReferenceMap<K extends Object, V extends Object>
    implements Map<K, V> {
  /// The root of the Tree Reference.
  final K root;

  /// Whether automatic purging of stale entries is enabled.
  ///
  /// When enabled, purge checks run during read/write operations.
  final bool autoPurge;

  /// Default threshold used when none is explicitly provided.
  static const int defaultAutoPurgeThreshold = 100;

  /// Number of operations after which an automatic purge is triggered.
  final int autoPurgeThreshold;

  /// Will stored purged entries in a separated [Map].
  final bool keepPurgedEntries;

  /// Purged entries timeout.
  final Duration? purgedEntriesTimeout;

  /// Maximum number of purged entries.
  final int? maxPurgedEntries;

  /// The [Function] that returns the parent of a key.
  final K? Function(K key)? parentGetter;

  /// The [Function] that returns the children of a key.
  final Iterable<K> Function(K key)? childrenGetter;

  /// The [Function] that returns true if [parent] has [child].
  final bool Function(K parent, K child, bool deep)? childChecker;

  /// Optional callback invoked after entries are purged.
  ///
  /// Receives a map containing all entries that were removed during
  /// the purge operation.
  void Function(Map<K, V> purgedEntries)? onPurgedEntries;

  TreeReferenceMap(this.root,
      {this.autoPurge = false,
      this.autoPurgeThreshold = defaultAutoPurgeThreshold,
      bool keepPurgedKeys = false,
      this.purgedEntriesTimeout,
      this.maxPurgedEntries,
      this.parentGetter,
      this.childrenGetter,
      this.childChecker,
      this.onPurgedEntries})
      : keepPurgedEntries = keepPurgedKeys;

  final WeakKeyMap<K, V> _map = WeakKeyMap(autoPurge: false);

  void put(K key, V value) {
    _map[key] = value;
    doAutoPurge();
    _expireCache();
  }

  V? get(K key) {
    doAutoPurge();
    return _map[key];
  }

  V? getAlsoFromPurgedEntries(K key) {
    doAutoPurge();
    return _map[key] ?? getFromPurgedEntries(key);
  }

  /// Returns [true] if [key] is valid (in the tree).
  bool isValidEntry(K key, V value) => isInTree(key);

  /// Returns [true] if [key] is in the tree.
  bool isInTree(K? key) {
    if (identical(root, key)) return true;

    K? cursor = key;
    while (cursor != null) {
      var parent = getParentOf(cursor);
      if (identical(parent, root)) return true;
      cursor = parent;
    }

    return false;
  }

  /// Returns the parent of [key].
  ///
  /// Will call [parentGetter].
  ///
  /// Should be overwritten if [parentGetter] is null.
  K? getParentOf(K? key) => key == null ? null : parentGetter!(key);

  /// Gets values from children of [key] in a tree, using depth-first, left-to-right traversal.
  ///
  /// - [key]: The key to start from. Returns empty list if `null`.
  /// - [includePurgedEntries]: If `true`, includes purged entries. Defaults to `false`.
  /// - [traverseSubValues]: If `true`, explores children after finding a value. Defaults to `false`.
  ///
  /// Returns: A [List<V>] of non-null values from child nodes.
  List<V> getSubValues(K? key,
      {bool includePurgedEntries = false, bool traverseSubValues = false}) {
    var subValues = <V>[];
    if (key == null) return subValues;

    if (includePurgedEntries) {
      _getSubValuesImpl(
          key, subValues, traverseSubValues, getAlsoFromPurgedEntries);
    } else {
      _getSubValuesImpl(key, subValues, traverseSubValues, get);
    }
    return subValues;
  }

  void _getSubValuesImpl(K key, List<V> subValues, bool traverseSubValues,
      V? Function(K key) get) {
    final stack = Queue<K>()..add(key);

    // Skip root key, push its children to stack in reverse order:
    {
      final current = stack.removeLast();
      final children = getChildrenOf(current);

      for (var i = children.length - 1; i >= 0; --i) {
        var child = children.elementAt(i);
        stack.add(child);
      }
    }

    // Traverse in depth-first, left-to-right order
    while (stack.isNotEmpty) {
      final current = stack.removeLast();

      final value = get(current);
      if (value != null) {
        subValues.add(value);
        if (!traverseSubValues) {
          continue;
        }
      }

      final children = getChildrenOf(current);

      final lng = children.length;
      if (lng == 0) continue;

      for (var i = lng - 1; i >= 0; --i) {
        var child = children.elementAt(i);
        stack.add(child);
      }
    }
  }

  /// Get 1st parent value of [child];
  V? getParentValue(K? child, {bool includePurgedEntries = false}) {
    if (child == null) return null;

    var parent = getParentKey(child);
    return parent != null
        ? (includePurgedEntries
            ? getAlsoFromPurgedEntries(parent)
            : get(parent))
        : null;
  }

  /// Get 1st parent key of [child];
  K? getParentKey(K? child, {bool includePurgedEntries = false}) {
    if (child == null || identical(child, root)) return null;

    if (includePurgedEntries) {
      var purged = _purged ?? <K, MapEntry<DateTime, V>>{};
      var cursor = getParentOf(child);
      while (cursor != null) {
        if (_map.containsKey(cursor) || purged.containsKey(cursor)) {
          return cursor;
        }
        cursor = getParentOf(cursor);
      }
    } else {
      var cursor = getParentOf(child);
      while (cursor != null) {
        if (_map.containsKey(cursor)) return cursor;
        cursor = getParentOf(cursor);
      }
    }

    if (isChildOf(root, child, false)) {
      return root;
    }

    return null;
  }

  /// Returns the children of [key].
  ///
  /// Will call [childrenGetter].
  ///
  /// Should be overwritten if [childrenGetter] is null.
  Iterable<K> getChildrenOf(K? key) =>
      key == null ? <K>[] : childrenGetter!(key);

  /// Returns true if [parent] has [child]. If [deep] is true, will check sub nodes children.
  ///
  /// Will call [childChecker].
  ///
  /// Should be overwritten if [childChecker] is null.
  bool isChildOf(K? parent, K? child, bool deep) =>
      parent != null && child != null && childChecker!(parent, child, deep);

  DualWeakMap<K, MapEntry<DateTime, V>>? _purged;

  /// Returns the purged entries length. Only relevant if [keepPurgedEntries] is true.
  int get purgedLength => _purged != null ? _purged!.length : 0;

  /// Returns [key] value from purged entries. Only relevant if [keepPurgedEntries] is true.
  V? getFromPurgedEntries(K? key) =>
      key == null ? null : (_purged != null ? _purged![key]?.value : null);

  /// Disposes purged entries. Only relevant if [keepPurgedEntries] is true.
  void disposePurgedEntries() {
    _purged = null;
    _expireCache();
  }

  int _purgedEntriesCount = 0;

  int get purgedEntriesCount => _purgedEntriesCount;

  int _unpurgedCount = 0;

  /// Remove all [invalidKeys].
  TreeReferenceMap<K, V> purge() {
    _unpurgedCount = 0;

    final onPurgedEntries = this.onPurgedEntries;

    var changed = false;
    var purgedEntries = <K, V>{};

    if (keepPurgedEntries) {
      revalidatePurgedEntries();
      checkPurgedEntriesTimeout();

      var invalidKeys = this.invalidKeys;
      if (invalidKeys.isEmpty) return this;

      var purged = _purged ?? DualWeakMap(autoPurge: false);
      _purged = purged;

      for (var k in invalidKeys) {
        var val = _map.remove(k);
        _purgedEntriesCount++;
        changed = true;
        if (val != null) {
          purged[k] = MapEntry(DateTime.now(), val);
          if (onPurgedEntries != null) {
            purgedEntries[k] = val;
          }
        }
      }

      checkPurgeEntriesLimit();
    } else {
      for (var k in invalidKeys) {
        var val = _map.remove(k);
        _purgedEntriesCount++;
        changed = true;
        if (val != null && onPurgedEntries != null) {
          purgedEntries[k] = val;
        }
      }
    }

    if (changed) {
      _expireCache();
      if (onPurgedEntries != null) {
        onPurgedEntries(purgedEntries);
      }
    }

    return this;
  }

  /// Same as [purge], but called automatically by many operations.
  bool doAutoPurge() {
    if (!autoPurge) return false;
    if (_unpurgedCount < autoPurgeThreshold) {
      ++_unpurgedCount;
      return false;
    }
    purge();
    return true;
  }

  /// Removed purged entries over [maxPurgedEntries] limit.
  void checkPurgeEntriesLimit() {
    var purged = _purged;
    var maxPurgedEntries = this.maxPurgedEntries;

    if (purged != null && maxPurgedEntries != null && maxPurgedEntries > 0) {
      var needToRemove = purged.length - maxPurgedEntries;
      if (needToRemove > 0) {
        var del = <K>[];
        for (var k in purged.keys) {
          del.add(k);
          if (del.length >= needToRemove) break;
        }

        if (del.isNotEmpty) {
          for (var k in del) {
            purged.remove(k);
          }
          _expireCache();
        }
      }
    }
  }

  /// Remove expired purged entries. Only relevant if [purgedEntriesTimeout] is not null.
  void checkPurgedEntriesTimeout() {
    var purged = _purged;
    var purgedEntriesTimeout = this.purgedEntriesTimeout;

    if (purged != null &&
        purgedEntriesTimeout != null &&
        purgedEntriesTimeout.inMilliseconds > 0) {
      var timeoutMs = purgedEntriesTimeout.inMilliseconds;
      var now = DateTime.now().millisecondsSinceEpoch;

      var expired = purged.entries
          .where((e) => (now - e.value.key.millisecondsSinceEpoch) > timeoutMs)
          .map((e) => e.key)
          .toList(growable: false);

      if (expired.isNotEmpty) {
        for (var k in expired) {
          purged.remove(k);
        }
        _expireCache();
      }
    }
  }

  int _revalidatedPurgedEntriesCount = 0;

  int get revalidatedPurgedEntriesCount => _revalidatedPurgedEntriesCount;

  /// Restore purged entries that are currently valid. Only relevant if [keepPurgedEntries] is true.
  int revalidatePurgedEntries() {
    var purged = _purged;
    if (purged == null) return 0;

    var revalidateCount = 0;

    purged.removeWhere((k, v) {
      var value = v.value;
      if (isValidEntry(k, value)) {
        ++revalidateCount;
        _map[k] = value;
        return true;
      } else {
        return false;
      }
    });

    if (revalidateCount > 0) {
      _expireCache();
      ++_unpurgedCount;
    }

    _revalidatedPurgedEntriesCount += revalidateCount;
    return revalidateCount;
  }

  /// Returns the valid entries.
  List<MapEntry<K, V>> get validEntries =>
      _map.entries.where((e) => isValidEntry(e.key, e.value)).toList();

  /// Returns the invalid entries.
  List<MapEntry<K, V>> get invalidEntries =>
      _map.entries.where((e) => !isValidEntry(e.key, e.value)).toList();

  /// Returns the purged entries. Only relevant if [keepPurgedEntries] is true.
  List<MapEntry<K, V>> get purgedEntries =>
      _purged?.entries.map((e) => MapEntry(e.key, e.value.value)).toList() ??
      <MapEntry<K, V>>[];

  /// Returns the purged keys. Only relevant if [keepPurgedEntries] is true.
  List<K> get purgedKeys => _purged?.keys.toList() ?? <K>[];

  /// Returns the valid keys.
  List<K> get validKeys => _map.entries
      .where((e) => isValidEntry(e.key, e.value))
      .map((e) => e.key)
      .toList();

  /// Returns the invalid keys.
  List<K> get invalidKeys => _map.entries
      .where((e) => !isValidEntry(e.key, e.value))
      .map((e) => e.key)
      .toList();

  /// Walks tree from [root] and stops when [walker] returns some [R] object.
  R? walkTree<R>(R Function(K node) walker, {K? root}) {
    return _walkTreeImpl(root ?? this.root, walker);
  }

  R? _walkTreeImpl<R>(K root, R? Function(K node) walker) {
    final stack = Queue<K>();

    {
      // Push root's children in reverse order
      final rootChildren = getChildrenOf(root);
      for (var i = rootChildren.length - 1; i >= 0; --i) {
        stack.add(rootChildren.elementAt(i));
      }
    }

    while (stack.isNotEmpty) {
      final node = stack.removeLast();
      final result = walker(node);
      if (result != null) return result;

      final children = getChildrenOf(node);
      for (var i = children.length - 1; i >= 0; --i) {
        stack.add(children.elementAt(i));
      }
    }

    return null;
  }

  @override
  String toString() {
    return '{root: $root,'
        ' length: $length,'
        ' purgedLength: $purgedLength,'
        ' purgedEntriesCount: $purgedEntriesCount,'
        ' revalidatedPurgedEntries: $revalidatedPurgedEntriesCount,'
        ' keepPurgedEntries: $keepPurgedEntries,'
        ' purgedEntriesTimeout: ${purgedEntriesTimeout?.inMilliseconds ?? -1}ms,'
        ' maxPurgedEntries: $maxPurgedEntries}';
  }

  @override
  void addAll(Map<K, V> other) {
    _map.addAll(other);
    doAutoPurge();
    _expireCache();
  }

  @override
  bool containsKey(Object? key) {
    doAutoPurge();
    return _map.containsKey(key);
  }

  @override
  bool containsValue(Object? value) {
    doAutoPurge();
    return _map.containsValue(value);
  }

  @override
  V? remove(Object? key) {
    var rm = _map.remove(key);
    doAutoPurge();
    _expireCache();
    return rm;
  }

  @override
  int get length {
    doAutoPurge();
    return _map.length;
  }

  @override
  void clear() {
    _map.clear();
    _expireCache();
    _unpurgedCount = 0;
  }

  List<K>? _keysReversedList;

  /// Returns [keys] reversed (unmodifiable);
  List<K> get keysReversed {
    var keys = _keysReversedList ??= _map.keys.toList().reversed.toList();
    return UnmodifiableListView(keys);
  }

  List<K>? _purgedKeysReversedList;

  /// Returns [purgedKeys] reversed (unmodifiable);
  List<K> get purgedKeysReversed {
    var keys = _purgedKeysReversedList ??=
        _purged?.keys.toList().reversed.toList() ?? [];
    return UnmodifiableListView(keys);
  }

  void _expireCache() {
    _keysReversedList = null;
    _purgedKeysReversedList = null;
  }

  @override
  Iterable<K> get keys {
    doAutoPurge();
    return _map.keys;
  }

  @override
  Iterable<V> get values {
    doAutoPurge();
    return _map.values;
  }

  @override
  V? operator [](Object? key) => key is K ? get(key) : null;

  @override
  void operator []=(K key, V value) => put(key, value);

  @override
  void addEntries(Iterable<MapEntry<K, V>> newEntries) {
    doAutoPurge();
    _map.addEntries(newEntries);
    _expireCache();
  }

  @override
  Iterable<MapEntry<K, V>> get entries {
    doAutoPurge();
    return _map.entries;
  }

  @override
  Map<RK, RV> cast<RK, RV>() {
    doAutoPurge();
    return _map.cast<RK, RV>();
  }

  @override
  void forEach(void Function(K key, V value) f) {
    doAutoPurge();
    _map.forEach(f);
  }

  @override
  bool get isEmpty {
    doAutoPurge();
    return _map.isEmpty;
  }

  @override
  bool get isNotEmpty => !isEmpty;

  @override
  V putIfAbsent(K key, V Function() ifAbsent) {
    doAutoPurge();
    var val = _map.putIfAbsent(key, ifAbsent);
    _expireCache();
    return val;
  }

  @override
  void removeWhere(bool Function(K key, V value) predicate) {
    doAutoPurge();
    _map.removeWhere(predicate);
    _expireCache();
  }

  @override
  V update(K key, V Function(V value) update, {V Function()? ifAbsent}) {
    doAutoPurge();
    var val = _map.update(key, update, ifAbsent: ifAbsent);
    _expireCache();
    return val;
  }

  @override
  void updateAll(V Function(K key, V value) update) {
    doAutoPurge();
    _map.updateAll(update);
    _expireCache();
  }

  @override
  Map<K2, V2> map<K2, V2>(MapEntry<K2, V2> Function(K key, V value) f) {
    doAutoPurge();
    return _map.map(f);
  }
}
