import 'dart:io';

import 'package:animestream/core/commons/extractQuality.dart';
import 'package:animestream/ui/models/playerControllers/videoController.dart';
import 'package:flutter/material.dart';
import 'package:video_player_win/video_player_win.dart';

class VideoPlayerWindowsWrapper implements VideoController {
  WinVideoPlayerController controller = WinVideoPlayerController.networkUrl(Uri.parse(""));

  final List<VoidCallback> _listeners = [];

  @override
  Future<void> initiateVideo(String url, {Map<String, String>? headers, bool offline = false}) async {
    final vol = controller.value.volume;
    //kill the player and create a new instance :)
    await controller.dispose();

    // wait some time for proper disposal.
    await Future.delayed(Duration(milliseconds: 100));
    controller = offline
        ? WinVideoPlayerController.file(File(url))
        : WinVideoPlayerController.networkUrl(Uri.parse(url), httpHeaders: headers ?? {});
    await controller.initialize();
    for (final listener in _listeners) {
      controller.addListener(listener);
    }
    await controller.setVolume(vol); //Restore the previously set volume
    await controller.play();
  }

  @override
  bool? get isBuffering => controller.value.isBuffering;

  @override
  bool? get isPlaying => controller.value.isPlaying;

  @override
  int? get position => controller.value.position.inMilliseconds;

  @override
  int? get duration => controller.value.duration.inMilliseconds;

  @override
  String? get activeMediaUrl => controller.dataSource;

  @override
  double? get volume => controller.value.volume;

  @override
  bool? get isInitialized => controller.value.isInitialized;

  @override
  Future<void> pause() {
    return controller.pause();
  }

  @override
  Future<void> play() {
    return controller.play();
  }

  @override
  Future<void> seekTo(Duration duration) {
    return controller.seekTo(duration);
  }

  @override
  Future<void> setSpeed(double speed) async {
    controller.setPlaybackSpeed(speed);
  }

  @override
  void dispose() async {
    return await controller.dispose();
  }

  @override
  Widget getWidget() {
    return AspectRatio(aspectRatio: 16/9,child: WinVideoPlayer(controller));
  }

  @override
  void addListener(VoidCallback cb) {
    _listeners.add(cb);
    controller.addListener(cb);
  }

  @override
  int? get buffered => null;

  @override
  void setFit(BoxFit fit) {
    return;
  }

  @override
  Future<void> setVolume(double volume) {
    return controller.setVolume(volume);
  }

  @override
  void removeListener(VoidCallback cb) {
    return controller.removeListener(cb);
  }

  @override
  Future<void> setPip(bool value) {
    throw Exception("PiP isnt supported on Windows.");
  }

  @override
  void setAudioTrack(AudioStream aud) {
    // TODO: implement setAudioTrack, not done cus WinVideoPlayerController doesnt support streams
  }

  @override
  void setQuality(QualityStream qs) {
    // TODO: implement setQuality, not done cus WinVideoPlayerController doesnt support streams
  }
  
}