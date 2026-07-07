import 'package:flutter/material.dart';
import 'package:resqboxvendor/Utils/textstyles.dart';

class AccessDeniedDialog {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text("Access Denied", style: AppTextStyles.size20SemiBold),
        content: Text(
          "You don't have access to this feature.",
          style: AppTextStyles.size14Medium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }
}
