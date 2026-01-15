import 'package:animestream/core/app/logging.dart';
import 'package:animestream/core/app/runtimeDatas.dart';
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
        title: Text(
          "Logs",
          style: TextStyle(fontFamily: "Rubik"),
        ),
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
                  for (final l in loggers) ButtonSegment(value: l.tag, label: Text("${l.tag}")),
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
