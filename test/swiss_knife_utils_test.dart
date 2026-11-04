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

      // NOTE: current behaviour; possibly a bug: `copy()` uses `deepCopy`,
      // which rebuilds maps as `Map<dynamic, dynamic>` and then casts to the
      // original type (collections.dart `deepCopy`), so copying a parameter
      // holding a typed map (here `Map<String, int>`) throws a TypeError.
      expect(p.copy, throwsA(isA<TypeError>()));

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

    test('equality is asymmetric across arities', () {
      // NOTE: current behaviour; possibly a bug: `Parameter.==` only checks
      // `other is Parameter` and `a`, so it is not symmetric with subclasses.
      expect(Parameter(1) == Parameters2(1, 2), isTrue);
      expect(Parameters2(1, 2) == Parameter(1), isFalse);
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

    test('null results are not cached', () {
      // NOTE: current behaviour; possibly a bug: a cached `null` result is
      // indistinguishable from a cache miss, so it is recomputed every time.
      var cc = CachedComputation<int?, int, int>((x) => null);
      expect(cc.compute(1), isNull);
      expect(cc.compute(1), isNull);
      expect(cc.computationCount, equals(2));
      expect(cc.cacheSize, equals(1));
    });

    test('List values with the default key generator', () {
      // NOTE: current behaviour; possibly a bug: the default key generator
      // deep-copies the value, but `List` keys use identity equality in the
      // cache `Map`, so List inputs never hit the cache and the cache grows on
      // every call.
      var cc = CachedComputation<int, List<int>, List<int>>((l) => l.length);
      var input = [1, 2];
      expect(cc.compute(input), equals(2));
      expect(cc.compute(input), equals(2));
      expect(cc.computationCount, equals(2));
      expect(cc.cacheSize, equals(2));
    });
  });
}
