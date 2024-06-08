import 'package:animestream/ui/pages/settingPages/common.dart';
import 'package:animestream/ui/pages/settings.dart';
import 'package:animestream/ui/theme/mainTheme.dart';
import 'package:flutter/material.dart';

class NewHome extends StatefulWidget {
  const NewHome({super.key});

  @override
  State<NewHome> createState() => _NewHomeState();
}

class _NewHomeState extends State<NewHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: pagePadding(context),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.only(left: 20, top: 10, right: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Home",
                    style: TextStyle(
                      color: textMainColor,
                      fontFamily: "Rubik",
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => SettingsPage(),
                      ),
                    ),
                    icon: Icon(
                      Icons.settings_rounded,
                      color: textMainColor,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
