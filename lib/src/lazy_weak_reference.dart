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
final class LazyWeakReference<T extends Object>
    implements Comparable<LazyWeakReference> {
  /// Unique sequence identifier assigned by the owning [manager].
  ///
  /// Used as a tie-breaker in [compareTo] to provide a strict ordering between
  /// instances that share the same timestamp. Uniqueness is only guaranteed
  /// among references created by the same manager.
  final int id;

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

  /// Unix timestamp (milliseconds) of creation or of the most recent
  /// transition to a strong reference.
  int get unixTimeMs => _unixTimeMs;

  /// Previous node in the manager’s intrusive doubly-linked aging queue.
  ///
  /// Used internally by [LazyWeakReferenceManager] to maintain O(1)
  /// insertion, removal, and reordering of strong references without
  /// external allocations.
  ///
  /// When this reference is not enqueued, this field is `null`.
  LazyWeakReference<T>? _prev;

  /// Next node in the manager’s intrusive doubly-linked aging queue.
  ///
  /// Together with [_prev], this forms an intrusive linked structure
  /// owned by the manager. The queue is ordered by last-strong-access
  /// time (oldest at head, newest at tail).
  ///
  /// When this reference is not enqueued, this field is `null`.
  LazyWeakReference<T>? _next;

  /// Creates a strong reference.
  ///
  /// The timestamp [_unixTimeMs] is assigned later by [manager] when the
  /// instance is enqueued for weakening.
  LazyWeakReference._strong(this.id, this._manager, T target)
      : _strongRef = target,
        _weakRef = null,
        _unixTimeMs = 0;

  /// Creates a weak reference.
  LazyWeakReference._weak(this.id, this._manager, T target, this._unixTimeMs)
      : _strongRef = null,
        _weakRef = WeakReference(target);

  /// Returns the object if still reachable.
  ///
  /// - Prefers strong reference
  /// - Falls back to weak reference
  T? get target => _strongRef ?? _weakRef?.target;

  /// Returns the object only if currently held strongly.
  ///
  /// Does not access [WeakReference.target].
  /// Returns `null` if weak, lost, or disposed.
  ///
  /// See [target].
  T? get targetIfStrong => _strongRef;

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

  /// Orders instances first by `_unixTimeMs` and then by the
  /// unique [id] to guarantee a strict total order.
  ///
  /// The tie-breaker ensures `compareTo` never returns 0 for distinct objects,
  /// allowing multiple references with the same timestamp to coexist inside
  /// a `SplayTreeSet`.
  ///
  /// Instances must only be compared with others produced by the same manager,
  /// since [id] uniqueness is only guaranteed within that scope.
  @override
  int compareTo(LazyWeakReference<Object> other) {
    final cmp = _unixTimeMs.compareTo(other._unixTimeMs);
    if (cmp != 0) return cmp;
    return id.compareTo(other.id);
  }
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

  int _refIdCount = 0;

  /// Creates a managed strong reference.
  LazyWeakReference<T> strong(T target) {
    var ref = LazyWeakReference<T>._strong(++_refIdCount, this, target);
    _handleNewStrongRef(ref);
    return ref;
  }

  /// Creates a managed weak reference.
  LazyWeakReference<T> weak(T target) {
    var ref =
        LazyWeakReference<T>._weak(++_refIdCount, this, target, unixTimeMs);
    _handleNewWeakRef(ref);
    return ref;
  }

  /// Current unix time in milliseconds.
  int get unixTimeMs => DateTime.now().millisecondsSinceEpoch;

  /// Head of the intrusive aging queue (oldest strong reference).
  ///
  /// References near this end are the next candidates to transition
  /// from strong → weak once [weakenDelay] has elapsed.
  /// Managed exclusively by the manager.
  LazyWeakReference<T>? _head; // oldest

  /// Tail of the intrusive aging queue (most recently accessed strong reference).
  ///
  /// Newly created or recently strengthened references are appended here.
  /// Managed exclusively by the manager.
  LazyWeakReference<T>? _tail; // newest

  /// Appends [ref] to the tail of the intrusive aging queue.
  ///
  /// This marks the reference as the most recently strengthened entry.
  /// Runs in O(1) time and performs no allocations.
  ///
  /// Precondition:
  /// - [ref] must NOT already be enqueued.
  ///
  /// Postcondition:
  /// - [ref] becomes the newest (tail) element.
  /// - [_queued] is set to true.
  void _pushBack(LazyWeakReference<T> ref) {
    assert(!ref._queued);

    ref._prev = _tail;
    ref._next = null;

    if (_tail != null) {
      _tail!._next = ref;
    } else {
      _head = ref;
    }

    _tail = ref;
    ref._queued = true;
  }

  /// Removes [ref] from the intrusive aging queue.
  ///
  /// This operation runs in O(1) time and updates neighboring links
  /// without traversing the queue.
  ///
  /// Precondition:
  /// - Safe to call only if [ref] is currently enqueued.
  ///
  /// Postcondition:
  /// - [ref] is detached from the queue.
  /// - [_queued] is set to false.
  /// - [_prev] and [_next] are cleared.
  void _remove(LazyWeakReference<T> ref) {
    assert(ref._queued);

    final p = ref._prev;
    final n = ref._next;

    if (p != null) {
      p._next = n;
    } else {
      _head = n;
    }

    if (n != null) {
      n._prev = p;
    } else {
      _tail = p;
    }

    ref._prev = null;
    ref._next = null;
    ref._queued = false;
  }

  /// Registers a new strong reference for future weakening.
  void _handleNewStrongRef(LazyWeakReference<T> ref) {
    assert(!ref._queued);

    // Set strong ref creation time:
    ref._unixTimeMs = unixTimeMs;
    _pushBack(ref);

    _scheduleWeakenStrongRefs(weakenDelay);
  }

  /// Registers an accessed strong reference for future weakening.
  void _handleAccessStrongRef(LazyWeakReference<T> ref) {
    assert(ref._queued);
    _remove(ref);

    // Update strong ref access time:
    ref._unixTimeMs = unixTimeMs;
    _pushBack(ref);

    _scheduleWeakenStrongRefs(weakenDelay);
  }

  /// Called when a reference transitions to weak state.
  ///
  /// If the reference was previously strong, it is removed from the
  /// pending strong-weakening queue to avoid redundant processing.
  void _handleNewWeakRef(LazyWeakReference<T> ref) {
    if (ref._queued) _remove(ref);
  }

  /// Called when a reference is permanently disposed.
  ///
  /// Ensures the reference is no longer tracked by the manager and will not
  /// participate in future weakening cycles. If the reference was waiting in
  /// the strong-reference queue, it is removed to prevent unnecessary work
  /// and to avoid holding stale entries.
  void _handleDisposedRef(LazyWeakReference<T> ref) {
    if (ref._queued) _remove(ref);
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

    // If we encounter a not-yet-eligible entry, we compute how long to wait.
    int? nextWeakenDelayMs;
    // Number of references processed in this batch.
    var count = 0;

    // Process only a limited amount to avoid long blocking work:
    while (_head != null && count < batchLimit) {
      // Oldest strong reference.
      final ref = _head!;
      assert(ref._queued);

      // How long this reference has been strong.
      final elapsedTimeMs = ref.elapsedMs(unixTimeMs);

      // Eligible → weaken (or dispose) immediately.
      if (elapsedTimeMs >= weakenDelay) {
        // Remove from strong queue and weaken the reference:
        _remove(ref);
        assert(!ref._queued);

        ref._weakOrDispose();
        ++count;
      } else {
        // Not ready yet: compute remaining wait time and stop batch.
        // Queue is time-ordered, so the rest are also not ready.
        nextWeakenDelayMs = weakenDelay - elapsedTimeMs;
        break;
      }
    }

    // If more items exist, schedule the next processing slice:
    if (_head != null) {
      // If next item has a known ready time, wake exactly then.
      // Otherwise, continue cooperative batching using batchInterval.
      var delay = nextWeakenDelayMs != null
          ? Duration(milliseconds: nextWeakenDelayMs)
          : batchInterval;

      _scheduleWeakenStrongRefs(delay, force: true);
    }
  }
}
