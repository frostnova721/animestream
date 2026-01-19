import 'dart:io';

import 'package:animestream/core/anime/downloader/downloaderHelper.dart';
import 'package:animestream/core/app/logging.dart';
import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:flutter/material.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  final loggers = [
    Logs.app,
    Logs.downloader,
    Logs.player,
  ];

  final loggerMap = {
    "APP": Logs.app,
    "DOWNLOADER": Logs.downloader,
    "PLAYER": Logs.player,
  };

  Set<String> selectedLogger = {Logs.app.tag};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.arrow_back,
              color: appTheme.textMainColor,
            )),
        title: Text(
          "Logs",
          style: TextStyle(fontFamily: "Rubik", color: appTheme.textMainColor),
        ),
        actionsPadding: EdgeInsets.only(right: 14),
        actions: [
          // IconButton(
          //   icon: Icon(
          //     Icons.list,
          //     color: appTheme.textMainColor,
          //   ),
          //   onPressed: () {},
          //   tooltip: "Show logs",
          // ),
          IconButton(
            icon: Icon(
              Icons.save,
              color: appTheme.textMainColor,
            ),
            onPressed: () async {
             final downloadPath = await DownloaderHelper().getDownloadsPath();
             final dir = Directory(downloadPath + "/logs/${Logs.app.session}/");
             await dir.create(recursive: true);
             for(final l in loggers) {
              l.log("Saving ${l.tag} log");
              await File(dir.path + "/${l.tag}.txt").writeAsString(l.logNotifier.value.join("\n"), mode: FileMode.append);
             }

             floatingSnackBar("Logs saved to your downloads folder!");
            },
            tooltip: "Save logs",
          ),
        ],
        backgroundColor: appTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
      ),
      body: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        child: Column(
          children: [
            SegmentedButton(
                showSelectedIcon: false,
                segments: [
                  for (final l in loggers)
                    ButtonSegment(
                      value: l.tag,
                      label: Text(
                        "${l.tag}",
                      ),
                    ),
                ],
                selected: selectedLogger,
                onSelectionChanged: (e) {
                  setState(() {
                    selectedLogger = e;
                  });
                }),
            Expanded(
              // flex: 5,
              child: Container(
                margin: EdgeInsets.all(10),
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                    border: Border.all(
                      color: appTheme.textSubColor,
                    ),
                    borderRadius: BorderRadius.circular(25)),
                child: ValueListenableBuilder(
                  valueListenable: loggerMap[selectedLogger.first]!.logNotifier,
                  builder: (context, logs, child) {
                    return logs.isNotEmpty
                        ? ListView.builder(
                            itemCount: logs.length,
                            itemBuilder: (ctx, index) {
                              return Text(logs[index], style: _logsTextStyle());
                            })
                        : Center(
                            child: Text(
                              "No Logs On This Yet!",
                              style: _logsTextStyle(),
                            ),
                          );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _logsTextStyle() {
    return TextStyle(
      fontFamily: "NunitoSans",
      fontSize: 14,
    );
  }
}
