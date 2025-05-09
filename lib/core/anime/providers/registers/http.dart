import 'package:animestream/core/anime/providers/type/response.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/dart_eval_extensions.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:http/http.dart' as http;

class HttpPlugin implements EvalPlugin {
  @override
  String get identifier => 'package:http';

  @override
  void configureForCompile(BridgeDeclarationRegistry registry) {

    registry.defineBridgeClass($Response.$declaration);

    registry.defineBridgeTopLevelFunction(
      BridgeFunctionDeclaration(
        'package:http/http.dart',
        'get',
        BridgeFunctionDef(returns: CoreTypes.future.ref.annotate, params: [
          'url'.param(CoreTypes.uri.ref.annotate),
        ], namedParams: [
          BridgeParameter("headers", CoreTypes.map.ref.annotate, true),
        ]),
      ),
    );

    registry.defineBridgeTopLevelFunction(
      BridgeFunctionDeclaration(
        "package:http/http.dart",
        "post",
        BridgeFunctionDef(returns: CoreTypes.future.ref.annotate, params: [
          'url'.param(CoreTypes.uri.ref.annotate),
        ], namedParams: [
          BridgeParameter('body', CoreTypes.dynamic.ref.annotate, true),
          BridgeParameter("headers", CoreTypes.map.ref.annotate, true),
        ]),
      ),
    );
  }

  @override
  void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFunc(
      'package:http/http.dart',
      'get',
      (Runtime runtime, $Value? target, List<$Value?> args) {
        final uri = args[0]!.$value as Uri;
        final headers = (args[1]?.$value as Map<$Value, $Value>?)
            ?.map((k, v) => MapEntry(k.$value, v.$reified))
            .cast<String, String>();
        return $Future.wrap(http.get(uri, headers: headers).then((res) {
          return $Response.wrap(res);
        }));
      },
    );

    runtime.registerBridgeFunc(
      "package:http/http.dart",
      "post",
      (Runtime runtime, $Value? target, List<$Value?> args) {
        final uri = args[0]!.$value as Uri;

        final body = args[1]?.$value;

        final headers = (args[2]?.$value as Map<$Value, $Value>?)
            ?.map((k, v) => MapEntry(k.$reified, v.$reified))
            .cast<String, String>();

        return $Future.wrap(http.post(uri, body: body ,headers: headers).then((res) {
          return $Response.wrap(res);
        }));
      },
    );
  }
}
