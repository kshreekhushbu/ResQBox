// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:resqboxvendor/Controller/KitchenRegistrationController.dart';
// import 'package:resqboxvendor/Screens/Auth/registration.dart';
// import 'package:resqboxvendor/Utils/images.dart';
// import 'package:resqboxvendor/Utils/navigations.dart';
// import 'package:resqboxvendor/Utils/textstyles.dart';
// import 'package:url_launcher/url_launcher.dart';
// import '../../Utils/colors.dart';

// class RejectedScreen extends StatefulWidget {
//   const RejectedScreen({super.key});

//   @override
//   State<RejectedScreen> createState() => _RejectedScreenState();
// }

// class _RejectedScreenState extends State<RejectedScreen> {
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       Provider.of<KitchenRegistrationController>(
//         context,
//         listen: false,
//       ).getConfig();
//     });
//   }

//   Future<void> _launchUrl(String url) async {
//     if (!await launchUrl(Uri.parse(url))) {
//       throw Exception('Could not launch $url');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<KitchenRegistrationController>(
//       builder: (context, controller, child) {
//         return Scaffold(
//           backgroundColor: AppColors.tWhiteColor,
//           body: SafeArea(
//             child: RefreshIndicator(
//               onRefresh: () async {
//                 await Provider.of<KitchenRegistrationController>(
//                   context,
//                   listen: false,
//                 ).getConfig();
//               },
//               child: SingleChildScrollView(
//                 physics: const AlwaysScrollableScrollPhysics(),
//                 padding: const EdgeInsets.symmetric(horizontal: 24.0),
//                 child: SizedBox(
//                   height: MediaQuery.of(context).size.height - 50,
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       Padding(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 60.0,
//                           vertical: 25,
//                         ),
//                         child: Container(
//                           alignment: Alignment.center,
//                           child: Image.asset(AppImages.rejected),
//                         ),
//                       ),

//                       Text(
//                         'Kitchen application Rejected',
//                         textAlign: TextAlign.center,
//                         style: AppTextStyles.size18SemiBold,
//                       ),
//                       const SizedBox(height: 16),

//                       Text(
//                         'Your Kitchen registration did not meet our verification requirements. Please review the feedback',
//                         textAlign: TextAlign.center,
//                         style: AppTextStyles.size14Regular.copyWith(
//                           color: const Color(0xff777777),
//                         ),
//                       ),

//                       const SizedBox(height: 40),

//                       Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 60.0),
//                         child: Column(
//                           children: [
//                             SizedBox(
//                               width: double.infinity,
//                               height: 50,
//                               child: OutlinedButton(
//                                 onPressed: () {
//                                   if (controller.supportNumber != null) {
//                                     _launchUrl(
//                                       'tel:${controller.supportNumber}',
//                                     );
//                                   }
//                                 },
//                                 style: OutlinedButton.styleFrom(
//                                   side: const BorderSide(
//                                     color: AppColors.mainAppColr,
//                                   ),
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(8),
//                                   ),
//                                 ),
//                                 child: Text(
//                                   'Call customer support',
//                                   style: AppTextStyles.size16SemiBold.copyWith(
//                                     color: Colors.black,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(height: 16),
//                             SizedBox(
//                               width: double.infinity,
//                               height: 50,
//                               child: ElevatedButton(
//                                 onPressed: () async {
//                                   final controller =
//                                       Provider.of<
//                                         KitchenRegistrationController
//                                       >(context, listen: false);
//                                   await controller.fetchKitchenDetails();
//                                   if (controller.isReapplying) {
//                                     NavigateTo().pushReplacement(
//                                       child: const KitchenRegistration(),
//                                     );
//                                   }
//                                 },
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: AppColors.mainAppColr,
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(8),
//                                   ),
//                                   elevation: 0,
//                                 ),
//                                 child: Text(
//                                   'Re-Apply',
//                                   style: AppTextStyles.size16SemiBold.copyWith(
//                                     color: Colors.white,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
