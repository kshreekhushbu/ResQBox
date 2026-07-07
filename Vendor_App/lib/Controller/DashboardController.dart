import 'package:flutter/material.dart';
import 'package:resqboxvendor/Models/dashboard_model.dart';
import 'package:resqboxvendor/Services/AppUrls.dart';
import 'package:resqboxvendor/Services/api.dart';
import 'package:resqboxvendor/Services/dynamic_response.dart';
import 'package:resqboxvendor/Utils/toast.dart';

class DashboardProvider extends ChangeNotifier {
  int _selectedIndex = 0;

  int get selectedIndex => _selectedIndex;

  void setIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  // Dashboard API Integration
  DashboardData? dashboardData;
  bool isLoading = false;
  String selectedFilter = 'today'; // Default filter

  // Get Dashboard Data
  Future<void> getDashboardData(String type) async {
    try {
      isLoading = true;
      selectedFilter = type;
      notifyListeners();

      final url = '${Api.baseUrl}${AppUrls.getKitchenDashboard}?type=$type';
      debugPrint("📤 Get Dashboard URL: $url");

      final res = await ApiService().getRequest(url);

      debugPrint("📥 Get Dashboard Response: $res");

      if (res != null && (res['status'] == 1 || res['Status'] == 1)) {
        final dashboardResponse = DashboardResponse.fromJson(res);
        dashboardData = dashboardResponse.data;
        debugPrint("✅ Dashboard data loaded for type: $type");
      } else {
        customToast(
          message: res?['message'] ?? "Failed to load dashboard data",
        );
        dashboardData = null;
      }
    } catch (e) {
      debugPrint("❌ Error getting dashboard data: $e");
      customToast(message: "Failed to load dashboard data");
      dashboardData = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Update filter
  void updateFilter(String type) {
    if (selectedFilter != type) {
      getDashboardData(type);
    }
  }
}
