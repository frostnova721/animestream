import 'package:animestream/ui/theme/mainTheme.dart';
import 'package:flutter/material.dart';

class HomeDrawer extends StatefulWidget {
  final void Function(int) onItemTapped;
  final int activeIndex;
  const HomeDrawer(
      {super.key, required this.onItemTapped, required this.activeIndex});

  @override
  State<HomeDrawer> createState() => _HomeDrawerState();
}

class _HomeDrawerState extends State<HomeDrawer> {
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.activeIndex;
  }

  List<Map<String, dynamic>> items = [
    {'icon': Icons.home, 'text': "Home"},
    {'icon': "lib/assets/images/shines.png", 'text': 'Discover'}
  ];

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 250,
      backgroundColor: backgroundColor,
      child: Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            return InkWell(
              borderRadius: BorderRadius.only(
                  topRight: Radius.circular(25),
                  bottomRight: Radius.circular(25)),
              onTap: () {
                setState(() {
                  selectedIndex = index;
                });
                widget.onItemTapped(index);
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                curve: Curves.easeIn,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                  color:
                      selectedIndex == index ? accentColor : Colors.transparent,
                ),
                child: Row(
                  children: [
                    Container(
                      height: 50,
                      width: 50,
                      margin: EdgeInsets.only(right: 15),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        // color: Colors.white,
                      ),
                      child: index == 1
                          ? Image.asset(
                              items[index]['icon'],
                              scale: 19,
                              color: selectedIndex == index
                                  ? Colors.black
                                  : Colors.white,
                            )
                          : Icon(
                              items[index]['icon'],
                              size: 40,
                              color: selectedIndex == index
                                  ? Colors.black
                                  : Colors.white,
                            ),
                    ),
                    Text(
                      items[index]['text'],
                      style: TextStyle(
                          color: selectedIndex == index
                              ? Colors.black
                              : textMainColor,
                          fontFamily: "NotoSans",
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
            );
          },
          // Container(
          //   child: Row(
          //     children: [
          //       Container(
          //           margin: EdgeInsets.only(right: 15),
          //           decoration: BoxDecoration(
          //               borderRadius: BorderRadius.circular(100),
          //               color: Colors.white),
          //           child: Icon(
          //             Icons.start,
          //             size: 40,
          //           )),
          //       Text(
          //         "star",
          //         style: TextStyle(color: textMainColor),
          //       )
          //     ],
          //   ),
          // ),
        ),
      ),
    );
  }
}
