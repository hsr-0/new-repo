import UIKit
import Flutter
import Firebase // ⭐ تأكد من استيراد Firebase

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // ⭐ الخطوة 1: تهيئة Firebase (لقد أضفتها بشكل صحيح)
    FirebaseApp.configure()

    GeneratedPluginRegistrant.register(with: self)

    // ⭐ الخطوة 2: تسجيل التطبيق لاستقبال الإشعارات (الجزء المفقود)
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }

    application.registerForRemoteNotifications()
    // --- نهاية الجزء المفقود ---

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}