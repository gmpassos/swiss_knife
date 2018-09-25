import 'dart:async';
import 'dart:convert';
import 'dart:html';


class RESTClient {

  String baseURL ;

  RESTClient(String baseURL) {
    if (baseURL.endsWith("/")) baseURL = baseURL.substring(0,baseURL.length-1) ;
    this.baseURL = baseURL ;
  }
  
  bool isLocalhost() {
    return baseURL.startsWith(new RegExp('https?://localhost')) ;
  }

  Future<dynamic> getJSON(String path, [Map<String,String> parameters]) async {
    return get(path, parameters).then((s) => _jsonDecode(s)) ;
  }

  Future<dynamic> postJSON(String path,  { Map<String,String> parameters , String body , String contentType }) async {
    return post(path, parameters: parameters, body: body, contentType: contentType).then((s) => _jsonDecode(s)) ;
  }

  Future<dynamic> putJSON(String path,  { String body , String contentType }) async {
    return put(path, body: body, contentType: contentType).then((s) => _jsonDecode(s)) ;
  }

  bool logJSON = false ;

  dynamic _jsonDecode(String s) {
    if (logJSON) _logJSON(s);

    return jsonDecode(s) ;
  }

  void _logJSON(String json) {
    var now = new DateTime.now();
    String log = "$now> RESTClient> $json" ;
    print(log);
  }

  Future<String> get(String path, [Map<String,String> parameters]) async {
    String url = _buildURL(path, parameters);
    return _requestGET(url);
  }

  Future<String> post(String path, { Map<String,String> parameters , String body , String contentType , String accept}) async {
    String url = _buildURL(path);

    var uri = Uri.parse(url);

    if (uri.queryParameters != null && uri.queryParameters.isNotEmpty) {
      if (parameters != null && parameters.isNotEmpty) {
        uri.queryParameters.forEach((k,v) => parameters.putIfAbsent(k, () => v) ) ;
      }
      else {
        parameters = uri.queryParameters ;
      }

      url = _removeURIQueryParameters(uri).toString() ;
    }

    return _requestPOST(url, parameters, body, contentType, accept);
  }

  Future<String> put(String path, { String body , String contentType , String accept}) async {
    String url = _buildURL(path);

    var uri = Uri.parse(url);

    return _requestPUT(url, body, contentType, accept);
  }

  Uri _removeURIQueryParameters(var uri) {
    if ( uri.scheme.toLowerCase() == "https" ) {
      return new Uri.https(uri.authority, uri.path) ;
    }
    else {
      return new Uri.http(uri.authority, uri.path) ;
    }
  }

  String _buildURL(String path, [Map<String,String> queryParameters]) {
    if ( !path.startsWith("/") ) path = "/$path" ;
    String url = "$baseURL$path" ;

    var uri = Uri.parse(url);

    var pathParameters = uri.queryParameters ;

    if ( pathParameters != null && pathParameters.isNotEmpty ) {
      if (queryParameters == null || queryParameters.isEmpty) {
        queryParameters = pathParameters ;
      }
      else {
        pathParameters.forEach((k,v) => queryParameters.putIfAbsent(k, () => v) ) ;
      }
    }

    var uri2 ;

    if ( uri.scheme.toLowerCase() == "https" ) {
      uri2 = new Uri.https(uri.authority, uri.path, queryParameters) ;
    }
    else {
      uri2 = new Uri.http(uri.authority, uri.path, queryParameters) ;
    }

    String url2 = uri2.toString() ;

    print("Request URL: $url2") ;

    return url2 ;
  }

  Future<String> _requestGET(String url) {
    return HttpRequest.request(url,
        method: 'GET',
        withCredentials: true,
        requestHeaders: _buildRequestHeaders(url)
    ).then( _processResponse );
  }

  Future<String> _requestPOST(String url, [Map<String,String> queryParameters, String body, String contentType, String accept]) {
    if (queryParameters != null && queryParameters.isNotEmpty) {
      return HttpRequest.postFormData(url, queryParameters,
          withCredentials: true,
          requestHeaders: _buildRequestHeaders(url, body, contentType, accept)
      ).then( _processResponse );
    }
    else {
      return HttpRequest.request(url,
          method: 'POST',
          withCredentials: true,
          requestHeaders: _buildRequestHeaders(url, body, contentType, accept),
          sendData: body
      ).then( _processResponse );
    }
  }

  Future<String> _requestPUT(String url, [String body, String contentType, String accept]) {
    return HttpRequest.request(url,
        method: 'PUT',
        withCredentials: true,
        requestHeaders: _buildRequestHeaders(url, body, contentType, accept),
        sendData: body
    ).then( _processResponse );
  }


  String _processResponse(HttpRequest xhr) {
    return xhr.responseText ;
  }

  Map<String, String> _buildRequestHeaders(String url, [String body, String contentType, String accept]) {
    var header = requestHeaders(url) ;

    if (contentType != null) {
      if (header == null) header = {} ;
      header["Content-Type"] = contentType ;
    }

    if (accept != null) {
      if (header == null) header = {} ;
      header["Accept"] = accept ;
    }

    /*
    if (body != null && body.isNotEmpty) {
      if (header == null) header = {} ;
      header["Content-Length"] = "${ body.length }" ;
    }
    */
    
    print(body);

    return header ;
  }

  Map<String, String> requestHeaders(String url) {
    return null ;
  }

}

typedef String SimulateResponse(String url, Map<String, String> queryParameters);

class RESTClientSimulation extends RESTClient {

  RESTClientSimulation(String baseURL) : super(baseURL) ;

  Map<RegExp, SimulateResponse> _getPatterns = {} ;

  void replyGET(RegExp urlPattern, String response) {
    simulateGET(urlPattern , (u,p) => response) ;
  }

  void simulateGET(RegExp urlPattern, SimulateResponse response) {
    _getPatterns[urlPattern] = response ;
  }

  Map<RegExp, SimulateResponse> _postPatterns = {} ;

  void replyPOST(RegExp urlPattern, String response) {
    simulatePOST(urlPattern , (u,p) => response) ;
  }

  void simulatePOST(RegExp urlPattern, SimulateResponse response) {
    _postPatterns[urlPattern] = response ;
  }

  Map<RegExp, SimulateResponse> _anyPatterns = {} ;

  void replyANY(RegExp urlPattern, String response) {
    simulateANY(urlPattern , (u,p) => response) ;
  }

  void simulateANY(RegExp urlPattern, SimulateResponse response) {
    _anyPatterns[urlPattern] = response ;
  }

  SimulateResponse _findResponse(String url, Map<RegExp, SimulateResponse> patterns ) {
    for (var p in patterns.keys) {
      if ( p.hasMatch(url) ) {
        return patterns[p] ;
      }
    }
    return null ;
  }

  @override
  Future<String> _requestGET(String url) {
    return _requestSimulated('GET', url, _getPatterns, null) ;
  }


  @override
  Future<String> _requestPOST(String url, [Map<String, String> queryParameters, String body, String contentType, String accept]) {
    return _requestSimulated('POST', url, _postPatterns, queryParameters) ;
  }

  Future<String> _requestSimulated(String method, String url, Map<RegExp, SimulateResponse> mainPatterns, Map<String, String> queryParameters) {
    var resp = _findResponse(url, mainPatterns) ;

    if (resp == null) {
      resp = _findResponse(url, _anyPatterns) ;
    }

    if (resp == null) {
      //var stackTrace = new StackTrace.fromString("simulated");
      return new Future.error("No simulated response[$method]") ;
    }

    var respVal = resp(url, queryParameters) ;

    return new Future.value(respVal) ;
  }

}
