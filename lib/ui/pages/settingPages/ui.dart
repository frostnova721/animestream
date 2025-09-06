import 'dart:io';

import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/data/settings.dart';
import 'package:animestream/core/data/theme.dart';
import 'package:animestream/core/data/types.dart';
import 'package:animestream/ui/models/popup.dart';
import 'package:animestream/ui/models/widgets/clickableItem.dart';
import 'package:animestream/ui/models/widgets/slider.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:animestream/ui/models/widgets/toggleItem.dart';
import 'package:animestream/ui/pages/settingPages/common.dart';
import 'package:animestream/ui/models/providers/themeProvider.dart';
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
    nativeTitle = currentUserSettings?.nativeTitle ?? false;
    // borderlessWindow = currentUserSettings?.useFramelessWindow ?? true;
  }

  // Future<void> setThemeMode(bool isDark) async {

  // }

  Future<void> applyTheme(int id) async {
    await setTheme(id);
    final theme = availableThemes.where((themeItem) => themeItem.id == id).toList()[0];
    Provider.of<AppProvider>(context, listen: false).applyTheme(darkMode ? theme.theme : theme.lightVariant);
  }

  int? currentThemeId;

  late double navbarTranslucency;
  late bool AMOLEDBackgroundEnabled;
  late bool darkMode;
  late bool isAboveAndroid12;
  late bool materialTheme;
  late bool useNewHomeScreen;
  late bool nativeTitle;
  // late bool borderlessWindow;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: appTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: pagePadding(context, bottom: true),
          child: Column(
            children: [
              settingPagesTitleHeader(context, "UI"),
              Container(
                child: currentThemeId != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ToggleItem(
                              label: "Material Theme",
                              value: materialTheme,
                              description: "wallpaper dependent theme",
                              onTapFunction: () async {
                                //the package just wont work if <android 12!!!
                                if (!isAboveAndroid12) return floatingSnackBar("Android 12 or greater is required");
                                materialTheme = !materialTheme;
                                await Settings().writeSettings(SettingsModal(materialTheme: materialTheme));
                                setState(() {});
                                if (materialTheme) {
                                  return Provider.of<AppProvider>(context, listen: false).justRefresh();
                                }
                                final t =
                                    availableThemes.where((themeItem) => themeItem.id == currentThemeId).toList()[0];
                                Provider.of<AppProvider>(context, listen: false)
                                    .applyTheme(darkMode ? t.theme : t.lightVariant);
                              }),
                          _themes(),
                          Container(
                            padding: EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Theme Mode",
                                  style: textStyle(),
                                ),
                                SegmentedButton(
                                  segments: [
                                    ButtonSegment(
                                        value: false,
                                        icon: Icon(Icons.wb_sunny_rounded,
                                            color: !darkMode ? appTheme.onAccent : appTheme.textMainColor)),
                                    ButtonSegment(
                                        value: true,
                                        icon: Icon(
                                          Icons.nights_stay_rounded,
                                          color: darkMode ? appTheme.onAccent : appTheme.accentColor,
                                        ))
                                  ],
                                  selected: {darkMode},
                                  multiSelectionEnabled: false,
                                  showSelectedIcon: false,
                                  emptySelectionAllowed: false,
                                  onSelectionChanged: (val) async {
                                    darkMode = val.first;
                                    await Settings().writeSettings(SettingsModal(darkMode: darkMode));

                                    await Provider.of<AppProvider>(context, listen: false).applyThemeMode(darkMode);
                                    // await setThemeMode(val.first);
                                    setState(() {});
                                  },
                                  style: SegmentedButton.styleFrom(
                                    selectedBackgroundColor: appTheme.accentColor,
                                    selectedForegroundColor: appTheme.onAccent, //not workin for some reason
                                    foregroundColor: appTheme.textMainColor,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ToggleItem(
                            onTapFunction: () async {
                              nativeTitle = !nativeTitle;
                              setState(() {});
                              await Settings().writeSettings(SettingsModal(nativeTitle: nativeTitle));
                              Provider.of<AppProvider>(context, listen: false).justRefresh();
                            },
                            label: "Prefer Native Titles",
                            value: nativeTitle,
                          ),
                          ToggleItem(
                            label: "AMOLED Background",
                            value: AMOLEDBackgroundEnabled,
                            onTapFunction: () async {
                              final thm = availableThemes.firstWhere((i) => i.id == currentThemeId);
                              // setState(() {
                              AMOLEDBackgroundEnabled = !AMOLEDBackgroundEnabled;
                              // });
                              await Settings().writeSettings(SettingsModal(amoledBackground: AMOLEDBackgroundEnabled));
                              appTheme = darkMode
                                  ? AnimeStreamTheme(
                                      accentColor: thm.theme.accentColor,
                                      backgroundColor:
                                          AMOLEDBackgroundEnabled ? Colors.black : thm.theme.backgroundColor,
                                      backgroundSubColor: thm.theme.backgroundSubColor,
                                      textMainColor: thm.theme.textMainColor,
                                      textSubColor: thm.theme.textSubColor,
                                      modalSheetBackgroundColor: thm.theme.modalSheetBackgroundColor,
                                      onAccent: thm.theme.onAccent)
                                  : thm.lightVariant;
                              // floatingSnackBar( "All set! restart the app to apply the theme");
                              // });
                              Provider.of<AppProvider>(context, listen: false).justRefresh();
                              setState(() {});
                            },
                            description: "Full black background",
                          ),
                          // if (Platform.isWindows)
                          //   _toggleItem(
                          //       "Borderless Window",
                          //       description: "*Resizing window will be affected",
                          //       borderlessWindow, () async {
                          //     setState(() {
                          //       borderlessWindow = !borderlessWindow;
                          //     });
                          //     if (borderlessWindow)
                          //       windowManager.setAsFrameless();
                          //     else
                          //       windowManager.setTitleBarStyle(TitleBarStyle.hidden, windowButtonVisibility: false);
                          //     await Settings().writeSettings(SettingsModal(useFramelessWindow: borderlessWindow));
                          //   }),
                          if (Platform.isAndroid)
                            Padding(
                              padding: EdgeInsets.only(top: 10, bottom: 10, left: 10, right: 10),
                              child: _sliderItem("Navbar Transparency", navbarTranslucency,
                                  min: 0,
                                  max: 1,
                                  description: "Transparency of the navbar",
                                  onChangedFunction: (val) {
                                    setState(() {
                                      navbarTranslucency = val;
                                    });
                                  },
                                  divisions: 10,
                                  onDragEnd: (val) async {
                                    await Settings().writeSettings(
                                      SettingsModal(navbarTranslucency: navbarTranslucency),
                                    );
                                    Provider.of<AppProvider>(context, listen: false).justRefresh();
                                  }),
                            ),
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

  Widget _themes() {
    return ClickableItem(
      label: "Themes",
      description: "Change your themes",
      suffixIcon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: appTheme.textMainColor,
      ),
      onTap: () {
        showPopup(
          context: context,
          isScrollControlledSheet: true,
          showSheetHandle: true,
          builder: (BuildContext context) => Container(
            // height: MediaQuery.of(context).orientation == Orientation.landscape
            //     ? MediaQuery.of(context).size.height / 2 + 100
            //     : MediaQuery.of(context).size.height / 3 + 100,
            width: Platform.isWindows ? MediaQuery.sizeOf(context).width / 3 : null,
            padding: EdgeInsets.only(
              top: 10,
              left: 20,
              right: 20,
            ),
            margin: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
                Container(
                  height: MediaQuery.of(context).orientation == Orientation.landscape
                      ? MediaQuery.of(context).size.height / 2
                      : MediaQuery.of(context).size.height / 3 + 120,
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: availableThemes.length,
                    itemBuilder: (context, index) {
                      return _themeItem(availableThemes[index].name, availableThemes[index], context);
                    },
                  ),
                ),
              ],
            ),
          ),
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

  Widget _themeItem(String name, ThemeItem theme, context) {
    bool isSelected = currentThemeId == theme.id;
    return AnimatedContainer(
      margin: EdgeInsets.only(top: 5, bottom: 5),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: isSelected ? appTheme.accentColor.withAlpha(150) : appTheme.backgroundSubColor,
        border: Border.all(
          color: isSelected ? theme.theme.accentColor : Colors.transparent,
          width: 2,
        ),
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
              // Navigator.of(context).pop();
            }
          },
          child: Padding(
            padding: const EdgeInsets.only(left: 10, right: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "$name",
                  style: textStyle().copyWith(color: isSelected ? appTheme.onAccent : appTheme.textMainColor),
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
