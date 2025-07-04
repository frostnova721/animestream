import 'dart:io';

import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/database/anilist/queries.dart';
import 'package:animestream/core/database/anilist/types.dart';
import 'package:animestream/ui/models/widgets/bottomBar.dart';
import 'package:animestream/ui/models/widgets/cards.dart';
import 'package:animestream/ui/models/widgets/cards/animeCard.dart';
import 'package:animestream/ui/models/widgets/loader.dart';
import 'package:animestream/ui/models/widgets/navRail.dart';
import 'package:flutter/material.dart';

class AnimeLists extends StatefulWidget {
  const AnimeLists({super.key});

  @override
  State<AnimeLists> createState() => _AnimeListsState();
}

class _AnimeListsState extends State<AnimeLists> with TickerProviderStateMixin {
  @override
  void initState() {
    tabController = TabController(length: 4, vsync: this);
    getAnimeList();
    super.initState();
  }

  List<AnimeCard> watchingList = [];
  List<AnimeCard> plannedList = [];
  List<AnimeCard> completedList = [];
  List<AnimeCard> droppedList = [];
  List<UserAnimeList> rawAnimeList = [];

  final railController = AnimeStreamBottomBarController(length: 4);

  List<AnimeCard> getSelectedTabView(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return watchingList;
      case 1:
        return plannedList;
      case 2:
        return droppedList;
      case 3:
        return completedList;
      default:
        throw new Exception("UNKNOWN STUFF (BAD INDEX)");
    }
  }

  void injectToCorrespondingList(List<UserAnimeList> list) {
    //empty all the lists first
    watchingList = [];
    plannedList = [];
    completedList = [];
    droppedList = [];

    //inject em boi!
    list.forEach((element) {
      if (element.name == "Watching") {
        element.list.forEach((item) {
          watchingList.add(
            Cards.animeCard(
              item.id,
              item.title['english'] ?? item.title['romaji'] ?? '',
              item.coverImage,
              rating: item.rating,
            ),
          );
        });
      }
      if (element.name == "Planning") {
        element.list.forEach((item) {
          plannedList.add(
            Cards.animeCard(
              item.id,
              item.title['english'] ?? item.title['romaji'] ?? '',
              item.coverImage,
              rating: item.rating,
            ),
          );
        });
      }
      if (element.name == "Dropped") {
        element.list.forEach((item) {
          droppedList.add(
            Cards.animeCard(
              item.id,
              item.title['english'] ?? item.title['romaji'] ?? '',
              item.coverImage,
              rating: item.rating,
            ),
          );
        });
      }
      if (element.name == "Completed") {
        element.list.forEach((item) {
          completedList.add(
            Cards.animeCard(
              item.id,
              item.title['english'] ?? item.title['romaji'] ?? '',
              item.coverImage,
              rating: item.rating,
            ),
          );
        });
      }
    });
  }

  Future<void> getAnimeList() async {
    final list = await AnilistQueries().getUserAnimeList(storedUserData!.name);
    if (list.isEmpty) throw new Exception("List is empty lil bro!");
    rawAnimeList = list;
    sort(SortType.RecentlyUpdated);
    setState(() {
      dataLoaded = true;
    });
  }

  void sort(SortType type) {
    switch (type) {
      case SortType.AtoZ:
        return setState(() {
          final List<UserAnimeList> atozList = copyRawAnimeList(false);
          atozList.forEach(
            (element) {
              element.list.sort(
                (a, b) => a.title['english'] != null
                    ? a.title['english']!.compareTo(b.title['english'] ?? b.title['romaji']!)
                    : a.title['romaji']!.compareTo(b.title['english'] ?? b.title['romaji']!),
              );
            },
          );
          injectToCorrespondingList(atozList);
        });

      case SortType.RecentlyUpdated:
        return setState(() {
          final List<UserAnimeList> recentlyUpdatedList = copyRawAnimeList(true);
          injectToCorrespondingList(recentlyUpdatedList);
        });
      case SortType.TopRated:
        setState(() {
          final List<UserAnimeList> ratingList = copyRawAnimeList(false);
          ratingList.forEach(
            (element) {
              element.list.sort((a, b) {
                double? ratingA = a.rating;
                double? ratingB = b.rating;
                if (ratingA == null) ratingA = 0;
                if (ratingB == null) ratingB = 0;
                return ratingB.compareTo(ratingA);
              });
            },
          );
          injectToCorrespondingList(ratingList);
        });
    }
  }

  List<UserAnimeList> copyRawAnimeList(bool reverse) {
    final List<UserAnimeList> cloneList = [];
    for (final list in rawAnimeList) {
      cloneList.add(UserAnimeList(
        list: reverse ? List.from(list.list.reversed) : List.from(list.list),
        name: list.name,
        status: list.status,
      ));
    }
    return cloneList;
  }

  bool dataLoaded = false;

  late TabController tabController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      body: Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, left: MediaQuery.of(context).padding.left),
        child: dataLoaded
            ? Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            icon: Icon(
                              Icons.arrow_back,
                              color: appTheme.textMainColor,
                              size: 28,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.only(left: 10, right: 20),
                            child: Text(
                              "${storedUserData?.name}'s List",
                              style: TextStyle(
                                color: appTheme.textMainColor,
                                fontFamily: "Rubik",
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      PopupMenuButton(
                        color: appTheme.backgroundColor,
                        surfaceTintColor: Colors.white,
                        tooltip: "sort",
                        itemBuilder: (context) {
                          return [
                            sortOptionButton("A-Z", SortType.AtoZ),
                            sortOptionButton("Top rated", SortType.TopRated),
                            sortOptionButton("Recent", SortType.RecentlyUpdated),
                          ];
                        },
                        icon: Icon(
                          Icons.sort,
                          color: appTheme.textMainColor,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                  if (!Platform.isWindows)
                    Container(
                      margin: EdgeInsets.only(top: 10),
                      child: TabBar(
                        tabAlignment: TabAlignment.center,
                        isScrollable: true,
                        controller: tabController,
                        indicatorColor: appTheme.accentColor,
                        overlayColor: WidgetStatePropertyAll(appTheme.accentColor.withValues(alpha: 0.3)),
                        labelColor: appTheme.textMainColor,
                        unselectedLabelColor: appTheme.textSubColor,
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: "NotoSans",
                        ),
                        tabs: [
                          Container(
                            alignment: Alignment.center,
                            height: 50,
                            child: Text(
                              "Watching (${watchingList.length})",
                              style: _textStyle(),
                            ),
                          ),
                          Container(
                            alignment: Alignment.center,
                            height: 50,
                            child: Text(
                              "Planning (${plannedList.length})",
                              style: _textStyle(),
                            ),
                          ),
                          Container(
                            alignment: Alignment.center,
                            height: 50,
                            child: Text(
                              "Dropped (${droppedList.length})",
                              style: _textStyle(),
                            ),
                          ),
                          Container(
                            alignment: Alignment.center,
                            height: 50,
                            child: Text(
                              "Completed (${completedList.length})",
                              style: _textStyle(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if(Platform.isWindows)
                        AnimeStreamNavRail(
                            shouldExpand: true,
                            destinations: [
                              const AnimeStreamNavDestination(icon: Icons.movie, label: "Watching"),
                              const AnimeStreamNavDestination(icon: Icons.calendar_month, label: "Planned"),
                              const AnimeStreamNavDestination(icon: Icons.highlight_off_outlined, label: "Dropped"),
                              const AnimeStreamNavDestination(icon: Icons.task_alt_rounded, label: "Completed")
                            ],
                            controller: railController,
                            initialIndex: 0),
                        getSelectedTabView(tabController.index).length == 0
                            //this wouldnt be shown! ik
                            ? Center(
                                child: Text(
                                  "Such a void!",
                                  style: TextStyle(
                                    color: appTheme.textSubColor,
                                    fontFamily: "NunitoSans",
                                    fontSize: 14,
                                  ),
                                ),
                              )
                            : Expanded(
                                child: Platform.isWindows
                                    ? Container(
                                      margin: EdgeInsets.all(12),
                                      padding: EdgeInsets.only(bottom: 22, top: 5, right: 10, left: 10),
                                      decoration: BoxDecoration(
                                      color: appTheme.backgroundSubColor.withAlpha(175),
                                      borderRadius: BorderRadius.circular(20)
                                      ),
                                      child: BottomBarView(
                                          children:
                                              List.generate(tabController.length, (index) => itemGrid(context, index)),
                                          controller: railController),
                                    )
                                    : TabBarView(
                                        controller: tabController,
                                        children:
                                            List.generate(tabController.length, (index) => itemGrid(context, index))),
                              ),
                      ],
                    ),
                  ),
                  // )
                ],
              )
            : Center(
                child: Container(
                  child: AnimeStreamLoading(
                    color: appTheme.accentColor,
                  ),
                ),
              ),
      ),
    );
  }

  PopupMenuItem sortOptionButton(String label, SortType sortType) {
    return PopupMenuItem(
      onTap: () => sort(sortType),
      child: Text(
        label,
        style: TextStyle(
          color: appTheme.textMainColor,
          fontFamily: "NotoSans",
          fontSize: 16,
        ),
      ),
    );
  }

  Widget itemGrid(BuildContext context, int currentTabIndex) {
    return RefreshIndicator(
      onRefresh: () async {
        await getAnimeList();
        print("refreshed lists!");
      },
      child: Container(
        padding: EdgeInsets.only(
          left: 10,
          right: 10,
        ),
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: Platform.isAndroid ? 140 : 180,
              mainAxisExtent: Platform.isAndroid ? 220 : 260,
              // crossAxisCount: MediaQuery.of(context).orientation == Orientation.portrait ? 3 : 6,
              childAspectRatio: 120 / 220,
              mainAxisSpacing: 10),
          padding: EdgeInsets.only(top: 20, bottom: MediaQuery.of(context).padding.bottom),
          // shrinkWrap: true,
          itemCount: getSelectedTabView(currentTabIndex).length,
          itemBuilder: (context, index) {
            return Container(
              child: getSelectedTabView(currentTabIndex)[index],
            );
          },
        ),
      ),
    );
  }

  TextStyle _textStyle() {
    return TextStyle(
      // color: appTheme.textMainColor,
      fontFamily: "NunitoSans",
      fontWeight: FontWeight.w700,
      fontSize: 17,
    );
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }
}
