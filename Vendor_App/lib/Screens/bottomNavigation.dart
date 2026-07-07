import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:resqboxvendor/Controller/DashboardController.dart';
import 'package:resqboxvendor/Screens/Account/account_screen.dart';
import 'package:resqboxvendor/Screens/Dashboard/dashBoard.dart';
import 'package:resqboxvendor/Screens/Invoice/invoice.dart';
import 'package:resqboxvendor/Screens/Menu/menu.dart';
import 'package:resqboxvendor/Screens/Orders/orders_screen.dart';
import 'package:resqboxvendor/Services/global_socket_service.dart';
import 'package:resqboxvendor/Utils/images.dart';
import 'package:resqboxvendor/Utils/textstyles.dart';

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize global socket service when app starts
    // This ensures socket stays connected even in background
    WidgetsBinding.instance.addPostFrameCallback((_) {
      GlobalSocketService().initialize(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = const [
      OrdersScreen(),
      MenuScreen(),
      DashBoardScreen(),
      Invoices(),
      AccountScreen(),
    ];
    final navProvider = Provider.of<DashboardProvider>(context);

    return Scaffold(
      body: screens[navProvider.selectedIndex],
      bottomNavigationBar: SafeArea(child: const CustomBottomNavBar()),
    );
  }
}

class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(color: Colors.white),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            context,
            0,
            AppImages.ordersColor,
            AppImages.orders,
            'Orders',
          ),
          _buildNavItem(
            context,
            1,
            AppImages.menuColor,
            AppImages.menu,
            'Menu',
          ),
          _buildNavItem(
            context,
            2,
            AppImages.dashboardColor,
            AppImages.dashboard,
            'Dashboard',
          ),
          _buildNavItem(
            context,
            3,
            AppImages.invoiceActiveColor,
            AppImages.invoicenon,
            'Invoice',
          ),
          _buildNavItem(
            context,
            4,
            AppImages.accountColor,
            AppImages.account,
            'Account',
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    String activeIcon,
    String inactiveIcon,
    String label,
  ) {
    return Consumer<DashboardProvider>(
      builder: (context, nav, child) {
        final isSelected = nav.selectedIndex == index;
        return GestureDetector(
          onTap: () => nav.setIndex(index),
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  isSelected ? activeIcon : inactiveIcon,
                  width: 26,
                  height: 26,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.size12Regular.copyWith(
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                    color: isSelected ? Color(0xff171717) : Color(0xff7A7A7A),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
