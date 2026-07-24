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
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:livekit_client/livekit_client.dart' hide ConnectionState, Priority;

import 'beytei_re/OrderTracking.dart';
import 'webview_screen.dart';
import '../beytei_re/re.dart';

import '/custom_code/actions/index.dart' as actions;
import 'backend/firebase/firebase_config.dart';
import '/flutter_flow/flutter_flow_theme.dart';
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

// دالة التوجيه الموحدة
void handleNotificationClick(Map<String, dynamic> data) {
  if (data['type'] == 'voip_call') {
    showIncomingCall(data);
  } else if (data['type'] == 'taxi_chat_message' || data['act'] == 'NEW_MESSAGE') {
    print("🚀 [Routing] توجيه لدردشة التاكسي - الرحلة: ${data['ride_id']}");
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
// 🔥 1. دوال مساعدة لإظهار المكالمة (محدثة لـ LiveKit)
// =======================================================================
Future<void> showIncomingCall(Map<String, dynamic> data) async {
  var uuid = const Uuid();
  String currentUuid = uuid.v4();

  CallKitParams params = CallKitParams(
    id: currentUuid,
    nameCaller: data['driver_name'] ?? 'مندوب بيتي',
    appName: 'منصة بيتي',
    avatar: data['driver_image'] ?? 'https://i.imgur.com/7k12epD.png',
    handle: data['customer_phone'] ?? 'اتصال وارد',
    type: 0,
    duration: 45000,
    textAccept: 'رد',
    textDecline: 'رفض',
    missedCallNotification: const NotificationParams(
      showNotification: true,
      isShowCallback: true,
      subtitle: 'مكالمة فائتة',
      callbackText: 'عاود الاتصال',
    ),
    // 🔥 هنا نمرر بيانات LiveKit الجاهزة (بما فيها الـ Token)
    extra: <String, dynamic>{
      'room_name': data['room_name'],
      'livekit_url': data['livekit_url'],
      'token': data['token'], // 🔥 هذا هو سر حل مشكلة الآيفون
      'driver_name': data['driver_name'],
      'order_id': data['order_id'],
    },
    headers: <String, dynamic>{'apiKey': 'Abc@123!', 'platform': 'flutter'},
    android: const AndroidParams(
      isCustomNotification: true,
      isShowLogo: false,
      ringtonePath: 'system_ringtone_default',
      backgroundColor: '#0955fa',
      actionColor: '#4CAF50',
      incomingCallNotificationChannelName: "مكالمات المندوب",
    ),
    ios: const IOSParams(
      iconName: 'CallKitLogo',
      handleType: '',
      supportsVideo: true,
      maximumCallGroups: 2,
      maximumCallsPerCallGroup: 1,
      audioSessionMode: 'default',
      audioSessionActive: true,
      audioSessionPreferredSampleRate: 44100.0,
      audioSessionPreferredIOBufferDuration: 0.005,
      supportsDTMF: true,
      supportsHolding: true,
      supportsGrouping: false,
      supportsUngrouping: false,
      ringtonePath: 'system_ringtone_default',
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

  if (message.data['type'] == 'cancel_call') {
    await FlutterCallkitIncoming.endAllCalls();
    return;
  }

  if (message.data['type'] == 'voip_call') {
    await showIncomingCall(message.data);
  }
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void _showLocalNotification(RemoteMessage message) {
  if (message.data['type'] == 'voip_call') return;

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
        print("🍏 [Apple PushKit] تم التقاط توكن المكالمات بنجاح");
      }
    } catch (e) {
      print("⚠️ فشل جلب توكن VoIP: $e");
    }
  }
}

// =======================================================================
// 🔥 3. استراتيجية الأذونات
// =======================================================================
Future<void> requestLocationPermissionOnly() async {
  print("🔐 التحقق من إذن الموقع...");
  final status = await Permission.location.status;

  if (!status.isGranted && !status.isPermanentlyDenied) {
    print("🔍 جاري طلب إذن الموقع...");
    await Permission.location.request();
  }
  _fetchLocationInBackground();
}

void _fetchLocationInBackground() async {
  try {
    print("📍 [الخلفية] جاري تحديد الموقع بصمت...");
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );
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

  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    print("🔔 [FCM] Received message in foreground");

    if (message.data['type'] == 'cancel_call') {
      await FlutterCallkitIncoming.endAllCalls();
      return;
    }

    if (message.data['type'] == 'voip_call') {
      showIncomingCall(message.data);
    } else {
      _showLocalNotification(message);
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    handleNotificationClick(message.data);
  });

  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    print("🚀 تم فتح التطبيق من إشعار وهو مغلق تماماً!");
    handleNotificationClick(initialMessage.data);
  }

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
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _router.routerDelegate.addListener(() {
        if (mounted) setState(() {});
      });
    });
  }

  Future<void> _checkTerminatedCall() async {
    try {
      var calls = await FlutterCallkitIncoming.activeCalls();
      if (calls is List && calls.isNotEmpty) {
        print("🚀 [App Launch] مكالمة نشطة موجودة! سيتم العرض فوراً...");
        activeCallNotifier.value = Map<String, dynamic>.from(calls.first);
      }
    } catch (e) {
      print("⚠️ Error checking active calls: $e");
    }
  }

  void _setupCallKitListener() {
    FlutterCallkitIncoming.onEvent.listen((CallEvent? event) async {
      if (event == null) return;

      switch (event.event) {
        case Event.actionCallAccept:
          print("✅ [CallKit] تم الضغط على رد...");
          activeCallNotifier.value = event.body ?? {};
          break;

        case Event.actionCallDecline:
        case Event.actionCallEnded:
        case Event.actionCallTimeout:
          print("❌ [CallKit] المكالمة انتهت أو رُفضت.");
          await FlutterCallkitIncoming.endAllCalls();
          activeCallNotifier.value = null;
          break;

        default:
          break;
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
      'driverName': extraData['driver_name']?.toString() ?? rawData['driver_name']?.toString() ?? 'كابتن بيتي',
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
                  if (callData == null) return const SizedBox.shrink();

                  final extractedData = _extractCallData(callData);

                  // 🔥 التحقق من وجود البيانات الأساسية قبل فتح الشاشة
                  if (extractedData['roomName']!.isEmpty || extractedData['token']!.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return ActiveVoiceCallScreen(
                    roomName: extractedData['roomName']!,
                    livekitUrl: extractedData['livekitUrl']!,
                    token: extractedData['token']!,
                    remoteName: extractedData['driverName']!,
                    onCallEnded: () {
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
// 🔥 6. شاشة المكالمة (محدثة بالكامل لـ LiveKit)
// =======================================================================
class ActiveVoiceCallScreen extends StatefulWidget {
  final String roomName;
  final String livekitUrl;
  final String token;
  final String remoteName;
  final VoidCallback onCallEnded;

  const ActiveVoiceCallScreen({
    super.key,
    required this.roomName,
    required this.livekitUrl,
    required this.token,
    required this.remoteName,
    required this.onCallEnded,
  });

  @override
  State<ActiveVoiceCallScreen> createState() => _ActiveVoiceCallScreenState();
}

class _ActiveVoiceCallScreenState extends State<ActiveVoiceCallScreen> {
  Room? _room;
  EventsListener<RoomEvent>? _listener; // 🆕 المستمع الجديد لنسخة LiveKit الحديثة

  bool _localUserJoined = false;
  bool _isDriverConnected = false; // لمعرفة هل السائق دخل الغرفة

  bool _isMuted = false;
  bool _isSpeaker = true;

  int _callDuration = 0;
  Timer? _durationTimer;
  Timer? _timeoutTimer;

  bool _hasError = false;
  String _errorMessage = "";
  bool _isEngineReleased = false;

  @override
  void initState() {
    super.initState();
    _initLiveKit();

    // إغلاق المكالمة تلقائياً بعد 45 ثانية إذا لم يرد السائق
    _timeoutTimer = Timer(const Duration(seconds: 45), () {
      if (!_isDriverConnected && !_isEngineReleased) {
        print("⏳ انتهى الوقت ولم يتم الاتصال بالسائق، جاري إنهاء المكالمة.");
        _endCall();
      }
    });
  }

  Future<void> _initLiveKit() async {
    final status = await Permission.microphone.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = "يرجى منح صلاحية المايكروفون في إعدادات الجهاز";
        });
      }
      return;
    }

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

    try {
      _room = Room();
      _listener = _room!.createListener();

      // 1. مستمع دخول الطرف الآخر
      _listener!.on<ParticipantConnectedEvent>((event) {
        if (mounted && !_isEngineReleased && !_isDriverConnected) {
          _timeoutTimer?.cancel();
          setState(() => _isDriverConnected = true);
          _startTimer();
          print("✅ الزبون: السائق دخل الغرفة");
        }
      });

      // 2. 🔥 مستمع استقبال الصوت (الأهم لمنع التعليق)
      _listener!.on<TrackSubscribedEvent>((event) {
        if (mounted && !_isEngineReleased && !_isDriverConnected) {
          _timeoutTimer?.cancel();
          setState(() => _isDriverConnected = true);
          _startTimer();
          print("✅ الزبون: تم استقبال مسار الصوت من السائق");
        }
      });

      _listener!.on<ParticipantDisconnectedEvent>((event) {
        if (mounted && _localUserJoined && !_isEngineReleased) {
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

      // الاتصال بالغرفة
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
        setState(() => _localUserJoined = true);

        // 3. 🔥 الفحص الفوري (الحل السحري لمشكلة السباق الزمني)
        // إذا كان السائق قد دخل الغرفة قبل أن نجهز المستمعين، نكتشفه فوراً هنا
        if (_room!.remoteParticipants.isNotEmpty) {
          setState(() => _isDriverConnected = true);
          _timeoutTimer?.cancel();
          _startTimer();
          print("✅ الزبون: السائق موجود مسبقاً في الغرفة (فحص فوري)");
        }

        await _room!.localParticipant?.setMicrophoneEnabled(true);
        await Hardware.instance.setSpeakerphoneOn(_isSpeaker);
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
      if (mounted && _isDriverConnected) {
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
    await Hardware.instance.setSpeakerphoneOn(_isSpeaker); // 🆕 الطريقة الحديثة
  }

  void _endCall() async {
    if (_isEngineReleased) return;
    _isEngineReleased = true;

    _durationTimer?.cancel();
    _timeoutTimer?.cancel();

    try {
      await _listener?.dispose(); // 🆕 تنظيف المستمع بالطريقة الجديدة
      await _room?.disconnect();
      _room = null;
    } catch (e) {
      print("Error releasing LiveKit room: $e");
    }

    await FlutterCallkitIncoming.endAllCalls();
    if (mounted) {
      widget.onCallEnded();
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
    if (_isDriverConnected) return "متصل الآن 🟢";
    if (_localUserJoined) return "جاري الاتصال بالكابتن... ⏳";
    return "تهيئة الاتصال...";
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _endCall();
        return false;
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
                    child: CircleAvatar(
                      radius: 70,
                      backgroundColor: Colors.grey.shade800,
                      child: const Icon(Icons.local_taxi, size: 70, color: Colors.white70),
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
                          : (_isDriverConnected ? Colors.green.withOpacity(0.2) : Colors.blue.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: _hasError
                            ? Colors.red
                            : (_isDriverConnected ? Colors.green : Colors.blue),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _hasError
                              ? Icons.error
                              : (_isDriverConnected ? Icons.check_circle : Icons.access_time),
                          color: _hasError ? Colors.red : (_isDriverConnected ? Colors.green : Colors.blue),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getCallStatus(),
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                          maxLines: 2,
                          textAlign: TextAlign.center,
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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: _toggleMute,
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: _isMuted ? Colors.red.withOpacity(0.2) : Colors.white10,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: _isMuted ? Colors.red : Colors.white70, width: 1.5),
                                  ),
                                  child: Icon(_isMuted ? Icons.mic_off : Icons.mic, color: _isMuted ? Colors.red : Colors.white, size: 28),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(_isMuted ? "إلغاء الكتم" : "كتم",
                                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        Expanded(
                          child: GestureDetector(
                            onTap: _endCall,
                            child: Container(
                              padding: const EdgeInsets.all(26),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.shade400,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 20, spreadRadius: 5),
                                ],
                              ),
                              child: const Icon(Icons.call_end, color: Colors.white, size: 36),
                            ),
                          ),
                        ),

                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: _toggleSpeaker,
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: _isSpeaker ? Colors.green.withOpacity(0.2) : Colors.white10,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: _isSpeaker ? Colors.green : Colors.white70, width: 1.5),
                                  ),
                                  child: Icon(_isSpeaker ? Icons.volume_up : Icons.volume_down, color: _isSpeaker ? Colors.green : Colors.white, size: 28),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(_isSpeaker ? "إيقاف السماعة" : "تفعيل السماعة",
                                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
