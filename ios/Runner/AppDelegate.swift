import UIKit
import Flutter
import Firebase
import CoreLocation
import PushKit
import flutter_callkit_incoming

@main // استخدام @main الحديث بدلاً من @UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

    let locationManager = CLLocationManager()
    var voipRegistry: PKPushRegistry?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        // 1. تشغيل PushKit للـ VoIP (مكالمات فقط)
        self.voipRegistry = PKPushRegistry(queue: .main)
        self.voipRegistry?.delegate = self
        self.voipRegistry?.desiredPushTypes = [.voIP]

        FirebaseApp.configure()
        locationManager.requestWhenInUseAuthorization()
        GeneratedPluginRegistrant.register(with: self)

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    override func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        UserDefaults.standard.set(error.localizedDescription, forKey: "flutter.ios_native_error")
        super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
    }

    // 🔥 تم الإصلاح: تحديد النوع Foundation.Data صراحة لمنع تضارب الأسماء مع المكتبات
    override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Foundation.Data) {
        UserDefaults.standard.set("✅ تم التسجيل بنجاح", forKey: "flutter.ios_native_error")
        super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
}

extension AppDelegate: PKPushRegistryDelegate {

    // سحب توكن المكالمات (VoIP Token)
    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        let tokenHex = credentials.token.map { String(format: "%02.2hhx", $0) }.joined()
        UserDefaults.standard.set("SUCCESS_NATIVE:\n" + tokenHex, forKey: "flutter.ios_native_voip_token")
    }

    // 🔥 الحل العبقري للكراش: تمرير الإشعار للمكتبة كمفوض (Delegate) لتعالجه هي بطريقتها المعتمدة
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {

        // التحقق من وجود نسخة نشطة من المكتبة وتمرير الإشعار لها لترن الشاشة فوراً
        if let pluginDelegate = SwiftFlutterCallkitIncomingPlugin.sharedInstance as? PKPushRegistryDelegate {
            pluginDelegate.pushRegistry?(registry, didReceiveIncomingPushWith: payload, for: type, completion: completion)
        } else {
            // في حال عدم توفر المكتبة، يجب إنهاء العملية لإبلاغ النظام باستلام البيانات
            completion()
        }
    }

    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        UserDefaults.standard.set("ERROR_NATIVE: إبطال التوكن", forKey: "flutter.ios_native_voip_token")
    }
}