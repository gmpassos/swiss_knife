import 'dart:convert' as dart_convert;

import 'collections.dart';
import 'string.dart';

/// Parses [json] to a JSON tree.
///
/// [def] The default value if [json] is null, empty or a blank String
/// (of any length).
dynamic parseJSON(Object? json, [Object? def]) {
  if (json == null) return def;

  if (json is String) {
    // `isBlankString` stops at the first non-blank char (cheap for a JSON).
    if (json.isEmpty || isBlankString(json)) return def;
    return dart_convert.json.decode(json);
  } else {
    return json;
  }
}

/// Encodes [json] to a JSON string.
///
/// [withIndent] If true applies [ident].
/// [indent] By default uses 2 spaces: `  `.
/// [clearNullEntries] If true will apply [removeNullEntries] and remove any null entry in tree.
/// [toEncodable] Function to transform an object to JSON.
String encodeJSON(
  Object? json, {
  String? indent,
  bool withIndent = false,
  bool clearNullEntries = false,
  Object? Function(Object? object) toEncodable = toEncodableJSON,
}) {
  if (clearNullEntries) {
    removeNullEntries(json);
  }

  if (withIndent && (indent == null || indent.isEmpty)) {
    indent = '  ';
  }

  dart_convert.JsonEncoder encoder;

  if (indent != null && indent.isNotEmpty) {
    encoder = dart_convert.JsonEncoder.withIndent(indent, toEncodable);
  } else {
    encoder = dart_convert.JsonEncoder(toEncodable);
  }

  return encoder.convert(json);
}

/// Remove null entries from [json] tree.
T? removeNullEntries<T>(T? json) {
  if (json == null) return null;

  if (json is List) {
    json.removeWhere((e) => e == null);
    json.forEach(removeNullEntries);
  } else if (json is Map) {
    json.removeWhere((key, value) => key == null || value == null);
    json.values.forEach(removeNullEntries);
  }

  return json;
}

/// Returns [true] if [value] is a JSON.
bool isJSON(Object? value) {
  return isJSONPrimitive(value) || isJSONList(value) || isJSONMap(value);
}

/// Returns [true] if [value] is a JSON primitive (String, bool, num, int, double, or null).
bool isJSONPrimitive(Object? value) {
  return value == null || value is String || value is num || value is bool;
}

/// Returns [true] if [value] is a JSON List.
bool isJSONList(Object? json) {
  if (json == null) return false;

  if (json is List<String>) return true;
  if (json is List<num>) return true;
  if (json is List<int>) return true;
  if (json is List<double>) return true;
  if (json is List<bool>) return true;

  if (json is List) {
    return json.isEmpty || listMatchesAll(json, isJSON);
  }

  return false;
}

/// Returns [true] if [value] is a JSON `Map<String,?>`.
bool isJSONMap(Object? json) {
  if (json == null) return false;

  if (json is Map<String, String>) return true;
  if (json is Map<String, num>) return true;
  if (json is Map<String, int>) return true;
  if (json is Map<String, double>) return true;
  if (json is Map<String, bool>) return true;

  if (json is Map) {
    if (json.isEmpty) return true;
    if (!isMapOfStringKeys(json)) return false;
    return listMatchesAll(json.values, isJSON);
  }

  return false;
}

/// Ensures that [o] is an encodable JSON tree.
Object? toEncodableJSON(Object? o) {
  if (o == null) return null;
  if (o is num) return o;
  if (o is bool) return o;
  if (o is String) return o;

  if (o is List) return toEncodableJSONList(o);
  if (o is Map) return toEncodableJSONMap(o);
  if (o is Set) return toEncodableJSONList(o.toList());

  Object encodable;
  try {
    dynamic d = o;
    if (d.toJson != null) {
      encodable = d.toJson();
    } else {
      encodable = o.toString();
    }
  } catch (e) {
    encodable = o.toString();
  }

  return toEncodableJSON(encodable);
}

/// Ensures that [list] is an encodable JSON tree.
List toEncodableJSONList(List? list) {
  if (list == null) return [];

  if (list is List<num>) return list;
  if (list is List<int>) return list;
  if (list is List<double>) return list;
  if (list is List<bool>) return list;
  if (list is List<String>) return list;

  if (list is List<List<num>>) return list;
  if (list is List<List<int>>) return list;
  if (list is List<List<double>>) return list;
  if (list is List<List<bool>>) return list;
  if (list is List<List<String>>) return list;

  if (list is List<Map<String, num>>) return list;
  if (list is List<Map<String, int>>) return list;
  if (list is List<Map<String, double>>) return list;
  if (list is List<Map<String, bool>>) return list;
  if (list is List<Map<String, String>>) return list;

  if (list.isEmpty) return <dynamic>[];

  if (isListEntriesAllOfType(list, int)) return List<int>.from(list);
  if (isListEntriesAllOfType(list, double)) return List<double>.from(list);
  // Mixed `int` and `double` values (no value has `runtimeType == num`):
  if (list.every((e) => e is num)) return List<num>.from(list);
  if (isListEntriesAllOfType(list, bool)) return List<bool>.from(list);
  if (isListEntriesAllOfType(list, String)) return List<String>.from(list);

  return list.map((e) => toEncodableJSON(e)).toList();
}

/// Ensures that [map] is an encodable JSON tree.
Map toEncodableJSONMap(Map? map) {
  if (map == null) return {};

  if (map is Map<String, num>) return map;
  if (map is Map<String, int>) return map;
  if (map is Map<String, double>) return map;
  if (map is Map<String, bool>) return map;
  if (map is Map<String, String>) return map;

  if (map.isEmpty) return <String, dynamic>{};

  if (map is Map<String, List<num>>) return map;
  if (map is Map<String, List<int>>) return map;
  if (map is Map<String, List<double>>) return map;
  if (map is Map<String, List<bool>>) return map;
  if (map is Map<String, List<String>>) return map;

  // Homogeneous values: returns a typed copy (`Map<String, int>`, ...).
  if (map is Map<String, Object> || map is Map<String, dynamic>) {
    var values = map.values;

    if (isListEntriesAllOfType(values, int)) {
      return _typedJSONMap<int>(map);
    } else if (isListEntriesAllOfType(values, double)) {
      return _typedJSONMap<double>(map);
    } else if (values.every((e) => e is num)) {
      // Mixed `int` and `double` values (no value has `runtimeType == num`):
      return _typedJSONMap<num>(map);
    } else if (isListEntriesAllOfType(values, bool)) {
      return _typedJSONMap<bool>(map);
    } else if (isListEntriesAllOfType(values, String)) {
      return _typedJSONMap<String>(map);
    }
  }

  return map.map((key, value) => MapEntry('$key', toEncodableJSON(value)));
}

Map<String, V> _typedJSONMap<V>(Map map) => map.map<String, V>(
  (key, value) => MapEntry<String, V>(key as String, value as V),
);

/// Returns [true] if [s] is a encoded JSON String of a primitive value.
bool isEncodedJSON(String? s) {
  if (s == null) return false;
  s = s.trim();
  if (s.isEmpty) return false;

  return _isEncodedJSONPrimitive(s) ||
      _isEncodedJSONList(s) ||
      _isEncodedJSONMap(s);
}

/// Returns [true] if [s] is a encoded JSON String of a primitive value.
bool isEncodedJSONPrimitive(String? s) {
  if (s == null) return false;
  s = s.trim();
  if (s.isEmpty) return false;

  return _isEncodedJSONPrimitive(s);
}

bool _isEncodedJSONPrimitive(String s) {
  return _isEncodedJSONString(s) ||
      _isEncodedJSONBoolean(s) ||
      _isEncodedJSONNumber(s) ||
      _isEncodedJSONNull(s);
}

/// Returns [true] if [s] is a encoded JSON `null`.
bool isEncodedJSONNull(String? s) {
  if (s == null) return false;
  s = s.trim();
  return _isEncodedJSONNull(s);
}

bool _isEncodedJSONNull(String s) => s == 'null';

/// Returns [true] if [s] is a encoded JSON [bool].
bool isEncodedJSONBoolean(String? s) {
  if (s == null) return false;
  s = s.trim();
  return _isEncodedJSONBoolean(s);
}

bool _isEncodedJSONBoolean(String s) => s == 'true' || s == 'false';

/// Returns [true] if [s] is a encoded JSON [num] (surrounding blanks are
/// ignored). Tokens that are not valid JSON numbers, such as `NaN`,
/// `Infinity`, `0x1F`, `+1`, `.5`, `1.` or `01`, return `false`.
bool isEncodedJSONNumber(String? s) {
  if (s == null) return false;
  s = s.trim();
  if (s.isEmpty) return false;
  return _isEncodedJSONNumber(s);
}

/// A JSON number (RFC 8259): an optional minus sign, an integer part without
/// leading zeros, an optional fraction and an optional exponent.
final RegExp _regExpJSONNumber = RegExp(
  r'^-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][-+]?\d+)?$',
);

bool _isEncodedJSONNumber(String s) => _regExpJSONNumber.hasMatch(s);

/// Returns [true] if [s] is a encoded JSON [String].
bool isEncodedJSONString(String? s) {
  if (s == null) return false;
  s = s.trim();
  return _isEncodedJSONString(s);
}

bool _isEncodedJSONString(String s) {
  if (s == '""') return true;

  if (s.startsWith('"') && s.endsWith('"')) {
    try {
      var list = parseJSON(s);
      return list is String;
    } catch (e) {
      return false;
    }
  }

  return false;
}

/// Returns [true] if [s] is a encoded JSON [List].
bool isEncodedJSONList(String? s) {
  if (s == null) return false;
  s = s.trim();
  if (s.isEmpty) return false;
  return _isEncodedJSONList(s);
}

bool _isEncodedJSONList(String s) {
  if (!s.startsWith('[') || !s.endsWith(']')) return false;

  try {
    var list = parseJSON(s);
    return list is List;
  } catch (e) {
    return false;
  }
}

/// Returns [true] if [s] is a encoded JSON [Map].
bool isEncodedJSONMap(String? s) {
  if (s == null) return false;
  s = s.trim();
  return _isEncodedJSONMap(s);
}

bool _isEncodedJSONMap(String s) {
  if (!s.startsWith('{') || !s.endsWith('}')) return false;

  try {
    var map = parseJSON(s);
    return map is Map;
  } catch (e) {
    return false;
  }
}
