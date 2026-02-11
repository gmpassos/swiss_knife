import 'dart:collection';
import 'dart:typed_data';

/// A compact hash map optimized for low allocation and cache-friendly access.
///
/// Uses flat arrays plus per-bucket chained indices instead of object nodes.
/// Collisions are handled via singly-linked chains stored in index arrays.
///
/// Design highlights:
/// - Integer indices instead of object references
/// - Reusable removed slots (free-list)
/// - Adaptive integer width for chain pointers (8/16/32/64 bits)
/// - Rehashing based on load per bucket
///
/// Index `0` is reserved as a null/end sentinel.
class FlatHashMap<K extends Object, V extends Object> extends MapBase<K, V> {
  /// Mask used to normalize hash codes to positive values.
  static const int _maskRemoveNegativeSign = 0x7FFFFFFF;

  /// Computes the bucket index for a hash code.
  static int _groupIndex(int objHashcode, int totalGroups) {
    return (objHashcode & _maskRemoveNegativeSign) % totalGroups;
  }

  /// Number of live key-value pairs.
  int _size = 0;

  /// Parallel arrays storing keys and values.
  ///
  /// Index `0` is unused and reserved.
  List<K?> _chainKey = [];
  List<V?> _chainVal = [];

  /// Number of allocated chain entries (including removed ones).
  int _chainLength = 0;

  /// Cached hash codes per chain entry.
  Uint32List _chainHash = Uint32List(8);

  /// Next pointer for collision chains or free-list.
  /// Uses the smallest possible unsigned integer width.
  TypedDataList<int> _chainNext = _newUIntList(8, 8);

  /// Head of the free-list of removed entries.
  int _chainRemoved = 0;

  /// Per-bucket head indices.
  Uint32List _groups;

  /// Creates an empty map with an initial bucket count of 8.
  Uint32List _groupsSizes;

  FlatHashMap()
      : _groups = Uint32List(8),
        _groupsSizes = Uint32List(8) {
    _skipFirstChainPos();
  }

  /// Current chain storage capacity.
  int get capacity => _chainNext.length;

  /// Bit-width used by the chain pointer storage.
  /// Useful to inspect internal memory optimization.
  int get capacityBits {
    final chainNext = _chainNext;

    if (chainNext is Uint8List) {
      return 8;
    } else if (chainNext is Uint16List) {
      return 16;
    } else if (chainNext is Uint32List) {
      return 32;
    } else if (chainNext is Uint64List) {
      return 64; // VM only
    }

    throw StateError('Unknown TypedDataList type: ${chainNext.runtimeType}');
  }

  /// Allocates an unsigned integer list with minimal width for [maxN].
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

  /// Expands an unsigned integer list, adapting its width if needed.
  TypedDataList<int> _expandUIntList(TypedDataList<int> l, int newCapacity) {
    var l2 = _newUIntList(newCapacity, newCapacity);
    l2.setRange(0, l.length, l);
    return l2;
  }

  /// Expands a [Uint32List] preserving existing content.
  Uint32List _expandUint32List(Uint32List l, int newCapacity) {
    final capacity = l.length;
    assert(newCapacity > capacity, "$newCapacity > $capacity");
    var l2 = Uint32List(newCapacity);
    l2.setRange(0, capacity, l);
    return l2;
  }

  /// Appends a new chain entry pointing to [groupPos].
  /// Automatically grows internal storage if needed.
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

  /// Reserves index `0` as a null/end sentinel.
  void _skipFirstChainPos() {
    _addEntry(0, 0, null, null);
  }

  /// Estimates internal memory usage in bytes.
  ///
  /// [objectReferenceBytes] is the assumed size (in bytes) of a single object
  /// reference (typically 8 bytes on 64-bit runtimes).
  ///
  /// The estimate includes all core internal buffers and scalar fields, but
  /// excludes VM object headers, alignment, and allocator overhead.
  /// Intended for diagnostics and relative comparisons only.
  int memory({int objectReferenceBytes = 8}) {
    final capacityBytes = capacityBits ~/ 8;
    return
        // key/value references
        objectReferenceBytes +
            (_chainKey.length * objectReferenceBytes) +
            objectReferenceBytes +
            (_chainVal.length * objectReferenceBytes) +
            // stored hash codes (Uint32)
            objectReferenceBytes +
            (_chainHash.length * 4) +
            // chain pointers (adaptive width)
            objectReferenceBytes +
            (_chainNext.length * capacityBytes) +
            // bucket heads and bucket sizes (Uint32)
            objectReferenceBytes +
            (_groups.length * 4) +
            objectReferenceBytes +
            (_groupsSizes.length * 4) +
            // scalar fields (ints):
            // _size, _chainLength, _chainRemoved
            (3 * 8);
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

  /// Returns the value associated with [key], or `null` if not present.
  ///
  /// - A `null` key is not supported and always returns `null`.
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

  /// Inserts or replaces a key-value pair.
  /// Returns the previous value if the key already existed.
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

  /// Checks whether a resize and rehash is required.
  ///
  /// Uses a conservative threshold of ~10 entries per bucket.
  void _checkRehashNeeded() {
    if (_size > _groups.length * 10) {
      _rehash(_groups.length * 2);
    }
  }

  /// Rebuilds all bucket chains for a new bucket count.
  ///
  /// Chain storage is preserved; only bucket heads are rebuilt.
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

  /// Clears the map.
  ///
  /// If [full] is true, internal storage is fully reallocated.
  /// Otherwise, buffers are reused to minimize allocations.
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

  /// Iterates keys in insertion order minus removed entries.
  @override
  Iterable<K> get keys sync* {
    for (var i = 1; i < _chainKey.length; i++) {
      final k = _chainKey[i];
      if (k != null) yield k;
    }
  }

  /// Iterates values in insertion order minus removed entries.
  @override
  Iterable<V> get values sync* {
    for (var i = 1; i < _chainVal.length; i++) {
      final v = _chainVal[i];
      if (v != null) yield v;
    }
  }

  /// Iterates entries in insertion order minus removed entries.
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
