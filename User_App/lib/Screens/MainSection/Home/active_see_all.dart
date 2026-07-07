import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resqbox_user/Controllers/home_controller.dart';
import 'package:resqbox_user/Screens/MainSection/Home/home.dart';
import 'package:resqbox_user/Utils/colors.dart';
import 'package:resqbox_user/Utils/custom_appbar.dart';
import 'package:resqbox_user/Utils/customtext.dart';
import 'package:resqbox_user/Utils/mediaquery.dart';
import 'package:resqbox_user/Utils/navigations.dart';

class ActiveSeeAll extends StatefulWidget {
  const ActiveSeeAll({super.key});

  @override
  State<ActiveSeeAll> createState() => _ActiveSeeAllState();
}

class _ActiveSeeAllState extends State<ActiveSeeAll> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final homeController =
          Provider.of<HomeController>(context, listen: false);
      await homeController.getActiveRestaurantsApi(
          homeController.locLatitude, homeController.locLongitude);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeController>(builder: (context, homeController, child) {
      return Scaffold(
        backgroundColor: AppColors.tWhiteColor,
        appBar: CustomAppBar(
          backgroundColor: AppColors.tWhiteColor,
          title: "Restaurants Near You",
          backTap: () {
            NavigateTo().backPage();
          },
        ),
        body: homeController.isLoadingActiveRestaurants == true
            ? const Center(child: CircularProgressIndicator())
            : homeController.activeRestaurantsModelData?.data?.isEmpty == true
                ? const Center(
                    child: CustomText(text: "No active restaurants found"))
                : SafeArea(
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: AlwaysScrollableScrollPhysics(),
                      itemCount: homeController
                              .activeRestaurantsModelData?.data?.length ??
                          0,
                      itemBuilder: (context, index) => Padding(
                        padding: EdgeInsets.only(
                          bottom: index ==
                                  (homeController.activeRestaurantsModelData
                                              ?.data?.length ??
                                          0) -
                                      1
                              ? 0
                              : Sizes.height * 0.015,
                          left: Sizes.width * 0.04,
                          right: Sizes.width * 0.04,
                        ),
                        child: ActiveRestaurantCard(
                            item: homeController
                                .activeRestaurantsModelData?.data?[index]),
                      ),
                    ),
                  ),
      );
    });
  }
}
