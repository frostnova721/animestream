import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/ui/models/widgets/floatyBar/controller.dart';
import 'package:flutter/material.dart';

class FloatyBarItem {
  final String title;
  final IconData icon;

  const FloatyBarItem({
    required this.title,
    required this.icon,
  });
}

class FloatyBottomBar extends StatefulWidget {
  final List<FloatyBarItem> items;
  final FloatyBottomBarController controller;
  final double height;
  final double bottomPadding;
  final Color backgroundColor;
  final Color accentColor;
  final Duration animationDuration;
  final double detachGap;
  final double outerRadius;
  final double activeRadius;

  const FloatyBottomBar({
    super.key,
    required this.items,
    required this.controller,
    this.height = 50,
    this.bottomPadding = 10,
    this.backgroundColor = Colors.black,
    this.accentColor = const Color(0xffcaf979),
    this.animationDuration = const Duration(milliseconds: 200),
    this.detachGap = 5,
    this.outerRadius = 20,
    this.activeRadius = 20,
  });

  @override
  State<FloatyBottomBar> createState() => _FloatyBottomBarState();
}

class _FloatyBottomBarState extends State<FloatyBottomBar> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.controller.currentIndex;
    widget.controller.currentIndexNotifier.addListener(_onControllerIndexChanged);
  }

  @override
  void dispose() {
    widget.controller.currentIndexNotifier.removeListener(_onControllerIndexChanged);
    super.dispose();
  }

  void _onControllerIndexChanged() {
    final newIndex = widget.controller.currentIndex;
    if (newIndex != _currentIndex) {
      setState(() => _currentIndex = newIndex);
    }
  }

  void _onItemTap(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _currentIndex = index;
      widget.controller.currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final lastIndex = widget.items.length - 1;

    bool hasGapBetween(int leftIndex, int rightIndex) {
      if (leftIndex < 0 || rightIndex > lastIndex) return false;
      final leftIsActive = leftIndex == _currentIndex;
      final rightIsActive = rightIndex == _currentIndex;
      return leftIsActive != rightIsActive;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset + widget.bottomPadding),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          decoration: BoxDecoration(
              color: appTheme.backgroundSubColor, borderRadius: BorderRadius.circular(widget.outerRadius + 2)),
          padding: EdgeInsets.all(5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(widget.items.length, (i) {
              final isActive = i == _currentIndex;
              final hasLeftGap = i > 0 && hasGapBetween(i - 1, i);
              final hasRightGap = i < lastIndex && hasGapBetween(i, i + 1);
              final leftNeighborIsActive = i > 0 && (i - 1) == _currentIndex;
              final rightNeighborIsActive = i < lastIndex && (i + 1) == _currentIndex;
              final segmentRadius = Radius.circular(isActive ? widget.activeRadius : widget.outerRadius);

              return GestureDetector(
                onTap: () => _onItemTap(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: widget.animationDuration,
                  curve: Curves.easeInOut,
                  height: widget.height,
                  margin: EdgeInsets.only(
                    left: hasLeftGap ? widget.detachGap / 2 : 0,
                    right: hasRightGap ? widget.detachGap / 2 : 0,
                  ),
                  decoration: BoxDecoration(
                    color: (isActive ? appTheme.accentColor : widget.accentColor.withAlpha(80)),
                    borderRadius: BorderRadius.only(
                      topLeft: (!isActive && leftNeighborIsActive)
                          ? Radius.zero
                          : (i == 0 || hasLeftGap)
                              ? segmentRadius
                              : Radius.zero,
                      bottomLeft: (!isActive && leftNeighborIsActive)
                          ? Radius.zero
                          : (i == 0 || hasLeftGap)
                              ? segmentRadius
                              : Radius.zero,
                      topRight: (!isActive && rightNeighborIsActive)
                          ? Radius.zero
                          : (i == lastIndex || hasRightGap)
                              ? segmentRadius
                              : Radius.zero,
                      bottomRight: (!isActive && rightNeighborIsActive)
                          ? Radius.zero
                          : (i == lastIndex || hasRightGap)
                              ? segmentRadius
                              : Radius.zero,
                    ),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: isActive ? 16 : 18,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isActive)
                        Icon(
                          widget.items[i].icon,
                          size: 24,
                          color: isActive ? appTheme.onAccent : appTheme.textMainColor,
                        ),
                      AnimatedSize(
                        duration: widget.animationDuration,
                        curve: Curves.easeInOut,
                        child: isActive
                            ? Row(mainAxisSize: MainAxisSize.min, children: [
                                // const SizedBox(width: 8),
                                Text(widget.items[i].title,
                                    style: TextStyle(
                                      color: appTheme.onAccent,
                                      fontFamily: "NotoSans",
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    )),
                              ])
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
