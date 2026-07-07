import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:resqbox_user/Utils/custom_gradient.dart';
import 'package:resqbox_user/main.dart';

import 'colors.dart';
import 'custom_padding.dart';
import 'customtext.dart';

class CustomDialogue {
  Future showMyDialog({
    List<Widget>? actions,
    Widget? title,
    Widget? content,
    Color? barrierColor,
    ShapeBorder? shape,
  }) async {
    return showDialog<void>(
      context: navigatorKey.currentContext!,
      barrierDismissible: true, // user must tap button!
      barrierColor: barrierColor ?? const Color(0XFF191919).withOpacity(.45),

      builder: (BuildContext context) {
        return Dialog(
          surfaceTintColor: AppColors.tWhiteColor,
          backgroundColor: AppColors.tWhiteColor,
          shape: shape ??
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          insetPadding: EdgeInsets.zero,
          child: SizedBox(width: .9, child: content!),
        );
      },
    );
  }

  Future permissionDialogue({
    String? title,
    String? content,
    String? positiveButtonText,
    String? negativeButtonText,
    void Function()? onPositiveTap,
    void Function()? onNegativeTap,
  }) {
    return CustomDialogue().showMyDialog(
      content: CustomPadding(
        horizontal: .02,
        vertical: .015,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(
              text: title ?? 'Exit',
              fontSize: .025,
              fontWeight: FontWeight.w700,
            ),
            CustomPadding(
              vertical: .02,
              child: CustomText(
                text: content ?? 'Are you sure you want to\nexit from the app?',
                fontSize: .02,
                textAlign: TextAlign.center,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: CustomGradientElevatedButton(
                    onPressed: onNegativeTap ??
                        () async {
                          // Navigator.pop();
                          // NavigateToPage.pop(navigatorKey.currentContext!);
                        },
                    text: negativeButtonText ?? 'No',
                    isGradient: false,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                // const CustomSizedBox(width: .015),
                Flexible(
                  child: CustomGradientElevatedButton(
                    onPressed: onPositiveTap ??
                        () async {
                          SystemNavigator.pop(animated: true);
                        },
                    text: positiveButtonText ?? 'Yes',
                    isGradient: true,
                    gradientColors: const [
                      AppColors.tPrimaryColor,
                      AppColors.tWhiteColor
                    ],
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
