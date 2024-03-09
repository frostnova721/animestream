import 'package:animestream/core/app/update.dart';
import 'package:animestream/core/database/anilist/anilist.dart';
import 'package:animestream/ui/models/cards.dart';
import 'package:animestream/ui/models/drawer.dart';
import 'package:animestream/ui/pages/Discover.dart';
import 'package:animestream/ui/pages/info.dart';
import 'package:animestream/ui/pages/search.dart';
import 'package:animestream/ui/pages/settings.dart';
import 'package:animestream/ui/theme/mainTheme.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    super.initState();

    getLists();
    checkForUpdates().then((value) {
      if(value != null) {
        showUpdateSheet(context, value.description, value.downloadLink, value.preRelease);
      }
    },);
  }

  int activeIndex = 0;

  TextEditingController textEditingController = TextEditingController();

  List<ListElement> recentlyWatched = [];
  List<ListElement> currentlyAiring = [];

  bool dataLoaded = false;
  bool error = false;

  onItemTapped(int index) {
    if (mounted)
      setState(() {
        activeIndex = index;
      });
  }

  Future<void> getLists() async {
    try {
      final box = await Hive.openBox('animestream');
      List watching = box.get('watching') ?? [];
      recentlyWatched = [];
      if (watching.length != 0) {
        if (watching.length > 20) watching = watching.sublist(0, 20);
        watching.reversed.toList().forEach((e) {
          recentlyWatched.add(ListElement(
              widget: animeCard(e['title'], e['imageUrl']), info: e));
        });
      }
      box.close();

      final List currentlyAiringResponse =
          await Anilist().getCurrentlyAiringAnime();
      if (currentlyAiringResponse.length == 0) return;

      currentlyAiring = [];
      currentlyAiringResponse.sublist(0, 20).forEach((e) {
        final title = e['title']['english'] ?? e['title']['romaji'];
        final image = e['coverImage']['large'] ?? e['coverImage']['extraLarge'];
        currentlyAiring
            .add(ListElement(widget: animeCard(title, image), info: e));
      });
      if (mounted)
        setState(() {
          dataLoaded = true;
        });
    } catch (err) {
      print(err);
      if (mounted)
        setState(() {
          error = true;
        });
    }
  }

  final GlobalKey<ScaffoldState> _globalKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _globalKey,
      backgroundColor: backgroundColor,
      drawer: HomeDrawer(
        onItemTapped: onItemTapped,
        activeIndex: activeIndex,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, bottom: MediaQuery.of(context).padding.bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    // width: MediaQuery.of(context).size.width - 100,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                _globalKey.currentState!.openDrawer();
                              },
                              icon: Icon(
                                Icons.menu_rounded,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: Text(
                                "AnimeStream",
                                style: TextStyle(
                                  color: textMainColor,
                                  fontSize: 23,
                                  fontFamily: 'NunitoSans',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.only(left: 10, right: 0, top: 10),
                          width: 300,
                          child: TextField(
                            controller: textEditingController,
                            autocorrect: false,
                            maxLines: 1,
                            onSubmitted: (String input) {
                              textEditingController.value =
                                  TextEditingValue.empty;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      Search(searchedText: input),
                                ),
                              );
                            },
                            cursorColor: accentColor,
                            decoration: InputDecoration(
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(left: 5),
                                child: Image.asset(
                                  "lib/assets/images/search.png",
                                  color: Colors.white,
                                  scale: 1.75,
                                ),
                              ),
                              hintText: "Search...",
                              hintStyle: TextStyle(
                                color: const Color.fromARGB(255, 129, 129, 129),
                                fontFamily: "Poppins",
                                fontSize: 16,
                              ),
                              focusColor: accentColor,
                              contentPadding: EdgeInsets.only(
                                  top: 5, bottom: 5, left: 20, right: 20),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: accentColor,
                                ),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            style: TextStyle(
                              backgroundColor: backgroundColor,
                              color: textMainColor,
                              fontFamily: 'Poppins',
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.only(right: 15),
                    child: IconButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsPage(),));
                      },
                      icon: Icon(
                        Icons.settings,
                        color: textMainColor,
                        size: 45,
                      ),
                    ),
                    // padding: EdgeInsets.only(right: 25),
                    // child: CircleAvatar(
                    //   radius: 25,
                    //   backgroundColor: ,
                    // ),
                  )
                ],
              ),
              activeIndex == 0
                  ? _homeItems()
                  : Discover(currentSeason: currentlyAiring),
            ],
          ),
        ),
      ),
    );
  }

  Column _homeItems() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(top: 40, left: 20, right: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Recently Watched",
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: textMainColor,
                  fontFamily: "Rubik",
                  fontSize: 20,
                ),
              ),
              dataLoaded
                  ? _cardListMaker(recentlyWatched)
                  : Container(
                      height: 250,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: accentColor,
                        ),
                      ),
                    ),
            ],
          ),
        ),
        Container(
          margin: EdgeInsets.only(left: 30, right: 30, top: 10, bottom: 10),
          height: 5,
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.4),
            borderRadius: BorderRadius.circular(
              50,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(top: 10, left: 20, right: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Currently Airing",
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: textMainColor,
                  fontFamily: "Rubik",
                  fontSize: 20,
                ),
              ),
              dataLoaded
                  ? _cardListMaker(currentlyAiring)
                  : Container(
                      height: 250,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: accentColor,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Column _cardListMaker(List<ListElement> widgetList) {
    return Column(
      children: [
        widgetList.length > 0
            ? Container(
                padding: const EdgeInsets.only(top: 15),
                height: 250,
                child: ListView.builder(
                  itemCount: widgetList.length,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    return Container(
                      alignment: Alignment.centerLeft,
                      width: 120,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  Info(id: widgetList[index].info['id']),
                            ),
                          ).then(
                            (value) {
                              if (mounted)
                                setState(() {
                                  getLists();
                                });
                            },
                          );
                        },
                        child: widgetList[index].widget,
                      ),
                    );
                  },
                ),
              )
            : Center(
                child: Container(
                  height: 250,
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
              ),
      ],
    );
  }
}
