import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resqbox_user/Controllers/cart_controller.dart';
import 'package:resqbox_user/Screens/MainSection/Account/help_and_support.dart';
import 'package:resqbox_user/Screens/MainSection/Orders/ongoing_orders.dart';
import 'package:resqbox_user/Screens/MainSection/Orders/past_orders.dart';
import 'package:resqbox_user/Screens/MainSection/bottom_navigation.dart';
import 'package:resqbox_user/Utils/colors.dart';
import 'package:resqbox_user/Utils/custom_padding.dart';
import 'package:resqbox_user/Utils/custom_sizedbox.dart';
import 'package:resqbox_user/Utils/customtext.dart';
import 'package:resqbox_user/Utils/images.dart';
import 'package:resqbox_user/Utils/mediaquery.dart';
import 'package:resqbox_user/Utils/navigations.dart';

class Orders extends StatefulWidget {
  const Orders({super.key});

  @override
  State<Orders> createState() => _OrdersState();
}

class _OrdersState extends State<Orders> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Provider.of<CartController>(context, listen: false).getCartApi();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? result) async {
          if (didPop) {
            return;
          }
          NavigateTo().nextPage(child: BottomNavigation(initialIndex: 0));
        },
        child: Scaffold(
          backgroundColor: const Color(0XFFF6F6F6),
          appBar: AppBar(
            backgroundColor: AppColors.tWhiteColor,
            elevation: 0,
            title: const CustomText(
              text: "My Orders",
              color: AppColors.tBlackColor,
              fontWeight: FontWeight.w600,
              fontSize: .022,
            ),
            actions: [
              InkWell(
                onTap: () {
                  NavigateTo().nextPage(child: HelpAndSupport());
                },
                child: CustomPadding(
                  right: 0.04,
                  child: Row(
                    children: [
                      const CustomText(
                        text: "HELP",
                        fontWeight: FontWeight.w600,
                        fontSize: 0.013,
                      ),
                      const CustomSizedBox(
                        width: 0.015,
                      ),
                      Image.asset(
                        AppImages.help,
                        color: AppColors.tBlackColor,
                        height: Sizes.height * 0.022,
                      ),
                    ],
                  ),
                ),
              )
            ],
            automaticallyImplyLeading: false,
            centerTitle: true,
            // leading: IconButton(
            //   icon: const Icon(Icons.arrow_back_ios),
            //   onPressed: () => Navigator.pop(context),
            // ),
            bottom: TabBar(
              indicatorPadding:
                  EdgeInsets.symmetric(horizontal: Sizes.width * .14),
              indicatorColor: AppColors.tPrimaryColor,
              indicatorWeight: 2.0,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                fontFamily: 'SFPro',
                color: AppColors.tBlackColor, // selected tab text color
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: AppColors.tTransparrent,
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                fontFamily: 'SFPro',
                color: AppColors.hintTclr, // selected tab text color
              ),
              tabs: const [
                Tab(text: "Ongoing"),
                Tab(text: "Past"),
              ],
            ),
          ),
          body: const TabBarView(
            children: [OngoingOrders(), PastOrders()],
          ),
        ),
      ),
    );
  }
}
