import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:resqboxvendor/Models/kitchen_details_model.dart';
import 'package:resqboxvendor/Services/AppUrls.dart';
import 'package:resqboxvendor/Services/api.dart';
import 'package:resqboxvendor/Services/dynamic_response.dart';
import 'package:resqboxvendor/Utils/toast.dart';

import 'package:app_links/app_links.dart'; // Import app_links
import 'dart:async'; // Import async
import 'package:resqboxvendor/main.dart'; // Import for navigatorKey
import 'package:resqboxvendor/Screens/Stripe/stripe_webview_screen.dart';

class KitchenProfileController extends ChangeNotifier {
  final ImagePicker _picker = ImagePicker();
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  KitchenProfileController() {
    initDeepLinkListener();
  }

  // Kitchen Details
  Kitchen? kitchenDetails;
  bool isLoadingKitchenDetails = false;
  bool isStripeLoading = false;

  // Kitchen Active Status
  // bool? isKitchenActive;
  bool isLoadingStatus = false;

  // Selected images for upload
  File? selectedKitchenProfilePhoto;
  List<File> selectedKitchenImages = [];

  // Get Kitchen Details
  Future<void> getKitchenDetails() async {
    try {
      isLoadingKitchenDetails = true;
      await Future.delayed(Duration.zero);
      notifyListeners();

      final url = '${Api.baseUrl}${AppUrls.getKitchenDetails}';
      debugPrint("📤 Get Kitchen Details URL: $url");

      final res = await ApiService().getRequest(url);

      debugPrint("📥 Get Kitchen Details Response: $res");

      if (res != null && (res['status'] == 1 || res['Status'] == 1)) {
        final getKitchenDetails = GetKitchenDetails.fromJson(res);
        kitchenDetails = getKitchenDetails.kitchen;

        // Update active status from kitchen details if available
        // Note: The API response doesn't explicitly show isActive,
        // but we can infer from status or other fields if needed

        debugPrint("✅ Kitchen details loaded: ${kitchenDetails?.kitchenName}");
      } else {
        customToast(
          message: res?['message'] ?? "Failed to load kitchen details",
        );
        kitchenDetails = null;
      }
    } catch (e) {
      debugPrint("❌ Error getting kitchen details: $e");
      customToast(message: "Failed to load kitchen details");
      kitchenDetails = null;
    } finally {
      isLoadingKitchenDetails = false;
      notifyListeners();
    }
  }

  Future<bool> updateKitchenActiveStatus(bool isActive) async {
    try {
      isLoadingStatus = true;
      notifyListeners();

      final url =
          '${Api.baseUrl}${AppUrls.updateKitchenActiveStatus}?isActive=${isActive ? 1 : 0}';
      debugPrint("📤 Update Kitchen Active Status URL: $url");

      final res = await ApiService().putRequest(url, {});

      debugPrint("📥 Update Kitchen Active Status Response: $res");

      if (res != null && (res['status'] == 1 || res['Status'] == 1)) {
        // isKitchenActive = isActive;
        getKitchenDetails();
        customToast(
          message: isActive
              ? "Kitchen activated successfully"
              : "Kitchen paused successfully",
        );
        notifyListeners();
        return true;
      } else {
        customToast(
          message: res?['message'] ?? "Failed to update kitchen status",
        );
        return false;
      }
    } catch (e) {
      debugPrint("❌ Error updating kitchen active status: $e");
      customToast(message: "Failed to update kitchen status");
      return false;
    } finally {
      isLoadingStatus = false;
      notifyListeners();
    }
  }

  // Update Notification Time (Buzz Sound Duration)
  Future<bool> updateNotificationTime(int seconds) async {
    try {
      isLoadingStatus = true;
      notifyListeners();

      final url = '${Api.baseUrl}${AppUrls.updateNotificationTime}';
      debugPrint("📤 Update Notification Time URL: $url");

      final body = {"notificationTime": seconds};
      debugPrint("📤 Payload: $body");

      final res = await ApiService().putRequest(url, body);

      debugPrint("📥 Update Notification Time Response: $res");

      if (res != null && (res['status'] == 1 || res['Status'] == 1)) {
        // Refresh kitchen details to get updated value
        await getKitchenDetails();
        customToast(message: "Notification time updated successfully");
        return true;
      } else {
        customToast(
          message: res?['message'] ?? "Failed to update notification time",
        );
        return false;
      }
    } catch (e) {
      debugPrint("❌ Error updating notification time: $e");
      customToast(message: "Failed to update notification time");
      return false;
    } finally {
      isLoadingStatus = false;
      notifyListeners();
    }
  }

  // Update Kitchen - Only sends fields that are provided
  Future<bool> updateKitchen({
    // Kitchen Details
    String? kitchenName,
    String? email,
    String? ownerName,
    String? contactNumber,
    String? openingTime,
    String? closingTime,
    String? description,
    // Address
    String? houseNo,
    String? street,
    String? pincode,
    String? city,
    String? state,
    String? country,
    String? landmark,
    double? latitude,
    double? longitude,
    // Photos
    List<String>? kitchenImages,
    String? kitchenProfilePhoto,
    String? deviceToken,
    int? timezoneId, // Added timezoneId parameter
  }) async {
    try {
      isLoadingKitchenDetails = true;
      notifyListeners();

      // Build payload with only provided fields
      final Map<String, dynamic> payload = {};

      // Kitchen Details
      if (kitchenName != null ||
          email != null ||
          ownerName != null ||
          contactNumber != null ||
          openingTime != null ||
          closingTime != null ||
          description != null ||
          timezoneId != null) {
        // Check timezoneId
        payload['kitchenDetails'] = {};
        if (kitchenName != null) {
          payload['kitchenDetails']['kitchenName'] = kitchenName;
        }
        if (email != null) {
          payload['kitchenDetails']['email'] = email;
        }
        if (ownerName != null) {
          payload['kitchenDetails']['ownerName'] = ownerName;
        }
        if (contactNumber != null) {
          payload['kitchenDetails']['contactNumber'] = contactNumber;
        }
        if (openingTime != null) {
          payload['kitchenDetails']['openingTime'] = openingTime;
        }
        if (closingTime != null) {
          payload['kitchenDetails']['closingTime'] = closingTime;
        }
        if (description != null) {
          payload['kitchenDetails']['description'] = description;
        }
        if (timezoneId != null) {
          payload['kitchenDetails']['timezoneId'] = timezoneId;
        }
      }

      // Address
      if (houseNo != null ||
          street != null ||
          pincode != null ||
          city != null ||
          state != null ||
          country != null ||
          landmark != null ||
          latitude != null ||
          longitude != null) {
        payload['address'] = {};
        if (houseNo != null) {
          payload['address']['houseNo'] = houseNo;
        }
        if (street != null) {
          payload['address']['street'] = street;
        }
        if (pincode != null) {
          payload['address']['pincode'] = pincode;
        }
        if (city != null) {
          payload['address']['city'] = city;
        }
        if (state != null) {
          payload['address']['state'] = state;
        }
        if (country != null) {
          payload['address']['country'] = country;
        }
        if (landmark != null) {
          payload['address']['landmark'] = landmark;
        }
        if (latitude != null) {
          payload['address']['latitude'] = latitude;
        }
        if (longitude != null) {
          payload['address']['longitude'] = longitude;
        }
      }

      // Photos
      if (kitchenImages != null || kitchenProfilePhoto != null) {
        payload['photos'] = {};
        if (kitchenImages != null) {
          payload['photos']['kitchenImages'] = kitchenImages;
        }
        if (kitchenProfilePhoto != null) {
          payload['photos']['kitchenProfilePhoto'] = kitchenProfilePhoto;
        }
      }

      // Device Token
      if (deviceToken != null) {
        payload['deviceToken'] = deviceToken;
      }

      final url = '${Api.baseUrl}${AppUrls.updateKitchen}';
      debugPrint("📤 Update Kitchen URL: $url");
      debugPrint("📤 Update Kitchen Payload: $payload");

      final res = await ApiService().putRequest(url, payload);

      debugPrint("📥 Update Kitchen Response: $res");

      if (res != null && (res['status'] == 1 || res['Status'] == 1)) {
        // Refresh kitchen details after update
        await getKitchenDetails();
        customToast(message: "Kitchen updated successfully");
        return true;
      } else {
        customToast(message: res?['message'] ?? "Failed to update kitchen");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Error updating kitchen: $e");
      customToast(message: "Failed to update kitchen");
      return false;
    } finally {
      isLoadingKitchenDetails = false;
      notifyListeners();
    }
  }

  // Pick Kitchen Profile Photo
  Future<void> pickKitchenProfilePhoto() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (picked != null) {
        selectedKitchenProfilePhoto = File(picked.path);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("❌ Error picking kitchen profile photo: $e");
      customToast(message: "Failed to pick image");
    }
  }

  // Pick Kitchen Images (multiple)
  Future<void> pickKitchenImages() async {
    try {
      final picked = await _picker.pickMultiImage(imageQuality: 80);
      if (picked.isNotEmpty) {
        selectedKitchenImages = picked
            .map((xFile) => File(xFile.path))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("❌ Error picking kitchen images: $e");
      customToast(message: "Failed to pick images");
    }
  }

  // Pick Single Image from Camera
  Future<File?> pickImageFromCamera() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (picked != null) {
        return File(picked.path);
      }
      return null;
    } catch (e) {
      debugPrint("❌ Error picking image from camera: $e");
      customToast(message: "Failed to capture image");
      return null;
    }
  }

  // Upload Single Image
  Future<String?> uploadSingleImage(File file, String folder) async {
    try {
      final url = '${Api.baseUrl}vendor/upload';
      final result = await ApiService().uploadImage(
        url: url,
        file: file,
        folder: folder,
        fieldName: "file",
      );

      if (result != null && result['fileName'] != null) {
        debugPrint("✅ Image uploaded: ${result['fileName']}");
        return result['fileName'];
      } else {
        customToast(message: "Failed to upload image");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Error uploading image: $e");
      customToast(message: "Failed to upload image");
      return null;
    }
  }

  // Upload Multiple Images
  Future<List<String>> uploadMultipleImages(List<File> files) async {
    try {
      final url = '${Api.baseUrl}vendor/uploads';
      final filenames = await ApiService().uploadImages(
        url: url,
        files: files,
        folder: "kitchen",
        fieldName: "files",
      );
      return filenames;
    } catch (e) {
      debugPrint("❌ Error uploading images: $e");
      customToast(message: "Failed to upload images");
      return [];
    }
  }

  // Start Stripe Onboarding
  Future<void> startStripeOnboarding() async {
    try {
      if (kitchenDetails?.kitchenId == null) {
        customToast(message: "Kitchen ID not found");
        return;
      }

      isStripeLoading = true;
      notifyListeners();

      // Step 1: Create Stripe Account
      final createAccountUrl = '${Api.baseUrl}${AppUrls.createStripeAccount}';
      debugPrint("📤 Create Stripe Account URL: $createAccountUrl");

      final accountRes = await ApiService().postRequest(createAccountUrl, {
        "kitchenId": kitchenDetails!.kitchenId,
      });

      debugPrint("📥 Create Stripe Account Response: $accountRes");

      String? accountId;
      if (accountRes != null &&
          (accountRes['status'] == 1 || accountRes['Status'] == 1)) {
        // Handle cases where the key might be differently named
        accountId =
            accountRes['stripeAccountId'] ??
            accountRes['accountId'] ??
            accountRes['account_id'];
      } else if (accountRes != null &&
          (accountRes['stripeAccountId'] != null ||
              accountRes['accountId'] != null)) {
        accountId = accountRes['stripeAccountId'] ?? accountRes['accountId'];
      }

      if (accountId == null) {
        customToast(
          message: accountRes?['message'] ?? "Failed to create Stripe account",
        );
        return;
      }

      // Step 2: Create Account Session
      final sessionUrl = '${Api.baseUrl}${AppUrls.createAccountSession}';
      debugPrint("📤 Create Account Session URL: $sessionUrl");

      final sessionRes = await ApiService().postRequest(sessionUrl, {
        "accountId": accountId,
      });

      debugPrint("📥 Create Account Session Response: $sessionRes");

      String? clientSecret;
      String? urlVal;

      if (sessionRes != null) {
        clientSecret =
            sessionRes['clientSecret'] ?? sessionRes['client_secret'];
        urlVal = sessionRes['url'] ?? sessionRes['onboardingUrl'];
      }

      if (clientSecret == null && urlVal == null) {
        customToast(
          message: sessionRes?['message'] ?? "Failed to create account session",
        );
        return;
      }

      // Step 3: Open WebView
      if (navigatorKey.currentContext != null) {
        await Navigator.push(
          navigatorKey.currentContext!,
          MaterialPageRoute(
            builder: (context) => StripeWebViewScreen(
              clientSecret: clientSecret,
              url: urlVal,
              accountId: accountId,
            ),
          ),
        );
        // Refresh details after coming back
        await getKitchenDetails();
      }
    } catch (e) {
      debugPrint("❌ Error starting Stripe onboarding: $e");
      customToast(message: "Failed to initiate Stripe onboarding");
    } finally {
      isStripeLoading = false;
      notifyListeners();
    }
  }

  // Continue Stripe Onboarding (if URL exists)
  Future<void> continueStripeOnboarding() async {
    // Start fresh onboarding session since we are using embedded flow.
    await startStripeOnboarding();
  }

  // Initialize Deep Link Listener
  void initDeepLinkListener() {
    _appLinks = AppLinks();

    // Check initial link
    _checkInitialLink();

    // Listen for link changes
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        debugPrint("🔗 Received Deep Link: $uri");
        _handleLink(uri);
      },
      onError: (err) {
        debugPrint("❌ Deep Link Error: $err");
      },
    );
  }

  Future<void> _checkInitialLink() async {
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null) {
        debugPrint("🔗 Received Initial Deep Link: $uri");
        _handleLink(uri);
      }
    } catch (e) {
      debugPrint("❌ Error getting initial link: $e");
    }
  }

  void _handleLink(Uri uri) {
    // Check if the link matches your scheme and host/path
    // Scheme: resqboxvendor
    // Host: stripe-callback (optional check depending on Manifest)
    if (uri.scheme == 'resqboxvendor') {
      debugPrint("✅ Handling Stripe Callback");

      // Verify logic: Refresh kitchen details to check if stripeOnboardingCompleted is now true
      getKitchenDetails();

      // Close any open dialog (e.g., StripeOnboardingDialog)
      // Use a delay to ensure the app has fully resumed before popping
      Future.delayed(Duration(milliseconds: 300), () {
        try {
          if (navigatorKey.currentContext != null) {
            final navigator = Navigator.of(navigatorKey.currentContext!);
            if (navigator.canPop()) {
              navigator.pop();
              debugPrint("✅ Dialog closed successfully");
            } else {
              debugPrint("⚠️ No dialog to pop");
            }
          }
        } catch (e) {
          debugPrint("⚠️ Could not pop dialog: $e");
        }
      });

      // Optionally show specific success message if path indicates success
      // e.g., resqboxvendor://stripe-callback?success=true
      if (uri.queryParameters['success'] == 'true' ||
          uri.toString().contains("success")) {
        customToast(message: "Stripe Onboarding Completed!");
      }

      // If you had a dialog open, you might want to close it or update UI state.
      // Since this is a Controller, notifying listeners (in getKitchenDetails) updates the UI.
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  // Sync FCM Token
  Future<void> syncFcmToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        debugPrint("🔄 Syncing FCM Token: $token");
        await updateKitchen(deviceToken: token);
      } else {
        debugPrint("⚠️ FCM Token is null, skipping sync.");
      }
    } catch (e) {
      debugPrint("❌ Error syncing FCM token: $e");
    }
  }

  // Timezones
  List<Timezone> timezones = [];
  Timezone? selectedTimezone;
  bool isLoadingTimezones = false;

  Future<void> getTimezones() async {
    try {
      isLoadingTimezones = true;
      await Future.delayed(Duration.zero);
      notifyListeners();

      final url = '${Api.baseUrl}${AppUrls.getActiveTimezones}';
      debugPrint("📤 Get Timezones URL: $url");

      final res = await ApiService().getRequest(url);
      debugPrint("📥 Get Timezones Response: $res");

      if (res != null && (res['status'] == 1 || res['Status'] == 1)) {
        if (res['timezones'] != null && res['timezones'] is List) {
          timezones = (res['timezones'] as List)
              .map((e) => Timezone.fromJson(e))
              .toList();

          // Prefill selected timezone if we have kitchen details
          if (kitchenDetails?.timezoneId != null && timezones.isNotEmpty) {
            try {
              selectedTimezone = timezones.firstWhere(
                (element) => element.id == kitchenDetails!.timezoneId,
              );
              debugPrint(
                "✅ Prefilled timezone: ${selectedTimezone?.displayName}",
              );
            } catch (e) {
              debugPrint(
                "⚠️ Could not find timezone with ID: ${kitchenDetails!.timezoneId}",
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint("❌ Error getting timezones: $e");
    } finally {
      isLoadingTimezones = false;
      notifyListeners();
    }
  }

  void setSelectedTimezone(Timezone timezone) {
    selectedTimezone = timezone;
    notifyListeners();
  }

  void setSelectedKitchenProfilePhoto(File? file) {
    selectedKitchenProfilePhoto = file;
    notifyListeners();
  }
}

class Timezone {
  int? id;
  String? name;
  String? displayName;
  String? offset;

  Timezone({this.id, this.name, this.displayName, this.offset});

  factory Timezone.fromJson(Map<String, dynamic> json) {
    return Timezone(
      id: json['id'],
      name: json['name'],
      displayName: json['displayName'],
      offset: json['offset'],
    );
  }
}
