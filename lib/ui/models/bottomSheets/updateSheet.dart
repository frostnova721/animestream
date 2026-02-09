import 'dart:async';
import 'dart:io';

import 'package:animestream/core/app/logging.dart';
import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:http/http.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class UpdateSheet extends StatefulWidget {
  final String markdownText;
  final String downloadLink;
  final bool pre;
  final String version;
  const UpdateSheet({
    required this.downloadLink,
    required this.markdownText,
    required this.pre,
    required this.version,
    super.key,
  });

  @override
  State<UpdateSheet> createState() => _UpdateSheetState();
}

class _UpdateSheetState extends State<UpdateSheet> {
  StreamSubscription<List<int>>? _sub;

  final ValueNotifier<double> progress = ValueNotifier(0);

  DownloadState downloadState = DownloadState.idle;

  String downloadPath = "";

  void downloadAndInstallUpdate({bool installOnly = false}) async {
    final filename = "animestream_${widget.version}.${Platform.isWindows ? "exe" : "apk"}";
    final tempPath = await getTemporaryDirectory();
    downloadPath = "${tempPath.path}/$filename";

    if (File(downloadPath).existsSync()) {
      Logs.app.log("Patch already downloaded. Opening the file...");
    } else {
      Logs.app.log("Downloading patch ${widget.version}...");

      setState(() {
        downloadState = DownloadState.downloading;
      });

      final uri = Uri.parse(widget.downloadLink);
      final buffer = <int>[];
      final completer = Completer();

      double downloadedBytes = 0;

      final req = Request("GET", uri);
      final res = await req.send();
      int totalBytes = res.contentLength ?? 1;

      _sub = res.stream.listen(
        (chunk) {
          downloadedBytes += chunk.length;
          progress.value = downloadedBytes / totalBytes;
          buffer.addAll(chunk);
        },
        onError: (err) => completer.completeError(err),
        onDone: () => completer.complete(),
      );

      try {
        await completer.future;
      } catch (err) {
        floatingSnackBar("There was an issue downloading the update.");
        Logs.app.log("Error downloading the update: ${err.toString()}");

        setState(() {
          downloadState = DownloadState.idle;
        });

        return;
      }

      // check and clean the old file (can pile up if not cleaned)
      // this is also cleanable with the "clear cache" option
      final oldVersion = File(
          "${tempPath.path}/animestream_${(await PackageInfo.fromPlatform()).version}.${Platform.isWindows ? "exe" : "apk"}");
      if (oldVersion.existsSync()) {
        oldVersion.delete();
      }

      await File(downloadPath).writeAsBytes(buffer);

      // set completed state after saving to disk
      setState(() {
        downloadState = DownloadState.completed;
      });

      Logs.app.log("nice... Download complete!");
    }

    final openRes = await OpenFile.open(downloadPath);
    if (openRes.type == ResultType.permissionDenied) {
      await Permission.requestInstallPackages.request();
    }
    if (openRes.type == ResultType.done) {
      Logs.app.log("Update dialog invoked succesfully.");
    }
  }

  void _cancelDownload() {
    _sub?.cancel();
    _sub = null;
    setState(() => downloadState = DownloadState.idle);
    progress.value = 0;
  }

  @override
  void dispose() {
    _sub?.cancel();
    progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom, left: 15, right: 15, top: 10),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Text(
                "Update Available",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 14, bottom: 12),
              child: Row(
                // mainAxisAlignment: ,
                children: [
                  Text(
                    widget.version,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  Container(
                      padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      margin: EdgeInsets.only(left: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        color: appTheme.accentColor,
                      ),
                      child: Text(
                        widget.pre ? "beta" : "stable",
                        style: TextStyle(
                          color: appTheme.onAccent,
                          fontSize: 15,
                          fontFamily: "NunitoSans",
                        ),
                      )),
                ],
              ),
            ),
            Container(
              height: 400,
              decoration: BoxDecoration(color: appTheme.backgroundSubColor, borderRadius: BorderRadius.circular(25)),
              padding: EdgeInsets.all(14),
              child: ListView(
                shrinkWrap: true,
                children: [
                  MarkdownBody(
                    data: widget.markdownText,
                    styleSheet: MarkdownStyleSheet(
                      h1: style(bold: true),
                      h2: style(bold: true),
                      listBullet: style(),
                      h3: style(),
                      h4: style(),
                      h5: style(),
                      h6: style(),
                      p: style(),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ValueListenableBuilder(
                        valueListenable: progress,
                        builder: (ctx, val, child) {
                          return LiquidDownloadButton(
                            state: downloadState,
                            progress: val,
                            onPressed: () {
                              // if the update is downloaded and state is install, it automatically opens
                              // the available update file
                              if (downloadState != DownloadState.downloading) return downloadAndInstallUpdate();
                            },
                          );
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: IconButton.outlined(
                      onPressed: () async {
                        _cancelDownload();
                        if (downloadPath.isNotEmpty && downloadState != DownloadState.completed) await File(downloadPath).delete();
                        setState(() {});
                        Navigator.pop(context);
                      },
                      color: appTheme.accentColor,
                      style: IconButton.styleFrom(
                        side: BorderSide(color: appTheme.accentColor),
                        fixedSize: Size.fromHeight(50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      icon: Icon(Icons.close),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle style({bool bold = false}) {
    return TextStyle(
      color: appTheme.textMainColor,
      fontFamily: "NotoSans",
      fontWeight: bold ? FontWeight.bold : null,
    );
  }
}

enum DownloadState { idle, downloading, completed }

class LiquidDownloadButton extends StatelessWidget {
  final DownloadState state;
  final double progress; // 0.0 to 1.0
  final VoidCallback onPressed;

  const LiquidDownloadButton({
    super.key,
    required this.state,
    required this.progress,
    required this.onPressed,
  }) : assert(progress >= 0 && progress <= 1, "Progress value must be between 0.0 and 1.0!");

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Container(
          height: 50,
          width: double.infinity,
          color: state == DownloadState.idle ? appTheme.accentColor : appTheme.backgroundSubColor,
          child: Stack(
            children: [
              if (state != DownloadState.idle)
                LayoutBuilder(
                  builder: (context, constraints) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      width: constraints.maxWidth * progress,
                      height: constraints.maxHeight,
                      color: appTheme.accentColor,
                    );
                  },
                ),
              Center(
                child: Text(
                  _getButtonText(),
                  style: TextStyle(
                    color: appTheme.onAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getButtonText() {
    switch (state) {
      case DownloadState.idle:
        return "Download";
      case DownloadState.downloading:
        return "Downloading... ${(progress * 100).toInt()}%";
      case DownloadState.completed:
        return "Install";
    }
  }
}
