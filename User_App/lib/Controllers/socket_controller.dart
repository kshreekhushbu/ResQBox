import 'package:provider/provider.dart';
import 'package:resqbox_user/Controllers/account_controller.dart';
import 'package:resqbox_user/Controllers/orders_controller.dart';
import 'package:resqbox_user/Services/apis.dart';
import 'package:resqbox_user/main.dart';

import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/material.dart';
import 'package:resqbox_user/Screens/Authentication/login_screen.dart';
import 'package:resqbox_user/Utils/shared_preference_helper.dart';
import 'package:resqbox_user/Utils/toast.dart';
import 'package:resqbox_user/Utils/navigations.dart';

class SocketController extends ChangeNotifier {
  IO.Socket? _socket;

  /// Initialize and connect the socket
  void initializeSocketConnection() {
    // Disconnect existing socket if any
    if (_socket != null) {
      _socket?.disconnect();
      _socket?.dispose();
      _socket = null;
    }

    final userId = Provider.of<AccountController>(navigatorKey.currentContext!,
            listen: false)
        .userDetailsData
        ?.user
        ?.userId;

    if (userId == null) {
      debugPrint('❌ Cannot initialize socket: userId is null');
      return;
    }

    debugPrint('🔌 Initializing socket connection to: ${Apis.socketBaseUrl}');
    debugPrint('👤 User ID: $userId');

    try {
      _socket = IO.io(
        Apis.socketBaseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setQuery({
              'userId': userId.toString(),
              'role': 'USER',
            })
            .enableAutoConnect()
            .enableReconnection()
            .build(),
      );

      // Set up event listeners
      _setupSocketListeners();
    } catch (e) {
      debugPrint('❌ Error creating socket: $e');
    }
  }

  void _setupSocketListeners() {
    _socket?.onConnect((_) {
      debugPrint('🛡️ Socket connected successfully');
      notifyListeners();
    });

    _socket?.onDisconnect((_) {
      debugPrint('🔌 Socket disconnected');
      notifyListeners();
    });

    _socket?.onConnectError((data) {
      debugPrint('❌ Socket connect error: $data');
    });

    _socket?.onError((data) {
      debugPrint('❌ Socket error: $data');
    });

    _socket?.onReconnect((_) {
      debugPrint('🔄 Socket reconnected');
      notifyListeners();
    });

    // Remove existing listener to avoid duplicates
    _socket?.off('support-message');

    // Set up support-message listener
    _socket?.on('support-message', (data) {
      debugPrint('📩 Support message received: $data');
      try {
        // Parse the data and add to AccountController
        if (data != null && data is Map<String, dynamic>) {
          final accountController = Provider.of<AccountController>(
            navigatorKey.currentContext!,
            listen: false,
          );
          accountController.addIncomingSocketMessage(data);
        } else {
          debugPrint('⚠️ Invalid socket message data format: $data');
        }
        notifyListeners();
      } catch (e, stackTrace) {
        debugPrint('❌ Error handling support-message event: $e');
        debugPrint('Stack trace: $stackTrace');
      }
    });

    // Set up account_status_changed listener
    _socket?.off('account_status_changed');
    _socket?.on('account_status_changed', (data) {
      debugPrint('👤 Account status changed: $data');
      try {
        if (data != null && data is Map<String, dynamic>) {
          debugPrint("kkkkkkkkkkkkkkkkkkkkkkk $data");
          if (data['status'] == 'INACTIVE') {
            SharedPreferencesHelper().remove("ApiToken");
            SharedPreferencesHelper().remove("Token2");
            SharedPreferencesHelper().remove("role");
            SharedPreferencesHelper().clearAlldata();
            customToast(
                message:
                    data['message'] ?? "Session Expired... Please login again");
            NavigateTo().pushRemove(child: const LoginScreen());
            disconnectSocket();
          }
        }
      } catch (e) {
        debugPrint('❌ Error handling account_status_changed event: $e');
      }
    });

    // Set up order_status_update listener
    _socket?.off('order_status_update');
    _socket?.on('order_status_update', (data) async {
      debugPrint('📦 Order status update received: $data');
      try {
        if (data != null && data is Map<String, dynamic>) {
          final ordersController = Provider.of<OrdersController>(
            navigatorKey.currentContext!,
            listen: false,
          );
          ordersController.updateOrderStatusFromSocket(data);
          await Provider.of<OrdersController>(navigatorKey.currentContext!,
                  listen: false)
              .myOrdersApi(1);
        }
      } catch (e, stackTrace) {
        debugPrint('❌ Error handling order_status_update event: $e');
        debugPrint('Stack trace: $stackTrace');
      }
    });
  }

  /// Emit data to the socket
  void emitEvent(String eventName, dynamic data) {
    if (_socket?.connected == true) {
      _socket?.emit(eventName, data);
    } else {
      debugPrint('Socket not connected. Cannot emit $eventName');
    }
  }

  /// Disconnect the socket
  void disconnectSocket() {
    if (_socket != null) {
      _socket?.off('support-message');
      _socket?.disconnect();
      _socket?.dispose();
      _socket?.offAny();
      _socket = null;
      debugPrint('🔌 Socket manually disconnected');
      notifyListeners();
    }
  }

  /// Check if socket is connected
  bool get isConnected => _socket?.connected ?? false;
}
