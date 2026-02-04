import 'dart:async';
import 'dart:io';

import 'package:animestream/core/app/logging.dart';
import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:http/http.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class UpdateSheet extends StatefulWidget {
  final String markdownText;
  final String downloadLink;
  final bool pre;
  final bool isDesktop;
  final String version;
  const UpdateSheet({
    required this.downloadLink,
    required this.markdownText,
    required this.pre,
    required this.isDesktop,
    required this.version,
    super.key,
  });

  @override
  State<UpdateSheet> createState() => _UpdateSheetState();
}

class _UpdateSheetState extends State<UpdateSheet> {
  StreamSubscription<Response>? _sub;

  double progress = 0;

  void downloadAndInstallUpdate() async {
    final filename = "animestream_${widget.version}.${Platform.isWindows ? "exe" : "apk"}";
    final tempPath = await getTemporaryDirectory();
    final downloadPath = "${tempPath.path}/$filename";

    if (File(filename).existsSync()) {
      Logs.app.log("Patch already downloaded. Opening the file...");
    } else {
      Logs.app.log("Downloading patch v${widget.version}...");
      final uri = Uri.parse(widget.downloadLink);
      final buffer = <int>[];
      final completer = Completer();

      double downloadedBytes = 0;

      _sub = await get(uri).asStream().listen(
        (res) {
          downloadedBytes += res.bodyBytes.length;
          progress = downloadedBytes / (res.contentLength ?? 1);
          buffer.addAll(res.bodyBytes);
        },
        onError: (err) => {completer.completeError(err)},
        onDone: () => completer.complete(),
      );

      try {
        await completer.future;
      } catch (err) {
        floatingSnackBar("There was an issue downloading the update.");
        Logs.app.log("Error downloading the update: ${err.toString()}");
        return;
      }

      await File(downloadPath).writeAsBytes(buffer);
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

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom, left: 15, right: 15, top: 10),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Update Available",
              style: TextStyle(fontSize: 24),
            ),
            Row(
              children: [
                Text(widget.version),
                Container(
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      color: appTheme.accentColor,
                    ),
                    child: Text(
                      widget.pre ? "beta" : "stable",
                      style: TextStyle(color: appTheme.onAccent),
                    )),
              ],
            ),
            if (widget.pre)
              Text(
                "Test Version",
                style: TextStyle(color: appTheme.textSubColor, fontFamily: "Poppins"),
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
            if (!widget.isDesktop)
              Container(
                margin: EdgeInsets.only(top: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ElevatedButton(
                        onPressed: downloadAndInstallUpdate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: appTheme.accentColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: BorderSide(
                              color: appTheme.accentColor,
                            ),
                          ),
                        ),
                        child: Container(
                          child: Text(
                            "download",
                            style: TextStyle(
                              color: appTheme.onAccent,
                              fontFamily: "Rubik",
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 5),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: appTheme.accentColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: BorderSide(
                              color: appTheme.accentColor,
                            ),
                          ),
                        ),
                        child: Container(
                          child: Text("nope",
                              style: TextStyle(
                                color: appTheme.onAccent,
                                fontFamily: "Rubik",
                                fontSize: 20,
                              )),
                        ),
                      ),
                    ),
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
