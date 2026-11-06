import 'dart:convert';

class VideoStream {
  /// The quality of the video stream.
  ///
  /// The format for quality is recommended to be "\<quality_string> [\<size>]".
  ///
  /// for example: "1080p [260 MB]" or "multi-quality"
  ///
  /// the size part is optional and can be omitted if unknown
  final String quality;

  /// The URL of the video. Can be a direct link to the video file or a stream playlist like m3u8 or dash
  final String url;

  /// The URL of the subtitle file, if available
  final String? subtitle;

  /// The format of the subtitle file, if available
  final String? subtitleFormat;

  /// The server name or identifier
  final String server;

  /// Whether this stream is a backup stream
  final bool backup;

  /// Wether this stream is a dub variant (defaults to false)
  final bool dub;

  /// The custom headers to be used when making requests to the video URL, optional unless required to access the stream
  final Map<String, String>? customHeaders;

  VideoStream({
    required this.quality,
    required this.url,
    required this.server,
    required this.backup,
    this.subtitleFormat = null,
    this.subtitle = null,
    this.customHeaders = null,
    this.dub = false,
  });

  @override
  String toString() {
    return 'VideoStream(quality: $quality, url: $url, subtitle: $subtitle, subtitleFormat: $subtitleFormat, server: $server, backup: $backup, dub: $dub, customHeaders: $customHeaders)';
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'quality': quality,
      'url': url,
      'subtitle': subtitle,
      'subtitleFormat': subtitleFormat,
      'server': server,
      'backup': backup,
      'dub': dub,
      'customHeaders': customHeaders,
    };
  }

  factory VideoStream.fromMap(Map<String, dynamic> map) {
    return VideoStream(
      quality: map['quality'] as String,
      url: map['url'] as String,
      subtitle: map['subtitle'] != null ? map['subtitle'] as String : null,
      subtitleFormat: map['subtitleFormat'] != null ? map['subtitleFormat'] : null,
      server: map['server'] as String,
      backup: map['backup'] as bool,
      dub: (map['dub'] ?? false) as bool,
      customHeaders:
          map['customHeaders'] != null ? Map<String, String>.from((map['customHeaders'] as Map<String, String>)) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory VideoStream.fromJson(String source) => VideoStream.fromMap(json.decode(source) as Map<String, dynamic>);
}
