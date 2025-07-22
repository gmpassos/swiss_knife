import 'package:collection/collection.dart' show IterableExtension;
import 'package:swiss_knife/src/collections.dart';
import 'package:test/test.dart';

class MyNode {
  MyNode? _parent;

  MyNode? get parent => _parent;

  final Set<MyNode> children = {};

  String text;

  MyNode(this.text, {List<MyNode>? children}) {
    if (children != null) {
      for (var child in children) {
        add(child);
      }
    }
  }

  void add(MyNode child) {
    child._parent = this;
    children.add(child);
  }

  bool remove(MyNode child) {
    if (children.remove(child)) {
      child._parent = null;
      return true;
    }
    return false;
  }

  @override
  String toString() {
    return '{text: $text, children: $children}';
  }
}

class MyTree extends TreeReferenceMap<MyNode, String> {
  MyTree(
    super.root, {
    super.autoPurge,
    super.keepPurgedKeys,
    super.purgedEntriesTimeout,
    super.maxPurgedEntries,
  });

  @override
  MyNode? getParentOf(MyNode? key) => key?.parent;

  @override
  bool isChildOf(MyNode? parent, MyNode? child, bool deep) {
    if (parent == null || child == null) return false;

    if (deep) {
      if (parent.children.contains(child)) return true;
      var found =
          parent.children.firstWhereOrNull((e) => isChildOf(e, child, true));
      return found != null;
    } else {
      return parent.children.contains(child);
    }
  }

  @override
  Iterable<MyNode> getChildrenOf(MyNode? key) => key?.children.toList() ?? [];
}

void main() {
  group('Collections', () {
    setUp(() {});

    test('Collections', () {
      MyNode a, b, c, b1, b2, b21;

      var root = MyNode('root', children: [
        a = MyNode('a'),
        b = MyNode('b', children: [
          b1 = MyNode('b:1'),
          b2 = MyNode('b:2', children: [b21 = MyNode('b:2:1')])
        ]),
        c = MyNode('c'),
      ]);

      var x = MyNode('x');

      var tree = MyTree(root, keepPurgedKeys: true);

      expect(tree.isEmpty, isTrue);
      expect(tree.length, equals(0));

      tree.put(root, 'ROOT');
      tree.put(a, 'A');
      tree.put(b, 'B');
      tree.put(b1, 'B1');
      tree.put(b21, 'B21');
      tree.put(c, 'C');

      expect(tree.length, equals(6));

      expect(tree.get(a), equals('A'));
      expect(tree.get(b), equals('B'));
      expect(tree.get(b1), equals('B1'));
      expect(tree.get(b21), equals('B21'));
      expect(tree.get(c), equals('C'));

      expect(tree.getParentKey(a)!.text, equals('root'));
      expect(tree.getParentKey(b)!.text, equals('root'));
      expect(tree.getParentKey(b1)!.text, equals('b'));
      expect(tree.getParentKey(b2)!.text, equals('b'));
      expect(tree.getParentKey(b21)!.text, equals('b'));

      expect(tree.getParentValue(a), equals('ROOT'));
      expect(tree.getParentValue(b), equals('ROOT'));
      expect(tree.getParentValue(b1), equals('B'));
      expect(tree.getParentValue(b2), equals('B'));

      expect(tree.getParentKey(x), isNull);

      {
        var list = <String>[];
        tree.walkTree((n) => list.add(n.text));
        expect(list, equals(['a', 'b', 'b:1', 'b:2', 'b:2:1', 'c']));
      }

      {
        var list = <String>[];
        var r = tree.walkTree((n) {
          list.add(n.text);
          if (n.text == 'b:2') {
            return n.text.toUpperCase();
          }
          return null;
        });
        expect(r, equals('B:2'));
        expect(list, equals(['a', 'b', 'b:1', 'b:2']));
      }

      {
        var list = <String>[];
        var r = tree.walkTree((n) {
          list.add(n.text);
          if (n.text == 'b') {
            return n.text.toUpperCase();
          }
          return null;
        });
        expect(r, equals('B'));
        expect(list, equals(['a', 'b']));
      }

      {
        var list = tree.getSubValues(b1);
        expect(list, equals([]));
      }

      {
        var list = tree.getSubValues(b2);
        expect(list, equals(['B21']));
      }

      {
        var list = tree.getSubValues(b);
        expect(list, equals(['B1', 'B21']));
      }

      {
        var list = tree.getSubValues(root, traverseSubValues: false);
        expect(list, equals(['A', 'B', 'C']));
      }

      {
        var list = tree.getSubValues(root, traverseSubValues: true);
        expect(list, equals(['A', 'B', 'B1', 'B21', 'C']));
      }

      tree.purge();

      {
        var list = tree.getSubValues(root, traverseSubValues: false);
        expect(list, equals(['A', 'B', 'C']));
      }

      {
        var list = tree.getSubValues(root, traverseSubValues: true);
        expect(list, equals(['A', 'B', 'B1', 'B21', 'C']));
      }

      b.remove(b2);

      {
        var list = tree.getSubValues(b2, includePurgedEntries: false);
        expect(list, equals(['B21']));
      }

      {
        var list = tree.getSubValues(b2, includePurgedEntries: true);
        expect(list, equals(['B21']));
      }

      tree.purge();

      {
        var list = tree.getSubValues(b2, includePurgedEntries: false);
        expect(list, equals([]));
      }

      {
        var list = tree.getSubValues(b2, includePurgedEntries: true);
        expect(list, equals(['B21']));
      }
    });
  });
}
