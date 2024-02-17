import 'package:animestream/ui/models/cards.dart';
import 'package:animestream/ui/pages/news.dart';
import 'package:animestream/ui/theme/mainTheme.dart';
import 'package:flutter/material.dart';

import '../../core/database/anilist/anilist.dart';

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
  }

  List thisSeason = [];

  Future getLists() async {
    // final List currentlyAiringResponse =
    //     await Anilist().getCurrentlyAiringAnime();
    // if (currentlyAiringResponse.length == 0) return;

    thisSeason = widget.currentSeason;
    // currentlyAiringResponse.forEach((e) {
    //   final title = e['title']['english'] ?? e['title']['romaji'];
    //   final image = e['coverImage']['large'] ?? e['coverImage']['extraLarge'];
    //   thisSeason.add(ListElement(widget: animeCard(title, image), info: e));
    // });
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 100,
        ),
        Container(
          child: InkWell(
            onTap: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (context) => News()));
            },
            child: Container(
              height: 50,
              width: 150,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.black,
                  border: Border.all(color: themeColor)),
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
            style: basicTextStyle("Rubik", 22),
          ),
        ),
        Container(
          height: 255,
          padding: EdgeInsets.only(left: 10, right: 10),
          child: ListView.builder(
            itemCount: thisSeason.length,
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) => Container(
              width: 125,
              child: thisSeason[index].widget,
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
}
