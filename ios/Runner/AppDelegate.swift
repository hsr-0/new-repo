import UIKit
import Flutter
import Firebase // ⭐ تأكد من استيراد Firebase

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // ⭐ الخطوة 1: تهيئة Firebase
    FirebaseApp.configure()

    GeneratedPluginRegistrant.register(with: self)

    // ⭐ الخطوة 2: تسجيل التطبيق لاستقبال الإشعارات ومعالجة الإشعارات في الواجهة
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }

    // [مهم] هذا السطر يسجل التطبيق لدى خدمة إشعارات Apple
    application.registerForRemoteNotifications()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
