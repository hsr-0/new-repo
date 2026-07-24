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
        print(logMessage)
    }

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        FirebaseApp.configure()
        GeneratedPluginRegistrant.register(with: self)

        if let controller = window?.rootViewController as? FlutterViewController {
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
        }

        self.voipRegistry = PKPushRegistry(queue: .main)
        self.voipRegistry?.delegate = self
        self.voipRegistry?.desiredPushTypes = [.voIP]

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // السماح لإشعارات فايربيس العادية بالمرور
    override func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable : Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        completionHandler(.newData)
    }
}

// =======================================================================
// VoIP Push Registry Delegate
// =======================================================================
extension AppDelegate: PKPushRegistryDelegate {

    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        guard type == .voIP else { return }

        let tokenHex = credentials.token.map { String(format: "%02.2hhx", $0) }.joined()
        UserDefaults.standard.set(tokenHex, forKey: "flutter.voip_token")
        writeLog("✅ تم حفظ التوكن: \(tokenHex.prefix(15))...")
    }

    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, withCompletionHandler completion: @escaping () -> Void) {

        guard type == .voIP else {
            completion()
            return
        }

        writeLog("⚠️ تم استلام إشعار مكالمة (VoIP)!")

        guard let dict = payload.dictionaryPayload as? [String: Any] else {
            writeLog("❌ البيانات فارغة أو غير صالحة")
            completion()
            return
        }

        let callType = dict["type"] as? Int ?? 0

        if callType == 0 {
            writeLog("📞 جاري تجهيز شاشة الرنين...")

            let callerName = dict["name"] as? String ?? "الكابتن"

            // 🔥 الإصلاح الأول: توليد UUID حقيقي يرضي شروط آبل لمنع الرفض الصامت
            let validUUID = UUID().uuidString

            let handle = dict["handle"] as? String ?? ""
            let duration = dict["duration"] as? Int ?? 60000

            // بيانات السيرفر الحقيقية (بما فيها رقم الطلب) تمر عبر extra ليفهمها الفلاتر
            let extra = dict["extra"] as? [String: Any] ?? dict

            var avatar = dict["avatar"] as? String ?? ""
            if avatar.hasPrefix("http://") {
                avatar = avatar.replacingOccurrences(of: "http://", with: "https://")
            }

            let callkitData: [String: Any] = [
                "id": validUUID, // استخدمنا الـ UUID الحقيقي هنا
                "nameCaller": callerName,
                "appName": "منصة بيتي",
                "handle": handle,
                "avatar": avatar,
                "type": 0,
                "duration": duration,
                "extra": extra
            ]

            do {
                let data = try flutter_callkit_incoming.Data(args: callkitData)
                if let plugin = SwiftFlutterCallkitIncomingPlugin.sharedInstance {
                    plugin.showCallkitIncoming(data, fromPushKit: true)
                    writeLog("✅ الشاشة رنت بنجاح.")
                }
            } catch {
                writeLog("❌ خطأ فادح في البيانات: \(error.localizedDescription)")
            }
        }
        else {
            writeLog("🚫 أمر إنهاء المكالمة.")
            if let plugin = SwiftFlutterCallkitIncomingPlugin.sharedInstance {
                plugin.endAllCalls()
            }
        }

        // 🔥 الإصلاح الثاني: تأخير الرد لآبل قليلاً لإعطاء فرصة لشاشة الرنين بالظهور لمنع الـ Crash
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            completion()
        }
    }

    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        guard type == .voIP else { return }
        writeLog("❌ تم إبطال التوكن من قبل آبل")
        UserDefaults.standard.removeObject(forKey: "flutter.voip_token")
    }
}