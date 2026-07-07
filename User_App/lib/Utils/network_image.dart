import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter/material.dart';
import 'package:resqbox_user/Utils/images.dart';
import 'package:shimmer/shimmer.dart';

import 'colors.dart';
import 'mediaquery.dart';

class CustomNetworkImage extends StatelessWidget {
  const CustomNetworkImage(
      {super.key,
      required this.url,
      this.height,
      this.width,
      this.isDecorationImage = false,
      this.color,
      this.fit,
      this.errorWidgetHeight,
      this.borderRadius});
  final String url;
  final double? height;
  final double? width;
  final Color? color;
  final BorderRadiusGeometry? borderRadius;
  final BoxFit? fit;
  final bool isDecorationImage;
  final double? errorWidgetHeight;
  @override
  Widget build(BuildContext context) {
    // if (url.endsWith('NA')) {
    //   return CustomImage(
    //     image: Images.viventIcon,
    //     height: height,
    //     width: width,
    //     fit: BoxFit.contain,
    //   );
    // }
    return CachedNetworkImage(
        progressIndicatorBuilder: (context, url, progress) => _buildShimmer(),
        color: isDecorationImage == true ? color : null,
        imageBuilder: isDecorationImage == true
            ? (context, imageProvider) => Container(
                  decoration: BoxDecoration(
                    borderRadius: borderRadius,
                    image: DecorationImage(
                      image: imageProvider,
                      fit: fit ?? BoxFit.contain,
                    ),
                  ),
                )
            : null,
        imageUrl: url,
        height: height != null ? height! * Sizes.height : null,
        width: width != null ? width! * Sizes.width : null,
        fit: fit,
        errorWidget: (context, url, error) => _buildShimmer()
        // const Icon(
        //   Icons.error,
        //   color: AppColors.blackText,
        //   size: 20,
        // ),
        );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
          width: width != null
              ? width! * Sizes.width
              : (height != null ? height! * Sizes.height : 180),
          height: height != null ? height! * Sizes.height : 180,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: borderRadius ?? BorderRadius.circular(15),
          ),
          child: Stack(
            children: [
              Center(
                child: Image.asset(
                  AppImages.logo,
                  width: width != null ? (width! * Sizes.width) * 0.5 : 60,
                  height: height != null ? (height! * Sizes.height) * 0.5 : 60,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          )),
    );
  }
}
