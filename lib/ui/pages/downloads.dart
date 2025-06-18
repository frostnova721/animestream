import 'dart:math';

import 'package:animestream/core/anime/downloader/downloader.dart';
import 'package:animestream/core/anime/downloader/types.dart';
import 'package:animestream/core/app/runtimeDatas.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(onPressed: () {
        Downloader().mockDownload(DownloadingItem(id: Random().nextInt(100), status: DownloadStatus.downloading, fileName: "Apothe niggas sd sdf sdffg hgdr5t wersdsg sfdg Ep 1"), Duration(seconds: 60));
      }, child: Icon(Icons.run_circle_outlined),),
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
                child: TabBarView(controller: _tabController, children: [
                  _buildDownloading(),
                  _buildDownloaded(),
                ]),
              ),
            ],
          ),
        ));
  }

  Widget _buildDownloading() {
    return ValueListenableBuilder(
      valueListenable: Downloader.downloadCount,
      builder: (ctx, val, child) => ListView.builder(
        itemCount: Downloader.downloadingItems.length,
        itemBuilder: (context, index) {
          return _downloadItem(Downloader.downloadingItems[index]);
        },
      ),
    );
  }

  Widget _buildDownloaded() {
    return ListView.builder(
      itemBuilder: (context, index) {

      },
    );
  }

  Container _tabBarItem(String label) {
    return Container(
      alignment: Alignment.center,
      height: 50,
      child: Text(
        label,
        style: TextStyle(
          fontFamily: "NotoSans-Bold",
          fontSize: 17,
        ),
      ),
    );
  }

  Widget _downloadItem(DownloadingItem downloadingItem) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            margin: EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: appTheme.backgroundSubColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.download),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Text(
                      downloadingItem.fileName,
                      style: TextStyle(fontFamily: "NunitoSans", fontWeight: FontWeight.bold, fontSize: 18),
                      maxLines: 2,
                    ),
                  ),
                  ValueListenableBuilder(
                    valueListenable: downloadingItem.progressNotifier,
                    builder: (context, value, child) {
                      return downloadingItem.status == DownloadStatus.downloading ? LinearProgressIndicator(
                        value: downloadingItem.progress / 100
                      ) : Text("queued", style: TextStyle(fontFamily: "NunitoSans", fontSize: 14, color: appTheme.textSubColor),);
                    }
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              Downloader.cancelDownload(downloadingItem.id);
            },
            icon: Icon(Icons.close, color: appTheme.textMainColor,),
          )
        ],
      ),
    );
  }
}
