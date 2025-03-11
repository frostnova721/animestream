import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/ui/models/bottomSheets/manualSearchSheet.dart';
import 'package:animestream/ui/models/bottomSheets/serverSelectionSheet.dart';
import 'package:animestream/ui/models/providers/infoProvider.dart';
import 'package:animestream/ui/models/sources.dart';
import 'package:animestream/ui/models/widgets/appWrapper.dart';
import 'package:animestream/ui/models/widgets/infoPageWidgets/commonInfo.dart';
import 'package:animestream/ui/models/widgets/infoPageWidgets/episodeGrid.dart';
import 'package:flutter/material.dart';

class WatchSection extends StatelessWidget {
  final InfoProvider provider;
  final Size size;
  final int splitWidth;
  const WatchSection({super.key, required this.provider, required this.size, required this.splitWidth});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: size.width / 10, top: 30),
          child: Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start, // Align the row contents to the top
                children: [
                  Column(
                    children: [
                      CommonInfo(
                        provider: provider,
                      ),
                      if (size.width < splitWidth)
                        Container(
                          width: size.width / 2,
                          margin: EdgeInsets.only(top: 50),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 1,
                                child: _sourceSection(context),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                flex: 1,
                                child: _buildContinueWatchingPanel(context),
                              ),
                            ],
                          ),
                        ),
                      _episodes(),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        if (size.width >= splitWidth)
          Expanded(
            child: Container(
              padding: EdgeInsets.only(top: 30, right: size.width / 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _sourceSection(context, isSideWidget: true),
                  _continueWatching(context),
                ],
              ),
            ),
          ),
      ],
    );
  }

 // Mobile/Small Window Version
Widget _buildContinueWatchingPanel(BuildContext context) {
  final int watchedProgress = (provider.lastWatchedDurationMap?[provider.watched < provider.epLinks.length ? provider.watched + 1 : provider.watched] ??
          0).toInt();
  
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
                          // Progress label
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
                          
                          // Progress bar
                          Stack(
                            children: [
                              // Background
                              Container(
                                height: 10,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: appTheme.textMainColor.withAlpha(15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              // Foreground
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

                  // Call to action button
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
                        // primary: appTheme.accentColor,
                        // onPrimary: appTheme.onAccent,
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

Widget _continueWatching(BuildContext context) {
  return Container(
    margin: EdgeInsets.only(left: 50, top: 20, bottom: 20),
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
        
        // Main Card
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
                                  Colors.black.withAlpha(179),
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
                      
                      // Play Button Overlay
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
                      
                      // Episode Info Overlay
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
              
              // Progress Section
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title & Progress
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
                    
                    // Progress Bar
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: 0,
                        end: (provider.lastWatchedDurationMap?[provider.watched < provider.epLinks.length ? provider.watched + 1 : provider.watched] ?? 0) / 100,
                      ),
                      duration: Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return Stack(
                          children: [
                            // Background
                            Container(
                              height: 8,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: appTheme.textMainColor.withAlpha(15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            // Foreground
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
                    
                    // Call to action button
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
                          // primary: appTheme.accentColor,
                          // onPrimary: appTheme.onAccent,
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
                              "Select Server & Watch",
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

  Container _episodes() {
    return Container(
      margin: EdgeInsets.only(top: 50, bottom: 50),
      height: (size.height / 1.75),
      width: size.width / (size.width > splitWidth ? 1.75 : 1.3),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: appTheme.backgroundSubColor,
      ),
      child: provider.foundName == null
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              spacing: 30,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Episode",
                        style: _textStyle(),
                      ),
                      if (provider.visibleEpList.isNotEmpty)
                        Row(
                          children: [
                            IconButton.outlined(
                              onPressed: () {
                                if (provider.currentPageIndex == 0) return;
                                provider.currentPageIndex -= 1;
                              },
                              icon: Icon(
                                Icons.arrow_back_ios_rounded,
                                color: appTheme.textMainColor,
                              ),
                              style: ButtonStyle(
                                shape: WidgetStatePropertyAll(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: GestureDetector(
                                onTap: () {
                                  showDialog(
                                      context: AppWrapper.navKey.currentContext!,
                                      builder: (ctx) => Dialog(
                                            backgroundColor: appTheme.backgroundColor,
                                            child: Container(
                                              width: size.width / 3,
                                              height: size.height / 2,
                                              alignment: Alignment.center,
                                              padding: EdgeInsets.all(30),
                                              child: GridView(
                                                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                                                  maxCrossAxisExtent: 100,
                                                  mainAxisExtent: 75,
                                                  mainAxisSpacing: 20,
                                                  crossAxisSpacing: 20,
                                                ),
                                                children: List.generate(
                                                    provider.visibleEpList.length,
                                                    (ind) => GestureDetector(
                                                          onTap: () {
                                                            provider.currentPageIndex = ind;
                                                            Navigator.of(ctx).pop();
                                                          },
                                                          child: Container(
                                                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                                            decoration: BoxDecoration(
                                                                color: provider.currentPageIndex == ind
                                                                    ? appTheme.accentColor
                                                                    : appTheme.backgroundSubColor,
                                                                borderRadius: BorderRadius.circular(10)),
                                                            alignment: Alignment.center,
                                                            child: Text(
                                                              "${provider.visibleEpList[ind].first['realIndex'] + 1}" +
                                                                  "- ${provider.visibleEpList[ind].last['realIndex'] + 1}",
                                                              style: TextStyle(
                                                                color: provider.currentPageIndex == ind
                                                                    ? appTheme.onAccent
                                                                    : appTheme.textMainColor,
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 17,
                                                              ),
                                                            ),
                                                          ),
                                                        )),
                                              ),
                                            ),
                                          ));
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  decoration: BoxDecoration(
                                      color: appTheme.accentColor, borderRadius: BorderRadius.circular(10)),
                                  child: Text(
                                    "${provider.visibleEpList[provider.currentPageIndex].first['realIndex'] + 1}" +
                                        "- ${provider.visibleEpList[provider.currentPageIndex].last['realIndex'] + 1}",
                                    style:
                                        TextStyle(color: appTheme.onAccent, fontWeight: FontWeight.bold, fontSize: 17),
                                  ),
                                ),
                              ),
                            ),
                            IconButton.outlined(
                              onPressed: () {
                                if (provider.currentPageIndex >= provider.visibleEpList.length - 1) return;
                                provider.currentPageIndex += 1;
                              },
                              icon: Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: appTheme.textMainColor,
                              ),
                              style: ButtonStyle(
                                shape: WidgetStatePropertyAll(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      Row(
                        children: [
                          IconButton(
                              style: ButtonStyle(
                                backgroundColor: WidgetStatePropertyAll(
                                    provider.viewMode == 0 ? appTheme.accentColor : Colors.transparent),
                              ),
                              onPressed: () {
                                provider.viewMode = 0;
                              },
                              icon: Icon(
                                Icons.view_list,
                                color: provider.viewMode == 0 ? appTheme.onAccent : appTheme.textMainColor,
                              )),
                          IconButton(
                              style: ButtonStyle(
                                backgroundColor: WidgetStatePropertyAll(
                                    provider.viewMode == 1 ? appTheme.accentColor : Colors.transparent),
                              ),
                              onPressed: () {
                                provider.viewMode = 1;
                              },
                              icon: Icon(
                                Icons.grid_view_sharp,
                                color: provider.viewMode == 1 ? appTheme.onAccent : appTheme.textMainColor,
                              )),
                          IconButton(
                              style: ButtonStyle(
                                backgroundColor: WidgetStatePropertyAll(
                                    provider.viewMode == 2 ? appTheme.accentColor : Colors.transparent),
                              ),
                              onPressed: () {
                                provider.viewMode = 2;
                              },
                              icon: Icon(
                                Icons.grid_on_sharp,
                                color: provider.viewMode == 2 ? appTheme.onAccent : appTheme.textMainColor,
                              )),
                        ],
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: provider.visibleEpList.isEmpty
                      ? Center(child: Text("No episodes!"))
                      : InfoPageEpisodeGrid(provider: provider, size: size),
                ),
              ],
            ),
    );
  }

  Widget _sourceSection(BuildContext context, {bool isSideWidget = false}) {
  String sourceMatchString = "Searching... ";
  IconData statusIcon;
  Color statusColor;
  
  if (provider.foundName != null) {
    bool isMatched = (provider.foundName == provider.data.title['english']) || 
                     (provider.foundName == provider.data.title['romaji']);
    
    sourceMatchString = "Matching title ${isMatched ? "found" : "not found"}";
    statusIcon = isMatched ? Icons.check_circle_rounded : Icons.error_rounded;
    statusColor = isMatched ? Colors.green.shade400 : Colors.orange.shade400;
  } else {
    statusIcon = Icons.search_rounded;
    statusColor = appTheme.textMainColor.withAlpha(153);
  }

  return Container(
    margin: EdgeInsets.only(
      left: isSideWidget ? 50 : 0, 
      bottom: isSideWidget ? 30 : 0,
      top: isSideWidget ? 20 : 0,
      right: isSideWidget ? 0 : 16,
    ),
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
          appTheme.backgroundSubColor.withAlpha(230),
        ],
      ),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          if (isSideWidget)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    appTheme.textMainColor.withAlpha(30),
                    appTheme.textMainColor.withAlpha(15),
                  ],
                ),
                border: Border(
                  bottom: BorderSide(
                    color: appTheme.textMainColor.withAlpha(25),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.source_rounded,
                    size: 18,
                    color: appTheme.accentColor.withAlpha(178),
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Source Selection",
                    style: TextStyle(
                      color: appTheme.textMainColor,
                      fontFamily: "Rubik",
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),

          // Content
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                // Source Dropdown
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(bottom: 10, left: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.playlist_play_rounded,
                              size: 18,
                              color: appTheme.accentColor.withAlpha(178),
                            ),
                            SizedBox(width: 6),
                            Text(
                              "Select Source",
                              style: TextStyle(
                                color: appTheme.textMainColor.withAlpha(220),
                                fontFamily: "Rubik",
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: appTheme.textMainColor.withAlpha(60),
                            width: 1,
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              appTheme.backgroundSubColor.withAlpha(127),
                              appTheme.backgroundSubColor,
                            ],
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: ButtonTheme(
                            alignedDropdown: true,
                            child: DropdownButton<String>(
                              isExpanded: true,
                              menuMaxHeight: 300,
                              icon: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: appTheme.accentColor.withAlpha(25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: appTheme.accentColor,
                                  size: 20,
                                ),
                              ),
                              value: provider.selectedSource,
                              onChanged: (val) {
                                if (val != null) {
                                  provider.selectedSource = val;
                                  provider.getEpisodes();
                                }
                              },
                              dropdownColor: appTheme.backgroundSubColor.withAlpha(242),
                              borderRadius: BorderRadius.circular(14),
                              style: TextStyle(
                                color: appTheme.textMainColor,
                                fontFamily: "Poppins",
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              items: sources
                                  .map((source) => DropdownMenuItem(
                                        value: source,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 6,
                                                height: 6,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: appTheme.accentColor.withAlpha(153),
                                                ),
                                              ),
                                              SizedBox(width: 10),
                                              Text(source),
                                            ],
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Status Card
                AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: appTheme.textMainColor.withAlpha(10),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: provider.foundName == null 
                          ? appTheme.textMainColor.withAlpha(30)
                          : (provider.foundName == provider.data.title['english'] || 
                             provider.foundName == provider.data.title['romaji'])
                              ? Colors.green.withAlpha(50)
                              : Colors.orange.withAlpha(50),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Match Status
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: statusColor.withAlpha(25),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              statusIcon,
                              color: statusColor,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 12),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Source Status",
                                  style: TextStyle(
                                    color: appTheme.textMainColor.withAlpha(150),
                                    fontFamily: "Poppins",
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  sourceMatchString,
                                  style: TextStyle(
                                    color: appTheme.textMainColor.withAlpha(230),
                                    fontFamily: "Poppins",
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 20),

                      // Manual Search Button
                      Container(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final title = provider.data.title['english'] ?? 
                                         provider.data.title['romaji'] ?? 
                                         "no bs";
                            showDialog(
                              context: context,
                              builder: (context) {
                                return Dialog(
                                  backgroundColor: appTheme.backgroundColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Container(
                                    padding: EdgeInsets.all(24),
                                    width: size.width / 3,
                                    height: size.height / 2,
                                    child: ManualSearchSheet(
                                      searchString: title,
                                      source: provider.selectedSource,
                                      anilistId: provider.id.toString(),
                                    ),
                                  ),
                                );
                              },
                            ).then((result) async {
                              if (result == null) return;
                              provider.epSearcherror = false;
                              provider.foundName = null;
                              final links = await getAnimeEpisodes(
                                provider.selectedSource, 
                                result['alias']
                              );

                              provider.paginate(links);
                              provider.foundName = result['name'];
                            });
                          },
                          icon: Icon(
                            Icons.search_rounded,
                            size: 18,
                          ),
                          label: Text(
                            "Manual Search",
                            style: TextStyle(
                              fontFamily: "Poppins",
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              letterSpacing: 0.3,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            // backgroundColor: appTheme.backgroundColor,
                            elevation: 2,
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      
                      // Usage hint text
                      if (provider.foundName == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 14,
                                color: appTheme.textMainColor.withAlpha(130),
                              ),
                              SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  "Use manual search if automatic matching fails",
                                  style: TextStyle(
                                    color: appTheme.textMainColor.withAlpha(130),
                                    fontFamily: "Poppins",
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
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
          ),
        ],
      ),
    ),
  );
}

  TextStyle _textStyle() => TextStyle(fontSize: 25, fontWeight: FontWeight.bold);
}
