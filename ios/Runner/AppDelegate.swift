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
        print(logMessage)

        var logs = UserDefaults.standard.stringArray(forKey: "ios_debug_logs") ?? []
        logs.append(logMessage)
        if logs.count > 100 { logs.removeFirst() }
        UserDefaults.standard.set(logs, forKey: "ios_debug_logs")
    }

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        FirebaseApp.configure()
        GeneratedPluginRegistrant.register(with: self)

        // إعداد Flutter Method Channel للتشخيص
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

        // إعداد VoIP Registry
        self.voipRegistry = PKPushRegistry(queue: .main)
        self.voipRegistry?.delegate = self
        self.voipRegistry?.desiredPushTypes = [.voIP]

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // معالجة الإشعارات العادية (غير VoIP)
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

    // تحديث التوكن
    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        guard type == .voIP else { return }

        let tokenHex = credentials.token.map { String(format: "%02.2hhx", $0) }.joined()
        UserDefaults.standard.set(tokenHex, forKey: "flutter.voip_token")
        writeLog("✅ تم تحديث توكن VoIP: \(tokenHex.prefix(20))...")

        // ✅ إرسال التوكن للسيرفر
        sendTokenToServer(tokenHex)
    }

    // استقبال إشعار VoIP وارد
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, withCompletionHandler completion: @escaping () -> Void) {

        guard type == .voIP else {
            completion()
            return
        }

        writeLog("📞 تم استلام إشعار VoIP!")

        guard let dict = payload.dictionaryPayload as? [String: Any] else {
            writeLog("❌ البيانات فارغة أو غير صالحة")
            completion()
            return
        }

        // فحص نوع الإشعار
        let messageType = dict["type"] as? String ?? "voip_call"

        // ✅ معالجة إلغاء المكالمة
        if messageType == "cancel_call" {
            writeLog("🚫 تم استلام أمر إلغاء المكالمة")
            if let plugin = SwiftFlutterCallkitIncomingPlugin.sharedInstance {
                plugin.endAllCalls()
            }
            completion()
            return
        }

        // ✅ معالجة مكالمة جديدة
        if messageType == "voip_call" {
            writeLog("📞 مكالمة جديدة واردة!")

            // 🔥 استخراج البيانات بطريقة آمنة (تتعامل مع String و Int)
            let callerName = (dict["name"] as? String) ?? (dict["driver_name"] as? String) ?? "الكابتن"
            let callId = (dict["id"] as? String) ?? UUID().uuidString
            let handle = (dict["handle"] as? String) ?? (dict["driver_phone"] as? String) ?? ""
            let avatar = (dict["avatar"] as? String) ?? ""

            // معالجة آمنة للمدة (Duration) لمنع الكراش إذا أرسلها السيرفر كنص
            var duration = 60000
            if let durationInt = dict["duration"] as? Int {
                duration = durationInt
            } else if let durationString = dict["duration"] as? String, let parsedInt = Int(durationString) {
                duration = parsedInt
            }

            let extra = (dict["extra"] as? [String: Any]) ?? dict

            writeLog("📋 البيانات: name=\(callerName), id=\(callId), duration=\(duration)")

            // تجهيز بيانات CallKit
            let callkitData: [String: Any] = [
                "id": callId,
                "nameCaller": callerName,
                "appName": "منصة بيتي",
                "handle": handle,
                "avatar": avatar,
                "type": 0,
                "duration": duration,
                "extra": extra
            ]

            // 🔥 استخدام do-catch لمنع انهيار التطبيق في حال وجود خطأ في البيانات
            do {
                let data = try flutter_callkit_incoming.Data(args: callkitData)

                if let plugin = SwiftFlutterCallkitIncomingPlugin.sharedInstance {
                    plugin.showCallkitIncoming(data, fromPushKit: true)
                    writeLog("✅ تم عرض شاشة المكالمة بنجاح")
                } else {
                    writeLog("❌ مكتبة CallKit غير جاهزة (sharedInstance is nil)")
                }
            } catch {
                writeLog("❌ خطأ فادح في بناء بيانات CallKit: \(error.localizedDescription)")
            }
        }

        // ✅ الحل الجذري: استدعاء completion فوراً (إلزامي من Apple)
        completion()
    }

    // إبطال التوكن
    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        guard type == .voIP else { return }
        writeLog("❌ تم إبطال توكن VoIP")
        UserDefaults.standard.removeObject(forKey: "flutter.voip_token")
    }

    // ✅ دالة إرسال التوكن للسيرفر
    func sendTokenToServer(_ voipToken: String) {
        let url = URL(string: "https://re.beytei.com/wp-json/restaurant-app/v1/register-device")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // جلب توكن FCM العادي
        let fcmToken = UserDefaults.standard.string(forKey: "fcm_token") ?? ""

        let body: [String: Any] = [
            "token": fcmToken,
            "voip_token": voipToken,
            "platform": "ios"
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                self.writeLog("❌ فشل إرسال التوكن: \(error.localizedDescription)")
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                self.writeLog("✅ تم إرسال توكن VoIP للسيرفر بنجاح")
            } else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                self.writeLog("⚠️ استجابة غير متوقعة من السيرفر: Code \(statusCode)")
            }
        }.resume()
    }
}