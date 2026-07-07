import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:resqbox_user/Models/active_restaurent_model.dart';
import 'package:resqbox_user/Models/all_restaurents_model.dart';
import 'package:resqbox_user/Models/filter_type_model.dart';
import 'package:resqbox_user/Models/get_notification_model.dart';
import 'package:resqbox_user/Models/home_data_model.dart';
import 'package:resqbox_user/Models/kitchen_view_model.dart';
import 'package:resqbox_user/Models/popular_near_you_model.dart';
import 'package:resqbox_user/Models/reviews_model.dart';
import 'package:resqbox_user/Models/search_model.dart';
import 'package:resqbox_user/Services/apis.dart';
import 'package:resqbox_user/Services/dynamic_response.dart';

class HomeController extends ChangeNotifier {
  LatLng? _currentPosition;
  String? _address;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  List<Placemark> placemarks = [];
  LatLng? get currentPosition => _currentPosition;

  String? get address => _address;
  Set<Marker> get markers => _markers;
  GoogleMapController? get mapController => _mapController;
  bool isLoading = false;
  bool isLoadingRestaurants = false;
  bool isRestaurentViewLoading = false;
  bool isKitchenReviewsLoading = false;
  bool isLoadingPopularRestaurants = false;
  bool isLoadingActiveRestaurants = false;
  bool isLoadingSearch = false;
  bool isLoadingNotifications = false;
  bool isLoadingFilterData = false;

  // Editable location details
  double? locLatitude;
  double? locLongitude;
  String? locPincode;
  String? locLandmark;
  String? locHouse;
  String? locAddress;
  bool isLocationServiceEnabled = true;
  String? locationErrorMessage;
  bool isLoadingLocation = false;
  HomeDataModel? homeData;
  AllRestaurentsModel? allRestaurantsData;
  KitchenViewModel? restaurantViewModelData;
  ReviewsModel? reviewsModelData;
  PopularNearModel? popularNearModelData;
  ActiveRestaurentModel? activeRestaurantsModelData;
  SearchModel? searchData;
  GetNotificationsModel? getNotificationsModelData;
  FilterTypeModel? filterTypeModelData;

  void setMapController(GoogleMapController controller) {
    _mapController = controller;
  }

  void setLocationDetails({
    required String house,
    required String landmark,
    required String pincode,
  }) {
    locHouse = house;
    locLandmark = landmark;
    locPincode = pincode;
    notifyListeners();
  }

  Future<void> getCurrentLocation({bool forceRefresh = false}) async {
    // If we already have valid location and not forcing refresh, skip
    if (!forceRefresh && locLatitude != null && locLongitude != null) {
      debugPrint("📍 Location already available, skipping fetch");
      return;
    }

    isLoadingLocation = true;
    isLoading = true;
    locationErrorMessage = null;
    notifyListeners();

    try {
      // Check app location permission using both methods
      LocationPermission permission = await Geolocator.checkPermission();
      final permissionHandlerStatus = await Permission.location.status;
      debugPrint("📍 Current location permission (Geolocator): $permission");
      debugPrint(
          "📍 Current location permission (Handler): $permissionHandlerStatus");

      // Check if permission is already granted
      final isAlreadyGranted = (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always) ||
          permissionHandlerStatus.isGranted;

      // If permission is denied forever, show error message
      if (permission == LocationPermission.deniedForever ||
          permissionHandlerStatus.isPermanentlyDenied) {
        locationErrorMessage =
            "Location permission denied permanently. Please enable it from app settings.";
        isLoadingLocation = false;
        isLoading = false;
        notifyListeners();
        debugPrint("❌ Location permission denied forever");
        return;
      }

      // If permission is not granted (denied, not determined, or restricted), request it
      final needsRequest = !isAlreadyGranted &&
          (permission == LocationPermission.denied ||
              permissionHandlerStatus.isDenied ||
              permissionHandlerStatus.isRestricted ||
              !permissionHandlerStatus.isGranted);

      if (needsRequest) {
        debugPrint(
            "📍 Permission not granted, requesting location permission...");

        final requestResult = await Permission.location.request();
        debugPrint("📍 Permission request result: $requestResult");

        await Future.delayed(const Duration(milliseconds: 300));

        // Re-check permission status after request
        permission = await Geolocator.checkPermission();
        final newPermissionStatus = await Permission.location.status;
        debugPrint("📍 Permission after request (Geolocator): $permission");
        debugPrint(
            "📍 Permission after request (Handler): $newPermissionStatus");

        // Check the result after requesting
        if (requestResult.isDenied || permission == LocationPermission.denied) {
          locationErrorMessage =
              "Location permission denied. Please allow location access.";
          isLoadingLocation = false;
          isLoading = false;
          notifyListeners();
          debugPrint("❌ Location permission denied after request");
          return;
        }

        if (requestResult.isPermanentlyDenied ||
            permission == LocationPermission.deniedForever) {
          locationErrorMessage =
              "Location permission denied permanently. Please enable it from app settings.";
          isLoadingLocation = false;
          isLoading = false;
          notifyListeners();
          debugPrint("❌ Location permission denied forever after request");
          return;
        }

        // If still not granted, return
        if (!requestResult.isGranted &&
            permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          locationErrorMessage =
              "Location permission not granted. Please allow location access.";
          isLoadingLocation = false;
          isLoading = false;
          notifyListeners();
          debugPrint("❌ Location permission not granted after request");
          return;
        }
      }

      // Verify permission is granted (whileInUse or always)
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        locationErrorMessage =
            "Location permission not granted. Please allow location access.";
        isLoadingLocation = false;
        isLoading = false;
        notifyListeners();
        debugPrint("❌ Location permission not granted: $permission");
        return;
      }

      debugPrint("✅ Location permission granted: $permission");

      // Check if location services (GPS) are enabled
      isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!isLocationServiceEnabled) {
        locationErrorMessage =
            "Location services (GPS) are disabled. Please enable GPS.";
        isLoadingLocation = false;
        isLoading = false;
        notifyListeners();
        debugPrint("❌ Location services (GPS) are disabled");
        return;
      }

      // Now get the actual location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentPosition = LatLng(position.latitude, position.longitude);
      locationErrorMessage = null;

      locLatitude = position.latitude;
      locLongitude = position.longitude;
      debugPrint("📍 Current position: $_currentPosition");

      placemarks = await placemarkFromCoordinates(locLatitude!, locLongitude!);
      if (placemarks.isNotEmpty) {
        _updateAddressDetails(placemarks.first);
      }

      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId("currentLocation"),
          position: _currentPosition!,
        ),
      );

      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(_currentPosition!),
        );
      }

      // Call homepage API if latitude and longitude are available
      if (locLatitude != null && locLongitude != null) {
        await fetchHomePageData(
          latitude: locLatitude!,
          longitude: locLongitude!,
          forceRefresh: forceRefresh,
        );
      }

      isLoadingLocation = false;
      isLoading = false;
      notifyListeners();
      debugPrint("✅ Location retrieved successfully");
    } catch (e) {
      debugPrint("❌ Error getting location: $e");
      isLoadingLocation = false;
      isLoading = false;
      locationErrorMessage = "Error getting location. Please try again.";
      notifyListeners();
    }
  }

  /// Opens device location settings
  Future<void> openLocationSettings() async {
    // Open app-specific location settings first (for permission)
    await Geolocator.openAppSettings();
    // Also open system location settings (for GPS)
    await Geolocator.openLocationSettings();
  }

  /// Explicitly request location permission (shows system dialog)
  Future<bool> requestLocationPermission() async {
    try {
      debugPrint("📍 Explicitly requesting location permission...");

      // Check current status first
      final currentStatus = await Permission.location.status;
      final geolocatorPermission = await Geolocator.checkPermission();
      debugPrint("📍 Current permission status (Handler): $currentStatus");
      debugPrint(
          "📍 Current permission status (Geolocator): $geolocatorPermission");

      // If permanently denied, we can't request again - must open settings
      if (currentStatus.isPermanentlyDenied ||
          geolocatorPermission == LocationPermission.deniedForever) {
        debugPrint("📍 Permission permanently denied, opening app settings");
        await openLocationSettings();
        // Wait a bit for user to potentially grant permission
        await Future.delayed(const Duration(milliseconds: 1000));
        // Re-check after returning from settings
        return await checkLocationStatus();
      }

      // If just denied (not permanently), we can request again
      if (currentStatus.isDenied ||
          geolocatorPermission == LocationPermission.denied) {
        debugPrint("📍 Permission denied, requesting again...");
        // Use permission_handler to request permission (this shows the system dialog)
        final status = await Permission.location.request();
        debugPrint("📍 Permission request result: $status");

        // Wait a bit for the system to update
        await Future.delayed(const Duration(milliseconds: 500));

        // Re-check with Geolocator
        final newGeolocatorPermission = await Geolocator.checkPermission();
        debugPrint(
            "📍 Geolocator permission after request: $newGeolocatorPermission");

        // Also re-check with permission_handler
        final finalStatus = await Permission.location.status;
        debugPrint("📍 Final permission status: $finalStatus");

        // Return true if permission is granted by either method
        final isGranted = (status.isGranted || finalStatus.isGranted) &&
            (newGeolocatorPermission == LocationPermission.whileInUse ||
                newGeolocatorPermission == LocationPermission.always);

        debugPrint("📍 Final permission granted: $isGranted");
        return isGranted;
      }

      // Already granted
      if (currentStatus.isGranted ||
          geolocatorPermission == LocationPermission.whileInUse ||
          geolocatorPermission == LocationPermission.always) {
        debugPrint("📍 Permission already granted");
        return true;
      }

      return false;
    } catch (e, stackTrace) {
      debugPrint("❌ Error requesting location permission: $e");
      debugPrint("❌ Stack trace: $stackTrace");
      return false;
    }
  }

  /// Checks if location permission is granted and services are enabled
  /// This checks both GPS service and app location permission
  Future<bool> checkLocationStatus() async {
    try {
      // First check if location services (GPS) are enabled
      isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isLocationServiceEnabled) {
        debugPrint("❌ Location services (GPS) are disabled");
        return false;
      }

      // Check app location permission with Geolocator
      LocationPermission geolocatorPermission =
          await Geolocator.checkPermission();
      final hasGeolocatorPermission =
          geolocatorPermission == LocationPermission.whileInUse ||
              geolocatorPermission == LocationPermission.always;

      // Also check using permission_handler
      final permissionHandlerStatus = await Permission.location.status;
      final hasPermissionHandlerPermission = permissionHandlerStatus.isGranted;

      debugPrint("📍 Location service enabled: $isLocationServiceEnabled");
      debugPrint("📍 Geolocator permission: $geolocatorPermission");
      debugPrint("📍 Permission handler status: $permissionHandlerStatus");

      // If either source says permission is granted, consider it granted
      // (Sometimes one updates before the other)
      final hasPermission =
          hasGeolocatorPermission || hasPermissionHandlerPermission;

      if (!hasPermission) {
        debugPrint("❌ Location permission not granted");
        return false;
      }

      debugPrint("✅ Location permission granted");
      return true;
    } catch (e) {
      debugPrint("❌ Error checking location status: $e");
      return false;
    }
  }

  Future<void> updateUserSelectedLocation(LatLng tappedLocation) async {
    _currentPosition = tappedLocation;
    locLatitude = tappedLocation.latitude;
    locLongitude = tappedLocation.longitude;

    _markers.clear();
    _markers.add(
      Marker(
        markerId: MarkerId("currentLocation"),
        position: tappedLocation,
      ),
    );

    _mapController?.animateCamera(
      CameraUpdate.newLatLng(tappedLocation),
    );

    try {
      placemarks = await placemarkFromCoordinates(
        tappedLocation.latitude,
        tappedLocation.longitude,
      );

      if (placemarks.isNotEmpty) {
        _updateAddressDetails(placemarks.first);
      }
      if (locLatitude != null && locLongitude != null) {
        await fetchHomePageData(
          latitude: locLatitude!,
          longitude: locLongitude!,
        );
      }
    } catch (e) {
      debugPrint("Error getting placemark: $e");
    }

    notifyListeners();
  }

  void _updateAddressDetails(Placemark place) {
    debugPrint("*************");
    debugPrint("***************************** Place: $place");
    _address =
        "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}, ${place.name}"; // ${place.thoroughfare}, ${place.subLocality},

    if (_address != null && _address!.isNotEmpty) {
      List<String> addressParts = _address!.split(", ");
      if (addressParts.length >= 4) {
        locAddress = addressParts.take(4).join(", ");
        locPincode = addressParts.last;
        locHouse = addressParts[0];
        locLandmark =
            "${addressParts[1]}, ${addressParts[2]}, ${addressParts[3]}";
      }
    }

    debugPrint("Formatted Address: $_address");
    debugPrint("Formatted locLandmark: $locLandmark");
  }

  Future<bool> fetchHomePageData(
      {required double latitude,
      required double longitude,
      bool forceRefresh = false}) async {
    // If we already have home data and not forcing refresh, skip
    if (!forceRefresh && homeData != null) {
      debugPrint("📍 Home data already available, skipping fetch");
      return true;
    }

    isLoading = true;
    notifyListeners();

    try {
      // Validate URL before making request
      final url =
          "${Apis.baseUrl}${Apis.homeApi}?latitude=$latitude&longitude=$longitude";
      debugPrint("Homepage URL: $url");

      // Validate URL format
      try {
        final uri = Uri.parse(url);
        if (uri.host.isEmpty) {
          debugPrint("❌ Invalid URL: No host specified");
          isLoading = false;
          notifyListeners();
          return false;
        }
      } catch (e) {
        debugPrint("❌ Invalid URL format: $url");
        isLoading = false;
        notifyListeners();
        return false;
      }

      final response = await ApiService().getRequest(url);
      debugPrint("Homepage data: $response");

      if (response != null && response["status"] == 1) {
        try {
          // Parse and validate response data
          homeData = HomeDataModel.fromJson(response);
          isLoading = false;
          notifyListeners();
          return true;
        } catch (e, stackTrace) {
          debugPrint("❌ Error parsing homepage data: $e");
          debugPrint("❌ Stack trace: $stackTrace");
          // Keep existing data if parsing fails
          isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        homeData = null;
        isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint("❌ Error fetching homepage data: $e");
      debugPrint("❌ Stack trace: $stackTrace");
      // Don't clear existing data on error, just stop loading
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> getAllRestaurantsApi(
      int? cuisineId, double? latitude, double? longitude) async {
    isLoadingRestaurants = true;
    notifyListeners();

    try {
      final url =
          "${Apis.baseUrl}${Apis.getAllRestaurantsApi}?cuisineId=$cuisineId&latitude=$latitude&longitude=$longitude";
      debugPrint("getkitchens URL: $url");
      final response = await ApiService().getRequest(url);
      debugPrint("getkitchens data: $response");
      if (response != null && response["status"] == 1) {
        allRestaurantsData = AllRestaurentsModel.fromJson(response);
      } else {
        allRestaurantsData = null;
      }
    } catch (e) {
      debugPrint("❌ Error fetching cart data: $e");
      allRestaurantsData = null;
    } finally {
      isLoadingRestaurants = false;
      notifyListeners();
    }
  }

  Future<void> viewRestaurantApi(
      int? restaurantId, double? latitude, double? longitude) async {
    isRestaurentViewLoading = true;
    notifyListeners();

    try {
      final url =
          "${Apis.baseUrl}${Apis.kitchenViewApi}/$restaurantId?latitude=${latitude}&longitude=${longitude}";
      debugPrint("viewRestaurant URL: $url");
      final response = await ApiService().getRequest(url);
      debugPrint("viewRestaurant data: $response");
      if (response != null && response["status"] == 1) {
        restaurantViewModelData = KitchenViewModel.fromJson(response);
        notifyListeners();
      } else {
        restaurantViewModelData = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("❌ Error fetching viewRestaurant data: $e");
    } finally {
      isRestaurentViewLoading = false;
      notifyListeners();
    }
  }

  Future<void> kitchenReviewsApi(int? restaurantId, int? rating) async {
    isKitchenReviewsLoading = true;
    notifyListeners();

    try {
      String ratingQuery = rating != null ? "rating=$rating" : "";
      final url = ratingQuery.isNotEmpty
          ? "${Apis.baseUrl}${Apis.kitchenReviewsApi}/$restaurantId?$ratingQuery"
          : "${Apis.baseUrl}${Apis.kitchenReviewsApi}/$restaurantId";
      debugPrint("kitchenReviews API URL: $url");
      final response = await ApiService().getRequest(url);
      debugPrint("kitchenReviews API data: $response");
      if (response != null && response["status"] == 1) {
        reviewsModelData = ReviewsModel.fromJson(response);
        notifyListeners();
      } else {
        reviewsModelData = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("❌ Error fetching viewRestaurant data: $e");
    } finally {
      isKitchenReviewsLoading = false;
      notifyListeners();
    }
  }

  Future<void> getPopularRestaurantsApi(
      double? latitude, double? longitude) async {
    isLoadingPopularRestaurants = true;
    notifyListeners();

    try {
      final url =
          "${Apis.baseUrl}${Apis.popularRestaurantsApi}?latitude=$latitude&longitude=$longitude";
      debugPrint("getPopularRestaurants URL: $url");
      final response = await ApiService().getRequest(url);
      debugPrint("getPopularRestaurants data: $response");
      if (response != null && response["status"] == 1) {
        popularNearModelData = PopularNearModel.fromJson(response);
        notifyListeners();
      } else {
        popularNearModelData = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching getPopularRestaurants data: $e");
    } finally {
      isLoadingPopularRestaurants = false;
      notifyListeners();
    }
  }

  Future<void> getActiveRestaurantsApi(
      double? latitude, double? longitude) async {
    isLoadingActiveRestaurants = true;
    notifyListeners();

    try {
      final url =
          "${Apis.baseUrl}${Apis.activeRestaurantsApi}?latitude=$latitude&longitude=$longitude";
      debugPrint("getActiveRestaurants URL: $url");
      final response = await ApiService().getRequest(url);
      debugPrint("getActiveRestaurants data: $response");
      if (response != null && response["status"] == 1) {
        activeRestaurantsModelData = ActiveRestaurentModel.fromJson(response);
        notifyListeners();
      } else {
        activeRestaurantsModelData = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching getPopularRestaurants data: $e");
    } finally {
      isLoadingActiveRestaurants = false;
      notifyListeners();
    }
  }

  Future<void> searchRestaurantsApi(String? searchQuery,
      {String? kitchenTypeIds, String? foodTypeIds}) async {
    isLoadingSearch = true;
    notifyListeners();

    try {
      String url = "${Apis.baseUrl}${Apis.searchApi}";
      List<String> queryParams = [];

      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams.add("search=$searchQuery");
      }
      if (kitchenTypeIds != null && kitchenTypeIds.isNotEmpty) {
        queryParams.add("kitchenTypeId=$kitchenTypeIds");
      }
      if (foodTypeIds != null && foodTypeIds.isNotEmpty) {
        queryParams.add("foodtypeId=$foodTypeIds");
      }

      if (queryParams.isNotEmpty) {
        url += "?${queryParams.join("&")}";
      }

      debugPrint("searchRestaurants URL: $url");
      final response = await ApiService().getRequest(url);
      debugPrint("searchRestaurants data: $response");
      if (response != null && response["status"] == 1) {
        searchData = SearchModel.fromJson(response);
        notifyListeners();
      } else {
        searchData = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching getPopularRestaurants data: $e");
    } finally {
      isLoadingSearch = false;
      notifyListeners();
    }
  }

  Future<void> getNotificationsApi({String? readStatus}) async {
    isLoadingNotifications = true;
    notifyListeners();

    try {
      final url = readStatus == "1"
          ? "${Apis.baseUrl}${Apis.getNotificationsApi}?isRead=true"
          : "${Apis.baseUrl}${Apis.getNotificationsApi}";
      debugPrint("getNotifications URL: $url");
      final response = await ApiService().getRequest(url);
      debugPrint("getNotifications data: $response");
      if (response != null && response["status"] == 1) {
        getNotificationsModelData = GetNotificationsModel.fromJson(response);
        notifyListeners();
      } else {
        getNotificationsModelData = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching getPopularR  estaurants data: $e");
    } finally {
      isLoadingNotifications = false;
      notifyListeners();
    }
  }

  Future<void> getFilterDataApi() async {
    isLoadingFilterData = true;
    notifyListeners();

    try {
      final url = "${Apis.baseUrl}${Apis.getFoodTypeApi}";
      debugPrint("filterData URL: $url");
      final response = await ApiService().getRequest(url);
      debugPrint("filterData data: $response");
      if (response != null && response["status"] == 1) {
        filterTypeModelData = FilterTypeModel.fromJson(response);
        notifyListeners();
      } else {
        filterTypeModelData = null;
        notifyListeners();
      }
    } catch (e) {
      filterTypeModelData = null;
      debugPrint("Error fetching getPopularRestaurants data: $e");
    } finally {
      isLoadingFilterData = false;
      notifyListeners();
    }
  }

  // Filter selection logic
  List<int> selectedKitchenIds = [];
  List<int> selectedMenuFoodIds = [];

  void toggleKitchenSelection(int id) {
    if (selectedKitchenIds.contains(id)) {
      selectedKitchenIds.remove(id);
    } else {
      selectedKitchenIds.add(id);
    }
    notifyListeners();
  }

  void toggleMenuFoodSelection(int id) {
    if (selectedMenuFoodIds.contains(id)) {
      selectedMenuFoodIds.remove(id);
    } else {
      selectedMenuFoodIds.add(id);
    }
    notifyListeners();
  }

  void clearFilters() {
    selectedKitchenIds.clear();
    selectedMenuFoodIds.clear();
    notifyListeners();
  }
}
