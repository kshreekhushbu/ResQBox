import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:resqboxvendor/Models/order_model.dart';
import 'package:provider/provider.dart';
import 'package:resqboxvendor/Controller/KitchenProfileController.dart';
import 'package:resqboxvendor/main.dart'; // for navigatorKey
import 'package:resqboxvendor/Services/api.dart';
import 'package:resqboxvendor/Utils/notification_service.dart';
import 'package:resqboxvendor/Utils/sound_service.dart';
import 'package:resqboxvendor/Models/local_notifications_model.dart';

class KitchenSocket {
  late IO.Socket socket;
  bool _isConnected = false;
  Function(dynamic)? _newOrderCallback;
  Function(dynamic)? _stripeOnboardingCallback;

  bool get isConnected => _isConnected;

  // Call this after login
  void connect(int kitchenId) {
    try {
      socket = IO.io(
        Api.socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setQuery({"kitchenId": kitchenId.toString()}) // auto join room
            .disableAutoConnect() // connect manually
            .enableReconnection() // Ensure reconnection is enabled
            .build(),
      );

      socket.connect();

      // When connected
      socket.onConnect((_) {
        _isConnected = true;
        debugPrint("🔌 Socket Connected (Kitchen ID: $kitchenId)");
      });

      // Listen for new order events
      socket.on("newOrder", (data) {
        debugPrint("📦 NEW ORDER RECEIVED:");
        debugPrint(data.toString());

        // Play sound notification with configured duration
        try {
          // Access notificationTime from KitchenProfileController
          if (navigatorKey.currentContext != null) {
            final kitchenController = Provider.of<KitchenProfileController>(
              navigatorKey.currentContext!,
              listen: false,
            );

            final notificationTime =
                kitchenController.kitchenDetails?.notificationTime;

            debugPrint(
              "🔊 Playing new order buzzer for duration: ${notificationTime}s",
            );
            SoundService.playNewOrderSound(duration: notificationTime);
          } else {
            // Fallback if context unavailable
            SoundService.playNewOrderSound();
          }
        } catch (e) {
          debugPrint("⚠️ Error playing custom duration sound: $e");
          SoundService.playNewOrderSound(); // Fallback
        }

        // Show local notification
        try {
          if (data is Map<String, dynamic>) {
            final order = Order.fromJson(data);
            NotificationApi.pushNotification(
              PushNotificationsModel(
                title: 'New Order Received! 🔔',
                body:
                    'Order #${order.orderDisplayId} - \$ ${order.totalAmount}',
              ),
            );
          } else if (data is List &&
              data.isNotEmpty &&
              data[0] is Map<String, dynamic>) {
            final order = Order.fromJson(data[0]);
            NotificationApi.pushNotification(
              PushNotificationsModel(
                title: 'New Order Received! 🔔',
                body:
                    'Order #${order.orderDisplayId} - \$ ${order.totalAmount}',
              ),
            );
          }
        } catch (e) {
          debugPrint("⚠️ Error parsing order for notification: $e");
          // Show generic notification if parsing fails
          NotificationApi.pushNotification(
            PushNotificationsModel(
              title: "New Order Received",
              body: "You have a new order!",
            ),
          );
        }

        if (_newOrderCallback != null) {
          _newOrderCallback!(data);
        }
      });

      // Listen for stripe onboarding completed
      socket.on("stripe-onboarding-completed", (data) {
        debugPrint("🏦 Stripe Onboarding Completed Event Received");
        print("🏦 Stripe Onboarding Completed Event Received");

        debugPrint(data.toString());
        print(data.toString());

        // Refresh Kitchen Details Directly
        try {
          if (navigatorKey.currentContext != null) {
            final kitchenController = Provider.of<KitchenProfileController>(
              navigatorKey.currentContext!,
              listen: false,
            );
            kitchenController.getKitchenDetails();
            debugPrint("🔄 Kitchen Details Refreshed from Socket (Direct)");
          }
        } catch (e) {
          debugPrint("⚠️ Error refreshing kitchen details directly: $e");
        }

        if (_stripeOnboardingCallback != null) {
          _stripeOnboardingCallback!(data);
        }
      });

      // If disconnected
      socket.onDisconnect((_) {
        _isConnected = false;
        debugPrint("❌ Socket Disconnected");
      });

      // Connection error
      socket.onError((err) {
        _isConnected = false;
        debugPrint("⚠️ Socket Error: $err");
      });

      // Reconnection attempt
      socket.onReconnect((_) {
        _isConnected = true;
        debugPrint("🔄 Socket Reconnected");
      });
    } catch (e) {
      debugPrint("❌ Error connecting socket: $e");
      _isConnected = false;
    }
  }

  // Set callback for new order events
  void onNewOrder(Function(dynamic) callback) {
    _newOrderCallback = callback;
  }

  // Set callback for stripe onboarding completed
  void onStripeOnboardingCompleted(Function(dynamic) callback) {
    _stripeOnboardingCallback = callback;
  }

  // Cleanup
  void disconnect() {
    if (_isConnected) {
      socket.disconnect();
      socket.dispose();
      _isConnected = false;
      debugPrint("🔌 Socket Disconnected and Disposed");
    }
  }
}
