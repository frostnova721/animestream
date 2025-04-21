import 'dart:collection';

import 'package:animestream/core/anime/providers/type/docFragment.dart';
import 'package:animestream/core/anime/providers/type/element.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/dart_eval_extensions.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:html/dom.dart';
import 'package:source_span/src/file.dart';

class $Document implements $Instance {
  static final $type = BridgeTypeSpec("package:html/dom.dart", "Document").ref;

  static final $declaration = BridgeClassDef(
    BridgeClassType($type),
    constructors: {
      '': BridgeConstructorDef(BridgeFunctionDef(
        returns: BridgeTypeAnnotation($type),
      )),
    },
    methods: {
      'querySelector': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($Element.$type, nullable: true),
          params: [
            BridgeParameter('selector', BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)), false),
          ],
        ),
      ),
    },
    getters: {
      'body': BridgeMethodDef(
        BridgeFunctionDef(returns: BridgeTypeAnnotation($Element.$type, nullable: true)),
        isStatic: false,
      ),
      'children': BridgeMethodDef(
        BridgeFunctionDef(returns: CoreTypes.list.refWith([$Element.$type]).annotate)
      )
    },
    wrap: true,
  );

  final Document $value;

  $Document.wrap(this.$value)
      : attributes = $value.attributes,
        parentNode = $value.parent,
        sourceSpan = null,
        text = $value.text;

  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'querySelector':
        return $Function((runtime, target, args) {
          final selector = args[0]!.$value as String;
          final result = $value.querySelector(selector);
          return result != null ? $Element.wrap(result) : $null();
        });
      case 'querySelectorAll':
        return $Function((runtime, target, args) {
          final selector = args[0]!.$value as String;
          final results = $value.querySelectorAll(selector);
          return $List.wrap(results.map($Element.wrap).toList());
        });
      case 'getElementById':
        return $Function((runtime, target, args) {
          final id = args[0]!.$value as String;
          final result = $value.getElementById(id);
          return result != null ? $Element.wrap(result) : $null();
        });
      case 'getElementsByClassName':
        return $Function((runtime, target, args) {
          final className = args[0]!.$value as String;
          final results = $value.getElementsByClassName(className);
          return $List.wrap(results.map($Element.wrap).toList());
        });
      case 'getElementsByTagName':
        return $Function((runtime, target, args) {
          final tagName = args[0]!.$value as String;
          final results = $value.getElementsByTagName(tagName);
          return $List.wrap(results.map($Element.wrap).toList());
        });
      case 'createElement':
        return $Function((runtime, target, args) {
          final tag = args[0]!.$value as String;
          final element = $value.createElement(tag);
          return $Element.wrap(element);
        });
      case 'createDocumentFragment':
        return $Function((runtime, target, args) {
          final fragment = $value.createDocumentFragment();
          return $DocumentFragment.wrap(fragment);
        });
      case 'body':
        final body = $value.body;
        return body != null ? $Element.wrap(body) : $null();
      case 'head':
        final head = $value.head;
        return head != null ? $Element.wrap(head) : $null();
      case 'documentElement':
        final docEl = $value.documentElement;
        return docEl != null ? $Element.wrap(docEl) : $null();
      case 'outerHtml':
        return $String($value.outerHtml);
      case 'text':
        return $String($value.text ?? '');
      case 'children':
        return $List.wrap($value.children.map((e) => $Element.wrap(e)).toList());
      default:
        return null;
    }
  }

  int $getRuntimeType(Runtime runtime) {
    return runtime.lookupType($type.spec!);
  }

  void $setProperty(Runtime runtime, String identifier, $Value value) {
    throw UnimplementedError("Document is immutable");
  }

  Document get $reified => $value;

  LinkedHashMap<Object, String> attributes;

  Node? parentNode;

  FileSpan? sourceSpan;

  String? text;

  void append(Node node) => $value.append(node);

  LinkedHashMap<Object, FileSpan>? get attributeSpans => $value.attributeSpans;

  LinkedHashMap<Object, FileSpan>? get attributeValueSpans => $value.attributeValueSpans;

  Element? get body => $value.body;

  List<Element> get children => $value.children;

  Document clone(bool deep) => $value.clone(deep);

  bool contains(Node node) => $value.contains(node);

  DocumentFragment createDocumentFragment() => $value.createDocumentFragment();

  Element createElement(String tag) => $value.createElement(tag);

  Element createElementNS(String? namespaceUri, String? tag) => $value.createElementNS(namespaceUri, tag);

  Element? get documentElement => $value.documentElement;

  Node? get firstChild => $value.firstChild;

  Element? getElementById(String id) => $value.getElementById(id);

  List<Element> getElementsByClassName(String classNames) => $value.getElementsByClassName(classNames);

  List<Element> getElementsByTagName(String localName) => $value.getElementsByTagName(localName);

  bool hasChildNodes() => $value.hasChildNodes();

  bool hasContent() => $value.hasContent();

  Element? get head => $value.head;

  void insertBefore(Node node, Node? refNode) => $value.insertBefore(node, refNode);

  int get nodeType => $value.nodeType;

  NodeList get nodes => $value.nodes;

  String get outerHtml => $value.outerHtml;

  Element? get parent => $value.parent;

  Element? querySelector(String selector) => $value.querySelector(selector);

  List<Element> querySelectorAll(String selector) => $value.querySelectorAll(selector);

  Node remove() => $value.remove();

  void reparentChildren(Node newParent) => $value.reparentChildren(newParent);

  Node replaceWith(Node otherNode) => $value.replaceWith(otherNode);
}
