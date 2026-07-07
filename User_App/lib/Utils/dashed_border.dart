// // import 'dart:ui';

// import 'package:flutter/material.dart';

// class DashedBorderPainter extends CustomPainter {
//   final Color color;
//   final double dashWidth;
//   final double dashSpace;

//   DashedBorderPainter({
//     required this.color,
//     this.dashWidth = 5,
//     this.dashSpace = 3,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = color
//       ..strokeWidth = 2
//       ..style = PaintingStyle.stroke;

//     final Path path = Path();
//     path.addRRect(
//       RRect.fromRectAndRadius(
//         Rect.fromLTWH(0, 0, size.width, size.height),
//         Radius.circular(8),
//       ),
//     );

//     Path dashedPath = Path();
//     for (PathMetric metric in path.computeMetrics()) {
//       double distance = 0.0;
//       while (distance < metric.length) {
//         final segment = metric.extractPath(distance, distance + dashWidth);
//         dashedPath.addPath(segment, Offset.zero);
//         distance += dashWidth + dashSpace;
//       }
//     }

//     canvas.drawPath(dashedPath, paint);
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }
