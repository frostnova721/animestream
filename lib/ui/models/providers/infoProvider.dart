import 'package:animestream/core/anime/providers/providerDetails.dart';
import 'package:animestream/core/anime/providers/types.dart';
import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/commons/utils.dart';
import 'package:animestream/core/data/animeSpecificPreference.dart';
import 'package:animestream/core/data/preferences.dart';
import 'package:animestream/core/data/types.dart';
import 'package:animestream/core/data/watching.dart';
import 'package:animestream/core/database/anilist/login.dart';
import 'package:animestream/core/database/database.dart';
import 'package:animestream/core/database/handler/handler.dart';
import 'package:animestream/core/database/types.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:animestream/ui/models/sources.dart';
import 'package:flutter/material.dart';

class InfoProvider extends ChangeNotifier {
  int id;
  InfoProvider(int id) : this.id = id;

  late DatabaseInfo _data;

  final sourceManager = SourceManager();

  // Will be set in _init()
  late ProviderDetails _selectedSource;

  String? _foundName;
  String? _manualSearchQuery;

  MediaStatus? _mediaListStatus;

  List<EpisodeDetails> _epLinks = [];
  List<VideoStream> _streamSources = [];
  List<Map<String, String>> _qualities = [];
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
  bool _infoPage = true;
  bool _infoLoadError = false;
  bool _preferDubs = false;

  // Getters
  bool get infoLoadError => _infoLoadError;
  bool get started => _started;
  bool get epSearcherror => _epSearcherror;
  bool get loggedIn => _loggedIn;
  bool get dataLoaded => _dataLoaded;
  bool get infoPage => _infoPage;
  bool get preferDubs => _preferDubs;

  Map? get lastWatchedDurationMap => _lastWatchedDurationMap;

  int get watched => _watched;
  int get viewMode => _viewMode;
  int get currentPageIndex => _currentPageIndex;
  int get viewModeIndexLength => 3;
  int? get selectedEpisodeToLoadStreams => _selectedEpisodeToLoadStreams;

  List<VideoStream> get streamSources => _streamSources;
  List<Map<String, String>> get qualities => _qualities;
  List<List<Map<String, dynamic>>> get visibleEpList => _visibleEpList;
  List<AlternateDatabaseId> get altDatabases => _altDatabases;
  List<EpisodeDetails> get epLinks => _epLinks;

  MediaStatus? get mediaListStatus => _mediaListStatus;

  String? get foundName => _foundName;

  ProviderDetails get selectedSource => _selectedSource;

  DatabaseInfo get data => _data;

  bool _initCalled = false;

  set selectedSource(ProviderDetails val) {
    _selectedSource = val;
    // we just using this condition for validation (too lazy to add a field for it)
    sourceManager.useInbuiltProviders = selectedSource.version == "0.0.0.0";
    notifyListeners();
  }

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

  /// Called in the init state
  void init() async {
    if (_initCalled) throw Exception("The initialization was already done");
    _initCalled = true;

    // Set up sources.
    final sources = sourceManager.sources;
    final matchedSource = sources.where((e) => e.identifier == currentUserSettings?.preferredProvider).firstOrNull;
    selectedSource =
        matchedSource != null ? matchedSource : (sources.isEmpty ? sourceManager.inbuiltSources[0] : sources[0]);

    await _getInfo(id);

    // Load manualsearch query and last watch
    await getAnimeSpecificPreference(id.toString()).then((it) {
      _lastWatchedDurationMap = it?.lastWatchDuration ?? {};
      _manualSearchQuery = it?.manualSearchQuery;
    });

    loadPreferences();
    await getEpisodes();
    await getWatched();
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

  Future<void> getWatched({bool refreshLastWatchDuration = false}) async {
    try {
      if (await AniListLogin().isAnilistLoggedIn()) if (_mediaListStatus == null) {
        _watched = 0;
        _started = false;
      }
      final item = await getAnimeWatchProgress(id, _mediaListStatus);
      _watched = item == 0 ? 0 : item;
      _started = item != 0;

      final supposedPageIndex = watched ~/ 25; //index increases when the episodes are >24

      _currentPageIndex = supposedPageIndex >= visibleEpList.length ? visibleEpList.length - 1 : supposedPageIndex;

      if (refreshLastWatchDuration) {
        _lastWatchedDurationMap = (await getAnimeSpecificPreference(id.toString()))?.lastWatchDuration;
      }
    } catch (err) {
      floatingSnackBar("Couldn't fetch watch progress.");
      print(err.toString());
    }

    notifyListeners();
  }

  Future<void> _getInfo(int id) async {
    try {
      if (currentUserSettings?.database == Databases.anilist && await AniListLogin().isAnilistLoggedIn()) {
        _loggedIn = true;
        //fetch ids from simkl and save em
        try {
          DatabaseHandler(database: Databases.simkl).search("https://anilist.co/anime/$id").then((res) {
            if (res.isEmpty) return;
            DatabaseHandler(database: Databases.simkl).getAnimeInfo(res[0].id).then((r) {
              final s = _altDatabases.toSet();
              r.alternateDatabases.forEach((it) {
                s.add(it);
              });
              _altDatabases = s.toList();
            });
          });
        } catch (err) {
          if (currentUserSettings?.showErrors ?? false) {
            floatingSnackBar("Couldnt fetch simkl data");
          }
        }
      }

      final info = await DatabaseHandler().getAnimeInfo(id);
      _altDatabases = info.alternateDatabases;
      _dataLoaded = true;
      _data = info;
      _mediaListStatus = assignItemEnum(data.mediaListStatus);
      notifyListeners();
    } catch (err) {
      print(err);
      if (currentUserSettings!.showErrors != null && currentUserSettings!.showErrors!) floatingSnackBar(err.toString());
      _infoLoadError = true;
      notifyListeners();
      rethrow;
    }
  }

  // Messy asf function. dont touch, not even I have a clue what its doing!
  void paginate(List<EpisodeDetails> links) {
    _visibleEpList = [];
    _epLinks = links;

    if (_epLinks.length > 24) {
      final totalPages = (_epLinks.length / 24).ceil();
      int remainingItems = _epLinks.length;
      for (int h = 0; h < totalPages; h++) {
        List<Map<String, dynamic>> page = [];
        for (int i = 0; i < 24 && remainingItems > 0; i++) {
          if (_preferDubs && !(_epLinks[(h * 24) + i].hasDub ?? false)) {
            remainingItems--;
          } else {
            page.add({'realIndex': (h * 24) + i, 'epLink': _epLinks[(h * 24) + i]});
            remainingItems--;
          }
        }
        visibleEpList.add(page);
      }
    } else {
      List<Map<String, dynamic>> pageOne = [];
      for (int i = 0; i < _epLinks.length; i++) {
        if (preferDubs && (epLinks[i].hasDub ?? false) || !preferDubs)
          pageOne.add({'realIndex': i, 'epLink': _epLinks[i]});
      }
      visibleEpList.add(pageOne);
    }
    _currentPageIndex = _currentPageIndex >= _visibleEpList.length ? 0 : watched ~/ 25;
  }

  Future<void> _search(String query) async {
    final sr = await sourceManager.searchInSource(selectedSource.identifier, query);
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
    print(foundName == query);
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
      notifyListeners();
    } catch (err) {
      print(err.toString());
      try {
        await _search(data.title['romaji'] ?? '');
      } catch (err) {
        print(err.toString());
        _epSearcherror = true;
        notifyListeners();
        if (currentUserSettings!.showErrors != null && currentUserSettings!.showErrors!) {
          floatingSnackBar(err.toString());
        }
      }
    }
  }

  void clearLastWatchDuration() async {
    await addLastWatchedDuration(id.toString(), {});
    _lastWatchedDurationMap = {};
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
      default:
        return Icons.add_rounded;
    }
  }

  void refreshListStatus(String status, int progress) {
    _mediaListStatus = assignItemEnum(status);
    _watched = progress;
    notifyListeners();
  }
}
