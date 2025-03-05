import 'dart:ui';

import 'package:animestream/core/commons/types.dart';
import 'package:animestream/ui/models/providers/infoProvider.dart';
import 'package:animestream/ui/models/widgets/bottomBar.dart';
import 'package:animestream/ui/models/widgets/infoPageWidgets/infoSection.dart';
import 'package:animestream/ui/models/widgets/infoPageWidgets/watchSection.dart';
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
  final splitWidth = 1500; // The width to generate the boxes on side

  final pageScrollController = ScrollController();

  final viewController = AnimeStreamBottomBarController(length: 3, nonViewIndices: [0], animDuration: 00);

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
          );
        },
      ),
    );
  }
}

class SourceSelectionDialog extends StatefulWidget {
  final List<VideoStream> sources;

  SourceSelectionDialog({required this.sources});

  @override
  _SourceSelectionDialogState createState() => _SourceSelectionDialogState();
}

class _SourceSelectionDialogState extends State<SourceSelectionDialog> {
  bool isExpanded = false; // Track window state

  @override
  Widget build(BuildContext context) {
     double width = MediaQuery.of(context).size.width * (isExpanded ? 0.6 : 0.3);
    double height = isExpanded ? 500 : 200; // Adjust size
    return  Dialog(
      backgroundColor: Colors.black87,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        width: width,
        height: height,
        padding: EdgeInsets.all(15),
        child: Column(
          children: [
            // Title Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Available Sources",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(isExpanded ? Icons.fullscreen_exit : Icons.fullscreen, color: Colors.white),
                      onPressed: () => setState(() => isExpanded = !isExpanded),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 10),

            // List of Sources
            Expanded(
              child: ListView.builder(
                itemCount: widget.sources.length,
                itemBuilder: (context, index) {
                  final source = widget.sources[index];

                  return ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    tileColor: Colors.grey[900],
                    leading: Icon(Icons.video_collection, color: Colors.white),
                    title: Text(source.server, style: TextStyle(color: Colors.white)),
                    subtitle: Text("${source.quality} - ${source.subtitleFormat}", style: TextStyle(color: Colors.grey)),
                    trailing: isExpanded
                        ? ElevatedButton(
                            onPressed: () {
                              // Play or load source
                            },
                            child: Text("Play"),
                          )
                        : null,
                    onTap: () {
                      if (!isExpanded) setState(() => isExpanded = true);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );;
  }
}