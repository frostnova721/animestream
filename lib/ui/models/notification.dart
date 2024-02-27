import 'package:animestream/core/anime/downloader/downloader.dart';
import 'package:animestream/ui/theme/mainTheme.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';

class NotificationService {
  Future<void> init() async {
    AwesomeNotifications().initialize(
      'resource://drawable/ic_launcher_foreground',
      [
        NotificationChannel(
          channelGroupKey: 'basic_channel_group',
          channelKey: 'animestream',
          channelName: 'animestream',
          channelDescription: 'animestream notification channel',
          defaultColor: themeColor,
          ledColor: Colors.white,
        ),
      ],
      debug: false,
      channelGroups: [
        NotificationChannelGroup(
          channelGroupKey: 'basic_channel_group',
          channelGroupName: 'animestream',
        )
      ],
    );
    bool isNotifAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isNotifAllowed)
      AwesomeNotifications().requestPermissionToSendNotifications();
  }

  pushBasicNotification(String title, String content) {
    AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: 69,
          channelKey: "animestream",
          title: title,
          body: content,
          backgroundColor: themeColor),
    );
  }

  removeNotification() {
    AwesomeNotifications().cancel(69);
  }

  Future<void> updateNotificationProgressBar({
    required int id,
    required int currentStep,
    required int maxStep,
    required String fileName,
    required String path,
  }) async {
    if (currentStep < maxStep) {
      int progress = ((currentStep / maxStep) * 100).round();
      await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: id,
            channelKey: 'animestream',
            title: 'Downloading $fileName ($progress%)',
            body: 'The file is being downloaded',
            category: NotificationCategory.Progress,
            payload: {
              'path': path,
            },
            notificationLayout: NotificationLayout.ProgressBar,
            progress: progress.toDouble(),
            locked: true,
            backgroundColor: themeColor,
          ),
          actionButtons: [
            NotificationActionButton(key: "cancel", label: "cancel")
          ]);
    } else {
      await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: id,
            channelKey: 'animestream',
            title: 'Download finished',
            body: '$fileName has been downloaded succesfully!',
            payload: {
              'path': path,
            },
            locked: false,
            backgroundColor: themeColor,
          ),
          actionButtons: [
            NotificationActionButton(key: "open_file", label: "open")
          ]);
    }
  }
}

class NotificationController {
  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(
      ReceivedNotification receivedNotification) async {}

  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(
      ReceivedNotification receivedNotification) async {}

  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(
      ReceivedAction receivedAction) async {}

  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    if (receivedAction.buttonKeyPressed == 'cancel') {
      NotificationService().removeNotification();
      Downloader().cancelDownload();
    }
    if (receivedAction.buttonKeyPressed == 'open_file') {
      OpenFile.open(receivedAction.payload?['path'], type: "video/mp4");
    }
  }
}
