import 'dart:io';
import 'dart:ui';

import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:animestream/ui/pages/info.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class Cards {
  /**only pass the context if using the animeCard method! */
  final BuildContext? context;

  Cards({this.context});

  /**Builds a character card (no navigation) */
  Widget characterCard(String name, String role, String imageUrl) {
    return Card(
      color: appTheme.backgroundColor,
      clipBehavior: Clip.hardEdge,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
            ),
            clipBehavior: Clip.hardEdge,
            height: 175,
            width: 115,
            child: Image.network(
              fit: BoxFit.cover,
              imageUrl,
              height: 175,
              width: 115,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded) return child;
                return AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: Duration(milliseconds: 150),
                  child: child,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 5, left: 5, right: 5),
            child: Text(
              name,
              style: TextStyle(
                color: appTheme.textMainColor,
                fontFamily: 'NotoSans',
                fontSize: 15,
                overflow: TextOverflow.ellipsis,
              ),
              maxLines: 2,
              textAlign: TextAlign.center,
            ),
          ),
          Text(
            role,
            style: TextStyle(
              color: appTheme.textSubColor,
              fontFamily: 'NotoSans',
              fontSize: 12,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /**Builds a card for news */
  Widget NewsCard(String title, String imageUrl, String date, String time) {
    return Card(
      surfaceTintColor: appTheme.textSubColor,
      color: appTheme.backgroundColor,
      child: Container(
        decoration: BoxDecoration(
            // boxShadow: [BoxShadow(color: Color.fromARGB(82, 92, 92, 92), blurRadius: 10, blurStyle: BlurStyle.normal, offset: Offset(0.0, 3), spreadRadius: 0)],
            color: Colors.transparent),
        height: 200,
        padding: EdgeInsets.only(right: 10),
        child: Row(
          children: [
            Container(
              margin: EdgeInsets.only(
                right: 20,
              ),
              width: 135,
              height: 175,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Padding(
                  padding: const EdgeInsets.all(40),
                  child: Image.asset('lib/assets/images/broken_heart.png'),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.only(top: 10),
                    child: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 5,
                      style: TextStyle(
                        color: appTheme.textMainColor,
                        fontSize: 18,
                        fontFamily: "Rubik",
                      ),
                    ),
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text(
                      "$date • $time",
                      style: TextStyle(
                        fontFamily: "NotoSans",
                        fontSize: 13,
                        color: appTheme.textSubColor,
                      ),
                    ),
                  ),
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /**Builds a card for anime (optional navigation) */
  AnimeCard animeCard(
    int id,
    String title,
    String imageUrl, {
    bool ongoing = false,
    bool shouldNavigate = true,
    bool isAnime = true,
    String? subText = null,
    double? rating = null,
    bool isMobile = true,
    void Function()? afterNavigation,
  }) {
    if (context == null) throw Exception("NO CONTEXT PROVIDED TO BUILD CARDS");
    return AnimeCard(
      // context: context,
      id: id,
      title: title,
      imageUrl: imageUrl,
      afterNavigation: afterNavigation,
      ongoing: ongoing,
      shouldNavigate: shouldNavigate,
      isAnime: isAnime,
      subText: subText,
      rating: rating,
      isMobile: isMobile,
    );
  }

  Card animeCardExtended(
    int id,
    String title,
    String imageUrl,
    double rating, {
    bool ongoing = false,
    bool shouldNavigate = true,
    bool isAnime = true,
    String? subText = null,
    void Function()? afterNavigation,
    int? watchedEpisodeCount,
    int? totalEpisodes,
    String? bannerImageUrl,
  }) {
    if (context == null) throw Exception("NO CONTEXT PROVIDED TO BUILD CARDS");
    return Card(
      color: appTheme.backgroundSubColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      clipBehavior: Clip.hardEdge,
      elevation: 0,
      child: InkWell(
        focusColor: appTheme.textSubColor,
        onTap: () {
          if (!isAnime) return floatingSnackBar(context!, "Mangas/Novels arent supported");
          if (shouldNavigate)
            Navigator.of(context!)
                .push(
              MaterialPageRoute(
                builder: (context) => Info(
                  id: id,
                ),
              ),
            )
                .then((val) {
              if (afterNavigation != null) afterNavigation();
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
                      imageUrl: bannerImageUrl,
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
                                    style: TextStyle(fontSize: 17, color: Theme.of(context!).colorScheme.secondary),
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
                                          color: Theme.of(context!).colorScheme.primary,
                                        ),
                                      ),
                                      Text(
                                        "/ ${totalEpisodes ?? "??"}",
                                        style: TextStyle(
                                          fontFamily: "NunitoSans",
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context!).colorScheme.onSecondaryContainer,
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
    );
  }
}

class AnimeCard extends StatefulWidget {
  final int id;
  final String title;
  final String imageUrl;
  final bool ongoing;
  final bool shouldNavigate;
  final bool isAnime;
  final bool isMobile;
  final String? subText;
  final double? rating;
  final void Function()? afterNavigation;

  const AnimeCard({
    super.key,
    required this.id,
    required this.title,
    required this.afterNavigation,
    required this.imageUrl,
    this.isAnime = true,
    this.ongoing = false,
    this.rating = null,
    this.shouldNavigate = true,
    this.subText = null,
    this.isMobile = true,
  });

  @override
  State<AnimeCard> createState() => _AnimeCardState();
}

class _AnimeCardState extends State<AnimeCard> {
  bool isFocused = false;
  double width = Platform.isWindows ? 150 : 110;
  double height = Platform.isWindows ? 200 : 160;

  void updateFocus(bool val) {
    return setState(() {
      isFocused = val;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.isMobile ? width : width + 5,
      margin: EdgeInsets.only(left: 5, right: 5),
      child: InkWell(
        onHover: updateFocus,
        onFocusChange: updateFocus,
        splashFactory: NoSplash.splashFactory,
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        overlayColor: WidgetStatePropertyAll(Colors.transparent),
        onTap: () {
          if (!widget.isAnime) return floatingSnackBar(context, "Manga or Novels aren't supported");
          if (widget.shouldNavigate)
            Navigator.of(context)
                .push(
              MaterialPageRoute(
                builder: (context) => Info(
                  id: widget.id,
                ),
              ),
            )
                .then((val) {
              widget.afterNavigation?.call();
            });
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  curve: Curves.linear,
                  height: widget.isMobile
                      ? height
                      : isFocused
                          ? height + 2
                          : height,
                  width: widget.isMobile
                      ? width
                      : isFocused
                          ? width + 2
                          : width,
                  margin: EdgeInsets.only(bottom: 10, top: widget.isMobile ? 0 : 5),
                  decoration: BoxDecoration(
                    border: widget.isMobile || Platform.isWindows
                        ? null
                        : isFocused
                            ? Border.all(
                                color: appTheme.accentColor,
                                strokeAlign: BorderSide.strokeAlignOutside,
                                width: 2,
                              )
                            : null,
                    borderRadius: BorderRadius.circular(widget.isMobile
                        ? 20
                        : isFocused
                            ? 5
                            : 10),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: CachedNetworkImage(
                    imageUrl: widget.imageUrl,
                    fadeInDuration: Duration(milliseconds: 200),
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: appTheme.backgroundSubColor,
                      height: height,
                      width: width,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 10,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(15),
                          bottomRight: Radius.circular(widget.isMobile
                              ? 15
                              : isFocused
                                  ? 4
                                  : 9)),
                      color: appTheme.accentColor,
                    ),
                    width: width / 2,
                    padding: EdgeInsets.only(left: 5, right: 5, top: 2, bottom: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.star,
                          color: appTheme.onAccent,
                          size: 13,
                        ),
                        Text(
                          " ${widget.rating ?? '00'}",
                          style: TextStyle(
                            fontSize: 14,
                            color: appTheme.onAccent,
                            fontFamily: "NotoSans",
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
            Text(
              widget.title,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              textAlign: TextAlign.left,
              style: TextStyle(
                  fontFamily: "NotoSans",
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isFocused ? appTheme.accentColor : appTheme.textMainColor),
            ),
            if (widget.subText != null)
              Text(
                widget.subText!,
                style: TextStyle(fontFamily: "NunitoSans", color: appTheme.textSubColor),
              )
          ],
        ),
      ),
    );
  }
}
