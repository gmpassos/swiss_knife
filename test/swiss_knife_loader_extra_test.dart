import 'package:swiss_knife/swiss_knife.dart';
import 'package:test/test.dart';

void main() {
  group('LoadController (extra)', () {
    test('generated ids', () {
      var l1 = LoadController();
      var l2 = LoadController();

      var id1 = int.parse(l1.id);
      var id2 = int.parse(l2.id);

      // NOTE: current behaviour; possibly a bug: the `id` field initializer
      // and the constructor both increment the global counter, so
      // consecutive generated ids skip one value.
      expect(id2 - id1, equals(2));

      expect(LoadController('custom').id, equals('custom'));
    });

    test('LoadController.function', () async {
      var calls = 0;
      var loader = LoadController.function(() async {
        calls++;
        return true;
      }, 'fn1');

      expect(loader.id, equals('fn1'));
      expect(loader.loader, isNotNull);
      expect(
        loader.toString(),
        equals('LoadController{id: fn1, loaded: false, loadSuccessful: null}'),
      );

      var events = <LoadController>[];
      loader.onLoad.listen(events.add);

      expect(await loader.load(), isTrue);
      expect(await loader.load(), isTrue);
      expect(calls, equals(1));

      await Future<void>.delayed(Duration.zero);
      expect(events, equals([loader]));

      expect(loader.isLoaded, isTrue);
      expect(loader.loadSuccessful, isTrue);
      expect(
        loader.toString(),
        equals('LoadController{id: fn1, loaded: true, loadSuccessful: true}'),
      );

      var generated = LoadController.function(() async => false);
      expect(int.tryParse(generated.id), isNotNull);
      expect(await generated.load(), isFalse);
    });

    test('LoadController.function with null loader', () {
      expect(() => LoadController.function(null), throwsArgumentError);
    });

    test('load with a second loader function', () async {
      var loader = LoadController.function(() async => true, 'fn2');
      await expectLater(loader.load(() async => false), throwsStateError);
      expect(loader.isLoaded, isFalse);
    });

    test('load without any loader function', () async {
      var loader = LoadController('none');
      await expectLater(loader.load(), throwsArgumentError);
      expect(loader.isLoaded, isFalse);
      expect(loader.loadSuccessful, isNull);
    });
  });
}
