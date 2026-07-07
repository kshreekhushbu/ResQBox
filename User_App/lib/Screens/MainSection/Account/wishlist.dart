import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resqbox_user/Controllers/account_controller.dart';
import 'package:resqbox_user/Screens/MainSection/Home/home.dart';
import 'package:resqbox_user/Screens/MainSection/Home/wishlist_card_screen.dart';
import 'package:resqbox_user/Utils/custom_appbar.dart';
import 'package:resqbox_user/Utils/customtext.dart';
import 'package:resqbox_user/Utils/mediaquery.dart';

import '../../../Utils/colors.dart';

class Wishlist extends StatefulWidget {
  const Wishlist({super.key});

  @override
  State<Wishlist> createState() => _WishlistState();
}

class _WishlistState extends State<Wishlist> {
  final List<WishListKitchen> _wishListItems = const [
    WishListKitchen(
      name: 'Chillis',
      cuisine: 'South Indian',
      heroImage:
          'https://cdn.pixabay.com/photo/2022/06/27/05/38/spices-7286740_640.jpg',
      avatarImage:
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSLfQN-rGhcenba6gG2gL2hautDZGzRO0Darg&s',
      rating: 4.5,
      distance: '1.2 km',
      address: '30 Queen St',
      discountLabel: '40% OFF',
    ),
    WishListKitchen(
      name: 'Budget Feast House',
      cuisine: 'Mixed Cuisine',
      heroImage:
          'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=900&q=60',
      avatarImage:
          'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?auto=format&fit=crop&w=400&q=60',
      rating: 4.2,
      distance: '3.4 km',
      address: '45 City SQ',
      discountLabel: '25% OFF',
    ),
    WishListKitchen(
      name: 'Homely Bowls',
      cuisine: 'Healthy Bowls',
      heroImage:
          'https://images.unsplash.com/photo-1473093226795-af9932fe5856?auto=format&fit=crop&w=900&q=60',
      avatarImage:
          'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=400&q=60',
      rating: 4.8,
      distance: '0.9 km',
      address: '22 Riverside',
      discountLabel: '20% OFF',
    ),
  ];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Provider.of<AccountController>(context, listen: false)
          .getWishlistApi();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountController>(
        builder: (context, accountController, child) {
      return Scaffold(
        backgroundColor: const Color(0XFFF6F6F6),
        appBar: CustomAppBar(
          title: "Wishlist",
          titleFontSize: 0.022,
          backgroundColor: AppColors.tWhiteColor,
          backTap: () => Navigator.of(context).pop(),
        ),
        body: accountController.isLoadingWishlist == true
            ? const Center(child: CircularProgressIndicator())
            : accountController.wishlistData?.kitchens?.isEmpty ?? true
                ? const Center(
                    child: CustomText(text: "No wishlist items found"))
                : SafeArea(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount:
                          accountController.wishlistData?.kitchens?.length ?? 0,
                      // padding: EdgeInsets.only(right: Sizes.width * 0.04),
                      itemBuilder: (context, index) => Padding(
                        padding: EdgeInsets.only(
                          left: Sizes.width * 0.04,
                          top: Sizes.height * 0.015,
                          right: Sizes.width * 0.04,
                        ),
                        child: WishListCard(
                            item: accountController
                                .wishlistData?.kitchens?[index],
                            from: "kitchens"),
                      ),
                    ),
                  ),
      );
    });
  }
}
