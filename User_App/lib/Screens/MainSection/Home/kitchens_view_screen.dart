import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:resqbox_user/Controllers/account_controller.dart';
import 'package:resqbox_user/Controllers/home_controller.dart';
import 'package:resqbox_user/Models/kitchen_view_model.dart';
import 'package:resqbox_user/Screens/Authentication/guest_login_screen.dart';
import 'package:resqbox_user/Screens/Authentication/login_screen.dart';
import 'package:resqbox_user/Screens/MainSection/Home/Menu/menu.dart';
import 'package:resqbox_user/Screens/MainSection/Home/view_ratings_screen.dart';
import 'package:resqbox_user/Utils/colors.dart';
import 'package:resqbox_user/Utils/custom_image_widget.dart';
import 'package:resqbox_user/Utils/custom_padding.dart';
import 'package:resqbox_user/Utils/custom_sizedbox.dart';
import 'package:resqbox_user/Utils/custom_tap.dart';
import 'package:resqbox_user/Utils/customtext.dart';
import 'package:resqbox_user/Utils/images.dart';
import 'package:resqbox_user/Utils/map_launcher.dart';
import 'package:resqbox_user/Utils/mediaquery.dart';
import 'package:resqbox_user/Utils/navigations.dart';
import 'package:resqbox_user/Utils/network_image.dart';
import 'package:resqbox_user/Utils/shared_preference_helper.dart';

class KitchensViewScreen extends StatefulWidget {
  final int? restaurantId;
  const KitchensViewScreen({super.key, this.restaurantId});

  @override
  State<KitchensViewScreen> createState() => _KitchensViewScreenState();
}

class _KitchensViewScreenState extends State<KitchensViewScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final PageController _pageController;
  int _currentBanner = 0;

  final List<String> _bannerImages = const [
    'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=1200&q=60',
    'https://images.unsplash.com/photo-1478145046317-39f10e56b5e9?auto=format&fit=crop&w=1200&q=60',
    'https://images.unsplash.com/photo-1504754524776-8f4f37790ca0?auto=format&fit=crop&w=1200&q=60',
  ];

  final List<String> _galleryImages = const [
    'https://images.unsplash.com/photo-1466978913421-dad2ebd01d17?auto=format&fit=crop&w=800&q=60',
    'https://images.unsplash.com/photo-1455619452474-d2be8b1e70cd?auto=format&fit=crop&w=800&q=60',
    'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=800&q=60',
    'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=800&q=60',
    'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=800&q=60',
    'https://images.unsplash.com/photo-1529042410759-befb1204b468?auto=format&fit=crop&w=800&q=60',
  ];

  final List<Map<String, String>> _dummyReviews = const [
    {
      'name': 'Priya S.',
      'rating': '4.5',
      'comment': 'Loved the homely flavours and quick pickup option!'
    },
    {
      'name': 'Karthik R.',
      'rating': '4.0',
      'comment': 'Paneer tikka was delicious. Portion size could be better.'
    },
    {
      'name': 'Meera D.',
      'rating': '5.0',
      'comment': 'Amazing variety and super friendly chef. Highly recommended.'
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _pageController = PageController();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final homeController =
          Provider.of<HomeController>(context, listen: false);
      await Provider.of<HomeController>(context, listen: false)
          .viewRestaurantApi(widget.restaurantId, homeController.locLatitude,
              homeController.locLongitude);
      if (mounted) {
        await Provider.of<AccountController>(context, listen: false)
            .getWishlistApi();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeController>(builder: (context, homeController, child) {
      return Scaffold(
        backgroundColor: AppColors.tWhiteColor,
        body: homeController.isRestaurentViewLoading == true
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildBannerSection(
                            context, homeController.restaurantViewModelData),
                        _buildKitchenInfoCard(
                            homeController.restaurantViewModelData),
                        _buildTabBar(),
                        _buildTabContent(
                            homeController.restaurantViewModelData),
                      ],
                    ),
                  ),
                  // Fixed icons overlay
                  _buildFixedIcons(context),
                ],
              ),

        // bottomNavigationBar: SafeArea(
        //   child: Padding(
        //     padding: EdgeInsets.symmetric(
        //       horizontal: Sizes.width * 0.04,
        //       vertical: Sizes.height * 0.015,
        //     ),
        //     child: ElevatedButton(
        //       style: ElevatedButton.styleFrom(
        //         backgroundColor: AppColors.tPrimaryColor,
        //         padding: EdgeInsets.symmetric(
        //           vertical: Sizes.height * 0.018,
        //         ),
        //         shape: RoundedRectangleBorder(
        //           borderRadius: BorderRadius.circular(30),
        //         ),
        //       ),
        //       onPressed: () {},
        //       child: const CustomText(
        //         text: 'View Menu',
        //         color: AppColors.tWhiteColor,
        //         fontWeight: FontWeight.w600,
        //         fontSize: 0.02,
        //       ),
        //     ),
        //   ),
        // ),
      );
    });
  }

  Widget _buildBannerSection(
      BuildContext context, KitchenViewModel? restaurantViewModelData) {
    return SizedBox(
      // height: Sizes.height * 0.4,
      child: Stack(
        children: [
          CustomNetworkImage(
            url: restaurantViewModelData?.kitchen?.photos?.kitchenImages?[0] ??
                '',
            // "https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=1200&q=60",
            fit: BoxFit.cover,
            height: .39,
            width: double.infinity,
          ),
          restaurantViewModelData?.kitchen?.discountPercentage != null &&
                  (restaurantViewModelData?.kitchen?.discountPercentage ?? 0) >
                      0
              ? Positioned(
                  right: 0,
                  top: Sizes.height * 0.12,
                  child: Stack(
                    alignment: Alignment
                        .centerRight, // ✅ Center everything inside Stack
                    children: [
                      const CustomImage(
                        image: AppImages.tag,
                        height: .04,
                        width: .35,
                        fit: BoxFit.cover,
                      ),
                      CustomPadding(
                        right: .02,
                        child: CustomText(
                          // ✅ No Positioned needed
                          text:
                              "UPTO ${restaurantViewModelData?.kitchen?.discountPercentage?.round() ?? 0}% OFF",
                          fontSize: .014,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                )
              : SizedBox(),
        ],
      ),
    );
  }

  Widget _buildFixedIcons(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          top: Sizes.height * 0.02,
          left: Sizes.width * 0.05,
          right: Sizes.width * 0.05,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomTap(
              onTap: () {
                NavigateTo().backPage();
              },
              child: Container(
                padding: EdgeInsets.all(Sizes.height * 0.003),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.tWhiteColor.withOpacity(.5),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: AppColors.tBlackColor,
                ),
              ),
            ),
            Row(
              children: [
                // Container(
                //   padding: EdgeInsets.all(Sizes.height * 0.003),
                //   decoration: BoxDecoration(
                //     shape: BoxShape.circle,
                //     color: AppColors.tWhiteColor.withOpacity(.5),
                //   ),
                //   child: const Icon(
                //     Icons.share_outlined,
                //     color: AppColors.tBlackColor,
                //   ),
                // ),
                // SizedBox(width: Sizes.width * 0.04),
                Consumer<AccountController>(
                    builder: (context, accountController, child) {
                  final isWishlisted = accountController.wishlistData?.kitchens
                          ?.any((element) =>
                              element.kitchenId == widget.restaurantId) ??
                      false;
                  return CustomTap(
                    onTap: () async {
                      if (SharedPreferencesHelper().getString("loginType") ==
                          "skip") {
                        SharedPreferencesHelper().remove("ApiToken");
                        SharedPreferencesHelper().remove("Token2");
                        SharedPreferencesHelper().remove("role");
                        SharedPreferencesHelper().clearAlldata();
                        NavigateTo().pushRemove(child: GuestLoginScreen());
                        return;
                      } else {
                        if (isWishlisted) {
                          await accountController
                              .removeFromWishlistApi(widget.restaurantId);
                        } else {
                          await accountController.addToWishlistApi(
                              body: {"kitchenId": widget.restaurantId});
                        }
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.all(Sizes.height * 0.003),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.tWhiteColor.withOpacity(.5),
                      ),
                      child: Icon(
                        isWishlisted ? Icons.favorite : Icons.favorite_border,
                        color: isWishlisted
                            ? AppColors.tPrimaryColor
                            : AppColors.tBlackColor,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: const Color(0xFFF1F4FC),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.tPrimaryColor,
        indicatorWeight: 3,
        labelColor: AppColors.tBlackColor,
        dividerColor: AppColors.tTransparrent,
        unselectedLabelColor: AppColors.hintTclr,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
        tabs: const [
          Tab(text: 'About'),
          Tab(text: 'Photos'),
          Tab(text: 'Reviews'),
        ],
      ),
    );
  }

  Widget _buildTabContent(KitchenViewModel? restaurantViewModelData) {
    switch (_tabController.index) {
      case 0:
        return _buildAboutTabContent(restaurantViewModelData);
      case 1:
        return _buildPhotosTabContent(restaurantViewModelData);
      case 2:
        return ReviwClass(
            rating: '4.5',
            reviews: restaurantViewModelData?.kitchen?.reviews,
            restaurantId: restaurantViewModelData?.kitchen?.kitchenId);
      default:
        return _buildAboutTabContent(restaurantViewModelData);
    }
  }

  Widget _buildKitchenInfoCard(KitchenViewModel? restaurantViewModelData) {
    return CustomPadding(
      horizontal: .04,
      // vertical: .02,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Sizes.width * 0.0,
          vertical: Sizes.height * 0.02,
        ),
        // decoration: BoxDecoration(
        //   color: AppColors.tWhiteColor,
        //   borderRadius: BorderRadius.circular(14),
        //   boxShadow: [
        //     BoxShadow(
        //       color: Colors.black.withOpacity(0.04),
        //       blurRadius: 12,
        //       offset: const Offset(0, 4),
        //     )
        //   ],
        // ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipOval(
                  child: SizedBox(
                    width: Sizes.height * 0.075,
                    height: Sizes.height * 0.075,
                    child: (restaurantViewModelData
                                    ?.kitchen?.photos?.kitchenProfilePhoto ==
                                null ||
                            restaurantViewModelData?.kitchen?.photos
                                    ?.kitchenProfilePhoto?.isEmpty ==
                                true)
                        ? CircleAvatar(
                            backgroundColor: AppColors.tPrimaryColor,
                            child: CustomText(
                              text: (restaurantViewModelData
                                          ?.kitchen?.kitchenName?.isNotEmpty ??
                                      false)
                                  ? (restaurantViewModelData
                                          ?.kitchen?.kitchenName?[0]
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
                            url: restaurantViewModelData
                                    ?.kitchen?.photos?.kitchenProfilePhoto ??
                                '',
                          ),
                  ),
                ),
                Expanded(
                  child: CustomPadding(
                    left: .02,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: CustomText(
                                text: (restaurantViewModelData
                                            ?.kitchen?.kitchenName ??
                                        '')
                                    .split(' ')
                                    .map((word) => word.isNotEmpty
                                        ? '${word[0].toUpperCase()}${word.substring(1)}'
                                        : '')
                                    .join(' '),
                                fontWeight: FontWeight.w700,
                                fontSize: 0.018,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            SizedBox(width: Sizes.width * 0.02),
                            CustomTap(
                              onTap: () {
                                final latitude = restaurantViewModelData
                                    ?.kitchen?.address?.latitude;
                                final longitude = restaurantViewModelData
                                    ?.kitchen?.address?.longitude;

                                if (latitude != null && longitude != null) {
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
                        const CustomSizedBox(height: .014),
                        Row(
                          children: [
                            const CustomImage(
                              image: AppImages.cartKitchenStar,
                              height: .017,
                            ),
                            SizedBox(width: Sizes.width * 0.026),
                            CustomText(
                              text: restaurantViewModelData?.kitchen?.rating ??
                                  '0.0',
                              fontWeight: FontWeight.w500,
                              color: Color(0XFF4B5563),
                              fontSize: 0.016,
                            ),
                            CustomPadding(
                              horizontal: .04,
                              child: Container(
                                width: 1,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: const Color(0XFFE2E2E2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                            const CustomImage(
                              image: AppImages.distance,
                              height: .017,
                            ),
                            SizedBox(width: Sizes.width * 0.026),
                            CustomText(
                              text:
                                  '${restaurantViewModelData?.kitchen?.distanceKm?.toStringAsFixed(1) ?? 0.0} Km',
                              fontWeight: FontWeight.w500,
                              color: Color(0XFF4B5563),
                              fontSize: 0.016,
                            ),
                            CustomPadding(
                              horizontal: .03,
                              child: Container(
                                width: 1,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: const Color(0XFFE2E2E2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                            const CustomImage(
                              image: AppImages.cartKitchenLocation,
                              height: .017,
                            ),
                            SizedBox(width: Sizes.width * 0.01),
                            CustomSizedBox(
                              width: .18,
                              child: CustomText(
                                text:
                                    "${restaurantViewModelData?.kitchen?.address?.street ?? ''}",
                                fontWeight: FontWeight.w500,
                                color: Color(0XFF4B5563),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                fontSize: 0.016,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const CustomSizedBox(height: .02),
            CustomPadding(
              vertical: .028,
              child: CustomTap(
                onTap: () async {
                  if ((restaurantViewModelData?.kitchen?.totalItemsQuantity ??
                          0) >
                      0) {
                    await NavigateTo().nextPage(
                        child: Menu(
                      from: "kitchen",
                      categoryId: restaurantViewModelData?.kitchen?.kitchenId,
                      categoryName:
                          restaurantViewModelData?.kitchen?.kitchenName,
                    ));
                    if (mounted) {
                      final homeController =
                          Provider.of<HomeController>(context, listen: false);
                      await Provider.of<HomeController>(context, listen: false)
                          .viewRestaurantApi(
                              widget.restaurantId,
                              homeController.locLatitude,
                              homeController.locLongitude);
                    }
                  } else {
                    return;
                  }
                },
                child: Stack(
                  children: [
                    Container(
                      width: Sizes.width,
                      padding: EdgeInsets.symmetric(
                        horizontal: Sizes.width * 0.02,
                        vertical: Sizes.height * 0.014,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0XFFFFF3E0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustomPadding(
                            left: .25,
                            child: (restaurantViewModelData
                                            ?.kitchen?.totalItemsQuantity ??
                                        0) >
                                    0
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CustomText(
                                        text: 'View Available \nResQBoxes',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 0.017,
                                      ),
                                      CustomSizedBox(height: 0.002),
                                      Text(
                                        "View all",
                                        style: GoogleFonts.roboto(
                                          shadows: [
                                            Shadow(
                                                color: AppColors.tPrimaryColor,
                                                offset: Offset(0, -3))
                                          ],
                                          color: Colors.transparent,
                                          decoration: TextDecoration.underline,
                                          decorationColor:
                                              AppColors.tPrimaryColor,
                                          decorationThickness: 1.2,
                                          decorationStyle:
                                              TextDecorationStyle.solid,
                                        ),
                                      )
                                    ],
                                  )
                                : CustomText(
                                    text:
                                        'No Food to save at this moment.\n Please check again later',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 0.017,
                                  ),
                          ),
                          (restaurantViewModelData
                                          ?.kitchen?.totalItemsQuantity ??
                                      0) >
                                  0
                              ? Row(
                                  children: [
                                    CustomText(
                                      text: restaurantViewModelData
                                              ?.kitchen?.totalItemsQuantity
                                              ?.toString() ??
                                          '0',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 0.04,
                                      color: AppColors.green,
                                    ),
                                    SizedBox(width: Sizes.width * 0.02),
                                    const Icon(Icons.arrow_forward_ios,
                                        size: 22, color: AppColors.tBlackColor),
                                  ],
                                )
                              : SizedBox.shrink()
                        ],
                      ),
                    ),
                    (restaurantViewModelData?.kitchen?.totalItemsQuantity ??
                                0) >
                            0
                        ? const Positioned(
                            bottom: 0,
                            left: 0,
                            child: CustomImage(
                              image: AppImages.cartKitchenBox,
                              height: .11,
                            ))
                        : const Positioned(
                            bottom: 0,
                            left: 0,
                            child: CustomImage(
                              image: AppImages.cartKitchenBox,
                              height: .085,
                            ))
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAboutTabContent(KitchenViewModel? restaurantViewModelData) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Sizes.width * 0.04,
        vertical: Sizes.height * 0.02,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            text: restaurantViewModelData?.kitchen?.description ?? '',
            // "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, ",
            color: AppColors.hintTclr,
            fontSize: 0.018,
            fontWeight: FontWeight.w400,
          ),
          const CustomSizedBox(height: .01),
          Divider(
            color: AppColors.hintTclr.withOpacity(.2),
            thickness: 1,
          ),
          const CustomSizedBox(height: .01),
          // Row(
          //   children: [
          //     ClipOval(
          //       child: SizedBox(
          //         width: Sizes.height * 0.075,
          //         height: Sizes.height * 0.075,
          //         child: (restaurantViewModelData
          //                         ?.kitchen?.photos?.kitchenProfilePhoto ==
          //                     null ||
          //                 restaurantViewModelData?.kitchen?.photos
          //                         ?.kitchenProfilePhoto?.isEmpty ==
          //                     true)
          //             ? CircleAvatar(
          //                 backgroundColor: AppColors.tPrimaryColor,
          //                 child: CustomText(
          //                   text: (restaurantViewModelData
          //                               ?.kitchen?.kitchenName?.isNotEmpty ??
          //                           false)
          //                       ? (restaurantViewModelData
          //                               ?.kitchen?.kitchenName?[0]
          //                               .toUpperCase() ??
          //                           'K')
          //                       : 'K',
          //                   fontSize: 0.024,
          //                   fontWeight: FontWeight.w600,
          //                   color: AppColors.tWhiteColor,
          //                 ),
          //               )
          //             : CustomNetworkImage(
          //                 // 'https://toppng.com/uploads/preview/veg-non-veg-plate-of-food-11562983570pkk1qzqvhy.png',
          //                 fit: BoxFit.cover,
          //                 url: restaurantViewModelData
          //                         ?.kitchen?.photos?.kitchenProfilePhoto ??
          //                     '',
          //               ),
          //       ),
          //     ),
          //     SizedBox(width: Sizes.width * 0.02),
          //     Expanded(
          //       child: CustomText(
          //         text: restaurantViewModelData?.kitchen?.kitchenName ?? '',
          //         fontSize: 0.019,
          //         fontWeight: FontWeight.w600,
          //         letterSpacing: 0.8,
          //         overflow: TextOverflow.ellipsis,
          //         maxLines: 1,
          //         color: Color(0xFF111827),
          //         decoration: TextDecoration.underline,
          //         decorationColor: Color(0xFF4B5563),
          //       ),
          //     ),
          //   ],
          // ),
          // const CustomSizedBox(
          //   height: .02,
          // ),
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
                      "${restaurantViewModelData?.kitchen?.address?.houseNo ?? ''} ${restaurantViewModelData?.kitchen?.address?.street ?? ''} ${restaurantViewModelData?.kitchen?.address?.city ?? ''} ${restaurantViewModelData?.kitchen?.address?.state ?? ''} ${restaurantViewModelData?.kitchen?.address?.pincode ?? ''}",
                  fontSize: .016,
                  fontWeight: FontWeight.w400,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  color: Color(0XFF4B5563),
                ),
              ),
            ],
          ),
          // const CustomSizedBox(
          //   height: .02,
          // ),
          // CustomText(
          //   text:
          //       "ACN : ${restaurantViewModelData?.kitchen?.kyc?.acn ?? '--'}   ABN : ${restaurantViewModelData?.kitchen?.kyc?.abnNumber ?? ''}",
          //   fontSize: 0.017,
          //   fontWeight: FontWeight.w500,
          //   color: Color(0XFF4B5563),
          // )
        ],
      ),
    );
  }

  Widget _buildPhotosTabContent(KitchenViewModel? restaurantViewModelData) {
    return Padding(
      padding: EdgeInsets.all(Sizes.width * 0.02),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount:
            restaurantViewModelData?.kitchen?.photos?.kitchenImages?.length ??
                0,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
          childAspectRatio: 1,
          mainAxisExtent: Sizes.height * 0.15,
        ),
        itemBuilder: (_, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(0),
            child: CustomNetworkImage(
              url: restaurantViewModelData
                      ?.kitchen?.photos?.kitchenImages?[index] ??
                  '',
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }

  Widget _buildReviewsTab() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: Sizes.width * 0.04,
        vertical: Sizes.height * 0.02,
      ),
      itemCount: _dummyReviews.length,
      itemBuilder: (_, index) {
        final review = _dummyReviews[index];
        return Container(
          margin: EdgeInsets.only(bottom: Sizes.height * 0.015),
          padding: EdgeInsets.all(Sizes.width * 0.035),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE4E4E4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText(
                    text: review['name'] ?? 'User',
                    fontWeight: FontWeight.w600,
                    fontSize: 0.018,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star,
                            size: 14, color: AppColors.green),
                        const SizedBox(width: 4),
                        CustomText(
                          text: review['rating'] ?? '0',
                          fontWeight: FontWeight.w600,
                          fontSize: 0.016,
                          color: AppColors.green,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const CustomSizedBox(height: .008),
              CustomText(
                text: review['comment'] ?? '',
                color: AppColors.hintTclr,
                fontSize: 0.016,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BannerIndicator extends StatelessWidget {
  const _BannerIndicator({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 6,
      width: isActive ? 24 : 6,
      decoration: BoxDecoration(
        color: isActive ? AppColors.tPrimaryColor : const Color(0xFFD5D5D5),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  const _StickyTabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: const Color(0xFFF1F4FC),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}

class ReviwClass extends StatefulWidget {
  // final List<KitchenReview>? model;
  final String? rating;
  final String? screenFrom;
  final List<Review>? reviews;
  final int? restaurantId;
  const ReviwClass(
      {super.key,
      required this.rating,
      this.screenFrom,
      this.reviews,
      this.restaurantId});

  @override
  State<ReviwClass> createState() => _ReviwClassState();
}

class _ReviwClassState extends State<ReviwClass> {
  int rating = 5;
  @override
  Widget build(BuildContext context) {
    return CustomPadding(
      top: 0.026,
      left: 0.07,
      right: 0.07,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                text: "User Reviews",
                fontSize: 0.018,
                color: AppColors.tBlackColor,
                fontWeight: FontWeight.w700,
              ),
              widget.reviews?.isEmpty == true
                  ? const SizedBox.shrink()
                  : GestureDetector(
                      onTap: () {
                        NavigateTo().nextPage(
                            child: ViewRatingsScreen(
                                restaurantId: widget.restaurantId));
                      },
                      child: const CustomText(
                        text: "See All",
                        fontSize: 0.018,
                        color: AppColors.tPrimaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ],
          ),
          const SizedBox(height: 16), // Add some spacing

          // Main content area
          widget.reviews?.isEmpty == true
              ? const Center(
                  child: CustomPadding(
                      top: .05, child: CustomText(text: 'No reviews found')))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: widget.reviews?.length ?? 0,
                  itemBuilder: (context, index) {
                    return Column(
                      children: [
                        reviewContainer(widget.reviews?[index]),
                      ],
                    );
                  },
                ),
        ],
      ),
    );
  }

  CustomPadding reviewContainer(Review? review) {
    return CustomPadding(
      // horizontal: 0.03,
      vertical: 0.02,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: Sizes.height * 0.08,
                width: Sizes.height * 0.08,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: (review?.user?.profilePicture == null ||
                        review?.user?.profilePicture?.isEmpty == true)
                    ? CircleAvatar(
                        backgroundColor: AppColors.tPrimaryColor,
                        child: CustomText(
                          text: (review?.user?.name?.isNotEmpty ?? false)
                              ? (review?.user?.name?[0].toUpperCase() ?? 'U')
                              : 'U',
                          fontSize: 0.024,
                          fontWeight: FontWeight.w600,
                          color: AppColors.tWhiteColor,
                        ),
                      )
                    : ClipOval(
                        child: CustomNetworkImage(
                          url: review?.user?.profilePicture ?? '',
                          // 'https://toppng.com/uploads/preview/veg-non-veg-plate-of-food-11562983570pkk1qzqvhy.png',
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
              const CustomSizedBox(width: .03),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: review?.user?.name ?? '',
                    fontSize: 0.018,
                    color: AppColors.tBlackColor,
                    fontWeight: FontWeight.w600,
                  ),
                  const CustomSizedBox(height: .008),
                  Row(
                    children: [
                      CustomText(
                        text: review?.rating ?? '',
                        fontWeight: FontWeight.w500,
                        fontSize: 0.016,
                        color: AppColors.hintTclr,
                      ),
                      CustomPadding(
                        left: 0.02,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            final rating =
                                double.tryParse(review?.rating ?? '0') ?? 0.0;
                            IconData iconData;
                            if (rating >= index + 1) {
                              // Full star
                              iconData = Icons.star;
                            } else if (rating > index) {
                              // Half star
                              iconData = Icons.star_half;
                            } else {
                              // Empty star
                              iconData = Icons.star_border;
                            }
                            return CustomPadding(
                              right: 0.002,
                              child: Icon(iconData,
                                  size: 16, color: AppColors.tPrimaryColor),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const CustomSizedBox(height: .015),
          // const CustomText(
          //   text: "Delicious & Authentic!",
          //   fontSize: 0.016,
          //   color: AppColors.tBlackColor,
          //   fontWeight: FontWeight.w600,
          // ),
          // const CustomSizedBox(height: .011),
          CustomText(
            textAlign: TextAlign.start,
            text: review?.review ?? '',
            // 'The South Indian meals from Sri Krishna are just like home. The sambar and chutney tasted amazing. Will definitely order again!',
            // "The South Indian meals from Sri Krishna are just like home. The sambar and chutney tasted amazing. Will definitely order again!",
            fontSize: 0.016,
            color: AppColors.hintTclr,
            fontWeight: FontWeight.w400,
          ),
        ],
      ),
    );
  }
}
