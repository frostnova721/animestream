import 'package:animestream/ui/models/providers/playerDataProvider.dart';
import 'package:animestream/ui/models/providers/playerProvider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SeekBar extends StatefulWidget {
  final SliderThemeData sliderTheme;
  final bool locked;

  const SeekBar({super.key, required this.sliderTheme, required this.locked});

  @override
  State<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  double? _dragValue;
  bool _wasPlaying = false;

  @override
  Widget build(BuildContext context) {
    final pp = context.read<PlayerProvider>();
    final position = context.select<PlayerDataProvider, int>((p) => p.state.sliderValue);

    final double max = (pp.controller.duration ?? 0) / 1000;
    final double safe = max > 0.0 ? max : 1.0;
    final double val = (_dragValue ?? position.toDouble()).clamp(0, safe);
    final buffered = pp.controller.buffered?.toDouble();
    return SliderTheme(
      data: widget.sliderTheme,
      child: Slider(
        min: 0,
        max: safe,
        value: val,
        secondaryTrackValue: buffered != null ? (buffered / 1000).clamp(0, safe) : null,
        onChanged: (val) {
          setState(() {
            _dragValue = val;
          });
        },
        onChangeStart: (value) {
          _wasPlaying = pp.state.playerState.isPlaying;
          pp.controller.pause();
        },
        onChangeEnd: (value) async {
          // just to make sure its on the same page...
          await pp.controller.seekTo(Duration(seconds: value.toInt()));

          if (_wasPlaying) await pp.controller.play();
        },
      ),
    );
  }
}