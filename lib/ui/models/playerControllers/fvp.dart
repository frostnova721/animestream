import 'dart:io';

import 'package:animestream/core/commons/extractQuality.dart';
import 'package:animestream/ui/models/playerControllers/videoController.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/material.dart';

class FvpWrapper implements VideoController {
  VideoPlayerController controller = VideoPlayerController.networkUrl(Uri.parse(""));

  bool controllerInitialized = false;

  final List<VoidCallback> listeners = [];

  @override
  String? get activeMediaUrl => controller.dataSource;

  @override
  int? get buffered => controller.value.buffered.lastOrNull?.end.inMilliseconds;

  @override
  void dispose() async {
    await controller.dispose();
  }

  @override
  int? get duration => controller.value.duration.inMilliseconds;

  @override
  Widget getWidget() {
    return VideoPlayer(controller);
  }

  @override
  Future<void> initiateVideo(String url, {Map<String, String>? headers = null, bool offline = false}) async {
    final vol = controllerInitialized ? controller.value.volume : 0.8;

    // kill the last controller
    if(controllerInitialized) {
      await controller.dispose();
      controllerInitialized = false;
    }

    controller = offline
        ? VideoPlayerController.file(File(url))
        : VideoPlayerController.networkUrl(Uri.parse(url), httpHeaders: headers ?? {},);

    controllerInitialized = true;

    await controller.initialize();

    for(int i=0; i<listeners.length; i++) {
      controller.addListener(listeners[i]);
    }
    await controller.setVolume(vol);
    await controller.play();
  }

  @override
  bool? get isBuffering => controller.value.isBuffering;

  @override
  bool? get isInitialized => controller.value.isInitialized;

  @override
  bool? get isPlaying => controller.value.isPlaying;

  @override
  Future<void> pause() {
    return controller.pause();
  }

  @override
  Future<void> play() {
    return controller.play();
  }

  @override
  int? get position => controller.value.position.inMilliseconds;

   @override
  void addListener(VoidCallback cb) {
    controller.addListener(cb);
    listeners.add(cb);
  }


  @override
  void removeListener(VoidCallback cb) {
    controller.removeListener(cb);
    listeners.remove(cb);
  }

  @override
  Future<void> seekTo(Duration duration) {
    return controller.seekTo(duration);
  }

  @override
  void setAudioTrack(AudioStream aud) async {
    return await controller.selectAudioTrack(aud.groupId);
  }

  @override
  void setFit(BoxFit fit) {
    throw UnimplementedError("I couldnt find the method :)");
  }

  @override
  Future<void> setPip(bool value) {
    throw Exception("PiP isnt supported natively on desktop.");
  }

  @override
  void setQuality(QualityStream qs) async {
    await initiateVideo(qs.url, headers: controller.httpHeaders, offline: false);
  }

  @override
  Future<void> setSpeed(double speed) {
    return controller.setPlaybackSpeed(speed);
  }

  @override
  Future<void> setVolume(double volume) {
    return controller.setVolume(volume);
  }

  @override
  double? get volume => controller.value.volume;
}
