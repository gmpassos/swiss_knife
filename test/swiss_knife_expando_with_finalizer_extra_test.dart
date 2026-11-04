import 'package:swiss_knife/swiss_knife.dart';
import 'package:test/test.dart';

class _Key {
  final int id;

  _Key(this.id);
}

void main() {
  group('Finalizer wrappers', () {
    test('SimpleFinalizerWrapper', () {
      final w = SimpleFinalizerWrapper<String>('v');
      expect(w.value, 'v');
    });

    test('SimpleFinalizerWrapperDebug keeps the key reachable for debug', () {
      final k = _Key(1);
      final w = SimpleFinalizerWrapperDebug<_Key, String>(k, 'v');
      expect(w.value, 'v');
      expect(w.key, same(k));
    });

    test('ExpandoValueWrapperDebug', () {
      final k = _Key(1);
      final w = ExpandoValueWrapperDebug<_Key, String>(k, 'v');
      expect(w.value, 'v');
      expect(w.key, same(k));
    });
  });

  group('AttachOnlyFinalizer', () {
    test('debug: false creates simple wrappers', () {
      final f = AttachOnlyFinalizer<_Key, String>((_) {});
      expect(f.debug, isFalse);
      final k = _Key(1);
      final w = f.createWrapper(k, 'v');
      expect(w, isNot(isA<SimpleFinalizerWrapperDebug>()));
      expect(w.value, 'v');
      expect(f.getWrapper(k), isNull);
    });

    test('debug: true creates debug wrappers', () {
      final f = AttachOnlyFinalizer<_Key, String>((_) {}, debug: true);
      expect(f.debug, isTrue);
      final k = _Key(1);
      final w = f.createWrapper(k, 'v');
      expect(w, isA<SimpleFinalizerWrapperDebug<_Key, String>>());
      expect((w as SimpleFinalizerWrapperDebug<_Key, String>).key, same(k));
      expect(w.value, 'v');

      // `put` never finds a previous wrapper, and does not throw:
      f.put(k, 'a');
      f.put(k, 'a');
      expect(f.getWrapper(k), isNull);
      expect(() => f.remove(k), throwsUnsupportedError);
    });

    test('default onFinalizeError is a no-op', () {
      final f = AttachOnlyFinalizer<_Key, String>((_) {});
      f.onFinalizeError(StateError('x'), StackTrace.current);
    });
  });

  group('ExpandoWithFinalizer', () {
    test('debug: true stores debug wrappers', () {
      final e = ExpandoWithFinalizer<_Key, String>((_) {}, debug: true);
      expect(e.debug, isTrue);
      final k = _Key(1);
      e[k] = 'v';

      final w = e.getWrapper(k);
      expect(w, isA<ExpandoValueWrapperDebug<_Key, String>>());
      expect((w as ExpandoValueWrapperDebug<_Key, String>).key, same(k));
      expect(w.value, 'v');
      expect(e[k], 'v');
      expect(e.containsKey(k), isTrue);

      expect(e.remove(k), 'v');
      expect(e.getWrapper(k), isNull);
      expect(e.containsKey(k), isFalse);
      expect(e.remove(k), isNull);
    });

    test('debug: false stores simple wrappers', () {
      final e = ExpandoWithFinalizer<_Key, String>((_) {});
      expect(e.debug, isFalse);
      final k = _Key(1);
      e.put(k, 'v');
      final w = e.getWrapper(k);
      expect(w, isNot(isA<ExpandoValueWrapperDebug>()));
      expect(w!.value, 'v');
      expect(e.get(k), 'v');
    });

    test('default onFinalizeError is a no-op', () {
      final e = ExpandoWithFinalizer<_Key, String>((_) {});
      e.onFinalizeError(StateError('x'), StackTrace.current);
      expect(e.onFinalize, isNotNull);
    });
  });
}
