import 'dart:io';

import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/extensions.dart';
import 'package:animestream/core/database/anilist/queries.dart';
import 'package:animestream/core/database/anilist/types.dart';
import 'package:animestream/ui/models/widgets/cards.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:animestream/ui/models/widgets/cards/animeCard.dart';
import 'package:animestream/ui/pages/settingPages/common.dart';
import 'package:flutter/material.dart';
import 'package:animestream/core/commons/genresAndTags.dart';

class GenresPage extends StatefulWidget {
  const GenresPage({super.key});

  @override
  State<GenresPage> createState() => _GenresPageState();
}

class _GenresPageState extends State<GenresPage> {
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(scrollListener);

    for (int i = 0; i < AnilistSortType.values.length; i++) {
      final e = AnilistSortType.values[i];
      final name = _toFriendlyString(e.value);
      sortTypesString.add(name);
      sortTypesMap.addAll({name: e});
    }
  }

  void scrollListener() async {
    //fetch more when scroll space is less than 300px
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      if (!_isLazyLoading) {
        print("loading...");
        getList(lazyLoaded: true);
      }
    }
  }

  Future<void> getList({bool lazyLoaded = false}) async {
    if (lazyLoaded) {
      _isLazyLoading = true;
      currentLoadedPage++;
    } else {
      currentLoadedPage = 1;
    }
    if (!_firstSearchDone) _firstSearchDone = true;
    try {
      setState(() {
        searchResultsAsWidgets = lazyLoaded ? searchResultsAsWidgets : [];
        _searching = true;
      });
      if (selectedGenres.isEmpty && selectedTags.isEmpty) {
        return;
      }
      print("loading page $currentLoadedPage");
      final res = await AnilistQueries().advancedSearch(
        genres: selectedGenres,
        tags: selectedTags,
        page: currentLoadedPage,
        ratingHigh: ratingRange.end.toInt(),
        ratingLow: ratingRange.start.toInt(),
        sort: sortTypesMap[sortType]!,
      );
      res.forEach((e) {
        final defaultTitle = e.title['english'] ?? e.title['romaji'] ?? '';
        final title = (currentUserSettings?.nativeTitle ?? false) ? e.title['native'] ?? defaultTitle : defaultTitle;
        searchResultsAsWidgets.add(
          Cards.animeCard(
            e.id,
            title,
            e.cover,
            ongoing: e.status == "RELEASING",
            rating: e.rating,
            isMobile: Platform.isAndroid,
          ),
        );
      });
      setState(() {
        _searching = false;
        _isLazyLoading = false;
      });
    } catch (err, st) {
      print(st);
      if (currentUserSettings?.showErrors ?? false) {
        floatingSnackBar(err.toString());
      }
      setState(() {
        _searching = false;
        _isLazyLoading = false;
      });
    }
  }

  /// Change the AnilistSortType strings to a more userfriendly string
  /// for example "TRENDING_DESC" -> "Trending Desc"
  static String _toFriendlyString(String input) {
    return input.split("_").map((e) => e.toLowerCase().capitalize()).join(" ");
  }

  //genre and tags list will be read from genresAndTags.dart file

  List<String> selectedGenres = [];
  List<String> selectedTags = [];

  String sortType = _toFriendlyString(AnilistSortType.trendingDesc.value);
  List<String> sortTypesString = [];
  Map<String, AnilistSortType> sortTypesMap = {};

  RangeValues ratingRange = RangeValues(1, 10);

  List<AnimeCard> searchResultsAsWidgets = [];

  int currentLoadedPage = 1;

  bool _searching = false;
  bool _isLazyLoading = false;
  bool _firstSearchDone = false;

  final ScrollController _scrollController = ScrollController();
  final ScrollController _tagsScrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      body: Padding(
        padding: pagePadding(context),
        child: Column(
          children: [
            topRow(context, "Genres"),
            Container(
              padding: EdgeInsets.only(left: 15, right: 15, top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    child: Text(
                      "Results",
                      style: TextStyle(
                          color: appTheme.textMainColor,
                          fontFamily: "NotoSans",
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: appTheme.modalSheetBackgroundColor,
                        isScrollControlled: true,
                        showDragHandle: true,
                        builder: (context) => StatefulBuilder(
                          builder: (context, setChildState) => Container(
                            width: double.infinity,
                            padding:
                                EdgeInsets.only(left: 15, right: 15, bottom: MediaQuery.of(context).padding.bottom),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Filters",
                                  style: TextStyle(
                                      color: appTheme.textMainColor,
                                      fontFamily: "Rubik",
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                                _scrollablelListWithTitle(setChildState,
                                    title: "Genres", mainList: genres, selectedList: selectedGenres),
                                _scrollablelListWithTitle(setChildState,
                                    title: "Tags", mainList: tags, selectedList: selectedTags),
                                _scrollablelRadioListWithTitle(
                                    title: "Sort",
                                    value: sortType,
                                    setChildState: setChildState,
                                    options: sortTypesString,
                                    onTap: (e) {
                                      sortType = e;
                                    }),
                                _filterItemTitle("Rating range"),
                                RangeSlider(
                                  values: ratingRange,
                                  min: 1,
                                  max: 10,
                                  divisions: 9,
                                  activeColor: appTheme.accentColor,
                                  labels: RangeLabels(ratingRange.start.toString(), ratingRange.end.toString()),
                                  onChanged: (rv) {
                                    setChildState(() {
                                      ratingRange = RangeValues(rv.start.roundToDouble(), rv.end.roundToDouble());
                                    });
                                  },
                                ),
                                Container(
                                  margin: EdgeInsets.only(top: 25),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        margin: EdgeInsets.only(right: 20),
                                        child: ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          style: ElevatedButton.styleFrom(backgroundColor: appTheme.accentColor),
                                          child: Text(
                                            "Cancel",
                                            style: TextStyle(color: appTheme.backgroundColor, fontFamily: "Poppins"),
                                          ),
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          // call twice on windows cus of the screen size :)
                                          getList().then((_) {
                                            if (Platform.isWindows) getList(lazyLoaded: true);
                                          });
                                          Navigator.of(context).pop();
                                        },
                                        style: ElevatedButton.styleFrom(backgroundColor: appTheme.accentColor),
                                        child: Text(
                                          "Apply",
                                          style: TextStyle(color: appTheme.backgroundColor, fontFamily: "Poppins"),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: appTheme.backgroundColor),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(
                          Icons.filter_alt_rounded,
                          color: appTheme.textMainColor,
                        ),
                        Text(
                          "filters",
                          style: TextStyle(color: appTheme.textMainColor),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.only(
                  left: 10,
                  right: 10,
                  top: 20,
                ),
                child: searchResultsAsWidgets.isEmpty && !_searching
                    ? Container(
                        margin: EdgeInsets.only(top: 40),
                        child: Center(
                          child: _firstSearchDone
                              ? Column(
                                  children: [
                                    Container(
                                        padding: EdgeInsets.only(bottom: 10),
                                        child: Image.asset(
                                          'lib/assets/images/ghost.png',
                                          color: appTheme.textMainColor,
                                        )),
                                    Text(
                                      "~~nooo matches~~",
                                      style: TextStyle(
                                          color: appTheme.textMainColor, fontFamily: "NunitoSans", fontSize: 17),
                                    ),
                                  ],
                                )
                              : Text(
                                  'Apply filters to discover animes!',
                                  style:
                                      TextStyle(color: appTheme.textMainColor, fontFamily: "NunitoSans", fontSize: 16),
                                  textAlign: TextAlign.center,
                                ),
                        ),
                      )
                    : Container(
                        foregroundDecoration: BoxDecoration(
                            gradient: LinearGradient(
                                colors: [
                                  appTheme.backgroundColor,
                                  appTheme.backgroundColor.withAlpha(0),
                                  appTheme.backgroundColor.withAlpha(0),
                                  appTheme.backgroundColor
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                stops: [0.00, 0.04, 0.96, 1])),
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          child: Column(
                            children: [
                              GridView.builder(
                                physics: NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: Platform.isAndroid ? 140 : 180,
                                    mainAxisExtent: Platform.isAndroid ? 220 : 260,
                                    // crossAxisCount: MediaQuery.of(context).orientation == Orientation.portrait ? 3 : 6,
                                    // childAspectRatio: 120 / 220,
                                    mainAxisSpacing: 10),
                                padding: EdgeInsets.only(top: 20, bottom: MediaQuery.of(context).padding.bottom),
                                shrinkWrap: true,
                                itemCount: searchResultsAsWidgets.length,
                                itemBuilder: (context, index) => Container(
                                  alignment: Alignment.center,
                                  child: searchResultsAsWidgets[index],
                                ),
                              ),
                              if (_searching)
                                Container(
                                  margin: EdgeInsets.only(top: 40, bottom: MediaQuery.of(context).padding.bottom + 10),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: appTheme.accentColor,
                                    ),
                                  ),
                                )
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Container _filterItemTitle(String title) {
    return Container(
      padding: const EdgeInsets.only(bottom: 15, top: 20, left: 20),
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          color: appTheme.textMainColor,
          fontFamily: "Rubik",
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Column _scrollablelRadioListWithTitle<T>(
      {required StateSetter setChildState,
      required String title,
      required T value,
      required List<String> options,
      required void Function(String selectedItem) onTap}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.only(bottom: 15, top: 20, left: 20),
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            style: TextStyle(
              color: appTheme.textMainColor,
              fontFamily: "Rubik",
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: options
                .map(
                  (e) => Container(
                    margin: EdgeInsets.only(left: 5, right: 5),
                    child: GestureDetector(
                      onTap: () {
                        onTap(e);

                        setChildState(() {});
                      },
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 150),
                        padding: EdgeInsets.only(left: 10, right: 10),
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: value == e ? appTheme.accentColor : appTheme.backgroundSubColor,
                            borderRadius: BorderRadius.circular(13)),
                        child: Text(
                          e,
                          style: TextStyle(
                              color: value == e ? appTheme.backgroundColor : appTheme.textMainColor,
                              fontFamily: "NotoSans",
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Column _scrollablelListWithTitle(StateSetter setChildState,
      {required String title, required List<String> mainList, required List<String> selectedList}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.only(bottom: 15, top: 20, left: 20),
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: TextStyle(
                  color: appTheme.textMainColor,
                  fontFamily: "Rubik",
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => StatefulBuilder(
                      builder: (context, setDialogState) => AlertDialog(
                        backgroundColor: Color(0xff121212),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                                padding: EdgeInsets.only(bottom: 20),
                                child: Text(
                                  title,
                                  style: TextStyle(color: appTheme.textMainColor, fontFamily: "Rubik", fontSize: 23),
                                )),
                            Container(
                              height: 550,
                              width: 500,
                              child: Scrollbar(
                                controller: _tagsScrollController,
                                interactive: true,
                                child: GridView(
                                    controller: _tagsScrollController,
                                    shrinkWrap: true,
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      mainAxisSpacing: 15,
                                      crossAxisSpacing: 15,
                                    ),
                                    children: mainList
                                        .map(
                                          (e) => GestureDetector(
                                            onTap: () {
                                              if (selectedList.contains(e))
                                                selectedList.remove(e);
                                              else
                                                selectedList.add(e);
                                              setChildState(() {});
                                              setDialogState(() {});
                                            },
                                            child: AnimatedContainer(
                                              duration: Duration(milliseconds: 150),
                                              padding: EdgeInsets.only(left: 10, right: 10),
                                              height: 40,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                  color: selectedList.contains(e)
                                                      ? appTheme.accentColor
                                                      : appTheme.backgroundSubColor,
                                                  borderRadius: BorderRadius.circular(13)),
                                              child: Text(
                                                e,
                                                style: TextStyle(
                                                    color: selectedList.contains(e)
                                                        ? appTheme.backgroundColor
                                                        : appTheme.textMainColor,
                                                    fontFamily: "NotoSans",
                                                    fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList()),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(top: 10),
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: appTheme.accentColor),
                                child: Text(
                                  "close",
                                  style: TextStyle(color: appTheme.backgroundColor, fontFamily: "Poppins"),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                icon: Icon(
                  Icons.grid_3x3_rounded,
                  color: appTheme.textMainColor,
                ))
          ],
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: mainList
                .map(
                  (e) => Container(
                    margin: EdgeInsets.only(left: 5, right: 5),
                    child: GestureDetector(
                      onTap: () {
                        if (selectedList.contains(e))
                          selectedList.remove(e);
                        else
                          selectedList.add(e);

                        setChildState(() {});
                      },
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 150),
                        padding: EdgeInsets.only(left: 10, right: 10),
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: selectedList.contains(e) ? appTheme.accentColor : appTheme.backgroundSubColor,
                            borderRadius: BorderRadius.circular(13)),
                        child: Text(
                          e,
                          style: TextStyle(
                              color: selectedList.contains(e) ? appTheme.backgroundColor : appTheme.textMainColor,
                              fontFamily: "NotoSans",
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}
