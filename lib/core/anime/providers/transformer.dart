
class TypeTransformer {
   static List<Map<String, String?>> transformToMap(List<dynamic> res) {
     if (res is List<dynamic>) {
    List<Map<String, String?>> result = res.map((item) {
      if (item is Map<dynamic, dynamic>) {
        return item.cast<String, String?>();
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