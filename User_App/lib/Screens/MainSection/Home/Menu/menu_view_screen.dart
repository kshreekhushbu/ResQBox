import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resqbox_user/Controllers/cart_controller.dart';
import 'package:resqbox_user/Controllers/home_controller.dart';
import 'package:resqbox_user/Controllers/menu_controller.dart';
import 'package:resqbox_user/Screens/Authentication/guest_login_screen.dart';
import 'package:resqbox_user/Screens/MainSection/Home/Menu/similar_food.dart';
import 'package:resqbox_user/Screens/MainSection/Home/food_menu_card.dart';
import 'package:resqbox_user/Screens/MainSection/Home/kitchens_view_screen.dart';
import 'package:resqbox_user/Screens/MainSection/Home/popular_kitchen_card.dart';
import 'package:resqbox_user/Screens/MainSection/bottom_navigation.dart';
import 'package:resqbox_user/Utils/colors.dart';
import 'package:resqbox_user/Utils/custom_image_widget.dart';
import 'package:resqbox_user/Utils/custom_padding.dart';
import 'package:resqbox_user/Utils/custom_sizedbox.dart';
import 'package:resqbox_user/Utils/custom_tap.dart';
import 'package:resqbox_user/Utils/customtext.dart';
import 'package:resqbox_user/Utils/horizontal_line.dart';
import 'package:resqbox_user/Utils/images.dart';
import 'package:resqbox_user/Utils/map_launcher.dart';
import 'package:resqbox_user/Utils/mediaquery.dart';
import 'package:resqbox_user/Utils/navigations.dart';
import 'package:resqbox_user/Utils/network_image.dart';
import 'package:resqbox_user/Screens/MainSection/Cart/cart.dart';
import 'package:resqbox_user/Utils/shared_preference_helper.dart';

class MenuViewScreen extends StatefulWidget {
  final int? menuId;
  const MenuViewScreen({super.key, this.menuId});

  @override
  State<MenuViewScreen> createState() => _MenuViewScreenState();
}

class _MenuViewScreenState extends State<MenuViewScreen> {
  late final PageController _pageController;
  final List<String> _bannerImages = const [
    "https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=1200&q=60",
    "https://images.unsplash.com/photo-1447078806655-40579c2520d6?auto=format&fit=crop&w=1200&q=60",
    "https://images.unsplash.com/photo-1512058564366-18510be2db19?auto=format&fit=crop&w=1200&q=60",
  ];
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final homeController =
          Provider.of<HomeController>(context, listen: false);
      await Provider.of<FoodMenuController>(context, listen: false).menuViewApi(
          widget.menuId,
          homeController.locLatitude,
          homeController.locLongitude);
      await Provider.of<CartController>(context, listen: false).getCartApi();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FoodMenuController>(builder: (context, controller, child) {
      return Scaffold(
        backgroundColor: AppColors.tWhiteColor,
        bottomNavigationBar: controller.isMenuViewLoading
            ? SizedBox.shrink()
            : Consumer<CartController>(
                builder: (context, cartController, child) {
                  final cartItems = cartController.cartData?.cartItems ?? [];
                  final totalQuantity = cartItems.fold<int>(
                    0,
                    (sum, item) => sum + (item.quantity ?? 0),
                  );
                  final hasItems = totalQuantity > 0;

                  if (!hasItems) {
                    return const SizedBox.shrink();
                  }

                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Sizes.width * 0.04,
                      vertical: Sizes.height * 0.025,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.tWhiteColor,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0XFF000000).withOpacity(0.2),
                          blurRadius: 4,
                          offset: Offset(0, -3),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: CustomTap(
                        onTap: () {
                          NavigateTo().nextPage(
                              child: BottomNavigation(initialIndex: 2));
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.green,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: Sizes.height * 0.015,
                            horizontal: Sizes.width * 0.04,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.shopping_cart,
                                    color: AppColors.tWhiteColor,
                                    size: Sizes.height * 0.025,
                                  ),
                                  SizedBox(width: Sizes.width * 0.02),
                                  CustomText(
                                    text:
                                        '$totalQuantity ${totalQuantity == 1 ? 'Item' : 'Items'}',
                                    fontSize: 0.018,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.tWhiteColor,
                                  ),
                                ],
                              ),
                              const CustomText(
                                text: "View Cart",
                                fontSize: 0.018,
                                // decoration: TextDecoration.underline,
                                // decorationColor: AppColors.tWhiteColor,
                                fontWeight: FontWeight.w600,
                                color: AppColors.tWhiteColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
        body: controller.isMenuViewLoading
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(
                          child: Stack(
                            children: [
                              ClipRRect(
                                  borderRadius: BorderRadius.circular(0),
                                  child: CustomNetworkImage(
                                    url: controller.menuViewModelData?.menuItem
                                            ?.image ??
                                        '',
                                    fit: BoxFit.cover,
                                    height: 0.39,
                                    width: Sizes.width,
                                  )),
                              // PageView.builder(
                              //   controller: _pageController,
                              //   itemCount: controller.menuViewModelData?.menuItem
                              //           ?.image?.length ??
                              //       0,
                              //   onPageChanged: (value) {
                              //     setState(() {
                              //       _currentPage = value;
                              //     });
                              //   },
                              //   itemBuilder: (context, index) => Padding(
                              //     padding: const EdgeInsets.symmetric(
                              //         // horizontal: Sizes.width * 0.04,
                              //         ),
                              //     child:
                              //   ),
                              // ),
                              controller.menuViewModelData?.menuItem
                                          ?.discountPercentage !=
                                      null
                                  ? Positioned(
                                      right: 0,
                                      top: Sizes.height * 0.06,
                                      child: Stack(
                                        alignment: Alignment
                                            .centerRight, // ✅ Center everything inside Stack
                                        children: [
                                          const CustomImage(
                                            image: AppImages.tag,
                                            height: .04,
                                            width: .25,
                                            fit: BoxFit.cover,
                                          ),
                                          CustomPadding(
                                            right: .02,
                                            child: CustomText(
                                              // ✅ No Positioned needed
                                              text:
                                                  "${controller.menuViewModelData?.menuItem?.discountPercentage?.round() ?? 0}% OFF",
                                              fontSize: .014,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : const SizedBox(),
                              // Positioned(
                              //   bottom: Sizes.height * 0.02,
                              //   left: 0,
                              //   right: 0,
                              //   child: Row(
                              //     mainAxisAlignment: MainAxisAlignment.center,
                              //     children: List.generate(
                              //       controller.menuViewModelData?.menuItem?.image
                              //               ?.length ??
                              //           0,
                              //       (index) => _IndicatorDot(
                              //           isActive: _currentPage == index),
                              //     ),
                              //   ),
                              // ),
                            ],
                          ),
                        ),
                        CustomPadding(
                          horizontal: .04,
                          vertical: .02,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: CustomText(
                                      text: (controller.menuViewModelData
                                                  ?.menuItem?.name ??
                                              '')
                                          .split(' ')
                                          .map((word) => word.isNotEmpty
                                              ? '${word[0].toUpperCase()}${word.substring(1)}'
                                              : '')
                                          .join(' '),
                                      fontSize: 0.02,
                                      overflow: TextOverflow.ellipsis,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Consumer<CartController>(
                                    builder: (context, cart, child) {
                                      final cartItems =
                                          cart.cartData?.cartItems ?? [];
                                      final matched = cartItems
                                          .where((e) =>
                                              e.menuItemId ==
                                              controller.menuViewModelData
                                                  ?.menuItem?.id)
                                          .toList();
                                      final cartItem = matched.isNotEmpty
                                          ? matched.first
                                          : null;

                                      if (cartItem == null) {
                                        return CustomTap(
                                          onTap: () async {
                                            if (SharedPreferencesHelper()
                                                    .getString("loginType") ==
                                                "skip") {
                                              SharedPreferencesHelper()
                                                  .remove("ApiToken");
                                              SharedPreferencesHelper()
                                                  .remove("Token2");
                                              SharedPreferencesHelper()
                                                  .remove("role");
                                              SharedPreferencesHelper()
                                                  .clearAlldata();
                                              NavigateTo().pushRemove(
                                                  child: GuestLoginScreen());
                                              return;
                                            }
                                            if (controller.menuViewModelData
                                                    ?.menuItem?.id ==
                                                null) return;
                                            await Provider.of<CartController>(
                                              context,
                                              listen: false,
                                            ).addToCartApi(
                                                menuItemId: controller
                                                        .menuViewModelData
                                                        ?.menuItem
                                                        ?.id ??
                                                    0,
                                                quantity: 1);
                                          },
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: Sizes.width * 0.055,
                                              vertical: Sizes.height * 0.0065,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      Sizes.height * 0.004),
                                              border: Border.all(
                                                  color:
                                                      const Color(0XFFD9D9D9)),
                                            ),
                                            child: const CustomText(
                                              text: "ADD",
                                              fontWeight: FontWeight.w600,
                                              fontSize: 0.016,
                                              color: AppColors.tPrimaryColor,
                                            ),
                                          ),
                                        );
                                      } else {
                                        return Container(
                                          padding: EdgeInsets.symmetric(
                                            vertical: Sizes.height * 0.005,
                                            horizontal: Sizes.width * 0.02,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            border: Border.all(
                                                color: const Color(0XFFD9D9D9)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              GestureDetector(
                                                onTap: () async {
                                                  if (SharedPreferencesHelper()
                                                          .getString(
                                                              "loginType") ==
                                                      "skip") {
                                                    SharedPreferencesHelper()
                                                        .remove("ApiToken");
                                                    SharedPreferencesHelper()
                                                        .remove("Token2");
                                                    SharedPreferencesHelper()
                                                        .remove("role");
                                                    SharedPreferencesHelper()
                                                        .clearAlldata();
                                                    NavigateTo().pushRemove(
                                                        child:
                                                            GuestLoginScreen());
                                                    return;
                                                  }
                                                  if (controller
                                                          .menuViewModelData
                                                          ?.menuItem
                                                          ?.id ==
                                                      null) {
                                                    return;
                                                  }
                                                  await Provider.of<
                                                      CartController>(
                                                    context,
                                                    listen: false,
                                                  ).addToCartApi(
                                                      menuItemId: controller
                                                              .menuViewModelData
                                                              ?.menuItem
                                                              ?.id ??
                                                          0,
                                                      quantity: -1);
                                                },
                                                child: const Icon(Icons.remove,
                                                    size: 18),
                                              ),
                                              CustomPadding(
                                                horizontal: .03,
                                                child: CustomText(
                                                  text:
                                                      '${cartItem.quantity ?? 0}',
                                                  color:
                                                      AppColors.tPrimaryColor,
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () async {
                                                  if (SharedPreferencesHelper()
                                                          .getString(
                                                              "loginType") ==
                                                      "skip") {
                                                    SharedPreferencesHelper()
                                                        .remove("ApiToken");
                                                    SharedPreferencesHelper()
                                                        .remove("Token2");
                                                    SharedPreferencesHelper()
                                                        .remove("role");
                                                    SharedPreferencesHelper()
                                                        .clearAlldata();
                                                    NavigateTo().pushRemove(
                                                        child:
                                                            GuestLoginScreen());
                                                    return;
                                                  }
                                                  if (controller
                                                          .menuViewModelData
                                                          ?.menuItem
                                                          ?.id ==
                                                      null) {
                                                    return;
                                                  }
                                                  await Provider.of<
                                                      CartController>(
                                                    context,
                                                    listen: false,
                                                  ).addToCartApi(
                                                      menuItemId: controller
                                                              .menuViewModelData
                                                              ?.menuItem
                                                              ?.id ??
                                                          0,
                                                      quantity: 1);
                                                },
                                                child: const Icon(Icons.add,
                                                    size: 18),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                    },
                                  )
                                ],
                              ),
                              const CustomSizedBox(
                                height: .005,
                              ),
                              Row(
                                children: [
                                  CustomText(
                                    text:
                                        "\$ ${controller.menuViewModelData?.menuItem?.discountPrice?.toStringAsFixed(2) ?? 0.0}",
                                    fontSize: 0.024,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.tPrimaryColor,
                                  ),
                                  SizedBox(width: 12),
                                  Stack(
                                    children: [
                                      CustomText(
                                        text:
                                            "\$ ${controller.menuViewModelData?.menuItem?.price?.toStringAsFixed(2) ?? 0.0}",
                                        fontSize: 0.018,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.hintTclr,
                                      ),
                                      Positioned.fill(
                                        child: CustomPaint(
                                          painter: DiagonalLinePainter(
                                            color: AppColors.tPrimaryColor,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const CustomSizedBox(
                                height: 0.01,
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    vertical: Sizes.height * 0.015,
                                    horizontal: Sizes.width * .06),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: const Color(0XFFFFF8EA)),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        controller.menuViewModelData?.menuItem
                                                    ?.foodtype !=
                                                null
                                            ? CustomNetworkImage(
                                                url: controller
                                                        .menuViewModelData
                                                        ?.menuItem
                                                        ?.foodtype
                                                        ?.image ??
                                                    '',
                                                height: .024,
                                                width: .04,
                                              )
                                            : SizedBox(),

                                        // Image.asset(
                                        //   AppImages.veg,
                                        //   color: controller
                                        //               .menuViewModelData
                                        //               ?.menuItem
                                        //               ?.isVegetarian ==
                                        //           true
                                        //       ? Color(0XFF4CAF50)
                                        //       : AppColors.red,
                                        //   height: Sizes.height * .02,
                                        // ),
                                        const CustomSizedBox(
                                          width: .02,
                                        ),
                                        controller.menuViewModelData?.menuItem
                                                    ?.foodtype !=
                                                null
                                            ? CustomText(
                                                text: controller
                                                        .menuViewModelData
                                                        ?.menuItem
                                                        ?.foodtype
                                                        ?.name ??
                                                    '',
                                                fontSize: .016,
                                                fontWeight: FontWeight.w400,
                                              )
                                            : SizedBox()
                                      ],
                                    ),
                                    // Row(
                                    //   children: [
                                    //     Image.asset(
                                    //       AppImages.cartMirchi,
                                    //       height: Sizes.height * .025,
                                    //     ),
                                    //     const CustomSizedBox(
                                    //       width: .02,
                                    //     ),
                                    //     CustomText(
                                    //       text: controller.menuViewModelData
                                    //               ?.menuItem?.isSpicy ??
                                    //           '',
                                    //       fontSize: .016,
                                    //       fontWeight: FontWeight.w400,
                                    //     )
                                    //   ],
                                    // ),
                                    Row(
                                      children: [
                                        Icon(Icons.star,
                                            size: 18,
                                            color: AppColors.tPrimaryColor),
                                        CustomSizedBox(
                                          width: .02,
                                        ),
                                        CustomText(
                                          text: controller.menuViewModelData
                                                  ?.menuItem?.rating ??
                                              '',
                                          fontSize: .016,
                                          fontWeight: FontWeight.w400,
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const CustomSizedBox(
                                height: 0.02,
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: Sizes.height * 0.015,
                                  horizontal: Sizes.width * 0.02,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0XFFE9FBEF),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: const Color(0XFF00D341)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                        padding: EdgeInsets.symmetric(
                                          vertical: Sizes.height * 0.009,
                                          horizontal: Sizes.width * 0.02,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0XFF00D341),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: const CustomImage(
                                          image: AppImages.clock,
                                          height: .024,
                                          color: AppColors.tWhiteColor,
                                        )),
                                    const CustomSizedBox(
                                      width: .02,
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CustomText(
                                          text: "Pickup Time",
                                          fontSize: .014,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        CustomSizedBox(height: .005),
                                        CustomText(
                                          text:
                                              "Before ${controller.menuViewModelData?.menuItem?.endTime ?? ''}", //${controller.menuViewModelData?.menuItem?.startTime ?? ''} -
                                          fontSize: .016,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.tBlackColor,
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              ),
                              const CustomSizedBox(
                                height: 0.02,
                              ),
                              const CustomPadding(
                                vertical: 0.008,
                                child: CustomText(
                                  text: "Description",
                                  fontSize: .018,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              CustomText(
                                text: controller.menuViewModelData?.menuItem
                                        ?.description ??
                                    '',
                                // "Dig into a bowl of fragrant basmati rice cooked with fresh vegetables, whole spices, and a hint of saffron. Our Veg Biryani is slow-cooked for rich flavor and served with raita on the side",
                                fontSize: .016,
                                fontWeight: FontWeight.w400,
                                color: AppColors.hintTclr,
                              ),
                              CustomPadding(
                                vertical: .025,
                                child: HorizontalDottedLine(
                                  width: Sizes.width,
                                  color: AppColors.hintTclr,
                                ),
                              ),
                              Row(
                                children: [
                                  CustomTap(
                                    onTap: () {
                                      NavigateTo().nextPage(
                                          child: KitchensViewScreen(
                                              restaurantId: controller
                                                  .menuViewModelData
                                                  ?.menuItem
                                                  ?.restaurant
                                                  ?.kitchenId));
                                    },
                                    child: ClipOval(
                                      child: SizedBox(
                                        width: Sizes.height * 0.06,
                                        height: Sizes.height * 0.06,
                                        child: (controller
                                                        .menuViewModelData
                                                        ?.menuItem
                                                        ?.restaurant
                                                        ?.photos
                                                        ?.kitchenProfilePhoto ==
                                                    null ||
                                                controller
                                                        .menuViewModelData
                                                        ?.menuItem
                                                        ?.restaurant
                                                        ?.photos
                                                        ?.kitchenProfilePhoto
                                                        ?.isEmpty ==
                                                    true)
                                            ? CircleAvatar(
                                                backgroundColor:
                                                    AppColors.tPrimaryColor,
                                                child: CustomText(
                                                  text: (controller
                                                              .menuViewModelData
                                                              ?.menuItem
                                                              ?.restaurant
                                                              ?.kitchenName
                                                              ?.isNotEmpty ??
                                                          false)
                                                      ? (controller
                                                              .menuViewModelData
                                                              ?.menuItem
                                                              ?.restaurant
                                                              ?.kitchenName?[0]
                                                              .toUpperCase() ??
                                                          'K')
                                                      : 'K',
                                                  fontSize: 0.024,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.tWhiteColor,
                                                ),
                                              )
                                            : CustomNetworkImage(
                                                // 'https://toppng.com/uploads/preview/veg-non-veg-plate-of-food-11562983570pkk1qzqvhy.png',
                                                fit: BoxFit.cover,
                                                url: controller
                                                        .menuViewModelData
                                                        ?.menuItem
                                                        ?.restaurant
                                                        ?.photos
                                                        ?.kitchenProfilePhoto ??
                                                    '',
                                              ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: Sizes.width * 0.02),
                                  Expanded(
                                    child: CustomTap(
                                      onTap: () {
                                        NavigateTo().nextPage(
                                            child: KitchensViewScreen(
                                                restaurantId: controller
                                                    .menuViewModelData
                                                    ?.menuItem
                                                    ?.restaurant
                                                    ?.kitchenId));
                                      },
                                      child: CustomText(
                                        text: (controller
                                                    .menuViewModelData
                                                    ?.menuItem
                                                    ?.restaurant
                                                    ?.kitchenName ??
                                                '')
                                            .split(' ')
                                            .map((word) => word.isNotEmpty
                                                ? '${word[0].toUpperCase()}${word.substring(1)}'
                                                : '')
                                            .join(' '),
                                        fontSize: 0.018,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.8,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        color: Color(0xFF111827),
                                        decoration: TextDecoration.underline,
                                        decorationColor: Color(0xFF4B5563),
                                      ),
                                    ),
                                  ),
                                  CustomTap(
                                    onTap: () {
                                      final latitude = controller
                                          .menuViewModelData
                                          ?.menuItem
                                          ?.restaurant
                                          ?.address
                                          ?.latitude;
                                      final longitude = controller
                                          .menuViewModelData
                                          ?.menuItem
                                          ?.restaurant
                                          ?.address
                                          ?.longitude;

                                      if (latitude != null &&
                                          longitude != null) {
                                        MapLauncher.openGoogleMaps(
                                          latitude: latitude,
                                          longitude: longitude,
                                        );
                                      }
                                    },
                                    child: const CustomText(
                                      text: "View on Map",
                                      fontSize: .018,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const CustomSizedBox(
                                height: .02,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomImage(
                                    image: AppImages.location,
                                    height: .024,
                                  ),
                                  CustomSizedBox(
                                    width: .02,
                                  ),
                                  Expanded(
                                    child: CustomText(
                                      text:
                                          "${controller.menuViewModelData?.menuItem?.restaurant?.address?.street ?? ''}, ${controller.menuViewModelData?.menuItem?.restaurant?.address?.city ?? ''}, ${controller.menuViewModelData?.menuItem?.restaurant?.address?.state ?? ''}, ${controller.menuViewModelData?.menuItem?.restaurant?.address?.pincode ?? ''}",
                                      fontSize: .016,
                                      fontWeight: FontWeight.w400,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                      color: Color(0XFF4B5563),
                                    ),
                                  ),
                                ],
                              ),
                              CustomPadding(
                                vertical: .015,
                                child: Row(
                                  children: [
                                    RatingStars(
                                        rating: double.parse(controller
                                                .menuViewModelData
                                                ?.menuItem
                                                ?.restaurant
                                                ?.rating ??
                                            '0.0')),
                                    SizedBox(width: Sizes.width * 0.03),
                                    const Icon(
                                      Icons.circle,
                                      size: 5,
                                      color: Color(0xFF989898),
                                    ),
                                    SizedBox(width: Sizes.width * 0.024),
                                    Row(
                                      children: [
                                        Image.asset(
                                          AppImages.distance,
                                          height: Sizes.height * 0.016,
                                          color: AppColors.green,
                                        ),
                                        SizedBox(width: Sizes.width * 0.015),
                                        CustomText(
                                          text:
                                              "${controller.menuViewModelData?.menuItem?.restaurant?.distanceKm?.toStringAsFixed(1) ?? 0.0} km",
                                          fontSize: 0.014,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF4B5563),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              CustomPadding(
                                vertical: .025,
                                child: HorizontalDottedLine(
                                  width: Sizes.width,
                                  color: AppColors.hintTclr,
                                ),
                              ),
                              controller.menuViewModelData?.recommendedItems
                                          ?.isNotEmpty ==
                                      true
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        CustomText(
                                          text: "More from this Restaurant",
                                          fontSize: .018,
                                        ),
                                        CustomTap(
                                          onTap: () {
                                            debugPrint(
                                                "................... ${controller.menuViewModelData?.menuItem?.restaurant?.kitchenId}");
                                            NavigateTo().nextPage(
                                                child: SimilarFood(
                                              kitchenId: controller
                                                  .menuViewModelData
                                                  ?.menuItem
                                                  ?.restaurant
                                                  ?.kitchenId,
                                            ));
                                          },
                                          child: CustomText(
                                            text: "See All",
                                            fontSize: .017,
                                            color: AppColors.tPrimaryColor,
                                          ),
                                        )
                                      ],
                                    )
                                  : SizedBox(height: Sizes.height * 0.02),
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 0, vertical: 20),
                                itemCount: controller.menuViewModelData
                                        ?.recommendedItems?.length ??
                                    0,
                                separatorBuilder: (_, __) => const Divider(
                                  color: Color(0XFFD9D9D9),
                                ),
                                itemBuilder: (context, index) {
                                  final menuItem = controller.menuViewModelData
                                      ?.recommendedItems?[index];
                                  return FoodMenuCard(item: menuItem);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Fixed back icon overlay
                  SafeArea(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: Sizes.height * 0.02,
                        left: Sizes.width * 0.05,
                      ),
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const CustomImage(
                          image: AppImages.cartBackIcon,
                          height: .03,
                        ),
                      ),
                    ),
                  ),
                  // Bottom cart container
                ],
              ),
      );
    });
  }
}

class _IndicatorDot extends StatelessWidget {
  const _IndicatorDot({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: isActive
          ? Container(
              height: 5,
              width: 25,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: isActive
                    ? AppColors.tPrimaryColor
                    : const Color(0xFFD5D5D5),
              ),
            )
          : Container(
              height: 5,
              width: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? AppColors.tPrimaryColor
                    : const Color(0xFFD5D5D5),
              ),
            ),
    );
  }
}

class DiagonalLinePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  DiagonalLinePainter({
    required this.color,
    this.strokeWidth = 1.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // Draw diagonal line from top-right to bottom-left (like "/")
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(0, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
