import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resqboxvendor/Controller/NotificationController.dart';
import 'package:resqboxvendor/Screens/Orders/new_order_detail_view.dart';
import 'package:resqboxvendor/Utils/colors.dart';
import 'package:resqboxvendor/Utils/custom_appbar.dart';
import 'package:resqboxvendor/Utils/images.dart';
import 'package:resqboxvendor/Utils/navigations.dart';
import 'package:resqboxvendor/Utils/no_data.dart';
import 'package:resqboxvendor/Utils/textstyles.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationController>(
        context,
        listen: false,
      ).getNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: "Notifications",
        isLeading: true,
        centerTitle: true,
        backTap: () => Navigator.pop(context),
      ),
      body: Consumer<NotificationController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.notifications.isEmpty) {
            return Center(
              child: NoDataFoundWidget(
                img: AppImages.notifications,
                title: "No Notifications",
                description: "You don't have any notifications yet.",
                imgHeight: 100,
                imgWidth: 100,
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => controller.getNotifications(),
            child: ListView.separated(
              itemCount: controller.notifications.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, color: AppColors.divClr),
              itemBuilder: (context, index) {
                final notification = controller.notifications[index];
                return Container(
                  color: notification.isRead == false
                      ? AppColors.lemonFAE8AE.withOpacity(0.3)
                      : Colors.white,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.mainAppColr.withOpacity(0.1),
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: AppColors.mainAppColr,
                      ),
                    ),
                    title: Text(
                      notification.title ?? "",
                      style: AppTextStyles.size16Medium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          notification.message ?? "",
                          style: AppTextStyles.size14Regular.copyWith(
                            color: AppColors.yash77,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatDate(notification.createdAt),
                          style: AppTextStyles.size12Regular.copyWith(
                            color: AppColors.yash77,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      // controller.getOrderDetailsById(order.orderId ?? 0);
                      if (notification.orderId != null) {
                        NavigateTo().nextPage(
                          child: NewOrderDetailView(
                            orderId: notification.orderId ?? 0,
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "";
    final localDate = date.toLocal();
    return "${localDate.day.toString().padLeft(2, '0')}/${localDate.month.toString().padLeft(2, '0')}/${localDate.year} ${localDate.hour.toString().padLeft(2, '0')}:${localDate.minute.toString().padLeft(2, '0')}";
  }
}
