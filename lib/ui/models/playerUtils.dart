import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';

BetterPlayerDataSource dataSourceConfig(String url) {
  return BetterPlayerDataSource(
    BetterPlayerDataSourceType.network,
    url,
    bufferingConfiguration: BetterPlayerBufferingConfiguration(
      maxBufferMs: 60000,
    ),
    cacheConfiguration: BetterPlayerCacheConfiguration(
      useCache: true,
      maxCacheFileSize: 20 * 1024 * 1024,
      maxCacheSize: 20 * 1024 * 1024,
    ),
    placeholder: Center(
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
    ),
  );
}
