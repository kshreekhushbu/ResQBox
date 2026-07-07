import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resqbox_user/Controllers/home_controller.dart';
import 'package:resqbox_user/Utils/colors.dart';
import 'package:resqbox_user/Utils/custom_border_btn.dart';
import 'package:resqbox_user/Utils/active_btn.dart';
import 'package:resqbox_user/Utils/custom_padding.dart';
import 'package:resqbox_user/Utils/network_image.dart';
import 'package:resqbox_user/Utils/custom_sizedbox.dart';
import 'package:resqbox_user/Utils/custom_tap.dart';
import 'package:resqbox_user/Utils/customtext.dart';
import 'package:resqbox_user/Utils/mediaquery.dart';

class FilterBottomSheet extends StatelessWidget {
  final VoidCallback? onApply;
  final VoidCallback? onClearAll;

  const FilterBottomSheet({
    super.key,
    this.onApply,
    this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeController>(
      builder: (context, homeController, child) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.tWhiteColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: Sizes.width * 0.04),
            child: CustomPadding(
              bottom: .03,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CustomSizedBox(height: 0.015),
                  Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      height: 4.5,
                      width: Sizes.width * .3,
                      decoration: BoxDecoration(
                        color: const Color(0XFFC5C5C5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const CustomSizedBox(height: 0.02),
                  Align(
                    alignment: Alignment.topRight,
                    child: CustomTap(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.tBlackColor),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: AppColors.tBlackColor,
                        ),
                      ),
                    ),
                  ),
                  homeController.isLoadingFilterData
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(
                                color: AppColors.tPrimaryColor),
                          ),
                        )
                      : ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: Sizes.height * 0.6,
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (homeController.filterTypeModelData
                                        ?.kitchenFoodType?.isNotEmpty ??
                                    false) ...[
                                  const CustomText(
                                    text: "Filter By Kitchen",
                                    fontSize: .020,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  const CustomSizedBox(height: 0.015),
                                  Wrap(
                                    spacing: Sizes.width * 0.02,
                                    runSpacing: Sizes.height * 0.01,
                                    children: homeController
                                        .filterTypeModelData!.kitchenFoodType!
                                        .map(
                                      (cuisine) {
                                        final isSelected = homeController
                                            .selectedKitchenIds
                                            .contains(cuisine.id);
                                        return CustomTap(
                                          onTap: () {
                                            if (cuisine.id != null) {
                                              homeController
                                                  .toggleKitchenSelection(
                                                      cuisine.id!);
                                            }
                                          },
                                          child: Container(
                                            width: Sizes.width * 0.45,
                                            padding: EdgeInsets.symmetric(
                                                horizontal: Sizes.width * 0.04,
                                                vertical: Sizes.height * 0.01),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                  color: isSelected
                                                      ? AppColors.tPrimaryColor
                                                      : const Color(0XFF4B5563)
                                                          .withOpacity(.6)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                CustomNetworkImage(
                                                  url: cuisine.image ?? "",
                                                  height: .026,
                                                  width: .04,
                                                ),
                                                const CustomSizedBox(
                                                    width: 0.03),
                                                Expanded(
                                                  child: CustomText(
                                                    text: cuisine.name ?? "",
                                                    fontSize: .018,
                                                    fontWeight: FontWeight.w500,
                                                    color:
                                                        const Color(0XFF5B5C5D),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (isSelected)
                                                  const Icon(
                                                    Icons.close,
                                                    color:
                                                        AppColors.tBlackColor,
                                                    size: 16,
                                                  ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ).toList(),
                                  ),
                                  const CustomSizedBox(height: 0.02),
                                  const Divider(
                                    color: Color(0XFFD2D2D2),
                                  ),
                                  const CustomSizedBox(height: 0.01),
                                ],
                                if (homeController.filterTypeModelData
                                        ?.menuFoodType?.isNotEmpty ??
                                    false) ...[
                                  const CustomText(
                                    text: "Filter By Items",
                                    fontSize: .020,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  const CustomSizedBox(height: 0.015),
                                  Wrap(
                                    spacing: Sizes.width * 0.02,
                                    runSpacing: Sizes.height * 0.01,
                                    children: homeController
                                        .filterTypeModelData!.menuFoodType!
                                        .map(
                                      (item) {
                                        final isSelected = homeController
                                            .selectedMenuFoodIds
                                            .contains(item.id);
                                        return CustomTap(
                                          onTap: () {
                                            if (item.id != null) {
                                              homeController
                                                  .toggleMenuFoodSelection(
                                                      item.id!);
                                            }
                                          },
                                          child: Container(
                                            width: Sizes.width * 0.45,
                                            padding: EdgeInsets.symmetric(
                                                horizontal: Sizes.width * 0.04,
                                                vertical: Sizes.height * 0.01),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                  color: isSelected
                                                      ? AppColors.tPrimaryColor
                                                      : const Color(0XFF4B5563)
                                                          .withOpacity(.6)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                CustomNetworkImage(
                                                  url: item.image ?? "",
                                                  height: .026,
                                                  width: .04,
                                                ),
                                                const CustomSizedBox(
                                                    width: 0.03),
                                                Expanded(
                                                  child: CustomText(
                                                    text: item.name ?? "",
                                                    fontSize: .018,
                                                    fontWeight: FontWeight.w500,
                                                    color:
                                                        const Color(0XFF5B5C5D),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (isSelected)
                                                  const Icon(
                                                    Icons.close,
                                                    color:
                                                        AppColors.tBlackColor,
                                                    size: 16,
                                                  ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ).toList(),
                                  ),
                                ],
                                if ((homeController.filterTypeModelData
                                            ?.kitchenFoodType?.isEmpty ??
                                        true) &&
                                    (homeController.filterTypeModelData
                                            ?.menuFoodType?.isEmpty ??
                                        true))
                                  const Center(
                                    child: Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 20.0),
                                      child: CustomText(
                                        text: "No filter categories available",
                                        fontSize: .018,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                  const CustomSizedBox(height: 0.035),
                  homeController.isLoadingFilterData
                      ? const SizedBox()
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CustomBorderBtn(
                              height: Sizes.height * .05,
                              width: Sizes.width * .45,
                              text: "Clear all",
                              onTap: () {
                                homeController.clearFilters();
                                if (onClearAll != null) onClearAll!();
                              },
                              borderRadius: 25,
                              fontSize: .018,
                              borderColor: const Color(0XFF4B5563),
                              textColor: const Color(0XFF4B5563),
                            ),
                            ActiveButton(
                              height: Sizes.height * .05,
                              width: Sizes.width * .45,
                              text: "Apply",
                              fontSize: .019,
                              borderRadius: 25,
                              color: (homeController
                                          .selectedKitchenIds.isNotEmpty ||
                                      homeController
                                          .selectedMenuFoodIds.isNotEmpty)
                                  ? AppColors.tPrimaryColor
                                  : Colors.grey,
                              onPressed: onApply ??
                                  () {
                                    Navigator.pop(context);
                                  },
                            )
                          ],
                        )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
