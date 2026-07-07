// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:provider/provider.dart';
// import 'package:pinput/pinput.dart';
// import 'package:resqboxvendor/Controller/AuthController.dart';
// import 'package:resqboxvendor/Controller/DashboardController.dart';
// import 'package:resqboxvendor/Controller/KitchenRegistrationController.dart';
// import 'package:resqboxvendor/Screens/Auth/registration.dart';
// import 'package:resqboxvendor/Screens/Auth/registration_verification.dart';
// import 'package:resqboxvendor/Screens/bottomNavigation.dart';
// import 'package:resqboxvendor/Utils/colors.dart';
// import 'package:resqboxvendor/Utils/custom_appbar.dart';
// import 'package:resqboxvendor/Utils/custom_border_btn.dart';
// import 'package:resqboxvendor/Utils/navigations.dart';
// import 'package:resqboxvendor/Utils/textstyles.dart';

// class OTPVerification extends StatefulWidget {
//   final String mobileNumber;
//   const OTPVerification({super.key, required this.mobileNumber});

//   @override
//   State<OTPVerification> createState() => _OTPVerificationState();
// }

// class _OTPVerificationState extends State<OTPVerification> {
//   String otp = "";
//   TextEditingController pinCon = TextEditingController();
//   final GlobalKey<FormState> otpFormKey = GlobalKey<FormState>();

//   @override
//   void initState() {
//     super.initState();
//   }

//   @override
//   void dispose() {
//     pinCon.dispose();
//     super.dispose();
//   }

//   void _resendOtp() async {
//     final authProvider = Provider.of<AuthController>(context, listen: false);
//     pinCon.clear();
//     otp = "";
//     setState(() {});

//     // Resend OTP
//     await authProvider.sendOtp();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final authProvider = Provider.of<AuthController>(context);
//     final defaultPinTheme = PinTheme(
//       width: 48,
//       height: 48,
//       textStyle: GoogleFonts.roboto(fontSize: 24, fontWeight: FontWeight.w500),
//       decoration: BoxDecoration(
//         color: Colors.grey.withOpacity(0.05),
//         border: Border.all(color: const Color.fromRGBO(234, 239, 243, 1)),
//         borderRadius: BorderRadius.circular(10),
//       ),
//     );

//     final focusedPinTheme = defaultPinTheme.copyDecorationWith(
//       border: Border.all(color: AppColors.mainAppColr),
//       borderRadius: BorderRadius.circular(8),
//     );

//     return Scaffold(
//       backgroundColor: AppColors.tWhiteColor,
//       appBar: CustomAppBar(
//         isLeading: true,
//         title: "OTP Verification",
//         backTap: () {
//           NavigateTo().backPage();
//         },
//       ),
//       body: Form(
//         key: otpFormKey,
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 48.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const SizedBox(height: 38),
//               Text(
//                 "Enter The OTP Sent To Your Number",
//                 style: AppTextStyles.size14Regular.copyWith(
//                   fontWeight: FontWeight.w500,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 8),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.start,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     "+91 ${widget.mobileNumber}",
//                     style: AppTextStyles.size16Medium,
//                   ),
//                   const SizedBox(width: 8),
//                   GestureDetector(
//                     onTap: () => NavigateTo().backPage(),
//                     child: Container(
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(5),
//                         border: Border.all(color: const Color(0xFF41D63C)),
//                       ),
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 8,
//                         vertical: 2,
//                       ),
//                       child: Text("Change", style: AppTextStyles.size12Regular),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 30),
//               Center(
//                 child: Pinput(
//                   controller: pinCon,
//                   length: 4,
//                   defaultPinTheme: defaultPinTheme,
//                   focusedPinTheme: focusedPinTheme,
//                   separatorBuilder: (index) => const SizedBox(width: 20),
//                   onChanged: (val) => setState(() => otp = val),
//                   onSubmitted: (pin) => setState(() => otp = pin),
//                   inputFormatters: [FilteringTextInputFormatter.digitsOnly],
//                   validator: (val) {
//                     if (val == null || val.isEmpty) {
//                       return "Please enter the verification code";
//                     }
//                     if (val.length != 4) {
//                       return "Please enter a valid verification code";
//                     }
//                     return null;
//                   },
//                 ),
//               ),
//               const SizedBox(height: 25),
//               Center(
//                 child: authProvider.start <= 0
//                     ? InkWell(
//                         onTap: _resendOtp,
//                         child: Container(
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(8),
//                             border: Border.all(color: AppColors.mainAppColr),
//                           ),
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 12,
//                             vertical: 8,
//                           ),
//                           child: Text(
//                             "Resend Code",
//                             style: AppTextStyles.size12Medium.copyWith(
//                               color: AppColors.mainAppColr,
//                             ),
//                           ),
//                         ),
//                       )
//                     : RichText(
//                         text: TextSpan(
//                           style: GoogleFonts.roboto(
//                             fontSize: 13,
//                             color: AppColors.tBlackColor,
//                           ),
//                           children: [
//                             const TextSpan(text: "Resend in "),
//                             TextSpan(
//                               text: authProvider.start < 10
//                                   ? "00:0${authProvider.start}"
//                                   : "00:${authProvider.start}",
//                               style: GoogleFonts.roboto(
//                                 fontWeight: FontWeight.bold,
//                                 color: AppColors.mainAppColr,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//               ),
//               SizedBox(height: 40),
//               CustomRectBtn(
//                 color: AppColors.mainAppColr,
//                 borderColor: AppColors.mainAppColr,
//                 height: 49,
//                 width: double.infinity,
//                 text: "Submit",
//                 onTap: () async {
//                   if (otpFormKey.currentState!.validate()) {
//                     if (otp.length == 4) {
//                       final result = await authProvider.verifyOtp(
//                         widget.mobileNumber,
//                         otp,
//                       );

//                       if (result != null &&
//                           result['success'] == true &&
//                           mounted) {
//                         final isExist = result['isExist'];

//                         // Check if user exists (isExist == 1) or is new (isExist == 0)
//                         if (isExist == 1 || isExist == true) {
//                           // Existing user - check kitchen status
//                           final kitchenController =
//                               Provider.of<KitchenRegistrationController>(
//                                 context,
//                                 listen: false,
//                               );

//                           await kitchenController.getKitchenStatus();

//                           if (!mounted) return;

//                           if (kitchenController.registrationStatus ==
//                               "APPROVED") {
//                             // Navigate to MainTabScreen if approved
//                             Navigator.pushAndRemoveUntil(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => ChangeNotifierProvider(
//                                   create: (_) =>
//                                       DashboardProvider()..setIndex(0),
//                                   child: const MainTabScreen(),
//                                 ),
//                               ),
//                               (route) => false,
//                             );
//                           } else {
//                             // Navigate to RegistrationVerification if not approved
//                             NavigateTo().pushRemove(
//                               child: const RegistrationVerification(),
//                             );
//                           }
//                         } else {
//                           // New user (isExist == 0) - navigate to registration
//                           NavigateTo().pushRemove(
//                             child: const KitchenRegistration(),
//                           );
//                         }
//                       }
//                     } else {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                           content: Text("Please enter a valid OTP"),
//                         ),
//                       );
//                     }
//                   }
//                 },
//                 textColor: Colors.white,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
