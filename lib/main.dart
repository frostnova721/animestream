import 'dart:async';
import 'dart:io';

import 'package:animestream/core/app/version.dart';
import 'package:animestream/core/data/preferences.dart';
import 'package:animestream/ui/models/sources.dart';
import 'package:animestream/ui/models/widgets/appWrapper.dart';
import 'package:animestream/ui/theme/lime.dart';
import 'package:app_links/app_links.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'package:animestream/core/anime/providers/animeonsen.dart';
import 'package:animestream/core/app/logging.dart';
import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/data/hive.dart';
import 'package:animestream/core/data/secureStorage.dart';
import 'package:animestream/core/data/settings.dart';
import 'package:animestream/core/data/theme.dart';
import 'package:animestream/ui/models/notification.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:animestream/ui/pages/mainNav.dart';
import 'package:animestream/ui/models/providers/themeProvider.dart';
import 'package:animestream/ui/theme/themes.dart';
import 'package:animestream/ui/theme/types.dart';
import 'package:window_manager/window_manager.dart';

void main(List<String> args) async {
  try {
    if (runWebViewTitleBarWidget(args)) {
      return;
    }

    WidgetsFlutterBinding.ensureInitialized();

    final Directory dir = await getApplicationDocumentsDirectory();

    // Initialise app version instance
    AppVersion.init();

    await Hive.initFlutter(dir.path);

    await loadAndAssignSettings();

    await migrateToSecureStorage();

    if (Platform.isWindows) {
      await windowManager.ensureInitialized();
      await windowManager.setTitleBarStyle(TitleBarStyle.hidden, windowButtonVisibility: false);

      // No frameless for now!
      // if (currentUserSettings?.useFramelessWindow ?? true) await windowManager.setAsFrameless();

      await windowManager.setResizable(true);
    }

    AnimeOnsen().checkAndUpdateToken();

    NotificationService().init();

    /// Load sources. we adding inbuilt sources till migrated
    final sm = SourceManager();

    sm
      ..addSources(sm.inbuiltSources)
      ..loadProviders(clearBeforeLoading: false);

    await dotenv.load(fileName: ".env");

    // if (currentUserSettings?.enableDiscordPresence ?? false) {
    //   await FlutterDiscordRPC.initialize("1362858832266657812");
    // }

    runApp(
      ChangeNotifierProvider(
        create: (context) => AppProvider(),
        child: const AnimeStream(),
      ),
    );
  } catch (err) {
    debugPrint(err.toString());

    Logger()
      ..addLog(err.toString())
      ..addLog("state: Crashed")
      ..writeLog();

    print("[CRASH] logged the error to logs folder");
    rethrow;
  }
}

// Migrate if not already done, will be removed in future versions (if not discontinued)
Future<void> migrateToSecureStorage() async {
  final token = await getVal(HiveKey.token);
  if (token != null) {
    await storeSecureVal(SecureStorageKey.anilistToken, token);
    await storeVal(HiveKey.token, null);
    print("[STARTUP] Migrated to Secure Storage");
  }
}

Future<void> loadAndAssignSettings() async {
  await Settings().getSettings().then((settings) => {
        currentUserSettings = settings,
        print("[STARTUP] Loaded user settings"),
      });

  await UserPreferences.getUserPreferences().then((pref) {
    userPreferences = pref;
    print("[STARTUP] Loaded user preferences");
  });

  //load and apply theme
  await getTheme().then((themeId) {
    if (themeId > availableThemes.length || themeId < 1) {
      print("[STARTUP] Failed to apply theme with ID $themeId, Applying default theme");
      showToast("Failed to apply theme. Using default theme");
      setTheme(01);
      themeId = 01;
    }

    final darkMode = currentUserSettings!.darkMode!;

    ThemeItem? theme = availableThemes.where((theme) => theme.id == themeId).toList().firstOrNull;

    if (theme == null) {
      // Set default theme incase of any corruptions/issues n stuff
      theme = LimeZest();
      print("[STARTUP] Failed to apply theme with ID $themeId, Applying default theme");
    }

    if (darkMode) {
      appTheme = theme.theme;
      appTheme.backgroundColor =
          (currentUserSettings!.amoledBackground ?? false) ? Colors.black : theme.theme.backgroundColor;
    } else {
      appTheme = AnimeStreamTheme(
        accentColor: theme.lightVariant.accentColor,
        textMainColor: theme.lightVariant.textMainColor,
        textSubColor: theme.lightVariant.textSubColor,
        backgroundColor: theme.lightVariant.backgroundColor,
        backgroundSubColor: theme.lightVariant.backgroundSubColor,
        modalSheetBackgroundColor: theme.lightVariant.modalSheetBackgroundColor,
        onAccent: theme.lightVariant.onAccent,
      );
    }

    print("[STARTUP] Loaded theme of ID $themeId (${theme.name})");
  });
}

class AnimeStream extends StatefulWidget {
  const AnimeStream({super.key});

  static final GlobalKey<ScaffoldMessengerState> snackbarKey = GlobalKey<ScaffoldMessengerState>();

  static final navigatorKey = GlobalKey<NavigatorState>();
  @override
  State<AnimeStream> createState() => _AnimeStreamState();
}

class _AnimeStreamState extends State<AnimeStream> {
  StreamSubscription<Uri>? _sub;
  late AppLinks _appLinks;

  @override
  void initState() {
    listenDeepLinkCall();

    AwesomeNotifications().setListeners(
      onActionReceivedMethod: NotificationController.onActionReceivedMethod,
      onNotificationCreatedMethod: NotificationController.onNotificationCreatedMethod,
      onNotificationDisplayedMethod: NotificationController.onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: NotificationController.onDismissActionReceivedMethod,
    );

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge, overlays: [SystemUiOverlay.top]);
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.black.withValues(alpha: 0.002),
        systemNavigationBarColor: Colors.black.withValues(alpha: 0.002),
      ),
    );

    // if (currentUserSettings?.enableDiscordPresence ?? false)
    // FlutterDiscordRPC.instance.connect(autoRetry: true, retryDelay: Duration(seconds: 10));

    super.initState();
  }

  @override
  void dispose() {
    _sub?.cancel();

    // if (currentUserSettings?.enableDiscordPresence ?? false) {
    //   FlutterDiscordRPC.instance.clearActivity();
    //   FlutterDiscordRPC.instance.disconnect();
    //   FlutterDiscordRPC.instance.dispose();
    // }
    super.dispose();
  }

  void listenDeepLinkCall() {
    _appLinks = AppLinks();
    _sub = _appLinks.uriLinkStream.listen((uri) {
      if (uri.scheme == "animestream") {
        print("Invoked DeepLink uri: ${uri.toString()}");
        String host = uri.host;
        switch (host) {
          case "info":
            {
              final id = int.tryParse(uri.queryParameters['id'] ?? "nothing");
              if (id != null)
                //need to do smth T-T
                break;
            }
          default:
            print("BAD-INTENT-PATH");
        }
      }
    });
  }

  Widget? deepLinkRequestedNavigationPage = null;

  // This widget is the root of *my* application.
  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightScheme, darkScheme) {
        late AnimeStreamTheme scheme;

        //just checks for dark mode and sets the appTheme variable with suitable theme
        if (currentUserSettings?.darkMode ?? true) {
          scheme = AnimeStreamTheme(
            accentColor: darkScheme?.primary ?? appTheme.accentColor,
            backgroundColor: (currentUserSettings?.amoledBackground ?? false)
                ? Colors.black
                : darkScheme?.surface ?? appTheme.backgroundColor,
            backgroundSubColor: darkScheme?.secondaryContainer ?? appTheme.backgroundSubColor,
            textMainColor: darkScheme?.onSurface ?? appTheme.textMainColor,
            textSubColor: darkScheme?.onSurfaceVariant ?? appTheme.textSubColor,
            modalSheetBackgroundColor: darkScheme?.surface ?? appTheme.modalSheetBackgroundColor,
            onAccent: darkScheme?.onPrimary ?? appTheme.onAccent,
          );
        } else {
          scheme = AnimeStreamTheme(
            accentColor: lightScheme?.primary ?? appTheme.accentColor,
            backgroundColor: lightScheme?.surface ?? appTheme.accentColor,
            backgroundSubColor: lightScheme?.secondaryContainer ?? appTheme.backgroundSubColor,
            textMainColor: lightScheme?.onSurface ?? appTheme.textMainColor,
            textSubColor: lightScheme?.onSurfaceVariant ?? appTheme.textSubColor,
            modalSheetBackgroundColor: lightScheme?.surface ?? appTheme.modalSheetBackgroundColor,
            onAccent: lightScheme?.onPrimary ?? appTheme.onAccent,
          );
        }

        if (currentUserSettings?.materialTheme ?? false) {
          appTheme = scheme;
          // print("[THEME] Applying Material You Theme");
        } else {
          // lmao we can make it follow material theme XD
          // final t = ThemeData.from(
          //   colorScheme: ColorScheme.fromSeed(
          //       seedColor: appTheme.accentColor,
          //       brightness: (currentUserSettings?.darkMode ?? true) ? Brightness.dark : Brightness.light),
          // ).colorScheme;
          // appTheme = AnimeStreamTheme(
          //   accentColor: t.primary,
          //   backgroundColor: t.surface,
          //   backgroundSubColor: t.secondaryContainer,
          //   textMainColor: t.onSurface,
          //   textSubColor: t.outline,
          //   modalSheetBackgroundColor: t.surface,
          //   onAccent: t.onPrimary,
          // );
        }

        final themeProvider = Provider.of<AppProvider>(context);

        //set status bar icon brightness (some devices do this automatically, some dont!
        //so here it is for all of em!)
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarIconBrightness: themeProvider.isDark ? Brightness.light : Brightness.dark,
            statusBarColor: Colors.black.withValues(alpha: 0.002),
            systemNavigationBarColor: Colors.black.withValues(alpha: 0.002),
          ),
        );

        return MaterialApp(
          title: 'Animestream',
          scaffoldMessengerKey: AnimeStream.snackbarKey,
          theme: ThemeData(
              useMaterial3: true,
              brightness: themeProvider.isDark ? Brightness.dark : Brightness.light,
              textTheme: Theme.of(context).textTheme.apply(bodyColor: appTheme.textMainColor, fontFamily: "NotoSans"),
              scaffoldBackgroundColor: appTheme.backgroundColor,
              bottomSheetTheme: BottomSheetThemeData(backgroundColor: appTheme.modalSheetBackgroundColor),
              colorScheme: ColorScheme.fromSeed(
                brightness: themeProvider.isDark ? Brightness.dark : Brightness.light,
                seedColor: (currentUserSettings?.materialTheme ?? false) ? scheme.accentColor : appTheme.accentColor,
              ),
              iconTheme: IconThemeData(color: appTheme.textMainColor)),
          home: Platform.isWindows
              ? AppWrapper(firstPage: deepLinkRequestedNavigationPage ?? MainNavigator())
              : deepLinkRequestedNavigationPage ?? MainNavigator(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
