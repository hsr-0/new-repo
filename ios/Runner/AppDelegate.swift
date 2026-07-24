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

        // ✅ الإصلاح 1: استخدام as? بدلاً من as! لمنع الانهيار عند فتح التطبيق
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
        writeLog("✅ تم تحديث توكن VoIP: \(tokenHex.prefix(20))...")

        sendTokenToServer(tokenHex)
    }

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

        let messageType = dict["type"] as? String ?? "voip_call"

        if messageType == "cancel_call" {
            writeLog("🚫 تم استلام أمر إلغاء المكالمة")
            if let plugin = SwiftFlutterCallkitIncomingPlugin.sharedInstance {
                plugin.endAllCalls()
            }
            completion()
            return
        }

        if messageType == "voip_call" {
            writeLog("📞 مكالمة جديدة واردة!")

            // استخراج البيانات بأمان
            let callerName = dict["name"] as? String ?? (dict["driver_name"] as? String ?? "الكابتن")
            let callId = dict["id"] as? String ?? (dict["order_id"] as? String ?? UUID().uuidString)
            let handle = dict["handle"] as? String ?? (dict["driver_phone"] as? String ?? "")

            // ✅ الإصلاح 2: معالجة رابط الشعار وإجباره على HTTPS لمنع رفض آبل له
            var avatar = dict["avatar"] as? String ?? (dict["driver_image"] as? String ?? "")
            if avatar.hasPrefix("http://") {
                avatar = avatar.replacingOccurrences(of: "http://", with: "https://")
                writeLog("⚠️ تم تحويل رابط الشعار من HTTP إلى HTTPS")
            }

            let duration = dict["duration"] as? Int ?? 60000
            let extra = dict["extra"] as? [String: Any] ?? dict

            writeLog("📋 البيانات: name=\(callerName), id=\(callId), avatar=\(avatar)")

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

            // ✅ الإصلاح 3: استخدام do-catch لمنع التطبيق من الانهيار (Crash) إذا كانت البيانات غير متوافقة
            do {
                let data = try flutter_callkit_incoming.Data(args: callkitData)

                if let plugin = SwiftFlutterCallkitIncomingPlugin.sharedInstance {
                    plugin.showCallkitIncoming(data, fromPushKit: true)
                    writeLog("✅ تم عرض شاشة المكالمة بنجاح")
                } else {
                    writeLog("❌ مكتبة CallKit غير جاهزة (sharedInstance is nil)")
                }
            } catch {
                // هذا السطر هو الذي كان يمنعك من معرفة سبب التوقف سابقاً
                writeLog("❌ خطأ فادح في بناء بيانات CallKit (سبب توقف التطبيق): \(error.localizedDescription)")
                writeLog("البيانات التي تسببت في الخطأ: \(callkitData)")
            }
        }

        // ✅ الحل الجذري: استدعاء completion فوراً في جميع الحالات
        completion()
    }

    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        guard type == .voIP else { return }
        writeLog("❌ تم إبطال توكن VoIP")
        UserDefaults.standard.removeObject(forKey: "flutter.voip_token")
    }

    func sendTokenToServer(_ voipToken: String) {
        let url = URL(string: "https://re.beytei.com/wp-json/restaurant-app/v1/register-device")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

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