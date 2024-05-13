import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/app/update.dart';
import 'package:animestream/core/data/watching.dart';
import 'package:animestream/core/database/anilist/anilist.dart';
import 'package:animestream/core/database/anilist/login.dart';
import 'package:animestream/core/database/anilist/types.dart';
import 'package:animestream/ui/models/cards.dart';
import 'package:animestream/ui/models/drawer.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:animestream/ui/pages/Discover.dart';
import 'package:animestream/ui/pages/info.dart';
import 'package:animestream/ui/pages/search.dart';
import 'package:animestream/ui/pages/settings.dart';
import 'package:animestream/ui/theme/mainTheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    super.initState();
    AniListLogin().isAnilistLoggedIn().then((loggedIn) {
      if (loggedIn)
        AniListLogin().getUserProfile().then((user) => {
              userProfile = user,
              storedUserData = user,
              print(storedUserData?.name),
              getLists(userName: user.name),
            });
      else
        getLists();
    });

    checkForUpdates().then(
      (value) {
        if (value != null) {
          showUpdateSheet(
              context, value.description, value.downloadLink, value.preRelease);
        }
      },
    );
  }

  int activeIndex = 0;

  UserModal? userProfile;

  TextEditingController textEditingController = TextEditingController();

  List<AnimeWidget> recentlyWatched = [];
  List<AnimeWidget> currentlyAiring = [];

  bool dataLoaded = false;
  bool error = false;
  bool refreshing = false;

  onItemTapped(int index) {
    if (mounted)
      setState(() {
        activeIndex = index;
      });
  }

  Widget useWidget() {
    switch (activeIndex) {
      case 0:
        return _homeItems();
      case 1:
        return Discover(currentSeason: currentlyAiring);
      default:
        return _homeItems();
    }
  }

  Future<void> getLists({String? userName}) async {
    try {
      recentlyWatched = [];
      List<UserAnimeListItem> watched =
          await getWatchedList(userName: userName);
      if (watched.length > 40) watched = watched.sublist(0, 40);
      watched.forEach((item) {
        final title = item.title['title'] ??
            item.title['english'] ??
            item.title['romaji'] ??
            '';
        recentlyWatched.add(
          AnimeWidget(
            widget: animeCard(title, item.coverImage),
            info: {'id': item.id},
          ),
        );
      });

      final List<CurrentlyAiringResult> currentlyAiringResponse =
          await Anilist().getCurrentlyAiringAnime();
      if (currentlyAiringResponse.length == 0) return;

      currentlyAiring = [];
      currentlyAiringResponse.sublist(0, 20).forEach((e) {
        final title = e.title['english'] ?? e.title['romaji'] ?? '';
        final image = e.cover;
        currentlyAiring
            .add(AnimeWidget(widget: animeCard(title, image,), info: {'id': e.id}));
      });
      if (mounted)
        setState(() {
          dataLoaded = true;
        });
    } catch (err) {
      print(err);
      if (currentUserSettings!.showErrors != null &&
          currentUserSettings!.showErrors!)
        floatingSnackBar(context, err.toString());
      if (mounted)
        setState(() {
          error = true;
        });
    }
  }

  Future<void> refresh({bool fromSettings = false}) async {
    setState(() {
      refreshing = true;
    });
    final loggedIn = await AniListLogin().isAnilistLoggedIn();
    if (loggedIn && userProfile == null) {
      //load the userprofile and list if the user just signed in!
      final user = await AniListLogin().getUserProfile();
      userProfile = user;
      storedUserData = user;
      print(storedUserData?.name);
      await getLists(userName: user.name);
    } else if (loggedIn && userProfile != null) {
      //just load the list if the user was already signed in.
      //also dont refrest the list if user just visited the settings page and were already logged in
      if (fromSettings)
        return setState(() {
          refreshing = false;
        });
      ;
      await getLists(userName: userProfile!.name);
    } else {
      await getLists();
      userProfile = null;
    }
    setState(() {
      refreshing = false;
    });
    refreshController.refreshCompleted();
  }

  bool popInvoked = false;

  //reset the popInvoke
  Future<void> popTimeoutWindow() async {
    await Future.delayed(Duration(seconds: 3));
    popInvoked = false;
  }

  RefreshController refreshController =
      RefreshController(initialRefresh: false);

  final GlobalKey<ScaffoldState> _globalKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
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
        key: _globalKey,
        backgroundColor: backgroundColor,
        drawer: HomeDrawer(
          onItemTapped: onItemTapped,
          activeIndex: activeIndex,
          loggedIn: userProfile != null ? true : false,
        ),
        body: SmartRefresher(
          onRefresh: refresh,
          controller: refreshController,
          header: MaterialClassicHeader(
            color: accentColor,
            backgroundColor: backgroundSubColor,
          ),
          physics:
              ClampingScrollPhysics(parent: NeverScrollableScrollPhysics()),
          child: SingleChildScrollView(
            physics: NeverScrollableScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top,
                  bottom: MediaQuery.of(context).padding.bottom,
                  left: MediaQuery.of(context).padding.left),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    _globalKey.currentState!.openDrawer();
                                  },
                                  icon: Icon(
                                    Icons.menu_rounded,
                                    color: textMainColor,
                                    size: 30,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 10),
                                  child: Text(
                                    "AnimeStream",
                                    style: TextStyle(
                                      color: textMainColor,
                                      fontSize: 23,
                                      fontFamily: 'NunitoSans',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding:
                                  EdgeInsets.only(left: 10, right: 0, top: 10),
                              width: 300,
                              child: TextField(
                                controller: textEditingController,
                                autocorrect: false,
                                maxLines: 1,
                                onSubmitted: (String input) {
                                  textEditingController.value =
                                      TextEditingValue.empty;
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          Search(searchedText: input),
                                    ),
                                  ).then(
                                    (value) async {
                                      setState(() {
                                        refreshing = true;
                                      });
                                      await getLists(
                                          userName: userProfile?.name ?? null);
                                      if (mounted)
                                        setState(() {
                                          refreshing = false;
                                        });
                                    },
                                  );
                                },
                                cursorColor: accentColor,
                                decoration: InputDecoration(
                                  prefixIcon: Padding(
                                    padding: const EdgeInsets.only(left: 5),
                                    child: Image.asset(
                                      "lib/assets/images/search.png",
                                      color: textMainColor,
                                      scale: 1.75,
                                    ),
                                  ),
                                  hintText: "Search...",
                                  hintStyle: TextStyle(
                                    color: textSubColor,
                                    fontFamily: "Poppins",
                                    fontSize: 16,
                                  ),
                                  focusColor: accentColor,
                                  contentPadding: EdgeInsets.only(
                                      top: 5, bottom: 5, left: 20, right: 20),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: accentColor,
                                    ),
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: textMainColor,
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                style: TextStyle(
                                  backgroundColor: backgroundColor,
                                  color: textMainColor,
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.only(right: 15),
                        child: IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SettingsPage(),
                              ),
                            ).then((value) => refresh(fromSettings: true));
                          },
                          icon: Icon(
                            Icons.settings,
                            color: textMainColor,
                            size: 45,
                          ),
                        ),
                        // padding: EdgeInsets.only(right: 25),
                        // child: CircleAvatar(
                        //   radius: 25,
                        //   backgroundColor: ,
                        // ),
                      )
                    ],
                  ),
                  useWidget()
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Column _homeItems() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(top: 40, left: 10, right: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 10, right: 10),
                    child: Text(
                      "Recently Watched",
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        color: textMainColor,
                        fontFamily: "Rubik",
                        fontSize: 20,
                      ),
                    ),
                  ),
                  if (refreshing)
                    Container(
                      margin: EdgeInsets.only(left: 15),
                      height: 15,
                      width: 15,
                      child: CircularProgressIndicator(
                        color: accentColor,
                        strokeWidth: 2,
                      ),
                    )
                ],
              ),
              dataLoaded
                  ? _cardListMaker(recentlyWatched)
                  : Container(
                      height: 250,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: accentColor,
                        ),
                      ),
                    ),
            ],
          ),
        ),
        _accentedHomeDivider(),
        _titleAndList("Currently Airing", currentlyAiring),

      ],
    );
  }

  Container _titleAndList(String title, List<AnimeWidget> list) {
    return Container(
        width: double.infinity,
        padding: EdgeInsets.only(top: 10, left: 10, right: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 10),
              child: Text(
                title,
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: textMainColor,
                  fontFamily: "Rubik",
                  fontSize: 20,
                ),
              ),
            ),
            dataLoaded
                ? _cardListMaker(list)
                : Container(
                    height: 250,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: accentColor,
                      ),
                    ),
                  ),
          ],
        ),
      );
  }

  /** just a division between the items in homescreen */
  Container _accentedHomeDivider() {
    return Container(
        margin: EdgeInsets.only(left: 30, right: 30, top: 10, bottom: 10),
        height: 5,
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.4),
          borderRadius: BorderRadius.circular(
            50,
          ),
        ),
      );
  }

  Column _cardListMaker(List<AnimeWidget> widgetList) {
    return Column(
      children: [
        widgetList.length > 0
            ? Container(
                padding: const EdgeInsets.only(top: 15),
                height: 250,
                child: ListView.builder(
                  itemCount: widgetList.length,
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  itemBuilder: (context, index) {
                    return Container(
                      alignment: Alignment.centerLeft,
                      width: 120,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  Info(id: widgetList[index].info['id']),
                            ),
                          ).then(
                            (value) async {
                              setState(() {
                                refreshing = true;
                              });
                              await getLists(
                                  userName: userProfile?.name ?? null);
                              if (mounted)
                                setState(() {
                                  refreshing = false;
                                });
                            },
                          );
                        },
                        child: widgetList[index].widget,
                      ),
                    );
                  },
                ),
              )
            : Center(
                child: Container(
                  height: 250,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        "lib/assets/images/ghost.png",
                        color: Color.fromARGB(255, 80, 80, 80),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: Text(
                          "Boo! Nothing's here!",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: "NunitoSans",
                            fontWeight: FontWeight.w500,
                            color: Color.fromARGB(255, 80, 80, 80),
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ],
    );
  }
}
