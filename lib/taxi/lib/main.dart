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