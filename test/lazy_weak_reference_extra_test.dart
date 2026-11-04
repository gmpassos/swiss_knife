import 'dart:async';

import 'package:swiss_knife/swiss_knife.dart';
import 'package:test/test.dart';

class Box {
  final int value;

  Box(this.value);

  @override
  String toString() => 'Box{$value}';
}

/// A manager with a controllable clock, for deterministic timestamps.
class FakeClockManager<T extends Object> extends LazyWeakReferenceManager<T> {
  int now = 1000;

  FakeClockManager({super.weakenDelay, super.batchLimit, super.batchInterval});

  @override
  int get unixTimeMs => now;
}

Future<void> sleep(int ms) => Future.delayed(Duration(milliseconds: ms));

void main() {
  group('LazyWeakReferenceManager constructor', () {
    test('defaults', () {
      final m = LazyWeakReferenceManager<Box>();
      expect(m.weakenDelay, LazyWeakReferenceManager.defaultWeakenDelay);
      expect(m.weakenDelay, Duration(seconds: 1));
      expect(m.batchLimit, LazyWeakReferenceManager.defaultBatchLimit);
      expect(m.batchLimit, 100);
      expect(m.batchInterval, LazyWeakReferenceManager.defaultBatchInterval);
      expect(m.batchInterval, Duration(milliseconds: 1));
    });

    test('valid values are kept', () {
      final m = LazyWeakReferenceManager<Box>(
        weakenDelay: Duration(milliseconds: 2),
        batchLimit: 7,
        batchInterval: Duration(milliseconds: 3),
      );
      expect(m.weakenDelay, Duration(milliseconds: 2));
      expect(m.batchLimit, 7);
      expect(m.batchInterval, Duration(milliseconds: 3));
    });

    test('invalid values are normalized', () {
      final m = LazyWeakReferenceManager<Box>(
        weakenDelay: Duration.zero,
        batchLimit: 0,
        batchInterval: Duration.zero,
      );
      expect(m.weakenDelay, Duration(seconds: 1));
      expect(m.batchLimit, 1);
      expect(m.batchInterval, Duration(milliseconds: 1));

      expect(LazyWeakReferenceManager<Box>(batchLimit: -5).batchLimit, 1);
      expect(LazyWeakReferenceManager<Box>(batchLimit: 1).batchLimit, 1);
    });

    test('a 1 ms weakenDelay is replaced by the default', () {
      // NOTE: current behaviour; possibly a bug: the check is
      // `weakenDelay.inMilliseconds > 1`, so a valid 1 ms delay silently
      // becomes the 1 second default (a 1000x longer delay).
      final m = LazyWeakReferenceManager<Box>(
        weakenDelay: Duration(milliseconds: 1),
      );
      expect(m.weakenDelay, Duration(seconds: 1));
    });

    test('ids are unique and increasing', () {
      final m1 = LazyWeakReferenceManager<Box>();
      final m2 = LazyWeakReferenceManager<Box>();
      expect(m2.id, greaterThan(m1.id));
    });

    test('unixTimeMs is the current time', () {
      final m = LazyWeakReferenceManager<Box>();
      final before = DateTime.now().millisecondsSinceEpoch;
      final t = m.unixTimeMs;
      final after = DateTime.now().millisecondsSinceEpoch;
      expect(t, inInclusiveRange(before, after));
    });
  });

  group('LazyWeakReferenceManager.toString', () {
    test('reflects state', () {
      final m = FakeClockManager<Box>(weakenDelay: Duration(seconds: 5));
      final prefix = 'LazyWeakReferenceManager#${m.id}<$Box>{';

      expect(
        m.toString(),
        '${prefix}weakenDelay: 5000 ms, batchLimit: 100, '
        'batchInterval: 1 ms, refIdCount: 0, queueSize: 0, '
        'scheduledWeakenStrongRefs: false}',
      );

      final a = m.strong(Box(1));
      final b = m.strong(Box(2));
      m.weak(Box(3));

      expect(
        m.toString(),
        '${prefix}weakenDelay: 5000 ms, batchLimit: 100, '
        'batchInterval: 1 ms, refIdCount: 3, queueSize: 2, '
        'scheduledWeakenStrongRefs: true}',
      );

      a.dispose();
      b.weak();

      expect(m.toString(), contains('refIdCount: 3, queueSize: 0,'));
    });
  });

  group('LazyWeakReference', () {
    test('ids, unixTimeMs and toString', () {
      final m = FakeClockManager<Box>(weakenDelay: Duration(seconds: 5));
      final a = m.strong(Box(1));
      m.now = 1500;
      final b = m.weak(Box(2));

      expect(a.id, 1);
      expect(b.id, 2);
      expect(a.unixTimeMs, 1000);
      expect(b.unixTimeMs, 1500);
      expect(a.elapsedMs(1600), 600);
      expect(a.manager, same(m));

      expect(
        a.toString(),
        'LazyWeakReference#1<$Box>{isStrong: true, isWeak: false, '
        'isDisposed: false, queued: true, unixTimeMs: 1000}@Box{1}',
      );

      a.dispose();
      expect(
        a.toString(),
        'LazyWeakReference#1<$Box>{isStrong: false, isWeak: false, '
        'isDisposed: true, queued: false, unixTimeMs: 1000}@null',
      );
    });

    test('strong() on a strong reference refreshes its timestamp', () {
      final m = FakeClockManager<Box>(weakenDelay: Duration(seconds: 5));
      final obj = Box(1);
      final ref = m.strong(obj);
      expect(ref.unixTimeMs, 1000);

      m.now = 1234;
      expect(ref.strong(), same(obj));
      expect(ref.unixTimeMs, 1234);
      expect(ref.isQueued, isTrue);
    });

    test('strong() on a disposed reference returns null', () {
      final m = FakeClockManager<Box>(weakenDelay: Duration(seconds: 5));
      final ref = m.strong(Box(1));
      ref.dispose();
      expect(ref.strong(), isNull);
      expect(ref.isStrong, isFalse);
      expect(ref.isQueued, isFalse);
    });

    test('strongIfWeak() on a strong reference does not refresh', () {
      final m = FakeClockManager<Box>(weakenDelay: Duration(seconds: 5));
      final obj = Box(1);
      final ref = m.strong(obj);

      m.now = 2000;
      expect(ref.strongIfWeak(), same(obj));
      expect(ref.unixTimeMs, 1000);
      expect(ref.isQueued, isTrue);
    });

    test('strongIfWeak() promotes a weak reference', () {
      final m = FakeClockManager<Box>(weakenDelay: Duration(seconds: 5));
      final obj = Box(1);
      final ref = m.weak(obj);
      expect(ref.isQueued, isFalse);

      m.now = 3000;
      expect(ref.strongIfWeak(), same(obj));
      expect(ref.isStrong, isTrue);
      expect(ref.isWeak, isFalse);
      expect(ref.isQueued, isTrue);
      expect(ref.unixTimeMs, 3000);

      // Back to weak: the kept weak handle is reused.
      expect(ref.weak(), same(obj));
      expect(ref.isWeak, isTrue);
      expect(ref.isQueued, isFalse);
    });

    test('strongIfWeak(keepWeakRef: false) drops the weak handle', () {
      final m = FakeClockManager<Box>(weakenDelay: Duration(seconds: 5));
      final obj = Box(1);
      final ref = m.weak(obj);

      expect(ref.strongIfWeak(keepWeakRef: false), same(obj));
      expect(ref.isStrong, isTrue);
      expect(ref.isQueued, isTrue);

      // Weakening creates a new weak handle:
      expect(ref.weak(), same(obj));
      expect(ref.isWeak, isTrue);
      expect(ref.target, same(obj));
    });

    test('strongIfWeak() on a disposed reference returns null', () {
      final m = FakeClockManager<Box>(weakenDelay: Duration(seconds: 5));
      final ref = m.weak(Box(1));
      ref.dispose();
      expect(ref.strongIfWeak(), isNull);
      expect(ref.isStrong, isFalse);
      expect(ref.isWeak, isFalse);
      expect(ref.isQueued, isFalse);
    });

    test('weak() on a weak reference', () {
      final m = FakeClockManager<Box>(weakenDelay: Duration(seconds: 5));
      final obj = Box(1);
      final ref = m.weak(obj);

      expect(ref.weak(), same(obj));
      expect(ref.weak(checkWeakRefTarget: false), isNull);
      expect(ref.isWeak, isTrue);
    });

    test('weak() on a disposed reference returns null', () {
      final m = FakeClockManager<Box>(weakenDelay: Duration(seconds: 5));
      final ref = m.strong(Box(1));
      ref.dispose();
      expect(ref.weak(), isNull);
      expect(ref.weak(checkWeakRefTarget: false), isNull);
      expect(ref.isLost, isTrue);
      expect(ref.isDisposed, isTrue);
    });

    test('compareTo orders by timestamp, then by id', () {
      final m = FakeClockManager<Box>(weakenDelay: Duration(seconds: 5));
      final a = m.strong(Box(1));
      final b = m.strong(Box(2));
      m.now = 900;
      final c = m.weak(Box(3));
      m.now = 2000;
      final d = m.weak(Box(4));

      expect(a.compareTo(a), 0);
      expect(a.compareTo(b), lessThan(0));
      expect(b.compareTo(a), greaterThan(0));
      expect(c.compareTo(a), lessThan(0));
      expect(a.compareTo(c), greaterThan(0));
      expect(d.compareTo(b), greaterThan(0));

      final sorted = [d, b, c, a]..sort();
      expect(sorted, [c, a, b, d]);
    });
  });

  group('Manager queue', () {
    test('removing middle, tail and head references', () {
      final m = FakeClockManager<Box>(weakenDelay: Duration(seconds: 5));
      final a = m.strong(Box(1));
      final b = m.strong(Box(2));
      final c = m.strong(Box(3));
      final d = m.strong(Box(4));

      expect(m.toString(), contains('queueSize: 4,'));

      b.weak(); // middle
      expect(m.toString(), contains('queueSize: 3,'));
      d.dispose(); // tail
      expect(m.toString(), contains('queueSize: 2,'));
      a.weak(); // head
      expect(m.toString(), contains('queueSize: 1,'));

      // Re-access the only element:
      expect(c.strong(), isNotNull);
      expect(m.toString(), contains('queueSize: 1,'));

      // Re-append after removal:
      b.strong();
      a.strong();
      expect(m.toString(), contains('queueSize: 3,'));

      // Access the head and move it to the tail:
      m.now = 1100;
      c.strong();
      expect(c.unixTimeMs, 1100);

      for (final r in [a, b, c]) {
        r.weak();
      }
      expect(m.toString(), contains('queueSize: 0,'));
    });

    test('weakening waits for the (fake) clock', () async {
      final m = FakeClockManager<Box>(
        weakenDelay: Duration(milliseconds: 5),
        batchInterval: Duration(milliseconds: 2),
      );
      final obj = Box(1);
      final ref = m.strong(obj);

      // Real time passes, but the manager's clock does not:
      await sleep(30);
      expect(ref.isStrong, isTrue);
      expect(ref.isQueued, isTrue);

      m.now += 5;
      await sleep(40);
      expect(ref.isStrong, isFalse);
      expect(ref.isWeak, isTrue);
      expect(ref.isQueued, isFalse);
      expect(ref.isDisposed, isFalse);
      expect(ref.target, same(obj));

      // Promoting again re-schedules weakening:
      expect(ref.strongIfWeak(), same(obj));
      expect(ref.isStrong, isTrue);
      m.now += 5;
      await sleep(40);
      expect(ref.isWeak, isTrue);
    });

    test('batchLimit splits weakening into slices', () async {
      final m = FakeClockManager<Box>(
        weakenDelay: Duration(milliseconds: 5),
        batchLimit: 2,
        batchInterval: Duration(milliseconds: 2),
      );
      final objs = List.generate(5, Box.new);
      final refs = objs.map(m.strong).toList();
      m.now += 10;

      await sleep(80);

      for (var i = 0; i < refs.length; i++) {
        expect(refs[i].isWeak, isTrue);
        expect(refs[i].target, same(objs[i]));
      }
      expect(m.toString(), contains('queueSize: 0,'));
    });
  });

  group('LazyWeakReferenceManagerByType', () {
    test('global configuration', () {
      final g = LazyWeakReferenceManagerByType.global;
      expect(identical(g, LazyWeakReferenceManagerByType.global), isTrue);
      expect(g.weakenDelay, Duration(seconds: 2));
      expect(g.batchLimit, 500);
      expect(g.batchInterval, Duration(milliseconds: 2));
    });

    test('defaults', () {
      final byType = LazyWeakReferenceManagerByType();
      expect(byType.weakenDelay, LazyWeakReferenceManager.defaultWeakenDelay);
      expect(byType.batchLimit, LazyWeakReferenceManager.defaultBatchLimit);
      expect(
        byType.batchInterval,
        LazyWeakReferenceManager.defaultBatchInterval,
      );
      expect(byType.length, 0);
      expect(byType.types, isEmpty);
      expect(byType.managers, isEmpty);
      expect(byType.entries, isEmpty);
    });

    test('get, remove and clear', () {
      final byType = LazyWeakReferenceManagerByType(
        weakenDelay: Duration(seconds: 3),
        batchLimit: 10,
        batchInterval: Duration(milliseconds: 4),
      );

      final boxes = byType.get<Box>();
      expect(boxes, isA<LazyWeakReferenceManager<Box>>());
      expect(boxes.weakenDelay, Duration(seconds: 3));
      expect(boxes.batchLimit, 10);
      expect(boxes.batchInterval, Duration(milliseconds: 4));
      expect(byType.get<Box>(), same(boxes));

      final strings = byType.get<String>();
      expect(strings, isNot(same(boxes)));

      expect(byType.length, 2);
      expect(byType.types.toList(), [Box, String]);
      expect(byType.managers.toList(), [boxes, strings]);
      final entries = byType.entries.toList();
      expect(entries.map((e) => e.key).toList(), [Box, String]);
      expect(entries[0].value, same(boxes));
      expect(entries[1].value, same(strings));

      expect(byType.remove<Box>(), same(boxes));
      expect(byType.remove<Box>(), isNull);
      expect(byType.length, 1);

      // Remove by explicit `Type`:
      expect(byType.remove(String), same(strings));
      expect(byType.length, 0);

      // A new manager is created after removal:
      final boxes2 = byType.get<Box>();
      expect(boxes2, isNot(same(boxes)));

      byType.get<int>();
      expect(byType.length, 2);
      byType.clear();
      expect(byType.length, 0);
      expect(byType.types, isEmpty);
    });
  });
}
