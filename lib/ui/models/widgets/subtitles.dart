// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/commons/subtitleParsers.dart';
import 'package:animestream/ui/models/extensions.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:animestream/ui/models/watchPageUtil.dart';

class Subtitle {
  final Duration start;
  final Duration end;
  final String dialogue;

  Subtitle({
    required this.dialogue,
    required this.end,
    required this.start,
  });

  @override
  String toString() =>
      'Subtitle(start: $start, end: $end, dialogue: $dialogue)';
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

  final bool bold;

  SubtitleSettings({
    this.backgroundColor = Colors.black,
    this.backgroundTransparency = 0,
    this.bottomMargin = 30,
    this.fontSize = 24,
    this.strokeColor = Colors.black,
    this.strokeWidth = 1.1,
    this.textColor = Colors.white,
    this.fontFamily = "Rubik",
    this.bold = false,
  });

  SubtitleSettings copyWith({
    Color? textColor,
    Color? strokeColor,
    Color? backgroundColor,
    String? fontFamily,
    double? strokeWidth,
    double? fontSize,
    double? bottomMargin,
    double? backgroundTransparency,
    bool? bold,
  }) {
    return SubtitleSettings(
      textColor: textColor ?? this.textColor,
      strokeColor: strokeColor ?? this.strokeColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      fontFamily: fontFamily ?? this.fontFamily,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      fontSize: fontSize ?? this.fontSize,
      bottomMargin: bottomMargin ?? this.bottomMargin,
      backgroundTransparency: backgroundTransparency ?? this.backgroundTransparency,
      bold: bold ?? this.bold,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'textColor': textColor.toInt(),
      'strokeColor': strokeColor.toInt(),
      'backgroundColor': backgroundColor.toInt(),
      'fontFamily': fontFamily,
      'strokeWidth': strokeWidth,
      'fontSize': fontSize,
      'bottomMargin': bottomMargin,
      'backgroundTransparency': backgroundTransparency,
      'bold': bold,
    };
  }

  factory SubtitleSettings.fromMap(Map<dynamic, dynamic> map) {
    return SubtitleSettings(
      textColor: Color(map['textColor'] as int? ?? Colors.white.toInt()),
      strokeColor: Color(map['strokeColor'] as int? ?? Colors.black.toInt()),
      backgroundColor: Color((map['backgroundColor'] ?? Colors.black.toInt()) as int),
      fontFamily:
          map['fontFamily'] != null ? map['fontFamily'] as String : "Rubik",
      strokeWidth: (map['strokeWidth'] ?? 1.1) as double,
      fontSize: (map['fontSize'] ?? 24) as double,
      bottomMargin: (map['bottomMargin'] ?? 30) as double,
      backgroundTransparency: (map['backgroundTransparency'] ?? 0) as double,
      bold: (map['bold'] ?? false) as bool,
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

          //the actual text
          Text(
            text,
            style: style.copyWith(shadows: [
              Shadow(color: Colors.black, blurRadius: 3.5, offset: Offset(1, 1)),
            ],),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class SubViewer extends StatefulWidget {
  final VideoController controller;
  final String subtitleSource;
  final SubtitleFormat format;
  final SubtitleSettings settings;

  const SubViewer({
    super.key,
    required this.controller,
    required this.format,
    required this.subtitleSource,
    required this.settings,
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

  String activeLine = "";
  bool areSubsLoading = true;

  void loadSubs() async {
    try {
      print("loading ${widget.format.name} subs");
      switch (widget.format) {
        case SubtitleFormat.ASS:
          subs = await Subtitleparsers().parseAss(widget.subtitleSource);
        case SubtitleFormat.VTT:
          subs = await Subtitleparsers().parseVtt(widget.subtitleSource);
        // default:
        // throw Exception("Not implemented!");
      }
      setState(() {
        areSubsLoading = false;
      });
    } catch (err) {
      print(err.toString());
      floatingSnackBar("Couldnt load the subtitles!");
      setState(() {
        areSubsLoading = false;
      });
    }
  }

  int lastLineIndex = 0;

  void _updateSubtitle() {
    final currentPosition = widget.controller.position;

    if (currentPosition == null || subs.isEmpty) return;

    int i = lastLineIndex;

    // Find the subtitle matching the current time
    // Search forward if we're past the current subtitle
    if (i < subs.length && currentPosition > subs[i].end.inMilliseconds) {
      while (i < subs.length && currentPosition > subs[i].end.inMilliseconds) {
        i++;
      }
    }
    // Search backward if we're before the current subtitle
    else if (i > 0 && currentPosition < subs[i].start.inMilliseconds) {
      while (i > 0 && currentPosition < subs[i].start.inMilliseconds) {
        i--;
      }
    }

    lastLineIndex = i;

    // Check if we're within the current subtitle's time range
    if (i < subs.length &&
        currentPosition >= subs[i].start.inMilliseconds &&
        currentPosition <= subs[i].end.inMilliseconds) {
      if (mounted) {
        setState(() {
          activeLine = subs[i].dialogue;
        });
      }
      return;
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
      fontSize: Platform.isWindows ? widget.settings.fontSize * 1.5 : widget.settings.fontSize,
      fontFamily: widget.settings.fontFamily ?? "Rubik",
      color: widget.settings.textColor,
      fontWeight: widget.settings.bold ? FontWeight.w700 : FontWeight.w500,
      letterSpacing: -0.2,
      // wordSpacing: 1,
      fontFamilyFallback: ["Poppins"],
      // backgroundColor: widget.settings.backgroundColor.withValues(alpha: widget.settings.backgroundTransparency),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Container(
            alignment: Alignment.bottomCenter,
            margin: EdgeInsets.only(bottom: widget.settings.bottomMargin),
            child: Container(
              width: MediaQuery.of(context).size.width / 1.6,
              alignment: Alignment.bottomCenter,
              child: SubtitleText(
                text: activeLine,
                style: subTextStyle(),
                strokeColor: widget.settings.strokeColor,
                strokeWidth: widget.settings.strokeWidth,
                backgroundColor: widget.settings.backgroundColor,
                backgroundTransparency: widget.settings.backgroundTransparency,
              ),
            ),
          );
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateSubtitle);
    super.dispose();
  }
}
