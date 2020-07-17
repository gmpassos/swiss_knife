import 'package:swiss_knife/swiss_knife.dart';
import 'package:test/test.dart';

void main() {
  group('Loader', () {
    setUp(() {});

    test('LoadController ok', () async {
      var loader = LoadController('Test1');

      expect(loader.isLoaded, isFalse);
      expect(loader.isNotLoaded, isTrue);
      expect(loader.loadSuccessful, isNull);

      var events = <String>[];

      var ok = await loader.load(() async {
        events.add('loaded');
        return true;
      });

      expect(ok, isTrue);

      var ok2 = await loader.load(() async {
        events.add('duplicated');
        return true;
      });

      expect(ok2, isTrue);

      expect(loader.isLoaded, isTrue);
      expect(loader.isNotLoaded, isFalse);
      expect(loader.loadSuccessful, isTrue);

      expect(events, equals(['loaded']));
    });

    test('LoadController error', () async {
      var loader = LoadController('Test1');

      expect(loader.isLoaded, isFalse);
      expect(loader.isNotLoaded, isTrue);
      expect(loader.loadSuccessful, isNull);

      var events = <String>[];

      var ok = await loader.load(() async {
        events.add('error');
        return false;
      });

      expect(ok, isFalse);

      expect(loader.isLoaded, isTrue);
      expect(loader.isNotLoaded, isFalse);
      expect(loader.loadSuccessful, isFalse);

      var ok2 = await loader.load(() async {
        events.add('duplicated');
        return true;
      });

      expect(ok2, isFalse);

      expect(loader.isLoaded, isTrue);
      expect(loader.isNotLoaded, isFalse);
      expect(loader.loadSuccessful, isFalse);

      expect(events, equals(['error']));
    });
  });
}
