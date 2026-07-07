import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resqbox_user/Controllers/home_controller.dart';
import 'package:resqbox_user/Models/reviews_model.dart';
import 'package:resqbox_user/Utils/colors.dart';
import 'package:resqbox_user/Utils/custom_appbar.dart';
import 'package:resqbox_user/Utils/custom_padding.dart';
import 'package:resqbox_user/Utils/custom_sizedbox.dart';
import 'package:resqbox_user/Utils/customtext.dart';
import 'package:resqbox_user/Utils/mediaquery.dart';
import 'package:resqbox_user/Utils/network_image.dart';

class ViewRatingsScreen extends StatefulWidget {
  final int? restaurantId;
  const ViewRatingsScreen({super.key, this.restaurantId});

  @override
  State<ViewRatingsScreen> createState() => _ViewRatingsScreenState();
}

class _ViewRatingsScreenState extends State<ViewRatingsScreen> {
  final List<_Review> _allReviews = const [
    _Review(
      name: 'Priya Sharma',
      rating: 5,
      comment:
          'Loved the homely flavours and packaging. Pickup was quick and hassle free.',
      avatar:
          'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=200&q=60',
    ),
    _Review(
      name: 'Karthik Rao',
      rating: 4,
      comment:
          'Paneer tikka was delicious. Would prefer a little less oil next time.',
      avatar:
          'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?auto=format&fit=crop&w=200&q=60',
    ),
    _Review(
      name: 'Meera D',
      rating: 5,
      comment: 'Amazing variety and super friendly chef. Highly recommended.',
      avatar:
          'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?auto=format&fit=crop&w=200&q=60',
    ),
    _Review(
      name: 'Srinivas',
      rating: 3,
      comment: 'Taste was good but portion size can be improved.',
      avatar:
          'https://images.unsplash.com/photo-1456327102063-fb5054efe647?auto=format&fit=crop&w=200&q=60',
    ),
  ];

  int? _selectedRating;

  List<_Review> get _filteredReviews {
    if (_selectedRating == null) return _allReviews;
    return _allReviews
        .where((element) => element.rating == _selectedRating)
        .toList();
  }

  double get _overallRating {
    if (_allReviews.isEmpty) return 0;
    final total = _allReviews.fold(
        0, (previousValue, element) => previousValue + element.rating);
    return total / _allReviews.length;
  }

  void _onFilterTap(int? rating) {
    setState(() {
      _selectedRating = rating;
    });
    // Call API with the selected rating filter
    Provider.of<HomeController>(context, listen: false)
        .kitchenReviewsApi(widget.restaurantId, rating);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Provider.of<HomeController>(context, listen: false)
          .kitchenReviewsApi(widget.restaurantId, null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeController>(builder: (context, homeController, child) {
      return Scaffold(
        backgroundColor: AppColors.tWhiteColor,
        appBar: CustomAppBar(
          title: 'Customer Reviews',
          backgroundColor: AppColors.tWhiteColor,
          titleFontSize: 0.022,
          backTap: () => Navigator.of(context).pop(),
        ),
        body: homeController.isKitchenReviewsLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomPadding(
                horizontal: .04,
                vertical: .02,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text:
                          'User Reviews (${homeController.reviewsModelData?.summary?.totalReviews ?? 0})',
                      fontSize: 0.022,
                      fontWeight: FontWeight.w700,
                    ),
                    const CustomSizedBox(height: .02),
                    Row(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            final rating = double.tryParse(homeController
                                        .reviewsModelData?.summary?.avgRating
                                        ?.toString() ??
                                    '0') ??
                                0.0;
                            IconData iconData;
                            if (rating >= index + 1) {
                              // Full star
                              iconData = Icons.star;
                            } else if (rating > index) {
                              // Half star
                              iconData = Icons.star_half;
                            } else {
                              // Empty star
                              iconData = Icons.star_border;
                            }
                            return CustomPadding(
                              right: 0.002,
                              child: Icon(iconData,
                                  size: 16, color: AppColors.tPrimaryColor),
                            );
                          }),
                        ),
                        const CustomSizedBox(width: .02),
                        CustomText(
                          text:
                              '${homeController.reviewsModelData?.summary?.avgRating?.toStringAsFixed(1) ?? '0'} out of 5',
                          fontSize: .016,
                          fontWeight: FontWeight.w600,
                        ),
                      ],
                    ),
                    const CustomSizedBox(height: .018),
                    CustomText(
                      text:
                          '${homeController.reviewsModelData?.reviews?.length ?? 0} reviews',
                      fontSize: .017,
                      fontWeight: FontWeight.w500,
                    ),
                    const CustomSizedBox(height: .023),
                    _buildFilterRow(),
                    const CustomSizedBox(height: .023),
                    homeController.reviewsModelData?.reviews?.isEmpty == true
                        ? const Center(
                            child: CustomPadding(
                                top: .25,
                                child: CustomText(text: 'No reviews found')))
                        : Expanded(
                            child: homeController
                                        .reviewsModelData?.reviews?.isEmpty ==
                                    true
                                ? const Center(
                                    child: CustomText(
                                        text: 'No reviews for this rating.'),
                                  )
                                : ListView.builder(
                                    itemCount: homeController.reviewsModelData
                                            ?.reviews?.length ??
                                        0,
                                    itemBuilder: (_, index) {
                                      final review = homeController
                                          .reviewsModelData?.reviews?[index];
                                      return _ReviewCard(review: review);
                                    },
                                  ),
                          ),
                  ],
                ),
              ),
      );
    });
  }

  Widget _buildFilterRow() {
    final filters = ['All', '5', '4', '3'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: filters
          .map(
            (label) => _RatingChip(
              text: label,
              selected: label == 'All'
                  ? _selectedRating == null
                  : _selectedRating == int.parse(label),
              onTap: () =>
                  _onFilterTap(label == 'All' ? null : int.parse(label)),
            ),
          )
          .toList(),
    );
  }
}

class _RatingChip extends StatelessWidget {
  const _RatingChip({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: Sizes.height * 0.0075,
          horizontal: Sizes.width * 0.07,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: selected ? const Color(0xFFEAF3FF) : AppColors.tWhiteColor,
          border: Border.all(
            color: selected ? const Color(0xFF2B75CB) : const Color(0xFFBFBFBF),
          ),
        ),
        child: Row(
          children: [
            CustomText(
              text: text,
              fontWeight: FontWeight.w500,
              fontSize: 0.018,
            ),
            if (text != 'All') ...[
              const SizedBox(width: 4),
              Icon(
                Icons.star,
                color: AppColors.tPrimaryColor,
                size: Sizes.height * 0.018,
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final Review? review;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: Sizes.height * 0.025),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: Sizes.height * 0.08,
                width: Sizes.height * 0.08,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: (review?.user?.profilePicture == null ||
                        review?.user?.profilePicture?.isEmpty == true)
                    ? CircleAvatar(
                        backgroundColor: AppColors.tPrimaryColor,
                        child: CustomText(
                          text: (review?.user?.name?.isNotEmpty ?? false)
                              ? (review?.user?.name?[0].toUpperCase() ?? 'U')
                              : 'U',
                          fontSize: 0.024,
                          fontWeight: FontWeight.w600,
                          color: AppColors.tWhiteColor,
                        ),
                      )
                    : ClipOval(
                        child: CustomNetworkImage(
                          url: review?.user?.profilePicture ?? '',
                          // 'https://toppng.com/uploads/preview/veg-non-veg-plate-of-food-11562983570pkk1qzqvhy.png',
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
              const CustomSizedBox(width: .03),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: review?.user?.name ?? '',
                    fontSize: 0.018,
                    color: AppColors.tBlackColor,
                    fontWeight: FontWeight.w600,
                  ),
                  const CustomSizedBox(height: .008),
                  Row(
                    children: [
                      CustomText(
                        text: review?.rating?.toString() ?? '0',
                        fontWeight: FontWeight.w500,
                        fontSize: 0.016,
                        color: AppColors.hintTclr,
                      ),
                      CustomPadding(
                        left: 0.02,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            final rating = review?.rating ?? 0.0;
                            IconData iconData;
                            if (rating >= index + 1) {
                              // Full star
                              iconData = Icons.star;
                            } else if (rating > index) {
                              // Half star
                              iconData = Icons.star_half;
                            } else {
                              // Empty star
                              iconData = Icons.star_border;
                            }
                            return CustomPadding(
                              right: 0.002,
                              child: Icon(iconData,
                                  size: 16, color: AppColors.tPrimaryColor),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const CustomSizedBox(height: .015),
          // const CustomText(
          //   text: "Delicious & Authentic!",
          //   fontSize: 0.016,
          //   color: AppColors.tBlackColor,
          //   fontWeight: FontWeight.w600,
          // ),
          // const CustomSizedBox(height: .011),
          CustomText(
            textAlign: TextAlign.start,
            text: review?.review ?? '',
            // 'The South Indian meals from Sri Krishna are just like home. The sambar and chutney tasted amazing. Will definitely order again!',
            // "The South Indian meals from Sri Krishna are just like home. The sambar and chutney tasted amazing. Will definitely order again!",
            fontSize: 0.016,
            color: AppColors.hintTclr,
            fontWeight: FontWeight.w500,
          ),
        ],
      ),
    );
  }
}

class _Review {
  final String name;
  final int rating;
  final String comment;
  final String avatar;

  const _Review({
    required this.name,
    required this.rating,
    required this.comment,
    required this.avatar,
  });
}
