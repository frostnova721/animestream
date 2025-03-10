import 'dart:ui';

import 'package:animestream/ui/models/providers/infoProvider.dart';
import 'package:animestream/ui/models/widgets/bottomBar.dart';
import 'package:animestream/ui/models/widgets/infoPageWidgets/infoSection.dart';
import 'package:animestream/ui/models/widgets/infoPageWidgets/watchSection.dart';
import 'package:animestream/ui/models/widgets/navRail.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class InfoDesktop extends StatefulWidget {
  const InfoDesktop({super.key});

  @override
  State<InfoDesktop> createState() => _InfoDesktopState();
}

class _InfoDesktopState extends State<InfoDesktop> {
  final splitWidth = 1500; // The width to generate the boxes on side

  final pageScrollController = ScrollController();

  final viewController = AnimeStreamBottomBarController(length: 3, nonViewIndices: [0], animDuration: 00);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InfoProvider>();
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      body: Row(
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
          !provider.dataLoaded
              ? Expanded(
                  child: Center(
                      child: Container(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      LinearProgressIndicator(),
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text("Loading..."),
                      )
                    ],
                  ),
                  width: 300,
                )))
              : Expanded(
                  child: SingleChildScrollView(
                    controller: pageScrollController,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 270,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          clipBehavior: Clip.antiAlias,
                          margin: EdgeInsets.all(15).copyWith(top: 15 + MediaQuery.paddingOf(context).top),
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
                        BottomBarView(
                          controller: viewController,
                          children: [
                            InfoSection(
                              size: size,
                              provider: provider,
                              splitWidth: splitWidth,
                            ),
                            WatchSection(
                              provider: provider,
                              size: size,
                              splitWidth: splitWidth,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
