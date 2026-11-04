import 'dart:typed_data';

import 'package:swiss_knife/swiss_knife.dart';
import 'package:test/test.dart';

void main() {
  group('Pair', () {
    test('basic', () {
      var p = Pair(1, 2);
      expect(p.a, equals(1));
      expect(p.b, equals(2));
      expect(p.swapAB(), equals(Pair(2, 1)));
      expect(p, equals(Pair(1, 2)));
      expect(p.hashCode, equals(Pair(1, 2).hashCode));
      expect(p == Pair(1, 3), isFalse);
      expect(p.toString(), equals('[1, 2]'));
      expect(p.join(), equals('12'));
      expect(p.join('x'), equals('1x2'));
      expect(p.asList, equals([1, 2]));
      expect(p.asMapEntry.key, equals(1));
      expect(p.asMapEntry.value, equals(2));
      expect(p.asPoint.x, equals(1));
      expect(p.asPoint.y, equals(2));
    });

    test('fromList and nulls', () {
      expect(Pair.fromList([3, 4]), equals(Pair(3, 4)));
      expect(Pair.fromList([5]), equals(Pair(5, 5)));

      var p = Pair<String?>(null, 'b');
      expect(p.aNotNull, isFalse);
      expect(p.bNotNull, isTrue);
      expect(p.aAsString, equals(''));
      expect(p.bAsString, equals('b'));
    });
  });

  group('Dimension', () {
    test('basic', () {
      var d = Dimension(800, 600);
      expect(d.width, equals(800));
      expect(d.height, equals(600));
      expect(d.area, equals(480000));
      expect(d.toString(), equals('800X600'));
      expect(d, equals(Dimension(800, 600)));
      expect(d.hashCode, equals(Dimension(800, 600).hashCode));
      expect(d == Dimension(600, 800), isFalse);
      expect(d.compareTo(Dimension(100, 100)), greaterThan(0));
      expect(d.compareTo(Dimension(1000, 1000)), lessThan(0));
      expect(d.compareTo(Dimension(600, 800)), equals(0));
    });

    test('parse', () {
      expect(Dimension.parse(null), isNull);
      expect(Dimension.parse('  '), isNull);
      expect(Dimension.parse('800'), isNull);
      expect(Dimension.parse('800x600'), equals(Dimension(800, 600)));
      expect(Dimension.parse('1024 x 768'), equals(Dimension(1024, 768)));
      expect(Dimension.parse('640,480'), equals(Dimension(640, 480)));
      expect(Dimension.parse('640;480'), equals(Dimension(640, 480)));
      expect(Dimension.parse('640|480', '|'), equals(Dimension(640, 480)));
    });

    test('from', () {
      var d = Dimension(10, 20);
      expect(Dimension.from(null), isNull);
      expect(Dimension.from(d), same(d));
      expect(Dimension.from(Pair(10, 20)), equals(d));
      expect(Dimension.from(Pair('10', '20')), equals(d));
      expect(Dimension.from(Pair('a', 'b')), isNull);
      expect(Dimension.from('10x20'), equals(d));
      expect(Dimension.from([10, 20]), equals(d));
      expect(Dimension.from(['10', '20']), equals(d));
      expect(Dimension.from(['x', '20']), isNull);
      expect(Dimension.from(['10x20']), equals(d));
      expect(Dimension.from(123), isNull);
    });

    test('from with extra parsers', () {
      Dimension? parser(Object? v) => v is int ? Dimension(v, v) : null;
      Dimension.parsers.add(parser);
      try {
        expect(Dimension.from(7), equals(Dimension(7, 7)));
        expect(Dimension.from(true), isNull);
      } finally {
        Dimension.parsers.remove(parser);
      }
    });
  });

  group('Equality', () {
    test('isEquals / isEqualsDeep / isEqualsAsString', () {
      expect(isEquals(1, 1), isTrue);
      expect(isEquals([1], [1]), isFalse);
      expect(isEquals([1], [1], true), isTrue);
      expect(
        isEqualsDeep(
          [
            1,
            [2, 3],
          ],
          [
            1,
            [2, 3],
          ],
        ),
        isTrue,
      );
      expect(
        isEqualsDeep(
          {
            'a': [1],
          },
          {
            'a': [1],
          },
        ),
        isTrue,
      );
      expect(
        isEqualsDeep(
          {
            'a': [1],
          },
          {
            'a': [2],
          },
        ),
        isFalse,
      );
      expect(isEqualsDeep([1], {'a': 1}), isFalse);
      expect(isEqualsDeep({'a': 1}, [1]), isFalse);

      expect(isEqualsAsString(1, '1'), isTrue);
      expect(isEqualsAsString(1.5, '1.5'), isTrue);
      expect(isEqualsAsString(null, null), isTrue);
      expect(isEqualsAsString(null, 'null'), isFalse);
      expect(isEqualsAsString(1, 2), isFalse);
    });

    test('isEquivalentList / Iterator / Map', () {
      expect(isEquivalentList(null, null), isTrue);
      expect(isEquivalentList([1], null), isFalse);
      expect(isEquivalentList(null, [1]), isFalse);
      expect(isEquivalentList([1, 2], [1]), isFalse);
      expect(isEquivalentList([1, 2], [2, 1]), isFalse);
      expect(isEquivalentList([1, 2], [2, 1], sort: true), isTrue);
      expect(
        isEquivalentList(
          [
            [1],
          ],
          [
            [1],
          ],
          deep: true,
        ),
        isTrue,
      );

      expect(isEquivalentIterator({1, 2}, [1, 2]), isTrue);
      expect(isEquivalentIterator({1, 2}, [2, 1]), isFalse);
      expect(isEquivalentIterator({1}, [1, 2]), isFalse);
      expect(isEquivalentIterator(null, [1]), isFalse);
      expect(isEquivalentIterator([1], null), isFalse);
      expect(isEquivalentIterator(null, null), isTrue);

      expect(isEquivalentMap({'a': 1, 'b': 2}, {'b': 2, 'a': 1}), isTrue);
      expect(isEquivalentMap({'a': 1}, {'a': 2}), isFalse);
      expect(isEquivalentMap({'a': 1}, {'b': 1}), isFalse);
      expect(isEquivalentMap({'a': 1}, {'a': 1, 'b': 2}), isFalse);
      expect(isEquivalentMap(null, {}), isFalse);
      expect(isEquivalentMap({}, null), isFalse);
      expect(isEquivalentMap(null, null), isTrue);
    });

    test('isEqualsList / Set / Iterable / Map', () {
      var l = [1, 2];
      expect(isEqualsList(l, l), isTrue);
      expect(isEqualsList([1, 2], [1, 2]), isTrue);
      expect(isEqualsList([1, 2], [2, 1]), isFalse);
      expect(isEqualsList([1, 2], [1]), isFalse);
      expect(isEqualsList(null, [1]), isFalse);
      expect(isEqualsList([1], null), isFalse);

      expect(isEqualsSet({1, 2}, {1, 2}), isTrue);
      expect(isEqualsSet({1, 2}, {2, 1}), isFalse);
      expect(isEqualsSet({1, 2}, {1}), isFalse);
      expect(isEqualsSet(null, {1}), isFalse);
      expect(isEqualsSet({1}, null), isFalse);

      expect(isEqualsIterable([1, 2], {1, 2}), isTrue);
      expect(isEqualsIterable([1, 2], {2, 1}), isFalse);
      expect(isEqualsIterable([1, 2], [1]), isFalse);
      expect(isEqualsIterable(null, [1]), isFalse);
      expect(isEqualsIterable([1], null), isFalse);

      expect(isEqualsMap({'a': 1, 'b': 2}, {'a': 1, 'b': 2}), isTrue);
      expect(isEqualsMap({'a': 1, 'b': 2}, {'b': 2, 'a': 1}), isFalse);
      expect(isEqualsMap({'a': 1}, {'a': 2}), isFalse);
      expect(isEqualsMap({'a': 1}, {'a': 1, 'b': 2}), isFalse);
      expect(isEqualsMap(null, {'a': 1}), isFalse);
      expect(isEqualsMap({'a': 1}, null), isFalse);
    });

    test('isAllEquals', () {
      expect(isAllEquals(1, 1), isTrue);
      expect(isAllEquals([1, 1, 1], 1), isTrue);
      expect(isAllEquals([1, 2], 1), isFalse);
      expect(isAllEquals({'a': 1, 'b': 1}, 1), isTrue);
      expect(isAllEquals({'a': 1, 'b': 2}, 1), isFalse);
      expect(isAllEquals('x', 1), isFalse);
      expect(
        isAllEquals(
          [
            [1],
            [1],
          ],
          [1],
          true,
        ),
        isTrue,
      );

      expect(isAllEqualsInList(null, 1), isFalse);
      expect(isAllEqualsInList([], 1), isFalse);
      expect(isAllEqualsInMap(null, 1), isFalse);
      expect(isAllEqualsInMap({}, 1), isFalse);
    });

    test('isListValuesIdentical', () {
      var o1 = Object();
      var o2 = Object();
      var l = [o1];
      expect(isListValuesIdentical(null, []), isFalse);
      expect(isListValuesIdentical(l, l), isTrue);
      expect(isListValuesIdentical([], []), isTrue);
      expect(isListValuesIdentical([o1, o2], [o1, o2]), isTrue);
      expect(isListValuesIdentical([o1, o2], [o2, o1]), isFalse);
      expect(isListValuesIdentical([o1], [o1, o2]), isFalse);
    });
  });

  group('List helpers', () {
    test('matchers', () {
      expect(listMatchesAny([1, 2, 3], (e) => e == 2), isTrue);
      expect(listMatchesAny([1, 3], (e) => e == 2), isFalse);
      expect(listMatchesAny<int>(null, (e) => true), isFalse);

      expect(isListEntriesAllOfSameType([1, 2, 3]), isTrue);
      expect(isListEntriesAllOfSameType([1]), isTrue);
      expect(isListEntriesAllOfSameType([1, 'a']), isFalse);
      expect(isListEntriesAllOfSameType([]), isFalse);
      expect(isListEntriesAllOfType(['a', 'b'], String), isTrue);
      expect(isListEntriesAllOfType(['a', 1], String), isFalse);
      expect(isListEntriesAllOfType(null, String), isFalse);
    });

    test('addAllToList / joinLists / copies', () {
      var l = [1];
      addAllToList(l, null);
      addAllToList(l, 2);
      addAllToList(l, [3, 4]);
      expect(l, equals([1, 2, 3, 4]));

      expect(joinLists(null), isEmpty);
      expect(
        joinLists([1], [2], [3], [4], [5], [6], [7], [8], [9]),
        equals([1, 2, 3, 4, 5, 6, 7, 8, 9]),
      );
      expect(joinLists([1], null, [3]), equals([1, 3]));

      var list = [1, 2];
      var listCopy = copyList(list)!;
      expect(listCopy, equals(list));
      expect(identical(listCopy, list), isFalse);
      expect(copyList(null), isNull);
      expect(copyListString(['a']), equals(['a']));
      expect(copyListString(null), isNull);

      var map = {'a': 1};
      var mapCopy = copyMap(map)!;
      expect(mapCopy, equals(map));
      expect(identical(mapCopy, map), isFalse);
      expect(copyMap(null), isNull);
      expect(copyMapString({'a': 'b'}), equals({'a': 'b'}));
      expect(copyMapString(null), isNull);
    });

    test('isListOf*', () {
      expect(isListOfStrings(['a', 'b']), isTrue);
      expect(isListOfStrings(['a', 1]), isFalse);
      expect(isListOfStrings([]), isFalse);

      expect(isListOfString(<String>[]), isTrue);
      expect(isListOfString(<Object>['a']), isTrue);
      expect(isListOfString(<Object>['a', 1]), isFalse);
      expect(isListOfString(null), isFalse);
      expect(isListOfString([]), isFalse);

      expect(isListOfNum(<num>[]), isTrue);
      expect(isListOfNum(<Object>[1, 2.5]), isTrue);
      expect(isListOfNum(<Object>[1, 'a']), isFalse);
      expect(isListOfNum(null), isFalse);
      expect(isListOfNum([]), isFalse);

      expect(isListOfType<int>(<int>[]), isTrue);
      expect(isListOfType<int>(<Object>[1, 2]), isTrue);
      expect(isListOfType<int>(<Object>[1, 'a']), isFalse);
      expect(isListOfType<int>(null), isFalse);
      expect(isListOfType<int>([]), isFalse);

      expect(isListOfTypes<int, String>(<int>[]), isTrue);
      expect(isListOfTypes<int, String>(<String>[]), isTrue);
      expect(isListOfTypes<int, String>(<Object>[1, 'a']), isTrue);
      expect(isListOfTypes<int, String>(<Object>[1, true]), isFalse);
      expect(isListOfTypes<int, String>(null), isFalse);
      expect(isListOfTypes<int, String>([]), isFalse);

      expect(listContainsType<String>(<String>[]), isTrue);
      expect(listContainsType<String>(<Object>[1, 'a']), isTrue);
      expect(listContainsType<String>(<Object>[1, 2]), isFalse);
      expect(listContainsType<String>(null), isFalse);
      expect(listContainsType<String>([]), isFalse);

      expect(listContainsAll([1, 2, 3], [1, 3]), isTrue);
      expect(listContainsAll([1, 2, 3], [1, 4]), isFalse);
      expect(listContainsAll([1], []), isFalse);
      expect(listContainsAll(null, [1]), isFalse);

      expect(isListOfList(<List>[]), isTrue);
      expect(
        isListOfList(<Object>[
          [1],
          [2],
        ]),
        isTrue,
      );
      expect(
        isListOfList(<Object>[
          [1],
          2,
        ]),
        isFalse,
      );
      expect(isListOfList([]), isFalse);
      expect(isListOfList('x'), isFalse);

      expect(isListOfListOfList(<List<List>>[]), isTrue);
      expect(
        isListOfListOfList(<Object>[
          [
            [1],
          ],
        ]),
        isTrue,
      );
      expect(
        isListOfListOfList(<Object>[
          [1],
        ]),
        isFalse,
      );
      expect(isListOfListOfList([]), isFalse);
      expect(isListOfListOfList(null), isFalse);

      expect(isListOfMap(<Map>[]), isTrue);
      expect(isListOfMap(<Object>[{}, {}]), isTrue);
      expect(isListOfMap(<Object>[{}, 1]), isFalse);
      expect(isListOfMap([]), isFalse);
      expect(isListOfMap(1), isFalse);
    });

    test('isListValuesAllEquals / isListOfListValuesAllEquals', () {
      expect(isListValuesAllEquals([1, 1, 1]), isTrue);
      expect(isListValuesAllEquals([1, 2]), isFalse);
      expect(isListValuesAllEquals([2, 2], 2), isTrue);
      expect(isListValuesAllEquals([2, 2], 3), isFalse);
      expect(isListValuesAllEquals([]), isFalse);
      expect(isListValuesAllEquals('x'), isFalse);

      expect(
        isListOfListValuesAllEquals([
          [1, 'a'],
          [2, 'a'],
        ], eqValueIndex: 1),
        isTrue,
      );
      expect(
        isListOfListValuesAllEquals([
          [1, 'a'],
          [2, 'b'],
        ], eqValueIndex: 1),
        isFalse,
      );
      expect(
        isListOfListValuesAllEquals(
          [
            [1, 'a'],
            [2, 'a'],
          ],
          eqValueIndex: 1,
          eqValue: 'b',
        ),
        isFalse,
      );
      expect(isListOfListValuesAllEquals(null), isFalse);
      expect(isListOfListValuesAllEquals([]), isFalse);
    });

    test('parseListOf / parseListOfList', () {
      int parser(Object? e) => parseInt(e)!;
      expect(parseListOf(null, parser), isNull);
      expect(parseListOf(null, parser, [0]), equals([0]));
      expect(parseListOf(['1', 2], parser), equals([1, 2]));
      expect(parseListOf('3', parser), equals([3]));

      expect(parseListOfList(null, parser), isNull);
      expect(
        parseListOfList([
          ['1', 2],
          '3',
        ], parser),
        equals([
          [1, 2],
          [3],
        ]),
      );
      expect(
        parseListOfList('4', parser),
        equals([
          [4],
        ]),
      );
    });

    test('toNonNullList / toNonNullSet / toNonNullMap', () {
      expect(toNonNullList<int>(null), isEmpty);
      expect(toNonNullList<int>([1, null, 2]), equals([1, 2]));
      expect(
        toNonNullList<int>([1, null, 'a'], forceTypeCast: false),
        equals([1]),
      );
      expect(() => toNonNullList<int>([1, 'a']), throwsA(isA<TypeError>()));

      expect(toNonNullSet<int>(null), isEmpty);
      expect(toNonNullSet<int>({1, null, 2}), equals({1, 2}));
      expect(
        toNonNullSet<int>({1, null, 'a'}, forceTypeCast: false),
        equals({1}),
      );

      expect(toNonNullMap<String, int>(null), isEmpty);
      expect(
        toNonNullMap<String, int>({'a': 1, 'b': null, null: 2}),
        equals({'a': 1}),
      );
      expect(
        toNonNullMap<String, int>({
          'a': 1,
          'b': 'x',
          3: 4,
        }, forceTypeCast: false),
        equals({'a': 1}),
      );
    });

    test('removeEmptyEntries / resolveValue', () {
      var l = ['a', '', null, [], 'b'];
      expect(removeEmptyEntries(l), isTrue);
      expect(l, equals(['a', 'b']));
      expect(removeEmptyEntries([null, '']), isFalse);
      expect(removeEmptyEntries(null), isFalse);

      expect(resolveValue('a', 'def'), equals('a'));
      expect(resolveValue('', 'def'), equals('def'));
      expect(resolveValue(null, 'def'), equals('def'));
      expect(resolveValue(5, 0, (v) => v != 5), equals(0));
    });
  });

  group('Map helpers', () {
    test('ignore case', () {
      var map = <String, int>{'Foo': 1, 'bar': 2};
      expect(getEntryIgnoreCase(map, null), isNull);
      expect(getEntryIgnoreCase(map, 'Foo')!.value, equals(1));
      expect(getEntryIgnoreCase(map, 'FOO')!.key, equals('Foo'));
      expect(getEntryIgnoreCase(map, 'baz'), isNull);
      expect(getIgnoreCase(map, 'BAR'), equals(2));

      expect(putIgnoreCase(map, 'FOO', 10), equals(1));
      expect(map, equals({'Foo': 10, 'bar': 2}));
      expect(putIgnoreCase(map, 'baz', 3), isNull);
      expect(map['baz'], equals(3));
    });

    test('asMap / asListOfMap / asMapOfString / asListOfString', () {
      var m = {'a': 1};
      expect(asMap(null), isNull);
      expect(asMap(m), same(m));
      expect(asMap(['a', 1, 'b', 2]), equals({'a': 1, 'b': 2}));
      expect(() => asMap('x'), throwsStateError);

      expect(asListOfMap(null), isNull);
      var lm = <Map>[m];
      expect(asListOfMap(lm), same(lm));
      expect(
        asListOfMap([
          m,
          ['b', 2],
        ]),
        equals([
          {'a': 1},
          {'b': 2},
        ]),
      );
      expect(asListOfMap(m), equals([m]));
      expect(
        asListOfMap('a: 1; b = 2'),
        equals([
          {'a': '1', 'b': '2'},
        ]),
      );

      expect(asMapOfString(null), isNull);
      expect(asMapOfString({1: 2}), equals({'1': '2'}));
      expect(asListOfString(null), isNull);
      expect(asListOfString([1, null, 'a']), equals(['1', '', 'a']));
    });

    test('asTreeOfKeyString', () {
      expect(asTreeOfKeyString(null), isNull);
      expect(asTreeOfKeyString(1), equals(1));
      var tree = asTreeOfKeyString({
        1: {2: 'a'},
        'l': [
          {3: 'b'},
        ],
      });
      expect(
        tree,
        equals({
          '1': {'2': 'a'},
          'l': [
            {'3': 'b'},
          ],
        }),
      );
      expect(tree, isA<Map<String, dynamic>>());
    });

    test('sortMapEntries', () {
      var map = {'b': 2, 'c': 1, 'a': 3};
      expect(sortMapEntries(map).keys, equals(['a', 'b', 'c']));
      expect(sortMapEntries(map, null, true).keys, equals(['c', 'b', 'a']));
      expect(sortMapEntriesByKey(map).keys, equals(['a', 'b', 'c']));
      expect(sortMapEntriesByKey(map, true).keys, equals(['c', 'b', 'a']));
      expect(sortMapEntriesByValue(map).keys, equals(['c', 'b', 'a']));
      expect(sortMapEntriesByValue(map, true).keys, equals(['a', 'b', 'c']));
      expect(
        sortMapEntries(map, (x, y) => x.value.compareTo(y.value)).values,
        equals([1, 2, 3]),
      );
    });

    test('isMapOf*', () {
      expect(isMapOfString(<String, String>{}), isTrue);
      expect(isMapOfString(<Object, Object>{'a': 'b'}), isTrue);
      expect(isMapOfString(<Object, Object>{'a': 1}), isFalse);
      expect(isMapOfString(<Object, Object>{1: 'a'}), isFalse);
      expect(isMapOfString({}), isFalse);
      expect(isMapOfString(null), isFalse);

      expect(isMapOfStringKeys(<String, dynamic>{}), isTrue);
      expect(isMapOfStringKeys(<Object, Object>{'a': 1}), isTrue);
      expect(isMapOfStringKeys(<Object, Object>{1: 1}), isFalse);
      expect(isMapOfStringKeys({}), isFalse);
      expect(isMapOfStringKeys(null), isFalse);

      expect(isMapOfStringKeysAndListValues(<String, List>{}), isTrue);
      expect(
        isMapOfStringKeysAndListValues(<Object, Object>{
          'a': [1],
        }),
        isTrue,
      );
      expect(isMapOfStringKeysAndListValues(<Object, Object>{'a': 1}), isFalse);
      expect(isMapOfStringKeysAndListValues({}), isFalse);
      expect(isMapOfStringKeysAndListValues(null), isFalse);

      expect(isMapOfStringKeysAndNumValues(<String, num>{}), isTrue);
      expect(isMapOfStringKeysAndNumValues(<Object, Object>{'a': 1.5}), isTrue);
      expect(
        isMapOfStringKeysAndNumValues(<Object, Object>{'a': 'x'}),
        isFalse,
      );
      expect(isMapOfStringKeysAndNumValues({}), isFalse);
      expect(isMapOfStringKeysAndNumValues(null), isFalse);
    });

    test('findKeyEntry / findKeyValue / findKeyName / findKeyPathValue', () {
      var map = {'Name': 'x', 'age': 10};
      expect(findKeyEntry(null, ['a']), isNull);
      expect(findKeyEntry(map, null), isNull);
      expect(findKeyEntry(map, ['name']), isNull);
      expect(findKeyEntry(map, ['name'], true)!.key, equals('Name'));
      expect(findKeyEntry(map, ['age'], true)!.value, equals(10));
      expect(findKeyEntry(map, ['x', 'age'])!.value, equals(10));
      expect(findKeyEntry(map, ['x'], true), isNull);
      expect(findKeyValue(map, ['zz', 'Name']), equals('x'));
      expect(findKeyName(map, ['NAME'], true), equals('Name'));

      var tree = {
        'a': {
          'B': [
            {'c': 1},
            {'c': 2},
          ],
        },
      };
      expect(findKeyPathValue(tree, 'a/b/1/c'), equals(2));
      expect(findKeyPathValue(tree, 'a.b.0.c', keyDelimiter: '.'), equals(1));
      expect(findKeyPathValue(tree, 'a/b/x'), isNull);
      expect(findKeyPathValue(tree, 'a/z'), isNull);
      expect(findKeyPathValue(tree, 'z'), isNull);
      expect(findKeyPathValue(tree, 'a/b/0/c/d'), isNull);
      expect(findKeyPathValue(tree, ''), isNull);
      expect(findKeyPathValue(null, 'a'), isNull);
      expect(
        findKeyPathValue(tree, 'a/b/1/c', isValidValue: (v) => v == 2),
        equals(2),
      );
      expect(
        findKeyPathValue(tree, 'a/b/1/c', isValidValue: (v) => v == 3),
        isNull,
      );
    });

    test('getSetEntryInstance', () {
      var p = Pair(1, 2);
      var set = {p};
      expect(getSetEntryInstance(set, Pair(1, 2)), same(p));
      expect(getSetEntryInstance(set, Pair(2, 1)), isNull);
      expect(getSetEntryInstance<Pair>(null, p), isNull);
    });
  });

  group('Strings and inline parsing', () {
    test('isEmptyString / isNotEmptyString / ensureNotEmptyString', () {
      expect(isEmptyString(null), isTrue);
      expect(isEmptyString(''), isTrue);
      expect(isEmptyString(' '), isFalse);
      expect(isEmptyString(' ', trim: true), isTrue);
      expect(isNotEmptyString('a'), isTrue);
      expect(isNotEmptyString(' ', trim: true), isFalse);

      expect(ensureNotEmptyString('a'), equals('a'));
      expect(ensureNotEmptyString('', def: 'd'), equals('d'));
      expect(ensureNotEmptyString(' ', trim: true, def: 'd'), equals('d'));
      expect(ensureNotEmptyString(null), isNull);
    });

    test('isEmptyObject with trim', () {
      expect(isEmptyObject([null], trim: true), isTrue);
      expect(isEmptyObject([null]), isFalse);
      expect(isEmptyObject({'a': null}, trim: true), isTrue);
      expect(isEmptyObject(<Object?>{null}, trim: true), isTrue);
      expect(isEmptyObject([null].map((e) => e), trim: true), isTrue);
      expect(isEmptyObject(StringBuffer(' '), trim: true), isTrue);
      expect(isEmptyObject(StringBuffer(' ')), isFalse);
      expect(isNotEmptyObject(1), isTrue);
    });

    test('parseFromInlineMap / parseFromInlineList / properties', () {
      expect(parseFromInlineMap<String, String>(null, ';', ':'), isNull);
      expect(
        parseFromInlineMap<String, String>(' ', ';', ':', null, null, {}),
        equals({}),
      );
      expect(
        parseFromInlineMap<String, int>(
          'a:1;b:2;c',
          ';',
          ':',
          null,
          (v) => v.isEmpty ? 0 : int.parse(v),
        ),
        equals({'a': 1, 'b': 2, 'c': 0}),
      );

      expect(parseFromInlineList<String>(null, ','), isNull);
      expect(parseFromInlineList<String>(' ', ',', null, ['d']), equals(['d']));
      expect(parseFromInlineList<String>('a,b', ','), equals(['a', 'b']));
      expect(parseFromInlineList<int>('1|2', '|', int.parse), equals([1, 2]));

      expect(
        parseFromInlineProperties('color: red; width = 10px'),
        equals({'color': 'red', 'width': '10px'}),
      );
    });

    test(
      'parseString / parseStringFromInlineMap / parseStringFromInlineList',
      () {
        expect(parseString(null), isNull);
        expect(parseString(null, 'd'), equals('d'));
        expect(parseString(' a '), equals(' a '));
        expect(parseString(StringBuffer(' a ')), equals('a'));
        expect(parseString(StringBuffer(' '), 'd'), equals('d'));

        expect(parseStringFromInlineMap(null, ';', ':'), isNull);
        expect(parseStringFromInlineMap({1: 2}, ';', ':'), equals({'1': '2'}));
        expect(
          parseStringFromInlineMap('a:1;b:2', ';', ':'),
          equals({'a': '1', 'b': '2'}),
        );

        expect(parseStringFromInlineList(null), isNull);
        expect(parseStringFromInlineList([1, null]), equals(['1', '']));
        expect(parseStringFromInlineList('a , b,c'), equals(['a', 'b', 'c']));
        expect(parseStringFromInlineList('a|b', '|'), equals(['a', 'b']));
      },
    );

    test('parseComparable', () {
      expect(parseComparable(null), isNull);
      expect(parseComparable(1), equals(1));
      expect(parseComparable('a'), equals('a'));
      expect(parseComparable(StringBuffer('b')), equals('b'));
    });

    test('parseMapEntryOfStrings', () {
      MapEntry<String, String>? p(Object? e, [Pattern? d]) =>
          parseMapEntryOfStrings(e, d);

      String s(MapEntry<String, String>? e) => '${e?.key}=${e?.value}';

      expect(parseMapEntryOfStrings(null), isNull);
      expect(s(p({'a': 1})), equals('a=1'));
      expect(p({}), isNull);
      expect(p({null: 1}), isNull);
      expect(p([]), isNull);
      expect(s(p(['a;b'])), equals('a=b'));
      expect(s(p(['a', 'b'])), equals('a=b'));
      expect(s(p(['a', 'b', 'c'])), equals('a=b,c'));
      expect(s(p('a:b')), equals('a=b'));
      expect(s(p('a,b')), equals('a=b'));
      expect(s(p('a|b', '|')), equals('a=b'));
      expect(p('ab'), isNull);
    });
  });

  group('Deep operations', () {
    test('deepHashCode', () {
      expect(deepHashCode(null), equals(0));
      expect(deepHashCodeList(null), equals(0));
      expect(deepHashCodeMap(null), equals(0));
      expect(
        deepHashCode([
          1,
          [2],
        ]),
        equals(
          deepHashCode([
            1,
            [2],
          ]),
        ),
      );
      expect(
        deepHashCode({
          'a': [1],
        }),
        equals(
          deepHashCode({
            'a': [1],
          }),
        ),
      );
      expect(deepHashCode('x'), equals('x'.hashCode));
    });

    test('deepCopy', () {
      var o = <dynamic, dynamic>{
        'a': [
          1,
          2,
          <dynamic, dynamic>{'b': true},
        ],
        'c': 'x',
        'd': 1.5,
      };
      var copy = deepCopy(o)!;
      expect(copy, equals(o));
      expect(identical(copy, o), isFalse);
      expect(identical(copy['a'], o['a']), isFalse);
      expect(identical(copy['a'][2], o['a'][2]), isFalse);

      // Typed lists keep their type:
      var ints = <int>[1, 2];
      var intsCopy = deepCopy(ints)!;
      expect(intsCopy, isA<List<int>>());
      expect(intsCopy, equals(ints));
      expect(identical(intsCopy, ints), isFalse);

      var nested = <List<int>>[
        [1],
        [2],
      ];
      var nestedCopy = deepCopy(nested)!;
      expect(nestedCopy, isA<List<List<int>>>());
      expect(nestedCopy, equals(nested));
      expect(identical(nestedCopy[0], nested[0]), isFalse);

      expect(deepCopy(null), isNull);
      expect(deepCopyList<int>(null), isNull);
      expect(deepCopyList<int>([]), isEmpty);
      expect(deepCopyMap<String, int>(null), isNull);
      expect(deepCopyMap<String, int>({}), isEmpty);

      var obj = Pair(1, 2);
      expect(deepCopy(obj), same(obj));
      expect(
        deepCopy(obj, copier: <T>(T? o) => (o is Pair ? o.swapAB() : o) as T?),
        equals(Pair(2, 1)),
      );
    });

    test('deepCopy of typed maps', () {
      // Regression: maps were rebuilt as `Map<dynamic, dynamic>` and then
      // cast to the original type, so typed maps threw a TypeError.
      var ints = <String, int>{'a': 1, 'b': 2};
      var intsCopy = deepCopy(ints)!;
      expect(intsCopy, isA<Map<String, int>>());
      expect(intsCopy, equals(ints));
      expect(identical(intsCopy, ints), isFalse);

      var empty = deepCopy(<String, Object>{})!;
      expect(empty, isA<Map<String, Object>>());
      expect(empty, isEmpty);

      var objs = <String, Object>{
        'l': <int>[1, 2],
        'm': <String, int>{'x': 1},
        'd': <dynamic, dynamic>{'k': 'v'},
      };
      var objsCopy = deepCopy(objs)!;
      expect(objsCopy, isA<Map<String, Object>>());
      expect(objsCopy, equals(objs));
      expect(objsCopy['l'], isA<List<int>>());
      expect(objsCopy['m'], isA<Map<String, int>>());
      expect(identical(objsCopy['l'], objs['l']), isFalse);
      expect(identical(objsCopy['m'], objs['m']), isFalse);
      expect(identical(objsCopy['d'], objs['d']), isFalse);

      // The copy is mutable with its own type:
      (objsCopy['m'] as Map<String, int>)['y'] = 2;
      expect(objs['m'], equals({'x': 1}));

      // Typed maps nested in typed collections:
      var listOfMaps = <Map<String, int>>[
        {'a': 1},
      ];
      var listOfMapsCopy = deepCopy(listOfMaps)!;
      expect(listOfMapsCopy, isA<List<Map<String, int>>>());
      expect(listOfMapsCopy[0], isA<Map<String, int>>());
      expect(identical(listOfMapsCopy[0], listOfMaps[0]), isFalse);

      var mapOfMaps = <String, Map<String, Object?>>{
        'a': {'b': null},
      };
      var mapOfMapsCopy = deepCopy(mapOfMaps)!;
      expect(mapOfMapsCopy, isA<Map<String, Map<String, Object?>>>());
      expect(mapOfMapsCopy, equals(mapOfMaps));
      expect(identical(mapOfMapsCopy['a'], mapOfMaps['a']), isFalse);

      var intKeys = <int, String?>{1: 'a', 2: null};
      expect(deepCopy(intKeys), isA<Map<int, String?>>());
      expect(deepCopy(intKeys), equals(intKeys));

      var mapType = deepCopyMap(<String, double>{'a': 1.5})!;
      expect(mapType, isA<Map<String, double>>());

      // `deepCopy` with an explicit wider type:
      var wide = deepCopy<Map>(<String, int>{'a': 1})!;
      expect(wide, equals({'a': 1}));
    });

    test('deepCopy of maps with types it cannot reproduce', () {
      // A typed map whose key type can't be reproduced: copied with a wider
      // type when that is accepted...
      var pairs = <Pair<int>, int>{Pair(1, 2): 3};
      var pairsCopy = deepCopy<Map<Object, int>>(pairs)!;
      expect(pairsCopy, equals(pairs));
      expect(identical(pairsCopy, pairs), isFalse);

      // ... otherwise the original instance is kept (it used to throw):
      expect(deepCopy(pairs), same(pairs));
      var listOfPairs = <Map<Pair<int>, int>>[pairs];
      var listOfPairsCopy = deepCopy(listOfPairs)!;
      expect(listOfPairsCopy, isA<List<Map<Pair<int>, int>>>());
      expect(listOfPairsCopy[0], same(pairs));

      // In an untyped collection the wider copy is stored:
      var untypedList = <dynamic>[pairs];
      var untypedListCopy = deepCopy(untypedList)!;
      expect(untypedListCopy[0], equals(pairs));
      expect(identical(untypedListCopy[0], pairs), isFalse);

      var mapOfPairs = <String, Map<Pair<int>, int>>{'p': pairs};
      var mapOfPairsCopy = deepCopy<Map<String, Object>>(mapOfPairs)!;
      expect(mapOfPairsCopy['p'], equals(pairs));
      expect(identical(mapOfPairsCopy['p'], pairs), isFalse);
      // Not as a `Map<String, Map<Pair<int>, int>>`:
      expect(deepCopy(mapOfPairs), same(mapOfPairs));
    });

    test('deepCopy of a decoded JSON', () {
      // Regression guard: a decoded JSON map isn't a `LinkedHashMap` on every
      // platform (dart2js uses a `_JsonMap`); its nested maps must still be
      // copied.
      var json = parseJSON('{"a": [{"b": 1, "c": null}], "d": {"e": "f"}}');
      dynamic copy = deepCopy(json);
      expect(copy, equals(json));
      expect(identical(copy['a'][0], json['a'][0]), isFalse);
      expect(identical(copy['d'], json['d']), isFalse);
      (copy['a'][0] as Map).remove('c');
      expect((json['a'][0] as Map).containsKey('c'), isTrue);
    });

    test('deepCopy of typed-data lists', () {
      // Regression: copied as a `List<int>`, which can't be returned as a
      // `Uint8List` (TypeError).
      var bytes = Uint8List.fromList([1, 2, 3]);
      var bytesCopy = deepCopy(bytes)!;
      expect(bytesCopy, isA<Uint8List>());
      expect(bytesCopy, equals(bytes));
      expect(identical(bytesCopy, bytes), isFalse);

      var nested = <Uint8List>[bytes];
      var nestedCopy = deepCopy(nested)!;
      expect(nestedCopy[0], isA<Uint8List>());
      expect(identical(nestedCopy[0], bytes), isFalse);
    });

    test('deepCopyList with null elements', () {
      // Regression: `deepCopyList` used `deepCopy(e)!`, so a null element
      // threw.
      expect(deepCopyList<int?>([1, null]), equals([1, null]));
    });

    test('deepReplaceValues', () {
      bool isInt(Object? c, Object? k, Object? v) => v is int;
      Object? double(Object? c, Object? k, Object? v) => (v as int) * 2;

      expect(deepReplaceValues(null, isInt, double), isNull);
      expect(deepReplaceValues(2, isInt, double), equals(4));
      expect(deepReplaceValues('a', isInt, double), equals('a'));

      var o = {
        'a': [
          1,
          'x',
          {2},
        ],
        'b': {'c': 3},
      };
      expect(
        deepReplaceValues(o, isInt, double),
        equals({
          'a': [
            2,
            'x',
            {4},
          ],
          'b': {'c': 6},
        }),
      );

      var set = {1, 'y'};
      deepReplaceValues(set, isInt, double);
      expect(set, equals({2, 'y'}));
    });

    test('deepCatchesValues', () {
      bool isInt(Object? c, Object? k, Object? v) => v is int;

      expect(deepCatchesValues(null, isInt), isEmpty);
      expect(deepCatchesValues(1, isInt), equals([1]));
      expect(
        deepCatchesValues({
          'a': [
            1,
            'x',
            {2},
          ],
          'b': {'c': 3},
        }, isInt),
        equals([1, 2, 3]),
      );
      expect(deepCatchesListValues(null, isInt), isEmpty);
      expect(deepCatchesMapValues(null, isInt), isEmpty);
      expect(deepCatchesSetValues(null, isInt), isEmpty);
    });
  });

  group('MapDelegate', () {
    test('delegates all operations', () {
      var map = <String, int>{'a': 1};
      var d = MapDelegate(map);

      d['b'] = 2;
      expect(map['b'], equals(2));
      expect(d['b'], equals(2));

      d.addAll({'c': 3});
      d.addEntries([MapEntry('d', 4)]);
      expect(d.length, equals(4));
      expect(d.isNotEmpty, isTrue);
      expect(d.isEmpty, isFalse);
      expect(d.keys, equals(['a', 'b', 'c', 'd']));
      expect(d.values, equals([1, 2, 3, 4]));
      expect(d.entries.map((e) => e.key), equals(['a', 'b', 'c', 'd']));
      expect(d.containsKey('a'), isTrue);
      expect(d.containsValue(4), isTrue);
      expect(d.containsValue(40), isFalse);

      var visited = <String>[];
      d.forEach((k, v) => visited.add(k));
      expect(visited, equals(['a', 'b', 'c', 'd']));

      expect(
        d.map((k, v) => MapEntry(v, k)),
        equals({1: 'a', 2: 'b', 3: 'c', 4: 'd'}),
      );
      expect(d.cast<String, num>()['a'], equals(1));

      expect(d.putIfAbsent('e', () => 5), equals(5));
      expect(d.putIfAbsent('e', () => 50), equals(5));
      expect(d.update('e', (v) => v + 1), equals(6));
      expect(d.update('f', (v) => v, ifAbsent: () => 7), equals(7));
      d.updateAll((k, v) => v * 10);
      expect(map['a'], equals(10));

      expect(d.remove('f'), equals(70));
      d.removeWhere((k, v) => v > 30);
      expect(d.keys, equals(['a', 'b', 'c']));

      d.clear();
      expect(map, isEmpty);
    });
  });

  group('MapProperties', () {
    test('parseValue', () {
      expect(MapProperties.parseValue('10'), equals(10));
      expect(MapProperties.parseValue('1.5'), equals(1.5));
      expect(MapProperties.parseValue('true'), equals(true));
      expect(MapProperties.parseValue('1,2,3'), equals([1, 2, 3]));
      expect(MapProperties.parseValue('1.5,2.5'), equals([1.5, 2.5]));
      expect(MapProperties.parseValue('true,false'), equals([true, false]));
      expect(MapProperties.parseValue('abc'), equals('abc'));
      expect(MapProperties.parseStringProperties(null), isEmpty);
      expect(
        MapProperties.parseStringProperties({'a': '1', 'b': 'x'}),
        equals({'a': 1, 'b': 'x'}),
      );
    });

    test('getters', () {
      var props = MapProperties.fromProperties({
        'Name': ' Foo ',
        'int': '10',
        'double': '1.5',
        'num': '2',
        'bool': 'true',
        'date': '2024-07-15',
        'strings': 'a,b',
        'ints': '1,2',
        'doubles': '1.5,2.5',
        'nums': '1,2.5',
        'bools': 'true,false',
        'dates': '2024-07-15,2024-08-01',
      });

      var d1 = DateTime(2024, 7, 15);
      var d2 = DateTime(2024, 8, 1);

      expect(props.getProperty('name'), equals(' Foo '));
      expect(props.getProperty('xx', 'def'), equals('def'));
      expect(props.findProperty(['xx', 'NAME']), equals(' Foo '));
      expect(props.findProperty(['xx'], 'def'), equals('def'));
      expect(props.getPropertyAs('int', (v) => '<$v>'), equals('<10>'));
      expect(props.findPropertyAs(['xx'], (v) => '<$v>', 'd'), equals('d'));

      expect(props.getPropertyAsString('name'), equals(' Foo '));
      expect(props.getPropertyAsStringTrim('name'), equals('Foo'));
      expect(props.getPropertyAsStringTrimLC('name'), equals('foo'));
      expect(props.getPropertyAsStringTrimUC('name'), equals('FOO'));
      expect(props.findPropertyAsString(['name']), equals(' Foo '));
      expect(props.findPropertyAsStringTrim(['name']), equals('Foo'));
      expect(props.findPropertyAsStringTrimLC(['name']), equals('foo'));
      expect(props.findPropertyAsStringTrimUC(['name']), equals('FOO'));

      expect(props.getPropertyAsInt('int'), equals(10));
      expect(props.getPropertyAsDouble('double'), equals(1.5));
      expect(props.getPropertyAsNum('num'), equals(2));
      expect(props.getPropertyAsBool('bool'), isTrue);
      expect(props.getPropertyAsDateTime('date'), equals(d1));
      expect(props.findPropertyAsInt(['int']), equals(10));
      expect(props.findPropertyAsDouble(['double']), equals(1.5));
      expect(props.findPropertyAsNum(['num']), equals(2));
      expect(props.findPropertyAsBool(['bool']), isTrue);
      expect(props.findPropertyAsDateTime(['date']), equals(d1));

      expect(props.getPropertyAsStringList('strings'), equals(['a', 'b']));
      expect(props.getPropertyAsIntList('ints'), equals([1, 2]));
      expect(props.getPropertyAsDoubleList('doubles'), equals([1.5, 2.5]));
      expect(props.getPropertyAsNumList('nums'), equals([1, 2.5]));
      expect(props.getPropertyAsBoolList('bools'), equals([true, false]));
      expect(props.getPropertyAsDateTimeList('dates'), equals([d1, d2]));
      expect(props.findPropertyAsStringList(['strings']), equals(['a', 'b']));
    });

    test('parse*FromInlineList', () {
      expect(parseIntsFromInlineList([1, '2', null]), equals([1, 2]));
      expect(parseNumsFromInlineList(null), isNull);
      expect(parseNumsFromInlineList(3), equals([3]));
      expect(parseNumsFromInlineList([1, '2.5', null]), equals([1, 2.5]));
      expect(parseNumsFromInlineList('1 ; 2.5', ';'), equals([1, 2.5]));
      expect(parseDoublesFromInlineList(null, ',', [0.0]), equals([0.0]));
      expect(parseDoublesFromInlineList(1.5), equals([1.5]));
      expect(parseDoublesFromInlineList(['1.5', 2, null]), equals([1.5, 2.0]));
      expect(parseDoublesFromInlineList('1.5,2.5'), equals([1.5, 2.5]));
      expect(parseBoolsFromInlineList(null, ','), isNull);
      expect(parseBoolsFromInlineList(true, ','), equals([true]));
      expect(
        parseBoolsFromInlineList(['true', false, null], ','),
        equals([true, false]),
      );
      expect(
        parseBoolsFromInlineList('true|false', '|'),
        equals([true, false]),
      );
    });

    test('constructors', () {
      expect(MapProperties(), isEmpty);
      expect(
        MapProperties.fromMap({1: 2, 'a': true}),
        equals({'1': '2', 'a': 'true'}),
      );
    });
  });
}
