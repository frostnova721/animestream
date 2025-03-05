import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/ui/models/bottomSheets/manualSearchSheet.dart';
import 'package:animestream/ui/models/bottomSheets/serverSelectionSheet.dart';
import 'package:animestream/ui/models/providers/infoProvider.dart';
import 'package:animestream/ui/models/sources.dart';
import 'package:animestream/ui/models/widgets/infoPageWidgets/commonInfo.dart';
import 'package:animestream/ui/pages/info/infoDesktop.dart';
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
                      _episodes(),
                    ],
                  ),
                ],
              ),
              if (size.width < splitWidth) Container()
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
                  if (provider.selectedEpisodeToLoadStreams != null) _selectedEpisodeBox()
                ],
              ),
            ),
          ),
      ],
    );
  }

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
                              "Continue Watching",
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
              "Episode ${provider.watched + 1}",
              style: _textStyle().copyWith(fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }

  Container _selectedEpisodeBox() {
    return Container(
      child: SourceSelectionDialog(sources: provider.streamSources),
        // margin: EdgeInsets.only(left: 50, top: 30),
        // padding: EdgeInsets.all(15),
        // decoration: BoxDecoration(
        //   borderRadius: BorderRadius.circular(15),
        //   color: appTheme.backgroundSubColor,
        // ),
        // child: Column(
        //   mainAxisSize: MainAxisSize.min,
        //   children: [
        //     Text("Sources: Episode ${provider.selectedEpisodeToLoadStreams! + 1}"),
        //     ListView.builder(
        //       itemCount: provider.streamSources.length,
        //       shrinkWrap: true,
        //       itemBuilder: (context, index) {
        //         final stream = provider.streamSources[index];
        //         return Column(
        //           mainAxisSize: MainAxisSize.min,
        //           children: [
        //             Text(stream.server),
        //             Text(stream.quality),
        //           ],
        //         );
        //       },
        //     ),
        //   ],
        // ),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Episode",
                      style: _textStyle(),
                    ),
                    if (provider.visibleEpList.isNotEmpty)
                      Container(
                        child: Text("${provider.visibleEpList[provider.currentPageIndex].first['realIndex'] + 1}" +
                            "- ${provider.visibleEpList[provider.currentPageIndex].last['realIndex'] + 1}"),
                      ),
                  ],
                ),
                Expanded(
                  child: provider.visibleEpList.isEmpty
                      ? Container(child: Text("No episodes!"))
                      : GridView.builder(
                          itemCount: provider.visibleEpList[provider.currentPageIndex].length,
                          gridDelegate:
                              SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 350, mainAxisExtent: 150),
                          itemBuilder: (context, index) {
                            final ValueNotifier<bool> hovered = ValueNotifier<bool>(false);
                            return Container(
                              margin: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: appTheme.backgroundColor,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  provider.selectedEpisodeToLoadStreams = index;
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
                                            episodeIndex: index,
                                            type: ServerSheetType.watch,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                                child: MouseRegion(
                                  onEnter: (event) => hovered.value = true,
                                  onExit: (event) => hovered.value = false,
                                  child: ValueListenableBuilder(
                                    valueListenable: hovered,
                                    builder: (context, value, child) {
                                      // Subject to change
                                      return Row(
                                        spacing: 5,
                                        children: [
                                          Container(
                                            clipBehavior: Clip.antiAlias,
                                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
                                            margin: EdgeInsets.all(10),
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Image.network(
                                                  provider.data.cover,
                                                  fit: BoxFit.cover,
                                                  opacity: AlwaysStoppedAnimation(hovered.value ? 0.4 : 1),
                                                ),
                                                if (hovered.value)
                                                  Center(
                                                      child: Icon(
                                                    Icons.play_arrow_rounded,
                                                    size: 35,
                                                  ))
                                              ],
                                            ),
                                          ),
                                          Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                "Episode ${provider.visibleEpList[provider.currentPageIndex][index]['realIndex'] + 1}",
                                                style: _textStyle().copyWith(fontSize: 20),
                                              ),
                                              Row(
                                                children: [
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 15),
                                                    child: IconButton.outlined(
                                                      onPressed: () {
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
                                                                  episodeIndex: index,
                                                                  type: ServerSheetType.download,
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        );
                                                      },
                                                      icon: Icon(
                                                        Icons.download,
                                                        color: appTheme.textMainColor,
                                                      ),
                                                      style: ButtonStyle(
                                                        shape: WidgetStatePropertyAll(
                                                          RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(10)),
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                ],
                                              )
                                            ],
                                          )
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Container _sourceSection(BuildContext context, {bool isSideWidget = false}) {
    return Container(
      margin: EdgeInsets.only(left: isSideWidget ? 50 : 0, bottom: 30),
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
              // Temporary. will be replaced later (Hopeflly)
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
              Text(
                  "Matching title ${(provider.foundName == provider.data.title['english']) || (provider.foundName == provider.data.title['romaji']) ? "found" : "not found"}. "),
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
                            child: ManualSearchSheet(
                                searchString: title, source: provider.selectedSource, anilistId: provider.id.toString()),
                          ),
                        );
                      },
                    );
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
