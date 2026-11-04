@TestOn('vm')
library;

import 'dart:io';

import 'package:resource_portable/resource.dart';
import 'package:swiss_knife/swiss_knife.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('swiss_knife_integration_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  /// Writes a Colossus paging JSON file for each page of [items].
  List<File> writePages(List<Map<String, Object>> items, int perPage) {
    var totalPages = (items.length / perPage).ceil();
    var dir = Directory('${tempDir.path}/pages')..createSync();
    return [
      for (var page = 0; page < totalPages; page++)
        File('${dir.path}/page-$page.json')..writeAsStringSync(
          encodeJSON({
            'PAGE': page,
            'ELEMENTS': items.skip(page * perPage).take(perPage).toList(),
            'SIZE': items.skip(page * perPage).take(perPage).length,
            'ELEMENTS_OFFSET': page * perPage,
            'ELEMENTS_PER_PAGE': perPage,
            'TOTAL_ELEMENTS': items.length,
            'TOTAL_PAGES': totalPages,
          }, withIndent: true),
        ),
    ];
  }

  var users = [
    for (var i = 1; i <= 7; i++)
      {'id': i, 'name': 'user$i', 'active': i.isOdd, 'score': i * 10},
  ];

  test('load JSON pages from files, page through them and aggregate', () async {
    var files = writePages(users, 3);
    expect(files.length, equals(3));

    var cache = ResourceContentCache();
    var loadedUris = <Uri?>[];

    Future<JSONPaging?> loadPage(ResourceContent rc) async {
      var cached = cache.get(rc)!;
      if (!cached.isLoaded) {
        cached.onLoad.listen((_) => loadedUris.add(cached.uri));
      }
      var paging = JSONPaging.from(parseJSON(await cached.getContent()));
      if (paging != null) {
        // The next pages are resolved relative to the current file:
        paging.pagingRequester = (page) async {
          var uri = await cached.resolveURL('page-$page.json');
          return loadPage(ResourceContent.fromURI(uri)!);
        };
      }
      return paging;
    }

    var first = (await loadPage(ResourceContent.fromURI(files.first.uri)!))!;
    expect(first, isA<ColossusPaging>());
    expect(first.totalPages, equals(3));
    expect(first.needsPaging, isTrue);

    var all = <Map>[];
    var paging = first;
    while (true) {
      all.addAll(asListOfMap(paging.elements)!);
      if (paging.isLastPage) break;
      paging = (await paging.requestNextPage())!;
    }

    expect(paging.currentPage, equals(2));
    expect(paging.elementsLength, equals(1));
    expect(all.length, equals(7));
    expect(isEqualsDeep(all, users), isTrue);

    var activeScores = all
        .where((u) => u['active'] == true)
        .map((u) => u['score'] as num);
    expect(sumIterable(activeScores), equals(10 + 30 + 50 + 70));
    expect(averageIterable(activeScores), equals(40));

    expect(cache.size, equals(3));

    await Future.delayed(Duration.zero);
    expect(
      loadedUris.map((u) => u!.pathSegments.last).toList(),
      equals(['page-0.json', 'page-1.json', 'page-2.json']),
    );

    // Going back hits the cache, even if the file changed:
    files[1].writeAsStringSync('{"broken": true}');
    var previous = (await paging.requestPreviousPage())!;
    expect(previous.currentPage, equals(1));
    expect(
      previous.elements.map((e) => e['name']).toList(),
      equals(['user4', 'user5', 'user6']),
    );
    expect(cache.size, equals(3));
  });

  test('a missing next page file ends the paging with null', () async {
    var files = writePages(users, 4);
    files[1].deleteSync();

    var rc = ResourceContent.from(Resource(files.first.uri))!;
    var paging = JSONPaging.from(parseJSON(await rc.getContent()))!;

    paging.pagingRequester = (page) async {
      var next = ResourceContent.fromURI(
        await rc.resolveURL('page-$page.json'),
      )!;
      var content = await next.getContent();
      expect(next.isLoadedWithError, isTrue);
      return JSONPaging.from(parseJSON(content));
    };

    expect(paging.isLastPage, isFalse);
    expect(await paging.requestNextPage(), isNull);
  });

  test('file changes trigger reloads through events', () async {
    var file = File('${tempDir.path}/config.json')
      ..writeAsStringSync('{"version": 1, "features": ["a"]}');

    var rc = ResourceContent.fromURI(file.uri)!;
    var versions = <int>[];
    var reloadRequests = EventStream<String>();

    rc.onLoad.listen((content) {
      var json = parseJSON(content) as Map;
      versions.add(json['version'] as int);
    });

    reloadRequests.listen((_) async {
      rc.reset();
      await rc.load();
    });

    await rc.load();
    // `onLoad` events are delivered asynchronously:
    await Future.delayed(Duration.zero);
    expect(versions, equals([1]));

    file.writeAsStringSync('{"version": 2, "features": ["a", "b"]}');
    reloadRequests.add('changed');

    var config = await rc.onLoad.first;
    expect(parseJSON(config)['features'], equals(['a', 'b']));
    await Future.delayed(Duration.zero);
    expect(versions, equals([1, 2]));

    await reloadRequests.close();
  });
}
