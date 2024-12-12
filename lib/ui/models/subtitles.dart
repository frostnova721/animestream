import 'package:animestream/core/commons/subtitleParsers.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:better_player/src/video_player/video_player.dart';
import 'package:flutter/material.dart';

enum SubtitleFormat { ASS }

class Subtitle {
  final Duration start;
  final Duration end;
  final String dialogue;
  // final String

  Subtitle({
    required this.dialogue,
    required this.end,
    required this.start,
  });
}

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
    this.fontSize = 25,
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

class SubtitleText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Color strokeColor;
  final double strokeWidth;

  const SubtitleText(
      {super.key, required this.text, required this.style, required this.strokeColor, required this.strokeWidth});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        //the actual text
        Text(
          text,
          style: style.copyWith(shadows: [
            Shadow(color: Colors.black, blurRadius: 4.5),
          ]),
          textAlign: TextAlign.center,
        ),

        //the stroke of that text since the flutter doesnt have it :(
        Text(
          text,
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..color = strokeColor
              ..strokeWidth = strokeWidth,
          ),
          textAlign: TextAlign.center,
        ),
      ],
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
    print("subs initialized");
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
        if (mounted)
          setState(() {
            activeLine = subtitle.dialogue;
          });
        return;
      }
    }

    //clear line when nothings there!
    if (mounted)
      setState(() {
        activeLine = '';
      });
  }

  //i tried to make it beautiful! okay???
  TextStyle subTextStyle() {
    return TextStyle(
      fontSize: settings.fontSize,
      fontFamily: settings.fontFamily ?? "Rubik",
      color: settings.textColor,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
      // wordSpacing: 1,
      fontFamilyFallback: ["Poppins"],
      backgroundColor: settings.backgroundColor.withValues(alpha: settings.backgroundTransparency),
    );
  }

  @override
  Widget build(BuildContext context) {
    ///uncomment the bottom line to reflect changes on refresh while tryin to edit the [SubtitleSettings]
    // settings = SubtitleSettings();
    return Container(
      alignment: Alignment.bottomCenter,
      margin: EdgeInsets.only(bottom: settings.bottomMargin),
      child: Container(
        width: MediaQuery.of(context).size.width / 1.6,
        alignment: Alignment.bottomCenter,
        child: SubtitleText(
          text: activeLine,
          style: subTextStyle(),
          strokeColor: settings.strokeColor,
          strokeWidth: settings.strokeWidth,
        ),
      ),
    );
  }
}
