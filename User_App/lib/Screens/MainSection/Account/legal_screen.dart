import 'package:flutter/material.dart';
import 'package:resqbox_user/Utils/colors.dart';
import 'package:resqbox_user/Utils/custom_appbar.dart';
import 'package:resqbox_user/Utils/custom_image_widget.dart';
import 'package:resqbox_user/Utils/custom_padding.dart';
import 'package:resqbox_user/Utils/custom_tap.dart';
import 'package:resqbox_user/Utils/customtext.dart';
import 'package:resqbox_user/Utils/images.dart';
import 'package:resqbox_user/Utils/navigations.dart';
import 'package:url_launcher/url_launcher.dart';

class LegalScreen extends StatefulWidget {
  const LegalScreen({super.key});

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0XFFF6F6F6),
      appBar: CustomAppBar(
        title: "Legal",
        titleFontSize: 0.022,
        backgroundColor: AppColors.tWhiteColor,
        backTap: () {
          NavigateTo().backPage();
        },
      ),
      body: Column(
        children: [
          CustomPadding(
            horizontal: .04,
            vertical: .02,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.tWhiteColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: CustomPadding(
                vertical: .01,
                child: Column(
                  children: [
                    profileRow("Privacy Policy", AppImages.accountPrivacy,
                        () async {
                      await launchUrl(Uri.parse(
                          "https://www.resqboxfood.com/privacy-policy"));
                    }),
                    const CustomPadding(
                        horizontal: .03,
                        vertical: .005,
                        child: Divider(color: Color(0XFFE1E1E1), height: 1)),
                    profileRow("Terms and Conditions", AppImages.accountPrivacy,
                        () async {
                      await launchUrl(Uri.parse(
                          "https://www.resqboxfood.com/terms-of-service"));
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  CustomPadding profileRow(String name, String image, VoidCallback onTap) {
    return CustomPadding(
      vertical: 0.018,
      horizontal: 0.06,
      child: CustomTap(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            CustomImage(
              image: image,
              height: .032,
            ),
            Expanded(
              child: CustomPadding(
                left: 0.04,
                child: CustomText(
                  text: name,
                  color: name == "Logout"
                      ? AppColors.tPrimaryColor
                      : AppColors.tBlackColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 0.018,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_outlined,
              color: Color(0XFFA6A6A6),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
