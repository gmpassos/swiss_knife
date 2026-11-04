import 'package:swiss_knife/swiss_knife.dart';
import 'package:test/test.dart';

class _WithToJson {
  final int id;

  _WithToJson(this.id);

  Map<String, Object?> toJson() => {
    'id': id,
    'tags': <Object>{'a'},
  };
}

class _NoToJson {
  @override
  String toString() => 'NoToJson!';
}

class _NullToJson {
  // A `toJson` member that is `null` makes `toEncodableJSON` fall back to
  // `toString()`.
  Function? get toJson => null;

  @override
  String toString() => 'NullToJson!';
}

void main() {
  group('parseJSON', () {
    test('null, empty and blank', () {
      expect(parseJSON(null), isNull);
      expect(parseJSON(null, 'def'), equals('def'));
      expect(parseJSON('', 1), equals(1));
      expect(parseJSON(' \n\t ', 2), equals(2));
    });

    test('decodes strings', () {
      expect(
        parseJSON('{"a":1,"b":[true,null,"x"]}'),
        equals({
          'a': 1,
          'b': [true, null, 'x'],
        }),
      );
      expect(parseJSON('[1,2]'), equals([1, 2]));
      expect(parseJSON('"s"'), equals('s'));
      expect(() => parseJSON('{bad'), throwsFormatException);
    });

    test('non-string values are returned as is', () {
      var list = [1, 2];
      expect(parseJSON(list), same(list));
      expect(parseJSON(123), equals(123));
    });

    test('long blank string', () {
      // NOTE: current behaviour; possibly a bug: the blank-string shortcut only
      // applies to strings shorter than 100 chars, so a longer blank string is
      // decoded and throws instead of returning `def`.
      expect(() => parseJSON(' ' * 100, 'def'), throwsFormatException);
      expect(parseJSON(' ' * 99, 'def'), equals('def'));
    });
  });

  group('encodeJSON', () {
    test('plain', () {
      expect(
        encodeJSON({
          'a': 1,
          'b': [true, 'x', null],
        }),
        equals('{"a":1,"b":[true,"x",null]}'),
      );
      expect(encodeJSON(null), equals('null'));
      expect(encodeJSON('x'), equals('"x"'));
    });

    test('indent', () {
      expect(encodeJSON({'a': 1}, withIndent: true), equals('{\n  "a": 1\n}'));
      expect(
        encodeJSON({'a': 1}, withIndent: true, indent: ''),
        equals('{\n  "a": 1\n}'),
      );
      expect(encodeJSON({'a': 1}, indent: '\t'), equals('{\n\t"a": 1\n}'));
      expect(
        encodeJSON([1], indent: '    ', withIndent: true),
        equals('[\n    1\n]'),
      );
    });

    test('clearNullEntries mutates the input', () {
      var m = <String, Object?>{
        'a': 1,
        'b': null,
        'c': [1, null],
      };
      expect(encodeJSON(m, clearNullEntries: true), equals('{"a":1,"c":[1]}'));
      expect(
        m,
        equals({
          'a': 1,
          'c': [1],
        }),
      );
    });

    test('toEncodable', () {
      expect(
        encodeJSON({'o': _WithToJson(7)}),
        equals('{"o":{"id":7,"tags":["a"]}}'),
      );
      expect(encodeJSON([_NoToJson()]), equals('["NoToJson!"]'));
      expect(
        encodeJSON([_NoToJson()], toEncodable: (o) => 'custom'),
        equals('["custom"]'),
      );
    });
  });

  group('removeNullEntries', () {
    test('lists and maps', () {
      expect(removeNullEntries(null), isNull);
      expect(removeNullEntries(5), equals(5));
      expect(
        removeNullEntries([
          1,
          null,
          [2, null],
          {'a': null, 'b': 3},
        ]),
        equals([
          1,
          [2],
          {'b': 3},
        ]),
      );
      expect(
        removeNullEntries(<Object?, Object?>{
          null: 1,
          'a': null,
          'b': {'c': null, 'd': 1},
          'e': [null, 'x'],
        }),
        equals({
          'b': {'d': 1},
          'e': ['x'],
        }),
      );
    });
  });

  group('isJSON*', () {
    test('isJSONPrimitive', () {
      expect(isJSONPrimitive(null), isTrue);
      expect(isJSONPrimitive('a'), isTrue);
      expect(isJSONPrimitive(1), isTrue);
      expect(isJSONPrimitive(1.5), isTrue);
      expect(isJSONPrimitive(true), isTrue);
      expect(isJSONPrimitive([1]), isFalse);
      expect(isJSONPrimitive(Object()), isFalse);
    });

    test('isJSONList', () {
      expect(isJSONList(null), isFalse);
      expect(isJSONList(<String>['a']), isTrue);
      expect(isJSONList(<num>[1]), isTrue);
      expect(isJSONList(<int>[1]), isTrue);
      expect(isJSONList(<double>[1.5]), isTrue);
      expect(isJSONList(<bool>[true]), isTrue);
      expect(isJSONList(<Object?>[]), isTrue);
      expect(
        isJSONList(<Object?>[
          1,
          'a',
          null,
          [2],
          {'k': 1},
        ]),
        isTrue,
      );
      expect(isJSONList(<Object>[Object()]), isFalse);
      expect(isJSONList('[1]'), isFalse);
    });

    test('isJSONMap', () {
      expect(isJSONMap(null), isFalse);
      expect(isJSONMap(<String, String>{'a': 'b'}), isTrue);
      expect(isJSONMap(<String, num>{'a': 1}), isTrue);
      expect(isJSONMap(<String, int>{'a': 1}), isTrue);
      expect(isJSONMap(<String, double>{'a': 1.5}), isTrue);
      expect(isJSONMap(<String, bool>{'a': true}), isTrue);
      expect(isJSONMap(<Object?, Object?>{}), isTrue);
      expect(
        isJSONMap(<Object?, Object?>{
          'a': [1],
          'b': {'c': null},
        }),
        isTrue,
      );
      expect(isJSONMap(<Object, Object>{1: 'a'}), isFalse);
      expect(isJSONMap(<String, Object>{'a': Object()}), isFalse);
      expect(isJSONMap(5), isFalse);
    });

    test('isJSON', () {
      expect(isJSON(null), isTrue);
      expect(isJSON('x'), isTrue);
      expect(isJSON([1, 'a']), isTrue);
      expect(isJSON({'a': 1}), isTrue);
      expect(isJSON(Object()), isFalse);
      expect(isJSON({1: 1}), isFalse);
    });
  });

  group('toEncodableJSON', () {
    test('primitives and collections', () {
      expect(toEncodableJSON(null), isNull);
      expect(toEncodableJSON(1), equals(1));
      expect(toEncodableJSON(true), isTrue);
      expect(toEncodableJSON('s'), equals('s'));
      expect(toEncodableJSON([1, 2]), equals([1, 2]));
      expect(toEncodableJSON({'a': 1}), equals({'a': 1}));
      expect(toEncodableJSON(<Object>{1, 'x'}), equals([1, 'x']));
    });

    test('objects', () {
      expect(
        toEncodableJSON(_WithToJson(3)),
        equals({
          'id': 3,
          'tags': ['a'],
        }),
      );
      expect(toEncodableJSON(_NoToJson()), equals('NoToJson!'));
      expect(toEncodableJSON(_NullToJson()), equals('NullToJson!'));
    });
  });

  group('toEncodableJSONList', () {
    test('typed lists are returned as is', () {
      expect(toEncodableJSONList(null), equals([]));

      for (var l in <List>[
        <num>[1],
        <int>[1],
        <double>[1.5],
        <bool>[true],
        <String>['a'],
        <List<num>>[
          [1],
        ],
        <List<int>>[
          [1],
        ],
        <List<double>>[
          [1.5],
        ],
        <List<bool>>[
          [true],
        ],
        <List<String>>[
          ['a'],
        ],
        <Map<String, num>>[
          {'a': 1},
        ],
        <Map<String, int>>[
          {'a': 1},
        ],
        <Map<String, double>>[
          {'a': 1.5},
        ],
        <Map<String, bool>>[
          {'a': true},
        ],
        <Map<String, String>>[
          {'a': 'b'},
        ],
      ]) {
        expect(toEncodableJSONList(l), same(l), reason: '$l');
      }
    });

    test('untyped lists', () {
      var empty = <Object?>[];
      var r0 = toEncodableJSONList(empty);
      expect(r0, isEmpty);
      expect(r0, isNot(same(empty)));

      var ints = toEncodableJSONList(<Object?>[1, 2]);
      expect(ints, isA<List<int>>());
      expect(ints, equals([1, 2]));

      var doubles = toEncodableJSONList(<Object?>[1.5, 2.5]);
      expect(doubles, isA<List<double>>());
      expect(doubles, equals([1.5, 2.5]));

      var bools = toEncodableJSONList(<Object?>[true, false]);
      expect(bools, isA<List<bool>>());
      expect(bools, equals([true, false]));

      var strings = toEncodableJSONList(<Object?>['a', 'b']);
      expect(strings, isA<List<String>>());
      expect(strings, equals(['a', 'b']));

      expect(
        toEncodableJSONList(<Object?>[
          1,
          'a',
          null,
          {
            1: <Object>{2},
          },
        ]),
        equals([
          1,
          'a',
          null,
          {
            '1': [2],
          },
        ]),
      );
    });
  });

  group('toEncodableJSONMap', () {
    test('typed maps are returned as is', () {
      expect(toEncodableJSONMap(null), equals({}));

      for (var m in <Map>[
        <String, num>{'a': 1},
        <String, int>{'a': 1},
        <String, double>{'a': 1.5},
        <String, bool>{'a': true},
        <String, String>{'a': 'b'},
        <String, List<num>>{
          'a': [1],
        },
        <String, List<int>>{
          'a': [1],
        },
        <String, List<double>>{
          'a': [1.5],
        },
        <String, List<bool>>{
          'a': [true],
        },
        <String, List<String>>{
          'a': ['b'],
        },
      ]) {
        expect(toEncodableJSONMap(m), same(m), reason: '$m');
      }
    });

    test('untyped maps', () {
      var empty = <Object?, Object?>{};
      var r0 = toEncodableJSONMap(empty);
      expect(r0, isA<Map<String, dynamic>>());
      expect(r0, isEmpty);

      // NOTE: current behaviour; possibly a bug: the homogeneous-value branches
      // (`value as int`, `as double`, ...) look meant to return a typed map,
      // but `Map.map` is inferred from the `Map` return type, so the result is
      // a plain `Map<dynamic, dynamic>` copy.
      var intsIn = <String, dynamic>{'a': 1, 'b': 2};
      var ints = toEncodableJSONMap(intsIn);
      expect(ints, isNot(same(intsIn)));
      expect(ints, isNot(isA<Map<dynamic, int>>()));
      expect(ints, equals({'a': 1, 'b': 2}));

      var doubles = toEncodableJSONMap(<String, Object>{'a': 1.5});
      expect(doubles, isNot(isA<Map<dynamic, double>>()));
      expect(doubles, equals({'a': 1.5}));

      var bools = toEncodableJSONMap(<String, dynamic>{'a': true});
      expect(bools, equals({'a': true}));

      var strings = toEncodableJSONMap(<String, dynamic>{'a': 'x'});
      expect(strings, equals({'a': 'x'}));

      expect(
        toEncodableJSONMap(<String, Object>{'a': 1, 'b': 'x'}),
        equals({'a': 1, 'b': 'x'}),
      );
      expect(
        toEncodableJSONMap(<Object?, Object?>{
          1: <Object>{2},
          'o': _WithToJson(1),
        }),
        equals({
          '1': [2],
          'o': {
            'id': 1,
            'tags': ['a'],
          },
        }),
      );
    });
  });

  group('isEncodedJSON*', () {
    test('isEncodedJSON', () {
      expect(isEncodedJSON(null), isFalse);
      expect(isEncodedJSON('  '), isFalse);
      expect(isEncodedJSON(' 1 '), isTrue);
      expect(isEncodedJSON('true'), isTrue);
      expect(isEncodedJSON('null'), isTrue);
      expect(isEncodedJSON('"a"'), isTrue);
      expect(isEncodedJSON('[1, 2]'), isTrue);
      expect(isEncodedJSON('{"a": 1}'), isTrue);
      expect(isEncodedJSON('abc'), isFalse);
      expect(isEncodedJSON('{a}'), isFalse);
      expect(isEncodedJSON('[1'), isFalse);
    });

    test('isEncodedJSONPrimitive', () {
      expect(isEncodedJSONPrimitive(null), isFalse);
      expect(isEncodedJSONPrimitive(' '), isFalse);
      expect(isEncodedJSONPrimitive(' "x" '), isTrue);
      expect(isEncodedJSONPrimitive('false'), isTrue);
      expect(isEncodedJSONPrimitive('-1.5e3'), isTrue);
      expect(isEncodedJSONPrimitive('null'), isTrue);
      expect(isEncodedJSONPrimitive('[1]'), isFalse);
      expect(isEncodedJSONPrimitive('{}'), isFalse);
    });

    test('isEncodedJSONNull', () {
      expect(isEncodedJSONNull(null), isFalse);
      expect(isEncodedJSONNull(' null '), isTrue);
      expect(isEncodedJSONNull('nil'), isFalse);
      expect(isEncodedJSONNull('"null"'), isFalse);
    });

    test('isEncodedJSONBoolean', () {
      expect(isEncodedJSONBoolean(null), isFalse);
      expect(isEncodedJSONBoolean(' true'), isTrue);
      expect(isEncodedJSONBoolean('false '), isTrue);
      expect(isEncodedJSONBoolean('yes'), isFalse);
      expect(isEncodedJSONBoolean('TRUE'), isFalse);
    });

    test('isEncodedJSONNumber', () {
      expect(isEncodedJSONNumber(null), isFalse);
      expect(isEncodedJSONNumber('  '), isFalse);
      expect(isEncodedJSONNumber(' 10 '), isTrue);
      expect(isEncodedJSONNumber('1.5'), isTrue);
      expect(isEncodedJSONNumber('abc'), isFalse);

      // NOTE: current behaviour; possibly a bug: number detection relies on
      // `num.tryParse`, which accepts tokens that are not valid JSON numbers.
      expect(isEncodedJSONNumber('NaN'), isTrue);
      expect(isEncodedJSONNumber('0x1F'), isTrue);
      expect(isEncodedJSON('NaN'), isTrue);
    });

    test('isEncodedJSONString', () {
      expect(isEncodedJSONString(null), isFalse);
      expect(isEncodedJSONString('""'), isTrue);
      expect(isEncodedJSONString(' "abc" '), isTrue);
      expect(isEncodedJSONString(r'"a\"b"'), isTrue);
      expect(isEncodedJSONString('"a"b"'), isFalse);
      expect(isEncodedJSONString('"'), isFalse);
      expect(isEncodedJSONString('abc'), isFalse);
      expect(isEncodedJSONString("'abc'"), isFalse);
    });

    test('isEncodedJSONList', () {
      expect(isEncodedJSONList(null), isFalse);
      expect(isEncodedJSONList(' '), isFalse);
      expect(isEncodedJSONList('[]'), isTrue);
      expect(isEncodedJSONList(' [1, "a"] '), isTrue);
      expect(isEncodedJSONList('[1,'), isFalse);
      expect(isEncodedJSONList('[1,]'), isFalse);
      expect(isEncodedJSONList('{}'), isFalse);
    });

    test('isEncodedJSONMap', () {
      expect(isEncodedJSONMap(null), isFalse);
      expect(isEncodedJSONMap(''), isFalse);
      expect(isEncodedJSONMap('{}'), isTrue);
      expect(isEncodedJSONMap(' {"a": [1]} '), isTrue);
      expect(isEncodedJSONMap('{a: 1}'), isFalse);
      expect(isEncodedJSONMap('[]'), isFalse);
    });
  });
}
