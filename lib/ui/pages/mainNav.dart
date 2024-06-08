import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/database/anilist/login.dart';
import 'package:animestream/core/database/anilist/types.dart';
import 'package:animestream/ui/models/cards.dart';
import 'package:animestream/ui/pages/discover.dart';
import 'package:animestream/ui/pages/lists.dart';
import 'package:animestream/ui/pages/newHome.dart';
import 'package:animestream/ui/pages/search.dart';
import 'package:animestream/ui/pages/settingPages/common.dart';
import 'package:animestream/ui/theme/mainTheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => MainNavigatorState();
}

class MainNavigatorState extends State<MainNavigator> with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();

    AniListLogin().isAnilistLoggedIn().then((loggedIn) {
      if (loggedIn)
        AniListLogin().getUserProfile().then((user) => {
              userProfile = user,
              storedUserData = user,
              print(storedUserData?.name),
            });
    });

    tabController = TabController(length: 4, vsync: this);
  }

  UserModal? userProfile;

  late TabController tabController;

  double iconSize = 30;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BottomBar(
        barColor: backgroundSubColor,
        borderRadius: BorderRadius.circular(10),
        fit: StackFit.passthrough,
        barAlignment: Alignment.bottomCenter,
        offset: MediaQuery.of(context).padding.bottom + 10,
        child: Container(
          padding: EdgeInsets.only(top: 5),
          child: TabBar(
            onTap: (val) => setState(() {}),
            overlayColor: WidgetStateColor.transparent,
            controller: tabController,
            isScrollable: false,
            labelColor: accentColor,
            unselectedLabelColor: textSubColor,
            dividerHeight: 0,
            indicatorColor: accentColor,
            labelPadding: EdgeInsets.only(bottom: 5),
            tabs: [
              TabIcon(icon: Icons.home_rounded, label: "Home", animate: tabController.index == 0,),
              TabIcon(icon: null, label: "Discover", animate: tabController.index == 1, image: true),
              TabIcon(icon: Icons.search_rounded, label: 'Search', animate: tabController.index == 2),
              TabIcon(icon: Icons.featured_play_list_rounded, label: "Lists", animate: tabController.index == 3)
            ],
          ),
        ),
        body: (context, scrollController) => TabBarView(
          controller: tabController,
          physics: NeverScrollableScrollPhysics(),
          children: [
            NewHome(),
            SingleChildScrollView(child: Discover(currentSeason: [])),
            Search(searchedText: ""),
            AnimeLists(),
          ],
        ),
      ),
    );
  }
}

class TabIcon extends StatefulWidget {
  final IconData? icon; final String label; final bool animate; final bool image;
  const TabIcon({super.key, required this.icon, this.image = false, required this.label, required this.animate});

  @override
  State<TabIcon> createState() => _TabIconState();
}

class _TabIconState extends State<TabIcon>  {

  @override
  void initState() {
    super.initState();
  }

  final double iconSize = 30;

  @override
  Widget build(BuildContext context) {
    if(widget.image == false && widget.icon == null) throw Exception("DIDNT RECIEVE 'IconData'"); 
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 300),
      child: widget.animate
          ? Text(widget.label, style: TextStyle(fontFamily: "NotoSans", fontWeight: FontWeight.w600, fontSize: 14),)
          : widget.image ? ImageIcon(
                AssetImage("lib/assets/images/shines.png"),
                size: iconSize - 4,
              ) : Icon(
              widget.icon,
              size: iconSize,
            ),
    );
  }
}
