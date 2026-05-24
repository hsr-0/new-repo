import UIKit
import Flutter
import Firebase
import PushKit
import flutter_callkit_incoming
import CoreLocation // لضمان تهيئة الموقع

@main
@objc class AppDelegate: FlutterAppDelegate {

    var voipRegistry: PKPushRegistry?
    let locationManager = CLLocationManager()

    func writeLog(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let timeString = formatter.string(from: Date())
        let logMessage = "[\(timeString)] 🍏 \(message)"
        var logs = UserDefaults.standard.stringArray(forKey: "ios_debug_logs") ?? []
        logs.append(logMessage)
        if logs.count > 30 { logs.removeFirst() }
        UserDefaults.standard.set(logs, forKey: "ios_debug_logs")
    }

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        // 1. تهيئة Firebase للإشعارات العادية
        FirebaseApp.configure()

        // 2. طلب الموقع لتجنب كراش الخرائط
        locationManager.requestWhenInUseAuthorization()

        GeneratedPluginRegistrant.register(with: self)

        // 3. إعداد قناة ديباج (اختياري)
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let debugChannel = FlutterMethodChannel(name: "beytei_deep_debugger", binaryMessenger: controller.binaryMessenger)
        debugChannel.setMethodCallHandler({ [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            if call.method == "getLogs" {
                let logs = UserDefaults.standard.stringArray(forKey: "ios_debug_logs") ?? []
                let token = UserDefaults.standard.string(forKey: "flutter.voip_token") ?? "لا يوجد توكن"
                result(["logs": logs.joined(separator: "\n\n"), "token": token])
            } else {
                result(FlutterMethodNotImplemented)
            }
        })

        // 4. تسجيل الإشعارات العادية (FCM)
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
        }
        application.registerForRemoteNotifications()

        // 5. تسجيل إشعارات المكالمات (PushKit / VoIP)
        self.voipRegistry = PKPushRegistry(queue: .main)
        self.voipRegistry?.delegate = self
        self.voipRegistry?.desiredPushTypes = [.voIP]

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}

// MARK: - VoIP PushKit Delegate (مخصص للمكالمات فقط)
extension AppDelegate: PKPushRegistryDelegate {

    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        let tokenHex = credentials.token.map { String(format: "%02.2hhx", $0) }.joined()
        UserDefaults.standard.set(tokenHex, forKey: "flutter.voip_token")
        writeLog("تم حفظ توكن المكالمات VoIP")
    }

    // استخدمنا withCompletionHandler الدقيقة التي يطلبها iOS
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, withCompletionHandler completion: @escaping () -> Void) {

        writeLog("⚠️ تم استلام مكالمة عبر VoIP")

        if let dict = payload.dictionaryPayload as? [String: Any] {
            let callerName = dict["driver_name"] as? String ?? "الكابتن"
            let orderId = dict["order_id"] as? String ?? ""
            let validCallKitId = UUID().uuidString

            let callkitData: [String: Any] = [
                "id": validCallKitId,
                "nameCaller": callerName,
                "appName": "مطاعم بيتي",
                "handle": "طلب رقم \(orderId)",
                "type": 0,
                "duration": 30000,
                "extra": dict
            ]

            let data = flutter_callkit_incoming.Data(args: callkitData)

            if let plugin = SwiftFlutterCallkitIncomingPlugin.sharedInstance {
                plugin.showCallkitIncoming(data, fromPushKit: true)
                writeLog("✅ شاشة الاتصال رنت بنجاح.")
            } else {
                writeLog("❌ مكتبة CallKit غير جاهزة.")
            }
        }

        completion()
    }

    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {}
}