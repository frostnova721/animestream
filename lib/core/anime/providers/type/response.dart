import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/dart_eval_extensions.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:http/http.dart';

class $Response implements $Instance {
  final Response $value;
  
  $Response.wrap(this.$value);
  
  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    if (identifier == 'body') {
      return $String($value.body);
    } else if (identifier == 'statusCode') {
      return $int($value.statusCode);
    } else if (identifier == 'headers') {
      return $Map.wrap($value.headers);
    }
    return null;
  }
  
  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    throw UnimplementedError('Response is immutable');
  }
  
  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType(BridgeTypeSpec('package:http/http.dart', 'Response').ref.spec!);
  
  @override
  Response get $reified => $value;
}