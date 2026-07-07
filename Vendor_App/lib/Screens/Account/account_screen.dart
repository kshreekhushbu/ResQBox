import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:resqboxvendor/Screens/Account/legaldocuments.dart';
import 'package:resqboxvendor/Screens/Auth/login_screen.dart';
import 'package:resqboxvendor/Utils/shared_preference_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:resqboxvendor/Controller/KitchenProfileController.dart';
import 'package:resqboxvendor/Screens/Account/buzz_sound_time_setting.dart';
import 'package:resqboxvendor/Screens/Account/change_password_screen.dart';
import 'package:resqboxvendor/Screens/Account/documents.dart';
import 'package:resqboxvendor/Screens/Account/help_and_support.dart';
import 'package:resqboxvendor/Screens/Account/kitchen_details.dart';
import 'package:resqboxvendor/Screens/Account/team.dart';
import 'package:resqboxvendor/Screens/Notifications/notification_screen.dart';
import 'package:resqboxvendor/Utils/access_helper.dart';
import 'package:resqboxvendor/Utils/colors.dart';
import 'package:resqboxvendor/Utils/custom_alert.dart';
import 'package:resqboxvendor/Utils/custom_appbar.dart';

import 'package:resqboxvendor/Utils/images.dart';
import 'package:resqboxvendor/Utils/navigations.dart';
import 'package:resqboxvendor/Utils/textstyles.dart';
import 'package:resqboxvendor/Controller/NotificationController.dart';
import 'package:resqboxvendor/Widgets/access_denied_dialog.dart';
import 'package:resqboxvendor/Utils/toast.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  @override
  void initState() {
    super.initState();
    final controller = Provider.of<KitchenProfileController>(
      context,
      listen: false,
    );
    controller.getKitchenDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff3f4f8),
      appBar: CustomAppBar(title: "Account", isLeading: false),
      body: SafeArea(
        child: Consumer<KitchenProfileController>(
          builder: (context, controller, child) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () {
                        _checkAccessAndExecute(() {
                          NavigateTo().nextPage(child: KitchenDetails());
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            // Profile Picture
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.mainAppColr,
                                  width: 1.5,
                                ),
                              ),
                              child: ClipOval(
                                child:
                                    controller
                                            .kitchenDetails
                                            ?.photos
                                            ?.kitchenProfilePhoto !=
                                        null
                                    ? Image.network(
                                        controller
                                            .kitchenDetails!
                                            .photos!
                                            .kitchenProfilePhoto!,
                                        height: 60,
                                        width: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                _buildInitialAvatar(
                                                  controller
                                                          .kitchenDetails
                                                          ?.kitchenName ??
                                                      "K",
                                                ),
                                      )
                                    : _buildInitialAvatar(
                                        controller
                                                .kitchenDetails
                                                ?.kitchenName ??
                                            "K",
                                      ),
                              ),
                            ),

                            const SizedBox(width: 16),

                            // DETAILS SECTION
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          controller
                                                  .kitchenDetails
                                                  ?.kitchenName ??
                                              "N/A",
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTextStyles.size16SemiBold
                                              .copyWith(
                                                color: const Color(0xff000000),
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xffD5FFE2),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Row(
                                          children: const [
                                            Icon(
                                              Icons.verified,
                                              size: 14,
                                              color: Color(0xff14B044),
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              "Verified",
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w400,
                                                color: Color(0xff14B044),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    controller.kitchenDetails?.address?.city ??
                                        controller
                                            .kitchenDetails
                                            ?.address
                                            ?.street ??
                                        "N/A",
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.size14Medium.copyWith(
                                      color: const Color(0xff777777),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 8),
                            SvgPicture.asset(
                              AppImages.chveronIcon,
                              height: 22,
                              width: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 8),

                          SizedBox(height: 8),
                          _buildOption(
                            onTap: () {
                              _checkAccessAndExecute(() {
                                NavigateTo().nextPage(child: HelpAndSupport());
                              });
                            },
                            svgAsset: AppImages.customerCare,
                            title: "Help Center",
                          ),
                          SizedBox(height: 8),

                          //_divider(),
                          // SizedBox(height: 4),

                          // _buildOption(
                          //   onTap: () {
                          //     _checkAccessAndExecute(() {
                          //       // NavigateTo().nextPage(child: BankAccount());
                          //     });
                          //   },
                          //   svgAsset: AppImages.bankAccount,
                          //   title: "Bank Account",
                          // ),
                          // SizedBox(height: 8),
                          Consumer<NotificationController>(
                            builder: (context, controller, child) {
                              return _buildOption(
                                onTap: () {
                                  _checkAccessAndExecute(() {
                                    NavigateTo().nextPage(
                                      child: NotificationScreen(),
                                    );
                                  });
                                },
                                svgAsset: controller.hasUnreadNotifications
                                    ? AppImages.notiifcation
                                    : AppImages.nonReadNotification,
                                title: "Notifications",
                              );
                            },
                          ),

                          SizedBox(height: 8),

                          Consumer<KitchenProfileController>(
                            builder: (context, controller, child) {
                              return _buildOption(
                                onTap: () async {
                                  _checkAccessAndExecute(() async {
                                    final url = controller
                                        .kitchenDetails
                                        ?.stripeDashBoardUrl;
                                    if (url != null && url.isNotEmpty) {
                                      if (await canLaunchUrl(Uri.parse(url))) {
                                        await launchUrl(
                                          Uri.parse(url),
                                          mode: LaunchMode.externalApplication,
                                        );
                                      } else {
                                        customToast(
                                          message: "Could not launch dashboard",
                                        );
                                      }
                                    } else {
                                      customToast(
                                        message:
                                            "Stripe dashboard URL not available",
                                      );
                                    }
                                  });
                                },
                                svgAsset: AppImages.stripepng,
                                title: "Earnings Dashboard",
                              );
                            },
                          ),

                          SizedBox(height: 8),
                          //_divider(),
                          SizedBox(height: 8),
                          _buildOption(
                            onTap: () {
                              _checkAccessAndExecute(() {
                                NavigateTo().nextPage(child: MyTeam());
                              });
                            },
                            svgAsset: AppImages.team,
                            title: "My Team",
                          ),

                          // SizedBox(height: 8),

                          //_divider(),
                          SizedBox(height: 8),
                          _buildOption(
                            onTap: () {
                              _checkAccessAndExecute(() {
                                NavigateTo().nextPage(child: DocumentsScreen());
                              });
                            },
                            svgAsset: AppImages.documents,
                            title: "Documents",
                          ),

                          SizedBox(height: 8),
                          _buildOption(
                            onTap: () {
                              // _checkAccessAndExecute(() {

                              // });
                              NavigateTo().nextPage(
                                child: ChangePasswordScreen(),
                              );
                            },
                            svgAsset: AppImages.chnagePasswordSvg,
                            title: "Change Password",
                          ),

                          SizedBox(height: 8),

                          _buildOption(
                            onTap: () async {
                              // const url =
                              //     'https://www.resqboxfood.com/privacy-policy';
                              // if (await canLaunchUrl(Uri.parse(url))) {
                              //   await launchUrl(
                              //     Uri.parse(url),
                              //     mode: LaunchMode.externalApplication,
                              //   );
                              // }
                              NavigateTo().nextPage(child: LegalDocuments());
                            },
                            svgAsset: AppImages.privacyPolicy,
                            title: "Legal",
                          ),

                          // SizedBox(height: 8),
                          // _buildOption(
                          //   onTap: () async {
                          //     const url =
                          //         'https://www.resqboxfood.com/vendor-terms';
                          //     if (await canLaunchUrl(Uri.parse(url))) {
                          //       await launchUrl(
                          //         Uri.parse(url),
                          //         mode: LaunchMode.externalApplication,
                          //       );
                          //     }
                          //   },
                          //   svgAsset: AppImages.terms,
                          //   title: "Terms & Conditions",
                          // ),
                          SizedBox(height: 8),
                          _buildOption(
                            onTap: () {
                              _checkAccessAndExecute(() {
                                NavigateTo().nextPage(
                                  child: BuzzSoundTimeSetting(),
                                );
                              });
                            },
                            svgAsset: AppImages.settings,
                            title: "Settings",
                          ),

                          // SizedBox(height: 8),
                          SizedBox(height: 8),
                          _buildOption(
                            onTap: () {
                              // _checkAccessAndExecute(() {
                              //   // NavigateTo().nextPage(
                              //   //   child: DeleteAccountScreen(),
                              //   // );
                              // });

                              showAlertDialog(
                                context: context,
                                title: "Delete Account",
                                content:
                                    "Are you sure you want to delete your account?",
                                onPressed: () async {
                                  final prefernce =
                                      await SharedPreferencesHelper.getInstance();
                                  await prefernce.clearAlldata();
                                  NavigateTo().pushRemove(child: LoginScreen());
                                },
                              );
                            },
                            svgAsset: AppImages.deleteAccount,
                            title: "Delete Account",
                          ),

                          // SizedBox(height: 8),

                          //_divider(),
                          SizedBox(height: 8),

                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: InkWell(
                              onTap: () {
                                showAlertDialog(context: context);
                              },
                              child: Row(
                                children: [
                                  SvgPicture.asset(AppImages.logout),
                                  SizedBox(width: 16),
                                  Text(
                                    "Logout",
                                    style: AppTextStyles.size14SemiBold
                                        .copyWith(color: AppColors.mainAppColr),
                                  ),
                                  Spacer(),
                                  SvgPicture.asset(
                                    AppImages.chveronIcon,
                                    height: 22,
                                    width: 22,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInitialAvatar(String? kitchenName) {
    final String initial = (kitchenName?.isNotEmpty ?? false)
        ? kitchenName!.trim()[0].toUpperCase()
        : "N/A";

    return Container(
      height: 70,
      width: 70,
      decoration: BoxDecoration(
        color: AppColors.mainAppColr.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: AppTextStyles.size24SemiBold.copyWith(
            color: AppColors.mainAppColr,
          ),
        ),
      ),
    );
  }

  // Helper method to check access before executing action
  Future<void> _checkAccessAndExecute(VoidCallback action) async {
    final isTeamMember = await AccessHelper.isTeamMember();
    if (isTeamMember) {
      if (mounted) {
        AccessDeniedDialog.show(context);
      }
    } else {
      action();
    }
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
