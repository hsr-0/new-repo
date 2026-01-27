import 'dart:io';
import 'dart:ui'; // ضروري لالتقاط الأخطاء العميقة
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toastification/toastification.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart'; // مكتبة ماب بوكس

// --- Import your project files ---
import 'package:cosmetic_store/taxi/lib/core/helper/string_format_helper.dart';
import 'package:cosmetic_store/taxi/lib/core/theme/light/light.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/audio_utils.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/my_images.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/util.dart';
import 'package:cosmetic_store/taxi/lib/data/services/running_ride_service.dart';
import 'package:cosmetic_store/taxi/lib/environment.dart';
import 'package:cosmetic_store/taxi/lib/data/services/push_notification_service.dart';
import 'package:cosmetic_store/taxi/lib/core/route/route.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/messages.dart';
import 'package:cosmetic_store/taxi/lib/data/controller/localization/localization_controller.dart';
import 'core/di_service/di_services.dart' as di_service;
import 'data/services/api_client.dart';

// =============================================================================
// 🛠️ أداة كشف الأخطاء (Debug Console) - مدمجة هنا للسهولة
// =============================================================================
final ValueNotifier<List<String>> _globalErrorLogs = ValueNotifier([]);

void _addDebugError(String error, [String? stack]) {
  final timestamp = DateTime.now().toIso8601String().split('T').last.substring(0, 8);
  String fullLog = "⏰ $timestamp\n🔴 ERROR: $error";
  if (stack != null) {
    fullLog += "\n📍 STACK: ${stack.split('\n').take(3).join('\n')}...";
  }
  _globalErrorLogs.value = [fullLog, ..._globalErrorLogs.value];
  debugPrint(fullLog); // طباعة في التيرمينال أيضاً
}

class _DebugConsoleOverlay extends StatefulWidget {
  final Widget child;
  const _DebugConsoleOverlay({required this.child});

  @override
  State<_DebugConsoleOverlay> createState() => _DebugConsoleOverlayState();
}

class _DebugConsoleOverlayState extends State<_DebugConsoleOverlay> {
  bool _isVisible = false; // ابدأ مخفياً لتجنب الإزعاج

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        // زر الإظهار/الإخفاء (يظهر في Debug و Release)
        Positioned(
          bottom: 100,
          left: 20,
          child: Material(
            color: Colors.transparent,
            child: FloatingActionButton(
              heroTag: "debug_btn",
              mini: true,
              backgroundColor: Colors.red.withOpacity(0.8),
              child: Icon(_isVisible ? Icons.close : Icons.bug_report, size: 20),
              onPressed: () => setState(() => _isVisible = !_isVisible),
            ),
          ),
        ),
        // شاشة الأخطاء
        if (_isVisible)
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            height: 300,
            child: Material(
              color: Colors.black.withOpacity(0.85),
              borderRadius: BorderRadius.circular(10),
              child: ValueListenableBuilder<List<String>>(
                valueListenable: _globalErrorLogs,
                builder: (context, logs, _) {
                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red[900],
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("⚠️ سجل الأخطاء", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            InkWell(
                              onTap: () => _globalErrorLogs.value = [],
                              child: const Icon(Icons.delete, color: Colors.white, size: 20),
                            )
                          ],
                        ),
                      ),
                      Expanded(
                        child: logs.isEmpty
                            ? const Center(child: Text("لا توجد أخطاء ✅", style: TextStyle(color: Colors.green)))
                            : ListView.separated(
                          padding: const EdgeInsets.all(8),
                          itemCount: logs.length,
                          separatorBuilder: (_, __) => const Divider(color: Colors.grey),
                          itemBuilder: (context, index) => SelectableText(
                            logs[index],
                            style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontFamily: 'Courier'),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

// =============================================================================
// 🚕 نقطة الدخول الرئيسية (Taxi Entry)
// =============================================================================

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
    _setupErrorHandling(); // تفعيل صائد الأخطاء
    _initTaxiServices();
  }

  // 1. إعداد صائد الأخطاء ليعرضها على الشاشة
  void _setupErrorHandling() {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      _addDebugError(details.exception.toString(), details.stack.toString());
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      _addDebugError(error.toString(), stack.toString());
      return true;
    };
  }

  // 2. تهيئة الخدمات مع حماية Mapbox
  Future<void> _initTaxiServices() async {
    try {
      if (!Get.isRegistered<ApiClient>()) {
        await ApiClient.init();
      }

      _languages = await di_service.init();

      // ✅✅✅ الحماية القصوى: تفعيل Mapbox للأندرويد فقط هنا ✅✅✅
      if (Platform.isAndroid) {
        try {
          MapboxOptions.setAccessToken(Environment.mapKey);
          print("✅ Mapbox Initialized for Android");
        } catch (e) {
          _addDebugError("Mapbox Init Failed: $e");
        }
      }
      // ⛔ لن يتم تشغيل أي كود Mapbox على iOS هنا

      MyUtils.allScreen();
      MyUtils().stopLandscape();
      AudioUtils();

      try {
        if (Get.isRegistered<ApiClient>()) {
          PushNotificationService(apiClient: Get.find()).setupInteractedMessage();
        }
      } catch (e) {
        _addDebugError("Notification Error: $e");
      }

      HttpOverrides.global = MyHttpOverrides();
      RunningRideService.instance.setIsRunning(false);
      tz.initializeTimeZones();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      _addDebugError("Fatal Init Error: $e", stack.toString());
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
      // تغليف التطبيق بـ DebugConsoleOverlay
      return _DebugConsoleOverlay(
        child: OvoApp(languages: _languages!),
      );
    }

    // شاشة التحميل (مع عرض الأخطاء أيضاً في حال الفشل)
    return _DebugConsoleOverlay(
      child: const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.deepPurple),
        ),
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