import 'package:swiss_knife/swiss_knife.dart';
import 'package:test/test.dart';

void main() {
  group('Uri base', () {
    test('getUriBase* reflect Uri.base', () {
      var base = Uri.base;
      expect(getUriBase(), equals(base));
      expect(getUriBaseScheme(), equals(base.scheme));
      expect(getUriBaseHost(), equals(base.host));
      expect(getUriBasePort(), equals(base.port));
      expect(isUriBaseIP(), equals(isIPAddress(base.host)));
      expect(
        isUriBaseLocalhost(),
        equals(base.host.isEmpty || isLocalhost(base.host)),
      );
    });

    test('getUriBaseHostAndPort', () {
      var host = Uri.base.host;
      expect(getUriBaseHostAndPort(port: 80), equals(host));
      expect(
        getUriBaseHostAndPort(port: 80, suppressPort80: false),
        equals('$host:80'),
      );
      expect(getUriBaseHostAndPort(port: 0), equals(host));
      expect(getUriBaseHostAndPort(port: 8080), equals('$host:8080'));
      expect(
        getUriRootURL(port: 8080),
        equals('${Uri.base.scheme}://$host:8080/'),
      );
      expect(getUriRootURL(port: 80), equals('${Uri.base.scheme}://$host/'));
    });
  });

  group('buildUri', () {
    test('ports and schemes', () {
      expect(buildUri('https', 'foo', 0).toString(), equals('https://foo/'));
      expect(buildUri('https', 'foo', 443).toString(), equals('https://foo/'));
      expect(
        buildUri('https', 'foo', 8443).toString(),
        equals('https://foo:8443/'),
      );
      expect(buildUri('http', 'foo', null).toString(), equals('http://foo/'));
      expect(buildUri('ftp', 'foo', 21).toString(), equals('ftp://foo:21/'));
      expect(
        buildUri('http', 'foo', 80, path: 'a/b').toString(),
        equals('http://foo/a/b'),
      );
      expect(
        buildUri('http', 'foo', 80, queryString: '', fragment: '').toString(),
        equals('http://foo/'),
      );
    });

    test('query and fragment inside path', () {
      expect(
        buildUri('http', 'foo', 80, path: '/a/b?x=1#frag').toString(),
        equals('http://foo/a/b?x=1#frag'),
      );
      expect(
        buildUri(
          'http',
          'foo',
          80,
          path: '/a/b?x=1#frag',
          queryString: 'y=2',
          fragment: 'f2',
        ).toString(),
        equals('http://foo/a/b?x=1&y=2#frag&f2'),
      );
      expect(
        buildUri('http', 'foo', 80, path: '/a/b?#').toString(),
        equals('http://foo/a/b'),
      );
    });

    test('path2 overriding query/fragment from path', () {
      expect(
        buildUri(
          'http',
          'foo',
          80,
          path: '/a/b?x=1#frag',
          path2: 'c?z=3#f3',
        ).toString(),
        equals('http://foo/a/c?z=3#f3'),
      );
      // Query/fragment coming only from `path` are dropped when `path2` is set:
      expect(
        buildUri(
          'http',
          'foo',
          80,
          path: '/a/b?x=1#frag',
          path2: 'c',
        ).toString(),
        equals('http://foo/a/c'),
      );
    });

    test('path2 combining with explicit query/fragment', () {
      expect(
        buildUri(
          'http',
          'foo',
          80,
          path: '/a/b',
          queryString: 'q=1',
          fragment: 'f',
          path2: 'c?z=3#f3',
        ).toString(),
        equals('http://foo/a/c?z=3&q=1#f3&f'),
      );
      expect(
        buildUri(
          'http',
          'foo',
          80,
          path: '/a/b',
          queryString: 'q=1',
          fragment: 'f',
          path2: 'c?#',
        ).toString(),
        equals('http://foo/a/c?q=1#f'),
      );
      expect(
        buildUri('http', 'foo', 80, path: '/a/b', path2: 'c?z=3#f3').toString(),
        equals('http://foo/a/c?z=3#f3'),
      );
    });

    test('path2 resolution', () {
      expect(
        buildUri('http', 'foo', 80, path: '/a/b', path2: './d').toString(),
        equals('http://foo/a/d'),
      );
      expect(
        buildUri('http', 'foo', 80, path: '/a/b/', path2: 'd').toString(),
        equals('http://foo/a/b/d'),
      );
      expect(
        buildUri('http', 'foo', 80, path: '/a/b', path2: '/abs').toString(),
        equals('http://foo/abs'),
      );
      expect(
        buildUri('http', 'foo', 80, path: '/a/b', path2: '').toString(),
        equals('http://foo/a/b'),
      );
    });
  });

  group('remove/resolve', () {
    test('removeUriQueryString/removeUriFragment', () {
      expect(
        removeUriQueryString('http://foo:81/a?x=1#f').toString(),
        equals('http://foo:81/a#f'),
      );
      expect(
        removeUriFragment('https://foo/a?x=1#f').toString(),
        equals('https://foo/a?x=1'),
      );
    });

    test('resolveUri/resolveURL with explicit base', () {
      var base = Uri.parse('http://h:81/a/b.html');

      expect(resolveUri('', baseUri: base), same(base));
      expect(resolveUri('/', baseUri: base), same(base));
      expect(resolveUri('./', baseUri: base), same(base));
      expect(
        resolveUri('  c.txt ', baseUri: base).toString(),
        equals('http://h:81/a/c.txt'),
      );

      expect(
        resolveURL('c.txt', baseURL: 'http://h:81/a/b.html'),
        equals('http://h:81/a/c.txt'),
      );
      expect(
        resolveURL('/x?y=1', baseURL: 'https://h/a/'),
        equals('https://h/x?y=1'),
      );
      expect(
        resolveURL('http://other.com/z', baseURL: 'https://h/a/'),
        equals('http://other.com/z'),
      );
      expect(resolveURL('', baseURL: 'https://h/a/'), equals('https://h/a/'));
    });

    test('resolveUri without base uses Uri.base', () {
      expect(resolveUri(''), equals(Uri.base));
      expect(resolveUri('./'), equals(Uri.base));
      expect(resolveURL('/'), equals(getUriRoot().toString()));
    });
  });

  group('host checks', () {
    test('isLocalhost', () {
      expect(isLocalhost(null), isFalse);
      expect(isLocalhost(''), isFalse);
      expect(isLocalhost('localhost'), isTrue);
      expect(isLocalhost('127.0.0.1'), isTrue);
      expect(isLocalhost('::1'), isTrue);
      expect(isLocalhost('example.com'), isFalse);
    });

    test('isIPAddress/isIPv4Address/isIPv6Address', () {
      expect(isIPv4Address(null), isFalse);
      expect(isIPv4Address('10.0.0.255'), isTrue);
      expect(isIPv4Address('10.0.0.256'), isFalse);
      expect(isIPv6Address(null), isFalse);
      expect(isIPAddress('192.168.1.1'), isTrue);
      expect(isIPAddress('fe80::1'), isTrue);
      expect(isIPAddress('example.com'), isFalse);
      expect(isIPAddress(null), isFalse);
    });

    test('isHttpURL', () {
      expect(isHttpURL(null), isFalse);
      expect(isHttpURL(Uri.parse('http://a')), isTrue);
      expect(isHttpURL(Uri.parse('https://a')), isTrue);
      expect(isHttpURL(Uri.parse('ftp://a')), isFalse);
      expect(isHttpURL(' https://a '), isTrue);
      expect(isHttpURL('http://a'), isTrue);
      expect(isHttpURL('   '), isFalse);
      expect(isHttpURL('ftp://a'), isFalse);
      expect(isHttpURL(123), isFalse);
    });
  });

  group('path helpers', () {
    test('getPathFileName', () {
      expect(getPathFileName(null), isNull);
      expect(getPathFileName('  '), isNull);
      expect(getPathFileName('file.txt'), equals('file.txt'));
      expect(getPathFileName('/a/b/c.txt'), equals('c.txt'));
      expect(getPathFileName(r'C:\dir\f.txt'), equals('f.txt'));
      expect(getPathFileName('/a/b/'), isNull);
    });

    test('getPathWithoutFileName', () {
      expect(getPathWithoutFileName(null), isNull);
      expect(getPathWithoutFileName('  '), isNull);
      // NOTE: current behaviour; possibly a bug: with no path separator the
      // whole input is returned, so the file name is not removed.
      expect(getPathWithoutFileName('file.txt'), equals('file.txt'));
      expect(getPathWithoutFileName(' /a/b/c.txt '), equals('/a/b/'));
      expect(getPathWithoutFileName(r'C:\dir\f.txt'), equals(r'C:\dir\'));
      expect(getPathWithoutFileName('/a/b/'), equals('/a/b/'));
    });

    test('getPathExtension', () {
      expect(getPathExtension(null), isNull);
      expect(getPathExtension(' '), isNull);
      expect(getPathExtension('noext'), isNull);
      expect(getPathExtension('a.'), isNull);
      expect(getPathExtension('a.tar.gz'), equals('gz'));
      expect(getPathExtension('/x/y.TXT'), equals('TXT'));
    });
  });
}
