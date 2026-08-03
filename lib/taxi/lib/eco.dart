import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

/// المتغير العام الجديد باستخدام الحزمة الحديثة
PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();

Future<void> initEchoService() async {
  try {
    // تهيئة الإعدادات
    await pusher.init(
      apiKey: 'nyxiq8d6adwi1aeupyz6',
      cluster: 'mt1',

      // دوال الاستماع لحالة الاتصال والأخطاء
      onConnectionStateChange: (dynamic currentState, dynamic previousState) {
        print("🔄 حالة الاتصال: $currentState");
      },
      onError: (String message, int? code, dynamic error) {
        print("❌ خطأ في الاتصال: $message");
      },
      onSubscriptionSucceeded: (String channelName, dynamic data) {
        print("✅ تم الاشتراك في القناة: $channelName");
      },
      onEvent: (PusherEvent event) {
        print("📩 استلام حدث جديد على القناة ${event.channelName}: ${event.data}");
      },
    );

    // بدء الاتصال
    await pusher.connect();
    print("✅ تم تهيئة اتصال Pusher (Reverb) بنجاح");

  } catch (e) {
    print("❌ فشل في تهيئة الاتصال: $e");
  }
}