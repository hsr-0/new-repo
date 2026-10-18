// lib/pages/home_flow/sections_page_widget.dart
// منصة بيتي - فتح الأقسام فوراً دون انتظار GPS.
// GPS تلقائي تقريبي سريع هو الخيار الأساسي، والخريطة بديل عند تعذره.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:version/version.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:facebook_app_events/facebook_app_events.dart';

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
  static const String PROMO_TITLE = '🏆 كل ما تطلب أكثر تربح أكثر!';
  static const String PROMO_MESSAGE =
      'تطبيق منصة بيتي يقدم لك هدايا وجوائز يومية\n\n'
      '🎁 الهدية الاسبوعية توزع يوم الجمعة الساعة 8 مساءً\n'
      '💰 كل طلب يؤهلك للفوز\n📱 اطلب الآن قبل انتهاء الوقت!';
  static Future<bool> shouldShowPromo() async => true;
}

class BannerItem {
  final String imageUrl, targetType, targetUrl;
  BannerItem({required this.imageUrl, required this.targetType, required this.targetUrl});
  factory BannerItem.fromJson(Map<String, dynamic> json) => BannerItem(
    imageUrl: json['imageUrl'],
    targetType: json['targetType'],
    targetUrl: json['targetUrl'],
  );
}

// =======================================================================
// 📍 خدمة GPS التقريبي السريع - لا تؤخر فتح الأقسام
// =======================================================================
class LocationService {
  static const String LAT_KEY = 'shared_user_latitude';
  static const String LNG_KEY = 'shared_user_longitude';
  static const String LOCATION_SOURCE_KEY = 'shared_location_source';
  static const String LOCATION_TIMESTAMP_KEY = 'shared_location_timestamp';
  static const int LOCATION_MAX_AGE_HOURS = 24;

  static bool isManualSource(String source) => source.contains('manual');

  static bool validCoordinates(double lat, double lng) =>
      lat.isFinite && lng.isFinite &&
          lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180 &&
          !(lat == 0 && lng == 0);

  /// كل موقع GPS جديد ناجح يصبح الموقع الأساسي؛ اليدوي بديل عند تعذر GPS.
  /// تُحفَظ الإحداثيات التلقائية منفصلة أيضاً للاستخدام عند الحاجة.
  /// إذا كان استدعاء آخر يحتاج الحفاظ على التحديد اليدوي يمكنه وضع
  /// replaceManual: false، لكن صفحة الرئيسية تختار GPS التلقائي دائماً.
  static Future<bool> saveLocation(
      double lat,
      double lng, {
        String source = 'auto',
        bool replaceManual = true,
        DateTime? capturedAt,
      }) async {
    if (!validCoordinates(lat, lng)) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final stamp = (capturedAt ?? DateTime.now()).millisecondsSinceEpoch;
      final isGps = !isManualSource(source);

      if (isGps) {
        await prefs.setDouble('last_detected_gps_latitude', lat);
        await prefs.setDouble('last_detected_gps_longitude', lng);
        await prefs.setInt('last_detected_gps_timestamp', stamp);
      }

      final previous = prefs.getString(LOCATION_SOURCE_KEY) ?? '';
      if (isGps && !replaceManual && isManualSource(previous)) {
        return true;
      }

      await prefs.setDouble(LAT_KEY, lat);
      await prefs.setDouble(LNG_KEY, lng);
      await prefs.setString(LOCATION_SOURCE_KEY, source);
      await prefs.setInt(LOCATION_TIMESTAMP_KEY, stamp);
      return true;
    } catch (e) {
      debugPrint('⚠️ Location save failed: $e');
      return false;
    }
  }

  static Future<({double lat, double lng, String source, bool isExpired})?>
  getSavedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble(LAT_KEY);
      final lng = prefs.getDouble(LNG_KEY);
      final source = prefs.getString(LOCATION_SOURCE_KEY) ?? 'unknown';
      final timestamp = prefs.getInt(LOCATION_TIMESTAMP_KEY);
      if (lat == null || lng == null || !validCoordinates(lat, lng)) {
        return null;
      }
      final isExpired = timestamp == null ||
          DateTime.now().difference(
            DateTime.fromMillisecondsSinceEpoch(timestamp),
          ) > const Duration(hours: LOCATION_MAX_AGE_HOURS);
      return (lat: lat, lng: lng, source: source, isExpired: isExpired);
    } catch (e) {
      debugPrint('⚠️ Location read failed: $e');
      return null;
    }
  }

  /// محاولة تقريبية في الخلفية، وليست انتظاراً للتنقل.
  /// مهلة 3 ثوانٍ حد لتوفير البطارية فقط، لا يراها المستخدم ولا ينتظرها.
  static Future<Position?> tryAutoDetectSilent({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) return null;
      return await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: timeout,
        ),
      ).timeout(timeout);
    } catch (e) {
      debugPrint('📍 Approximate GPS unavailable: $e');
      return null;
    }
  }

  /// آخر موقع تلقائي معروف حديث يُستخدم مبدئياً دون انتظار GPS جديد.
  /// لا نعد موقعاً عمره ساعات وجهة توصيل حالية.
  static Future<Position?> recentLastKnownLocation() async {
    try {
      final position = await Geolocator.getLastKnownPosition();
      if (position == null ||
          !validCoordinates(position.latitude, position.longitude)) return null;
      final age = DateTime.now().difference(position.timestamp);
      if (age.isNegative || age > const Duration(minutes: 10)) return null;
      return position;
    } catch (_) {
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
// 📱 واجهة التطبيق الرئيسية
// =======================================================================
class SectionsPageWidget extends StatefulWidget {
  const SectionsPageWidget({Key? key}) : super(key: key);
  @override
  State<SectionsPageWidget> createState() => _SectionsPageWidgetState();
}

class _SectionsPageWidgetState extends State<SectionsPageWidget>
    with WidgetsBindingObserver {
  List<BannerItem> banners = [];
  bool showBanners = false;

  bool _isCheckingLocation = false;
  bool _openedAnySection = false;
  bool _autoLocationPromptShown = false;
  bool _locationDialogOpen = false;
  bool _isLocationTimerBusy = false;
  ({double lat, double lng, String source, bool isExpired})? _savedLocation;
  Future<bool>? _gpsRequestInProgress;
  Timer? _backgroundLocationTimer;
  Timer? _firstPermissionWatcher;
  DateTime? _lastPermissionGpsAttempt;
  int _firstPermissionChecks = 0;
  bool _permissionWatcherTickBusy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // يشمل العودة من نافذة صلاحيات Android أو من إعدادات التطبيق.
      _checkLocationSilently();
      _watchInitialLocationPermission();
    } else {
      // هذه ليست خدمة GPS تعمل بعد مغادرة التطبيق.
      _backgroundLocationTimer?.cancel();
      _firstPermissionWatcher?.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _backgroundLocationTimer?.cancel();
    _firstPermissionWatcher?.cancel();
    super.dispose();
  }

  void _initializeApp() {
    _startBackgroundTasks();
    _checkLocationSilently();
    // إذن الموقع يمكن أن يُمنح بعد بناء الصفحة؛ نكتشفه بدون إعادة تشغيل.
    _watchInitialLocationPermission();
    // إذا لم توجد إحداثيات إطلاقاً: أعطِ الزبون خيار GPS أو الخريطة.
    // هذه النافذة لا تؤخر فتح أي قسم ولا تنتظر GPS.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_showMissingLocationPromptOnce());
    });
  }

  /// يظهر في الواجهة الرئيسية مرة واحدة فقط إذا لا توجد إحداثيات محفوظة.
  /// لا يفرض الموقع عند دخول أي قسم؛ يستطيع الزبون اختيار «لاحقاً».
  Future<void> _showMissingLocationPromptOnce() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted || _openedAnySection || _autoLocationPromptShown ||
        _locationDialogOpen) return;
    if (WidgetsBinding.instance.lifecycleState != null &&
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) return;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return;
    final stored = await LocationService.getSavedLocation();
    if (!mounted || _openedAnySection || _autoLocationPromptShown ||
        _locationDialogOpen || stored != null) return;
    _autoLocationPromptShown = true;
    _showLocationPickerDialog(null);
  }

  // =======================================================================
  // ⚙️ مهام الصفحة غير المتعلقة بصلاحية GPS
  // =======================================================================
  void _startBackgroundTasks() {
    _loginFirebaseSilently();
    _loadBannersWithCache();
    _checkForUpdate();
    AppReviewManager().requestReviewIfAppropriate();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(seconds: 12));
      if (!mounted) return;
      // main.dart هو المسؤول عن إذن الإشعارات والميكروفون.
      // لا نطلب الإشعارات هنا مرة ثانية كي لا تتداخل النوافذ.
      await _requestSafePermissions();

      // لا تغطِّ نوافذ أول تشغيل بالمكافآت قبل اختيار موقع التوصيل.
      final current = await LocationService.getSavedLocation();
      if (!mounted || current == null || current.isExpired ||
          _isCheckingLocation || _openedAnySection) return;
      if (await PromoManager.shouldShowPromo() && mounted) {
        _showPromoDialog();
      }
    });
  }

  Future<void> _loginFirebaseSilently() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        await FirebaseAuth.instance.signInAnonymously();
        print('✅ Firebase anonymous sign-in');
      } else {
        print('✅ Firebase user already signed in: ${user.uid}');
      }
    } catch (e) {
      print('❌ Firebase auth error: $e');
    }
  }

  Future<void> _requestSafePermissions() async {
    try {
      final facebookAppEvents = FacebookAppEvents();
      await facebookAppEvents.setAdvertiserTracking(enabled: true);
      await facebookAppEvents.logEvent(
        name: 'fb_mobile_activate_app',
        parameters: {'platform': 'flutter_home_screen'},
      );
    } catch (e) {
      print('❌ Facebook initialization error: $e');
    }
  }

  // =======================================================================
  // 📍 الموقع: التحديث الصامت مستقل تماماً عن فتح أي قسم
  // =======================================================================

  Future<void> _checkLocationSilently() async {
    // اعرض أي إحداثيات محفوظة فوراً دون تحميل يحجب الشاشة.
    final stored = await LocationService.getSavedLocation();
    if (!mounted) return;
    setState(() => _savedLocation = stored);
    _startSilentBackgroundLocationUpdates();
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed ||
        WidgetsBinding.instance.lifecycleState == null) {
      // لا تنتظر GPS إطلاقاً في هذه الدالة ولا تُظهر مؤشر التحميل.
      unawaited(_captureAndSaveCurrentLocation(
        requestPermission: false, showFeedback: false, showLoading: false,
      ));
    }
  }

  /// عند أول تثبيت يبدأ main.dart بطلب الأذونات بالتسلسل.
  /// قد يكون الموقع مرفوضاً في هذه اللحظة ثم يوافق عليه المستخدم بعد ثوانٍ.
  /// نفحص حالة الإذن مدة محدودة ونلتقط GPS مباشرة بعد السماح، دون خروج/دخول.
  void _watchInitialLocationPermission() {
    _firstPermissionWatcher?.cancel();
    _firstPermissionChecks = 0;
    _firstPermissionWatcher = Timer.periodic(
      const Duration(seconds: 2),
          (timer) async {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (WidgetsBinding.instance.lifecycleState != null &&
            WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
          return;
        }
        _firstPermissionChecks++;
        if (_firstPermissionChecks >= 45) {
          timer.cancel(); // متابعة منح الإذن لأول تشغيل، دون منع أي تنقل.
          return;
        }
        if (_gpsRequestInProgress != null || _permissionWatcherTickBusy) return;
        _permissionWatcherTickBusy = true;
        try {
          final latest = await LocationService.getSavedLocation();
          if (!mounted) return;
          if (latest != null &&
              (_savedLocation == null ||
                  latest.lat != _savedLocation!.lat ||
                  latest.lng != _savedLocation!.lng ||
                  latest.source != _savedLocation!.source)) {
            setState(() => _savedLocation = latest);
          }
          // إحداثيات GPS محفوظة الآن بواسطة main.dart أو هذه الصفحة.
          // إذا كانت حديثة، لا نعيد طلب GPS بلا داعٍ.
          if (latest != null && !LocationService.isManualSource(latest.source) &&
              !latest.isExpired) {
            final prefs = await SharedPreferences.getInstance();
            final stamp = prefs.getInt(LocationService.LOCATION_TIMESTAMP_KEY);
            if (stamp != null &&
                DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(stamp)) <
                    const Duration(minutes: 2)) {
              timer.cancel();
              _startSilentBackgroundLocationUpdates();
              return;
            }
          }
          if (!await Geolocator.isLocationServiceEnabled()) return;
          final permission = await Geolocator.checkPermission();
          if (permission != LocationPermission.whileInUse &&
              permission != LocationPermission.always) return;
          final now = DateTime.now();
          if (_lastPermissionGpsAttempt != null &&
              now.difference(_lastPermissionGpsAttempt!) <
                  const Duration(seconds: 10)) return;
          _lastPermissionGpsAttempt = now;
          final ok = await _captureAndSaveCurrentLocation(
            requestPermission: false, showFeedback: false,
            showLoading: false,
          );
          if (ok) timer.cancel();
        } catch (e) {
          debugPrint('⚠️ GPS permission watcher: $e');
        } finally {
          _permissionWatcherTickBusy = false;
        }
      },
    );
  }

  /// لا GPS ولا فحص أذونات ولا انتظار SharedPreferences عند الضغط.
  /// requireRestaurantArea للتوافق مع الاستدعاءات السابقة فقط؛
  /// صفحة المطاعم تعرض اختيار المنطقة داخلها عند الحاجة.
  void _navigateWithLocationCheck(VoidCallback onNavigate,
      {bool requireRestaurantArea = false}) {
    if (!mounted) return;
    _openedAnySection = true;
    try {
      onNavigate(); // التنفيذ فوري في نفس ضغطة الزبون.
    } catch (e) {
      debugPrint('⚠️ Cannot open selected section: $e');
      _showSnackBar('تعذر فتح القسم. حاول مجدداً.');
    }
  }

  /// تحديث GPS في الواجهة فقط وبصمت، من دون إجبار أي قسم على الانتظار.
  /// GPS الجديد يحل محل اختيار الموقع اليدوي المؤقت في الرئيسية؛ لا يمس عرض طلب مكتمل.
  void _startSilentBackgroundLocationUpdates() {
    _backgroundLocationTimer?.cancel();
    if (WidgetsBinding.instance.lifecycleState != null &&
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) return;
    _backgroundLocationTimer = Timer.periodic(
      const Duration(minutes: 4),
          (_) async {
        if (!mounted || _isLocationTimerBusy || _gpsRequestInProgress != null ||
            (WidgetsBinding.instance.lifecycleState != null &&
                WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed)) return;
        _isLocationTimerBusy = true;
        try {
          await _captureAndSaveCurrentLocation(
            requestPermission: false, showFeedback: false, showLoading: false,
          );
        } finally {
          _isLocationTimerBusy = false;
        }
      },
    );
  }

  /// نعيد استخدام الطلب الجاري بدلاً من بدء جلبين GPS في اللحظة نفسها.
  Future<bool> _captureAndSaveCurrentLocation({
    required bool requestPermission,
    bool showFeedback = true,
    bool showLoading = true,
  }) async {
    if (_gpsRequestInProgress != null) {
      final previous = await _gpsRequestInProgress!;
      // نتيجة ناجحة من العملية الصامتة تعني أن GPS محفوظ وجاهز؛ لا نعيد انتظاره.
      if (previous || !requestPermission) return previous;
    }
    final future = _performGpsCapture(
      requestPermission: requestPermission,
      showFeedback: showFeedback,
      showLoading: showLoading,
    );
    _gpsRequestInProgress = future;
    try {
      return await future;
    } finally {
      if (identical(_gpsRequestInProgress, future)) {
        _gpsRequestInProgress = null;
      }
    }
  }

  Future<bool> _performGpsCapture({
    required bool requestPermission,
    required bool showFeedback,
    required bool showLoading,
  }) async {
    if (!mounted) return false;
    // أي مؤشر تحميل هنا يظهر فقط إذا ضغط الزبون بنفسه «موقعي الحالي».
    // كل تحديث تلقائي في الواجهة يعمل بصمت وبشكل مستقل عن التنقل.
    if (showLoading) setState(() => _isCheckingLocation = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (showFeedback) _showSnackBar('GPS مطفأ، يمكنك اختيار الموقع من الخريطة.');
        return false;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && requestPermission) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        if (showFeedback) _showSnackBar('اسمح بالموقع أو اختر عنوانك من الخريطة.');
        return false;
      }

      bool storedSomeGps = false;

      // 1) ابدأ بآخر GPS حديث دون انتظار نتيجة مستشعر جديد.
      final cached = await LocationService.recentLastKnownLocation();
      if (cached != null && mounted) {
        storedSomeGps = await LocationService.saveLocation(
          cached.latitude, cached.longitude,
          source: 'auto_recent', replaceManual: true,
          capturedAt: cached.timestamp,
        );
        if (storedSomeGps && mounted) {
          final saved = await LocationService.getSavedLocation();
          if (saved != null) setState(() => _savedLocation = saved);
        }
      }

      // 2) حسّن الموقع بصمت بدقة LOW، ولا تطلب HIGH/BEST.
      // المهلة هنا 3 ثوانٍ داخل مهمة خلفية فقط ولا علاقة لها بسرعة فتح الأقسام.
      final current = await LocationService.tryAutoDetectSilent(
        timeout: const Duration(seconds: 3),
      );
      if (!mounted) return storedSomeGps;

      if (current != null && LocationService.validCoordinates(
        current.latitude, current.longitude,
      )) {
        final saved = await LocationService.saveLocation(
          current.latitude, current.longitude,
          source: 'auto_gps', replaceManual: true,
          capturedAt: current.timestamp,
        );
        if (saved && mounted) {
          final latest = await LocationService.getSavedLocation();
          if (latest != null) setState(() => _savedLocation = latest);
          _firstPermissionWatcher?.cancel();
          return true;
        }
      }

      if (storedSomeGps) {
        _firstPermissionWatcher?.cancel();
        return true;
      }
      if (showFeedback) _showSnackBar('لم يتوفر موقع تلقائي الآن. اختره من الخريطة.');
      return false;
    } catch (e) {
      debugPrint('⚠️ Quick GPS failed: $e');
      if (showFeedback) _showSnackBar('تعذر تحديد الموقع حالياً. يمكنك اختياره من الخريطة.');
      return false;
    } finally {
      if (mounted && showLoading) setState(() => _isCheckingLocation = false);
    }
  }

  // =======================================================================
  // 🗺️ حوار اختيار عنوان التوصيل
  // =======================================================================
  void _showLocationPickerDialog(VoidCallback? onSuccessNavigation) {
    if (!mounted || _locationDialogOpen) return;
    _locationDialogOpen = true;
    unawaited(showDialog<void>(
      context: context,
      barrierDismissible: true,
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
                      Text('تحديد موقع التوصيل',
                          style: TextStyle(color: Colors.white, fontSize: 18,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    children: [
                      const Text(
                        'اختر موقعك تلقائياً أو حدده على الخريطة لحساب التوصيل. يمكنك تصفح الأقسام الآن وتحديده لاحقاً.',
                        style: TextStyle(fontSize: 15, height: 1.6,
                            color: Colors.grey),
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
                              label: const Text('من الخريطة',
                                  style: TextStyle(color: Colors.orange)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.orange),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                Navigator.pop(ctx);
                                await _requestLocationWithPermission(onSuccessNavigation);
                              },
                              icon: const Icon(Icons.my_location),
                              label: const Text('موقعي الحالي'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('لاحقاً',
                            style: TextStyle(color: Colors.grey, fontSize: 14)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(() {
      _locationDialogOpen = false;
    }));
  }

  /// اختيار «موقعي الحالي» فقط هو الذي يطلب صلاحية الموقع من Android/iOS.
  /// عند رفض الإذن أو توقف GPS تظهر خيارات الإعدادات والخريطة فوراً.
  Future<void> _requestLocationWithPermission(
      VoidCallback? onSuccessNavigation) async {
    if (!mounted) return;
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (!mounted) return;
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        await _showLocationRecoveryDialog(
          'يرجى السماح لمنصة بيتي بالوصول إلى الموقع، أو اختيار عنوانك على الخريطة.',
          onSuccessNavigation,
        );
        return;
      }

      if (!await Geolocator.isLocationServiceEnabled()) {
        if (!mounted) return;
        await _showLocationRecoveryDialog(
          'خدمة الموقع GPS متوقفة. فعّل الموقع من إعدادات الهاتف أو اختر موقعك يدوياً.',
          onSuccessNavigation,
          gpsDisabled: true,
        );
        return;
      }
      final ok = await _captureAndSaveCurrentLocation(
        requestPermission: false,
        showFeedback: false,
        showLoading: true,
      );
      if (!mounted) return;
      if (ok) {
        if (onSuccessNavigation != null) onSuccessNavigation();
        return;
      }
      await _showLocationRecoveryDialog(
        'لم نتمكن من تحديد الموقع التلقائي الآن. يمكنك إعادة المحاولة أو اختيار موقعك من الخريطة.',
        onSuccessNavigation,
      );
    } catch (e) {
      debugPrint('⚠️ Explicit location selection failed: $e');
      if (!mounted) return;
      await _showLocationRecoveryDialog(
        'تعذّر تحديد الموقع. اختره من الخريطة أو افتح إعدادات الموقع.',
        onSuccessNavigation,
      );
    }
  }

  Future<void> _showLocationRecoveryDialog(
      String message,
      VoidCallback? onSuccessNavigation, {
        bool gpsDisabled = false,
      }) async {
    if (!mounted) return;
    final action = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: const Text('📍 تعذّر تحديد الموقع تلقائياً'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'map'),
            child: const Text('من الخريطة'),
          ),
          if (gpsDisabled)
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'gps-settings'),
              child: const Text('تفعيل GPS'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'app-settings'),
            child: const Text('إعدادات التطبيق'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'retry'),
            child: const Text('إعادة المحاولة'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('لاحقاً'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    switch (action) {
      case 'map':
        final saved = await _handleManualLocationPick();
        if (saved && mounted && onSuccessNavigation != null) {
          onSuccessNavigation();
        }
        break;
      case 'gps-settings':
        await Geolocator.openLocationSettings();
        // عند العودة إلى التطبيق، didChangeAppLifecycleState يحدث GPS بصمت.
        break;
      case 'app-settings':
        await Geolocator.openAppSettings();
        break;
      case 'retry':
        await _requestLocationWithPermission(onSuccessNavigation);
        break;
      default:
        break;
    }
  }

  void _showSnackBar(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(text), backgroundColor: Colors.orange),
      );
    }
  }

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
      if (!mounted || result is! Map ||
          result['lat'] == null || result['lng'] == null) return false;
      final lat = (result['lat'] as num).toDouble();
      final lng = (result['lng'] as num).toDouble();
      // الموقع اليدوي بديل مؤقت؛ يعود GPS ليكون الأساسي عند نجاح التحديث التالي.
      final saved = await LocationService.saveLocation(
        lat, lng, source: 'manual_map',
      );
      if (!saved || !mounted) return false;
      final current = await LocationService.getSavedLocation();
      if (current == null) return false;
      setState(() => _savedLocation = current);
      // يبقى GPS التلقائي مفعلاً دون تعليق التنقل.
      _startSilentBackgroundLocationUpdates();
      return true;
    } catch (e) {
      debugPrint('⚠️ Manual location picker failed: $e');
      return false;
    }
  }

  // =======================================================================
  // 🌐 إدارة البانرات والمهام الأخرى (بدون تغيير الوظائف)
  // =======================================================================
  Future<void> _loadBannersWithCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(CacheConstants.CACHE_KEY_BANNERS);
    final lastFetchTime = prefs.getInt(CacheConstants.CACHE_KEY_BANNER_TIME);

    if (cachedData != null && lastFetchTime != null) {
      final cacheAge = DateTime.now().difference(
          DateTime.fromMillisecondsSinceEpoch(lastFetchTime));
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
        await prefs.setInt(CacheConstants.CACHE_KEY_BANNER_TIME,
            DateTime.now().millisecondsSinceEpoch);
        _processBannerData(response.body);
      }
    } catch (e) {
      print('Banner fetch error: $e');
    }
  }

  void _processBannerData(String jsonData) {
    try {
      final jsonMap = json.decode(jsonData);
      if (mounted) {
        setState(() {
          showBanners = jsonMap['showBanners'] ?? false;
          final bannerList =
          List<Map<String, dynamic>>.from(jsonMap['banners'] ?? []);
          banners = bannerList.map((item) => BannerItem.fromJson(item)).toList();
        });
      }
    } catch (e) {}
  }

  void _onBannerTapped(BannerItem banner) {
    if (banner.targetType == 'route') {
      if (banner.targetUrl.contains('restaurants-store')) {
        _navigateWithLocationCheck(() {
          GoRouter.of(context).push(banner.targetUrl);
        }, requireRestaurantArea: true);
        return;
      }
      _openedAnySection = true;
      GoRouter.of(context).push(banner.targetUrl);
    } else if (banner.targetType == 'webview') {
      _openedAnySection = true;
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => WebViewPage(url: banner.targetUrl)));
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
          ),
        ],
      ),
    );
  }

  Future<void> _showPromoDialog() async {
    if (!mounted) return;
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
                gradient: const LinearGradient(
                    colors: [Colors.deepPurple, Colors.purpleAccent],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(23)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: const BoxDecoration(
                        color: Colors.deepPurple,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(23),
                          topRight: Radius.circular(23),
                        ),
                      ),
                      child: Center(
                        child: Column(children: [
                          Icon(Icons.card_giftcard_rounded,
                              color: Colors.yellow.shade300, size: 60),
                          const SizedBox(height: 10),
                          const Text(PromoManager.PROMO_TITLE,
                              style: TextStyle(color: Colors.white,
                                  fontSize: 18, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center),
                        ]),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(25),
                      child: Column(children: [
                        Text(PromoManager.PROMO_MESSAGE,
                            style: TextStyle(fontSize: 16, height: 1.6,
                                color: Colors.grey.shade800),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 25),
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.access_time_filled_rounded,
                                  color: Colors.orange.shade700),
                              const SizedBox(width: 10),
                              Text('موعد التوزيع: 8:00 مساءً',
                                  style: TextStyle(fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade800)),
                            ],
                          ),
                        ),
                      ]),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 25, right: 25, bottom: 25),
                      child: Row(children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              side: BorderSide(color: Colors.grey.shade400),
                            ),
                            child: Text('لاحقاً', style: TextStyle(
                                color: Colors.grey.shade700, fontSize: 15,
                                fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => const BeyteiZoneScreen()));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 3,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.rocket_launch_rounded, size: 20),
                                SizedBox(width: 8),
                                Text('ابدأ الفوز', style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 10, left: 10,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.1), blurRadius: 5)],
                  ),
                  child: Icon(Icons.close_rounded,
                      color: Colors.grey.shade600, size: 20),
                ),
              ),
            ),
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
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => SupportUserChatScreen(
          taxiName: tName, taxiPhone: tPhone,
          orderName: oName, orderPhone: oPhone, orderId: oId,
        ),
      ));
    }
  }

  Widget? _buildLocationIndicator() {
    if (_isCheckingLocation) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        child: Row(children: [
          SizedBox(width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 8),
          Text('جاري تحديد موقعك...',
              style: TextStyle(fontSize: 13, color: Colors.grey)),
        ]),
      );
    }
    if (_savedLocation != null) {
      final sourceText = LocationService.isManualSource(_savedLocation!.source)
          ? '(يدوي)' : '(تلقائي)';
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        child: Row(children: [
          const Icon(Icons.check_circle_rounded,
              color: Colors.green, size: 16),
          const SizedBox(width: 6),
          Expanded(child: Text(
            _savedLocation!.isExpired
                ? 'الموقع محفوظ ويحتاج تحديث'
                : 'تم تحديد الموقع ✓ $sourceText',
            style: TextStyle(fontSize: 13, color: Colors.green[700],
                fontWeight: FontWeight.w500),
          )),
          TextButton.icon(
            onPressed: () => _showLocationPickerDialog(null),
            icon: const Icon(Icons.edit, size: 14),
            label: const Text('تعديل', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
                padding: EdgeInsets.zero, minimumSize: Size.zero),
          ),
        ]),
      );
    }
    // إذا لم يوجد موقع، يبقى زر تحديد الموقع واضحاً حتى لو أُغلقت النافذة.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child: Row(
        children: [
          const Icon(Icons.location_off_outlined, color: Colors.deepOrange, size: 17),
          const SizedBox(width: 6),
          const Expanded(
            child: Text('لم يتم تحديد موقع التوصيل بعد',
                style: TextStyle(fontSize: 13, color: Colors.deepOrange)),
          ),
          TextButton.icon(
            onPressed: () => _showLocationPickerDialog(null),
            icon: const Icon(Icons.add_location_alt_outlined, size: 16),
            label: const Text('تحديد الموقع'),
          ),
        ],
      ),
    );
  }

  // =======================================================================
  // 🖼️ واجهة المستخدم - تصميم المنصة الأصلي
  // =======================================================================
  @override
  Widget build(BuildContext context) {
    final locationIndicator = _buildLocationIndicator();
    return Scaffold(
      appBar: AppBar(
        title: const Text('منصة بيتي',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          Padding(
            padding: const EdgeInsets.only(
                right: 12.0, top: 10.0, bottom: 10.0, left: 10.0),
            child: InkWell(
              onTap: _openSmartSupportChat,
              borderRadius: BorderRadius.circular(25),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [BoxShadow(
                    color: const Color(0xFF0083B0).withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.headset_mic_rounded,
                        color: Colors.white, size: 20),
                    SizedBox(width: 6),
                    Text('الدعم الفني',
                        style: TextStyle(color: Colors.white,
                            fontWeight: FontWeight.bold, fontSize: 13)),
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
              if (locationIndicator != null) locationIndicator,
              if (showBanners && banners.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
                  child: Text('العروض المميزة',
                      style: TextStyle(fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ),
                CarouselSlider(
                  options: CarouselOptions(
                    height: 180.0,
                    autoPlay: true,
                    enlargeCenterPage: true,
                  ),
                  items: banners.map((banner) {
                    return Builder(builder: (BuildContext context) => GestureDetector(
                      onTap: () => _onBannerTapped(banner),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.network(
                          banner.imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          loadingBuilder: (context, child, loadingProgress) =>
                          loadingProgress == null
                              ? child
                              : const Center(child: CircularProgressIndicator()),
                          errorBuilder: (context, error, stackTrace) =>
                          const Center(child: Icon(Icons.error)),
                        ),
                      ),
                    ));
                  }).toList(),
                ),
              ],
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: Text('خدماتنا',
                    style: TextStyle(fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 10),
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
                      title: 'مطاعم وماركت ',
                      imagePath: 'assets/images/re.jpg',
                      onTap: () => _navigateWithLocationCheck(() {
                        GoRouter.of(context).push('/restaurants-store');
                      }, requireRestaurantArea: true),
                    ),
                    _buildGridCard(
                      context: context,
                      title: 'تكسي بيتي',
                      imagePath: 'assets/images/taxi.png',
                      onTap: () => _navigateWithLocationCheck(() {
                        Navigator.push(context, MaterialPageRoute(
                            builder: (_) => const TaxiAppEntry()));
                      }),
                    ),
                    _buildGridCard(
                      context: context,
                      title: 'الصيدليات',
                      imagePath: 'assets/images/ph.png',
                      onTap: () => _navigateWithLocationCheck(() {
                        context.push('/pharmacy-store');
                      }),
                    ),
                    _buildGridCard(
                      context: context,
                      title: 'بوتيك وكوزمتك بيتي',
                      imagePath: 'assets/images/cosmetics.png',
                      onTap: () { _openedAnySection = true; context.push('/splash'); },
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
            _openedAnySection = true;
            Navigator.push(context, MaterialPageRoute(
                builder: (_) => const BeyteiZoneScreen()));
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
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15)),
                child: Image.asset(imagePath,
                    width: double.infinity, fit: BoxFit.cover),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 8.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(15)),
              ),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15,
                    fontWeight: FontWeight.bold, color: Color(0xFF0083B0)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
