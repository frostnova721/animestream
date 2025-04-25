import 'package:animestream/core/anime/providers/types.dart';
import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/ui/models/bottomSheets/serverSelectionSheet.dart';
import 'package:animestream/ui/models/providers/infoProvider.dart';
import 'package:animestream/ui/models/widgets/ContextMenu.dart';
import 'package:flutter/material.dart';

class InfoPageEpisodeGrid extends StatelessWidget {
  final Size size;
  final InfoProvider provider;
  const InfoPageEpisodeGrid({
    super.key,
    required this.provider,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisExtents = <double>[330, 150, 100];
    final mainAxisExtents = <double>[130, 150, 100];
    return GridView.builder(
      itemCount: provider.visibleEpList[provider.currentPageIndex].length,
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: crossAxisExtents[provider.viewMode],
        mainAxisExtent: mainAxisExtents[provider.viewMode],
        mainAxisSpacing: 12,
        crossAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final ValueNotifier<bool> hovered = ValueNotifier<bool>(false);
        return Container(
          decoration: BoxDecoration(
            color: appTheme.backgroundColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: GestureDetector(
            onTap: () {
              provider.selectedEpisodeToLoadStreams = index;
              showDialog(
                context: context,
                useRootNavigator: false,
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
                  final desktopWidgets = [_episodeTileDesktop, _episodeGridTileDesktop, _episodeCompactTileDesktop];
                  return desktopWidgets[provider.viewMode](hovered, index, context);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _episodeCompactTileDesktop(ValueNotifier<bool> hovered, int index, BuildContext context) {
    final episodeNumber = provider.visibleEpList[provider.currentPageIndex][index]['realIndex'] + 1;

    return ContextMenu(
      menuItems: [
        ContextMenuItem(
            icon: Icons.play_arrow_rounded,
            label: "Watch",
            onClick: () {
              provider.selectedEpisodeToLoadStreams = index;
              showDialog(
                context: context,
                useRootNavigator: false,
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
            }),
        ContextMenuItem(
            icon: Icons.download, label: "Download", onClick: () => _showDownloadDialog(context, provider, index))
      ],
      child: Container(
        margin: EdgeInsets.all(5),
        padding: EdgeInsets.all(8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: hovered.value ? appTheme.backgroundColor : appTheme.backgroundSubColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          "$episodeNumber",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: appTheme.textMainColor,
          ),
        ),
      ),
    );
  }

  Widget _episodeGridTileDesktop(ValueNotifier<bool> hovered, int index, BuildContext context) {
    final episodeNumber = provider.visibleEpList[provider.currentPageIndex][index]['realIndex'] + 1;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 90,
                width: double.infinity,
                padding: EdgeInsets.all(5),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    provider.data.cover,
                    fit: BoxFit.cover,
                    color: hovered.value ? Colors.black.withAlpha(100) : null,
                    colorBlendMode: BlendMode.darken,
                  ),
                ),
              ),
              AnimatedOpacity(
                  duration: Duration(milliseconds: 100),
                  opacity: hovered.value ? 1 : 0,
                  child: Icon(
                    Icons.play_circle_fill_rounded,
                    size: 35,
                    color: appTheme.textMainColor,
                  ))
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "EP $episodeNumber",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: appTheme.textMainColor,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    _showDownloadDialog(context, provider, index);
                  },
                  icon: Icon(Icons.download_rounded, color: Colors.white),
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(Colors.black.withAlpha(180)),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _episodeTileDesktop(ValueNotifier<bool> hovered, int index, BuildContext context) {
    final episode = provider.visibleEpList[provider.currentPageIndex][index]['epLink'] as EpisodeDetails;
    final episodeNumber = episode.episodeNumber;
    final thumbnail = episode.thumbnail ?? provider.data.cover;
    final title = episode.episodeTitle != null ? "$episodeNumber: ${episode.episodeTitle}" : 'Episode $episodeNumber';
    final isFiller = episode.isFiller ?? false;

    return MouseRegion(
      onEnter: (_) => hovered.value = true,
      onExit: (_) => hovered.value = false,
      child: Stack(
        children: [
          Container(
            margin: EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              // overflow: Overflow.hidden,
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.network(
              thumbnail,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              color: hovered.value ? Colors.black.withAlpha(100) : null,
              colorBlendMode: BlendMode.darken,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withAlpha(179),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            left: 12,
            right: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isFiller)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Filler',
                      style: TextStyle(
                        fontSize: 12,
                        color: appTheme.accentColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            bottom: 10,
            right: 10,
            child: IconButton(
              onPressed: () {
                _showDownloadDialog(context, provider, index);
              },
              icon: Icon(Icons.download_rounded, color: Colors.white),
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(Colors.black.withAlpha(150)),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              tooltip: 'Download',
            ),
          ),
          AnimatedOpacity(
            duration: Duration(milliseconds: 120),
            opacity: hovered.value ? 1 : 0,
            child: Center(
              child: Icon(
                Icons.play_circle_fill_rounded,
                size: 52,
                color: Colors.white.withAlpha(204),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDownloadDialog(BuildContext context, InfoProvider provider, int index) {
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (context) {
        return Dialog(
          backgroundColor: appTheme.backgroundColor,
          child: Container(
            padding: const EdgeInsets.all(20),
            width: MediaQuery.of(context).size.width / 3,
            child: ServerSelectionBottomSheet(
              provider: provider,
              episodeIndex: index,
              type: ServerSheetType.download,
            ),
          ),
        );
      },
    );
  }
}
