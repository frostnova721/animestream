import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/database/anilist/types.dart';
import 'package:animestream/ui/models/widgets/cards.dart';
import 'package:animestream/ui/models/widgets/header.dart';
import 'package:animestream/ui/pages/genres.dart';
import 'package:animestream/ui/pages/info.dart';
import 'package:animestream/ui/pages/news.dart';
import 'package:animestream/ui/pages/settingPages/common.dart';

class Discover extends StatefulWidget {
  final List<AnimeCard> thisSeason;
  final List<TrendingResult> trendingList;
  final List<AnimeCard> recentlyUpdatedList;
  final List<AnimeCard> recommendedList;
  const Discover({
    super.key,
    required this.recentlyUpdatedList,
    required this.recommendedList,
    required this.thisSeason,
    required this.trendingList,
  });

  @override
  State<Discover> createState() => _DiscoverState();
}

class _DiscoverState extends State<Discover> {
  @override
  void initState() {
    super.initState();
    // getLists();
    // getTrendingList();
    // getRecentlyUpdated();
    // getRecommended();

    _pageController.addListener(onScroll);
  }

  // List<AnimeCard> thisSeason = [];
  // List<TrendingResult> trendingList = [];
  // List<AnimeCard> recentlyUpdatedList = [];
  // List<AnimeCard> recommendedList = [];
  int currentPage = 0;
  final PageController _pageController = PageController();
  Timer? timer;
  // bool trendingLoaded = false, recentlyUpdatedLoaded = false, recommendedLoaded = false;
  double page = 0;

  void onScroll() {
    setState(() {
      page = _pageController.page ?? 0;
    });
  }

  Future<void> pageTimeout() async {
    if (timer != null && timer!.isActive) timer!.cancel();
    timer = Timer(Duration(seconds: 5), () {
      if (currentPage < widget.trendingList.length - 1) {
        currentPage++;
      } else
        currentPage = 0;
      if (mounted)
        setState(() {
          _pageController.animateToPage(currentPage, duration: Duration(milliseconds: 400), curve: Curves.easeOut);
        });
    });
  }

  bool initialTimeOutCalled = false;

  bool isHoveredOverScrollList = false;

  @override
  Widget build(BuildContext context) {
    if (!initialTimeOutCalled && widget.trendingList.length > 0) {
      pageTimeout();
      initialTimeOutCalled = true;
    }
    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      body: SingleChildScrollView(
        physics: isHoveredOverScrollList ? NeverScrollableScrollPhysics() : null,
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  // margin: EdgeInsets.only(top: 30),
                  height: 370,
                  // width: double.infinity,
                  child: widget.trendingList.length > 0
                      ? _trendingAnimesPageView()
                      : Container(
                          child: Center(
                            child: CircularProgressIndicator(
                              color: appTheme.accentColor,
                            ),
                          ),
                        ),
                ),
                Padding(
                  padding: pagePadding(context).copyWith(left: 0),
                  child: buildHeader("Discover", context, afterNavigation: () => setState(() {})),
                )
              ],
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
                      height: 75,
                      width: 150,
                      decoration: BoxDecoration(
                        // color: appTheme.backgroundSubColor,
                        borderRadius: BorderRadius.circular(20),
                        image: DecorationImage(
                            image: AssetImage(
                              'lib/assets/images/chisato.jpeg',
                            ),
                            fit: BoxFit.cover,
                            opacity: 0.4),
                        border: Border.all(color: appTheme.accentColor),
                      ),
                      child: Center(
                        child: Text(
                          "News",
                          style: TextStyle(
                            color: appTheme.textMainColor,
                            fontFamily: "NotoSans",
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
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
                      height: 75,
                      width: 150,
                      decoration: BoxDecoration(
                        // color: appTheme.backgroundSubColor,
                        borderRadius: BorderRadius.circular(20),
                        image: DecorationImage(
                            image: AssetImage(
                              'lib/assets/images/mitsuha.jpg',
                            ),
                            fit: BoxFit.cover,
                            opacity: 0.4),
                        border: Border.all(color: appTheme.accentColor),
                      ),
                      child: Center(
                        child: Text(
                          "Genres",
                          style: TextStyle(
                            color: appTheme.textMainColor,
                            fontFamily: "NotoSans",
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            _itemTitle("Recently updated"),
            _scrollList(widget.recentlyUpdatedList),
            _itemTitle("This season"),
            _scrollList(widget.thisSeason),
            _itemTitle("Recommended"),
            _scrollList(widget.recommendedList),
            footSpace(),
          ],
        ),
      ),
    );
  }

  SizedBox footSpace() {
    return SizedBox(
      height: MediaQuery.of(context).padding.bottom + 60,
    );
  }

  PageView _trendingAnimesPageView() {
    return PageView.builder(
        pageSnapping: true,
        controller: _pageController,
        allowImplicitScrolling: true,
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
                    id: widget.trendingList[index % widget.trendingList.length].id,
                  ),
                ),
              );
            },
            child: Container(
              child: Stack(
                alignment: Alignment.center,
                fit: StackFit.expand,
                children: [
                  Container(
                    width: double.infinity,
                    child: ClipRRect(
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Image.network(
                          widget.trendingList[index % widget.trendingList.length].banner ??
                              widget.trendingList[index % widget.trendingList.length].cover,
                          alignment: Alignment((index - page).clamp(-1, 1).toDouble(), 1),
                          opacity: AlwaysStoppedAnimation(0.5),
                          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                            if (wasSynchronouslyLoaded) return child;
                            return AnimatedOpacity(
                              opacity: frame == null ? 0 : 1,
                              duration: Duration(milliseconds: 150),
                              child: child,
                            );
                          },
                          height: 360,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    // ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 20.0, top: MediaQuery.of(context).padding.top + 50),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            widget.trendingList[index % widget.trendingList.length].cover,
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
                                  widget.trendingList[index % widget.trendingList.length].title['english'] ??
                                      widget.trendingList[index % widget.trendingList.length].title['romaji'] ??
                                      '',
                                  style: TextStyle(
                                    color: appTheme.textMainColor,
                                    fontFamily: 'NunitoSans',
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  maxLines: 2,
                                ),
                              ),
                              Text(
                                widget.trendingList[index % widget.trendingList.length].genres.join(', '),
                                style: TextStyle(
                                    color: appTheme.textMainColor.withAlpha(145),
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
                                      color: appTheme.textMainColor,
                                      size: 20,
                                    ),
                                    Text(
                                      "${widget.trendingList[index % widget.trendingList.length].rating != null ? widget.trendingList[index % widget.trendingList.length].rating! / 10 : '??'}",
                                      style:
                                          TextStyle(color: appTheme.textMainColor, fontFamily: "Rubik", fontSize: 17),
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

  Container _scrollList(List<AnimeCard> list) {
    return Container(
      height: (list.firstOrNull?.isMobile ?? true) ? 220 : 265,
      padding: EdgeInsets.only(left: 10, right: 10),
      child: list.length > 0
          ? ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: list.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) => list[index],
            )
          : Center(
              child: CircularProgressIndicator(
                color: appTheme.accentColor,
              ),
            ),
    );
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
      color: appTheme.textMainColor,
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
