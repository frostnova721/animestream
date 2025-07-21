import 'dart:io';

import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/ui/models/widgets/cards/animeCardExtended.dart';
import 'package:animestream/ui/models/widgets/cards/animeCard.dart';
import 'package:flutter/material.dart';

class Cards {
  /**Builds a character card (no navigation) */
  static Widget characterCard(String name, String role, String imageUrl) {
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
  static Widget NewsCard(String title, String imageUrl, String date, String time) {
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
  static AnimeCard animeCard(
    int id,
    String title,
    String imageUrl, {
    bool ongoing = false,
    bool shouldNavigate = true,
    bool isAnime = true,
    String? subText = null,
    double? rating = null,
    bool? isMobile,
    void Function()? afterNavigation,
  }) {
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
      isMobile: isMobile ?? Platform.isAndroid,
    );
  }

  static AnimeCardExtended animeCardExtended(
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
  }) =>
      AnimeCardExtended(
        id: id,
        title: title,
        imageUrl: imageUrl,
        rating: rating,
        afterNavigation: afterNavigation,
        bannerImageUrl: bannerImageUrl,
        isAnime: isAnime,
        shouldNavigate: shouldNavigate,
        subText: subText,
        totalEpisodes: totalEpisodes,
        watchedEpisodeCount: watchedEpisodeCount,
      );
}
