import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resqbox_user/Controllers/home_controller.dart';
import 'package:resqbox_user/Models/filter_type_model.dart';
import 'package:resqbox_user/Screens/MainSection/Home/Widgets/active_filter_chip.dart';
import 'package:resqbox_user/Screens/MainSection/Home/Widgets/filter_bottom_sheet.dart';
import 'package:resqbox_user/Screens/MainSection/Home/food_menu_card.dart';
import 'package:resqbox_user/Screens/MainSection/Home/wishlist_card_screen.dart';
import 'package:resqbox_user/Utils/colors.dart';
import 'package:resqbox_user/Utils/custom_image_widget.dart';
import 'package:resqbox_user/Utils/custom_sizedbox.dart';
import 'package:resqbox_user/Utils/custom_tap.dart';
import 'package:resqbox_user/Utils/customtext.dart';
import 'package:resqbox_user/Utils/images.dart';
import 'package:resqbox_user/Utils/mediaquery.dart';
import 'package:resqbox_user/Utils/navigations.dart';
import 'package:resqbox_user/Utils/textformfield.dart';

import '../../../Utils/custom_padding.dart';

class SearchScreen extends StatefulWidget {
  final String? kitchenTypeIds;
  final String? foodTypeIds;
  const SearchScreen({super.key, this.kitchenTypeIds, this.foodTypeIds});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  Timer? _debounce;
  TextEditingController searchController = TextEditingController();
  TabController? _tabController;
  String? _currentKitchenTypeIds;
  String? _currentFoodTypeIds;

  @override
  void initState() {
    super.initState();
    _currentKitchenTypeIds = widget.kitchenTypeIds;
    _currentFoodTypeIds = widget.foodTypeIds;
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _fetchSearchResults();
    });
    searchController.addListener(_onSearchChanged);
  }

  void _fetchSearchResults() {
    final homeProvider = Provider.of<HomeController>(context, listen: false);
    homeProvider.searchRestaurantsApi(
      searchController.text,
      kitchenTypeIds: _currentKitchenTypeIds,
      foodTypeIds: _currentFoodTypeIds,
    );
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    _debounce?.cancel();
    _tabController?.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchSearchResults();
    });
  }

  @override
  Widget build(BuildContext context) {
    bool areFiltersApplied =
        _currentKitchenTypeIds != null || _currentFoodTypeIds != null;

    return Consumer<HomeController>(builder: (context, homeController, child) {
      return Scaffold(
        backgroundColor: const Color(0XFFF6F6F6),
        appBar: AppBar(
          backgroundColor: AppColors.tWhiteColor,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
          leading: IconButton(
            onPressed: () {
              NavigateTo().backPage();
            },
            icon: const Icon(
              Icons.arrow_back_ios,
              color: AppColors.tBlackColor,
            ),
          ),
          title: CustomText(
            text: 'Search',
            fontSize: 0.022,
            fontWeight: FontWeight.w600,
          ),
          bottom: PreferredSize(
            preferredSize: areFiltersApplied
                ? Size.fromHeight(Sizes.height * .11)
                : Size.fromHeight(Sizes.height * .118),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(
                  color: Color(0XFFE9E9E9),
                  height: 1,
                  thickness: 1,
                ),
                CustomPadding(
                  top: .01,
                  left: .04,
                  right: .04,
                  bottom: .01,
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomTextFormField(
                          controller: searchController,
                          hintText: "Search...",
                          hintFontSize: .016,
                          fillColor: AppColors.tWhiteColor,
                          hintColor: const Color(0XFF727272),
                          prefixIconHeight: .024,
                          onChanged: (value) {
                            debugPrint("valueeee ${value}");
                            setState(() {
                              searchController;
                            });
                          },
                          prefixIcon: AppImages.locSearch,
                          customBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: const BorderSide(
                              color: AppColors.tPrimaryColor,
                            ),
                          ),
                        ),
                      ),
                      CustomSizedBox(
                        width: .02,
                      ),
                      CustomTap(
                        onTap: () {
                          final homeController = Provider.of<HomeController>(
                              context,
                              listen: false);

                          // Sync controller state with current applied filters
                          homeController.selectedKitchenIds.clear();
                          if (_currentKitchenTypeIds != null &&
                              _currentKitchenTypeIds!.isNotEmpty) {
                            homeController.selectedKitchenIds.addAll(
                                _currentKitchenTypeIds!
                                    .split(',')
                                    .map((e) => int.parse(e.trim())));
                          }

                          homeController.selectedMenuFoodIds.clear();
                          if (_currentFoodTypeIds != null &&
                              _currentFoodTypeIds!.isNotEmpty) {
                            homeController.selectedMenuFoodIds.addAll(
                                _currentFoodTypeIds!
                                    .split(',')
                                    .map((e) => int.parse(e.trim())));
                          }

                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) {
                              return FilterBottomSheet(
                                onApply: () {
                                  final controller =
                                      Provider.of<HomeController>(context,
                                          listen: false);
                                  String? kitchenTypeIds = controller
                                          .selectedKitchenIds.isEmpty
                                      ? null
                                      : controller.selectedKitchenIds.join(',');
                                  String? foodTypeIds =
                                      controller.selectedMenuFoodIds.isEmpty
                                          ? null
                                          : controller.selectedMenuFoodIds
                                              .join(',');

                                  setState(() {
                                    _currentKitchenTypeIds = kitchenTypeIds;
                                    _currentFoodTypeIds = foodTypeIds;
                                  });
                                  _fetchSearchResults();
                                  Navigator.pop(context);
                                },
                              );
                            },
                          );
                        },
                        child: Container(
                            padding: EdgeInsets.all(Sizes.height * 0.004),
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: const Color(0XFFD4D4D4)),
                              color: AppColors.tWhiteColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const CustomImage(
                              image: AppImages.filter,
                              height: .03,
                            )),
                      ),
                    ],
                  ),
                ),
                if (areFiltersApplied) _buildAppliedFilters(homeController),
                if (!areFiltersApplied && _tabController != null)
                  TabBar(
                    controller: _tabController,
                    labelColor: AppColors.tPrimaryColor,
                    unselectedLabelColor: AppColors.hintTclr,
                    indicatorColor: AppColors.tPrimaryColor,
                    tabs: const [
                      Tab(text: "Food"),
                      Tab(text: "Kitchens"),
                    ],
                  ),
              ],
            ),
          ),
        ),
        body: homeController.isLoadingSearch
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : areFiltersApplied
                ? _buildFoodList(homeController)
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildFoodList(homeController),
                      _buildKitchenList(homeController),
                    ],
                  ),
      );
    });
  }

  Widget _buildAppliedFilters(HomeController homeController) {
    List<Widget> chips = [];

    if (_currentKitchenTypeIds != null && _currentKitchenTypeIds!.isNotEmpty) {
      final ids = _currentKitchenTypeIds!.split(',').map((e) => int.parse(e));
      for (final id in ids) {
        final filter = homeController.filterTypeModelData?.kitchenFoodType
            ?.firstWhere((element) => element.id == id,
                orElse: () => FoodType(id: id, name: "Kitchen $id"));
        chips.add(ActiveFilterChip(
          name: filter?.name ?? "Kitchen",
          imageUrl: filter?.image,
          onRemove: () {
            final newIds = _currentKitchenTypeIds!
                .split(',')
                .where((e) => e != id.toString())
                .join(',');
            setState(() {
              _currentKitchenTypeIds = newIds.isEmpty ? null : newIds;
            });
            _fetchSearchResults();
          },
        ));
      }
    }

    if (_currentFoodTypeIds != null && _currentFoodTypeIds!.isNotEmpty) {
      final ids = _currentFoodTypeIds!.split(',').map((e) => int.parse(e));
      for (final id in ids) {
        final filter = homeController.filterTypeModelData?.menuFoodType
            ?.firstWhere((element) => element.id == id,
                orElse: () => FoodType(id: id, name: "Food $id"));
        chips.add(ActiveFilterChip(
          name: filter?.name ?? "Food",
          imageUrl: filter?.image,
          onRemove: () {
            final newIds = _currentFoodTypeIds!
                .split(',')
                .where((e) => e != id.toString())
                .join(',');
            setState(() {
              _currentFoodTypeIds = newIds.isEmpty ? null : newIds;
            });
            _fetchSearchResults();
          },
        ));
      }
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

  Widget _buildKitchenList(HomeController homeController) {
    if (homeController.searchData?.kitchens?.isEmpty ?? true) {
      return const Center(child: Text('No kitchens found'));
    }
    return ListView.builder(
      itemCount: homeController.searchData?.kitchens?.length ?? 0,
      itemBuilder: (context, index) => Padding(
        padding: EdgeInsets.only(
          left: Sizes.width * 0.04,
          top: Sizes.height * 0.015,
          right: Sizes.width * 0.04,
        ),
        child: WishListCard(
          item: homeController.searchData?.kitchens?[index],
          from: "kitchens",
        ),
      ),
    );
  }

  Widget _buildFoodList(HomeController homeController) {
    if (homeController.searchData?.menu?.isEmpty ?? true) {
      return const Center(child: Text('No food items found'));
    }
    return ListView.builder(
      itemCount: homeController.searchData?.menu?.length ?? 0,
      itemBuilder: (context, index) => Padding(
        padding: EdgeInsets.only(
          left: Sizes.width * 0.04,
          top: Sizes.height * 0.015,
          right: Sizes.width * 0.04,
        ),
        child: FoodMenuCard(
          item: homeController.searchData?.menu?[index],
          from: "search",
        ),
      ),
    );
  }
}
