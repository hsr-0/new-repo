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
            debugChannel.setMethodCallHandler({ (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
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

    // ترك إشعارات Firebase (FCM) تمر بسلام
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

        // 🔥 دالة الطوارئ: تمنع آبل من إرسال (0xbaadca11 Crash) مهما حدث
        func reportFakeCallToSatisfyApple() {
            let fakeUUID = UUID().uuidString
            let fakeData: [String: Any] = ["id": fakeUUID, "nameCaller": "مكالمة واردة", "appName": "منصة بيتي", "type": 0]
            if let data = try? flutter_callkit_incoming.Data(args: fakeData) {
                SwiftFlutterCallkitIncomingPlugin.sharedInstance?.showCallkitIncoming(data, fromPushKit: true)
                // إنهاء المكالمة الوهمية فوراً
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.endCall(data)
                }
            }
            completion()
        }

        guard let dict = payload.dictionaryPayload as? [String: Any] else {
            writeLog("❌ البيانات غير صالحة. جاري تنفيذ خطة الطوارئ لمنع الانهيار.")
            reportFakeCallToSatisfyApple()
            return
        }

        // 1. استخراج نوع الإشعار (مكالمة جديدة أم إلغاء)
        let isCancel = (dict["type"] as? String == "cancel_call")

        // 2. معالجة الـ ID (السبب الجذري للانهيار 0xbaadca11)
        // يجب تحويل رقم الطلب (مثل 17511) إلى UUID مقبول لدى Apple
        let rawId = dict["id"] as? String ?? dict["order_id"] as? String ?? ""
        var validUUID = UUID().uuidString

        if let existingUUID = UUID(uuidString: rawId) {
            validUUID = existingUUID.uuidString
        } else if !rawId.isEmpty {
            // تغليف الرقم القصير ليصبح UUID نظامي: 00000000-0000-0000-0000-000000017511
            let cleanString = String(rawId.prefix(12))
            let padded = String(repeating: "0", count: max(0, 12 - cleanString.count)) + cleanString
            validUUID = "00000000-0000-0000-0000-\(padded)"
        }

        let callerName = dict["name"] as? String ?? dict["driver_name"] as? String ?? "الكابتن"
        let handle = dict["handle"] as? String ?? dict["driver_phone"] as? String ?? ""
        let duration = dict["duration"] as? Int ?? 60000
        let extra = dict["extra"] as? [String: Any] ?? dict

        var avatar = dict["avatar"] as? String ?? dict["driver_image"] as? String ?? ""
        if avatar.hasPrefix("http://") {
            avatar = avatar.replacingOccurrences(of: "http://", with: "https://")
        }

        let callkitData: [String: Any] = [
            "id": validUUID, // استخدمنا الـ UUID الذي صنعناه
            "nameCaller": callerName,
            "appName": "منصة بيتي",
            "handle": handle,
            "avatar": avatar,
            "type": 0,
            "duration": duration,
            "extra": extra
        ]

        let plugin = SwiftFlutterCallkitIncomingPlugin.sharedInstance ?? SwiftFlutterCallkitIncomingPlugin()
        if SwiftFlutterCallkitIncomingPlugin.sharedInstance == nil {
            SwiftFlutterCallkitIncomingPlugin.sharedInstance = plugin
        }

        do {
            let data = try flutter_callkit_incoming.Data(args: callkitData)

            if isCancel {
                // آبل تشترط الإبلاغ عن المكالمة حتى لو كانت رسالة إلغاء
                plugin.showCallkitIncoming(data, fromPushKit: true)
                plugin.endCall(data)
                writeLog("🚫 تم تنفيذ الإلغاء بنجاح.")
            } else {
                plugin.showCallkitIncoming(data, fromPushKit: true)
                writeLog("✅ الشاشة رنت بنجاح (UUID: \(validUUID)).")
            }
            completion() // يجب استدعاؤها فوراً بعد الإبلاغ

        } catch {
            writeLog("❌ فشل بناء البيانات. جاري تنفيذ خطة الطوارئ.")
            reportFakeCallToSatisfyApple()
        }
    }

    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        guard type == .voIP else { return }
        UserDefaults.standard.removeObject(forKey: "flutter.voip_token")
    }
}