import "package:floating_snackbar/floating_snackbar.dart";
import "package:flutter/material.dart";
import "../theme/mainTheme.dart";

void floatingSnackBar(BuildContext context, String message) {
  return FloatingSnackBar(
    message: message,
    context: context,
    textStyle: TextStyle(
      color: Colors.black,
      fontFamily: "NatoSans",
    ),
    backgroundColor: themeColor,
  );
}
