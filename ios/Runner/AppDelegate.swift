import UIKit
import Flutter
import Firebase
import PushKit
import flutter_callkit_incoming

@main
@objc class AppDelegate: FlutterAppDelegate {

    var voipRegistry: PKPushRegistry?
    // 🔥 الاحتفاظ بمحرك الخلفية لمنعه من التدمير من الذاكرة
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
        completionHandler(.newData)
    }
}

// =======================================================================
// VoIP Push Registry Delegate - نظام الاتصال واستلام الإشعارات
// =======================================================================
extension AppDelegate: PKPushRegistryDelegate {

    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        guard type == .voIP else { return }
        let tokenHex = credentials.token.map { String(format: "%02.2hhx", $0) }.joined()
        UserDefaults.standard.set(tokenHex, forKey: "flutter.voip_token")
        writeLog("🔑 تم استلام توكن آبل بنجاح: \(tokenHex.prefix(15))...")
    }

    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, withCompletionHandler completion: @escaping () -> Void) {

        guard type == .voIP else {
            completion()
            return
        }

        writeLog("⬇️ استلمت آيفون إشعار VoIP جديد من السيرفر")

        // 🔥 التأكد من تشغيل محرك فلاتر في الخلفية إذا كان التطبيق مغلقاً (Killed State)
        if self.window?.rootViewController as? FlutterViewController == nil {
            writeLog("⚙️ التطبيق مغلق، جاري تشغيل محرك الخلفية")
            let engine = FlutterEngine(name: "VoIPBackgroundEngine")
            engine.run(withEntrypoint: nil)
            GeneratedPluginRegistrant.register(with: engine)
            self.backgroundEngine = engine // حفظه في الذاكرة لمنع تدميره
        }

        // جلب مثيل الإضافة بأمان
        guard let callkitPlugin = SwiftFlutterCallkitIncomingPlugin.sharedInstance else {
            writeLog("❌ خطأ: لم يتم العثور على إضافة CallKit")
            completion()
            return
        }

        // دالة الطوارئ المضمونة 100% لإرضاء آبل
        func reportFakeCallToSatisfyApple(reason: String) {
            writeLog("⚠️ تفعيل خطة الطوارئ بسبب: \(reason)")
            let fakeUUID = UUID().uuidString
            let fakeData: [String: Any] = ["id": fakeUUID, "nameCaller": "مكالمة واردة", "appName": "منصة بيتي", "type": 0]

            // ✅ تم إزالة messenger من هنا لتجنب خطأ الكومبايلر
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

        let isCancel = (dict["type"] as? String == "cancel_call") || (dict["type"] as? Int == 1)

        // ===========================================================
        // 🔥 التعديل الجذري لمنع الـ Crash (0xbaadca11)
        // ===========================================================

        // 1. توليد UUID عشوائي وجديد 100% دائماً لكي تقبله آبل دون مشاكل
        let validUUID = UUID().uuidString

        // 2. الاحتفاظ برقم الطلب الحقيقي القادم من السيرفر
        let realServerId = dict["id"] as? String ?? dict["order_id"] as? String ?? ""

        let callerName = dict["name"] as? String ?? dict["driver_name"] as? String ?? "مندوب بيتي"
        let handle = dict["handle"] as? String ?? dict["driver_phone"] as? String ?? "مكالمة واردة"
        let duration = dict["duration"] as? Int ?? 60000

        // 3. تمرير رقم الطلب الحقيقي داخل الـ extra لكي نقرأه من دارت
        var extra = dict["extra"] as? [String: Any] ?? dict
        extra["real_order_id"] = realServerId

        var avatar = dict["avatar"] as? String ?? dict["driver_image"] as? String ?? ""
        if avatar.hasPrefix("http://") {
            avatar = avatar.replacingOccurrences(of: "http://", with: "https://")
            writeLog("تم تعديل رابط الصورة إلى HTTPS")
        }

        let callkitData: [String: Any] = [
            "id": validUUID, // إرسال المعرف العشوائي فقط لـ CallKit
            "nameCaller": callerName,
            "appName": "منصة بيتي",
            "handle": handle,
            "avatar": avatar,
            "type": 0,
            "duration": duration,
            "extra": extra // الـ extra يحتوي الآن على رقم الطلب الحقيقي
        ]

        do {
            // ✅ تم إزالة messenger من هنا لتجنب خطأ الكومبايلر
            let data = try flutter_callkit_incoming.Data(args: callkitData)

            if isCancel {
                callkitPlugin.showCallkitIncoming(data, fromPushKit: true)
                callkitPlugin.endCall(data)
                writeLog("🚫 تم معالجة طلب إلغاء المكالمة بنجاح")
            } else {
                callkitPlugin.showCallkitIncoming(data, fromPushKit: true)
                writeLog("🔔 تم عرض شاشة الاتصال بنجاح! (UUID: \(validUUID))")
            }
            completion() // يجب استدعاؤها في النهاية لترضي النظام

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