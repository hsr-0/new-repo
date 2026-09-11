import UIKit
import Flutter
import Firebase
import FirebaseMessaging
import PushKit
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

    // =======================================================================
    // ️ نظام التشخيص وتسجيل الأحداث (Logger)
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

        //  قناة التشخيص الشاملة
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
                    self.writeLog("📋 تم طلب السجلات من Flutter")

                case "runFullDiagnostics":
                    // 🔬 تشغيل التشخيص الشامل وإرساله للسيرفر
                    let serverUrl = call.arguments as? String ?? ""
                    self.writeLog("🔬 بدء التشخيص الشامل...")
                    let report = self.collectFullDiagnosticReport()
                    self.sendDiagnosticToServer(report: report, serverUrl: serverUrl) { success, response in
                        if success {
                            self.writeLog("✅ تم إرسال التقرير للسيرفر بنجاح")
                        } else {
                            self.writeLog("❌ فشل إرسال التقرير: \(response ?? "unknown")")
                        }
                        result(["success": success, "report": report, "serverResponse": response ?? ""])
                    }

                case "testLocalCallKit":
                    // 🧪 اختبار محلي لـ CallKit بدون سيرفر
                    self.writeLog("🧪 بدء اختبار CallKit محلياً...")
                    self.testLocalCallKit(result: result)

                case "checkPermissions":
                    //  فحص الأذونات
                    let status = self.checkAllPermissions()
                    result(status)
                    self.writeLog("🔐 تم فحص الأذونات: \(status)")

                case "getPushKitStatus":
                    //  حالة PushKit
                    let status: [String: Any] = [
                        "receivedCount": self.pushKitReceivedCount,
                        "callKitShownCount": self.callKitShownCount,
                        "lastPayload": self.lastPushKitPayload ?? [:],
                        "lastError": self.lastError ?? "لا يوجد خطأ",
                        "voipToken": UserDefaults.standard.string(forKey: "flutter.voip_token") ?? "❌ مفقود"
                    ]
                    result(status)

                default:
                    result(FlutterMethodNotImplemented)
                }
            })
        }

        // تفعيل VoIP
        self.voipRegistry = PKPushRegistry(queue: .main)
        self.voipRegistry?.delegate = self
        self.voipRegistry?.desiredPushTypes = [.voIP]

        writeLog("🚀 التطبيق بدأ وتم تهيئة PushKit + نظام التشخيص")
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
    // 🔬 جمع التقرير التشخيصي الشامل
    // =======================================================================
    func collectFullDiagnosticReport() -> [String: Any] {
        var report: [String: Any] = [:]

        // 1. معلومات الجهاز
        report["deviceInfo"] = [
            "model": UIDevice.current.model,
            "systemName": UIDevice.current.systemName,
            "systemVersion": UIDevice.current.systemVersion,
            "name": UIDevice.current.name,
            "identifierForVendor": UIDevice.current.identifierForVendor?.uuidString ?? " مفقود",
            "isPhysicalDevice": TARGET_OS_SIMULATOR == 0 ? "نعم (جهاز حقيقي)" : "لا (محاكي)"
        ]

        // 2. حالة التوكنات
        let voipToken = UserDefaults.standard.string(forKey: "flutter.voip_token") ?? ""
        report["tokens"] = [
            "voipToken": voipToken,
            "voipTokenLength": voipToken.count,
            "voipTokenValid": voipToken.count == 64,
            "fcmToken": UserDefaults.standard.string(forKey: "flutter.fcm_token") ?? "❌ مفقود"
        ]

        // 3. حالة PushKit
        report["pushKit"] = [
            "isRegistered": voipRegistry != nil,
            "receivedCount": pushKitReceivedCount,
            "callKitShownCount": callKitShownCount,
            "lastError": lastError ?? "لا يوجد"
        ]

        // 4. الأذونات
        report["permissions"] = checkAllPermissions()

        // 5. حالة الشبكة
        report["network"] = checkNetworkStatus()

        // 6. إعدادات Background Modes
        let bgModes = Bundle.main.infoDictionary?["UIBackgroundModes"] as? [String] ?? []
        report["backgroundModes"] = [
            "configured": bgModes,
            "hasVoIP": bgModes.contains("voip"),
            "hasRemoteNotification": bgModes.contains("remote-notification"),
            "hasAudio": bgModes.contains("audio")
        ]

        // 7. السجلات الأخيرة
        report["recentLogs"] = UserDefaults.standard.stringArray(forKey: "ios_debug_logs") ?? []

        // 8. معلومات التطبيق
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] ?? "غير معروف"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] ?? "غير معروف"
        report["appInfo"] = [
            "version": appVersion,
            "build": buildNumber,
            "bundleId": Bundle.main.bundleIdentifier ?? "❌ مفقود"
        ]

        // 9. حالة CallKit Plugin
        report["callKitPlugin"] = [
            "isAvailable": SwiftFlutterCallkitIncomingPlugin.sharedInstance != nil
        ]

        // 10. الوقت
        report["timestamp"] = ISO8601DateFormatter().string(from: Date())

        return report
    }

    // =======================================================================
    // 🔐 فحص الأذونات
    // =======================================================================
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
        case .denied: return "مرفوضة "
        case .authorized: return "مسموحة ✅"
        case .provisional: return "مؤقتة"
        case .ephemeral: return "مؤقتة (App Clip)"
        @unknown default: return "غير معروف"
        }
    }

    // =======================================================================
    //  فحص الشبكة
    // =======================================================================
    func checkNetworkStatus() -> [String: Any] {
        var result: [String: Any] = [:]

        // فحص الاتصال بالإنترنت
        guard let url = URL(string: "https://api.push.apple.com") else {
            result["internet"] = "❌ URL غير صالح"
            return result
        }

        let task = URLSession.shared.dataTask(with: url) { _, response, error in
            if let error = error {
                result["internet"] = "❌ فشل: \(error.localizedDescription)"
            } else if let httpResponse = response as? HTTPURLResponse {
                result["internet"] = "✅ متصل - Status: \(httpResponse.statusCode)"
            } else {
                result["internet"] = "️ استجابة غير معروفة"
            }
        }
        task.resume()
        task.waitUntilFinished()

        result["applePushServer"] = "تم الفحص"
        return result
    }

    // =======================================================================
    // 📤 إرسال التقرير للسيرفر
    // =======================================================================
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

    // =======================================================================
    // 🧪 اختبار CallKit محلياً
    // =======================================================================
    func testLocalCallKit(result: @escaping FlutterResult) {
        writeLog(" بدء اختبار CallKit محلياً...")

        do {
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
                "timestamp": Date().timeIntervalSince1970,
                "room_name": "test_diagnostic_\(Int(Date().timeIntervalSince1970))",
                "livekit_url": "wss://call.beytei.com",
                "token": "test_token_\(testUUID)"
            ] as NSDictionary

            writeLog("🔔 عرض CallKit تجريبي (UUID: \(testUUID))...")
            SwiftFlutterCallkitIncomingPlugin.sharedInstance?.showCallkitIncoming(callData, fromPushKit: false)
            callKitShownCount += 1

            result([
                "success": true,
                "message": "تم إرسال أمر CallKit بنجاح. إذا ظهرت الشاشة، فالمكتبة تعمل. إذا لم تظهر، فالمشكلة في إعدادات Background Modes أو الأذونات.",
                "uuid": testUUID
            ])

        } catch {
            lastError = "فشل اختبار CallKit: \(error.localizedDescription)"
            writeLog("❌ \(lastError ?? "")")
            result(["success": false, "message": lastError ?? "خطأ غير معروف"])
        }
    }
}

// =======================================================================
// VoIP Push Registry Delegate
// =======================================================================
extension AppDelegate: PKPushRegistryDelegate {

    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        guard type == .voIP else { return }

        let deviceToken = credentials.token.map { String(format: "%02.2hhx", $0) }.joined()
        UserDefaults.standard.set(deviceToken, forKey: "flutter.voip_token")
        SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP(deviceToken)
        writeLog("🔑 تم استلام توكن VoIP: \(deviceToken.prefix(15))... (الطول: \(deviceToken.count))")
    }

    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, withCompletionHandler completion: @escaping () -> Void) {

        guard type == .voIP else {
            completion()
            return
        }

        pushKitReceivedCount += 1
        writeLog("⬇️ استلام إشعار VoIP (#\(pushKitReceivedCount))")

        let dict = payload.dictionaryPayload as? [String: Any] ?? [:]
        lastPushKitPayload = dict

        let isCancel = (dict["type"] as? String == "cancel_call") || (dict["type"] as? Int == 1) || (dict["type"] as? String == "1")

        let rawId = (dict["id"] as? String) ?? (dict["order_id"] as? String) ?? ""
        let validUUID = UUID(uuidString: rawId)?.uuidString ?? UUID().uuidString

        if isCancel {
            writeLog("🚫 إلغاء المكالمة (UUID: \(validUUID))")
            let callData = flutter_callkit_incoming.Data(id: validUUID, nameCaller: "", handle: "", type: 0)
            SwiftFlutterCallkitIncomingPlugin.sharedInstance?.endCall(callData)
            completion()
            return
        }

        let callerName = (dict["name"] as? String) ?? (dict["driver_name"] as? String) ?? "مندوب بيتي"
        let handle = (dict["handle"] as? String) ?? (dict["driver_phone"] as? String) ?? "مكالمة واردة"
        let duration = dict["duration"] as? Int ?? 60000

        let rawExtra = dict["extra"] as? [String: Any] ?? dict
        let extraDict = rawExtra as NSDictionary

        var avatar = dict["avatar"] as? String ?? dict["driver_image"] as? String ?? ""
        if avatar.hasPrefix("http://") {
            avatar = avatar.replacingOccurrences(of: "http://", with: "https://")
        }

        let callData = flutter_callkit_incoming.Data(id: validUUID, nameCaller: callerName, handle: handle, type: 0)
        callData.appName = "منصة بيتي"
        callData.avatar = avatar
        callData.duration = duration
        callData.extra = extraDict

        writeLog("🔔 عرض CallKit (UUID: \(validUUID), Caller: \(callerName))")

        do {
            SwiftFlutterCallkitIncomingPlugin.sharedInstance?.showCallkitIncoming(callData, fromPushKit: true)
            callKitShownCount += 1
            writeLog("✅ تم إرسال CallKit بنجاح")
        } catch {
            lastError = "فشل عرض CallKit: \(error.localizedDescription)"
            writeLog("❌ \(lastError ?? "")")
        }

        completion()
    }

    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        guard type == .voIP else { return }
        UserDefaults.standard.removeObject(forKey: "flutter.voip_token")
        SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP("")
        writeLog("⚠️ تم إبطال توكن VoIP")
    }
}