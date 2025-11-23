import 'package:animestream/core/anime/providers/types.dart';
import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/extractQuality.dart';
import 'package:animestream/core/commons/utils.dart';
import 'package:animestream/core/data/preferences.dart';
import 'package:animestream/core/database/types.dart';
import 'package:animestream/ui/models/sources.dart';
import 'package:animestream/ui/models/widgets/subtitles/subtitleSettings.dart';
import 'package:flutter/material.dart';

/// Handle the state of player. manages datas like quality, servers etc..
class PlayerDataProvider extends ChangeNotifier {
  PlayerDataProviderState _state;
  List<EpisodeDetails> epLinks;
  String showTitle; // Title of the anime
  String? coverImageUrl;
  int showId; // Id of the anime
  String selectedSource;
  int startIndex; // Index of episode to start from
  List<AlternateDatabaseId> altDatabases;
  double? lastWatchDuration;
  bool preferDubs;

  PlayerDataProvider({
    required List<VideoStream> initialStreams,
    required VideoStream initialStream,
    required this.epLinks,
    required this.showTitle,
    required this.selectedSource,
    required this.showId,
    required this.startIndex,
    required this.altDatabases,
    required this.lastWatchDuration,
    this.coverImageUrl, // just for presence updation
    this.preferDubs = false,
  }) : _state = PlayerDataProviderState(
          streams: initialStreams,
          currentStream: initialStream,
          controlsLocked: false,
          qualities: [],
          currentQuality: QualityStream.paceholder(),
          audioTracks: [],
          currentAudioTrack: AudioStream.placeholder(),
          currentEpIndex: startIndex,
          preloadStarted: false,
          preloadedSources: [],
          currentTimeStamp: '00:00',
          maxTimeStamp: '00:00',
          preferredServer: selectedSource,
          sliderValue: 0,
        );

  PlayerDataProviderState get state => _state;

  late SubtitleSettings subtitleSettings;

  /// Call this to refresh/init subs settings
  void initSubsettings() => UserPreferences.getUserPreferences().then((val) {
        subtitleSettings = val.subtitleSettings ?? SubtitleSettings();
        _state = _state.copyWith(subsInited: true);
        notifyListeners();
      });

  /// Get and store the qualities and audio available for the current stream
  Future<void> extractCurrentStreamQualities() async {
    final url = _state.currentStream.url;
    final headers = _state.currentStream.customHeaders;
    String? mime;
    if(!url.contains(RegExp(r'\.(mkv|mp4|mov|webm|dash|m3u|m3u8)', caseSensitive: false))) {
      //get mime if none is mentioned
      mime = await getMediaMimeType(url, headers);
      print(mime);
    }
    if (url.contains(".m3u8") || (mime != null && mime.contains("mpegurl"))) {
      final master = await parseMasterPlaylist(url, customHeader: headers);
      _state = _state.copyWith(qualities: master.qualityStreams, audioTracks: master.audioStreams);
    } else {
      _state = _state.copyWith(
        qualities: [
          QualityStream(url: url, resolution: 'default', quality: _state.currentStream.quality)
        ],
      );
    }
    notifyListeners();
    print("Available Qualities: ${state.qualities}");
  }

  /// Selects the preferred quality stream from available qualities, if it exists. Just a small helper
  QualityStream getPreferredQualityStreamFromQualities() {
    return _state.qualities
            .where((it) => it.quality == (currentUserSettings?.preferredQuality ?? '720p'))
            .firstOrNull ??
        _state.qualities[0];
  }

  /// Update the state of current quality
  void updateCurrentQuality(QualityStream quality) {
    _state = _state.copyWith(currentQuality: quality);
    notifyListeners();
  }

  /// Update the current audio track!
  void updateCurrentAudioTrack(AudioStream track) {
    _state = _state.copyWith(currentAudioTrack: track);
    notifyListeners();
  }

  /// Update the state of streams
  void updateStreams(List<VideoStream> streams) {
    _state = _state.copyWith(streams: streams);
    notifyListeners();
  }

  /// Update the state of current stream
  void updateCurrentStream(VideoStream stream) {
    _state = _state.copyWith(currentStream: stream);
    notifyListeners();
  }

  /// Update the state of preloaded sources
  void updatePreloadSources(List<VideoStream> sources) {
    _state = _state.copyWith(preloadedSources: sources);
    notifyListeners();
  }

  /// Update the state of currentEpIndex
  void updateCurrentEpIndex(int newIndex) {
    _state = _state.copyWith(currentEpIndex: newIndex, preloadStarted: false, preloadedSources: []);
    notifyListeners();
  }

  /// Toggle control lock
  void toggleControlsLock() {
    _state = _state.copyWith(controlsLocked: !_state.controlsLocked);
    notifyListeners();
  }

  /// Update the state of time stamps
  void updateTimeStamps(String current, String max) {
    _state = _state.copyWith(
      currentTimeStamp: current,
      maxTimeStamp: max,
    );
    notifyListeners();
  }

  /// Update slider value
  void updateSliderValue(int val) {
    _state = _state.copyWith(sliderValue: val);
    notifyListeners();
  }

  /// Load the sources for streaming of next episode
  void preloadNextEpisode() async {
    // Just return if its the last episode!
    if (_state.currentEpIndex + 1 >= epLinks.length) {
      _state = _state.copyWith(
        preloadStarted: true, // setting to true to avoid unwanted repeated calls
      );
      return;
    }

    _state = _state.copyWith(preloadStarted: true, preloadedSources: []);

    final index = _state.currentEpIndex + 1 == epLinks.length ? null : _state.currentEpIndex + 1;
    if (index == null) {
      print("On the final episode. No preloads available");
      return;
    }
    List<VideoStream> srcs = [];
    //its actually the getStreams function!
    await SourceManager().getStreams(selectedSource, epLinks[index].episodeLink,
        dub: preferDubs, metadata: epLinks[index].metadata, (list, finished) {
      srcs = srcs + list;
      if (finished) {
        _state = _state.copyWith(preloadedSources: srcs);
        print("[PlAYER] PRELOAD FINISHED FOUND ${srcs.length} SERVERS");
      }
    });
  }

  /// Update subtitle settings
  void updateSubtitleSettings(SubtitleSettings settings) {
    subtitleSettings = settings;
  }

  /// Update any value from state
  void update(PlayerDataProviderState newState) {
    _state = newState;
    notifyListeners();
  }

  // Future<void> updateDiscordPresence() async {
  //   if (!(currentUserSettings?.enableDiscordPresence ?? false)) return;
  //   return FlutterDiscordRPC.instance.setActivity(
  //       activity: RPCActivity(
  //     activityType: ActivityType.watching,
  //     details: showTitle,
  //     state: "Episode ${state.currentEpIndex + 1}",
  //     timestamps: RPCTimestamps(start: DateTime.now().millisecondsSinceEpoch),
  //     assets: RPCAssets(
  //       largeText: coverImageUrl != null ? showTitle : null,
  //       largeImage: coverImageUrl,
  //     ),
  //   ));
  // }

  // void clearDiscordPresence() {
  //   if (!(currentUserSettings?.enableDiscordPresence ?? false)) return;
  //   FlutterDiscordRPC.instance.clearActivity();
  // }
}

class PlayerDataProviderState {
  /// All available streams for the episode
  final List<VideoStream> streams;

  /// Currently playing stream
  final VideoStream currentStream;

  /// Control's lock state
  final bool controlsLocked;
  
  /// Available qualities for current stream
  final List<QualityStream> qualities;

  /// Currently selected quality
  final QualityStream currentQuality;

  /// Available audio tracks
  final List<AudioStream> audioTracks;

  /// Currently playing audio track
  final AudioStream currentAudioTrack;

  /// Current episode index (obviously)
  final int currentEpIndex;

  /// The flag to check if the preload has started
  final bool preloadStarted;

  /// Preloaded sources for next episode
  final List<VideoStream> preloadedSources;

  /// Guess what?! Current time stamp
  final String currentTimeStamp;

  /// yes.. the duration of the video as timestamp
  final String maxTimeStamp;

  /// Preferred server for streaming
  final String preferredServer;

  /// The value for the player progress slider
  final int sliderValue;

  /// Whether subtitle settings have been inited
  final bool subsInited;

  PlayerDataProviderState({
    required this.streams,
    required this.currentStream,
    required this.controlsLocked,
    required this.qualities,
    required this.currentQuality,
    required this.currentEpIndex,
    required this.preloadStarted,
    required this.preloadedSources,
    required this.currentTimeStamp,
    required this.maxTimeStamp,
    required this.preferredServer,
    required this.sliderValue,
    required this.audioTracks,
    required this.currentAudioTrack,
    this.subsInited = false,
  });

  PlayerDataProviderState copyWith({
    List<VideoStream>? streams,
    VideoStream? currentStream,
    bool? controlsLocked,
    bool? controlsVisible,
    bool? wakelockEnabled,
    List<QualityStream>? qualities,
    QualityStream? currentQuality,
    int? currentEpIndex,
    bool? preloadStarted,
    List<VideoStream>? preloadedSources,
    String? currentTimeStamp,
    String? maxTimeStamp,
    String? preferredServer,
    int? sliderValue,
    bool? subsInited,
    List<AudioStream>? audioTracks,
  AudioStream? currentAudioTrack,
  }) {
    return PlayerDataProviderState(
      streams: streams ?? this.streams,
      currentStream: currentStream ?? this.currentStream,
      controlsLocked: controlsLocked ?? this.controlsLocked,
      qualities: qualities ?? this.qualities,
      currentQuality: currentQuality ?? this.currentQuality,
      currentEpIndex: currentEpIndex ?? this.currentEpIndex,
      preloadStarted: preloadStarted ?? this.preloadStarted,
      preloadedSources: preloadedSources ?? this.preloadedSources,
      currentTimeStamp: currentTimeStamp ?? this.currentTimeStamp,
      maxTimeStamp: maxTimeStamp ?? this.maxTimeStamp,
      preferredServer: preferredServer ?? this.preferredServer,
      sliderValue: sliderValue ?? this.sliderValue,
      subsInited: subsInited ?? this.subsInited,
      audioTracks: audioTracks ?? this.audioTracks,
      currentAudioTrack: currentAudioTrack ?? this.currentAudioTrack,
    );
  }
}

class ViewMode {
  final IconData icon;
  final String desc;
  final BoxFit value;

  ViewMode({required this.icon, required this.desc, required this.value});

  static ViewMode get fit => viewModes[0];

  static ViewMode get filled => viewModes[1];

  static ViewMode get cropped => viewModes[2];
}

final List<ViewMode> viewModes = [
  ViewMode(
    icon: Icons.fullscreen,
    desc: "fit",
    value: BoxFit.contain,
  ),
  ViewMode(
    icon: Icons.zoom_out_map_rounded,
    desc: "filled",
    value: BoxFit.fill,
  ),
  ViewMode(
    icon: Icons.crop_outlined,
    desc: "cropped",
    value: BoxFit.cover,
  ),
];
