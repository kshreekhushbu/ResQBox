import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class StarClass extends StatelessWidget {
  const StarClass({
    super.key,
    required this.starNumber,
    required this.rating,
    this.starColor = const Color(0XFFEDD119),
    this.starSize = 14.0,
  });

  final int starNumber;
  final double rating;
  final Color starColor;
  final double starSize;

  @override
  Widget build(BuildContext context) {
    if (rating >= 1.0) {
      // Full star
      return Icon(
        Icons.star,
        color: starColor,
        size: starSize,
      );
    } else if (rating > 0.0) {
      // Half star
      return Stack(
        children: [
          Icon(
            Icons.star_border,
            color: starColor,
            size: starSize,
          ),
          ClipRect(
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: rating,
              child: Icon(
                Icons.star,
                color: starColor,
                size: starSize + 2, // Slightly larger for better visual effect
              ),
            ),
          ),
        ],
      );
    } else {
      // Empty star
      return Icon(
        Icons.star_border,
        color: starColor,
        size: starSize,
      );
    }
  }
}
