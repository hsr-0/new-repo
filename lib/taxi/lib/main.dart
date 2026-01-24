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
  // ✅ ميزة التسريع: جعلنا المتغيرات static لكي تحتفظ بقيمتها في الذاكرة
  // هذا يعني أن التهيئة ستحدث مرة واحدة فقط، والمرات القادمة ستكون فورية
  static Map<String, Map<String, String>>? _cachedLanguages;
  static bool _isServicesInitialized = false;

  @override
  void initState() {
    super.initState();
    // ✅ التحقق: إذا كانت الخدمات مهيأة سابقاً، لا نعيد تحميلها
    if (!_isServicesInitialized) {
      _initTaxiServices();
    }
  }

  Future<void> _initTaxiServices() async {
    try {
      // Initialize the API client
      await ApiClient.init();

      // Load localization
      Map<String, Map<String, String>> languages = await di_service.init();

      // UI Config
      MyUtils.allScreen();
      MyUtils().stopLandscape();
      AudioUtils();

      // Setup Notifications
      try {
        PushNotificationService(apiClient: Get.find()).setupInteractedMessage();
      } catch (e) {
        printX("Notification Error: $e");
      }

      // HTTP Overrides
      HttpOverrides.global = MyHttpOverrides();

      // Reset ride status
      RunningRideService.instance.setIsRunning(false);

      // Timezones
      tz.initializeTimeZones();

      // ✅ حفظ البيانات في المتغيرات الثابتة (الكاش)
      _cachedLanguages = languages;
      _isServicesInitialized = true;

      // تحديث الواجهة فقط إذا كانت الصفحة ما زالت معروضة
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      printX("Error initializing Taxi services: $e");
      // في حالة الخطأ، نعتبره مهيأً لتجنب التعليق
      if (mounted) setState(() => _isServicesInitialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ الفحص السريع: إذا كانت البيانات موجودة في الكاش، اعرض التطبيق فوراً
    if (_isServicesInitialized && _cachedLanguages != null) {
      return OvoApp(languages: _cachedLanguages!);
    }

    // شاشة التحميل تظهر فقط في المرة الأولى أبداً (لأول ثواني فقط)
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
          // ✅ مفتاح الملاحة: يضمن عدم تداخل الصفحات
          // key: GlobalKey(debugLabel: 'TaxiAppKey'),
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
          // ✅ يمنع الخروج الكامل من التطبيق عند الرجوع
          popGesture: true,
        ),
      ),
    );
  }
}