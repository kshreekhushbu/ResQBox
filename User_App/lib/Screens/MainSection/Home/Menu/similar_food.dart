import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resqbox_user/Controllers/home_controller.dart';
import 'package:resqbox_user/Controllers/menu_controller.dart';
import 'package:resqbox_user/Screens/MainSection/Home/food_menu_card.dart';
import 'package:resqbox_user/Utils/colors.dart';
import 'package:resqbox_user/Utils/custom_appbar.dart';
import 'package:resqbox_user/Utils/navigations.dart';

class SimilarFood extends StatefulWidget {
  final int? kitchenId;
  const SimilarFood({super.key, this.kitchenId});

  @override
  State<SimilarFood> createState() => _SimilarFoodState();
}

class _SimilarFoodState extends State<SimilarFood> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    final homeController = Provider.of<HomeController>(context, listen: false);
    Provider.of<FoodMenuController>(context, listen: false).getMenuByCategoryId(
        widget.kitchenId,
        null,
        homeController.locLatitude,
        homeController.locLongitude,
        from: "kitchen");
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FoodMenuController>(builder: (context, controller, child) {
      return Scaffold(
        backgroundColor: AppColors.tWhiteColor,
        appBar: CustomAppBar(
          title: "More from this Restaurant",
          titleFontSize: 0.022,
          backgroundColor: AppColors.tWhiteColor,
          backTap: () {
            NavigateTo().backPage();
          },
        ),
        body: controller.isMenuLoading == true
            ? const Center(child: CircularProgressIndicator())
            : ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                itemCount:
                    controller.menuByCategoryData?.menuItems?.length ?? 0,
                separatorBuilder: (_, __) => const Divider(
                  color: Color(0XFFD9D9D9),
                ),
                itemBuilder: (context, index) {
                  final menuItem =
                      controller.menuByCategoryData?.menuItems?[index];
                  return FoodMenuCard(item: menuItem, from: "menu");
                },
              ),
      );
    });
  }
}
