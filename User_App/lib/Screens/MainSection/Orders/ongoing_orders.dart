import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resqbox_user/Controllers/orders_controller.dart';
import 'package:resqbox_user/Models/orders_model.dart';
import 'package:resqbox_user/Screens/MainSection/Orders/order_details.dart';
import 'package:resqbox_user/Screens/MainSection/Orders/orders.dart';
import 'package:resqbox_user/Utils/colors.dart';
import 'package:resqbox_user/Utils/const_validations.dart';
import 'package:resqbox_user/Utils/custom_padding.dart';
import 'package:resqbox_user/Utils/custom_sizedbox.dart';
import 'package:resqbox_user/Utils/custom_tap.dart';
import 'package:resqbox_user/Utils/customtext.dart';
import 'package:resqbox_user/Utils/horizontal_line.dart';
import 'package:resqbox_user/Utils/mediaquery.dart';
import 'package:resqbox_user/Utils/navigations.dart';

class OngoingOrders extends StatefulWidget {
  const OngoingOrders({super.key});

  @override
  State<OngoingOrders> createState() => _OngoingOrdersState();
}

class _OngoingOrdersState extends State<OngoingOrders> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Provider.of<OrdersController>(context, listen: false)
          .myOrdersApi(1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrdersController>(
        builder: (context, ordersController, child) {
      return Scaffold(
        backgroundColor: const Color(0XFFF6F6F6),
        body: ordersController.isMyOrdersLoading == true
            ? const Center(child: CircularProgressIndicator())
            : ordersController.ordersData?.orders?.isEmpty == true
                ? const Center(child: CustomText(text: "No orders found"))
                : CustomPadding(
                    vertical: .015,
                    child: ListView.builder(
                      itemCount:
                          ordersController.ordersData?.orders?.length ?? 0,
                      padding: EdgeInsets.zero,
                      itemBuilder: (context, index) {
                        return OrderWidget(
                            order: ordersController.ordersData?.orders?[index]);
                      },
                    ),
                  ),
      );
    });
  }
}

class OrderWidget extends StatelessWidget {
  const OrderWidget({
    super.key,
    required this.order,
  });

  final OrdersData? order;

  @override
  Widget build(BuildContext context) {
    return CustomPadding(
      horizontal: .04,
      vertical: .004,
      child: CustomTap(
        onTap: () {
          NavigateTo().nextPage(
              child: OrderDetails(from: 'ongoing', orderId: order?.orderId));
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: Sizes.height * .01,
            horizontal: Sizes.width * .0,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: AppColors.tWhiteColor,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomPadding(
                horizontal: .04,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: CustomText(
                            text: (order?.title ?? '')
                                .split(' ')
                                .map((word) => word.isNotEmpty
                                    ? '${word[0].toUpperCase()}${word.substring(1)}'
                                    : '')
                                .join(' '),
                            fontSize: .018,
                            color: AppColors.tPrimaryColor,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                            decorationThickness: 1,
                            overflow: TextOverflow.ellipsis,
                            decorationHeight: 2,
                            decorationColor: AppColors.tPrimaryColor,
                          ),
                        ),
                        CustomText(
                          text: formatDate(order?.orderedAt?.toString() ?? ''),
                          fontSize: .013,
                          fontWeight: FontWeight.w400,
                        )
                      ],
                    ),
                    CustomPadding(
                      top: .006,
                      bottom: .004,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustomText(
                            text: "Order ID -${order?.orderDisplayId}",
                            fontSize: .014,
                            color: AppColors.tBlackColor,
                            fontWeight: FontWeight.w400,
                          ),
                          CustomText(
                            text:
                                formatTime(order?.orderedAt?.toString() ?? ''),
                            fontSize: .013,
                            fontWeight: FontWeight.w400,
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              CustomPadding(
                vertical: .008,
                child: Divider(
                  height: 2,
                  color: const Color(0XFFD9D9D9).withOpacity(.7),
                ),
              ),
              CustomPadding(
                horizontal: .04,
                child: const CustomText(
                  text: "Items",
                  fontSize: .014,
                  fontWeight: FontWeight.w400,
                ),
              ),
              CustomPadding(
                horizontal: .05,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CustomSizedBox(height: .009),
                    ...order!.items!.map(
                      (item) => Padding(
                        padding: EdgeInsets.only(bottom: Sizes.height * .006),
                        child: CustomText(
                          text: "${item.quantity} X ${item.name}",
                          fontSize: .016,
                          color: const Color(0XFF1C2130),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    const CustomSizedBox(height: .014),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomText(
                          text: "Restaurant Name",
                          fontSize: .016,
                          color: AppColors.tBlackColor,
                          maxLines: 1,
                          fontWeight: FontWeight.w500,
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: CustomText(
                              text: (order?.restaurantName ?? '')
                                  .split(' ')
                                  .map((word) => word.isNotEmpty
                                      ? '${word[0].toUpperCase()}${word.substring(1)}'
                                      : '')
                                  .join(' '),
                              fontSize: .016,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              fontWeight: FontWeight.w700,
                              color: AppColors.tBlackColor,
                            ),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
              CustomPadding(
                vertical: 0.02,
                horizontal: .007,
                child: HorizontalDottedLine(
                  width: Sizes.width,
                  color: AppColors.hintTclr.withOpacity(0.8),
                ),
              ),
              CustomPadding(
                bottom: .006,
                left: .045,
                right: .045,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        const CustomText(
                          text: "Bill Amount",
                          fontSize: .014,
                          fontWeight: FontWeight.w400,
                        ),
                        CustomText(
                          text:
                              "\$ ${(order?.amount ?? 0.0).toDouble().toStringAsFixed(2)}",
                          fontSize: .016,
                          fontWeight: FontWeight.w600,
                        )
                      ],
                    ),
                    Container(
                      height: Sizes.height * .04,
                      width: Sizes.width * .3,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: const Color(0XFFE9FFED)),
                      child: Center(
                        child: CustomText(
                          text: order?.status ?? '',
                          color: const Color(0XFF00D341),
                          fontSize: 0.016,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class Order {
  final String orderName;
  final String orderId;
  final String date;
  final String time;
  final String restaurantName;
  final String billAmount;
  final String status;
  final List<String> foodItems;

  const Order({
    required this.orderName,
    required this.orderId,
    required this.date,
    required this.time,
    required this.restaurantName,
    required this.billAmount,
    required this.status,
    required this.foodItems,
  });
}
