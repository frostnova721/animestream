import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';

class TypeTransformer {
   static List<Map<String, String?>> transformSearchResults(List<dynamic> searchResult) {
     if (searchResult is List<$Value>) {
    List<Map<String, String?>> result = searchResult.map((item) {
      if (item is $Map<$Value, $Value>) {
        return item.$reified.cast<String, String?>();
      } else {
        throw TypeError();
      }
    }).toList();
    
    print(result);
    return result;
  } else {
    throw TypeError();
  }
  }  
}