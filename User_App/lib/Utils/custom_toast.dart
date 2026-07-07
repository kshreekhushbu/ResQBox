import 'package:flutter/material.dart';
import 'package:resqbox_user/Utils/colors.dart';
import 'package:resqbox_user/Utils/customtext.dart';
import 'package:resqbox_user/main.dart';
import 'navigations.dart';

class CustomToast {
  void showToast({
    required String? message,
    bool isSuccessToast = false,
  }) {
    ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
      SnackBar(
        backgroundColor: isSuccessToast ? Colors.green : Colors.red,
        content: CustomText(
          text: message ?? '',
          color: AppColors.tWhiteColor,
        ),
      ),
    );
  }
}
