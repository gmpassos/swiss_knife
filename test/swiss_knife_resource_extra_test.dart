@TestOn('vm')
library;

import 'dart:io';

import 'package:resource_portable/resource.dart';
import 'package:swiss_knife/swiss_knife.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('swiss_knife_resource_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  File writeFile(String name, String content) {
    var file = File('${tempDir.path}/$name');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
    return file;
  }

  group('ResourceContent (file system)', () {
    test('loads a real file', () async {
      var file = writeFile('hello.txt', 'Hello, World!');

      var rc = ResourceContent.from(Resource(file.uri))!;
      expect(rc.uri, equals(file.uri));
      expect(rc.uriFileExtension, equals('txt'));
      expect(rc.uriMimeType!.toString(), equals('text/plain'));
      expect(rc.isLoaded, isFalse);

      var events = <String?>[];
      rc.onLoad.listen(events.add);

      expect(await rc.getContent(), equals('Hello, World!'));
      expect(rc.isLoaded, isTrue);
      expect(rc.isLoadedWithError, isFalse);
      expect(rc.getContentIfLoaded(), equals('Hello, World!'));

      await Future.delayed(Duration.zero);
      expect(events, equals(['Hello, World!']));
    });

    test('loads UTF-8 content', () async {
      var file = writeFile('utf8.txt', 'Olá, açúcar — ✓');
      var rc = ResourceContent.fromURI(file.uri)!;
      expect(await rc.getContent(), equals('Olá, açúcar — ✓'));
    });

    test('loads by a file path string', () async {
      var file = writeFile('by_path.json', '{"a": 1}');

      var rc = ResourceContent.from(file.path)!;
      expect(rc.uri!.toFilePath(), equals(file.path));
      expect(rc.uriFileExtension, equals('json'));
      expect(await rc.getContent(), equals('{"a": 1}'));
      expect((await rc.uriResolved)!.toFilePath(), equals(file.path));
    });

    test('missing file is a load error', () async {
      var missing = File('${tempDir.path}/missing.txt');
      var rc = ResourceContent.fromURI(missing.uri)!;

      var events = <String?>[];
      rc.onLoad.listen(events.add);

      expect(await rc.getContent(), isNull);
      expect(rc.isLoaded, isTrue);
      expect(rc.isLoadedWithError, isTrue);
      expect(rc.hasContent, isFalse);

      await Future.delayed(Duration.zero);
      expect(events, equals([null]));

      // Once the file exists, a new `getContent` succeeds:
      missing.writeAsStringSync('created');
      expect(await rc.getContent(), equals('created'));
      expect(rc.isLoadedWithError, isFalse);
    });

    test('content is kept until reset', () async {
      var file = writeFile('changing.txt', 'v1');
      var rc = ResourceContent.fromURI(file.uri)!;

      expect(await rc.getContent(), equals('v1'));

      file.writeAsStringSync('v2');
      // Still the loaded content:
      expect(await rc.getContent(), equals('v1'));

      rc.reset();
      expect(rc.isLoaded, isFalse);
      expect(await rc.getContent(), equals('v2'));
    });

    test('resolveURL relative to a file', () async {
      var page = writeFile('site/pages/index.html', '<html></html>');
      var data = writeFile('site/pages/data/info.txt', 'INFO');
      var root = writeFile('site/root.txt', 'ROOT');

      var rc = ResourceContent.fromURI(page.uri)!;

      var dataUri = (await rc.resolveURL('data/info.txt'))!;
      expect(dataUri.toFilePath(), equals(data.path));
      expect(
        await ResourceContent.fromURI(dataUri)!.getContent(),
        equals('INFO'),
      );

      var dotUri = (await rc.resolveURL('./data/info.txt'))!;
      expect(dotUri, equals(dataUri));

      var upUri = (await ResourceContent.resolveURLFromReference(
        rc,
        './../root.txt',
      ))!;
      expect(upUri.normalizePath().toFilePath(), equals(root.path));
      expect(
        await ResourceContent.fromURI(upUri)!.getContent(),
        equals('ROOT'),
      );

      var absUri = (await rc.resolveURL(root.path))!;
      expect(absUri.toFilePath(), equals(root.path));
    });

    test('resolveURL without a reference uses the current directory', () async {
      var uri = (await ResourceContent.resolveURLFromReference(
        null,
        'some/file.txt',
      ))!;
      expect(uri.scheme, equals('file'));
      expect(
        uri.toFilePath(),
        equals('${Directory.current.absolute.path}/some/file.txt'),
      );
    });

    test('fromResolvedUrl with a file base', () async {
      var file = writeFile('base/a.txt', 'A');

      var rc = ResourceContent.fromResolvedUrl(
        'a.txt',
        baseURL: '${tempDir.uri}base/',
      )!;
      expect(rc.uri!.toFilePath(), equals(file.path));
      expect(await rc.getContent(), equals('A'));
    });
  });

  group('ResourceContentCache (file system)', () {
    test('caches by uri and shares the loaded content', () async {
      var file = writeFile('cached.txt', 'CACHED');

      var cache = ResourceContentCache();

      var rc1 = cache.get(file.uri)!;
      expect(cache.size, equals(1));
      expect(await rc1.getContent(), equals('CACHED'));

      // Same file by `Uri`, `Resource` and `ResourceContent`:
      expect(cache.get(file.uri), same(rc1));
      expect(cache.get(Resource(file.uri)), same(rc1));
      expect(cache.get(ResourceContent.fromURI(file.uri)), same(rc1));
      expect(cache.contains(file.uri), isTrue);
      expect(cache.size, equals(1));

      // Cached instance keeps its content even if the file changes:
      file.writeAsStringSync('CHANGED');
      expect(await cache.get(file.uri)!.getContent(), equals('CACHED'));

      // Removing forces a fresh instance:
      expect(cache.remove(file.uri), same(rc1));
      expect(cache.size, equals(0));
      var rc2 = cache.get(file.uri)!;
      expect(identical(rc2, rc1), isFalse);
      expect(await rc2.getContent(), equals('CHANGED'));

      cache.clear();
      expect(cache.size, equals(0));
    });

    test('multiple files', () async {
      var files = [
        for (var i = 0; i < 5; i++) writeFile('f$i.txt', 'content-$i'),
      ];

      var cache = ResourceContentCache();
      var contents = <String?>[];
      for (var f in files) {
        contents.add(await cache.get(f.uri)!.getContent());
      }

      expect(
        contents,
        equals([
          'content-0',
          'content-1',
          'content-2',
          'content-3',
          'content-4',
        ]),
      );
      expect(cache.size, equals(5));

      // All loaded instances are returned from the cache:
      for (var f in files) {
        expect(cache.get(f.uri)!.isLoaded, isTrue);
      }
    });

    test('a missing file is cached as a load error', () async {
      var cache = ResourceContentCache();
      var missing = File('${tempDir.path}/nope.txt');

      var rc = cache.get(missing.uri)!;
      expect(await rc.getContent(), isNull);
      expect(cache.get(missing.uri)!.isLoadedWithError, isTrue);
    });
  });
}
