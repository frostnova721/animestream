import 'dart:typed_data';

class DownloadingItem {
  final int id;
  bool downloading;
  final String? streamLink;
  final String? fileName;
  final int retryAttempts;
  final int parallelBatches;
  final Map<String, String> customHeaders;
  final String? subtitleUrl;

  DownloadingItem({
    required this.id,
    required this.downloading,
    this.customHeaders = const {},
    this.streamLink,
    this.fileName,
    this.retryAttempts = 5,
    this.parallelBatches = 5,
    this.subtitleUrl,
  });
}

class BufferItem {
  final int index;
  final Uint8List buffer;

  BufferItem({required this.index, required this.buffer});
}
