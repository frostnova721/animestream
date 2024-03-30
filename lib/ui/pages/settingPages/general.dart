import 'package:animestream/core/data/settings.dart';
import 'package:animestream/core/data/types.dart';
import 'package:animestream/ui/pages/settingPages/common.dart';
import 'package:animestream/ui/theme/mainTheme.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top,
          bottom: MediaQuery.of(context).padding.bottom,
        ),
        child: loaded
            ? Column(
                children: [
                  topRow(context, "General"),
                  Container(
                    margin: EdgeInsets.only(top: 30),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          showErrorsButtonState = !showErrorsButtonState;
                        });
                        writeSettings(
                            SettingsModal(showErrors: showErrorsButtonState));
                      },
                      child: Container(
                        padding: EdgeInsets.only(
                            left: 20, right: 20, top: 10, bottom: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Show Errors",
                              style: textStyle(),
                            ),
                            Switch(
                              value: showErrorsButtonState,
                              activeColor: backgroundColor,
                              activeTrackColor: accentColor,
                              onChanged: (val) {
                                setState(() {
                                  showErrorsButtonState = val;
                                });
                                writeSettings(SettingsModal(
                                    showErrors: showErrorsButtonState));
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              )
            : Container(),
      ),
    );
  }
}
