import 'package:flutter/material.dart';
import 'package:resqboxvendor/Utils/mediaquery.dart';

class VerticalDottedLine extends StatelessWidget {
  final double height;
  final Color color;

  const VerticalDottedLine({
    this.height = 100,
    this.color = Colors.black,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _VerticalDottedLinePainter(color: color),
      child: SizedBox(
        width: Sizes.width * .25, // Line thickness
        height: height,
      ),
    );
  }
}

class _VerticalDottedLinePainter extends CustomPainter {
  final Color color;

  _VerticalDottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    double startY = 0;
    const dashHeight = 5;
    const dashSpace = 3;

    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
