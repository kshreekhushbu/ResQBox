import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:resqboxvendor/Controller/TeamController.dart';
import 'package:resqboxvendor/Utils/colors.dart';
import 'package:resqboxvendor/Utils/custom_appbar.dart';
import 'package:resqboxvendor/Utils/custom_border_btn.dart';
import 'package:resqboxvendor/Utils/navigations.dart';
import 'package:resqboxvendor/Utils/text_field.dart';
import 'package:resqboxvendor/Utils/textstyles.dart';

class AddTeamMember extends StatefulWidget {
  const AddTeamMember({super.key});

  @override
  State<AddTeamMember> createState() => _AddTeamMemberState();
}

class _AddTeamMemberState extends State<AddTeamMember> {
  bool _hasCapital = false;
  bool _hasSmall = false;
  bool _hasSpecial = false;
  bool _hasNumber = false;
  bool _hasMinLength = false;

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

  @override
  void initState() {
    super.initState();
    // Only reset form if not in edit mode
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<TeamController>(context, listen: false);
      if (!controller.isEditMode) {
        controller.resetForm();
      }
    });
  }

  Future<void> _handleAddTeamMember() async {
    final controller = Provider.of<TeamController>(context, listen: false);

    // Validate password if in Add mode
    if (!controller.isEditMode) {
      if (!_hasCapital ||
          !_hasSmall ||
          !_hasNumber ||
          !_hasSpecial ||
          !_hasMinLength) {
        // Import customToast if not available or use ScaffoldMessenger
        // customToast is imported from Utils/toast.dart based on imports
        // But wait, I can't call customToast without importing it if it's not in scope?
        // It is imported in line 15 of original file (not shown in snippet but likely there based on pattern)
        // Let me check imports first.
        // Imports show Utils/toast.dart is NOT imported in the snippet I saw earlier?
        // Wait, file view of add_team.dart showed imports:
        // 1: import 'package:flutter/material.dart';
        // ...
        // 9: import 'package:resqboxvendor/Utils/textstyles.dart';
        // It does NOT import toast.dart. I need to add that import too or use controller's toast mechanism?
        // controller uses customToast.
        // I will add import validation later or now?
        // Let's assume I can add import or usage.
        // Actually, I should check if customToast is available.
        // The snippet of add_team.dart did NOT show toast.dart import.
        // I will trust the user context or add it.
        // Actually, looking at previous step 226, lines 1-10:
        /*
            1: import 'package:flutter/material.dart';
            2: import 'package:provider/provider.dart';
            3: import 'package:resqboxvendor/Controller/TeamController.dart';
            4: import 'package:resqboxvendor/Utils/colors.dart';
            5: import 'package:resqboxvendor/Utils/custom_appbar.dart';
            6: import 'package:resqboxvendor/Utils/custom_border_btn.dart';
            7: import 'package:resqboxvendor/Utils/navigations.dart';
            8: import 'package:resqboxvendor/Utils/text_field.dart';
            9: import 'package:resqboxvendor/Utils/textstyles.dart';
         */
        // Correct, no toast import. I should add `import 'package:resqboxvendor/Utils/toast.dart';`

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please meet all password requirements")),
        );
        return;
      }
    }

    bool success;
    if (controller.isEditMode && controller.selectedTeamMember != null) {
      success = await controller.updateTeamMember(
        controller.selectedTeamMember!.id!,
      );
    } else {
      success = await controller.addTeamMember();
    }
    if (success && mounted) {
      NavigateTo().backPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TeamController>(
      builder: (context, controller, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: CustomAppBar(
            title: controller.isEditMode
                ? "Edit Team Member"
                : "Add Team Member",
            isLeading: true,
            backTap: () {
              controller.resetForm();
              NavigateTo().backPage();
            },
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Consumer<TeamController>(
                    builder: (context, controller, child) {
                      return Center(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                controller.pickProfilePhoto();
                              },
                              child: Stack(
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFFE0E0E0),
                                    ),
                                    child: controller.profilePhoto != null
                                        ? ClipOval(
                                            child: Image.file(
                                              controller.profilePhoto!,
                                              width: 100,
                                              height: 100,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : controller.displayedProfilePhotoUrl !=
                                              null
                                        ? ClipOval(
                                            child: Image.network(
                                              controller
                                                  .displayedProfilePhotoUrl!,
                                              width: 100,
                                              height: 100,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return const Icon(
                                                      Icons.person,
                                                      size: 50,
                                                      color: Colors.white,
                                                    );
                                                  },
                                            ),
                                          )
                                        : const Icon(
                                            Icons.person,
                                            size: 50,
                                            color: Colors.white,
                                          ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xffF1913D),
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Upload picture",
                              style: AppTextStyles.size14Medium.copyWith(
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 30),

                  // First Name
                  Text("First Name", style: AppTextStyles.size14Medium),
                  const SizedBox(height: 10),
                  Consumer<TeamController>(
                    builder: (context, controller, child) {
                      return CustomTextFormField(
                        isfilled: true,
                        controller: controller.firstNameController,
                        hintText: "Enter First Name",
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Last Name
                  Text("Last Name", style: AppTextStyles.size14Medium),
                  const SizedBox(height: 10),
                  Consumer<TeamController>(
                    builder: (context, controller, child) {
                      return CustomTextFormField(
                        isfilled: true,
                        controller: controller.lastNameController,
                        hintText: "Enter Last Name",
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Email Address
                  Text("Email Address", style: AppTextStyles.size14Medium),
                  const SizedBox(height: 10),
                  Consumer<TeamController>(
                    builder: (context, controller, child) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomTextFormField(
                            isfilled: true,
                            controller: controller.emailController,
                            hintText: "Enter Your Email",
                            isEmail: true,
                            onChanged: (value) {
                              // Sync username with email
                              controller.userNameController.text = value;

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
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  else
                                    Text(
                                      controller.emailValidationMessage!,
                                      style: AppTextStyles.size12Regular
                                          .copyWith(
                                            color:
                                                controller
                                                    .emailValidationMessage!
                                                    .contains("✅")
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Phone Number
                  Text(
                    "Phone Number (Optional)",
                    style: AppTextStyles.size14Medium,
                  ),
                  const SizedBox(height: 10),
                  Consumer<TeamController>(
                    builder: (context, controller, child) {
                      return CustomTextFormField(
                        isfilled: true,
                        controller: controller.phoneController,
                        hintText: "Enter Phone Number",
                        isMobile: true,
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // // Create User name & Password Section Header
                  // Text(
                  //   "Create User name & Password",
                  //   style: AppTextStyles.size14Medium,
                  // ),
                  // const SizedBox(height: 20),

                  // User Name
                  // Text("User Name", style: AppTextStyles.size14Medium),
                  // const SizedBox(height: 10),
                  // Consumer<TeamController>(
                  //   builder: (context, controller, child) {
                  //     return CustomTextFormField(
                  //       isfilled: true,
                  //       controller: controller.userNameController,
                  //       hintText: "Create User Name",
                  //       isEditable: false, // Make it read-only
                  //     );
                  //   },
                  // ),
                  // const SizedBox(height: 20),

                  // Password
                  Text("Password", style: AppTextStyles.size14Medium),
                  const SizedBox(height: 10),
                  Consumer<TeamController>(
                    builder: (context, controller, child) {
                      return CustomTextFormField(
                        isfilled: true,
                        controller: controller.passwordController,
                        hintText: "Create Password",
                        obscureText: true,
                        onChanged: _checkPassword,
                      );
                    },
                  ),

                  // Validation Checklist (Only show in Add Mode)
                  Consumer<TeamController>(
                    builder: (context, controller, child) {
                      if (controller.isEditMode) return SizedBox.shrink();
                      return Padding(
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
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Consumer<TeamController>(
                builder: (context, controller, child) {
                  return CustomRectBtn(
                    width: double.infinity,
                    onTap: controller.isLoading
                        ? () {}
                        : () {
                            _handleAddTeamMember();
                          },
                    height: 49,
                    borderRadius: 25,
                    leading: Center(
                      child: controller.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              controller.isEditMode
                                  ? "Update Team member"
                                  : "Add Team member",
                              style: AppTextStyles.size16SemiBold.copyWith(
                                color: Colors.white,
                              ),
                            ),
                    ),
                    color: AppColors.mainAppColr,
                    borderColor: AppColors.mainAppColr,
                    textColor: Colors.white,
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
