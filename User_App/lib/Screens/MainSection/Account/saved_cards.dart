import 'package:flutter/material.dart';
import 'package:resqbox_user/Screens/MainSection/Account/add_new_card.dart';
import 'package:resqbox_user/Utils/active_btn.dart';
import 'package:resqbox_user/Utils/colors.dart';
import 'package:resqbox_user/Utils/custom_appbar.dart';
import 'package:resqbox_user/Utils/custom_padding.dart';
import 'package:resqbox_user/Utils/custom_sizedbox.dart';
import 'package:resqbox_user/Utils/customtext.dart';
import 'package:resqbox_user/Utils/custom_image_widget.dart';
import 'package:resqbox_user/Utils/custom_tap.dart';
import 'package:resqbox_user/Utils/images.dart';
import 'package:resqbox_user/Utils/mediaquery.dart';
import 'package:resqbox_user/Utils/navigations.dart';
import 'package:provider/provider.dart';
import 'package:resqbox_user/Controllers/account_controller.dart';
import 'package:resqbox_user/Models/saved_card_model.dart';

class SavedCards extends StatefulWidget {
  const SavedCards({super.key});

  @override
  State<SavedCards> createState() => _SavedCardsState();
}

class _SavedCardsState extends State<SavedCards> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AccountController>(context, listen: false).getSavedCardsApi();
    });
  }

  void _showDeleteConfirmation(BuildContext context, String cardId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const CustomText(
          text: "Delete Card?",
          fontWeight: FontWeight.w700,
          fontSize: 0.02,
        ),
        content: const CustomText(
          text: "Are you sure you want to remove this card?",
          fontSize: 0.016,
          color: AppColors.hintTclr,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const CustomText(
              text: "Cancel",
              fontSize: 0.016,
              fontWeight: FontWeight.w600,
              color: AppColors.hintTclr,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Provider.of<AccountController>(context, listen: false)
                  .deleteCardApi(cardId);
            },
            child: const CustomText(
              text: "Delete",
              fontSize: 0.016,
              fontWeight: FontWeight.w700,
              color: AppColors.red,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountController>(
        builder: (context, accountController, child) {
      final savedCards = accountController.savedCardsData?.data ?? [];

      return Scaffold(
        backgroundColor: const Color(0XFFF6F6F6),
        appBar: CustomAppBar(
          title: "Saved Cards",
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
              text: "Add New",
              borderRadius: 25,
              onPressed: () {
                accountController.initAddCardFlow();
              }),
        ),
        body: accountController.isLoadingCards
            ? const Center(child: CircularProgressIndicator())
            : savedCards.isEmpty
                ? const Center(
                    child: CustomText(
                      text: "No saved cards found",
                      fontSize: 0.018,
                      color: AppColors.hintTclr,
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: Sizes.width * 0.04,
                      vertical: Sizes.height * 0.02,
                    ),
                    itemCount: savedCards.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == savedCards.length - 1
                              ? 0
                              : Sizes.height * 0.018,
                        ),
                        child: _SavedCardWidget(
                          card: savedCards[index],
                          onDelete: () => _showDeleteConfirmation(
                              context, savedCards[index].cardId.toString()),
                        ),
                      );
                    },
                  ),
      );
    });
  }
}

class _SavedCardWidget extends StatelessWidget {
  const _SavedCardWidget({required this.card, required this.onDelete});

  final PaymentMethodData card;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    String brandLogo = AppImages.accountCardLogo1; // Default
    String cardTypeLogo = AppImages.accountCardName1;

    if (card.cardBrand?.toLowerCase() == "visa") {
      brandLogo = AppImages.accountCardLogo1;
      cardTypeLogo = AppImages.accountCardName1;
    } else if (card.cardBrand?.toLowerCase() == "mastercard") {
      brandLogo = AppImages.accountCardLogo2;
      cardTypeLogo = AppImages.accountCardName2;
    } else if (card.cardBrand?.toLowerCase() == "amex") {
      brandLogo = AppImages.american;
      cardTypeLogo = AppImages.accountCardName2;
    } else if (card.cardBrand?.toLowerCase() == "rupay") {
      brandLogo = AppImages.rupay;
      cardTypeLogo = AppImages.accountCardName2;
    } else {
      // Fallback for other card brands (Amex, Discover, etc.)
      brandLogo = AppImages.others;
      cardTypeLogo = AppImages.accountCreditCards;
    }

    return Container(
      padding: EdgeInsets.all(Sizes.width * 0.0),
      decoration: BoxDecoration(
        color: AppColors.tWhiteColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: CustomPadding(
        vertical: .018,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomPadding(
              horizontal: .05,
              child: Row(
                children: [
                  CustomImage(
                    image: brandLogo,
                    height: .035,
                    fit: BoxFit.contain,
                  ),
                  CustomSizedBox(width: .015),
                  Expanded(
                    child: CustomText(
                      text: card.cardBrand?.toUpperCase() ?? "CARD",
                      fontSize: 0.018,
                      fontWeight: FontWeight.w600,
                      color: Color(0XFF4B5563),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      CustomImage(
                        image: cardTypeLogo,
                        height: .024,
                        fit: BoxFit.contain,
                      ),
                      CustomSizedBox(height: .006),
                      CustomText(
                        text: "EXP ${card.cardExpMonth}/${card.cardExpYear}",
                        fontSize: 0.014,
                        fontWeight: FontWeight.w500,
                        color: Color(0XFF4B5563),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            CustomSizedBox(height: .02),
            CustomPadding(
              horizontal: .05,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CustomText(
                    text: "CARD NUMBER",
                    fontSize: 0.016,
                    fontWeight: FontWeight.w500,
                    color: Color(0XFF4B5563),
                  ),
                  CustomSizedBox(height: .006),
                  CustomPadding(
                    left: .01,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.star,
                          size: 17,
                          color: Color(0XFF4B5563),
                        ),
                        const Icon(
                          Icons.star,
                          size: 17,
                          color: Color(0XFF4B5563),
                        ),
                        const Icon(
                          Icons.star,
                          size: 17,
                          color: Color(0XFF4B5563),
                        ),
                        const Icon(
                          Icons.star,
                          size: 17,
                          color: Color(0XFF4B5563),
                        ),
                        CustomSizedBox(width: .01),
                        CustomText(
                          text: "${card.cardLast4}",
                          fontSize: 0.028,
                          fontWeight: FontWeight.w600,
                          color: AppColors.tBlackColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            CustomPadding(
                vertical: .02,
                child: Divider(color: Color(0XFFE1E1E1), height: 1)),
            Center(
              child: CustomTap(
                onTap: onDelete,
                child: const CustomText(
                  text: "REMOVE CARD",
                  fontSize: 0.016,
                  fontWeight: FontWeight.w600,
                  color: Color(0XFFE71A1A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
