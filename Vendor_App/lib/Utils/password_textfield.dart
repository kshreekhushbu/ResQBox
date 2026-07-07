import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:resqboxvendor/Utils/colors.dart';
import 'package:resqboxvendor/Utils/mediaquery.dart';

class PasswordField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final Widget? prefixImage;
  final bool isRequired;
  final bool isConfirmPassword;
  final String? originalPassword; // For confirm password validation
  final int? maxLength;
  final bool isEditable;
  final bool isLogin; // For simple login validation

  const PasswordField({
    super.key,
    this.controller,
    this.hintText,
    this.prefixImage,
    this.isRequired = false,
    this.isConfirmPassword = false,
    this.originalPassword,
    this.maxLength,
    this.isEditable = true,
    this.isLogin = false, // Default to false for full validation
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _isObscured = true;

  String? _validate(String? value) {
    final trimmedValue = value?.trim() ?? '';

    if (widget.isRequired && trimmedValue.isEmpty) {
      return 'Please enter ${widget.hintText?.toLowerCase() ?? 'password'}';
    }

    // For login, only validate empty field
    if (widget.isLogin) {
      return null; // No additional validation for login
    }

    if (widget.isConfirmPassword && trimmedValue.isNotEmpty) {
      if (trimmedValue != widget.originalPassword) {
        return 'Passwords do not match';
      }
    } else if (!widget.isConfirmPassword && trimmedValue.isNotEmpty) {
      // Password strength validation (only for registration/signup)
      if (trimmedValue.length < 8) {
        return 'Password must be at least 8 characters long';
      }

      // Check for at least one uppercase letter
      if (!RegExp(r'[A-Z]').hasMatch(trimmedValue)) {
        return 'Password must contain at least one uppercase letter';
      }

      // Check for at least one lowercase letter
      if (!RegExp(r'[a-z]').hasMatch(trimmedValue)) {
        return 'Password must contain at least one lowercase letter';
      }

      // Check for at least one number
      if (!RegExp(r'\d').hasMatch(trimmedValue)) {
        return 'Password must contain at least one number';
      }

      // Check for at least one special character
      if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(trimmedValue)) {
        return 'Password must contain at least one special character';
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      style: GoogleFonts.roboto(
        fontSize: Sizes.height * 0.018,
        fontWeight: FontWeight.w500,
        color: AppColors.blackText,
      ),
      maxLength: widget.maxLength,
      readOnly: !widget.isEditable,
      obscureText: _isObscured,
      keyboardType: TextInputType.visiblePassword,
      decoration: InputDecoration(
        fillColor: const Color(0XFFF9F9F9),
        filled: false,
        hintText: widget.hintText,
        floatingLabelBehavior: FloatingLabelBehavior.never,
        labelStyle: GoogleFonts.roboto(
          fontSize: Sizes.height * 0.018,
          fontWeight: FontWeight.w500,
          color: AppColors.blackText,
        ),
        hintStyle: GoogleFonts.roboto(
          fontSize: Sizes.height * 0.015,
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
        prefixIcon: widget.prefixImage != null
            ? Padding(
                padding: const EdgeInsets.all(12.0),
                child: widget.prefixImage,
              )
            : null,
        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              _isObscured = !_isObscured;
            });
          },
          icon: Icon(
            _isObscured ? Icons.visibility_off : Icons.visibility,
            color: const Color(0XFF727272),
            size: 20,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(1),
          borderSide: const BorderSide(color: Color(0xffD9D8DD)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(1),
          borderSide: const BorderSide(color: Color(0xffD9D8DD)),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(1),
          borderSide: const BorderSide(color: Color(0xffD9D8DD)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(1),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(1),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
      validator: _validate,
    );
  }
}
