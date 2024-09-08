import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/data/settings.dart';
import 'package:animestream/core/data/types.dart';
import 'package:animestream/ui/models/sources.dart';
import 'package:animestream/ui/pages/settingPages/common.dart';
import 'package:flutter/material.dart';

class GeneralSetting extends StatefulWidget {
  const GeneralSetting({super.key});

  @override
  State<GeneralSetting> createState() => _GeneralSettingState();
}

class _GeneralSettingState extends State<GeneralSetting> {
  @override
  initState() {
    readSettings().then((val) => setState(() {
          loaded = true;
        }));
    super.initState();
  }

  Future<void> readSettings() async {
    final settings = await Settings().getSettings();
    setState(() {
      showErrorsButtonState = settings.showErrors!;
      receivePreReleases = settings.receivePreReleases!;
      fasterDownloads = settings.fasterDownloads!;
    });
  }

  Future<void> writeSettings(SettingsModal settings) async {
    await Settings().writeSettings(settings);
    setState(() {
      readSettings();
    });
  }

  bool loaded = false;
  bool showErrorsButtonState = false;
  bool receivePreReleases = false;
  bool fasterDownloads = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      body: loaded
          ? SingleChildScrollView(
              child: Padding(
                padding: pagePadding(context, bottom: true),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    settingPagesTitleHeader(context, "General"),
                    toggleItem(
                      "Show errors",
                      showErrorsButtonState,
                      () {
                        setState(() {
                          showErrorsButtonState = !showErrorsButtonState;
                        });
                        writeSettings(SettingsModal(showErrors: showErrorsButtonState));
                      },
                    ),
                    toggleItem(
                      "Receive beta updates",
                      receivePreReleases,
                      () {
                        setState(() {
                          receivePreReleases = !receivePreReleases;
                        });
                        writeSettings(SettingsModal(receivePreReleases: receivePreReleases));
                      },
                      description: "*maybe unstable",
                    ),
                    toggleItem("Use faster downloading", fasterDownloads, () {
                      setState(() {
                        fasterDownloads = !fasterDownloads;
                      });
                      writeSettings(SettingsModal(fasterDownloads: fasterDownloads));
                    }, description: "*download 2x items per batch"),
                    Container(
                      padding: EdgeInsets.only(top: 20, bottom: 10, left: 20, right: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Default provider",
                            style: textStyle(),
                          ),
                          Container(
                            alignment: Alignment.center,
                            padding: EdgeInsets.only(top: 20),
                            child: DropdownMenu(
                              width: MediaQuery.of(context).size.width - 80,
                              label: Text("providers", style: TextStyle(color: appTheme.textMainColor, fontSize: 18, fontWeight: FontWeight.bold),),
                              leadingIcon: Icon(Icons.source_rounded, color: appTheme.textMainColor,),
                                initialSelection: currentUserSettings?.preferredProvider ?? sources[0],
                                onSelected: (val) async {
                                  writeSettings(SettingsModal(preferredProvider: val));
                                },
                                textStyle: TextStyle(fontFamily: "NotoSans", fontSize: 16, fontWeight: FontWeight.bold, color: appTheme.textMainColor),
                                menuStyle: MenuStyle(backgroundColor: WidgetStatePropertyAll(appTheme.backgroundColor), shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)))),
                                dropdownMenuEntries: getSourceDropdownList()),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Container(),
    );
  }
}
