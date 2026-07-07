import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resqbox_user/Controllers/cart_controller.dart';
import 'package:resqbox_user/Screens/MainSection/Account/account.dart';
import 'package:resqbox_user/Screens/MainSection/Cart/cart.dart';
import 'package:resqbox_user/Screens/MainSection/Home/home.dart';
import 'package:resqbox_user/Screens/MainSection/Orders/orders.dart';
import 'package:resqbox_user/Utils/colors.dart';
import 'package:resqbox_user/Utils/customtext.dart';
import 'package:resqbox_user/Utils/images.dart';
import 'package:resqbox_user/Utils/mediaquery.dart';

class BottomNavigation extends StatefulWidget {
  final int initialIndex;
  const BottomNavigation({super.key, this.initialIndex = 0});

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  List<Widget> pages = [];
  int currentIndex = 0;
  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    pages = [const Home(), const Orders(), const Cart(), const Account()];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CartController>(context, listen: false).getCartApi();
    });
  }

  void onTapped(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: Sizes.height * 0.075,
          padding: EdgeInsets.only(
            right: Sizes.width * 0.03,
          ),
          decoration: BoxDecoration(
            color: AppColors.tWhiteColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 3,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Consumer<CartController>(
            builder: (context, cartController, child) {
              int getTotalCartCount() {
                final items = cartController.cartData?.cartItems ?? [];
                return items.fold<int>(
                  0,
                  (sum, item) => sum + (item.quantity ?? 0),
                );
              }

              return BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                backgroundColor: AppColors.tWhiteColor,
                elevation: 0,
                iconSize: Sizes.height * 0.024,
                selectedItemColor: AppColors.tPrimaryColor,
                unselectedItemColor: AppColors.hintTclr,
                currentIndex: currentIndex,
                selectedFontSize: 0,
                unselectedFontSize: 0,
                selectedLabelStyle: TextStyle(height: 0),
                unselectedLabelStyle: TextStyle(height: 0),
                onTap: onTapped,
                items: <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    backgroundColor: AppColors.tWhiteColor,
                    icon: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          AppImages.home,
                          height: Sizes.height * 0.028,
                          color: currentIndex == 0
                              ? AppColors.tPrimaryColor
                              : Color(0XFF4B5563),
                          fit: BoxFit.contain,
                        ),
                        SizedBox(height: Sizes.height * 0.004),
                        CustomText(
                          text: "Home",
                          fontSize: 0.015,
                          fontWeight: currentIndex == 0
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: currentIndex == 0
                              ? AppColors.tBlackColor
                              : Color(0XFF4B5563),
                        ),
                      ],
                    ),
                    label: "",
                  ),
                  BottomNavigationBarItem(
                    backgroundColor: AppColors.tWhiteColor,
                    icon: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          AppImages.orders,
                          height: Sizes.height * 0.028,
                          color: currentIndex == 1
                              ? AppColors.tPrimaryColor
                              : Color(0XFF4B5563),
                          fit: BoxFit.contain,
                        ),
                        SizedBox(height: Sizes.height * 0.004),
                        CustomText(
                          text: "Orders",
                          fontSize: 0.015,
                          fontWeight: currentIndex == 1
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: currentIndex == 1
                              ? AppColors.tBlackColor
                              : Color(0XFF4B5563),
                        ),
                      ],
                    ),
                    label: "",
                  ),
                  BottomNavigationBarItem(
                    backgroundColor: AppColors.tWhiteColor,
                    icon: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Image.asset(
                              AppImages.cart,
                              height: Sizes.height * 0.028,
                              color: currentIndex == 2
                                  ? AppColors.tPrimaryColor
                                  : Color(0XFF4B5563),
                              fit: BoxFit.contain,
                            ),
                            if (cartController
                                    .cartData?.cartItems?.isNotEmpty ==
                                true)
                              Positioned(
                                right: -4, // Adjust for positioning
                                top: -4, // Adjust for positioning
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Center(
                                    child: CustomText(
                                      text: '${getTotalCartCount()}',
                                      color: Colors.white,
                                      fontSize: 0.01,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: Sizes.height * 0.004),
                        CustomText(
                          text: "Cart",
                          fontSize: 0.015,
                          fontWeight: currentIndex == 2
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: currentIndex == 2
                              ? AppColors.tBlackColor
                              : Color(0XFF4B5563),
                        ),
                      ],
                    ),
                    label: "",
                  ),
                  BottomNavigationBarItem(
                    backgroundColor: AppColors.tWhiteColor,
                    icon: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          AppImages.account,
                          height: Sizes.height * 0.028,
                          color: currentIndex == 3
                              ? AppColors.tPrimaryColor
                              : Color(0XFF4B5563),
                          fit: BoxFit.contain,
                        ),
                        SizedBox(height: Sizes.height * 0.004),
                        CustomText(
                          text: "Account",
                          fontSize: 0.015,
                          fontWeight: currentIndex == 3
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: currentIndex == 3
                              ? AppColors.tBlackColor
                              : Color(0XFF4B5563),
                        ),
                      ],
                    ),
                    label: "",
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
