import 'dart:async';

import 'package:swiss_knife/swiss_knife.dart';
import 'package:test/test.dart';

/// A key with value equality (non identical instances can be equal).
class _Key {
  final String name;

  _Key(this.name);

  @override
  bool operator ==(Object other) => other is _Key && other.name == name;

  @override
  int get hashCode => name.hashCode;
}

Future<void> _tick() => Future.delayed(Duration.zero);

void main() {
  group('EventStream singletons', () {
    test('onDone of a singleton listener releases the identifier', () async {
      var es = EventStream<int>();

      var done = 0;
      var values = <int>[];
      var sub = es.listen(
        values.add,
        singletonIdentifier: 'S',
        onDone: () => done++,
      );
      expect(es.getSingletonSubscription('S'), same(sub));

      es.add(1);
      await es.close();

      expect(values, equals([1]));
      expect(done, equals(1));
      expect(es.getSingletonSubscription('S'), isNull);
      expect(es.cancelSingletonSubscription('S'), isFalse);
    });

    test('onDone of a singleton listener without a callback', () async {
      var es = EventStream<int>();
      es.listen((_) {}, singletonIdentifier: 'S');
      await es.close();
      expect(es.getSingletonSubscription('S'), isNull);
    });

    test('singletonIdentifyByInstance', () async {
      var es = EventStream<int>();

      var a = <int>[];
      var b = <int>[];

      // By instance (default): equal but not identical keys are different.
      var subA = es.listen(a.add, singletonIdentifier: _Key('k'));
      var subB = es.listen(b.add, singletonIdentifier: _Key('k'));
      expect(identical(subA, subB), isFalse);
      expect(es.getSingletonSubscription(_Key('k')), isNull);

      es.add(1);
      await _tick();
      expect(a, equals([1]));
      expect(b, equals([1]));

      es.cancelAllSingletonSubscriptions();

      // By equality:
      var c = <int>[];
      var subC1 = es.listen(
        c.add,
        singletonIdentifier: _Key('k'),
        singletonIdentifyByInstance: false,
      );
      var subC2 = es.listen(
        c.add,
        singletonIdentifier: _Key('k'),
        singletonIdentifyByInstance: false,
      );
      expect(subC2, same(subC1));
      expect(es.getSingletonSubscription(_Key('k'), false), same(subC1));
      // NOTE: current behaviour: the lookup compares with the *stored*
      // signature's mode (`stored == lookup`), so a by-equality registration
      // is also found by a by-instance lookup.
      expect(es.getSingletonSubscription(_Key('k')), same(subC1));

      es.add(2);
      await _tick();
      expect(c, equals([2]));

      expect(es.cancelSingletonSubscription(_Key('k'), false), isTrue);
      es.add(3);
      await _tick();
      expect(c, equals([2]));
      expect(a, equals([1]));

      await es.close();
    });

    test('cancelAllSingletonSubscriptions without singletons', () {
      var es = EventStream<int>();
      es.cancelAllSingletonSubscriptions();
      expect(es.getSingletonSubscription('x'), isNull);
      expect(es.cancelSingletonSubscription('x'), isFalse);
    });

    test('listenOneShot ignores singletonIdentifier', () async {
      var es = EventStream<int>();

      var a = <int>[];
      var b = <int>[];

      // NOTE: current behaviour; possibly a bug: `EventStream.listenOneShot`
      // accepts `singletonIdentifier`/`singletonIdentifyByInstance` but never
      // passes them to the `ListenerWrapper`, so two one-shot listeners with
      // the same identifier are both registered and no singleton
      // subscription is recorded.
      var w1 = es.listenOneShot(a.add, singletonIdentifier: 'ONE')!;
      var w2 = es.listenOneShot(b.add, singletonIdentifier: 'ONE')!;

      expect(identical(w1.subscription, w2.subscription), isFalse);
      expect(w1.singletonIdentifier, isNull);
      expect(es.getSingletonSubscription('ONE'), isNull);

      es.add(1);
      es.add(2);
      await _tick();

      expect(a, equals([1]));
      expect(b, equals([1]));

      await es.close();
    });

    test('listenOneShot with onError and onDone', () async {
      var es = EventStream<int>();

      var errors = <Object>[];
      var values = <int>[];
      var w = es.listenOneShot(
        values.add,
        onError: (Object e) => errors.add(e),
      )!;

      es.addError('E1');
      es.add(1);
      await _tick();

      // The error was the one shot:
      expect(errors, equals(['E1']));
      expect(values, isEmpty);
      expect(w.errorCount, equals(1));
      expect(w.eventCount, equals(1));
      expect(w.isListening, isFalse);

      var done = 0;
      var w2 = es.listenOneShot((_) {}, onDone: () => done++)!;
      await es.close();
      expect(done, equals(1));
      expect(w2.isListening, isFalse);
    });
  });

  group('ListenerWrapper', () {
    test('over an EventStream with a singletonIdentifier', () async {
      var es = EventStream<int>();
      var values = <int>[];

      var w = ListenerWrapper<int>(
        es,
        values.add,
        singletonIdentifier: 'W',
        singletonIdentifyByInstance: false,
      );
      expect(w.listen(), isTrue);
      expect(es.getSingletonSubscription('W', false), same(w.subscription));

      // Another wrapper with the same identifier shares the subscription:
      var w2 = ListenerWrapper<int>(
        es,
        (_) {},
        singletonIdentifier: 'W',
        singletonIdentifyByInstance: false,
      );
      expect(w2.listen(), isTrue);
      expect(w2.subscription, same(w.subscription));

      es.add(7);
      await _tick();
      expect(values, equals([7]));
      expect(w.eventCount, equals(1));
      expect(w2.eventCount, equals(0));

      await es.close();
    });

    test('onError with an incompatible signature', () {
      var w = ListenerWrapper<int>(
        Stream<int>.empty(),
        (_) {},
        onError: (String error) {},
      );
      // Not a `(Object, StackTrace)`, `(Object)` or `()` function: it is
      // called with no arguments, which fails.
      expect(
        () => w.onErrorWrapper('e', StackTrace.current),
        throwsNoSuchMethodError,
      );
      expect(w.errorCount, equals(1));
      expect(w.eventCount, equals(1));
    });

    test('onDoneWrapper without onDone', () {
      var w = ListenerWrapper<int>(Stream<int>.empty(), (_) {});
      w.onDoneWrapper();
      expect(w.eventCount, equals(1));
    });
  });

  group('EventStreamDelegator', () {
    test('delegates the Stream API (short-circuit and errors)', () async {
      var es = EventStream<int>();
      var d = EventStreamDelegator(es);

      var futureFirst = d.first;
      var futureAny = d.any((e) => e == 2);
      var futureElementAt = d.elementAt(1);
      var futureFirstWhere = d.firstWhere((e) => e > 1);
      var futureIsEmpty = d.isEmpty;
      var futureTake = d.take(2).toList();
      var futureTakeWhile = d.takeWhile((e) => e < 3).toList();
      var futureAsFuture = d.listenAsFuture();
      var futureList = d.toList();

      expect(d.isUsed, isTrue);
      expect(d.isBroadcast, isTrue);
      expect(d.isPaused, isFalse);

      d.add(1);
      d.add(2);
      d.add(3);

      await d.close();
      expect(d.isClosed, isTrue);

      expect(await futureFirst, equals(1));
      expect(await futureAsFuture, equals(1));
      expect(await futureFirstWhere, equals(2));
      expect(await futureElementAt, equals(2));
      expect(await futureAny, isTrue);
      expect(await futureIsEmpty, isFalse);
      expect(await futureTake, equals([1, 2]));
      expect(await futureTakeWhile, equals([1, 2]));
      expect(await futureList, equals([1, 2, 3]));
    });

    test('handleError', () async {
      var es = EventStream<int>();
      var d = EventStreamDelegator(es);

      var handled = <Object>[];
      var futureList = d
          .handleError(
            (Object e) => handled.add(e),
            test: (e) => e == 'handled',
          )
          .toList();

      d.add(1);
      d.addError('handled', StackTrace.current);
      d.add(2);
      await d.close();

      expect(await futureList, equals([1, 2]));
      expect(handled, equals(['handled']));
    });

    test('delegates the Stream API (no errors)', () async {
      var es = EventStream<int>();
      var d = EventStreamDelegator(es);

      var futureSet = d.toSet();
      var futureLast = d.last;
      var futureLength = d.length;
      var futureJoin = d.join('-');
      var futureEvery = d.every((e) => e > 0);
      var futureContains = d.contains(3);
      var futureFold = d.fold<int>(0, (p, e) => p + e);
      var futureReduce = d.reduce((p, e) => p * e);
      var futureLastWhere = d.lastWhere((e) => e < 3);
      var futureMap = d.map((e) => e * 10).toList();
      var futureWhere = d.where((e) => e.isOdd).toList();
      var futureSkip = d.skip(1).toList();
      var futureSkipWhile = d.skipWhile((e) => e < 2).toList();
      var futureExpand = d.expand((e) => [e]).toList();
      var futureAsyncMap = d.asyncMap((e) async => '$e').toList();
      var futureAsyncExpand = d
          .asyncExpand((e) => Stream.fromIterable([e, e]))
          .toList();
      var futureCast = d.cast<num>().toList();
      var futureDistinct = d.distinct().toList();
      var futureTransform = d
          .transform(
            StreamTransformer<int, String>.fromHandlers(
              handleData: (e, sink) => sink.add('<$e>'),
            ),
          )
          .toList();
      var forEachValues = <int>[];
      var futureForEach = d.forEach(forEachValues.add);
      var futureDrain = d.drain<String>('drained');
      var futureBroadcast = d.asBroadcastStream().toList();
      var futureTimeout = d.timeout(Duration(seconds: 10)).toList();

      d.add(1);
      d.add(2);
      d.add(3);
      d.add(3);
      await d.close();

      expect(await futureSet, equals({1, 2, 3}));
      expect(await futureLast, equals(3));
      expect(await futureLength, equals(4));
      expect(await futureJoin, equals('1-2-3-3'));
      expect(await futureEvery, isTrue);
      expect(await futureContains, isTrue);
      expect(await futureFold, equals(9));
      expect(await futureReduce, equals(18));
      expect(await futureLastWhere, equals(2));
      expect(await futureMap, equals([10, 20, 30, 30]));
      expect(await futureWhere, equals([1, 3, 3]));
      expect(await futureSkip, equals([2, 3, 3]));
      expect(await futureSkipWhile, equals([2, 3, 3]));
      expect(await futureExpand, equals([1, 2, 3, 3]));
      expect(await futureAsyncMap, equals(['1', '2', '3', '3']));
      expect(await futureAsyncExpand, equals([1, 1, 2, 2, 3, 3, 3, 3]));
      expect(await futureCast, equals([1, 2, 3, 3]));
      expect(await futureDistinct, equals([1, 2, 3]));
      expect(await futureTransform, equals(['<1>', '<2>', '<3>', '<3>']));
      await futureForEach;
      expect(forEachValues, equals([1, 2, 3, 3]));
      expect(await futureDrain, equals('drained'));
      expect(await futureBroadcast, equals([1, 2, 3, 3]));
      expect(await futureTimeout, equals([1, 2, 3, 3]));
    });

    test('single, singleWhere, addStream and pipe', () async {
      var es = EventStream<String>();
      var d = EventStreamDelegator(es);

      var futureSingle = d.single;
      var futureSingleWhere = d.singleWhere((e) => e == 'x');
      var piped = StreamController<String>();
      var pipedList = piped.stream.toList();
      var futurePipe = d.pipe(piped);

      await d.addStream(Stream.fromIterable(['x']));
      await d.close();

      expect(await futureSingle, equals('x'));
      expect(await futureSingleWhere, equals('x'));
      await futurePipe;
      expect(await pipedList, equals(['x']));
    });

    test('addError and singleton subscriptions', () async {
      var es = EventStream<int>();
      var d = EventStreamDelegator(es);

      var errors = <Object>[];
      var sub = d.listen(
        (_) {},
        onError: (Object e) => errors.add(e),
        singletonIdentifier: 'S',
      );
      expect(d.getSingletonSubscription('S'), same(sub));
      expect(es.getSingletonSubscription('S'), same(sub));

      d.addError('E');
      await _tick();
      expect(errors, equals(['E']));

      expect(d.cancelSingletonSubscription('S'), isTrue);
      expect(d.getSingletonSubscription('S'), isNull);

      d.listen((_) {}, singletonIdentifier: 'T');
      d.cancelAllSingletonSubscriptions();
      expect(es.getSingletonSubscription('T'), isNull);

      await d.close();
    });

    test('provider returning null', () {
      var d = EventStreamDelegator<int>.provider(() => null);
      expect(d.eventStream, isNull);
      expect(d.getSingletonSubscription('x'), isNull);
      expect(d.eventValidator, isNull);
      d.eventValidator = (s, e) => true;
      expect(d.eventValidator, isNull);
      // Explicit flush without a stream: no-op.
      d.flush();
      expect(d.listenOneShot((_) {}), isNull);
      d.clearUnflushed();
    });

    test('listenOneShot with an EventStream', () async {
      var es = EventStream<int>();
      var d = EventStreamDelegator(es);

      var values = <int>[];
      var w = d.listenOneShot(values.add, cancelOnError: false)!;
      expect(w.oneShot, isTrue);

      d.add(1);
      d.add(2);
      await _tick();
      expect(values, equals([1]));

      // Regression: the delegator forwarded `cancelOnError!`, so calling
      // `listenOneShot` without it threw a `TypeError`.
      var w2 = d.listenOneShot(values.add)!;
      expect(w2.oneShot, isTrue);
      d.add(3);
      d.add(4);
      await _tick();
      expect(values, equals([1, 3]));

      await d.close();
    });

    test('buffered listenOneShot is registered on flush', () async {
      EventStream<int>? target;
      var d = EventStreamDelegator<int>.provider(() => target);

      var values = <int>[];
      expect(d.listenOneShot(values.add, cancelOnError: false), isNull);

      d.add(1);

      target = EventStream<int>();
      // Flushes: registers the one-shot listener, then adds `1`.
      expect(d.eventStream, same(target));

      d.add(2);
      await _tick();
      expect(values, equals([1]));

      await d.close();
    });

    test('buffered listenOneShot without cancelOnError on flush', () async {
      EventStream<int>? target;
      var d = EventStreamDelegator<int>.provider(() => target);

      var values = <int>[];
      expect(d.listenOneShot(values.add), isNull);

      target = EventStream<int>();

      // Regression: the buffered `cancelOnError` was `null` and `flush`
      // forwarded it to a non-nullable `bool`, so the first access to
      // `eventStream` threw a `TypeError`.
      expect(d.eventStream, same(target));

      d.add(1);
      d.add(2);
      await _tick();
      expect(values, equals([1]));

      await d.close();
    });

    test('subscription returned while buffering', () async {
      EventStream<int>? target;
      var d = EventStreamDelegator<int>.provider(() => target);

      var values = <int>[];
      var sub = d.listen(values.add);

      target = EventStream<int>();
      // Flushes: registers `values.add` on `target`.
      expect(d.eventStream, same(target));

      d.add(1);
      await _tick();
      expect(values, equals([1]));

      // NOTE: current behaviour; possibly a bug: the subscription returned
      // while buffering is a lazy proxy that calls `listen` again on first
      // use, so it controls a second subscription (duplicating events) and
      // cancelling it does not cancel the listener registered by `flush`.
      expect(sub.isPaused, isFalse);
      d.add(2);
      await _tick();
      expect(values, equals([1, 2, 2]));

      await sub.cancel();
      d.add(3);
      await _tick();
      expect(values, equals([1, 2, 2, 3]));

      await d.close();
    });

    test('subscription proxy delegates to the subscription', () async {
      EventStream<int>? target;
      var d = EventStreamDelegator<int>.provider(() => target);

      var sub = d.listen((_) {});
      d.clearUnflushed();
      target = EventStream<int>();

      var data = <int>[];
      var errors = <Object>[];
      var done = false;

      sub.onData(data.add);
      sub.onError((Object e) => errors.add(e));
      sub.onDone(() => done = true);

      sub.pause();
      expect(sub.isPaused, isTrue);
      d.add(1);
      d.addError('E');
      await _tick();
      expect(data, isEmpty);

      sub.resume();
      expect(sub.isPaused, isFalse);
      await _tick();
      expect(data, equals([1]));
      expect(errors, equals(['E']));

      await d.close();
      await _tick();
      expect(done, isTrue);
    });

    test('subscription proxy asFuture', () async {
      EventStream<int>? target;
      var d = EventStreamDelegator<int>.provider(() => target);

      var sub = d.listen((_) {});
      d.clearUnflushed();
      target = EventStream<int>();

      var future = sub.asFuture<String>('finished');
      d.add(1);
      await d.close();
      expect(await future, equals('finished'));
    });
  });

  group('AsyncValue.from', () {
    test(
      'a `Future Function()` that is not a `Future<T> Function()`',
      () async {
        // Declared return type `Future<dynamic>`, returning a `Future<int>`:
        Future<dynamic> f() => Future<int>.value(4);
        var av = AsyncValue<int>.from(f);
        expect(await av.future, equals(4));
        expect(av.get(), equals(4));
      },
    );

    test('a function not returning T', () async {
      String f() => 'x';
      // NOTE: current behaviour; possibly a bug (dead branch): a generic
      // `Function` (not `T Function()` nor `Future Function()`) has its result
      // wrapped in a `Future<dynamic>`, which can never be cast to
      // `Future<T>` for such a `T`, so the branch always throws.
      expect(() => AsyncValue<int>.from(f), throwsA(isA<TypeError>()));

      // A `Future Function()` returning a `Future` of another type:
      Future<String> fAsync() async => 'y';
      expect(() => AsyncValue<int>.from(fAsync), throwsA(isA<TypeError>()));

      // Let the scheduled microtasks run:
      await _tick();
    });
  });

  group('InteractionCompleter', () {
    test('triggerDelayLimit forces the trigger', () async {
      var calls = 0;
      var ic = InteractionCompleter(
        'limit',
        triggerDelay: Duration(milliseconds: 200),
        triggerDelayLimit: Duration(milliseconds: 1),
        functionToTrigger: () => calls++,
      );
      expect(ic.hasTriggerDelayLimit, isTrue);

      var completed = ic.onComplete.first;

      ic.interact();
      expect(ic.isTriggerScheduled, isTrue);

      // A new interaction postpones the trigger, but the limit was exceeded:
      await Future.delayed(Duration(milliseconds: 50));
      ic.interact();
      var secondInteraction = DateTime.now();

      expect(await completed, same(ic));
      expect(calls, equals(1));
      expect(ic.isTriggerScheduled, isFalse);
      expect(ic.hasInteractionNotTriggered, isFalse);

      // Triggered at the first schedule (~150ms after the 2nd interaction),
      // not after a full `triggerDelay` (200ms) since the 2nd interaction:
      var elapsed = DateTime.now().difference(secondInteraction);
      expect(elapsed.inMilliseconds, lessThan(200));
    });

    test('without a limit a new interaction postpones the trigger', () async {
      var ic = InteractionCompleter(
        'no-limit',
        triggerDelay: Duration(milliseconds: 40),
        triggerDelayLimit: Duration.zero,
      );
      expect(ic.hasTriggerDelayLimit, isFalse);

      var completed = ic.onComplete.first;
      ic.interact();
      await Future.delayed(Duration(milliseconds: 20));
      ic.interact();
      var secondInteraction = DateTime.now();

      expect(await completed, same(ic));
      var elapsed = DateTime.now().difference(secondInteraction);
      expect(elapsed.inMilliseconds, greaterThanOrEqualTo(30));
    });
  });

  group('UniqueCaller', () {
    test('identifier from a StackTrace', () {
      var stackTrace = StackTrace.current;
      var caller = UniqueCaller<int>(() => 1, stackTraceIdentifier: stackTrace);
      var identifier = caller.identifier;
      expect(identifier.hashCode, equals(stackTrace.toString().hashCode));
      expect(identifier.toString(), contains('_IdentifierWrapper{hashCode: '));
      expect(caller.call(), equals(1));
    });

    test('identifier toString and hashCode', () {
      var caller = UniqueCaller<int>(() => 1, identifier: 'my-id');
      expect(caller.identifier.hashCode, equals('my-id'.hashCode));
      expect(
        caller.identifier.toString(),
        equals(
          '_IdentifierWrapper{hashCode: ${'my-id'.hashCode} ; '
          'identifier: my-id}',
        ),
      );
    });

    test('async call releases the identifier after completion', () async {
      var completer = Completer<int>();
      var duplicated = 0;
      var caller = UniqueCaller<int>(
        () => completer.future,
        identifier: 'async-call-id',
        onDuplicatedCall: (_) => duplicated++,
      );

      expect(caller.call(), isNull);
      expect(caller.call(), isNull);
      expect(duplicated, equals(1));

      completer.complete(5);
      await _tick();

      expect(UniqueCaller.calling, isEmpty);
      var caller2 = UniqueCaller<int>(() => 6, identifier: 'async-call-id');
      expect(caller2.call(), equals(6));
    });
  });
}
