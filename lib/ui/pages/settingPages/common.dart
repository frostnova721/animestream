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
