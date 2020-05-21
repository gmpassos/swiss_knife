
import 'dart:async';

class _ListenSignature {
  final dynamic _identifier ;
  bool _identifyByInstance ;
  final bool _cancelOnError ;

  _ListenSignature(this._identifier, bool identifyByInstance, this._cancelOnError) {
    _identifyByInstance = identifyByInstance ?? true ;
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

class EventStream<T> implements Stream<T> {

  StreamController<T> _controller ;
  Stream<T> _s ;

  EventStream() {
    _controller = StreamController();
    _s = _controller.stream.asBroadcastStream() ;
  }

  bool _used = false ;

  bool get isUsed => _used;

  void _markUsed() => _used = true ;

  Stream<T> get _stream {
    _markUsed();
    return _s ;
  }

  /////////////////////////////////////////////////

  void add(T value) {
    if (!_used) return ;
    _controller.add(value);
  }

  void addError(Object error, StackTrace stackTrace) {
    if (!_used) return ;
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
    return _stream.any(test) ;
  }

  @override
  Stream<T> asBroadcastStream({void Function(StreamSubscription<T> subscription) onListen, void Function(StreamSubscription<T> subscription) onCancel}) {
    return _stream.asBroadcastStream(onListen: onListen, onCancel: onCancel) ;
  }

  @override
  Stream<E> asyncExpand<E>(Stream<E> Function(T event) convert) {
    return _stream.asyncExpand(convert);
  }

  @override
  Stream<E> asyncMap<E>(FutureOr<E> Function(T event) convert) {
    return _stream.asyncMap(convert);
  }

  @override
  Stream<R> cast<R>() {
    return _stream.cast();
  }

  @override
  Future<bool> contains(Object needle) {
    return _stream.contains(needle);
  }

  @override
  Stream<T> distinct([bool Function(T previous, T next) equals]) {
    return _stream.distinct(equals);
  }

  @override
  Future<E> drain<E>([E futureValue]) {
    return _stream.drain(futureValue);
  }

  @override
  Future<T> elementAt(int updateMetadata) {
    return _stream.elementAt(updateMetadata);
  }

  @override
  Future<bool> every(bool Function(T element) test) {
    return _stream.every(test);
  }

  @override
  Stream<S> expand<S>(Iterable<S> Function(T element) convert) {
    return _stream.expand(convert);
  }

  @override
  Future<T> get first => _stream.first;

  @override
  Future<T> firstWhere(bool Function(T element) test, {T Function() orElse}) {
    return _stream.firstWhere(test, orElse: orElse);
  }

  @override
  Future<S> fold<S>(S initialValue, S Function(S previous, T element) combine) {
    return _stream.fold(initialValue, combine) ;
  }

  @override
  Future forEach(void Function(T element) action) {
    return _stream.forEach(action);
  }

  @override
  Stream<T> handleError(Function onError, {bool Function(dynamic error) test}) {
    return _stream.handleError(onError, test: test);
  }

  @override
  bool get isBroadcast => _stream.isBroadcast;

  @override
  Future<bool> get isEmpty => _stream.isEmpty;

  @override
  Future<String> join([String separator = '']) {
    return _stream.join(separator);
  }

  @override
  Future<T> get last => _stream.last;

  @override
  Future<T> lastWhere(bool Function(T element) test, {T Function() orElse}) {
    return _stream.lastWhere(test, orElse: orElse);
  }

  @override
  Future<int> get length => _stream.length;

  final Set<_ListenSignature> _listenSignatures = {} ;

  @override
  StreamSubscription<T> listen(void Function(T event) onData, {Function onError, void Function() onDone, bool cancelOnError, dynamic singletonIdentifier, bool singletonIdentifyByInstance = true}) {
    try {
      cancelOnError ??= false;

      if (singletonIdentifier != null) {
        var listenSignature = _ListenSignature(singletonIdentifier, singletonIdentifyByInstance, cancelOnError);

        if ( _listenSignatures.contains(listenSignature) ) {
          return null ;
        }
        _listenSignatures.add(listenSignature) ;
      }

      return _stream.listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError) ;
    }
    catch (e,s) {
      print(e);
      print(s);
      return null ;
    }
  }

  Future<T> listenAsFuture() {
    var completer = Completer<T>() ;
    listen((e){
      completer.complete(e) ;
    });
    return completer.future ;
  }

  @override
  Stream<S> map<S>(S Function(T event) convert) {
    return _stream.map(convert);
  }

  @override
  Future pipe(StreamConsumer<T> streamConsumer) {
    return _stream.pipe(streamConsumer);
  }

  @override
  Future<T> reduce(T Function(T previous, T element) combine) {
    return _stream.reduce(combine);
  }

  @override
  Future<T> get single => _stream.single;

  @override
  Future<T> singleWhere(bool Function(T element) test, {T Function() orElse}) {
    return _stream.singleWhere(test, orElse: orElse);
  }

  @override
  Stream<T> skip(int count) {
    return _stream.skip(count);
  }

  @override
  Stream<T> skipWhile(bool Function(T element) test) {
    return _stream.skipWhile(test);
  }

  @override
  Stream<T> take(int count) {
    return _stream.take(count);
  }

  @override
  Stream<T> takeWhile(bool Function(T element) test) {
    return _stream.takeWhile(test);
  }

  @override
  Stream<T> timeout(Duration timeLimit, {void Function(EventSink<T> sink) onTimeout}) {
    return _stream.timeout(timeLimit, onTimeout: onTimeout);
  }

  @override
  Future<List<T>> toList() {
    return _stream.toList();
  }

  @override
  Future<Set<T>> toSet() {
    return _stream.toSet();
  }

  @override
  Stream<S> transform<S>(StreamTransformer<T, S> streamTransformer) {
    return _stream.transform(streamTransformer);
  }

  @override
  Stream<T> where(bool Function(T event) test) {
    return _stream.where(test);
  }

}

