import 'package:animestream/ui/pages/settings.dart';
import 'package:animestream/ui/theme/mainTheme.dart';
import 'package:flutter/material.dart';

Container buildHeader(String title, BuildContext context) {
  return Container(
    padding: EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 20),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: textMainColor,
            fontFamily: "Rubik",
            fontWeight: FontWeight.bold,
            fontSize: 30,
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => SettingsPage(),
            ),
          ),
          icon: Icon(
            Icons.settings_rounded,
            color: textMainColor,
            size: 32,
          ),
        ),
      ],
    ),
  );
}
