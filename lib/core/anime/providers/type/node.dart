import 'dart:collection';

import 'package:animestream/core/anime/providers/type/element.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/dart_eval_extensions.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:html/dom.dart';
import 'package:source_span/src/file.dart';

// Redundant asf. However....
class $Node implements Node, $Instance {
  @override
  final Node $value;

  static final $type = BridgeTypeSpec("package:html/dom.dart", "Node").ref;

  $Node.wrap(this.$value)
      : attributes = LinkedHashMap<Object, String>(),
        parentNode = $value.parentNode,
        text = $value.text,
        sourceSpan = $value.sourceSpan;

  @override
  LinkedHashMap<Object, String> attributes;

  @override
  Node? parentNode;

  @override
  FileSpan? sourceSpan;

  @override
  String? text;

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'children':
        return $List.wrap($value.children.map((e) => $Element.wrap(e)).toList());
      default: throw UnimplementedError("$identifier has not defined!");
    }
  }

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);

  @override
  get $reified => $value;

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {}

  @override
  void append(Node node) => $value.append(node);

  @override
  LinkedHashMap<Object, FileSpan>? get attributeSpans => $value.attributeSpans;

  @override
  LinkedHashMap<Object, FileSpan>? get attributeValueSpans => $value.attributeSpans;

  @override
  List<Element> get children => $value.children;

  @override
  Node clone(bool deep) => $value.clone(deep);

  @override
  bool contains(Node node) => $value.contains(node);

  @override
  Node? get firstChild => $value.firstChild;

  @override
  bool hasChildNodes() => $value.hasChildNodes();

  @override
  bool hasContent() => $value.hasContent();

  @override
  void insertBefore(Node node, Node? refNode) => $value.insertBefore(node, refNode);

  @override
  int get nodeType => $value.nodeType;

  @override
  NodeList get nodes => $value.nodes;

  @override
  Element? get parent => $value.parent;

  @override
  Node remove() => $value.remove();

  @override
  void reparentChildren(Node newParent) => $value.reparentChildren(newParent);

  @override
  Node replaceWith(Node otherNode) => $value.replaceWith(otherNode);
}
