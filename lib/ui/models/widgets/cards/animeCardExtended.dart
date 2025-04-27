import 'dart:ui';

import 'package:animestream/core/anime/providers/providerPlugin.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:animestream/ui/pages/info.dart';

class AnimeCardExtended extends StatelessWidget {
  final int id;
  final String title;
  final String imageUrl;
  final double rating;
  final bool ongoing;
  final bool shouldNavigate;
  final bool isAnime;
  final String? subText;
  final void Function()? afterNavigation;
  final int? watchedEpisodeCount;
  final int? totalEpisodes;
  final String? bannerImageUrl;

  const AnimeCardExtended({
    super.key,
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.rating,
    this.ongoing = false,
    this.shouldNavigate = true,
    this.isAnime = true,
    this.subText = null,
    this.afterNavigation,
    this.watchedEpisodeCount,
    this.totalEpisodes,
    this.bannerImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: appTheme.backgroundColor,
      ),
      clipBehavior: Clip.hardEdge,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          focusColor: appTheme.textSubColor,
          onTap: () async {
            final pp = ProviderPlugin().getProvider("animepahe");
            // print("Provider OK");
            // final sr = await pp.search("oreshura");
            // print(sr);
            // print("SEARCH OK");
            // final epl = await pp.getAnimeEpisodeLink(sr[0]['alias']!);
            // print(epl);
            // print("EPISODE LINK OK");
            final str = await pp.getStreams("https://animepahe.ru/play/8ad50145-a1af-1ae7-728e-9ead3e3c6ff1/60d256743082299c9c015df870eeb274368e22cde0ee194bb7d6c8cb784d83d0",
             (a,b) => print(a));
            

            return;
            if (!isAnime) return floatingSnackBar("Mangas/Novels arent supported");
            if (shouldNavigate)
              Navigator.of(context)
                  .push(
                MaterialPageRoute(
                  builder: (context) => Info(
                    id: id,
                  ),
                ),
              )
                  .then((val) {
                if (afterNavigation != null) afterNavigation?.call();
              });
          },
          child: Container(
            width: 305,
            height: 150,
            child: Stack(
              children: [
                if (bannerImageUrl != null)
                  ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                    child: Opacity(
                      opacity: 0.5,
                      child: CachedNetworkImage(
                        imageUrl: bannerImageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  ),
                Container(
                  padding: EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          fadeInDuration: Duration(milliseconds: 200),
                          fadeInCurve: Curves.easeIn,
                          width: 100,
                          height: 130,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.only(left: 15, top: 10),
                        width: 175,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                color: appTheme.textMainColor,
                                fontFamily: "NotoSans",
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                            Container(
                              margin: EdgeInsets.only(bottom: 15),
                              child: Row(
                                // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 52,
                                    padding: EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                        color: appTheme.accentColor.withValues(alpha: 0.8),
                                        borderRadius: BorderRadius.circular(10)),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.star,
                                          color: appTheme.onAccent,
                                          // (currentUserSettings?.darkMode ?? true) ? appTheme.backgroundColor : appTheme.textMainColor,
                                          size: 15,
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(left: 3),
                                          child: Text(
                                            "$rating",
                                            style: TextStyle(
                                              color: appTheme.onAccent,
                                              //  (currentUserSettings?.darkMode ?? true) ? appTheme.backgroundColor : appTheme.textMainColor,
                                              fontFamily: "NotoSans",
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                            maxLines: 2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // if (totalEpisodes != null || watchedEpisodeCount != null)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 13, right: 13),
                                    child: Text(
                                      '•',
                                      style: TextStyle(fontSize: 17, color: Theme.of(context).colorScheme.secondary),
                                    ),
                                  ),
                                  Container(
                                    child: Row(
                                      children: [
                                        Text(
                                          "${watchedEpisodeCount ?? "~"} ",
                                          style: TextStyle(
                                            fontFamily: "NunitoSans",
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                        ),
                                        Text(
                                          "/ ${totalEpisodes ?? "??"}",
                                          style: TextStyle(
                                            fontFamily: "NunitoSans",
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.onSecondaryContainer,
                                          ),
                                        ),
                                      ],
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
            ),
          ),
        ),
      ),
    );
  }
}
