import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:resqboxvendor/Utils/mediaquery.dart';

class CustomTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String image;
  final String? hintText;
  final String? label;
  final String? errorText;
  final bool isRequired;
  final bool isfilled;
  final int? maxLength;
  final int? maxlines;
  final int? minlines;
  final TextCapitalization? textCapitalization;
  final bool isEmail;
  final bool isMobile;
  final bool isAmount;
  final bool isFullName;
  final bool isEditable;
  final String suffixImg;
  final Widget? suffixIcon;
  final bool isGST;
  final bool isPincode;
  final TextStyle? textStyle;
  final bool isHouseNumber;
  final bool isFloorNumber;
  final bool isLandmark;
  final bool isApartment;
  final bool isContactNumber;
  final bool isNumeric; // Added isNumeric property
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final bool showClearButton; // Show clear button when text is not empty
  final VoidCallback? onClear; // Callback when clear button is pressed
  final bool obscureText;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;

  const CustomTextFormField({
    super.key,
    required this.controller,
    this.image = '',
    this.onTap,
    this.onChanged,
    this.hintText,
    this.label,
    this.isfilled = false,
    this.errorText,
    this.isRequired = false,
    this.maxLength,
    this.isAmount = false,
    this.isEmail = false,
    this.textCapitalization,
    this.isMobile = false,
    this.isFullName = false,
    this.isEditable = true,
    this.suffixImg = '',
    this.suffixIcon,
    this.isGST = false,
    this.isPincode = false,
    this.textStyle,
    this.isHouseNumber = false,
    this.isFloorNumber = false,
    this.isLandmark = false,
    this.isApartment = false,
    this.isContactNumber = false,
    this.isNumeric = false, // Initialize default value
    this.maxlines,
    this.minlines,
    this.showClearButton = false,
    this.onClear,
    this.obscureText = false,
    this.inputFormatters,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      focusNode: focusNode,
      controller: controller,
      obscureText: obscureText,
      onTap: onTap,
      onChanged: onChanged,
      maxLength:
          maxLength ??
          (isMobile
              ? 10
              : isPincode
              ? 4
              : null),
      keyboardType: _getKeyboardType(),
      inputFormatters: [
        ..._getInputFormatters(),
        if (inputFormatters != null) ...inputFormatters!,
      ],
      textCapitalization: textCapitalization ?? TextCapitalization.none,
      maxLines: maxlines ?? 1,
      minLines: minlines ?? 1,
      style:
          textStyle ??
          GoogleFonts.roboto(
            fontSize: Sizes.height * 0.018,
            fontWeight: FontWeight.w500,
            color: const Color(0XFF777777),
          ),
      readOnly: !isEditable,
      decoration: InputDecoration(
        filled: isfilled,
        fillColor: Color(0xffF9F9F9),
        floatingLabelBehavior: FloatingLabelBehavior.never,
        errorText: errorText,
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
        contentPadding: EdgeInsets.all(Sizes.height * 0.012),
        counterText: '',
        suffixIcon: showClearButton && controller.text.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear, size: 20, color: Colors.grey),
                onPressed: () {
                  controller.clear();
                  if (onClear != null) onClear!();
                },
              )
            : suffixImg.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.all(12.0),
                child: Image.asset(suffixImg, height: Sizes.height * 0.025),
              )
            : suffixIcon,

        prefixIcon: image.isEmpty
            ? null
            : Padding(
                padding: const EdgeInsets.all(12.0),
                child: Image.asset(
                  image,
                  height: Sizes.height * 0.032,
                  // height: 24,
                  // color: AppColors.mainAppColr,
                ),
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
      validator: (value) {
        if (isRequired && (value == null || value.trim().isEmpty)) {
          debugPrint("BNVVVVVVVVVVVVVVVVVVV $value");
          if (isMobile) {
            return 'Enter Contact Number';
          }
          return errorText ?? 'This field is required';
        }
        if (isEmail && !_isValidEmail(value!)) {
          return 'Enter a valid email';
        }
        if (isMobile && !_isValidMobile(value!)) {
          return 'Please Enter Valid Contact Number';
        }
        if (isPincode && !_isValidPincode(value!)) {
          return 'Enter a valid pincode';
        }

        if (isFullName && !_isValidFullName(value!)) {
          return 'Enter a valid name';
        }
        if (isAmount && !_isValidAmount(value!)) {
          return 'Enter a Valid Amount';
        }
        if (isGST && !_isValidGST(value!)) {
          return 'Enter a valid GST number';
        }
        if (isHouseNumber && value!.trim().isEmpty) {
          return 'Enter house number';
        }
        if (isFloorNumber && value!.trim().isEmpty) {
          return 'Enter floor number';
        }
        if (isLandmark && value!.trim().isEmpty) {
          return 'Enter landmark';
        }
        if (isApartment && value!.trim().isEmpty) {
          return 'Enter apartment name';
        }
        if (isContactNumber && !_isValidMobile(value!)) {
          return 'Enter a valid contact number';
        }

        return null;
      },
    );
  }

  TextInputType _getKeyboardType() {
    if (isMobile) return TextInputType.phone;
    if (isEmail) return TextInputType.emailAddress;
    if (isAmount) return const TextInputType.numberWithOptions(decimal: true);
    if (isNumeric || isPincode) {
      return TextInputType.number; // Added numeric keyboard type
    }
    return TextInputType.text;
  }

  List<TextInputFormatter> _getInputFormatters() {
    if (isMobile || isNumeric || isPincode) {
      // Added isNumeric to digits only formatter
      return [FilteringTextInputFormatter.digitsOnly];
    } else if (isAmount) {
      return [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))];
    } else if (isFullName) {
      return [FilteringTextInputFormatter.allow(RegExp(r"^[a-zA-Z0-9\s]+$"))];
    } else if (isGST) {
      return [UpperCaseTextFormatter()];
    }
    return [];
  }

  bool _isValidEmail(String value) {
    // Ensure only one @ symbol exists and proper email format
    if (value.split('@').length != 2) return false;
    final regex = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
    return regex.hasMatch(value.trim());
  }

  // bool _isValidMobile(String value) {
  //   return RegExp(r"^[6-9]\d{9}$").hasMatch(value); // Indian mobile format
  // }

  bool _isValidMobile(String value) {
    return RegExp(r"^[0-9]{9,10}$").hasMatch(value);
  }

  // bool _isValidPincode(String value) {
  //   return RegExp(r"^[1-9][0-9]{5}$").hasMatch(value); // Indian pincode
  // }
  bool _isValidPincode(String value) {
    // Australian postcode: exactly 4 digits
    return RegExp(r"^[0-9]{4}$").hasMatch(value);
  }

  bool _isValidAmount(String value) {
    return RegExp(r"^\d*\.?\d+$").hasMatch(value) &&
        (double.tryParse(value) ?? 0) > 0;
  }

  bool _isValidGST(String value) {
    return RegExp(
      r"^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$",
    ).hasMatch(value.trim().toUpperCase());
  }

  bool _isValidFullName(String value) {
    return RegExp(r"^[a-zA-Z\s]+$").hasMatch(value);
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

class CustomTextFormFieldBorder extends StatelessWidget {
  final TextEditingController controller;
  final String image;
  final String? hintText;
  final String? label;
  final String? errorText;
  final bool isRequired;
  final bool isfilled;
  final int? maxLength;
  final int? maxlines;
  final int? minlines;
  final TextCapitalization? textCapitalization;
  final bool isEmail;
  final bool isMobile;
  final bool isAmount;
  final bool isFullName;
  final bool isEditable;
  final String suffixImg;
  final bool isGST;
  final bool isPincode;
  final TextStyle? textStyle;
  final bool isHouseNumber;
  final bool isFloorNumber;
  final bool isLandmark;
  final bool isApartment;
  final bool isContactNumber;
  final bool isNumber; // Added isNumber parameter
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final bool obscureText; // For password fields
  final VoidCallback?
  onSuffixTap; // For suffix icon tap (e.g., toggle password visibility)
  final Widget? suffixIcon;

  const CustomTextFormFieldBorder({
    super.key,
    required this.controller,
    this.image = '',
    this.onTap,
    this.onChanged,
    this.hintText,
    this.label,
    this.isfilled = false,
    this.errorText,
    this.isRequired = false,
    this.maxLength,
    this.isAmount = false,
    this.isEmail = false,
    this.textCapitalization,
    this.isMobile = false,
    this.isFullName = false,
    this.isEditable = true,
    this.suffixImg = '',
    this.isGST = false,
    this.isPincode = false,
    this.textStyle,
    this.isHouseNumber = false,
    this.isFloorNumber = false,
    this.isLandmark = false,
    this.isApartment = false,
    this.isContactNumber = false,
    this.isNumber = false, // Initialize default value
    this.maxlines,
    this.minlines,
    this.obscureText = false,
    this.onSuffixTap,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      onTap: onTap,
      onChanged: onChanged,
      obscureText: obscureText,
      maxLength:
          maxLength ??
          (isMobile
              ? 10
              : isPincode
              ? 4
              : null), // Mobile max length 10
      keyboardType: _getKeyboardType(), // Corrected dynamic keyboard type
      inputFormatters: _getInputFormatters(),
      textCapitalization: textCapitalization ?? TextCapitalization.none,
      maxLines: maxlines ?? 1,
      minLines: minlines ?? 1,
      style:
          textStyle ??
          GoogleFonts.roboto(
            fontSize: Sizes.height * 0.018,
            fontWeight: FontWeight.w500,
            color: const Color(0XFF777777),
          ),
      readOnly: !isEditable,
      decoration: InputDecoration(
        filled: isfilled,
        fillColor: Color(0xffF9F9F9),
        floatingLabelBehavior: FloatingLabelBehavior.never,
        labelText: label,
        labelStyle: GoogleFonts.roboto(
          fontSize: Sizes.height * 0.016,
          fontWeight: FontWeight.w500,
          color: const Color(0XFF777777),
        ),
        hintText: hintText,
        hintStyle: GoogleFonts.roboto(
          fontSize: Sizes.height * 0.016,
          fontWeight: FontWeight.w400,
          color: const Color(0xff707070),
        ),
        errorStyle: GoogleFonts.roboto(
          fontSize: Sizes.height * 0.014,
          fontWeight: FontWeight.w500,
          color: Colors.red,
        ),
        contentPadding: EdgeInsets.all(Sizes.height * 0.012),
        counterText: '',
        suffixIcon: suffixImg.isNotEmpty
            ? GestureDetector(
                onTap: onSuffixTap,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Image.asset(suffixImg, height: Sizes.height * 0.025),
                ),
              )
            : suffixIcon,

        prefixIcon: image.isEmpty
            ? null
            : Padding(
                padding: const EdgeInsets.all(15.0),
                child: Image.asset(
                  image,
                  height: Sizes.height * 0.032,
                  // color: AppColors.mainAppColr,
                ),
              ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(45),
          borderSide: const BorderSide(color: Color(0xffD9D8DD)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(45),
          borderSide: const BorderSide(color: Color(0xffD9D8DD)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(45),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(45),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
      validator: (value) {
        if (isRequired && (value == null || value.trim().isEmpty)) {
          debugPrint("BNVVVVVVVVVVVVVVVVVVV $value");
          if (isMobile) {
            // return 'Enter Contact Number';
            return "This field is required";
          }
          return errorText ?? 'This field is required';
        }
        if (isEmail && !_isValidEmail(value!)) {
          return 'Enter a valid email';
        }
        if (isMobile && !_isValidMobile(value!)) {
          return 'Please Enter Valid Contact Number';
        }
        if (isPincode && !_isValidPincode(value!)) {
          return 'Enter a valid postal code';
        }

        if (isFullName && !_isValidFullName(value!)) {
          return 'Enter a valid name';
        }
        if (isAmount && !_isValidAmount(value!)) {
          return 'Enter a Valid Amount';
        }
        if (isGST && !_isValidGST(value!)) {
          return 'Enter a valid GST number';
        }
        if (isHouseNumber && value!.trim().isEmpty) {
          return 'Enter house number';
        }
        if (isFloorNumber && value!.trim().isEmpty) {
          return 'Enter floor number';
        }
        if (isLandmark && value!.trim().isEmpty) {
          return 'Enter landmark';
        }
        if (isApartment && value!.trim().isEmpty) {
          return 'Enter apartment name';
        }
        if (isContactNumber && !_isValidMobile(value!)) {
          return 'Enter a valid contact number';
        }

        return null;
      },
    );
  }

  TextInputType _getKeyboardType() {
    if (isMobile) return TextInputType.phone;
    if (isEmail) return TextInputType.emailAddress;
    if (isAmount) return const TextInputType.numberWithOptions(decimal: true);
    if (isNumber || isPincode) {
      return TextInputType.number; // Added number keyboard type
    }
    return TextInputType.text;
  }

  List<TextInputFormatter> _getInputFormatters() {
    if (isMobile || isNumber || isPincode) {
      // Added isNumber to formatters
      return [FilteringTextInputFormatter.digitsOnly]; // Allow only numbers
    } else if (isAmount) {
      return [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))];
    } else if (isFullName) {
      return [FilteringTextInputFormatter.allow(RegExp(r"^[a-zA-Z0-9\s]+$"))];
    } else if (isGST) {
      return [
        UpperCaseTextFormatterBorder(), // Just this is enough!
      ];
    }
    return [];
  }

  bool _isValidEmail(String value) {
    // Ensure only one @ symbol exists and proper email format
    if (value.split('@').length != 2) return false;
    final regex = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
    return regex.hasMatch(value.trim());
  }

  bool _isValidMobile(String value) {
    return RegExp(r"^[0-9]{9,10}$").hasMatch(value);
  }

  // bool _isValidPincode(String value) {
  //   return RegExp(r"^[1-9][0-9]{5}$").hasMatch(value); // Indian pincode
  // }

  bool _isValidPincode(String value) {
    return RegExp(r"^[0-9]{4}$").hasMatch(value);
  }

  bool _isValidAmount(String value) {
    return RegExp(r"^\d*\.?\d+$").hasMatch(value) &&
        (double.tryParse(value) ?? 0) > 0;
  }

  bool _isValidGST(String value) {
    return RegExp(
      r"^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$",
    ).hasMatch(value.trim().toUpperCase());
  }

  bool _isValidFullName(String value) {
    return RegExp(r"^[a-zA-Z\s]+$").hasMatch(value);
  }
}

class UpperCaseTextFormatterBorder extends TextInputFormatter {
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
