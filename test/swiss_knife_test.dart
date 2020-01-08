
import 'package:test/test.dart';

import 'package:swiss_knife/swiss_knife.dart';

class Foo {

  bool get isOk => true ;

}

void main() {
  group('A group of tests', () {
    Foo awesome;

    setUp(() {
      awesome = new Foo();
    });

    test('Math Test', () {
      expect( Math.max(11, 22), equals(22));
      expect( Math.min(11, 22), equals(11));
    });
  });
}
