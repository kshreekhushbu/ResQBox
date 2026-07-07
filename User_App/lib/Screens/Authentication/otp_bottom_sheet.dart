import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:resqbox_user/Controllers/authentication_controller.dart';
import 'package:resqbox_user/Utils/active_btn.dart';
import 'package:resqbox_user/Utils/colors.dart';
import 'package:resqbox_user/Utils/custom_padding.dart';
import 'package:resqbox_user/Utils/custom_sizedbox.dart';
import 'package:resqbox_user/Utils/customtext.dart';
import 'package:resqbox_user/Utils/mediaquery.dart';
import 'package:resqbox_user/Utils/notifications.dart';

class OtpBottomSheet extends StatefulWidget {
  final String phoneNumber;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? fromScreen;
  final String? countryCode;

  const OtpBottomSheet({
    super.key,
    required this.phoneNumber,
    this.firstName,
    this.lastName,
    this.email,
    this.fromScreen,
    this.countryCode,
  });

  @override
  State<OtpBottomSheet> createState() => _OtpBottomSheetState();

  static void show(BuildContext context, String phoneNumber,
      {String? firstName,
      String? lastName,
      String? email,
      String? fromScreen,
      String? countryCode}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.hintTclr.withOpacity(0.8),
      isDismissible: true,
      enableDrag: true,
      builder: (BuildContext bottomSheetContext) {
        final keyboardHeight =
            MediaQuery.of(bottomSheetContext).viewInsets.bottom;
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Padding(
            padding: EdgeInsets.only(bottom: keyboardHeight),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(bottomSheetContext).size.height * 0.7,
              ),
              child: OtpBottomSheet(
                  phoneNumber: phoneNumber,
                  firstName: firstName,
                  lastName: lastName,
                  email: email,
                  fromScreen: fromScreen,
                  countryCode: countryCode),
            ),
          ),
        );
      },
    );
  }
}

class _OtpBottomSheetState extends State<OtpBottomSheet> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();
  Timer? _timer;
  int _remainingSeconds = 30;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _remainingSeconds = 30;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        _timer?.cancel();
      }
    });
  }

  void _resendOtp() {
    if (_canResend) {
      _startTimer();
      // Call resend OTP API here - don't show bottom sheet when resending
      if (widget.fromScreen == 'signup') {
        Provider.of<AuthenticationController>(context, listen: false)
            .signUpVerifyOtpApi(
          body: {
            "email": widget.email,
          },
          phoneNumber: widget.phoneNumber,
          firstName: widget.firstName ?? '',
          lastName: widget.lastName ?? '',
          email: widget.email ?? '',
          showBottomSheet: false, // Don't show new bottom sheet when resending
          countryCode: widget.countryCode ?? '',
        );
      } else {
        Provider.of<AuthenticationController>(context, listen: false).loginApi(
          body: {
            "email": widget.email,
          },
          showBottomSheet: false, // Don't show new bottom sheet when resending
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: Sizes.width * 0.12,
      height: Sizes.height * 0.06,
      textStyle: const TextStyle(
        fontSize: 20,
        color: AppColors.tTextColor,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: const Color(0XFFF3F3F3),
        border: Border.all(color: AppColors.lightYash),
        borderRadius: BorderRadius.circular(12),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: AppColors.tPrimaryColor),
      borderRadius: BorderRadius.circular(15),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        color: Colors.transparent,
        border: Border.all(color: AppColors.tPrimaryColor),
      ),
    );

    return Wrap(
      children: [
        Container(
          decoration: const BoxDecoration(
            color: AppColors.tWhiteColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: SafeArea(
            child: CustomPadding(
              vertical: .04,
              horizontal: .06,
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // CustomSizedBox(height: .04),
                    const CustomText(
                      text: "Verify your ResQBox Food account",
                      fontSize: .024,
                      fontWeight: FontWeight.w600,
                    ),
                    const CustomSizedBox(height: .03),
                    CustomText(
                      text:
                          "We’ve sent a 6-digit verification code to \n${widget.email}  Enter it below to \nverify your account.",
                      fontSize: .02,
                      textAlign: TextAlign.center,
                      fontWeight: FontWeight.w500,
                      color: AppColors.tBlackColor,
                    ),
                    const CustomSizedBox(height: .045),
                    Pinput(
                      length: 6,
                      controller: _otpController,
                      focusNode: _pinFocusNode,
                      defaultPinTheme: defaultPinTheme,
                      focusedPinTheme: focusedPinTheme,
                      submittedPinTheme: submittedPinTheme,
                      pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                      showCursor: true,
                      onCompleted: (pin) {
                        // Handle OTP completion
                      },
                    ),
                    const CustomSizedBox(height: .045),
                    Center(
                      child: GestureDetector(
                        onTap: _canResend ? _resendOtp : null,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const CustomText(
                              text: "Didn't get the code? ",
                              fontSize: .019,
                              fontWeight: FontWeight.w500,
                              color: AppColors.tBlackColor,
                            ),
                            _canResend
                                ? const CustomText(
                                    text: "Resend",
                                    fontSize: .019,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.tPrimaryColor,
                                  )
                                : CustomText(
                                    text: "Resend in ${_remainingSeconds}s",
                                    fontSize: .019,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.hintTclr,
                                  ),
                          ],
                        ),
                      ),
                    ),
                    const CustomSizedBox(height: .045),
                    ActiveButton(
                      height: Sizes.height * .062,
                      width: Sizes.width,
                      text: "Verify",
                      fontSize: .022,
                      borderRadius: 6,
                      onPressed: () async {
                        final deviceToken = await getFcmToken();
                        debugPrint("deviceToken: $deviceToken");
                        if (widget.fromScreen == 'signup') {
                          Map<String, dynamic> body = {
                            "phoneNumber": widget.phoneNumber,
                            "firstName": widget.firstName,
                            "lastName": widget.lastName,
                            "email": widget.email,
                            "countryCode": widget.countryCode,
                            "otp": _otpController.text,
                            "deviceToken": deviceToken
                          };
                          Provider.of<AuthenticationController>(context,
                                  listen: false)
                              .signUpApi(body: body);
                        } else {
                          Provider.of<AuthenticationController>(context,
                                  listen: false)
                              .foodieVerifyOtp(body: {
                            "email": widget.email,
                            "otp": _otpController.text,
                            "deviceToken": deviceToken
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
