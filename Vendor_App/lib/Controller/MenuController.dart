import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:image_picker/image_picker.dart';
import 'package:resqboxvendor/Models/category_model.dart';
import 'package:resqboxvendor/Models/cuisine_model.dart';
import 'package:resqboxvendor/Models/food_type_model.dart';
import 'package:resqboxvendor/Models/menu_item_model.dart';
import 'package:resqboxvendor/Services/AppUrls.dart';
import 'package:resqboxvendor/Services/api.dart';
import 'package:resqboxvendor/Services/dynamic_response.dart';
import 'package:resqboxvendor/Utils/toast.dart';

class MenuController extends ChangeNotifier {
  final ImagePicker _picker = ImagePicker();

  int? spiceLevel;

  void setSpiceLevel(int? level) {
    spiceLevel = level;
    notifyListeners();
  }

  // Form Controllers
  final TextEditingController itemNameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController discountPriceController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController startTimeController = TextEditingController();
  final TextEditingController endTimeController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();

  DateTime? startTimeDate;
  DateTime? endTimeDate;

  List<Category> _selectedCategories = [];
  List<Category> get selectedCategories => _selectedCategories;

  List<FoodType> _selectedMenuTypes = [];
  List<FoodType> get selectedMenuTypes => _selectedMenuTypes;

  bool _isVegetarian = false;
  bool get isVegetarian => _isVegetarian;

  bool _isNonVegetarian = true;
  bool get isNonVegetarian => _isNonVegetarian;

  // Setters
  void setSelectedCategories(List<Category> categories) {
    _selectedCategories = categories;
    notifyListeners();
  }

  void setSelectedMenuTypes(List<FoodType> types) {
    _selectedMenuTypes = types;
    notifyListeners();
  }

  void setIsVegetarian(bool value) {
    _isVegetarian = value;
    _isNonVegetarian = !value;
    notifyListeners();
  }

  void setIsNonVegetarian(bool value) {
    _isNonVegetarian = value;
    _isVegetarian = !value;
    notifyListeners();
  }

  void setStartTime(String time) {
    startTimeController.text = time;
    notifyListeners();
  }

  void setEndTime(String time) {
    endTimeController.text = time;
    notifyListeners();
  }

  void setStartDate(DateTime date, String formattedDate) {
    startTimeDate = date;
    startDateController.text = formattedDate;
    notifyListeners();
  }

  void setEndDate(DateTime date, String formattedDate) {
    endTimeDate = date;
    endDateController.text = formattedDate;
    notifyListeners();
  }

  // Map spice level to API format
  String? get spiceLevelString {
    switch (spiceLevel) {
      case 1:
        return "NORMAL";
      case 2:
        return "MEDIUM";
      case 3:
        return "EXTRA_SPICY";
      default:
        return null;
    }
  }

  File? dishImage;
  String? uploadedImageFileName;
  String? displayedImageUrl;

  List<Category> categories = [];
  List<Cuisine> cuisines = [];
  List<FoodType> foodTypes = [];
  List<FoodType> menuTypes = [];

  bool isLoadingCategories = false;
  bool isLoadingCuisines = false;
  bool isLoadingFoodTypes = false;
  bool isLoadingMenuTypes = false;

  // Menu Items
  List<MenuItem> menuItems = [];
  bool isLoadingMenuItems = false;

  // Search
  bool isSearchVisible = false;
  final TextEditingController searchController = TextEditingController();

  // Offer Price Validation
  String? offerPriceValidationMessage;
  bool isValidatingOfferPrice = false;

  Future<void> validateOfferPrice() async {
    final priceText = priceController.text.trim();
    final offerPriceText = discountPriceController.text.trim();

    final price = double.tryParse(priceText);
    final offerPrice = double.tryParse(offerPriceText);

    if (price == null || offerPrice == null) {
      offerPriceValidationMessage = null;
      notifyListeners();
      return;
    }

    try {
      isValidatingOfferPrice = true;
      notifyListeners();

      final url = '${Api.baseUrl}${AppUrls.validateOfferPrice}';
      final body = {"price": price, "offerPrice": offerPrice};

      debugPrint("📤 Validate Offer Price Payload: $body");

      final res = await ApiService().postRequest(url, body);

      debugPrint("📥 Validate Offer Price Response: $res");

      if (res != null) {
        if (res['status'] == 1 || res['Status'] == 1) {
          offerPriceValidationMessage = "✅ ${res['message']}";
        } else {
          offerPriceValidationMessage = "❌ ${res['message']}";
        }
      } else {
        offerPriceValidationMessage = "❌ Failed to validate price";
      }
    } catch (e) {
      debugPrint("❌ Error validating offer price: $e");
      offerPriceValidationMessage = "❌ Error validating price";
    } finally {
      isValidatingOfferPrice = false;
      notifyListeners();
    }
  }

  void clearOfferPriceValidation() {
    offerPriceValidationMessage = null;
    isValidatingOfferPrice = false;
    notifyListeners();
  }

  // Edit Mode
  bool isEditMode = false;
  int? editingItemId;
  int currentActiveStatus = 0; // 0: Inactive, 1: Active

  // Pick Dish Image
  Future<void> pickDishImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (picked != null) {
        dishImage = File(picked.path);
        displayedImageUrl =
            null; // Clear displayed URL when new image is picked
        notifyListeners();
      }
    } catch (e) {
      debugPrint("❌ Error picking dish image: $e");
      customToast(message: "Failed to pick image");
    }
  }

  // Set Dish Image (Manually)
  void setDishImage(File file) {
    dishImage = file;
    displayedImageUrl = null; // Clear displayed URL when new image is picked
    notifyListeners();
  }

  // Get Categories
  Future<void> getCategories() async {
    try {
      isLoadingCategories = true;
      await Future.delayed(Duration.zero);
      notifyListeners();

      final url = '${Api.baseUrl}${AppUrls.getCategories}';
      debugPrint("📤 Get Categories URL: $url");

      final res = await ApiService().getRequest(url);

      debugPrint("📥 Get Categories Response: $res");

      if (res != null && (res['status'] == 1 || res['Status'] == 1)) {
        final getCategories = GetCategories.fromJson(res);
        final loadedCategories = getCategories.categories ?? [];
        // Remove duplicates based on ID
        categories = loadedCategories
            .fold<Map<int, Category>>({}, (map, category) {
              if (category.id != null && !map.containsKey(category.id)) {
                map[category.id!] = category;
              }
              return map;
            })
            .values
            .toList();
        debugPrint("✅ Categories loaded: ${categories.length}");
      } else {
        customToast(message: res?['message'] ?? "Failed to load categories");
        categories = [];
      }
    } catch (e) {
      debugPrint("❌ Error getting categories: $e");
      customToast(message: "Failed to load categories");
      categories = [];
    } finally {
      isLoadingCategories = false;
      notifyListeners();
    }
  }

  // Get Cuisines
  Future<void> getCuisines() async {
    try {
      isLoadingCuisines = true;
      await Future.delayed(Duration.zero);
      notifyListeners();

      final url = '${Api.baseUrl}${AppUrls.getCuisines}';
      debugPrint("📤 Get Cuisines URL: $url");

      final res = await ApiService().getRequest(url);

      debugPrint("📥 Get Cuisines Response: $res");

      if (res != null && (res['status'] == 1 || res['Status'] == 1)) {
        final getCuisines = GetCuisines.fromJson(res);
        final loadedCuisines = getCuisines.cuisines ?? [];
        // Remove duplicates based on ID
        cuisines = loadedCuisines
            .fold<Map<int, Cuisine>>({}, (map, cuisine) {
              if (cuisine.id != null && !map.containsKey(cuisine.id)) {
                map[cuisine.id!] = cuisine;
              }
              return map;
            })
            .values
            .toList();
        debugPrint("✅ Cuisines loaded: ${cuisines.length}");
      } else {
        customToast(message: res?['message'] ?? "Failed to load cuisines");
        cuisines = [];
      }
    } catch (e) {
      debugPrint("❌ Error getting cuisines: $e");
      customToast(message: "Failed to load cuisines");
      cuisines = [];
    } finally {
      isLoadingCuisines = false;
      notifyListeners();
    }
  }

  // Get Food Types
  Future<void> getFoodTypes() async {
    try {
      isLoadingFoodTypes = true;
      await Future.delayed(Duration.zero);
      notifyListeners();

      final url = '${Api.baseUrl}${AppUrls.getFoodTypes}';
      debugPrint("📤 Get Food Types URL: $url");

      final res = await ApiService().getRequest(url);

      debugPrint("📥 Get Food Types Response: $res");

      if (res != null && (res['status'] == 1 || res['Status'] == 1)) {
        final getFoodTypes = GetFoodTypes.fromJson(res);
        final loadedFoodTypes = getFoodTypes.foodTypes ?? [];
        // Remove duplicates based on ID
        foodTypes = loadedFoodTypes
            .fold<Map<int, FoodType>>({}, (map, foodType) {
              if (foodType.id != null && !map.containsKey(foodType.id)) {
                map[foodType.id!] = foodType;
              }
              return map;
            })
            .values
            .toList();
        debugPrint("✅ Food Types loaded: ${foodTypes.length}");
      } else {
        customToast(message: res?['message'] ?? "Failed to load food types");
        foodTypes = [];
      }
    } catch (e) {
      debugPrint("❌ Error getting food types: $e");
      customToast(message: "Failed to load food types");
      foodTypes = [];
    } finally {
      isLoadingFoodTypes = false;
      notifyListeners();
    }
  }

  // Get Menu Types
  Future<void> getMenuTypes() async {
    try {
      isLoadingMenuTypes = true;
      await Future.delayed(Duration.zero);
      notifyListeners();

      final url = '${Api.baseUrl}${AppUrls.getMenuTypes}';
      debugPrint("📤 Get Menu Types URL: $url");

      final res = await ApiService().getRequest(url);

      debugPrint("📥 Get Menu Types Response: $res");

      if (res != null && (res['status'] == 1 || res['Status'] == 1)) {
        final getMenuTypes = GetMenuTypes.fromJson(res);
        final loadedMenuTypes = getMenuTypes.menuTypes ?? [];
        // Remove duplicates based on ID
        menuTypes = loadedMenuTypes
            .fold<Map<int, FoodType>>({}, (map, menuType) {
              if (menuType.id != null && !map.containsKey(menuType.id)) {
                map[menuType.id!] = menuType;
              }
              return map;
            })
            .values
            .toList();
        debugPrint("✅ Menu Types loaded: ${menuTypes.length}");
      } else {
        customToast(message: res?['message'] ?? "Failed to load menu types");
        menuTypes = [];
      }
    } catch (e) {
      debugPrint("❌ Error getting menu types: $e");
      customToast(message: "Failed to load menu types");
      menuTypes = [];
    } finally {
      isLoadingMenuTypes = false;
      notifyListeners();
    }
  }

  // Upload Dish Image
  Future<String?> uploadDishImage({File? imageFile}) async {
    final fileToUpload = imageFile ?? dishImage;

    // If no new image selected, return existing image filename (for edit mode)
    if (fileToUpload == null) {
      if (isEditMode &&
          uploadedImageFileName != null &&
          uploadedImageFileName!.isNotEmpty) {
        debugPrint("✅ Using existing image: $uploadedImageFileName");
        return uploadedImageFileName;
      }
      customToast(message: "Please select a dish image");
      return null;
    }

    try {
      final url = '${Api.baseUrl}vendor/upload';

      final result = await ApiService().uploadImage(
        url: url,
        file: fileToUpload,
        folder: "menu",
        fieldName: "file",
      );

      if (result != null && result['fileName'] != null) {
        uploadedImageFileName = result['fileName'];
        // Also store the full URL if provided
        if (result['fileUrl'] != null) {
          displayedImageUrl = result['fileUrl'];
        } else {
          // Construct URL from filename if fileUrl not provided
          displayedImageUrl = result['fileName'];
        }
        debugPrint("✅ Dish image uploaded: ${result['fileName']}");
        return result['fileName'];
      } else {
        customToast(message: "Failed to upload image");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Error uploading dish image: $e");
      customToast(message: "Failed to upload image");
      return null;
    }
  }

  // Validate Form
  bool validateForm({File? imageOverride}) {
    if (itemNameController.text.trim().isEmpty) {
      customToast(message: "Please enter item name");
      return false;
    }
    if (_selectedCategories.isEmpty) {
      customToast(message: "Please select at least one item category");
      return false;
    }
    if (_selectedMenuTypes.isEmpty) {
      customToast(message: "Please select menu type");
      return false;
    }
    if (quantityController.text.trim().isEmpty) {
      customToast(message: "Please enter item quantity");
      return false;
    }
    if (priceController.text.trim().isEmpty) {
      customToast(message: "Please enter item price");
      return false;
    }
    if (discountPriceController.text.trim().isEmpty) {
      customToast(message: "Please enter discount price");
      return false;
    }
    if (descriptionController.text.trim().isEmpty) {
      customToast(message: "Please enter dish description");
      return false;
    }
    if (endTimeController.text.trim().isEmpty) {
      customToast(message: "Please select end time");
      return false;
    }
    // For edit mode, allow existing image. For add mode, require new image.
    if (!isEditMode && dishImage == null && imageOverride == null) {
      customToast(message: "Please upload dish picture");
      return false;
    }
    // For edit mode, require either existing image or new image
    if (isEditMode &&
        dishImage == null &&
        imageOverride == null &&
        (uploadedImageFileName == null || uploadedImageFileName!.isEmpty)) {
      customToast(message: "Please upload dish picture");
      return false;
    }
    return true;
  }

  // Add Menu Item
  Future<bool> addMenuItem({File? defaultImage}) async {
    try {
      if (!validateForm(imageOverride: defaultImage)) return false;

      EasyLoading.show(status: 'Adding menu item...');

      // Upload image first (for add mode, dishImage or defaultImage must be selected)
      final imageFileName = await uploadDishImage(imageFile: defaultImage);
      if (imageFileName == null || imageFileName.isEmpty) {
        EasyLoading.dismiss();
        return false;
      }

      // Format time to HH:mm
      String formatTime(String timeStr) {
        if (timeStr.isEmpty) return "";
        // If already in HH:mm format, return as is
        if (timeStr.contains(":") && timeStr.length == 5) {
          return timeStr;
        }
        // Try to parse and format
        try {
          final parts = timeStr.split(":");
          if (parts.length >= 2) {
            final hour = parts[0].padLeft(2, '0');
            final minute = parts[1].split(" ")[0].padLeft(2, '0');
            return "$hour:$minute";
          }
        } catch (e) {
          debugPrint("Error formatting time: $e");
        }
        return timeStr;
      }

      // Prepare payload
      final payload = {
        "name": itemNameController.text.trim(),
        "categoryIds": _selectedCategories.map((cat) => cat.id!).toList(),
        "foodtypeIds": _selectedMenuTypes.map((type) => type.id!).toList(),
        "quantity": int.tryParse(quantityController.text.trim()) ?? 0,
        "price": double.tryParse(priceController.text.trim()) ?? 0.0,
        "discountPrice":
            double.tryParse(discountPriceController.text.trim()) ?? 0.0,
        "description": descriptionController.text.trim(),
        "image": imageFileName,
        // "isVegetarian": _isVegetarian,
        // "isSpicy": spiceLevelString,
        "startTime": startTimeController.text.trim().isEmpty
            ? formatTime(DateFormat('HH:mm').format(DateTime.now()))
            : formatTime(startTimeController.text.trim()),
        "endTime": formatTime(endTimeController.text.trim()),
        "startTimeDate": startTimeDate != null
            ? DateFormat('yyyy-MM-dd').format(startTimeDate!)
            : DateFormat('yyyy-MM-dd').format(DateTime.now()),
        "endTimeDate": endTimeDate != null
            ? DateFormat('yyyy-MM-dd').format(endTimeDate!)
            : null,
      };

      final url = '${Api.baseUrl}${AppUrls.addMenuItem}';
      debugPrint("📤 Add Menu Item URL: $url");
      debugPrint("📤 Payload: $payload");

      final res = await ApiService().postRequest(url, payload);

      debugPrint("📥 Add Menu Item Response: $res");

      if (res != null && (res['status'] == 1 || res['Status'] == 1)) {
        customToast(message: "Menu item added successfully!");
        resetForm();
        return true;
      } else {
        customToast(message: res?['message'] ?? "Failed to add menu item");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Error adding menu item: $e");
      customToast(message: "Failed to add menu item");
      return false;
    } finally {
      EasyLoading.dismiss();
    }
  }

  // Get All Menu Items
  Future<void> getAllMenuItems({String? searchQuery}) async {
    try {
      isLoadingMenuItems = true;
      await Future.delayed(Duration.zero);
      notifyListeners();

      String url = '${Api.baseUrl}${AppUrls.getAllMenuItems}';
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        url += '?search=${Uri.encodeComponent(searchQuery.trim())}';
      }
      debugPrint("📤 Get All Menu Items URL: $url");

      final res = await ApiService().getRequest(url);

      debugPrint("📥 Get All Menu Items Response: $res");

      if (res != null && (res['status'] == 1 || res['Status'] == 1)) {
        final getMenuItems = GetMenuItems.fromJson(res);
        menuItems = getMenuItems.menuItems ?? [];
        debugPrint("✅ Menu items loaded: ${menuItems.length}");
      } else {
        customToast(message: res?['message'] ?? "Failed to load menu items");
        menuItems = [];
      }
    } catch (e) {
      debugPrint("❌ Error getting menu items: $e");
      customToast(message: "Failed to load menu items");
      menuItems = [];
    } finally {
      isLoadingMenuItems = false;
      notifyListeners();
    }
  }

  // Toggle Search Visibility
  void toggleSearchVisibility() {
    isSearchVisible = !isSearchVisible;
    if (!isSearchVisible) {
      // Clear search and get full list
      searchController.clear();
      getAllMenuItems();
    }
    notifyListeners();
  }

  // Perform Search
  void performSearch(String query) {
    if (query.trim().isEmpty) {
      getAllMenuItems(); // Get full list if search is empty
    } else {
      getAllMenuItems(searchQuery: query);
    }
  }

  void clearSearch() {
    searchController.clear();
    getAllMenuItems();
  }

  Future<void> loadMenuItemForEditing(MenuItem item) async {
    isEditMode = true;
    editingItemId = item.id;

    if (categories.isEmpty) {
      await getCategories();
    }
    if (cuisines.isEmpty) {
      await getCuisines();
    }
    if (foodTypes.isEmpty) {
      await getFoodTypes();
    }

    itemNameController.text = item.name ?? "";
    quantityController.text = item.quantity?.toString() ?? "";
    priceController.text = item.price != null
        ? item.price!.toString().replaceAll(RegExp(r'\.0$'), '')
        : "";
    discountPriceController.text = item.discountPrice != null
        ? item.discountPrice!.toString().replaceAll(RegExp(r'\.0$'), '')
        : "";
    descriptionController.text = item.description ?? "";
    startTimeController.text = item.startTime ?? "";
    endTimeController.text = item.endTime ?? "";

    if (item.startTimeDate != null && item.startTimeDate!.isNotEmpty) {
      DateTime? parsedDate;
      try {
        parsedDate = DateFormat('yyyy-MM-dd').parse(item.startTimeDate!);
      } catch (e) {
        try {
          parsedDate = DateTime.parse(item.startTimeDate!);
        } catch (e2) {
          debugPrint("❌ Error parsing startTimeDate: $e2");
        }
      }

      if (parsedDate != null) {
        startTimeDate = parsedDate;
        startDateController.text = DateFormat('dd-MM-yyyy').format(parsedDate);
      }
    }
    if (item.endTimeDate != null && item.endTimeDate!.isNotEmpty) {
      DateTime? parsedDate;
      try {
        parsedDate = DateFormat('yyyy-MM-dd').parse(item.endTimeDate!);
      } catch (e) {
        try {
          parsedDate = DateTime.parse(item.endTimeDate!);
        } catch (e2) {
          debugPrint("❌ Error parsing endTimeDate: $e2");
        }
      }

      if (parsedDate != null) {
        endTimeDate = parsedDate;
        endDateController.text = DateFormat('dd-MM-yyyy').format(parsedDate);
      }
    }

    _isVegetarian = item.isVegetarian ?? false;
    _isNonVegetarian = !(_isVegetarian);

    // Map isSpicy string to spiceLevel int
    if (item.isSpicy != null) {
      if (item.isSpicy is String) {
        final spicyStr = item.isSpicy.toString().toUpperCase();
        switch (spicyStr) {
          case "NORMAL":
            spiceLevel = 1;
            break;
          case "MEDIUM":
            spiceLevel = 2;
            break;
          case "EXTRA_SPICY":
            spiceLevel = 3;
            break;
          default:
            spiceLevel = 1;
        }
      } else if (item.isSpicy is bool) {
        spiceLevel = (item.isSpicy as bool) ? 2 : 1;
      }
    } else {
      spiceLevel = null;
    }

    // Find and set categories - handle categoryIds array from API
    _selectedCategories = [];
    if (item.categoryIds != null && item.categoryIds!.isNotEmpty) {
      // Use categoryIds array from API response
      for (var categoryInfo in item.categoryIds!) {
        if (categoryInfo.id != null && categories.isNotEmpty) {
          try {
            final foundCategory = categories.firstWhere(
              (cat) => cat.id == categoryInfo.id,
            );
            if (!_selectedCategories.contains(foundCategory)) {
              _selectedCategories.add(foundCategory);
            }
          } catch (e) {
            debugPrint("❌ Category not found: ${categoryInfo.id}, Error: $e");
          }
        }
      }
      debugPrint("✅ Categories set: ${_selectedCategories.length} categories");
    } else if (item.categoryId != null && categories.isNotEmpty) {
      // Fallback to single categoryId if categoryIds array is not available
      try {
        final foundCategory = categories.firstWhere(
          (cat) => cat.id == item.categoryId,
        );
        _selectedCategories = [foundCategory];
        debugPrint(
          "✅ Category set: ${foundCategory.name} (ID: ${foundCategory.id})",
        );
      } catch (e) {
        debugPrint("❌ Category not found: ${item.categoryId}, Error: $e");
        _selectedCategories = [];
      }
    } else {
      debugPrint("⚠️ Category IDs are null or categories list is empty");
      _selectedCategories = [];
    }

    // Find and set food type - check both foodtypeId and foodtype object
    // _selectedFoodType = null;
    // int? foodTypeIdToUse = item.foodtypeId ?? item.foodtype?.id;
    // if (foodTypeIdToUse != null && foodTypes.isNotEmpty) {
    //   try {
    //     final foundFoodType = foodTypes.firstWhere(
    //       (ft) => ft.id == foodTypeIdToUse,
    //     );
    //     _selectedFoodType = foundFoodType;
    //     debugPrint(
    //       "✅ Food Type set: ${foundFoodType.name} (ID: ${foundFoodType.id})",
    //     );
    //   } catch (e) {
    //     debugPrint("❌ Food Type not found: $foodTypeIdToUse, Error: $e");
    //     _selectedFoodType = null;
    //   }
    // } else {
    //   debugPrint("⚠️ Food Type ID is null or food types list is empty");
    //   _selectedFoodType = null;
    // }

    // Find and set menu types
    _selectedMenuTypes = [];
    if (item.menuTypes != null && item.menuTypes!.isNotEmpty) {
      for (var menuTypeInfo in item.menuTypes!) {
        if (menuTypeInfo.id != null) {
          try {
            // Since menuTypes list might not be loaded yet if we jump straight to edit
            // we might need to load them or use what we have in the item
            if (menuTypes.isEmpty) {
              await getMenuTypes();
            }
            final foundType = menuTypes.firstWhere(
              (mt) => mt.id == menuTypeInfo.id,
            );
            if (!_selectedMenuTypes.contains(foundType)) {
              _selectedMenuTypes.add(foundType);
            }
          } catch (e) {
            debugPrint("❌ Menu Type not found: ${menuTypeInfo.id}, Error: $e");
          }
        }
      }
      debugPrint("✅ Menu Types set: ${_selectedMenuTypes.length} types");
    }

    // Force notify listeners after setting values
    notifyListeners();

    // Small delay to ensure UI updates
    await Future.delayed(Duration(milliseconds: 100));

    // Note: Image will be handled separately - user can choose to keep existing or upload new
    // Store both full URL (for display) and filename (for API)
    if (item.image != null && item.image!.isNotEmpty) {
      if (item.image!.contains('/')) {
        // Full URL - store both URL for display and filename for API
        displayedImageUrl = item.image; // Full URL for UI display
        uploadedImageFileName = item.image!.split('/').last; // Filename for API
        debugPrint("✅ Image URL for display: $displayedImageUrl");
        debugPrint("✅ Extracted filename for API: $uploadedImageFileName");
      } else {
        // Already a filename - assume it needs to be constructed as URL
        uploadedImageFileName = item.image;
        // Try to construct full URL if we have base URL
        displayedImageUrl =
            item.image; // Will try to use as-is, or construct if needed
        debugPrint("✅ Using filename as-is: $uploadedImageFileName");
      }
    } else {
      uploadedImageFileName = null;
      displayedImageUrl = null;
    }
    dishImage = null; // Reset local image, will use existing if not changed

    currentActiveStatus = item.isActive ?? 0;
    debugPrint("✅ Current Active Status: $currentActiveStatus");

    notifyListeners();
  }

  // Update Menu Item
  Future<bool> updateMenuItem() async {
    try {
      if (!validateForm()) return false;
      if (editingItemId == null) return false;

      EasyLoading.show(status: 'Updating menu item...');

      // Upload new image if user selected one, otherwise use existing
      String? imageFileName = uploadedImageFileName;
      if (dishImage != null) {
        final uploaded = await uploadDishImage();
        if (uploaded == null) {
          EasyLoading.dismiss();
          return false;
        }
        imageFileName = uploaded;
      } else if (imageFileName != null && imageFileName.contains('/')) {
        // Extract filename from URL if it's still a full URL
        imageFileName = imageFileName.split('/').last;
        debugPrint("✅ Extracted filename for update: $imageFileName");
      }

      // Format time to HH:mm
      String formatTime(String timeStr) {
        if (timeStr.isEmpty) return "";
        // If already in HH:mm format, return as is
        if (timeStr.contains(":") && timeStr.length == 5) {
          return timeStr;
        }
        // Try to parse and format
        try {
          final parts = timeStr.split(":");
          if (parts.length >= 2) {
            final hour = parts[0].padLeft(2, '0');
            final minute = parts[1].split(" ")[0].padLeft(2, '0');
            return "$hour:$minute";
          }
        } catch (e) {
          debugPrint("Error formatting time: $e");
        }
        return timeStr;
      }

      // Prepare payload
      final payload = {
        "name": itemNameController.text.trim(),
        "categoryIds": _selectedCategories.map((cat) => cat.id!).toList(),
        "foodtypeIds": _selectedMenuTypes.map((type) => type.id!).toList(),
        "quantity": int.tryParse(quantityController.text.trim()) ?? 0,
        "price": double.tryParse(priceController.text.trim()) ?? 0.0,
        "discountPrice":
            double.tryParse(discountPriceController.text.trim()) ?? 0.0,
        "description": descriptionController.text.trim(),
        "image": imageFileName ?? "",
        "isVegetarian": _isVegetarian,
        "isSpicy": spiceLevelString,
        "startTime": startTimeController.text.trim().isEmpty
            ? formatTime(DateFormat('HH:mm').format(DateTime.now()))
            : formatTime(startTimeController.text.trim()),
        "endTime": formatTime(endTimeController.text.trim()),
        "startTimeDate": startTimeDate != null
            ? DateFormat('yyyy-MM-dd').format(startTimeDate!)
            : DateFormat('yyyy-MM-dd').format(DateTime.now()),
        "endTimeDate": endTimeDate != null
            ? DateFormat('yyyy-MM-dd').format(endTimeDate!)
            : null,
        "isActive": 1, // Automatically enable item after update
      };

      final url = '${Api.baseUrl}${AppUrls.updateMenuItem}/$editingItemId';
      debugPrint("📤 Update Menu Item URL: $url");
      debugPrint("📤 Payload: $payload");

      final res = await ApiService().putRequest(url, payload);

      debugPrint("📥 Update Menu Item Response: $res");

      if (res != null && (res['status'] == 1 || res['Status'] == 1)) {
        customToast(message: "Menu item updated successfully!");
        resetForm();
        await getAllMenuItems(); // Refresh list
        return true;
      } else {
        customToast(message: res?['message'] ?? "Failed to update menu item");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Error updating menu item: $e");
      customToast(message: "Failed to update menu item");
      return false;
    } finally {
      EasyLoading.dismiss();
    }
  }

  // Delete Menu Item
  Future<bool> deleteMenuItem(int itemId) async {
    try {
      EasyLoading.show(status: 'Deleting menu item...');

      final url = '${Api.baseUrl}${AppUrls.deleteMenuItem}/$itemId';
      debugPrint("📤 Delete Menu Item URL: $url");

      final res = await ApiService().deleteRequest(url);

      debugPrint("📥 Delete Menu Item Response: $res");

      if (res != null && (res['status'] == 1 || res['Status'] == 1)) {
        customToast(message: "Menu item deleted successfully!");
        await getAllMenuItems(); // Refresh list
        return true;
      } else {
        customToast(message: res?['message'] ?? "Failed to delete menu item");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Error deleting menu item: $e");
      customToast(message: "Failed to delete menu item");
      return false;
    } finally {
      EasyLoading.dismiss();
    }
  }

  // Toggle Menu Item Active Status
  Future<void> toggleMenuItemStatus(int itemId, bool isActive) async {
    try {
      EasyLoading.show(status: 'Updating status...');

      final url =
          '${Api.baseUrl}${AppUrls.activateMenuItem}/$itemId?isActive=${isActive ? 1 : 0}';
      debugPrint("📤 Toggle Menu Item Status URL: $url");

      final res = await ApiService().putRequest(url, {});

      debugPrint("📥 Toggle Menu Item Status Response: $res");

      if (res != null && (res['status'] == 1 || res['Status'] == 1)) {
        // Update local state
        final index = menuItems.indexWhere((item) => item.id == itemId);
        if (index != -1) {
          menuItems[index].isActive = isActive ? 1 : 0;
          notifyListeners();
        }
        customToast(message: "Status updated successfully");
      } else {
        customToast(message: res?['message'] ?? "Failed to update status");
      }
    } catch (e) {
      debugPrint("❌ Error toggling menu item status: $e");
      customToast(message: "Failed to update status");
    } finally {
      EasyLoading.dismiss();
    }
  }

  // Reset Form
  void resetForm() {
    isEditMode = false;
    editingItemId = null;
    itemNameController.clear();
    quantityController.clear();
    priceController.clear();
    discountPriceController.clear();
    descriptionController.clear();
    startTimeController.clear();
    endTimeController.clear();
    startDateController.clear();
    endDateController.clear();
    startTimeDate = null;
    endTimeDate = null;
    _selectedCategories = [];
    _selectedMenuTypes = [];
    // _selectedFoodType = null;
    _isVegetarian = false;
    _isNonVegetarian = true;
    spiceLevel = null;
    dishImage = null;
    uploadedImageFileName = null;
    displayedImageUrl = null;
    offerPriceValidationMessage = null;
    isValidatingOfferPrice = false;
    notifyListeners();
  }

  @override
  void dispose() {
    itemNameController.dispose();
    quantityController.dispose();
    priceController.dispose();
    discountPriceController.dispose();
    descriptionController.dispose();
    startTimeController.dispose();
    endTimeController.dispose();
    startDateController.dispose();
    endDateController.dispose();
    searchController.dispose();
    super.dispose();
  }
}
