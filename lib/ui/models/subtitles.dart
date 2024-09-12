import 'package:animestream/core/commons/subtitleParsers.dart';
import 'package:animestream/core/commons/types.dart';
import 'package:better_player/src/video_player/video_player.dart';
import 'package:flutter/material.dart';

enum SubtitleFormat { ASS }

class SubViewer extends StatefulWidget {
  final VideoPlayerController controller;
  final String subtitleSource;
  final SubtitleFormat format;

  const SubViewer({
    super.key,
    required this.controller,
    required this.format,
    required this.subtitleSource,
  });

  @override
  State<SubViewer> createState() => _SubViewerState();
}

class _SubViewerState extends State<SubViewer> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateSubtitle);
    loadSubs();
    print("inited");
  }

  List<Subtitle> subs = [];

  String activeLine = "";
  bool areSubsLoading = true;

  void loadSubs() async {
    try {
      switch (widget.format) {
        case SubtitleFormat.ASS:
          subs = await Subtitleparsers().parseAss(widget.subtitleSource);
        default:
          throw Exception("Not implemented!");
      }
      areSubsLoading = false;
    } catch (err) {
      print(err.toString());
      areSubsLoading = false;
    }
  }

  void _updateSubtitle() {
    final currentPosition = widget.controller.value.position.inMilliseconds;

    // Find the subtitle matching the current time
    for (var subtitle in subs) {
      if (currentPosition >= subtitle.start.inMilliseconds && currentPosition <= subtitle.end.inMilliseconds) {
        if(mounted)
        setState(() {
          activeLine = subtitle.dialogue;
        });
        return;
      }
    }

    //clear line when nothings there!
    if(mounted)
    setState(() {
      activeLine = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    // print();
    return Container(
      alignment: Alignment.bottomCenter,
      margin: EdgeInsets.only(bottom: 40),
      child: Container(
        width: MediaQuery.of(context).size.width / 2,
        alignment: Alignment.bottomCenter,
        child: Stack(children: [
          //the actual text
          Text(
            areSubsLoading ? "Loading subs.." : activeLine,
            style: TextStyle(
              fontSize: 25,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        
          //the stroke of that text since the flutter doesnt have it :(
          Text(
            areSubsLoading ? "Loading subs.." : activeLine,
            style: TextStyle(
                fontSize: 25,
                // color: Colors.white,
                fontWeight: FontWeight.bold,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..color = Colors.black
                  ..strokeWidth = 1
                  ),
                  textAlign: TextAlign.center,
          ),
        ]),
      ),
    );
  }
}
