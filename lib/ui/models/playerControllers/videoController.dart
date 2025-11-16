import 'dart:async';
// import 'package:av_media_player/player.dart';
// import 'package:av_media_player/widget.dart';
import 'package:animestream/core/commons/extractQuality.dart';
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

  /// Detach the listener from the controller
  void removeListener(VoidCallback cb);

  /// Set the player view mode
  void setFit(BoxFit fit);

  /// manage PiP
  Future<void> setPip(bool value);

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

  // List<QualityStream> get qualities;

  void setAudioTrack(AudioStream aud);

  void setQuality(QualityStream qs);
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
