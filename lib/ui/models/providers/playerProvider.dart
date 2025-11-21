import 'dart:io';

import 'package:animestream/core/anime/providers/types.dart';
import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/extractQuality.dart';
import 'package:animestream/ui/models/providers/playerDataProvider.dart';
import 'package:flutter/material.dart';

import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/ui/models/playerControllers/videoController.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Handle the core player stuff
class PlayerProvider extends ChangeNotifier {
  final VideoController _controller;

  final bool _isOffline;

  PlayerProviderState _state;

  PlayerProvider(this._controller, this._isOffline)
      : _state = PlayerProviderState(
          playerState: PlayerState.paused,
          showSubs: false,
          speed: 1,
          volume: 1,
          controlsVisible: true,
          wakelockEnabled: false,
          currentViewMode: ViewMode.fit,
          pip: false,
        );

  VideoController get controller => _controller;

  PlayerProviderState get state => _state;

  bool get isOffline => _isOffline;

  List<double> get playbackSpeeds => [
        1,
        1.25,
        1.5,
        1.75,
        2,
        if ((currentUserSettings?.enableSuperSpeeds ?? false) && !Platform.isWindows) ...[4, 5, 8, 10]
      ];

  /// Play a media
  Future<void> playVideo(
    String url, {
    required VideoStream currentStream,
    bool offline = false,
    bool preserveProgress = false,
    // List<VideoStream>? streams,
  }) async {
    int? seekTime = null;
    if (preserveProgress) {
      seekTime = _controller.position ?? 0;
      await _controller.pause();
    }
    await _controller.initiateVideo(url, headers: currentStream.customHeaders, offline: offline);

    if (seekTime != null) await _controller.seekTo(Duration(milliseconds: seekTime));
  }

  /// Fast forward / Seek n seconds
  Future<void> fastForward(int seekDuration) async {
    final currentPosition = (_controller.position ?? 0) ~/ 1000;
    final duration = (_controller.duration ?? 0) ~/ 1000;

    if (currentPosition + seekDuration <= 0) {
      await _controller.seekTo(Duration.zero);
    } else if (currentPosition + seekDuration >= duration) {
      await _controller.seekTo(Duration(milliseconds: _controller.duration! - 500));
    } else {
      await _controller.seekTo(Duration(seconds: currentPosition + seekDuration));
    }
  }

  /// It just manages the state of wakelock according to video play status
  void handleWakelock() async {
    if ((_controller.isPlaying ?? false) && !_state.wakelockEnabled) {
      await WakelockPlus.enable();
      _state = _state.copyWith(wakelockEnabled: true);
      debugPrint("wakelock enabled");
    } else if (!(_controller.isPlaying ?? false) && _state.wakelockEnabled) {
      await WakelockPlus.disable();
      _state = _state.copyWith(wakelockEnabled: false);
      debugPrint("wakelock disabled");
    }
  }

  /// tweak the video volume
  void updateVolume(double vol) {
    _state = _state.copyWith(volume: vol);
    _controller.setVolume(vol);
    notifyListeners();
  }

  void updatePlayState(PlayerState playState) {
    _state = _state.copyWith(playerState: playState);
    notifyListeners();
  }

  /// Toggle visibility of controls
  void toggleControlsVisibility({ bool? action = null}) {
    _state = _state.copyWith(controlsVisible: action ?? !_state.controlsVisible);
    notifyListeners();
  }

  /// Toggle subtitle visibility
  void toggleSubs({bool? action = null}) {
    _state = _state.copyWith(showSubs: action ?? !_state.showSubs);
    notifyListeners();
  }

  /// Index for keeping track of view mode
  int viewModeIndex = 0;

  /// Cycle between view modes
  void cycleViewMode() {
    viewModeIndex = (viewModeIndex + 1) % viewModes.length;
    _state = _state.copyWith(currentViewMode: (viewModes[viewModeIndex]));
    _controller.setFit(_state.currentViewMode.value);
    notifyListeners();
  }

  /// Set pip mode
  Future<void> setPip(bool val) async {
    print("[PLAYER] set pip: $val");
    _state = _state.copyWith(pip: val);
    await controller.setPip(val);
    notifyListeners();
  }

  /// Set playback speed
  void setSpeed(double val) {
    _state = _state.copyWith(speed: val);
    _controller.setSpeed(val);
    notifyListeners();
  }

  Future<void> setQuality(QualityStream qs) async {
    _controller.setQuality(qs);
    notifyListeners();
  }

  /// Plays an episode from preloaded episode from the data provider
  void playPreloadedEpisode(PlayerDataProvider dataProvider) async {
    //just return if episode ended and next video is being loaded or the episode is the last one
    if (dataProvider.state.currentEpIndex + 1 >= dataProvider.epLinks.length /**add autonext*/) {
      return;
    }
    // calledAutoNext = true;
    if (dataProvider.state.preloadedSources.isNotEmpty) {
      //try to get the preferred source otherwise use the first source from the list
      final preferredServerLink = dataProvider.state.preloadedSources
          .where(
            (source) => source.server == dataProvider.state.currentStream.server,
          )
          .toList();
      print("${preferredServerLink}");

      final src = preferredServerLink.isNotEmpty ? preferredServerLink[0] : dataProvider.state.preloadedSources[0];

      dataProvider.update(dataProvider.state.copyWith(
        streams: dataProvider.state.preloadedSources,
        currentStream: src,
        currentEpIndex: dataProvider.state.currentEpIndex + 1,
        preloadStarted: false,
        preloadedSources: [],
      ));

      await dataProvider.extractCurrentStreamQualities();

      final q = dataProvider.getPreferredQualityStreamFromQualities();

      dataProvider.updateCurrentQuality(q);

      // Start the video and set the preffered quality
      await controller.initiateVideo(src.link, headers: src.customHeaders);

      controller.setQuality(q);
    } else {
      // showModalBottomSheet(
      //   context: context,
      //   backgroundColor: appTheme.modalSheetBackgroundColor,
      //   builder: (context) {
      //     return CustomControlsBottomSheet(
      //       getEpisodeSources: widget.episode['getEpisodeSources'],
      //       currentSources: currentSources,
      //       playVideo: playVideo,
      //       next: true,
      //       epLinks: widget.episode['epLinks'],
      //       currentEpIndex: currentEpIndex,
      //       refreshPage: widget.refreshPage,
      //       updateCurrentEpIndex: updateCurrentEpIndex,
      //     );
      //   },
      // );
    }
  }
}

class PlayerProviderState {
  final PlayerState playerState;
  final bool showSubs;
  final double speed;
  final double volume;
  final bool controlsVisible;
  final bool wakelockEnabled;
  final ViewMode currentViewMode;
  final bool pip;

  PlayerProviderState({
    required this.playerState,
    required this.showSubs,
    required this.speed,
    required this.volume,
    required this.controlsVisible,
    required this.wakelockEnabled,
    required this.currentViewMode,
    required this.pip,
  });

  PlayerProviderState copyWith({
    PlayerState? playerState,
    bool? showSubs,
    double? speed,
    double? volume,
    bool? controlsVisible,
    bool? wakelockEnabled,
    ViewMode? currentViewMode,
    bool? pip,
  }) {
    return PlayerProviderState(
      playerState: playerState ?? this.playerState,
      showSubs: showSubs ?? this.showSubs,
      speed: speed ?? this.speed,
      volume: volume ?? this.volume,
      controlsVisible: controlsVisible ?? this.controlsVisible,
      wakelockEnabled: wakelockEnabled ?? this.wakelockEnabled,
      currentViewMode: currentViewMode ?? this.currentViewMode,
      pip: pip ?? this.pip,
    );
  }
}
