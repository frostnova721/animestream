import "package:flutter/material.dart";
import "package:flutter/services.dart";

dynamic floatingSnackBar(BuildContext context, String message, {int? duration, bool waitForPreviousToFinish = false}) {
  if (!waitForPreviousToFinish) ScaffoldMessenger.of(context).removeCurrentSnackBar();
  return ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Center(
        child: Text(message, style: TextStyle(fontFamily: "NotoSans", color: Colors.white, fontSize: 14)),
      ),
      duration: Duration(seconds: duration != null ? duration : 3),
      backgroundColor: Color.fromARGB(244, 26, 26, 26),
      behavior: SnackBarBehavior.floating,
      dismissDirection: DismissDirection.down,
      margin: EdgeInsets.only(bottom: 40, left: 20, right: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

void showToast(String message) async {
  final platform = MethodChannel('animestream.app/utils');
  await platform.invokeMethod("showToast", {'message': message});
}
