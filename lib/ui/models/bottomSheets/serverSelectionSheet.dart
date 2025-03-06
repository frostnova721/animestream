import 'dart:io';

import 'package:animestream/core/anime/downloader/downloader.dart';
import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/extractQuality.dart';
import 'package:animestream/core/commons/types.dart';
import 'package:animestream/core/data/watching.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/ui/models/providers/infoProvider.dart';
import 'package:animestream/ui/models/providers/playerDataProvider.dart';
import 'package:animestream/ui/models/providers/playerProvider.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:animestream/ui/models/watchPageUtil.dart';
import 'package:animestream/ui/models/widgets/appWrapper.dart';
import 'package:animestream/ui/models/widgets/sourceTile.dart';
import 'package:animestream/ui/pages/settingPages/common.dart';
import 'package:animestream/ui/pages/watch.dart';
import 'package:flutter/material.dart';
import 'package:animestream/ui/models/sources.dart' as srcs;
import 'package:provider/provider.dart';

class ServerSelectionBottomSheet extends StatefulWidget {
  final InfoProvider provider;
  final ServerSheetType type;
  final int episodeIndex;

  const ServerSelectionBottomSheet({
    super.key,
    required this.provider,
    required this.episodeIndex,
    required this.type,
  });

  @override
  State<ServerSelectionBottomSheet> createState() => ServerSelectionBottomSheetState();
}

class ServerSelectionBottomSheetState extends State<ServerSelectionBottomSheet> {
  List<VideoStream> streamSources = [];
  List<Map<String, String>> qualities = [];

  getStreams(InfoProvider provider, {bool directElseBlock = false}) async {
    streamSources = [];
    if (widget.type == ServerSheetType.download && !directElseBlock) {
      try {
        await srcs.getDownloadSources(
          widget.provider.selectedSource,
          widget.provider.epLinks[widget.episodeIndex],
          (list, finished) {
            if (mounted)
              setState(() {
                if (finished) {
                  _isLoading = widget.type == ServerSheetType.download ? true : false;
                }
                streamSources = streamSources + list;
                if (widget.type == ServerSheetType.download) {
                  list.forEach((element) async {
                    qualities.add({
                      'link': element.link,
                      'server': "${element.server}  ${element.backup ? "- backup" : ""}",
                      'quality': "${element.quality}"
                    });
                  });
                  if (mounted)
                    setState(() {
                      _isLoading = false;
                    });
                }
              });
          },
        );
      } catch (err) {
        if (err is UnimplementedError) {
          getStreams(provider, directElseBlock: true);
        }
      }
    } else {
      await srcs.getStreams(widget.provider.selectedSource, widget.provider.epLinks[widget.episodeIndex],
          (list, finished) {
        if (mounted)
          setState(() {
            if (finished) {
              _isLoading = widget.type == ServerSheetType.download ? true : false;
            }
            streamSources = streamSources + list;
            if (widget.type == ServerSheetType.download) {
              list.forEach((element) async {
                if (element.quality == "multi-quality") {
                  await getQualities(element.link, element.server, element.backup);
                } else {
                  qualities.add({
                    'link': element.link,
                    'server': "${element.server}  ${element.backup ? "- backup" : ""}",
                    'quality': "${element.quality}"
                  });
                }
              });
              if (mounted)
                setState(() {
                  _isLoading = false;
                });
            }
          });
      });
    }
  }

  Future<void> getQualities(String link, String server, bool backup) async {
    List<Map<String, String>> mainList = [];

    final List<dynamic> list = await getQualityStreams(link);
    list.forEach((element) {
      element['server'] = "${server} ${backup ? "- backup" : ""}";
      element['quality'] = element['quality'] == "default" ? "default" : "${element['quality']}p";
      mainList.add(element);
    });
    // if (mounted)
    setState(() {
      //     _isLoading = false;
      qualities = qualities + mainList;
    });
  }

  @override
  void initState() {
    super.initState();
    getStreams(widget.provider);
  }

  bool _isLoading = true;

  int? hoveredIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 20, right: 20, top: 10, bottom: MediaQuery.of(context).padding.bottom),
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(bottom: 10, left: 10),
            child: Text(
              "Select Server",
              style: textStyle().copyWith(fontSize: 23),
            ),
          ),
          streamSources.isNotEmpty
              ? _isLoading
                  ? SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _list(),
                          Container(
                            padding: EdgeInsets.only(bottom: 10),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: appTheme.accentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Container(
                      height: MediaQuery.of(context).orientation == Orientation.landscape
                          ? MediaQuery.of(context).size.height / 2
                          : MediaQuery.of(context).size.height / 3,
                      child: _list())
              : Container(
                  height: 100,
                  padding: EdgeInsets.only(bottom: 10, top: 20),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: appTheme.accentColor,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  ListView _list() {
    final title = widget.provider.data.title['english'] ?? widget.provider.data.title['romaji'] ?? "";
    return widget.type == ServerSheetType.watch
        ?   ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: Platform.isAndroid ? 10 : 15),
      shrinkWrap: true,
      itemCount: streamSources.length,
      itemBuilder: (context, index) {
        final source = streamSources[index];

        return SourceTile(source: source, onTap: () async {
          await storeWatching(
                title,
                widget.provider.data.cover,
                widget.provider.id,
                widget.episodeIndex,
                totalEpisodes: widget.provider.data.episodes,
                alternateDatabases: widget.provider.altDatabases,
              );

              final controller = Platform.isWindows ? VideoPlayerWindowsWrapper() : BetterPlayerWrapper();
              final provider = widget.provider;
              final navigatorState = (Platform.isWindows ? AppWrapper.navKey.currentState : Navigator.of(context));

              Navigator.pop(context, true);

              navigatorState?.push(
                MaterialPageRoute(
                  builder: (context) => MultiProvider(
                    providers: [
                      ChangeNotifierProvider(
                        create: (context) => PlayerDataProvider(
                          initialStreams: streamSources,
                          initialStream: streamSources[index],
                          epLinks: provider.epLinks,
                          showTitle: title,
                          showId: provider.id,
                          selectedSource: provider.selectedSource,
                          startIndex: widget.episodeIndex,
                          altDatabases: provider.altDatabases,
                          lastWatchDuration: provider.lastWatchedDurationMap?[
                              provider.watched < provider.epLinks.length
                                  ? provider.watched + 1
                                  : provider.watched],
                        ),
                      ),
                      ChangeNotifierProvider(
                        create: (context) => PlayerProvider(controller),
                      ),
                    ],
                    child: Watch(
                      controller: controller,
                    ),
                  ),
                ),
              ).then((value) {
                provider.getWatched();
              });
        },);
      },
    )
        : ListView.builder(
            itemCount: qualities.length,
            shrinkWrap: true,
            // physics: NeverScrollableScrollPhysics(),
            itemBuilder: (BuildContext context, ind) => Container(
              margin: EdgeInsets.only(top: 10),
              child: ElevatedButton(
                onPressed: () {
                  if (currentUserSettings?.useQueuedDownloads ?? false) {
                    Downloader()
                        .addToQueue(qualities[ind]['link']!, "${title}_Ep_${widget.episodeIndex + 1}",
                            parallelBatches: (currentUserSettings?.fasterDownloads ?? false) ? 10 : 5)
                        .onError((err, st) {
                      print(err);
                      print(st);
                      floatingSnackBar(context, "$err");
                    });
                  } else {
                    Downloader()
                        .download(qualities[ind]['link']!, "${title}_Ep_${widget.episodeIndex + 1}",
                            parallelBatches: (currentUserSettings?.fasterDownloads ?? false) ? 10 : 5)
                        .onError((err, st) {
                      print(err);
                      print(st);
                      floatingSnackBar(context, "$err");
                    });
                  }
                  Navigator.of(context).pop();
                  floatingSnackBar(context, "Downloading the episode to your downloads folder");
                },
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: appTheme.backgroundSubColor,
                  padding: EdgeInsets.only(top: 10, bottom: 10, left: 20, right: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 5),
                          child: Row(
                            children: [
                              Text(
                                "${qualities[ind]['server']}",
                                style: TextStyle(
                                  color: appTheme.accentColor,
                                  fontSize: 18,
                                  fontFamily: "Rubik",
                                ),
                              ),
                              Text(
                                "• ${qualities[ind]['quality']}",
                                style: TextStyle(
                                  color: appTheme.textMainColor,
                                  fontSize: 18,
                                  fontFamily: "Rubik",
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
