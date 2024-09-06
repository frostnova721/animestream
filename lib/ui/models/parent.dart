import 'package:flutter/material.dart';

class ThemeChanger extends InheritedWidget {

  final _ThemeChangerWidgetState data;

  const ThemeChanger({
    Key? key,
    required this.data,
    required Widget child,
  }) : super(child: child, key: key);

  static _ThemeChangerWidgetState of(BuildContext context) {
    return (context.dependOnInheritedWidgetOfExactType(aspect: ThemeChanger)
            as ThemeChanger)
        .data;
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return this != oldWidget;
  }
  
}

class ThemeChangerWidget extends StatefulWidget {
  final Widget child;
  const ThemeChangerWidget({super.key, required this.child});

  @override
  State<ThemeChangerWidget> createState() => _ThemeChangerWidgetState();
}

class _ThemeChangerWidgetState extends State<ThemeChangerWidget> {

  void refreshTree() {
    setState(() {
    });
  }

  @override
  Widget build(BuildContext context) {
    return ThemeChanger(data: this, child: widget.child);
  }
}