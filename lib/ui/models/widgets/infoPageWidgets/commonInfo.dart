import 'package:animestream/core/app/runtimeDatas.dart';
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
                        onClick: () {},
                        child: Text(
                          "${provider.mediaListStatus?.name ?? "UNTRACKED"}",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
                        ),
                      ),
                    ),
                    _button(
                      onClick: () {},
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

  InkWell _button({required void Function() onClick, required Widget child}) {
    return InkWell(
      onTap: onClick,
      child: Container(
        child: child,
        padding: EdgeInsets.fromLTRB(20, 5, 20, 5),
        decoration:
            BoxDecoration(border: Border.all(color: appTheme.accentColor), borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
