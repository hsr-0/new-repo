import UIKit
import Flutter
import Firebase
import CoreLocation
import PushKit
import flutter_callkit_incoming // ✅ استيراد المكتبة ضروري هنا

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

    let locationManager = CLLocationManager()

    // تعريف سجل الـ VoIP لضمان بقائه في الذاكرة
    var voipRegistry: PKPushRegistry?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        // 1. تشغيل خدمة مكالمات آبل (PushKit) فوراً
        self.voipRegistry = PKPushRegistry(queue: .main)
        self.voipRegistry?.delegate = self
        self.voipRegistry?.desiredPushTypes = [.voIP]

        // 2. تهيئة Firebase
        FirebaseApp.configure()

        // 3. إذن الموقع (اختياري حسب حاجتك)
        locationManager.requestWhenInUseAuthorization()

        // 4. تسجيل إضافات فلاتر
        GeneratedPluginRegistrant.register(with: self)

        // 5. إعدادات الإشعارات العادية (الدردشة وغيرها)
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

    // ✅ تم تحديد Foundation.Data لحل مشكلة 'Ambiguous lookup'
    override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Foundation.Data) {
        UserDefaults.standard.set("✅ تم التسجيل بنجاح", forKey: "flutter.ios_native_error")
        super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
}

// MARK: - معالجة إشعارات VoIP
extension AppDelegate: PKPushRegistryDelegate {

    // التقاط توكن المكالمات وتخزينه لاستخدامه في السيرفر
    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        let tokenHex = credentials.token.map { String(format: "%02.2hhx", $0) }.joined()
        UserDefaults.standard.set("SUCCESS_NATIVE:\n" + tokenHex, forKey: "flutter.ios_native_voip_token")
        print("✅ VoIP Token: \(tokenHex)")
    }

    // 🔥 هذه الدالة هي المسؤولة عن جعل الهاتف "يرن" عند وصول إشعار VoIP
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {

        // تمرير البيانات لمكتبة flutter_callkit_incoming لإظهار الواجهة
        if let plugin = SwiftFlutterCallkitIncomingPlugin.sharedInstance {
            plugin.didReceiveIncomingPush(with: payload.dictionaryPayload, completion: completion)
        } else {
            // في حال لم يكن الـ Plugin جاهزاً، يجب إنهاء العملية لتجنب تعليق النظام
            completion()
        }
    }

    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        UserDefaults.standard.set("ERROR_NATIVE: تم إبطال التوكن", forKey: "flutter.ios_native_voip_token")
    }
}