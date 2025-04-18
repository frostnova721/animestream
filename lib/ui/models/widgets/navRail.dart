import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/ui/models/widgets/bottomBar.dart';
import 'package:flutter/material.dart';

class AnimeStreamNavDestination {
  final IconData icon;
  final String label;
  final Color? selectedColor;
  final Color? unselectedColor;
  final Color? selectedIconColor;
  final Color? unselectedIconColor;
  final VoidCallback? onClick;

  AnimeStreamNavDestination({
    required this.icon,
    required this.label,
    this.selectedColor,
    this.unselectedColor,
    this.selectedIconColor,
    this.unselectedIconColor,
    this.onClick,
  });
}

class AnimeStreamNavRail extends StatefulWidget {
  final List<AnimeStreamNavDestination> destinations;
  final AnimeStreamBottomBarController controller;
  final int initialIndex;
  const AnimeStreamNavRail({
    super.key,
    required this.destinations,
    required this.controller,
    required this.initialIndex,
  });

  @override
  State<AnimeStreamNavRail> createState() => _AnimeStreamNavRailState();
}

class _AnimeStreamNavRailState extends State<AnimeStreamNavRail> {
  @override
  void initState() {
    super.initState();
    widget.controller.currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      child: ValueListenableBuilder(
          valueListenable: widget.controller.currentIndexNotifier,
          builder: (context, currentIndex, child) {
            return ListView.builder(
                itemCount: widget.destinations.length,
                itemBuilder: (context, index) {
                  final item = widget.destinations[index];
                  final controller = widget.controller;
                  final isNonNavButton = controller.nonViewIndices.contains(index);

                  final hovered = ValueNotifier(false);

                  return MouseRegion(
                    onEnter: (_) => hovered.value = true,
                    onExit: (_) => hovered.value = false,
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        if (item.onClick != null)
                          return item.onClick?.call();
                        else if (!isNonNavButton) controller.currentIndex = index;
                      },
                      child: ValueListenableBuilder(
                        valueListenable: hovered,
                        builder: (context, value, child) {
                          return AnimatedContainer(
                            duration: Duration(milliseconds: widget.controller.animDuration),
                            height: 50,
                            width: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: currentIndex == index && !isNonNavButton
                                  ? (item.selectedColor ?? appTheme.accentColor)
                                  : value ? appTheme.backgroundSubColor.withAlpha(150)  : (item.unselectedColor ?? appTheme.backgroundSubColor),
                            ),
                            margin: EdgeInsets.all(5),
                            child: Icon(
                              item.icon,
                              size: 30,
                              color: currentIndex == index && !isNonNavButton
                                  ? (item.selectedIconColor ?? appTheme.onAccent)
                                  : (item.unselectedIconColor ?? appTheme.textMainColor),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                });
          }),
    );
  }
}
