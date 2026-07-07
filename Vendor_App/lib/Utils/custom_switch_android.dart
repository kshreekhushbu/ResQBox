import 'package:flutter/material.dart';
import 'package:resqboxvendor/Utils/colors.dart';

class CustomThumbSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  final Color? activeColor;
  final Color? trackColor;

  final Color? inActiveColor;
  final Color? inActiveTrackColor;

  final BoxBorder? border;

  final double? trackWidth;

  final double? trackHeight;

  final double? thumbSize;

  const CustomThumbSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.trackColor,
    this.inActiveColor,
    this.inActiveTrackColor,
    this.border,
    this.trackWidth,
    this.trackHeight,
    this.thumbSize,
  });

  @override
  State<CustomThumbSwitch> createState() => _CustomThumbSwitchState();
}

class _CustomThumbSwitchState extends State<CustomThumbSwitch>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _thumbPosition;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
      value: widget.value ? 1.0 : 0.0,
    );
    _thumbPosition = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant CustomThumbSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      widget.value ? _controller.forward() : _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    double trackWidth = widget.trackWidth ?? 40;
    double trackHeight = widget.trackHeight ?? 13;
    double thumbSize = widget.thumbSize ?? 21; // Bigger than track height

    return GestureDetector(
      onTap: () => widget.onChanged(!widget.value),
      child: SizedBox(
        width: trackWidth,
        height: thumbSize,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            // Track
            Container(
              width: trackWidth,
              height: trackHeight,
              decoration: BoxDecoration(
                color: widget.value
                    ? widget.trackColor ??
                          AppColors.mainAppColr.withOpacity(0.5)
                    : widget.inActiveTrackColor ?? Color(0xffDDDDDD),
                borderRadius: BorderRadius.circular(trackHeight / 2),
              ),
            ),
            // Thumb
            AnimatedBuilder(
              animation: _thumbPosition,
              builder: (_, __) {
                double dx = _thumbPosition.value * (trackWidth - thumbSize);
                return Positioned(
                  left: dx,
                  child: Container(
                    width: thumbSize,
                    height: thumbSize,
                    decoration: BoxDecoration(
                      border: widget.border,
                      color: widget.value
                          ? widget.activeColor ?? AppColors.mainAppColr
                          : widget.inActiveColor ?? Color(0xff888888),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
