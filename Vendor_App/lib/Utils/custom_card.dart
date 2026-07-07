import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  final double? height;
  final double? width;
  final Widget child;
  final Color? backgroundColor;
  final double borderRadius;
  final double blurRadius;
  final double spreadRadius;
  final Offset shadowOffset;
  final Color shadowColor;

  const CustomCard({
    super.key,
    this.height,
    this.width,
    required this.child,
    this.backgroundColor = Colors.white,
    this.borderRadius = 8.0,
    this.blurRadius = 5.0,
    this.spreadRadius = 0.3,
    this.shadowOffset = const Offset(0, 0),
    this.shadowColor = Colors.black54,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height, // Customizable height
      width: width, // Customizable width
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: const Color(0XFFC0C0C0), width: 1),
        borderRadius: BorderRadius.circular(
          borderRadius,
        ),
        // boxShadow: [
        //   BoxShadow(
        //     color: AppColors.blackText.withOpacity(0.2), // Shadow color
        //     blurRadius: 5, // Increase blur for a softer shadow
        //     spreadRadius: 0.1, // Increase spread to cover all sides
        //     offset: Offset(
        //       0,
        //       2,
        //     ), // Adjust the position of the shadow
        //   ),
        // ],
      ),
      child: Card(
        surfaceTintColor: backgroundColor?.withOpacity(0.2),
        semanticContainer: true,
        color: backgroundColor,
        elevation: 0, // Disable default shadow
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: child,
      ),
    );
  }
}
