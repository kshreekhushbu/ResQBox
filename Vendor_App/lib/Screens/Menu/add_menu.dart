import 'dart:async';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:resqboxvendor/Utils/toast.dart';
import 'package:provider/provider.dart';
import 'package:resqboxvendor/Controller/MenuController.dart' as menu;
import 'package:resqboxvendor/Models/category_model.dart';
import 'package:http/http.dart' as http;
import 'package:resqboxvendor/Controller/KitchenProfileController.dart';

import 'package:resqboxvendor/Screens/Menu/success_screen.dart';
import 'package:resqboxvendor/Utils/colors.dart';
import 'package:resqboxvendor/Utils/custom_appbar.dart';
import 'package:resqboxvendor/Utils/custom_border_btn.dart';
import 'package:resqboxvendor/Utils/dashed_border.dart';
import 'package:resqboxvendor/Utils/images.dart';
import 'package:resqboxvendor/Utils/navigations.dart';
import 'package:resqboxvendor/Utils/text_field.dart';
import 'package:resqboxvendor/Utils/textstyles.dart';
import 'package:resqboxvendor/Utils/image_upload_selection_bottomsheet.dart'; // Added Import

class AddMenu extends StatefulWidget {
  const AddMenu({super.key});

  @override
  State<AddMenu> createState() => _AddMenuState();
}

class _AddMenuState extends State<AddMenu> {
  @override
  void initState() {
    super.initState();
    final controller = Provider.of<menu.MenuController>(context, listen: false);
    controller.getCategories();
    controller.getMenuTypes();
    // controller.getFoodTypes();
  }

  final TextEditingController _categoryDisplayController =
      TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _categoryDisplayController.dispose();

    super.dispose();
  }

  void _showCategorySelectionSheet(BuildContext context) {
    final controller = Provider.of<menu.MenuController>(context, listen: false);
    // Create a local set of selected IDs for the sheet state
    List<Category> tempSelectedCategories = List.from(
      controller.selectedCategories,
    );
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
            // Filter categories based on search query
            final filteredCategories = controller.categories.where((category) {
              return (category.name ?? "").toLowerCase().contains(
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
                  SizedBox(height: 15),

                  // Search Bar
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
                    child: filteredCategories.isEmpty
                        ? Center(child: Text("No categories found"))
                        : ListView.builder(
                            itemCount: filteredCategories.length,
                            itemBuilder: (context, index) {
                              final category = filteredCategories[index];
                              final isSelected = tempSelectedCategories.any(
                                (c) => c.id == category.id,
                              );

                              return CheckboxListTile(
                                title: Text(category.name ?? ""),
                                value: isSelected,
                                activeColor: AppColors.mainAppColr,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      if (tempSelectedCategories.length >= 5) {
                                        customToast(
                                          message:
                                              "You can only select up to 5 categories",
                                        );
                                        return;
                                      }
                                      tempSelectedCategories.add(category);
                                    } else {
                                      tempSelectedCategories.removeWhere(
                                        (c) => c.id == category.id,
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
                    color: AppColors.mainAppColr,
                    borderColor: AppColors.mainAppColr,
                    height: 50,
                    width: double.infinity,
                    text: "Done",
                    onTap: () {
                      controller.setSelectedCategories(tempSelectedCategories);
                      _categoryDisplayController.text = tempSelectedCategories
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

  Widget _buildRequiredLabel(String text) {
    return RichText(
      text: TextSpan(
        text: text,
        style: AppTextStyles.size14Medium.copyWith(color: Color(0xff212121)),
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
  Widget build(BuildContext context) {
    final controller = Provider.of<menu.MenuController>(context);

    // Sync display controller with selected categories
    String newCategoryText = controller.selectedCategories
        .map((e) => e.name ?? "")
        .join(", ");
    if (_categoryDisplayController.text != newCategoryText) {
      _categoryDisplayController.text = newCategoryText;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: controller.isEditMode ? "Edit Menu" : "Add Menu",
        isLeading: true,
        backTap: () {
          controller.resetForm();
          NavigateTo().backPage();
        },
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: _autoValidateMode,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                height: 1,
                width: double.infinity,
                color: Color(0xffDDDDDD),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRequiredLabel("Name"),
                    const SizedBox(height: 10),
                    CustomTextFormField(
                      isfilled: true,
                      controller: controller.itemNameController,
                      hintText: "Enter Name",
                      maxLength: 30,
                      isRequired: true,
                    ),
                    const SizedBox(height: 20),
                    _buildRequiredLabel("Category"),
                    const SizedBox(height: 10),
                    CustomTextFormField(
                      isfilled: true,
                      controller: _categoryDisplayController,
                      hintText: "Select Category",
                      isEditable: false,
                      isRequired: true,
                      suffixIcon: Icon(Icons.arrow_drop_down),
                      onTap: () {
                        _showCategorySelectionSheet(context);
                      },
                    ),

                    // const SizedBox(height: 20),

                    // Text(
                    //   "Food Type",
                    //   style: AppTextStyles.size14Medium.copyWith(
                    //     color: Color(0xff212121),
                    //   ),
                    // ),
                    // const SizedBox(height: 10),
                    // CustomDropdownField<FoodType>(
                    //   isfilled: true,
                    //   hintText: "Select Food Type",
                    //   items: controller.foodTypes,
                    //   value: controller.selectedFoodType,
                    //   onChanged: (val) {
                    //     controller.setSelectedFoodType(val);
                    //   },
                    //   itemLabelBuilder: (foodType) => foodType.name ?? "",
                    // ),
                    // const SizedBox(height: 20),
                    // const SizedBox(height: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // _buildRequiredLabel("Menu Type"),
                        // const SizedBox(height: 10),
                        // Consumer<menu.MenuController>(
                        //   builder: (context, controller, child) {
                        //     return ListView.separated(
                        //       shrinkWrap: true,
                        //       physics: NeverScrollableScrollPhysics(),
                        //       itemCount: controller.menuTypes.length,
                        //       separatorBuilder: (context, index) =>
                        //           SizedBox(height: 12),
                        //       itemBuilder: (context, index) {
                        //         final type = controller.menuTypes[index];
                        //         final isSelected = controller.selectedMenuTypes
                        //             .any((t) => t.id == type.id);

                        //         return Container(
                        //           padding: EdgeInsets.symmetric(
                        //             horizontal: 0,
                        //             vertical: 0,
                        //           ),
                        //           decoration: BoxDecoration(
                        //             borderRadius: BorderRadius.circular(8),
                        //             border: Border.all(
                        //               color: Color(0xffE1E1E1),
                        //             ),
                        //             color: Colors.white,
                        //           ),
                        //           child: Row(
                        //             children: [
                        //               ClipRRect(
                        //                 borderRadius: BorderRadius.only(
                        //                   topLeft: Radius.circular(8),
                        //                   bottomLeft: Radius.circular(8),
                        //                 ),
                        //                 child: Image.network(
                        //                   type.image ?? "",
                        //                   height: 50,
                        //                   width: 50,
                        //                   fit: BoxFit.cover,
                        //                   errorBuilder: (_, __, ___) =>
                        //                       Container(
                        //                         color: Colors.grey[200],
                        //                         height: 50,
                        //                         width: 50,
                        //                         child: Icon(
                        //                           Icons.image_not_supported,
                        //                           size: 20,
                        //                         ),
                        //                       ),
                        //                 ),
                        //               ),
                        //               SizedBox(width: 12),
                        //               Expanded(
                        //                 child: Text(
                        //                   type.name ?? "",
                        //                   style: AppTextStyles.size14Medium
                        //                       .copyWith(
                        //                         color: Color(0xff212121),
                        //                       ),
                        //                 ),
                        //               ),
                        //               Switch(
                        //                 value: isSelected,
                        //                 activeColor: AppColors.mainAppColr,
                        //                 onChanged: (val) {
                        //                   if (val) {
                        //                     controller.setSelectedMenuTypes([
                        //                       type,
                        //                     ]);
                        //                   } else {
                        //                     controller.setSelectedMenuTypes([]);
                        //                   }
                        //                 },
                        //               ),
                        //               SizedBox(width: 8),
                        //             ],
                        //           ),
                        //         );
                        //       },
                        //     );
                        //   },
                        // ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildRequiredLabel("Actual Price"),
                                  const SizedBox(height: 10),
                                  CustomTextFormField(
                                    isfilled: true,
                                    controller: controller.priceController,
                                    hintText: "Enter Actual Price",
                                    isAmount: true,
                                    isRequired: true,
                                    onChanged: (val) {
                                      if (val.trim().isEmpty) {
                                        controller.clearOfferPriceValidation();
                                        if (_debounce?.isActive ?? false) {
                                          _debounce!.cancel();
                                        }
                                        return;
                                      }
                                      if (_debounce?.isActive ?? false) {
                                        _debounce!.cancel();
                                      }
                                      _debounce = Timer(
                                        const Duration(milliseconds: 500),
                                        () {
                                          controller.validateOfferPrice();
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildRequiredLabel("Offer Price"),
                                  const SizedBox(height: 10),
                                  CustomTextFormField(
                                    isfilled: true,
                                    controller:
                                        controller.discountPriceController,
                                    hintText: "Enter Offer Price",
                                    isAmount: true,
                                    isRequired: true,
                                    onChanged: (val) {
                                      if (val.trim().isEmpty) {
                                        controller.clearOfferPriceValidation();
                                        if (_debounce?.isActive ?? false) {
                                          _debounce!.cancel();
                                        }
                                        return;
                                      }
                                      if (_debounce?.isActive ?? false) {
                                        _debounce!.cancel();
                                      }
                                      _debounce = Timer(
                                        const Duration(milliseconds: 500),
                                        () {
                                          controller.validateOfferPrice();
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        if (controller.isValidatingOfferPrice)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: SizedBox(
                              height: 10,
                              width: 10,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        if (controller.offerPriceValidationMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              controller.offerPriceValidationMessage!,
                              style: AppTextStyles.size12Regular.copyWith(
                                color:
                                    controller.offerPriceValidationMessage!
                                        .startsWith("✅")
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildRequiredLabel("Number of Boxes"),
                    const SizedBox(height: 10),
                    CustomTextFormField(
                      isfilled: true,
                      controller: controller.quantityController,
                      hintText: "Enter Number of Boxes",
                      isAmount: true,
                      maxLength: 4,
                      isRequired: true,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 20),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRequiredLabel("Pickup End Time"),
                        const SizedBox(height: 10),
                        Consumer<menu.MenuController>(
                          builder: (context, controller, child) {
                            return Column(
                              children: [
                                // Row(
                                //   children: [
                                //     Expanded(
                                //       child: GestureDetector(
                                //         onTap: () => _pickDateTime(
                                //           isStartTime: true,
                                //           controller: controller,
                                //         ),
                                //         child: _buildDateTimeContainer(
                                //           text:
                                //               controller
                                //                   .startDateController
                                //                   .text
                                //                   .isEmpty
                                //               ? "Start Date"
                                //               : controller
                                //                     .startDateController
                                //                     .text,
                                //           isEmpty: controller
                                //               .startDateController
                                //               .text
                                //               .isEmpty,
                                //           icon: Icons.calendar_today,
                                //         ),
                                //       ),
                                //     ),
                                //     const SizedBox(width: 12),
                                //     Expanded(
                                //       child: GestureDetector(
                                //         onTap: () => _pickDateTime(
                                //           isStartTime: true,
                                //           controller: controller,
                                //         ),
                                //         child: _buildDateTimeContainer(
                                //           text:
                                //               controller
                                //                   .startTimeController
                                //                   .text
                                //                   .isEmpty
                                //               ? "Start Time"
                                //               : controller
                                //                     .startTimeController
                                //                     .text,
                                //           isEmpty: controller
                                //               .startTimeController
                                //               .text
                                //               .isEmpty,
                                //           iconPath: AppImages.clock,
                                //         ),
                                //       ),
                                //     ),
                                //   ],
                                // ),
                                // const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => _pickDateTime(
                                          isStartTime: false,
                                          controller: controller,
                                        ),
                                        child: _buildDateTimeContainer(
                                          text:
                                              controller
                                                  .endDateController
                                                  .text
                                                  .isEmpty
                                              ? "End Date"
                                              : controller
                                                    .endDateController
                                                    .text,
                                          isEmpty: controller
                                              .endDateController
                                              .text
                                              .isEmpty,
                                          icon: Icons.calendar_today,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => _pickDateTime(
                                          isStartTime: false,
                                          controller: controller,
                                        ),
                                        child: _buildDateTimeContainer(
                                          text:
                                              controller
                                                  .endTimeController
                                                  .text
                                                  .isEmpty
                                              ? "End Time"
                                              : controller
                                                    .endTimeController
                                                    .text,
                                          isEmpty: controller
                                              .endTimeController
                                              .text
                                              .isEmpty,
                                          iconPath: AppImages.clock,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildRequiredLabel("Description"),
                    const SizedBox(height: 10),
                    CustomTextFormField(
                      isfilled: true,
                      controller: controller.descriptionController,
                      minlines: 5,
                      maxlines: 10,
                      maxLength: 200,
                      hintText: "Enter description",
                      isRequired: true,
                      onChanged: (val) {
                        setState(() {});
                      },
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4.0, right: 4.0),
                        child: Text(
                          "${controller.descriptionController.text.length}/200",
                          style: AppTextStyles.size12Regular.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Upload Picture",
                      style: AppTextStyles.size14Medium.copyWith(
                        color: Color(0xff212121),
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () {
                        ImagePickerBottomSheet.show(
                          context: context,
                          onImageSelected: (file) {
                            controller.setDishImage(file);
                          },
                        );
                      },
                      child: CustomDottedBorder(
                        borderRadius: 1,
                        gap: 4,
                        strokeWidth: 2,
                        color: AppColors.mainAppColr,
                        child: Container(
                          height: 110,
                          decoration: BoxDecoration(
                            color: const Color(0xffF9F9F9),
                            borderRadius: BorderRadius.circular(8),
                            image: controller.dishImage != null
                                ? DecorationImage(
                                    image: FileImage(controller.dishImage!),
                                    fit: BoxFit.cover,
                                  )
                                : controller.displayedImageUrl != null &&
                                      controller.displayedImageUrl!.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(
                                      controller.displayedImageUrl!,
                                    ),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child:
                              controller.dishImage == null &&
                                  (controller.displayedImageUrl == null ||
                                      controller.displayedImageUrl!.isEmpty)
                              ? Center(
                                  child: Image.asset(
                                    AppImages.cameraRegsitration,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildRequiredLabel("Menu Type"),
                    const SizedBox(height: 10),
                    Consumer<menu.MenuController>(
                      builder: (context, controller, child) {
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: controller.menuTypes.length,
                          separatorBuilder: (context, index) =>
                              SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final type = controller.menuTypes[index];
                            final isSelected = controller.selectedMenuTypes.any(
                              (t) => t.id == type.id,
                            );
                            return Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(
                                    type.image ?? "",
                                    width: 16,
                                    height: 16,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 16,
                                      height: 16,
                                      color: Colors.grey[200],
                                      child: Icon(
                                        Icons.image_not_supported,
                                        size: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  type.name ?? "",
                                  style: AppTextStyles.size14Medium.copyWith(
                                    color: Color(0xff212121),
                                  ),
                                ),
                                Spacer(),
                                Switch(
                                  value: isSelected,
                                  onChanged: (value) {
                                    if (value) {
                                      controller.setSelectedMenuTypes([type]);
                                    } else {
                                      controller.setSelectedMenuTypes([]);
                                    }
                                  },
                                  activeColor: AppColors.mainAppColr,
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 26),
                    // Row(
                    //   children: [
                    //     Image.asset(AppImages.spicy),
                    //     SizedBox(width: 4),
                    //     Text(
                    //       "Spicy Item",
                    //       style: AppTextStyles.size14Medium.copyWith(
                    //         color: Color(0xff212121),
                    //       ),
                    //     ),
                    //     Spacer(),
                    //     CustomThumbSwitch(
                    //       value: controller.isSpicy,
                    //       onChanged: (value) {
                    //         controller.setIsSpicy(value);
                    //       },
                    //     ),
                    //   ],
                    // ),
                    // Text(
                    //   "Choose Spice levels",
                    //   style: AppTextStyles.size14Medium.copyWith(
                    //     color: const Color(0xff212121),
                    //   ),
                    // ),
                    // const SizedBox(height: 10),

                    // Row(
                    //   children: [
                    //     Radio<int>(
                    //       value: 1,
                    //       groupValue: controller.spiceLevel,
                    //       onChanged: (value) {
                    //         controller.setSpiceLevel(value!);
                    //       },
                    //     ),
                    //     const Text("Normal"),
                    //     const SizedBox(width: 8),
                    //     Image.asset(AppImages.spicy, height: 16),
                    //   ],
                    // ),
                    // Row(
                    //   children: [
                    //     Radio<int>(
                    //       value: 2,
                    //       groupValue: controller.spiceLevel,
                    //       onChanged: (value) {
                    //         controller.setSpiceLevel(value!);
                    //       },
                    //     ),
                    //     const Text("Medium"),
                    //     const SizedBox(width: 8),
                    //     Row(
                    //       children: List.generate(
                    //         2,
                    //         (index) => Image.asset(AppImages.spicy, height: 16),
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    // Row(
                    //   children: [
                    //     Radio<int>(
                    //       value: 3,
                    //       groupValue: controller.spiceLevel,
                    //       onChanged: (value) {
                    //         controller.setSpiceLevel(value!);
                    //       },
                    //     ),
                    //     const Text("Very Spicy"),
                    //     const SizedBox(width: 8),
                    //     Row(
                    //       children: List.generate(
                    //         4,
                    //         (index) => Image.asset(AppImages.spicy, height: 16),
                    //       ),
                    //     ),
                    //   ],
                    // ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(16.0),
        child: CustomRectBtn(
          width: double.infinity,
          onTap: () async {
            if (!_formKey.currentState!.validate()) {
              setState(() {
                _autoValidateMode = AutovalidateMode.onUserInteraction;
              });
              return;
            }
            if (controller.endTimeController.text.isEmpty) {
              customToast(message: "Please select end time");
              return;
            }

            // Default image logic: Use Kitchen Profile Photo if none selected
            File? defaultImageFile;
            if (!controller.isEditMode && controller.dishImage == null) {
              try {
                final kitchenController = Provider.of<KitchenProfileController>(
                  context,
                  listen: false,
                );
                final profilePhotoUrl = kitchenController
                    .kitchenDetails
                    ?.photos
                    ?.kitchenProfilePhoto;

                if (profilePhotoUrl != null && profilePhotoUrl.isNotEmpty) {
                  final response = await http.get(Uri.parse(profilePhotoUrl));
                  if (response.statusCode == 200) {
                    final tempDir = await getTemporaryDirectory();
                    defaultImageFile = File(
                      '${tempDir.path}/default_menu_bg_${DateTime.now().millisecondsSinceEpoch}.png',
                    );
                    await defaultImageFile.writeAsBytes(response.bodyBytes);
                  }
                }
              } catch (e) {
                debugPrint('❌ Error loading default kitchen image: $e');
              }
            }

            bool success = false;
            if (controller.isEditMode) {
              // Only call toggle API if current status is inactive (0)
              if (controller.currentActiveStatus == 0) {
                await controller.toggleMenuItemStatus(
                  controller.editingItemId!,
                  true,
                );
              }
              success = await controller.updateMenuItem();
            } else {
              success = await controller.addMenuItem(
                defaultImage: defaultImageFile,
              );
            }
            if (success && mounted) {
              if (controller.isEditMode) {
                NavigateTo().backPage();
              } else {
                NavigateTo().nextPage(child: SuccessScreen());
              }
            }
          },
          height: 49,
          borderRadius: 8,
          leading: Center(
            child: Text(
              controller.isEditMode ? "Update Item" : "Add Item",
              style: AppTextStyles.size16SemiBold.copyWith(color: Colors.white),
            ),
          ),
          color: Color(0xffEB7712),
          borderColor: const Color(0xffEB7712),
          textColor: Colors.black,
        ),
      ),
    );
  }

  Future<void> _pickDateTime({
    required bool isStartTime,
    required menu.MenuController controller,
  }) async {
    final DateTime now = DateTime.now();
    final DateTime tomorrow = now.add(const Duration(days: 1));

    // 1. Pick Date (Restricted to Today and Tomorrow)
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate:
          (isStartTime ? controller.startTimeDate : controller.endTimeDate) ??
          now,
      firstDate: now,
      lastDate: tomorrow,
    );

    if (pickedDate == null || !mounted) return;

    // 2. Pick Time
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime == null) return;

    // Construct full DateTime for validation
    final DateTime pickedDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    // Validation 1: Cannot enter past time
    if (pickedDateTime.isBefore(now)) {
      customToast(message: "Cannot select a past time");
      return;
    }

    if (!isStartTime) {
      // Validation for End Time
      // Requirement: Within 12 hours from current time
      final durationFromNow = pickedDateTime.difference(now);
      if (durationFromNow.inHours > 12 ||
          (durationFromNow.inHours == 12 &&
              durationFromNow.inMinutes % 60 > 0)) {
        customToast(
          message: "End time cannot exceed 12 hours from current time",
        );
        return;
      }

      // If start time is somehow set (e.g. from elsewhere), still ensure end > start
      if (controller.startTimeDate != null &&
          controller.startTimeController.text.isNotEmpty) {
        final startParts = controller.startTimeController.text.split(':');
        final startDateTime = DateTime(
          controller.startTimeDate!.year,
          controller.startTimeDate!.month,
          controller.startTimeDate!.day,
          int.parse(startParts[0]),
          int.parse(startParts[1]),
        );

        if (pickedDateTime.isBefore(startDateTime)) {
          customToast(message: "End time must be after start time");
          return;
        }
      }
    }

    // Success - update controllers
    final formattedDate = DateFormat('dd-MM-yyyy').format(pickedDate);
    final formattedTime =
        "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}";

    if (isStartTime) {
      controller.setStartDate(pickedDate, formattedDate);
      controller.setStartTime(formattedTime);

      // If End Time was already set, check if it now violates the 24h rule
      if (controller.endTimeDate != null &&
          controller.endTimeController.text.isNotEmpty) {
        final endParts = controller.endTimeController.text.split(':');
        final endDateTime = DateTime(
          controller.endTimeDate!.year,
          controller.endTimeDate!.month,
          controller.endTimeDate!.day,
          int.parse(endParts[0]),
          int.parse(endParts[1]),
        );

        final duration = endDateTime.difference(pickedDateTime);
        if (duration.isNegative ||
            duration.inHours > 24 ||
            (duration.inHours == 24 && duration.inMinutes % 60 > 0)) {
          controller.setEndDate(DateTime.now(), "");
          controller.setEndTime("");
          customToast(message: "End time cleared (exceeded 24h limit)");
        }
      }
    } else {
      controller.setEndDate(pickedDate, formattedDate);
      controller.setEndTime(formattedTime);
    }
  }

  Widget _buildDateTimeContainer({
    required String text,
    required bool isEmpty,
    IconData? icon,
    String? iconPath,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              text,
              style: AppTextStyles.size14Regular.copyWith(
                color: isEmpty ? Color(0xff727272) : Colors.black,
              ),
            ),
          ),
          if (iconPath != null)
            Image.asset(iconPath, width: 20, height: 20)
          else if (icon != null)
            Icon(icon, size: 20, color: Color(0xff727272)),
        ],
      ),
    );
  }
}
