import 'package:swiss_knife/swiss_knife.dart';
import 'package:test/test.dart';

// Non-primitive classes to use as weak keys/values.
class KeyObj {
  final int id;

  KeyObj(this.id);

  @override
  bool operator ==(Object other) => other is KeyObj && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class ValueObj {
  final String label;

  ValueObj(this.label);

  @override
  bool operator ==(Object other) => other is ValueObj && other.label == label;

  @override
  int get hashCode => label.hashCode;
}

void main() {
  group('WeakKeyMap', () {
    test('put and get', () {
      final map = WeakKeyMap<KeyObj, ValueObj>();

      final k = KeyObj(1);
      final v = ValueObj('a');

      map[k] = v;

      expect(map[k], same(v));
      expect(map.length, 1);
    });

    test('containsKey and containsValue', () {
      final map = WeakKeyMap<KeyObj, ValueObj>();

      final k = KeyObj(1);
      final v = ValueObj('a');

      map[k] = v;

      expect(map.containsKey(k), isTrue);
      expect(map.containsValue(v), isTrue);
    });

    test('remove returns value and deletes entry', () {
      final map = WeakKeyMap<KeyObj, ValueObj>();

      final k = KeyObj(1);
      final v = ValueObj('a');

      map[k] = v;

      final removed = map.remove(k);

      expect(removed, same(v));
      expect(map.containsKey(k), isFalse);
      expect(map.length, 0);
    });

    test('iterate visits all entries', () {
      final map = WeakKeyMap<KeyObj, ValueObj>();

      final k1 = KeyObj(1);
      final k2 = KeyObj(2);

      final v1 = ValueObj('a');
      final v2 = ValueObj('b');

      map[k1] = v1;
      map[k2] = v2;

      final seen = <int, String>{};

      map.iterate((k, v) {
        seen[k.id] = v.label;
      });

      expect(seen, {
        1: 'a',
        2: 'b',
      });
    });

    test('autoPurge threshold logic', () {
      final map = WeakKeyMap<KeyObj, ValueObj>(
        autoPurge: true,
        autoPurgeThreshold: 2,
      );

      final k1 = KeyObj(1);
      final k2 = KeyObj(2);

      map[k1] = ValueObj('a');
      map[k2] = ValueObj('b');

      expect(map.isAutoPurgeRequired(), isTrue);
    });

    test('keys, values and entries reflect current state', () {
      final map = WeakKeyMap<KeyObj, ValueObj>();

      final k1 = KeyObj(1);
      final k2 = KeyObj(2);
      final v1 = ValueObj('a');
      final v2 = ValueObj('b');

      map[k1] = v1;
      map[k2] = v2;

      expect(map.keys.toSet(), equals({k1, k2}));
      expect(map.values.toSet(), equals({v1, v2}));
      expect(
        map.entries.map((e) => '${e.key.id}:${e.value.label}').toSet(),
        equals({'1:a', '2:b'}),
      );
    });

    test('entriesSwapped returns value->key pairs', () {
      final map = WeakKeyMap<KeyObj, ValueObj>();

      final k = KeyObj(1);
      final v = ValueObj('a');

      map[k] = v;

      final swapped = map.entriesSwapped.single;
      expect(swapped.key, same(v));
      expect(swapped.value, same(k));
    });

    test('removeWhere removes matching entries', () {
      final map = WeakKeyMap<KeyObj, ValueObj>();

      final k1 = KeyObj(1);
      final k2 = KeyObj(2);

      map[k1] = ValueObj('keep');
      map[k2] = ValueObj('drop');

      map.removeWhere((k, v) => v.label == 'drop');

      expect(map.containsKey(k1), isTrue);
      expect(map.containsKey(k2), isFalse);
      expect(map.length, 1);
    });

    test('containsKey and get are null/type safe', () {
      final map = WeakKeyMap<KeyObj, ValueObj>();

      map[KeyObj(1)] = ValueObj('a');

      expect(map.containsKey(null), isFalse);
      expect(map[null], isNull);
      // ignore: collection_methods_unrelated_type
      expect(map['wrong-type'], isNull);
    });

    test('clear resets length and state', () {
      final map = WeakKeyMap<KeyObj, ValueObj>();

      map[KeyObj(1)] = ValueObj('a');
      map.clear();

      expect(map.length, 0);
      expect(map.keys, isEmpty);
      expect(map.values, isEmpty);
    });
  });

  group('DualWeakMap', () {
    test('put and get by key', () {
      final map = DualWeakMap<KeyObj, ValueObj>();

      final k = KeyObj(1);
      final v = ValueObj('a');

      map[k] = v;

      expect(map[k], same(v));
      expect(map.length, 1);
    });

    test('swapped map get by value', () {
      final map = DualWeakMap<KeyObj, ValueObj>();
      final swapped = map.swapped;

      final k = KeyObj(1);
      final v = ValueObj('a');

      map[k] = v;

      expect(swapped[v], same(k));
    });

    test('swapped assignment overwrites correctly', () {
      final map = DualWeakMap<KeyObj, ValueObj>();
      final swapped = map.swapped;

      final k1 = KeyObj(1);
      final k2 = KeyObj(2);
      final v = ValueObj('a');

      map[k1] = v;
      swapped[v] = k2;

      expect(map.containsKey(k1), isFalse);
      expect(map[k2], same(v));
      expect(swapped[v], same(k2));
    });

    test('remove via swapped map', () {
      final map = DualWeakMap<KeyObj, ValueObj>();
      final swapped = map.swapped;

      final k = KeyObj(1);
      final v = ValueObj('a');

      map[k] = v;

      final removedKey = swapped.remove(v);

      expect(removedKey, same(k));
      expect(map.isEmpty, isTrue);
    });

    test('clear clears both directions', () {
      final map = DualWeakMap<KeyObj, ValueObj>();

      map[KeyObj(1)] = ValueObj('a');
      map[KeyObj(2)] = ValueObj('b');

      map.clear();

      expect(map.isEmpty, isTrue);
      expect(map.swapped.isEmpty, isTrue);
    });

    test('keys and values views are swapped correctly', () {
      final map = DualWeakMap<KeyObj, ValueObj>();

      final k1 = KeyObj(1);
      final k2 = KeyObj(2);
      final v1 = ValueObj('a');
      final v2 = ValueObj('b');

      map[k1] = v1;
      map[k2] = v2;

      expect(map.keys.toSet(), equals({k1, k2}));
      expect(map.values.toSet(), equals({v1, v2}));

      final swapped = map.swapped;
      expect(swapped.keys.toSet(), equals({v1, v2}));
      expect(swapped.values.toSet(), equals({k1, k2}));
    });

    test('swapped assignment with same mapping is a no-op', () {
      final map = DualWeakMap<KeyObj, ValueObj>();
      final swapped = map.swapped;

      final k = KeyObj(1);
      final v = ValueObj('a');

      map[k] = v;
      swapped[v] = k;

      expect(map.length, 1);
      expect(map[k], same(v));
    });

    test('removing by key removes value mapping too', () {
      final map = DualWeakMap<KeyObj, ValueObj>();
      final swapped = map.swapped;

      final k = KeyObj(1);
      final v = ValueObj('a');

      map[k] = v;
      map.remove(k);

      expect(swapped[v], isNull);
      expect(map.isEmpty, isTrue);
    });

    test('entries and swapped entries stay consistent', () {
      final map = DualWeakMap<KeyObj, ValueObj>();

      final k = KeyObj(1);
      final v = ValueObj('a');

      map[k] = v;

      final e1 = map.entries.single;
      final e2 = map.entriesSwapped.single;

      expect(e1.key, same(k));
      expect(e1.value, same(v));
      expect(e2.key, same(v));
      expect(e2.value, same(k));
    });
  });
}
