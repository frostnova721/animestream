import 'dart:collection';

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/dart_eval_extensions.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:html/dom.dart';
import 'package:source_span/src/file.dart';

class $Element implements $Instance, Element {
  static final $type = BridgeTypeSpec("package:html/dart", "Element").ref;

  static final $declaration = BridgeClassDef(BridgeClassType($type),
      constructors: {
        '': BridgeConstructorDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation($type),
          ),
        ),
      },
      methods: {
        'querySelector': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation($Element.$type, nullable: true),
            params: [
              BridgeParameter('selector', CoreTypes.string.ref.annotate, false),
            ],
          ),
        ),
        'hasContent': BridgeMethodDef(
          BridgeFunctionDef(returns: CoreTypes.bool.ref.annotate),
        ),
      },
      getters: {
        'children': BridgeMethodDef(BridgeFunctionDef(returns: CoreTypes.list.refWith([$Element.$type]).annotate))
      },
      wrap: true);

  final Element $value;

  $Element.wrap(this.$value)
      : attributes = $value.attributes,
        className = $value.className,
        id = $value.id,
        endSourceSpan = $value.endSourceSpan,
        parentNode = $value.parentNode,
        sourceSpan = $value.sourceSpan;

  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'querySelector':
        return $Function((Runtime runtime, $Value? target, List<$Value?> args) {
          final selector = args[0]!.$value as String;
          final result = $value.querySelector(selector);
          if (result == null) return $null();
          return $Element.wrap(result);
        });
      case 'querySelectorAll':
        return $Function((runtime, target, args) {
          final selector = args[0]!.$value as String;
          final results = $value.querySelectorAll(selector);
          return $List.wrap(results.map($Element.wrap).toList());
        });
      case 'children':
        return $List.wrap($value.children.map((e) => $Element.wrap(e)).toList());
      case 'outerHtml':
        return $String($value.outerHtml);
      case 'innerHtml':
        return $String($value.innerHtml);
      case 'contains':
        return $Function((runtime, target, args) => $bool($value.contains(args[0]! as Node)));
      case 'hasContent':
        return $Function(
          (runtime, target, args) => $bool($value.hasContent()),
        );
      case 'className':
        return $String($value.className);
      default:
        return null;
    }
  }

  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);

  void $setProperty(Runtime runtime, String identifier, $Value value) {
    throw UnimplementedError("Element properties are immutable or require special handling.");
  }

  Element get $reified => $value;

  String get outerHtml => $value.outerHtml;

  String get innerHtml => $value.innerHtml;

  set innerHtml(String value) {
    $value.innerHtml = value;
  }

  String get text => $value.text;

  set text(String? value) {
    $value.text = value;
  }

  LinkedHashMap<Object, String> attributes;

  String className;

  FileSpan? endSourceSpan;

  String id;

  Node? parentNode;

  FileSpan? sourceSpan;

  void append(Node node) => throw UnimplementedError();

  LinkedHashMap<Object, FileSpan>? get attributeSpans => $value.attributeSpans;

  LinkedHashMap<Object, FileSpan>? get attributeValueSpans => $value.attributeValueSpans;

  List<Element> get children => $value.children;

  CssClassSet get classes => throw UnimplementedError();

  Element clone(bool deep) {
    return $value.clone(deep);
  }

  bool contains(Node node) => $value.contains(node);

  Node? get firstChild => throw UnimplementedError();

  List<Element> getElementsByClassName(String classNames) => $value.getElementsByClassName(classNames);

  List<Element> getElementsByTagName(String localName) => $value.getElementsByTagName(localName);

  bool hasChildNodes() {
    return $value.hasChildNodes();
  }

  bool hasContent() => $value.hasContent();

  void insertBefore(Node node, Node? refNode) => $value.insertBefore(node, refNode);

  String? get localName => $value.localName;

  String? get namespaceUri => $value.namespaceUri;

  Element? get nextElementSibling => $value.nextElementSibling;

  int get nodeType => $value.nodeType;

  NodeList get nodes => throw UnimplementedError();

  Element? get parent => $value.parent;

  Element? get previousElementSibling => $value.previousElementSibling;

  Element? querySelector(String selector) => $value.querySelector(selector);

  List<Element> querySelectorAll(String selector) => $value.querySelectorAll(selector);

  Node remove() => $value.remove();

  void reparentChildren(Node newParent) => $value.reparentChildren(newParent);

  Node replaceWith(Node otherNode) => $value.replaceWith(otherNode);
}
