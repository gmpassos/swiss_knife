import 'package:swiss_knife/swiss_knife.dart';
import 'package:test/test.dart';

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
  });
}
