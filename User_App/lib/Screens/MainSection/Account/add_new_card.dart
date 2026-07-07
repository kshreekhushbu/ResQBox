import 'package:flutter/material.dart';
import 'package:resqbox_user/Utils/active_btn.dart';
import 'package:resqbox_user/Utils/colors.dart';
import 'package:resqbox_user/Utils/custom_appbar.dart';
import 'package:resqbox_user/Utils/custom_image_widget.dart';
import 'package:resqbox_user/Utils/custom_padding.dart';
import 'package:resqbox_user/Utils/custom_sizedbox.dart';
import 'package:resqbox_user/Utils/customtext.dart';
import 'package:resqbox_user/Utils/images.dart';
import 'package:resqbox_user/Utils/mediaquery.dart';
import 'package:resqbox_user/Utils/navigations.dart';

class AddNewCard extends StatefulWidget {
  const AddNewCard({super.key});

  @override
  State<AddNewCard> createState() => _AddNewCardState();
}

class _AddNewCardState extends State<AddNewCard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0XFFF6F6F6),
      appBar: CustomAppBar(
        title: "Add New Card",
        titleFontSize: 0.022,
        backgroundColor: AppColors.tWhiteColor,
        backTap: () => Navigator.of(context).pop(),
      ),
      bottomNavigationBar: CustomPadding(
        vertical: .02,
        horizontal: .04,
        child: ActiveButton(
            height: Sizes.height * .062,
            width: Sizes.width,
            text: "Add Card",
            borderRadius: 25,
            onPressed: () {
              // NavigateTo().nextPage(child: const AddNewCard());
            }),
      ),
      body: CustomPadding(
        vertical: .02,
        horizontal: .03,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.tWhiteColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomPadding(
                vertical: .025,
                horizontal: .03,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CustomText(
                      text: "Cardholder Name",
                      color: Color(0XFFA2A2A7),
                      fontSize: 0.018,
                      fontWeight: FontWeight.w500,
                    ),
                    const CustomPadding(
                      vertical: .015,
                      child: Row(
                        children: [
                          CustomImage(
                            image: AppImages.accountCardProfile,
                            height: .03,
                            fit: BoxFit.contain,
                          ),
                          CustomSizedBox(width: .025),
                          CustomText(
                            text: "Aimal Naseem",
                            color: AppColors.tBlackColor,
                            fontSize: 0.018,
                            fontWeight: FontWeight.w500,
                          ),
                        ],
                      ),
                    ),
                    Divider(
                        color: const Color(0XFFE1E1E1).withOpacity(.5),
                        height: 1),
                    const CustomSizedBox(height: .02),
                    const CustomText(
                      text: "Expiry Date",
                      color: Color(0XFFA2A2A7),
                      fontSize: 0.018,
                      fontWeight: FontWeight.w500,
                    ),
                    const CustomPadding(
                      vertical: .015,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustomText(
                            text: "09/06/2024",
                            color: AppColors.tBlackColor,
                            fontSize: 0.018,
                            fontWeight: FontWeight.w500,
                          ),
                          CustomSizedBox(width: .025),
                          CustomImage(
                            image: AppImages.accountCardCalender,
                            height: .03,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                    ),
                    Divider(
                        color: const Color(0XFFE1E1E1).withOpacity(.5),
                        height: 1),
                    const CustomSizedBox(height: .02),
                    const CustomText(
                      text: "Card Number",
                      color: Color(0XFFA2A2A7),
                      fontSize: 0.018,
                      fontWeight: FontWeight.w500,
                    ),
                    const CustomPadding(
                      vertical: .015,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustomImage(
                            image: AppImages.accountCreditCards,
                            height: .03,
                            fit: BoxFit.contain,
                          ),
                          CustomSizedBox(width: .025),
                          Expanded(
                            child: CustomText(
                              text: "4562 1122 4595 7852",
                              color: AppColors.tBlackColor,
                              fontSize: 0.018,
                              fontWeight: FontWeight.w500,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          CustomImage(
                            image: AppImages.accountCardId,
                            height: .02,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                    ),
                    Divider(
                        color: const Color(0XFFE1E1E1).withOpacity(.5),
                        height: 1),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
