import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:swiss_knife/swiss_knife.dart';
import 'package:test/test.dart';

String? _mt(String? s, [String? def]) => MimeType.parseAsString(s, def);

void main() {
  group('MimeType.parse', () {
    test('null, empty and default values', () {
      expect(MimeType.parse(null), isNull);
      expect(MimeType.parse(''), isNull);
      expect(MimeType.parse('   '), isNull);
      expect(MimeType.parse(null, '  '), isNull);
      expect(MimeType.parse('  ', '  '), isNull);
      expect(
        MimeType.parse(null, 'json').toString(),
        equals('application/json'),
      );
      expect(MimeType.parse('  ', ' png ').toString(), equals('image/png'));
      expect(_mt(null), isNull);
      expect(_mt(null, 'text'), equals('text/plain'));
    });

    test('aliases', () {
      expect(_mt('JSON'), equals('application/json'));
      expect(_mt('text/json'), equals('application/json'));
      expect(_mt('javascript'), equals('application/javascript'));
      expect(_mt('js'), equals('application/javascript'));
      expect(_mt('text/javascript'), equals('application/javascript'));
      expect(_mt('text/js'), equals('application/javascript'));
      expect(_mt('jpg'), equals('image/jpeg'));
      expect(_mt('image/jpg'), equals('image/jpeg'));
      expect(_mt('png'), equals('image/png'));
      expect(_mt('svg'), equals('image/svg+xml'));
      expect(_mt('image/svg+xml'), equals('image/svg+xml'));
      expect(_mt('text'), equals('text/plain'));
      expect(_mt('txt'), equals('text/plain'));
      expect(_mt('css'), equals('text/css'));
      expect(_mt('html'), equals('text/html'));
      expect(_mt('htm'), equals('text/html'));
      expect(_mt('text/htm'), equals('text/html'));
      expect(_mt('icon'), equals('image/x-icon'));
      expect(_mt('ico'), equals('image/x-icon'));
      expect(_mt('image/icon'), equals('image/x-icon'));
      expect(_mt('image/x-icon'), equals('image/x-icon'));
      expect(_mt('gif'), equals('image/gif'));
      expect(_mt('otf'), equals('font/otf'));
      expect(_mt('ttf'), equals('font/ttf'));
      expect(_mt('woff'), equals('font/woff'));
      expect(_mt('woff2'), equals('font/woff2'));
      expect(_mt('font/woff2'), equals('font/woff2'));
      expect(_mt('webp'), equals('image/webp'));
      expect(_mt('weba'), equals('audio/webm'));
      expect(_mt('audio/weba'), equals('audio/webm'));
      expect(_mt('audio/webm'), equals('audio/webm'));
      expect(_mt('webm'), equals('video/webm'));
      expect(_mt('video/webm'), equals('video/webm'));
      expect(_mt('yaml'), equals('application/yaml'));
      expect(_mt('yml'), equals('application/yaml'));
      expect(_mt('text/yaml'), equals('application/yaml'));
      expect(_mt('xml'), equals('application/xml'));
      expect(_mt('text/xml'), equals('application/xml'));
      expect(_mt('zip'), equals('application/zip'));
      expect(_mt('gzip'), equals('application/gzip'));
      expect(_mt('gz'), equals('application/gzip'));
      expect(_mt('pdf'), equals('application/pdf'));
      expect(_mt('md'), equals('text/markdown'));
      expect(_mt('markdown'), equals('text/markdown'));
      expect(_mt('dart'), equals('application/dart'));
      expect(_mt('mpeg'), equals('video/mpeg'));
      expect(_mt('video/mpeg'), equals('video/mpeg'));
    });

    test('mp3 / audio/mpeg', () {
      // NOTE: current behaviour; possibly a bug: `MimeType.mp3` is
      // 'audio/mpeg', but parsing it yields the non-standard 'audio/mp3'.
      expect(_mt('mp3'), equals('audio/mp3'));
      expect(_mt(MimeType.mp3), equals('audio/mp3'));
      expect(MimeType.parse(MimeType.mp3), isNot(MimeType('audio', 'mpeg')));
    });

    test('xhtml', () {
      // Regression: parsing 'xhtml' (and even the `MimeType.xhtml` constant
      // 'application/xhtml+xml') yielded 'application/xhtml', so `isXHTML`
      // was false.
      expect(_mt('xhtml'), equals('application/xhtml+xml'));
      expect(_mt(MimeType.xhtml), equals('application/xhtml+xml'));
      expect(MimeType.parse(MimeType.xhtml)!.isXHTML, isTrue);
      expect(MimeType.parse(MimeType.xhtml)!.fileExtension, equals('xhtml'));
      expect(MimeType.byExtension('xhtml')!.isXHTML, isTrue);
      expect(MimeType('application', 'xhtml+xml').isXHTML, isTrue);
    });

    test('generic types and invalid', () {
      expect(_mt('Foo/Bar'), equals('foo/bar'));
      expect(_mt('something'), equals('application/something'));
      expect(() => MimeType.parse('foo/'), throwsArgumentError);
      // NOTE: current behaviour; possibly a bug: a leading '/' isn't rejected
      // and produces a sub-type containing the slash.
      expect(_mt('/foo'), equals('application//foo'));
    });

    test('charset', () {
      expect(
        _mt('application/json; charset=UTF-8'),
        equals('application/json; charset=utf-8'),
      );
      expect(
        _mt('text/plain; charset=ISO-8859-1'),
        equals('text/plain; charset=iso-8859-1'),
      );
      expect(_mt('png;charset=utf8'), equals('image/png; charset=utf8'));
      expect(_mt('text/plain; '), equals('text/plain'));

      // NOTE: current behaviour; possibly a bug: the jpeg and 'text'/'txt'
      // branches drop the parsed charset, unlike every other branch.
      expect(_mt('image/jpeg; charset=utf-8'), equals('image/jpeg'));
      expect(_mt('txt; charset=utf-8'), equals('text/plain'));
      expect(
        _mt('xhtml; charset=utf-8'),
        equals('application/xhtml+xml; charset=utf-8'),
      );
    });
  });

  group('MimeType.byExtension', () {
    test('known extensions', () {
      String? ext(String e) => MimeType.byExtension(e)?.toString();

      expect(MimeType.byExtension(null), isNull);
      expect(ext('file.ZIP'), equals('application/zip'));
      expect(ext('gzip'), equals('application/gzip'));
      expect(ext('archive.tar.gz'), equals('application/gzip'));
      expect(ext('png'), equals('image/png'));
      expect(ext('photo.jpeg'), equals('image/jpeg'));
      expect(ext('jpg'), equals('image/jpeg'));
      expect(ext('gif'), equals('image/gif'));
      expect(ext('css'), equals('text/css'));
      expect(ext('json'), equals('application/json'));
      expect(ext('js'), equals('application/javascript'));
      expect(ext('javascript'), equals('application/javascript'));
      expect(ext('index.html'), equals('text/html'));
      expect(ext('htm'), equals('text/html'));
      expect(ext('xhtml'), equals('application/xhtml+xml'));
      expect(ext('text'), equals('text/plain'));
      expect(ext('txt'), equals('text/plain'));
      expect(ext('pdf'), equals('application/pdf'));
      expect(ext('mp3'), equals('audio/mp3'));
      expect(ext('mpeg'), equals('video/mpeg'));
      expect(ext('xml'), equals('application/xml'));
      expect(ext('icon'), equals('image/x-icon'));
      expect(ext('favicon.ico'), equals('image/x-icon'));
      expect(ext('svg'), equals('image/svg+xml'));
      expect(ext('webp'), equals('image/webp'));
      expect(ext('weba'), equals('audio/webm'));
      expect(ext('webm'), equals('video/webm'));
      expect(ext('otf'), equals('font/otf'));
      expect(ext('ttf'), equals('font/ttf'));
      expect(ext('woff'), equals('font/woff'));
      expect(ext('woff2'), equals('font/woff2'));
      expect(ext('README.md'), equals('text/markdown'));
      expect(ext('yaml'), equals('application/yaml'));
      expect(ext('pubspec.yml'), equals('application/yaml'));
      expect(ext('main.dart'), equals('application/dart'));
    });

    test('unknown extension', () {
      expect(
        MimeType.byExtension('file.Foo').toString(),
        equals('application/foo'),
      );
      expect(
        MimeType.byExtension('file.foo', defaultAsApplication: false),
        isNull,
      );
    });
  });

  group('MimeType', () {
    test('normalizeCharset', () {
      expect(MimeType.normalizeCharset(null), isNull);
      expect(MimeType.normalizeCharset(''), isNull);
      expect(MimeType.normalizeCharset('charset= '), isNull);
      expect(MimeType.normalizeCharset('CHARSET=UTF-8'), equals('utf-8'));
      expect(MimeType.normalizeCharset(' Latin1 '), equals('latin1'));
    });

    test('charset getters and encoding', () {
      var noCharset = MimeType('text', 'plain');
      expect(noCharset.charset, isNull);
      expect(noCharset.hasCharset, isFalse);
      expect(noCharset.charsetEncoding, isNull);

      var u8 = MimeType('text', 'plain', 'UTF-8');
      expect(u8.hasCharset, isTrue);
      expect(u8.isCharsetUTF8, isTrue);
      expect(u8.isCharsetUTF16, isFalse);
      expect(u8.isCharsetLATIN1, isFalse);
      expect(u8.charsetEncoding, same(utf8));
      expect(MimeType('text', 'plain', 'utf8').isCharsetUTF8, isTrue);

      var u16 = MimeType('text', 'plain', 'utf-16');
      expect(u16.isCharsetUTF16, isTrue);
      expect(MimeType('text', 'plain', 'utf16').isCharsetUTF16, isTrue);
      expect(u16.charsetEncoding, isNull);

      for (var cs in ['latin1', 'latin-1', 'iso-8859-1', 'iso88591']) {
        var m = MimeType('text', 'plain', cs);
        expect(m.isCharsetLATIN1, isTrue, reason: cs);
        expect(m.charsetEncoding, same(latin1), reason: cs);
      }
    });

    test('getCharsetEncoding', () {
      expect(getCharsetEncoding(null), isNull);
      expect(getCharsetEncoding(''), isNull);
      expect(getCharsetEncoding('UTF-8'), same(utf8));
      expect(getCharsetEncoding('ISO-8859-1'), same(latin1));
      expect(getCharsetEncoding('utf-16'), isNull);
    });

    test('type checks and htmlTag', () {
      var jpeg = MimeType.parse('jpeg')!;
      expect(jpeg.isImage, isTrue);
      expect(jpeg.isImageJPEG, isTrue);
      expect(jpeg.isImagePNG, isFalse);
      expect(jpeg.htmlTag, equals('img'));

      expect(MimeType.parse('png')!.isImagePNG, isTrue);
      expect(MimeType.parse('webp')!.isImageWebP, isTrue);
      expect(MimeType.parse('svg')!.isImageSVG, isTrue);
      expect(MimeType('text', 'png').isImagePNG, isFalse);

      var video = MimeType.parse('webm')!;
      expect(video.isVideo, isTrue);
      expect(video.htmlTag, equals('video'));

      var audio = MimeType.parse('weba')!;
      expect(audio.isAudio, isTrue);
      expect(audio.htmlTag, equals('audio'));

      expect(MimeType.parse('text')!.htmlTag, isNull);
      expect(MimeType.parse('woff')!.isFont, isTrue);

      expect(MimeType.parse('js')!.isJavascript, isTrue);
      expect(MimeType.parse('json')!.isJSON, isTrue);
      expect(MimeType.parse('yaml')!.isYAML, isTrue);
      expect(MimeType.parse('css')!.isText, isTrue);
      expect(MimeType.parse('xml')!.isXML, isTrue);
      expect(
        MimeType.parse('application/x-www-form-urlencoded')!.isFormURLEncoded,
        isTrue,
      );
      expect(
        MimeType('text', 'x-www-form-urlencoded').isFormURLEncoded,
        isFalse,
      );
      expect(MimeType.parse('pdf')!.isPDF, isTrue);
      expect(MimeType.parse('dart')!.isDart, isTrue);
      expect(MimeType.parse('zip')!.isZip, isTrue);
      expect(MimeType.parse('gz')!.isGZip, isTrue);
      expect(MimeType.parse('application/octet-stream')!.isOctetStream, isTrue);
      expect(MimeType('text', 'octet-stream').isOctetStream, isFalse);
    });

    test('compression types', () {
      MimeType app(String sub) => MimeType('application', sub);

      expect(app('bzip2').isBZip2, isTrue);
      expect(app('x-xz').isXZ, isTrue);
      expect(app('x-tar').isTar, isTrue);
      expect(app('x-tar').isTarCompressed, isFalse);
      expect(app('x-tar').isCompressed, isFalse);
      expect(app('x-tar+gzip').isTarGZip, isTrue);
      expect(app('x-tar+bzip2').isTarBZip2, isTrue);
      expect(app('x-tar+xz').isTarXZ, isTrue);

      for (var sub in [
        'zip',
        'gzip',
        'bzip2',
        'x-xz',
        'x-tar+gzip',
        'x-tar+bzip2',
        'x-tar+xz',
      ]) {
        expect(app(sub).isCompressed, isTrue, reason: sub);
      }
      for (var sub in ['x-tar+gzip', 'x-tar+bzip2', 'x-tar+xz']) {
        expect(app(sub).isTarCompressed, isTrue, reason: sub);
      }
      expect(app('json').isCompressed, isFalse);
    });

    test('isStringType', () {
      for (var m in [
        'text/plain',
        'json',
        'js',
        'yaml',
        'application/x-www-form-urlencoded',
        'xml',
        'dart',
        'svg',
      ]) {
        expect(MimeType.parse(m)!.isStringType, isTrue, reason: m);
      }
      expect(MimeType('application', 'xhtml+xml').isStringType, isTrue);
      expect(MimeType.parse('png')!.isStringType, isFalse);
      expect(MimeType.parse('pdf')!.isStringType, isFalse);
    });

    test('preferredStringEncoding', () {
      Encoding? enc(String m) => MimeType.parse(m)!.preferredStringEncoding;

      expect(enc('image/png; charset=utf-8'), same(utf8));
      expect(enc('application/zip; charset=latin1'), same(latin1));
      expect(enc('text/plain'), same(utf8));
      expect(enc('json'), same(utf8));
      expect(enc('svg'), same(utf8));
      expect(enc('png'), same(latin1));
      expect(enc('webm'), same(latin1));
      expect(enc('weba'), same(latin1));
      expect(enc('ttf'), same(latin1));
      expect(enc('application/octet-stream'), same(latin1));
      expect(enc('zip'), same(latin1));
      expect(enc('application/x-tar'), same(latin1));
      expect(enc('pdf'), same(latin1));
      expect(enc('application/x-unknown'), isNull);
    });

    test('fileExtension', () {
      expect(MimeType.parse('js')!.fileExtension, equals('js'));
      expect(MimeType.parse('gzip')!.fileExtension, equals('gz'));
      expect(MimeType.parse('zip')!.fileExtension, equals('zip'));
      expect(MimeType.parse('svg')!.fileExtension, equals('svg'));
      expect(
        MimeType('application', 'xhtml+xml').fileExtension,
        equals('xhtml'),
      );
      expect(MimeType('audio', 'mpeg').fileExtension, equals('mp3'));
      // Regression: 'video/mpeg' mapped to the non-existent extension 'mp3g'.
      expect(MimeType('video', 'mpeg').fileExtension, equals('mpg'));
      expect(MimeType.parse('ico')!.fileExtension, equals('ico'));
      expect(MimeType.parse('png')!.fileExtension, equals('png'));
      expect(MimeType.parse('pdf')!.fileExtension, equals('pdf'));
    });

    test('fileName', () {
      var png = MimeType.parse('png')!;
      expect(png.fileName(), equals('image.png'));
      expect(png.fileName('   '), equals('image.png'));
      expect(png.fileName(' my file.v1 '), equals('image-my_file_v1.png'));
      expect(png.fileName('x', ' _ '), equals('image_x.png'));
      expect(png.fileNameTimeMillis(123), equals('image-123.png'));
      expect(png.fileNameTimeMillis(), matches(RegExp(r'^image-\d+\.png$')));
      expect(png.fileNameRandom(), matches(RegExp(r'^image-\w+\.png$')));
      expect(
        MimeType.parse('js')!.fileName('app'),
        equals('application-app.js'),
      );
    });

    test('equality, hashCode and toString', () {
      var a = MimeType('text', 'plain', 'utf-8');
      var b = MimeType('text', 'plain');
      var c = MimeType('text', 'html');

      expect(a == a, isTrue);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
      expect(a, isNot(equals('text/plain')));

      expect(a.fullType, equals('text/plain'));
      expect(a.toString(), equals('text/plain; charset=utf-8'));
      expect(a.toString(true), equals('text/plain; charset=utf-8'));
      expect(a.toString(false), equals('text/plain'));
      expect(b.toString(true), equals('text/plain'));
    });

    test('asString', () {
      expect(MimeType.asString(null), isNull);
      expect(MimeType.asString(null, 'text/html'), equals('text/html'));
      expect(MimeType.asString('json'), equals('application/json'));
      expect(MimeType.asString(MimeType('image', 'png')), equals('image/png'));
      expect(MimeType.asString(123, 'x/y'), equals('x/y'));
      expect(MimeType.asString(123), isNull);
      expect(MimeType.asString('', 'x/y'), equals('x/y'));
    });

    test('constants', () {
      expect(MimeType.bytes, equals('application/octet-stream'));
      expect(MimeType.json, equals('application/json'));
      expect(MimeType.javaScript, equals('application/javascript'));
      expect(MimeType.zip, equals('application/zip'));
      expect(MimeType.gzip, equals('application/gzip'));
      expect(MimeType.pdf, equals('application/pdf'));
      expect(MimeType.jpeg, equals('image/jpeg'));
      expect(MimeType.png, equals('image/png'));
      expect(MimeType.gif, equals('image/gif'));
      expect(MimeType.icon, equals('image/x-icon'));
      expect(MimeType.svg, equals('image/svg+xml'));
      expect(MimeType.webp, equals('image/webp'));
      expect(MimeType.weba, equals('audio/webm'));
      expect(MimeType.webm, equals('video/webm'));
      expect(MimeType.html, equals('text/html'));
      expect(MimeType.css, equals('text/css'));
      expect(MimeType.text, equals('text/plain'));
      expect(MimeType.xml, equals('application/xml'));
      expect(MimeType.xhtml, equals('application/xhtml+xml'));
      expect(MimeType.mpeg, equals('video/mpeg'));
      expect(MimeType.mp3, equals('audio/mpeg'));
      expect(MimeType.yaml, equals('application/yaml'));
      expect(MimeType.markdown, equals('text/markdown'));
      expect(MimeType.dart, equals('application/dart'));
      expect(MimeType.otf, equals('font/otf'));
      expect(MimeType.ttf, equals('font/ttf'));
      expect(MimeType.woff, equals('font/woff'));
      expect(MimeType.woff2, equals('font/woff2'));
    });
  });

  group('Base64', () {
    test('encode/decode', () {
      expect(
        Base64.encodeArrayBuffer(Uint8List.fromList([1, 2, 3])),
        equals('AQID'),
      );
      expect(Base64.decodeAsArrayBuffer('AQID'), equals([1, 2, 3]));
      expect(Base64.encode('Olá'), equals('T2zDoQ=='));
      expect(Base64.decode('T2zDoQ=='), equals('Olá'));
    });
  });

  group('DataURLBase64', () {
    test('parsePayload*', () {
      expect(DataURLBase64.parsePayloadAsBase64(null), isNull);
      expect(DataURLBase64.parsePayloadAsBase64('data'), isNull);
      expect(DataURLBase64.parsePayloadAsBase64('http://foo'), isNull);
      expect(
        DataURLBase64.parsePayloadAsBase64('data:text/plain;base64,SGVsbG8='),
        equals('SGVsbG8='),
      );

      expect(
        DataURLBase64.parsePayloadAsArrayBuffer('data:x/y;base64,AQID'),
        equals([1, 2, 3]),
      );
      expect(DataURLBase64.parsePayloadAsArrayBuffer('nope'), isNull);

      // Decoded as LATIN-1: 0xE9 => 'é'.
      expect(
        DataURLBase64.parsePayloadAsString('data:text/plain;base64,6Q=='),
        equals('é'),
      );
      expect(DataURLBase64.parsePayloadAsString('nope'), isNull);
    });

    test('constructor and getters', () {
      var d = DataURLBase64('AQID', 'png');
      expect(d.mimeType, equals(MimeType('image', 'png')));
      expect(d.mimeTypeAsString, equals('image/png'));
      expect(d.payloadArrayBuffer, equals([1, 2, 3]));
      expect(d.asDataURLString(), equals('data:image/png;base64,AQID'));
      expect(d.toString(), equals('data:image/png;base64,AQID'));

      var noMime = DataURLBase64('SGVsbG8=');
      expect(noMime.mimeType, isNull);
      expect(noMime.mimeTypeAsString, equals(''));
      expect(noMime.payload, equals('Hello'));
      expect(noMime.toString(), equals('data:;base64,SGVsbG8='));
    });

    test('from', () {
      expect(
        DataURLBase64.from([1, 2, 3], MimeType('image', 'png')).toString(),
        equals('data:image/png;base64,AQID'),
      );
      expect(
        DataURLBase64.from(Uint8List.fromList([1, 2, 3]), 'gif').toString(),
        equals('data:image/gif;base64,AQID'),
      );

      var base = DataURLBase64('AQID', 'png');
      expect(
        DataURLBase64.from(base).toString(),
        equals('data:image/png;base64,AQID'),
      );
      expect(
        DataURLBase64.from(base, 'gif').toString(),
        equals('data:image/gif;base64,AQID'),
      );

      expect(
        DataURLBase64.from('data:image/png;base64,AQID', 'jpeg').toString(),
        equals('data:image/jpeg;base64,AQID'),
      );

      // A valid Base-64 string is used as payload directly:
      expect(
        DataURLBase64.from('AQID').toString(),
        equals('data:;base64,AQID'),
      );

      // Non Base-64 content is encoded as `text/plain` by default:
      expect(
        DataURLBase64.from('Hello').toString(),
        equals('data:text/plain;base64,SGVsbG8='),
      );
      expect(
        DataURLBase64.from('Hello', 'html').toString(),
        equals('data:text/html;base64,SGVsbG8='),
      );
      expect(DataURLBase64.from(12345).payload, equals('12345'));
    });

    test('parseMimeType / parseMimeTypeAsString', () {
      expect(
        DataURLBase64.parseMimeType('data:image/png;base64,AQID'),
        equals(MimeType('image', 'png')),
      );
      expect(DataURLBase64.parseMimeType('foo'), isNull);
      expect(
        DataURLBase64.parseMimeType('foo', defaultMimeType: 'json'),
        equals(MimeType('application', 'json')),
      );

      expect(DataURLBase64.parseMimeTypeAsString(null), isNull);
      expect(
        DataURLBase64.parseMimeTypeAsString(null, defaultMimeType: 'd'),
        equals('d'),
      );
      expect(
        DataURLBase64.parseMimeTypeAsString('  ', defaultMimeType: 'd'),
        equals('d'),
      );
      expect(
        DataURLBase64.parseMimeTypeAsString('http:x', defaultMimeType: 'd'),
        equals('d'),
      );
      expect(
        DataURLBase64.parseMimeTypeAsString('data:,abc', defaultMimeType: 'd'),
        equals('d'),
      );
      expect(
        DataURLBase64.parseMimeTypeAsString(
          'data: ;base64,',
          defaultMimeType: 'd',
        ),
        equals('d'),
      );
      expect(
        DataURLBase64.parseMimeTypeAsString(' data: IMAGE/PNG ;base64,AQID'),
        equals('image/png'),
      );
    });

    test('parse', () {
      expect(DataURLBase64.parse(null), isNull);
      expect(DataURLBase64.parse('  '), isNull);
      expect(DataURLBase64.parse('foo'), isNull);
      expect(DataURLBase64.parse('data:text/plain'), isNull);
      expect(DataURLBase64.parse('data:text/plain;base64'), isNull);
      expect(DataURLBase64.parse('data:text/plain;utf8,abc'), isNull);

      var d = DataURLBase64.parse(' data:TEXT/PLAIN;BASE64,SGVsbG8= ')!;
      expect(d.mimeTypeAsString, equals('text/plain'));
      expect(d.payload, equals('Hello'));

      var noMime = DataURLBase64.parse('data:;base64,AQID')!;
      expect(noMime.mimeType, isNull);

      var def = DataURLBase64.parse(
        'data:;base64,AQID',
        defaultMimeType: 'png',
      )!;
      expect(def.mimeTypeAsString, equals('image/png'));

      expect(DataURLBase64.matches('data:x/y;base64,AQID'), isTrue);
      expect(DataURLBase64.matches('data:x/y,AQID'), isFalse);
    });
  });

  group('isEmail', () {
    test('valid and invalid', () {
      expect(isEmail('joe@example.com'), isTrue);
      expect(isEmail('a.b+c@sub.example.org'), isTrue);
      expect(isEmail('a@localhost'), isTrue);

      expect(isEmail(null), isFalse);
      expect(isEmail(123), isFalse);
      expect(isEmail('abc'), isFalse);
      expect(isEmail('a@'), isFalse);
      expect(isEmail('@b.com'), isFalse);
      expect(isEmail('a@-b.com'), isFalse);
      expect(isEmail('a b@c.com'), isFalse);
      expect(regExpEmail.hasMatch('x@y.z'), isTrue);
    });
  });

  group('Geolocation', () {
    test('parseLatitudeOrLongitudeValue', () {
      num? p(String? s, [bool only = false]) =>
          Geolocation.parseLatitudeOrLongitudeValue(s, only);

      expect(p(null), isNull);
      expect(p('abc'), isNull);
      expect(p('10.5N'), equals(10.5));
      expect(p('10.5n'), equals(10.5));
      expect(p('10.5S'), equals(-10.5));
      expect(p('20.25E'), equals(20.25));
      expect(p('20.25W'), equals(-20.25));
      expect(p('10.5°N'), equals(10.5));
      expect(p('10.5 ° S'), equals(-10.5));
      expect(p('10.5N', true), equals(10.5));

      // Explicit sign wins over the cardinal:
      expect(p('-10.5N'), equals(-10.5));
      expect(p('-10.5N', true), isNull);

      // Unknown cardinal:
      expect(p('10.5X'), equals(10.5));
      expect(p('10.5X', true), isNull);

      // NOTE: current behaviour; possibly a bug: the format RegExp requires a
      // trailing word char (the cardinal), so a plain number loses its last
      // digit: '123' parses as 12.
      expect(p('123'), equals(12));
      expect(p('123', true), isNull);

      // NOTE: current behaviour; possibly a bug: the RegExp accepts '=' as a
      // sign and ',' as decimal separator, but neither is valid for
      // `double.parse`, so these throw instead of returning a value or null.
      expect(() => p('=10.5N'), throwsFormatException);
      expect(() => p('10,5N'), throwsFormatException);
    });

    test('format', () {
      // NOTE: current behaviour; possibly a bug: latitude is formatted with
      // E/W and longitude with N/S (swapped), and negative values keep the
      // minus sign in addition to the W/S cardinal.
      expect(Geolocation.formatLatitude(10), equals('10°E'));
      expect(Geolocation.formatLatitude(-10), equals('-10°W'));
      expect(Geolocation.formatLongitude(20), equals('20°N'));
      expect(Geolocation.formatLongitude(-20), equals('-20°S'));
      expect(
        Geolocation.formatGeolocation(const Point(1, -2)),
        equals('1°E -2°S'),
      );
    });

    test('instance', () {
      var geo = Geolocation(10.5, -20.25);
      expect(geo.latitude, equals(10.5));
      expect(geo.longitude, equals(-20.25));
      expect(geo.asPoint(), equals(const Point(10.5, -20.25)));
      expect(geo.toString(), equals('10.5°E -20.25°S'));
      expect(geo.windowID('geo'), equals('geo__10.5__-20.25'));
      expect(
        geo.googleMapsURL(),
        equals('https://www.google.com/maps/search/?api=1&query=10.5,-20.25'),
      );
      expect(
        geo.googleMapsDirectionsURL(Geolocation(1.5, 2.5)),
        equals(
          'https://www.google.com/maps/dir/?api=1&origin=10.5,-20.25'
          '&destination=1.5,2.5',
        ),
      );
    });

    test('fromCoords', () {
      expect(Geolocation.fromCoords(null), isNull);
      expect(Geolocation.fromCoords('   '), isNull);
      expect(Geolocation.fromCoords('10.5N'), isNull);
      expect(Geolocation.fromCoords('abc def'), isNull);

      var geo = Geolocation.fromCoords(' 10.5N   20.25W ')!;
      expect(geo.latitude, equals(10.5));
      expect(geo.longitude, equals(-20.25));

      expect(Geolocation.fromCoords('-10.5N 20.25W', true), isNull);
      var geo2 = Geolocation.fromCoords('10.5S 20.25E', true)!;
      expect(geo2.asPoint(), equals(const Point(-10.5, 20.25)));
    });
  });

  group('parseRectangle', () {
    test('from list', () {
      expect(parseRectangle([1, 2, 3, 4]), equals(const Rectangle(1, 2, 3, 4)));
      expect(
        parseRectangle(['1', '2', '3.5', '4']),
        equals(const Rectangle(1, 2, 3.5, 4)),
      );
      expect(parseRectangleFromList([1, 2, 3]), isNull);
      expect(parseRectangleFromList([1, 'x', 3, 4]), isNull);
    });

    test('from map', () {
      expect(
        parseRectangle({'x': 1, 'y': 2, 'width': 3, 'height': 4}),
        equals(const Rectangle(1, 2, 3, 4)),
      );
      expect(
        parseRectangle({'LEFT': '1', 'Top': 2, 'W': 3, 'h': '4'}),
        equals(const Rectangle(1, 2, 3, 4)),
      );
      expect(parseRectangleFromMap(null), isNull);
      expect(parseRectangleFromMap({}), isNull);
      expect(parseRectangle({'x': 1, 'y': 2, 'w': 3}), isNull);
    });

    test('from string', () {
      expect(
        parseRectangle(' 1, 2 ,3 , 4 '),
        equals(const Rectangle(1, 2, 3, 4)),
      );
      expect(parseRectangleFromString(null), isNull);
      expect(parseRectangleFromString('  '), isNull);
      expect(parseRectangleFromString('1,2,3'), isNull);
      expect(parseRectangleFromString('a,b,c,d'), isNull);
    });

    test('other types', () {
      expect(parseRectangle(null), isNull);
      expect(parseRectangle(123), isNull);
    });
  });

  group('parsePoint', () {
    test('from list', () {
      expect(parsePoint([1, 2]), equals(const Point(1, 2)));
      expect(parsePoint(['1.5', 2]), equals(const Point(1.5, 2)));
      expect(parsePointFromList(null), isNull);
      expect(parsePointFromList([1]), isNull);
      expect(parsePointFromList([1, 'x']), isNull);
    });

    test('from map', () {
      expect(parsePoint({'x': 1, 'y': 2}), equals(const Point(1, 2)));
      expect(parsePoint({'Left': '3', 'TOP': '4'}), equals(const Point(3, 4)));
      expect(parsePointFromMap({'x': 1}), isNull);
    });

    test('from string', () {
      expect(parsePoint(' 1 , 2 '), equals(const Point(1, 2)));
      expect(parsePointFromString(null), isNull);
      expect(parsePointFromString(' '), isNull);
      expect(parsePointFromString('1'), isNull);
      expect(parsePointFromString('a,b'), isNull);
    });

    test('other types', () {
      expect(parsePoint(null), isNull);
      expect(parsePoint(true), isNull);
    });
  });

  group('dataSizeFormat', () {
    test('decimal base (default)', () {
      expect(dataSizeFormat(null), isNull);
      expect(dataSizeFormat(0), equals('0 bytes'));
      expect(dataSizeFormat(999), equals('999 bytes'));
      expect(dataSizeFormat(1000), equals('1 KB'));
      expect(dataSizeFormat(1999), equals('1 KB'));
      expect(dataSizeFormat(1500000), equals('1.5 MB'));
      expect(dataSizeFormat(1234567), equals('1.23 MB'));
      expect(dataSizeFormat(2500000000), equals('2.5 GB'));
      expect(dataSizeFormat(3000000000), equals('3 GB'));
    });

    test('binary base', () {
      expect(dataSizeFormat(1023, decimalBase: false), equals('1023 bytes'));
      expect(dataSizeFormat(2048, decimalBase: false), equals('2 KiB'));
      expect(dataSizeFormat(1572864, binaryBase: true), equals('1.5 MiB'));
      expect(dataSizeFormat(3221225472, binaryBase: true), equals('3 GiB'));
      expect(
        dataSizeFormat(2048, decimalBase: false, binaryBase: true),
        equals('2 KiB'),
      );
    });

    test('flag combinations', () {
      expect(
        dataSizeFormat(2048, decimalBase: true, binaryBase: true),
        equals('2 KB'),
      );
      expect(dataSizeFormat(2048, binaryBase: false), equals('2 KB'));
      // Both flags false: falls back to the decimal base.
      expect(
        dataSizeFormat(2048, decimalBase: false, binaryBase: false),
        equals('2 KB'),
      );
    });
  });
}
