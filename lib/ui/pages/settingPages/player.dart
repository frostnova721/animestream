import 'package:animestream/core/data/settings.dart';
import 'package:animestream/core/data/types.dart';
import 'package:animestream/ui/pages/settingPages/common.dart';
import 'package:animestream/ui/theme/mainTheme.dart';
import 'package:flutter/material.dart';

class PlayerSetting extends StatefulWidget {
  const PlayerSetting({super.key});

  @override
  State<PlayerSetting> createState() => PlayerSettingState();
}

class PlayerSettingState extends State<PlayerSetting> {
  @override
  void initState() {
    super.initState();
    readSettings();
  }

  int? skipDuration;
  int? megaSkipDuration;
  bool loaded = false;

  Future<void> readSettings() async {
    final settings = await Settings().getSettings();
    loaded = true;
    setState(() {
      skipDuration = settings.skipDuration;
      megaSkipDuration = settings.megaSkipDuration;
    });
  }

  Future<void> writeSettings(SettingsModal settings) async {
    await Settings().writeSettings(settings);
    setState(() {
      readSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: Container(
          child: loaded
              ? Column(
                  children: [
                    topRow(context, "Player"),
                    Container(
                      padding: EdgeInsets.only(left: 20, right: 20, top: 30),
                      child: Column(
                        children: [
                          Container(
                            height: 60,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Skip duration",
                                  style: textStyle(),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          if (skipDuration! > 5)
                                            writeSettings(SettingsModal(
                                                skipDuration: skipDuration! - 5));
                                        });
                                      },
                                      icon: Icon(
                                        Icons.remove_rounded,
                                        color: textMainColor,
                                      ),
                                    ),
                                    Container(
                                      alignment: Alignment.center,
                                      width: 40,
                                      child: Text(
                                        "$skipDuration",
                                        style: textStyle(),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          if (skipDuration! < 50)
                                            writeSettings(SettingsModal(
                                                skipDuration: skipDuration! + 5));
                                        });
                                      },
                                      icon: Icon(
                                        Icons.add_rounded,
                                        color: textMainColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 60,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Mega skip duration",
                                  style: textStyle(),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          if (megaSkipDuration! > 20)
                                            writeSettings(SettingsModal(
                                                megaSkipDuration: megaSkipDuration! - 5));
                                        });
                                      },
                                      icon: Icon(
                                        Icons.remove_rounded,
                                        color: textMainColor,
                                      ),
                                    ),
                                    Container(
                                      alignment: Alignment.center,
                                      width: 40,
                                      child: Text(
                                        "$megaSkipDuration",
                                        style: textStyle(),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          if (megaSkipDuration! < 150)
                                            writeSettings(SettingsModal(
                                                megaSkipDuration: megaSkipDuration! + 5));
                                        });
                                      },
                                      icon: Icon(
                                        Icons.add_rounded,
                                        color: textMainColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                )
              : Container(),
        ),
      ),
    );
  }
}
