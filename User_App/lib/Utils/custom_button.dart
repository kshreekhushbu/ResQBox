import 'package:flutter/material.dart';
import 'package:resqbox_user/Utils/mediaquery.dart';

import 'colors.dart';
import 'custom_image_widget.dart';
import 'custom_padding.dart';
import 'custom_tap.dart';
import 'customtext.dart';

class CustomButton extends StatelessWidget {
  const CustomButton(
      {super.key,
      required this.title,
      this.onTap,
      this.buttonColor,
      this.textColor,
      this.width,
      this.height,
      this.textsize,
      this.buttonImage,
      this.borderRaduise,
      this.fontWeight,
      this.border,
      this.boxShadow});
  final String title;
  final Color? buttonColor;
  final Color? textColor;
  final void Function()? onTap;

  final double? width;
  final double? height;
  final double? textsize;
  final double? borderRaduise;
  final String? buttonImage;
  final FontWeight? fontWeight;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  @override
  Widget build(BuildContext context) {
    // Ensure that height and width are properly initialized
    final double buttonHeight =
        height != null ? (height! * Sizes.height) : Sizes.height * .045;
    final double buttonWidth = width != null
        ? Sizes.width * width!
        : Sizes.width * 0.8; // Default width if not passed

    return CustomTap(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        height: buttonHeight,
        //  height != null ? (height! * Sizes.height) : Sizes.height * .045,
        width: buttonWidth,
        //  width != null ? Sizes.width * width! : width,
        decoration: BoxDecoration(
            border: border ?? Border.all(),
            // gradient: buttonColor == Colors.transparent
            //     ? LinearGradient(
            //         colors: [AppColors.tTransparrent, AppColors.tTransparrent])
            //     : LinearGradient(colors: [
            //         AppColors.tPrimaryColor,
            //         AppColors.tSecdoryColor,
            //         AppColors.tSecdoryColor
            //       ]),
            color: buttonColor ?? AppColors.tWhiteColor,
            borderRadius: BorderRadius.circular(borderRaduise ?? 10),
            boxShadow: boxShadow),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (buttonImage != null)
              CustomPadding(
                right: .015,
                child: CustomImage(
                  image: buttonImage ?? '',
                  height: .03,
                ),
              ),
            CustomText(
              text: title,
              color: textColor ?? AppColors.tWhiteColor,
              fontWeight: fontWeight ?? FontWeight.w700,
              fontSize: textsize ?? .0175,
            ),
          ],
        ),
      ),
    );
  }
}

// class Sizes {
//   static double height = 0;
//   static double width = 0;

//   // Initialize this in an appropriate place, such as in your main widget's build method or initState
//   static void initialize(BuildContext context) {
//     height = MediaQuery.of(context).size.height;
//     width = MediaQuery.of(context).size.width;
//   }
// }
