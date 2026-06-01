// lib/widgets/sections_page_widget.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:version/version.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

// ✅ مكتبة فيسبوك
import 'package:facebook_app_events/facebook_app_events.dart';

// استيراد الشاشات الأخرى
import '../../beytei_re/re.dart';
import '../../chat/chatsupport.dart';
import '../../doctore/medical_home_screen.dart';
import '../../taxi/lib/main.dart';
import '../../zone.dart';
import '../webview_flow/webview_page.dart';

// --- ثوابت التخزين ---
class CacheConstants {
  static const String CACHE_KEY_BANNERS = 'cached_banner_data';
  static const String CACHE_KEY_BANNER_TIME = 'cached_banner_time';
  static const int CACHE_DURATION_HOURS = 6;
}

// --- مدير نافذة الترويج ---
class PromoManager {
  static const String PROMO_TITLE = "🏆 كل ما تطلب أكثر تربح أكثر!";
  static const String PROMO_MESSAGE = "تطبيق منصة بيتي يقدم لك هدايا وجوائز يومية\n\n🎁 الهدية الاسبوعية توزع يوم الجمعة الساعة 8 مساءً\n💰 كل طلب يؤهلك للفوز\n📱 اطلب الآن قبل انتهاء الوقت!";

  static Future<bool> shouldShowPromo() async => true;
}

// 📍 خدمة إدارة الموقع
// =======================================================================
// 📍 خدمة إدارة الموقع المحفوظ (موحدة - متاحة لجميع الشاشات)
// =======================================================================
class LocationService {
  // ✅ مفاتيح موحدة للمشاركة بين التطبيقات (تبدأ بـ shared_)
  static const String LAT_KEY = 'shared_user_latitude';
  static const String LNG_KEY = 'shared_user_longitude';
  static const String LOCATION_SOURCE_KEY = 'shared_location_source';
  static const String LOCATION_TIMESTAMP_KEY = 'shared_location_timestamp';
  static const String AREA_ID_KEY = 'shared_area_id';
  static const String AREA_NAME_KEY = 'shared_area_name';
  static const int LOCATION_MAX_AGE_HOURS = 24;

  /// حفظ الموقع مع مصدره ووقت الحفظ وبيانات المنطقة
  static Future<bool> saveLocation(double lat, double lng, {
    String source = 'auto',
    int? areaId,
    String? areaName,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(LAT_KEY, lat);
      await prefs.setDouble(LNG_KEY, lng);
      await prefs.setString(LOCATION_SOURCE_KEY, source);
      await prefs.setInt(LOCATION_TIMESTAMP_KEY, DateTime.now().millisecondsSinceEpoch);
      if (areaId != null) await prefs.setInt(AREA_ID_KEY, areaId);
      if (areaName != null) await prefs.setString(AREA_NAME_KEY, areaName);
      return true;
    } catch (e) {
      print('❌ Error saving location: $e');
      return false;
    }
  }

  /// جلب الموقع المحفوظ مع التحقق من صلاحيته
  static Future<({double lat, double lng, String source, bool isExpired})?> getSavedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble(LAT_KEY);
      final lng = prefs.getDouble(LNG_KEY);
      final source = prefs.getString(LOCATION_SOURCE_KEY) ?? 'unknown';
      final timestamp = prefs.getInt(LOCATION_TIMESTAMP_KEY);

      if (lat != null && lng != null) {
        bool isExpired = false;
        if (timestamp != null) {
          final age = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(timestamp));
          isExpired = age.inHours > LOCATION_MAX_AGE_HOURS;
        }
        return (lat: lat, lng: lng, source: source, isExpired: isExpired);
      }
      return null;
    } catch (e) {
      print('❌ Error getting location: $e');
      return null;
    }
  }

  /// دالة مبسطة: ترجع الإحداثيات فقط
  static Future<({double lat, double lng})?> getSavedLocationSimple() async {
    final saved = await getSavedLocation();
    if (saved != null) return (lat: saved.lat, lng: saved.lng);
    return null;
  }

  /// التحقق من وجود موقع محفوظ
  static Future<bool> hasSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(LAT_KEY) && prefs.containsKey(LNG_KEY);
  }

  /// حذف الموقع المحفوظ
  static Future<void> clearSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(LAT_KEY);
    await prefs.remove(LNG_KEY);
    await prefs.remove(LOCATION_SOURCE_KEY);
    await prefs.remove(LOCATION_TIMESTAMP_KEY);
    await prefs.remove(AREA_ID_KEY);
    await prefs.remove(AREA_NAME_KEY);
  }

  /// محاولة التحديد التلقائي للموقع (صامت - بدون طلب إذن إذا كان مسموحاً مسبقاً)
  /// محاولة التحديد التلقائي للموقع (صامت - بدون طلب إذن إذا كان مسموحاً مسبقاً)
  /// محاولة التحديد التلقائي للموقع (صامت - بدون طلب إذن إذا كان مسموحاً مسبقاً)
  static Future<geolocator.Position?> tryAutoDetectSilent({Duration timeout = const Duration(seconds: 5)}) async {
    try {
      bool serviceEnabled = await geolocator.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      geolocator.LocationPermission permission = await geolocator.Geolocator.checkPermission();
      if (permission == geolocator.LocationPermission.denied || permission == geolocator.LocationPermission.deniedForever) {
        return null;
      }

      // 🔥 التعديل الجذري: استخدام دقة منخفضة + إجبار الدالة على التوقف بعد 5 ثواني
      geolocator.Position position = await geolocator.Geolocator.getCurrentPosition(
        desiredAccuracy: geolocator.LocationAccuracy.low,
      ).timeout(timeout);

      return position;
    } catch (e) {
      print('❌ Silent auto-detect location failed: $e');
      return null;
    }
  }  /// محاولة التحديد التلقائي مع طلب الإذن (عند الحاجة)
  static Future<geolocator.Position?> tryAutoDetectWithPermission({Duration timeout = const Duration(seconds: 20)}) async {
    try {
      bool serviceEnabled = await geolocator.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      geolocator.LocationPermission permission = await geolocator.Geolocator.checkPermission();
      if (permission == geolocator.LocationPermission.denied) {
        permission = await geolocator.Geolocator.requestPermission();
        if (permission != geolocator.LocationPermission.whileInUse && permission != geolocator.LocationPermission.always) {
          return null;
        }
      }
      if (permission == geolocator.LocationPermission.deniedForever) return null;

      geolocator.Position position = await geolocator.Geolocator.getCurrentPosition(
        desiredAccuracy: geolocator.LocationAccuracy.medium,
        timeLimit: timeout,
      );
      return position;
    } catch (e) {
      print('❌ Auto-detect with permission failed: $e');
      return null;
    }
  }

  /// حساب المسافة بين نقطتين
  static double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    return geolocator.Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }
}
// --- كلاس طلب التقييم ---
class AppReviewManager {
  final InAppReview _inAppReview = InAppReview.instance;

  Future<void> requestReviewIfAppropriate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int appOpenCount = prefs.getInt('appOpenCount') ?? 0;
      bool hasRequestedReview = prefs.getBool('hasRequestedReview') ?? false;

      if (hasRequestedReview) return;
      appOpenCount++;
      await prefs.setInt('appOpenCount', appOpenCount);

      if (appOpenCount >= 5 && await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
        await prefs.setBool('hasRequestedReview', true);
      }
    } catch (e) {
      print('App Review Error: $e');
    }
  }
}

class BannerItem {
  final String imageUrl, targetType, targetUrl;
  BannerItem({required this.imageUrl, required this.targetType, required this.targetUrl});
  factory BannerItem.fromJson(Map<String, dynamic> json) =>
      BannerItem(imageUrl: json['imageUrl'], targetType: json['targetType'], targetUrl: json['targetUrl']);
}

class SectionsPageWidget extends StatefulWidget {
  const SectionsPageWidget({Key? key}) : super(key: key);
  @override
  State<SectionsPageWidget> createState() => _SectionsPageWidgetState();
}

class _SectionsPageWidgetState extends State<SectionsPageWidget> {
  List<BannerItem> banners = [];
  bool showBanners = false;

  // 📍 متغيرات حالة الموقع
  bool _isCheckingLocation = true;
  bool _locationDialogShown = false;
  ({double lat, double lng, String source, bool isExpired})? _savedLocation;
  Timer? _backgroundLocationTimer;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    _backgroundLocationTimer?.cancel();
    super.dispose();
  }

  /// تهيئة التطبيق: الموقع + المهام الخلفية
  Future<void> _initializeApp() async {
    await _checkAndHandleLocation();
    _startBackgroundTasks();
    _startSilentBackgroundLocationUpdates();
  }
  /// 🛡️ التأكد من صلاحية الموقع (تُرجع true إذا كانت الصلاحية متاحة)
  Future<bool> _ensureLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // يمكن هنا تنبيه المستخدم لتشغيل الـ GPS إذا رغبت
      print('ℹ️ خدمات الموقع (GPS) مغلقة');
    }

    LocationPermission permission = await Geolocator.checkPermission();

    // إذا لم يتم طلب الصلاحية من قبل، نطلبها الآن
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // إذا رفض المستخدم الصلاحية نهائياً (Denied Forever)
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        _showSettingsDialog();
      }
      return false;
    }

    return permission == LocationPermission.whileInUse || permission == LocationPermission.always;
  }

  /// ⚙️ عرض رسالة إجبارية تطلب من المستخدم فتح الإعدادات لمنح الصلاحية
  void _showSettingsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // لا يمكن تخطيها
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Row(
            children: [
              Icon(Icons.location_disabled_rounded, color: Colors.red),
              SizedBox(width: 10),
              Text('صلاحية الموقع مطلوبة', style: TextStyle(fontSize: 18)),
            ],
          ),
          content: const Text(
            'التطبيق يعتمد بشكل كامل على موقعك لتقديم خدمات التوصيل وحساب المسافات بدقة. يرجى تفعيل الصلاحية من إعدادات الجهاز للمتابعة.',
            style: TextStyle(height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // يمكن السماح له بالاستمرار للتحديد اليدوي كخيار أخير
              },
              child: const Text('المتابعة بدون موقع', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () async {
                Navigator.of(context).pop();
                await Geolocator.openAppSettings(); // يفتح إعدادات التطبيق مباشرة
              },
              child: const Text('فتح الإعدادات لتفعيل اذن الموقع', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
  /// 📍 المنطق الرئيسي للتحقق من الموقع
  /// 📍 المنطق الرئيسي للتحقق من الموقع والصلاحيات عند الدخول
  /// 📍 المنطق الرئيسي للتحقق من الموقع والصلاحيات عند الدخول
  Future<void> _checkAndHandleLocation() async {
    if (!mounted) return;
    setState(() => _isCheckingLocation = true);

    try {
      // 1. التحقق من الصلاحية أولاً
      bool hasPermission = await _ensureLocationPermission();

      if (hasPermission) {
        // 🔥 الخدعة الذكية: محاولة جلب آخر موقع معروف (فوري ولا يسبب تعليق)
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null && mounted) {
          await LocationService.saveLocation(lastKnown.latitude, lastKnown.longitude, source: 'auto_fast');
          setState(() {
            _savedLocation = (lat: lastKnown.latitude, lng: lastKnown.longitude, source: 'auto_fast', isExpired: false);
          });
          return; // الخروج فوراً للواجهة الرئيسية
        }

        // إذا لم يكن هناك موقع معروف، نجرب التحديد الحي ولكن بمهلة قصيرة جداً (5 ثواني بدل 40)
        final position = await LocationService.tryAutoDetectSilent(timeout: const Duration(seconds: 5));
        if (position != null && mounted) {
          await LocationService.saveLocation(position.latitude, position.longitude, source: 'auto');
          setState(() {
            _savedLocation = (lat: position.latitude, lng: position.longitude, source: 'auto', isExpired: false);
          });
          return;
        }
      }

      // 2. الخطة البديلة: جلب الموقع المحفوظ
      _savedLocation = await LocationService.getSavedLocation();
      if (_savedLocation != null) {
        return;
      }

      // 3. لا يوجد أي موقع -> نجهز نافذة الاختيار اليدوي
      if (mounted && !_locationDialogShown) {
        _locationDialogShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showLocationPickerDialog();
        });
      }
    } catch (e) {
      print('❌ Error in Location Check: $e');
    } finally {
      // 🔥🔥🔥 الحماية القصوى: هذا الكود سيعمل دائماً مهما حدث من أخطاء، وسيزيل شاشة التحميل
      if (mounted) {
        setState(() => _isCheckingLocation = false);
        _startSilentBackgroundLocationUpdates();
      }
    }
  }  /// 🔄 محاولة تحديث الموقع في الخلفية (بدون إزعاج المستخدم)
  Future<void> _tryUpdateLocationInBackground() async {
    if (_savedLocation == null) return;

    // نحاول الحصول على موقع جديد بصمت
    final newPosition = await LocationService.tryAutoDetectSilent();
    if (newPosition != null && mounted) {
      // تحديث الموقع إذا نجح
      await LocationService.saveLocation(
        newPosition.latitude,
        newPosition.longitude,
        source: 'auto',
      );
      setState(() {
        _savedLocation = (
        lat: newPosition.latitude,
        lng: newPosition.longitude,
        source: 'auto',
        isExpired: false,
        );
      });
      print('✅ Location updated in background');
    } else {
      // نحتفظ بالموقع القديم
      print('ℹ️ Keeping old location, background update failed');
    }
  }

  /// ⏰ تحديث الموقع بشكل دوري في الخلفية (كل 5 دقائق مثلاً)
  void _startSilentBackgroundLocationUpdates() {
    _backgroundLocationTimer?.cancel();
    _backgroundLocationTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      if (_savedLocation != null) {
        await _tryUpdateLocationInBackground();
      }
    });
  }

  /// تحديث الموقع في الخلفية (يدوي)
  void _startBackgroundLocationUpdate() {
    _tryUpdateLocationInBackground();
  }

  /// 🗺️ حوار تحديد الموقع الحديث
  /// 🗺️ حوار تحديد الموقع الحديث
  void _showLocationPickerDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.orange, Colors.deepOrange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(23),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(23),
                      topRight: Radius.circular(23),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on_rounded, color: Colors.white, size: 28),
                      SizedBox(width: 10),
                      Text(
                        'تحديد موقع التوصيل',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    children: [
                      const Text(
                        'لتتمكن من عرض أسعار التوصيل الدقيقة واستخدام خدماتنا، يرجى تحديد موقعك الحالي على الخريطة.',
                        style: TextStyle(fontSize: 15, height: 1.6, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 25),
                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                Navigator.pop(ctx);
                                final success = await _handleManualLocationPick();
                                if (!success && mounted) {
                                  // إعادة عرض الحوار إذا فشل
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    if (mounted) _showLocationPickerDialog();
                                  });
                                }
                              },
                              icon: const Icon(Icons.map, color: Colors.orange),
                              label: const Text('اختر من الخريطة', style: TextStyle(color: Colors.orange)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.orange),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                Navigator.pop(ctx); // إغلاق النافذة الحالية
                                setState(() => _isCheckingLocation = true);

                                try {
                                  // 🔥 1. فحص خدمة الـ GPS
                                  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
                                  if (!serviceEnabled) {
                                    setState(() => _isCheckingLocation = false);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('يرجى تشغيل خدمة الـ GPS أولاً.'), backgroundColor: Colors.red)
                                      );
                                      _showLocationPickerDialog(); // إعادة عرض النافذة
                                    }
                                    return;
                                  }

                                  // 🔥 2. فحص الصلاحيات (ستظهر نافذة "الصلاحية مرفوضة" إذا كانت ممنوعة)
                                  bool hasPermission = await _ensureLocationPermission();
                                  if (!hasPermission) {
                                    setState(() => _isCheckingLocation = false);
                                    // إذا رفض الصلاحية، نكتفي بالتوقف لأن دالة _ensureLocationPermission ستعرض نافذة الإعدادات
                                    if (mounted) _showLocationPickerDialog();
                                    return;
                                  }

                                  // 🔥 3. محاولة التقاط الموقع الفعلي
                                  final position = await Geolocator.getCurrentPosition(
                                    desiredAccuracy: LocationAccuracy.medium,
                                    timeLimit: const Duration(seconds: 10),
                                  );

                                  if (mounted) {
                                    await LocationService.saveLocation(
                                      position.latitude,
                                      position.longitude,
                                      source: 'auto',
                                    );
                                    setState(() {
                                      _savedLocation = (
                                      lat: position.latitude,
                                      lng: position.longitude,
                                      source: 'auto',
                                      isExpired: false,
                                      );
                                      _isCheckingLocation = false;
                                    });
                                    _startSilentBackgroundLocationUpdates();
                                  }

                                } catch (e) {
                                  // 🔥 4. في حال فشل الالتقاط (ضعف الإشارة)
                                  setState(() => _isCheckingLocation = false);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('فشل في التقاط الموقع. حاول مرة أخرى أو استخدم التحديد اليدوي.'), backgroundColor: Colors.orange)
                                    );
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      if (mounted) _showLocationPickerDialog();
                                    });
                                  }
                                }
                              },
                              icon: const Icon(Icons.my_location),
                              label: const Text('موقعي الحالي'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          // متابعة بدون موقع (للعرض فقط)
                        },
                        child: const Text(
                          'متابعة لاحقاً',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  /// 🗺️ فتح شاشة اختيار الموقع يدوياً
  Future<bool> _handleManualLocationPick() async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MapLocationPicker(
            mapStyleUrl: 'https://tiles.openfreemap.org/styles/liberty',
            initialLat: _savedLocation?.lat,
            initialLng: _savedLocation?.lng,
          ),
        ),
      );

      if (result != null && result is Map && result['lat'] != null && result['lng'] != null) {
        await LocationService.saveLocation(
          result['lat'],
          result['lng'],
          source: result['source'] ?? 'manual',
        );
        setState(() {
          _savedLocation = (
          lat: result['lat'],
          lng: result['lng'],
          source: result['source'] ?? 'manual',
          isExpired: false,
          );
        });

        // بدء التحديث الصامت في الخلفية بعد الحفظ
        _startSilentBackgroundLocationUpdates();

        return true;
      }
      return false;
    } catch (e) {
      print('❌ Manual location pick error: $e');
      return false;
    }
  }

  // =========================================================================
  // باقي الدوال
  // =========================================================================

  void _startBackgroundTasks() async {
    _requestAllPermissions();
    _loadBannersWithCache();
    _checkForUpdate();
    AppReviewManager().requestReviewIfAppropriate();

    try {
      final facebookAppEvents = FacebookAppEvents();
      await facebookAppEvents.setAdvertiserTracking(enabled: true);
      await facebookAppEvents.logEvent(
        name: 'fb_mobile_activate_app',
        parameters: {'platform': 'flutter_home_screen'},
      );
    } catch (e) {
      print("❌ Facebook SDK Error: $e");
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted && await PromoManager.shouldShowPromo()) {
        _showPromoDialog();
      }
    });
  }

  Future<void> _openSmartSupportChat() async {
    String tName = '', tPhone = '', oName = '', oPhone = '', oId = '';
    try {
      final prefs = await SharedPreferences.getInstance();
      tName = prefs.getString('firstname') ?? '';
      tPhone = prefs.getString('mobile') ?? '';
      // TODO: استرجاع بيانات الطلب من OrderHistoryService عند الحاجة
    } catch (e) {
      print("خطأ في قراءة بيانات الزبون: $e");
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SupportUserChatScreen(
            taxiName: tName,
            taxiPhone: tPhone,
            orderName: oName,
            orderPhone: oPhone,
            orderId: oId,
          ),
        ),
      );
    }
  }

  Future<void> _showPromoDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Colors.deepPurple, Colors.purpleAccent], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(23)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: const BoxDecoration(color: Colors.deepPurple, borderRadius: BorderRadius.only(topLeft: Radius.circular(23), topRight: Radius.circular(23))),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.card_giftcard_rounded, color: Colors.yellow.shade300, size: 60),
                            const SizedBox(height: 10),
                            const Text(PromoManager.PROMO_TITLE, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(25),
                      child: Column(
                        children: [
                          Text(PromoManager.PROMO_MESSAGE, style: TextStyle(fontSize: 16, height: 1.6, color: Colors.grey.shade800), textAlign: TextAlign.center),
                          const SizedBox(height: 25),
                          Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.orange.shade200)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.access_time_filled_rounded, color: Colors.orange.shade700),
                                const SizedBox(width: 10),
                                Text("موعد التوزيع: 8:00 مساءً", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 25, right: 25, bottom: 25),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: BorderSide(color: Colors.grey.shade400)),
                              child: Text('لاحقاً', style: TextStyle(color: Colors.grey.shade700, fontSize: 15, fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const BeyteiZoneScreen()));
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 3),
                              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.rocket_launch_rounded, size: 20), SizedBox(width: 8), Text('ابدأ الفوز', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600))]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 10, left: 10,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5)]), child: Icon(Icons.close_rounded, color: Colors.grey.shade600, size: 20)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestAllPermissions() async {
    if (Platform.isIOS) {
      await FirebaseMessaging.instance.requestPermission();
    }
    final locationStatus = await Permission.location.status;
    if (locationStatus.isDenied) {
      await Permission.location.request();
    }
  }

  Future<void> _checkForUpdate() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.fetchAndActivate();
      final configString = remoteConfig.getString('app_update_config');
      if (configString.isEmpty) return;
      final config = jsonDecode(configString);
      final platformConfig = Platform.isIOS ? config['ios'] : config['android'];
      final minVer = platformConfig['minimum_version'];
      final url = platformConfig['store_url'];
      if (minVer != null && url != null) {
        final current = Version.parse((await PackageInfo.fromPlatform()).version);
        if (current < Version.parse(minVer)) {
          if (mounted) _showUpdateDialog(url);
        }
      }
    } catch (e) {
      print('Update check error: $e');
    }
  }

  void _showUpdateDialog(String updateUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('تحديث إجباري'),
        content: const Text('يرجى تحديث التطبيق للمتابعة.'),
        actions: [
          TextButton(
            child: const Text('تحديث'),
            onPressed: () async {
              final uri = Uri.parse(updateUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          )
        ],
      ),
    );
  }

  Future<void> _loadBannersWithCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(CacheConstants.CACHE_KEY_BANNERS);
    final lastFetchTime = prefs.getInt(CacheConstants.CACHE_KEY_BANNER_TIME);

    if (cachedData != null && lastFetchTime != null) {
      final cacheAge = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(lastFetchTime));
      if (cacheAge < const Duration(hours: CacheConstants.CACHE_DURATION_HOURS)) {
        _processBannerData(cachedData);
        _fetchBannersSilently();
        return;
      }
    }
    _fetchBannersSilently();
  }

  Future<void> _fetchBannersSilently() async {
    try {
      final url = Uri.parse('https://banner.beytei.com/images/banners.json');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(CacheConstants.CACHE_KEY_BANNERS, response.body);
        await prefs.setInt(CacheConstants.CACHE_KEY_BANNER_TIME, DateTime.now().millisecondsSinceEpoch);
        _processBannerData(response.body);
      }
    } catch (e) {
      print("Banner fetch error: $e");
    }
  }

  void _processBannerData(String jsonData) {
    try {
      final jsonMap = json.decode(jsonData);
      if (mounted) {
        setState(() {
          showBanners = jsonMap['showBanners'] ?? false;
          final bannerList = List<Map<String, dynamic>>.from(jsonMap['banners'] ?? []);
          banners = bannerList.map((item) => BannerItem.fromJson(item)).toList();
        });
      }
    } catch (e) {
      print('Banner processing error: $e');
    }
  }

  void _onBannerTapped(BannerItem banner) {
    if (banner.targetType == 'route') {
      GoRouter.of(context).push(banner.targetUrl);
    } else if (banner.targetType == 'webview') {
      Navigator.push(context, MaterialPageRoute(builder: (context) => WebViewPage(url: banner.targetUrl)));
    }
  }

  // 📍 دالة مساعدة لعرض حالة الموقع في الواجهة
  Widget? _buildLocationIndicator() {
    if (_isCheckingLocation) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        child: Row(
          children: [
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 8),
            Text('جاري تحديد موقعك...', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          ],
        ),
      );
    }
    if (_savedLocation != null) {
      String sourceText = _savedLocation!.source == 'manual' ? '(يدوي)' : '(تلقائي)';
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
            const SizedBox(width: 6),
            Text(
              'تم تحديد الموقع ✓ $sourceText',
              style: TextStyle(fontSize: 13, color: Colors.green[700], fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _showLocationPickerDialog,
              icon: const Icon(Icons.edit, size: 14),
              label: const Text('تعديل', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
            ),
          ],
        ),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // 🎯 أثناء التحقق من الموقع: عرض شاشة تحميل أنيقة
    if (_isCheckingLocation) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Colors.orange, Colors.deepOrange]),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 20)],
                ),
                child: const Icon(Icons.location_searching_rounded, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 24),
              const Text(
                'جاري تحديد موقعك...',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'لتوفير أفضل تجربة توصيل',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 30),
              const CircularProgressIndicator(color: Colors.orange),
            ],
          ),
        ),
      );
    }

    // ✅ الواجهة الرئيسية بعد تحديد الموقع
    return Scaffold(
      appBar: AppBar(
        title: const Text('منصة بيتي', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0, top: 10.0, bottom: 10.0, left: 10.0),
            child: InkWell(
              onTap: _openSmartSupportChat,
              borderRadius: BorderRadius.circular(25),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF0083B0).withOpacity(0.4), blurRadius: 8, offset: Offset(0, 3))
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.headset_mic_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 6),
                    Text("الدعم الفني", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadBannersWithCache(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📍 مؤشر حالة الموقع
              if (_buildLocationIndicator() != null) _buildLocationIndicator()!,

              // البانرات
              if (showBanners && banners.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
                  child: Text('العروض المميزة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                CarouselSlider(
                  options: CarouselOptions(height: 180.0, autoPlay: true, enlargeCenterPage: true),
                  items: banners.map((banner) {
                    return Builder(
                      builder: (BuildContext context) => GestureDetector(
                        onTap: () => _onBannerTapped(banner),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.network(
                            banner.imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            loadingBuilder: (context, child, loadingProgress) =>
                            loadingProgress == null ? child : const Center(child: CircularProgressIndicator()),
                            errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.error)),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: Text('خدماتنا', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 10),

              // الشبكة
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildGridCard(
                      context: context,
                      title: 'المطاعم',
                      imagePath: 'assets/images/re.jpg',
                      onTap: () => GoRouter.of(context).push('/restaurants-store'),
                    ),
                    _buildGridCard(
                      context: context,
                      title: 'تكسي بيتي',
                      imagePath: 'assets/images/taxi.png',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TaxiAppEntry())),
                    ),
                    _buildGridCard(
                      context: context,
                      title: 'الصيدليات',
                      imagePath: 'assets/images/ph.png',
                      onTap: () => context.push('/pharmacy-store'),
                    ),
                    _buildGridCard(
                      context: context,
                      title: 'بوتيك وكوزمتك بيتي',
                      imagePath: 'assets/images/cosmetics.png',
                      onTap: () => context.push('/splash'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const BeyteiZoneScreen()));
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.stars), label: 'بيتي زون'),
        ],
      ),
    );
  }

  Widget _buildGridCard({
    required BuildContext context,
    required String title,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 3,
        shadowColor: Colors.black.withOpacity(0.1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: Image.asset(imagePath, width: double.infinity, fit: BoxFit.cover),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
              ),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0083B0)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
