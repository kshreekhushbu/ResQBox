import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'colors.dart';
import 'custom_image_widget.dart';
import 'custom_padding.dart';
import 'customtext.dart';
import 'validations.dart';

class CustomTextFormField extends StatelessWidget {
  const CustomTextFormField({
    super.key,
    required this.controller,
    this.hintText,
    this.sufficIconHeight,
    this.textAlignVertical,
    this.prefixIcon,
    this.maxxLength,
    this.isCountryCodeAdded,
    this.isPhoneNumber = false,
    this.validator,
    this.isEmailAdress = false,
    this.nextFocus,
    this.focusNode,
    this.isPincode,
    this.suffixIcon,
    this.obscureText = false,
    this.readOnly = false,
    this.onTap,
    this.ignoreCountrySelection = false,
    this.ignoreSpecialCharactersValidation = false,
    this.inputFormatters,
    this.textInputType,
    this.isNumberOnly,
    this.isExpands = false,
    this.isDense = false,
    this.isRemoveInputFormatter = false,
    this.autofocus = false,
    this.showCursor,
    this.customWarningMessage,
    this.customSuffix,
    this.contentPadding,
    this.onChanged,
    this.prefixIconHeight,
    this.onSuffixChanged,
    this.hintColor,
    this.prefixIconColor,
    this.customBorder,
    this.labelName,
    this.inputTextSize,
    this.maxLines,
    this.initialValue,
    this.hintFontWeight,
    this.hintFontSize,
    this.cursorHeight,
    this.textCapitalization = TextCapitalization.words,
    this.fillColor,
    this.customPrefixWidget,
    this.suffixIconColor,
    this.borderRaduise,
    this.textAlign = TextAlign.start,
    this.onFieldSubmitted,
    this.inputTextColor,
    this.textInputAction,
    this.floatingLabelFontWeight,
    this.minLines,
  });
  final TextEditingController controller;
  final String? hintText;
  final String? prefixIcon;
  final Widget? customPrefixWidget;
  final Widget? customSuffix;
  final void Function(String?)? isCountryCodeAdded;
  final bool? isPhoneNumber;
  final bool? isNumberOnly;
  final bool? isPincode;
  final bool ignoreCountrySelection;
  final bool? isEmailAdress;
  final String? Function(String?)? validator;
  final double? prefixIconHeight;
  final double? sufficIconHeight;
  final FocusNode? nextFocus;
  final FocusNode? focusNode;
  final String? suffixIcon;
  final bool? obscureText;
  final bool readOnly;
  final void Function(String)? onChanged;
  final TextInputType? textInputType;
  final TextInputFormatter? inputFormatters;
  final Function()? onTap;
  final String? labelName;
  final bool? showCursor;
  final EdgeInsetsGeometry? contentPadding;
  final void Function()? onSuffixChanged;
  final Color? hintColor;
  final FontWeight? hintFontWeight;
  final Color? fillColor;
  final double? hintFontSize;
  final Color? prefixIconColor;
  final Color? suffixIconColor;
  final int? maxLines;
  final int? minLines;
  final String? customWarningMessage;
  final bool isExpands;
  final bool isDense;
  final bool isRemoveInputFormatter;
  final double? inputTextSize;
  final double? borderRaduise;
  final double? cursorHeight;
  final InputBorder? customBorder;
  final TextAlignVertical? textAlignVertical;
  final bool autofocus;
  final int? maxxLength;
  final bool ignoreSpecialCharactersValidation;
  final TextCapitalization textCapitalization;
  final TextAlign textAlign;
  final Color? inputTextColor;
  final void Function(String)? onFieldSubmitted;
  final TextInputAction? textInputAction;
  final FontWeight? floatingLabelFontWeight;
  final String? initialValue;
  @override
  Widget build(BuildContext context) {
    TextInputType? keyboard;
    TextInputFormatter? digitsOnly;
    TextCapitalization textCapital = textCapitalization;
    int? maxLength;
    if (isPhoneNumber == true) {
      keyboard = TextInputType.phone;
      // maxLength = 10;
      digitsOnly = FilteringTextInputFormatter.digitsOnly;
    }
    if (isNumberOnly == true) {
      keyboard = TextInputType.number;

      digitsOnly = FilteringTextInputFormatter.digitsOnly;
    }

    if (isPincode == true) {
      keyboard = TextInputType.number;
      // maxLength = 6;
      digitsOnly = FilteringTextInputFormatter.digitsOnly;
    }

    if (isEmailAdress == true) {
      keyboard = TextInputType.emailAddress;
      textCapital = TextCapitalization.none;
    }

    return TextFormField(
      readOnly: readOnly, textAlign: textAlign, initialValue: initialValue,
      onTap: onTap,
      controller: controller, cursorHeight: cursorHeight,
      // autovalidateMode: AutovalidateMode.onUserInteraction,
      obscureText: obscureText ?? false,
      onChanged: onChanged, textAlignVertical: TextAlignVertical.top,
      textInputAction: textInputAction ??
          (nextFocus != null ? TextInputAction.next : TextInputAction.done),
      focusNode: focusNode, showCursor: showCursor, autofocus: autofocus,

      onFieldSubmitted: onFieldSubmitted ??
          (value) {
            if (focusNode != null) {
              focusNode!.unfocus();
              FocusScope.of(context).requestFocus(nextFocus);
            }
          },
      maxLength: maxxLength ?? maxLength, maxLines: maxLines,
      minLines: minLines,

      validator: validator ??
          (value) {
            if (value!.trim().isEmpty) {
              if (customWarningMessage != null) {
                return customWarningMessage;
              }
              if (hintText!.contains('Enter')) {
                return 'Please $hintText';
              }
              return 'Please Enter $hintText';
            }

            if (!ignoreSpecialCharactersValidation) {
              if (!Validations().validateFirstCharacterIsLetter(value)) {
                return 'Special characters are not allowed';
              }
            }

            if (!ignoreSpecialCharactersValidation) {
              if (value.contains(RegExp(r'[^a-zA-Z0-9 .@]'))) {
                return 'Special characters are not allowed';
              }
            }

            if (value.contains(RegExp(r'[\s]{2,}|\.{2,}'))) {
              return 'Consecutive spaces and consecutive dots are not allowed';
            }

            if (isPhoneNumber == true) {
              if (value.isNotEmpty) {
                if (int.parse(value[0]) <= 5) {
                  var number = controller.text[0];

                  return 'Number Cannot Be Start With $number ';
                }
                if (value.length != 10) {
                  return 'Mobile Number Should Be 10 Digits';
                }
              }
            }

            if (isEmailAdress == true) {
              if (value.isNotEmpty) {
                if (!value.isValidEmail()) {
                  return 'Please Enter Valid E-Mail';
                }
              }
            }

            // if (isPincode == true) {
            //   if (value.isNotEmpty) {
            //     if (value.length != 6) {
            //       return 'Invalid Pincode';
            //     }
            //   }
            // }

            return null;
          },

      style: customTextstyle(
        color: inputTextColor ?? AppColors.tTextColor,
        fontWeight: FontWeight.w600,
        fontSize: inputTextSize,
      ),
      keyboardType: textInputType ?? keyboard ?? TextInputType.multiline,
      textCapitalization: textCapital,
      inputFormatters: isRemoveInputFormatter
          ? null
          : [
              SingleSpaceInputFormatter(),
              inputFormatters ??
                  (digitsOnly ??
                      FilteringTextInputFormatter.singleLineFormatter),
            ],
      expands: isExpands,
      // autofillHints: ,
      decoration: InputDecoration(
        hintText: hintText,
        isDense: isDense,
        labelText: labelName,
        alignLabelWithHint: true,
        labelStyle: customTextstyle(
            color: hintColor ?? AppColors.tTextColor,
            fontWeight: hintFontWeight ?? FontWeight.w500,
            fontSize: hintFontSize),
        floatingLabelStyle: customTextstyle(
            fontSize: .018,
            color: AppColors.tTextColor,
            fontWeight: floatingLabelFontWeight ?? FontWeight.w400),
        counterText: '',
        prefixIcon: prefixIcon != null
            ? IconButton(
                onPressed: () {},
                icon: CustomImage(
                  image: prefixIcon!,
                  color: prefixIconColor,
                  height: prefixIconHeight ?? .033,
                ))
            : customPrefixWidget,
        suffixIcon: customSuffix ??
            (suffixIcon != null
                ? CustomPadding(
                    right: .008,
                    child: IconButton(
                        onPressed: onSuffixChanged,
                        icon: CustomImage(
                          image: suffixIcon!,
                          color: suffixIconColor,
                          height: sufficIconHeight ?? .03,
                        )),
                  )
                : null),
        fillColor: fillColor ?? const Color(0XFFF5F5F5),
        filled: true,
        contentPadding: contentPadding ??
            const EdgeInsets.only(top: 12, bottom: 10, left: 5),
        hintStyle: customTextstyle(
            color: hintColor ?? AppColors.hintTclr,
            fontWeight: hintFontWeight ?? FontWeight.w400,
            fontSize: hintFontSize),
        border: customBorder ?? inputBorder(borderRaduise: borderRaduise),
        disabledBorder:
            customBorder ?? inputBorder(borderRaduise: borderRaduise),
        enabledBorder:
            customBorder ?? inputBorder(borderRaduise: borderRaduise),
        errorBorder: customBorder ?? inputBorder(borderRaduise: borderRaduise),
        focusedBorder:
            customBorder ?? inputBorder(borderRaduise: borderRaduise),
        focusedErrorBorder:
            customBorder ?? inputBorder(borderRaduise: borderRaduise),
      ),
    );
  }
}

OutlineInputBorder inputBorder({double? borderRaduise}) {
  return OutlineInputBorder(
      // borderSide: const BorderSide(color: AppColors.tTextColor, width: .5),
      borderSide: BorderSide.none,
      borderRadius: BorderRadius.circular(borderRaduise ?? 30));
}

class SingleSpaceInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Check if the new value has any non-space characters.
    bool hasNonSpaceCharacters = newValue.text.trim().isNotEmpty;

    // Replace multiple spaces with a single space after the text,
    // but only if there are non-space characters in the input.
    String formattedText = hasNonSpaceCharacters
        ? newValue.text.replaceAll(RegExp(r'\s+'), ' ')
        : '';

    // Preserve the cursor position if possible
    int selectionIndex = newValue.selection.baseOffset;
    if (selectionIndex > formattedText.length) {
      selectionIndex = formattedText.length;
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.fromPosition(
        TextPosition(offset: selectionIndex),
      ),
    );
  }
}
