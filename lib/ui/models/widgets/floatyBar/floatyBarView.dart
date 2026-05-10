import 'package:animestream/ui/models/widgets/floatyBar/controller.dart';
import 'package:flutter/material.dart';

class FloatyBarView extends StatefulWidget {
  final List<Widget> children;
  final FloatyBottomBarController controller;
  const FloatyBarView({super.key, required this.children, required this.controller});

  @override
  State<FloatyBarView> createState() => _FloatyBarViewState();
}

class _FloatyBarViewState extends State<FloatyBarView> {
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
