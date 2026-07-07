import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:resqboxvendor/Controller/AuthController.dart';
import 'package:resqboxvendor/Screens/Auth/login_screen.dart';
import 'package:resqboxvendor/Utils/colors.dart';
import 'package:resqboxvendor/Utils/navigations.dart';
import 'package:resqboxvendor/Utils/shared_preference_helper.dart';
import 'package:resqboxvendor/Utils/textstyles.dart';

Future showAlertDialog({
  required BuildContext context,
  String? title,
  String? content,
  void Function()? onPressed,
}) {
  return showCupertinoModalPopup<void>(
    context: context,
    builder: (BuildContext context) => CupertinoAlertDialog(
      title: Text(
        title ?? 'Log Out',
        style: AppTextStyles.size14Medium.copyWith(
          color: AppColors.mainAppColr,
        ),
      ),
      content: Text(
        content ?? 'Are You Sure, You Want To Logout From App??',
        style: AppTextStyles.size14Medium,
      ),
      actions: <CupertinoDialogAction>[
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () {
            Navigator.pop(context, false);
          },
          child: Text(
            "No",
            style: AppTextStyles.size14Regular.copyWith(
              color: AppColors.mainAppColr,
            ),
          ),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed:
              onPressed ??
              () async {
                Navigator.pop(context, true);

                try {
                  final authController = Provider.of<AuthController>(
                    context,
                    listen: false,
                  );
                  await authController.logout(context);
                } catch (e) {
                  debugPrint("Error accessing AuthController: $e"); 
                  final prefernce = await SharedPreferencesHelper.getInstance();
                  await prefernce.clearAlldata();
                }

                NavigateTo().pushRemove(child: LoginScreen());
              },
          child: Text(
            "Yes",
            style: AppTextStyles.size14Regular.copyWith(
              color: AppColors.green26A860,
            ),
          ),
        ),
      ],
    ),
  );
}
