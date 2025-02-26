import 'dart:io';

import 'package:animestream/core/anime/downloader/downloader.dart';
import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/extractQuality.dart';
import 'package:animestream/core/commons/types.dart';
import 'package:animestream/core/data/watching.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/database/types.dart';
import 'package:animestream/ui/models/providers/playerDataProvider.dart';
import 'package:animestream/ui/models/providers/playerProvider.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:animestream/ui/models/watchPageUtil.dart';
import 'package:animestream/ui/pages/settingPages/common.dart';
import 'package:animestream/ui/pages/watch.dart';
import 'package:flutter/material.dart';
import 'package:animestream/ui/models/sources.dart' as srcs;
import 'package:provider/provider.dart';

class ServerSelectionBottomSheet extends StatefulWidget {
  final ServerSelectionBottomSheetContentData bottomSheetContentData;
  final Type type;
  final Function? getWatched;
  final List<AlternateDatabaseId> altDatabases;

  const ServerSelectionBottomSheet({
    super.key,
    required this.bottomSheetContentData,
    required this.type,
    required this.altDatabases,
    this.getWatched,
  });

  @override
  State<ServerSelectionBottomSheet> createState() => ServerSelectionBottomSheetState();
}

class ServerSelectionBottomSheetState extends State<ServerSelectionBottomSheet> {
  List<VideoStream> streamSources = [];
  List<Map<String, String>> qualities = [];

  getStreams({bool directElseBlock = false}) async {
    streamSources = [];
    if (widget.type == Type.download && !directElseBlock) {
      try {
        await srcs.getDownloadSources(
          widget.bottomSheetContentData.selectedSource,
          widget.bottomSheetContentData.epLinks[widget.bottomSheetContentData.episodeIndex],
          (list, finished) {
            if (mounted)
              setState(() {
                if (finished) {
                  _isLoading = widget.type == Type.download ? true : false;
                }
                streamSources = streamSources + list;
                if (widget.type == Type.download) {
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
          getStreams(directElseBlock: true);
        }
      }
    } else {
      await srcs.getStreams(widget.bottomSheetContentData.selectedSource,
          widget.bottomSheetContentData.epLinks[widget.bottomSheetContentData.episodeIndex], (list, finished) {
        if (mounted)
          setState(() {
            if (finished) {
              _isLoading = widget.type == Type.download ? true : false;
            }
            streamSources = streamSources + list;
            if (widget.type == Type.download) {
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
      element['quality'] = "${element['quality']}p";
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
    getStreams();
  }

  bool _isLoading = true;

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
    return widget.type == Type.watch
        ? ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            // physics: NeverScrollableScrollPhysics(),
            itemCount: streamSources.length,
            itemBuilder: (context, index) {
              return Container(
                margin: EdgeInsets.only(top: 15),
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 37, 34, 49),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ElevatedButton(
                  onPressed: () async {
                    await storeWatching(
                      widget.bottomSheetContentData.title,
                      widget.bottomSheetContentData.cover,
                      widget.bottomSheetContentData.id,
                      widget.bottomSheetContentData.episodeIndex,
                      totalEpisodes: widget.bottomSheetContentData.totalEpisodes,
                      alternateDatabases: widget.altDatabases,
                    );
                    final controller = Platform.isWindows ? VideoPlayerWindowsWrapper() : BetterPlayerWrapper();

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MultiProvider(
                          providers: [
                            ChangeNotifierProvider(
                              create: (context) => PlayerDataProvider(
                                  initialStreams: streamSources, initialStream: streamSources[index],
                                  epLinks: widget.bottomSheetContentData.epLinks,
                                  showTitle: widget.bottomSheetContentData.title,
                                  showId: widget.bottomSheetContentData.id,
                                  selectedSource: widget.bottomSheetContentData.selectedSource,
                                  startIndex: widget.bottomSheetContentData.episodeIndex,
                                  altDatabases: widget.altDatabases,
                                  lastWatchDuration: widget.bottomSheetContentData.lastWatchDuration,
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
                      widget.getWatched!();
                      Navigator.of(context).pop(true);
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: appTheme.backgroundSubColor,
                    padding: EdgeInsets.only(top: 10, bottom: 10, left: 20, right: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            streamSources[index].server,
                            style: TextStyle(
                              fontFamily: "NotoSans",
                              fontSize: 17,
                              color: appTheme.accentColor,
                            ),
                          ),
                          if (streamSources[index].backup)
                            Text(
                              " • backup",
                              style: TextStyle(
                                fontFamily: "NotoSans",
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            )
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 5),
                        child: Text(
                          streamSources[index].quality,
                          style: TextStyle(color: appTheme.textMainColor, fontFamily: "Rubik"),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          )
        : ListView.builder(
            itemCount: qualities.length,
            shrinkWrap: true,
            // physics: NeverScrollableScrollPhysics(),
            itemBuilder: (BuildContext context, ind) => Container(
              margin: EdgeInsets.only(top: 15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ElevatedButton(
                onPressed: () {
                  if (currentUserSettings?.useQueuedDownloads ?? false) {
                    Downloader()
                        .addToQueue(qualities[ind]['link']!,
                            "${widget.bottomSheetContentData.title}_Ep_${widget.bottomSheetContentData.episodeIndex + 1}",
                            parallelBatches: (currentUserSettings?.fasterDownloads ?? false) ? 10 : 5)
                        .onError((err, st) {
                      print(err);
                      print(st);
                      floatingSnackBar(context, "$err");
                    });
                  } else {
                    Downloader()
                        .download(qualities[ind]['link']!,
                            "${widget.bottomSheetContentData.title}_Ep_${widget.bottomSheetContentData.episodeIndex + 1}",
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
                    borderRadius: BorderRadius.circular(20),
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

//long name lol
