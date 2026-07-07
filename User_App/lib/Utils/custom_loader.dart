import 'package:lottie/lottie.dart';
import 'package:flutter/material.dart';
import 'package:resqbox_user/Utils/custom_dialogue.dart';
import 'package:resqbox_user/Utils/mediaquery.dart';
import 'package:resqbox_user/main.dart';

import 'images.dart';

class Loaders {
  static Future<void> showLoadingDialog() async {
    return showDialog<void>(
      context: navigatorKey.currentContext!,
      barrierDismissible: false,
      useRootNavigator: true, // 👈 important!
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
          },
          child: SizedBox(
            height: Sizes.height,
            width: Sizes.width,
            child: SimpleDialog(
              elevation: 0.0,
              backgroundColor: Colors.transparent,
              children: <Widget>[
                Center(
                  child: Lottie.asset(
                    AnimationImages.load,
                    height: Sizes.height * .5,
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  static void hideLoadingDialog() {
    if (navigatorKey.currentContext != null &&
        Navigator.of(navigatorKey.currentContext!, rootNavigator: true)
            .canPop()) {
      Navigator.of(navigatorKey.currentContext!, rootNavigator: true).pop();
    }
  }
}
