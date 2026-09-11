import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audio_session/audio_session.dart';
import 'package:cosmetic_store/taxi/lib/presentation/screens/inbox/ride_message_screen.dart';
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
// 🔥 متغير عالمي لحفظ بيانات آخر مكالمة واردة (لمنع فقدان البيانات عند الرد)
// =======================================================================
Map<String, dynamic>? _lastIncomingCallData;

// =======================================================================
// 🔥 دوال مساعدة للتحقق من نوع الرسالة (تقبل النص والرقم)
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
// 🔥 1. دوال مساعدة لإظهار المكالمة (مصححة باستخدام CallKitParams)
// =======================================================================
Future<void> showIncomingCall(Map<String, dynamic> data) async {
  // ✅ حفظ البيانات في الذاكرة المؤقتة فوراً لضمان عدم فقدانها عند الضغط على "رد"
  _lastIncomingCallData = data;

  var uuid = const Uuid();
  String currentUuid = uuid.v4();

  final String driverName = data['driver_name'] ?? data['nameCaller'] ?? 'مندوب بيتي';
  final String driverPhone = data['driver_phone'] ?? data['handle'] ?? 'اتصال وارد';
  final String driverImage = data['driver_image'] ?? data['avatar'] ?? 'https://i.imgur.com/7k12epD.png';
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
      // ✅ إضافات حاسمة لإجبار أندرويد على إظهار الشاشة الكاملة وإيقاظ الجهاز
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

  await FlutterCallkitIncoming.showCallkitIncoming(params);
}

// =======================================================================
// 🔥 2. معالج الخلفية
// =======================================================================
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("🔥 [Background] Handling a background message: ${message.messageId}");
  print("🔥 [Background] Data: ${message.data}");

  if (isCancelCall(message.data)) {
    print("❌ [Background] Cancel call received");
    await FlutterCallkitIncoming.endAllCalls();
    return;
  }

  if (isVoipCall(message.data)) {
    print("📞 [Background] VoIP call received - showing incoming call");
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
        print("🍏 [Apple PushKit] تم التقاط توكن المكالمات بنجاح: $voipToken");
      }
    } catch (e) {
      print("⚠️ فشل جلب توكن VoIP: $e");
    }
  }
}

// =======================================================================
// 🔥 3. استراتيجية الأذونات (معدلة لمنع التوقف)
// =======================================================================
Future<void> requestLocationPermissionOnly() async {
  print("🔐 التحقق من حالة الـ GPS...");
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    print("⚠️ خدمة الموقع (GPS) مغلقة. سيتم تجاوز الطلب لمنع توقف التطبيق.");
    return; // ✅ يمنع تجميد التطبيق عندما يكون الموقع مغلقاً
  }

  print("🔐 التحقق من إذن الموقع...");
  final status = await Permission.location.status;

  if (!status.isGranted && !status.isPermanentlyDenied) {
    print("🔍 جاري طلب إذن الموقع...");
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
        timeLimit: const Duration(seconds: 5), // ✅ تقليل وقت الانتظار لمنع الـ Crash
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
      print("✅ تم تسجيل دخول الزبون مجهول الهوية في فايربيس بنجاح");
    }
  } catch (e) {
    print("⚠️ خطأ في مصادقة فايربيس: $e");
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
  // ✅ معالجة رسائل FCM في الواجهة الأمامية (مع حماية المكالمة المقبولة)
  // =======================================================================
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    print("🔔 [FCM] Received message in foreground");
    print("🔔 [FCM] Data: ${message.data}");

    if (isCancelCall(message.data)) {
      print("❌ [Foreground] Cancel call received");

      // 🛡️ الحماية الجذرية: تجاهل الإلغاء إذا كانت المكالمة مقبولة بالفعل
      if (activeCallNotifier.value != null) {
        print("🛡️ [PROTECTED] تم تجاهل cancel_call لأن المكالمة مقبولة بالفعل ويحاول الزبون الاتصال!");
        return; // اخرج من الدالة ولا تنفذ endAllCalls
      }

      // إذا لم تكن مقبولة بعد، ألغِ المكالمة بشكل طبيعي
      await FlutterCallkitIncoming.endAllCalls();
      activeCallNotifier.value = null;
      _lastIncomingCallData = null;
      return;
    }

    if (isVoipCall(message.data)) {
      print("📞 [Foreground] VoIP call received");
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
    child: MyApp(),
  ));
}

// =======================================================================
// 🔥 5. التطبيق الرئيسي (MyApp)
// =======================================================================
class MyApp extends StatefulWidget {
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

  @override
  void initState() {
    super.initState();
    _appStateNotifier = AppStateNotifier.instance;
    _router = createRouter(_appStateNotifier);

    _setupCallKitListener();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTerminatedCall();

      FirebaseMessaging.instance.getInitialMessage().then((message) {
        if (message != null) {
          print("🚀 [App Launch] فتح التطبيق من إشعار والتقاط البيانات");
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

  // =======================================================================
  // ✅ التحقق من المكالمات النشطة عند فتح التطبيق (آمن 100%)
  // =======================================================================
  Future<void> _checkTerminatedCall() async {
    try {
      dynamic calls = await FlutterCallkitIncoming.activeCalls();
      if (calls is List && calls.isNotEmpty) {
        print("🚀 [App Launch] مكالمة نشطة موجودة! سيتم العرض فوراً...");
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
  // ✅ معالج الأحداث (آمن، ديناميكي، ويحتوي على شبكة أمان لاسترداد البيانات)
  // =======================================================================
  // =======================================================================
  // ✅ معالج الأحداث (محدث لاستخراج البيانات من CallKitParams بشكل مضمون)
  // =======================================================================
  // =======================================================================
  // ✅ معالج الأحداث (مصحح ليتوافق مع الهيكل الجديد لـ CallEvent)
  // =======================================================================
// =======================================================================
  // ✅ معالج الأحداث (مصحح ليتوافق مع الإصدارات الحديثة من CallKit)
  // =======================================================================
  void _setupCallKitListener() {
    FlutterCallkitIncoming.onEvent.listen((dynamic event) async {
      if (event == null) return;

      print("📞 [CallKit Event] Received: $event");

      String? eventType;
      Map<String, dynamic>? eventData;

      try {
        // 1. تحديد نوع الحدث عن طريق تحويل الكائن إلى نص والبحث عن اسم الكلاس
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
          // دعم احتياطي للإصدارات القديمة جداً
          eventType = event['event']?.toString();
        }

        // 2. استخراج البيانات (extra) بأمان تام
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
          print("⚠️ تعذر استخراج callKitParams، سيتم الاعتماد على البيانات الاحتياطية.");
        }
      } catch (e) {
        print("⚠️ Failed to parse event: $e");
      }

      if (eventType == null) {
        print("⚠️ لم يتم التعرف على نوع الحدث.");
        return;
      }

      print("📞 [CallKit Event] Parsed Type: $eventType");

      // 🚀 شبكة الأمان القصوى: إذا فشل استخراج البيانات، نستخدم المحفوظة سابقاً
      if (eventData == null || eventData.isEmpty || eventData['room_name'] == null) {
        print("♻️ [FALLBACK] يتم الاعتماد الكلي على _lastIncomingCallData");
        eventData = _lastIncomingCallData;
      }

      // 1️⃣ معالجة زر الرد (قبول المكالمة)
      if (eventType == 'Accept' || eventType.contains('actionCallAccept')) {
        print("✅ [CallKit] تم الضغط على رد... جاري فتح الشاشة");

        final mergedData = {
          ...?_lastIncomingCallData, // الأولوية المطلقة للبيانات المحفوظة مسبقاً
          ...?(eventData ?? {}),
        };

        print("🔍 [DEBUG] Room: ${mergedData['room_name']}, Token exists: ${mergedData['token'] != null}");

        // إشعار الواجهة لفتح شاشة المكالمة
        activeCallNotifier.value = mergedData;
      }
      // 2️⃣ معالجة الرفض أو الإنهاء أو انتهاء الوقت
      else if (eventType == 'Decline' || eventType == 'Ended' || eventType == 'Timeout' ||
          eventType.contains('actionCallDecline') || eventType.contains('actionCallEnded') || eventType.contains('actionCallTimeout')) {
        print("❌ [CallKit] المكالمة انتهت أو رُفضت.");
        await FlutterCallkitIncoming.endAllCalls();
        activeCallNotifier.value = null;
        _lastIncomingCallData = null;
      }
    });
  }

  // 🔥 استخراج بيانات المكالمة المحدثة لـ LiveKit
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
      'driverName': extraData['driver_name']?.toString() ?? rawData['driver_name']?.toString() ??
          extraData['nameCaller']?.toString() ?? rawData['nameCaller']?.toString() ?? 'كابتن بيتي',
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

              // 1. المكالمة الصوتية (محدثة لـ LiveKit)
              ValueListenableBuilder<Map<String, dynamic>?>(
                valueListenable: activeCallNotifier,
                builder: (context, callData, _) {
                  // ✅ طباعة تشخيصية للتأكد من عدم إلغاء البيانات فجأة
                  print("🔍 [UI Builder] حالة callData: ${callData == null ? 'فارغة (null)' : 'موجودة وتحتوي على بيانات'}");

                  if (callData == null) return const SizedBox.shrink();

                  final extractedData = _extractCallData(callData);

                  if (extractedData['roomName']!.isEmpty || extractedData['token']!.isEmpty) {
                    print("⚠️ [Call Screen] Missing roomName or token");
                    return const SizedBox.shrink();
                  }

                  print("📞 [Call Screen] ✅ SHOWING SCREEN with room: ${extractedData['roomName']}");

                  return ActiveVoiceCallScreen(
                    roomName: extractedData['roomName']!,
                    livekitUrl: extractedData['livekitUrl']!,
                    token: extractedData['token']!,
                    remoteName: extractedData['driverName']!,
                    onCallEnded: () {
                      print("📞 [Call Screen] Call ended callback triggered");
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
                        print("لم يتم العثور على الطلب محلياً: $e");
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
            ],
          ),
        );
      },
    );
  }
}

// =======================================================================
// 🔥 6. شاشة المكالمة (محدثة بالكامل لـ LiveKit - النسخة المحسنة والآمنة)
// =======================================================================
class ActiveVoiceCallScreen extends StatefulWidget {
  final String roomName;
  final String livekitUrl;
  final String token;
  final String remoteName;
  final String? orderId;
  final VoidCallback? onCallEnded;

  const ActiveVoiceCallScreen({
    super.key,
    required this.roomName,
    required this.livekitUrl,
    required this.token,
    required this.remoteName,
    this.orderId,
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

  AudioTrack? _remoteAudioTrack;
  RemoteParticipant? _remoteParticipant;

  @override
  void initState() {
    super.initState();
    _initLiveKit();

    _timeoutTimer = Timer(const Duration(seconds: 45), () {
      if (!_isRemoteConnected && mounted && !_isEngineReleased) {
        print("⏳ انتهى الوقت ولم يتم الاتصال (Order: ${widget.orderId ?? 'N/A'})");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('السائق لا يرد حالياً'), backgroundColor: Colors.orange),
        );
        _endCall();
      }
    });
  }

  Future<void> _initLiveKit() async {
    // 🚀 تأخير بسيط لضمان ظهور الشاشة قبل طلب المايكروفون (أندرويد 14+)
    await Future.delayed(const Duration(milliseconds: 1200));

    final status = await Permission.microphone.request();
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

      _room = Room();
      _listener = _room!.createListener();

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
          print("✅ الزبون: تم استقبال مسار الصوت (سيُشغَّل تلقائياً)");
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
        if (mounted && _isConnected && !_isEngineReleased) {
          print("📞 الزبون: السائق أنهى المكالمة.");
          _endCall();
        }
      });

      _listener!.on<RoomDisconnectedEvent>((event) {
        if (mounted && !_isEngineReleased) {
          print("⚠️ الزبون: انقطع الاتصال بالغرفة.");
          _endCall();
        }
      });

      await _room!.connect(
        widget.livekitUrl,
        widget.token,
        roomOptions: const RoomOptions(
          adaptiveStream: true,
          dynacast: true,
          defaultAudioPublishOptions: AudioPublishOptions(),
        ),
      );

      if (mounted) {
        setState(() => _isConnected = true);

        // ✅✅✅ الإصلاح الحاسم: استخدام .values.first لأن remoteParticipants هي Map
        if (_room!.remoteParticipants.isNotEmpty) {
          _timeoutTimer?.cancel();
          setState(() {
            _isRemoteConnected = true;
            _remoteParticipant = _room!.remoteParticipants.values.first;
          });
          _startTimer();
          print("✅ الزبون: السائق موجود مسبقاً في الغرفة (فحص فوري)!");
        }

        await _room!.localParticipant?.setMicrophoneEnabled(true);

        await Future.delayed(const Duration(milliseconds: 300));
        try {
          await Hardware.instance.setSpeakerphoneOn(_isSpeaker);
        } catch (e) {
          print("⚠️ تحذير: فشل في تبديل السماعة تلقائياً: $e");
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

  void _endCall() async {
    if (_isEngineReleased) return;
    _isEngineReleased = true;

    _durationTimer?.cancel();
    _timeoutTimer?.cancel();

    try {
      await _listener?.dispose();
      await _room?.disconnect();
      _room = null;
    } catch (e) {
      print("Error releasing LiveKit room: $e");
    }

    await FlutterCallkitIncoming.endAllCalls();

    if (mounted) {
      if (widget.onCallEnded != null) {
        widget.onCallEnded!();
      } else {
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
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

    FlutterCallkitIncoming.endAllCalls();
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
