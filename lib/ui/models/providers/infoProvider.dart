import 'package:flutter/material.dart';

import 'package:animestream/core/anime/providers/providerDetails.dart';
import 'package:animestream/core/anime/providers/types.dart';
import 'package:animestream/core/app/logging.dart';
import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/commons/utils.dart';
import 'package:animestream/core/data/animeSpecificPreference.dart';
import 'package:animestream/core/data/preferences.dart';
import 'package:animestream/core/data/types.dart';
import 'package:animestream/core/data/watching.dart';
import 'package:animestream/core/database/anilist/login.dart';
import 'package:animestream/core/data/secureStorage.dart';
import 'package:animestream/core/database/database.dart';
import 'package:animestream/core/database/simkl/login.dart';
import 'package:animestream/core/database/simkl/simkl.dart';
import 'package:animestream/core/database/handler/handler.dart';
import 'package:animestream/core/database/types.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:animestream/ui/models/sources.dart';

class InfoProvider extends ChangeNotifier {
  int id;
  InfoProvider(int id) : this.id = id;

  late DatabaseInfo _data;

  final sourceManager = SourceManager.instance;

  // Will be set in _init()
  late ProviderDetails _selectedSource;

  String? _foundName;
  String? _manualSearchQuery;

  MediaStatus? _mediaListStatus;

  List<EpisodeDetails> _epLinks = [];
  // List<VideoStream> _streamSources = [];
  // List<Map<String, String>> _qualities = [];
  List<List<Map<String, dynamic>>> _visibleEpList = [];
  List<AlternateDatabaseId> _altDatabases = [];

  int _currentPageIndex = 0;
  int _watched = 0;
  int _viewMode = 0;

  // Index of episode selected
  int? _selectedEpisodeToLoadStreams;

  Map? _lastWatchedDurationMap = {};

  bool _started = false;
  bool _epSearcherror = false;
  bool _loggedIn = false;
  bool _dataLoaded = false;
  // bool _infoPage = true;
  bool _infoLoadError = false;
  bool _preferDubs = false;

  // Getters
  bool get infoLoadError => _infoLoadError;
  bool get started => _started;
  bool get epSearcherror => _epSearcherror;
  bool get loggedIn => _loggedIn;
  bool get dataLoaded => _dataLoaded;
  // bool get infoPage => _infoPage;
  bool get preferDubs => _preferDubs;

  Map? get lastWatchedDurationMap => _lastWatchedDurationMap;

  int get watched => _watched;
  int get viewMode => _viewMode;
  int get currentPageIndex => _currentPageIndex;
  int get viewModeIndexLength => 3;
  int? get selectedEpisodeToLoadStreams => _selectedEpisodeToLoadStreams;

  // List<VideoStream> get streamSources => _streamSources;
  // List<Map<String, String>> get qualities => _qualities;
  List<List<Map<String, dynamic>>> get visibleEpList => _visibleEpList;
  List<AlternateDatabaseId> get altDatabases => _altDatabases;
  List<EpisodeDetails> get epLinks => _epLinks;

  /// Current [MediaStatus] in the user's list
  MediaStatus? get mediaListStatus => _mediaListStatus;

  /// The name found from the search in the source
  String? get foundName => _foundName;

  /// Previously used server in the respective provider
  String? get previouslyUsedServer => _previouslyUsedServer;
  String? get previouslyUsedServerQuality => _previouslyUsedServerQuality;

  /// Currently selected source
  ProviderDetails get selectedSource => _selectedSource;

  /// The Anime info
  DatabaseInfo get data => _data;

  bool _initCalled = false;

  String? aspProvider;
  String? _previouslyUsedServer, _previouslyUsedServerQuality;

  set selectedSource(ProviderDetails val) {
    _selectedSource = val;
    if (aspProvider != val.identifier) {
      aspProvider = val.identifier;
      saveAnimeSpecificPreference(
          id.toString(),
          AnimeSpecificPreference(
            preferredProvider: val.identifier,
          ));
    }
    // we just using this condition for validation (too lazy to add a field for it)
    sourceManager.useInbuiltProviders = selectedSource.version == "0.0.0.0";
    notifyListeners();
  }

  // set previouslyUsedServer(String? val) {
  //   if (_previouslyUsedServer == null && _previouslyUsedServer == val) return;
  //   _previouslyUsedServer = val;
  //   saveAnimeSpecificPreference(id.toString(), AnimeSpecificPreference(previouslyUsedServer: val)).then((v) {
  //     notifyListeners();
  //   });
  //   // notifyListeners();
  // }

  set viewMode(int newIndex) {
    _viewMode = newIndex;
    UserPreferences.saveUserPreferences(
      UserPreferencesModal(
        episodesViewMode: UserPreferencesModal.getViewModeEnum(newIndex),
      ),
    );
    notifyListeners();
  }

  set foundName(String? val) {
    _foundName = val;
    notifyListeners();
  }

  set epSearcherror(bool val) {
    _epSearcherror = val;
    notifyListeners();
  }

  set currentPageIndex(int val) {
    _currentPageIndex = val;
    notifyListeners();
  }

  set selectedEpisodeToLoadStreams(int? newIndex) {
    _selectedEpisodeToLoadStreams = newIndex;
    notifyListeners();
  }

  set preferDubs(bool val) {
    _preferDubs = val;
    UserPreferences.saveUserPreferences(
      UserPreferencesModal(
        preferDubs: val,
      ),
    );
    paginate(epLinks);
    notifyListeners();
  }

  set manualSearchQuery(String? query) {
    _manualSearchQuery = query;
    notifyListeners();
  }

  /// Called in the init state
  void init() async {
    if (_initCalled) return;
    _initCalled = true;

    // Load manualsearch query and last watch
    final asp = await getAnimeSpecificPreference(id.toString());
    _lastWatchedDurationMap = asp?.lastWatchDuration ?? {};
    _manualSearchQuery = asp?.manualSearchQuery;

    aspProvider = asp?.preferredProvider;

    _previouslyUsedServer = asp?.previouslyUsedServer;

    // Set up sources.
    final sources = sourceManager.sources;
    final matchedSource = sources
        .where((e) => e.identifier == (asp?.preferredProvider ?? currentUserSettings?.preferredProvider))
        .firstOrNull; // pick provider from last selected provider or default one
    selectedSource =
        matchedSource != null ? matchedSource : (sources.isEmpty ? sourceManager.inbuiltSources[0] : sources[0]);

    await _getInfo(id);

    await loadPreferences();

    // load em concurrently (fixes the delay in loading the progress)
    getWatched();
    getEpisodes();
  }

  /// Fetch preferences
  Future<void> loadPreferences() async {
    final preferences = await UserPreferences.getUserPreferences();
    _viewMode = UserPreferencesModal.getViewModeIndex(preferences.episodesViewMode ?? EpisodeViewModes.tile);
    _preferDubs = preferences.preferDubs ?? false;

    //load TV stuff
    if (await isTv()) {
      // _watchInfoButtonFocusNode.requestFocus();
    }
    notifyListeners();
  }

  Future<void> updatePrevUsedServer(String? server, String? quality) async {
    if (server == null) return;
    _previouslyUsedServer = server;
    _previouslyUsedServerQuality = quality;
    await saveAnimeSpecificPreference(
        id.toString(),
        AnimeSpecificPreference(
          previouslyUsedServer: server,
          previouslyUsedServerQuality: quality,
        ));
    notifyListeners();
  }

  Future<void> getWatched({bool refreshLastWatchDuration = false}) async {
    try {
      final isLoggedInAnilist = await AniListLogin().isAnilistLoggedIn();

      if (!isLoggedInAnilist) {
        final progress = await getAnimeWatchProgress(id, _mediaListStatus);
        _watched = progress == -1 ? 0 : progress;
        _started = progress != -1;
      } else {
        if (_mediaListStatus == null || data.progress == null) {
          _watched = 0;
          _started = false;
        } else {
          _watched = data.progress ?? 0;
          _started = true;
        }
      }

      final supposedPageIndex = watched ~/ 25; //index increases when the episodes are >24

      _currentPageIndex = visibleEpList.isEmpty
          ? 0
          : (supposedPageIndex >= visibleEpList.length ? visibleEpList.length - 1 : supposedPageIndex);

      if (refreshLastWatchDuration) {
        _lastWatchedDurationMap = (await getAnimeSpecificPreference(id.toString()))?.lastWatchDuration;
      }
    } catch (err) {
      Logs.app.log("[WATCH PROGRESS] $err");
      if (currentUserSettings?.showErrors ?? false) {
        floatingSnackBar("Couldn't fetch watch progress: $err", waitForPreviousToFinish: true);
      }
    }

    notifyListeners();
  }

  Future<void> _getInfo(int id) async {
    try {
      if (currentUserSettings?.database == Databases.anilist) {
        _loggedIn = await AniListLogin().isAnilistLoggedIn();
      } else if (currentUserSettings?.database == Databases.mal) {
        _loggedIn = (await getSecureVal(SecureStorageKey.malToken)) != null;
      } else if (currentUserSettings?.database == Databases.simkl) {
        _loggedIn = await SimklLogin.isLoggedIn();
      }

      // Fetch anime details directly without waiting on auxiliary trackers
      final info = await DatabaseHandler().getAnimeInfo(id);
      final s = _altDatabases.toSet();
      s.addAll(info.alternateDatabases);
      _altDatabases = s.toList();
      _dataLoaded = true;
      _data = info;
      _mediaListStatus = assignItemEnum(data.mediaListStatus);
      notifyListeners();

      // Resolve Simkl ID asynchronously
      final anilistId = currentUserSettings?.database == Databases.anilist
          ? id
          : _altDatabases.where((d) => d.database == Databases.anilist).firstOrNull?.id;
      final malId = currentUserSettings?.database == Databases.mal
          ? id
          : _altDatabases.where((d) => d.database == Databases.mal).firstOrNull?.id;
      _resolveSimklId(anilistId: anilistId, malId: malId);
    } catch (err) {
      Logs.app.log(err.toString());
      if (currentUserSettings?.showErrors ?? false) floatingSnackBar(err.toString());
      _infoLoadError = true;
      notifyListeners();
    }
  }

  void _resolveSimklId({int? anilistId, int? malId}) async {
    try {
      if (_altDatabases.any((db) => db.database == Databases.simkl)) return;

      final simklId = await Simkl().getIdFromRedirect(anilistId: anilistId, malId: malId);
      if (simklId != null) {
        final s = _altDatabases.toSet();
        s.add(AlternateDatabaseId(database: Databases.simkl, id: simklId));
        _altDatabases = s.toList();
        notifyListeners();
      }
    } catch (err) {
      Logs.app.log("[INFO] couldn't resolve simkl id: $err");
    }
  }

  // cleaned, refactored and pretty good ig
  void paginate(List<EpisodeDetails> links) {
    _epLinks = links;
    _visibleEpList.clear();

    final filteredList = <Map<String, dynamic>>[];
    int? watchedProgressIndex; // js a variable to track the last watched episode in filtered list

    // filter the list if dubs are available and user needs dubs (works for subs too)
    for (int i = 0; i < _epLinks.length; i++) {
      final hasDub = links[i].hasDub ?? false;
      if (!_preferDubs || hasDub) {
        if (watched == i) watchedProgressIndex = filteredList.length;
        filteredList.add({'realIndex': i, 'epLink': links[i]});
      }
    }

    // Paginate to sections of 24 stuff
    for (int i = 0; i < filteredList.length; i += 24) {
      int end = (i + 24 < filteredList.length) ? i + 24 : filteredList.length;
      _visibleEpList.add(filteredList.sublist(i, end));
    }

    if (_visibleEpList.isEmpty) {
      // to avoid errors ofcourse
      _visibleEpList.add([]);
      _currentPageIndex = 0;
    } else {
      _currentPageIndex = watchedProgressIndex != null ? (watchedProgressIndex ~/ 24) : 0;
    }

    // _currentPageIndex = _currentPageIndex >= _visibleEpList.length ? _visibleEpList.length-1 : _currentPageIndex;
  }

  Future<void> _search(String query) async {
    final sr = await sourceManager.searchInSource(selectedSource.identifier, query);
    if (sr.isEmpty) {
      _foundName = null;
      notifyListeners();
      throw Exception("Search results were empty!");
    }

    //to find a exact match
    List<Map<String, String?>> match = sr
        .where(
          (e) => e['name'] == query,
        )
        .toList();
    if (match.isEmpty) match = sr;
    final links = await sourceManager.getAnimeEpisodes(selectedSource.identifier, match[0]['alias']!);
    paginate(links);
    _foundName = match[0]['name'];
    notifyListeners();
  }

  Future<void> getEpisodes() async {
    _foundName = null;
    _epSearcherror = false;
    try {
      String searchTitle = data.title['english'] ?? data.title['romaji'] ?? '';
      if (_manualSearchQuery != null) {
        searchTitle = _manualSearchQuery!;
      }
      await _search(searchTitle);
    } catch (err) {
      Logs.app.log(err.toString());

      // try again with romaji title if english title failed

      final hasEnglishTitle = data.title['english'] != null;
      final didUseManualQuery = _manualSearchQuery != null;

      final romajiTitle = data.title['romaji'];
      if (hasEnglishTitle && !didUseManualQuery && romajiTitle != null && romajiTitle != data.title['english']) {
        // try once more with romaji title if english title failed and romaji is different
        try {
          await _search(romajiTitle);
          return;
        } catch (e) {
          Logs.app.log(e.toString());
        }
      }

      _epSearcherror = true;
      notifyListeners();
      if (currentUserSettings?.showErrors ?? false) {
        floatingSnackBar(err.toString());
      }
    }
  }

  void clearLastWatchDuration() async {
    _lastWatchedDurationMap = {};
    await saveAnimeSpecificPreference(
        id.toString(), AnimeSpecificPreference(lastWatchDuration: _lastWatchedDurationMap));
    notifyListeners();
  }

  static IconData getTrackerIcon(MediaStatus? mediaListStatus) {
    switch (mediaListStatus?.name) {
      case "CURRENT":
        return Icons.movie_outlined;
      case "PLANNING":
        return Icons.calendar_month_outlined;
      case "COMPLETED":
        return Icons.done_all_rounded;
      case "DROPPED":
        return Icons.close_rounded;
      case "PAUSED":
        return Icons.pause_circle_outline_rounded;
      default:
        return Icons.add_rounded;
    }
  }

  void refreshListStatus(String? status, int progress) {
    _mediaListStatus = assignItemEnum(status);
    _watched = progress;
    _started = progress > 0;

    // recalculate the page index based on updated value
    paginate(epLinks);
    notifyListeners();
  }
}
