import 'package:swiss_knife/src/flat_hash_map.dart';
import 'package:test/test.dart';

class Key {
  final int id;
  final int hash;

  Key(this.id, this.hash);

  @override
  int get hashCode => hash;

  @override
  bool operator ==(Object other) => other is Key && other.id == id;
}

void main() {
  group('FlatHashMap basic behavior', () {
    test('initial state', () {
      final map = FlatHashMap<int, String>();
      expect(map.isEmpty, isTrue);
      expect(map.length, 0);
    });

    test('put and get', () {
      final map = FlatHashMap<int, String>();
      map[1] = 'a';
      map[2] = 'b';

      expect(map.length, 2);
      expect(map[1], 'a');
      expect(map[2], 'b');
      expect(map[3], isNull);
    });

    test('overwrite value returns previous', () {
      final map = FlatHashMap<int, String>();
      expect(map.put(1, 'a'), isNull);
      expect(map.put(1, 'b'), 'a');
      expect(map[1], 'b');
      expect(map.length, 1);
    });

    test('containsKey and containsValue', () {
      final map = FlatHashMap<int, String>();
      map[1] = 'x';

      expect(map.containsKey(1), isTrue);
      expect(map.containsKey(2), isFalse);
      expect(map.containsValue('x'), isTrue);
      expect(map.containsValue('y'), isFalse);
    });

    test('remove existing and missing key', () {
      final map = FlatHashMap<int, String>();
      map[1] = 'a';
      map[2] = 'b';

      expect(map.remove(1), 'a');
      expect(map.remove(1), isNull);
      expect(map.containsKey(1), isFalse);
      expect(map.length, 1);
    });

    test('FlatHashMap preserves key insertion order', () {
      final map = FlatHashMap<int, String>();

      map[3] = 'c';
      map[1] = 'a';
      map[4] = 'd';
      map[2] = 'b';

      final keys = map.keys.toList();
      final values = map.values.toList();

      expect(keys, equals([3, 1, 4, 2]));
      expect(values, equals(['c', 'a', 'd', 'b']));
    });

    test('FlatHashMap preserves insertion order with many entries', () {
      final map = FlatHashMap<int, int>();

      const total = 10_000;

      // Insert in non-sorted, deterministic order
      for (var i = 0; i < total; i++) {
        final key = (i * 37) % total; // permutation
        map[key] = i;
      }

      expect(map.length, total);

      final keys = map.keys.toList();
      final values = map.values.toList();

      // Rebuild expected insertion order
      final expectedKeys = <int>[];
      final expectedValues = <int>[];

      for (var i = 0; i < total; i++) {
        final key = (i * 37) % total;
        expectedKeys.add(key);
        expectedValues.add(i);
      }

      expect(keys, equals(expectedKeys));
      expect(values, equals(expectedValues));
    });
  });

  group('Collision handling', () {
    test('keys with same hash but different equality', () {
      final map = FlatHashMap<Key, String>();
      final k1 = Key(1, 42);
      final k2 = Key(2, 42);

      map[k1] = 'a';
      map[k2] = 'b';

      expect(map.length, 2);
      expect(map[k1], 'a');
      expect(map[k2], 'b');
    });

    test('remove from collision chain', () {
      final map = FlatHashMap<Key, int>();
      final k1 = Key(1, 7);
      final k2 = Key(2, 7);
      final k3 = Key(3, 7);

      map[k1] = 1;
      map[k2] = 2;
      map[k3] = 3;

      expect(map.remove(k2), 2);
      expect(map[k1], 1);
      expect(map[k3], 3);
      expect(map.length, 2);
    });
  });

  group('Reuse removed slots', () {
    test('removed entries are reused', () {
      final map = FlatHashMap<int, int>();

      map[1] = 10;
      map[2] = 20;
      map.remove(1);
      map[3] = 30;

      expect(map.containsKey(1), isFalse);
      expect(map[2], 20);
      expect(map[3], 30);
      expect(map.length, 2);
    });
  });

  group('Rehashing', () {
    test('rehash preserves all entries', () {
      final map = FlatHashMap<int, int>();

      for (var i = 0; i < 100; i++) {
        map[i] = i * 10;
      }

      expect(map.length, 100);
      for (var i = 0; i < 100; i++) {
        expect(map[i], i * 10);
      }
    });
  });

  group('Iteration and clear', () {
    test('keys, values, entries', () {
      final map = FlatHashMap<int, String>();
      map[1] = 'a';
      map[2] = 'b';

      expect(map.keys.toSet(), {1, 2});
      expect(map.values.toSet(), {'a', 'b'});
      expect(
        map.entries.map((e) => '${e.key}:${e.value}').toSet(),
        {'1:a', '2:b'},
      );
    });

    test('clear resets map', () {
      final map = FlatHashMap<int, String>();
      map[1] = 'x';
      map.clear();

      expect(map.isEmpty, isTrue);
      expect(map.length, 0);
      expect(map.containsKey(1), isFalse);
    });
  });

  group('Edge cases and invariants', () {
    test('null key behavior', () {
      final map = FlatHashMap<int, String>();
      expect(map[null], isNull);
      expect(map.remove(null), isNull);
      expect(map.containsKey(null), isFalse);
    });

    test('containsValue ignores removed entries', () {
      final map = FlatHashMap<int, String>();
      map[1] = 'a';
      map[2] = 'b';
      map.remove(1);

      expect(map.containsValue('a'), isFalse);
      expect(map.containsValue('b'), isTrue);
    });
  });

  group('Chain order and head removal', () {
    test('remove head of collision chain', () {
      final map = FlatHashMap<Key, int>();
      final k1 = Key(1, 5);
      final k2 = Key(2, 5);

      map[k1] = 10;
      map[k2] = 20;

      // k2 is at head due to insertion order
      expect(map.remove(k2), 20);
      expect(map[k1], 10);
      expect(map.length, 1);
    });

    test('remove tail of collision chain', () {
      final map = FlatHashMap<Key, int>();
      final k1 = Key(1, 9);
      final k2 = Key(2, 9);
      final k3 = Key(3, 9);

      map[k1] = 1;
      map[k2] = 2;
      map[k3] = 3;

      expect(map.remove(k1), 1);
      expect(map[k2], 2);
      expect(map[k3], 3);
      expect(map.length, 2);
    });
  });

  group('Rehash boundaries', () {
    test('no rehash below threshold', () {
      final map = FlatHashMap<int, int>();
      for (var i = 0; i < 79; i++) {
        map[i] = i;
      }

      expect(map.length, 79);
      for (var i = 0; i < 79; i++) {
        expect(map[i], i);
      }
    });

    test('multiple rehash cycles preserve correctness', () {
      final map = FlatHashMap<int, int>();

      for (var round = 0; round < 3; round++) {
        for (var i = 0; i < 120; i++) {
          map[i + round * 1000] = i;
        }
      }

      expect(map.length, 360);
      expect(map[0], 0);
      expect(map[1000], 0);
      expect(map[2000], 0);
    });
  });

  group('Iteration consistency after mutations', () {
    test('iteration after removals and inserts', () {
      final map = FlatHashMap<int, int>();
      map[1] = 1;
      map[2] = 2;
      map[3] = 3;

      map.remove(2);
      map[4] = 4;

      expect(map.keys.toSet(), {1, 3, 4});
      expect(map.values.toSet(), {1, 3, 4});
    });

    test('entries reflect latest values only', () {
      final map = FlatHashMap<int, int>();
      map[1] = 10;
      map[1] = 20;

      final entries = map.entries.toList();
      expect(entries.length, 1);
      expect(entries.single.key, 1);
      expect(entries.single.value, 20);
    });
  });

  group('Clear and reuse after clear', () {
    test('put works correctly after clear', () {
      final map = FlatHashMap<int, int>();
      map[1] = 1;
      map.clear();
      map[2] = 2;

      expect(map.length, 1);
      expect(map[2], 2);
      expect(map.containsKey(1), isFalse);
    });
  });

  group('Rehash behavior (forced and structural)', () {
    test('rehash changes bucket distribution but keeps lookup correct', () {
      final map = FlatHashMap<int, int>();

      // Force rehash: threshold is groups * 10 = 80
      for (var i = 0; i < 81; i++) {
        map[i] = i * 2;
      }

      expect(map.length, 81);

      for (var i = 0; i < 81; i++) {
        expect(map[i], i * 2);
      }
    });

    test('rehash with heavy collisions', () {
      final map = FlatHashMap<Key, int>();

      // All keys collide initially
      for (var i = 0; i < 90; i++) {
        map[Key(i, 1)] = i;
      }

      expect(map.length, 90);

      for (var i = 0; i < 90; i++) {
        expect(map[Key(i, 1)], i);
      }
    });

    test('rehash preserves chain integrity after removals', () {
      final map = FlatHashMap<Key, int>();

      for (var i = 0; i < 85; i++) {
        map[Key(i, i % 3)] = i;
      }

      // Remove some entries before and after rehash
      for (var i = 0; i < 85; i += 5) {
        expect(map.remove(Key(i, i % 3)), i);
      }

      for (var i = 0; i < 85; i++) {
        final v = map[Key(i, i % 3)];
        if (i % 5 == 0) {
          expect(v, isNull);
        } else {
          expect(v, i);
        }
      }
    });

    test('rehash followed by further inserts', () {
      final map = FlatHashMap<int, int>();

      for (var i = 0; i < 100; i++) {
        map[i] = i;
      }

      for (var i = 100; i < 150; i++) {
        map[i] = i * 3;
      }

      expect(map.length, 150);
      expect(map[0], 0);
      expect(map[149], 447);
    });
  });

  group('FlatHashMap capacity bits', () {
    test('grows to 16-bit capacity (Uint16List)', () {
      final map = FlatHashMap<int, int>();

      expect(map.capacityBits, 8);
      expect(map.length, 0);

      for (var i = 0; i < 100; i++) {
        map[i] = i;
      }

      expect(map.capacityBits, 8);
      expect(map.length, 100);

      // Grow beyond 0xFF (255) entries
      for (var i = 100; i < 300; i++) {
        map[i] = i;
      }

      expect(map.capacityBits, 16);
      expect(map.length, 300);

      // Sanity check correctness
      for (var i = 0; i < 300; i++) {
        expect(map[i], i);
      }
    });

    test('grows to 32-bit capacity (Uint32List)', () {
      final map = FlatHashMap<int, int>();

      expect(map.capacityBits, 8);
      expect(map.length, 0);

      // Grow beyond 0xFF (255) entries
      for (var i = 0; i < 1000; i++) {
        map[i] = i;
      }

      expect(map.capacityBits, 16);
      expect(map.length, 1000);

      // Grow beyond 0xFFFF (65535) entries
      for (var i = 1000; i < 70000; i++) {
        map[i] = i;
      }

      expect(map.capacityBits, 32);
      expect(map.length, 70000);

      // Spot-check correctness
      for (var i = 0; i < 1000; i += 137) {
        expect(map[i], i);
      }
    });
  });
}
