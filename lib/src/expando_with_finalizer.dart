/// Small wrapper used as the Expando payload.
class _ExpandoBox<V> {
  final V value;

  _ExpandoBox(this.value);
}

/// Callback executed with the associated value when the key becomes
/// unreachable and is garbage-collected.
typedef ExpandoFinalizer<V> = void Function(V value);

/// A weak key → strong value association similar to [Expando], but with a
/// finalization callback.
///
/// When a [key] becomes unreachable and is garbage-collected, the provided
/// [onFinalize] ([ExpandoFinalizer]) is invoked with the last associated value.
///
/// The value remains alive while associated with the key. Replacing or removing
/// the value cancels the pending finalization for the previous association.
///
/// Typical use cases:
/// - Cleaning native resources tied to Dart objects
/// - Cache entries that must release external handles
/// - Lifecycle hooks without modifying the key class
class ExpandoWithFinalizer<K extends Object, V extends Object> {
  /// Native Expando that weakly associates data to a key (does not prevent GC).
  final Expando<_ExpandoBox<V>> _expando = Expando<_ExpandoBox<V>>();

  /// User-provided finalization callback.
  final ExpandoFinalizer<V> onFinalize;

  ExpandoWithFinalizer(this.onFinalize);

  /// Finalizer triggered when the associated key is garbage-collected.
  /// It receives the attached token (_ExpandoBox) so the stored value
  /// can be forwarded to the user callback.
  late final Finalizer<_ExpandoBox> _finalizer =
      Finalizer<_ExpandoBox>(_onFinalize);

  // Internal bridge: unwrap the stored value and notify user code.
  void _onFinalize(_ExpandoBox box) {
    onFinalize(box.value);
  }

  /// Associates [value] with [key], replacing any previous value.
  /// Cancels the previous finalization and attaches a new one.
  /// When the key is GC-collected, [onFinalize] is called with the [value].
  void put(K key, V value) {
    final prevBox = _expando[key];
    if (prevBox != null) {
      if (identical(prevBox.value, value)) {
        // Same object already associated → avoid detach/attach churn.
        return;
      }

      // Cancel pending finalization for the previous value because the
      // association is being replaced.
      _finalizer.detach(prevBox);
    }

    final box = _ExpandoBox<V>(value);

    // Weakly associate value with the key.
    _expando[key] = box;

    // Attach finalization to the key lifecycle.
    // When key is GC-collected, `_onFinalize(box)` will be invoked.
    // `detach: box` allows later manual cancellation via detach(box).
    _finalizer.attach(key, box, detach: box);
  }

  /// Returns associated value if the [key] is still alive.
  V? get(K key) => _expando[key]?.value;

  /// Returns whether a value is currently associated with [key].
  bool containsKey(K key) => _expando[key] != null;

  /// Removes and returns the value associated with [key], if any.
  /// Cancels the pending finalization for that association.
  V? remove(K key) {
    final box = _expando[key];
    if (box != null) {
      // Manual removal: prevent the finalizer from firing later.
      _finalizer.detach(box);
      _expando[key] = null;
      return box.value;
    }
    return null;
  }

  /// Returns the value associated with [key]. See [get].
  V? operator [](K key) => get(key);

  /// Associates [value] with [key]. See [put].
  void operator []=(K key, V value) => put(key, value);
}
