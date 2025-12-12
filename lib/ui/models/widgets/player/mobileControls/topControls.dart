import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/ui/models/providers/playerDataProvider.dart';
import 'package:animestream/ui/models/providers/playerProvider.dart';
import 'package:animestream/ui/pages/settingPages/player.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TopControls extends StatelessWidget {
  const TopControls({
    super.key,
    required this.provider,
    required this.dataProvider,
    required this.context,
  });

  final PlayerProvider provider;
  final PlayerDataProvider dataProvider;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    final epTitle = provider.isOffline
        ? 'Episode ${dataProvider.state.currentEpIndex + 1}'
        : dataProvider.epLinks[dataProvider.state.currentEpIndex].episodeTitle;
    return Expanded(
      child: Container(
        alignment: Alignment.topCenter,
        child: Container(
          height: 50,
          child: Row(
            children: [
              if (!dataProvider.state.controlsLocked)
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 25,
                  ),
                ),
              Expanded(
                child: dataProvider.state.controlsLocked
                    ? Container()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.only(left: 20, top: 5),
                            alignment: Alignment.topLeft,
                            child: Text(
                                (epTitle == null || epTitle.isEmpty)
                                    ? "Episode ${dataProvider.state.currentEpIndex + 1}"
                                    : epTitle,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'NotoSans',
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                )),
                          ),
                          Container(
                            padding: const EdgeInsets.only(left: 20),
                            alignment: Alignment.topLeft,
                            child: Text(
                              "${dataProvider.showTitle}",
                              style: TextStyle(
                                color: Color.fromARGB(255, 190, 190, 190),
                                fontFamily: 'NotoSans',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                overflow: TextOverflow.ellipsis,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
              ),
              if (kDebugMode && !dataProvider.state.controlsLocked)
                IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) => AlertDialog(
                        backgroundColor: Colors.black,
                        contentTextStyle: TextStyle(color: Colors.white),
                        title: Text("VideoStream info", style: TextStyle(color: appTheme.accentColor)),
                        content: Text(
                          "Resolution: ${dataProvider.state.currentQuality.resolution}"
                          "\nServer: ${dataProvider.state.preferredServer}"
                          "\nSource: ${dataProvider.state.currentStream.server} ${dataProvider.state.currentStream.backup ? "\(backup\)" : ''}"
                          "\nQuality: ${dataProvider.state.currentQuality.quality}"
                          "\nBandwidth: ${dataProvider.state.currentQuality.bandwidth ?? 'N/A'}"
                          "\nSubtitle: ${dataProvider.state.currentStream.subtitle != null ? "${dataProvider.state.currentStream.subtitleFormat}" : "N/A"}",
                        ),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.info_rounded,
                    color: Colors.white,
                  ),
                ),
              if (!dataProvider.state.controlsLocked)
                IconButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => PlayerSetting(
                                  fromWatchPage: true,
                                ))).then((val) {
                      dataProvider.initSubsettings();
                      // Restore View state (subtitle screen may change the view type)
                      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
                      SystemChrome.setPreferredOrientations([
                        DeviceOrientation.landscapeLeft,
                        DeviceOrientation.landscapeRight,
                      ]);
                    });
                  },
                  tooltip: "Player settings",
                  icon: Icon(
                    Icons.video_settings_rounded,
                    color: Colors.white,
                  ),
                ),
              IconButton(
                onPressed: () {
                  dataProvider.toggleControlsLock();
                },
                icon: Icon(
                  !dataProvider.state.controlsLocked ? Icons.lock_open_rounded : Icons.lock_rounded,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}