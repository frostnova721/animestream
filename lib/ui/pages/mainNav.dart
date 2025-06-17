import 'dart:io';

import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/app/update.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/commons/types.dart';
import 'package:animestream/core/commons/utils.dart';
import 'package:animestream/core/data/watching.dart';
import 'package:animestream/core/database/anilist/anilist.dart';
import 'package:animestream/core/database/anilist/login.dart';
import 'package:animestream/core/database/anilist/queries.dart';
import 'package:animestream/core/database/anilist/types.dart';
import 'package:animestream/ui/models/widgets/bottomBar.dart';
import 'package:animestream/ui/models/widgets/cards.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:animestream/ui/models/widgets/cards/animeCard.dart';
import 'package:animestream/ui/pages/discover.dart';
import 'package:animestream/ui/pages/home.dart';
import 'package:animestream/ui/pages/search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => MainNavigatorState();
}

class MainNavigatorState extends State<MainNavigator> with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    isTv().then((value) => tv = value);

    //check for app updates & show prompt
    checkForUpdates().then((data) => {
          if (data != null)
            {
              showUpdateSheet(context, data.description, data.downloadLink, data.preRelease),
            }
        });

    //check login status and get userprofile
    AniListLogin().isAnilistLoggedIn().then((loggedIn) {
      if (loggedIn) {
        AniListLogin()
            .getUserProfile()
            .then((user) => {
                  userProfile = user,
                  storedUserData = user,
                  print("[AUTHENTICATION] ${storedUserData?.name} Login Successful"),
                  loadListsForHome(userName: user.name),
                  loadDiscoverItems(),
                })
            .catchError((err) {
          floatingSnackBar("couldnt load user profile");
          loadListsForHome();
          loadDiscoverItems();

          //return statement so that linter would shut up!
          return <void>{};
        });
      } else {
        loadListsForHome();
        loadDiscoverItems();
      }
    });
  }

  //general variables
  UserModal? userProfile;

  AnimeStreamBottomBarController _barController = AnimeStreamBottomBarController(length: 3);

  bool popInvoked = false;
  late bool tv;
  bool isAndroid = Platform.isAndroid;

  RefreshController refreshController = RefreshController(initialRefresh: false);

  //home items

  List<HomePageList> currentlyAiring = [];
  List<HomePageList> recentlyWatched = [];
  List<HomePageList> plannedList = [];

  bool homePageError = false;
  bool homeDataLoaded = false;

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
        thisSeason.add(
          Cards.animeCard(
            item.id,
            item.title['english'] ?? item.title['romaji'] ?? '',
            item.cover,
            rating: item.rating,
          ),
        );
      });

      if (userName != null) {
        List<UserAnimeList> pl = futures[2] as List<UserAnimeList>;
        if (pl.isEmpty) {
          setState(() {
            homeDataLoaded = true;
          });
          return;
        }
        ;
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

      if (mounted)
        setState(() {
          homeDataLoaded = true;
        });
    } catch (err) {
      print(err);
      if (currentUserSettings!.showErrors != null && currentUserSettings!.showErrors!)
        floatingSnackBar(err.toString(), waitForPreviousToFinish: true);
      floatingSnackBar("couldnt fetch the lists, anilist might be down", waitForPreviousToFinish: true);
      if (mounted)
        setState(() {
          homePageError = true;
        });
    }
  }

  void updateWatchedList(List<HomePageList> watchedList) {
    setState(() {
      recentlyWatched = watchedList;
    });
  }

  //discover items

  List<TrendingResult> trendingList = [];
  List<AnimeCard> recommendedList = [];
  List<AnilistRecommendations> recommendedListData = [];
  List<AnimeCard> recentlyUpdatedList = [];
  List<RecentlyUpdatedResult> recentlyUpdatedListData = [];
  List<AnimeCard> thisSeason = [];
  List<CurrentlyAiringResult> thisSeasonData = [];

  void rebuildCards() {
    recentlyUpdatedList.clear();

    final isMobile = !tv && isAndroid;

    recentlyUpdatedListData.forEach((elem) {
      recentlyUpdatedList.add(
        Cards.animeCard(
          elem.id,
          elem.title['english'] ?? elem.title['romaji'] ?? '',
          elem.cover,
          rating: (elem.rating ?? 0) / 10,
          isMobile: isMobile,
        ),
      );
    });

    recommendedList.clear();
    recommendedListData.forEach((item) {
      recommendedList.add(Cards.animeCard(item.id, item.title['english'] ?? item.title['romaji'] ?? '', item.cover,
          rating: item.rating, isMobile: isMobile));
    });

    thisSeason.clear();
    thisSeasonData.forEach((item) {
      thisSeason.add(Cards.animeCard(item.id, item.title['english'] ?? item.title['romaji'] ?? '', item.cover,
          rating: item.rating, isMobile: isMobile));
    });

    setState(() {});
  }

  Future<void> getTrendingList() async {
    final list = await Anilist().getTrending();
    if (mounted)
      setState(() {
        trendingList = list.sublist(0, 20);
      });
  }

  Future<void> getRecommended() async {
    final list = await AnilistQueries().getRecommendedAnimes();
    recommendedListData = list;
    for (final item in list) {
      recommendedList.add(
        Cards.animeCard(
          item.id,
          item.title['english'] ?? item.title['romaji'] ?? '',
          item.cover,
          rating: item.rating,
          isMobile: !tv && isAndroid,
        ),
      );
    }
    if (mounted) setState(() {});
  }

  Future<void> getRecentlyUpdated() async {
    final list = await Anilist().recentlyUpdated();
    //to filter out the dupes
    Set<int> ids = {};
    for (final elem in list) {
      if (!ids.contains(elem.id)) {
        ids.add(elem.id);
        recentlyUpdatedListData.add(elem);
        recentlyUpdatedList.add(
          Cards.animeCard(
            elem.id,
            elem.title['english'] ?? elem.title['romaji'] ?? '',
            elem.cover,
            rating: (elem.rating ?? 0) / 10,
            isMobile: !tv && isAndroid,
          ),
        );
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> loadDiscoverItems() async {
    getTrendingList();
    getRecentlyUpdated();
    getRecommended();
  }

  //reset the popInvoke
  Future<void> popTimeoutWindow() async {
    await Future.delayed(Duration(seconds: 3));
    popInvoked = false;
  }

  //refresh
  Future<void> refresh({bool fromSettings = false}) async {
    // setState(() {
    // });
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
    refreshController.refreshCompleted();
  }

  @override
  Widget build(BuildContext context) {
    if (recentlyUpdatedList.isNotEmpty && thisSeason.isNotEmpty) {
      rebuildCards();
    }
    double blurSigmaValue = currentUserSettings!.navbarTranslucency ?? 5;
    if (blurSigmaValue <= 1) {
      blurSigmaValue = blurSigmaValue * 10;
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, res) async {
        if (_barController.currentIndex != 0) {
          _barController.currentIndex = 0;
          return;
        }

        //exit the app if back is pressed again within 3 sec window
        if (popInvoked) return await SystemNavigator.pop();

        floatingSnackBar("Hit back once again to exit the app");
        popInvoked = true;
        popTimeoutWindow();
      },
      child: Scaffold(
        body: MediaQuery.of(context).orientation == Orientation.landscape || Platform.isWindows
            ? Row(
                children: [
                  NavigationRail(
                    onDestinationSelected: (value) {
                      _barController.currentIndex = value;
                      setState(() {});
                    },
                    backgroundColor: appTheme.backgroundColor,
                    elevation: 1,
                    indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    indicatorColor: appTheme.accentColor,
                    destinations: [
                      NavigationRailDestination(
                        icon: Icon(
                          Icons.home,
                          color: _barController.currentIndex == 0 ? appTheme.onAccent : appTheme.textMainColor,
                        ),
                        label: Text(
                          "Home",
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                      NavigationRailDestination(
                        icon: Icon(
                          Icons.auto_awesome,
                          color: _barController.currentIndex == 1 ? appTheme.onAccent : appTheme.textMainColor,
                        ),
                        label: Text(
                          "Discover",
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.search_rounded,
                            color: _barController.currentIndex == 2 ? appTheme.onAccent : appTheme.textMainColor),
                        label: Text(
                          "Search",
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                    selectedIndex: _barController.currentIndex,
                  ),
                  Expanded(
                    child: BottomBarView(
                      controller: _barController,
                      // physics: NeverScrollableScrollPhysics(),
                      children: [
                        Home(
                          recentlyWatched: recentlyWatched,
                          currentlyAiring: currentlyAiring,
                          dataLoaded: homeDataLoaded,
                          error: homePageError,
                          updateWatchedList: updateWatchedList,
                          planned: plannedList,
                        ),
                        Discover(
                          thisSeason: thisSeason,
                          recentlyUpdatedList: recentlyUpdatedList,
                          recommendedList: recommendedList,
                          trendingList: trendingList,
                        ),
                        Search(),
                      ],
                    ),
                  ),
                ],
              )
            : _bottomBar(context, blurSigmaValue),
      ),
    );
  }

  Widget _bottomBar(BuildContext context, double blurSigmaValue) {
    return Stack(
      children: [
        BottomBarView(
          controller: _barController,
          children: [
            Home(
              key: ValueKey("0"),
              recentlyWatched: recentlyWatched,
              currentlyAiring: currentlyAiring,
              dataLoaded: homeDataLoaded,
              error: homePageError,
              updateWatchedList: updateWatchedList,
              planned: plannedList,
            ),
            Discover(
              key: ValueKey("1"),
              thisSeason: thisSeason,
              recentlyUpdatedList: recentlyUpdatedList,
              recommendedList: recommendedList,
              trendingList: trendingList,
            ),
            Search(
              key: ValueKey("2"),
            ),
          ],
        ),
        AnimeStreamBottomBar(
          controller: _barController,
          accentColor: appTheme.accentColor,
          backgroundColor:
              appTheme.backgroundSubColor.withValues(alpha: currentUserSettings?.navbarTranslucency ?? 0.5),
          borderRadius: 10,
          items: [
            BottomBarItem(title: 'Home', icon: Icon(Icons.home)),
            BottomBarItem(title: 'Discover', icon: Icon(Icons.auto_awesome)),
            BottomBarItem(title: 'Search', icon: Icon(Icons.search)),
          ],
        )
      ],
    );
  }
}
