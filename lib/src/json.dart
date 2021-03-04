import 'dart:convert' as dart_convert;

import 'package:swiss_knife/src/string.dart';
import 'package:swiss_knife/swiss_knife.dart';

import 'collections.dart';

/// Parses [json] to a JSON tree.
///
/// [def] The default value if [json] is null, empty or a blank String.
dynamic parseJSON(dynamic json, [dynamic def]) {
  if (json == null) return def;

  if (json is String) {
    if (json.isEmpty || (json.length < 100 && isBlankString(json))) return def;
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
String encodeJSON(dynamic json,
    {String indent,
    bool withIndent,
    bool clearNullEntries,
    Object Function(dynamic object) toEncodable}) {
  clearNullEntries ??= false;
  if (clearNullEntries) {
    removeNullEntries(json);
  }

  if (withIndent != null && withIndent) {
    if (indent == null || indent.isEmpty) {
      indent = '  ';
    }
  }

  toEncodable ??= toEncodableJSON;

  dart_convert.JsonEncoder encoder;

  if (indent != null && indent.isNotEmpty) {
    encoder = dart_convert.JsonEncoder.withIndent(indent, toEncodable);
  } else {
    encoder = dart_convert.JsonEncoder(toEncodable);
  }

  return encoder.convert(json);
}

/// Remove null entries from [json] tree.
T removeNullEntries<T>(T json) {
  if (json == null) return json;

  if (json is List) {
    json.removeWhere((e) => null);
    json.forEach(removeNullEntries);
  } else if (json is Map) {
    json.removeWhere((key, value) => key == null || value == null);
    json.values.forEach(removeNullEntries);
  }

  return json;
}

/// Returns [true] if [value] is a JSON.
bool isJSON(dynamic value) {
  return isJSONPrimitive(value) || isJSONList(value) || isJSONMap(value);
}

/// Returns [true] if [value] is a JSON primitive (String, bool, num, int, double, or null).
bool isJSONPrimitive(dynamic value) {
  return value == null || value is String || value is num || value is bool;
}

/// Returns [true] if [value] is a JSON List.
bool isJSONList(dynamic json) {
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

/// Returns [true] if [value] is a JSON Map<String,?>.
bool isJSONMap(dynamic json) {
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
dynamic toEncodableJSON(dynamic o) {
  if (o == null) return null;
  if (o is num) return o;
  if (o is bool) return o;
  if (o is String) return o;

  if (o is List) return toEncodableJSONList(o);
  if (o is Map) return toEncodableJSONMap(o);
  if (o is Set) return toEncodableJSONList(o.toList());

  dynamic encodable;
  try {
    if (o.toJson != null) {
      encodable = o.toJson();
    } else {
      encodable = o.toString();
    }
  } catch (e) {
    encodable = o.toString();
  }

  return toEncodableJSON(encodable);
}

/// Ensures that [list] is an encodable JSON tree.
List toEncodableJSONList(List list) {
  if (list == null) return null;

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

  if (isListEntriesAllOfType(list, num)) return List<num>.from(list);
  if (isListEntriesAllOfType(list, int)) return List<int>.from(list);
  if (isListEntriesAllOfType(list, double)) return List<double>.from(list);
  if (isListEntriesAllOfType(list, bool)) return List<bool>.from(list);
  if (isListEntriesAllOfType(list, String)) return List<String>.from(list);

  return list.map((e) => toEncodableJSON(e)).toList();
}

/// Ensures that [map] is an encodable JSON tree.
Map toEncodableJSONMap(Map map) {
  if (map == null) return null;

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

  if (map is Map<String, Object> || map is Map<String, dynamic>) {
    var values = map.values.toList();

    if (isListEntriesAllOfType(values, num)) {
      return map.map((key, value) => MapEntry(key, value as num));
    } else if (isListEntriesAllOfType(values, int)) {
      return map.map((key, value) => MapEntry(key, value as int));
    } else if (isListEntriesAllOfType(values, double)) {
      return map.map((key, value) => MapEntry(key, value as double));
    } else if (isListEntriesAllOfType(values, bool)) {
      return map.map((key, value) => MapEntry(key, value as bool));
    } else if (isListEntriesAllOfType(values, String)) {
      return map.map((key, value) => MapEntry(key, value as String));
    }
  }

  return map.map((key, value) => MapEntry('$key', toEncodableJSON(value)));
}

/// Returns [true] if [s] is a encoded JSON String of a primitive value.
bool isEncodedJSON(String s) {
  if (s == null) return false;
  s = s.trim();
  if (s.isEmpty) return false;

  return _isEncodedJSONPrimitive(s) ||
      _isEncodedJSONList(s) ||
      _isEncodedJSONMap(s);
}

/// Returns [true] if [s] is a encoded JSON String of a primitive value.
bool isEncodedJSONPrimitive(String s) {
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
bool isEncodedJSONNull(String s) {
  if (s == null) return false;
  s = s.trim();
  return _isEncodedJSONNull(s);
}

bool _isEncodedJSONNull(String s) => s == 'null';

/// Returns [true] if [s] is a encoded JSON [bool].
bool isEncodedJSONBoolean(String s) {
  if (s == null) return false;
  s = s.trim();
  return _isEncodedJSONBoolean(s);
}

bool _isEncodedJSONBoolean(String s) => s == 'true' || s == 'false';

/// Returns [true] if [s] is a encoded JSON [num].
bool isEncodedJSONNumber(String s) {
  if (s == null) return false;
  s = s.trim();
  if (s.isEmpty) return false;
  return _isEncodedJSONNumber(s);
}

bool _isEncodedJSONNumber(String s) {
  return isNum(s);
}

/// Returns [true] if [s] is a encoded JSON [String].
bool isEncodedJSONString(String s) {
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
bool isEncodedJSONList(String s) {
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
bool isEncodedJSONMap(String s) {
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
