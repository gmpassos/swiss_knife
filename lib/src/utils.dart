
import 'dart:async';

Future callAsync(int delayMs, function()) {
  return new Future.delayed(new Duration(milliseconds: delayMs), function) ;
}

String encodeQueryString(Map<String,String> parameters) {
  if (parameters == null || parameters.isEmpty) return "" ;

  var pairs = [];

  parameters.forEach((key, value) {
    var pair = Uri.encodeQueryComponent(key) +'='+ Uri.encodeQueryComponent(value);
    pairs.add(pair);
  });

  var queryString = pairs.join('&');
  return queryString;
}

Map<String,String> decodeQueryString(String queryString) {
  if (queryString == null || queryString.isEmpty) return {} ;

  var pairs = queryString.split('&');

  Map<String,String> parameters = {} ;

  for (var pair in pairs) {
    if (pair.isEmpty) continue ;
    var kv = pair.split('=');

    String k = kv[0];
    String v = kv.length > 1 ? kv[1] : '' ;

    k = Uri.decodeQueryComponent(k);
    v = Uri.decodeQueryComponent(v);

    parameters[k] = v ;
  }

  return parameters;
}

String toUpperCaseInitials(String s) {
  if (s == null || s.isEmpty) return s ;
  return s.toLowerCase().replaceAllMapped(new RegExp("(\\s|^)(\\w)"), (m) => "${m[1]}${m[2].toUpperCase()}") ;
}

List<String> split(String s, String delimiter, [int limit]) {
  if (limit == null) return s.split(delimiter) ;
  if (limit < 1) return [s] ;

  int delimiterSz = delimiter.length ;

  if (limit == 1) {
    int idx = s.indexOf(delimiter) ;
    return idx >= 0 ? [ s.substring(0,idx) , s.substring(idx+delimiterSz) ] : [s] ;
  }

  List<String> parts = [] ;

  for (int i = 0; i < limit; i++) {
    int idx = s.indexOf(delimiter) ;

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
