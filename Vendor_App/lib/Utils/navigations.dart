import 'package:flutter/cupertino.dart';
import 'package:resqboxvendor/main.dart';

// final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NavigateTo {
  Future nextPage({required Widget child, RouteSettings? settings}) {
    return Navigator.push(
      navigatorKey.currentContext!,
      CupertinoPageRoute(builder: (_) => child, settings: settings),
    );
  }

  Future pushReplacement({required Widget child}) {
    return Navigator.pushReplacement(
      navigatorKey.currentContext!,
      CupertinoPageRoute(builder: (_) => child),
    );
  }

  Future pushRemove({required Widget child}) {
    return Navigator.pushAndRemoveUntil(
      navigatorKey.currentContext!,
      CupertinoPageRoute(builder: (_) => child),
      (route) => false,
    );
  }

  void backPage() {
    return Navigator.pop(navigatorKey.currentContext!);
  }
}
