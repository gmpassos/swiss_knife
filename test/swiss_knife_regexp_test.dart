import 'package:swiss_knife/swiss_knife.dart';
import 'package:test/test.dart';

void main() {
  group('RegExp helpers', () {
    test('parseRegExp/regExpHasMatch', () {
      expect(parseRegExp(null), isNull);
      var re = RegExp(r'\d');
      expect(parseRegExp(re), same(re));
      expect(parseRegExp(r'a+')!.pattern, equals('a+'));

      expect(regExpHasMatch(null, 'abc'), isFalse);
      expect(regExpHasMatch(r'b', 'abc'), isTrue);
      expect(regExpHasMatch(RegExp(r'^\d+$'), '12x'), isFalse);
    });

    test('regExpReplaceAll', () {
      expect(regExpReplaceAll(null, 'a1', 'x'), equals('a1'));
      expect(
        regExpReplaceAll(r'(\w)(\d)', 'a1 b2', r'${2}$1'),
        equals('1a 2b'),
      );
      expect(regExpReplaceAll(r'(\w)(\d)?', 'a', r'[$1$2]'), equals('[a]'));
      expect(regExpReplaceAll(r'\d', 'a1b2', '#'), equals('a#b#'));
    });

    test('regExpReplaceAllMapped', () {
      expect(regExpReplaceAllMapped(null, 'a1', (m) => 'x'), equals('a1'));
      expect(
        regExpReplaceAllMapped(r'\d+', 'a1b22', (m) => '<${m[0]}>'),
        equals('a<1>b<22>'),
      );
      expect(
        regExpReplaceAllMapped(RegExp(r'[aeiou]'), 'banana', (m) => '_'),
        equals('b_n_n_'),
      );
    });
  });

  group('RegExpDialect', () {
    test('words, word patterns and cache', () {
      var d = RegExpDialect({'n': r'\d+', 'pair': r'$n,$n'});

      expect(d.hasErrors, isFalse);
      expect(d.errorWords, isEmpty);
      expect(d.words, equals(['n', 'pair']));
      expect(d.getWordErrorMessage('n'), isNull);
      expect(d.getWordErrorPattern('n'), isNull);

      expect(d.getWordPattern(null), isNull);
      expect(d.getWordPattern('unknown'), isNull);

      var pair = d.getWordPattern('pair')!;
      expect(pair.pattern, equals(r'\d+,\d+'));
      expect(pair.hasMatch('12,3'), isTrue);
      expect(identical(d.getWordPattern('pair'), pair), isTrue);

      var p = d.getPattern(r'^$pair$');
      expect(p.pattern, equals(r'^\d+,\d+$'));
      expect(identical(d.getPattern(r'^$pair$'), p), isTrue);
      expect(p.hasMatch('1,2'), isTrue);
      expect(p.hasMatch('1,2,3'), isFalse);
    });

    test('escaped and unknown placeholders', () {
      var d = RegExpDialect({'a': 'A'});
      expect(d.getPattern(r'\$a').pattern, equals(r'\$a'));
      expect(d.getPattern(r'$a$zz').pattern, equals(r'A$zz'));
    });

    test('regExpDialect function with flags', () {
      var re = regExpDialect(
        {'w': '[a-z]+'},
        r'^$w$',
        multiLine: true,
        caseSensitive: false,
      );
      expect(re.isMultiLine, isTrue);
      expect(re.isCaseSensitive, isFalse);
      expect(re.hasMatch('123\nABC'), isTrue);
    });

    test('withParameters', () {
      var d = RegExpDialect({'w': 'ab'});

      expect(identical(d.withParameters(), d), isTrue);
      expect(
        identical(d.withParameters(multiLine: null, caseSensitive: null), d),
        isTrue,
      );

      var d2 = d.withParameters(caseSensitive: false);
      expect(identical(d2, d), isFalse);
      expect(d2.caseSensitive, isFalse);
      expect(d2.multiLine, isFalse);
      expect(d2.words, equals(['w']));
      expect(d2.getPattern(r'$w').isCaseSensitive, isFalse);
      expect(d2.getPattern(r'$w').hasMatch('AB'), isTrue);
      expect(d2.getWordPattern('w')!.hasMatch('AB'), isTrue);

      var d3 = d2.withParameters(multiLine: true, caseSensitive: null);
      expect(d3.multiLine, isTrue);
      expect(d3.caseSensitive, isFalse);
    });

    test('from', () {
      expect(RegExpDialect.from(null), isNull);
      expect(RegExpDialect.from('not a dialect'), isNull);

      var d = RegExpDialect({'w': 'ab'});
      expect(identical(RegExpDialect.from(d), d), isTrue);

      var d2 = RegExpDialect.from(d, multiLine: true)!;
      expect(identical(d2, d), isFalse);
      expect(d2.multiLine, isTrue);

      var d3 = RegExpDialect.from({'x': 1}, caseSensitive: false)!;
      expect(d3.words, equals(['x']));
      expect(d3.caseSensitive, isFalse);
      expect(d3.getWordPattern('x')!.pattern, equals('1'));
    });

    test('compilation errors', () {
      expect(
        () => RegExpDialect({'bad': '(', 'ok': 'a'}),
        throwsFormatException,
      );

      // `bad` is invalid alone, but `ref` (which wraps it) is valid.
      var d = RegExpDialect({
        'bad': '(a',
        'ref': r'$bad)',
        'ok': 'b',
      }, throwCompilationErrors: false);

      expect(d.hasErrors, isTrue);
      expect(d.errorWords, equals(['bad']));
      expect(d.getWordErrorMessage('bad'), isNotEmpty);
      expect(d.getWordErrorPattern('bad'), equals('(a'));
      expect(d.getWordErrorPattern('ok'), isNull);

      expect(() => d.getWordPattern('bad'), throwsStateError);
      expect(() => d.getWordPattern('ref'), throwsStateError);
      expect(d.getWordPattern('ok')!.pattern, equals('b'));

      expect(() => d.withParameters(multiLine: true), throwsStateError);
      expect(() => RegExpDialect.from(d, multiLine: true), throwsStateError);

      var d2 = d.withParameters(multiLine: true, throwCompilationErrors: false);
      expect(d2.multiLine, isTrue);
      // NOTE: current behaviour; possibly a bug: the copy made by
      // `withParameters` does not carry the compilation errors, so it reports
      // no errors and `getWordPattern` of a broken word fails with a raw
      // FormatException instead of the StateError the original throws.
      expect(d2.hasErrors, isFalse);
      expect(() => d2.getWordPattern('bad'), throwsFormatException);
    });
  });

  group('buildStringPattern/replaceStringMarks', () {
    test('buildStringPattern with key paths and extra parameters', () {
      expect(buildStringPattern(null, {}), isNull);

      expect(
        buildStringPattern('<{{/a/b/}}>', {
          'a': {'b': 'X'},
        }),
        equals('<X>'),
      );
      expect(buildStringPattern('{{/a}}{{a/}}!', {'a': 1}), equals('11!'));
      // Only a single leading/trailing slash is accepted by the placeholder:
      expect(buildStringPattern('{{//a}}', {'a': 1}), equals('{{//a}}'));

      expect(
        buildStringPattern(
          '{{x}}-{{y}}',
          {'x': 1},
          [
            null,
            {},
            {'y': 2},
            {'y': 3},
          ],
        ),
        equals('1-2'),
      );
      expect(buildStringPattern('{{z}}.', {'x': 1}, [null]), equals('.'));
    });

    test('replaceStringMarks', () {
      expect(replaceStringMarks(null, RegExp(r'%(\w+)%'), (m) => m), isNull);
      expect(
        replaceStringMarks(
          'a %x% b %y%',
          RegExp(r'%(\w+)%'),
          (m) => m.toUpperCase(),
        ),
        equals('a X b Y'),
      );
      expect(
        replaceStringMarks('none', RegExp(r'%(\w+)%'), (m) => '?'),
        equals('none'),
      );
    });
  });
}
