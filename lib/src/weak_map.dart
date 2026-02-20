import 'dart:collection';

/// Internal map entry abstraction.
///
/// Encapsulates equality and hashing semantics based on the underlying
/// [target], allowing comparison against both other entries and raw keys.
abstract class _Entry<K extends Object, V extends Object> {
  /// Cached hash code derived from the original target.
  final int _hashCode;

  _Entry(this._hashCode);

  /// The referenced key object, or `null` if it was garbage-collected.
  K? get target;

  /// The associated value (payload), or `null` if unavailable or collected.
  V? get payload;

  @override
  int get hashCode => _hashCode;

  /// Equality is based on the underlying [target].
  ///
  /// Supports comparison with both other [_Entry] instances and raw key
  /// objects for efficient map lookups.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    if (other is _Entry<K, V>) {
      if (_hashCode != other._hashCode) return false;

      final target = this.target;
      if (target == null) return false;

      final otherTarget = other.target;
      if (otherTarget == null) return false;

      if (identical(target, otherTarget)) return true;
      return target == otherTarget;
    } else {
      final target = this.target;
      if (target == null) return false;

      if (identical(target, other)) return true;
      return target == other;
    }
  }
}

/// Strong-key entry used only for lookups.
///
/// Holds a strong reference to the key and has no associated payload.
class _EntryKey<K extends Object, V extends Object> extends _Entry<K, V> {
  final K _obj;

  _EntryKey(K key)
      : _obj = key,
        super(key.hashCode);

  @override
  K get target => _obj;

  /// Always throws, as lookup entries do not carry values.
  @override
  V get payload => throw UnsupportedError("No `payload` for `_KeyObj` class");

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    if (other is _Entry<K, V>) {
      if (_hashCode != other._hashCode) return false;

      final otherTarget = other.target;
      if (otherTarget == null) return false;

      final target = _obj;
      if (identical(target, otherTarget)) return true;
      return target == otherTarget;
    } else {
      final target = _obj;
      if (identical(target, other)) return true;
      return target == other;
    }
  }

  @override
  int get hashCode => _hashCode;
}

/// Base class for entries holding a weakly-referenced key.
abstract class _EntryRef<K extends Object, V extends Object>
    extends _Entry<K, V> {
  /// Weak reference to the key.
  final WeakReference<K> _refKey;

  _EntryRef(K key)
      : _refKey = WeakReference(key),
        super(key.hashCode);

  @override
  K? get target => _refKey.target;
}

/// Entry with a weak key and a strong value.
class _EntryRef1<K extends Object, V extends Object> extends _EntryRef<K, V> {
  final V _value;

  _EntryRef1(super.key, V value) : _value = value;

  @override
  V get payload => _value;
}

/// Entry with both key and value weakly referenced.
///
/// The value is tracked via a paired [_EntryRefValue].
class _EntryRef2<K extends Object, V extends Object> extends _EntryRef<K, V> {
  late final _EntryRefValue<V, K> _valueEntry;

  _EntryRef2(super.key, V value) {
    _valueEntry = _EntryRefValue<V, K>(this, value);
  }

  @override
  V? get payload => _valueEntry._refValue.target;
}

/// Weak-value entry paired with a [_EntryRef2] key entry.
class _EntryRefValue<V extends Object, K extends Object> extends _Entry<V, K> {
  final _EntryRef2<K, V> _keyEntry;

  /// Weak reference to the value.
  final WeakReference<V> _refValue;

  _EntryRefValue(this._keyEntry, V value)
      : _refValue = WeakReference(value),
        super(value.hashCode);

  /// Back-reference to the owning key entry.
  _EntryRef2<K, V> get keyEntry => _keyEntry;

  @override
  V? get target => _refValue.target;

  @override
  K? get payload => _keyEntry._refKey.target;
}

/// A [Map] with weakly-referenced keys.
///
/// Unlike [Expando], this is a full [Map] implementation, supporting the
/// complete set of [Map] operations such as iteration, removal, and views
/// over keys, values, and entries.
///
/// Entries are automatically purged when keys are garbage-collected.
/// Optional auto-purge logic prevents unbounded growth and can notify
/// consumers about removed values.
class WeakKeyMap<K extends Object, V extends Object> extends MapBase<K, V> {
  /// Internal storage mapping entries to themselves.
  final Map<_EntryRef<K, V>, _EntryRef<K, V>> _map = {};

  final bool _autoPurge;
  final int _autoPurgeThreshold;

  /// Default threshold for triggering auto-purge.
  static const defaultAutoPurgeThreshold = 100;

  /// Optional callback invoked with values removed during purge.
  final void Function(List<V> purgedValues)? onPurgedValues;

  WeakKeyMap(
      {bool autoPurge = true,
      int autoPurgeThreshold = defaultAutoPurgeThreshold,
      this.onPurgedValues})
      : _autoPurge = autoPurge,
        _autoPurgeThreshold = _normalizeAutoPurgeThreshold(autoPurgeThreshold),
        super();

  static int _normalizeAutoPurgeThreshold(int autoPurgeThreshold) =>
      autoPurgeThreshold >= 1 ? autoPurgeThreshold : defaultAutoPurgeThreshold;

  /// Number of operations tolerated before auto-purge is triggered.
  int get autoPurgeThreshold => _autoPurgeThreshold;

  @override
  V? operator [](Object? key) => get(key);

  @override
  void operator []=(K key, V value) => put(key, value);

  /// Returns the value associated with [key], or `null` if absent or collected.
  V? get(Object? key) {
    if (key == null || key is! K) return null;

    var k = _EntryKey<K, V>(key);
    // ignore: collection_methods_unrelated_type
    var e = _map[k];
    if (e == null) return null;

    var eKey = e.target;
    var eValue = e.payload;

    if (eKey == null || eValue == null) {
      _map.remove(e);
      _onRemoveEntry(e);
      ++_unpurgedCount;
      return null;
    }

    return eValue;
  }

  /// Returns the value associated with [key], or `null` if absent or collected.
  /// Same as [get], but does NOT purge entries with collected key or value.
  V? getNoPurge(Object? key) {
    if (key == null || key is! K) return null;

    var k = _EntryKey<K, V>(key);
    // ignore: collection_methods_unrelated_type
    var e = _map[k];
    if (e == null) return null;

    var eValue = e.payload;
    return eValue;
  }

  /// Returns the [MapEntry] for [key], or `null` if not found or invalid.
  ///
  /// If [key] is `null`, not of type [K], or if the weak key or value was
  /// garbage-collected, the entry is removed and `null` is returned.
  MapEntry<K, V>? getEntry(Object? key) {
    if (key == null || key is! K) return null;

    var k = _EntryKey<K, V>(key);
    // ignore: collection_methods_unrelated_type
    var e = _map[k];
    if (e == null) return null;

    var eKey = e.target;
    var eValue = e.payload;

    if (eKey == null || eValue == null) {
      _map.remove(e);
      _onRemoveEntry(e);
      ++_unpurgedCount;
      return null;
    }

    return MapEntry(eKey, eValue);
  }

  /// Hook invoked when an entry is removed.
  void _onRemoveEntry(_EntryRef<K, V> e) {}

  /// Inserts or replaces a key-value pair.
  void put(K key, V value) {
    var keyEntry = _createEntry(key, value);
    _map[keyEntry] = keyEntry;
    _onPutEntry(keyEntry, value);
    ++_unpurgedCount;
  }

  /// Inserts [value] for [key] only if no entry for [key] already exists.
  ///
  /// Returns `true` if the value was inserted, or `false` if an entry was
  /// already present and nothing was changed.
  ///
  /// This does not replace an existing value.
  bool putValueIfAbsent(K key, V value) {
    var keyEntry = _createEntry(key, value);
    var put = false;
    _map.putIfAbsent(keyEntry, () {
      put = true;
      return keyEntry;
    });
    if (put) {
      _onPutEntry(keyEntry, value);
      ++_unpurgedCount;
    }
    return put;
  }

  /// Factory for creating entry representations.
  _EntryRef<K, V> _createEntry(key, value) => _EntryRef1<K, V>(key, value);

  /// Hook invoked after inserting an entry.
  void _onPutEntry(_EntryRef<K, V> e, V value) {}

  @override
  void clear() {
    _map.clear();
    _unpurgedCount = 0;
  }

  int _unpurgedCount = 0;

  /// Removes all entries whose keys were garbage-collected.
  WeakKeyMap<K, V> purge() {
    final onPurgedValues = this.onPurgedValues;

    var purgedValues = <V>[];

    _map.removeWhere((key, value) {
      if (value.target == null) {
        if (onPurgedValues != null) {
          var v = value.payload;
          if (v != null) {
            purgedValues.add(v);
          }
        }
        return true;
      }
      return false;
    });

    _onPurgeValues(purgedValues);

    _unpurgedCount = 0;

    if (onPurgedValues != null && purgedValues.isNotEmpty) {
      onPurgedValues(purgedValues);
    }

    return this;
  }

  /// Hook invoked after a purge operation.
  void _onPurgeValues(List<V> purgedValues) {}

  /// Whether auto-purge is enabled.
  bool get isAutoPurgeEnabled => _autoPurge;

  /// Runs purge automatically if the threshold is exceeded.
  bool autoPurge() {
    if (_autoPurge && isAutoPurgeRequired()) {
      purge();
      return true;
    }
    return false;
  }

  /// Returns `true` if auto-purge should be triggered.
  bool isAutoPurgeRequired() => _unpurgedCount >= _autoPurgeThreshold;

  @override
  int get length {
    autoPurge();
    return _map.length;
  }

  @override
  Iterable<K> get keys => _WeakMapIterable<K, V, K>(this, (k, v) => k);

  @override
  Iterable<V> get values => _WeakMapIterable<K, V, V>(this, (k, v) => v);

  @override
  Iterable<MapEntry<K, V>> get entries =>
      _WeakMapIterable<K, V, MapEntry<K, V>>(this, (k, v) => MapEntry(k, v));

  /// Iterable of entries with key and value swapped.
  /// See [DualWeakMap.swapped] [SwappedDualWeakMap]
  Iterable<MapEntry<V, K>> get entriesSwapped =>
      _WeakMapIterable<K, V, MapEntry<V, K>>(this, (k, v) => MapEntry(v, k));

  /// Iterates over live entries only.
  void iterate(void Function(K, V) action) {
    List<_Entry<K, V>>? del;

    for (var k in _map.keys) {
      var target = k.target;
      if (target == null) {
        del ??= <_Entry<K, V>>[];
        del.add(k);
      } else {
        var payload = k.payload;
        if (payload != null) {
          action(target, payload);
        } else {
          del ??= <_Entry<K, V>>[];
          del.add(k);
        }
      }
    }

    if (del != null) {
      for (var e in del) {
        _map.remove(e);
        if (e is _EntryRef<K, V>) {
          _onRemoveEntry(e);
        }
      }
      _unpurgedCount = 0;
    }
  }

  @override
  bool containsKey(Object? key) {
    if (key == null || key is! K) return false;
    var k = _EntryKey<K, V>(key);
    // ignore: collection_methods_unrelated_type
    var e = _map[k];
    if (e == null) return false;

    var target = e.target;
    if (target == null) {
      _map.remove(e);
      _onRemoveEntry(e);
      ++_unpurgedCount;
      return false;
    }

    return true;
  }

  /// Returns `true` if [key] has an associated value.
  ///
  /// Same as [containsKey], but does NOT purge entries whose key or value
  /// has already been collected.
  bool containsKeyNoPurge(Object? key) {
    if (key == null || key is! K) return false;
    var k = _EntryKey<K, V>(key);
    // ignore: collection_methods_unrelated_type
    return _map.containsKey(k);
  }

  @override
  bool containsValue(Object? value) {
    List<_EntryRef<K, V>>? del;
    bool found = false;

    for (var k in _map.keys) {
      var target = k.target;
      if (target == null) {
        del ??= <_EntryRef<K, V>>[];
        del.add(k);
      } else {
        if (k.payload == value) {
          found = true;
          break;
        }
      }
    }

    if (del != null) {
      for (var e in del) {
        _map.remove(e);
        _onRemoveEntry(e);
      }
      _unpurgedCount = 0;
    }

    return found;
  }

  /// Returns `true` if any entry currently maps to [value].
  ///
  /// Same as [containsValue], but does NOT purge entries whose key or value
  /// has already been collected. It performs a direct scan and may therefore
  /// temporarily report `true` for stale keys.
  bool containsValueNoPurge(Object? value) {
    for (var k in _map.keys) {
      if (k.payload == value) {
        return true;
      }
    }
    return false;
  }

  @override
  V? remove(Object? key) {
    if (key == null || key is! K) return null;
    var k = _EntryKey<K, V>(key);
    // ignore: collection_methods_unrelated_type
    var e = _map.remove(k);
    if (e == null) return null;
    _onRemoveEntry(e);
    return e.payload;
  }

  @override
  void removeWhere(bool Function(K key, V value) test) {
    var del = <_EntryRef<K, V>>[];

    for (var k in _map.keys) {
      var target = k.target;
      if (target == null) {
        del.add(k);
      } else {
        var payload = k.payload;
        if (payload == null || test(target, payload)) {
          del.add(k);
        }
      }
    }

    for (var k in del) {
      _map.remove(k);
      _onRemoveEntry(k);
    }
  }
}

/// Iterable adapter for [WeakKeyMap].
class _WeakMapIterable<K extends Object, V extends Object, T>
    extends Iterable<T> {
  final WeakKeyMap<K, V> _map;
  final _IteratorMapper<K, V, T> _project;

  _WeakMapIterable(this._map, this._project);

  @override
  Iterator<T> get iterator => _WeakMapIterator<K, V, T>(_map, _project);
}

/// Maps a key-value pair into an iterator element.
typedef _IteratorMapper<K, V, T> = T Function(K key, V value);

/// Iterator that skips collected entries and cleans them up.
class _WeakMapIterator<K extends Object, V extends Object, T>
    implements Iterator<T> {
  final WeakKeyMap<K, V> _map;
  final _IteratorMapper<K, V, T> _iteratorMapper;
  final Iterator<_EntryRef<K, V>> _it;

  _WeakMapIterator(this._map, this._iteratorMapper)
      :
        // On `WeakKeyMap._map`, the keys are the same instance of values:
        _it = _map._map.keys.iterator;

  T? _current;

  @override
  T get current =>
      _current ??
      (throw StateError("No current element! Call `moveNext` before."));

  bool _done = false;

  @override
  bool moveNext() {
    if (_done) return false;

    while (_it.moveNext()) {
      final e = _it.current;
      final k = e.target;
      final v = e.payload;

      if (k != null && v != null) {
        _current = _iteratorMapper(k, v);
        return true;
      }

      _del ??= <_EntryRef<K, V>>[];
      _del!.add(e);
    }

    _done = true;
    _finalize();
    return false;
  }

  List<_EntryRef<K, V>>? _del;

  /// Removes collected entries after iteration completes.
  void _finalize() {
    final del = _del;
    if (del == null) return;

    _del = null;

    for (var e in del) {
      _map._map.remove(e);
      _map._onRemoveEntry(e);
    }

    _map._unpurgedCount = 0;
  }
}

/// A [Map] with both keys and values weakly referenced.
///
/// Unlike [Expando], this is a complete [Map] implementation, supporting the
/// full [Map] API, including iteration, removal, and entry views.
///
/// Entries are automatically removed when either the key or the value is
/// garbage-collected, keeping the map consistent without preventing GC.
///
/// This map also provides a lightweight swapped view via [swapped], allowing
/// values to be accessed as keys and keys as values without copying data.
class DualWeakMap<K extends Object, V extends Object> extends WeakKeyMap<K, V> {
  /// Secondary map for weakly-referenced values.
  final Map<_EntryRefValue<V, K>, _EntryRefValue<V, K>> _mapValues = {};

  DualWeakMap(
      {super.autoPurge, super.autoPurgeThreshold, super.onPurgedValues});

  @override
  _EntryRef<K, V> _createEntry(key, value) => _EntryRef2<K, V>(key, value);

  /// Returns the key associated with a given value, if still alive.
  K? getKeyFromValue(Object? value) {
    if (value == null || value is! V) return null;

    var v = _EntryKey<V, K>(value);
    // ignore: collection_methods_unrelated_type
    var valueEntry = _mapValues[v];
    if (valueEntry == null) return null;

    var eKey = valueEntry.payload;
    var eValue = valueEntry.target;

    if (eKey == null || eValue == null) {
      _map.remove(valueEntry.keyEntry);
      _mapValues.remove(valueEntry);
      ++_unpurgedCount;
      return null;
    }

    return eKey;
  }

  @override
  bool containsValue(Object? value) {
    if (value == null || value is! V) return false;

    var v = _EntryKey<V, K>(value);
    // ignore: collection_methods_unrelated_type
    var valueEntry = _mapValues[v];
    if (valueEntry == null) return false;

    var eKey = valueEntry.payload;
    var eValue = valueEntry.target;

    if (eKey == null || eValue == null) {
      _map.remove(valueEntry.keyEntry);
      _mapValues.remove(valueEntry);
      ++_unpurgedCount;
      return false;
    }

    return true;
  }

  @override
  bool containsValueNoPurge(Object? value) {
    if (value == null || value is! V) return false;

    var v = _EntryKey<V, K>(value);
    // ignore: collection_methods_unrelated_type
    var valueEntry = _mapValues[v];
    if (valueEntry == null) return false;

    var eValue = valueEntry.target;
    return eValue != null;
  }

  @override
  _onPutEntry(_EntryRef<K, V> e, V value) {
    var e2 = e as _EntryRef2<K, V>;
    _mapValues[e2._valueEntry] = e2._valueEntry;
  }

  @override
  _onRemoveEntry(_EntryRef<K, V> e) {
    var e2 = e as _EntryRef2<K, V>;
    _mapValues.remove(e2._valueEntry);
  }

  @override
  void clear() {
    super.clear();
    _mapValues.clear();
  }

  @override
  void _onPurgeValues(List<V> purgedValues) {
    _mapValues.removeWhere((key, value) {
      if (value.target == null) {
        _map.remove(value.keyEntry);
        return true;
      }
      return false;
    });
  }

  /// Returns a view with keys and values swapped.
  SwappedDualWeakMap<V, K> get swapped => SwappedDualWeakMap<V, K>(this);
}

/// A swapped view of a [DualWeakMap], exposing values as keys and keys as values.
///
/// This is a lightweight, live view backed by the original [DualWeakMap],
/// not a copy. All operations directly affect the underlying map.
///
/// Entries remain weakly referenced on both sides, and garbage collection
/// of either the original key or value is immediately reflected in this view.
class SwappedDualWeakMap<V extends Object, K extends Object>
    extends MapBase<V, K> {
  final DualWeakMap<K, V> _dualWeakMap;

  SwappedDualWeakMap(this._dualWeakMap);

  @override
  K? operator [](Object? value) => _dualWeakMap.getKeyFromValue(value);

  @override
  void operator []=(V key, K value) {
    // ignore: collection_methods_unrelated_type
    var prev = _dualWeakMap._mapValues[_EntryKey<V, K>(key)];
    if (prev != null) {
      // Only modify if different:
      if (prev.payload != value) {
        _dualWeakMap._mapValues.remove(prev);
        _dualWeakMap._map.remove(prev.keyEntry);
        _dualWeakMap.put(value, key);
      }
      return;
    }

    _dualWeakMap.put(value, key);
  }

  @override
  Iterable<V> get keys => _dualWeakMap.values;

  @override
  Iterable<K> get values => _dualWeakMap.keys;

  @override
  Iterable<MapEntry<V, K>> get entries => _dualWeakMap.entriesSwapped;

  @override
  K? remove(Object? key) {
    for (var e in _dualWeakMap.entries) {
      if (e.value == key) {
        _dualWeakMap.remove(e.key);
        return e.key;
      }
    }
    return null;
  }

  @override
  void clear() => _dualWeakMap.clear();
}
