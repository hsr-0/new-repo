import UIKit
import Flutter
import Firebase
import PushKit
import CallKit          // ✅ ضروري لـ CXProviderDelegate
import AVFoundation     // ✅ ضروري لـ AVAudioSession
import flutter_callkit_incoming

@main
@objc class AppDelegate: FlutterAppDelegate {

    var voipRegistry: PKPushRegistry?
    var callKitProvider: CXProvider?
    var callKitCallController: CXCallController?

    // متغير لتتبع حالة المكالمة الحالية
    private var currentCallUUID: UUID?

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

        // إعداد CallKit Provider
        let configuration = CXProviderConfiguration(localizedName: "منصة بيتي")
        configuration.maximumCallGroups = 2
        configuration.maximumCallsPerCallGroup = 1
        configuration.supportsVideo = false
        configuration.supportedHandleTypes = [.generic, .phoneNumber]

        self.callKitProvider = CXProvider(configuration: configuration)
        self.callKitProvider?.setDelegate(self, queue: nil)
        self.callKitCallController = CXCallController()

        // إعداد Flutter Method Channel للتشخيص
        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
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

        // إرسال التوكن للسيرفر
        sendTokenToServer(voipToken: tokenHex)
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

        if messageType == "cancel_call" {
            writeLog("🚫 تم استلام أمر إلغاء المكالمة")

            if let uuid = currentCallUUID {
                callKitProvider?.reportCall(with: uuid, endedAt: Date(), reason: .remoteEnded)
            }

            if let plugin = SwiftFlutterCallkitIncomingPlugin.sharedInstance {
                plugin.endAllCalls()
            }

            completion()
            return
        }

        // معالجة مكالمة جديدة
        if messageType == "voip_call" {
            writeLog("📞 مكالمة جديدة واردة!")

            let callerName = dict["name"] as? String ?? (dict["driver_name"] as? String ?? "الكابتن")
            let handle = dict["handle"] as? String ?? (dict["driver_phone"] as? String ?? "")

            let callUUID = UUID()
            currentCallUUID = callUUID

            let update = CXCallUpdate()
            update.remoteHandle = CXHandle(type: .generic, value: handle)
            update.localizedCallerName = callerName
            update.hasVideo = false

            writeLog("🔔 إبلاغ CallKit بالمكالمة: \(callerName)")

            callKitProvider?.reportNewIncomingCall(with: callUUID, update: update) { [weak self] error in
                if let error = error {
                    self?.writeLog("❌ فشل إبلاغ CallKit: \(error.localizedDescription)")
                } else {
                    self?.writeLog("✅ تم إبلاغ CallKit بنجاح")
                    self?.passDataToFlutter(callUUID: callUUID, callerName: callerName, handle: handle, dict: dict)
                }
            }
        }

        completion()
    }

    func passDataToFlutter(callUUID: UUID, callerName: String, handle: String, dict: [String: Any]) {
        let callkitData: [String: Any] = [
            "id": callUUID.uuidString,
            "nameCaller": callerName,
            "appName": "منصة بيتي",
            "handle": handle,
            "avatar": dict["avatar"] as? String ?? "",
            "type": 0,
            "duration": dict["duration"] as? Int ?? 60000,
            "extra": dict["extra"] as? [String: Any] ?? dict
        ]

        let data = flutter_callkit_incoming.Data(args: callkitData)

        if let plugin = SwiftFlutterCallkitIncomingPlugin.sharedInstance {
            plugin.showCallkitIncoming(data, fromPushKit: true)
            writeLog("✅ تم عرض شاشة المكالمة")
        }
    }

    // إبطال التوكن
    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        guard type == .voIP else { return }
        writeLog("❌ تم إبطال توكن VoIP")
        UserDefaults.standard.removeObject(forKey: "flutter.voip_token")
    }

    // إرسال التوكن للسيرفر
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
            }
        }.resume()
    }
}

// =======================================================================
// CXProvider Delegate (معالجة أحداث المكالمة)
// =======================================================================
extension AppDelegate: CXProviderDelegate {

    // النظام يطلب بدء المكالمة
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        writeLog("📞 بدء المكالمة: \(action.callUUID)")
        action.fulfill()
    }

    // المستخدم رد على المكالمة
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        writeLog("✅ المستخدم رد على المكالمة: \(action.callUUID)")
        action.fulfill()
    }

    // المستخدم أنهى المكالمة
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        writeLog("❌ المستخدم أنهى المكالمة: \(action.callUUID)")
        currentCallUUID = nil
        action.fulfill()
    }

    // النظام يطلب تفعيل الصوت
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        writeLog("🔊 تم تفعيل جلسة الصوت")
    }

    // النظام يطلب إلغاء جلسة الصوت
    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        writeLog("🔇 تم إلغاء جلسة الصوت")
    }
}