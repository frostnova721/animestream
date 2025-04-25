import 'package:animestream/core/anime/providers/types.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/dart_eval_extensions.dart';
import 'package:dart_eval/stdlib/core.dart';

class $VideoStream implements $Instance, VideoStream {
  static final $type = BridgeTypeSpec("package:test/main.dart", "VideoStream").ref;

  $VideoStream.wrap(this.$value);

  static final $declaration = BridgeClassDef(
    BridgeClassType($type, isAbstract: true),
    constructors: {
      '': BridgeFunctionDef(returns: $type.annotate).asConstructor,
    },
    methods: {
      'toJson': BridgeFunctionDef(returns: CoreTypes.string.ref.annotate).asMethod,
      'toMap': BridgeFunctionDef(
              returns: BridgeTypeRef(CoreTypes.map.ref.spec!, [CoreTypes.string.ref, CoreTypes.string.ref]).annotateNullable)
          .asMethod,
    },
    getters: {
      'link': BridgeFunctionDef(returns: CoreTypes.string.ref.annotate).asMethod,
      'backup': BridgeFunctionDef(returns: CoreTypes.bool.ref.annotate).asMethod,
      'subtitle': BridgeFunctionDef(returns: CoreTypes.string.ref.annotateNullable).asMethod,
      'subtitleFormat': BridgeFunctionDef(returns: CoreTypes.string.ref.annotateNullable).asMethod,
      'customHeaders': BridgeFunctionDef(returns: CoreTypes.map.ref.annotateNullable).asMethod,
      'server': BridgeFunctionDef(returns: CoreTypes.string.ref.annotate).asMethod,
      'quality': BridgeFunctionDef(returns: CoreTypes.string.ref.annotate).asMethod,
      'isM3u8': BridgeFunctionDef(returns: CoreTypes.bool.ref.annotate).asMethod,
    },
    wrap: true,
  );

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    return switch (identifier) {
      'link' => $String($value.link),
      'isM3u8' => $bool($value.isM3u8),
      'quality' => $String($value.quality),
      'server' => $String($value.quality),
      'subtitle' => $value.subtitle != null ? $String($value.subtitle!) : null,
      'subtitleFormat' => $value.subtitleFormat != null ? $String($value.subtitleFormat!) : null,
      'backup' => $bool($value.backup),
      'customHeaders' => $value.customHeaders != null ? $Map.wrap($value.customHeaders!) : null,
      _ => throw ArgumentError("Unknown identifier $identifier"),
    };
  }

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);

  @override
  VideoStream get $reified => $value;

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    throw UnimplementedError("VideoStream is Immutable");
  }

  @override
  VideoStream $value;

  @override
  bool get backup => $value.backup;

  @override
  Map<String, String>? get customHeaders => $value.customHeaders;

  @override
  bool get isM3u8 => $value.isM3u8;

  @override
  String get link => $value.link;

  @override
  String get quality => $value.quality;

  @override
  String get server => $value.server;

  @override
  String? get subtitle => $value.subtitle;

  @override
  String? get subtitleFormat => $value.subtitleFormat;

  @override
  String toJson() => $value.toJson();

  @override
  Map<String, dynamic> toMap() => $value.toMap();
}
