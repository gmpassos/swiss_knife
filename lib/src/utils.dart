
import 'dart:async';

import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class Math {

  static num min(num a, num b) => a < b ? a : b ;
  static num max(num a, num b) => a > b ? a : b ;

}

bool isListOfStrings(List list) {
  if (list == null || list.isEmpty) return false ;

  for (var value in list) {
    if ( !(value is String) ) return false ;
  }

  return true ;
}

bool isEquivalentList(List l1, List l2, [bool sort = false]) {
  if (l1 == l2) return true ;

  if (l1 == null) return false ;
  if (l2 == null) return false ;

  if ( l1.length != l2.length ) return false ;

  if (sort) {
    l1.sort();
    l2.sort();
  }

  for (var i = 0; i < l1.length; ++i) {
    var v1 = l1[i];
    var v2 = l2[i];
    if (v1 != v2) return false ;
  }

  return true ;
}

bool isEquivalentMap(Map m1, Map m2) {
  if (m1 == m2) return true ;

  if (m1 == null) return false ;
  if (m2 == null) return false ;

  var k1 = new List.from(m1.keys);
  var k2 = new List.from(m2.keys);

  if ( !isEquivalentList(k1,k2,true) ) return false ;

  for (var k in k1) {
    var v1 = m1[k];
    var v2 = m2[k];

    if ( v1 != v2 ) return false ;
  }

  return true ;
}

void addAllToList(List l, dynamic v) {
  if (v == null) return ;

  if (v is List) {
    l.addAll(v);
  }
  else {
    l.add(v);
  }
}

List joinLists(List l1, [List l2, List l3, List l4, List l5, List l6, List l7, List l8, List l9]) {
  List l = [] ;

  if (l1 != null) l.addAll(l1) ;
  if (l2 != null) l.addAll(l2) ;
  if (l3 != null) l.addAll(l3) ;
  if (l4 != null) l.addAll(l4) ;
  if (l5 != null) l.addAll(l5) ;
  if (l6 != null) l.addAll(l6) ;
  if (l7 != null) l.addAll(l7) ;
  if (l8 != null) l.addAll(l8) ;
  if (l9 != null) l.addAll(l9) ;

  return l ;
}

List copyList(List l) {
  if (l == null) return null ;
  return new List.from(l);
}

List<String> copyListString(List<String> l) {
  if (l == null) return null ;
  return new List<String>.from(l);
}

Map copyMap(Map m) {
  if (m == null) return null ;
  return new Map.from(m);
}

Map<String,String> copyMapString(Map<String,String> m) {
  if (m == null) return null ;
  return new Map<String,String>.from(m);
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

dynamic getIgnoreCase(Map m, String key) {
  var val = m[key] ;
  if (val != null) return val ;

  key = key.toLowerCase() ;

  for (var v in m.keys) {
    if ( v.toString().toLowerCase() == key ) {
      return m[v] ;
    }
  }

  return null ;
}

int getCurrentTimeMillis() {
  return new DateTime.now().millisecondsSinceEpoch ;
}

Future callAsync(int delayMs, function()) {
  return new Future.delayed(new Duration(milliseconds: delayMs), function) ;
}

String dataSizeFormat(int size) {
  if (size < 1024) {
    return "$size bytes" ;
  }
  else if (size < 1024*1024) {
    var s = "${size / 1024} KB";
    var s2 = s.replaceFirstMapped(new RegExp("\\.(\\d\\d)\\d+"), (m) => ".${m[1]}");
    return s2 ;
  }
  else {
    var s = "${size / (1024*1024)} MB";
    var s2 = s.replaceFirstMapped(new RegExp("\\.(\\d\\d)\\d+"), (m) => ".${m[1]}");
    return s2 ;
  }
}

void _initializeDateFormatting() {
  var locale = Intl.defaultLocale;
  if (locale == null || locale.isEmpty) locale = 'en' ;
  initializeDateFormatting(locale, null);
}

String dateFormat_YYYY_MM_dd_HH_mm_ss([int time]) {
  if (time == null) time = getCurrentTimeMillis() ;

  _initializeDateFormatting();

  var date = new DateTime.fromMillisecondsSinceEpoch(time) ;
  var dateFormat = new DateFormat('yyyy-MM-dd HH:mm:ss');
  return dateFormat.format(date) ;
}

String dateFormat_YYYY_MM_dd([int time]) {
  if (time == null) time = getCurrentTimeMillis() ;

  _initializeDateFormatting();

  var date = new DateTime.fromMillisecondsSinceEpoch(time) ;
  var dateFormat = new DateFormat('yyyy-MM-dd');
  return dateFormat.format(date) ;
}

String getDateAmPm([int time]) {
  if (time == null) time = getCurrentTimeMillis() ;

  _initializeDateFormatting();

  var date = new DateTime.fromMillisecondsSinceEpoch(time) ;
  var dateFormat = new DateFormat('jm');
  var s = dateFormat.format(date) ;
  return s.contains("PM") ? 'PM' : 'AM';
}

int getDateHour([int time]) {
  if (time == null) time = getCurrentTimeMillis() ;

  _initializeDateFormatting();

  var date = new DateTime.fromMillisecondsSinceEpoch(time) ;
  var dateFormat = new DateFormat('HH');
  var s = dateFormat.format(date) ;
  return int.parse(s);
}

int parseInt(dynamic v, [int def]) {
  if (v == null) return def ;

  if (v is int) return v ;
  if (v is num) return v.toInt() ;

  String s ;
  if (v is String) {
    s = v ;
  }
  else {
    s = v.toString() ;
  }

  s = s.trim() ;

  if (s.isEmpty) return def ;

  return int.parse(s) ;
}

double parseDouble(dynamic v, [double def]) {
  if (v == null) return def ;

  if (v is double) return v ;
  if (v is num) return v.toDouble();

  String s ;
  if (v is String) {
    s = v ;
  }
  else {
    s = v.toString() ;
  }

  s = s.trim() ;

  if (s.isEmpty) return def ;

  return double.parse(s) ;
}

String toUpperCaseInitials(String s) {
  if (s == null || s.isEmpty) return s ;
  return s.toLowerCase().replaceAllMapped(new RegExp("(\\s|^)(\\w)"), (m) => "${m[1]}${m[2].toUpperCase()}") ;
}

List<String> asListOfString( dynamic o ) {
  if (o == null) return null ;
  List<dynamic> l = o as List<dynamic> ;
  return l.map( (e) => e.toString() ).toList() as List<String> ;
}

Map asMap(dynamic o) {
  if (o == null) return null ;
  if (o is Map) return o ;

  Map m = {} ;

  if (o is List) {
    int sz = o.length ;

    for (int i = 0 ; i < sz ; i+=2) {
      dynamic key = o[i] ;
      dynamic val = o[i+1] ;
      m[key] = val ;
    }
  }
  else {
    throw new StateError("Can't handle type: "+ o) ;
  }

  return m ;
}

List<Map> asListOfMap( dynamic o ) {
  if (o == null) return null ;
  List<dynamic> l = o as List<dynamic> ;
  return l.map( (e) => asMap(e) ).toList() ;
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
