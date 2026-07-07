import 'package:flutter/material.dart';
import 'package:resqbox_user/Utils/customtext.dart';
import 'package:resqbox_user/Utils/mediaquery.dart';

class CustomBorderBtn extends StatelessWidget {
  final double height;
  final double width;
  final String text;
  final VoidCallback onTap;
  final Color borderColor;
  final Color textColor;
  final double? fontSize;
  final double? borderRadius;
  final Widget? icon;

  const CustomBorderBtn({
    super.key,
    required this.height,
    required this.width,
    required this.text,
    required this.onTap,
    required this.borderColor,
    required this.textColor,
    this.fontSize,
    this.borderRadius,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: icon != null
          ? Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(borderRadius ?? 5),
                border: Border.all(color: borderColor, width: 1.2),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: Sizes.width * .23,
                  ),
                  icon!,
                  SizedBox(width: 10),
                  CustomText(
                    text: text,
                    color: textColor,
                    fontSize: fontSize ?? 0.012,
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
            )
          : Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(borderRadius ?? 5),
                border: Border.all(color: borderColor, width: 1.2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CustomText(
                    text: text,
                    color: textColor,
                    fontSize: fontSize ?? 0.012,
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
            ),
    );
  }
}

class CustomRoundedBorderBtn extends StatelessWidget {
  final double height;
  final double width;
  final String text;
  final VoidCallback onTap;
  final Color borderColor;
  final Color textColor;
  final double? fontSize;
  final double? borderRadius;

  const CustomRoundedBorderBtn({
    super.key,
    required this.height,
    required this.width,
    required this.text,
    required this.onTap,
    required this.borderColor,
    required this.textColor,
    this.fontSize,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius ?? 8),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Center(
            child: CustomText(
          text: text,
          color: textColor,
          fontSize: fontSize ?? 0.012,
          fontWeight: FontWeight.w500,
        )),
      ),
    );
  }
}
