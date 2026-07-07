import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:resqboxvendor/Services/AppUrls.dart';
import 'package:resqboxvendor/Services/api.dart';
import 'package:resqboxvendor/Services/dynamic_response.dart';
import 'package:resqboxvendor/Utils/shared_preference_helper.dart';
import 'package:resqboxvendor/Utils/toast.dart';

class AuthController extends ChangeNotifier {
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();

  Future<Map<String, dynamic>?> login() async {
    try {
      EasyLoading.show();
      notifyListeners();

      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
      } catch (e) {
        debugPrint("⚠️ FCM Token not available: $e");
      }

      debugPrint("🔥 FCM Token: $fcmToken");

      final url = '${Api.baseUrl}${AppUrls.loginKitchen}';
      final payload = {
        "email": email.text,
        "password": password.text,
        "deviceToken": fcmToken,
      };

      debugPrint("📤 Login URL: $url");
      debugPrint("📤 Payload: $payload");

      final res = await ApiService().postRequest(url, payload);

      debugPrint("📥 Login Response: $res");

      if (res != null && (res['status'] == 1 || res['Status'] == 1)) {
        final token = res['token'];
        final isExist = res['isExist'];
        final isTeamMember = res['isTeamMember'] ?? false;
        final teamMemberId = res['teamMemberId'];

        if (token != null && token.toString().isNotEmpty) {
          final sharedPrefHelper = await SharedPreferencesHelper.getInstance();
          await sharedPrefHelper.saveString('ApiToken', token);

          // Save team member status
          await sharedPrefHelper.saveBool('isTeamMember', isTeamMember);
          if (teamMemberId != null) {
            await sharedPrefHelper.saveInt('teamMemberId', teamMemberId);
          }

          debugPrint("✅ Token saved successfully.");
          debugPrint("✅ Team Member Status: $isTeamMember");
        }

        customToast(message: "Login Successful");
        return {"success": true, "isExist": isExist};
      } else {
        customToast(message: res?['message'] ?? "Invalid credentials");
        return {"success": false};
      }
    } catch (e) {
      debugPrint("❌ Error logging in: $e");
      customToast(message: "Error logging in");
      return {"success": false};
    } finally {
      EasyLoading.dismiss();
      notifyListeners();
    }
  }

  // Forgot Password - Step 1: Send OTP
  Future<Map<String, dynamic>?> sendForgotPasswordOTP(String email) async {
    try {
      EasyLoading.show();
      notifyListeners();

      final url = '${Api.baseUrl}${AppUrls.sendForgotPasswordOTP}';
      final payload = {"email": email};

      debugPrint("📤 Send OTP URL: $url");
      debugPrint("📤 Payload: $payload");

      final res = await ApiService().postRequest(url, payload);

      debugPrint("📥 Send OTP Response: $res");

      if (res != null && (res['status'] == 1 || res['Status'] == 1)) {
        customToast(message: res['message'] ?? "OTP sent successfully");
        return {"success": true};
      } else {
        customToast(message: res?['message'] ?? "Failed to send OTP");
        return {"success": false};
      }
    } catch (e) {
      debugPrint("❌ Error sending OTP: $e");
      customToast(message: "Error sending OTP");
      return {"success": false};
    } finally {
      EasyLoading.dismiss();
      notifyListeners();
    }
  }

  // Forgot Password - Step 2: Verify OTP
  Future<Map<String, dynamic>?> verifyForgotPasswordOTP(
    String email,
    String otp,
  ) async {
    try {
      EasyLoading.show();
      notifyListeners();

      final url = '${Api.baseUrl}${AppUrls.verifyForgotPasswordOTP}';
      final payload = {"email": email, "otp": otp};

      debugPrint("📤 Verify OTP URL: $url");
      debugPrint("📤 Payload: $payload");

      final res = await ApiService().postRequest(url, payload);

      debugPrint("📥 Verify OTP Response: $res");

      if (res != null && (res['status'] == 1 || res['Status'] == 1)) {
        customToast(message: res['message'] ?? "OTP verified successfully");
        return {"success": true};
      } else {
        customToast(message: res?['message'] ?? "Invalid OTP");
        return {"success": false};
      }
    } catch (e) {
      debugPrint("❌ Error verifying OTP: $e");
      customToast(message: "Error verifying OTP");
      return {"success": false};
    } finally {
      EasyLoading.dismiss();
      notifyListeners();
    }
  }

  // Forgot Password - Step 3: Reset Password
  Future<Map<String, dynamic>?> resetPassword(
    String email,
    String newPassword,
  ) async {
    try {
      EasyLoading.show();
      notifyListeners();

      final url = '${Api.baseUrl}${AppUrls.resetPassword}';
      final payload = {"email": email, "newPassword": newPassword};

      debugPrint("📤 Reset Password URL: $url");
      debugPrint("📤 Payload: $payload");

      final res = await ApiService().postRequest(url, payload);

      debugPrint("📥 Reset Password Response: $res");

      if (res != null && (res['status'] == 1 || res['Status'] == 1)) {
        customToast(message: res['message'] ?? "Password reset successfully");
        return {"success": true};
      } else {
        customToast(message: res?['message'] ?? "Failed to reset password");
        return {"success": false};
      }
    } catch (e) {
      debugPrint("❌ Error resetting password: $e");
      customToast(message: "Error resetting password");
      return {"success": false};
    } finally {
      EasyLoading.dismiss();
      notifyListeners();
    }
  }

  // Reset Old Password
  Future<Map<String, dynamic>?> resetOldPassword(
    String oldPassword,
    String newPassword,
  ) async {
    try {
      EasyLoading.show();
      notifyListeners();

      final url = '${Api.baseUrl}${AppUrls.resetOldPassword}';
      final payload = {"oldPassword": oldPassword, "newPassword": newPassword};

      debugPrint("📤 Reset Old Password URL: $url");
      debugPrint("📤 Payload: $payload");

      final res = await ApiService().postRequest(url, payload);

      debugPrint("📥 Reset Old Password Response: $res");

      if (res != null && (res['status'] == 1 || res['Status'] == 1)) {
        customToast(message: res['message'] ?? "Password changed successfully");
        return {"success": true};
      } else {
        customToast(message: res?['message'] ?? "Failed to change password");
        return {"success": false};
      }
    } catch (e) {
      debugPrint("❌ Error resetting old password: $e");
      customToast(message: "Error resetting old password");
      return {"success": false};
    } finally {
      EasyLoading.dismiss();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  // Logout
  Future<void> logout(BuildContext context) async {
    try {
      EasyLoading.show(status: 'Logging out...');

      // Get Device Token
      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
      } catch (e) {
        debugPrint("⚠️ FCM Token not available: $e");
      }

      final url = '${Api.baseUrl}${AppUrls.logoutKitchen}';
      final payload = {"deviceToken": fcmToken ?? ""};

      debugPrint("📤 Logout URL: $url");
      debugPrint("📤 Payload: $payload");

      // We proceed with local logout regardless of API success
      try {
        final res = await ApiService().postRequest(url, payload);
        debugPrint("📥 Logout Response: $res");
      } catch (e) {
        debugPrint("⚠️ Error calling logout API: $e");
      }
    } catch (e) {
      debugPrint("❌ Error in logout process: $e");
    } finally {
      EasyLoading.dismiss();

      // Clear local data
      final sharedPrefHelper = await SharedPreferencesHelper.getInstance();
      await sharedPrefHelper.clearAlldata();

      // Navigate to Login
      // Using context to pushAndRemoveUntil might be safer if available,
      // but NavigateTo uses navigatorKey which is also fine.
      // We need to import LoginScreen first.

      // Since LoginScreen is not imported here and might cause circular dependency if AuthController is used in LoginScreen
      // We will handle navigation in the UI or use the route name if possible.
      // But NavigateTo().pushRemove(child: LoginScreen()) is standard here.
    }
  }
}
