import 'package:flutter/material.dart';
import 'package:resqboxvendor/Models/order_model.dart';
import 'package:resqboxvendor/Services/AppUrls.dart';
import 'package:resqboxvendor/Services/api.dart';
import 'package:resqboxvendor/Services/dynamic_response.dart';
import 'package:resqboxvendor/Utils/sound_service.dart';
import 'package:resqboxvendor/Utils/toast.dart';
import 'package:url_launcher/url_launcher.dart';

class OrdersController extends ChangeNotifier {
  // New Orders (type 1)
  List<Order> newOrders = [];
  bool isLoadingNewOrders = false;

  // Ongoing Orders (type 2)
  List<Order> ongoingOrders = [];
  bool isLoadingOngoingOrders = false;

  // Past Orders (type 3)
  List<Order> pastOrders = [];
  bool isLoadingPastOrders = false;

  // Order Details
  Order? orderDetails;
  bool isLoadingOrderDetails = false;

  // Action Loading States
  bool isAcceptingOrder = false;
  bool isRejectingOrder = false;
  bool isUpdatingStatus = false;
  bool isDownloadingPdf = false;

  // Get Kitchen Orders by Type
  // type: 1 = NEW (PENDING), 2 = ONGOING, 3 = COMPLETED
  Future<void> getKitchenOrders(
    int type, {
    String? date,
    String? search,
  }) async {
    try {
      _setLoadingState(type, true);
      await Future.delayed(Duration.zero);
      notifyListeners();

      var url = '${Api.baseUrl}${AppUrls.getKitchenOrders}?type=$type';
      if (date != null && date.isNotEmpty) {
        url += '&date=$date';
      }
      if (search != null && search.isNotEmpty) {
        url += '&search=$search';
      }
      debugPrint("📤 Get Kitchen Orders URL: $url");

      final res = await ApiService().getRequest(url);

      debugPrint("📥 Get Kitchen Orders Response: $res");

      if (res != null && (res['status'] == 1 || res['Status'] == 1)) {
        final orderResponse = OrderResponse.fromJson(res);
        _setOrdersList(type, orderResponse.orders ?? []);
        debugPrint(
          "✅ Loaded ${_getOrdersList(type).length} orders for type $type",
        );
      } else {
        _setOrdersList(type, []);
        customToast(message: res?['message'] ?? "Failed to load orders");
      }
    } catch (e) {
      debugPrint("❌ Error getting kitchen orders: $e");
      _setOrdersList(type, []);
      customToast(message: "Failed to load orders");
    } finally {
      _setLoadingState(type, false);
      notifyListeners();
    }
  }

  // Get Order Details By ID
  Future<void> getOrderDetailsById(int orderId) async {
    try {
      isLoadingOrderDetails = true;
      await Future.delayed(Duration.zero);
      notifyListeners();

      final url = '${Api.baseUrl}${AppUrls.getKitchenOrderById}/$orderId';
      debugPrint("📤 Get Order Details URL: $url");

      final res = await ApiService().getRequest(url);

      debugPrint("📥 Get Order Details Response: $res");

      if (res != null && (res['status'] == 1 || res['Status'] == 1)) {
        final orderDetailResponse = OrderDetailResponse.fromJson(res);
        orderDetails = orderDetailResponse.order;
        debugPrint("✅ Order details loaded: ${orderDetails?.orderId}");
      } else {
        orderDetails = null;
        customToast(message: res?['message'] ?? "Failed to load order details");
      }
    } catch (e) {
      debugPrint("❌ Error getting order details: $e");
      orderDetails = null;
      customToast(message: "Failed to load order details");
    } finally {
      isLoadingOrderDetails = false;
      notifyListeners();
    }
  }

  // Accept Order
  Future<bool> acceptOrder(int orderId) async {
    try {
      isAcceptingOrder = true;
      notifyListeners();

      final url = '${Api.baseUrl}${AppUrls.acceptOrder}/$orderId';
      debugPrint("📤 Accept Order URL: $url");

      final body = {"dateTime": DateTime.now().toIso8601String()};
      debugPrint("📤 Accept Order Body: $body");
      final res = await ApiService().putRequest(url, body);

      debugPrint("📥 Accept Order Response: $res");

      if (res != null && (res['status'] == 1 || res['Status'] == 1)) {
        customToast(message: "Order accepted successfully");
        // Stop the notification sound
        SoundService.stopSound();
        // Refresh orders
        await getKitchenOrders(1); // Refresh new orders
        await getKitchenOrders(2); // Refresh ongoing orders
        notifyListeners();
        return true;
      } else {
        customToast(message: res?['message'] ?? "Failed to accept order");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Error accepting order: $e");
      customToast(message: "Failed to accept order");
      return false;
    } finally {
      isAcceptingOrder = false;
      notifyListeners();
    }
  }

  // Reject Order
  Future<bool> rejectOrder(int orderId) async {
    try {
      isRejectingOrder = true;
      notifyListeners();

      final url = '${Api.baseUrl}${AppUrls.rejectOrder}/$orderId';
      debugPrint("📤 Reject Order URL: $url");

      final body = {"dateTime": DateTime.now().toIso8601String()};
      debugPrint("📤 Reject Order Body: $body");
      final res = await ApiService().putRequest(url, body);

      debugPrint("📥 Reject Order Response: $res");

      if (res != null && (res['status'] == 1 || res['Status'] == 1)) {
        customToast(message: "Order rejected successfully");
        // Stop the notification sound
        SoundService.stopSound();
        // Refresh orders
        await getKitchenOrders(1); // Refresh new orders
        await getKitchenOrders(3); // Refresh past orders
        notifyListeners();
        return true;
      } else {
        customToast(message: res?['message'] ?? "Failed to reject order");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Error rejecting order: $e");
      customToast(message: "Failed to reject order");
      return false;
    } finally {
      isRejectingOrder = false;
      notifyListeners();
    }
  }

  Future<void> cancelOrder(int orderId) async {
    await updateOrderStatus(orderId, OrderStatus.cancelled);
  }

  // Update Order Status
  Future<bool> updateOrderStatus(int orderId, OrderStatus status) async {
    try {
      isUpdatingStatus = true;
      notifyListeners();

      final url = '${Api.baseUrl}${AppUrls.updateOrderStatus}/$orderId';
      debugPrint("📤 Update Order Status URL: $url");
      debugPrint("📤 Status: ${status.value}");

      final body = {
        "status": status.value,
        "dateTime": DateTime.now().toIso8601String(),
      };
      debugPrint("📤 Update Order Status Body: $body");
      final res = await ApiService().putRequest(url, body);

      debugPrint("📥 Update Order Status Response: $res");

      if (res != null && (res['status'] == 1 || res['Status'] == 1)) {
        customToast(message: "Order status updated successfully");
        // Stop the notification sound if order is no longer pending
        SoundService.stopSound();
        await getKitchenOrders(1);
        await getKitchenOrders(2);
        await getKitchenOrders(3);
        if (orderDetails?.orderId == orderId) {
          await getOrderDetailsById(orderId);
        }
        notifyListeners();
        return true;
      } else {
        customToast(
          message: res?['message'] ?? "Failed to update order status",
        );
        return false;
      }
    } catch (e) {
      debugPrint("❌ Error updating order status: $e");
      customToast(message: "Failed to update order status");
      return false;
    } finally {
      isUpdatingStatus = false;
      notifyListeners();
    }
  }

  // Download Order Invoice PDF
  Future<void> downloadOrderInvoice(String? pdfUrl) async {
    if (pdfUrl == null || pdfUrl.isEmpty) {
      customToast(message: "Invoice PDF not available");
      return;
    }

    try {
      isDownloadingPdf = true;
      notifyListeners();

      final url = Uri.parse(pdfUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        customToast(message: "Could not launch PDF URL");
      }
    } catch (e) {
      debugPrint("❌ Error launching PDF: $e");
      customToast(message: "Failed to download PDF");
    } finally {
      isDownloadingPdf = false;
      notifyListeners();
    }
  }

  // Helper methods
  void _setLoadingState(int type, bool loading) {
    switch (type) {
      case 1:
        isLoadingNewOrders = loading;
        break;
      case 2:
        isLoadingOngoingOrders = loading;
        break;
      case 3:
        isLoadingPastOrders = loading;
        break;
    }
  }

  void _setOrdersList(int type, List<Order> orders) {
    switch (type) {
      case 1:
        newOrders = orders;
        break;
      case 2:
        ongoingOrders = orders;
        break;
      case 3:
        pastOrders = orders;
        break;
    }
  }

  List<Order> _getOrdersList(int type) {
    switch (type) {
      case 1:
        return newOrders;
      case 2:
        return ongoingOrders;
      case 3:
        return pastOrders;
      default:
        return [];
    }
  }

  // Get display status text
  String getStatusDisplayText(String? status) {
    if (status == null) return "Unknown";
    switch (status.toUpperCase()) {
      case "PENDING":
        return "New Order";
      case "ACCEPTED":
        return "Accepted";
      case "PREPARING":
        return "Preparing";
      case "READY":
        return "Ready for Pickup";
      case "PICKED":
        return "Picked Up";
      case "NO_SHOW":
        return "No Show";
      case "CANCELLED":
        return "Cancelled";
      case "REJECTED":
        return "Rejected";
      default:
        return status;
    }
  }

  // Check if order is pickup
  bool isPickupOrder(Order? order) {
    return order?.deliveryType?.toUpperCase() == "PICKUP";
  }

  // Format date time
  String formatDateTime(String? dateTime) {
    if (dateTime == null) return "";
    try {
      final dt = DateTime.parse(dateTime);
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} ${dt.day}/${dt.month}/${dt.year}";
    } catch (e) {
      return dateTime;
    }
  }

  // Format date
  String formatDate(String? dateTime) {
    if (dateTime == null) return "";
    try {
      final dt = DateTime.parse(dateTime);
      return "${dt.day} ${_getMonthName(dt.month)} ${dt.year}";
    } catch (e) {
      return dateTime;
    }
  }

  // Format time
  String formatTime(String? dateTime) {
    if (dateTime == null) return "";
    try {
      final dt = DateTime.parse(dateTime);
      final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
      final amPm = dt.hour >= 12 ? "PM" : "AM";
      return "${hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $amPm";
    } catch (e) {
      return dateTime;
    }
  }

  // Format full date and time
  String formatFullDateAndTime(String? dateTime) {
    if (dateTime == null) return "";
    try {
      final dt = DateTime.parse(dateTime);
      final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
      final timePart = dt.hour == 12
          ? 12
          : hour == 0
          ? 12
          : hour;
      final amPm = dt.hour >= 12 ? "PM" : "AM";
      return "${dt.day} ${_getMonthName(dt.month)} ${dt.year}, ${timePart.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $amPm";
    } catch (e) {
      return dateTime;
    }
  }

  String _getMonthName(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return months[month - 1];
  }
}
