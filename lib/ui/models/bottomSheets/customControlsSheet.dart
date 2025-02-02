import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/ui/pages/settingPages/common.dart';
import 'package:flutter/material.dart';
import 'package:animestream/core/commons/types.dart';

class CustomControlsBottomSheet extends StatefulWidget {
  final Function(String, Function(List<Stream>, bool)) getEpisodeSources;
  final List<Stream> currentSources;
  final Future<void> Function(String, {bool preserveProgress}) playVideo;
  final bool next;
  final int currentEpIndex;
  final List<String> epLinks;
  final Function refreshPage;
  final Function(int) updateCurrentEpIndex;
  final bool preserveProgress;
  final int? customIndex;
  final String? preferredServer;

  const CustomControlsBottomSheet({
    super.key,
    required this.getEpisodeSources,
    required this.currentSources,
    required this.playVideo,
    required this.next,
    required this.epLinks,
    required this.currentEpIndex,
    required this.refreshPage,
    required this.updateCurrentEpIndex,
    this.preserveProgress = false,
    this.customIndex,
    this.preferredServer = null,
  });

  @override
  State<CustomControlsBottomSheet> createState() => CustomControls_BottomSheetState();
}

class CustomControls_BottomSheetState extends State<CustomControlsBottomSheet> {
  List<Stream> currentSources = [];
  int currentEpIndex = 0;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    currentEpIndex = widget.currentEpIndex;

    //I think this line is useless
    currentSources = widget.currentSources;

    getSources(widget.next);
  }

  Future getSources(bool nextEpisode) async {
    if ((currentEpIndex == 0 && !nextEpisode) || (currentEpIndex + 1 >= widget.epLinks.length && nextEpisode)) {
      throw new Exception("Index too low or too high. Item not found!");
    }
    currentSources = [];
    bool alreadyCalledaSource = false;
    final index = widget.customIndex != null
        ? widget.customIndex
        : nextEpisode
            ? currentEpIndex + 1
            : currentEpIndex - 1;
    final srcs = await widget.getEpisodeSources(widget.epLinks[index!], (list, finished) {
      if (list.length > 0) {
        if (list[0].server == widget.preferredServer && !alreadyCalledaSource) {
          widget.playVideo(list[0].link, preserveProgress: widget.preserveProgress);
          currentEpIndex = index;
          widget.refreshPage(currentEpIndex, list[0]);
          widget.updateCurrentEpIndex(currentEpIndex);
          Navigator.pop(context);
          alreadyCalledaSource = true;
          return;
        }
      }
      if (mounted)
        setState(() {
          if (finished) _isLoading = false;
          currentSources = currentSources + list;
        });
    });
    if (mounted)
      setState(() {
        currentSources = srcs ?? [];
      });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height - 100,
      padding: EdgeInsets.only(left: 30, right: 30, top: 20, bottom: 20),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              "Select Server",
              style: textStyle().copyWith(fontSize: 23),
            ),
          ),
          Expanded(
            child: currentSources.length > 0
                ? _isLoading
                    ? SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _list(),
                            Center(
                              child: Container(
                                height: 100,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: appTheme.accentColor,
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      )
                    : _list()
                : Container(
                    height: 100,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: appTheme.accentColor,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  ListView _list() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: currentSources.length,
      // physics: NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.only(top: 15),
          decoration: BoxDecoration(
            color: Color.fromARGB(97, 190, 175, 255),
            borderRadius: BorderRadius.circular(20),
          ),
          child: ElevatedButton(
            onPressed: () {
              widget.playVideo(currentSources[index].link, preserveProgress: widget.preserveProgress);
              currentEpIndex = widget.customIndex != null
                  ? widget.customIndex!
                  : widget.next
                      ? currentEpIndex + 1
                      : currentEpIndex - 1;
              widget.refreshPage(currentEpIndex, currentSources[index]);
              widget.updateCurrentEpIndex(currentEpIndex);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              elevation: 0,
              surfaceTintColor: Colors.black,
              backgroundColor: appTheme.backgroundSubColor,
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
                        color: appTheme.accentColor,
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
