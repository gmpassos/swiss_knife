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

  @override
  String toString() => 'KeyObj($id)';
}

class ValueObj {
  final String label;

  ValueObj(this.label);

  @override
  bool operator ==(Object other) => other is ValueObj && other.label == label;

  @override
  int get hashCode => label.hashCode;

  @override
  String toString() => 'ValueObj($label)';
}

/// A [LazyWeakReferenceManager] that records every reference it creates.
///
/// Disposing a recorded reference makes its `target` permanently `null`,
/// which deterministically simulates a garbage-collected key/value without
/// depending on the GC actually running.
class TrackingManager<T extends Object> extends LazyWeakReferenceManager<T> {
  final List<LazyWeakReference<T>> refs = [];

  TrackingManager() : super(weakenDelay: Duration(seconds: 5));

  @override
  LazyWeakReference<T> strong(T target) {
    final ref = super.strong(target);
    refs.add(ref);
    return ref;
  }

  /// Disposes the reference created for [target] (simulates its collection).
  void lose(T target) {
    for (final ref in refs) {
      if (identical(ref.target, target)) {
        ref.dispose();
        return;
      }
    }
    throw StateError('No reference for $target');
  }
}

void main() {
  group('WeakKeyMap configuration', () {
    test('autoPurgeThreshold is normalized', () {
      expect(WeakKeyMap<KeyObj, ValueObj>().autoPurgeThreshold, 100);
      expect(
        WeakKeyMap<KeyObj, ValueObj>(autoPurgeThreshold: 5).autoPurgeThreshold,
        5,
      );
      expect(
        WeakKeyMap<KeyObj, ValueObj>(autoPurgeThreshold: 1).autoPurgeThreshold,
        1,
      );
      expect(
        WeakKeyMap<KeyObj, ValueObj>(autoPurgeThreshold: 0).autoPurgeThreshold,
        WeakKeyMap.defaultAutoPurgeThreshold,
      );
      expect(
        WeakKeyMap<KeyObj, ValueObj>(autoPurgeThreshold: -3).autoPurgeThreshold,
        WeakKeyMap.defaultAutoPurgeThreshold,
      );
    });

    test('isAutoPurgeEnabled', () {
      expect(WeakKeyMap<KeyObj, ValueObj>().isAutoPurgeEnabled, isTrue);
      expect(
        WeakKeyMap<KeyObj, ValueObj>(autoPurge: false).isAutoPurgeEnabled,
        isFalse,
      );
    });

    test('configured picks implementation by manager', () {
      final plain = WeakKeyMap<KeyObj, ValueObj>.configured(
        autoPurgeThreshold: 7,
      );
      expect(plain, isNot(isA<LazyWeakKeyMap>()));
      expect(plain.autoPurgeThreshold, 7);

      final lazy = WeakKeyMap<KeyObj, ValueObj>.configured(
        keyLazyRefManager: TrackingManager<KeyObj>(),
        autoPurge: false,
        autoPurgeThreshold: 3,
      );
      expect(lazy, isA<LazyWeakKeyMap<KeyObj, ValueObj>>());
      expect(lazy.isAutoPurgeEnabled, isFalse);
      expect(lazy.autoPurgeThreshold, 3);
    });

    test('DualWeakMap.configured needs both managers to be lazy', () {
      expect(
        DualWeakMap<KeyObj, ValueObj>.configured(),
        isNot(isA<DualLazyWeakMap>()),
      );
      expect(
        DualWeakMap<KeyObj, ValueObj>.configured(
          keyLazyRefManager: TrackingManager<KeyObj>(),
        ),
        isNot(isA<DualLazyWeakMap>()),
      );
      expect(
        DualWeakMap<KeyObj, ValueObj>.configured(
          valueLazyRefManager: TrackingManager<ValueObj>(),
        ),
        isNot(isA<DualLazyWeakMap>()),
      );
      expect(
        DualWeakMap<KeyObj, ValueObj>.configured(
          keyLazyRefManager: TrackingManager<KeyObj>(),
          valueLazyRefManager: TrackingManager<ValueObj>(),
          autoPurgeThreshold: 9,
        ),
        isA<DualLazyWeakMap<KeyObj, ValueObj>>().having(
          (m) => m.autoPurgeThreshold,
          'autoPurgeThreshold',
          9,
        ),
      );
    });
  });

  group('WeakKeyMap (strong references)', () {
    for (final lazy in [false, true]) {
      group(lazy ? 'lazy' : 'weak', () {
        WeakKeyMap<KeyObj, ValueObj> newMap({
          bool autoPurge = true,
          int autoPurgeThreshold = WeakKeyMap.defaultAutoPurgeThreshold,
          OnPurgedValues<ValueObj>? onPurgedValues,
        }) => WeakKeyMap<KeyObj, ValueObj>.configured(
          keyLazyRefManager: lazy ? TrackingManager<KeyObj>() : null,
          autoPurge: autoPurge,
          autoPurgeThreshold: autoPurgeThreshold,
          onPurgedValues: onPurgedValues,
        );

        test('getNoPurge', () {
          final map = newMap();
          final k = KeyObj(1);
          final v = ValueObj('a');
          map[k] = v;

          expect(map.getNoPurge(k), same(v));
          expect(map.getNoPurge(KeyObj(1)), isNull); // identity, not ==
          expect(map.getNoPurge(KeyObj(2)), isNull);
          expect(map.getNoPurge(null), isNull);
          expect(map.getNoPurge('x'), isNull);
        });

        test('lookups match by identity, not ==', () {
          final map = newMap();
          final k = KeyObj(1);
          map[k] = ValueObj('a');

          final equalKey = KeyObj(1);
          expect(equalKey == k, isTrue);
          expect(map[equalKey], isNull);
          expect(map.containsKey(equalKey), isFalse);
          expect(map.remove(equalKey), isNull);
          expect(map.length, 1);
        });

        test('putValueIfAbsent', () {
          final map = newMap();
          final k = KeyObj(1);
          final v1 = ValueObj('a');
          final v2 = ValueObj('b');

          expect(map.putValueIfAbsent(k, v1), isTrue);
          expect(map.putValueIfAbsent(k, v2), isFalse);
          expect(map[k], same(v1));
          expect(map.length, 1);
          expect(map.values.single, same(v1));
        });

        test('putValueIfAbsent counts towards auto-purge', () {
          final map = newMap(autoPurgeThreshold: 2);
          map.putValueIfAbsent(KeyObj(1), ValueObj('a'));
          expect(map.isAutoPurgeRequired(), isFalse);
          final k2 = KeyObj(2);
          map.putValueIfAbsent(k2, ValueObj('b'));
          expect(map.isAutoPurgeRequired(), isTrue);
        });

        test('putValueIfAbsent that does nothing does not count', () {
          final map = newMap(autoPurgeThreshold: 2);
          final k = KeyObj(1);
          map.putValueIfAbsent(k, ValueObj('a'));
          map.putValueIfAbsent(k, ValueObj('b'));
          map.putValueIfAbsent(k, ValueObj('c'));
          expect(map.isAutoPurgeRequired(), isFalse);
        });

        test('containsKeyNoPurge', () {
          final map = newMap();
          final k = KeyObj(1);
          map[k] = ValueObj('a');

          expect(map.containsKeyNoPurge(k), isTrue);
          expect(map.containsKeyNoPurge(KeyObj(1)), isFalse);
          expect(map.containsKeyNoPurge(null), isFalse);
          expect(map.containsKeyNoPurge(1), isFalse);
        });

        test('containsValue and containsValueNoPurge', () {
          final map = newMap();
          final k = KeyObj(1);
          final v = ValueObj('a');
          map[k] = v;
          map[KeyObj(2)] = ValueObj('b');

          expect(map.containsValue(v), isTrue);
          // `WeakKeyMap` compares values with `==`:
          expect(map.containsValue(ValueObj('a')), isTrue);
          expect(map.containsValue(ValueObj('z')), isFalse);
          // ignore: collection_methods_unrelated_type
          expect(map.containsValue(null), isFalse);

          expect(map.containsValueNoPurge(v), isTrue);
          expect(map.containsValueNoPurge(ValueObj('b')), isTrue);
          expect(map.containsValueNoPurge(ValueObj('z')), isFalse);
          expect(map.containsValueNoPurge(null), isFalse);
        });

        test('removeWhereKey', () {
          final map = newMap();
          final keys = List.generate(5, KeyObj.new);
          for (final k in keys) {
            map[k] = ValueObj('${k.id}');
          }

          map.removeWhereKey((k) => k.id.isEven);

          expect(map.keys.map((k) => k.id).toList(), [1, 3]);
          expect(map.values.map((v) => v.label).toList(), ['1', '3']);
        });

        test('removeWhere passes key and value', () {
          final map = newMap();
          final keys = List.generate(4, KeyObj.new);
          for (final k in keys) {
            map[k] = ValueObj('v${k.id}');
          }

          final seen = <String>[];
          map.removeWhere((k, v) {
            seen.add('${k.id}=${v.label}');
            return v.label == 'v2';
          });

          expect(seen, ['0=v0', '1=v1', '2=v2', '3=v3']);
          expect(map.keys.map((k) => k.id).toList(), [0, 1, 3]);
        });

        test('iterator: current before moveNext throws', () {
          final map = newMap();
          map[KeyObj(1)] = ValueObj('a');

          final it = map.keys.iterator;
          expect(() => it.current, throwsStateError);
          expect(it.moveNext(), isTrue);
          expect(it.current.id, 1);
          expect(it.moveNext(), isFalse);
          // Once done, it stays done:
          expect(it.moveNext(), isFalse);
        });

        test('iterator on empty map', () {
          final map = newMap();
          final it = map.entries.iterator;
          expect(it.moveNext(), isFalse);
          expect(() => it.current, throwsStateError);
          expect(it.moveNext(), isFalse);
        });

        test('entries, entriesSwapped and toString', () {
          final map = newMap();
          final k1 = KeyObj(1);
          final k2 = KeyObj(2);
          map[k1] = ValueObj('a');
          map[k2] = ValueObj('b');

          expect(
            map.entries.map((e) => '${e.key.id}:${e.value.label}').toList(),
            ['1:a', '2:b'],
          );
          expect(
            map.entriesSwapped
                .map((e) => '${e.key.label}:${e.value.id}')
                .toList(),
            ['a:1', 'b:2'],
          );
          expect(
            map.toString(),
            '{KeyObj(1): ValueObj(a), KeyObj(2): '
            'ValueObj(b)}',
          );
        });

        test('purge with nothing collected', () {
          final purged = <List<ValueObj>>[];
          final map = newMap(onPurgedValues: purged.add);
          final k = KeyObj(1);
          map[k] = ValueObj('a');

          expect(map.purge(), same(map));
          expect(purged, isEmpty);
          expect(map[k]!.label, 'a');
          expect(map.length, 1);
        });

        test('purge without callback', () {
          final map = newMap();
          final k = KeyObj(1);
          map[k] = ValueObj('a');
          expect(map.purge(), same(map));
          expect(map.length, 1);
        });

        test('autoPurge resets the operation counter', () {
          final map = newMap(autoPurgeThreshold: 2);
          final k1 = KeyObj(1);
          final k2 = KeyObj(2);

          map[k1] = ValueObj('a');
          expect(map.isAutoPurgeRequired(), isFalse);
          expect(map.autoPurge(), isFalse);

          map[k2] = ValueObj('b');
          expect(map.isAutoPurgeRequired(), isTrue);
          expect(map.autoPurge(), isTrue);
          expect(map.isAutoPurgeRequired(), isFalse);
          expect(map.autoPurge(), isFalse);
          expect(map.length, 2);
        });

        test('length triggers auto-purge', () {
          final map = newMap(autoPurgeThreshold: 1);
          final k = KeyObj(1);
          map[k] = ValueObj('a');
          expect(map.isAutoPurgeRequired(), isTrue);
          expect(map.length, 1);
          expect(map.isAutoPurgeRequired(), isFalse);
        });

        test('auto-purge disabled', () {
          final map = newMap(autoPurge: false, autoPurgeThreshold: 1);
          final k = KeyObj(1);
          map[k] = ValueObj('a');
          expect(map.isAutoPurgeRequired(), isFalse);
          expect(map.autoPurge(), isFalse);
        });

        test('clear resets the operation counter', () {
          final map = newMap(autoPurgeThreshold: 2);
          final k1 = KeyObj(1);
          final k2 = KeyObj(2);
          map[k1] = ValueObj('a');
          map[k2] = ValueObj('b');
          expect(map.isAutoPurgeRequired(), isTrue);
          map.clear();
          expect(map.isAutoPurgeRequired(), isFalse);
          expect(map.isEmpty, isTrue);
        });

        test('put overwrite: lookup returns the new value', () {
          final map = newMap();
          final k = KeyObj(1);
          final v1 = ValueObj('a');
          final v2 = ValueObj('b');

          map[k] = v1;
          map[k] = v2;

          expect(map[k], same(v2));
          expect(map.getEntry(k)!.value, same(v2));
          expect(map.length, 1);

          // Regression: an existing equal key entry was kept as the internal
          // map key, so iteration (`keys`/`values`/`entries`/`iterate`/
          // `containsValue`) still saw the OLD value after an overwrite.
          expect(map.keys.single, same(k));
          expect(map.values.single, same(v2));
          expect(map.entries.single.value, same(v2));
          expect(map.containsValue(v1), isFalse);
          expect(map.containsValue(v2), isTrue);

          // `remove` returns the current value:
          expect(map.remove(k), same(v2));
          expect(map.isEmpty, isTrue);
        });
      });
    }
  });

  group('LazyWeakKeyMap with simulated collected keys', () {
    late TrackingManager<KeyObj> keyManager;
    late List<List<ValueObj>> purged;
    late LazyWeakKeyMap<KeyObj, ValueObj> map;
    late List<KeyObj> keys;
    late List<ValueObj> values;

    setUp(() {
      keyManager = TrackingManager<KeyObj>();
      purged = [];
      map = LazyWeakKeyMap<KeyObj, ValueObj>(
        keyManager,
        autoPurgeThreshold: 1000,
        onPurgedValues: purged.add,
      );
      keys = List.generate(3, KeyObj.new);
      values = List.generate(3, (i) => ValueObj('v$i'));
      for (var i = 0; i < 3; i++) {
        map[keys[i]] = values[i];
      }
      // Simulate the collection of key #1:
      keyManager.lose(keys[1]);
    });

    test('purge removes collected keys and reports their values', () {
      expect(map.purge(), same(map));
      expect(purged, [
        [values[1]],
      ]);
      expect(map.keys.toList(), [keys[0], keys[2]]);

      // A second purge reports nothing:
      map.purge();
      expect(purged.length, 1);
    });

    test('auto-purge via length', () {
      final map2 = LazyWeakKeyMap<KeyObj, ValueObj>(
        keyManager,
        autoPurgeThreshold: 2,
        onPurgedValues: purged.add,
      );
      final k1 = KeyObj(10);
      final k2 = KeyObj(11);
      map2[k1] = ValueObj('x');
      map2[k2] = ValueObj('y');
      keyManager.lose(k1);

      expect(map2.isAutoPurgeRequired(), isTrue);
      expect(map2.length, 1);
      expect(purged.single.single.label, 'x');
    });

    test('purge without callback', () {
      final map2 = LazyWeakKeyMap<KeyObj, ValueObj>(keyManager);
      final k1 = KeyObj(10);
      final k2 = KeyObj(11);
      map2[k1] = ValueObj('x');
      map2[k2] = ValueObj('y');
      keyManager.lose(k1);

      map2.purge();
      expect(map2.keys.toList(), [k2]);
    });

    test('iterate skips and removes collected keys', () {
      final seen = <int>[];
      map.iterate((k, v) => seen.add(k.id));
      expect(seen, [0, 2]);
      expect(map.length, 2);
      // Nothing left to purge:
      map.purge();
      expect(purged, isEmpty);
    });

    test('keys iteration skips and removes collected keys', () {
      expect(map.keys.map((k) => k.id).toList(), [0, 2]);
      map.purge();
      expect(purged, isEmpty);
      expect(map.length, 2);
    });

    test('values and entries skip collected keys', () {
      expect(map.values.toList(), [values[0], values[2]]);
      expect(map.entries.map((e) => e.key.id).toList(), [0, 2]);
      expect(map.entriesSwapped.map((e) => e.key.label).toList(), ['v0', 'v2']);
    });

    test('partially consumed iterator does not remove entries', () {
      final it = map.keys.iterator;
      expect(it.moveNext(), isTrue);
      expect(it.current.id, 0);
      expect(it.moveNext(), isTrue);
      expect(it.current.id, 2);
      // Not finished yet: the collected entry is still pending removal.
      map.purge();
      expect(purged, [
        [values[1]],
      ]);
    });

    test('containsValue skips and removes collected keys', () {
      // Value of the collected key is not reported:
      expect(map.containsValue(values[1]), isFalse);
      expect(map.containsValue(values[2]), isTrue);
      map.purge();
      expect(purged, isEmpty);
      expect(map.length, 2);
    });

    test('containsValue found before reaching the collected entry', () {
      expect(map.containsValue(values[0]), isTrue);
      // Stopped at the first entry, so the collected one is still there:
      map.purge();
      expect(purged, [
        [values[1]],
      ]);
    });

    test('containsValueNoPurge still sees values of collected keys', () {
      expect(map.containsValueNoPurge(values[1]), isTrue);
      map.purge();
      expect(purged, [
        [values[1]],
      ]);
    });

    test('removeWhere removes collected keys without testing them', () {
      final tested = <int>[];
      map.removeWhere((k, v) {
        tested.add(k.id);
        return k.id == 2;
      });
      expect(tested, [0, 2]);
      expect(map.keys.toList(), [keys[0]]);
      map.purge();
      expect(purged, isEmpty);
    });

    test('removeWhereKey removes collected keys without testing them', () {
      final tested = <int>[];
      map.removeWhereKey((k) {
        tested.add(k.id);
        return false;
      });
      expect(tested, [0, 2]);
      expect(map.keys.toList(), [keys[0], keys[2]]);
      map.purge();
      expect(purged, isEmpty);
    });

    test('lookups of a collected key return nothing', () {
      expect(map[keys[1]], isNull);
      expect(map.getNoPurge(keys[1]), isNull);
      expect(map.getEntry(keys[1]), isNull);
      expect(map.containsKey(keys[1]), isFalse);
      expect(map.remove(keys[1]), isNull);
      // Live keys are unaffected:
      expect(map[keys[0]], same(values[0]));
      expect(map[keys[2]], same(values[2]));
    });

    test('clear', () {
      map.clear();
      expect(map.isEmpty, isTrue);
      map.purge();
      expect(purged, isEmpty);
    });
  });

  group('DualWeakMap (strong references)', () {
    for (final lazy in [false, true]) {
      group(lazy ? 'lazy' : 'weak', () {
        DualWeakMap<KeyObj, ValueObj> newMap() =>
            DualWeakMap<KeyObj, ValueObj>.configured(
              keyLazyRefManager: lazy ? TrackingManager<KeyObj>() : null,
              valueLazyRefManager: lazy ? TrackingManager<ValueObj>() : null,
            );

        test('containsValue uses identity', () {
          final map = newMap();
          final k = KeyObj(1);
          final v = ValueObj('a');
          map[k] = v;

          expect(map.containsValue(v), isTrue);
          expect(map.containsValue(ValueObj('a')), isFalse);
          // ignore: collection_methods_unrelated_type
          expect(map.containsValue(null), isFalse);
          // ignore: collection_methods_unrelated_type
          expect(map.containsValue(123), isFalse);

          expect(map.containsValueNoPurge(v), isTrue);
          expect(map.containsValueNoPurge(ValueObj('a')), isFalse);
          expect(map.containsValueNoPurge(null), isFalse);
          expect(map.containsValueNoPurge('x'), isFalse);
        });

        test('putValueIfAbsent registers the value side', () {
          final map = newMap();
          final k = KeyObj(1);
          final v1 = ValueObj('a');
          final v2 = ValueObj('b');

          expect(map.putValueIfAbsent(k, v1), isTrue);
          expect(map.putValueIfAbsent(k, v2), isFalse);
          expect(map.getKeyFromValue(v1), same(k));
          expect(map.getKeyFromValue(v2), isNull);
          expect(map.containsValue(v2), isFalse);
        });

        test('removeWhere and removeWhereKey update the value side', () {
          final map = newMap();
          final keys = List.generate(4, KeyObj.new);
          final values = List.generate(4, (i) => ValueObj('v$i'));
          for (var i = 0; i < 4; i++) {
            map[keys[i]] = values[i];
          }

          map.removeWhere((k, v) => k.id == 1);
          map.removeWhereKey((k) => k.id == 3);

          expect(map.keys.toList(), [keys[0], keys[2]]);
          expect(map.getKeyFromValue(values[1]), isNull);
          expect(map.getKeyFromValue(values[3]), isNull);
          expect(map.getKeyFromValue(values[2]), same(keys[2]));
          expect(map.swapped.keys.toList(), [values[0], values[2]]);
        });

        test('purge with nothing collected', () {
          final map = newMap();
          final k = KeyObj(1);
          final v = ValueObj('a');
          map[k] = v;
          map.purge();
          expect(map[k], same(v));
          expect(map.getKeyFromValue(v), same(k));
        });

        test('swapped view operations', () {
          final map = newMap();
          final swapped = map.swapped;

          final k1 = KeyObj(1);
          final k2 = KeyObj(2);
          final v1 = ValueObj('a');
          final v2 = ValueObj('b');

          // Insert through the swapped view (no previous mapping):
          swapped[v1] = k1;
          swapped[v2] = k2;

          expect(map[k1], same(v1));
          expect(map[k2], same(v2));
          expect(swapped.length, 2);
          expect(swapped[v1], same(k1));
          expect(swapped.entries.map((e) => '${e.key}=${e.value}').toList(), [
            'ValueObj(a)=KeyObj(1)',
            'ValueObj(b)=KeyObj(2)',
          ]);
          expect(swapped.keys.toList(), [v1, v2]);
          expect(swapped.values.toList(), [k1, k2]);
          expect(swapped.containsKey(v2), isTrue);

          expect(swapped.remove(v2), same(k2));
          expect(map.containsKey(k2), isFalse);
          expect(swapped.remove(v2), isNull);

          swapped.clear();
          expect(map.isEmpty, isTrue);
          expect(swapped.isEmpty, isTrue);
          expect(map.getKeyFromValue(v1), isNull);
        });

        test('put overwrite removes the previous reverse mapping', () {
          final map = newMap();
          final k = KeyObj(1);
          final v1 = ValueObj('a');
          final v2 = ValueObj('b');

          map[k] = v1;
          map[k] = v2;

          expect(map[k], same(v2));
          expect(map.getKeyFromValue(v2), same(k));
          expect(map.length, 1);
          expect(map.values.single, same(v2));

          // Regression: overwriting `k` kept the reverse (value -> key) entry
          // of the previous value `v1`.
          expect(map.getKeyFromValue(v1), isNull);
          expect(map.containsValue(v1), isFalse);

          // Re-putting the same value keeps the mapping:
          map[k] = v2;
          expect(map.getKeyFromValue(v2), same(k));
          expect(map.length, 1);
        });
      });
    }
  });

  group('DualLazyWeakMap with simulated collection', () {
    late TrackingManager<KeyObj> keyManager;
    late TrackingManager<ValueObj> valueManager;
    late List<List<ValueObj>> purged;
    late DualLazyWeakMap<KeyObj, ValueObj> map;
    late List<KeyObj> keys;
    late List<ValueObj> values;

    setUp(() {
      keyManager = TrackingManager<KeyObj>();
      valueManager = TrackingManager<ValueObj>();
      purged = [];
      map = DualLazyWeakMap<KeyObj, ValueObj>(
        keyManager,
        valueManager,
        autoPurgeThreshold: 1000,
        onPurgedValues: purged.add,
      );
      keys = List.generate(3, KeyObj.new);
      values = List.generate(3, (i) => ValueObj('v$i'));
      for (var i = 0; i < 3; i++) {
        map[keys[i]] = values[i];
      }
    });

    group('collected value', () {
      setUp(() => valueManager.lose(values[1]));

      test('get removes the entry', () {
        expect(map[keys[1]], isNull);
        expect(map.containsKeyNoPurge(keys[1]), isFalse);
        expect(map.keys.toList(), [keys[0], keys[2]]);
      });

      test('getEntry removes the entry', () {
        expect(map.getEntry(keys[1]), isNull);
        expect(map.containsKeyNoPurge(keys[1]), isFalse);
        expect(map.getEntry(keys[2])!.value, same(values[2]));
      });

      test('getNoPurge returns null but keeps the entry', () {
        expect(map.getNoPurge(keys[1]), isNull);
        expect(map.containsKeyNoPurge(keys[1]), isTrue);
        // The key is still alive, so `containsKey` reports it:
        expect(map.containsKey(keys[1]), isTrue);
      });

      test('iterate skips and removes the entry', () {
        final seen = <int>[];
        map.iterate((k, v) => seen.add(k.id));
        expect(seen, [0, 2]);
        expect(map.containsKeyNoPurge(keys[1]), isFalse);
      });

      test('keys iteration skips and removes the entry', () {
        expect(map.keys.map((k) => k.id).toList(), [0, 2]);
        expect(map.containsKeyNoPurge(keys[1]), isFalse);
      });

      test('removeWhere removes the entry without testing it', () {
        final tested = <int>[];
        map.removeWhere((k, v) {
          tested.add(k.id);
          return false;
        });
        expect(tested, [0, 2]);
        expect(map.containsKeyNoPurge(keys[1]), isFalse);
      });

      test('purge drops the entry of the collected value', () {
        map.purge();
        // The key is alive, so no value is reported:
        expect(purged, isEmpty);
        expect(map.containsKeyNoPurge(keys[1]), isFalse);
        expect(map.keys.toList(), [keys[0], keys[2]]);
        expect(map.swapped.keys.toList(), [values[0], values[2]]);
      });
    });

    group('collected key', () {
      setUp(() => keyManager.lose(keys[1]));

      test('getKeyFromValue removes the entry', () {
        expect(map.getKeyFromValue(values[1]), isNull);
        expect(map.containsValueNoPurge(values[1]), isFalse);
        expect(map.length, 2);
        expect(map.getKeyFromValue(values[2]), same(keys[2]));
      });

      test('swapped [] removes the entry', () {
        expect(map.swapped[values[1]], isNull);
        expect(map.containsValueNoPurge(values[1]), isFalse);
      });

      test('containsValue removes the entry', () {
        // The value itself is alive:
        expect(map.containsValueNoPurge(values[1]), isTrue);
        expect(map.containsValue(values[1]), isFalse);
        expect(map.containsValueNoPurge(values[1]), isFalse);
        expect(map.length, 2);
      });

      test('purge reports the value of the collected key', () {
        map.purge();
        expect(purged, [
          [values[1]],
        ]);
        expect(map.keys.toList(), [keys[0], keys[2]]);

        // NOTE: current behaviour; possibly a bug: `purge` removes the key
        // entry from the internal key map directly (bypassing
        // `_onRemoveEntry`), and `_onPurgeValues` only drops reverse entries
        // whose *value* was collected. So the reverse entry of a live value
        // whose key was collected survives the purge:
        expect(map.containsValueNoPurge(values[1]), isTrue);
        // It is only dropped lazily, on a purging lookup:
        expect(map.getKeyFromValue(values[1]), isNull);
        expect(map.containsValueNoPurge(values[1]), isFalse);
      });

      test('keys iteration removes the entry on both sides', () {
        expect(map.keys.toList(), [keys[0], keys[2]]);
        expect(map.containsValueNoPurge(values[1]), isFalse);
      });
    });
  });
}
