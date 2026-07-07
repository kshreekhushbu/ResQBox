import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resqbox_user/Controllers/cart_controller.dart';
import 'package:resqbox_user/Controllers/home_controller.dart';
import 'package:resqbox_user/Controllers/menu_controller.dart';
import 'package:resqbox_user/Models/filter_type_model.dart';
import 'package:resqbox_user/Screens/MainSection/Home/Widgets/active_filter_chip.dart';
import 'package:resqbox_user/Screens/MainSection/Home/Widgets/filter_bottom_sheet.dart';
import 'package:resqbox_user/Screens/MainSection/Home/food_menu_card.dart';
import 'package:resqbox_user/Screens/MainSection/bottom_navigation.dart';
import 'package:resqbox_user/Utils/colors.dart';
import 'package:resqbox_user/Utils/custom_image_widget.dart';
import 'package:resqbox_user/Utils/custom_padding.dart';
import 'package:resqbox_user/Utils/custom_tap.dart';
import 'package:resqbox_user/Utils/customtext.dart';
import 'package:resqbox_user/Utils/images.dart';
import 'package:resqbox_user/Utils/mediaquery.dart';
import 'package:resqbox_user/Utils/navigations.dart';
import 'package:resqbox_user/Utils/textformfield.dart';

class Menu extends StatefulWidget {
  final int? categoryId;
  final String? categoryName;
  final String? from;
  const Menu({super.key, this.categoryId, this.categoryName, this.from});

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final homeController =
          Provider.of<HomeController>(context, listen: false);
      homeController.clearFilters();
      _fetchMenuData();
    });
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchMenuData();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchMenuData() async {
    final homeController = Provider.of<HomeController>(context, listen: false);
    final controller = Provider.of<FoodMenuController>(context, listen: false);
    final cartController = Provider.of<CartController>(context, listen: false);

    final kitchenTypeIds = homeController.selectedKitchenIds.isEmpty
        ? null
        : homeController.selectedKitchenIds.join(',');
    final foodTypeIds = homeController.selectedMenuFoodIds.isEmpty
        ? null
        : homeController.selectedMenuFoodIds.join(',');

    List<Future> futures = [cartController.getCartApi()];

    if (widget.categoryId != null) {
      futures.add(controller.getMenuByCategoryId(
        widget.categoryId,
        null,
        homeController.locLatitude,
        homeController.locLongitude,
        from: widget.from,
        kitchenTypeIds: kitchenTypeIds,
        foodTypeIds: foodTypeIds,
      ));
    }

    await Future.wait(futures);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeController>(builder: (context, homeController, child) {
      final areFiltersApplied = homeController.selectedKitchenIds.isNotEmpty ||
          homeController.selectedMenuFoodIds.isNotEmpty;

      return Scaffold(
        backgroundColor: AppColors.tWhiteColor,
        appBar: AppBar(
          backgroundColor: AppColors.tWhiteColor,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_ios,
              color: AppColors.tBlackColor,
            ),
          ),
          title: CustomText(
            text: widget.categoryName ?? '',
            fontSize: 0.022,
            fontWeight: FontWeight.w600,
          ),
          actions: [
            Consumer<CartController>(
              builder: (context, cart, child) {
                int getTotalCartCount() {
                  final items = cart.cartData?.cartItems ?? [];
                  return items.fold<int>(
                    0,
                    (sum, item) => sum + (item.quantity ?? 0),
                  );
                }

                return CustomPadding(
                  right: .04,
                  child: CustomTap(
                    onTap: () {
                      NavigateTo()
                          .nextPage(child: BottomNavigation(initialIndex: 2));
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CustomImage(
                          image: AppImages.cart,
                          height: .03,
                        ),
                        if (cart.cartData?.cartItems?.isNotEmpty == true)
                          Positioned(
                            right: 0,
                            top: -4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0XFFF14E47),
                                shape: BoxShape.circle,
                              ),
                              child: CustomText(
                                text: '${getTotalCartCount()}',
                                fontSize: 0.012,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        bottomNavigationBar: Consumer<CartController>(
          builder: (context, cart, child) {
            final cartItems = cart.cartData?.cartItems ?? [];
            final totalQuantity = cartItems.fold<int>(
              0,
              (sum, item) => sum + (item.quantity ?? 0),
            );

            if (totalQuantity == 0) return const SizedBox.shrink();

            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: Sizes.width * 0.04,
                vertical: Sizes.height * 0.025,
              ),
              decoration: BoxDecoration(
                color: AppColors.tWhiteColor,
                boxShadow: [
                  BoxShadow(
                    color: Color(0XFF000000).withOpacity(0.2),
                    blurRadius: 4,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                child: CustomTap(
                  onTap: () {
                    NavigateTo()
                        .nextPage(child: BottomNavigation(initialIndex: 2));
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: Sizes.height * 0.015,
                      horizontal: Sizes.width * 0.04,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_cart,
                              color: AppColors.tWhiteColor,
                              size: Sizes.height * 0.025,
                            ),
                            SizedBox(width: Sizes.width * 0.02),
                            CustomText(
                              text:
                                  '$totalQuantity ${totalQuantity == 1 ? 'Item' : 'Items'}',
                              fontSize: 0.018,
                              fontWeight: FontWeight.w600,
                              color: AppColors.tWhiteColor,
                            ),
                          ],
                        ),
                        const CustomText(
                          text: "View Cart",
                          fontSize: 0.018,
                          // decoration: TextDecoration.underline,
                          // decorationColor: AppColors.tWhiteColor,
                          fontWeight: FontWeight.w600,
                          color: AppColors.tWhiteColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section (Search & Filter)
            const Divider(color: Color(0XFFE9E9E9), height: 1, thickness: 1),
            CustomPadding(
              top: 0.01,
              left: 0.04,
              right: 0.04,
              bottom: 0.01,
              child: Row(
                children: [
                  Expanded(
                    child: CustomTextFormField(
                      controller: _searchController,
                      hintText: "Search...",
                      hintFontSize: 0.016,
                      fillColor: AppColors.tWhiteColor,
                      hintColor: AppColors.tBlackColor,
                      prefixIconHeight: 0.024,
                      prefixIcon: AppImages.search,
                      prefixIconColor: AppColors.hintTclr,
                      customBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide:
                            const BorderSide(color: AppColors.tPrimaryColor),
                      ),
                    ),
                  ),
                  SizedBox(width: Sizes.width * 0.02),
                  CustomTap(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) {
                          return FilterBottomSheet(
                            onApply: () {
                              _fetchMenuData();
                              Navigator.pop(context);
                            },
                          );
                        },
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.all(Sizes.height * 0.005),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0XFFD4D4D4)),
                        color: AppColors.tWhiteColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const CustomImage(
                        image: AppImages.filter,
                        height: 0.035,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (areFiltersApplied) _buildAppliedFilters(homeController),
            const Divider(color: Color(0XFFE9E9E9), height: 1, thickness: 1),

            // Content Section
            Expanded(
              child: Consumer<FoodMenuController>(
                builder: (context, controller, child) {
                  if (controller.isMenuLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final menuItems =
                      controller.menuByCategoryData?.menuItems ?? [];

                  if (menuItems.isEmpty) {
                    return const Center(
                      child: CustomText(
                        text: 'No menu items available',
                        fontSize: 0.018,
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 20),
                    itemCount: menuItems.length,
                    separatorBuilder: (_, __) => const Divider(
                      color: Color(0XFFD9D9D9),
                    ),
                    itemBuilder: (context, index) {
                      final menuItem = menuItems[index];
                      return FoodMenuCard(
                          item: menuItem,
                          from: "menu",
                          isFromKitchanView:
                              widget.from == "kitchen" ? "kitchenMenu" : null);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildAppliedFilters(HomeController homeController) {
    List<Widget> chips = [];

    // Filter by Kitchen
    for (final id in homeController.selectedKitchenIds) {
      final filter = homeController.filterTypeModelData?.kitchenFoodType
          ?.firstWhere((element) => element.id == id,
              orElse: () => FoodType(id: id, name: "Kitchen $id"));
      chips.add(ActiveFilterChip(
        name: filter?.name ?? "Kitchen",
        imageUrl: filter?.image,
        onRemove: () {
          homeController.toggleKitchenSelection(id);
          _fetchMenuData();
        },
      ));
    }

    // Filter by Items
    for (final id in homeController.selectedMenuFoodIds) {
      final filter = homeController.filterTypeModelData?.menuFoodType
          ?.firstWhere((element) => element.id == id,
              orElse: () => FoodType(id: id, name: "Food $id"));
      chips.add(ActiveFilterChip(
        name: filter?.name ?? "Food",
        imageUrl: filter?.image,
        onRemove: () {
          homeController.toggleMenuFoodSelection(id);
          _fetchMenuData();
        },
      ));
    }

    return CustomPadding(
      bottom: .01,
      child: SizedBox(
        height: Sizes.height * 0.05,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: Sizes.width * 0.04),
          child: Row(
            children: chips
                .map((chip) => Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: chip,
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}
