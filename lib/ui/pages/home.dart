import 'package:animestream/core/database/anilist/anilist.dart';
import 'package:animestream/ui/models/cards.dart';
import 'package:animestream/ui/pages/Discover.dart';
import 'package:animestream/ui/pages/search.dart';
import 'package:animestream/ui/pages/info.dart';
import 'package:animestream/ui/theme/mainTheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter/services.dart';
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
    error = false;
    getLists();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  List<ListElement> recentlyWatched = [];
  List<ListElement> currentlyAiring = [];
  bool dataLoaded = false;
  bool error = false;
  int activeIndex = 0;
  // TabController tabController =;

  Future getLists() async {
    // currentlyAiring = [];
    // recentlyWatched = [];

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

      // print(recentlyWatched[0].widget);

      final List currentlyAiringResponse =
          await Anilist().getCurrentlyAiringAnime();
      if (currentlyAiringResponse.length == 0) return;

      currentlyAiring = [];
      currentlyAiringResponse.forEach((e) {
        final title = e['title']['english'] ?? e['title']['romaji'];
        final image = e['coverImage']['large'] ?? e['coverImage']['extraLarge'];
        // final id = e['id'];
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

  Widget getPage(context) {
    switch (activeIndex) {
      case 0:
        return _homePage(context);
      case 1:
        return Discover(currentSeason: currentlyAiring,);
      default:
        return _homePage(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        body: SingleChildScrollView(child: getPage(context)),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
          ),
          width: 150,
          height: 50,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: Theme(
              data: ThemeData(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  hoverColor: Colors.transparent),
              child: BottomNavigationBar(
                selectedItemColor: themeColor,
                unselectedItemColor: Colors.white,
                currentIndex: activeIndex,
                backgroundColor: Color.fromARGB(22, 255, 255, 255),
                elevation: 0,
                onTap: (val) => setState(() {
                  activeIndex = val;
                }),
                selectedLabelStyle: TextStyle(fontSize: 0),
                items: [
                  BottomNavigationBarItem(
                      label: "",
                      icon: Icon(Icons.home_rounded),
                      tooltip: "home"),
                  BottomNavigationBarItem(
                      label: "",
                      icon: Image.asset(
                        'lib/assets/images/shines.png',
                        color: activeIndex == 1 ? themeColor : Colors.white,
                        scale: 25,
                      ),
                      tooltip: "discover"),
                ],
              ),
            ),
          ),
        ));
  }

  Column _homePage(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 50,
        ),
        Row(
          children: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Search(),
                  ),
                ).then((value) => setState(() {
                      getLists();
                    }));
              },
              iconSize: 40,
              tooltip: "Discover",
              icon: Image.asset(
                "lib/assets/images/search.png",
                color: Colors.white,
                scale: 1.5,
              ),
            ),
          ],
        ),
        Column(
          children: [
            Container(
              padding: const EdgeInsets.only(
                  left: 15, right: 10, top: 40, bottom: 10),
              alignment: Alignment.topLeft,
              child: const Text(
                'Recently Watched',
                style: TextStyle(
                  fontSize: 22,
                  fontFamily: "Rubik",
                  color: Colors.white,
                ),
              ),
            ),
            error
                ? _errorText()
                : dataLoaded
                    ? _cardListMaker(recentlyWatched)
                    : Container(
                        height: 280,
                        child: Center(
                          child: SpinKitThreeBounce(
                            color: themeColor,
                            size: 30,
                          ),
                        ),
                      ),
            Container(
              padding: const EdgeInsets.only(left: 15, right: 10, bottom: 10),
              alignment: Alignment.topLeft,
              child: const Text(
                'Currently Airing',
                style: TextStyle(
                  fontSize: 22,
                  fontFamily: "Rubik",
                  color: Colors.white,
                ),
              ),
            ),
            error
                ? _errorText()
                : dataLoaded
                    ? _cardListMaker(currentlyAiring.sublist(0, 20))
                    : Container(
                        height: 280,
                        child: Center(
                          child: SpinKitThreeBounce(
                            color: themeColor,
                            size: 30,
                          ),
                        ),
                      ),
          ],
        )
      ],
    );
  }

  Container _errorText() {
    return Container(
      height: 280,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'lib/assets/images/broken_heart.png',
            scale: 7.5,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 15),
            child: Text(
              "Had some issues loading the list!",
              style: TextStyle(
                color: Color(0xfff92b60),
                fontFamily: "NunitoSans",
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Column _cardListMaker(List<ListElement> widgetList) {
    return Column(
      children: [
        widgetList.length > 0
            ? Container(
                padding: const EdgeInsets.only(left: 15, right: 15, top: 15),
                height: 255,
                child: ListView.builder(
                  itemCount: widgetList.length,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    return Container(
                      alignment: Alignment.centerLeft,
                      width: 125,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  Info(id: widgetList[index].info['id']),
                            ),
                          ).then((value) => setState(() {
                                getLists();
                              }));
                        },
                        child: widgetList[index].widget,
                      ),
                    );
                  },
                ),
              )
            : Container(
                height: 280,
                padding: EdgeInsets.only(top: 125),
                child: Text(
                  "Nothing to see here!",
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
    );
  }
}
