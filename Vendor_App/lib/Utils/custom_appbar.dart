import 'package:flutter/material.dart';
import 'package:resqboxvendor/Utils/colors.dart';
import 'package:resqboxvendor/Utils/textstyles.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  const CustomAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.backTap,
    this.actionTap,
    this.actionImage,
    this.leadingImage,
    this.titleFontSize,
    this.isFromTabsScreen = false,
    this.backgroundColor,
    this.textColor,
    this.leadingHeight,
    this.actions,
    this.isLeading = true,
    this.centerTitle = true,
    this.bgColor,
    this.isBackground = false,
    this.bottom, // ✅ added bottom
    this.titleTextStyle,
  });

  final String? title;
  final Widget? titleWidget;
  final Function()? backTap;
  final Function()? actionTap;
  final String? actionImage;
  final String? leadingImage;
  final Color? backgroundColor;
  final Color? textColor;
  final double? leadingHeight;
  final double? titleFontSize;
  final bool isFromTabsScreen;
  final List<Widget>? actions;
  final bool isLeading;
  final bool? centerTitle;
  final Color? bgColor;
  final bool isBackground;
  final PreferredSizeWidget? bottom; // ✅ added field
  final TextStyle? titleTextStyle;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      automaticallyImplyLeading: isLeading,
      leading: isLeading
          ? Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: leadingImage != null
                  ? GestureDetector(
                      onTap: backTap,
                      child: CircleAvatar(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        backgroundImage: AssetImage(leadingImage!),
                        radius: leadingHeight ?? 18,
                      ),
                    )
                  : IconButton(
                      onPressed: backTap,
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: AppColors.black131313,
                      ),
                    ),
            )
          : null,
      backgroundColor: backgroundColor ?? Colors.white,
      centerTitle: centerTitle,
      title:
          titleWidget ??
          Text(
            title ?? "",
            style:
                titleTextStyle ??
                AppTextStyles.size20SemiBold.copyWith(
                  color: textColor ?? Color(0xff222222),
                ),
          ),
      scrolledUnderElevation: 0,
      actions: actions,
      bottom: bottom, // ✅ keep bottom here
    );
  }
}
