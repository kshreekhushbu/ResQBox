import 'package:flutter/material.dart' hide MenuController;
import 'package:provider/provider.dart';
import 'package:resqboxvendor/Controller/MenuController.dart' as menu;
import 'package:resqboxvendor/Models/menu_item_model.dart';
import 'package:resqboxvendor/Screens/Menu/add_menu.dart';
import 'package:resqboxvendor/Utils/custom_appbar.dart';
import 'package:resqboxvendor/Utils/images.dart';
import 'package:resqboxvendor/Utils/navigations.dart';
import 'package:resqboxvendor/Utils/textstyles.dart';

class EditMenuScreen extends StatefulWidget {
  const EditMenuScreen({super.key});

  @override
  State<EditMenuScreen> createState() => _EditMenuScreenState();
}

class _EditMenuScreenState extends State<EditMenuScreen> {
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
        title: "Edit menu",
        isLeading: true,
        backTap: () {
          NavigateTo().backPage();
        },
      ),
      body: SafeArea(
        child: Consumer<menu.MenuController>(
          builder: (context, controller, child) {
            if (controller.isLoadingMenuItems) {
              return Center(child: CircularProgressIndicator());
            }

            if (controller.menuItems.isEmpty) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "No items in menu",
                        style: AppTextStyles.size20SemiBold,
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Add items to edit them",
                        textAlign: TextAlign.center,
                        style: AppTextStyles.size14Medium.copyWith(
                          color: Color(0xff777777),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => controller.getAllMenuItems(),
              child: ListView.builder(
                padding: EdgeInsets.all(16.0),
                itemCount: controller.menuItems.length,
                itemBuilder: (context, index) {
                  final item = controller.menuItems[index];
                  return _EditMenuItemCard(item: item, controller: controller);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EditMenuItemCard extends StatelessWidget {
  final MenuItem item;
  final menu.MenuController controller;

  const _EditMenuItemCard({required this.item, required this.controller});

  @override
  Widget build(BuildContext context) {
    final categoryCuisine = [
      if (item.cuisine?.name != null) item.cuisine!.name!,
      if (item.category?.name != null) item.category!.name!,
    ].join(' & ');

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xffE1E1E1)),
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item.image != null && item.image!.isNotEmpty
                  ? Image.network(
                      item.image!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 100,
                          height: 100,
                          color: Color(0xffF9F9F9),
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                          ),
                        );
                      },
                    )
                  : Container(
                      width: 100,
                      height: 100,
                      color: Color(0xffF9F9F9),
                      child: Icon(Icons.image, color: Colors.grey),
                    ),
            ),
            SizedBox(width: 12),
            // Middle Section - Name, Category, Vegetarian Icon
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name ?? "",
                    style: AppTextStyles.size16SemiBold,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  if (categoryCuisine.isNotEmpty)
                    Text(
                      categoryCuisine,
                      style: AppTextStyles.size14Medium.copyWith(
                        color: Color(0xff989898),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  SizedBox(height: 8),
                  if (item.isVegetarian == true) Image.asset(AppImages.isVeg),
                ],
              ),
            ),
            SizedBox(width: 12),
            // Right Section - Price, Edit, Delete
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "\$ ${item.price != null ? item.price!.toString().replaceAll(RegExp(r'\.0$'), '') : "0"}",
                  style: AppTextStyles.size16SemiBold.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                // Edit and Delete Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        await controller.loadMenuItemForEditing(item);
                        if (context.mounted) {
                          NavigateTo().nextPage(child: AddMenu());
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Color(0xffF3F4F8),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.edit,
                          size: 18,
                          color: Color(0xffEB7712),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text("Delete Item"),
                            content: Text(
                              "Are you sure you want to delete this menu item?",
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
                      child: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Color(0xffF3F4F8),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
