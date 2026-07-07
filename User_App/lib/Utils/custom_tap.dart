import 'package:flutter/material.dart';

class CustomTap extends StatelessWidget {
  const CustomTap({super.key, this.child, this.onTap, this.behavior});
  final Widget? child;
  final void Function()? onTap;
  final HitTestBehavior? behavior;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: behavior,
      onTap: onTap,
      child: child,
    );
  }
}
