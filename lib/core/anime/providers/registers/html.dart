import 'package:animestream/core/anime/providers/type/document.dart';
import 'package:animestream/core/anime/providers/type/element.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/dart_eval_extensions.dart';
import 'package:html/parser.dart';

class HtmlPlugin extends EvalPlugin {
  @override
  String get identifier => "package:html";

  @override
  void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($Document.$declaration);
    registry.defineBridgeClass($Element.$declaration);

    registry.defineBridgeTopLevelFunction(
      BridgeFunctionDeclaration(
        "package:html/parser.dart",
        "parse",
        BridgeFunctionDef(
          returns: $Document.$type.annotate,
          params: [
            BridgeParameter("input", CoreTypes.dynamic.ref.annotate, false),
          ],
        ),
      ),
    );
  }

  @override
  void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFunc("package:html/parser.dart", "parse", (runtime, target, args) {
      final input = args[0]!.$value as String;
      final doc = parse(input);
      return $Document.wrap(doc);
    },);
  }
}
