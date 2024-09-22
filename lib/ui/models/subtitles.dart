import 'package:animestream/core/commons/subtitleParsers.dart';
import 'package:animestream/core/commons/types.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:better_player/src/video_player/video_player.dart';
import 'package:flutter/material.dart';

enum SubtitleFormat { ASS }

class SubtitleSettings {
  final Color textColor;
  final Color strokeColor;
  final Color backgroundColor;

  final String? fontFamily;

  final double strokeWidth;
  final double fontSize;
  final double bottomMargin;
  final double backgroundTransparency;

  SubtitleSettings({
    this.backgroundColor = Colors.black,
    this.backgroundTransparency = 0,
    this.bottomMargin = 35,
    this.fontSize = 23,
    this.strokeColor = Colors.black,
    this.strokeWidth = 1.1,
    this.textColor = Colors.white,
    this.fontFamily = null,
  });

  SubtitleSettings copyWith({
    Color? backgroundColor,
    Color? textColor,
    Color? strokeColor,
    double? fontSize,
    double? strokeWidth,
    double? bottomMargin,
    double? backgroundTransparency,
    String? fontFamily,
  }) {
    return SubtitleSettings(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      backgroundTransparency: backgroundTransparency ?? this.backgroundTransparency,
      bottomMargin: bottomMargin ?? this.bottomMargin,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      strokeColor: strokeColor ?? this.strokeColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      textColor: textColor ?? this.textColor,
    );
  }
}

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

  SubtitleSettings settings = SubtitleSettings();

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
      setState(() {
        areSubsLoading = false;
      });
    } catch (err) {
      print(err.toString());
      floatingSnackBar(context, "Couldnt load the subtitles!");
      setState(() {
        areSubsLoading = false;
      });
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
      margin: EdgeInsets.only(bottom: settings.bottomMargin),
      child: Container(
        width: MediaQuery.of(context).size.width / 1.6,
        alignment: Alignment.bottomCenter,
        child: Stack(children: [
          //the actual text
          Text(
            areSubsLoading ? "Loading subs.." : activeLine,
            style: TextStyle(
              fontSize: settings.fontSize,
              fontFamily: settings.fontFamily,
              color: settings.textColor,
              fontWeight: FontWeight.bold,
              backgroundColor: settings.backgroundColor.withOpacity(settings.backgroundTransparency)
            ),
            textAlign: TextAlign.center,
          ),
        
          //the stroke of that text since the flutter doesnt have it :(
          Text(
            areSubsLoading ? "Loading subs.." : activeLine,
            style: TextStyle(
                fontSize: settings.fontSize,
                fontFamily: settings.fontFamily,
                // color: Colors.white,
                fontWeight: FontWeight.bold,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..color = settings.strokeColor
                  ..strokeWidth = settings.strokeWidth
                  ),
                  textAlign: TextAlign.center,
          ),
        ]),
      ),
    );
  }
}
