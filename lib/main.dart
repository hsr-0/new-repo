import 'dart:async';
import 'dart:convert'; // للمعالجة JSON
import 'dart:io';      // لمعرفة نوع النظام Platform
import 'package:http/http.dart' as http; // للتعامل مع الطلبات
import 'package:shared_preferences/shared_preferences.dart'; // لحفظ التوكن محلياً

import 'package:flutter/material.dart';
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

// استيرادات مشروعك الخاصة
import '/custom_code/actions/index.dart' as actions;
import 'backend/firebase/firebase_config.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/internationalization.dart';
import '/flutter_flow/nav/nav.dart';
import 'index.dart';

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

  if (message.data['type'] == 'voip_call') {
    await showIncomingCall(message.data);
  } else {
    _showLocalNotification(message);
  }
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

void _showLocalNotification(RemoteMessage message) {
  final String title = message.data['title'] ?? 'إشعار جديد';
  final String body = message.data['body'] ?? 'لديك رسالة جديدة.';

  const AndroidNotificationDetails androidPlatformChannelSpecifics =
  AndroidNotificationDetails(
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
    payload: message.data.toString(),
  );
}

// =======================================================================
// 🔥 3. دوال إدارة التوكن (الجديدة)
// =======================================================================

// دالة لتحديث التوكن تلقائياً عند التغيير
Future<void> _handleTokenRefresh() async {
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    print("🔄 [FCM] Token refreshed: ${newToken.substring(0, 20)}...");
    await _saveAndRegisterToken(newToken);
  });
}

// دالة لحفظ التوكن وإرساله للسيرفر
Future<void> _saveAndRegisterToken(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('fcm_token', token);

  // إرسال التوكن للسيرفر (حتى لو لم يطلب المستخدم)
  try {
    final response = await http.post(
      Uri.parse(
          'https://re.beytei.com/wp-json/restaurant-app/v1/register-device'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'token': token,
        'platform': Platform.isAndroid ? 'android' : 'ios',
      }),
    );
    if (response.statusCode == 200) {
      print("✅ [FCM] Token registered successfully");
    } else {
      print(
          "⚠️ [FCM] Server responded with status: ${response.statusCode} - ${response.body}");
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

  // تهيئة الفايربيس
  await initFirebase();

  // --- بداية التعديل: التعامل مع التوكن ---
  // 1. الحصول على التوكن الحالي وتسجيله
  try {
    String? initialToken = await FirebaseMessaging.instance.getToken();
    if (initialToken != null) {
      await _saveAndRegisterToken(initialToken);
    }
  } catch (e) {
    print("⚠️ Error fetching initial FCM token: $e");
  }

  // 2. الاستماع لتغيير التوكن (في الخلفية)
  _handleTokenRefresh();
  // --- نهاية التعديل ---

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
    playSound: true,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("🔔 [FCM] Received message in foreground: ${message.data}");
    if (message.data['type'] == 'voip_call') {
      showIncomingCall(message.data);
    } else {
      _showLocalNotification(message);
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    if (message.data['type'] == 'voip_call') {
      showIncomingCall(message.data);
    }
  });

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

    // تشغيل مستمع CallKit عند بدء التطبيق
    _setupCallKitListener();

    _router.routerDelegate.addListener(() {
      if (mounted) setState(() {});
    });
  }

  // --- 🔥 دالة الاستماع لأزرار CallKit 🔥 ---
  void _setupCallKitListener() {
    FlutterCallkitIncoming.onEvent.listen((CallEvent? event) async {
      if (event == null) return;

      if (event.event == Event.actionCallAccept) {
        final data = event.body['extra'];
        final channelName = data['channel_name'];
        final driverName = data['driver_name'];

        final context = _router.routerDelegate.navigatorKey.currentContext;
        if (context != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CustomerCallPage(
                channelName: channelName,
                driverName: driverName,
              ),
            ),
          );
        }
      }
    });
  }

  void setLocale(String language) {
    safeSetState(() => _locale = createLocale(language));
    FFLocalizations.storeLocale(language);
  }

  void setThemeMode(ThemeMode mode) => safeSetState(() {
    _themeMode = mode;
  });

  // ------------------------------------------------------------------
  // ✅✅ الدوال المساعدة للراوتر ✅✅
  // ------------------------------------------------------------------
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
  // ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'منصة بيتي',
      localizationsDelegates: [
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
    );
  }
}

// =======================================================================
// 🔥 6. صفحة المكالمة (CustomerCallPage)
// =======================================================================
class CustomerCallPage extends StatefulWidget {
  final String channelName;
  final String driverName;
  final String agoraAppId = "3924f8eebe7048f8a65cb3bd4a4adcec";

  const CustomerCallPage(
      {super.key, required this.channelName, required this.driverName});

  @override
  State<CustomerCallPage> createState() => _CustomerCallPageState();
}

class _CustomerCallPageState extends State<CustomerCallPage> {
  late RtcEngine _engine;
  bool _localUserJoined = false;
  bool _muted = false;
  bool _speaker = false;

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    await [Permission.microphone].request();

    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(
      appId: widget.agoraAppId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          setState(() => _localUserJoined = true);
        },
        onUserOffline: (connection, remoteUid, reason) {
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text("انتهت المكالمة")));
            Navigator.pop(context);
          }
        },
      ),
    );

    await _engine.enableAudio();
    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine.setEnableSpeakerphone(_speaker);

    await _engine.joinChannel(
      token: "",
      channelId: widget.channelName,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  @override
  void dispose() {
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF202124),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(height: 50),
            Column(
              children: [
                const CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.teal,
                  child: Icon(Icons.person, size: 70, color: Colors.white),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.driverName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  _localUserJoined ? "متصل 00:00" : "جاري الاتصال...",
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() => _muted = !_muted);
                      _engine.muteLocalAudioStream(_muted);
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _muted ? Colors.white : Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _muted ? Icons.mic_off : Icons.mic,
                        color: _muted ? Colors.black : Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                  FloatingActionButton(
                    onPressed: () async {
                      await _engine.leaveChannel();
                      if (mounted) Navigator.pop(context);
                    },
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.call_end, color: Colors.white,
                        size: 35),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() => _speaker = !_speaker);
                      _engine.setEnableSpeakerphone(_speaker);
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _speaker ? Colors.white : Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _speaker ? Icons.volume_up : Icons.volume_off,
                        color: _speaker ? Colors.black : Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}