import UIKit
import Flutter
import Firebase
import PushKit
import flutter_callkit_incoming

@main
@objc class AppDelegate: FlutterAppDelegate {

    var voipRegistry: PKPushRegistry?

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

        FirebaseApp.configure()
        GeneratedPluginRegistrant.register(with: self)

        let controller = window?.rootViewController as! FlutterViewController
        let debugChannel = FlutterMethodChannel(name: "beytei_deep_debugger", binaryMessenger: controller.binaryMessenger)

        debugChannel.setMethodCallHandler({ [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            if call.method == "getLogs" {
                let logs = UserDefaults.standard.stringArray(forKey: "ios_debug_logs") ?? []
                let token = UserDefaults.standard.string(forKey: "flutter.voip_token") ?? "لا يوجد توكن"
                result(["logs": logs.joined(separator: "\n\n"), "token": token])
            } else {
                result(FlutterMethodNotImplemented)
            }
        })

        self.voipRegistry = PKPushRegistry(queue: .main)
        self.voipRegistry?.delegate = self
        self.voipRegistry?.desiredPushTypes = [.voIP]

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}

// MARK: - PushKit Delegate
extension AppDelegate: PKPushRegistryDelegate {

    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        let tokenHex = credentials.token.map { String(format: "%02.2hhx", $0) }.joined()
        UserDefaults.standard.set(tokenHex, forKey: "flutter.voip_token")
        writeLog("تم حفظ التوكن")
    }

    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {

        writeLog("⚠️ تم استلام إشعار عبر PushKit")

        guard let dict = payload.dictionaryPayload as? [String: Any],
              let notificationType = dict["type"] as? String,
              notificationType == "voip_call" else {
            writeLog("ℹ️ إشعار غير متعلق بالمكالمات. يتم تجاهله بأمان.")
            completion()
            return
        }

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
            "extra": [
                "channel_name": dict["channel_name"] as? String ?? "",
                "agora_app_id": dict["agora_app_id"] as? String ?? "",
                "order_id": orderId,
                "driver_phone": dict["driver_phone"] as? String ?? ""
            ]
        ]

        let data = flutter_callkit_incoming.Data(args: callkitData)

        if let plugin = SwiftFlutterCallkitIncomingPlugin.sharedInstance {
            plugin.showCallkitIncoming(data, fromPushKit: true)
            writeLog("✅ تم عرض شاشة المكالمة بنجاح.")
        } else {
            writeLog("❌ مكتبة CallKit غير جاهزة.")
        }

        completion()
    }

    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {}
}