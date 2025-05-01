import 'package:animestream/core/anime/providers/transformer.dart';
import 'package:animestream/core/anime/providers/animeProvider.dart';
import 'package:animestream/core/anime/providers/types.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/dart_eval_extensions.dart';
import 'package:dart_eval/stdlib/core.dart';

class $AnimeProvider$bridge with $Bridge<AnimeProvider> implements AnimeProvider {
  static final $type = BridgeTypeSpec("package:provins/classes.dart", "AnimeProvider").ref;

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
      'getAnimeEpisodeLink': BridgeFunctionDef(
              returns: CoreTypes.future.refWith([
        CoreTypes.list.refWith([CoreTypes.map.ref])
      ]).annotate)
          .asMethod,
      'getStreams': BridgeFunctionDef(returns: BridgeTypeAnnotation(CoreTypes.voidType.ref), params: [
        'episodeId'.param(CoreTypes.string.ref.annotate),
        'update'.param(CoreTypes.function.ref.annotate),
        'dub'.paramOptional(CoreTypes.bool.ref.annotate),
        'metadata'.paramOptional(CoreTypes.string.ref.annotate),
      ]).asMethod,
      'getDownloadSources': BridgeFunctionDef(returns: BridgeTypeAnnotation(CoreTypes.voidType.ref), params: [
        'episodeId'.param(CoreTypes.string.ref.annotate),
        'update'.param(CoreTypes.function.ref.annotate),
        'dub'.paramOptional(CoreTypes.bool.ref.annotate),
        'metadata'.paramOptional(CoreTypes.string.ref.annotate),
      ]).asMethod,
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
  Future<List<Map<String, dynamic>>> getAnimeEpisodeLink(String aliasId, {bool dub = false}) async {
    final res = await $_invoke("getAnimeEpisodeLink", [$String(aliasId), $bool(dub)]);
    return TypeTransformer.transformToMap(res);
  }

  @override
  Future<void> getDownloadSources(String episodeId, void Function(List<VideoStream> p1, bool p2) update,
      {bool dub = false, String? metadata}) async {
    $Value? _update(Runtime runtime, $Value? target, List<$Value?> args) {
      final streams = (runtime.args[3] as $List).$value.cast<VideoStream>();
      final finished = (runtime.args[4] as $bool).$value;
      // print(streams);
      update(streams, finished);
      return $null();
    }

    final updateWrapped = $Function(_update);

    return await $_invoke("getDownloadSources", [
      $String(episodeId),
      updateWrapped,
      $bool(dub),
      metadata != null ? $String(metadata) : $null(),
    ]);
  }

  @override
  Future<void> getStreams(String episodeId, void Function(List<VideoStream> p1, bool p2) update,
      {bool dub = false, String? metadata}) async {
    $Value? _update(Runtime runtime, $Value? target, List<$Value?> args) {
      final streams = (runtime.args[3] as $List).$value.cast<VideoStream>();
      final finished = (runtime.args[4] as $bool).$value;
      // print(streams);
      update(streams, finished);
      return $null();
    }

    final updateWrapped = $Function(_update);

    return await $_invoke("getStreams", [
      $String(episodeId),
      updateWrapped,
      $bool(dub),
      metadata != null ? $String(metadata) : $null(),
    ]);
  }

  @override
  Future<List<Map<String, String?>>> search(String query) async {
    final searchRes = await $_invoke("search", [$String(query)]);
    return TypeTransformer.transformToMap(searchRes);
  }
}
