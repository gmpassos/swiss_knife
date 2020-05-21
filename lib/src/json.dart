
import 'collections.dart';

bool isJSON(dynamic json) {
  return isJSONPrimitive(json) || isJSONList(json) || isJSONMap(json) ;
}

bool isJSONPrimitive(dynamic json) {
  return json == null || json is String || json is num || json is bool ;
}

bool isJSONList(dynamic json) {
  if (json == null) return false ;

  if (json is List<String>) return true ;
  if (json is List<num>) return true ;
  if (json is List<bool>) return true ;

  if (json is List) {
    return listMatchesAll(json, isJSON) ;
  }

  return false ;
}

bool isJSONMap(dynamic json) {
  if (json == null) return false ;

  if (json is Map<String,String>) return true ;
  if (json is Map<String,num>) return true ;
  if (json is Map<String,bool>) return true ;

  if (json is Map) {
    if ( !isMapOfStringKeys( json ) ) return false ;
    return listMatchesAll(json.values, isJSON) ;
  }

  return false ;
}

