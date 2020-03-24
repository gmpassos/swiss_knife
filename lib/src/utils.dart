
import 'dart:async';

import 'package:swiss_knife/src/collections.dart';

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

bool regExpHasMatch(dynamic regExp, String s) {
  var theRegExp = regExp is RegExp ? regExp : RegExp(regExp) ;
  return theRegExp.hasMatch(s);
}

class RegExpReplacer {
  List _parts ;

  RegExpReplacer(String replace) {
    var matches = RegExp(r'(?:\$(\d+)|\${(\d+)})').allMatches(replace) ;

    _parts = [] ;

    int cursor = 0 ;
    for (var match in matches) {
      if ( match.start > cursor ) {
        String sPrev = replace.substring(cursor , match.start) ;
        _parts.add(sPrev) ;
      }

      var g1 = match.group(1);
      var g2 = match.group(2);

      var id = g1 ?? g2 ;

      int groupID = int.parse(id) ;

      _parts.add(groupID) ;

      cursor = match.end ;
    }

    if ( cursor < replace.length ) {
      var sEnd = replace.substring(cursor) ;
      _parts.add(sEnd) ;
    }
  }

  String replaceMatch( Match match ) {
    String s = '';

    for (var part in _parts) {
      if (part is int) {
        var groupValue = match.group(part) ;
        if (groupValue != null) {
          s += groupValue ;
        }
      }
      else {
        s += part ;
      }
    }

    return s ;
  }

  String replaceAll( dynamic regExp , String s ) {
    var theRegExp = regExp is RegExp ? regExp : RegExp(regExp) ;
    return s.replaceAllMapped(theRegExp, replaceMatch) ;
  }

}

String regExpReplaceAll(dynamic regExp, String s, String replace) {
  return RegExpReplacer( replace ).replaceAll(regExp, s) ;
}

String regExpReplaceAllMapped(dynamic regExp, String s, String replace(Match match)) {
  return s.replaceAllMapped(regExp, replace) ;
}

RegExp regExpDialect( Map<String,String> words , String pattern , { bool multiLine = false, bool caseSensitive = true}) {
  for (var i = 0 ; i < 10 ; i++) {
    var words2 = words.map((k, v) => MapEntry(k, _regExpDialectImpl(words, v).pattern));
    if ( isEqualsDeep(words, words2)) break ;
    words = words2 ;
  }
  return _regExpDialectImpl(words, pattern) ;
}

RegExp _regExpDialectImpl( Map<String,String> words , String pattern , { bool multiLine = false, bool caseSensitive = true}) {
  var translated = pattern.replaceAllMapped(RegExp(r'(\\\$|\$)(\w+)'), (m) {
    var mark = m.group(1) ;
    var key = m.group(2) ;

    if (mark == r'\$') return '$mark$key' ;

    var value = words[key] ;
    return value ?? '$mark$key' ;
  });
  return RegExp(translated, multiLine: multiLine, caseSensitive: caseSensitive);
}

bool isHttpURL(String s) {
  if (s == null) return false ;
  s = s.trim() ;
  if (s.isEmpty) return false ;
  return s.startsWith("http") && ( s.startsWith("http://") || s.startsWith("https://") ) ;
}

String getPathExtension(String path) {
  if (path == null) return null ;
  path = path.trim() ;
  if (path.isEmpty) return null ;

  int idx = path.lastIndexOf('.') ;
  if (idx < 0) return null ;
  var ext = path.substring(idx+1) ;
  return ext.isNotEmpty ? ext : null ;
}


String buildStringPattern(String pattern, Map parameters, [ List<Map> extraParameters ]) {
  if (pattern == null) return null ;

  var matches = RegExp(r'{{(/?\w+(?:/\w+)*/?)}}').allMatches(pattern) ;

  var strFilled = '' ;

  var pos = 0 ;
  for (var match in matches) {
    var prev = pattern.substring(pos, match.start) ;
    strFilled += prev ;

    var varName = match.group(1) ;

    while (varName.startsWith('/')) {
      varName = varName.substring(1) ;
    }

    while (varName.endsWith('/')) {
      varName = varName.substring(0, varName.length-1) ;
    }

    var val = findKeyPathValue(parameters, varName) ;

    if (val == null && extraParameters != null) {
      for (var parameters2 in extraParameters) {
        val = findKeyPathValue(parameters2, varName) ;
      }
    }

    strFilled += '$val' ;

    pos = match.end ;
  }

  if (pos < pattern.length) {
    var prev = pattern.substring(pos) ;
    strFilled += prev ;
  }

  return strFilled ;
}


