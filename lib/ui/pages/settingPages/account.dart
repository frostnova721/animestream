import 'dart:ui';

import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/data/secureStorage.dart';
import 'package:animestream/core/database/anilist/login.dart';
import 'package:animestream/core/database/anilist/types.dart';
import 'package:animestream/core/database/database.dart';
import 'package:animestream/core/database/mal/login.dart';
import 'package:animestream/core/database/simkl/login.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:animestream/ui/pages/settingPages/common.dart';
import 'package:animestream/ui/pages/settingPages/stats.dart';
import 'package:animestream/ui/theme/themeProvider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AccountSetting extends StatefulWidget {
  const AccountSetting({super.key});

  @override
  State<AccountSetting> createState() => _AccountSettingState();
}

class _AccountSettingState extends State<AccountSetting> {
  @override
  void initState() {
    getLoggedIn().then((value) {
      //display login button if not logged in any of accounts
      if (!anilistLoggedIn && !simklLoggedIn && !malLoggedIn) {
        if (mounted)
          setState(() {
            loading = false;
          });
      }

      List<Future> futures = [];
      UserModal? alu, simu, malu;

      //load user profile if logged in
      if (anilistLoggedIn) {
        futures.add(AniListLogin().getUserProfile().then((res) {
          alu = res;
        }));
      }
      if (simklLoggedIn) {
        futures.add(SimklLogin().getUserProfile().then((res) {
          simu = res;
        }));
      }

      if(malLoggedIn) {
        futures.add(MALLogin().getUserProfile().then((res) {
          malu = res;
        }));
      }

      Future.wait(futures).then((val) {
        if (mounted)
          setState(() {
            simklUser = simu;
            user = alu;
            malu = malu;
            loading = false;
          });
      });
    });
    super.initState();
  }

  bool anilistLoggedIn = false;
  bool simklLoggedIn = false;
  bool malLoggedIn = false;

  UserModal? user;
  UserModal? simklUser;
  UserModal? malUser;

  bool loading = true;

  Future<void> getLoggedIn() async {
    final aniToken = await getSecureVal(SecureStorageKey.anilistToken);
    final simklToken = await getSecureVal(SecureStorageKey.simklToken);
    final malToken = await getSecureVal(SecureStorageKey.malToken);
    if (aniToken != null && mounted) {
      setState(() {
        anilistLoggedIn = true;
      });
    }
    if (malToken != null && mounted) {
      setState(() {
        malLoggedIn = true;
      });
    }
    if (simklToken != null && mounted) {
      setState(() {
        simklLoggedIn = true;
      });
    }
  }

  String capitalizeFirstLetter(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1);
  }

  bool getLoginState(Databases db) {
    switch (db) {
      case Databases.anilist:
        return anilistLoggedIn;
      case Databases.simkl:
        return simklLoggedIn;
      case Databases.mal:
        return malLoggedIn;
      // default:
      //   return false; // Default for other databases
    }
  }

  UserModal? getUserModal(String databaseName) {
    switch (databaseName) {
      case "anilist":
        return user;
      case "simkl":
        return simklUser;
      case "mal":
        return malUser;
      default:
        throw Exception("No User for $databaseName");
    }
  }

  Future<bool> Function() getLoginFunction(Databases db) {
    switch (db) {
      case Databases.anilist:
        return AniListLogin().initiateLogin;
      case Databases.simkl:
        return SimklLogin().initiateLogin;
      case Databases.mal:
        return MALLogin().initiateLogin;
      // default:
      //   throw Exception("Login function not defined for $db");
    }
  }

  Future<void> Function() getLogoutFunction(Databases db) {
    switch (db) {
      case Databases.anilist:
        return AniListLogin().removeToken;
      case Databases.simkl:
        return SimklLogin().removeToken;
      case Databases.mal:
        return MALLogin().removeToken;
      // default:
      // throw Exception("Logout function not defined for $db");
    }
  }

  final dbs = Databases.values;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              settingPagesTitleHeader(context, "Account"),
              loading
                  ? Container(
                      padding: EdgeInsets.only(top: 30),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: appTheme.accentColor,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: dbs.length,
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        final db = Databases.values[index];
                        final dbName = capitalizeFirstLetter(db.name);
                        final loggedIn = getLoginState(db);
                        final loginFunction = getLoginFunction(db);
                        final logoutFunction = getLogoutFunction(db);

                        return _databaseAccountCard(
                          context,
                          dbName,
                          loggedIn,
                          loginFunction,
                          logoutFunction,
                        );
                      }),
            ],
          ),
        ),
      ),
    );
  }

  Container _databaseAccountCard(
    BuildContext context,
    String databaseName,
    bool loggedIn,
    Future<bool> Function() onLogin,
    Future<void> Function() onLogout,
  ) {
    return Container(
      padding: EdgeInsets.only(left: 20, right: 20),
      margin: EdgeInsets.only(bottom: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(bottom: 25),
            child: Text(
              capitalizeFirstLetter(databaseName),
              style: textStyle().copyWith(
                fontSize: 24,
              ),
            ),
          ),
          loggedIn
              ? _accountCard(context, onLogout: () {
                  if (mounted)
                    setState(() {
                      onLogout().then(
                        (value) => setState(() {
                          if (databaseName.toLowerCase() == 'anilist') {
                            anilistLoggedIn = false;
                          } else if (databaseName.toLowerCase() == 'simkl') {
                            simklLoggedIn = false;
                          } else if (databaseName.toLowerCase() == 'mal') {
                            malLoggedIn = false;
                          }
                        }),
                      );
                    });
                  floatingSnackBar(context, "Logged out successfully!");
                }, usermodal: getUserModal(databaseName.toLowerCase()))
              : _loginCard(context, onLogin: () {
                  setState(() {
                    onLogin().then((logged) {
                      if (logged) {
                        floatingSnackBar(context, "Login successful!");
                        Provider.of<ThemeProvider>(context, listen: false).justRefresh();
                      }
                      //replace the page with itself to avoid recalling the functions in initState to update the user data
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AccountSetting(),
                        ),
                      );
                    }).onError((err, st) {
                      floatingSnackBar(context, "Login failed! Try again");
                      print(err.toString());
                      print(st.toString());
                    });
                  });
                }),
        ],
      ),
    );
  }

  Container _loginCard(
    BuildContext context, {
    required void Function() onLogin,
  }) {
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: appTheme.backgroundSubColor,
          boxShadow: [BoxShadow(color: appTheme.backgroundSubColor, blurRadius: 5)]),
      padding: EdgeInsets.only(top: 20, bottom: 20),
      height: 150,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: onLogin,
            style: ElevatedButton.styleFrom(
                backgroundColor: appTheme.backgroundColor,
                fixedSize: Size(150, 50),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: appTheme.accentColor),
                  borderRadius: BorderRadius.circular(35),
                )),
            child: Text(
              "Log In",
              style: TextStyle(
                color: appTheme.accentColor,
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
                color: appTheme.textSubColor,
                fontFamily: "NunitoSans",
                fontSize: 12,
              ),
            ),
          )
        ],
      ),
    );
  }

  GestureDetector _accountCard(BuildContext context,
      {required void Function() onLogout, required UserModal? usermodal}) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => UserStats(userModal: usermodal!)));
      },
      child: ClipRRect(
        clipBehavior: Clip.hardEdge,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            image: DecorationImage(
              image: usermodal?.banner != null
                  ? NetworkImage(usermodal!.banner!)
                  : AssetImage('lib/assets/images/profile_banner.jpg') //such a nice image!
                      as ImageProvider,
              fit: BoxFit.cover,
              opacity: 0.75,
            ),
          ),
          // alignment: Alignment.bottomCenter,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundImage: usermodal?.avatar != null
                      ? NetworkImage(usermodal!.avatar!)
                      : AssetImage(
                          "lib/assets/images/ghost.png",
                        ) as ImageProvider,
                  radius: 35,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text(
                          usermodal?.name ?? "UNKNOWN_GUY_69",
                          style: TextStyle(fontFamily: "Poppins", fontSize: 20),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: onLogout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent.withAlpha(50),
                          shape: RoundedRectangleBorder(
                            side: BorderSide(color: appTheme.accentColor),
                            borderRadius: BorderRadius.circular(
                              10,
                            ),
                          ),
                        ),
                        child: Text(
                          "Logout",
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: "NotoSans",
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
