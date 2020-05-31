import 'collections.dart';

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
