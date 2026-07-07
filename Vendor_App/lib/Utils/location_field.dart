import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:resqboxvendor/Utils/colors.dart';
import 'package:resqboxvendor/Utils/mediaquery.dart';

class LocationField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final Widget? prefixImage;
  final Widget? suffixImage;
  final TextInputType keyboardType;
  final bool isRequired;

  // Validation options
  final bool isEmail;
  final bool isPincode;
  final bool isContactNumber;
  final bool isGstNumber;
  final bool isName;
  final bool isEditable;

  final int? maxLength;
  final bool isAddress;
  final bool editAddressGst;
  final bool isPanCard;
  final bool isAadhaarCard;
  final bool isPrice;
  final bool isQuantity;

  const LocationField({
    super.key,
    this.controller,
    this.hintText,
    this.prefixImage,
    this.suffixImage,
    this.keyboardType = TextInputType.text,
    this.isRequired = false,
    this.isEmail = false,
    this.isPincode = false,
    this.isContactNumber = false,
    this.isGstNumber = false,
    this.isName = false,
    this.isEditable = true,
    this.maxLength,
    this.isAddress = false,
    this.editAddressGst = false,
    this.isPanCard = false,
    this.isAadhaarCard = false,
    this.isPrice = false,
    this.isQuantity = false,
  });

  String? _validate(String? value) {
    final trimmedValue = value?.trim() ?? '';

    if (isRequired && trimmedValue.isEmpty) {
      return 'Please enter ${hintText?.toLowerCase() ?? 'this field'}';
    }

    if (isEmail && trimmedValue.isNotEmpty) {
      // Ensure only one @ symbol exists
      if (trimmedValue.split('@').length != 2) {
        return 'Enter a valid email address';
      }
      final emailRegex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      );
      if (!emailRegex.hasMatch(trimmedValue))
        return 'Enter a valid email address';
    } else if (isEmail && value!.isEmpty) {
      return "Please $hintText";
    }

    if (isPincode && trimmedValue.isNotEmpty) {
      final pincodeRegex = RegExp(r'^\d{6}$');
      if (!pincodeRegex.hasMatch(trimmedValue)) {
        return 'Enter a valid 6-digit pincode';
      }
    } else if (isPincode && value!.isEmpty) {
      return "Please $hintText";
    }

    if (isContactNumber && trimmedValue.isNotEmpty) {
      final contactRegex = RegExp(r'^[6-9]\d{9}$');
      if (!contactRegex.hasMatch(trimmedValue))
        return 'Enter a valid 10-digit number';
    } else if (isContactNumber && value!.isEmpty) {
      return "Please ${hintText}";
    }
    if (!editAddressGst) {
      if (isGstNumber && trimmedValue.isNotEmpty) {
        final gstRegex = RegExp(
          r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$',
        );
        if (!gstRegex.hasMatch(trimmedValue)) return 'Enter a valid GST number';
      } else if (isGstNumber && value!.isEmpty) {
        return "Please ${hintText}";
      }
    }
    if (isPanCard && trimmedValue.isNotEmpty) {
      final panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
      if (!panRegex.hasMatch(trimmedValue)) {
        return 'Enter a valid PAN card number';
      }
    } else if (isPanCard && value!.isEmpty) {
      return "Please enter your PAN card number";
    }

    if (isAadhaarCard && trimmedValue.isNotEmpty) {
      final aadhaarRegex = RegExp(r'^\d{12}$');
      if (!aadhaarRegex.hasMatch(trimmedValue)) {
        return 'Enter a valid Aadhaar card number';
      }
    } else if (isAadhaarCard && value!.isEmpty) {
      return "Please enter your Aadhaar card number";
    }

    // if (isGstNumber && trimmedValue.isNotEmpty) {
    //   final gstRegex =
    //       RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');
    //   if (!gstRegex.hasMatch(trimmedValue)) return 'Enter a valid GST number';
    // } else if (isGstNumber && value!.isEmpty) {
    //   return "Please ${hintText}";
    // }

    // if (isName && trimmedValue.isNotEmpty) {
    //   final nameRegex = RegExp(r"^[a-zA-Z\s]{2,}$");
    //   if (!nameRegex.hasMatch(trimmedValue)) return 'Enter a valid name';
    // } else if (isName && value!.isEmpty) {
    //   return "Please ${hintText}";
    // }
    if (isName && trimmedValue.isNotEmpty) {
      final nameRegex = RegExp(r"^[\p{L}].*$", unicode: true);
      if (!nameRegex.hasMatch(trimmedValue)) {
        return 'Name must start with a letter';
      }
    } else if (isName && value!.isEmpty) {
      return "Please $hintText";
    }

    if (isAddress && value != null && value.trim().isEmpty) {
      return "Please ${hintText}";
    }
    if (isPrice && trimmedValue.isNotEmpty) {
      final priceRegex = RegExp(r'^\d+(\.\d{1,2})?$');
      if (!priceRegex.hasMatch(trimmedValue)) {
        return 'Enter a valid price (e.g. 99 or 99.99)';
      }
    } else if (isPrice && value!.isEmpty) {
      return "Please enter the price";
    }

    if (isQuantity && trimmedValue.isNotEmpty) {
      final quantityRegex = RegExp(
        r'^\d+(\.\d+)?\s?(kg|kgs|g|gm|gms|grams|gram)$',
        caseSensitive: false,
      );
      if (!quantityRegex.hasMatch(trimmedValue)) {
        return 'Enter a valid quantity (e.g., 1kg, 500gms)';
      }
    } else if (isQuantity && value!.isEmpty) {
      return "Please enter the quantity";
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: GoogleFonts.roboto(
        fontSize: Sizes.height * 0.018,
        fontWeight: FontWeight.w500,
        color: AppColors.blackText,
      ),
      maxLength: maxLength ?? (isContactNumber ? 10 : null),
      readOnly: !isEditable,
      keyboardType: _getKeyboardType(),
      inputFormatters: isPanCard
          ? [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
              UpperCaseTextFormatter(),
            ]
          : null,
      textCapitalization: isPanCard
          ? TextCapitalization.characters
          : TextCapitalization.none,
      decoration: InputDecoration(
        fillColor: const Color(0XFFF9F9F9),
        filled: false,
        hintText: hintText,
        floatingLabelBehavior: FloatingLabelBehavior.never,
        labelStyle: GoogleFonts.roboto(
          fontSize: Sizes.height * 0.018,
          fontWeight: FontWeight.w500,
          color: AppColors.blackText,
        ),
        hintStyle: GoogleFonts.roboto(
          fontSize: Sizes.height * 0.016,
          fontWeight: FontWeight.w400,
          color: const Color(0XFF727272),
        ),
        errorStyle: GoogleFonts.roboto(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.red,
        ),
        contentPadding: const EdgeInsets.all(15),
        counterText: '',
        prefixIcon: prefixImage != null
            ? Padding(padding: const EdgeInsets.all(12.0), child: prefixImage)
            : null,
        suffixIcon: suffixImage != null
            ? Padding(padding: const EdgeInsets.all(12.0), child: suffixImage)
            : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0XFFB4B4B4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0XFFB4B4B4)),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0XFFB4B4B4)),
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
      validator: _validate,
    );
  }

  TextInputType _getKeyboardType() {
    if (isEmail) return TextInputType.emailAddress;
    if (isContactNumber || isPincode || isAadhaarCard) {
      return TextInputType.number;
    }
    if (isAddress) return TextInputType.multiline;
    return keyboardType;
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
