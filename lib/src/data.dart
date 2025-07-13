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
  static const applicationOctetStream = 'application/octet-stream';
  static const bytes = applicationOctetStream;

  static const applicationJson = 'application/json';
  static const json = applicationJson;

  static const applicationJavaScript = 'application/javascript';
  static const javaScript = applicationJavaScript;

  static const applicationZip = 'application/zip';
  static const zip = applicationZip;

  static const applicationGzip = 'application/gzip';
  static const gzip = applicationGzip;

  static const applicationPDF = 'application/pdf';
  static const pdf = applicationPDF;

  static const imageJPEG = 'image/jpeg';
  static const jpeg = imageJPEG;

  static const imagePNG = 'image/png';
  static const png = imagePNG;

  static const imageGIF = 'image/gif';
  static const gif = imageGIF;

  static const imageIcon = 'image/x-icon';
  static const icon = imageIcon;

  static const imageSVG = 'image/svg+xml';
  static const svg = imageSVG;

  static const imageWebp = 'image/webp';
  static const webp = imageWebp;

  static const audioWebm = 'audio/webm';
  static const weba = audioWebm;

  static const videoWebm = 'video/webm';
  static const webm = videoWebm;

  static const textHTML = 'text/html';
  static const html = textHTML;

  static const textCSS = 'text/css';
  static const css = textCSS;

  static const textPlain = 'text/plain';
  static const text = textPlain;

  static const applicationXML = 'application/xml';
  static const xml = applicationXML;

  static const applicationXHTML = 'application/xhtml+xml';
  static const xhtml = applicationXHTML;

  static const videoMPEG = 'video/mpeg';
  static const mpeg = videoMPEG;

  static const audioMPEG = 'audio/mpeg';
  static const mp3 = audioMPEG;

  static const applicationYaml = 'application/yaml';
  static const yaml = applicationYaml;

  static const textMarkdown = 'text/markdown';
  static const markdown = textMarkdown;

  static const applicationDart = 'application/dart';
  static const dart = applicationDart;

  static const fontOtf = 'font/otf';
  static const otf = fontOtf;

  static const fontTtf = 'font/ttf';
  static const ttf = fontTtf;

  static const fontWoff = 'font/woff';
  static const woff = fontWoff;

  static const fontWoff2 = 'font/woff2';
  static const woff2 = fontWoff2;

  //woff2

  /// Parses a [mimeType] string and returns as a normalized MIME-Type string.
  /// Note that this can resolve aliases like `JSON`.
  ///
  /// [defaultMimeType] if [mimeType] is invalid.
  static String? parseAsString(String? mimeType, [String? defaultMimeType]) {
    var m = MimeType.parse(mimeType, defaultMimeType);
    return m?.toString();
  }

  /// Constructor that parses a [mimeType] string.
  ///
  /// [defaultMimeType] if [mimeType] is invalid.
  static MimeType? parse(String? mimeType, [String? defaultMimeType]) {
    if (mimeType != null) {
      mimeType = mimeType.trim();
      if (mimeType.isEmpty) {
        if (defaultMimeType != null) {
          mimeType = defaultMimeType.trim();
          if (mimeType.isEmpty) return null;
        } else {
          return null;
        }
      }
    } else if (defaultMimeType != null) {
      mimeType = defaultMimeType.trim();
      if (mimeType.isEmpty) return null;
    } else {
      return null;
    }

    assert(mimeType.isNotEmpty && mimeType == mimeType.trim());

    mimeType = mimeType.toLowerCase();

    var parts = split(mimeType, ';', 2);

    mimeType = parts[0];

    String? charset = (parts.length == 2 ? parts[1] : '').trim();
    charset = normalizeCharset(charset);

    if (mimeType == 'json' || mimeType.endsWith('/json')) {
      return MimeType('application', 'json', charset);
    } else if (mimeType == 'javascript' ||
        mimeType == 'js' ||
        mimeType.endsWith('/javascript') ||
        mimeType.endsWith('/js')) {
      return MimeType('application', 'javascript', charset);
    } else if (mimeType == 'jpeg' ||
        mimeType == 'jpg' ||
        mimeType.endsWith('/jpeg') ||
        mimeType.endsWith('/jpg')) {
      return MimeType('image', 'jpeg');
    } else if (mimeType == 'png' || mimeType.endsWith('/png')) {
      return MimeType('image', 'png', charset);
    } else if (mimeType == 'svg' ||
        mimeType.endsWith('/svg') ||
        mimeType.endsWith('/svg+xml')) {
      return MimeType('image', 'svg+xml', charset);
    } else if (mimeType == 'text' || mimeType == 'txt') {
      return MimeType('text', 'plain');
    } else if (mimeType == 'css' || mimeType.endsWith('/css')) {
      return MimeType('text', 'css', charset);
    } else if (mimeType == 'html' ||
        mimeType == 'htm' ||
        mimeType.endsWith('/html') ||
        mimeType.endsWith('/htm')) {
      return MimeType('text', 'html', charset);
    } else if (mimeType == 'icon' ||
        mimeType == 'ico' ||
        mimeType.endsWith('/x-icon') ||
        mimeType.endsWith('/icon')) {
      return MimeType('image', 'x-icon', charset);
    } else if (mimeType == 'gif' || mimeType.endsWith('/gif')) {
      return MimeType('image', 'gif', charset);
    } else if (mimeType == 'otf' || mimeType.endsWith('/otf')) {
      return MimeType('font', 'otf', charset);
    } else if (mimeType == 'ttf' || mimeType.endsWith('/ttf')) {
      return MimeType('font', 'ttf', charset);
    } else if (mimeType == 'woff' || mimeType.endsWith('/woff')) {
      return MimeType('font', 'woff', charset);
    } else if (mimeType == 'woff2' || mimeType.endsWith('/woff2')) {
      return MimeType('font', 'woff2', charset);
    } else if (mimeType == 'webp' || mimeType.endsWith('/webp')) {
      return MimeType('image', 'webp', charset);
    } else if (mimeType == 'weba' ||
        mimeType == 'audio/webm' ||
        mimeType == 'audio/weba') {
      return MimeType('audio', 'webm', charset);
    } else if (mimeType == 'webm' || mimeType == 'video/webm') {
      return MimeType('video', 'webm', charset);
    } else if (mimeType == 'yaml' ||
        mimeType == 'yml' ||
        mimeType.endsWith('/yaml')) {
      return MimeType('application', 'yaml', charset);
    } else if (mimeType == 'xml' || mimeType.endsWith('/xml')) {
      return MimeType('application', 'xml', charset);
    } else if (mimeType == 'zip' || mimeType.endsWith('/zip')) {
      return MimeType('application', 'zip', charset);
    } else if (mimeType == 'gzip' ||
        mimeType == 'gz' ||
        mimeType.endsWith('/gzip')) {
      return MimeType('application', 'gzip', charset);
    } else if (mimeType == 'pdf' || mimeType.endsWith('/pdf')) {
      return MimeType('application', 'pdf', charset);
    } else if (mimeType == 'mp3' ||
        mimeType.endsWith('/mp3') ||
        mimeType.endsWith('audio/mpeg')) {
      return MimeType('audio', 'mp3', charset);
    } else if (mimeType == 'mpeg' || mimeType.endsWith('video/mpeg')) {
      return MimeType('video', 'mpeg', charset);
    } else if (mimeType == 'xhtml' ||
        mimeType.endsWith('/xhtml') ||
        mimeType.endsWith('/xhtml+xml')) {
      return MimeType('application', 'xhtml');
    } else if (mimeType == 'markdown' ||
        mimeType == 'md' ||
        mimeType.endsWith('/markdown')) {
      return MimeType('text', 'markdown', charset);
    } else if (mimeType == 'dart' || mimeType.endsWith('/dart')) {
      return MimeType('application', 'dart', charset);
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
  static MimeType? byExtension(String? extension,
      {bool defaultAsApplication = true}) {
    if (extension == null) return null;

    var idx = extension.lastIndexOf('.');
    if (idx >= 0) {
      extension = extension.substring(idx + 1);
    }
    extension = extension.trim().toLowerCase();

    switch (extension) {
      case 'zip':
        return MimeType.parse(zip);
      case 'gzip':
      case 'gz':
        return MimeType.parse(gzip);
      case 'png':
        return MimeType.parse(png);
      case 'jpeg':
      case 'jpg':
        return MimeType.parse(jpeg);
      case 'gif':
        return MimeType.parse(gif);
      case 'css':
        return MimeType.parse(css);
      case 'json':
        return MimeType.parse(json);
      case 'js':
      case 'javascript':
        return MimeType.parse(javaScript);
      case 'html':
      case 'htm':
        return MimeType.parse(html);
      case 'xhtml':
        return MimeType.parse(xhtml);
      case 'text':
      case 'txt':
        return MimeType.parse(text);
      case 'pdf':
        return MimeType.parse(pdf);
      case 'mp3':
        return MimeType.parse(mp3);
      case 'mpeg':
        return MimeType.parse(mpeg);
      case 'xml':
        return MimeType.parse(xml);
      case 'icon':
      case 'ico':
        return MimeType.parse(icon);
      case 'svg':
        return MimeType.parse(svg);

      case 'webp':
        return MimeType.parse(webp);
      case 'weba':
        return MimeType.parse(weba);
      case 'webm':
        return MimeType.parse(webm);

      case 'otf':
        return MimeType.parse(otf);
      case 'ttf':
        return MimeType.parse(ttf);
      case 'woff':
        return MimeType.parse(woff);
      case 'woff2':
        return MimeType.parse(woff2);
      case 'md':
        return MimeType.parse(markdown);
      case 'yaml':
      case 'yml':
        return MimeType.parse(yaml);
      case 'dart':
        return MimeType.parse(dart);
      default:
        {
          if (defaultAsApplication) {
            return MimeType.parse('application/$extension');
          }
          return null;
        }
    }
  }

  static String? normalizeCharset(String? charset) {
    if (charset == null || charset.isEmpty) return null;
    charset = charset.toLowerCase();
    charset = charset.replaceFirst('charset=', '');
    charset = charset.trim();
    if (charset.isEmpty) return null;
    return charset;
  }

  final String type;

  final String subType;

  final String? charset;

  MimeType(this.type, this.subType, [String? charSet])
      : charset = normalizeCharset(charSet);

  /// Returns [true] if [charset] is defined.
  bool get hasCharset => charset != null && charset!.isNotEmpty;

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

  Encoding? get charsetEncoding {
    if (charset == null) {
      return null;
    } else if (isCharsetUTF8) {
      return utf8;
    } else if (isCharsetLATIN1) {
      return latin1;
    } else {
      return null;
    }
  }

  /// Returns [true] if this an image MIME-Type.
  bool get isImage => type == 'image';

  /// Returns [true] if this a video MIME-Type.
  bool get isVideo => type == 'video';

  /// Returns [true] if this an audio MIME-Type.
  bool get isAudio => type == 'audio';

  /// Returns [true] if this a font MIME-Type.
  bool get isFont => type == 'font';

  /// Returns the HTML tag name for this MIME-Type.
  String? get htmlTag {
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

  /// Returns [true] if this is `image/png`.
  bool get isImageWebP => isImage && subType == 'webp';

  /// Returns [true] if this is `image/svg+xml`.
  bool get isImageSVG => isImage && subType == 'svg+xml';

  bool get isJavascript => subType == 'javascript';

  /// Returns [true] if is `application/json`.
  bool get isJSON => subType == 'json';

  /// Returns [true] if is `application/yaml`.
  bool get isYAML => subType == 'yaml';

  /// Returns [true] if is `text/*`.
  bool get isText => type == 'text';

  /// Returns [true] if is XML.
  bool get isXML => subType == 'xml';

  /// Returns [true] if is XHTML.
  bool get isXHTML => subType == 'xhtml+xml';

  /// Returns [true] if is `application/x-www-form-urlencoded`.
  bool get isFormURLEncoded =>
      type == 'application' && subType == 'x-www-form-urlencoded';

  /// Returns [true] if is PDF.
  bool get isPDF => subType == 'pdf';

  /// Returns [true] if is a Dart script/code.
  bool get isDart => subType == 'dart';

  /// Returns [true] if is Zip.
  bool get isZip => subType == 'zip';

  /// Returns [true] if is GZip.
  bool get isGZip => subType == 'gzip';

  /// Returns [true] if is GZip.
  bool get isBZip2 => subType == 'bzip2';

  /// Returns [true] if is XZ.
  bool get isXZ => subType == 'x-xz';

  /// Returns [true] if is Tar.
  bool get isTar => subType == 'x-tar';

  /// Returns [true] if is `tar.gz`.
  bool get isTarGZip => subType == 'x-tar+gzip';

  /// Returns [true] if is `tar.bz2`.
  bool get isTarBZip2 => subType == 'x-tar+bzip2';

  /// Returns [true] if is `tar.xz`.
  bool get isTarXZ => subType == 'x-tar+xz';

  /// Returns [true] if is Tar+Compression.
  bool get isTarCompressed => isTarGZip || isTarBZip2 || isTarXZ;

  /// Returns [true] if is a compression type.
  bool get isCompressed =>
      isZip || isGZip || isBZip2 || isXZ || isTarCompressed;

  /// Returns [true] if is `application/octet-stream`.
  bool get isOctetStream => type == 'application' && subType == 'octet-stream';

  /// Returns [true] if type is better represented as [String].
  bool get isStringType {
    return isText ||
        isJSON ||
        isJavascript ||
        isYAML ||
        isFormURLEncoded ||
        isXML ||
        isXHTML ||
        isDart ||
        isImageSVG;
  }

  /// The preferred [String] [Encoding] for this MIME-Type:
  Encoding? get preferredStringEncoding {
    if (isCharsetUTF8) {
      return utf8;
    } else if (isCharsetLATIN1) {
      return latin1;
    } else if (isStringType) {
      return utf8;
    } else if (isImage) {
      return isImageSVG ? utf8 : latin1;
    } else if (isVideo || isAudio || isFont) {
      return latin1;
    } else if (isOctetStream || isCompressed || isTar || isPDF) {
      return latin1;
    } else {
      return null;
    }
  }

  /// Returns the common file extension for the MIME-Type.
  String get fileExtension {
    switch (subType) {
      case 'javascript':
        return 'js';
      case 'gzip':
        return 'gz';
      case 'zip':
        return 'zip';
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
  String fileNameTimeMillis([int? timeMillis]) {
    timeMillis ??= DateTime.now().millisecondsSinceEpoch;
    return fileName(timeMillis.toString());
  }

  /// Generates a file name for the type, using [identifier] as name and the corresponding [fileExtension].
  String fileName([String? identifier, String delimiter = '-']) {
    if (identifier != null) identifier = identifier.trim();

    if (identifier != null && identifier.isNotEmpty) {
      identifier = identifier.replaceAll(RegExp(r'\W'), '_');
    }

    if (identifier != null && identifier.isNotEmpty) {
      delimiter = delimiter.trim();

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
  String toString([bool? withCharset]) {
    if (hasCharset && (withCharset ?? true)) {
      return '$fullType; charset=$charset';
    } else {
      return fullType;
    }
  }

  /// Parses a [mimeType] to a MIME-Type string.
  static String? asString(Object? mimeType, [String? defaultMimeType]) {
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

Encoding? getCharsetEncoding(String? charset) {
  if (charset == null || charset.isEmpty) return null;
  var mimeType = MimeType('text', 'plain', charset);
  return mimeType.charsetEncoding;
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
  static String? parsePayloadAsBase64(String? dataURL) {
    if (dataURL == null || dataURL.length < 5 || !dataURL.startsWith('data:')) {
      return null;
    }
    var idx = dataURL.indexOf(',');
    return dataURL.substring(idx + 1);
  }

  /// Parses the Data URL to am array buffer.
  static Uint8List? parsePayloadAsArrayBuffer(String dataURL) {
    var payload = parsePayloadAsBase64(dataURL);
    return payload != null ? base64.decode(payload) : null;
  }

  /// Parses the Data URL to decoded string.
  static String? parsePayloadAsString(String dataURL) {
    var data = parsePayloadAsArrayBuffer(dataURL);
    return data != null ? latin1.decode(data) : null;
  }

  /// Returns true if [s] is in Data URL (Base-64) format.
  static bool matches(String s) {
    return DataURLBase64.parse(s) != null;
  }

  /// The MIME-Type of parsed Data URL.
  final MimeType? mimeType;

  /// Returns [mimeType] as [String]. Returns '' if null.
  String get mimeTypeAsString => mimeType != null ? mimeType.toString() : '';

  /// The Base-64 paylod/content of the parsed Data URL.
  final String payloadBase64;

  String? _payload;

  /// The decoded payload as [String].
  String get payload => _payload ??= Base64.decode(payloadBase64);

  Uint8List? _payloadArrayBuffer;

  /// The decoded payload as array buffer.
  Uint8List get payloadArrayBuffer =>
      _payloadArrayBuffer ??= Base64.decodeAsArrayBuffer(payloadBase64);

  DataURLBase64(this.payloadBase64, [String? mimeType])
      : mimeType = MimeType.parse(mimeType);

  /// Instantiates a [DataURLBase64] automatically resolving [payload] and [mimeType].
  factory DataURLBase64.from(Object payload, [Object? mimeType]) {
    String? m =
        mimeType is MimeType ? mimeType.toString() : mimeType?.toString();

    if (payload is List<int>) {
      return DataURLBase64(base64.encode(payload), m);
    } else if (payload is DataURLBase64) {
      return DataURLBase64(
          payload.payloadBase64, m ?? payload.mimeTypeAsString);
    } else {
      var s = payload.toString();

      var dataUrl = DataURLBase64.parse(s);
      if (dataUrl != null) {
        return DataURLBase64(
            dataUrl.payloadBase64, m ?? dataUrl.mimeTypeAsString);
      } else {
        var bs = _decodeBase64(s);
        if (bs != null) {
          return DataURLBase64(s, m);
        } else {
          return DataURLBase64(Base64.encode(s), m ?? 'text/plain');
        }
      }
    }
  }

  /// Parses only the [MimeType] of the Data URL [s].
  ///
  /// [defaultMimeType] if [s] is invalid.
  static MimeType? parseMimeType(String s, {String? defaultMimeType}) {
    return MimeType.parse(
        parseMimeTypeAsString(s, defaultMimeType: defaultMimeType),
        defaultMimeType);
  }

  /// Parses only the MIME-Type of the Data URL [s] as string.
  static String? parseMimeTypeAsString(String? s, {String? defaultMimeType}) {
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
  static DataURLBase64? parse(String? s, {String? defaultMimeType}) {
    if (s == null) return null;
    s = s.trim();
    if (s.isEmpty) return null;

    if (!s.startsWith('data:')) return null;

    var idx = s.indexOf(';');
    if (idx < 5) return null;

    String? mimeType = s.substring(5, idx);

    var idx2 = s.indexOf(',');
    if (idx2 < idx + 1) return null;

    var encoding = s.substring(idx + 1, idx2).toLowerCase();

    if (encoding != 'base64') return null;

    var payload = s.substring(idx2 + 1);

    mimeType = MimeType.parseAsString(mimeType, defaultMimeType);

    return DataURLBase64(payload, mimeType);
  }

  String? _dataURLString;

  /// Returns a Data URL string.
  ///
  /// Example: `data:text/plain;base64,SGVsbG8=`
  /// that encodes `Hello` with MIME-Type `text/plain`.
  String asDataURLString() =>
      _dataURLString ??= 'data:$mimeTypeAsString;base64,$payloadBase64';

  @override
  String toString() => asDataURLString();
}

Uint8List? _decodeBase64(String s) {
  try {
    return base64.decode(s);
  } catch (_) {
    return null;
  }
}

final regExpEmail = RegExp(
    r'''^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$''');

/// Returns [true] if [value] represents an e-mail address.
bool isEmail(Object? value) {
  return value is String && value.contains('@') && regExpEmail.hasMatch(value);
}

/// Represents a Geo Location in latitude and longitude.
class Geolocation {
  static final RegExp geolocationFormat =
      RegExp(r'([-=]?)(\d+[,.]?\d*)\s*[°o]?\s*(\w)');

  static num? parseLatitudeOrLongitudeValue(String? s,
      [bool onlyWithCardinals = false]) {
    if (s == null) return null;

    var match = geolocationFormat.firstMatch(s);
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
    return number != null ? double.parse(number) : null;
  }

  static String formatLatitude(num lat) {
    return lat >= 0 ? '$lat°E' : '$lat°W';
  }

  static String formatLongitude(num long) {
    return long >= 0 ? '$long°N' : '$long°S';
  }

  static String formatGeolocation(Point geo) {
    return '${formatLatitude(geo.x)} ${formatLongitude(geo.y)}';
  }

  final num _latitude;

  final num _longitude;

  Geolocation(this._latitude, this._longitude);

  static Geolocation? fromCoords(String? coords,
      [bool onlyWithCardinals = false]) {
    if (coords == null) return null;
    coords = coords.trim();
    if (coords.isEmpty) return null;

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
  String googleMapsDirectionsURL(Geolocation destinationGeo) {
    return 'https://www.google.com/maps/dir/?api=1&origin=$_latitude,$longitude&destination=${destinationGeo.latitude},${destinationGeo.longitude}';
  }
}

/// Parses [value] as a [Rectangle].
Rectangle<num>? parseRectangle(Object? value) {
  if (value is List) return parseRectangleFromList(value);
  if (value is Map) {
    return parseRectangleFromMap(toNonNullMap<String, Object>(value));
  }
  if (value is String) return parseRectangleFromString(value);
  return null;
}

/// Parses [list] as a [Rectangle].
Rectangle<num>? parseRectangleFromList(List list) {
  if (list.length < 4) return null;
  list = list.map((e) => parseNum(e)).whereType<num>().toList();
  if (list.length < 4) return null;
  return Rectangle(list[0], list[1], list[2], list[3]);
}

/// Parses [map] as a [Rectangle].
Rectangle<num>? parseRectangleFromMap(Map<String, Object>? map) {
  if (map == null || map.isEmpty) return null;

  var x = parseNum(findKeyValue(map, ['x', 'left'], true));
  var y = parseNum(findKeyValue(map, ['y', 'top'], true));
  var w = parseNum(findKeyValue(map, ['width', 'w'], true));
  var h = parseNum(findKeyValue(map, ['height', 'h'], true));

  if (x == null || y == null || w == null || h == null) return null;

  return Rectangle(x, y, w, h);
}

/// Parses [s] as a [Rectangle].
Rectangle<num>? parseRectangleFromString(String? s) {
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
Point<num>? parsePoint(Object? value) {
  if (value is List) return parsePointFromList(value);
  if (value is Map) return parsePointFromMap(value);
  if (value is String) return parsePointFromString(value);
  return null;
}

/// Parses [list] as a [Point].
Point<num>? parsePointFromList(List? list) {
  if (list == null || list.length < 2) return null;
  var x = parseNum(list[0]);
  var y = parseNum(list[1]);
  return x != null && y != null ? Point<num>(x, y) : null;
}

/// Parses [map] as a [Point].
Point<num>? parsePointFromMap(Map map) {
  var x = parseNum(
      findKeyValue(toNonNullMap<String, Object>(map), ['x', 'left'], true));
  var y = parseNum(
      findKeyValue(toNonNullMap<String, Object>(map), ['y', 'top'], true));
  if (x == null || y == null) return null;
  return Point<num>(x, y);
}

/// Parses [s] as a [Point].
Point<num>? parsePointFromString(String? s) {
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
String? dataSizeFormat(int? size, {bool? decimalBase, bool? binaryBase}) {
  if (size == null) return null;

  bool? baseDecimal;

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
      return '${formatDecimal(size / (1000 * 1000))!} MB';
    } else {
      return '${formatDecimal(size / (1000 * 1000 * 1000))!} GB';
    }
  } else {
    if (size < 1024) {
      return '$size bytes';
    } else if (size < 1024 * 1024) {
      var s = '${size ~/ 1024} KiB';
      return s;
    } else if (size < 1024 * 1024 * 1024) {
      return '${formatDecimal(size / (1024 * 1024))!} MiB';
    } else {
      return '${formatDecimal(size / (1024 * 1024 * 1024))!} GiB';
    }
  }
}
