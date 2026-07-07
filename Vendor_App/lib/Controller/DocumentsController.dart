import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:resqboxvendor/Models/food_certificate_model.dart';
import 'package:resqboxvendor/Services/AppUrls.dart';
import 'package:resqboxvendor/Services/api.dart';
import 'package:resqboxvendor/Services/dynamic_response.dart';
import 'package:resqboxvendor/Utils/toast.dart';
import 'package:intl/intl.dart';

class DocumentsController extends ChangeNotifier {
  final ImagePicker _picker = ImagePicker();

  // Food Certificates
  List<FoodCertificate> foodCertificates = [];
  bool isLoading = false;
  bool isUploading = false;

  // Selected image and date for new certificate
  File? selectedCertificateImage;
  DateTime? selectedExpireDate;

  // Get Food Certificates
  Future<void> getFoodCertificates() async {
    try {
      isLoading = true;
      notifyListeners();

      final url = '${Api.baseUrl}${AppUrls.getFoodCertificates}';
      debugPrint("📤 Get Food Certificates URL: $url");

      final res = await ApiService().getRequest(url);

      debugPrint("📥 Get Food Certificates Response: $res");

      if (res != null && (res['status'] == 1 || res['Status'] == 1)) {
        final response = FoodCertificatesResponse.fromJson(res);
        foodCertificates = response.foodCertificateImages;
        debugPrint("✅ Food certificates loaded: ${foodCertificates.length}");
      } else {
        customToast(message: res?['message'] ?? "Failed to load certificates");
        foodCertificates = [];
      }
    } catch (e) {
      debugPrint("❌ Error getting food certificates: $e");
      customToast(message: "Failed to load certificates");
      foodCertificates = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Pick Certificate Image
  Future<void> pickCertificateImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (picked != null) {
        selectedCertificateImage = File(picked.path);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("❌ Error picking certificate image: $e");
      customToast(message: "Failed to pick image");
    }
  }

  // Set Expire Date
  void setExpireDate(DateTime date) {
    selectedExpireDate = date;
    notifyListeners();
  }

  // Upload Certificate Image
  Future<String?> uploadCertificateImage(File file) async {
    try {
      final url = '${Api.baseUrl}vendor/upload';
      final result = await ApiService().uploadImage(
        url: url,
        file: file,
        folder: "kyc",
        fieldName: "file",
      );

      if (result != null && result['fileName'] != null) {
        debugPrint("✅ Certificate image uploaded: ${result['fileName']}");
        return result['fileName'];
      } else {
        customToast(message: "Failed to upload image");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Error uploading certificate image: $e");
      customToast(message: "Failed to upload image");
      return null;
    }
  }

  // Add Food Certificate
  Future<bool> addFoodCertificate() async {
    try {
      if (selectedCertificateImage == null) {
        customToast(message: "Please select a certificate image");
        return false;
      }

      if (selectedExpireDate == null) {
        customToast(message: "Please select an expiry date");
        return false;
      }

      isUploading = true;
      notifyListeners();

      // First upload the image
      final fileName = await uploadCertificateImage(selectedCertificateImage!);
      if (fileName == null) {
        return false;
      }

      // Format the date as YYYY-MM-DD
      final formattedDate = DateFormat(
        'yyyy-MM-dd',
      ).format(selectedExpireDate!);

      // Then submit the certificate
      final url = '${Api.baseUrl}${AppUrls.addFoodCertificate}';
      debugPrint("📤 Add Food Certificate URL: $url");

      final body = {
        "foodCertificateImage": fileName,
        "expireDate": formattedDate,
      };
      debugPrint("📤 Add Food Certificate Body: $body");

      final res = await ApiService().postRequest(url, body);

      debugPrint("📥 Add Food Certificate Response: $res");

      if (res != null && (res['status'] == 1 || res['Status'] == 1)) {
        customToast(message: "Certificate added successfully");

        // Clear selections
        selectedCertificateImage = null;
        selectedExpireDate = null;

        // Refresh the list
        await getFoodCertificates();

        return true;
      } else {
        customToast(message: res?['message'] ?? "Failed to add certificate");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Error adding food certificate: $e");
      customToast(message: "Failed to add certificate");
      return false;
    } finally {
      isUploading = false;
      notifyListeners();
    }
  }

  // Clear selections
  void clearSelections() {
    selectedCertificateImage = null;
    selectedExpireDate = null;
    notifyListeners();
  }
}
