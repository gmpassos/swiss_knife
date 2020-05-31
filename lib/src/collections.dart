import 'dart:collection';
import 'dart:math' as dart_math;

import 'date.dart';
import 'math.dart';

class Pair<T> {
  final T a;

  final T b;

  Pair(this.a, this.b);

  Pair.fromList(List<T> list)
      : this(list[0], list.length > 1 ? list[1] : list[0]);

  Pair<T> swapAB() {
    return Pair(b, a);
  }

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

  bool get aNotNull => a != null;

  bool get bNotNull => b != null;

  String get aAsString => aNotNull ? a.toString() : '';

  String get bAsString => bNotNull ? b.toString() : '';

  @override
  String toString() {
    return '[$a, $b]';
  }

  String join(String delimiter) {
    return '$a$delimiter$b';
  }

  MapEntry<T, T> get asMapEntry => MapEntry(a, b);

  List<T> get asList => [a, b];
}

bool isEquals(dynamic o1, dynamic o2, [bool deep = false]) {
  if (deep != null && deep) {
    return isEqualsDeep(o1, o2);
  } else {
    return o1 == o2;
  }
}

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

bool isEqualsAsString(dynamic o1, dynamic o2) {
  if (identical(o1, o2)) return true;
  if (o1 == o2) return true;
  if (o1 == null || o2 == null) return false;
  var s1 = o1.toString();
  var s2 = o2.toString();
  return s1 == s2;
}

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

// ignore: use_function_type_syntax_for_parameters
bool listNotMatchesAll<T>(Iterable<T> list, bool matcher(T entry)) {
  var noMatch = list.firstWhere((e) => !matcher(e), orElse: () => null);
  return noMatch != null;
}

// ignore: use_function_type_syntax_for_parameters
bool listMatchesAll<T>(Iterable<T> list, bool matcher(T entry)) {
  return !listNotMatchesAll(list, matcher);
}

void addAllToList(List l, dynamic v) {
  if (v == null) return;

  if (v is List) {
    l.addAll(v);
  } else {
    l.add(v);
  }
}

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

List copyList(List l) {
  if (l == null) return null;
  return List.from(l);
}

List<String> copyListString(List<String> l) {
  if (l == null) return null;
  return List<String>.from(l);
}

Map copyMap(Map m) {
  if (m == null) return null;
  return Map.from(m);
}

Map<String, String> copyMapString(Map<String, String> m) {
  if (m == null) return null;
  return Map<String, String>.from(m);
}

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

V getIgnoreCase<V>(Map<String, V> map, String key) {
  var entry = getEntryIgnoreCase(map, key);
  return entry != null ? entry.value : null;
}

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

List<Map> asListOfMap(dynamic o) {
  if (o == null) return null;
  var l = o as List<dynamic>;
  return l.map((e) => asMap(e)).toList();
}

Map<K, V> sortMapEntries<K, V>(Map map,
    [int Function(MapEntry<K, V> entry1, MapEntry<K, V> entry2) compare]) {
  // ignore: omit_local_variable_types
  Map<K, V> mapSorted = LinkedHashMap.fromEntries(map.entries.toList()
        ..sort(compare ?? (a, b) => a.key.compareTo(b.key)))
      .cast();

  return mapSorted;
}

////////////////////////////////////////////////////////////////////////////////

bool isListOfStrings(Iterable list) {
  if (list == null || list.isEmpty) return false;

  for (var value in list) {
    if (!(value is String)) return false;
  }

  return true;
}

List<String> asListOfString(dynamic o) {
  if (o == null) return null;
  var l = o as List<dynamic>;
  return l.map((e) => e.toString()).toList();
}

Map<String, String> asMapOfString(dynamic o) {
  if (o == null) return null;
  var m = o as Map<dynamic, dynamic>;
  return m.map((k, v) => MapEntry('$k', '$v'));
}

final RegExp _toListOfStrings_delimiter = RegExp(r'\s+');

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

bool isListOfString(Iterable list) {
  if (list == null) return false;
  if (list is List<String>) return true;
  if (list.isEmpty) return false;

  if (listNotMatchesAll(list, (e) => (e is String))) return false;

  return true;
}

bool isListOfNum(Iterable list) {
  if (list == null) return false;
  if (list is List<num>) return true;
  if (list.isEmpty) return false;

  if (listNotMatchesAll(list, (e) => (e is num))) return false;

  return true;
}

typedef TypeTester<T> = bool Function(T value);

bool isListOfType<T>(Iterable list) {
  if (list == null) return false;
  if (list is List<T>) return true;
  if (list.isEmpty) return false;

  if (listNotMatchesAll(list, (e) => (e is T))) return false;

  return true;
}

bool isListOfTypes<A, B>(Iterable list) {
  if (list == null) return false;
  if (list is List<A>) return true;
  if (list is List<B>) return true;
  if (list.isEmpty) return false;

  if (listNotMatchesAll(list, (e) => (e is A) || (e is B))) return false;

  return true;
}

bool listContainsType<T>(Iterable list) {
  if (list == null) return false;
  if (list is List<T>) return true;
  if (list.isEmpty) return false;

  var found = list.firstWhere((l) => l is T, orElse: () => null);

  return found != null;
}

bool isListOfList(Iterable list) {
  if (list == null) return false;
  if (list is List<List>) return true;
  if (list.isEmpty) return false;

  if (listNotMatchesAll(list, (e) => (e is List))) return false;

  return true;
}

bool isListOfListOfList(Iterable list) {
  if (list == null) return false;
  if (list is List<List<List>>) return true;
  if (list.isEmpty) return false;

  if (listNotMatchesAll(list, (e) => isListOfList(e))) return false;

  return true;
}

bool isListOfMap(Iterable list) {
  if (list == null) return false;
  if (list is List<Map>) return true;
  if (list.isEmpty) return false;

  if (listNotMatchesAll(list, (e) => (e is Map))) return false;

  return true;
}

bool isAllListValuesEquals(Iterable list, [value]) {
  if (list == null) return false;
  if (list.isEmpty) return false;

  value ??= list.first;

  return listMatchesAll(list, (v) => v == value);
}

bool isAllListOfListValuesEquals(Iterable list, {value, int valueIndex}) {
  if (list == null) return false;
  if (list.isEmpty) return false;

  value ??= valueIndex != null ? list.first[valueIndex] : list.first;

  if (valueIndex != null) {
    return listMatchesAll(list, (v) => v[valueIndex] == value);
  } else {
    return listMatchesAll(list, (v) => v == value);
  }
}

typedef ParserFunction<T, R> = R Function(T value);

List<R> parseListOf<T, R>(dynamic s,
    [ParserFunction<T, R> parser, List<R> def]) {
  if (s == null) return def;
  if (s is List) return s.map((e) => parser(e)).toList();
  return [parser(s)];
}

List<List<R>> parseListOfList<T, R>(dynamic s,
    [ParserFunction<T, R> parser, List<List<R>> def]) {
  if (s == null) return def;
  if (s is List) return s.map((e) => parseListOf(e, parser)).toList();
  return [parseListOf(s, parser)];
}

////////////////////////////////////////////////////////////////////////////////

bool isMapOfString(Map map) {
  if (map == null) return false;
  if (map is Map<String, String>) return true;
  if (map.isEmpty) return false;

  if (listNotMatchesAll(map.keys, (k) => (k is String))) return false;
  if (listNotMatchesAll(map.values, (k) => (k is String))) return false;

  return true;
}

bool isMapOfStringKeys(Map map) {
  if (map == null) return false;
  if (map is Map<String, String>) return true;
  if (map is Map<String, dynamic>) return true;
  if (map.isEmpty) return false;

  if (listNotMatchesAll(map.keys, (k) => (k is String))) return false;

  return true;
}

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

bool isMapOfStringKeysAndNumValues(Map map) {
  if (map == null) return false;
  if (map is Map<String, num>) return true;
  if (map.isEmpty) return false;

  if (listNotMatchesAll<MapEntry>(
      map.entries, (e) => (e.key is String) && (e.value is num))) return false;

  return true;
}

////////////////////////////////////////////////////////////////////////////////

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

V findKeyValue<K, V>(Map<K, V> map, List<K> keys, [bool ignoreCase]) {
  var entry = findKeyEntry(map, keys, ignoreCase);
  return entry != null ? entry.value : null;
}

K findKeyName<K, V>(Map<K, V> map, List<K> keys, [bool ignoreCase]) {
  var entry = findKeyEntry(map, keys, ignoreCase);
  return entry != null ? entry.key : null;
}

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

////////////////////////////////////////////////////////////////////////////////

bool isEmptyValue<T>(T value) {
  if (value == null) return true;

  if (value is String && value.isEmpty) return true;
  if (value is List && value.isEmpty) return true;
  if (value is Map && value.isEmpty) return true;
  if (value is Iterable && value.isEmpty) return true;
  if (value is Set && value.isEmpty) return true;

  return false;
}

typedef ValueValidator<V> = bool Function(V value);

T resolveValue<T>(T value, T def, [ValueValidator valueValidator]) {
  if (value == null) return def;
  if (def == null) return value;

  valueValidator ??= isEmptyValue;
  var valid = valueValidator(value) ?? true;
  return valid ? value : def;
}

typedef StringMapper<T> = T Function(String s);

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

String parseString(dynamic v, [String def]) {
  if (v == null) return def;

  if (v is String) return v;

  var s = v.toString().trim();

  if (s.isEmpty) return def;

  return s;
}

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

int deepHashCodeList(List l) {
  if (l == null) return 0;

  var h = 1;

  for (var e in l) {
    h ^= deepHashCode(e);
  }

  return h;
}

int deepHashCodeMap(Map m) {
  if (m == null) return 0;

  var h = 1;

  for (var e in m.entries) {
    h ^= deepHashCode(e.key) ^ deepHashCode(e.value);
  }

  return h;
}

T deepCopy<T>(T o) {
  if (o == null) return null;
  if (o is String) return o;
  if (o is num) return o;
  if (o is bool) return o;

  if (o is List) return deepCopyList(o) as T;
  if (o is Map) return deepCopyMap(o) as T;

  return o;
}

List deepCopyList(List l) {
  if (l == null) return null;
  if (l.isEmpty) return [];
  return l.map((e) => deepCopy(e)).toList();
}

Map deepCopyMap(Map m) {
  if (m == null) return null;
  if (m.isEmpty) return {};
  return m.map((k, v) => MapEntry(deepCopy(k), deepCopy(v)));
}

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

class MapProperties extends MapDelegate<String, dynamic> {
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

  T getProperty<T>(String key, [T def]) {
    var val = findKeyValue(_map, [key], true);
    return val != null ? val as T : def;
  }

  T findProperty<T>(List<String> keys, [T def]) {
    var val = findKeyValue(_map, keys, true);
    return val != null ? val as T : def;
  }

  // ignore: use_function_type_syntax_for_parameters
  T getPropertyAs<T>(String key, T mapper(dynamic v), [T def]) {
    var val = findKeyValue(_map, [key], true);
    return val != null ? mapper(val) : def;
  }

  // ignore: use_function_type_syntax_for_parameters
  T findPropertyAs<T>(List<String> keys, T mapper(dynamic v), [T def]) {
    var val = findKeyValue(_map, keys, true);
    return val != null ? mapper(val) : def;
  }

  String getPropertyAsStringTrimLC(String key, [String def]) {
    var val = getPropertyAsStringTrim(key, def);
    return val != null ? val.toLowerCase() : null;
  }

  String findPropertyAsStringTrimLC(List<String> keys, [String def]) {
    var val = findPropertyAsStringTrim(keys, def);
    return val != null ? val.toLowerCase() : null;
  }

  String getPropertyAsStringTrimUC(String key, [String def]) {
    var val = getPropertyAsStringTrim(key, def);
    return val != null ? val.toUpperCase() : null;
  }

  String findPropertyAsStringTrimUC(List<String> keys, [String def]) {
    var val = findPropertyAsStringTrim(keys, def);
    return val != null ? val.toUpperCase() : null;
  }

  String getPropertyAsStringTrim(String key, [String def]) {
    var val = getPropertyAsString(key, def);
    return val != null ? val.trim() : null;
  }

  String findPropertyAsStringTrim(List<String> keys, [String def]) {
    var val = findPropertyAsString(keys, def);
    return val != null ? val.trim() : null;
  }

  String getPropertyAsString(String key, [String def]) =>
      getPropertyAs(key, parseString, def);

  int getPropertyAsInt(String key, [int def]) =>
      getPropertyAs(key, parseInt, def);

  double getPropertyAsDouble(String key, [double def]) =>
      getPropertyAs(key, parseDouble, def);

  num getPropertyAsNum(String key, [num def]) =>
      getPropertyAs(key, parseNum, def);

  bool getPropertyAsBool(String key, [bool def]) =>
      getPropertyAs(key, parseBool, def);

  DateTime getPropertyAsDateTime(String key, [DateTime def]) =>
      getPropertyAs(key, parseDateTime, def);

  String findPropertyAsString(List<String> keys, [String def]) =>
      findPropertyAs(keys, parseString, def);

  int findPropertyAsInt(List<String> keys, [int def]) =>
      findPropertyAs(keys, parseInt, def);

  double findPropertyAsDouble(List<String> keys, [double def]) =>
      findPropertyAs(keys, parseDouble, def);

  num findPropertyAsNum(List<String> keys, [num def]) =>
      findPropertyAs(keys, parseNum, def);

  bool findPropertyAsBool(List<String> keys, [bool def]) =>
      findPropertyAs(keys, parseBool, def);

  DateTime findPropertyAsDateTime(List<String> keys, [DateTime def]) =>
      findPropertyAs(keys, parseDateTime, def);

  List<String> getPropertyAsStringList(String key, [List<String> def]) =>
      getPropertyAs(key, (v) => parseStringFromInlineList(v, ',', def), def);

  List<int> getPropertyAsIntList(String key, [List<int> def]) =>
      getPropertyAs(key, (v) => parseIntsFromInlineList(v, ',', def), def);

  List<double> getPropertyAsDoubleList(String key, [List<double> def]) =>
      getPropertyAs(key, (v) => parseDoublesFromInlineList(v, ',', def), def);

  List<num> getPropertyAsNumList(String key, [List<num> def]) =>
      getPropertyAs(key, (v) => parseNumsFromInlineList(v, ',', def), def);

  List<bool> getPropertyAsBoolList(String key, [List<bool> def]) =>
      getPropertyAs(key, (v) => parseBoolsFromInlineList(v, ',', def), def);

  List<DateTime> getPropertyAsDateTimeList(String key, [List<DateTime> def]) =>
      getPropertyAs(key, (v) => parseDateTimeFromInlineList(v, ',', def), def);

  List<String> findPropertyAsStringList(List<String> keys,
          [List<String> def]) =>
      findPropertyAs(keys, (v) => parseStringFromInlineList(v, ',', def), def);

  List<int> findPropertyAsIntList(List<String> keys, [List<int> def]) =>
      findPropertyAs(keys, (v) => parseIntsFromInlineList(v, ',', def), def);

  List<double> findPropertyAsDoubleList(List<String> keys,
          [List<double> def]) =>
      findPropertyAs(keys, (v) => parseDoublesFromInlineList(v, ',', def), def);

  List<num> findPropertyAsNumList(List<String> keys, [List<num> def]) =>
      findPropertyAs(keys, (v) => parseNumsFromInlineList(v, ',', def), def);

  List<bool> findPropertyAsBoolList(List<String> keys, [List<bool> def]) =>
      findPropertyAs(keys, (v) => parseBoolsFromInlineList(v, ',', def), def);

  List<DateTime> findPropertyAsDateTimeList(List<String> keys,
          [List<DateTime> def]) =>
      findPropertyAs(
          keys, (v) => parseDateTimeFromInlineList(v, ',', def), def);

  Map<String, String> getPropertyAsStringMap(String key,
          [Map<String, String> def]) =>
      getPropertyAs(
          key, (v) => parseStringFromInlineMap(v, ';', ':', def), def);

  Map<String, String> findPropertyAsStringMap(List<String> keys,
          [Map<String, String> def]) =>
      findPropertyAs(
          keys, (v) => parseStringFromInlineMap(v, ';', ':', def), def);

  Map<String, dynamic> toProperties() {
    return Map.from(_map).cast();
  }

  Map<String, String> toStringProperties() {
    return _map.map((k, v) => MapEntry(k, parseString(v)));
  }

  dynamic put(String key, dynamic value) {
    var valueStr = toStringValue(value);

    var prev = this[key];
    this[key] = valueStr;
    return prev;
  }

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
