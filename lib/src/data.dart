
import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';

import 'math.dart';
import 'collections.dart';

class MimeType {

  static const APPLICATION_JSON = 'application/json' ;
  static const JSON = APPLICATION_JSON ;

  static const APPLICATION_JAVASCRIPT = 'application/javascript' ;
  static const JAVASCRIPT = APPLICATION_JAVASCRIPT ;

  static const IMAGE_JPEG = 'image/jpeg' ;
  static const JPEG = IMAGE_JPEG ;

  static const IMAGE_PNG = 'image/png' ;
  static const PNG = IMAGE_PNG ;

  static const TEXT_HTML = 'text/html' ;
  static const HTML = TEXT_HTML ;

  static const TEXT_PLAIN = 'text/plain' ;
  static const TEXT = TEXT_PLAIN ;

  static String parseAsString(String mimeType, [String defaultMimeType]) {
    var m = MimeType.parse(mimeType, defaultMimeType) ;
    return m != null ? m.toString() : null ;
  }

  factory MimeType.parse(String mimeType, [String defaultMimeType]) {
    mimeType ??= defaultMimeType;

    if (mimeType == null) return null ;

    mimeType = mimeType.trim() ;

    if (mimeType.isEmpty) mimeType = defaultMimeType ;
    if (mimeType.isEmpty) return null ;

    mimeType = mimeType.toLowerCase() ;

    if ( mimeType == 'json' || mimeType.endsWith('/json') ) return MimeType('application','json') ;
    if ( mimeType == 'javascript' || mimeType == 'js' || mimeType.endsWith('/javascript') || mimeType.endsWith('/js') ) return MimeType('application','javascript') ;

    if ( mimeType == 'jpeg' || mimeType == 'jpg' || mimeType.endsWith('/jpeg') || mimeType.endsWith('/jpg') ) return MimeType('image','jpeg') ;
    if ( mimeType == 'png' || mimeType.endsWith('/png') ) return MimeType('image','png') ;
    if ( mimeType == 'png' || mimeType.endsWith('/gif') ) return MimeType('image','gif') ;

    if (mimeType == 'text' ) return MimeType('text','plain') ;
    if (mimeType == 'html' || mimeType == 'htm' || mimeType.endsWith('/html') || mimeType.endsWith('/htm') ) return MimeType('text','html') ;
    if (mimeType == 'css' || mimeType.endsWith('/css') ) return MimeType('text','css') ;
    if (mimeType == 'xml' || mimeType.endsWith('/xml') ) return MimeType('text','xml') ;

    if (mimeType == 'zip' || mimeType.endsWith('/zip') ) return MimeType('application','zip') ;
    if (mimeType == 'pdf' || mimeType.endsWith('/pdf') ) return MimeType('application','pdf') ;

    var idx = mimeType.indexOf('/') ;

    if (idx > 0) {
      var type = mimeType.substring(0, idx).trim() ;
      var subType = mimeType.substring(idx+1).trim() ;

      if (type.isNotEmpty && subType.isNotEmpty) {
        return MimeType(type, subType) ;
      }
      else {
        throw ArgumentError('Invaliud MimeType: $mimeType') ;
      }
    }

    return MimeType('application', mimeType) ;
  }

  final String type ;
  final String subType ;

  MimeType(this.type, this.subType);

  bool get isImage => type == 'image' ;
  bool get isVideo => type == 'video' ;

  bool get isImageJPEG => isImage && subType == 'jpeg' ;
  bool get isImagePNG => isImage && subType == 'png' ;

  String get fileExtension {
    switch (subType) {
      case 'javascript' : return 'js' ;
      default: return subType ;
    }
  }

  String fileNameRandom() {
    return fileName( Math.random().toString() ) ;
  }

  String fileNameTimeMillis( [int timeMillis] ) {
    timeMillis ??= DateTime.now().millisecondsSinceEpoch ;
    return fileName( timeMillis.toString() ) ;
  }

  String fileName( [String identifier , String delimiter = '-']) {
    if (identifier != null) identifier = identifier.trim() ;

    if (identifier != null && identifier.isNotEmpty) {
      identifier = identifier.replaceAll(RegExp(r'\W'), '_') ;
    }

    if (identifier != null && identifier.isNotEmpty) {
      if (delimiter != null) delimiter = delimiter.trim() ;
      delimiter ??= '-' ;

      return '$type$delimiter$identifier.$fileExtension' ;
    }
    else {
      return '$type.$fileExtension' ;
    }
  }

  @override
  String toString() {
    return '$type/$subType';
  }

  static String asString(dynamic mimeType , [String defaultMimeType]) {
    if (mimeType == null) return defaultMimeType ;

    if (mimeType is String) {
      mimeType = MimeType.parse(mimeType) ;
    }

    if (mimeType is MimeType) {
      return mimeType.toString() ;
    }

    return defaultMimeType ;
  }

}

class Base64 {

  static String encodeArrayBuffer(Uint8List a) => base64.encode(a) ;
  static Uint8List decodeAsArrayBuffer(String s) => base64.decode(s) ;

  static String encode(String s) => base64.encode( utf8.encode(s) ) ;
  static String decode(String s) => utf8.decode( decodeAsArrayBuffer(s) ) ;

}

class DataURLBase64 {

  static String parsePayloadAsBase64(String dataURL) {
    if (dataURL == null || dataURL.length < 5 || !dataURL.startsWith('data:')) return null ;
    var idx = dataURL.indexOf(',') ;
    return dataURL.substring(idx+1) ;
  }

  static Uint8List parsePayloadAsArrayBuffer(String dataURL) {
    var payload = parsePayloadAsBase64(dataURL) ;
    return payload != null ? base64.decode(payload) : null ;
  }

  static String parsePayloadAsString(String dataURL) {
    var data = parsePayloadAsArrayBuffer(dataURL) ;
    return data != null ? latin1.decode(data) : null ;
  }

  //////////////////////////////////

  static bool matches(String s) {
    return DataURLBase64.parse(s) != null ;
  }

  final MimeType mimeType ;
  String get mimeTypeAsString => mimeType != null ? mimeType.toString() : '' ;

  final String payloadBase64 ;

  String _payload ;

  String get payload {
    _payload ??= Base64.decode(payloadBase64);
    return _payload ;
  }

  Uint8List _payloadArrayBuffer ;

  Uint8List get payloadArrayBuffer {
    _payloadArrayBuffer ??= Base64.decodeAsArrayBuffer( payloadBase64 );
    return _payloadArrayBuffer ;
  }

  DataURLBase64(this.payloadBase64, [String mimeType]) :
      mimeType = MimeType.parse(mimeType)
  ;

  static MimeType parseMimeType(String s, { String defaultMimeType }) {
    return MimeType.parse( parseMimeTypeAsString(s, defaultMimeType: defaultMimeType) , defaultMimeType ) ;
  }

  static String parseMimeTypeAsString(String s, { String defaultMimeType }) {
    if (s == null) return defaultMimeType ;
    s = s.trim() ;
    if (s.isEmpty) return defaultMimeType ;

    if (!s.startsWith('data:')) return defaultMimeType ;

    var idx = s.indexOf(';') ;
    if (idx < 5) return defaultMimeType ;

    var mimeType = s.substring(5, idx).trim().toLowerCase() ;
    if (mimeType.isEmpty) return defaultMimeType ;

    return mimeType ;
  }

  factory DataURLBase64.parse(String s, { String defaultMimeType }) {
    if (s == null) return null ;
    s = s.trim() ;
    if (s.isEmpty) return null ;

    if (!s.startsWith('data:')) return null ;

    var idx = s.indexOf(';') ;
    if (idx < 5) return null ;

    var mimeType = s.substring(5, idx) ;

    var idx2 = s.indexOf(',') ;
    if (idx2 < idx+1) return null ;

    var encoding = s.substring(idx+1,idx2).toLowerCase() ;

    if (encoding != 'base64') return null ;

    var payload = s.substring(idx2+1) ;

    mimeType = MimeType.parseAsString(mimeType, defaultMimeType) ;

    return DataURLBase64(payload, mimeType) ;
  }

  String _dataURLString ;

  String asDataURLString() {
    _dataURLString ??= 'data:$mimeTypeAsString;base64,$payloadBase64}';
    return _dataURLString ;
  }

  @override
  String toString() {
    return asDataURLString() ;
  }

}

bool isHttpHURL(dynamic value) {
  return value is String && ( value.startsWith('http://') || value.startsWith('https://') ) ;
}

final REGEXP_EMAIL = RegExp(r'''^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$''');

bool isEmail(dynamic value) {
  return value is String && value.contains('@') && REGEXP_EMAIL.hasMatch(value) ;
}

////////////////////////////////////////////////////////////////////////////////


class Geolocation {

  static final RegExp GEOLOCATION_FORMAT = RegExp(r'([-=]?)(\d+[,.]?\d*)\s*[°o]?\s*(\w)') ;

  static num parseLatitudeOrLongitudeValue(String s, [bool onlyWithCardinals = false]) {
    onlyWithCardinals ??= false ;

    var match = GEOLOCATION_FORMAT.firstMatch(s) ;
    if ( match == null ) return null ;

    var signal = match.group(1) ;
    var number = match.group(2) ;
    var cardinal = match.group(3) ;

    if ( signal != null && signal.isNotEmpty ) {
      if (onlyWithCardinals) return null ;
      return double.parse('$signal$number') ;
    }
    else if ( cardinal != null && cardinal.isNotEmpty ) {
      cardinal = cardinal.toUpperCase() ;

      switch (cardinal) {
        case 'N': return double.parse('$number') ;
        case 'S': return double.parse('-$number') ;
        case 'E': return double.parse('$number') ;
        case 'W': return double.parse('-$number') ;
      }
    }

    if (onlyWithCardinals) return null ;
    return double.parse(number) ;
  }

  static String formatLatitude(num lat) {
    return lat >= 0 ? '$lat°E' : '$lat°W' ;
  }

  static String formatLongitude(num long) {
    return long >= 0 ? '$long°N' : '$long°S' ;
  }

  static String formatGeolocation(Point geo) {
    return formatLatitude( geo.x ) +' '+ formatLongitude( geo.y ) ;
  }

  ///////////////////////////////////////////////////

  num _latitude ;
  num _longitude ;

  Geolocation(this._latitude, this._longitude) {
    if (_latitude == null || _longitude == null) throw ArgumentError('Invalid coords: $_latitude $longitude') ;
  }

  factory Geolocation.fromCoords(String coords, [bool onlyWithCardinals]) {
    coords = coords.trim() ;

    var parts = coords.split(RegExp(r'\s+')) ;
    if (parts.length < 2) return null ;

    var lat = parseLatitudeOrLongitudeValue(parts[0] , onlyWithCardinals) ;
    var long = parseLatitudeOrLongitudeValue(parts[1] , onlyWithCardinals) ;

    return lat != null && long != null ? Geolocation(lat, long) : null ;
  }

  num get latitude => _latitude;
  num get longitude => _longitude;

  Point<num> asPoint() => Point(_latitude, _longitude) ;

  @override
  String toString() {
    return formatGeolocation( asPoint() ) ;
  }

  String windowID(String prefix) {
    return '${prefix}__${latitude}__${longitude}';
  }

  String googleMapsURL() {
    return 'https://www.google.com/maps/search/?api=1&query=$_latitude,$longitude' ;
  }

  Future<String> googleMapsDirectionsURL( Geolocation currentGeo ) async {
    if (currentGeo == null) return null ;
    return 'https://www.google.com/maps/dir/?api=1&origin=${ currentGeo.latitude },${ currentGeo.longitude }&destination=$_latitude,$longitude' ;
  }

}

////////////////////////////////////////////////////////////////////////////////

Rectangle<num> parseRectangle(dynamic value) {
  if (value is List) return parseRectangleFromList(value) ;
  if (value is Map) return parseRectangleFromMap(value) ;
  if (value is String) return parseRectangleFromString(value) ;
  return null ;
}

Rectangle<num> parseRectangleFromList(List list) {
  if (list.length < 4) return null ;
  list = list.map( (e) => parseNum(e) ).whereType<num>().toList() ;
  if (list.length < 4) return null ;
  return Rectangle( list[0], list[1], list[2], list[3] );
}

Rectangle<num> parseRectangleFromMap(Map map) {
  if (map == null || map.isEmpty) return null ;

  var x = parseNum( findKeyValue(map, ['x', 'left'] , true) );
  var y = parseNum( findKeyValue(map, ['y', 'top'] , true) );
  var w = parseNum( findKeyValue(map, ['width', 'w'] , true) );
  var h = parseNum( findKeyValue(map, ['height', 'h'] , true) );

  if (x == null || y == null || w ==  null || h == null) return null ;

  return Rectangle(x, y, w, h) ;
}

Rectangle<num> parseRectangleFromString(String s) {
  if (s == null) return null ;
  s = s.trim() ;
  if (s.isEmpty) return null ;

  var parts = s.split(RegExp(r'\s*,\s*')) ;
  if ( parts.length < 4 ) return null ;

  var nums = parts.map( (e) => parseNum(e) ).whereType<num>().toList() ;
  if ( nums.length < 4 ) return null ;

  return Rectangle<num>(nums[0], nums[1], nums[2], nums[3]);
}

//////////////////

Point<num> parsePoint(dynamic value) {
  if (value is List) return parsePointFromList(value) ;
  if (value is Map) return parsePointFromMap(value) ;
  if (value is String) return parsePointFromString(value) ;
  return null ;
}

Point<num> parsePointFromList(List l) {
  if (l == null || l.length < 2) return null ;
  return Point<num>( parseNum(l[0]), parseNum(l[1]) ) ;
}

Point<num> parsePointFromMap(Map map) {
  var x = parseNum( findKeyValue(map, ['x','left'] , true) );
  var y = parseNum( findKeyValue(map, ['y','top'] , true) );
  if (x == null || y == null ) return null ;
  return Point<num>(x, y) ;
}

Point<num> parsePointFromString(String s) {
  if (s == null) return null ;
  s = s.trim() ;
  if (s.isEmpty) return null ;

  var parts = s.split(RegExp(r'\s*,\s*'));
  if ( parts.length < 2 ) return null ;
  var nums = parts.map( (e) => parseNum(e) ).whereType<num>().toList() ;
  if ( nums.length < 2 ) return null ;
  return Point<num>( nums[0] , nums[1] ) ;
}

String dataSizeFormat(int size) {
  if (size < 1024) {
    return '$size bytes' ;
  }
  else if (size < 1024*1024) {
    var s = '${size ~/ 1024} KB';
    return s ;
  }
  else {
    return formatDecimal( size / (1024*1024) )+ ' MB' ;
  }
}

