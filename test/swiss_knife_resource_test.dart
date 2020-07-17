import 'dart:convert';

import 'package:resource_portable/resource.dart';
import 'package:swiss_knife/swiss_knife.dart';
import 'package:test/test.dart';

class MyResourceLoader extends ResourceLoader {
  @override
  Stream<List<int>> openRead(Uri uri) {
    return Stream.fromFuture(readAsBytes(uri));
  }

  @override
  Future<List<int>> readAsBytes(Uri uri) async {
    var str = await readAsString(uri);
    return str.codeUnits;
  }

  @override
  Future<String> readAsString(Uri uri, {Encoding encoding}) async {
    return uri.toString().split('://')[1];
  }
}

void main() {
  group('Resource', () {
    setUp(() {});

    test('ResourceContent', () async {
      var loader = MyResourceLoader();
      var resourceContent =
          ResourceContent.from(Resource('test://foo', loader: loader));

      expect(resourceContent.isLoaded, isFalse);

      expect(await resourceContent.getContent(), 'foo');

      expect(resourceContent.isLoaded, isTrue);
      expect(resourceContent.isLoadedWithError, isFalse);
    });
  });

  test('ResourceContent.resolveURLFromReference', () async {
    var loader = MyResourceLoader();
    var resourceContent = ResourceContent.from(
        Resource('http://localhost/path/file.txt', loader: loader));

    expect(
        (await ResourceContent.resolveURLFromReference(
                resourceContent, 'file2.txt'))
            .toString(),
        equals('http://localhost/path/file2.txt'));
    expect(
        (await ResourceContent.resolveURLFromReference(
                resourceContent, './file2.txt'))
            .toString(),
        equals('http://localhost/path/file2.txt'));
    expect(
        (await ResourceContent.resolveURLFromReference(
                resourceContent, './../file2.txt'))
            .toString(),
        equals('http://localhost/file2.txt'));
    expect(
        (await ResourceContent.resolveURLFromReference(
                resourceContent, '/file2.txt'))
            .toString(),
        equals('http://localhost/file2.txt'));

    expect(
        (await ResourceContent.resolveURLFromReference(
                resourceContent, 'http://localhost2/path/file.txt'))
            .toString(),
        equals('http://localhost2/path/file.txt'));
  });

  test('ResourceContentCache', () async {
    var loader = MyResourceLoader();

    var cache = ResourceContentCache();

    var resourceContent =
        ResourceContent.from(Resource('test://foo', loader: loader));

    expect(resourceContent.isLoaded, isFalse);

    var resourceContentCached = cache.get(resourceContent);

    expect(await resourceContentCached.getContent(), 'foo');

    expect(resourceContent.isLoaded, isTrue);
    expect(resourceContent.isLoadedWithError, isFalse);

    var resourceContent2 =
        ResourceContent.from(Resource('test://foo', loader: loader));

    expect(resourceContent, equals(resourceContent2));

    expect(identical(resourceContent, resourceContent2), isFalse);

    var resourceContentCached2 = cache.get(resourceContent);

    expect(identical(resourceContent, resourceContentCached2), isTrue);
  });
}
