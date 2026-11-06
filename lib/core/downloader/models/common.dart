// some of them here are just for names lol
enum DownloadStatus { downloading, queued, paused, completed, cancelled, failed }

class DownloadMessage {
  final int progress;
  final String status;
  final int id;
  final String? message;
  final List<Object> extras; // ik, not a good way to do it! might refactor later, lazy rn
  final bool silent;

  DownloadMessage({
    required this.status,
    required this.id,
    this.message,
    this.progress = 0,
    this.extras = const [],
    this.silent = false,
  });
}
