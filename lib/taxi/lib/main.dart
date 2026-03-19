import 'dart:io';
// تأكد من مسارات الاستيراد الخاصة بك، إذا كان هناك خطأ في الاستيراد احذف السطر وأعد استيراده
import 'package:cosmetic_store/taxi/lib/core/helper/string_format_helper.dart';
import 'package:cosmetic_store/taxi/lib/core/theme/light/light.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/audio_utils.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/my_images.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:get/get.dart';
import 'package:cosmetic_store/taxi/lib/data/services/running_ride_service.dart';
import 'package:cosmetic_store/taxi/lib/environment.dart';
import 'package:cosmetic_store/taxi/lib/data/services/push_notification_service.dart';
import 'package:cosmetic_store/taxi/lib/core/route/route.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/messages.dart';
import 'package:cosmetic_store/taxi/lib/data/controller/localization/localization_controller.dart';
import 'package:toastification/toastification.dart';
import 'core/di_service/di_services.dart' as di_service;
import 'data/services/api_client.dart';
import 'package:timezone/data/latest.dart' as tz;

// 🔥 الاستيرادات الجديدة الخاصة بالمكالمات المجانية (CallKit + Agora)
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:uuid/uuid.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

// =========================================================
// 🔥 1. دالة الخلفية (لإيقاظ الهاتف المقفل والرنين)
// =========================================================
@pragma('vm:entry-point')
Future<void> taxiFirebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  // فحص هل الإشعار هو مكالمة صوتية؟
  if (message.data['type'] == 'voip_call') {
    final callId = const Uuid().v4();
    final driverName = message.data['driver_name'] ?? 'كابتن التوصيل';
    final channelName = message.data['channel_name'] ?? '';

    CallKitParams callKitParams = CallKitParams(
      id: callId,
      nameCaller: driverName,
      appName: 'تكسي بيتي',
      handle: 'مكالمة عبر الإنترنت...',
      type: 0, // 0 تعني مكالمة صوتية
      duration: 30000, // الرنين لمدة 30 ثانية
      textAccept: 'رد',
      textDecline: 'رفض',
      extra: <String, dynamic>{
        'channelName': channelName,
        'driverName': driverName,
      },
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default', // رنة الهاتف الأصلية
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

    // إطلاق الرنين الحقيقي
    await FlutterCallkitIncoming.showCallkitIncoming(callKitParams);
  }
}

// =========================================================
// 🔥 2. كلاس إدارة الرد على المكالمات (Call Handler)
// =========================================================
class CallHandlerService {
  static void setupCallKitListener() {
    FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
      if (event == null) return;

      switch (event.event) {
        case Event.actionCallAccept:
        // 📞 الزبون ضغط زر "رد"
          final extra = event.body['extra'];
          final channelName = extra['channelName'];
          final driverName = extra['driverName'];

          // الانتقال الفوري لشاشة المكالمة باستخدام GetX
          Get.to(() => ActiveVoiceCallScreen(
            channelName: channelName,
            remoteName: driverName,
          ));
          break;
        case Event.actionCallDecline:
        // ❌ الزبون ضغط "رفض"
          printX("المكالمة رُفضت من قبل المستخدم");
          break;
        default:
          break;
      }
    });
  }
}


// =========================================================
// 3. نقطة الدخول لقسم التكسي
// =========================================================
class TaxiAppEntry extends StatefulWidget {
  const TaxiAppEntry({super.key});

  @override
  State<TaxiAppEntry> createState() => _TaxiAppEntryState();
}

class _TaxiAppEntryState extends State<TaxiAppEntry> {
  Map<String, Map<String, String>>? _languages;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initTaxiServices();
  }

  Future<void> _initTaxiServices() async {
    try {
      if (!Get.isRegistered<ApiClient>()) {
        await ApiClient.init();
      }

      _languages = await di_service.init();

      MyUtils.allScreen();
      MyUtils().stopLandscape();
      AudioUtils();

      try {
        if (Get.isRegistered<ApiClient>()) {
          PushNotificationService(apiClient: Get.find()).setupInteractedMessage();
        }
      } catch (e) {
        printX("Notification Error: $e");
      }

      // 🔥 تسجيل خدمة الرنين في الخلفية ومستمع الأحداث
      FirebaseMessaging.onBackgroundMessage(taxiFirebaseMessagingBackgroundHandler);
      CallHandlerService.setupCallKitListener();

      HttpOverrides.global = MyHttpOverrides();
      RunningRideService.instance.setIsRunning(false);
      tz.initializeTimeZones();

      if (mounted) setState(() => _isLoading = false);

    } catch (e) {
      printX("Error initializing Taxi services: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _languages == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Colors.deepPurple),
        ),
      );
    }

    return OvoApp(languages: _languages!);
  }
}

// =========================================================
// 4. تجاوز شهادات الأمان
// =========================================================
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

// =========================================================
// 5. التطبيق الفعلي
// =========================================================
class OvoApp extends StatefulWidget {
  final Map<String, Map<String, String>> languages;

  const OvoApp({super.key, required this.languages});

  @override
  State<OvoApp> createState() => _OvoAppState();
}

class _OvoAppState extends State<OvoApp> {

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    MyUtils.precacheImagesFromPathList(context, [
      MyImages.backgroundImage,
      MyImages.logoWhite,
      MyImages.noDataImage
    ]);
  }

  Future<bool> _showExitConfirmationDialog() async {
    return await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            const Icon(Icons.exit_to_app, color: Colors.red),
            const SizedBox(width: 10),
            Text('exit_app'.tr, style: const TextStyle(fontSize: 18)),
          ],
        ),
        content: const Text(
          'هل أنت متأكد من الخروج من قسم التكسي والعودة للصفحة الرئيسية؟',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('no'.tr, style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('yes'.tr),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LocalizationController>(
      builder: (localizeController) {
        bool isRtl = localizeController.locale.languageCode == 'ar';

        return ToastificationWrapper(
          config: const ToastificationConfig(maxToastLimit: 10),

          child: PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) return;

              final NavigatorState? navigator = Get.key.currentState;
              if (navigator != null && navigator.canPop()) {
                navigator.pop();
              } else {
                bool shouldExit = await _showExitConfirmationDialog();
                if (!context.mounted) return;

                if (shouldExit) {
                  Navigator.of(context, rootNavigator: true).pop();
                }
              }
            },
            child: GetMaterialApp(
              title: Environment.appName,
              debugShowCheckedModeBanner: false,
              theme: lightThemeData,
              defaultTransition: Transition.fadeIn,
              transitionDuration: const Duration(milliseconds: 300),
              initialRoute: RouteHelper.splashScreen,
              getPages: RouteHelper().routes,
              locale: localizeController.locale,
              translations: Messages(languages: widget.languages),
              fallbackLocale: Locale(
                localizeController.locale.languageCode,
                localizeController.locale.countryCode,
              ),

              builder: (context, child) {
                return Stack(
                  children: [
                    child ?? const SizedBox(),

                    Positioned(
                      top: 50,
                      left: isRtl ? 20 : null,
                      right: isRtl ? null : 20,
                      child: Material(
                        type: MaterialType.transparency,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 8,
                                spreadRadius: 2,
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

// =========================================================
// 🔥 6. شاشة المكالمة الصوتية (Agora Engine)
// =========================================================
class ActiveVoiceCallScreen extends StatefulWidget {
  final String channelName;
  final String remoteName;

  const ActiveVoiceCallScreen({
    super.key,
    required this.channelName,
    required this.remoteName,
  });

  @override
  State<ActiveVoiceCallScreen> createState() => _ActiveVoiceCallScreenState();
}

class _ActiveVoiceCallScreenState extends State<ActiveVoiceCallScreen> {

  // ⚠️ تنبيه هام: ضع هنا הـ App ID الخاص بك من موقع Agora
  final String appId = "ضع_الاب_ايدي_الخاص_بك_هنا";

  late RtcEngine _engine;
  bool _isJoined = false;
  bool _isMuted = false;
  bool _isSpeaker = false;
  int? _remoteUid;

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    // 1. طلب صلاحية المايكروفون
    await [Permission.microphone].request();

    // 2. تهيئة محرك الصوت
    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    // 3. الاستماع لأحداث المكالمة
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          setState(() => _isJoined = true);
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          setState(() => _remoteUid = remoteUid);
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          // الطرف الآخر أغلق الخط
          _endCall();
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          setState(() => _isJoined = false);
        },
      ),
    );

    // 4. تمكين الصوت والانضمام للغرفة
    await _engine.enableAudio();
    await _engine.setEnableSpeakerphone(_isSpeaker);
    await _engine.joinChannel(
      token: '', // اتركها فارغة إذا لم تقم بتفعيل Security Token في حسابك
      channelId: widget.channelName,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
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
    await _engine.leaveChannel();
    await _engine.release();
    if (mounted) Get.back(); // استخدام Get.back() للخروج من الشاشة
  }

  @override
  void dispose() {
    _endCall();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade900,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            // صورة المتصل
            const CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 20),
            // اسم المتصل
            Text(
              widget.remoteName,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // حالة المكالمة
            Text(
              _remoteUid != null ? '00:00 (متصل)' : (_isJoined ? 'جاري الاتصال...' : 'تهيئة...'),
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const Spacer(),

            // أزرار التحكم
            Container(
              padding: const EdgeInsets.symmetric(vertical: 30),
              decoration: const BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // المايكروفون
                  _buildControlButton(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    color: _isMuted ? Colors.white : Colors.white24,
                    iconColor: _isMuted ? Colors.black : Colors.white,
                    onPressed: _toggleMute,
                  ),
                  // إنهاء المكالمة
                  _buildControlButton(
                    icon: Icons.call_end,
                    color: Colors.red,
                    iconColor: Colors.white,
                    size: 65,
                    onPressed: _endCall,
                  ),
                  // السبيكر
                  _buildControlButton(
                    icon: _isSpeaker ? Icons.volume_up : Icons.volume_down,
                    color: _isSpeaker ? Colors.white : Colors.white24,
                    iconColor: _isSpeaker ? Colors.black : Colors.white,
                    onPressed: _toggleSpeaker,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback onPressed,
    double size = 55,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: size * 0.5),
      ),
    );
  }
}