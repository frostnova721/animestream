import 'package:animestream/core/database/anilist/types.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/dart_eval_extensions.dart';
import 'package:dart_eval/stdlib/core.dart';

class $AnilistSearchResult implements $Instance, AnilistSearchResult {
  @override
  final AnilistSearchResult $value;

  $AnilistSearchResult.wrap(this.$value);

  static final $type = BridgeTypeRef(BridgeTypeSpec("package:provins/classes.dart", "AnilistSearchResult"));

  static final $declaration = BridgeClassDef(
    BridgeClassType($type),
    constructors: {
      '': BridgeConstructorDef(BridgeFunctionDef(returns: $type.annotate)),
    },
    getters: {
      "id": BridgeFunctionDef(returns: CoreTypes.int.ref.annotate).asMethod,
      "idMal": BridgeFunctionDef(returns: CoreTypes.int.ref.annotateNullable).asMethod,
      "cover": BridgeFunctionDef(returns: CoreTypes.string.ref.annotate).asMethod,
      "title": BridgeFunctionDef(returns: CoreTypes.map.ref.annotate).asMethod
    },
    wrap: true,
  );

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    return switch (identifier) {
      "id" => $int(id),
      "idMal" => idMal == null ? $null() : $int(idMal!),
      "cover" => $String(cover),
      "title" => $Map.wrap(title.map((k,v) => MapEntry($String(k), v == null ? $null() : $String(v)),)),
      "rating" => rating != null ? $double(rating!) : $null(),
      _ => throw ArgumentError("Unknown identifier $identifier"),
    };
  }

  @override
  int $getRuntimeType(Runtime runtime) {
    return runtime.lookupType($type.spec!);
  }

  @override
  AnilistSearchResult get $reified => $value;

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    throw Exception("\$AnilistSearchResult is Immutable.");
  }

  @override
  double? rating;

  @override
  String get cover => $value.cover;

  @override
  int get id => $value.id;

  @override
  int? get idMal => $value.idMal;

  @override
  Map<String, String?> get title => $value.title;
}
