import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/database/anilist/queries.dart';
import 'package:animestream/core/database/anilist/types.dart';
import 'package:animestream/ui/models/cards.dart';
import 'package:animestream/ui/pages/info.dart';
import 'package:animestream/ui/theme/mainTheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

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

  List<ListElement> getSelectedTabView() {
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
    rawAnimeList = list.reversed.toList();
    injectToCorrespondingList(rawAnimeList);
    setState(() {
      dataLoaded = true;
    });
  }

  void sort(SortType type) {
    switch (type) {
      case SortType.AtoZ:
        return setState(() {
          final atozList = [...rawAnimeList];
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
          final recentlyUpdatedList = [...rawAnimeList];
          recentlyUpdatedList[0].list.asMap().values.forEach((element) { print(element.title);});
          injectToCorrespondingList(recentlyUpdatedList);
        });
      case SortType.TopRated:
      setState(() {
        final List<UserAnimeList> ratingList = [...rawAnimeList]; 
          ratingList.forEach(
            (element) {
              element.list.sort(
                (a, b) {
                  double? ratingA = a.rating;
                  double? ratingB = b.rating;
                  if(ratingA == null) ratingA = 0;
                  if(ratingB == null) ratingB = 0;
                  return ratingB.compareTo(ratingA);
                }
              );
            },
          );
          injectToCorrespondingList(ratingList);
          rawAnimeList[0].list.asMap().values.forEach((element) { print(element.title);});
      });
    }
  }

  bool dataLoaded = false;
  int tabIndex = 0;

  late TabController tabController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top,
        ),
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
                            PopupMenuItem(
                              onTap: () => sort(SortType.AtoZ),
                              child: Text(
                                "A-Z",
                                style: TextStyle(
                                    color: textMainColor,
                                    fontFamily: "NotoSans-Bold",
                                    fontSize: 16),
                              ),
                            ),
                            //shhh
                            // PopupMenuItem(
                            //   onTap: () {sort(SortType.RecentlyUpdated);},
                            //   child: Text(
                            //     "Recently updated",
                            //     style: TextStyle(
                            //         color: textMainColor,
                            //         fontFamily: "NotoSans-Bold",
                            //         fontSize: 16),
                            //   ),
                            // ),
                            PopupMenuItem(
                               onTap: () {sort(SortType.TopRated);},
                              child: Text(
                                "Top rated",
                                style: TextStyle(
                                    color: textMainColor,
                                    fontFamily: "NotoSans-Bold",
                                    fontSize: 16),
                              ),
                            ),
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
                      onTap: ((value) {
                        setState(() {
                          tabIndex = value;
                        });
                      }),
                      tabAlignment: TabAlignment.center,
                      isScrollable: true,
                      controller: tabController,
                      indicatorColor: accentColor,
                      overlayColor: MaterialStatePropertyAll(
                          accentColor.withOpacity(0.3)),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: "NotoSans",
                      ),
                      tabs: [
                        Container(
                          alignment: Alignment.center,
                          height: 50,
                          child: Text(
                            "Watching",
                            style: _textStyle(),
                          ),
                        ),
                        Container(
                          alignment: Alignment.center,
                          height: 50,
                          child: Text(
                            "Planning",
                            style: _textStyle(),
                          ),
                        ),
                        Container(
                          alignment: Alignment.center,
                          height: 50,
                          child: Text(
                            "Dropped",
                            style: _textStyle(),
                          ),
                        ),
                        Container(
                          alignment: Alignment.center,
                          height: 50,
                          child: Text(
                            "Completed",
                            style: _textStyle(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: getSelectedTabView().length == 0
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
                        : Container(
                            padding: EdgeInsets.only(left: 10, right: 10),
                            child: GridView.builder(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 120 / 220,
                              ),
                              padding: EdgeInsets.only(top: 20),
                              // shrinkWrap: true,
                              itemCount: getSelectedTabView().length,
                              itemBuilder: (context, index) {
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => Info(
                                          id: getSelectedTabView()[index]
                                              .info['id'],
                                        ),
                                      ),
                                    ).then((value) => getAnimeList());
                                  },
                                  child: Container(
                                    child: getSelectedTabView()[index].widget,
                                  ),
                                );
                              },
                            ),
                          ),
                  )
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

  TextStyle _textStyle() {
    return TextStyle(
      color: textMainColor,
      fontFamily: "NotoSans-Bold",
      fontSize: 18,
    );
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }
}
