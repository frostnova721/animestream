import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/database/anilist/queries.dart';
import 'package:animestream/core/database/anilist/types.dart';
import 'package:animestream/ui/models/cards.dart';
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

  List<Card> watchingList = [];
  List<Card> plannedList = [];
  List<Card> completedList = [];
  List<Card> droppedList = [];
  List<UserAnimeList> rawAnimeList = [];

  List<Card> getSelectedTabView(int tabIndex) {
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
            Cards(context: context).animeCard(
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
            Cards(context: context).animeCard(
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
            Cards(context: context).animeCard(
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
            Cards(context: context).animeCard(
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
    sort(SortType.TopRated);
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
        //not working as expected. the rawAnimeList is getting modified :(
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
        list: reverse ? list.list.reversed.toList() : list.list,
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
                            // sortOptionButton("Recent",SortType.RecentlyUpdated), // aint workin' :(
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
                  Container(
                    margin: EdgeInsets.only(top: 10),
                    child: TabBar(
                      tabAlignment: TabAlignment.center,
                      isScrollable: true,
                      controller: tabController,
                      indicatorColor: appTheme.accentColor,
                      overlayColor: WidgetStatePropertyAll(appTheme.accentColor.withOpacity(0.3)),
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
                    child: getSelectedTabView(tabController.index).length == 0
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
                        : TabBarView(
                            controller: tabController,
                            children: List.generate(tabController.length, (index) => itemGrid(context, index))),
                  ),
                  // )
                ],
              )
            : Center(
                child: Container(
                  child: CircularProgressIndicator(
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
        style: TextStyle(color: appTheme.textMainColor, fontFamily: "NotoSans-Bold", fontSize: 16),
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
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).orientation == Orientation.portrait ? 3 : 6,
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
      fontFamily: "NotoSans-Bold",
      fontSize: 17,
    );
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }
}
