import 'package:flutter/material.dart';
import 'package:resqboxvendor/Screens/Auth/login_screen.dart';
import 'package:resqboxvendor/Utils/colors.dart';
import 'package:resqboxvendor/Utils/custom_border_btn.dart';
import 'package:resqboxvendor/Utils/navigations.dart';
import 'package:resqboxvendor/Utils/textstyles.dart';
import 'package:resqboxvendor/Utils/images.dart';

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({super.key});

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  int _currentIndex = 0;

  final List<Map<String, String>> onboardingData = [
    {
      "image": AppImages.onboarding1,
      "title": "Turn Your Kitchen Into a Business",
      "description":
          "Join resqboxvendor and share your homemade recipes with local food lovers.",
    },
    {
      "image": AppImages.onboarding2,
      "title": "Register Your Kitchen",
      "description":
          "Add your kitchen details, cuisine type, and complete simple verification to get started",
    },
    {
      "image": AppImages.onboarding3,
      "title": "Create Your Daily Menu",
      "description":
          "List your dishes each day, set prices, and update availability in just a few taps",
    },
    {
      "image": AppImages.onboarding4,
      "title": "Accept & Track Orders",
      "description":
          "Get notified instantly, manage incoming orders, and update delivery status with ease",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 35),
            Center(
              child: Image.asset(
                "Assets/zoviyImage.png",
                height: 85,
                width: 200,
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              height: 320,
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  for (final entry
                      in onboardingData.asMap().entries.toList()..sort((a, b) {
                        if (a.key == _currentIndex) return 1;
                        if (b.key == _currentIndex) return -1;
                        return a.key.compareTo(b.key);
                      }))
                    Builder(
                      builder: (context) {
                        final int index = entry.key;
                        final Map<String, String> item = entry.value;

                        double dx = 0;
                        double scale = 1.0;
                        double opacity = 1.0;

                        if (index == _currentIndex) {
                          dx = 0;
                          scale = 1.0;
                          opacity = 1.0;
                        } else if (index ==
                            (_currentIndex - 1 + onboardingData.length) %
                                onboardingData.length) {
                          dx = -73;
                          scale = 0.85;
                          opacity = 0.7;
                        } else if (index ==
                            (_currentIndex + 1) % onboardingData.length) {
                          dx = 73;
                          scale = 0.85;
                          opacity = 0.7;
                        } else {
                          opacity = 0;
                        }

                        final double imageWidth =
                            MediaQuery.of(context).size.width * 0.65;

                        return AnimatedPositioned(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                          left:
                              MediaQuery.of(context).size.width / 2 -
                              imageWidth / 2 +
                              dx,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 400),
                            opacity: opacity,
                            child: AnimatedScale(
                              duration: const Duration(milliseconds: 400),
                              scale: scale,
                              child: Container(
                                width: imageWidth,
                                height: 320,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xffE0E0E0),
                                    width: 2,
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Image.asset(
                                  item["image"]!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Spacer(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  Text(
                    onboardingData[_currentIndex]["title"]!,
                    style: AppTextStyles.size20SemiBold.copyWith(
                      color: const Color(0xff212121),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    onboardingData[_currentIndex]["description"]!,
                    style: AppTextStyles.size14Medium.copyWith(
                      color: const Color(0xff777777),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Page Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                onboardingData.length,
                (index) => Container(
                  width: _currentIndex == index ? 25 : 5,
                  height: 5,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _currentIndex == index
                        ? AppColors.mainAppColr
                        : const Color(0xffD9D8DD),
                  ),
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomRectBtn(
                color: AppColors.mainAppColr,
                borderColor: AppColors.mainAppColr,
                height: 49,
                width: double.infinity,
                text: _currentIndex == onboardingData.length - 1
                    ? "Get Started"
                    : "Next",
                onTap: () {
                  if (_currentIndex < onboardingData.length - 1) {
                    setState(() => _currentIndex++);
                  } else {
                    NavigateTo().pushReplacement(child: const LoginScreen());
                  }
                },
                textColor: Colors.white,
              ),
              const SizedBox(height: 10),
              CustomRectBtn(
                color: Colors.white,
                borderColor: Colors.white,
                height: 49,
                width: double.infinity,
                text: "Skip",
                onTap: () {
                  NavigateTo().pushReplacement(child: const LoginScreen());
                },
                textColor: Colors.black,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
