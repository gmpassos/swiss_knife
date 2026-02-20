import 'package:swiss_knife/swiss_knife.dart';
import 'package:test/test.dart';

void main() {
  group('DualMap basic operations', () {
    test('insert and read forward', () {
      final m = DualMap<int, String>();

      m[1] = 'a';
      m[2] = 'b';

      expect(m[1], 'a');
      expect(m[2], 'b');
      expect(m.length, 2);
    });

    test('reverse lookup', () {
      final m = DualMap<int, String>();

      m[1] = 'a';
      m[2] = 'b';

      expect(m.getKeyFromValue('a'), 1);
      expect(m.getKeyFromValue('b'), 2);
      expect(m.getKeyFromValue('x'), null);
    });

    test('overwrite existing key replaces reverse mapping', () {
      final m = DualMap<int, String>();

      m[1] = 'a';
      m[1] = 'b';

      expect(m[1], 'b');
      expect(m.getKeyFromValue('a'), null);
      expect(m.getKeyFromValue('b'), 1);
    });

    test('remove deletes both directions', () {
      final m = DualMap<int, String>();

      m[1] = 'a';

      expect(m.remove(1), 'a');
      expect(m[1], null);
      expect(m.getKeyFromValue('a'), null);
      expect(m.isEmpty, true);
    });

    test('clear removes everything', () {
      final m = DualMap<int, String>();

      m[1] = 'a';
      m[2] = 'b';

      m.clear();

      expect(m.isEmpty, true);
      expect(m.getKeyFromValue('a'), null);
      expect(m.getKeyFromValue('b'), null);
    });
  });

  group('DualMap Map API behavior', () {
    test('keys and values iterable', () {
      final m = DualMap<int, String>();

      m[1] = 'a';
      m[2] = 'b';

      expect(m.keys.toSet(), {1, 2});
      expect(m.values.toSet(), {'a', 'b'});
    });

    test('entries iterable', () {
      final m = DualMap<int, String>();

      m[1] = 'a';
      m[2] = 'b';

      final map = Map.fromEntries(m.entries);
      expect(map, {1: 'a', 2: 'b'});
    });
  });

  group('putIfAbsent', () {
    test('inserts when absent', () {
      final m = DualMap<int, String>();

      final v = m.putIfAbsent(1, () => 'a');

      expect(v, 'a');
      expect(m[1], 'a');
      expect(m.getKeyFromValue('a'), 1);
    });

    test('does not overwrite existing key', () {
      final m = DualMap<int, String>();

      m[1] = 'a';
      final v = m.putIfAbsent(1, () => 'b');

      expect(v, 'a');
      expect(m[1], 'a');
      expect(m.getKeyFromValue('a'), 1);
      expect(m.getKeyFromValue('b'), null);
    });
  });

  group('putValueIfAbsent', () {
    test('returns true when inserted', () {
      final m = DualMap<int, String>();

      final inserted = m.putValueIfAbsent(1, 'a');

      expect(inserted, true);
      expect(m[1], 'a');
      expect(m.getKeyFromValue('a'), 1);
    });

    test('returns false when key already exists', () {
      final m = DualMap<int, String>();

      m[1] = 'a';
      final inserted = m.putValueIfAbsent(1, 'b');

      expect(inserted, false);
      expect(m[1], 'a');
      expect(m.getKeyFromValue('a'), 1);
      expect(m.getKeyFromValue('b'), null);
    });
  });

  group('edge consistency cases', () {
    test('reusing same value overwrites reverse mapping (documented behavior)',
        () {
      final m = DualMap<int, String>();

      m[1] = 'a';
      m[2] = 'a';

      expect(m[1], 'a');
      expect(m[2], 'a');

      // Only last survives in reverse map
      expect(m.getKeyFromValue('a'), 2);
    });

    test('remove after overwrite keeps correct reverse', () {
      final m = DualMap<int, String>();

      m[1] = 'a';
      m[2] = 'a';

      m.remove(2);

      expect(m.getKeyFromValue('a'), null);
      expect(m[1], 'a'); // forward still there
    });
  });
}
