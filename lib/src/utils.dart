
import 'dart:async';


/// Calls a function with a [delayMs].
///
/// [delayMs] is milliseconds. If null or <= 0 won't have a delay.
Future callAsync(int delayMs, Function() function) {
  if (delayMs == null || delayMs <= 0) {
    return Future.microtask( function ) ;
  }
  return Future.delayed(Duration(milliseconds: delayMs), function) ;
}

/// Encodes [parameters] as a query string.
String encodeQueryString(Map<String,String> parameters) {
  if (parameters == null || parameters.isEmpty) return '' ;

  var pairs = [];

  parameters.forEach((key, value) {
    var pair = Uri.encodeQueryComponent(key) +'='+ Uri.encodeQueryComponent(value);
    pairs.add(pair);
  });

  var queryString = pairs.join('&');
  return queryString;
}

/// Decodes [queryString] to a [Map<String,String>].
Map<String,String> decodeQueryString(String queryString) {
  if (queryString == null || queryString.isEmpty) return {} ;

  var pairs = queryString.split('&');

  var parameters = <String,String>{} ;

  for (var pair in pairs) {
    if (pair.isEmpty) continue ;
    var kv = pair.split('=');

    var k = kv[0];
    var v = kv.length > 1 ? kv[1] : '' ;

    k = Uri.decodeQueryComponent(k);
    v = Uri.decodeQueryComponent(v);

    parameters[k] = v ;
  }

  return parameters;
}

/// Formats [s] with initial character to Upper case.
String toUpperCaseInitials(String s) {
  if (s == null || s.isEmpty) return s ;
  return s.toLowerCase().replaceAllMapped(RegExp(r'(\s|^)(\S)'), (m) => '${ m[1] }${ m[2].toUpperCase() }') ;
}

/// Formats [s] with camel case style.
String toCamelCase(String s) {
  return toUpperCaseInitials(s).replaceAll(RegExp(r'\s+'), '') ;
}

/// Splits [s] using [delimiter] and [limit].
///
/// [delimiter] String to use to split [s].
/// [limit] The maximum elements to return.
///
/// Note: Standard Dart split doesn't have [limit] parameter.
List<String> split(String s, String delimiter, [int limit]) {
  if (limit == null) return s.split(delimiter) ;
  if (limit == 1) return [s] ;

  var delimiterSz = delimiter.length ;

  if (limit == 2) {
    var idx = s.indexOf(delimiter) ;
    return idx >= 0 ? [ s.substring(0,idx) , s.substring(idx+delimiterSz) ] : [s] ;
  }

  if (limit <= 0) limit = s.length ;

  var parts = <String>[] ;

  limit-- ;

  for (var i = 0; i < limit; i++) {
    var idx = s.indexOf(delimiter) ;

    if (idx >= 0) {
      var s1 = s.substring(0, idx) ;
      var s2 = s.substring(idx+delimiterSz) ;

      parts.add(s1) ;
      s = s2 ;
    }
    else {
      break ;
    }
  }

  parts.add(s) ;
  return parts ;
}
