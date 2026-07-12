import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/data/secureStorage.dart';
import 'package:animestream/core/database/anilist/anilist.dart';
import 'package:animestream/core/database/anilist/login.dart';
import 'package:animestream/core/database/anilist/types.dart';
import 'package:animestream/core/database/database.dart';
import 'package:animestream/core/database/mal/login.dart';
import 'package:animestream/core/database/simkl/login.dart';
import 'package:animestream/core/database/simkl/types.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:animestream/ui/models/widgets/loader.dart';
import 'package:animestream/ui/pages/settingPages/common.dart';
import 'package:animestream/ui/models/providers/appProvider.dart';
import 'package:animestream/ui/pages/settingPages/widgets/database_account_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AccountSetting extends StatefulWidget {
  const AccountSetting({super.key});

  @override
  State<AccountSetting> createState() => _AccountSettingState();
}

class _AccountSettingState extends State<AccountSetting> {
  bool anilistLoggedIn = false;
  bool simklLoggedIn = false;
  bool malLoggedIn = false;
  bool discordLoggedIn = false;

  UserModal? user;
  UserModal? simklUser;
  UserModal? malUser;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await _checkLogins();
    if (!anilistLoggedIn && !simklLoggedIn && !malLoggedIn && !discordLoggedIn) {
      if (mounted) {
        setState(() => loading = false);
      }
      return;
    }

    await Future.wait([
      if (anilistLoggedIn) _fetchAnilistProfile(),
      if (simklLoggedIn) _fetchSimklProfile(),
      if (malLoggedIn) _fetchMalProfile(),
    ]);

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> _checkLogins() async {
    final aniToken = await getSecureVal(SecureStorageKey.anilistToken);
    final simklToken = await getSecureVal(SecureStorageKey.simklToken);
    final malToken = await getSecureVal(SecureStorageKey.malToken);

    if (mounted) {
      setState(() {
        anilistLoggedIn = aniToken != null;
        simklLoggedIn = simklToken != null;
        malLoggedIn = malToken != null;
      });
    }
  }

  Future<void> _fetchAnilistProfile() async {
    try {
      final res = await AniListLogin().getUserProfile();
      if (mounted) setState(() => user = res);
    } catch (err) {
      if (err is AnilistApiException) {
        if (err.statusCode == 401 || err.message.toLowerCase().contains("invalid token")) {
          floatingSnackBar("Anilist token is invalid. Login again!");
          await AniListLogin().removeToken();
          if (mounted) setState(() => anilistLoggedIn = false);
        }
      } else {
        floatingSnackBar("Anilist error: ${err.toString()}");
        if (mounted) setState(() => anilistLoggedIn = false);
      }
    }
  }

  Future<void> _fetchSimklProfile() async {
    try {
      final res = await SimklLogin().getUserProfile();
      if (mounted) setState(() => simklUser = res);
    } on SimklException catch (err) {
      if (err.isUnauthorized) {
        floatingSnackBar("Simkl token is invalid. Login again!");
        await SimklLogin().removeToken();
      }
      if (mounted) setState(() => simklLoggedIn = false);
    } catch (err) {
      if (mounted) setState(() => simklLoggedIn = false);
    }
  }

  Future<void> _fetchMalProfile() async {
    try {
      final res = await MALLogin().getUserProfile();
      if (mounted) setState(() => malUser = res);
    } catch (err) {
      floatingSnackBar("MAL error: ${err.toString()}");
      if (mounted) setState(() => malLoggedIn = false);
    }
  }

  void _handleLogout(Databases db) async {
    switch (db) {
      case Databases.anilist:
        await AniListLogin().removeToken();
        if (mounted) setState(() => anilistLoggedIn = false);
        break;
      case Databases.simkl:
        await SimklLogin().removeToken();
        if (mounted) setState(() => simklLoggedIn = false);
        break;
      case Databases.mal:
        await MALLogin().removeToken();
        if (mounted) setState(() => malLoggedIn = false);
        break;
    }
    floatingSnackBar("Logged out successfully!");
  }

  void _handleLogin(Databases db) async {
    bool logged = false;
    try {
      switch (db) {
        case Databases.anilist:
          logged = await AniListLogin().initiateLogin();
          break;
        case Databases.simkl:
          logged = await SimklLogin().initiateLogin();
          break;
        case Databases.mal:
          logged = await MALLogin().initiateLogin();
          break;
      }

      if (logged) {
        floatingSnackBar("Login successful!");
        if (mounted) {
          Provider.of<AppProvider>(context, listen: false).justRefresh();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AccountSetting()),
          );
        }
      }
    } catch (err) {
      floatingSnackBar("Login failed! Try again");
      print(err.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: pagePadding(context),
          child: Column(
            // crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              settingPagesTitleHeader(context, "Account"),
              loading
                  ? Container(
                      padding: const EdgeInsets.only(top: 30),
                      child: Center(
                        child: AnimeStreamLoading(
                          color: appTheme.accentColor,
                        ),
                      ),
                    )
                  : Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      // runAlignment: WrapAlignment.center,
                      // alignment: WrapAlignment.center,
                      // crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ...Databases.values.map((db) {
                          bool isLoggedIn = false;
                          UserModal? userModal;

                          switch (db) {
                            case Databases.anilist:
                              isLoggedIn = anilistLoggedIn;
                              userModal = user;
                              break;
                            case Databases.simkl:
                              isLoggedIn = simklLoggedIn;
                              userModal = simklUser;
                              break;
                            case Databases.mal:
                              isLoggedIn = malLoggedIn;
                              userModal = malUser;
                              break;
                          }

                          return DatabaseAccountCard(
                            databaseName: db.name,
                            loggedIn: isLoggedIn,
                            userModal: userModal,
                            onLogin: () => _handleLogin(db),
                            onLogout: () => _handleLogout(db),
                          );
                        }).toList(),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
