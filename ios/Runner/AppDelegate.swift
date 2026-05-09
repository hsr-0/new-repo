import UIKit
import Flutter
import Firebase
import PushKit
import flutter_callkit_incoming // 👈 استدعاء المكتبة بشكل صريح

@main
@objc class AppDelegate: FlutterAppDelegate {

    var voipRegistry: PKPushRegistry?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        FirebaseApp.configure()
        GeneratedPluginRegistrant.register(with: self)

        // تفعيل استقبال مكالمات VoIP
        self.voipRegistry = PKPushRegistry(queue: .main)
        self.voipRegistry?.delegate = self
        self.voipRegistry?.desiredPushTypes = [.voIP]

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}

extension AppDelegate: PKPushRegistryDelegate {

    // 1. استلام وحفظ توكن الآيفون
    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        let tokenHex = credentials.token.map { String(format: "%02.2hhx", $0) }.joined()
        UserDefaults.standard.set(tokenHex, forKey: "flutter.voip_token")
    }

    // 2. ⚡ لحظة استلام الرنة في الخلفية (هنا الحل)
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {

        if let dict = payload.dictionaryPayload as? [String: Any] {

            // أ. استخراج بيانات السيرفر
            let callerName = dict["driver_name"] as? String ?? "الكابتن"
            let orderId = dict["order_id"] as? String ?? ""
            let channelName = dict["channel_name"] as? String ?? UUID().uuidString

            // ب. 💡 تحويلها للصيغة القياسية التي تتطلبها مكتبة CallKit لكي تعمل
            let callkitData: [String: Any] = [
                "id": channelName,
                "nameCaller": callerName,
                "appName": "مطاعم بيتي",
                "handle": "طلب رقم \(orderId)",
                "type": 0, // 0 يعني مكالمة صوتية
                "duration": 30000, // الرنين لمدة 30 ثانية
                "extra": dict // نمرر كل البيانات الإضافية ليقرأها Flutter عند الرد
            ]

            // ج. 🚀 إطلاق شاشة الرنين الأصلية فوراً!
            if let plugin = SwiftFlutterCallkitIncomingPlugin.sharedInstance {
                // استخدام الكلاس الداخلي للمكتبة (Data)
                let data = flutter_callkit_incoming.Data(args: callkitData)
                plugin.showCallkitIncoming(data)
            }
        }

        // د. إبلاغ آبل أننا انتهينا خلال ثانية واحدة (لتجنب الكراش والحظر)
        completion()
    }

    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        // تم إبطال التوكن
    }
}