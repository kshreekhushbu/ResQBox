import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resqboxvendor/Controller/TransactionsController.dart';
import 'package:resqboxvendor/Utils/colors.dart';
import 'package:resqboxvendor/Utils/custom_appbar.dart';
import 'package:resqboxvendor/Utils/custom_border_btn.dart';
import 'package:resqboxvendor/Utils/images.dart';
import 'package:resqboxvendor/Utils/navigations.dart';
import 'package:resqboxvendor/Utils/textstyles.dart';

import 'package:resqboxvendor/Utils/toast.dart';
import 'package:intl/intl.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  TransactionsController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller == null) {
      _controller = context.read<TransactionsController>();
      _controller!.getAllTransactions();
    }
  }

  @override
  void dispose() {
    // Clear date filters when leaving the screen
    _controller?.clearFilters();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final controller = context.read<TransactionsController>();

    if (!isFromDate && controller.fromDate == null) {
      customToast(message: "Please select From Date first");
      return;
    }

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: isFromDate
          ? (controller.fromDate ?? DateTime.now())
          : (controller.toDate ?? controller.fromDate ?? DateTime.now()),
      firstDate: isFromDate
          ? DateTime(2023)
          : (controller.fromDate ?? DateTime(2023)),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: Color(0xff00D341)),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      if (isFromDate) {
        controller.setFromDate(pickedDate);
      } else {
        controller.setToDate(pickedDate);
      }
    }
  }

  String _maskName(String? name) {
    if (name == null || name.isEmpty) return "Unknown";
    final trimmedName = name.trim();
    if (trimmedName.length <= 2) return trimmedName;
    return "${trimmedName[0]}${'*' * (trimmedName.length - 2)}${trimmedName[trimmedName.length - 1]}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8F8F8),
      appBar: CustomAppBar(
        title: "All Transactions",
        isLeading: true,
        backTap: () {
          NavigateTo().backPage();
        },
        // actions: [
        //   Image.asset(AppImages.calendar, height: 24, width: 24),
        //   const SizedBox(width: 24),
        // ],
      ),
      body: Consumer<TransactionsController>(
        builder: (context, controller, child) {
          return SingleChildScrollView(
            child: Column(
              children: [
                // 🟡 Date Filters
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(16.0),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selectDate(context, true),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "From Date",
                                style: AppTextStyles.size16Medium.copyWith(
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xffF3F4F8),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xffE2E2E2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      controller.fromDate == null
                                          ? "From Date"
                                          : DateFormat(
                                              'dd/MM/yyyy',
                                            ).format(controller.fromDate!),
                                      style: AppTextStyles.size16Regular
                                          .copyWith(
                                            color: controller.fromDate == null
                                                ? const Color(0xff4B5563)
                                                : Colors.black,
                                          ),
                                    ),
                                    Image.asset(
                                      AppImages.calendar,
                                      height: 20,
                                      width: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selectDate(context, false),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "To Date",
                                style: AppTextStyles.size16Medium.copyWith(
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xffF3F4F8),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xffE2E2E2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      controller.toDate == null
                                          ? "To Date"
                                          : DateFormat(
                                              'dd/MM/yyyy',
                                            ).format(controller.toDate!),
                                      style: AppTextStyles.size16Regular
                                          .copyWith(
                                            color: controller.toDate == null
                                                ? const Color(0xff4B5563)
                                                : Colors.black,
                                          ),
                                    ),
                                    Image.asset(
                                      AppImages.calendar,
                                      height: 20,
                                      width: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // 🟢 Transactions List
                if (controller.isLoading)
                  Container(
                    padding: EdgeInsets.all(50),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xff00D341),
                      ),
                    ),
                  )
                else if (controller.transactions.isEmpty)
                  Container(
                    padding: EdgeInsets.all(50),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            "No transactions found",
                            style: AppTextStyles.size16Medium.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.transactions.length,
                    itemBuilder: (context, index) {
                      final tx = controller.transactions[index];
                      final dateFormat = DateFormat('dd MMM yyyy');
                      final formattedDate = dateFormat.format(
                        DateTime.parse(tx.date),
                      );

                      return Container(
                        margin: EdgeInsets.only(bottom: 5),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        decoration: const BoxDecoration(color: Colors.white),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Order No: #${tx.orderNumber ?? tx.orderId}",
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyles.size16Medium
                                            .copyWith(color: Colors.black),
                                      ),
                                      Text(
                                        "\$ ${tx.amount}",
                                        style: AppTextStyles.size16SemiBold
                                            .copyWith(color: Colors.black),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "${_maskName(tx.customerName)} • $formattedDate",
                                          style: AppTextStyles.size14Regular
                                              .copyWith(
                                                color: Color(0xff4B5563),
                                              ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            25,
                                          ),
                                          color: Color(0xffDFFFE4),
                                        ),
                                        child: Text(
                                          "Completed",
                                          style: AppTextStyles.size14Regular
                                              .copyWith(
                                                color: Color(0xff16A52F),
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
                    },
                  ),
              ],
            ),
          );
        },
      ),

      bottomNavigationBar: Consumer<TransactionsController>(
        builder: (context, controller, child) {
          return Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey),
            ),
            child: Row(
              children: [
                Flexible(
                  child: CustomRectBtn(
                    color: AppColors.tWhiteColor,
                    borderColor: AppColors.mainAppColr,
                    height: 49,
                    width: double.infinity,
                    leading: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (controller.isSendingMail)
                          SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: AppColors.black131313,
                              strokeWidth: 2,
                            ),
                          )
                        else ...[
                          Image.asset(
                            AppImages.dashboardMail,
                            height: 22,
                            width: 22,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            "Send to Mail",
                            style: AppTextStyles.size16SemiBold,
                          ),
                        ],
                      ],
                    ),
                    onTap: controller.isSendingMail
                        ? () {}
                        : () {
                            controller.displayShareSheet();
                          },
                    textColor: AppColors.black131313,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: CustomRectBtn(
                    color: AppColors.mainAppColr,
                    borderColor: AppColors.mainAppColr,
                    height: 49,
                    width: double.infinity,
                    leading: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (controller.isDownloading)
                          SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        else ...[
                          Image.asset(
                            AppImages.downlaod,
                            height: 22,
                            width: 22,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            "Download",
                            style: AppTextStyles.size16SemiBold.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                    onTap: controller.isDownloading
                        ? () {}
                        : () {
                            controller.downloadPDF();
                          },
                    textColor: AppColors.tWhiteColor,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
