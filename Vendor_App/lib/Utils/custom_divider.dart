import 'package:flutter/material.dart';
import 'package:resqboxvendor/Utils/colors.dart';
import 'package:resqboxvendor/Utils/custom_padding.dart';

class CustomDivider extends StatelessWidget {
  final double height;
  final double width;
  final Color color;

  const CustomDivider({
    super.key,
    this.height = 1,
    required this.width,
    this.color = AppColors.yash77,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPadding(
      top: 0.01,
      bottom: 0.01,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          color: color,
        ),
      ),
    );
  }
}
