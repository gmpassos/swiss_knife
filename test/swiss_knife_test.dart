
import 'package:test/test.dart';

class Foo {

  bool get isOk => true ;

}

void main() {
  group('A group of tests', () {
    Foo awesome;

    setUp(() {
      awesome = new Foo();
    });

    test('First Test', () {
      expect(awesome.isOk, isTrue);
    });
  });
}
