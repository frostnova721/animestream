import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';

BetterPlayerDataSource dataSourceConfig(String url, { Map<String, String>? headers = null}) {
  return BetterPlayerDataSource(
    BetterPlayerDataSourceType.network,
    url,
    bufferingConfiguration: BetterPlayerBufferingConfiguration(
      maxBufferMs: 120000,
    ),
    cacheConfiguration: BetterPlayerCacheConfiguration(
      useCache: true,
      maxCacheFileSize: 50 * 1024 * 1024,
      maxCacheSize: 50 * 1024 * 1024,
    ),
    headers: headers,
    placeholder: PlayerLoadingWidget(),
  );
}

class PlayerLoadingWidget extends StatelessWidget {
  const PlayerLoadingWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              height: 200,
              width: 200,
              child: Image.asset(
                "lib/assets/icons/logo_foreground.png",
                opacity: AlwaysStoppedAnimation(0.6),
              )),
          Text(
            "Loading Your Anime...",
            style: TextStyle(color: Colors.grey, fontFamily: "Rubik", fontWeight: FontWeight.bold),
          )
        ],
      ),
    );
  }
}

 /**Format seconds to hour:min:sec format */
  String getFormattedTime(int timeInSeconds) {
    String formatTime(int val) {
      return val.toString().padLeft(2, '0');
    }

    int hours = timeInSeconds ~/ 3600;
    int minutes = (timeInSeconds % 3600) ~/ 60;
    int seconds = timeInSeconds % 60;

    String formattedHours = hours == 0 ? '' : formatTime(hours);
    String formattedMins = formatTime(minutes);
    String formattedSeconds = formatTime(seconds);

    return "${formattedHours.length > 0 ? "$formattedHours:" : ''}$formattedMins:$formattedSeconds";
  }