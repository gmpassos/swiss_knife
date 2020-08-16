import 'dart:convert' as dart_convert;

import 'package:swiss_knife/src/string.dart';
import 'package:swiss_knife/swiss_knife.dart';

import 'collections.dart';

/// Parses [json].
///
/// [def] The default value if [json] is null, empty or blank String.
dynamic parseJSON(dynamic json, [dynamic def]) {
  if (json == null) return def;

  if (json is String) {
    if (json.isEmpty || (json.length < 100 && isBlankString(json))) return def;
    return dart_convert.json.decode(json);
  } else {
    return json;
  }
}

/// Encodes [json].
String encodeJSON(dynamic json,
    {String ident, bool withIdent, bool clearNullEntries}) {
  clearNullEntries ??= false;
  if (clearNullEntries) {
    removeNullEntries(json);
  }

  if (withIdent != null && withIdent) {
    if (ident == null || ident.isEmpty) {
      ident = '  ';
    }
  }

  dart_convert.JsonEncoder encoder;

  if (ident != null && ident.isNotEmpty) {
    encoder = dart_convert.JsonEncoder.withIndent(ident);
  } else {
    encoder = dart_convert.JsonEncoder();
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
  if (json is List<bool>) return true;

  if (json is List) {
    return listMatchesAll(json, isJSON);
  }

  return false;
}

/// Returns [true] if [value] is a JSON Map<String,?>.
bool isJSONMap(dynamic json) {
  if (json == null) return false;

  if (json is Map<String, String>) return true;
  if (json is Map<String, num>) return true;
  if (json is Map<String, bool>) return true;

  if (json is Map) {
    if (!isMapOfStringKeys(json)) return false;
    return listMatchesAll(json.values, isJSON);
  }

  return false;
}
