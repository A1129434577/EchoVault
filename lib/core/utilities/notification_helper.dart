import 'dart:io';
import 'dart:math';

import 'package:ad/ad.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:player_base/models/file_info.dart';
import 'package:timezone/timezone.dart';
import 'package:echo_vault/features/discovery/controllers/discovery_state.dart';
import 'package:timezone/data/latest.dart';

class NotificationHelper {
  static final AsyncMemoizer _memoizer = AsyncMemoizer();

  static List _pushHourList = [];
  static set pushConfig(int configArg) {
    if (configArg == 0) {
      _pushHourList = [];
    } else if (configArg == 1) {
      _pushHourList = [10, 15];
    } else if (configArg == 2) {
      _pushHourList = [10, 15, 18, 20];
    }
    if (Platform.isIOS) {
      _scheduleLocalNotification();
    }
  }

  static Future<void> init() async {
    await _memoizer.runOnce(() async {
      try {
        //初始化本地通知
        if (Platform.isIOS) {
          //安卓的部分用户可能在指定AndroidInitializationSettings的logo时发生
          //'int java.lang.Integer.intValue()' on a null object reference的错误
          initializeTimeZones();
          await FlutterLocalNotificationsPlugin().initialize(
            settings: InitializationSettings(
              iOS: DarwinInitializationSettings(
                requestSoundPermission: true,
                requestBadgePermission: true,
                requestAlertPermission: true,
              ),
              android: AndroidInitializationSettings('logo'),
            ),
            onDidReceiveNotificationResponse:
                (NotificationResponse notificationResponseArg) {},
          );
          _scheduleLocalNotification();
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    });
  }

  static Future<void> _scheduleLocalNotification() async {
    try {
      await FlutterLocalNotificationsPlugin().cancelAll();
      if (_pushHourList.isEmpty) return;

      List<FileInfo> suggestedItems = await DiscoveryState.instance
          .fetchRecommend();
      if (suggestedItems.isEmpty) {
        suggestedItems.add(
          FileInfo(name: 'Open Via Timer and let the sound focus you'),
        );
      }

      Random randomLocal = Random();
      for (int offset = 0; offset < _pushHourList.length; offset++) {
        int randomIndexLocal = randomLocal.nextInt(suggestedItems.length);
        FileInfo mediaEntry = suggestedItems[randomIndexLocal];
        if (suggestedItems.length > 1) {
          suggestedItems.remove(mediaEntry);
        }

        int hourLocal = _pushHourList[offset];
        TZDateTime dateTimeLocal = TZDateTime.from(
          DateTime.now().copyWith(hour: hourLocal, minute: 0, second: 3),
          local,
        );

        await FlutterLocalNotificationsPlugin().zonedSchedule(
          id: mediaEntry.hashCode,
          title: mediaEntry.name,
          body: mediaEntry.artist,
          scheduledDate: dateTimeLocal,
          notificationDetails: NotificationDetails(
            iOS: DarwinNotificationDetails(presentBadge: true, badgeNumber: 1),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        await Future.delayed(Duration(seconds: 3));
      }
    } catch (_) {}
  }
}
