import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/ui/models/playerUtils.dart';
import 'package:animestream/ui/models/watchPageUtil.dart';
import 'package:flutter/material.dart';
import 'package:animestream/core/commons/types.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class ControlsProvider with ChangeNotifier {
  final VideoController _controller;
  VideoPlayerState _state;
  final Map<String, dynamic> episode;
  final String preferredServer;
  final Function(int) updateWatchProgress;
  final Function(int, Stream) refreshPage;
  final Function(String) playAnotherEpisode;
  bool calledAutoNext = false;

  ControlsProvider({
    required VideoController controller,
    required this.episode,
    required this.preferredServer,
    required this.updateWatchProgress,
    required this.refreshPage,
    required this.playAnotherEpisode,
  })  : _controller = controller,
        _state = VideoPlayerState(
          currentEpIndex: episode['currentEpIndex'],
          sliderValue: 0,
          currentTime: '00:00',
          maxTime: '00:00',
          buffering: true,
          playerState: PlayerState.paused,
          wakelockEnabled: false,
          preloadedSources: [],
          preloadStarted: false,
          finalEpisodeReached: false,
          currentSources: [],
        ) {
    _controller.addListener(_playerEventListener);
  }

  VideoPlayerState get state => _state;
  VideoController get controller => _controller;

  void _playerEventListener() {
    // Manage currentEpIndex and clear preloads if the index changed
    if (_state.currentEpIndex != episode['currentEpIndex']) {
      _state = _state.copyWith(
        preloadedSources: [],
        preloadStarted: false,
      );
    }

    // Managing the UI updates
    int duration = ((_controller.duration ?? 0) / 1000).toInt();
    int val = ((_controller.position ?? 0) / 1000).toInt();

    _state = _state.copyWith(
      sliderValue: val,
      playerState: (_controller.isPlaying ?? false) ? PlayerState.playing : PlayerState.paused,
      currentTime: getFormattedTime(val),
      maxTime: getFormattedTime(duration),
      buffering: _controller.isBuffering ?? true,
    );

    notifyListeners();

    _handleWakelock();
    _handleAutoPlay();
    _handlePreloading();
  }

  void _handleWakelock() async {
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

  void _handleAutoPlay() async {
    if (!_state.finalEpisodeReached &&
        _controller.duration != null &&
        (_controller.position ?? 0) / 1000 == (_controller.duration ?? 0) / 1000) {
      if (_controller.isPlaying ?? false) {
        await _controller.pause();
      }
      await playPreloadedEpisode();
    }
  }

  void _handlePreloading() {
    final currentByTotal = (_controller.position ?? 0) / (_controller.duration ?? 0);
    if (currentByTotal * 100 >= 75 && !_state.preloadStarted && (_controller.isPlaying ?? false)) {
      preloadNextEpisode();
      updateWatchProgress(_state.currentEpIndex);
    }
  }

  Future<void> playPreloadedEpisode() async {
    if (_state.currentEpIndex + 1 >= episode['epLinks'].length || calledAutoNext) {
      return;
    }

    calledAutoNext = true;
    if (_state.preloadedSources.isNotEmpty) {
      final newIndex = _state.currentEpIndex + 1;

      final preferredServerLink = _state.preloadedSources.where((source) => source.server == preferredServer).toList();

      final src = preferredServerLink.isNotEmpty ? preferredServerLink[0] : _state.preloadedSources[0];

      refreshPage(newIndex, src);
      await playVideo(src.link);

      _state = _state.copyWith(currentEpIndex: newIndex);
    }
  }

  Future<void> preloadNextEpisode() async {
    if (_state.currentEpIndex + 1 >= episode['epLinks'].length) {
      _state = _state.copyWith(
        finalEpisodeReached: true,
        preloadStarted: true,
      );
      return;
    }

    _state = _state.copyWith(preloadStarted: true, preloadedSources: []);

    List<Stream> srcs = [];
    await episode['getEpisodeSources'](
      episode['epLinks'][_state.currentEpIndex + 1],
      (list, finished) {
        srcs = srcs + list;
        if (finished) {
          _state = _state.copyWith(preloadedSources: srcs);
          debugPrint("[PLAYER] PRELOAD FINISHED FOUND ${srcs.length} SERVERS");
        }
      },
    );
  }

  Future<void> playVideo(String url, {bool preserveProgress = false}) async {
    _state = _state.copyWith(preloadedSources: [], sliderValue: 0);
    await playAnotherEpisode(url);
    _state = _state.copyWith(
      preloadStarted: false,
    );
    calledAutoNext = false;
  }

  void fastForward(int seekDuration) async {
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

  void updateCurrentEpIndex(int updatedIndex) {
    _state = _state.copyWith(currentEpIndex: updatedIndex, sliderValue: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class VideoPlayerState {
  final int currentEpIndex;
  final int sliderValue;
  final String currentTime;
  final String maxTime;
  final bool buffering;
  final PlayerState playerState;
  final bool wakelockEnabled;
  final List<Stream> preloadedSources;
  final bool preloadStarted;
  final bool finalEpisodeReached;
  final List<Stream> currentSources;

  VideoPlayerState({
    required this.currentEpIndex,
    required this.sliderValue,
    required this.currentTime,
    required this.maxTime,
    required this.buffering,
    required this.playerState,
    required this.wakelockEnabled,
    required this.preloadedSources,
    required this.preloadStarted,
    required this.finalEpisodeReached,
    required this.currentSources,
  });

  VideoPlayerState copyWith({
    int? currentEpIndex,
    int? sliderValue,
    String? currentTime,
    String? maxTime,
    bool? buffering,
    PlayerState? playerState,
    bool? wakelockEnabled,
    List<Stream>? preloadedSources,
    bool? preloadStarted,
    bool? finalEpisodeReached,
    List<Stream>? currentSources,
  }) {
    return VideoPlayerState(
      currentEpIndex: currentEpIndex ?? this.currentEpIndex,
      sliderValue: sliderValue ?? this.sliderValue,
      currentTime: currentTime ?? this.currentTime,
      maxTime: maxTime ?? this.maxTime,
      buffering: buffering ?? this.buffering,
      playerState: playerState ?? this.playerState,
      wakelockEnabled: wakelockEnabled ?? this.wakelockEnabled,
      preloadedSources: preloadedSources ?? this.preloadedSources,
      preloadStarted: preloadStarted ?? this.preloadStarted,
      finalEpisodeReached: finalEpisodeReached ?? this.finalEpisodeReached,
      currentSources: currentSources ?? this.currentSources,
    );
  }
}
