import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:resqboxvendor/Utils/colors.dart';

class AppTextStyles {
  static const double size10 = 10;
  static const double size12 = 12;
  static const double size14 = 14;
  static const double size16 = 16;
  static const double size18 = 18;
  static const double size20 = 20;
  static const double size24 = 24;
  static const double size28 = 28;
  static const double size32 = 32;
  static const double size42 = 42;

  // static const double size10 = 9;
  // static const double size12 = 11;
  // static const double size14 = 13;
  // static const double size16 = 15;
  // static const double size18 = 17;
  // static const double size20 = 19;
  // static const double size24 = 23;
  // static const double size28 = 27;
  // static const double size32 = 31;
  // static const double size42 = 41;

  // === Size 10 ===
  static TextStyle get size10Regular =>
      GoogleFonts.roboto(fontSize: size10, fontWeight: FontWeight.w400);
  static TextStyle get size10Medium =>
      GoogleFonts.roboto(fontSize: size10, fontWeight: FontWeight.w500);
  static TextStyle get size10SemiBold =>
      GoogleFonts.roboto(fontSize: size10, fontWeight: FontWeight.w600);
  static TextStyle get size10Bold =>
      GoogleFonts.roboto(fontSize: size10, fontWeight: FontWeight.w700);

  // === Size 12 ===
  static TextStyle get size12Regular =>
      GoogleFonts.roboto(fontSize: size12, fontWeight: FontWeight.w400);
  static TextStyle get size12Medium =>
      GoogleFonts.roboto(fontSize: size12, fontWeight: FontWeight.w500);
  static TextStyle get size12SemiBold =>
      GoogleFonts.roboto(fontSize: size12, fontWeight: FontWeight.w600);
  static TextStyle get size12Bold =>
      GoogleFonts.roboto(fontSize: size12, fontWeight: FontWeight.w700);

  // === Size 14 ===
  static TextStyle get size14Regular =>
      GoogleFonts.roboto(fontSize: size14, fontWeight: FontWeight.w400);
  static TextStyle get size14Medium => GoogleFonts.roboto(
    fontSize: size14,
    fontWeight: FontWeight.w500,
    color: const Color(0xff1C1B29),
  );
  static TextStyle get size14SemiBold =>
      GoogleFonts.roboto(fontSize: size14, fontWeight: FontWeight.w600);
  static TextStyle get size14Bold =>
      GoogleFonts.roboto(fontSize: size14, fontWeight: FontWeight.w700);

  // === Size 16 ===
  static TextStyle get size16Regular =>
      GoogleFonts.roboto(fontSize: size16, fontWeight: FontWeight.w400);
  static TextStyle get size16Medium => GoogleFonts.roboto(
    fontSize: size16,
    fontWeight: FontWeight.w500,
    color: const Color(0xff707070),
  );
  static TextStyle get size16SemiBold =>
      GoogleFonts.roboto(fontSize: size16, fontWeight: FontWeight.w600);
  static TextStyle get size16Bold =>
      GoogleFonts.roboto(fontSize: size16, fontWeight: FontWeight.w700);

  // === Size 18 ===
  static TextStyle get size18Regular =>
      GoogleFonts.roboto(fontSize: size18, fontWeight: FontWeight.w400);
  static TextStyle get size18Medium =>
      GoogleFonts.roboto(fontSize: size18, fontWeight: FontWeight.w500);
  static TextStyle get size18SemiBold =>
      GoogleFonts.roboto(fontSize: size18, fontWeight: FontWeight.w600);
  static TextStyle get size18Bold =>
      GoogleFonts.roboto(fontSize: size18, fontWeight: FontWeight.w700);

  // === Size 20 ===
  static TextStyle get size20Regular =>
      GoogleFonts.roboto(fontSize: size20, fontWeight: FontWeight.w400);
  static TextStyle get size20Medium =>
      GoogleFonts.roboto(fontSize: size20, fontWeight: FontWeight.w500);
  static TextStyle get size20SemiBold =>
      GoogleFonts.roboto(fontSize: size20, fontWeight: FontWeight.w600);
  static TextStyle get size20Bold =>
      GoogleFonts.roboto(fontSize: size20, fontWeight: FontWeight.w700);

  // === Size 24 ===
  static TextStyle get size24Regular =>
      GoogleFonts.roboto(fontSize: size24, fontWeight: FontWeight.w400);
  static TextStyle get size24Medium =>
      GoogleFonts.roboto(fontSize: size24, fontWeight: FontWeight.w500);
  static TextStyle get size24SemiBold =>
      GoogleFonts.roboto(fontSize: size24, fontWeight: FontWeight.w600);
  static TextStyle get size24Bold =>
      GoogleFonts.roboto(fontSize: size24, fontWeight: FontWeight.w700);

  // === Size 28 ===
  static TextStyle get size28Regular =>
      GoogleFonts.roboto(fontSize: size28, fontWeight: FontWeight.w400);
  static TextStyle get size28Medium =>
      GoogleFonts.roboto(fontSize: size28, fontWeight: FontWeight.w500);
  static TextStyle get size28SemiBold =>
      GoogleFonts.roboto(fontSize: size28, fontWeight: FontWeight.w600);
  static TextStyle get size28Bold =>
      GoogleFonts.roboto(fontSize: size28, fontWeight: FontWeight.w700);

  // === Size 32 ===
  static TextStyle get size32Regular =>
      GoogleFonts.roboto(fontSize: size32, fontWeight: FontWeight.w400);
  static TextStyle get size32Medium =>
      GoogleFonts.roboto(fontSize: size32, fontWeight: FontWeight.w500);
  static TextStyle get size32SemiBold =>
      GoogleFonts.roboto(fontSize: size32, fontWeight: FontWeight.w600);
  static TextStyle get size32Bold =>
      GoogleFonts.roboto(fontSize: size32, fontWeight: FontWeight.w700);

  // === Size 42 ===
  static TextStyle get size42Medium =>
      GoogleFonts.roboto(fontSize: size42, fontWeight: FontWeight.w500);
  static TextStyle get size42SemiBold =>
      GoogleFonts.roboto(fontSize: size42, fontWeight: FontWeight.w600);
  static TextStyle get size42Bold =>
      GoogleFonts.roboto(fontSize: size42, fontWeight: FontWeight.w700);

  // === Custom Styles ===
  static TextStyle get headingLarge => GoogleFonts.roboto(
    fontSize: size42,
    fontWeight: FontWeight.w700,
    color: AppColors.mainAppColr,
  );

  static TextStyle get heading => GoogleFonts.roboto(
    fontSize: size42,
    fontWeight: FontWeight.w700,
    // color: AppColors.mainAppColr,
  );

  static TextStyle get titleRedColor => GoogleFonts.roboto(
    fontSize: size24,
    fontWeight: FontWeight.w700,
    color: AppColors.mainAppColr,
  );

  static TextStyle get title14red => GoogleFonts.roboto(
    fontSize: size14,
    fontWeight: FontWeight.w500,
    color: AppColors.mainAppColr,
  );

  static TextStyle get buttonText => GoogleFonts.roboto(
    fontSize: size16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static TextStyle get caption => GoogleFonts.roboto(
    fontSize: size12,
    fontWeight: FontWeight.w400,
    color: const Color(0xff1C1B29),
  );

  static TextStyle get boldCaption => GoogleFonts.roboto(
    fontSize: size12,
    fontWeight: FontWeight.w700,
    color: const Color(0xffB4BBC6),
  );

  static TextStyle get size14RegularBlue => GoogleFonts.roboto(
    fontSize: size14,
    fontWeight: FontWeight.w400,
    color: const Color(0xff4385E7),
  );
}
