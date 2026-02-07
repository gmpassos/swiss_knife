import 'dart:collection';

abstract class _Entry<K extends Object, V extends Object> {
  final int _hashCode;

  _Entry(this._hashCode);

  K? get target;

  V? get payload;

  @override
  int get hashCode => _hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    final target = this.target;
    if (target == null) return false;

    if (other is _Entry) {
      final otherTarget = other.target;
      if (otherTarget == null) return false;
      if (identical(target, otherTarget)) return true;
      return target == otherTarget;
    } else {
      if (identical(target, other)) return true;
      return target == other;
    }
  }
}

class _EntryKey<K extends Object, V extends Object> extends _Entry<K, V> {
  final K _obj;

  _EntryKey(K key)
      : _obj = key,
        super(key.hashCode);

  @override
  K? get target => _obj;

  @override
  V get payload => throw UnsupportedError("No `payload` for `_KeyObj` class");
}

abstract class _EntryRef<K extends Object, V extends Object>
    extends _Entry<K, V> {
  final WeakReference<K> _refKey;

  _EntryRef(K key)
      : _refKey = WeakReference(key),
        super(key.hashCode);

  @override
  K? get target => _refKey.target;
}

class _EntryRef1<K extends Object, V extends Object> extends _EntryRef<K, V> {
  final V _value;

  _EntryRef1(super.key, V value) : _value = value;

  @override
  V get payload => _value;
}

class _EntryRef2<K extends Object, V extends Object> extends _EntryRef<K, V> {
  late final _EntryRefValue<V, K> _valueEntry;

  _EntryRef2(super.key, V value) {
    _valueEntry = _EntryRefValue<V, K>(this, value);
  }

  @override
  V? get payload => _valueEntry._refValue.target;
}

class _EntryRefValue<V extends Object, K extends Object> extends _Entry<V, K> {
  final _EntryRef2<K, V> _keyEntry;

  final WeakReference<V> _refValue;

  _EntryRefValue(this._keyEntry, V value)
      : _refValue = WeakReference(value),
        super(value.hashCode);

  _EntryRef2<K, V> get keyEntry => _keyEntry;

  @override
  V? get target => _refValue.target;

  @override
  K? get payload => _keyEntry._refKey.target;
}

/// A [Map] with weakly-referenced keys.
class WeakKeyMap<K extends Object, V extends Object> extends MapBase<K, V> {
  final Map<_EntryRef<K, V>, _EntryRef<K, V>> _map = {};

  final bool _autoPurge;

  final int _autoPurgeThreshold;

  static const defaultAutoPurgeThreshold = 100;

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

  int get autoPurgeThreshold => _autoPurgeThreshold;

  @override
  V? operator [](Object? key) => get(key);

  @override
  void operator []=(K key, V value) => put(key, value);

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

  void _onRemoveEntry(_EntryRef<K, V> e) {}

  void put(K key, V value) {
    var keyEntry = _createEntry(key, value);
    _map[keyEntry] = keyEntry;
    _onPutEntry(keyEntry, value);
    ++_unpurgedCount;
  }

  _EntryRef<K, V> _createEntry(key, value) => _EntryRef1<K, V>(key, value);

  void _onPutEntry(_EntryRef<K, V> e, V value) {}

  @override
  void clear() {
    _map.clear();
    _unpurgedCount = 0;
  }

  int _unpurgedCount = 0;

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

  void _onPurgeValues(List<V> purgedValues) {}

  bool get isAutoPurgeEnabled => _autoPurge;

  bool autoPurge() {
    if (_autoPurge && isAutoPurgeRequired()) {
      purge();
      return true;
    }
    return false;
  }

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

  Iterable<MapEntry<V, K>> get entriesSwapped =>
      _WeakMapIterable<K, V, MapEntry<V, K>>(this, (k, v) => MapEntry(v, k));

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

class _WeakMapIterable<K extends Object, V extends Object, T>
    extends Iterable<T> {
  final WeakKeyMap<K, V> _map;
  final _IteratorMapper<K, V, T> _project;

  _WeakMapIterable(this._map, this._project);

  @override
  Iterator<T> get iterator => _WeakMapIterator<K, V, T>(_map, _project);
}

typedef _IteratorMapper<K, V, T> = T Function(K key, V value);

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

/// A [Map] with weakly-referenced keys and values.
class DualWeakMap<K extends Object, V extends Object> extends WeakKeyMap<K, V> {
  final Map<_EntryRefValue<V, K>, _EntryRefValue<V, K>> _mapValues = {};

  DualWeakMap(
      {super.autoPurge, super.autoPurgeThreshold, super.onPurgedValues});

  @override
  _EntryRef<K, V> _createEntry(key, value) => _EntryRef2<K, V>(key, value);

  K? _getKeyFromValue(Object? value) {
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

  SwappedDualWeakMap<V, K> get swapped => SwappedDualWeakMap<V, K>(this);
}

/// A view of [DualWeakMap] with keys and values swapped.
class SwappedDualWeakMap<V extends Object, K extends Object>
    extends MapBase<V, K> {
  final DualWeakMap<K, V> _dualWeakMap;

  SwappedDualWeakMap(this._dualWeakMap);

  @override
  K? operator [](Object? value) => _dualWeakMap._getKeyFromValue(value);

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
