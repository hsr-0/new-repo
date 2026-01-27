import UIKit
import Flutter
import Firebase
import CoreLocation // ✅ إضافة مكتبة الموقع لضمان الاستقرار

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

    // ✅ تعريف مدير الموقع لضمان تهيئة الخدمة قبل طلب الخريطة لها
    let locationManager = CLLocationManager()

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        // 1. تهيئة Firebase أولاً
        FirebaseApp.configure()

        // 2. طلب إذن الموقع بشكل مبدئي لتهيئة النظام وتجنب كراش Mapbox المفاجئ
        locationManager.requestWhenInUseAuthorization()

        // 3. تسجيل الإضافات (Plugins)
        GeneratedPluginRegistrant.register(with: self)

        // 4. إعدادات الإشعارات
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
        }
        application.registerForRemoteNotifications()

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}