import 'dart:convert';
import 'dart:io';

import 'package:bandha/features/notifications/entities/notification.dart';
import 'package:bandha/features/main/handlers/notification_handler.dart';
import 'package:bandha/features/notifications/repositories/notification_repository.dart';
import 'package:bandha/common/types/controller.dart';
import 'package:bandha/common/types/notification_action.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationManager {
  final NotificationRepository notificationRepository;
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NotificationManager({required this.notificationRepository});

  Future<void> init(
    NotificationHandler notificationHandler,
    DidReceiveBackgroundNotificationResponseCallback?
    didReceiveBackgroundNotificationResponseCallback,
  ) async {
    if (Platform.isAndroid) {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation("Asia/Jakarta"));

      const androidSettings = AndroidInitializationSettings(
        "@mipmap/ic_launcher",
      );

      const initializationSettings = InitializationSettings(
        android: androidSettings,
      );

      await notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()!
          .requestNotificationsPermission();
      await notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()!
          .requestExactAlarmsPermission();
      await notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()!
          .requestFullScreenIntentPermission();

      final launchDetails = await notificationsPlugin
          .getNotificationAppLaunchDetails();

      await notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (response) {
          notificationHandler.handle(response);
        },
        onDidReceiveBackgroundNotificationResponse:
            didReceiveBackgroundNotificationResponseCallback,
      );

      if (launchDetails?.didNotificationLaunchApp ?? false) {
        final response = launchDetails!.notificationResponse!;
        notificationHandler.handle(response);
      }
    }
  }

  Future<void> setReminder({
    required String title,
    required String body,
    required DateTime sentAt,
    required Controller controller,
    List<NotificationAction>? actions,
  }) async {
    if (sentAt.isBefore(DateTime.now())) {
      return;
    }

    final Notification notification = Notification.create(
      title: title,
      body: body,
      sentAt: sentAt,
      controller: controller,
    );

    await notificationRepository.save(notification);

    return notificationsPlugin.zonedSchedule(
      notification.id,
      notification.title,
      notification.body,
      tz.TZDateTime.from(sentAt, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          controller.type.id,
          controller.type.label,
          actions: actions
              ?.map(
                (action) => AndroidNotificationAction(
                  action.id,
                  action.title,
                  showsUserInterface: true,
                ),
              )
              .toList(),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: notificationPayload(controller),
    );
  }

  notificationPayload(Controller controller) {
    return jsonEncode({
      "controller_id": controller.id,
      "controller_type": controller.type.name,
    });
  }

  Future<void> cancelReminder(Controller controller) async {
    final notification = await notificationRepository.getByController(
      controller,
    );

    if (notification == null) return;
    await notificationRepository.delete(notification.id);
    await notificationsPlugin.cancel(notification.id);
  }
}
