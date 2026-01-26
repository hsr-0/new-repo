import 'dart:io';
import 'package:cosmetic_store/taxi/lib/core/helper/string_format_helper.dart';
import 'package:cosmetic_store/taxi/lib/core/theme/light/light.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/audio_utils.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/my_images.dart';

import 'package:cosmetic_store/taxi/lib/core/utils/util.dart';
import 'package:flutter/material.dart';
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

class TaxiAppEntry extends StatefulWidget {
  const TaxiAppEntry({super.key});

  @override
  State<TaxiAppEntry> createState() => _TaxiAppEntryState();
}

class _TaxiAppEntryState extends State<TaxiAppEntry> {
  // ❌ أزلنا static: لكي يتم تصفير المتغيرات عند كل دخول جديد
  Map<String, Map<String, String>>? _languages;

  // متغير بسيط للتحكم في شاشة التحميل الحالية
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // ✅ دائماً نستدعي دالة التهيئة عند الدخول (بدون شروط)
    _initTaxiServices();
  }

  Future<void> _initTaxiServices() async {
    try {
      // 1. تهيئة الـ API Client (نتأكد من عدم وجوده أولاً لتجنب التكرار)
      if (!Get.isRegistered<ApiClient>()) {
        await ApiClient.init();
      }

      // 2. تحميل اللغات وحقن الـ Controllers (هذا هو السطر الذي يمنع الانهيار)
      // سيقوم هذا السطر بإعادة إنشاء LocalizationController المفقود
      _languages = await di_service.init();

      // UI Config
      MyUtils.allScreen();
      MyUtils().stopLandscape();
      AudioUtils();

      // Setup Notifications
      try {
        if (Get.isRegistered<ApiClient>()) {
          PushNotificationService(apiClient: Get.find()).setupInteractedMessage();
        }
      } catch (e) {
        printX("Notification Error: $e");
      }

      // HTTP Overrides
      HttpOverrides.global = MyHttpOverrides();

      // Reset ride status
      RunningRideService.instance.setIsRunning(false);

      // Timezones
      tz.initializeTimeZones();

      // ✅ تم التحميل: نخفي شاشة التحميل ونعرض التطبيق
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      printX("Error initializing Taxi services: $e");
      // في حالة الخطأ، نفتح التطبيق لتجنب التعليق
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ إذا انتهى التحميل والبيانات موجودة، اعرض التطبيق
    if (!_isLoading && _languages != null) {
      return OvoApp(languages: _languages!);
    }

    // شاشة التحميل (CircularProgressIndicator) كما طلبت تماماً
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: Colors.deepPurple),
      ),
    );
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => false;
  }
}

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
    try {
      MyUtils.precacheImagesFromPathList(context, [
        MyImages.backgroundImage,
        MyImages.logoWhite,
        MyImages.noDataImage
      ]);
    } catch (e) {
      printX("Image cache error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LocalizationController>(
      builder: (localizeController) => ToastificationWrapper(
        config: ToastificationConfig(maxToastLimit: 10),
        child: GetMaterialApp(
          // key: GlobalKey(debugLabel: 'TaxiAppKey'),
          title: Environment.appName,
          debugShowCheckedModeBanner: false,
          theme: lightThemeData,
          defaultTransition: Transition.fadeIn,
          transitionDuration: const Duration(milliseconds: 300),
          // ✅ سيبدأ دائماً من شاشة السبلاش (كأول مرة)
          initialRoute: RouteHelper.splashScreen,
          getPages: RouteHelper().routes,
          locale: localizeController.locale,
          translations: Messages(languages: widget.languages),
          fallbackLocale: Locale(
            localizeController.locale.languageCode,
            localizeController.locale.countryCode,
          ),
          // يمنع الخروج الكامل من التطبيق عند الرجوع
          popGesture: true,
        ),
      ),
    );
  }
}
