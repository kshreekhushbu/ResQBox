import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:resqbox_user/Models/config_details_model.dart';
import 'package:resqbox_user/Screens/Authentication/account_inactive_screen.dart';
import 'package:resqbox_user/Screens/Authentication/otp_bottom_sheet.dart';
import 'package:resqbox_user/Screens/MainSection/bottom_navigation.dart';
import 'package:resqbox_user/Services/apis.dart';
import 'package:resqbox_user/Services/dynamic_response.dart';
import 'package:resqbox_user/Utils/custom_loader.dart';
import 'package:resqbox_user/Utils/navigations.dart';
import 'package:resqbox_user/Utils/notifications.dart';
import 'package:resqbox_user/Utils/shared_preference_helper.dart';
import 'package:resqbox_user/Utils/toast.dart';
import 'package:resqbox_user/main.dart';
import 'package:resqbox_user/Controllers/account_controller.dart';
import 'package:resqbox_user/Controllers/socket_controller.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthenticationController extends ChangeNotifier {
  bool isSupportLoading = false;
  ConfigDetailsModel? supportdata;

  Future<void> _initializeUserSession() async {
    if (navigatorKey.currentContext != null) {
      final accountController = Provider.of<AccountController>(
          navigatorKey.currentContext!,
          listen: false);
      await accountController.getProfileApi();

      final socketController = Provider.of<SocketController>(
          navigatorKey.currentContext!,
          listen: false);
      socketController.initializeSocketConnection();
    }
  }

  void loginApi({
    required Map<String, dynamic> body,
    bool showBottomSheet = true,
  }) async {
    try {
      Loaders.showLoadingDialog();
      notifyListeners();
      String url = Apis.baseUrl + Apis.loginApi;
      var res = await ApiService().authResponse(
        body: body,
        requestType: 'post',
        url: url,
      );
      debugPrint("API URL: $url");
      debugPrint("API Response: $res");
      if (res['status'] == 1) {
        customToast(message: res['message'] ?? 'please try again ');
        Loaders.hideLoadingDialog();
        if (showBottomSheet) {
          OtpBottomSheet.show(
            navigatorKey.currentContext!,
            "",
            email: body['email'],
          );
        }
        notifyListeners();
      } else if (res['status'] == 0) {
        customToast(message: res['message'] ?? 'please try again ');
        Loaders.hideLoadingDialog();
        notifyListeners();
      } else if (res['status'] == 2) {
        Loaders.hideLoadingDialog();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          NavigateTo().nextPage(child: const AccountInactiveScreen());
        });
        notifyListeners();
      }
    } catch (e) {
      Loaders.hideLoadingDialog();
      customToast(message: "please try again");
      notifyListeners();
      debugPrint("eeeeeeeeee $e");
    }
  }

  void signUpVerifyOtpApi({
    required Map<String, dynamic> body,
    required String phoneNumber,
    required String firstName,
    required String lastName,
    required String email,
    required String countryCode,
    bool showBottomSheet = true,
  }) async {
    try {
      Loaders.showLoadingDialog();
      notifyListeners();
      String url = Apis.baseUrl + Apis.signUpVerifyOtpApi;
      var res = await ApiService().authResponse(
        body: body,
        requestType: 'post',
        url: url,
      );
      debugPrint("API URL: $url");
      debugPrint("API Response: $res");
      if (res['status'] == 1) {
        customToast(message: res['message'] ?? 'please try again ');
        Loaders.hideLoadingDialog();
        if (showBottomSheet) {
          OtpBottomSheet.show(
            navigatorKey.currentContext!,
            phoneNumber,
            firstName: firstName,
            lastName: lastName,
            email: email,
            fromScreen: 'signup',
            countryCode: countryCode,
          );
        }
        notifyListeners();
      } else if (res['status'] == 0) {
        customToast(message: res['message'] ?? 'please try again ');
        Loaders.hideLoadingDialog();
        notifyListeners();
      }
    } catch (e) {
      Loaders.hideLoadingDialog();
      customToast(message: "please try again");
      notifyListeners();
      debugPrint("eeeeeeeeee $e");
    }
  }

  Future<bool> foodieVerifyOtp({required Map<String, dynamic> body}) async {
    try {
      Loaders.showLoadingDialog();
      notifyListeners();
      String url = Apis.baseUrl + Apis.verifyOtpApi;
      var res = await ApiService().authResponse(
        body: body,
        requestType: 'post',
        url: url,
      );
      debugPrint("API URL: $url");
      debugPrint("API Response: $res");

      if (res['status'] == 1) {
        SharedPreferencesHelper().saveString('ApiToken', res['token']);
        Loaders.hideLoadingDialog();
        notifyListeners();
        customToast(message: res['message'] ?? 'please try again ');
        await _initializeUserSession();
        NavigateTo().pushRemove(child: const BottomNavigation(initialIndex: 0));
        return true;
      } else {
        customToast(message: res['message'] ?? 'please try again ');
        Loaders.hideLoadingDialog();
        notifyListeners();
        return false;
      }
    } catch (e) {
      Loaders.hideLoadingDialog();
      notifyListeners();
      debugPrint("eeeeeeeeee $e");
      return false;
    }
  }

  void signUpApi({required Map<String, dynamic> body}) async {
    try {
      Loaders.showLoadingDialog();
      notifyListeners();
      String url = Apis.baseUrl + Apis.signupApi;
      var res = await ApiService().authResponse(
        body: body,
        requestType: 'post',
        url: url,
      );
      debugPrint("API URL: $url");
      debugPrint("API Response: $res");
      if (res['status'] == 1) {
        SharedPreferencesHelper().saveString('ApiToken', res['token']);
        Loaders.hideLoadingDialog();
        notifyListeners();
        customToast(message: res['message'] ?? 'please try again ');
        await _initializeUserSession();
        NavigateTo().pushRemove(child: const BottomNavigation(initialIndex: 0));
      } else if (res['status'] == 0) {
        Loaders.hideLoadingDialog();
        notifyListeners();
        customToast(message: res['Message'] ?? 'please try again ');
      }
    } catch (e) {
      Loaders.hideLoadingDialog();
      customToast(message: "please try again");
      notifyListeners();
      debugPrint("eeeeeeeeee $e");
    }
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  Future<void> signInWithApple(BuildContext context) async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(oauthCredential);

      // ✅ THIS is the correct Firebase token
      final firebaseToken = await userCredential.user!.getIdToken();

      await continueWithAppleApi({
        "idToken": firebaseToken, // ✅ Send Firebase token
        "deviceToken": await getFcmToken(),
      });
    } catch (e) {
      print("Apple Sign-In Error: $e");
    }
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint("User cancelled");
        return;
      }

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      print('111111111111111111111111111111111111111111111111');

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      print('222222222222222222222222222222222222222222222222');

      final idToken = await userCredential.user!.getIdToken();

      print('333333333333333333333333333333333333333333333333333333');

      await continueWithGoogleApi({
        "idToken": idToken,
        "deviceToken": await getFcmToken(),
      });
    } catch (e) {
      debugPrint("Google Sign-In Error: $e");
    }
  }

  Future<void> continueWithGoogleApi(Map<String, dynamic> body) async {
    Loaders.showLoadingDialog();
    notifyListeners();
    try {
      final url = "${Apis.baseUrl}${Apis.googleLoginApi}";
      debugPrint("google api messages URL: $url");
      final response = await ApiService().postRequest(url, body);
      debugPrint("google api messages data: $response");
      if (response != null && response["status"] == 1) {
        SharedPreferencesHelper().saveString('ApiToken', response['token']);
        Loaders.hideLoadingDialog();
        customToast(message: response['message'] ?? 'please try again');
        await _initializeUserSession();
        NavigateTo().pushRemove(child: const BottomNavigation(initialIndex: 0));
        notifyListeners();
      } else if (response != null && response["status"] == 2) {
        Loaders.hideLoadingDialog();
        NavigateTo().nextPage(child: const AccountInactiveScreen());
        notifyListeners();
      } else {
        Loaders.hideLoadingDialog();
        customToast(message: response?['message'] ?? 'please try again');
        notifyListeners();
      }
    } catch (e) {
      Loaders.hideLoadingDialog();
      notifyListeners();
      debugPrint("❌ Error fetching data: $e");
    }
  }

  Future<void> continueWithAppleApi(Map<String, dynamic> body) async {
    Loaders.showLoadingDialog();
    notifyListeners();
    try {
      final url = "${Apis.baseUrl}${Apis.appleLoginApi}";
      debugPrint("google api messages URL: $url");
      final response = await ApiService().postRequest(url, body);
      debugPrint("google api messages data: $response");
      if (response != null && response["status"] == 1) {
        SharedPreferencesHelper().saveString('ApiToken', response['token']);
        Loaders.hideLoadingDialog();
        customToast(message: response['message'] ?? 'please try again');
        await _initializeUserSession();
        NavigateTo().pushRemove(child: const BottomNavigation(initialIndex: 0));
        notifyListeners();
      } else {
        Loaders.hideLoadingDialog();
        customToast(message: response['message'] ?? 'please try again');
        notifyListeners();
      }
    } catch (e) {
      Loaders.hideLoadingDialog();
      notifyListeners();
      debugPrint("❌ Error fetching data: $e");
    }
  }

  Future<void> signInWithFacebook(BuildContext context) async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );
      debugPrint("Facebook login result: $result");

      if (result.status == LoginStatus.success) {
        final accessToken = result.accessToken!;
        await continueWithFacebookApi({
          "idToken": accessToken.tokenString,
          "deviceToken": await getFcmToken(),
        });
      } else {
        debugPrint("Facebook login failed: ${result.status}");
        debugPrint(result.message);
      }
    } catch (e) {
      debugPrint("Facebook Sign-In Error: $e");
    }
  }

  Future<void> continueWithFacebookApi(Map<String, dynamic> body) async {
    Loaders.showLoadingDialog();
    notifyListeners();
    try {
      final url = "${Apis.baseUrl}${Apis.facebookLoginApi}";
      debugPrint("facebook api messages URL: $url");
      final response = await ApiService().postRequest(url, body);
      debugPrint("facebook api messages data: $response");
      if (response != null && response["status"] == 1) {
        SharedPreferencesHelper().saveString('ApiToken', response['token']);
        Loaders.hideLoadingDialog();
        customToast(message: response['message'] ?? 'please try again');
        await _initializeUserSession();
        NavigateTo().pushRemove(child: const BottomNavigation(initialIndex: 0));
        notifyListeners();
      } else if (response != null && response["status"] == 2) {
        Loaders.hideLoadingDialog();
        NavigateTo().nextPage(child: const AccountInactiveScreen());
        notifyListeners();
      } else {
        Loaders.hideLoadingDialog();
        customToast(message: response?['message'] ?? 'please try again');
        notifyListeners();
      }
    } catch (e) {
      Loaders.hideLoadingDialog();
      notifyListeners();
      debugPrint("❌ Error fetching data: $e");
    }
  }

  Future<void> getSupportDetails() async {
    isSupportLoading = true;
    notifyListeners();

    try {
      final url = "${Apis.baseUrl}${Apis.getSupportDetailsApi}";
      debugPrint("menuView URL: $url");
      final response = await ApiService().getRequest(url);
      debugPrint("menuView data: $response");
      if (response != null && response["status"] == 1) {
        supportdata = ConfigDetailsModel.fromJson(response);
        isSupportLoading = false;
        notifyListeners();
      } else {
        supportdata = null;
        isSupportLoading = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("❌ Error fetching menu view data: $e");
      isSupportLoading = false;
      notifyListeners();
    }
  }
}
