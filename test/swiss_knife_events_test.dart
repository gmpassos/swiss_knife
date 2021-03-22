import 'package:swiss_knife/swiss_knife.dart';
import 'package:test/test.dart';

Future<void> _sleep(int delayMs) async {
  if (delayMs <= 0) return;
  await Future.delayed(Duration(milliseconds: delayMs), () {});
}

void _asyncCall(List<String> calls) async {
  var callID = DateTime.now().microsecondsSinceEpoch;
  calls.add('$callID> a');
  await Future.delayed(Duration(seconds: 2));
  calls.add('$callID> b');
}

void _doUniqueCall(List<String> calls) async {
  var uniqueCaller = UniqueCaller(() => _asyncCall(calls));
  uniqueCaller.call();
}

void main() {
  group('Events', () {
    setUp(() {});

    test('EventStream', () async {
      var onEvent = EventStream<int>();

      expect(onEvent.isUsed, isFalse);

      var caughtA = <int>[];
      var caughtB = <int>[];

      onEvent.add(1);
      expect(caughtA, equals([]));

      onEvent.listen((event) => caughtA.add(event), singletonIdentifier: 'A');
      onEvent.listen((event) => caughtA.add(event), singletonIdentifier: 'A');

      onEvent.listen((event) => caughtB.add(event));
      onEvent.listen((event) => caughtB.add(event));

      var future = onEvent.listenAsFuture();

      onEvent.add(2);

      expect(onEvent.isUsed, isTrue);

      await onEvent.close();

      expect(caughtA, equals([2]));
      expect(caughtB, equals([2, 2]));

      var val = await future;

      expect(val, equals(2));
    });

    test('InteractionCompleter', () async {
      var counter = NNField<int>(0);

      var interactionCompleter = InteractionCompleter('test',
          triggerDelay: Duration(seconds: 1),
          functionToTrigger: () => counter.set(counter.value + 1));

      interactionCompleter.interact();
      expect(interactionCompleter.isTriggerScheduled, isTrue);
      expect(counter.value, equals(0));

      for (var i = 0; i < 20; ++i) {
        await _sleep(100);

        expect(counter.value, equals(0));

        interactionCompleter.interact();
        expect(interactionCompleter.isTriggerScheduled, isTrue);
        expect(counter.value, equals(0));
      }

      await _sleep(2000);
      expect(interactionCompleter.isTriggerScheduled, isFalse);
      expect(counter.value, equals(1));
    });

    test('NON UniqueCaller', () async {
      var calls = <String>[];

      expect(UniqueCaller.calling, isEmpty);

      _asyncCall(calls);
      _asyncCall(calls);

      expect(UniqueCaller.calling, isEmpty);

      print('NON UniqueCaller> $calls');

      expect(calls.where((e) => e.contains(' a')).length, equals(2));
    });

    test('UniqueCaller', () async {
      var calls = <String>[];

      expect(UniqueCaller.calling, isEmpty);

      _doUniqueCall(calls);
      _doUniqueCall(calls);

      expect(UniqueCaller.calling.length, equals(1));

      await Future.wait(UniqueCaller.calling);

      expect(UniqueCaller.calling.length, equals(0));

      print('UniqueCaller> $calls');

      expect(calls.where((e) => e.contains(' a')).length, equals(1));
    });
  });
}
