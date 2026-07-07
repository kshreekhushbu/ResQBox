import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resqboxvendor/Controller/DashboardController.dart';
import 'package:resqboxvendor/Controller/KitchenRegistrationController.dart';
import 'package:resqboxvendor/Screens/bottomNavigation.dart';
import 'package:resqboxvendor/Utils/colors.dart';
import 'package:resqboxvendor/Utils/custom_border_btn.dart';
import 'package:resqboxvendor/Utils/dotted_line.dart';
import 'package:resqboxvendor/Utils/images.dart';
import 'package:resqboxvendor/Utils/textstyles.dart';

class RegistrationVerification extends StatefulWidget {
  const RegistrationVerification({super.key});

  @override
  State<RegistrationVerification> createState() =>
      _RegistrationVerificationState();
}

class _RegistrationVerificationState extends State<RegistrationVerification> {
  @override
  void initState() {
    super.initState();
    final controller = Provider.of<KitchenRegistrationController>(
      context,
      listen: false,
    );
    controller.getKitchenStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<KitchenRegistrationController>(
      builder: (context, controller, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 22.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 70),
                        Text(
                          "Verification",
                          style: AppTextStyles.size24SemiBold,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "Once verified you will get a Text notification\nvia phone number",
                          style: AppTextStyles.size14Medium.copyWith(
                            color: Color(0xff777777),
                          ),
                        ),
                        SizedBox(height: 30),
                        Text("Status", style: AppTextStyles.size16Regular),
                        SizedBox(height: 10),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: Image.asset(
                            AppImages.verification,
                            width: 220,
                            height: 220,
                            fit: BoxFit.contain,
                          ),
                        ),

                        Positioned(
                          left: 0,
                          top: 20,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final screenWidth = MediaQuery.of(
                                context,
                              ).size.width;
                              final imageWidth = 220.0;
                              final buttonWidth =
                                  (screenWidth - imageWidth - 0) + 14;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomRectBtn(
                                    color: AppColors.tWhiteColor,
                                    borderColor: AppColors.mainAppColr,
                                    height: 40,
                                    width: buttonWidth,
                                    leading: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          AppImages.inProgress,
                                          height: 24,
                                          width: 24,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            "In Progress",
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTextStyles.size14Medium
                                                .copyWith(
                                                  color: Colors.black,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    onTap: () {},
                                    textColor: Colors.black,
                                  ),

                                  const SizedBox(height: 10),
                                  const Row(
                                    children: [
                                      SizedBox(width: 25),
                                      VerticalDottedLine(height: 80),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  CustomRectBtn(
                                    color: AppColors.tWhiteColor,
                                    borderColor:
                                        controller.registrationStatus ==
                                            "APPROVED"
                                        ? AppColors.mainAppColr
                                        : controller.registrationStatus !=
                                                  null &&
                                              controller.registrationStatus !=
                                                  "APPROVED"
                                        ? Colors.red
                                        : const Color(0xff777777),
                                    height: 40,
                                    width: buttonWidth,
                                    leading: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        const SizedBox(width: 6),
                                        Container(
                                          height: 20,
                                          width: 20,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              50,
                                            ),
                                            color:
                                                controller.registrationStatus ==
                                                    "APPROVED"
                                                ? AppColors.mainAppColr
                                                : controller.registrationStatus !=
                                                          null &&
                                                      controller
                                                              .registrationStatus !=
                                                          "APPROVED"
                                                ? Colors.red
                                                : const Color(0xffD6D6D6),
                                          ),
                                          child: Icon(
                                            Icons.check,
                                            size: 15,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            controller.isLoadingStatus
                                                ? "Loading..."
                                                : controller
                                                          .registrationStatus ??
                                                      "Verified",
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTextStyles.size14Medium.copyWith(
                                              color:
                                                  controller
                                                          .registrationStatus ==
                                                      "APPROVED"
                                                  ? AppColors.mainAppColr
                                                  : controller.registrationStatus !=
                                                            null &&
                                                        controller
                                                                .registrationStatus !=
                                                            "APPROVED"
                                                  ? Colors.red
                                                  : const Color(0xffD6D6D6),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    onTap: () {},
                                    textColor: Colors.black,
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Do you have any queries? Contact us.",
                          style: AppTextStyles.size16SemiBold,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "Our support team is here to help! Reach out to us for any questions or assistance.",
                          textAlign: TextAlign.center,
                          style: AppTextStyles.size14Medium.copyWith(
                            color: Color(0xff777777),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: CustomRectBtn(
                      color: AppColors.tWhiteColor,
                      borderColor: Color(0xffC0C0C0),
                      height: 49,
                      width: double.infinity,
                      leading: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(AppImages.mail, width: 24, height: 24),
                          SizedBox(width: 10),
                          Text(
                            "support@resqboxvendor.com",
                            style: AppTextStyles.size16Medium.copyWith(
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChangeNotifierProvider(
                              create: (_) => DashboardProvider()..setIndex(0),
                              child: MainTabScreen(),
                            ),
                          ),
                        );
                      },
                      textColor: Colors.black,
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(height: 1, color: Color(0xffD9D8DD), width: 65),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15.0),
                        child: Text(
                          "OR",
                          textAlign: TextAlign.center,
                          style: AppTextStyles.size14Regular.copyWith(
                            color: Color(0xff777777),
                          ),
                        ),
                      ),
                      Container(height: 1, color: Color(0xffD9D8DD), width: 65),
                    ],
                  ),
                  SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: CustomRectBtn(
                      color: AppColors.tWhiteColor,
                      borderColor: Color(0xffC0C0C0),
                      height: 49,
                      width: double.infinity,
                      leading: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(AppImages.call, width: 24, height: 24),
                          SizedBox(width: 10),
                          Text(
                            "+91876543221",
                            style: AppTextStyles.size16Medium.copyWith(
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      onTap: () {},
                      textColor: Colors.black,
                    ),
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
