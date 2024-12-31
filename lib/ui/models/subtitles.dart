// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:animestream/core/data/preferences.dart';
import 'package:better_player/src/video_player/video_player.dart';
import 'package:flutter/material.dart';

import 'package:animestream/core/commons/subtitleParsers.dart';
import 'package:animestream/ui/models/snackBar.dart';

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
    this.fontFamily = "Rubik",
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

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'textColor': textColor.value,
      'strokeColor': strokeColor.value,
      'backgroundColor': backgroundColor.value,
      'fontFamily': fontFamily,
      'strokeWidth': strokeWidth,
      'fontSize': fontSize,
      'bottomMargin': bottomMargin,
      'backgroundTransparency': backgroundTransparency,
    };
  }

  factory SubtitleSettings.fromMap(Map<dynamic, dynamic> map) {
    return SubtitleSettings(
      textColor: Color(map['textColor'] as int),
      strokeColor: Color(map['strokeColor'] as int),
      backgroundColor: Color(map['backgroundColor'] as int),
      fontFamily: map['fontFamily'] != null ? map['fontFamily'] as String : null,
      strokeWidth: map['strokeWidth'] as double,
      fontSize: map['fontSize'] as double,
      bottomMargin: map['bottomMargin'] as double,
      backgroundTransparency: map['backgroundTransparency'] as double,
    );
  }

  String toJson() => json.encode(toMap());

  factory SubtitleSettings.fromJson(String source) =>
      SubtitleSettings.fromMap(json.decode(source) as Map<String, dynamic>);
}

class SubtitleText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Color strokeColor;
  final Color backgroundColor;
  final double strokeWidth;
  final double backgroundTransparency;

  const SubtitleText({
    super.key,
    required this.text,
    required this.style,
    required this.strokeColor,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.backgroundTransparency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor.withAlpha((backgroundTransparency * 255).toInt()),
      child: Stack(
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
      ),
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
    initiateSubs().then((_) {
      loadSubs();
      print("subs initialized");
    });
  }

  List<Subtitle> subs = [];

  late SubtitleSettings settings;

  String activeLine = "";
  bool areSubsLoading = true;
  bool settingsInited = false;

  Future<void> initiateSubs() async {
    settings = (await UserPreferences().getUserPreferences()).subtitleSettings ?? SubtitleSettings();
    setState(() {
      settingsInited = true;
    });
  }

  void loadSubs() async {
    try {
      switch (widget.format) {
        case SubtitleFormat.ASS:
          subs = await Subtitleparsers().parseAss(widget.subtitleSource);
        // default:
        // throw Exception("Not implemented!");
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
      // backgroundColor: settings.backgroundColor.withValues(alpha: settings.backgroundTransparency),
    );
  }

  @override
  Widget build(BuildContext context) {
    ///uncomment the bottom line to reflect changes on refresh while tryin to edit the [SubtitleSettings]
    // settings = SubtitleSettings();
    return settingsInited
        ? Container(
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
                backgroundColor: settings.backgroundColor,
                backgroundTransparency: settings.backgroundTransparency,
              ),
            ),
          )
        : SizedBox();
  }
}
