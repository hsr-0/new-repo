import UIKit
import Flutter
import Firebase
import PushKit
import flutter_callkit_incoming

@main
@objc class AppDelegate: FlutterAppDelegate {

    var voipRegistry: PKPushRegistry?

    // =======================================================================
    // 🛠️ نظام التشخيص وتسجيل الأحداث (Logger)
    // =======================================================================
    func writeLog(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        let timeString = formatter.string(from: Date())
        let logMessage = "[\(timeString)] 🍏 \(message)"

        var logs = UserDefaults.standard.stringArray(forKey: "ios_debug_logs") ?? []
        logs.append(logMessage)
        // الاحتفاظ بآخر 50 حدث فقط
        if logs.count > 150 { logs.removeFirst() }
        UserDefaults.standard.set(logs, forKey: "ios_debug_logs")
        print(logMessage)
    }

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        FirebaseApp.configure()
        GeneratedPluginRegistrant.register(with: self)

        // =======================================================================
        // 📡 قناة فلاتر (MethodChannel) لإرسال التوكن والسجلات للتطبيق
        // =======================================================================
        if let controller = window?.rootViewController as? FlutterViewController {
            let debugChannel = FlutterMethodChannel(name: "beytei_deep_debugger", binaryMessenger: controller.binaryMessenger)
            debugChannel.setMethodCallHandler({ [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
                if call.method == "getLogs" {
                    let logs = UserDefaults.standard.stringArray(forKey: "ios_debug_logs") ?? []
                    let token = UserDefaults.standard.string(forKey: "flutter.voip_token") ?? "❌ لا يوجد توكن VoIP مسجل"
                    result(["logs": logs.joined(separator: "\n\n"), "token": token])
                    self?.writeLog("تم طلب السجلات من تطبيق فلاتر")
                } else {
                    result(FlutterMethodNotImplemented)
                }
            })
        }

        // تفعيل استقبال مكالمات الإنترنت (VoIP)
        self.voipRegistry = PKPushRegistry(queue: .main)
        self.voipRegistry?.delegate = self
        self.voipRegistry?.desiredPushTypes = [.voIP]

        writeLog("🚀 التطبيق بدأ العمل وتم تهيئة PushKit")

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // السماح لإشعارات Firebase العادية بالمرور
    override func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable : Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        completionHandler(.newData)
    }
}

// =======================================================================
// VoIP Push Registry Delegate - نظام الاتصال واستلام الإشعارات
// =======================================================================
extension AppDelegate: PKPushRegistryDelegate {

    // 1. تسجيل توكن الآيفون (VoIP Token)
    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        guard type == .voIP else { return }
        let tokenHex = credentials.token.map { String(format: "%02.2hhx", $0) }.joined()
        UserDefaults.standard.set(tokenHex, forKey: "flutter.voip_token")
        writeLog("🔑 تم استلام توكن آبل بنجاح: \(tokenHex.prefix(15))...")
    }

    // 2. استلام إشعار المكالمة في الخلفية أو التطبيق مغلق
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, withCompletionHandler completion: @escaping () -> Void) {

        guard type == .voIP else {
            completion()
            return
        }

        writeLog("⬇️ استلمت آيفون إشعار VoIP جديد من السيرفر")

        // 🔥 التعديل السحري: نستخدم النسخة الموجودة، وإذا كانت غير جاهزة ننشئ نسخة فورية لإنقاذ الموقف
        let callkitPlugin = SwiftFlutterCallkitIncomingPlugin.sharedInstance ?? SwiftFlutterCallkitIncomingPlugin()

        // 🔥 دالة الطوارئ المضمونة 100%: تمنع آبل من عمل (Crash) في حال كانت البيانات خاطئة
        func reportFakeCallToSatisfyApple(reason: String) {
            writeLog("⚠️ تفعيل خطة الطوارئ بسبب: \(reason)")
            let fakeUUID = UUID().uuidString
            let fakeData: [String: Any] = ["id": fakeUUID, "nameCaller": "مكالمة واردة", "appName": "منصة بيتي", "type": 0]

            if let data = try? flutter_callkit_incoming.Data(args: fakeData) {
                callkitPlugin.showCallkitIncoming(data, fromPushKit: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    callkitPlugin.endCall(data)
                }
            }
            completion()
        }

        guard let dict = payload.dictionaryPayload as? [String: Any] else {
            reportFakeCallToSatisfyApple(reason: "فشل في قراءة Payload من السيرفر")
            return
        }

        // هل هذا إشعار مكالمة جديدة أم إلغاء؟
        let isCancel = (dict["type"] as? String == "cancel_call") || (dict["type"] as? Int == 1)

        // معالجة الـ ID ليصبح UUID نظامي كما تطلب آبل
        let rawId = dict["id"] as? String ?? dict["order_id"] as? String ?? ""
        var validUUID = UUID().uuidString

        if let existingUUID = UUID(uuidString: rawId) {
            validUUID = existingUUID.uuidString
        } else if !rawId.isEmpty {
            let cleanString = String(rawId.prefix(12))
            let padded = String(repeating: "0", count: max(0, 12 - cleanString.count)) + cleanString
            validUUID = "00000000-0000-0000-0000-\(padded)"
        }

        let callerName = dict["name"] as? String ?? dict["driver_name"] as? String ?? "مندوب بيتي"
        let handle = dict["handle"] as? String ?? dict["driver_phone"] as? String ?? "مكالمة واردة"
        let duration = dict["duration"] as? Int ?? 60000
        let extra = dict["extra"] as? [String: Any] ?? dict

        var avatar = dict["avatar"] as? String ?? dict["driver_image"] as? String ?? ""
        if avatar.hasPrefix("http://") {
            avatar = avatar.replacingOccurrences(of: "http://", with: "https://")
            writeLog("تم تعديل رابط الصورة إلى HTTPS")
        }

        let callkitData: [String: Any] = [
            "id": validUUID,
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

            if isCancel {
                callkitPlugin.showCallkitIncoming(data, fromPushKit: true)
                callkitPlugin.endCall(data)
                writeLog("🚫 تم معالجة طلب إلغاء المكالمة بنجاح")
            } else {
                callkitPlugin.showCallkitIncoming(data, fromPushKit: true)
                writeLog("🔔 تم عرض شاشة الاتصال بنجاح! (UUID: \(validUUID))")
            }
            completion()

        } catch let error {
            reportFakeCallToSatisfyApple(reason: "فشل بناء بيانات CallKit: \(error.localizedDescription)")
        }
    }

    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        guard type == .voIP else { return }
        UserDefaults.standard.removeObject(forKey: "flutter.voip_token")
        writeLog("⚠️ تم إبطال التوكن من قبل نظام آبل")
    }
}