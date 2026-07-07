import 'package:flutter/material.dart';
import 'package:resqbox_user/Screens/LandingScreens/intro_screen.dart';
import 'package:resqbox_user/Screens/MainSection/bottom_navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:resqbox_user/Controllers/account_controller.dart';
import 'package:resqbox_user/Controllers/socket_controller.dart';
import '../../Utils/images.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _animationController.forward();
    _checkTokenAndNavigate();
  }

  Future<void> _checkTokenAndNavigate() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('ApiToken');

    if (token != null && token.isNotEmpty) {
      // Token exists, fetch profile and initialize socket
      try {
        final accountController =
            Provider.of<AccountController>(context, listen: false);
        await accountController.getProfileApi();

        if (mounted) {
          final socketController =
              Provider.of<SocketController>(context, listen: false);
          socketController.initializeSocketConnection();

          // Navigate to home page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const BottomNavigation(initialIndex: 0),
            ),
          );
        }
      } catch (e) {
        debugPrint('❌ Error in splash screen: $e');
        // Fallback navigation if something fails
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const BottomNavigation(initialIndex: 0),
            ),
          );
        }
      }
    } else {
      // No token, navigate to intro screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const IntroScreen()),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Image.asset(
                  AppImages.logo,
                  fit: BoxFit.contain,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
