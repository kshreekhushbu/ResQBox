import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:image_picker/image_picker.dart';
import 'package:resqboxvendor/Services/AppUrls.dart';
import 'package:resqboxvendor/Services/api.dart';
import 'package:resqboxvendor/Services/dynamic_response.dart';
import 'package:resqboxvendor/Utils/shared_preference_helper.dart';
import 'package:resqboxvendor/Utils/toast.dart';
import 'package:intl/intl.dart';

class Timezone {
  final int id;
  final String name;
  final String displayName;
  final String offset;

  Timezone({
    required this.id,
    required this.name,
    required this.displayName,
    required this.offset,
  });

  factory Timezone.fromJson(Map<String, dynamic> json) {
    return Timezone(
      id: json['id'],
      name: json['name'],
      displayName: json['displayName'],
      offset: json['offset'],
    );
  }
}

class FoodType {
  final int id;
  final String name;
  final String? image;
  final int isActive;
  final String? question;

  FoodType({
    required this.id,
    required this.name,
    this.image,
    required this.isActive,
    this.question,
  });

  factory FoodType.fromJson(Map<String, dynamic> json) {
    return FoodType(
      id: json['id'],
      name: json['name'],
      image: json['image'],
      isActive: json['isActive'],
      question: json['question'],
    );
  }
}

class KitchenRegistrationController extends ChangeNotifier {
  // ... existing code ...
  List<Timezone> timezones = [];
  Timezone? selectedTimezone;

  void setSelectedTimezone(Timezone timezone) {
    selectedTimezone = timezone;
    notifyListeners();
  }

  Future<void> getTimezones() async {
    try {
      final url = '${Api.baseUrl}${AppUrls.getActiveTimezones}';
      final res = await ApiService().getRequest(url);

      if (res != null && (res['status'] == 1 || res['Status'] == 1)) {
        if (res['timezones'] != null && res['timezones'] is List) {
          timezones = (res['timezones'] as List)
              .map((e) => Timezone.fromJson(e))
              .toList();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("Error fetching timezones: $e");
    }
  }

  final ImagePicker _picker = ImagePicker();

  // Kitchen Status
  String? registrationStatus;
  String? statusMessage;
  bool isLoadingStatus = false;

  // Cuisines
  List<Cuisine> cuisines = [];
  List<Cuisine> selectedCuisines = [];
  bool isLoadingCuisines = false;

  // Food Types
  List<FoodType> foodTypes = [];
  List<FoodType> selectedFoodTypes = [];
  Map<int, bool> foodTypeAnswers = {}; // ID -> Yes(true)/No(false)
  bool isLoadingFoodTypes = false;
  bool noneOfTheAbove = false;

  void setNoneOfTheAbove(bool value) {
    noneOfTheAbove = value;
    if (value) {
      // Clear other selections
      foodTypeAnswers.clear();
      selectedFoodTypes.clear();
    }
    notifyListeners();
  }

  void setFoodTypeAnswer(FoodType foodType, bool isYes) {
    if (isYes) {
      // Set this one to Yes
      foodTypeAnswers[foodType.id] = true;

      selectedFoodTypes.clear();
      selectedFoodTypes.add(foodType);

      // Set ALL other food types to No
      for (var type in foodTypes) {
        if (type.id != foodType.id) {
          foodTypeAnswers[type.id] = false;
        }
      }

      // Uncheck "None of the Above"
      if (noneOfTheAbove) {
        noneOfTheAbove = false;
      }
    } else {
      // If selecting "No"
      foodTypeAnswers[foodType.id] = false;
      selectedFoodTypes.removeWhere((e) => e.id == foodType.id);
    }
    notifyListeners();
  }

  bool validateFoodTypes() {
    if (foodTypes.isEmpty)
      return true; // Or false if food types are mandatory to exist

    if (noneOfTheAbove) return true;

    if (selectedFoodTypes.isEmpty) {
      customToast(message: "Please select a food type");
      return false;
    }
    return true;
  }

  Future<void> getFoodTypes() async {
    try {
      isLoadingFoodTypes = true;
      await Future.delayed(Duration.zero);
      notifyListeners();

      final url = '${Api.baseUrl}vendor/getFoodTypes';
      debugPrint("📤 Get FoodTypes URL: $url");

      final res = await ApiService().getRequest(url);

      debugPrint("📥 Get FoodTypes Response: $res");

      if (res != null && (res['status'] == 1 || res['Status'] == 1)) {
        final list = res['foodTypes'] as List?;
        if (list != null) {
          foodTypes = list
              .map((item) => FoodType.fromJson(item))
              .where((item) => item.isActive == 1)
              .toList();
          debugPrint("✅ Loaded ${foodTypes.length} food types");
        }
      }
    } catch (e) {
      debugPrint("❌ Error getting food types: $e");
    } finally {
      isLoadingFoodTypes = false;
      notifyListeners();
    }
  }

  void setSelectedCuisines(List<Cuisine> cuisines) {
    selectedCuisines = cuisines;
    notifyListeners();
  }

  // Kitchen Details Controllers
  final TextEditingController kitchenNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController ownerNameController = TextEditingController();
  final TextEditingController contactNumberController = TextEditingController();
  final TextEditingController openingTimeController = TextEditingController();
  final TextEditingController closingTimeController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  // Address Details
  String? houseNo;
  String? street;
  String? landmark;
  String? pincode;
  String? state;
  String? city;
  String? country;
  double? latitude;
  double? longitude;

  // Images
  List<File?> kitchenImages = List.generate(4, (_) => null);
  File? kitchenProfilePhoto;

  // KYC Documents
  final TextEditingController abnNumberController = TextEditingController();
  final TextEditingController acnController = TextEditingController();
  final TextEditingController foodCertificateNumberController =
      TextEditingController();
  final TextEditingController foodCertificateExpireDateController =
      TextEditingController();
  File? foodCertificateImage;

  // Uploaded file names
  List<String> uploadedKitchenImages = [];
  String? uploadedKitchenProfilePhoto;
  String? uploadedFoodCertificateImage;

  // Re-apply Data
  bool isReapplying = false;
  List<String?> existingKitchenImages = List.generate(4, (_) => null);
  String? existingKitchenProfilePhoto;
  String? existingFoodCertificateImage;

  // Config Support Details
  String? supportEmail;
  String? supportNumber;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Pick Kitchen Image
  Future<void> pickKitchenImage(int index) async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (picked != null) {
        kitchenImages[index] = File(picked.path);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("❌ Error picking kitchen image: $e");
      customToast(message: "Failed to pick image");
    }
  }

  // Set Kitchen Image (Manually)
  void setKitchenImage(int index, File file) {
    kitchenImages[index] = file;
    notifyListeners();
  }

  // Pick Kitchen Profile Photo
  Future<void> pickKitchenProfilePhoto() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (picked != null) {
        kitchenProfilePhoto = File(picked.path);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("❌ Error picking kitchen profile photo: $e");
      customToast(message: "Failed to pick image");
    }
  }

  // Set Kitchen Profile Photo (Manually)
  void setKitchenProfilePhoto(File file) {
    kitchenProfilePhoto = file;
    notifyListeners();
  }

  // Pick Food Certificate Image
  Future<void> pickFoodCertificateImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (picked != null) {
        foodCertificateImage = File(picked.path);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("❌ Error picking food certificate image: $e");
      customToast(message: "Failed to pick image");
    }
  }

  // Set Food Certificate Image (Manually)
  void setFoodCertificateImage(File file) {
    foodCertificateImage = file;
    notifyListeners();
  }

  // Upload Multiple Kitchen Images
  Future<bool> uploadKitchenImages() async {
    try {
      final filesToUpload = kitchenImages
          .where((file) => file != null)
          .cast<File>()
          .toList();

      if (filesToUpload.isEmpty) {
        if (isReapplying &&
            existingKitchenImages.any((img) => img != null && img.isNotEmpty)) {
          debugPrint("✅ No new kitchen images to upload, using existing.");
          return true;
        }
        customToast(message: "Please select at least one kitchen image");
        return false;
      }

      EasyLoading.show(status: 'Uploading...');
      final url = '${Api.baseUrl}vendor/uploads';

      final filenames = await ApiService().uploadImages(
        url: url,
        files: filesToUpload,
        folder: "kitchen",
        fieldName: "files",
      );

      if (filenames.isNotEmpty) {
        uploadedKitchenImages = filenames;
        debugPrint("✅ Kitchen images uploaded: $filenames");
        return true;
      } else {
        customToast(message: "Failed to upload kitchen images");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Error uploading kitchen images: $e");
      customToast(message: "Failed to upload kitchen images");
      return false;
    } finally {
      EasyLoading.dismiss();
    }
  }

  // Upload Single Image (for profile photos and KYC)
  Future<String?> uploadSingleImage(File file, String folder) async {
    try {
      // EasyLoading.show();
      final url = '${Api.baseUrl}vendor/upload';

      final result = await ApiService().uploadImage(
        url: url,
        file: file,
        folder: folder,
        fieldName: "file",
      );

      if (result != null && result['fileName'] != null) {
        debugPrint("✅ Image uploaded: ${result['fileName']}");
        return result['fileName'] as String;
      } else {
        customToast(message: "Failed to upload image");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Error uploading image: $e");
      customToast(message: "Failed to upload image");
      return null;
    } finally {
      EasyLoading.dismiss();
    }
  }

  // Upload All Images
  Future<bool> uploadAllImages() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Upload kitchen images (multiple)
      if (!await uploadKitchenImages()) {
        return false;
      }

      // Upload kitchen profile photo
      if (kitchenProfilePhoto != null) {
        final fileName = await uploadSingleImage(
          kitchenProfilePhoto!,
          "kitchen",
        );
        if (fileName == null) return false;
        uploadedKitchenProfilePhoto = fileName;
      }

      // Upload food certificate image
      if (foodCertificateImage != null) {
        final fileName = await uploadSingleImage(foodCertificateImage!, "kyc");
        if (fileName == null) return false;
        uploadedFoodCertificateImage = fileName;
      }

      return true;
    } catch (e) {
      debugPrint("❌ Error uploading all images: $e");
      customToast(message: "Failed to upload images");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Set Address Details
  void setAddressDetails({
    String? houseNo,
    String? street,
    String? landmark,
    String? pincode,
    String? state,
    String? city,
    String? country,
    double? latitude,
    double? longitude,
  }) {
    this.houseNo = houseNo;
    this.street = street;
    this.landmark = landmark;
    this.pincode = pincode;
    this.state = state;
    this.city = city;
    this.country = country;
    this.latitude = latitude;
    this.longitude = longitude;

    // Update address display text
    final addressParts = [
      houseNo,
      street,
      landmark,
      city,
      state,
      pincode,
    ].where((part) => part != null && part.isNotEmpty).toList();

    addressController.text = addressParts.join(", ");
    notifyListeners();
  }

  // Validate Step 1: Kitchen Details
  bool validateKitchenDetails() {
    if (kitchenNameController.text.trim().isEmpty) {
      customToast(message: "Please enter kitchen name");
      return false;
    }
    if (kitchenNameController.text.length > 30) {
      customToast(message: "Kitchen name must be less than 30 characters");
      return false;
    }
    if (emailController.text.trim().isEmpty) {
      customToast(message: "Please enter email");
      return false;
    }
    if (passwordController.text.trim().isEmpty) {
      customToast(message: "Please enter password");
      return false;
    }
    if (passwordController.text.trim().length < 6) {
      customToast(message: "Password must be at least 6 characters");
      return false;
    }
    if (confirmPasswordController.text.trim() !=
        passwordController.text.trim()) {
      customToast(message: "Passwords do not match");
      return false;
    }
    if (ownerNameController.text.trim().isEmpty) {
      customToast(message: "Please enter owner/chef name");
      return false;
    }
    if (RegExp(r'\s{2,}').hasMatch(ownerNameController.text)) {
      customToast(message: "Chef/Owner Name cannot have continuous spaces");
      return false;
    }
    if (selectedCuisines.isEmpty) {
      customToast(message: "Please select at least one restaurant category");
      return false;
    }
    if (descriptionController.text.trim().isEmpty) {
      customToast(message: "Please enter description");
      return false;
    }
    if (RegExp(r'\s{2,}').hasMatch(descriptionController.text)) {
      customToast(message: "Description cannot have continuous spaces");
      return false;
    }
    if (selectedTimezone == null) {
      customToast(message: "Please select a time zone");
      return false;
    }

    if (!validateFoodTypes()) {
      return false;
    }

    return true;
  }

  // Validate Step 2: Contact Details
  bool validateContactDetails() {
    if (contactNumberController.text.trim().isEmpty) {
      customToast(message: "Please enter contact number");
      return false;
    }
    if (openingTimeController.text.trim().isEmpty) {
      customToast(message: "Please select opening time");
      return false;
    }
    if (closingTimeController.text.trim().isEmpty) {
      customToast(message: "Please select closing time");
      return false;
    }
    if (addressController.text.trim().isEmpty ||
        latitude == null ||
        longitude == null) {
      customToast(message: "Please add address");
      return false;
    }
    return true;
  }

  // Validate Step 3: Images
  // Validate Step 3: Images
  bool validateImages() {
    final hasNewKitchenImages = kitchenImages.any((file) => file != null);
    final hasExistingKitchenImages =
        isReapplying &&
        existingKitchenImages.any((img) => img != null && img.isNotEmpty);

    debugPrint("🔍 validating Images:");
    debugPrint("  - hasNewKitchenImages: $hasNewKitchenImages");
    debugPrint("  - hasExistingKitchenImages: $hasExistingKitchenImages");
    debugPrint("  - isReapplying: $isReapplying");
    debugPrint("  - existingKitchenImages: $existingKitchenImages");

    if (!hasNewKitchenImages && !hasExistingKitchenImages) {
      customToast(message: "Please upload at least one kitchen image");
      return false;
    }

    final hasNewProfile = kitchenProfilePhoto != null;
    final hasExistingProfile =
        isReapplying &&
        existingKitchenProfilePhoto != null &&
        existingKitchenProfilePhoto!.isNotEmpty;

    debugPrint("  - hasNewProfile: $hasNewProfile");
    debugPrint("  - hasExistingProfile: $hasExistingProfile");
    debugPrint("  - existingKitchenProfilePhoto: $existingKitchenProfilePhoto");

    if (!hasNewProfile && !hasExistingProfile) {
      customToast(message: "Please upload kitchen profile photo");
      return false;
    }
    return true;
  }

  // Validate Step 4: KYC
  bool validateKYC() {
    final abn = abnNumberController.text.trim();
    if (abn.isEmpty) {
      customToast(message: "Please enter ABN number");
      return false;
    }
    if (!RegExp(r'^[0-9]{11}$').hasMatch(abn)) {
      customToast(message: "ABN number must be 11 numeric digits");
      return false;
    }

    final acn = acnController.text.trim();
    if (acn.isNotEmpty) {
      if (!RegExp(r'^[0-9]{9}$').hasMatch(acn)) {
        customToast(message: "ACN number must be 9 numeric digits");
        return false;
      }
    }
    if (foodCertificateNumberController.text.trim().isEmpty) {
      customToast(message: "Please enter food certificate number");
      return false;
    }
    if (foodCertificateExpireDateController.text.trim().isEmpty) {
      customToast(message: "Please enter expire date");
      return false;
    }

    final hasNewCert = foodCertificateImage != null;
    final hasExistingCert =
        isReapplying &&
        existingFoodCertificateImage != null &&
        existingFoodCertificateImage!.isNotEmpty;

    if (!hasNewCert && !hasExistingCert) {
      customToast(message: "Please upload food certificate image");
      return false;
    }
    return true;
  }

  // Register Kitchen
  Future<bool> registerKitchen() async {
    try {
      EasyLoading.show(status: 'Registering kitchen...');

      // Upload all images first
      if (!await uploadAllImages()) {
        return false;
      }

      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
      } catch (e) {
        debugPrint("⚠️ FCM Token not available: $e");
      }

      debugPrint("🔥 FCM Token: $fcmToken");

      // Format time to HH:mm
      String formatTime(String timeStr) {
        if (timeStr.isEmpty) return "";

        // Normalize string
        timeStr = timeStr.trim().toUpperCase();

        // Check for AM/PM
        bool isPm = timeStr.contains("PM");
        bool isAm = timeStr.contains("AM");

        // Remove AM/PM text
        String cleanTime = timeStr.replaceAll(RegExp(r"[^0-9:]"), "");

        try {
          final parts = cleanTime.split(":");
          if (parts.length >= 2) {
            int hour = int.parse(parts[0]);
            int minute = int.parse(parts[1]);

            if (isPm && hour < 12) hour += 12;
            if (isAm && hour == 12) hour = 0;

            return "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}";
          }
        } catch (e) {
          debugPrint("Error formatting time: $e");
        }
        return timeStr; // Fallback
      }

      // Prepare payload
      final payload = {
        "kitchenDetails": {
          "kitchenName": kitchenNameController.text.trim(),
          "email": emailController.text.trim(),
          "password": passwordController.text.trim(),
          "ownerName": ownerNameController.text.trim(),
          "contactNumber": contactNumberController.text.trim(),
          "openingTime": formatTime(openingTimeController.text.trim()),
          "closingTime": formatTime(closingTimeController.text.trim()),
          "description": descriptionController.text.trim(),
          "deviceToken": fcmToken,
          "cuisineIds": selectedCuisines.map((c) => c.id).toList(),
          "timezoneId": selectedTimezone?.id,
          "foodtypes": noneOfTheAbove
              ? []
              : selectedFoodTypes.map((f) => f.id).toList(),
        },
        "address": {
          "houseNo": houseNo ?? "",
          "street": street ?? "",
          "pincode": pincode ?? "",
          "state": state ?? "",
          "city": city ?? "",
          "country": country ?? "",
          "landmark": landmark ?? "",
          "latitude": latitude ?? 0.0,
          "longitude": longitude ?? 0.0,
        },
        "photos": {
          "kitchenImages": uploadedKitchenImages,
          "kitchenProfilePhoto": uploadedKitchenProfilePhoto ?? "",
        },
        "kyc": {
          "abnNumber": abnNumberController.text.trim(),
          "acn": acnController.text.trim(),
          "foodCertificateNumber": foodCertificateNumberController.text.trim(),
          "foodCertificateImage": uploadedFoodCertificateImage ?? "",
          "expireDate": () {
            try {
              final date = DateFormat(
                'dd-MM-yyyy',
              ).parse(foodCertificateExpireDateController.text.trim());
              return DateFormat('yyyy-MM-dd').format(date);
            } catch (e) {
              return foodCertificateExpireDateController.text.trim();
            }
          }(),
        },
      };

      final url = '${Api.baseUrl}${AppUrls.registerKitchen}';
      debugPrint("📤 Register Kitchen URL: $url");
      debugPrint("📤 Payload: $payload");

      final res = await ApiService().postRequest(url, payload);

      debugPrint("📥 Register Kitchen Response: $res");

      if (res != null && (res['status'] == 1 || res['Status'] == 1)) {
        final token = res['token'];

        if (token != null && token.toString().isNotEmpty) {
          final sharedPrefHelper = await SharedPreferencesHelper.getInstance();
          await sharedPrefHelper.saveString('ApiToken', token);
          debugPrint("✅ Token saved successfully.");
        }

        customToast(message: "Kitchen registered successfully!");
        return true;
      } else {
        customToast(message: res?['message'] ?? "Failed to register kitchen");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Error registering kitchen: $e");
      customToast(message: "Failed to register kitchen");
      return false;
    } finally {
      EasyLoading.dismiss();
    }
  }

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
        final cuisinesList = res['cuisines'] as List?;
        if (cuisinesList != null) {
          cuisines = cuisinesList
              .map((item) => Cuisine.fromJson(item))
              .where((cuisine) => cuisine.isActive == 1)
              .toList();
          debugPrint("✅ Loaded ${cuisines.length} cuisines");
        }
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

  // Get Kitchen Status
  Future<void> getKitchenStatus() async {
    try {
      isLoadingStatus = true;
      await Future.delayed(Duration.zero);
      notifyListeners();

      // EasyLoading.show(status: 'Checking status...');

      final url = '${Api.baseUrl}${AppUrls.getKitchenStatus}';
      debugPrint("📤 Get Kitchen Status URL: $url");

      final res = await ApiService().getRequest(url);

      debugPrint("📥 Get Kitchen Status Response: $res");

      if (res != null && (res['status'] == 1 || res['Status'] == 1)) {
        registrationStatus = res['registrationStatus'];
        statusMessage = res['message'];
      } else {
        customToast(message: res?['message'] ?? "Failed to get kitchen status");
        registrationStatus = null;
        statusMessage = null;
      }
    } catch (e) {
      debugPrint("❌ Error getting kitchen status: $e");
      customToast(message: "Failed to get kitchen status");
      registrationStatus = null;
      statusMessage = null;
    } finally {
      isLoadingStatus = false;
      EasyLoading.dismiss();
      notifyListeners();
    }
  }

  // Get Config
  Future<void> getConfig() async {
    try {
      final url = '${Api.baseUrl}${AppUrls.getConfig}';
      debugPrint("📤 Get Config URL: $url");

      final res = await ApiService().getRequest(url);

      debugPrint("📥 Get Config Response: $res");

      if (res != null && (res['status'] == 1 || res['Status'] == 1)) {
        final configList = res['config'] as List?;
        if (configList != null) {
          for (var item in configList) {
            final key = item['configKey'];
            final value = item['configValue'];
            if (key == "Support Email") {
              supportEmail = value;
            } else if (key == "Support Number") {
              supportNumber = value;
            }
          }
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("❌ Error getting config: $e");
    }
  }

  // Fetch Kitchen Details for Re-apply
  Future<void> fetchKitchenDetails() async {
    try {
      EasyLoading.show();

      final url = '${Api.baseUrl}${AppUrls.getKitchenDetails}';
      debugPrint("📤 Get Kitchen Details URL: $url");

      final res = await ApiService().getRequest(url);

      debugPrint("📥 Get Kitchen Details Response: $res");

      if (res != null && (res['status'] == 1 || res['Status'] == 1)) {
        final kitchen = res['kitchen'];

        if (kitchen == null) {
          customToast(message: "Kitchen data not found");
          return;
        }

        // Address is nested in kitchen based on logs: address: {...}
        final address = kitchen['address'] ?? {};
        final kyc = kitchen['kyc'] ?? {};

        final photos = kitchen['photos'] ?? kitchen;

        // Populate Kitchen Details
        kitchenNameController.text = kitchen['kitchenName'] ?? "";
        emailController.text = kitchen['email'] ?? "";

        ownerNameController.text = kitchen['ownerName'] ?? "";
        contactNumberController.text = kitchen['contactNumber'] ?? "";
        openingTimeController.text = kitchen['openingTime'] ?? "";
        closingTimeController.text = kitchen['closingTime'] ?? "";
        descriptionController.text = kitchen['description'] ?? "";

        // Cuisines (Restaurant Category)
        // Check multiple possible field names: cuisineIds, cuisines, categories, categoryIds
        dynamic cuisineData =
            kitchen['cuisineIds'] ??
            kitchen['cuisines'] ??
            kitchen['categories'] ??
            kitchen['categoryIds'];

        debugPrint("🔍 Raw cuisine data from API: $cuisineData");

        if (cuisineData != null && cuisineData is List) {
          final ids = cuisineData
              .map((e) {
                if (e is Map) {
                  // Try 'id' then 'cuisineId' then 'categoryId'
                  return (e['id'] ?? e['cuisineId'] ?? e['categoryId'])
                          ?.toString() ??
                      "";
                }
                return e.toString();
              })
              .where((id) => id.isNotEmpty)
              .toList();

          debugPrint("🔍 Parsed cuisine IDs: $ids");

          if (cuisines.isEmpty) {
            debugPrint("⏳ Cuisines list empty, fetching master list...");
            await getCuisines();
          }

          selectedCuisines = cuisines
              .where((c) => ids.contains(c.id.toString()))
              .toList();

          debugPrint(
            "✅ Cuisines pre-filled: ${selectedCuisines.map((e) => e.name).toList()}",
          );
        } else if (cuisineData != null) {
          // Handle case where it might be a single ID or object instead of a list
          String? singleId;
          if (cuisineData is Map) {
            singleId =
                (cuisineData['id'] ??
                        cuisineData['cuisineId'] ??
                        cuisineData['categoryId'])
                    ?.toString();
          } else {
            singleId = cuisineData.toString();
          }

          if (singleId != null && singleId.isNotEmpty) {
            if (cuisines.isEmpty) await getCuisines();
            selectedCuisines = cuisines
                .where((c) => c.id.toString() == singleId)
                .toList();
            debugPrint(
              "✅ Single cuisine pre-filled: ${selectedCuisines.map((e) => e.name).toList()}",
            );
          }
        } else {
          debugPrint(
            "⚠️ No cuisine data found in response under any known field name.",
          );
        }

        // Timezone
        if (kitchen['timezoneId'] != null) {
          final tzId = kitchen['timezoneId'].toString();
          if (timezones.isEmpty || timezones.length < 2) {
            // ensure we have the list
            await getTimezones();
          }
          try {
            if (timezones.isNotEmpty) {
              selectedTimezone = timezones.firstWhere(
                (tz) => tz.id.toString() == tzId,
              );
            }
          } catch (e) {
            debugPrint("Warning: Timezone ID $tzId not found in list");
          }
        }

        // Food Types
        if (kitchen['foodtypes'] != null) {
          final foodTypesList = kitchen['foodtypes'] as List;
          // Extract IDs from the list of objects or simple list
          final foodTypeIds = foodTypesList.map((e) {
            if (e is Map) {
              return e['id'].toString();
            }
            return e.toString();
          }).toList();

          if (foodTypes.isEmpty) await getFoodTypes();

          selectedFoodTypes = foodTypes
              .where((f) => foodTypeIds.contains(f.id.toString()))
              .toList();

          // Populate answers map for UI (Radio buttons)
          foodTypeAnswers.clear();
          for (var foodType in foodTypes) {
            // If ID is in selectedFoodTypes, answer is Yes (true), else No (false)
            bool isSelected = foodTypeIds.contains(foodType.id.toString());
            foodTypeAnswers[foodType.id] = isSelected;
          }
        } else {
          // Initialize as all 'No' if not present? Or leave empty?
          // Leaving empty forces user to answer again, which might be safer,
          // but user asked to prefill "as it is".
          // If 'foodtypes' is null in response, we can't prefill.
        }

        // Address
        houseNo = address['houseNo']?.toString();
        street = address['street'];
        pincode = address['pincode']?.toString();
        state = address['state'];
        city = address['city'];
        country = address['country'];
        landmark = address['landmark'];

        // Parse lat/long safely
        if (address['latitude'] != null)
          latitude = double.tryParse(address['latitude'].toString());
        if (address['longitude'] != null)
          longitude = double.tryParse(address['longitude'].toString());

        setAddressDetails(
          houseNo: houseNo,
          street: street,
          landmark: landmark,
          pincode: pincode,
          state: state,
          city: city,
          country: country,
          latitude: latitude,
          longitude: longitude,
        );

        // Images
        List<dynamic>? imgs;
        debugPrint(
          "🔍 Checking for images in photos: ${photos?['kitchenImages']}",
        );
        debugPrint(
          "🔍 Checking for images in kitchen: ${kitchen['kitchenImages']}",
        );

        if (photos != null && photos['kitchenImages'] != null) {
          imgs = photos['kitchenImages'];
        } else if (kitchen['kitchenImages'] != null) {
          imgs = kitchen['kitchenImages'];
        }

        if (imgs != null) {
          debugPrint("✅ Found ${imgs.length} images: $imgs");
          for (int i = 0; i < 4 && i < imgs.length; i++) {
            existingKitchenImages[i] = imgs[i].toString();
          }
        } else {
          debugPrint("❌ No kitchen images found in response");
        }

        debugPrint("📸 Existing Kitchen Images State: $existingKitchenImages");

        existingKitchenProfilePhoto =
            photos['kitchenProfilePhoto'] ?? kitchen['kitchenProfilePhoto'];

        // KYC
        abnNumberController.text = kyc['abnNumber'] ?? "";
        acnController.text = kyc['acn'] ?? "";
        foodCertificateNumberController.text =
            kyc['foodCertificateNumber'] ?? "";
        foodCertificateExpireDateController.text = kyc['expireDate'] ?? "";
        existingFoodCertificateImage = kyc['foodCertificateImage'];

        isReapplying = true;
        notifyListeners();
      } else {
        customToast(message: res?['message'] ?? "Failed to fetch details");
      }
    } catch (e) {
      debugPrint("❌ Error fetching details: $e");
      customToast(message: "Failed to fetch details");
    } finally {
      EasyLoading.dismiss();
    }
  }

  // Re-apply Kitchen
  Future<bool> reapplyKitchen() async {
    try {
      EasyLoading.show(status: 'Re-applying...');

      // Upload new images if any
      if (!await uploadAllImages()) {
        return false;
      }

      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
      } catch (e) {
        // ignore
      }

      // Format time
      String formatTime(String timeStr) {
        if (timeStr.isEmpty) return "";

        // Normalize string
        timeStr = timeStr.trim().toUpperCase();

        // Check for AM/PM
        bool isPm = timeStr.contains("PM");
        bool isAm = timeStr.contains("AM");

        // Remove AM/PM text
        String cleanTime = timeStr.replaceAll(RegExp(r"[^0-9:]"), "");

        try {
          final parts = cleanTime.split(":");
          if (parts.length >= 2) {
            int hour = int.parse(parts[0]);
            int minute = int.parse(parts[1]);

            if (isPm && hour < 12) hour += 12;
            if (isAm && hour == 12) hour = 0;

            return "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}";
          }
        } catch (e) {
          debugPrint("Error formatting time: $e");
        }
        return timeStr; // Fallback
      }

      // Prepare payload
      // Helper function to extract filename from URL
      String extractFilename(String? urlOrFilename) {
        if (urlOrFilename == null || urlOrFilename.isEmpty) return "";
        // If it contains '/', extract the last part (filename)
        if (urlOrFilename.contains('/')) {
          return urlOrFilename.split('/').last;
        }
        // Already a filename
        return urlOrFilename;
      }

      // Use uploaded image if new one exists, else use existing URL
      List<String> finalKitchenImages = [];
      int uploadCounter = 0;
      for (int i = 0; i < 4; i++) {
        if (kitchenImages[i] != null) {
          // New file was selected and uploaded
          if (uploadedKitchenImages.isNotEmpty &&
              uploadCounter < uploadedKitchenImages.length) {
            finalKitchenImages.add(uploadedKitchenImages[uploadCounter]);
            uploadCounter++;
          }
        } else if (existingKitchenImages[i] != null) {
          // No new file, use existing but extract filename from URL
          finalKitchenImages.add(extractFilename(existingKitchenImages[i]));
        }
      }

      final kitchenProfile = (kitchenProfilePhoto != null)
          ? uploadedKitchenProfilePhoto
          : extractFilename(existingKitchenProfilePhoto);
      final certificateImg = (foodCertificateImage != null)
          ? uploadedFoodCertificateImage
          : extractFilename(existingFoodCertificateImage);

      final payload = {
        "kitchenDetails": {
          "kitchenName": kitchenNameController.text.trim(),
          "email": emailController.text.trim(),
          "password": passwordController.text.trim(),
          "ownerName": ownerNameController.text.trim(),
          "contactNumber": contactNumberController.text.trim(),
          "openingTime": formatTime(openingTimeController.text.trim()),
          "closingTime": formatTime(closingTimeController.text.trim()),
          "description": descriptionController.text.trim(),
          "deviceToken": fcmToken,
          "cuisineIds": selectedCuisines.map((c) => c.id).toList(),
          "timezoneId": selectedTimezone?.id,
          "foodtypes": selectedFoodTypes.map((f) => f.id).toList(),
        },
        "address": {
          "houseNo": houseNo ?? "",
          "street": street ?? "",
          "pincode": pincode ?? "",
          "state": state ?? "",
          "city": city ?? "",
          "country": country ?? "",
          "landmark": landmark ?? "",
          "latitude": latitude ?? 0.0,
          "longitude": longitude ?? 0.0,
        },
        "photos": {
          "kitchenImages": finalKitchenImages,
          "kitchenProfilePhoto": kitchenProfile ?? "",
        },
        "kyc": {
          "abnNumber": abnNumberController.text.trim(),
          "acn": acnController.text.trim(),
          "foodCertificateNumber": foodCertificateNumberController.text.trim(),
          "foodCertificateImage": certificateImg ?? "",
          "expireDate": foodCertificateExpireDateController.text.trim(),
        },
      };

      final url = '${Api.baseUrl}${AppUrls.reapplyKitchen}';
      debugPrint("📤 Reapply Kitchen URL: $url");
      debugPrint("📤 Payload: $payload");

      final res = await ApiService().putRequest(
        url,
        payload,
      ); // Using putRequest as implied by PUT

      debugPrint("📥 Reapply Kitchen Response: $res");

      if (res != null && (res['status'] == 1 || res['Status'] == 1)) {
        customToast(message: "Re-application submitted successfully!");
        _clearData();
        return true;
      } else {
        customToast(message: res?['message'] ?? "Failed to re-apply");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Error re-applying: $e");
      customToast(message: "Failed to re-apply");
      return false;
    } finally {
      EasyLoading.dismiss();
    }
  }

  void _clearData() {
    kitchenNameController.clear();
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    ownerNameController.clear();
    contactNumberController.clear();
    openingTimeController.clear();
    closingTimeController.clear();
    descriptionController.clear();
    addressController.clear();
    abnNumberController.clear();
    acnController.clear();
    foodCertificateNumberController.clear();
    foodCertificateExpireDateController.clear();

    selectedCuisines.clear();
    kitchenImages = List.generate(4, (_) => null);
    existingKitchenImages = List.generate(4, (_) => null);
    kitchenProfilePhoto = null;
    existingKitchenProfilePhoto = null;
    foodCertificateImage = null;
    existingFoodCertificateImage = null;

    isReapplying = false;
    notifyListeners();
  }

  // Email validation state
  String? emailValidationMessage;
  bool isCheckingEmail = false;

  // Check if email already exists
  Future<void> checkEmailExists(String email) async {
    if (email.trim().isEmpty) {
      emailValidationMessage = null;
      notifyListeners();
      return;
    }

    // Basic email format validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      emailValidationMessage = null;
      notifyListeners();
      return;
    }

    try {
      isCheckingEmail = true;
      emailValidationMessage = null;
      notifyListeners();

      final url = '${Api.baseUrl}${AppUrls.checkEmailExists}';
      debugPrint("📤 Check Email Exists URL: $url");

      final payload = {"email": email.trim()};
      debugPrint("📤 Payload: $payload");

      final res = await ApiService().postRequest(url, payload);
      debugPrint("📥 Check Email Response: $res");

      if (res != null) {
        if (res['exists'] == true || res['status'] == 0) {
          emailValidationMessage = "❌ Email already exists";
        } else {
          emailValidationMessage = null;
        }
      }
    } catch (e) {
      debugPrint("❌ Error checking email: $e");
      emailValidationMessage = null;
    } finally {
      isCheckingEmail = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    kitchenNameController.dispose();

    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    ownerNameController.dispose();
    contactNumberController.dispose();
    openingTimeController.dispose();
    closingTimeController.dispose();
    descriptionController.dispose();
    addressController.dispose();
    abnNumberController.dispose();
    acnController.dispose();
    foodCertificateNumberController.dispose();
    foodCertificateExpireDateController.dispose();
    super.dispose();
  }

  // Clear all fields when user exits registration
  void clearAllFields() {
    // Clear text controllers
    kitchenNameController.clear();
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    ownerNameController.clear();
    contactNumberController.clear();
    openingTimeController.clear();
    closingTimeController.clear();
    descriptionController.clear();
    addressController.clear();
    abnNumberController.clear();
    acnController.clear();
    foodCertificateNumberController.clear();
    foodCertificateExpireDateController.clear();

    // Clear selections
    selectedCuisines.clear();
    selectedFoodTypes.clear();
    foodTypeAnswers.clear();
    selectedTimezone = null;

    // Clear address details
    houseNo = null;
    street = null;
    landmark = null;
    pincode = null;
    state = null;
    city = null;
    country = null;
    latitude = null;
    longitude = null;

    // Clear images
    kitchenImages = List.generate(4, (_) => null);
    kitchenProfilePhoto = null;
    foodCertificateImage = null;

    // Clear uploaded file names
    uploadedKitchenImages.clear();
    uploadedKitchenProfilePhoto = null;
    uploadedFoodCertificateImage = null;

    // Defer notification to avoid "widget tree locked" errors during dispose
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}

// Cuisine Model
class Cuisine {
  final int id;
  final String name;
  final int isActive;
  final String? image;
  final String? createdAt;
  final String? updatedAt;

  Cuisine({
    required this.id,
    required this.name,
    required this.isActive,
    this.image,
    this.createdAt,
    this.updatedAt,
  });

  factory Cuisine.fromJson(Map<String, dynamic> json) {
    return Cuisine(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      isActive: json['isActive'] ?? 0,
      image: json['image'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }
}
