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
        writeLog("تم حفظ توكن المكالمات (VoIP)")
    }

    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {

        writeLog("⚠️ تم استلام إشعار عبر مسار (VoIP)!")

        if let dict = payload.dictionaryPayload as? [String: Any] {

            // 💡 نظام الفلترة: التحقق مما إذا كان الإشعار يحتوي على بيانات مكالمة حقيقية
            // يتم فحص وجود مفاتيح معينة لا يرسلها السيرفر إلا مع المكالمات (مثل channel_name أو توكن agora)
            let isCall = dict["is_call"] as? String ?? "false"
            let hasChannelName = dict["channel_name"] != nil

            // إذا كان الإشعار يحمل علامة المكالمة أو اسم قناة، قم بتشغيل شاشة الرنين
            if isCall == "true" || hasChannelName {
                writeLog("📞 هذا إشعار مكالمة حقيقي. جاري تشغيل شاشة الرنين...")

                let callerName = dict["driver_name"] as? String ?? "الكابتن"
                let orderId = dict["order_id"] as? String ?? ""

                // توليد UUID فريد لتجنب كراش CallKit
                let validCallKitId = UUID().uuidString

                let callkitData: [String: Any] = [
                    "id": validCallKitId,
                    "nameCaller": callerName,
                    "appName": "منصة بيتي",
                    "handle": "طلب رقم \(orderId)",
                    "type": 0,
                    "duration": 30000,
                    "extra": dict // تمرير كامل البيانات ليتعامل معها Flutter بعد الرد
                ]

                let data = flutter_callkit_incoming.Data(args: callkitData)

                if let plugin = SwiftFlutterCallkitIncomingPlugin.sharedInstance {
                    plugin.showCallkitIncoming(data, fromPushKit: true)
                    writeLog("✅ الشاشة رنت بنجاح.")
                } else {
                    writeLog("❌ المكتبة غير جاهزة.")
                }
            } else {
                // 🚫 الإشعار عادي (وليس مكالمة)، نتجاهل تشغيل CallKit لمنع الرنين الخاطئ
                writeLog("🚫 تم استلام إشعار عادي عبر مسار المكالمات. تم إيقاف شاشة الرنين لمنع الإزعاج.")
            }
        }

        completion()
    }

    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {}
}