import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/ui/models/providers/playerDataProvider.dart';
import 'package:animestream/ui/models/providers/playerProvider.dart';
import 'package:animestream/ui/pages/settingPages/player.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class TopControls extends StatelessWidget {
  const TopControls({
    super.key,
    required this.context,
  });

  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    final (epIdx, locked) = context.select<PlayerDataProvider, (int, bool)>((p) => (p.state.currentEpIndex ,p.state.controlsLocked));
    final epTitle = context.read<PlayerProvider>().isOffline
        ? 'Episode ${epIdx + 1}'
        : context.read<PlayerDataProvider>().epLinks[epIdx].episodeTitle;
    return Expanded(
      child: Container(
        alignment: Alignment.topCenter,
        child: Container(
          height: 50,
          child: Row(
            children: [
              if (!locked)
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
                child: locked
                    ? Container()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.only(left: 20, top: 5),
                            alignment: Alignment.topLeft,
                            child: Text(
                                (epTitle == null || epTitle.isEmpty)
                                    ? "Episode ${epIdx + 1}"
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
                              "${context.read<PlayerDataProvider>().showTitle}",
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
              if (kDebugMode && !locked)
                IconButton(
                  onPressed: () {
                    final dataProvider = context.read<PlayerDataProvider>();
                    showDialog(
                      context: context,
                      builder: (BuildContext context) => AlertDialog(
                        backgroundColor: Colors.black,
                        contentTextStyle: TextStyle(color: Colors.white),
                        title: Text("VideoStream info", style: TextStyle(color: appTheme.accentColor)),
                        content: Text(
                          "Resolution: ${dataProvider.state.currentQuality.resolution}"
                          "\nProvider: ${dataProvider.state.preferredServer}"
                          "\nServer: ${dataProvider.state.currentStream.server} ${dataProvider.state.currentStream.backup ? "\(backup\)" : ''}"
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
              if (!locked)
                IconButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => PlayerSetting(
                                  fromWatchPage: true,
                                ))).then((val) {
                      context.read<PlayerDataProvider>().initSubsettings();
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
                  context.read<PlayerDataProvider>().toggleControlsLock();
                },
                icon: Icon(
                  !locked ? Icons.lock_open_rounded : Icons.lock_rounded,
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