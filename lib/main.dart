import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audio_session/audio_session.dart';
import 'package:cosmetic_store/taxi/lib/presentation/screens/inbox/ride_message_screen.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/entities/notification_params.dart';
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'package:livekit_client/livekit_client.dart' hide ConnectionState, Priority;

import 'beytei_re/OrderTracking.dart';
import 'webview_screen.dart';
import '../beytei_re/re.dart';

import '/custom_code/actions/index.dart' as actions;
import 'backend/firebase/firebase_config.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/internationalization.dart';
import '/flutter_flow/nav/nav.dart';
import 'index.dart';

// =======================================================================
// 🔥 متغيرات عالمية للتوجيه الذكي (Overlay)
// =======================================================================
final ValueNotifier<Map<String, dynamic>?> activeCallNotifier = ValueNotifier(null);
final ValueNotifier<Map<String, dynamic>?> activeChatNotifier = ValueNotifier(null);
final ValueNotifier<Map<String, dynamic>?> activeTrackingNotifier = ValueNotifier(null);
final ValueNotifier<Map<String, dynamic>?> activeTaxiChatNotifier = ValueNotifier(null);

// =======================================================================
// 🔥 متغير عالمي لحفظ بيانات آخر مكالمة واردة
// =======================================================================
Map<String, dynamic>? _lastIncomingCallData;

// =======================================================================
// 🔥 قناة Native iOS CallKit (تُستخدم على iOS فقط)
// =======================================================================
const MethodChannel _nativeCallChannel = MethodChannel('beytei_native_call');

// Native CallKit hangup must reach the LiveKit screen BEFORE its overlay is
// removed. The active screen then closes the room, timers and microphone.
final ValueNotifier<String?> nativeEndedCallId = ValueNotifier<String?>(null);

// Display name inside the customer's Flutter call screen. Native iOS CallKit
// caller name comes from the server payload, so it is configured on PHP side.
String _beyteiDriverDisplayName(dynamic rawName) {
  final String name = (rawName ?? '').toString().trim();
  if (name.startsWith('مندوب منصة بيتي')) return name;
  if (name.isEmpty || name == 'السائق' || name == 'الكابتن' ||
      name == 'مندوب بيتي') {
    return 'مندوب منصة بيتي';
  }
  return 'مندوب منصة بيتي - $name';
}

// =======================================================================
// 🔥 دوال مساعدة للتحقق من نوع الرسالة
// =======================================================================
bool isVoipCall(dynamic data) {
  if (data == null) return false;
  final type = data['type'];
  return type == 'voip_call' || type == 0 || type == '0';
}

bool isCancelCall(dynamic data) {
  if (data == null) return false;
  final type = data['type'];
  return type == 'cancel_call' || type == 1 || type == '1';
}

// =======================================================================
// 🔥 مساعد: هل القيمة فارغة؟
// =======================================================================
bool _payloadValueIsBlank(dynamic value) {
  return value == null || value.toString().trim().isEmpty;
}

// =======================================================================
// 🔥 مساعد: توحيد بيانات المكالمة
// =======================================================================
Map<String, dynamic> normalizeNativeCallPayload(Map<String, dynamic> payload) {
  final Map<String, dynamic> result = Map<String, dynamic>.from(payload);

  Map<String, dynamic> extraMap = <String, dynamic>{};

  final dynamic rawExtra = result['extra'];

  if (rawExtra is Map) {
    extraMap = Map<String, dynamic>.from(rawExtra);
  } else if (rawExtra is String) {
    try {
      final dynamic decoded = jsonDecode(rawExtra);
      if (decoded is Map) {
        extraMap = Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
  }

  void copyIfMissing(String key) {
    if (_payloadValueIsBlank(result[key]) &&
        !_payloadValueIsBlank(extraMap[key])) {
      result[key] = extraMap[key];
    }
  }

  const List<String> keysToCopy = [
    'id',
    'room_name',
    'channel_name',
    'livekit_url',
    'token',
    'livekit_token',
    'order_id',
    'driver_name',
    'driver_phone',
    'driver_image',
    'nameCaller',
    'handle',
    'avatar',
    'type',
  ];

  for (final String key in keysToCopy) {
    copyIfMissing(key);
  }

  if (extraMap.isNotEmpty) {
    result['extra'] = extraMap;
  }

  if (_payloadValueIsBlank(result['room_name']) &&
      !_payloadValueIsBlank(result['channel_name'])) {
    result['room_name'] = result['channel_name'];
  }

  if (_payloadValueIsBlank(result['nameCaller']) &&
      !_payloadValueIsBlank(result['driver_name'])) {
    result['nameCaller'] = result['driver_name'];
  }

  if (_payloadValueIsBlank(result['handle']) &&
      !_payloadValueIsBlank(result['driver_phone'])) {
    result['handle'] = result['driver_phone'];
  }

  if (_payloadValueIsBlank(result['avatar']) &&
      !_payloadValueIsBlank(result['driver_image'])) {
    result['avatar'] = result['driver_image'];
  }

  if (_payloadValueIsBlank(result['token']) &&
      !_payloadValueIsBlank(result['livekit_token'])) {
    result['token'] = result['livekit_token'];
  }

  return result;
}

// =======================================================================
// 🔥 دالة التوجيه الموحدة
// =======================================================================
void handleNotificationClick(Map<String, dynamic> data) {
  print("🔔 [Notification Click] Type: ${data['type']}");

  if (isVoipCall(data)) {
    print("📞 [Notification Click] VoIP Call - Opening call screen");
    showIncomingCall(data);
  } else if (data['type'] == 'taxi_chat_message' || data['act'] == 'NEW_MESSAGE') {
    print("💬 [Routing] توجيه لدردشة التاكسي - الرحلة: ${data['ride_id']}");
    Future.delayed(const Duration(milliseconds: 1500), () {
      activeTaxiChatNotifier.value = data;
    });
  } else if (data['type'] == 'chat_message') {
    Future.delayed(const Duration(milliseconds: 1500), () {
      activeChatNotifier.value = data;
    });
  } else if (data['type'] == 'status_update') {
    Future.delayed(const Duration(milliseconds: 1500), () {
      activeTrackingNotifier.value = data;
    });
  }
}

// =======================================================================
// 🔥 دالة إظهار المكالمة (For Android - uses flutter_callkit_incoming)
// على iOS: Native CXProvider يعرض CallKit، ولا نحتاج هذه الدالة
// =======================================================================
Future<void> showIncomingCall(Map<String, dynamic> data) async {
  // 🔥 إذا كنا على iOS، لا نستخدم هذه الدالة
  // لأن Native CXProvider يعرض المكالمة تلقائياً
  if (Platform.isIOS) {
    print("🍏 [Show Call] iOS detected - Native CXProvider handles display");
    // نحفظ البيانات فقط
    _lastIncomingCallData = data;
    return;
  }

  // ====== من هنا وما بعد: Android فقط ======
  print("🤖 [Show Call] Android - Using flutter_callkit_incoming...");

  _lastIncomingCallData = data;

  String currentUuid = (data['id'] as String?) ?? (data['order_id'] as String?) ?? const Uuid().v4();
  print("🔑 [Show Call] UUID: $currentUuid");

  final String driverName = data['driver_name'] ?? data['nameCaller'] ?? 'مندوب بيتي';
  final String driverPhone = data['driver_phone'] ?? data['handle'] ?? 'اتصال وارد';

  String driverImage = data['driver_image'] ?? data['avatar'] ?? 'assets/default_avatar.png';

  if (driverImage.startsWith('http://')) {
    driverImage = driverImage.replaceFirst('http://', 'https://');
  }

  final String roomName = data['room_name'] ?? '';
  final String livekitUrl = data['livekit_url'] ?? 'wss://call.beytei.com';
  final String token = data['token'] ?? '';
  final String orderId = data['order_id']?.toString() ?? '';

  print("📞 [Show Call] Driver: $driverName, Room: $roomName");

  final params = CallKitParams(
    id: currentUuid,
    nameCaller: driverName,
    appName: 'منصة بيتي',
    avatar: driverImage,
    handle: driverPhone,
    type: 0,
    duration: 45000,
    extra: {
      'room_name': roomName,
      'livekit_url': livekitUrl,
      'token': token,
      'driver_name': driverName,
      'driver_phone': driverPhone,
      'driver_image': driverImage,
      'order_id': orderId,
    },
    android: const AndroidParams(
      isCustomNotification: true,
      isShowLogo: true,
      ringtonePath: 'system_ringtone_default',
      backgroundColor: '#0955fa',
      actionColor: '#4CAF50',
      incomingCallNotificationChannelName: 'Incoming Call',
      isShowCallID: false,
      isShowFullLockedScreen: true,
      isImportant: true,
    ),
    ios: const IOSParams(
      iconName: 'CallKitLogo',
      handleType: 'generic',
      supportsVideo: false,
      maximumCallGroups: 2,
      maximumCallsPerCallGroup: 1,
      audioSessionMode: 'voiceChat',
      audioSessionActive: true,
      audioSessionPreferredSampleRate: 44100.0,
      audioSessionPreferredIOBufferDuration: 0.005,
      supportsDTMF: false,
      supportsHolding: false,
      supportsGrouping: false,
      supportsUngrouping: false,
    ),
    missedCallNotification: const NotificationParams(
      showNotification: true,
      isShowCallback: true,
      subtitle: 'مكالمة فائتة',
      callbackText: 'عاود الاتصال',
    ),
  );

  try {
    print("🚀 [Show Call] Calling FlutterCallkitIncoming...");
    await FlutterCallkitIncoming.showCallkitIncoming(params);
    print("✅ [Show Call] Done!");
  } catch (e) {
    print("❌ [Show Call] Failed: $e");
  }
}

// =======================================================================
// 🔥 معالج الخلفية
// =======================================================================
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("🔥 [Background] Message: ${message.messageId}");
  print("🔥 [Background] Data: ${message.data}");

  if (isCancelCall(message.data)) {
    print("❌ [Background] Cancel call received");
    // على iOS، Native CXProvider يتولى الإلغاء
    if (Platform.isAndroid) {
      await FlutterCallkitIncoming.endAllCalls();
    }
    return;
  }

  if (isVoipCall(message.data)) {
    print("📞 [Background] VoIP call - showing on Android only");
    // showIncomingCall internally checks Platform.isIOS
    await showIncomingCall(message.data);
  }
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void _showLocalNotification(RemoteMessage message) {
  if (isVoipCall(message.data)) return;

  final String title = message.notification?.title ?? message.data['title'] ?? 'تحديث من منصة بيتي';
  final String body = message.notification?.body ?? message.data['body'] ?? 'لديك تحديث جديد بخصوص طلبك.';

  const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'high_importance_channel',
    'High Importance Notifications',
    channelDescription: 'This channel is used for important notifications.',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
  );

  const NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
  );

  flutterLocalNotificationsPlugin.show(
    DateTime.now().millisecondsSinceEpoch.toSigned(31),
    title,
    body,
    platformChannelSpecifics,
    payload: jsonEncode(message.data),
  );
}

Future<void> _handleTokenRefresh() async {
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    print("🔄 [FCM] Token refreshed");
    await _saveAndRegisterToken(newToken);
  });
}

Future<void> _saveAndRegisterToken(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('fcm_token', token);

  String? voipToken = '';

  if (Platform.isIOS) {
    try {
      voipToken = await FlutterCallkitIncoming.getDevicePushTokenVoIP();
      if (voipToken != null && voipToken.isNotEmpty) {
        await prefs.setString('voip_token', voipToken);
        print("🍏 [Apple PushKit] VoIP Token: $voipToken");
      }
    } catch (e) {
      print("⚠️ فشل جلب توكن VoIP: $e");
    }
  }
}

// =======================================================================
// 🔥 استراتيجية الأذونات
// =======================================================================
Future<void> requestLocationPermissionOnly() async {
  print("🔐 التحقق من حالة الـ GPS...");
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    print("⚠️ خدمة الموقع (GPS) مغلقة.");
    return;
  }

  final status = await Permission.location.status;

  if (!status.isGranted && !status.isPermanentlyDenied) {
    await Permission.location.request();
  }

  if (await Permission.location.isGranted) {
    _fetchLocationInBackground();
  }
}

void _fetchLocationInBackground() async {
  try {
    print("📍 [الخلفية] جاري تحديد الموقع بصمت...");
    Position? position = await Geolocator.getLastKnownPosition();
    if (position == null) {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 5),
      );
    }
    print("✅ [الخلفية] تم التقاط الموقع: ${position.latitude}, ${position.longitude}");
  } catch (e) {
    print("⚠️ [الخلفية] فشل التقاط الموقع: $e");
  }
}

Future<void> requestSecondaryPermissions() async {
  final notifStatus = await Permission.notification.status;
  if (!notifStatus.isGranted && !notifStatus.isPermanentlyDenied) {
    await Permission.notification.request();
  }

  final micStatus = await Permission.microphone.status;
  if (!micStatus.isGranted && !micStatus.isPermanentlyDenied) {
    await Permission.microphone.request();
  }
}

// =======================================================================
// 🔥 4. الدالة الرئيسية (MAIN)
// =======================================================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  usePathUrlStrategy();

  await initFirebase();

  try {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
      print("✅ Firebase anonymous sign-in");
    }
  } catch (e) {
    print("⚠️ Firebase auth error: $e");
  }

  try {
    String? initialToken = await FirebaseMessaging.instance.getToken();
    if (initialToken != null) {
      await _saveAndRegisterToken(initialToken);
    }
  } catch (e) {
    print("⚠️ Error fetching initial FCM token: $e");
  }

  _handleTokenRefresh();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      if (response.payload != null) {
        try {
          handleNotificationClick(jsonDecode(response.payload!));
        } catch (e) {
          print("Error parsing local notification payload: $e");
        }
      }
    },
  );

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
    playSound: true,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // =======================================================================
  // ✅ معالجة رسائل FCM في الواجهة الأمامية
  // =======================================================================
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    print("🔔 [FCM] Foreground: ${message.data}");

    if (isCancelCall(message.data)) {
      print("❌ [Foreground] Cancel call received");

      if (activeCallNotifier.value != null) {
        print("🛡️ [PROTECTED] تجاهل cancel_call (المكالمة مقبولة)");
        return;
      }

      // 🔥 على iOS: Native يعالج الإلغاء
      // على Android: نستخدم المكتبة
      if (Platform.isAndroid) {
        await FlutterCallkitIncoming.endAllCalls();
      }
      activeCallNotifier.value = null;
      _lastIncomingCallData = null;
      return;
    }

    if (isVoipCall(message.data)) {
      print("📞 [Foreground] VoIP call");
      // on iOS: Native AppDelegate سيتولى الأمر
      // on Android: showIncomingCall سيُظهر المكالمة
      showIncomingCall(message.data);
    } else {
      _showLocalNotification(message);
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print("🔔 [Message Opened] Data: ${message.data}");
    handleNotificationClick(message.data);
  });

  await actions.connected();
  await actions.notificationInit();
  await actions.lockOrientation();

  await FFLocalizations.initialize();

  final appState = FFAppState();
  await appState.initializePersistedState();

  runApp(ChangeNotifierProvider(
    create: (context) => appState,
    child: const MyApp(),
  ));
}

// =======================================================================
// 🔥 5. التطبيق الرئيسي (MyApp)
// =======================================================================
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;
}

class _MyAppState extends State<MyApp> {
  Locale? _locale = FFLocalizations.getStoredLocale();
  Locale? get locale => _locale;
  ThemeMode _themeMode = ThemeMode.system;

  late AppStateNotifier _appStateNotifier;
  late GoRouter _router;

  // لمنع تكرار فتح نفس المكالمة
  final Set<String> _handledNativeCallIds = <String>{};

  @override
  void initState() {
    super.initState();
    _appStateNotifier = AppStateNotifier.instance;
    _router = createRouter(_appStateNotifier);

    _setupCallKitListener();

    // 🔥 مستمع Native iOS فقط على iOS (Android غير متأثر)
    if (Platform.isIOS) {
      _setupNativeCallListener();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTerminatedCall();

      FirebaseMessaging.instance.getInitialMessage().then((message) {
        if (message != null) {
          print("🚀 [App Launch] من إشعار");
          handleNotificationClick(message.data);
        }
      });

      requestLocationPermissionOnly();
      requestSecondaryPermissions();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _router.routerDelegate.addListener(() {
        if (mounted) setState(() {});
      });
    });
  }

  Future<void> _checkTerminatedCall() async {
    try {
      dynamic calls = await FlutterCallkitIncoming.activeCalls();
      if (calls is List && calls.isNotEmpty) {
        print("🚀 [App Launch] مكالمة نشطة موجودة!");
        var firstCall = calls.first;

        if (firstCall is Map) {
          activeCallNotifier.value = Map<String, dynamic>.from(firstCall);
        } else {
          try {
            var callObj = firstCall as dynamic;
            if (callObj.extra != null) {
              activeCallNotifier.value = Map<String, dynamic>.from(callObj.extra);
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      print("⚠️ Error checking active calls: $e");
    }
  }

  // =======================================================================
  // 🔥 مستمع أحداث iOS Native CallKit (iOS فقط)
  // =======================================================================
  void _setupNativeCallListener() {
    _nativeCallChannel.setMethodCallHandler((call) async {
      if (!mounted) return;

      if (call.method == 'onCallEvent') {
        final dynamic arguments = call.arguments;

        String event = '';
        Map<String, dynamic> payload = <String, dynamic>{};

        if (arguments is Map) {
          event = arguments['event']?.toString() ?? '';

          final dynamic rawPayload = arguments['payload'];

          if (rawPayload is Map) {
            payload = Map<String, dynamic>.from(rawPayload);
          } else if (rawPayload is String) {
            try {
              final dynamic decoded = jsonDecode(rawPayload);
              if (decoded is Map) {
                payload = Map<String, dynamic>.from(decoded);
              }
            } catch (_) {}
          }
        } else if (arguments is String) {
          event = arguments;
        }

        print("🍏 [Native iOS Call] event=$event");
        print("🍏 [Native iOS Call] payload=$payload");

        // ======================= حدث "incoming" =======================
        if (event == 'incoming') {
          final Map<String, dynamic> normalized = normalizeNativeCallPayload(payload);
          final String callId = normalized['id']?.toString() ?? '';

          final bool hasRoom = !_payloadValueIsBlank(normalized['room_name']);
          final bool hasToken = !_payloadValueIsBlank(normalized['token']);

          if (hasRoom && hasToken) {
            _lastIncomingCallData = normalized;
            print("📞 [Native iOS Call] incoming (ID: $callId) - awaiting accept");
          } else {
            print("⚠️ [Native iOS Call] incoming but data incomplete");
          }
          return;
        }

        // ======================= حدث "accept" =======================
        if (event == 'accept') {
          final Map<String, dynamic> normalized = normalizeNativeCallPayload(payload);
          final String callId = normalized['id']?.toString() ?? '';

          if (callId.isNotEmpty && _handledNativeCallIds.contains(callId)) {
            print("♻️ [Native iOS Call] accept مكرر - تجاهل");
            await _clearPendingNativeCall();
            return;
          }

          if (callId.isNotEmpty) {
            _handledNativeCallIds.add(callId);
          }

          final bool hasRoom = !_payloadValueIsBlank(normalized['room_name']);
          final bool hasToken = !_payloadValueIsBlank(normalized['token']);

          if (hasRoom && hasToken) {
            nativeEndedCallId.value = null;
            _lastIncomingCallData = normalized;
            activeCallNotifier.value = normalized;
            print("✅ [Native iOS Call] فتح شاشة LiveKit");
          } else if (_lastIncomingCallData != null) {
            activeCallNotifier.value = _lastIncomingCallData;
            print("♻️ [Native iOS Call] استخدام بيانات محفوظة");
          } else {
            print("⚠️ [Native iOS Call] بيانات ناقصة");
          }

          await _clearPendingNativeCall();
        }
        // ======================= event: end/decline/timeout =======================
        else if (event == 'end' || event == 'decline' || event == 'timeout') {
          final normalized = normalizeNativeCallPayload(payload);
          final String callId = normalized['id']?.toString().trim().isNotEmpty == true
              ? normalized['id'].toString()
              : (activeCallNotifier.value?['id']?.toString() ?? '');

          if (callId.isNotEmpty) {
            _handledNativeCallIds.remove(callId);
          }

          final activeId = activeCallNotifier.value?['id']?.toString() ?? '';
          if (activeCallNotifier.value != null &&
              (callId.isEmpty || activeId.isEmpty || callId == activeId)) {
            // Do NOT clear the overlay first: the screen must disconnect
            // LiveKit and stop its timer through its own _endCall().
            nativeEndedCallId.value = activeId.isNotEmpty ? activeId : callId;
          } else if (activeCallNotifier.value == null) {
            // Declined while ringing, before the LiveKit screen opened.
            nativeEndedCallId.value = null;
          }

          _lastIncomingCallData = null;
          print('📴 [Native iOS Call] $event; closing LiveKit if active');
          await _clearPendingNativeCall();
        }
      }
    });

    _checkPendingNativeCall();
  }

  // =======================================================================
  // 🔥 فحص المكالمة الأصلية المعلقة
  // =======================================================================
  Future<void> _checkPendingNativeCall() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      final String? payloadString = prefs.getString('pending_native_call_payload');
      final String? event = prefs.getString('pending_native_call_event');

      if (payloadString == null || payloadString.isEmpty) {
        return;
      }

      if (activeCallNotifier.value != null) {
        await prefs.remove('pending_native_call_payload');
        await prefs.remove('pending_native_call_event');
        return;
      }

      Map<String, dynamic> payload = <String, dynamic>{};

      try {
        final dynamic decoded = jsonDecode(payloadString);
        if (decoded is Map) {
          payload = Map<String, dynamic>.from(decoded);
        }
      } catch (e) {
        print("❌ [Pending Native Call] JSON parse error: $e");
        await prefs.remove('pending_native_call_payload');
        await prefs.remove('pending_native_call_event');
        return;
      }

      print("🍏 [Pending Native Call] event=$event");

      if (event == 'accept') {
        final Map<String, dynamic> normalized = normalizeNativeCallPayload(payload);
        final String callId = normalized['id']?.toString() ?? '';

        if (callId.isNotEmpty && _handledNativeCallIds.contains(callId)) {
          await prefs.remove('pending_native_call_payload');
          await prefs.remove('pending_native_call_event');
          return;
        }

        if (callId.isNotEmpty) {
          _handledNativeCallIds.add(callId);
        }

        final bool hasRoom = !_payloadValueIsBlank(normalized['room_name']);
        final bool hasToken = !_payloadValueIsBlank(normalized['token']);

        if (hasRoom && hasToken) {
          _lastIncomingCallData = normalized;
          activeCallNotifier.value = normalized;
          print("✅ [Pending Native Call] فتح شاشة LiveKit");
        } else if (_lastIncomingCallData != null) {
          activeCallNotifier.value = _lastIncomingCallData;
          print("♻️ [Pending Native Call] استخدام بيانات محفوظة");
        }

        await prefs.remove('pending_native_call_payload');
        await prefs.remove('pending_native_call_event');
      } else if (event == 'end' || event == 'decline' || event == 'timeout') {
        final String callId = payload['id']?.toString() ?? '';

        if (callId.isNotEmpty) {
          _handledNativeCallIds.remove(callId);
        }

        activeCallNotifier.value = null;
        _lastIncomingCallData = null;

        await prefs.remove('pending_native_call_payload');
        await prefs.remove('pending_native_call_event');
      }
    } catch (e) {
      print("❌ Error checking pending native call: $e");
    }
  }

  Future<void> _clearPendingNativeCall() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('pending_native_call_payload');
      await prefs.remove('pending_native_call_event');
    } catch (_) {}
  }

  // =======================================================================
  // 🔥 إعلام Native iOS بإنهاء المكالمة (iOS فقط)
  // =======================================================================
  Future<void> notifyNativeCallEnded(String callId) async {
    // ⚠️ على Android: لا نفعل أي شيء
    if (!Platform.isIOS) return;
    if (callId.isEmpty) return;

    try {
      await _nativeCallChannel.invokeMethod('endNativeCall', {
        'callId': callId,
      });
      print("📞 [Native Call End] iOS informed: $callId");
    } catch (e) {
      print("⚠️ فشل إعلام native: $e");
    }
  }

  void _setupCallKitListener() {
    FlutterCallkitIncoming.onEvent.listen((dynamic event) async {
      if (event == null) return;

      print("📞 [CallKit Event] $event");

      String? eventType;
      Map<String, dynamic>? eventData;

      try {
        String eventStr = event.toString();

        if (eventStr.contains('CallEventActionCallAccept')) {
          eventType = 'Accept';
        } else if (eventStr.contains('CallEventActionCallDecline')) {
          eventType = 'Decline';
        } else if (eventStr.contains('CallEventActionCallEnded')) {
          eventType = 'Ended';
        } else if (eventStr.contains('CallEventActionCallTimeout')) {
          eventType = 'Timeout';
        } else if (event is Map) {
          eventType = event['event']?.toString();
        }

        try {
          var params = (event as dynamic).callKitParams;
          if (params != null && params.extra != null) {
            if (params.extra is Map) {
              eventData = Map<String, dynamic>.from(params.extra);
            } else if (params.extra is String) {
              eventData = Map<String, dynamic>.from(jsonDecode(params.extra));
            }
          }
        } catch (e) {
          print("⚠️ تعذر استخراج callKitParams");
        }
      } catch (e) {
        print("⚠️ Failed to parse event: $e");
      }

      if (eventType == null) {
        print("⚠️ نوع حدث غير معروف.");
        return;
      }

      print("📞 [CallKit Event] Type: $eventType");

      // 🔥 على iOS: Native يتولى الأمر عبر onCallEvent
      // لكننا نبقي هذا للحالات الخاصة (Android أو Fallback)
      if (Platform.isIOS && eventType == 'Accept') {
        // نتجاهل هذا على iOS لأن Native سيرسل 'accept' عبر قناته
        print("🍏 [iOS] تجاهل حدث المكتبة (Native يتولى الأمر)");
        return;
      }

      if (eventData == null || eventData.isEmpty || eventData['room_name'] == null) {
        print("♻️ [FALLBACK] استخدام _lastIncomingCallData");
        eventData = _lastIncomingCallData;
      }

      if (eventType == 'Accept' || eventType.contains('actionCallAccept')) {
        print("✅ [CallKit] تم الرد");
        final mergedData = {
          ...?_lastIncomingCallData,
          ...?(eventData ?? {}),
        };
        activeCallNotifier.value = mergedData;
      } else if (eventType == 'Decline' || eventType == 'Ended' || eventType == 'Timeout' ||
          eventType.contains('actionCallDecline') || eventType.contains('actionCallEnded') || eventType.contains('actionCallTimeout')) {
        print('📴 [CallKit] end/decline/timeout; clean LiveKit before hiding UI');
        if (Platform.isIOS) {
          final id = activeCallNotifier.value?['id']?.toString() ?? '';
          if (id.isNotEmpty) {
            // Native plugin events can precede the MethodChannel event.
            nativeEndedCallId.value = id;
          } else {
            _lastIncomingCallData = null;
          }
        } else {
          // The Android call overlay is not the LiveKit room. Keep this
          // existing behavior for incoming calls not yet accepted.
          await FlutterCallkitIncoming.endAllCalls();
          activeCallNotifier.value = null;
          _lastIncomingCallData = null;
        }
      }
    });
  }

  Map<String, String> _extractCallData(Map<String, dynamic> rawData) {
    Map<String, dynamic> extraData = {};
    if (rawData['extra'] != null) {
      if (rawData['extra'] is Map) {
        extraData = Map<String, dynamic>.from(rawData['extra']);
      } else if (rawData['extra'] is String) {
        try { extraData = jsonDecode(rawData['extra']); } catch (_) {}
      }
    }
    return {
      'roomName': extraData['room_name']?.toString() ?? rawData['room_name']?.toString() ?? '',
      'livekitUrl': extraData['livekit_url']?.toString() ?? rawData['livekit_url']?.toString() ?? 'wss://call.beytei.com',
      'token': extraData['token']?.toString() ?? rawData['token']?.toString() ?? '',
      'driverName': _beyteiDriverDisplayName(
        extraData['driver_name'] ?? rawData['driver_name'] ??
            extraData['nameCaller'] ?? rawData['nameCaller'] ?? 'السائق',
      ),
    };
  }

  void setLocale(String language) {
    safeSetState(() => _locale = createLocale(language));
    FFLocalizations.storeLocale(language);
  }

  void setThemeMode(ThemeMode mode) => safeSetState(() {
    _themeMode = mode;
  });

  String getRoute([RouteMatch? routeMatch]) {
    final RouteMatch lastMatch = routeMatch ?? _router.routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : _router.routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }

  List<String> getRouteStack() =>
      _router.routerDelegate.currentConfiguration.matches
          .map((e) => getRoute(e as dynamic))
          .toList();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'منصة بيتي',
      localizationsDelegates: const [
        FFLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FallbackMaterialLocalizationDelegate(),
        FallbackCupertinoLocalizationDelegate(),
      ],
      locale: _locale,
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      theme: ThemeData(
        brightness: Brightness.light,
      ),
      themeMode: _themeMode,
      routerConfig: _router,

      builder: (context, child) {
        return Scaffold(
          body: Stack(
            children: [
              if (child != null) child,

              // 1. المكالمة الصوتية
              ValueListenableBuilder<Map<String, dynamic>?>(
                valueListenable: activeCallNotifier,
                builder: (context, callData, _) {
                  if (callData == null) return const SizedBox.shrink();

                  final extractedData = _extractCallData(callData);

                  if (extractedData['roomName']!.isEmpty || extractedData['token']!.isEmpty) {
                    print("⚠️ [Call Screen] Missing roomName or token");
                    return const SizedBox.shrink();
                  }

                  print("📞 [Call Screen] SHOWING - room: ${extractedData['roomName']}");

                  // 🔥 استخراج callId من البيانات
                  final String callId = callData['id']?.toString() ??
                      callData['order_id']?.toString() ??
                      '';

                  return ActiveVoiceCallScreen(
                    roomName: extractedData['roomName']!,
                    livekitUrl: extractedData['livekitUrl']!,
                    token: extractedData['token']!,
                    remoteName: extractedData['driverName']!,
                    callId: callId,
                    onCallEnded: () {
                      print("📞 [Call Screen] Ended");
                      activeCallNotifier.value = null;
                    },
                  );
                },
              ),

              // 2. الدردشة العادية
              ValueListenableBuilder<Map<String, dynamic>?>(
                valueListenable: activeChatNotifier,
                builder: (context, chatData, _) {
                  if (chatData != null) {
                    Future.microtask(() {
                      _router.routerDelegate.navigatorKey.currentState?.push(
                        MaterialPageRoute(
                          builder: (_) => CustomerChatPage(
                            orderId: chatData['order_id'].toString(),
                            driverName: chatData['sender_name'] ?? 'المندوب',
                            customerName: 'الزبون',
                          ),
                        ),
                      ).then((_) {
                        activeChatNotifier.value = null;
                      });
                    });
                  }
                  return const SizedBox.shrink();
                },
              ),

              // 3. تتبع الطلب
              ValueListenableBuilder<Map<String, dynamic>?>(
                valueListenable: activeTrackingNotifier,
                builder: (context, trackData, _) {
                  if (trackData != null) {
                    Future.microtask(() async {
                      try {
                        final orderId = trackData['order_id'].toString();
                        final localOrders = await OrderHistoryService().getOrders();
                        final order = localOrders.firstWhere((o) => o.id.toString() == orderId);

                        _router.routerDelegate.navigatorKey.currentState?.push(
                          MaterialPageRoute(
                            builder: (_) => OrderTrackingScreen(order: order),
                          ),
                        ).then((_) {
                          activeTrackingNotifier.value = null;
                        });
                      } catch (e) {
                        print("لم يتم العثور على الطلب محليا: $e");
                        activeTrackingNotifier.value = null;
                      }
                    });
                  }
                  return const SizedBox.shrink();
                },
              ),

              // 4. دردشة التاكسي
              ValueListenableBuilder<Map<String, dynamic>?>(
                valueListenable: activeTaxiChatNotifier,
                builder: (context, data, _) {
                  if (data != null) {
                    Future.microtask(() {
                      _router.routerDelegate.navigatorKey.currentState?.push(
                        MaterialPageRoute(
                          builder: (_) => RideMessageScreen(
                            rideID: data['ride_id']?.toString() ?? '-1',
                          ),
                        ),
                      ).then((_) {
                        activeTaxiChatNotifier.value = null;
                      });
                    });
                  }
                  return const SizedBox.shrink();
                },
              ),

              // زر التشخيص العائم
              Positioned(
                bottom: 20,
                left: 20,
                child: FloatingActionButton.small(
                  onPressed: () {
                    _router.routerDelegate.navigatorKey.currentState?.push(
                      MaterialPageRoute(builder: (_) => const IOSDiagnosticConsole()),
                    );
                  },
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.bug_report, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// =======================================================================
// 🔬 نظام التشخيص الذاتي (Diagnostic System)
// =======================================================================
class IOSDiagnosticConsole extends StatefulWidget {
  const IOSDiagnosticConsole({super.key});

  @override
  State<IOSDiagnosticConsole> createState() => _IOSDiagnosticConsoleState();
}

class _IOSDiagnosticConsoleState extends State<IOSDiagnosticConsole> {
  static const _channel = MethodChannel('beytei_deep_debugger');

  String _logs = 'جاري التحميل...';
  String _voipToken = 'جاري التحميل...';
  String _fcmToken = 'جاري التحميل...';
  String _deviceInfo = 'جاري التحميل...';
  String _pushKitStatus = 'جاري التحميل...';
  String _permissions = 'جاري التحميل...';
  String _bgModes = 'جاري التحميل...';
  String _appInfo = 'جاري التحميل...';
  String _testResult = '';

  String _serverCallResult = '';
  bool _isRequestingCall = false;

  bool _isLoading = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);

    try {
      final logsResult = await _channel.invokeMethod('getLogs');
      if (logsResult is Map) {
        _logs = logsResult['logs']?.toString() ?? 'لا توجد سجلات';
        _voipToken = logsResult['token']?.toString() ?? '❌ مفقود';
      }

      final pushKitResult = await _channel.invokeMethod('getPushKitStatus');
      if (pushKitResult is Map) {
        _pushKitStatus = 'استلام VoIP: ${pushKitResult['receivedCount'] ?? 0}\n'
            'عرض CallKit: ${pushKitResult['callKitShownCount'] ?? 0}\n'
            'آخر خطأ: ${pushKitResult['lastError'] ?? 'لا يوجد'}\n'
            'آخر Payload: ${pushKitResult['lastPayload'] ?? 'لا يوجد'}';
      }

      final permResult = await _channel.invokeMethod('checkPermissions');
      if (permResult is Map) {
        final notif = permResult['notifications'] as Map?;
        _permissions = 'الإشعارات: ${notif?['statusText'] ?? 'غير معروف'}\n'
            'الصوت: ${notif?['soundSetting'] ?? '?'}\n'
            'الشارة: ${notif?['badgeSetting'] ?? '?'}';
      }

      final fullReport = await _channel.invokeMethod('runFullDiagnostics', 'https://re.beytei.com/wp-json/beytei-diagnostics/v1/receive-ios-report');
      if (fullReport is Map) {
        final report = fullReport['report'] as Map?;
        if (report != null) {
          final device = report['deviceInfo'] as Map?;
          _deviceInfo = 'الموديل: ${device?['model'] ?? '?'}\n'
              'النظام: ${device?['systemName'] ?? '?'} ${device?['systemVersion'] ?? '?'}\n'
              'جهاز حقيقي: ${device?['isPhysicalDevice'] ?? '?'}\n'
              'المعرف: ${device?['identifierForVendor'] ?? '?'}';

          final tokens = report['tokens'] as Map?;
          _fcmToken = tokens?['fcmToken']?.toString() ?? '❌ مفقود';
          if (_voipToken == '❌ لا يوجد' || _voipToken == 'جاري التحميل...') {
            _voipToken = tokens?['voipToken']?.toString() ?? '❌ مفقود';
          }

          final bg = report['backgroundModes'] as Map?;
          _bgModes = 'voip: ${bg?['hasVoIP'] ?? false}\n'
              'audio: ${bg?['hasAudio'] ?? false}\n'
              'remote-notification: ${bg?['hasRemoteNotification'] ?? false}\n'
              'الكل: ${bg?['configured'] ?? []}';

          final app = report['appInfo'] as Map?;
          _appInfo = 'الإصدار: ${app?['version'] ?? '?'}\n'
              'البناء: ${app?['build'] ?? '?'}\n'
              'Bundle ID: ${app?['bundleId'] ?? '?'}';
        }
      }
    } catch (e) {
      _logs = '❌ خطأ في جلب البيانات: $e';
    }

    setState(() => _isLoading = false);
  }

  Future<void> _testCallKitLocally() async {
    setState(() {
      _testResult = '⏳ جاري اختبار CallKit محليا...';
    });
    try {
      final result = await _channel.invokeMethod('testLocalCallKit');
      if (result is Map && result['success'] == true) {
        setState(() {
          _testResult = '✅ ${result['message']}\nUUID: ${result['uuid']}';
        });
      } else {
        setState(() {
          _testResult = '❌ فشل: ${result?['message'] ?? 'خطأ غير معروف'}';
        });
      }
    } catch (e) {
      setState(() {
        _testResult = '❌ خطأ: $e';
      });
    }
  }

  Future<void> _requestCallFromServer() async {
    setState(() {
      _isRequestingCall = true;
      _serverCallResult = '⏳ جاري طلب مكالمة من السيرفر...\nيرجى الانتظار 5-10 ثوانٍ...';
    });

    try {
      String deviceType = Platform.isIOS ? 'ios' : (Platform.isAndroid ? 'android' : 'unknown');

      String cleanVoipToken = _voipToken.contains('❌') ? '' : _voipToken.split('\n')[0].trim();
      String cleanFcmToken = _fcmToken.contains('❌') ? '' : _fcmToken.split('\n')[0].trim();

      final response = await http.post(
        Uri.parse('https://re.beytei.com/wp-json/beytei/v1/request-diagnostic-call'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'voip_token': cleanVoipToken,
          'fcm_token': cleanFcmToken,
          'device_type': deviceType,
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      setState(() {
        _serverCallResult = data['log'] ?? 'لا يوجد سجل';
        if (data['http_code'] != null) {
          _serverCallResult += '\n\n📊 كود HTTP: ${data['http_code']}';
        }
        if (data['apple_response'] != null && data['apple_response'].toString().isNotEmpty) {
          _serverCallResult += '\n🍏 رد Apple: ${data['apple_response']}';
        }
        if (data['uuid'] != null) {
          _serverCallResult += '\n\n🆔 UUID المكالمة: ${data['uuid']}';
        }
      });
    } catch (e) {
      setState(() {
        _serverCallResult = '❌ خطأ في الاتصال بالسيرفر: $e\n\nتأكد من إضافة كود PHP في functions.php';
      });
    }

    setState(() => _isRequestingCall = false);
  }

  Future<void> _sendReportToServer() async {
    setState(() => _isSending = true);
    try {
      final result = await _channel.invokeMethod(
        'runFullDiagnostics',
        'https://re.beytei.com/wp-json/beytei-diagnostics/v1/receive-ios-report',
      );
      if (result is Map && result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ تم إرسال التقرير للسيرفر بنجاح'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ فشل: ${result?['serverResponse'] ?? 'خطأ'}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ خطأ: $e'), backgroundColor: Colors.red),
      );
    }
    setState(() => _isSending = false);
  }

  Future<void> _clearCacheAndReset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('voip_token');
    await prefs.remove('fcm_token');
    await prefs.remove('ios_debug_logs');

    await prefs.remove('pending_native_call_payload');
    await prefs.remove('pending_native_call_event');

    setState(() {
      _logs = '🗑️ تم مسح السجلات';
      _voipToken = '🗑️ تم مسح التوكن (أعد تشغيل التطبيق)';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ تم مسح الكاش. أعد تشغيل التطبيق لتوليد توكن جديد.'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 5),
      ),
    );
  }

  Future<void> _copyAllToClipboard() async {
    final buffer = StringBuffer();
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln(' تقرير تشخيص iOS كامل');
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('📅 التاريخ: ${DateTime.now()}');
    buffer.writeln('');
    buffer.writeln('📱 معلومات التطبيق:\n$_appInfo');
    buffer.writeln('');
    buffer.writeln('🖥️ معلومات الجهاز:\n$_deviceInfo');
    buffer.writeln('');
    buffer.writeln('🔑 توكن VoIP:\n$_voipToken');
    buffer.writeln('');
    buffer.writeln('🔑 توكن FCM:\n$_fcmToken');
    buffer.writeln('');
    buffer.writeln('📡 حالة PushKit:\n$_pushKitStatus');
    buffer.writeln('');
    buffer.writeln('🔐 الأذونات:\n$_permissions');
    buffer.writeln('');
    buffer.writeln('⚙️ أوضاع الخلفية:\n$_bgModes');
    if (_testResult.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('🧪 نتيجة اختبار CallKit:\n$_testResult');
    }
    if (_serverCallResult.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('📞 نتيجة طلب المكالمة من السيرفر:\n$_serverCallResult');
    }
    buffer.writeln('');
    buffer.writeln('📜 سجلات التطبيق:\n$_logs');
    buffer.writeln('═══════════════════════════════════════');

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ تم نسخ كل المعلومات! الصقها في المحادثة'), backgroundColor: Colors.green),
      );
    }
  }

  Widget _buildSection(String title, String content, {Color borderColor = Colors.blue}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border(right: BorderSide(color: borderColor, width: 4)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
          const SizedBox(height: 6),
          SelectableText(
            content,
            style: const TextStyle(fontSize: 12, color: Colors.black54, fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        title: const Text('🔬 iOS Diagnostic Console'),
        backgroundColor: const Color(0xFF16213e),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_all),
            onPressed: _copyAllToClipboard,
            tooltip: 'نسخ كل شيء',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllData,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _testCallKitLocally,
                    icon: const Icon(Icons.phone, size: 18),
                    label: const Text('اختبار CallKit', style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isRequestingCall ? null : _requestCallFromServer,
                    icon: const Icon(Icons.call, size: 18),
                    label: const Text('طلب مكالمة من السيرفر', style: TextStyle(fontSize: 10)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSending ? null : _sendReportToServer,
                    icon: const Icon(Icons.cloud_upload, size: 18),
                    label: const Text('إرسال للسيرفر', style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _clearCacheAndReset,
                    icon: const Icon(Icons.delete_sweep, size: 18),
                    label: const Text('مسح الكاش', style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_testResult.isNotEmpty)
              _buildSection('🧪 نتيجة اختبار CallKit', _testResult,
                  borderColor: _testResult.startsWith('✅') ? Colors.green : Colors.red),

            if (_serverCallResult.isNotEmpty)
              _buildSection('📞 نتيجة طلب المكالمة من السيرفر', _serverCallResult,
                  borderColor: _serverCallResult.contains('✅') || _serverCallResult.contains('نجاح') ? Colors.green : Colors.orange),

            _buildSection('📱 معلومات التطبيق', _appInfo, borderColor: Colors.purple),
            _buildSection('🖥️ معلومات الجهاز', _deviceInfo, borderColor: Colors.teal),

            _buildSection(
              '🔑 توكن VoIP (الآيفون)',
              _voipToken.length > 20 ? '${_voipToken.substring(0, 20)}...\n(الطول: ${_voipToken.length})' : _voipToken,
              borderColor: _voipToken.contains('❌') ? Colors.red : Colors.green,
            ),
            _buildSection(
              '🔑 توكن FCM',
              _fcmToken.length > 20 ? '${_fcmToken.substring(0, 20)}...\n(الطول: ${_fcmToken.length})' : _fcmToken,
              borderColor: _fcmToken.contains('❌') ? Colors.red : Colors.green,
            ),

            _buildSection('📡 حالة PushKit', _pushKitStatus, borderColor: Colors.orange),
            _buildSection('🔐 الأذونات', _permissions, borderColor: Colors.indigo),
            _buildSection('⚙️ أوضاع الخلفية (Info.plist)', _bgModes,
                borderColor: _bgModes.contains('true') ? Colors.green : Colors.red),

            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0d1117),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📜 سجلات التطبيق (آخر 100 سطر)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green)),
                  const SizedBox(height: 8),
                  Container(
                    height: 300,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        _logs,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.greenAccent,
                          fontFamily: 'monospace',
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.yellow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.yellow.withOpacity(0.5)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('💡 دليل التشخيص السريع', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.yellow)),
                  SizedBox(height: 8),
                  Text('1. توكن VoIP مفقود: التطبيق لم يسجل PushKit.', style: TextStyle(fontSize: 11, color: Colors.white70)),
                  SizedBox(height: 4),
                  Text('2. "استلام VoIP: 0": الإشعار لم يصل من السيرفر.', style: TextStyle(fontSize: 11, color: Colors.white70)),
                  SizedBox(height: 4),
                  Text('3. "استلام > 0" لكن "عرض CallKit: 0": مشكلة في العرض.', style: TextStyle(fontSize: 11, color: Colors.white70)),
                  SizedBox(height: 4),
                  Text('4. اختبار محلي يعمل لكن الحقيقي لا: المشكلة في Backend.', style: TextStyle(fontSize: 11, color: Colors.white70)),
                  SizedBox(height: 4),
                  Text('5. إذا انهار التطبيق: اضغط "مسح الكاش" وأعد التشغيل.', style: TextStyle(fontSize: 11, color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// =======================================================================
// 🔥 شاشة المكالمة (تدعم iOS Native CallKit + Android)
// =======================================================================
class ActiveVoiceCallScreen extends StatefulWidget {
  final String roomName;
  final String livekitUrl;
  final String token;
  final String remoteName;
  final String? orderId;
  final String? callId;  // 🔥 جديد: لإنهاء المكالمة على iOS
  final VoidCallback? onCallEnded;

  const ActiveVoiceCallScreen({
    super.key,
    required this.roomName,
    required this.livekitUrl,
    required this.token,
    required this.remoteName,
    this.orderId,
    this.callId,
    this.onCallEnded,
  });

  @override
  State<ActiveVoiceCallScreen> createState() => _ActiveVoiceCallScreenState();
}

class _ActiveVoiceCallScreenState extends State<ActiveVoiceCallScreen> {
  Room? _room;
  EventsListener<RoomEvent>? _listener;

  bool _isConnected = false;
  bool _isRemoteConnected = false;

  bool _isMuted = false;
  bool _isSpeaker = true;

  int _callDuration = 0;
  Timer? _durationTimer;
  Timer? _timeoutTimer;

  bool _hasError = false;
  String _errorMessage = "";
  bool _isEngineReleased = false;

  // Native CallKit may end a call before Flutter's on-screen hangup is used.
  void _handleNativeHangup() {
    if (!mounted || _isEngineReleased) return;
    final incomingEndId = nativeEndedCallId.value;
    if (incomingEndId == null || incomingEndId.isEmpty) return;
    if (widget.callId != null &&
        widget.callId!.isNotEmpty &&
        widget.callId != incomingEndId) return;
    _endCall(notifyOther: true, closeNative: false);
  }

  AudioTrack? _remoteAudioTrack;
  RemoteParticipant? _remoteParticipant;

  @override
  void initState() {
    super.initState();
    if (Platform.isIOS) {
      nativeEndedCallId.addListener(_handleNativeHangup);
    }
    _initLiveKit();

    _timeoutTimer = Timer(const Duration(seconds: 45), () {
      if (!_isRemoteConnected && mounted && !_isEngineReleased) {
        print("⏳ Timeout (Order: ${widget.orderId ?? 'N/A'})");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('السائق لا يرد حاليا'), backgroundColor: Colors.orange),
        );
        _endCall();
      }
    });
  }

  Future<void> _initLiveKit() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted || _isEngineReleased) return;

    final status = await Permission.microphone.request();
    if (!mounted || _isEngineReleased) return;
    if (status.isDenied || status.isPermanentlyDenied) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = "يرجى منح صلاحية المايكروفون من إعدادات الجهاز";
      });
      return;
    }

    try {
      if (Platform.isIOS) {
        final session = await AudioSession.instance;
        await session.configure(AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
          avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth |
          AVAudioSessionCategoryOptions.defaultToSpeaker,
          avAudioSessionMode: AVAudioSessionMode.voiceChat,
          avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
        ));
      }

      if (!mounted || _isEngineReleased) return;
      _room = Room();
      _listener = _room!.createListener();

      // A hangup message is independent of the microphone/audio track state.
      _listener!.on<DataReceivedEvent>((event) {
        if (_isEngineReleased || event.topic != 'beytei_call') return;
        try {
          final message = jsonDecode(utf8.decode(event.data));
          if (message is Map &&
              message['action'] == 'call_ended' &&
              message['room_name']?.toString() == widget.roomName) {
            print('📴 Received LiveKit hangup from remote participant');
            _endCall(notifyOther: false);
          }
        } catch (error) {
          print('⚠️ Invalid LiveKit hangup message: $error');
        }
      });

      _listener!.on<ParticipantConnectedEvent>((event) {
        if (mounted && !_isEngineReleased && !_isRemoteConnected) {
          setState(() {
            _remoteParticipant = event.participant;
          });
          print("✅ الزبون: السائق دخل الغرفة");
        }
      });

      _listener!.on<TrackSubscribedEvent>((event) {
        if (mounted && !_isEngineReleased) {
          _timeoutTimer?.cancel();
          setState(() {
            _isRemoteConnected = true;
            if (event.track is AudioTrack) {
              _remoteAudioTrack = event.track as AudioTrack;
            }
          });
          _startTimer();
          print("✅ الزبون: تم استقبال مسار الصوت");
        }
      });

      _listener!.on<TrackUnsubscribedEvent>((event) {
        if (mounted && event.track is AudioTrack) {
          setState(() {
            _remoteAudioTrack = null;
          });
        }
      });

      _listener!.on<ParticipantDisconnectedEvent>((event) {
        if (!mounted || _isEngineReleased) return;
        print('📴 Remote LiveKit participant left the room');
        _endCall(notifyOther: false);
      });

      _listener!.on<RoomDisconnectedEvent>((event) {
        if (!mounted || _isEngineReleased) return;
        print('📴 LiveKit room disconnected');
        _endCall(notifyOther: false);
      });

      final connectingRoom = _room!;
      await connectingRoom.connect(
        widget.livekitUrl,
        widget.token,
        roomOptions: const RoomOptions(
          adaptiveStream: true,
          dynacast: true,
          defaultAudioPublishOptions: AudioPublishOptions(),
        ),
      );

      if (_isEngineReleased || !mounted) {
        try { await connectingRoom.disconnect(); } catch (_) {}
        return;
      }

      if (mounted) {
        setState(() => _isConnected = true);

        if (_room!.remoteParticipants.isNotEmpty) {
          _timeoutTimer?.cancel();
          setState(() {
            _isRemoteConnected = true;
            _remoteParticipant = _room!.remoteParticipants.values.first;
          });
          _startTimer();
          print("✅ الزبون: السائق موجود مسبقا في الغرفة");
        }

        await _room!.localParticipant?.setMicrophoneEnabled(true);

        await Future.delayed(const Duration(milliseconds: 300));
        try {
          await Hardware.instance.setSpeakerphoneOn(_isSpeaker);
        } catch (e) {
          print("⚠️ فشل تبديل السماعة: $e");
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = "فشل في بدء المكالمة: ${e.toString()}";
        });
      }
    }
  }

  void _startTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _isRemoteConnected) {
        setState(() => _callDuration++);
      }
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _toggleMute() async {
    setState(() => _isMuted = !_isMuted);
    await _room?.localParticipant?.setMicrophoneEnabled(!_isMuted);
  }

  Future<void> _toggleSpeaker() async {
    setState(() => _isSpeaker = !_isSpeaker);
    try {
      await Hardware.instance.setSpeakerphoneOn(_isSpeaker);
    } catch (e) {
      print("⚠️ فشل تبديل السماعة: $e");
    }
  }

  Future<void> _endCall({
    bool notifyOther = true,
    bool closeNative = true,
  }) async {
    // Exactly-once cleanup: native events, LiveKit events and the hangup
    // button can all fire almost simultaneously.
    if (_isEngineReleased) return;
    _isEngineReleased = true;

    // Stop the counters IMMEDIATELY, not after network operations.
    _durationTimer?.cancel();
    _timeoutTimer?.cancel();
    _durationTimer = null;
    _timeoutTimer = null;
    _isConnected = false;
    _isRemoteConnected = false;

    final Room? currentRoom = _room;
    final EventsListener<RoomEvent>? currentListener = _listener;
    _room = null;
    _listener = null;

    // Dismiss the Flutter overlay immediately. Its dispose() sees the
    // cleanup guard and leaves the async LiveKit teardown to this function.
    if (mounted) {
      _lastIncomingCallData = null;
      if (widget.onCallEnded != null) {
        widget.onCallEnded!();
      } else {
        Navigator.of(context).maybePop();
      }
    }

    // Notify a still-connected remote party before leaving the room.
    // They must support this message (the driver's app needs the same logic).
    if (notifyOther && currentRoom?.localParticipant != null) {
      try {
        final message = jsonEncode({
          'action': 'call_ended',
          'room_name': widget.roomName,
          'call_id': widget.callId ?? '',
        });
        await currentRoom!.localParticipant!.publishData(
          utf8.encode(message),
          reliable: true,
          topic: 'beytei_call',
        ).timeout(const Duration(seconds: 2));
        print('✅ LiveKit hangup signal sent');
      } catch (error) {
        print('⚠️ Could not send LiveKit hangup signal: $error');
      }
    }

    try {
      await currentRoom?.localParticipant?.setMicrophoneEnabled(false);
    } catch (error) {
      print('⚠️ Could not mute microphone: $error');
    }

    try {
      await currentRoom?.disconnect();
    } catch (error) {
      print('⚠️ Could not disconnect LiveKit: $error');
    }

    try {
      await currentListener?.dispose();
    } catch (error) {
      print('⚠️ Could not dispose LiveKit listener: $error');
    }

    try {
      await currentRoom?.dispose();
    } catch (error) {
      print('⚠️ Could not dispose LiveKit room: $error');
    }

    // End the native CallKit call only when Flutter started the hangup.
    // If native CallKit initiated it, the native action is already in flight.
    if (Platform.isIOS) {
      if (closeNative &&
          widget.callId != null &&
          widget.callId!.isNotEmpty) {
        try {
          await _nativeCallChannel.invokeMethod(
            'endNativeCall',
            {'callId': widget.callId},
          );
          print('✅ iOS CallKit ended: ${widget.callId}');
        } catch (error) {
          print('⚠️ Could not end iOS CallKit: $error');
        }
      }
    } else {
      try {
        await FlutterCallkitIncoming.endAllCalls();
      } catch (error) {
        print('⚠️ Could not end Android CallKit: $error');
      }
    }

    print('✅ Call, microphone and timers are now ended');
  }

  @override
  void dispose() {
    if (Platform.isIOS) {
      nativeEndedCallId.removeListener(_handleNativeHangup);
    }
    _durationTimer?.cancel();
    _timeoutTimer?.cancel();

    if (!_isEngineReleased) {
      _isEngineReleased = true;
      try {
        _listener?.dispose();
        _room?.disconnect();
      } catch (e) {
        print("Error in dispose: $e");
      }
    }

    // 🔥 على Android فقط: إنهاء المكتبة عند dispose
    // على iOS: Native يتولى الأمر ولا نستدعي المكتبة
    if (Platform.isAndroid) {
      FlutterCallkitIncoming.endAllCalls();
    }

    super.dispose();
  }

  String _getCallStatus() {
    if (_hasError) return _errorMessage;
    if (_isRemoteConnected) return "متصل الآن 🟢";
    if (_isConnected) return "يرن عند السائق... ⏳";
    return "جاري الاتصال بالسيرفر...";
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _endCall();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F2027),
        body: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: _endCall,
                    ),
                    Text(
                      _formatDuration(_callDuration),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isSpeaker ? Icons.volume_up : Icons.volume_off,
                        color: _isSpeaker ? Colors.green : Colors.white70,
                        size: 28,
                      ),
                      onPressed: _toggleSpeaker,
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                    ),
                    child: const CircleAvatar(
                      radius: 70,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, size: 70, color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 25),

                  Text(
                    widget.remoteName,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    "غرفة: ${widget.roomName}",
                    style: const TextStyle(fontSize: 12, color: Colors.yellow),
                  ),
                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      color: _hasError
                          ? Colors.red.withOpacity(0.2)
                          : (_isRemoteConnected ? Colors.green.withOpacity(0.2) : Colors.blue.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: _hasError
                            ? Colors.red
                            : (_isRemoteConnected ? Colors.green : Colors.blue),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _hasError
                              ? Icons.error
                              : (_isRemoteConnected ? Icons.check_circle : Icons.access_time),
                          color: _hasError ? Colors.red : (_isRemoteConnected ? Colors.green : Colors.blue),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _getCallStatus(),
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                            maxLines: 2,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Spacer(flex: 3),

              Container(
                padding: const EdgeInsets.only(bottom: 40, top: 25),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, spreadRadius: 5),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: _toggleMute,
                              child: Container(
                                padding: const EdgeInsets.all(22),
                                decoration: BoxDecoration(
                                  color: _isMuted ? Colors.red.withOpacity(0.2) : Colors.white10,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: _isMuted ? Colors.red : Colors.white70, width: 1.5),
                                ),
                                child: Icon(_isMuted ? Icons.mic_off : Icons.mic, color: _isMuted ? Colors.red : Colors.white, size: 30),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(_isMuted ? "إلغاء الكتم" : "كتم", style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                          ],
                        ),

                        GestureDetector(
                          onTap: _endCall,
                          child: Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.shade400,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 20, spreadRadius: 5),
                              ],
                            ),
                            child: const Icon(Icons.call_end, color: Colors.white, size: 38),
                          ),
                        ),

                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: _toggleSpeaker,
                              child: Container(
                                padding: const EdgeInsets.all(22),
                                decoration: BoxDecoration(
                                  color: _isSpeaker ? Colors.green.withOpacity(0.2) : Colors.white10,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: _isSpeaker ? Colors.green : Colors.white70, width: 1.5),
                                ),
                                child: Icon(_isSpeaker ? Icons.volume_up : Icons.volume_down, color: _isSpeaker ? Colors.green : Colors.white, size: 30),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(_isSpeaker ? "إيقاف السماعة" : "تفعيل السماعة", style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
