import 'dart:async';

class _ListenSignature {
  final dynamic _identifier;

  bool _identifyByInstance;

  final bool _cancelOnError;

  _ListenSignature(
      this._identifier, bool identifyByInstance, this._cancelOnError) {
    _identifyByInstance = identifyByInstance ?? true;
  }

  dynamic get identifier => _identifier;

  bool get identifyByInstance => _identifyByInstance;

  bool get cancelOnError => _cancelOnError;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ListenSignature &&
          runtimeType == other.runtimeType &&
          (_identifyByInstance
              ? identical(_identifier, other._identifier)
              : _identifier == other._identifier);

  @override
  int get hashCode => _identifier.hashCode;

  StreamSubscription subscription;

  bool _canceled = false;

  bool get isCanceled => _canceled != null && _canceled;

  void cancel() {
    _cancel(true);
  }

  void _cancel(bool cancelSubscription) {
    _canceled = true;

    if (subscription != null) {
      if (cancelSubscription) {
        try {
          subscription.cancel();
        } catch (e, s) {
          print(e);
          print(s);
        }
      }
      subscription = null;
    }
  }
}

/// Implements a Stream for events and additional features.
///
/// See [Stream] for more documentation of delegated methods.
class EventStream<T> implements Stream<T> {
  StreamController<T> _controller;

  Stream<T> _s;

  EventStream() {
    _controller = StreamController();
    _s = _controller.stream.asBroadcastStream();
  }

  bool _used = false;

  bool get isUsed => _used;

  void _markUsed() => _used = true;

  Stream<T> get _stream {
    _markUsed();
    return _s;
  }

  /////////////////////////////////////////////////

  /// Adds an event and notify it to listeners.
  void add(T value) {
    if (!_used) return;
    _controller.add(value);
  }

  /// Adds an error event and notify it to listeners.
  void addError(Object error, StackTrace stackTrace) {
    if (!_used) return;
    _controller.addError(error, stackTrace);
  }

  Future addStream(Stream<T> source, {bool cancelOnError}) {
    return _controller.addStream(source, cancelOnError: cancelOnError);
  }

  /// Closes this stream.
  Future close() {
    return _controller.close();
  }

  /// Returns [true] if this stream is closed.
  bool get isClosed => _controller.isClosed;

  /// Returns [true] if this stream is paused.
  bool get isPaused => _controller.isPaused;

  /////////////////////////////////////////////////

  @override
  Future<bool> any(bool Function(T element) test) {
    return _stream.any(test);
  }

  @override
  Stream<T> asBroadcastStream(
      {void Function(StreamSubscription<T> subscription) onListen,
      void Function(StreamSubscription<T> subscription) onCancel}) {
    return _stream.asBroadcastStream(onListen: onListen, onCancel: onCancel);
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
    return _stream.fold(initialValue, combine);
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

  final Set<_ListenSignature> _listenSignatures = {};

  /// Cancels all [StreamSubscription] of singleton listeners.
  void cancelAllSingletonSubscriptions() {
    for (var signature in _listenSignatures) {
      signature.cancel();
    }
    _listenSignatures.clear();
  }

  /// Cancels [StreamSubscription] associated with [singletonIdentifier].
  bool cancelSingletonSubscription(dynamic singletonIdentifier,
      [bool singletonIdentifyByInstance = true]) {
    var signature =
        _getListenSignature(singletonIdentifier, singletonIdentifyByInstance);

    if (signature != null && !signature.isCanceled) {
      signature.cancel();
      return true;
    } else {
      return false;
    }
  }

  /// Returns a [StreamSubscription] associated with [singletonIdentifier].
  StreamSubscription<T> getSingletonSubscription(dynamic singletonIdentifier,
      [bool singletonIdentifyByInstance = true]) {
    var signature =
        _getListenSignature(singletonIdentifier, singletonIdentifyByInstance);
    return signature != null ? signature.subscription : null;
  }

  _ListenSignature _getListenSignature(dynamic singletonIdentifier,
      [bool singletonIdentifyByInstance = true]) {
    if (singletonIdentifier == null) return null;
    singletonIdentifyByInstance ??= true;

    var listenSignature = _ListenSignature(
        singletonIdentifier, singletonIdentifyByInstance, false);

    for (var signature in _listenSignatures) {
      if (signature == listenSignature) {
        return signature;
      }
    }

    return null;
  }

  /// Listen for events.
  ///
  /// [onData] on event data.
  /// [onError] on error is added.
  /// [singletonIdentifier] identifier to avoid multiple listeners with the same identifier. This will register a singleton [StreamSubscription] associated with [singletonIdentifier].
  /// [singletonIdentifyByInstance] if true uses `identical(...)` to compare the [singletonIdentifier].
  @override
  StreamSubscription<T> listen(void Function(T event) onData,
      {Function onError,
      void Function() onDone,
      bool cancelOnError,
      dynamic singletonIdentifier,
      bool singletonIdentifyByInstance = true}) {
    try {
      cancelOnError ??= false;

      if (singletonIdentifier != null) {
        var listenSignature = _ListenSignature(
            singletonIdentifier, singletonIdentifyByInstance, cancelOnError);

        if (_listenSignatures.contains(listenSignature)) {
          return null;
        }
        _listenSignatures.add(listenSignature);

        var subscription = _stream.listen(onData, onError: onError, onDone: () {
          listenSignature._cancel(false);
          _listenSignatures.remove(listenSignature);

          if (onDone != null) {
            onDone();
          }
        }, cancelOnError: cancelOnError);

        listenSignature.subscription = subscription;

        return subscription;
      } else {
        return _stream.listen(onData,
            onError: onError, onDone: onDone, cancelOnError: cancelOnError);
      }
    } catch (e, s) {
      print(e);
      print(s);
      return null;
    }
  }

  /// Returns a future that completes when receives at least 1 event.
  Future<T> listenAsFuture() {
    var completer = Completer<T>();
    listen((e) {
      if (!completer.isCompleted) {
        completer.complete(e);
      }
    });
    return completer.future;
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
  Stream<T> timeout(Duration timeLimit,
      {void Function(EventSink<T> sink) onTimeout}) {
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

/// Tracks interactions and after a delay, without interaction, triggers
/// [onComplete].
class InteractionCompleter {
  /// Name of this instance.
  final String name;

  /// The delay of triggers, started after last interaction.
  final Duration triggerDelay;
  Function functionToTrigger;

  InteractionCompleter(String name,
      {Duration triggerDelay, this.functionToTrigger})
      : name = name ?? '',
        triggerDelay = triggerDelay ?? Duration(milliseconds: 500);

  int get now {
    return DateTime.now().millisecondsSinceEpoch;
  }

  int get triggerDelayMs => triggerDelay.inMilliseconds;

  int _lastInteractionTime;

  int get lastInteractionTime => _lastInteractionTime;

  bool _interactionNotTriggered = false;

  bool get hasInteractionNotTriggered => _interactionNotTriggered;

  /// Marks an interaction and schedules delayed trigger.
  ///
  /// [noTriggering] If [true] won't schedule trigger, only mark interaction.
  void interact({noTriggering = false}) {
    noTriggering ??= false;

    log('interact', [noTriggering]);

    _lastInteractionTime = now;
    _interactionNotTriggered = true;

    if (!noTriggering) {
      _scheduleTrigger(triggerDelayMs);
    }
  }

  int get interactionElapsedTime =>
      _lastInteractionTime != null ? now - _lastInteractionTime : null;

  bool _triggerScheduled = false;

  bool get isTriggerScheduled => _triggerScheduled;

  void _scheduleTrigger(int delay) {
    if (_triggerScheduled) return;

    log('_scheduleTrigger', [delay]);

    _triggerScheduled = true;
    Future.delayed(Duration(milliseconds: delay), () => _callTrigger());
  }

  void _callTrigger() {
    if (!_triggerScheduled) return;

    var timeUntilNextTrigger = triggerDelayMs - interactionElapsedTime;

    log('_callTrigger', [timeUntilNextTrigger]);

    if (timeUntilNextTrigger > 0) {
      Future.delayed(
          Duration(milliseconds: timeUntilNextTrigger), () => _callTrigger());
      return;
    } else {
      triggerNow();
    }
  }

  /// Triggers only if already has some interaction.
  void triggerIfHasInteraction() {
    if (hasInteractionNotTriggered) {
      triggerNow();
    }
  }

  final EventStream<InteractionCompleter> onComplete = EventStream();

  /// Triggers immediately.
  void triggerNow() {
    log('triggerNow');
    _triggerScheduled = false;
    _interactionNotTriggered = false;

    if (functionToTrigger != null) {
      try {
        functionToTrigger();
      } catch (e, s) {
        print(e);
        print(s);
      }
    }

    onComplete.add(this);
  }

  /// Cancels any event scheduled to be triggered.
  void cancel() {
    _triggerScheduled = false;
    _interactionNotTriggered = false;
  }

  void log(String method, [List parameters]) {
    //print('InteractionCompleter[$name] $method> ${parameters ?? ''}');
  }
}

/// A dummy version of [InteractionCompleter].
class InteractionCompleterDummy extends InteractionCompleter {
  InteractionCompleterDummy() : super('');

  @override
  void interact({noTriggering = false}) {}

  @override
  void triggerIfHasInteraction() {}

  @override
  void triggerNow() {}
}

/// Listen [stream], calling [onData] only after [triggerDelay] duration.
///
/// [onData] is only called when [stream] event is triggered and stays
/// without any new event for [triggerDelay] duration.
InteractionCompleter listenStreamWithInteractionCompleter<T>(
    Stream<T> stream, Duration triggerDelay, void Function(T event) onData) {
  if (stream == null) throw ArgumentError.notNull('stream');
  if (triggerDelay == null) throw ArgumentError.notNull('triggerDelay');
  if (onData == null) throw ArgumentError.notNull('onData');

  var lastEvent = <T>[];

  var interactionCompleter = InteractionCompleter(
      'listenStreamWithInteractionCompleter[${stream}]',
      triggerDelay: triggerDelay, functionToTrigger: () {
    var event = lastEvent.isNotEmpty ? lastEvent.first : null;
    onData(event);
  });

  stream.listen((event) {
    lastEvent.clear();
    lastEvent.add(event);
    interactionCompleter.interact();
  });

  return interactionCompleter;
}
