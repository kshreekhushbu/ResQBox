import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class ScrollHideWidget extends StatefulWidget {
  final Widget child;
  final ValueNotifier<bool> hideNotifier;
  final ValueNotifier<bool>? hideAppBarNotifier;

  const ScrollHideWidget({
    super.key,
    required this.child,
    required this.hideNotifier,
    this.hideAppBarNotifier,
  });

  @override
  State<ScrollHideWidget> createState() => _ScrollHideWidgetState();
}

class _ScrollHideWidgetState extends State<ScrollHideWidget> {
  @override
  Widget build(BuildContext context) {
    // Use NotificationListener to detect scroll direction
    return NotificationListener<UserScrollNotification>(
      onNotification: (notification) {
        if (notification.direction == ScrollDirection.reverse) {
          widget.hideNotifier.value = true; // hide bottom nav
          widget.hideAppBarNotifier?.value = true; // hide app bar
        } else if (notification.direction == ScrollDirection.forward) {
          widget.hideNotifier.value = false; // show bottom nav
          widget.hideAppBarNotifier?.value = false; // show app bar
        }
        return false;
      },
      child: widget.child,
    );
  }
}
