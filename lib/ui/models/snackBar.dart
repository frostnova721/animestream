import "package:flutter/material.dart";

floatingSnackBar(BuildContext context, String message, { int? duration }) {
  return ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Center(
        child: Text(message,
        style: TextStyle(
          fontFamily: "NotoSans",
          color: const Color.fromARGB(255, 255, 255, 255),
          fontSize: 14
        )
        ),
      ),
      duration: Duration(seconds: duration != null ? duration : 3),
      backgroundColor: Color.fromARGB(235, 29, 29, 29),
      behavior: SnackBarBehavior.floating,
      dismissDirection: DismissDirection.down,
      margin: EdgeInsets.only(bottom: 40, left: 20, right: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}