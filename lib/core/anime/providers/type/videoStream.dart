import 'package:animestream/core/anime/providers/types.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/dart_eval_extensions.dart';
import 'package:dart_eval/stdlib/core.dart';

class $VideoStream implements $Instance, VideoStream {
  static final $type = BridgeTypeSpec("package:provins/classes.dart", "VideoStream").ref;

  static final $declaration = BridgeClassDef(
    BridgeClassType($type),
    constructors: {
      '': BridgeFunctionDef(
        returns: $type.annotate,
        namedParams: [
          BridgeParameter('link', BridgeTypeAnnotation(CoreTypes.string.ref), false),
          BridgeParameter('quality', BridgeTypeAnnotation(CoreTypes.string.ref), false),
          BridgeParameter('server', BridgeTypeAnnotation(CoreTypes.string.ref), false),
          BridgeParameter('backup', BridgeTypeAnnotation(CoreTypes.bool.ref), false),
          BridgeParameter('subtitle', BridgeTypeAnnotation(CoreTypes.string.ref, nullable: true), true),
          BridgeParameter('subtitleFormat', BridgeTypeAnnotation(CoreTypes.string.ref, nullable: true), true),
          BridgeParameter('isM3u8', BridgeTypeAnnotation(CoreTypes.bool.ref), false),
          BridgeParameter('customHeaders', BridgeTypeAnnotation(CoreTypes.map.ref, nullable: true), true),
        ],
      ).asConstructor,
    },
    methods: {
      'toJson': BridgeFunctionDef(returns: CoreTypes.string.ref.annotate).asMethod,
      'toMap': BridgeFunctionDef(
              returns:
                  BridgeTypeRef(CoreTypes.map.ref.spec!, [CoreTypes.string.ref, CoreTypes.string.ref]).annotateNullable)
          .asMethod,
      'toString': BridgeFunctionDef(returns: CoreTypes.string.ref.annotate).asMethod,
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

  $VideoStream.wrap(this.$value);

  static $Value? $new(Runtime runtime, $Value? target, List<$Value?> args) {
    return $VideoStream.wrap(VideoStream(
      link: args[0]!.$value as String,
      quality: args[1]?.$value as String,
      server: args[2]?.$value as String,
      backup: args[3]?.$value as bool,
      subtitle: args[4]?.$value as String?,
      subtitleFormat: args[5]?.$value as String?,
      isM3u8: args[6]?.$value as bool,
      customHeaders: args[7]?.$reified as Map<String, String>?,
    ));
  }

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
      'toString' => __toString,
      'toJson' => __toJson,
      'toMap' => __toMap,
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

  static const $Function __toJson = $Function(_toJson);

  static $Value? _toJson(final Runtime runtime, final $Value? target, final List<$Value?> args) {
    final $t = (target?.$value as VideoStream);
    return $String($t.toJson());
  }

  @override
  Map<String, dynamic> toMap() => $value.toMap();

  static const $Function __toMap = $Function(_toMap);

  static $Value? _toMap(final Runtime runtime, final $Value? target, final List<$Value?> args) {
    final $t = (target?.$value as VideoStream);
    return $Map.wrap($t.toMap());
  }

  @override
  String toString() => $value.toString();

  static const $Function __toString = $Function(_toString);

  static $Value? _toString(final Runtime runtime, final $Value? target, final List<$Value?> args) {
    final $t = (target?.$value as VideoStream);
    return $String($t.toString());
  }
}
