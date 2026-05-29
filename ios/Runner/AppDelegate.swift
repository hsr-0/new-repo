import UIKit
import Flutter
import Firebase
import FirebaseMessaging
import PushKit
import flutter_callkit_incoming
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {

    var voipRegistry: PKPushRegistry?

    // =======================================================================
    // 🔥 دالة تسجيل السجلات (للتشخيص)
    // =======================================================================
    func writeLog(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let timeString = formatter.string(from: Date())
        let logMessage = "[\(timeString)] 🍏 \(message)"
        var logs = UserDefaults.standard.stringArray(forKey: "ios_debug_logs") ?? []
        logs.append(logMessage)
        if logs.count > 30 { logs.removeFirst() }
        UserDefaults.standard.set(logs, forKey: "ios_debug_logs")
    }

    // =======================================================================
    // 🔥 تهيئة التطبيق
    // =======================================================================
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        // 1. تهيئة فايربيس
        FirebaseApp.configure()

        // 2. تسجيل البلجنز
        GeneratedPluginRegistrant.register(with: self)

        // 3. قناة التصحيح (Debug Channel)
        if let controller = window?.rootViewController as? FlutterViewController {
            let debugChannel = FlutterMethodChannel(
                name: "beytei_deep_debugger",
                binaryMessenger: controller.binaryMessenger
            )
            debugChannel.setMethodCallHandler { [weak self] (call, result) in
                if call.method == "getLogs" {
                    let logs = UserDefaults.standard.stringArray(forKey: "ios_debug_logs") ?? []
                    let token = UserDefaults.standard.string(forKey: "flutter.voip_token") ?? "لا يوجد توكن"
                    result(["logs": logs.joined(separator: "\n\n"), "token": token])
                } else {
                    result(FlutterMethodNotImplemented)
                }
            }
        }

        // 4. تهيئة إشعارات المستخدم (للإشعارات العادية)
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
        }
        application.registerForRemoteNotifications()

        // 5. تهيئة إشعارات فايربيس
        Messaging.messaging().delegate = self

        // 6. تهيئة PushKit للمكالمات (VoIP) - هذا الجزء يعمل ولا نلمسه
        voipRegistry = PKPushRegistry(queue: .main)
        voipRegistry?.delegate = self
        voipRegistry?.desiredPushTypes = [.voIP]

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // =======================================================================
    // 🔥 معالجة فتح التطبيق من إشعار (عندما يكون التطبيق مغلقاً)
    // =======================================================================
    override func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        writeLog("🔔 Received remote notification: \(userInfo)")

        // تمرير البيانات لـ فلاتر عبر قناة الحدث
        if let controller = window?.rootViewController as? FlutterViewController {
            let channel = FlutterMethodChannel(
                name: "firebase_messaging",
                binaryMessenger: controller.binaryMessenger
            )
            channel.invokeMethod("onMessageOpenedApp", arguments: userInfo)
        }

        completionHandler(.newData)
    }
}

// =======================================================================
// 🔥 معالجة إشعارات فايربيس العادية (FCM) - UNUserNotificationCenterDelegate
// =======================================================================
extension AppDelegate: UNUserNotificationCenterDelegate {

    // عند استلام إشعار والتطبيق في المقدمة
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        writeLog("🔔 FCM Foreground: \(userInfo)")

        // تمرير البيانات لـ فلاتر
        if let controller = window?.rootViewController as? FlutterViewController {
            let channel = FlutterMethodChannel(
                name: "firebase_messaging",
                binaryMessenger: controller.binaryMessenger
            )
            channel.invokeMethod("onMessage", arguments: userInfo)
        }

        // إظهار الإشعار حتى لو كان التطبيق في المقدمة
        completionHandler([.banner, .sound, .badge])
    }

    // عند الضغط على الإشعار
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        writeLog("🔔 FCM Tapped: \(userInfo)")

        // تمرير البيانات لـ فلاتر
        if let controller = window?.rootViewController as? FlutterViewController {
            let channel = FlutterMethodChannel(
                name: "firebase_messaging",
                binaryMessenger: controller.binaryMessenger
            )
            channel.invokeMethod("onMessageOpenedApp", arguments: userInfo)
        }

        completionHandler()
    }
}

// =======================================================================
// 🔥 معالجة تحديث توكن فايربيس - MessagingDelegate
// =======================================================================
extension AppDelegate: MessagingDelegate {

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken, !token.isEmpty else { return }
        writeLog("🔄 FCM Token refreshed: \(token.prefix(20))...")

        // حفظ التوكن محلياً
        UserDefaults.standard.set(token, forKey: "flutter.fcm_token")

        // تمرير التوكن لـ فلاتر
        if let controller = window?.rootViewController as? FlutterViewController {
            let channel = FlutterMethodChannel(
                name: "firebase_messaging",
                binaryMessenger: controller.binaryMessenger
            )
            channel.invokeMethod("onTokenRefresh", arguments: token)
        }
    }
}

// =======================================================================
// 🔥 معالجة مكالمات VoIP عبر PushKit - PKPushRegistryDelegate
// =======================================================================
extension AppDelegate: PKPushRegistryDelegate {

    // عند تحديث توكن المكالمات (VoIP)
    func pushRegistry(_ registry: PKPushRegistry,
                      didUpdate credentials: PKPushCredentials,
                      for type: PKPushType) {

        let tokenHex = credentials.token.map { String(format: "%02.2hhx", $0) }.joined()
        UserDefaults.standard.set(tokenHex, forKey: "flutter.voip_token")
        writeLog("✅ تم حفظ توكن المكالمات VoIP: \(tokenHex.prefix(20))...")

        // تمرير التوكن لـ فلاتر
        if let controller = window?.rootViewController as? FlutterViewController {
            let channel = FlutterMethodChannel(
                name: "firebase_messaging",
                binaryMessenger: controller.binaryMessenger
            )
            channel.invokeMethod("onVoIPToken", arguments: tokenHex)
        }
    }

    // 🔥 عند استلام مكالمة VoIP جديدة (هنا الحل الجذري للكراش)
    func pushRegistry(_ registry: PKPushRegistry,
                      didReceiveIncomingPushWith payload: PKPushPayload,
                      for type: PKPushType,
                      withCompletionHandler completion: @escaping () -> Void) {

        writeLog("⚠️ تم استلام مكالمة عبر VoIP")

        // 🔥 1. التأكد أن هذا إشعار مكالمة فقط (ليس عروض أو إشعار عادي)
        guard let dict = payload.dictionaryPayload as? [String: Any],
              let callType = dict["type"] as? String,
              callType == "voip_call" else {

            // ❌ إذا لم يكن مكالمة، نخرج فوراً دون معالجة
            writeLog("⚠️ Ignored non-VoIP push: \(payload.dictionaryPayload)")
            completion()
            return
        }

        writeLog("✅ Processing VoIP call: \(dict)")

        // 🔥 2. تنظيف البيانات قبل الاستخدام (يمنع كراش `-[__NSCFString count]`)
        func sanitizeValue(_ value: Any?) -> Any? {
            switch value {
            case let str as String: return str
            case let num as NSNumber: return num
            case let bool as Bool: return bool
            case let arr as [Any]:
                return arr.compactMap { sanitizeValue($0) }
            case let dic as [String: Any]:
                return dic.compactMapValues { sanitizeValue($0) }
            case nil: return nil
            default: return String(describing: value) // تحويل أي نوع غريب لنص
            }
        }

        let cleanedDict = dict.compactMapValues { sanitizeValue($0) }

        let callerName = cleanedDict["driver_name"] as? String ?? "الكابتن"
        let orderId = cleanedDict["order_id"] as? String ?? ""
        let validCallKitId = UUID().uuidString

        let callkitData: [String: Any] = [
            "id": validCallKitId,           // 👈 UUID حقيقي (مطلوب من آبل)
            "nameCaller": callerName,
            "appName": "منصة بيتي",
            "handle": "طلب رقم \(orderId)",
            "type": 0,
            "duration": 30000,
            "textAccept": "رد",
            "textDecline": "رفض",
            "extra": cleanedDict            // 👈 البيانات المنظفة فقط
        ]

        let data = flutter_callkit_incoming.Data(args: callkitData)

        if let plugin = SwiftFlutterCallkitIncomingPlugin.sharedInstance {
            plugin.showCallkitIncoming(data, fromPushKit: true)
            writeLog("✅ CallKit displayed successfully")
        } else {
            writeLog("❌ flutter_callkit_incoming plugin not ready")
        }

        completion()
    }

    // دالة الإصدارات القديمة (للتوافق مع iOS 13 وما قبل)
    func pushRegistry(_ registry: PKPushRegistry,
                      didReceiveRemoteNotificationPayload payload: PKPushPayload,
                      for type: PKPushType) {
        // لا تفعل شيئاً - هذه الدالة لم تعد تُستخدم في iOS 14+
        writeLog("⚠️ Received legacy VoIP payload (ignored)")
    }

    func pushRegistry(_ registry: PKPushRegistry,
                      didInvalidatePushTokenFor type: PKPushType) {
        writeLog("⚠️ VoIP token invalidated")
        UserDefaults.standard.removeObject(forKey: "flutter.voip_token")
    }
}