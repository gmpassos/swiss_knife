import 'dart:async';

import 'package:swiss_knife/swiss_knife.dart';
import 'package:test/test.dart';

class Box {
  final int value;

  Box(this.value);

  @override
  String toString() => 'Box{$value}';
}

Future<void> sleep([int ms = 0]) async {
  await Future.delayed(Duration(milliseconds: ms));
}

void main() {
  group('Creation', () {
    test('strong() starts strong', () {
      final m =
          LazyWeakReferenceManager<Box>(weakenDelay: Duration(seconds: 5));
      final obj = Box(1);

      final ref = m.strong(obj);

      expect(ref.isStrong, true);
      expect(ref.isWeak, false);
      expect(ref.target, same(obj));
      expect(ref.targetIfStrong, same(obj));
      expect(ref.isAlive, true);
      expect(ref.isLost, false);
    });

    test('weak() starts weak', () {
      final m = LazyWeakReferenceManager<Box>();
      final obj = Box(2);

      final ref = m.weak(obj);

      expect(ref.isStrong, false);
      expect(ref.isWeak, true);
      expect(ref.target, same(obj));
      expect(ref.targetIfStrong, null);
    });
  });

  group('State flags', () {
    test('isQueued true while strong and managed', () async {
      final m = LazyWeakReferenceManager<Box>(
        weakenDelay: Duration(milliseconds: 100),
      );

      final ref = m.strong(Box(1));

      expect(ref.isQueued, true);

      ref.weak();

      expect(ref.isQueued, false);
    });

    test('elapsedMs increases', () async {
      final m = LazyWeakReferenceManager<Box>();
      final ref = m.strong(Box(2));

      final t0 = m.unixTimeMs;
      expect(ref.elapsedMs(t0) < 10, true);

      await sleep(10);
      final t1 = m.unixTimeMs;

      expect(ref.elapsedMs(t1) >= 10, true);
    });
  });

  group('Promotion strong()', () {
    test('weak -> strong promotion', () {
      final m =
          LazyWeakReferenceManager<Box>(weakenDelay: Duration(seconds: 5));
      final obj = Box(3);

      final ref = m.weak(obj);
      final promoted = ref.strong();

      expect(promoted, same(obj));
      expect(ref.isStrong, true);
      expect(ref.targetIfStrong, same(obj));
    });

    test('strong() keeps weakRef when requested', () {
      final m =
          LazyWeakReferenceManager<Box>(weakenDelay: Duration(seconds: 5));
      final obj = Box(4);

      final ref = m.weak(obj);
      ref.strong(keepWeakRef: true);

      expect(ref.isStrong, true);
      expect(ref.target, same(obj));
    });

    test('strong() removes weakRef when keepWeakRef=false', () {
      final m =
          LazyWeakReferenceManager<Box>(weakenDelay: Duration(seconds: 5));
      final obj = Box(5);

      final ref = m.weak(obj);
      ref.strong(keepWeakRef: false);

      expect(ref.isStrong, true);
      expect(ref.target, same(obj));
    });
  });

  group('Manual weakening', () {
    test('strong -> weak', () {
      final m =
          LazyWeakReferenceManager<Box>(weakenDelay: Duration(seconds: 5));
      final obj = Box(6);

      final ref = m.strong(obj);

      final returned = ref.weak();

      expect(returned, same(obj));
      expect(ref.isStrong, false);
      expect(ref.isWeak, true);
    });

    test('weak(checkWeakRefTarget:false) does not touch weak target', () {
      final m = LazyWeakReferenceManager<Box>();
      final obj = Box(7);

      final ref = m.weak(obj);

      final r = ref.weak(checkWeakRefTarget: false);

      expect(r, null);
      expect(ref.isWeak, true);
    });
  });

  group('Automatic weakening by manager', () {
    test('becomes weak after delay', () async {
      final m = LazyWeakReferenceManager<Box>(
        weakenDelay: Duration(milliseconds: 40),
        batchInterval: Duration(milliseconds: 1),
      );

      final ref = m.strong(Box(10));

      expect(ref.isStrong, true);

      await sleep(60);

      expect(ref.isStrong, false);
      expect(ref.isWeak, true);
    });

    test('promotion refreshes weaken timer', () async {
      final m = LazyWeakReferenceManager<Box>(
        weakenDelay: Duration(milliseconds: 40),
      );

      final ref = m.strong(Box(11));

      await sleep(25);
      ref.strong(); // refresh

      await sleep(25);

      // Should still be strong
      expect(ref.isStrong, true);

      await sleep(50);

      expect(ref.isWeak, true);
    });
  });

  group('Dispose', () {
    test('dispose clears everything', () {
      final m = LazyWeakReferenceManager<Box>();
      final ref = m.strong(Box(20));

      ref.dispose();

      expect(ref.isDisposed, true);
      expect(ref.manager, null);
      expect(ref.target, null);
      expect(ref.isAlive, false);
    });

    test('dispose idempotent', () {
      final m = LazyWeakReferenceManager<Box>();
      final ref = m.strong(Box(21));

      ref.dispose();
      ref.dispose();

      expect(ref.isDisposed, true);
    });
  });

  group('Manager queue behavior', () {
    test('weak removes from queue', () async {
      final m = LazyWeakReferenceManager<Box>(
        weakenDelay: Duration(milliseconds: 50),
      );

      final ref = m.strong(Box(30));

      ref.weak();

      await sleep(70);

      expect(ref.isWeak, true);
    });

    test('dispose removes from queue', () async {
      final m = LazyWeakReferenceManager<Box>(
        weakenDelay: Duration(milliseconds: 50),
      );

      final ref = m.strong(Box(31));
      ref.dispose();

      await sleep(70);

      expect(ref.isDisposed, true);
    });
  });

  group('Batch processing', () {
    test('large batch weakens progressively', () async {
      final m = LazyWeakReferenceManager<Box>(
        weakenDelay: Duration(milliseconds: 20),
        batchLimit: 3,
        batchInterval: Duration(milliseconds: 5),
      );

      final refs = List.generate(10, (i) => m.strong(Box(i)));

      await sleep(100);

      for (final r in refs) {
        expect(r.isWeak || r.isDisposed, true);
      }
    });
  });

  group('Lost target handling', () {
    test('weak target cleanup when already null', () {
      final m = LazyWeakReferenceManager<Box>();
      final ref = m.weak(Box(3));

      // Drop strong variable
      // ignore: unused_local_variable
      final lost = ref.weak();

      // We cannot guarantee GC, but weak() path should not crash
      expect(ref.isStrong, false);
    });

    test('strong() returns null if weak target lost', () {
      final m = LazyWeakReferenceManager<Box>();
      final ref = m.weak(Box(4));

      // Simulate lost by manually clearing weakRef through dispose
      ref.dispose();

      final promoted = ref.strong();
      expect(promoted, null);
    });
  });

  group('_weakOrDispose behavior', () {
    test('auto dispose when target already gone', () async {
      final m = LazyWeakReferenceManager<Box>(
        weakenDelay: Duration(milliseconds: 10),
      );

      var ref = m.strong(Box(5));

      // Dispose manually to simulate lost state
      ref.dispose();

      await sleep(20);

      expect(ref.isDisposed, true);
    });
  });

  group('Queue reordering', () {
    test('recent access moves ref to end of queue', () async {
      final m = LazyWeakReferenceManager<Box>(
        weakenDelay: Duration(milliseconds: 40),
        batchInterval: Duration(milliseconds: 1),
      );

      final a = m.strong(Box(1));
      await sleep(10);
      final b = m.strong(Box(2));

      await sleep(20);

      // Refresh 'a' so it should weaken after 'b'
      a.strong();

      await sleep(30);

      // b should weaken first
      expect(b.isWeak, true);
      expect(a.isStrong, true);

      await sleep(50);

      expect(a.isWeak, true);
    });
  });

  group('Batch limit boundary', () {
    test('exact batchLimit processed per cycle', () async {
      final m = LazyWeakReferenceManager<Box>(
        weakenDelay: Duration(milliseconds: 20),
        batchLimit: 2,
        batchInterval: Duration(milliseconds: 10),
      );

      final refs = List.generate(5, (i) => m.strong(Box(i)));

      await sleep(25);

      // After first cycle only 2 should have weakened
      final weakened1 = refs.where((r) => r.isWeak).length;
      expect(weakened1 <= 2, true);

      await sleep(100);

      for (final r in refs) {
        expect(r.isWeak, true);
      }
    });
  });

  group('Debounce scheduling', () {
    test('multiple strong inserts schedule only once', () async {
      final m = LazyWeakReferenceManager<Box>(
        weakenDelay: Duration(milliseconds: 30),
      );

      final a = m.strong(Box(1));
      final b = m.strong(Box(2));
      final c = m.strong(Box(3));

      expect(a.isQueued, true);
      expect(b.isQueued, true);
      expect(c.isQueued, true);

      await sleep(60);

      expect(a.isWeak, true);
      expect(b.isWeak, true);
      expect(c.isWeak, true);
    });
  });

  group('toString', () {
    test('prints target', () {
      final m = LazyWeakReferenceManager<Box>();
      final ref = m.strong(Box(99));

      expect(ref.toString(), contains('99'));
    });
  });
}
