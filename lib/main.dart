import 'dart:async';
import 'dart:convert'; // للمعالجة JSON
import 'dart:io';      // لمعرفة نوع النظام Platform
import 'package:http/http.dart' as http; // للتعامل مع الطلبات
import 'package:shared_preferences/shared_preferences.dart'; // لحفظ التوكن محلياً

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:uuid/uuid.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:easy_debounce/easy_debounce.dart';

// ✅ 1. مكتبة فيسبوك هنا
import 'package:facebook_app_events/facebook_app_events.dart';

// استيرادات مشروعك الخاصة
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

// دالة التوجيه الموحدة (تعمل عند الضغط على الإشعار من أي مكان)
void handleNotificationClick(Map<String, dynamic> data) {
  if (data['type'] == 'voip_call') {
    showIncomingCall(data);
  } else if (data['type'] == 'chat_message') {
    print("🚀 [Routing] توجيه مباشر إلى شاشة الدردشة!");
    activeChatNotifier.value = data;
  } else if (data['type'] == 'status_update' || data['type'] == 'driver_assigned' || data['type'] == 'new_order') {
    print("🚀 [Routing] توجيه مباشر إلى شاشة تتبع الطلب!");
    activeTrackingNotifier.value = data;
  }
}

// =======================================================================
// 🔥 1. دوال مساعدة لإظهار المكالمة
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
    extra: <String, dynamic>{
      'channel_name': data['channel_name'],
      'driver_name': data['driver_name'],
      'order_id': data['order_id'],
      'agora_app_id': data['agora_app_id'] ?? '3924f8eebe7048f8a65cb3bd4a4adcec',
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
// 🔥 2. معالج الخلفية (Background Handler)
// =======================================================================
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("🔥 [Background] Handling a background message: ${message.messageId}");

  if (message.data['type'] == 'cancel_call') {
    await FlutterCallkitIncoming.endAllCalls();
    return;
  }

  // 🛡️ هذا هو نفس الفرز في الكود القديم الخاص بك 100%
  if (message.data['type'] == 'voip_call') {
    await showIncomingCall(message.data);
  } else {
    _showLocalNotification(message);
  }
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void _showLocalNotification(RemoteMessage message) {
  // إضافة حماية إضافية
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
    // حفظ البيانات ليتم توجيه المستخدم عند الضغط
    payload: jsonEncode(message.data),
  );
}

// =======================================================================
// 🔥 3. دوال إدارة التوكن
// =======================================================================

Future<void> _handleTokenRefresh() async {
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    print("🔄 [FCM] Token refreshed: ${newToken.substring(0, 20)}...");
    await _saveAndRegisterToken(newToken);
  });
}

Future<void> _saveAndRegisterToken(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('fcm_token', token);

  try {
    final response = await http.post(
      Uri.parse('https://re.beytei.com/wp-json/restaurant-app/v1/register-device'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'token': token,
        'platform': Platform.isAndroid ? 'android' : 'ios',
      }),
    );
    if (response.statusCode == 200) {
      print("✅ [FCM] Token registered successfully");
    } else {
      print("⚠️ [FCM] Server responded with status: ${response.statusCode}");
    }
  } catch (e) {
    print("⚠️ [FCM] Failed to register token: $e");
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

    // 🛡️ نفس أسلوبك القديم في المعالجة
    if (message.data['type'] == 'voip_call') {
      showIncomingCall(message.data);
    } else {
      _showLocalNotification(message);
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    // توجيه الإشعارات من الخلفية
    handleNotificationClick(message.data);
  });

  // معالجة فتح التطبيق من الإشعار وهو مغلق تماماً
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    print("🚀 تم فتح التطبيق من إشعار وهو مغلق تماماً!");
    handleNotificationClick(initialMessage.data);
  }

  await actions.connected();
  await actions.notificationPermission();
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
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.data['type'] == 'cancel_call') {
        if (mounted) {
          activeCallNotifier.value = null;
        }
      }
    });

    _router.routerDelegate.addListener(() {
      if (mounted) setState(() {});
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
      'channelName': extraData['channelName']?.toString() ?? extraData['channel_name']?.toString() ?? rawData['channel_name']?.toString() ?? '',
      'driverName': extraData['driverName']?.toString() ?? extraData['driver_name']?.toString() ?? rawData['driver_name']?.toString() ?? 'كابتن بيتي',
      'appId': extraData['agoraAppId']?.toString() ?? extraData['agora_app_id']?.toString() ?? rawData['agora_app_id']?.toString() ?? '3924f8eebe7048f8a65cb3bd4a4adcec',
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
    final RouteMatch lastMatch =
        routeMatch ?? _router.routerDelegate.currentConfiguration.last;
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

      // 🔥 سحر الـ Overlay: رسم المكالمة والدردشة والتتبع فوق التطبيق بالكامل
      builder: (context, child) {
        return Scaffold(
          body: Stack(
            children: [
              if (child != null) child,

              // 1. الاستماع لحالة المكالمة
              ValueListenableBuilder<Map<String, dynamic>?>(
                valueListenable: activeCallNotifier,
                builder: (context, callData, _) {
                  if (callData == null) return const SizedBox.shrink();

                  final extractedData = _extractCallData(callData);

                  if (extractedData['channelName']!.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return ActiveVoiceCallScreen(
                    channelName: extractedData['channelName']!,
                    remoteName: extractedData['driverName']!,
                    agoraAppId: extractedData['appId']!,
                    onCallEnded: () {
                      activeCallNotifier.value = null;
                    },
                  );
                },
              ),

              // 2. الاستماع لفتح الدردشة المباشرة
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

              // 3. الاستماع لفتح شاشة تتبع الطلب المباشرة
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
            ],
          ),
        );
      },
    );
  }
}

// =======================================================================
// 🔥 6. شاشة المكالمة الصوتية المحدثة (ActiveVoiceCallScreen)
// =======================================================================
class ActiveVoiceCallScreen extends StatefulWidget {
  final String channelName;
  final String remoteName;
  final String agoraAppId;
  final VoidCallback onCallEnded;

  const ActiveVoiceCallScreen({
    super.key,
    required this.channelName,
    required this.remoteName,
    required this.onCallEnded,
    this.agoraAppId = "3924f8eebe7048f8a65cb3bd4a4adcec",
  });

  @override
  State<ActiveVoiceCallScreen> createState() => _ActiveVoiceCallScreenState();
}

class _ActiveVoiceCallScreenState extends State<ActiveVoiceCallScreen> {
  late RtcEngine _engine;
  bool _localUserJoined = false;
  int? _remoteUid;

  bool _isMuted = false;
  bool _isSpeaker = false;

  int _callDuration = 0;
  Timer? _durationTimer;
  Timer? _timeoutTimer;

  bool _hasError = false;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _initAgora();

    _timeoutTimer = Timer(const Duration(seconds: 30), () {
      if (_remoteUid == null) {
        print("⏳ انتهى الوقت ولم يتم الاتصال بالسائق، جاري إنهاء المكالمة.");
        _endCall();
      }
    });
  }

  Future<void> _initAgora() async {
    final status = await Permission.microphone.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      setState(() {
        _hasError = true;
        _errorMessage = "يرجى منح صلاحية المايكروفون في إعدادات الجهاز";
      });
      return;
    }

    try {
      _engine = createAgoraRtcEngine();
      await _engine.initialize(RtcEngineContext(
        appId: widget.agoraAppId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      _engine.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          if (mounted) {
            setState(() => _localUserJoined = true);
            _engine.setEnableSpeakerphone(_isSpeaker);
          }
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          if (mounted && !_hasError) {
            _timeoutTimer?.cancel();
            setState(() {
              _remoteUid = remoteUid;
            });
            _startTimer();
          }
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          if (mounted && _localUserJoined) {
            print("📞 الطرف الآخر أنهى المكالمة. جاري الإغلاق التلقائي...");
            _endCall();
          }
        },
        onError: (ErrorCodeType err, String msg) {
          if (mounted && !_hasError) {
            setState(() {
              _hasError = true;
              _errorMessage = "خطأ في الاتصال: $msg";
            });
          }
        },
      ));

      await _engine.enableAudio();
      await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

      const ChannelMediaOptions options = ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishMicrophoneTrack: true,
        autoSubscribeAudio: true,
      );

      await _engine.joinChannel(
        token: "",
        channelId: widget.channelName,
        uid: 0,
        options: options,
      );

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
      if (mounted && _remoteUid != null) {
        setState(() => _callDuration++);
      }
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _showCallEndedDialog(String message) {
    _durationTimer?.cancel();
    _timeoutTimer?.cancel();

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.call_end, color: Colors.red),
              SizedBox(width: 10),
              Text("انتهت المكالمة"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message),
              const SizedBox(height: 10),
              Text("المدة: ${_formatDuration(_callDuration)}",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _endCall();
              },
              child: const Text("موافق", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    _engine.muteLocalAudioStream(_isMuted);
  }

  void _toggleSpeaker() {
    setState(() => _isSpeaker = !_isSpeaker);
    _engine.setEnableSpeakerphone(_isSpeaker);
  }

  void _endCall() async {
    _durationTimer?.cancel();
    _timeoutTimer?.cancel();

    try {
      await _engine.leaveChannel();
      await _engine.release();
    } catch (e) {
      print("Error releasing Agora engine: $e");
    }

    await FlutterCallkitIncoming.endAllCalls();
    widget.onCallEnded();
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _timeoutTimer?.cancel();
    try {
      _engine.leaveChannel();
      _engine.release();
    } catch (e) {
      print("Error in dispose: $e");
    }
    FlutterCallkitIncoming.endAllCalls();
    super.dispose();
  }

  String _getCallStatus() {
    if (_hasError) return _errorMessage;
    if (_remoteUid != null) return "متصل الآن 🟢";
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
                    "رقم الغرفة: ${widget.channelName}",
                    style: const TextStyle(fontSize: 12, color: Colors.yellow),
                  ),
                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      color: _hasError
                          ? Colors.red.withOpacity(0.2)
                          : (_remoteUid != null ? Colors.green.withOpacity(0.2) : Colors.blue.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: _hasError
                            ? Colors.red
                            : (_remoteUid != null ? Colors.green : Colors.blue),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _hasError
                              ? Icons.error
                              : (_remoteUid != null ? Icons.check_circle : Icons.access_time),
                          color: _hasError ? Colors.red : (_remoteUid != null ? Colors.green : Colors.blue),
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
                child: Row(
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
