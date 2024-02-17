import "package:flutter/material.dart";

floatingSnackBar(BuildContext context, String message) {
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
      backgroundColor: Color.fromARGB(206, 100, 100, 100),
      behavior: SnackBarBehavior.floating,
      dismissDirection: DismissDirection.down,
      // margin: EdgeInsets.only(bottom: 40, left: 50, right: 50),
      width: 300,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
    ),
  );
}
