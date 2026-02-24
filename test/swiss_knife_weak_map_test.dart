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
  group('WeakReference', () {
    _doTests();
  });

  group('LazyWeakReference', () {
    _doTests(LazyWeakReferenceManager(), LazyWeakReferenceManager());
  });
}

void _doTests(
    [LazyWeakReferenceManager<KeyObj>? keyManager,
    LazyWeakReferenceManager<ValueObj>? valueManager]) {
  group('WeakKeyMap', () {
    test('put and get', () {
      final map = _newWeakKeyMap(keyManager);

      final k = KeyObj(1);
      final v = ValueObj('a');

      map[k] = v;

      expect(map[k], same(v));
      expect(map.length, 1);
    });

    test('containsKey and containsValue', () {
      final map = _newWeakKeyMap(keyManager);

      final k = KeyObj(1);
      final v = ValueObj('a');

      map[k] = v;

      expect(map.containsKey(k), isTrue);
      expect(map.containsValue(v), isTrue);
    });

    test('remove returns value and deletes entry', () {
      final map = _newWeakKeyMap(keyManager);

      final k = KeyObj(1);
      final v = ValueObj('a');

      map[k] = v;

      final removed = map.remove(k);

      expect(removed, same(v));
      expect(map.containsKey(k), isFalse);
      expect(map.length, 0);
    });

    test('iterate visits all entries', () {
      final map = _newWeakKeyMap(keyManager);

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
      final map = _newWeakKeyMap(keyManager);

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
      final map = _newWeakKeyMap(keyManager);

      final k = KeyObj(1);
      final v = ValueObj('a');

      map[k] = v;

      final swapped = map.entriesSwapped.single;
      expect(swapped.key, same(v));
      expect(swapped.value, same(k));
    });

    test('removeWhere removes matching entries', () {
      final map = _newWeakKeyMap(keyManager);

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
      final map = _newWeakKeyMap(keyManager);

      map[KeyObj(1)] = ValueObj('a');

      expect(map.containsKey(null), isFalse);
      expect(map[null], isNull);
      // ignore: collection_methods_unrelated_type
      expect(map['wrong-type'], isNull);
    });

    test('clear resets length and state', () {
      final map = _newWeakKeyMap(keyManager);

      map[KeyObj(1)] = ValueObj('a');
      map.clear();

      expect(map.length, 0);
      expect(map.keys, isEmpty);
      expect(map.values, isEmpty);
    });

    test('getEntry returns MapEntry when key and value are alive', () {
      final map = _newWeakKeyMap(keyManager);

      final k = KeyObj(1);
      final v = ValueObj('a');

      map[k] = v;

      final entry = map.getEntry(k);

      expect(entry, isNotNull);
      expect(entry!.key, same(k));
      expect(entry.value, same(v));
    });

    test('getEntry returns null for missing or invalid keys', () {
      final map = _newWeakKeyMap(keyManager);

      map[KeyObj(1)] = ValueObj('a');

      expect(map.getEntry(KeyObj(999)), isNull);
      expect(map.getEntry(null), isNull);
      expect(map.getEntry('wrong-type'), isNull);
    });

    test('getEntry reflects removals', () {
      final map = _newWeakKeyMap(keyManager);

      final k = KeyObj(1);
      map[k] = ValueObj('a');

      map.remove(k);

      expect(map.getEntry(k), isNull);
    });
  });

  group('DualWeakMap', () {
    test('put and get by key', () {
      final map = _newDualWeakMap(keyManager, valueManager);

      final k = KeyObj(1);
      final v = ValueObj('a');

      map[k] = v;

      expect(map[k], same(v));
      expect(map.length, 1);
    });

    test('swapped map get by value', () {
      final map = _newDualWeakMap(keyManager, valueManager);
      final swapped = map.swapped;

      final k = KeyObj(1);
      final v = ValueObj('a');

      map[k] = v;

      expect(swapped[v], same(k));
    });

    test('swapped assignment overwrites correctly', () {
      final map = _newDualWeakMap(keyManager, valueManager);
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
      final map = _newDualWeakMap(keyManager, valueManager);
      final swapped = map.swapped;

      final k = KeyObj(1);
      final v = ValueObj('a');

      map[k] = v;

      final removedKey = swapped.remove(v);

      expect(removedKey, same(k));
      expect(map.isEmpty, isTrue);
    });

    test('clear clears both directions', () {
      final map = _newDualWeakMap(keyManager, valueManager);

      map[KeyObj(1)] = ValueObj('a');
      map[KeyObj(2)] = ValueObj('b');

      map.clear();

      expect(map.isEmpty, isTrue);
      expect(map.swapped.isEmpty, isTrue);
    });

    test('keys and values views are swapped correctly', () {
      final map = _newDualWeakMap(keyManager, valueManager);

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
      final map = _newDualWeakMap(keyManager, valueManager);
      final swapped = map.swapped;

      final k = KeyObj(1);
      final v = ValueObj('a');

      map[k] = v;
      swapped[v] = k;

      expect(map.length, 1);
      expect(map[k], same(v));
    });

    test('removing by key removes value mapping too', () {
      final map = _newDualWeakMap(keyManager, valueManager);
      final swapped = map.swapped;

      final k = KeyObj(1);
      final v = ValueObj('a');

      map[k] = v;
      map.remove(k);

      expect(swapped[v], isNull);
      expect(map.isEmpty, isTrue);
    });

    test('entries and swapped entries stay consistent', () {
      final map = _newDualWeakMap(keyManager, valueManager);

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

    test('getKeyFromValue returns key for existing value', () {
      final map = _newDualWeakMap(keyManager, valueManager);

      final k = KeyObj(1);
      final v = ValueObj('a');

      map[k] = v;

      final key = map.getKeyFromValue(v);

      expect(key, same(k));
    });

    test('getKeyFromValue returns null for unknown value', () {
      final map = _newDualWeakMap(keyManager, valueManager);

      map[KeyObj(1)] = ValueObj('a');

      expect(map.getKeyFromValue(ValueObj('missing')), isNull);
    });

    test('getKeyFromValue is null- and type-safe', () {
      final map = _newDualWeakMap(keyManager, valueManager);

      map[KeyObj(1)] = ValueObj('a');

      expect(map.getKeyFromValue(null), isNull);
      expect(map.getKeyFromValue('wrong-type'), isNull);
    });

    test('getKeyFromValue reflects removals', () {
      final map = _newDualWeakMap(keyManager, valueManager);

      final k = KeyObj(1);
      final v = ValueObj('a');

      map[k] = v;
      map.remove(k);

      expect(map.getKeyFromValue(v), isNull);
    });
  });
}

WeakKeyMap<KeyObj, ValueObj> _newWeakKeyMap(
        LazyWeakReferenceManager<KeyObj>? keyManager) =>
    WeakKeyMap<KeyObj, ValueObj>.configured(keyLazyRefManager: keyManager);

DualWeakMap<KeyObj, ValueObj> _newDualWeakMap(
        LazyWeakReferenceManager<KeyObj>? keyManager,
        LazyWeakReferenceManager<ValueObj>? valueManager) =>
    DualWeakMap<KeyObj, ValueObj>.configured(
        keyLazyRefManager: keyManager, valueLazyRefManager: valueManager);
