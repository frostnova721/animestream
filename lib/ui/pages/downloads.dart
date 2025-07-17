import 'dart:io';

import 'package:animestream/core/anime/downloader/downloadManager.dart';
import 'package:animestream/core/anime/downloader/types.dart';
import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/extensions.dart';
import 'package:animestream/core/data/downloadHistory.dart';
import 'package:flutter/material.dart';

class DownloadsPage extends StatefulWidget {
  const DownloadsPage({super.key});

  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> with TickerProviderStateMixin {
  @override
  initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  late final TabController _tabController;
  int dc = 0;

  final DownloadManager _dm = DownloadManager();

  final _boxListenable = DownloadHistory.listenable;

  Future<void> _deleteDownload(DownloadHistoryItem item) async {
    await DownloadHistory.removeItem(item.id);
    final file = File(item.filePath!);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            final url =
                "https://vault-14.kwikie.ru/stream/14/04/949408bf3775e6800948c22550842b1147995c801349d3de960e76760b81de14/uwu.m3u8";
            // DownloadManager().addDownloadTask(url, "Down$dc");
            dc++;
            setState(() {});
          },
          child: Icon(Icons.run_circle_outlined),
        ),
        appBar: AppBar(
          title: Text(
            "Downloads",
            style: TextStyle(fontFamily: "Rubik", fontWeight: FontWeight.bold, fontSize: 24),
          ),
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back_rounded,
              size: 28,
              color: appTheme.textMainColor,
            ),
          ),
          surfaceTintColor: Colors.transparent,
          backgroundColor: appTheme.backgroundColor,
        ),
        body: Container(
          // padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                tabAlignment: TabAlignment.center,
                isScrollable: true,
                indicatorColor: appTheme.accentColor,
                overlayColor: WidgetStatePropertyAll(appTheme.accentColor.withValues(alpha: 0.3)),
                labelColor: appTheme.textMainColor,
                unselectedLabelColor: appTheme.textSubColor,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: "NotoSans",
                ),
                tabs: [_tabBarItem("Downloading"), _tabBarItem("Downloaded")],
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      left: MediaQuery.paddingOf(context).left, right: MediaQuery.paddingOf(context).right),
                  child: TabBarView(controller: _tabController, children: [
                    _buildDownloading(),
                    _buildDownloaded(),
                  ]),
                ),
              ),
            ],
          ),
        ));
  }

  Widget _buildDownloading() {
    return ValueListenableBuilder(
      valueListenable: DownloadManager.downloadsCount,
      builder: (ctx, val, child) => ListView.builder(
        itemCount: DownloadManager.downloadsCount.value,
        // itemCount: dc,
        padding: EdgeInsets.only(top: 16),
        itemBuilder: (context, index) {
          // final it = DownloadItem(
          //     id: dc,
          //     url: "",
          //     status: DownloadStatus.downloading,
          //     fileName: "That Time I Got Reincarnated as a Slime EP ${"$dc".padLeft(2, '0')}");
          // return _downloadItem2(it);
          return _downloadItem2(DownloadManager.downloadingItems[index]);
        },
      ),
    );
  }

  Widget _buildDownloaded() {
    return ValueListenableBuilder(
        valueListenable: _boxListenable,
        builder: (context, box, child) {
          final values = DownloadHistory.getDownloadHistory(status: DownloadStatus.completed);
          return ListView.builder(
            itemCount: values.length,
            padding: EdgeInsets.only(top: 16),
            itemBuilder: (context, index) {
              return _downloadedItem(values[index]);
            },
          );
        });
  }

  Container _tabBarItem(String label) {
    return Container(
      alignment: Alignment.center,
      height: 50,
      child: Text(
        label,
        style: TextStyle(
          fontFamily: "NunitoSans",
          fontWeight: FontWeight.w700,
          fontSize: 17,
        ),
      ),
    );
  }

  Widget _downloadedItem(DownloadHistoryItem item) {
    return Container(
      decoration: BoxDecoration(color: appTheme.backgroundSubColor, borderRadius: BorderRadius.circular(12)),
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      margin: EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Container(
              child: Icon(
                Icons.play_arrow_rounded,
                size: 35,
              ),
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.only(right: 15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: appTheme.backgroundColor.withAlpha(130),
              ),
            ),
          ),
          Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.fileName,
                    style: _titleStyle(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Text(
                      item.status.name + " • ${_toMegs(item.size)} MB",
                      style: TextStyle(fontFamily: "Rubik", color: appTheme.textSubColor),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.only(right: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: IconButton.filled(
                              onPressed: () {
                                // Video play logic!
                              },
                              icon: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.open_in_new),
                                  Text(
                                    "Open",
                                    style: TextStyle(
                                        fontFamily: "NotoSans", fontWeight: FontWeight.bold, color: appTheme.onAccent),
                                  )
                                ],
                              ),
                              style: _iconButtonStyle(),
                            ),
                          ),
                        ),
                        Expanded(
                          child: IconButton.filled(
                            onPressed: () {
                              showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                        title: Text("You Sure?"),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: Text("no"),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              await _deleteDownload(item);
                                              Navigator.pop(context);
                                            },
                                            style: TextButton.styleFrom(
                                              backgroundColor: appTheme.accentColor,
                                              foregroundColor: appTheme.onAccent,
                                            ),
                                            child: Text("Yes"),
                                          ),
                                        ],
                                        content: Padding(
                                          padding: const EdgeInsets.all(5),
                                          child: Text('Are you sure to delete "${item.fileName}" from your device?'),
                                        ),
                                      ));
                            },
                            icon: Icon(Icons.delete),
                            style: _iconButtonStyle(),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              )),
        ],
      ),
    );
  }

  Widget _downloadItem2(DownloadItem item) {
    return Container(
      decoration: BoxDecoration(color: appTheme.backgroundSubColor, borderRadius: BorderRadius.circular(12)),
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      margin: EdgeInsets.all(8),
      child: ValueListenableBuilder(
        valueListenable: item.statusNotifier,
        builder: (context, status, child) => Row(
          children: [
            Expanded(
              flex: 1,
              child: Container(
                child: ValueListenableBuilder(
                  valueListenable: item.progressNotifier,
                  builder: (context, progress, child) => Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Center(
                          child: CircularProgressIndicator(
                            year2023: false,
                            value: item.progress / 100,
                          ),
                        ),
                      ),
                      Text(
                        "$progress%",
                        style: TextStyle(fontFamily: "NotoSans", fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                ),
                padding: EdgeInsets.all(16),
                margin: EdgeInsets.only(right: 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: appTheme.backgroundColor.withAlpha(130),
                ),
              ),
            ),
            Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.fileName,
                      style: _titleStyle(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Text(
                        item.status.name + " • ?? MB",
                        style: TextStyle(fontFamily: "Rubik", color: appTheme.textSubColor),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.only(right: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: IconButton.filled(
                                onPressed: () {
                                  if (status.isPaused)
                                    _dm.resumeDownload(item.id);
                                  else
                                    _dm.pauseDownload(item.id);
                                },
                                icon: Icon(status.isPaused ? Icons.play_arrow_rounded : Icons.pause),
                                style: _iconButtonStyle(),
                              ),
                            ),
                          ),
                          Expanded(
                            child: IconButton.filled(
                              onPressed: () {
                                _dm.cancelDownload(item.id);
                              },
                              icon: Icon(Icons.close),
                              style: _iconButtonStyle(),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                )),
          ],
        ),
      ),
    );
  }

  Widget _downloadItem(DownloadItem downloadingItem) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: appTheme.backgroundSubColor.withAlpha(150),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      padding: EdgeInsets.all(8),
      child: ValueListenableBuilder(
        valueListenable: downloadingItem.statusNotifier,
        builder: (context, status, child) => Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: appTheme.backgroundSubColor,
                borderRadius: BorderRadius.circular(8),
              ),
              margin: EdgeInsets.only(right: 5),
              clipBehavior: Clip.hardEdge,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (downloadingItem.isPaused) {
                      _dm.resumeDownload(downloadingItem.id);
                    } else {
                      _dm.pauseDownload(downloadingItem.id);
                    }

                    setState(() {});
                  },
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Icon(status == DownloadStatus.downloading ? Icons.pause_rounded : Icons.download_rounded),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Text(
                        downloadingItem.fileName,
                        style: _titleStyle(),
                        maxLines: 2,
                      ),
                    ),
                    ValueListenableBuilder(
                        valueListenable: downloadingItem.progressNotifier,
                        builder: (context, value, child) {
                          return downloadingItem.status == DownloadStatus.downloading
                              ? LinearProgressIndicator(
                                  year2023: false,
                                  value: downloadingItem.progress / 100,
                                  color: appTheme.accentColor,
                                )
                              : Text(
                                  downloadingItem.status.name,
                                  style:
                                      TextStyle(fontFamily: "NunitoSans", fontSize: 14, color: appTheme.textSubColor),
                                );
                        }),
                  ],
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                _dm.cancelDownload(downloadingItem.id);
                dc--;
                setState(() {});
              },
              icon: Icon(
                Icons.close,
                color: appTheme.textMainColor,
              ),
            )
          ],
        ),
      ),
    );
  }

  String _toMegs(int sizeInBytes) => (sizeInBytes / (1024 * 1024)).toStringAsFixed(1);

  TextStyle _titleStyle() => TextStyle(fontFamily: "NunitoSans", fontWeight: FontWeight.bold, fontSize: 18);

  ButtonStyle _iconButtonStyle() => IconButton.styleFrom(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      backgroundColor: appTheme.accentColor);
}
