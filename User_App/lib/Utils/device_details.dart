// import 'package:device_info_plus/device_info_plus.dart';
// import 'package:package_info_plus/package_info_plus.dart';
// import 'dart:io';

// Future<Map<String, String>> getDeviceAndAppDetails() async {
//   final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
//   final PackageInfo packageInfo = await PackageInfo.fromPlatform();

//   String deviceModel = "";
//   String deviceOsName = "";
//   String deviceOsVersion = "";

//   // Get device details based on platform
//   if (Platform.isAndroid) {
//     final androidInfo = await deviceInfo.androidInfo;
//     deviceModel = androidInfo.model;
//     deviceOsName = "Android";
//     deviceOsVersion = androidInfo.version.release;
//   } else if (Platform.isIOS) {
//     final iosInfo = await deviceInfo.iosInfo;
//     deviceModel = iosInfo.utsname.machine;
//     deviceOsName = "iOS";
//     deviceOsVersion = iosInfo.systemVersion;
//   }

//   // Get app details
//   final String appVersion = packageInfo.version;

//   return {
//     "device_model": deviceModel,
//     "device_os_name": deviceOsName,
//     "device_os_version": deviceOsVersion,
//     "app_version": appVersion,
//   };
// }
