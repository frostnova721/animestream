import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/ui/models/bottomSheets/manualSearchSheet.dart';
import 'package:animestream/ui/models/bottomSheets/serverSelectionSheet.dart';
import 'package:animestream/ui/models/providers/infoProvider.dart';
import 'package:animestream/ui/models/sources.dart';
import 'package:animestream/ui/models/widgets/appWrapper.dart';
import 'package:animestream/ui/models/widgets/infoPageWidgets/commonInfo.dart';
import 'package:animestream/ui/models/widgets/infoPageWidgets/episodeGrid.dart';
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
                      // if (size.width < splitWidth)
                      //   Container(
                      //     width: size.width / 2,
                      //     child: Row(
                      //       children: [_sourceSection(context), _continueWatchingBodyWidget(context)],
                      //     ),
                      //   ),
                      _episodes(),
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
                  _sourceSection(context, isSideWidget: true),
                  _continueWatching(context),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // Container _continueWatchingBodyWidget(BuildContext context) {
  //   return Container(
  //     child: InkWell(
  //       child: Container(
  //         decoration: BoxDecoration(
  //           image: DecorationImage(
  //               image: CachedNetworkImageProvider(
  //                 provider.data.banner ?? provider.data.cover,
  //               ),
  //               fit: BoxFit.cover),
  //         ),
  //         child: Center(
  //           child: Text(
  //               "Continue Episode ${provider.watched >= provider.epLinks.length ? provider.watched : provider.watched + 1}"),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Container _continueWatching(BuildContext context) {
    final ValueNotifier<bool> hovered = ValueNotifier(false);
    return Container(
      margin: EdgeInsets.only(left: 50),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: appTheme.backgroundSubColor,
      ),
      child: Column(
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (event) => hovered.value = true,
            onExit: (event) => hovered.value = false,
            child: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return Dialog(
                      backgroundColor: appTheme.backgroundColor,
                      child: Container(
                        padding: EdgeInsets.all(20),
                        width: size.width / 3,
                        child: ServerSelectionBottomSheet(
                          provider: provider,
                          episodeIndex: provider.watched,
                          type: ServerSheetType.watch,
                        ),
                      ),
                    );
                  },
                );
              },
              child: ValueListenableBuilder(
                valueListenable: hovered,
                builder: (context, value, child) => Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: value
                          ? Border.all(color: appTheme.accentColor, strokeAlign: BorderSide.strokeAlignOutside)
                          : null,
                    ),
                    height: 130,
                    child: Stack(
                      alignment: Alignment.center,
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          provider.data.banner ?? provider.data.cover,
                          fit: BoxFit.cover,
                          opacity: AlwaysStoppedAnimation(0.5),
                        ),
                        Icon(
                          Icons.play_arrow_rounded,
                          size: 40,
                        ),
                        Container(
                            padding: EdgeInsets.only(bottom: 15),
                            alignment: Alignment.bottomCenter,
                            child: Text(
                              "${provider.started ? 'Continue' : 'Start'} Watching",
                              style: TextStyle(fontFamily: "Rubik"),
                            )),
                      ],
                    )),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 15),
            child: Text(
              "Episode ${provider.watched >= provider.epLinks.length ? provider.watched : provider.watched + 1}",
              style: _textStyle().copyWith(fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }

  Container _episodes() {
    return Container(
      margin: EdgeInsets.only(top: 50, bottom: 50),
      height: (size.height / 1.75),
      width: size.width / (size.width > splitWidth ? 1.75 : 1.3),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: appTheme.backgroundSubColor,
      ),
      child: provider.foundName == null
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              spacing: 30,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Episode",
                        style: _textStyle(),
                      ),
                      if (provider.visibleEpList.isNotEmpty)
                        Row(
                          children: [
                            IconButton.outlined(
                              onPressed: () {
                                if (provider.currentPageIndex == 0) return;
                                provider.currentPageIndex -= 1;
                              },
                              icon: Icon(
                                Icons.arrow_back_ios_rounded,
                                color: appTheme.textMainColor,
                              ),
                              style: ButtonStyle(
                                shape: WidgetStatePropertyAll(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: GestureDetector(
                                onTap: () {
                                  showDialog(
                                      context: AppWrapper.navKey.currentContext!,
                                      builder: (ctx) => Dialog(
                                            backgroundColor: appTheme.backgroundColor,
                                            child: Container(
                                              width: size.width / 3,
                                              height: size.height / 2,
                                              alignment: Alignment.center,
                                              padding: EdgeInsets.all(30),
                                              child: GridView(
                                                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                                                  maxCrossAxisExtent: 100,
                                                  mainAxisExtent: 75,
                                                  mainAxisSpacing: 20,
                                                  crossAxisSpacing: 20,
                                                ),
                                                children: List.generate(
                                                    provider.visibleEpList.length,
                                                    (ind) => GestureDetector(
                                                          onTap: () {
                                                            provider.currentPageIndex = ind;
                                                            Navigator.of(ctx).pop();
                                                          },
                                                          child: Container(
                                                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                                            decoration: BoxDecoration(
                                                                color: provider.currentPageIndex == ind
                                                                    ? appTheme.accentColor
                                                                    : appTheme.backgroundSubColor,
                                                                borderRadius: BorderRadius.circular(10)),
                                                            alignment: Alignment.center,
                                                            child: Text(
                                                              "${provider.visibleEpList[ind].first['realIndex'] + 1}" +
                                                                  "- ${provider.visibleEpList[ind].last['realIndex'] + 1}",
                                                              style: TextStyle(
                                                                color: provider.currentPageIndex == ind
                                                                    ? appTheme.onAccent
                                                                    : appTheme.textMainColor,
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 17,
                                                              ),
                                                            ),
                                                          ),
                                                        )),
                                              ),
                                            ),
                                          ));
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  decoration: BoxDecoration(
                                      color: appTheme.accentColor, borderRadius: BorderRadius.circular(10)),
                                  child: Text(
                                    "${provider.visibleEpList[provider.currentPageIndex].first['realIndex'] + 1}" +
                                        "- ${provider.visibleEpList[provider.currentPageIndex].last['realIndex'] + 1}",
                                    style:
                                        TextStyle(color: appTheme.onAccent, fontWeight: FontWeight.bold, fontSize: 17),
                                  ),
                                ),
                              ),
                            ),
                            IconButton.outlined(
                              onPressed: () {
                                if (provider.currentPageIndex >= provider.visibleEpList.length - 1) return;
                                provider.currentPageIndex += 1;
                              },
                              icon: Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: appTheme.textMainColor,
                              ),
                              style: ButtonStyle(
                                shape: WidgetStatePropertyAll(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      Row(
                        children: [
                          IconButton(
                              style: ButtonStyle(
                                backgroundColor: WidgetStatePropertyAll(
                                    provider.viewMode == 0 ? appTheme.accentColor : Colors.transparent),
                              ),
                              onPressed: () {
                                provider.viewMode = 0;
                              },
                              icon: Icon(
                                Icons.view_list,
                                color: provider.viewMode == 0 ? appTheme.onAccent : appTheme.textMainColor,
                              )),
                          IconButton(
                              style: ButtonStyle(
                                backgroundColor: WidgetStatePropertyAll(
                                    provider.viewMode == 1 ? appTheme.accentColor : Colors.transparent),
                              ),
                              onPressed: () {
                                provider.viewMode = 1;
                              },
                              icon: Icon(
                                Icons.grid_view_sharp,
                                color: provider.viewMode == 1 ? appTheme.onAccent : appTheme.textMainColor,
                              )),
                          IconButton(
                              style: ButtonStyle(
                                backgroundColor: WidgetStatePropertyAll(
                                    provider.viewMode == 2 ? appTheme.accentColor : Colors.transparent),
                              ),
                              onPressed: () {
                                provider.viewMode = 2;
                              },
                              icon: Icon(
                                Icons.grid_on_sharp,
                                color: provider.viewMode == 2 ? appTheme.onAccent : appTheme.textMainColor,
                              )),
                        ],
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: provider.visibleEpList.isEmpty
                      ? Center(child: Text("No episodes!"))
                      : InfoPageEpisodeGrid(provider: provider, size: size),
                ),
              ],
            ),
    );
  }

  Container _sourceSection(BuildContext context, {bool isSideWidget = false}) {
    String sourceMatchString = "Searching... ";
    if (provider.foundName != null) {
      sourceMatchString =
          "Matching title ${(provider.foundName == provider.data.title['english']) || (provider.foundName == provider.data.title['romaji']) ? "found" : "not found"}. ";
    }
    return Container(
      margin: EdgeInsets.only(top: isSideWidget ? 0 : 50, left: isSideWidget ? 50 : 0, bottom: isSideWidget ? 30 : 0),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: appTheme.backgroundSubColor,
      ),
      child: Column(
        children: [
          Text(
            "Source",
            style: _textStyle(),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Temporary. will be replaced later (Hopefully)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20),
                margin: EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                    border: Border.all(color: appTheme.textMainColor), borderRadius: BorderRadius.circular(10)),
                child: DropdownButton<String>(
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: appTheme.textMainColor,
                  ),
                  underline: SizedBox.shrink(),
                  padding: EdgeInsets.all(0),
                  onChanged: (val) {
                    if (val != null) provider.selectedSource = val;
                    provider.getEpisodes();
                  },
                  value: provider.selectedSource,
                  items: List.generate(
                    sources.length,
                    (ind) => DropdownMenuItem(
                      child: Text(sources[ind]),
                      value: sources[ind],
                    ),
                  ),
                ),
              )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            // mainAxisSize: MainAxisSize.min,
            children: [
              Text(sourceMatchString),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    final title = provider.data.title['english'] ?? provider.data.title['romaji'] ?? "no bs";
                    showDialog(
                      context: context,
                      builder: (context) {
                        return Dialog(
                          backgroundColor: appTheme.backgroundColor,
                          child: Container(
                            padding: EdgeInsets.all(20),
                            width: size.width / 3,
                            height: size.height / 2,
                            child: ManualSearchSheet(
                                searchString: title,
                                source: provider.selectedSource,
                                anilistId: provider.id.toString()),
                          ),
                        );
                      },
                    ).then((result) async {
                      if (result == null) return;
                      provider.epSearcherror = false;
                      provider.foundName = null;
                      final links = await getAnimeEpisodes(provider.selectedSource, result['alias']);

                      provider.paginate(links);
                      provider.foundName = result['name'];
                    });
                  },
                  child: Text(
                    "Manual search",
                    style: TextStyle(
                      color: Colors.transparent,
                      decoration: TextDecoration.underline,
                      decorationColor: appTheme.textMainColor,
                      decorationStyle: TextDecorationStyle.solid,
                      decorationThickness: 2,
                      fontFamily: "NotoSans",
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: appTheme.textMainColor, offset: Offset(0, -2))],
                    ),
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  TextStyle _textStyle() => TextStyle(fontSize: 25, fontWeight: FontWeight.bold);
}
