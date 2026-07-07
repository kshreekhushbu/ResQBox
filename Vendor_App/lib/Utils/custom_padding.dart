import 'package:flutter/material.dart';

import 'mediaquery.dart';

class CustomPadding extends StatelessWidget {
  const CustomPadding(
      {super.key,
      this.child,
      this.horizontal,
      this.vertical,
      this.top,
      this.bottom,
      this.isDefaultHorizontalPadding = false,
      this.left,
      this.right});
  final Widget? child;
  final double? horizontal;
  final double? vertical;
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final bool isDefaultHorizontalPadding;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          horizontal != null || vertical != null || isDefaultHorizontalPadding
              ? EdgeInsets.symmetric(
                  horizontal: isDefaultHorizontalPadding
                      ? Sizes.width * Sizes.horizontalPadding
                      : horizontal != null
                          ? Sizes.width * horizontal!
                          : 0,
                  vertical: vertical != null ? Sizes.height * vertical! : 0)
              : EdgeInsets.only(
                  top: top != null ? Sizes.height * top! : 0,
                  bottom: bottom != null ? Sizes.height * bottom! : 0,
                  left: left != null ? Sizes.width * left! : 0,
                  right: right != null ? Sizes.width * right! : 0,
                ),
      child: child,
    );
  }
}
