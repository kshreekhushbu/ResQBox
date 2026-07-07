import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resqbox_user/Controllers/account_controller.dart';
import 'package:resqbox_user/Models/home_data_model.dart';
import 'package:resqbox_user/Screens/Authentication/guest_login_screen.dart';
import 'package:resqbox_user/Screens/MainSection/Account/wishlist.dart';
import 'package:resqbox_user/Screens/MainSection/Home/kitchens_view_screen.dart';
import 'package:resqbox_user/Screens/MainSection/Home/popular_kitchen_card.dart';
import 'package:resqbox_user/Utils/colors.dart';
import 'package:resqbox_user/Utils/custom_image_widget.dart';
import 'package:resqbox_user/Utils/custom_padding.dart';
import 'package:resqbox_user/Utils/custom_tap.dart';
import 'package:resqbox_user/Utils/customtext.dart';
import 'package:resqbox_user/Utils/images.dart';
import 'package:resqbox_user/Utils/mediaquery.dart';
import 'package:resqbox_user/Utils/navigations.dart';
import 'package:resqbox_user/Utils/network_image.dart';
import 'package:resqbox_user/Utils/shared_preference_helper.dart';

class WishListSection extends StatefulWidget {
  final List<ActiveRestaurantData>? items;
  const WishListSection({super.key, this.items});

  @override
  State<WishListSection> createState() => _WishListSectionState();
}

class _WishListSectionState extends State<WishListSection> {
  @override
  Widget build(BuildContext context) {
    return CustomPadding(
      horizontal: .04,
      vertical: .01,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                text: "Your Wishlist",
                fontWeight: FontWeight.w600,
                fontSize: 0.018,
              ),
              CustomTap(
                onTap: () {
                  NavigateTo().nextPage(child: const Wishlist());
                },
                child: CustomText(
                  text: "See All",
                  fontWeight: FontWeight.w500,
                  color: AppColors.tPrimaryColor,
                  fontSize: 0.018,
                ),
              ),
            ],
          ),
          SizedBox(height: Sizes.height * 0.025),
          (widget.items == null || widget.items!.isEmpty)
              ? const SizedBox.shrink()
              : SizedBox(
                  height: Sizes.height * 0.32,
                  width: Sizes.width,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.items!.length,
                    padding: EdgeInsets.only(right: Sizes.width * 0.04),
                    itemBuilder: (context, index) => Padding(
                      padding: EdgeInsets.only(
                        right: index == widget.items!.length - 1
                            ? 0
                            : Sizes.width * 0.02,
                      ),
                      child: WishListCard(item: widget.items![index]),
                    ),
                  ),
                ),
          SizedBox(height: Sizes.height * 0.025),
        ],
      ),
    );
  }
}

class WishListCard extends StatefulWidget {
  const WishListCard({super.key, required this.item, this.from});

  final ActiveRestaurantData? item;
  final String? from;

  @override
  State<WishListCard> createState() => _WishListCardState();
}

class _WishListCardState extends State<WishListCard> {
  int? _localIsWishlist;

  @override
  void initState() {
    super.initState();
    _localIsWishlist = widget.item?.isWishlist;
  }

  @override
  Widget build(BuildContext context) {
    bool isOutOfStock = (widget.item?.totalItemsQuantity ?? 0) <= 0;

    return CustomTap(
      onTap: () {
        NavigateTo().nextPage(
            child: KitchensViewScreen(
          restaurantId: widget.item?.kitchenId,
        ));
      },
      child: ColorFiltered(
        colorFilter: isOutOfStock
            ? const ColorFilter.matrix(<double>[
                0.6065,
                0.3575,
                0.0360,
                0,
                0,
                0.1065,
                0.8575,
                0.0360,
                0,
                0,
                0.1065,
                0.3575,
                0.5360,
                0,
                0,
                0,
                0,
                0,
                1,
                0,
              ])
            : const ColorFilter.mode(
                Colors.transparent,
                BlendMode.dst,
              ),
        child: Container(
          width: widget.from == "kitchens" ? Sizes.width : Sizes.width * 0.78,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE1E1E1)),
            borderRadius: BorderRadius.circular(8),
            color: AppColors.tWhiteColor,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(7),
                      topRight: Radius.circular(7),
                    ),
                    child: SizedBox(
                      height: Sizes.height * 0.2,
                      width: double.infinity,
                      child: CustomNetworkImage(
                        url: widget.item?.photos?.kitchenImages?.first ?? '',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  if (widget.item?.discountPercentage != null &&
                      (widget.item?.discountPercentage ?? 0) > 0)
                    Positioned(
                      top: 10,
                      right: 0,
                      child: Row(
                        children: [
                          Stack(
                            alignment: Alignment
                                .centerRight, // ✅ Center contents inside this Stack
                            children: [
                              CustomImage(
                                image: AppImages.tag,
                                height: .043,
                                width: .33,
                                fit: BoxFit.cover,
                              ),
                              CustomPadding(
                                right: .02,
                                child: CustomText(
                                  // ✅ No Positioned needed
                                  text:
                                      "Upto ${(widget.item?.discountPercentage ?? 0).round()}% OFF",
                                  fontSize: 0.015,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.tBlackColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: Sizes.width * 0.015,
                  vertical: Sizes.height * 0.01,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    ClipOval(
                      child: SizedBox(
                        height: Sizes.height * 0.075,
                        width: Sizes.height * 0.075,
                        child: CustomNetworkImage(
                          url: widget.item?.photos?.kitchenProfilePhoto ?? '',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(width: Sizes.width * 0.02),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: CustomText(
                                  text: (widget.item?.kitchenName ?? '')
                                      .split(' ')
                                      .map((word) => word.isNotEmpty
                                          ? '${word[0].toUpperCase()}${word.substring(1)}'
                                          : '')
                                      .join(' '),
                                  //  widget.item?.kitchenName ?? '',
                                  fontSize: 0.016,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  if (SharedPreferencesHelper()
                                          .getString("loginType") ==
                                      "skip") {
                                    SharedPreferencesHelper()
                                        .remove("ApiToken");
                                    SharedPreferencesHelper().remove("Token2");
                                    SharedPreferencesHelper().remove("role");
                                    SharedPreferencesHelper().clearAlldata();
                                    NavigateTo()
                                        .pushRemove(child: GuestLoginScreen());
                                    return;
                                  }
                                  final accountController =
                                      Provider.of<AccountController>(context,
                                          listen: false);
                                  final kitchenId = widget.item?.kitchenId;

                                  if (kitchenId == null) return;

                                  final currentWishlistStatus =
                                      _localIsWishlist ??
                                          widget.item?.isWishlist ??
                                          0;

                                  // Update local state optimistically
                                  setState(() {
                                    _localIsWishlist =
                                        currentWishlistStatus == 1 ? 0 : 1;
                                  });

                                  bool success = false;

                                  // If isWishlist is 1, remove from wishlist
                                  // If isWishlist is 0, add to wishlist
                                  if (currentWishlistStatus == 1) {
                                    // Currently in wishlist, remove it
                                    success = await accountController
                                        .removeFromWishlistApi(kitchenId);
                                  } else {
                                    // Not in wishlist, add it
                                    success = await accountController
                                        .addToWishlistApi(
                                            body: {"kitchenId": kitchenId});
                                  }

                                  // Revert on failure
                                  if (!success) {
                                    setState(() {
                                      _localIsWishlist = currentWishlistStatus;
                                    });
                                  }
                                },
                                child: CustomImage(
                                  image: AppImages.favIcon,
                                  color: (_localIsWishlist ??
                                              widget.item?.isWishlist ??
                                              0) ==
                                          1
                                      ? AppColors.tPrimaryColor
                                      : Colors.grey.shade400,
                                  height: 0.02,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: Sizes.height * 0.001),
                          CustomText(
                            text: widget.item?.cuisines?.first ?? '',
                            fontSize: 0.014,
                            fontWeight: FontWeight.w500,
                            color: AppColors.hintTclr,
                          ),
                          SizedBox(height: Sizes.height * 0.002),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Expanded(
                                child: RatingStars(
                                    rating: double.parse(
                                        widget.item?.rating ?? '0')),
                              ),
                              SizedBox(
                                  width: widget.from == "kitchens"
                                      ? Sizes.width * .02
                                      : Sizes.width * 0.0),
                              const Icon(
                                Icons.circle,
                                size: 4,
                                color: Color(0xFF989898),
                              ),
                              SizedBox(
                                  width: widget.from == "kitchens"
                                      ? Sizes.width * .02
                                      : Sizes.width * 0.012),
                              Image.asset(
                                AppImages.distance,
                                height: Sizes.height * 0.016,
                                color: AppColors.green,
                              ),
                              SizedBox(
                                  width: widget.from == "kitchens"
                                      ? Sizes.width * .012
                                      : Sizes.width * 0.01),
                              Flexible(
                                child: CustomText(
                                  text:
                                      "${widget.item?.distanceKm?.toStringAsFixed(1) ?? '0.0'} km",
                                  fontSize: 0.014,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF4B5563),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              SizedBox(width: Sizes.width * 0.012),
                              Image.asset(
                                AppImages.locCard,
                                height: Sizes.height * 0.016,
                                color: AppColors.green,
                              ),
                              SizedBox(width: Sizes.width * 0.008),
                              Flexible(
                                child: CustomText(
                                  text:
                                      "${widget.item?.address?.street ?? ''},${widget.item?.address?.city ?? ''}",
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  fontSize: 0.014,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF4B5563),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: Sizes.height * 0.005),
                          CustomText(
                            text:
                                "${widget.item?.totalItemsQuantity ?? 0} ResQBoxes Available",
                            fontSize: 0.016,
                            fontWeight: FontWeight.w500,
                            color: AppColors.tPrimaryColor,
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              // SizedBox(height: Sizes.height * 0.01),
            ],
          ),
        ),
      ),
    );
  }
}
