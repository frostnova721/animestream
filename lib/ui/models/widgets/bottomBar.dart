import 'package:flutter/material.dart';

class BottomBarItem {
  final String title;
  final Widget icon;

  BottomBarItem({
    required this.title,
    required this.icon,
  });
}

class AnimeStreamBottomBar extends StatefulWidget {
  final List<BottomBarItem> items;
  final AnimeStreamBottomBarController controller;
  final double width;
  final double height;
  final double bottomPadding;
  final Color backgroundColor;
  final double borderRadius;
  final Color accentColor;

  const AnimeStreamBottomBar({
    super.key,
    required this.items,
    required this.controller,
    this.width = 250,
    this.height = 55,
    this.bottomPadding = 10,
    this.backgroundColor = Colors.black,
    this.borderRadius = 0,
    this.accentColor = const Color(0xffcaf979),
  });

  @override
  State<AnimeStreamBottomBar> createState() => _AnimeStreamBottomBarState();
}

class _AnimeStreamBottomBarState extends State<AnimeStreamBottomBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.currentIndexNotifier.addListener(_onControllerIndexChanged);
  }

  @override
  void dispose() {
    widget.controller.currentIndexNotifier.removeListener(_onControllerIndexChanged);
    super.dispose();
  }

  void _onControllerIndexChanged() {
    setState(() {});
  }

  void onItemTap(int val) {
    setState(() {
      widget.controller.currentIndex = val;
      // currentIndex = val;
    });
  }

  List<Widget> generateWidgets() {
    return widget.items.map((e) {
      final itIndex = widget.items.indexOf(e);
      bool isSelected = itIndex == widget.controller.currentIndex;

      return InkWell(
        onTap: () => onItemTap(itIndex),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: Duration(milliseconds: 200),
              alignment: Alignment.center,
              height: widget.height - 5,
              width: widget.width / widget.items.length,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: child,
                        alignment: Alignment.bottomCenter,
                      );
                    },
                    duration: Duration(milliseconds: widget.controller.animDuration),
                    child: isSelected
                        ? Text(
                            e.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: widget.accentColor, fontWeight: FontWeight.bold),
                          )
                        : e.icon,
                  ),
                ],
              ),
            ),
            // if (isSelected)
            AnimatedSwitcher(
              duration: Duration(milliseconds: widget.controller.animDuration),
              transitionBuilder: (child, animation) {
                return SlideTransition(
                    position: animation.drive(Tween<Offset>(begin: Offset(0, 1), end: Offset(0, 0))), child: child);
              },
              child: isSelected
                  ? Container(
                      height: 5,
                      width: (widget.width / widget.items.length) - 20,
                      decoration: BoxDecoration(
                        color: widget.accentColor,
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(5), topRight: Radius.circular(5)),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + widget.bottomPadding),
      child: Align(
        alignment: Alignment.bottomCenter,
        // mainAxisAlignment: MainAxisAlignment.end,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Container(
            color: widget.backgroundColor,
            width: widget.width,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.max,
                children: generateWidgets()),
          ),
        ),
      ),
    );
  }
}

class BottomBarView extends StatefulWidget {
  final List<Widget> children;
  final AnimeStreamBottomBarController controller;
  const BottomBarView({super.key, required this.children, required this.controller});

  @override
  State<BottomBarView> createState() => _BottomBarViewState();
}

class _BottomBarViewState extends State<BottomBarView> {
  @override
  void initState() {
    super.initState();
    widget.controller.currentIndexNotifier.addListener(_onControllerIndexChanged);
  }

  @override
  void dispose() {
    widget.controller.currentIndexNotifier.removeListener(_onControllerIndexChanged);
    super.dispose();
  }

  void _onControllerIndexChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (widget.children.length < 2) {
      throw Exception("BottomBarView requires at least 2 children");
    }
    if ((widget.controller.length - widget.controller.nonViewIndices.length) != widget.children.length) {
      throw Exception("Index out of bounds");
    }

    // Generate list based on available views
    List<int> viewIndices = List.generate(widget.controller.length, (i) => i)
        .where((i) => !widget.controller.nonViewIndices.contains(i))
        .toList();

    final activeViewIndex = viewIndices.indexOf(widget.controller.currentIndex);

    if (activeViewIndex == -1)
      throw Exception(
        [
          "The index of active views recieved as -1.",
          "This usually means that you have only provided a non view buttons to controller"
        ].join(" "),
      );

    // return widget.children[widget.controller.currentIndex];
    return AnimatedSwitcher(
      duration: Duration(milliseconds: widget.controller.animDuration),
      reverseDuration: Duration(milliseconds: widget.controller.animDuration),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: widget.children[activeViewIndex],
    );
  }
}

class AnimeStreamBottomBarController {
  final int length;
  final List<int> nonViewIndices;
  final int animDuration;
  // late int currentIndex;

  ValueNotifier<int> currentIndexNotifier;

  int get currentIndex => currentIndexNotifier.value;

  set currentIndex(int index) {
    if (!nonViewIndices.contains(index)) currentIndexNotifier.value = index;
  }

  AnimeStreamBottomBarController({
    required this.length,
    this.nonViewIndices = const [],
    this.animDuration = 200,
  }) : currentIndexNotifier = ValueNotifier<int>(0);
}
