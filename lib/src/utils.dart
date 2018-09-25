
import 'dart:async';

import 'package:intl/intl.dart';

class EventStream<T> implements Stream<T>{

  StreamController<T> _controller ;
  Stream<T> _s ;

  EventStream() {
    _controller = new StreamController();
    _s = _controller.stream.asBroadcastStream() ;
  }

  /////////////////////////////////////////////////

  void add(T value) {
    _controller.add(value);
  }

  void addError(Object error, StackTrace stackTrace) {
    _controller.addError(error, stackTrace) ;
  }

  Future addStream(Stream<T> source, {bool cancelOnError}) {
    _controller.addStream(source, cancelOnError: cancelOnError) ;
  }

  Future close() {
    return _controller.close() ;
  }

  bool get isClosed => _controller.isClosed ;
  bool get isPaused => _controller.isPaused ;

  /////////////////////////////////////////////////

  @override
  Future<bool> any(bool Function(T element) test) {
    return _s.any(test) ;
  }

  @override
  Stream<T> asBroadcastStream({void Function(StreamSubscription<T> subscription) onListen, void Function(StreamSubscription<T> subscription) onCancel}) {
    return _s.asBroadcastStream(onListen: onListen, onCancel: onCancel) ;
  }

  @override
  Stream<E> asyncExpand<E>(Stream<E> Function(T event) convert) {
    return _s.asyncExpand(convert);
  }

  @override
  Stream<E> asyncMap<E>(FutureOr<E> Function(T event) convert) {
    return _s.asyncMap(convert);
  }

  @override
  Stream<R> cast<R>() {
    return _s.cast();
  }

  @override
  Future<bool> contains(Object needle) {
    return _s.contains(needle);
  }

  @override
  Stream<T> distinct([bool Function(T previous, T next) equals]) {
    return _s.distinct(equals);
  }

  @override
  Future<E> drain<E>([E futureValue]) {
    return _s.drain(futureValue);
  }

  @override
  Future<T> elementAt(int index) {
    return _s.elementAt(index);
  }

  @override
  Future<bool> every(bool Function(T element) test) {
    return _s.every(test);
  }

  @override
  Stream<S> expand<S>(Iterable<S> Function(T element) convert) {
    return _s.expand(convert);
  }

  @override
  Future<T> get first => _s.first;

  @override
  Future<T> firstWhere(bool Function(T element) test, {T Function() orElse}) {
    return _s.firstWhere(test, orElse: orElse);
  }

  @override
  Future<S> fold<S>(S initialValue, S Function(S previous, T element) combine) {
    return _s.fold(initialValue, combine) ;
  }

  @override
  Future forEach(void Function(T element) action) {
    return _s.forEach(action);
  }

  @override
  Stream<T> handleError(Function onError, {bool Function(dynamic error) test}) {
    return _s.handleError(onError, test: test);
  }

  @override
  bool get isBroadcast => _s.isBroadcast;

  @override
  Future<bool> get isEmpty => _s.isEmpty;

  @override
  Future<String> join([String separator = ""]) {
    return _s.join(separator);
  }

  @override
  Future<T> get last => _s.last;

  @override
  Future<T> lastWhere(bool Function(T element) test, {T Function() orElse}) {
    return _s.lastWhere(test, orElse: orElse);
  }

  @override
  Future<int> get length => _s.length;

  @override
  StreamSubscription<T> listen(void Function(T event) onData, {Function onError, void Function() onDone, bool cancelOnError}) {
    try {
      return _s.listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError) ;
    }
    catch (e,s) {
      print(e);
      print(s);
      return null ;
    }
  }

  Future<T> listenAsFuture() {
    Completer<T> completer = new Completer() ;
    listen((e){
      completer.complete(e) ;
    });
    return completer.future ;
  }

  @override
  Stream<S> map<S>(S Function(T event) convert) {
    return _s.map(convert);
  }

  @override
  Future pipe(StreamConsumer<T> streamConsumer) {
    return _s.pipe(streamConsumer);
  }

  @override
  Future<T> reduce(T Function(T previous, T element) combine) {
    return _s.reduce(combine);
  }

  @override
  Future<T> get single => _s.single;

  @override
  Future<T> singleWhere(bool Function(T element) test, {T Function() orElse}) {
    return _s.singleWhere(test, orElse: orElse);
  }

  @override
  Stream<T> skip(int count) {
    return _s.skip(count);
  }

  @override
  Stream<T> skipWhile(bool Function(T element) test) {
    return _s.skipWhile(test);
  }

  @override
  Stream<T> take(int count) {
    return _s.take(count);
  }

  @override
  Stream<T> takeWhile(bool Function(T element) test) {
    return _s.takeWhile(test);
  }

  @override
  Stream<T> timeout(Duration timeLimit, {void Function(EventSink<T> sink) onTimeout}) {
    return _s.timeout(timeLimit, onTimeout: onTimeout);
  }

  @override
  Future<List<T>> toList() {
    return _s.toList();
  }

  @override
  Future<Set<T>> toSet() {
    return _s.toSet();
  }

  @override
  Stream<S> transform<S>(StreamTransformer<T, S> streamTransformer) {
    return _s.transform(streamTransformer);
  }

  @override
  Stream<T> where(bool Function(T event) test) {
    return _s.where(test);
  }





}

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

String dateFormat_YYYY_MM_dd_HH_mm_ss([int time]) {
  if (time == null) time = getCurrentTimeMillis() ;

  var date = new DateTime.fromMillisecondsSinceEpoch(time) ;
  var dateFormat = new DateFormat('yyyy-MM-dd HH:mm:ss');
  return dateFormat.format(date) ;
}

String dateFormat_YYYY_MM_dd([int time]) {
  if (time == null) time = getCurrentTimeMillis() ;

  var date = new DateTime.fromMillisecondsSinceEpoch(time) ;
  var dateFormat = new DateFormat('yyyy-MM-dd');
  return dateFormat.format(date) ;
}

String getDateAmPm([int time]) {
  if (time == null) time = getCurrentTimeMillis() ;

  var date = new DateTime.fromMillisecondsSinceEpoch(time) ;
  var dateFormat = new DateFormat('jm');
  var s = dateFormat.format(date) ;
  return s.contains("PM") ? 'PM' : 'AM';
}

int getDateHour([int time]) {
  if (time == null) time = getCurrentTimeMillis() ;

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
