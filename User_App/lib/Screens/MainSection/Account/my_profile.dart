import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:resqbox_user/Controllers/account_controller.dart';
import 'package:resqbox_user/Models/user_details_model.dart';
import 'package:resqbox_user/Screens/MainSection/Orders/rating_screen.dart';
import 'package:resqbox_user/Utils/active_btn.dart';
import 'package:resqbox_user/Utils/colors.dart';
import 'package:resqbox_user/Utils/custom_appbar.dart';
import 'package:resqbox_user/Utils/custom_border_btn.dart';
import 'package:resqbox_user/Utils/custom_image_widget.dart';
import 'package:resqbox_user/Utils/custom_padding.dart';
import 'package:resqbox_user/Utils/custom_sizedbox.dart';
import 'package:resqbox_user/Utils/customtext.dart';
import 'package:resqbox_user/Utils/images.dart';
import 'package:resqbox_user/Utils/mediaquery.dart';
import 'package:resqbox_user/Utils/navigations.dart';
import 'package:resqbox_user/Utils/textformfield.dart';
import 'package:resqbox_user/Utils/toast.dart';
import 'package:resqbox_user/Utils/custom_loader.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../../../Utils/network_image.dart';

class MyProfile extends StatefulWidget {
  final User? user;
  const MyProfile({super.key, this.user});

  @override
  State<MyProfile> createState() => _MyProfileState();
}

class _MyProfileState extends State<MyProfile> {
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController emailAddressController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  File? _selectedImage;
  String? uploadedImageUrl;
  bool isEditing = false;
  String? _countryCode;

  @override
  void initState() {
    super.initState();
    firstNameController.text = widget.user?.name ?? '';
    lastNameController.text = widget.user?.lastName ?? '';
    emailAddressController.text = widget.user?.email ?? '';
    phoneNumberController.text = widget.user?.phoneNumber ?? '';
    _countryCode = widget.user?.countryCode;
    uploadedImageUrl = widget.user?.profilePicture;
  }

  // Extract filename from URL or path
  String _extractFilename(String? url) {
    if (url == null || url.isEmpty) return '';

    // If it's a full URL, extract the filename
    if (url.startsWith('http://') || url.startsWith('https://')) {
      try {
        final uri = Uri.parse(url);
        final pathSegments = uri.pathSegments;
        if (pathSegments.isNotEmpty) {
          // Get the last segment (filename)
          String filename = pathSegments.last;
          // Remove query parameters if any
          if (filename.contains('?')) {
            filename = filename.split('?').first;
          }
          return filename;
        }
      } catch (e) {
        debugPrint("Error parsing URL: $e");
      }
      // Fallback: extract from path
      final parts = url.split('/');
      if (parts.isNotEmpty) {
        String filename = parts.last;
        if (filename.contains('?')) {
          filename = filename.split('?').first;
        }
        return filename;
      }
    }

    // If it's already just a filename or path, extract filename
    final parts = url.split('/');
    if (parts.isNotEmpty) {
      String filename = parts.last;
      if (filename.contains('?')) {
        filename = filename.split('?').first;
      }
      return filename;
    }

    return url;
  }

  void _showImagePickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.tWhiteColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: Sizes.width * 0.04,
              right: Sizes.width * 0.04,
              top: Sizes.height * 0.02,
              bottom: MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CustomText(
                  text: "Choose an option",
                  fontSize: 0.018,
                  fontWeight: FontWeight.bold,
                ),
                SizedBox(height: Sizes.height * 0.015),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.camera_alt),
                  title: const CustomText(text: "Take Photo"),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.photo_library),
                  title: const CustomText(text: "Choose from Gallery"),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();

      if (source == ImageSource.camera) {
        var status = await Permission.camera.status;
        if (status.isPermanentlyDenied) {
          customToast(
            message:
                "Camera permission is permanently denied. Please enable it in app settings.",
          );
          try {
            await openAppSettings();
          } catch (e) {
            debugPrint("Error opening app settings: $e");
          }
          return;
        }
        if (status.isDenied) {
          status = await Permission.camera.request();
          if (status.isDenied) {
            customToast(
              message: "Camera permission is required to take photos",
            );
            return;
          }
        }
      } else {
        PermissionStatus status = PermissionStatus.granted;
        if (Platform.isAndroid) {
          final androidInfo = await DeviceInfoPlugin().androidInfo;
          if (androidInfo.version.sdkInt >= 33) {
            // On Android 13+, image_picker uses the Photo Picker which requires NO manifest permission.
            // We skip manual permission requests here to comply with Play Store policies.
            status = PermissionStatus.granted;
          } else {
            status = await Permission.storage.status;
            if (status.isDenied) {
              status = await Permission.storage.request();
            }
          }
        } else {
          // iOS handling for photo library
          status = await Permission.photos.status;
          if (status.isDenied) {
            status = await Permission.photos.request();
          }
        }

        if (status.isPermanentlyDenied) {
          customToast(
            message:
                "Gallery permission is permanently denied. Please enable it in app settings.",
          );
          try {
            await openAppSettings();
          } catch (e) {
            debugPrint("Error opening app settings: $e");
          }
          return;
        }

        if (status.isDenied) {
          customToast(message: "Gallery permission is required");
          return;
        }
      }

      final XFile? pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          uploadedImageUrl =
              null; // Clear previous URL when new image is selected
        });
      }
    } catch (e) {
      debugPrint("Image picker error: $e");
      if (e.toString().contains('permission') ||
          e.toString().contains('Permission') ||
          e.toString().contains('MissingPluginException')) {
        customToast(
          message:
              "Permission denied. Please enable camera/gallery permission in app settings.",
        );
        try {
          await openAppSettings();
        } catch (settingsError) {
          debugPrint("Error opening app settings: $settingsError");
          // If we can't open settings, just show the toast message
        }
      } else {
        customToast(message: "Failed to pick image. Please try again.");
      }
    }
  }

  Widget _buildProfileImage() {
    if (_selectedImage != null) {
      // Show selected image
      return Container(
        width: Sizes.height * 0.1,
        height: Sizes.height * 0.1,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.tPrimaryColor),
        ),
        child: ClipOval(
          child: Image.file(
            _selectedImage!,
            fit: BoxFit.cover,
            width: Sizes.height * 0.1,
            height: Sizes.height * 0.1,
          ),
        ),
      );
    } else if (uploadedImageUrl != null && uploadedImageUrl!.isNotEmpty) {
      // Show profile picture from API
      return Container(
        width: Sizes.height * 0.1,
        height: Sizes.height * 0.1,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.tPrimaryColor),
        ),
        child: CircleAvatar(
          backgroundColor: Colors.transparent,
          radius: Sizes.height * 0.04,
          child: ClipOval(
            child: CustomNetworkImage(
              url: uploadedImageUrl!,
              height: .085,
              width: .185,
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    } else {
      // Show default grey icon
      return Container(
        width: Sizes.height * 0.1,
        height: Sizes.height * 0.1,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.tPrimaryColor),
          color: Colors.white,
        ),
        child: Icon(
          Icons.person,
          size: Sizes.height * 0.08,
          color: Colors.grey.shade400,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0XFFF6F6F6),
      appBar: CustomAppBar(
        title: "My Profile",
        titleFontSize: 0.022,
        backgroundColor: AppColors.tWhiteColor,
        backTap: () => Navigator.of(context).pop(),
      ),
      bottomNavigationBar: Container(
        color: AppColors.tWhiteColor,
        padding: EdgeInsets.symmetric(
          vertical: Sizes.height * .02,
          horizontal: Sizes.width * .06,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomBorderBtn(
              height: Sizes.height * .062,
              width: Sizes.width * .42,
              borderRadius: 25,
              text: "Cancel",
              onTap: () {
                NavigateTo().backPage();
              },
              fontSize: 0.018,
              borderColor: AppColors.tBlackColor,
              textColor: AppColors.hintTclr,
            ),
            ActiveButton(
              height: Sizes.height * .062,
              width: Sizes.width * .42,
              borderRadius: 25,
              text: "Edit Profile",
              fontSize: .018,
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final accountController = Provider.of<AccountController>(
                    context,
                    listen: false,
                  );

                  String? profilePictureToSend;

                  // If a new image is selected, upload it first
                  if (_selectedImage != null) {
                    Loaders.showLoadingDialog();
                    final uploadedUrl = await accountController.uploadImage(
                      _selectedImage!,
                    );
                    Loaders.hideLoadingDialog();

                    if (uploadedUrl != null) {
                      profilePictureToSend = uploadedUrl;
                    } else {
                      customToast(
                        message:
                            "Failed to upload profile picture. Please try again.",
                      );
                      return;
                    }
                  } else {
                    // No new image selected - extract filename from existing URL
                    final existingProfilePicture = widget.user?.profilePicture;
                    if (existingProfilePicture != null &&
                        existingProfilePicture.isNotEmpty) {
                      // Extract only the filename from the existing URL
                      profilePictureToSend = _extractFilename(
                        existingProfilePicture,
                      );
                    } else {
                      profilePictureToSend = '';
                    }
                  }

                  // Now update the profile with the uploaded image URL or filename
                  Map<String, dynamic> body = {
                    "name": firstNameController.text,
                    "lastName": lastNameController.text,
                    "email": emailAddressController.text.isNotEmpty
                        ? emailAddressController.text
                        : widget.user?.email ?? '',
                    "phoneNumber": phoneNumberController.text,
                    "countryCode": _countryCode ?? '',
                    "profilePicture": profilePictureToSend,
                    "deviceToken": widget.user?.deviceToken ?? '',
                  };

                  debugPrint("body ........ $body");
                  await accountController.updateProfileApi(body: body);
                }
              },
            ),
          ],
        ),
      ),
      body: CustomPadding(
        horizontal: .04,
        vertical: .02,
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.tWhiteColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: CustomPadding(
                    horizontal: .03,
                    vertical: .023,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => _showImagePickerOptions(context),
                          child: Stack(
                            children: [
                              _buildProfileImage(),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: EdgeInsets.all(Sizes.width * 0.01),
                                  decoration: BoxDecoration(
                                    color: AppColors.tBlackColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.add_a_photo,
                                    color: AppColors.tWhiteColor,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const CustomSizedBox(width: .04),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText(
                                text:
                                    '${widget.user?.name ?? ''} ${widget.user?.lastName ?? ''}',
                                fontWeight: FontWeight.w700,
                                fontSize: .022,
                              ),
                              CustomSizedBox(height: .003),
                              CustomText(
                                text: "${widget.user?.email ?? ''}",
                                fontWeight: FontWeight.w500,
                                fontSize: .018,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                color: AppColors.hintTclr,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                CustomSizedBox(height: .02),
                Container(
                  width: Sizes.width,
                  decoration: BoxDecoration(
                    color: AppColors.tWhiteColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: CustomPadding(
                    horizontal: .03,
                    vertical: .023,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          text: "Profile Information",
                          fontSize: .02,
                          fontWeight: FontWeight.w700,
                        ),
                        CustomSizedBox(height: .012),
                        Row(
                          children: [
                            CustomText(
                              text: "First Name",
                              fontSize: .016,
                              color: Color(0xFF4B5563),
                              fontWeight: FontWeight.w400,
                            ),
                            CustomSizedBox(width: .03),
                            CustomImage(
                              image: AppImages.accountRedStar,
                              height: .02,
                              width: .02,
                            ),
                          ],
                        ),
                        CustomPadding(
                          vertical: .013,
                          child: CustomTextFormField(
                            controller: firstNameController,
                            hintText: "Enter First Name",
                            hintFontSize: .018,
                            hintFontWeight: FontWeight.w400,
                            fillColor: Colors.transparent,
                            maxLines: 1,
                            maxxLength: 30,
                            borderRaduise: 25,
                            validator: (value) {
                              if (value!.isEmpty) {
                                return 'Please enter first name';
                              }
                              return null;
                            },
                            contentPadding: EdgeInsets.only(left: 12),
                            customBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: const BorderSide(
                                color: Color(0xFFC0C0C0),
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            CustomText(
                              text: "Last Name",
                              fontSize: .016,
                              color: Color(0xFF4B5563),
                              fontWeight: FontWeight.w400,
                            ),
                            CustomSizedBox(width: .03),
                            CustomImage(
                              image: AppImages.accountRedStar,
                              height: .02,
                              width: .02,
                            ),
                          ],
                        ),
                        CustomPadding(
                          vertical: .013,
                          child: CustomTextFormField(
                            controller: lastNameController,
                            hintText: "Enter Last Name",
                            hintFontSize: .018,
                            maxLines: 1,
                            maxxLength: 30,
                            contentPadding: EdgeInsets.only(left: 12),
                            fillColor: Colors.transparent,
                            borderRaduise: 25,
                            validator: (value) {
                              if (value!.isEmpty) {
                                return 'Please enter last name';
                              }
                              return null;
                            },
                            customBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: const BorderSide(
                                color: Color(0xFFC0C0C0),
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            CustomText(
                              text: "Email Address",
                              fontSize: .016,
                              color: Color(0xFF4B5563),
                              fontWeight: FontWeight.w400,
                            ),
                            CustomSizedBox(width: .03),
                            CustomImage(
                              image: AppImages.accountRedStar,
                              height: .02,
                              width: .02,
                            ),
                          ],
                        ),
                        CustomPadding(
                          vertical: .013,
                          child: CustomTextFormField(
                            controller: emailAddressController,
                            hintText: "Enter Email Address",
                            hintFontSize: .018,
                            readOnly: true,
                            validator: (value) {
                              return null;
                            },
                            fillColor: Colors.transparent,
                            borderRaduise: 25,
                            contentPadding: EdgeInsets.only(left: 12),
                            customBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: const BorderSide(
                                color: Color(0xFFC0C0C0),
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            CustomText(
                              text: "Phone number",
                              fontSize: .016,
                              color: Color(0xFF4B5563),
                              fontWeight: FontWeight.w400,
                            ),
                            // CustomSizedBox(width: .03),
                            // CustomImage(
                            //   image: AppImages.accountRedStar,
                            //   height: .02,
                            //   width: .02,
                            // ),
                          ],
                        ),
                        CustomPadding(
                          vertical: .013,
                          child: IntlPhoneField(
                            controller: phoneNumberController,
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
                              fillColor: Colors.transparent,
                              filled: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: const BorderSide(
                                  color: Color(0xFFC0C0C0),
                                  width: 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: const BorderSide(
                                  color: Color(0xFFC0C0C0),
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: const BorderSide(
                                  color: Color(0xFFC0C0C0),
                                  width: 1,
                                ),
                              ),
                            ),
                            initialCountryCode: (_countryCode != null &&
                                    _countryCode!.startsWith('+'))
                                ? null // Let value handle it if we have full code
                                : 'AU',
                            initialValue: (_countryCode != null &&
                                    phoneNumberController.text.isNotEmpty)
                                ? '${_countryCode}${phoneNumberController.text}'
                                : null,
                            onCountryChanged: (country) {
                              phoneNumberController.clear();
                              _countryCode = '+${country.dialCode}';
                            },
                            onChanged: (phone) {
                              _countryCode = phone.countryCode;
                              phoneNumberController.text = phone.number;
                            },
                            validator: (phone) {
                              if (phone == null || phone.number.isEmpty) {
                                return null; // allow empty as per requirement
                              }
                              return null;
                            },
                          ),
                        ),
                        // Row(
                        //   children: [
                        //     CustomText(
                        //       text: "Location",
                        //       fontSize: .016,
                        //       color: Color(0xFF4B5563),
                        //       fontWeight: FontWeight.w400,
                        //     ),
                        //     CustomSizedBox(width: .03),
                        //     CustomImage(
                        //       image: AppImages.accountRedStar,
                        //       height: .02,
                        //       width: .02,
                        //     ),
                        //   ],
                        // ),
                        // CustomPadding(
                        //   vertical: .013,
                        //   child: CustomTextFormField(
                        //     controller: firstNameController,
                        //     hintText: "Enter Location",
                        //     hintFontSize: .018,
                        //     fillColor: Colors.transparent,
                        //     borderRaduise: 25,
                        //     contentPadding: EdgeInsets.only(left: 12),
                        //     customBorder: OutlineInputBorder(
                        //       borderRadius: BorderRadius.circular(25),
                        //       borderSide: const BorderSide(
                        //         color: Color(0xFFC0C0C0),
                        //         width: 1,
                        //       ),
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
