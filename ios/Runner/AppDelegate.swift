import UIKit
import Flutter
import Firebase
import FirebaseMessaging
import PushKit
import flutter_callkit_incoming
import CallKit

@main
@objc class AppDelegate: FlutterAppDelegate {

    // MARK: - Properties

    private var voipRegistry: PKPushRegistry?
    private var diagnosticChannelConfigured = false

    private lazy var callKitProvider: CXProvider = {
        let config = CXProviderConfiguration()
        config.localizedName = "منصة بيتي"
        config.supportsVideo = false
        config.maximumCallGroups = 1
        config.maximumCallsPerCallGroup = 1
        config.supportedHandleTypes = [.generic]

        let provider = CXProvider(configuration: config)
        provider.setDelegate(self, queue: .main)
        return provider
    }()

    private var pendingPayloadByUUID: [UUID: [String: Any]] = [:]
    private var activeCallUUIDs: Set<UUID> = []
    private var answeredCallUUIDs: Set<UUID> = []

    private var pushKitReceivedCount = 0
    private var callKitShownCount = 0
    private var lastPushKitPayload: [String: Any]?
    private var lastError: String?

    // MARK: - Logger

    private func writeLog(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        let timeString = formatter.string(from: Date())
        let logMessage = "[\(timeString)] 🍏 \(message)"

        var logs = UserDefaults.standard.stringArray(forKey: "ios_debug_logs") ?? []
        logs.append(logMessage)

        if logs.count > 100 {
            logs.removeFirst()
        }

        UserDefaults.standard.set(logs, forKey: "ios_debug_logs")
        print(logMessage)
    }

    // MARK: - App Lifecycle

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        FirebaseApp.configure()
        GeneratedPluginRegistrant.register(with: self)

        let launched = super.application(application, didFinishLaunchingWithOptions: launchOptions)

        setupDiagnosticChannelIfNeeded()

        // استعادة توكن VoIP إلى مكتبة flutter_callkit_incoming إن وُجد
        if let storedToken = UserDefaults.standard.string(forKey: "flutter.voip_token"),
           !storedToken.isEmpty {
            SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP(storedToken)
            writeLog("🔁 تم استعادة توكن VoIP إلى flutter_callkit_incoming")
        } else {
            writeLog("⚠️ لا يوجد توكن VoIP محفوظ عند بدء التطبيق")
        }

        // تجهيز Native CallKit Provider
        _ = callKitProvider
        writeLog("🧠 تم تجهيز Native CXProvider")

        // تجهيز PushKit
        let registry = PKPushRegistry(queue: .main)
        registry.delegate = self
        registry.desiredPushTypes = [.voIP]
        self.voipRegistry = registry

        writeLog("🚀 تم تشغيل PushKit + Native CallKit fallback + Diagnostic Channel")

        return launched
    }

    override func applicationDidBecomeActive(_ application: UIApplication) {
        super.applicationDidBecomeActive(application)
        setupDiagnosticChannelIfNeeded()
    }

    override func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable : Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        Messaging.messaging().appDidReceiveMessage(userInfo)
        completionHandler(.newData)
    }

    // MARK: - Diagnostic Channel

    private func setupDiagnosticChannelIfNeeded() {
        guard !diagnosticChannelConfigured else { return }

        guard let controller = window?.rootViewController as? FlutterViewController else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.setupDiagnosticChannelIfNeeded()
            }
            return
        }

        let channel = FlutterMethodChannel(
            name: "beytei_deep_debugger",
            binaryMessenger: controller.binaryMessenger
        )

        channel.setMethodCallHandler { [weak self] call, result in
            guard let self = self else { return }

            switch call.method {
            case "getLogs":
                let logs = UserDefaults.standard.stringArray(forKey: "ios_debug_logs") ?? []
                let token = UserDefaults.standard.string(forKey: "flutter.voip_token") ?? "❌ لا يوجد"

                result([
                    "logs": logs.joined(separator: "\n\n"),
                    "token": token
                ])

                self.writeLog("📋 تم طلب السجلات من Flutter")

            case "getPushKitStatus":
                result([
                    "receivedCount": self.pushKitReceivedCount,
                    "callKitShownCount": self.callKitShownCount,
                    "lastPayload": self.lastPushKitPayload ?? [:],
                    "lastError": self.lastError ?? "لا يوجد خطأ",
                    "voipToken": UserDefaults.standard.string(forKey: "flutter.voip_token") ?? "❌ مفقود"
                ])

            case "testLocalCallKit":
                self.testLocalCallKit(result: result)

            case "checkPermissions":
                self.checkPermissions(result: result)

            case "runFullDiagnostics":
                let serverUrl = call.arguments as? String ?? ""
                self.writeLog("🔬 بدء التشخيص الشامل...")

                let report = self.collectFullDiagnosticReport()

                self.sendDiagnosticToServer(report: report, serverUrl: serverUrl) { success, response in
                    DispatchQueue.main.async {
                        if success {
                            self.writeLog("✅ تم إرسال التقرير للسيرفر بنجاح")
                        } else {
                            self.writeLog("❌ فشل إرسال التقرير: \(response ?? "unknown")")
                        }

                        result([
                            "success": success,
                            "report": report,
                            "serverResponse": response ?? ""
                        ])
                    }
                }

            default:
                result(FlutterMethodNotImplemented)
            }
        }

        diagnosticChannelConfigured = true
        writeLog("🧰 تم تجهيز قناة التشخيص beytei_deep_debugger")
    }

    private func testLocalCallKit(result: @escaping FlutterResult) {
        writeLog("🧪 بدء اختبار CallKit محليًا...")

        guard let plugin = SwiftFlutterCallkitIncomingPlugin.sharedInstance else {
            lastError = "مكتبة flutter_callkit_incoming غير جاهزة"
            writeLog("❌ \(lastError ?? "")")
            result([
                "success": false,
                "message": lastError ?? "مكتبة flutter_callkit_incoming غير جاهزة"
            ])
            return
        }

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

        plugin.showCallkitIncoming(callData, fromPushKit: false)
        callKitShownCount += 1

        writeLog("🔔 تم إرسال اختبار CallKit محليًا UUID: \(testUUID)")

        result([
            "success": true,
            "message": "تم إرسال أمر CallKit بنجاح.",
            "uuid": testUUID
        ])
    }

    private func checkPermissions(result: @escaping FlutterResult) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let statusText: String

            switch settings.authorizationStatus {
            case .notDetermined:
                statusText = "لم تُحدد بعد"
            case .denied:
                statusText = "مرفوضة"
            case .authorized:
                statusText = "مسموحة ✅"
            case .provisional:
                statusText = "مؤقتة"
            case .ephemeral:
                statusText = "مؤقتة (App Clip)"
            @unknown default:
                statusText = "غير معروف"
            }

            let payload: [String: Any] = [
                "notifications": [
                    "authorizationStatus": settings.authorizationStatus.rawValue,
                    "statusText": statusText,
                    "soundSetting": settings.soundSetting.rawValue,
                    "badgeSetting": settings.badgeSetting.rawValue,
                    "alertSetting": settings.alertSetting.rawValue
                ]
            ]

            DispatchQueue.main.async {
                result(payload)
                self.writeLog("🔐 تم فحص الأذونات")
            }
        }
    }

    private func collectFullDiagnosticReport() -> [String: Any] {
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

    private func sendDiagnosticToServer(
        report: [String: Any],
        serverUrl: String,
        completion: @escaping (Bool, String?) -> Void
    ) {
        guard !serverUrl.isEmpty, let url = URL(string: serverUrl) else {
            completion(false, "serverUrl غير صالح أو فارغ")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let safeReport = sanitizedStringDictionary(report)
            let jsonData = try JSONSerialization.data(withJSONObject: safeReport, options: .prettyPrinted)
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

    // MARK: - Sanitization Helpers

    private func sanitizedDictionary(_ input: [AnyHashable: Any]) -> [String: Any] {
        var output: [String: Any] = [:]

        for (key, value) in input {
            guard let stringKey = key as? String else { continue }
            output[stringKey] = sanitizedValue(value)
        }

        return output
    }

    private func sanitizedStringDictionary(_ input: [String: Any]) -> [String: Any] {
        var output: [String: Any] = [:]

        for (key, value) in input {
            output[key] = sanitizedValue(value)
        }

        return output
    }

    private func sanitizedValue(_ value: Any) -> Any {
        if let dict = value as? [AnyHashable: Any] {
            return sanitizedDictionary(dict)
        }

        if let array = value as? [Any] {
            return array.map { sanitizedValue($0) }
        }

        if let data = value as? Data {
            return data.base64EncodedString()
        }

        if value is String || value is NSNumber || value is NSNull {
            return value
        }

        return String(describing: value)
    }

    // MARK: - Native CallKit Helpers

    private func reportNativeIncomingCall(
        uuidString: String,
        callerName: String,
        handle: String,
        payload: [String: Any],
        pushCompletion: @escaping () -> Void
    ) {
        let callUUID = UUID(uuidString: uuidString) ?? UUID()

        var normalizedPayload = sanitizedStringDictionary(payload)
        normalizedPayload["id"] = callUUID.uuidString

        pendingPayloadByUUID[callUUID] = normalizedPayload
        activeCallUUIDs.insert(callUUID)

        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: handle)
        update.localizedCallerName = callerName
        update.hasVideo = false

        var finished = false

        let finishOnce: () -> Void = {
            if !finished {
                finished = true
                pushCompletion()
                self.writeLog("✅ تم استدعاء completion() بعد Native CallKit")
            }
        }

        writeLog("📞 جاري الإبلاغ عن مكالمة Native: \(callUUID.uuidString)")

        callKitProvider.reportNewIncomingCall(with: callUUID, update: update) { error in
            if let error = error {
                self.lastError = error.localizedDescription
                self.writeLog("❌ فشل Native CallKit: \(error.localizedDescription)")

                self.activeCallUUIDs.remove(callUUID)
                self.answeredCallUUIDs.remove(callUUID)
                self.pendingPayloadByUUID.removeValue(forKey: callUUID)
            } else {
                self.callKitShownCount += 1
                self.writeLog("✅ تم عرض Native CallKit بنجاح")
            }

            finishOnce()
        }

        // شبكة أمان: لا تترك completion معلقًا للأبد
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            finishOnce()
        }
    }

    private func deliverCallEventToFlutter(payload: [String: Any], event: String) {
        writeLog("📨 إرسال حدث المكالمة إلى Flutter: \(event)")

        let safePayload = sanitizedStringDictionary(payload)

        if let controller = window?.rootViewController as? FlutterViewController {
            let channel = FlutterMethodChannel(
                name: "beytei_native_call",
                binaryMessenger: controller.binaryMessenger
            )

            channel.invokeMethod("onCallEvent", arguments: [
                "event": event,
                "payload": safePayload
            ])

            writeLog("✅ تم إرسال حدث \(event) إلى Flutter مباشرة")
        } else {
            // إذا لم يكن Flutter جاهزًا، احفظه ليقرأه التطبيق عند الإقلاع
            if let data = try? JSONSerialization.data(withJSONObject: safePayload, options: []),
               let jsonString = String(data: data, encoding: .utf8) {
                UserDefaults.standard.set(jsonString, forKey: "pending_native_call_payload")
                UserDefaults.standard.set(event, forKey: "pending_native_call_event")
                writeLog("💾 تم حفظ حدث المكالمة مؤقتًا في UserDefaults: \(event)")
            } else {
                UserDefaults.standard.set("{}", forKey: "pending_native_call_payload")
                UserDefaults.standard.set(event, forKey: "pending_native_call_event")
                writeLog("⚠️ تم حفظ حدث المكالمة مؤقتًا لكن payload غير قابل للتحويل إلى JSON")
            }
        }
    }

    private func endNativeCallIfNeeded(uuidString: String) {
        guard let callUUID = UUID(uuidString: uuidString) else { return }

        if activeCallUUIDs.contains(callUUID) {
            let wasAnswered = answeredCallUUIDs.contains(callUUID)
            let payload = pendingPayloadByUUID[callUUID] ?? [:]

            callKitProvider.endCall(with: callUUID)

            activeCallUUIDs.remove(callUUID)
            answeredCallUUIDs.remove(callUUID)
            pendingPayloadByUUID.removeValue(forKey: callUUID)

            deliverCallEventToFlutter(payload: payload, event: wasAnswered ? "end" : "decline")

            writeLog("🚫 تم إنهاء مكالمة Native: \(uuidString)")
        }
    }
}

// MARK: - PKPushRegistryDelegate

extension AppDelegate: PKPushRegistryDelegate {

    func pushRegistry(
        _ registry: PKPushRegistry,
        didUpdate credentials: PKPushCredentials,
        for type: PKPushType
    ) {
        guard type == .voIP else { return }

        let deviceToken = credentials.token.map { String(format: "%02x", $0) }.joined()

        UserDefaults.standard.set(deviceToken, forKey: "flutter.voip_token")

        SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP(deviceToken)

        writeLog("🔑 VoIP Token: \(deviceToken.prefix(15))... length=\(deviceToken.count)")
    }

    func pushRegistry(
        _ registry: PKPushRegistry,
        didInvalidatePushTokenFor type: PKPushType
    ) {
        guard type == .voIP else { return }

        UserDefaults.standard.removeObject(forKey: "flutter.voip_token")
        SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP("")

        writeLog("⚠️ تم إبطال VoIP Token")
    }

    func pushRegistry(
        _ registry: PKPushRegistry,
        didReceiveIncomingPushWith payload: PKPushPayload,
        for type: PKPushType,
        withCompletionHandler completion: @escaping () -> Void
    ) {
        writeLog("🔥🔥 وصل إشعار VoIP إلى AppDelegate")

        guard type == .voIP else {
            writeLog("⚠️ تم تجاهل إشعار غير VoIP")
            completion()
            return
        }

        pushKitReceivedCount += 1

        let dict = sanitizedDictionary(payload.dictionaryPayload)
        lastPushKitPayload = dict

        writeLog("⬇️ Payload: \(dict)")

        let rawId = (dict["id"] as? String) ?? (dict["order_id"] as? String) ?? ""
        let callUUID = UUID(uuidString: rawId) ?? UUID()
        let validUUID = callUUID.uuidString

        let typeValue = dict["type"]
        let actionValue = dict["action"] as? String
        let isCancelFlag = (dict["is_cancel"] as? Bool) == true

        // تنبيه: تطبيقك حاليًا صوتي فقط، لذلك نعتبر type == 1 إلغاء.
        // إذا أضفت مكالمات فيديو مستقبلًا، يجب إزالة هذا الشرط أو استخدام action/is_cancel فقط.
        let isCancelNumeric =
            (typeValue as? Int == 1) ||
            (typeValue as? String == "1")

        let isCancel =
            actionValue == "cancel_call" ||
            (typeValue as? String == "cancel_call") ||
            isCancelFlag ||
            isCancelNumeric

        if isCancel {
            writeLog("🚫 طلب إلغاء مكالمة عبر VoIP Push: \(validUUID)")

            let wasAnswered = answeredCallUUIDs.contains(callUUID)
            let payloadForFlutter = pendingPayloadByUUID[callUUID] ?? [:]
            let wasActive = activeCallUUIDs.contains(callUUID)

            if wasActive {
                callKitProvider.endCall(with: callUUID)

                activeCallUUIDs.remove(callUUID)
                answeredCallUUIDs.remove(callUUID)
                pendingPayloadByUUID.removeValue(forKey: callUUID)

                deliverCallEventToFlutter(
                    payload: payloadForFlutter,
                    event: wasAnswered ? "end" : "decline"
                )

                writeLog("✅ تم إنهاء المكالمة النشطة بسبب cancel")
            } else {
                writeLog("⚠️ وصل cancel بدون مكالمة نشطة في Native CallKit")
            }

            // محاولة إنهاء المكالمة عبر مكتبة flutter_callkit_incoming إن كانت جاهزة
            if let plugin = SwiftFlutterCallkitIncomingPlugin.sharedInstance {
                let callData = flutter_callkit_incoming.Data(
                    id: validUUID,
                    nameCaller: "",
                    handle: "",
                    type: 1
                )

                plugin.endCall(callData)
            }

            completion()
            return
        }

        let callerName =
            (dict["nameCaller"] as? String) ??
            (dict["driver_name"] as? String) ??
            (dict["name"] as? String) ??
            "مندوب بيتي"

        let handle =
            (dict["handle"] as? String) ??
            (dict["driver_phone"] as? String) ??
            "مكالمة واردة"

        // الحل الأقوى للآيفون:
        // لا تعتمد على plugin.sharedInstance لعرض المكالمة الواردة من PushKit.
        // استخدم Native CallKit مباشرة لضمان أن iOS يرى مكالمة واردة.
        reportNativeIncomingCall(
            uuidString: validUUID,
            callerName: callerName,
            handle: handle,
            payload: dict,
            pushCompletion: completion
        )
    }
}

// MARK: - CXProviderDelegate

extension AppDelegate: CXProviderDelegate {

    func providerDidReset(_ provider: CXProvider) {
        writeLog("🔄 تم إعادة تعيين CXProvider")

        activeCallUUIDs.removeAll()
        answeredCallUUIDs.removeAll()
        pendingPayloadByUUID.removeAll()
    }

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        writeLog("✅ المستخدم رد على المكالمة Native")

        answeredCallUUIDs.insert(action.call.uuid)

        let payload = pendingPayloadByUUID[action.call.uuid] ?? [:]

        action.fulfill()

        deliverCallEventToFlutter(payload: payload, event: "accept")
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        let uuid = action.call.uuid
        let wasAnswered = answeredCallUUIDs.contains(uuid)
        let payload = pendingPayloadByUUID[uuid] ?? [:]

        writeLog(wasAnswered ? "⛔ تم إنهاء المكالمة Native بعد الرد" : "⛔ تم رفض المكالمة Native")

        answeredCallUUIDs.remove(uuid)
        activeCallUUIDs.remove(uuid)
        pendingPayloadByUUID.removeValue(forKey: uuid)

        action.fulfill()

        deliverCallEventToFlutter(payload: payload, event: wasAnswered ? "end" : "decline")
    }

    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        action.fulfill()
    }

    func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
        action.fulfill()
    }
}