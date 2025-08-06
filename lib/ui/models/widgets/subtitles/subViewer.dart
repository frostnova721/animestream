import 'dart:io';

import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/commons/subtitleParsers.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:animestream/ui/models/watchPageUtil.dart';
import 'package:animestream/ui/models/widgets/subtitles/subtitle.dart';
import 'package:animestream/ui/models/widgets/subtitles/subtitleSettings.dart';
import 'package:animestream/ui/models/widgets/subtitles/subtitleText.dart';
import 'package:flutter/material.dart';

class SubViewer extends StatefulWidget {
  final VideoController controller;
  final String subtitleSource;
  final Map<String, String>? headers;
  final SubtitleFormat format;
  final SubtitleSettings settings;

  const SubViewer({
    super.key,
    required this.controller,
    required this.format,
    required this.subtitleSource,
    required this.settings,
    this.headers = const {},
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

  String? _loadedSubsUrl;

  void loadSubs() async {
    try {
      setState(() {
        areSubsLoading = true;
      });
      subs.clear(); // clear the old subs (if any)
      print("loading ${widget.format.name} subs");
      switch (widget.format) {
        case SubtitleFormat.ASS:
          subs = await Subtitleparsers().parseAss(widget.subtitleSource, headers: widget.headers!);
        case SubtitleFormat.VTT:
          subs = await Subtitleparsers().parseVtt(widget.subtitleSource, headers: widget.headers!);
        // default:
        // throw Exception("Not implemented!");
      }
      print(widget.subtitleSource);
      _loadedSubsUrl = widget.subtitleSource; // for changing subs when episode changes
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

    if (_loadedSubsUrl != widget.subtitleSource && !areSubsLoading) return loadSubs();

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
      // letterSpacing: -0.2,
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
          text: areSubsLoading ? "Loading Subs" : activeLine,
          style: subTextStyle(),
          strokeColor: widget.settings.strokeColor,
          strokeWidth: widget.settings.strokeWidth,
          backgroundColor: widget.settings.backgroundColor,
          backgroundTransparency: widget.settings.backgroundTransparency,
          enableShadows: widget.settings.enableShadows,
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
