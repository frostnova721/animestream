import 'package:animestream/core/anime/providers/type/anilistSearchResult.dart';
import 'package:animestream/core/data/misc.dart';
import 'package:animestream/core/database/anilist/anilist.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/dart_eval_extensions.dart';
import 'package:dart_eval/stdlib/core.dart';

class UtilPlugin extends EvalPlugin {
  @override
  void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($AnilistSearchResult.$declaration);

    // Get val function
    registry.defineBridgeTopLevelFunction(
      BridgeFunctionDeclaration(
        "package:provins/util.dart",
        "getVal",
        BridgeFunctionDef(returns: CoreTypes.future.refWith([CoreTypes.dynamic.ref]).annotate, params: [
          'key'.param(CoreTypes.string.ref.annotate),
        ]),
      ),
    );

    // Store val function
    registry.defineBridgeTopLevelFunction(
      BridgeFunctionDeclaration(
        "package:provins/util.dart",
        "storeVal",
        BridgeFunctionDef(returns: CoreTypes.future.refWith([CoreTypes.voidType.ref]).annotate, params: [
          'key'.param(CoreTypes.string.ref.annotate),
          'value'.param(CoreTypes.dynamic.ref.annotate),
        ]),
      ),
    );

    // Anilist search
    registry.defineBridgeTopLevelFunction(
      BridgeFunctionDeclaration(
        "package:provins/util.dart",
        "anilistSearch",
        BridgeFunctionDef(
            returns: CoreTypes.future.refWith([
              CoreTypes.list.refWith([$AnilistSearchResult.$type])
            ]).annotate,
            params: [
              'query'.param(CoreTypes.string.ref.annotate),
            ]),
      ),
    );
  }

  @override
  void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFunc("package:provins/util.dart", "getVal", (runtime, target, args) {
      if (args.isEmpty) throw Exception("Key required to get a corresponding value.");
      if (args[0] is $String) {
        final key = (args[0] as $String).$value;
        return $Future.wrap(getMiscVal(key).then((val) {
          return runtime.wrap(val, recursive: true);
          }));
      } else {
        throw Exception("Key should be of type \$String instead of ${args[0].runtimeType}");
      }
    });

    runtime.registerBridgeFunc("package:provins/util.dart", "storeVal", (runtime, target, args) {
      if (args.length < 2) throw Exception("Key and Value are not provided.");
      if (args[0] is $String) {
        final key = (args[0] as $String).$value;
        final val = args[1]!.$value;
        return $Future.wrap(storeMiscVal(key, val));
      } else {
        throw Exception("Key should be of type \$String instead of ${args[0].runtimeType}");
      }
    });

    runtime.registerBridgeFunc("package:provins/util.dart", "anilistSearch", (runtime, target, args) {
      if (args.isEmpty) throw Exception("Query not provided.");
      if (args[0] is $String) {
        final query = (args[0] as $String).$value;
        return $Future.wrap(Anilist().search(query).then((val) {
          final $res = val.map((e) => $AnilistSearchResult.wrap(e)).toList();
          return $List.wrap($res);
        }));
      } else {
        throw Exception("query should be of type \$String instead of ${args[0].runtimeType}");
      }
    });
  }

  @override
  String get identifier => "package:provins";
}
