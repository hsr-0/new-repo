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
        formatter.dateFormat = "HH:mm:ss.SSS" // أضفنا أجزاء الثانية لدقة التتبع
        let timeString = formatter.string(from: Date())
        let logMessage = "[\(timeString)] 🍏 \(message)"
        var logs = UserDefaults.standard.stringArray(forKey: "ios_debug_logs") ?? []
        logs.append(logMessage)
        if logs.count > 50 { logs.removeFirst() } // رفعنا العدد لـ 50 سجل
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

        writeLog("تم تشغيل التطبيق وتهيئة PushKit")
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}

extension AppDelegate: PKPushRegistryDelegate {

    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        let tokenHex = credentials.token.map { String(format: "%02.2hhx", $0) }.joined()
        UserDefaults.standard.set(tokenHex, forKey: "flutter.voip_token")
        writeLog("تم حفظ توكن VoIP الجديد")
    }

    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {

        writeLog("⚠️ تم استلام إشعار VoIP!")

        // 1. استخراج البيانات بأمان (حتى لو فشل، نضع بيانات افتراضية لمنع الكراش)
        let dict = payload.dictionaryPayload as? [String: Any] ?? ["fallback": "true"]
        writeLog("📦 محتوى الإشعار: \(dict)")

        let callerName = dict["driver_name"] as? String ?? "تنبيه النظام"
        let orderId = dict["order_id"] as? String ?? "N/A"

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
            writeLog("✅ جاري عرض شاشة CallKit...")
            plugin.showCallkitIncoming(data, fromPushKit: true)
        } else {
            // إذا كانت المكتبة غير مهيأة، نسجل ذلك
            writeLog("❌ خطأ: SwiftFlutterCallkitIncomingPlugin.sharedInstance غير متاح!")
        }

        // 🔥 التعديل الأهم لمنع Crash نظام iOS:
        // آبل تتطلب إرجاع completion بعد أن يتم إخبار النظام بالمكالمة.
        // تأخيره قليلاً (ثانية واحدة) يضمن أن CallKit قد أخذ مجراه في النظام ولم يتم قتله.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            completion()
            self.writeLog("🏁 تم إنهاء الـ completion بسلام لمنع الكراش.")
        }
    }

    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        writeLog("⚠️ تم إبطال توكن VoIP من قبل آبل.")
    }
}