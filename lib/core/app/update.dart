import 'dart:convert';
import 'dart:io';

import 'package:animestream/core/app/logging.dart';
import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/utils.dart';
import 'package:animestream/ui/models/bottomSheets/updateSheet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

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

  @override
  String toString() {
    return 'UpdateCheckResult(latestVersion: $latestVersion, currentVersion: $currentVersion, preRelease: $preRelease, downloadLink: $downloadLink, description: $description)';
  }
}

/// Alright! the versioning is like: v?n.n.n(-stage?)
/// n are the numbers. follows the scheme like super-major.okaish.minor (dependent on changes in quality)
/// v is when the update is parsed from github api.
/// stage can be alpha, beta, gamma(dev) (these are rare and arent present most time)
Future<UpdateCheckResult?> checkForUpdates() async {
  try {
    final releasesUrl = 'https://api.github.com/repos/frostnova721/animestream/releases';
    final packageInfo = await PackageInfo.fromPlatform();
    final releasesRes = json.decode(await fetch(releasesUrl))[0];
    final String currentVersion = packageInfo.version;
    final String latestVersion = releasesRes['tag_name'];
    Logs.app.log("<UPDATE-CHECK> current ver: $currentVersion , latest ver: ${latestVersion.replaceAll('v', '')}");
    final String description = releasesRes['body'];
    final bool pre = releasesRes['prerelease'];
    if (!currentUserSettings!.receivePreReleases! && pre) {
      return null;
    }

    bool triggerSheet = true; // Change this flag for triggering the sheet for debugging
    // int? currentVersionJoined, latestVersionJoined;

    final latestVersionCode = latestVersion.replaceAll('v', '');
    final versionNumber = latestVersionCode.split("-")[0];

    bool isAnUpgrade = false;

    try {
      isAnUpgrade = _checkIfTheNewVersionIsActuallyAnUpgrade(latestVersionCode, currentVersion);
    } catch (err) {
      // old version check logic as a backup method!
      if (currentVersion.split("-").firstOrNull != versionNumber) triggerSheet = true;
    }

    // we can assert not null since we do null check in try statement & the comparison wont occur if theres an issue
    if (triggerSheet || isAnUpgrade) {
      Logs.app.log("<UPDATE-CHECK> UPDATE AVAILABLE!!!");
      final List<dynamic> apkItem = releasesRes['assets']
          .where((item) => item['name'] == (Platform.isAndroid ? "app-release.apk" : "animestream-x86_64.exe"))
          .toList();
      if (apkItem.isEmpty) return null;
      final downloadLink = apkItem[0]['browser_download_url'];
      return UpdateCheckResult(
        latestVersion: latestVersion,
        currentVersion: currentVersion,
        preRelease: pre,
        downloadLink: downloadLink,
        description: description,
      );
    } else {
      Logs.app.log("<UPDATE-CHECK> APP IS ALREADY UP-TO-DATE!");
      return null;
    }
  } catch (err) {
    // graceful quitting
    Logs.app.log("<UPDATE-CHECK> Update check failed. \n$err");
    return null;
  }
}

// Naming Conventions?
bool _checkIfTheNewVersionIsActuallyAnUpgrade(String newVersion, String oldVersion) {
  final oldParts = oldVersion.split('-').first.split('.');
  final newParts = newVersion.split('-').first.split('.');

  if (oldParts.length < 3 || newParts.length < 3) {
    return false;
  }

  // Parse the version parts to integers
  final (oldMajor, oldMinor, oldPatch) =
      (int.tryParse(oldParts[0]), int.tryParse(oldParts[1]), int.tryParse(oldParts[2]));
  final (newMajor, newMinor, newPatch) =
      (int.tryParse(newParts[0]), int.tryParse(newParts[1]), int.tryParse(newParts[2]));

  // probably redundant but yeah!
  if (oldMajor == null ||
      oldMinor == null ||
      oldPatch == null ||
      newMajor == null ||
      newMinor == null ||
      newPatch == null) {
    return false;
  }

  // Compare by the parts
  if (newMajor > oldMajor) {
    return true;
  } else if (newMajor == oldMajor) {
    if (newMinor > oldMinor) {
      return true;
    } else if (newMinor == oldMinor) {
      if (newPatch > oldPatch) {
        return true;
      }
    }
  }

  return false;
}

showUpdateSheet(BuildContext context, String markdownText, String downloadLink, bool pre, String version,
    {bool forceTrigger = false}) async {
  //dont show the sheet if recievePreRelease if off and release is a pre release
  if (pre && pre != (currentUserSettings?.receivePreReleases! ?? false)) {
    return;
  }

  // trigger if forced for debug
  if (kDebugMode && !forceTrigger) {
    return;
  }

  if (Platform.isWindows || await isTv()) {
    return showDialog(
      context: context,
      useRootNavigator: false,
      builder: (context) => AlertDialog(
        content: Container(
          width: MediaQuery.sizeOf(context).width / 3,
          child: UpdateSheet(
            downloadLink: downloadLink,
            isDesktop: true,
            markdownText: markdownText,
            pre: pre,
            version: version,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
              },
              child: Text("maybe later")),
          TextButton(
              onPressed: () async {
                final uri = Uri.parse(downloadLink);
                final asset = await get(uri);

                final tempPath = await getTemporaryDirectory();
                final downloadPath = "${tempPath.path}/astrm_update.${Platform.isWindows ? "exe" : "apk"}";

                await File(downloadPath).writeAsBytes(asset.bodyBytes);

                final openRes = await OpenFile.open(downloadPath);
                if (openRes.type == ResultType.done) {
                  print("OK! stuff's done");
                }
                // if (!(await launchUrl(uri))) {
                //   throw new Exception("Couldnt launch");
                // }
              },
              child: Text("download")),
        ],
      ),
    );
  }
  return showModalBottomSheet(
    showDragHandle: true,
    backgroundColor: appTheme.modalSheetBackgroundColor,
    isScrollControlled: true,
    context: context,
    builder: (context) {
      return UpdateSheet(
        downloadLink: downloadLink,
        isDesktop: false,
        markdownText: markdownText,
        pre: pre,
         version: version,
      );
    },
  );
}
