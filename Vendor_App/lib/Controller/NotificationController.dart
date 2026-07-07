import 'package:flutter/material.dart';
import 'package:resqboxvendor/Models/notification_model.dart';
import 'package:resqboxvendor/Services/AppUrls.dart';
import 'package:resqboxvendor/Services/api.dart';
import 'package:resqboxvendor/Services/dynamic_response.dart';
import 'package:resqboxvendor/Utils/toast.dart';

class NotificationController extends ChangeNotifier {
  List<NotificationItem> notifications = [];
  bool isLoading = false;

  Future<void> getNotifications() async {
    try {
      isLoading = true;
      notifyListeners();

      final url = '${Api.baseUrl}${AppUrls.getNotifications}';
      debugPrint("📤 Get Notifications URL: $url");

      final res = await ApiService().getRequest(url);

      debugPrint("📥 Get Notifications Response: $res");

      if (res != null && (res['status'] == 1 || res['Status'] == 1)) {
        final response = GetNotificationsResponse.fromJson(res);
        notifications = response.notifications ?? [];
        debugPrint("✅ Notifications loaded: ${notifications.length}");
      } else {
        // Handle empty or error case gracefully
        debugPrint("⚠️ Failed to load notifications: ${res?['message']}");
        // customToast(
        //   message: res?['message'] ?? "Failed to load notifications",
        // );
      }
    } catch (e) {
      debugPrint("❌ Error getting notifications: $e");
      customToast(message: "Failed to load notifications");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  bool get hasUnreadNotifications =>
      notifications.any((element) => element.isRead == false);
}
