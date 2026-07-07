import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resqboxvendor/Controller/AuthController.dart';
import 'package:resqboxvendor/Utils/colors.dart';
import 'package:resqboxvendor/Utils/custom_border_btn.dart';
import 'package:resqboxvendor/Utils/custom_image_widget.dart';
import 'package:resqboxvendor/Utils/images.dart';
import 'package:resqboxvendor/Utils/navigations.dart';
import 'package:resqboxvendor/Utils/text_field.dart';
import 'package:resqboxvendor/Utils/textstyles.dart';
import 'package:resqboxvendor/Utils/toast.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isOtpVerified = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _hasCapital = false;
  bool _hasSmall = false;
  bool _hasSpecial = false;
  bool _hasNumber = false;
  bool _hasMinLength = false;

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _checkPassword(String value) {
    setState(() {
      _hasCapital = value.contains(RegExp(r'[A-Z]'));
      _hasSmall = value.contains(RegExp(r'[a-z]'));
      _hasNumber = value.contains(RegExp(r'[0-9]'));
      _hasSpecial = value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
      _hasMinLength = value.length >= 8;
    });
  }

  Widget _buildValidationRow(String text, bool isValid) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.circle_outlined,
            color: isValid ? Colors.green : Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: AppTextStyles.size12Medium.copyWith(
              color: isValid ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // Step 1: Send OTP
  Future<void> _sendOTP() async {
    if (_emailController.text.trim().isEmpty) {
      customToast(message: "Please enter your email");
      return;
    }

    final authProvider = Provider.of<AuthController>(context, listen: false);
    final result = await authProvider.sendForgotPasswordOTP(
      _emailController.text.trim(),
    );

    if (result != null && result['success'] == true && mounted) {
      // Show OTP bottom sheet
      _showOtpBottomSheet();
    }
  }

  // Step 2: Show OTP Bottom Sheet
  void _showOtpBottomSheet() {
    final TextEditingController otpController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Verify OTP", style: AppTextStyles.size20SemiBold),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Text(
                "Enter the OTP sent to ${_emailController.text}",
                style: AppTextStyles.size14Medium.copyWith(
                  color: const Color(0xff777777),
                ),
              ),

              const SizedBox(height: 20),

              // OTP Input Field
              CustomTextFormFieldBorder(
                controller: otpController,
                isRequired: true,
                hintText: "Enter OTP",
                image: AppImages.lockTextField,
                isNumber: true,
              ),

              const SizedBox(height: 20),

              // Verify Button
              CustomRectBtn(
                borderRadius: 35,
                color: AppColors.mainAppColr,
                borderColor: AppColors.mainAppColr,
                height: 50,
                width: double.infinity,
                text: "Verify OTP",
                onTap: () async {
                  if (otpController.text.trim().isEmpty) {
                    customToast(message: "Please enter OTP");
                    return;
                  }

                  final authProvider = Provider.of<AuthController>(
                    context,
                    listen: false,
                  );
                  final result = await authProvider.verifyForgotPasswordOTP(
                    _emailController.text.trim(),
                    otpController.text.trim(),
                  );

                  if (result != null && result['success'] == true && mounted) {
                    Navigator.pop(context); // Close bottom sheet
                    setState(() {
                      _isOtpVerified = true;
                    });
                  }
                },
                textColor: Colors.white,
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // Step 3: Reset Password
  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      if (!_hasCapital ||
          !_hasSmall ||
          !_hasNumber ||
          !_hasSpecial ||
          !_hasMinLength) {
        customToast(message: "Please meet all password requirements");
        return;
      }

      if (_newPasswordController.text != _confirmPasswordController.text) {
        customToast(message: "Passwords do not match");
        return;
      }

      final authProvider = Provider.of<AuthController>(context, listen: false);
      final result = await authProvider.resetPassword(
        _emailController.text.trim(),
        _newPasswordController.text,
      );

      if (result != null && result['success'] == true && mounted) {
        // Navigate back to login screen
        NavigateTo().backPage();
        customToast(message: "Password reset successfully. Please login.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Form(
                key: _formKey,
                child: CustomScrollView(
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),

                          // Back Button
                          IconButton(
                            onPressed: () => NavigateTo().backPage(),
                            icon: const Icon(Icons.arrow_back),
                            padding: EdgeInsets.zero,
                            alignment: Alignment.centerLeft,
                          ),

                          // const SizedBox(height: 10),

                          // Logo
                          Center(
                            child: Image.asset(
                              AppImages.splashImage,
                              height: 120,
                              fit: BoxFit.contain,
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Title
                          Center(
                            child: Text(
                              "Forgot Password?",
                              textAlign: TextAlign.center,
                              style: AppTextStyles.size20SemiBold,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Center(
                            child: Text(
                              _isOtpVerified
                                  ? "Enter your new password"
                                  : "Enter your email to receive OTP",
                              style: AppTextStyles.size14Medium.copyWith(
                                color: const Color(0xff777777),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Email Field
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Email",
                              style: AppTextStyles.size14SemiBold,
                            ),
                          ),
                          const SizedBox(height: 5),

                          CustomTextFormFieldBorder(
                            controller: _emailController,
                            isRequired: true,
                            hintText: "Enter your Registered Email",
                            image: AppImages.phoneTextField,
                            isEditable:
                                !_isOtpVerified, // Disable after OTP verified
                          ),

                          const SizedBox(height: 20),

                          // Show password fields only after OTP verification
                          if (_isOtpVerified) ...[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "New Password",
                                style: AppTextStyles.size14SemiBold,
                              ),
                            ),
                            const SizedBox(height: 5),

                            CustomTextFormFieldBorder(
                              controller: _newPasswordController,
                              obscureText: _obscureNewPassword,
                              isRequired: true,
                              hintText: "Enter New Password",
                              image: AppImages.lockTextField,
                              onChanged: _checkPassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureNewPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureNewPassword = !_obscureNewPassword;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 10),

                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Confirm Password",
                                style: AppTextStyles.size14SemiBold,
                              ),
                            ),
                            const SizedBox(height: 5),

                            CustomTextFormFieldBorder(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              isRequired: true,
                              hintText: "Confirm New Password",
                              image: AppImages.lockTextField,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.only(
                                top: 8.0,
                                bottom: 8.0,
                              ),
                              child: Column(
                                children: [
                                  _buildValidationRow(
                                    "At least 8 characters Long",
                                    _hasMinLength,
                                  ),
                                  _buildValidationRow(
                                    "At least 1 uppercase (A-Z)",
                                    _hasCapital,
                                  ),
                                  _buildValidationRow(
                                    "At least 1 lowercase (a-z)",
                                    _hasSmall,
                                  ),
                                  _buildValidationRow(
                                    "At least 1 special character (@-/\$)",
                                    _hasSpecial,
                                  ),
                                  _buildValidationRow(
                                    "At least 1 Number (0-9)",
                                    _hasNumber,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),

                            // const SizedBox(height: 20),
                          ],

                          const Spacer(),

                          // Action Button
                          CustomRectBtn(
                            borderRadius: 35,
                            color: AppColors.mainAppColr,
                            borderColor: AppColors.mainAppColr,
                            height: 50,
                            width: double.infinity,
                            text: _isOtpVerified
                                ? "Reset Password"
                                : "Send OTP",
                            onTap: _isOtpVerified ? _resetPassword : _sendOTP,
                            textColor: Colors.white,
                          ),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
