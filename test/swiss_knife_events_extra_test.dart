import 'dart:async';

import 'package:swiss_knife/swiss_knife.dart';
import 'package:test/test.dart';

void main() {
  group('EventStream', () {
    test('add before listen is ignored', () async {
      var es = EventStream<int>();
      es.add(1);
      es.addError('ignored');
      expect(es.isUsed, isFalse);
      expect(es.isClosed, isFalse);
      expect(es.isPaused, isFalse);
      await es.close();
    });

    test('stream API delegates', () async {
      var es = EventStream<int>();

      var futureList = es.toList();
      var futureSet = es.toSet();
      var futureFirst = es.first;
      var futureLast = es.last;
      var futureLength = es.length;
      var futureJoin = es.join(',');
      var futureAny = es.any((e) => e == 2);
      var futureEvery = es.every((e) => e > 0);
      var futureContains = es.contains(3);
      var futureElementAt = es.elementAt(1);
      var futureFold = es.fold<int>(0, (p, e) => p + e);
      var futureReduce = es.reduce((p, e) => p * e);
      var futureFirstWhere = es.firstWhere((e) => e > 1);
      var futureLastWhere = es.lastWhere((e) => e < 3);
      var futureIsEmpty = es.isEmpty;
      var futureMapped = es.map((e) => e * 10).toList();
      var futureWhere = es.where((e) => e.isOdd).toList();
      var futureSkip = es.skip(1).toList();
      var futureTake = es.take(2).toList();
      var futureSkipWhile = es.skipWhile((e) => e < 2).toList();
      var futureTakeWhile = es.takeWhile((e) => e < 3).toList();
      var futureExpand = es.expand((e) => [e, e]).toList();
      var futureAsyncMap = es.asyncMap((e) async => '$e').toList();
      var futureAsyncExpand = es
          .asyncExpand((e) => Stream.fromIterable([e]))
          .toList();
      var futureCast = es.cast<num>().toList();
      var futureDistinct = es.distinct().toList();
      var futureTransform = es
          .transform(
            StreamTransformer<int, String>.fromHandlers(
              handleData: (e, sink) => sink.add('<$e>'),
            ),
          )
          .toList();
      var futureForEach = <int>[];
      var forEachDone = es.forEach(futureForEach.add);
      var futureDrain = es.drain<String>('drained');
      var futureBroadcast = es.asBroadcastStream().toList();
      var futureTimeout = es.timeout(Duration(seconds: 10)).toList();

      expect(es.isUsed, isTrue);
      expect(es.isBroadcast, isTrue);

      es.add(1);
      es.add(2);
      es.add(3);
      await es.close();

      expect(es.isClosed, isTrue);

      expect(await futureList, equals([1, 2, 3]));
      expect(await futureSet, equals({1, 2, 3}));
      expect(await futureFirst, equals(1));
      expect(await futureLast, equals(3));
      expect(await futureLength, equals(3));
      expect(await futureJoin, equals('1,2,3'));
      expect(await futureAny, isTrue);
      expect(await futureEvery, isTrue);
      expect(await futureContains, isTrue);
      expect(await futureElementAt, equals(2));
      expect(await futureFold, equals(6));
      expect(await futureReduce, equals(6));
      expect(await futureFirstWhere, equals(2));
      expect(await futureLastWhere, equals(2));
      expect(await futureIsEmpty, isFalse);
      expect(await futureMapped, equals([10, 20, 30]));
      expect(await futureWhere, equals([1, 3]));
      expect(await futureSkip, equals([2, 3]));
      expect(await futureTake, equals([1, 2]));
      expect(await futureSkipWhile, equals([2, 3]));
      expect(await futureTakeWhile, equals([1, 2]));
      expect(await futureExpand, equals([1, 1, 2, 2, 3, 3]));
      expect(await futureAsyncMap, equals(['1', '2', '3']));
      expect(await futureAsyncExpand, equals([1, 2, 3]));
      expect(await futureCast, equals([1, 2, 3]));
      expect(await futureDistinct, equals([1, 2, 3]));
      expect(await futureTransform, equals(['<1>', '<2>', '<3>']));
      await forEachDone;
      expect(futureForEach, equals([1, 2, 3]));
      expect(await futureDrain, equals('drained'));
      expect(await futureBroadcast, equals([1, 2, 3]));
      expect(await futureTimeout, equals([1, 2, 3]));
    });

    test('single and singleWhere', () async {
      var es = EventStream<String>();
      var futureSingle = es.single;
      var futureSingleWhere = es.singleWhere((e) => e == 'x');
      es.add('x');
      await es.close();
      expect(await futureSingle, equals('x'));
      expect(await futureSingleWhere, equals('x'));
    });

    test('addError and handleError', () async {
      var es = EventStream<int>();

      var errors = <Object>[];
      var values = <int>[];
      es.listen(values.add, onError: (Object e) => errors.add(e));

      var handled = <Object>[];
      var handledFuture = es.handleError((Object e) => handled.add(e)).toList();

      es.add(1);
      es.addError(StateError('fail'));
      es.add(2);
      await es.close();

      expect(values, equals([1, 2]));
      expect(errors.single, isA<StateError>());
      expect(await handledFuture, equals([1, 2]));
      expect(handled.single, isA<StateError>());
    });

    test('addStream', () async {
      var es = EventStream<int>();
      var futureList = es.toList();
      await es.addStream(Stream.fromIterable([4, 5]));
      await es.close();
      expect(await futureList, equals([4, 5]));
    });

    test('pipe', () async {
      var es = EventStream<int>();
      var controller = StreamController<int>();
      var futureList = controller.stream.toList();
      var pipeDone = es.pipe(controller);
      es.add(7);
      await es.close();
      await pipeDone;
      expect(await futureList, equals([7]));
    });

    test('eventValidator', () async {
      var es = EventStream<int>();
      es.eventValidator = (eventStream, e) => e.isEven;

      var values = <int>[];
      es.listen(values.add);

      var values2 = <int>[];
      es.listen(values2.add, eventValidator: (eventStream, e) => e > 2);

      for (var i = 1; i <= 4; ++i) {
        es.add(i);
      }
      await es.close();

      expect(values, equals([2, 4]));
      expect(values2, equals([3, 4]));
    });

    test('singleton subscriptions', () async {
      var es = EventStream<int>();

      var a = <int>[];
      var b = <int>[];

      var sub1 = es.listen(a.add, singletonIdentifier: 'A');
      var sub2 = es.listen(a.add, singletonIdentifier: 'A');
      expect(identical(sub1, sub2), isTrue);
      expect(es.getSingletonSubscription('A'), same(sub1));
      expect(es.getSingletonSubscription('B'), isNull);

      es.listen(b.add, singletonIdentifier: 'B');

      es.add(1);
      await Future.delayed(Duration.zero);
      expect(a, equals([1]));
      expect(b, equals([1]));

      // Overwrite the singleton subscription `A`:
      var a2 = <int>[];
      var sub3 = es.listen(
        a2.add,
        singletonIdentifier: 'A',
        overwriteSingletonSubscription: true,
      );
      expect(identical(sub3, sub1), isFalse);

      es.add(2);
      await Future.delayed(Duration.zero);
      expect(a, equals([1]));
      expect(a2, equals([2]));

      expect(es.cancelSingletonSubscription('B'), isTrue);
      expect(es.cancelSingletonSubscription('B'), isFalse);
      expect(es.getSingletonSubscription('B'), isNull);

      es.add(3);
      await Future.delayed(Duration.zero);
      expect(b, equals([1, 2]));
      expect(a2, equals([2, 3]));

      es.cancelAllSingletonSubscriptions();
      expect(es.getSingletonSubscription('A'), isNull);

      es.add(4);
      await Future.delayed(Duration.zero);
      expect(a2, equals([2, 3]));

      await es.close();
    });

    test('listenOneShot', () async {
      var es = EventStream<dynamic>();

      var values = [];
      var wrapper = es.listenOneShot(values.add)!;
      expect(wrapper.isListening, isTrue);
      expect(wrapper.oneShot, isTrue);

      es.add(1);
      es.add(2);
      await Future.delayed(Duration.zero);

      expect(values, equals([1]));
      expect(wrapper.eventCount, equals(1));
      expect(wrapper.isListening, isFalse);

      await es.close();
    });

    test('listenOneShot with a typed EventStream', () async {
      var es = EventStream<int>();

      var values = <int>[];
      var wrapper = es.listenOneShot(values.add)!;

      es.add(1);
      es.add(2);
      await Future.delayed(Duration.zero);

      expect(values, equals([1]));
      expect(wrapper.isListening, isFalse);

      await es.close();
    });

    test('listenAsFuture', () async {
      var es = EventStream<int>();
      var future = es.listenAsFuture();
      es.add(10);
      es.add(20);
      expect(await future, equals(10));
      await es.close();
    });
  });

  group('EventStreamDelegator', () {
    test('delegates to an existing EventStream', () async {
      var es = EventStream<int>();
      var delegator = EventStreamDelegator(es);

      expect(delegator.eventStream, same(es));

      var values = <int>[];
      delegator.listen(values.add);
      expect(delegator.isUsed, isTrue);
      expect(delegator.isBroadcast, isTrue);

      delegator.add(1);
      delegator.add(2);
      await Future.delayed(Duration.zero);
      expect(values, equals([1, 2]));

      expect(delegator.isClosed, isFalse);
      expect(delegator.isPaused, isFalse);
      await delegator.close();
      expect(delegator.isClosed, isTrue);
    });

    test('buffers until the provider returns an EventStream', () async {
      EventStream<int>? target;

      var delegator = EventStreamDelegator<int>.provider(() => target);
      expect(delegator.eventStream, isNull);

      var values = <int>[];
      var errors = <Object>[];
      var subscription = delegator.listen(
        values.add,
        onError: (Object e) => errors.add(e),
      );
      expect(subscription, isNotNull);

      // Not delivered yet: buffered.
      delegator.add(1);
      delegator.addError('err');

      target = EventStream<int>();
      expect(delegator.eventStream, same(target));

      await Future.delayed(Duration.zero);
      expect(values, equals([1]));
      expect(errors, equals(['err']));

      delegator.add(2);
      await Future.delayed(Duration.zero);
      expect(values, equals([1, 2]));

      await target.close();
    });

    test(
      'eventStream setter flushes and clearUnflushed drops buffer',
      () async {
        var delegator = EventStreamDelegator<int>.provider(() => null);

        var values = <int>[];
        delegator.listen(values.add);
        delegator.add(1);
        delegator.clearUnflushed();

        var values2 = <int>[];
        delegator.listen(values2.add);
        delegator.add(2);

        var es = EventStream<int>();
        delegator.eventStream = es;
        expect(delegator.eventStream, same(es));

        await Future.delayed(Duration.zero);
        expect(values, isEmpty);
        expect(values2, equals([2]));

        var futureList = delegator.toList();
        var futureFirst = delegator.first;
        delegator.add(3);
        delegator.add(4);
        await delegator.close();

        expect(await futureList, equals([3, 4]));
        expect(await futureFirst, equals(3));
      },
    );

    test('eventValidator delegates', () {
      var es = EventStream<int>();
      var delegator = EventStreamDelegator(es);
      expect(delegator.eventValidator, isNull);
      bool validator(EventStream<int> s, int e) => true;
      delegator.eventValidator = validator;
      expect(es.eventValidator, same(validator));
    });
  });

  group('ListenerWrapper', () {
    test('wraps a plain Stream', () async {
      var controller = StreamController<int>();

      var values = <int>[];
      var errors = <Object>[];
      var done = false;

      var wrapper = ListenerWrapper<int>(
        controller.stream,
        values.add,
        onError: (Object e, StackTrace s) => errors.add(e),
        onDone: () => done = true,
      );

      expect(wrapper.isListening, isFalse);
      expect(wrapper.listen(), isTrue);
      expect(wrapper.isListening, isTrue);
      expect(wrapper.subscription, isNotNull);
      // Already listening:
      expect(wrapper.listen(), isFalse);

      controller.add(1);
      controller.addError('e1');
      controller.add(2);
      await controller.close();

      expect(values, equals([1, 2]));
      expect(errors, equals(['e1']));
      expect(wrapper.errorCount, equals(1));
      // 2 data events + 1 error + done:
      expect(wrapper.eventCount, equals(4));
      expect(done, isTrue);

      wrapper.cancel();
      expect(wrapper.isListening, isFalse);
    });

    test('onError with 1 or 0 parameters', () async {
      var errors1 = <Object>[];
      var controller1 = StreamController<int>();
      ListenerWrapper<int>(
        controller1.stream,
        (_) {},
        onError: (Object e) => errors1.add(e),
      ).listen();
      controller1.addError('x');
      await controller1.close();
      expect(errors1, equals(['x']));

      var errors0 = 0;
      var controller0 = StreamController<int>();
      ListenerWrapper<int>(
        controller0.stream,
        (_) {},
        onError: () => errors0++,
      ).listen();
      controller0.addError('y');
      await controller0.close();
      expect(errors0, equals(1));
    });

    test('oneShot cancels after the first event', () async {
      var controller = StreamController<int>.broadcast();
      var values = <int>[];
      var wrapper = ListenerWrapper<int>(
        controller.stream,
        values.add,
        oneShot: true,
      );
      wrapper.listen();

      controller.add(1);
      controller.add(2);
      await Future.delayed(Duration.zero);

      expect(values, equals([1]));
      expect(wrapper.isListening, isFalse);
      await controller.close();
    });
  });

  group('AsyncValue', () {
    test('loads a value', () async {
      var av = AsyncValue<int>(Future.value(10));
      expect(av.isLoaded, isFalse);
      expect(() => av.get(), throwsStateError);
      expect(av.getIfLoaded(), isNull);

      var loaded = <int?>[];
      av.onLoad.listen(loaded.add);

      expect(await av.future, equals(10));
      expect(av.isLoaded, isTrue);
      expect(av.isLoadedOK, isTrue);
      expect(av.isLoadedWithError, isFalse);
      expect(av.hasError, isFalse);
      expect(av.error, isNull);
      expect(av.get(), equals(10));
      expect(av.getIfLoaded(), equals(10));
      expect(await av.getAsync(), equals(10));

      await Future.delayed(Duration.zero);
      expect(loaded, equals([10]));

      av.dispose();
      expect(av.getIfLoaded(), isNull);
    });

    test('dispose with nullable type', () async {
      var av = AsyncValue<int?>(Future.value(5));
      expect(await av.future, equals(5));
      av.dispose();
      expect(av.getIfLoaded(), isNull);
      expect(av.error, isNull);
      expect(await av.future, isNull);
    });

    test('getAsync waits for the value', () async {
      var completer = Completer<String>();
      var av = AsyncValue<String>(completer.future);
      var future = av.getAsync();
      completer.complete('ok');
      expect(await future, equals('ok'));
    });

    test('nullable value completing with null', () async {
      var av = AsyncValue<int?>(Future.value(null));
      expect(await av.future, isNull);
      expect(av.isLoadedOK, isTrue);
    });

    test(
      'error with non-nullable type propagates the original error',
      () async {
        var av = AsyncValue<int>(Future.error(StateError('boom')));
        await expectLater(av.future, throwsStateError);
        expect(av.isLoaded, isTrue);
        expect(av.hasError, isTrue);
        expect(av.isLoadedWithError, isTrue);
        expect(av.isLoadedOK, isFalse);
        expect(av.error, isA<StateError>());
        expect(av.get(), isNull);
      },
    );

    test('error with nullable type completes with null', () async {
      var av = AsyncValue<int?>(Future.error('boom'));
      expect(await av.future, isNull);
      expect(av.error, equals('boom'));
      expect(av.isLoadedWithError, isTrue);
    });

    test('AsyncValue.from', () async {
      expect(await AsyncValue<int>.from(Future.value(1)).future, equals(1));
      expect(
        await AsyncValue<int>.from(() => Future.value(2)).future,
        equals(2),
      );
      expect(await AsyncValue<int>.from(() => 3).future, equals(3));
      expect(
        await AsyncValue<dynamic>.from(() async => 'x').future,
        equals('x'),
      );
      expect(() => AsyncValue<int>.from(123), throwsArgumentError);
    });
  });

  group('InteractionCompleter', () {
    test('triggerNow and parameters', () async {
      var calls = 0;
      var ic = InteractionCompleter(
        'test',
        triggerDelay: Duration(milliseconds: 50),
        functionToTrigger: () => calls++,
      );

      expect(ic.triggerDelayMs, equals(50));
      expect(ic.hasTriggerDelayLimit, isFalse);
      expect(ic.lastInteractionTime, isNull);
      expect(ic.interactionElapsedTime, isNull);
      expect(ic.fullInteractionElapsedTime, isNull);

      var completed = <InteractionCompleter>[];
      ic.onComplete.listen(completed.add);

      ic.interact(noTriggering: true, interactionParameters: [1]);
      expect(ic.isTriggerScheduled, isFalse);
      expect(ic.hasInteractionNotTriggered, isTrue);
      expect(ic.lastInteractionParameters, equals([1]));
      expect(ic.lastInteractionTime, isNotNull);
      expect(ic.interactionElapsedTime, greaterThanOrEqualTo(0));
      expect(ic.fullInteractionElapsedTime, greaterThanOrEqualTo(0));

      ic.triggerIfHasInteraction(interactionParameters: [2]);
      expect(calls, equals(1));
      expect(ic.hasInteractionNotTriggered, isFalse);
      expect(ic.lastInteractionParameters, equals([2]));

      // No pending interaction: nothing happens.
      ic.triggerIfHasInteraction();
      expect(calls, equals(1));

      ic.disposeLastInteractionParameters();
      expect(ic.lastInteractionParameters, isNull);

      await Future.delayed(Duration.zero);
      expect(completed, equals([ic]));
    });

    test('ignoreConsecutiveEqualsParameters', () {
      var ic = InteractionCompleter('test');
      ic.interact(noTriggering: true, interactionParameters: [1, 2]);
      var time = ic.lastInteractionTime;
      ic.interact(
        noTriggering: true,
        interactionParameters: [1, 2],
        ignoreConsecutiveEqualsParameters: true,
      );
      expect(ic.lastInteractionTime, equals(time));
      expect(ic.lastInteractionParameters, equals([1, 2]));
      ic.dispose();
      expect(ic.lastInteractionParameters, isNull);
    });

    test('cancel prevents triggering', () async {
      var calls = 0;
      var ic = InteractionCompleter(
        'test',
        triggerDelay: Duration(milliseconds: 20),
        functionToTrigger: () => calls++,
      );
      ic.interact();
      expect(ic.isTriggerScheduled, isTrue);
      ic.cancel();
      expect(ic.isTriggerScheduled, isFalse);
      await Future.delayed(Duration(milliseconds: 100));
      expect(calls, equals(0));
    });

    test('a throwing functionToTrigger still completes', () async {
      var ic = InteractionCompleter(
        'test',
        functionToTrigger: () => throw StateError('x'),
      );
      var completed = ic.onComplete.first;
      ic.triggerNow();
      expect(await completed, same(ic));
    });

    test('InteractionCompleterDummy does nothing', () {
      var ic = InteractionCompleterDummy();
      ic.interact(interactionParameters: [1]);
      ic.triggerIfHasInteraction();
      ic.triggerNow();
      expect(ic.hasInteractionNotTriggered, isFalse);
      expect(ic.isTriggerScheduled, isFalse);
      expect(ic.lastInteractionParameters, isNull);
    });

    test('listenStreamWithInteractionCompleter', () async {
      var controller = StreamController<int>();
      var received = <int?>[];
      var ic = listenStreamWithInteractionCompleter<int>(
        controller.stream,
        Duration(milliseconds: 20),
        received.add,
      );

      controller.add(1);
      controller.add(2);
      await Future.delayed(Duration.zero);
      expect(ic.hasInteractionNotTriggered, isTrue);

      ic.triggerNow();
      expect(received, equals([2]));
      await controller.close();
    });
  });

  group('UniqueCaller', () {
    test('sync call and duplicated call', () async {
      var duplicated = 0;

      var completer = Completer<int>();
      var caller = UniqueCaller<int>(
        () => completer.future,
        identifier: 'unique-test-id',
        onDuplicatedCall: (_) => duplicated++,
      );

      expect(caller.identifier, isNotNull);

      var f1 = caller.callAsync();
      var f2 = caller.callAsync();
      expect(await f2, isNull);
      expect(duplicated, equals(1));

      expect(UniqueCaller.calling, isNotEmpty);
      var callFuture = UniqueCaller.getCallFuture<int>('unique-test-id');

      completer.complete(42);
      expect(await f1, equals(42));
      expect(await callFuture, equals(42));
      expect(UniqueCaller.calling, isEmpty);

      var syncCaller = UniqueCaller<String>(
        () => 'sync',
        identifier: 'sync-id',
      );
      expect(syncCaller.call(), equals('sync'));
      expect(await syncCaller.callAsync(), equals('sync'));
    });

    test('call rethrows and releases the identifier', () {
      var caller = UniqueCaller<int>(
        () => throw StateError('x'),
        identifier: 'throwing-id',
      );
      expect(() => caller.call(), throwsStateError);
      expect(() => caller.call(), throwsStateError);
    });

    test('stackTraceIdentifier', () {
      expect(UniqueCaller.stackTraceIdentifier(), isNotEmpty);
    });
  });
}
