import UIKit
import Flutter
import Firebase
import PushKit
import flutter_callkit_incoming

@main
@objc class AppDelegate: FlutterAppDelegate {

    var voipRegistry: PKPushRegistry?

    // 📝 دالة لكتابة السجلات داخل ذاكرة الهاتف لكي لا تضيع إذا حدث كراش
    func writeLog(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let timeString = formatter.string(from: Date())
        let logMessage = "[\(timeString)] 🍏 \(message)"

        var logs = UserDefaults.standard.stringArray(forKey: "ios_debug_logs") ?? []
        logs.append(logMessage)
        // نحتفظ بآخر 30 رسالة فقط
        if logs.count > 30 { logs.removeFirst() }
        UserDefaults.standard.set(logs, forKey: "ios_debug_logs")
    }

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        FirebaseApp.configure()
        GeneratedPluginRegistrant.register(with: self)

        // 1. مسح السجلات القديمة عند فتح التطبيق
        UserDefaults.standard.set([], forKey: "ios_debug_logs")
        writeLog("بدء تشغيل التطبيق وتسجيل PushKit...")

        // 2. إعداد قناة الاتصال مع Flutter لإرسال السجلات للزر العائم
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
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

        // 3. تفعيل VoIP
        self.voipRegistry = PKPushRegistry(queue: .main)
        self.voipRegistry?.delegate = self
        self.voipRegistry?.desiredPushTypes = [.voIP]

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}

extension AppDelegate: PKPushRegistryDelegate {

    // ✅ استلام توكن المكالمات
    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        let tokenHex = credentials.token.map { String(format: "%02.2hhx", $0) }.joined()
        writeLog("تم استلام VoIP Token بنجاح طوله \(tokenHex.count) حرف")

        // حفظه ليقرأه فلاتر
        UserDefaults.standard.set(tokenHex, forKey: "flutter.voip_token")
    }

    // 📞 استلام الرنة (هنا يحدث الكراش عادة)
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {

        writeLog("⚠️ إنذار: تم استلام إشعار مكالمة (VoIP Push) في الخلفية!")

        if let dict = payload.dictionaryPayload as? [String: Any] {
            writeLog("📦 البيانات المستلمة: \(dict.keys)")
        }

        // محاولة تشغيل CallKit
        if let pluginDelegate = SwiftFlutterCallkitIncomingPlugin.sharedInstance as? PKPushRegistryDelegate {
            writeLog("⚡ جاري تمرير المكالمة لمكتبة CallKit لترن الشاشة...")

            // تمرير الإشعار للمكتبة
            pluginDelegate.pushRegistry?(registry, didReceiveIncomingPushWith: payload, for: type, completion: {
                self.writeLog("✅ مكتبة CallKit أبلغت iOS بنجاح إظهار شاشة الاتصال.")
                completion()
            })
        } else {
            writeLog("❌ خطأ قاتل: لم يتم العثور على مكتبة CallKit، سيتم إجهاض المكالمة لتجنب الحظر.")
            completion()
        }
    }

    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        writeLog("🚫 قامت Apple بإبطال التوكن (Invalidated). غالباً بسبب فشل إظهار شاشة الاتصال سابقاً.")
    }
}