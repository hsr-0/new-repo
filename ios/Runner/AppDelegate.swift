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

        self.voipRegistry = PKPushRegistry(queue: .main)
        self.voipRegistry?.delegate = self
        self.voipRegistry?.desiredPushTypes = [.voIP]

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}

extension AppDelegate: PKPushRegistryDelegate {

    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        let tokenHex = credentials.token.map { String(format: "%02.2hhx", $0) }.joined()
        UserDefaults.standard.set(tokenHex, forKey: "flutter.voip_token")
        writeLog("تم حفظ التوكن")
    }

    // 🔥 الحل النهائي والقاطع: إطلاق شاشة الرنين إجبارياً 🔥
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {

        writeLog("⚠️ تم استلام إشعار مكالمة (VoIP)!")

        if let dict = payload.dictionaryPayload as? [String: Any] {

            let callerName = dict["driver_name"] as? String ?? "الكابتن"
            let orderId = dict["order_id"] as? String ?? ""
            let channelName = dict["channel_name"] as? String ?? UUID().uuidString

            // تجهيز البيانات للصيغة التي تفهمها الشاشة مباشرة
            let callkitData: [String: Any] = [
                "id": channelName,
                "nameCaller": callerName,
                "appName": "مطاعم بيتي",
                "handle": "طلب رقم \(orderId)",
                "type": 0,
                "duration": 30000,
                "extra": dict
            ]

            let data = flutter_callkit_incoming.Data(args: callkitData)

            // ضرب الشاشة مباشرة لعرض الرنة
            if let plugin = SwiftFlutterCallkitIncomingPlugin.sharedInstance {
                plugin.showCallkitIncoming(data)
                writeLog("✅ الشاشة رنت (المكتبة كانت مستيقظة).")
            } else {
                let newPlugin = SwiftFlutterCallkitIncomingPlugin()
                SwiftFlutterCallkitIncomingPlugin.sharedInstance = newPlugin
                newPlugin.showCallkitIncoming(data)
                writeLog("✅ الشاشة رنت (تم إيقاظ المكتبة إجبارياً).")
            }
        }

        // الإبلاغ الفوري لآبل لتجنب الكراش
        completion()
    }

    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {}
}