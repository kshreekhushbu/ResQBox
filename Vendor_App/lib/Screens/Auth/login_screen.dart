import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:resqboxvendor/Controller/AuthController.dart';
import 'package:resqboxvendor/Controller/DashboardController.dart';
import 'package:resqboxvendor/Controller/KitchenRegistrationController.dart';
import 'package:resqboxvendor/Screens/Auth/forgot_password_screen.dart';
import 'package:resqboxvendor/Screens/Auth/pending.dart';
import 'package:resqboxvendor/Screens/Auth/registration.dart';
import 'package:resqboxvendor/Screens/Auth/rejection.dart';
import 'package:resqboxvendor/Screens/bottomNavigation.dart';
import 'package:resqboxvendor/Utils/colors.dart';
import 'package:resqboxvendor/Utils/custom_border_btn.dart';
import 'package:resqboxvendor/Utils/custom_image_widget.dart';
import 'package:resqboxvendor/Utils/images.dart';
import 'package:resqboxvendor/Utils/navigations.dart';
import 'package:resqboxvendor/Utils/text_field.dart';
import 'package:resqboxvendor/Utils/textstyles.dart';

final GlobalKey<FormState> formKey = GlobalKey<FormState>();

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passController = TextEditingController();
  bool _obscurePassword = true; // Password visibility state

  @override
  void dispose() {
    emailController.dispose();
    passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthController>(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const CustomImage(
            image: AppImages.loginBg,
            width: double.infinity,
            fit: BoxFit.cover,
          ),

          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          const SizedBox(height: 20),

                          /// LOGO
                          Center(
                            child: Image.asset(
                              AppImages.splashImage,
                              height: 150,
                              fit: BoxFit.contain,
                            ),
                          ),

                          const SizedBox(height: 15),
                          Column(
                            children: [
                              Text(
                                "Welcome to ResQBox Food Kitchen!",
                                textAlign: TextAlign.center,
                                style: AppTextStyles.size20SemiBold,
                              ),

                              const SizedBox(height: 10),

                              Text(
                                "Manage your kitchen and serve your community",
                                style: AppTextStyles.size14Medium.copyWith(
                                  color: const Color(0xff777777),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),

                          Column(
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "Login",
                                  style: AppTextStyles.size14SemiBold,
                                ),
                              ),
                              SizedBox(height: 5),

                              CustomTextFormFieldBorder(
                                controller: emailController,
                                isRequired: true,
                                hintText: "Enter your Registered Mail ID",
                                image: AppImages.phoneTextField,
                              ),

                              const SizedBox(height: 15),

                              CustomTextFormFieldBorder(
                                controller: passController,
                                obscureText: _obscurePassword,
                                isRequired: true,
                                hintText: "Enter your Password",
                                image: AppImages.lockTextField,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: const Color(0xff777777),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),

                              const SizedBox(height: 15),

                              Align(
                                alignment: Alignment.centerLeft,
                                child: GestureDetector(
                                  onTap: () {
                                    NavigateTo().nextPage(
                                      child: const ForgotPasswordScreen(),
                                    );
                                  },
                                  child: Text(
                                    "Forgot Password?",
                                    style: AppTextStyles.size14Medium.copyWith(
                                      color: AppColors.mainAppColr,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          /// LOGIN BUTTON
                          CustomRectBtn(
                            borderRadius: 35,
                            color: AppColors.mainAppColr,
                            borderColor: AppColors.mainAppColr,
                            height: 50,
                            width: double.infinity,
                            text: "Login",
                            onTap: () async {
                              if (formKey.currentState!.validate()) {
                                authProvider.email.text = emailController.text;
                                authProvider.password.text =
                                    passController.text;
                                final result = await authProvider.login();

                                if (result != null &&
                                    result['success'] == true &&
                                    mounted) {
                                  // Check Kitchen Status
                                  final kitchenController =
                                      Provider.of<
                                        KitchenRegistrationController
                                      >(context, listen: false);
                                  await kitchenController.getKitchenStatus();

                                  if (!mounted) return;

                                  if (kitchenController.registrationStatus ==
                                      "APPROVED") {
                                    context.read<DashboardProvider>().setIndex(
                                      0,
                                    );
                                    NavigateTo().pushRemove(
                                      child: MainTabScreen(),
                                    );
                                  } else if (kitchenController
                                          .registrationStatus ==
                                      "REJECTED") {
                                    NavigateTo().pushReplacement(
                                      child: const RejectedScreen(),
                                    );
                                  } else {
                                    NavigateTo().pushReplacement(
                                      child: const PendingScreen(),
                                    );
                                  }
                                }
                              }
                            },
                            textColor: Colors.white,
                          ),
                          const SizedBox(height: 20),
                          Column(
                            children: [
                              Text(
                                "Don’t have an account?\nRegister your Restaurant",
                                textAlign: TextAlign.center,
                                style: AppTextStyles.size16SemiBold,
                              ),

                              const SizedBox(height: 10),

                              CustomRectBtn(
                                borderRadius: 35,
                                color: Colors.white,
                                borderColor: AppColors.mainAppColr,
                                height: 50,
                                width: double.infinity,
                                text: "Create Account",
                                onTap: () {
                                  NavigateTo().nextPage(
                                    child: KitchenRegistration(),
                                  );
                                },
                                textColor: Colors.black,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: AppTextStyles.size12Regular.copyWith(
                                color: const Color(0xff777777),
                              ),
                              children: [
                                const TextSpan(
                                  text: "By Continuing you agree to our\n",
                                ),
                                TextSpan(
                                  text: "Terms & Conditions",
                                  style: const TextStyle(
                                    color: AppColors.mainAppColr,
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () async {
                                      const url =
                                          'https://www.resqboxfood.com/vendor-terms';
                                      if (await canLaunchUrl(Uri.parse(url))) {
                                        await launchUrl(
                                          Uri.parse(url),
                                          mode: LaunchMode.externalApplication,
                                        );
                                      }
                                    },
                                ),
                                const TextSpan(text: " and "),
                                TextSpan(
                                  text: "Privacy policy",
                                  style: const TextStyle(
                                    color: AppColors.mainAppColr,
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () async {
                                      const url =
                                          'https://www.resqboxfood.com/privacy-policy';
                                      if (await canLaunchUrl(Uri.parse(url))) {
                                        await launchUrl(
                                          Uri.parse(url),
                                          mode: LaunchMode.externalApplication,
                                        );
                                      }
                                    },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 35),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
