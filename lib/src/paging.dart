import 'collections.dart';

typedef PagingFormatMatcher = bool Function(dynamic json);
typedef PagingFormatInstantiator = JSONPaging Function(dynamic json);

/// A Function that performs a paging request.
///
/// [page] the page of the request.
typedef PagingRequester = Future<JSONPaging> Function(int page);

/// Generic representation of a paging result in JSON.
abstract class JSONPaging extends MapDelegate<String, dynamic> {
  static final Map<PagingFormatMatcher, PagingFormatInstantiator>
      _pagingFormats = {};

  static void registerPagingFormat(
      PagingFormatMatcher matcher, PagingFormatInstantiator instantiator) {
    _registerPagingFormats();

    _registerPagingFormatImpl(matcher, instantiator);
  }

  static void _registerPagingFormatImpl(
      PagingFormatMatcher matcher, PagingFormatInstantiator instantiator) {
    _pagingFormats[matcher] = instantiator;
  }

  factory JSONPaging.from(dynamic json) {
    if (json == null) return null;

    _registerPagingFormats();

    if (json is JSONPaging) return json;

    for (var entry in _pagingFormats.entries) {
      var matcher = entry.key;

      if (matcher(json)) {
        var instantiator = entry.value;
        return instantiator(json);
      }
    }

    return null;
  }

  JSONPaging(Map<String, dynamic> json) : super(json);

  Map<String, dynamic> get json => mainMap;

  /// Total number of pages.
  int get totalPages;

  /// Total elements of request.
  int get totalElements;

  /// Current page index, starting from 0.
  int get currentPage;

  /// Elements in this page.
  List<dynamic> get elements;

  /// The json key for elements.
  String get elementsEntryKey;

  /// The offset of elements for the request.
  int get elementsOffset;

  /// Current page elements length.
  int get elementsLength;

  /// Number of elements used for paging.
  int get elementsPerPage;

  /// Returns [true] if this is the last page.
  bool get isLastPage => currentPage == totalPages - 1;

  /// Returns [true] if this is the first page.
  bool get isFirstPage => currentPage == 0;

  /// The index of the previous page.
  ///
  /// If this is the first page, returns 0 (the current page index).
  int get previousPage {
    var page = currentPage;
    return page > 0 ? page - 1 : 0;
  }

  /// Next page index.
  ///
  /// If this is the last page returns the last page index (the current page index).
  int get nextPage {
    var page = currentPage;
    var lastPageIndex = totalPages - 1;
    return page < lastPageIndex ? page + 1 : lastPageIndex;
  }

  /// If needs a paging controller.
  ///
  /// If [totalPages] is 1, returns false.
  bool get needsPaging => totalPages != 1;

  /// Paging implementation format/name.
  String get pagingFormat;

  /// Returns [true] if [format] is the same of current [pagingFormat].
  bool isOfPagingFormat(String format) {
    if (format == null || format.isEmpty) return false;
    var myFormat = pagingFormat;
    return myFormat.trim().toLowerCase() == format.trim().toLowerCase();
  }

  /// Requesting Function that is able to make new requests to a specific page.
  /// See [PagingRequester].
  PagingRequester pagingRequester;

  /// The url for a request using [url] and [page] to build.
  String pagingRequestURL(String url, int page);

  Future<JSONPaging> requestPage(int page) {
    if (pagingRequester == null) return null;
    return pagingRequester(page);
  }

  /// Requests next page.
  /// If [isLastPage] returns [this].
  Future<JSONPaging> requestNextPage() async {
    if (isLastPage) return this;
    return requestPage(nextPage);
  }

  /// Requests the previous page.
  /// If [isFirstPage] returns [this].
  Future<JSONPaging> requestPreviousPage() async {
    if (isFirstPage) return this;
    return requestPage(previousPage);
  }
}

/// Implementation for Colossus.services DB and Nodes.
class ColossusPaging extends JSONPaging {
  static final PagingFormatMatcher MATCHER = matches;

  static final PagingFormatInstantiator INSTANTIATOR =
      (json) => ColossusPaging(json);

  static bool matches(dynamic json) {
    if (isMapOfStringKeys(json)) {
      var map = (json as Map).cast<String, dynamic>();

      return map.containsKey('PAGE') &&
          map.containsKey('TOTAL_PAGES') &&
          map.containsKey('ELEMENTS') &&
          map.containsKey('SIZE') &&
          map.containsKey('ELEMENTS_OFFSET') &&
          map.containsKey('ELEMENTS_PER_PAGE') &&
          map.containsKey('TOTAL_ELEMENTS');
    }
    return false;
  }

  ColossusPaging(Map<String, dynamic> json) : super(json);

  @override
  int get currentPage => json['PAGE'];

  @override
  List get elements => json['ELEMENTS'];

  @override
  String get elementsEntryKey => 'ELEMENTS';

  @override
  int get elementsLength => json['SIZE'];

  @override
  int get elementsOffset => json['ELEMENTS_OFFSET'];

  @override
  int get elementsPerPage => json['ELEMENTS_PER_PAGE'];

  @override
  int get totalElements => json['TOTAL_ELEMENTS'];

  @override
  int get totalPages => json['TOTAL_PAGES'];

  @override
  String get pagingFormat => 'Colossus';

  @override
  String pagingRequestURL(String url, int page) {
    var uri = Uri.parse(url);

    var queryParameters =
        (Map.from(uri.queryParametersAll) ?? <String, dynamic>{})
            .cast<String, dynamic>();

    var pageEntry = findKeyEntry(queryParameters, ['-PAGE', '--PAGE']);

    if (pageEntry != null) {
      queryParameters[pageEntry.key] = '$page';
    } else {
      queryParameters['--PAGE'] = '$page';
    }

    return Uri(
            scheme: uri.scheme,
            userInfo: uri.userInfo,
            host: uri.host,
            port: uri.port,
            path: uri.path,
            queryParameters: queryParameters)
        .toString();
  }
}

/// Implementation for Spring Boot.
class SpringBootPaging extends JSONPaging {
  static final PagingFormatMatcher MATCHER = matches;

  static final PagingFormatInstantiator INSTANTIATOR =
      (json) => SpringBootPaging(json);

  static bool matches(dynamic json) {
    if (isMapOfStringKeys(json)) {
      var map = (json as Map).cast<String, dynamic>();

      var pageable = map['pageable'];
      if (!(pageable is Map && pageable.isNotEmpty)) return false;

      return map.containsKey('totalPages') &&
          map.containsKey('totalElements') &&
          map.containsKey('content') &&
          map.containsKey('size') &&
          pageable.containsKey('pageNumber') &&
          pageable.containsKey('offset') &&
          pageable.containsKey('pageSize');
    }
    return false;
  }

  SpringBootPaging(Map<String, dynamic> json) : super(json);

  @override
  int get currentPage => json['pageable']['pageNumber'];

  @override
  List get elements => json['content'];

  @override
  String get elementsEntryKey => 'content';

  @override
  int get elementsLength => json['size'];

  @override
  int get elementsOffset => json['pageable']['offset'];

  @override
  int get elementsPerPage => json['pageable']['pageSize'];

  @override
  int get totalElements => json['totalElements'];

  @override
  int get totalPages => json['totalPages'];

  @override
  String get pagingFormat => 'SpringBoot';

  @override
  String pagingRequestURL(String url, int page) {
    var uri = Uri.parse(url);

    var queryParameters =
        (uri.queryParametersAll ?? {}).cast<String, dynamic>();

    var pageEntry = findKeyEntry(queryParameters, ['page']);

    if (pageEntry != null) {
      queryParameters[pageEntry.key] = '$page';
    } else {
      queryParameters['page'] = '$page';
    }

    return Uri(
            scheme: uri.scheme,
            userInfo: uri.userInfo,
            host: uri.host,
            port: uri.port,
            path: uri.path,
            queryParameters: queryParameters)
        .toString();
  }
}

bool _registerPagingFormatsCalled = false;

bool _registerPagingFormats() {
  if (_registerPagingFormatsCalled) return false;
  _registerPagingFormatsCalled = true;

  JSONPaging._registerPagingFormatImpl(
      ColossusPaging.MATCHER, ColossusPaging.INSTANTIATOR);
  JSONPaging._registerPagingFormatImpl(
      SpringBootPaging.MATCHER, SpringBootPaging.INSTANTIATOR);

  return true;
}
