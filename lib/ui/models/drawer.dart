import 'package:animestream/ui/theme/mainTheme.dart';
import 'package:flutter/material.dart';

class HomeDrawer extends StatefulWidget {
  const HomeDrawer({super.key});

  @override
  State<HomeDrawer> createState() => _HomeDrawerState();
}

class _HomeDrawerState extends State<HomeDrawer> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 250,
      backgroundColor: backgroundColor,
      child: Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: ListView.builder(
          itemCount: 2,
          itemBuilder: (context, index) {
            return InkWell(
              borderRadius: BorderRadius.only(topRight: Radius.circular(25), bottomRight: Radius.circular(25)),
              onTap: () {
                setState(() {
                  selectedIndex = index;
                  print(selectedIndex);
                });
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
                      selectedIndex == index ? themeColor : Colors.transparent,
                ),
                child: Row(
                  children: [
                    Container(
                      margin: EdgeInsets.only(right: 15),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        // color: Colors.white,
                      ),
                      child: Icon(
                        Icons.home,
                        size: 40,
                        color: selectedIndex == index ? Colors.black : Colors.white,
                      ),
                    ),
                    Text(
                      "home",
                      style: TextStyle(color: selectedIndex == index ? Colors.black : textColor),
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
          //         style: TextStyle(color: textColor),
          //       )
          //     ],
          //   ),
          // ),
        ),
      ),
    );
  }

  _getIconAndText(int index) {
    switch(index) {
      case 0:
      return (icon: Icon(Icons.home_rounded), text: "Home");
      case 1:
      return (icon: Image.asset("lib/"));
    }
  } 

  _drawerItem(int index) {
    return InkWell(
              borderRadius: BorderRadius.only(topRight: Radius.circular(25), bottomRight: Radius.circular(25)),
              onTap: () {
                setState(() {
                  selectedIndex = index;
                  print(selectedIndex);
                });
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
                      selectedIndex == index ? themeColor : Colors.transparent,
                ),
                child: Row(
                  children: [
                    Container(
                      margin: EdgeInsets.only(right: 15),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        // color: Colors.white,
                      ),
                      child: Icon(
                        Icons.home,
                        size: 40,
                        color: selectedIndex == index ? Colors.black : Colors.white,
                      ),
                    ),
                    Text(
                      "home",
                      style: TextStyle(color: selectedIndex == index ? Colors.black : textColor),
                    )
                  ],
                ),
              ),
            );
  }
}
