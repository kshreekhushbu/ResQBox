import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resqbox_user/Controllers/account_controller.dart';
import 'package:resqbox_user/Screens/Authentication/login_screen.dart';
import 'package:resqbox_user/Screens/MainSection/Account/help_and_support.dart';
import 'package:resqbox_user/Screens/MainSection/Account/legal_screen.dart';
import 'package:resqbox_user/Screens/MainSection/Account/my_profile.dart';
import 'package:resqbox_user/Screens/MainSection/Account/notifications_screen.dart';
import 'package:resqbox_user/Screens/MainSection/Account/saved_cards.dart';
import 'package:resqbox_user/Screens/MainSection/Account/wishlist.dart';
import 'package:resqbox_user/Screens/MainSection/bottom_navigation.dart';
import 'package:resqbox_user/Utils/colors.dart';
import 'package:resqbox_user/Utils/custom_appbar.dart';
import 'package:resqbox_user/Utils/custom_image_widget.dart';
import 'package:resqbox_user/Utils/custom_padding.dart';
import 'package:resqbox_user/Utils/custom_sizedbox.dart';
import 'package:resqbox_user/Utils/custom_tap.dart';
import 'package:resqbox_user/Utils/customtext.dart';
import 'package:resqbox_user/Utils/images.dart';
import 'package:resqbox_user/Utils/mediaquery.dart';
import 'package:resqbox_user/Utils/navigations.dart';
import 'package:resqbox_user/Utils/network_image.dart';
import 'package:resqbox_user/Utils/shared_preference_helper.dart';
import 'package:shimmer/shimmer.dart';
import 'package:resqbox_user/Utils/textformfield.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:resqbox_user/Controllers/home_controller.dart';

class Account extends StatefulWidget {
  const Account({super.key});

  @override
  State<Account> createState() => _AccountState();
}

class _AccountState extends State<Account> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Provider.of<AccountController>(context, listen: false)
          .getProfileApi();
      if (mounted) {
        await Provider.of<HomeController>(context, listen: false)
            .getNotificationsApi();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountController>(
        builder: (context, accountController, child) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? result) async {
          if (didPop) {
            return;
          }
          NavigateTo().nextPage(child: BottomNavigation(initialIndex: 0));
        },
        child: Scaffold(
          backgroundColor: const Color(0XFFF6F6F6),
          appBar: CustomAppBar(
            title: "Account",
            titleFontSize: 0.022,
            backgroundColor: AppColors.tWhiteColor,
            backTap: () {
              NavigateTo().nextPage(child: BottomNavigation(initialIndex: 0));
            },
          ),
          body: SingleChildScrollView(
            child: CustomPadding(
              horizontal: .04,
              vertical: .02,
              child: Column(
                children: [
                  accountController.isLoading
                      ? Container(
                          decoration: BoxDecoration(
                            color: AppColors.tWhiteColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: CustomPadding(
                            horizontal: .03,
                            vertical: .015,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Shimmer.fromColors(
                                  baseColor: Colors.grey.shade300,
                                  highlightColor: Colors.grey.shade100,
                                  child: Container(
                                    width: Sizes.height * 0.1,
                                    height: Sizes.height * 0.1,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.grey.shade300,
                                      border: Border.all(
                                          color: AppColors.tPrimaryColor),
                                    ),
                                  ),
                                ),
                                const CustomSizedBox(
                                  width: .04,
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Shimmer.fromColors(
                                        baseColor: Colors.grey.shade300,
                                        highlightColor: Colors.grey.shade100,
                                        child: Container(
                                          height: Sizes.height * 0.02,
                                          width: Sizes.width * 0.35,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade300,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                        ),
                                      ),
                                      CustomSizedBox(
                                        height: .003,
                                      ),
                                      Shimmer.fromColors(
                                        baseColor: Colors.grey.shade300,
                                        highlightColor: Colors.grey.shade100,
                                        child: Container(
                                          height: Sizes.height * 0.015,
                                          width: Sizes.width * 0.28,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade300,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                CustomPadding(
                                  right: .034,
                                  child: Icon(
                                    Icons.arrow_forward_ios_outlined,
                                    color: Color(0XFFA6A6A6),
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : CustomTap(
                          onTap: () {
                            NavigateTo().nextPage(
                                child: MyProfile(
                                    user: accountController
                                        .userDetailsData?.user));
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.tWhiteColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: CustomPadding(
                              horizontal: .03,
                              vertical: .015,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                    width: Sizes.height * 0.1,
                                    height: Sizes.height * 0.1,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: AppColors.tPrimaryColor),
                                    ),
                                    child: (accountController.userDetailsData
                                                    ?.user?.profilePicture ==
                                                null ||
                                            accountController.userDetailsData!
                                                .user!.profilePicture!.isEmpty)
                                        ? CircleAvatar(
                                            backgroundColor: Colors.white,
                                            radius: Sizes.height * 0.04,
                                            child: Icon(
                                              Icons.person,
                                              size: Sizes.height * 0.075,
                                              color: Colors.grey.shade400,
                                            ),
                                          )
                                        : CircleAvatar(
                                            backgroundColor: Colors.transparent,
                                            radius: Sizes.height * 0.04,
                                            child: ClipOval(
                                                child: CustomNetworkImage(
                                              url: accountController
                                                  .userDetailsData!
                                                  .user!
                                                  .profilePicture!,
                                              height: .085,
                                              width: .185,
                                              fit: BoxFit.cover,
                                            )),
                                          ),
                                  ),
                                  const CustomSizedBox(
                                    width: .04,
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CustomText(
                                          text:
                                              "${accountController.userDetailsData?.user?.name} ${accountController.userDetailsData?.user?.lastName}",
                                          fontWeight: FontWeight.w700,
                                          fontSize: .018,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                        CustomSizedBox(
                                          height: .003,
                                        ),
                                        CustomText(
                                          text:
                                              "${accountController.userDetailsData?.user?.email ?? ''}",
                                          fontWeight: FontWeight.w500,
                                          fontSize: .015,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          color: AppColors.hintTclr,
                                        )
                                      ],
                                    ),
                                  ),
                                  CustomPadding(
                                    right: .034,
                                    child: Icon(
                                      Icons.arrow_forward_ios_outlined,
                                      color: Color(0XFFA6A6A6),
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                  // Banner Carousel
                  if ((accountController.userDetailsData?.co2Message != null &&
                          accountController
                              .userDetailsData!.co2Message!.isNotEmpty) ||
                      (accountController.userDetailsData?.discountMessage !=
                              null &&
                          accountController
                              .userDetailsData!.discountMessage!.isNotEmpty))
                    const CustomSizedBox(height: .01),
                  BannerCarousel(
                    messages: [
                      if (accountController.userDetailsData?.co2Message !=
                              null &&
                          accountController
                              .userDetailsData!.co2Message!.isNotEmpty)
                        accountController.userDetailsData!.co2Message!,
                      if (accountController.userDetailsData?.discountMessage !=
                              null &&
                          accountController
                              .userDetailsData!.discountMessage!.isNotEmpty)
                        accountController.userDetailsData!.discountMessage!,
                    ],
                  ),
                  const CustomSizedBox(height: .01),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.tWhiteColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: CustomPadding(
                      vertical: .01,
                      child: Column(
                        children: [
                          profileRow("Wishlist", AppImages.accountWishlist, () {
                            NavigateTo().nextPage(child: const Wishlist());
                          }),
                          const CustomPadding(
                              horizontal: .03,
                              vertical: .005,
                              child:
                                  Divider(color: Color(0XFFE1E1E1), height: 1)),
                          CustomPadding(
                            vertical: 0.018,
                            horizontal: 0.06,
                            child: CustomTap(
                              onTap: () {
                                NavigateTo()
                                    .nextPage(child: const Notifications());
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Row(
                                children: [
                                  // CustomImage(
                                  //   image: AppImages.notification,
                                  //   height: .028,
                                  //   color: AppColors.hintTclr,
                                  // ),
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      CustomImage(
                                        image: AppImages.notification,
                                        height: .028,
                                        color: AppColors.hintTclr,
                                      ),
                                      Consumer<HomeController>(
                                        builder:
                                            (context, homeController, child) {
                                          return (homeController.getNotificationsModelData != null &&
                                                  homeController
                                                          .getNotificationsModelData!
                                                          .count !=
                                                      null &&
                                                  homeController
                                                          .getNotificationsModelData!
                                                          .count! >
                                                      0)
                                              ? Positioned(
                                                  right: -2,
                                                  top: -2,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(4),
                                                    decoration:
                                                        const BoxDecoration(
                                                      color: Color(0XFF00D341),
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                )
                                              : const SizedBox.shrink();
                                        },
                                      ),
                                    ],
                                  ),
                                  Expanded(
                                    child: CustomPadding(
                                      left: 0.04,
                                      child: CustomText(
                                        text: "Notifications",
                                        color: AppColors.tBlackColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 0.018,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios_outlined,
                                    color: Color(0XFFA6A6A6),
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const CustomPadding(
                              horizontal: .03,
                              vertical: .005,
                              child:
                                  Divider(color: Color(0XFFE1E1E1), height: 1)),
                          profileRow("Help Center", AppImages.accountHelp, () {
                            NavigateTo()
                                .nextPage(child: const HelpAndSupport());
                          }),
                          const CustomPadding(
                              horizontal: .03,
                              vertical: .005,
                              child:
                                  Divider(color: Color(0XFFE1E1E1), height: 1)),
                          profileRow("Saved Cards", AppImages.accountCards, () {
                            NavigateTo().nextPage(child: const SavedCards());
                          }),
                        ],
                      ),
                    ),
                  ),
                  const CustomSizedBox(height: .015),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.tWhiteColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: CustomPadding(
                      vertical: .01,
                      child: Column(
                        children: [
                          profileRow("Legal", AppImages.accountPrivacy,
                              () async {
                            NavigateTo().nextPage(child: const LegalScreen());
                          }),
                          const CustomPadding(
                              horizontal: .03,
                              vertical: .005,
                              child:
                                  Divider(color: Color(0XFFE1E1E1), height: 1)),
                          profileRow("Delete account", AppImages.accountDelete,
                              () {
                            _showDeleteAccountDialog();
                          }),
                          const CustomPadding(
                              horizontal: .03,
                              vertical: .005,
                              child:
                                  Divider(color: Color(0XFFE1E1E1), height: 1)),
                          profileRow("Logout", AppImages.accountLogout, () {
                            _showLogoutDialog();
                          }),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  CustomPadding profileRow(String name, String image, VoidCallback onTap) {
    return CustomPadding(
      vertical: 0.018,
      horizontal: 0.06,
      child: CustomTap(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            CustomImage(
              image: image,
              height: .032,
            ),
            Expanded(
              child: CustomPadding(
                left: 0.04,
                child: CustomText(
                  text: name,
                  color: name == "Logout"
                      ? AppColors.tPrimaryColor
                      : AppColors.tBlackColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 0.018,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_outlined,
              color: Color(0XFFA6A6A6),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteReasonDialog() {
    final TextEditingController reasonController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.tWhiteColor,
        surfaceTintColor: AppColors.tWhiteColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: EdgeInsets.zero,
        title: Column(
          children: [
            CustomPadding(
              top: 0.02,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.report_problem_outlined,
                  color: AppColors.red,
                  size: 32,
                ),
              ),
            ),
            const CustomSizedBox(height: 0.015),
            const CustomText(
              text: "Delete Account?",
              fontWeight: FontWeight.w700,
              fontSize: 0.022,
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CustomText(
                text:
                    "Are you sure you want to delete your account? Please let us know why you are leaving.",
                fontSize: 0.015,
                color: AppColors.hintTclr,
                textAlign: TextAlign.center,
              ),
              const CustomSizedBox(height: 0.02),
              CustomTextFormField(
                controller: reasonController,
                hintText: "Reason for deleting...",
                maxLines: 3,
                fillColor: const Color(0XFFF9F9F9),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please enter a reason";
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
        actions: [
          Row(
            children: [
              Expanded(
                child: CustomTap(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0XFFD4D4D4)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: CustomText(
                        text: "Cancel",
                        fontSize: 0.016,
                        fontWeight: FontWeight.w600,
                        color: AppColors.hintTclr,
                      ),
                    ),
                  ),
                ),
              ),
              const CustomSizedBox(width: 0.03),
              Expanded(
                child: CustomTap(
                  onTap: () async {
                    if (formKey.currentState!.validate()) {
                      Navigator.of(context).pop();
                      await Provider.of<AccountController>(context,
                              listen: false)
                          .deleteAccountApi(reasonText: reasonController.text);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: CustomText(
                        text: "Delete",
                        fontSize: 0.016,
                        fontWeight: FontWeight.w700,
                        color: AppColors.tWhiteColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.tWhiteColor,
        surfaceTintColor: AppColors.tWhiteColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const CustomText(
          text: "Delete Account?",
          fontWeight: FontWeight.w700,
          fontSize: 0.02,
        ),
        content: const CustomText(
          text: "Are you sure you want to delete your account?",
          fontSize: 0.016,
          color: AppColors.hintTclr,
        ),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          Row(
            children: [
              Expanded(
                child: CustomTap(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0XFFD4D4D4)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: CustomText(
                        text: "No",
                        fontSize: 0.016,
                        fontWeight: FontWeight.w600,
                        color: AppColors.hintTclr,
                      ),
                    ),
                  ),
                ),
              ),
              const CustomSizedBox(width: 0.03),
              Expanded(
                child: CustomTap(
                  onTap: () {
                    Navigator.of(context).pop();
                    _showDeleteReasonDialog();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: CustomText(
                        text: "Yes",
                        fontSize: 0.016,
                        fontWeight: FontWeight.w700,
                        color: AppColors.tWhiteColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const CustomText(
          text: "Logout?",
          fontWeight: FontWeight.w700,
          fontSize: 0.02,
        ),
        content: const CustomText(
          text: "Are you sure you want to logout from ResQBox Food?",
          fontSize: 0.016,
          color: AppColors.hintTclr,
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const CustomText(
              text: "Stay Logged In",
              fontSize: 0.016,
              fontWeight: FontWeight.w600,
              color: AppColors.hintTclr,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: handle logout action
              SharedPreferencesHelper().remove("ApiToken");
              SharedPreferencesHelper().clearAlldata();
              NavigateTo().pushRemove(child: LoginScreen());
            },
            child: const CustomText(
              text: "Logout",
              fontSize: 0.016,
              fontWeight: FontWeight.w700,
              color: AppColors.tPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class BannerCarousel extends StatefulWidget {
  final List<String> messages;
  const BannerCarousel({super.key, required this.messages});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  late PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;
  static const int _initialPage = 1000;

  @override
  void initState() {
    super.initState();
    _currentPage = _initialPage;
    _pageController = PageController(initialPage: _initialPage);
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant BannerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.messages.length != oldWidget.messages.length) {
      _timer?.cancel();
      _currentPage = _initialPage;

      if (_pageController.hasClients) {
        _pageController.jumpToPage(_initialPage);
      }

      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();

    if (widget.messages.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (!_pageController.hasClients) return;

        _currentPage++;

        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty) return const SizedBox.shrink();

    return SizedBox(
        width: double.infinity,
        height: Sizes.height * 0.16,
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            _currentPage = index;
          },
          itemBuilder: (context, index) {
            final message = widget.messages[index % widget.messages.length];
            return Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CustomImage(
                    image: AppImages.accountBanner,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 15,
                  left: 20,
                  right: 20,
                  child: CustomText(
                    text: message,
                    color: const Color(0XFF038208),
                    fontWeight: FontWeight.w700,
                    fontSize: 0.02,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          },
        ));
  }
}
