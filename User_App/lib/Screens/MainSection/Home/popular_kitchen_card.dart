import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:resqbox_user/Models/home_data_model.dart';
import 'package:resqbox_user/Screens/MainSection/Home/Menu/menu_view_screen.dart';
import 'package:resqbox_user/Screens/MainSection/Home/kitchens_view_screen.dart';
import 'package:resqbox_user/Utils/colors.dart';
import 'package:resqbox_user/Utils/custom_image_widget.dart';
import 'package:resqbox_user/Utils/custom_tap.dart';
import 'package:resqbox_user/Utils/customtext.dart';
import 'package:resqbox_user/Utils/images.dart';
import 'package:resqbox_user/Utils/mediaquery.dart';
import 'package:resqbox_user/Utils/navigations.dart';
import 'package:resqbox_user/Utils/network_image.dart';

class PopularKitchenCard extends StatefulWidget {
  const PopularKitchenCard({super.key, this.item, this.cardWidth});

  final Product? item;
  final double? cardWidth;

  @override
  State<PopularKitchenCard> createState() => _PopularKitchenCardState();
}

class _PopularKitchenCardState extends State<PopularKitchenCard> {
  @override
  Widget build(BuildContext context) {
    final double cardWidth = widget.cardWidth ?? Sizes.width * 0.58;
    bool isOutOfStock = (widget.item?.quantity ?? 0) <= 0;

    return AbsorbPointer(
      absorbing: isOutOfStock,
      child: CustomTap(
        onTap: () {
          NavigateTo().nextPage(
            child: MenuViewScreen(
              menuId: widget.item?.id,
            ),
          );
        },
        child: Stack(
          children: [
            ColorFiltered(
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
                width: cardWidth,
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
                            height: Sizes.height * 0.19,
                            width: cardWidth,
                            child: CustomNetworkImage(
                              url: widget.item?.image ?? '',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                            top: 10,
                            right: 0,
                            child: CustomImage(
                              image: AppImages.tag,
                              height: .032,
                            )),
                        Positioned(
                            top: 15,
                            right: 2,
                            child: Center(
                              child: CustomText(
                                text:
                                    "${widget.item?.discountPercentage?.round() ?? 0}% OFF",
                                fontSize: 0.014,
                                // letterSpacing: 0.8,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                fontWeight: FontWeight.w600,
                                color: AppColors.tBlackColor,
                              ),
                            )),
                        if (isOutOfStock)
                          Positioned(
                              top: 35,
                              bottom: 35,
                              left: 35,
                              right: 35,
                              child: CustomImage(
                                image: AppImages.soldOut,
                                color: AppColors.tWhiteColor,
                                height: .05,
                              ))
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: Sizes.width * 0.02,
                        vertical: Sizes.height * 0.01,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: CustomText(
                                  text: (widget.item?.name ?? '')
                                      .split(' ')
                                      .map((word) => word.isNotEmpty
                                          ? '${word[0].toUpperCase()}${word.substring(1)}'
                                          : '')
                                      .join(' '),
                                  //  widget.item?.name ?? '',
                                  fontSize: 0.018,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              CustomText(
                                text:
                                    "\$${(widget.item?.discountPrice ?? 0.0).toDouble().toStringAsFixed(2)}",
                                fontSize: 0.018,
                                fontWeight: FontWeight.w700,
                                color: AppColors.tPrimaryColor,
                              ),
                              SizedBox(width: Sizes.width * 0.02),
                              Stack(
                                children: [
                                  CustomText(
                                    text:
                                        "\$${(widget.item?.price ?? 0.0).toDouble().toStringAsFixed(2)}",
                                    fontSize: 0.014,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xff4B5563),
                                  ),
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: DiagonalLinePainter(
                                        color: AppColors.tPrimaryColor,
                                        strokeWidth: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: Sizes.height * 0.01),
                          widget.cardWidth == Sizes.width
                              ? Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Rating section
                                    // Expanded(
                                    //   child: Row(
                                    //     mainAxisSize: MainAxisSize.min,
                                    //     children: [
                                    //
                                    //     ],
                                    //   ),
                                    // ),
                                    RatingStars(
                                        rating: double.parse(
                                            widget.item?.rating ?? '0')),
                                    SizedBox(width: Sizes.width * 0.045),

                                    // Distance section
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.circle,
                                          size: 4,
                                          color: Color(0xFF989898),
                                        ),
                                        SizedBox(width: Sizes.width * 0.01),
                                        Image.asset(
                                          AppImages.distance,
                                          height: Sizes.height * 0.016,
                                          color: AppColors.green,
                                        ),
                                        SizedBox(width: Sizes.width * 0.008),
                                        Flexible(
                                          child: CustomText(
                                            text:
                                                '${widget.item?.restaurant?.distanceKm?.toStringAsFixed(1) ?? '0.0'} km',
                                            fontSize: 0.014,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFF4B5563),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(width: Sizes.width * 0.01),

                                    // Time section
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.circle,
                                          size: 4,
                                          color: Color(0xFF989898),
                                        ),
                                        SizedBox(width: Sizes.width * 0.01),
                                        Image.asset(
                                          AppImages.clock,
                                          height: Sizes.height * 0.016,
                                          color: AppColors.green,
                                        ),
                                        SizedBox(width: Sizes.width * 0.008),
                                        Flexible(
                                          child: CustomText(
                                            text: widget.item?.endTime ?? '',
                                            fontSize: 0.014,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFF4B5563),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    // Rating section
                                    // Expanded(
                                    //   child: Row(
                                    //     mainAxisSize: MainAxisSize.min,
                                    //     children: [
                                    //
                                    //     ],
                                    //   ),
                                    // ),
                                    RatingStars(
                                        rating: double.parse(
                                            widget.item?.rating ?? '0')),
                                    SizedBox(width: Sizes.width * 0.045),
                                    const Icon(
                                      Icons.circle,
                                      size: 4,
                                      color: Color(0xFF989898),
                                    ),
                                    SizedBox(width: Sizes.width * 0.01),
                                    // Distance section
                                    Expanded(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Image.asset(
                                            AppImages.distance,
                                            height: Sizes.height * 0.016,
                                            color: AppColors.green,
                                          ),
                                          SizedBox(width: Sizes.width * 0.008),
                                          Flexible(
                                            child: CustomText(
                                              text:
                                                  '${widget.item?.restaurant?.distanceKm?.toStringAsFixed(1) ?? '0.0'} km',
                                              fontSize: 0.014,
                                              fontWeight: FontWeight.w500,
                                              color: const Color(0xFF4B5563),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: Sizes.width * 0.01),
                                    const Icon(
                                      Icons.circle,
                                      size: 4,
                                      color: Color(0xFF989898),
                                    ),
                                    SizedBox(width: Sizes.width * 0.01),
                                    // Time section
                                    Expanded(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Image.asset(
                                            AppImages.clock,
                                            height: Sizes.height * 0.016,
                                            color: AppColors.green,
                                          ),
                                          SizedBox(width: Sizes.width * 0.008),
                                          Flexible(
                                            child: CustomText(
                                              text: widget.item?.endTime ?? '',
                                              fontSize: 0.014,
                                              fontWeight: FontWeight.w500,
                                              color: const Color(0xFF4B5563),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                          SizedBox(height: Sizes.height * 0.012),
                          Row(
                            children: [
                              CustomTap(
                                onTap: () {
                                  NavigateTo().nextPage(
                                      child: KitchensViewScreen(
                                          restaurantId: widget
                                              .item?.restaurant?.kitchenId));
                                },
                                child: ClipOval(
                                  child: SizedBox(
                                    width: Sizes.height * 0.052,
                                    height: Sizes.height * 0.052,
                                    child: (widget.item?.restaurant?.photos
                                                    ?.kitchenProfilePhoto ==
                                                null ||
                                            widget
                                                    .item
                                                    ?.restaurant
                                                    ?.photos
                                                    ?.kitchenProfilePhoto
                                                    ?.isEmpty ==
                                                true)
                                        ? CircleAvatar(
                                            backgroundColor:
                                                AppColors.tPrimaryColor,
                                            child: CustomText(
                                              text: (widget
                                                          .item
                                                          ?.restaurant
                                                          ?.kitchenName
                                                          ?.isNotEmpty ??
                                                      false)
                                                  ? (widget.item?.restaurant
                                                          ?.kitchenName?[0]
                                                          .toUpperCase() ??
                                                      'K')
                                                  : 'K',
                                              fontSize: 0.018,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.tWhiteColor,
                                            ),
                                          )
                                        : CustomNetworkImage(
                                            url: widget.item?.restaurant?.photos
                                                    ?.kitchenProfilePhoto ??
                                                '',
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                ),
                              ),
                              SizedBox(width: Sizes.width * 0.01),
                              Expanded(
                                child: CustomTap(
                                  onTap: () {
                                    NavigateTo().nextPage(
                                        child: KitchensViewScreen(
                                            restaurantId: widget
                                                .item?.restaurant?.kitchenId));
                                  },
                                  child: Text(
                                    (widget.item?.restaurant?.kitchenName ?? '')
                                        .split(' ')
                                        .map((word) => word.isNotEmpty
                                            ? '${word[0].toUpperCase()}${word.substring(1)}'
                                            : '')
                                        .join(' '),
                                    // widget.item?.restaurant?.kitchenName ?? '',
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: GoogleFonts.inter(
                                      fontSize: Sizes.height * 0.018,
                                      fontWeight: FontWeight.w500,
                                      shadows: [
                                        Shadow(
                                            color: Color(0xFF4B5563),
                                            offset: Offset(0, -2))
                                      ],
                                      color: Colors.transparent,
                                      decoration: TextDecoration.underline,
                                      decorationColor: Color(0xFF4B5563),
                                      decorationThickness: 1.2,
                                      decorationStyle:
                                          TextDecorationStyle.solid,
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // if (isOutOfStock)
            //   Positioned.fill(
            //     child: Center(
            //       child: TweenAnimationBuilder<double>(
            //         tween: Tween(begin: 0.0, end: 1.0),
            //         duration: const Duration(milliseconds: 300),
            //         builder: (context, value, child) {
            //           return Opacity(
            //             opacity: value,
            //             child: Container(
            //               padding: EdgeInsets.symmetric(
            //                   horizontal: Sizes.width * 0.04,
            //                   vertical: Sizes.height * 0.006),
            //               decoration: BoxDecoration(
            //                 color: AppColors.tBlackColor.withOpacity(0.7),
            //                 borderRadius: BorderRadius.circular(20),
            //               ),
            //               child: CustomText(
            //                 text: "SOLD OUT",
            //                 color: AppColors.tWhiteColor,
            //                 fontWeight: FontWeight.w700,
            //                 fontSize: 0.012,
            //               ),
            //             ),
            //           );
            //         },
            //       ),
            //     ),
            //   ),
          ],
        ),
      ),
    );
  }
}

class RatingStars extends StatelessWidget {
  final double rating;
  const RatingStars({super.key, required this.rating});

  @override
  Widget build(BuildContext context) {
    IconData iconData;
    if (rating >= 4.75) {
      iconData = Icons.star;
    } else if (rating >= 4.25) {
      iconData = Icons.star;
    } else if (rating >= 3.75) {
      iconData = Icons.star_half;
    } else {
      iconData = Icons.star_border;
    }

    return Row(
      children: [
        Icon(
          iconData,
          size: Sizes.height * 0.018,
          color: AppColors.green,
        ),
        SizedBox(width: Sizes.width * 0.01),
        CustomText(
          text: rating.toStringAsFixed(1),
          fontSize: 0.014,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF4B5563),
        ),
      ],
    );
  }
}
