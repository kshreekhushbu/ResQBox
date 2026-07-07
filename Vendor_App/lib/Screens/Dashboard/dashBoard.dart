import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:resqboxvendor/Controller/DashboardController.dart';
import 'package:resqboxvendor/Utils/access_helper.dart';
import 'package:resqboxvendor/Utils/colors.dart';

import 'package:resqboxvendor/Screens/Dashboard/transactions.dart';
import 'package:resqboxvendor/Utils/custom_appbar.dart';
import 'package:resqboxvendor/Utils/images.dart';
import 'package:resqboxvendor/Utils/navigations.dart';
import 'package:resqboxvendor/Utils/textstyles.dart';

class DashBoardScreen extends StatefulWidget {
  const DashBoardScreen({super.key});

  @override
  State<DashBoardScreen> createState() => _DashBoardScreenState();
}

class _DashBoardScreenState extends State<DashBoardScreen> {
  // Chart data
  final List<ChartData> orderData = [
    ChartData(day: 1, orders: 60, revenue: 45),
    ChartData(day: 2, orders: 50, revenue: 55),
    ChartData(day: 3, orders: 180, revenue: 30),
    ChartData(day: 4, orders: 220, revenue: 75),
    ChartData(day: 5, orders: 30, revenue: 25),
    ChartData(day: 6, orders: 290, revenue: 75),
    ChartData(day: 7, orders: 320, revenue: 75),
  ];

  final List<String> dayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  void initState() {
    super.initState();
    // Load initial dashboard data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<DashboardProvider>(context, listen: false);
      provider.getDashboardData('today');
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xffF6F6F6),
      appBar: CustomAppBar(
        title: "Dashboard",
        isLeading: false,
        // actions: [
        //   Image.asset(AppImages.search, height: 24, width: 24),
        //   const SizedBox(width: 24),
        // ],
      ),
      body: FutureBuilder<bool>(
        future: AccessHelper.isTeamMember(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final isTeamMember = snapshot.data ?? false;

          if (isTeamMember) {
            // Show access denied message for team members
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    "You Don't Have Access",
                    style: AppTextStyles.size20SemiBold,
                  ),
                  SizedBox(height: 10),
                  Text(
                    "This feature is only available for kitchen owners",
                    style: AppTextStyles.size14Medium.copyWith(
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Show normal dashboard for kitchen owners
          return Consumer<DashboardProvider>(
            builder: (context, dashboardProvider, child) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🟣 Total Income Card
                    Container(
                      height: 130,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Overall Income",
                                style: AppTextStyles.size16Medium.copyWith(
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // dashboardProvider.isLoading
                              //     ? CircularProgressIndicator(
                              //         strokeWidth: 2,
                              //         color: AppColors.mainAppColr,
                              //       )
                              //     :
                              Text(
                                "\$ ${dashboardProvider.dashboardData?.totalIncome?.toStringAsFixed(2) ?? '0.00'}",
                                style: AppTextStyles.size32SemiBold.copyWith(
                                  color: AppColors.mainAppColr,
                                ),
                              ),
                            ],
                          ),
                          SvgPicture.asset(AppImages.NewDashBoard),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        _buildFilterButton(
                          context,
                          "Today",
                          "today",
                          dashboardProvider,
                        ),
                        SizedBox(width: 6),
                        _buildFilterButton(
                          context,
                          "This Week",
                          "week",
                          dashboardProvider,
                        ),
                        SizedBox(width: 6),

                        _buildFilterButton(
                          context,
                          "This Month",
                          "month",
                          dashboardProvider,
                          hasIcon: false,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSummaryBox(
                          title: dashboardProvider.selectedFilter == 'today'
                              ? "Today Orders"
                              : dashboardProvider.selectedFilter == 'week'
                              ? "This Week Orders"
                              : "This Month Orders",
                          value: dashboardProvider.isLoading
                              ? "..."
                              : "${dashboardProvider.dashboardData?.summary?.orders ?? 0}",
                          color: const Color(0xff6FB671),
                          icon: AppImages.totalOrders,
                          width: (width - 48) / 2.8,
                        ),
                        _buildSummaryBox(
                          title: dashboardProvider.selectedFilter == 'today'
                              ? "Today's Revenue"
                              : dashboardProvider.selectedFilter == 'week'
                              ? "This Week Revenue"
                              : "This Month Revenue",
                          value: dashboardProvider.isLoading
                              ? "..."
                              : "\$ ${dashboardProvider.dashboardData?.summary?.revenue?.toStringAsFixed(2) ?? '0.00'}",
                          color: const Color(0xffF89E6C),
                          icon: AppImages.revenue,
                          width: (width - 48) / 3,
                        ),
                        _buildSummaryBox(
                          title: "Canceled Orders",
                          value: dashboardProvider.isLoading
                              ? "..."
                              : "${dashboardProvider.dashboardData?.summary?.cancelledOrders ?? 0}",
                          color: const Color(0xffF1A297),
                          icon: AppImages.cancelledOrders,
                          width: (width - 48) / 3,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Container(
                    //   padding: const EdgeInsets.all(16),
                    //   decoration: BoxDecoration(
                    //     color: Colors.white,
                    //     borderRadius: BorderRadius.circular(12),
                    //   ),
                    //   child: Column(
                    //     children: [
                    //       Row(
                    //         children: [
                    //           Expanded(
                    //             child: GestureDetector(
                    //               onTap: () async {
                    //                 final picked = await showDatePicker(
                    //                   context: context,
                    //                   initialDate: DateTime.now(),
                    //                   firstDate: DateTime(2000),
                    //                   lastDate: DateTime(2100),
                    //                 );
                    //                 if (picked != null) {}
                    //               },
                    //               child: Container(
                    //                 height: 35,
                    //                 padding: const EdgeInsets.symmetric(
                    //                   horizontal: 12,
                    //                 ),
                    //                 alignment: Alignment.centerLeft,
                    //                 decoration: BoxDecoration(
                    //                   color: Colors.white,
                    //                   borderRadius: BorderRadius.circular(4),
                    //                   border: Border.all(
                    //                     color: const Color(0xffE0E0E0),
                    //                   ),
                    //                 ),
                    //                 child: Text(
                    //                   "Start Date",
                    //                   style: AppTextStyles.size12Medium.copyWith(
                    //                     color: const Color(0xff999999),
                    //                   ),
                    //                 ),
                    //               ),
                    //             ),
                    //           ),

                    //           const SizedBox(width: 8),

                    //           Expanded(
                    //             child: GestureDetector(
                    //               onTap: () async {
                    //                 final picked = await showDatePicker(
                    //                   context: context,
                    //                   initialDate: DateTime.now(),
                    //                   firstDate: DateTime(2000),
                    //                   lastDate: DateTime(2100),
                    //                 );
                    //                 if (picked != null) {}
                    //               },
                    //               child: Container(
                    //                 height: 35,
                    //                 padding: const EdgeInsets.symmetric(
                    //                   horizontal: 12,
                    //                 ),
                    //                 alignment: Alignment.centerLeft,
                    //                 decoration: BoxDecoration(
                    //                   color: Colors.white,
                    //                   borderRadius: BorderRadius.circular(4),
                    //                   border: Border.all(
                    //                     color: const Color(0xffE0E0E0),
                    //                   ),
                    //                 ),
                    //                 child: Text(
                    //                   "End Date",
                    //                   style: AppTextStyles.size12Medium.copyWith(
                    //                     color: const Color(0xff999999),
                    //                   ),
                    //                 ),
                    //               ),
                    //             ),
                    //           ),

                    //           const SizedBox(width: 8),

                    //           GestureDetector(
                    //             onTap: () async {
                    //               final picked = await showDatePicker(
                    //                 context: context,
                    //                 initialDate: DateTime.now(),
                    //                 firstDate: DateTime(2000),
                    //                 lastDate: DateTime(2100),
                    //                 initialDatePickerMode: DatePickerMode.year,
                    //               );
                    //               if (picked != null) {}
                    //             },
                    //             child: Container(
                    //               height: 35,
                    //               padding: const EdgeInsets.symmetric(
                    //                 horizontal: 12,
                    //               ),
                    //               decoration: BoxDecoration(
                    //                 color: Colors.white,
                    //                 borderRadius: BorderRadius.circular(4),
                    //                 border: Border.all(
                    //                   color: const Color(0xffE0E0E0),
                    //                 ),
                    //               ),
                    //               child: Row(
                    //                 mainAxisAlignment: MainAxisAlignment.center,
                    //                 children: [
                    //                   const Icon(
                    //                     Icons.calendar_month,
                    //                     color: Color(0xffF89E6C),
                    //                     size: 20,
                    //                   ),
                    //                   const SizedBox(width: 4),
                    //                   Text(
                    //                     "Month",
                    //                     style: AppTextStyles.size12Medium.copyWith(
                    //                       color: const Color(0xff131313),
                    //                     ),
                    //                   ),
                    //                 ],
                    //               ),
                    //             ),
                    //           ),
                    //         ],
                    //       ),
                    //       SizedBox(height: 12),
                    //       Container(
                    //         height: 1,
                    //         width: double.infinity,
                    //         color: Color(0xffDDDDDD),
                    //       ),
                    //       SizedBox(height: 12),

                    //       Row(
                    //         mainAxisAlignment: MainAxisAlignment.end,
                    //         crossAxisAlignment: CrossAxisAlignment.end,
                    //         children: [
                    //           _buildLegendItem(
                    //             "No.of Orders",
                    //             const Color(0xffF1F423),
                    //           ),
                    //           const SizedBox(width: 20),
                    //           _buildLegendItem("Revenue", const Color(0xff00D341)),
                    //         ],
                    //       ),
                    //       const SizedBox(height: 16),

                    //       SizedBox(
                    //         height: 250,
                    //         child: Row(
                    //           children: [
                    //             RotatedBox(
                    //               quarterTurns: 3,
                    //               child: Text(
                    //                 "Orders / Revenue",
                    //                 style: AppTextStyles.size12Medium.copyWith(
                    //                   color: const Color(0xff666666),
                    //                 ),
                    //               ),
                    //             ),
                    //             SfCartesianChart(
                    //               plotAreaBorderWidth: 0,
                    //               primaryXAxis: NumericAxis(
                    //                 minimum: 0,
                    //                 maximum: 8,
                    //                 interval: 1,
                    //                 majorGridLines: const MajorGridLines(width: 0),
                    //                 axisLine: const AxisLine(width: 0),
                    //                 axisLabelFormatter:
                    //                     (AxisLabelRenderDetails details) {
                    //                       int index = details.value.toInt() - 1;
                    //                       if (index >= 0 &&
                    //                           index < dayLabels.length) {
                    //                         return ChartAxisLabel(
                    //                           dayLabels[index],
                    //                           AppTextStyles.size10Medium.copyWith(
                    //                             color: const Color(0xff666666),
                    //                           ),
                    //                         );
                    //                       }
                    //                       return ChartAxisLabel(
                    //                         '',
                    //                         const TextStyle(),
                    //                       );
                    //                     },
                    //               ),
                    //               primaryYAxis: NumericAxis(
                    //                 minimum: 0,
                    //                 maximum: 350,
                    //                 interval: 80,
                    //                 axisLine: const AxisLine(width: 0),
                    //                 majorTickLines: const MajorTickLines(width: 0),
                    //                 majorGridLines: const MajorGridLines(
                    //                   width: 1,
                    //                   color: Color(0xffF0F0F0),
                    //                 ),
                    //                 labelStyle: AppTextStyles.size10Medium.copyWith(
                    //                   color: const Color(0xff4B4B4B),
                    //                 ),
                    //               ),
                    //               series: <CartesianSeries>[
                    //                 // Orders Column Series
                    //                 ColumnSeries<ChartData, num>(
                    //                   dataSource: orderData,
                    //                   xValueMapper: (ChartData data, _) => data.day,
                    //                   yValueMapper: (ChartData data, _) =>
                    //                       data.orders,
                    //                   color: const Color(0xffF1F423),
                    //                   width: 0.6,
                    //                   borderRadius: const BorderRadius.only(
                    //                     topLeft: Radius.circular(4),
                    //                     topRight: Radius.circular(4),
                    //                   ),
                    //                 ),

                    //                 // Revenue Column Series
                    //                 ColumnSeries<ChartData, num>(
                    //                   dataSource: orderData,
                    //                   xValueMapper: (ChartData data, _) => data.day,
                    //                   yValueMapper: (ChartData data, _) =>
                    //                       data.revenue,
                    //                   color: const Color(0xff00D341),
                    //                   width: 0.6,
                    //                   borderRadius: const BorderRadius.only(
                    //                     topLeft: Radius.circular(4),
                    //                     topRight: Radius.circular(4),
                    //                   ),
                    //                 ),
                    //               ],
                    //             ),
                    //           ],
                    //         ),
                    //       ),

                    //       // Days label
                    //       Text(
                    //         "Days",
                    //         style: AppTextStyles.size12Medium.copyWith(
                    //           color: const Color(0xff666666),
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),

                    // const SizedBox(height: 20),

                    // 📊 Transactions button
                    InkWell(
                      onTap: () {
                        NavigateTo().nextPage(child: const TransactionScreen());
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Image.asset(
                              AppImages.invoice,
                              height: 24,
                              width: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "View All Transactions",
                                style: AppTextStyles.size14Medium.copyWith(
                                  color: const Color(0xff131313),
                                ),
                              ),
                            ),
                            SvgPicture.asset(
                              AppImages.chveronIcon,
                              height: 30,
                              width: 30,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // � Filter button widget
  Widget _buildFilterButton(
    BuildContext context,
    String label,
    String filterType,
    DashboardProvider provider, {
    bool hasIcon = false,
  }) {
    final isSelected = provider.selectedFilter == filterType;

    return GestureDetector(
      onTap: () => provider.updateFilter(filterType),
      child: Container(
        height: 35,
        padding: EdgeInsets.symmetric(
          horizontal: hasIcon ? 12 : 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xff00D341) : Colors.white,
          border: isSelected ? null : Border.all(color: Color(0xffE3DCDC)),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Center(
          child: hasIcon
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_month,
                      color: isSelected ? Colors.white : Color(0xffF89E6C),
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      label,
                      style: AppTextStyles.size12Medium.copyWith(
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                )
              : Text(
                  label,
                  style: AppTextStyles.size12Medium.copyWith(
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
        ),
      ),
    );
  }

  // �📦 Reusable summary box widget
  Widget _buildSummaryBox({
    required String title,
    required String value,
    required Color color,
    required String icon,
    required double width,
  }) {
    return Container(
      height: 90,
      width: width,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.161),
            offset: const Offset(0, 3),
            blurRadius: 6,
            spreadRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            textAlign: TextAlign.start,
            style: AppTextStyles.size12Medium.copyWith(color: Colors.white),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.size16SemiBold.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
              Image.asset(icon, height: 26, width: 26),
            ],
          ),
        ],
      ),
    );
  }
}

// 📊 Chart Data Model
class ChartData {
  ChartData({required this.day, required this.orders, required this.revenue});

  final int day;
  final double orders;
  final double revenue;
}
