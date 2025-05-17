import 'package:animestream/core/anime/providers/animeProvider.dart';
import 'package:animestream/core/anime/providers/types.dart';
import 'package:d4rt/d4rt.dart';

class AnimeProviderBridge {
  static final $bridger = BridgedClassDefinition(nativeType: AnimeProvider, name: "AnimeProvider", constructors: {
    '': (InterpreterVisitor? v, List<Object?> args, Map<String, Object?> namedArgs) {
      return AnimeProvider;
    }
  }, getters: {
    'providerName': (InterpreterVisitor? visitor, Object target) {
      if (target is AnimeProvider) return target.providerName;
      throw TypeError();
    },
  }, methods: {
    'search': (InterpreterVisitor? v, Object target, List<Object?> args, Map<String, Object?> namedArgs) {
      if (target is AnimeProvider) {
        final query = args[0] as String;
        return target.search(query);
      }
      throw TypeError();
    },
    'getAnimeEpisodeLink': (InterpreterVisitor? v, Object target, List<Object?> args, Map<String, Object?> namedArgs) {
      if (target is AnimeProvider) {
        final alias = args[0] as String;
        final dub = namedArgs['dub'] = args[0] as bool;
        return target.getAnimeEpisodeLink(alias, dub: dub);
      }
      throw TypeError();
    },
    'getStreams': (InterpreterVisitor? v, Object target, List<Object?> args, Map<String, Object?> namedArgs) {
      if (target is AnimeProvider) {
        final episodeId = args[0] as String;
        final updateFunc = args[1] as Future<void> Function(List<VideoStream>, bool);

        return target.getStreams(episodeId, updateFunc,
            dub: namedArgs['dub'] as bool, metadata: namedArgs['metadata'] as String?);
      }
      return TypeError();
    },
    'getDownloadSources': (InterpreterVisitor? v, Object target, List<Object?> args, Map<String, Object?> namedArgs) {
      if (target is AnimeProvider) {
        final episodeId = args[0] as String;
        final updateFunc = args[1] as Future<void> Function(List<VideoStream>, bool);

        return target.getStreams(episodeId, updateFunc,
            dub: namedArgs['dub'] as bool, metadata: namedArgs['metadata'] as String?);
      }
      return TypeError();
    },
  });

  static final videoStreamBridge = BridgedClassDefinition(nativeType: VideoStream, name: "VideoStream", constructors: {
    '': (InterpreterVisitor? v, List<Object?> args, Map<String, Object?> namedArgs) {
      return VideoStream(
        backup: namedArgs['backup'] as bool,
        isM3u8: namedArgs['isM3u8'] as bool,
        link: namedArgs['link'] as String,
        quality: namedArgs['quality'] as String,
        server: namedArgs['server'] as String,
        customHeaders: namedArgs['customHeaders'] as Map<String, String>?,
        subtitle: namedArgs['subtitle'] as String?,
        subtitleFormat: namedArgs['subtitleFormat'] as String?,
      );
    }
  }, getters: {
    'quality': (v, t) => (t as VideoStream).quality,
    'link': (v, t) => (t as VideoStream).link,
    'isM3u8': (v, t) => (t as VideoStream).isM3u8,
    'server': (v, t) => (t as VideoStream).server,
    'backup': (v, t) => (t as VideoStream).backup,
    'subtitle': (v, t) => (t as VideoStream).subtitle,
    'subtitleFormat': (v, t) => (t as VideoStream).subtitleFormat,
    'customHeaders': (v, t) => (t as VideoStream).customHeaders,
  });
}

class APWrapper extends AnimeProvider {
  final D4rt d4rt;

  APWrapper(this.d4rt);

  @override
  Future<List<Map<String, dynamic>>> getAnimeEpisodeLink(String aliasId, {bool dub = false}) {
    return (d4rt.invoke("getAnimeEpisodeLink", [aliasId], {'dub': dub}));
  }

  @override
  Future<void> getDownloadSources(String episodeUrl, Function(List<VideoStream> p1, bool p2) update,
      {bool dub = false, String? metadata}) {
    return d4rt.invoke("getDownloadSources", [episodeUrl, update], {'dub': dub, 'metadata': metadata});
  }

  @override
  Future<void> getStreams(String episodeId, Function(List<VideoStream> p1, bool p2) update,
      {bool dub = false, String? metadata}) {
    return d4rt.invoke("getStreams", [episodeId, update], {'dub': dub, 'metadata': metadata});
  }

  @override
  String get providerName => d4rt.invoke("providerName", []);

  @override
  Future<List<Map<String, String?>>> search(String query) async {
    return (await d4rt.invoke("search", [query]) as List).map((e) => (e as Map).cast<String, String?>()).toList().cast<Map<String, String?>>();
  }
}
