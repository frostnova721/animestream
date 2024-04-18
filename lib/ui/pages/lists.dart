import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/database/anilist/queries.dart';
import 'package:animestream/core/database/anilist/types.dart';
import 'package:animestream/ui/models/cards.dart';
import 'package:animestream/ui/pages/info.dart';
import 'package:animestream/ui/theme/mainTheme.dart';
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

  List<ListElement> watchingList = [];
  List<ListElement> plannedList = [];
  List<ListElement> completedList = [];
  List<ListElement> droppedList = [];
  List<UserAnimeList> rawAnimeList = [];

  List<ListElement> getSelectedTabView(int tabIndex) {
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
          watchingList.add(ListElement(
              widget: animeCard(
                item.title['english'] ?? item.title['romaji'] ?? '',
                item.coverImage,
              ),
              info: {
                'id': item.id,
              }));
        });
      }
      if (element.name == "Planning") {
        element.list.forEach((item) {
          plannedList.add(ListElement(
              widget: animeCard(
                item.title['english'] ?? item.title['romaji'] ?? '',
                item.coverImage,
              ),
              info: {
                'id': item.id,
              }));
        });
      }
      if (element.name == "Dropped") {
        element.list.forEach((item) {
          droppedList.add(ListElement(
              widget: animeCard(
                item.title['english'] ?? item.title['romaji'] ?? '',
                item.coverImage,
              ),
              info: {
                'id': item.id,
              }));
        });
      }
      if (element.name == "Completed") {
        element.list.forEach((item) {
          completedList.add(ListElement(
              widget: animeCard(
                item.title['english'] ?? item.title['romaji'] ?? '',
                item.coverImage,
              ),
              info: {
                'id': item.id,
              }));
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
                    ? a.title['english']!
                        .compareTo(b.title['english'] ?? b.title['romaji']!)
                    : a.title['romaji']!
                        .compareTo(b.title['english'] ?? b.title['romaji']!),
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
      backgroundColor: backgroundColor,
      body: Padding(
        padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top,
            left: MediaQuery.of(context).padding.left),
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
                              color: textMainColor,
                              size: 28,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.only(left: 10, right: 20),
                            child: Text(
                              "${storedUserData?.name}'s List",
                              style: TextStyle(
                                color: textMainColor,
                                fontFamily: "Rubik",
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      PopupMenuButton(
                        color: backgroundColor,
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
                          color: textMainColor,
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
                      indicatorColor: accentColor,
                      overlayColor: MaterialStatePropertyAll(
                          accentColor.withOpacity(0.3)),
                      labelColor: textMainColor,
                      unselectedLabelColor: textSubColor,
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
                        ? Center(
                            child: Text(
                              "Such a void!",
                              style: TextStyle(
                                color: textSubColor,
                                fontFamily: "NunitoSans",
                                fontSize: 14,
                              ),
                            ),
                          )
                        : TabBarView(
                            controller: tabController,
                            children: List.generate(tabController.length,
                                (index) => itemGrid(context, index))),
                  ),
                  // )
                ],
              )
            : Center(
                child: Container(
                  child: CircularProgressIndicator(
                    color: accentColor,
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
            color: textMainColor, fontFamily: "NotoSans-Bold", fontSize: 16),
      ),
    );
  }

  Container itemGrid(BuildContext context, int currentTabIndex) {
    return Container(
      padding: EdgeInsets.only(left: 10, right: 10,),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount:
              MediaQuery.of(context).orientation == Orientation.portrait
                  ? 3
                  : 6,
          childAspectRatio: 120 / 220,
          mainAxisSpacing: 10
        ),
        padding: EdgeInsets.only(top: 20, bottom: MediaQuery.of(context).padding.bottom),
        // shrinkWrap: true,
        itemCount: getSelectedTabView(currentTabIndex).length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Info(
                    id: getSelectedTabView(currentTabIndex)[index].info['id'],
                  ),
                ),
              ).then((value) => getAnimeList());
            },
            child: Container(
              child: getSelectedTabView(currentTabIndex)[index].widget,
            ),
          );
        },
      ),
    );
  }

  TextStyle _textStyle() {
    return TextStyle(
      // color: textMainColor,
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
