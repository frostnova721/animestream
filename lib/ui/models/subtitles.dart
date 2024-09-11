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
    print("inited");
  }

  List<Subtitle> subs = [];

  String activeLine = "";

  void loadSubs() async {
    switch(widget.format) {
      case SubtitleFormat.ASS:
        subs = await Subtitleparsers().parseAss(widget.subtitleSource);
      default:
        throw Exception("Not implemented!");
    }
  }

  void _updateSubtitle() {
    final currentPosition = widget.controller.value.position.inMilliseconds;

    // Find the subtitle matching the current time
    for (var subtitle in subs) {
      if (currentPosition >= subtitle.start.inMilliseconds && currentPosition <= subtitle.end.inMilliseconds) {
        setState(() {
          activeLine = subtitle.dialogue;
        });
        return;
      }
    }

    //clear line when nothings there!
    setState(() {
      activeLine = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    // print();
    return Container(
      child: Text(activeLine, style: TextStyle(fontSize: 20, color: Colors.black),),
    );
  }
}
