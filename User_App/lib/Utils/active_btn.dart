import 'package:flutter/material.dart';
import 'package:resqbox_user/Utils/colors.dart';
import 'package:resqbox_user/Utils/customtext.dart';

class ActiveButton extends StatelessWidget {
  final double height;
  final double width;
  final String text;
  final Function onPressed;
  final Color? color;
  final String? bgColor;
  final Color? txtClr;
  final double? fontSize;
  final double? borderRadius;

  const ActiveButton({
    required this.height,
    required this.width,
    required this.text,
    required this.onPressed,
    this.color,
    this.bgColor,
    this.txtClr,
    this.fontSize,
    this.borderRadius,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onPressed(),
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius ?? 8),
          color: color ?? AppColors.tPrimaryColor,
        ),
        child: Center(
            child: CustomText(
          text: text,
          color: txtClr ?? AppColors.tWhiteColor,
          fontSize: fontSize ?? 0.020,
          fontWeight: FontWeight.w600,
        )),
      ),
    );
  }
}
