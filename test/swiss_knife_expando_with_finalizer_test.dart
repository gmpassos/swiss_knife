@Timeout(Duration(seconds: 120))
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
  const perRound = 32; // 8 MB per round
  const rounds = 16; // ~128 MB total churn (not simultaneous)

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
    {Duration timeout = const Duration(seconds: 40)}) async {
  var stackTrace = StackTrace.current;
  final start = DateTime.now();
  while (!cond()) {
    if (DateTime.now().difference(start) > timeout) {
      Error.throwWithStackTrace(
          TestFailure('Timed out waiting for condition'), stackTrace);
    }
    await _encourageGC();
  }
}

void main() {
  tearDown(() async {
    await _encourageGC();
  });

  group('ExpandoWithFinalizer basic behavior', () {
    test('set + get', () {
      final exp = ExpandoWithFinalizer<_Key, String>((_) {});
      final key = _Key(1);

      exp.put(key, 'hello');

      expect(exp.get(key), 'hello');
      expect(exp.containsKey(key), true);
      expect(exp[key], 'hello');
    });

    test('containsKey remains true after replace', () {
      final exp = ExpandoWithFinalizer<_Key, String>((_) {});
      final key = _Key(1);

      exp[key] = 'a';
      exp[key] = 'b';

      expect(exp.containsKey(key), true);
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

    test('remove twice returns null second time', () {
      final exp = ExpandoWithFinalizer<_Key, String>((_) {});
      final key = _Key(2);

      exp[key] = 'value';

      expect(exp.remove(key), 'value');
      expect(exp.remove(key), null);
    });

    test('get on unknown key returns null', () {
      final exp = ExpandoWithFinalizer<_Key, String>((_) {});

      expect(exp.get(_Key(999)), null);
      expect(exp.containsKey(_Key(999)), false);
    });

    test('remove after replace removes latest value only', () {
      final exp = ExpandoWithFinalizer<_Key, String>((_) {});
      final key = _Key(101);

      exp[key] = 'old';
      exp[key] = 'new';

      final removed = exp.remove(key);

      expect(removed, 'new');
      expect(exp.containsKey(key), false);
    });

    test('remove unknown key returns null', () {
      final exp = ExpandoWithFinalizer<_Key, String>((_) {});

      expect(exp.remove(_Key(200)), null);
    });

    test('multiple replaces finalize only last value', () async {
      final finalized = <String>[];

      final exp = ExpandoWithFinalizer<_Key, String>(
        finalized.add,
      );

      void createKey() {
        final key = _Key(300);
        exp[key] = 'a';
        exp[key] = 'b';
        exp[key] = 'c';
      }

      createKey();

      await _waitUntil(() => finalized.isNotEmpty);

      expect(finalized, ['c']);
      expect(exp[_Key(300)], isNull);
    });

    test('large batch finalization', () async {
      final finalized = <int>[];

      final exp = ExpandoWithFinalizer<_Key, int>((v) => finalized.add(v));

      void create() {
        for (var i = 0; i < 50; i++) {
          exp[_Key(i)] = i;
        }
      }

      create();

      await _waitUntil(() => finalized.length == 50);

      expect(finalized.length, 50);
      expect(exp[_Key(1)], isNull);
    });

    test('wrapper removed after finalization', () async {
      final exp = ExpandoWithFinalizer<_Key, String>((_) {});

      void create() {
        exp[_Key(400)] = 'v';
      }

      create();

      await _waitUntil(() => exp.getWrapper(_Key(400)) == null);

      expect(exp.getWrapper(_Key(400)), null);
    });

    test('finalizer error does not stop other finalizations', () async {
      final finalized = <String>[];

      final exp = _TestExpando<_Key, String>(
        (v) {
          if (v == 'bad') {
            throw StateError("Bad");
          }
          finalized.add(v);
        },
      );

      void create() {
        exp[_Key(1)] = 'ok';
        exp[_Key(2)] = 'bad';
      }

      create();

      await _waitUntil(() => finalized.contains('ok'));

      expect(finalized, contains('ok'));
      expect(exp[_Key(1)], isNull);
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

    test('finalizer fires only once per association', () async {
      final finalized = <String>[];

      final exp = ExpandoWithFinalizer<_Key, String>((v) {
        finalized.add(v);
      });

      void createKey() {
        final key = _Key(50);
        exp[key] = 'once';
      }

      createKey();

      await _waitUntil(() => finalized.isNotEmpty);

      await _encourageGC();
      await Future.delayed(const Duration(milliseconds: 200));

      expect(finalized, ['once']);
      expect(exp.get(_Key(50)), null);
    });

    test('multiple keys finalize independently', () async {
      final finalized = <String>[];

      final exp = ExpandoWithFinalizer<_Key, String>((v) {
        finalized.add(v);
      });

      void createKeys() {
        exp[_Key(1)] = 'a';
        exp[_Key(2)] = 'b';
        exp[_Key(3)] = 'c';
      }

      createKeys();

      await _waitUntil(() => finalized.length == 3);

      expect(finalized.toSet(), {'a', 'b', 'c'});
      expect(exp.get(_Key(1)), null);
      expect(exp.get(_Key(2)), null);
      expect(exp.get(_Key(3)), null);
    });

    test('onFinalizeError called when callback throws', () async {
      Object? capturedError;

      final exp = _TestExpando(
        (_) => throw StateError('boom'),
        onError: (e) => capturedError = e,
      );

      void createKey() {
        exp[_Key(60)] = 'x';
      }

      createKey();

      await _waitUntil(() => capturedError != null);

      expect(capturedError, isA<StateError>());
      expect(exp.get(_Key(60)), null);
    });

    test('debug wrapper does not keep key alive', () async {
      final finalized = <String>[];

      final exp = ExpandoWithFinalizer<_Key, String>((v) => finalized.add(v),
          debug: true);

      void createKey() {
        final key = _Key(70);
        exp[key] = 'debug';
      }

      createKey();

      await _waitUntil(() => finalized.contains('debug'));

      expect(finalized, ['debug']);
      expect(exp.get(_Key(70)), null);
    });

    test('identical value does not replace wrapper', () {
      final exp = ExpandoWithFinalizer<_Key, Object>((_) {});
      final key = _Key(80);

      final value = Object();

      exp.put(key, value);

      final wrapper1 = exp.getWrapper(key);

      exp.put(key, value);

      final wrapper2 = exp.getWrapper(key);

      expect(identical(wrapper1, wrapper2), true);
    });
  });

  group('AttachOnlyFinalizer', () {
    test('remove throws', () {
      final f = AttachOnlyFinalizer<_Key, String>((_) {});

      expect(
        () => f.remove(_Key(1)),
        throwsUnsupportedError,
      );
    });

    test('finalizer runs', () async {
      final finalized = <String>[];

      final f = AttachOnlyFinalizer<_Key, String>((v) {
        finalized.add(v);
      });

      void createKey() {
        final key = _Key(90);
        f.put(key, 'value');
      }

      createKey();

      await _waitUntil(() => finalized.isNotEmpty);

      expect(finalized, ['value']);
      expect(f, isNotNull);
    });

    test('AttachOnly allows multiple attachments', () async {
      final finalized = <String>[];

      final f = AttachOnlyFinalizer<_Key, String>(finalized.add);

      void create() {
        final key = _Key(500);
        f.put(key, 'a');
        f.put(key, 'b');
      }

      create();

      await _waitUntil(() => finalized.length == 2);

      expect(finalized.toSet(), {'a', 'b'});
      expect(f, isNotNull);
    });
  });
}

class _TestExpando<K extends Object, V extends Object>
    extends ExpandoWithFinalizer<K, V> {
  final void Function(Object error)? onError;

  _TestExpando(super.cb, {this.onError});

  @override
  void onFinalizeError(Object error, StackTrace stackTrace) {
    onError?.call(error);
  }
}
