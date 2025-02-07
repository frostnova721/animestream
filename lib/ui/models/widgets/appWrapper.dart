import 'package:animestream/ui/theme/themeProvider.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

class AppWrapper extends StatelessWidget {
  final Widget firstPage;
  const AppWrapper({super.key, required this.firstPage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: (defaultTargetPlatform == TargetPlatform.windows && !Provider.of<ThemeProvider>(context).isFullScreen)
          ? PreferredSize(
              preferredSize: const Size(double.maxFinite, 34),
              child: Row(
                // backgroundColor: Colors.black,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: DragToMoveArea(
                      child: Container(
                          // child: Row(
                          //   children: [
                          //   ],
                          // ),
                          ),
                    ),
                  ),
                  Row(
                    children: [
                      WindowButton(
                        onClick: () => windowManager.minimize(),
                        icon: FluentIcons.subtract_16_regular,
                        // hoverColor: ,
                      ),
                      WindowButton(
                        onClick: () async {
                          await windowManager.isMaximized() ? windowManager.unmaximize() : windowManager.maximize();
                        },
                        icon: FluentIcons.maximize_16_regular,
                      ),
                      WindowButton(
                        onClick: () => windowManager.close(),
                        hoverColor: const Color.fromARGB(255, 230, 37, 23),
                        icon: FluentIcons.dismiss_16_regular,
                      ),
                    ],
                  ),
                ],
              ),
            )
          : null,
      body: Navigator(
        onGenerateRoute: (settings) {
          Widget page = firstPage;
          return MaterialPageRoute(builder: (context) => page);
        },
      ),
    );
  }
}

class WindowButton extends StatefulWidget {
  final void Function() onClick;
  final IconData icon;
  final Color hoverColor;
  final double? size;
  const WindowButton({
    super.key,
    required this.onClick,
    this.hoverColor = const Color.fromARGB(122, 56, 56, 56),
    required this.icon,
    this.size,
  });

  @override
  State<WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<WindowButton> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (event) {
        hovered = true;
        setState(() {});
      },
      onExit: (event) {
        hovered = false;
        setState(() {});
      },
      child: GestureDetector(
        onTap: widget.onClick,
        child: Container(
          width: 45,
          height: 30,
          alignment: Alignment.center,
          color: hovered ? widget.hoverColor : Colors.transparent,
          child: Icon(
            widget.icon,
            size: widget.size ?? 16,
          ),
        ),
      ),
    );
  }
}
