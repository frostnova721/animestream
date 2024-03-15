import 'package:animestream/core/data/hive.dart';
import 'package:animestream/core/database/anilist/login.dart';
import 'package:animestream/core/database/anilist/types.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:animestream/ui/pages/settingPages/common.dart';
import 'package:animestream/ui/theme/mainTheme.dart';
import 'package:flutter/material.dart';

class AccountSetting extends StatefulWidget {
  const AccountSetting({super.key});

  @override
  State<AccountSetting> createState() => _AccountSettingState();
}

class _AccountSettingState extends State<AccountSetting> {
  @override
  void initState() {
    isLoggedIn();
    AniListLogin().getUserProfile().then((res) => setState(() {
          user = res;
          loading = false;
        }));
    super.initState();
  }

  bool anilistLoggedIn = false;
  UserModal? user;
  bool loading = true;

  Future<void> isLoggedIn() async {
    final token = await getVal("token");
    if (token != null || token.isNotEmpty) {
      setState(() {
        anilistLoggedIn = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top,
          bottom: MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          children: [
            topRow(context, "Account"),
            if (!loading)
              Container(
                padding: EdgeInsets.only(left: 20, right: 20),
                child: Column(
                  children: [
                    Container(
                      margin: EdgeInsets.only(bottom: 25),
                      child: Text(
                        "Anilist",
                        style: textStyle(),
                      ),
                    ),
                    anilistLoggedIn
                        ? Container(
                            height: 150,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              image: DecorationImage(
                                image: user?.banner != null
                                    ? NetworkImage(user!.banner!)
                                    : AssetImage(
                                            'lib/assets/images/chisato.jpeg')
                                        as ImageProvider,
                                fit: BoxFit.cover,
                                // opacity: 0.6,
                              ),
                            ),
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              height: 65,
                              padding: EdgeInsets.only(
                                  left: 15, right: 15, bottom: 10, top: 10),
                              decoration: BoxDecoration(
                                color: backgroundColor.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 15),
                                        child: CircleAvatar(
                                          radius: 25,
                                          backgroundImage: user?.avatar != null
                                              ? NetworkImage(user!.avatar!)
                                              : AssetImage(
                                                      "lib/assets/images/ghost.png")
                                                  as ImageProvider,
                                        ),
                                      ),
                                      Text(
                                        user?.name ?? "__NO_NAME_ERR__", //lol
                                        style: textStyle(),
                                      ),
                                    ],
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() async {
                                        await AniListLogin().removeToken();
                                        anilistLoggedIn = false;
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: backgroundColor,
                                        shape: RoundedRectangleBorder(
                                            side:
                                                BorderSide(color: accentColor),
                                            borderRadius:
                                                BorderRadius.circular(35))),
                                    child: Text(
                                      "Logout",
                                      style: TextStyle(
                                        color: accentColor,
                                        fontFamily: "NotoSans",
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Container(
                            child: Column(
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      AniListLogin()
                                          .launchWebView(context)
                                          .then((logged) {
                                        setState(() {
                                          anilistLoggedIn = logged;
                                        });
                                        if (logged) {
                                          floatingSnackBar(
                                              context, "Login successful!");
                                        }
                                      });
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: backgroundColor,
                                      fixedSize: Size(150, 50),
                                      shape: RoundedRectangleBorder(
                                          side: BorderSide(color: accentColor),
                                          borderRadius:
                                              BorderRadius.circular(35))),
                                  child: Text(
                                    "Log In",
                                    style: TextStyle(
                                      color: accentColor,
                                      fontFamily: "NotoSans",
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 15),
                                  child: Text(
                                    "The Animes watched is being saved in local storage.",
                                    style: TextStyle(
                                      color: textSubColor,
                                      fontFamily: "NunitoSans",
                                      fontSize: 12,
                                    ),
                                  ),
                                )
                              ],
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
