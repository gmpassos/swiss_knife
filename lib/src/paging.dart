
import 'collections.dart';


typedef PagingFormatMatcher = bool Function(dynamic json) ;
typedef PagingFormatInstantiator = JSONPaging Function(dynamic json) ;

typedef PagingRequester = Future<JSONPaging> Function(int page) ;

abstract class JSONPaging extends MapDelegate<String, dynamic> {

  static final Map<PagingFormatMatcher, PagingFormatInstantiator> _pagingFormats = {} ;

  static void registerPagingFormat(PagingFormatMatcher matcher, PagingFormatInstantiator instantiator) {
    _registerPagingFormats();

    _registerPagingFormatImpl(matcher, instantiator) ;
  }

  static void _registerPagingFormatImpl(PagingFormatMatcher matcher, PagingFormatInstantiator instantiator) {
    _pagingFormats[matcher] = instantiator ;
  }

  factory JSONPaging.from(dynamic json) {
    if (json == null) return null ;

    _registerPagingFormats();

    if (json is JSONPaging) return json ;

    for (var entry in _pagingFormats.entries) {
      var matcher = entry.key ;

      if ( matcher(json) ) {
        var instantiator = entry.value ;
        return instantiator(json) ;
      }
    }

    return null ;
  }

  JSONPaging( Map<String, dynamic> json ) : super(json) ;

  Map<String, dynamic> get json => mainMap ;

  int get totalPages ;

  int get totalElements ;

  int get currentPage ;

  List<dynamic> get elements ;

  String get elementsEntryKey ;

  int get elementsOffset ;

  int get elementsLength ;

  int get elementsPerPage ;

  bool get isLastPage => currentPage == totalPages-1 ;

  bool get isFirstPage => currentPage == 0 ;

  int get previousPage {
    var page = currentPage ;
    return page > 0 ? page-1 : 0 ;
  }

  int get nextPage {
    var page = currentPage ;
    var lastPageIndex = totalPages-1;
    return page < lastPageIndex ? page+1 : lastPageIndex ;
  }

  bool get needsPaging => totalPages != 1 ;

  String get pagingFormat ;

  bool isOfPagingFormat(String format) {
    if (format == null || format.isEmpty) return false ;
    var myFormat = pagingFormat ;
    return myFormat.trim().toLowerCase() == format.trim().toLowerCase() ;
  }

  PagingRequester _pagingRequester ;

  PagingRequester get pagingRequester => _pagingRequester ;

  set pagingRequester(PagingRequester value) {
    _pagingRequester = value;
  }

  String pagingRequestURL(String url, int page) ;

  Future<JSONPaging> requestPage(int page) {
    if ( _pagingRequester == null ) return null ;
    return _pagingRequester(page) ;
  }


  Future<JSONPaging> requestNextPage() async {
    if ( isLastPage ) return this ;
    return requestPage(nextPage) ;
  }

  Future<JSONPaging> requestPreviousPage() async {
    if ( isFirstPage ) return this ;
    return requestPage(previousPage) ;
  }

}

class ColossusPaging extends JSONPaging {

  static final PagingFormatMatcher MATCHER = matches ;
  static final PagingFormatInstantiator INSTANTIATOR = (json) => ColossusPaging(json) ;

  static bool matches(dynamic json) {
    if ( isMapOfStringKeys(json) ) {
      var map = (json as Map).cast<String,dynamic>() ;

      return
            map.containsKey('PAGE') &&
            map.containsKey('TOTAL_PAGES') &&
            map.containsKey('ELEMENTS') &&
            map.containsKey('SIZE') &&
            map.containsKey('ELEMENTS_OFFSET') &&
            map.containsKey('ELEMENTS_PER_PAGE') &&
            map.containsKey('TOTAL_ELEMENTS')
      ;
    }
    return false ;
  }

  ColossusPaging(Map<String, dynamic> json) : super(json);

  @override
  int get currentPage => json['PAGE'] ;

  @override
  List get elements => json['ELEMENTS'] ;

  @override
  String get elementsEntryKey => 'ELEMENTS' ;

  @override
  int get elementsLength => json['SIZE'] ;

  @override
  int get elementsOffset => json['ELEMENTS_OFFSET'] ;

  @override
  int get elementsPerPage => json['ELEMENTS_PER_PAGE'] ;

  @override
  int get totalElements => json['TOTAL_ELEMENTS'] ;

  @override
  int get totalPages => json['TOTAL_PAGES'] ;

  @override
  String get pagingFormat => 'Colossus' ;

  @override
  String pagingRequestURL(String url, int page) {
    Uri uri = Uri.parse(url) ;

    Map<String,dynamic> queryParameters = ( Map.from(uri.queryParametersAll) ?? {} ).cast() ;

    var pageEntry = findKeyEntry(queryParameters, ['-PAGE','--PAGE']) ;

    if ( pageEntry != null ) {
      queryParameters[ pageEntry.key ] = '$page' ;
    }
    else {
      queryParameters['--PAGE'] = '$page' ;
    }

    return Uri( scheme: uri.scheme, userInfo: uri.userInfo, host: uri.host, port: uri.port, path: uri.path , queryParameters: queryParameters ).toString() ;
  }

}


class SpringBootPaging extends JSONPaging {

  static final PagingFormatMatcher MATCHER = matches ;
  static final PagingFormatInstantiator INSTANTIATOR = (json) => SpringBootPaging(json) ;

  static bool matches(dynamic json) {
    if ( isMapOfStringKeys(json) ) {
      var map = (json as Map).cast<String, dynamic>();

      var pageable = map['pageable'] ;
      if ( !( pageable is Map && pageable.isNotEmpty ) ) return false ;

      return
            map.containsKey('totalPages') &&
            map.containsKey('totalElements') &&
            map.containsKey('content') &&
            map.containsKey('size') &&
            pageable.containsKey('pageNumber') &&
            pageable.containsKey('offset') &&
            pageable.containsKey('pageSize')
      ;
    }
    return false ;
  }

  SpringBootPaging(Map<String, dynamic> json) : super(json);

  @override
  int get currentPage => json['pageable']['pageNumber'] ;

  @override
  List get elements => json['content'] ;

  @override
  String get elementsEntryKey => 'content' ;

  @override
  int get elementsLength => json['size'] ;

  @override
  int get elementsOffset => json['pageable']['offset'] ;

  @override
  int get elementsPerPage => json['pageable']['pageSize'] ;

  @override
  int get totalElements => json['totalElements'] ;

  @override
  int get totalPages => json['totalPages'] ;

  @override
  String get pagingFormat => 'SpringBoot' ;

  @override
  String pagingRequestURL(String url, int page) {
    Uri uri = Uri.parse(url) ;

    var queryParameters = ( uri.queryParametersAll ?? {} ).cast<String,dynamic>() ;

    var pageEntry = findKeyEntry(queryParameters, ['page']) ;

    if ( pageEntry != null ) {
      queryParameters[ pageEntry.key ] = '$page' ;
    }
    else {
      queryParameters['page'] = '$page' ;
    }

    return Uri( scheme: uri.scheme, userInfo: uri.userInfo, host: uri.host, port: uri.port, path: uri.path , queryParameters: queryParameters ).toString() ;
  }

}

bool _registerPagingFormatsCalled = false ;

bool _registerPagingFormats() {
  if (_registerPagingFormatsCalled) return false ;
  _registerPagingFormatsCalled = true ;

  JSONPaging._registerPagingFormatImpl( ColossusPaging.MATCHER , ColossusPaging.INSTANTIATOR ) ;
  JSONPaging._registerPagingFormatImpl( SpringBootPaging.MATCHER , SpringBootPaging.INSTANTIATOR ) ;

  return true ;
}

