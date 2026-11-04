import 'package:swiss_knife/swiss_knife.dart';
import 'package:test/test.dart';

int _c(String s) => s.codeUnitAt(0);

void main() {
  group('String (extra)', () {
    test('isDigit', () {
      for (var c in '0123456789'.split('')) {
        expect(isDigit(_c(c)), isTrue, reason: c);
      }
      for (var c in ['/', ':', 'a', 'Z', ' ', '_']) {
        expect(isDigit(_c(c)), isFalse, reason: c);
      }
    });

    test('isAlphaNumeric', () {
      for (var c in ['0', '5', '9', 'A', 'M', 'Z', 'a', 'm', 'z', '_']) {
        expect(isAlphaNumeric(_c(c)), isTrue, reason: c);
      }
      for (var c in [' ', '/', ':', '@', '[', '^', '`', '{', '-', '~', 'é']) {
        expect(isAlphaNumeric(_c(c)), isFalse, reason: c);
      }
    });

    test('isDigitString', () {
      expect(isDigitString('0123'), isTrue);
      expect(isDigitString(''), isFalse);
      expect(isDigitString('12a'), isFalse);
      expect(isDigitString('ab12', 2), isTrue);
      expect(isDigitString('12', 5), isFalse);
    });

    test('isDigitStringInRange', () {
      expect(isDigitStringInRange('a12b', 1, 2), isTrue);
      expect(isDigitStringInRange('a12b', 1, 3), isFalse);
      expect(isDigitStringInRange('a12', 1, 10), isTrue);
      expect(isDigitStringInRange('123', 0, 0), isFalse);
      expect(isDigitStringInRange('123', 0, -1), isFalse);
    });

    test('isAlphaNumericString', () {
      expect(isAlphaNumericString('abc_123XYZ'), isTrue);
      expect(isAlphaNumericString('abc-1'), isFalse);
      expect(isAlphaNumericString(''), isFalse);
      expect(isAlphaNumericString('--ab', 2), isTrue);
      expect(isAlphaNumericString('ab', 2), isFalse);
    });

    test('isAlphaNumericStringInRange', () {
      expect(isAlphaNumericStringInRange('a-b', 0, 1), isTrue);
      expect(isAlphaNumericStringInRange('a-b', 0, 2), isFalse);
      expect(isAlphaNumericStringInRange('-ab', 1, 10), isTrue);
      expect(isAlphaNumericStringInRange('ab', 0, 0), isFalse);
    });

    test('unquoteString', () {
      expect(unquoteString(''), equals(''));
      expect(unquoteString('"'), equals('"'));
      expect(unquoteString("'"), equals("'"));
      expect(unquoteString('""'), equals(''));
      expect(unquoteString('"abc"'), equals('abc'));
      expect(unquoteString("'abc'"), equals('abc'));
      expect(unquoteString('"a"b"'), equals('a"b'));
      expect(unquoteString('"abc\''), equals('"abc\''));
      expect(unquoteString('abc'), equals('abc'));
      expect(unquoteString(' "abc" '), equals(' "abc" '));
    });

    test('blank helpers', () {
      expect(isBlankCodeUnit(_c(' ')), isTrue);
      expect(isBlankCodeUnit(_c('\r')), isTrue);
      expect(isBlankCodeUnit(_c('x')), isFalse);
      expect(hasBlankChar('ab c'), isTrue);
      expect(hasBlankChar('abc'), isFalse);
      expect(hasBlankCharFrom('a bc', 2), isFalse);
      expect(hasBlankCharInRange('ab c', 0, 2), isFalse);
      expect(hasBlankCharInRange('ab c', 0, 10), isTrue);
      expect(isBlankString('  \t\n'), isTrue);
      expect(isBlankString('ab  ', 2), isTrue);
      expect(isBlankString(''), isFalse);
      expect(isBlankStringInRange(' a ', 0, 1), isTrue);
      expect(isBlankStringInRange(' a ', 0, 2), isFalse);
    });
  });
}
