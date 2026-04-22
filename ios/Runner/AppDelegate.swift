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

        // ❌ أزلنا الأسطر التي كانت تخطف الإشعارات العادية من الفايربيس
        // الفايربيس الآن سيتولى إشعارات الدردشة تلقائياً وبشكل سليم!

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

    // تمرير المكالمة لترن الشاشة
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        if let plugin = SwiftFlutterCallkitIncomingPlugin.sharedInstance {
            plugin.pushRegistry(registry, didReceiveIncomingPushWith: payload, for: type, completion: completion)
        } else {
            completion()
        }
    }

    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        UserDefaults.standard.set("ERROR_NATIVE: إبطال التوكن", forKey: "flutter.ios_native_voip_token")
    }
}