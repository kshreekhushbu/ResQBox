import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:resqboxvendor/Utils/colors.dart';
import 'package:resqboxvendor/Utils/custom_padding.dart';
import 'package:resqboxvendor/Utils/custom_sizedbox.dart';
import 'package:resqboxvendor/Utils/mediaquery.dart';

class CustomSearchField extends StatefulWidget {
  final TextEditingController controller;
  final String searchIconPath;
  final String hintText;
  final ValueChanged<String>? onChanged;

  const CustomSearchField({
    super.key,
    required this.controller,
    required this.searchIconPath,
    this.hintText = 'Search...',
    this.onChanged,
  });

  @override
  State<CustomSearchField> createState() => _CustomSearchFieldState();
}

class _CustomSearchFieldState extends State<CustomSearchField> {
  @override
  Widget build(BuildContext context) {
    return CustomSizedBox(
      width: .7,
      height: .06,
      child: TextField(
        controller: widget.controller,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: GoogleFonts.roboto(
            fontSize: Sizes.height * 0.016,
            color: AppColors.yash7070707,
            fontWeight: FontWeight.w500,
          ),
          fillColor: AppColors.tWhiteColor,
          filled: true,
          prefixIcon: CustomPadding(
            vertical: 0.01,
            child: Image.asset(
              widget.searchIconPath,
              height: Sizes.height * 0.016,
              color: AppColors.yash7070707,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: const BorderSide(color: Color(0XFFE0E2E7)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: const BorderSide(color: Color(0XFFE0E2E7)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: const BorderSide(color: Color(0XFFE0E2E7)),
          ),
        ),
      ),
    );
  }
}
