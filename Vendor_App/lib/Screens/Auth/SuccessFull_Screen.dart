import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resqboxvendor/Controller/DashboardController.dart';
import 'package:resqboxvendor/Controller/KitchenRegistrationController.dart';
import 'package:resqboxvendor/Screens/Auth/registration.dart';
import 'package:resqboxvendor/Screens/Auth/rejected.dart';
import 'package:resqboxvendor/Screens/bottomNavigation.dart';
import 'package:resqboxvendor/Utils/colors.dart';
import 'package:resqboxvendor/Utils/images.dart';
import 'package:resqboxvendor/Utils/navigations.dart';
import 'package:resqboxvendor/Utils/textstyles.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:resqboxvendor/Utils/custom_alert.dart';

class SuccessfulScreen extends StatefulWidget {
  const SuccessfulScreen({super.key});

  @override
  State<SuccessfulScreen> createState() => _SuccessfulScreenState();
}

class _SuccessfulScreenState extends State<SuccessfulScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<KitchenRegistrationController>(
        context,
        listen: false,
      ).getConfig();
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        showAlertDialog(
          context: context,
          title: "Exit App",
          content: "Are you sure you want to exit?",
          onPressed: () {
            SystemNavigator.pop();
          },
        );
        return false;
      },
      child: Scaffold(
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 30),
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () async {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChangeNotifierProvider(
                      create: (_) => DashboardProvider()..setIndex(0),
                      child: const MainTabScreen(),
                      // child: SuccessfulScreen(),
                    ),
                  ),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mainAppColr,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                'Continue',
                style: AppTextStyles.size16SemiBold.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        backgroundColor: AppColors.tWhiteColor,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              final controller = Provider.of<KitchenRegistrationController>(
                context,
                listen: false,
              );
              await controller.getConfig();
              await controller.getKitchenStatus();

              if (context.mounted) {
                if (controller.registrationStatus == "APPROVED") {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangeNotifierProvider(
                        create: (_) => DashboardProvider()..setIndex(0),
                        child: const MainTabScreen(),
                      ),
                    ),
                    (route) => false,
                  );
                } else if (controller.registrationStatus == "REJECTED") {
                  NavigateTo().pushRemove(child: const SuccessfulScreen());
                }
              }
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  // Header
                  const Row(children: [Spacer()]),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Verification',
                          style: AppTextStyles.size24SemiBold,
                        ),
                      ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {
                            showAlertDialog(context: context);
                          },
                          child: Icon(Icons.logout, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Your restaurant has been verified successfully.',
                      style: AppTextStyles.size14SemiBold.copyWith(
                        color: Color(0xff777777),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Please add your bank details to receive payouts in the next step.',
                      style: AppTextStyles.size14Regular.copyWith(
                        // fontWeight: FontWeight.w400,
                        color: Color(0xff777777),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  Container(
                    height: 200,
                    width: double.infinity,
                    alignment: Alignment.center,
                    child: Image.asset(AppImages.pendingRegsitration),
                  ),

                  const SizedBox(height: 40),

                  // Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Verification Status:  ',
                        style: AppTextStyles.size14Medium,
                      ),
                      // Text(' ', style: AppTextStyles.size14Medium),
                      Text(
                        'Verified ',
                        style: AppTextStyles.size14Medium.copyWith(
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.tWhiteColor,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // const SizedBox(height: 30),

                  // Text(
                  //   'Do you have any queries? Contact us.',
                  //   style: AppTextStyles.size16SemiBold,
                  // ),
                  // const SizedBox(height: 8),
                  // Text(
                  //   'Our support team is here to help! Reach out to us for any questions or assistance.',
                  //   textAlign: TextAlign.center,
                  //   style: AppTextStyles.size14Medium.copyWith(
                  //     color: Color(0xff777777),
                  //   ),
                  // ),

                  // const SizedBox(height: 30),

                  // Consumer<KitchenRegistrationController>(
                  //   builder: (context, controller, child) {
                  //     return Padding(
                  //       padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  //       child: Column(
                  //         children: [
                  //           SizedBox(
                  //             width: double.infinity,
                  //             height: 50,
                  //             child: OutlinedButton.icon(
                  //               onPressed: () async {
                  //                 final email =
                  //                     controller.supportEmail ??
                  //                     'support@resqbox.com';
                  //                 final Uri emailUri = Uri(
                  //                   scheme: 'mailto',
                  //                   path: email,
                  //                   query: 'subject=Support Request',
                  //                 );
                  //                 try {
                  //                   await launchUrl(
                  //                     emailUri,
                  //                     mode: LaunchMode.externalApplication,
                  //                   );
                  //                 } catch (e) {
                  //                   debugPrint('Could not launch email: $e');
                  //                 }
                  //               },
                  //               icon: const Icon(
                  //                 Icons.email_outlined,
                  //                 color: AppColors.mainAppColr,
                  //               ),
                  //               label: Text(
                  //                 controller.supportEmail ??
                  //                     'support@resqbox.com',
                  //                 style: AppTextStyles.size14Medium,
                  //               ),
                  //               style: OutlinedButton.styleFrom(
                  //                 side: const BorderSide(
                  //                   color: Color(0xffC0C0C0),
                  //                 ),
                  //                 shape: RoundedRectangleBorder(
                  //                   borderRadius: BorderRadius.circular(8),
                  //                 ),
                  //               ),
                  //             ),
                  //           ),

                  //           const SizedBox(height: 20),

                  //           Padding(
                  //             padding: const EdgeInsets.symmetric(
                  //               horizontal: 60.0,
                  //             ),
                  //             child: Row(
                  //               children: [
                  //                 Expanded(
                  //                   child: Container(
                  //                     height: 1,
                  //                     color: AppColors.yashCECE,
                  //                   ),
                  //                 ),
                  //                 const Padding(
                  //                   padding: EdgeInsets.symmetric(
                  //                     horizontal: 10,
                  //                   ),
                  //                   child: Text(
                  //                     'OR',
                  //                     style: TextStyle(
                  //                       color: AppColors.yash77,
                  //                       fontSize: 12,
                  //                     ),
                  //                   ),
                  //                 ),
                  //                 Expanded(
                  //                   child: Container(
                  //                     height: 1,
                  //                     color: AppColors.yashCECE,
                  //                   ),
                  //                 ),
                  //               ],
                  //             ),
                  //           ),

                  //           const SizedBox(height: 20),

                  //           SizedBox(
                  //             width: double.infinity,
                  //             height: 50,
                  //             child: OutlinedButton.icon(
                  //               onPressed: () async {
                  //                 final phone =
                  //                     controller.supportNumber ??
                  //                     '+61412345678';
                  //                 final Uri phoneUri = Uri(
                  //                   scheme: 'tel',
                  //                   path: phone,
                  //                 );
                  //                 try {
                  //                   await launchUrl(
                  //                     phoneUri,
                  //                     mode: LaunchMode.externalApplication,
                  //                   );
                  //                 } catch (e) {
                  //                   debugPrint('Could not launch phone: $e');
                  //                 }
                  //               },
                  //               icon: const Icon(
                  //                 Icons.phone_outlined,
                  //                 color: AppColors.mainAppColr,
                  //               ),
                  //               label: Text(
                  //                 controller.supportNumber ??
                  //                     '+61 4 12 345 678',
                  //                 style: AppTextStyles.size14Medium,
                  //               ),
                  //               style: OutlinedButton.styleFrom(
                  //                 side: const BorderSide(
                  //                   color: AppColors.yashCECE,
                  //                 ),
                  //                 shape: RoundedRectangleBorder(
                  //                   borderRadius: BorderRadius.circular(8),
                  //                 ),
                  //               ),
                  //             ),
                  //           ),
                  //         ],
                  //       ),
                  //     );
                  //   },
                  // ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
