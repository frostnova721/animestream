import 'package:animestream/core/anime/providers/types.dart';
import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/ui/models/providers/playerDataProvider.dart';
import 'package:animestream/ui/models/providers/playerProvider.dart';
import 'package:animestream/ui/models/sources.dart';
import 'package:animestream/ui/pages/settingPages/common.dart';
import 'package:flutter/material.dart';

class CustomControlsBottomSheet extends StatefulWidget {
  /// The index of episode to switch
  final int index;
  final PlayerDataProvider dataProvider;
  final PlayerProvider playerProvider;

  const CustomControlsBottomSheet({
    super.key,
    required this.index,
    required this.dataProvider,
    required this.playerProvider,
  });

  @override
  State<CustomControlsBottomSheet> createState() => CustomControls_BottomSheetState();
}

class CustomControls_BottomSheetState extends State<CustomControlsBottomSheet> {
  List<VideoStream> currentSources = [];
  // int currentEpIndex = 0;

  late int index;

  bool _isLoading = true;

  late PlayerProvider pp;
  late PlayerDataProvider dp;

  @override
  void initState() {
    super.initState();

    index = widget.index;
    pp = widget.playerProvider;
    dp = widget.dataProvider;

    getSources();
  }

  Future getSources() async {
    if ((index < 0) || (index >= dp.epLinks.length)) {
      throw new Exception("Index too low or too high. Item not found!");
    }

    bool alreadyCalledaSource = false;

    if (index == dp.state.currentEpIndex) {
      currentSources = dp.state.streams;
      _isLoading = false;
    } else {
      await SourceManager().getStreams(dp.selectedSource, dp.epLinks[index].episodeLink, (list, finished) {
        if (list.length > 0) {
          if (mounted)
            setState(() {
              if (finished) _isLoading = false;
              currentSources += list;
            });
          print("got one!");
          dp.updateStreams(currentSources);
          if (list[0].server == dp.state.currentStream.server &&
              !alreadyCalledaSource &&
              index != dp.state.currentEpIndex) {
            dp.updateCurrentStream(
              list[0],
            );
            Navigator.pop(context);
            alreadyCalledaSource = true;
            play();
          }
        }
      });
    }
  }

  void play() {
    dp.extractCurrentStreamQualities().then((val) {
      final q = dp.getPreferredQualityStreamFromQualities();
      pp.playVideo(q['link']!,
          currentStream: dp.state.currentStream, preserveProgress: index == dp.state.currentEpIndex);
      dp.update(dp.state.copyWith(
        currentQuality: q,
        currentEpIndex: index,
        preloadStarted: false,
        preloadedSources: [],
        sliderValue: index == dp.state.currentEpIndex ? null : 0,
      ));
      // dp.updateDiscordPresence();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height - 100,
      padding: EdgeInsets.only(left: 30, right: 30, top: 20, bottom: 20),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              "Select Server",
              style: textStyle().copyWith(fontSize: 23),
            ),
          ),
          Expanded(
            child: currentSources.length > 0
                ? _isLoading
                    ? SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _list(),
                            Center(
                              child: Container(
                                height: 100,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: appTheme.accentColor,
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      )
                    : _list()
                : Container(
                    height: 100,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: appTheme.accentColor,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  ListView _list() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: currentSources.length,
      // physics: NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.only(top: 15),
          decoration: BoxDecoration(
            color: Color.fromARGB(97, 190, 175, 255),
            borderRadius: BorderRadius.circular(20),
          ),
          child: ElevatedButton(
            onPressed: () {
              dp.update(
                dp.state.copyWith(
                  currentStream: currentSources[index],
                  streams: currentSources,
                ),
              );
              Navigator.pop(context);
              play();
            },
            style: ElevatedButton.styleFrom(
              elevation: 0,
              surfaceTintColor: Colors.black,
              backgroundColor: appTheme.backgroundSubColor,
              padding: EdgeInsets.only(top: 5, bottom: 5, left: 20, right: 20),
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
                      currentSources[index].server,
                      style: TextStyle(
                        fontFamily: "NotoSans",
                        fontSize: 17,
                        color: appTheme.accentColor,
                      ),
                    ),
                    if (currentSources[index].backup)
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
                    currentSources[index].quality,
                    style: TextStyle(color: Colors.white, fontFamily: "Rubik"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
