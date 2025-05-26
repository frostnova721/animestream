// import 'package:d4rt/d4rt.dart';
// import 'package:html/dom.dart';
// import 'package:html/parser.dart';

// class HtmlRegister {
//   void register(D4rt d4rt) {
//     d4rt.registerBridgedClass(docBridge);
//     d4rt.registerBridgedClass(elemBridge);

//     d4rt.registertopLevelFunction("parse",
//         (InterpreterVisitor? v, List<Object?> args, Map<String, Object?> namedArgs, List<RuntimeType>? rt) {
//       return parse(args[0] as dynamic);
//     });
//   }

//   final docBridge = BridgedClassDefinition(
//     nativeType: Document,
//     name: 'Document',
//     constructors: {
//       '': (_, __, ___) {
//         return Document;
//       },
//     },
//     getters: {
//       'body': (visitor, target) => (target as Document).body,
//       'documentElement': (visitor, target) => (target as Document).documentElement,
//       'head': (visitor, target) => (target as Document).head,
//       'parent': (visitor, target) => (target as Document).parent,
//       'outerHtml': (visitor, target) => (target as Document).outerHtml,
//       'text': (visitor, target) => (target as Document).text,
//       'children': (visitor, target) => (target as Document).children,
//     },
//     methods: {
//       'querySelector': (visitor, target, positionalArgs, namedArgs) =>
//           (target as Document).querySelector(positionalArgs[0] as String),
//       'querySelectorAll': (visitor, target, positionalArgs, namedArgs) =>
//           (target as Document).querySelectorAll(positionalArgs[0] as String),
//       'getElementsByClassName': (visitor, target, positionalArgs, namedArgs) =>
//           (target as Document).getElementsByClassName(positionalArgs[0] as String),
//       'getElementsByTagName': (visitor, target, positionalArgs, namedArgs) =>
//           (target as Document).getElementsByTagName(positionalArgs[0] as String),
//       'getElementById': (visitor, target, positionalArgs, namedArgs) =>
//           (target as Document).getElementById(positionalArgs[0] as String),
//       'attributes': (visitor, target, positionalArgs, namedArgs) => (target as Document).attributes,
//     },
//   );

//   // Bridge for element
//   final elemBridge = BridgedClassDefinition(
//     nativeType: Element,
//     name: 'Element',
//     constructors: {
//       '': (_, __, ___) {
//         return Element;
//       },
//     },
//     getters: {
//       'outerHtml': (visitor, target) => (target as Element).outerHtml,
//       'innerHtml': (visitor, target) => (target as Element).innerHtml,
//       'localName': (visitor, target) => (target as Element).localName,
//       'children': (visitor, target) => (target as Element).children,
//       'text': (visitor, target) => (target as Element).text,
//       'parent': (visitor, target) => (target as Element).parent,
//       'namespaceUri': (visitor, target) => (target as Element).namespaceUri,
//       'className': (visitor, target) => (target as Element).className,
//       'previousElementSibling': (visitor, target) => (target as Element).previousElementSibling,
//       'nextElementSibling': (visitor, target) => (target as Element).nextElementSibling,
//     },
//     methods: {
//       'attributes': (visitor, target, args, namedArgs) => (target as Element).attributes,
//       'text': (visitor, target, args, namedArgs) => (target as Element).text,
//       'querySelector': (visitor, target, args, namedArgs) =>
//           (target as Element).querySelector(args[0] as String),
//       'querySelectorAll': (visitor, target, args, namedArgs) =>
//           (target as Element).querySelectorAll(args[0] as String),
//       'getElementsByClassName': (visitor, target, args, namedArgs) =>
//           (target as Element).getElementsByClassName(args[0] as String),
//       'getElementsByTagName': (visitor, target, args, namedArgs) =>
//           (target as Element).getElementsByTagName(args[0] as String),
//     },
//   );
// }
