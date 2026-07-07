import 'package:flutter/material.dart' hide MenuController;
import 'package:provider/provider.dart';
import 'package:resqboxvendor/Controller/AuthController.dart';
import 'package:resqboxvendor/Controller/DashboardController.dart';
import 'package:resqboxvendor/Controller/DocumentsController.dart';
import 'package:resqboxvendor/Controller/InvoicesController.dart';
import 'package:resqboxvendor/Controller/KitchenProfileController.dart';
import 'package:resqboxvendor/Controller/KitchenRegistrationController.dart';
import 'package:resqboxvendor/Controller/MenuController.dart';
import 'package:resqboxvendor/Controller/OrdersController.dart';
import 'package:resqboxvendor/Controller/SupportController.dart';
import 'package:resqboxvendor/Controller/TeamController.dart';
import 'package:resqboxvendor/Controller/TransactionsController.dart';
import 'package:resqboxvendor/Controller/NotificationController.dart';

class AppProviders {
  static Widget withProviders(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => KitchenRegistrationController()),
        ChangeNotifierProvider(create: (_) => MenuController()),
        ChangeNotifierProvider(create: (_) => KitchenProfileController()),
        ChangeNotifierProvider(create: (_) => OrdersController()),
        ChangeNotifierProvider(create: (_) => TeamController()),
        ChangeNotifierProvider(create: (_) => SupportController()),
        ChangeNotifierProvider(create: (_) => DocumentsController()),
        ChangeNotifierProvider(create: (_) => TransactionsController()),
        ChangeNotifierProvider(create: (_) => InvoicesController()),
        ChangeNotifierProvider(create: (_) => NotificationController()),
        // ChangeNotifierProvider(create: (_) => AccountController()),
        // ChangeNotifierProvider(create: (_) => CreateCouponController()),
        // ChangeNotifierProvider(create: (_) => DashoardController()),
        // ChangeNotifierProvider(create: (_) => CustomerController()),
        // ChangeNotifierProvider(create: (_) => AccountController()),
      ],
      child: child,
    );
  }
}
