import 'package:animestream/core/anime/downloader/types.dart';
import 'package:flutter/material.dart';

extension ColorExtensions on Color {
  String toHexString() {
    final alpha = (this.a * 255).toInt();
    final red = (this.r * 255).toInt();
    final green = (this.g * 255).toInt();
    final blue = (this.b * 255).toInt();

    return "${alpha.toRadixString(16).padLeft(2,'0')}${red.toRadixString(16).padLeft(2,'0')}${green.toRadixString(16).padLeft(2,'0')}${blue.toRadixString(16).padLeft(2,'0')}";
  }

  /**Returns the integer representation of the color */
  int toInt() {
    final alpha = (this.a * 255).toInt();
    final red = (this.r * 255).toInt();
    final green = (this.g * 255).toInt();
    final blue = (this.b * 255).toInt();
    return (alpha << 24) | (red << 16) | (green << 8) | blue;
  }
}

extension StringExtensions on String {
  String capitalize() {
    if(this.length < 1) return "";
    return this.replaceFirst(this[0], this[0].toUpperCase());
  }

  String capitalizeAllWords({String delimiter = " "}) {
    final words = this.split(delimiter);
    List<String> newString = [];
    for(final word in words) {
      newString.add(word.capitalize());
    }
    return newString.join(" ");
  }

  Uri? toUri() {
    return Uri.tryParse(this);
  }
}

extension DownloadStatusExtension on DownloadStatus {
  bool get isCancelled => this == DownloadStatus.cancelled;
  bool get isActive => this == DownloadStatus.queued || this == DownloadStatus.downloading;
  bool get isPaused => this == DownloadStatus.paused;
  bool get isDead => this == DownloadStatus.cancelled || this == DownloadStatus.completed || this == DownloadStatus.failed;
}

extension DownloadItemExtension on DownloadItem {
  bool get isActive => this.status.isActive;
  bool get isPaused => this.status.isPaused;
  bool get isQueued => this.status == DownloadStatus.queued;
}