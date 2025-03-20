import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/ui/models/providers/infoProvider.dart';
import 'package:animestream/ui/models/widgets/appWrapper.dart';
import 'package:animestream/ui/models/widgets/infoPageWidgets/commonInfo.dart';
import 'package:animestream/ui/models/widgets/infoPageWidgets/continueBoxes.dart';
import 'package:animestream/ui/models/widgets/infoPageWidgets/episodeGrid.dart';
import 'package:animestream/ui/models/widgets/infoPageWidgets/sourceBoxes.dart';
import 'package:flutter/material.dart';

class WatchSection extends StatelessWidget {
  final InfoProvider provider;
  final Size size;
  final int splitWidth;
  const WatchSection({super.key, required this.provider, required this.size, required this.splitWidth});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: size.width / 10, top: 30),
          child: Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start, // Align the row contents to the top
                children: [
                  Column(
                    children: [
                      CommonInfo(
                        provider: provider,
                      ),
                      if (size.width < splitWidth)
                        Container(
                          width: size.width / 2,
                          margin: EdgeInsets.only(top: 50),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 1,
                                child: SourceBodyWidget(provider: provider),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                flex: 1,
                                child: ContinueWatchingBodyBox(provider: provider,),
                              ),
                            ],
                          ),
                        ),
                      buildEpisodesContainer(context),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        if (size.width >= splitWidth)
          Expanded(
            child: Container(
              padding: EdgeInsets.only(top: 30, right: size.width / 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SourceSideWidget(
                    provider: provider,
                  ),
                  ContinueWatchingSideBox(
                    provider: provider,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget buildEpisodesContainer(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 20).copyWith(top: 50),
      height: (size.height / 1.75),
      width: size.width / (size.width > splitWidth ? 1.75 : 1.3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: appTheme.backgroundSubColor,
      ),
      child: provider.foundName == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: appTheme.accentColor,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Loading episodes...",
                    style: TextStyle(
                      color: appTheme.textMainColor.withAlpha(204),
                      fontFamily: "Poppins",
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        appTheme.accentColor.withAlpha(50),
                        appTheme.accentColor.withAlpha(15),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.video_library_rounded,
                            size: 18,
                            color: appTheme.accentColor,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Episodes",
                            style: TextStyle(
                              color: appTheme.textMainColor,
                              fontFamily: "Poppins",
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: appTheme.accentColor.withAlpha(70),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.playlist_play_rounded,
                          color: appTheme.accentColor,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (provider.visibleEpList.isNotEmpty)
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: appTheme.textMainColor.withAlpha(15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  onPressed: () {
                                    if (provider.currentPageIndex == 0) return;
                                    provider.currentPageIndex -= 1;
                                  },
                                  icon: Icon(
                                    Icons.arrow_back_ios_rounded,
                                    color: appTheme.textMainColor,
                                    size: 16,
                                  ),
                                  tooltip: "Previous page",
                                ),
                              ),
                              SizedBox(width: 10),
                              GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: AppWrapper.navKey.currentContext!,
                                    builder: (ctx) => Dialog(
                                      backgroundColor: appTheme.backgroundColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Container(
                                        width: size.width / 3,
                                        height: size.height / 2,
                                        alignment: Alignment.center,
                                        padding: EdgeInsets.all(24),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(left: 8, bottom: 16),
                                              child: Text(
                                                "Select Episode Range",
                                                style: TextStyle(
                                                  color: appTheme.textMainColor,
                                                  fontFamily: "Poppins",
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: GridView(
                                                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                                                  maxCrossAxisExtent: 100,
                                                  mainAxisExtent: 75,
                                                  mainAxisSpacing: 16,
                                                  crossAxisSpacing: 16,
                                                ),
                                                children: List.generate(
                                                  provider.visibleEpList.length,
                                                  (ind) => GestureDetector(
                                                    onTap: () {
                                                      provider.currentPageIndex = ind;
                                                      Navigator.of(ctx).pop();
                                                    },
                                                    child: Container(
                                                      padding: EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 10,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: provider.currentPageIndex == ind
                                                            ? appTheme.accentColor
                                                            : appTheme.backgroundSubColor,
                                                        borderRadius: BorderRadius.circular(14),
                                                        border: Border.all(
                                                          color: provider.currentPageIndex == ind
                                                              ? appTheme.accentColor
                                                              : appTheme.textMainColor.withAlpha(60),
                                                          width: 1,
                                                        ),
                                                        boxShadow: provider.currentPageIndex == ind
                                                            ? [
                                                                BoxShadow(
                                                                  color: appTheme.accentColor.withAlpha(70),
                                                                  blurRadius: 8,
                                                                  offset: Offset(0, 2),
                                                                ),
                                                              ]
                                                            : null,
                                                      ),
                                                      alignment: Alignment.center,
                                                      child: Text(
                                                        "${provider.visibleEpList[ind].first['realIndex'] + 1} - ${provider.visibleEpList[ind].last['realIndex'] + 1}",
                                                        style: TextStyle(
                                                          color: provider.currentPageIndex == ind
                                                              ? appTheme.onAccent
                                                              : appTheme.textMainColor,
                                                          fontWeight: FontWeight.w600,
                                                          fontSize: 15,
                                                          fontFamily: "Poppins",
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: appTheme.accentColor,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: appTheme.accentColor.withAlpha(70),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        "${provider.visibleEpList[provider.currentPageIndex].first['realIndex'] + 1} - ${provider.visibleEpList[provider.currentPageIndex].last['realIndex'] + 1}",
                                        style: TextStyle(
                                          color: appTheme.onAccent,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          fontFamily: "Poppins",
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Icon(
                                        Icons.arrow_drop_down,
                                        color: appTheme.onAccent,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Container(
                                decoration: BoxDecoration(
                                  color: appTheme.textMainColor.withAlpha(15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  onPressed: () {
                                    if (provider.currentPageIndex >= provider.visibleEpList.length - 1) return;
                                    provider.currentPageIndex += 1;
                                  },
                                  icon: Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: appTheme.textMainColor,
                                    size: 16,
                                  ),
                                  tooltip: "Next page",
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Expanded(
                          child: Container(),
                        ),
                      Container(
                        decoration: BoxDecoration(
                          color: appTheme.textMainColor.withAlpha(15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Row(
                          children: [
                            _buildViewModeButton(0, Icons.view_list),
                            _buildViewModeButton(1, Icons.grid_view_sharp),
                            _buildViewModeButton(2, Icons.grid_on_sharp),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: provider.visibleEpList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.video_library_rounded,
                                size: 48,
                                color: appTheme.textMainColor.withAlpha(100),
                              ),
                              SizedBox(height: 16),
                              Text(
                                "No episodes found",
                                style: TextStyle(
                                  color: appTheme.textMainColor.withAlpha(204),
                                  fontFamily: "Poppins",
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Try changing the source or using manual search",
                                style: TextStyle(
                                  color: appTheme.textMainColor.withAlpha(153),
                                  fontFamily: "Poppins",
                                  fontSize: 14,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: InfoPageEpisodeGrid(provider: provider, size: size),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildViewModeButton(int mode, IconData icon) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 2, vertical: 3),
      decoration: BoxDecoration(
        color: provider.viewMode == mode ? appTheme.accentColor : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        onPressed: () {
          provider.viewMode = mode;
        },
        style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        icon: Icon(
          icon,
          color: provider.viewMode == mode ? appTheme.onAccent : appTheme.textMainColor,
          size: 18,
        ),
        padding: EdgeInsets.all(8),
        constraints: BoxConstraints(
          minWidth: 36,
          minHeight: 36,
        ),
        tooltip: mode == 0
            ? "List view"
            : mode == 1
                ? "Grid view"
                : "Compact grid",
      ),
    );
  }
}
