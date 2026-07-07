import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:resqboxvendor/Models/local_notifications_model.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationApi {
  static final _notification = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    await _notification.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/launcher_icon'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    await _createNotificationChannel();
  }

  static Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'order_buzzer_channel_v3', // id
      'General Notifications', // title
      description: 'channel description', // description
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('order_buzzer'),
    );

    await _notification
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  //add the method to NotificationApi class

  static pushNotification(PushNotificationsModel? data) async {
    // Try with custom sound first
    try {
      var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'order_buzzer_channel_v4', // New channel ID
        'General Notifications',
        channelDescription: 'channel description',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('order_buzzer'),
        styleInformation: BigTextStyleInformation(
          data?.body ?? '',
          htmlFormatBigText: true,
        ),
        icon: '@mipmap/launcher_icon',
      );

      var iOSPlatformChannelSpecifics = const DarwinNotificationDetails();
      var platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _notification.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        data?.title,
        data?.body,
        platformChannelSpecifics,
      );
    } catch (e) {
      debugPrint("⚠️ Error playing custom sound notification: $e");
      // Fallback to default sound
      var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
        'order_buzzer_channel_default',
        'General Notifications Default',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        icon: '@mipmap/launcher_icon',
      );
      var iOSPlatformChannelSpecifics = const DarwinNotificationDetails();
      var platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _notification.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        data?.title,
        data?.body,
        platformChannelSpecifics,
      );
    }
  }
}

Future<String?> getFcmToken() async {
  String? token = await FirebaseMessaging.instance.getToken();
  return token;
}
