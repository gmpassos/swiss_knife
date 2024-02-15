import 'dart:async';

import 'collections.dart';
import 'math.dart';

class _ListenSignature {
  final Object _identifier;

  final bool _identifyByInstance;

  final bool _cancelOnError;

  _ListenSignature(
      this._identifier, this._identifyByInstance, this._cancelOnError);

  Object get identifier => _identifier;

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

  late StreamSubscription? subscription;

  bool _canceled = false;

  bool get isCanceled => _canceled;

  bool cancel() => _cancel(true);

  bool _cancel(bool cancelSubscription) {
    _canceled = true;

    var subscription = this.subscription;
    if (subscription == null) return false;

    this.subscription = null;

    if (cancelSubscription) {
      try {
        subscription.cancel();
      } catch (e, s) {
        print(e);
        print(s);
      }
    }

    return true;
  }
}

typedef EventValidatorFunction<T> = bool Function(
    EventStream<T> eventStream, T event);

/// Implements a Stream for events and additional features.
///
/// See [Stream] for more documentation of delegated methods.
class EventStream<T> implements Stream<T> {
  final StreamController<T> _controller = StreamController();

  late final Stream<T> _s;

  EventStream() {
    _s = _controller.stream.asBroadcastStream();
  }

  bool _used = false;

  bool get isUsed => _used;

  void _markUsed() => _used = true;

  Stream<T> get _stream {
    _markUsed();
    return _s;
  }

  /// Adds an event and notify it to listeners.
  void add(T value) {
    if (!_used) return;
    _controller.add(value);
  }

  /// Adds an error event and notify it to listeners.
  void addError(Object error, [StackTrace? stackTrace]) {
    if (!_used) return;
    _controller.addError(error, stackTrace);
  }

  Future addStream(Stream<T> source, {bool? cancelOnError}) =>
      _controller.addStream(source, cancelOnError: cancelOnError);

  /// Closes this stream.
  Future close() => _controller.close();

  /// Returns [true] if this stream is closed.
  bool get isClosed => _controller.isClosed;

  /// Returns [true] if this stream is paused.
  bool get isPaused => _controller.isPaused;

  @override
  Future<bool> any(bool Function(T element) test) {
    return _stream.any(test);
  }

  @override
  Stream<T> asBroadcastStream(
      {void Function(StreamSubscription<T> subscription)? onListen,
      void Function(StreamSubscription<T> subscription)? onCancel}) {
    return _stream.asBroadcastStream(onListen: onListen, onCancel: onCancel);
  }

  @override
  Stream<E> asyncExpand<E>(Stream<E>? Function(T event) convert) {
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
  Future<bool> contains(Object? needle) {
    return _stream.contains(needle);
  }

  @override
  Stream<T> distinct([bool Function(T previous, T next)? equals]) {
    return _stream.distinct(equals);
  }

  @override
  Future<E> drain<E>([E? futureValue]) {
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
  Future<T> firstWhere(bool Function(T element) test, {T Function()? orElse}) {
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
  Stream<T> handleError(Function onError,
      {bool Function(Object? error)? test}) {
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
  Future<T> lastWhere(bool Function(T element) test, {T Function()? orElse}) {
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
  bool cancelSingletonSubscription(Object singletonIdentifier,
      [bool singletonIdentifyByInstance = true]) {
    var signature =
        _getListenSignature(singletonIdentifier, singletonIdentifyByInstance);

    if (signature != null) {
      _listenSignatures.remove(signature);
      return signature.cancel();
    }

    return false;
  }

  /// Returns a [StreamSubscription] associated with [singletonIdentifier].
  StreamSubscription<T?>? getSingletonSubscription(Object singletonIdentifier,
      [bool singletonIdentifyByInstance = true]) {
    var signature =
        _getListenSignature(singletonIdentifier, singletonIdentifyByInstance);
    return signature?.subscription as StreamSubscription<T?>?;
  }

  _ListenSignature? _getListenSignature(Object singletonIdentifier,
      [bool singletonIdentifyByInstance = true]) {
    var listenSignature = _ListenSignature(
        singletonIdentifier, singletonIdentifyByInstance, false);

    for (var signature in _listenSignatures) {
      if (signature == listenSignature) {
        return signature;
      }
    }

    return null;
  }

  EventValidatorFunction<T>? eventValidator;

  /// Listen for events.
  ///
  /// [onData] on event data.
  /// [onError] on error is added.
  /// [singletonIdentifier] identifier to avoid multiple listeners with the same identifier. This will register a singleton [StreamSubscription] associated with [singletonIdentifier].
  /// [singletonIdentifyByInstance] if true uses `identical(...)` to compare the [singletonIdentifier].
  @override
  StreamSubscription<T> listen(void Function(T event)? onData,
      {Function? onError,
      void Function()? onDone,
      bool? cancelOnError = false,
      Object? singletonIdentifier,
      bool singletonIdentifyByInstance = true,
      EventValidatorFunction<T>? eventValidator,
      bool overwriteSingletonSubscription = false}) {
    try {
      eventValidator ??= this.eventValidator;

      if (eventValidator != null && onData != null) {
        var eventValidatorOriginal = eventValidator;
        var onDataOriginal = onData;
        onData = (event) {
          var valid = eventValidatorOriginal(this, event);
          if (valid) {
            onDataOriginal(event);
          }
        };
      }

      if (singletonIdentifier != null) {
        var listenSignature = _ListenSignature(singletonIdentifier,
            singletonIdentifyByInstance, cancelOnError ?? false);

        var prevSubscription =
            getSetEntryInstance(_listenSignatures, listenSignature);

        if (overwriteSingletonSubscription && prevSubscription != null) {
          _listenSignatures.remove(prevSubscription);
          prevSubscription.cancel();
          prevSubscription = null;
        }

        if (prevSubscription != null) {
          var subscription = prevSubscription.subscription;
          if (subscription != null) {
            return subscription as StreamSubscription<T>;
          } else {
            _listenSignatures.remove(prevSubscription);
          }
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
    } catch (e) {
      rethrow;
    }
  }

  ListenerWrapper<T>? listenOneShot(void Function(T event) onData,
      {Function? onError,
      void Function()? onDone,
      bool cancelOnError = false,
      Object? singletonIdentifier,
      bool? singletonIdentifyByInstance = true}) {
    var listenerWrapper = ListenerWrapper<T>(this, onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError,
        oneShot: true);
    var ok = listenerWrapper.listen();
    return ok ? listenerWrapper : null;
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
  Future<T> singleWhere(bool Function(T element) test, {T Function()? orElse}) {
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
      {void Function(EventSink<T> sink)? onTimeout}) {
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

/// A delegator for `EventStream`.
///
/// Useful to point to `EventStream` instances that are not instantiated yet.
class EventStreamDelegator<T> implements EventStream<T> {
  EventStream<T>? _eventStream;

  final EventStream<T>? Function()? _eventStreamProvider;

  EventStreamDelegator(EventStream<T> eventStream)
      : _eventStream = eventStream,
        _eventStreamProvider = null;

  EventStreamDelegator.provider(EventStream<T>? Function() eventStreamProvider)
      : _eventStream = null,
        _eventStreamProvider = eventStreamProvider;

  /// Returns the main [EventStream].
  EventStream<T>? get eventStream {
    if (_eventStream == null) {
      _eventStream =
          _eventStreamProvider != null ? _eventStreamProvider() : null;
      if (_eventStream != null) {
        flush();
      }
    }
    return _eventStream;
  }

  /// Sets the main [EventStream].
  set eventStream(EventStream<T>? value) {
    if (_eventStream != value) {
      _eventStream = value;
      if (_eventStream != null) {
        flush();
      }
    }
  }

  /// Flushes any event in buffer.
  void flush() {
    _eventStream ??= _eventStreamProvider!();

    var es = _eventStream;
    if (es == null) return;

    for (var v in _listenBuffer) {
      es.listen(
        v[0],
        onError: v[1],
        onDone: v[2],
        cancelOnError: v[3],
        singletonIdentifier: v[4],
        singletonIdentifyByInstance: v[5],
        eventValidator: v[6],
        overwriteSingletonSubscription: v[7],
      );
    }

    for (var v in _listenOneShotBuffer) {
      es.listenOneShot(v[0],
          onError: v[1],
          onDone: v[2],
          cancelOnError: v[3],
          singletonIdentifier: v[4],
          singletonIdentifyByInstance: v[5]);
    }

    for (var v in _addBuffer) {
      es.add(v);
    }

    for (var v in _addErrorBuffer) {
      es.addError(v[0], v[1]);
    }

    clearUnflushed();
  }

  /// Clears unflushed events.
  void clearUnflushed() {
    _addBuffer.clear();
    _addErrorBuffer.clear();
    _listenBuffer.clear();
    _listenOneShotBuffer.clear();
  }

  @override
  late StreamController<T> _controller;

  @override
  late Stream<T> _s;

  @override
  late bool _used;

  @override
  _ListenSignature _getListenSignature(singletonIdentifier,
      [bool singletonIdentifyByInstance = true]) {
    throw UnimplementedError();
  }

  @override
  Set<_ListenSignature> get _listenSignatures => throw UnimplementedError();

  @override
  void _markUsed() {}

  @override
  Stream<T> get _stream => throw UnimplementedError();

  final List<T> _addBuffer = [];

  @override
  void add(T value) {
    var es = eventStream;
    if (es == null) {
      _addBuffer.add(value);
    } else {
      es.add(value);
    }
  }

  final List<List> _addErrorBuffer = [];

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    var es = eventStream;
    if (es == null) {
      _addErrorBuffer.add([error, stackTrace]);
    } else {
      es.addError(error, stackTrace);
    }
  }

  final List _listenBuffer = [];

  @override
  StreamSubscription<T> listen(void Function(T event)? onData,
      {Function? onError,
      void Function()? onDone,
      bool? cancelOnError = false,
      singletonIdentifier,
      bool singletonIdentifyByInstance = true,
      EventValidatorFunction<T>? eventValidator,
      bool overwriteSingletonSubscription = false}) {
    var es = eventStream;
    if (es == null) {
      _listenBuffer.add([
        onData,
        onError,
        onDone,
        cancelOnError,
        singletonIdentifier,
        singletonIdentifyByInstance,
        eventValidator,
        overwriteSingletonSubscription
      ]);

      return _StreamSubscriptionProvider(() {
        var es2 = eventStream;
        return es2?.listen(onData,
            onError: onError,
            onDone: onDone,
            cancelOnError: cancelOnError,
            singletonIdentifier: singletonIdentifier,
            singletonIdentifyByInstance: singletonIdentifyByInstance,
            eventValidator: eventValidator,
            overwriteSingletonSubscription: overwriteSingletonSubscription);
      });
    } else {
      return es.listen(onData,
          onError: onError,
          onDone: onDone,
          cancelOnError: cancelOnError,
          singletonIdentifier: singletonIdentifier,
          singletonIdentifyByInstance: singletonIdentifyByInstance,
          eventValidator: eventValidator,
          overwriteSingletonSubscription: overwriteSingletonSubscription);
    }
  }

  final List _listenOneShotBuffer = [];

  @override
  ListenerWrapper<T>? listenOneShot(void Function(T event) onData,
      {Function? onError,
      void Function()? onDone,
      bool? cancelOnError,
      singletonIdentifier,
      bool? singletonIdentifyByInstance = true}) {
    var es = eventStream;
    if (es == null) {
      _listenOneShotBuffer.add([
        onData,
        onError,
        onDone,
        cancelOnError,
        singletonIdentifier,
        singletonIdentifyByInstance,
      ]);
      return null;
    } else {
      return es.listenOneShot(onData,
          onError: onError,
          onDone: onDone,
          cancelOnError: cancelOnError!,
          singletonIdentifier: singletonIdentifier,
          singletonIdentifyByInstance: singletonIdentifyByInstance);
    }
  }

  @override
  Future addStream(Stream<T> source, {bool? cancelOnError}) =>
      eventStream!.addStream(source, cancelOnError: cancelOnError);

  @override
  Future<bool> any(bool Function(T element) test) => eventStream!.any(test);

  @override
  Stream<T> asBroadcastStream(
          {void Function(StreamSubscription<T> subscription)? onListen,
          void Function(StreamSubscription<T> subscription)? onCancel}) =>
      eventStream!.asBroadcastStream(onListen: onListen, onCancel: onCancel);

  @override
  Stream<E> asyncExpand<E>(Stream<E>? Function(T event) convert) =>
      eventStream!.asyncExpand(convert);

  @override
  Stream<E> asyncMap<E>(FutureOr<E> Function(T event) convert) =>
      eventStream!.asyncMap(convert);

  @override
  void cancelAllSingletonSubscriptions() =>
      eventStream!.cancelAllSingletonSubscriptions();

  @override
  bool cancelSingletonSubscription(singletonIdentifier,
          [bool singletonIdentifyByInstance = true]) =>
      eventStream!.cancelSingletonSubscription(
          singletonIdentifier, singletonIdentifyByInstance);

  @override
  Stream<R> cast<R>() => eventStream!.cast<R>();

  @override
  Future close() => eventStream!.close();

  @override
  Future<bool> contains(Object? needle) => eventStream!.contains(needle);

  @override
  Stream<T> distinct([bool Function(T previous, T next)? equals]) =>
      eventStream!.distinct(equals);

  @override
  Future<E> drain<E>([E? futureValue]) => eventStream!.drain(futureValue);

  @override
  Future<T> elementAt(int updateMetadata) =>
      eventStream!.elementAt(updateMetadata);

  @override
  Future<bool> every(bool Function(T element) test) => eventStream!.every(test);

  @override
  Stream<S> expand<S>(Iterable<S> Function(T element) convert) =>
      eventStream!.expand(convert);

  @override
  Future<T> get first => eventStream!.first;

  @override
  Future<T> firstWhere(bool Function(T element) test, {T Function()? orElse}) =>
      eventStream!.firstWhere(test, orElse: orElse);

  @override
  Future<S> fold<S>(
          S initialValue, S Function(S previous, T element) combine) =>
      eventStream!.fold(initialValue, combine);

  @override
  Future forEach(void Function(T element) action) =>
      eventStream!.forEach(action);

  @override
  StreamSubscription<T?>? getSingletonSubscription(singletonIdentifier,
          [bool singletonIdentifyByInstance = true]) =>
      eventStream?.getSingletonSubscription(
          singletonIdentifier, singletonIdentifyByInstance);

  @override
  Stream<T> handleError(Function onError,
          {bool Function(Object? error)? test}) =>
      eventStream!.handleError(onError, test: test);

  @override
  bool get isBroadcast => eventStream!.isBroadcast;

  @override
  bool get isClosed => eventStream!.isClosed;

  @override
  Future<bool> get isEmpty => eventStream!.isEmpty;

  @override
  bool get isPaused => eventStream!.isPaused;

  @override
  bool get isUsed => eventStream!.isUsed;

  @override
  Future<String> join([String separator = '']) => eventStream!.join(separator);

  @override
  Future<T> get last => eventStream!.last;

  @override
  Future<T> lastWhere(bool Function(T element) test, {T Function()? orElse}) =>
      eventStream!.lastWhere(test, orElse: orElse);

  @override
  Future<int> get length => eventStream!.length;

  @override
  Future<T> listenAsFuture() => eventStream!.listenAsFuture();

  @override
  Stream<S> map<S>(S Function(T event) convert) => eventStream!.map(convert);

  @override
  Future pipe(StreamConsumer<T> streamConsumer) =>
      eventStream!.pipe(streamConsumer);

  @override
  Future<T> reduce(T Function(T previous, T element) combine) =>
      eventStream!.reduce(combine);

  @override
  Future<T> get single => eventStream!.single;

  @override
  Future<T> singleWhere(bool Function(T element) test,
          {T Function()? orElse}) =>
      eventStream!.singleWhere(test, orElse: orElse);

  @override
  Stream<T> skip(int count) => eventStream!.skip(count);

  @override
  Stream<T> skipWhile(bool Function(T element) test) =>
      eventStream!.skipWhile(test);

  @override
  Stream<T> take(int count) => eventStream!.take(count);

  @override
  Stream<T> takeWhile(bool Function(T element) test) =>
      eventStream!.takeWhile(test);

  @override
  Stream<T> timeout(Duration timeLimit,
          {void Function(EventSink<T> sink)? onTimeout}) =>
      eventStream!.timeout(timeLimit, onTimeout: onTimeout);

  @override
  Future<List<T>> toList() => eventStream!.toList();

  @override
  Future<Set<T>> toSet() => eventStream!.toSet();

  @override
  Stream<S> transform<S>(StreamTransformer<T, S> streamTransformer) =>
      eventStream!.transform(streamTransformer);

  @override
  Stream<T> where(bool Function(T event) test) => eventStream!.where(test);

  @override
  EventValidatorFunction<T>? get eventValidator => eventStream?.eventValidator;

  @override
  set eventValidator(EventValidatorFunction<T>? eventValidator) =>
      eventStream?.eventValidator = eventValidator;
}

class _StreamSubscriptionProvider<T> implements StreamSubscription<T> {
  final StreamSubscription<T>? Function() _provider;
  StreamSubscription<T>? _s;

  StreamSubscription<T> get _source {
    _s ??= _provider();
    return _s!;
  }

  _StreamSubscriptionProvider(this._provider);

  @override
  void onData(void Function(T)? handleData) {
    _source.onData(handleData);
  }

  @override
  void onError(Function? handleError) {
    _source.onError(handleError);
  }

  @override
  void onDone(void Function()? handleDone) {
    _source.onDone(handleDone);
  }

  @override
  void pause([Future? resumeFuture]) {
    _source.pause(resumeFuture);
  }

  @override
  void resume() {
    _source.resume();
  }

  @override
  Future cancel() => _source.cancel();

  @override
  Future<E> asFuture<E>([E? futureValue]) => _source.asFuture(futureValue);

  @override
  bool get isPaused => _source.isPaused;
}

/// Tracks interactions and after a delay, without interaction, triggers
/// [onComplete].
class InteractionCompleter {
  /// Name of this instance.
  final String name;

  /// The delay between [interact] and triggering.
  /// Delay starts/restarts on each interaction.
  final Duration triggerDelay;

  /// The limit of delay between 1st [interact] and triggering.
  /// Delay starts in the 1st call to [interact] and is zeroed when the trigger is called.
  ///
  /// * NOTE: After the trigger is called, the next call to [interact] is considered a 1st call.
  final Duration? triggerDelayLimit;

  Function? functionToTrigger;

  InteractionCompleter(this.name,
      {Duration? triggerDelay, this.functionToTrigger, this.triggerDelayLimit})
      : triggerDelay = triggerDelay ?? Duration(milliseconds: 500);

  int get now {
    return DateTime.now().millisecondsSinceEpoch;
  }

  int get triggerDelayMs => triggerDelay.inMilliseconds;

  bool get hasTriggerDelayLimit =>
      triggerDelayLimit != null && triggerDelayLimit!.inMilliseconds > 0;

  int? _initInteractionTime;
  int? _lastInteractionTime;

  int? get lastInteractionTime => _lastInteractionTime;

  bool _interactionNotTriggered = false;

  bool get hasInteractionNotTriggered => _interactionNotTriggered;

  List? _lastInteractionParameters;

  List? get lastInteractionParameters => _lastInteractionParameters;

  void disposeLastInteractionParameters() {
    _lastInteractionParameters = null;
  }

  /// Marks an interaction and schedules delayed trigger.
  ///
  /// [noTriggering] If [true] won't schedule trigger, only mark interaction.
  /// [interactionParameters] Stores parameters that can be used while triggering, using [lastInteractionParameters].
  void interact(
      {noTriggering = false,
      List? interactionParameters,
      bool ignoreConsecutiveEqualsParameters = false}) {
    noTriggering ??= false;

    if (interactionParameters != null) {
      if (ignoreConsecutiveEqualsParameters) {
        if (_lastInteractionParameters != null &&
            isEqualsDeep(_lastInteractionParameters, interactionParameters)) {
          log('ignore interact', [noTriggering, interactionParameters]);
          return;
        }
      }

      _lastInteractionParameters = interactionParameters;
    }

    log('interact', [noTriggering, interactionParameters]);

    var now = this.now;

    _lastInteractionTime = now;
    _initInteractionTime ??= now;
    _interactionNotTriggered = true;

    if (!noTriggering) {
      _scheduleTrigger(triggerDelayMs);
    }
  }

  int? get interactionElapsedTime =>
      _lastInteractionTime != null ? now - _lastInteractionTime! : null;

  int? get fullInteractionElapsedTime =>
      _initInteractionTime != null ? now - _initInteractionTime! : null;

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

    var timeUntilNextTrigger = triggerDelayMs - interactionElapsedTime!;

    log('_callTrigger', [timeUntilNextTrigger]);

    if (timeUntilNextTrigger > 0) {
      if (hasTriggerDelayLimit &&
          fullInteractionElapsedTime! > triggerDelayLimit!.inMilliseconds) {
        triggerNow();
      } else {
        Future.delayed(
            Duration(milliseconds: timeUntilNextTrigger), () => _callTrigger());
      }
    } else {
      triggerNow();
    }
  }

  /// Triggers only if already has some interaction.
  void triggerIfHasInteraction({List? interactionParameters}) {
    if (hasInteractionNotTriggered) {
      triggerNow(interactionParameters: interactionParameters);
    }
  }

  final EventStream<InteractionCompleter> onComplete = EventStream();

  /// Triggers immediately.
  void triggerNow({List? interactionParameters}) {
    log('triggerNow');

    if (interactionParameters != null) {
      _lastInteractionParameters = interactionParameters;
    }

    _triggerScheduled = false;
    _interactionNotTriggered = false;
    _initInteractionTime = null;

    if (functionToTrigger != null) {
      try {
        functionToTrigger!();
      } catch (e, s) {
        print(e);
        print(s);
      }
    }

    onComplete.add(this);
  }

  /// Cancels any event scheduled to be triggered.
  void cancel() {
    log('cancel');

    _triggerScheduled = false;
    _interactionNotTriggered = false;
  }

  /// [cancel] this instance and dispose any resource.
  void dispose() {
    log('dispose');

    cancel();
    _lastInteractionParameters = null;
  }

  void log(String method, [List? parameters]) {
    //print('InteractionCompleter[$name] $method> ${parameters ?? ''}');
  }
}

/// A dummy version of [InteractionCompleter].
class InteractionCompleterDummy extends InteractionCompleter {
  InteractionCompleterDummy() : super('');

  @override
  void interact(
      {noTriggering = false,
      List? interactionParameters,
      bool ignoreConsecutiveEqualsParameters = false}) {}

  @override
  void triggerIfHasInteraction({List? interactionParameters}) {}

  @override
  void triggerNow({List? interactionParameters}) {}
}

/// Listen [stream], calling [onData] only after [triggerDelay] duration.
///
/// [onData] is only called when [stream] event is triggered and stays
/// without any new event for [triggerDelay] duration.
InteractionCompleter listenStreamWithInteractionCompleter<T>(
    Stream<T> stream, Duration triggerDelay, void Function(T? event) onData) {
  var lastEvent = [];

  var interactionCompleter = InteractionCompleter(
      'listenStreamWithInteractionCompleter[$stream]',
      triggerDelay: triggerDelay, functionToTrigger: () {
    var event = lastEvent.isNotEmpty ? lastEvent.first : null;
    onData(event is T ? event : null);
  });

  stream.listen((Object? event) {
    lastEvent.clear();
    lastEvent.add(event);
    interactionCompleter.interact();
  });

  return interactionCompleter;
}

/// A wrapper and handler for a value that is asynchronous (from a [Future]).
class AsyncValue<T> {
  late final Future<T> _future;

  AsyncValue(Future<T> future) {
    _future = future.then((v) => _onLoad(v)!, onError: _onError);
  }

  factory AsyncValue.from(Object? value) {
    if (value is Future) {
      return AsyncValue(value as Future<T>);
    } else if (value is Future<T> Function()) {
      var future = value();
      return AsyncValue<T>(future);
    } else if (value is Future Function()) {
      var future = value();
      return AsyncValue(future as Future<T>);
    } else if (value is T Function()) {
      var future = Future.microtask(() => value());
      return AsyncValue<T>(future);
    } else if (value is Function) {
      var future = Future.microtask(() async {
        var result = value();
        if (result is Future) {
          var result2 = await result;
          return result2;
        } else {
          return result;
        }
      });
      return AsyncValue(future as Future<T>);
    } else {
      throw ArgumentError('Not an async value: $value');
    }
  }

  Future<T> get future => _future;

  /// Handles `load` events.
  final EventStream<T?> onLoad = EventStream();

  bool _loaded = false;

  /// Returns [true] if value is loaded.
  bool get isLoaded => _loaded;

  /// Returns [true] if [isLoaded] and no error (OK).
  bool get isLoadedOK => _loaded && _error == null;

  /// Returns [true] if [isLoaded] and has an [error]
  bool get isLoadedWithError => _loaded && _error != null;

  Object? _error;

  Object? get error => _error;

  /// Returns [true] if the value has an execution [error].
  bool get hasError => _error != null;

  T? _value;

  T? _onLoad(value) {
    _loaded = true;
    _value = value;
    onLoad.add(value);
    return value;
  }

  void _onError(error) {
    _loaded = true;
    _error = error ?? 'error';
    onLoad.add(null);
  }

  /// Returns the value (only if already loaded).
  ///
  /// [StateError] in case the value is not loaded yet.
  T? get() {
    if (!isLoaded) throw StateError('Not loaded yet!');
    return _value;
  }

  /// Returns the value if loaded.
  T? getIfLoaded() => _value;

  /// Returns a [Future<T>] with the value.
  Future<T?> getAsync() async {
    if (isLoaded) return _value;
    await _future;
    return _value;
  }

  /// Disposes the value, error and future associated.
  void dispose() {
    _future = Future<T>.value();
    _error = null;
    _value = null;
  }
}

/// Wraps [Stream] listen call.
///
/// Useful to create a one shot listener or extend and introduce different behaviors.
class ListenerWrapper<T> {
  /// [Stream] to wrap [listen] calls.
  final Stream<T> stream;

  final void Function(T event) onData;

  final Function? onError;

  final void Function()? onDone;

  final bool cancelOnError;

  final Object? singletonIdentifier;

  final bool singletonIdentifyByInstance;

  /// See [Stream.listen].
  ListenerWrapper(this.stream, this.onData,
      {this.onError,
      this.onDone,
      this.cancelOnError = false,
      this.oneShot = false,
      this.singletonIdentifier,
      this.singletonIdentifyByInstance = true});

  /// If [true] will wait for 1 event and call [cancel].
  bool oneShot = false;

  int _eventCount = 0;

  int get eventCount => _eventCount;

  /// Wrapper for any [event] or [error].
  void onEvent(T? event, Object? error, StackTrace? stackTrace) {
    ++_eventCount;
    if (oneShot) {
      cancel();
    }
  }

  /// Wrapper for [event].
  void onDataWrapper(T event) {
    onEvent(event, null, null);
    onData(event);
  }

  int _errorCount = 0;

  int get errorCount => _errorCount;

  /// Wrapper for [error].
  void onErrorWrapper(Object error, StackTrace stackTrace) {
    ++_errorCount;

    onEvent(null, error, stackTrace);

    if (onError is void Function(Object error, StackTrace stackTrace)) {
      onError!(error, stackTrace);
    } else if (onError is void Function(Object error)) {
      onError!(error);
    } else if (onError is void Function()) {
      onError!();
    } else if (onError != null) {
      onError!.call();
    }
  }

  /// Wrapper called when done.
  void onDoneWrapper() {
    onEvent(null, null, null);
    if (onDone != null) {
      onDone!();
    }
  }

  StreamSubscription<T>? _subscription;

  /// The last [stream.listen] [StreamSubscription].
  StreamSubscription<T>? get subscription => _subscription;

  /// Returns [true] if listening.
  bool get isListening => _subscription != null;

  /// Calls [stream.listen] and sets [subscription].
  ///
  /// Returns [false] if already listening.
  bool listen() {
    if (isListening) return false;

    if (stream is EventStream) {
      var eventStream = stream as EventStream;
      _subscription = eventStream.listen(
              onDataWrapper as void Function(Object?),
              onError: onErrorWrapper,
              onDone: onDoneWrapper,
              cancelOnError: cancelOnError,
              singletonIdentifier: singletonIdentifier,
              singletonIdentifyByInstance: singletonIdentifyByInstance)
          as StreamSubscription<T>?;
    } else {
      _subscription = stream.listen(onDataWrapper,
          onError: onErrorWrapper,
          onDone: onDoneWrapper,
          cancelOnError: cancelOnError);
    }

    return _subscription != null;
  }

  /// Cancels [subscription];
  void cancel() {
    _subscription?.cancel();
    _subscription = null;
  }
}

/// Ensures that a call is executed only 1 per time.
class UniqueCaller<R> {
  final FutureOr<R?> Function() function;

  final void Function(UniqueCaller<R> caller)? onDuplicatedCall;

  final _IdentifierWrapper _identifier;

  static String stackTraceIdentifier([int stackOffset = 0]) {
    var stackTracer = StackTrace.current;
    var stackTraceStr = stackTracer.toString();

    var lines = stackTraceStr.split(RegExp(r'[\r\n]+', multiLine: false));

    var start = Math.min(1 + stackOffset, lines.length - 1);
    var end = Math.min(3, lines.length);

    lines = lines.sublist(start, Math.max(start, end));

    var s = lines.join('\n');
    return s;
  }

  UniqueCaller(this.function,
      {Object? identifier,
      StackTrace? stackTraceIdentifier,
      this.onDuplicatedCall})
      : _identifier = _IdentifierWrapper(identifier ??
            stackTraceIdentifier?.toString() ??
            UniqueCaller.stackTraceIdentifier());

  Object get identifier => _identifier;

  static final Set<_IdentifierWrapper> _calling = {};

  static final Map<_IdentifierWrapper, Future> _callsFuture = {};

  static Future<R?> getCallFuture<R>(Object identifier) {
    var identifierWrapper = _IdentifierWrapper(identifier);
    return _callsFuture[identifierWrapper] as Future<R?>;
  }

  static List<Future> get calling {
    return _callsFuture.values.toList();
  }

  Future<R?> callAsync() async {
    if (_calling.contains(_identifier)) {
      if (onDuplicatedCall != null) onDuplicatedCall!(this);
      return Future<R?>.value(null);
    }

    _calling.add(_identifier);
    try {
      var ret = function();
      if (ret is Future) {
        _callsFuture[_identifier] = ret as Future;
        return await ret;
      } else {
        return ret;
      }
    } finally {
      _finalizeCall();
    }
  }

  R? call() {
    if (_calling.contains(_identifier)) {
      if (onDuplicatedCall != null) onDuplicatedCall!(this);
      return null;
    }

    _calling.add(_identifier);
    try {
      var ret = function();
      if (ret is Future) {
        var future = ret as Future;
        _callsFuture[_identifier] = future;
        future.then((value) {
          _finalizeCall();
          return value;
        });
        return null;
      } else {
        _finalizeCall();
        return ret;
      }
    } catch (e) {
      _finalizeCall();
      rethrow;
    }
  }

  void _finalizeCall() {
    // ignore: unawaited_futures
    _callsFuture.remove(_identifier);
    _calling.remove(_identifier);
  }
}

class _IdentifierWrapper {
  final Object identifier;

  _IdentifierWrapper(this.identifier);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _IdentifierWrapper &&
          runtimeType == other.runtimeType &&
          _identical(identifier, other.identifier);

  bool _identical(Object? o1, Object? o2) {
    if (o1 == null && o2 == null) return true;
    if (identical(o1, o2)) return true;
    if (o1 != null && o2 == null) return false;
    if (o1 == null && o2 != null) return false;

    if (o1.runtimeType != o2.runtimeType) return false;

    if (o1 is Future || o1 is Function) {
      return false;
    } else {
      return o1 == o2;
    }
  }

  @override
  int get hashCode => identifier.hashCode;

  @override
  String toString() {
    return '_IdentifierWrapper{hashCode: $hashCode ; identifier: $identifier}';
  }
}
