import UIKit
import Flutter
import Firebase
import CoreLocation
import PushKit
import flutter_callkit_incoming

@UIApplicationMain
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

    override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        UserDefaults.standard.set("✅ تم التسجيل بنجاح", forKey: "flutter.ios_native_error")
        super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
}

extension AppDelegate: PKPushRegistryDelegate {

    // سحب توكن المكالمات
    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        let tokenHex = credentials.token.map { String(format: "%02.2hhx", $0) }.joined()
        UserDefaults.standard.set("SUCCESS_NATIVE:\n" + tokenHex, forKey: "flutter.ios_native_voip_token")
    }

    // 🔥 الحل النهائي للكراش والرنين: استخدام showCallkitIncoming
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {

        // 1. استخراج البيانات القادمة من السيرفر (PHP)
        let dictionaryPayload = payload.dictionaryPayload

        // 2. تحويلها إلى صيغة تفهمها مكتبة flutter_callkit_incoming
        let callData = flutter_callkit_incoming.Data(args: dictionaryPayload)

        // 3. أمر المكتبة بعرض شاشة الرنين فوراً
        SwiftFlutterCallkitIncomingPlugin.sharedInstance?.showCallkitIncoming(with: callData)

        // 4. إخبار آبل أن الاستلام والتشغيل تم بنجاح (لمنع الكراش)
        completion()
    }

    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        UserDefaults.standard.set("ERROR_NATIVE: إبطال التوكن", forKey: "flutter.ios_native_voip_token")
    }
}