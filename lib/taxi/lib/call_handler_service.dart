import 'dart:convert'; // 🔴 مهم جداً لفك تشفير البيانات
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:uuid/uuid.dart';

import 'active_voice_call_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> taxiFirebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  if (message.data['type'] == 'voip_call') {
    final callId = const Uuid().v4();
    final driverName = message.data['driver_name'] ?? 'كابتن التوصيل';
    final channelName = message.data['channel_name'] ?? '';
    final agoraAppId = message.data['agora_app_id'] ?? '3924f8eebe7048f8a65cb3bd4a4adcec';

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
        'agoraAppId': agoraAppId,
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

      print("📞 [CallKit Event] Action: ${event.event}");

      if (event.event == Event.actionCallAccept) {
        print("✅ [CallKit] تم الضغط على رد. جاري استخراج البيانات...");

        // 🛡️ استخراج مدرع للبيانات لمنع ضياع رقم الغرفة
        final bodyData = event.body ?? {};
        Map<String, dynamic> extraData = {};

        // الأندرويد أحياناً يرسل الـ extra كنص String وليس Map، هذا الكود يحل المشكلة:
        if (bodyData['extra'] != null) {
          if (bodyData['extra'] is Map) {
            extraData = Map<String, dynamic>.from(bodyData['extra']);
          } else if (bodyData['extra'] is String) {
            try {
              extraData = jsonDecode(bodyData['extra']);
            } catch (_) {}
          }
        }

        // استخراج القيم النهائية
        final channel = extraData['channelName']?.toString() ?? extraData['channel_name']?.toString() ?? bodyData['channel_name']?.toString() ?? '';
        final driver = extraData['driverName']?.toString() ?? extraData['driver_name']?.toString() ?? bodyData['driver_name']?.toString() ?? 'الكابتن';
        final appId = extraData['agoraAppId']?.toString() ?? extraData['agora_app_id']?.toString() ?? bodyData['agora_app_id']?.toString() ?? '3924f8eebe7048f8a65cb3bd4a4adcec';

        print("🔍 الغرفة المستخرجة: $channel"); // يجب أن لا يكون فارغاً

        Future.delayed(const Duration(milliseconds: 500), () {
          if (navigatorKey.currentState != null && channel.isNotEmpty) {
            navigatorKey.currentState!.push(
              MaterialPageRoute(
                builder: (_) => ActiveVoiceCallScreen(
                  channelName: channel,
                  remoteName: driver,
                  agoraAppId: appId,
                ),
              ),
            );
          } else {
            print("🚨🚨 [FATAL ERROR] رقم الغرفة مفقود أو المفتاح غير مربوط!");
          }
        });
      }
    });
  }
}