import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resqbox_user/Controllers/orders_controller.dart';
import 'package:resqbox_user/Models/orders_model.dart';
import 'package:resqbox_user/Screens/MainSection/Orders/order_details.dart';
import 'package:resqbox_user/Screens/MainSection/Orders/rating_screen.dart';
import 'package:resqbox_user/Utils/active_btn.dart';
import 'package:resqbox_user/Utils/colors.dart';
import 'package:resqbox_user/Utils/const_validations.dart';
import 'package:resqbox_user/Utils/custom_border_btn.dart';
import 'package:resqbox_user/Utils/custom_padding.dart';
import 'package:resqbox_user/Utils/custom_tap.dart';
import 'package:resqbox_user/Utils/customtext.dart';
import 'package:resqbox_user/Utils/mediaquery.dart';
import 'package:resqbox_user/Utils/navigations.dart';
import 'package:resqbox_user/Utils/network_image.dart';
import 'package:resqbox_user/Utils/toast.dart';

class PastOrders extends StatefulWidget {
  const PastOrders({super.key});

  @override
  State<PastOrders> createState() => _PastOrdersState();
}

class _PastOrdersState extends State<PastOrders> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Provider.of<OrdersController>(context, listen: false)
          .myOrdersApi(2);
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
                    // vertical: .02,
                    horizontal: .04,
                    child: ListView.builder(
                      padding: EdgeInsets.only(
                        top: Sizes.height * .02,
                        bottom: Sizes.height * .02,
                      ),
                      itemCount: ordersController.ordersData?.orders?.length,
                      itemBuilder: (context, index) => Padding(
                        padding: EdgeInsets.only(
                          bottom: index ==
                                  (ordersController
                                              .ordersData?.orders?.length ??
                                          0) -
                                      1
                              ? 0
                              : Sizes.height * .01,
                        ),
                        child: _PastOrderCard(
                            order: ordersController.ordersData?.orders?[index]),
                      ),
                    ),
                  ),
      );
    });
  }
}

class _PastOrderCard extends StatelessWidget {
  const _PastOrderCard({required this.order});

  final OrdersData? order;

  @override
  Widget build(BuildContext context) {
    return CustomTap(
      onTap: () {
        NavigateTo().nextPage(
            child: OrderDetails(from: 'past', orderId: order?.orderId));
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: Sizes.height * .02,
          horizontal: Sizes.width * .03,
        ),
        width: Sizes.width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: AppColors.tWhiteColor,
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CustomNetworkImage(
                    url: order?.items?.first.image ?? '',
                    // "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTMI1gdlIRJ86PM5NXTwBTQB1URrtOm22wfcQ&s",
                    height: .11,
                    width: .23,
                    fit: BoxFit.cover,
                  ),
                ),
                Expanded(
                  child: CustomPadding(
                    left: 0.02,
                    right: .02,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: CustomText(
                                text: "OrderId - ${order?.orderDisplayId}",
                                //  (order?.title ?? '')
                                //     .split(' ')
                                //     .map((word) => word.isNotEmpty
                                //         ? '${word[0].toUpperCase()}${word.substring(1)}'
                                //         : '')
                                //     .join(' '),
                                fontWeight: FontWeight.w600,
                                fontSize: 0.016,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ),
                        CustomPadding(
                          top: 0.004,
                          child: CustomText(
                            text: order?.status == "REJECTED"
                                ? "Your Order Rejected"
                                : order?.status == "NO_SHOW"
                                    ? "You haven't picked up your order"
                                    : "Pickedup on ${formatDate(order?.orderedAt?.toString() ?? '')} ${formatTime(order?.orderedAt?.toString() ?? '')}",
                            color: order?.status == "REJECTED"
                                ? AppColors.red.withOpacity(.4)
                                : const Color(0XFF989898),
                            fontWeight: FontWeight.w500,
                            fontSize: 0.014,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        CustomPadding(
                          top: 0.006,
                          child: CustomText(
                            text: (order?.restaurantName ?? '')
                                .split(' ')
                                .map((word) => word.isNotEmpty
                                    ? '${word[0].toUpperCase()}${word.substring(1)}'
                                    : '')
                                .join(' '),
                            color: const Color(0XFF989898),
                            fontWeight: FontWeight.w500,
                            fontSize: 0.016,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                CustomText(
                  text:
                      "\$ ${(order?.amount ?? 0.0).toDouble().toStringAsFixed(2)}",
                  fontWeight: FontWeight.w900,
                  fontSize: 0.016,
                ),
              ],
            ),
            order?.status == "REJECTED"
                ? SizedBox.shrink()
                : Column(
                    children: [
                      CustomPadding(
                        vertical: .015,
                        child: Divider(
                          height: 2,
                          color: const Color(0XFFD9D9D9).withOpacity(.7),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          order?.rating == "0"
                              ? CustomBorderBtn(
                                  height: Sizes.height * .048,
                                  width: Sizes.width * .42,
                                  text: "Give Rating",
                                  onTap: () {
                                    NavigateTo().nextPage(
                                        child: RatingScreen(
                                            orderId: order?.orderId,
                                            kitchenIdImage:
                                                order?.kitchenImage ?? '',
                                            foodIdImage:
                                                order?.items?.first.image ??
                                                    ''));
                                  },
                                  fontSize: 0.016,
                                  borderColor: AppColors.tPrimaryColor,
                                  textColor: AppColors.tBlackColor)
                              : SizedBox.shrink(),
                          ActiveButton(
                            height: Sizes.height * .048,
                            width: Sizes.width * .42,
                            text: "Download Invoice",
                            fontSize: .016,
                            borderRadius: 5,
                            onPressed: () {
                              debugPrint(
                                  "VVVVVVVVVVVV ${order?.orderInvoice?.pdfUrl}");
                              if (order?.orderInvoice?.pdfUrl != null) {
                                Provider.of<OrdersController>(context,
                                        listen: false)
                                    .downloadUploadedFiles(
                                        order?.orderInvoice?.pdfUrl ?? '');
                              } else {
                                customToast(message: "Invoice not available");
                              }
                            },
                          )
                        ],
                      ),
                    ],
                  )
          ],
        ),
      ),
    );
  }
}

class PastOrder {
  final String title;
  final String deliveredInfo;
  final String restaurantAddress;
  final String amount;
  final String imageUrl;

  const PastOrder({
    required this.title,
    required this.deliveredInfo,
    required this.restaurantAddress,
    required this.amount,
    required this.imageUrl,
  });
}
