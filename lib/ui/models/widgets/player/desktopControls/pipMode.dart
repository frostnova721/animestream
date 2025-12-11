import 'package:animestream/ui/models/providers/playerDataProvider.dart';
import 'package:animestream/ui/models/providers/playerProvider.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class PipUi extends StatelessWidget {
  final PlayerProvider playerProvider;
  final PlayerDataProvider dataProvider;
  const PipUi({super.key, required this.playerProvider, required this.dataProvider});

  @override
  Widget build(BuildContext context) {
    final isPlaying = playerProvider.controller.isPlaying ?? false;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (details) {
        windowManager.startDragging();
      },
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                    tooltip: "Exit PiP Mode",
                    onPressed: () {
                      playerProvider.setPip(false);
                    },
                    icon: const Icon(Icons.open_in_new_rounded))
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                    iconSize: 40,
                    tooltip: isPlaying ? "Pause" : "Play",
                    onPressed: () {
                      isPlaying ? playerProvider.controller.pause() : playerProvider.controller.play();
                    },
                    icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded))
              ],
            ),
          ],
        ),
      ),
    );
  }
}
