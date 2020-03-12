
import 'dart:async';

Future callAsync(int delayMs, function()) {
  return Future.delayed(Duration(milliseconds: delayMs), function) ;
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
  return s.toLowerCase().replaceAllMapped(RegExp("(\\s|^)(\\w)"), (m) => "${m[1]}${m[2].toUpperCase()}") ;
}

List<String> split(String s, String delimiter, [int limit]) {
  if (limit == null) return s.split(delimiter) ;
  if (limit == 1) return [s] ;

  int delimiterSz = delimiter.length ;

  if (limit == 2) {
    int idx = s.indexOf(delimiter) ;
    return idx >= 0 ? [ s.substring(0,idx) , s.substring(idx+delimiterSz) ] : [s] ;
  }

  if (limit <= 0) limit = s.length ;

  List<String> parts = [] ;

  limit-- ;

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

List<String> splitRegExp(String s, Pattern delimiter, [int limit]) {
  if (limit == null) return s.split(delimiter) ;
  if (limit == 1) return [s] ;

  if (limit == 2) {
    for ( var match in delimiter.allMatches(s) ) {
      var s1 = s.substring(0 , match.start) ;
      var s2 = s.substring( match.end ) ;
      return [s1,s2] ;
    }
    return [s] ;
  }

  if (limit <= 0) limit = s.length ;

  List<String> parts = [] ;

  int sOffset = 0 ;

  --limit ;

  for ( var match in delimiter.allMatches(s) ) {
    var start = match.start - sOffset;
    var end = match.end - sOffset ;

    var s1 = s.substring(0, start) ;
    var s2 = s.substring(end) ;

    parts.add(s1) ;

    s = s2 ;
    sOffset = match.end ;

    if ( parts.length == limit ) {
      break ;
    }
  }

  parts.add(s) ;

  return parts ;
}


