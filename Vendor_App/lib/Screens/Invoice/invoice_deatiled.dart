import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resqboxvendor/Controller/InvoicesController.dart';
import 'package:resqboxvendor/Models/monthly_invoice_details_model.dart'
    as monthly;
import 'package:resqboxvendor/Models/payout_invoice_details_model.dart';
import 'package:resqboxvendor/Utils/custom_appbar.dart';
import 'package:resqboxvendor/Utils/custom_border_btn.dart';
import 'package:resqboxvendor/Utils/navigations.dart';
import 'package:resqboxvendor/Utils/textstyles.dart';
import 'package:resqboxvendor/utils/colors.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final String dateRange;
  final int payoutId;
  final bool isMonthly;

  const InvoiceDetailScreen({
    super.key,
    required this.dateRange,
    required this.payoutId,
    this.isMonthly = false,
  });

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  InvoicesController? _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller = context.read<InvoicesController>();
      if (widget.isMonthly) {
        _controller!.getMonthlyInvoiceDetails(widget.payoutId);
      } else {
        _controller!.getPayoutInvoiceDetails(widget.payoutId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: CustomAppBar(
        title: widget.dateRange,
        isLeading: true,
        backTap: () {
          NavigateTo().backPage();
        },
      ),
      body: Consumer<InvoicesController>(
        builder: (context, controller, child) {
          final isLoading = widget.isMonthly
              ? controller.isMonthlyDetailsLoading
              : controller.isDetailsLoading;

          if (isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.mainAppColr),
            );
          }

          final details = widget.isMonthly
              ? controller.monthlyInvoiceDetails
              : controller.invoiceDetails;

          if (details == null) {
            return Center(
              child: Text(
                'Failed to load invoice details',
                style: AppTextStyles.size16Medium,
              ),
            );
          }

          // Use dynamic access for common fields or map data
          // PayoutInvoiceDetails and MonthlyInvoiceDetails have same summary structure
          final summary = details is PayoutInvoiceDetails
              ? details.summary
              : (details as monthly.MonthlyInvoiceDetails).summary;

          final orders = details is PayoutInvoiceDetails
              ? details.orders
              : (details as monthly.MonthlyInvoiceDetails).orders;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(color: Colors.white),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Color(0xff2462EB)),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Description',
                                style: AppTextStyles.size12SemiBold.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'GST (%)',
                                style: AppTextStyles.size12SemiBold.copyWith(
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Net\nAmount',
                                style: AppTextStyles.size12SemiBold.copyWith(
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Total',
                                style: AppTextStyles.size12SemiBold.copyWith(
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildSummaryRow(
                        'Listed Price (LP)',
                        '\$${summary.breakdown?.listedPrice.gst ?? 0}',
                        '\$${summary.breakdown?.listedPrice.netAmount ?? 0}',
                        '\$${summary.breakdown?.listedPrice.total ?? 0}',
                        false,
                      ),
                      _buildSummaryRow(
                        bgColor: Color(0xffFFF5F2),
                        'Service Fee',
                        '\$${summary.breakdown?.serviceFee.gst ?? 0}',
                        '\$${summary.breakdown?.serviceFee.netAmount ?? 0}',
                        '\$${summary.breakdown?.serviceFee.total ?? 0}',
                        true,
                      ),
                      _buildSummaryRow(
                        'Total Payout',
                        '\$${summary.breakdown?.totalPayout.gst ?? 0}',
                        '\$${summary.breakdown?.totalPayout.netAmount ?? 0}',
                        '\$${summary.breakdown?.totalPayout.total ?? 0}',
                        false,
                        isTotal: true,
                      ),
                      const Divider(height: 1),
                      SizedBox(height: 16),

                      // Download Button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: CustomRectBtn(
                          width: double.infinity,
                          onTap: () {
                            controller.downloadInvoice(
                              isMonthly: widget.isMonthly,
                            );
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.file_download_outlined,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        "Download PDF",
                                        style: AppTextStyles.size16SemiBold
                                            .copyWith(color: Colors.white),
                                      ),
                                    ],
                                  ),
                          ),
                          color: AppColors.mainAppColr,
                          borderColor: AppColors.mainAppColr,
                          textColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'View all Orders',
                    style: AppTextStyles.size18Medium,
                  ),
                ),

                const SizedBox(height: 12),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return _buildOrderCard(order);
                  },
                ),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryRow(
    String description,
    String gst,
    String netAmount,
    String total,
    bool isNegative, {
    bool isTotal = false,
    Color? bgColor,
  }) {
    return Container(
      color: bgColor ?? Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: isTotal
                      ? Colors.black
                      : (isNegative ? Colors.red : Colors.black),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Text(
                gst,
                style: TextStyle(
                  fontSize: 14,
                  color: isTotal
                      ? Colors.green
                      : (isNegative ? Colors.red : Colors.black),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: Text(
                netAmount,
                style: TextStyle(
                  fontSize: 14,
                  color: isTotal
                      ? Colors.green
                      : (isNegative ? Colors.red : Colors.black),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: Text(
                total,
                style: TextStyle(
                  fontSize: 14,
                  color: isTotal
                      ? Colors.green
                      : (isNegative ? Colors.red : Colors.black),
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(InvoiceOrder order) {
    Color statusColor;
    String statusText = order.status;

    switch (order.status) {
      case 'PICKED':
        statusColor = Color(0xff16A52F);
        statusText = 'Picked Up';
        break;
      case 'PENDING':
        statusColor = Colors.orange;
        break;
      case 'ACCEPTED':
        statusColor = Colors.blue;
        break;
      case 'REJECTED':
      case 'NO_SHOW':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Order ID: #${order.orderId}",
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.size16Medium.copyWith(
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      "\$ ${order.totalAmount}",
                      style: AppTextStyles.size16SemiBold.copyWith(
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: order.items.map((item) {
                          return Text(
                            "${item.quantity}x ${item.name}",
                            style: AppTextStyles.size14Regular.copyWith(
                              color: Color(0xff3096EF),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        }).toList(),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        color: statusColor.withOpacity(0.1),
                      ),
                      child: Text(
                        statusText,
                        style: AppTextStyles.size14Regular.copyWith(
                          color: statusColor,
                        ),
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
  }
}
