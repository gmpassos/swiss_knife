import 'dart:collection';

/// A bidirectional map between non-nullable [K] and [V].
///
/// Each key maps to exactly one value and each value maps back to exactly one
/// key. Internally two maps are maintained:
/// - `_map`: K → V
/// - `_map2`: V → K
///
/// This allows O(1) lookup in both directions.
///
/// ⚠️ It is the caller’s responsibility to avoid inserting the same value for
/// different keys. If a value is reused, the reverse mapping will be overwritten
/// and the structure becomes inconsistent.
class DualMap<K extends Object, V extends Object> extends MapBase<K, V> {
  final Map<K, V> _map = {};
  final Map<V, K> _map2 = {};

  /// Returns the value associated with [key], or `null` if absent.
  V? get(Object? key) => _map[key];

  /// Associates [value] with [key].
  ///
  /// If either the key or value already existed, the previous relation is
  /// replaced in both directions.
  void put(K key, V value) {
    _map.update(
      key,
      (oldValue) {
        // Key existed → remove old reverse mapping.
        _map2.remove(oldValue);
        _map2[value] = key;
        return value;
      },
      ifAbsent: () {
        // New key.
        _map2[value] = key;
        return value;
      },
    );
  }

  @override
  V? operator [](Object? key) => get(key);

  @override
  void operator []=(K key, V value) => put(key, value);

  /// Removes all mappings from both directions.
  @override
  void clear() {
    _map.clear();
    _map2.clear();
  }

  /// Iterable view of the keys (K → V direction).
  @override
  Iterable<K> get keys => _map.keys;

  /// Iterable view of the values.
  ///
  /// Implemented using the reverse map keys to avoid allocation.
  @override
  Iterable<V> get values => _map2.keys;

  /// Iterable view of the forward entries.
  @override
  Iterable<MapEntry<K, V>> get entries => _map.entries;

  /// Removes the mapping for [key] and its reverse mapping.
  ///
  /// Returns the removed value, or `null` if absent.
  @override
  V? remove(Object? key) {
    final value = _map.remove(key);
    if (value != null) {
      _map2.remove(value);
    }
    return value;
  }

  /// Returns the key associated with [value], or `null` if absent.
  K? getKeyFromValue(V value) => _map2[value];

  @override
  V putIfAbsent(K key, V Function() ifAbsent) => _map.putIfAbsent(key, () {
        var value = ifAbsent();
        _map2[value] = key;
        return value;
      });

  /// Inserts [value] only if [key] is not already present.
  ///
  /// Returns `true` if the value was inserted, `false` otherwise.
  bool putValueIfAbsent(K key, V value) {
    var inserted = false;

    _map.putIfAbsent(key, () {
      inserted = true;
      _map2[value] = key;
      return value;
    });

    return inserted;
  }
}
