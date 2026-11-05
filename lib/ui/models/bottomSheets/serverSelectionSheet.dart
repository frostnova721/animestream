import 'dart:io';

import 'package:animestream/core/anime/downloader/downloadManager.dart';
import 'package:animestream/core/anime/providers/types.dart';
import 'package:animestream/core/app/logging.dart';
import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/hlsParser/audioStream.dart';
import 'package:animestream/core/commons/hlsParser/hlsMasterPlaylist.dart';
import 'package:animestream/core/commons/hlsParser/hlsParser.dart';
import 'package:animestream/core/commons/hlsParser/qualityStream.dart';
import 'package:animestream/core/data/watching.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/ui/models/playerControllers/betterPlayer.dart';
import 'package:animestream/ui/models/playerControllers/fvp.dart';
import 'package:animestream/ui/models/providers/infoProvider.dart';
import 'package:animestream/ui/models/providers/playerDataProvider.dart';
import 'package:animestream/ui/models/providers/playerProvider.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:animestream/ui/models/widgets/appWrapper.dart';
import 'package:animestream/ui/models/widgets/sourceTile.dart';
import 'package:animestream/ui/pages/settingPages/common.dart';
import 'package:animestream/ui/pages/watch.dart';
import 'package:flutter/material.dart';
import 'package:animestream/ui/models/sources.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

class DownloadStreamOptions({
  required final QualityStream videoStream,
  required final List<AudioStream> audioStreams,
  required final String server,
  final String? subtitleUrl,
  final Map<String, String> headers = const {},
});

class ServerSelectionBottomSheet extends StatefulWidget {
  final InfoProvider provider;
  final ServerSheetType type;
  final int episodeIndex;

  const ServerSelectionBottomSheet({super.key, required this.provider, required this.episodeIndex, required this.type});

  @override
  State<ServerSelectionBottomSheet> createState() => ServerSelectionBottomSheetState();
}

class ServerSelectionBottomSheetState extends State<ServerSelectionBottomSheet> {
  List<VideoStream> streamSources = [];
  List<DownloadStreamOptions> qualities = [];

  final src = SourceManager.instance;

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
                    qualities.add(
                      DownloadStreamOptions(
                        videoStream: QualityStream(quality: element.quality, url: element.url, resolution: "??"),
                        audioStreams: const [],
                        server: "${element.server}  ${element.backup ? "- backup" : ""}",
                        subtitleUrl: element.subtitle,
                        headers: element.customHeaders ?? {},
                      ),
                    );
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
        widget.provider.selectedSource.identifier,
        widget.provider.epLinks[widget.episodeIndex].episodeLink,
        dub: provider.preferDubs,
        metadata: provider.epLinks[widget.episodeIndex].metadata,
        (list, finished) {
          if (mounted)
            setState(() {
              streamSources = streamSources + list;
              if (finished) {
                _isLoading = (widget.type == ServerSheetType.download) ? true : false;

                // we're checking for "_isLoading" since its on download mode if its still on loading.
                // by doing this, we can just skip a equality check.
                if (widget.provider.previouslyUsedServer != null &&
                    userPreferences?.autoSelectPreviouslyUsedServer == true &&
                    !_isLoading) {
                  final autoSelected = streamSources.firstWhereOrNull(
                    (element) =>
                        element.server == widget.provider.previouslyUsedServer &&
                        element.quality == widget.provider.previouslyUsedServerQuality,
                  );
                  if (autoSelected != null) {
                    _navigateToPlayer(title, streamSources.indexOf(autoSelected));
                  }
                }
              }
              if (widget.type == ServerSheetType.download) {
                list.forEach((element) async {
                  // auto or multi quality would mean multiple qualities
                  if (element.quality == "multi-quality" || element.quality == "auto") {
                    await getQualities(element);
                  } else {
                    qualities.add(
                      DownloadStreamOptions(
                        videoStream: QualityStream(quality: element.quality, url: element.url, resolution: "??"),
                        audioStreams: const [],
                        server: "${element.server}  ${element.backup ? "- backup" : ""}",
                        subtitleUrl: element.subtitle,
                        headers: element.customHeaders ?? {},
                      ),
                    );
                  }
                });
                if (mounted)
                  setState(() {
                    _isLoading = false;
                  });
              }
            });
        },
      );
    }
  }

  Future<void> getQualities(VideoStream source) async {
    List<DownloadStreamOptions> mainList = [];

    final HlsMasterPlaylist list = await HlsParser.parseMasterPlaylist(source.url, customHeader: source.customHeaders)
        .catchError((e) {
          Logs.app.log("${source.server}: $e");
          return HlsMasterPlaylist(audioStreams: [], qualityStreams: []);
        });

    list.qualityStreams.forEach((element) {
      final downloadStream = DownloadStreamOptions(
        videoStream: element,
        audioStreams: list.audioStreams,
        server: "${source.server} ${source.backup ? "- backup" : ""}",
        subtitleUrl: source.subtitle,
        headers: source.customHeaders ?? {},
      );
      mainList.add(downloadStream);
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

    final titles = widget.provider.data.title;
    final defaultTitle = titles['english'] ?? titles['romaji'] ?? "";
    title = (currentUserSettings?.nativeTitle ?? false) ? titles['native'] ?? defaultTitle : defaultTitle;

    getStreams(widget.provider);
  }

  late String title;

  bool _isLoading = true;

  int? hoveredIndex;

  Future<void> _navigateToPlayer(String title, int index) async {
    // return print(streamSources[index]);

    await storeWatching(
      title,
      widget.provider.data.cover,
      widget.provider.id,
      widget.episodeIndex,
      totalEpisodes: widget.provider.data.episodes,
      alternateDatabases: widget.provider.altDatabases,
      rating: widget.provider.data.rating,
    );

    final controller = Platform.isAndroid ? BetterPlayerWrapper() : FvpWrapper();
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
                    lastWatchDuration:
                        provider.lastWatchedDurationMap?[provider.watched < provider.epLinks.length
                            ? provider.watched + 1
                            : provider.watched],
                  ),
                ),
                ChangeNotifierProvider(create: (context) => PlayerProvider(controller, true)),
              ],
              child: Watch(controller: controller),
            ),
          ),
        )
        .then((value) {
          provider.getWatched(refreshLastWatchDuration: true);
        });
  }

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Select Server", style: textStyle().copyWith(fontSize: 23)),
                Text(
                  "Episode ${widget.episodeIndex + 1}",
                  style: TextStyle(color: appTheme.textSubColor, fontFamily: "Rubik"),
                ),
              ],
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
                        child: Center(child: CircularProgressIndicator(color: appTheme.accentColor)),
                      ),
                    ],
                  ),
                )
              : streamSources.isNotEmpty
              ? ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height / 2),
                  child: _list(),
                )
              : Container(
                  height: 100,
                  padding: EdgeInsets.only(bottom: 10, top: 20),
                  child: Center(
                    child: Text("Woah! empty list of servers!", style: TextStyle(fontFamily: "Rubik", fontSize: 18)),
                  ),
                ),
        ],
      ),
    );
  }

  ListView _list() {
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
                  await widget.provider.updatePrevUsedServer(source.server, source.quality);
                  return _navigateToPlayer(title, index);
                },
              );
            },
          )
        : ListView.builder(
            itemCount: qualities.length,
            shrinkWrap: true,
            itemBuilder: (BuildContext context, ind) =>
                _DownloadTile(stream: qualities[ind], parentSheet: widget, title: title),
          );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class _DownloadTile extends StatefulWidget {
  const _DownloadTile({required this.stream, required this.parentSheet, required this.title});

  final DownloadStreamOptions stream;
  final ServerSelectionBottomSheet parentSheet;
  final String title;

  @override
  State<_DownloadTile> createState() => _DownloadTileState();
}

class _DownloadTileState extends State<_DownloadTile> {
  bool _expanded = false;
  late int _selectedAudioIndex;

  bool get _hasMultipleAudio => widget.stream.audioStreams.length > 1;

  @override
  void initState() {
    super.initState();
    // Default to track loved by the user if available, otherwise first
    final streams = widget.stream.audioStreams;
    final preferedLangIdx = streams.indexWhere(
      (a) => widget.parentSheet.provider.preferDubs
          ? a.isEnglish
          : a.language.toLowerCase() == "jp" || a.language.toLowerCase() == "japanese",
    );
    _selectedAudioIndex = preferedLangIdx != -1 ? preferedLangIdx : 0;
  }

  void _startDownload({AudioStream? audioOverride}) {
    String? subs = widget.stream.subtitleUrl;
    subs = (subs?.isEmpty ?? true) ? null : subs;

    final episodeNum = "${widget.parentSheet.episodeIndex + 1}";
    final fileName = "${widget.title} EP ${episodeNum.padLeft(2, '0')}";

    final audioStreams = audioOverride != null ? [audioOverride] : widget.stream.audioStreams;

    DownloadManager()
        .addDownloadTask(
          widget.stream.videoStream.url,
          fileName,
          customHeaders: widget.stream.headers,
          subtitleUrl: subs,
          videoStream: widget.stream.videoStream,
          audioStreams: audioStreams,
        )
        .onError((err, st) {
          print(err);
          print(st);
          floatingSnackBar("$err");
        });
    Navigator.of(context).pop();
    floatingSnackBar("Downloading the episode to your downloads folder");
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 10),
      child: Material(
        color: appTheme.backgroundSubColor,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            if (!_hasMultipleAudio) {
              _startDownload();
            } else {
              setState(() => _expanded = !_expanded);
            }
          },
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 5),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${widget.stream.server}",
                              style: TextStyle(color: appTheme.accentColor, fontSize: 18, fontFamily: "Rubik"),
                            ),
                            Text(
                              "${widget.stream.videoStream.quality}",
                              style: TextStyle(color: appTheme.textMainColor, fontSize: 18, fontFamily: "Rubik"),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_hasMultipleAudio)
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: Duration(milliseconds: 200),
                        child: Icon(Icons.expand_more, color: appTheme.textSubColor),
                      ),
                  ],
                ),
                AnimatedSize(
                  duration: Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  child: _expanded ? _audioTrackSection() : SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _audioTrackSection() {
    final audioStreams = widget.stream.audioStreams;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: appTheme.textSubColor.withAlpha(50)),
        Padding(
          padding: EdgeInsets.only(top: 4, bottom: 8),
          child: Row(
            children: [
              Icon(Icons.audiotrack_rounded, size: 16, color: appTheme.textSubColor),
              SizedBox(width: 6),
              Text(
                "Audio Track",
                style: TextStyle(color: appTheme.textSubColor, fontSize: 14, fontFamily: "Rubik"),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(audioStreams.length, (index) {
            final audio = audioStreams[index];
            final selected = _selectedAudioIndex == index;
            final label = audio.name.isNotEmpty ? audio.name : audio.language;
            return ChoiceChip(
              selected: selected,
              showCheckmark: false,
              label: Text(
                label,
                style: TextStyle(
                  color: selected ? appTheme.onAccent : appTheme.textMainColor,
                  fontFamily: "Rubik",
                  fontSize: 13,
                ),
              ),
              selectedColor: appTheme.accentColor,
              backgroundColor: appTheme.backgroundColor,
              side: BorderSide(color: selected ? appTheme.accentColor : appTheme.textSubColor.withAlpha(80)),
              onSelected: (val) {
                if (val) setState(() => _selectedAudioIndex = index);
              },
            );
          }),
        ),
        SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              _startDownload(audioOverride: audioStreams[_selectedAudioIndex]);
            },
            icon: Icon(Icons.download_rounded),
            label: Text("Download"),
            style: FilledButton.styleFrom(
              backgroundColor: appTheme.accentColor,
              foregroundColor: appTheme.onAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }
}
