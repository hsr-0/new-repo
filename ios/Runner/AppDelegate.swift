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
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, CallkitIncomingAppDelegate {

    var voipRegistry: PKPushRegistry?

    private var pushKitReceivedCount = 0
    private var lastPushKitPayload: [String: Any]?
    private var callKitShownCount = 0
    private var lastError: String?
    private var activeCallMap: [UUID: [String: Any]] = [:]

    // Best-effort native cancellation watcher while CallKit is ringing.
    // A suspended app may pause timers; FCM and CallKit's own timeout remain
    // fallbacks. The backend state is always authoritative.
    private var ringStatusTimers: [String: Timer] = [:]

    private func stopRingStatusWatch(uuid: String) {
        let key = uuid.uppercased()
        ringStatusTimers[key]?.invalidate()
        ringStatusTimers.removeValue(forKey: key)
    }

    @discardableResult
    private func endSpecificCall(uuid: String, reason: String) -> Bool {
        let normalized = UUID(uuidString: uuid)?.uuidString ?? uuid
        stopRingStatusWatch(uuid: normalized)
        guard let plugin = SwiftFlutterCallkitIncomingPlugin.sharedInstance else {
            writeLog("⚠️ لا يوجد CallKit plugin عند إغلاق \(normalized)")
            return false
        }
        let callData = flutter_callkit_incoming.Data(
            id: normalized, nameCaller: "", handle: "", type: 0
        )
        plugin.endCall(callData)
        writeLog("📴 Closing CallKit \(normalized) | \(reason)")
        return true
    }

    private func checkServerCallStatus(orderId: String, uuid: String) {
        guard !orderId.isEmpty, !uuid.isEmpty else { return }
        var components = URLComponents(string:
            "https://re.beytei.com/wp-json/beytei-calls/v1/status")!
        components.queryItems = [
            URLQueryItem(name: "order_id", value: orderId),
            URLQueryItem(name: "uuid", value: uuid)
        ]
        guard let url = components.url else { return }
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 5
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard error == nil,
                  let http = response as? HTTPURLResponse,
                  http.statusCode == 200,
                  let data = data,
                  let object = try? JSONSerialization.jsonObject(with: data)
                    as? [String: Any],
                  let state = object["state"] as? String else { return }
            if ["cancelled", "declined", "missed"].contains(state) {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    guard self.ringStatusTimers[uuid.uppercased()] != nil else { return }
                    self.endSpecificCall(uuid: uuid, reason: "server status: \(state)")
                    self.notifyFlutterCallEnded(data: ["id": uuid, "order_id": orderId])
                }
            }
        }.resume()
    }

    private func startRingStatusWatch(orderId: String, uuid: String) {
        guard !orderId.isEmpty, !uuid.isEmpty else { return }
        let key = uuid.uppercased()
        stopRingStatusWatch(uuid: key)
        var attempts = 0
        let timer = Timer(timeInterval: 3, repeats: true) { [weak self] timer in
            attempts += 1
            if attempts > 20 { timer.invalidate(); self?.ringStatusTimers.removeValue(forKey: key); return }
            self?.checkServerCallStatus(orderId: orderId, uuid: key)
        }
        ringStatusTimers[key] = timer
        RunLoop.main.add(timer, forMode: .common)
        checkServerCallStatus(orderId: orderId, uuid: key)
    }

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
                    if let args = call.arguments as? [String: Any],
                       let callId = args["callId"] as? String,
                       !callId.isEmpty {
                        result(self.endSpecificCall(uuid: callId, reason: "Flutter hangup or cancel"))
                    } else {
                        result(FlutterError(code: "missing_call_id", message: "callId required", details: nil))
                    }


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
            "callKitShownCount": callKitShownCount, // Callback completed; not an independent UI-visibility signal
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
        else if let presented = window?.rootViewController?.presentedViewController as? FlutterViewController { flutterVC = presented }

        guard let controller = flutterVC else {
            writeLog("⚠️ تعذر إرسال حدث إنهاء المكالمة إلى Flutter؛ لا توجد FlutterViewController")
            return
        }

        let channel = FlutterMethodChannel(
            name: "beytei_native_call",
            binaryMessenger: controller.binaryMessenger
        )
        channel.invokeMethod("onCallEvent", arguments: ["event": "end", "payload": data]) { _ in }
    }

    // MARK: - CallkitIncomingAppDelegate callbacks
    // These callbacks connect the native CallKit answer/end actions to Flutter.
    func onAccept(_ call: Call, _ action: CXAnswerCallAction) {
        stopRingStatusWatch(uuid: String(describing: call.data.uuid))
        writeLog("📞 CallKit: قبول المكالمة \(call.data.uuid)")
        action.fulfill()
        let callData = call.data.toJSON()
        DispatchQueue.main.async {
            self.notifyFlutterCallAccepted(data: callData)
        }
    }

    func onDecline(_ call: Call, _ action: CXEndCallAction) {
        stopRingStatusWatch(uuid: String(describing: call.data.uuid))
        writeLog("📵 CallKit: رفض المكالمة \(call.data.uuid)")
        action.fulfill()
        let callData = call.data.toJSON()
        DispatchQueue.main.async {
            self.notifyFlutterCallEnded(data: callData)
        }
    }

    func onEnd(_ call: Call, _ action: CXEndCallAction) {
        stopRingStatusWatch(uuid: String(describing: call.data.uuid))
        writeLog("📴 CallKit: إنهاء المكالمة \(call.data.uuid)")
        action.fulfill()
        let callData = call.data.toJSON()
        DispatchQueue.main.async {
            self.notifyFlutterCallEnded(data: callData)
        }
    }

    func onTimeOut(_ call: Call) {
        stopRingStatusWatch(uuid: String(describing: call.data.uuid))
        writeLog("⌛ CallKit: انتهت مهلة الرنين للمكالمة \(call.data.uuid)")
        let callData = call.data.toJSON()
        DispatchQueue.main.async {
            self.notifyFlutterCallEnded(data: callData)
        }
    }

    func didActivateAudioSession(_ audioSession: AVAudioSession) {
        writeLog("🔊 CallKit activated the audio session")
    }

    func didDeactivateAudioSession(_ audioSession: AVAudioSession) {
        writeLog("🔇 CallKit deactivated the audio session")
    }

    func providerDidReset() {
        writeLog("⚠️ CallKit provider was reset")
    }
}

// ===========================================================================
// 📞 PushKit Delegate - النسخة النهائية المُصحّحة حسب توثيق المكتبة الرسمي
// ===========================================================================
extension AppDelegate: PKPushRegistryDelegate {

    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        guard type == .voIP else { return }

        let deviceToken = credentials.token.map { String(format: "%02x", $0) }.joined()
        UserDefaults.standard.set(deviceToken, forKey: "flutter.voip_token")
        SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP(deviceToken)
        writeLog("🔑 تم استلام توكن VoIP: \(deviceToken.prefix(15))... (الطول: \(deviceToken.count))")
    }

    // ===========================================================================
    // 🚀 دالة استقبال VoIP Push - النسخة المُصحّحة حسب توثيق المكتبة الرسمي
    // ⚠️ التوثيق الرسمي يقول: يجب تأخير completion() بـ 1.5 ثانية
    // ===========================================================================
    // Apple's Swift protocol name is `completion:` (not `withCompletionHandler:`).
    // This exact selector is required for PushKit to invoke this delegate method.
    func pushRegistry(
        _ registry: PKPushRegistry,
        didReceiveIncomingPushWith payload: PKPushPayload,
        for type: PKPushType,
        completion: @escaping () -> Void
    ) {
        guard type == .voIP else {
            completion()
            return
        }

        // Keep this log before any other work so it is visible as early as possible.
        writeLog("📥 دخلت دالة استقبال PushKit")

        let dict = payload.dictionaryPayload as? [String: Any] ?? [:]
        let nestedExtra = dict["extra"] as? [String: Any] ?? [:]

        let rawId = (dict["id"] as? String) ?? UUID().uuidString
        let callUUID = UUID(uuidString: rawId)?.uuidString ?? UUID().uuidString

        // Read from top level first, then from `extra`; ignore blank top-level values.
        func payloadString(_ key: String, fallback: String = "") -> String {
            if let value = dict[key] as? String, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return value
            }
            if let value = nestedExtra[key] as? String, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return value
            }
            return fallback
        }

        let callerName = payloadString(
            "nameCaller",
            fallback: payloadString("driver_name", fallback: "مندوب بيتي")
        )
        let handle = payloadString(
            "handle",
            fallback: payloadString("driver_phone", fallback: "مكالمة واردة")
        )

        var avatar = payloadString(
            "avatar",
            fallback: payloadString("driver_image", fallback: "")
        )
        if avatar.hasPrefix("http://") {
            avatar = avatar.replacingOccurrences(of: "http://", with: "https://")
        }

        // Cancellation messages must end the existing call, not create a new call.
        let typeValue = dict["type"] as? String
        let actionValue = dict["action"] as? String
        let isCancel = typeValue == "cancel_call" ||
            actionValue == "cancel_call" ||
            typeValue == "cancel" ||
            actionValue == "cancel"

        if isCancel {
            let cancelData = flutter_callkit_incoming.Data(
                id: callUUID,
                nameCaller: "",
                handle: "",
                type: 0
            )

            if let plugin = SwiftFlutterCallkitIncomingPlugin.sharedInstance {
                plugin.endCall(cancelData)
                writeLog("🚫 أُرسل طلب إنهاء المكالمة إلى CallKit (UUID: \(callUUID))")
            } else {
                lastError = "CallKit plugin instance is nil while cancelling a call"
                writeLog("❌ لا توجد نسخة من مكتبة CallKit عند طلب الإلغاء")
            }

            completion()
            return
        }

        let callData = flutter_callkit_incoming.Data(
            id: callUUID,
            nameCaller: callerName,
            handle: handle,
            type: 0
        )
        callData.appName = "منصة بيتي"
        callData.avatar = avatar
        callData.duration = 60000

        // Preserve all nested extra values (for example `test`) and normalize
        // connection fields from either the top level or nested `extra`.
        var extraDict = nestedExtra
        extraDict["id"] = callUUID
        extraDict["nameCaller"] = callerName
        extraDict["handle"] = handle
        extraDict["avatar"] = avatar
        extraDict["room_name"] = payloadString(
            "room_name",
            fallback: payloadString("channel_name", fallback: "")
        )
        extraDict["livekit_url"] = payloadString(
            "livekit_url",
            fallback: "wss://call.beytei.com"
        )
        extraDict["token"] = payloadString(
            "token",
            fallback: payloadString("livekit_token", fallback: "")
        )
        extraDict["order_id"] = payloadString("order_id", fallback: "")
        callData.extra = extraDict as NSDictionary

        guard let plugin = SwiftFlutterCallkitIncomingPlugin.sharedInstance else {
            lastError = "CallKit plugin instance is nil"
            writeLog("❌ CallKit plugin instance is nil; incoming call could not be reported")
            // Do not claim the call was displayed. Without the plugin/provider there
            // is no successful CallKit report in this path.
            completion()
            return
        }

        writeLog("📞 إرسال طلب عرض المكالمة إلى CallKit: \(callUUID)")

        // Use the library's completion overload. It is called after the library's
        // reportNewIncomingCall completion handler, unlike an arbitrary fixed delay.
        plugin.showCallkitIncoming(callData, fromPushKit: true) {
            // Call PushKit's completion exactly once, after the CallKit reporting path
            // has completed. The library overload does not expose the CallKit error,
            // so this log means callback completed, not that the UI is guaranteed shown.
            completion()

            DispatchQueue.main.async {
                self.pushKitReceivedCount += 1
                self.lastPushKitPayload = dict
                self.callKitShownCount += 1
                self.activeCallMap[UUID(uuidString: callUUID) ?? UUID()] = extraDict
                UserDefaults.standard.set(extraDict, forKey: "call_\(callUUID)")

                self.writeLog("✅ اكتمل callback الخاص ببلاغ CallKit (UUID: \(callUUID))")
                self.writeLog("ℹ️ عداد CallKit يعبّر عن اكتمال callback، وليس تأكيداً مستقلاً لظهور الواجهة")

                let markerKey = "flutter.beytei_cancel_\(callUUID.uppercased())"
                let cancelledAt = UserDefaults.standard.object(forKey: markerKey) as? Int ?? 0
                let ageMillis = Int(Date().timeIntervalSince1970 * 1000) - cancelledAt
                if cancelledAt > 0 && ageMillis >= 0 && ageMillis < 120000 {
                    self.endSpecificCall(uuid: callUUID, reason: "FCM cancellation arrived before PushKit")
                    UserDefaults.standard.removeObject(forKey: markerKey)
                } else {
                    self.startRingStatusWatch(
                        orderId: extraDict["order_id"] as? String ?? "",
                        uuid: callUUID
                    )
                    self.notifyFlutterIncomingCall(data: extraDict)
                }
            }
        }
    }

    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        guard type == .voIP else { return }
        UserDefaults.standard.removeObject(forKey: "flutter.voip_token")
        SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP("")
        writeLog("⚠️ تم إبطال توكن VoIP")
    }
}
