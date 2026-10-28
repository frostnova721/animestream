import 'package:animestream/core/app/logging.dart';

class AnilistRateLimiter {
  AnilistRateLimiter._();
  static final AnilistRateLimiter _instance = AnilistRateLimiter._();
  static AnilistRateLimiter get instance => _instance;

  int? _remaining;
  DateTime? _resetAt;
  DateTime? _blockedUntil;

  bool get isBlocked => _blockedUntil != null && DateTime.now().isBefore(_blockedUntil!);

  Duration get timeUntilUnblock {
    if (!isBlocked) return Duration.zero;
    return _blockedUntil!.difference(DateTime.now());
  }

  Future<void> waitUntilSlot() async {
    if (_resetAt != null && DateTime.now().isAfter(_resetAt!)) {
      _remaining = null;
      _resetAt = null;
      _blockedUntil = null;
    }

    while (isBlocked) {
      final wait = timeUntilUnblock;
      Logs.app.log("[ANILIST] Rate limit reached. Waiting for ${wait.inSeconds} seconds until next slot.");

      // a small buffer for a breathing space
      await Future.delayed(wait + const Duration(milliseconds: 200));
    }

    if (_remaining != null && _remaining! <= 1 && _resetAt != null && DateTime.now().isBefore(_resetAt!)) {
      final wait = _resetAt!.difference(DateTime.now()) + const Duration(seconds: 1);
      if (wait.isNegative) return;
      Logs.app.log("[ANILIST] Rate limit slot available in ${wait.inSeconds} seconds. Waiting...");
      _blockedUntil = DateTime.now().add(wait);
      await Future.delayed(wait);
    }
  }

  void updateFromHeaders(Map<String, String> headers) {
    final remStr = headers['x-ratelimit-remaining'];
    final resetStr = headers['x-ratelimit-reset'];

    if (remStr != null) {
      _remaining = int.tryParse(remStr);
    }

    if (resetStr != null) {
      // representend in Epoch
      final resetSeconds = int.tryParse(resetStr);
      if (resetSeconds != null) {
        _resetAt = DateTime.fromMillisecondsSinceEpoch(resetSeconds * 1000);
      }
    }

    if (_remaining != null && _remaining! <= 1 && _resetAt != null) {
      if (DateTime.now().isBefore(_resetAt!)) {
        _blockedUntil = _resetAt!.add(const Duration(seconds: 1));
      }
    }
  }

  Duration handleRateLimitExceeded(Map<String, String> headers) {
    int wait = 60; // safe 1 min fallback cooldown timer!

    final retryAfter = headers['retry-after'];
    if (retryAfter != null) {
      wait = int.tryParse(retryAfter) ?? 60;
    } else {
      final resetStr = headers['x-ratelimit-reset'];
      if (resetStr != null) {
        final resetEpoch = int.tryParse(resetStr);
        if (resetEpoch != null) {
          final resetTime = DateTime.fromMillisecondsSinceEpoch(resetEpoch * 1000);
          final waitDuration = resetTime.difference(DateTime.now()).inSeconds;
          if (waitDuration > 0) wait = waitDuration + 1; // add 1 second buffer
        }
      }
    }

    if (wait < 1) wait = 1; // ensure at least 1 second wait
    final cooldown = Duration(seconds: wait);
    _blockedUntil = DateTime.now().add(cooldown + const Duration(milliseconds: 500));
    _remaining = 0;

    Logs.app.log("[ANILIST RATE LIMIT] 429 Too Many Requests! Pausing queries for $wait seconds.");

    return cooldown;
  }
}
