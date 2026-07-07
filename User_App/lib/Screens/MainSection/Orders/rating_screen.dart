import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resqbox_user/Controllers/orders_controller.dart';
import 'package:resqbox_user/Utils/active_btn.dart';
import 'package:resqbox_user/Utils/colors.dart';
import 'package:resqbox_user/Utils/custom_appbar.dart';
import 'package:resqbox_user/Utils/custom_padding.dart';
import 'package:resqbox_user/Utils/custom_sizedbox.dart';
import 'package:resqbox_user/Utils/customtext.dart';
import 'package:resqbox_user/Utils/mediaquery.dart';
import 'package:resqbox_user/Utils/network_image.dart';
import 'package:resqbox_user/Utils/textformfield.dart';

class OrderedFood {
  final String title;
  final String subtitle;
  final String price;
  final int quantity;
  final String imageUrl;

  const OrderedFood({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.quantity,
    required this.imageUrl,
  });
}

class RatingScreen extends StatefulWidget {
  final int? orderId;
  final String? kitchenIdImage;
  final String? foodIdImage;
  const RatingScreen(
      {super.key, this.orderId, this.kitchenIdImage, this.foodIdImage});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  final TextEditingController _feedbackController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  int _kitchenRating = 0;
  int _foodRating = 0;
  String? _kitchenRatingError;
  String? _foodRatingError;
  String? _reviewError;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.tWhiteColor,
      appBar: CustomAppBar(
        title: "Rate & Review",
        titleFontSize: 0.022,
        backgroundColor: AppColors.tWhiteColor,
        backTap: () => Navigator.of(context).pop(),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
              bottom: Sizes.height * 0.03, top: Sizes.height * 0.02),
          child: Column(
            children: [
              _buildRatingCard(
                title: "Please share your experience with \nthe Resturant",
                subtitle: "Please share your experience with the kitchen",
                imageUrl: widget.kitchenIdImage ?? '',
                // "https://images.unsplash.com/photo-1452251889946-8ff5f191c9c?auto=format&fit=crop&w=900&q=60",
                rating: _kitchenRating,
                onRated: (value) => setState(() {
                  _kitchenRating = value;
                  _kitchenRatingError = null;
                }),
                errorText: _kitchenRatingError,
              ),
              CustomSizedBox(height: 0.02),
              _buildRatingCard(
                title: "How was the Food?",
                subtitle: "Let us know what you loved the most",
                imageUrl: widget.foodIdImage ?? '',
                // "https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=900&q=60",
                rating: _foodRating,
                onRated: (value) => setState(() {
                  _foodRating = value;
                  _foodRatingError = null;
                }),
                errorText: _foodRatingError,
              ),
              CustomSizedBox(height: 0.02),
              _buildFeedbackCard(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomPadding(
        horizontal: .04,
        vertical: .015,
        child: ActiveButton(
          height: Sizes.height * .06,
          width: Sizes.width,
          text: "Submit Review",
          borderRadius: 25,
          onPressed: () async {
            // Validate ratings and review
            String? kitchenError;
            String? foodError;
            String? reviewError;
            bool isValid = true;

            if (_kitchenRating == 0) {
              kitchenError = "Please rate the restaurant";
              isValid = false;
            }

            if (_foodRating == 0) {
              foodError = "Please rate the food";
              isValid = false;
            }

            bool isReviewMandatory =
                (_kitchenRating > 0 && _kitchenRating <= 2) ||
                    (_foodRating > 0 && _foodRating <= 2);

            if (isReviewMandatory && _feedbackController.text.trim().isEmpty) {
              reviewError = "Please write your review";
              isValid = false;
            }

            setState(() {
              _kitchenRatingError = kitchenError;
              _foodRatingError = foodError;
              _reviewError = reviewError;
            });
            if (!isValid) {
              return;
            }
            Map<String, dynamic> body = {
              "orderId": widget.orderId,
              "orderRating": _foodRating,
              "kitchenRating": _kitchenRating,
              "kitchenReview": _feedbackController.text.trim()
            };
            await Provider.of<OrdersController>(context, listen: false)
                .submitRatingApi(body);
          },
        ),
      ),
    );
  }

  Widget _buildRatingCard({
    required String title,
    required String subtitle,
    required String imageUrl,
    required int rating,
    required ValueChanged<int> onRated,
    String? errorText,
  }) {
    return CustomPadding(
      horizontal: .04,
      top: .02,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: Sizes.height * 0.018,
          horizontal: Sizes.width * 0.03,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0XFFE1DFDF)),
          color: AppColors.tWhiteColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              offset: const Offset(0, 8),
              blurRadius: 18,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              height: Sizes.height * 0.11,
              width: Sizes.height * 0.11,
              padding: EdgeInsets.all(Sizes.height * 0.01),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.tPrimaryColor, width: 1),
              ),
              child: ClipOval(
                child: CustomNetworkImage(
                  url: imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: Sizes.height * 0.01),
            CustomPadding(
              vertical: 0.008,
              horizontal: 0.08,
              child: CustomText(
                text: title,
                fontSize: 0.016,
                fontWeight: FontWeight.w600,
                textAlign: TextAlign.center,
              ),
            ),
            CustomPadding(
              top: 0.01,
              bottom: .005,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => GestureDetector(
                    onTap: () => onRated(index + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        size: 38,
                        color: index < rating
                            ? AppColors.tPrimaryColor
                            : AppColors.hintTclr.withOpacity(0.3),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (errorText != null)
              CustomPadding(
                top: 0.008,
                child: CustomText(
                  text: errorText,
                  fontSize: 0.014,
                  color: Colors.red,
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackCard() {
    return CustomPadding(
      horizontal: .04,
      top: .025,
      child: Container(
        padding: EdgeInsets.all(Sizes.width * 0.04),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0XFFE1DFDF)),
          color: AppColors.tWhiteColor,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CustomText(
              text:
                  "How was your Experience? Your feedback helps us improve and serve you better",
              fontSize: 0.018,
              fontWeight: FontWeight.w500,
            ),
            const CustomSizedBox(height: 0.015),
            // const CustomText(
            //   text: "Your feedback helps us improve and serve you better.",
            //   fontSize: 0.015,
            //   color: AppColors.hintTclr,
            // ),
            // const CustomSizedBox(height: 0.015),
            CustomTextFormField(
              controller: _feedbackController,
              maxLines: 6,
              hintColor: AppColors.hintTclr,
              hintText:
                  "Write your review here ${(_kitchenRating > 0 && _kitchenRating <= 2) || (_foodRating > 0 && _foodRating <= 2) ? '(Required)' : '(Optional)'}",
              hintFontSize: 0.016,
              fillColor: const Color(0XFFF7F8FC),
              customBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              onChanged: (value) {
                if (value.trim().isNotEmpty && _reviewError != null) {
                  setState(() {
                    _reviewError = null;
                  });
                }
              },
            ),
            if (_reviewError != null)
              CustomPadding(
                top: 0.008,
                child: CustomText(
                  text: _reviewError!,
                  fontSize: 0.014,
                  color: Colors.red,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
