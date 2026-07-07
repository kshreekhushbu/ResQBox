import 'dart:developer';
// import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_native_splash/flutter_native_splash.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:tejpandit/app/features/auth/screens/login_screen.dart';
// import '../app/features/auth/data/data_source/location_local_data_source.dart';
// import '../app/features/auth/screens/language_screen.dart';
// import '../app/features/feeds/screens/root_screen.dart';
// import '../app/services/permission.dart';
// import '../app/utils/navigate_to_page.dart';
// import '../app/utils/utils.dart';
// import 'navigations.dart';

/// Provides methods to manage dynamic links.
final class DynamicLinkHandler {
  DynamicLinkHandler._();

  static final instance = DynamicLinkHandler._();

  // final _appLinks = AppLinks();
  // bool _isLinkHandled = false; // Flag to track if the link is already handled

  /// Initializes the [DynamicLinkHandler].
  // Future<void> initialize() async {
  //   // * Listens to the dynamic links and manages navigation.
  //   _appLinks.uriLinkStream.distinct().listen(_handleLinkData).onError((error) {
  //     log('$error', name: 'Dynamic Link Handler');
  //   });
  //   _checkInitialLink();
  // }

  /// Handle navigation if initial link is found on app start.
  // Future<void> _checkInitialLink() async {
  //   final initialLink = await _appLinks.getInitialLink();
  //   if (initialLink != null) {
  //     _handleLinkData(initialLink);
  //   } else {
  //     // checkUser();
  //   }
  // }

  /// Handles the link navigation Dynamic Links.
  void _handleLinkData(Uri data) async {
    // if (_isLinkHandled) return; // Ignore if already handled

    // _isLinkHandled = true; // Mark the link as handled

    log(data.toString(), name: 'Dynamic Link Handler');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (data.toString().endsWith('inviteuser')) {
        // NavigateTo().pushRemove(child: const LoginScreen());
        return;
      }
      // checkUser();
    });
  }
}

// void checkUser() async {
//   await Future.delayed(
//       Duration.zero); // Ensures this is called after initialization

//   final user = await SharedPreferences.getInstance();

//   String? token = user.getString('token');

//   try {
//     PermissionStatus status = await PermissionManager.hasLocationPermissions();

//     if (status.isGranted) {
//       Position position = await Geolocator.getCurrentPosition(
//           desiredAccuracy: LocationAccuracy.high);

//       LocationSharePreferences.saveLocation(
//           position.latitude.toString(), position.longitude.toString());
//     }

//     bool result = await InternetConnection().hasInternetAccess;

//     if (!result) {
//       Utils.showSnackBar(
//         navigatorKey.currentContext!,
//         const Text("Internet Not Available"),
//         duration: const Duration(hours: 1),
//       );
//       return;
//     }

//     FlutterNativeSplash.remove();

//     if (token != null) {
//       // NavigateToPage.pushAndRemoveUntil(
//       //     navigatorKey.currentContext!, const RootScreen());
//     } else {
//       // Navigator.of(navigatorKey.currentContext!)
//       //     .pushReplacementNamed(OnboardingScreen.routeName);

//       // NavigateToPage.pushNamedReplacement(
//       //     navigatorKey.currentContext!, LanguageSelectionScreen.routeName);
//     }
//   } catch (e) {
//     FlutterNativeSplash.remove();

//     // NavigateToPage.pushNamedReplacement(
//     //     navigatorKey.currentContext!, LanguageSelectionScreen.routeName);
//   }
//   return;
// }
