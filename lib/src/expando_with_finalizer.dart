/// A strongly typed wrapper used as a finalization token.
///
/// Implementations encapsulate a non-null [value] that will be delivered
/// to user code when the associated key becomes unreachable and is
/// garbage-collected.
///
/// This indirection allows attaching structured metadata to a
/// [Finalizer] while keeping the actual value strongly typed.
abstract class FinalizerValueWrapper<V extends Object> {
  /// The wrapped value associated with the finalizer.
  ///
  /// Must always return a non-null instance.
  V get value;
}

/// Simple concrete implementation of [FinalizerValueWrapper].
///
/// Holds a strong reference to [value] to be delivered on finalization.
class SimpleFinalizerWrapper<V extends Object>
    extends FinalizerValueWrapper<V> {
  @override
  final V value;

  SimpleFinalizerWrapper(this.value);
}

/// Debug variant of [SimpleFinalizerWrapper].
///
/// In addition to the wrapped value, it keeps a weak reference to the
/// associated [key] for inspection. The key is stored in [_key] as a
/// [WeakReference], so it does not prevent garbage collection.
///
/// Intended for memory leak analysis and lifecycle debugging.
class SimpleFinalizerWrapperDebug<K extends Object, V extends Object>
    extends SimpleFinalizerWrapper<V> {
  /// Weak reference to the associated key (debug only).
  final WeakReference<K> _key;

  K? get key => _key.target;

  SimpleFinalizerWrapperDebug(K key, super.value) : _key = WeakReference(key);
}

/// Signature for a callback invoked when a key associated with a
/// finalizer becomes unreachable.
///
/// The provided [value] corresponds to the value previously associated
/// with the collected key.
typedef FinalizerCallback<V> = void Function(V value);

/// Base class for managing key → value associations backed by a [Finalizer].
///
/// A value is weakly associated with a key. When the key becomes
/// unreachable and is garbage-collected, the provided [onFinalize]
/// callback is invoked with the associated value.
///
/// Implementations are responsible for:
/// - Storing and retrieving wrappers via [createWrapper] and [getWrapper].
/// - Maintaining any required internal key → wrapper mapping.
///
/// The finalizer is automatically attached and detached as associations
/// are added, replaced, or manually removed.
abstract class WithFinalizer<K extends Object, V extends Object,
    W extends FinalizerValueWrapper<V>> {
  /// User-provided callback invoked when a key is garbage-collected.
  final FinalizerCallback<V> onFinalize;

  WithFinalizer(this.onFinalize);

  /// Internal [Finalizer] responsible for tracking key reachability.
  ///
  /// When a key is collected, `_onFinalize` receives the associated
  /// wrapper token.
  late final Finalizer<W> _finalizer = Finalizer<W>(_onFinalize);

  /// Internal bridge between the Dart [Finalizer] and user code.
  ///
  /// Extracts the wrapped value and forwards it to [onFinalize].
  /// Any exception thrown by user code is routed to [onFinalizeError].
  void _onFinalize(W wrapper) {
    try {
      onFinalize(wrapper.value);
    } catch (error, stackTrace) {
      onFinalizeError(error, stackTrace);
    }
  }

  /// Called when [onFinalize] throws.
  ///
  /// Default implementation is a no-op. Subclasses may override to log
  /// or report errors.
  void onFinalizeError(Object error, StackTrace stackTrace) {}

  /// Associates [value] with [key], replacing any existing association.
  ///
  /// If a wrapper is already associated with [key]:
  /// - If its value is `identical` to [value], nothing is changed.
  /// - Otherwise, the previous finalization is detached before
  ///   attaching the new association.
  ///
  /// When [key] becomes unreachable and is garbage-collected,
  /// [onFinalize] is invoked with the associated [value].
  void put(K key, V value) {
    final previousWrapper = getWrapper(key);

    if (previousWrapper != null) {
      if (identical(previousWrapper.value, value)) {
        // Avoid unnecessary detach/attach when nothing changed.
        return;
      }

      // Cancel pending finalization for the previous association.
      _finalizer.detach(previousWrapper);
    }

    final wrapper = createWrapper(key, value);

    // Attach finalization to the key lifecycle.
    //
    // When [key] is garbage-collected, `_onFinalize(wrapper)` will run.
    // The wrapper itself is used as the detach token, allowing explicit
    // cancellation via `_finalizer.detach(wrapper)`.
    _finalizer.attach(key, wrapper, detach: wrapper);
  }

  /// Creates a wrapper for the given [key] and [value].
  ///
  /// Implementations typically store the wrapper in an internal
  /// key → wrapper structure before returning it.
  W createWrapper(K key, V value);

  /// Returns the wrapper currently associated with [key], or `null`
  /// if no association exists.
  W? getWrapper(K key);

  /// Removes the association for [key], if present.
  ///
  /// Detaches the wrapper from the internal [Finalizer] to prevent
  /// the callback from firing in the future.
  ///
  /// Returns the previously associated value, or `null` if none existed.
  V? remove(K key) {
    final wrapper = getWrapper(key);
    if (wrapper != null) {
      _finalizer.detach(wrapper);
      return wrapper.value;
    }
    return null;
  }
}

/// A write-only [WithFinalizer] implementation.
///
/// Associates values with keys solely for finalization purposes.
/// This class does **not** store, expose, or allow removal of
/// key–value associations.
///
/// When a [key] becomes unreachable and is garbage-collected,
/// the provided [onFinalize] callback is invoked with the
/// associated value.
///
/// Any attempt to retrieve or manually remove an association
/// results in [UnsupportedError].
class AttachOnlyFinalizer<K extends Object, V extends Object>
    extends WithFinalizer<K, V, SimpleFinalizerWrapper<V>> {
  /// Enables debug mode.
  ///
  /// When `true`, created wrappers retain a weak reference to the
  /// associated key, allowing inspection for memory leak analysis.
  /// When `false`, a minimal wrapper is used.
  final bool debug;

  /// Creates an attach-only finalizer.
  ///
  /// The [onFinalize] callback is invoked when a key becomes
  /// unreachable and is garbage-collected.
  ///
  /// If [debug] is enabled, debug wrappers are created to allow
  /// key inspection during lifecycle analysis.
  AttachOnlyFinalizer(super.onFinalize, {this.debug = false});

  @override
  SimpleFinalizerWrapper<V> createWrapper(K key, V value) => debug
      ? SimpleFinalizerWrapperDebug(key, value)
      : SimpleFinalizerWrapper(value);

  @override
  SimpleFinalizerWrapper<V>? getWrapper(K key) => null;

  @override
  Never remove(K key) => throw UnsupportedError("Can't remove keys!");
}

/// Concrete [FinalizerValueWrapper] used by [ExpandoWithFinalizer].
///
/// Stores a strongly referenced [value] delivered to the finalizer callback.
class ExpandoValueWrapper<V extends Object> extends FinalizerValueWrapper<V> {
  @override
  final V value;

  ExpandoValueWrapper(this.value);
}

/// Debug variant of [ExpandoValueWrapper].
///
/// Stores a weak reference to the associated `key` in the [_key] field
/// for inspection, without preventing it from being garbage-collected.
///
/// Useful for memory leak inspection and tracking unexpected
/// object retention.
class ExpandoValueWrapperDebug<K extends Object, V extends Object>
    extends ExpandoValueWrapper<V> {
  /// Weak reference to the associated key (debug only).
  final WeakReference<K> _key;

  K? get key => _key.target;

  ExpandoValueWrapperDebug(K key, super.value) : _key = WeakReference(key);
}

/// A weak key → strong value association similar to [Expando], but with a
/// finalization callback.
///
/// When a [key] becomes unreachable and is garbage-collected, the provided
/// [onFinalize] ([FinalizerCallback]) is invoked with the last associated value.
///
/// The value remains alive while associated with the key. Replacing or removing
/// the value cancels the pending finalization for the previous association.
///
/// Typical use cases:
/// - Cleaning native resources tied to Dart objects
/// - Cache entries that must release external handles
/// - Lifecycle hooks without modifying the key class
class ExpandoWithFinalizer<K extends Object, V extends Object>
    extends WithFinalizer<K, V, ExpandoValueWrapper<V>> {
  /// Native Expando that weakly associates data to a key (does not prevent GC).
  final Expando<ExpandoValueWrapper<V>> _expando =
      Expando<ExpandoValueWrapper<V>>();

  /// Enables debug mode.
  ///
  /// When `true`, wrappers retain an additional weak reference to the
  /// associated key, allowing inspection for memory leak analysis.
  /// When `false`, a lighter wrapper is used.
  final bool debug;

  /// Creates an [ExpandoWithFinalizer].
  ///
  /// If [debug] is enabled, a debug wrapper is used to allow
  /// key inspection during memory analysis.
  ExpandoWithFinalizer(super.onFinalize, {this.debug = false});

  /// Creates and stores a wrapper for the given [key] and [value].
  ///
  /// The wrapper type depends on [debug]:
  /// - `false`: uses [ExpandoValueWrapper].
  /// - `true`: uses [ExpandoValueWrapperDebug] (keeps a weak reference to [key]).
  ///
  /// The wrapper is weakly associated with [key] via the internal [Expando].
  @override
  ExpandoValueWrapper<V> createWrapper(K key, V value) {
    final wrapper = debug
        ? ExpandoValueWrapperDebug<K, V>(key, value)
        : ExpandoValueWrapper<V>(value);
    // Weakly associate value with the key.
    _expando[key] = wrapper;
    return wrapper;
  }

  /// Returns the wrapper associated with [key], if any.
  ///
  /// The association is stored internally using an [Expando],
  /// so it does not prevent [key] from being garbage-collected.
  @override
  ExpandoValueWrapper<V>? getWrapper(K key) => _expando[key];

  /// Returns associated value if the [key] is still alive.
  V? get(K key) => _expando[key]?.value;

  /// Returns whether a value is currently associated with [key].
  bool containsKey(K key) => _expando[key] != null;

  @override
  V? remove(K key) {
    var value = super.remove(key);
    if (value != null) {
      _expando[key] = null;
      return value;
    }
    return null;
  }

  /// Returns the value associated with [key]. See [get].
  V? operator [](K key) => get(key);

  /// Associates [value] with [key]. See [put].
  void operator []=(K key, V value) => put(key, value);
}
