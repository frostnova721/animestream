import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/ui/models/bottomSheets/serverSelectionSheet.dart';
import 'package:animestream/ui/models/providers/infoProvider.dart';
import 'package:flutter/material.dart';

class ContinueWatchingSideBox extends StatelessWidget {
  final InfoProvider provider;
  const ContinueWatchingSideBox({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Container(
      margin: EdgeInsets.only(left: 60, top: 20, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 15, bottom: 15),
            child: Text(
              "Continue Watching",
              style: TextStyle(
                color: appTheme.textMainColor,
                fontFamily: "Poppins",
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
          Container(
            // width: 350,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: appTheme.backgroundSubColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(40),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                  spreadRadius: 1,
                ),
              ],
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  appTheme.backgroundSubColor,
                  appTheme.backgroundSubColor.withAlpha(230),
                ],
              ),
            ),
            child: Column(
              children: [
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return Dialog(
                            backgroundColor: appTheme.backgroundColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Container(
                              padding: EdgeInsets.all(20),
                              width: size.width / 3,
                              child: ServerSelectionBottomSheet(
                                provider: provider,
                                episodeIndex: provider.watched,
                                type: ServerSheetType.watch,
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                          child: Container(
                            height: 180,
                            width: double.infinity,
                            child: ShaderMask(
                              shaderCallback: (rect) {
                                return LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withAlpha(150),
                                    Colors.black.withAlpha(230),
                                  ],
                                ).createShader(rect);
                              },
                              blendMode: BlendMode.darken,
                              child: Image.network(
                                provider.data.banner ?? provider.data.cover,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: appTheme.backgroundSubColor.withAlpha(127),
                                  child: Center(
                                    child: Icon(
                                      Icons.image_not_supported_rounded,
                                      color: appTheme.textMainColor.withAlpha(76),
                                      size: 40,
                                    ),
                                  ),
                                ),
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: appTheme.backgroundSubColor.withAlpha(127),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(appTheme.accentColor),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: appTheme.accentColor.withAlpha(51),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: appTheme.accentColor.withAlpha(127),
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 45,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withAlpha(179),
                                ],
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${provider.started ? 'Continue' : 'Start'}",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: "Poppins",
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "Episode ${provider.watched >= provider.epLinks.length ? provider.watched : provider.watched + 1}",
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(204),
                                    fontFamily: "Poppins",
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Your Progress",
                            style: TextStyle(
                              color: appTheme.textMainColor,
                              fontFamily: "Poppins",
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: appTheme.accentColor.withAlpha(51),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "${(provider.lastWatchedDurationMap?[provider.watched < provider.epLinks.length ? provider.watched + 1 : provider.watched] ?? 0).toInt()}%",
                              style: TextStyle(
                                color: appTheme.accentColor,
                                fontFamily: "Poppins",
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 15),
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(
                          begin: 0,
                          end: (provider.lastWatchedDurationMap?[provider.watched < provider.epLinks.length
                                      ? provider.watched + 1
                                      : provider.watched] ??
                                  0) /
                              100,
                        ),
                        duration: Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) {
                          return Stack(
                            children: [
                              Container(
                                height: 8,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: appTheme.textMainColor.withAlpha(15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              Container(
                                height: 8,
                                width: 350 * value,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      appTheme.accentColor,
                                      appTheme.accentColor.withAlpha(204),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: appTheme.accentColor.withAlpha(76),
                                      blurRadius: 6,
                                      offset: Offset(0, 0),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return Dialog(
                                  backgroundColor: appTheme.backgroundColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Container(
                                    padding: EdgeInsets.all(20),
                                    width: size.width / 3,
                                    child: ServerSelectionBottomSheet(
                                      provider: provider,
                                      episodeIndex: provider.watched,
                                      type: ServerSheetType.watch,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.play_circle_filled_rounded, size: 18),
                              SizedBox(width: 8),
                              Text(
                                "Watch",
                                style: TextStyle(
                                  fontFamily: "Poppins",
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ContinueWatchingBodyBox extends StatelessWidget {
  final InfoProvider provider;
  const ContinueWatchingBodyBox({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final int watchedProgress = (provider.lastWatchedDurationMap?[
                provider.watched < provider.epLinks.length ? provider.watched + 1 : provider.watched] ??
            0)
        .toInt();
        final size = MediaQuery.sizeOf(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => showDialog(
          context: context,
          builder: (context) {
            return Dialog(
              backgroundColor: appTheme.backgroundColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                padding: EdgeInsets.all(20),
                width: size.width / 3,
                child: ServerSelectionBottomSheet(
                  provider: provider,
                  episodeIndex: provider.watched,
                  type: ServerSheetType.watch,
                ),
              ),
            );
          },
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: appTheme.backgroundSubColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(30),
                blurRadius: 15,
                offset: Offset(0, 5),
                spreadRadius: 1,
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                appTheme.backgroundSubColor,
                appTheme.backgroundSubColor.withAlpha(204),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      appTheme.accentColor.withAlpha(50),
                      appTheme.accentColor.withAlpha(15),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Continue Episode ${provider.watched + 1}",
                      style: TextStyle(
                        color: appTheme.textMainColor,
                        fontFamily: "Poppins",
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: appTheme.accentColor.withAlpha(70),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: appTheme.accentColor,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: watchedProgress.toDouble() / 100),
                      duration: Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Your progress",
                                    style: TextStyle(
                                      color: appTheme.textMainColor.withAlpha(204),
                                      fontFamily: "Poppins",
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: appTheme.accentColor.withAlpha(51),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      "$watchedProgress%",
                                      style: TextStyle(
                                        color: appTheme.accentColor,
                                        fontFamily: "Poppins",
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Stack(
                              children: [
                                Container(
                                  height: 10,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: appTheme.textMainColor.withAlpha(15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                Container(
                                  height: 10,
                                  width: size.width / 5 * value, // This value is roughly the size of bar
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        appTheme.accentColor,
                                        appTheme.accentColor.withAlpha(204),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: appTheme.accentColor.withAlpha(76),
                                        blurRadius: 8,
                                        offset: Offset(0, 0),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),

                    SizedBox(height: 24),

                    Container(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => showDialog(
                          context: context,
                          builder: (context) {
                            return Dialog(
                              backgroundColor: appTheme.backgroundColor,
                              child: Container(
                                padding: EdgeInsets.all(20),
                                width: size.width / 3,
                                child: ServerSelectionBottomSheet(
                                  provider: provider,
                                  episodeIndex: provider.watched,
                                  type: ServerSheetType.watch,
                                ),
                              ),
                            );
                          },
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_circle_filled_rounded, size: 18),
                            SizedBox(width: 8),
                            Text(
                              "Continue Watching",
                              style: TextStyle(
                                fontFamily: "Poppins",
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
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
    );
  }
}
