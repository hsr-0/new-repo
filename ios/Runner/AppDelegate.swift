import UIKit
import Flutter
import Firebase
import PushKit
import flutter_callkit_incoming

@main
@objc class AppDelegate: FlutterAppDelegate {

    var voipRegistry: PKPushRegistry?
    var backgroundEngine: FlutterEngine?

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
        if logs.count > 50 { logs.removeFirst() }
        UserDefaults.standard.set(logs, forKey: "ios_debug_logs")
        print(logMessage)
    }

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        FirebaseApp.configure()
        GeneratedPluginRegistrant.register(with: self)

        // قناة فلاتر لقراءة السجلات (للفحص)
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

    override func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable : Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        // السماح لـ FCM بمعالجة الإشعار في الخلفية
        completionHandler(.newData)
    }
}

// =======================================================================
// VoIP Push Registry Delegate - نظام الاتصال واستلام الإشعارات
// =======================================================================
extension AppDelegate: PKPushRegistryDelegate {

    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        guard type == .voIP else { return }

        let deviceToken = credentials.token.map { String(format: "%02.2hhx", $0) }.joined()
        UserDefaults.standard.set(deviceToken, forKey: "flutter.voip_token")

        // إرسال التوكن لمكتبة فلاتر
        SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP(deviceToken)
        writeLog("🔑 تم استلام توكن آبل VoIP بنجاح: \(deviceToken.prefix(15))...")
    }

    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, withCompletionHandler completion: @escaping () -> Void) {

        // ⚠️ هام جداً: يجب استدعاء completion دائماً عند الخروج المبكر
        guard type == .voIP else {
            completion()
            return
        }

        writeLog("⬇️ استلمت آيفون إشعار VoIP جديد من السيرفر")

        // تشغيل محرك الخلفية إذا كان التطبيق مغلقاً تماماً (Cold Start)
        if self.window?.rootViewController as? FlutterViewController == nil {
            writeLog("⚙️ التطبيق مغلق، جاري تشغيل محرك الخلفية")
            let engine = FlutterEngine(name: "VoIPBackgroundEngine")
            engine.run(withEntrypoint: nil)
            GeneratedPluginRegistrant.register(with: engine)
            self.backgroundEngine = engine
        }

        let dict = payload.dictionaryPayload as? [String: Any] ?? [:]
        let isCancel = (dict["type"] as? String == "cancel_call") || (dict["type"] as? Int == 1)

        // استخراج البيانات بأمان
        let rawId = (dict["id"] as? String) ?? (dict["order_id"] as? String) ?? ""
        // محاولة استخدام الـ UUID القادم من السيرفر، وإذا فشل نولد واحداً جديداً
        let validUUID = UUID(uuidString: rawId)?.uuidString ?? UUID().uuidString

        let callerName = (dict["name"] as? String) ?? (dict["driver_name"] as? String) ?? "مندوب بيتي"
        let handle = (dict["handle"] as? String) ?? (dict["driver_phone"] as? String) ?? "مكالمة واردة"
        let duration = dict["duration"] as? Int ?? 60000

        // 🔥 الحل الجذري لخطأ Xcode: تحويل القاموس صراحةً إلى NSDictionary
        let rawExtra = dict["extra"] as? [String: Any] ?? dict
        let extraDict = rawExtra as NSDictionary

        var avatar = dict["avatar"] as? String ?? dict["driver_image"] as? String ?? ""
        if avatar.hasPrefix("http://") {
            avatar = avatar.replacingOccurrences(of: "http://", with: "https://")
        }

        // تهيئة بيانات المكالمة وفقاً لـ v3.1.3
        let callData = flutter_callkit_incoming.Data(id: validUUID, nameCaller: callerName, handle: handle, type: 0)
        callData.appName = "منصة بيتي"
        callData.avatar = avatar
        callData.duration = duration
        callData.extra = extraDict // الآن النوع متطابق تماماً مع متطلبات المكتبة

        if isCancel {
            // ✅ التعديل الحاسم: إلغاء المكالمة دون إظهارها أولاً لمنع الوميض/التعطل
            writeLog("🚫 معالجة طلب إلغاء المكالمة (UUID: \(validUUID))")
            SwiftFlutterCallkitIncomingPlugin.sharedInstance?.endCall(callData)
            completion() // إنهاء المعالجة فوراً
            return
        } else {
            // عرض شاشة المكالمة
            writeLog("🔔 جاري إرسال أمر الرنين لمكتبة فلاتر! (UUID: \(validUUID))")
            SwiftFlutterCallkitIncomingPlugin.sharedInstance?.showCallkitIncoming(callData, fromPushKit: true)

            // ✅ التعديل الحاسم: استدعاء completion على الـ Main Thread لضمان استقرار آبل
            DispatchQueue.main.async {
                completion()
            }
        }
    }

    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        guard type == .voIP else { return }
        UserDefaults.standard.removeObject(forKey: "flutter.voip_token")
        SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP("")
        writeLog("⚠️ تم إبطال التوكن من قبل نظام آبل")
    }
}
