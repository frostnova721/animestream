import 'dart:convert';

import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/utils.dart';
import 'package:animestream/ui/theme/mainTheme.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateCheckResult {
  final String latestVersion;
  final String currentVersion;
  final bool preRelease;
  final String downloadLink;
  final String description;

  UpdateCheckResult({
    required this.latestVersion,
    required this.currentVersion,
    required this.preRelease,
    required this.downloadLink,
    required this.description,
  });
}

Future<UpdateCheckResult?> checkForUpdates() async {
  final releasesUrl = 'https://api.github.com/repos/frostnova721/animestream/releases';
  final packageInfo = await PackageInfo.fromPlatform();
  final releasesRes = json.decode(await fetch(releasesUrl))[0];
  final String currentVersion = packageInfo.version;
  final String latestVersion = releasesRes['tag_name'];
  print("current ver: $currentVersion , latest ver: ${latestVersion.replaceAll('v', '')}");
  final String description = releasesRes['body'];
  final bool pre = releasesRes['prerelease'];
  if (!currentUserSettings!.receivePreReleases! && pre) {
    return null;
  }
  if (currentVersion != latestVersion.replaceAll('v', '').split("-")[0]) {
    final apkItem = releasesRes['assets'].where((item) => item['name'] == "app-release.apk").toList();
    final downloadLink = apkItem[0]['browser_download_url'];
    return UpdateCheckResult(
      latestVersion: latestVersion,
      currentVersion: currentVersion,
      preRelease: pre,
      downloadLink: downloadLink,
      description: description,
    );
  } else
    return null;
}

showUpdateSheet(BuildContext context, String markdownText, String downloadLink, bool pre) {
  //dont show the sheet if recievePreRelease if off and release is a pre release
  if(pre && pre != (currentUserSettings?.receivePreReleases! ?? false)) {
    return;
  } 
  showModalBottomSheet(
    showDragHandle: true,
    backgroundColor: Color(0xff121212),
    isScrollControlled: true,
    context: context,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom, left: 15, right: 15, top: 10),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (pre)
                Text(
                  "Test Version",
                  style: TextStyle(color: textSubColor, fontFamily: "Poppins"),
                ),
              Container(
                height: 400,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    MarkdownBody(
                      data: markdownText,
                      styleSheet: MarkdownStyleSheet(
                        h1: style(),
                        h2: style(),
                        listBullet: style(),
                        h3: style(),
                        h4: style(),
                        h5: style(),
                        h6: style(),
                        p: style(),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ElevatedButton(
                        onPressed: () async {
                          final uri = Uri.parse(downloadLink);
                          if (!(await launchUrl(uri))) {
                            throw new Exception("Couldnt launch");
                          }
                          ;
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: BorderSide(
                              color: accentColor,
                            ),
                          ),
                        ),
                        child: Container(
                          child: Text(
                            "download",
                            style: TextStyle(
                              color: backgroundColor,
                              fontFamily: "Rubik",
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 5),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: BorderSide(
                              color: accentColor,
                            ),
                          ),
                        ),
                        child: Container(
                          child: Text("maybe later",
                              style: TextStyle(
                                color: backgroundColor,
                                fontFamily: "Rubik",
                                fontSize: 20,
                              )),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

TextStyle style() {
  return TextStyle(color: textMainColor, fontFamily: "NotoSans");
}
