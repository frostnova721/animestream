import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/types.dart';
import 'package:animestream/core/commons/utils.dart';
import 'package:animestream/core/data/manualSearches.dart';
import 'package:animestream/core/data/preferences.dart';
import 'package:animestream/core/data/types.dart';
import 'package:animestream/core/data/watching.dart';
import 'package:animestream/core/database/anilist/login.dart';
import 'package:animestream/core/database/anilist/queries.dart';
import 'package:animestream/core/database/anilist/types.dart';
import 'package:animestream/ui/models/bottomSheets/serverSelectionSheet.dart';
import 'package:animestream/ui/models/bottomSheets/manualSearchSheet.dart';
import 'package:animestream/ui/models/bottomSheets/mediaListStatus.dart';
import 'package:animestream/ui/models/cards.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:animestream/ui/models/sources.dart';
import 'package:animestream/ui/theme/mainTheme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:animestream/core/commons/enums.dart';
import "package:image_gallery_saver/image_gallery_saver.dart";

class Info extends StatefulWidget {
  final int id;
  const Info({required this.id});

  @override
  State<Info> createState() => _InfoState();
}

class _InfoState extends State<Info> {
  @override
  void initState() {
    super.initState();
    loadPreferences();
    AniListLogin().isAnilistLoggedIn().then((value) => loggedIn = value);
    getInfo(widget.id).then((value) {
      getEpisodes();
      getWatched();
    });
  }

  late AnilistInfo data;

  String selectedSource = "gogoanime";
  String? foundName;

  MediaStatus? mediaListStatus;

  List<String> epLinks = [];
  List streamSources = [];
  List qualities = [];
  List<List<Map<String, dynamic>>> visibleEpList = [];

  int currentPageIndex = 0;
  int watched = 1;

  bool showBar = false;
  bool gridMode = false;
  bool started = false;
  bool _epSearcherror = false;
  bool loggedIn = false;
  bool dataLoaded = false;
  bool infoPage = true;

  Future<void> loadPreferences() async {
    final preferences = await UserPreferences().getUserPreferences();
    gridMode = preferences.episodeGridView ?? false;
  }

  Future<void> getWatched() async {
    if (await AniListLogin().isAnilistLoggedIn()) if (mediaListStatus == null) {
      return setState(() {
        watched = 0;
        started = false;
      });
    }
    final item = await getAnimeWatchProgress(widget.id, mediaListStatus);
    watched = item == 0 ? 0 : item;
    started = item == 0 ? false : true;

    if (mounted) setState(() {});
  }

  Future getInfo(int id) async {
    try {
      final info = await AnilistQueries().getAnimeInfo(id);
      setState(() {
        dataLoaded = true;
        data = info;
        mediaListStatus = assignItemEnum(data.mediaListStatus);
      });
    } catch (err) {
      if (currentUserSettings!.showErrors != null && currentUserSettings!.showErrors!)
        floatingSnackBar(context, err.toString());
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
      //add more :(
      default:
        return Icons.add_rounded;
    }
  }

  //to refresh the mediaList status
  void refreshListStatus(String status, int progress) {
    setState(() {
      mediaListStatus = assignItemEnum(status);
      watched = progress;
    });
  }

  Future<void> getQualities() async {
    List<dynamic> mainList = [];
    for (int i = 0; i < streamSources.length; i++) {
      final List<dynamic> list = await generateQualitiesForMultiQuality(streamSources[i].link);
      list.forEach((element) {
        element['server'] = "${streamSources[i].server} ${streamSources[i].backup ? "• backup" : ""}";
        mainList.add(element);
      });
    }
    if (mounted)
      setState(() {
        qualities = mainList;
      });
  }

  Future getEpisodeSources(String epLink) async {
    streamSources = [];
    // final epSrcs =
    await getStreams(selectedSource, epLink, (list, finished) {
      if (mounted)
        setState(() {
          if (finished) streamSources = streamSources + list;
        });
    });
    // setState(() {
    //   streamSources = epSrcs;
    // });
  }

  void paginate(List<String> links) {
    visibleEpList = [];
    epLinks = links;
    if (epLinks.length > 24) {
      final totalPages = (epLinks.length / 24).ceil();
      int remainingItems = epLinks.length;
      for (int h = 0; h < totalPages; h++) {
        List<Map<String, dynamic>> page = [];
        for (int i = 0; i < 24 && remainingItems > 0; i++) {
          page.add({'realIndex': (h * 24) + i, 'epLink': epLinks[(h * 24) + i]});
          remainingItems--;
        }
        visibleEpList.add(page);
      }
    } else {
      List<Map<String, dynamic>> pageOne = [];
      for (int i = 0; i < epLinks.length; i++) {
        pageOne.add({'realIndex': i, 'epLink': epLinks[i]});
      }
      visibleEpList.add(pageOne);
    }
  }

  Future<void> search(String query) async {
    final sr = await searchInSource(selectedSource, query);
    //to find a exact match
    List<dynamic> match = sr
        .where(
          (e) => e['name'] == query,
        )
        .toList();
    if (match.isEmpty) match = sr;
    final links = await getAnimeEpisodes(selectedSource, match[0]['alias']);
    if (mounted)
      setState(() {
        paginate(links);
        foundName = match[0]['name'];
      });
  }

  Future<void> getEpisodes() async {
    foundName = null;
    _epSearcherror = false;
    try {
      final manualSearchQuery = await getManualSearchQuery('${widget.id}');
      String searchTitle = data.title['english'] ?? data.title['romaji'] ?? '';
      if (manualSearchQuery != null) searchTitle = manualSearchQuery;
      await search(searchTitle);
    } catch (err) {
      try {
        await search(data.title['romaji'] ?? '');
      } catch (err) {
        if (mounted)
          setState(() {
            _epSearcherror = true;
          });
        if (currentUserSettings!.showErrors != null && currentUserSettings!.showErrors!)
          floatingSnackBar(context, err.toString());
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: dataLoaded
            ? SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _stack(),
                      Container(
                        margin: EdgeInsets.only(top: 30),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              // width: 120,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: accentColor, fixedSize: Size(135, 55)),
                                onPressed: () {
                                  setState(() {
                                    infoPage = !infoPage;
                                  });
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      infoPage ? Icons.play_arrow_rounded : Icons.info_rounded,
                                      color: Colors.black,
                                      size: 28,
                                    ),
                                    Text(
                                      infoPage ? "watch" : "info",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontFamily: "Poppins",
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (loggedIn)
                              Container(
                                child: ElevatedButton(
                                  onPressed: () {
                                    showModalBottomSheet(
                                      context: context,
                                      backgroundColor: Color(0xff121212),
                                      showDragHandle: true,
                                      builder: (context) => MediaListStatusBottomSheet(
                                        status: mediaListStatus,
                                        id: widget.id,
                                        refreshListStatus: refreshListStatus,
                                        totalEpisodes: data.episodes ?? 0,
                                        episodesWatched: watched,
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    shape: CircleBorder(
                                      side: BorderSide(
                                        color: accentColor,
                                      ),
                                    ),
                                    fixedSize: Size(50, 50),
                                    backgroundColor: backgroundColor,
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: Icon(
                                    getTrackerIcon(),
                                    color: accentColor,
                                    size: 28,
                                  ),
                                ),
                              )
                          ],
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 45),
                        padding: EdgeInsets.only(left: 20, right: 20),
                        alignment: Alignment.center,
                        // padding: EdgeInsets.only(left: 40, right: 25),
                        child: Text(
                          data.title['english'] ?? data.title['romaji'] ?? '',
                          style: TextStyle(
                            color: textMainColor,
                            fontFamily: "NunitoSans",
                            fontSize: 25,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: Duration(milliseconds: 200),
                        child: infoPage ? _infoItems(context) : _watchItems(context),
                      ),
                    ],
                  ),
                ),
              )
            : Center(
                child: CircularProgressIndicator(
                  color: accentColor,
                ),
              ),
      );
    } catch (err) {
      print(err);
      return Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'lib/assets/images/broken_heart.png',
              scale: 7.5,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 15, left: 30, right: 30),
              child: const Text(
                'oops! something went wrong',
                style:
                    TextStyle(color: Colors.white, fontFamily: "NunitoSans", fontSize: 25, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }
  }

  Column _watchItems(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.only(top: 30),
          child: DropdownMenu(
            initialSelection: sources.first,
            dropdownMenuEntries: getSourceDropdownList(),
            // menuHeight: 75,
            width: 300,
            textStyle: TextStyle(
              color: textMainColor,
              fontFamily: "Poppins",
            ),
            trailingIcon: Icon(
              Icons.arrow_drop_down,
              color: textMainColor,
            ),
            selectedTrailingIcon: Icon(
              Icons.arrow_drop_up,
              color: textMainColor,
            ),
            menuStyle: MenuStyle(
              surfaceTintColor: WidgetStatePropertyAll(backgroundSubColor),
              backgroundColor: WidgetStatePropertyAll(Color.fromARGB(255, 0, 0, 0)),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  side: BorderSide(color: textMainColor),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            onSelected: (value) {
              selectedSource = value;
              setState(() {
                getEpisodes();
              });
            },
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderSide: BorderSide(
                  width: 1,
                  color: Colors.white,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: EdgeInsets.only(left: 20, right: 20),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  width: 1,
                  color: Colors.white,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            label: Text(
              "source",
              style:
                  TextStyle(color: textMainColor, fontSize: 20, fontFamily: "Rubik", overflow: TextOverflow.ellipsis),
            ),
          ),
        ),
        _searchStatus(),
        _manualSearch(context),
        if (foundName != null) _continueButton(),
        Container(
          margin: EdgeInsets.only(top: 25, left: 20, right: 20),
          padding: EdgeInsets.only(top: 15, bottom: 20),
          decoration:
              BoxDecoration(borderRadius: BorderRadius.circular(20), color: const Color.fromARGB(255, 29, 29, 29)),
          child: Column(
            children: [
              Container(
                height: 45,
                child: Stack(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _categoryTitle("Episodes"),
                      ],
                    ),
                    if (foundName != null)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: IconButton(
                              tooltip: gridMode ? "switch to list view" : "switch to grid view",
                              onPressed: () {
                                setState(() {
                                  gridMode = !gridMode;
                                  UserPreferences()
                                      .saveUserPreferences(UserPreferencesModal(episodeGridView: gridMode));
                                });
                              },
                              icon: Icon(
                                gridMode ? Icons.view_list_rounded : Icons.grid_view_rounded,
                              ),
                              color: textMainColor,
                              iconSize: 28,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              _epSearcherror
                  ? Container(
                      width: 350,
                      height: 120,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'lib/assets/images/broken_heart.png',
                              scale: 7.5,
                            ),
                            Text(
                              "Couldnt get any results :(",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: "NunitoSans",
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : foundName != null
                      ? Column(
                          children: [
                            _pages(),
                            AnimatedSwitcher(
                              duration: Duration(milliseconds: 400),
                              child: gridMode ? _episodesGrid() : _episodes(),
                            ),
                          ],
                        )
                      : Container(
                          width: 350,
                          height: 100,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: accentColor,
                            ),
                          ),
                        ),
              // ),
            ],
          ),
        ),
      ],
    );
  }

  Container _manualSearch(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(right: 20, top: 15),
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            showDragHandle: true,
            backgroundColor: Color(0xff121212),
            builder: (context) => ManualSearchSheet(
              searchString: data.title['english'] ?? data.title['romaji'] ?? '',
              source: selectedSource,
              anilistId: widget.id.toString(),
            ),
          ).then((result) async {
            if (result == null) return;
            setState(() {
              _epSearcherror = false;
              foundName = null;
            });
            final links = await getAnimeEpisodes(selectedSource, result['alias']);
            if (mounted)
              setState(() {
                paginate(links);
                foundName = result['name'];
              });
          });
        },
        child: Text(
          "Manual Search",
          style: TextStyle(
            color: Colors.transparent,
            decoration: TextDecoration.underline,
            decorationColor: textMainColor,
            decorationStyle: TextDecorationStyle.solid,
            decorationThickness: 2,
            fontFamily: "NotoSans",
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: textMainColor, offset: Offset(0, -2))],
          ),
        ),
      ),
    );
  }

  Container _pages() {
    return Container(
      height: 35,
      margin: EdgeInsets.only(bottom: 10, top: 10),
      padding: EdgeInsets.only(left: 10, right: 10),
      child: ListView.builder(
        itemCount: visibleEpList.length,
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(left: 10),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: currentPageIndex == index ? accentColor : backgroundColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      currentPageIndex = index;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.only(
                      left: 10,
                      right: 10,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "${(index * 24) + 1} - ${(index * 24) + 24 > epLinks.length ? epLinks.length : (index * 24) + 24}",
                      style: TextStyle(
                        color: currentPageIndex == index ? backgroundColor : textMainColor,
                        fontFamily: 'NotoSans',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Container _continueButton() {
    return Container(
      margin: EdgeInsets.only(
        top: 25,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: accentColor),
        color: Colors.black,
        image: DecorationImage(
          image: data.banner != null ? NetworkImage(data.banner!) : NetworkImage(data.cover),
          fit: BoxFit.cover,
          opacity: 0.46,
        ),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        onTap: () async {
          showModalBottomSheet(
            isScrollControlled: true,
            showDragHandle: true,
            backgroundColor: Color(0xff121212),
            context: context,
            builder: (BuildContext context) {
              return ServerSelectionBottomSheet(
                getStreams: getStreams,
                bottomSheetContentData: ServerSelectionBottomSheetContentData(
                  epLinks: epLinks,
                  episodeIndex: watched,
                  selectedSource: selectedSource,
                  title: data.title['english'] ?? data.title['romaji'] ?? '',
                  id: widget.id,
                  cover: data.cover,
                ),
                type: Type.watch,
                getWatched: getWatched,
              );
            },
          ).then((val) {
            if (val == true) {
              refreshListStatus("CURRENT", watched);
            }
          });
        },
        child:
            // Column(
            // crossAxisAlignment: CrossAxisAlignment.start,
            // mainAxisSize: MainAxisSize.min,
            // children: [
            Container(
          width: 325,
          height: 80,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${started ? 'Continue' : 'Start'} from:',
                  style: TextStyle(
                    color: accentColor,
                    fontFamily: "Rubik",
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Episode ${watched < epLinks.length ? watched + 1 : watched}',
                  style: TextStyle(
                    color: accentColor,
                    fontFamily: "Rubik",
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          ),
        ),

        //needs to store progress :(
        // Container(
        //   width: 325 * ((timeProgress[watched < epLinks.length ? watched + 1 : watched]) ?? 1 / 100),
        //   margin: EdgeInsets.only(left: 15),
        //   height: 2,
        //   decoration: BoxDecoration(
        //     borderRadius: BorderRadius.circular(10),
        //     color: textMainColor,
        //   ),
        // ),
        // ],
        // ),
      ),
    );
  }

  Container _searchStatus() {
    dynamic text = "searching: ${data.title['english'] ?? data.title['romaji'] ?? ''}";
    if (foundName != null) {
      text = "found: $foundName";
    } else if (_epSearcherror) {
      text = "couldnt't find any matches";
    }
    return Container(
      width: 300,
      margin: EdgeInsets.only(top: 5),
      padding: EdgeInsets.only(left: 8, right: 8),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontFamily: "NotoSans",
          fontWeight: FontWeight.bold,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  GridView _episodesGrid() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).orientation == Orientation.portrait ? 2 : 5,
        childAspectRatio: MediaQuery.of(context).orientation == Orientation.portrait ? 1 / 1.3 : 1 / 1.4,
        mainAxisSpacing: 15,
        crossAxisSpacing: 15,
      ),
      itemCount: visibleEpList[currentPageIndex].length,
      padding: EdgeInsets.all(15),
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) => GestureDetector(
        onTap: () {
          showModalBottomSheet(
              showDragHandle: true,
              context: context,
              isScrollControlled: true,
              backgroundColor: Color(0xff121212),
              builder: (context) {
                return ServerSelectionBottomSheet(
                  getStreams: getStreams,
                  bottomSheetContentData: ServerSelectionBottomSheetContentData(
                      epLinks: epLinks,
                      episodeIndex: visibleEpList[currentPageIndex][index]['realIndex'],
                      selectedSource: selectedSource,
                      title: data.title['english'] ?? data.title['romaji'] ?? '',
                      id: widget.id,
                      cover: data.cover),
                  type: Type.watch,
                  getWatched: getWatched,
                );
              }).then((val) {
            if (val == true) {
              refreshListStatus("CURRENT", watched);
            }
          });
        },
        child: Container(
          // padding: EdgeInsets.all(10),
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: backgroundColor,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Opacity(
                opacity: visibleEpList[currentPageIndex][index]['realIndex'] + 1 > watched ? 1.0 : 0.5,
                child: Container(
                  height: 140,
                  width: 175,
                  margin: EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    image: DecorationImage(
                        image: NetworkImage(
                          data.cover,
                        ),
                        fit: BoxFit.cover),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(topLeft: Radius.circular(15)),
                            color: accentColor.withOpacity(0.8)),
                        child: IconButton(
                          onPressed: () async {
                            showModalBottomSheet(
                              showDragHandle: true,
                              isScrollControlled: true,
                              context: context,
                              builder: (BuildContext context) {
                                return ServerSelectionBottomSheet(
                                  getStreams: getStreams,
                                  bottomSheetContentData: ServerSelectionBottomSheetContentData(
                                    epLinks: epLinks,
                                    episodeIndex: visibleEpList[currentPageIndex][index]['realIndex'],
                                    selectedSource: selectedSource,
                                    title: data.title['english'] ?? data.title['romaji'] ?? '',
                                    id: widget.id,
                                    cover: data.cover,
                                  ),
                                  type: Type.download,
                                );
                              },
                            );
                          },
                          icon: Icon(
                            Icons.download_rounded,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 10, right: 10),
                child: Text(
                  "Episode ${visibleEpList[currentPageIndex][index]['realIndex'] + 1}",
                  style: TextStyle(
                    color: visibleEpList[currentPageIndex][index]['realIndex'] + 1 > watched
                        ? Colors.white
                        : Color.fromARGB(155, 255, 255, 255),
                    fontFamily: 'Poppins',
                    fontSize: 17,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  ListView _episodes() {
    return ListView.builder(
      padding: EdgeInsets.only(top: 0, bottom: 15),
      itemCount: visibleEpList[currentPageIndex].length,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () async {
            showModalBottomSheet(
                showDragHandle: true,
                isScrollControlled: true,
                context: context,
                builder: (context) {
                  return ServerSelectionBottomSheet(
                    getStreams: getStreams,
                    bottomSheetContentData: ServerSelectionBottomSheetContentData(
                      epLinks: epLinks,
                      episodeIndex: visibleEpList[currentPageIndex][index]['realIndex'],
                      selectedSource: selectedSource,
                      title: data.title['english'] ?? data.title['romaji'] ?? '',
                      id: widget.id,
                      cover: data.cover,
                    ),
                    type: Type.watch,
                    getWatched: getWatched,
                  );
                });
          },

          //list style
          // child: Container(
          //   padding: EdgeInsets.only(left: 20, right: 20),
          //   child: Container(
          //     child: Column(
          //       mainAxisSize: MainAxisSize.min,
          //       children: [
          //         Padding(
          //           padding: EdgeInsets.only(left: 20, right: 20),
          //           child: Row(
          //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //             children: [
          //               Text("Episode ${index+1}", style: TextStyle(color: textMainColor, fontFamily: "NotoSans", fontWeight: FontWeight.bold, fontSize: 17),),
          //               Icon(Icons.download_rounded, color: textMainColor,)
          //             ],
          //           ),
          //         ),
          //         Padding(
          //           padding: const EdgeInsets.only(top:8, left: 40, right: 40),
          //           child: Divider(),
          //         )
          //       ],
          //     ),
          //   ),
          // ),

          //saikou style
          child: Stack(
            children: [
              Container(
                clipBehavior: Clip.hardEdge,
                height: 110,
                margin: EdgeInsets.only(top: 10, left: 10, right: 10),
                padding: EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.black,
                ),
                alignment: Alignment.center,
                child: Stack(
                  children: [
                    Opacity(
                      opacity: visibleEpList[currentPageIndex][index]['realIndex'] + 1 > watched ? 1.0 : 0.5,
                      child: ShaderMask(
                        blendMode: BlendMode.darken,
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [Colors.transparent, Color.fromARGB(245, 0, 0, 0)],
                          stops: [0.2, 1.0],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ).createShader(bounds),
                        child: Image.network(
                          data.cover,
                          fit: BoxFit.cover,
                          width: 165,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 140,
                        ),
                        // Image.network(data.cover, fit: BoxFit.fill,),
                        // ClipRRect(
                        //   borderRadius: BorderRadius.circular(15),
                        // child: Opacity(
                        //   opacity: visibleEpList[currentPageIndex][index]['realIndex'] + 1 > watched ? 1.0 : 0.6,
                        //     child: Image.network(
                        //       data.cover,
                        //       width: 140,
                        //       height: 90,
                        //       fit: BoxFit.cover,
                        //     ),
                        //   ),
                        // ),
                        Text(
                          "Episode ${visibleEpList[currentPageIndex][index]['realIndex'] + 1}",
                          style: TextStyle(
                            color: visibleEpList[currentPageIndex][index]['realIndex'] + 1 > watched
                                ? Colors.white
                                : Color.fromARGB(155, 255, 255, 255),
                            fontFamily: "Poppins",
                            fontSize: 18,
                          ),
                        ),
                        // ),
                        Container(
                          child: IconButton(
                            onPressed: () async {
                              showModalBottomSheet(
                                showDragHandle: true,
                                context: context,
                                isScrollControlled: true,
                                builder: (BuildContext context) {
                                  return ServerSelectionBottomSheet(
                                    getStreams: getStreams,
                                    bottomSheetContentData: ServerSelectionBottomSheetContentData(
                                      epLinks: epLinks,
                                      episodeIndex: visibleEpList[currentPageIndex][index]['realIndex'],
                                      selectedSource: selectedSource,
                                      title: data.title['english'] ?? data.title['romaji'] ?? '',
                                      id: widget.id,
                                      cover: data.cover,
                                    ),
                                    type: Type.download,
                                  );
                                },
                              );
                            },
                            icon: Icon(
                              Icons.download_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (watched > visibleEpList[currentPageIndex][index]['realIndex'])
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20, right: 25),
                    child: ImageIcon(
                      AssetImage('lib/assets/images/check.png'),
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Container _infoItems(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: 50),
            child: Column(
              children: [
                _buildInfoItems(
                  _infoLeft('Type'),
                  _infoRight(data.type.toLowerCase()),
                ),
                _buildInfoItems(
                  _infoLeft('Status'),
                  _infoRight('${data.status ?? '??'}'.toLowerCase()),
                ),
                _buildInfoItems(
                  _infoLeft('Rating'),
                  _infoRight('${data.rating ?? '??'}/10'),
                ),
                _buildInfoItems(
                  _infoLeft('Episodes'),
                  _infoRight('${data.episodes ?? '??'}'),
                ),
                _buildInfoItems(
                  _infoLeft('Duration'),
                  _infoRight('${data.duration}'),
                ),
                _buildInfoItems(
                  _infoLeft('Studios'),
                  _infoRight(data.studios.isEmpty ? '??' : data.studios[0] ?? '??'),
                ),
              ],
            ),
          ),
          // Container(
          //   child: Column(
          //     children: [
          //       _categoryTitle("Alternate Titles"),
          //     ],
          //   ),
          // ),
          Container(
            margin: EdgeInsets.only(top: 30),
            padding: EdgeInsets.only(left: 15, right: 15),
            child: Column(
              children: [
                _categoryTitle('Genres'),
                SizedBox(
                  height: 65,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: data.genres.length,
                    itemBuilder: (context, index) {
                      return Container(
                        alignment: Alignment.center,
                        margin: EdgeInsets.all(5),
                        padding: EdgeInsets.only(left: 15, right: 15),
                        decoration: BoxDecoration(color: Colors.grey.shade700, borderRadius: BorderRadius.circular(20)),
                        child: Text(
                          data.genres[index],
                          style: TextStyle(
                            color: textMainColor,
                            fontSize: 20,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 30),
            padding: EdgeInsets.only(left: 15, right: 15),
            child: Column(
              children: [
                _categoryTitle('Tags'),
                SizedBox(
                  height: 45,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: data.genres.length,
                    itemBuilder: (context, index) {
                      return Container(
                        alignment: Alignment.center,
                        margin: EdgeInsets.all(5),
                        padding: EdgeInsets.only(left: 15, right: 15),
                        decoration: BoxDecoration(color: Colors.grey.shade800, borderRadius: BorderRadius.circular(5)),
                        child: Text(
                          data.tags[index],
                          style: TextStyle(
                            color: textMainColor,
                            fontSize: 15,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 30),
            padding: EdgeInsets.only(left: 25, right: 25),
            child: Column(
              children: [
                _categoryTitle('Description'),
                Text(
                  data.synopsis ?? '',
                  style: TextStyle(
                    color: textMainColor,
                    fontFamily: "NunitoSans",
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 30),
            child: Column(
              children: [
                _categoryTitle('Characters'),
                SizedBox(
                  height: 260,
                  child: ListView.builder(
                    itemCount: data.characters.length,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final character = data.characters[index];
                      return Container(
                        width: 130,
                        child: Cards().characterCard(
                          character['name'],
                          character['role'],
                          character['image'],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 20),
            child: Column(
              children: [
                _categoryTitle('Related'),
                _buildRecAndRel(data.related, false, context),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 20),
            child: Column(
              children: [
                _categoryTitle('Recommended'),
                _buildRecAndRel(data.recommended, true, context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Container _buildInfoItems(Widget itemLeft, Widget itemRight) {
    return Container(
      padding: EdgeInsets.only(left: 15, right: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          itemLeft,
          Container(width: 150, child: itemRight),
        ],
      ),
    );
  }

  SizedBox _buildRecAndRel(List data, bool recommended, BuildContext context) {
    if (data.length == 0)
      return SizedBox(
        height: 240,
        child: Center(
          child: const Text(
            'Nothing to see here!',
            style: TextStyle(
              fontFamily: "NunitoSans",
              fontSize: 18,
              color: const Color.fromARGB(255, 255, 255, 255),
            ),
          ),
        ),
      );
    return SizedBox(
      height: 260,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: data.length,
        itemBuilder: (context, index) {
          final item = data[index];
          return GestureDetector(
            onTap: () {
              if (item.type.toLowerCase() != "anime") {
                return floatingSnackBar(context, 'Mangas/Novels arent supported');
              }

              //only navigate if the list is being built by characterCard method.
              //since the animeCard has inbuilt navigation
              if (!recommended)
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => Info(
                      id: item.id,
                    ),
                  ),
                );
            },
            child: Container(
                width: 130,
                child: recommended
                    ? Cards(context: context).animeCard(
                        item.id,
                        item.title['english'] ?? item.title['romaji'],
                        item.cover,
                      )
                    : Cards().characterCard(
                        item.title['english'] ?? item.title['romaji'],
                        recommended ? item.type : item.relationType,
                        item.cover,
                      )),
          );
        },
      ),
    );
  }

  Padding _categoryTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          color: textMainColor,
          fontFamily: "NatoSans",
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Padding _infoLeft(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        text,
        style: TextStyle(
            color: const Color.fromARGB(255, 141, 141, 141),
            fontSize: 17,
            fontFamily: "NatoSans",
            fontWeight: FontWeight.bold),
      ),
    );
  }

  Padding _infoRight(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        text,
        style: TextStyle(
          color: textMainColor,
          fontSize: 17,
          fontFamily: "NotoSans",
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.end,
      ),
    );
  }

  Stack _stack() {
    return Stack(
      children: [
        GestureDetector(
          onLongPress: () {
            final img = data.banner != null ? data.banner! : data.cover;
            showModalBottomSheet(
              context: context,
              showDragHandle: true,
              backgroundColor: Color.fromARGB(255, 19, 19, 19),
              builder: (BuildContext context) {
                return SingleChildScrollView(
                  child: Container(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Image.network(
                          img,
                          height: 250,
                        ),
                        Container(
                          margin: EdgeInsets.only(top: 20, bottom: 10),
                          alignment: Alignment.center,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () async {
                              final res = await get(Uri.parse(img));
                              await ImageGallerySaver.saveImage(
                                res.bodyBytes,
                                quality: 100,
                                name: data.title['english'] ?? data.title['romaji'] ?? '',
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              fixedSize: Size(150, 75),
                              backgroundColor: accentColor,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(color: accentColor),
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: Text(
                              "save",
                              style: TextStyle(
                                  color: backgroundColor,
                                  fontFamily: "Poppins",
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          child: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
                colors: [backgroundColor, Colors.transparent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                stops: [0.09, 0.23]).createShader(bounds),
            blendMode: BlendMode.darken,
            child: Container(
              height: 270,
              width: double.infinity,
              child: Image.network(
                data.banner != null ? data.banner! : data.cover,
                fit: BoxFit.cover,
                opacity: AlwaysStoppedAnimation(0.6),
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded) return child;
                  return AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: Duration(milliseconds: 300),
                    child: child,
                    curve: Curves.easeIn,
                  );
                },
              ),
            ),
          ),
        ),
        Container(
          alignment: Alignment.center,
          margin: EdgeInsets.only(top: 100),
          child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: CachedNetworkImage(
                imageUrl: data.cover,
                height: 220,
                fadeInDuration: Duration(milliseconds: 200),
                fadeInCurve: Curves.easeIn,
                // fit: BoxFit.cover,
              )),
        ),
        Container(
          margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          child: IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            iconSize: 27,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
            ),
            style: IconButton.styleFrom(backgroundColor: Color.fromARGB(69, 0, 0, 0)),
          ),
        ),
      ],
    );
  }
}
