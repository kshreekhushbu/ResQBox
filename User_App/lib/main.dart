import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';
import 'package:resqbox_user/Controllers/account_controller.dart';
import 'package:resqbox_user/Controllers/authentication_controller.dart';
import 'package:resqbox_user/Controllers/cart_controller.dart';
import 'package:resqbox_user/Controllers/home_controller.dart';
import 'package:resqbox_user/Controllers/menu_controller.dart';
import 'package:resqbox_user/Controllers/orders_controller.dart';
import 'package:resqbox_user/Controllers/socket_controller.dart';
import 'package:resqbox_user/Models/local_notifications_model.dart';
import 'package:resqbox_user/Screens/LandingScreens/splash_screen.dart';
import 'package:resqbox_user/Screens/MainSection/Orders/order_details.dart';
import 'package:resqbox_user/Services/apis.dart';
import 'package:resqbox_user/Utils/colors.dart';
import 'package:resqbox_user/Utils/mediaquery.dart';
import 'package:resqbox_user/Utils/navigations.dart';
import 'package:resqbox_user/Utils/notifications.dart';
import 'package:resqbox_user/Utils/shared_preference_helper.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  // Add global error handling to prevent crashes
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint("❌ Flutter Error: ${details.exception}");
    debugPrint("❌ Stack trace: ${details.stack}");
  };

  // Handle platform errors
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint("❌ Platform Error: $error");
    debugPrint("❌ Stack trace: $stack");
    return true;
  };

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SharedPreferencesHelper.getInstance();
  isEnvironment(environment: Environment.prod);

  // Initialize Stripe
  // The publishable key is a PUBLIC key from Stripe - safe to use in client-side code
  // Get it from: https://dashboard.stripe.com/test/apikeys (for test) or /apikeys (for live)
  // It starts with "pk_test_" for test mode or "pk_live_" for production
  // Since this is Android-only, we don't need merchantIdentifier (that's for iOS Apple Pay)
  Stripe.publishableKey =
      "pk_test_51Sd6x1RmznpMJ3k9if9BJHeZnQeCxt131H5d1vRxCLI62FSbA8RQQBqDJAf0LOdg2WKDn5WrwiOrPfh8unppqV5300NvyO6dnq";
  // "pk_test_51Sd6vJDKI2oRvm5amvTQu6EB3LxtfKNo6iEad5Brv8Tgg6FKTrwSMYSRwTZp0fsXW1cajz01ZbH3RaEv09mWpXO400YrTzzmJx"; // TODO: Replace with your actual Stripe publishable key

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  NotificationApi.init();

  notificationHandler();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthenticationController()),
        ChangeNotifierProvider(create: (_) => HomeController()),
        ChangeNotifierProvider(create: (_) => AccountController()),
        ChangeNotifierProvider(create: (_) => OrdersController()),
        ChangeNotifierProvider(create: (_) => CartController()),
        ChangeNotifierProvider(create: (_) => FoodMenuController()),
        ChangeNotifierProvider(create: (_) => SocketController()),
      ],
      child: const MyApp(),
    ),
  );
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage event) async {
  await Firebase.initializeApp();
  NotificationApi.init();
  if (event.data.isNotEmpty) {
    PushNotificationsModel pushNotificationsModel =
        PushNotificationsModel.fromJson(event.data);

    int? orderId;
    if (event.data['orderId'] != null) {
      orderId = int.tryParse(event.data['orderId'].toString());
    }

    await NotificationApi.pushNotification(
      pushNotificationsModel,
      orderId: orderId,
    );
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

  // Handle background interactions
  setupInteractedMessage();

  FirebaseMessaging.onMessage.listen((RemoteMessage event) async {
    debugPrint('************');
    debugPrint('event.....****** ${event.data}');

    if (event.notification != null) {
      debugPrint("Notification Title: ${event.notification!.title}");
      debugPrint("Notification Body: ${event.notification!.body}");
    }

    if (event.data.isNotEmpty) {
      PushNotificationsModel pushNotificationsModel =
          PushNotificationsModel.fromJson(event.data);
      await NotificationApi.pushNotification(
        pushNotificationsModel,
        orderId: int.tryParse(event.data['orderId'].toString()),
      );

      // Call notifications API to update unread count
      if (navigatorKey.currentContext != null) {
        try {
          await Provider.of<HomeController>(
            navigatorKey.currentContext!,
            listen: false,
          ).getNotificationsApi();
        } catch (e) {
          debugPrint("Error calling notifications API: $e");
        }
      }
    }
  });
}

Future<void> setupInteractedMessage() async {
  // Get any messages which caused the application to open from a terminated state.
  RemoteMessage? initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();

  if (initialMessage != null) {
    _handleMessage(initialMessage);
  }

  // Also handle any interaction when the app is in the background via a
  // Stream listener
  FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
}

void _handleMessage(RemoteMessage message) {
  if (message.data['orderId'] != null) {
    int? orderId = int.tryParse(message.data['orderId'].toString());
    if (orderId != null && navigatorKey.currentContext != null) {
      NavigateTo().nextPage(
        child: OrderDetails(from: "push", orderId: orderId),
      );
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ResQBox Food',
      navigatorKey: navigatorKey,
      navigatorObservers: [routeObserver],
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Create a fixed text-scale MediaQuery
        final mq = MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(1.0));

        // Initialize Sizes AFTER media query is ready
        Sizes.init(context);

        return MediaQuery(data: mq, child: child!);
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.tPrimaryColor),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
