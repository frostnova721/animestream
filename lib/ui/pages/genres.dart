import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/database/anilist/queries.dart';
import 'package:animestream/ui/models/cards.dart';
import 'package:animestream/ui/models/snackBar.dart';
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

  void getList({bool lazyLoaded = false}) async {
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
      final res = await AnilistQueries().getAnimesWithGenresAndTags(
        selectedGenres,
        selectedTags,
        page: currentLoadedPage,
        ratingHigh: ratingRange.end.toInt(),
        ratingLow: ratingRange.start.toInt(),
      );
      res.forEach((e) {
        searchResultsAsWidgets.add(
          Cards(context: context).animeCard(
            e.id,
            e.title['english'] ?? e.title['romaji'] ?? '',
            e.cover,
            ongoing: e.status == "RELEASING",
            rating: e.rating,
          ),
        );
      });
      setState(() {
        _searching = false;
        _isLazyLoading = false;
      });
    } catch (err) {
      if (currentUserSettings?.showErrors ?? false) {
        floatingSnackBar(context, err.toString());
      }
    }
  }

  //genre and tags list will be read from genresAndTags.dart file

  List<String> selectedGenres = [];
  List<String> selectedTags = [];

  RangeValues ratingRange = RangeValues(1, 10);

  List<Card> searchResultsAsWidgets = [];

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
        child: SingleChildScrollView(
          controller: _scrollController,
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
                                            getList();
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
              Container(
                padding: EdgeInsets.only(left: 10, right: 10, top: 20, bottom: MediaQuery.of(context).padding.bottom),
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
                    : Column(
                        children: [
                          GridView.builder(
                            physics: NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 140,
                                mainAxisExtent: 230,
                                // crossAxisCount: MediaQuery.of(context).orientation == Orientation.portrait ? 3 : 6,
                                childAspectRatio: 120 / 220,
                                mainAxisSpacing: 10),
                            padding: EdgeInsets.only(top: 20, bottom: MediaQuery.of(context).padding.bottom),
                            shrinkWrap: true,
                            itemCount: searchResultsAsWidgets.length,
                            itemBuilder: (context, index) => Container(
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
            ],
          ),
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
