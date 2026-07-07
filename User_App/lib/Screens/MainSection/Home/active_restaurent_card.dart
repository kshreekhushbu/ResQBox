// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:resqbox_user/Controllers/account_controller.dart';
// import 'package:resqbox_user/Controllers/home_controller.dart';
// import 'package:resqbox_user/Models/home_data_model.dart';
// import 'package:resqbox_user/Screens/MainSection/Home/kitchens_view_screen.dart';
// import 'package:resqbox_user/Screens/MainSection/Home/popular_kitchen_card.dart';
// import 'package:resqbox_user/Utils/colors.dart';
// import 'package:resqbox_user/Utils/custom_image_widget.dart';
// import 'package:resqbox_user/Utils/custom_padding.dart';
// import 'package:resqbox_user/Utils/customtext.dart';
// import 'package:resqbox_user/Utils/images.dart';
// import 'package:resqbox_user/Utils/mediaquery.dart';
// import 'package:resqbox_user/Utils/navigations.dart';
// import 'package:resqbox_user/Utils/network_image.dart';

// import '../../../Utils/custom_tap.dart';

// class ActiveRestaurantsSection extends StatelessWidget {
//   const ActiveRestaurantsSection({super.key, required this.items});

//   final List<ActiveRestaurantData>? items;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: Sizes.width,
//       color: AppColors.tWhiteColor,
//       child: CustomPadding(
//         vertical: .03,
//         horizontal: .04,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 CustomText(
//                   text: "Active restaurants near you",
//                   fontWeight: FontWeight.w600,
//                   fontSize: 0.018,
//                 ),
//                 CustomText(
//                   text: "See All",
//                   fontWeight: FontWeight.w500,
//                   color: AppColors.tPrimaryColor,
//                   fontSize: 0.018,
//                 ),
//               ],
//             ),
//             SizedBox(height: Sizes.height * 0.02),
//             (items == null || items!.isEmpty)
//                 ? const SizedBox.shrink()
//                 : ListView.builder(
//                     shrinkWrap: true,
//                     physics: const NeverScrollableScrollPhysics(),
//                     itemCount: items!.length,
//                     itemBuilder: (context, index) => Padding(
//                       padding: EdgeInsets.only(
//                         bottom: index == items!.length - 1
//                             ? 0
//                             : Sizes.height * 0.018,
//                       ),
//                       child: _ActiveRestaurantCard(item: items![index]),
//                     ),
//                   ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _ActiveRestaurantCard extends StatefulWidget {
//   const _ActiveRestaurantCard({required this.item});

//   final ActiveRestaurantData? item;

//   @override
//   State<_ActiveRestaurantCard> createState() => _ActiveRestaurantCardState();
// }

// class _ActiveRestaurantCardState extends State<_ActiveRestaurantCard> {
//   int? _localIsWishlist;

//   @override
//   void initState() {
//     super.initState();
//     _localIsWishlist = widget.item?.isWishlist;
//   }

//   @override
//   void didUpdateWidget(_ActiveRestaurantCard oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     // Update local state when widget data changes
//     if (oldWidget.item?.isWishlist != widget.item?.isWishlist) {
//       _localIsWishlist = widget.item?.isWishlist;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(Sizes.height * 0.01),
//         border: Border.all(color: const Color(0xFFDEDEDE), width: 0.8),
//         color: AppColors.tWhiteColor,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.08),
//             blurRadius: 12,
//             offset: const Offset(0, 8),
//           ),
//         ],
//       ),
//       child: CustomPadding(
//         top: .015,
//         bottom: .015,
//         left: .02,
//         right: .03,
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             ClipOval(
//               child: SizedBox(
//                 height: Sizes.height * 0.075,
//                 width: Sizes.height * 0.075,
//                 child: CustomNetworkImage(
//                   url: widget.item?.photos?.kitchenProfilePhoto ?? '',
//                   fit: BoxFit.cover,
//                 ),
//               ),
//             ),
//             SizedBox(width: Sizes.width * 0.02),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Expanded(
//                         child: CustomText(
//                           text: widget.item?.kitchenName ?? '',
//                           fontSize: 0.016,
//                           overflow: TextOverflow.ellipsis,
//                           maxLines: 1,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                       GestureDetector(
//                         onTap: () async {
//                           final accountController =
//                               Provider.of<AccountController>(context,
//                                   listen: false);
//                           final homeController = Provider.of<HomeController>(
//                               context,
//                               listen: false);
//                           final kitchenId = widget.item?.kitchenId;

//                           if (kitchenId == null) return;

//                           final currentWishlistStatus =
//                               _localIsWishlist ?? widget.item?.isWishlist ?? 0;

//                           // Update local state optimistically
//                           setState(() {
//                             _localIsWishlist =
//                                 currentWishlistStatus == 1 ? 0 : 1;
//                           });

//                           bool success = false;

//                           // If isWishlist is 1, remove from wishlist
//                           // If isWishlist is 0, add to wishlist
//                           if (currentWishlistStatus == 1) {
//                             // Currently in wishlist, remove it
//                             success = await accountController
//                                 .removeFromWishlistApi(kitchenId);
//                           } else {
//                             // Not in wishlist, add it
//                             success = await accountController.addToWishlistApi(
//                                 body: {"kitchenId": kitchenId});
//                           }

//                           if (success) {
//                             // Refresh home data to update wishlist status
//                             if (homeController.locLatitude != null &&
//                                 homeController.locLongitude != null) {
//                               await homeController.fetchHomePageData(
//                                 latitude: homeController.locLatitude!,
//                                 longitude: homeController.locLongitude!,
//                               );
//                             }
//                           } else {
//                             // Revert on failure
//                             setState(() {
//                               _localIsWishlist = currentWishlistStatus;
//                             });
//                           }
//                         },
//                         child: Padding(
//                           padding: EdgeInsets.all(Sizes.width * 0.01),
//                           child: CustomImage(
//                             image: AppImages.favIcon,
//                             color: (_localIsWishlist ??
//                                         widget.item?.isWishlist ??
//                                         0) ==
//                                     1
//                                 ? AppColors.tPrimaryColor
//                                 : Colors.grey.shade400,
//                             height: 0.02,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: Sizes.height * 0.001),
//                   CustomText(
//                     text: widget.item?.cuisines?.first ?? '',
//                     fontSize: 0.014,
//                     fontWeight: FontWeight.w500,
//                     color: AppColors.hintTclr,
//                   ),
//                   SizedBox(height: Sizes.height * 0.004),
//                   Row(
//                     children: [
//                       RatingStars(
//                           rating: double.parse(widget.item?.rating ?? '0')),
//                       SizedBox(width: Sizes.width * 0.015),
//                       const Icon(
//                         Icons.circle,
//                         size: 5,
//                         color: Color(0xFF989898),
//                       ),
//                       SizedBox(width: Sizes.width * 0.015),
//                       Row(
//                         children: [
//                           Image.asset(
//                             AppImages.distance,
//                             height: Sizes.height * 0.018,
//                             color: AppColors.green,
//                           ),
//                           SizedBox(width: Sizes.width * 0.01),
//                           CustomText(
//                             text:
//                                 "${widget.item?.distanceKm?.toStringAsFixed(1) ?? '0.0'} km",
//                             fontSize: 0.014,
//                             fontWeight: FontWeight.w500,
//                             color: const Color(0xFF4B5563),
//                           ),
//                         ],
//                       ),
//                       SizedBox(width: Sizes.width * 0.015),
//                       const Icon(
//                         Icons.circle,
//                         size: 5,
//                         color: Color(0xFF989898),
//                       ),
//                       SizedBox(width: Sizes.width * 0.015),
//                       Row(
//                         children: [
//                           Image.asset(
//                             AppImages.locCard,
//                             height: Sizes.height * 0.018,
//                             color: AppColors.green,
//                           ),
//                           SizedBox(width: Sizes.width * 0.005),
//                           Flexible(
//                             child: CustomText(
//                               text:
//                                   "${widget.item?.address?.landmark ?? ''} - ${widget.item?.address?.city ?? ''}",
//                               overflow: TextOverflow.ellipsis,
//                               maxLines: 1,
//                               fontSize: 0.014,
//                               fontWeight: FontWeight.w500,
//                               color: const Color(0xFF4B5563),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: Sizes.height * 0.006),
//                   CustomText(
//                     text:
//                         "${widget.item?.totalItemsQuantity ?? 0} Boxes Available",
//                     fontSize: 0.016,
//                     fontWeight: FontWeight.w500,
//                     color: AppColors.tPrimaryColor,
//                   ),
//                 ],
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
