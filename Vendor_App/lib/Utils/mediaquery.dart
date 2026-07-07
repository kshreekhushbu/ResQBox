import 'package:flutter/material.dart';

class Sizes {
  static void init(BuildContext context) {
    //instantiate variables here
    _mediaQueryData = MediaQuery.sizeOf(context);
    width = _mediaQueryData.width;
    height = _mediaQueryData.height;
  }

  //declare variables here
  static late Size _mediaQueryData;
  static double width = 0;
  static double height = 0;

  // Default Horizontal Padding for entire App
  static double horizontalPadding = .04;
}
