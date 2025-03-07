import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/ui/models/bottomSheets/mediaListStatus.dart';
import 'package:animestream/ui/models/providers/infoProvider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// The Common part (cover, banner stuff)
class CommonInfo extends StatelessWidget {
  final InfoProvider provider;
  const CommonInfo({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: CachedNetworkImage(
            imageUrl: provider.data.cover,
            width: 165,
            height: 220,
            fit: BoxFit.cover,
          ),
        ),
        Container(
          constraints: BoxConstraints(minHeight: 220),
          padding: EdgeInsets.only(left: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end, // Push content to bottom
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: size.width / 2),
                child: Text(
                  provider.data.title['english'] ?? provider.data.title['romaji'] ?? 'no title :(',
                  style: TextStyle(
                    fontFamily: "Rubik",
                    fontWeight: FontWeight.bold,
                    fontSize: 45,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 3,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 10, bottom: 20), // Top and bottom spacing
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(right: 20),
                      child: _button(
                        onClick: () {
                          showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              backgroundColor: appTheme.backgroundColor,
                              child: Container(
                                padding: EdgeInsets.all(20),
                                width: size.width / 3,
                                child: MediaListStatusBottomSheet(
                                  provider: provider,
                                ),
                              ),
                            ),
                          );
                        },
                        child: Text(
                          "${provider.mediaListStatus?.name ?? "UNTRACKED"}",
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 28,
                          ),
                        ),
                      ),
                    ),
                    _button(
                      onClick: () {
                        showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              backgroundColor: appTheme.backgroundColor,
                              child: Container(
                                padding: EdgeInsets.all(20),
                                width: size.width / 3,
                                child: MediaListStatusBottomSheet(
                                  provider: provider,
                                ),
                              ),
                            ),
                          );
                      },
                      child: Row(
                        children: [
                          Text("${provider.watched}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28)),
                          Text(
                            " | ${provider.data.episodes ?? "??"}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 26,
                              color: appTheme.textSubColor,
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _button({required void Function() onClick, required Widget child}) {
    final ValueNotifier<bool> hovered = ValueNotifier(false);
    return ValueListenableBuilder<bool>(
      valueListenable: hovered,
      builder: (context, value, _) {
        return MouseRegion(
          onEnter: (event) => hovered.value = true,
          onExit: (event) => hovered.value = false,
          cursor: SystemMouseCursors.click,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
                border: Border.all(
                  color: hovered.value ? appTheme.textMainColor : appTheme.accentColor,
                ),
                borderRadius: BorderRadius.circular(10)),
            child: GestureDetector(
              onTap: onClick,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
