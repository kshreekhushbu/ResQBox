import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resqboxvendor/Controller/InvoicesController.dart';
import 'package:resqboxvendor/Screens/Invoice/invoice_deatiled.dart';
import 'package:resqboxvendor/Utils/custom_appbar.dart';
import 'package:resqboxvendor/Utils/textstyles.dart';
import 'package:resqboxvendor/utils/colors.dart';
import 'package:resqboxvendor/Widgets/team_member_access_wrapper.dart';
import 'package:intl/intl.dart';

class Invoices extends StatefulWidget {
  const Invoices({super.key});

  @override
  State<Invoices> createState() => _InvoicesState();
}

class _InvoicesState extends State<Invoices>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  final TextEditingController searchController = TextEditingController();
  InvoicesController? _controller;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller == null) {
      _controller = context.read<InvoicesController>();
      _controller!.getPayoutInvoices();
      _controller!.getMonthlyInvoices();
    }
  }

  @override
  void dispose() {
    tabController.dispose();
    searchController.dispose();
    _controller?.clearInvoices();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffF1F4FC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(130),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomAppBar(
              title: "Invoice",
              isLeading: false,
              // backTap: () {
              //   NavigateTo().backPage();
              // },
              isFromTabsScreen: false,
              leadingHeight: 24,
            ),
            // Container(
            //   color: Colors.white,
            //   padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            //   child: Row(
            //     children: [
            //       Expanded(
            //         child: Container(
            //           height: 45,
            //           // decoration: BoxDecoration(
            //           //   borderRadius: BorderRadius.circular(8),
            //           //   border: Border.all(color: Color(0xffD6D6D6)),
            //           // ),
            //           child: CustomTextFormField(
            //             image: AppImages.search,
            //             isfilled: false,
            //             controller: searchController,
            //             hintText: "Search...",
            //           ),
            //         ),
            //       ),

            //       const SizedBox(width: 12),

            //       GestureDetector(
            //         onTap: () {},
            //         child: Container(
            //           height: 45,
            //           width: 45,
            //           decoration: BoxDecoration(
            //             color: Color(0xff00D341),
            //             borderRadius: BorderRadius.circular(8),
            //           ),
            //           child: const Icon(
            //             Icons.calendar_month,
            //             color: Colors.white,
            //           ),
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
          ],
        ),
      ),
      body: TeamMemberAccessWrapper(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              child: TabBar(
                controller: tabController,
                indicatorColor: AppColors.mainAppColr,
                labelColor: AppColors.mainAppColr,
                unselectedLabelColor: const Color(0xff4B5563),
                indicatorWeight: 3.0,
                labelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(text: "Weekly"),
                  Tab(text: "Monthly"),
                ],
              ),
            ),
            // TabBarView
            Expanded(
              child: TabBarView(
                controller: tabController,
                children: [buildWeeklyInvoiceList(), buildMonthlyInvoiceList()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildWeeklyInvoiceList() {
    return Consumer<InvoicesController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return Center(
            child: CircularProgressIndicator(color: Color(0xff00D341)),
          );
        }

        if (controller.payoutInvoices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  "No invoices found",
                  style: AppTextStyles.size16Medium.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.payoutInvoices.length,
          itemBuilder: (context, index) {
            final invoice = controller.payoutInvoices[index];

            // Format dates
            final startDate = DateTime.parse(invoice.periodStart);
            final endDate = DateTime.parse(invoice.periodEnd);
            final dateFormat = DateFormat('MMM dd');
            final dateRange =
                '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}';

            return InvoiceCard(
              date: dateRange,
              amount: '+\$${invoice.payoutAmount}',
              orders: '${invoice.ordersCount} Orders',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InvoiceDetailScreen(
                      dateRange: dateRange,
                      payoutId: invoice.payoutId,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget buildMonthlyInvoiceList() {
    return Consumer<InvoicesController>(
      builder: (context, controller, child) {
        if (controller.isMonthlyInvoicesLoading) {
          return Center(
            child: CircularProgressIndicator(color: Color(0xff00D341)),
          );
        }

        if (controller.monthlyInvoices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  "No monthly invoices found",
                  style: AppTextStyles.size16Medium.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.monthlyInvoices.length,
          itemBuilder: (context, index) {
            final invoice = controller.monthlyInvoices[index];

            // Format dates
            final startDate = DateTime.parse(invoice.periodStart);
            final endDate = DateTime.parse(invoice.periodEnd);
            final dateFormat = DateFormat('MMM dd, yyyy');
            final dateRange =
                '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}';

            return InvoiceCard(
              date: dateRange,
              amount: '+\$${invoice.netAmount}',
              orders: '${invoice.ordersCount} Orders',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InvoiceDetailScreen(
                      dateRange: dateRange,
                      payoutId: invoice.invoiceId,
                      isMonthly: true,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class InvoiceCard extends StatelessWidget {
  final String date;
  final String amount;
  final String orders;
  final VoidCallback onTap;

  const InvoiceCard({
    super.key,
    required this.date,
    required this.amount,
    required this.orders,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.mainAppColr),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(date, style: AppTextStyles.size14SemiBold),
                  SizedBox(height: 8),
                  Text(
                    orders,
                    style: AppTextStyles.size14Regular.copyWith(
                      color: Color(0xff4B5563),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            amount,
                            style: AppTextStyles.size14Bold.copyWith(
                              color: Color(0xff16A34A),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Payout',
                            style: AppTextStyles.size14Regular.copyWith(
                              color: Color(0xff4B5563),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.chevron_right, color: Colors.black),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
