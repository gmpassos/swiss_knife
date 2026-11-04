import 'dart:async';
import 'dart:convert';

import 'package:resource_portable/resource.dart';
import 'package:swiss_knife/swiss_knife.dart';
import 'package:test/test.dart';

/// Builds a Spring Boot paging JSON string for [page] of [allItems].
String _springBootPageJson(List<Map<String, Object>> allItems, int page) {
  const pageSize = 2;
  var totalPages = (allItems.length / pageSize).ceil();
  var content = allItems.skip(page * pageSize).take(pageSize).toList();
  return encodeJSON({
    'totalPages': totalPages,
    'totalElements': allItems.length,
    'content': content,
    'size': content.length,
    'pageable': {
      'pageNumber': page,
      'offset': page * pageSize,
      'pageSize': pageSize,
    },
  });
}

final List<Map<String, Object>> _items = [
  {'id': 1, 'name': 'apple', 'category': 'fruit', 'price': 3},
  {'id': 2, 'name': 'carrot', 'category': 'vegetable', 'price': 2},
  {'id': 3, 'name': 'banana', 'category': 'fruit', 'price': 1},
  {'id': 4, 'name': 'leek', 'category': 'vegetable', 'price': 4},
  {'id': 5, 'name': 'cherry', 'category': 'fruit', 'price': 10},
];

/// In-memory HTTP-like loader: serves [pages] by URL.
class _ApiLoader extends ResourceLoader {
  final Map<String, String> pages;
  final List<String> requested = [];

  _ApiLoader(this.pages);

  @override
  Stream<List<int>> openRead(Uri uri) => Stream.fromFuture(readAsBytes(uri));

  @override
  Future<List<int>> readAsBytes(Uri uri) async =>
      utf8.encode(await readAsString(uri));

  @override
  Future<String> readAsString(Uri uri, {Encoding? encoding}) async {
    requested.add(uri.toString());
    var body = pages[uri.toString()];
    if (body == null) throw StateError('404: $uri');
    return body;
  }

  @override
  Uri parseUri(String s) => Uri.parse(s);

  @override
  Future<Uri> resolveUri(Uri uri) async => uri;
}

void main() {
  group('JSON -> paging -> collections', () {
    test('parse a page and process its elements', () {
      var jsonString = _springBootPageJson(_items, 0);
      expect(isEncodedJSONMap(jsonString), isTrue);

      var json = parseJSON(jsonString);
      expect(isJSONMap(json), isTrue);

      var paging = JSONPaging.from(json)!;
      expect(paging, isA<SpringBootPaging>());
      expect(paging.pagingFormat, equals('SpringBoot'));
      expect(paging.totalPages, equals(3));
      expect(paging.totalElements, equals(5));
      expect(paging.currentPage, equals(0));
      expect(paging.isFirstPage, isTrue);
      expect(paging.isLastPage, isFalse);
      expect(paging.needsPaging, isTrue);
      expect(paging.nextPage, equals(1));
      expect(paging.elementsLength, equals(2));
      expect(paging.elementsPerPage, equals(2));

      var elements = asListOfMap(paging.elements)!;
      expect(
        elements.map((e) => e['name']).toList(),
        equals(['apple', 'carrot']),
      );
      expect(
        listMatchesAll<Map>(elements, (e) => e.containsKey('price')),
        isTrue,
      );
      expect(sumIterable(elements.map((e) => e['price'] as num)), equals(5));
      expect(findKeyPathValue(json as Map, 'content/1/name'), equals('carrot'));
      expect(findKeyPathValue(json, 'PAGEABLE/pageSize'), equals(2));

      expect(
        paging.pagingRequestURL('http://api.example.com/items?size=2', 1),
        equals('http://api.example.com/items?size=2&page=1'),
      );
    });

    test('walk all pages with a pagingRequester and aggregate', () async {
      var pages = [for (var p = 0; p < 3; p++) _springBootPageJson(_items, p)];

      var requested = <int>[];

      JSONPaging? load(int page) {
        requested.add(page);
        var paging = JSONPaging.from(parseJSON(pages[page]));
        paging!.pagingRequester = (p) async => load(p);
        return paging;
      }

      var all = <Map>[];
      var paging = load(0)!;
      while (true) {
        all.addAll(asListOfMap(paging.elements)!);
        if (paging.isLastPage) break;
        paging = (await paging.requestNextPage())!;
      }

      expect(requested, equals([0, 1, 2]));
      expect(paging.currentPage, equals(2));
      expect(paging.nextPage, equals(2));
      // The last page returns itself:
      expect(await paging.requestNextPage(), same(paging));
      expect(all.length, equals(paging.totalElements));

      expect(isEqualsDeep(all, _items), isTrue);

      // Group names by category:
      var byCategory = groupIterableBy<String, List<String>, Map>(
        all,
        (e) => MapEntry(e['category'] as String, [e['name'] as String]),
        (k, a, b) => [...a, ...b],
      );
      expect(
        byCategory,
        equals({
          'fruit': ['apple', 'banana', 'cherry'],
          'vegetable': ['carrot', 'leek'],
        }),
      );

      // Prices by name, sorted by value (descending):
      var prices = <String, int>{
        for (var e in all) e['name'] as String: e['price'] as int,
      };
      var sorted = sortMapEntriesByValue(prices, true);
      expect(
        sorted.keys.toList(),
        equals(['cherry', 'leek', 'apple', 'carrot', 'banana']),
      );
      expect(maxInIterable(prices.values), equals(10));
      expect(minInIterable(prices.values), equals(1));
      expect(averageIterable(prices.values), equals(4));

      // Going back:
      var previous = (await paging.requestPreviousPage())!;
      expect(previous.currentPage, equals(1));
      expect(requested, equals([0, 1, 2, 1]));
    });

    test('Colossus paging round trip through encodeJSON', () {
      // A decoded JSON tree (dynamic collections):
      var original = parseJSON(
        '{"PAGE": 1, "ELEMENTS": [{"k": "a", "v": null}, {"k": "b", "v": 2}],'
        ' "SIZE": 2, "ELEMENTS_OFFSET": 2, "ELEMENTS_PER_PAGE": 2,'
        ' "TOTAL_ELEMENTS": 4, "TOTAL_PAGES": 2}',
      ) as Map<String, dynamic>;

      var copy = deepCopy<Map>(original)!;
      var encoded = encodeJSON(copy, clearNullEntries: true);
      // `clearNullEntries` mutated the copy, not the original:
      expect(
        (original['ELEMENTS'] as List).first,
        equals({'k': 'a', 'v': null}),
      );

      var paging = JSONPaging.from(parseJSON(encoded))!;
      expect(paging, isA<ColossusPaging>());
      expect(paging.isLastPage, isTrue);
      expect(paging.previousPage, equals(0));
      expect(
        paging.elements,
        equals([
          {'k': 'a'},
          {'k': 'b', 'v': 2},
        ]),
      );
      expect(
        paging.pagingRequestURL('http://h/db?--PAGE=0&q=x', 1),
        equals('http://h/db?--PAGE=1&q=x'),
      );
    });
  });

  group('Events driving data updates', () {
    test('EventStream of JSON patches updates a model', () async {
      var model = <String, Object?>{'count': 0, 'tags': <String>[]};
      var updates = EventStream<String>();
      var modelChanged = EventStream<Map<String, Object?>>();

      var snapshots = <Map>[];
      modelChanged.listen((m) => snapshots.add(deepCopy(m)!));

      // Only valid JSON maps are forwarded (the validator is captured when
      // `listen` is called, so it is set before):
      updates.eventValidator = (_, e) => isEncodedJSONMap(e);

      updates.listen((patchJson) {
        var patch = parseJSON(patchJson) as Map;
        for (var entry in patch.entries) {
          if (entry.key == 'tag') {
            (model['tags'] as List<String>).add(entry.value as String);
          } else {
            model[entry.key as String] = entry.value;
          }
        }
        modelChanged.add(model);
      });

      updates.add('{"count": 1}');
      updates.add('not json');
      updates.add('{"tag": "a"}');
      updates.add('{"count": 2, "tag": "b"}');
      await Future.delayed(Duration.zero);

      expect(
        model,
        equals({
          'count': 2,
          'tags': ['a', 'b'],
        }),
      );
      expect(snapshots.length, equals(3));
      expect(snapshots.first, equals({'count': 1, 'tags': []}));
      expect(
        snapshots.last,
        equals({
          'count': 2,
          'tags': ['a', 'b'],
        }),
      );

      await updates.close();
      await modelChanged.close();
    });

    test('InteractionCompleter batches updates into one save', () async {
      var saved = <String>[];
      var pending = <String, Object?>{};

      var completer = InteractionCompleter(
        'save',
        triggerDelay: Duration(milliseconds: 10),
        functionToTrigger: () {
          saved.add(encodeJSON(sortMapEntriesByKey(pending)));
          pending.clear();
        },
      );

      var edits = EventStream<MapEntry<String, Object?>>();
      edits.listen((e) {
        pending[e.key] = e.value;
        completer.interact(interactionParameters: [e.key]);
      });

      var done = completer.onComplete.first;

      edits.add(MapEntry('b', 2));
      edits.add(MapEntry('a', 1));
      edits.add(MapEntry('b', 3));

      await done;
      expect(saved, equals(['{"a":1,"b":3}']));
      expect(completer.lastInteractionParameters, equals(['b']));
      expect(pending, isEmpty);

      await edits.close();
    });

    test('AsyncValue of a JSON page feeds a paging view', () async {
      var loaded = <JSONPaging?>[];
      var av = AsyncValue<String>(
        Future.delayed(
          Duration(milliseconds: 1),
          () => _springBootPageJson(_items, 2),
        ),
      );
      av.onLoad.listen((s) => loaded.add(JSONPaging.from(parseJSON(s))));

      var jsonString = await av.future;
      await Future.delayed(Duration.zero);

      expect(av.isLoadedOK, isTrue);
      expect(loaded.length, equals(1));
      var paging = loaded.single!;
      expect(paging.isLastPage, isTrue);
      expect(paging.elements.single['name'], equals('cherry'));
      expect(parseJSON(jsonString)['totalElements'], equals(5));
    });
  });

  group('Resources -> JSON -> paging', () {
    test('load pages through a ResourceContentCache', () async {
      var base = 'http://api.example.com/items';
      var loader = _ApiLoader({
        for (var p = 0; p < 3; p++)
          '$base?page=$p': _springBootPageJson(_items, p),
      });

      var cache = ResourceContentCache();
      var onLoadEvents = <int>[];

      Future<JSONPaging?> requestPage(int page) async {
        var url = Uri.parse('$base?page=$page');
        var rc = cache.get(Resource(url, loader: loader))!;
        if (!rc.isLoaded) {
          rc.onLoad.listen((_) => onLoadEvents.add(page));
        }
        var paging = JSONPaging.from(parseJSON(await rc.getContent()));
        paging?.pagingRequester = requestPage;
        return paging;
      }

      var names = <String>[];
      var paging = (await requestPage(0))!;
      while (true) {
        names.addAll(paging.elements.map((e) => e['name'] as String));
        if (paging.isLastPage) break;
        paging = (await paging.requestNextPage())!;
      }

      expect(names, equals(['apple', 'carrot', 'banana', 'leek', 'cherry']));
      expect(cache.size, equals(3));
      expect(loader.requested.length, equals(3));

      // Re-requesting a page uses the cache (no new loader read):
      var again = (await requestPage(1))!;
      expect(again.currentPage, equals(1));
      expect(loader.requested.length, equals(3));

      await Future.delayed(Duration.zero);
      expect(onLoadEvents, equals([0, 1, 2]));

      // A missing page is a load error and parses to no paging:
      var missing = ResourceContent(
        Resource(Uri.parse('$base?page=9'), loader: loader),
      );
      expect(JSONPaging.from(parseJSON(await missing.getContent())), isNull);
      expect(missing.isLoadedWithError, isTrue);
    });

    test('relative page URLs resolved from the first resource', () async {
      var loader = _ApiLoader({
        'http://h/api/v1/page0.json': _springBootPageJson(_items, 0),
        'http://h/api/v1/page1.json': _springBootPageJson(_items, 1),
      });

      var first = ResourceContent(
        Resource(Uri.parse('http://h/api/v1/page0.json'), loader: loader),
      );
      var firstPaging = JSONPaging.from(parseJSON(await first.getContent()))!;

      var nextUri = (await first.resolveURL(
        'page${firstPaging.nextPage}.json',
      ))!;
      expect(nextUri.toString(), equals('http://h/api/v1/page1.json'));

      var next = ResourceContent(Resource(nextUri, loader: loader));
      var nextPaging = JSONPaging.from(parseJSON(await next.getContent()))!;
      expect(nextPaging.currentPage, equals(1));
      expect(nextPaging.elements.map((e) => e['id']).toList(), equals([3, 4]));
    });
  });
}
