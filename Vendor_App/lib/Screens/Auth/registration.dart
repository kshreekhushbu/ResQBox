import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:resqboxvendor/Controller/KitchenRegistrationController.dart';
import 'package:resqboxvendor/Controller/AuthController.dart'; // Added AuthController
import 'package:resqboxvendor/Utils/shared_preference_helper.dart'; // Added SharedPreferencesHelper
import 'package:resqboxvendor/Screens/Auth/location_picker.dart';
import 'package:resqboxvendor/Screens/Auth/login_screen.dart';
import 'package:resqboxvendor/Screens/Auth/registration_success.dart';
import 'package:resqboxvendor/Utils/colors.dart';
import 'package:resqboxvendor/Utils/custom_appbar.dart';
import 'package:resqboxvendor/Utils/custom_border_btn.dart';

import 'package:resqboxvendor/Utils/dashed_border.dart';
import 'package:resqboxvendor/Utils/images.dart';
import 'package:resqboxvendor/Utils/navigations.dart';
import 'package:resqboxvendor/Utils/text_field.dart';
import 'package:resqboxvendor/Utils/textstyles.dart';
import 'package:resqboxvendor/Utils/toast.dart';
import 'package:resqboxvendor/Services/api.dart';
import 'package:flutter/services.dart';
import 'package:resqboxvendor/Utils/image_upload_selection_bottomsheet.dart'; // Added Import
import 'package:resqboxvendor/Utils/custom_alert.dart';

class KitchenRegistration extends StatefulWidget {
  const KitchenRegistration({super.key});

  @override
  State<KitchenRegistration> createState() => _KitchenRegistrationState();
}

class _KitchenRegistrationState extends State<KitchenRegistration> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalSteps = 4;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final TextEditingController _cuisineDisplayController =
      TextEditingController();
  final TextEditingController _timezoneController = TextEditingController();
  final FocusNode _confirmPasswordFocusNode = FocusNode();
  String? _confirmPasswordError;
  String? _emailError; // Real-time email validation error
  int _descriptionLength = 0; // Track description length for counter
  bool _showImageErrors =
      false; // Track if we should show image validation errors

  // Form keys for validation on each page
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(); // Page 1
  final GlobalKey<FormState> _formKeyPage2 = GlobalKey<FormState>(); // Page 2
  final GlobalKey<FormState> _formKeyPage4 = GlobalKey<FormState>(); // Page 4

  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled; // Page 1
  AutovalidateMode _autovalidateModeP2 = AutovalidateMode.disabled; // Page 2
  AutovalidateMode _autovalidateModeP4 = AutovalidateMode.disabled; // Page 4

  bool _hasCapital = false;
  bool _hasSmall = false;
  bool _hasSpecial = false;
  bool _hasNumber = false;
  bool _hasMinLength = false;
  KitchenRegistrationController? _registrationController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _registrationController = Provider.of<KitchenRegistrationController>(
      context,
      listen: false,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadCuisines();
    _confirmPasswordFocusNode.addListener(() {
      if (!_confirmPasswordFocusNode.hasFocus) {
        _validateConfirmPassword();
      }
    });
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

  // Helper method to build label with red asterisk for required fields
  Widget _buildRequiredLabel(String text) {
    return RichText(
      text: TextSpan(
        text: text,
        style: AppTextStyles.size16Medium.copyWith(color: Colors.black),
        children: [
          TextSpan(
            text: ' *',
            style: AppTextStyles.size14Medium.copyWith(color: Colors.red),
          ),
        ],
      ),
    );
  }

  @override
  @override
  void dispose() {
    try {
      _registrationController?.clearAllFields();
    } catch (e) {
      debugPrint("❌ Error clearing registration fields: $e");
    }

    _cuisineDisplayController.dispose();
    _timezoneController.dispose();
    _confirmPasswordFocusNode.dispose();
    _pageController.dispose();
    super.dispose();
  }

  bool _canExit = false;

  void _validateConfirmPassword() {
    final controller = Provider.of<KitchenRegistrationController>(
      context,
      listen: false,
    );
    if (controller.confirmPasswordController.text !=
        controller.passwordController.text) {
      setState(() {
        _confirmPasswordError = "Passwords do not match";
      });
    } else {
      setState(() {
        _confirmPasswordError = null;
      });
    }
  }

  Future<void> _showExitConfirmation() async {
    showAlertDialog(
      context: context,
      title: "Quit Registration",
      content:
          "Do you want to quit registration? All entered data will be lost.",
      onPressed: () async {
        Navigator.pop(context); // Pop dialog
        setState(() {
          _canExit = true;
        });

        try {
          final authController = Provider.of<AuthController>(
            context,
            listen: false,
          );
          await authController.logout(context);
        } catch (e) {
          debugPrint("Error accessing AuthController: $e");
          final prefernce = await SharedPreferencesHelper.getInstance();
          await prefernce.clearAlldata();
        }

        // NavigateTo().backPage();
        NavigateTo().pushRemove(child: const LoginScreen());
      },
    );
  }

  void _handleBackNavigation() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _showExitConfirmation();
    }
  }

  void _loadCuisines() {
    final controller = Provider.of<KitchenRegistrationController>(
      context,
      listen: false,
    );
    controller.getCuisines();
    controller.getFoodTypes();
    controller.getTimezones();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _canExit,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _handleBackNavigation();
      },
      child: Scaffold(
        backgroundColor: AppColors.tWhiteColor,
        appBar: CustomAppBar(
          title: "Register your Kitchen",
          isLeading: _currentPage > 0 ? true : false,
          backTap: () {
            _handleBackNavigation();
          },
          actions: [
            GestureDetector(
              onTap: () {
                _showExitConfirmation();
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: AppColors.mainAppColr),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  "Step ${_currentPage + 1} / $_totalSteps",
                  style: AppTextStyles.size12Regular,
                ),
              ),
            ),
            const SizedBox(width: 5),
          ],
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              height: 1,
              color: const Color(0xffD5D5D5),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(
                      value: (_currentPage + 1) / _totalSteps,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xffFE5E00),
                      ),
                      minHeight: 13,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    SizedBox(height: 22),
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: NeverScrollableScrollPhysics(),
                        onPageChanged: (index) {
                          setState(() {
                            _currentPage = index;
                          });
                        },
                        children: [
                          _enterKitchenDetails(),
                          _enterKitchenContactDetails(),
                          _uploadKitchenImages(),
                          _enterKYCDetails(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _currentPage == 0
              ? CustomRectBtn(
                  borderRadius: 35,
                  color: AppColors.mainAppColr,
                  borderColor: AppColors.mainAppColr,
                  height: 49,
                  width: double.infinity,
                  text: "Next",
                  onTap: () async {
                    final controller =
                        Provider.of<KitchenRegistrationController>(
                          context,
                          listen: false,
                        );

                    // Validate form fields (including email format)
                    if (!_formKey.currentState!.validate()) {
                      // Enable auto-validation after first failed attempt
                      setState(() {
                        _autovalidateMode = AutovalidateMode.onUserInteraction;
                      });
                      return;
                    }

                    // Validate kitchen details
                    if (!controller.validateKitchenDetails()) {
                      return;
                    }

                    // NEW: Validate Password Strength Logic
                    if (!_hasCapital ||
                        !_hasSmall ||
                        !_hasNumber ||
                        !_hasSpecial ||
                        !_hasMinLength) {
                      customToast(
                        message: "Please meet all password requirements",
                      );
                      return;
                    }

                    // Validate email on first page
                    final email = controller.emailController.text.trim();

                    // Check if email is empty
                    if (email.isEmpty) {
                      customToast(message: "Please enter your email address");
                      return;
                    }

                    // Check if email validation is still in progress
                    if (controller.isCheckingEmail) {
                      customToast(
                        message: "Please wait while we verify your email",
                      );
                      return;
                    }

                    debugPrint(
                      "🔍 Email validation message: ${controller.emailValidationMessage}",
                    );

                    // Check if email already exists - PREVENT NAVIGATION
                    if (controller.emailValidationMessage != null &&
                        (controller.emailValidationMessage!
                                .toLowerCase()
                                .contains("already exists") ||
                            controller.emailValidationMessage!.contains("❌"))) {
                      customToast(
                        message:
                            "This email is already registered. Please use a different email.",
                      );
                      return; // DON'T navigate if email exists
                    }

                    // Proceed to next page only if email is valid
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  },
                  textColor: Colors.white,
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CustomRectBtn(
                      borderRadius: 35,
                      color: AppColors.tWhiteColor,
                      borderColor: AppColors.mainAppColr,
                      height: 49,
                      width: MediaQuery.of(context).size.width / 2.5,
                      text: "Back",
                      onTap: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      },
                      textColor: Colors.black,
                    ),
                    Consumer<KitchenRegistrationController>(
                      builder: (context, controller, child) {
                        return CustomRectBtn(
                          borderRadius: 35,
                          color: AppColors.mainAppColr,
                          borderColor: AppColors.mainAppColr,
                          height: 49,
                          width: MediaQuery.of(context).size.width / 2.5,
                          text: _currentPage == _totalSteps - 1
                              ? "Submit"
                              : "Next",
                          onTap: controller.isLoading
                              ? () {} // Disable button when loading
                              : () async {
                                  final controller =
                                      Provider.of<
                                        KitchenRegistrationController
                                      >(context, listen: false);

                                  if (_currentPage == 1) {
                                    // Validate contact details form first
                                    if (!_formKeyPage2.currentState!
                                        .validate()) {
                                      setState(() {
                                        _autovalidateModeP2 =
                                            AutovalidateMode.onUserInteraction;
                                      });
                                      return;
                                    }
                                    // Then validate contact details logic
                                    if (controller.validateContactDetails()) {
                                      _pageController.nextPage(
                                        duration: const Duration(
                                          milliseconds: 400,
                                        ),
                                        curve: Curves.easeInOut,
                                      );
                                    }
                                  } else if (_currentPage == 2) {
                                    // Validate images
                                    if (controller.validateImages()) {
                                      _pageController.nextPage(
                                        duration: const Duration(
                                          milliseconds: 400,
                                        ),
                                        curve: Curves.easeInOut,
                                      );
                                    }
                                  } else if (_currentPage == 3) {
                                    // Validate KYC Form first
                                    if (!_formKeyPage4.currentState!
                                        .validate()) {
                                      setState(() {
                                        _autovalidateModeP4 =
                                            AutovalidateMode.onUserInteraction;
                                      });
                                      return;
                                    }

                                    // Validate KYC and submit
                                    if (controller.validateKYC()) {
                                      bool success;
                                      if (controller.isReapplying) {
                                        success = await controller
                                            .reapplyKitchen();
                                      } else {
                                        success = await controller
                                            .registerKitchen();
                                      }
                                      if (success && mounted) {
                                        NavigateTo().nextPage(
                                          child: RegistrationSuccess(),
                                        );
                                      }
                                    }
                                  }
                                },
                          leading: controller.isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : null,
                          textColor: Colors.white,
                        );
                      },
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _enterKitchenDetails() {
    final controller = Provider.of<KitchenRegistrationController>(context);

    // Sync text controller with selected cuisines
    final selectedNames = controller.selectedCuisines
        .map((e) => e.name)
        .join(", ");
    if (_cuisineDisplayController.text != selectedNames) {
      _cuisineDisplayController.text = selectedNames;
    }

    // Sync timezone controller
    if (controller.selectedTimezone != null &&
        _timezoneController.text != controller.selectedTimezone!.displayName) {
      _timezoneController.text = controller.selectedTimezone!.displayName;
    }

    return Form(
      key: _formKey,
      autovalidateMode: _autovalidateMode, // Only validate after first submit
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                text: "Enter Your ",
                style: AppTextStyles.size20SemiBold.copyWith(
                  color: Colors.black,
                ),
                children: [
                  TextSpan(
                    text: "Kitchen Details",
                    style: AppTextStyles.size20Bold.copyWith(
                      color: AppColors.mainAppColr,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),
            _buildRequiredLabel("Kitchen Name"),
            SizedBox(height: 10),

            CustomTextFormField(
              isfilled: true,
              controller: controller.kitchenNameController,
              hintText: "Enter Your Kitchen Name",
              maxLength: 30,
              isRequired: true,
            ),
            SizedBox(height: 20),
            _buildRequiredLabel("Email"),
            SizedBox(height: 10),
            CustomTextFormField(
              isfilled: true,
              controller: controller.emailController,
              hintText: "Enter Your Email",
              isEmail: true,
              isRequired: true,
              errorText: _emailError, // Show real-time error
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'\s')), // Deny spaces
              ],
              onChanged: (value) {
                // Real-time email validation
                setState(() {
                  if (value.trim().isEmpty) {
                    _emailError = null; // Don't show error for empty field
                  } else if (value.split('@').length != 2) {
                    _emailError = 'Enter a valid email';
                  } else if (!RegExp(
                    r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
                  ).hasMatch(value.trim())) {
                    _emailError = 'Enter a valid email';
                  } else {
                    _emailError = null; // Valid email
                  }
                });

                // Debounce email check - wait 800ms after user stops typing
                Future.delayed(Duration(milliseconds: 800), () {
                  if (controller.emailController.text == value) {
                    controller.checkEmailExists(value);
                  }
                });
              },
            ),
            if (controller.emailValidationMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    if (controller.isCheckingEmail)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Text(
                        controller.emailValidationMessage!,
                        style: AppTextStyles.size12Regular.copyWith(
                          color:
                              controller.emailValidationMessage!.contains("✅")
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                  ],
                ),
              ),
            SizedBox(height: 20),
            _buildRequiredLabel("Password"),
            SizedBox(height: 10),
            CustomTextFormField(
              isfilled: true,
              controller: controller.passwordController,
              hintText: "Enter Your Password",
              obscureText: _obscurePassword,
              onChanged: _checkPassword,
              isRequired: true,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xff777777),
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),

            SizedBox(height: 20),
            _buildRequiredLabel("Confirm Password"),
            SizedBox(height: 10),
            CustomTextFormField(
              isfilled: true,
              controller: controller.confirmPasswordController,
              focusNode: _confirmPasswordFocusNode,
              hintText: "Enter Your Confirm Password",
              errorText: _confirmPasswordError,
              obscureText: _obscureConfirmPassword,
              isRequired: true,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: const Color(0xff777777),
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
            ),

            // Validation Checklist
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
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
                  _buildValidationRow("At least 1 lowercase (a-z)", _hasSmall),
                  _buildValidationRow(
                    "At least 1 special character (@-/\$)",
                    _hasSpecial,
                  ),
                  _buildValidationRow("At least 1 Number (0-9)", _hasNumber),
                ],
              ),
            ),

            SizedBox(height: 20),
            _buildRequiredLabel("Owner/Chef Name"),
            SizedBox(height: 10),
            CustomTextFormField(
              isfilled: true,
              controller: controller.ownerNameController,
              hintText: "Enter Restaurant Owner/Chef Name",
              maxLength: 30,
              isRequired: true,
            ),
            SizedBox(height: 20),
            _buildRequiredLabel("Restaurant Category"),
            SizedBox(height: 10),
            Consumer<KitchenRegistrationController>(
              builder: (context, controller, child) {
                if (controller.isLoadingCuisines) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.mainAppColr,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "Loading cuisines...",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (controller.cuisines.isEmpty) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      "No cuisines available",
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  );
                }

                return CustomTextFormField(
                  isfilled: true,
                  controller: _cuisineDisplayController,
                  hintText: "Select Restaurant Category",
                  isEditable: false, // Make it read-only
                  suffixIcon: Icon(Icons.arrow_drop_down, color: Colors.grey),
                  onTap: () {
                    if (controller.isLoadingCuisines) {
                      customToast(message: "Loading cuisines, please wait...");
                    } else if (controller.cuisines.isEmpty) {
                      controller.getCuisines();
                    } else {
                      _showCuisineSelectionSheet(context);
                    }
                  },
                );
              },
            ),
            SizedBox(height: 20),
            _buildRequiredLabel("Description"),
            SizedBox(height: 10),
            CustomTextFormField(
              isfilled: true,
              maxLength: 200,
              // minLength: 30,
              minlines: 5,
              maxlines: 5,
              controller: controller.descriptionController,
              hintText: "Enter Description",
              isRequired: true,
              onChanged: (value) {
                setState(() {
                  _descriptionLength = value.length;
                });
              },
            ),
            // Character counter
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 4.0, right: 4.0),
                child: Text(
                  "$_descriptionLength/200",
                  style: AppTextStyles.size12Regular.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildRequiredLabel("Time Zone"),
            const SizedBox(height: 10),
            CustomTextFormField(
              isfilled: true,
              controller: _timezoneController,
              hintText: "Select Time Zone",
              isEditable: false,
              suffixIcon: const Icon(
                Icons.arrow_drop_down,
                color: Color(0xffD0D5DD),
              ),
              onTap: () {
                if (controller.timezones.isEmpty) {
                  controller.getTimezones().then((_) {
                    if (context.mounted) {
                      _showTimezoneSelectionSheet(context, controller);
                    }
                  });
                } else {
                  _showTimezoneSelectionSheet(context, controller);
                }
              },
              isRequired: true,
            ),
            SizedBox(height: 20),
            Consumer<KitchenRegistrationController>(
              builder: (context, controller, child) {
                if (controller.isLoadingFoodTypes) {
                  return Center(child: CircularProgressIndicator());
                }

                if (controller.foodTypes.isEmpty) {
                  return SizedBox.shrink();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRequiredLabel("Kitchen Types"),
                    SizedBox(height: 10),
                    ...controller.foodTypes.map((foodType) {
                      return Container(
                        // margin: EdgeInsets.only(bottom: 2),
                        // padding: EdgeInsets.only(
                        //   right: 6,
                        //   left: 6,
                        //   top: 2,
                        //   bottom: 2,
                        // ),
                        decoration: BoxDecoration(color: Colors.white),
                        child: Row(
                          children: [
                            Radio<bool>(
                              value: true,
                              groupValue:
                                  controller.foodTypeAnswers[foodType.id],
                              activeColor: AppColors.mainAppColr,
                              onChanged: (val) {
                                if (val != null) {
                                  controller.setFoodTypeAnswer(foodType, val);
                                }
                              },
                            ),
                            Expanded(
                              child: Text(
                                foodType.question ?? foodType.name,
                                style: AppTextStyles.size14Medium,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                );
              },
            ),
            // SizedBox(height: 10),
            Row(
              children: [
                // Checkbox(
                //   value: controller.noneOfTheAbove,
                //   activeColor: AppColors.mainAppColr,
                //   onChanged: (value) {
                //     controller.setNoneOfTheAbove(value!);
                //   },
                // ),
                Radio<bool>(
                  value: true,
                  groupValue: controller.noneOfTheAbove,
                  activeColor: AppColors.mainAppColr,
                  onChanged: (val) {
                    if (val != null) {
                      controller.setNoneOfTheAbove(val);
                    }
                  },
                ),
                Expanded(
                  child: Text(
                    "Please select this if you don't belong to any of the above",
                    style: AppTextStyles.size14Medium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTimezoneSelectionSheet(
    BuildContext context,
    KitchenRegistrationController controller,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Text(
                        "Select Time Zone",
                        style: AppTextStyles.size18Medium.copyWith(
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: controller.timezones.length,
                    itemBuilder: (context, index) {
                      final timezone = controller.timezones[index];
                      final isSelected =
                          controller.selectedTimezone?.id == timezone.id;

                      return ListTile(
                        title: Text(
                          timezone.displayName,
                          style: AppTextStyles.size14Medium.copyWith(
                            color: isSelected
                                ? AppColors.mainAppColr
                                : Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          "Offset: ${timezone.offset}",
                          style: AppTextStyles.size12Regular.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle,
                                color: AppColors.mainAppColr,
                              )
                            : null,
                        onTap: () {
                          controller.setSelectedTimezone(timezone);
                          _timezoneController.text = timezone.displayName;
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCuisineSelectionSheet(BuildContext context) {
    final controller = Provider.of<KitchenRegistrationController>(
      context,
      listen: false,
    );
    // Create a local set of selected IDs for the sheet state
    List<Cuisine> tempSelectedCuisines = List.from(controller.selectedCuisines);
    String searchQuery = "";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Filter cuisines based on search query
            final filteredCuisines = controller.cuisines.where((cuisine) {
              return cuisine.name.toLowerCase().contains(
                searchQuery.toLowerCase(),
              );
            }).toList();

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Select Categories",
                        style: AppTextStyles.size18SemiBold,
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  Text(
                    "You can select up to 5 categories",
                    style: AppTextStyles.size12Regular.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 15),

                  TextFormField(
                    decoration: InputDecoration(
                      hintText: "Search categories...",
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                  SizedBox(height: 10),

                  Expanded(
                    child: filteredCuisines.isEmpty
                        ? Center(child: Text("No cuisines found"))
                        : ListView.builder(
                            itemCount: filteredCuisines.length,
                            itemBuilder: (context, index) {
                              final cuisine = filteredCuisines[index];
                              final isSelected = tempSelectedCuisines.any(
                                (c) => c.id == cuisine.id,
                              );

                              return CheckboxListTile(
                                title: Text(cuisine.name),
                                value: isSelected,
                                activeColor: AppColors.mainAppColr,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      if (tempSelectedCuisines.length >= 5) {
                                        customToast(
                                          message:
                                              "You can only select up to 5 categories",
                                        );
                                      } else {
                                        tempSelectedCuisines.add(cuisine);
                                      }
                                    } else {
                                      tempSelectedCuisines.removeWhere(
                                        (c) => c.id == cuisine.id,
                                      );
                                    }
                                  });
                                },
                              );
                            },
                          ),
                  ),
                  SizedBox(height: 10),
                  CustomRectBtn(
                    borderRadius: 35,
                    color: AppColors.mainAppColr,
                    borderColor: AppColors.mainAppColr,
                    height: 50,
                    width: double.infinity,
                    text: "Done",
                    onTap: () {
                      controller.setSelectedCuisines(tempSelectedCuisines);
                      _cuisineDisplayController.text = tempSelectedCuisines
                          .map((e) => e.name)
                          .join(", ");
                      Navigator.pop(context);
                    },
                    textColor: Colors.white,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _enterKitchenContactDetails() {
    final controller = Provider.of<KitchenRegistrationController>(context);
    return Form(
      key: _formKeyPage2,
      autovalidateMode: _autovalidateModeP2,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                text: "Enter Your ",
                style: AppTextStyles.size20SemiBold.copyWith(
                  color: Colors.black,
                ),
                children: [
                  TextSpan(
                    text: "Kitchen Contact Details",
                    style: AppTextStyles.size20Bold.copyWith(
                      color: AppColors.mainAppColr,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),
            _buildRequiredLabel("Contact Number"),
            SizedBox(height: 10),
            CustomTextFormField(
              isfilled: true,
              controller: controller.contactNumberController,
              hintText: "Enter Contact Number",
              isMobile: true,
              isRequired: true,
            ),
            SizedBox(height: 20),
            _buildRequiredLabel("Operating Hours"),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Opening Time", style: AppTextStyles.size12Regular),
                      SizedBox(height: 10),
                      GestureDetector(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null && mounted) {
                            setState(() {
                              controller.openingTimeController.text = time
                                  .format(context);
                            });
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  controller.openingTimeController.text.isEmpty
                                      ? "Select Time"
                                      : controller.openingTimeController.text,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color:
                                        controller
                                            .openingTimeController
                                            .text
                                            .isEmpty
                                        ? Colors.grey[400]
                                        : Colors.black,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.access_time,
                                size: 18,
                                color: Colors.grey[600],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Closing time", style: AppTextStyles.size12Regular),
                      SizedBox(height: 10),
                      GestureDetector(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null && mounted) {
                            // Validate that closing time is greater than opening time
                            if (controller
                                .openingTimeController
                                .text
                                .isNotEmpty) {
                              // Parse opening time (format: "2:30 PM")
                              final openingTimeStr =
                                  controller.openingTimeController.text;
                              final openingTime = _parseTimeOfDay(
                                openingTimeStr,
                              );

                              if (openingTime != null) {
                                final openingMinutes =
                                    openingTime.hour * 60 + openingTime.minute;
                                final closingMinutes =
                                    time.hour * 60 + time.minute;

                                if (closingMinutes <= openingMinutes) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Closing time must be greater than opening time',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                              }
                            }

                            setState(() {
                              controller.closingTimeController.text = time
                                  .format(context);
                            });
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  controller.closingTimeController.text.isEmpty
                                      ? "Select Time"
                                      : controller.closingTimeController.text,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color:
                                        controller
                                            .closingTimeController
                                            .text
                                            .isEmpty
                                        ? Colors.grey[400]
                                        : Colors.black,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.access_time,
                                size: 18,
                                color: Colors.grey[600],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            _buildRequiredLabel("Address"),
            SizedBox(height: 10),
            Consumer<KitchenRegistrationController>(
              builder: (context, controller, child) {
                return CustomTextFormField(
                  isfilled: true,
                  isEditable: false,
                  suffixImg: AppImages.locate,
                  controller: controller.addressController,
                  isRequired: true,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LocationPickerScreen(),
                      ),
                    );
                    // Address will be updated via controller.setAddressDetails
                    // Consumer will automatically rebuild when controller notifies
                  },
                  hintText: "Choose Restaurant Address",
                );
              },
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _uploadKitchenImages() {
    final controller = Provider.of<KitchenRegistrationController>(context);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                text: "Upload ",
                style: AppTextStyles.size20SemiBold.copyWith(
                  color: Colors.black,
                ),
                children: [
                  TextSpan(
                    text: "Kitchen Photos",
                    style: AppTextStyles.size20Bold.copyWith(
                      color: AppColors.mainAppColr,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _buildRequiredLabel("Kitchen Images"),
            const SizedBox(height: 20),

            // 🔹 Image Grid (Clickable)
            GridView.builder(
              itemCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1.5,
              ),
              itemBuilder: (context, index) {
                // Determine image source
                ImageProvider? imageProvider;
                if (controller.kitchenImages[index] != null) {
                  imageProvider = FileImage(controller.kitchenImages[index]!);
                } else if (controller.isReapplying &&
                    controller.existingKitchenImages[index] != null &&
                    controller.existingKitchenImages[index]!.isNotEmpty) {
                  // Ensure full URL if needed, assuming API sends full or partial.
                  // If partial (filename), append base url. Assuming full for now or standard helper.
                  // The upload response usually gives filename. The retrieval usually gives full URL or filename.
                  // Let's assume full URL or modify if it breaks.
                  // Actually typical implementation: "${Api.baseUrl}${path}"
                  String path = controller.existingKitchenImages[index]!;
                  if (!path.startsWith("http")) {
                    path = "${Api.baseUrl}$path";
                    // Wait, usually uploads are in /uploads/ or similar and baseUrl ends in /api/.
                    // Let's check typical image usage in this project.
                    // No other usage visible in these files.
                    // Safest bet: check if it starts with http, if not prepend baseUrl (but remove 'api/' if present?)
                    // Actually, let's just use NetworkImage and if it fails, we know why.
                    // Adjust based on standard: usually image paths from DB are relative to public root.
                    // Let's try prepending baseUrl if no http.
                  }
                  imageProvider = NetworkImage(path);
                }

                return GestureDetector(
                  onTap: () {
                    ImagePickerBottomSheet.show(
                      context: context,
                      onImageSelected: (file) {
                        controller.setKitchenImage(index, file);
                        // Clear error when image is selected
                        setState(() {
                          _showImageErrors = false;
                        });
                      },
                    );
                  },
                  child: CustomDottedBorder(
                    borderRadius: 1,
                    gap: 4,
                    strokeWidth: 2,
                    color: _showImageErrors && imageProvider == null
                        ? Colors
                              .red // Red border if validation failed and no image
                        : AppColors.mainAppColr, // Normal color
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xffF9F9F9),
                        borderRadius: BorderRadius.circular(8),
                        image: imageProvider != null
                            ? DecorationImage(
                                image: imageProvider,
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: imageProvider == null
                          ? Center(
                              child: Image.asset(AppImages.cameraRegsitration),
                            )
                          : null,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 30),
            _buildRequiredLabel("Kitchen Profile Photo"),
            const SizedBox(height: 20),

            // 🔹 Kitchen Profile Photo Picker
            GestureDetector(
              onTap: () {
                ImagePickerBottomSheet.show(
                  context: context,
                  onImageSelected: (file) {
                    controller.setKitchenProfilePhoto(file);
                  },
                );
              },
              child: CustomDottedBorder(
                borderRadius: 1,
                gap: 4,
                strokeWidth: 2,
                color: AppColors.mainAppColr,
                child: Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xffF9F9F9),
                    borderRadius: BorderRadius.circular(8),
                    image: _getProfileImageProvider(controller) != null
                        ? DecorationImage(
                            image: _getProfileImageProvider(controller)!,
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _getProfileImageProvider(controller) == null
                      ? Center(child: Image.asset(AppImages.cameraRegsitration))
                      : null,
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _enterKYCDetails() {
    return Consumer<KitchenRegistrationController>(
      builder: (context, controller, child) {
        return Form(
          key: _formKeyPage4,
          autovalidateMode: _autovalidateModeP4,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    text: "Enter Your ",
                    style: AppTextStyles.size20SemiBold.copyWith(
                      color: Colors.black,
                    ),
                    children: [
                      TextSpan(
                        text: "Verification Details",
                        style: AppTextStyles.size20Bold.copyWith(
                          color: AppColors.mainAppColr,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30),
                _buildRequiredLabel("ABN Number"),
                SizedBox(height: 10),
                CustomTextFormField(
                  isfilled: true,
                  controller: controller.abnNumberController,
                  hintText: "Enter ABN Number",
                  isNumeric: true,
                  maxLength: 11,
                  isRequired: true,
                ),
                SizedBox(height: 20),
                Text("ACN (Optional)", style: AppTextStyles.size14Medium),
                SizedBox(height: 10),
                CustomTextFormField(
                  isfilled: true,
                  controller: controller.acnController,
                  hintText: "Enter ACN Number",
                  isNumeric: true,
                  maxLength: 9,
                ),
                SizedBox(height: 20),
                _buildRequiredLabel("Food Certificate Number"),
                SizedBox(height: 10),
                CustomTextFormField(
                  isfilled: true,
                  controller: controller.foodCertificateNumberController,
                  hintText: "Enter Food Certificate number",
                  isRequired: true,
                ),
                SizedBox(height: 20),
                _buildRequiredLabel("Expire Date"),
                SizedBox(height: 10),
                CustomTextFormField(
                  isfilled: true,
                  controller: controller.foodCertificateExpireDateController,
                  hintText: "YYYY-MM-DD",
                  isRequired: true, // Enable validation error text
                  isEditable: false,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (date != null) {
                      controller.foodCertificateExpireDateController.text =
                          DateFormat('dd-MM-yyyy').format(date);
                    }
                  },
                ),
                SizedBox(height: 20),
                _buildRequiredLabel("Food Certificate Image"),
                SizedBox(height: 10),
                CustomTextFormField(
                  isfilled: true,
                  controller: TextEditingController(
                    text: controller.foodCertificateImage != null
                        ? "Food Certificate Selected"
                        : "",
                  ),
                  hintText: "Upload Food certificate",
                  suffixImg: AppImages.upload,
                  isRequired: true, // Enable validation error text
                  isEditable: false,
                  onTap: () {
                    ImagePickerBottomSheet.show(
                      context: context,
                      onImageSelected: (file) {
                        controller.setFoodCertificateImage(file);
                      },
                    );
                  },
                ),
                const SizedBox(height: 15),

                // if (controller.isReapplying &&
                //     controller.existingFoodCertificateImage != null &&
                //     controller.existingFoodCertificateImage!.isNotEmpty &&
                //     controller.foodCertificateImage == null)
                //   Padding(
                //     padding: const EdgeInsets.only(top: 8.0),
                //     child: Text(
                //       "Existing certificate attached: ${controller.existingFoodCertificateImage!.split('/').last}",
                //       style: AppTextStyles.size12Regular.copyWith(
                //         color: Colors.green,
                //       ),
                //     ),
                //   ),
                SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  ImageProvider? _getProfileImageProvider(
    KitchenRegistrationController controller,
  ) {
    if (controller.kitchenProfilePhoto != null) {
      return FileImage(controller.kitchenProfilePhoto!);
    } else if (controller.isReapplying &&
        controller.existingKitchenProfilePhoto != null &&
        controller.existingKitchenProfilePhoto!.isNotEmpty) {
      String path = controller.existingKitchenProfilePhoto!;
      if (!path.startsWith("http")) {
        path = "${Api.baseUrl}$path";
      }
      return NetworkImage(path);
    }
    return null;
  }

  // Helper method to parse time string (e.g., "2:30 PM") to TimeOfDay
  TimeOfDay? _parseTimeOfDay(String timeStr) {
    try {
      final parts = timeStr.split(' ');
      if (parts.length != 2) return null;

      final timeParts = parts[0].split(':');
      if (timeParts.length != 2) return null;

      int hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final period = parts[1].toUpperCase();

      // Convert to 24-hour format
      if (period == 'PM' && hour != 12) {
        hour += 12;
      } else if (period == 'AM' && hour == 12) {
        hour = 0;
      }

      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return null;
    }
  }
}
