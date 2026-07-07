import 'package:flutter/material.dart';
import 'package:resqbox_user/Utils/colors.dart';
import 'package:resqbox_user/Utils/customtext.dart';

class CustomButton2 extends StatelessWidget {
  final String text;
  final Color borderColo;
  final Color buttonColor;
  final Color textColor;
  final double borderRadius;
  final double fontSize;
  final double elevation;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;

  const CustomButton2({
    super.key,
    required this.text,
    required this.onPressed,
    this.borderColo = AppColors.tTransparrent,
    this.buttonColor = AppColors.tPrimaryColor,
    this.textColor = AppColors.tWhiteColor,
    this.borderRadius = 10.0,
    this.fontSize = 0.016,
    this.elevation = 5.0,
    this.isLoading = false, // Default to false
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      width: double.infinity,
      child: ElevatedButton(
          onPressed: isLoading ? null : onPressed, // Disable when loading
          style: ElevatedButton.styleFrom(
            elevation: elevation,
            backgroundColor:
                isOutlined ? Colors.white : AppColors.tPrimaryColor,
            foregroundColor:
                isOutlined ? AppColors.tPrimaryColor : Colors.white,
            side: isOutlined ? BorderSide(color: borderColo) : null,
            // padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          child: isLoading
              ? const Align(
                  child: SizedBox(
                      height: 30,
                      width: 30,
                      child: CircularProgressIndicator(color: Colors.white)),
                )
              : CustomText(
                  text: text,
                  fontSize: fontSize,
                  color: textColor,
                )
          // Text(
          //     text,
          //     style: const TextStyle(fontSize: 16),
          //   ),
          ),
    );
  }
}
