import 'dart:typed_data';

class DownloadingItem {
  final int id;
  bool downloading;
  
  DownloadingItem({required this.id, required this.downloading});
}

class BufferItem {
  final int index;
  final Uint8List buffer;

  BufferItem({required this.index, required this.buffer});
}