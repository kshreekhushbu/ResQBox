import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';
import 'mediaquery.dart';

class CustomText extends StatelessWidget {
  const CustomText({
    super.key,
    required this.text,
    this.color,
    this.fontSize,
    this.maxLines,
    this.decorationColor,
    this.fontWeight,
    this.overflow,
    this.letterSpacing,
    this.decoration,
    this.textAlign,
    this.decorationStyle,
    this.decorationThickness,
    this.shadows,
    this.decorationHeight,
  });
  final String text;
  final Color? color;
  final Color? decorationColor;
  final double? fontSize;
  final int? maxLines;
  final FontWeight? fontWeight;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final TextDecoration? decoration;
  final TextDecorationStyle? decorationStyle;
  final double? decorationThickness;
  final List<Shadow>? shadows;
  final double? decorationHeight;
  final double? letterSpacing;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      style: customTextstyle(
          color: color,
          fontWeight: fontWeight,
          shadows: shadows,
          letterSpacing: letterSpacing,
          decorationStyle: decorationStyle,
          decorationThickness: decorationThickness,
          fontSize: fontSize,
          decorationHeight: decorationHeight,
          decorationColor: decorationColor,
          decoration: decoration),
    );
  }
}

TextStyle customTextstyle(
    {Color? color,
    TextDecoration? decoration,
    double? fontSize,
    double? decorationThickness,
    TextDecorationStyle? decorationStyle,
    Color? decorationColor,
    FontWeight? fontWeight,
    List<Shadow>? shadows,
    double? decorationHeight,
    double? letterSpacing,
    String? fontFamily}) {
  double textSize =
      fontSize != null ? fontSize * Sizes.height : Sizes.height * .019;
  return
      // TextStyle(
      //     fontFamily: 'SFPro',
      //     color: color ?? AppColors.tTextColor,
      //     fontSize: textSize,
      //     fontWeight: fontWeight ?? FontWeight.w600,
      //     decorationColor: decorationColor,
      //     decorationThickness: decorationThickness,
      //     shadows: shadows,
      //     letterSpacing: letterSpacing ?? 0.8,
      //     height: decorationHeight,
      //     decorationStyle: decorationStyle,
      //     decoration: decoration);
      GoogleFonts.roboto(
          color: color ?? AppColors.tBlackColor,
          fontSize: textSize,
          fontWeight: fontWeight ?? FontWeight.w600,
          decorationColor: decorationColor,
          decorationThickness: decorationThickness,
          shadows: shadows,
          letterSpacing: letterSpacing,
          height: decorationHeight,
          decorationStyle: decorationStyle,
          decoration: decoration);
}

TextStyle reusableFontStyle(
    {Color? color,
    TextDecoration? decoration,
    double? fontSize,
    double? decorationThickness,
    TextDecorationStyle? decorationStyle,
    Color? decorationColor,
    FontWeight? fontWeight,
    List<Shadow>? shadows,
    double? decorationHeight,
    double? letterSpacing,
    required String fontFamily}) {
  double textSize =
      fontSize != null ? fontSize * Sizes.height : Sizes.height * .019;
  return GoogleFonts.getFont(fontFamily,
      color: color ?? AppColors.tTextColor,
      fontSize: textSize,
      fontWeight: fontWeight ?? FontWeight.w600,
      decorationColor: decorationColor,
      decorationThickness: decorationThickness,
      shadows: shadows,
      letterSpacing: letterSpacing,
      height: decorationHeight,
      decorationStyle: decorationStyle,
      decoration: decoration);
}

class CustomText2 extends StatelessWidget {
  const CustomText2({
    super.key,
    required this.text,
    this.color,
    this.fontSize,
    this.maxLines,
    this.decorationColor,
    this.fontWeight,
    this.overflow,
    this.letterSpacing,
    this.decoration,
    this.textAlign,
    this.decorationStyle,
    this.decorationThickness,
    this.shadows,
    this.decorationHeight,
  });
  final String text;
  final Color? color;
  final Color? decorationColor;
  final double? fontSize;
  final int? maxLines;
  final FontWeight? fontWeight;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final TextDecoration? decoration;
  final TextDecorationStyle? decorationStyle;
  final double? decorationThickness;
  final List<Shadow>? shadows;
  final double? decorationHeight;
  final double? letterSpacing;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      style: customTextstyle2(
          color: color,
          fontWeight: fontWeight,
          shadows: shadows,
          letterSpacing: letterSpacing,
          decorationStyle: decorationStyle,
          decorationThickness: decorationThickness,
          fontSize: fontSize,
          decorationHeight: decorationHeight,
          decorationColor: decorationColor,
          decoration: decoration),
    );
  }
}

TextStyle customTextstyle2(
    {Color? color,
    TextDecoration? decoration,
    double? fontSize,
    double? decorationThickness,
    TextDecorationStyle? decorationStyle,
    Color? decorationColor,
    FontWeight? fontWeight,
    List<Shadow>? shadows,
    double? decorationHeight,
    double? letterSpacing,
    String? fontFamily}) {
  double textSize =
      fontSize != null ? fontSize * Sizes.height : Sizes.height * .019;
  return GoogleFonts.lato(
      color: color ?? AppColors.tTextColor,
      fontSize: textSize,
      fontWeight: fontWeight ?? FontWeight.w600,
      decorationColor: decorationColor,
      decorationThickness: decorationThickness,
      shadows: shadows,
      letterSpacing: letterSpacing,
      height: decorationHeight,
      decorationStyle: decorationStyle,
      decoration: decoration);
}

TextStyle reusableFontStyle2(
    {Color? color,
    TextDecoration? decoration,
    double? fontSize,
    double? decorationThickness,
    TextDecorationStyle? decorationStyle,
    Color? decorationColor,
    FontWeight? fontWeight,
    List<Shadow>? shadows,
    double? decorationHeight,
    double? letterSpacing,
    required String fontFamily}) {
  double textSize =
      fontSize != null ? fontSize * Sizes.height : Sizes.height * .019;
  return GoogleFonts.getFont(fontFamily,
      color: color ?? AppColors.tTextColor,
      fontSize: textSize,
      fontWeight: fontWeight ?? FontWeight.w600,
      decorationColor: decorationColor,
      decorationThickness: decorationThickness,
      shadows: shadows,
      letterSpacing: letterSpacing,
      height: decorationHeight,
      decorationStyle: decorationStyle,
      decoration: decoration);
}
