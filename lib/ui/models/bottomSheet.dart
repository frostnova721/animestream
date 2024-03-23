import 'package:animestream/core/anime/downloader/downloader.dart';
import 'package:animestream/core/commons/extractQuality.dart';
import 'package:animestream/core/commons/types.dart';
import 'package:animestream/core/data/watching.dart';
import 'package:animestream/core/database/anilist/mutations.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:animestream/ui/pages/watch.dart';
import 'package:animestream/ui/theme/mainTheme.dart';
import 'package:flutter/material.dart';

class BottomSheetContent extends StatefulWidget {
  final Function(
          String selectedSource, String epLink, Function(List<dynamic>, bool))
      getStreams;
  final BottomSheetContentData bottomSheetContentData;
  final Type type;
  final Function? getWatched;
  const BottomSheetContent({
    super.key,
    required this.getStreams,
    required this.bottomSheetContentData,
    required this.type,
    this.getWatched,
  });

  @override
  State<BottomSheetContent> createState() => BottomSheetContentState();
}

class BottomSheetContentState extends State<BottomSheetContent> {
  List streamSources = [];
  List qualities = [];

  getStreams() async {
    streamSources = [];
    await widget.getStreams(
        widget.bottomSheetContentData.selectedSource,
        widget.bottomSheetContentData
            .epLinks[widget.bottomSheetContentData.episodeIndex],
        (list, finished) {
      // streamSources.add(list);
      if (mounted)
        setState(() {
          if (finished) _isLoading = false;
          streamSources = streamSources + list;
          if (widget.type == Type.download)
            list.forEach((element) {
              getQualities(element.link, element.server, element.backup);
            });
          // streamSources = streamSources.expand((element) => element).toList();
          // print(streamSources);
        });
    });
  }

  Future<void> getQualities(String link, String server, bool backup) async {
    List<dynamic> mainList = [];
    final List<dynamic> list = await getQualityStreams(link);
    list.forEach((element) {
      element['server'] = "${server} ${backup ? "• backup" : ""}";
      mainList.add(element);
    });
    if (mounted)
      setState(() {
        qualities = qualities + mainList;
      });
  }

  @override
  void initState() {
    super.initState();
    getStreams();
  }

  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 30),
      width: double.infinity,
      child: _isLoading
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _list(),
                Container(
                  padding: EdgeInsets.only(bottom: 30),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: accentColor,
                    ),
                  ),
                )
              ],
            )
          : _list(),
    );
  }

  ListView _list() {
    return widget.type == Type.watch
        ? ListView.builder(
            shrinkWrap: true,
            itemCount: streamSources.length,
            itemBuilder: (context, index) {
              return Container(
                margin: EdgeInsets.only(top: 15),
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 37, 34, 49),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ElevatedButton(
                  onPressed: () async {
                    await storeWatching(
                      widget.bottomSheetContentData.title,
                      widget.bottomSheetContentData.cover,
                      widget.bottomSheetContentData.id,
                      widget.bottomSheetContentData.episodeIndex + 1,
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Watch(
                          selectedSource:
                              widget.bottomSheetContentData.selectedSource,
                          info: WatchPageInfo(
                              animeTitle: widget.bottomSheetContentData.title,
                              episodeNumber:
                                  widget.bottomSheetContentData.episodeIndex +
                                      1,
                              streamInfo: streamSources[index],
                              id: widget.bottomSheetContentData.id),
                          episodes: widget.bottomSheetContentData.epLinks,
                        ),
                      ),
                    ).then((value) => widget.getWatched!());
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
                            streamSources[index].server,
                            style: TextStyle(
                              fontFamily: "NotoSans",
                              fontSize: 17,
                              color: accentColor,
                            ),
                          ),
                          if (streamSources[index].backup)
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
                          streamSources[index].quality,
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
        : ListView.builder(
            itemCount: qualities.length,
            shrinkWrap: true,
            itemBuilder: (BuildContext context, ind) => Container(
              margin: EdgeInsets.only(top: 15),
              decoration: BoxDecoration(
                color: Color.fromARGB(97, 190, 175, 255),
                borderRadius: BorderRadius.circular(20),
              ),
              child: ElevatedButton(
                onPressed: () async {
                  Downloader().download(qualities[ind]['link'],
                      "${widget.bottomSheetContentData.title}_Ep_${widget.bottomSheetContentData.episodeIndex + 1}");
                  floatingSnackBar(context,
                      "Downloading the episode to your downloads folder");
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(68, 190, 175, 255),
                  padding:
                      EdgeInsets.only(top: 10, bottom: 10, left: 20, right: 20),
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
                          Padding(
                            padding: EdgeInsets.only(top: 5),
                            child: Text(
                              "${qualities[ind]['server']} • ${qualities[ind]['quality']}p",
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 18,
                                fontFamily: "Rubik",
                              ),
                            ),
                          ),
                        ],
                      ),
                    ]),
              ),
            ),
          );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

//long name lol
class MediaListStatusBottomSheet extends StatefulWidget {
  final String? status;
  final int id;
  final Function(String, int) refreshListStatus;
  final int totalEpisodes;
  final int episodesWatched;

  const MediaListStatusBottomSheet({
    super.key,
    required this.status,
    required this.id,
    required this.refreshListStatus,
    required this.totalEpisodes,
    required this.episodesWatched,
  });

  @override
  State<MediaListStatusBottomSheet> createState() =>
      _MediaListStatusBottomSheetState();
}

class _MediaListStatusBottomSheetState
    extends State<MediaListStatusBottomSheet> {
  @override
  void initState() {
    super.initState();
    itemList = makeItemList();
    textEditingController.value =
        TextEditingValue(text: "${widget.episodesWatched}");
  }

  final List<String> statuses = ["PLANNING", "CURRENT", "DROPPED", "COMPLETED"];

  List<DropdownMenuEntry> itemList = [];
  String? initialSelection;

  MediaStatus assignItemEnum(String valueInString) {
    switch (valueInString) {
      case "CURRENT":
        return MediaStatus.CURRENT;
      case "PLANNING":
        return MediaStatus.PLANNING;
      case "DROPPED":
        return MediaStatus.DROPPED;
      case "COMPLETED":
        return MediaStatus.COMPLETED;
      default:
        throw new Exception("ERR_BAD_STRING");
    }
  }

  List<DropdownMenuEntry> makeItemList() {
    final List<DropdownMenuEntry> itemList = [];
    statuses.forEach((element) {
      itemList.add(
        DropdownMenuEntry(
          value: element,
          label: element,
          style: ButtonStyle(
            foregroundColor: MaterialStatePropertyAll(Colors.white),
            textStyle: MaterialStatePropertyAll(
              TextStyle(
                color: Colors.white,
                fontFamily: "Rubik",
                fontSize: 16,
              ),
            ),
          ),
        ),
      );
    });
    return itemList;
  }

  String getInitialSelection() {
    if (widget.status == null) {
      initialSelection = itemList[0].value;
      return itemList[0].value;
    } else {
      initialSelection = widget.status!;
      selectedValue = initialSelection;
      return widget.status!;
    }
  }

  String? selectedValue;

  TextEditingController textEditingController = TextEditingController();
  TextEditingController menuController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom, left: 20, right: 20),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              DropdownMenu(
                controller: menuController,
                onSelected: (value) => {
                  if (value != initialSelection) selectedValue = value,
                },
                menuStyle: MenuStyle(
                  backgroundColor: MaterialStatePropertyAll(backgroundColor),
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
                textStyle: TextStyle(
                  color: Colors.white,
                  fontFamily: "Poppins",
                ),
                inputDecorationTheme: InputDecorationTheme(
                  border: OutlineInputBorder(
                    borderSide: BorderSide(width: 1, color: Colors.white),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: EdgeInsets.only(left: 20, right: 20),
                ),
                width: 300,
                label: Text(
                  "status",
                  style: TextStyle(color: textMainColor, fontFamily: "Poppins"),
                ),
                initialSelection: getInitialSelection(),
                dropdownMenuEntries: itemList,
              ),
              Container(
                padding: EdgeInsets.only(top: 20, bottom: 20),
                child: Text(
                  "Progress",
                  style: TextStyle(
                    color: textMainColor,
                    fontFamily: "Rubik",
                    fontSize: 22,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      final currentNumber = int.parse(
                          textEditingController.value.text.isEmpty
                              ? "0"
                              : textEditingController.value.text);
                      if (currentNumber < 1) return;
                      textEditingController.value =
                          TextEditingValue(text: "${currentNumber - 1}");
                    },
                    icon: Icon(
                      Icons.remove_circle_outline_rounded,
                      color: textMainColor,
                      size: 35,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.only(right: 10),
                        height: 50,
                        width: 100,
                        child: TextField(
                          controller: textEditingController,
                          onChanged: (value) => {
                            if (value.isNotEmpty &&
                                int.parse(value) > widget.totalEpisodes)
                              {
                                textEditingController.value = TextEditingValue(
                                  text: "${widget.totalEpisodes}",
                                ),
                              }
                          },
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.end,
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.only(
                                top: 5, bottom: 5, left: 10, right: 10),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: textMainColor,
                              ),
                            ),
                          ),
                          style: TextStyle(
                            color: textMainColor,
                            fontFamily: "Rubik",
                            fontSize: 20,
                          ),
                          autocorrect: false,
                        ),
                      ),
                      Text(
                        "/ ${widget.totalEpisodes}",
                        style: TextStyle(
                          color: textMainColor,
                          fontFamily: "Rubik",
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {
                      final currentNumber = int.parse(
                          textEditingController.value.text.isEmpty
                              ? "0"
                              : textEditingController.value.text);
                      if (currentNumber + 1 >= widget.totalEpisodes) {
                        menuController.value =
                            TextEditingValue(text: "COMPLETED");
                        selectedValue = "COMPLETED";
                      }
                      if (currentNumber + 1 > widget.totalEpisodes) return;
                      textEditingController.value =
                          TextEditingValue(text: "${currentNumber + 1}");
                    },
                    icon: Icon(
                      Icons.add_circle_outline_rounded,
                      color: textMainColor,
                      size: 35,
                    ),
                  )
                ],
              )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    side: BorderSide(
                      color: accentColor,
                    ),
                    textStyle: TextStyle(
                      color: accentColor,
                      fontFamily: "Rubik",
                      fontSize: 18,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    "cancel",
                    style: TextStyle(
                      color: accentColor,
                      fontFamily: "Rubik",
                      fontSize: 22,
                    ),
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  side: BorderSide(
                    color: accentColor,
                  ),
                  textStyle: TextStyle(
                    color: accentColor,
                    fontFamily: "Rubik",
                    fontSize: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () {
                  final int progress =
                      int.parse(textEditingController.value.text);
                  if (selectedValue != null ||
                      progress != widget.episodesWatched) {
                    AnilistMutations().mutateAnimeList(
                      id: widget.id,
                      status: assignItemEnum(selectedValue!),
                      progress: progress,
                    ).then((value) {
                      if(mounted) {
                        Navigator.of(context).pop();
                      }
                      floatingSnackBar(context, "The list has been updated!");
                    });
                    initialSelection = selectedValue;
                    widget.refreshListStatus(selectedValue!, progress);
                  }
                },
                child: Text(
                  "save",
                  style: TextStyle(
                    color: accentColor,
                    fontFamily: "Rubik",
                    fontSize: 22,
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    textEditingController.dispose();
    menuController.dispose();
    super.dispose();
  }
}
