
/// Returns platform base Uri. See [ Uri.base ].
///
/// - In the browser is the current window.location.href.
/// - When not in a Browser is the current working directory.
Uri getUriBase() {
  return Uri.base ;
}

/// The root [Uri] for the platform.
///
/// - In the browser will be current URL with `/` path.
/// - When not in a Browser will be the `/` directory.
Uri getUriRoot() {
  var base = getUriBase() ;
  return buildUri( base.scheme , base.host , base.port ) ;
}

/// The scheme of base Uri.
String getUriBaseScheme() {
  var uri = getUriBase() ;
  return uri.scheme;
}

/// The host of base Uri.
String getUriBaseHost() {
  var uri = getUriBase() ;
  return uri.host;
}

/// The port of base Uri.
int getUriBasePort() {
  var uri = getUriBase() ;
  return uri.port;
}

/// The host and port of base Uri.
///
/// [suppressPort80] if true suppresses port 80 and returns only the host.
String getUriBaseHostAndPort( [bool suppressPort80 = true] ) {
  suppressPort80 ??= true ;

  var uri = getUriBase() ;

  if ( suppressPort80 && uri.port == 80 ) {
    return uri.host ;
  }

  if (uri.port == 0) {
    return uri.host ;
  }

  return '${ uri.host }:${ uri.port }' ;
}

/// Returns base Uri as URL string.
String getUriRootURL( [bool ignorePort80 = true] ) {
  return getUriBaseScheme() +'://'+ getUriBaseHostAndPort(ignorePort80) +'/' ;
}

/// Builds an Uri with the parameters.
///
/// [path2] appends to [path]. If starts with `/` overwrites it.
Uri buildUri( String scheme , String host , int port , { String path , String path2 , String queryString, String fragment } ) {
  var base = getUriBase() ;

  scheme ??= base.scheme ;
  host ??= base.host ;
  port ??= base.port ;

  var defaultPort = scheme == 'https' ? 443 : ( scheme == 'http' ? 80 : 0 ) ;

  port ??= scheme == base.scheme && host == base.host ? base.port : defaultPort;

  path ??= '/' ;
  if ( !path.startsWith('/') ) path = '/$path' ;

  if ( queryString == '' ) queryString = null ;

  if ( fragment == '' ) fragment = null ;

  // path fragment:

  var idx = path.indexOf('#') ;

  var fragmentFromPath = false ;

  if (idx >= 0) {
    var pathFragment = path.substring(idx+1);

    if (pathFragment.isNotEmpty) {
      if (fragment == null) {
        fragment = pathFragment;
      }
      else {
        fragment = pathFragment +'&'+ fragment ;
      }

      fragmentFromPath = true ;
    }

    path = path.substring(0 , idx) ;
  }

  // path queryString:

  var queryStringFromPath = false ;

  idx = path.indexOf('?') ;
  if (idx >= 0) {
    var pathQuery = path.substring(idx+1);

    if (pathQuery.isNotEmpty) {
      if (queryString == null) {
        queryString = pathQuery;
      }
      else {
        queryString = pathQuery + '&' + queryString;
      }

      queryStringFromPath = true ;
    }

    path = path.substring(0 , idx) ;
  }

  // path2

  if (path2 != null) {

    // path2 fragment:

    idx = path2.indexOf('#') ;

    if (idx >= 0) {
      var path2Fragment = path2.substring(idx+1);

      if (path2Fragment.isNotEmpty) {
        if (fragment == null) {
          fragment = path2Fragment;
        }
        else {
          if (fragmentFromPath) {
            fragment = path2Fragment ;
          }
          else {
            fragment = path2Fragment +'&'+ fragment ;
          }
        }

        fragmentFromPath = false ;
      }

      path2 = path2.substring(0 , idx) ;
    }

    if (fragmentFromPath) {
      fragment = null ;
    }

    // path2 queryString:

    idx = path2.indexOf('?') ;

    if (idx >= 0) {
      var path2Query = path2.substring(idx+1);

      if ( path2Query.isNotEmpty ) {
        if (queryString == null) {
          queryString = path2Query;
        }
        else {
          if ( queryStringFromPath ) {
            queryString = path2Query ;
          }
          else {
            queryString = path2Query +'&'+ queryString ;
          }
        }

        queryStringFromPath = false ;
      }

      path2 = path2.substring(0 , idx) ;
    }

    if (queryStringFromPath) {
      queryString = null ;
    }

    // path + path2:

    if ( path2.isNotEmpty ) {
      if ( path2.startsWith('/') ) {
        path = path2 ;
      }
      else {
        if (!path.endsWith('/')) {
          idx = path.lastIndexOf('/') ;
          if (idx >= 0) {
            path = path.substring(0,idx+1);
          }
          else {
            path = '/' ;
          }
        }

        if ( path2.startsWith('./') ) {
          path += path2.substring(2) ;
        }
        else {
          path += path2 ;
        }
      }
    }
  }

  var resolved = port == defaultPort ? Uri( scheme: scheme , host: host, path: path, query: queryString, fragment: fragment) : Uri( scheme: scheme , host: host, port: port, path: path, query: queryString, fragment: fragment) ;

  return resolved ;
}

/// Removes query string from [url] and returns an [Uri].
Uri removeUriQueryString(String url) {
  var uri = Uri.parse(url) ;
  return buildUri( uri.scheme , uri.host , uri.port , path: uri.path , fragment: uri.fragment ) ;
}

/// Removes fragment from [url] and returns an [Uri].
Uri removeUriFragment(String url) {
  var uri = Uri.parse(url) ;
  return buildUri( uri.scheme , uri.host , uri.port , path: uri.path , queryString: uri.query ) ;
}

/// Resolves [url] and returns an [Uri].
///
/// If [url] starts without a scheme, it will use base Uri (from [getUriBase]) as base.
Uri resolveUri(String url) {
  if (url == null) return null ;
  url = url.trim() ;
  if (url.isEmpty) return getUriBase() ;

  if (url == '/') return getUriRoot() ;

  if (url == './') return getUriBase() ;

  if (url.startsWith( RegExp(r'\w+://')) ) return Uri.parse(url) ;

  var base = getUriBase() ;
  return buildUri( base.scheme , base.host , base.port , path: base.path , path2: url) ;
}


RegExp _REGEXP_localhost = RegExp( r'^(?:localhost|127\.0\.0\.1|::1)$' ) ;

/// Returns [true] if base Uri is localhost. See [isLocalhost].
bool isUriBaseLocalhost() {
  var host = getUriBaseHost();
  return isLocalhost(host) ;
}

bool isUriBaseIP() {
  var host = getUriBaseHost();
  return isIPAddress( host ) ;
}

/// Returns [true] if [host] is localhost (also checks for IPv4 and IPv6 addresses).
bool isLocalhost(String host) {
  return host.isEmpty || _REGEXP_localhost.hasMatch( host ) ;
}

/// Returns [true] if is a IPv4 or IPv6 address.
bool isIPAddress(String host) {
  return isIPv4Address( host ) || isIPv6Address( host ) ;
}

RegExp _REGEXP_IPv4 = RegExp(r'^(?:(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])\.){3}(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])$') ;

/// Returns [true] if is a IPv4 address.
bool isIPv4Address(String host) {
  return _REGEXP_IPv4.hasMatch( host ) ;
}

RegExp _REGEXP_IPv6 = RegExp(r'^(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))$') ;

/// Returns [true] if is a IPv6 address.
bool isIPv6Address(String host) {
  return _REGEXP_IPv6.hasMatch( host ) || host == '::/0' || host == '0000:0000:0000:0000:0000:0000:0000:0000' ;
}

/// Returns [true] if [value] represents a HTTP or HTTPS URL.
bool isHttpURL(dynamic value) {
  if (value == null) return false ;
  if (value is Uri) {
    return value.scheme == 'http' || value.scheme == 'https' ;
  }

  if (value is String) {
    var s = value.trim() ;
    if (s.isEmpty) return false ;
    return s.startsWith('http://') || s.startsWith('https://') ;
  }

  return false ;
}

/// Returns the File name of a [path].
String getPathFileName(String path) {
  if (path == null) return null ;
  path = path.trim() ;
  if (path.isEmpty) return null ;

  var idx = path.lastIndexOf( RegExp(r'[/\\]') ) ;
  if (idx < 0) return path ;

  var name = path.substring(idx+1) ;
  return name.isNotEmpty ? name : null ;
}

/// Returns [path] removing File name if present.
String getPathWithoutFileName(String path) {
  if (path == null) return null ;
  path = path.trim() ;
  if (path.isEmpty) return null ;

  var idx = path.lastIndexOf( RegExp(r'[/\\]') ) ;
  if (idx < 0) return path ;

  var onlyPath = path.substring(0, idx+1) ;
  return onlyPath ;
}

/// Returns the File extension of a [path].
String getPathExtension(String path) {
  if (path == null) return null ;
  path = path.trim() ;
  if (path.isEmpty) return null ;

  var idx = path.lastIndexOf('.') ;
  if (idx < 0) return null ;
  var ext = path.substring(idx+1) ;
  return ext.isNotEmpty ? ext : null ;
}


