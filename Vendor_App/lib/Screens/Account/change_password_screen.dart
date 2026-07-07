import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resqboxvendor/Controller/AuthController.dart';
import 'package:resqboxvendor/Utils/colors.dart';
import 'package:resqboxvendor/Utils/custom_appbar.dart';
import 'package:resqboxvendor/Utils/custom_border_btn.dart';
import 'package:resqboxvendor/Utils/images.dart';
import 'package:resqboxvendor/Utils/navigations.dart';
import 'package:resqboxvendor/Utils/text_field.dart';
import 'package:resqboxvendor/Utils/textstyles.dart';
import 'package:resqboxvendor/Utils/toast.dart';
import 'package:resqboxvendor/Utils/shared_preference_helper.dart';
import 'package:resqboxvendor/Screens/Auth/login_screen.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  bool _hasCapital = false;
  bool _hasSmall = false;
  bool _hasSpecial = false;
  bool _hasNumber = false;
  bool _hasMinLength = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
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

  Future<void> _changePassword() async {
    if (_formKey.currentState!.validate()) {
      // Validate password strength
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

      setState(() {
        _isLoading = true;
      });

      try {
        final authProvider = Provider.of<AuthController>(
          context,
          listen: false,
        );

        final result = await authProvider.resetOldPassword(
          _currentPasswordController.text.trim(),
          _newPasswordController.text.trim(),
        );

        if (result != null && result['success'] == true && mounted) {
          customToast(
            message: "Password changed successfully. Please login again.",
          );
          final prefs = await SharedPreferencesHelper.getInstance();
          await prefs.clearAlldata();
          NavigateTo().pushRemove(child: LoginScreen());
        }
      } catch (e) {
        // Error handling
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: "Change Password",
        isLeading: true,
        backTap: () {
          NavigateTo().backPage();
        },
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Current Password",
                      style: AppTextStyles.size14SemiBold,
                    ),
                  ),
                  const SizedBox(height: 5),

                  CustomTextFormFieldBorder(
                    controller: _currentPasswordController,
                    obscureText: _obscureCurrentPassword,
                    isRequired: true,
                    hintText: "Enter Current Password",
                    image: AppImages.lockTextField,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureCurrentPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureCurrentPassword = !_obscureCurrentPassword;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

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

                  const SizedBox(height: 20),

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
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // VALIDATION CHECKLIST
                  _buildValidationRow(
                    "At least 8 characters Long",
                    _hasMinLength,
                  ),
                  _buildValidationRow(
                    "At least 1 uppercase (A-Z)",
                    _hasCapital,
                  ),
                  _buildValidationRow("At least 1 lowercase (a-z)", _hasSmall),
                  _buildValidationRow(
                    "At least 1 special character (@-/\$)",
                    _hasSpecial,
                  ),
                  _buildValidationRow("At least 1 Number (0-9)", _hasNumber),

                  const SizedBox(height: 40), // Spacing before button

                  CustomRectBtn(
                    borderRadius: 35,
                    color: AppColors.mainAppColr,
                    borderColor: AppColors.mainAppColr,
                    height: 50,
                    width: double.infinity,
                    text: "Update Password",
                    leading: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : null,
                    onTap: _isLoading ? () {} : _changePassword,
                    textColor: Colors.white,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
}
