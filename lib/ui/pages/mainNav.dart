import 'dart:io';

import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/app/update.dart';
import 'package:animestream/core/commons/utils.dart';
import 'package:animestream/core/data/downloadHistory.dart';
import 'package:animestream/ui/models/providers/mainNavProvider.dart';
import 'package:animestream/ui/models/widgets/bottomBar.dart';
import 'package:animestream/ui/models/widgets/cards.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:animestream/ui/pages/discover.dart';
import 'package:animestream/ui/pages/home.dart';
import 'package:animestream/ui/pages/search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => MainNavigatorState();
}

class MainNavigatorState extends State<MainNavigator> with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();

    final provider = context.read<MainNavProvider>();

    isTv().then((value) => provider.tv = value);

    // open the box for the whole app life time!
    DownloadHistory.initBox();

    //check for app updates & show prompt
    checkForUpdates().then((data) => {
          if (data != null)
            {
              showUpdateSheet(
                context,
                data.description,
                data.downloadLink,
                data.preRelease,
              ),
            }
        });

    // load the stuff
    provider.init();
  }

  AnimeStreamBottomBarController _barController = AnimeStreamBottomBarController(length: 3);

  bool popInvoked = false;
  // late bool tv;
  // bool isAndroid = Platform.isAndroid;

  late MainNavProvider mainNavProvider;

  void rebuildCards() {
    mainNavProvider.recentlyUpdatedList.clear();

    final isMobile = !mainNavProvider.tv && mainNavProvider.isAndroid;

    mainNavProvider.recentlyUpdatedListData.forEach((elem) {
      final title = elem.title['english'] ?? elem.title['romaji'] ?? '';
      mainNavProvider.recentlyUpdatedList.add(
        Cards.animeCard(
          elem.id,
          (currentUserSettings?.nativeTitle ?? false) ? elem.title['native'] ?? title : title,
          elem.cover,
          rating: (elem.rating ?? 0) / 10,
          isMobile: isMobile,
        ),
      );
    });

    mainNavProvider.recommendedList.clear();
    mainNavProvider.recommendedListData.forEach((item) {
      final title = item.title['english'] ?? item.title['romaji'] ?? '';
      mainNavProvider.recommendedList.add(Cards.animeCard(
          item.id, (currentUserSettings?.nativeTitle ?? false) ? item.title['native'] ?? title : title, item.cover,
          rating: item.rating, isMobile: isMobile));
    });

    mainNavProvider.thisSeason.clear();
    mainNavProvider.thisSeasonData.forEach((item) {
      final title = item.title['english'] ?? item.title['romaji'] ?? '';
      mainNavProvider.thisSeason.add(Cards.animeCard(
          item.id, (currentUserSettings?.nativeTitle ?? false) ? item.title['native'] ?? title : title, item.cover,
          rating: item.rating, isMobile: isMobile));
    });

    setState(() {});
  }

  //reset the popInvoke
  Future<void> popTimeoutWindow() async {
    await Future.delayed(Duration(seconds: 3));
    popInvoked = false;
  }

  @override
  Widget build(BuildContext context) {
    mainNavProvider = context.watch<MainNavProvider>();

    if (mainNavProvider.recentlyUpdatedList.isNotEmpty && mainNavProvider.thisSeason.isNotEmpty) {
      rebuildCards();
    }
    double blurSigmaValue = currentUserSettings!.navbarTranslucency ?? 5;
    if (blurSigmaValue <= 1) {
      blurSigmaValue = blurSigmaValue * 10;
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, res) async {
        if (_barController.currentIndex != 0) {
          _barController.currentIndex = 0;
          return;
        }

        //exit the app if back is pressed again within 3 sec window
        if (popInvoked) return await SystemNavigator.pop();

        floatingSnackBar("Hit back once again to exit the app");
        popInvoked = true;
        popTimeoutWindow();
      },
      child: Scaffold(
        body: MediaQuery.of(context).orientation == Orientation.landscape || Platform.isWindows
            ? Row(
                children: [
                  // AnimeStreamNavRail(
                  //   destinations: [
                  //     AnimeStreamNavDestination(icon: Icons.home, label: "Home"),
                  //     AnimeStreamNavDestination(icon: Icons.auto_awesome, label: "Discover"),
                  //     AnimeStreamNavDestination(icon: Icons.search, label: "Search"),
                  //   ],
                  //   controller: _barController,
                  //   initialIndex: 0,
                  //   shouldExpand: true,
                  // ),
                  NavigationRail(
                    onDestinationSelected: (value) {
                      _barController.currentIndex = value;
                      setState(() {});
                    },
                    backgroundColor: appTheme.backgroundColor,
                    elevation: 1,
                    indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    indicatorColor: appTheme.accentColor,
                    destinations: [
                      NavigationRailDestination(
                        icon: Icon(
                          Icons.home,
                          color: _barController.currentIndex == 0 ? appTheme.onAccent : appTheme.textMainColor,
                        ),
                        label: Text(
                          "Home",
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                      NavigationRailDestination(
                        icon: Icon(
                          Icons.auto_awesome,
                          color: _barController.currentIndex == 1 ? appTheme.onAccent : appTheme.textMainColor,
                        ),
                        label: Text(
                          "Discover",
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.search_rounded,
                            color: _barController.currentIndex == 2 ? appTheme.onAccent : appTheme.textMainColor),
                        label: Text(
                          "Search",
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                    selectedIndex: _barController.currentIndex,
                  ),
                  Expanded(
                    child: BottomBarView(
                      controller: _barController,
                      // physics: NeverScrollableScrollPhysics(),
                      children: [
                        Home(
                          mainNavProvider: mainNavProvider,
                        ),
                        Discover(
                          mainNavProvider: mainNavProvider,
                        ),
                        Search(),
                      ],
                    ),
                  ),
                ],
              )
            : _bottomBar(context, blurSigmaValue),
      ),
    );
  }

  Widget _bottomBar(BuildContext context, double blurSigmaValue) {
    return Stack(
      children: [
        BottomBarView(
          controller: _barController,
          children: [
            Home(
              key: ValueKey("0"),
              mainNavProvider: mainNavProvider,
            ),
            Discover(
              key: ValueKey("1"),
              mainNavProvider: mainNavProvider,
            ),
            Search(
              key: ValueKey("2"),
            ),
          ],
        ),
        AnimeStreamBottomBar(
          controller: _barController,
          accentColor: appTheme.accentColor,
          backgroundColor:
              appTheme.backgroundSubColor.withValues(alpha: currentUserSettings?.navbarTranslucency ?? 0.5),
          borderRadius: 10,
          items: [
            BottomBarItem(title: 'Home', icon: Icon(Icons.home)),
            BottomBarItem(title: 'Discover', icon: Icon(Icons.auto_awesome)),
            BottomBarItem(title: 'Search', icon: Icon(Icons.search)),
          ],
        )
      ],
    );
  }
}
