import 'package:animestream/ui/theme/mainTheme.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

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

  pushBasicNotification(String title, String content, current) {
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 69,
        channelKey: "animestream",
        title: title,
        body: content,
      ),
    );
  }

  void updateNotificationProgressBar({
    required int id,
    required int currentStep,
    required int maxStep,
    required String fileName,
  }) {
    if (currentStep < maxStep) {
      int progress = ((currentStep / maxStep) * 100).round();
      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: 'animestream',
          title: 'Downloading $fileName ($progress%)',
          body: '$fileName',
          category: NotificationCategory.Progress,
          payload: {'file': '$fileName', 'path': ''},
          notificationLayout: NotificationLayout.ProgressBar,
          progress: progress.toDouble(),
          locked: true,
        ),
      );
    } else {
      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: 'animestream',
          title: 'Download finished',
          body: '$fileName has been downloaded succesfully!',
          category: NotificationCategory.Progress,
          payload: {'file': '$fileName', 'path': ''},
          locked: false,
        ),
      );
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
    // MyApp.navigatorKey.currentState?.pushNamedAndRemoveUntil(
    //   '/notification-page',
    //   (route) => (route.settings.name != '/notification-page') || route.isFirst,
    //   arguments: receivedAction,
    // );
  }
}
