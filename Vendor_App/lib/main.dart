import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import 'package:resqboxvendor/Screens/Splash/splash_screen.dart';
import 'package:resqboxvendor/Services/api.dart';
import 'package:resqboxvendor/Utils/colors.dart';
import 'package:resqboxvendor/Utils/dependency_injection.dart';
import 'package:resqboxvendor/Utils/mediaquery.dart';
import 'package:resqboxvendor/Utils/notification_service.dart';
import 'package:resqboxvendor/Utils/shared_preference_helper.dart';
import 'package:resqboxvendor/firebase_options.dart';
import 'package:resqboxvendor/Models/local_notifications_model.dart'; // Added

// ---------------------- Navigator Key ----------------------
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// ---------------------- Background Handler ----------------------
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage event) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  debugPrint("🌙 BACKGROUND NOTIFICATION RECEIVED");
  debugPrint("   Title: ${event.notification?.title}");
  debugPrint("   Body: ${event.notification?.body}");
  debugPrint("   Data: ${event.data}");

  if (event.data.isNotEmpty) {
    PushNotificationsModel pushNotificationsModel =
        PushNotificationsModel.fromJson(event.data);

    await NotificationApi.pushNotification(pushNotificationsModel);
  }
}

//create a method that handles notification
void notificationHandler() async {
  FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  await firebaseMessaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  FirebaseMessaging.onMessage.listen((RemoteMessage event) async {
    debugPrint("☀️ FOREGROUND NOTIFICATION RECEIVED");
    debugPrint("   Data: ${event.data}");

    if (event.notification != null) {
      debugPrint("   Title: ${event.notification!.title}");
      debugPrint("   Body: ${event.notification!.body}");

      // Also show local notification for standard notifications if needed
      // Or just let system handle it if app is in background.
      // But for foreground, we need to show it manually:
      PushNotificationsModel model = PushNotificationsModel(
        title: event.notification!.title,
        body: event.notification!.body,
      );
      await NotificationApi.pushNotification(model);
    }

    if (event.data.isNotEmpty) {
      PushNotificationsModel pushNotificationsModel =
          PushNotificationsModel.fromJson(event.data);
      await NotificationApi.pushNotification(pushNotificationsModel);
    }
  });
}

// ---------------------- Main ----------------------
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Handle Hybrid Composition for Maps
  // AndroidGoogleMapsFlutter.useAndroidViewSurface = true; // Preventing crash

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      debugPrint('⚠️ Firebase already initialized');
    } else {
      rethrow;
    }
  }

  // Initialize notification service
  await NotificationApi.init();

  // Setup FCM background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  notificationHandler();

  // Initialize app environment and dependencies
  setEnvironment(env: Environment.dev);
  await SharedPreferencesHelper.getInstance();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // EasyLoading setup
  EasyLoading.instance
    ..userInteractions = false
    ..maskType = EasyLoadingMaskType.black
    ..dismissOnTap = false;

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // Initialize Firebase Messaging
  // await _initFirebaseMessaging();

  runApp(AppProviders.withProviders(const MyApp()));
}

// ---------------------- MyApp ----------------------
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Sizes.init(context);
    return SafeArea(
      bottom: true,
      top: false,
      left: false,
      right: false,
      child: MaterialApp(
        title: 'ResQBox Food Kitchen',
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.tWhiteColor),
          useMaterial3: true,
        ),
        builder: EasyLoading.init(),
        home: const SplashScreen(),
      ),
    );
  }
}
