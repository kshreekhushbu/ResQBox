import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomBlurDialog extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final String confirmText;
  final String cancelText;
  final Color iconBgColor;
  final Color iconColor;
  final Color confirmButtonColor;
  final TextStyle? titleStyle;
  final TextStyle? descriptionStyle;
  final TextStyle? confirmTextStyle;
  final TextStyle? cancelTextStyle;
  final double borderRadius;
  final EdgeInsetsGeometry contentPadding;
  final Color backgroundColor;
  final bool barrierDismissible;

  const CustomBlurDialog({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onConfirm,
    required this.onCancel,
    this.confirmText = "Yes",
    this.cancelText = "Cancel",
    this.iconBgColor = const Color(0xFFD1E2FF),
    this.iconColor = const Color(0xFF0051FF),
    this.confirmButtonColor = const Color(0xFF0051FF),
    this.titleStyle,
    this.descriptionStyle,
    this.confirmTextStyle,
    this.cancelTextStyle,
    this.borderRadius = 20,
    this.contentPadding =
        const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
    this.backgroundColor = Colors.white,
    this.barrierDismissible = true,
  });

  static void show(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onConfirm,
    required VoidCallback onCancel,
    String confirmText = "Yes",
    String cancelText = "Cancel",
    Color iconBgColor = const Color(0xFFD1E2FF),
    Color iconColor = const Color(0xFF0051FF),
    Color confirmButtonColor = const Color(0xFF0051FF),
    TextStyle? titleStyle,
    TextStyle? descriptionStyle,
    TextStyle? confirmTextStyle,
    TextStyle? cancelTextStyle,
    double borderRadius = 20,
    EdgeInsetsGeometry contentPadding =
        const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
    Color backgroundColor = Colors.white,
    bool barrierDismissible = true,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: "Dialog",
      barrierColor: Colors.black.withOpacity(0.2),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: SafeArea(
            child: Center(
              child: CustomBlurDialog(
                title: title,
                description: description,
                icon: icon,
                onConfirm: onConfirm,
                onCancel: onCancel,
                confirmText: confirmText,
                cancelText: cancelText,
                iconBgColor: iconBgColor,
                iconColor: iconColor,
                confirmButtonColor: confirmButtonColor,
                titleStyle: titleStyle,
                descriptionStyle: descriptionStyle,
                confirmTextStyle: confirmTextStyle,
                cancelTextStyle: cancelTextStyle,
                borderRadius: borderRadius,
                contentPadding: contentPadding,
                backgroundColor: backgroundColor,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      backgroundColor: backgroundColor,
      child: Padding(
        padding: contentPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: iconBgColor,
              child: Icon(
                icon,
                size: 40,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: titleStyle ??
                  GoogleFonts.montserrat(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.black,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: descriptionStyle ??
                  GoogleFonts.montserrat(
                    fontWeight: FontWeight.w400,
                    color: Colors.black87,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: onCancel,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black,
                    ),
                    child: Text(
                      cancelText,
                      style: cancelTextStyle ??
                          GoogleFonts.montserrat(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confirmButtonColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      confirmText,
                      style: confirmTextStyle ??
                          GoogleFonts.montserrat(
                              fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
