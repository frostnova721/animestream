import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/data/settings.dart';
import 'package:animestream/core/data/types.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:animestream/ui/models/widgets/toggleItem.dart';
import 'package:animestream/ui/pages/settingPages/common.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class DownloaderSettings extends StatefulWidget {
  const DownloaderSettings({super.key});

  @override
  State<DownloaderSettings> createState() => _DownloaderSettingsState();
}

class _DownloaderSettingsState extends State<DownloaderSettings> {

  @override
  void initState() {
    super.initState();

    readSettings();
  }

  Future<void> writeSettings(SettingsModal settings) async {
    await Settings().writeSettings(settings);
    setState(() {
      readSettings();
    });
  }

  Future<void> readSettings() async {
    final settings = await Settings().getSettings();
    setState(() {
      fasterDownloads = settings.fasterDownloads!;
      useQueuedDownloads = settings.useQueuedDownloads!;
      writeSubtitleTrackToVideo = settings.writeSubtitleTrackToVideo!;
      useRemuxer = settings.useMkvRemuxer!;
    });
  }

  bool fasterDownloads = false;
  bool useQueuedDownloads = false;
  bool writeSubtitleTrackToVideo = false;
  bool useRemuxer = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: appTheme.backgroundColor,
        body: SingleChildScrollView(
          child: Container(
            padding: pagePadding(context, bottom: true),
            child: Column(
              children: [
                settingPagesTitleHeader(context, "Downloader"),
                ToggleItem(
                    label: "Use faster downloading",
                    value: fasterDownloads,
                    onTapFunction: () {
                      setState(() {
                        fasterDownloads = !fasterDownloads;
                      });
                      writeSettings(SettingsModal(fasterDownloads: fasterDownloads));
                    },
                    description: "download 2x items per batch"),
                ToggleItem(
                    label: "Queued downloads",
                    value: useQueuedDownloads,
                    description: "Download items one by one",
                    onTapFunction: () {
                      setState(() {
                        useQueuedDownloads = !useQueuedDownloads;
                      });
                      writeSettings(SettingsModal(useQueuedDownloads: useQueuedDownloads));
                    }),

                // f**k experimental notice
                ToggleItem(
                    label: "Use MKV Remuxer",
                    value: useRemuxer,
                    description: "Remux streams to MKV",
                    onTapFunction: () {
                      setState(() async {
                        useRemuxer = !useRemuxer;
                      });
                      writeSettings(SettingsModal(useMkvRemuxer: useRemuxer));
                    }),
                ToggleItem(
                    label: "Write subtitle to video",
                    value: writeSubtitleTrackToVideo,
                    description: "only works while remuxing",
                    onTapFunction: () {
                      setState(() async {
                        writeSubtitleTrackToVideo = !writeSubtitleTrackToVideo;
                      });
                      writeSettings(SettingsModal(writeSubtitleTrackToVideo: writeSubtitleTrackToVideo));
                    }),
                InkWell(
                  onTap: () async {
                    String? dir;
                    // if (Platform.isWindows) {
                    //   dir = await FilePickerWindows().getDirectoryPath();
                    // } else if (Platform.isLinux) {
                    //   dir = await FilePickerLinux().getDirectoryPath();
                    // } else {
                      dir = await FilePicker.getDirectoryPath();
                    // }
                    if (dir == null) return;
                    print("Path set to: $dir");
                    await Settings().writeSettings(SettingsModal(downloadPath: dir));
                    setState(() {});
                    floatingSnackBar("might need to provide 'allow access to all files' while downloading!");
                  },
                  child: Container(
                    padding: EdgeInsets.only(top: 10, bottom: 10, left: 20, right: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Download path",
                              style: textStyle(),
                            ),
                            Text(
                              currentUserSettings?.downloadPath ?? "Default downloads directory",
                              style: textStyle().copyWith(color: appTheme.textSubColor, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        Icon(Icons.navigate_next_rounded)
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
