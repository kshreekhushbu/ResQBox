import Flutter
import UIKit
import GoogleMaps
import Firebase
@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }
    GeneratedPluginRegistrant.register(with: self)
    GMSServices.provideAPIKey("AIzaSyBZpiSwjq1dm3Xn2-eHS13d_8qDS2ey9WU")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
