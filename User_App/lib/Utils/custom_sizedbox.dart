import 'package:flutter/material.dart';

import 'mediaquery.dart';

class CustomSizedBox extends StatelessWidget {
  const CustomSizedBox({super.key, this.height, this.width, this.child});
  final double? height;
  final double? width;
  final Widget? child;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height != null ? Sizes.height * height! : null,
      width: width != null ? Sizes.width * width! : null,
      child: child,
    );
  }
}
