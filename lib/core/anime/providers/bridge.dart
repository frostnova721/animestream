
import 'package:animestream/core/anime/providers/transformer.dart';
import 'package:animestream/core/anime/providers/types.dart';
import 'package:animestream/core/commons/types.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/dart_eval_extensions.dart';
import 'package:dart_eval/stdlib/core.dart';

class $AnimeProvider$bridge with $Bridge<AnimeProvider> implements AnimeProvider {
  static final $type = BridgeTypeSpec("package:test/main.dart", "AnimeProvider").ref;

  static final $declaration = BridgeClassDef(
    BridgeClassType($type, isAbstract: true),
    constructors: {
      '': BridgeFunctionDef(returns: $type.annotate).asConstructor,
    },
    methods: {
      'search': BridgeFunctionDef(
        returns: CoreTypes.list.refWith([CoreTypes.map.ref]).annotate,
        params: ['query'.param(CoreTypes.string.ref.annotate)],
      ).asMethod,
      // 'getAnimeEpisodeLink': BridgeFunctionDef(returns: CoreTypes.list.ref.annotate, ).asMethod,
    },
    getters: {
      'providerName': BridgeMethodDef(isStatic: false, BridgeFunctionDef(returns: CoreTypes.string.ref.annotate)),
    },
    bridge: true,
  );

  static $Value? $new(Runtime runtime, $Value? target, List<$Value?> args) {
    return $AnimeProvider$bridge();
  }

  @override
  $Value? $bridgeGet(String identifier) {
     switch (identifier) {
      case 'providerName':
        return $String(providerName);
      default: 
        throw UnimplementedError(
      'Cannot get property "$identifier" on AnimeProvider',
    );
    }
  }

  @override
  void $bridgeSet(String identifier, $Value value) {
    throw UnimplementedError("Cannot set property for abstract class $identifier");
  }

  @override
  String get providerName => $_get("providerName");

  @override
  Future<List<String>> getAnimeEpisodeLink(String aliasId) => $_invoke("getAnimeEpisodeLink", [$String(aliasId)]);

  @override
  Future<void> getDownloadSources(String episodeUrl, Function(List<VideoStream> p1, bool p2) update) {
    throw UnimplementedError("Get download sources not implemeted");
  }

  @override
  Future<void> getStreams(String episodeId, Function(List<VideoStream> p1, bool p2) update) {
   throw UnimplementedError("Get streams not implemented!");
    // $_invoke("getStreams", [
      // $String(episodeId),
    // ]);
  }

  @override
  Future<List<Map<String, String?>>> search(String query) async {
    final searchRes = await $_invoke("search", [$String(query)]);
    return TypeTransformer.transformSearchResults(searchRes);
    }
}