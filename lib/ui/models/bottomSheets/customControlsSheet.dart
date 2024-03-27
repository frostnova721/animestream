import 'package:animestream/ui/theme/mainTheme.dart';
import 'package:flutter/material.dart';

class CustomControlsBottomSheet extends StatefulWidget {
  final Function(String, Function(List<dynamic>, bool)) getEpisodeSources;
  final List<dynamic> currentSources;
  final Function playVideo;
  final bool next;
  final int currentEpIndex;
  final List<String> epLinks;
  final Function refreshPage;
  final Function(int) updateCurrentEpIndex;
  const CustomControlsBottomSheet({
    super.key,
    required this.getEpisodeSources,
    required this.currentSources,
    required this.playVideo,
    required this.next,
    required this.epLinks,
    required this.currentEpIndex,
    required this.refreshPage,
    required this.updateCurrentEpIndex, //this updation is just for custom controls. i think this whole file needs a redesign (its really confusing than other files)
  });

  @override
  State<CustomControlsBottomSheet> createState() =>
      CustomControls_BottomSheetState();
}

class CustomControls_BottomSheetState extends State<CustomControlsBottomSheet> {
  List currentSources = [];
  int currentEpIndex = 0;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    currentEpIndex = widget.currentEpIndex;
    currentSources = widget.currentSources;
    getSources(widget.next);
  }

  Future getSources(bool nextEpisode) async {
    if ((currentEpIndex == 0 && !nextEpisode) ||
        (currentEpIndex + 1 > widget.epLinks.length && nextEpisode)) {
      throw new Exception("Index too low or too high. Item not found!");
    }
    currentSources = [];
    final index = nextEpisode ? currentEpIndex + 1 : currentEpIndex - 1;
    final srcs =
        await widget.getEpisodeSources(widget.epLinks[index], (list, finished) {
      if (mounted)
        setState(() {
          if (finished) _isLoading = false;
          currentSources = currentSources + list;
        });
    });
    if (mounted)
      setState(() {
        currentSources = srcs;
      });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.only(left: 30, right: 30, top: 10, bottom: 20),
        child: currentSources.length > 0
            ? _isLoading
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _list(),
                      Center(
                        child: Container(
                          height: 100,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: accentColor,
                            ),
                          ),
                        ),
                      )
                    ],
                  )
                : _list()
            : Container(
                height: 100,
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
    return ListView.builder(
      shrinkWrap: true,
      itemCount: currentSources.length,
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.only(top: 15),
          decoration: BoxDecoration(
            color: Color.fromARGB(97, 190, 175, 255),
            borderRadius: BorderRadius.circular(20),
          ),
          child: ElevatedButton(
            onPressed: () async {
              await widget.playVideo(currentSources[index].link);
              currentEpIndex =
                  widget.next ? currentEpIndex + 1 : currentEpIndex - 1;
              widget.refreshPage(currentEpIndex, currentSources[index]);
              widget.updateCurrentEpIndex(currentEpIndex);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color.fromARGB(68, 190, 175, 255),
              padding: EdgeInsets.only(top: 5, bottom: 5, left: 20, right: 20),
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
                      currentSources[index].server,
                      style: TextStyle(
                        fontFamily: "NotoSans",
                        fontSize: 17,
                        color: accentColor,
                      ),
                    ),
                    if (currentSources[index].backup)
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
                    currentSources[index].quality,
                    style: TextStyle(color: Colors.white, fontFamily: "Rubik"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
