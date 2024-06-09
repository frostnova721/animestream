import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/types.dart';
import 'package:animestream/core/data/watching.dart';
import 'package:animestream/core/database/anilist/anilist.dart';
import 'package:animestream/core/database/anilist/types.dart';
import 'package:animestream/ui/models/cards.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:animestream/ui/pages/settingPages/common.dart';
import 'package:animestream/ui/pages/settings.dart';
import 'package:animestream/ui/theme/mainTheme.dart';
import 'package:flutter/material.dart';

class NewHome extends StatefulWidget {
  final UserModal? user;

  const NewHome({
    super.key,
    required this.user,
  });

  @override
  State<NewHome> createState() => _NewHomeState();
}

class _NewHomeState extends State<NewHome> {
  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      userProfile = widget.user;
      getLists(userName: userProfile!.name);
    } else {
      getLists();
    }
  }

  bool error = false;
  bool dataLoaded = false;

  UserModal? userProfile;

  List<HomePageList> recentlyWatched = [];
  List<HomePageList> currentlyAiring = [];

  Future<void> getLists({String? userName}) async {
    try {
      List<UserAnimeListItem> watched = await getWatchedList(userName: userName);
      if (watched.length > 40) watched = watched.sublist(0, 40);
      recentlyWatched = [];
      watched.forEach((item) => recentlyWatched
          .add(HomePageList(coverImage: item.coverImage, id: item.id, rating: item.rating, title: item.title)));

      final List<CurrentlyAiringResult> currentlyAiringResponse = await Anilist().getCurrentlyAiringAnime();
      if (currentlyAiringResponse.length == 0) return;

      currentlyAiring = [];
      currentlyAiringResponse.sublist(0, 20).forEach((item) => currentlyAiring
          .add(HomePageList(coverImage: item.cover, id: item.id, rating: item.rating, title: item.title)));
      ;
      if (mounted)
        setState(() {
          dataLoaded = true;
        });
    } catch (err) {
      print(err);
      if (currentUserSettings!.showErrors != null && currentUserSettings!.showErrors!)
        floatingSnackBar(context, err.toString());
      if (mounted)
        setState(() {
          error = true;
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
              if (userProfile != null) _accountCard(),
              _titleAndList("Continue Watching", recentlyWatched),
              divider(),
              _titleAndList("Aired This Season", currentlyAiring),
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

  Container _accountCard() {
    return Container(
      margin: EdgeInsets.only(left: 20, bottom: 20),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: backgroundSubColor),
      width: 200,
      padding: EdgeInsets.all(10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(userProfile!.avatar!),
          ),
          Padding(
            padding: EdgeInsets.only(left: 10),
            child: Text(
              userProfile!.name,
              style: TextStyle(
                fontFamily: "Poppins",
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
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

  Column _titleAndList(String title, List<HomePageList> list) {
    return Column(
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
        Container(
          height: 160,
          child: dataLoaded
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
                          bannerImageUrl: item.coverImage),
                    );
                  })
              : Center(
                  child: CircularProgressIndicator(),
                ),
        )
      ],
    );
  }
}
