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

      HttpOverrides.global = MyHttpOverrides();
      RunningRideService.instance.setIsRunning(false);
      tz.initializeTimeZones();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      printX("Error initializing Taxi services: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoading && _languages != null) {
      return OvoApp(languages: _languages!);
    }

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
  // مفتاح للتحكم في الملاحة الداخلية لتطبيق التكسي
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

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

  // دالة لإظهار حوار تأكيد الخروج
  Future<bool> _showExitConfirmationDialog() async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الخروج'),
        content: const Text('هل تريد الخروج من قسم التكسي والعودة  الى الرئيسية؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // لا تخرج
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true), // نعم اخرج
            child: const Text('خروج', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LocalizationController>(
      builder: (localizeController) => ToastificationWrapper(
        config: ToastificationConfig(maxToastLimit: 10),
        // ✅ PopScope للتحكم في زر الرجوع
        child: PopScope(
          canPop: false, // نمنع الخروج التلقائي لنتحكم فيه يدوياً
          onPopInvoked: (didPop) async {
            if (didPop) return;

            // 1. محاولة الرجوع خطوة للوراء داخل تطبيق التكسي
            final NavigatorState? navigator = _navigatorKey.currentState;
            if (navigator != null && navigator.canPop()) {
              navigator.pop();
              return;
            }

            // 2. إذا لم يعد هناك صفحات للرجوع (وصلنا للبداية)، نسأل المستخدم
            final bool shouldExit = await _showExitConfirmationDialog();
            if (shouldExit && context.mounted) {
              // الخروج النهائي من قسم التكسي
              Navigator.of(context).pop();
            }
          },
          child: GetMaterialApp(
            // ✅ ربط مفتاح الملاحة هنا
            navigatorKey: _navigatorKey,
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
          ),
        ),
      ),
    );
  }
}