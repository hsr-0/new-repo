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
        formatter.dateFormat = "HH:mm:ss.SSS"
        let timeString = formatter.string(from: Date())
        let logMessage = "[\(timeString)] 🍏 \(message)"
        var logs = UserDefaults.standard.stringArray(forKey: "ios_debug_logs") ?? []
        logs.append(logMessage)
        if logs.count > 50 { logs.removeFirst() }
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

    // 🔥 هذا الدرع الواقي يمنع محرك Flutter من الفحص الخاطئ عند وصول إشعار عادي
    override func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable : Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        completionHandler(.newData)
    }
}

extension AppDelegate: PKPushRegistryDelegate {

    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        let tokenHex = credentials.token.map { String(format: "%02.2hhx", $0) }.joined()
        UserDefaults.standard.set(tokenHex, forKey: "flutter.voip_token")
        writeLog("✅ تم حفظ التوكن: \(tokenHex.prefix(15))...")
    }

    // 🔥 هنا تم تصحيح اسم الدالة لتطابق iOS 11+ وتمنع تسريب الإشعار لـ Flutter
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, withCompletionHandler completion: @escaping () -> Void) {

        writeLog("⚠️ تم استلام إشعار مكالمة (VoIP)!")

        if let dict = payload.dictionaryPayload as? [String: Any] {

            // 🔥 التكيف مع هيكل السيرفر الجديد (CallKit Structure)
            // السيرفر الآن يرسل 'name' بدلاً من 'driver_name' في الجذر
            let callerName = dict["name"] as? String ?? (dict["driver_name"] as? String ?? "الكابتن")
            let callId = dict["id"] as? String ?? UUID().uuidString
            let handle = dict["handle"] as? String ?? ""
            let avatar = dict["avatar"] as? String ?? ""
            let duration = dict["duration"] as? Int ?? 60000

            // 🔥 استخراج الـ extra التي تحتوي على channel_name و agora_app_id
            // إذا لم تكن موجودة (في حال كان السيرفر قديماً)، نأخذ الـ dict كاملاً كاحتياط
            let extra = dict["extra"] as? [String: Any] ?? dict

            let callkitData: [String: Any] = [
                "id": callId,
                "nameCaller": callerName,
                "appName": "مطاعم بيتي",
                "handle": handle,
                "avatar": avatar,
                "type": 0,
                "duration": duration,
                "extra": extra // 👈 هنا يمرر الـ channel_name لتطبيق فلاتر بنجاح
            ]

            let data = flutter_callkit_incoming.Data(args: callkitData)

            if let plugin = SwiftFlutterCallkitIncomingPlugin.sharedInstance {
                plugin.showCallkitIncoming(data, fromPushKit: true)
                writeLog("✅ الشاشة رنت بنجاح. الـ Extra: \(extra.keys)")
            } else {
                writeLog("❌ المكتبة غير جاهزة.")
            }
        }

        // 🔥 تأخير الرد لآبل بجزء من الثانية لضمان تشغيل شاشة المكالمة بنجاح
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            completion()
        }
    }

    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        writeLog("❌ تم إبطال التوكن")
    }
}
