import 'package:swiss_knife/swiss_knife.dart';
import 'package:test/test.dart';

/// A [Pattern] that is neither a [String] nor a [RegExp].
class _CustomPattern implements Pattern {
  @override
  Iterable<Match> allMatches(String string, [int start = 0]) =>
      ','.allMatches(string, start);

  @override
  Match? matchAsPrefix(String string, [int start = 0]) =>
      ','.matchAsPrefix(string, start);
}

void main() {
  group('callAsync', () {
    test('without delay', () async {
      var order = <String>[];
      var f = callAsync(0, () {
        order.add('call');
        return 1;
      });
      order.add('sync');
      expect(await f, equals(1));
      expect(order, equals(['sync', 'call']));

      expect(await callAsync(-10, () => 'neg'), equals('neg'));
    });

    test('with delay', () async {
      var sw = Stopwatch()..start();
      var r = await callAsync(20, () => 'delayed');
      expect(r, equals('delayed'));
      expect(sw.elapsedMilliseconds, greaterThanOrEqualTo(15));
    });
  });

  group('query string', () {
    test('encodeQueryString', () {
      expect(encodeQueryString(null), equals(''));
      expect(encodeQueryString({}), equals(''));
      expect(
        encodeQueryString({'a': '1', 'b c': 'x&y=z', 'e': ''}),
        equals('a=1&b+c=x%26y%3Dz&e='),
      );
    });

    test('decodeQueryString', () {
      expect(decodeQueryString(null), equals({}));
      expect(decodeQueryString(''), equals({}));
      expect(
        decodeQueryString('a=1&&b+c=x%26y%3Dz&d&e='),
        equals({'a': '1', 'b c': 'x&y=z', 'd': '', 'e': ''}),
      );
      expect(decodeQueryString('a=1&a=2'), equals({'a': '2'}));
    });

    test('round trip', () {
      var params = {'q': 'hello world', 'x': 'á/é?', 'n': '1+1'};
      expect(decodeQueryString(encodeQueryString(params)), equals(params));
    });

    test('unescaped "=" in value', () {
      // Regression: the pair was split on every '=', so anything after a
      // second unescaped '=' in a value was dropped.
      expect(decodeQueryString('a=b=c'), equals({'a': 'b=c'}));
      expect(decodeQueryString('t=x==&k'), equals({'t': 'x==', 'k': ''}));
      expect(decodeQueryString('=v'), equals({'': 'v'}));
    });
  });

  group('case', () {
    test('toUpperCaseInitials', () {
      expect(toUpperCaseInitials(''), equals(''));
      expect(toUpperCaseInitials('a'), equals('A'));
      expect(
        toUpperCaseInitials('hello WORLD  foo\tbar'),
        equals('Hello World  Foo\tBar'),
      );
      expect(toUpperCaseInitials(' x'), equals(' X'));
    });

    test('toCamelCase', () {
      expect(toCamelCase(''), equals(''));
      expect(toCamelCase('hello big  WORLD'), equals('HelloBigWorld'));
      expect(toCamelCase(' a b '), equals('AB'));
    });
  });

  group('split', () {
    test('invalid delimiter type', () {
      expect(() => split('a,b', _CustomPattern()), throwsArgumentError);
    });

    test('limit with no matches', () {
      expect(split('abc', ',', 2), equals(['abc']));
      expect(split('abc', ',', 3), equals(['abc']));
      expect(split('abc', RegExp(r'\s*,\s*'), 2), equals(['abc']));
      expect(split('abc', RegExp(r','), 3), equals(['abc']));
    });

    test('RegExp delimiter', () {
      var re = RegExp(r'\s*;\s*');
      expect(split('a ; b;c ;d', re), equals(['a', 'b', 'c', 'd']));
      expect(split('a ; b;c ;d', re, 2), equals(['a', 'b;c ;d']));
      expect(split('a ; b;c ;d', re, 3), equals(['a', 'b', 'c ;d']));
      expect(split('a ; b;c ;d', re, -1), equals(['a', 'b', 'c', 'd']));
    });
  });

  group('Parameter', () {
    test('Parameter', () {
      var p = Parameter([1, 2]);
      expect(p.a, equals([1, 2]));
      expect(p == p, isTrue);
      expect(p, equals(Parameter([1, 2])));
      expect(p, isNot(equals(Parameter([1, 3]))));
      expect(p, isNot(equals([1, 2])));
      expect(p.hashCode, equals(Parameter([1, 2]).hashCode));
      expect(p.hashCode, equals(p.computeHashCode));
      expect(p.toString(), equals('Parameter{a: [1, 2]}'));

      var c = p.copy();
      expect(c, equals(p));
      expect(c.a, isNot(same(p.a)));
    });

    test('Parameters2', () {
      var p = Parameters2(1, ['b']);
      expect(p.b, equals(['b']));
      expect(p, equals(Parameters2(1, ['b'])));
      expect(p, isNot(equals(Parameters2(1, ['c']))));
      expect(p, isNot(equals(Parameters2(2, ['b']))));
      expect(p.toString(), equals('Parameters2{a: 1 ; b: [b]}'));
      expect(p.hashCode, equals(Parameters2(1, ['b']).hashCode));
      expect(p.computeHashCode2, equals(deepHashCode(['b'])));

      var c = p.copy();
      expect(c, equals(p));
      expect(c.b, isNot(same(p.b)));
    });

    test('Parameters3', () {
      var p = Parameters3(1, 'b', {'c': 3});
      expect(p.c, equals({'c': 3}));
      expect(p, equals(Parameters3(1, 'b', {'c': 3})));
      expect(p, isNot(equals(Parameters3(1, 'b', {'c': 4}))));
      expect(p.toString(), equals('Parameters3{a: 1 ; b: b ; c: {c: 3}}'));
      expect(p.hashCode, equals(Parameters3(1, 'b', {'c': 3}).hashCode));
      expect(p.computeHashCode3, equals(deepHashCode({'c': 3})));

      // Regression: `copy()` uses `deepCopy`, which rebuilt maps as
      // `Map<dynamic, dynamic>` and then cast them to the original type, so
      // copying a parameter holding a typed map (here `Map<String, int>`)
      // threw a TypeError.
      var pc = p.copy();
      expect(pc, equals(p));
      expect(pc.c, isA<Map<String, int>>());
      expect(pc.c, isNot(same(p.c)));

      var typedObj = Parameter(<String, Object>{
        'x': [1, 2],
        'y': <String, int>{'z': 1},
      });
      var typedObjCopy = typedObj.copy();
      expect(typedObjCopy, equals(typedObj));
      expect(typedObjCopy.a, isA<Map<String, Object>>());
      expect(typedObjCopy.a!['y'], isA<Map<String, int>>());
      expect(typedObjCopy.a!['y'], isNot(same(typedObj.a['y'])));

      var untyped = Parameters3(1, 'b', <dynamic, dynamic>{'c': 3});
      var c = untyped.copy();
      expect(c, equals(untyped));
      expect(c, equals(p));
      expect(c.c, isNot(same(untyped.c)));
    });

    test('Parameters4', () {
      var p = Parameters4(1, 'b', 3, [4]);
      expect(p.d, equals([4]));
      expect(p, equals(Parameters4(1, 'b', 3, [4])));
      expect(p, isNot(equals(Parameters4(1, 'b', 3, [5]))));
      expect(p.toString(), equals('Parameters4{a: 1 ; b: b ; c: 3 ; d: [4]}'));
      expect(p.hashCode, equals(Parameters4(1, 'b', 3, [4]).hashCode));
      expect(p.computeHashCode4, equals(deepHashCode([4])));

      var c = p.copy();
      expect(c, equals(p));
      expect(c.d, isNot(same(p.d)));
    });

    test('hashCode depends on all fields', () {
      // Regression: each subclass' `hashCode` XORed its extra field on top of
      // `super.hashCode`, which already included it via the overridden
      // `computeHashCode`, so the extra fields cancelled out and every
      // ParametersN hashed as `deepHashCode(a)`.
      var h = Parameter(1).hashCode;
      expect(h, equals(deepHashCode(1)));

      var p2 = Parameters2(1, 'x');
      expect(p2.hashCode, equals(deepHashCode(1) ^ deepHashCode('x')));
      expect(p2.hashCode, equals(p2.computeHashCode));
      expect(p2.hashCode, isNot(equals(Parameters2(1, 'y').hashCode)));

      var p3 = Parameters3(1, 'x', 'z');
      expect(p3.hashCode, equals(p3.computeHashCode));
      expect(p3.hashCode, isNot(equals(Parameters3(1, 'x', 'w').hashCode)));

      var p4 = Parameters4(1, 'x', 'z', 'q');
      expect(p4.hashCode, equals(p4.computeHashCode));
      expect(
        p4.hashCode,
        isNot(equals(Parameters4(1, 'x', 'z', 'r').hashCode)),
      );

      // Usable as Map keys:
      var m = {p2: 'p2', p3: 'p3', p4: 'p4'};
      expect(m[Parameters2(1, 'x')], 'p2');
      expect(m[Parameters3(1, 'x', 'z')], 'p3');
      expect(m[Parameters4(1, 'x', 'z', 'q')], 'p4');
    });

    test('equality is symmetric across arities', () {
      // Regression: `Parameter.==` only checked `other is Parameter` and `a`,
      // so `Parameter(1) == Parameters2(1, 2)` was true but not the reverse
      // (and their hash codes differed).
      expect(Parameter(1) == Parameters2(1, 2), isFalse);
      expect(Parameters2(1, 2) == Parameter(1), isFalse);
      expect(Parameters2(1, 2) == Parameters3(1, 2, 3), isFalse);
      expect(Parameters3(1, 2, 3) == Parameters2(1, 2), isFalse);
      expect(Parameters3(1, 2, 3) == Parameters4(1, 2, 3, 4), isFalse);
      expect(Parameters4(1, 2, 3, 4) == Parameters3(1, 2, 3), isFalse);

      // Same arity, different type arguments:
      expect(Parameter<num>(1) == Parameter<int>(1), isTrue);
      expect(Parameter<int>(1) == Parameter<num>(1), isTrue);
      expect(
        Parameters2<int, Object>(1, [2]) == Parameters2<num, List>(1, [2]),
        isTrue,
      );

      var set = {Parameter(1), Parameters2(1, 2)};
      expect(set.length, equals(2));
      expect(set.contains(Parameter(1)), isTrue);
      expect(set.contains(Parameters2(1, 2)), isTrue);
    });
  });

  group('CachedComputation', () {
    test('caches by value', () {
      var calls = <int>[];
      var cc = CachedComputation<int, int, int>((x) {
        calls.add(x);
        return x * 2;
      });

      expect(cc.cacheSize, equals(0));
      expect(cc.computationCount, equals(0));
      expect(cc.generateKey(5), equals(5));

      expect(cc.compute(2), equals(4));
      expect(cc.compute(2), equals(4));
      expect(cc.compute(3), equals(6));
      expect(cc.computationCount, equals(2));
      expect(cc.cacheSize, equals(2));
      expect(calls, equals([2, 3]));

      cc.clear();
      expect(cc.cacheSize, equals(0));
      expect(cc.compute(2), equals(4));
      expect(cc.computationCount, equals(3));
    });

    test('custom key generator', () {
      var cc = CachedComputation<int, String, String>(
        (s) => s.length,
        (s) => s.toLowerCase(),
      );
      expect(cc.compute('AB'), equals(2));
      expect(cc.compute('ab'), equals(2));
      expect(cc.computationCount, equals(1));
      expect(cc.generateKey('Xy'), equals('xy'));
    });

    test('null results are cached', () {
      // Regression: a cached `null` result was indistinguishable from a cache
      // miss, so it was recomputed every time.
      var cc = CachedComputation<int?, int, int>((x) => null);
      expect(cc.compute(1), isNull);
      expect(cc.compute(1), isNull);
      expect(cc.computationCount, equals(1));
      expect(cc.cacheSize, equals(1));

      // A `null` key (from a custom key generator) is cached too:
      var cc2 = CachedComputation<String?, int, int?>((x) => null, (x) => null);
      expect(cc2.compute(1), isNull);
      expect(cc2.compute(2), isNull);
      expect(cc2.computationCount, equals(1));
    });

    test('List values with the default key generator', () {
      // Regression: the default key generator deep-copies the value, but
      // `List` keys used identity equality in the cache `Map`, so List inputs
      // never hit the cache and the cache grew on every call.
      var cc = CachedComputation<int, List<int>, List<int>>((l) => l.length);
      var input = [1, 2];
      expect(cc.compute(input), equals(2));
      expect(cc.compute(input), equals(2));
      expect(cc.compute([1, 2]), equals(2));
      expect(cc.computationCount, equals(1));
      expect(cc.cacheSize, equals(1));

      // The key is a copy: changing the input after the computation doesn't
      // change the cached key.
      input.add(3);
      expect(cc.compute(input), equals(3));
      expect(cc.compute([1, 2]), equals(2));
      expect(cc.computationCount, equals(2));
      expect(cc.cacheSize, equals(2));
    });

    test('Map values with the default key generator', () {
      var cc = CachedComputation<int, Map<String, int>, Map<String, int>>(
        (m) => m.length,
      );
      expect(cc.compute({'a': 1}), equals(1));
      expect(cc.compute({'a': 1}), equals(1));
      expect(cc.compute({'a': 2}), equals(1));
      expect(cc.computationCount, equals(2));
      expect(cc.cacheSize, equals(2));
    });
  });
}
