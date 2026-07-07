import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resqboxvendor/Controller/KitchenProfileController.dart';
import 'package:resqboxvendor/Utils/custom_appbar.dart';
import 'package:resqboxvendor/Utils/custom_border_btn.dart';
import 'package:resqboxvendor/Utils/image_upload_selection_bottomsheet.dart';
import 'package:resqboxvendor/Utils/navigations.dart';
import 'package:resqboxvendor/Utils/text_field.dart';
import 'package:resqboxvendor/Utils/textstyles.dart';
import 'package:resqboxvendor/Utils/toast.dart';

class InfoEditScreen extends StatefulWidget {
  const InfoEditScreen({super.key});

  @override
  State<InfoEditScreen> createState() => _InfoEditScreenState();
}

class _InfoEditScreenState extends State<InfoEditScreen> {
  // final TextEditingController _kitchenNameController = TextEditingController();
  // final TextEditingController _ownerNameController = TextEditingController();
  // final TextEditingController _contactNumberController =
  //     TextEditingController();
  // final TextEditingController _descriptionController = TextEditingController();

  final TextEditingController _timezoneController =
      TextEditingController(); // Added
  final TextEditingController _emailController =
      TextEditingController(); // Added
  TimeOfDay? openingTime;
  TimeOfDay? closingTime;
  String openingPeriod = 'AM';
  String closingPeriod = 'PM';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  @override
  void dispose() {
    _timezoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentData() async {
    final controller = Provider.of<KitchenProfileController>(
      context,
      listen: false,
    );
    final kitchen = controller.kitchenDetails;

    // Load timezones and prefill
    if (controller.timezones.isEmpty) {
      await controller.getTimezones();
    }

    if (controller.selectedTimezone == null &&
        kitchen?.timezoneId != null &&
        controller.timezones.isNotEmpty) {
      // Try to find it if already loaded but not selected
      try {
        final found = controller.timezones.firstWhere(
          (e) => e.id == kitchen!.timezoneId,
        );
        controller.setSelectedTimezone(found);
      } catch (e) {
        debugPrint("Error finding timezone: $e");
      }
    }

    if (controller.selectedTimezone != null) {
      _timezoneController.text = controller.selectedTimezone!.displayName ?? "";
    }
    _emailController.text = kitchen?.email ?? '';

    if (kitchen?.openingTime != null) {
      final openingParts = kitchen!.openingTime!.split(':');
      if (openingParts.length == 2) {
        final hour = int.tryParse(openingParts[0]) ?? 11;
        final minute = int.tryParse(openingParts[1]) ?? 0;
        openingTime = TimeOfDay(hour: hour, minute: minute);
        openingPeriod = hour >= 12 ? 'PM' : 'AM';
      }
    } else {
      openingTime = const TimeOfDay(hour: 11, minute: 0);
    }

    if (kitchen?.closingTime != null) {
      final closingParts = kitchen!.closingTime!.split(':');
      if (closingParts.length == 2) {
        final hour = int.tryParse(closingParts[0]) ?? 23;
        final minute = int.tryParse(closingParts[1]) ?? 30;
        closingTime = TimeOfDay(hour: hour, minute: minute);
        closingPeriod = hour >= 12 ? 'PM' : 'AM';
      }
    } else {
      closingTime = const TimeOfDay(hour: 23, minute: 30);
    }
    setState(() {}); // Ensure UI updates after async load
  }

  Future<void> _selectTime(BuildContext context, bool isOpening) async {
    final TimeOfDay initialTime = isOpening
        ? (openingTime ?? const TimeOfDay(hour: 11, minute: 0))
        : (closingTime ?? const TimeOfDay(hour: 23, minute: 30));

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: const Color(0xffF1913D),
            colorScheme: const ColorScheme.light(primary: Color(0xffF1913D)),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isOpening) {
          openingTime = picked;
          openingPeriod = picked.hour >= 12 ? 'PM' : 'AM';
        } else {
          closingTime = picked;
          closingPeriod = picked.hour >= 12 ? 'PM' : 'AM';
        }
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    int hour = time.hour;
    if (hour > 12) {
      hour = hour - 12;
    } else if (hour == 0) {
      hour = 12;
    }
    return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatTimeForAPI(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _saveChanges() async {
    if (openingTime == null || closingTime == null) {
      customToast(message: "Please select both opening and closing times");
      return;
    }

    final openingMinutes = openingTime!.hour * 60 + openingTime!.minute;
    final closingMinutes = closingTime!.hour * 60 + closingTime!.minute;

    if (closingMinutes <= openingMinutes) {
      customToast(message: "Closing time must be after opening time");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final controller = Provider.of<KitchenProfileController>(
      context,
      listen: false,
    );

    // Check if timezone selected
    if (controller.selectedTimezone == null) {
      customToast(message: "Please select a time zone");
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Upload profile photo if selected
    String? uploadedProfilePhoto;
    if (controller.selectedKitchenProfilePhoto != null) {
      uploadedProfilePhoto = await controller.uploadSingleImage(
        controller.selectedKitchenProfilePhoto!,
        "kitchen",
      );
      if (uploadedProfilePhoto == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
    }

    final success = await controller.updateKitchen(
      // kitchenName: _kitchenNameController.text,
      // ownerName: _ownerNameController.text,
      // contactNumber: _contactNumberController.text,
      // description: _descriptionController.text,
      openingTime: _formatTimeForAPI(openingTime!),
      closingTime: _formatTimeForAPI(closingTime!),
      kitchenProfilePhoto: uploadedProfilePhoto,
      timezoneId: controller.selectedTimezone?.id, // Added timezoneId
    );

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      // Clear selected photo after successful update
      controller.selectedKitchenProfilePhoto = null;
      NavigateTo().backPage();
    }
  }

  void _showTimezoneSelectionSheet(
    BuildContext context,
    KitchenProfileController controller,
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
                  child: controller.timezones.isEmpty
                      ? const Center(child: Text("No timezones available"))
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: controller.timezones.length,
                          itemBuilder: (context, index) {
                            final timezone = controller.timezones[index];
                            final isSelected =
                                controller.selectedTimezone?.id == timezone.id;

                            return ListTile(
                              title: Text(
                                timezone.displayName ?? "",
                                style: AppTextStyles.size14Medium.copyWith(
                                  color: isSelected
                                      ? const Color(0xffF1913D)
                                      : Colors.black87,
                                ),
                              ),
                              subtitle: Text(
                                "Offset: ${timezone.offset ?? ''}",
                                style: AppTextStyles.size12Regular.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                              trailing: isSelected
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: Color(0xffF1913D),
                                    )
                                  : null,
                              onTap: () {
                                controller.setSelectedTimezone(timezone);
                                _timezoneController.text =
                                    timezone.displayName ?? "";
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: "Edit Info",
        isLeading: true,
        backTap: () {
          NavigateTo().backPage();
        },
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              color: Color(0xffE9E9E9),
              width: double.infinity,
              height: 1,
            ),
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // const SizedBox(height: 70),
                  Text('Kitchen Logo', style: AppTextStyles.size14Medium),
                  const SizedBox(height: 16),

                  Consumer<KitchenProfileController>(
                    builder: (context, controller, child) {
                      final kitchen = controller.kitchenDetails;
                      final profilePhotoUrl =
                          kitchen?.photos?.kitchenProfilePhoto;
                      final selectedPhoto =
                          controller.selectedKitchenProfilePhoto;

                      return Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 140,
                              height: 140,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              child: ClipOval(
                                child: selectedPhoto != null
                                    ? Image.file(
                                        selectedPhoto,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey[300],
                                                child: const Icon(
                                                  Icons.restaurant,
                                                  size: 60,
                                                  color: Colors.grey,
                                                ),
                                              );
                                            },
                                      )
                                    : profilePhotoUrl != null &&
                                          profilePhotoUrl.isNotEmpty
                                    ? Image.network(
                                        profilePhotoUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey[300],
                                                child: const Icon(
                                                  Icons.restaurant,
                                                  size: 60,
                                                  color: Colors.grey,
                                                ),
                                              );
                                            },
                                      )
                                    : Image.asset(
                                        'Assets/Account/storeprofile.png',
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey[300],
                                                child: const Icon(
                                                  Icons.restaurant,
                                                  size: 60,
                                                  color: Colors.grey,
                                                ),
                                              );
                                            },
                                      ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () {
                                  ImagePickerBottomSheet.show(
                                    context: context,
                                    onImageSelected: (File file) {
                                      controller.setSelectedKitchenProfilePhoto(
                                        file,
                                      );
                                    },
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xffF1913D),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 6),

                  Center(
                    child: Consumer<KitchenProfileController>(
                      builder: (context, controller, child) {
                        return TextButton(
                          onPressed: () {
                            ImagePickerBottomSheet.show(
                              context: context,
                              onImageSelected: (File file) {
                                controller.setSelectedKitchenProfilePhoto(file);
                              },
                            );
                          },
                          child: Text(
                            'Change Logo',
                            style: AppTextStyles.size14Medium.copyWith(
                              color: const Color(0xff707070),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 32),

                  // _buildTextField(
                  //   label: 'Kitchen Name',
                  //   controller: _kitchenNameController,
                  // ),
                  // _buildTextField(
                  //   label: 'Owner Name',
                  //   controller: _ownerNameController,
                  // ),
                  // _buildTextField(
                  //   label: 'Contact Number',
                  //   controller: _contactNumberController,
                  //   keyboardType: TextInputType.phone,
                  // ),
                  // _buildTextField(
                  //   label: 'Description',
                  //   controller: _descriptionController,
                  //   maxLines: 3,
                  // ),
                  Text('Operating Hours', style: AppTextStyles.size14Medium),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Opening Time',
                              style: AppTextStyles.size12Regular.copyWith(
                                color: const Color(0xff777777),
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => _selectTime(context, true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xffF9F9F9),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xffE2E2E2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      openingTime != null
                                          ? _formatTime(openingTime!)
                                          : "Select Time",
                                      style: AppTextStyles.size16SemiBold,
                                    ),
                                    Text(
                                      openingPeriod,
                                      style: AppTextStyles.size16SemiBold,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Closing Time
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Closing time',
                              style: AppTextStyles.size12Regular.copyWith(
                                color: const Color(0xff777777),
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => _selectTime(context, false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xffF9F9F9),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xffE2E2E2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      closingTime != null
                                          ? _formatTime(closingTime!)
                                          : "Select Time",
                                      style: AppTextStyles.size16SemiBold,
                                    ),
                                    Text(
                                      closingPeriod,
                                      style: AppTextStyles.size16SemiBold,
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

                  const SizedBox(height: 20),
                  Consumer<KitchenProfileController>(
                    builder: (context, controller, child) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // const SizedBox(height: 10),
                          const SizedBox(height: 8),
                          Text("Time Zone", style: AppTextStyles.size14Medium),
                          const SizedBox(height: 8),
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
                                    _showTimezoneSelectionSheet(
                                      context,
                                      controller,
                                    );
                                  }
                                });
                              } else {
                                _showTimezoneSelectionSheet(
                                  context,
                                  controller,
                                );
                              }
                            },
                            isRequired: true,
                          ),
                          const SizedBox(height: 8),
                          Text("Email :- ", style: AppTextStyles.size14Medium),
                          const SizedBox(height: 8),

                          CustomTextFormField(
                            isfilled: true,
                            isEditable: false,
                            controller: _emailController,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: CustomRectBtn(
                width: MediaQuery.of(context).size.width * 0.45,
                onTap: () => NavigateTo().backPage(),
                height: 49,
                borderRadius: 25,
                leading: Center(
                  child: Text(
                    "Cancel",
                    style: AppTextStyles.size16SemiBold.copyWith(
                      color: Colors.black,
                    ),
                  ),
                ),
                color: Colors.white,
                borderColor: const Color(0xffF1913D),
                textColor: Colors.black,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomRectBtn(
                onTap: _isLoading
                    ? () {}
                    : () {
                        _saveChanges();
                      },
                height: 49,
                width: MediaQuery.of(context).size.width * 0.45,
                borderRadius: 25,
                leading: Center(
                  child: _isLoading
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
                      : Text(
                          "Save Changes",
                          style: AppTextStyles.size16SemiBold.copyWith(
                            color: Colors.white,
                          ),
                        ),
                ),
                color: const Color(0xffF1913D),
                borderColor: const Color(0xffF1913D),
                textColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildTextField({
  //   required String label,
  //   required TextEditingController controller,
  //   int maxLines = 1,
  //   TextInputType? keyboardType,
  // }) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(label, style: AppTextStyles.size14Medium),
  //       const SizedBox(height: 8),
  //       TextFormField(
  //         controller: controller,
  //         maxLines: maxLines,
  //         keyboardType: keyboardType,
  //         decoration: InputDecoration(
  //           contentPadding: const EdgeInsets.symmetric(
  //             horizontal: 16,
  //             vertical: 14,
  //           ),
  //           border: OutlineInputBorder(
  //             borderRadius: BorderRadius.circular(8),
  //             borderSide: BorderSide(color: Color(0xffE2E2E2)),
  //           ),
  //           enabledBorder: OutlineInputBorder(
  //             borderRadius: BorderRadius.circular(8),
  //             borderSide: BorderSide(color: Color(0xffE2E2E2)),
  //           ),
  //           focusedBorder: OutlineInputBorder(
  //             borderRadius: BorderRadius.circular(8),
  //             borderSide: BorderSide(color: Color(0xffF1913D)),
  //           ),
  //           filled: true,
  //           fillColor: const Color(0xffF9F9F9),
  //         ),
  //         style: AppTextStyles.size16SemiBold,
  //       ),
  //       const SizedBox(height: 16),
  //     ],
  //   );
  // }
}
