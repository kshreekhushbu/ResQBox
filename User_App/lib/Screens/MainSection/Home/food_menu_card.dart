import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resqbox_user/Controllers/cart_controller.dart';
import 'package:resqbox_user/Models/home_data_model.dart';
import 'package:resqbox_user/Screens/Authentication/guest_login_screen.dart';
import 'package:resqbox_user/Screens/MainSection/Home/Menu/menu_view_screen.dart';
import 'package:resqbox_user/Utils/colors.dart';
import 'package:resqbox_user/Utils/custom_image_widget.dart';
import 'package:resqbox_user/Utils/custom_padding.dart';
import 'package:resqbox_user/Utils/custom_sizedbox.dart';
import 'package:resqbox_user/Utils/custom_tap.dart';
import 'package:resqbox_user/Utils/customtext.dart';
import 'package:resqbox_user/Utils/images.dart';
import 'package:resqbox_user/Utils/mediaquery.dart';
import 'package:resqbox_user/Utils/navigations.dart';
import 'package:resqbox_user/Utils/network_image.dart';
import 'package:resqbox_user/Utils/shared_preference_helper.dart';

class FoodMenuCard extends StatefulWidget {
  const FoodMenuCard({
    super.key,
    required this.item,
    this.from,
    this.isFromKitchanView,
    this.kitchenStatus = false,
  });

  final Product? item;
  final String? from;
  final String? isFromKitchanView;
  final bool? kitchenStatus;

  @override
  State<FoodMenuCard> createState() => _FoodMenuCardState();
}

class _FoodMenuCardState extends State<FoodMenuCard> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    bool isOutOfStock = (widget.item?.quantity ?? 0) <= 0;

    return AbsorbPointer(
      absorbing: isOutOfStock,
      child: CustomPadding(
        bottom: .01,
        child: CustomTap(
          onTap: () {
            NavigateTo().nextPage(
                child: MenuViewScreen(
              menuId: widget.item?.id,
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
                // const ColorFilter.matrix(<double>[
                //     0.2126,
                //     0.7152,
                //     0.0722,
                //     0,
                //     0,
                //     0.2126,
                //     0.7152,
                //     0.0722,
                //     0,
                //     0,
                //     0.2126,
                //     0.7152,
                //     0.0722,
                //     0,
                //     0,
                //     0,
                //     0,
                //     0,
                //     1,
                //     0,
                //   ])
                // : const ColorFilter.mode(
                //     Colors.transparent,
                //     BlendMode.dst,
                //   ),
                : const ColorFilter.mode(
                    Colors.transparent,
                    BlendMode.dst,
                  ),
            child: Stack(
              children: [
                Row(
                  children: [
                    Stack(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CustomNetworkImage(
                          url: widget.item?.image ?? '',
                          height: .11,
                          width: .23,
                          fit: BoxFit.cover,
                        ),
                      ),
                      if (isOutOfStock)
                        Positioned(
                            top: 15,
                            bottom: 15,
                            left: 15,
                            right: 15,
                            child: CustomImage(
                              image: AppImages.soldOut,
                              color: AppColors.tWhiteColor,
                              height: .05,
                            ))
                    ]),
                    Expanded(
                      child: CustomPadding(
                        left: 0.04,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: CustomText(
                                    text: (widget.item?.name ?? '')
                                        .split(' ')
                                        .map((word) => word.isNotEmpty
                                            ? '${word[0].toUpperCase()}${word.substring(1)}'
                                            : '')
                                        .join(' '),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 0.018,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                SizedBox(width: Sizes.width * 0.04),
                                Row(
                                  children: [
                                    CustomText(
                                      text:
                                          "\$${(widget.item?.discountPrice ?? 0.0).toDouble().toStringAsFixed(2)}",
                                      fontWeight: FontWeight.w600,
                                      fontSize: 0.018,
                                    ),
                                    SizedBox(width: Sizes.width * 0.02),
                                    Stack(
                                      children: [
                                        CustomText(
                                          text:
                                              "\$${(widget.item?.price ?? 0.0).toDouble().toStringAsFixed(2)}",
                                          fontSize: 0.013,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xff4B5563),
                                        ),
                                        Positioned.fill(
                                          child: CustomPaint(
                                            painter: DiagonalLinePainter(
                                              color: AppColors.tPrimaryColor,
                                              strokeWidth: 1.1,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            CustomPadding(
                              top: 0.006,
                              child: CustomText(
                                text: widget.item?.categories?.isNotEmpty ==
                                        true
                                    ? widget.item!.categories!.first.name ?? ''
                                    : '',
                                color: const Color(0XFF989898),
                                fontWeight: FontWeight.w400,
                                fontSize: 0.016,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const CustomSizedBox(
                                        height: 0.003,
                                      ),
                                      widget.isFromKitchanView == "kitchenMenu"
                                          ? const SizedBox.shrink()
                                          : CustomText(
                                              text: (widget.item?.restaurant
                                                          ?.kitchenName ??
                                                      '')
                                                  .split(' ')
                                                  .map((word) => word.isNotEmpty
                                                      ? '${word[0].toUpperCase()}${word.substring(1)}'
                                                      : '')
                                                  .join(' '),
                                              color: const Color(0XFF989898),
                                              fontWeight: FontWeight.w400,
                                              fontSize: 0.014,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                      const CustomSizedBox(
                                        height: 0.006,
                                      ),
                                      Row(
                                        children: [
                                          widget.item?.foodtype != null
                                              ? CustomNetworkImage(
                                                  url: widget.item?.foodtype
                                                          ?.image ??
                                                      '',
                                                  height: 0.02,
                                                )
                                              : const SizedBox.shrink(),
                                          SizedBox(width: Sizes.width * 0.02),
                                          Expanded(
                                            child: CustomText(
                                              text:
                                                  "${widget.item?.quantity ?? 0} ResQBoxes Available",
                                              color: AppColors.green,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 0.016,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          )
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Consumer<CartController>(
                                  builder: (context, cart, child) {
                                    final cartItems =
                                        cart.cartData?.cartItems ?? [];
                                    final matched = cartItems
                                        .where((e) =>
                                            e.menuItemId == widget.item?.id)
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
                                                child:
                                                    const GuestLoginScreen());
                                            return;
                                          } else {
                                            if (widget.item?.id == null) return;
                                            await Provider.of<CartController>(
                                              context,
                                              listen: false,
                                            ).addToCartApi(
                                                menuItemId: widget.item!.id!,
                                                quantity: 1);
                                          }
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: Sizes.width * 0.055,
                                            vertical: Sizes.height * 0.0065,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                                Sizes.height * 0.004),
                                            border: Border.all(
                                                color: const Color(0XFFD9D9D9)),
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
                                                          const GuestLoginScreen());
                                                  return;
                                                } else {
                                                  if (widget.item?.id == null) {
                                                    return;
                                                  }
                                                  await Provider.of<
                                                      CartController>(
                                                    context,
                                                    listen: false,
                                                  ).addToCartApi(
                                                      menuItemId:
                                                          widget.item!.id!,
                                                      quantity: -1);
                                                }
                                              },
                                              child: const Icon(Icons.remove,
                                                  size: 18),
                                            ),
                                            CustomPadding(
                                              horizontal: .03,
                                              child: CustomText(
                                                text:
                                                    '${cartItem.quantity ?? 0}',
                                                color: AppColors.tPrimaryColor,
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
                                                          const GuestLoginScreen());
                                                  return;
                                                } else {
                                                  if (widget.item?.id == null) {
                                                    return;
                                                  }
                                                  await Provider.of<
                                                      CartController>(
                                                    context,
                                                    listen: false,
                                                  ).addToCartApi(
                                                      menuItemId:
                                                          widget.item!.id!,
                                                      quantity: 1);
                                                }
                                              },
                                              child: const Icon(Icons.add,
                                                  size: 18),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FoodMenu {
  final String name;
  final String price;
  final String category;
  final String kitchenName;
  final String boxesAvailable;
  final String imageUrl;

  const FoodMenu({
    required this.name,
    required this.price,
    required this.category,
    required this.kitchenName,
    required this.boxesAvailable,
    required this.imageUrl,
  });
}
