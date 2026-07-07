// // import 'package:flutter/material.dart';

// // class CustomLauncer {
// //   Future<void> urlLaunch(
// //       {required String val, required BuildContext context}) async {
// //     Uri url = Uri.parse(val);
// //     if (!await launchUrl(url)) {
// //       if (!context.mounted) {
// //         return;
// //       }
// //       ShowToast().customToast(context, message: 'Invalid url');
// //       // throw Exception('Could not launch $url');
// //     }
// //   }
// // }

// import 'package:app_4wd/Utils/custom_toast.dart';
// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';

// // import '../app/utils/customtoast.dart';

// void navigatoToMap({
//   required String url,
//   required BuildContext context,
// }) async {
//   if (await canLaunchUrl(Uri.parse(url))) {
//     await launchUrl(Uri.parse(url));
//   } else {
//     CustomToast().showToast(message: 'No Map Found In Your Device');
//   }
// }

// Future<void> customUrlLauncher({required String? url}) async {
//   if (url == null) {
//     CustomToast().showToast(message: 'Invalid URL');
//     return;
//   }
//   if (!await launchUrl(Uri.parse(url))) {
//     CustomToast().showToast(message: 'Could not launch $url');
//     throw Exception('Could not launch $url');
//   }
// }
