// import 'package:flutter/material.dart';
// import 'package:tejpandit/Utils/colors.dart';
// import 'package:tejpandit/Utils/custom_image_widget.dart';
// import 'package:tejpandit/Utils/custom_padding.dart';
// import 'package:tejpandit/Utils/customtext.dart';
// import 'package:tejpandit/Utils/images.dart';
// import 'package:tejpandit/Utils/mediaquery.dart';

// // class TempleContainer extends StatelessWidget {
// //   final String templeName;
// //   final String location;
// //   final String text;
// //   const TempleContainer({
// //     super.key,
// //     required this.templeName,
// //     required this.location,
// //     required this.text,
// //   });

// //   @override
// //   Widget build(BuildContext context) {
// //     return CustomPadding(
// //       top: 0.015,
// //       child: Container(
// //         margin: const EdgeInsets.only(right: 2),
// //         decoration: BoxDecoration(
// //             border: Border.all(
// //               color: AppColors.lightYash,
// //             ),
// //             borderRadius: BorderRadius.circular(15)),
// //         padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
// //         child: Row(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //           children: [
// //             Placeholder(
// //               fallbackHeight: Sizes.height * .08,
// //               fallbackWidth: Sizes.width * .17,
// //             ),
// //             Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //               mainAxisSize: MainAxisSize.min,
// //               children: [
// //                 CustomPadding(
// //                   bottom: .01,
// //                   child: CustomText(
// //                     text: templeName,
// //                     fontWeight: FontWeight.w600,
// //                     fontSize: .02,
// //                   ),
// //                 ),
// //                 CustomPadding(
// //                   // bottom: .008,
// //                   child: Row(
// //                     children: [
// //                       const CustomPadding(
// //                         right: .015,
// //                         child: CustomImage(
// //                           image: AppImages.locationIcon,
// //                           height: .018,
// //                         ),
// //                       ),
// //                       CustomText(
// //                         text: location,
// //                         fontWeight: FontWeight.w400,
// //                         fontSize: .014,
// //                       )
// //                     ],
// //                   ),
// //                 ),
// //               ],
// //             ),
// //             CustomPadding(
// //                 top: .02,
// //                 child: Container(
// //                   height: 35,
// //                   width: 80,
// //                   decoration: BoxDecoration(
// //                       color: AppColors.subText,
// //                       borderRadius: BorderRadius.circular(6)),
// //                   child: Align(
// //                     alignment: Alignment.center,
// //                     child: CustomText(
// //                       text: text,
// //                       color: AppColors.tWhiteColor,
// //                       fontSize: 0.012,
// //                     ),
// //                   ),
// //                 ))
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
