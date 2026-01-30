import 'dart:io';
// تأكد من مسارات الاستيراد الخاصة بك، إذا كان هناك خطأ في الاستيراد احذف السطر وأعد استيراده
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

// =========================================================
// 1. نقطة الدخول لقسم التكسي
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
          // ✅ إصلاح: استخدام لون ثابت بدلاً من MyColor المفقود
          child: CircularProgressIndicator(color: Colors.deepPurple),
        ),
      );
    }

    return OvoApp(languages: _languages!);
  }
}

// =========================================================
// 2. تجاوز شهادات الأمان
// =========================================================
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

// =========================================================
// 3. التطبيق الفعلي
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
        // ✅ إصلاح: تعريف المتغير يدوياً لأن الكنترولر لا يحتوي عليه
        bool isRtl = localizeController.locale.languageCode == 'ar';

        return ToastificationWrapper(
          config: const ToastificationConfig(maxToastLimit: 10),

          // ✅ إصلاح: استخدام onPopInvokedWithResult بدلاً من القديمة
          child: PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) return;

              final NavigatorState? navigator = Get.key.currentState;
              if (navigator != null && navigator.canPop()) {
                navigator.pop();
              } else {
                bool shouldExit = await _showExitConfirmationDialog();
                // ✅ إصلاح Async Gap: التحقق من وجود الشاشة قبل استخدام context
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
                      // ✅ استخدام المتغير المعرف بالأعلى
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
                                // ✅ إصلاح: استخدام withValues بدلاً من withOpacity
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