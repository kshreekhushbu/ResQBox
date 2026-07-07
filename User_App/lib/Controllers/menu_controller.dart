import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:resqbox_user/Controllers/cart_controller.dart';
import 'package:resqbox_user/Models/categories_tabs_model.dart';
import 'package:resqbox_user/Models/menu_by_category_model.dart';
import 'package:resqbox_user/Models/menu_view_model.dart';
import 'package:resqbox_user/Services/apis.dart';
import 'package:resqbox_user/Services/dynamic_response.dart';
import 'package:resqbox_user/Utils/custom_loader.dart';
import 'package:resqbox_user/Utils/toast.dart';
import 'package:resqbox_user/main.dart';

class FoodMenuController extends ChangeNotifier {
  bool isLoading = false;
  bool isMenuLoading = false;
  bool isMenuViewLoading = false;
  bool isSeeAllLoading = false;
  CategoryTabsModel? categoriesTabsData;
  MenuByCategoryModel? menuByCategoryData;
  MenuViewModel? menuViewModelData;

  Future<void> allCategoriesTabsApi() async {
    isLoading = true;
    notifyListeners();

    try {
      final url = "${Apis.baseUrl}${Apis.tabsCategoriesApi}";
      debugPrint("categories URL: $url");
      final response = await ApiService().getRequest(url);
      debugPrint("categories data: $response");
      if (response != null && response["status"] == 1) {
        isLoading = false;
        categoriesTabsData = CategoryTabsModel.fromJson(response);
        notifyListeners();
      } else {
        isLoading = false;
        categoriesTabsData = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("❌ Error fetching categories data: $e");
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getMenuByCategoryId(
      int? categoryId, int? tabId, double? latitude, double? longitude,
      {String? from, String? kitchenTypeIds, String? foodTypeIds}) async {
    isMenuLoading = true;
    menuByCategoryData = null; // Clear old data before loading new data
    notifyListeners();

    try {
      // Build URL dynamically
      String url = "${Apis.baseUrl}${Apis.getMenuApi}?";
      List<String> queryParams = [];

      if (from == "kitchen") {
        if (categoryId != null) queryParams.add("kitchenId=$categoryId");
        if (tabId != null) queryParams.add("categoryId=$tabId");
      } else if (from == "category") {
        if (categoryId != null) queryParams.add("categoryId=$categoryId");
      } else {
        if (categoryId != null) queryParams.add("foodtypeId=$categoryId");
        if (tabId != null) queryParams.add("categoryId=$tabId");
      }

      // Add filter parameters if present
      if (kitchenTypeIds != null && kitchenTypeIds.isNotEmpty) {
        queryParams.add("kitchenTypeId=$kitchenTypeIds");
      }
      if (foodTypeIds != null && foodTypeIds.isNotEmpty) {
        queryParams.add("foodtypeId=$foodTypeIds");
      }

      url += queryParams.join("&");
      debugPrint("menu URL: $url");
      final response = await ApiService().getRequest(url);
      debugPrint("menu data: $response");
      if (response != null && response["status"] == 1) {
        isMenuLoading = false;
        menuByCategoryData = MenuByCategoryModel.fromJson(response);
        notifyListeners();
      } else {
        isMenuLoading = false;
        menuByCategoryData = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("❌ Error fetching menu data: $e");
      isMenuLoading = false;
      notifyListeners();
    }
  }

  Future<void> addToCartApi(Map<String, dynamic> body) async {
    Loaders.showLoadingDialog();
    notifyListeners();

    try {
      final url = "${Apis.baseUrl}${Apis.addToCartApi}";
      debugPrint("addToCart URL: $url");
      final response = await ApiService().postRequest(url, body);
      debugPrint("addToCart data: $response");
      if (response != null && response["status"] == 1) {
        Loaders.hideLoadingDialog();
        await Provider.of<CartController>(navigatorKey.currentContext!,
                listen: false)
            .getCartApi();
        customToast(
            message: response["message"] ?? 'Item added to cart successfully');
        notifyListeners();
      } else {
        Loaders.hideLoadingDialog();
        customToast(
            message: response["message"] ?? 'Failed to add item to cart');
        notifyListeners();
      }
    } catch (e) {
      debugPrint("❌ Error adding to cart: $e");
      Loaders.hideLoadingDialog();
      notifyListeners();
    }
  }

  Future<void> menuViewApi(
      int? menuId, double? latitude, double? longitude) async {
    isMenuViewLoading = true;
    notifyListeners();

    try {
      final url =
          "${Apis.baseUrl}${Apis.menuViewApi}/$menuId?latitude=$latitude&longitude=$longitude";
      debugPrint("menuView URL: $url");
      final response = await ApiService().getRequest(url);
      debugPrint("menuView data: $response");
      if (response != null && response["status"] == 1) {
        isMenuViewLoading = false;
        menuViewModelData = MenuViewModel.fromJson(response);
        notifyListeners();
      } else {
        isMenuViewLoading = false;
        menuViewModelData = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("❌ Error fetching menu view data: $e");
      isMenuViewLoading = false;
      notifyListeners();
    }
  }

  Future<void> seeAllMenuApi(int? kitchenId) async {
    isMenuViewLoading = true;
    notifyListeners();

    try {
      final url = "${Apis.baseUrl}${Apis.menuViewApi}/$kitchenId";
      debugPrint("menuView URL: $url");
      final response = await ApiService().getRequest(url);
      debugPrint("menuView data: $response");
      if (response != null && response["status"] == 1) {
        isMenuViewLoading = false;
        menuViewModelData = MenuViewModel.fromJson(response);
        notifyListeners();
      } else {
        isMenuViewLoading = false;
        menuViewModelData = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("❌ Error fetching menu view data: $e");
      isMenuViewLoading = false;
      notifyListeners();
    }
  }
}
