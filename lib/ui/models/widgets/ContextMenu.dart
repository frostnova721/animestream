import 'dart:ui';

import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:flutter/material.dart';

typedef ContextMenuBuilder = Widget Function(BuildContext context, Offset offset);

class ContextMenu extends StatefulWidget {
  final Widget child;
  final List<ContextMenuItem> menuItems;
  const ContextMenu({super.key, required this.child, required this.menuItems});

  @override
  State<ContextMenu> createState() => _ContextMenuState();
}

class _ContextMenuState extends State<ContextMenu> {
  OverlayEntry? _overlayEntry;

  void _showContextMenu(Offset pos) {
    _hideContextMenu();

    final hoverList = List.generate(widget.menuItems.length, (ind) => ValueNotifier<bool>(false));

    _overlayEntry = OverlayEntry(builder: (context) {
      const double width = 230 + 8;
      return Stack(
        children: [
          Positioned.fill(
              child: GestureDetector(
            onTap: () => _hideContextMenu(),
            behavior: HitTestBehavior.translucent,
          )),
          Positioned(
            top: pos.dy,
            left: pos.dx + width > MediaQuery.of(context).size.width ? pos.dx - width : pos.dx,
            child: ClipRRect(
              clipBehavior: Clip.antiAlias,
              borderRadius: BorderRadius.circular(10),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: appTheme.textMainColor.withAlpha(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(150),
                        blurRadius: 1,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  height: (widget.menuItems.length * 40) + 8, //add the padding
                  width: width,
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    physics: NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      return MouseRegion(
                        onEnter: (event) => hoverList[index].value = true,
                        onExit: (event) => hoverList[index].value = false,
                        child: ValueListenableBuilder(
                          valueListenable: hoverList[index],
                          builder: (context, hovered, child) => GestureDetector(
                            onTap: () {
                              widget.menuItems[index].onClick();
                              _hideContextMenu();
                            },
                            child: Container(
                                decoration: BoxDecoration(
                                    color: hovered ? Colors.white.withAlpha(10) : null,
                                    borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: widget.menuItems[index]),
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (context, int) {
                      return Divider(
                        color: appTheme.textSubColor,
                      );
                    },
                    itemCount: widget.menuItems.length,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideContextMenu() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _hideContextMenu(),
      onSecondaryTapUp: (details) {
        _showContextMenu(details.globalPosition);
      },
      child: widget.child,
    );
  }
}

class ContextMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onClick;

  ContextMenuItem({required this.icon, required this.label, required this.onClick});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white,),
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            label,
            style: TextStyle(fontFamily: "NotoSans", fontSize: 16, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
