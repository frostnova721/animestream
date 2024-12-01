import 'dart:io';

import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/data/settings.dart';
import 'package:animestream/core/data/theme.dart';
import 'package:animestream/core/data/types.dart';
import 'package:animestream/ui/models/slider.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:animestream/ui/pages/settingPages/common.dart';
import 'package:animestream/ui/theme/themeProvider.dart';
import 'package:animestream/ui/theme/themes.dart';
import 'package:animestream/ui/theme/types.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ThemeSetting extends StatefulWidget {
  const ThemeSetting({super.key});

  @override
  State<ThemeSetting> createState() => _ThemeSettingState();
}

class _ThemeSettingState extends State<ThemeSetting> {
  @override
  void initState() {
    super.initState();
    readSettings();
    getAPILevel();
  }

  void getAPILevel() {
    if (Platform.isAndroid)
      DeviceInfoPlugin().androidInfo.then((val) => isAboveAndroid12 = (val.version.sdkInt >= 31));
    else
      isAboveAndroid12 = true;
  }

  void readSettings() {
    getTheme().then((value) => setState(() {
          currentThemeId = value;
        }));
    AMOLEDBackgroundEnabled = currentUserSettings?.amoledBackground ?? false;
    navbarTranslucency = currentUserSettings?.navbarTranslucency ?? 0.6;
    darkMode = currentUserSettings?.darkMode ?? true;
    materialTheme = currentUserSettings?.materialTheme ?? false;
  }

  Future<void> setThemeMode(bool isDark) async {
    await Settings().writeSettings(SettingsModal(darkMode: isDark));

    Provider.of<ThemeProvider>(context, listen: false).applyThemeMode(isDark);

    return;
  }

  Future<void> applyTheme(int id) async {
    await setTheme(id);
    // print(Theme.of(context).);
    Provider.of<ThemeProvider>(context, listen: false)
        .applyTheme(availableThemes.where((themeItem) => themeItem.id == id).toList()[0].theme);
    // floatingSnackBar(context, "All set! restart the app to apply the theme");
  }

  int? currentThemeId;

  late double navbarTranslucency;
  late bool AMOLEDBackgroundEnabled;
  late bool darkMode;
  late bool isAboveAndroid12;
  late bool materialTheme;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: pagePadding(context, bottom: true),
          child: Column(
            children: [
              settingPagesTitleHeader(context, "UI"),
              Container(
                padding: EdgeInsets.only(left: 15, right: 15, top: 0),
                child: currentThemeId != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _toggleItem("Material Theme", materialTheme, description: "wallpaper dependent theme",
                              () async {
                            //the package just wont work if <android 12!!!
                            if (!isAboveAndroid12)
                              return floatingSnackBar(context, "Android 12 or greater is required");
                            materialTheme = !materialTheme;
                            await Settings().writeSettings(SettingsModal(materialTheme: materialTheme));
                            setState(() {});
                            if (materialTheme) {
                              return Provider.of<ThemeProvider>(context, listen: false).justRefresh();
                            }
                            Provider.of<ThemeProvider>(context, listen: false).applyTheme(
                                availableThemes.where((themeItem) => themeItem.id == currentThemeId).toList()[0].theme);
                          }),
                          _themes(),
                          Container(
                            padding: EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Mode",
                                  style: textStyle(),
                                ),
                                SegmentedButton(segments: [
                                  ButtonSegment(value: false, icon: Icon(Icons.wb_sunny_rounded)),
                                  ButtonSegment(value: true, icon: Icon(Icons.nights_stay_rounded))
                                ], selected: {darkMode},
                                multiSelectionEnabled: false,
                                showSelectedIcon: false,
                                emptySelectionAllowed: false,
                                onSelectionChanged: (val) async {
                                  await setThemeMode(val.first);
                                  setState(() {
                                    darkMode = val.first;
                                  });
                                },
                                style: SegmentedButton.styleFrom(
                                  selectedBackgroundColor: appTheme.accentColor,
                                  selectedForegroundColor: appTheme.backgroundColor,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                                ),
                                ),
                              ],
                            ),
                          ),
                          _toggleItem(
                            "AMOLED Background",
                            AMOLEDBackgroundEnabled,
                            () {
                              setState(() {
                                AMOLEDBackgroundEnabled = !AMOLEDBackgroundEnabled;
                                Settings().writeSettings(SettingsModal(amoledBackground: AMOLEDBackgroundEnabled));
                                appTheme.backgroundColor = AMOLEDBackgroundEnabled && darkMode
                                    ? Colors.black
                                    : darkMode
                                        ? darkModeValues.backgroundColor
                                        : lightModeValues.backgroundColor;
                                // floatingSnackBar(context, "All set! restart the app to apply the theme");
                              });
                              return Provider.of<ThemeProvider>(context, listen: false).justRefresh();
                            },
                            description: "Full black background",
                          ),
                          _sliderItem("Navbar Translucency", navbarTranslucency,
                              min: 0,
                              max: 1,
                              description: "transparency and blur of the navbar",
                              onChangedFunction: (val) {
                                setState(() {
                                  navbarTranslucency = val;
                                });
                              },
                              divisions: 10,
                              onDragEnd: (val) {
                                Settings().writeSettings(
                                  SettingsModal(navbarTranslucency: navbarTranslucency),
                                );
                              }),
                        ],
                      )
                    : Container(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sliderItem(
    String label,
    double variable, {
    required void Function(double) onChangedFunction,
    required double min,
    required double max,
    String? description,
    int divisions = 10,
    void Function(double)? onDragStart,
    void Function(double)? onDragEnd,
  }) {
    return item(
      child: Container(
        padding: EdgeInsets.only(left: 10, right: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: textStyle(),
            ),
            if (description != null)
              Text(
                description,
                style: textStyle().copyWith(color: appTheme.textSubColor, fontSize: 12),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 30),
              child: CustomSlider(
                min: min,
                max: max,
                onChanged: onChangedFunction,
                onDragStart: onDragStart,
                onDragEnd: onDragEnd,
                divisions: divisions,
                value: variable,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _clickableItem(String label, {String? description, void Function()? onTapFunction, Icon? suffixIcon}) {
    return InkWell(
      onTap: onTapFunction,
      child: item(
        child: Container(
          padding: EdgeInsets.only(left: 10, right: 10),
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: textStyle(),
                    ),
                    if (description != null)
                      Text(
                        description,
                        style: textStyle().copyWith(color: appTheme.textSubColor, fontSize: 12),
                      ),
                  ],
                ),
              ),
              if (suffixIcon != null) suffixIcon,
            ],
          ),
        ),
      ),
    );
  }

  Widget _themes() {
    return _clickableItem(
      "Themes",
      description: "Change your themes",
      suffixIcon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: appTheme.textMainColor,
      ),
      onTapFunction: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: appTheme.modalSheetBackgroundColor,
          showDragHandle: true,
          builder: (context) {
            return Container(
              height: MediaQuery.of(context).orientation == Orientation.landscape
                  ? MediaQuery.of(context).size.height / 2 + 100
                  : MediaQuery.of(context).size.height / 3 + 100,
              padding: EdgeInsets.only(
                top: 10,
                left: 20,
                right: 20,
              ),
              margin: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 10, bottom: 20),
                    child: Text(
                      "Select Theme",
                      style: textStyle().copyWith(
                        fontSize: 23,
                      ),
                    ),
                  ),
                  Expanded(
                    // height: MediaQuery.of(context).orientation == Orientation.landscape
                    //     ? MediaQuery.of(context).size.height / 2
                    //     : MediaQuery.of(context).size.height / 3,
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      // shrinkWrap: true,
                      itemCount: availableThemes.length,
                      itemBuilder: (context, index) {
                        return _themeItem(availableThemes[index].name, availableThemes[index], context);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Container item({required Widget child}) {
    return Container(
      padding: EdgeInsets.only(top: 15, bottom: 15),
      child: child,
    );
  }

  InkWell _toggleItem(String label, bool value, void Function() onTapFunction, {String? description = null}) {
    return InkWell(
      onTap: onTapFunction,
      child: item(
        child: Container(
          padding: EdgeInsets.only(
            left: 10,
            right: 10,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: textStyle(),
                  ),
                  if (description != null)
                    Text(
                      description,
                      style: textStyle().copyWith(color: appTheme.textSubColor, fontSize: 12),
                    ),
                ],
              ),
              Switch(
                value: value,
                onChanged: (val) {
                  onTapFunction();
                },
                activeColor: appTheme.backgroundColor,
                activeTrackColor: appTheme.accentColor,
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _themeItem(String name, ThemeItem theme, context) {
    return AnimatedContainer(
      margin: EdgeInsets.only(top: 5, bottom: 5),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: currentThemeId == theme.id ? appTheme.accentColor : appTheme.backgroundSubColor,
      ),
      duration: Duration(milliseconds: 200),
      height: 60,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            if (currentThemeId != theme.id) {
            await applyTheme(theme.id);
            setState(() {
              currentThemeId = theme.id;
            });
            Navigator.of(context).pop();
          }
          },
          child: Padding(
            padding: const EdgeInsets.only(left: 10, right: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "$name",
                  style: textStyle()
                      .copyWith(color: currentThemeId == theme.id ? appTheme.backgroundColor : appTheme.textMainColor),
                ),
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 3),
                    borderRadius: BorderRadius.circular(10),
                    color: theme.theme.accentColor,
                  ),
                )
              ],
            ),
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
