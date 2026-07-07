import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:resqbox_user/Controllers/orders_controller.dart';
import 'package:resqbox_user/Screens/MainSection/Account/help_and_support.dart';
import 'package:resqbox_user/Screens/MainSection/Home/kitchens_view_screen.dart';
import 'package:resqbox_user/Screens/MainSection/Orders/rating_screen.dart';
import 'package:resqbox_user/Models/order_details_model.dart';
import 'package:resqbox_user/Screens/MainSection/bottom_navigation.dart';
import 'package:resqbox_user/Utils/active_btn.dart';
import 'package:resqbox_user/Utils/colors.dart';
import 'package:resqbox_user/Utils/const_validations.dart';
import 'package:resqbox_user/Utils/custom_appbar.dart';
import 'package:resqbox_user/Utils/custom_border_btn.dart';
import 'package:resqbox_user/Utils/custom_image_widget.dart';
import 'package:resqbox_user/Utils/custom_padding.dart';
import 'package:resqbox_user/Utils/custom_sizedbox.dart';
import 'package:resqbox_user/Utils/custom_tap.dart';
import 'package:resqbox_user/Utils/customtext.dart';
import 'package:resqbox_user/Utils/horizontal_line.dart';
import 'package:resqbox_user/Utils/images.dart';
import 'package:resqbox_user/Utils/map_launcher.dart';
import 'package:resqbox_user/Utils/mediaquery.dart';
import 'package:resqbox_user/Utils/navigations.dart';
import 'package:flutter/foundation.dart';
import 'package:resqbox_user/Utils/network_image.dart';
import 'package:resqbox_user/Utils/toast.dart';

class OrderDetails extends StatefulWidget {
  final String? from;
  final int? orderId;
  const OrderDetails({super.key, this.from, this.orderId});

  @override
  State<OrderDetails> createState() => _OrderDetailsState();
}

class _OrderDetailsState extends State<OrderDetails> {
  bool _isTrackingExpanded = false;
  Duration _pickupTimerRemaining = Duration.zero;
  Timer? _pickupTimer;
  DateTime? _pickupEndTime;
  bool _timerInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final result = await Provider.of<OrdersController>(context, listen: false)
          .myOrdersByIdApi(widget.orderId);

      if (result) {
        _initializeTimer(Provider.of<OrdersController>(context, listen: false));
      }
    });
  }

  void _initializeTimer(OrdersController ordersController) {
    if (_timerInitialized) return;

    final pickupEndTimeStr =
        ordersController.ordersDetailsData?.order?.pickupEndTime;
    final pickupStartTimeStr =
        ordersController.ordersDetailsData?.order?.pickupStartTime;
    final offsetStr =
        ordersController.ordersDetailsData?.order?.kitchen?.timezone?.offset;
    final tzName =
        ordersController.ordersDetailsData?.order?.kitchen?.timezone?.name;

    if (pickupEndTimeStr != null && pickupEndTimeStr.isNotEmpty) {
      _pickupEndTime = _parseTimeString(
          pickupEndTimeStr, pickupStartTimeStr, offsetStr, tzName);

      debugPrint("_pickupEndTime $_pickupEndTime");

      debugPrint(
          "orderid${ordersController.ordersDetailsData?.order?.orderId}");
      if (_pickupEndTime != null) {
        _timerInitialized = true;
        _updateTimer();
        _startPickupTimer();
      }
    }
  }

  Duration _getOffset(String? tzName, String? fallbackOffsetStr) {
    if (tzName != null && tzName.isNotEmpty) {
      try {
        final location = tz.getLocation(tzName);
        final now = DateTime.now();
        final timezone = location.timeZone(now.millisecondsSinceEpoch);
        return Duration(milliseconds: timezone.offset);
      } catch (e) {
        debugPrint("Error getting offset for timezone $tzName: $e");
      }
    }
    return _parseOffset(fallbackOffsetStr);
  }

  Duration _parseOffset(String? offsetStr) {
    if (offsetStr == null || offsetStr.isEmpty) return Duration.zero;
    try {
      final sign = offsetStr.startsWith('-') ? -1 : 1;
      final parts = offsetStr.substring(1).split(':');
      final hours = int.parse(parts[0]);
      final minutes = parts.length > 1 ? int.parse(parts[1]) : 0;
      return Duration(hours: hours, minutes: minutes) * sign;
    } catch (e) {
      debugPrint("Error parsing offset: $e");
      return Duration.zero;
    }
  }

  DateTime? _parseTimeString(
      String timeStr, String? startTimeStr, String? offsetStr, String? tzName) {
    try {
      final offset = _getOffset(tzName, offsetStr);
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        // 1. Get current moment in the target timezone (e.g. Melbourne)
        final nowUtc = DateTime.now().toUtc();
        final targetNow = nowUtc.add(offset);

        var hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final second = parts.length > 2 ? int.parse(parts[2]) : 0;

        // 2. Determine if time is AM or PM based on context (Heuristic)
        if (hour < 12) {
          if (startTimeStr != null) {
            final startParts = startTimeStr.split(':');
            if (startParts.length >= 2) {
              final startHour = int.parse(startParts[0]);
              // If start is AM and current target time is PM, convert end to PM
              if (startHour < 12 && targetNow.hour >= 12) {
                hour += 12;
              }
            }
          } else {
            // No start time, if current target time is PM, try PM version first
            if (targetNow.hour >= 12) {
              final pmHour = hour + 12;
              // If PM time is in the future relative to targetNow, use it
              if (pmHour > targetNow.hour) {
                hour = pmHour;
              }
            }
          }
        }

        // 3. Create the pickup time using target timezone's date components
        // We use DateTime.utc to represent 'absolute' local time at restaurant
        var pickupTimeInTarget = DateTime.utc(
          targetNow.year,
          targetNow.month,
          targetNow.day,
          hour,
          minute,
          second,
        );

        // 4. Handle "next day" or late PM transition
        if (pickupTimeInTarget.isBefore(targetNow)) {
          final originalHour = int.parse(parts[0]);
          // If we haven't tried PM yet and it was AM, try PM
          if (originalHour < 12 && hour < 12) {
            final pmTime = pickupTimeInTarget.add(const Duration(hours: 12));
            if (pmTime.isAfter(targetNow)) {
              pickupTimeInTarget = pmTime;
            } else {
              // Otherwise, it truly is tomorrow
              pickupTimeInTarget =
                  pickupTimeInTarget.add(const Duration(days: 1));
            }
          } else {
            // Already PM or 24h format, set to next day
            pickupTimeInTarget =
                pickupTimeInTarget.add(const Duration(days: 1));
          }
        }

        // 5. Convert this absolute moment back to UTC for comparison with nowUtc
        return pickupTimeInTarget.subtract(offset);
      }
    } catch (e) {
      print('Error parsing time: $e');
    }
    return null;
  }

  void _updateTimer() {
    if (_pickupEndTime == null) return;

    final nowUtc = DateTime.now().toUtc();
    final difference = _pickupEndTime!.difference(nowUtc);

    if (difference.isNegative) {
      _pickupTimerRemaining = Duration.zero;
      _pickupTimer?.cancel();
      return;
    }

    setState(() {
      _pickupTimerRemaining = difference;
    });
  }

  void _startPickupTimer() {
    _pickupTimer?.cancel();
    _pickupTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      _updateTimer();
    });
  }

  Color _getTimerColor() {
    final totalMinutes = _pickupTimerRemaining.inMinutes;

    // Last 30 minutes: red
    if (totalMinutes <= 30) {
      return Colors.red;
    }
    // 1 hour to 30 minutes: yellow
    else if (totalMinutes <= 60) {
      return Colors.yellow.shade700; // Yellow color
    }
    // More than 1 hour: black (default)
    else {
      return AppColors.tBlackColor;
    }
  }

  @override
  void dispose() {
    _pickupTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrdersController>(
        builder: (context, ordersController, child) {
      // Initialize timer when order data is available
      // if (ordersController.ordersDetailsData?.order != null &&
      //     !_timerInitialized) {
      //   WidgetsBinding.instance.addPostFrameCallback((_) {
      //     _initializeTimer(ordersController);
      //   });
      // }

      // Stop timer if status is PICKED or NO_SHOW
      final status =
          ordersController.ordersDetailsData?.order?.status?.toUpperCase();
      if ((status == 'PICKED' || status == 'NO_SHOW') &&
          _pickupTimer != null &&
          _pickupTimer!.isActive) {
        _pickupTimer?.cancel();
      }

      // Re-initialize timer if pickupEndTime changed (e.g. via socket)
      final currentPickupEndTime =
          ordersController.ordersDetailsData?.order?.pickupEndTime;
      if (currentPickupEndTime != null && _timerInitialized) {
        final newEndTime = _parseTimeString(
            currentPickupEndTime,
            ordersController.ordersDetailsData?.order?.pickupStartTime,
            ordersController
                .ordersDetailsData?.order?.kitchen?.timezone?.offset,
            ordersController.ordersDetailsData?.order?.kitchen?.timezone?.name);

        if (newEndTime != null &&
            (_pickupEndTime == null ||
                !newEndTime.isAtSameMomentAs(_pickupEndTime!))) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _timerInitialized = false;
              _initializeTimer(ordersController);
            });
          });
        }
      }

      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? result) async {
          if (didPop) {
            return;
          }
          if (widget.from == "push") {
            NavigateTo().nextPage(child: BottomNavigation(initialIndex: 0));
          } else {
            NavigateTo().backPage();
          }
        },
        child: Scaffold(
          backgroundColor: const Color(0XFFF6F6F6),
          appBar: CustomAppBar(
            title: "Order Details",
            backgroundColor: AppColors.tWhiteColor,
            titleFontSize: 0.022,
            backTap: () {
              if (widget.from == "push") {
                NavigateTo().nextPage(child: BottomNavigation(initialIndex: 0));
              } else {
                NavigateTo().backPage();
              }
            },
            actions: [
              InkWell(
                onTap: () {
                  NavigateTo().nextPage(child: HelpAndSupport());
                },
                child: CustomPadding(
                  right: 0.04,
                  child: Row(
                    children: [
                      const CustomText(
                        text: "HELP",
                        fontWeight: FontWeight.w600,
                        fontSize: 0.013,
                      ),
                      const CustomSizedBox(
                        width: 0.015,
                      ),
                      Image.asset(
                        AppImages.help,
                        color: AppColors.tBlackColor,
                        height: Sizes.height * 0.024,
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
          bottomNavigationBar: ordersController.isMyOrdersByIdLoading == true
              ? SizedBox.shrink()
              : ordersController.ordersDetailsData?.order?.status ==
                          "DELIVERED" ||
                      ordersController.ordersDetailsData?.order?.status ==
                          "PICKED" ||
                      ordersController.ordersDetailsData?.order?.status ==
                          "NO_SHOW"
                  ? Container(
                      color: AppColors.tWhiteColor,
                      padding: EdgeInsets.symmetric(
                        vertical: Sizes.height * .02,
                        horizontal: Sizes.width * .04,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // CustomBorderBtn(
                          //     height: Sizes.height * .05,
                          //     width: Sizes.width,
                          //     text: "Download Invoice",
                          //     onTap: () {
                          //       ordersController.downloadUploadedFiles(
                          //           ordersController.ordersDetailsData?.order
                          //                   ?.orderInvoice?.pdfUrl ??
                          //               '');
                          //     },
                          //     fontSize: 0.016,
                          //     borderColor: AppColors.tPrimaryColor,
                          //     textColor: AppColors.tBlackColor),
                          // const CustomSizedBox(height: 0.015),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ordersController
                                          .ordersDetailsData?.order?.rating ==
                                      "0"
                                  ? CustomBorderBtn(
                                      height: Sizes.height * .05,
                                      width: Sizes.width * .43,
                                      text: "Give Rating",
                                      onTap: () {
                                        NavigateTo().nextPage(
                                            child: RatingScreen(
                                                orderId: widget.orderId,
                                                kitchenIdImage: ordersController
                                                        .ordersDetailsData
                                                        ?.order
                                                        ?.kitchen
                                                        ?.photos
                                                        ?.kitchenProfilePhoto ??
                                                    '',
                                                foodIdImage: ordersController
                                                        .ordersDetailsData
                                                        ?.order
                                                        ?.items
                                                        ?.first
                                                        .image ??
                                                    ''));
                                      },
                                      fontSize: 0.016,
                                      borderColor: AppColors.tPrimaryColor,
                                      textColor: AppColors.tBlackColor)
                                  : const SizedBox.shrink(),
                              // ActiveButton(
                              //   height: Sizes.height * .05,
                              //   width: Sizes.width * .43,
                              //   text: "Re order",
                              //   fontSize: .016,
                              //   borderRadius: 5,
                              //   onPressed: () {},
                              // )
                              ActiveButton(
                                height: Sizes.height * .05,
                                width: ordersController
                                            .ordersDetailsData?.order?.rating ==
                                        "0"
                                    ? Sizes.width * .43
                                    : Sizes.width * .9,
                                text: "Download Invoice",
                                fontSize: .016,
                                borderRadius: 5,
                                onPressed: () {
                                  if (ordersController.ordersDetailsData?.order
                                          ?.orderInvoice?.pdfUrl !=
                                      null) {
                                    ordersController.downloadUploadedFiles(
                                        ordersController.ordersDetailsData
                                                ?.order?.orderInvoice?.pdfUrl ??
                                            '');
                                  } else {
                                    customToast(
                                      message: "Invoice not available",
                                    );
                                  }
                                },
                              )
                            ],
                          ),
                        ],
                      ))
                  : SizedBox.shrink(),
          body: ordersController.isMyOrdersByIdLoading
              ? const Center(child: CircularProgressIndicator())
              : CustomPadding(
                  vertical: .02,
                  horizontal: .04,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            vertical: Sizes.height * .01,
                            horizontal: Sizes.width * .03,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: AppColors.tWhiteColor,
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  CustomText(
                                    text:
                                        "Order ID - ${ordersController.ordersDetailsData?.order?.orderDisplayId}",
                                    fontSize: .015,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  Row(
                                    children: [
                                      CustomText(
                                        text: formatTime(ordersController
                                                .ordersDetailsData
                                                ?.order
                                                ?.orderedAt
                                                ?.toString() ??
                                            ''),
                                        fontSize: .013,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      CustomSizedBox(
                                        width: .02,
                                      ),
                                      CustomText(
                                        text: formatDate(ordersController
                                                .ordersDetailsData
                                                ?.order
                                                ?.orderedAt
                                                ?.toString() ??
                                            ''),
                                        fontSize: .013,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ],
                                  )
                                ],
                              ),
                              const CustomSizedBox(
                                height: .015,
                              ),
                              ListView.builder(
                                itemCount: ordersController.ordersDetailsData
                                        ?.order?.items?.length ??
                                    0,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: EdgeInsets.only(
                                        bottom: Sizes.height * 0.01,
                                        left: Sizes.width * 0.015),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          child: CustomNetworkImage(
                                            url: ordersController
                                                    .ordersDetailsData
                                                    ?.order
                                                    ?.items?[index]
                                                    .image ??
                                                '',
                                            height: .04,
                                            width: .09,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        const CustomSizedBox(width: .03),
                                        Expanded(
                                          child: CustomText(
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            text:
                                                '${ordersController.ordersDetailsData?.order?.items?[index].quantity} x ${ordersController.ordersDetailsData?.order?.items?[index].name}',
                                            fontSize: .015,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              Divider(
                                height: 2,
                                color: const Color(0XFFD9D9D9).withOpacity(.3),
                              ),
                              // provider.orderDetailsData?.orderStatus == "Cancelled"
                              //     ? CustomPadding(
                              //         vertical: .004,
                              //         child: Row(
                              //           children: [
                              //             Container(
                              //               padding: const EdgeInsets.all(2),
                              //               decoration: const BoxDecoration(
                              //                   shape: BoxShape.circle,
                              //                   color: AppColors.redD25E0B),
                              //               child: const Icon(
                              //                 Icons.close,
                              //                 color: AppColors.tWhiteColor,
                              //                 size: 14,
                              //               ),
                              //             ),
                              //             const CustomSizedBox(
                              //               width: .04,
                              //             ),
                              //             const CustomText(
                              //               text: "Your Order is Cancelled",
                              //               fontSize: .016,
                              //               fontWeight: FontWeight.w400,
                              //             ),
                              //           ],
                              //         ),
                              //       )
                              //     :
                              CustomPadding(
                                top: .015,
                                bottom: .01,
                                child: Row(
                                  // crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    CustomImage(
                                      image: AppImages.status,
                                      height: .016,
                                      color: ordersController.ordersDetailsData
                                                  ?.order?.status ==
                                              "REJECTED"
                                          ? AppColors.red
                                          : null,
                                    ),
                                    CustomSizedBox(
                                      width: .02,
                                    ),
                                    Expanded(
                                      child: CustomText(
                                        text: () {
                                          final status = ordersController
                                              .ordersDetailsData?.order?.status;
                                          if (status == null ||
                                              status.isEmpty) {
                                            return "Your Order Has Been";
                                          }
                                          final capitalizedStatus =
                                              '${status[0].toUpperCase()}${status.substring(1).toLowerCase()}';
                                          return ordersController
                                                      .ordersDetailsData
                                                      ?.order
                                                      ?.status ==
                                                  "NO_SHOW"
                                              ? "Your order was completed, but we noticed it wasn’t picked up. The order has now been closed."
                                              : ordersController
                                                          .ordersDetailsData
                                                          ?.order
                                                          ?.status ==
                                                      "REJECTED"
                                                  ? "The restaurant didn’t accept your order in time. No charges were made. Please try again."
                                                  : "Your Order Has Been $capitalizedStatus";
                                        }(),
                                        fontSize: .014,
                                        color: ordersController
                                                    .ordersDetailsData
                                                    ?.order
                                                    ?.status ==
                                                "REJECTED"
                                            ? AppColors.red
                                            : Color(0XFF4B5563),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),

                        ordersController.ordersDetailsData?.order?.status ==
                                "REJECTED"
                            ? SizedBox.shrink()
                            : Column(
                                children: [
                                  const CustomSizedBox(
                                    height: .01,
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      vertical: Sizes.height * .015,
                                      horizontal: Sizes.width * .03,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      color: AppColors.tWhiteColor,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        CustomText(
                                            text: "Your Order Pickup ID:",
                                            fontSize: .015,
                                            color: Color(0XFF4B5563),
                                            fontWeight: FontWeight.w400),
                                        CustomText(
                                            text: ordersController
                                                    .ordersDetailsData
                                                    ?.order
                                                    ?.pickupId ??
                                                '',
                                            fontSize: .017,
                                            fontWeight: FontWeight.w600),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                        ordersController.ordersDetailsData?.order?.status ==
                                "REJECTED"
                            ? SizedBox.shrink()
                            : Column(
                                children: [
                                  const CustomSizedBox(height: .01),
                                  _buildOrderTrackingCard(ordersController
                                      .ordersDetailsData?.order),
                                ],
                              ),
                        const CustomSizedBox(height: .01),
                        Container(
                          padding: EdgeInsets.symmetric(
                            vertical: Sizes.height * .005,
                            // horizontal: Sizes.width * .02,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: AppColors.tWhiteColor,
                          ),
                          child: CustomPadding(
                            vertical: 0.02,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const CustomPadding(
                                  left: .04,
                                  child: CustomText(
                                    text: "Price Details",
                                    fontSize: 0.018,
                                    color: AppColors.tBlackColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                BillWidget(
                                  isDiscount: false,
                                  title:
                                      'Price (${ordersController.ordersDetailsData?.order?.items?.length ?? 0} items) Inclusive of GST', //Charges(${provider.orderDetailsData?.gstPercentage ?? ''})%
                                  price:
                                      '\$ ${(ordersController.ordersDetailsData?.order?.itemTotal ?? 0.0).toDouble().toStringAsFixed(2)}',
                                ),
                                CustomPadding(
                                  // vertical: .005,
                                  horizontal: .04,
                                  child: HorizontalDottedLine(
                                    width: Sizes.width,
                                    color: AppColors.hintTclr.withOpacity(0.2),
                                  ),
                                ),
                                BillWidget(
                                  isDiscount: false,
                                  title:
                                      'Platform fee', //(${ordersController.ordersDetailsData?.order?.taxPercent?.toStringAsFixed(1) ?? '0.00'}%)
                                  price:
                                      '\$ ${(ordersController.ordersDetailsData?.order?.platformFee ?? 0.0).toDouble().toStringAsFixed(2)}',
                                ),
                                // const CustomPadding(
                                //   bottom: .015,
                                //   left: .04,
                                //   child: Row(
                                //     children: [
                                //       CustomImage(
                                //           image: AppImages.info, height: .02),
                                //       CustomSizedBox(
                                //         width: .01,
                                //       ),
                                //       CustomText(
                                //           fontSize: .015,
                                //           fontWeight: FontWeight.w500,
                                //           text: "Know more"),
                                //     ],
                                //   ),
                                // ),
                                CustomPadding(
                                  vertical: .005,
                                  horizontal: .04,
                                  child: HorizontalDottedLine(
                                    width: Sizes.width,
                                    color: AppColors.hintTclr.withOpacity(0.2),
                                  ),
                                ),
                                CustomPadding(
                                  horizontal: 0.06,
                                  vertical: 0.02,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      CustomText(
                                        text: "Total Amount",
                                        fontSize: 0.018,
                                        color: Color(0XFF4B5563),
                                        fontWeight: FontWeight.w600,
                                      ),
                                      CustomText(
                                        text:
                                            "\$ ${(ordersController.ordersDetailsData?.order?.totalAmount ?? 0.0).toDouble().toStringAsFixed(2)}",
                                        fontSize: 0.02,
                                        color: AppColors.tBlackColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                        const CustomSizedBox(
                          height: .01,
                        ),

                        Container(
                          width: Sizes.width,
                          padding: EdgeInsets.symmetric(
                            vertical: Sizes.height * .005,
                            // horizontal: Sizes.width * .02,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: AppColors.tWhiteColor,
                          ),
                          child: CustomPadding(
                            horizontal: .04,
                            vertical: .015,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    CustomText(
                                      text: "Restaurant Location",
                                      fontSize: 0.018,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    CustomTap(
                                      onTap: () {
                                        final latitude = ordersController
                                            .ordersDetailsData
                                            ?.order
                                            ?.kitchen
                                            ?.address
                                            ?.latitude;
                                        final longitude = ordersController
                                            .ordersDetailsData
                                            ?.order
                                            ?.kitchen
                                            ?.address
                                            ?.longitude;

                                        if (latitude != null &&
                                            longitude != null) {
                                          MapLauncher.openGoogleMaps(
                                            latitude: latitude,
                                            longitude: longitude,
                                          );
                                        }
                                      },
                                      child: CustomText(
                                        text: "View on Map",
                                        fontSize: 0.018,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                CustomPadding(
                                  top: .02,
                                  bottom: .013,
                                  child: Row(
                                    children: [
                                      CustomTap(
                                        onTap: () {
                                          NavigateTo().nextPage(
                                              child: KitchensViewScreen(
                                                  restaurantId: ordersController
                                                      .ordersDetailsData
                                                      ?.order
                                                      ?.kitchen
                                                      ?.kitchenId));
                                        },
                                        child: ClipOval(
                                          child: SizedBox(
                                            width: Sizes.height * 0.05,
                                            height: Sizes.height * 0.05,
                                            child: (ordersController
                                                            .ordersDetailsData
                                                            ?.order
                                                            ?.kitchen
                                                            ?.kitchenImage ==
                                                        null ||
                                                    ordersController
                                                            .ordersDetailsData
                                                            ?.order
                                                            ?.kitchen
                                                            ?.kitchenImage
                                                            ?.isEmpty ==
                                                        true)
                                                ? CircleAvatar(
                                                    backgroundColor:
                                                        AppColors.tPrimaryColor,
                                                    child: CustomText(
                                                      text: (ordersController
                                                                  .ordersDetailsData
                                                                  ?.order
                                                                  ?.kitchen
                                                                  ?.kitchenName
                                                                  ?.isNotEmpty ??
                                                              false)
                                                          ? (ordersController
                                                                  .ordersDetailsData
                                                                  ?.order
                                                                  ?.kitchen
                                                                  ?.kitchenName?[
                                                                      0]
                                                                  .toUpperCase() ??
                                                              'K')
                                                          : 'K',
                                                      fontSize: 0.024,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          AppColors.tWhiteColor,
                                                    ),
                                                  )
                                                : CustomNetworkImage(
                                                    url: ordersController
                                                            .ordersDetailsData
                                                            ?.order
                                                            ?.kitchen
                                                            ?.kitchenImage ??
                                                        '',
                                                    fit: BoxFit.cover,
                                                  ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: Sizes.width * 0.02),
                                      Expanded(
                                        child: CustomTap(
                                          onTap: () {
                                            NavigateTo().nextPage(
                                                child: KitchensViewScreen(
                                                    restaurantId:
                                                        ordersController
                                                            .ordersDetailsData
                                                            ?.order
                                                            ?.kitchen
                                                            ?.kitchenId));
                                          },
                                          child: CustomText(
                                            text: (ordersController
                                                        .ordersDetailsData
                                                        ?.order
                                                        ?.kitchen
                                                        ?.kitchenName ??
                                                    '')
                                                .split(' ')
                                                .map((word) => word.isNotEmpty
                                                    ? '${word[0].toUpperCase()}${word.substring(1)}'
                                                    : '')
                                                .join(' '),
                                            fontSize: 0.017,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.8,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            color: Color(0xFF4B5563),
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor: Color(0xFF4B5563),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                CustomText(
                                  text:
                                      "${ordersController.ordersDetailsData?.order?.kitchen?.address?.houseNo ?? ''}, ${ordersController.ordersDetailsData?.order?.kitchen?.address?.landmark ?? ''}, ${ordersController.ordersDetailsData?.order?.kitchen?.address?.street ?? ''}, ${ordersController.ordersDetailsData?.order?.kitchen?.address?.city ?? ''} ${ordersController.ordersDetailsData?.order?.kitchen?.address?.state ?? ''} ${ordersController.ordersDetailsData?.order?.kitchen?.address?.pincode ?? ''}",
                                  fontSize: .016,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0XFF4B5563),
                                )
                              ],
                            ),
                          ),
                        ),
                        const CustomSizedBox(height: .015),
                        // Container(
                        //   width: Sizes.width,
                        //   padding: EdgeInsets.symmetric(
                        //     vertical: Sizes.height * .015,
                        //     horizontal: Sizes.width * .03,
                        //   ),
                        //   decoration: BoxDecoration(
                        //     borderRadius: BorderRadius.circular(5),
                        //     color: AppColors.tWhiteColor,
                        //   ),
                        //   child: Column(
                        //     crossAxisAlignment: CrossAxisAlignment.start,
                        //     children: [
                        //       const CustomText(
                        //         text: "Payment Details",
                        //         fontSize: .018,
                        //         fontWeight: FontWeight.w500,
                        //         color: Colors.black,
                        //       ),
                        //       const CustomSizedBox(height: .015),
                        //       CustomPadding(
                        //         child: Row(
                        //           children: [
                        //             CustomText(
                        //               text: ordersController.ordersDetailsData
                        //                           ?.order?.paymentMethod ==
                        //                       "ONLINE"
                        //                   ? "Online"
                        //                   : "Cash on Delivery",
                        //               fontWeight: FontWeight.w500,
                        //               fontSize: .019,
                        //               color: Colors.black,
                        //             ),
                        //             SizedBox(width: Sizes.width * 0.05),
                        //             CustomText(
                        //               text: "Visa XXXX-XXXX-0014",
                        //               fontWeight: FontWeight.w400,
                        //               fontSize: .016,
                        //               color: Color(0XFF4B5563),
                        //             ),
                        //           ],
                        //         ),
                        //       ),
                        //     ],
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ),
        ),
      );
    });
  }

  Widget _buildOrderTrackingCard(Order? order) {
    final List<OrderStatus> statuses = _buildOrderStatuses(order);
    final int currentStep = _mapStatusToStep(order?.status);
    final bool isCancelled =
        (order?.status?.toUpperCase() ?? '') == 'CANCELLED';
    final String cancelReason =
        (order?.cancelReason?.toString().isNotEmpty ?? false)
            ? order!.cancelReason.toString()
            : '';
    final String cancelledAt = _formatDateTime(order?.cancelledAt);
    return Container(
      padding: EdgeInsets.only(
        bottom: Sizes.height * .0,
        // horizontal: Sizes.width * .045,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: AppColors.tWhiteColor,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          childrenPadding: const EdgeInsets.all(0),
          iconColor: const Color(0XFF0EB23A),
          initiallyExpanded: _isTrackingExpanded,
          title: const CustomText(
            text: "Order Details",
            fontSize: .018,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
          onExpansionChanged: (expanded) {
            setState(() {
              _isTrackingExpanded = expanded;
            });
          },
          children: [
            CustomPadding(
              left: 0.06,
              child: Column(
                children: [
                  ...List.generate(statuses.length, (index) {
                    final status = statuses[index];
                    final bool isCompleted =
                        !isCancelled && index <= currentStep;
                    final bool isLast = index == statuses.length - 1;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Image.asset(
                              AppImages.status,
                              height: Sizes.height * 0.024,
                              color: isCompleted
                                  ? const Color(0XFF0EB23A)
                                  : const Color(0XFFD0D0D0),
                            ),
                            if (!isLast)
                              Container(
                                width: 2,
                                height: Sizes.height * 0.11,
                                color: isCompleted
                                    ? const Color(0XFF0EB23A)
                                    : const Color(0XFFD0D0D0),
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CustomText(
                                    text: status.title,
                                    fontWeight: FontWeight.w400,
                                    fontSize: .017,
                                    color: isCompleted
                                        ? Colors.black
                                        : AppColors.hintTclr,
                                  ),
                                  status.title == "Ready for Pickup"
                                      ? order?.status == 'PICKED' ||
                                              order?.status == 'NO_SHOW'
                                          ? SizedBox.shrink()
                                          : CustomPadding(
                                              left: .03,
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal:
                                                      Sizes.width * 0.02,
                                                  vertical:
                                                      Sizes.height * 0.004,
                                                ),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(30),
                                                ),
                                                child: CustomText(
                                                  text: _formatDuration(
                                                      _pickupTimerRemaining),
                                                  fontSize: .017,
                                                  fontWeight: FontWeight.w800,
                                                  color: _getTimerColor(),
                                                ),
                                              ),
                                            )
                                      : SizedBox.shrink(),
                                ],
                              ),
                              CustomPadding(
                                top: 0.004,
                                bottom: 0.002,
                                child: CustomText(
                                  text: status.description,
                                  fontSize: .017,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0XFF111827),
                                ),
                              ),
                              status.title == "Ready for Pickup"
                                  ? const SizedBox.shrink()
                                  : CustomText(
                                      text: status.timestamp,
                                      fontSize: .016,
                                      color: Color(0XFF4B5563),
                                      fontWeight: FontWeight.w400,
                                    ),
                              if (status.title == "Ready for Pickup")
                                CustomPadding(
                                  top: .002,
                                  child: CustomText(
                                      text: //${order?.pickupStartTime} –
                                          "Head to Kitchen before ${order?.pickupEndTime} to pick it up. Don’t be late - it’s best enjoyed fresh!",
                                      fontSize: .016,
                                      color: Color(0XFF111827),
                                      fontWeight: FontWeight.w400),
                                ),
                              SizedBox(height: Sizes.height * 0.015),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                  if (isCancelled && cancelReason.isNotEmpty)
                    CustomPadding(
                      top: .01,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CustomText(
                            text: "Order Cancelled",
                            fontSize: .017,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                          const CustomSizedBox(height: .004),
                          CustomText(
                            text: "Reason: $cancelReason",
                            fontSize: .016,
                            fontWeight: FontWeight.w500,
                            color: Colors.red,
                          ),
                          if (cancelledAt.isNotEmpty)
                            CustomText(
                              text: "Cancelled at: $cancelledAt",
                              fontSize: .015,
                              fontWeight: FontWeight.w400,
                              color: AppColors.hintTclr,
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final int hours = duration.inHours;
    final int minutes = duration.inMinutes % 60;
    final int seconds = duration.inSeconds % 60;
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}";
  }

  List<OrderStatus> _buildOrderStatuses(Order? order) {
    return [
      OrderStatus(
        title: "Order Placed",
        description: "Your order has been placed successfully.",
        timestamp: _formatDateTime(order?.orderedAt),
      ),
      OrderStatus(
        title: "Order Accepted",
        description: "Restaurant accepted your order.",
        timestamp: _formatDateTime(order?.acceptedAt),
      ),
      OrderStatus(
        title: "Food is Being Prepared",
        description: "Chef is preparing your meal.",
        timestamp: _formatDateTime(order?.preparedAt),
      ),
      OrderStatus(
        title: "Ready for Pickup",
        description: "Your order is ready to collect.",
        timestamp: _formatDateTime(order?.updatedAt),
      ),
      OrderStatus(
        title: (order?.status?.toUpperCase() == "NO_SHOW")
            ? "No Show"
            : "Order Picked Up",
        description: (order?.status?.toUpperCase() == "NO_SHOW")
            ? "You missed the pickup window."
            : "Order has been picked up.",
        timestamp: _formatDateTime(order?.pickedAt),
      ),
    ];
  }

  int _mapStatusToStep(String? status) {
    switch (status?.toUpperCase()) {
      case 'PENDING':
        return 0;
      case 'ACCEPTED':
        return 1;
      case 'PREPARING':
        return 2;
      case 'READY':
        return 3;
      case 'PICKED':
        return 4; // PICKED means order was picked up, so Ready for Pickup is completed
      case 'NO_SHOW':
        return 4; // NO_SHOW means order was not picked up, so Ready for Pickup is completed
      default:
        return 0;
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '--';
    final local = dateTime;
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    final time = TimeOfDay.fromDateTime(local);
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? "AM" : "PM";
    return "$day/$month/$year - $hour:$minute $period";
  }
}

class BillWidget extends StatelessWidget {
  const BillWidget({
    super.key,
    required this.title,
    required this.price,
    required this.isDiscount,
  });

  final String title;
  final String price;
  final bool isDiscount;

  @override
  Widget build(BuildContext context) {
    return CustomPadding(
      horizontal: 0.04,
      vertical: 0.02,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomText(
            text: title,
            fontSize: 0.017,
            color: const Color(0XFF4B5563),
            fontWeight: FontWeight.w500,
          ),
          CustomText(
            text: "$price",
            fontSize: 0.016,
            color: AppColors.tBlackColor,
            fontWeight: FontWeight.w600,
          ),
        ],
      ),
    );
  }
}

class OrderStatus {
  final String title;
  final String description;
  final String timestamp;

  const OrderStatus({
    required this.title,
    required this.description,
    required this.timestamp,
  });
}
