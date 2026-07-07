import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NoDataFoundWidget extends StatelessWidget {
  final String img;
  final String title;
  final String description;
  final double? imgWidth;
  final double? imgHeight;

  const NoDataFoundWidget({
    super.key,
    required this.img,
    required this.title,
    required this.description,
    this.imgWidth,
    this.imgHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          img,
          width: imgWidth,
          height: imgHeight,
          fit: BoxFit.contain,
        ),
        Text(
          title,
          style: GoogleFonts.roboto(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            description,
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF5D5D5D),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
