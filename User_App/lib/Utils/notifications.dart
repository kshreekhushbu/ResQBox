import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:resqbox_user/Models/local_notifications_model.dart';
import 'package:resqbox_user/Screens/MainSection/Orders/order_details.dart';
import 'package:resqbox_user/Utils/navigations.dart';
import 'package:resqbox_user/main.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse details) {
  debugPrint("Background notification tapped: ${details.payload}");
  if (details.payload != null) {
    try {
      final data = jsonDecode(details.payload!);
      debugPrint("Parsed notification data: $data");

      if (data['orderId'] != null) {
        final orderId = data['orderId'];
        debugPrint("Navigating to chat with orderId: $orderId");

        // Use navigatorKey to navigate
        if (navigatorKey.currentContext != null) {
          // // Call getChatRooms API to refresh chat list
          // try {
          //   Provider.of<ChatController>(navigatorKey.currentContext!,
          //           listen: false)
          //       .getChatRooms();
          // } catch (e) {
          //   debugPrint("Error calling getChatRooms: $e");
          // }

          NavigateTo().nextPage(
            child: OrderDetails(
              from: "push",
              orderId: orderId is int
                  ? orderId
                  : int.tryParse(orderId.toString()) ?? 0,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error parsing notification payload: $e");
    }
  }
}

class NotificationApi {
  static final _notification = FlutterLocalNotificationsPlugin();

  static void _notificationTapHandler(NotificationResponse details) {
    debugPrint("Foreground notification tapped: ${details.payload}");

    final payload = details.payload;

    /// ✅ FIX: guard against null & empty payload
    if (payload == null || payload.trim().isEmpty) {
      debugPrint("Notification payload is empty. Ignoring tap.");
      return;
    }

    try {
      final Map<String, dynamic> data = jsonDecode(payload);
      debugPrint("Parsed notification data: $data");

      final orderId = data['orderId'];
      if (orderId == null) return;

      debugPrint("Navigating to order with orderId: $orderId");

      if (navigatorKey.currentContext != null) {
        NavigateTo().nextPage(
          child: OrderDetails(
            from: "push",
            orderId: orderId is int
                ? orderId
                : int.tryParse(orderId.toString()) ?? 0,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error parsing notification payload: $e");
    }
  }

  static void init() {
    // _notification.initialize(
    //   const InitializationSettings(
    //     android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    //     iOS: DarwinInitializationSettings(),
    //   ),
    // );
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    _notification.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _notificationTapHandler,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  //add the method to NotificationApi class

  static pushNotification(PushNotificationsModel? data, {int? orderId}) async {
    var androidPlatformChannelSpecifics =
        AndroidNotificationDetails('channed id', 'channel name',
            channelDescription: 'channel description',
            importance: Importance.max,
            priority: Priority.high,
            styleInformation: BigTextStyleInformation(
              data?.body ?? '',
              htmlFormatBigText: true,
            ),
            icon: '@mipmap/ic_launcher');
    var iOSPlatformChannelSpecifics = const DarwinNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    // Include notification data as payload for tap handling
    String? payload;
    if (orderId != null) {
      payload = jsonEncode({
        "orderId": orderId,
      });
    }

    await _notification.show(
        0, data?.title, data?.body, platformChannelSpecifics,
        payload: payload);
  }
}

Future<String?> getFcmToken() async {
  String? token = await FirebaseMessaging.instance.getToken();
  return token;
}
