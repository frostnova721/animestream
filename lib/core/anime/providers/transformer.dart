import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';

class TypeTransformer {
   static List<Map<String, String?>> transformToMap(List<dynamic> res) {
     if (res is List<$Value?>) {
    List<Map<String, String?>> result = res.map((item) {
      if (item is $Map<$Value, $Value?>) {
        return item.$reified.cast<String, String?>();
      } else {
        throw TypeError();
      }
    }).toList();
    return result;
  } else {
    throw TypeError();
  }
  }
}