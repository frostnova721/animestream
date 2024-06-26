import 'package:animestream/ui/theme/mainTheme.dart';
import 'package:flutter/material.dart';

Widget topRow(BuildContext context, String title) {
  return Row(
    children: [
      IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: Icon(
          Icons.arrow_back_rounded,
          color: textMainColor,
          size: 32,
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(left: 10),
        child: Text(
          title,
          style: TextStyle(
            fontFamily: "Rubik",
            fontSize: 23,
            color: textMainColor,
          ),
        ),
      ),
    ],
  );
}

PreferredSizeWidget settingPagesAppBar(BuildContext context) {
  return PreferredSize(
    preferredSize: Size(double.infinity, 70),
    child: Container(
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: MediaQuery.of(context).padding.left + 10,
        right: MediaQuery.of(context).padding.right + 10,
        bottom: 10,
      ),
      child: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(
            Icons.arrow_back_rounded,
            color: textMainColor,
            size: 35,
          )),
    ),
  );
}

Widget settingPagesTitleHeader(BuildContext context, String title) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(
          // top: 5,
          left: 10,
          right: 10,
          bottom: 10,
        ),
        child: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(
              Icons.arrow_back_rounded,
              color: textMainColor,
              size: 35,
            )),
      ),
      Container(
        padding: EdgeInsets.only(top: 40, left: 20, bottom: 40),
        child: Text(
          title,
          style: TextStyle(fontFamily: "Rubik", fontSize: 40),
        ),
      ),
    ],
  );
}

InkWell toggleItem(String label, bool value, void Function() onTapFunction, {String? description = null}) {
    return InkWell(
      onTap: onTapFunction,
      child: Container(
        padding: EdgeInsets.only(top: 10, bottom: 10, left: 10, right: 10),
        child: Container(
          padding: EdgeInsets.only(
            left: 10,
            right: 10,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: textStyle(),
                  ),
                  if (description != null)
                    Text(
                      description,
                      style: textStyle().copyWith(color: textSubColor, fontSize: 12),
                    ),
                ],
              ),
              Switch(
                value: value,
                onChanged: (val) {
                  onTapFunction();
                },
                activeColor: backgroundColor,
                activeTrackColor: accentColor,
              )
            ],
          ),
        ),
      ),
    );
  }

TextStyle textStyle() {
  return TextStyle(
    color: textMainColor,
    fontFamily: "NotoSans",
    fontWeight: FontWeight.bold,
    fontSize: 20,
  );
}

EdgeInsets pagePadding(BuildContext context, {bool bottom = false}) {
  final paddingQuery = MediaQuery.of(context).padding;
  return EdgeInsets.only(
    top: paddingQuery.top + 10,
    left: paddingQuery.left,
    right: paddingQuery.right,
    bottom: bottom ? paddingQuery.bottom : 0,
  );
}