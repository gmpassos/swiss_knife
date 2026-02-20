@Timeout(Duration(seconds: 60))
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:swiss_knife/swiss_knife.dart';
import 'package:test/test.dart';

/// Helper object used as key
class _Key {
  final int id;

  _Key(this.id);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _Key && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => '_Key{$id}';
}

/// Encourages a full GC without huge allocations.
/// Designed for stable Finalizer tests and CI environments.
Future<void> _encourageGC() async {
  const chunk = 256 * 1024; // 256 KB
  const perRound = 24; // 6 MB per round
  const rounds = 12; // ~72 MB total churn (not simultaneous)

  for (int r = 0; r < rounds; r++) {
    final buffers = <Uint8List>[];

    for (int i = 0; i < perRound; i++) {
      final b = Uint8List(chunk);
      b[0] = r; // touch memory
      b[b.length - 1] = i;
      buffers.add(b);
    }

    // Drop references → eligible for collection
    await Future.delayed(const Duration(milliseconds: 8));
  }
}

/// Waits until condition true or timeout
Future<void> _waitUntil(bool Function() cond,
    {Duration timeout = const Duration(seconds: 10)}) async {
  final start = DateTime.now();
  while (!cond()) {
    if (DateTime.now().difference(start) > timeout) {
      fail('Timed out waiting for condition');
    }
    await _encourageGC();
  }
}

void main() {
  group('ExpandoWithFinalizer basic behavior', () {
    test('set + get', () {
      final exp = ExpandoWithFinalizer<_Key, String>((_) {});
      final key = _Key(1);

      exp.put(key, 'hello');

      expect(exp.get(key), 'hello');
      expect(exp.containsKey(key), true);
      expect(exp[key], 'hello');
    });

    test('replace value', () {
      final exp = ExpandoWithFinalizer<_Key, String>((_) {});
      final key = _Key(1);

      exp[key] = 'a';
      exp[key] = 'b';

      expect(exp.get(key), 'b');
    });

    test('remove cancels association', () {
      final exp = ExpandoWithFinalizer<_Key, String>((_) {});
      final key = _Key(1);

      exp[key] = 'value';

      final removed = exp.remove(key);

      expect(removed, 'value');
      expect(exp.containsKey(key), false);
      expect(exp.get(key), null);
    });
  });

  group('finalizer behavior', () {
    test('finalizer called when key GCd', () async {
      final finalized = <String>[];
      final exp = ExpandoWithFinalizer<_Key, String>((v) {
        finalized.add(v);
      });

      void createKey() {
        final key = _Key(10);
        exp[key] = 'hello';
      }

      createKey();

      await _waitUntil(() => finalized.contains('hello'));

      expect(finalized, ['hello']);
      expect(exp.get(_Key(10)), null);
    });

    test('remove prevents finalizer', () async {
      final finalized = <String>[];
      final exp = ExpandoWithFinalizer<_Key, String>((v) {
        finalized.add(v);
      });

      void createKey() {
        final key = _Key(20);
        exp[key] = 'hello';
        exp.remove(key);
      }

      createKey();

      await _encourageGC();
      await Future.delayed(const Duration(milliseconds: 200));

      expect(finalized, isEmpty);
      expect(exp.get(_Key(20)), null);
    });

    test('replace cancels old value finalization', () async {
      final finalized = <String>[];
      final exp = ExpandoWithFinalizer<_Key, String>((v) {
        finalized.add(v);
      });

      void createKey() {
        final key = _Key(30);
        exp[key] = 'old';
        exp[key] = 'new';
      }

      createKey();

      await _waitUntil(() => finalized.isNotEmpty);

      expect(finalized, ['new']);
      expect(exp.get(_Key(30)), null);
    });

    test('same object set does not reattach', () async {
      final finalized = <String>[];
      final exp = ExpandoWithFinalizer<_Key, String>((v) {
        finalized.add(v);
      });

      void createKey() {
        final key = _Key(40);
        final value = 'same';
        exp[key] = value;
        exp[key] = value;
      }

      createKey();

      await _waitUntil(() => finalized.isNotEmpty);

      expect(finalized, ['same']);
      expect(exp.get(_Key(40)), null);
    });
  });
}
