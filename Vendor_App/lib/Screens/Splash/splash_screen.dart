import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resqboxvendor/Controller/DashboardController.dart';
import 'package:resqboxvendor/Controller/KitchenRegistrationController.dart';

import 'package:resqboxvendor/Screens/Auth/login_screen.dart';
import 'package:resqboxvendor/Screens/Auth/pending.dart';
import 'package:resqboxvendor/Screens/Auth/rejected.dart';
import 'package:resqboxvendor/Screens/Auth/rejection.dart';
import 'package:resqboxvendor/Screens/bottomNavigation.dart';
import 'package:resqboxvendor/Utils/images.dart';
import 'package:resqboxvendor/Utils/mediaquery.dart';
import 'package:resqboxvendor/Utils/navigations.dart';
import 'package:resqboxvendor/Utils/shared_preference_helper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double scale = 0.5;
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        scale = 1.2;
      });
    });

    Timer(const Duration(seconds: 3), () async {
      if (!mounted) return;

      SharedPreferencesHelper prefs =
          await SharedPreferencesHelper.getInstance();
      String? token = prefs.getString("ApiToken");

      debugPrint("TOKEN  $token");

      if ((token ?? '').isNotEmpty) {
        final controller = Provider.of<KitchenRegistrationController>(
          context,
          listen: false,
        );
        // final profileController = Provider.of<KitchenProfileController>(
        //   context,
        //   listen: false,
        // );

        // // Sync FCM Token
        // await profileController.syncFcmToken();

        await controller.getKitchenStatus();

        if (!mounted) return;

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
          NavigateTo().pushRemove(child: const RejectedScreen());
        } else {
          // Default to Pending if not APPROVED or REJECTED (includes PENDING)
          NavigateTo().pushRemove(child: const PendingScreen());
        }
      } else {
        NavigateTo().pushRemove(child: LoginScreen());
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Sizes.init(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Center(child: Image.asset(AppImages.splashImage)),

          // Bottom content
          // Align(
          //   alignment: Alignment.bottomCenter,
          //   child: Padding(
          //     padding: const EdgeInsets.only(bottom: 30),
          //     child: Column(
          //       mainAxisSize: MainAxisSize.min,
          //       children: [
          //         Image.asset(AppImages.spalshPot, height: 85, width: 85),
          //         const SizedBox(height: 10),
          //         Text(
          //           'Loading...',
          //           style: AppTextStyles.size16SemiBold.copyWith(
          //             color: const Color(0xff777777),
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}
