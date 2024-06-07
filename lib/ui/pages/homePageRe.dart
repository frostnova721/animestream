import 'package:animestream/ui/models/cards.dart';
import 'package:animestream/ui/pages/settingPages/common.dart';
import 'package:flutter/material.dart';

class TESTHOME extends StatefulWidget {
  const TESTHOME({super.key});

  @override
  State<TESTHOME> createState() => TESTHOMEState();
}

class TESTHOMEState extends State<TESTHOME> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: pagePadding(context),
        child: Center(
          child: Cards(context: context).animeCardExtended(154587, "meow meow nigga",
              "https://s4.anilist.co/file/anilistcdn/media/anime/cover/medium/bx154587-gHSraOSa0nBG.jpg", 6.9, bannerImageUrl: "https://s4.anilist.co/file/anilistcdn/media/anime/cover/medium/bx104464-VOIqGSQs1aiR.png"),
        ),
      ),
    );
  }
}
