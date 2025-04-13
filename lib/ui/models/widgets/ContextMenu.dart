import 'dart:ui';

import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:flutter/material.dart';

typedef ContextMenuBuilder = Widget Function(BuildContext context, Offset offset);

class ContextMenu extends StatefulWidget {
  final Widget child;
  final Widget? header;
  final List<ContextMenuItem> menuItems;
  const ContextMenu({super.key, required this.child, required this.menuItems, this.header});

  @override
  State<ContextMenu> createState() => _ContextMenuState();
}

class _ContextMenuState extends State<ContextMenu> {
  ContextMenuController controller = ContextMenuController();

  void _showContextMenu(Offset pos) {
    _hideContextMenu();

    final hoverList = List.generate(widget.menuItems.length, (ind) => ValueNotifier<bool>(false));

    const double width = 230 + 8;

    controller.show(
        context: context,
        contextMenuBuilder: (context) => Stack(
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
                        height: (widget.menuItems.length * 40) + 10 + (widget.header != null ? 50 : 0), //add the padding
                        width: width,
                        child: Column(
                          children: [
                            if (widget.header != null) SizedBox(height: 50, child: widget.header!),
                            Expanded(
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
                                            height: 40,
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
                                  return Container(
                                    height: 1,
                                    margin: EdgeInsets.symmetric(horizontal: 20),
                                    color: appTheme.textSubColor.withAlpha(100),
                                  );
                                },
                                itemCount: widget.menuItems.length,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ));
  }

  void _hideContextMenu() {
    controller.remove();
  }

  @override
  void dispose() {
    controller.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
        Icon(
          icon,
          color: Colors.white,
        ),
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
