import 'package:http/http.dart';

Future<String> fetch(String uri) async {
  final res = await get(Uri.parse(uri));
  return res.body;
}