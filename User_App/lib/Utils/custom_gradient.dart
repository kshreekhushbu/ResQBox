import 'package:flutter/material.dart';

class CustomGradientElevatedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool isGradient;
  final Color? color;
  final List<Color>? gradientColors;

  const CustomGradientElevatedButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.isGradient = true,
    this.color,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: isGradient
            ? LinearGradient(
                colors: gradientColors ?? [Colors.blue, Colors.blueAccent],
              )
            : null,
        color: isGradient ? null : color ?? Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isGradient ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}
