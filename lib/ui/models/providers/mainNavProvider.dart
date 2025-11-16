import 'dart:io';

import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/commons/types.dart';
import 'package:animestream/core/data/watching.dart';
import 'package:animestream/core/database/anilist/anilist.dart';
import 'package:animestream/core/database/anilist/login.dart';
import 'package:animestream/core/database/anilist/queries.dart';
import 'package:animestream/core/database/anilist/types.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:animestream/ui/models/widgets/cards.dart';
import 'package:animestream/ui/models/widgets/cards/animeCard.dart';
import 'package:flutter/widgets.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class MainNavProvider extends ChangeNotifier {
  bool _isAndroid = Platform.isAndroid;
  bool get isAndroid => _isAndroid;

  bool _tv = false;
  bool get tv => _tv;
  set tv(bool value) {
    _tv = value;
    notifyListeners();
  }

  UserModal? _userProfile;
  UserModal? get userProfile => _userProfile;
  set userProfile(UserModal? user) {
    _userProfile = user;
    notifyListeners();
  }

  //home items

  List<HomePageList> _currentlyAiring = [];
  List<HomePageList> _recentlyWatched = [];
  List<HomePageList> _plannedList = [];

  bool _homePageError = false;
  bool _homeDataLoaded = false;

  //Discover items

  List<TrendingResult> _trendingList = [];
  List<AnimeCard> _recommendedList = [];
  List<AnilistRecommendations> _recommendedListData = [];
  List<AnimeCard> _recentlyUpdatedList = [];
  List<RecentlyUpdatedResult> _recentlyUpdatedListData = [];
  List<AnimeCard> _thisSeason = [];
  List<CurrentlyAiringResult> _thisSeasonData = [];

  bool _discoverDataLoaded = false;
  bool get discoverDataLoaded => _discoverDataLoaded;
  set discoverDataLoaded(bool value) {
    _discoverDataLoaded = value;
    notifyListeners();
  }

  // Home items
  List<HomePageList> get currentlyAiring => _currentlyAiring;
  set currentlyAiring(List<HomePageList> value) {
    _currentlyAiring = value;
    notifyListeners();
  }

  List<HomePageList> get recentlyWatched => _recentlyWatched;
  set recentlyWatched(List<HomePageList> value) {
    _recentlyWatched = value;
    notifyListeners();
  }

  List<HomePageList> get plannedList => _plannedList;
  set plannedList(List<HomePageList> value) {
    _plannedList = value;
    notifyListeners();
  }

  bool get homePageError => _homePageError;
  set homePageError(bool value) {
    _homePageError = value;
    notifyListeners();
  }

  bool get homeDataLoaded => _homeDataLoaded;
  set homeDataLoaded(bool value) {
    _homeDataLoaded = value;
    notifyListeners();
  }

  // Discover items

  List<TrendingResult> get trendingList => _trendingList;
  set trendingList(List<TrendingResult> value) {
    _trendingList = value;
    notifyListeners();
  }

  List<AnimeCard> get recommendedList => _recommendedList;
  set recommendedList(List<AnimeCard> value) {
    _recommendedList = value;
    notifyListeners();
  }

  List<AnilistRecommendations> get recommendedListData => _recommendedListData;
  set recommendedListData(List<AnilistRecommendations> value) {
    _recommendedListData = value;
    notifyListeners();
  }

  List<AnimeCard> get recentlyUpdatedList => _recentlyUpdatedList;
  set recentlyUpdatedList(List<AnimeCard> value) {
    _recentlyUpdatedList = value;
    notifyListeners();
  }

  List<RecentlyUpdatedResult> get recentlyUpdatedListData => _recentlyUpdatedListData;
  set recentlyUpdatedListData(List<RecentlyUpdatedResult> value) {
    _recentlyUpdatedListData = value;
    notifyListeners();
  }

  List<AnimeCard> get thisSeason => _thisSeason;
  set thisSeason(List<AnimeCard> value) {
    _thisSeason = value;
    notifyListeners();
  }

  List<CurrentlyAiringResult> get thisSeasonData => _thisSeasonData;
  set thisSeasonData(List<CurrentlyAiringResult> value) {
    _thisSeasonData = value;
    notifyListeners();
  }

  // Methods

  /// check login status and get userprofile then load lists
  Future<void> init() async {
    final loggedIn = await AniListLogin().isAnilistLoggedIn();
    if (loggedIn) {
      AniListLogin()
          .getUserProfile()
          .then((user) => {
                _userProfile = user,
                storedUserData = user,
                print("[AUTHENTICATION] ${storedUserData?.name} Login Successful"),
                loadListsForHome(userName: user.name),
                // loadDiscoverItems(),
              })
          .catchError((err) {
        floatingSnackBar("couldnt load user profile");
        loadListsForHome();
        // loadDiscoverItems(); // lets let the discover page be lazy loaded

        //return statement so that linter would shut up!
        return <void>{};
      });
    } else {
      loadListsForHome();
      // loadDiscoverItems(); // lets let the discover page be lazy loaded
    }
  }

  /// Fetch the trending list from Anilist API
  Future<void> getTrendingList() async {
    final list = await Anilist().getTrending();
    trendingList = list.sublist(0, 20);
  }

  /// Fetch the recommended list from Anilist API
  Future<void> getRecommended() async {
    final list = await AnilistQueries().getRecommendedAnimes();
    recommendedListData = list;
    for (final item in list) {
      final title = item.title['english'] ?? item.title['romaji'] ?? '';
      recommendedList.add(
        Cards.animeCard(
          item.id,
          (currentUserSettings?.nativeTitle ?? false) ? item.title['native'] ?? title : title,
          item.cover,
          rating: item.rating,
          isMobile: !tv && isAndroid,
        ),
      );
    }
    notifyListeners();
  }

  /// Fetch the recently updated list from Anilist API
  Future<void> getRecentlyUpdated() async {
    final list = await Anilist().recentlyUpdated();
    //to filter out the dupes
    Set<int> ids = {};
    for (final elem in list) {
      if (!ids.contains(elem.id)) {
        final title = elem.title['english'] ?? elem.title['romaji'] ?? '';
        ids.add(elem.id);
        recentlyUpdatedListData.add(elem);
        recentlyUpdatedList.add(
          Cards.animeCard(
            elem.id,
            (currentUserSettings?.nativeTitle ?? false) ? elem.title['native'] ?? title : title,
            elem.cover,
            rating: (elem.rating ?? 0) / 10,
            isMobile: !tv && isAndroid,
          ),
        );
      }
    }

    notifyListeners();
  }

  void updateWatchedList(List<HomePageList> watchedList) {
    recentlyWatched = watchedList;
    notifyListeners();
  }

  Future<void> loadListsForHome({String? userName}) async {
    try {
      //get all of em data
      final futures = await Future.wait([
        getWatchedList(userName: userName),
        Anilist().getCurrentlyAiringAnime(),
        if (userName != null) AnilistQueries().getUserAnimeList(userName, status: MediaStatus.PLANNING),
      ]);

      List<UserAnimeListItem> watched = futures[0] as List<UserAnimeListItem>;
      if (watched.length > 40) watched = watched.sublist(0, 40);
      recentlyWatched = [];
      watched.forEach(
        (item) => recentlyWatched.add(
          HomePageList(
            coverImage: item.coverImage,
            id: item.id,
            rating: item.rating,
            title: item.title,
            watchedEpisodeCount: item.watchProgress,
            totalEpisodes: item.episodes,
          ),
        ),
      );

      final List<CurrentlyAiringResult> currentlyAiringResponse = futures[1] as List<CurrentlyAiringResult>;
      if (currentlyAiringResponse.isEmpty) return;

      currentlyAiring = [];
      thisSeasonData = currentlyAiringResponse;
      currentlyAiringResponse.forEach((item) {
        currentlyAiring.add(
          HomePageList(
              coverImage: item.cover,
              id: item.id,
              rating: item.rating,
              title: item.title,
              totalEpisodes: item.episodes,
              watchedEpisodeCount: item.watchProgress),
        );
        final title = item.title['english'] ?? item.title['romaji'] ?? '';
        thisSeason.add(
          Cards.animeCard(
            item.id,
            (currentUserSettings?.nativeTitle ?? false) ? item.title['native'] ?? title : title,
            item.cover,
            rating: item.rating,
          ),
        );
      });

      if (userName != null) {
        List<UserAnimeList> pl = futures[2] as List<UserAnimeList>;
        if (pl.isEmpty) {
          homeDataLoaded = true;
          notifyListeners();
          return;
        }
        plannedList = [];
        List<UserAnimeListItem> itemList = pl[0].list;
        if (itemList.length > 25) itemList = itemList.sublist(0, 25);
        itemList.forEach((item) {
          plannedList.add(HomePageList(
            coverImage: item.coverImage,
            rating: item.rating,
            title: item.title,
            id: item.id,
            totalEpisodes: item.episodes,
            watchedEpisodeCount: item.watchProgress,
          ));
        });
      }

      homeDataLoaded = true;
      notifyListeners();
    } catch (err) {
      print(err);
      if (currentUserSettings!.showErrors != null && currentUserSettings!.showErrors!)
        floatingSnackBar(err.toString(), waitForPreviousToFinish: true);
      floatingSnackBar("couldnt fetch the lists, anilist might be down", waitForPreviousToFinish: true);

      homePageError = true;
      notifyListeners();
    }
  }

  /// Load the items list for the Discover page
  Future<void> loadDiscoverItems() async {
    try {
      await Future.wait([
        getTrendingList(),
        getRecentlyUpdated(),
        getRecommended(),
      ]);
      discoverDataLoaded = true;
    } catch (e) {
      print("Error loading discover items: $e");
      discoverDataLoaded = false;
      if (currentUserSettings!.showErrors != null && currentUserSettings!.showErrors!)
        floatingSnackBar(e.toString(), waitForPreviousToFinish: true);
    }
  }

  final RefreshController homeRefreshController = RefreshController(initialRefresh: false);
  final RefreshController discoverRefreshController = RefreshController(initialRefresh: false);

  /// refresh [0 = home, 1 = discover]
  Future<void> refresh({required int refreshPage, bool fromSettings = false}) async {
    if (refreshPage != 0 && refreshPage != 1) return;

    if (refreshPage == 1) {
      await loadDiscoverItems();
      discoverRefreshController.refreshCompleted();
      notifyListeners();
      return;
    }

    // yes a bit expensive... we could check the userProfile nullability first. but meh
    final loggedIn = await AniListLogin().isAnilistLoggedIn();
    if (loggedIn && userProfile == null) {
      //load the userprofile and list if the user just signed in!
      final user = await AniListLogin().getUserProfile();
      userProfile = user;
      storedUserData = user;
      print("[AUTHENTICATION] ${storedUserData?.name} Login Successful");
      await loadListsForHome(userName: user.name);
    } else if (loggedIn && userProfile != null) {
      //just load the list if the user was already signed in.
      //also dont refrest the list if user just visited the settings page and were already logged in
      if (fromSettings) return;

      await loadListsForHome(userName: userProfile!.name);
    } else {
      await loadListsForHome();
      userProfile = null;
    }
    homeRefreshController.refreshCompleted();
    notifyListeners();
  }
}
