// import 'package:flutter/material.dart';

// import 'mediaquery.dart';

// class CustomImage extends StatelessWidget {
//   const CustomImage(
//       {super.key,
//       this.borderRadius,
//       required this.image,
//       this.height,
//       this.width,
//       this.fit,
//       this.alignment,
//       this.color});
//   final BorderRadius? borderRadius;
//   final String image;
//   final double? height;
//   final double? width;
//   final BoxFit? fit;
//   final AlignmentGeometry? alignment;
//   final Color? color;

//   @override
//   Widget build(BuildContext context) {
//     return ClipRRect(
//       borderRadius: borderRadius ?? BorderRadius.zero,
//       child: Image.asset(
//         image,
//         height: height != null ? height! * Sizes.height : null,
//         width: width != null ? width! * Sizes.width : null,
//         fit: fit,
//         alignment: alignment ?? Alignment.center,
//         color: color,
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'mediaquery.dart';

class CustomImage extends StatelessWidget {
  const CustomImage({
    super.key,
    this.borderRadius,
    required this.image,
    this.height,
    this.width,
    this.fit,
    this.alignment,
    this.color,
  });

  final BorderRadius? borderRadius;
  final String image;
  final double? height;
  final double? width;
  final BoxFit? fit;
  final AlignmentGeometry? alignment;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: image.startsWith('http')
          ? Image.network(
              image,
              height: height != null ? height! * Sizes.height : null,
              width: width != null ? width! * Sizes.width : null,
              fit: fit,
              alignment: alignment ?? Alignment.center,
              color: color,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image),
            )
          : Image.asset(
              image,
              height: height != null ? height! * Sizes.height : null,
              width: width != null ? width! * Sizes.width : null,
              fit: fit,
              alignment: alignment ?? Alignment.center,
              color: color,
            ),
    );
  }
}
