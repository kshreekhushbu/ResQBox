import 'package:flutter/material.dart';

import 'customtext.dart';

class ErrorText extends StatelessWidget {
  const ErrorText({super.key, required this.text, this.fontSize, this.onTap});
  final String text;
  final double? fontSize;
  final void Function()? onTap;
  @override
  Widget build(BuildContext context) {
    return CustomText(
      text: text,
      fontSize: fontSize ?? .025,
      textAlign: TextAlign.center,
    );
  }
}
