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

    // 🔥 CXProvider خاص بنا - يُبلّغ iOS SYNCHRONOUSLY عن المكالمات
    var callKitProvider: CXProvider?

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

        // ============================================================
        // 🔥🔥🔥 الخطوة 1: تهيئة CXProvider الخاص بنا أولاً 🔥🔥🔥
        // ============================================================
        let providerConfig = CXProviderConfiguration()
        providerConfig.supportsVideo = false
        providerConfig.maximumCallGroups = 1
        providerConfig.maximumCallsPerCallGroup = 1
        providerConfig.supportedHandleTypes = [.generic, .phoneNumber]
        if let logoImage = UIImage(named: "CallKitLogo") {
            providerConfig.iconTemplateImageData = logoImage.pngData()
        }

        self.callKitProvider = CXProvider(configuration: providerConfig)
        self.callKitProvider?.setDelegate(self, queue: nil)  // nil = main queue

        // ============================================================
        // الخطوة 2: تهيئة Firebase والمكتبات
        // ============================================================
        FirebaseApp.configure()
        GeneratedPluginRegistrant.register(with: self)

        // ============================================================
        // الخطوة 3: قناة التشخيص
        // ============================================================
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
                    self.writeLog("🧪 بدء اختبار CallKit محلياً...")
                    self.testLocalCallKit(result: result)

                case "checkPermissions":
                    let status = self.checkAllPermissions()
                    result(status)
                    self.writeLog("🔐 تم فحص الأذونات")

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
                    // 🔥 إنهاء مكالمة Native من Dart
                    if let args = call.arguments as? [String: Any],
                       let callId = args["callId"] as? String,
                       let uuid = UUID(uuidString: callId) {
                        self.writeLog("📞 إعلام iOS بإنهاء المكالمة: \(callId)")
                        let endCallAction = CXEndCallAction(call: uuid)
                        let transaction = CXTransaction(action: endCallAction)
                        CXCallController().request(transaction) { error in
                            if let error = error {
                                self.writeLog("❌ فشل إنهاء المكالمة: \(error.localizedDescription)")
                            } else {
                                self.writeLog("✅ تم إنهاء المكالمة بنجاح")
                            }
                        }
                    }
                    result(true)

                default:
                    result(FlutterMethodNotImplemented)
                }
            })
        }

        // ============================================================
        // 🔥🔥🔥 الخطوة 4: تهيئة PushKit 🔥🔥🔥
        // ============================================================
        self.voipRegistry = PKPushRegistry(queue: .main)
        self.voipRegistry?.delegate = self
        self.voipRegistry?.desiredPushTypes = [.voIP]

        writeLog("🚀 التطبيق بدأ + PushKit + Native CXProvider + Diagnostic Channel")
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

        report["nativeProvider"] = [
            "isReady": callKitProvider != nil
        ]

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
        case .denied: return "مرفوضة"
        case .authorized: return "مسموحة ✅"
        case .provisional: return "مؤقتة"
        case .ephemeral: return "مؤقتة (App Clip)"
        @unknown default: return "غير معروف"
        }
    }

    // =======================================================================
    // 🌐 فحص الشبكة
    // =======================================================================
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
    // 🧪 اختبار CallKit محلياً (يستخدم المكتبة - يعمل)
    // =======================================================================
    func testLocalCallKit(result: @escaping FlutterResult) {
        writeLog("🧪 بدء اختبار CallKit محلياً...")
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

        result(["success": true, "message": "تم إرسال أمر CallKit بنجاح.", "uuid": testUUID])
    }

    // =======================================================================
    // 📢 إعلام Flutter - مكالمة واردة
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
            writeLog("⚠️ لا يمكن إعلام Flutter: لم يتم العثور على FlutterViewController")
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

        writeLog("📢 تم إعلام Flutter بوجود مكالمة واردة")
    }

    // =======================================================================
    // 📢 إعلام Flutter - تم قبول المكالمة
    // =======================================================================
    func notifyFlutterCallAccepted(data: [String: Any]) {
        var flutterVC: FlutterViewController? = nil

        if let vc = window?.rootViewController as? FlutterViewController {
            flutterVC = vc
        } else if let nav = window?.rootViewController as? UINavigationController {
            flutterVC = nav.topViewController as? FlutterViewController
        } else if let tab = window?.rootViewController as? UITabBarController {
            flutterVC = tab.selectedViewController as? FlutterViewController
        }

        guard let controller = flutterVC else { return }

        let channel = FlutterMethodChannel(
            name: "beytei_native_call",
            binaryMessenger: controller.binaryMessenger
        )

        channel.invokeMethod("onCallEvent", arguments: [
            "event": "accept",
            "payload": data
        ]) { _ in }

        writeLog("📢 تم إعلام Flutter بقبول المكالمة")
    }

    // =======================================================================
    // 📢 إعلام Flutter - انتهاء المكالمة
    // =======================================================================
    func notifyFlutterCallEnded(data: [String: Any]) {
        var flutterVC: FlutterViewController? = nil

        if let vc = window?.rootViewController as? FlutterViewController {
            flutterVC = vc
        } else if let nav = window?.rootViewController as? UINavigationController {
            flutterVC = nav.topViewController as? FlutterViewController
        } else if let tab = window?.rootViewController as? UITabBarController {
            flutterVC = tab.selectedViewController as? FlutterViewController
        }

        guard let controller = flutterVC else { return }

        let channel = FlutterMethodChannel(
            name: "beytei_native_call",
            binaryMessenger: controller.binaryMessenger
        )

        channel.invokeMethod("onCallEvent", arguments: [
            "event": "end",
            "payload": data
        ]) { _ in }

        writeLog("📢 تم إعلام Flutter بانتهاء المكالمة")
    }
}

// ===========================================================================
// 📞 PushKit Delegate - النسخة النهائية المُحسّنة (SYNC-FIRST)
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
    // 🚀 الدالة الحرجة - استقبال VoIP Push
    // ⚠️⚠️⚠️ تحذير: iOS يمنح ~5 ثوانٍ فقط قبل قتل التطبيق
    // ⚠️⚠️⚠️ لا تنفذ أي عملية بطيئة (writeLog أو UserDefaults) قبل reportNewIncomingCall
    // ===========================================================================
    func pushRegistry(_ registry: PKPushRegistry,
                      didReceiveIncomingPushWith payload: PKPushPayload,
                      for type: PKPushType,
                      withCompletionHandler completion: @escaping () -> Void) {

        guard type == .voIP else {
            completion()
            return
        }

        // ✅ استخراج البيانات الأساسية فقط (بدون أي عمليات بطيئة)
        let dict = payload.dictionaryPayload as? [String: Any] ?? [:]
        let rawId = (dict["id"] as? String) ?? UUID().uuidString
        let callUUID = UUID(uuidString: rawId) ?? UUID()

        let callerName = (dict["nameCaller"] as? String)
                      ?? (dict["driver_name"] as? String)
                      ?? (dict["caller_name"] as? String)
                      ?? "مندوب بيتي"

        let handle = (dict["handle"] as? String)
                  ?? (dict["driver_phone"] as? String)
                  ?? (dict["caller_phone"] as? String)
                  ?? "مكالمة واردة"

        // فحص الإلغاء
        let typeValue = dict["type"]
        let actionValue = dict["action"]
        let isCancel = (typeValue as? String == "cancel_call") ||
                       (actionValue as? String == "cancel_call") ||
                       (typeValue as? String == "cancel") ||
                       (actionValue as? String == "cancel")

        guard let provider = self.callKitProvider else {
            // ⚠️ لا يمكن الإبلاغ! نستدعي completion فوراً لتجنب قتل التطبيق
            completion()
            // الآن نسجل الخطأ بشكل منفصل
            DispatchQueue.main.async {
                self.writeLog("❌ CXProvider غير موجود - لم يتم الإبلاغ")
                self.lastError = "CXProvider missing"
            }
            return
        }

        // =================================================================
        // 🚫 حالة الإلغاء - سريعة
        // =================================================================
        if isCancel {
            let endCallAction = CXEndCallAction(call: callUUID)
            let transaction = CXTransaction(action: endCallAction)
            CXCallController().request(transaction) { _ in }
            completion()

            DispatchQueue.main.async {
                self.writeLog("🚫 إلغاء المكالمة (UUID: \(callUUID))")
            }
            return
        }

        // =================================================================
        // 🔥🔥🔥 الحالة الطبيعية: الإبلاغ الفوري عن المكالمة
        // =================================================================
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: handle)
        update.localizedCallerName = callerName
        update.hasVideo = false
        update.supportsHolding = false
        update.supportsGrouping = false
        update.supportsUngrouping = false
        update.supportsDTMF = false

        // 🔥🔥🔥 الأهم: الإبلاغ فوراً بدون أي writeLog قبل هذا السطر
        provider.reportNewIncomingCall(with: callUUID, update: update) { [weak self] error in

            // ✅✅✅ الأهم: استدعاء completion() كأول شيء في الـ callback
            completion()

            // ============================================================
            // الآن ننفذ العمليات الثقيلة (لأن iOS أصبح راضياً)
            // ============================================================
            DispatchQueue.main.async {
                guard let self = self else { return }

                // 1. تسجيل الاستلام
                self.pushKitReceivedCount += 1
                self.lastPushKitPayload = dict
                self.writeLog("🔥 استلام VoIP Push #\(self.pushKitReceivedCount) (UUID: \(callUUID))")
                self.writeLog("✅ تم استدعاء completion() - iOS راضٍ")

                // 2. معالجة الخطأ إن وُجد
                if let error = error {
                    self.lastError = error.localizedDescription
                    self.writeLog("❌ فشل الإبلاغ عن المكالمة: \(error.localizedDescription)")
                    return
                }

                // 3. نجاح الإبلاغ
                self.callKitShownCount += 1
                self.writeLog("✅ تم الإبلاغ بنجاح - CallKit يظهر الآن")

                // 4. معالجة البيانات الكاملة
                var avatar = (dict["avatar"] as? String)
                          ?? (dict["driver_image"] as? String)
                          ?? (dict["caller_image"] as? String)
                          ?? ""

                if avatar.hasPrefix("http://") {
                    avatar = avatar.replacingOccurrences(of: "http://", with: "https://")
                }

                var extraDict: [String: Any] = (dict["extra"] as? [String: Any]) ?? dict
                extraDict["id"] = callUUID.uuidString
                extraDict["nameCaller"] = callerName
                extraDict["handle"] = handle
                extraDict["avatar"] = avatar
                extraDict["room_name"] = (dict["room_name"] as? String) ?? ""
                extraDict["livekit_url"] = (dict["livekit_url"] as? String) ?? "wss://call.beytei.com"
                extraDict["token"] = (dict["token"] as? String) ?? ""
                extraDict["order_id"] = (dict["order_id"] as? String) ?? ""

                // 5. حفظ البيانات
                self.activeCallMap[callUUID] = extraDict
                UserDefaults.standard.set(extraDict, forKey: "call_\(callUUID.uuidString)")

                // 6. إعلام Flutter
                self.notifyFlutterIncomingCall(data: extraDict)
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

// ===========================================================================
// 📞 CXProvider Delegate - للتعامل مع أحداث CallKit (قبول/رفض/إنهاء)
// ===========================================================================
extension AppDelegate: CXProviderDelegate {

    func providerDidReset(_ provider: CXProvider) {
        writeLog("🔄 تم إعادة تعيين CXProvider")
        activeCallMap.removeAll()
    }

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        writeLog("✅ المستخدم قَبِل المكالمة: \(action.callUUID)")

        if let data = activeCallMap[action.callUUID] {
            notifyFlutterCallAccepted(data: data)
        }

        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        writeLog("❌ المستخدم رفض/أنهى المكالمة: \(action.callUUID)")

        if let data = activeCallMap[action.callUUID] {
            notifyFlutterCallEnded(data: data)
        }

        activeCallMap.removeValue(forKey: action.callUUID)
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        action.fulfill()
    }

    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        writeLog("🎤 تم تفعيل جلسة الصوت")

        do {
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .defaultToSpeaker])
            try audioSession.setActive(true)
        } catch {
            writeLog("❌ فشل تفعيل الصوت: \(error.localizedDescription)")
        }
    }

    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        writeLog("🔇 تم إيقاف جلسة الصوت")
    }
}