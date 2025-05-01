import 'dart:typed_data';

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/dart_eval_extensions.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:http/http.dart';

class $Response implements $Instance, Response {
  static final $type = BridgeTypeSpec('package:http/http.dart', 'Response').ref;

  static final $declaration = BridgeClassDef(
    BridgeClassType($type),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
        ),
      ),
    },
    getters: {
      'body': BridgeFunctionDef(returns: CoreTypes.string.ref.annotate).asMethod,
      'bodyBytes': BridgeFunctionDef(returns: CoreTypes.list.refWith([CoreTypes.int.ref]).annotate).asMethod,
      'headers': BridgeFunctionDef(returns: CoreTypes.map.ref.annotate).asMethod,
      'statusCode': BridgeFunctionDef(returns: CoreTypes.int.ref.annotate).asMethod,
      'contentLength': BridgeFunctionDef(returns: CoreTypes.int.ref.annotateNullable).asMethod,
    },
    wrap: true,
  );

  final Response $value;

  $Response.wrap(this.$value);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    return switch (identifier) {
      "body" => $String(body),
      "bodyBytes" => $List.wrap(bodyBytes.toList()),
      "statusCode" => $int(statusCode),
      "headers" => $Map.wrap(headers.map((k, v) => $MapEntry.wrap(MapEntry($String(k), $String(v))))),
      "contentLength" => contentLength != null ? $int(contentLength!) : $null(),
      _ => null,
    };
  }

  void $setProperty(Runtime runtime, String identifier, $Value value) {
    throw UnimplementedError('Response is immutable');
  }

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);

  @override
  Response get $reified => $value;

  @override
  String get body => $value.body;

  @override
  Uint8List get bodyBytes => $value.bodyBytes;

  @override
  int? get contentLength => $value.contentLength;

  @override
  Map<String, String> get headers => $value.headers;

  @override
  bool get isRedirect => $value.isRedirect;

  @override
  bool get persistentConnection => $value.persistentConnection;

  @override
  String? get reasonPhrase => $value.reasonPhrase;

  @override
  BaseRequest? get request => $value.request;

  @override
  int get statusCode => $value.statusCode;
}
