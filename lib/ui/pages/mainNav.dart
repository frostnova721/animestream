import 'dart:ui';

import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/app/update.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/commons/types.dart';
import 'package:animestream/core/data/watching.dart';
import 'package:animestream/core/database/anilist/anilist.dart';
import 'package:animestream/core/database/anilist/login.dart';
import 'package:animestream/core/database/anilist/queries.dart';
import 'package:animestream/core/database/anilist/types.dart';
import 'package:animestream/ui/models/cards.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:animestream/ui/pages/discover.dart';
import 'package:animestream/ui/pages/home.dart';
import 'package:animestream/ui/pages/search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
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

    //check for app updates
    checkForUpdates().then((data) => {
          if (data != null)
            {
              showUpdateSheet(context, data.description, data.downloadLink, data.preRelease),
            }
        });

    //check login status and get userprofile
    AniListLogin().isAnilistLoggedIn().then((loggedIn) {
      if (loggedIn) {
        AniListLogin().getUserProfile().then((user) => {
              userProfile = user,
              storedUserData = user,
              print("[AUTHENTICATION] ${storedUserData?.name} Login Successful"),
              loadListsForHome(userName: user.name),
              loadDiscoverItems(),
            });
      } else {
        loadListsForHome();
        loadDiscoverItems();
      }
    });

    tabController = TabController(length: 3, vsync: this);
  }

  //general variables

  UserModal? userProfile;

  late TabController tabController;

  bool popInvoked = false;

  RefreshController refreshController = RefreshController(initialRefresh: false);

  //home items

  List<HomePageList> currentlyAiring = [];
  List<HomePageList> recentlyWatched = [];
  List<HomePageList> plannedList = [];

  bool homePageError = false;
  bool homeDataLoaded = false;

  Future<void> loadListsForHome({String? userName}) async {
    try {
      List<UserAnimeListItem> watched = await getWatchedList(userName: userName);
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

      final List<CurrentlyAiringResult> currentlyAiringResponse = await Anilist().getCurrentlyAiringAnime();
      if (currentlyAiringResponse.length == 0) return;

      currentlyAiring = [];
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
          Cards(context: context).animeCard(
            item.id,
            item.title['english'] ?? item.title['romaji'] ?? '',
            item.cover,
            rating: item.rating,
          ),
        );
      });

      if (userName != null) {
        List<UserAnimeList> pl = await AnilistQueries().getUserAnimeList(userName, status: MediaStatus.PLANNING);
        if (pl.isEmpty) return;
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
        floatingSnackBar(context, err.toString());
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
  List<Card> recommendedList = [];
  List<Card> recentlyUpdatedList = [];
  List<Card> thisSeason = [];

  Future<void> getTrendingList() async {
    final list = await Anilist().getTrending();
    if (mounted)
      setState(() {
        trendingList = list.sublist(0, 20);
      });
  }

  Future<void> getRecommended() async {
    final list = await AnilistQueries().getRecommendedAnimes();
    for (final item in list) {
      recommendedList.add(
        Cards(context: context).animeCard(
          item.id,
          item.title['english'] ?? item.title['romaji'] ?? '',
          item.cover,
          rating: item.rating,
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
        recentlyUpdatedList.add(
          Cards(context: context).animeCard(
            elem.id,
            elem.title['english'] ?? elem.title['romaji'] ?? '',
            elem.cover,
            rating: (elem.rating ?? 0) / 10,
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
    double blurSigmaValue = currentUserSettings!.navbarTranslucency ?? 5; 
    if(blurSigmaValue <= 1) {
      blurSigmaValue = blurSigmaValue * 10;
    }
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        //exit the app if back is pressed again within 3 sec window
        if (popInvoked) return await SystemNavigator.pop();

        floatingSnackBar(context, "Hit back once again to exit the app");
        popInvoked = true;
        popTimeoutWindow();
      },
      child: Scaffold(
        body: BottomBar(
          barColor: appTheme.backgroundSubColor.withOpacity(currentUserSettings!.navbarTranslucency ?? 0.6 ),
          borderRadius: BorderRadius.circular(10),
          barAlignment: Alignment.bottomCenter,
          width: MediaQuery.of(context).size.width / 2 + 20,
          offset: MediaQuery.of(context).padding.bottom + 10,
          child: ClipRRect(
            clipBehavior: Clip.hardEdge,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: EdgeInsets.only(top: 5),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blurSigmaValue, sigmaY: blurSigmaValue),
                child: TabBar(
                  onTap: (val) => setState(() {}),
                  overlayColor: WidgetStateColor.transparent,
                  controller: tabController,
                  isScrollable: false,
                  labelColor: appTheme.accentColor,
                  unselectedLabelColor: appTheme.textSubColor,
                  dividerHeight: 0,
                  indicatorColor: appTheme.accentColor,
                  labelPadding: EdgeInsets.only(bottom: 5),
                  tabs: [
                    TabIcon(
                      icon: Icons.home_rounded,
                      label: "Home",
                      animate: tabController.index == 0,
                    ),
                    TabIcon(icon: null, label: "Discover", animate: tabController.index == 1, image: true),
                    TabIcon(icon: Icons.search_rounded, label: 'Search', animate: tabController.index == 2),
                  ],
                ),
              ),
            ),
          ),
          body: (context, scrollController) => SmartRefresher(
            controller: refreshController,
            onRefresh: refresh,
            header: MaterialClassicHeader(
              color: appTheme.accentColor,
              backgroundColor: appTheme.backgroundSubColor,
            ),
            child: TabBarView(
              controller: tabController,
              physics: NeverScrollableScrollPhysics(),
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
        ),
      ),
    );
  }
}

class TabIcon extends StatefulWidget {
  final IconData? icon;
  final String label;
  final bool animate;
  final bool image;
  const TabIcon({super.key, required this.icon, this.image = false, required this.label, required this.animate});

  @override
  State<TabIcon> createState() => _TabIconState();
}

class _TabIconState extends State<TabIcon> {
  @override
  void initState() {
    super.initState();
  }

  final double iconSize = 30;

  @override
  Widget build(BuildContext context) {
    if (widget.image == false && widget.icon == null) throw Exception("DIDNT RECIEVE 'IconData'");
    return Container(
      height: 40,
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        child: widget.animate
            ? Text(
                widget.label,
                style: TextStyle(fontFamily: "NotoSans", fontWeight: FontWeight.w600, fontSize: 14),
              )
            : widget.image
                ? ImageIcon(
                    AssetImage("lib/assets/images/shines.png"),
                    size: iconSize - 4,
                    color: appTheme.textMainColor,
                  )
                : Icon(
                    widget.icon,
                    size: iconSize,
                    color: appTheme.textMainColor,
                  ),
      ),
    );
  }
}
