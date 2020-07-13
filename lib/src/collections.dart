import 'dart:collection';
import 'dart:math' as dart_math;

import 'date.dart';
import 'math.dart';

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
      dart_math.Point<num>(parseNum(a), parseNum(b));

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
  String join(String delimiter) {
    return '$a$delimiter$b';
  }

  /// Returns as a [MapEntry].
  MapEntry<T, T> get asMapEntry => MapEntry(a, b);

  /// Returns as a List with [a,b].
  List<T> get asList => [a, b];
}

/// Returns [true] if [o1] and [o2] are equals.
///
/// [deep] If [true] checks the collections deeply.
bool isEquals(dynamic o1, dynamic o2, [bool deep = false]) {
  if (deep != null && deep) {
    return isEqualsDeep(o1, o2);
  } else {
    return o1 == o2;
  }
}

/// Returns [true] if [o1] and [o2] are equals deeply.
bool isEqualsDeep(dynamic o1, dynamic o2) {
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
bool isEqualsAsString(dynamic o1, dynamic o2) {
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
bool isEquivalentList(List l1, List l2,
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

  deep ??= false;

  for (var i = 0; i < l1.length; ++i) {
    var v1 = l1[i];
    var v2 = l2[i];

    if (!isEquals(v1, v2, deep)) return false;
  }

  return true;
}

/// Same as [isEquivalentList] but for [Iterable].
bool isEquivalentIterator(Iterable it1, Iterable it2, {bool deep = false}) {
  if (it1 == it2) return true;

  if (it1 == null) return false;
  if (it2 == null) return false;

  var length = it1.length;
  if (length != it2.length) return false;

  deep ??= false;

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
bool isEquivalentMap(Map m1, Map m2, {bool deep = false}) {
  if (m1 == m2) return true;

  if (m1 == null) return false;
  if (m2 == null) return false;

  if (m1.length != m2.length) return false;

  var k1 = List.from(m1.keys);
  var k2 = List.from(m2.keys);

  if (!isEquivalentList(k1, k2, sort: true)) return false;

  deep ??= false;

  for (var k in k1) {
    var v1 = m1[k];
    var v2 = m2[k];

    if (!isEquals(v1, v2, deep)) return false;
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
bool isAllEquals(dynamic element, dynamic value, [bool deep = false]) {
  if (isEquals(element, value, deep)) {
    return true;
  }

  if (element is List) {
    return isAllEqualsInList(element, value, deep);
  } else if (element is Map) {
    return isAllEqualsInMap(element, value, deep);
  }

  return false;
}

/// Returns [true] if [list] elements are all equals to [value].
///
/// [deep] IF [true] checks deeply collections values.
bool isAllEqualsInList(List list, dynamic value, [bool deep = false]) {
  if (list == null || list.isEmpty) return false;

  deep ??= false;

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
bool isAllEqualsInMap(Map map, dynamic value, [bool deep = false]) {
  if (map == null || map.isEmpty) return false;

  deep ??= false;

  for (var e in map.values) {
    if (!isEquals(e, value, deep)) {
      return false;
    }
  }

  return true;
}

/// Returns [true] if at least ONE [list] element does NOT matches [matcher].
// ignore: use_function_type_syntax_for_parameters
bool listNotMatchesAll<T>(Iterable<T> list, bool matcher(T entry)) {
  var noMatch = list.firstWhere((e) => !matcher(e), orElse: () => null);
  return noMatch != null;
}

/// Returns [true] if all [list] elements matches [matcher].
// ignore: use_function_type_syntax_for_parameters
bool listMatchesAll<T>(Iterable<T> list, bool matcher(T entry)) {
  return !listNotMatchesAll(list, matcher);
}

/// Returns [true] if all [list] elements are of the same type.
bool isListEntriesAllOfSameType(Iterable list) {
  if (list == null || list.isEmpty) return null;
  if (list.length == 1) return true;
  var t = list.first.runtimeType;
  return listMatchesAll(list, (e) => e.runtimeType == t);
}

/// Adds all [values] to [list].
void addAllToList(List list, dynamic values) {
  if (values == null) return;

  if (values is List) {
    list.addAll(values);
  } else {
    list.add(values);
  }
}

/// Joins all parameters to a single list.
List joinLists(List l1,
    [List l2, List l3, List l4, List l5, List l6, List l7, List l8, List l9]) {
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
List copyList(List list) {
  if (list == null) return null;
  return List.from(list);
}

/// Copies [list] as a [List<String>].
List<String> copyListString(List<String> list) {
  if (list == null) return null;
  return List<String>.from(list);
}

/// Copies [map].
Map copyMap(Map map) {
  if (map == null) return null;
  return Map.from(map);
}

/// Copies [map] as a [Map<String,String>].
Map<String, String> copyMapString(Map<String, String> m) {
  if (m == null) return null;
  return Map<String, String>.from(m);
}

/// Gets a [map] entry ignoring key case.
MapEntry<String, V> getEntryIgnoreCase<V>(Map<String, V> map, String key) {
  var val = map[key];
  if (val != null) return MapEntry(key, val);

  if (key == null) return null;

  var keyLC = key.toLowerCase();

  for (var k in map.keys) {
    if (k.toLowerCase() == keyLC) {
      var value = map[k];
      return MapEntry<String, V>(k, value);
    }
  }

  return null;
}

/// Gets a [map] value ignoring [key] case.
V getIgnoreCase<V>(Map<String, V> map, String key) {
  var entry = getEntryIgnoreCase(map, key);
  return entry != null ? entry.value : null;
}

/// Puts a [map] value ignoring [key] case.
V putIgnoreCase<V>(Map<String, V> map, String key, V value) {
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
Map asMap(dynamic o) {
  if (o == null) return null;
  if (o is Map) return o;

  var m = {};

  if (o is List) {
    var sz = o.length;

    for (var i = 0; i < sz; i += 2) {
      dynamic key = o[i];
      dynamic val = o[i + 1];
      m[key] = val;
    }
  } else {
    throw StateError("Can't handle type: " + o);
  }

  return m;
}

/// Returns [o] as a [List<Map>]. Converts it if needed.
List<Map> asListOfMap(dynamic o) {
  if (o == null) return null;
  var l = o as List<dynamic>;
  return l.map((e) => asMap(e)).toList();
}

/// Returns a Map with sorted keys.
Map<K, V> sortMapEntries<K, V>(Map map,
    [int Function(MapEntry<K, V> entry1, MapEntry<K, V> entry2) compare]) {
  // ignore: omit_local_variable_types
  Map<K, V> mapSorted = LinkedHashMap.fromEntries(map.entries.toList()
        ..sort(compare ?? (a, b) => a.key.compareTo(b.key)))
      .cast();

  return mapSorted;
}

////////////////////////////////////////////////////////////////////////////////

/// Returns [true] if [list] is of [String].
bool isListOfStrings(Iterable list) {
  if (list == null || list.isEmpty) return false;

  for (var value in list) {
    if (!(value is String)) return false;
  }

  return true;
}

/// Returns [o] as a [List<String>]. Converts it if needed.
List<String> asListOfString(dynamic o) {
  if (o == null) return null;
  var l = o as List<dynamic>;
  return l.map((e) => e.toString()).toList();
}

/// Returns [o] as a [Map<String,String>]. Converts it if needed.
Map<String, String> asMapOfString(dynamic o) {
  if (o == null) return null;
  var m = o as Map<dynamic, dynamic>;
  return m.map((k, v) => MapEntry('$k', '$v'));
}

final RegExp _toListOfStrings_delimiter = RegExp(r'\s+');

/// Converts [s] to a [List<String>].
/// Converts any collection to a flat list of strings.
List<String> toFlatListOfStrings(dynamic s,
    {Pattern delimiter, bool trim, bool ignoreEmpty}) {
  if (s == null) return [];

  delimiter ??= _toListOfStrings_delimiter;
  trim ??= true;
  ignoreEmpty ??= true;

  List<String> list;

  if (s is String) {
    list = s.split(delimiter);
  } else if (s is Iterable) {
    list = [];

    for (var e in s) {
      if (e == null) continue;

      if (e is String) {
        var l2 = toFlatListOfStrings(e,
            delimiter: delimiter, trim: trim, ignoreEmpty: ignoreEmpty);
        list.addAll(l2);
      } else if (e is Iterable) {
        var l2 = toFlatListOfStrings(e,
            delimiter: delimiter, trim: trim, ignoreEmpty: ignoreEmpty);
        list.addAll(l2);
      } else {
        var str = '$e';
        var l2 = toFlatListOfStrings(str,
            delimiter: delimiter, trim: trim, ignoreEmpty: ignoreEmpty);
        list.addAll(l2);
      }
    }
  } else {
    list = [];
  }

  if (trim) {
    for (var i = 0; i < list.length; ++i) {
      var e = list[i];
      if (e != null) {
        var e2 = e.trim();
        if (e2.length != e.length) {
          list[i] = e2;
        }
      }
    }
  }

  list.removeWhere((e) => e == null || (ignoreEmpty && e.isEmpty));

  return list;
}

/// Returns [true] if [list] elements are all of type [String].
bool isListOfString(Iterable list) {
  if (list == null) return false;
  if (list is List<String>) return true;
  if (list.isEmpty) return false;

  if (listNotMatchesAll(list, (e) => (e is String))) return false;

  return true;
}

/// Returns [true] if [list] elements are all of type [num].
bool isListOfNum(Iterable list) {
  if (list == null) return false;
  if (list is List<num>) return true;
  if (list.isEmpty) return false;

  if (listNotMatchesAll(list, (e) => (e is num))) return false;

  return true;
}

typedef TypeTester<T> = bool Function(T value);

/// Returns [true] if [list] elements are all of type [T].
bool isListOfType<T>(Iterable list) {
  if (list == null) return false;
  if (list is List<T>) return true;
  if (list.isEmpty) return false;

  if (listNotMatchesAll(list, (e) => (e is T))) return false;

  return true;
}

/// Returns [true] if [list] elements are all of type [A] or [B].
bool isListOfTypes<A, B>(Iterable list) {
  if (list == null) return false;
  if (list is List<A>) return true;
  if (list is List<B>) return true;
  if (list.isEmpty) return false;

  if (listNotMatchesAll(list, (e) => (e is A) || (e is B))) return false;

  return true;
}

/// Returns [true] if [list] contains elements of type [T].
bool listContainsType<T>(Iterable list) {
  if (list == null) return false;
  if (list is List<T>) return true;
  if (list.isEmpty) return false;

  var found = list.firstWhere((l) => l is T, orElse: () => null);

  return found != null;
}

/// Returns [true] if [list] elements are all of type [List].
bool isListOfList(Iterable list) {
  if (list == null) return false;
  if (list is List<List>) return true;
  if (list.isEmpty) return false;

  if (listNotMatchesAll(list, (e) => (e is List))) return false;

  return true;
}

/// Returns [true] if [list] elements are all of type [List<List>].
bool isListOfListOfList(Iterable list) {
  if (list == null) return false;
  if (list is List<List<List>>) return true;
  if (list.isEmpty) return false;

  if (listNotMatchesAll(list, (e) => isListOfList(e))) return false;

  return true;
}

/// Returns [true] if [list] elements are all of type [Map].
bool isListOfMap(Iterable list) {
  if (list == null) return false;
  if (list is List<Map>) return true;
  if (list.isEmpty) return false;

  if (listNotMatchesAll(list, (e) => (e is Map))) return false;

  return true;
}

/// Returns [true] if [list] elements are all equals to [value].
bool isListValuesAllEquals(Iterable list, [eqValue]) {
  if (list == null) return false;
  if (list.isEmpty) return false;

  eqValue ??= list.first;

  return listMatchesAll(list, (v) => v == eqValue);
}

/// Returns [true] if [list] elements are all equals to value
/// at index [valueIndex].
bool isListOfListValuesAllEquals(Iterable<List> list,
    {dynamic eqValue, int eqValueIndex}) {
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
List<R> parseListOf<T, R>(dynamic s,
    [ParserFunction<T, R> parser, List<R> def]) {
  if (s == null) return def;
  if (s is List) return s.map((e) => parser(e)).toList();
  return [parser(s)];
}

/// Parses [s] to a [List<List<R>>], where [R] is the result of [parse].
///
/// [def] The default value if [s] is invalid.
List<List<R>> parseListOfList<T, R>(dynamic s,
    [ParserFunction<T, R> parser, List<List<R>> def]) {
  if (s == null) return def;
  if (s is List) return s.map((e) => parseListOf(e, parser)).toList();
  return [parseListOf(s, parser)];
}

////////////////////////////////////////////////////////////////////////////////

/// Returns [true] if [map] is [Map<String,String>].
bool isMapOfString(Map map) {
  if (map == null) return false;
  if (map is Map<String, String>) return true;
  if (map.isEmpty) return false;

  if (listNotMatchesAll(map.keys, (k) => (k is String))) return false;
  if (listNotMatchesAll(map.values, (k) => (k is String))) return false;

  return true;
}

/// Returns [true] if [map] has [String] keys.
bool isMapOfStringKeys(Map map) {
  if (map == null) return false;
  if (map is Map<String, String>) return true;
  if (map is Map<String, dynamic>) return true;
  if (map.isEmpty) return false;

  if (listNotMatchesAll(map.keys, (k) => (k is String))) return false;

  return true;
}

/// Returns [true] if [map] has [String] keys and [List] values.
bool isMapOfStringKeysAndListValues(Map map) {
  if (map == null) return false;
  if (map is Map<String, List>) return true;
  if (map is Map<String, List<String>>) return true;
  if (map is Map<String, List<num>>) return true;
  if (map is Map<String, List<dynamic>>) return true;
  if (map.isEmpty) return false;

  if (listNotMatchesAll<MapEntry>(
      map.entries, (e) => (e.key is String) && (e.value is List))) return false;

  return true;
}

/// Returns [true] if [map] has [String] keys and [num] values.
bool isMapOfStringKeysAndNumValues(Map map) {
  if (map == null) return false;
  if (map is Map<String, num>) return true;
  if (map.isEmpty) return false;

  if (listNotMatchesAll<MapEntry>(
      map.entries, (e) => (e.key is String) && (e.value is num))) return false;

  return true;
}

////////////////////////////////////////////////////////////////////////////////

/// Finds in [map] a entry that has one of [keys].
///
/// [ignoreCase] If [true] ignores the case of the keys.
MapEntry<K, V> findKeyEntry<K, V>(Map<K, V> map, List<K> keys,
    [bool ignoreCase]) {
  if (map == null || keys == null) return null;

  ignoreCase ??= false;

  if (ignoreCase) {
    for (var key in keys) {
      if (map.containsKey(key)) return MapEntry(key, map[key]);

      var keyLC = key.toString().toLowerCase();

      for (var k in map.keys) {
        if (k.toString().toLowerCase() == keyLC) {
          var value = map[k];
          return MapEntry<K, V>(k, value);
        }
      }
    }
  } else {
    for (var key in keys) {
      if (map.containsKey(key)) return MapEntry(key, map[key]);
    }
  }

  return null;
}

/// Finds in [map] a value that has one of [keys].
///
/// [ignoreCase] If [true] ignores the case of the keys.
V findKeyValue<K, V>(Map<K, V> map, List<K> keys, [bool ignoreCase]) {
  var entry = findKeyEntry(map, keys, ignoreCase);
  return entry != null ? entry.value : null;
}

/// Finds in [map] a value that is in key path [keyPath]
///
/// [keyDelimiter] The key path delimiter.
/// [isValidValue] validates a matching value.
V findKeyPathValue<V>(Map map, String keyPath,
    {String keyDelimiter = '/', bool Function(dynamic value) isValidValue}) {
  if (map.isEmpty || keyPath == null || keyPath.isEmpty) return null;
  keyDelimiter ??= '/';

  var keys = keyPath.split('/');

  dynamic value = findKeyValue(map, [keys.removeAt(0)], true);
  if (value == null) return null;

  for (var k in keys) {
    if (value is Map) {
      value = findKeyValue(value, [k], true);
    } else if (value is List && isInt(k)) {
      var idx = parseInt(k);
      value = value[idx];
    } else {
      value = null;
    }

    if (value == null) return null;
  }

  if (isValidValue != null) {
    if (isValidValue(value)) {
      return value as V;
    } else {
      return null;
    }
  } else {
    return value as V;
  }
}

/// Finds in [map] a key that has one of [keys].
///
/// [ignoreCase] If [true] ignores the case of the keys.
K findKeyName<K, V>(Map<K, V> map, List<K> keys, [bool ignoreCase]) {
  var entry = findKeyEntry(map, keys, ignoreCase);
  return entry != null ? entry.key : null;
}

/// Returns [true] if [o] is empty. Checks for [String], [List], [Map]
/// [Iterable], [Set] or `o.toString()`.
bool isEmptyObject<T>(T o) {
  if (o == null) return true;

  if (o is String) {
    return o.isEmpty;
  }
  else if (o is List) {
    return o.isEmpty;
  }
  else if (o is Map) {
    return o.isEmpty;
  }
  else if (o is Iterable) {
    return o.isEmpty;
  }
  else if (o is Set) {
    return o.isEmpty;
  } else {
    return o.toString().isEmpty ;
  }
}

/// Returns ![isEmptyObject].
bool isNotEmptyObject<T>(T value) {
  return !isEmptyObject(value) ;
}

typedef ValueValidator<V> = bool Function(V value);

/// Validates [value] and returns [value] or [def].
T resolveValue<T>(T value, T def, [ValueValidator valueValidator]) {
  if (value == null) return def;
  if (def == null) return value;

  valueValidator ??= isNotEmptyObject;
  var valid = valueValidator(value) ?? true;
  return valid ? value : def;
}

typedef StringMapper<T> = T Function(String s);

/// Parses [s] as a inline Map.
///
/// [delimiterPairs] The delimiter for pairs.
/// [delimiterKeyValue] The delimiter for keys and values.
/// [mapperKey] Maps keys to another type.
/// [mapperValue] Maps values to another type.
Map<K, V> parseFromInlineMap<K, V>(String s, Pattern delimiterPairs,
    Pattern delimiterKeyValue, StringMapper mapperKey, StringMapper mapperValue,
    [Map<K, V> def]) {
  if (s == null) return def;
  s = s.trim();
  if (s.isEmpty) return def;

  var pairs = s.split(delimiterPairs);

  var map = <K, V>{};

  for (var pair in pairs) {
    var entry = pair.split(delimiterKeyValue);
    var k = mapperKey(entry[0]);
    var v = mapperValue(entry.length > 1 ? entry[1] : null);
    map[k] = v;
  }

  return map;
}

/// Parses [s] as a inline list.
///
/// [delimiter] Elements delimiter.
/// [mapper] Maps elements to another type.
List<T> parseFromInlineList<T>(String s, Pattern delimiter, StringMapper mapper,
    [List<T> def]) {
  if (s == null) return def;
  s = s.trim();
  if (s.isEmpty) return def;

  var parts = s.split(delimiter);

  var list = <T>[];

  for (var n in parts) {
    list.add(mapper(n));
  }

  return list;
}

/// Parses [v] as [String].
///
/// [def] Default value if [v] is invalid.
String parseString(dynamic v, [String def]) {
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
Map<String, String> parseStringFromInlineMap(dynamic s,
    [Pattern delimiterPairs,
    Pattern delimiterKeyValue,
    Map<String, String> def]) {
  if (s == null) return def;
  if (s is Map) {
    return s.map((k, v) => MapEntry(parseString(k), parseString(v)));
  }
  return parseFromInlineMap(s.toString(), delimiterPairs, delimiterKeyValue,
      parseString, parseString, def);
}

/// Parses [s] as inline [List<String>].
///
/// [delimiter] The delimiter of elements.
///
/// [def] The default value if [s] is invalid.
List<String> parseStringFromInlineList(dynamic s,
    [Pattern delimiter, List<String> def]) {
  if (s == null) return def;
  if (s is List) return s.map((e) => parseString(e)).toList();
  return parseFromInlineList(s.toString(), delimiter, parseString, def);
}

int deepHashCode(dynamic o) {
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
int deepHashCodeList(List list) {
  if (list == null) return 0;

  var h = 1;

  for (var e in list) {
    h ^= deepHashCode(e);
  }

  return h;
}

/// Computes a hash code inspecting deeply [map].
int deepHashCodeMap(Map map) {
  if (map == null) return 0;

  var h = 1;

  for (var e in map.entries) {
    h ^= deepHashCode(e.key) ^ deepHashCode(e.value);
  }

  return h;
}

/// Deeply copies [o].
T deepCopy<T>(T o) {
  if (o == null) return null;
  if (o is String) return o;
  if (o is num) return o;
  if (o is bool) return o;

  if (o is List) return deepCopyList(o) as T;
  if (o is Map) return deepCopyMap(o) as T;

  return o;
}

/// Deeply copies [list].
List deepCopyList(List l) {
  if (l == null) return null;
  if (l.isEmpty) return [];
  return l.map((e) => deepCopy(e)).toList();
}

/// Deeply copies [map].
Map deepCopyMap(Map map) {
  if (map == null) return null;
  if (map.isEmpty) return {};
  return map.map((k, v) => MapEntry(deepCopy(k), deepCopy(v)));
}

/// A [Map] that delegates to another [_map].
/// Useful to extend [Map] features.
class MapDelegate<K, V> implements Map<K, V> {
  final Map<K, V> _map;

  MapDelegate(this._map);

  Map<K, V> get mainMap => _map;

  @override
  V operator [](Object key) => _map[key];

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
  bool containsKey(Object key) => _map.containsKey(key);

  @override
  bool containsValue(Object value) => _map.containsValue(value);

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
  V putIfAbsent(K key, Function() ifAbsent) => _map.putIfAbsent(key, ifAbsent);

  @override
  V remove(Object key) => _map.remove(key);

  @override
  void removeWhere(bool Function(K key, V value) predicate) =>
      _map.removeWhere(predicate);

  @override
  V update(K key, Function(V value) update, {Function() ifAbsent}) =>
      _map.update(key, update);

  @override
  void updateAll(Function(K key, V value) update) => _map.updateAll(update);

  @override
  Iterable<V> get values => _map.values;
}

/// A [Map] of properties.
class MapProperties extends MapDelegate<String, dynamic> {
  /// Parses [value] to a valid property [value].
  static dynamic parseValue(dynamic value) {
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
      Map<String, String> stringProperties) {
    if (stringProperties == null || stringProperties.isEmpty) return {};
    return stringProperties.map((k, v) => MapEntry(k, parseValue(v)));
  }

  MapProperties() : super({});

  MapProperties.fromProperties(Map<String, dynamic> properties)
      : super(Map.from((properties ?? {})).cast());

  MapProperties.fromStringProperties(Map<String, String> stringProperties)
      : super(parseStringProperties(stringProperties));

  MapProperties.fromMap(Map properties)
      : super((properties ?? {})
            .map((k, v) => MapEntry(parseString(k), parseString(v))));

  /// Gets a property with [key].
  ///
  /// [def] The default value if [key] not found.
  T getProperty<T>(String key, [T def]) {
    var val = findKeyValue(_map, [key], true);
    return val != null ? val as T : def;
  }

  /// Finds a property with [keys].
  ///
  /// [def] The default value if [keys] not found.
  T findProperty<T>(List<String> keys, [T def]) {
    var val = findKeyValue(_map, keys, true);
    return val != null ? val as T : def;
  }

  /// Gets a property with [key].
  ///
  /// [mapper] Maps the value to [T].
  /// [def] The default value if [key] not found.
  // ignore: use_function_type_syntax_for_parameters
  T getPropertyAs<T>(String key, T mapper(dynamic v), [T def]) {
    var val = findKeyValue(_map, [key], true);
    return val != null ? mapper(val) : def;
  }

  /// Finds a property with [keys].
  ///
  /// [mapper] Maps the value to [T].
  /// [def] The default value if [key] not found.
  // ignore: use_function_type_syntax_for_parameters
  T findPropertyAs<T>(List<String> keys, T mapper(dynamic v), [T def]) {
    var val = findKeyValue(_map, keys, true);
    return val != null ? mapper(val) : def;
  }

  /// Gets a property with [key]. Returns the value in lower case and trimmed.
  ///
  /// [def] The default value if [key] not found.
  String getPropertyAsStringTrimLC(String key, [String def]) {
    var val = getPropertyAsStringTrim(key, def);
    return val != null ? val.toLowerCase() : null;
  }

  /// Finds a property with [keys]. Returns the value in lower case and trimmed.
  ///
  /// [def] The default value if [keys] not found.
  String findPropertyAsStringTrimLC(List<String> keys, [String def]) {
    var val = findPropertyAsStringTrim(keys, def);
    return val != null ? val.toLowerCase() : null;
  }

  /// Gets a property with [key]. Returns the value in upper case and trimmed.
  ///
  /// [def] The default value if [key] not found.
  String getPropertyAsStringTrimUC(String key, [String def]) {
    var val = getPropertyAsStringTrim(key, def);
    return val != null ? val.toUpperCase() : null;
  }

  /// Finds a property with [keys]. Returns the value in upper case and trimmed.
  ///
  /// [def] The default value if [keys] not found.
  String findPropertyAsStringTrimUC(List<String> keys, [String def]) {
    var val = findPropertyAsStringTrim(keys, def);
    return val != null ? val.toUpperCase() : null;
  }

  /// Gets a property with [key]. Returns the value trimmed.
  ///
  /// [def] The default value if [key] not found.
  String getPropertyAsStringTrim(String key, [String def]) {
    var val = getPropertyAsString(key, def);
    return val != null ? val.trim() : null;
  }

  /// Finds a property with [keys]. Returns the value trimmed.
  ///
  /// [def] The default value if [keys] not found.
  String findPropertyAsStringTrim(List<String> keys, [String def]) {
    var val = findPropertyAsString(keys, def);
    return val != null ? val.trim() : null;
  }

  /// Gets a property with [key]. Returns the value as [String].
  ///
  /// [def] The default value if [key] not found.
  String getPropertyAsString(String key, [String def]) =>
      getPropertyAs(key, parseString, def);

  /// Gets a property with [key]. Returns the value as [int].
  ///
  /// [def] The default value if [key] not found.
  int getPropertyAsInt(String key, [int def]) =>
      getPropertyAs(key, parseInt, def);

  /// Gets a property with [key]. Returns the value as [double].
  ///
  /// [def] The default value if [key] not found.
  double getPropertyAsDouble(String key, [double def]) =>
      getPropertyAs(key, parseDouble, def);

  /// Gets a property with [key]. Returns the value as [num].
  ///
  /// [def] The default value if [key] not found.
  num getPropertyAsNum(String key, [num def]) =>
      getPropertyAs(key, parseNum, def);

  /// Gets a property with [key]. Returns the value as [bool].
  ///
  /// [def] The default value if [key] not found.
  bool getPropertyAsBool(String key, [bool def]) =>
      getPropertyAs(key, parseBool, def);

  /// Gets a property with [key]. Returns the value as [DateTime].
  ///
  /// [def] The default value if [key] not found.
  DateTime getPropertyAsDateTime(String key, [DateTime def]) =>
      getPropertyAs(key, parseDateTime, def);

  /// Finds a property with [keys]. Returns the value as [String].
  ///
  /// [def] The default value if [keys] not found.
  String findPropertyAsString(List<String> keys, [String def]) =>
      findPropertyAs(keys, parseString, def);

  /// Finds a property with [keys]. Returns the value as [int].
  ///
  /// [def] The default value if [keys] not found.
  int findPropertyAsInt(List<String> keys, [int def]) =>
      findPropertyAs(keys, parseInt, def);

  /// Finds a property with [keys]. Returns the value as [double].
  ///
  /// [def] The default value if [keys] not found.
  double findPropertyAsDouble(List<String> keys, [double def]) =>
      findPropertyAs(keys, parseDouble, def);

  /// Finds a property with [keys]. Returns the value as [num].
  ///
  /// [def] The default value if [keys] not found.
  num findPropertyAsNum(List<String> keys, [num def]) =>
      findPropertyAs(keys, parseNum, def);

  /// Finds a property with [keys]. Returns the value as [bool].
  ///
  /// [def] The default value if [keys] not found.
  bool findPropertyAsBool(List<String> keys, [bool def]) =>
      findPropertyAs(keys, parseBool, def);

  /// Finds a property with [keys]. Returns the value as [DateTime].
  ///
  /// [def] The default value if [keys] not found.
  DateTime findPropertyAsDateTime(List<String> keys, [DateTime def]) =>
      findPropertyAs(keys, parseDateTime, def);

  /// Gets a property with [key] as [List<String>].
  ///
  /// [def] The default value if [key] not found.
  List<String> getPropertyAsStringList(String key, [List<String> def]) =>
      getPropertyAs(key, (v) => parseStringFromInlineList(v, ',', def), def);

  /// Gets a property with [key] as [List<int>].
  ///
  /// [def] The default value if [key] not found.
  List<int> getPropertyAsIntList(String key, [List<int> def]) =>
      getPropertyAs(key, (v) => parseIntsFromInlineList(v, ',', def), def);

  /// Gets a property with [key] as [List<double>].
  ///
  /// [def] The default value if [key] not found.
  List<double> getPropertyAsDoubleList(String key, [List<double> def]) =>
      getPropertyAs(key, (v) => parseDoublesFromInlineList(v, ',', def), def);

  /// Gets a property with [key] as [List<num>].
  ///
  /// [def] The default value if [key] not found.
  List<num> getPropertyAsNumList(String key, [List<num> def]) =>
      getPropertyAs(key, (v) => parseNumsFromInlineList(v, ',', def), def);

  /// Gets a property with [key] as [List<bool>].
  ///
  /// [def] The default value if [key] not found.
  List<bool> getPropertyAsBoolList(String key, [List<bool> def]) =>
      getPropertyAs(key, (v) => parseBoolsFromInlineList(v, ',', def), def);

  /// Gets a property with [key] as [List<DateTime>].
  ///
  /// [def] The default value if [key] not found.
  List<DateTime> getPropertyAsDateTimeList(String key, [List<DateTime> def]) =>
      getPropertyAs(key, (v) => parseDateTimeFromInlineList(v, ',', def), def);

  /// Finds a property with [keys] as [List<String>].
  ///
  /// [def] The default value if [keys] not found.
  List<String> findPropertyAsStringList(List<String> keys,
          [List<String> def]) =>
      findPropertyAs(keys, (v) => parseStringFromInlineList(v, ',', def), def);

  /// Finds a property with [keys] as [List<int>].
  ///
  /// [def] The default value if [keys] not found.
  List<int> findPropertyAsIntList(List<String> keys, [List<int> def]) =>
      findPropertyAs(keys, (v) => parseIntsFromInlineList(v, ',', def), def);

  /// Finds a property with [keys] as [List<int>].
  ///
  /// [def] The default value if [keys] not found.
  List<double> findPropertyAsDoubleList(List<String> keys,
          [List<double> def]) =>
      findPropertyAs(keys, (v) => parseDoublesFromInlineList(v, ',', def), def);

  /// Finds a property with [keys] as [List<num>].
  ///
  /// [def] The default value if [keys] not found.
  List<num> findPropertyAsNumList(List<String> keys, [List<num> def]) =>
      findPropertyAs(keys, (v) => parseNumsFromInlineList(v, ',', def), def);

  /// Finds a property with [keys] as [List<bool>].
  ///
  /// [def] The default value if [keys] not found.
  List<bool> findPropertyAsBoolList(List<String> keys, [List<bool> def]) =>
      findPropertyAs(keys, (v) => parseBoolsFromInlineList(v, ',', def), def);

  /// Finds a property with [keys] as [List<DateTime>].
  ///
  /// [def] The default value if [keys] not found.
  List<DateTime> findPropertyAsDateTimeList(List<String> keys,
          [List<DateTime> def]) =>
      findPropertyAs(
          keys, (v) => parseDateTimeFromInlineList(v, ',', def), def);

  /// Gets a property with [key] as [List<Map>].
  ///
  /// [def] The default value if [key] not found.
  Map<String, String> getPropertyAsStringMap(String key,
          [Map<String, String> def]) =>
      getPropertyAs(
          key, (v) => parseStringFromInlineMap(v, ';', ':', def), def);

  /// Finds a property with [keys] as [List<Map>].
  ///
  /// [def] The default value if [keys] not found.
  Map<String, String> findPropertyAsStringMap(List<String> keys,
          [Map<String, String> def]) =>
      findPropertyAs(
          keys, (v) => parseStringFromInlineMap(v, ';', ':', def), def);

  /// Returns this as a [Map<String,dynamic>].
  Map<String, dynamic> toProperties() {
    return Map.from(_map).cast();
  }

  /// Returns this as a [Map<String,String>].
  Map<String, String> toStringProperties() {
    return _map.map((k, v) => MapEntry(k, parseString(v)));
  }

  /// put property [value] to [key].
  dynamic put(String key, dynamic value) {
    var valueStr = toStringValue(value);

    var prev = this[key];
    this[key] = valueStr;
    return prev;
  }

  /// Returns [value] as a [String].
  static String toStringValue(dynamic value) {
    String valueStr;

    if (value is String) {
      valueStr = value;
    } else if (value is List) {
      valueStr = value.map(toStringValue).join(',');
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
