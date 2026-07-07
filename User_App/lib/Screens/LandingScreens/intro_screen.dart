import 'dart:async';
import 'package:flutter/material.dart';
import 'package:resqbox_user/Screens/Authentication/login_screen.dart';
import 'package:resqbox_user/Utils/colors.dart';
import 'package:resqbox_user/Utils/custom_image_widget.dart';
import 'package:resqbox_user/Utils/custom_padding.dart';
import 'package:resqbox_user/Utils/customtext.dart';
import 'package:resqbox_user/Utils/images.dart';
import 'package:resqbox_user/Utils/mediaquery.dart';
import 'package:resqbox_user/Utils/navigations.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  final List<String> _introTexts = [
    'Find and order fresh, home-\nstyle meals from nearby \nkitchens.',
    'Order ahead and collect \nyour food from \ntrusted local chefs no \ndelivery delays.',
    'Support local kitchens \nand enjoy freshly \nprepared meals every \nday.',
  ];

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.tWhiteColor,
      body: SafeArea(
        child: CustomPadding(
          top: .075,
          bottom: .05,
          child: Stack(
            children: [
              _currentPage % _introTexts.length == 0
                  ? const Positioned(
                      child: CustomImage(
                      image: AppImages.rightbox,
                      height: .08,
                    ))
                  : const SizedBox.shrink(),
              _currentPage % _introTexts.length == 0
                  ? Positioned(
                      right: 0,
                      top: Sizes.height * .52,
                      child: const CustomImage(
                        image: AppImages.leftbox,
                        height: .08,
                      ))
                  : const SizedBox.shrink(),
              _currentPage % _introTexts.length == 1
                  ? Positioned(
                      right: 0,
                      top: Sizes.height * .11,
                      child: const CustomImage(
                        image: AppImages.halfbox,
                        height: .1,
                      ))
                  : const SizedBox.shrink(),
              _currentPage % _introTexts.length == 2
                  ? Positioned(
                      right: 0,
                      top: Sizes.height * .4,
                      child: const CustomImage(
                        image: AppImages.lext,
                        height: .07,
                      ))
                  : const SizedBox.shrink(),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const CustomPadding(
                    top: .02,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: CustomImage(
                        image: AppImages.logo,
                        height: .065,
                      ),
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      // itemCount: _introTexts.length, // Removed for infinite scroll
                      itemBuilder: (context, index) {
                        final realIndex = index % _introTexts.length;
                        return CustomPadding(
                          top: .07,
                          bottom: .07,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Align(
                                alignment: Alignment.center,
                                child: CustomImage(
                                  image: AppImages.landing,
                                  height: .36,
                                ),
                              ),
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: Center(
                                  child: CustomText(
                                    text: _introTexts[realIndex],
                                    textAlign: TextAlign.center,
                                    fontSize: .02,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  CustomPadding(
                    top: .03,
                    bottom: .02,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _introTexts.length,
                        (index) => _buildIndicator(index),
                      ),
                    ),
                  ),
                  SizedBox(height: Sizes.height * .05),
                  // ActiveButton(
                  //     height: Sizes.height * .06,
                  //     width: Sizes.width * .9,
                  //     text: "Sign in",
                  //     fontSize: .02,
                  //     borderRadius: 25,
                  //     onPressed: () {
                  //       NavigateTo().nextPage(child: const LoginScreen());
                  //     }),
                  // SizedBox(height: Sizes.height * .03),
                  // CustomBorderBtn(
                  //     height: Sizes.height * .06,
                  //     width: Sizes.width * .9,
                  //     text: "Create Account",
                  //     onTap: () {
                  //       NavigateTo().nextPage(child: const SignupScreen());
                  //     },
                  //     borderRadius: 25,
                  //     fontSize: .02,
                  //     borderColor: AppColors.tPrimaryColor,
                  //     textColor: AppColors.tBlackColor),
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: Sizes.width * 0.05),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            NavigateTo().nextPage(child: const LoginScreen());
                          },
                          child: const CustomText(
                            text: "Skip",
                            fontSize: .02,
                            fontWeight: FontWeight.w600,
                            color: AppColors.tBlackColor,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // If we are on the last logical item, navigate to login
                            // Otherwise, just go to next page
                            if (_currentPage % _introTexts.length <
                                _introTexts.length - 1) {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            } else {
                              NavigateTo().nextPage(child: const LoginScreen());
                            }
                          },
                          child: const CustomText(
                            text: "Next",
                            fontSize: .02,
                            fontWeight: FontWeight.w600,
                            color: AppColors.tPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIndicator(int index) {
    return Container(
      width: Sizes.width * 0.09,
      height: Sizes.width * 0.011,
      margin: EdgeInsets.symmetric(horizontal: Sizes.width * 0.01),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: (_currentPage % _introTexts.length) == index
            ? AppColors.tPrimaryColor
            : AppColors.lightYash,
      ),
    );
  }
}
