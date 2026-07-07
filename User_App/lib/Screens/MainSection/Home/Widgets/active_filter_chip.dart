import 'package:flutter/material.dart';
import 'package:resqbox_user/Utils/colors.dart';
import 'package:resqbox_user/Utils/custom_sizedbox.dart';
import 'package:resqbox_user/Utils/custom_tap.dart';
import 'package:resqbox_user/Utils/customtext.dart';
import 'package:resqbox_user/Utils/mediaquery.dart';
import 'package:resqbox_user/Utils/network_image.dart';

class ActiveFilterChip extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final VoidCallback onRemove;

  const ActiveFilterChip({
    super.key,
    required this.name,
    this.imageUrl,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Sizes.width * 0.02,
        vertical: Sizes.height * 0.005,
      ),
      decoration: BoxDecoration(
        color: AppColors.tWhiteColor,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.tPrimaryColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (imageUrl != null && imageUrl!.isNotEmpty) ...[
            CustomNetworkImage(
              url: imageUrl!,
              height: .024,
              width: .05,
            ),
            const CustomSizedBox(width: 0.015),
          ],
          CustomText(
            text: name,
            fontSize: .014,
            fontWeight: FontWeight.w500,
            color: AppColors.tBlackColor,
          ),
          const CustomSizedBox(width: 0.015),
          CustomTap(
            onTap: onRemove,
            child: const Icon(
              Icons.close,
              size: 16,
              color: AppColors.tBlackColor,
            ),
          ),
        ],
      ),
    );
  }
}
