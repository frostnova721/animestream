import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/commons/types.dart';
import 'package:animestream/core/commons/utils.dart';
import 'package:animestream/core/data/animeSpecificPreference.dart';
import 'package:animestream/core/data/preferences.dart';
import 'package:animestream/core/data/types.dart';
import 'package:animestream/core/data/watching.dart';
import 'package:animestream/core/database/anilist/login.dart';
import 'package:animestream/core/database/database.dart';
import 'package:animestream/core/database/handler/handler.dart';
import 'package:animestream/core/database/types.dart';
import 'package:animestream/ui/models/sources.dart';
import 'package:flutter/material.dart';

class InfoProvider extends ChangeNotifier {
  int id;
  InfoProvider(int id) : this.id = id;

  late DatabaseInfo _data;

  // Pick a source from the source list if it exists. select first available source if that source is removed
  String _selectedSource = sources.contains(currentUserSettings?.preferredProvider)
      ? currentUserSettings?.preferredProvider ?? sources[0]
      : sources[0];
  String? _foundName;
  String? _manualSearchQuery;

  MediaStatus? _mediaListStatus;

  List<String> _epLinks = [];
  List<VideoStream> _streamSources = [];
  List<Map<String, String>> _qualities = [];
  List<List<Map<String, dynamic>>> _visibleEpList = [];
  List<AlternateDatabaseId> _altDatabases = [];

  int _currentPageIndex = 0;
  int _watched = 1;
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

  // Getters
  bool get infoLoadError => _infoLoadError;
  bool get started => _started;
  bool get epSearcherror => _epSearcherror;
  bool get loggedIn => _loggedIn;
  bool get dataLoaded => _dataLoaded;
  bool get infoPage => _infoPage;

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
  List<String> get epLinks => _epLinks;

  MediaStatus? get mediaListStatus => _mediaListStatus;

  String? get foundName => _foundName;
  String get selectedSource => _selectedSource;

  DatabaseInfo get data => _data;

  bool _initCalled = false;

  set selectedSource(String val) {
    _selectedSource = val;
    notifyListeners();
  }

  set viewMode(int newIndex) {
    _viewMode = newIndex;
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

  /// Called in the init state
  void init() async {
    if (_initCalled) throw Exception("The initialization was already done");
    _initCalled = true;
    await _getInfo(id);

    // Load manualsearch query and last watch
    await getAnimeSpecificPreference(id.toString()).then((it) {
      _lastWatchedDurationMap = it?.lastWatchDuration ?? {};
      _manualSearchQuery = it?.manualSearchQuery;
    });

    await getEpisodes();
    await getWatched();
  }

  /// Fetch preferences
  Future<void> loadPreferences() async {
    final preferences = await UserPreferences().getUserPreferences();
    _viewMode = UserPreferencesModal.getViewModeIndex(preferences.episodesViewMode ?? EpisodeViewModes.tile);

    //load TV stuff
    if (await isTv()) {
      // _watchInfoButtonFocusNode.requestFocus();
    }
    notifyListeners();
  }

  Future<void> getWatched({ bool refreshLastWatchDuration = false }) async {
    if (await AniListLogin().isAnilistLoggedIn()) if (_mediaListStatus == null) {
      _watched = 0;
      _started = false;
    }
    final item = await getAnimeWatchProgress(id, _mediaListStatus);
    _watched = item == 0 ? 0 : item;
    _started = item != 0;

    _currentPageIndex = watched ~/ 25; //index increases when the episodes are >24

    if(refreshLastWatchDuration) {
      _lastWatchedDurationMap = (await getAnimeSpecificPreference(id.toString()))?.lastWatchDuration;
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
            // floatingSnackBar(context, "Couldnt fetch simkl data");
          }
        }
      }

      // getLastWatchedDuration(widget.id.toString()).then((it) => lastWatchedDurationMap = it ?? {}); // retrieve the last watch duration
      final info = await DatabaseHandler().getAnimeInfo(id);
      _altDatabases = info.alternateDatabases;
      _dataLoaded = true;
      _data = info;
      _mediaListStatus = assignItemEnum(data.mediaListStatus);
      notifyListeners();
    } catch (err) {
      print(err);
      if (currentUserSettings!.showErrors != null && currentUserSettings!.showErrors!)
        // floatingSnackBar(context, err.toString());
        _infoLoadError = true;
      notifyListeners();
      rethrow;
    }
  }

  void paginate(List<String> links) {
    _visibleEpList = [];
    _epLinks = links;
    if (_epLinks.length > 24) {
      final totalPages = (_epLinks.length / 24).ceil();
      int remainingItems = _epLinks.length;
      for (int h = 0; h < totalPages; h++) {
        List<Map<String, dynamic>> page = [];
        for (int i = 0; i < 24 && remainingItems > 0; i++) {
          page.add({'realIndex': (h * 24) + i, 'epLink': _epLinks[(h * 24) + i]});
          remainingItems--;
        }
        visibleEpList.add(page);
      }
    } else {
      List<Map<String, dynamic>> pageOne = [];
      for (int i = 0; i < _epLinks.length; i++) {
        pageOne.add({'realIndex': i, 'epLink': _epLinks[i]});
      }
      visibleEpList.add(pageOne);
    }
  }

  Future<void> _search(String query) async {
    final sr = await searchInSource(selectedSource, query);
    //to find a exact match
    List<Map<String, String?>> match = sr
        .where(
          (e) => e['name'] == query,
        )
        .toList();
    if (match.isEmpty) match = sr;
    final links = await getAnimeEpisodes(selectedSource, match[0]['alias']!);
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
          // floatingSnackBar(context, err.toString());
        }
      }
    }
  }

  IconData getTrackerIcon() {
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

  // Future<void> getQualities() async {
  //   List<Map<String, String>> mainList = [];
  //   for (int i = 0; i < _streamSources.length; i++) {
  //     final list = await generateQualitiesForMultiQuality(_streamSources[i].link);
  //     list.forEach((element) {
  //       element['server'] = "${_streamSources[i].server} ${_streamSources[i].backup ? "• backup" : ""}";
  //       mainList.add(element);
  //     });
  //   }
  //   _qualities = mainList;
  // }

  // Future getEpisodeSources(String epLink) async {
  //   _streamSources = [];
  //   await getStreams(selectedSource, epLink, (list, finished) {
  //     if (finished) _streamSources = _streamSources + list;
  //   });
  // }
}
