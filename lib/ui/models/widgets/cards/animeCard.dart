import 'dart:io';

import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:animestream/ui/pages/info.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

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
          if (!widget.isAnime) return floatingSnackBar("Manga or Novels aren't supported");
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
