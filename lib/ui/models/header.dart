import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/ui/pages/settings.dart';
import 'package:flutter/material.dart';

Container buildHeader(String title, BuildContext context, { void Function()? afterNavigation}) {
  return Container(
    padding: EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 20),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: appTheme.textMainColor,
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
          ).then((value) {
            if(afterNavigation != null)
            afterNavigation();
          },),
          icon: Icon(
            Icons.settings_rounded,
            color: appTheme.textMainColor,
            size: 32,
          ),
        ),
      ],
    ),
  );
}
