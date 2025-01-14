import 'dart:typed_data';

class DownloadingItem {
  final int id;
  bool downloading;
  final String? streamLink;
  final String? fileName;
  final int retryAttempts;
  final int parallelBatches;

  DownloadingItem({
    required this.id,
    required this.downloading,
    this.streamLink,
    this.fileName,
    this.retryAttempts = 5,
    this.parallelBatches = 5,
  });
}

class BufferItem {
  final int index;
  final Uint8List buffer;

  BufferItem({required this.index, required this.buffer});
}
