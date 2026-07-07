import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:resqboxvendor/Controller/KitchenProfileController.dart';
import 'package:resqboxvendor/Screens/Account/about_edit.dart';
import 'package:resqboxvendor/Screens/Account/info_edit.dart';
import 'package:resqboxvendor/Screens/Account/update_location_picker.dart';
import 'package:resqboxvendor/Utils/colors.dart';
import 'package:resqboxvendor/Utils/custom_appbar.dart';
import 'package:resqboxvendor/Utils/custom_border_btn.dart';
import 'package:resqboxvendor/Utils/images.dart';
import 'package:resqboxvendor/Utils/navigations.dart';
import 'package:resqboxvendor/Utils/textstyles.dart';

class KitchenDetails extends StatefulWidget {
  const KitchenDetails({super.key});

  @override
  State<KitchenDetails> createState() => _KitchenDetailsState();
}

class _KitchenDetailsState extends State<KitchenDetails>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final controller = Provider.of<KitchenProfileController>(
      context,
      listen: false,
    );
    controller.getKitchenDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<KitchenProfileController>(
      builder: (context, controller, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: CustomAppBar(
            title: controller.kitchenDetails?.kitchenName ?? "N/A",
            isLeading: true,
            backTap: () {
              NavigateTo().backPage();
            },
          ),
          body: NestedScrollView(
            headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
              return <Widget>[
                // Header Image Section
                SliverToBoxAdapter(
                  child: Consumer<KitchenProfileController>(
                    builder: (context, controller, child) {
                      final headerImage =
                          controller
                                  .kitchenDetails
                                  ?.photos
                                  ?.kitchenImages
                                  ?.isNotEmpty ==
                              true
                          ? controller.kitchenDetails!.photos!.kitchenImages![0]
                          : null;
                      return Stack(
                        children: [
                          headerImage != null
                              ? Image.network(
                                  headerImage,
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: double.infinity,
                                      height: 200,
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.image,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  width: double.infinity,
                                  height: 200,
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.image,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                ),
                          // Positioned(
                          //   bottom: 16,
                          //   right: 16,
                          //   child: Container(
                          //     padding: const EdgeInsets.all(8),
                          //     decoration: BoxDecoration(
                          //       color: Colors.black.withOpacity(0.5),
                          //       borderRadius: BorderRadius.circular(50),
                          //     ),
                          //     child: Image.asset(AppImages.camera),
                          //   ),
                          // ),
                        ],
                      );
                    },
                  ),
                ),

                // Restaurant Info Card
                SliverToBoxAdapter(
                  child: Consumer<KitchenProfileController>(
                    builder: (context, controller, child) {
                      final kitchen = controller.kitchenDetails;
                      // final openingTime = kitchen?.openingTime ?? "00:00";
                      // final closingTime = kitchen?.closingTime ?? "00:00";
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              child: ClipOval(
                                child:
                                    kitchen?.photos?.kitchenProfilePhoto != null
                                    ? Image.network(
                                        kitchen!.photos!.kitchenProfilePhoto!,
                                        height: 80,
                                        width: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                                  height: 80,
                                                  width: 80,
                                                  color: Colors.grey[300],
                                                  child: const Icon(
                                                    Icons.store,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                      )
                                    : Image.asset(
                                        "Assets/Account/storeprofile.png",
                                        height: 80,
                                        width: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                                  height: 80,
                                                  width: 80,
                                                  color: Colors.grey[300],
                                                  child: const Icon(
                                                    Icons.store,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          kitchen?.kitchenName ?? 'N/A',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTextStyles.size16SemiBold,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      CustomRectBtn(
                                        onTap: () {
                                          NavigateTo().nextPage(
                                            child: InfoEditScreen(),
                                          );
                                        },
                                        height: 25,
                                        borderRadius: 4,
                                        width: 70,
                                        leading: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              "Edit",
                                              style: AppTextStyles.size12Regular
                                                  .copyWith(
                                                    color: Colors.black,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        color: Colors.white,
                                        borderColor: const Color(0xffFE5E00),
                                        textColor: Colors.black,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  // Text(
                                  //   kitchen?.ownerName ?? 'Sree Leela',
                                  //   style: AppTextStyles.size14Medium.copyWith(
                                  //     color: const Color(0xff777777),
                                  //   ),
                                  // ),
                                  // const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      SvgPicture.asset(AppImages.avgRating),
                                      SizedBox(width: 6),
                                      Text(
                                        controller.kitchenDetails?.rating ??
                                            "0.0",
                                        style: AppTextStyles.size14Medium
                                            .copyWith(
                                              color: const Color(0xff4B5563),
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Sticky TabBar
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickyTabBarDelegate(
                    TabBar(
                      controller: _tabController,
                      labelColor: const Color(0xff212121),
                      unselectedLabelColor: const Color(0xff777777),
                      labelStyle: AppTextStyles.size16SemiBold,
                      unselectedLabelStyle: AppTextStyles.size14Medium.copyWith(
                        fontWeight: FontWeight.normal,
                      ),
                      indicatorColor: Colors.orange[700],
                      indicatorWeight: 2,
                      tabs: const [
                        Tab(text: 'About'),
                        Tab(text: 'Photos'),
                        Tab(text: 'Reviews'),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [_buildAboutTab(), _buildPhotos(), _buildReview()],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAboutTab() {
    return Consumer<KitchenProfileController>(
      builder: (context, controller, child) {
        final kitchen = controller.kitchenDetails;
        final address = kitchen?.address;

        String fullAddress = '';
        if (address != null) {
          final addressParts = [
            // if (address.houseNo != null && address.houseNo!.isNotEmpty)
            //   address.houseNo,
            if (address.street != null && address.street!.isNotEmpty)
              address.street,
            if (address.city != null && address.city!.isNotEmpty) address.city,
            if (address.state != null && address.state!.isNotEmpty)
              address.state,
            if (address.country != null && address.country!.isNotEmpty)
              address.country,
            if (address.pincode != null && address.pincode!.isNotEmpty)
              address.pincode,
          ].where((part) => part != null && part.isNotEmpty).join(', ');
          fullAddress = addressParts.isNotEmpty ? addressParts : 'N/A';
        } else {
          fullAddress = 'N/A';
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chef Section
              // Row(
              //   children: [
              //     CircleAvatar(
              //       radius: 28,
              //       backgroundImage: kitchen?.photos?.chefProfilePhoto != null
              //           ? NetworkImage(kitchen!.photos!.chefProfilePhoto!)
              //           : null,
              //       child: kitchen?.photos?.chefProfilePhoto == null
              //           ? const Icon(Icons.person, size: 28)
              //           : null,
              //     ),
              //     const SizedBox(width: 12),
              //     Column(
              //       crossAxisAlignment: CrossAxisAlignment.start,
              //       children: [
              //         Text(
              //           kitchen?.ownerName ?? 'Sree Leela',
              //           style: AppTextStyles.size16Medium.copyWith(
              //             color: Colors.black,
              //           ),
              //         ),
              //         Text(
              //           'Chef/Kitchen owner',
              //           style: AppTextStyles.size14Medium.copyWith(
              //             color: const Color(0xff777777),
              //           ),
              //         ),
              //       ],
              //     ),
              //   ],
              // ),

              // const SizedBox(height: 12),
              // Divider(color: Color(0xffDDDDDD)),
              // const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('About', style: AppTextStyles.size16SemiBold),
                  CustomRectBtn(
                    onTap: () {
                      NavigateTo().nextPage(child: AboutEditScreen());
                    },
                    height: 25,
                    borderRadius: 4,
                    width: 70,
                    leading: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Edit",
                          style: AppTextStyles.size12Regular.copyWith(
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    color: Colors.white,
                    borderColor: const Color(0xffFE5E00),
                    textColor: Colors.black,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Text(
                kitchen?.description ??
                    'Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting.',
                style: AppTextStyles.size14Medium.copyWith(
                  color: const Color(0xff777777),
                  height: 1.5,
                ),
              ),

              // const SizedBox(height: 12),
              // Divider(color: Color(0xffDDDDDD)),
              // const SizedBox(height: 12),

              // Row(
              //   children: [
              //     Image.asset(AppImages.fssai),
              //     const SizedBox(width: 12),
              //     Text(
              //       'License no ${kitchen?.kyc?.fssaiNumber ?? "12345678990987"}',
              //       style: AppTextStyles.size14Medium.copyWith(
              //         color: const Color(0xff777777),
              //       ),
              //     ),
              //   ],
              // ),
              const SizedBox(height: 12),
              Divider(color: Color(0xffDDDDDD)),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    kitchen?.ownerName ?? 'N/A',
                    style: AppTextStyles.size14Medium,
                  ),
                  CustomRectBtn(
                    onTap: () {
                      final lat = kitchen?.address?.latitude;
                      final lng = kitchen?.address?.longitude;
                      NavigateTo().nextPage(
                        child: UpdateLocationPickerScreen(
                          initialLatitude: lat,
                          initialLongitude: lng,
                          initialHouseNo: kitchen?.address?.houseNo,
                          initialStreet: kitchen?.address?.street,
                          initialCity: kitchen?.address?.city,
                          initialState: kitchen?.address?.state,
                          initialCountry: kitchen?.address?.country,
                          initialPincode: kitchen?.address?.pincode,
                        ),
                      );
                    },
                    height: 25,
                    borderRadius: 4,
                    width: 70,
                    leading: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Edit",
                          style: AppTextStyles.size12Regular.copyWith(
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    color: Colors.white,
                    borderColor: const Color(0xffFE5E00),
                    textColor: Colors.black,
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                address?.landmark ?? address?.street ?? 'N/A',
                style: AppTextStyles.size12Medium.copyWith(
                  color: const Color(0xff4B5563),
                ),
              ),

              const SizedBox(height: 8),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 24,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      fullAddress,
                      style: AppTextStyles.size12Medium.copyWith(
                        color: const Color(0xff4B5563),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "ACN : ${controller.kitchenDetails?.kyc?.acn ?? "N/A"}",
                      style: AppTextStyles.size14Medium.copyWith(
                        color: const Color(0xff777777),
                        height: 1.5,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "ABN : ${controller.kitchenDetails?.kyc?.abnNumber ?? "N/A"}",
                      style: AppTextStyles.size14Medium.copyWith(
                        color: const Color(0xff777777),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhotos() {
    return Consumer<KitchenProfileController>(
      builder: (context, controller, child) {
        final kitchenImages =
            controller.kitchenDetails?.photos?.kitchenImages ?? [];
        final itemCount = kitchenImages.isNotEmpty ? kitchenImages.length : 9;

        return Column(
          children: [
            Expanded(
              child: GridView.builder(
                itemCount: itemCount,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 3,
                  mainAxisSpacing: 3,
                ),
                itemBuilder: (context, index) {
                  if (kitchenImages.isNotEmpty &&
                      index < kitchenImages.length) {
                    return Image.network(
                      kitchenImages[index],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: Icon(Icons.image, color: Colors.grey),
                        );
                      },
                    );
                  } else {
                    return Image.network(
                      "https://images.unsplash.com/photo-1606787366850-de6330128bfc?w=800&q=80",
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: Icon(Icons.image, color: Colors.grey),
                        );
                      },
                    );
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Consumer<KitchenProfileController>(
                builder: (context, controller, child) {
                  return CustomRectBtn(
                    onTap: () {
                      _showPhotosBottomSheet(context, controller);
                    },
                    height: 49,
                    borderRadius: 25,
                    width: double.infinity,
                    leading: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(AppImages.camera),
                        SizedBox(width: 5),
                        Text(
                          "Add Photos",
                          style: AppTextStyles.size16SemiBold.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    color: Color(0xff00D341),
                    borderColor: Color(0xff00D341),
                    textColor: Colors.white,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReview() {
    return Consumer<KitchenProfileController>(
      builder: (context, controller, child) {
        final reviews = controller.kitchenDetails?.reviews ?? [];

        return Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("User Reviews", style: AppTextStyles.size16SemiBold),
                  if (reviews.length > 5)
                    Text(
                      "See All",
                      style: AppTextStyles.size14Medium.copyWith(
                        color: AppColors.mainAppColr,
                      ),
                    ),
                ],
              ),
              SizedBox(height: 16),
              Expanded(
                child: reviews.isEmpty
                    ? Center(
                        child: Text(
                          "No Reviews Yet",
                          style: AppTextStyles.size14Medium.copyWith(
                            color: Color(0xff777777),
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: reviews.length,
                        itemBuilder: (context, index) {
                          final review = reviews[index];
                          return Container(
                            margin: EdgeInsets.only(bottom: 16),
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Color(0xffE2E2E2)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundImage:
                                          review.user?.profilePicture != null &&
                                              review
                                                  .user!
                                                  .profilePicture!
                                                  .isNotEmpty
                                          ? NetworkImage(
                                              review.user!.profilePicture!,
                                            )
                                          : null,
                                      child:
                                          review.user?.profilePicture == null ||
                                              review
                                                  .user!
                                                  .profilePicture!
                                                  .isEmpty
                                          ? _buildInitialAvatar(
                                              review.user?.name,
                                            )
                                          : null,
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            review.user?.name ?? "Anonymous",
                                            style: AppTextStyles.size16SemiBold,
                                          ),
                                          SizedBox(height: 4),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Text(
                                                "${review.rating ?? "0"}.0",
                                                style: AppTextStyles
                                                    .size12SemiBold
                                                    .copyWith(
                                                      color: Color(0xff777777),
                                                    ),
                                              ),
                                              SizedBox(width: 8),
                                              Row(
                                                children: List.generate(5, (
                                                  starIndex,
                                                ) {
                                                  final ratingValue =
                                                      double.tryParse(
                                                        review.rating ?? "0",
                                                      ) ??
                                                      0.0;
                                                  final isFilled =
                                                      starIndex <
                                                      ratingValue.round();
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          right: 2,
                                                        ),
                                                    child: Image.asset(
                                                      AppImages.reviewStar,
                                                      height: 14,
                                                      width: 14,
                                                      fit: BoxFit.contain,
                                                      color: isFilled
                                                          ? null
                                                          : Colors.grey[300],
                                                      colorBlendMode: isFilled
                                                          ? null
                                                          : BlendMode.modulate,
                                                    ),
                                                  );
                                                }),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (review.review != null &&
                                    review.review!.isNotEmpty) ...[
                                  SizedBox(height: 8),
                                  Text(
                                    review.review!,
                                    style: AppTextStyles.size14Regular.copyWith(
                                      color: Color(0xff777777),
                                    ),
                                  ),
                                ],
                                // if (review.createdAt != null) ...[
                                //   SizedBox(height: 8),
                                //   Text(
                                //     _formatReviewDate(review.createdAt!),
                                //     style: AppTextStyles.size12Regular.copyWith(
                                //       color: Color(0xff999999),
                                //     ),
                                //   ),
                                // ],
                                // SizedBox(height: 8),
                                // Align(
                                //   alignment: Alignment.centerRight,
                                //   child: CustomRectBtn(
                                //     onTap: () {},
                                //     height: 35,
                                //     borderRadius: 8,
                                //     width: 75,
                                //     text: "Report",
                                //     // leading: Center(
                                //     //   child: Text(
                                //     //     "Report",
                                //     //     textAlign: TextAlign.center,
                                //     //     overflow: TextOverflow.ellipsis,
                                //     //     style: AppTextStyles.size12SemiBold
                                //     //         .copyWith(color: Color(0xffF85757)),
                                //     //   ),
                                //     // ),
                                //     color: Colors.white,
                                //     fontSize: 12,
                                //     borderColor: const Color(0xffE2E2E2),
                                //     textColor: Color(0xffF85757),
                                //   ),
                                // ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInitialAvatar(String? name) {
    final String initial = (name?.isNotEmpty ?? false)
        ? name!.trim()[0].toUpperCase()
        : "A";
    return Container(
      decoration: BoxDecoration(
        color: AppColors.mainAppColr.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: AppTextStyles.size16SemiBold.copyWith(
            color: AppColors.mainAppColr,
          ),
        ),
      ),
    );
  }

  // String _formatReviewDate(String dateTime) {
  //   try {
  //     final dt = DateTime.parse(dateTime);
  //     final now = DateTime.now();
  //     final difference = now.difference(dt);

  //     if (difference.inDays == 0) {
  //       if (difference.inHours == 0) {
  //         if (difference.inMinutes == 0) {
  //           return "Just now";
  //         }
  //         return "${difference.inMinutes}m ago";
  //       }
  //       return "${difference.inHours}h ago";
  //     } else if (difference.inDays == 1) {
  //       return "Yesterday";
  //     } else if (difference.inDays < 7) {
  //       return "${difference.inDays}d ago";
  //     } else if (difference.inDays < 30) {
  //       final weeks = (difference.inDays / 7).floor();
  //       return "${weeks}w ago";
  //     } else if (difference.inDays < 365) {
  //       final months = (difference.inDays / 30).floor();
  //       return "${months}mo ago";
  //     } else {
  //       final years = (difference.inDays / 365).floor();
  //       return "${years}y ago";
  //     }
  //   } catch (e) {
  //     return dateTime;
  //   }
  // }

  void _showPhotosBottomSheet(
    BuildContext context,
    KitchenProfileController controller,
  ) {
    // Extract existing image URLs and filenames
    final existingImageUrls =
        controller.kitchenDetails?.photos?.kitchenImages ?? [];

    // Track which images to keep (by index)
    final Set<int> imagesToKeep = Set.from(
      Iterable.generate(existingImageUrls.length),
    );
    // Track newly selected images
    List<File> selectedImages = List.from(controller.selectedKitchenImages);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Manage Photos",
                          style: AppTextStyles.size20SemiBold,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),

                  // Images Grid
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1,
                            ),
                        itemCount:
                            existingImageUrls.length +
                            selectedImages.length +
                            1,
                        itemBuilder: (context, index) {
                          // First item: Add folder icon
                          if (index == 0) {
                            return GestureDetector(
                              onTap: () {
                                // Custom bottom sheet for Camera/Gallery with Multi-picker support for Gallery
                                showModalBottomSheet(
                                  context: context,
                                  builder: (ctx) => Wrap(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(16),
                                            topRight: Radius.circular(16),
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          children: [
                                            Text(
                                              'Select Image to Upload',
                                              style:
                                                  AppTextStyles.size16SemiBold,
                                            ),
                                            const SizedBox(height: 10),
                                            ListTile(
                                              leading: const Icon(
                                                Icons.camera_alt,
                                              ),
                                              title: const Text("Camera"),
                                              onTap: () async {
                                                Navigator.pop(ctx);
                                                final file = await controller
                                                    .pickImageFromCamera();
                                                if (file != null) {
                                                  setState(() {
                                                    selectedImages.add(file);
                                                    controller
                                                            .selectedKitchenImages =
                                                        List.from(
                                                          selectedImages,
                                                        );
                                                  });
                                                }
                                              },
                                            ),
                                            ListTile(
                                              leading: const Icon(
                                                Icons.photo_library,
                                              ),
                                              title: const Text("Gallery"),
                                              onTap: () async {
                                                Navigator.pop(ctx);
                                                await controller
                                                    .pickKitchenImages();
                                                // Append newly picked images to existing selection
                                                if (controller
                                                    .selectedKitchenImages
                                                    .isNotEmpty) {
                                                  // Identify truly new files (not already in selectedImages)
                                                  // Since pickKitchenImages replaces controller list, we merged them.
                                                  // Wait, pickKitchenImages REPLACES selectedKitchenImages in controller.
                                                  // So we need to take those and ADD to our local `selectedImages`.

                                                  // However, controller.pickKitchenImages() updates controller.selectedKitchenImages directly.
                                                  // We should grab those, add to our local list, and then update controller back.

                                                  final newFiles = controller
                                                      .selectedKitchenImages;
                                                  setState(() {
                                                    selectedImages.addAll(
                                                      newFiles,
                                                    );
                                                    // Update controller with FULL list
                                                    controller
                                                            .selectedKitchenImages =
                                                        List.from(
                                                          selectedImages,
                                                        );
                                                  });
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 2,
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.folder,
                                      size: 40,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Add Photos",
                                      style: AppTextStyles.size12Medium
                                          .copyWith(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          // Existing images (index 1 to existingImageUrls.length)
                          if (index <= existingImageUrls.length) {
                            final imageIndex = index - 1;
                            final imageUrl = existingImageUrls[imageIndex];
                            final isRemoved = !imagesToKeep.contains(
                              imageIndex,
                            );

                            return Stack(
                              children: [
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isRemoved
                                            ? Colors.red
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Opacity(
                                        opacity: isRemoved ? 0.5 : 1.0,
                                        child: Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return Container(
                                                  color: Colors.grey[300],
                                                  child: const Icon(
                                                    Icons.image,
                                                    color: Colors.grey,
                                                  ),
                                                );
                                              },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (isRemoved) {
                                          imagesToKeep.add(imageIndex);
                                        } else {
                                          imagesToKeep.remove(imageIndex);
                                        }
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: isRemoved
                                            ? Colors.green
                                            : Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isRemoved ? Icons.undo : Icons.close,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }

                          // Newly selected images
                          final selectedIndex =
                              index - existingImageUrls.length - 1;
                          final selectedImage = selectedImages[selectedIndex];

                          return Stack(
                            children: [
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.green,
                                      width: 2,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      selectedImage,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey[300],
                                              child: const Icon(
                                                Icons.image,
                                                color: Colors.grey,
                                              ),
                                            );
                                          },
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedImages.removeAt(selectedIndex);
                                      controller.selectedKitchenImages =
                                          List.from(selectedImages);
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),

                  // Upload Button
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: CustomRectBtn(
                      width: double.infinity,
                      onTap: () async {
                        Navigator.pop(context);

                        // Get filenames of images to keep
                        final existingFilenames = existingImageUrls
                            .asMap()
                            .entries
                            .where((entry) => imagesToKeep.contains(entry.key))
                            .map((entry) {
                              final url = entry.value;
                              // Extract filename from URL
                              String cleanUrl = url.trim();
                              final baseUrlPattern =
                                  'https://d39ka8sbzm0rbx.cloudfront.net/kitchen/';
                              while (cleanUrl.startsWith(baseUrlPattern)) {
                                cleanUrl = cleanUrl.substring(
                                  baseUrlPattern.length,
                                );
                              }
                              if (cleanUrl.startsWith('http://') ||
                                  cleanUrl.startsWith('https://')) {
                                final uri = Uri.tryParse(cleanUrl);
                                if (uri != null &&
                                    uri.pathSegments.isNotEmpty) {
                                  cleanUrl = uri.pathSegments.last;
                                }
                              }
                              if (cleanUrl.contains('/')) {
                                cleanUrl = cleanUrl.split('/').last;
                              }
                              return cleanUrl;
                            })
                            .where(
                              (filename) =>
                                  filename.isNotEmpty &&
                                  !filename.startsWith('http'),
                            )
                            .toList();

                        // Upload new images if any
                        List<String> newFilenames = [];
                        if (selectedImages.isNotEmpty) {
                          controller.selectedKitchenImages = List.from(
                            selectedImages,
                          );
                          newFilenames = await controller.uploadMultipleImages(
                            selectedImages,
                          );
                        }

                        // Combine existing and new filenames
                        final updatedImages = [
                          ...existingFilenames,
                          ...newFilenames,
                        ];

                        debugPrint("📤 Images to keep: ${imagesToKeep.length}");
                        debugPrint("📤 Existing filenames: $existingFilenames");
                        debugPrint("📤 New uploaded filenames: $newFilenames");
                        debugPrint(
                          "📤 Combined filenames to send: $updatedImages",
                        );

                        // Update kitchen with images
                        if (updatedImages.isNotEmpty ||
                            selectedImages.isNotEmpty) {
                          final success = await controller.updateKitchen(
                            kitchenImages: updatedImages,
                          );

                          if (success) {
                            controller.selectedKitchenImages = [];
                          }
                        }
                      },
                      height: 49,
                      borderRadius: 8,
                      text: "Upload Photos",
                      color: AppColors.mainAppColr,
                      borderColor: AppColors.mainAppColr,
                      textColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// Delegate for sticky TabBar
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  const _StickyTabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Color(0xffF3F4F8), child: tabBar);
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}
