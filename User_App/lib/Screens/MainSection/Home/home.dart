import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:resqbox_user/Controllers/account_controller.dart';
import 'package:resqbox_user/Controllers/cart_controller.dart';
import 'package:resqbox_user/Controllers/home_controller.dart';
import 'package:resqbox_user/Models/home_data_model.dart';
import 'package:resqbox_user/Screens/Authentication/guest_login_screen.dart';
import 'package:resqbox_user/Screens/Authentication/login_screen.dart';
import 'package:resqbox_user/Screens/MainSection/Account/notifications_screen.dart';
import 'package:resqbox_user/Screens/MainSection/Account/wishlist.dart';
import 'package:resqbox_user/Screens/MainSection/Home/Menu/menu.dart';
import 'package:resqbox_user/Screens/MainSection/Home/active_see_all.dart';
import 'package:resqbox_user/Screens/MainSection/Home/food_menu_card.dart';
import 'package:resqbox_user/Screens/MainSection/Home/kitchens_list.dart';
import 'package:resqbox_user/Screens/MainSection/Home/kitchens_view_screen.dart';
import 'package:resqbox_user/Screens/MainSection/Home/popular_kitchen_card.dart';
import 'package:resqbox_user/Screens/MainSection/Home/popular_see_all.dart';
import 'package:resqbox_user/Screens/MainSection/Home/search_location.dart';
import 'package:resqbox_user/Screens/MainSection/Home/search_screen.dart';
import 'package:resqbox_user/Screens/MainSection/Home/wishlist_card_screen.dart';
import 'package:resqbox_user/Utils/colors.dart';
import 'package:resqbox_user/Utils/custom_alert.dart';
import 'package:resqbox_user/Utils/custom_image_widget.dart';
import 'package:resqbox_user/Utils/custom_padding.dart';
import 'package:resqbox_user/Utils/network_image.dart';
import 'package:resqbox_user/Utils/custom_sizedbox.dart';
import 'package:resqbox_user/Utils/custom_tap.dart';
import 'package:resqbox_user/Utils/customtext.dart';
import 'package:resqbox_user/Utils/images.dart';
import 'package:resqbox_user/Utils/mediaquery.dart';
import 'package:resqbox_user/Utils/navigations.dart';

import 'package:resqbox_user/Utils/shared_preference_helper.dart';
import 'package:resqbox_user/Utils/toast.dart';
import 'package:shimmer/shimmer.dart';
import 'package:resqbox_user/main.dart';
import 'package:resqbox_user/Screens/MainSection/Home/Widgets/filter_bottom_sheet.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver, RouteAware {
  int _currentNewKitchen = 0;
  bool _locationDialogShown = false;
  BuildContext?
  _locationDialogContext; // Store dialog context to close it properly

  Timer? _messageTimer;
  int _messageIndex = 0;

  void _startMessageTimer() {
    _messageTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _messageIndex++;
        });
        if (_messageIndex >= 2) {
          timer.cancel();
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _startMessageTimer();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final homeController = Provider.of<HomeController>(
        context,
        listen: false,
      );

      // First check location status before trying to get location
      final hasLocation = await homeController.checkLocationStatus();
      final isGpsOn = homeController.isLocationServiceEnabled;

      // Only show dialog if there's a problem (GPS off or permission denied)
      // Don't show during normal loading
      if (!isGpsOn || !hasLocation) {
        await _checkAndShowLocationDialog(homeController);
      }

      // Try to get location (this will request permission if needed)
      await homeController.getCurrentLocation();

      // Check again after getting location (in case permission was denied)
      if (!homeController.isLoadingLocation) {
        await _checkAndShowLocationDialog(homeController);
      }

      // Force refresh Home Page Data (fixes issue where data isn't called on tab switch)
      if (homeController.locLatitude != null &&
          homeController.locLongitude != null) {
        await homeController.fetchHomePageData(
          latitude: homeController.locLatitude!,
          longitude: homeController.locLongitude!,
          forceRefresh: true,
        );
      }

      await Provider.of<CartController>(context, listen: false).getCartApi();
      await Provider.of<HomeController>(
        context,
        listen: false,
      ).getFilterDataApi();
      await Provider.of<HomeController>(
        context,
        listen: false,
      ).getNotificationsApi();

      // Start the persistent periodic check for location/GPS changes
      if (mounted) {
        _checkLocationPeriodically(homeController);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() {
    // Called when the top route has been popped off, and the current route shows up.
    debugPrint("🏠 Home screen visible again - refreshing data");
    final homeController = Provider.of<HomeController>(context, listen: false);
    if (homeController.locLatitude != null &&
        homeController.locLongitude != null) {
      homeController.fetchHomePageData(
        latitude: homeController.locLatitude!,
        longitude: homeController.locLongitude!,
        forceRefresh: true,
      );
      // Also refresh other endpoints if needed
      Provider.of<CartController>(context, listen: false).getCartApi();
      Provider.of<HomeController>(context, listen: false).getNotificationsApi();
    } else {
      homeController.getCurrentLocation(forceRefresh: true);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _messageTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // When app resumes, check location again (user might have changed settings)
    if (state == AppLifecycleState.resumed && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final homeController = Provider.of<HomeController>(
          context,
          listen: false,
        );
        // Re-check location status when app resumes
        await _checkAndShowLocationDialog(homeController);
        // Also try to get location if it's now enabled
        final hasLocation = await homeController.checkLocationStatus();
        if (hasLocation && mounted) {
          await homeController.getCurrentLocation();
        }
      });
    }
  }

  Future<void> _checkAndShowLocationDialog(
    HomeController homeController,
  ) async {
    if (!mounted) return;

    // Don't show dialog if location is currently being loaded (normal loading state)
    if (homeController.isLoadingLocation) {
      debugPrint("📍 Location is loading, not showing dialog");
      return;
    }

    // First check the actual location status (both GPS and permission)
    final hasLocation = await homeController.checkLocationStatus();

    // Check if we have valid location coordinates
    final hasValidLocation =
        homeController.locLatitude != null &&
        homeController.locLongitude != null;

    // If location is enabled and we have valid coordinates, close dialog if shown
    if (hasLocation && hasValidLocation && _locationDialogShown) {
      _locationDialogShown = false;
      // Close dialog using stored context (avoids popping other screens)
      if (mounted && _locationDialogContext != null) {
        try {
          if (Navigator.of(_locationDialogContext!).canPop()) {
            Navigator.of(_locationDialogContext!).pop();
            _locationDialogContext = null;
          }
        } catch (e) {
          debugPrint("❌ Error closing dialog: $e");
          _locationDialogContext = null;
        }
      }
      return;
    }

    // Only show dialog if there's an ACTUAL problem (not during normal loading):
    // 1. GPS is disabled, OR
    // 2. Permission is denied (not just loading)
    final isGpsOn = homeController.isLocationServiceEnabled;
    final permissionDenied = !hasLocation && isGpsOn;
    final gpsOff = !isGpsOn;

    // Show dialog ONLY if:
    // 1. GPS is off, OR
    // 2. Permission is denied (GPS is on but permission is not granted)
    // Do NOT show if location is just being fetched (normal loading)
    final shouldShowDialog = gpsOff || permissionDenied;

    if (shouldShowDialog && !_locationDialogShown && mounted) {
      debugPrint(
        "📍 Showing location dialog - GPS off: $gpsOff, Permission denied: $permissionDenied",
      );
      _locationDialogShown = true;
      _showLocationDialog(homeController, isPermissionDenied: permissionDenied);
    } else if (hasLocation &&
        hasValidLocation &&
        _locationDialogShown &&
        mounted) {
      // If location is now enabled and we have valid coordinates, close dialog
      _locationDialogShown = false;
      // Close dialog using stored context (avoids popping other screens)
      if (_locationDialogContext != null) {
        try {
          if (Navigator.of(_locationDialogContext!).canPop()) {
            Navigator.of(_locationDialogContext!).pop();
            _locationDialogContext = null;
          }
        } catch (e) {
          debugPrint("❌ Error closing dialog: $e");
          _locationDialogContext = null;
        }
      }
    }
  }

  void _showLocationDialog(
    HomeController homeController, {
    required bool isPermissionDenied,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        // Store dialog context for proper closing
        _locationDialogContext = dialogContext;

        return PopScope(
          canPop: false, // Prevent dismissing by back button
          child: Consumer<HomeController>(
            builder: (context, controller, child) {
              final isGpsOn = controller.isLocationServiceEnabled;
              // Re-evaluate permission denial state reactively
              final currentPermissionDenied =
                  controller.locationErrorMessage?.contains("permission") ??
                  isPermissionDenied;

              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: const CustomText(
                  text: "Location Permission Required",
                  fontSize: 0.022,
                  fontWeight: FontWeight.w600,
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CustomText(
                      text:
                          "Location access is required to use this app. We need your location to show nearby restaurants and food options.",
                      fontSize: 0.018,
                      fontWeight: FontWeight.w400,
                      textAlign: TextAlign.center,
                    ),
                    const CustomSizedBox(height: .02),
                    if (isGpsOn && currentPermissionDenied)
                      const CustomText(
                        text:
                            "GPS is enabled but location permission is denied. Please grant location permission to continue.",
                        fontSize: 0.016,
                        fontWeight: FontWeight.w500,
                        textAlign: TextAlign.center,
                        color: AppColors.hintTclr,
                      )
                    else
                      const CustomText(
                        text:
                            "Please enable Location Services and grant permission.",
                        fontSize: 0.016,
                        fontWeight: FontWeight.w500,
                        textAlign: TextAlign.center,
                        color: AppColors.hintTclr,
                      ),
                  ],
                ),
                actions: [
                  // Show "Grant Permission" button if GPS is on but permission denied
                  if (isGpsOn && currentPermissionDenied)
                    TextButton(
                      onPressed: () async {
                        debugPrint("🔘 Grant Permission button pressed");
                        try {
                          // Check current status
                          final permissionStatus =
                              await Permission.location.status;
                          final geolocatorPermission =
                              await Geolocator.checkPermission();

                          debugPrint(
                            "📍 Current status before request - Handler: $permissionStatus, Geolocator: $geolocatorPermission",
                          );

                          // If permanently denied, open settings directly
                          if (permissionStatus.isPermanentlyDenied ||
                              geolocatorPermission ==
                                  LocationPermission.deniedForever) {
                            debugPrint(
                              "📍 Permission permanently denied, opening settings",
                            );
                            await homeController.openLocationSettings();
                            // Don't close dialog - let periodic check handle it
                            return;
                          }

                          // Try to request permission again
                          final granted = await homeController
                              .requestLocationPermission();
                          debugPrint("📍 Permission request result: $granted");

                          // Wait a moment for system to update
                          await Future.delayed(
                            const Duration(milliseconds: 300),
                          );

                          // Re-check status
                          final finalStatus = await homeController
                              .checkLocationStatus();
                          final hasValidLocation =
                              homeController.locLatitude != null &&
                              homeController.locLongitude != null;

                          if (finalStatus && hasValidLocation) {
                            // Permission granted, close dialog and get location
                            debugPrint("✅ Permission granted, closing dialog");
                            _locationDialogShown = false;
                            // Close dialog using the dialog's context (not rootNavigator)
                            if (mounted &&
                                Navigator.of(dialogContext).canPop()) {
                              Navigator.of(dialogContext).pop();
                              _locationDialogContext = null;
                            }
                            if (mounted) {
                              await homeController.getCurrentLocation();
                            }
                          } else {
                            debugPrint(
                              "❌ Permission still not granted, keeping dialog open",
                            );
                            // Keep dialog open - periodic check will handle when permission is granted
                          }
                        } catch (e) {
                          debugPrint("❌ Error in Grant Permission button: $e");
                        }
                      },
                      child: const CustomText(
                        text: "Grant Permission",
                        fontSize: 0.018,
                        fontWeight: FontWeight.w600,
                        color: AppColors.tPrimaryColor,
                      ),
                    ),
                  TextButton(
                    onPressed: () async {
                      debugPrint("🔘 Open Settings button pressed");
                      // Open location settings
                      await homeController.openLocationSettings();
                    },
                    child: const CustomText(
                      text: "Open Settings",
                      fontSize: 0.018,
                      fontWeight: FontWeight.w600,
                      color: AppColors.tPrimaryColor,
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _checkLocationPeriodically(HomeController homeController) {
    // Check location status every 2 seconds for continuous monitoring
    Future.delayed(const Duration(milliseconds: 2000), () async {
      if (!mounted) return;

      // Always check and potentially show/hide dialog based on status
      await _checkAndShowLocationDialog(homeController);

      // If location is enabled but we don't have valid coordinates yet, try to fetch
      final hasLocation = await homeController.checkLocationStatus();
      final hasValidLocation =
          homeController.locLatitude != null &&
          homeController.locLongitude != null;

      if (hasLocation &&
          !hasValidLocation &&
          !homeController.isLoadingLocation) {
        debugPrint("📍 Permission granted but no coordinates, fetching...");
        await homeController.getCurrentLocation();
      }

      // Always schedule the next check to maintain persistence
      if (mounted) {
        _checkLocationPeriodically(homeController);
      }
    });
  }

  // /void _showFilterBottomSheet(BuildContext context) {
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.transparent,
  //     builder: (context) {
  //       return const FilterBottomSheet();
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeController>(
      builder: (context, homeController, child) {
        // Check and show location dialog if needed (only when not loading)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Only check dialog if not currently loading location (normal loading state)
          if (!homeController.isLoadingLocation) {
            _checkAndShowLocationDialog(homeController);
          }
        });

        try {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (bool didPop, Object? result) async {
              // if (didPop) {
              //   return;
              // }
              // // Check if location is mandatory and not available
              // final hasLocation = await homeController.checkLocationStatus();
              // final hasValidLocation = homeController.locLatitude != null &&
              //     homeController.locLongitude != null;

              // // If location is not available, don't allow exit (location is mandatory)
              // if (!hasLocation || !hasValidLocation) {
              //   // Show location dialog if not already shown
              //   if (!_locationDialogShown && mounted) {
              //     _locationDialogShown = true;
              //     // _showLocationDialog(homeController);
              //   }
              //   return;
              // }

              // Location is available, allow exit confirmation
              showAlertDialog(
                context: context,
                title: 'Exit',
                content: 'Are You Sure, You Want To Exit From App?',
                onPressed: () {
                  SystemNavigator.pop();
                },
              );
            },
            child: Scaffold(
              backgroundColor: const Color(0XFFF6F6F6),
              appBar: PreferredSize(
                preferredSize: Size.fromHeight(Sizes.height * 0.16),
                child: Container(
                  color: AppColors.tWhiteColor,
                  child: Column(
                    children: [
                      CustomPadding(
                        top: 0.05,
                        left: 0.04,
                        right: 0.04,
                        bottom: .008,
                        child: Row(
                          children: [
                            Image.asset(
                              AppImages.locationHome,
                              height: Sizes.height * 0.03,
                            ),
                            Expanded(
                              child: CustomTap(
                                onTap: () {
                                  if (SharedPreferencesHelper().getString(
                                        "loginType",
                                      ) ==
                                      "skip") {
                                    customToast(
                                      message:
                                          "Please login with your credentials to continue",
                                    );
                                    SharedPreferencesHelper().clearAlldata();
                                    NavigateTo().pushRemove(
                                      child: const GuestLoginScreen(),
                                    );
                                  } else {
                                    NavigateTo().nextPage(
                                      child: const SearchLocation(),
                                    );
                                  }
                                },
                                child: CustomPadding(
                                  left: 0.02,
                                  child: homeController.isLoadingLocation
                                      ? Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            CustomPadding(
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Shimmer.fromColors(
                                                      baseColor:
                                                          Colors.grey.shade300,
                                                      highlightColor:
                                                          Colors.grey.shade100,
                                                      child: Container(
                                                        height:
                                                            Sizes.height * 0.02,
                                                        decoration: BoxDecoration(
                                                          color: Colors
                                                              .grey
                                                              .shade300,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                4,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const CustomSizedBox(
                                                    width: 0.01,
                                                  ),
                                                  Icon(
                                                    Icons.keyboard_arrow_down,
                                                    size: Sizes.height * 0.024,
                                                    color: const Color(
                                                      0XFF2A2A2A,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            CustomSizedBox(height: 0.008),
                                            Shimmer.fromColors(
                                              baseColor: Colors.grey.shade300,
                                              highlightColor:
                                                  Colors.grey.shade100,
                                              child: Container(
                                                height: Sizes.height * 0.016,
                                                width: Sizes.width * 0.5,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade300,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      : Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            CustomPadding(
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: CustomText(
                                                      text:
                                                          homeController
                                                              .locHouse ??
                                                          '',
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 0.02,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      maxLines: 1,
                                                    ),
                                                  ),
                                                  const CustomSizedBox(
                                                    width: 0.01,
                                                  ),
                                                  Icon(
                                                    Icons.keyboard_arrow_down,
                                                    size: Sizes.height * 0.024,
                                                    color: const Color(
                                                      0XFF2A2A2A,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: CustomText(
                                                    text:
                                                        homeController
                                                            .locLandmark ??
                                                        '',
                                                    color: Color(0XFF111827),
                                                    fontSize: 0.016,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                            CustomSizedBox(width: 0.02),
                            Row(
                              children: [
                                CustomPadding(
                                  right: 0.03,
                                  child: InkWell(
                                    onTap: () {
                                      NavigateTo().nextPage(
                                        child: const Wishlist(),
                                      );
                                    },
                                    child: Image.asset(
                                      AppImages.fav,
                                      height: Sizes.height * 0.022,
                                    ),
                                  ),
                                ),
                                const CustomSizedBox(width: 0.02),
                                InkWell(
                                  onTap: () {
                                    NavigateTo().nextPage(
                                      child: const Notifications(),
                                    );
                                  },
                                  child: Stack(
                                    children: [
                                      Image.asset(
                                        AppImages.notification,
                                        height: Sizes.height * 0.028,
                                      ),
                                      if (homeController
                                                  .getNotificationsModelData !=
                                              null &&
                                          homeController
                                                  .getNotificationsModelData!
                                                  .count !=
                                              null &&
                                          homeController
                                                  .getNotificationsModelData!
                                                  .count! >
                                              0)
                                        Positioned(
                                          right: 0,
                                          top: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: Color(0XFFE9E9E9)),
                      InkWell(
                        child: CustomPadding(
                          top: .006,
                          left: 0.04,
                          right: 0.04,
                          child: Row(
                            children: [
                              Expanded(
                                child: CustomTap(
                                  onTap: () {
                                    NavigateTo().nextPage(
                                      child: const SearchScreen(),
                                    );
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: Sizes.width * 0.04,
                                      vertical: Sizes.height * 0.013,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.tWhiteColor,
                                      border: Border.all(
                                        color: const Color(0XFFDFDFDF),
                                        width: 0.8,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        Sizes.height * 0.08,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Image.asset(
                                          AppImages.search,
                                          height: Sizes.height * 0.026,
                                        ),
                                        SizedBox(width: Sizes.width * 0.02),
                                        const CustomText(
                                          text: "Search...",
                                          fontSize: 0.016,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0XFF2A2A2A),
                                        ),
                                        SizedBox(width: Sizes.width * 0.02),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              CustomSizedBox(width: 0.02),
                              CustomTap(
                                onTap: () {
                                  Provider.of<HomeController>(
                                    context,
                                    listen: false,
                                  ).clearFilters();
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) {
                                      return FilterBottomSheet(
                                        onApply: () {
                                          final homeController =
                                              Provider.of<HomeController>(
                                                context,
                                                listen: false,
                                              );
                                          String? kitchenTypeIds =
                                              homeController
                                                  .selectedKitchenIds
                                                  .isEmpty
                                              ? null
                                              : homeController
                                                    .selectedKitchenIds
                                                    .join(',');
                                          String? foodTypeIds =
                                              homeController
                                                  .selectedMenuFoodIds
                                                  .isEmpty
                                              ? null
                                              : homeController
                                                    .selectedMenuFoodIds
                                                    .join(',');

                                          Navigator.pop(context);
                                          NavigateTo().nextPage(
                                            child: SearchScreen(
                                              kitchenTypeIds: kitchenTypeIds,
                                              foodTypeIds: foodTypeIds,
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                                child: Container(
                                  padding: EdgeInsets.all(Sizes.height * 0.004),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0XFFD4D4D4),
                                    ),
                                    color: AppColors.tWhiteColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const CustomImage(
                                    image: AppImages.filter,
                                    height: .03,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              body: homeController.isLoading == true
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: () async {
                        if (homeController.locLatitude != null &&
                            homeController.locLongitude != null) {
                          await homeController.fetchHomePageData(
                            latitude: homeController.locLatitude!,
                            longitude: homeController.locLongitude!,
                            forceRefresh: true,
                          );
                          if (context.mounted) {
                            await Provider.of<CartController>(
                              context,
                              listen: false,
                            ).getCartApi();
                            await Provider.of<HomeController>(
                              context,
                              listen: false,
                            ).getNotificationsApi();
                          }
                        } else {
                          await homeController.getCurrentLocation(
                            forceRefresh: true,
                          );
                        }
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          children: [
                            // Builder(builder: (context) {
                            //   final co2Msg = homeController.homeData?.co2Message;
                            //   final discountMsg =
                            //       homeController.homeData?.discountMessage;

                            //   final List<String> messages = [];
                            //   if (co2Msg != null) messages.add(co2Msg);
                            //   if (discountMsg != null) messages.add(discountMsg);

                            //   if (messages.isEmpty ||
                            //       _messageIndex >= messages.length) {
                            //     return const SizedBox.shrink();
                            //   }

                            //   // If we haven't loaded data yet, _messageIndex might have advanced.
                            //   // Ideally we want to show messages for full duration once loaded,
                            //   // but matching the request "only once" closely with the timer.
                            //   // If data comes late, they might see nothing or just the tail.

                            //   final messageToShow = messages[_messageIndex];

                            //   return Padding(
                            //     padding: EdgeInsets.fromLTRB(Sizes.width * 0.0,
                            //         Sizes.height * 0.0, Sizes.width * 0.0, 0),
                            //     child: Container(
                            //       width: Sizes.width,
                            //       padding: EdgeInsets.symmetric(
                            //           horizontal: Sizes.width * 0.04,
                            //           vertical: Sizes.height * 0.02),
                            //       decoration: BoxDecoration(
                            //         gradient: const LinearGradient(
                            //           colors: [
                            //             Color(0xFF24E9E5),
                            //             Color(0xFFA6FFC1)
                            //           ],
                            //           begin: Alignment.centerLeft,
                            //           end: Alignment.centerRight,
                            //         ),
                            //         borderRadius: BorderRadius.circular(0),
                            //       ),
                            //       child: CustomText(
                            //         text: messageToShow,
                            //         fontSize: 0.016,
                            //         fontWeight: FontWeight.w600,
                            //         color: Colors.black,
                            //       ),
                            //     ),
                            //   );
                            // }),
                            homeController.homeData?.categories?.isEmpty ?? true
                                ? const SizedBox.shrink()
                                : TopCategoriesContainer(
                                    topCategories:
                                        homeController.homeData?.categories,
                                  ),
                            homeController.homeData?.popularProducts?.isEmpty ??
                                    true
                                ? CustomPadding(
                                    top: .015,
                                    left: .04,
                                    child: Column(
                                      children: [
                                        CustomImage(
                                          image: AppImages.nofood,
                                          height: .35,
                                        ),
                                        CustomSizedBox(height: .025),
                                        CustomText(
                                          text: 'Nothing to Save Yet',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 0.022,
                                          color: Color(0XFF212121),
                                        ),
                                        CustomSizedBox(height: .015),
                                        CustomText(
                                          text:
                                              "No food to save at this moment \nPlease check again later",
                                          fontSize: 0.016,
                                          color: Color(0XFF777777),
                                          fontWeight: FontWeight.w500,
                                          textAlign: TextAlign.center,
                                        ),
                                        CustomSizedBox(height: .04),

                                        // CustomPadding(
                                        //   right: .04,
                                        //   child: Stack(
                                        //     children: [
                                        //       Container(
                                        //         width: Sizes.width,
                                        //         padding: EdgeInsets.symmetric(
                                        //           horizontal: Sizes.width * 0.02,
                                        //           vertical: Sizes.height * 0.014,
                                        //         ),
                                        //         decoration: BoxDecoration(
                                        //           color: Color(0XFFFFF3E0),
                                        //           borderRadius:
                                        //               BorderRadius.circular(6),
                                        //         ),
                                        //         child: Row(
                                        //           mainAxisAlignment:
                                        //               MainAxisAlignment
                                        //                   .spaceBetween,
                                        //           children: [
                                        //             CustomPadding(
                                        //               left: .25,
                                        //               child: CustomText(
                                        //                 text:
                                        //                     'No Food to save at this moment.\n Please check again later',
                                        //                 fontWeight:
                                        //                     FontWeight.w600,
                                        //                 fontSize: 0.017,
                                        //               ),
                                        //             ),
                                        //           ],
                                        //         ),
                                        //       ),
                                        //       Positioned(
                                        //           bottom: 0,
                                        //           left: 0,
                                        //           child: CustomImage(
                                        //             image:
                                        //                 AppImages.cartKitchenBox,
                                        //             height: .085,
                                        //           ))
                                        //     ],
                                        //   ),
                                        // ),
                                      ],
                                    ),
                                  )
                                : PopularNearYouSection(
                                    popularProducts: homeController
                                        .homeData
                                        ?.popularProducts,
                                  ),
                            homeController
                                        .homeData
                                        ?.wishlistKitchens
                                        ?.isEmpty ??
                                    true
                                ? const SizedBox.shrink()
                                : WishListSection(
                                    items: homeController
                                        .homeData
                                        ?.wishlistKitchens,
                                  ),

                            homeController
                                        .homeData
                                        ?.topRatedProducts
                                        ?.isEmpty ??
                                    true
                                ? const SizedBox.shrink()
                                : TopRatedSection(
                                    items: homeController
                                        .homeData
                                        ?.topRatedProducts,
                                  ),

                            homeController.homeData?.cuisines?.isEmpty ?? true
                                ? const SizedBox.shrink()
                                : NewOnResQboxSection(
                                    kitchens: homeController.homeData?.cuisines,
                                    currentIndex: _currentNewKitchen,
                                    onIndexChanged: (index) {
                                      setState(() {
                                        _currentNewKitchen = index;
                                      });
                                    },
                                  ),
                            homeController
                                        .homeData
                                        ?.activeRestaurants
                                        ?.isEmpty ??
                                    true
                                ? const SizedBox.shrink()
                                : ActiveRestaurantsSection(
                                    items: homeController
                                        .homeData
                                        ?.activeRestaurants,
                                  ),

                            // homeController.homeData?.activeRestaurants?.isEmpty ??
                            //         true
                            //     ? const SizedBox.shrink()
                            //     : ActiveRestaurantsSection(
                            //         items:
                            //             homeController.homeData?.activeRestaurants),
                            CustomSizedBox(height: 0.025),
                            Stack(
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(
                                    top: Sizes.height * 0.06,
                                  ), // ✅ Top space above image
                                  child: CustomImage(
                                    image: AppImages.homebg,
                                    width: .98,
                                    height: .25,
                                  ),
                                ),
                                Positioned.fill(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      left: Sizes.width * 0.04,
                                    ),
                                    child: Align(
                                      alignment: Alignment.topLeft,
                                      child: CustomText(
                                        text:
                                            "Made with \nlove \nserved local.",
                                        color: Color(
                                          0XFF4B5563,
                                        ).withOpacity(.6),
                                        fontSize: 0.037,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            CustomSizedBox(height: 0.03),
                          ],
                        ),
                      ),
                    ),
            ),
          );
        } catch (e) {
          debugPrint('Error building Home page: $e');
          return Scaffold(
            backgroundColor: const Color(0XFFF6F6F6),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  CustomText(
                    text: 'Error loading home page',
                    fontSize: 0.018,
                    fontWeight: FontWeight.w500,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {});
                    },
                    child: const CustomText(text: 'Retry'),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}

class TopCategoriesContainer extends StatefulWidget {
  final List<Category>? topCategories;
  const TopCategoriesContainer({super.key, this.topCategories});

  @override
  State<TopCategoriesContainer> createState() => _TopCategoriesContainerState();
}

class _TopCategoriesContainerState extends State<TopCategoriesContainer> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Sizes.width * 0.04,
        vertical: Sizes.height * 0.025,
      ),
      width: Sizes.width,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: Sizes.width * 0.015,
                vertical: Sizes.height * 0.01,
              ),
              decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: BorderRadius.circular(Sizes.height * 0.06),
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(Sizes.height * 0.01),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.tWhiteColor,
                    ),
                    child: const CustomImage(
                      image: AppImages.cardLocation,
                      height: .035,
                    ),
                  ),
                  const CustomPadding(
                    vertical: .01,
                    child: CustomText(
                      text: "Near By",
                      fontSize: 0.012,
                      fontWeight: FontWeight.w600,
                      color: AppColors.tWhiteColor,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: Sizes.width * 0.04),
            ...(widget.topCategories ?? []).map(
              (category) => Padding(
                padding: EdgeInsets.only(right: Sizes.width * 0.035),
                child: CustomTap(
                  onTap: () {
                    NavigateTo().nextPage(
                      child: Menu(
                        from: "category",
                        categoryId: category.id,
                        categoryName: category.name,
                      ),
                    );
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: Sizes.height * 0.078,
                        height: Sizes.height * 0.078,
                        padding: EdgeInsets.all(Sizes.height * 0.012),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.tWhiteColor,
                        ),
                        child: ClipOval(
                          child: CustomNetworkImage(
                            url: category.image ?? '',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(height: Sizes.height * 0.006),
                      CustomText(
                        text: category.name ?? '',
                        fontSize: 0.014,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TopCategory {
  final String title;
  final String imageUrl;
  const TopCategory({required this.title, required this.imageUrl});
}

class PopularNearYouSection extends StatefulWidget {
  const PopularNearYouSection({super.key, this.popularProducts});

  final List<Product>? popularProducts;

  @override
  State<PopularNearYouSection> createState() => _PopularNearYouSectionState();
}

class _PopularNearYouSectionState extends State<PopularNearYouSection> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: Sizes.width,
      color: AppColors.tWhiteColor,
      child: CustomPadding(
        top: .024,
        bottom: .024,
        left: .04,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomPadding(
              right: .04,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const CustomText(
                    text: "Popular Near You",
                    fontWeight: FontWeight.w600,
                    fontSize: 0.018,
                  ),
                  CustomTap(
                    onTap: () {
                      NavigateTo().nextPage(child: const PopularSeeAll());
                    },
                    child: const CustomText(
                      text: "See All",
                      fontWeight: FontWeight.w500,
                      color: AppColors.tPrimaryColor,
                      fontSize: 0.018,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: Sizes.height * 0.02),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                height: Sizes.height * 0.34,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  itemCount: widget.popularProducts?.length ?? 0,
                  padding: EdgeInsets.only(right: Sizes.width * 0.04),
                  itemBuilder: (context, index) {
                    final item = widget.popularProducts?[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        right:
                            index == (widget.popularProducts?.length ?? 0) - 1
                            ? 0
                            : Sizes.width * 0.03,
                      ),
                      child: PopularKitchenCard(item: item),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NewOnResQboxSection extends StatefulWidget {
  const NewOnResQboxSection({
    super.key,
    required this.kitchens,
    required this.currentIndex,
    required this.onIndexChanged,
  });

  final List<Category>? kitchens;
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;

  @override
  State<NewOnResQboxSection> createState() => _NewOnResQboxSectionState();
}

class _NewOnResQboxSectionState extends State<NewOnResQboxSection> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (widget.kitchens != null && widget.kitchens!.isNotEmpty) {
        widget.onIndexChanged(
          (widget.currentIndex + 1) % widget.kitchens!.length,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.kitchens == null || widget.kitchens!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: Sizes.width,
      // color: AppColors.tWhiteColor,
      child: CustomPadding(
        top: .03,
        bottom: .035,
        left: .04,
        right: .04,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CustomPadding(
              vertical: .01,
              child: Align(
                alignment: Alignment.center,
                child: CustomText(
                  text: "Popular on ResQBox Food",
                  fontWeight: FontWeight.w600,
                  color: Color(0XFF111827),
                  fontSize: 0.018,
                ),
              ),
            ),
            // SizedBox(height: Sizes.height * 0.02),
            GestureDetector(
              onHorizontalDragEnd: (details) {
                final kitchensLength = widget.kitchens?.length ?? 0;
                if (details.primaryVelocity == null || kitchensLength == 0)
                  return;
                if (details.primaryVelocity! < -120) {
                  widget.onIndexChanged(
                    (widget.currentIndex + 1) % kitchensLength,
                  );
                } else if (details.primaryVelocity! > 120) {
                  widget.onIndexChanged(
                    (widget.currentIndex - 1 + kitchensLength) % kitchensLength,
                  );
                }
              },
              child: CustomPadding(
                horizontal: .05,
                child: SizedBox(
                  height: Sizes.height * 0.45,
                  width: Sizes.width,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: _buildStackedCards(
                          stackWidth: constraints.maxWidth,
                          stackHeight: Sizes.height * 0.51,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            SizedBox(height: Sizes.height * 0.015),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.kitchens?.length ?? 0,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: EdgeInsets.symmetric(horizontal: Sizes.width * 0.006),
                  height: Sizes.height * 0.007,
                  width: widget.currentIndex == index
                      ? Sizes.width * 0.07
                      : Sizes.width * 0.07,
                  decoration: BoxDecoration(
                    color: widget.currentIndex == index
                        ? AppColors.tPrimaryColor
                        : const Color(0xFFE7E7E7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStackedCards({
    required double stackWidth,
    required double stackHeight,
  }) {
    final kitchensLength = widget.kitchens?.length ?? 0;
    if (kitchensLength == 0) {
      return [];
    }

    final cards = widget.kitchens!.asMap().entries.toList()
      ..sort((a, b) {
        if (a.key == widget.currentIndex) return 1;
        if (b.key == widget.currentIndex) return -1;
        return a.key.compareTo(b.key);
      });
    final double cardWidth = stackWidth * 0.82;
    final double cardHeight = stackHeight * 0.82;
    const double sideOffset = 75;
    const double sideScale = 0.85;
    const double sideOpacity = 0.75;
    final prevIndex =
        (widget.currentIndex - 1 + kitchensLength) % kitchensLength;
    final nextIndex = (widget.currentIndex + 1) % kitchensLength;

    return cards.map((entry) {
      final index = entry.key;
      final kitchen = entry.value;
      double dx = 0;
      double scale = 1;
      double opacity = 1;

      if (index == widget.currentIndex) {
        dx = 0;
        scale = 1;
        opacity = 1;
      } else if (index == prevIndex) {
        dx = -sideOffset;
        scale = sideScale;
        opacity = sideOpacity;
      } else if (index == nextIndex) {
        dx = sideOffset;
        scale = sideScale;
        opacity = sideOpacity;
      } else {
        opacity = 0;
      }

      return AnimatedPositioned(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        left: stackWidth / 2 - cardWidth / 2 + dx,
        // top: stackHeight / 2 - cardHeight / 2,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 350),
          opacity: opacity,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 350),
            scale: scale,
            child: SizedBox(
              width: cardWidth,
              height: cardHeight,
              child: _NewKitchenCard(
                kitchen: kitchen,
                isSelected: index == widget.currentIndex,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}

class _NewKitchenCard extends StatelessWidget {
  const _NewKitchenCard({required this.kitchen, required this.isSelected});

  final Category kitchen;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(Sizes.height * 0.015),
      margin: EdgeInsets.symmetric(horizontal: Sizes.width * 0.01),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFECECEC), width: 0.8),
        color: AppColors.tWhiteColor,
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.black.withOpacity(0.05),
        //     blurRadius: 15,
        //     offset: const Offset(0, 8),
        //   )
        // ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CustomNetworkImage(
              url: kitchen.image ?? '',
              height: .3,
              fit: BoxFit.cover,
            ),
          ),
          if (isSelected)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Sizes.width * 0.0,
                vertical: Sizes.height * 0.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: Sizes.height * 0.008),
                  CustomPadding(
                    vertical: .009,
                    child: CustomText(
                      text: (kitchen.name ?? '')
                          .split(' ')
                          .map(
                            (word) => word.isNotEmpty
                                ? '${word[0].toUpperCase()}${word.substring(1)}'
                                : '',
                          )
                          .join(' '),
                      // kitchen.name ?? '',
                      fontSize: 0.02,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  // CustomSizedBox(height: Sizes.height * 0.002),
                  CustomTap(
                    onTap: () {
                      NavigateTo().nextPage(
                        child: KitchensList(
                          cuisineId: kitchen.id,
                          cuisineName: kitchen.name,
                        ),
                      );
                    },
                    child: Text(
                      "View restaurants",
                      style: GoogleFonts.roboto(
                        shadows: [
                          Shadow(
                            color: AppColors.tPrimaryColor,
                            offset: Offset(0, -3),
                          ),
                        ],
                        color: Colors.transparent,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.tPrimaryColor,
                        decorationThickness: 1.2,
                        decorationStyle: TextDecorationStyle.solid,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class NewKitchen {
  final String title;
  final String subtitle;
  final String imageUrl;

  const NewKitchen({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
  });
}

class WishListKitchen {
  final String name;
  final String cuisine;
  final String heroImage;
  final String avatarImage;
  final double rating;
  final String distance;
  final String address;
  final String discountLabel;

  const WishListKitchen({
    required this.name,
    required this.cuisine,
    required this.heroImage,
    required this.avatarImage,
    required this.rating,
    required this.distance,
    required this.address,
    required this.discountLabel,
  });
}

class ActiveRestaurantsSection extends StatefulWidget {
  const ActiveRestaurantsSection({super.key, required this.items});

  final List<ActiveRestaurantData>? items;

  @override
  State<ActiveRestaurantsSection> createState() =>
      _ActiveRestaurantsSectionState();
}

class _ActiveRestaurantsSectionState extends State<ActiveRestaurantsSection> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: Sizes.width,
      color: AppColors.tWhiteColor,
      child: CustomPadding(
        vertical: .03,
        horizontal: .04,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  text: "Restaurants Near You",
                  fontWeight: FontWeight.w600,
                  fontSize: 0.018,
                ),
                CustomTap(
                  onTap: () {
                    NavigateTo().nextPage(child: const ActiveSeeAll());
                  },
                  child: CustomText(
                    text: "See All",
                    fontWeight: FontWeight.w500,
                    color: AppColors.tPrimaryColor,
                    fontSize: 0.018,
                  ),
                ),
              ],
            ),
            SizedBox(height: Sizes.height * 0.02),
            (widget.items == null || widget.items!.isEmpty)
                ? const SizedBox.shrink()
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.items!.length,
                    itemBuilder: (context, index) => Padding(
                      padding: EdgeInsets.only(
                        bottom: index == widget.items!.length - 1
                            ? 0
                            : Sizes.height * 0.015,
                      ),
                      child: ActiveRestaurantCard(item: widget.items![index]),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class ActiveRestaurantCard extends StatefulWidget {
  const ActiveRestaurantCard({this.item});

  final ActiveRestaurantData? item;

  @override
  State<ActiveRestaurantCard> createState() => _ActiveRestaurantCardState();
}

class _ActiveRestaurantCardState extends State<ActiveRestaurantCard> {
  @override
  Widget build(BuildContext context) {
    bool isOutOfStock = (widget.item?.totalItemsQuantity ?? 0) <= 0;
    return Consumer<AccountController>(
      builder: (context, accountController, child) {
        return CustomTap(
          onTap: () {
            NavigateTo().nextPage(
              child: KitchensViewScreen(restaurantId: widget.item?.kitchenId),
            );
          },
          child: ColorFiltered(
            colorFilter: isOutOfStock
                ? const ColorFilter.matrix(<double>[
                    0.6065,
                    0.3575,
                    0.0360,
                    0,
                    0,
                    0.1065,
                    0.8575,
                    0.0360,
                    0,
                    0,
                    0.1065,
                    0.3575,
                    0.5360,
                    0,
                    0,
                    0,
                    0,
                    0,
                    1,
                    0,
                  ])
                : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Sizes.height * 0.01),
                border: Border.all(color: const Color(0xFFDEDEDE), width: 0.8),
                color: AppColors.tWhiteColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: CustomPadding(
                top: .015,
                bottom: .015,
                left: .02,
                right: .03,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipOval(
                      child: SizedBox(
                        height: Sizes.height * 0.075,
                        width: Sizes.height * 0.075,
                        child: CustomNetworkImage(
                          url: widget.item?.photos?.kitchenProfilePhoto ?? '',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(width: Sizes.width * 0.02),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: CustomText(
                                  text: (widget.item?.kitchenName ?? '')
                                      .split(' ')
                                      .map(
                                        (word) => word.isNotEmpty
                                            ? '${word[0].toUpperCase()}${word.substring(1)}'
                                            : '',
                                      )
                                      .join(' '),
                                  fontSize: 0.016,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  if (SharedPreferencesHelper().getString(
                                        "loginType",
                                      ) ==
                                      "skip") {
                                    SharedPreferencesHelper().remove(
                                      "ApiToken",
                                    );
                                    SharedPreferencesHelper().remove("Token2");
                                    SharedPreferencesHelper().remove("role");
                                    SharedPreferencesHelper().clearAlldata();
                                    NavigateTo().pushRemove(
                                      child: GuestLoginScreen(),
                                    );
                                    return;
                                    // customToast(
                                    //     message:
                                    //         "Please login with your credentials to continue");
                                  } else {
                                    final kitchenId = widget.item?.kitchenId;
                                    if (kitchenId == null) return;

                                    // Check status from AccountController or fallback to item data
                                    final isWishlisted =
                                        accountController.wishlistData?.kitchens
                                            ?.any(
                                              (k) => k.kitchenId == kitchenId,
                                            ) ??
                                        (widget.item?.isWishlist == 1);

                                    if (isWishlisted) {
                                      await accountController
                                          .removeFromWishlistApi(kitchenId);
                                    } else {
                                      await accountController.addToWishlistApi(
                                        body: {"kitchenId": kitchenId},
                                      );
                                    }
                                  }
                                },
                                behavior: HitTestBehavior.opaque,
                                child: CustomImage(
                                  image: AppImages.favIcon,
                                  color:
                                      (accountController.wishlistData?.kitchens
                                              ?.any(
                                                (k) =>
                                                    k.kitchenId ==
                                                    widget.item?.kitchenId,
                                              ) ??
                                          (widget.item?.isWishlist == 1))
                                      ? AppColors.tPrimaryColor
                                      : const Color(0XFFDDDDDD),
                                  height: 0.02,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: Sizes.height * 0.001),
                          CustomText(
                            text: widget.item?.cuisines?.first ?? '',
                            fontSize: 0.014,
                            fontWeight: FontWeight.w500,
                            color: AppColors.hintTclr,
                          ),
                          SizedBox(height: Sizes.height * 0.004),
                          Row(
                            children: [
                              Expanded(
                                child: RatingStars(
                                  rating: double.parse(
                                    widget.item?.rating ?? '0',
                                  ),
                                ),
                              ),
                              SizedBox(width: Sizes.width * 0.012),
                              const Icon(
                                Icons.circle,
                                size: 4,
                                color: Color(0xFF989898),
                              ),
                              SizedBox(width: Sizes.width * 0.012),
                              Expanded(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset(
                                      AppImages.distance,
                                      height: Sizes.height * 0.016,
                                      color: AppColors.green,
                                    ),
                                    SizedBox(width: Sizes.width * 0.008),
                                    Flexible(
                                      child: CustomText(
                                        text:
                                            "${widget.item?.distanceKm?.toStringAsFixed(1) ?? '0.0'} km",
                                        fontSize: 0.014,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF4B5563),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset(
                                      AppImages.location,
                                      height: Sizes.height * 0.016,
                                      color: AppColors.green,
                                    ),
                                    SizedBox(width: Sizes.width * 0.008),
                                    Flexible(
                                      child: CustomText(
                                        text:
                                            "${widget.item?.address?.street ?? ''},${widget.item?.address?.city ?? ''}",
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        fontSize: 0.014,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF4B5563),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: Sizes.height * 0.006),
                          CustomText(
                            text:
                                "${widget.item?.totalItemsQuantity ?? 0} ResQBoxes Available",
                            fontSize: 0.016,
                            fontWeight: FontWeight.w500,
                            color: AppColors.tPrimaryColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class TopRatedSection extends StatefulWidget {
  const TopRatedSection({super.key, required this.items});

  final List<Product>? items;

  @override
  State<TopRatedSection> createState() => _TopRatedSectionState();
}

class _TopRatedSectionState extends State<TopRatedSection> {
  @override
  Widget build(BuildContext context) {
    return CustomPadding(
      vertical: .025,
      horizontal: .04,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: CustomText(
              text: "Top Rated",
              fontWeight: FontWeight.w600,
              fontSize: 0.018,
            ),
          ),
          SizedBox(height: Sizes.height * 0.02),
          (widget.items == null || widget.items!.isEmpty)
              ? const SizedBox.shrink()
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.items!.length,
                  itemBuilder: (context, index) => Padding(
                    padding: EdgeInsets.only(
                      bottom: index == widget.items!.length - 1
                          ? 0
                          : Sizes.height * 0.02,
                    ),
                    child: FoodMenuCard(
                      item: widget.items![index],
                      from: "home",
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class ActiveRestaurant {
  final String name;
  final String cuisine;
  final String heroImage;
  final String avatarImage;
  final double rating;
  final String distance;
  final String address;
  final String boxesAvailable;

  const ActiveRestaurant({
    required this.name,
    required this.cuisine,
    required this.heroImage,
    required this.avatarImage,
    required this.rating,
    required this.distance,
    required this.address,
    required this.boxesAvailable,
  });
}
