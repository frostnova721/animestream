import 'package:animestream/core/database/anilist/anilist.dart';
import 'package:animestream/ui/models/cards.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:animestream/ui/models/sources.dart';
import 'package:animestream/ui/pages/watch.dart';
import 'package:animestream/ui/theme/mainTheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import "package:animestream/core/data/watching.dart";
import 'package:http/http.dart';
import "package:image_gallery_saver/image_gallery_saver.dart";

class Info extends StatefulWidget {
  final int id;
  const Info({required this.id});

  @override
  State<Info> createState() => _InfoState();
}

class _InfoState extends State<Info> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ));
    getInfo(widget.id).then((value) => getEpisodes());
  }

  bool dataLoaded = false;
  bool infoPage = true;
  dynamic data;
  String selectedSouce = "gogoanime";
  String? foundName;
  List<String> epLinks = [];
  List streamSources = [];
  int watched = 1;
  bool started = false;

  Future<void> getWatched() async {
    final box = await Hive.openBox('animestream');
    final List watching = box.get('watching') ?? [];
    final item = watching.where((item) => item['id'] == widget.id).firstOrNull;
    if (item != null) {
      watched = item['watched'];
      started = true;
    }
    if (mounted)
     setState(() {});
  }

  //incase the results need to be stored!
  // Future<void> storeEpisodeLinks(List epLinks) async {
  //   final box = await Hive.openBox('animestream');
  //   if(epLinks.length != 0) {
  //     box.clear();
  //     box.put('episodes', epLinks);
  //     return box.close();
  //   }
  //   box.close();
  // }

  Future getInfo(int id) async {
    final info = await Anilist().getAnimeInfo(id);
    if (info != null || info.length != 0) {
      setState(() {
        dataLoaded = true;
        data = info;
      });
    }
  }

  Future getEpisodeSources(String epLink) async {
    streamSources = [];
    final epSrcs = await getStreams(selectedSouce, epLink);
    setState(() {
      streamSources = epSrcs;
    });
  }

  Future getEpisodes() async {
    try {
      final sr = await searchInSource(
          selectedSouce, data.title['english'] ?? data.title['romaji']);
      final links = await getAnimeEpisodes(selectedSouce, sr[0]['alias']);
      getWatched();
      setState(() {
        epLinks = links;
        foundName = sr[0]['name'];
      });
    } catch (err) {
      final sr = await searchInSource(selectedSouce, data.title['romaji']);
      final links = await getAnimeEpisodes(selectedSouce, sr[0]['alias']);
      getWatched();
      setState(() {
        epLinks = links;
        foundName = sr[0]['name'];
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Scaffold(
        backgroundColor: Colors.black,
        body: dataLoaded
            ? SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _stack(),
                    Container(
                      // width: 120,
                      margin: EdgeInsets.only(top: 30),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                            fixedSize: Size(135, 55)),
                        onPressed: () {
                          setState(() {
                            infoPage = !infoPage;
                          });
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              infoPage
                                  ? Icons.play_arrow_rounded
                                  : Icons.info_rounded,
                              color: Colors.black,
                              size: 28,
                            ),
                            Text(
                              infoPage ? "watch" : "info",
                              style: TextStyle(
                                color: Colors.black,
                                fontFamily: "Poppins",
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 45),
                      padding: EdgeInsets.only(left: 20, right: 20),
                      alignment: Alignment.center,
                      // padding: EdgeInsets.only(left: 40, right: 25),
                      child: Text(
                        data.title['english'] ?? data.title['romaji'],
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: "NunitoSans",
                          fontSize: 25,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    infoPage
                        ? _infoItems(context)
                        : Column(
                            children: [
                              Container(
                                margin: EdgeInsets.only(top: 30),
                                child: DropdownMenu(
                                  initialSelection: sources.first,
                                  dropdownMenuEntries: getSourceDropdownList(),
                                  menuHeight: 75,
                                  width: 300,
                                  textStyle: TextStyle(
                                    color: Colors.white,
                                    fontFamily: "Poppins",
                                  ),
                                  menuStyle: MenuStyle(
                                    backgroundColor: MaterialStatePropertyAll(
                                        Color.fromARGB(255, 0, 0, 0)),
                                    shape: MaterialStatePropertyAll(
                                      RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        side: BorderSide(
                                          width: 1,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  onSelected: (value) {
                                    selectedSouce = value;
                                    getEpisodes();
                                  },
                                  inputDecorationTheme: InputDecorationTheme(
                                    border: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          width: 1, color: Colors.white),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    contentPadding:
                                        EdgeInsets.only(left: 20, right: 20),
                                  ),
                                  label: Text(
                                    "source",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontFamily: "Rubik",
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ),
                              ),
                              _searchStatus(),
                              if (foundName != null) _continueButton(),
                              Container(
                                margin: EdgeInsets.only(
                                    top: 25, left: 20, right: 20),
                                padding: EdgeInsets.only(top: 15, bottom: 20),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color:
                                        const Color.fromARGB(255, 29, 29, 29)),
                                child: Column(
                                  children: [
                                    _categoryTitle("Episodes"),
                                    // Container(
                                    // height: 500,
                                    // alignment: Alignment.topCenter,
                                    foundName != null
                                        ? _episodes()
                                        : Container(
                                            width: 350,
                                            height: 100,
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                  color: themeColor),
                                            ),
                                          ),
                                    // ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              )
            : Container(),
      );
    } catch (err) {
      print(err);
      return Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'lib/assets/images/broken_heart.png',
              scale: 7.5,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 15, left: 30, right: 30),
              child: const Text(
                'oops! something went wrong',
                style: TextStyle(
                    color: Colors.white,
                    fontFamily: "NunitoSans",
                    fontSize: 25,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }
  }

  Container _continueButton() {
    return Container(
      margin: EdgeInsets.only(
        top: 25,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: themeColor),
        image: DecorationImage(
          image: data.banner.length > 1
              ? NetworkImage(data.banner)
              : NetworkImage(data.cover),
          fit: BoxFit.cover,
          opacity: 0.4,
        ),
      ),
      child: InkWell(
        customBorder:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        onTap: () async {
          showModalBottomSheet(
            showDragHandle: true,
            backgroundColor: Color(0xff121212),
            context: context,
            builder: (BuildContext context) {
              return _streamButton(0);
            },
          );
          await getEpisodeSources(epLinks[watched - 1]);
          Navigator.of(context).pop();
          showModalBottomSheet(
            showDragHandle: true,
            backgroundColor: Color.fromARGB(255, 19, 19, 19),
            context: context,
            builder: (BuildContext context) {
              return _streamButton(watched - 1);
            },
          );
        },
        child: Container(
          width: 325,
          height: 80,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${started ? 'Continue' : 'Start'} from:',
                  style: TextStyle(
                    color: themeColor,
                    fontFamily: "Rubik",
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Episode $watched',
                  style: TextStyle(
                    color: themeColor,
                    fontFamily: "Rubik",
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Container _searchStatus() {
    dynamic text =
        "searching: ${data.title['english'] ?? data.title['romaji']}";
    if (foundName != null) {
      text = "found: $foundName";
    }
    return Container(
      width: 300,
      margin: EdgeInsets.only(top: 5),
      padding: EdgeInsets.only(left: 8, right: 8),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontFamily: "NotoSans",
          fontWeight: FontWeight.bold,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  ListView _episodes() {
    return ListView.builder(
        padding: EdgeInsets.only(top: 0, bottom: 15),
        itemCount: epLinks.length,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () async {
              showModalBottomSheet(
                showDragHandle: true,
                backgroundColor: Color(0xff121212),
                context: context,
                builder: (BuildContext context) {
                  return _streamButton(0);
                },
              );
              try {
                await getEpisodeSources(epLinks[index]);
                Navigator.of(context).pop();
                showModalBottomSheet(
                  showDragHandle: true,
                  backgroundColor: Color.fromARGB(255, 19, 19, 19),
                  context: context,
                  builder: (BuildContext context) {
                    return _streamButton(index);
                  },
                );
              } catch (err) {
                Navigator.of(context).pop();
                showModalBottomSheet(
                  showDragHandle: true,
                  backgroundColor: Color.fromARGB(255, 19, 19, 19),
                  context: context,
                  builder: (BuildContext context) {
                    return Container();
                  },
                );
              }
            },
            child: Stack(
              children: [
                Container(
                  height: 120,
                  margin: EdgeInsets.only(top: 10, left: 10, right: 10),
                  padding: EdgeInsets.only(left: 10, right: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.black,
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Opacity(
                          opacity: index + 2 > watched ? 1.0 : 0.6,
                          child: Image.network(
                            data.cover,
                            width: 150,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 15,
                        ),
                        child: Text(
                          "Episode ${index + 1}",
                          style: TextStyle(
                            color: index + 2 > watched
                                ? Colors.white
                                : Color.fromARGB(155, 255, 255, 255),
                            fontFamily: "Poppins",
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (watched > index + 1)
                  Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 20, right: 25),
                        child: ImageIcon(
                          AssetImage('lib/assets/images/check.png'),
                          color: Colors.white,
                          size: 18,
                        ),
                      )),
              ],
            ),
          );
        });
  }

  Container _streamButton(int episode) {
    return Container(
      padding: EdgeInsets.only(top: 20, left: 25, right: 25, bottom: 30),
      child: streamSources.length > 0
          ? ListView.builder(
              shrinkWrap: true,
              // physics: NeverScrollableScrollPhysics(),
              itemCount: streamSources.length,
              itemBuilder: (context, i) {
                return Container(
                  margin: EdgeInsets.only(top: 15),
                  decoration: BoxDecoration(
                    color: Color.fromARGB(97, 190, 175, 255),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      await storeWatching(
                        data.title['english'] ?? data.title['romaji'],
                        data.cover,
                        widget.id,
                        episode + 1,
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Watch(
                            selectedSource: selectedSouce,
                            info: {
                              'episodeNumber': episode + 1,
                              'animeTitle':
                                  data.title['english'] ?? data.title['romaji'],
                              'streamInfo': streamSources[i]
                            },
                            episodes: epLinks,
                          ),
                        ),
                      ).then((value) => getWatched());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(68, 190, 175, 255),
                      padding: EdgeInsets.only(
                          top: 10, bottom: 10, left: 20, right: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              streamSources[i].server,
                              style: TextStyle(
                                fontFamily: "NotoSans",
                                fontSize: 17,
                                color: themeColor,
                              ),
                            ),
                            if (streamSources[i].backup)
                              Text(
                                " • backup",
                                style: TextStyle(
                                  fontFamily: "NotoSans",
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              )
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 5),
                          child: Text(
                            streamSources[i].quality,
                            style: TextStyle(
                                color: Colors.white, fontFamily: "Rubik"),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          : Container(
              height: 100,
              child: Center(
                child: CircularProgressIndicator(
                  color: themeColor,
                ),
              ),
            ),
    );
  }

  Column _infoItems(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.only(top: 50),
          child: Column(
            children: [
              _buildInfoItems(
                _infoLeft('Type'),
                _infoRight(data.type),
              ),
              _buildInfoItems(
                _infoLeft('Rating'),
                _infoRight('${data.rating ?? '??'}/10'),
              ),
              _buildInfoItems(
                _infoLeft('Episodes'),
                _infoRight('${data.episodes ?? '??'}'),
              ),
              _buildInfoItems(
                _infoLeft('Duration'),
                _infoRight('${data.duration ?? '??'}'),
              ),
              _buildInfoItems(
                _infoLeft('Studios'),
                _infoRight(data.studios.isEmpty ? '??' : data.studios[0]),
              ),
            ],
          ),
        ),
        Container(
          margin: EdgeInsets.only(top: 30),
          padding: EdgeInsets.only(left: 15, right: 15),
          child: Column(
            children: [
              _categoryTitle('Genres'),
              SizedBox(
                height: 65,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: data.genres.length,
                  itemBuilder: (context, index) {
                    return Container(
                      alignment: Alignment.center,
                      margin: EdgeInsets.all(5),
                      padding: EdgeInsets.only(left: 15, right: 15),
                      decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(25)),
                      child: Text(
                        data.genres[index],
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: EdgeInsets.only(top: 30),
          padding: EdgeInsets.only(left: 25, right: 25),
          child: Column(
            children: [
              _categoryTitle('Description'),
              Text(
                data.synopsis,
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: "NunitoSans",
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: EdgeInsets.only(top: 30),
          child: Column(
            children: [
              _categoryTitle('Characters'),
              SizedBox(
                height: 275,
                child: ListView.builder(
                  itemCount: data.characters.length,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    final character = data.characters[index];
                    return Container(
                      width: 130,
                      child: characterCard(
                        character['name'],
                        character['role'],
                        character['image'],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: EdgeInsets.only(top: 30),
          child: Column(
            children: [
              _categoryTitle('Related'),
              _buildRecAndRel(data.related, false),
            ],
          ),
        ),
        Container(
          margin: EdgeInsets.only(top: 30),
          child: Column(
            children: [
              _categoryTitle('Recommended'),
              _buildRecAndRel(data.recommended, true),
            ],
          ),
        ),
      ],
    );
  }

  Container _buildInfoItems(Widget itemLeft, Widget itemRight) {
    return Container(
      padding: EdgeInsets.only(left: 15, right: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          itemLeft,
          Container(width: 150, child: itemRight),
        ],
      ),
    );
  }

  SizedBox _buildRecAndRel(List data, bool recommended) {
    if (data.length == 0)
      return SizedBox(
        height: 275,
        child: Center(
          child: const Text(
            'Nothing to see here!',
            style: TextStyle(
              fontFamily: "NunitoSans",
              fontSize: 18,
              color: const Color.fromARGB(255, 255, 255, 255),
            ),
          ),
        ),
      );
    return SizedBox(
      height: 275,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: data.length,
        itemBuilder: (context, index) {
          final item = data[index];
          return GestureDetector(
            onTap: () {
              if (item.type.toLowerCase() != "anime") {
                return floatingSnackBar(
                    context, 'Mangas/Novels arent supported');
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Info(
                    id: item.id,
                  ),
                ),
              );
            },
            child: Container(
                width: 130,
                child: recommended
                    ? animeCard(
                        item.title['english'] ?? item.title['romaji'],
                        item.cover,
                      )
                    : characterCard(
                        item.title['english'] ?? item.title['romaji'],
                        recommended ? item.type : item.relationType,
                        item.cover,
                      )),
          );
        },
      ),
    );
  }

  Padding _categoryTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontFamily: "NatoSans",
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Padding _infoLeft(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        text,
        style: TextStyle(
            color: const Color.fromARGB(255, 141, 141, 141),
            fontSize: 17,
            fontFamily: "NatoSans",
            fontWeight: FontWeight.bold),
      ),
    );
  }

  Padding _infoRight(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        text,
        style: TextStyle(
          color: Color.fromARGB(255, 255, 255, 255),
          fontSize: 17,
          fontFamily: "NotoSans",
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.end,
      ),
    );
  }

  Stack _stack() {
    return Stack(
      children: [
        GestureDetector(
          onLongPress: () {
            final img = data.banner.length > 0 ? data.banner : data.cover;
            showModalBottomSheet(
              context: context,
              showDragHandle: true,
              backgroundColor: Color.fromARGB(255, 19, 19, 19),
              builder: (BuildContext context) {
                return Container(
                  padding: EdgeInsets.all(20),
                  child: ListView(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    children: [
                      Image.network(img),
                      Container(
                        margin: EdgeInsets.only(top: 20),
                        alignment: Alignment.center,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            final res = await get(Uri.parse(img));
                            await ImageGallerySaver.saveImage(
                              res.bodyBytes,
                              quality: 100,
                              name:
                                  data.title['english'] ?? data.title['romaji'],
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            fixedSize: Size(150, 75),
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(color: themeColor),
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: Text(
                            "save",
                            style: TextStyle(
                                color: themeColor,
                                fontFamily: "Poppins",
                                fontWeight: FontWeight.bold,
                                fontSize: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                    color: Colors.black,
                    blurRadius: 20,
                    offset: Offset(10, 10),
                    spreadRadius: 10)
              ],
              color: Color.fromARGB(255, 0, 0, 0),
              image: DecorationImage(
                opacity: 0.5,
                image: data.banner.length > 0
                    ? NetworkImage(data.banner)
                    : NetworkImage(data.cover),
                fit: BoxFit.cover,
              ),
            ),
            height: 250,
          ),
        ),
        Container(
          height: 100,
          margin: EdgeInsets.only(top: 190),
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 0, 0, 0),
                  Color.fromARGB(0, 0, 0, 0)
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                stops: [0.35, 0.8]),
          ),
        ),
        Container(
          alignment: Alignment.center,
          margin: EdgeInsets.only(top: 100),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.network(
              data.cover,
              height: 220,
            ),
          ),
        ),
      ],
    );
  }
}
