import 'dart:async';
import 'package:animestream/core/commons/extractQuality.dart';
import 'package:animestream/ui/models/playerControllers/videoController.dart';
import 'package:fvp/mdk.dart' as mdk;
import 'package:flutter/material.dart';

class FvpWrapper implements VideoController {
  // VideoPlayerController controller = VideoPlayerController.networkUrl(Uri.parse(""));
  mdk.Player _player = mdk.Player();

  bool controllerInitialized = false;
  Timer? _timer;

  final List<VoidCallback> listeners = [];

  FvpWrapper() {
    _timer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (controllerInitialized && listeners.isNotEmpty) {
        for (var cb in listeners) {
          cb();
        }
      }
    });
  }

  @override
  String? get activeMediaUrl => _player.media;

  @override
  int? get buffered => _player.buffered();

  @override
  void dispose() {
    _timer?.cancel();
    _player.dispose();
  }

  @override
  int? get duration => _player.mediaInfo.duration;

  @override
  Widget getWidget() {
    return AspectRatio(
        aspectRatio: 16 / 9,
        child: ValueListenableBuilder(
          valueListenable: _player.textureId,
          builder: (context, value, child) {
            return value != null
                ? Texture(
                    textureId: value,
                  )
                : Container();
          }
        ));
  }


  @override
  Future<void> initiateVideo(String url, {Map<String, String>? headers = null, bool offline = false}) async {
    if (controllerInitialized) {
      _player.state = mdk.PlaybackState.stopped;
      controllerInitialized = false;
    }

    if (headers != null && headers.isNotEmpty) {
      final headerStr = headers.entries.map((e) => '${e.key}: ${e.value}').join('\r\n') + '\r\n';
      _player.setProperty('avio.headers', headerStr);
      _player.setProperty('headers', headerStr);
    }

    _player.media = url;
    controllerInitialized = true;

    await _player.prepare();
    await _player.updateTexture();
    _player.state = mdk.PlaybackState.playing;
  }

  @override
  bool? get isBuffering => _player.mediaStatus.test(mdk.MediaStatus.buffering);

  @override
  bool? get isInitialized => _player.mediaStatus.test(mdk.MediaStatus.prepared);

  @override
  bool? get isPlaying => _player.state == mdk.PlaybackState.playing;

  @override
  Future<void> pause() async {
     _player.state = mdk.PlaybackState.paused;
  }

  @override
  Future<void> play() async {
    _player.state = mdk.PlaybackState.playing;
  }

  @override
  int? get position => _player.position;

  @override
  void addListener(VoidCallback cb) {
    listeners.add(cb);
  }

  @override
  void removeListener(VoidCallback cb) {
    listeners.remove(cb);
  }

  @override
  Future<void> seekTo(Duration duration) async {
    final wasPlaying = _player.state == mdk.PlaybackState.playing;
    _player.state = mdk.PlaybackState.paused;
    await _player.seek(
      position: duration.inMilliseconds,
      flags: const mdk.SeekFlag(mdk.SeekFlag.defaultFlags)
    );
    if (wasPlaying) {
      _player.state = mdk.PlaybackState.playing;
    }
  }

  @override
  void setAudioTrack(AudioStream aud) async {
    print("Setting audio track: ${aud.language}");
    if (aud.url != "placeholder" && aud.url.isNotEmpty) {
      _player.setMedia(aud.url, mdk.MediaType.audio);
    } else {
      final audioTracks = _player.mediaInfo.audio;
      if (audioTracks != null) {
        for (var track in audioTracks) {
          final lang = track.metadata['language'] ?? track.metadata['LANGUAGE'];
          if (lang == aud.language || track.index.toString() == aud.groupId) {
            _player.activeAudioTracks = [track.index];
            return;
          }
        }
      }
    }
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
    await initiateVideo(qs.url,offline: false);
  }

  @override
  Future<void> setSpeed(double speed)async {
    _player.playbackRate = speed;
  }

  @override
  Future<void> setVolume(double volume) async {
    _player.volume = volume;
  }

  @override
  double? get volume => _player.volume;
}
