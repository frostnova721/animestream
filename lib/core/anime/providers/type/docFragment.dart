import 'package:animestream/core/anime/providers/type/element.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/dart_eval_extensions.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:html/dom.dart';

class $DocumentFragment implements $Instance {
  static final $type = BridgeTypeSpec('package:html/dom.dart', 'DocumentFragment').ref;

  static final $declaration = BridgeClassDef(
    BridgeClassType($type),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
        ),
      ),
    },
    methods: {
      'append': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          params: [
            BridgeParameter('node', BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object)), false),
          ],
        ),
      ),
      'clone': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          params: [
            BridgeParameter('deep', BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)), false),
          ],
        ),
      ),
      'hasChildNodes': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
        ),
      ),
      'querySelector': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object), nullable: true),
          params: [
            BridgeParameter('selector', BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)), false),
          ],
        ),
      ),
      'querySelectorAll': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.list)),
          params: [
            BridgeParameter('selector', BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)), false),
          ],
        ),
      ),
    },
  );

  @override
  final DocumentFragment $value;

  $DocumentFragment.wrap(this.$value);

  @override
  DocumentFragment get $reified => $value;

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'append':
        return $Function((runtime, target, args) {
          final node = args[0]!.$value as Node;
          $value.append(node);
          return $null();
        });
      case 'clone':
        return $Function((runtime, target, args) {
          final deep = args[0]!.$value as bool;
          final cloned = $value.clone(deep);
          return $DocumentFragment.wrap(cloned);
        });
      case 'hasChildNodes':
        return $Function((runtime, target, args) {
          return $bool($value.hasChildNodes());
        });
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
      default:
        return null;
    }
  }

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    throw UnimplementedError('DocumentFragment is immutable');
  }
}