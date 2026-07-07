import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:resqboxvendor/Utils/colors.dart';
import 'package:resqboxvendor/Utils/custom_alert.dart';
import 'package:resqboxvendor/Utils/images.dart';
import 'package:resqboxvendor/Utils/textstyles.dart';

class StripeOnboardingDialog extends StatelessWidget {
  final VoidCallback onContinue;
  final bool isPending;
  final bool hasUrl;
  final bool isLoading;

  const StripeOnboardingDialog({
    super.key,
    required this.onContinue,
    this.isPending = false,
    this.hasUrl = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    // Use a Stack to position the logout button on the overlay
    return Stack(
      fit: StackFit.expand,
      children: [
        // The centered Dialog
        Center(
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24.0),
            ),
            backgroundColor: Colors.white,
            insetPadding: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  Container(
                    height: 100,
                    alignment: Alignment.center,
                    child: Image.asset(AppImages.stripebank),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isPending
                        ? "Account Verification Pending"
                        : "Add Bank Account Securely",
                    textAlign: TextAlign.center,
                    style: AppTextStyles.size18Bold.copyWith(
                      color: Color(0xff4B5563),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isPending
                        ? "Your Stripe account is currently pending verification. This process verifies your details to ensure secure payouts. Please check back soon."
                        : "You'll be redirected to Stripe, our trusted payment partner, to securely add your bank details. This helps us verification your account and send payouts directly to you.",
                    textAlign: TextAlign.center,
                    style: AppTextStyles.size14Medium.copyWith(
                      color: Color(0xff4B5563),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : onContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mainAppColr,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              isPending
                                  ? "Check Status"
                                  : (hasUrl
                                        ? "Complete Onboarding"
                                        : "Continue"),
                              style: AppTextStyles.size16SemiBold,
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),

        Positioned(
          top: 16,
          right: 16,
          child: SafeArea(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  showAlertDialog(
                    context: context,
                    onPressed: () {
                      Navigator.pop(context); // Close Alert
                      Navigator.pop(
                        context,
                        "logout",
                      ); // Close Stripe Dialog with 'logout'
                    },
                  );
                },
                borderRadius: BorderRadius.circular(5),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    // shape: BoxShape.circle,
                  ),
                  // child: SvgPicture.asset(
                  //   AppImages.logout,
                  //   height: 24,
                  //   width: 24,
                  // ),
                  child: Column(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      Text("Logout", style: AppTextStyles.size14Medium),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
