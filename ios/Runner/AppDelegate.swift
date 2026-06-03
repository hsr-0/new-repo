import UIKit
import Flutter
import Firebase
import PushKit
import CallKit // 🔥 مهم جداً لدرع الحماية
import flutter_callkit_incoming

@main
@objc class AppDelegate: FlutterAppDelegate, PKPushRegistryDelegate, CXProviderDelegate {

    var voipRegistry: PKPushRegistry?
    var backupProvider: CXProvider? // 🛡️ درع الحماية للآيفون

    func writeLog(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        let timeString = formatter.string(from: Date())
        let logMessage = "[\(timeString)] 🍏 \(message)"
        var logs = UserDefaults.standard.stringArray(forKey: "ios_debug_logs") ?? []
        logs.append(logMessage)
        if logs.count > 50 { logs.removeFirst() }
        UserDefaults.standard.set(logs, forKey: "ios_debug_logs")
    }

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        FirebaseApp.configure()
        GeneratedPluginRegistrant.register(with: self)

        // 🛡️ تهيئة درع الحماية الأصلي (CXProvider) لمنع الكراش في حالة إغلاق التطبيق تماماً
        let providerConfig = CXProviderConfiguration(localizedName: "مطاعم بيتي")
        providerConfig.supportsVideo = false
        providerConfig.maximumCallsPerCallGroup = 1
        providerConfig.supportedHandleTypes = [.generic]
        self.backupProvider = CXProvider(configuration: providerConfig)
        self.backupProvider?.setDelegate(self, queue: nil)

        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let debugChannel = FlutterMethodChannel(name: "beytei_deep_debugger", binaryMessenger: controller.binaryMessenger)
        debugChannel.setMethodCallHandler({ [weak self] (call, result) in
            if call.method == "getLogs" {
                let logs = UserDefaults.standard.stringArray(forKey: "ios_debug_logs") ?? []
                let token = UserDefaults.standard.string(forKey: "flutter.voip_token") ?? "لا يوجد توكن"
                result(["logs": logs.joined(separator: "\n\n"), "token": token])
            }
        })

        self.voipRegistry = PKPushRegistry(queue: .main)
        self.voipRegistry?.delegate = self
        self.voipRegistry?.desiredPushTypes = [.voIP]

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // دوال PushKit الإلزامية
    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        let tokenHex = credentials.token.map { String(format: "%02.2hhx", $0) }.joined()
        UserDefaults.standard.set(tokenHex, forKey: "flutter.voip_token")
        writeLog("✅ تم حفظ توكن VoIP بنجاح")
    }

    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, withCompletionHandler completion: @escaping () -> Void) {

        writeLog("⚠️ استلام إشعار مكالمة (VoIP)")

        let dict = payload.dictionaryPayload as? [String: Any] ?? [:]
        let callerName = dict["driver_name"] as? String ?? "الكابتن"
        let orderId = dict["order_id"] as? String ?? "0"
        let validCallKitId = UUID()

        if let plugin = SwiftFlutterCallkitIncomingPlugin.sharedInstance {
            // إذا كان محرك Flutter مستيقظاً، نعطيه المهمة
            let callkitData: [String: Any] = [
                "id": validCallKitId.uuidString,
                "nameCaller": callerName,
                "appName": "مطاعم بيتي",
                "handle": "طلب رقم \(orderId)",
                "type": 0,
                "duration": 30000,
                "extra": dict
            ]
            let data = flutter_callkit_incoming.Data(args: callkitData)
            plugin.showCallkitIncoming(data, fromPushKit: true)
            writeLog("✅ الشاشة رنت عبر مكتبة فلاتر.")
        } else {
            // 🛡️ درع الحماية يتدخل فوراً: محرك Flutter لا يزال نائماً أو يحمل، نرن الشاشة نحن لمنع الكراش!
            writeLog("🛡️ تدخل درع الحماية السريع لمنع الكراش!")
            let update = CXCallUpdate()
            update.remoteHandle = CXHandle(type: .generic, value: callerName)
            update.hasVideo = false
            update.localizedCallerName = callerName

            self.backupProvider?.reportNewIncomingCall(with: validCallKitId, update: update) { error in
                if let error = error {
                    self.writeLog("❌ فشل درع الحماية: \(error.localizedDescription)")
                } else {
                    self.writeLog("✅ الشاشة رنت بنجاح عبر درع الحماية.")
                }
            }
        }

        // ⚠️ السر هنا: يجب استدعاء الدالة فوراً وبدون أي تأخير زمني (Delay) لإرضاء آبل!
        completion()
    }

    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {}

    // دالة إلزامية لدرع الحماية (CXProviderDelegate)
    func providerDidReset(_ provider: CXProvider) {}
}