import UIKit
import Flutter
import Firebase
import CoreLocation
import PushKit

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

    let locationManager = CLLocationManager()

    // 🔥 التعديل الجذري: تعريف المتغير هنا لكي لا يمسحه النظام من الذاكرة
    var voipRegistry: PKPushRegistry?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        // ---------------------------------------------------------
        // 🔥 1. تشغيل خدمة مكالمات آبل (PushKit) أولاً وقبل كل شيء!
        // ---------------------------------------------------------
        self.voipRegistry = PKPushRegistry(queue: .main)
        self.voipRegistry?.delegate = self
        self.voipRegistry?.desiredPushTypes = [.voIP]

        // 2. تهيئة Firebase بعد PushKit لمنع التعارض
        FirebaseApp.configure()

        // 3. طلب إذن الموقع
        locationManager.requestWhenInUseAuthorization()

        // 4. تسجيل الإضافات
        GeneratedPluginRegistrant.register(with: self)

        // 5. إعدادات الإشعارات العادية
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
        }
        application.registerForRemoteNotifications()

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    override func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        UserDefaults.standard.set(error.localizedDescription, forKey: "flutter.ios_native_error")
        super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
    }

    override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        UserDefaults.standard.set("✅ تم التسجيل بنجاح، لا توجد أخطاء في الشهادة.", forKey: "flutter.ios_native_error")
        super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
}

// ---------------------------------------------------------
// 🔥 التقاط توكن المكالمات (VoIP)
// ---------------------------------------------------------
extension AppDelegate: PKPushRegistryDelegate {

    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        let tokenHex = credentials.token.map { String(format: "%02.2hhx", $0) }.joined()

        UserDefaults.standard.set("SUCCESS_NATIVE:\n" + tokenHex, forKey: "flutter.ios_native_voip_token")
        print("✅ VoIP Token Native: \(tokenHex)")
    }

    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        UserDefaults.standard.set("ERROR_NATIVE: تم إبطال التوكن من آبل", forKey: "flutter.ios_native_voip_token")
    }
}