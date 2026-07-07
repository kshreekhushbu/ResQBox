import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resqbox_user/Controllers/home_controller.dart';
import 'package:resqbox_user/Screens/MainSection/Home/popular_kitchen_card.dart';
import 'package:resqbox_user/Screens/MainSection/Home/wishlist_card_screen.dart';
import 'package:resqbox_user/Utils/colors.dart';
import 'package:resqbox_user/Utils/custom_appbar.dart';
import 'package:resqbox_user/Utils/customtext.dart';
import 'package:resqbox_user/Utils/mediaquery.dart';
import 'package:resqbox_user/Utils/navigations.dart';

class PopularSeeAll extends StatefulWidget {
  const PopularSeeAll({super.key});

  @override
  State<PopularSeeAll> createState() => _PopularSeeAllState();
}

class _PopularSeeAllState extends State<PopularSeeAll> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final homeController =
          Provider.of<HomeController>(context, listen: false);

      await Provider.of<HomeController>(context, listen: false)
          .getPopularRestaurantsApi(
              homeController.locLatitude, homeController.locLongitude);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeController>(builder: (context, homeController, child) {
      return Scaffold(
        backgroundColor: AppColors.tWhiteColor,
        appBar: CustomAppBar(
          title: "Popular Near You",
          titleFontSize: 0.022,
          backgroundColor: AppColors.tWhiteColor,
          backTap: () {
            NavigateTo().backPage();
          },
        ),
        body: SafeArea(
          child: homeController.isLoadingPopularRestaurants == true
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : homeController.popularNearModelData?.data?.isEmpty == true
                  ? const Center(
                      child: CustomText(text: "No popular restaurants found"))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount:
                          homeController.popularNearModelData?.data?.length ??
                              0,
                      // padding: EdgeInsets.only(right: Sizes.width * 0.04),
                      itemBuilder: (context, index) => Padding(
                        padding: EdgeInsets.only(
                          left: Sizes.width * 0.04,
                          // top: Sizes.height * 0.015,
                          bottom: Sizes.height * 0.015,
                          right: Sizes.width * 0.04,
                        ),
                        child: PopularKitchenCard(
                          item:
                              homeController.popularNearModelData?.data?[index],
                          cardWidth: Sizes.width,
                        ),
                      ),
                    ),
        ),
      );
    });
  }
}
