import 'package:swiss_knife/swiss_knife.dart';
import 'package:test/test.dart';

class _Node {
  final String name;
  _Node? parent;
  final List<_Node> children = [];

  _Node(this.name);

  _Node add(_Node child) {
    child.parent = this;
    children.add(child);
    return child;
  }

  void detach() {
    parent?.children.remove(this);
    parent = null;
  }

  @override
  String toString() => name;
}

bool _isChild(_Node parent, _Node child, bool deep) {
  if (!deep) return identical(child.parent, parent);
  var cursor = child.parent;
  while (cursor != null) {
    if (identical(cursor, parent)) return true;
    cursor = cursor.parent;
  }
  return false;
}

TreeReferenceMap<_Node, String> _newTreeMap(
  _Node root, {
  bool autoPurge = false,
  int autoPurgeThreshold = TreeReferenceMap.defaultAutoPurgeThreshold,
  bool keepPurgedKeys = false,
  Duration? purgedEntriesTimeout,
  int? maxPurgedEntries,
  void Function(Map<_Node, String> purgedEntries)? onPurgedEntries,
}) => TreeReferenceMap<_Node, String>(
  root,
  autoPurge: autoPurge,
  autoPurgeThreshold: autoPurgeThreshold,
  keepPurgedKeys: keepPurgedKeys,
  purgedEntriesTimeout: purgedEntriesTimeout,
  maxPurgedEntries: maxPurgedEntries,
  parentGetter: (n) => n.parent,
  childrenGetter: (n) => n.children,
  childChecker: _isChild,
  onPurgedEntries: onPurgedEntries,
);

class _Counter {
  final int id;
  bool valid = true;

  _Counter(this.id);
}

void main() {
  group('Dimension (extra)', () {
    test('subtract', () {
      var d1 = Dimension(10, 20);
      var d2 = Dimension(4, 15);
      // dw = 6, dh = 5
      // Regression: the doc says `maximumDifferences = true` returns the
      // maximum difference, but the implementation swapped min/max
      // (true -> min, false -> max).
      expect(d1.subtract(d2), equals(5));
      expect(d1.subtract(d2, true), equals(6));
      expect(d1.subtract(d2, false), equals(5));

      // Negative differences:
      expect(d2.subtract(d1), equals(-6));
      expect(d2.subtract(d1, true), equals(-5));
    });
  });

  group('List helpers (extra)', () {
    test('toFlatListOfStrings with a non-String/non-Iterable value', () {
      expect(toFlatListOfStrings(123), equals(['123']));
      expect(toFlatListOfStrings(true), equals(['true']));
      expect(toFlatListOfStrings(null), equals(<String>[]));
    });

    test('isListOfListValuesAllEquals', () {
      expect(isListOfListValuesAllEquals(null), isFalse);
      expect(isListOfListValuesAllEquals([]), isFalse);

      expect(
        isListOfListValuesAllEquals([
          [1, 2],
          [1, 3],
        ], eqValueIndex: 0),
        isTrue,
      );
      expect(
        isListOfListValuesAllEquals([
          [1, 2],
          [1, 3],
        ], eqValueIndex: 1),
        isFalse,
      );
      expect(
        isListOfListValuesAllEquals(
          [
            [1, 2],
            [1, 3],
          ],
          eqValue: 2,
          eqValueIndex: 1,
        ),
        isFalse,
      );
      expect(
        isListOfListValuesAllEquals(
          [
            [5, 2],
            [5, 2],
          ],
          eqValue: 2,
          eqValueIndex: 1,
        ),
        isTrue,
      );

      // Regression: without `eqValueIndex` the default `eqValue` was the first
      // *element* of the first non-empty sub-list, but each whole sub-list was
      // compared against it, so the result was always false.
      expect(
        isListOfListValuesAllEquals([
          [1],
          [1],
        ]),
        isTrue,
      );
      expect(
        isListOfListValuesAllEquals([
          [],
          [7, 7],
          [7],
        ]),
        isTrue,
      );
      expect(
        isListOfListValuesAllEquals([
          [1, 1],
          [1, 2],
        ]),
        isFalse,
      );
      expect(
        isListOfListValuesAllEquals([
          [3],
          [3],
        ], eqValue: 3),
        isTrue,
      );
      expect(
        isListOfListValuesAllEquals([
          [3],
          [3],
        ], eqValue: 4),
        isFalse,
      );
      expect(
        isListOfListValuesAllEquals([
          [null],
          [null],
        ]),
        isTrue,
      );
      // No values at all (it threw a StateError):
      expect(isListOfListValuesAllEquals([[], []]), isFalse);
      expect(isListOfListValuesAllEquals([[], []], eqValue: 1), isFalse);
    });

    test('isEmptyObject with Iterable/Set', () {
      expect(isEmptyObject(<int>{}), isTrue);
      expect(isEmptyObject(<int?>{null}, trim: true), isTrue);
      expect(isEmptyObject(<int?>{null}), isFalse);
      expect(isEmptyObject(<int>{1}, trim: true), isFalse);
      expect(isEmptyObject([1].map((e) => e)), isFalse);
      expect(isEmptyObject(<int?>[null].map((e) => e), trim: true), isTrue);
    });
  });

  group('Parsing (extra)', () {
    test('parseMapEntryOfStrings from a String', () {
      expect(
        parseMapEntryOfStrings('a:b')?.toString(),
        equals(MapEntry('a', 'b').toString()),
      );
      var def = MapEntry('d', 'e');
      expect(parseMapEntryOfStrings('abc', null, def), same(def));
      expect(parseMapEntryOfStrings('abc'), isNull);
    });
  });

  group('Deep operations (extra)', () {
    test('deepCopyList empty', () {
      var l = <int>[];
      var c = deepCopyList(l)!;
      expect(c, isEmpty);
      expect(identical(c, l), isFalse);
      expect(deepCopyList<int>(null), isNull);

      var nested = <List<int>>[
        [1, 2],
        [3],
      ];
      var nestedCopy = deepCopyList(nested)!;
      expect(nestedCopy, equals(nested));
      expect(identical(nestedCopy[0], nested[0]), isFalse);
      nestedCopy[0].add(9);
      expect(nested[0], equals([1, 2]));

      var copied = deepCopyList<Object>([
        _Counter(1),
        'x',
      ], copier: <T>(T? o) => o is _Counter ? _Counter(o.id + 10) as T : o)!;
      expect((copied[0] as _Counter).id, equals(11));
      expect(copied[1], equals('x'));
    });

    test('deepCatchesValues in a Set', () {
      var set = <Object>{
        [1, 2],
        'x',
        {'k': 3},
      };
      var result = deepCatchesValues(set, (c, k, v) => v is int);
      expect(result, equals([1, 2, 3]));

      expect(deepCatchesSetValues(null, (c, k, v) => true), isEmpty);
      expect(
        deepCatchesSetValues({1, 'a', 2}, (c, k, v) => v is int),
        equals([1, 2]),
      );
    });
  });

  group('MapProperties (extra)', () {
    test('parseValue num list', () {
      expect(MapProperties.parseValue('1,2.5'), equals([1, 2.5]));
      expect(MapProperties.parseValue(null), isNull);
    });

    test('find*List and string maps', () {
      var props = MapProperties.fromProperties({
        'ints': '1,2',
        'doubles': '1.5,2.5',
        'nums': '1,2.5',
        'bools': 'true,false',
        'dates': '2024-07-15,2024-08-01',
        'map': 'a:1;b:2',
      });

      var d1 = DateTime(2024, 7, 15);
      var d2 = DateTime(2024, 8, 1);

      expect(props.findPropertyAsIntList(['x', 'INTS']), equals([1, 2]));
      expect(props.findPropertyAsIntList(['x'], [9]), equals([9]));
      expect(props.findPropertyAsDoubleList(['doubles']), equals([1.5, 2.5]));
      expect(props.findPropertyAsDoubleList(['x']), isNull);
      expect(props.findPropertyAsNumList(['nums']), equals([1, 2.5]));
      expect(props.findPropertyAsBoolList(['bools']), equals([true, false]));
      expect(props.findPropertyAsDateTimeList(['dates']), equals([d1, d2]));
      expect(props.findPropertyAsDateTimeList(['x'], [d2]), equals([d2]));

      expect(props.getPropertyAsStringMap('map'), equals({'a': '1', 'b': '2'}));
      expect(props.getPropertyAsStringMap('x', {'z': 'z'}), equals({'z': 'z'}));
      expect(
        props.findPropertyAsStringMap(['x', 'MAP']),
        equals({'a': '1', 'b': '2'}),
      );
      expect(props.findPropertyAsStringMap(['x']), isNull);
    });

    test('toProperties, toStringProperties, put, toString', () {
      var props = MapProperties.fromProperties({'a': 1, 'b': true});

      var asProps = props.toProperties();
      expect(asProps, equals({'a': 1, 'b': true}));
      asProps['c'] = 3;
      expect(props.containsKey('c'), isFalse);

      expect(props.toStringProperties(), equals({'a': '1', 'b': 'true'}));

      expect(props.put('a', [1, 2]), equals(1));
      expect(props['a'], equals('1,2'));
      expect(props.put('n', null), isNull);
      expect(props.containsKey('n'), isTrue);
      expect(props['n'], isNull);

      var p2 = MapProperties.fromProperties({
        'i': 10,
        'b': false,
        's': 'x',
        'z': null,
      });
      expect(
        p2.toString(),
        equals('{ \n"i": 10 , "b": false , "s": "x" , "z": null }'),
      );
      expect(MapProperties().toString(), equals('{ \n }'));
    });

    test('toStringValue', () {
      expect(MapProperties.toStringValue(null), isNull);
      expect(MapProperties.toStringValue(null, 'def'), equals('def'));
      expect(MapProperties.toStringValue('s'), equals('s'));
      expect(MapProperties.toStringValue([1, 'a', 3]), equals('1,a,3'));
      expect(
        MapProperties.toStringValue({
          'a': 1,
          'b': [2, 3],
        }),
        equals('a:1;b:2,3'),
      );
      expect(MapProperties.toStringValue({1, 2}), equals('1,2'));
      expect(MapProperties.toStringValue(Pair('a', 'b')), equals('a,b'));
      expect(MapProperties.toStringValue(MapEntry('k', 7)), equals('k,7'));
      expect(MapProperties.toStringValue(42), equals('42'));
      expect(MapProperties.toStringValue(true), equals('true'));
    });
  });

  group('Iterable aggregation', () {
    test('groupIterableBy', () {
      expect(
        groupIterableBy<String, int, int>(
          [],
          (e) => MapEntry('k', e),
          (k, a, b) => a + b,
        ),
        isEmpty,
      );

      var groups = groupIterableBy<String, int, int>(
        [1, 2, 3, 4, 5],
        (e) => MapEntry(e.isEven ? 'even' : 'odd', e),
        (k, a, b) => a + b,
      );
      expect(groups, equals({'odd': 9, 'even': 6}));

      var keysSeen = <String>[];
      var g2 = groupIterableBy<String, String, String>(
        ['a1', 'b1', 'a2', 'a3'],
        (e) => MapEntry(e.substring(0, 1), e),
        (k, a, b) {
          keysSeen.add(k);
          return '$a|$b';
        },
      );
      expect(g2, equals({'a': 'a1|a2|a3', 'b': 'b1'}));
      expect(keysSeen, equals(['a', 'a']));
    });

    test('mergeIterable', () {
      expect(mergeIterable<int, int>([], (t, v) => t! + v, 7), equals(7));
      expect(mergeIterable<int, int>([], (t, v) => t! + v), isNull);
      expect(
        mergeIterable<String, String>([
          'a',
          'b',
          'c',
        ], (t, v) => '${t ?? ''}$v'),
        equals('abc'),
      );
      expect(
        mergeIterable<int, int>([1, 2, 3], (t, v) => t! * v, 2),
        equals(12),
      );
    });

    test('sum, max, min, average', () {
      expect(sumIterable([]), equals(0));
      expect(sumIterable([], init: 5), equals(5));
      expect(sumIterable([1, 2, 3]), equals(6));
      expect(sumIterable([1, 2, 3], init: 10), equals(16));

      expect(maxInIterable([]), isNull);
      expect(maxInIterable([3, 9, 1]), equals(9));
      // Regression: the merge was seeded with `0`, so an iterable of only
      // negative numbers returned 0 instead of its real maximum.
      expect(maxInIterable([-3, -1, -2]), equals(-1));
      expect(maxInIterable([-7]), equals(-7));

      expect(minInIterable([]), isNull);
      expect(minInIterable([3, 9, 1]), equals(1));
      expect(minInIterable([-3, -1, -2]), equals(-3));

      expect(averageIterable([]), isNull);
      expect(averageIterable([1, 2, 3, 4]), equals(2.5));
    });
  });

  group('NNField', () {
    test('default, set, get, value setter', () {
      var f = NNField<int>(5);
      expect(f.value, equals(5));
      expect(f.get(), equals(5));
      expect(f.defaultValue, equals(5));
      expect(f.deepHashcode, isFalse);

      f.value = 10;
      expect(f.value, equals(10));
      f.set(null);
      expect(f.value, equals(5));
      f.value = null;
      expect(f.value, equals(5));
    });

    test('set converting values on failed casts', () {
      var fi = NNField<int>(0);
      fi.set('12');
      expect(fi.value, equals(12));

      var fd = NNField<double>(0.5);
      fd.set('1.5');
      expect(fd.value, equals(1.5));

      var fb = NNField<bool>(false);
      fb.set('true');
      expect(fb.value, isTrue);

      var fs = NNField<String>('');
      fs.set(5);
      expect(fs.value, equals('5'));

      var fl = NNField<List<int>>(<int>[]);
      expect(() => fl.set('x'), throwsA(isA<TypeError>()));
      expect(fl.value, equals(<int>[]));
    });

    test('filter and resolver', () {
      var f = NNField<int>(
        1,
        filter: (v) => parseInt(v, 0)! * 2,
        resolver: (v) => v + 100,
      );
      expect(f.value, equals(101));
      f.set('3');
      expect(f.value, equals(106));
      expect(f.asInt, equals(6));
      f.set(null);
      expect(f.value, equals(101));
    });

    test('equals, ==, hashCode, toString', () {
      var f = NNField<int>(3);
      expect(f.equals(null), isFalse);
      expect(f.equals(3), isTrue);
      expect(f.equals(4), isFalse);
      expect(f.equals(NNField<int>(3)), isTrue);
      expect(f.equals(NNField<int>(4)), isFalse);
      // ignore: unrelated_type_equality_checks
      expect(f == 3, isTrue);
      expect(f == NNField<int>(3), isTrue);
      expect(f.hashCode, equals(3.hashCode));
      expect(f.toString(), equals('3'));
      expect(f.asString, equals('3'));

      var fl = NNField<List<int>>([1, 2], deepHashcode: true);
      expect(fl.hashCode, equals(deepHashCode([1, 2])));
    });

    test('as* getters', () {
      var f = NNField<String>('7');
      expect(f.asNum, equals(7));
      expect(f.asInt, equals(7));
      expect(f.asDouble, equals(7.0));
      expect(f.asString, equals('7'));

      var b = NNField<String>('true');
      expect(b.asBool, isTrue);
    });

    test('operators', () {
      var f = NNField<int>(10);
      expect(f * 2, equals(20));
      expect(f / 4, equals(2.5));
      expect(f + '5', equals(15));
      expect(f - 3, equals(7));
      expect(f ^ 3, equals(9));
      expect(f > 5, isTrue);
      expect(f > 10, isFalse);
      expect(f >= 10, isTrue);
      expect(f < 11, isTrue);
      expect(f < 10, isFalse);
      expect(f <= 10, isTrue);
      expect(f.value, equals(10));
    });

    test('increment, decrement, multiply, divide', () {
      var f = NNField<num>(10);
      expect(f.increment(5), equals(15));
      expect(f.value, equals(15));
      expect(f.decrement('3'), equals(12));
      expect(f.multiply(2), equals(24));
      expect(f.divide(16), equals(1.5));
      expect(f.value, equals(1.5));
    });
  });

  group('ObjectCache', () {
    test('get without definition', () {
      var cache = ObjectCache();
      expect(cache.maxInstances, isNull);
      expect(cache.get('x'), isNull);
      expect(cache['x'], isNull);
    });

    test('define, get, cached instance and operator []', () {
      var cache = ObjectCache();
      var count = 0;
      cache.define('a', () => _Counter(++count));

      var o1 = cache.get<_Counter>('a')!;
      expect(o1.id, equals(1));
      expect(identical(cache.get<_Counter>('a'), o1), isTrue);
      expect(identical(cache['a'], o1), isTrue);
      expect(count, equals(1));

      // Explicit instantiator is ignored when an instance is cached:
      expect(identical(cache.get('a', () => _Counter(99)), o1), isTrue);

      // Explicit instantiator for an undefined key:
      var o2 = cache.get('b', () => _Counter(50))!;
      expect(o2.id, equals(50));
      expect(identical(cache['b'], o2), isTrue);
    });

    test('cache validators', () {
      var cache = ObjectCache();
      var count = 0;
      cache.define('a', () => _Counter(++count), (o) => (o as _Counter).valid);

      var o1 = cache.get<_Counter>('a')!;
      expect(identical(cache.get('a'), o1), isTrue);

      o1.valid = false;
      var o2 = cache.get<_Counter>('a')!;
      expect(identical(o2, o1), isFalse);
      expect(o2.id, equals(2));
      expect(identical(cache.get('a'), o2), isTrue);

      // Explicit validator parameter overrides the defined one:
      var o3 = cache.get<_Counter>('a', null, (o) => false)!;
      expect(o3.id, equals(3));

      // setInstantiator / setCacheValidator:
      cache.setInstantiator('s', () => _Counter(++count));
      var s1 = cache.get<_Counter>('s')!;
      expect(s1.id, equals(4));
      cache.setCacheValidator('s', (o) => false);
      var s2 = cache.get<_Counter>('s')!;
      expect(s2.id, equals(5));
    });

    test('defineAll', () {
      var cache = ObjectCache();
      var validatorCalls = 0;
      cache.defineAll({
        'f': () => 'F',
        'l1': [() => 'L1'],
        'l2': [
          () => 'L2',
          (o) {
            validatorCalls++;
            return true;
          },
        ],
        'bad': 123,
        'l3': [1, 2, 3],
      });

      expect(cache.get('f'), equals('F'));
      expect(cache.get('l1'), equals('L1'));
      expect(cache.get('l2'), equals('L2'));
      expect(validatorCalls, equals(0));
      expect(cache.get('l2'), equals('L2'));
      expect(validatorCalls, equals(1));
      expect(cache.get('bad'), isNull);
      expect(cache.get('l3'), isNull);
    });

    test('maxInstances', () {
      var cache = ObjectCache(2);
      var count = 0;
      for (var k in ['a', 'b', 'c']) {
        cache.define(k, () => _Counter(++count));
      }

      var a1 = cache.get<_Counter>('a')!;
      var b1 = cache.get<_Counter>('b')!;
      expect(count, equals(2));

      // Getting 'c' removes the oldest instance ('a'):
      var c1 = cache.get<_Counter>('c')!;
      expect(c1.id, equals(3));
      expect(identical(cache.get('b'), b1), isTrue);
      expect(identical(cache.get('c'), c1), isTrue);
      expect(count, equals(3));

      var a2 = cache.get<_Counter>('a')!;
      expect(identical(a2, a1), isFalse);
      expect(a2.id, equals(4));

      // `maxInstances = 0` disables the limit:
      var unlimited = ObjectCache(0);
      for (var i = 0; i < 5; ++i) {
        unlimited.define('k$i', () => _Counter(i));
        unlimited.get('k$i');
      }
      expect(unlimited.disposeInstances(100), equals(5));
    });

    test('disposeInstances, disposeInstance, clearInstances, clear', () {
      var cache = ObjectCache();
      var count = 0;
      for (var k in ['a', 'b', 'c']) {
        cache.define(k, () => _Counter(++count));
        cache.get(k);
      }
      expect(count, equals(3));

      expect(cache.disposeInstances(null), equals(0));
      expect(cache.disposeInstances(0), equals(0));
      expect(cache.disposeInstances(1), equals(1));
      // 'a' disposed -> re-instantiated:
      expect(cache.get<_Counter>('a')!.id, equals(4));

      var b = cache.get<_Counter>('b')!;
      cache.disposeInstance('b');
      var b2 = cache.get<_Counter>('b')!;
      expect(identical(b, b2), isFalse);
      expect(b2.id, equals(5));

      cache.clearInstances();
      expect(cache.disposeInstances(10), equals(0));
      expect(cache.get<_Counter>('c')!.id, equals(6));

      cache.undefine('c');
      cache.clearInstances();
      expect(cache.get('c'), isNull);
      expect(cache.get<_Counter>('a')!.id, equals(7));

      cache.clear();
      expect(cache.get('a'), isNull);
      expect(cache.get('b'), isNull);
    });
  });

  group('TreeReferenceMap (getters)', () {
    late _Node root, a, a1, a2, b;

    setUp(() {
      root = _Node('root');
      a = root.add(_Node('a'));
      a1 = a.add(_Node('a1'));
      a2 = a.add(_Node('a2'));
      b = root.add(_Node('b'));
    });

    test('tree navigation', () {
      var m = _newTreeMap(root);
      m[a] = 'A';
      m[a1] = 'A1';
      m[b] = 'B';

      expect(m.isInTree(root), isTrue);
      expect(m.isInTree(a2), isTrue);
      expect(m.isInTree(_Node('x')), isFalse);
      expect(m.isInTree(null), isFalse);

      expect(m.getParentOf(null), isNull);
      expect(m.getParentOf(a1), same(a));
      expect(m.getChildrenOf(null), isEmpty);
      expect(m.getChildrenOf(a), equals([a1, a2]));
      expect(m.isChildOf(null, a, false), isFalse);
      expect(m.isChildOf(root, a1, false), isFalse);
      expect(m.isChildOf(root, a1, true), isTrue);

      expect(m.getSubValues(null), isEmpty);
      expect(m.getSubValues(root), equals(['A', 'B']));
      expect(
        m.getSubValues(root, traverseSubValues: true),
        equals(['A', 'A1', 'B']),
      );
      expect(m.getSubValues(a), equals(['A1']));

      expect(m.getParentKey(null), isNull);
      expect(m.getParentKey(root), isNull);
      expect(m.getParentKey(a1), same(a));
      expect(m.getParentKey(a2), same(a));
      expect(m.getParentKey(a), same(root));
      expect(m.getParentKey(_Node('x')), isNull);
      expect(m.getParentKey(a1, includePurgedEntries: true), same(a));
      expect(m.getParentKey(a, includePurgedEntries: true), same(root));

      expect(m.getParentValue(null), isNull);
      expect(m.getParentValue(a1), equals('A'));
      expect(m.getParentValue(a1, includePurgedEntries: true), equals('A'));
      expect(m.getParentValue(a), isNull);
      expect(m.getParentValue(_Node('x')), isNull);

      expect(m.walkTree((n) => n.name == 'a2' ? n : null), same(a2));
      expect(m.walkTree((n) => n.name == 'zz' ? n : null), isNull);
      expect(m.walkTree((n) => n.name == 'a2' ? n : null, root: b), isNull);
      var visited = <String>[];
      var r = m.walkTree<String?>((n) {
        visited.add(n.name);
        return null;
      });
      expect(r, isNull);
      expect(visited, equals(['a', 'a1', 'a2', 'b']));
    });

    test('Map interface', () {
      var m = _newTreeMap(root);
      expect(m.isEmpty, isTrue);
      expect(m.isNotEmpty, isFalse);

      m.addAll({a: 'A', b: 'B'});
      m.addEntries([MapEntry(a1, 'A1')]);
      expect(m.length, equals(3));
      expect(m.isNotEmpty, isTrue);
      expect(m.keys, equals([a, b, a1]));
      expect(m.values, equals(['A', 'B', 'A1']));
      expect(
        m.entries.map((e) => '${e.key}=${e.value}'),
        equals(['a=A', 'b=B', 'a1=A1']),
      );
      expect(m.containsKey(a), isTrue);
      expect(m.containsKey(a2), isFalse);
      expect(m.containsValue('B'), isTrue);
      expect(m.containsValue('Z'), isFalse);
      Object notANode = 'not a node';
      expect(m[notANode], isNull);
      expect(m[a], equals('A'));
      expect(m.get(b), equals('B'));

      var seen = <String>[];
      m.forEach((k, v) => seen.add('$k:$v'));
      expect(seen, equals(['a:A', 'b:B', 'a1:A1']));

      expect(m.keysReversed, equals([a1, b, a]));
      expect(() => m.keysReversed.add(a2), throwsUnsupportedError);

      expect(m.putIfAbsent(a2, () => 'A2'), equals('A2'));
      expect(m.putIfAbsent(a2, () => 'XX'), equals('A2'));
      expect(m.keysReversed, equals([a2, a1, b, a]));

      expect(m.update(a2, (v) => '$v!'), equals('A2!'));
      expect(m.update(root, (v) => v, ifAbsent: () => 'R'), equals('R'));

      m.updateAll((k, v) => v.toLowerCase());
      expect(m.values, equals(['a', 'b', 'a1', 'a2!', 'r']));

      m.removeWhere((k, v) => v.startsWith('a'));
      expect(m.keys, equals([b, root]));

      expect(
        m.map((k, v) => MapEntry(k.name, v.length)),
        equals({'b': 1, 'root': 1}),
      );

      Map<Object, Object> casted = m.cast<Object, Object>();
      expect(casted[b], equals('b'));

      expect(m.remove(root), equals('r'));
      expect(m.remove(root), isNull);
      expect(m.keys, equals([b]));

      m.clear();
      expect(m.isEmpty, isTrue);
      expect(m.keysReversed, isEmpty);
    });

    test('toString', () {
      var m = _newTreeMap(root);
      m[a] = 'A';
      expect(
        m.toString(),
        equals(
          '{root: root, length: 1, purgedLength: 0, purgedEntriesCount: 0,'
          ' revalidatedPurgedEntries: 0, keepPurgedEntries: false,'
          ' purgedEntriesTimeout: -1ms, maxPurgedEntries: null}',
        ),
      );

      var m2 = _newTreeMap(
        root,
        keepPurgedKeys: true,
        purgedEntriesTimeout: Duration(seconds: 2),
        maxPurgedEntries: 10,
      );
      expect(
        m2.toString(),
        equals(
          '{root: root, length: 0, purgedLength: 0, purgedEntriesCount: 0,'
          ' revalidatedPurgedEntries: 0, keepPurgedEntries: true,'
          ' purgedEntriesTimeout: 2000ms, maxPurgedEntries: 10}',
        ),
      );
    });

    test('purge without keeping purged entries', () {
      var purgedCalls = <Map<_Node, String>>[];
      var m = _newTreeMap(root, onPurgedEntries: purgedCalls.add);
      m[a] = 'A';
      m[a1] = 'A1';
      m[b] = 'B';

      expect(m.invalidKeys, isEmpty);
      expect(m.validKeys, equals([a, a1, b]));

      a.detach();

      expect(m.validKeys, equals([b]));
      expect(m.invalidKeys, equals([a, a1]));
      expect(m.validEntries.map((e) => e.value), equals(['B']));
      expect(m.invalidEntries.map((e) => e.value), equals(['A', 'A1']));

      expect(m.purge(), same(m));
      expect(m.length, equals(1));
      expect(m.purgedEntriesCount, equals(2));
      expect(m.purgedLength, equals(0));
      expect(m.purgedKeys, isEmpty);
      expect(m.purgedEntries, isEmpty);
      expect(m.purgedKeysReversed, isEmpty);
      expect(m.getFromPurgedEntries(a), isNull);
      expect(purgedCalls.length, equals(1));
      expect(purgedCalls.first, equals({a: 'A', a1: 'A1'}));

      // Nothing to purge -> no callback:
      m.purge();
      expect(purgedCalls.length, equals(1));
    });

    test('purge keeping purged entries and revalidation', () {
      var purgedCalls = <Map<_Node, String>>[];
      var m = _newTreeMap(
        root,
        keepPurgedKeys: true,
        onPurgedEntries: purgedCalls.add,
      );
      m[a] = 'A';
      m[a1] = 'A1';
      m[b] = 'B';

      expect(m.revalidatePurgedEntries(), equals(0));

      // Nothing invalid: early return.
      expect(m.purge(), same(m));
      expect(purgedCalls, isEmpty);

      a.detach();
      m.purge();

      expect(purgedCalls.length, equals(1));
      expect(purgedCalls.first, equals({a: 'A', a1: 'A1'}));
      expect(m.length, equals(1));
      expect(m.purgedLength, equals(2));
      expect(m.purgedEntriesCount, equals(2));
      expect(m.purgedKeys, equals([a, a1]));
      expect(m.purgedKeysReversed, equals([a1, a]));
      expect(
        m.purgedEntries.map((e) => '${e.key}=${e.value}'),
        equals(['a=A', 'a1=A1']),
      );

      expect(m.getFromPurgedEntries(null), isNull);
      expect(m.getFromPurgedEntries(a), equals('A'));
      expect(m.getFromPurgedEntries(b), isNull);
      expect(m.get(a), isNull);
      expect(m.getAlsoFromPurgedEntries(a), equals('A'));
      expect(m.getAlsoFromPurgedEntries(b), equals('B'));

      expect(m.getSubValues(a), isEmpty);
      expect(m.getSubValues(a, includePurgedEntries: true), equals(['A1']));

      expect(m.getParentKey(a1), isNull);
      expect(m.getParentKey(a1, includePurgedEntries: true), same(a));
      // Regression: `getParentValue` did not forward `includePurgedEntries`
      // to `getParentKey`, so a purged parent was never found.
      expect(m.getParentValue(a1), isNull);
      expect(m.getParentValue(a1, includePurgedEntries: true), equals('A'));

      // Re-attach and revalidate:
      root.add(a);
      expect(m.revalidatePurgedEntries(), equals(2));
      expect(m.revalidatedPurgedEntriesCount, equals(2));
      expect(m.purgedLength, equals(0));
      expect(m.length, equals(3));
      expect(m[a1], equals('A1'));

      // Revalidation also happens inside `purge`:
      a.detach();
      m.purge();
      expect(m.purgedLength, equals(2));
      root.add(a);
      m.purge();
      expect(m.purgedLength, equals(0));
      expect(m.revalidatedPurgedEntriesCount, equals(4));
      expect(m.length, equals(3));

      a.detach();
      m.purge();
      expect(m.purgedLength, equals(2));
      m.disposePurgedEntries();
      expect(m.purgedLength, equals(0));
      expect(m.purgedKeys, isEmpty);
      expect(m.getAlsoFromPurgedEntries(a), isNull);
    });

    test('maxPurgedEntries', () {
      var m = _newTreeMap(root, keepPurgedKeys: true, maxPurgedEntries: 1);
      m[a] = 'A';
      m[a1] = 'A1';
      m[a2] = 'A2';
      m[b] = 'B';

      a.detach();
      m.purge();

      expect(m.purgedEntriesCount, equals(3));
      expect(m.purgedLength, equals(1));
      expect(m.purgedKeys, equals([a2]));

      // Without a limit, nothing is removed:
      var m2 = _newTreeMap(root, keepPurgedKeys: true);
      m2[b] = 'B';
      m2.checkPurgeEntriesLimit();
      expect(m2.purgedLength, equals(0));
    });

    test('purgedEntriesTimeout', () async {
      var m = _newTreeMap(
        root,
        keepPurgedKeys: true,
        purgedEntriesTimeout: Duration(milliseconds: 1),
      );
      m[a] = 'A';
      m[a1] = 'A1';
      m[b] = 'B';

      a.detach();
      m.purge();
      expect(m.purgedLength, equals(2));

      await Future.delayed(Duration(milliseconds: 10));

      m.checkPurgedEntriesTimeout();
      expect(m.purgedLength, equals(0));
      expect(m.purgedKeys, isEmpty);

      // No timeout -> nothing expires:
      var m2 = _newTreeMap(root, keepPurgedKeys: true);
      m2[b] = 'B';
      b.detach();
      m2.purge();
      m2.checkPurgedEntriesTimeout();
      expect(m2.purgedLength, equals(1));
    });

    test('autoPurge', () {
      var m0 = _newTreeMap(root);
      expect(m0.doAutoPurge(), isFalse);

      var m = _newTreeMap(root, autoPurge: true, autoPurgeThreshold: 2);
      expect(m.autoPurge, isTrue);
      expect(m.autoPurgeThreshold, equals(2));

      m[a] = 'A'; // unpurged: 0 -> 1
      m[a1] = 'A1'; // unpurged: 1 -> 2
      m[b] = 'B'; // auto purge (nothing invalid)
      expect(m.purgedEntriesCount, equals(0));

      a.detach();

      expect(m.doAutoPurge(), isFalse);
      expect(m.doAutoPurge(), isFalse);
      expect(m.purgedEntriesCount, equals(0));
      expect(m.doAutoPurge(), isTrue);
      expect(m.purgedEntriesCount, equals(2));
      expect(m.keys, equals([b]));
    });
  });
}
