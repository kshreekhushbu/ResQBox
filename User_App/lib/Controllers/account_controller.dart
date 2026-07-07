import 'dart:io';

import 'package:flutter/material.dart';
import 'package:resqbox_user/Models/support_chat_model.dart';
import 'package:resqbox_user/Models/user_details_model.dart';
import 'package:resqbox_user/Models/wishlist_model.dart';
import 'package:resqbox_user/Screens/Authentication/login_screen.dart';
import 'package:resqbox_user/Services/apis.dart';
import 'package:resqbox_user/Services/dynamic_response.dart';
import 'package:resqbox_user/Utils/custom_loader.dart';
import 'package:resqbox_user/Utils/navigations.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:resqbox_user/Utils/shared_preference_helper.dart';
import 'package:resqbox_user/Utils/toast.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:resqbox_user/Models/saved_card_model.dart';

class AccountController extends ChangeNotifier {
  bool isLoading = false;
  bool isLoadingWishlist = false;
  bool isSupport = false;
  bool isLoadingSupportMessage = false;
  bool isLoadingCards = false;
  UserDetailsModel? userDetailsData;
  WishlistModel? wishlistData;
  SupportChatModel? supportChatData;
  SavedCardModel? savedCardsData;

  Future<void> getProfileApi() async {
    isLoading = true;
    notifyListeners();

    try {
      final url = "${Apis.baseUrl}${Apis.profileApi}";
      debugPrint("categories URL: $url");
      final response = await ApiService().getRequest(url);
      debugPrint("categories data: $response");
      if (response != null && response["status"] == 1) {
        isLoading = false;
        userDetailsData = UserDetailsModel.fromJson(response);
        notifyListeners();
      } else {
        isLoading = false;
        userDetailsData = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("❌ Error fetching categories data: $e");
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfileApi({required Map<String, dynamic> body}) async {
    Loaders.showLoadingDialog();
    notifyListeners();

    try {
      final url = "${Apis.baseUrl}${Apis.updateProfileApi}";
      debugPrint("profile URL: $url");
      final response = await ApiService().postRequest(url, body);
      debugPrint("profile data: $response");
      if (response != null && response["status"] == 1) {
        await getProfileApi();
        Loaders.hideLoadingDialog();
        customToast(
            message: response["message"] ?? "Profile updated successfully");
        NavigateTo().backPage();
        notifyListeners();
      } else {
        Loaders.hideLoadingDialog();
        customToast(message: response["message"] ?? "Failed to update profile");
        notifyListeners();
      }
    } catch (e) {
      debugPrint("❌ Error fetching profile data: $e");
      Loaders.hideLoadingDialog();
      notifyListeners();
    }
  }

  // Compress image before uploading
  Future<File?> _compressImage(File imageFile) async {
    try {
      final originalSize = imageFile.lengthSync();
      debugPrint("Original image size: $originalSize bytes");

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final targetPath = path.join(
        tempDir.path,
        '${DateTime.now().millisecondsSinceEpoch}_compressed${path.extension(imageFile.path)}',
      );

      // Compress image
      final compressedXFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: 85, // Quality between 0-100 (85 is a good balance)
        minWidth: 1920, // Max width
        minHeight: 1920, // Max height
      );

      if (compressedXFile != null) {
        // Convert XFile to File
        final compressedFile = File(compressedXFile.path);
        final compressedSize = compressedFile.lengthSync();
        debugPrint("Compressed image size: $compressedSize bytes");
        final reduction = ((originalSize - compressedSize) / originalSize * 100)
            .toStringAsFixed(1);
        debugPrint("Image compressed: $reduction% reduction");
        return compressedFile;
      } else {
        debugPrint("Compression failed, using original image");
        return imageFile;
      }
    } catch (e) {
      debugPrint("Error compressing image: $e");
      // Return original file if compression fails
      return imageFile;
    }
  }

  Future<String?> uploadImage(File imageFile, {String? folderName}) async {
    try {
      debugPrint("imageFile........ $imageFile");

      // Compress image before uploading
      File? fileToUpload = await _compressImage(imageFile);
      if (fileToUpload == null) {
        fileToUpload = imageFile; // Fallback to original if compression fails
      }

      String uploadUrl = "${Apis.baseUrl}${Apis.uploadImage}";

      var response = await ApiService().uploadFile(
        url: uploadUrl,
        file: fileToUpload,
        folderName: folderName ?? "users",
      );

      // Clean up compressed file if it's different from original
      if (fileToUpload.path != imageFile.path) {
        try {
          await fileToUpload.delete();
        } catch (e) {
          debugPrint("Error deleting compressed file: $e");
        }
      }

      if (response != null && response is Map<String, dynamic>) {
        String? imageUrl =
            folderName == "chat" ? response['fileUrl'] : response['fileName'];
        debugPrint("Upload successful! Image URL: $imageUrl");
        return imageUrl;
      } else {
        return null;
      }
    } catch (e) {
      debugPrint("Error uploading image: $e");
      return null;
    }
  }

  Future<void> getWishlistApi() async {
    isLoadingWishlist = true;
    notifyListeners();

    try {
      final url = "${Apis.baseUrl}${Apis.getWishlistApi}";
      debugPrint("wishlist URL: $url");
      final response = await ApiService().getRequest(url);
      debugPrint("wishlist data: $response");
      if (response != null && response["status"] == 1) {
        isLoadingWishlist = false;
        wishlistData = WishlistModel.fromJson(response);
        notifyListeners();
      } else {
        isLoadingWishlist = false;
        wishlistData = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("❌ Error fetching categories data: $e");
      isLoadingWishlist = false;
      notifyListeners();
    }
  }

  Future<bool> addToWishlistApi({required Map<String, dynamic> body}) async {
    Loaders.showLoadingDialog();
    notifyListeners();

    try {
      final url = "${Apis.baseUrl}${Apis.addToWishlistApi}";
      debugPrint("wishlist URL: $url");
      final response = await ApiService().postRequest(url, body);
      debugPrint("wishlist data: $response");
      if (response != null && response["status"] == 1) {
        Loaders.hideLoadingDialog();
        await getWishlistApi();
        customToast(
            message:
                response["message"] ?? "Item added to wishlist successfully");

        notifyListeners();
        return true;
      } else {
        Loaders.hideLoadingDialog();
        customToast(
            message: response["message"] ?? "Failed to add item to wishlist");
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint("❌ Error adding to wishlist: $e");
      Loaders.hideLoadingDialog();
      customToast(message: "Failed to add item to wishlist");
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeFromWishlistApi(int? kitchenId) async {
    Loaders.showLoadingDialog();
    notifyListeners();

    try {
      final url = "${Apis.baseUrl}${Apis.removeFromWishlistApi}/$kitchenId";
      debugPrint("wishlist URL: $url");
      final response = await ApiService().postRequest(url, {});
      debugPrint("wishlist data: $response");
      if (response != null && response["status"] == 1) {
        Loaders.hideLoadingDialog();
        await getWishlistApi();
        customToast(
            message: response["message"] ??
                "Item removed from wishlist successfully");
        notifyListeners();
        return true;
      } else {
        Loaders.hideLoadingDialog();
        customToast(
            message:
                response["message"] ?? "Failed to remove item from wishlist");
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint("❌ Error removing from wishlist: $e");
      Loaders.hideLoadingDialog();
      customToast(message: "Failed to remove item from wishlist");
      notifyListeners();
      return false;
    }
  }

  Future<void> getSupportMessages() async {
    isSupport = true;
    notifyListeners();

    try {
      final url = "${Apis.baseUrl}${Apis.sendSupportMessageApi}";
      debugPrint("support messages URL: $url");
      final response = await ApiService().getRequest(url);
      debugPrint("support messages data: $response");
      if (response != null && response["status"] == 1) {
        isSupport = false;
        supportChatData = SupportChatModel.fromJson(response);
        notifyListeners();
      } else {
        isSupport = false;
        supportChatData = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("❌ Error fetching categories data: $e");
      isSupport = false;
      notifyListeners();
    }
  }

  Future<void> deleteAccountApi({required String reasonText}) async {
    Loaders.showLoadingDialog();
    notifyListeners();

    try {
      final url = "${Apis.baseUrl}${Apis.deleteAccountApi}";
      debugPrint("delete account URL: $url");
      final response =
          await ApiService().postRequest(url, {"reasonText": reasonText});
      debugPrint("delete account data: $response");
      if (response != null && response["status"] == 1) {
        Loaders.hideLoadingDialog();
        customToast(
            message: response["message"] ?? "Account deleted successfully");
        SharedPreferencesHelper().remove("ApiToken");
        SharedPreferencesHelper().clearAlldata();
        NavigateTo().pushRemove(child: LoginScreen());
        notifyListeners();
      } else {
        Loaders.hideLoadingDialog();
        customToast(message: response["message"] ?? "Failed to delete account");
        notifyListeners();
      }
    } catch (e) {
      debugPrint("❌ Error deleting account: $e");
      Loaders.hideLoadingDialog();
      notifyListeners();
    }
  }

  Future<void> sendSupportMessageApi(
      {required Map<String, dynamic> body}) async {
    isLoadingSupportMessage = true;
    notifyListeners();

    // Initialize supportChatData if it's null (e.g., first message in new chat)
    if (supportChatData == null) {
      supportChatData = SupportChatModel(
        messages: [],
        roomStatus: "OPEN", // Optimistically set to OPEN
      );
    } else {
      // If data exists but room is closed, optimistically open it
      if (supportChatData!.roomStatus?.toUpperCase() == "CLOSED") {
        supportChatData!.roomStatus = "OPEN";
      }
    }

    // Optimistically add message to UI immediately
    final tempMessage = Message(
      messageId: null, // Will be updated from server response
      roomId: supportChatData?.roomId,
      senderRole: "USER",
      senderId: userDetailsData?.user?.userId,
      message: body['message'],
      image: body['image'],
      createdAt: DateTime.now(),
    );

    // Add to messages list
    supportChatData!.messages ??= [];
    supportChatData!.messages!.add(tempMessage);
    isLoadingSupportMessage = false;
    notifyListeners();

    try {
      final url = "${Apis.baseUrl}${Apis.sendSupport}";
      debugPrint("📤 sendSupportMessage URL: $url");
      debugPrint("📤 sendSupportMessage body: $body");
      final response = await ApiService().postRequest(url, body);
      debugPrint("📥 sendSupportMessage response: $response");
      if (response != null && response["status"] == 1) {
        // Replace optimistic message with actual message from response
        if (supportChatData != null &&
            supportChatData!.messages != null &&
            supportChatData!.messages!.isNotEmpty &&
            response["data"] != null) {
          // Remove the last optimistic message
          supportChatData!.messages!.removeLast();

          // Add the actual message from response using fromJson
          final messageData = response["data"];
          final actualMessage = Message.fromJson(messageData);

          supportChatData!.messages!.add(actualMessage);
        }

        isLoadingSupportMessage = false;
        // customToast(
        //     message: response["message"] ?? "Message sent successfully");
        notifyListeners();
      } else {
        // Remove the optimistic message if API call failed
        if (supportChatData != null && supportChatData!.messages != null) {
          supportChatData!.messages!.removeLast();
        }
        isLoadingSupportMessage = false;
        customToast(message: response["message"] ?? "Failed to send message");
        notifyListeners();
      }
    } catch (e) {
      debugPrint("❌ Error sending support message: $e");
      // Remove the optimistic message if API call failed
      if (supportChatData != null && supportChatData!.messages != null) {
        supportChatData!.messages!.removeLast();
      }
      isLoadingSupportMessage = false;
      customToast(message: "Failed to send message. Please try again.");
      notifyListeners();
    }
  }

  /// Add incoming message from socket to the messages list
  void addIncomingSocketMessage(Map<String, dynamic> messageData) {
    try {
      if (supportChatData == null) {
        debugPrint("⚠️ supportChatData is null, cannot add socket message");
        return;
      }

      supportChatData!.messages ??= [];

      // Parse the message data
      final incomingMessage = Message.fromJson(messageData);

      // Check if message already exists (by messageId) to avoid duplicates
      final messageId = incomingMessage.messageId;
      if (messageId != null) {
        final exists = supportChatData!.messages!.any(
          (msg) => msg.messageId == messageId,
        );
        if (exists) {
          debugPrint("⚠️ Message with ID $messageId already exists, skipping");
          return;
        }
      }

      // Add the new message
      supportChatData!.messages!.add(incomingMessage);
      debugPrint(
          "✅ Added socket message to list: ${incomingMessage.messageId}");
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Error adding socket message: $e");
    }
  }

  Future<void> getSavedCardsApi() async {
    isLoadingCards = true;
    notifyListeners();

    try {
      final url = "${Apis.baseUrl}${Apis.getSavedCardsApi}";
      debugPrint("getSavedCards URL: $url");
      final response = await ApiService().getRequest(url);
      debugPrint("getSavedCards response: $response");
      if (response != null && response["status"] == 1) {
        savedCardsData = SavedCardModel.fromJson(response);
      } else {
        savedCardsData = null;
      }
    } catch (e) {
      debugPrint("❌ Error fetching saved cards: $e");
      savedCardsData = null;
    } finally {
      isLoadingCards = false;
      notifyListeners();
    }
  }

  Future<void> deleteCardApi(String cardId) async {
    Loaders.showLoadingDialog();

    try {
      final url = "${Apis.baseUrl}${Apis.deleteSavedCardApi}/$cardId";
      debugPrint("deleteCard URL: $url");
      final response = await ApiService().deleteRequest(url);
      debugPrint("deleteCard response: $response");
      if (response != null && response["status"] == 1) {
        customToast(
            message: response["message"] ?? "Card deleted successfully");
        await getSavedCardsApi();
      } else {
        customToast(message: response["message"] ?? "Failed to delete card");
      }
    } catch (e) {
      debugPrint("❌ Error deleting card: $e");
      customToast(message: "Error deleting card");
    } finally {
      Loaders.hideLoadingDialog();
    }
  }

  Future<void> initAddCardFlow() async {
    Loaders.showLoadingDialog();

    try {
      // 1. Create Setup Intent
      final url = "${Apis.baseUrl}${Apis.createPaymentIntentApi}";
      debugPrint("createSetupIntent URL: $url");
      final response = await ApiService().postRequest(url, {});
      debugPrint("createSetupIntent response: $response");

      if (response != null && response["status"] == 1) {
        final clientSecret = response['data']["clientSecret"];
        final customerId = response['data']["setupIntentId"] ??
            response['data']["setupIntentId"];

        if (clientSecret == null) {
          Loaders.hideLoadingDialog();
          customToast(message: "Failed to initialize card setup");
          return;
        }

        // 2. Initialize Payment Sheet for Setup Intent
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            setupIntentClientSecret: clientSecret,
            merchantDisplayName: 'ResQBox Food',
            customerId: customerId,
            style: ThemeMode.system,
          ),
        );

        Loaders.hideLoadingDialog();

        // 3. Present Payment Sheet
        await Stripe.instance.presentPaymentSheet();

        // 4. Retrieve SetupIntent to get paymentMethodId
        final setupIntent =
            await Stripe.instance.retrieveSetupIntent(clientSecret);
        final paymentMethodId = setupIntent.paymentMethodId;

        debugPrint(
            "✅ SetupIntent confirmed, PaymentMethod ID: $paymentMethodId");

        // 5. Confirm to backend
        await _confirmSavedCardBackend({
          "paymentMethodId": paymentMethodId,
          "setAsDefault": true,
        });
      } else {
        Loaders.hideLoadingDialog();
        customToast(
            message: response["message"] ?? "Failed to initialize card setup");
      }
    } catch (e) {
      Loaders.hideLoadingDialog();
      debugPrint("❌ Error in add card flow: $e");
      if (e is StripeException) {
        debugPrint("Stripe Error: ${e.error.localizedMessage}");
        if (e.error.code != FailureCode.Canceled) {
          customToast(message: e.error.localizedMessage ?? "Payment failed");
        }
      } else {
        customToast(message: "An unexpected error occurred");
      }
    }
  }

  Future<void> _confirmSavedCardBackend(Map<String, dynamic> body) async {
    Loaders.showLoadingDialog();
    try {
      final url = "${Apis.baseUrl}${Apis.saveCardApi}";
      debugPrint("confirmSavedCard URL: $url");
      final response = await ApiService().postRequest(url, body);
      debugPrint("confirmSavedCard response: $response");
      if (response != null && response["status"] == 1) {
        customToast(message: response["message"] ?? "Card saved successfully");
        await getSavedCardsApi();
      } else {
        customToast(
            message: response["message"] ?? "Failed to confirm card saving");
      }
    } catch (e) {
      debugPrint("❌ Error confirming card: $e");
    } finally {
      Loaders.hideLoadingDialog();
    }
  }
}
