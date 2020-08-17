import 'package:swiss_knife/swiss_knife.dart';
import 'package:test/test.dart';

void main() {
  group('String', () {
    setUp(() {});

    test('isBlankChar', () async {
      expect(isBlankChar(' '), isTrue);
      expect(isBlankChar('\t'), isTrue);
      expect(isBlankChar('\n'), isTrue);
      expect(isBlankChar('\r'), isTrue);

      expect(isBlankChar(''), isFalse);
      expect(isBlankChar('a'), isFalse);
      expect(isBlankChar('_'), isFalse);
    });

    test('isNonBlankChar', () async {
      expect(isNonBlankChar(' '), isFalse);
      expect(isNonBlankChar('\t'), isFalse);
      expect(isNonBlankChar('\n'), isFalse);
      expect(isNonBlankChar('\r'), isFalse);

      expect(isNonBlankChar(''), isTrue);
      expect(isNonBlankChar('a'), isTrue);
      expect(isNonBlankChar('_'), isTrue);
    });

    test('isNotBlankCodeUnit', () async {
      expect(isNotBlankCodeUnit(' '.codeUnitAt(0)), isFalse);
      expect(isNotBlankCodeUnit('\t'.codeUnitAt(0)), isFalse);
      expect(isNotBlankCodeUnit('\n'.codeUnitAt(0)), isFalse);
      expect(isNotBlankCodeUnit('\r'.codeUnitAt(0)), isFalse);

      expect(isNotBlankCodeUnit('a'.codeUnitAt(0)), isTrue);
      expect(isNotBlankCodeUnit('_'.codeUnitAt(0)), isTrue);
    });

    test('hasBlankChar', () async {
      expect(hasBlankChar(''), isFalse);
      expect(hasBlankChar('abc'), isFalse);

      expect(hasBlankChar(' '), isTrue);
      expect(hasBlankChar('a b'), isTrue);
      expect(hasBlankChar('a\tb'), isTrue);
      expect(hasBlankChar('a\nb'), isTrue);
      expect(hasBlankChar('a\rb'), isTrue);
    });

    test('hasBlankChar', () async {
      expect(isBlankString(''), isFalse);
      expect(isBlankString('abc'), isFalse);

      expect(isBlankString('a b'), isFalse);
      expect(isBlankString('a\tb'), isFalse);
      expect(isBlankString('a\nb'), isFalse);
      expect(isBlankString('a\rb'), isFalse);

      expect(isBlankString(' '), isTrue);
      expect(isBlankString('   '), isTrue);
      expect(isBlankString('\t'), isTrue);
      expect(isBlankString('\t\t'), isTrue);

      expect(isBlankString('\n'), isTrue);
      expect(isBlankString('\n\n'), isTrue);

      expect(isBlankString('\r'), isTrue);
      expect(isBlankString('\r\r'), isTrue);

      expect(isBlankString(' \t\r\n'), isTrue);
    });
  });
}
