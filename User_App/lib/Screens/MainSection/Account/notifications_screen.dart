import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resqbox_user/Controllers/home_controller.dart';
import 'package:resqbox_user/Models/get_notification_model.dart';
import 'package:resqbox_user/Screens/MainSection/Orders/order_details.dart';
import 'package:resqbox_user/Utils/colors.dart';
import 'package:resqbox_user/Utils/const_validations.dart';
import 'package:resqbox_user/Utils/custom_appbar.dart';
import 'package:resqbox_user/Utils/custom_tap.dart';
import 'package:resqbox_user/Utils/customtext.dart';
import 'package:resqbox_user/Utils/mediaquery.dart';
import 'package:resqbox_user/Utils/navigations.dart';

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  final List<NotificationModel> notificationsList = [
    NotificationModel(
      title: "🛒 Order Confirmed!",
      message:
          "Your order has been successfully placed! We’ll notify you when it’s out for delivery. 🚀",
    ),
    NotificationModel(
      title: "🚚 Out for Delivery!",
      message:
          "Your groceries are on the way! Get ready to receive fresh items at your doorstep. 📦",
    ),
    NotificationModel(
      title: "🔥 Exclusive Deal Alert!",
      message:
          "Limited-time offer! Get 20% off on fresh vegetables today. Shop now before it’s gone!🥦",
    ),
  ];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Provider.of<HomeController>(context, listen: false)
          .getNotificationsApi(readStatus: "1");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeController>(builder: (context, value, child) {
      return Scaffold(
        backgroundColor: Color(0XFFF6F6F6),
        appBar: CustomAppBar(
          title: "Notifications",
          backgroundColor: AppColors.tWhiteColor,
          // textColor: AppColors.tPrimaryColor,
          backTap: () {
            Navigator.pop(context);
          },
        ),
        body: value.isLoadingNotifications == true
            ? Center(
                child: CircularProgressIndicator(),
              )
            : value.getNotificationsModelData?.notifications?.isEmpty ?? true
                ? Center(
                    child: CustomText(text: "No Notifications"),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    shrinkWrap: true,
                    itemCount:
                        value.getNotificationsModelData?.notifications?.length,
                    itemBuilder: (context, index) {
                      final notification = value
                          .getNotificationsModelData?.notifications?[index];
                      return NotificationCard(notification: notification);
                    },
                  ),
      );
    });
  }
}

class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    this.notification,
  });

  final NotificationData? notification;

  @override
  Widget build(BuildContext context) {
    return CustomTap(
      onTap: () async {
        if (notification?.orderId == null) {
          return;
        } else {
          await Provider.of<HomeController>(context, listen: false)
              .getNotificationsApi();
          NavigateTo().nextPage(
              child: OrderDetails(
            orderId: notification?.orderId,
            from: "ongoing",
          ));
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: Sizes.height * .01),
        width: Sizes.width,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.tWhiteColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0XFFE5E5E5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              text: notification?.title ?? '',
              fontSize: .018,
              fontWeight: FontWeight.w600,
            ),
            SizedBox(height: Sizes.height * .01),
            CustomText(
                text: notification?.message ?? '',
                fontSize: .016,
                fontWeight: FontWeight.w400,
                color: AppColors.hintTclr),
            SizedBox(height: Sizes.height * .008),
            CustomText(
              text: formatNotificationDateTime(
                  notification?.createdAt.toString()),
              fontSize: .014,
              fontWeight: FontWeight.w400,
              color: AppColors.hintTclr,
            ),
          ],
        ),
      ),
    );
  }
}

// Notification Model
class NotificationModel {
  final String title;
  final String message;

  NotificationModel({
    required this.title,
    required this.message,
  });
}
