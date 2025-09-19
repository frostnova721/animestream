import 'dart:convert';
import 'dart:io';

import 'package:animestream/core/anime/downloader/downloadManager.dart';
import 'package:animestream/core/anime/providers/types.dart';
import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/extractQuality.dart';
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
import 'package:animestream/ui/models/sources.dart';
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

  final src = SourceManager();

  Future<void> getStreams(InfoProvider provider, {bool directElseBlock = false}) async {
    streamSources = [];
    if (widget.type == ServerSheetType.download && !directElseBlock) {
      try {
        await src.getDownloadSources(
          widget.provider.selectedSource.identifier,
          widget.provider.epLinks[widget.episodeIndex].episodeLink,
          dub: provider.preferDubs,
          metadata: provider.epLinks[widget.episodeIndex].metadata,
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
      await src.getStreams(
          widget.provider.selectedSource.identifier, widget.provider.epLinks[widget.episodeIndex].episodeLink,
          dub: provider.preferDubs, metadata: provider.epLinks[widget.episodeIndex].metadata, (list, finished) {
        if (mounted)
          setState(() {
            if (finished) {
              _isLoading = (widget.type == ServerSheetType.download) ? true : false;
            }
            streamSources = streamSources + list;
            if (widget.type == ServerSheetType.download) {
              list.forEach((element) async {
                // auto or multi quality would mean multiple qualities
                if (element.quality == "multi-quality" || element.quality == "auto") {
                  await getQualities(element);
                } else {
                  qualities.add({
                    'link': element.link,
                    'server': "${element.server}  ${element.backup ? "- backup" : ""}",
                    'quality': "${element.quality}",
                    'headers': jsonEncode(element.customHeaders ?? {}),
                    'subtitle': element.subtitle ?? "",
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

  Future<void> getQualities(VideoStream source) async {
    List<Map<String, String>> mainList = [];

    final list = await parseMasterPlaylist(source.link, customHeader: source.customHeaders);
    list.qualityStreams.forEach((element) {
      final map = element.toMap();
      map['bandwidth'] = map['bandwidth']?.toString();
      map['server'] = "${source.server} ${source.backup ? "- backup" : ""}";
      map['subtitle'] = source.subtitle ?? "";
      map['headers'] = jsonEncode(source.customHeaders ?? {});
      mainList.add(map.cast());
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
          _isLoading
              ? SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (streamSources.isNotEmpty) _list(),
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
              : streamSources.isNotEmpty
                  ? Container(
                      height: MediaQuery.of(context).orientation == Orientation.landscape
                          ? MediaQuery.of(context).size.height / 2
                          : MediaQuery.of(context).size.height / 3,
                      child: _list(),
                    )
                  : Container(
                      height: 100,
                      padding: EdgeInsets.only(bottom: 10, top: 20),
                      child: Center(
                        child: Text(
                          "Woah! empty list of servers!",
                          style: TextStyle(fontFamily: "Rubik", fontSize: 18),
                        ),
                      ),
                    )
        ],
      ),
    );
  }

  ListView _list() {
    final title = widget.provider.data.title['english'] ?? widget.provider.data.title['romaji'] ?? "";

    return widget.type == ServerSheetType.watch
        ? ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: Platform.isAndroid ? 10 : 15),
            shrinkWrap: true,
            itemCount: streamSources.length,
            itemBuilder: (context, index) {
              final source = streamSources[index];

              return SourceTile(
                source: source,
                onTap: () async {
                  // return print(streamSources[index]);

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

                  navigatorState
                      ?.push(
                    MaterialPageRoute(
                      builder: (context) => MultiProvider(
                        providers: [
                          ChangeNotifierProvider(
                            create: (context) => PlayerDataProvider(
                              initialStreams: streamSources,
                              initialStream: streamSources[index],
                              epLinks: provider.epLinks,
                              showTitle: title,
                              coverImageUrl: widget.provider.data.cover,
                              showId: provider.id,
                              selectedSource: provider.selectedSource.identifier,
                              startIndex: widget.episodeIndex,
                              altDatabases: provider.altDatabases,
                              preferDubs: provider.preferDubs,
                              lastWatchDuration: provider.lastWatchedDurationMap?[
                                  provider.watched < provider.epLinks.length ? provider.watched + 1 : provider.watched],
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
                  )
                      .then((value) {
                    provider.getWatched(refreshLastWatchDuration: true);
                  });
                },
              );
            },
          )
        : ListView.builder(
            itemCount: qualities.length,
            shrinkWrap: true,
            itemBuilder: (BuildContext context, ind) => Container(
              margin: EdgeInsets.only(top: 10),
              child: ElevatedButton(
                onPressed: () {
                  String? subs = qualities[ind]['subtitle'];
                  subs = (subs?.isEmpty ?? true) ? null : subs;
                  // print(qualities[ind]);
                  final mapped = jsonDecode(qualities[ind]['headers'] ?? "{}");
                  Map<String, String> headers = Map.from(mapped).cast();

                  final episodeNum = "${widget.episodeIndex + 1}";

                  final fileName = "${title} EP ${episodeNum.padLeft(2, '0')}";
                  final streamLink = qualities[ind]['url']!;
                  // print(streamLink);

                  DownloadManager().addDownloadTask(
                    streamLink,
                    fileName,
                    customHeaders: headers,
                    subtitleUrl: subs,
                  ).onError((err, st) {
                    print(err);
                    print(st);
                    floatingSnackBar("$err");
                  });
                  Navigator.of(context).pop();
                  floatingSnackBar("Downloading the episode to your downloads folder");
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
