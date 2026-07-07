import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resqboxvendor/Controller/DashboardController.dart';
import 'package:resqboxvendor/Controller/KitchenRegistrationController.dart';
import 'package:resqboxvendor/Screens/Auth/pending.dart';
import 'package:resqboxvendor/Screens/Auth/rejected.dart';
import 'package:resqboxvendor/Screens/Auth/rejection.dart';
import 'package:resqboxvendor/Screens/bottomNavigation.dart';
import 'package:resqboxvendor/Utils/custom_border_btn.dart';
import 'package:resqboxvendor/Utils/images.dart';
import 'package:resqboxvendor/Utils/navigations.dart';
import 'package:resqboxvendor/Utils/textstyles.dart';

class RegistrationSuccess extends StatefulWidget {
  const RegistrationSuccess({super.key});

  @override
  State<RegistrationSuccess> createState() => _RegistrationSuccessState();
}

class _RegistrationSuccessState extends State<RegistrationSuccess> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(AppImages.success, height: 250),
              Text(
                "Request Submitted Successfully!",
                style: AppTextStyles.size18SemiBold,
              ),
              SizedBox(height: 12),
              Text(
                "Our admin team will review and verify your details within 24 hours. You’ll be notified once the confirmation is complete.",
                textAlign: TextAlign.center,
                style: AppTextStyles.size14Medium.copyWith(
                  color: Color(0xff777777),
                ),
              ),

              SizedBox(height: 20),
              CustomRectBtn(
                width: MediaQuery.of(context).size.width * 0.45,
                onTap: () async {
                  final controller = Provider.of<KitchenRegistrationController>(
                    context,
                    listen: false,
                  );
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
                      NavigateTo().pushRemove(child: const RejectedScreen());
                    } else {
                      NavigateTo().pushRemove(child: const PendingScreen());
                    }
                  }
                },
                height: 49,
                borderRadius: 8,
                leading: Center(
                  child: Text(
                    "Got it",
                    style: AppTextStyles.size16SemiBold.copyWith(
                      color: Colors.black,
                    ),
                  ),
                ),
                color: Colors.white,
                borderColor: const Color(0xffEB7712),
                textColor: Colors.black,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
