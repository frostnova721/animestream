import 'dart:math';
import 'dart:ui';

import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/database/anilist/queries.dart';
import 'package:animestream/core/database/anilist/types.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:animestream/ui/pages/settingPages/common.dart';
import 'package:flutter/material.dart';

class UserStats extends StatefulWidget {
  final UserModal userModal;
  const UserStats({super.key, required this.userModal});

  @override
  State<UserStats> createState() => _UserStatsState();
}

class _UserStatsState extends State<UserStats> {
  @override
  void initState() {
    user = widget.userModal;
    fetchUserStats();
    super.initState();
  }

  Future<void> fetchUserStats() async {
    try {
      final res = await AnilistQueries().getUserStats(user.name);
      final genreRes = await AnilistQueries().getGenreThumbnail(res.genres[0].genre);
      setState(() {
        stats = res;
        genreThumbnail = genreRes.length > 0 ? genreRes[Random().nextInt(genreRes.length)] : null;
        timeSpent = convertMinutes(res.minutesWatched);
      });
    } catch (err) {
      if (currentUserSettings?.showErrors == true) {
        floatingSnackBar(context, err.toString());
      }
    }
  }

  late UserModal user;
  String? genreThumbnail;
  AnilistUserStats? stats;

  ({int minutes, int hours, int days, int months, int years})? timeSpent;

  TextStyle textStyle(double fontSize, {bool bold = false, String fontFamily = "NotoSans-Bold"}) => TextStyle(
        color: appTheme.textMainColor,
        fontFamily: fontFamily,
        fontSize: fontSize,
        fontWeight: bold ? FontWeight.bold : null,
      );

  ({int minutes, int hours, int days, int months, int years}) convertMinutes(int minutes) {
    int minutesInYear = 60 * 24 * 365;
    int minutesInMonth = 60 * 24 * 30;
    int minutesInDay = 60 * 24;
    int minutesInHour = 60;

    int years = minutes ~/ minutesInYear;
    int months = (minutes % minutesInYear) ~/ minutesInMonth;
    int days = ((minutes % minutesInYear) % minutesInMonth) ~/ minutesInDay;
    int hours = (((minutes % minutesInYear) % minutesInMonth) % minutesInDay) ~/ minutesInHour;
    int remainingMinutes = (((minutes % minutesInYear) % minutesInMonth) % minutesInDay) % minutesInHour;

    return (minutes: remainingMinutes, hours: hours, days: days, months: months, years: years);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back_rounded,
          color: appTheme.textMainColor,),
        ),
        backgroundColor: appTheme.backgroundColor,
        title: Text(
          "Stats",
          style: TextStyle(color: Colors.white, fontFamily: "Poppins", fontSize: 25),
        ),
      ),
      body: stats != null
          ? Container(
              padding: pagePadding(context).copyWith(top: 0),
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(decelerationRate: ScrollDecelerationRate.fast),
                child: Column(
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 30, left: 15, right: 15),
                      child: Column(
                        // crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            alignment: Alignment.center,
                            child: CircleAvatar(
                              backgroundImage: user.avatar != null
                                  ? NetworkImage(user.avatar!)
                                  : AssetImage('lib/assets/images/chisato_AI.png') as ImageProvider,
                              backgroundColor: Colors.grey,
                              radius: 50,
                            ),
                          ),
                          Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.only(top: 15),
                            child: Text(
                              "${user.name}",
                              style: textStyle(22, bold: true),
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.only(top: 30),
                            child: Text(
                              "Stats",
                              style: textStyle(23, bold: true, fontFamily: "Rubik"),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.only(top: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Animes watched/watching: ",
                                      style: textStyle(18, bold: true),
                                    ),
                                    Text(
                                      "${stats!.notInPlanned}",
                                      style: textStyle(18),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Episodes watched: ",
                                      style: textStyle(18, bold: true),
                                    ),
                                    Text(
                                      "${stats!.episodesWatched}",
                                      style: textStyle(18),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Total time: ",
                                      style: textStyle(18, bold: true),
                                    ),
                                    Text(
                                      "${stats!.minutesWatched} minutes ",
                                      style: textStyle(17),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            actions: [
                                              TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: Text("aight!"))
                                            ],
                                            backgroundColor: appTheme.backgroundSubColor,
                                            content: Text(
                                              "Its about ${timeSpent!.years} years, ${timeSpent!.months} months, ${timeSpent!.days} days, ${timeSpent!.hours} hours and ${timeSpent!.minutes} minutes!",
                                              style: textStyle(18),
                                            ),
                                          ),
                                        );
                                      },
                                      child: Icon(
                                        Icons.info_outline_rounded,
                                        color: appTheme.textMainColor,
                                        size: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.only(top: 30),
                            child: Text(
                              "Most Watched Genre",
                              style: textStyle(23, bold: true, fontFamily: "Rubik"),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.only(
                              top: 20,
                            ),
                            child: Container(
                              width: 400,
                              height: 150,
                              padding: EdgeInsets.only(left: 15, top: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                image: DecorationImage(
                                    image: genreThumbnail != null
                                        ? NetworkImage(genreThumbnail!)
                                        : AssetImage('lib/assets/images/chisato.jpeg') as ImageProvider,
                                    fit: BoxFit.cover,
                                    opacity: 0.55),
                              ),
                              child: ClipRRect(
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${stats!.genres[0].genre}",
                                        style: textStyle(35, fontFamily: "Poppins", bold: true),
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            "watched: ",
                                            style: textStyle(18, bold: true),
                                          ),
                                          Text(
                                            "${stats!.genres[0].count}",
                                            style: textStyle(17),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            "Time spent: ",
                                            style: textStyle(18, bold: true),
                                          ),
                                          Text(
                                            "${stats!.genres[0].minutesWatched} min",
                                            style: textStyle(17),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.only(top: 35),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                    alignment: Alignment.centerLeft,
                                    width: (MediaQuery.of(context).size.width / 3 + 10) -
                                        MediaQuery.of(context).padding.left,
                                    child: Text(
                                      "Genre",
                                      style: textStyle(21, bold: true, fontFamily: "Rubik"),
                                    )),
                                Container(
                                    alignment: Alignment.center,
                                    width: (MediaQuery.of(context).size.width / 3 - 20) -
                                        MediaQuery.of(context).padding.left,
                                    child: Text(
                                      "Watched",
                                      style: textStyle(21, bold: true, fontFamily: "Rubik"),
                                    )),
                                Container(
                                    alignment: Alignment.centerRight,
                                    width: (MediaQuery.of(context).size.width / 3 - 20) -
                                        MediaQuery.of(context).padding.left,
                                    child: Text(
                                      "Minutes",
                                      style: textStyle(21, bold: true, fontFamily: "Rubik"),
                                    ))
                              ],
                            ),
                          ),
                          ListView.builder(
                            padding: EdgeInsets.only(top: 20),
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: stats!.genres.length,
                            itemBuilder: (context, index) => Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                    alignment: Alignment.centerLeft,
                                    width: (MediaQuery.of(context).size.width / 3 + 10) -
                                        MediaQuery.of(context).padding.left,
                                    child: Text(
                                      "${stats!.genres[index].genre}",
                                      style: textStyle(18, bold: true),
                                    )),
                                Container(
                                    alignment: Alignment.center,
                                    width: (MediaQuery.of(context).size.width / 3 - 20) -
                                        MediaQuery.of(context).padding.left,
                                    child: Text(
                                      "${stats!.genres[index].count}",
                                      style: textStyle(18, bold: true),
                                    )),
                                Container(
                                    alignment: Alignment.centerRight,
                                    width: (MediaQuery.of(context).size.width / 3 - 20) -
                                        MediaQuery.of(context).padding.left,
                                    child: Text(
                                      "${stats!.genres[index].minutesWatched}",
                                      style: textStyle(18, bold: true),
                                    ))
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    Container(
                      height: MediaQuery.of(context).padding.bottom + 10,
                    ),
                  ],
                ),
              ),
            )
          : Center(
              child: CircularProgressIndicator(
                color: appTheme.accentColor,
              ),
            ),
    );
  }
}
