import 'dart:collection';

/// A reference that starts **strong** and automatically degrades to **weak**
/// after a period (See [LazyWeakReferenceManager.weakenDelay]).
///
/// This is useful for caches:
/// - Recently accessed objects remain strongly reachable (cannot be GC'ed)
/// - Old objects become weak and can be garbage-collected
///
/// The reference lifecycle:
///   strong  →  weak  →  lost/disposed
///
/// ⚡ Performance note:
/// This design avoids the immediate cost of creating a [WeakReference]
/// and accessing its [WeakReference.target] on every use.
/// Instances start as purely strong references, making creation and access
/// lightweight. The weak reference is created lazily and only when needed,
/// delaying the overhead of weak-reference allocation and GC tracking.
///
/// The transition from strong → weak is controlled by
/// [LazyWeakReferenceManager].
final class LazyWeakReference<T extends Object> {
  /// Owning manager responsible for scheduling lifecycle transitions.
  ///
  /// It controls when this reference moves from strong → weak according to
  /// the configured weaken delay. When null, the reference is considered
  /// disposed and no further management occurs.
  LazyWeakReferenceManager<T>? _manager;

  /// Strong reference keeps the object alive.
  T? _strongRef;

  /// Whether this reference is currently enqueued in the [manager]’s
  /// strong-reference queue.
  ///
  /// Used internally to prevent duplicate registrations while the
  /// reference awaits automatic weakening.
  bool _queued = false;

  /// Whether this reference is currently enqueued in the [manager]’s
  /// strong-reference queue.
  bool get isQueued => _queued;

  /// Weak reference allows GC.
  WeakReference<T>? _weakRef;

  /// Unix timestamp (milliseconds) of creation or of the most recent
  /// transition to a strong reference.
  ///
  /// Used by the [manager] to determine when this reference should be
  /// weakened.
  int _unixTimeMs;

  /// Creates a strong reference.
  LazyWeakReference._strong(this._manager, T target, this._unixTimeMs)
      : _strongRef = target,
        _weakRef = null;

  /// Creates a weak reference.
  LazyWeakReference._weak(this._manager, T target, this._unixTimeMs)
      : _strongRef = null,
        _weakRef = WeakReference(target);

  /// Returns the object if still reachable.
  ///
  /// - Prefers strong reference
  /// - Falls back to weak reference
  T? get target {
    var strongRef = _strongRef;
    if (strongRef != null) {
      return strongRef;
    } else {
      return _weakRef?.target;
    }
  }

  /// Returns the object only if currently held strongly.
  ///
  /// Does not access [WeakReference.target].
  /// Returns `null` if weak, lost, or disposed.
  ///
  /// See [target].
  T? get targetIfStrong {
    var strongRef = _strongRef;
    if (strongRef != null) {
      return strongRef;
    }
    return null;
  }

  /// Whether this currently holds a strong reference.
  bool get isStrong => _strongRef != null;

  /// Promotes this reference to **strong**.
  ///
  /// If the object still exists:
  /// - It becomes strongly reachable again
  /// - Timestamp is refreshed
  /// - Manager schedules future weakening
  ///
  /// If already collected:
  /// - Weak reference is cleared
  /// - Returns null
  ///
  /// [keepWeakRef] keeps the weak handle alongside the strong one.
  T? strong({bool keepWeakRef = true}) {
    var ref = _strongRef;
    if (ref != null) {
      // Already a strong reference:
      assert(_queued);
      final manager = _manager;
      if (manager != null) {
        _unixTimeMs = manager.unixTimeMs;
        manager._handleAccessStrongRef(this);
        assert(_queued);
      }
      return ref;
    }

    _strongRef = ref = _weakRef?.target;

    if (ref == null) {
      // Lost reference, not reachable either strongly or weakly:
      _weakRef = null;
    } else {
      if (!keepWeakRef) {
        // Dispose weak reference, but still reachable through `_strongRef`:
        _weakRef = null;
      }

      // Weak ref state, not queued:
      assert(!_queued);

      // New strong reference, handle it:
      final manager = _manager;
      if (manager != null) {
        _unixTimeMs = manager.unixTimeMs;
        manager._handleNewStrongRef(this);
        assert(_queued);
      }
    }

    return ref;
  }

  /// Whether this reference is marked as weak (not strong). See [isStrong].
  ///
  /// NOTE: This does NOT verify if the target is still reachable (see [isAlive]).
  /// It only checks that no strong reference exists and a weak reference
  /// object is present. The referenced object may already have been
  /// garbage-collected.
  bool get isWeak => _strongRef == null && _weakRef != null;

  /// Converts this reference into a **weak** reference.
  ///
  /// If currently strong:
  /// - Releases the strong reference
  /// - Creates a [WeakReference] if one does not already exist
  /// - Notifies the manager that this reference is no longer strong
  /// - Returns the target object
  ///
  /// If already weak:
  /// - No state change occurs
  /// - If [checkWeakRefTarget] is `true` (default), reads
  ///   `WeakReference.target` and returns the object if still reachable
  /// - If the object was already collected, clears the weak reference
  ///   and returns `null`
  /// - If [checkWeakRefTarget] is `false`, does not access the weak
  ///   reference and returns `null`
  T? weak({bool checkWeakRefTarget = true}) {
    var ref = _strongRef;
    if (ref != null) {
      _strongRef = null;
      // If a weak reference already exists, it points to `ref`
      // since the strong reference keeps it alive.
      // Only create it if missing:
      _weakRef ??= WeakReference(ref);

      // New weak reference, handle it:
      _manager?._handleNewWeakRef(this);
      assert(!_queued);
      return ref;
    }

    // Avoid checking `_weakRef.target`:
    if (!checkWeakRefTarget) {
      return null;
    }

    ref = _weakRef?.target;
    if (ref == null) {
      // Lost reference, not reachable either strongly or weakly:
      _weakRef = null;
    }

    return ref;
  }

  /// Whether the object is still reachable.
  bool get isAlive => _strongRef != null || _weakRef?.target != null;

  /// True if GC has collected the object.
  bool get isLost => !isAlive;

  /// Current manager.
  LazyWeakReferenceManager<T>? get manager => _manager;

  /// Weakens or disposes if target no longer exists.
  void _weakOrDispose() {
    weak(checkWeakRefTarget: false);
    if (_strongRef == null && _weakRef == null) {
      dispose();
    }
  }

  /// True after manual or automatic disposal.
  bool get isDisposed => _manager == null;

  /// Permanently releases all references.
  void dispose() {
    var manager = _manager;
    if (manager == null) return;

    manager._handleDisposedRef(this);
    assert(!_queued);

    _manager = null;
    _strongRef = null;
    _weakRef = null;
  }

  /// Returns the elapsed time (in milliseconds) since creation or since the
  /// most recent transition to a strong reference.
  int elapsedMs(int nowUnixTime) => nowUnixTime - _unixTimeMs;

  @override
  String toString() => 'LazyWeakReference{'
      'isStrong: $isStrong, '
      'isWeak: $isWeak, '
      'isDisposed: $isDisposed, '
      'queued: $isQueued, '
      'unixTimeMs: $_unixTimeMs'
      '}@$target';
}

/// Controls automatic weakening of strong references held by
/// [LazyWeakReference] instances.
///
/// The manager temporarily keeps objects strongly reachable and
/// later downgrades them to weak references after a configurable delay.
/// This effectively behaves like a time-based generational cache,
/// preserving recently used objects while allowing older ones to be
/// garbage-collected.
class LazyWeakReferenceManager<T extends Object> {
  /// Time before a strong reference becomes weak. Default: 1 sec
  final Duration weakenDelay;

  /// Maximum references processed per batch. Default: 100
  final int batchLimit;

  /// Delay between batch processing. Default: 1 ms
  ///
  /// Helps prevent long processing from blocking I/O, events, or UI updates
  /// by yielding time back to the event loop between batches.
  final Duration batchInterval;

  static const defaultWeakenDelay = Duration(seconds: 1);
  static const defaultBatchLimit = 100;
  static const defaultBatchInterval = Duration(milliseconds: 1);

  LazyWeakReferenceManager(
      {Duration weakenDelay = defaultWeakenDelay,
      int batchLimit = defaultBatchLimit,
      Duration batchInterval = defaultBatchInterval})
      : weakenDelay =
            weakenDelay.inMilliseconds > 1 ? weakenDelay : defaultWeakenDelay,
        batchLimit = batchLimit > 1 ? batchLimit : 1,
        batchInterval = batchInterval.inMilliseconds > 1
            ? batchInterval
            : defaultBatchInterval;

  /// Creates a managed strong reference.
  LazyWeakReference<T> strong(T target) {
    var ref = LazyWeakReference<T>._strong(this, target, unixTimeMs);
    _handleNewStrongRef(ref);
    return ref;
  }

  /// Creates a managed weak reference.
  LazyWeakReference<T> weak(T target) {
    var ref = LazyWeakReference<T>._weak(this, target, unixTimeMs);
    _handleNewWeakRef(ref);
    return ref;
  }

  /// Current unix time in milliseconds.
  int get unixTimeMs => DateTime.now().millisecondsSinceEpoch;

  /// Queue of strong references waiting to weaken.
  final Queue<LazyWeakReference<T>> _strongRegs = Queue();

  /// Registers a strong reference for future weakening.
  void _handleNewStrongRef(LazyWeakReference<T> ref) {
    assert(!ref._queued);
    assert(!_strongRegs.contains(ref));

    _strongRegs.addLast(ref);
    ref._queued = true;

    _scheduleWeakenStrongRefs(weakenDelay);
  }

  /// Registers a strong reference for future weakening.
  void _handleAccessStrongRef(LazyWeakReference<T> ref) {
    assert(ref._queued);
    assert(_strongRegs.contains(ref));
    _strongRegs.remove(ref);
    _strongRegs.addLast(ref);
    _scheduleWeakenStrongRefs(weakenDelay);
  }

  /// Called when a reference transitions to weak state.
  ///
  /// If the reference was previously strong, it is removed from the
  /// pending strong-weakening queue to avoid redundant processing.
  void _handleNewWeakRef(LazyWeakReference<T> ref) {
    if (ref._queued) {
      _strongRegs.remove(ref);
      ref._queued = false;
    }
  }

  /// Called when a reference is permanently disposed.
  ///
  /// Ensures the reference is no longer tracked by the manager and will not
  /// participate in future weakening cycles. If the reference was waiting in
  /// the strong-reference queue, it is removed to prevent unnecessary work
  /// and to avoid holding stale entries.
  void _handleDisposedRef(LazyWeakReference<T> ref) {
    if (ref._queued) {
      _strongRegs.remove(ref);
      ref._queued = false;
    }
  }

  Future<void>? _scheduledWeakenStrongRefs;

  /// Schedules the weaken process (debounced).
  void _scheduleWeakenStrongRefs(Duration delay, {bool force = false}) {
    var scheduled = _scheduledWeakenStrongRefs;
    if (scheduled != null && !force) return;

    _scheduledWeakenStrongRefs =
        scheduled = Future.delayed(delay, _weakenStrongRefs);

    scheduled.whenComplete(() {
      if (identical(scheduled, _scheduledWeakenStrongRefs)) {
        _scheduledWeakenStrongRefs = null;
      }
    });
  }

  /// Weakens references in batches to avoid UI jank / event-loop blocking.
  void _weakenStrongRefs() {
    // Current unix time in milliseconds:
    final unixTimeMs = this.unixTimeMs;
    // Minimum time a reference must stay strong before it becomes eligible:
    final weakenDelay = this.weakenDelay.inMilliseconds;
    // Maximum number of references processed in a single run:
    final batchLimit = this.batchLimit;

    final strongRegs = _strongRegs;

    // If we encounter a not-yet-eligible entry, we compute how long to wait.
    int? untilWeakenMs;
    // Number of references processed in this batch.
    var count = 0;

    // Process only a limited amount to avoid long blocking work:
    while (strongRegs.isNotEmpty && count < batchLimit) {
      // Oldest strong reference.
      var ref = strongRegs.first;

      // How long this reference has been strong.
      var elapsedTimeMs = ref.elapsedMs(unixTimeMs);

      // Eligible → weaken (or dispose) immediately.
      if (elapsedTimeMs >= weakenDelay) {
        // Remove from strong queue and weaken the reference:
        strongRegs.removeFirst();
        ref._queued = false;

        ref._weakOrDispose();
        ++count;
      } else {
        // Not ready yet: compute remaining wait time and stop batch.
        // Queue is time-ordered, so the rest are also not ready.
        untilWeakenMs = weakenDelay - elapsedTimeMs;
        break;
      }
    }

    // If more items exist, schedule the next processing slice.
    if (strongRegs.isNotEmpty) {
      // If next item has a known ready time, wake exactly then.
      // Otherwise, continue cooperative batching using batchInterval.
      var delay = untilWeakenMs != null
          ? Duration(milliseconds: untilWeakenMs)
          : batchInterval;
      _scheduleWeakenStrongRefs(delay, force: true);
    }
  }
}
