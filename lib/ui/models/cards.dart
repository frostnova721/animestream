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
  Card animeCard(
    int id,
    String title,
    String imageUrl, {
    bool ongoing = false,
    bool shouldNavigate = true,
    bool isAnime = true,
    String? subText = null,
    double? rating = null,
    void Function()? afterNavigation,
  }) {
    if (context == null) throw Exception("NO CONTEXT PROVIDED TO BUILD CARDS");
    return Card(
      color: appTheme.backgroundColor,
      shadowColor: null,
      borderOnForeground: false,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
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
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        focusColor: appTheme.textSubColor,
        child: Container(
          alignment: Alignment.center,
          width: 120,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                margin: EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                ),
                // clipBehavior: Clip.hardEdge,
                height: 165,
                width: 110,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        height: 165,
                        width: 110,
                        fadeInCurve: Curves.easeIn,
                        fadeInDuration: Duration(milliseconds: 200),
                        placeholder: (context, url) => Container(
                          color: appTheme.backgroundSubColor,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        padding: EdgeInsets.only(left: 5, top: 2, bottom: 2, right: 5),
                        height: 25,
                        width: 50,
                        decoration: BoxDecoration(
                          color: appTheme.accentColor.withOpacity(0.9),
                          borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(17),
                            topLeft: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 3),
                              child: Icon(
                                Icons.star,
                                size: 13,
                                color: (currentUserSettings?.darkMode ?? true) ? appTheme.backgroundColor : appTheme.textMainColor
                              ),
                            ),
                            Text(
                              "${rating ?? "??"}",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                fontFamily: "NotoSans",
                                color: (currentUserSettings?.darkMode ?? true) ? appTheme.backgroundColor : appTheme.textMainColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (ongoing)
                      Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                              boxShadow: <BoxShadow>[BoxShadow(color: Colors.green, spreadRadius: 2)],
                              borderRadius: BorderRadius.circular(100),
                              color: Color.fromARGB(255, 40, 209, 46),
                              border: Border.all(color: Colors.black, width: 2)),
                        ),
                      ),
                  ],
                  // ),
                  // : Container(
                  //     decoration: BoxDecoration(
                  //       borderRadius: BorderRadius.circular(20),
                  //     ),
                  //     clipBehavior: Clip.hardEdge,
                  //     child: CachedNetworkImage(
                  //       imageUrl: imageUrl,
                  //       fit: BoxFit.cover,
                  //       height: 165,
                  //       width: 110,
                  //       fadeInCurve: Curves.easeIn,
                  //       fadeInDuration: Duration(milliseconds: 200),
                  //       placeholder: (context, url) => Container(color: appTheme.backgroundSubColor,),
                  //     ),
                  //   ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(right: 5, bottom: subText == null ? 0 : 5),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: TextStyle(
                      color: appTheme.textMainColor,
                      fontFamily: 'NotoSans',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      overflow: TextOverflow.ellipsis,
                    ),
                    maxLines: 2,
                    textAlign: TextAlign.left,
                  ),
                ),
              ),
              if (subText != null)
                Text(
                  subText,
                  style: TextStyle(
                    color: appTheme.textSubColor,
                    fontFamily: 'NotoSans',
                    fontSize: 12,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
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
                                  width: 50,
                                  padding: EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                      color: appTheme.accentColor.withOpacity(0.8), borderRadius: BorderRadius.circular(10)),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        color: (currentUserSettings?.darkMode ?? true) ? appTheme.backgroundColor : appTheme.textMainColor,
                                        size: 18,
                                      ),
                                      Text(
                                        "$rating",
                                        style: TextStyle(
                                          color: (currentUserSettings?.darkMode ?? true) ? appTheme.backgroundColor : appTheme.textMainColor,
                                          fontFamily: "NotoSans",
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                        maxLines: 2,
                                      ),
                                    ],
                                  ),
                                ),
                                // if (totalEpisodes != null || watchedEpisodeCount != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 13, right: 13),
                                  child: Text(
                                    '•',
                                    style: TextStyle(fontSize: 17,
                                    color: Theme.of(context!).colorScheme.secondary),
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
