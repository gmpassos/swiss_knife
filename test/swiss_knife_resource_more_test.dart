import 'dart:convert';

import 'package:resource_portable/resource.dart';
import 'package:swiss_knife/swiss_knife.dart';
import 'package:test/test.dart';

/// An in-memory [ResourceLoader]: `mem://<name>` maps to [files].
/// Missing entries throw a [StateError] (a load error).
class _MemoryLoader extends ResourceLoader {
  final Map<String, String> files;

  int reads = 0;

  _MemoryLoader(this.files);

  @override
  Stream<List<int>> openRead(Uri uri) => Stream.fromFuture(readAsBytes(uri));

  @override
  Future<List<int>> readAsBytes(Uri uri) async =>
      utf8.encode(await readAsString(uri));

  @override
  Future<String> readAsString(Uri uri, {Encoding? encoding}) async {
    reads++;
    var content = files[uri.toString()];
    if (content == null) throw StateError('Not found: $uri');
    return content;
  }

  @override
  Uri parseUri(String s) => Uri.parse(s);

  @override
  Future<Uri> resolveUri(Uri uri) async => uri;
}

/// How the default [ResourceLoader] parses [url] on the current platform.
Uri _parsed(String url) => Resource(url).uri;

class _UriHolder {
  final String url;

  _UriHolder(this.url);

  @override
  String toString() => url;
}

void main() {
  group('ResourceContent', () {
    test('constructor requires a resource or a content', () {
      expect(() => ResourceContent(null), throwsStateError);
      expect(() => ResourceContent(null, null), throwsStateError);

      var rc = ResourceContent(null, 'abc');
      expect(rc.resource, isNull);
      expect(rc.uri, isNull);
      expect(rc.hasContent, isTrue);
      // Content given in the constructor is not considered "loaded":
      expect(rc.isLoaded, isFalse);
      expect(rc.getContentIfLoaded(), isNull);
    });

    test('fromURI', () {
      expect(ResourceContent.fromURI(null), isNull);
      expect(ResourceContent.fromURI(null, null), isNull);

      var fromUri = ResourceContent.fromURI(Uri.parse('http://h/a.txt'))!;
      expect(fromUri.uri.toString(), equals('http://h/a.txt'));
      expect(fromUri.hasContent, isFalse);

      // A `String` is parsed by the default `ResourceLoader`, which is
      // platform dependent (on the VM it is parsed as a file path), so
      // compare with a `Resource` parsing the same string:
      var fromString = ResourceContent.fromURI('http://h/b.txt', 'B')!;
      expect(fromString.uri, equals(_parsed('http://h/b.txt')));
      expect(fromString.hasContent, isTrue);

      var fromRC = ResourceContent.fromURI(fromString, 'C')!;
      expect(identical(fromRC, fromString), isFalse);
      expect(fromRC.uri, equals(_parsed('http://h/b.txt')));
      expect(fromRC, equals(fromString));
      expect(fromRC.hasContent, isTrue);

      var fromOther = ResourceContent.fromURI(_UriHolder('http://h/c.txt'))!;
      expect(fromOther.uri, equals(_parsed('http://h/c.txt')));
    });

    test('fromURI with a null uri and a content', () {
      // Regression: `fromURI(null, content)` fell through to the
      // `uri.toString()` branch and created a `Resource('null')` instead of a
      // content-only `ResourceContent` (like `fromResolvedUrl` does).
      var rc = ResourceContent.fromURI(null, 'X')!;
      expect(rc.resource, isNull);
      expect(rc.uri, isNull);
      expect(rc.hasContent, isTrue);
      expect(ResourceContent.fromURI(null), isNull);
    });

    test('from', () {
      var rc = ResourceContent(null, 'x');
      expect(ResourceContent.from(rc), same(rc));

      var resource = Resource('http://h/r.txt');
      var fromResource = ResourceContent.from(resource)!;
      expect(fromResource.resource, same(resource));

      expect(
        ResourceContent.from('http://h/s.txt')!.uri,
        equals(_parsed('http://h/s.txt')),
      );
      expect(
        ResourceContent.from(Uri.parse('http://h/s.txt'))!.uri.toString(),
        equals('http://h/s.txt'),
      );
      expect(ResourceContent.from(null), isNull);
    });

    test('fromResolvedUrl', () {
      expect(ResourceContent.fromResolvedUrl(null), isNull);

      var contentOnly = ResourceContent.fromResolvedUrl(null, content: 'c')!;
      expect(contentOnly.resource, isNull);
      expect(contentOnly.hasContent, isTrue);

      var absolute = ResourceContent.fromResolvedUrl('http://h2/x/y.json')!;
      expect(absolute.uri.toString(), equals('http://h2/x/y.json'));

      var resolved = ResourceContent.fromResolvedUrl(
        'data/z.json',
        baseURL: 'http://host:8080/base/',
        content: '{}',
      )!;
      expect(
        resolved.uri.toString(),
        equals('http://host:8080/base/data/z.json'),
      );
      expect(resolved.hasContent, isTrue);
    });

    test('getContent, onLoad, isLoaded and reset', () async {
      var loader = _MemoryLoader({'mem://a': 'AAA'});
      var rc = ResourceContent(Resource('mem://a', loader: loader));

      var events = <String?>[];
      rc.onLoad.listen(events.add);
      expect(identical(rc.onLoad, rc.onLoad), isTrue);

      expect(rc.isLoaded, isFalse);
      expect(rc.hasContent, isFalse);
      expect(rc.getContentIfLoaded(), isNull);

      await rc.load();
      expect(rc.isLoaded, isTrue);
      expect(rc.isLoadedWithError, isFalse);
      expect(rc.hasContent, isTrue);
      expect(rc.getContentIfLoaded(), equals('AAA'));
      expect(loader.reads, equals(1));

      // Already has content: no new read.
      expect(await rc.getContent(), equals('AAA'));
      expect(loader.reads, equals(1));

      await Future.delayed(Duration.zero);
      expect(events, equals(['AAA']));

      rc.reset();
      expect(rc.isLoaded, isFalse);
      expect(rc.hasContent, isFalse);
      expect(rc.getContentIfLoaded(), isNull);

      loader.files['mem://a'] = 'BBB';
      expect(await rc.getContent(), equals('BBB'));
      expect(loader.reads, equals(2));

      await Future.delayed(Duration.zero);
      expect(events, equals(['AAA', 'BBB']));
    });

    test('reset keeps the content of a content-only resource', () async {
      var rc = ResourceContent(null, 'keep');
      rc.reset();
      expect(rc.hasContent, isTrue);
      expect(await rc.getContent(), equals('keep'));
    });

    test('load error', () async {
      var loader = _MemoryLoader({});
      var rc = ResourceContent(Resource('mem://missing', loader: loader));

      var events = <String?>[];
      rc.onLoad.listen(events.add);

      expect(await rc.getContent(), isNull);
      expect(rc.isLoaded, isTrue);
      expect(rc.isLoadedWithError, isTrue);
      expect(rc.hasContent, isFalse);
      expect(rc.getContentIfLoaded(), isNull);

      await Future.delayed(Duration.zero);
      expect(events, equals([null]));

      // Not cached as content: a new attempt reads again.
      loader.files['mem://missing'] = 'now';
      expect(await rc.getContent(), equals('now'));
      expect(rc.isLoadedWithError, isFalse);
    });

    test('uriFileExtension and uriMimeType', () {
      var json = ResourceContent.from('http://h/dir/file.json')!;
      expect(json.uriFileExtension, equals('json'));
      expect(json.uriMimeType!.toString(), equals('application/json'));

      var png = ResourceContent.from('http://h/img.PNG')!;
      expect(png.uriFileExtension, equals('PNG'));
      expect(png.uriMimeType!.toString(), equals('image/png'));

      var noExt = ResourceContent.from('http://h/dir/file')!;
      expect(noExt.uriFileExtension, isNull);

      var contentOnly = ResourceContent(null, 'x');
      expect(contentOnly.uriFileExtension, isNull);
      expect(contentOnly.uriMimeType, isNull);
    });

    test('uriResolved', () async {
      var loader = _MemoryLoader({});
      var rc = ResourceContent(Resource('mem://q', loader: loader));
      expect((await rc.uriResolved).toString(), equals('mem://q'));
    });

    test('equality, hashCode and toString', () {
      var a1 = ResourceContent.from(Uri.parse('http://h/a'))!;
      var a2 = ResourceContent.from(Uri.parse('http://h/a'))!;
      var b = ResourceContent.from(Uri.parse('http://h/b'))!;

      expect(a1 == a2, isTrue);
      expect(a1.hashCode, equals(a2.hashCode));
      expect(a1.hashCode, equals(Uri.parse('http://h/a').hashCode));
      expect(a1 == b, isFalse);
      expect(a1, equals(a1));

      var c1 = ResourceContent(null, 'x');
      var c2 = ResourceContent(null, 'y');
      expect(c1.hashCode, equals(0));
      // Both have a null `uri`:
      expect(c1 == c2, isTrue);

      expect(a1.toString(), equals('ResourceContent{resource: http://h/a}'));
      expect(c1.toString(), equals('ResourceContent{resource: null}'));
    });
  });

  group('ResourceContent.resolveURLFromReference', () {
    var loader = _MemoryLoader({});
    var reference = ResourceContent(
      Resource('http://example.com:8080/a/b/page.html', loader: loader),
    );

    Future<String> resolve(String? url, [ResourceContent? ref]) async =>
        (await ResourceContent.resolveURLFromReference(ref, url)).toString();

    test('null url', () async {
      expect(
        await ResourceContent.resolveURLFromReference(reference, null),
        isNull,
      );
    });

    test('absolute, relative and root urls', () async {
      expect(
        await resolve('  https://other/x.txt ', reference),
        equals('https://other/x.txt'),
      );
      expect(
        await resolve('c.txt', reference),
        equals('http://example.com:8080/a/b/c.txt'),
      );
      expect(
        await resolve('sub-dir/c.txt', reference),
        equals('http://example.com:8080/a/b/sub-dir/c.txt'),
      );
      expect(
        await resolve('./c.txt', reference),
        equals('http://example.com:8080/a/b/c.txt'),
      );
      expect(
        await resolve('/root.txt', reference),
        equals('http://example.com:8080/root.txt'),
      );
      // Not a word char, `./` or `/`: just parsed.
      expect(await resolve('../up.txt', reference), equals('../up.txt'));
      expect(await resolve('#frag', reference), equals('#frag'));
    });

    test('resolveURL instance method', () async {
      expect(
        (await reference.resolveURL('img/x.png')).toString(),
        equals('http://example.com:8080/a/b/img/x.png'),
      );
    });

    test('without a reference uses the current base', () async {
      var base = (await ResourceContent.fromURI('./')!.uriResolved)!;

      var relative = (await ResourceContent.resolveURLFromReference(
        null,
        'rel.txt',
      ))!;
      expect(relative.scheme, equals(base.scheme));
      expect(relative.host, equals(base.host));
      expect(relative.path, endsWith('/rel.txt'));

      var root = (await ResourceContent.resolveURLFromReference(
        null,
        '/abs.txt',
      ))!;
      expect(root.scheme, equals(base.scheme));
      expect(root.host, equals(base.host));
      expect(root.path, equals('/abs.txt'));
    });
  });

  group('ResourceContentCache', () {
    test('null keys', () {
      var cache = ResourceContentCache();
      expect(cache.get(null), isNull);
      expect(cache.remove(null), isNull);
      expect(cache.contains(null), isFalse);
      expect(cache.size, equals(0));
    });

    test('get, contains, remove and clear by uri', () async {
      var loader = _MemoryLoader({'mem://x': 'X'});
      var cache = ResourceContentCache();

      var rc = ResourceContent(Resource('mem://x', loader: loader));
      expect(cache.get(rc), same(rc));
      expect(cache.size, equals(1));
      // Same instance again:
      expect(cache.get(rc), same(rc));

      // Lookup by an equal `Uri` or `Resource` returns the cached instance:
      expect(cache.get(Uri.parse('mem://x')), same(rc));
      expect(cache.get(Resource(Uri.parse('mem://x'))), same(rc));
      expect(cache.contains(Uri.parse('mem://x')), isTrue);
      expect(cache.size, equals(1));

      // A URI string is parsed by the default loader:
      var byString = cache.get('mem://y')!;
      expect(byString.uri, equals(_parsed('mem://y')));
      expect(cache.get('mem://y'), same(byString));
      expect(cache.size, equals(2));

      expect(cache.remove(Uri.parse('mem://x')), same(rc));
      expect(cache.remove(Uri.parse('mem://x')), isNull);
      expect(cache.size, equals(1));

      // Regression: `contains` inserted the resource when absent (it called
      // `get`), so it was always true.
      expect(cache.contains(Uri.parse('mem://z')), isFalse);
      expect(cache.contains('mem://z'), isFalse);
      expect(cache.contains(ResourceContent(null, 'not cached')), isFalse);
      expect(cache.size, equals(1));
      expect(cache.contains(Uri.parse('mem://x')), isFalse);
      expect(cache.contains(byString), isTrue);
      expect(cache.contains('mem://y'), isTrue);
      expect(cache.size, equals(1));

      cache.clear();
      expect(cache.size, equals(0));
    });

    test('content from a new instance is moved into the cached one', () async {
      var cache = ResourceContentCache();

      var cached = ResourceContent.from('http://h/c.txt')!;
      expect(cache.get(cached), same(cached));
      expect(cached.hasContent, isFalse);

      var events = <String?>[];
      cached.onLoad.listen(events.add);

      var withContent = ResourceContent.fromURI('http://h/c.txt', 'CONTENT')!;
      expect(cache.get(withContent), same(cached));

      expect(cached.hasContent, isTrue);
      expect(await cached.getContent(), equals('CONTENT'));
      // Regression: the transferred content did not mark the cached instance
      // as loaded, so `getContentIfLoaded` still returned null.
      expect(cached.isLoaded, isTrue);
      expect(cached.isLoadedWithError, isFalse);
      expect(cached.getContentIfLoaded(), equals('CONTENT'));

      await Future.delayed(Duration.zero);
      expect(events, equals(['CONTENT']));

      // A cached instance with content is not overwritten:
      var other = ResourceContent.fromURI('http://h/c.txt', 'OTHER')!;
      expect(cache.get(other), same(cached));
      expect(await cached.getContent(), equals('CONTENT'));
    });

    test('content-only resources are cached by content', () {
      var cache = ResourceContentCache();

      // Regression: `_cacheKey` used `getContentIfLoaded()!`, but a
      // content-only instance is never "loaded", so `get`/`contains`/`remove`
      // threw a `TypeError` for every content-only instance.
      var contents = ['', 'a', 'abc', 'abcde', 'abcdefgh'];
      for (var content in contents) {
        var rc = ResourceContent(null, content);
        expect(rc.hasContent, isTrue);
        expect(cache.get(rc), same(rc), reason: content);
        expect(cache.contains(rc), isTrue, reason: content);

        // An equal content resolves to the cached instance:
        var rc2 = ResourceContent(null, content);
        expect(cache.contains(rc2), isTrue, reason: content);
        expect(cache.get(rc2), same(rc), reason: content);
      }

      expect(cache.size, equals(contents.length));

      for (var content in contents) {
        var removed = cache.remove(ResourceContent(null, content));
        expect(removed, isNotNull, reason: content);
        expect(removed!.hasContent, isTrue, reason: content);
      }

      expect(cache.size, equals(0));
    });
  });

  group('ContextualResource', () {
    test('context resolution', () {
      var r1 = ContextualResource<String, String>('a', 'k');
      expect(r1.resource, equals('a'));
      expect(r1.context, equals('k'));

      var r2 = ContextualResource<String, String>(
        'abc',
        (String r) => r.toUpperCase(),
      );
      expect(r2.context, equals('ABC'));

      // A function returning a function:
      var r3 = ContextualResource<String, String>(
        'abcd',
        (String r) =>
            (String r2) => '$r2$r2',
      );
      expect(r3.context, equals('abcdabcd'));

      var r4 = ContextualResource<String, String>('x', null);
      expect(r4.context, isNull);

      expect(
        () => ContextualResource<String, String>('y', 123),
        throwsStateError,
      );
    });

    test('toList', () {
      var list = ContextualResource.toList<String, String>([
        'a',
        'bb',
        'ccc',
      ], (r) => r.toUpperCase());
      expect(list.map((e) => e.context).toList(), equals(['A', 'BB', 'CCC']));
      expect(list.map((e) => e.resource).toList(), equals(['a', 'bb', 'ccc']));
    });

    test('equality, hashCode, toString', () {
      var a = ContextualResource<String, String>('a', '1');
      var a2 = ContextualResource<String, String>('a', '1');
      var b = ContextualResource<String, String>('a', '2');
      expect(a == a2, isTrue);
      expect(a.hashCode, equals(a2.hashCode));
      expect(a == b, isFalse);
      expect(a, equals(a));
      expect(
        a.toString(),
        equals('ContextualResource{resource: a, context: 1}'),
      );
    });

    test('compareTo', () {
      var r1 = ContextualResource<String, String>('a', '1');
      var r2 = ContextualResource<String, String>('b', '2');
      var rn = ContextualResource<String, String>('n', null);
      var rn2 = ContextualResource<String, String>('m', null);

      expect(r1.compareTo(r2), equals(-1));
      expect(r2.compareTo(r1), equals(1));
      expect(r1.compareTo(r1), equals(0));
      expect(r1.compareTo(rn), equals(-1));
      expect(rn.compareTo(r1), equals(1));
      expect(rn.compareTo(rn2), equals(0));

      var sorted = [rn, r2, r1]..sort();
      expect(sorted.map((e) => e.resource).toList(), equals(['a', 'b', 'n']));
    });

    test('compareContext', () {
      // Regression: `compareContext` never compared the contexts: it returned
      // -1 whenever this context was non-null and 1 when it was null (the
      // `compareTo` branch was dead).
      var r5 = ContextualResource<String, String>('a', '5');
      expect(r5.compareContext('1'), greaterThan(0));
      expect(r5.compareContext('5'), equals(0));
      expect(r5.compareContext('9'), lessThan(0));

      var i5 = ContextualResource<String, num>('a', 5);
      expect(i5.compareContext(1), equals(1));
      expect(i5.compareContext(5), equals(0));
      expect(i5.compareContext(9), equals(-1));

      // A null context is greater than any context:
      var rn = ContextualResource<String, String>('n', null);
      expect(rn.compareContext('1'), equals(1));
    });
  });

  group('ContextualResourceResolver', () {
    // Contexts are zero-padded strings, so they sort numerically.
    ContextualResource<String, String> cr(String r, String? c) =>
        ContextualResource<String, String>(r, c);

    test('empty resolver and defaults', () {
      var resolver = ContextualResourceResolver<String, String>();
      expect(resolver.keys, isEmpty);
      expect(resolver.resolve('x'), isNull);
      expect(resolver['x'], isNull);

      resolver.defaultResource = cr('default', '000');
      expect(resolver.resolve('x'), equals('default'));

      resolver.add('k', []);
      expect(resolver.keys, isEmpty);
    });

    test('resolve without a context', () {
      var resolver = ContextualResourceResolver<String, String>();
      resolver.add('img', [cr('small', '010'), cr('big', '100')]);
      expect(resolver.keys, equals(['img']));

      // No context and no default: the first added option.
      expect(resolver.resolve('img'), equals('small'));
      expect(resolver['img'], equals('small'));

      resolver.defaultResource = cr('default', '000');
      expect(resolver.resolve('img'), equals('default'));
    });

    test('resolve with a context comparator', () {
      var resolver = ContextualResourceResolver<String, String>(
        contextComparator: (a, b) => a.compareTo(b),
        defaultContext: '050',
      );

      resolver.add('img', [
        cr('r100', '100'),
        cr('r10', '010'),
        cr('r50', '050'),
      ]);

      expect(resolver.resolve('img', '010'), equals('r10'));
      expect(resolver.resolve('img', '050'), equals('r50'));
      expect(resolver.resolve('img', '100'), equals('r100'));
      // No exact match: the next greater context.
      expect(resolver.resolve('img', '001'), equals('r10'));
      expect(resolver.resolve('img', '011'), equals('r50'));
      expect(resolver.resolve('img', '051'), equals('r100'));
      // `defaultContext`:
      expect(resolver['img'], equals('r50'));

      // Regression: a context greater than all options made the binary
      // search end at `low == length` and `options[low]` threw a `RangeError`
      // instead of returning the last (greatest) option.
      expect(resolver.resolve('img', '101'), equals('r100'));
      expect(resolver.resolve('img', '999'), equals('r100'));

      // Adding a new option invalidates the sorted cache:
      resolver.add('img', [cr('r200', '200')]);
      expect(resolver.resolve('img', '101'), equals('r200'));

      // Adding an existing option keeps it:
      resolver.add('img', [cr('r200', '200')]);
      expect(resolver.resolve('img', '150'), equals('r200'));
    });

    test('resolve with the default comparator', () {
      var resolver = ContextualResourceResolver<String, String>();
      resolver.add('img', [cr('r10', '010'), cr('r50', '050')]);

      // Regression: without a `contextComparator`, `compareContext` always
      // returned -1 for non-null contexts, so the search ran past the end and
      // threw a `RangeError` even for an exact match.
      expect(resolver.resolve('img', '010'), equals('r10'));
      expect(resolver.resolve('img', '050'), equals('r50'));
      expect(resolver.resolve('img', '001'), equals('r10'));
      expect(resolver.resolve('img', '011'), equals('r50'));
      expect(resolver.resolve('img', '051'), equals('r50'));

      // A null-context option (sorted last) is the one found for contexts
      // greater than all the others (it was found for every context):
      resolver.add('img', [cr('any', null)]);
      expect(resolver.resolve('img', '010'), equals('r10'));
      expect(resolver.resolve('img', '050'), equals('r50'));
      expect(resolver.resolve('img', '051'), equals('any'));
    });

    test('resolve with a context comparator and null contexts', () {
      // Regression: a null-context option threw a `TypeError` with a
      // `contextComparator` (`midVal.context!`), and the options were sorted
      // with the natural order instead of the comparator.
      var resolver = ContextualResourceResolver<String, num>(
        // Reversed order:
        contextComparator: (a, b) => b.compareTo(a),
      );
      resolver.add('img', [
        ContextualResource<String, num>('r10', 10),
        ContextualResource<String, num>('r50', 50),
        ContextualResource<String, num>('r100', 100),
        ContextualResource<String, num>('any', null),
      ]);

      expect(resolver.resolve('img', 100), equals('r100'));
      expect(resolver.resolve('img', 50), equals('r50'));
      expect(resolver.resolve('img', 10), equals('r10'));
      // Next "greater" in the reversed order:
      expect(resolver.resolve('img', 60), equals('r50'));
      expect(resolver.resolve('img', 200), equals('r100'));
      expect(resolver.resolve('img', 5), equals('any'));
    });

    test('resolve with int contexts and a single option', () {
      var resolver = ContextualResourceResolver<String, num>();
      resolver.add('img', [ContextualResource<String, num>('only', 10)]);
      expect(resolver.resolve('img', 1), equals('only'));
      expect(resolver.resolve('img', 10), equals('only'));
      expect(resolver.resolve('img', 100), equals('only'));
    });

    test('constructor resources map', () {
      var resolver = ContextualResourceResolver<String, String>(
        resources: {
          'single': cr('s', '1'),
          'list': [cr('l1', '1'), cr('l2', '2')],
          'function': () => cr('f', '3'),
          'function-list': () => [cr('fl1', '1'), cr('fl2', '2')],
          'function-of-key': () =>
              (Object? key) => cr('key:$key', '4'),
          'ignored': 123,
        },
      );

      expect(
        resolver.keys,
        equals([
          'single',
          'list',
          'function',
          'function-list',
          'function-of-key',
        ]),
      );
      expect(resolver['single'], equals('s'));
      expect(resolver['list'], equals('l1'));
      expect(resolver['function'], equals('f'));
      expect(resolver['function-list'], equals('fl1'));
      // A function returned by a constructor function is called with the key:
      expect(resolver['function-of-key'], equals('key:function-of-key'));
      expect(resolver['ignored'], isNull);

      expect(resolver.toString(), startsWith('ScalableResourceResolver{'));

      resolver.clear();
      expect(resolver.keys, isEmpty);
    });

    test('addDynamic with mapper', () {
      var resolver = ContextualResourceResolver<String, String>();

      ContextualResource<String, String> upper(Object? v) {
        var c = v as ContextualResource<String, String>;
        return cr(c.resource.toUpperCase(), c.context);
      }

      resolver.addDynamic('a', cr('x', '1'), upper);
      expect(resolver['a'], equals('X'));

      resolver.addDynamic('b', [cr('y', '1'), cr('z', '2')], upper);
      expect(resolver['b'], equals('Y'));

      resolver.addDynamic('c', (Object? key) => cr('w-$key', '1'), upper);
      expect(resolver['c'], equals('W-C'));

      resolver.addDynamic('d', (Object? key) => [cr('v-$key', '1')]);
      expect(resolver['d'], equals('v-d'));

      resolver.addDynamic('e', 'not a resource');
      expect(resolver['e'], isNull);
    });
  });
}
