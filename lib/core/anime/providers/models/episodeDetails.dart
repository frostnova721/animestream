import 'dart:convert';

class EpisodeDetails {
  /// The episode link or id to be parsed in getStreams function
  final String episodeLink;

  /// Episode number
  final int episodeNumber;

  /// Episode thumbnail url, if available
  final String? thumbnail;

  /// Episode title, if available
  final String? episodeTitle;

  /// Description about the episode. if any
  final String? description;

  /// Dub availability
  final bool? hasDub;

  /// Filler Episode
  final bool? isFiller;

  /// Additional data for processing if required in getStreams function
  final String? metadata;

  EpisodeDetails({
    required this.episodeLink,
    required this.episodeNumber,
    this.thumbnail = null,
    this.episodeTitle = null,
    this.hasDub = false,
    this.isFiller = false,
    this.metadata = null,
    this.description = null,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'episodeLink': episodeLink,
      'episodeNumber': episodeNumber,
      'thumbnail': thumbnail,
      'episodeTitle': episodeTitle,
      'hasDub': hasDub,
      'isFiller': isFiller,
      'metadata': metadata,
      'description': description,
    };
  }

  factory EpisodeDetails.fromMap(Map<String, dynamic> map) {
    final episodeNumber = map['episodeNumber'];
    final isFiller = map['isFiller'];
    return EpisodeDetails(
      episodeLink: map['episodeLink'] as String,
      episodeNumber: episodeNumber is int ? episodeNumber : int.parse(episodeNumber),
      thumbnail: map['thumbnail'] != null ? map['thumbnail'] as String : null,
      episodeTitle: map['episodeTitle'] != null ? map['episodeTitle'] as String : null,
      hasDub: map['hasDub'] != null
          ? map['hasDub'] is bool
              ? map['hasDub']
              : bool.parse(map['hasDub'])
          : null,
      isFiller: isFiller != null
          ? isFiller is bool
              ? isFiller
              : bool.parse(isFiller)
          : null,
      metadata: map['metadata'] != null ? map['metadata'] as String : null,
      description: map['description'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory EpisodeDetails.fromJson(String source) => EpisodeDetails.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'EpisodeDetails(episodeLink: $episodeLink, episodeNumber: $episodeNumber, thumbnail: $thumbnail, episodeTitle: $episodeTitle, description: $description, hasDub: $hasDub, isFiller: $isFiller, metadata: $metadata)';
  }
}
