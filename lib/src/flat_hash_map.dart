import 'dart:collection';
import 'dart:typed_data';

class FlatHashMap<K extends Object, V extends Object> extends MapBase<K, V> {
  static const int _maskRemoveNegativeSign = 0x7FFFFFFF;

  static int _groupIndex(int objHashcode, int totalGroups) {
    return (objHashcode & _maskRemoveNegativeSign) % totalGroups;
  }

  int _size = 0;

  List<K?> _chainKey = [];
  List<V?> _chainVal = [];

  int _chainLength = 0;
  Uint32List _chainHash = Uint32List(8);
  TypedDataList<int> _chainNext = _newUIntList(8, 8);

  int _chainRemoved = 0;

  Uint32List _groups;
  Uint32List _groupsSizes;

  FlatHashMap()
      : _groups = Uint32List(8),
        _groupsSizes = Uint32List(8) {
    _skipFirstChainPos();
  }

  int get capacity => _chainNext.length;

  int get capacityBits {
    if (_chainNext is Uint8List) {
      return 8;
    } else if (_chainNext is Uint16List) {
      return 16;
    } else if (_chainNext is Uint32List) {
      return 32;
    } else if (_chainNext is Uint64List) {
      return 64; // VM only
    }

    throw StateError('Unknown TypedDataList type: ${_chainNext.runtimeType}');
  }

  static TypedDataList<int> _newUIntList(int length, int maxN) {
    if (maxN <= 0xFF) {
      return Uint8List(length);
    } else if (maxN <= 0xFFFF) {
      return Uint16List(length);
    } else if (maxN <= 0xFFFFFFFF) {
      return Uint32List(length);
    } else {
      return Uint64List(length); // VM only
    }
  }

  Uint32List _expandUint32List(Uint32List l, int newCapacity) {
    final capacity = l.length;
    assert(newCapacity > capacity, "$newCapacity > $capacity");
    var l2 = Uint32List(newCapacity);
    l2.setRange(0, capacity, l);
    return l2;
  }

  TypedDataList<int> _expandUIntList(TypedDataList<int> l, int newCapacity) {
    var l2 = _newUIntList(newCapacity, newCapacity);
    l2.setRange(0, l.length, l);
    return l2;
  }

  void _addEntry(int groupPos, int objHash, K? key, V? value) {
    if (_chainLength >= _chainNext.length) {
      var newCapacity = _chainNext.length * 2;
      _chainHash = _expandUint32List(_chainHash, newCapacity);
      _chainNext = _expandUIntList(_chainNext, newCapacity);
    }

    _chainNext[_chainLength] = groupPos;
    _chainHash[_chainLength] = objHash;
    ++_chainLength;

    _chainKey.add(key);
    _chainVal.add(value);
  }

  void _skipFirstChainPos() {
    // index 0 is reserved as null/end
    _addEntry(0, 0, null, null);
  }

  int memory() {
    return (_chainKey.length * 64) +
        (_chainVal.length * 64) +
        (_chainHash.length * 64) +
        (_chainNext.length * 64);
  }

  @override
  int get length => _size;

  @override
  bool get isEmpty => _size == 0;

  @override
  bool containsKey(Object? key) {
    if (key == null) return false;

    final objHash = key.hashCode;
    final groupIdx = _groupIndex(objHash, _groups.length);

    var pos = _groups[groupIdx];
    while (pos > 0) {
      if (_chainHash[pos] == objHash && key == _chainKey[pos]) {
        return true;
      }
      pos = _chainNext[pos];
    }
    return false;
  }

  @override
  bool containsValue(Object? value) => _chainVal.contains(value);

  @override
  V? operator [](Object? key) => get(key);

  V? get(Object? key) {
    if (key == null) return null;

    final objHash = key.hashCode;
    final groupIdx = _groupIndex(objHash, _groups.length);

    var pos = _groups[groupIdx];
    while (pos > 0) {
      if (_chainHash[pos] == objHash && key == _chainKey[pos]) {
        return _chainVal[pos];
      }
      pos = _chainNext[pos];
    }
    return null;
  }

  @override
  void operator []=(K key, V value) {
    put(key, value);
  }

  V? put(K key, V value) {
    final objHash = key.hashCode;
    final groupIdx = _groupIndex(objHash, _groups.length);

    final groupPos = _groups[groupIdx];
    var cursor = groupPos;

    while (cursor > 0) {
      if (_chainHash[cursor] == objHash && key == _chainKey[cursor]) {
        final prev = _chainVal[cursor];
        _chainKey[cursor] = key;
        _chainVal[cursor] = value;
        return prev;
      }
      cursor = _chainNext[cursor];
    }

    int newPos;
    if (_chainRemoved > 0) {
      newPos = _chainRemoved;
      _chainRemoved = _chainNext[newPos];

      _chainNext[newPos] = groupPos;
      _chainHash[newPos] = objHash;
      _chainKey[newPos] = key;
      _chainVal[newPos] = value;
    } else {
      newPos = _chainLength;

      _addEntry(groupPos, objHash, key, value);
    }

    _groups[groupIdx] = newPos;
    _groupsSizes[groupIdx]++;
    _size++;

    _checkRehashNeeded();
    return null;
  }

  @override
  V? remove(Object? key) {
    if (key == null) return null;

    final objHash = key.hashCode;
    final groupIdx = _groupIndex(objHash, _groups.length);

    var prevPos = 0;
    var pos = _groups[groupIdx];

    while (pos > 0) {
      if (_chainHash[pos] == objHash && key == _chainKey[pos]) {
        _chainKey[pos] = null;
        final prev = _chainVal[pos];
        _chainVal[pos] = null;

        final next = _chainNext[pos];
        if (prevPos > 0) {
          _chainNext[prevPos] = next;
        } else {
          _groups[groupIdx] = next;
        }

        _groupsSizes[groupIdx]--;
        _size--;

        _chainNext[pos] = _chainRemoved;
        _chainRemoved = pos;

        return prev;
      }
      prevPos = pos;
      pos = _chainNext[pos];
    }
    return null;
  }

  void _checkRehashNeeded() {
    if (_size > _groups.length * 10) {
      _rehash(_groups.length * 2);
    }
  }

  void _rehash(int totalGroups) {
    if (_groups.length == totalGroups) return;

    final groups2 = Uint32List(totalGroups);
    final groupsSizes2 = Uint32List(totalGroups);

    final sz = _size + 1;
    for (var i = 1; i < sz; i++) {
      final key = _chainKey[i];
      if (key == null) continue;

      final objHash = key.hashCode;
      final groupIdx = _groupIndex(objHash, totalGroups);

      final prevPos = groups2[groupIdx];
      groups2[groupIdx] = i;
      groupsSizes2[groupIdx]++;
      _chainNext[i] = prevPos;
    }

    _groups = groups2;
    _groupsSizes = groupsSizes2;
  }

  @override
  void clear({bool full = false}) {
    _size = 0;

    if (full) {
      _chainKey = [];
      _chainVal = [];
      _chainHash = Uint32List(8);
      _chainNext = _newUIntList(8, 8);
    } else {
      _chainKey.clear();
      _chainVal.clear();
      _chainHash.fillRange(0, _chainLength, 0);
      _chainNext.fillRange(0, _chainLength, 0);
    }

    _chainLength = 0;

    _groups = Uint32List(8);
    _groupsSizes = Uint32List(8);
    _chainRemoved = 0;

    _skipFirstChainPos();
  }

  @override
  Iterable<K> get keys sync* {
    for (var i = 1; i < _chainKey.length; i++) {
      final k = _chainKey[i];
      if (k != null) yield k;
    }
  }

  @override
  Iterable<V> get values sync* {
    for (var i = 1; i < _chainVal.length; i++) {
      final v = _chainVal[i];
      if (v != null) yield v;
    }
  }

  @override
  Iterable<MapEntry<K, V>> get entries sync* {
    for (var i = 1; i < _chainKey.length; i++) {
      final k = _chainKey[i];
      final v = _chainVal[i];
      if (k != null && v != null) {
        yield MapEntry(k, v);
      }
    }
  }
}
