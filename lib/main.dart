import 'dart:io';

import 'package:animestream/core/app/logging.dart';
import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/data/settings.dart';
import 'package:animestream/core/data/theme.dart';
import 'package:animestream/ui/models/notification.dart';
import 'package:animestream/ui/models/parent.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:animestream/ui/pages/mainNav.dart';
import 'package:animestream/ui/theme/mainTheme.dart';
import 'package:animestream/ui/theme/themes.dart';
import 'package:animestream/ui/theme/types.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/services.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    final Directory dir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(dir.path);
    await loadAndAssignSettings();
    NotificationService().init();
    runApp(ThemeChangerWidget(
      child: const AnimeStream()));
  } catch (err) {
    debugPrint(err.toString());
    Logger().writeLog(err.toString());
    print("[CRASH] logged the error to logs folder");
  }
}

Future<void> loadAndAssignSettings() async {
  await Settings().getSettings().then((settings) => {
        currentUserSettings = settings,
        print("[STARTUP] Loaded user settings"),
      });

  //load and apply theme
  await getTheme().then((themeId) {
    if (themeId > availableThemes.length) {
      print("[STARTUP] Failed to apply theme with ID $themeId, Applying default theme");
      showToast("Failed to apply theme. Using default theme");
      setTheme(01);
      themeId = 01;
    }

    final darkMode = currentUserSettings!.darkMode!;

    final theme = availableThemes.where((theme) => theme.id == themeId).toList()[0];
    if (darkMode) {
      appTheme = theme.theme;
      accentColor = theme.theme.accentColor;
      textMainColor = theme.theme.textMainColor;
      textSubColor = theme.theme.textSubColor;
      backgroundColor = (currentUserSettings?.amoledBackground ?? false) ? Colors.black : theme.theme.backgroundColor;
      backgroundSubColor = theme.theme.backgroundSubColor;
      modalSheetBackgroundColor = theme.theme.modalSheetBackgroundColor;
    } else {
      appTheme = AnimeStreamTheme(
        accentColor: theme.theme.accentColor,
        textMainColor: Colors.black,
        textSubColor: theme.theme.textSubColor,
        backgroundColor: Colors.white,
        backgroundSubColor: Color.fromARGB(255, 179, 179, 179),
        modalSheetBackgroundColor: theme.theme.modalSheetBackgroundColor,
      );
    }

    print("[STARTUP] Loaded theme of ID $themeId");
  });
}

class AnimeStream extends StatefulWidget {
  const AnimeStream({super.key});

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  @override
  State<AnimeStream> createState() => _AnimeStreamState();
}

class _AnimeStreamState extends State<AnimeStream> {
  @override
  void initState() {
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: NotificationController.onActionReceivedMethod,
      onNotificationCreatedMethod: NotificationController.onNotificationCreatedMethod,
      onNotificationDisplayedMethod: NotificationController.onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: NotificationController.onDismissActionReceivedMethod,
    );

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Colors.black.withOpacity(0.002), systemNavigationBarColor: Colors.black.withOpacity(0.002)));

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge, overlays: [SystemUiOverlay.top]);

    super.initState();
  }

  // This widget is the root of *my* application.
  @override
  Widget build(BuildContext context) {
    backgroundSubColor = Color.fromARGB(255, 196, 196, 196);
    return MaterialApp(
      title: 'Animestream',
      theme: ThemeData(
        useMaterial3: true,
        textTheme: Theme.of(context).textTheme.apply(bodyColor: appTheme?.textMainColor, fontFamily: "NotoSans"),
        scaffoldBackgroundColor: appTheme?.backgroundColor,
        bottomSheetTheme: BottomSheetThemeData(backgroundColor: appTheme?.modalSheetBackgroundColor),
        colorScheme: ColorScheme.fromSeed(
          seedColor: appTheme?.accentColor ?? accentColor,
        ),
      ),
      home: const MainNavigator(),
      debugShowCheckedModeBanner: false,
    );
  }
}
