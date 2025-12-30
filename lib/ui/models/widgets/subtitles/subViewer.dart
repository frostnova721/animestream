import 'dart:io';

import 'package:animestream/core/app/logging.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/commons/subtitleParsers/subtitleParsers.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:animestream/ui/models/playerControllers/videoController.dart';
import 'package:animestream/ui/models/widgets/subtitles/subtitle.dart';
import 'package:animestream/ui/models/widgets/subtitles/subtitleSettings.dart';
import 'package:animestream/ui/models/widgets/subtitles/subtitleText.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

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

  List<Subtitle> activeSubtitles = [];
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
          subs = await Subtitleparsers().parseAss(widget.subtitleSource, headers: widget.headers ?? {});
        case SubtitleFormat.VTT:
          subs = await Subtitleparsers().parseVtt(widget.subtitleSource, headers: widget.headers ?? {});
        case SubtitleFormat.SRT:
          subs = await Subtitleparsers().parseSrt(widget.subtitleSource, headers: widget.headers ?? {});
        // default:
        // throw Exception("Not implemented!");
      }
      print(widget.subtitleSource);
      _loadedSubsUrl = widget.subtitleSource; // for changing subs when episode changes
      setState(() {
        areSubsLoading = false;
      });
    } catch (err) {
      Logs.player.log(err.toString());
      SchedulerBinding.instance.addPostFrameCallback((dur) {
        floatingSnackBar("Couldnt load the subtitles!");
      });
      setState(() {
        areSubsLoading = false;
      });
    }
  }

  int lastLineIndex = 0;

  void _updateSubtitle() {
    final currentPosition = widget.controller.position;

    if (currentPosition == null || subs.isEmpty) return;

    if (_loadedSubsUrl != widget.subtitleSource && !areSubsLoading) {
      print("Subtitle Source Changed, Loading new subs..");
      return loadSubs();
    }

    // If we seeked backward (current time is before the last known start), reset hint.
    if (lastLineIndex >= subs.length ||
        (lastLineIndex > 0 && subs[lastLineIndex].start.inMilliseconds > currentPosition)) {
      lastLineIndex = 0; // reset to start for safety
    }

    // Move forward past any subtitles that are over
    while (lastLineIndex < subs.length && subs[lastLineIndex].end.inMilliseconds < currentPosition) {
      lastLineIndex++;
    }

    List<Subtitle> newMatches = [];

    // Start checking from our synced index.
    for (int i = lastLineIndex; i < subs.length; i++) {
      final sub = subs[i];

      // If we hit a subtitle that starts in the future, we can stop looking entirely.
      // Because the list is usually sorted, no subsequent subtitle can be active either.
      if (sub.start.inMilliseconds > currentPosition) {
        break;
      }

      // If we are here, the subtitle started before now.
      // We just need to check if it hasn't ended yet.
      if (sub.end.inMilliseconds >= currentPosition) {
        newMatches.add(sub);
      }
    }

    if (!_areSubtitleListsEqual(activeSubtitles, newMatches)) {
      if (mounted) {
        setState(() {
          activeSubtitles = newMatches;
        });
      }
    }
  }

  // Helper to compare lists efficiently
  bool _areSubtitleListsEqual(List<Subtitle> a, List<Subtitle> b) {
    if (a.length != b.length) return false;
    if (a.isEmpty && b.isEmpty) return true;

    // compare the start n end times of the first and last subtitles
    return a.first.start.inMilliseconds == b.first.start.inMilliseconds &&
        a.first.end.inMilliseconds == b.first.end.inMilliseconds &&
        a.last.start.inMilliseconds == b.last.start.inMilliseconds &&
        a.last.end.inMilliseconds == b.last.end.inMilliseconds;
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
    return Stack(
      children: activeSubtitles
          .map(
            (activeSubtitle) => Container(
              alignment: Alignment.bottomCenter,
              margin: EdgeInsets.only(bottom: widget.settings.bottomMargin, top: widget.settings.bottomMargin),
              child: Container(
                width: MediaQuery.of(context).size.width / 1.4,
                alignment: getLineAlignment(activeSubtitle.alignment),
                child: SubtitleText(
                  text: areSubsLoading ? "Loading Subs" : activeSubtitle.dialogue,
                  style: subTextStyle(),
                  strokeColor: widget.settings.strokeColor,
                  strokeWidth: widget.settings.strokeWidth,
                  backgroundColor: widget.settings.backgroundColor,
                  backgroundTransparency: widget.settings.backgroundTransparency,
                  enableShadows: widget.settings.enableShadows,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Alignment getLineAlignment(SubtitleAlignment alignment) {
    switch (alignment) {
      case SubtitleAlignment.topLeft:
        return Alignment.topLeft;
      case SubtitleAlignment.topCenter:
        return Alignment.topCenter;
      case SubtitleAlignment.topRight:
        return Alignment.topRight;
      case SubtitleAlignment.centerLeft:
        return Alignment.centerLeft;
      case SubtitleAlignment.center:
        return Alignment.center;
      case SubtitleAlignment.centerRight:
        return Alignment.centerRight;
      case SubtitleAlignment.bottomLeft:
        return Alignment.bottomLeft;
      case SubtitleAlignment.bottomCenter:
        return Alignment.bottomCenter;
      case SubtitleAlignment.bottomRight:
        return Alignment.bottomRight;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateSubtitle);
    super.dispose();
  }
}
