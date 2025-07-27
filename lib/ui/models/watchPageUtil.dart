import 'dart:async';
import 'dart:io';

import 'package:animestream/ui/models/widgets/player/playerUtils.dart';
// import 'package:av_media_player/player.dart';
// import 'package:av_media_player/widget.dart';
import 'package:better_player/better_player.dart';
import 'package:video_player_win/video_player_win.dart';
import 'package:flutter/material.dart';

class Player extends StatelessWidget {
  late final VideoController controller;
  Player(VideoController controller) {
    this.controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Center(child: controller.getWidget());
  }
}

abstract class VideoController {
  /// Play the paused media
  Future<void> play();

  /// Pause the currently playing media
  Future<void> pause();

  // initiate a source
  Future<void> initiateVideo(String url, {Map<String, String>? headers = null, bool offline = false});

  /// Retuns the Widget of the player
  Widget getWidget();

  /// Seek the media to a particular position
  Future<void> seekTo(Duration duration);

  /// Set the playback speeds.
  /// upto 2x for windows & 10x for android
  Future<void> setSpeed(double speed);

  /// Set volume of the media.
  /// Range: 0 to 1
  Future<void> setVolume(double volume);

  void dispose();

  /// Add a listener for videoplayer controller
  void addListener(VoidCallback cb);

  void removeListener(VoidCallback cb);

  void setFit(BoxFit fit);

  /// Playing state of the VideoPlayer
  bool? get isPlaying;

  /// Buffering state of the VideoPlayer
  bool? get isBuffering;

  /// Position of the video in milliseconds
  int? get position;

  /// Total duration of the video in milliseconds
  int? get duration;

  /// Buffered duration, in milliseconds. Returns null for windows
  int? get buffered;

  /// Volume level, a value between 0 and 1
  double? get volume;

  /// Url of currently playing media
  String? get activeMediaUrl;

  /// Initialisation status of player
  bool? get isInitialized;
}

class BetterPlayerWrapper implements VideoController {
  late BetterPlayerController controller = BetterPlayerController(_config);

  final List<VoidCallback?> listeners = [];

  static final _config = BetterPlayerConfiguration(
    aspectRatio: 16 / 9,
    fit: BoxFit.contain,
    expandToFill: true,
    autoPlay: true,
    autoDispose: true,
    controlsConfiguration: BetterPlayerControlsConfiguration(showControls: false),
  );

  @override
  Future<void> initiateVideo(String url, {Map<String, String>? headers, bool offline = false}) async {
    final ds = offline ? BetterPlayerDataSource.file(url) : await dataSourceConfig(url, headers: headers);
    return await controller.setupDataSource(ds);
  }

  @override
  bool? get isBuffering => controller.isBuffering();

  @override
  bool? get isPlaying => controller.isPlaying();

  @override
  int? get position => controller.videoPlayerController?.value.position.inMilliseconds;

  @override
  int? get duration => controller.videoPlayerController?.value.duration?.inMilliseconds;

  @override
  int? get buffered => controller.videoPlayerController?.value.buffered.lastOrNull?.end.inSeconds;

  @override
  double? get volume => controller.videoPlayerController?.value.volume;

  @override
  String? get activeMediaUrl => controller.betterPlayerDataSource?.url;

  @override
  bool? get isInitialized => controller.isVideoInitialized();

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
    controller.setSpeed(speed);
  }

  @override
  void dispose() {
    return controller.dispose();
  }

  @override
  Widget getWidget() {
    return BetterPlayer(controller: controller);
  }

  @override
  void addListener(VoidCallback cb) {
    listeners.add(cb);
    controller.videoPlayerController?.addListener(cb);
  }

  @override
  void setFit(BoxFit fit) {
    return controller.setOverriddenFit(fit);
  }

  @override
  Future<void> setVolume(double volume) {
    return controller.setVolume(volume);
  }

  @override
  void removeListener(VoidCallback cb) {
    return controller.videoPlayerController?.removeListener(cb);
  }
}

class VideoPlayerWindowsWrapper implements VideoController {
  WinVideoPlayerController controller = WinVideoPlayerController.network("");

  final List<VoidCallback> _listeners = [];

  @override
  Future<void> initiateVideo(String url, {Map<String, String>? headers, bool offline = false}) async {
    final vol = controller.value.volume;
    //kill the player and create a new instance :)
    await controller.dispose();

    // wait some time for proper disposal.
    await Future.delayed(Duration(milliseconds: 100));
    controller = offline ? WinVideoPlayerController.file(File(url)) : WinVideoPlayerController.network(url);
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
    return WinVideoPlayer(controller);
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
}

// un comment this class if package is installed to run it! Im not using this pakcage cus it mandates the minSdk 26 for android

// class AvPlayerWrapper implements VideoController {
//   final AvMediaPlayer controller = AvMediaPlayer();

//   @override
//   Future<void> initiateVideo(String url, {Map<String, String>? headers = null}) async {
//     return controller.open(url);
//   }

//   @override
//   bool? get isBuffering => controller.loading.value;

//   @override
//   bool? get isPlaying => controller.playbackState.value == PlaybackState.playing;

//   @override
//   int? get position => controller.position.value;

//   @override
//   int? get duration => controller.mediaInfo.value?.duration;

//   @override
//   Future<void> pause() async {
//     controller.pause();
//   }

//   @override
//   Future<void> play() async {
//     controller.play();
//   }

//   @override
//   Future<void> seekTo(Duration duration) async {
//     controller.seekTo(duration.inMilliseconds);
//   }

//   @override
//   Future<void> setSpeed(double speed) async {
//     controller.setSpeed(speed);
//   }

//   @override
//   void dispose() {
//     return controller.dispose();
//   }

//   @override
//   Widget getWidget() {
//     return AvMediaView(
//       initPlayer: controller,
//       initAutoPlay: true,
//     );
//   }

//   @override
//   void addListener(VoidCallback cb) {
//     controller.loading.addListener(cb);
//   }
// }
