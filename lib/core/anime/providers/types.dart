// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class VideoStream {
  final String quality;
  final String link;
  final String? subtitle;
  final String? subtitleFormat;
  final String server;
  final bool backup;
  final Map<String, String>? customHeaders;

  VideoStream({
    required this.quality,
    required this.link,
    required this.server,
    required this.backup,
    this.subtitleFormat = null,
    this.subtitle = null,
    this.customHeaders = null,
  });

  @override
  String toString() {
    return 'VideoStream(quality: $quality, link: $link, subtitle: $subtitle, subtitleFormat: $subtitleFormat, server: $server, backup: $backup, customHeaders: $customHeaders)';
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'quality': quality,
      'link': link,
      'subtitle': subtitle,
      'subtitleFormat': subtitleFormat,
      'server': server,
      'backup': backup,
      'customHeaders': customHeaders,
    };
  }

  factory VideoStream.fromMap(Map<String, dynamic> map) {
    return VideoStream(
      quality: map['quality'] as String,
      link: map['link'] as String,
      subtitle: map['subtitle'] != null ? map['subtitle'] as String : null,
      subtitleFormat: map['subtitleFormat'] != null ? map['subtitleFormat'] : null,
      server: map['server'] as String,
      backup: map['backup'] as bool,
      customHeaders: map['customHeaders'] != null ? Map<String, String>.from((map['customHeaders'] as Map<String, String>)) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory VideoStream.fromJson(String source) => VideoStream.fromMap(json.decode(source) as Map<String, dynamic>);
}

class EpisodeDetails {
  /// The episode link or id to be parsed in getStreams function
  final String episodeLink;

  /// Episode number
  final int episodeNumber;

  /// Episode thumbnail url, if available
  final String? thumbnail;

  /// Episode title, if available
  final String? episodeTitle;

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
      hasDub: map['hasDub'] != null ? map['hasDub'] is bool ? map['hasDub'] : bool.parse(map['hasDub']) : null,
      isFiller: isFiller != null ? isFiller is bool ? isFiller : bool.parse(isFiller) : null,
      metadata: map['metadata'] != null ? map['metadata'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory EpisodeDetails.fromJson(String source) => EpisodeDetails.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'EpisodeDetails(episodeLink: $episodeLink, episodeNumber: $episodeNumber, thumbnail: $thumbnail, episodeTitle: $episodeTitle, hasDub: $hasDub, isFiller: $isFiller, metadata: $metadata)';
  }
}
