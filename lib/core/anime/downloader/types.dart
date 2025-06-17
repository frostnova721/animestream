import 'dart:typed_data';

import 'package:flutter/material.dart';

class DownloadingItem {
  final int id;
  bool downloading;
  final String? streamLink;
  final String fileName;
  final int retryAttempts;
  final int parallelBatches;
  final Map<String, String> customHeaders;
  final String? subtitleUrl;
  
  // late int _progress;

  ValueNotifier<int> progressNotifier = ValueNotifier(0);

  int get progress => progressNotifier.value;

  set progress(int prg) {
    progressNotifier.value = prg;
  }

  DownloadingItem({
    required this.id,
    required this.downloading,
    required this.fileName,
    this.customHeaders = const {},
    this.streamLink,
    this.retryAttempts = 5,
    this.parallelBatches = 5,
    int progress = 0,
    this.subtitleUrl,
  }) {

    progressNotifier.value = progress;
  }
}

class BufferItem {
  final int index;
  final Uint8List buffer;

  BufferItem({required this.index, required this.buffer});
}
