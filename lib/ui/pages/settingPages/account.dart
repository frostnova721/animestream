import 'dart:ui';

import 'package:animestream/core/data/hive.dart';
import 'package:animestream/core/database/anilist/login.dart';
import 'package:animestream/core/database/anilist/types.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:animestream/ui/pages/settingPages/common.dart';
import 'package:animestream/ui/pages/settingPages/stats.dart';
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
    isLoggedIn().then((value) {
      //load user profile if logged in
      if (value) {
        AniListLogin().getUserProfile().then((res) {
          if (mounted)
            setState(() {
              user = res;
              loading = false;
            });
        });
      }
      //display login button if not logged in
      else {
        if (mounted)
          setState(() {
            loading = false;
          });
      }
    });
    super.initState();
  }

  bool anilistLoggedIn = false;
  UserModal? user;
  bool loading = true;

  Future<bool> isLoggedIn() async {
    final token = await getVal("token");
    if (token != null && mounted) {
      setState(() {
        anilistLoggedIn = true;
      });
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              settingPagesTitleHeader(context, "Account"),
              loading
                  ? Center(
                    child: CircularProgressIndicator(
                      color: accentColor,
                    ),
                  )
                  : Container(
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
                                                  'lib/assets/images/profile_banner.jpg') //such a nice image!
                                              as ImageProvider,
                                      fit: BoxFit.cover,
                                      // opacity: 0.6,
                                    ),
                                  ),
                                  alignment: Alignment.bottomCenter,
                                  child: ClipRRect(
                                    child: BackdropFilter(
                                      filter:
                                          ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                                      child: Container(
                                        height: 65,
                                        padding: EdgeInsets.only(
                                            left: 15,
                                            right: 15,
                                            bottom: 10,
                                            top: 10),
                                        decoration: BoxDecoration(
                                          color: backgroundColor.withOpacity(0.5),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            InkWell(
                                              onTap: () {
                                                Navigator.of(context).push(MaterialPageRoute(builder: (context) => UserStats(userModal: user!,)));
                                              },
                                              child: Row(
                                                children: [
                                                  Padding(
                                                    padding: const EdgeInsets.only(
                                                        right: 15),
                                                    child: CircleAvatar(
                                                      radius: 25,
                                                      backgroundColor: textSubColor,
                                                      backgroundImage:
                                                          user?.avatar != null
                                                              ? NetworkImage(
                                                                  user!.avatar!)
                                                              : AssetImage(
                                                                  "lib/assets/images/ghost.png",
                                                                ) as ImageProvider,
                                                    ),
                                                  ),
                                                  Text(
                                                    user?.name ??
                                                        "NO_NAME_ERR", //lol
                                                    style: TextStyle(
                                                        color: textMainColor,
                                                        fontFamily: "NotoSans",
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 20,
                                                        overflow:
                                                            TextOverflow.ellipsis),
                                                    maxLines: 2,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                if(mounted)
                                                setState(() {
                                                  AniListLogin()
                                                      .removeToken()
                                                      .then(
                                                        (value) => setState(() {
                                                          anilistLoggedIn = false;
                                                        }),
                                                      );
                                                });
                                                floatingSnackBar(context, "Logged out successfully!");
                                              },
                                              style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  shape: RoundedRectangleBorder(
                                                      side: BorderSide(
                                                          color: accentColor),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              35))),
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
                                              if (logged) {
                                                floatingSnackBar(
                                                    context, "Login successful!");
                                              }
                                              //replace the page with itself to avoid recalling the functions in initState to update the user data
                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      AccountSetting(),
                                                ),
                                              );
                                            });
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: backgroundColor,
                                            fixedSize: Size(150, 50),
                                            shape: RoundedRectangleBorder(
                                              side:
                                                  BorderSide(color: accentColor),
                                              borderRadius:
                                                  BorderRadius.circular(35),
                                            )),
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
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
