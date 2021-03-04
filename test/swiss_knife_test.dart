import 'dart:collection';

import 'package:swiss_knife/swiss_knife.dart';
import 'package:test/test.dart';

String uriRootScheme =
    Uri.base.toString().startsWith('file:/') ? 'file' : 'http';

String uriRootInit = uriRootScheme == 'file' ? 'file:///' : 'http://';

String uriRootHost = uriRootScheme == 'file' ? '' : 'localhost';

RegExp uriRootHostAndPort =
    uriRootScheme == 'file' ? RegExp(r'^$') : RegExp(r'^localhost:\d+$');

RegExp uriRootPort =
    uriRootScheme == 'file' ? RegExp(r'^0$') : RegExp(r'^\d+$');

String uriRoot = getUriRoot().toString();

class Foo {
  int id;

  String name;

  Foo(this.id, this.name);

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }

  @override
  String toString() {
    return 'Foo{id: $id, name: $name}';
  }
}

class Bar {
  int id;

  String name;

  Bar(this.id, this.name);

  @override
  String toString() {
    return 'Bar{id: $id, name: $name}';
  }
}

void main() {
  group('Collections', () {
    setUp(() {});

    test('Collections', () {
      expect(isEquivalentMap({'a': 1, 'b': 2}, {'b': 2, 'a': 1}), equals(true));
      expect(
          isEquivalentMap({'a': 1, 'b': 2}, {'b': 3, 'a': 1}), equals(false));

      expect(isEquivalentList([1, 2, 3, 4], [4, 3, 2, 1], sort: true),
          equals(true));
      expect(isEquivalentList([1, 2, 3, 4], [4, 3, 2, 1], sort: false),
          equals(false));

      expect(findKeyValue({'a': 11, 'b': 22}, ['A'], true), equals(11));
      expect(findKeyValue({'a': 11, 'b': 22}, ['A'], false), equals(null));
      expect(findKeyValue({'a': 11, 'b': 22}, ['a'], false), equals(11));

      expect(findKeyName({'a': 11, 'b': 22}, ['A'], true), equals('a'));
      expect(findKeyName({'a': 11, 'b': 22}, ['A'], false), equals(null));
      expect(findKeyName({'a': 11, 'b': 22}, ['a'], false), equals('a'));

      expect(
          findKeyName({'Aa': 11, 'b': 22}, ['aa', 'Aa'], false), equals('Aa'));

      expect(findKeyEntry({'Aa': 11, 'b': 22}, ['aa', 'Aa'], false).toString(),
          equals(MapEntry('Aa', 11).toString()));

      expect(getIgnoreCase({'Aa': 11, 'b': 22}, 'aa'), equals(11));
      expect(getEntryIgnoreCase({'Aa': 11, 'b': 22}, 'aa').value, equals(11));

      {
        var map = {'Aa': 11.0, 'b': 22};
        expect(map['Aa'], equals(11.0));
        putIgnoreCase(map, 'aa', 11.1);
        expect(map['Aa'], equals(11.1));
      }
    });

    test('deep', () {
      expect(
          isEquivalentMap({
            'a': [1, 2],
            'b': 2
          }, {
            'b': 2,
            'a': [1, 2]
          }),
          equals(false));
      expect(
          isEquivalentMap({
            'a': [1, 2],
            'b': 2
          }, {
            'b': 2,
            'a': [1, 2]
          }, deep: true),
          equals(true));
      expect(
          isEquivalentMap({
            'a': [1, 2],
            'b': 2
          }, {
            'b': 2,
            'a': [1, '2']
          }, deep: true),
          equals(false));

      expect(
          isEquivalentMap({
            'a': {
              'x': [1, 2]
            },
            'b': 2
          }, {
            'b': 2,
            'a': {
              'x': [1, 2]
            }
          }),
          equals(false));
      expect(
          isEquivalentMap({
            'a': {
              'x': [1, 2]
            },
            'b': 2
          }, {
            'b': 2,
            'a': {
              'x': [1, 2]
            }
          }, deep: true),
          equals(true));
      expect(
          isEquivalentMap({
            'a': {
              'x': [1, 2]
            },
            'b': 2
          }, {
            'b': 2,
            'a': {
              'x': [1, '2']
            }
          }, deep: true),
          equals(false));

      var deepObj = [
        'a',
        'b',
        1,
        2,
        {
          'a': 1,
          'b': 2,
          'c': [
            {'id', 1},
            {'id', 2}
          ]
        }
      ];

      expect(isEqualsDeep(deepObj, deepCopy(deepObj)), isTrue);

      var deepObj2 = {
        'list': [
          {'id': 1},
          {'id': 2}
        ]
      };

      deepReplaceValues(deepObj2, (c, k, v) => k == 'id', (c, k, v) => v * 10);

      expect(
          isEqualsDeep(deepObj2, {
            'list': [
              {'id': 10},
              {'id': 20}
            ]
          }),
          isTrue);
    });

    test('sort', () {
      // ignore: prefer_collection_literals
      var map1 = LinkedHashMap<String, int>();
      map1['c'] = 10;
      map1['a'] = 30;
      map1['b'] = 20;

      expect(sortMapEntriesByKey(map1).keys.toList(), equals(['a', 'b', 'c']));

      expect(
          sortMapEntriesByValue(map1).keys.toList(), equals(['c', 'b', 'a']));
    });
  });

  group('String', () {
    setUp(() {});

    test('split: String delimiter', () {
      expect(split('a,b,c', ','), equals(['a', 'b', 'c']));
      expect(split('a,b,c', ',', 0), equals(['a', 'b', 'c']));
      expect(split('a,b,c', ',', 1), equals(['a,b,c']));
      expect(split('a,b,c', ',', 2), equals(['a', 'b,c']));
      expect(split('a,b,c', ',', 3), equals(['a', 'b', 'c']));

      expect(split('a,b,c,d', ',', 0), equals(['a', 'b', 'c', 'd']));
      expect(split('a,b,c,d', ',', 1), equals(['a,b,c,d']));
      expect(split('a,b,c,d', ',', 2), equals(['a', 'b,c,d']));
      expect(split('a,b,c,d', ',', 3), equals(['a', 'b', 'c,d']));
      expect(split('a,b,c,d', ',', 4), equals(['a', 'b', 'c', 'd']));
      expect(split('a,b,c,d', ',', 5), equals(['a', 'b', 'c', 'd']));

      expect(split('a,', ',', 0), equals(['a', '']));
      expect(split('a,', ',', 1), equals(['a,']));
      expect(split('a,', ',', 2), equals(['a', '']));
      expect(split('a,', ',', 3), equals(['a', '']));

      expect(split('a,b,', ',', 0), equals(['a', 'b', '']));
      expect(split('a,b,', ',', 1), equals(['a,b,']));
      expect(split('a,b,', ',', 2), equals(['a', 'b,']));
      expect(split('a,b,', ',', 3), equals(['a', 'b', '']));

      expect(split('AA,,BB,,CC', ',,'), equals(['AA', 'BB', 'CC']));
      expect(split('AA,,BB,,CC,,', ',,'), equals(['AA', 'BB', 'CC', '']));
      expect(split('AA,,BB,,CC', ',,', 2), equals(['AA', 'BB,,CC']));
      expect(split('AA,,BB,,CC', ',,', 3), equals(['AA', 'BB', 'CC']));
      expect(split('AA,,BB,,CC,,', ',,', 3), equals(['AA', 'BB', 'CC,,']));
    });

    test('split: regexp', () {
      var delimiter = RegExp(',');

      expect(split('a,b,c', delimiter), equals(['a', 'b', 'c']));
      expect(split('a,b,c', delimiter, 0), equals(['a', 'b', 'c']));
      expect(split('a,b,c', delimiter, 1), equals(['a,b,c']));
      expect(split('a,b,c', delimiter, 2), equals(['a', 'b,c']));
      expect(split('a,b,c', delimiter, 3), equals(['a', 'b', 'c']));

      expect(split('a,b,c,d', delimiter, 0), equals(['a', 'b', 'c', 'd']));
      expect(split('a,b,c,d', delimiter, 1), equals(['a,b,c,d']));
      expect(split('a,b,c,d', delimiter, 2), equals(['a', 'b,c,d']));
      expect(split('a,b,c,d', delimiter, 3), equals(['a', 'b', 'c,d']));
      expect(split('a,b,c,d', delimiter, 4), equals(['a', 'b', 'c', 'd']));
      expect(split('a,b,c,d', delimiter, 5), equals(['a', 'b', 'c', 'd']));

      expect(split('a,b,', delimiter, 0), equals(['a', 'b', '']));
      expect(split('a,b,', delimiter, 1), equals(['a,b,']));
      expect(split('a,b,', delimiter, 2), equals(['a', 'b,']));
      expect(split('a,b,', delimiter, 3), equals(['a', 'b', '']));

      expect(split('AA,,BB,,CC', ',,'), equals(['AA', 'BB', 'CC']));
      expect(split('AA,,BB,,CC,,', ',,'), equals(['AA', 'BB', 'CC', '']));
      expect(split('AA,,BB,,CC', ',,', 2), equals(['AA', 'BB,,CC']));
      expect(split('AA,,BB,,CC', ',,', 3), equals(['AA', 'BB', 'CC']));
      expect(split('AA,,BB,,CC,,', ',,', 3), equals(['AA', 'BB', 'CC,,']));
    });

    test('NNField: String', () {
      var field = NNField('def');
      expect(field.get(), equals('def'));

      field.set('abc');
      expect(field.get(), equals('abc'));

      field.set(null);
      expect(field.get(), equals('def'));
    });

    test('NNField: num', () {
      var field = NNField(100);
      expect(field.get(), equals(100));

      field.set(10);
      expect(field.get(), equals(10));

      field.set(null);
      expect(field.get(), equals(100));

      expect(field.asNum, equals(100));
      expect(field.asInt, equals(100));
      expect(field.asDouble, equals(100.0));
      expect(field.asString, equals('100'));
      expect(field.asBool, isTrue);

      expect(field * 0.20, equals(20));
      expect(field / 2, equals(50));

      expect(field + 11, equals(111));
      expect(field - 1, equals(99));

      // ignore: unrelated_type_equality_checks
      expect(field == 100, isTrue);
      expect(field > 99, isTrue);
      expect(field >= 100, isTrue);
      expect(field < 101, isTrue);
      expect(field <= 100, isTrue);

      field.increment(11);
      expect(field.value, equals(111));
      field.decrement(1);
      expect(field.value, equals(110));
      field.multiply(2);
      expect(field.value, equals(220));
      field.divide(2);
      expect(field.value, equals(110));
    });
  });

  group('Math', () {
    setUp(() {});

    test('max,min', () {
      expect(Math.max(11, 22), equals(22));
      expect(Math.min(11, 22), equals(11));

      expect(Math.minMax([11, 33, 22]), equals(Pair(11, 33)));
    });

    test('ceil,floor,round', () {
      expect(Math.ceil(2.2), equals(3));
      expect(Math.floor(2.2), equals(2));

      expect(Math.round(2.2), equals(2));
      expect(Math.round(2.7), equals(3));
    });

    test('statistics', () {
      expect(Math.sum([2, 4]), equals(6));
      expect(Math.mean([2, 4]), equals(3));
    });

    test('parseNum', () {
      expect(parseNum(0), equals(0));
      expect(parseNum(1), equals(1));
      expect(parseNum(-1), equals(-1));
      expect(parseNum(3), equals(3));
      expect(parseNum(3.3), equals(3.3));
      expect(parseNum(-3.3), equals(-3.3));
      expect(parseNum('0'), equals(0));
      expect(parseNum('1'), equals(1));
      expect(parseNum('2'), equals(2));
      expect(parseNum('5.5'), equals(5.5));
      expect(parseNum('-1'), equals(-1));
      expect(parseNum('-2'), equals(-2));
      expect(parseNum('-5.5'), equals(-5.5));

      expect(parseNumsFromList([1, 2, 3.3, '-5.5', '11.5']),
          equals([1, 2, 3.3, -5.5, 11.5]));
    });

    test('parseInt', () {
      expect(parseInt(0), equals(0));
      expect(parseInt(1), equals(1));
      expect(parseInt(-1), equals(-1));
      expect(parseInt(3), equals(3));
      expect(parseInt(3.3), equals(3));
      expect(parseInt(-3.3), equals(-3));
      expect(parseInt('0'), equals(0));
      expect(parseInt('1'), equals(1));
      expect(parseInt('2'), equals(2));
      expect(parseInt('5.5'), equals(5));
      expect(parseInt('-1'), equals(-1));
      expect(parseInt('-2'), equals(-2));
      expect(parseInt('-5.5'), equals(-5));
    });

    test('parseDouble', () {
      expect(parseDouble(0), equals(0));
      expect(parseDouble(1), equals(1));
      expect(parseDouble(-1), equals(-1));
      expect(parseDouble(3), equals(3));
      expect(parseDouble(3.3), equals(3.3));
      expect(parseDouble(-3.3), equals(-3.3));
      expect(parseDouble('0'), equals(0));
      expect(parseDouble('1'), equals(1));
      expect(parseDouble('2'), equals(2));
      expect(parseDouble('5.5'), equals(5.5));
      expect(parseDouble('-1'), equals(-1));
      expect(parseDouble('-2'), equals(-2));
      expect(parseDouble('-5.5'), equals(-5.5));
    });

    test('parsePercent', () {
      expect(parsePercent('0%'), equals(0));
      expect(parsePercent('10%'), equals(10));
      expect(parsePercent('-10%'), equals(-10));
      expect(parsePercent('0.1%'), equals(0.1));
      expect(parsePercent('-0.1%'), equals(-0.1));

      expect(parsePercent(null), equals(null));
      expect(parsePercent(double.nan), equals(null));

      expect(formatPercent(0), equals('0%'));
      expect(formatPercent(1), equals('1%'));
      expect(formatPercent(-1), equals('-1%'));
      expect(formatPercent(10), equals('10%'));
      expect(formatPercent(-10), equals('-10%'));
      expect(formatPercent(10.01), equals('10.01%'));
      expect(formatPercent(-10.01), equals('-10.01%'));
      expect(formatPercent(3.3), equals('3.3%'));

      expect(formatPercent(0.33, 2, true), equals('33%'));
      expect(formatPercent(0.333, 2, true), equals('33.30%'));
      expect(formatPercent(0.3333, 2, true), equals('33.33%'));
      expect(formatPercent(1 / 3, 2, true), equals('33.33%'));
      expect(formatPercent(1 / 3, 3, true), equals('33.333%'));
      expect(formatPercent(1 / 3, 4, true), equals('33.3333%'));

      expect(formatPercent(33), equals('33%'));
      expect(formatPercent(33.3), equals('33.3%'));
      expect(formatPercent(100 / 3), equals('33.33%'));

      expect(formatPercent(-100 / 3), equals('-33.33%'));
    });

    test('formatDecimal', () {
      expect(formatDecimal(0), equals('0'));
      expect(formatDecimal(1), equals('1'));
      expect(formatDecimal(-1), equals('-1'));
      expect(formatDecimal(10), equals('10'));
      expect(formatDecimal(-10), equals('-10'));
      expect(formatDecimal(10.01), equals('10.01'));
      expect(formatDecimal(-10.01), equals('-10.01'));
      expect(formatDecimal(3.3), equals('3.3'));

      expect(formatDecimal(33.0, 2), equals('33'));
      expect(formatDecimal(33.30, 2), equals('33.3'));
      expect(formatDecimal(33.33, 2), equals('33.33'));
      expect(formatDecimal(1 / 3, 2), equals('0.33'));
      expect(formatDecimal(1 / 3, 3), equals('0.333'));
      expect(formatDecimal(1 / 3, 4), equals('0.3333'));

      expect(formatDecimal(33), equals('33'));
      expect(formatDecimal(33.3), equals('33.3'));
      expect(formatDecimal(100 / 3), equals('33.33'));

      expect(formatDecimal(-100 / 3), equals('-33.33'));
    });

    test('clipNumber', () {
      expect(clipNumber(12, 10, 20), equals(12));
      expect(clipNumber(2, 10, 20), equals(10));
      expect(clipNumber(30, 10, 20), equals(20));

      expect(clipNumber(null, 10, 20, 15), equals(15));
      expect(clipNumber(null, 10, 20, 150), equals(20));
    });

    test('isPositiveNumber', () {
      expect(isPositiveNumber(1), isTrue);
      expect(isPositiveNumber(2), isTrue);
      expect(isPositiveNumber(1000), isTrue);
      expect(isPositiveNumber(0), isFalse);
      expect(isPositiveNumber(-1), isFalse);
      expect(isPositiveNumber(-2), isFalse);
    });

    test('isNegativeNumber', () {
      expect(isNegativeNumber(1), isFalse);
      expect(isNegativeNumber(2), isFalse);
      expect(isNegativeNumber(1000), isFalse);
      expect(isNegativeNumber(0), isFalse);
      expect(isNegativeNumber(-1), isTrue);
      expect(isNegativeNumber(-2), isTrue);
    });

    test('Scale', () {
      var s1 = Scale.from([10, -10, 20, 5]);

      expect(s1.minimum, equals(-10));
      expect(s1.maximum, equals(20));
      expect(s1.length, equals(30));

      var s2 = ScaleNum.from([10, -10, 20, 5]);

      expect(s2.minimum, equals(-10));
      expect(s2.maximum, equals(20));
      expect(s2.length, equals(30));

      expect(s2.normalize(-10), equals(0.0));
      expect(s2.normalize(0), equals(0.3333333333333333));
      expect(s2.normalize(5), equals(0.5));
      expect(s2.normalize(15), equals(0.8333333333333334));
      expect(s2.normalize(20), equals(1));

      expect(s2.denormalize(0.0), equals(-10));
      expect(s2.denormalize(0.3333333333333333), equals(0));
      expect(s2.denormalize(0.5), equals(5));
      expect(s2.denormalize(0.8333333333333334), equals(15));
      expect(s2.denormalize(1), equals(20));
    });
  });

  group('Data', () {
    setUp(() {});

    test('Base64,DataURLBase64', () {
      var text = 'Hello';
      var textBase64 = 'SGVsbG8=';

      expect(Base64.encode(text), equals(textBase64));
      expect(Base64.decode(textBase64), equals(text));

      expect(DataURLBase64.matches('data:text/plain;base64,$textBase64'),
          equals(true));

      expect(
          DataURLBase64.parse('data:text/plain;base64,$textBase64')
              .payloadBase64,
          equals(textBase64));
      expect(DataURLBase64.parse('data:text/plain;base64,$textBase64').payload,
          equals(text));
    });

    test('MimeType', () {
      expect(
          MimeType.parse('text/plain').toString(), equals(MimeType.TEXT_PLAIN));
      expect(
          MimeType.byExtension('txt').toString(), equals(MimeType.TEXT_PLAIN));
      expect(
          MimeType.byExtension('text').toString(), equals(MimeType.TEXT_PLAIN));
      expect(MimeType.byExtension('foo.txt').toString(),
          equals(MimeType.TEXT_PLAIN));

      expect(
          MimeType.parse('image/jpeg').toString(), equals(MimeType.IMAGE_JPEG));
      expect(MimeType.parse('jpeg').toString(), equals(MimeType.IMAGE_JPEG));
      expect(
          MimeType.byExtension('jpeg').toString(), equals(MimeType.IMAGE_JPEG));
      expect(
          MimeType.byExtension('jpg').toString(), equals(MimeType.IMAGE_JPEG));

      expect(
          MimeType.parse('image/png').toString(), equals(MimeType.IMAGE_PNG));
      expect(MimeType.parse('png').toString(), equals(MimeType.IMAGE_PNG));
      expect(
          MimeType.byExtension('png').toString(), equals(MimeType.IMAGE_PNG));

      expect(
          MimeType.parse('image/gif').toString(), equals(MimeType.IMAGE_GIF));
      expect(MimeType.parse('gif').toString(), equals(MimeType.IMAGE_GIF));
      expect(
          MimeType.byExtension('gif').toString(), equals(MimeType.IMAGE_GIF));

      expect(
          MimeType.parse('text/html').toString(), equals(MimeType.TEXT_HTML));
      expect(MimeType.parse('html').toString(), equals(MimeType.TEXT_HTML));
      expect(
          MimeType.byExtension('html').toString(), equals(MimeType.TEXT_HTML));
      expect(
          MimeType.byExtension('htm').toString(), equals(MimeType.TEXT_HTML));

      expect(MimeType.parse('text/css').toString(), equals(MimeType.TEXT_CSS));
      expect(MimeType.parse('css').toString(), equals(MimeType.TEXT_CSS));
      expect(MimeType.byExtension('css').toString(), equals(MimeType.TEXT_CSS));

      expect(MimeType.parse('application/json').toString(),
          equals(MimeType.APPLICATION_JSON));
      expect(
          MimeType.parse('json').toString(), equals(MimeType.APPLICATION_JSON));
      expect(MimeType.byExtension('json').toString(),
          equals(MimeType.APPLICATION_JSON));

      expect(MimeType.parse('javascript').toString(),
          equals(MimeType.APPLICATION_JAVASCRIPT));
      expect(MimeType.parse('js').toString(),
          equals(MimeType.APPLICATION_JAVASCRIPT));
      expect(MimeType.byExtension('js').toString(),
          equals(MimeType.APPLICATION_JAVASCRIPT));

      expect(MimeType.parse('zip').toString(), equals('application/zip'));
      expect(MimeType.byExtension('zip').toString(), equals('application/zip'));

      expect(MimeType.parse('gzip').toString(), equals('application/gzip'));
      expect(MimeType.parse('gz').toString(), equals('application/gzip'));
      expect(
          MimeType.byExtension('gzip').toString(), equals('application/gzip'));
      expect(MimeType.byExtension('gz').toString(), equals('application/gzip'));

      expect(MimeType.parse('pdf').toString(), equals('application/pdf'));
      expect(MimeType.byExtension('pdf').toString(), equals('application/pdf'));

      expect(MimeType.parse('xml').toString(), equals('text/xml'));
      expect(MimeType.byExtension('xml').toString(), equals('text/xml'));
    });

    test('dataSizeFormat() decimal', () {
      expect(dataSizeFormat(100), equals('100 bytes'));
      expect(dataSizeFormat(1000), equals('1 KB'));
      expect(dataSizeFormat(1000 * 2), equals('2 KB'));

      expect(dataSizeFormat(1000 * 1000), equals('1 MB'));
      expect(dataSizeFormat(1000 * 1000 * 2), equals('2 MB'));
      expect(dataSizeFormat((1000 * 1000 * 2.5).toInt()), equals('2.5 MB'));
      expect(dataSizeFormat((1000 * 1000 * (2 + 1 / 3)).toInt()),
          equals('2.33 MB'));

      expect(dataSizeFormat(1000 * 2, decimalBase: true), equals('2 KB'));
      expect(dataSizeFormat(1000 * 2, binaryBase: false), equals('2 KB'));
      expect(dataSizeFormat(1000 * 2, decimalBase: true, binaryBase: false),
          equals('2 KB'));
      expect(dataSizeFormat(1000 * 2, decimalBase: true, binaryBase: true),
          equals('2 KB'));
    });

    test('dataSizeFormat() binary', () {
      expect(dataSizeFormat(100, binaryBase: true), equals('100 bytes'));
      expect(dataSizeFormat(1024, binaryBase: true), equals('1 KiB'));
      expect(dataSizeFormat(1024 * 2, binaryBase: true), equals('2 KiB'));

      expect(dataSizeFormat(1024 * 1024, binaryBase: true), equals('1 MiB'));
      expect(
          dataSizeFormat(1024 * 1024 * 2, binaryBase: true), equals('2 MiB'));
      expect(dataSizeFormat((1024 * 1024 * 2.5).toInt(), binaryBase: true),
          equals('2.5 MiB'));
      expect(
          dataSizeFormat((1024 * 1024 * (2 + 1 / 3)).toInt(), binaryBase: true),
          equals('2.33 MiB'));

      expect(dataSizeFormat(1024 * 2, binaryBase: true, decimalBase: false),
          equals('2 KiB'));
    });
  });

  group('Date', () {
    setUp(() {});

    test('Base64,DataURLBase64', () {
      expect(formatTimeMillis(1), equals('1 ms'));
      expect(formatTimeMillis(123), equals('123 ms'));
      expect(formatTimeMillis(1000), equals('1 sec'));
      expect(formatTimeMillis(1500), equals('1.5 sec'));
      expect(formatTimeMillis(2000), equals('2 sec'));
      expect(formatTimeMillis(1000 * 60), equals('1 min'));
      expect(formatTimeMillis(1000 * 60 * 2), equals('2 min'));
      expect(formatTimeMillis((1000 * 60 * 2.5).toInt()), equals('2 min 30 s'));
      expect(formatTimeMillis(1000 * 60 * 60), equals('1 h'));
      expect(formatTimeMillis((1000 * 60 * 60 * 2.5).toInt()),
          equals('2 h 30 min'));
      expect(formatTimeMillis(1000 * 60 * 60 * 24), equals('1 d'));
      expect(formatTimeMillis(1000 * 60 * 60 * 24 * 2), equals('2 d'));
      expect(formatTimeMillis((1000 * 60 * 60 * 24 * 2.5).toInt()),
          equals('2 d 12 h'));
    });
  });

  group('deepHashCode', () {
    setUp(() {});

    test('Base64,DataURLBase64', () {
      expect({'a': 1, 'b': 1}.hashCode == {'a': 1, 'b': 1}.hashCode,
          equals(false));
      expect(deepHashCode({'a': 1, 'b': 1}) == {'a': 1, 'b': 1}.hashCode,
          equals(false));
      expect(deepHashCode({'a': 1, 'b': 1}) == deepHashCode({'a': 1, 'b': 1}),
          equals(true));
    });
  });

  group('RegExp', () {
    setUp(() {});

    test('regExpHasMatch', () {
      expect(regExpHasMatch(r'\w\s*(,+)\s*\w', 'a,b'), equals(true));
      expect(regExpHasMatch(r'\w\s*(,+)\s*\w', 'a, b'), equals(true));
      expect(regExpHasMatch(r'\w\s*(,+)\s*\w', 'a ,b'), equals(true));
      expect(regExpHasMatch(r'\w\s*(,+)\s*\w', 'a , b'), equals(true));
      expect(regExpHasMatch(r'\w\s*(,+)\s*\w', 'a ;, b'), equals(false));
    });

    test('regExpReplaceAll', () {
      expect(regExpReplaceAll(r'\s*(,+)\s*', 'a ,b, c ,, d', '\$1'),
          equals('a,b,c,,d'));
      expect(regExpReplaceAll(r'\s*(,+)\s*', 'a ,b, c ,, d', '-\$1-'),
          equals('a-,-b-,-c-,,-d'));

      expect(regExpReplaceAll(r'\s*(,+)\s*', 'a ,b, c ,, d', '\${1}'),
          equals('a,b,c,,d'));
      expect(regExpReplaceAll(r'\s*(,+)\s*', 'a ,b, c ,, d', '-\${1}-'),
          equals('a-,-b-,-c-,,-d'));
    });

    test('regExpDialect', () {
      var pattern1 = regExpDialect({
        's': '[ \t]',
        'commas': ',+',
      }, r'$s*($commas)$s*');

      expect(regExpReplaceAll(pattern1, 'a ,b, c ,, d', '\$1'),
          equals('a,b,c,,d'));
      expect(regExpReplaceAll(pattern1, 'a ,b, c ,, d', '-\$1-'),
          equals('a-,-b-,-c-,,-d'));
    });

    test('RegExpDialect', () {
      var dialect = RegExpDialect.from({
        's': '[ \t]',
        'commas': ',+',
      }, multiLine: false, caseSensitive: false);

      expect(dialect.hasErrors, isFalse);

      var pattern1 = dialect.getPattern(r'$s*($commas)$s*');

      expect(regExpReplaceAll(pattern1, 'a ,b, c ,, d', '\$1'),
          equals('a,b,c,,d'));
      expect(regExpReplaceAll(pattern1, 'a ,b, c ,, d', '-\$1-'),
          equals('a-,-b-,-c-,,-d'));
    });

    test('RegExpDialect error', () {
      var dialect = RegExpDialect.from({
        's': '[ \t',
        'commas': ',+',
      }, multiLine: false, caseSensitive: false, throwCompilationErrors: false);

      expect(dialect.hasErrors, isTrue);

      var errorWords = dialect.errorWords;
      expect(errorWords, equals(['s']));

      expect(dialect.getWordErrorMessage('s'),
          contains('FormatException: Unterminated character'));
    });

    test('buildStringPattern', () {
      expect(
          buildStringPattern('user: <{{username}}>', {}), equals('user: <>'));
      expect(buildStringPattern('user: <{{username}}>', {'username': 'joe'}),
          equals('user: <joe>'));
      expect(buildStringPattern('user: {{username}}', {'username': 'joe'}),
          equals('user: joe'));
      expect(buildStringPattern('{{username}}', {'username': 'joe'}),
          equals('joe'));
      expect(buildStringPattern('{{username}}!', {'username': 'joe'}),
          equals('joe!'));
      expect(
          buildStringPattern('user: <{{username}}> ; email: <{{email}}>', {
            'username': 'joe'
          }, [
            {'email': 'joe@mail.com'}
          ]),
          equals('user: <joe> ; email: <joe@mail.com>'));
      expect(
          buildStringPattern(
              'user: <{{username}}> ; email: <{{email}}> ; id: #{{id}}', {
            'username': 'joe'
          }, [
            {'email': 'joe@mail.com'},
            {'id': 123}
          ]),
          equals('user: <joe> ; email: <joe@mail.com> ; id: #123'));
    });
  });

  group('Uri', () {
    setUp(() {});

    test('isIPv4Address', () {
      expect(isIPv4Address('0.0.0.0'), equals(true));
      expect(isIPv4Address('192.168.0.1'), equals(true));
      expect(isIPv4Address('10.0.0.1'), equals(true));
      expect(isIPv4Address('172.123.12.1'), equals(true));

      expect(isIPv4Address('000.021.01.0'), equals(false));
      expect(isIPv4Address('123.456.789.123'), equals(false));

      expect(isIPv4Address('abc def'), equals(false));
      expect(isIPv4Address('0.0.0'), equals(false));
    });

    test('isIPv6Address', () {
      expect(isIPv6Address('::1'), equals(true));

      expect(isIPv6Address('::'), equals(true));
      expect(isIPv6Address('::/0'), equals(true));
      expect(isIPv6Address('0000:0000:0000:0000:0000:0000:0000:0000'),
          equals(true));

      expect(isIPv6Address('2001:db8:a0b:12f0::1'), equals(true));

      expect(isIPv6Address('0.0.0.0'), equals(false));
      expect(isIPv6Address('192.168.0.1'), equals(false));
      expect(isIPv6Address('10.0.0.1'), equals(false));
      expect(isIPv6Address('172.123.12.1'), equals(false));

      expect(isIPv6Address('000.021.01.0'), equals(false));
      expect(isIPv6Address('123.456.789.123'), equals(false));

      expect(isIPv6Address('abc def'), equals(false));
      expect(isIPv6Address('0.0.0'), equals(false));
    });

    test('UriBase', () {
      expect(getUriBase().toString(), matches(r'^' + uriRootInit + r'.+'));
      expect(getUriRoot().toString(), equals(uriRoot));
      expect(getUriBaseHost(), equals(uriRootHost));
      expect(getUriBasePort().toString(), matches(uriRootPort));
      expect(getUriBaseScheme(), equals(uriRootScheme));
      expect(getUriBaseHostAndPort(), matches(uriRootHostAndPort));
      expect(getUriRootURL(), equals(uriRoot));

      expect(isUriBaseLocalhost(), equals(true));

      expect(isLocalhost('localhost'), equals(true));
      expect(isLocalhost('127.0.0.1'), equals(true));
      expect(isLocalhost('::1'), equals(true));
      expect(isLocalhost('local'), equals(false));
      expect(isLocalhost('www.foo.com'), equals(false));
      expect(isLocalhost('0.0.0.0'), equals(true));

      expect(isIPAddress('192.168.0.1'), equals(true));
      expect(isIPAddress('192.168.0.50'), equals(true));
      expect(isIPAddress('10.0.0.1'), equals(true));
      expect(isIPAddress('localhost'), equals(false));
      expect(isIPAddress('foo.com'), equals(false));
    });

    test('Uri', () {
      expect(buildUri('http', 'foo', 80).toString(), equals('http://foo/'));
      expect(buildUri('http', 'foo', 81).toString(), equals('http://foo:81/'));

      expect(
          buildUri('http', 'foo', 81,
                  path: 'path/x', queryString: 'query=1', fragment: 'frag1')
              .toString(),
          equals('http://foo:81/path/x?query=1#frag1'));

      expect(
          buildUri('http', 'foo', 81,
                  path: 'path/x',
                  path2: './y',
                  queryString: 'query=1',
                  fragment: 'frag1')
              .toString(),
          equals('http://foo:81/path/y?query=1#frag1'));
      expect(
          buildUri('http', 'foo', 81,
                  path: 'path/x',
                  path2: 'y',
                  queryString: 'query=1',
                  fragment: 'frag1')
              .toString(),
          equals('http://foo:81/path/y?query=1#frag1'));

      expect(
          buildUri('http', 'foo', 81,
                  path: 'path/x/',
                  path2: './y',
                  queryString: 'query=1',
                  fragment: 'frag1')
              .toString(),
          equals('http://foo:81/path/x/y?query=1#frag1'));
      expect(
          buildUri('http', 'foo', 81,
                  path: 'path/x/',
                  path2: 'y',
                  queryString: 'query=1',
                  fragment: 'frag1')
              .toString(),
          equals('http://foo:81/path/x/y?query=1#frag1'));

      expect(
          buildUri('http', 'foo', 81,
                  path: 'path/x',
                  path2: '/y',
                  queryString: 'query=1',
                  fragment: 'frag1')
              .toString(),
          equals('http://foo:81/y?query=1#frag1'));

      expect(resolveUri('/').toString(), equals(uriRoot));
      expect(resolveUri('/foo.txt').toString(), equals('${uriRoot}foo.txt'));

      expect(resolveUri('./foo.txt').toString(),
          matches(r'^' + uriRootInit + r'.+?/foo\.txt$'));

      expect(
          removeUriFragment('https://foo:81/path/x?query=1#section1')
              .toString(),
          equals('https://foo:81/path/x?query=1'));
      expect(
          removeUriQueryString('https://foo:81/path/x?query=1#section1')
              .toString(),
          equals('https://foo:81/path/x#section1'));
    });

    test('Path', () {
      expect(getPathFileName('/some/path/file-x.txt').toString(),
          equals('file-x.txt'));
      expect(
          getPathExtension('/some/path/file-x.txt').toString(), equals('txt'));
    });
  });

  group('isType', () {
    setUp(() {});

    test('isInt', () {
      expect(isInt(1), equals(true));
      expect(isInt(1.0), equals(true));
      expect(isInt(123), equals(true));
      expect(isInt('1'), equals(true));
      expect(isInt('123'), equals(true));

      expect(isInt('aa'), equals(false));
      expect(isInt(''), equals(false));
      expect(isInt(1.1), equals(false));
      expect(isInt(true), equals(false));
      expect(isInt(null), equals(false));
    });

    test('isNum', () {
      expect(isNum(1), equals(true));
      expect(isNum(1.0), equals(true));
      expect(isNum(123), equals(true));
      expect(isNum('1'), equals(true));
      expect(isNum('123'), equals(true));
      expect(isNum(1.1), equals(true));

      expect(isNum('aa'), equals(false));
      expect(isNum(''), equals(false));
      expect(isNum(true), equals(false));
      expect(isNum(null), equals(false));
    });

    test('isDouble', () {
      expect(isDouble(1.0), equals(true));
      expect(isDouble(2.0), equals(true));
      expect(isDouble(2.2), equals(true));
      expect(isDouble(1.1), equals(true));
      expect(isDouble('123.1'), equals(true));

      expect(isDouble('1'), equals(false));
      expect(isDouble('123'), equals(false));
      expect(isDouble('aa'), equals(false));
      expect(isDouble(''), equals(false));
      expect(isDouble(true), equals(false));
      expect(isDouble(null), equals(false));
    });

    test('isBool', () {
      expect(isBool(true), equals(true));
      expect(isBool(false), equals(true));
      expect(isBool('true'), equals(true));
      expect(isBool('false'), equals(true));
      expect(isBool('yes'), equals(true));
      expect(isBool('no'), equals(true));

      expect(isBool(1.0), equals(false));
      expect(isBool(2.0), equals(false));
      expect(isBool(2.2), equals(false));
      expect(isBool(1.1), equals(false));
      expect(isBool('123.1'), equals(false));

      expect(isBool('1'), equals(false));
      expect(isBool('123'), equals(false));
      expect(isBool('aa'), equals(false));
      expect(isBool(''), equals(false));
      expect(isBool(null), equals(false));
    });

    test('isIntList', () {
      expect(isIntList('1'), equals(false));
      expect(isIntList('1,2'), equals(true));
      expect(isIntList('1,2,3'), equals(true));

      expect(isIntList('1'), equals(false));
      expect(isIntList('123'), equals(false));

      expect(isIntList('1 2 3'), equals(false));
      expect(isIntList('1 2 3', ' '), equals(true));

      expect(isIntList('a,a'), equals(false));
      expect(isIntList(123), equals(false));
      expect(isIntList(null), equals(false));
    });

    test('isNumList', () {
      expect(isNumList('1'), equals(false));
      expect(isNumList('1,2'), equals(true));
      expect(isNumList('1.1,2'), equals(true));
      expect(isNumList('1,2,3'), equals(true));
      expect(isNumList('1,2.2,3'), equals(true));
      expect(isNumList('1.1,2.2,3'), equals(true));

      expect(isNumList('1'), equals(false));
      expect(isNumList('1.1'), equals(false));
      expect(isNumList('123'), equals(false));
      expect(isNumList('123.4'), equals(false));

      expect(isNumList('1 2 3'), equals(false));
      expect(isNumList('1 2 3', ' '), equals(true));
      expect(isNumList('1.1 2.2 3', ' '), equals(true));

      expect(isNumList('a,a'), equals(false));
      expect(isNumList(123), equals(false));
      expect(isNumList(null), equals(false));
    });

    test('isDoubleList', () {
      expect(isDoubleList('1'), equals(false));

      expect(isDoubleList('1,2.2'), equals(false));
      expect(isDoubleList('1.1,2'), equals(false));
      expect(isDoubleList('1.1,2.2'), equals(true));

      expect(isDoubleList('1,2,3'), equals(false));
      expect(isDoubleList('1.1,2.2,3.3'), equals(true));

      expect(isDoubleList('1'), equals(false));
      expect(isDoubleList('1.1'), equals(false));
      expect(isDoubleList('123'), equals(false));
      expect(isDoubleList('123.4'), equals(false));

      expect(isDoubleList('1 2 3'), equals(false));
      expect(isDoubleList('1 2 3', ' '), equals(false));
      expect(isDoubleList('1.1 2.2 3.3', ' '), equals(true));

      expect(isDoubleList('a,a'), equals(false));
      expect(isDoubleList(123), equals(false));
      expect(isDoubleList(null), equals(false));
    });

    test('isBoolList', () {
      expect(isBoolList('true'), equals(false));

      expect(isBoolList('true,true,false'), equals(true));
      expect(isBoolList('true,yes,no'), equals(true));

      expect(isBoolList(1), equals(false));
      expect(isBoolList(123), equals(false));
      expect(isBoolList(1.2), equals(false));
      expect(isBoolList('aaa'), equals(false));
      expect(isBoolList(true), equals(false));
      expect(isBoolList(false), equals(false));
    });

    test('toFlatListOfStrings', () {
      expect(toFlatListOfStrings(null), equals([]));
      expect(toFlatListOfStrings(''), equals([]));
      expect(toFlatListOfStrings(' '), equals([]));

      expect(toFlatListOfStrings('a'), equals(['a']));
      expect(toFlatListOfStrings('a b c'), equals(['a', 'b', 'c']));

      expect(
          toFlatListOfStrings([
            'a b c',
            ['d e', ' f ', 'g']
          ]),
          equals(['a', 'b', 'c', 'd', 'e', 'f', 'g']));

      expect(
          toFlatListOfStrings([
            'a b c',
            [
              'd e',
              [' f '],
              'g'
            ]
          ]),
          equals(['a', 'b', 'c', 'd', 'e', 'f', 'g']));

      expect(
          toFlatListOfStrings([
            '   ',
            'a b c  ',
            [
              'd e',
              null,
              '',
              [' f ', 'g'],
              [],
              'h'
            ]
          ]),
          equals(['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h']));

      expect(toFlatListOfStrings(['a', ' b ', 'c']), equals(['a', 'b', 'c']));
      expect(toFlatListOfStrings(['a', ' b ', 'c'], trim: true),
          equals(['a', 'b', 'c']));
      expect(toFlatListOfStrings(['a', ' b ', 'c'], trim: false),
          equals(['a', 'b', 'c']));

      expect(toFlatListOfStrings(['a', ' b ', 'c'], trim: null),
          equals(['a', 'b', 'c']));

      expect(toFlatListOfStrings([' a ', ' b ', 'c_d'], delimiter: '_'),
          equals(['a', 'b', 'c', 'd']));
      expect(
          toFlatListOfStrings([' a ', ' b ', 'c_d'],
              delimiter: '_', trim: true),
          equals(['a', 'b', 'c', 'd']));
      expect(
          toFlatListOfStrings([' a ', ' b ', 'c_d'],
              delimiter: '_', trim: false),
          equals([' a ', ' b ', 'c', 'd']));
    });

    test('listMatchesAll/listNotMatchesAll', () {
      expect(listMatchesAll(null, (e) => e == 1), equals(false));
      expect(listMatchesAll([], (e) => e == 1), equals(false));

      expect(listMatchesAll([1, 1, 1], (e) => e == 1), equals(true));
      expect(listMatchesAll([1, 0, 1], (e) => e == 1), equals(false));
      expect(listMatchesAll([1, 1, 1], (e) => e == 0), equals(false));
      expect(listMatchesAll([1, 1, null, 1], (e) => e == 0), equals(false));

      expect(listNotMatchesAll(null, (e) => e == 1), equals(false));
      expect(listNotMatchesAll([], (e) => e == 1), equals(false));

      expect(listNotMatchesAll([1, 1, 1], (e) => e == 1), equals(false));
      expect(listNotMatchesAll([1, 0, 1], (e) => e == 1), equals(true));
      expect(listNotMatchesAll([1, 1, 1], (e) => e == 0), equals(true));
      expect(listNotMatchesAll([1, 1, null, 1], (e) => e == 0), equals(true));

      expect(isListValuesAllEquals([3, 3, 3, 3, 3], 3), equals(true));
      expect(isListValuesAllEquals([3, 3, 3, 3, 3]), equals(true));
      expect(isListValuesAllEquals([3, 3, 3, 2, 3]), equals(false));
      expect(isListValuesAllEquals([3, 3, 3, 3, 3], 2), equals(false));
    });

    test('isEmptyObject', () {
      expect(isEmptyObject(null), isTrue);
      expect(isEmptyObject([]), isTrue);
      expect(isEmptyObject({}), isTrue);
      expect(isEmptyObject(<dynamic>{}), isTrue);
      expect(isEmptyObject(''), isTrue);

      expect(isEmptyObject([1]), isFalse);
      expect(isEmptyObject([1, 2]), isFalse);

      expect(isEmptyObject({'a': 1}), isFalse);
      expect(isEmptyObject({'a': 1, 'b': 2}), isFalse);

      expect(isEmptyObject({1}), isFalse);
      expect(isEmptyObject({1, 2}), isFalse);

      expect(isEmptyObject('1'), isFalse);
      expect(isEmptyObject('12'), isFalse);
    });
  });

  group('JSON', () {
    setUp(() {});

    test('isJSONPrimitive', () {
      expect(isJSONPrimitive('string'), isTrue);
      expect(isJSONPrimitive(true), isTrue);
      expect(isJSONPrimitive(123), isTrue);
      expect(isJSONPrimitive(1.5), isTrue);

      expect(isJSONPrimitive([]), isFalse);
      expect(isJSONPrimitive({}), isFalse);
    });

    test('isJSONList', () {
      expect(isJSONList([]), isTrue);
      expect(isJSONList([1, 2]), isTrue);

      expect(isJSONList({}), isFalse);

      expect(isJSONList('string'), isFalse);
      expect(isJSONList(true), isFalse);
      expect(isJSONList(123), isFalse);
      expect(isJSONList(1.5), isFalse);
    });

    test('isJSONMap', () {
      expect(isJSONMap({'a': 1}), isTrue);
      expect(isJSONMap({'b': 's'}), isTrue);

      expect(isJSONMap([]), isFalse);
      expect(isJSONMap([1, 2]), isFalse);

      expect(isJSONMap('string'), isFalse);
      expect(isJSONMap(true), isFalse);
      expect(isJSONMap(123), isFalse);
      expect(isJSONMap(1.5), isFalse);
    });

    test('isJSON', () {
      expect(isJSON('string'), isTrue);
      expect(isJSON(true), isTrue);
      expect(isJSON(123), isTrue);
      expect(isJSON(1.5), isTrue);

      expect(isJSON([]), isTrue);
      expect(isJSON([1, 2]), isTrue);

      expect(isJSON({'a': 1}), isTrue);
      expect(isJSON({'b': 's'}), isTrue);
    });

    test('toEncodableJSON', () {
      expect(toEncodableJSON('abc'), equals('abc'));
      expect(toEncodableJSON(123), equals(123));
      expect(toEncodableJSON(1.2), equals(1.2));
      expect(toEncodableJSON(true), equals(true));
      expect(toEncodableJSON(false), equals(false));
      expect(toEncodableJSON(null), equals(null));

      expect(toEncodableJSON(['a', 'b']), equals(['a', 'b']));
      expect(toEncodableJSON([1, 2, 3]), equals([1, 2, 3]));
      expect(
          toEncodableJSON(['a', 2, Foo(2, 'b')]),
          equals([
            'a',
            2,
            {'id': 2, 'name': 'b'}
          ]));

      expect(
          toEncodableJSON({'a': 'A', 'b': 'B'}), equals({'a': 'A', 'b': 'B'}));
      expect(toEncodableJSON({'a': 1, 'b': 2}), equals({'a': 1, 'b': 2}));

      expect(
          toEncodableJSON(Foo(123, 'abc')), equals({'id': 123, 'name': 'abc'}));

      expect(
          toEncodableJSON(Bar(123, 'abc')), equals('Bar{id: 123, name: abc}'));
    });
  });

  group('MapDelegate', () {
    setUp(() {});

    test('MapDelegate basic', () {
      var map1 = {'a': 1, 'b': 2};

      var map2 = MapDelegate(map1);

      expect(identical(map1, map2), isFalse);

      expect(map1, equals(map2));

      map1['c'] = 3;

      expect(map1.length, equals(map2.length));
      expect(map1['c'], equals(3));
      expect(map2['c'], equals(3));
      expect(map1, equals(map2));

      map1.remove('b');

      expect(map1.length, equals(map2.length));
      expect(map1.containsKey('b'), isFalse);
      expect(map2.containsKey('b'), isFalse);
      expect(map1, equals(map2));
    });
  });

  group('MapProperties', () {
    setUp(() {});

    test('MapProperties String', () {
      var map = MapProperties.fromStringProperties({'a': '1', 'b': '2'});

      expect(map.getPropertyAsInt('a'), equals(1));
      expect(map.getPropertyAsInt('b'), equals(2));
      expect(map.getPropertyAsInt('b', 20), equals(2));
      expect(map.getPropertyAsInt('c', 30), equals(30));
    });

    test('MapProperties dynamic', () {
      var map = MapProperties.fromProperties({
        'a': 1,
        'b': [20, 21],
        'c': '30,31,32'
      });

      expect(map.getPropertyAsInt('a'), equals(1));
      expect(map.getPropertyAsIntList('b'), equals([20, 21]));
      expect(map.getPropertyAsIntList('b', [200, 201]), equals([20, 21]));
      expect(map.getPropertyAsIntList('c'), equals([30, 31, 32]));

      expect(map.getPropertyAsIntList('d', [40, 41]), equals([40, 41]));

      var map2 = map.toStringProperties();
      expect(map2, equals({'a': '1', 'b': '[20, 21]', 'c': '30,31,32'}));

      var map3 = map.toProperties();
      expect(
          map3,
          equals({
            'a': 1,
            'b': [20, 21],
            'c': '30,31,32'
          }));
    });
  });

  group('Date', () {
    setUp(() {});

    test('getDateTimeStartOf/EndOf', () {
      expect(
          getDateTimeStartOf(
              DateTime(2020, 03, 12, 10, 30, 59, 300), Unit.Seconds),
          equals(DateTime(2020, 03, 12, 10, 30, 59, 0)));
      expect(getDateTimeEndOf(DateTime(2020, 03, 12, 10, 30, 59, 300), 'sec'),
          equals(DateTime(2020, 03, 12, 10, 30, 59, 999)));

      expect(getDateTimeStartOf(DateTime(2020, 03, 12, 10, 30, 59, 300), 'min'),
          equals(DateTime(2020, 03, 12, 10, 30, 0, 0)));
      expect(getDateTimeEndOf(DateTime(2020, 03, 12, 10, 30, 59, 300), 'min'),
          equals(DateTime(2020, 03, 12, 10, 30, 59, 999)));

      expect(
          getDateTimeStartOf(DateTime(2020, 03, 12, 10, 30, 59, 300), 'hour'),
          equals(DateTime(2020, 03, 12, 10, 0, 0, 0)));
      expect(getDateTimeEndOf(DateTime(2020, 03, 12, 10, 30, 59, 300), 'hour'),
          equals(DateTime(2020, 03, 12, 10, 59, 59, 999)));

      expect(getDateTimeStartOf(DateTime(2020, 03, 12, 10, 30, 59, 300), 'day'),
          equals(DateTime(2020, 03, 12, 0, 0, 0, 0)));
      expect(getDateTimeEndOf(DateTime(2020, 03, 12, 10, 30, 59, 300), 'day'),
          equals(DateTime(2020, 03, 12, 23, 59, 59, 999)));

      expect(
          getDateTimeStartOf(DateTime(2020, 03, 12, 10, 30, 59, 300), 'month'),
          equals(DateTime(2020, 03, 1, 0, 0, 0, 0)));
      expect(
          getDateTimeEndOf(
              DateTime(2020, 03, 12, 10, 30, 59, 300), Unit.Months),
          equals(DateTime(2020, 03, 31, 23, 59, 59, 999)));

      expect(getDateTimeStartOf(DateTime(2020, 03, 12, 10, 30, 59, 300), 'y'),
          equals(DateTime(2020, 01, 1, 0, 0, 0, 0)));
      expect(
          getDateTimeEndOf(DateTime(2020, 03, 12, 10, 30, 59, 300), Unit.Years),
          equals(DateTime(2020, 12, 31, 23, 59, 59, 999)));
    });
  });

  group('Date', () {
    setUp(() {});

    test('getDateTimeStartOf/EndOf', () {
      var cachedComputation = CachedComputation<int,
          Parameters2<List<int>, int>, Parameters2<List<int>, int>>((v) {
        return sumIterable(v.a.map((n) => n * v.b));
      });

      expect(cachedComputation.cacheSize, equals(0));
      expect(cachedComputation.computationCount, equals(0));

      expect(cachedComputation.compute(Parameters2([1, 2], 3)), equals(9));

      expect(cachedComputation.cacheSize, equals(1));
      expect(cachedComputation.computationCount, equals(1));

      expect(cachedComputation.compute(Parameters2([1, 2], 3)), equals(9));

      expect(cachedComputation.cacheSize, equals(1));
      expect(cachedComputation.computationCount, equals(1));
    });
  });
}
