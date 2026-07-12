import 'package:animestream/core/app/env.dart';
import 'package:dart_discord_presence/dart_discord_presence.dart';

class DiscordDesktopRPC {
  final _discord = DiscordRPC();
  bool _isInitialized = false;

  Future<void> initiateConnection() async {
    _discord.onError.listen((e) => print(e.message));

    _discord.onReady.listen((val) {
      print("RPC Client connected as ${val.user.username}.");
    });

    await _discord.initialize(AnimeStreamEnvironment.discordApplicationId);
    _isInitialized = true;
  }

  Future<void> updatePresence(DiscordPresence presence) async {
    if (!_isInitialized) {
      await initiateConnection();
    }
    await _discord.setPresence(presence);
  }

  Future<void> clearPresence() => _discord.clearPresence();

  Future<void> dispose() => _discord.dispose();
}
