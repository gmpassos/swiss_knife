import 'package:swiss_knife/swiss_knife.dart';
import 'package:test/test.dart';

/// Key with a controllable hash code, to force bucket collisions.
class HKey {
  final String name;
  final int hash;

  HKey(this.name, this.hash);

  @override
  bool operator ==(Object other) => other is HKey && other.name == name;

  @override
  int get hashCode => hash;

  @override
  String toString() => 'HKey($name)';
}

void main() {
  group('FlatHashMap capacity and memory', () {
    test('initial capacity', () {
      final m = FlatHashMap<String, int>();
      expect(m.capacity, 8);
      expect(m.capacityBits, 8);
    });

    test('capacity doubles when the chain storage is full', () {
      final m = FlatHashMap<String, int>();
      // Index 0 is reserved, so 7 entries fit in the initial 8 slots:
      for (var i = 0; i < 7; i++) {
        m['k$i'] = i;
      }
      expect(m.capacity, 8);
      m['k7'] = 7;
      expect(m.capacity, 16);
      expect(m.capacityBits, 8);
      expect(m.length, 8);
    });

    test('memory estimate of an empty map', () {
      final m = FlatHashMap<String, int>();
      // keys(1) + values(1) refs, hashes 8*4, chain 8*1, groups 8*4 + 8*4,
      // 6 buffer references and 3 scalar ints:
      expect(m.memory(), 8 + 8 + 8 + 8 + 8 + 32 + 8 + 8 + 8 + 32 + 8 + 32 + 24);
      expect(m.memory(), 192);
      expect(m.memory(objectReferenceBytes: 4), 160);
    });

    test('memory estimate grows with entries', () {
      final m = FlatHashMap<String, int>();
      for (var i = 0; i < 8; i++) {
        m['k$i'] = i;
      }
      // keys/values: 9 refs each; hashes 16*4; chain 16*1:
      expect(
        m.memory(),
        8 + 9 * 8 + 8 + 9 * 8 + 8 + 16 * 4 + 8 + 16 + 8 + 32 + 8 + 32 + 24,
      );
    });

    test('memory accounts for 16-bit chain pointers', () {
      final m = FlatHashMap<int, int>();
      for (var i = 0; i < 300; i++) {
        m[i] = i;
      }
      expect(m.capacityBits, 16);
      expect(m.capacity, 512);
      final refBytes = m.memory() - m.memory(objectReferenceBytes: 0);
      // Only the references change with `objectReferenceBytes`:
      // 6 buffers + keys + values.
      expect(refBytes, 8 * (6 + 301 + 301));
      // Non-reference part: hashes 512*4, chain 512*2, groups (rehashed to
      // 32 buckets) 32*4 * 2, scalars 24:
      expect(m.memory(objectReferenceBytes: 0), 512 * 4 + 512 * 2 + 256 + 24);
    });
  });

  group('FlatHashMap collisions', () {
    test('containsKey and get walk the collision chain', () {
      final m = FlatHashMap<HKey, int>();
      final a = HKey('a', 3);
      final b = HKey('b', 3);
      final c = HKey('c', 11); // same bucket as 3 (mod 8)

      m[a] = 1;
      m[b] = 2;
      m[c] = 3;

      // `a` is at the end of its bucket chain:
      expect(m.containsKey(a), isTrue);
      expect(m.containsKey(b), isTrue);
      expect(m.containsKey(c), isTrue);
      expect(m.containsKey(HKey('a', 3)), isTrue);
      expect(m.containsKey(HKey('z', 3)), isFalse);
      expect(m.containsKey(HKey('z', 11)), isFalse);
      expect(m.containsKey(HKey('a', 4)), isFalse);
      // ignore: collection_methods_unrelated_type
      expect(m.containsKey(null), isFalse);

      expect(m[a], 1);
      expect(m[b], 2);
      expect(m[c], 3);
      expect(m[HKey('z', 3)], isNull);
    });

    test('keys with negative hash codes', () {
      final m = FlatHashMap<HKey, String>();
      final k = HKey('neg', -5);
      m[k] = 'x';

      expect(m.length, 1);
      expect(m.keys.toList(), [k]);
      expect(m.containsValue('x'), isTrue);

      // Regression: the cached hash is stored in a `Uint32List`, so a
      // negative hashCode never matched and such keys could not be found,
      // replaced or removed.
      expect(m[k], 'x');
      expect(m[HKey('neg', -5)], 'x');
      expect(m.containsKey(k), isTrue);

      // Re-putting the same key replaces the value:
      expect(m.put(k, 'y'), 'x');
      expect(m.length, 1);
      expect(m.keys.toList(), [k]);
      expect(m.values.toList(), ['y']);

      expect(m.remove(k), 'y');
      expect(m.length, 0);
      expect(m.containsKey(k), isFalse);
    });

    test('negative int keys', () {
      final m = FlatHashMap<int, int>();
      for (var i = -50; i < 50; i++) {
        m[i] = i * 2;
      }
      expect(m.length, 100);
      for (var i = -50; i < 50; i++) {
        expect(m[i], i * 2, reason: 'key $i');
      }
      m[-7] = 0;
      expect(m.length, 100);
      expect(m[-7], 0);
      expect(m.remove(-50), -100);
      expect(m.containsKey(-50), isFalse);
      expect(m.length, 99);
    });

    test('rehash keeps all entries when there are removed slots', () {
      final m = FlatHashMap<int, int>();
      for (var i = 0; i < 40; i++) {
        m[i] = i;
      }
      for (var i = 0; i < 40; i += 2) {
        m.remove(i);
      }
      expect(m.length, 20);
      for (var i = 100; i < 300; i++) {
        m[i] = i;
      }
      expect(m.length, 220);
      for (var i = 1; i < 40; i += 2) {
        expect(m[i], i, reason: 'key $i');
      }
      for (var i = 100; i < 300; i++) {
        expect(m[i], i, reason: 'key $i');
      }
      expect(m.keys.length, 220);
    });
  });

  group('FlatHashMap clear', () {
    test('clear(full: true) reallocates storage', () {
      final m = FlatHashMap<String, int>();
      for (var i = 0; i < 20; i++) {
        m['k$i'] = i;
      }
      expect(m.capacity, 32);

      m.clear(full: true);
      expect(m.isEmpty, isTrue);
      expect(m.length, 0);
      expect(m.capacity, 8);
      expect(m.memory(), FlatHashMap<String, int>().memory());
      expect(m.keys, isEmpty);
      expect(m['k1'], isNull);

      m['a'] = 1;
      m['b'] = 2;
      expect(m.length, 2);
      expect(m.keys.toList(), ['a', 'b']);
      expect(m.values.toList(), [1, 2]);
      expect(m['b'], 2);
      expect(m.remove('a'), 1);
      expect(m.keys.toList(), ['b']);
    });

    test('clear() keeps the grown storage', () {
      final m = FlatHashMap<String, int>();
      for (var i = 0; i < 20; i++) {
        m['k$i'] = i;
      }
      m.clear();
      expect(m.isEmpty, isTrue);
      expect(m.capacity, 32);

      m['a'] = 1;
      expect(m['a'], 1);
      expect(m.entries.map((e) => '${e.key}=${e.value}').toList(), ['a=1']);
    });
  });

  group('FlatHashMap containsValue', () {
    test('finds live values', () {
      final m = FlatHashMap<String, int>();
      m['a'] = 1;
      expect(m.containsValue(1), isTrue);
      expect(m.containsValue(2), isFalse);
    });

    test('null value', () {
      final m = FlatHashMap<String, int>();
      // Regression: `containsValue` scanned the raw value storage, whose
      // reserved slot 0 (and any removed slot) holds `null`, so
      // `containsValue(null)` was `true` even for an empty map.
      // ignore: collection_methods_unrelated_type
      expect(m.containsValue(null), isFalse);
      expect(m.isEmpty, isTrue);
      m['a'] = 1;
      m['b'] = 2;
      m.remove('a');
      // ignore: collection_methods_unrelated_type
      expect(m.containsValue(null), isFalse);
      expect(m.containsValue(1), isFalse);
      expect(m.containsValue(2), isTrue);
    });
  });
}
