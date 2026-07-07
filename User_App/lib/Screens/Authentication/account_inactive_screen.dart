import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resqbox_user/Controllers/authentication_controller.dart';
import 'package:resqbox_user/Screens/Authentication/login_screen.dart';
import 'package:resqbox_user/Utils/active_btn.dart';
import 'package:resqbox_user/Utils/colors.dart';
import 'package:resqbox_user/Utils/custom_image_widget.dart';
import 'package:resqbox_user/Utils/custom_padding.dart';
import 'package:resqbox_user/Utils/custom_sizedbox.dart';
import 'package:resqbox_user/Utils/customtext.dart';
import 'package:resqbox_user/Utils/images.dart';
import 'package:resqbox_user/Utils/mediaquery.dart';
import 'package:resqbox_user/Utils/navigations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:resqbox_user/Models/config_details_model.dart';

class AccountInactiveScreen extends StatefulWidget {
  const AccountInactiveScreen({super.key});

  @override
  State<AccountInactiveScreen> createState() => _AccountInactiveScreenState();
}

class _AccountInactiveScreenState extends State<AccountInactiveScreen> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Provider.of<AuthenticationController>(context, listen: false)
          .getSupportDetails();
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("Building AccountInactiveScreen...");
    return Scaffold(
      backgroundColor: AppColors.tWhiteColor,
      bottomNavigationBar: CustomPadding(
        bottom: 0.03,
        left: .05,
        right: .05,
        child: ActiveButton(
          onPressed: () {
            NavigateTo().pushRemove(child: const LoginScreen());
          },
          text: "Back to Login",
          width: Sizes.width,
          height: Sizes.height * .06,
          borderRadius: 4,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: CustomPadding(
            left: .06,
            right: .06,
            top: .14,
            child: Consumer<AuthenticationController>(
              builder: (context, provider, child) {
                final email = provider.supportdata?.config
                        ?.firstWhere(
                          (element) => element.configKey == 'Support Email',
                          orElse: () =>
                              Config(configValue: 'support@resqboxfood.com'),
                        )
                        .configValue ??
                    'support@resqboxfood.com';

                final phone = provider.supportdata?.config
                        ?.firstWhere(
                          (element) => element.configKey == 'Support Number',
                          orElse: () => Config(configValue: '+91 777777777'),
                        )
                        .configValue ??
                    '+91 777777777';

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CustomText(
                      text: "Account Inactive",
                      fontSize: 0.026,
                      fontWeight: FontWeight.w600,
                      color: AppColors.tBlackColor,
                    ),
                    // cons/t CustomPadding(
                    //   top: 0.015,
                    //   child: CustomText(
                    //     textAlign: TextAlign.start,
                    //     text:
                    //         "Your account is currently inactive. Please contact support for assistance.",
                    //     fontSize: 0.016,
                    //     fontWeight: FontWeight.w500,
                    //     color: AppColors.hintTclr,
                    //   ),
                    // ),
                    const CustomSizedBox(height: .035),
                    const Center(
                      child: CustomImage(
                        image: AppImages.inactive,
                        height: .25,
                      ),
                    ),
                    // const CustomPadding(
                    //   top: 0.055,
                    //   // horizontal: .08,
                    //   child: Align(
                    //     alignment: Alignment.center,
                    //     child: CustomText(
                    //       text: "Do you have any Queries contact us",
                    //       fontSize: 0.019,
                    //       fontWeight: FontWeight.w600,
                    //       color: AppColors.tBlackColor,
                    //     ),
                    //   ),
                    // ),
                    const CustomSizedBox(
                      height: 0.055,
                    ),
                    const CustomPadding(
                      horizontal: .06,
                      child: CustomText(
                        textAlign: TextAlign.center,
                        text:
                            "Your account is currently inactive. Please contact support for more information.",
                        // "Our support team is here to help! Reach out to us for any questions or assistance.",
                        fontSize: 0.016,
                        fontWeight: FontWeight.w500,
                        color: AppColors.hintTclr,
                      ),
                    ),
                    const CustomSizedBox(
                      height: 0.025,
                    ),
                    CustomPadding(
                      horizontal: .1,
                      vertical: 0.02,
                      child: BorderCustomContainer(
                        height: Sizes.height * 0.05,
                        width: Sizes.width,
                        text: email,
                        onTap: () async {
                          await launchUrl(Uri.parse(
                              "mailto:$email?subject=Hello&body=This%20is%20a%20message"));
                        },
                        borderColor: const Color(0XFFC0C0C0),
                        textColor: AppColors.tBlackColor,
                        fontSize: 0.016,
                        image: AppImages.inactivemail,
                      ),
                    ),
                    // CustomPadding(
                    //   left: .1,
                    //   right: .1,
                    //   top: 0.02,
                    //   child: BorderCustomContainer(
                    //     height: Sizes.height * 0.05,
                    //     width: Sizes.width,
                    //     text: phone,
                    //     onTap: () async {
                    //       await launchUrl(Uri.parse("tel:$phone"));
                    //     },
                    //     borderColor: const Color(0XFFC0C0C0),
                    //     textColor: AppColors.tBlackColor,
                    //     fontSize: 0.016,
                    //     image: AppImages.inactivecall,
                    //   ),
                    // ),
                    // const CustomSizedBox(height: 0.05),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class BorderCustomContainer extends StatelessWidget {
  final double height;
  final double width;
  final String text;
  final VoidCallback onTap;
  final Color borderColor;
  final Color textColor;
  final double? fontSize;
  final String image;
  const BorderCustomContainer(
      {super.key,
      required this.height,
      required this.width,
      required this.text,
      required this.onTap,
      required this.borderColor,
      required this.textColor,
      required this.fontSize,
      required this.image});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CustomSizedBox(width: 0.04),
            Image.asset(
              image,
              height: Sizes.height * 0.034,
            ),
            const CustomSizedBox(
              width: 0.02,
            ),
            Expanded(
              child: CustomText(
                text: text, //text,
                color: textColor,
                fontSize: fontSize,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DivRow extends StatelessWidget {
  const DivRow({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(
            thickness: 1.2,
            color: AppColors.hintTclr,
          ),
        ),
        CustomPadding(
          horizontal: Sizes.width * 0.04,
          child: const CustomText(
            text: 'OR',
            fontSize: 0.018,
            color: AppColors.tBlackColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Expanded(
          child: Divider(
            thickness: 1.2,
            color: AppColors.hintTclr,
          ),
        ),
      ],
    );
  }
}
