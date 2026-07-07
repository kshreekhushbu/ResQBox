import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resqboxvendor/Controller/DashboardController.dart';
import 'package:resqboxvendor/Screens/bottomNavigation.dart';
import 'package:resqboxvendor/Utils/custom_border_btn.dart';
import 'package:resqboxvendor/Utils/images.dart';
import 'package:resqboxvendor/Utils/navigations.dart';
import 'package:resqboxvendor/Utils/textstyles.dart';

class SuccessScreen extends StatefulWidget {
  const SuccessScreen({super.key});

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 45.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(AppImages.success, height: 250),
              Text(
                "Item has been added successfully!",
                style: AppTextStyles.size18SemiBold,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                "Your menu item has been successfully added and is now available for customers to order.",
                textAlign: TextAlign.center,
                style: AppTextStyles.size14Medium.copyWith(
                  color: Color(0xff777777),
                ),
              ),
              SizedBox(height: 25),
              CustomRectBtn(
                width: MediaQuery.of(context).size.width * 0.45,
                // onTap: () => {NavigateTo().nextPage(child: AddMenu())},
                onTap: () {
                  context.read<DashboardProvider>().setIndex(1);
                  NavigateTo().pushRemove(child: MainTabScreen());
                },
                height: 49,
                borderRadius: 8,
                leading: Center(
                  child: Text(
                    "View Menu",
                    style: AppTextStyles.size16SemiBold.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
                color: Color(0xffEB7712),
                borderColor: const Color(0xffEB7712),
                textColor: Colors.black,
              ),
              SizedBox(height: 20),
              CustomRectBtn(
                width: MediaQuery.of(context).size.width * 0.45,
                onTap: () {
                  context.read<DashboardProvider>().setIndex(0);
                  NavigateTo().pushRemove(child: MainTabScreen());
                },
                height: 49,
                borderRadius: 8,
                leading: Center(
                  child: Text(
                    "Go Home",
                    style: AppTextStyles.size16SemiBold.copyWith(
                      color: Colors.black,
                    ),
                  ),
                ),
                color: Colors.white,
                borderColor: const Color(0xffEB7712),
                textColor: Colors.black,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
