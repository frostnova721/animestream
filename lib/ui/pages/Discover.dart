import 'dart:async';
import 'dart:ui';

import 'package:animestream/core/database/anilist/queries.dart';
import 'package:animestream/core/database/anilist/types.dart';
import 'package:animestream/ui/models/cards.dart';
import 'package:animestream/ui/pages/genres.dart';
import 'package:animestream/ui/pages/info.dart';
import 'package:animestream/ui/pages/news.dart';
import 'package:animestream/ui/theme/mainTheme.dart';
import 'package:flutter/material.dart';
import 'package:animestream/core/database/anilist/anilist.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class Discover extends StatefulWidget {
  final List currentSeason;
  const Discover({super.key, required this.currentSeason});

  @override
  State<Discover> createState() => _DiscoverState();
}

class _DiscoverState extends State<Discover> {
  @override
  void initState() {
    super.initState();
    getLists();
    getTrendingList();
    getRecentlyUpdated();
    getRecommended();
  }

  List thisSeason = [];
  List<TrendingResult> trendingList = [];
  List<AnimeWidget> recentlyUpdatedList = [];
  List<AnimeWidget> recommendedList = [];
  int currentPage = 0;
  final PageController _pageController = PageController();
  Timer? timer;
  bool trendingLoaded = false, recentlyUpdatedLoaded = false, recommendedLoaded = false;

  Future getLists() async {
    thisSeason = widget.currentSeason;

    if (mounted) setState(() {});
  }

  Future<void> getTrendingList() async {
    final list = await Anilist().getTrending();
    if (mounted)
      setState(() {
        trendingList = list.sublist(0, 20);
        trendingLoaded = true;
        pageTimeout();
      });
  }

  Future<void> getRecommended() async {
    final list = await AnilistQueries().getRecommendedAnimes();
    for (final item in list) {
      recommendedList.add(
        AnimeWidget(
          widget: animeCard(item.title['english'] ?? item.title['romaji'] ?? '', item.cover),
          info: {'id': item.id},
        ),
      );
    }
    if (mounted)
      setState(() {
        recommendedLoaded = true;
      });
  }

  Future<void> getRecentlyUpdated() async {
    final list = await Anilist().recentlyUpdated();
    //to filter out the dupes
    Set<int> ids = {};
    for (final elem in list) {
      if (!ids.contains(elem.id)) {
        ids.add(elem.id);
        recentlyUpdatedList.add(
          AnimeWidget(
            widget: animeCard(elem.title['english'] ?? elem.title['romaji'] ?? '', elem.cover),
            info: {'id': elem.id},
          ),
        );
      }
    }
    if (mounted)
      setState(() {
        recentlyUpdatedLoaded = true;
      });
  }

  Future<void> pageTimeout() async {
    if (timer != null && timer!.isActive) timer!.cancel();
    timer = Timer(Duration(seconds: 5), () {
      if (currentPage < trendingList.length - 1) {
        currentPage++;
      } else
        currentPage = 0;
      if (mounted)
        setState(() {
          _pageController.animateToPage(currentPage, duration: Duration(milliseconds: 200), curve: Curves.easeIn);
        });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.only(top: 30),
          height: 275,
          // width: double.infinity,
          child: trendingLoaded
              ? _trendingAnimesPageView()
              : Container(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: accentColor,
                    ),
                  ),
                ),
        ),
        if (trendingList.isNotEmpty)
          Container(
            margin: EdgeInsets.only(top: 10),
            child: SmoothPageIndicator(
              controller: _pageController,
              count: trendingList.length,
              axisDirection: Axis.horizontal,
              effect: ScrollingDotsEffect(
                activeDotColor: accentColor,
                dotColor: textMainColor,
                dotHeight: 5,
                dotWidth: 5,
              ),
              onDotClicked: (index) {
                _pageController.animateToPage(index, duration: Duration(milliseconds: 250), curve: Curves.easeIn);
              },
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              margin: EdgeInsets.only(top: 30, right: 25),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => News()));
                },
                child: Container(
                  height: 50,
                  width: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: DecorationImage(
                        image: AssetImage(
                          'lib/assets/images/chisato.jpeg',
                        ),
                        fit: BoxFit.cover,
                        opacity: 0.35),
                    border: Border.all(color: accentColor),
                  ),
                  child: Center(
                    child: Text(
                      "News",
                      style: TextStyle(
                        color: textMainColor,
                        fontFamily: "NotoSans",
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 30),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => GenresPage()));
                },
                child: Container(
                  height: 50,
                  width: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: DecorationImage(
                        image: AssetImage(
                          'lib/assets/images/mitsuha.jpg',
                        ),
                        fit: BoxFit.cover,
                        opacity: 0.35),
                    border: Border.all(color: accentColor),
                  ),
                  child: Center(
                    child: Text(
                      "Genres",
                      style: TextStyle(
                        color: textMainColor,
                        fontFamily: "NotoSans",
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        _itemTitle("Recently updated"),
        _scrollList(recentlyUpdatedList),
        _itemTitle("This season"),
        _scrollList(thisSeason),
        _itemTitle("Recommended"),
        _scrollList(recommendedList),
      ],
    );
  }

  PageView _trendingAnimesPageView() {
    return PageView.builder(
        pageSnapping: true,
        controller: _pageController,
        // itemCount: trendingList.length,
        onPageChanged: (page) async {
          currentPage = page;
          await pageTimeout();
        },
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Info(
                    id: trendingList[index % trendingList.length].id,
                  ),
                ),
              );
            },
            child: Container(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    child: ClipRRect(
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Image.network(
                          trendingList[index % trendingList.length].banner ??
                              trendingList[index % trendingList.length].cover,
                          opacity: AlwaysStoppedAnimation(0.5),
                          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                            if (wasSynchronouslyLoaded) return child;
                            return AnimatedOpacity(
                              opacity: frame == null ? 0 : 1,
                              duration: Duration(milliseconds: 150),
                              child: child,
                            );
                          },
                          height: 275,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    // ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 20.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            trendingList[index % trendingList.length].cover,
                            height: 170,
                            width: 120,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.only(left: 10, right: 10),
                          width: 250,
                          child: Column(
                            // mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10.0),
                                child: Text(
                                  trendingList[index % trendingList.length].title['english'] ??
                                      trendingList[index % trendingList.length].title['romaji'] ??
                                      '',
                                  style: TextStyle(
                                    color: textMainColor,
                                    fontFamily: 'NunitoSans',
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  maxLines: 2,
                                ),
                              ),
                              Text(
                                trendingList[index % trendingList.length].genres.join(', '),
                                style: TextStyle(
                                    color: Color.fromARGB(255, 180, 180, 180),
                                    fontFamily: 'NunitoSans',
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    overflow: TextOverflow.ellipsis),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.star,
                                      color: textMainColor,
                                      size: 20,
                                    ),
                                    Text(
                                      "${trendingList[index % trendingList.length].rating != null ? trendingList[index % trendingList.length].rating! / 10 : '??'}",
                                      style: TextStyle(color: textMainColor, fontFamily: "Rubik", fontSize: 17),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  Container _scrollList(List<dynamic> list) {
    return Container(
        height: 230,
        padding: EdgeInsets.only(left: 10, right: 10),
        child: list.length > 0
            ? ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: list.length,
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) => GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Info(
                          id: list[index].info['id'],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 125,
                    child: list[index].widget,
                  ),
                ),
              )
            : Center(
                child: CircularProgressIndicator(
                  color: accentColor,
                ),
              ));
  }

  Container _itemTitle(String title) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.only(top: 25, left: 25, right: 25, bottom: 20),
      child: Text(
        title,
        style: basicTextStyle("Rubik", 20),
      ),
    );
  }

  TextStyle basicTextStyle(String? family, double? size) {
    return TextStyle(
      color: Colors.white,
      fontFamily: family ?? 'NotoSans',
      fontSize: size ?? 15,
    );
  }

  @override
  void dispose() {
    super.dispose();
    _pageController.dispose();
    if (timer != null && timer!.isActive) timer?.cancel();
  }
}
