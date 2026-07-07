import 'dart:async';
import 'package:flutter/material.dart';
import 'package:resqbox_user/Models/order_success_model.dart';
import 'package:resqbox_user/Screens/MainSection/bottom_navigation.dart';
import 'package:resqbox_user/Utils/active_btn.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:resqbox_user/Utils/colors.dart';
import 'package:resqbox_user/Utils/custom_appbar.dart';
import 'package:resqbox_user/Utils/custom_border_btn.dart';
import 'package:resqbox_user/Utils/custom_image_widget.dart';
import 'package:resqbox_user/Utils/custom_padding.dart';
import 'package:resqbox_user/Utils/custom_sizedbox.dart';
import 'package:resqbox_user/Utils/customtext.dart';
import 'package:resqbox_user/Utils/images.dart';
import 'package:resqbox_user/Utils/mediaquery.dart';
import 'package:resqbox_user/Utils/navigations.dart';

class OrderSuccesScreen extends StatefulWidget {
  final OrderSuccessModel? orderdata;
  const OrderSuccesScreen({super.key, this.orderdata});

  @override
  State<OrderSuccesScreen> createState() => _OrderSuccesScreenState();
}

class _OrderSuccesScreenState extends State<OrderSuccesScreen> {
  Timer? _timer;
  String _timeLeft = "00:00:00";
  DateTime? _pickupEndTime;

  @override
  void initState() {
    super.initState();
    _initializeTimer();
  }

  void _initializeTimer() {
    final pickupEndTimeStr = widget.orderdata?.orderDetails?.pickupEndTime;
    final pickupStartTimeStr = widget.orderdata?.orderDetails?.pickupStartTime;
    final offsetStr = widget.orderdata?.orderDetails?.timezone?.offset;
    final tzName = widget.orderdata?.orderDetails?.timezone?.name;

    if (pickupEndTimeStr != null && pickupEndTimeStr.isNotEmpty) {
      _pickupEndTime = _parseTimeString(
        pickupEndTimeStr,
        pickupStartTimeStr,
        offsetStr,
        tzName,
      );
      if (_pickupEndTime != null) {
        _updateTimer();
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          _updateTimer();
        });
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
      debugPrint('Error parsing time: $e');
    }
    return null;
  }

  void _updateTimer() {
    if (_pickupEndTime == null) return;

    // Compare with current time in UTC
    final nowUtc = DateTime.now().toUtc();
    final difference = _pickupEndTime!.difference(nowUtc);

    if (difference.isNegative) {
      _timeLeft = "00:00:00";
      _timer?.cancel();
      return;
    }

    final hours = difference.inHours;
    final minutes = difference.inMinutes.remainder(60);
    final seconds = difference.inSeconds.remainder(60);

    setState(() {
      _timeLeft =
          "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          title: "",
          titleFontSize: 0.022,
          backgroundColor: AppColors.tWhiteColor,
          isBackButton: false,
        ),
        bottomNavigationBar: SafeArea(
          child: CustomPadding(
            // top: .01,
            bottom: .02,
            left: .04,
            right: .04,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomBorderBtn(
                    height: Sizes.height * .06,
                    width: Sizes.width * .43,
                    text: "View Order",
                    fontSize: 0.018,
                    onTap: () {
                      NavigateTo()
                          .nextPage(child: BottomNavigation(initialIndex: 1));
                    },
                    borderRadius: 8,
                    borderColor: AppColors.green,
                    textColor: AppColors.green),
                ActiveButton(
                  height: Sizes.height * .06,
                  width: Sizes.width * .43,
                  text: "Explore More",
                  borderRadius: 8,
                  fontSize: 0.018,
                  onPressed: () {
                    NavigateTo()
                        .nextPage(child: BottomNavigation(initialIndex: 0));
                  },
                ),
              ],
            ),
          ),
        ),
        body: SafeArea(
          child: CustomPadding(
            vertical: .02,
            horizontal: .04,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: Sizes.height * 0.0425),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: EdgeInsets.only(top: Sizes.height * 0.06),
                          width: Sizes.width,
                          decoration: BoxDecoration(
                            color: AppColors.tWhiteColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              CustomPadding(
                                bottom: .02,
                                child: Column(
                                  children: [
                                    CustomText(
                                        text: "Order ID",
                                        fontSize: 0.018,
                                        fontWeight: FontWeight.w500),
                                    CustomText(
                                        text: widget.orderdata?.orderDetails
                                                ?.orderDisplayId ??
                                            "",
                                        fontSize: 0.022,
                                        letterSpacing: 0,
                                        fontWeight: FontWeight.w800)
                                  ],
                                ),
                              ),
                              Divider(
                                color: AppColors.hintTclr.withOpacity(.2),
                                thickness: 1.5,
                              ),
                              CustomPadding(
                                vertical: .02,
                                horizontal: .04,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CustomImage(
                                            image: AppImages.cartStore,
                                            height: .024),
                                        CustomSizedBox(width: .02),
                                        CustomText(
                                            text: "Your Order",
                                            fontSize: 0.018,
                                            color: Color(0XFF111827),
                                            fontWeight: FontWeight.w400),
                                      ],
                                    ),
                                    (widget.orderdata?.orderDetails?.items ==
                                                null ||
                                            widget.orderdata!.orderDetails!
                                                .items!.isEmpty)
                                        ? const SizedBox.shrink()
                                        : Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: widget
                                                .orderdata!.orderDetails!.items!
                                                .map((item) => CustomPadding(
                                                      vertical: .02,
                                                      child: CustomText(
                                                        text: "${item.quantity ?? 0} X ${item.name ?? ''}"
                                                            .split(' ')
                                                            .map((word) => word
                                                                    .isNotEmpty
                                                                ? '${word[0].toUpperCase()}${word.substring(1)}'
                                                                : '')
                                                            .join(' '),
                                                        fontSize: .019,
                                                      ),
                                                    ))
                                                .toList(),
                                          ),
                                    CustomText(
                                        text: widget.orderdata?.orderDetails
                                                ?.items?.first.kitchenName ??
                                            '',
                                        fontSize: 0.018,
                                        color: Color(0XFF4B5563),
                                        fontWeight: FontWeight.w400),
                                    CustomPadding(
                                      vertical: .02,
                                      child: Row(
                                        children: [
                                          CustomImage(
                                              image: AppImages.cartTimer,
                                              height: .024),
                                          CustomSizedBox(width: .02),
                                          CustomText(
                                              text: "Pickup Time",
                                              fontSize: 0.018,
                                              color: Color(0XFF111827),
                                              fontWeight: FontWeight.w400),
                                        ],
                                      ),
                                    ),
                                    CustomPadding(
                                        // vertical: .02,
                                        child: CustomText(
                                      text: // ${widget.orderdata?.orderDetails?.pickupStartTime} -
                                          "Before ${widget.orderdata?.orderDetails?.pickupEndTime}",
                                      fontSize: .019,
                                    )),
                                    CustomPadding(
                                      vertical: .02,
                                      child: Row(
                                        children: [
                                          CustomImage(
                                              image: AppImages.cartLoc,
                                              height: .028),
                                          CustomSizedBox(width: .02),
                                          CustomText(
                                              text: "Pickup Location",
                                              fontSize: 0.018,
                                              color: Color(0XFF111827),
                                              fontWeight: FontWeight.w400),
                                        ],
                                      ),
                                    ),
                                    CustomText(
                                      text:
                                          "${widget.orderdata?.orderDetails?.items?.first.address?.houseNo ?? ''}, ${widget.orderdata?.orderDetails?.items?.first.address?.street ?? ''}, ${widget.orderdata?.orderDetails?.items?.first.address?.city ?? ''}, ${widget.orderdata?.orderDetails?.items?.first.address?.state ?? ''} ${widget.orderdata?.orderDetails?.items?.first.address?.pincode ?? ''}",
                                      fontSize: .019,
                                    )
                                  ],
                                ),
                              ),
                              Divider(
                                color: AppColors.hintTclr.withOpacity(.2),
                                thickness: 1.5,
                              ),
                              CustomPadding(
                                vertical: .02,
                                horizontal: .04,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    CustomText(
                                        text: "Total Paid",
                                        fontSize: 0.019,
                                        fontWeight: FontWeight.w500),
                                    CustomText(
                                        text:
                                            "\$${(widget.orderdata?.orderDetails?.totalPaid ?? 0.0).toDouble().toStringAsFixed(2)}",
                                        fontSize: 0.02,
                                        color: AppColors.green,
                                        fontWeight: FontWeight.w600),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: -(Sizes.height * 0.085 / 2),
                          left: 0,
                          right: 0,
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              width: Sizes.height * 0.085,
                              height: Sizes.height * 0.085,
                              decoration: BoxDecoration(
                                color: AppColors.tWhiteColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: CustomImage(
                                  image: AppImages.cartSuccess,
                                  height: .2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  CustomPadding(
                    top: .02,
                    bottom: .02,
                    // vertical: .025,
                    // horizontal: .05,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                          10), // <-- This will clip EVERYTHING inside
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFF47923),
                                  Color(0xFF04F24D),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                            padding: const EdgeInsets.all(1),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                vertical: Sizes.height * 0.03,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: AppColors.tWhiteColor,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const CustomText(
                                    text: "Time Left for Pickup",
                                    fontSize: 0.018,
                                    color: AppColors.tBlackColor,
                                    textAlign: TextAlign.center,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  const CustomSizedBox(width: .04),
                                  CustomText(
                                    text: _timeLeft,
                                    fontSize: 0.022,
                                    color: Color(0XFFFF8D28),
                                    textAlign: TextAlign.center,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 3,
                            left: 0,
                            child: CustomImage(
                              image: AppImages.cartbox,
                              height: .08,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  CustomPadding(
                    vertical: .025,
                    // horizontal: .05,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Sizes.width * 0.05,
                        vertical: Sizes.height * 0.018,
                      ),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: const Color(0XFFFFFBEB),
                          border: Border.all(
                            color: const Color(0XFFA38A26),
                          )),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomImage(
                            image: AppImages.cartTimer,
                            height: .024,
                            color: Color(0XFF998227),
                          ),
                          CustomSizedBox(width: .02),
                          CustomText(
                            text: "Please arrive with in the pickup window",
                            fontSize: 0.017,
                            color: Color(0XFFA38A26),
                            textAlign: TextAlign.center,
                            fontWeight: FontWeight.w500,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
