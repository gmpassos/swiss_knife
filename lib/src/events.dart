
import 'dart:async';

class _ListenSignature {
  final dynamic _identifier ;
  bool _identifyByInstance ;
  final bool _cancelOnError ;

  _ListenSignature(this._identifier, bool identifyByInstance, this._cancelOnError) {
    this._identifyByInstance = identifyByInstance ?? true ;
  }

  dynamic get identifier => _identifier;
  bool get identifyByInstance => _identifyByInstance;
  bool get cancelOnError => _cancelOnError;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is _ListenSignature &&
              runtimeType == other.runtimeType &&
              ( _identifyByInstance ? identical( _identifier , other._identifier ) : _identifier == other._identifier ) &&
              _cancelOnError == other._cancelOnError ;

  @override
  int get hashCode =>
      _identifier.hashCode ^
      ( _cancelOnError != null ? _cancelOnError.hashCode : 0 ) ;

}

class EventStream<T> implements Stream<T>{

  StreamController<T> _controller ;
  Stream<T> _s ;

  EventStream() {
    _controller = StreamController();
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
    return _controller.addStream(source, cancelOnError: cancelOnError) ;
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
  Future<T> elementAt(int updateMetadata) {
    return _s.elementAt(updateMetadata);
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

  final Set<_ListenSignature> _listenSignatures = {} ;

  @override
  StreamSubscription<T> listen(void Function(T event) onData, {Function onError, void Function() onDone, bool cancelOnError, dynamic singletonIdentifier, bool singletonIdentifyByInstance = true}) {
    try {
      if (cancelOnError == null) cancelOnError = false ;

      if (singletonIdentifier != null) {
        var listenSignature = _ListenSignature(singletonIdentifier, singletonIdentifyByInstance, cancelOnError);

        if ( _listenSignatures.contains(listenSignature) ) {
          return null ;
        }
        _listenSignatures.add(listenSignature) ;
      }

      return _s.listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError) ;
    }
    catch (e,s) {
      print(e);
      print(s);
      return null ;
    }
  }

  Future<T> listenAsFuture() {
    Completer<T> completer = Completer() ;
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

