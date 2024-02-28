import 'package:animestream/core/database/anilist/anilist.dart';
import 'package:animestream/ui/models/cards.dart';
import 'package:animestream/ui/models/drawer.dart';
import 'package:animestream/ui/pages/info.dart';
import 'package:animestream/ui/theme/mainTheme.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class Home2 extends StatefulWidget {
  const Home2({super.key});

  @override
  State<Home2> createState() => _Home2State();
}

class _Home2State extends State<Home2> {
  @override
  void initState() {
    super.initState();

    getLists();
  }

  int activeIndex = 0;

  List<ListElement> recentlyWatched = [];
  List<ListElement> currentlyAiring = [];

  bool dataLoaded = false;
  bool error = false;

  Future<void> getLists() async {
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

      final List currentlyAiringResponse =
          await Anilist().getCurrentlyAiringAnime();
      if (currentlyAiringResponse.length == 0) return;

      currentlyAiring = [];
      currentlyAiringResponse.forEach((e) {
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
      drawer: HomeDrawer(),
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      // floatingActionButton: Container(
      //   width: 200,
      //   decoration: BoxDecoration(borderRadius: BorderRadius.circular(40)),
      //   clipBehavior: Clip.hardEdge,
      //   child: BottomNavigationBar(
      //     selectedItemColor: themeColor,
      //     unselectedItemColor: Colors.white,
      //     currentIndex: activeIndex,
      //     selectedLabelStyle: TextStyle(fontSize: 0),
      //     onTap: (index) {
      //       setState(() {
      //         activeIndex = index;
      //       });
      //     },
      //     backgroundColor: Color.fromARGB(164, 56, 56, 56),
      //     items: [
      //       BottomNavigationBarItem(
      //         label: "",
      //         icon: Icon(
      //           Icons.home,
      //           size: 30,
      //           // color: Colors.white,
      //         ),
      //       ),
      //       BottomNavigationBarItem(
      //           icon: Image.asset(
      //             "lib/assets/images/shines.png",
      //             scale: 20,
      //             color: activeIndex == 1 ? themeColor : Colors.white,
      //           ),
      //           label: ""),
      //     ],
      //   ),
      // ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          child: Column(
            children: [
              // Container(
              //   height: 0,
              // ),
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
                        color: textColor,
                        fontSize: 23,
                        fontFamily: 'NunitoSans',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.only(left: 30, right: 30, top: 10),
                child: TextField(
                  autocorrect: false,
                  maxLines: 1,
                  onSubmitted: (String input) {},
                  cursorColor: themeColor,
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
                    focusColor: themeColor,
                    contentPadding:
                        EdgeInsets.only(top: 5, bottom: 5, left: 20, right: 20),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: themeColor,
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
                    color: textColor,
                    fontFamily: 'Poppins',
                    fontSize: 16,
                  ),
                ),
              ),
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
                        color: textColor,
                        fontFamily: "Rubik",
                        fontSize: 20,
                      ),
                    ),
                    _cardListMaker(currentlyAiring)
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.only(left: 30, right: 30, top: 10, bottom: 10),
                height: 5,
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.4),
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
                        color: textColor,
                        fontFamily: "Rubik",
                        fontSize: 20,
                      ),
                    ),
                    _cardListMaker(currentlyAiring)
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
            : Center(
                child: Container(
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
              ),
      ],
    );
  }
}
