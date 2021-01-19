import 'package:swiss_knife/src/collections.dart';
import 'package:test/test.dart';

class MyNode {
  MyNode _parent;

  MyNode get parent => _parent;

  Set<MyNode> children = {};

  String text;

  MyNode(this.text, {List<MyNode> children}) {
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

  @override
  String toString() {
    return '{text: $text, children: $children}';
  }
}

class MyTree extends TreeReferenceMap<MyNode, String> {
  MyTree(
    root, {
    bool autoPurge,
    bool keepPurgedKeys,
    Duration purgedEntriesTimeout,
    int maxPurgedEntries,
  }) : super(root,
            autoPurge: autoPurge,
            keepPurgedKeys: keepPurgedKeys,
            purgedEntriesTimeout: purgedEntriesTimeout,
            maxPurgedEntries: maxPurgedEntries);

  @override
  MyNode getParentOf(MyNode key) => key?.parent;

  @override
  bool isChildOf(MyNode parent, MyNode child, bool deep) {
    if (parent == null || child == null) return false;
    if (deep ?? false) {
      if (parent.children.contains(child)) return true;
      var found = parent.children
          .firstWhere((e) => isChildOf(e, child, true), orElse: () => null);
      return found != null;
    } else {
      return parent.children.contains(child);
    }
  }

  @override
  Iterable<MyNode> getChildrenOf(MyNode key) => key?.children?.toList();
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

      var tree = MyTree(root);

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

      expect(tree.getParentKey(a).text, equals('root'));
      expect(tree.getParentKey(b).text, equals('root'));
      expect(tree.getParentKey(b1).text, equals('b'));
      expect(tree.getParentKey(b2).text, equals('b'));
      expect(tree.getParentKey(b21).text, equals('b'));

      expect(tree.getParentValue(a), equals('ROOT'));
      expect(tree.getParentValue(b), equals('ROOT'));
      expect(tree.getParentValue(b1), equals('B'));
      expect(tree.getParentValue(b2), equals('B'));

      expect(tree.getParentKey(x), isNull);
    });
  });
}
