import 'package:flutter/cupertino.dart';
import 'package:resqbox_user/Utils/colors.dart';
import 'package:resqbox_user/Utils/customtext.dart';

Future<bool?> showAlertDialog({
  required BuildContext context,
  String? title,
  String? content,
  void Function()? onPressed,
}) {
  return showCupertinoModalPopup<bool>(
    context: context,
    builder: (BuildContext context) => CupertinoAlertDialog(
      title: CustomText(
        text: title ?? 'Log Out',
        color: AppColors.red,
      ),
      content: CustomText(
        text: content ?? 'Are You Sure, You Want To Logout From App??',
        fontWeight: FontWeight.w500,
      ),
      actions: <CupertinoDialogAction>[
        CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const CustomText(
              text: 'No',
              color: AppColors.red,
            )),
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () {
            if (onPressed != null) {
              Navigator.pop(context, true);
              onPressed();
            } else {
              Navigator.pop(context, true);
            }
          },
          child: const CustomText(
            text: 'Yes',
            color: AppColors.green,
          ),
        ),
      ],
    ),
  );
}
