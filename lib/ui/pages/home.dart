import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/types.dart';
import 'package:animestream/core/data/watching.dart';
import 'package:animestream/core/database/anilist/types.dart';
import 'package:animestream/ui/models/cards.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:animestream/ui/pages/lists.dart';
import 'package:animestream/ui/pages/settingPages/common.dart';
import 'package:animestream/ui/pages/settings.dart';
import 'package:animestream/ui/theme/mainTheme.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  final List<HomePageList> recentlyWatched;
  final List<HomePageList> currentlyAiring;
  final bool dataLoaded;
  final bool error;
  final void Function(List<HomePageList> recentlyWatched) updateWatchedList;

  const Home({
    super.key,
    required this.currentlyAiring,
    required this.recentlyWatched,
    required this.dataLoaded,
    required this.error,
    required this.updateWatchedList,
  });

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    super.initState();
  }

  UserModal? userProfile;

  List<HomePageList> recentlyWatched = [];
  // List<HomePageList> currentlyAiring = [];

  bool refreshing = false;

  Future<void> getLists({String? userName}) async {
    try {
      setState(() {
        refreshing = true;
      });
      List<UserAnimeListItem> watched = await getWatchedList(userName: userName);
      if (watched.length > 40) watched = watched.sublist(0, 40);
      recentlyWatched = [];
      watched.forEach(
        (item) => recentlyWatched.add(
          HomePageList(
            coverImage: item.coverImage,
            id: item.id,
            rating: item.rating,
            title: item.title,
            totalEpisodes: item.episodes,
            watchedEpisodeCount: item.watchProgress,
          ),
        ),
      );

      widget.updateWatchedList(recentlyWatched);

      widget.recentlyWatched.forEach((i) => print(i.title['english']));

      // final List<CurrentlyAiringResult> currentlyAiringResponse = await Anilist().getCurrentlyAiringAnime();
      // if (currentlyAiringResponse.length == 0) return;

      // currentlyAiring = [];
      // currentlyAiringResponse.sublist(0, 20).forEach((item) => currentlyAiring
      //     .add(HomePageList(coverImage: item.cover, id: item.id, rating: item.rating, title: item.title)));
      // ;

      if (mounted)
        setState(() {
          refreshing = false;
        });
    } catch (err) {
      print(err);
      if (currentUserSettings!.showErrors != null && currentUserSettings!.showErrors!)
        floatingSnackBar(context, err.toString());
      if (mounted)
        setState(() {
          refreshing = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: pagePadding(context),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Home",
                      style: TextStyle(
                        color: textMainColor,
                        fontFamily: "Rubik",
                        fontWeight: FontWeight.bold,
                        fontSize: 30,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => SettingsPage(),
                        ),
                      ),
                      icon: Icon(
                        Icons.settings_rounded,
                        color: textMainColor,
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ),
              if (storedUserData != null)
                Container(
                  margin: EdgeInsets.only(left: 20, bottom: 20, right: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _accountCard(),
                      _listButton(),
                    ],
                  ),
                ),
              _titleAndList("Continue Watching", widget.recentlyWatched, showRefreshIndication: refreshing),
              divider(),
              _titleAndList("Aired This Season", widget.currentlyAiring),
              footSpace(),
            ],
          ),
        ),
      ),
    );
  }

  SizedBox footSpace() {
    return SizedBox(
      height: MediaQuery.of(context).padding.bottom + 60,
    );
  }

  Container _listButton() {
    return Container(
      height: 60,
      width: 140,
      margin: EdgeInsets.only(left: 10),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundSubColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => AnimeLists())).then((val) => getLists(userName: userProfile?.name)),
        child: Container(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.folder_rounded,
                color: textMainColor,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Text(
                  "Lists",
                  style: TextStyle(
                    color: textMainColor,
                    fontFamily: "Poppins",
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Container _accountCard() {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: backgroundSubColor),
      width: 200,
      height: 60,
      padding: EdgeInsets.all(10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(storedUserData!.avatar!),
          ),
          Padding(
            padding: EdgeInsets.only(left: 10),
            child: Text(
              storedUserData!.name,
              style: TextStyle(
                fontFamily: "Poppins",
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Center divider() {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width / 2,
        margin: EdgeInsets.only(top: 20, bottom: 20),
        height: 6,
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.6),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Column _titleAndList(String title, List<HomePageList> list, {bool showRefreshIndication = false}) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              alignment: Alignment.centerLeft,
              // margin: EdgeInsets.only(top: 20),
              padding: EdgeInsets.only(left: 15, right: 15),
              child: Text(
                title,
                style: TextStyle(fontFamily: "Rubik", fontSize: 20),
              ),
            ),
            if (showRefreshIndication)
              Container(
                margin: EdgeInsets.only(left: 5),
                height: 15,
                width: 15,
                child: CircularProgressIndicator(
                  color: accentColor,
                ),
              ),
          ],
        ),
        Container(
          height: 160,
          child: widget.dataLoaded
              ? list.length > 0
                  ? ListView.builder(
                      padding: EdgeInsets.zero,
                      scrollDirection: Axis.horizontal,
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final item = list[index];
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Cards(context: context).animeCardExtended(item.id,
                              item.title['english'] ?? item.title['romaji'] ?? '', item.coverImage, item.rating ?? 0.0,
                              bannerImageUrl: item.coverImage,
                              watchedEpisodeCount: item.watchedEpisodeCount,
                              totalEpisodes: item.totalEpisodes,
                              afterNavigation: () => getLists(userName: storedUserData?.name)),
                        );
                      })
                  : Center(
                      child: Container(
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              "lib/assets/images/ghost.png",
                              color: Color.fromARGB(255, 80, 80, 80),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 10.0),
                              child: Text(
                                "Boo! Nothing's here!",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: "NunitoSans",
                                  fontWeight: FontWeight.w500,
                                  color: Color.fromARGB(255, 80, 80, 80),
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
              : Center(
                  child: CircularProgressIndicator(),
                ),
        )
      ],
    );
  }
}
