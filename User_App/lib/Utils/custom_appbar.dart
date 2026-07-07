import 'package:flutter/material.dart';
import 'package:resqbox_user/Utils/custom_tap.dart';

import 'colors.dart';
import 'customtext.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  const CustomAppBar(
      {super.key,
      required this.title,
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
      this.isBackButton,
      this.backButtonColor});
  final String title;
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
  final bool? isBackButton;
  final Color? backButtonColor;
  @override
  Widget build(BuildContext context) {
    return PreferredSize(
        preferredSize: const Size.fromHeight(62.0), // Adjust height as needed
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.tWhiteColor,
            // boxShadow: [
            //   BoxShadow(
            //       color: const Color(0XFF797979).withOpacity(.2),
            //       blurRadius: 4,
            //       spreadRadius: 0,
            //       offset: const Offset(0, 2))
            // ],
          ),
          child: AppBar(
            backgroundColor: backgroundColor,
            elevation: 0,
            centerTitle: true,
            automaticallyImplyLeading: false,
            leading: isBackButton == false
                ? SizedBox.shrink()
                : CustomTap(
                    onTap: backTap,
                    child: IconButton(
                        onPressed: backTap,
                        icon: Icon(
                          Icons.arrow_back_ios,
                          color: backButtonColor ?? AppColors.tTextColor,
                          size: 24,
                        )),
                  ),
            title: titleWidget ??
                CustomText(
                  text: title,
                  color: textColor ?? AppColors.tTextColor,
                  fontWeight: FontWeight.w600,
                  fontSize: .022,
                ),
            scrolledUnderElevation: 0,
            actions: actions,
          ),
        ));
  }
}
