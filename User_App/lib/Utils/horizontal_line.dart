import 'package:flutter/material.dart';
import 'package:resqbox_user/Utils/mediaquery.dart';

class HorizontalDottedLine extends StatelessWidget {
  final double width;
  final Color color;

  const HorizontalDottedLine({
    this.width = 100,
    this.color = Colors.black,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HorizontalDottedLinePainter(color: color),
      child: SizedBox(
        width: width,
        height: Sizes.height * 0.005, // Line thickness
      ),
    );
  }
}

class _HorizontalDottedLinePainter extends CustomPainter {
  final Color color;

  _HorizontalDottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    double startX = 0;
    const dashWidth = 3;
    const dashSpace = 2;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
