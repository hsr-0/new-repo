// lib/widgets/sections_page_widget.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 👈 أضفنا مصادقة فايربيس
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:version/version.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

// =======================================================================
// --- ثوابت التخزين ومدير العروض ---
// =======================================================================
class CacheConstants {
  static const String CACHE_KEY_BANNERS = 'cached_banner_data';
  static const String CACHE_KEY_BANNER_TIME = 'cached_banner_time';
  static const int CACHE_DURATION_HOURS = 6;
}

class PromoManager {
  static const String PROMO_TITLE = "🏆 كل ما تطلب أكثر تربح أكثر!";
  static const String PROMO_MESSAGE = "تطبيق منصة بيتي يقدم لك هدايا وجوائز يومية\n\n🎁 الهدية الاسبوعية توزع يوم الجمعة الساعة 8 مساءً\n💰 كل طلب يؤهلك للفوز\n📱 اطلب الآن قبل انتهاء الوقت!";
  static Future<bool> shouldShowPromo() async => true;
}

class BannerItem {
  final String imageUrl, targetType, targetUrl;
  BannerItem({required this.imageUrl, required this.targetType, required this.targetUrl});
  factory BannerItem.fromJson(Map<String, dynamic> json) => BannerItem(imageUrl: json['imageUrl'], targetType: json['targetType'], targetUrl: json['targetUrl']);
}

// =======================================================================
// 📍 خدمة إدارة الموقع (Location Service)
// =======================================================================
class LocationService {
  static const String LAT_KEY = 'shared_user_latitude';
  static const String LNG_KEY = 'shared_user_longitude';
  static const String LOCATION_SOURCE_KEY = 'shared_location_source';
  static const String LOCATION_TIMESTAMP_KEY = 'shared_location_timestamp';
  static const int LOCATION_MAX_AGE_HOURS = 24;

  static Future<bool> saveLocation(double lat, double lng, {String source = 'auto'}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(LAT_KEY, lat);
      await prefs.setDouble(LNG_KEY, lng);
      await prefs.setString(LOCATION_SOURCE_KEY, source);
      await prefs.setInt(LOCATION_TIMESTAMP_KEY, DateTime.now().millisecondsSinceEpoch);
      return true;
    } catch (e) {
      return false;
    }
  }

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
      return null;
    }
  }

  static Future<geolocator.Position?> tryAutoDetectSilent({Duration timeout = const Duration(seconds: 5)}) async {
    try {
      bool serviceEnabled = await geolocator.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;
      geolocator.LocationPermission permission = await geolocator.Geolocator.checkPermission();
      if (permission == geolocator.LocationPermission.denied || permission == geolocator.LocationPermission.deniedForever) return null;

      return await geolocator.Geolocator.getCurrentPosition(desiredAccuracy: geolocator.LocationAccuracy.low).timeout(timeout);
    } catch (e) {
      return null;
    }
  }
}

// =======================================================================
// ⭐ مدير التقييم
// =======================================================================
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
    } catch (e) {}
  }
}

// =======================================================================
// 📱 واجهة التطبيق الرئيسية (Main Widget)
// =======================================================================
class SectionsPageWidget extends StatefulWidget {
  const SectionsPageWidget({Key? key}) : super(key: key);
  @override
  State<SectionsPageWidget> createState() => _SectionsPageWidgetState();
}

class _SectionsPageWidgetState extends State<SectionsPageWidget> {
  List<BannerItem> banners = [];
  bool showBanners = false;

  bool _isCheckingLocation = false;
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

  /// 🚀 تهيئة التطبيق بالكامل بدون إيقاف الواجهة (Non-blocking)
  void _initializeApp() {
    // 1. تشغيل مهام الخلفية فوراً (بدون await) لكي لا نؤخر بناء الواجهة
    _startBackgroundTasks();

    // 2. فحص الموقع بصمت
    _checkLocationSilently();
  }

  // =======================================================================
  // ⚙️ المهام الخلفية (Background Tasks)
  // =======================================================================
  void _startBackgroundTasks() {
    // 🔥 تسجيل الدخول أو تهيئة الفايربيس في الخلفية بصمت تام
    _loginFirebaseSilently();

    // جلب البانرات من الكاش أو السيرفر في الخلفية
    _loadBannersWithCache();

    // التحقق من التحديثات بصمت
    _checkForUpdate();

    // تقييم التطبيق
    AppReviewManager().requestReviewIfAppropriate();

    // ⏳ تأخير عرض الأذونات والنوافذ المنبثقة حتى تفتح الصفحة بسلاسة
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 1500)); // ننتظر ثانية ونصف

      if (mounted) {
        // نطلب الإشعارات والتتبع أولاً
        await _requestSafePermissions();

        // بعد انتهاء الإشعارات، نظهر نافذة الجوائز إن وجدت (لمنع تداخل النوافذ)
        if (await PromoManager.shouldShowPromo()) {
          _showPromoDialog();
        }
      }
    });
  }

  /// 🔥 تسجيل الدخول للفايربيس في الخلفية بدون أي تأخير للواجهة
  Future<void> _loginFirebaseSilently() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // تسجيل دخول مجهول في الخلفية للاستفادة من خدمات الفايربيس
        await FirebaseAuth.instance.signInAnonymously();
        print("✅ تم تسجيل الدخول لفايربيس مجهول الهوية بنجاح (في الخلفية)");
      } else {
        print("✅ المستخدم مسجل دخوله مسبقاً في الفايربيس: ${user.uid}");
      }
    } catch (e) {
      print("❌ خطأ في تسجيل الدخول الصامت لفايربيس: $e");
    }
  }

  /// 🛡️ طلب صلاحيات الإشعارات والتتبع بشكل آمن
  Future<void> _requestSafePermissions() async {
    try {
      // 1. طلب إذن الإشعارات (للآيفون والأندرويد 13+)
      await FirebaseMessaging.instance.requestPermission(
        alert: true, announcement: false, badge: true, carPlay: false, criticalAlert: false, provisional: false, sound: true,
      );

      // 2. إعداد التتبع لفيسبوك
      final facebookAppEvents = FacebookAppEvents();
      await facebookAppEvents.setAdvertiserTracking(enabled: true);
      await facebookAppEvents.logEvent(name: 'fb_mobile_activate_app', parameters: {'platform': 'flutter_home_screen'});
    } catch (e) {
      print("❌ خطأ في طلب الأذونات: $e");
    }
  }

  // =======================================================================
  // 📍 إدارة الموقع (Location Management)
  // =======================================================================

  /// 📍 فحص الموقع بصمت تام
  Future<void> _checkLocationSilently() async {
    // نقرأ من الكاش أولاً
    _savedLocation = await LocationService.getSavedLocation();
    if (_savedLocation != null) {
      if (mounted) setState(() {});
      _startSilentBackgroundLocationUpdates();
      return;
    }

    // إذا لم يكن هناك كاش، نتحقق بهدوء إذا كانت الصلاحية ممنوحة مسبقاً من الإعدادات
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      Position? position = await LocationService.tryAutoDetectSilent(timeout: const Duration(seconds: 3));
      if (position != null && mounted) {
        await LocationService.saveLocation(position.latitude, position.longitude, source: 'auto_silent');
        setState(() {
          _savedLocation = (lat: position.latitude, lng: position.longitude, source: 'auto_silent', isExpired: false);
        });
        _startSilentBackgroundLocationUpdates();
      }
    }
  }

  /// 🚀 الحارس الشخصي للأقسام: التحقق من الموقع قبل الفتح
  Future<void> _navigateWithLocationCheck(VoidCallback onNavigate) async {
    // إذا كان الموقع موجوداً بالفعل، افتح القسم فوراً (Zero Delay)
    if (_savedLocation != null) {
      onNavigate();
      return;
    }
    // إذا لم يكن موجوداً، نظهر النافذة الآن فقط!
    _showLocationPickerDialog(onNavigate);
  }

  /// ⏰ تحديث الموقع بشكل دوري في الخلفية (صامت)
  void _startSilentBackgroundLocationUpdates() {
    _backgroundLocationTimer?.cancel();
    _backgroundLocationTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      if (_savedLocation != null) {
        final newPosition = await LocationService.tryAutoDetectSilent();
        if (newPosition != null && mounted) {
          await LocationService.saveLocation(newPosition.latitude, newPosition.longitude, source: 'auto');
          setState(() {
            _savedLocation = (lat: newPosition.latitude, lng: newPosition.longitude, source: 'auto', isExpired: false);
          });
        }
      }
    });
  }

  /// 🗺️ حوار تحديد الموقع الذكي
  void _showLocationPickerDialog(VoidCallback? onSuccessNavigation) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Colors.orange, Colors.deepOrange], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(23)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: const BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.only(topLeft: Radius.circular(23), topRight: Radius.circular(23))),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on_rounded, color: Colors.white, size: 28),
                      SizedBox(width: 10),
                      Text('تحديد موقع التوصيل', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    children: [
                      const Text(
                        'للدخول إلى هذا القسم وتقديم أفضل خدمة توصيل لك، يرجى تحديد موقعك.',
                        style: TextStyle(fontSize: 15, height: 1.6, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 25),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                Navigator.pop(ctx);
                                final success = await _handleManualLocationPick();
                                if (success && onSuccessNavigation != null && mounted) {
                                  onSuccessNavigation();
                                }
                              },
                              icon: const Icon(Icons.map, color: Colors.orange),
                              label: const Text('من الخريطة', style: TextStyle(color: Colors.orange)),
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.orange), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                Navigator.pop(ctx);
                                _requestLocationWithPermission(onSuccessNavigation);
                              },
                              icon: const Icon(Icons.my_location),
                              label: const Text('موقعي الحالي'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Colors.grey, fontSize: 14))),
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

  /// 📍 طلب الموقع برمجياً مع طلب الصلاحية
  Future<void> _requestLocationWithPermission(VoidCallback? onSuccessNavigation) async {
    setState(() => _isCheckingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar('يرجى تشغيل خدمة الـ GPS أولاً.');
        setState(() => _isCheckingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackBar('صلاحية الموقع مرفوضة، يرجى تفعيلها من الإعدادات.');
        setState(() => _isCheckingLocation = false);
        Geolocator.openAppSettings();
        return;
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium, timeLimit: const Duration(seconds: 10));
        await LocationService.saveLocation(position.latitude, position.longitude, source: 'auto');
        if (mounted) {
          setState(() {
            _savedLocation = (lat: position.latitude, lng: position.longitude, source: 'auto', isExpired: false);
            _isCheckingLocation = false;
          });
          _startSilentBackgroundLocationUpdates();
          if (onSuccessNavigation != null) onSuccessNavigation();
        }
      } else {
        setState(() => _isCheckingLocation = false);
      }
    } catch (e) {
      setState(() => _isCheckingLocation = false);
      _showSnackBar('فشل التقاط الموقع، جرب التحديد اليدوي.');
    }
  }

  void _showSnackBar(String text) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), backgroundColor: Colors.orange));
  }

  Future<bool> _handleManualLocationPick() async {
    try {
      final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => MapLocationPicker(mapStyleUrl: 'https://tiles.openfreemap.org/styles/liberty', initialLat: _savedLocation?.lat, initialLng: _savedLocation?.lng)));
      if (result != null && result is Map && result['lat'] != null && result['lng'] != null) {
        await LocationService.saveLocation(result['lat'], result['lng'], source: result['source'] ?? 'manual');
        setState(() {
          _savedLocation = (lat: result['lat'], lng: result['lng'], source: result['source'] ?? 'manual', isExpired: false);
        });
        _startSilentBackgroundLocationUpdates();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // =======================================================================
  // 🌐 إدارة البانرات والمهام الأخرى
  // =======================================================================

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
    } catch (e) {}
  }

  void _onBannerTapped(BannerItem banner) {
    if (banner.targetType == 'route') {
      GoRouter.of(context).push(banner.targetUrl);
    } else if (banner.targetType == 'webview') {
      Navigator.push(context, MaterialPageRoute(builder: (context) => WebViewPage(url: banner.targetUrl)));
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
        if (current < Version.parse(minVer) && mounted) {
          _showUpdateDialog(url);
        }
      }
    } catch (e) {}
  }

  void _showUpdateDialog(String updateUrl) {
    showDialog(
      context: context, barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('تحديث إجباري'), content: const Text('يرجى تحديث التطبيق للمتابعة.'),
        actions: [
          TextButton(
            child: const Text('تحديث'),
            onPressed: () async {
              final uri = Uri.parse(updateUrl);
              if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
          )
        ],
      ),
    );
  }

  Future<void> _showPromoDialog() async {
    await showDialog(
      context: context, barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        backgroundColor: Colors.transparent, elevation: 0,
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Colors.deepPurple, Colors.purpleAccent], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(25)),
              child: Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(23)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: const BoxDecoration(color: Colors.deepPurple, borderRadius: BorderRadius.only(topLeft: Radius.circular(23), topRight: Radius.circular(23))),
                      child: Center(child: Column(children: [Icon(Icons.card_giftcard_rounded, color: Colors.yellow.shade300, size: 60), const SizedBox(height: 10), const Text(PromoManager.PROMO_TITLE, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center)])),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(25),
                      child: Column(
                        children: [
                          Text(PromoManager.PROMO_MESSAGE, style: TextStyle(fontSize: 16, height: 1.6, color: Colors.grey.shade800), textAlign: TextAlign.center),
                          const SizedBox(height: 25),
                          Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.orange.shade200)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.access_time_filled_rounded, color: Colors.orange.shade700), const SizedBox(width: 10), Text("موعد التوزيع: 8:00 مساءً", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange.shade800))])),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 25, right: 25, bottom: 25),
                      child: Row(
                        children: [
                          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: BorderSide(color: Colors.grey.shade400)), child: Text('لاحقاً', style: TextStyle(color: Colors.grey.shade700, fontSize: 15, fontWeight: FontWeight.w600)))),
                          const SizedBox(width: 15),
                          Expanded(child: ElevatedButton(onPressed: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const BeyteiZoneScreen())); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 3), child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.rocket_launch_rounded, size: 20), SizedBox(width: 8), Text('ابدأ الفوز', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600))]))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(top: 10, left: 10, child: IconButton(onPressed: () => Navigator.pop(context), icon: Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5)]), child: Icon(Icons.close_rounded, color: Colors.grey.shade600, size: 20)))),
          ],
        ),
      ),
    );
  }

  Future<void> _openSmartSupportChat() async {
    String tName = '', tPhone = '', oName = '', oPhone = '', oId = '';
    try {
      final prefs = await SharedPreferences.getInstance();
      tName = prefs.getString('firstname') ?? '';
      tPhone = prefs.getString('mobile') ?? '';
    } catch (e) {}

    if (mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => SupportUserChatScreen(taxiName: tName, taxiPhone: tPhone, orderName: oName, orderPhone: oPhone, orderId: oId)));
    }
  }

  Widget? _buildLocationIndicator() {
    if (_isCheckingLocation) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        child: Row(children: [SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)), SizedBox(width: 8), Text('جاري تحديد موقعك...', style: TextStyle(fontSize: 13, color: Colors.grey))]),
      );
    }
    if (_savedLocation != null) {
      String sourceText = _savedLocation!.source == 'manual' ? '(يدوي)' : '(تلقائي)';
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16), const SizedBox(width: 6),
            Text('تم تحديد الموقع ✓ $sourceText', style: TextStyle(fontSize: 13, color: Colors.green[700], fontWeight: FontWeight.w500)),
            const Spacer(),
            TextButton.icon(onPressed: () => _showLocationPickerDialog(null), icon: const Icon(Icons.edit, size: 14), label: const Text('تعديل', style: TextStyle(fontSize: 12)), style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero)),
          ],
        ),
      );
    }
    return null;
  }

  // =======================================================================
  // 🖼️ بناء واجهة المستخدم (Build)
  // =======================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('منصة بيتي', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false, backgroundColor: Colors.white, elevation: 0.5,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0, top: 10.0, bottom: 10.0, left: 10.0),
            child: InkWell(
              onTap: _openSmartSupportChat,
              borderRadius: BorderRadius.circular(25),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF00B4DB), Color(0xFF0083B0)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: const Color(0xFF0083B0).withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))]),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.headset_mic_rounded, color: Colors.white, size: 20), SizedBox(width: 6), Text("الدعم الفني", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))]),
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
              if (_buildLocationIndicator() != null) _buildLocationIndicator()!,

              if (showBanners && banners.isNotEmpty) ...[
                const Padding(padding: EdgeInsets.fromLTRB(15, 10, 15, 10), child: Text('العروض المميزة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                CarouselSlider(
                  options: CarouselOptions(height: 180.0, autoPlay: true, enlargeCenterPage: true),
                  items: banners.map((banner) {
                    return Builder(
                      builder: (BuildContext context) => GestureDetector(
                        onTap: () => _onBannerTapped(banner),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.network(banner.imageUrl, fit: BoxFit.cover, width: double.infinity, loadingBuilder: (context, child, loadingProgress) => loadingProgress == null ? child : const Center(child: CircularProgressIndicator()), errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.error))),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 20),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 15), child: Text('خدماتنا', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              const SizedBox(height: 10),

              // 🛡️ حماية الأقسام بدالة _navigateWithLocationCheck
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: GridView.count(
                  crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildGridCard(
                      context: context, title: 'المطاعم', imagePath: 'assets/images/re.jpg',
                      onTap: () => _navigateWithLocationCheck(() { GoRouter.of(context).push('/restaurants-store'); }),
                    ),
                    _buildGridCard(
                      context: context, title: 'تكسي بيتي', imagePath: 'assets/images/taxi.png',
                      onTap: () => _navigateWithLocationCheck(() { Navigator.push(context, MaterialPageRoute(builder: (context) => const TaxiAppEntry())); }),
                    ),
                    _buildGridCard(
                      context: context, title: 'الصيدليات', imagePath: 'assets/images/ph.png',
                      onTap: () => _navigateWithLocationCheck(() { context.push('/pharmacy-store'); }),
                    ),
                    _buildGridCard(
                      context: context, title: 'بوتيك وكوزمتك بيتي', imagePath: 'assets/images/cosmetics.png',
                      // إذا كان البوتيك لا يحتاج موقع، يمكنك حذف _navigateWithLocationCheck منه:
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
        currentIndex: 0, selectedItemColor: Colors.deepPurple, unselectedItemColor: Colors.grey,
        onTap: (index) { if (index == 1) { Navigator.push(context, MaterialPageRoute(builder: (context) => const BeyteiZoneScreen())); } },
        items: const [BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'), BottomNavigationBarItem(icon: Icon(Icons.stars), label: 'بيتي زون')],
      ),
    );
  }

  Widget _buildGridCard({required BuildContext context, required String title, required String imagePath, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), elevation: 3, shadowColor: Colors.black.withOpacity(0.1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(15)), child: Image.asset(imagePath, width: double.infinity, fit: BoxFit.cover))),
            Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15))), child: Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0083B0)))),
          ],
        ),
      ),
    );
  }
}
