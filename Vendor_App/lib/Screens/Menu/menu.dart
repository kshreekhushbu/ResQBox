import 'package:flutter/material.dart' hide MenuController;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:resqboxvendor/Controller/MenuController.dart' as menu;
import 'package:resqboxvendor/Models/menu_item_model.dart';
import 'package:resqboxvendor/Screens/Menu/add_menu.dart';
import 'package:resqboxvendor/Utils/custom_appbar.dart';
import 'package:resqboxvendor/Utils/custom_border_btn.dart';
import 'package:resqboxvendor/Utils/custom_switch_android.dart';
import 'package:resqboxvendor/Utils/images.dart';
import 'package:resqboxvendor/Utils/navigations.dart';
import 'package:resqboxvendor/Utils/textstyles.dart';
import 'package:resqboxvendor/utils/colors.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  @override
  void initState() {
    super.initState();
    final controller = Provider.of<menu.MenuController>(context, listen: false);
    controller.getAllMenuItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffF3F4F8),
      appBar: CustomAppBar(
        title: "Menu",
        actions: [
          GestureDetector(
            onTap: () {
              final controller = Provider.of<menu.MenuController>(
                context,
                listen: false,
              );
              controller.toggleSearchVisibility();
            },
            child: Image.asset(AppImages.search, height: 24, width: 24),
          ),
          SizedBox(width: 24),
        ],
        isLeading: false,
      ),
      body: SafeArea(
        child: Consumer<menu.MenuController>(
          builder: (context, controller, child) {
            return Column(
              children: [
                // Search Field
                if (controller.isSearchVisible)
                  Container(
                    padding: EdgeInsets.all(16.0),
                    color: Colors.white,
                    child: Row(
                      children: [
                        Expanded(
                          child: StatefulBuilder(
                            builder: (context, setState) {
                              return TextField(
                                controller: controller.searchController,
                                decoration: InputDecoration(
                                  hintText: "Search menu items...",
                                  prefixIcon: Icon(Icons.search),
                                  suffixIcon:
                                      controller
                                          .searchController
                                          .text
                                          .isNotEmpty
                                      ? IconButton(
                                          icon: Icon(Icons.clear),
                                          onPressed: () {
                                            controller.clearSearch();
                                            setState(() {}); // Update UI
                                          },
                                        )
                                      : null,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Color(0xffE1E1E1),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Color(0xffE1E1E1),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Color(0xffEB7712),
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                onChanged: (value) {
                                  setState(
                                    () {},
                                  ); // Update clear button visibility
                                  // Debounce search - wait for user to stop typing
                                  Future.delayed(
                                    Duration(milliseconds: 500),
                                    () {
                                      if (controller.searchController.text ==
                                          value) {
                                        controller.performSearch(value);
                                      }
                                    },
                                  );
                                },
                                onSubmitted: (value) {
                                  controller.performSearch(value);
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                Container(
                  height: 1,
                  width: double.infinity,
                  color: Color(0xffDDDDDD),
                ),
                // Menu Content
                Expanded(
                  child: controller.isLoadingMenuItems
                      ? Center(child: CircularProgressIndicator())
                      : controller.menuItems.isEmpty
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset(AppImages.noMenuImage),
                                SizedBox(height: 20),
                                Text(
                                  "No food to save",
                                  style: AppTextStyles.size20SemiBold,
                                ),
                                SizedBox(height: 20),
                                Text(
                                  "Add today's ResQBoxes to save food going waste and start getting customer orders",
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.size14Medium.copyWith(
                                    color: Color(0xff777777),
                                  ),
                                ),
                                SizedBox(height: 20),
                                CustomRectBtn(
                                  width:
                                      MediaQuery.of(context).size.width * 0.45,
                                  onTap: () => {
                                    NavigateTo().nextPage(child: AddMenu()),
                                  },
                                  height: 49,
                                  borderRadius: 8,
                                  leading: Center(
                                    child: Text(
                                      "Add ResQBoxes",
                                      style: AppTextStyles.size16SemiBold
                                          .copyWith(color: Colors.white),
                                    ),
                                  ),
                                  color: Color(0xffEB7712),
                                  borderColor: const Color(0xffEB7712),
                                  textColor: Colors.black,
                                ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => controller.getAllMenuItems(
                            searchQuery:
                                controller.searchController.text
                                    .trim()
                                    .isNotEmpty
                                ? controller.searchController.text.trim()
                                : null,
                          ),
                          child: ListView.builder(
                            padding: EdgeInsets.all(16.0),
                            itemCount: controller.menuItems.length,
                            itemBuilder: (context, index) {
                              final item = controller.menuItems[index];
                              return _MenuItemCard(
                                item: item,
                                controller: controller,
                              );
                            },
                          ),
                        ),
                ),
                // Bottom Buttons
                if (controller.menuItems.isNotEmpty)
                  Container(
                    padding: EdgeInsets.all(16.0),
                    child: CustomRectBtn(
                      width: double.infinity,
                      onTap: () {
                        controller.resetForm();
                        NavigateTo().nextPage(child: AddMenu());
                      },
                      height: 49,
                      borderRadius: 8,
                      leading: Center(
                        child: Text(
                          "Add New",
                          style: AppTextStyles.size16SemiBold.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      color: Color(0xffEB7712),
                      borderColor: const Color(0xffEB7712),
                      textColor: Colors.black,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final menu.MenuController controller;

  const _MenuItemCard({required this.item, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isActive = item.isActive == 1;
    final availabilityText = isActive ? "Available" : "Not Available";
    // final stockText = isActive ? "${controller.} Boxes Available" : "Not available";
    final stockColor = isActive ? AppColors.mainAppColr : Colors.red;

    final categoryCuisine = [
      if (item.cuisine?.name != null) item.cuisine!.name!,
      if (item.categoryIds != null && item.categoryIds!.isNotEmpty)
        ...item.categoryIds!.map((e) => e.name ?? "")
      else if (item.category?.name != null)
        item.category!.name!,
    ].where((e) => e.isNotEmpty).join(", ");

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xffE1E1E1)),
        color: isActive ? Colors.white : Color(0xfff4f4f4),
      ),

      child: Padding(
        padding: EdgeInsets.all(12),
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // IMAGE
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item.image ?? "",
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 90,
                      height: 90,
                      color: Color(0xffF9F9F9),
                      child: Icon(Icons.image_not_supported),
                    ),
                  ),
                ),
                SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              (item.name ?? "").toTitleCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.size16SemiBold.copyWith(
                                color: isActive ? Colors.black : Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),

                      Text(
                        categoryCuisine.isEmpty ? "N/A" : categoryCuisine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.size14Medium.copyWith(
                          color: Color(0xff989898),
                        ),
                      ),
                      SizedBox(height: 10),

                      Row(
                        children: [
                          // if (item.menuTypes != null &&
                          //     item.menuTypes!.isNotEmpty) ...[
                          //   Image.network(
                          //     item.menuTypes!.first.image ?? "",
                          //     width: 16,
                          //     height: 16,
                          //     errorBuilder: (context, error, stackTrace) =>
                          //         const SizedBox(),
                          //   ),
                          //   SizedBox(width: 4),
                          // ],
                          // SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              isActive
                                  ? "${item.quantity ?? '0'} Boxes Available"
                                  : "Not Available",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.size12Medium.copyWith(
                                color: stockColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            if (item.discountPrice != item.price)
                              Text(
                                "\$ ${item.price != null ? item.price!.toString().replaceAll(RegExp(r'\.0$'), '') : "0"}",
                                style: AppTextStyles.size12SemiBold.copyWith(
                                  color: Colors.grey,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            SizedBox(width: 4),
                            Text(
                              "\$ ${item.discountPrice != null ? item.discountPrice!.toString().replaceAll(RegExp(r'\.0$'), '') : "0"}",
                              style: AppTextStyles.size16SemiBold.copyWith(
                                color: isActive ? Colors.black : Colors.grey,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 8),

                        // SWITCH
                        CustomThumbSwitch(
                          value: isActive,
                          activeColor: Color(0xff41AB45),
                          trackColor: Color(0xff30B435).withOpacity(0.10),
                          onChanged: (val) async {
                            if (val == true) {
                              // Toggle status ON first
                              await controller.toggleMenuItemStatus(
                                item.id!,
                                val,
                              );
                              // Then navigate to edit page
                              await controller.loadMenuItemForEditing(item);
                              NavigateTo().nextPage(child: AddMenu());
                            } else {
                              // Just toggle status OFF
                              controller.toggleMenuItemStatus(item.id!, val);
                            }
                          },
                        ),

                        SizedBox(height: 4),

                        Transform.translate(
                          offset: Offset(5, 0),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: SizedBox(
                              width: 60,
                              child: Text(
                                availabilityText,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.size12Medium.copyWith(
                                  color: Color(0xff989898),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(padding: EdgeInsetsGeometry.only(right: 26)),
                    // GestureDetector(
                    //   onTap: () => _showMenuOptions(context),
                    //   child: Padding(
                    //     padding: EdgeInsets.all(4),
                    //     child: Icon(
                    //       Icons.more_horiz,
                    //       size: 20,
                    //       color: Color(0xff989898),
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ],
            ),

            // THREE DOTS MENU - Positioned absolutely at top-right
            Positioned(
              top: -12,
              right: -5,
              child: GestureDetector(
                onTap: () => _showMenuOptions(context),
                child: Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.more_horiz,
                    size: 20,
                    color: Color(0xff989898),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMenuOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// Item Preview
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item.image ?? "",
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 80,
                      height: 80,
                      color: Color(0xffF9F9F9),
                      child: Icon(Icons.image_not_supported),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name ?? "",
                        style: AppTextStyles.size16SemiBold,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        [
                              if (item.cuisine?.name != null)
                                item.cuisine!.name!,
                              if (item.categoryIds != null &&
                                  item.categoryIds!.isNotEmpty)
                                ...item.categoryIds!.map((e) => e.name ?? "")
                              else if (item.category?.name != null)
                                item.category!.name!,
                            ].where((e) => e.isNotEmpty).join(", ").isEmpty
                            ? "N/A"
                            : [
                                if (item.cuisine?.name != null)
                                  item.cuisine!.name!,
                                if (item.categoryIds != null &&
                                    item.categoryIds!.isNotEmpty)
                                  ...item.categoryIds!.map((e) => e.name ?? "")
                                else if (item.category?.name != null)
                                  item.category!.name!,
                              ].where((e) => e.isNotEmpty).join(", "),
                        style: AppTextStyles.size14Medium.copyWith(
                          color: Color(0xff989898),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      if (item.isActive == 1)
                        Row(
                          children: [
                            // item.isVegetarian == true
                            //     ? Image.asset(AppImages.isVeg, height: 14)
                            //     : Image.asset(AppImages.nonVeg, height: 14),
                            // // Image.asset(AppImages.isVeg, height: 14),
                            // SizedBox(width: 5),
                            Text(
                              "${item.quantity ?? '0'} Boxes Available",
                              style: AppTextStyles.size12Medium.copyWith(
                                color: Color(0xffFF6B00),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: CustomRectBtn(
                    width: MediaQuery.of(context).size.width * 0.45,
                    onTap: () async {
                      Navigator.pop(context);

                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(
                            "Delete Item",
                            style: AppTextStyles.size20SemiBold,
                          ),
                          content: Text(
                            "Are you sure you want to delete this menu item?",
                            style: AppTextStyles.size14SemiBold.copyWith(
                              color: Colors.black,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(
                                "Delete",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await controller.deleteMenuItem(item.id!);
                      }
                    },
                    height: 49,
                    borderRadius: 25,
                    leading: Center(
                      child: Text(
                        "Delete",
                        style: AppTextStyles.size16SemiBold.copyWith(
                          color: Colors.black,
                        ),
                      ),
                    ),
                    color: Colors.white,
                    borderColor: Color(0xffF1913D),
                    textColor: Colors.black,
                  ),
                ),
                SizedBox(width: 12),

                /// Edit Button
                Expanded(
                  child: CustomRectBtn(
                    width: MediaQuery.of(context).size.width * 0.45,
                    onTap: () async {
                      // Close bottom sheet
                      Navigator.pop(context);

                      // Load menu item for editing
                      await controller.loadMenuItemForEditing(item);

                      // Navigate to AddMenu screen (it will be in edit mode)
                      NavigateTo().nextPage(child: AddMenu());
                    },
                    height: 49,
                    borderRadius: 25,
                    leading: Center(
                      child: Text(
                        "Edit",
                        style: AppTextStyles.size16SemiBold.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    color: AppColors.mainAppColr,
                    borderColor: AppColors.mainAppColr,
                    textColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String toTitleCase() {
    if (isEmpty) return this;
    return split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }
}
