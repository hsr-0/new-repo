import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:uuid/uuid.dart';
import 'package:get/get.dart'; // ✅ أضفنا GetX للانتقال السهل

// استيراد شاشة المكالمة من ملفها المستقل
import 'active_voice_call_screen.dart';

@pragma('vm:entry-point')
Future<void> taxiFirebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  if (message.data['type'] == 'voip_call') {
    final callId = const Uuid().v4();
    final driverName = message.data['driver_name'] ?? 'كابتن التوصيل';
    final channelName = message.data['channel_name'] ?? '';

    CallKitParams callKitParams = CallKitParams(
      id: callId,
      nameCaller: driverName,
      appName: 'تكسي بيتي',
      handle: 'مكالمة عبر الإنترنت...',
      type: 0,
      duration: 30000,
      textAccept: 'رد',
      textDecline: 'رفض',
      extra: <String, dynamic>{
        'channelName': channelName,
        'driverName': driverName,
      },
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#0955fa',
        actionColor: '#4CAF50',
      ),
      ios: const IOSParams(
        iconName: 'CallKitLogo',
        handleType: 'generic',
        supportsVideo: false,
        audioSessionMode: 'default',
        audioSessionActive: true,
        ringtonePath: 'system_ringtone_default',
      ),
    );

    await FlutterCallkitIncoming.showCallkitIncoming(callKitParams);
  }
}

class CallHandlerService {
  static void setupCallKitListener() {
    FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
      if (event == null) return;

      switch (event.event) {
        case Event.actionCallAccept:
        // 📞 الزبون ضغط "رد"
          final extra = event.body['extra'];
          final channelName = extra['channelName'];
          final driverName = extra['driverName'];

          // ✅ تم الحل: استخدام Get.to للانتقال لشاشة المكالمة
          Get.to(() => ActiveVoiceCallScreen(
            channelName: channelName,
            remoteName: driverName,
          ));
          break;
        case Event.actionCallDecline:
        // ❌ الزبون ضغط "رفض"
          print("المكالمة رُفضت من قبل المستخدم");
          break;
        default:
          break;
      }
    });
  }
}