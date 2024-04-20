import 'package:animestream/core/anime/downloader/downloader.dart';
import 'package:animestream/core/commons/extractQuality.dart';
import 'package:animestream/core/commons/types.dart';
import 'package:animestream/core/data/watching.dart';
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
      if (mounted)
        setState(() {
          if (finished) _isLoading = false;
          streamSources = streamSources + list;
          if (widget.type == Type.download)
            list.forEach((element) {
              getQualities(element.link, element.server, element.backup);
            });
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
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 30),
        width: double.infinity,
        child: streamSources.isNotEmpty
            ? _isLoading
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _list(),
                      Container(
                        padding: EdgeInsets.only(bottom: 10),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: accentColor,
                          ),
                        ),
                      ),
                    ],
                  )
                : _list()
            : Container(
                height: 100,
                padding: EdgeInsets.only(bottom: 10, top: 20),
                child: Center(
                  child: CircularProgressIndicator(
                    color: accentColor,
                  ),
                ),
              ),
      ),
    );
  }

  ListView _list() {
    return widget.type == Type.watch
        ? ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
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
                      widget.bottomSheetContentData.episodeIndex,
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
                    ).then((value) {
                      widget.getWatched!();
                      ScaffoldMessenger.of(context).setState(() {});
                      Navigator.of(context).pop();
                    });
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
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (BuildContext context, ind) => Container(
              margin: EdgeInsets.only(top: 15),
              decoration: BoxDecoration(
                color: Color.fromARGB(97, 190, 175, 255),
                borderRadius: BorderRadius.circular(20),
              ),
              child: ElevatedButton(
                onPressed: () {
                  Downloader().download(qualities[ind]['link'],
                      "${widget.bottomSheetContentData.title}_Ep_${widget.bottomSheetContentData.episodeIndex + 1}").catchError((err) {
                        floatingSnackBar(context, "$err");
                      });
                  Navigator.of(context).pop();
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
                  mainAxisSize: MainAxisSize.min,
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
                  ],
                ),
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
