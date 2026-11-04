import 'package:swiss_knife/swiss_knife.dart';
import 'package:test/test.dart';

Map<String, dynamic> _colossusJson({
  int page = 0,
  int? totalPages = 3,
  List elements = const [1, 2],
}) => {
  'PAGE': page,
  'ELEMENTS': elements,
  'SIZE': elements.length,
  'ELEMENTS_OFFSET': page * 2,
  'ELEMENTS_PER_PAGE': 2,
  'TOTAL_ELEMENTS': 6,
  'TOTAL_PAGES': ?totalPages,
};

Map<String, dynamic> _springBootJson({int page = 0, int totalPages = 3}) => {
  'totalPages': totalPages,
  'totalElements': 30,
  'content': ['a', 'b', 'c'],
  'size': 3,
  'pageable': {'pageNumber': page, 'offset': page * 10, 'pageSize': 10},
};

void main() {
  group('JSONPaging.from', () {
    test('null and unknown formats', () {
      expect(JSONPaging.from(null), isNull);
      expect(JSONPaging.from({'foo': 1}), isNull);
      expect(JSONPaging.from([1, 2, 3]), isNull);
      expect(JSONPaging.from('x'), isNull);
    });

    test('returns the same instance for a JSONPaging', () {
      var paging = ColossusPaging(_colossusJson());
      expect(JSONPaging.from(paging), same(paging));
    });

    test('detects Colossus format', () {
      var paging = JSONPaging.from(_colossusJson(page: 1))!;
      expect(paging, isA<ColossusPaging>());
      expect(paging.pagingFormat, equals('Colossus'));
      expect(paging.isOfPagingFormat('colossus'), isTrue);
      expect(paging.isOfPagingFormat(' COLOSSUS '), isTrue);
      expect(paging.isOfPagingFormat('SpringBoot'), isFalse);
      expect(paging.isOfPagingFormat(''), isFalse);
      expect(paging.isOfPagingFormat(null), isFalse);
    });

    test('detects SpringBoot format', () {
      var paging = JSONPaging.from(_springBootJson())!;
      expect(paging, isA<SpringBootPaging>());
      expect(paging.isOfPagingFormat('springboot'), isTrue);
    });

    test('SpringBoot requires a non-empty pageable', () {
      var json = _springBootJson()..['pageable'] = {};
      expect(SpringBootPaging.matches(json), isFalse);
      expect(SpringBootPaging.matches('x'), isFalse);
      expect(ColossusPaging.matches('x'), isFalse);
    });

    test('registerPagingFormat', () {
      JSONPaging.registerPagingFormat(
        (json) => json is Map && json.containsKey('__custom_paging__'),
        (json) => ColossusPaging({
          ..._colossusJson(page: 2),
          ...(json as Map).cast<String, dynamic>(),
        }),
      );

      var paging = JSONPaging.from({'__custom_paging__': true})!;
      expect(paging, isA<ColossusPaging>());
      expect(paging.currentPage, equals(2));
    });
  });

  group('ColossusPaging', () {
    test('getters', () {
      var paging = ColossusPaging(_colossusJson(page: 1, elements: [3, 4]));

      expect(paging.json['PAGE'], equals(1));
      expect(paging['PAGE'], equals(1));
      expect(paging.currentPage, equals(1));
      expect(paging.elements, equals([3, 4]));
      expect(paging.elementsEntryKey, equals('ELEMENTS'));
      expect(paging.elementsLength, equals(2));
      expect(paging.elementsOffset, equals(2));
      expect(paging.elementsPerPage, equals(2));
      expect(paging.totalElements, equals(6));
      expect(paging.totalPages, equals(3));
    });

    test('page navigation', () {
      var first = ColossusPaging(_colossusJson(page: 0));
      expect(first.isFirstPage, isTrue);
      expect(first.isLastPage, isFalse);
      expect(first.previousPage, equals(0));
      expect(first.nextPage, equals(1));
      expect(first.needsPaging, isTrue);

      var middle = ColossusPaging(_colossusJson(page: 1));
      expect(middle.isFirstPage, isFalse);
      expect(middle.isLastPage, isFalse);
      expect(middle.previousPage, equals(0));
      expect(middle.nextPage, equals(2));

      var last = ColossusPaging(_colossusJson(page: 2));
      expect(last.isLastPage, isTrue);
      expect(last.nextPage, equals(2));
      expect(last.previousPage, equals(1));
    });

    test('unknown total pages', () {
      var paging = ColossusPaging(_colossusJson(page: 4, totalPages: null));
      expect(paging.totalPages, isNull);
      expect(paging.isLastPage, isFalse);
      expect(paging.nextPage, equals(5));
      expect(paging.needsPaging, isFalse);
    });

    test('single page does not need paging', () {
      var paging = ColossusPaging(_colossusJson(page: 0, totalPages: 1));
      expect(paging.needsPaging, isFalse);
      expect(paging.isFirstPage, isTrue);
      expect(paging.isLastPage, isTrue);
    });

    test('pagingRequestURL', () {
      var paging = ColossusPaging(_colossusJson());

      expect(
        Uri.parse(paging.pagingRequestURL('http://host:8080/path?q=x', 3))
            .queryParameters,
        equals({'q': 'x', '--PAGE': '3'}),
      );

      var url = paging.pagingRequestURL('http://host/path?-PAGE=1', 2);
      var uri = Uri.parse(url);
      expect(uri.host, equals('host'));
      expect(uri.path, equals('/path'));
      expect(uri.queryParameters, equals({'-PAGE': '2'}));
    });

    test('requestPage without requester', () async {
      var paging = ColossusPaging(_colossusJson());
      expect(paging.pagingRequester, isNull);
      expect(await paging.requestPage(1), isNull);
      expect(await paging.requestNextPage(), isNull);
      // First page: returns itself.
      expect(await paging.requestPreviousPage(), same(paging));
    });

    test('requestPage with requester', () async {
      var requested = <int>[];

      Future<JSONPaging?> requester(int page) async {
        requested.add(page);
        var p = ColossusPaging(_colossusJson(page: page));
        return p;
      }

      var middle = ColossusPaging(_colossusJson(page: 1))
        ..pagingRequester = requester;

      expect((await middle.requestNextPage())!.currentPage, equals(2));
      expect((await middle.requestPreviousPage())!.currentPage, equals(0));
      expect((await middle.requestPage(1))!.currentPage, equals(1));
      expect(requested, equals([2, 0, 1]));

      var last = ColossusPaging(_colossusJson(page: 2))
        ..pagingRequester = requester;
      expect(await last.requestNextPage(), same(last));
      expect(requested, equals([2, 0, 1]));
    });
  });

  group('SpringBootPaging', () {
    test('getters', () {
      var paging = SpringBootPaging(_springBootJson(page: 1));

      expect(paging.currentPage, equals(1));
      expect(paging.elements, equals(['a', 'b', 'c']));
      expect(paging.elementsEntryKey, equals('content'));
      expect(paging.elementsLength, equals(3));
      expect(paging.elementsOffset, equals(10));
      expect(paging.elementsPerPage, equals(10));
      expect(paging.totalElements, equals(30));
      expect(paging.totalPages, equals(3));
      expect(paging.pagingFormat, equals('SpringBoot'));
      expect(paging.isFirstPage, isFalse);
      expect(paging.isLastPage, isFalse);
      expect(paging.nextPage, equals(2));
      expect(paging.previousPage, equals(0));
    });

    test('pagingRequestURL', () {
      var paging = SpringBootPaging(_springBootJson());

      expect(
        Uri.parse(
          paging.pagingRequestURL('https://host/api/items?sort=name', 4),
        ).queryParameters,
        equals({'sort': 'name', 'page': '4'}),
      );

      expect(
        Uri.parse(paging.pagingRequestURL('https://host/api/items?page=1', 2))
            .queryParameters,
        equals({'page': '2'}),
      );
    });
  });
}
