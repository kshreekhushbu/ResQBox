import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resqboxvendor/Controller/OrdersController.dart';
import 'package:resqboxvendor/Utils/colors.dart';
import 'package:resqboxvendor/Utils/custom_appbar.dart';
import 'package:resqboxvendor/Utils/custom_border_btn.dart';
import 'package:resqboxvendor/Utils/images.dart';
import 'package:resqboxvendor/Utils/navigations.dart';
import 'package:resqboxvendor/Utils/textstyles.dart';
import 'package:resqboxvendor/Utils/toast.dart';

class NewOrderDetailView extends StatefulWidget {
  final int orderId;
  const NewOrderDetailView({super.key, required this.orderId});

  @override
  State<NewOrderDetailView> createState() => _NewOrderDetailViewState();
}

class _NewOrderDetailViewState extends State<NewOrderDetailView> {
  @override
  void initState() {
    super.initState();
    final controller = Provider.of<OrdersController>(context, listen: false);
    controller.getOrderDetailsById(widget.orderId);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrdersController>(
      builder: (context, controller, child) {
        final order = controller.orderDetails;

        if (controller.isLoadingOrderDetails) {
          return Scaffold(
            appBar: CustomAppBar(
              title: "Order Details",
              isLeading: true,
              backTap: () {
                NavigateTo().backPage();
              },
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (order == null) {
          return Scaffold(
            appBar: CustomAppBar(
              title: "Order Details",
              isLeading: true,
              backTap: () {
                NavigateTo().backPage();
              },
            ),
            body: const Center(child: Text("Order not found")),
          );
        }

        final totalItems = order.items?.length ?? 0;
        final itemTotal = order.itemTotal ?? 0.0;
        final gstAmount = order.gstAmount ?? 0.0;
        final serviceFeePercent =
            order.restaurantOrderInvoice?.serviceFeePercent ?? 0.0;
        final serviceFeeAmount = (itemTotal * serviceFeePercent) / 100;
        final netEarnings = itemTotal - serviceFeeAmount;
        // final platformFee = order.platformFee ?? 0.0;
        // final totalAmount = order.totalAmount ?? 0.0;

        return Scaffold(
          appBar: CustomAppBar(
            title: controller.getStatusDisplayText(order.status),
            isLeading: true,
            backTap: () {
              NavigateTo().backPage();
            },
          ),
          bottomNavigationBar: (order.status?.toUpperCase() == "PENDING")
              ? null
              : Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: CustomRectBtn(
                    width: double.infinity,
                    onTap: () {
                      if (order.status?.toUpperCase() == "PICKED" ||
                          order.status?.toUpperCase() == "NO_SHOW") {
                        controller.downloadOrderInvoice(
                          order.restaurantOrderInvoice?.pdfUrl,
                        );
                      } else {
                        customToast(
                          message:
                              "Your invoice will be generated after order completion.",
                        );
                      }
                    },
                    height: 49,
                    borderRadius: 8,
                    leading: Center(
                      child: controller.isDownloadingPdf
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Order Invoice",
                                  style: AppTextStyles.size16SemiBold.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                    color: AppColors.mainAppColr,
                    borderColor: AppColors.mainAppColr,
                    textColor: Colors.white,
                  ),
                ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.getStatusDisplayText(order.status),
                    style: AppTextStyles.size16Medium.copyWith(
                      color: AppColors.mainAppColr,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "#${order.orderDisplayId}",
                        style: AppTextStyles.size14Regular,
                      ),
                      Text(
                        controller.formatFullDateAndTime(order.orderedAt),
                        style: AppTextStyles.size12Regular.copyWith(
                          color: const Color(0xff727272),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Item Details",
                    style: AppTextStyles.size12Medium.copyWith(
                      color: const Color(0xff727272),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (order.items != null && order.items!.isNotEmpty)
                    ...order.items!.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildItemRow(
                          image: item.menu?.isVegetarian == true
                              ? AppImages.isVeg
                              : AppImages.nonVeg,
                          title: item.menu?.name ?? "Item",
                          qty: item.quantity?.toString() ?? "1",
                          price:
                              "\$ ${item.totalPrice?.toStringAsFixed(2) ?? '0.00'}",
                        ),
                      );
                    }).toList(),
                  const SizedBox(height: 16),
                  _divider(),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Text(
                        "Net Amount",
                        style: AppTextStyles.size12Medium.copyWith(
                          color: const Color(0xff7A7A7A),
                        ),
                      ),

                      const Spacer(),
                      Text(
                        "\$ ${(itemTotal - gstAmount).toStringAsFixed(2)}",
                        style: AppTextStyles.size12SemiBold,
                      ),
                    ],
                  ),

                  if (gstAmount > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          "GST",
                          style: AppTextStyles.size12Medium.copyWith(
                            color: const Color(0xff7A7A7A),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "\$ ${gstAmount.toStringAsFixed(2)}",
                          style: AppTextStyles.size12Medium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],

                  Row(
                    children: [
                      Text("Total", style: AppTextStyles.size14Medium),
                      const SizedBox(width: 10),
                      Text(
                        "$totalItems ${totalItems == 1 ? 'Item' : 'Items'}",
                        style: AppTextStyles.size12Medium.copyWith(
                          color: const Color(0xff7A7A7A),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        "\$ ${itemTotal.toStringAsFixed(2)}",
                        style: AppTextStyles.size12SemiBold,
                      ),
                    ],
                  ),

                  // if (deliveryFee > 0) ...[
                  //   const SizedBox(height: 8),
                  //   Row(
                  //     children: [
                  //       Text(
                  //         "Delivery Fee",
                  //         style: AppTextStyles.size12Medium.copyWith(
                  //           color: const Color(0xff7A7A7A),
                  //         ),
                  //       ),
                  //       const Spacer(),
                  //       Text(
                  //         "$ ${deliveryFee.toStringAsFixed(2)}",
                  //         style: AppTextStyles.size12Medium,
                  //       ),
                  //     ],
                  //   ),
                  // ],
                  // if (platformFee > 0) ...[
                  //   const SizedBox(height: 8),
                  //   Row(
                  //     children: [
                  //       Text(
                  //         "Platform Fee",
                  //         style: AppTextStyles.size14SemiBold.copyWith(
                  //           color: const Color(0xff7A7A7A),
                  //         ),
                  //       ),
                  //       const Spacer(),
                  //       Text(
                  //         "\$ ${platformFee.toStringAsFixed(2)}",
                  //         style: AppTextStyles.size12Medium.copyWith(
                  //           color: AppColors.greenColor,
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ],
                  const SizedBox(height: 16),
                  _divider(),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Text(
                        "Service Fee",
                        style: AppTextStyles.size12Medium.copyWith(
                          color: const Color(0xff7A7A7A),
                        ),
                      ),

                      const Spacer(),
                      Text(
                        "- \$ ${serviceFeeAmount.toStringAsFixed(2)}",
                        style: AppTextStyles.size12SemiBold.copyWith(
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Text("Net Earnings", style: AppTextStyles.size14Medium),

                      const Spacer(),
                      Text(
                        "\$ ${netEarnings.toStringAsFixed(2)}",
                        style: AppTextStyles.size12SemiBold.copyWith(
                          color: const Color(0xff16A52F),
                        ),
                      ),
                    ],
                  ),
                  // const SizedBox(height: 16),
                  // Row(
                  //   children: [
                  //     Text(
                  //       "Final Total",
                  //       style: AppTextStyles.size16SemiBold.copyWith(
                  //         color: const Color(0xff111827),
                  //       ),
                  //     ),
                  //     const Spacer(),
                  //     Text(
                  //       "\$ ${totalAmount.toStringAsFixed(2)}",
                  //       style: AppTextStyles.size12SemiBold,
                  //     ),
                  //   ],
                  // ),
                  const SizedBox(height: 16),
                  // _divider(),
                  // const SizedBox(height: 16),
                  // Text("Customer Info", style: AppTextStyles.size14SemiBold),
                  // const SizedBox(height: 16),
                  // Row(
                  //   children: [
                  //     ClipOval(
                  //       child: order.user?.profilePicture != null
                  //           ? Image.network(
                  //               order.user!.profilePicture!,
                  //               height: 45,
                  //               width: 45,
                  //               fit: BoxFit.cover,
                  //               errorBuilder: (context, error, stackTrace) =>
                  //                   _buildInitialAvatar(order.user?.name),
                  //             )
                  //           : _buildInitialAvatar(order.user?.name),
                  //     ),
                  //     const SizedBox(width: 8),
                  //     Expanded(
                  //       child: Column(
                  //         crossAxisAlignment: CrossAxisAlignment.start,
                  //         children: [
                  //           Text(
                  //             order.user?.name ?? "Customer",
                  //             overflow: TextOverflow.ellipsis,
                  //             style: AppTextStyles.size16Regular,
                  //           ),
                  //           Column(
                  //             crossAxisAlignment: CrossAxisAlignment.start,
                  //             children: [
                  //               Text(
                  //                 "+91 9977 XXXXXX",
                  //                 overflow: TextOverflow.ellipsis,
                  //                 style: AppTextStyles.size14Regular.copyWith(
                  //                   color: Color(0xff7A7A7A),
                  //                 ),
                  //               ),
                  //               Text(
                  //                 "maXXXXell@gmail.com",
                  //                 overflow: TextOverflow.ellipsis,
                  //                 style: AppTextStyles.size14Regular.copyWith(
                  //                   color: Color(0xff7A7A7A),
                  //                 ),
                  //               ),
                  //             ],
                  //           ),
                  //         ],
                  //       ),
                  //     ),
                  //     // Image.asset(AppImages.chat, height: 28, width: 28),
                  //     // const SizedBox(width: 12),
                  //     // Image.asset(AppImages.orderCall, height: 28, width: 28),
                  //   ],
                  // ),
                  // const SizedBox(height: 24),
                  // _divider(),
                  // const SizedBox(height: 24),
                  // Text(
                  //   "Order Type",
                  //   style: AppTextStyles.size12Regular.copyWith(
                  //     color: const Color(0xff7A7A7A),
                  //   ),
                  // ),
                  // const SizedBox(height: 16),
                  // Row(
                  //   children: [
                  //     Container(
                  //       padding: const EdgeInsets.all(8),
                  //       decoration: BoxDecoration(
                  //         color: const Color(0xffFFF4E6),
                  //         borderRadius: BorderRadius.circular(8),
                  //       ),
                  //       child: Image.asset(
                  //         isPickup ? AppImages.pickUp : AppImages.homeDelivery,
                  //         height: 30,
                  //         width: 30,
                  //       ),
                  //     ),
                  //     const SizedBox(width: 12),
                  //     Expanded(
                  //       child: Text(
                  //         isPickup
                  //             ? "Pickup at Kitchen"
                  //             : "Home Delivery${distance.isNotEmpty ? ' - $distance away' : ''}",
                  //         maxLines: 1,
                  //         overflow: TextOverflow.ellipsis,
                  //         style: AppTextStyles.size12Medium.copyWith(
                  //           color: const Color(0xff727272),
                  //         ),
                  //       ),
                  //     ),
                  //   ],
                  // ),
                  if (order.status?.toUpperCase() == "PENDING") ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          flex: 2,
                          child: CustomRectBtn(
                            color: AppColors.tWhiteColor,
                            borderColor: AppColors.mainAppColr,
                            height: 38,
                            width: MediaQuery.of(context).size.width / 5,
                            text: "Reject",
                            onTap: () {
                              controller.rejectOrder(order.orderId ?? 0);
                              NavigateTo().backPage();
                            },
                            textColor: AppColors.mainAppColr,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          flex: 3,
                          child: CustomRectBtn(
                            color: const Color(0xff00D341),
                            borderColor: const Color(0xff00D341),
                            height: 38,
                            width: MediaQuery.of(context).size.width / 2.9,
                            text: "Accept Order",
                            onTap: () {
                              controller.acceptOrder(order.orderId ?? 0);
                              NavigateTo().backPage();
                            },
                            textColor: AppColors.tWhiteColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildItemRow({
    required String image,
    required String title,
    required String qty,
    required String price,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(image, height: 15, width: 15),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.size12Medium,
          ),
        ),
        const SizedBox(width: 8),
        Text("x $qty", style: AppTextStyles.size12Medium),
        const SizedBox(width: 20),
        Text(price, style: AppTextStyles.size12SemiBold),
      ],
    );
  }

  Widget _divider() => Container(
    width: double.infinity,
    height: 1,
    color: const Color(0xffE2E2E2),
  );
}
