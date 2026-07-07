import 'package:flutter/material.dart';
import 'package:resqbox_user/Screens/Authentication/login_screen.dart';
import 'package:resqbox_user/Utils/active_btn.dart';
import 'package:resqbox_user/Utils/colors.dart';
import 'package:resqbox_user/Utils/custom_image_widget.dart';
import 'package:resqbox_user/Utils/custom_padding.dart';
import 'package:resqbox_user/Utils/customtext.dart';
import 'package:resqbox_user/Utils/images.dart';
import 'package:resqbox_user/Utils/mediaquery.dart';
import 'package:resqbox_user/Utils/navigations.dart';

class GuestLoginScreen extends StatefulWidget {
  const GuestLoginScreen({super.key});

  @override
  State<GuestLoginScreen> createState() => _GuestLoginScreenState();
}

class _GuestLoginScreenState extends State<GuestLoginScreen> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          return;
        }
        NavigateTo().nextPage(child: LoginScreen());
      },
      child: SafeArea(
        bottom: false,
        top: false,
        child: Scaffold(
          backgroundColor: AppColors.tWhiteColor,
          body: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const CustomPadding(
                    top: .15,
                    child: Align(
                        alignment: Alignment.center,
                        child:
                            CustomImage(image: AppImages.logo, height: .068)),
                  ),
                  const CustomPadding(
                    top: .04,
                    child: Align(
                      alignment: Alignment.center,
                      child: CustomText(
                        text:
                            "Find and order fresh,\n home-style meals \nfrom nearby kitchens.",
                        fontSize: 0.032,
                        fontWeight: FontWeight.w700,
                        color: AppColors.tBlackColor,
                      ),
                    ),
                  ),
                  const CustomPadding(
                    top: .06,
                    child: Align(
                        alignment: Alignment.center,
                        child:
                            CustomImage(image: AppImages.guest, height: .43)),
                  ),
                ],
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.tPrimaryColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                      ),
                    ),
                    child: CustomPadding(
                      top: .035,
                      bottom: .035,
                      left: .05,
                      right: .05,
                      child: ActiveButton(
                        onPressed: () {
                          NavigateTo().pushRemove(child: const LoginScreen());
                        },
                        text: "Sign In",
                        width: Sizes.width,
                        height: Sizes.height * .06,
                        borderRadius: 25,
                        color: AppColors.tWhiteColor,
                        txtClr: AppColors.tBlackColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
