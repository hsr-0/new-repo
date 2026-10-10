import UIKit
import AVFoundation
import Flutter
import Firebase
import FirebaseMessaging
import PushKit
import CallKit
import flutter_callkit_incoming
import SystemConfiguration
import Network

@main
@objc class AppDelegate: FlutterAppDelegate {

    var voipRegistry: PKPushRegistry?

    private var pushKitReceivedCount = 0
    private var lastPushKitPayload: [String: Any]?
    private var callKitShownCount = 0
    private var lastError: String?
    private var activeCallMap: [UUID: [String: Any]] = [:]

    // =======================================================================
    // 📝 نظام التسجيل
    // =======================================================================
    func writeLog(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        let timeString = formatter.string(from: Date())
        let logMessage = "[\(timeString)] 🍏 \(message)"

        var logs = UserDefaults.standard.stringArray(forKey: "ios_debug_logs") ?? []
        logs.append(logMessage)
        if logs.count > 100 { logs.removeFirst() }
        UserDefaults.standard.set(logs, forKey: "ios_debug_logs")
        print(logMessage)
    }

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        FirebaseApp.configure()
        GeneratedPluginRegistrant.register(with: self)

        // ===================================================================
        // ⚠️⚠️⚠️ ملاحظة حاسمة: لا نُهيّئ CXProvider هنا أبداً
        // المكتبة flutter_callkit_incoming تُدير CXProvider بنفسها
        // إنشاء CXProvider إضافي = تعارض = iOS يتجاهلنا = Crash
        // ===================================================================

        // قناة التشخيص
        if let controller = window?.rootViewController as? FlutterViewController {
            let diagnosticChannel = FlutterMethodChannel(
                name: "beytei_deep_debugger",
                binaryMessenger: controller.binaryMessenger
            )

            diagnosticChannel.setMethodCallHandler({ [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
                guard let self = self else { return }

                switch call.method {
                case "getLogs":
                    let logs = UserDefaults.standard.stringArray(forKey: "ios_debug_logs") ?? []
                    let token = UserDefaults.standard.string(forKey: "flutter.voip_token") ?? "❌ لا يوجد"
                    result(["logs": logs.joined(separator: "\n\n"), "token": token])

                case "runFullDiagnostics":
                    let serverUrl = call.arguments as? String ?? ""
                    let report = self.collectFullDiagnosticReport()
                    self.sendDiagnosticToServer(report: report, serverUrl: serverUrl) { success, response in
                        result(["success": success, "report": report, "serverResponse": response ?? ""])
                    }

                case "testLocalCallKit":
                    self.testLocalCallKit(result: result)

                case "checkPermissions":
                    result(self.checkAllPermissions())

                case "getPushKitStatus":
                    let status: [String: Any] = [
                        "receivedCount": self.pushKitReceivedCount,
                        "callKitShownCount": self.callKitShownCount,
                        "lastPayload": self.lastPushKitPayload ?? [:],
                        "lastError": self.lastError ?? "لا يوجد خطأ",
                        "voipToken": UserDefaults.standard.string(forKey: "flutter.voip_token") ?? "❌ مفقود"
                    ]
                    result(status)

                case "endNativeCall":
                    // 🔥 إنهاء مكالمة عبر المكتبة (وليس CXProvider خاص بنا)
                    if let args = call.arguments as? [String: Any],
                       let callId = args["callId"] as? String {
                        let callData = flutter_callkit_incoming.Data(
                            id: callId,
                            nameCaller: "",
                            handle: "",
                            type: 0
                        )
                        SwiftFlutterCallkitIncomingPlugin.sharedInstance?.endCall(callData)
                        self.writeLog("📞 endCall via Library: \(callId)")
                    }
                    result(true)

                default:
                    result(FlutterMethodNotImplemented)
                }
            })
        }

        // تهيئة PushKit
        self.voipRegistry = PKPushRegistry(queue: .main)
        self.voipRegistry?.delegate = self
        self.voipRegistry?.desiredPushTypes = [.voIP]

        writeLog("🚀 التطبيق بدأ - باستخدام flutter_callkit_incoming فقط (بدون CXProvider مزدوج)")
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    override func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable : Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        Messaging.messaging().appDidReceiveMessage(userInfo)
        completionHandler(.newData)
    }

    // =======================================================================
    // 🔬 التقرير التشخيصي
    // =======================================================================
    func collectFullDiagnosticReport() -> [String: Any] {
        var report: [String: Any] = [:]

        #if targetEnvironment(simulator)
        let isPhysicalDeviceText = "لا (محاكي)"
        #else
        let isPhysicalDeviceText = "نعم (جهاز حقيقي)"
        #endif

        report["deviceInfo"] = [
            "model": UIDevice.current.model,
            "systemName": UIDevice.current.systemName,
            "systemVersion": UIDevice.current.systemVersion,
            "name": UIDevice.current.name,
            "identifierForVendor": UIDevice.current.identifierForVendor?.uuidString ?? "مفقود",
            "isPhysicalDevice": isPhysicalDeviceText
        ]

        let voipToken = UserDefaults.standard.string(forKey: "flutter.voip_token") ?? ""
        report["tokens"] = [
            "voipToken": voipToken,
            "voipTokenLength": voipToken.count,
            "voipTokenValid": voipToken.count == 64,
            "fcmToken": UserDefaults.standard.string(forKey: "flutter.fcm_token") ?? "❌ مفقود"
        ]

        report["pushKit"] = [
            "isRegistered": voipRegistry != nil,
            "receivedCount": pushKitReceivedCount,
            "callKitShownCount": callKitShownCount,
            "lastError": lastError ?? "لا يوجد"
        ]

        report["permissions"] = checkAllPermissions()
        report["network"] = checkNetworkStatus()

        let bgModes = Bundle.main.infoDictionary?["UIBackgroundModes"] as? [String] ?? []
        report["backgroundModes"] = [
            "configured": bgModes,
            "hasVoIP": bgModes.contains("voip"),
            "hasRemoteNotification": bgModes.contains("remote-notification"),
            "hasAudio": bgModes.contains("audio")
        ]

        report["recentLogs"] = UserDefaults.standard.stringArray(forKey: "ios_debug_logs") ?? []

        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] ?? "غير معروف"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] ?? "غير معروف"
        report["appInfo"] = [
            "version": appVersion,
            "build": buildNumber,
            "bundleId": Bundle.main.bundleIdentifier ?? "❌ مفقود"
        ]

        report["callKitPlugin"] = [
            "isAvailable": SwiftFlutterCallkitIncomingPlugin.sharedInstance != nil
        ]

        report["timestamp"] = ISO8601DateFormatter().string(from: Date())
        return report
    }

    func checkAllPermissions() -> [String: Any] {
        let center = UNUserNotificationCenter.current()
        var result: [String: Any] = [:]
        let semaphore = DispatchSemaphore(value: 0)

        center.getNotificationSettings { settings in
            result["notifications"] = [
                "authorizationStatus": settings.authorizationStatus.rawValue,
                "statusText": self.getNotificationStatusText(settings.authorizationStatus),
                "soundSetting": settings.soundSetting.rawValue,
                "badgeSetting": settings.badgeSetting.rawValue,
                "alertSetting": settings.alertSetting.rawValue
            ]
            semaphore.signal()
        }

        semaphore.wait()
        return result
    }

    func getNotificationStatusText(_ status: UNAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "لم تُحدد بعد"
        case .denied: return "مرفوضة"
        case .authorized: return "مسموحة ✅"
        case .provisional: return "مؤقتة"
        case .ephemeral: return "مؤقتة (App Clip)"
        @unknown default: return "غير معروف"
        }
    }

    func checkNetworkStatus() -> [String: Any] {
        var result: [String: Any] = [:]
        guard let url = URL(string: "https://api.push.apple.com") else {
            result["internet"] = "❌ URL غير صالح"
            return result
        }

        let semaphore = DispatchSemaphore(value: 0)
        let task = URLSession.shared.dataTask(with: url) { _, response, error in
            if let error = error {
                result["internet"] = "❌ فشل: \(error.localizedDescription)"
            } else if let httpResponse = response as? HTTPURLResponse {
                result["internet"] = "✅ متصل - Status: \(httpResponse.statusCode)"
            } else {
                result["internet"] = "⚠️ استجابة غير معروفة"
            }
            semaphore.signal()
        }
        task.resume()
        _ = semaphore.wait(timeout: .now() + 5.0)

        if result["internet"] == nil {
            result["internet"] = "⏱️ انتهت مهلة الاتصال"
        }
        result["applePushServer"] = "تم الفحص"
        return result
    }

    func sendDiagnosticToServer(report: [String: Any], serverUrl: String, completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: serverUrl) else {
            completion(false, "URL غير صالح")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: report, options: .prettyPrinted)
            request.httpBody = jsonData

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(false, error.localizedDescription)
                    return
                }
                if let httpResponse = response as? HTTPURLResponse {
                    let statusCode = httpResponse.statusCode
                    if let data = data, let responseBody = String(data: data, encoding: .utf8) {
                        completion(statusCode == 200, "HTTP \(statusCode): \(responseBody)")
                    } else {
                        completion(statusCode == 200, "HTTP \(statusCode)")
                    }
                } else {
                    completion(false, "لا استجابة من السيرفر")
                }
            }
            task.resume()
        } catch {
            completion(false, "فشل تحويل JSON: \(error.localizedDescription)")
        }
    }

    func testLocalCallKit(result: @escaping FlutterResult) {
        writeLog("🧪 اختبار CallKit محلياً...")
        let testUUID = UUID().uuidString
        let callData = flutter_callkit_incoming.Data(
            id: testUUID,
            nameCaller: "اختبار تشخيصي",
            handle: "07700000000",
            type: 0
        )
        callData.appName = "منصة بيتي - تشخيص"
        callData.duration = 30000
        callData.extra = [
            "test": true,
            "room_name": "test_diagnostic_\(Int(Date().timeIntervalSince1970))",
            "livekit_url": "wss://call.beytei.com",
            "token": "test_token_\(testUUID)"
        ] as NSDictionary

        SwiftFlutterCallkitIncomingPlugin.sharedInstance?.showCallkitIncoming(callData, fromPushKit: false)
        callKitShownCount += 1

        result(["success": true, "message": "تم إرسال أمر CallKit بنجاح.", "uuid": testUUID])
    }

    // =======================================================================
    // 📢 إعلام Flutter
    // =======================================================================
    func notifyFlutterIncomingCall(data: [String: Any]) {
        var flutterVC: FlutterViewController? = nil

        if let vc = window?.rootViewController as? FlutterViewController {
            flutterVC = vc
        } else if let nav = window?.rootViewController as? UINavigationController {
            flutterVC = nav.topViewController as? FlutterViewController
        } else if let tab = window?.rootViewController as? UITabBarController {
            flutterVC = tab.selectedViewController as? FlutterViewController
        } else if let presented = window?.rootViewController?.presentedViewController as? FlutterViewController {
            flutterVC = presented
        }

        guard let controller = flutterVC else {
            writeLog("⚠️ لا يمكن إعلام Flutter")
            return
        }

        let channel = FlutterMethodChannel(
            name: "beytei_native_call",
            binaryMessenger: controller.binaryMessenger
        )

        channel.invokeMethod("onCallEvent", arguments: [
            "event": "incoming",
            "payload": data
        ]) { _ in }

        writeLog("📢 تم إعلام Flutter")
    }

    func notifyFlutterCallAccepted(data: [String: Any]) {
        var flutterVC: FlutterViewController? = nil
        if let vc = window?.rootViewController as? FlutterViewController { flutterVC = vc }
        else if let nav = window?.rootViewController as? UINavigationController { flutterVC = nav.topViewController as? FlutterViewController }
        else if let tab = window?.rootViewController as? UITabBarController { flutterVC = tab.selectedViewController as? FlutterViewController }

        guard let controller = flutterVC else { return }

        let channel = FlutterMethodChannel(
            name: "beytei_native_call",
            binaryMessenger: controller.binaryMessenger
        )
        channel.invokeMethod("onCallEvent", arguments: ["event": "accept", "payload": data]) { _ in }
    }

    func notifyFlutterCallEnded(data: [String: Any]) {
        var flutterVC: FlutterViewController? = nil
        if let vc = window?.rootViewController as? FlutterViewController { flutterVC = vc }
        else if let nav = window?.rootViewController as? UINavigationController { flutterVC = nav.topViewController as? FlutterViewController }
        else if let tab = window?.rootViewController as? UITabBarController { flutterVC = tab.selectedViewController as? FlutterViewController }

        guard let controller = flutterVC else { return }

        let channel = FlutterMethodChannel(
            name: "beytei_native_call",
            binaryMessenger: controller.binaryMessenger
        )
        channel.invokeMethod("onCallEvent", arguments: ["event": "end", "payload": data]) { _ in }
    }
}

// ===========================================================================
// 📞 PushKit Delegate - النسخة النهائية المُصحّحة حسب توثيق المكتبة الرسمي
// ===========================================================================
extension AppDelegate: PKPushRegistryDelegate {

    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        guard type == .voIP else { return }

        let deviceToken = credentials.token.map { String(format: "%02.2hhx", $0) }.joined()
        UserDefaults.standard.set(deviceToken, forKey: "flutter.voip_token")
        SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP(deviceToken)
        writeLog("🔑 تم استلام توكن VoIP: \(deviceToken.prefix(15))... (الطول: \(deviceToken.count))")
    }

    // ===========================================================================
    // 🚀 دالة استقبال VoIP Push - النسخة المُصحّحة حسب توثيق المكتبة الرسمي
    // ⚠️ التوثيق الرسمي يقول: يجب تأخير completion() بـ 1.5 ثانية
    // ===========================================================================
    func pushRegistry(_ registry: PKPushRegistry,
                      didReceiveIncomingPushWith payload: PKPushPayload,
                      for type: PKPushType,
                      withCompletionHandler completion: @escaping () -> Void) {

        guard type == .voIP else {
            completion()
            return
        }

        // استخراج البيانات الأساسية فقط
        let dict = payload.dictionaryPayload as? [String: Any] ?? [:]
        let rawId = (dict["id"] as? String) ?? UUID().uuidString
        let callUUID = UUID(uuidString: rawId)?.uuidString ?? UUID().uuidString

        let callerName = (dict["nameCaller"] as? String)
                      ?? (dict["driver_name"] as? String)
                      ?? "مندوب بيتي"

        let handle = (dict["handle"] as? String)
                  ?? (dict["driver_phone"] as? String)
                  ?? "مكالمة واردة"

        var avatar = (dict["avatar"] as? String)
                  ?? (dict["driver_image"] as? String)
                  ?? ""

        if avatar.hasPrefix("http://") {
            avatar = avatar.replacingOccurrences(of: "http://", with: "https://")
        }

        // فحص الإلغاء
        let typeValue = dict["type"]
        let actionValue = dict["action"]
        let isCancel = (typeValue as? String == "cancel_call") ||
                       (actionValue as? String == "cancel_call") ||
                       (typeValue as? String == "cancel") ||
                       (actionValue as? String == "cancel")

        // ===================================================================
        // 🔥🔥🔥 حالة الإلغاء
        // ===================================================================
        if isCancel {
            let callData = flutter_callkit_incoming.Data(id: callUUID, nameCaller: "", handle: "", type: 0)
            SwiftFlutterCallkitIncomingPlugin.sharedInstance?.endCall(callData)
            completion()

            DispatchQueue.main.async {
                self.writeLog("🚫 إلغاء المكالمة (UUID: \(callUUID))")
            }
            return
        }

        // ===================================================================
        // 🔥🔥🔥 الحالة الطبيعية: بناء بيانات CallKit
        // ===================================================================
        let callData = flutter_callkit_incoming.Data(
            id: callUUID,
            nameCaller: callerName,
            handle: handle,
            type: 0
        )
        callData.appName = "منصة بيتي"
        callData.avatar = avatar
        callData.duration = 60000

        var extraDict: [String: Any] = (dict["extra"] as? [String: Any]) ?? dict
        extraDict["id"] = callUUID
        extraDict["nameCaller"] = callerName
        extraDict["handle"] = handle
        extraDict["avatar"] = avatar
        extraDict["room_name"] = (dict["room_name"] as? String) ?? ""
        extraDict["livekit_url"] = (dict["livekit_url"] as? String) ?? "wss://call.beytei.com"
        extraDict["token"] = (dict["token"] as? String) ?? ""
        extraDict["order_id"] = (dict["order_id"] as? String) ?? ""

        callData.extra = extraDict as NSDictionary

        // ===================================================================
        // ✅ الخطوة 1: الإبلاغ الفوري عبر المكتبة
        // ===================================================================
        SwiftFlutterCallkitIncomingPlugin.sharedInstance?.showCallkitIncoming(callData, fromPushKit: true)

        // ===================================================================
        // ✅✅✅ الخطوة 2: تأخير completion() بـ 1.5 ثانية (حسب التوثيق الرسمي)
        // ⚠️ المكتبة تُنفّذ showCallkitIncoming بشكل غير متزامن داخلياً
        // ⚠️ لذا يجب تأخير completion() حتى تكتمل عملية الإبلاغ
        // ⚠️ التوثيق يقول: "if you don't call completion() ... there may be app crash"
        // ===================================================================
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            completion()
        }

        // ===================================================================
        // ✅ الخطوة 3: العمليات البطيئة (بعد الإبلاغ)
        // ===================================================================
        DispatchQueue.main.async {
            self.pushKitReceivedCount += 1
            self.lastPushKitPayload = dict
            self.callKitShownCount += 1
            self.activeCallMap[UUID(uuidString: callUUID) ?? UUID()] = extraDict

            UserDefaults.standard.set(extraDict, forKey: "call_\(callUUID)")

            self.writeLog("🔥 استلام VoIP Push #\(self.pushKitReceivedCount) - تم عرض CallKit بنجاح (UUID: \(callUUID))")
            self.writeLog("✅ سيتم استدعاء completion() بعد 1.5 ثانية - iOS راضٍ")

            // إعلام Flutter
            self.notifyFlutterIncomingCall(data: extraDict)
        }
    }

    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        guard type == .voIP else { return }
        UserDefaults.standard.removeObject(forKey: "flutter.voip_token")
        SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP("")
        writeLog("⚠️ تم إبطال توكن VoIP")
    }
}