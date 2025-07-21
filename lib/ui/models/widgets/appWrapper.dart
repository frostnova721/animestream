import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/ui/models/providers/themeProvider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

class AppWrapper extends StatelessWidget {
  final Widget firstPage;
  const AppWrapper({super.key, required this.firstPage});

  static final navKey = GlobalKey<NavigatorState>();

  static final _fn = FocusNode();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: (defaultTargetPlatform == TargetPlatform.windows && !Provider.of<AppProvider>(context).isFullScreen)
          ? PreferredSize(
              preferredSize: const Size(double.maxFinite, 33),
              child: Container(
                color: Provider.of<AppProvider>(context).titleBarColor ?? appTheme.backgroundColor.withAlpha(150),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: DragToMoveArea(child: Container()),
                    ),
                    Row(
                      children: [
                        WindowButton(
                          onClick: () => windowManager.minimize(),
                          icon: "lib/assets/images/fluent_min.svg",
                          // hoverColor: ,
                        ),
                        WindowButton(
                          onClick: () async {
                            await windowManager.isMaximized() ? windowManager.unmaximize() : windowManager.maximize();
                          },
                          icon: "lib/assets/images/fluent_max.svg",
                        ),
                        WindowButton(
                          onClick: () => windowManager.close(),
                          hoverColor: const Color.fromARGB(255, 230, 37, 23),
                          iconColorOnHover: Colors.white,
                          icon: "lib/assets/images/fluent_close.svg",
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: StatefulBuilder(
        builder: (context, setState) {
          return Listener(
            onPointerDown: (event) {
              if(event.buttons == kBackMouseButton) {
                Navigator.of(navKey.currentState!.context).maybePop();
                setState((){});
              }
            },
            child: Navigator(
              key: navKey,
              onGenerateRoute: (settings) {
                Widget page = firstPage;
                return MaterialPageRoute(builder: (context) => page);
              },
            ),
          );
        }
      ),
    );
  }
}

class WindowButton extends StatefulWidget {
  final void Function() onClick;
  final String icon;
  final Color hoverColor;
  final Color? iconColorOnHover;
  final double? size;
  const WindowButton({
    super.key,
    required this.onClick,
    this.hoverColor = const Color.fromARGB(122, 56, 56, 56),
    this.iconColorOnHover,
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
          height: 33,
          alignment: Alignment.center,
          color: hovered ? widget.hoverColor : Colors.transparent,
          child: SvgPicture.asset(
            widget.icon,
            fit: BoxFit.none,
            // size: widget.size ?? 16,
            colorFilter: ColorFilter.mode(hovered ? (widget.iconColorOnHover ?? appTheme.textMainColor) : appTheme.textMainColor, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}


