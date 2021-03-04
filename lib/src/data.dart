import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'collections.dart';
import 'math.dart';
import 'utils.dart';

/// Represents MIME-Type. Useful for Content-Type and file handling.
///
/// Supported aliases:
///   - json: application/javascript
///   - javascript, js: application/javascript
///   - jpeg: image/jpeg
///   - png: image/png
///   - text: text/plain
///   - html: text/html
///   - css: text/css
///   - zip: application/zip
///   - gzip, gz: application/gzip
///   - pdf: application/pdf
///
class MimeType {
  static const APPLICATION_JSON = 'application/json';

  static const JSON = APPLICATION_JSON;

  static const APPLICATION_JAVASCRIPT = 'application/javascript';

  static const JAVASCRIPT = APPLICATION_JAVASCRIPT;

  static const APPLICATION_ZIP = 'application/zip';

  static const ZIP = APPLICATION_ZIP;

  static const APPLICATION_GZIP = 'application/gzip';

  static const GZIP = APPLICATION_GZIP;

  static const APPLICATION_PDF = 'application/pdf';

  static const PDF = APPLICATION_PDF;

  static const IMAGE_JPEG = 'image/jpeg';

  static const JPEG = IMAGE_JPEG;

  static const IMAGE_PNG = 'image/png';

  static const PNG = IMAGE_PNG;

  static const IMAGE_GIF = 'image/gif';

  static const GIF = IMAGE_GIF;

  static const IMAGE_ICON = 'image/x-icon';

  static const ICON = IMAGE_ICON;

  static const IMAGE_SVG = 'image/svg+xml';

  static const SVG = IMAGE_SVG;

  static const TEXT_HTML = 'text/html';

  static const HTML = TEXT_HTML;

  static const TEXT_CSS = 'text/css';

  static const CSS = TEXT_CSS;

  static const TEXT_PLAIN = 'text/plain';

  static const TEXT = TEXT_PLAIN;

  static const APPLICATION_XML = 'application/xml';

  static const XML = APPLICATION_XML;

  static const APPLICATION_XHTML = 'application/xhtml+xml';

  static const XHTML = APPLICATION_XHTML;

  static const VIDEO_MPEG = 'video/mpeg';

  static const MPEG = VIDEO_MPEG;

  static const AUDIO_MPEG = 'audio/mpeg';

  static const MP3 = AUDIO_MPEG;

  /// Parses a [mimeType] string and returns as a normalized MIME-Type string.
  /// Note that this can resolve aliases like `JSON`.
  ///
  /// [defaultMimeType] if [mimeType] is invalid.
  static String parseAsString(String mimeType, [String defaultMimeType]) {
    var m = MimeType.parse(mimeType, defaultMimeType);
    return m != null ? m.toString() : null;
  }

  /// Constructor that parses a [mimeType] string.
  ///
  /// [defaultMimeType] if [mimeType] is invalid.
  factory MimeType.parse(String mimeType, [String defaultMimeType]) {
    mimeType ??= defaultMimeType;

    if (mimeType == null) return null;
    mimeType = mimeType.trim();
    if (mimeType.isEmpty) mimeType = defaultMimeType;
    if (mimeType == null) return null;
    mimeType = mimeType.trim();
    if (mimeType.isEmpty) return null;

    mimeType = mimeType.toLowerCase();

    var parts = split(mimeType, ';', 2);

    mimeType = parts[0];

    var charset = (parts.length == 2 ? parts[1] : '').trim();
    charset = normalizeCharset(charset);

    if (mimeType == 'json' || mimeType.endsWith('/json')) {
      return MimeType('application', 'json', charset);
    }
    if (mimeType == 'javascript' ||
        mimeType == 'js' ||
        mimeType.endsWith('/javascript') ||
        mimeType.endsWith('/js')) {
      return MimeType('application', 'javascript', charset);
    }
    if (mimeType == 'jpeg' ||
        mimeType == 'jpg' ||
        mimeType.endsWith('/jpeg') ||
        mimeType.endsWith('/jpg')) {
      return MimeType('image', 'jpeg');
    }
    if (mimeType == 'png' || mimeType.endsWith('/png')) {
      return MimeType('image', 'png', charset);
    }
    if (mimeType == 'gif' || mimeType.endsWith('/gif')) {
      return MimeType('image', 'gif', charset);
    }
    if (mimeType == 'text') {
      return MimeType('text', 'plain');
    }
    if (mimeType == 'html' ||
        mimeType == 'htm' ||
        mimeType.endsWith('/html') ||
        mimeType.endsWith('/htm')) {
      return MimeType('text', 'html');
    }
    if (mimeType == 'xhtml' || mimeType.endsWith('/xhtml')) {
      return MimeType('application', 'xhtml');
    }
    if (mimeType == 'css' || mimeType.endsWith('/css')) {
      return MimeType('text', 'css', charset);
    }
    if (mimeType == 'xml' || mimeType.endsWith('/xml')) {
      return MimeType('text', 'xml', charset);
    }
    if (mimeType == 'zip' || mimeType.endsWith('/zip')) {
      return MimeType('application', 'zip', charset);
    }
    if (mimeType == 'gzip' || mimeType == 'gz' || mimeType.endsWith('/gzip')) {
      return MimeType('application', 'gzip', charset);
    }
    if (mimeType == 'pdf' || mimeType.endsWith('/pdf')) {
      return MimeType('application', 'pdf', charset);
    }
    if (mimeType == 'xml' || mimeType.endsWith('/xml')) {
      return MimeType('application', 'xml', charset);
    }
    if (mimeType == 'mp3' ||
        mimeType.endsWith('/mp3') ||
        mimeType.endsWith('audio/mpeg')) {
      return MimeType('audio', 'mp3', charset);
    }
    if (mimeType == 'mpeg' || mimeType.endsWith('video/mpeg')) {
      return MimeType('video', 'mpeg', charset);
    }
    if (mimeType == 'icon' ||
        mimeType == 'ico' ||
        mimeType.endsWith('/x-icon') ||
        mimeType.endsWith('/icon')) {
      return MimeType('image', 'x-icon', charset);
    }
    if (mimeType == 'svg' ||
        mimeType.endsWith('/svg') ||
        mimeType.endsWith('/svg+xml')) {
      return MimeType('image', 'svg+xml', charset);
    }

    var idx = mimeType.indexOf('/');

    if (idx > 0) {
      var type = mimeType.substring(0, idx).trim();
      var subType = mimeType.substring(idx + 1).trim();

      if (type.isNotEmpty && subType.isNotEmpty) {
        return MimeType(type, subType, charset);
      } else {
        throw ArgumentError('Invalid MimeType: $mimeType');
      }
    }

    return MimeType('application', mimeType, charset);
  }

  /// Creates an instance by file [extension].
  ///
  /// [defaultAsApplication] if true returns 'application/[extension]'.
  factory MimeType.byExtension(String extension,
      {bool defaultAsApplication = true}) {
    if (extension == null) return null;
    var idx = extension.lastIndexOf('.');
    if (idx >= 0) {
      extension = extension.substring(idx + 1);
    }
    extension = extension.trim().toLowerCase();

    switch (extension) {
      case 'zip':
        return MimeType.parse(ZIP);
      case 'gzip':
      case 'gz':
        return MimeType.parse(GZIP);
      case 'png':
        return MimeType.parse(PNG);
      case 'jpeg':
      case 'jpg':
        return MimeType.parse(JPEG);
      case 'gif':
        return MimeType.parse(GIF);
      case 'css':
        return MimeType.parse(CSS);
      case 'json':
        return MimeType.parse(JSON);
      case 'js':
      case 'javascript':
        return MimeType.parse(JAVASCRIPT);
      case 'html':
      case 'htm':
        return MimeType.parse(HTML);
      case 'xhtml':
        return MimeType.parse(XHTML);
      case 'text':
      case 'txt':
        return MimeType.parse(TEXT);
      case 'pdf':
        return MimeType.parse(PDF);
      case 'mp3':
        return MimeType.parse(MP3);
      case 'mpeg':
        return MimeType.parse(MPEG);
      case 'xml':
        return MimeType.parse(XML);
      case 'icon':
      case 'ico':
        return MimeType.parse(ICON);
      case 'svg':
        return MimeType.parse(SVG);
      default:
        {
          if (defaultAsApplication ?? true) {
            return MimeType.parse('application/$extension');
          }
          return null;
        }
    }
  }

  static String normalizeCharset(String charset) {
    if (charset == null) return null;
    charset = charset.trim();
    if (charset.isEmpty) return null;
    charset = charset.toLowerCase();
    charset = charset.replaceFirst('charset=', '').trim();
    if (charset.isEmpty) return null;
    return charset;
  }

  final String type;

  final String subType;

  final String charset;

  MimeType(this.type, this.subType, [String charSet])
      : charset = charSet != null ? charSet.trim() : null;

  /// Returns [true] if [charset] is defined.
  bool get hasCharset => charset != null && charset.isNotEmpty;

  /// Returns [true] if [charset] is UTF-8.
  bool get isCharsetUTF8 => charset == 'utf8' || charset == 'utf-8';

  /// Returns [true] if [charset] is UTF-16.
  bool get isCharsetUTF16 => charset == 'utf16' || charset == 'utf-16';

  /// Returns [true] if [charset] is LATIN-1.
  bool get isCharsetLATIN1 =>
      charset == 'latin1' ||
      charset == 'latin-1' ||
      charset == 'iso-8859-1' ||
      charset == 'iso88591';

  /// Returns [true] if this a image MIME-Type.
  bool get isImage => type == 'image';

  /// Returns [true] if this a video MIME-Type.
  bool get isVideo => type == 'video';

  /// Returns [true] if this a audio MIME-Type.
  bool get isAudio => type == 'audio';

  /// Returns the HTML tag name for this MIME-Type.
  String get htmlTag {
    if (isImage) {
      return 'img';
    } else if (isVideo) {
      return 'video';
    } else if (isAudio) {
      return 'audio';
    } else {
      return null;
    }
  }

  /// Returns [true] if this is `image/jpeg`.
  bool get isImageJPEG => isImage && subType == 'jpeg';

  /// Returns [true] if this is `image/png`.
  bool get isImagePNG => isImage && subType == 'png';

  /// Returns [true] if this is `image/svg+xml`.
  bool get isImageSVG => isImage && subType == 'svg';

  bool get isJavascript => subType == 'javascript';

  /// Returns [true] if is `application/json`.
  bool get isJSON => subType == 'json';

  /// Returns [true] if is `text/*`.
  bool get isText => type == 'text';

  /// Returns [true] if is XML.
  bool get isXML => subType == 'xml';

  /// Returns [true] if is XHTML.
  bool get isXHTML => subType == 'xhtml+xml';

  /// Returns [true] if is `application/x-www-form-urlencoded`.
  bool get isFormURLEncoded =>
      type == 'application' && subType == 'x-www-form-urlencoded';

  /// Returns [true] if type is better represented as [String].
  bool get isStringType {
    return isText ||
        isJSON ||
        isJavascript ||
        isFormURLEncoded ||
        isXML ||
        isXHTML;
  }

  /// Returns the common file extension for the MIME-Type.
  String get fileExtension {
    switch (subType) {
      case 'javascript':
        return 'js';
      case 'gzip':
        return 'gz';
      case 'svg+xml':
        return 'svg';
      case 'xhtml+xml':
        return 'xhtml';
      case 'mpeg':
        return type == 'audio' ? 'mp3' : 'mp3g';
      case 'x-icon':
        return 'ico';
      default:
        return subType;
    }
  }

  /// Generates a random file name for the type, with the corresponding [fileExtension].
  String fileNameRandom() {
    return fileName(Math.random().toString());
  }

  /// Generates a file name for the type, using [timeMillis] as name and the corresponding [fileExtension].
  String fileNameTimeMillis([int timeMillis]) {
    timeMillis ??= DateTime.now().millisecondsSinceEpoch;
    return fileName(timeMillis.toString());
  }

  /// Generates a file name for the type, using [identifier] as name and the corresponding [fileExtension].
  String fileName([String identifier, String delimiter = '-']) {
    if (identifier != null) identifier = identifier.trim();

    if (identifier != null && identifier.isNotEmpty) {
      identifier = identifier.replaceAll(RegExp(r'\W'), '_');
    }

    if (identifier != null && identifier.isNotEmpty) {
      if (delimiter != null) delimiter = delimiter.trim();
      delimiter ??= '-';

      return '$type$delimiter$identifier.$fileExtension';
    } else {
      return '$type.$fileExtension';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MimeType &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          subType == other.subType;

  @override
  int get hashCode => type.hashCode ^ subType.hashCode;

  /// Returns `$type/$subType`.
  String get fullType => '$type/$subType';

  @override
  String toString([bool withCharset]) {
    if (hasCharset && (withCharset ?? true)) {
      return '$fullType; charset=$charset';
    } else {
      return fullType;
    }
  }

  /// Parses a [mimeType] to a MIME-Type string.
  static String asString(dynamic mimeType, [String defaultMimeType]) {
    if (mimeType == null) return defaultMimeType;

    if (mimeType is String) {
      mimeType = MimeType.parse(mimeType);
    }

    if (mimeType is MimeType) {
      return mimeType.toString();
    }

    return defaultMimeType;
  }
}

/// Base-64 utils.
class Base64 {
  static String encodeArrayBuffer(Uint8List a) => base64.encode(a);

  static Uint8List decodeAsArrayBuffer(String s) => base64.decode(s);

  static String encode(String s) => base64.encode(utf8.encode(s));

  static String decode(String s) => utf8.decode(decodeAsArrayBuffer(s));
}

/// Represent a Data URL in Base-64
class DataURLBase64 {
  /// Parses the Data URL to a Base-64 string.
  static String parsePayloadAsBase64(String dataURL) {
    if (dataURL == null || dataURL.length < 5 || !dataURL.startsWith('data:')) {
      return null;
    }
    var idx = dataURL.indexOf(',');
    return dataURL.substring(idx + 1);
  }

  /// Parses the Data URL to am array buffer.
  static Uint8List parsePayloadAsArrayBuffer(String dataURL) {
    var payload = parsePayloadAsBase64(dataURL);
    return payload != null ? base64.decode(payload) : null;
  }

  /// Parses the Data URL to decoded string.
  static String parsePayloadAsString(String dataURL) {
    var data = parsePayloadAsArrayBuffer(dataURL);
    return data != null ? latin1.decode(data) : null;
  }

  /// Returns true if [s] is in Data URL (Base-64) format.
  static bool matches(String s) {
    return DataURLBase64.parse(s) != null;
  }

  /// The MIME-Type of parsed Data URL.
  final MimeType mimeType;

  /// Returns [mimeType] as [String]. Returns '' if null.
  String get mimeTypeAsString => mimeType != null ? mimeType.toString() : '';

  /// The Base-64 paylod/content of the parsed Data URL.
  final String payloadBase64;

  String _payload;

  /// The decoded payload as [String].
  String get payload {
    _payload ??= Base64.decode(payloadBase64);
    return _payload;
  }

  Uint8List _payloadArrayBuffer;

  /// The decoded payload as array buffer.
  Uint8List get payloadArrayBuffer {
    _payloadArrayBuffer ??= Base64.decodeAsArrayBuffer(payloadBase64);
    return _payloadArrayBuffer;
  }

  DataURLBase64(this.payloadBase64, [String mimeType])
      : mimeType = MimeType.parse(mimeType);

  /// Parses only the [MimeType] of the Data URL [s].
  ///
  /// [defaultMimeType] if [s] is invalid.
  static MimeType parseMimeType(String s, {String defaultMimeType}) {
    return MimeType.parse(
        parseMimeTypeAsString(s, defaultMimeType: defaultMimeType),
        defaultMimeType);
  }

  /// Parses only the MIME-Type of the Data URL [s] as string.
  static String parseMimeTypeAsString(String s, {String defaultMimeType}) {
    if (s == null) return defaultMimeType;
    s = s.trim();
    if (s.isEmpty) return defaultMimeType;

    if (!s.startsWith('data:')) return defaultMimeType;

    var idx = s.indexOf(';');
    if (idx < 5) return defaultMimeType;

    var mimeType = s.substring(5, idx).trim().toLowerCase();
    if (mimeType.isEmpty) return defaultMimeType;

    return mimeType;
  }

  /// Constructor that parses a Data URL [s]
  ///
  /// [defaultMimeType] if [s] is invalid.
  factory DataURLBase64.parse(String s, {String defaultMimeType}) {
    if (s == null) return null;
    s = s.trim();
    if (s.isEmpty) return null;

    if (!s.startsWith('data:')) return null;

    var idx = s.indexOf(';');
    if (idx < 5) return null;

    var mimeType = s.substring(5, idx);

    var idx2 = s.indexOf(',');
    if (idx2 < idx + 1) return null;

    var encoding = s.substring(idx + 1, idx2).toLowerCase();

    if (encoding != 'base64') return null;

    var payload = s.substring(idx2 + 1);

    mimeType = MimeType.parseAsString(mimeType, defaultMimeType);

    return DataURLBase64(payload, mimeType);
  }

  String _dataURLString;

  /// Returns a Data URL string.
  ///
  /// Example: `data:text/plain;base64,SGVsbG8=`
  /// that encodes `Hello` with MIME-Type `text/plain`.
  String asDataURLString() {
    _dataURLString ??= 'data:$mimeTypeAsString;base64,$payloadBase64';
    return _dataURLString;
  }

  @override
  String toString() {
    return asDataURLString();
  }
}

final REGEXP_EMAIL = RegExp(
    r'''^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$''');

/// Returns [true] if [value] represents an e-mail address.
bool isEmail(dynamic value) {
  return value is String && value.contains('@') && REGEXP_EMAIL.hasMatch(value);
}

/// Represents a Geo Location in latitude and longitude.
class Geolocation {
  static final RegExp GEOLOCATION_FORMAT =
      RegExp(r'([-=]?)(\d+[,.]?\d*)\s*[°o]?\s*(\w)');

  static num parseLatitudeOrLongitudeValue(String s,
      [bool onlyWithCardinals = false]) {
    onlyWithCardinals ??= false;

    var match = GEOLOCATION_FORMAT.firstMatch(s);
    if (match == null) return null;

    var signal = match.group(1);
    var number = match.group(2);
    var cardinal = match.group(3);

    if (signal != null && signal.isNotEmpty) {
      if (onlyWithCardinals) return null;
      return double.parse('$signal$number');
    } else if (cardinal != null && cardinal.isNotEmpty) {
      cardinal = cardinal.toUpperCase();

      switch (cardinal) {
        case 'N':
          return double.parse('$number');
        case 'S':
          return double.parse('-$number');
        case 'E':
          return double.parse('$number');
        case 'W':
          return double.parse('-$number');
      }
    }

    if (onlyWithCardinals) return null;
    return double.parse(number);
  }

  static String formatLatitude(num lat) {
    return lat >= 0 ? '$lat°E' : '$lat°W';
  }

  static String formatLongitude(num long) {
    return long >= 0 ? '$long°N' : '$long°S';
  }

  static String formatGeolocation(Point geo) {
    return formatLatitude(geo.x) + ' ' + formatLongitude(geo.y);
  }

  num _latitude;

  num _longitude;

  Geolocation(this._latitude, this._longitude) {
    if (_latitude == null || _longitude == null) {
      throw ArgumentError('Invalid coords: $_latitude $longitude');
    }
  }

  factory Geolocation.fromCoords(String coords, [bool onlyWithCardinals]) {
    coords = coords.trim();

    var parts = coords.split(RegExp(r'\s+'));
    if (parts.length < 2) return null;

    var lat = parseLatitudeOrLongitudeValue(parts[0], onlyWithCardinals);
    var long = parseLatitudeOrLongitudeValue(parts[1], onlyWithCardinals);

    return lat != null && long != null ? Geolocation(lat, long) : null;
  }

  /// The latitude of the coordinate.
  num get latitude => _latitude;

  /// The longitude of the coordinate.
  num get longitude => _longitude;

  /// As Point([latitude] , [longitude]).
  Point<num> asPoint() => Point(_latitude, _longitude);

  @override
  String toString() {
    return formatGeolocation(asPoint());
  }

  /// Generates a browser windoe ID with coordinates.
  String windowID(String prefix) {
    return '${prefix}__${latitude}__$longitude';
  }

  /// Generates a Google Maps URL with coordinates.
  String googleMapsURL() {
    return 'https://www.google.com/maps/search/?api=1&query=$_latitude,$longitude';
  }

  /// Generates a Google Maps Directions URL with coordinates.
  Future<String> googleMapsDirectionsURL(Geolocation currentGeo) async {
    if (currentGeo == null) return null;
    return 'https://www.google.com/maps/dir/?api=1&origin=${currentGeo.latitude},${currentGeo.longitude}&destination=$_latitude,$longitude';
  }
}

/// Parses [value] as a [Rectangle].
Rectangle<num> parseRectangle(dynamic value) {
  if (value is List) return parseRectangleFromList(value);
  if (value is Map) return parseRectangleFromMap(value);
  if (value is String) return parseRectangleFromString(value);
  return null;
}

/// Parses [list] as a [Rectangle].
Rectangle<num> parseRectangleFromList(List list) {
  if (list.length < 4) return null;
  list = list.map((e) => parseNum(e)).whereType<num>().toList();
  if (list.length < 4) return null;
  return Rectangle(list[0], list[1], list[2], list[3]);
}

/// Parses [map] as a [Rectangle].
Rectangle<num> parseRectangleFromMap(Map map) {
  if (map == null || map.isEmpty) return null;

  var x = parseNum(findKeyValue(map, ['x', 'left'], true));
  var y = parseNum(findKeyValue(map, ['y', 'top'], true));
  var w = parseNum(findKeyValue(map, ['width', 'w'], true));
  var h = parseNum(findKeyValue(map, ['height', 'h'], true));

  if (x == null || y == null || w == null || h == null) return null;

  return Rectangle(x, y, w, h);
}

/// Parses [s] as a [Rectangle].
Rectangle<num> parseRectangleFromString(String s) {
  if (s == null) return null;
  s = s.trim();
  if (s.isEmpty) return null;

  var parts = s.split(RegExp(r'\s*,\s*'));
  if (parts.length < 4) return null;

  var nums = parts.map((e) => parseNum(e)).whereType<num>().toList();
  if (nums.length < 4) return null;

  return Rectangle<num>(nums[0], nums[1], nums[2], nums[3]);
}

/// Parses [value] as a [Point].
Point<num> parsePoint(dynamic value) {
  if (value is List) return parsePointFromList(value);
  if (value is Map) return parsePointFromMap(value);
  if (value is String) return parsePointFromString(value);
  return null;
}

/// Parses [list] as a [Point].
Point<num> parsePointFromList(List list) {
  if (list == null || list.length < 2) return null;
  return Point<num>(parseNum(list[0]), parseNum(list[1]));
}

/// Parses [map] as a [Point].
Point<num> parsePointFromMap(Map map) {
  var x = parseNum(findKeyValue(map, ['x', 'left'], true));
  var y = parseNum(findKeyValue(map, ['y', 'top'], true));
  if (x == null || y == null) return null;
  return Point<num>(x, y);
}

/// Parses [s] as a [Point].
Point<num> parsePointFromString(String s) {
  if (s == null) return null;
  s = s.trim();
  if (s.isEmpty) return null;

  var parts = s.split(RegExp(r'\s*,\s*'));
  if (parts.length < 2) return null;
  var nums = parts.map((e) => parseNum(e)).whereType<num>().toList();
  if (nums.length < 2) return null;
  return Point<num>(nums[0], nums[1]);
}

/// Formats [size] as a data format using binary of decimal base for sufixes.
///
/// - Decimal base: `bytes`, `KB`, `MB` and `GB`.
/// - Binary base: `bytes`, `KiB`, `MiB` and `GiB`.
///
/// [decimalBase] Default [true]. If [true] uses a decimal base, if false uses
/// decimal base.
///
/// [binaryBase] Default [false]. If [true] uses a binary base, if false uses
/// decimal base.
String dataSizeFormat(int size, {bool decimalBase, bool binaryBase}) {
  if (size == null) return null;

  var baseDecimal;

  if (decimalBase != null) {
    baseDecimal = decimalBase;
  }

  if (binaryBase != null) {
    if (baseDecimal == null) {
      baseDecimal = !binaryBase;
    } else if (baseDecimal) {
      baseDecimal = true;
    } else {
      baseDecimal = !binaryBase;
    }
  }

  baseDecimal ??= true;

  if (baseDecimal) {
    if (size < 1000) {
      return '$size bytes';
    } else if (size < 1000 * 1000) {
      var s = '${size ~/ 1000} KB';
      return s;
    } else if (size < 1000 * 1000 * 1000) {
      return formatDecimal(size / (1000 * 1000)) + ' MB';
    } else {
      return formatDecimal(size / (1000 * 1000 * 1000)) + ' GB';
    }
  } else {
    if (size < 1024) {
      return '$size bytes';
    } else if (size < 1024 * 1024) {
      var s = '${size ~/ 1024} KiB';
      return s;
    } else if (size < 1024 * 1024 * 1024) {
      return formatDecimal(size / (1024 * 1024)) + ' MiB';
    } else {
      return formatDecimal(size / (1024 * 1024 * 1024)) + ' GiB';
    }
  }
}
