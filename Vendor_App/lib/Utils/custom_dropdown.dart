import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:resqboxvendor/Utils/mediaquery.dart';

class CustomDropdownField<T> extends StatelessWidget {
  final String? hintText;
  final String? label;
  final bool isfilled;
  final bool isRequired;
  final String? errorText;
  final List<T>? items;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final String Function(T)? itemLabelBuilder;
  final bool isEditable;

  const CustomDropdownField({
    super.key,
    this.hintText,
    this.label,
    this.isfilled = false,
    this.isRequired = false,
    this.errorText,
    this.items,
    this.value,
    this.onChanged,
    this.itemLabelBuilder,
    this.isEditable = true,
  });

  @override
  Widget build(BuildContext context) {
    final dropdownItems = (items ?? [])
        .map(
          (e) => DropdownMenuItem<T>(
            value: e,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              itemLabelBuilder != null ? itemLabelBuilder!(e) : e.toString(),
              style: GoogleFonts.roboto(
                fontSize: Sizes.height * 0.018,
                fontWeight: FontWeight.w500,
                color: const Color(0XFF777777),
              ),
            ),
          ),
        )
        .toList();

    return IgnorePointer(
      ignoring: !isEditable,
      child: DropdownButtonFormField<T>(
        value: value,
        isExpanded: true,
        items: dropdownItems.isEmpty ? null : dropdownItems,
        onChanged: onChanged,
        validator: (val) {
          if (isRequired && val == null) {
            return errorText ?? 'This field is required';
          }
          return null;
        },
        style: GoogleFonts.roboto(
          fontSize: Sizes.height * 0.016,
          fontWeight: FontWeight.w400,
          color: const Color(0XFF777777),
        ),
        decoration: InputDecoration(
          isDense: true,
          filled: isfilled,
          fillColor: const Color(0xffF9F9F9),
          floatingLabelBehavior: FloatingLabelBehavior.never,
          labelText: label,
          labelStyle: GoogleFonts.roboto(
            fontSize: Sizes.height * 0.016,
            fontWeight: FontWeight.w500,
            color: const Color(0XFF777777),
          ),
          hintText: hintText,
          hintStyle: GoogleFonts.roboto(
            fontSize: Sizes.height * 0.015,
            fontWeight: FontWeight.w400,
            color: const Color(0xff707070),
          ),
          errorStyle: GoogleFonts.roboto(
            fontSize: Sizes.height * 0.014,
            fontWeight: FontWeight.w500,
            color: Colors.red,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: Sizes.height * 0.015,
            vertical: Sizes.height * 0.015,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xffD9D8DD)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xffD9D8DD)),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red),
          ),
        ),

        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: Color(0xffEB7712),
        ),
        dropdownColor: Colors.white,
      ),
    );
  }
}
