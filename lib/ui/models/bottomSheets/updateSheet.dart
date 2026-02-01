import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:http/http.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom, left: 15, right: 15, top: 10),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.pre)
              Text(
                "Test Version",
                style: TextStyle(color: appTheme.textSubColor, fontFamily: "Poppins"),
              ),
            Container(
              height: 400,
              child: ListView(
                shrinkWrap: true,
                children: [
                  MarkdownBody(
                    data: widget.markdownText,
                    styleSheet: MarkdownStyleSheet(
                      h1: style(),
                      h2: style(),
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
                        onPressed: () async {
                          final uri = Uri.parse(widget.downloadLink);
                          final buffer = <int>[];

                          _sub = await get(uri).asStream().listen((res) {
                            buffer.addAll(res.bodyBytes);
                          });

                          final tempPath = await getTemporaryDirectory();
                          final downloadPath = "${tempPath.path}/animestream_update.${Platform.isWindows ? "exe" : "apk"}";

                          await File(downloadPath).writeAsBytes(buffer);

                          final openRes = await OpenFile.open(downloadPath);
                          if (openRes.type == ResultType.done) {
                            print("OK! stuff's done");
                          }
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
                          child: Text("maybe later",
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

  TextStyle style() {
    return TextStyle(color: appTheme.textMainColor, fontFamily: "NotoSans");
  }
}
