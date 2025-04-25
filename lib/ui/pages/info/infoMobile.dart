import 'package:animestream/core/anime/downloader/downloader.dart';
import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/data/types.dart';
import 'package:animestream/core/database/types.dart';
import 'package:animestream/ui/models/bottomSheets/manualSearchSheet.dart';
import 'package:animestream/ui/models/bottomSheets/mediaListStatus.dart';
import 'package:animestream/ui/models/bottomSheets/serverSelectionSheet.dart';
import 'package:animestream/ui/models/providers/infoProvider.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:animestream/ui/models/sources.dart';
import 'package:animestream/ui/models/widgets/cards.dart';
import 'package:animestream/ui/models/widgets/loader.dart';
import 'package:animestream/ui/pages/info.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class InfoMobile extends StatefulWidget {
  const InfoMobile({super.key});

  @override
  State<InfoMobile> createState() => _InfoMobileState();
}

class _InfoMobileState extends State<InfoMobile> {
  late InfoProvider provider;

  bool infoPage = true;

  FocusNode _watchInfoButtonFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    provider = context.watch<InfoProvider>();
    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      body: provider.infoLoadError
          ? Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'lib/assets/images/broken_heart.png',
                    scale: 7.5,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 15, left: 30, right: 30, bottom: 15),
                    child: const Text(
                      'oops! something went wrong',
                      style: TextStyle(
                          color: Colors.white, fontFamily: "NunitoSans", fontSize: 25, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appTheme.accentColor,
                      ),
                      child: Text(
                        "Go Back",
                        style: TextStyle(color: appTheme.backgroundColor, fontWeight: FontWeight.bold),
                      )),
                ],
              ),
            )
          : provider.dataLoaded
              ? CustomScrollView(
                  slivers: [
                    SliverList.list(
                      children: [
                        _stack(),
                        Container(
                          margin: EdgeInsets.only(top: 30),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                // width: 120,
                                child: ElevatedButton(
                                  focusNode: _watchInfoButtonFocusNode,
                                  onFocusChange: (val) {
                                    setState(() {});
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _watchInfoButtonFocusNode.hasFocus
                                        ? appTheme.textMainColor
                                        : appTheme.accentColor,
                                    fixedSize: Size(135, 55),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      infoPage = !infoPage;
                                    });
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        infoPage ? Icons.play_arrow_rounded : Icons.info_rounded,
                                        color: appTheme.onAccent,
                                        size: 28,
                                      ),
                                      Text(
                                        infoPage ? "watch" : " info",
                                        style: TextStyle(
                                          color: appTheme.onAccent,
                                          fontFamily: "Poppins",
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (provider.loggedIn)
                                Container(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      showModalBottomSheet(
                                        context: context,
                                        backgroundColor: appTheme.backgroundColor,
                                        showDragHandle: true,
                                        isScrollControlled: true,
                                        builder: (context) => MediaListStatusBottomSheet(
                                          provider: provider,
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      shape: CircleBorder(
                                        side: BorderSide(
                                          color: appTheme.accentColor,
                                        ),
                                      ),
                                      fixedSize: Size(50, 50),
                                      backgroundColor: appTheme.backgroundColor,
                                      padding: EdgeInsets.zero,
                                    ),
                                    child: Icon(
                                      InfoProvider.getTrackerIcon(provider.mediaListStatus),
                                      color: appTheme.accentColor,
                                      size: 28,
                                    ),
                                  ),
                                )
                            ],
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(top: 45),
                          padding: EdgeInsets.only(left: 20, right: 20),
                          alignment: Alignment.center,
                          // padding: EdgeInsets.only(left: 40, right: 25),
                          child: Text(
                            provider.data.title['english'] ?? provider.data.title['romaji'] ?? '',
                            style: TextStyle(
                              color: appTheme.textMainColor,
                              fontFamily: "NunitoSans",
                              fontSize: 25,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        AnimatedSwitcher(
                          duration: Duration(milliseconds: 200),
                          child: infoPage ? _infoItems(context) : _watchItems(context),
                        ),
                      ],
                    ),
                  ],
                )
              : Center(
                  child: AnimeStreamLoading(
                    color: appTheme.accentColor,
                  ),
                ),
    );
  }

  IconData viewModeIcon() {
    switch (provider.viewMode) {
      case 0:
        return Icons.grid_view_rounded;
      case 1:
        return Icons.view_module_rounded;
      case 2:
        return Icons.view_list_rounded;
      default:
        throw Exception("Unknown Index For Icon");
    }
  }

  GridView viewModeWidget() {
    switch (provider.viewMode) {
      case 0:
        return _episodes();
      case 1:
        return _episodesGrid();
      case 2:
        return _episodeTiles();
      default:
        throw Exception("Unknown Index For Icon");
    }
  }

  Column _watchItems(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.only(top: 30),
          child: DropdownMenu(
            initialSelection: provider.selectedSource,
            dropdownMenuEntries: getSourceDropdownList(),
            // menuHeight: 75,
            width: 300,
            textStyle: TextStyle(
              color: appTheme.textMainColor,
              fontFamily: "Poppins",
            ),
            trailingIcon: Icon(
              Icons.arrow_drop_down,
              color: appTheme.textMainColor,
            ),
            selectedTrailingIcon: Icon(
              Icons.arrow_drop_up,
              color: appTheme.textMainColor,
            ),
            menuStyle: MenuStyle(
              // surfaceTintColor: WidgetStatePropertyAll(backgroundSubColor),
              backgroundColor: WidgetStatePropertyAll(appTheme.backgroundColor),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  side: BorderSide(color: appTheme.textMainColor),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            onSelected: (value) {
              provider.selectedSource = value;
              setState(() {
                provider.getEpisodes();
              });
            },
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderSide: BorderSide(
                  width: 1,
                  color: appTheme.textMainColor,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: EdgeInsets.only(left: 20, right: 20),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  width: 1,
                  color: appTheme.textMainColor,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            label: Text(
              "source",
              style: TextStyle(
                  color: appTheme.textMainColor, fontSize: 20, fontFamily: "Rubik", overflow: TextOverflow.ellipsis),
            ),
          ),
        ),
        _searchStatus(),
        _manualSearch(context),
        if (provider.foundName != null && provider.epLinks.length > 0) _continueButton(),
        Container(
          margin: EdgeInsets.only(
              top: 25,
              left: 20 + MediaQuery.of(context).padding.left,
              right: 20 + MediaQuery.of(context).padding.right),
          padding: EdgeInsets.only(top: 15, bottom: 20),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: appTheme.backgroundSubColor),
          child: Column(
            children: [
              Container(
                height: 45,
                margin: EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                        padding: EdgeInsets.only(left: 20),
                        child: Text(
                          "Episodes",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            fontFamily: "Rubik",
                          ),
                        )),
                    if (provider.foundName != null)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          InkWell(
                            onTap: () => provider.preferDubs = !provider.preferDubs,
                            child: Container(
                              margin: EdgeInsets.all(2),
                              width: 40,
                              height: 25,
                              alignment: Alignment.center,
                              padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration:
                                  BoxDecoration(borderRadius: BorderRadius.circular(6), color: appTheme.textMainColor),
                              child: Text(provider.preferDubs ? "dub" : "sub",
                                  style: TextStyle(color: appTheme.backgroundColor, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: IconButton(
                              tooltip:
                                  "switch to ${UserPreferencesModal.getViewModeEnum((provider.viewMode + 1) % provider.viewModeIndexLength).name} view",
                              onPressed: () {
                                setState(() {
                                  provider.viewMode = (provider.viewMode + 1) % provider.viewModeIndexLength;
                                });
                              },
                              icon: Icon(
                                viewModeIcon(),
                              ),
                              color: appTheme.textMainColor,
                              iconSize: 28,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              provider.epSearcherror
                  ? Container(
                      width: 350,
                      height: 120,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'lib/assets/images/broken_heart.png',
                              scale: 7.5,
                            ),
                            Text(
                              "Couldnt get any results :(",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: "NunitoSans",
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : provider.foundName != null
                      ? Column(
                          children: [
                            _pages(),
                            AnimatedSwitcher(
                              duration: Duration(milliseconds: 400),
                              child: viewModeWidget(),
                            ),
                          ],
                        )
                      : Container(
                          width: 350,
                          height: 100,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: appTheme.accentColor,
                            ),
                          ),
                        ),
              // ),
            ],
          ),
        ),
      ],
    );
  }

  Container _manualSearch(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(right: 20, top: 15),
      alignment: Alignment.centerRight,
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            showDragHandle: true,
            backgroundColor: appTheme.modalSheetBackgroundColor,
            builder: (context) => ManualSearchSheet(
              searchString: provider.data.title['english'] ?? provider.data.title['romaji'] ?? '',
              source: provider.selectedSource,
              anilistId: provider.id.toString(),
            ),
          ).then((result) async {
            if (result == null) return;
            setState(() {
              provider.epSearcherror = false;
              provider.foundName = null;
            });
            final links = await getAnimeEpisodes(provider.selectedSource, result['alias']);
            if (mounted)
              setState(() {
                provider.paginate(links);
                provider.foundName = result['name'];
              });
          });
        },
        child: Text(
          "Manual Search",
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
    );
  }

  Container _pages() {
    return Container(
      height: 35,
      margin: EdgeInsets.only(bottom: 10, top: 10),
      padding: EdgeInsets.only(left: 10, right: 10),
      child: ListView.builder(
        itemCount: provider.visibleEpList.length,
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(left: 10),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: provider.currentPageIndex == index ? appTheme.accentColor : appTheme.backgroundColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      provider.currentPageIndex = index;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.only(
                      left: 10,
                      right: 10,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "${(index * 24) + 1} - ${(index * 24) + 24 > provider.epLinks.length ? provider.epLinks.length : (index * 24) + 24}",
                      style: TextStyle(
                        color: provider.currentPageIndex == index ? appTheme.onAccent : appTheme.textMainColor,
                        fontFamily: 'NotoSans',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Container _continueButton() {
    return Container(
      width: 325,
      margin: EdgeInsets.only(
        top: 25,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: appTheme.accentColor),
        image: DecorationImage(
          image: provider.data.banner != null ? NetworkImage(provider.data.banner!) : NetworkImage(provider.data.cover),
          fit: BoxFit.cover,
          opacity: 0.46,
        ),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        focusColor: appTheme.textSubColor,
        onLongPress: () {
          showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  actions: [
                    TextButton(onPressed: () => Navigator.of(context).pop(), child: Text("No")),
                    TextButton(
                      onPressed: () {
                        provider.clearLastWatchDuration();
                        Navigator.pop(context);
                      },
                      child: Text("Yes"),
                      style: TextButton.styleFrom(
                          backgroundColor: appTheme.accentColor, foregroundColor: appTheme.onAccent),
                    )
                  ],
                  content: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      "Clear watch progress for this episode?",
                      style: TextStyle(fontSize: 15),
                    ),
                  ),
                );
              });
        },
        onTap: () async {
          showModalBottomSheet(
            isScrollControlled: true,
            showDragHandle: true,
            backgroundColor: appTheme.modalSheetBackgroundColor,
            context: context,
            builder: (BuildContext context) {
              return ServerSelectionBottomSheet(
                provider: provider,
                episodeIndex: provider.watched,
                type: ServerSheetType.watch,
              );
            },
          ).then((val) {
            if (val == true) {
              provider.refreshListStatus("CURRENT", provider.watched);
            }
          });
        },
        child: Padding(
          padding: EdgeInsets.only(left: 20, right: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 325,
                height: 80,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${provider.started ? 'Continue' : 'Start'} from:',
                        style: TextStyle(
                          color: appTheme.textMainColor,
                          fontFamily: "Rubik",
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Episode ${provider.watched < provider.epLinks.length ? provider.watched + 1 : provider.watched}',
                        style: TextStyle(
                          color: appTheme.textMainColor,
                          fontFamily: "Rubik",
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (provider.lastWatchedDurationMap?[
                      provider.watched < provider.epLinks.length ? provider.watched + 1 : provider.watched] !=
                  null)
                Container(
                  width: 285 *
                      ((provider.lastWatchedDurationMap?[provider.watched < provider.epLinks.length
                                  ? provider.watched + 1
                                  : provider.watched] ??
                              0) /
                          100) as double,
                  height: 1.8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    color: appTheme.textMainColor,
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }

  Container _searchStatus() {
    String text = "searching: ${provider.data.title['english'] ?? provider.data.title['romaji'] ?? ''}";
    if (provider.foundName != null) {
      text = "found: ${provider.foundName}";
    } else if (provider.epSearcherror) {
      text = "couldnt't find any matches";
    }
    return Container(
      width: 300,
      margin: EdgeInsets.only(top: 5),
      padding: EdgeInsets.only(left: 8, right: 8),
      child: Text(
        text,
        style: TextStyle(
          color: appTheme.textMainColor,
          fontFamily: "NotoSans",
          fontWeight: FontWeight.bold,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  GridView _episodeTiles() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).orientation == Orientation.portrait ? 5 : 10,
      ),
      shrinkWrap: true,
      itemCount: provider.visibleEpList[provider.currentPageIndex].length,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(10),
      itemBuilder: (context, index) => GestureDetector(
        onLongPress: () {
          showModalBottomSheet(
              showDragHandle: true,
              context: context,
              builder: (ctx) => Container(
                    width: double.infinity,
                    padding: EdgeInsets.only(left: 20, right: 20, bottom: MediaQuery.paddingOf(ctx).bottom),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 16,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            "Select Action",
                            style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            ServerSheetType.values.length,
                            (ind) => Expanded(
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 5),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: appTheme.accentColor,
                                      foregroundColor: appTheme.backgroundColor,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                  onPressed: () async {
                                    Navigator.of(ctx).pop();
                                    showModalBottomSheet(
                                      showDragHandle: true,
                                      isScrollControlled: true,
                                      context: context,
                                      backgroundColor: appTheme.modalSheetBackgroundColor,
                                      builder: (BuildContext context) {
                                        return ServerSelectionBottomSheet(
                                          provider: provider,
                                          episodeIndex: provider.visibleEpList[provider.currentPageIndex][index]
                                              ['realIndex'],
                                          type: ServerSheetType.values[ind],
                                        );
                                      },
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    child: Text(
                                      ServerSheetType.values[ind].name,
                                      style: TextStyle(fontFamily: "Poppins", fontSize: 18),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox.shrink()
                      ],
                    ),
                  ));
        },
        onTap: () {
          showModalBottomSheet(
              showDragHandle: true,
              context: context,
              isScrollControlled: true,
              backgroundColor: appTheme.modalSheetBackgroundColor,
              builder: (context) {
                return ServerSelectionBottomSheet(
                  provider: provider,
                  episodeIndex: provider.visibleEpList[provider.currentPageIndex][index]['realIndex'],
                  type: ServerSheetType.watch,
                );
              }).then((val) {
            if (val == true) {
              provider.refreshListStatus("CURRENT", provider.watched);
            }
          });
        },
        child: Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: appTheme.backgroundColor,
          ),
          padding: EdgeInsets.all(7),
          margin: EdgeInsets.all(3),
          alignment: Alignment.center,
          child: Text(
            "${index + 1}",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }

  GridView _episodesGrid() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).orientation == Orientation.portrait ? 2 : 5,
        childAspectRatio: MediaQuery.of(context).orientation == Orientation.portrait ? 1 / 1.3 : 1 / 1.4,
        mainAxisSpacing: 15,
        crossAxisSpacing: 15,
      ),
      itemCount: provider.visibleEpList[provider.currentPageIndex].length,
      padding: EdgeInsets.all(15),
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) => Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: appTheme.backgroundColor,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              showModalBottomSheet(
                  showDragHandle: true,
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: appTheme.modalSheetBackgroundColor,
                  builder: (context) {
                    return ServerSelectionBottomSheet(
                      provider: provider,
                      episodeIndex: provider.visibleEpList[provider.currentPageIndex][index]['realIndex'],
                      type: ServerSheetType.watch,
                    );
                  }).then((val) {
                if (val == true) {
                  provider.refreshListStatus("CURRENT", provider.watched);
                }
              });
            },
            // child: Container(
            // padding: EdgeInsets.all(10),

            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Opacity(
                  opacity: provider.visibleEpList[provider.currentPageIndex][index]['realIndex'] + 1 > provider.watched
                      ? 1.0
                      : 0.5,
                  child: Container(
                    height: 140,
                    width: 175,
                    margin: EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      image: DecorationImage(
                          image: NetworkImage(
                            provider.data.cover,
                          ),
                          fit: BoxFit.cover),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (!unDownloadableSources.contains(provider.selectedSource))
                          Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.only(topLeft: Radius.circular(15)),
                                color: appTheme.accentColor.withValues(alpha: 0.8)),
                            child: IconButton(
                              onPressed: () async {
                                showModalBottomSheet(
                                  showDragHandle: true,
                                  isScrollControlled: true,
                                  context: context,
                                  backgroundColor: appTheme.modalSheetBackgroundColor,
                                  builder: (BuildContext context) {
                                    return ServerSelectionBottomSheet(
                                      provider: provider,
                                      episodeIndex: provider.visibleEpList[provider.currentPageIndex][index]
                                          ['realIndex'],
                                      type: ServerSheetType.download,
                                    );
                                  },
                                );
                              },
                              icon: Icon(
                                Icons.download_rounded,
                                color: Colors.black,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10, right: 10),
                  child: Text(
                    "Episode ${provider.visibleEpList[provider.currentPageIndex][index]['realIndex'] + 1}",
                    style: TextStyle(
                      color:
                          provider.visibleEpList[provider.currentPageIndex][index]['realIndex'] + 1 > provider.watched
                              ? appTheme.textMainColor
                              : appTheme.textSubColor,
                      fontFamily: 'Poppins',
                      fontSize: 17,
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  GridView _episodes() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.orientationOf(context) == Orientation.portrait ? 1 : 2,
          childAspectRatio: 3.2,
          mainAxisSpacing: 0,
          mainAxisExtent: 110),
      padding: EdgeInsets.only(top: 0, bottom: 15),
      itemCount: provider.visibleEpList[provider.currentPageIndex].length,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Stack(
          children: [
            Container(
              clipBehavior: Clip.hardEdge,
              height: 110,
              margin: EdgeInsets.only(top: 10, left: 10, right: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: appTheme.backgroundColor,
              ),
              alignment: Alignment.center,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    showModalBottomSheet(
                        showDragHandle: true,
                        isScrollControlled: true,
                        context: context,
                        backgroundColor: appTheme.modalSheetBackgroundColor,
                        builder: (context) {
                          return ServerSelectionBottomSheet(
                            provider: provider,
                            episodeIndex: provider.visibleEpList[provider.currentPageIndex][index]['realIndex'],
                            type: ServerSheetType.watch,
                          );
                        });
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Stack(
                      children: [
                        Opacity(
                          opacity: provider.visibleEpList[provider.currentPageIndex][index]['realIndex'] + 1 >
                                  provider.watched
                              ? 1.0
                              : 0.5,
                          child: ShaderMask(
                            blendMode: BlendMode.dstIn,
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [appTheme.backgroundColor, Colors.transparent],
                              stops: [0.6, 0.99],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ).createShader(bounds),
                            child: Image.network(
                              provider.data.cover,
                              fit: BoxFit.cover,
                              width: 165,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 140,
                            ),
                            Text(
                              "Episode ${provider.visibleEpList[provider.currentPageIndex][index]['realIndex'] + 1}",
                              style: TextStyle(
                                color: provider.visibleEpList[provider.currentPageIndex][index]['realIndex'] + 1 >
                                        provider.watched
                                    ? appTheme.textMainColor
                                    : appTheme.textSubColor,
                                fontFamily: "Poppins",
                                fontSize: 18,
                              ),
                            ),
                            if (!unDownloadableSources.contains(provider.selectedSource))
                              Container(
                                child: IconButton(
                                  onPressed: () async {
                                    showModalBottomSheet(
                                      showDragHandle: true,
                                      context: context,
                                      backgroundColor: appTheme.modalSheetBackgroundColor,
                                      isScrollControlled: true,
                                      builder: (BuildContext context) {
                                        return ServerSelectionBottomSheet(
                                          provider: provider,
                                          episodeIndex: provider.visibleEpList[provider.currentPageIndex][index]
                                              ['realIndex'],
                                          type: ServerSheetType.download,
                                        );
                                      },
                                    );
                                  },
                                  icon: Icon(
                                    Icons.download_rounded,
                                    color: appTheme.textMainColor,
                                  ),
                                ),
                              )
                            else
                              Container()
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (provider.watched > provider.visibleEpList[provider.currentPageIndex][index]['realIndex'])
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 20, right: 25),
                  child: ImageIcon(
                    AssetImage('lib/assets/images/check.png'),
                    color: appTheme.textMainColor,
                    size: 18,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Container _infoItems(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: 50),
            child: Column(
              children: [
                _buildInfoItems(
                  _infoLeft('Type'),
                  _infoRight(provider.data.type.toLowerCase()),
                ),
                _buildInfoItems(
                  _infoLeft('Status'),
                  _infoRight('${provider.data.status ?? '??'}'.toLowerCase().replaceAll("_", ' ')),
                ),
                _buildInfoItems(
                  _infoLeft('Rating'),
                  _infoRight('${provider.data.rating ?? '??'}/10'),
                ),
                _buildInfoItems(
                  _infoLeft('Episodes'),
                  _infoRight('${provider.data.episodes ?? '??'}'),
                ),
                _buildInfoItems(
                  _infoLeft('Duration'),
                  _infoRight('${provider.data.duration}'),
                ),
                _buildInfoItems(
                  _infoLeft('Studios'),
                  _infoRight(provider.data.studios.isEmpty ? '??' : provider.data.studios[0] ?? '??'),
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 30),
            padding: EdgeInsets.only(left: 15, right: 15),
            child: Column(
              children: [
                _categoryTitle('Genres'),
                SizedBox(
                  height: 65,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: provider.data.genres.length,
                    itemBuilder: (context, index) {
                      return Container(
                        alignment: Alignment.center,
                        margin: EdgeInsets.all(5),
                        padding: EdgeInsets.only(left: 15, right: 15),
                        decoration:
                            BoxDecoration(color: appTheme.backgroundSubColor, borderRadius: BorderRadius.circular(20)),
                        child: Text(
                          provider.data.genres[index],
                          style: TextStyle(
                            color: appTheme.textMainColor,
                            fontSize: 20,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (provider.data.tags != null)
            Container(
              margin: EdgeInsets.only(top: 30),
              padding: EdgeInsets.only(left: 15, right: 15),
              child: Column(
                children: [
                  _categoryTitle('Tags'),
                  SizedBox(
                    height: 45,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: provider.data.tags!.length,
                      itemBuilder: (context, index) {
                        return Container(
                          alignment: Alignment.center,
                          margin: EdgeInsets.all(5),
                          padding: EdgeInsets.only(left: 15, right: 15),
                          decoration:
                              BoxDecoration(color: appTheme.backgroundSubColor, borderRadius: BorderRadius.circular(5)),
                          child: Text(
                            provider.data.tags![index],
                            style: TextStyle(
                              color: appTheme.textMainColor,
                              fontSize: 15,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          Container(
            margin: EdgeInsets.only(top: 30),
            padding: EdgeInsets.only(left: 25, right: 25),
            child: Column(
              children: [
                _categoryTitle('Description'),
                Text(
                  provider.data.synopsis ?? '',
                  style: TextStyle(
                    color: appTheme.textMainColor,
                    fontFamily: "NunitoSans",
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 30),
            child: Column(
              children: [
                _categoryTitle('Characters'),
                SizedBox(
                  height: 260,
                  child: ListView.builder(
                    itemCount: provider.data.characters.length,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final character = provider.data.characters[index];
                      return Container(
                        width: 130,
                        child: Cards.characterCard(
                          character['name'],
                          character['role'],
                          character['image'],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 20),
            child: Column(
              children: [
                _categoryTitle('Related'),
                _buildRecAndRel(provider.data.related, false, context),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 20),
            child: Column(
              children: [
                _categoryTitle('Recommended'),
                _buildRecAndRel(provider.data.recommended, true, context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Container _buildInfoItems(Widget itemLeft, Widget itemRight) {
    return Container(
      padding: EdgeInsets.only(left: 15, right: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          itemLeft,
          Container(width: 150, child: itemRight),
        ],
      ),
    );
  }

  SizedBox _buildRecAndRel(List<DatabaseRelatedRecommendation> data, bool recommended, BuildContext context) {
    if (data.isEmpty)
      return SizedBox(
        height: 240,
        child: Center(
          child: const Text(
            'Nothing to see here!',
            style: TextStyle(
              fontFamily: "NunitoSans",
              fontSize: 18,
              color: const Color.fromARGB(255, 255, 255, 255),
            ),
          ),
        ),
      );
    return SizedBox(
      height: 260,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: data.length,
        itemBuilder: (context, index) {
          final item = data[index];
          return GestureDetector(
            onTap: () {
              if (item.type.toLowerCase() != "anime") {
                return floatingSnackBar('Mangas/Novels arent supported');
              }

              //only navigate if the list is being built by characterCard method.
              //since the animeCard has inbuilt navigation
              if (!recommended)
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => Info(
                      id: item.id,
                    ),
                  ),
                );
            },
            child: Container(
                width: 130,
                child: recommended
                    ? Cards.animeCard(item.id, item.title['english'] ?? item.title['romaji'] ?? "", item.cover,
                        rating: item.rating)
                    : Cards.characterCard(
                        item.title['english'] ?? item.title['romaji'] ?? "",
                        recommended ? item.type : item.relationType!,
                        item.cover,
                      )),
          );
        },
      ),
    );
  }

  Padding _categoryTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          color: appTheme.textMainColor,
          fontFamily: "NatoSans",
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Padding _infoLeft(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        text,
        style: TextStyle(
            color: const Color.fromARGB(255, 141, 141, 141),
            fontSize: 17,
            fontFamily: "NatoSans",
            fontWeight: FontWeight.bold),
      ),
    );
  }

  Padding _infoRight(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        text,
        style: TextStyle(
          color: appTheme.textMainColor,
          fontSize: 17,
          fontFamily: "NotoSans",
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.end,
      ),
    );
  }

  Stack _stack() {
    return Stack(
      children: [
        GestureDetector(
          onLongPress: () {
            final img = provider.data.banner != null ? provider.data.banner! : provider.data.cover;
            showModalBottomSheet(
              context: context,
              showDragHandle: true,
              backgroundColor: appTheme.modalSheetBackgroundColor,
              builder: (BuildContext context) {
                return SingleChildScrollView(
                  child: Container(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          "${provider.data.title['english'] ?? provider.data.title['romaji']} - Banner",
                          style: TextStyle(fontFamily: "Rubik", fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                        Image.network(
                          img,
                          height: 250,
                        ),
                        Container(
                          margin: EdgeInsets.only(top: 20, bottom: 10),
                          alignment: Alignment.center,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () async {
                              try {
                                await Downloader().downloadImage(
                                    img,
                                    (provider.data.title['english'] ?? provider.data.title['romaji'] ?? "anime") +
                                        "_Banner");
                                floatingSnackBar("Succesfully saved to your downloads folder!");
                                Navigator.of(context).pop();
                              } catch (err) {
                                floatingSnackBar("Couldnt save the image!");
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              fixedSize: Size(150, 75),
                              backgroundColor: appTheme.accentColor,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(color: appTheme.accentColor),
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: Text(
                              "save",
                              style: TextStyle(
                                  color: appTheme.onAccent,
                                  fontFamily: "Poppins",
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          child: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
                colors: [Colors.transparent, appTheme.backgroundColor],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                stops: [0.09, 0.23]).createShader(bounds),
            blendMode: BlendMode.dstIn,
            child: Container(
              height: 270,
              width: double.infinity,
              child: Image.network(
                provider.data.banner != null ? provider.data.banner! : provider.data.cover,
                fit: BoxFit.cover,
                opacity: AlwaysStoppedAnimation(0.6),
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded) return child;
                  return AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: Duration(milliseconds: 300),
                    child: child,
                    curve: Curves.easeIn,
                  );
                },
              ),
            ),
          ),
        ),
        Container(
          alignment: Alignment.center,
          margin: EdgeInsets.only(top: 100),
          child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: CachedNetworkImage(
                imageUrl: provider.data.cover,
                height: 220,
                fadeInDuration: Duration(milliseconds: 200),
                fadeInCurve: Curves.easeIn,
                // fit: BoxFit.cover,
              )),
        ),
        Container(
          margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          child: IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            iconSize: 27,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
            ),
            style: IconButton.styleFrom(backgroundColor: Color.fromARGB(69, 0, 0, 0)),
          ),
        ),
      ],
    );
  }
}
