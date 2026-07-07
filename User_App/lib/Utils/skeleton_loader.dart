// import 'package:flutter/material.dart';
// import 'package:skeleton_text/skeleton_text.dart';

// import 'mediaquery.dart';

// class SkeletonLoaderWidget extends StatelessWidget {
//   const SkeletonLoaderWidget({
//     super.key,
//     required this.height,
//     required this.width,
//   });

//   final double height;
//   final double width;

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//         child: SkeletonAnimation(
//       shimmerDuration: 200,
//       child: Container(
//         height: Sizes.height * height,
//         width: Sizes.width * width,
//         decoration: BoxDecoration(
//           color: Colors.grey[300],
//           borderRadius: BorderRadius.circular(5),
//           boxShadow: const [BoxShadow(color: Colors.pink)],
//         ),
//       ),
//     ));
//   }
// }
