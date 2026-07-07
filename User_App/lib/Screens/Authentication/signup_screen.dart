import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:resqbox_user/Controllers/authentication_controller.dart';
import 'package:resqbox_user/Screens/Authentication/login_screen.dart';
import 'package:resqbox_user/Utils/active_btn.dart';
import 'package:resqbox_user/Utils/colors.dart';
import 'package:resqbox_user/Utils/custom_image_widget.dart';
import 'package:resqbox_user/Utils/custom_padding.dart';
import 'package:resqbox_user/Utils/custom_sizedbox.dart';
import 'package:resqbox_user/Utils/custom_tap.dart';
import 'package:resqbox_user/Utils/customtext.dart';
import 'package:resqbox_user/Utils/images.dart';
import 'package:resqbox_user/Utils/mediaquery.dart';
import 'package:resqbox_user/Utils/navigations.dart';
import 'package:resqbox_user/Utils/textformfield.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  String _completePhoneNumber = '';

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  static const String termsOfServiceUrl =
      'https://www.resqboxfood.com/terms-of-service';
  static const String privacyPolicyUrl =
      'https://www.resqboxfood.com/privacy-policy';

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $urlString');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.tWhiteColor,
      appBar: AppBar(
        backgroundColor: AppColors.tWhiteColor,
        elevation: 0,
        leading: CustomTap(
          onTap: () {
            NavigateTo().backPage();
          },
          child: const Icon(
            Icons.arrow_back_ios,
            color: AppColors.tTextColor,
            size: 26,
          ),
        ),
        centerTitle: true,
        title: const CustomImage(image: AppImages.logo, height: .063),
      ),
      body: Stack(
        children: [
          // Background images - rendered first (behind)
          IgnorePointer(
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  child: CustomImage(image: AppImages.line2, height: .3),
                ),
                Positioned(
                  top: Sizes.height * .4,
                  right: 0,
                  child: CustomImage(image: AppImages.line3, height: .4),
                ),
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: CustomImage(image: AppImages.loginbg, height: .21),
                ),
              ],
            ),
          ),
          // Form content - rendered second (on top)
          SafeArea(
            child: CustomPadding(
              top: .03,
              left: .045,
              right: .045,
              bottom: .02,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Align(
                        alignment: Alignment.center,
                        child: CustomText(
                          text: "Create your ResQBox Food account",
                          fontSize: .024,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const CustomSizedBox(height: .025),
                      const CustomText(
                        text:
                            "Join the community and start ordering from \nnearby kitchens.",
                        fontSize: .018,
                        letterSpacing: 0.8,
                        textAlign: TextAlign.center,
                        color: Color(0XFF4B5563),
                        fontWeight: FontWeight.w500,
                      ),
                      const CustomSizedBox(height: .048),
                      CustomTextFormField(
                        controller: _firstNameController,
                        prefixIcon: AppImages.name,
                        prefixIconHeight: .024,
                        hintText: "Enter First Name",
                        hintFontSize: .016,
                        maxxLength: 30,
                        maxLines: 1,
                        hintColor: const Color(0xFF1C1B29),
                        textAlign: TextAlign.start,
                        fillColor: AppColors.tWhiteColor,
                        // borderRaduise: 25,
                        customBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: const BorderSide(
                            color: Color(0xFFC0C0C0),
                            width: 1.2,
                          ),
                        ),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please Enter First Name';
                          }
                          return null;
                        },
                      ),
                      const CustomSizedBox(height: .02),
                      CustomTextFormField(
                        controller: _lastNameController,
                        prefixIcon: AppImages.name,
                        prefixIconHeight: .024,
                        hintText: "Enter Last Name",
                        hintFontSize: .016,
                        maxxLength: 30,
                        maxLines: 1,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please Enter Last Name';
                          }
                          return null;
                        },
                        hintColor: const Color(0xFF1C1B29),
                        fillColor: AppColors.tWhiteColor,
                        borderRaduise: 25,
                        customBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: const BorderSide(
                            color: Color(0xFFC0C0C0),
                            width: 1.2,
                          ),
                        ),
                      ),
                      const CustomSizedBox(height: .02),
                      CustomTextFormField(
                        controller: _emailController,
                        prefixIcon: AppImages.mail,
                        prefixIconHeight: .024,
                        hintText: "Enter Mail ID",
                        hintFontSize: .016,
                        textInputType: TextInputType.emailAddress,
                        textCapitalization: TextCapitalization.none,
                        hintColor: const Color(0xFF1C1B29),
                        fillColor: AppColors.tWhiteColor,
                        borderRaduise: 25,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email is required';
                          } else if (!value.trim().isValidEmail()) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                        customBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: const BorderSide(
                            color: Color(0xFFC0C0C0),
                            width: 1.2,
                          ),
                        ),
                      ),
                      const CustomSizedBox(height: .02),
                      IntlPhoneField(
                        controller: _phoneController,
                        style: customTextstyle(
                          color: const Color(0xFF1C1B29),
                          fontWeight: FontWeight.w600,
                          fontSize: .018,
                        ),
                        decoration: InputDecoration(
                          hintText: "Enter your Phone Number",
                          hintStyle: customTextstyle(
                            color: const Color(0xFF1C1B29),
                            fontWeight: FontWeight.w400,
                            fontSize: .016,
                          ),
                          counterText: "",
                          fillColor: AppColors.tWhiteColor,
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: const BorderSide(
                              color: Color(0xFFC0C0C0),
                              width: 1.2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: const BorderSide(
                              color: Color(0xFFC0C0C0),
                              width: 1.2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: const BorderSide(
                              color: Color(0xFFC0C0C0),
                              width: 1.2,
                            ),
                          ),
                        ),
                        initialCountryCode: 'AU',
                        onCountryChanged: (country) {
                          _phoneController.clear();
                          _completePhoneNumber = '+${country.dialCode}';
                        },
                        onChanged: (phone) {
                          _completePhoneNumber = phone.countryCode;
                          _phoneController.text = phone.number;
                        },
                        validator: (phone) {
                          if (phone == null || phone.number.isEmpty) {
                            return null;
                          }
                          return null;
                        },
                      ),
                      CustomPadding(
                        vertical: .035,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Checkbox(
                            //   value: _acceptTerms,
                            //   onChanged: (value) {
                            //     setState(() {
                            //       _acceptTerms = value ?? false;
                            //     });
                            //   },
                            //   activeColor: AppColors.tPrimaryColor,
                            //   side: const BorderSide(
                            //       color: AppColors.tPrimaryColor, width: 1),
                            //   materialTapTargetSize:
                            //       MaterialTapTargetSize.shrinkWrap,
                            //   visualDensity:
                            //       VisualDensity.compact, // 👈 key line
                            //   focusColor: AppColors.tPrimaryColor,
                            // ),
                            Expanded(
                              child: CustomPadding(
                                top: .005,
                                child: Text.rich(
                                  TextSpan(
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                    children: [
                                      const TextSpan(
                                        text: "By signing up you agree to our ",
                                      ),
                                      TextSpan(
                                        text: "terms of service",
                                        style: GoogleFonts.inter(
                                          color: Colors.green,
                                          fontWeight: FontWeight.w500,
                                          decoration: TextDecoration.underline,
                                          decorationColor: Colors.green,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () {
                                            _launchURL(termsOfServiceUrl);
                                          },
                                      ),
                                      const TextSpan(text: " and our "),
                                      TextSpan(
                                        text: "privacy policy",
                                        style: GoogleFonts.inter(
                                          color: Colors.green,
                                          fontWeight: FontWeight.w500,
                                          decoration: TextDecoration.underline,
                                          decorationColor: Colors.green,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () {
                                            _launchURL(privacyPolicyUrl);
                                          },
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                  softWrap: true,
                                  maxLines: 2, // ✅ forces 2 lines
                                  overflow: TextOverflow.visible,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ActiveButton(
                        height: Sizes.height * .06,
                        width: Sizes.width,
                        text: "Sign Up",
                        borderRadius: 25,
                        onPressed: () {
                          // if (_phoneController.text.isNotEmpty) {
                          if (formKey.currentState!.validate()) {
                            FocusManager.instance.primaryFocus?.unfocus();
                            // if (!_acceptTerms) {
                            //   customToast(
                            //       message:
                            //           "Please accept the terms and conditions");
                            //   return;
                            // }
                            debugPrint(
                                "${_phoneController.text}, ${_firstNameController.text}, ${_lastNameController.text}, ${_emailController.text}, ${_completePhoneNumber}  ");
                            Provider.of<AuthenticationController>(
                              context,
                              listen: false,
                            ).signUpVerifyOtpApi(
                              body: {"email": _emailController.text},
                              phoneNumber: _phoneController.text,
                              firstName: _firstNameController.text,
                              lastName: _lastNameController.text,
                              email: _emailController.text,
                              countryCode: _completePhoneNumber,
                            );
                            // // Provider.of<AuthenticationController>(context,
                            //         listen: false)
                            //     .signUpApi(body: {
                            //   "phoneNumber": _phoneController.text,
                            //   "firstName": _firstNameController.text,
                            //   "lastName": _lastNameController.text,
                            //   "email": _emailController.text,
                            //   "deviceToken": "jndnnsbdnbs cndbfnbnf"
                            // });
                          }
                          // }
                        },
                      ),
                      const CustomSizedBox(height: .02),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomText(
                            text: "Already have an account?",
                            fontSize: .018,
                            fontWeight: FontWeight.w600,
                          ),
                          const CustomSizedBox(width: .02),
                          CustomTap(
                            onTap: () {
                              NavigateTo().nextPage(child: const LoginScreen());
                            },
                            child: CustomText(
                              text: "Login",
                              fontSize: .019,
                              color: AppColors.tPrimaryColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      // const CustomSizedBox(height: .02),
                      // CustomBorderBtn(
                      //   height: Sizes.height * .055,
                      //   width: Sizes.width * .9,
                      //   text: "Login",
                      //   onTap: () {
                      //     NavigateTo().nextPage(child: const LoginScreen());
                      //   },
                      //   borderRadius: 25,
                      //   fontSize: .02,
                      //   borderColor: AppColors.tPrimaryColor,
                      //   textColor: AppColors.tBlackColor,
                      // ),
                      // const CustomSizedBox(height: .018),
                      const CustomSizedBox(
                        height: .025,
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
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          CustomTap(
                            onTap: () {
                              Provider.of<AuthenticationController>(context,
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
                              Provider.of<AuthenticationController>(context,
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
                              Provider.of<AuthenticationController>(context,
                                      listen: false)
                                  .signInWithApple(context);
                            },
                            child: CustomImage(
                              image: AppImages.apple,
                              height: .04,
                            ),
                          ),
                          // CustomTap(
                          //   onTap: () {
                          //     NavigateTo()
                          //         .nextPage(child: const SignupScreen());
                          //   },
                          //   child: CustomImage(
                          //     image: AppImages.mail,
                          //     height: .04,
                          //   ),
                          // ),
                          // CustomTap(
                          //   onTap: () {
                          //     SharedPreferencesHelper()
                          //         .saveString("loginType", "skip");
                          //     NavigateTo().pushRemove(
                          //         child: BottomNavigation(initialIndex: 0));
                          //   },
                          //   child: CustomImage(
                          //     image: AppImages.account,
                          //     height: .04,
                          //   ),
                          // ),
                        ],
                      ),
                      // CustomBorderBtn(
                      //   height: Sizes.height * .055,
                      //   width: Sizes.width * .9,
                      //   text: "Continue with Google",
                      //   icon: CustomImage(image: AppImages.google, height: .02),
                      //   onTap: () {
                      //     Provider.of<AuthenticationController>(
                      //       context,
                      //       listen: false,
                      //     ).signInWithGoogle(context);
                      //   },
                      //   borderRadius: 25,
                      //   fontSize: .018,
                      //   borderColor: AppColors.tPrimaryColor,
                      //   textColor: AppColors.tBlackColor,
                      // ),
                      // const CustomSizedBox(height: .018),
                      // CustomBorderBtn(
                      //   height: Sizes.height * .055,
                      //   width: Sizes.width * .9,
                      //   text: "Continue with Apple",
                      //   icon: CustomImage(
                      //     image: AppImages.apple,
                      //     height: .02,
                      //   ),
                      //   onTap: () async {
                      //     Provider.of<AuthenticationController>(context,
                      //             listen: false)
                      //         .signInWithApple(context);
                      //   },
                      //   borderRadius: 25,
                      //   fontSize: .018,
                      //   borderColor: AppColors.tPrimaryColor,
                      //   textColor: AppColors.tBlackColor,
                      // ),
                      // const CustomSizedBox(height: .018),
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
                      //       context,
                      //       listen: false,
                      //     ).signInWithFacebook(context);
                      //   },
                      //   borderRadius: 25,
                      //   fontSize: .018,
                      //   borderColor: AppColors.tPrimaryColor,
                      //   textColor: AppColors.tBlackColor,
                      // ),
                      // CustomSizedBox(
                      //   height: .02,p
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
                      //           child: BottomNavigation(initialIndex: 0));
                      //     },
                      //     borderRadius: 25,
                      //     fontSize: .018,
                      //     borderColor: AppColors.tPrimaryColor,
                      //     textColor: AppColors.tBlackColor),
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

extension EmailValidator on String {
  bool isValidEmail() {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(this);
  }
}
