import 'dart:io';
import 'dart:ui';

import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/ui/models/providers/infoProvider.dart';
import 'package:animestream/ui/models/widgets/cards.dart';
import 'package:animestream/ui/models/widgets/infoPageWidgets/commonInfo.dart';
import 'package:animestream/ui/models/widgets/navRail.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class InfoDesktop extends StatefulWidget {
  final int id;
  const InfoDesktop({super.key, required this.id});

  @override
  State<InfoDesktop> createState() => _InfoDesktopState();
}

class _InfoDesktopState extends State<InfoDesktop> {
  final splitWidth = 1800; // The width to generate the boxes on side

  final recommendationScrollController = ScrollController();
  final charactersScrollController = ScrollController();

  final viewController = AnimeStreamNavRailController(length: 3, nonViewIndices: [0]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ChangeNotifierProvider(
        create: (context) => InfoProvider(widget.id)..init(),
        builder: (context, child) {
          final provider = context.watch<InfoProvider>();
          if (!provider.dataLoaded) return Container(); // TODO: Set a loading screen
          final size = MediaQuery.sizeOf(context);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimeStreamNavRail(
                controller: viewController,
                initialIndex: 1,
                destinations: [
                  AnimeStreamNavDestination(
                      icon: Icons.arrow_back,
                      label: "Back",
                      onClick: () {
                        Navigator.of(context).pop();
                      }),
                  AnimeStreamNavDestination(
                    icon: Icons.info_outline_rounded,
                    label: "Info",
                  ),
                  AnimeStreamNavDestination(
                    icon: Icons.play_arrow_rounded,
                    label: "Play",
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 270,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        clipBehavior: Clip.antiAlias,
                        margin: EdgeInsets.all(15),
                        child: ImageFiltered(
                          imageFilter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
                          child: Opacity(
                            opacity: 0.9,
                            child: CachedNetworkImage(
                              imageUrl: provider.data.banner ?? provider.data.cover,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(left: size.width / 10, top: 30),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start, // Align the row contents to the top
                                  children: [
                                    Column(
                                      children: [
                                        CommonInfo(
                                          provider: provider,
                                        ),
                                        Container(
                                          padding: EdgeInsets.all(20),
                                          margin: EdgeInsets.only(top: 50),
                                          width: size.width / 2,
                                          constraints: BoxConstraints(maxWidth: 650),
                                          child: Column(
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.star,
                                                        size: 35,
                                                      ),
                                                      Text(
                                                        " ${provider.data.rating}",
                                                        style: _textStyle(),
                                                      ),
                                                    ],
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets.only(left: 15, right: 15),
                                                    child: Text(
                                                      provider.data.type,
                                                      style: _textStyle(),
                                                    ),
                                                  ),
                                                  Text("${provider.data.episodes ?? "??"} Episodes",
                                                      style: _textStyle())
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.only(top: 50, bottom: 50),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    decoration: BoxDecoration(
                                                        color: appTheme.backgroundSubColor,
                                                        borderRadius: BorderRadius.circular(20)),
                                                    constraints: BoxConstraints(minWidth: 450, maxWidth: 650),
                                                    width: size.width / 2.5,
                                                    padding: EdgeInsets.all(25),
                                                    child: Row(
                                                      children: [
                                                        Expanded(
                                                          child: Column(
                                                            spacing: 2,
                                                            children: [
                                                              _infoBoxItem("Status:", provider.data.status ?? "??"),
                                                              _infoBoxItem("Duration:", provider.data.duration),
                                                              _infoBoxItem(
                                                                  "Studios:", provider.data.studios.join(", ")),
                                                              _infoBoxItem(
                                                                  "Air start",
                                                                  provider.data.aired['start']!.trim().isEmpty
                                                                      ? "??"
                                                                      : provider.data.aired['start']!),
                                                              _infoBoxItem(
                                                                  "Air end",
                                                                  provider.data.aired['end']!.trim().isEmpty
                                                                      ? "??"
                                                                      : provider.data.aired['end']!),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  if (size.width >= 1200 && size.width < 1800)
                                                    _tagsNgenresBuilder(provider, "Genres", provider.data.genres),
                                                ],
                                              ),
                                              if (size.width < 1200)
                                                Padding(
                                                  padding: EdgeInsets.only(top: 20),
                                                  child: _tagsNgenresBuilder(provider, "Genres", provider.data.genres,
                                                      unconstrainedWidth: true),
                                                ),
                                            ],
                                          ),
                                        ),
                                        if (size.width < splitWidth)
                                          _tagsNgenresBuilder(provider, "Tags", provider.data.tags!,
                                              unconstrainedWidth: true),
                                        SizedBox(
                                          width: size.width / (size.width > 1800 ? 1.75 : 1.3),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 20, bottom: 20),
                                                    child: Text(
                                                      "Characters",
                                                      style: _textStyle(),
                                                    ),
                                                  ),
                                                  _scrollButtons(charactersScrollController),
                                                ],
                                              ),
                                              Container(
                                                height: 250,
                                                width: size.width / (size.width > 1800 ? 1.75 : 1.3),
                                                child: ListView.builder(
                                                  itemCount: provider.data.characters.length,
                                                  scrollDirection: Axis.horizontal,
                                                  controller: charactersScrollController,
                                                  itemBuilder: (context, index) {
                                                    final it = provider.data.characters[index];
                                                    return Cards().characterCard(it['name'], it['role'], it['image']);
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                          width: size.width / (size.width > 1800 ? 1.75 : 1.3),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(top: 40, bottom: 20),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.max,
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      "Recommended",
                                                      style: _textStyle(),
                                                    ),
                                                    _scrollButtons(recommendationScrollController),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                height: 260,
                                                // width: size.width / (size.width > 1800 ? 1.75 : 1.3),
                                                child: ListView.builder(
                                                  controller: recommendationScrollController,
                                                  itemCount: provider.data.recommended.length,
                                                  scrollDirection: Axis.horizontal,
                                                  itemBuilder: (context, index) {
                                                    final it = provider.data.recommended[index];
                                                    return Cards(context: context).animeCard(
                                                      it.id,
                                                      it.title['english'] ?? it.title['romaji']!,
                                                      it.cover,
                                                      isMobile: !Platform.isWindows,
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ), // Yeah put stuff in this column
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (size.width >= splitWidth)
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.only(top: 30, right: size.width / 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    _tagsNgenresBuilder(provider, "Genres", provider.data.genres),
                                    if (provider.data.tags != null)
                                      _tagsNgenresBuilder(provider, "Tags", provider.data.tags!),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Row _scrollButtons(ScrollController controller) {
    final scrollOffset = 500;
    return Row(
      spacing: 15,
      children: [
        OutlinedButton(
            onPressed: () {
              controller.animateTo(controller.offset - scrollOffset,
                  duration: Duration(milliseconds: 200), curve: Curves.easeInOut);
            },
            child: Icon(Icons.arrow_back_ios_new_rounded)),
        OutlinedButton(
            onPressed: () {
              controller.animateTo(controller.offset + scrollOffset,
                  duration: Duration(milliseconds: 200), curve: Curves.easeInOut);
            },
            child: Icon(Icons.arrow_forward_ios_rounded)),
      ],
    );
  }

  Row _infoBoxItem(String key, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Text(
            key,
            style: _textStyle().copyWith(fontSize: 20),
          ),
        ),
        Text(
          value,
          style: _textStyle().copyWith(fontWeight: FontWeight.normal, fontSize: 20),
        ),
      ],
    );
  }

  TextStyle _textStyle() => TextStyle(fontSize: 25, fontWeight: FontWeight.bold);

  Container _tagsNgenresBuilder(InfoProvider provider, String title, List<dynamic> list,
      {bool unconstrainedWidth = false}) {
    return Container(
      margin: EdgeInsets.only(left: 50, bottom: 30),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: appTheme.backgroundSubColor,
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: "Rubik"),
          ),
          Container(
            width: unconstrainedWidth ? MediaQuery.sizeOf(context).width / 2 : 400,
            padding: EdgeInsets.only(top: 20),
            child: Wrap(
              spacing: 5, // Horizontal space between items
              runSpacing: 5, // Vertical space between lines
              children: list
                  .map((genre) => Container(
                        margin: EdgeInsets.zero,
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: appTheme.textSubColor,
                        ),
                        child: Text(
                          genre ?? "",
                          style: TextStyle(fontSize: 18),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
