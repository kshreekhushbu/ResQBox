import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:resqbox_user/Controllers/authentication_controller.dart';
import 'package:resqbox_user/Screens/Authentication/otp_bottom_sheet.dart';
import 'package:resqbox_user/Screens/Authentication/signup_screen.dart';
import 'package:resqbox_user/Screens/MainSection/bottom_navigation.dart';
import 'package:resqbox_user/Utils/active_btn.dart';
import 'package:resqbox_user/Utils/colors.dart';
import 'package:resqbox_user/Utils/custom_border_btn.dart';
import 'package:resqbox_user/Utils/custom_image_widget.dart';
import 'package:resqbox_user/Utils/custom_padding.dart';
import 'package:resqbox_user/Utils/custom_sizedbox.dart';
import 'package:resqbox_user/Utils/custom_tap.dart';
import 'package:resqbox_user/Utils/customtext.dart';
import 'package:resqbox_user/Utils/images.dart';
import 'package:resqbox_user/Utils/mediaquery.dart';
import 'package:resqbox_user/Utils/navigations.dart';
import 'package:resqbox_user/Utils/shared_preference_helper.dart';
import 'package:resqbox_user/Utils/textformfield.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.tWhiteColor,
      body: Stack(
        children: [
          // Background images - rendered first (behind)
          const IgnorePointer(
            child: Stack(
              children: [
                Positioned(
                  bottom: 0,
                  child: CustomImage(image: AppImages.loginbg, height: .21),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  child: CustomImage(
                    image: AppImages.line2,
                    height: .25,
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: CustomImage(
                    image: AppImages.line1,
                    height: .36,
                  ),
                ),
              ],
            ),
          ),
          // Form content - rendered second (on top)
          SafeArea(
            child: SingleChildScrollView(
              child: CustomPadding(
                top: .09,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Align(
                          alignment: Alignment.center,
                          child:
                              CustomImage(image: AppImages.logo, height: .065)),
                      const CustomSizedBox(
                        height: .05,
                      ),
                      const CustomText(
                          text: "Welcome to ResQBox Food!",
                          fontSize: .023,
                          fontWeight: FontWeight.w600),
                      const CustomSizedBox(
                        height: .02,
                      ),
                      const CustomText(
                          text: "Pick up your next delicious meal in minutes.",
                          fontSize: .018,
                          fontWeight: FontWeight.w500),
                      const CustomSizedBox(
                        height: .035,
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: CustomPadding(
                            horizontal: .04,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const CustomText(
                                    text: "Login",
                                    fontSize: .023,
                                    fontWeight: FontWeight.w600),
                                const CustomSizedBox(
                                  height: .025,
                                ),
                                CustomTextFormField(
                                  textInputType: TextInputType.emailAddress,
                                  textCapitalization: TextCapitalization.none,
                                  controller: _phoneController,
                                  customPrefixWidget: IconButton(
                                    onPressed: () {},
                                    icon: CustomImage(
                                        image: AppImages.mail, height: .028),
                                  ),
                                  // prefixIcon: AppImages.phone,
                                  // prefixIconHeight: .024,
                                  hintText: "Enter your Email",
                                  hintFontSize: .016,
                                  // isEmailAdress: true,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Email is required';
                                    } else if (!value.trim().isValidEmail()) {
                                      return 'Enter a valid email address';
                                    }
                                    return null;
                                  },

                                  hintColor: const Color(0xFF1C1B29),
                                  fillColor: AppColors.tWhiteColor,
                                  borderRaduise: 25,
                                  maxLines: 1,

                                  customBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFC0C0C0),
                                      width: 1.2,
                                    ),
                                  ),
                                ),
                                const CustomSizedBox(
                                  height: .035,
                                ),
                                ActiveButton(
                                    height: Sizes.height * .06,
                                    width: Sizes.width,
                                    text: "Get OTP",
                                    borderRadius: 25,
                                    onPressed: () async {
                                      // if (_phoneController.text.isNotEmpty) {
                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();
                                      if (formKey.currentState!.validate()) {
                                        Provider.of<AuthenticationController>(
                                                context,
                                                listen: false)
                                            .loginApi(body: {
                                          "email": _phoneController.text
                                        });
                                        // _phoneController.text = '';
                                      }
                                      // }
                                    }),
                                const CustomSizedBox(
                                  height: .025,
                                ),
                                Platform.isIOS
                                    ? CustomPadding(
                                        top: .003,
                                        bottom: .02,
                                        child: ActiveButton(
                                            height: Sizes.height * .06,
                                            width: Sizes.width,
                                            text: "Skip Login",
                                            borderRadius: 25,
                                            onPressed: () async {
                                              await SharedPreferencesHelper()
                                                  .saveString(
                                                      "loginType", "skip");
                                              NavigateTo().pushRemove(
                                                  child: BottomNavigation(
                                                      initialIndex: 0));
                                            }),
                                      )
                                    : SizedBox.shrink(),
                                const Align(
                                  alignment: Alignment.center,
                                  child: CustomText(
                                      text: "Don't have an account?",
                                      fontSize: .018,
                                      fontWeight: FontWeight.w600),
                                ),
                                const CustomSizedBox(
                                  height: .055,
                                ),
                                Align(
                                  alignment: Alignment.center,
                                  child: CustomText(
                                    text: "Continue with",
                                    fontSize: .02,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const CustomSizedBox(
                                  height: .02,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    CustomTap(
                                      onTap: () {
                                        Provider.of<AuthenticationController>(
                                                context,
                                                listen: false)
                                            .signInWithGoogle(context);
                                      },
                                      child: CustomImage(
                                        image: AppImages.google,
                                        height: .04,
                                      ),
                                    ),
                                    CustomTap(
                                      onTap: () {
                                        Provider.of<AuthenticationController>(
                                                context,
                                                listen: false)
                                            .signInWithFacebook(context);
                                      },
                                      child: CustomImage(
                                        image: AppImages.facebook,
                                        height: .04,
                                      ),
                                    ),
                                    CustomTap(
                                      onTap: () async {
                                        Provider.of<AuthenticationController>(
                                                context,
                                                listen: false)
                                            .signInWithApple(context);
                                      },
                                      child: CustomImage(
                                        image: AppImages.apple,
                                        height: .04,
                                      ),
                                    ),
                                    CustomTap(
                                      onTap: () {
                                        NavigateTo().nextPage(
                                            child: const SignupScreen());
                                      },
                                      child: CustomImage(
                                        image: AppImages.mail,
                                        height: .04,
                                      ),
                                    ),
                                    CustomTap(
                                      onTap: () {
                                        SharedPreferencesHelper()
                                            .saveString("loginType", "skip");
                                        NavigateTo().pushRemove(
                                            child: BottomNavigation(
                                                initialIndex: 0));
                                      },
                                      child: CustomImage(
                                        image: AppImages.account,
                                        height: .04,
                                      ),
                                    ),
                                  ],
                                ),

                                // CustomBorderBtn(
                                //   height: Sizes.height * .055,
                                //   width: Sizes.width * .9,
                                //   text: "Continue with Google",
                                //   icon: CustomImage(
                                //     image: AppImages.google,
                                //     height: .02,
                                //   ),
                                //   onTap: () {
                                //     Provider.of<AuthenticationController>(
                                //             context,
                                //             listen: false)
                                //         .signInWithGoogle(context);
                                //   },
                                //   borderRadius: 25,
                                //   fontSize: .018,
                                //   borderColor: AppColors.tPrimaryColor,
                                //   textColor: AppColors.tBlackColor,
                                // ),
                                // const CustomSizedBox(
                                //   height: .02,
                                // ),

                                // CustomBorderBtn(
                                //   height: Sizes.height * .055,
                                //   width: Sizes.width * .9,
                                //   text: "Continue with Apple",
                                //   icon: CustomImage(
                                //     image: AppImages.apple,
                                //     height: .02,
                                //   ),
                                //   onTap: () async {
                                //     Provider.of<AuthenticationController>(
                                //             context,
                                //             listen: false)
                                //         .signInWithApple(context);
                                //   },
                                //   borderRadius: 25,
                                //   fontSize: .018,
                                //   borderColor: AppColors.tPrimaryColor,
                                //   textColor: AppColors.tBlackColor,
                                // ),
                                // // const CustomSizedBox(
                                // //   height: .02,
                                // // ),
                                // // CustomBorderBtn(
                                // //   height: Sizes.height * .055,
                                // //   width: Sizes.width * .9,
                                // //   text: "Continue with Apple",
                                // //   icon: CustomImage(
                                // //     image: AppImages.apple,
                                // //     height: .02,
                                // //   ),
                                // //   onTap: () async {
                                // //     Provider.of<AuthenticationController>(
                                // //             context,
                                // //             listen: false)
                                // //         .signInWithApple(context);
                                // //   },
                                // //   borderRadius: 25,
                                // //   fontSize: .018,
                                // //   borderColor: AppColors.tPrimaryColor,
                                // //   textColor: AppColors.tBlackColor,
                                // // ),
                                // const CustomSizedBox(
                                //   height: .02,
                                // ),
                                // CustomBorderBtn(
                                //   height: Sizes.height * .055,
                                //   width: Sizes.width * .9,
                                //   text: "Continue with Facebook",
                                //   icon: CustomImage(
                                //     image: AppImages.facebook,
                                //     height: .02,
                                //   ),
                                //   onTap: () {
                                //     Provider.of<AuthenticationController>(
                                //             context,
                                //             listen: false)
                                //         .signInWithFacebook(context);
                                //   },
                                //   borderRadius: 25,
                                //   fontSize: .018,
                                //   borderColor: AppColors.tPrimaryColor,
                                //   textColor: AppColors.tBlackColor,
                                // ),
                                // const CustomSizedBox(
                                //   height: .02,
                                // ),
                                // CustomBorderBtn(
                                //     height: Sizes.height * .055,
                                //     width: Sizes.width * .9,
                                //     text: "Continue with Email",
                                //     icon: CustomImage(
                                //       image: AppImages.mail,
                                //       height: .024,
                                //     ),
                                //     onTap: () {
                                //       NavigateTo().nextPage(
                                //           child: const SignupScreen());
                                //     },
                                //     borderRadius: 25,
                                //     fontSize: .018,
                                //     borderColor: AppColors.tPrimaryColor,
                                //     textColor: AppColors.tBlackColor),
                                // CustomSizedBox(
                                //   height: .02,
                                // ),
                                // CustomBorderBtn(
                                //     height: Sizes.height * .055,
                                //     width: Sizes.width * .9,
                                //     text: "Continue as Guest",
                                //     icon: CustomImage(
                                //       image: AppImages.account,
                                //       height: .024,
                                //     ),
                                //     onTap: () {
                                //       SharedPreferencesHelper()
                                //           .saveString("loginType", "skip");
                                //       NavigateTo().pushRemove(
                                //           child: BottomNavigation(
                                //               initialIndex: 0));
                                //     },
                                //     borderRadius: 25,
                                //     fontSize: .018,
                                //     borderColor: AppColors.tPrimaryColor,
                                //     textColor: AppColors.tBlackColor),
                                // const CustomSizedBox(
                                //   height: .02,
                                // ),
                              ],
                            )),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
