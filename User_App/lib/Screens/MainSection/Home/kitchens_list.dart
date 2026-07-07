import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resqbox_user/Controllers/cart_controller.dart';
import 'package:resqbox_user/Controllers/home_controller.dart';
import 'package:resqbox_user/Screens/MainSection/Home/home.dart';
import 'package:resqbox_user/Screens/MainSection/Home/wishlist_card_screen.dart';
import 'package:resqbox_user/Screens/MainSection/bottom_navigation.dart';
import 'package:resqbox_user/Utils/colors.dart';
import 'package:resqbox_user/Utils/custom_image_widget.dart';
import 'package:resqbox_user/Utils/custom_padding.dart';
import 'package:resqbox_user/Utils/custom_tap.dart';
import 'package:resqbox_user/Utils/customtext.dart';
import 'package:resqbox_user/Utils/images.dart';
import 'package:resqbox_user/Utils/mediaquery.dart';
import 'package:resqbox_user/Utils/navigations.dart';
import 'package:resqbox_user/Utils/textformfield.dart';

class KitchensList extends StatefulWidget {
  final int? cuisineId;
  final String? cuisineName;
  const KitchensList({super.key, this.cuisineId, this.cuisineName});

  @override
  State<KitchensList> createState() => _KitchensListState();
}

class _KitchensListState extends State<KitchensList> {
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final homeController =
          Provider.of<HomeController>(context, listen: false);
      await Provider.of<HomeController>(context, listen: false)
          .getAllRestaurantsApi(widget.cuisineId, homeController.locLatitude,
              homeController.locLongitude);
      await Provider.of<CartController>(context, listen: false).getCartApi();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<HomeController, CartController>(
        builder: (context, homeController, cartController, child) {
      int getTotalCartCount() {
        final items = cartController.cartData?.cartItems ?? [];
        return items.fold<int>(
          0,
          (sum, item) => sum + (item.quantity ?? 0),
        );
      }

      return Scaffold(
        backgroundColor: const Color(0XFFF6F6F6),
        appBar: AppBar(
          backgroundColor: AppColors.tWhiteColor,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
          leading: IconButton(
            onPressed: () {
              NavigateTo().backPage();
            },
            icon: const Icon(
              Icons.arrow_back_ios,
              color: AppColors.tBlackColor,
            ),
          ),
          title: CustomText(
            text: widget.cuisineName ?? '',
            fontSize: 0.022,
            fontWeight: FontWeight.w600,
          ),
          actions: [
            Consumer<CartController>(
              builder: (context, cart, child) {
                final count = cart.cartData?.priceDetails?.totalItems ??
                    cart.cartData?.cartItems?.fold<int>(
                      0,
                      (sum, e) => sum + (e.quantity ?? 0),
                    ) ??
                    0;
                return CustomPadding(
                  right: .04,
                  child: CustomTap(
                    onTap: () {
                      NavigateTo()
                          .nextPage(child: BottomNavigation(initialIndex: 2));
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CustomImage(
                          image: AppImages.cart,
                          height: .03,
                        ),
                        if (cartController.cartData?.cartItems?.isNotEmpty ==
                                true &&
                            getTotalCartCount() > 0)
                          Positioned(
                            right: 0,
                            top: -4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0XFFF14E47),
                                shape: BoxShape.circle,
                              ),
                              child: CustomText(
                                text: '${getTotalCartCount()}',
                                fontSize: 0.012,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
          bottom: PreferredSize(
              preferredSize: Size.fromHeight(Sizes.height * .068),
              child: Column(
                children: [
                  const Divider(
                    color: Color(0XFFE9E9E9),
                    height: 1,
                    thickness: 1,
                  ),
                  CustomPadding(
                    top: .01,
                    left: .04,
                    right: .04,
                    bottom: .01,
                    child: Row(
                      children: [
                        Expanded(
                          child: CustomTextFormField(
                              controller: searchController,
                              hintText: "Search...",
                              hintFontSize: .016,
                              fillColor: AppColors.tWhiteColor,
                              hintColor: const Color(0XFF727272),
                              prefixIconHeight: .024,
                              prefixIcon: AppImages.locSearch,
                              customBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  borderSide: const BorderSide(
                                      color: AppColors.tPrimaryColor))),
                        ),
                        // SizedBox(width: Sizes.width * 0.02),
                        // Container(
                        //   width: Sizes.width * .1,
                        //   height: Sizes.height * .043,
                        //   decoration: BoxDecoration(
                        //     border: Border.all(color: const Color(0XFFD4D4D4)),
                        //     color: AppColors.tWhiteColor,
                        //     borderRadius: BorderRadius.circular(8),
                        //   ),
                        //   child: Icon(
                        //     Icons.filter_list,
                        //     color: AppColors.tBlackColor,
                        //     size: Sizes.height * 0.024,
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ],
              )),
        ),
        body: homeController.isLoadingRestaurants
            ? const Center(child: CircularProgressIndicator())
            : homeController.allRestaurantsData?.kitchens?.isEmpty ?? true
                ? const Center(child: CustomText(text: "No restaurants found"))
                : SafeArea(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount:
                          homeController.allRestaurantsData?.kitchens?.length ??
                              0,
                      // padding: EdgeInsets.only(right: Sizes.width * 0.04),
                      itemBuilder: (context, index) => Padding(
                        padding: EdgeInsets.only(
                          left: Sizes.width * 0.04,
                          top: Sizes.height * 0.015,
                          right: Sizes.width * 0.04,
                        ),
                        child: WishListCard(
                            item: homeController
                                .allRestaurantsData?.kitchens?[index],
                            from: "kitchens"),
                      ),
                    ),
                  ),
      );
    });
  }
}
