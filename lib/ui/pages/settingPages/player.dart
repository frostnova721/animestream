import 'package:animestream/ui/pages/settingPages/common.dart';
import 'package:animestream/ui/theme/mainTheme.dart';
import 'package:flutter/material.dart';

class PlayerSetting extends StatefulWidget {
  const PlayerSetting({super.key});

  @override
  State<PlayerSetting> createState() => PlayerSettingState();
}

class PlayerSettingState extends State<PlayerSetting> {
  int skipDuration = 10;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: Container(
          child: Column(
            children: [
              topRow(context, "Player"),
              Container(
                padding: EdgeInsets.only(left: 20, right: 20, top: 30),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Skip duration",
                          style: textStyle(),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  if (skipDuration > 5)
                                    skipDuration = skipDuration - 5;
                                });
                              },
                              icon: Icon(
                                Icons.remove_rounded,
                                color: textMainColor,
                              ),
                            ),
                            Container(
                              alignment: Alignment.center,
                              width: 40,
                              child: Text(
                                "$skipDuration",
                                style: textStyle(),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  if (skipDuration < 50)
                                    skipDuration = skipDuration + 5;
                                });
                              },
                              icon: Icon(
                                Icons.add_rounded,
                                color: textMainColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  TextStyle textStyle() {
    return TextStyle(
      color: textMainColor,
      fontFamily: "NotoSans",
      fontWeight: FontWeight.bold,
      fontSize: 20,
    );
  }
}
