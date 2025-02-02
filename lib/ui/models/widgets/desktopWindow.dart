import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';

class Desktopwindow extends StatelessWidget {
  const Desktopwindow({super.key});

  @override
  Widget build(BuildContext context) {
    return WindowBorder(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [],
            ),
            Row(
              children: [WindowButtons()],
            ),
          ],
        ),
        color: Colors.white);
  }
}

class WindowButtons extends StatelessWidget {
  const WindowButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MinimizeWindowButton(
          colors: WindowButtonColors(),
        ),
        MaximizeWindowButton(),
        CloseWindowButton(),
      ],
    );
  }
}
