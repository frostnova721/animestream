import 'dart:ui';

import 'package:animestream/core/database/anilist/types.dart';
import 'package:animestream/ui/pages/info.dart';
import 'package:animestream/ui/pages/news.dart';
import 'package:animestream/ui/theme/mainTheme.dart';
import 'package:flutter/material.dart';
import 'package:animestream/core/database/anilist/anilist.dart';

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
  }

  List thisSeason = [];
  List<TrendingResult> trendingList = [];

  Future getLists() async {
    thisSeason = widget.currentSeason;

    if (mounted) setState(() {});
  }

  Future<void> getTrendingList() async {
    final list = await Anilist().getTrending();
    setState(() {
      trendingList = list.sublist(0, 10);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.only(top: 30),
          height: 220,
          width: double.infinity,
          child: PageView.builder(
              pageSnapping: true,
              itemCount: trendingList.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                return Container(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: double.infinity,
                        child: ClipRRect(
                          child: ImageFiltered(
                            imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                            child: Image.network(
                              trendingList[index].banner ??
                                  trendingList[index].cover,
                              opacity: AlwaysStoppedAnimation(0.5),
                              height: 220,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 20.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.network(
                                trendingList[index].cover,
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
                                  Text(
                                    trendingList[index].title['english'] ??
                                        trendingList[index].title['romaji'] ??
                                        '',
                                    style: TextStyle(
                                        color: textMainColor,
                                        fontFamily: 'NunitoSans',
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        overflow: TextOverflow.ellipsis,),
                                        maxLines: 2,
                                  ),
                                  Text(
                                    trendingList[index].genres.join(', '),
                                    style: TextStyle(
                                        color:
                                            Color.fromARGB(255, 180, 180, 180),
                                        fontFamily: 'NunitoSans',
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
        ),
        Container(
          margin: EdgeInsets.only(top: 30),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (context) => News()));
            },
            child: Container(
              height: 50,
              width: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.transparent,
                border: Border.all(color: themeColor),
              ),
              child: Center(
                child: Text(
                  "News",
                  style: TextStyle(
                    color: themeColor,
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
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.only(top: 50, left: 25, right: 25, bottom: 20),
          child: Text(
            "This season",
            style: basicTextStyle("Rubik", 20),
          ),
        ),
        Container(
          height: 255,
          padding: EdgeInsets.only(left: 10, right: 10),
          child: ListView.builder(
            itemCount: thisSeason.length,
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) => GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Info(
                      id: thisSeason[index].info['id'],
                    ),
                  ),
                );
              },
              child: Container(
                width: 125,
                child: thisSeason[index].widget,
              ),
            ),
          ),
        )
      ],
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
  }
}
