// import 'package:d4rt/d4rt.dart';
// import 'package:http/http.dart';

// class HttpRegisters {
//   static void register(D4rt d4rt) {
//     // Register GET
//     d4rt.registertopLevelFunction("get",
//         (InterpreterVisitor? v, List<Object?> args, Map<String, Object?> namedArgs, List<RuntimeType>? rt) {
//       final Map<String, String> headers = (namedArgs['headers'] as Map).map(
//         (key, value) => MapEntry(key.toString(), value.toString()),
//       );
//       return get(args[0] as Uri, headers: headers);
//     });

//     // Register POST
//     d4rt.registertopLevelFunction("post",
//         (InterpreterVisitor? v, List<Object?> args, Map<String, Object?> namedArgs, List<RuntimeType>? rt) {
//       final Map<String, String> headers = (namedArgs['headers'] as Map).map(
//         (key, value) => MapEntry(key.toString(), value.toString()),
//       );
//       return post(args[0] as Uri, headers: headers, body: namedArgs['body']);
//     });

//     // Register Response class
//     d4rt.registerBridgedClass(BridgedClassDefinition(
//       nativeType: Response,
//       name: 'Response',
//       constructors: {
//         '': (visitor, positionalArgs, namedArgs) {
//           return Response;
//         },
//       },
//       getters: {
//         'statusCode': (visitor, target) => (target as Response).statusCode,
//         'body': (visitor, target) => (target as Response).body,
//         'headers': (visitor, target) => (target as Response).headers,
//         'isRedirect': (visitor, target) => (target as Response).isRedirect,
//         'reasonPhrase': (visitor, target) => (target as Response).reasonPhrase,
//         'contentLength': (visitor, target) => (target as Response).contentLength,
//         'bodyBytes': (visitor, target) => (target as Response).bodyBytes,
//         'persistentConnection': (visitor, target) => (target as Response).persistentConnection,
//         'request': (visitor, target) => (target as Response).request,
//       },
//     ));
//   }
// }
