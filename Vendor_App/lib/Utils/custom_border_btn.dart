import 'package:flutter/material.dart';
import 'package:resqboxvendor/Utils/textstyles.dart';
import 'package:resqboxvendor/utils/colors.dart';

class CustomBorderBtn extends StatelessWidget {
  final double height;
  final double width;
  final String text;
  final VoidCallback onTap;
  final Color? borderColor;
  final Color? color;
  final Color textColor;
  final double? fontSize;
  final Widget? leading; // <-- Added for image/icon

  const CustomBorderBtn({
    super.key,
    required this.height,
    required this.width,
    this.color = AppColors.mainAppColr,
    required this.text,
    required this.onTap,
    this.borderColor = Colors.transparent,
    required this.textColor,
    this.fontSize,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: borderColor!, width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 8)],
            Text(
              text,
              style: AppTextStyles.buttonText.copyWith(color: textColor),
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
  final Widget? leading; // <-- Added for image/icon

  const CustomRoundedBorderBtn({
    super.key,
    required this.height,
    required this.width,
    required this.text,
    required this.onTap,
    required this.borderColor,
    required this.textColor,
    this.fontSize,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: const Color(0XFFFBFFC2),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 8)],
            Text(
              text,
              style: AppTextStyles.size14Medium.copyWith(
                fontSize: fontSize ?? 14,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// class CustomRectBtn extends StatelessWidget {
//   final double height;
//   final double width;
//   final String? text; // optional
//   final VoidCallback onTap;
//   final Color color;
//   final Color textColor;
//   final double? fontSize;
//   final Color? borderColor;
//   final double borderRadius;
//   final Widget? leading; // optional

//   const CustomRectBtn({
//     super.key,
//     required this.height,
//     required this.width,
//     this.text,
//     required this.onTap,
//     required this.color,
//     required this.textColor,
//     this.fontSize,
//     this.borderColor,
//     this.borderRadius = 5,
//     this.leading,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: width,
//         height: height,
//         padding: const EdgeInsets.symmetric(horizontal: 12),
//         decoration: BoxDecoration(
//           color: color,
//           borderRadius: BorderRadius.circular(borderRadius),
//           border: Border.all(
//             color: borderColor ?? Colors.transparent,
//             width: 1.2,
//           ),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             if (leading != null) leading!,
//             if (leading != null && text != null) const SizedBox(width: 6),
//             if (text != null)
//               Text(
//                 text!,
//                 overflow: TextOverflow.ellipsis,
//                 style: AppTextStyles.size16SemiBold.copyWith(
//                   overflow: TextOverflow.ellipsis,
//                   color: textColor,
//                   fontSize: fontSize ?? 16,
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }

class CustomRectBtn extends StatelessWidget {
  final double height;
  final double width;
  final String? text; // optional
  final VoidCallback onTap;
  final Color color;
  final Color textColor;
  final double? fontSize;
  final Color? borderColor;
  final double borderRadius;
  final Widget? leading; // optional

  const CustomRectBtn({
    super.key,
    required this.height,
    required this.width,
    this.text,
    required this.onTap,
    required this.color,
    required this.textColor,
    this.fontSize,
    this.borderColor,
    this.borderRadius = 5,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: borderColor ?? Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Center(
          // ✅ Centers the Row perfectly
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (leading != null) ...[
                Flexible(child: leading!),
                const SizedBox(width: 6),
              ],
              if (text != null)
                Flexible(
                  // ✅ Prevents overflow and enables ellipsis
                  child: Text(
                    text!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.size16SemiBold.copyWith(
                      color: textColor,
                      fontSize: fontSize ?? 16,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
