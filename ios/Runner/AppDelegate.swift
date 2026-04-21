import UIKit
import Flutter
import Firebase
import CoreLocation
import PushKit

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

    let locationManager = CLLocationManager()

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        FirebaseApp.configure()
        locationManager.requestWhenInUseAuthorization()
        GeneratedPluginRegistrant.register(with: self)

        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
        }
        application.registerForRemoteNotifications()

        // ---------------------------------------------------------
        // 🕵️‍♂️ كود التجسس على ملف Info.plist المدمج
        // ---------------------------------------------------------
        if let bgModes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String] {
            let modesStr = bgModes.joined(separator: ", ")
            UserDefaults.standard.set(modesStr, forKey: "flutter.ios_bg_modes")
        } else {
            UserDefaults.standard.set("المصفوفة غير موجودة نهائياً ❌", forKey: "flutter.ios_bg_modes")
        }

        // ---------------------------------------------------------
        // 🔥 تشغيل خدمة مكالمات آبل (PushKit)
        // ---------------------------------------------------------
        let voipRegistry = PKPushRegistry(queue: .main)
        voipRegistry.delegate = self
        voipRegistry.desiredPushTypes = [.voIP]

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
// 🔥 التقاط توكن المكالمات (VoIP) من نظام آبل الأصلي
// ---------------------------------------------------------
extension AppDelegate: PKPushRegistryDelegate {

    // ✅ التعديل هنا: استخدام didUpdate بدلاً من didUpdatePushCredentials كما طلبت آبل
    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        let tokenHex = credentials.token.map { String(format: "%02.2hhx", $0) }.joined()

        UserDefaults.standard.set("SUCCESS_NATIVE:\n" + tokenHex, forKey: "flutter.ios_native_voip_token")
        print("✅ VoIP Token Native: \(tokenHex)")
    }

    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        UserDefaults.standard.set("ERROR_NATIVE: تم إبطال التوكن من آبل", forKey: "flutter.ios_native_voip_token")
    }
}