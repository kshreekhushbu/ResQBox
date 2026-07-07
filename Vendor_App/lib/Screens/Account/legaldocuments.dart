import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:resqboxvendor/Utils/custom_appbar.dart';
import 'package:resqboxvendor/Utils/images.dart';
import 'package:resqboxvendor/Utils/navigations.dart';
import 'package:resqboxvendor/Utils/textstyles.dart';
import 'package:url_launcher/url_launcher.dart';

class LegalDocuments extends StatefulWidget {
  const LegalDocuments({super.key});

  @override
  State<LegalDocuments> createState() => _LegalDocumentsState();
}

class _LegalDocumentsState extends State<LegalDocuments> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Legal",
        isLeading: true,
        backTap: () {
          NavigateTo().backPage();
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildOption(
                onTap: () async {
                  const url = 'https://www.resqboxfood.com/privacy-policy';
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(
                      Uri.parse(url),
                      mode: LaunchMode.externalApplication,
                    );
                  }
                },
                svgAsset: AppImages.privacyPolicy,
                title: "Privacy Policy",
              ),
              SizedBox(height: 8),
              _buildOption(
                onTap: () async {
                  const url = 'https://www.resqboxfood.com/vendor-terms';
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(
                      Uri.parse(url),
                      mode: LaunchMode.externalApplication,
                    );
                  }
                },
                svgAsset: AppImages.terms,
                title: "Terms & Conditions",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption({
    required String title,
    String? svgAsset,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap ?? () {},
      child: Container(
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(),
        child: Row(
          children: [
            if (svgAsset != null && svgAsset.toLowerCase().endsWith('.svg'))
              SvgPicture.asset(svgAsset, height: 30, width: 30)
            else if (svgAsset != null && svgAsset.isNotEmpty)
              Image.asset(svgAsset, height: 30, width: 30)
            else
              const SizedBox(height: 30, width: 30),
            SizedBox(width: 6),
            Text(
              title,
              style: AppTextStyles.size14SemiBold.copyWith(
                color: Color(0xff191919),
              ),
            ),
            Spacer(),
            SvgPicture.asset(AppImages.chveronIcon, height: 22, width: 22),
          ],
        ),
      ),
    );
  }
}
