import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resqboxvendor/Controller/KitchenProfileController.dart';
import 'package:resqboxvendor/Utils/colors.dart';
import 'package:resqboxvendor/Utils/custom_appbar.dart';
import 'package:resqboxvendor/Utils/custom_border_btn.dart';
import 'package:resqboxvendor/Utils/navigations.dart';
import 'package:resqboxvendor/Utils/text_field.dart';
import 'package:resqboxvendor/Utils/textstyles.dart';

class BuzzSoundTimeSetting extends StatefulWidget {
  const BuzzSoundTimeSetting({super.key});

  @override
  State<BuzzSoundTimeSetting> createState() => _BuzzSoundTimeSettingState();
}

class _BuzzSoundTimeSettingState extends State<BuzzSoundTimeSetting> {
  final TextEditingController _secondsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load current notification time from kitchen details
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<KitchenProfileController>(
        context,
        listen: false,
      );
      final currentTime = controller.kitchenDetails?.notificationTime;
      if (currentTime != null) {
        _secondsController.text = currentTime.toString();
      }
    });
  }

  Future<void> _saveNotificationTime() async {
    final controller = Provider.of<KitchenProfileController>(
      context,
      listen: false,
    );

    final seconds = int.tryParse(_secondsController.text.trim());
    if (seconds == null || seconds <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter a valid number of seconds")),
      );
      return;
    }

    final success = await controller.updateNotificationTime(seconds);
    if (success && mounted) {
      NavigateTo().backPage();
    }
  }

  @override
  void dispose() {
    _secondsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: "Notification Settings",
        isLeading: true,
        backTap: () {
          NavigateTo().backPage();
        },
      ),
      body: Consumer<KitchenProfileController>(
        builder: (context, controller, child) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Buzz Sound Duration",
                    style: AppTextStyles.size18SemiBold,
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Set how long the notification sound should ring when you receive a new order.",
                    style: AppTextStyles.size14Medium.copyWith(
                      color: Color(0xff777777),
                    ),
                  ),
                  SizedBox(height: 30),
                  Text(
                    "Duration (in seconds)",
                    style: AppTextStyles.size14Medium,
                  ),
                  SizedBox(height: 10),
                  CustomTextFormField(
                    controller: _secondsController,
                    hintText: "Enter seconds (e.g., 10)",
                    isfilled: true,
                    isNumeric: true,
                    maxLength: 2,
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Current setting: ${controller.kitchenDetails?.notificationTime ?? 'Not set'} seconds",
                    style: AppTextStyles.size12Regular.copyWith(
                      color: AppColors.mainAppColr,
                    ),
                  ),
                  SizedBox(height: 40),
                  CustomRectBtn(
                    width: double.infinity,
                    onTap: controller.isLoadingStatus
                        ? () {}
                        : _saveNotificationTime,
                    height: 49,
                    borderRadius: 8,
                    leading: Center(
                      child: controller.isLoadingStatus
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              "Save Settings",
                              style: AppTextStyles.size16SemiBold.copyWith(
                                color: Colors.white,
                              ),
                            ),
                    ),
                    color: AppColors.mainAppColr,
                    borderColor: AppColors.mainAppColr,
                    textColor: Colors.white,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
