import UIKit
import Flutter
import Firebase
import FirebaseMessaging
import PushKit
import flutter_callkit_incoming
import CallKit

@main
@objc class AppDelegate: FlutterAppDelegate {

    private var voipRegistry: PKPushRegistry?

    private lazy var callKitProvider: CXProvider = {
        let config = CXProviderConfiguration(localizedName: "منصة بيتي")
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
        if logs.count > 100 { logs.removeFirst() }
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

        // استعادة توكن VoIP إلى المكتبة إن وُجد
        if let storedToken = UserDefaults.standard.string(forKey: "flutter.voip_token"),
           !storedToken.isEmpty {
            SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP(storedToken)
            writeLog("🔁 تم استعادة توكن VoIP إلى flutter_callkit_incoming")
        }

        // تجهيز Native CallKit Provider
        _ = callKitProvider
        writeLog("🧠 تم تجهيز Native CXProvider")

        // تجهيز PushKit
        let registry = PKPushRegistry(queue: .main)
        registry.delegate = self
        registry.desiredPushTypes = [.voIP]
        self.voipRegistry = registry

        writeLog("🚀 تم تشغيل PushKit + Native CallKit fallback")

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

    // MARK: - Native CallKit Helpers

    private func reportNativeIncomingCall(
        uuidString: String,
        callerName: String,
        handle: String,
        payload: [String: Any],
        pushCompletion: @escaping () -> Void
    ) {
        let callUUID = UUID(uuidString: uuidString) ?? UUID()

        pendingPayloadByUUID[callUUID] = payload
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

        if let controller = window?.rootViewController as? FlutterViewController {
            let channel = FlutterMethodChannel(
                name: "beytei_native_call",
                binaryMessenger: controller.binaryMessenger
            )

            channel.invokeMethod("onCallEvent", arguments: [
                "event": event,
                "payload": payload
            ])
        } else {
            // إذا لم يكن Flutter جاهزًا، احفظه ليقرأه التطبيق عند الإقلاع
            if let data = try? JSONSerialization.data(withJSONObject: payload),
               let jsonString = String(data: data, encoding: .utf8) {
                UserDefaults.standard.set(jsonString, forKey: "pending_native_call_payload")
                UserDefaults.standard.set(event, forKey: "pending_native_call_event")
                writeLog("💾 تم حفظ حدث المكالمة مؤقتًا في UserDefaults")
            }
        }
    }

    private func endNativeCallIfNeeded(uuidString: String) {
        guard let callUUID = UUID(uuidString: uuidString) else { return }

        if activeCallUUIDs.contains(callUUID) {
            callKitProvider.endCall(with: callUUID)
            activeCallUUIDs.remove(callUUID)
            pendingPayloadByUUID.removeValue(forKey: callUUID)
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

        let deviceToken = credentials.token.map { String(format: "%02.2hhx", $0) }.joined()
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
        writeLog("🔥🔥🔥 وصل إشعار VoIP إلى AppDelegate")

        guard type == .voIP else {
            completion()
            return
        }

        pushKitReceivedCount += 1

        let dict = payload.dictionaryPayload as? [String: Any] ?? [:]
        lastPushKitPayload = dict
        writeLog("⬇️ Payload: \(dict)")

        let rawId = (dict["id"] as? String) ?? (dict["order_id"] as? String) ?? ""
        let validUUID = UUID(uuidString: rawId)?.uuidString ?? UUID().uuidString

        let typeValue = dict["type"]
        let isCancel =
            (typeValue as? String == "cancel_call") ||
            (typeValue as? Int == 1) ||
            (typeValue as? String == "1")

        // ⚠️ الأفضل عدم إرسال cancel عبر VoIP Push أصلًا.
        // إذا وصلك cancel، أنهِ المكالمة إن كانت نشطة فقط.
        if isCancel {
            writeLog("🚫 طلب إلغاء مكالمة عبر VoIP Push")
            endNativeCallIfNeeded(uuidString: validUUID)

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
        pendingPayloadByUUID.removeAll()
    }

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        writeLog("✅ المستخدم رد على المكالمة Native")
        action.fulfill()

        if let payload = pendingPayloadByUUID[action.call.uuid] {
            deliverCallEventToFlutter(payload: payload, event: "accept")
        } else {
            deliverCallEventToFlutter(payload: [:], event: "accept")
        }
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        writeLog("⛔ تم إنهاء المكالمة Native")
        action.fulfill()

        activeCallUUIDs.remove(action.call.uuid)
        pendingPayloadByUUID.removeValue(forKey: action.call.uuid)

        deliverCallEventToFlutter(payload: [:], event: "end")
    }

    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        action.fulfill()
    }
}