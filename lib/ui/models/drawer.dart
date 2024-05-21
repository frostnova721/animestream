import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/ui/pages/lists.dart';
import 'package:animestream/ui/pages/settingPages/common.dart';
import 'package:animestream/ui/theme/mainTheme.dart';
import 'package:flutter/material.dart';

class HomeDrawer extends StatefulWidget {
  final void Function(int) onItemTapped;
  final int activeIndex;
  final bool loggedIn;
  const HomeDrawer({super.key, required this.onItemTapped, required this.activeIndex, required this.loggedIn});

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
    {'icon': Icons.home_rounded, 'text': "Home"},
    {'icon': "lib/assets/images/shines.png", 'text': 'Discover'},
  ];

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 250,
      backgroundColor: backgroundColor,
      surfaceTintColor: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: Column(
          children: [
            if (widget.loggedIn)
              Container(
                decoration: BoxDecoration(
                    color: backgroundSubColor,
                    boxShadow: [BoxShadow(blurRadius: 5, color: backgroundSubColor, spreadRadius: 1)],
                    borderRadius: BorderRadius.circular(10)),
                padding: EdgeInsets.only(left: 10, right: 10, bottom: 15, top: 15),
                margin: EdgeInsets.only(bottom: 15, left: 10, right: 10, top: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: CircleAvatar(
                        backgroundImage: NetworkImage(storedUserData!.avatar!),
                      ),
                    ),
                    Text(
                      storedUserData?.name ?? "who knows",
                      style: textStyle().copyWith(fontFamily: "Rubik"),
                    )
                  ],
                ),
              ),
            Container(
              padding: EdgeInsets.only(bottom: 10, left: 10, right: 10),
              alignment: Alignment.centerLeft,
              child: Text(
                "Navigate",
                style: textStyle().copyWith(fontSize: 18, fontFamily: "Poppins"),
              ),
            ),
            ListView.builder(
              itemCount: items.length,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemBuilder: (context, index) {
                return InkWell(
                  borderRadius: BorderRadius.only(topRight: Radius.circular(25), bottomRight: Radius.circular(25)),
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
                      color: selectedIndex == index ? accentColor : Colors.transparent,
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
                                  color: selectedIndex == index ? Colors.black : Colors.white,
                                )
                              : Icon(
                                  items[index]['icon'],
                                  size: 40,
                                  color: selectedIndex == index ? Colors.black : Colors.white,
                                ),
                        ),
                        Text(
                          items[index]['text'],
                          style: TextStyle(
                              color: selectedIndex == index ? Colors.black : textMainColor,
                              fontFamily: "NotoSans",
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
            if (widget.loggedIn)
              InkWell(
                borderRadius: BorderRadius.only(topRight: Radius.circular(25), bottomRight: Radius.circular(25)),
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      transitionDuration: Duration(milliseconds: 75),
                      reverseTransitionDuration: Duration(milliseconds: 100),
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          FadeTransition(opacity: animation, child: AnimeLists()),
                    ),
                  );
                },
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  curve: Curves.easeIn,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                    color: Colors.transparent,
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
                        child: Icon(
                          Icons.list_alt_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "Your Lists",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: "NotoSans",
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
