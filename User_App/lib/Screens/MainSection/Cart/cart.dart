import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resqbox_user/Controllers/cart_controller.dart';
import 'package:resqbox_user/Controllers/menu_controller.dart';
import 'package:resqbox_user/Screens/MainSection/Cart/order_succes_screen.dart';
import 'package:resqbox_user/Screens/MainSection/Home/Menu/menu.dart';
import 'package:resqbox_user/Screens/MainSection/Home/Menu/menu_view_screen.dart';
import 'package:resqbox_user/Screens/MainSection/Home/kitchens_view_screen.dart';
import 'package:resqbox_user/Screens/MainSection/Orders/order_details.dart';
import 'package:resqbox_user/Screens/MainSection/bottom_navigation.dart';
import 'package:resqbox_user/Utils/active_btn.dart';
import 'package:resqbox_user/Utils/colors.dart';
import 'package:resqbox_user/Utils/custom_appbar.dart';
import 'package:resqbox_user/Utils/custom_image_widget.dart';
import 'package:resqbox_user/Utils/custom_padding.dart';
import 'package:resqbox_user/Utils/custom_sizedbox.dart';
import 'package:resqbox_user/Utils/custom_tap.dart';
import 'package:resqbox_user/Utils/customtext.dart';
import 'package:resqbox_user/Utils/horizontal_line.dart';
import 'package:resqbox_user/Utils/map_launcher.dart';
import 'package:resqbox_user/Utils/mediaquery.dart';
import 'package:resqbox_user/Utils/navigations.dart';
import 'package:resqbox_user/Utils/network_image.dart';
import 'package:resqbox_user/Controllers/account_controller.dart';
import 'package:resqbox_user/Models/saved_card_model.dart';
import '../../../Utils/images.dart';

class Cart extends StatefulWidget {
  const Cart({super.key});

  @override
  State<Cart> createState() => _CartState();
}

class _CartState extends State<Cart> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Provider.of<CartController>(context, listen: false).getCartApi();
      if (mounted) {
        Provider.of<AccountController>(context, listen: false)
            .getSavedCardsApi();
      }
    });
  }

  void _showPaymentSelectionSheet(BuildContext context, CartController cart,
      List<PaymentMethodData> cards) {
    bool saveCardForFuture = false;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(builder: (context, setState) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: Sizes.width * 0.05,
            vertical: Sizes.height * 0.03,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const CustomText(
                    text: "Select Payment Method",
                    fontSize: 0.02,
                    fontWeight: FontWeight.w700,
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  )
                ],
              ),
              const Divider(),
              if (cards.isNotEmpty) ...[
                const CustomPadding(
                  vertical: 0.015,
                  child: CustomText(
                    text: "Saved Cards",
                    fontSize: 0.016,
                    fontWeight: FontWeight.w600,
                    color: AppColors.hintTclr,
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: Sizes.height * 0.4,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: cards.length,
                    itemBuilder: (context, index) {
                      final card = cards[index];
                      return CustomTap(
                        onTap: () {
                          Navigator.pop(context);
                          _handlePayment(context, cart, cardId: card.cardId);
                        },
                        child: Container(
                          margin: EdgeInsets.only(bottom: Sizes.height * 0.015),
                          padding: EdgeInsets.all(Sizes.width * 0.03),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              _getCardIcon(card.cardBrand),
                              CustomSizedBox(width: 0.03),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomText(
                                      text:
                                          "${card.cardBrand?.toUpperCase()} **** ${card.cardLast4}",
                                      fontSize: 0.017,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    CustomText(
                                      text:
                                          "Expires ${card.cardExpMonth}/${card.cardExpYear}",
                                      fontSize: 0.014,
                                      color: AppColors.hintTclr,
                                    ),
                                    CustomText(
                                      text: "No CVV Required",
                                      fontSize: 0.012,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.hintTclr
                                          .withValues(alpha: .8),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 16),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(),
              ],
              CustomTap(
                onTap: () {
                  Navigator.pop(context);
                  _handlePayment(context, cart, saveCard: saveCardForFuture);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: Sizes.height * 0.015),
                  child: Row(
                    children: [
                      const Icon(Icons.add_circle_outline,
                          color: AppColors.tPrimaryColor),
                      CustomSizedBox(width: 0.03),
                      const CustomText(
                        text: "Add New Card",
                        fontSize: 0.017,
                        fontWeight: FontWeight.w600,
                        color: AppColors.tPrimaryColor,
                      ),
                    ],
                  ),
                ),
              ),
              CustomTap(
                onTap: () {
                  setState(() {
                    saveCardForFuture = !saveCardForFuture;
                  });
                },
                child: Row(
                  children: [
                    CustomSizedBox(width: 0.01),
                    SizedBox(
                      height: 20,
                      width: 20,
                      child: Checkbox(
                        value: saveCardForFuture,
                        activeColor: AppColors.tPrimaryColor,
                        onChanged: (value) {
                          setState(() {
                            saveCardForFuture = value ?? true;
                          });
                        },
                      ),
                    ),
                    const CustomSizedBox(width: 0.02),
                    const CustomText(
                      text: "Secure this card for future payments",
                      fontSize: 0.015,
                      color: AppColors.hintTclr,
                      fontWeight: FontWeight.w500,
                    ),
                  ],
                ),
              ),
              CustomSizedBox(height: 0.025),
            ],
          ),
        );
      }),
    );
  }

  Widget _getCardIcon(String? brand) {
    String image = AppImages.others;
    if (brand?.toLowerCase() == "visa") image = AppImages.accountCardLogo1;
    if (brand?.toLowerCase() == "mastercard")
      image = AppImages.accountCardLogo2;
    if (brand?.toLowerCase() == "amex") image = AppImages.american;
    if (brand?.toLowerCase() == "rupay") image = AppImages.rupay;

    return CustomImage(
      image: image,
      height: 0.03,
      width: 0.045,
      fit: BoxFit.contain,
    );
  }

  void _handlePayment(BuildContext context, CartController cart,
      {int? cardId, bool saveCard = false}) {
    Map<String, dynamic> body = {
      "paymentMethod": cardId == null ? "ONLINE" : "CARD",
      "kitchenId": cart.cartData?.kitchen?.kitchenId,
      "items": cart.cartData?.cartItems
          ?.map((e) => {
                "menuItemId": e.menuItemId,
                "quantity": e.quantity,
                "actualPrice": e.actualPrice,
                "discountPrice": e.discountPrice
              })
          .toList(),
      "itemTotal": cart.cartData?.priceDetails?.itemTotal,
      "taxAmount": cart.cartData?.priceDetails?.taxAmount,
      "platformFee": cart.cartData?.priceDetails?.platformFee,
      "totalAmount": cart.cartData?.priceDetails?.totalAmount,
      "placedAt": DateTime.now().toIso8601String()
    };

    if (cardId != null) {
      body["cardId"] = cardId;
    }

    debugPrint("body: $body");
    if (cardId == null) {
      if (saveCard) {
        Provider.of<CartController>(context, listen: false)
            .initAddCardAndPlaceOrder(orderBody: body);
      } else {
        Provider.of<CartController>(context, listen: false)
            .placeOrderApi(body: body);
      }
    } else {
      Provider.of<CartController>(context, listen: false)
          .placeOrderApi(body: body);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartController>(builder: (context, cart, child) {
      int getTotalCartCount() {
        final items = cart.cartData?.cartItems ?? [];
        return items.fold<int>(
          0,
          (sum, item) => sum + (item.quantity ?? 0),
        );
      }

      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? result) async {
          if (didPop) {
            return;
          }
          NavigateTo().nextPage(child: BottomNavigation(initialIndex: 0));
        },
        child: Scaffold(
          backgroundColor: const Color(0XFFF6F6F6),
          appBar: CustomAppBar(
            title: "Cart",
            titleFontSize: 0.022,
            backgroundColor: AppColors.tWhiteColor,
            backTap: () {
              NavigateTo().nextPage(child: BottomNavigation(initialIndex: 0));
            },
          ),
          body: cart.isLoading
              ? const Center(child: CircularProgressIndicator())
              : cart.cartData?.cartItems?.isEmpty == true ||
                      cart.cartData == null
                  ? const Center(child: CustomText(text: "No items in cart"))
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          const CustomSizedBox(
                            height: .005,
                          ),
                          Container(
                            color: AppColors.tWhiteColor,
                            padding: EdgeInsets.symmetric(
                                horizontal: Sizes.width * 0.04,
                                vertical: Sizes.height * 0.02),
                            child: Column(
                              children: [
                                ListView.builder(
                                  itemCount:
                                      cart.cartData?.cartItems?.length ?? 0,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    // final item = provider.cartData?.result?[index];
                                    return CustomPadding(
                                      bottom: .015,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: CustomText(
                                                  text: (cart
                                                              .cartData
                                                              ?.cartItems?[
                                                                  index]
                                                              .name ??
                                                          '')
                                                      .split(' ')
                                                      .map((word) => word
                                                              .isNotEmpty
                                                          ? '${word[0].toUpperCase()}${word.substring(1)}'
                                                          : '')
                                                      .join(' '),
                                                  fontSize: 0.017,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(
                                                width: 10,
                                              ),
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  vertical: Sizes.height * .006,
                                                  horizontal: Sizes.width * .02,
                                                ),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  border: Border.all(
                                                      color: const Color(
                                                          0XFFD9D9D9)),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    GestureDetector(
                                                      onTap: () async {
                                                        debugPrint(
                                                            "yyyyyyyyyyyyyyy${cart.cartData?.cartItems?[index].menuItemId}");
                                                        await Provider.of<
                                                            FoodMenuController>(
                                                          context,
                                                          listen: false,
                                                        ).addToCartApi(
                                                          {
                                                            "menuItemId": cart
                                                                .cartData
                                                                ?.cartItems?[
                                                                    index]
                                                                .menuItemId,
                                                            "quantity": -1,
                                                          },
                                                        );
                                                      },
                                                      child: const Icon(
                                                          Icons.remove,
                                                          size: 18),
                                                    ),
                                                    CustomPadding(
                                                      horizontal: .03,
                                                      child: CustomText(
                                                        text: cart
                                                                .cartData
                                                                ?.cartItems?[
                                                                    index]
                                                                .quantity
                                                                .toString() ??
                                                            '0',
                                                        color: AppColors
                                                            .tPrimaryColor,
                                                      ),
                                                    ),
                                                    GestureDetector(
                                                      onTap: () async {
                                                        debugPrint(
                                                            "deyyyyyyyyyyyyyyy${cart.cartData?.cartItems?[index].menuItemId}");
                                                        await Provider.of<
                                                            FoodMenuController>(
                                                          context,
                                                          listen: false,
                                                        ).addToCartApi(
                                                          {
                                                            "menuItemId": cart
                                                                .cartData
                                                                ?.cartItems?[
                                                                    index]
                                                                .menuItemId,
                                                            "quantity": 1,
                                                          },
                                                        );
                                                      },
                                                      child: const Icon(
                                                          Icons.add,
                                                          size: 18),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              CustomText(
                                                text:
                                                    "\$ ${(cart.cartData?.cartItems?[index].discountPrice ?? 0).toDouble().toStringAsFixed(2)}",
                                                fontSize: 0.017,
                                                fontWeight: FontWeight.w400,
                                                color: Color(0XFFEA7726),
                                              ),
                                              SizedBox(
                                                width: 10,
                                              ),
                                              Stack(
                                                children: [
                                                  CustomText(
                                                    text:
                                                        "\$${(cart.cartData?.cartItems?[index].actualPrice ?? 0).toDouble().toStringAsFixed(2)}",
                                                    fontSize: 0.013,
                                                    fontWeight: FontWeight.w500,
                                                    color: Color(0xff4B5563),
                                                  ),
                                                  Positioned.fill(
                                                    child: CustomPaint(
                                                      painter:
                                                          DiagonalLinePainter(
                                                        color: AppColors
                                                            .tPrimaryColor,
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
                                    );
                                  },
                                ),
                                Divider(
                                  color: AppColors.hintTclr.withOpacity(0.2),
                                ),
                                CustomPadding(
                                  // horizontal: .04,
                                  vertical: .005,
                                  child: CustomTap(
                                    onTap: () {
                                      NavigateTo().nextPage(
                                          child: Menu(
                                              from: "kitchen",
                                              categoryId: cart
                                                  .cartData?.kitchen?.kitchenId,
                                              categoryName: cart.cartData
                                                  ?.kitchen?.kitchenName));
                                      // NavigateTo().nextPage(
                                      //     child: KitchensViewScreen(
                                      //         restaurantId: cart.cartData
                                      //             ?.kitchen?.kitchenId));
                                    },
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const CustomText(
                                          text: "Add More Products",
                                          fontSize: 0.018,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(1),
                                          decoration: const BoxDecoration(
                                              color: AppColors.green,
                                              shape: BoxShape.circle),
                                          child: const Icon(
                                            Icons.add,
                                            size: 20,
                                            color: AppColors.tWhiteColor,
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const CustomSizedBox(
                            height: .005,
                          ),
                          Container(
                            color: AppColors.tWhiteColor,
                            padding: EdgeInsets.symmetric(
                                horizontal: Sizes.width * 0.04,
                                vertical: Sizes.height * 0.02),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    CustomText(
                                      text: "Restaurant Location",
                                      fontSize: 0.018,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    CustomTap(
                                      onTap: () {
                                        final latitude = cart.cartData?.kitchen
                                            ?.address?.latitude;
                                        final longitude = cart.cartData?.kitchen
                                            ?.address?.longitude;
                                        debugPrint("latitude: $latitude");
                                        debugPrint("longitude: $longitude");

                                        if (latitude != null &&
                                            longitude != null) {
                                          MapLauncher.openGoogleMaps(
                                            latitude: latitude,
                                            longitude: longitude,
                                          );
                                        }
                                      },
                                      child: CustomText(
                                        text: "View on Map",
                                        fontSize: 0.018,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                CustomPadding(
                                  top: .02,
                                  bottom: .013,
                                  child: CustomTap(
                                    onTap: () {
                                      NavigateTo().nextPage(
                                          child: KitchensViewScreen(
                                              restaurantId: cart.cartData
                                                  ?.kitchen?.kitchenId));
                                    },
                                    child: Row(
                                      children: [
                                        ClipOval(
                                          child: SizedBox(
                                            width: Sizes.height * 0.05,
                                            height: Sizes.height * 0.05,
                                            child: (cart.cartData?.kitchen
                                                            ?.kitchenProfilePhoto ==
                                                        null ||
                                                    (cart.cartData?.kitchen
                                                                ?.kitchenProfilePhoto ??
                                                            '')
                                                        .isEmpty)
                                                ? CircleAvatar(
                                                    backgroundColor:
                                                        AppColors.tPrimaryColor,
                                                    radius:
                                                        Sizes.height * 0.025,
                                                    child: CustomText(
                                                      text: (cart
                                                                      .cartData
                                                                      ?.kitchen
                                                                      ?.kitchenName !=
                                                                  null &&
                                                              cart
                                                                  .cartData!
                                                                  .kitchen!
                                                                  .kitchenName!
                                                                  .isNotEmpty)
                                                          ? cart
                                                              .cartData!
                                                              .kitchen!
                                                              .kitchenName![0]
                                                              .toUpperCase()
                                                          : 'K',
                                                      fontSize: 0.025,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          AppColors.tWhiteColor,
                                                    ),
                                                  )
                                                : CustomNetworkImage(
                                                    url: cart.cartData?.kitchen
                                                            ?.kitchenProfilePhoto ??
                                                        '',
                                                    fit: BoxFit.cover,
                                                  ),
                                          ),
                                        ),
                                        SizedBox(width: Sizes.width * 0.02),
                                        Expanded(
                                          child: CustomText(
                                            text: (cart.cartData?.kitchen
                                                        ?.kitchenName ??
                                                    '')
                                                .split(' ')
                                                .map((word) => word.isNotEmpty
                                                    ? '${word[0].toUpperCase()}${word.substring(1)}'
                                                    : '')
                                                .join(' '),
                                            fontSize: 0.017,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.8,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            color: Color(0xFF4B5563),
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor: Color(0xFF4B5563),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                CustomText(
                                  text:
                                      "${cart.cartData?.kitchen?.address?.street ?? ''}, ${cart.cartData?.kitchen?.address?.city ?? ''} ${cart.cartData?.kitchen?.address?.state ?? ''} ${cart.cartData?.kitchen?.address?.pincode ?? ''}",
                                  fontSize: .016,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0XFF4B5563),
                                )
                              ],
                            ),
                          ),
                          const CustomSizedBox(
                            height: .005,
                          ),
                          Container(
                            color: AppColors.tWhiteColor,
                            padding: EdgeInsets.symmetric(
                                horizontal: Sizes.width * 0.0,
                                vertical: Sizes.height * 0.02),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const CustomPadding(
                                  left: .04,
                                  top: .02,
                                  child: CustomText(
                                    text: "Price Details",
                                    fontSize: 0.018,
                                    color: AppColors.tBlackColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                CustomPadding(
                                  horizontal: 0.04,
                                  vertical: 0.02,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      CustomText(
                                        text:
                                            "Price (${getTotalCartCount()} items) Inclusive of GST",
                                        fontSize: 0.017,
                                        color: Color(0XFF4B5563),
                                        fontWeight: FontWeight.w500,
                                      ),
                                      CustomText(
                                        text:
                                            "\$ ${(cart.cartData?.priceDetails?.itemTotal ?? 0.0).toDouble().toStringAsFixed(2)}",
                                        fontSize: 0.016,
                                        color: AppColors.tBlackColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ],
                                  ),
                                ),
                                CustomPadding(
                                  // vertical: .005,
                                  horizontal: .04,
                                  child: HorizontalDottedLine(
                                    width: Sizes.width,
                                    color: AppColors.hintTclr.withOpacity(0.2),
                                  ),
                                ),
                                // CustomPadding(
                                //   left: 0.04,
                                //   right: .04,
                                //   top: .02,
                                //   // bottom: .013,
                                //   // vertical: 0.02,
                                //   child: Row(
                                //     mainAxisAlignment:
                                //         MainAxisAlignment.spaceBetween,
                                //     children: [
                                //       CustomText(
                                //         text:
                                //             "Tax (${cart.cartData?.priceDetails?.taxPercent ?? 0.0}%)",
                                //         fontSize: 0.017,
                                //         color: Color(0XFF4B5563),
                                //         fontWeight: FontWeight.w500,
                                //       ),
                                //       CustomText(
                                //         text:
                                //             "A\$ ${cart.cartData?.priceDetails?.taxAmount ?? 0.0}",
                                //         fontSize: 0.016,
                                //         color: AppColors.tBlackColor,
                                //         fontWeight: FontWeight.w600,
                                //       ),
                                //     ],
                                //   ),
                                // ),
                                CustomPadding(
                                  horizontal: 0.04,
                                  vertical: 0.02,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      CustomText(
                                        text: "Platform fee",
                                        fontSize: 0.017,
                                        color: Color(0XFF4B5563),
                                        fontWeight: FontWeight.w500,
                                      ),
                                      CustomText(
                                        text:
                                            "\$ ${(cart.cartData?.priceDetails?.platformFee ?? 0.0).toDouble().toStringAsFixed(2)}",
                                        fontSize: 0.016,
                                        color: AppColors.tBlackColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ],
                                  ),
                                ),
                                // const CustomPadding(
                                //   bottom: .015,
                                //   left: .04,
                                //   child: Row(
                                //     children: [
                                //       CustomImage(
                                //           image: AppImages.info, height: .02),
                                //       CustomSizedBox(
                                //         width: .01,
                                //       ),
                                //       CustomText(
                                //           fontSize: .015,
                                //           fontWeight: FontWeight.w500,
                                //           text: "Know more"),
                                //     ],
                                //   ),
                                // ),
                                CustomPadding(
                                  vertical: .005,
                                  horizontal: .04,
                                  child: HorizontalDottedLine(
                                    width: Sizes.width,
                                    color: AppColors.hintTclr.withOpacity(0.2),
                                  ),
                                ),
                                CustomPadding(
                                  horizontal: 0.04,
                                  vertical: 0.015,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      CustomText(
                                        text: "Total Amount",
                                        fontSize: 0.018,
                                        color: Color(0XFF4B5563),
                                        fontWeight: FontWeight.w600,
                                      ),
                                      CustomText(
                                        text:
                                            "\$ ${(cart.cartData?.priceDetails?.totalAmount ?? 0.0).toDouble().toStringAsFixed(2)}",
                                        fontSize: 0.02,
                                        color: AppColors.tBlackColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                          CustomPadding(
                            vertical: .025,
                            horizontal: .05,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: Sizes.width * 0.05,
                                vertical: Sizes.height * 0.023,
                              ),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: const Color(0XFFE9FBEF),
                                  border: Border.all(
                                    color: const Color(0XFF00D341),
                                  )),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomImage(
                                      image: AppImages.ordersCart,
                                      height: .035),
                                  Expanded(
                                    child: CustomText(
                                      text:
                                          "By ordering this box, you’re helping save food from going to waste and supporting local restaurants",
                                      fontSize: 0.017,
                                      color: Color(0XFF4B5563),
                                      textAlign: TextAlign.center,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            color: AppColors.tWhiteColor,
                            child: CustomPadding(
                              vertical: .02,
                              horizontal: .04,
                              child: ActiveButton(
                                  height: Sizes.height * .06,
                                  width: Sizes.width,
                                  borderRadius: 25,
                                  text: "Make payment",
                                  onPressed: () {
                                    final accountController =
                                        Provider.of<AccountController>(context,
                                            listen: false);
                                    _showPaymentSelectionSheet(
                                        context,
                                        cart,
                                        accountController
                                            .savedCardsData!.data!);
                                    // if (accountController
                                    //             .savedCardsData?.data !=
                                    //         null &&
                                    //     accountController
                                    //         .savedCardsData!.data!.isNotEmpty) {

                                    // } else {
                                    //   _handlePayment(context, cart);
                                    // }
                                  }),
                            ),
                          )
                        ],
                      ),
                    ),
        ),
      );
    });
  }
}
