import 'dart:convert';
import 'dart:io';

import 'package:animestream/core/app/logging.dart';
import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/utils.dart';
import 'package:animestream/ui/models/bottomSheets/updateSheet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpdateCheckResult {
  /// The version code of the latest release
  final String latestVersion;

  /// The version code of the current package
  final String currentVersion;

  /// Wether the release is a pre-release (beta versions)
  final bool preRelease;

  /// The direct download link for the asset
  final String downloadLink;

  /// The description markdown of the release
  final String description;

  /// The hash of the asset in the [downloadLink]
  final String hash;

  UpdateCheckResult({
    required this.latestVersion,
    required this.currentVersion,
    required this.preRelease,
    required this.downloadLink,
    required this.description,
    required this.hash,
  });

  @override
  String toString() {
    return 'UpdateCheckResult(latestVersion: $latestVersion, currentVersion: $currentVersion, preRelease: $preRelease, downloadLink: $downloadLink, description: $description)';
  }
}

/// Alright! the versioning is like: v?n.n.n(-stagen?) eg: 1.3.4-beta1
/// n are the numbers. follows the scheme like super-major.okaish.minor (dependent on changes in quality)
/// v is when the update is parsed from github api.
/// stage can be beta followed by the iterative number (these are rare and arent present most time)
Future<UpdateCheckResult?> checkForUpdates() async {
  print(_checkIfTheNewVersionIsActuallyAnUpgrade("1.6.0-beta1", "1.6.0-beta1"));
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

    bool triggerSheet = false; // Change this flag for triggering the sheet for debugging
    // int? currentVersionJoined, latestVersionJoined;

    final latestVersionCode = latestVersion.replaceAll('v', '');

    bool isAnUpgrade = false;

    try {
      isAnUpgrade = _checkIfTheNewVersionIsActuallyAnUpgrade(latestVersionCode, currentVersion);
    } catch (err) {
      // old version check logic as a backup method!
      final versionNumber = latestVersionCode.split("-")[0];
      if (currentVersion.split("-").firstOrNull != versionNumber) triggerSheet = true;
    }

    // we can assert not null since we do null check in try statement & the comparison wont occur if theres an issue
    if (triggerSheet || isAnUpgrade) {
      Logs.app.log("<UPDATE-CHECK> UPDATE AVAILABLE!!!");
      final List<dynamic> asset = releasesRes['assets']
          .where((item) => item['name'] == (Platform.isAndroid ? "app-release.apk" : "animestream-x86_64.exe"))
          .toList();
      if (asset.isEmpty) return null;
      final downloadLink = asset[0]['browser_download_url'];
      final hash = asset[0]['digest'] as String;
      return UpdateCheckResult(
        latestVersion: latestVersion,
        currentVersion: currentVersion,
        preRelease: pre,
        downloadLink: downloadLink,
        description: description,
        hash: hash,
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
  final oldSplit = oldVersion.split('-');
  final newSplit = newVersion.split('-');

  final oldParts = oldSplit.first.split('.');
  final newParts = newSplit.first.split('.');

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
  if (newMajor > oldMajor) return true;
  if (newMajor < oldMajor) return false;

  // condition where the majors are same
  if (newMinor > oldMinor) return true;
  if (newMinor < oldMinor) return false;

  // condition where minors are same
  if (newPatch > oldPatch) return true;
  if (newPatch < oldPatch) return false;

  // condition where the versions are def equal. Time for stage check!

  final isTheOldOneStable = oldSplit.length == 1;
  final isTheNewOneStable = newSplit.length == 1;

  if(isTheNewOneStable && isTheOldOneStable) return false;

  // check if the the old ver is non-stable and new ver is stable
  if (!isTheOldOneStable && isTheNewOneStable) {
    return true; // new stable is always prefered than old unstables
  }

  if(isTheOldOneStable && !isTheNewOneStable) {
    return false; // prevent from downgrading to a beta of same version
  }

  final oldStage = oldSplit[1];
  final newStage = newSplit[1];

  final stageRegex = RegExp(r"([a-z]+)(\d+)?");

  final oldVerMatches = stageRegex.allMatches(oldStage);
  final newVerMatches = stageRegex.allMatches(newStage);

  if (oldVerMatches.isEmpty || newVerMatches.isEmpty) {
    return false;
  }

  final oldStageName = oldVerMatches.firstOrNull?.group(1) ?? '';
  final newStageName = newVerMatches.firstOrNull?.group(1) ?? '';
  final oldStageNum = int.tryParse(oldVerMatches.firstOrNull?.group(2) ?? '') ?? 0;
  final newStageNum = int.tryParse(newVerMatches.firstOrNull?.group(2) ?? '') ?? 0;

  // weights for stages, higher weight means newer stage. if the stage is not recognized, it gets 0 weight by default
  final stageWeights = {
    'alpha': 1,
    'beta': 2,
    // 'stable': 3,
    'rc': 3, // release candidate
  };

  final oldStageWeight = stageWeights[oldStageName] ?? 0;
  final newStageWeight = stageWeights[newStageName] ?? 0;

  if (newStageWeight > oldStageWeight) return true;

  if (newStageWeight < oldStageWeight) return false;

  return newStageNum > oldStageNum;
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
            markdownText: markdownText,
            pre: pre,
            version: version,
          ),
        ),
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
        markdownText: markdownText,
        pre: pre,
        version: version,
      );
    },
  );
}

// just for testing while development. Not used else where in prod
// ignore: unused_element
void _testVersionCheck() {
  print("--- STANDARD UPGRADES (Expected: true) ---");
  print("1.0.1 > 1.0.0: ${_checkIfTheNewVersionIsActuallyAnUpgrade("1.0.1", "1.0.0")}");
  print("1.1.0 > 1.0.9: ${_checkIfTheNewVersionIsActuallyAnUpgrade("1.1.0", "1.0.9")}");
  print("2.0.0 > 1.9.9: ${_checkIfTheNewVersionIsActuallyAnUpgrade("2.0.0", "1.9.9")}");

  print("\n--- STAGE UPGRADES (Expected: true) ---");
  print("1.0.0-beta > 1.0.0-alpha: ${_checkIfTheNewVersionIsActuallyAnUpgrade("1.0.0-beta", "1.0.0-alpha")}");
  print("1.0.0-rc > 1.0.0-beta:    ${_checkIfTheNewVersionIsActuallyAnUpgrade("1.0.0-rc", "1.0.0-beta")}");
  print("1.0.0-beta2 > 1.0.0-beta1: ${_checkIfTheNewVersionIsActuallyAnUpgrade("1.0.0-beta2", "1.0.0-beta1")}");
  print("1.0.0-beta10 > 1.0.0-beta2: ${_checkIfTheNewVersionIsActuallyAnUpgrade("1.0.0-beta10", "1.0.0-beta2")}"); // Numeric check

  print("\n--- GRADUATION (Expected: true) ---");
  print("1.0.0 > 1.0.0-rc:    ${_checkIfTheNewVersionIsActuallyAnUpgrade("1.0.0", "1.0.0-rc")}");
  print("1.0.0 > 1.0.0-beta:  ${_checkIfTheNewVersionIsActuallyAnUpgrade("1.0.0", "1.0.0-beta")}");
  print("1.0.0 > 1.0.0-alpha: ${_checkIfTheNewVersionIsActuallyAnUpgrade("1.0.0", "1.0.0-alpha")}");

  print("\n--- NO CHANGE / EQUAL (Expected: false) ---");
  print("1.0.0 vs 1.0.0:       ${_checkIfTheNewVersionIsActuallyAnUpgrade("1.0.0", "1.0.0")}");
  print("1.0.0-beta vs 1.0.0-beta: ${_checkIfTheNewVersionIsActuallyAnUpgrade("1.0.0-beta", "1.0.0-beta")}");
  print("1.0.5 vs 1.0.5:       ${_checkIfTheNewVersionIsActuallyAnUpgrade("1.0.5", "1.0.5")}");

  print("\n--- DOWNGRADES (Expected: false) ---");
  print("1.0.0 < 1.0.1:       ${_checkIfTheNewVersionIsActuallyAnUpgrade("1.0.0", "1.0.1")}");
  print("0.9.9 < 1.0.0:       ${_checkIfTheNewVersionIsActuallyAnUpgrade("0.9.9", "1.0.0")}");
  print("1.0.0-alpha < 1.0.0-beta: ${_checkIfTheNewVersionIsActuallyAnUpgrade("1.0.0-alpha", "1.0.0-beta")}");
  print("1.0.0-beta1 < 1.0.0-beta2: ${_checkIfTheNewVersionIsActuallyAnUpgrade("1.0.0-beta1", "1.0.0-beta2")}");

  print("\n--- STABILITY DOWNGRADES (Expected: false) ---");
  print("1.0.0-beta < 1.0.0:  ${_checkIfTheNewVersionIsActuallyAnUpgrade("1.0.0-beta", "1.0.0")}");
  print("1.0.0-rc < 1.0.0:    ${_checkIfTheNewVersionIsActuallyAnUpgrade("1.0.0-rc", "1.0.0")}");

  print("\n--- EDGE CASES (Expected: varies) ---");
  print("1.0.0-beta (implicit 0) < 1.0.0-beta1: ${_checkIfTheNewVersionIsActuallyAnUpgrade("1.0.0-beta1", "1.0.0-beta")}"); // True
  print("1.0.1-alpha > 1.0.0 (Version > Stage): ${_checkIfTheNewVersionIsActuallyAnUpgrade("1.0.1-alpha", "1.0.0")}"); // True (Core version is higher)
}