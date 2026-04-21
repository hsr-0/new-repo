import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/services.dart'; // مطلوب للاهتزاز
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/date_symbol_data_local.dart'; // 👈 مهم جداً

import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:uuid/uuid.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

import '../beytei_re/OrderTracking.dart';
import 'package:flutter/foundation.dart';

// =======================================================================
// --- إعدادات وثوابت عامة للوحدة ---
// =======================================================================
// (تم تغيير الدومين إلى beytei.com ومسار API جديد)
const String BEYTEI_URL = 'https://beytei.com';
const String STORE_APP_NAMESPACE = '/wp-json/store-app/v1'; // (هذا مسار مقترح للـ Backend)
const String STORE_APP_URL = BEYTEI_URL + STORE_APP_NAMESPACE;

// (هذه الثوابت خاصة بـ WooCommerce API للزبون - من الكود الخاص بك)
const String CONSUMER_KEY = 'ck_86b62f6fe8a298a5f9d564d70d689db81b9255ed';
const String CONSUMER_SECRET = 'cs_b2de9b284f6245c8297caaf37976d899d6789ab2';

const Duration API_TIMEOUT = Duration(seconds: 30);


class AppConstants {

  // ✨ مفاتيح الكاش الخاصة بالمسواك
  static const String CACHE_KEY_MISWAK_HOME_PREFIX = 'cache_miswak_home_area_';
  static const String CACHE_KEY_MISWAK_MENU_PREFIX = 'cache_miswak_products_store_';
  static const String CACHE_TIMESTAMP_MISWAK_PREFIX = 'cache_time_miswak_';
}



// =======================================================================
// --- معالج رسائل الخلفية ---
// =======================================================================
// --- معالج رسائل الخلفية (يعمل والتطبيق مغلق تماماً أو في الخلفية) ---
// =======================================================================
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  // 🔥 التحقق مما إذا كان الإشعار عبارة عن مكالمة واردة
  if (message.data['type'] == 'incoming_call') {
    final params = CallKitParams(
      id: message.data['order_id'] ?? const Uuid().v4(),
      nameCaller: message.data['driver_name'] ?? 'السائق',
      appName: 'بيتي مسواك',
      avatar: message.data['driver_image'] ?? 'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
      handle: message.data['channel_name'] ?? 'طلب توصيل',
      type: 0, // 0 للصوت
      duration: 30000, // 30 ثانية رنين
      textAccept: 'رد',
      textDecline: 'رفض',
      missedCallNotification: const NotificationParams(
        showNotification: true,
        isShowCallback: true,
        subtitle: 'مكالمة فائتة',
        callbackText: 'عاود الاتصال',
      ),
      extra: <String, dynamic>{
        'channelName': message.data['channel_name'] ?? '',
        'agoraAppId': message.data['agora_app_id'] ?? '3924f8eebe7048f8a65cb3bd4a4adcec',
        'orderId': message.data['order_id'] ?? '0',
        'driverName': message.data['driver_name'] ?? 'السائق',
        'driverImage': message.data['driver_image'] ?? '',
      },
      headers: <String, dynamic>{'apiKey': 'Abc@123!', 'platform': 'flutter'},
      android: AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#009688',
        actionColor: '#4CAF50',
        textColor: '#ffffff',
        incomingCallNotificationChannelName: "المكالمات الواردة",
        isShowFullLockedScreen: true, // 👈 الأهم: يظهر فوق شاشة القفل مثل واتساب
        isShowCallID: true,
      ),
      ios: const IOSParams(
        iconName: 'CallKitLogo',
        handleType: 'generic',
        supportsVideo: false,
        maximumCallGroups: 1,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'default',
        audioSessionActive: true,
        audioSessionPreferredSampleRate: 44100.0,
        audioSessionPreferredIOBufferDuration: 0.005,
        supportsDTMF: true,
        supportsHolding: true,
        supportsGrouping: false,
        supportsUngrouping: false,
        ringtonePath: 'system_ringtone_default',
      ),
    );

    // 1. عرض شاشة المكالمة الواردة فوراً
    await FlutterCallkitIncoming.showCallkitIncoming(params);

    // 2. حفظ البيانات في SharedPreferences لاستخدامها عند الرد
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('incoming_call', json.encode({
      'channel_name': message.data['channel_name'] ?? '',
      'order_id': message.data['order_id'] ?? '0',
      'driver_name': message.data['driver_name'] ?? 'السائق',
      'driver_image': message.data['driver_image'] ?? '',
      'agora_app_id': message.data['agora_app_id'] ?? '3924f8eebe7048f8a65cb3bd4a4adcec'
    }));

    return; // 👈 إيقاف التنفيذ هنا حتى لا يظهر كإشعار نصي عادي
  }














    final data = message.data;
    final type = data['type'];

  if (type == 'refresh_delivery_config') {
    print("📡 [Miswak] استلام إشارة تحديث ملف التسعير...");
    final configProvider = MiswakDeliveryConfigProvider(); // 🔥 البروفايدر الصحيح
    await configProvider.fetchAndCacheConfig();
    return;
  }









  // إذا لم يكن مكالمة، سيتم عرضه كإشعار عادي
  await NotificationService.display(message);
}



// =======================================================================
// --- PROVIDERS ---
// =======================================================================

class NotificationProvider with ChangeNotifier {
  void triggerRefresh() {
    notifyListeners();
  }
}

class NavigationProvider with ChangeNotifier {
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  void changeTab(int index) {
    if (_currentIndex == index) return;
    _currentIndex = index;
    notifyListeners();
  }
}


// =======================================================================
// 🔥🔥🔥 نظام الاتصال المتكامل (Call System - All in One) 🔥🔥🔥
// =======================================================================

// -----------------------------------------------------------------------
// 1. خدمة إدارة المكالمات (CallKit Service)
// -----------------------------------------------------------------------










class StoreAuthProvider with ChangeNotifier {
  String? _token;
  String? _userRole;
  bool _isLoading = true;

  String? get token => _token;
  String? get userRole => _userRole;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _token != null;

  StoreAuthProvider() {
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    // استخدام نفس المفاتيح القياسية لضمان التوافق
    _token = prefs.getString('store_jwt_token');
    _userRole = prefs.getString('store_user_role');
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String username, String password, String role, {String? lat, String? lng}) async {
    final authService = AuthService();
    // محاولة تسجيل الدخول
    final token = await authService.loginRestaurantOwner(username, password);

    if (token != null) {
      _token = token;
      _userRole = role;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('store_jwt_token', token);
      await prefs.setString('store_user_role', role);

      // تحديث الموقع إذا وجد
      if (lat != null && lng != null) {
        final apiService = ApiService();
        await apiService.updateMyLocation(token, lat, lng);
        // حفظ الموقع محلياً أيضاً للأتمتة
        await prefs.setDouble('restaurant_lat', double.tryParse(lat) ?? 0.0);
        await prefs.setDouble('restaurant_lng', double.tryParse(lng) ?? 0.0);
      }

      // تسجيل الجهاز للإشعارات
      await authService.registerDeviceToken();

      notifyListeners(); // 🔥 هذا السطر هو الذي سيشغل ProxyProvider
      return true;
    }
    return false;
  }

  Future<void> logout(BuildContext context) async {
    final authService = AuthService();
    await authService.logout();

    _token = null;
    _userRole = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('store_jwt_token');
    await prefs.remove('store_user_role');
    await prefs.remove('restaurant_lat');
    await prefs.remove('restaurant_lng');

    // تنظيف البيانات عند الخروج
    if (context.mounted) {
      // حاول تنظيف البيانات، تجاهل الأخطاء إذا لم يتم العثور على المزود
      try {
        Provider.of<MiswakDashboardProvider>(context, listen: false).stopAutoRefresh();
      } catch (_) {}
    }
    notifyListeners();
  }
}
class StoreCustomerProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // المتغيرات
  Map<String, List<dynamic>> _homeData = {};
  List<Restaurant> _allStores = [];
  Map<int, List<FoodItem>> _storeItems = {};

  int _lastLoadedAreaId = -1;
  bool _isLoadingHome = false;
  bool _isLoadingMenu = false;
  bool _hasError = false;

  // 🔥 متغيرات الكاش
  DateTime? _lastHomeFetchTime;
  DateTime? _lastProductsFetchTime;

  // --- Getters ---
  Map<String, List<dynamic>> get homeData => _homeData;
  List<Restaurant> get allStores => _allStores;
  Map<int, List<FoodItem>> get storeItems => _storeItems;

  bool get isLoading => _isLoadingHome;
  bool get isLoadingRestaurants => _isLoadingHome;
  bool get isLoadingMenu => _isLoadingMenu;
  bool get hasError => _hasError;

  List<Restaurant> get allRestaurants => _allStores;
  Map<int, List<FoodItem>> get menuItems => _storeItems;

  // --- مسح البيانات ---
  void clearData() {
    _homeData = {};
    _allStores = [];
    _storeItems = {};
    _lastLoadedAreaId = -1;
    _lastHomeFetchTime = null;
    _lastProductsFetchTime = null;
    _hasError = false;
    notifyListeners();
  }

  // ============================================================
  // 1. جلب الرئيسية (Home) - [حل مشكلة Watermark/Loading]
  // ============================================================
  Future<void> fetchStoreHomeData(int areaId, {bool isRefresh = false}) async {
    _lastLoadedAreaId = areaId;
    _hasError = false;

    // 1. الفحص الفوري للذاكرة (يمنع دائرة التحميل عند العودة)
    if (!isRefresh && _homeData.isEmpty) {
      await _loadHomeFromCache(areaId);
      // إذا وجدنا بيانات في الكاش، أظهرها فوراً
      if (_homeData.isNotEmpty) notifyListeners();
    }

    // 2. الكاش الصارم (يمنع طلبات الشبكة المتكررة)
    if (!isRefresh && _homeData.isNotEmpty && await _isCacheValid('home_$areaId', minutes: 1400)) {
      print("✅ استخدام الكاش للمسواك (البيانات حديثة).");
      return;
    }

    // 3. التحميل من الشبكة
    _isLoadingHome = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _apiService.getRawDeliverableIds(areaId),
        _apiService.getRawRestaurants(areaId),
      ]);

      final deliverableJson = results[0];
      final storesJson = results[1];

      _processAndSetHomeData(deliverableJson, storesJson);
      await _saveHomeToCache(areaId, deliverableJson, storesJson);
      _lastHomeFetchTime = DateTime.now();

    } catch (e) {
      print("⚠️ فشل تحديث المسواك من الشبكة: $e");
      if (_homeData.isEmpty) _hasError = true;
    } finally {
      _isLoadingHome = false;
      notifyListeners();
    }
  }

  // ✅ الدالة الحاسمة [حل مشكلة Watermark]
  void _processAndSetHomeData(String deliverableJson, String storesJson) {
    try {
      final deliverableList = json.decode(deliverableJson) as List;
      final Set<int> deliverableIds = deliverableList.map<int>((item) => item['id']).toSet();

      final storesList = json.decode(storesJson) as List;
      List<Restaurant> parsedStores = storesList.map((json) => Restaurant.fromJson(json)).toList();

      // 3. تطبيق حالة التوصيل على كل متجر
      for (var s in parsedStores) {
        s.isDeliverable = deliverableIds.contains(s.id);
      }

      _allStores = parsedStores;
      _homeData['stores'] = parsedStores;
      _homeData['restaurants'] = parsedStores;
    } catch (e) {
      print("Error parsing and setting home data: $e");
      // لا نرمي الخطأ لكي لا ينهار التطبيق، بل نعتبره فشل في الكاش
    }
  }

  // ============================================================
  // 2. جلب منتجات المتجر - مع التخزين الدائم
  // ============================================================
  Future<void> fetchMenuForRestaurant(int storeId, {bool isRefresh = false}) async {
    _hasError = false;

    // أ) التحميل من الكاش
    if (!isRefresh && !_storeItems.containsKey(storeId)) {
      await _loadMenuFromCache(storeId);
    }

    if (!_storeItems.containsKey(storeId)) {
      _isLoadingMenu = true;
      notifyListeners();
    }

    // ب) التحقق من الوقت (10 دقائق للمنتجات)
    if (!isRefresh && _storeItems.containsKey(storeId) && await _isCacheValid('${AppConstants.CACHE_TIMESTAMP_MISWAK_PREFIX}menu_$storeId', minutes: 60)) {
      print("✅ استخدام الكاش لمنتجات المسواك (البيانات حديثة)");
      _isLoadingMenu = false;
      notifyListeners();
      return;
    }

    // ج) جلب من الشبكة
    try {
      final jsonStr = await _apiService.getRawMenu(storeId);

      _processAndSetMenu(storeId, jsonStr);
      await _saveMenuToCache(storeId, jsonStr);

    } catch (e) {
      print("⚠️ فشل تحديث منتجات المسواك: $e");
      if (!_storeItems.containsKey(storeId)) {
        _hasError = true;
        _storeItems[storeId] = [];
      }
    } finally {
      _isLoadingMenu = false;
      notifyListeners();
    }
  }

  void _processAndSetMenu(int storeId, String jsonStr) {
    try {
      final List<dynamic> decoded = json.decode(jsonStr);
      List<FoodItem> items = decoded.map((json) => FoodItem.fromJson(json)).toList();

      Restaurant? store = _allStores.firstWhere(
              (s) => s.id == storeId,
          orElse: () => Restaurant(id: 0, name: '', imageUrl: '', isOpen: false, autoOpenTime: '', autoCloseTime: '', latitude: 0, longitude: 0)
      );

      bool isAvailable = store.isDeliverable && store.isOpen;
      for (var item in items) {
        item.isDeliverable = isAvailable;
      }

      _storeItems[storeId] = items;
    } catch (e) {
      print("Error parsing store items: $e");
      throw Exception('Store Items parsing error');
    }
  }

  // ============================================================
  // 3. دوال إدارة الكاش (Helper Methods)
  // ============================================================
  // 🔥🔥🔥 الحل لمشكلة Watermark (تطبيق الفلترة على الكاش المحمل) 🔥🔥🔥
  Future<void> _loadHomeFromCache(int areaId) async {
    final prefs = await SharedPreferences.getInstance();
    final idsJson = prefs.getString('${AppConstants.CACHE_KEY_MISWAK_HOME_PREFIX}${areaId}_ids');
    final storesJson = prefs.getString('${AppConstants.CACHE_KEY_MISWAK_HOME_PREFIX}${areaId}_list');

    if (idsJson != null && storesJson != null) {
      try {
        // ✅ استخدام دالة التنسيق لتطبيق فلترة المنطقة المتاحة
        _processAndSetHomeData(idsJson, storesJson);
        print("📂 تم تحميل المسواك من الذاكرة.");
      } catch (e) {
        print("Cache data corrupted: $e");
      }
    }
  }

  Future<void> _saveHomeToCache(int areaId, String idsJson, String storesJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${AppConstants.CACHE_KEY_MISWAK_HOME_PREFIX}${areaId}_ids', idsJson);
    await prefs.setString('${AppConstants.CACHE_KEY_MISWAK_HOME_PREFIX}${areaId}_list', storesJson);
    await prefs.setInt('${AppConstants.CACHE_TIMESTAMP_MISWAK_PREFIX}home_$areaId', DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _loadMenuFromCache(int storeId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('${AppConstants.CACHE_KEY_MISWAK_MENU_PREFIX}$storeId');
    if (jsonStr != null) {
      try {
        _processAndSetMenu(storeId, jsonStr);
        notifyListeners();
      } catch (_) {}
    }
  }

  Future<void> _saveMenuToCache(int storeId, String jsonStr) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${AppConstants.CACHE_KEY_MISWAK_MENU_PREFIX}$storeId', jsonStr);
    await prefs.setInt('${AppConstants.CACHE_TIMESTAMP_MISWAK_PREFIX}menu_$storeId', DateTime.now().millisecondsSinceEpoch);
  }

  Future<bool> _isCacheValid(String key, {required int minutes}) async {
    final prefs = await SharedPreferences.getInstance();
    final lastTime = prefs.getInt(key);
    if (lastTime == null) return false;
    final diff = DateTime.now().millisecondsSinceEpoch - lastTime;
    return (diff / 1000 / 60) < minutes;
  }

  Future<void> fetchAllRestaurants(int areaId, {bool isRefresh = false}) async {
    await fetchStoreHomeData(areaId, isRefresh: isRefresh);
  }
}

// ✅ الاسم الجديد: MiswakDashboardProvider
class MiswakDashboardProvider with ChangeNotifier {
  Map<String, List<Order>> _orders = {
    'active': [],
    'completed': []
  };
  RestaurantRatingsDashboard? _ratingsDashboard;
  Map<int, String> _pickupCodes = {};

  bool _isLoading = false;
  String? _error;
  Timer? _debounceTimer;

  Map<String, List<Order>> get orders => _orders;
  RestaurantRatingsDashboard? get ratingsDashboard => _ratingsDashboard;
  Map<int, String> get pickupCodes => _pickupCodes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void startAutoRefresh(String token) {
    _debounceTimer?.cancel();
    // نطلب البيانات مرة واحدة فقط عند فتح الشاشة
    fetchDashboardData(token, silent: false);
  }

  void stopAutoRefresh() {
    _debounceTimer?.cancel();
  }

  void triggerSmartRefresh(String token) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    _debounceTimer = Timer(const Duration(seconds: 3), () {
      fetchDashboardData(token, silent: true);
    });
  }

  void setPickupCode(int orderId, String code) {
    _pickupCodes[orderId] = code;
    notifyListeners();
  }

  Future<void> fetchDashboardData(String? token, {bool silent = false}) async {
    if (token == null) return;

    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final ApiService api = ApiService();

      final activeFromServer = await api.getRestaurantOrders(status: 'active', token: token);
      final completedFromServer = await api.getRestaurantOrders(status: 'completed', token: token);

      List<Order> allOrders = [...activeFromServer, ...completedFromServer];
      final ids = <int>{};
      allOrders.retainWhere((x) => ids.add(x.id));

      List<Order> finalActive = [];
      List<Order> finalCompleted = [];
      final List<String> archiveStatuses = ['completed', 'cancelled', 'refunded', 'failed', 'trash'];

      for (var order in allOrders) {
        if (!archiveStatuses.contains(order.status)) {
          finalActive.add(order);
        } else {
          finalCompleted.add(order);
        }
      }

      finalActive.sort((a, b) => b.dateCreated.compareTo(a.dateCreated));
      finalCompleted.sort((a, b) => b.dateCreated.compareTo(a.dateCreated));

      _orders['active'] = finalActive;
      _orders['completed'] = finalCompleted;

      try {
        final ratings = await api.getDashboardRatings(token);
        _ratingsDashboard = ratings;
      } catch (_) {}

      _error = null;

    } catch (e) {
      if (!silent) _error = "فشل: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
// 🔥 استبدال كامل لكلاس إعدادات المسواك
class MiswakSettingsProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isRestaurantOpen = true;
  String _openTime = '09:00';
  String _closeTime = '22:00';
  bool _isLoading = false;

  bool get isRestaurantOpen => _isRestaurantOpen;
  String get openTime => _openTime;
  String get closeTime => _closeTime;
  bool get isLoading => _isLoading;

  Future<void> fetchSettings(String? token) async {
    if (token == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      final settings = await _apiService.getRestaurantSettings(token);
      _isRestaurantOpen = settings['is_open'] ?? true;
      _openTime = settings['auto_open_time'] ?? '09:00';
      _closeTime = settings['auto_close_time'] ?? '22:00';

      if (settings['restaurant_info'] != null) {
        final prefs = await SharedPreferences.getInstance();
        final info = settings['restaurant_info'];
        if (info['latitude'] != null && info['longitude'] != null) {
          await prefs.setDouble('restaurant_lat', double.tryParse(info['latitude'].toString()) ?? 0.0);
          await prefs.setDouble('restaurant_lng', double.tryParse(info['longitude'].toString()) ?? 0.0);
        }
        if (info['name'] != null) {
          await prefs.setString('restaurant_name', info['name'].toString());
        }
      }
    } catch (e) {
      print("Error fetching settings: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateOpenStatus(String? token, bool isOpen) async {
    if (token == null) return false;
    _isLoading = true;
    notifyListeners();
    try {
      final success = await _apiService.updateRestaurantStatus(token, isOpen);
      if (success) _isRestaurantOpen = isOpen;
      return success;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateAutoTimes(String? token, String openTime, String closeTime) async {
    if (token == null) return false;
    _isLoading = true;
    notifyListeners();
    try {
      final success = await _apiService.updateRestaurantAutoTimes(token, openTime, closeTime);
      if (success) {
        _openTime = openTime;
        _closeTime = closeTime;
      }
      return success;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearData() {
    _isRestaurantOpen = true;
    _openTime = '09:00';
    _closeTime = '22:00';
    notifyListeners();
  }
}
// 🔥 2.3 MiswakProductsProvider (بديل RestaurantProductsProvider)
// 🔥 استبدال كامل لكلاس منتجات المسواك
// ✅ الاسم الجديد: MiswakProductsProvider
class MiswakProductsProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<FoodItem> _allProducts = [];
  List<FoodItem> _filteredProducts = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<FoodItem> get products => _filteredProducts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchProducts(String? token) async {
    if (token == null) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _allProducts = await _apiService.getMyRestaurantProducts(token);
      _filteredProducts = _allProducts;
    } catch (e) {
      _errorMessage = "فشل جلب المنتجات: ${e.toString()}";
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addProduct(String token, String name, String price, String? salePrice, String? description, File? imageFile) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    bool success = false;
    try {
      success = await _apiService.createProduct(token, name, price, salePrice, description, imageFile);
      if (success) {
        await fetchProducts(token);
      }
    } catch (e) {
      _errorMessage = "فشل إضافة المنتج: ${e.toString()}";
      success = false;
    }
    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> updateProduct(String token, int productId, String name, String price, String salePrice, {File? imageFile}) async {
    _isLoading = true;
    notifyListeners();
    bool success = false;
    try {
      success = await _apiService.updateMyProduct(token, productId, name, price, salePrice, imageFile);
      if (success) {
        await fetchProducts(token);
      }
    } catch (e) {
      _errorMessage = "فشل تحديث المنتج: ${e.toString()}";
      success = false;
    }
    _isLoading = false;
    notifyListeners();
    return success;
  }

  void search(String query) {
    if (query.isEmpty) {
      _filteredProducts = _allProducts;
    } else {
      _filteredProducts = _allProducts
          .where((item) => item.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  void clearData() {
    _allProducts = [];
    _filteredProducts = [];
    notifyListeners();
  }
}
class RestaurantProductsProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<FoodItem> _allProducts = [];
  List<FoodItem> _filteredProducts = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<FoodItem> get products => _filteredProducts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchProducts(String? token) async {
    if (token == null) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allProducts = await _apiService.getMyRestaurantProducts(token);
      _filteredProducts = _allProducts;
    } catch (e) {
      _errorMessage = "فشل جلب المنتجات: ${e.toString()}";
    }
    _isLoading = false;
    notifyListeners();
  }

  // ✅ تم إضافة الدالة الصحيحة التي تقبل 6 متغيرات
  Future<bool> addProduct(String token, String name, String price, String? salePrice, String? description, File? imageFile) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    bool success = false;

    try {
      // استدعاء دالة API للإضافة
      success = await _apiService.createProduct(token, name, price, salePrice, description, imageFile);

      if (success) {
        // تحديث القائمة فوراً بعد الإضافة الناجحة
        await fetchProducts(token);
      }
    } catch (e) {
      _errorMessage = "فشل إضافة المنتج: ${e.toString()}";
      success = false;
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> updateProduct(String token, int productId, String name, String price, String salePrice, {File? imageFile}) async {
    _isLoading = true;
    notifyListeners();
    bool success = false;
    try {
      success = await _apiService.updateMyProduct(token, productId, name, price, salePrice, imageFile);
      if (success) {
        await fetchProducts(token);
      }
    } catch (e) {
      _errorMessage = "فشل تحديث المنتج: ${e.toString()}";
      success = false;
    }
    _isLoading = false;
    notifyListeners();
    return success;
  }

  void search(String query) {
    if (query.isEmpty) {
      _filteredProducts = _allProducts;
    } else {
      _filteredProducts = _allProducts
          .where((item) => item.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  void clearData() {
    _allProducts = [];
    _filteredProducts = [];
    notifyListeners();
  }
}
// =======================================================================
// --- MODELS ---
// =======================================================================
class Area {
  final int id;
  final String name;
  final int parentId;
  Area({required this.id, required this.name, required this.parentId});
  factory Area.fromJson(Map<String, dynamic> json) => Area(id: json['id'], name: json['name'], parentId: json['parent']);
}

// في ملف re.dart (داخل قسم MODELS)
// استبدل الكلاس Restaurant القديم بهذا:

// (الصق هذا بدلاً من Restaurant القديم)
class Restaurant {
  final int id;
  final String name;
  final String imageUrl;
  bool isDeliverable; // Flag indicating if it delivers to the selected area
  final double averageRating;
  final int ratingCount;
  // ✨ الحقول الجديدة لحالة المطعم وأوقات العمل
  final bool isOpen; // <<< الحالة النهائية المحسوبة من الخادم (يدوي + تلقائي)
  final String autoOpenTime; // <<< وقت الفتح التلقائي (للعرض فقط)
  final String autoCloseTime; // <<< وقت الإغلاق التلقائي (للعرض فقط)

  // ✨ [إضافة جديدة] إحداثيات المطعم لحساب سعر التوصيل
  final double latitude;
  final double longitude;

  Restaurant({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.isDeliverable = false,
    this.averageRating = 0.0,
    this.ratingCount = 0,
    required this.isOpen,
    required this.autoOpenTime,
    required this.autoCloseTime,
    // ✨ إضافة الإحداثيات
    required this.latitude,
    required this.longitude,
  });

  // ✨ --- تم حذف الـ Getter `isCurrentlyOpen` بالكامل ---
  // ✨ --- تم حذف الدالة المساعدة `_parseTime` بالكامل ---

  // --- toJson() Method ---
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'image': {'src': imageUrl},
    'count': ratingCount,
    'meta_data': [
      {'key': '_wc_average_rating', 'value': averageRating.toString()},
      {'key': '_wc_rating_count', 'value': ratingCount.toString()},
      {'key': '_restaurant_is_open_final_state_received', 'value': isOpen ? '1' : '0'},
      {'key': '_restaurant_auto_open_time', 'value': autoOpenTime},
      {'key': '_restaurant_auto_close_time', 'value': autoCloseTime},
      // ✨ إضافة الإحداثيات
      {'key': 'restaurant_latitude', 'value': latitude.toString()},
      {'key': 'restaurant_longitude', 'value': longitude.toString()},
    ],
  };

  // --- Factory fromJson (هذا هو الإصلاح الأهم) ---
  factory Restaurant.fromJson(Map<String, dynamic> json) {
    double avgRating = 0.0;
    int rCount = 0;
    String openTime = '00:00';
    String closeTime = '23:59';
    bool finalIsOpenStatus = true; // الافتراضي: مفتوح
    double lat = 0.0;
    double lng = 0.0;

    if (json['meta_data'] != null && json['meta_data'] is List) {
      final metaData = json['meta_data'] as List;

      var ratingMeta = metaData.firstWhere((m) => m is Map && m['key'] == '_wc_average_rating', orElse: () => null);
      if (ratingMeta != null) avgRating = double.tryParse(ratingMeta['value'].toString()) ?? 0.0;

      var countMeta = metaData.firstWhere((m) => m is Map && m['key'] == '_wc_rating_count', orElse: () => null);
      if (countMeta != null) rCount = int.tryParse(countMeta['value'].toString()) ?? 0;

      // ✨ --- [ الإصلاح 1: قراءة الحالة من الخادم ] ---
      // هذا يقرأ النتيجة التي أرسلها الخادم (CLOSED)
      var isOpenMeta = metaData.firstWhere((m) => m is Map && m['key'] == '_restaurant_is_open', orElse: () => null);
      if (isOpenMeta != null) {
        finalIsOpenStatus = isOpenMeta['value'].toString() == '1';
      }
      // --- نهاية الإصلاح ---

      var openMeta = metaData.firstWhere((m) => m is Map && m['key'] == '_restaurant_auto_open_time', orElse: () => null);
      if (openMeta != null) openTime = openMeta['value'].toString();

      var closeMeta = metaData.firstWhere((m) => m is Map && m['key'] == '_restaurant_auto_close_time', orElse: () => null);
      if (closeMeta != null) closeTime = closeMeta['value'].toString();

      // ✨ --- [ الإصلاح 2: قراءة الإحداثيات لسعر التوصيل ] ---
      var latMeta = metaData.firstWhere((m) => m is Map && m['key'] == 'restaurant_latitude', orElse: () => null);
      if (latMeta != null) lat = double.tryParse(latMeta['value'].toString()) ?? 0.0;

      var lngMeta = metaData.firstWhere((m) => m is Map && m['key'] == 'restaurant_longitude', orElse: () => null);
      if (lngMeta != null) lng = double.tryParse(lngMeta['value'].toString()) ?? 0.0;
      // --- نهاية الإصلاح ---
    }

    return Restaurant(
      id: json['id'],
      name: json['name'] ?? 'اسم غير معروف',
      imageUrl: json['image'] != null && json['image']['src'] != false
          ? json['image']['src']
          : 'https://via.placeholder.com/300',
      averageRating: avgRating,
      ratingCount: rCount,
      isOpen: finalIsOpenStatus, // <-- استخدام الحالة القادمة من الخادم
      autoOpenTime: openTime,
      autoCloseTime: closeTime,
      latitude: lat, // <-- إضافة الإحداثيات
      longitude: lng, // <-- إضافة الإحداثيات
    );
  }
}

class FoodItem {
  final int id;
  final String name;
  final String description;
  final double price;
  final double? salePrice;
  final String imageUrl;
  int quantity;
  final int categoryId;
  bool isDeliverable;
  final double averageRating;
  final int ratingCount;

  // ✨ حقول لاستقبال موقع المطعم مع المنتج
  final double restaurantLat;
  final double restaurantLng;

  // ✨✨ [هذا هو المتغير الناقص الذي سبب الخطأ] ✨✨
  double selectedWeight;

  FoodItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.salePrice,
    required this.imageUrl,
    this.quantity = 1,
    required this.categoryId,
    this.isDeliverable = false,
    this.averageRating = 0.0,
    this.ratingCount = 0,
    this.restaurantLat = 0.0,
    this.restaurantLng = 0.0,
    // الافتراضي 1.0 (كيلو أو قطعة) حتى لا يحدث خطأ للمطاعم
    this.selectedWeight = 1.0,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    double safeParseDouble(dynamic value, [double defaultValue = 0.0]) {
      if (value == null) return defaultValue;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      return double.tryParse(value.toString().trim()) ?? defaultValue;
    }

    int safeParseInt(dynamic value, [int defaultValue = 0]) {
      if (value == null) return defaultValue;
      return int.tryParse(value.toString()) ?? defaultValue;
    }

    String extractImageUrl(dynamic images) {
      if (images is List && images.isNotEmpty && images[0] is Map && images[0]['src'] != null) {
        return images[0]['src'];
      }
      return 'https://via.placeholder.com/150';
    }

    int extractRestaurantId(Map<String, dynamic> json) {
      if (json['meta_data'] != null && json['meta_data'] is List) {
        final metaData = json['meta_data'] as List;
        var parentIdMeta = metaData.firstWhere((m) => m is Map && m['key'] == '_restaurant_parent_id', orElse: () => null);
        if (parentIdMeta != null && parentIdMeta['value'] != null) {
          return int.tryParse(parentIdMeta['value'].toString()) ?? 0;
        }
      }
      dynamic categories = json['categories'];
      if (categories is List && categories.isNotEmpty && categories[0] is Map) {
        return categories[0]['id'];
      }
      return 0;
    }

    String cleanDescription(dynamic desc) {
      if (desc is String) return desc.replaceAll(RegExp(r'<[^>]*>|&nbsp;'), '').trim();
      return '';
    }

    double rLat = 0.0;
    double rLng = 0.0;
    if (json['meta_data'] != null && json['meta_data'] is List) {
      final metaData = json['meta_data'] as List;
      var latMeta = metaData.firstWhere((m) => m is Map && m['key'] == 'restaurant_latitude', orElse: () => null);
      if (latMeta != null) rLat = safeParseDouble(latMeta['value']);
      var lngMeta = metaData.firstWhere((m) => m is Map && m['key'] == 'restaurant_longitude', orElse: () => null);
      if (lngMeta != null) rLng = safeParseDouble(lngMeta['value']);
    }

    return FoodItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'اسم غير متوفر',
      description: cleanDescription(json['short_description']),
      price: safeParseDouble(json['regular_price']),
      salePrice: (json['sale_price'] != '' && json['sale_price'] != null) ? safeParseDouble(json['sale_price'], -1.0) : null,
      imageUrl: extractImageUrl(json['images']),
      categoryId: extractRestaurantId(json),
      averageRating: safeParseDouble(json['average_rating']),
      ratingCount: safeParseInt(json['rating_count']),
      restaurantLat: rLat,
      restaurantLng: rLng,
      selectedWeight: 1.0,
    );
  }

  // ✨ حساب السعر النهائي (السعر الأساسي * الوزن)
  double get displayPrice {
    double base = salePrice != null && salePrice! >= 0 ? salePrice! : price;
    return base * selectedWeight;
  }

  // ✨ تنسيق السعر
  String get formattedPrice {
    final format = NumberFormat('#,###', 'ar_IQ');
    return '${format.format(displayPrice)} د.ع';
  }

  // ✨ نص يعرض الوزن بشكل جميل (يستخدم في السلة)
  String get weightLabel {
    if (selectedWeight == 0.25) return "ربع كيلو (250غم)";
    if (selectedWeight == 0.5) return "نصف كيلو (500غم)";
    if (selectedWeight == 1.0) return "1 كيلو";
    if (selectedWeight % 1 == 0) return "${selectedWeight.toInt()} كيلو";
    return "$selectedWeight كيلو";
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'quantity': quantity,
    'categoryId': categoryId,
    'selectedWeight': selectedWeight, // حفظ الوزن
  };
}


class Order {
  final int id;
  final String status;
  final DateTime dateCreated;
  final String total;
  final String customerName;
  final String address;
  final String phone;
  final List<LineItem> lineItems;
  final String? destinationLat;
  final String? destinationLng;
  final String shippingTotal; // ✨ جديد: سعر التوصيل

  Order({
    required this.id,
    required this.status,
    required this.dateCreated,
    required this.total,
    required this.customerName,
    required this.address,
    required this.phone,
    required this.lineItems,
    this.destinationLat,
    this.destinationLng,
    required this.shippingTotal, // ✨
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'status': status,
    'date_created': dateCreated.toIso8601String(),
    'total': total,
    'customerName': customerName,
    'address': address,
    'phone': phone,
    'line_items': lineItems.map((item) => item.toJson()).toList(),
  };

  factory Order.fromJson(Map<String, dynamic> json) {
    final billing = json['billing'] as Map<String, dynamic>?;
    final shipping = json['shipping'] as Map<String, dynamic>?;
    return Order(
      id: json['id'],
      status: json['status'],
      dateCreated: DateTime.parse(json['date_created']),
      total: json['total'].toString(),
      customerName: json['customerName'] ?? '${billing?['first_name'] ?? ''} ${billing?['last_name'] ?? ''}'.trim(),
      address: json['address'] ?? shipping?['address_1'] ?? billing?['address_1'] ?? 'N/A',
      phone: json['phone'] ?? billing?['phone'] ?? 'N/A',
      lineItems: (json['line_items'] as List).map((i) => LineItem.fromJson(i)).toList(),
      destinationLat: json['destination_lat'],
      destinationLng: json['destination_lng'],
      // ✨ قراءة سعر التوصيل التلقائي
      shippingTotal: json['shipping_total'] ?? '0',
    );
  }

  Map<String, dynamic> get statusDisplay {
    switch (status) {
      case 'processing':
        return {'text': 'جاري تحضير الطلب', 'icon': Icons.soup_kitchen_outlined, 'color': Colors.blue};
      case 'out-for-delivery':
      // ✨ تغيير النص
        return {'text': 'المندوب قادم إليك 🛵', 'icon': Icons.delivery_dining, 'color': Colors.orange.shade700};
      case 'completed':
        return {'text': 'تم توصيل الطلب', 'icon': Icons.check_circle, 'color': Colors.green};
      case 'cancelled':
        return {'text': 'تم إلغاء الطلب', 'icon': Icons.cancel, 'color': Colors.red};
      case 'pending':
      default:
        return {'text': 'تم استلام الطلب', 'icon': Icons.receipt_long, 'color': Colors.grey.shade700};
    }
  }
}
class LineItem {
  final String name;
  final int quantity;
  final String total;
  LineItem({required this.name, required this.quantity, required this.total});
  Map<String, dynamic> toJson() => {'name': name, 'quantity': quantity, 'total': total};
  factory LineItem.fromJson(Map<String, dynamic> json) => LineItem(name: json['name'], quantity: json['quantity'], total: json['total'].toString());
}
class RestaurantRatingsDashboard {
  final double averageRating;
  final int totalReviews;
  final List<Review> recentReviews;
  RestaurantRatingsDashboard({required this.averageRating, required this.totalReviews, required this.recentReviews});

  // --- Keep ONLY ONE toJson() Method ---
  Map<String, dynamic> toJson() => {
    'average_rating': averageRating,
    'total_reviews': totalReviews,
    'recent_reviews': recentReviews.map((r) => r.toJson()).toList(), // Requires toJson in Review
  };
  // --- End toJson() Method ---


  factory RestaurantRatingsDashboard.fromJson(Map<String, dynamic> json) => RestaurantRatingsDashboard(
    averageRating: (json['average_rating'] as num).toDouble(),
    totalReviews: json['total_reviews'],
    recentReviews: (json['recent_reviews'] as List).map((i) => Review.fromJson(i)).toList(),
  );
} // End of RestaurantRatingsDashboard class
class Review {
  final String productName;
  final String author;
  final int rating;
  final String content;
  final DateTime date;
  Review({required this.productName, required this.author, required this.rating, required this.content, required this.date});

  // --- Add this toJson() Method ONCE inside the class ---
  Map<String, dynamic> toJson() => {
    'product_name': productName,
    'author': author,
    'rating': rating,
    'content': content,
    'date': date.toIso8601String(), // Save date as text
  };
  // --- End toJson() Method ---


  factory Review.fromJson(Map<String, dynamic> json) => Review(
    productName: json['product_name'],
    author: json['author'],
    rating: json['rating'],
    content: json['content'],
    date: DateTime.parse(json['date']),
  );
} // End of Review class
// =======================================================================
// --- SERVICES ---
// =======================================================================
class DeliveryConfig {
  final double baseFee;
  final double feePerKm;
  final double maxDistanceKm;

  DeliveryConfig({
    required this.baseFee,
    required this.feePerKm,
    required this.maxDistanceKm,
  });

  factory DeliveryConfig.fromJson(Map<String, dynamic> json) {
    return DeliveryConfig(
      baseFee: (json['base_fee'] as num? ?? 1500).toDouble(),
      feePerKm: (json['fee_per_km'] as num? ?? 500).toDouble(),
      maxDistanceKm: (json['max_distance_km'] as num? ?? 25).toDouble(),
    );
  }
}
// =======================================================================
// --- Delivery Provider (Server-Side Calculation) ---
// =======================================================================
class DeliveryProvider with ChangeNotifier {
  // متغيرات الواجهة
  double _deliveryFee = 0.0;
  String _message = "";
  bool _isLoading = false;
  bool _hasError = false;

  // بيانات الكاش
  List<dynamic> _zones = [];
  Map<int, LatLng> _storeLocations = {};
  double _defaultBaseFee = 1000.0;

  // Getters
  double get deliveryFee => _deliveryFee;
  String get message => _message;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;

  // مفاتيح التخزين
  static const String KEY_CONFIG = "delivery_config_json_v2";
  static const String KEY_LAST_FETCH = "delivery_config_last_fetch_v2";

  // --- 1. دالة التهيئة (تحميل البيانات عند فتح التطبيق) ---
  @override
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final lastFetch = prefs.getInt(KEY_LAST_FETCH) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // تحديث الكاش كل 7 أيام أو إذا كان فارغاً
    if (now - lastFetch > 7 * 24 * 60 * 60 * 1000 || !prefs.containsKey(KEY_CONFIG)) {
      await refreshConfigFromServer();
    } else {
      _parseConfig(prefs.getString(KEY_CONFIG)!);
    }
  }

  Future<void> refreshConfigFromServer() async {
    try {
      final response = await http.get(
          Uri.parse('https://beytei.com/wp-json/restaurant-app/v1/delivery-config-full')
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(KEY_CONFIG, response.body);
        await prefs.setInt(KEY_LAST_FETCH, DateTime.now().millisecondsSinceEpoch);
        _parseConfig(response.body);
      }
    } catch (e) {
      print("⚠️ Error refreshing config: $e");
    }
  }

  void _parseConfig(String jsonStr) {
    try {
      final data = json.decode(jsonStr);
      _zones = data['zones'] ?? [];
      _storeLocations.clear();
      for (var loc in data['locations']) {
        _storeLocations[loc['id']] = LatLng(
            double.parse(loc['lat'].toString()),
            double.parse(loc['lng'].toString())
        );
      }
      _defaultBaseFee = double.parse(data['pricing']['base_fee'].toString());
      notifyListeners();
    } catch (e) {
      print("❌ Parse Error: $e");
    }
  }

  // --- 2. 🔥 دالة الحساب الفوري (Instant Calculation) ---
  Future<void> calculateDeliveryFee({
    required int restaurantId,
    required double userLat,
    required double userLng,
  }) async {
    _isLoading = true;
    _message = "جاري حساب التكلفة...";
    notifyListeners();

    // محاكاة تأخير بسيط جداً لإعطاء شعور بالعملية (اختياري)
    await Future.delayed(const Duration(milliseconds: 100));

    final userPos = LatLng(userLat, userLng);

    // أ) فحص إذا كان الزبون داخل منطقة مرسومة (Polygon)
    for (var zone in _zones) {
      if (_isPointInPolygon(userPos, zone['latlngs'])) {
        _deliveryFee = double.parse(zone['price'].toString());
        _message = "✅ موقعك ضمن (${zone['name']}). أجرة ثابتة.";
        _isLoading = false;
        _hasError = false;
        notifyListeners();
        return;
      }
    }

    // ب) إذا لم يكن في منطقة، الحساب بناءً على المسافة
    final storePos = _storeLocations[restaurantId];
    if (storePos != null) {
      final distance = const Distance().as(LengthUnit.Kilometer, userPos, storePos);

      // تطبيق معادلة المسافة (مثال: أول 5 كم بـ 1000، ثم 250 لكل كم إضافي)
      double fee = _defaultBaseFee;
      if (distance > 5) {
        fee += (distance - 5) * 250;
      }

      _deliveryFee = (fee / 250).ceil() * 250.0; // تقريب لأقرب 250
      if (_deliveryFee > 2000) _deliveryFee = 2000; // سقف السعر

      _message = "📏 المسافة من المتجر: ${distance.toStringAsFixed(1)} كم.";
    } else {
      _deliveryFee = _defaultBaseFee;
      _message = "تم استخدام السعر الافتراضي.";
    }

    _isLoading = false;
    _hasError = false;
    notifyListeners();
  }

  // خوارزمية فحص النقطة داخل المضلع (Ray Casting)
  bool _isPointInPolygon(LatLng point, dynamic polygonData) {
    List<dynamic> points = polygonData is List && polygonData[0] is List ? polygonData[0] : polygonData;
    var intersections = 0;

    for (var i = 0; i < points.length; i++) {
      var p1 = points[i];
      var p2 = points[(i + 1) % points.length];

      double p1Lat = double.parse(p1['lat'].toString());
      double p1Lng = double.parse(p1['lng'].toString());
      double p2Lat = double.parse(p2['lat'].toString());
      double p2Lng = double.parse(p2['lng'].toString());

      if (p1Lng > point.longitude != p2Lng > point.longitude &&
          point.latitude < (p2Lat - p1Lat) * (point.longitude - p1Lng) / (p2Lng - p1Lng) + p1Lat) {
        intersections++;
      }
    }
    return intersections % 2 != 0;
  }

  void reset() {
    _deliveryFee = 0.0;
    _message = "";
    _hasError = false;
    notifyListeners();
  }
}



class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'تنبيهات الطلبات العاجلة',
    description: 'هذه القناة مخصصة لتنبيه السائقين والمسواك والمطاعم.',
    importance: Importance.max,
    playSound: true,
    // ✨ 1. تحديد الصوت للقناة (للأندرويد 8 وما فوق)
    sound: RawResourceAndroidNotificationSound('woo_sound.mp3'),
    enableVibration: true,
  );

  static Future<void> initialize() async {
    // ... (نفس كود initialize السابق، لا تغيير فيه) ...
    // لكن تأكد من هذا السطر لإنشاء القناة بالصوت الجديد:
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  static Future<void> display(RemoteMessage message) async {
    try {
      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          // ✨ 2. تحديد الصوت للإشعار الفردي (للأندرويد القديم)
          sound: const RawResourceAndroidNotificationSound('woo_sound'),
          enableVibration: true,
          fullScreenIntent: true,
          styleInformation: const BigTextStyleInformation(''),
        ),
        iOS: const DarwinNotificationDetails(
          presentSound: true,
          // ✨ 3. تحديد الصوت للآيفون
          sound: 'woo_sound.caf', // تأكد من الامتداد الصحيح
        ),
      );

      await _localNotifications.show(
        id,
        message.notification?.title ?? message.data['title'] ?? 'تنبيه جديد',
        message.notification?.body ?? message.data['body'] ?? '',
        platformChannelSpecifics,
        payload: message.data['order_id'],
      );
    } catch (e) {
      print("خطأ في عرض الإشعار: $e");
    }
  }
}
class CacheService {
  Future<void> saveData(String key, String data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, data);
  }

  Future<String?> getData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  Future<void> clearAllCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (String key in keys) {
      if (key != 'jwt_token' && key != 'selectedAreaId' && key != 'selectedAreaName') {
        await prefs.remove(key);
      }
    }
  }
}

// =======================================================================
// --- خدمة سجل الطلبات الموحدة (للمسواك والمطاعم) ---
// =======================================================================
class OrderHistoryService {
  // ✅ استخدام نفس المفتاح المشترك لتوحيد السجل بين النظامين
  static const _key = 'order_history';

  /// 1️⃣ دالة حفظ طلب جديد (لأول مرة)
  Future<void> saveOrder(Order order) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Order> orders = await getOrders();

    // إزالة النسخة القديمة إن وجدت لتجنب التكرار
    orders.removeWhere((o) => o.id == order.id);

    // إضافة الطلب الجديد في البداية (الأحدث أولاً)
    orders.insert(0, order);

    // حفظ القائمة المحدثة في الذاكرة المحلية
    final String encodedData = json.encode(
        orders.map<Map<String, dynamic>>((o) => o.toJson()).toList()
    );
    await prefs.setString(_key, encodedData);

    print("💾 [OrderHistory] تم حفظ الطلب #${order.id} في السجل المحلي");
  }

  /// 2️⃣ دالة جلب كل الطلبات المخزنة محلياً
  Future<List<Order>> getOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final String? ordersString = prefs.getString(_key);

    if (ordersString != null) {
      try {
        final List<dynamic> decodedData = json.decode(ordersString);
        return decodedData.map<Order>((item) => Order.fromJson(item)).toList();
      } catch (e) {
        print("❌ [OrderHistory] خطأ في قراءة السجل المحلي: $e");
        return [];
      }
    }
    return [];
  }

  /// 3️⃣ 🔥 دالة تحديث حالة طلب موجود محلياً (مهمة جداً لتحديث الحالة فوراً)
  Future<void> updateOrderStatusLocally(int orderId, String newStatus) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? ordersString = prefs.getString(_key);

      if (ordersString != null) {
        List<dynamic> decodedData = json.decode(ordersString);
        bool isUpdated = false;

        // البحث عن الطلب وتحديث حالته فقط
        for (var i = 0; i < decodedData.length; i++) {
          if (decodedData[i]['id'] == orderId) {
            decodedData[i]['status'] = newStatus;
            isUpdated = true;
            print("🔄 [OrderHistory] تم تحديث الطلب #$orderId محلياً إلى: $newStatus");
            break;
          }
        }

        // إذا تم التعديل، نحفظ القائمة الجديدة
        if (isUpdated) {
          await prefs.setString(_key, json.encode(decodedData));
        }
      }
    } catch (e) {
      print("⚠️ [OrderHistory] خطأ أثناء التحديث المحلي: $e");
    }
  }

  /// 4️⃣ دالة مسح السجل المحلي (لأغراض الصيانة أو تسجيل الخروج)
  Future<void> clearLocalHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    print("🗑️ [OrderHistory] تم مسح السجل المحلي");
  }

  /// 5️⃣ دالة جلب الطلبات النشطة فقط (للعرض السريع)
  Future<List<Order>> getActiveOrders() async {
    final allOrders = await getOrders();
    final activeStatuses = [
      'pending',
      'processing',
      'on-hold',
      'accepted',
      'at_store',
      'picked_up',
      'out-for-delivery',
      'driver-assigned'
    ];

    return allOrders.where((order) {
      return activeStatuses.contains(order.status.toLowerCase());
    }).toList();
  }

  /// 6️⃣ دالة جلب الطلبات المكتملة/المنتهية فقط
  Future<List<Order>> getCompletedOrders() async {
    final allOrders = await getOrders();
    final completedStatuses = [
      'completed',
      'cancelled',
      'refunded',
      'failed',
      'trash'
    ];

    return allOrders.where((order) {
      return completedStatuses.contains(order.status.toLowerCase());
    }).toList();
  }
}
// في ملف re.dart (تحت قسم WIDGETS)

class LoyaltyChallengeWidget extends StatefulWidget {
  const LoyaltyChallengeWidget({super.key});

  @override
  State<LoyaltyChallengeWidget> createState() => _LoyaltyChallengeWidgetState();
}

class _LoyaltyChallengeWidgetState extends State<LoyaltyChallengeWidget> {
  // للتحكم في ظهور الإشعار لمرة واحدة في الجلسة
  bool _isVisible = true;

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final status = cartProvider.getLoyaltyChallengeStatus;

    if (!status['show'] || !_isVisible) {
      return const SizedBox.shrink();
    }

    // ✨ تحديد لون الخلفية والأيقونة بناءً على حالة التقدم
    Color backgroundColor = cartProvider.usageCount >= 3 ? Colors.amber.shade700 : Colors.teal.shade500;
    IconData icon = cartProvider.usageCount >= 3 ? Icons.celebration : Icons.local_fire_department;
    String title = cartProvider.usageCount >= 3 ? 'خصم الولاء متاح!' : 'تحدي جديد!';

    return Container(
      margin: const EdgeInsets.only(bottom: 15, left: 15, right: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: backgroundColor.withOpacity(0.4), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              GestureDetector(
                onTap: () {
                  setState(() => _isVisible = false); // إخفاء الإشعار بعد النقر
                },
                child: const Icon(Icons.close, color: Colors.white70, size: 20),
              ),
            ],
          ),
          const Divider(color: Colors.white54, height: 15),
          Text(status['message']!, style: const TextStyle(color: Colors.white, fontSize: 14)),
          if (cartProvider.promoterCode != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'رمزك: ${cartProvider.promoterCode}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, decoration: TextDecoration.underline),
              ),
            ),
        ],
      ),
    );
  }
}
// (الصق هذا الكلاس بالكامل بدلاً من CartProvider القديم)
class CartProvider with ChangeNotifier {
  final List<FoodItem> _items = [];

  List<FoodItem> get items => _items;

  int get cartCount => _items.fold(0, (sum, item) => sum + item.quantity);

  // السعر الكلي (يعتمد على displayPrice في FoodItem الذي يحسب السعر × الوزن)
  double get totalPrice => _items.fold(0.0, (sum, item) => sum + (item.displayPrice * item.quantity));

  String? _appliedCoupon;
  double _discountPercentage = 0.0;
  double _discountAmount = 0.0;
  String _discountType = '';

  // ✨ متغيرات نظام الولاء (المروج)
  String? _promoterCode;
  int _usageCount = 0;
  double _loyaltyDiscountPercentage = 0.0;

  String? get appliedCoupon => _appliedCoupon;
  String? get promoterCode => _promoterCode;
  int get usageCount => _usageCount;

  // ✨✨✨ دالة مقارنة الأوزان بدقة (الحل الأساسي للمشكلة) ✨✨✨
  bool _weightsAreEqual(double w1, double w2) {
    return (w1 - w2).abs() < 0.001;
  }

  // --- حساب الخصومات ---
  double get totalDiscountAmount {
    double couponDiscount = 0.0;
    if (_discountType == 'fixed_cart') {
      couponDiscount = _discountAmount;
    } else if (_discountType == 'percent') {
      couponDiscount = totalPrice * (_discountPercentage / 100);
    }
    double loyaltyDiscount = totalPrice * (_loyaltyDiscountPercentage / 100);
    return max(couponDiscount, loyaltyDiscount);
  }

  double get discountedTotal {
    return (totalPrice - totalDiscountAmount).clamp(0, double.infinity);
  }

  // --- إدارة نظام الولاء ---
  Future<int> _loadUsageCount(String code) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('promoter_usage_$code') ?? 0;
  }

  Future<void> _recordSuccessfulOrder() async {
    final prefs = await SharedPreferences.getInstance();
    if (_promoterCode != null) {
      int currentCount = await _loadUsageCount(_promoterCode!);
      if (currentCount < 3) {
        await prefs.setInt('promoter_usage_$_promoterCode', currentCount + 1);
      } else {
        await prefs.setInt('promoter_usage_$_promoterCode', 0);
      }
    }
  }

  Map<String, dynamic> get getLoyaltyChallengeStatus {
    if (_promoterCode == null) {
      return {'show': false, 'message': 'لا يوجد رمز مروج مفعل.'};
    }
    if (_usageCount == 3) {
      return {'show': true, 'message': '🎉 تهانينا! خصم الـ 50% متاح الآن على سلتك!'};
    }
    final remaining = 3 - _usageCount;
    return {
      'show': true,
      'message': 'أنت في مرحلة الطلب رقم (${_usageCount + 1}). تبقى لك ${remaining} طلب للحصول على خصم ٥٠٪!',
    };
  }

  // --- إدارة الكوبونات ---
  Future<Map<String, dynamic>> applyCoupon(String code) async {
    final result = await ApiService().validateCoupon(code);
    if (result['is_promoter'] == true) {
      _promoterCode = code.toUpperCase();
      _usageCount = await _loadUsageCount(_promoterCode!);
      if (_usageCount == 3) {
        _loyaltyDiscountPercentage = 50.0;
        _discountType = 'loyalty_discount';
        result['message'] = '🎉 تهانينا! خصم ٥٠٪ على هذا الطلب مفعل.';
      } else {
        _loyaltyDiscountPercentage = 0.0;
        _discountType = '';
        final remaining = 3 - _usageCount;
        result['message'] = "تم تفعيل رمز المروج. تبقى ${remaining} طلب للحصول على خصم ٥٠٪!";
      }
      _appliedCoupon = null;
      _discountAmount = 0.0;
      _discountPercentage = 0.0;
      notifyListeners();
      return result;
    } else if (result['valid'] == true) {
      _appliedCoupon = code.toUpperCase();
      _discountType = result['discount_type'];
      _discountAmount = double.tryParse(result['amount'].toString()) ?? 0.0;
      if (_discountType == 'percent') _discountPercentage = _discountAmount;
      _promoterCode = null;
      _loyaltyDiscountPercentage = 0.0;
      notifyListeners();
      return result;
    }
    return result;
  }

  void removeCoupon() {
    _appliedCoupon = null;
    _discountPercentage = 0.0;
    _discountAmount = 0.0;
    _discountType = '';
    _promoterCode = null;
    _loyaltyDiscountPercentage = 0.0;
    notifyListeners();
  }

  // --- 🔥 إدارة السلة (الإضافة والتعديل) - ✅ مُصلح 🔥 ---

  void addToCart(FoodItem foodItem, BuildContext context, {double weight = 1.0}) {
    if (!foodItem.isDeliverable) {
      _showItemUnavailableDialog(context, foodItem);
      return;
    }

    // ✅ البحث عن منتج بنفس المعرف ونفس الوزن باستخدام المقارنة الدقيقة
    final existingIndex = _items.indexWhere((item) =>
    item.id == foodItem.id && _weightsAreEqual(item.selectedWeight, weight)
    );

    if (existingIndex != -1) {
      // إذا وجد نفس المنتج بنفس الوزن، نزيد الكمية
      _items[existingIndex].quantity++;
    } else {
      // إذا لم يوجد، نضيف كعنصر جديد مع الوزن المحدد
      _items.add(FoodItem(
        id: foodItem.id,
        name: foodItem.name,
        description: foodItem.description,
        price: foodItem.price,
        salePrice: foodItem.salePrice,
        imageUrl: foodItem.imageUrl,
        quantity: 1,
        categoryId: foodItem.categoryId,
        isDeliverable: foodItem.isDeliverable,
        restaurantLat: foodItem.restaurantLat,
        restaurantLng: foodItem.restaurantLng,
        averageRating: foodItem.averageRating,
        ratingCount: foodItem.ratingCount,
        // ✅ حفظ الوزن المختار بدقة
        selectedWeight: weight,
      ));
    }
    notifyListeners();
    _showAddToCartDialog(context, foodItem, weight);
  }

  void incrementQuantity(FoodItem foodItem) {
    // ✅ البحث بالمعرف والوزن معاً باستخدام المقارنة الدقيقة
    final itemIndex = _items.indexWhere((item) =>
    item.id == foodItem.id && _weightsAreEqual(item.selectedWeight, foodItem.selectedWeight)
    );

    if (itemIndex != -1) {
      _items[itemIndex].quantity++;
      notifyListeners();
    }
  }

  void decrementQuantity(FoodItem foodItem) {
    // ✅ البحث بالمعرف والوزن معاً باستخدام المقارنة الدقيقة
    final itemIndex = _items.indexWhere((item) =>
    item.id == foodItem.id && _weightsAreEqual(item.selectedWeight, foodItem.selectedWeight)
    );

    if (itemIndex != -1) {
      if (_items[itemIndex].quantity > 1) {
        _items[itemIndex].quantity--;
      } else {
        _items.removeAt(itemIndex);
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    removeCoupon();
    notifyListeners();
  }

  // --- نوافذ التنبيه ---
  void _showItemUnavailableDialog(BuildContext context, FoodItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("عذراً، المنتج غير متاح"),
        content: Text("لا يمكن إضافة '${item.name}' إلى السلة لأن المتجر مغلق حالياً."),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("حسناً")),
        ],
      ),
    );
  }

  void _showAddToCartDialog(BuildContext context, FoodItem item, double weight) {
    // ✨ تجهيز نص الوزن للعرض بشكل جميل
    String weightText = _getWeightDisplayText(weight);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 10),
            Text("تمت الإضافة", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.scale, size: 16, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 5),
                  Text('الوزن: $weightText', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("تابع التسوق"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Provider.of<NavigationProvider>(context, listen: false).changeTab(3);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("الذهاب للسلة"),
          ),
        ],
      ),
    );
  }

  // ✨ دالة مساعدة لعرض الوزن بشكل جميل
  String _getWeightDisplayText(double weight) {
    if (weight == 0.25) return "ربع كيلو (250غم)";
    if (weight == 0.5) return "نصف كيلو (500غم)";
    if (weight == 1.0) return "1 كيلو";
    if (weight == 1.5) return "كيلو ونصف (1.5 كغم)";
    if (weight % 1 == 0) return "${weight.toInt()} كيلو";
    return "$weight كيلو";
  }
}

// =======================================================================
// --- API SERVICE (المعدل والنهائي) ---
// =======================================================================
class ApiService {
  final String _authString = 'Basic ${base64Encode(utf8.encode('$CONSUMER_KEY:$CONSUMER_SECRET'))}';
  final CacheService _cacheService = CacheService();

  // =================================================================
  // 🔥 1. دالة التنفيذ الذكي (Exponential Backoff) - المحدثة
  // =================================================================
  Future<T> _executeWithRetry<T>(Future<T> Function() action) async {
    int attempts = 0;
    while (attempts < 3) {
      try {
        return await action().timeout(API_TIMEOUT);
      } catch (e) {
        attempts++;
        String errorString = e.toString();

        // 🛑 توقف فوراً في حالة الحظر أو الأخطاء الصريحة
        if (errorString.contains('403') || errorString.contains('429') || errorString.contains('صلاحيات')) {
          print("⛔ تم إيقاف المحاولات لتجنب الحظر أو لعدم الصلاحية: $errorString");
          rethrow;
        }

        if (attempts >= 3) rethrow;

        // ⏳ انتظار تصاعدي (2 ثانية، 4 ثواني...)
        int delaySeconds = pow(2, attempts).toInt();
        print("⚠️ فشل الطلب (محاولة $attempts)، انتظار $delaySeconds ثواني...");
        await Future.delayed(Duration(seconds: delaySeconds));
      }
    }
    throw Exception('Failed after multiple retries');
  }

  // =================================================================
  // 2. دوال المتجر / المدير (Store Manager Methods)
  // =================================================================

  // ✅ جلب الطلبات (مع طباعة الخطأ)
  Future<List<Order>> getRestaurantOrders({required String status, required String token}) async {
    return _executeWithRetry(() async {
      final uri = Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/get-orders?status=$status');
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return (json.decode(response.body) as List).map((json) => Order.fromJson(json)).toList();
      }

      // 🔥 طباعة الخطأ الحقيقي من السيرفر
      print("❌ API Error [getOrders]: Code ${response.statusCode}, Body: ${response.body}");

      if (response.statusCode == 403) {
        throw Exception("صلاحيات غير كافية (403): تأكد من ربط حساب المدير بمتجر في ووردبريس.");
      }

      throw Exception('Failed to load orders: ${response.statusCode}');
    });
  }

  // ✅ جلب المنتجات (مع طباعة الخطأ)
  Future<List<FoodItem>> getMyRestaurantProducts(String token) async {
    return _executeWithRetry(() async {
      final response = await http.get(
        Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/my-products'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        return data.map((json) => FoodItem.fromJson(json)).toList();
      }

      // 🔥 طباعة الخطأ الحقيقي
      print("❌ API Error [getProducts]: Code ${response.statusCode}, Body: ${response.body}");

      throw Exception('Failed to load restaurant products: ${response.statusCode}');
    });
  }

  // ✅ جلب الإعدادات (مع طباعة الخطأ)
  Future<Map<String, dynamic>> getRestaurantSettings(String token) async {
    return _executeWithRetry(() async {
      final response = await http.get(
        Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/get-settings'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }

      // 🔥 طباعة الخطأ الحقيقي
      print("❌ API Error [getSettings]: Code ${response.statusCode}, Body: ${response.body}");

      throw Exception('Failed to load settings: ${response.statusCode}');
    });
  }

  // إضافة منتج (نسخة التصحيح Debug Version)
  Future<bool> createProduct(String token, String name, String price, String? salePrice, String? description, File? imageFile) async {
    return _executeWithRetry(() async {
      String? imageBase64;
      if (imageFile != null) {
        List<int> imageBytes = await imageFile.readAsBytes();
        imageBase64 = base64Encode(imageBytes);
      }

      print("🚀 جاري إرسال طلب إضافة المنتج...");
      print("Token: ${token.substring(0, 10)}...");

      final response = await http.post(
        Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/create-product'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: json.encode({
          'name': name,
          'regular_price': price,
          'sale_price': salePrice,
          'description': description,
          'image_base64': imageBase64, // الصورة المرسلة
        }),
      );

      print("📡 كود الحالة: ${response.statusCode}");
      print("📄 رد السيرفر: ${response.body}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        final body = json.decode(response.body);
        throw Exception(body['message'] ?? 'خطأ غير معروف من السيرفر');
      }
    });
  }
  // تحديث منتج
  Future<bool> updateMyProduct(String token, int productId, String name, String price, String salePrice, File? newImageFile) async {
    return _executeWithRetry(() async {
      String? imageBase64;
      if (newImageFile != null) {
        List<int> imageBytes = await newImageFile.readAsBytes();
        imageBase64 = base64Encode(imageBytes);
      }

      final response = await http.post(
        Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/update-product'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: json.encode({
          'product_id': productId,
          'name': name,
          'regular_price': price,
          'sale_price': salePrice,
          'image_base64': imageBase64,
        }),
      );
      return response.statusCode == 200;
    });
  }

  Future<bool> updateOrderStatus(int orderId, String status) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? prefs.getString('store_jwt_token');
    if (token == null) throw Exception('User not logged in');

    final response = await _executeWithRetry(() => http.post(
      Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/update-order-status/$orderId'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: json.encode({'status': status}),
    ));
    return response.statusCode == 200;
  }

  Future<RestaurantRatingsDashboard> getDashboardRatings(String token) async {
    return _executeWithRetry(() async {
      final response = await http.get(
        Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/dashboard-ratings'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) return RestaurantRatingsDashboard.fromJson(json.decode(response.body));

      print("❌ API Error [getRatings]: Code ${response.statusCode}, Body: ${response.body}");
      throw Exception('Failed to load dashboard ratings');
    });
  }

  Future<bool> updateRestaurantStatus(String token, bool isOpen) async {
    return _executeWithRetry(() async {
      final response = await http.post(
        Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/update-status'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: json.encode({'is_open': isOpen ? 1 : 0}),
      );
      return response.statusCode == 200;
    });
  }

  Future<bool> updateRestaurantAutoTimes(String token, String openTime, String closeTime) async {
    return _executeWithRetry(() async {
      final response = await http.post(
        Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/update-auto-times'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: json.encode({'open_time': openTime, 'close_time': closeTime}),
      );
      return response.statusCode == 200;
    });
  }

  Future<bool> updateMyLocation(String token, String lat, String lng) async {
    return _executeWithRetry(() async {
      final response = await http.post(
        Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/update-my-location'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: json.encode({'lat': lat, 'lng': lng}),
      );
      return response.statusCode == 200;
    });
  }

  Future<bool> testNotification() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? prefs.getString('store_jwt_token');
    if (token == null) throw Exception('User not logged in');

    final response = await _executeWithRetry(() => http.post(
      Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/test-notification'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
    ));
    return response.statusCode == 200;
  }

  // =================================================================
  // 3. دوال الزبون (Customer Side)
  // =================================================================

  Future<String> getRawRestaurants(int areaId) async {
    const fields = 'id,name,image,count,meta_data';
    final url = '$BEYTEI_URL/wp-json/wc/v3/products/categories?parent=0&per_page=100&_fields=$fields&area_id=$areaId';

    return _executeWithRetry(() async {
      final response = await http.get(Uri.parse(url), headers: {'Authorization': _authString});
      if (response.statusCode == 200) return response.body;
      throw Exception('Failed to load raw restaurants');
    });
  }

  Future<String> getRawDeliverableIds(int areaId) async {
    final url = '$BEYTEI_URL/wp-json/restaurant-app/v1/restaurants-by-area?area_id=$areaId';
    return _executeWithRetry(() async {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) return response.body;
      throw Exception('Failed to load deliverable IDs raw');
    });
  }

  Future<String> getRawMenu(int parentId) async {
    const fields = 'id,name,regular_price,sale_price,images,categories,short_description,average_rating,rating_count,meta_data';
    final url = '$BEYTEI_URL/wp-json/wc/v3/products?category=$parentId&per_page=100&_fields=$fields';

    return _executeWithRetry(() async {
      final response = await http.get(Uri.parse(url), headers: {'Authorization': _authString});
      if (response.statusCode == 200) return response.body;
      throw Exception('Failed to load raw menu');
    });
  }

  Future<List<Area>> getAreas() async {
    const cacheKey = 'all_areas';
    return _executeWithRetry(() async {
      final response = await http.get(Uri.parse('$BEYTEI_URL/wp-json/wp/v2/area?per_page=100'));
      if (response.statusCode == 200) {
        await _cacheService.saveData(cacheKey, response.body);
        return (json.decode(response.body) as List).map((json) => Area.fromJson(json)).toList();
      }
      throw Exception('Server error ${response.statusCode}');
    });
  }

  Future<List<Restaurant>> getAllRestaurants({required int areaId}) async {
    final jsonStr = await getRawRestaurants(areaId);
    final data = json.decode(jsonStr) as List;
    return data.map((json) => Restaurant.fromJson(json)).toList();
  }

  Future<Set<int>> getDeliverableRestaurantIds(int areaId) async {
    final jsonStr = await getRawDeliverableIds(areaId);
    final List<dynamic> data = json.decode(jsonStr);
    return data.map<int>((item) => item['id'] as int).toSet();
  }

  Future<List<FoodItem>> getMenuForRestaurant(int categoryId) async {
    final jsonStr = await getRawMenu(categoryId);
    final data = json.decode(jsonStr) as List;
    return data.map((json) => FoodItem.fromJson(json)).toList();
  }

  Future<List<FoodItem>> searchProducts({required String query}) async {
    const fields = 'id,name,regular_price,sale_price,images,categories,short_description,average_rating,rating_count,meta_data';
    final url = '$BEYTEI_URL/wp-json/wc/v3/products?search=$query&per_page=20&_fields=$fields';
    return _executeWithRetry(() async {
      final response = await http.get(Uri.parse(url), headers: {'Authorization': _authString});
      if (response.statusCode == 200) {
        return (json.decode(response.body) as List).map((json) => FoodItem.fromJson(json)).toList();
      }
      throw Exception('Failed search');
    });
  }

  // =================================================================
  // 4. التوصيل والطلبات الموحدة (Delivery & Unified Orders)
  // =================================================================

  Future<List<UnifiedDeliveryOrder>> getOrdersByRegion(int areaId, String token) async {
    // ✅ الرابط الجديد الموحد
    final url = '$BEYTEI_URL/wp-json/restaurant-app/v1/region-orders?area_id=$areaId';

    return _executeWithRetry(() async {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map<UnifiedDeliveryOrder>((json) {
          return UnifiedDeliveryOrder.fromJson(json);
        }).toList();
      } else {
        throw Exception('Server Error: ${response.statusCode}');
      }
    });
  }

  Future<DeliveryConfig> getDeliveryConfig() async {
    return _executeWithRetry(() async {
      final response = await http.get(Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/get-delivery-config'));
      if (response.statusCode == 200) {
        return DeliveryConfig.fromJson(json.decode(response.body));
      }
      throw Exception('Failed to load delivery config');
    });
  }

  Future<Map<String, dynamic>> getDeliveryFee({
    required int restaurantId,
    required double customerLat,
    required double customerLng,
  }) async {
    return _executeWithRetry(() async {
      final response = await http.post(
        Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/get-delivery-fee'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'restaurant_id': restaurantId,
          'customer_lat': customerLat,
          'customer_lng': customerLng,
        }),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      try {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'فشل حساب سعر التوصيل');
      } catch (e) {
        throw Exception('فشل حساب سعر التوصيل');
      }
    });
  }

  Future<Map<String, dynamic>> createUnifiedDeliveryRequest({
    required String token,
    required String sourceType,
    required String pickupName,
    required double pickupLat,
    required double pickupLng,
    required String destinationAddress,
    double? destinationLat,
    double? destinationLng,
    required String deliveryFee,
    required String orderDescription,
    required String endCustomerPhone,
    String? sourceOrderId,
  }) async {
    return await _executeWithRetry(() async {
      final response = await http.post(
        Uri.parse('https://banner.beytei.com/wp-json/taxi/v2/delivery/create'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: json.encode({
          'source_type': sourceType,
          'source_order_id': sourceOrderId,
          'pickup_location_name': pickupName,
          'pickup_lat': pickupLat.toString(),
          'pickup_lng': pickupLng.toString(),
          'destination_address': destinationAddress,
          'destination_lat': destinationLat?.toString() ?? "0",
          'destination_lng': destinationLng?.toString() ?? "0",
          'delivery_fee': deliveryFee,
          'order_description': orderDescription,
          'end_customer_phone': endCustomerPhone,
        }),
      );

      final responseBody = json.decode(response.body);
      if (response.statusCode == 201 && responseBody['success'] == true) {
        return responseBody;
      }
      throw Exception(responseBody['message'] ?? 'فشل إرسال طلب التوصيل.');
    });
  }

  // =================================================================
  // 🔥🔥🔥 دالة إرسال الطلب المعدلة (مع دعم الأوزان والكسور) 🔥🔥🔥
  // =================================================================
  // 🔥🔥 دالة إرسال الطلب النهائية (مكتملة التعديلات)
  Future<Order?> submitOrder({
    required String name,
    required String phone,
    required String address,
    required List<FoodItem> cartItems,
    String? couponCode,
    geolocator.Position? position,
    double? deliveryFee, // ✅ السعر المحسوب محلياً
    required int? restaurantId,
    required int? regionId,
  }) async {
    // 1. تجهيز كوبون الخصم
    List<Map<String, dynamic>> couponLines = couponCode != null && couponCode.isNotEmpty
        ? [{"code": couponCode}]
        : [];

    // 2. ✅ تجهيز خط الشحن بالسعر المحسوب
    List<Map<String, dynamic>> shippingLines = deliveryFee != null
        ? [{
      "method_id": "flat_rate",
      "method_title": "توصيل",
      "total": deliveryFee.toString()
    }]
        : [];

    // 3. 🔥 جلب التوكنات الحيوية
    final prefs = await SharedPreferences.getInstance();
    String? voipToken = prefs.getString('voip_token');

    String? fcmToken;
    try {
      fcmToken = await FirebaseMessaging.instance.getToken();
      if (kDebugMode) print("🚀 [SubmitOrder] FCM Token: $fcmToken");
    } catch (e) {
      if (kDebugMode) print("⚠️ [SubmitOrder] Failed to get FCM token: $e");
    }

    // 4. 🔥🔥 تجهيز المنتجات مع الأوزان والكسور
    List<Map<String, dynamic>> preparedLineItems = cartItems.map((item) {
      Map<String, dynamic> lineItem = {
        "product_id": item.id,
        "quantity": item.quantity,
        "subtotal": (item.displayPrice * item.quantity).toString(),
        "total": (item.displayPrice * item.quantity).toString(),
      };

      // معالجة الوزن المختار
      if (item.selectedWeight != null && item.selectedWeight != 1.0) {
        String weightText = "";
        if (item.selectedWeight == 0.25) weightText = "ربع كيلو (250غم)";
        else if (item.selectedWeight == 0.5) weightText = "نصف كيلو (500غم)";
        else if (item.selectedWeight == 0.75) weightText = "كيلو إلا ربع";
        else if (item.selectedWeight == 1.25) weightText = "كيلو وربع";
        else if (item.selectedWeight == 1.5) weightText = "كيلو ونصف (1.5 كغم)";
        else if (item.selectedWeight == 1.75) weightText = "كيلو و 750 غرام";
        else if (item.selectedWeight == 2.25) weightText = "كيلوين وربع";
        else if (item.selectedWeight == 2.5) weightText = "كيلوين ونصف";
        else if (item.selectedWeight! % 1 == 0) weightText = "${item.selectedWeight!.toInt()} كيلو";
        else weightText = "${item.selectedWeight} كيلو";

        lineItem["meta_data"] = [
          {"key": "الوزن المختار", "value": weightText}
        ];
      }
      return lineItem;
    }).toList();

    // 5. 🔥🔥🔥 بناء جسم الطلب مع الميتا داتا الكاملة
    Map<String, dynamic> bodyPayload = {
      "payment_method": "cod",
      "payment_method_title": "الدفع عند الاستلام",
      "billing": {
        "first_name": name,
        "last_name": ".",
        "phone": phone,
        "address_1": address,
        "country": "IQ",
        "city": "Default",
        "postcode": "10001",
        "email": "customer@example.com"
      },
      "shipping": {
        "first_name": name,
        "last_name": ".",
        "address_1": address,
        "country": "IQ",
        "city": "Default",
        "postcode": "10001"
      },
      "line_items": preparedLineItems,
      "coupon_lines": couponLines,
      "shipping_lines": shippingLines,

      // ✅ الميتا داتا: السعر المنفصل، التوكنات، الإحداثيات
      "meta_data": [
        // أ) توكنات الإشعارات والمكالمات
        if (fcmToken != null) ...[
          {"key": "_customer_fcm_token", "value": fcmToken},
          {"key": "fcm_token", "value": fcmToken},
        ],
        if (voipToken != null && voipToken.isNotEmpty)
          {"key": "voip_token", "value": voipToken},

        // ب) 🔥 السعر المحسوب محلياً (الأهم للتكسي)
        if (deliveryFee != null)
          {"key": "calculated_delivery_fee", "value": deliveryFee.toString()},

        // ج) إحداثيات الزبون الدقيقة
        if (position != null) ...[
          {"key": "_customer_destination_lat", "value": position.latitude.toString()},
          {"key": "_customer_destination_lng", "value": position.longitude.toString()},
        ],

        // د) معرفات المتجر والمنطقة
        if (restaurantId != null)
          {"key": "_restaurant_id", "value": restaurantId.toString()},
        if (regionId != null) ...[
          {"key": "_region_id", "value": regionId.toString()},
          {"key": "_area_id", "value": regionId.toString()},
        ],
      ],
    };

    // 6. الإرسال للسيرفر
    try {
      final response = await _executeWithRetry(() => http.post(
          Uri.parse('$BEYTEI_URL/wp-json/wc/v3/orders'),
          headers: {
            'Authorization': _authString,
            'Content-Type': 'application/json'
          },
          body: json.encode(bodyPayload)
      ));

      if (response.statusCode == 201) {
        final createdOrder = Order.fromJson(json.decode(response.body));
        await OrderHistoryService().saveOrder(createdOrder);
        return createdOrder;
      } else {
        throw Exception('فشل إنشاء الطلب: ${response.body}');
      }
    } catch (e) {
      throw Exception('خطأ في الاتصال: $e');
    }

  }
  Future<bool> submitReview({required int productId, required double rating, required String review, required String author, required String email}) async {
    final response = await _executeWithRetry(() => http.post(
      Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/submit-review'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'product_id': productId, 'rating': rating, 'review': review, 'author': author, 'email': email}),
    ));
    return response.statusCode == 201;
  }

  Future<Map<String, dynamic>> validateCoupon(String code) async {
    try {
      final response = await _executeWithRetry(() => http.post(
        Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/validate-coupon'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'code': code}),
      ));
      if (response.statusCode == 200) return json.decode(response.body);
      return {'valid': false, 'message': 'كود غير صالح'};
    } catch (e) {
      return {'valid': false, 'message': 'خطأ في الاتصال بالخادم'};
    }
  }
}

class AuthService {
  // دالة تسجيل الدخول المحسنة مع طباعة تفاصيل الخطأ
  Future<String?> loginRestaurantOwner(String username, String password) async {
    final url = '$BEYTEI_URL/wp-json/jwt-auth/v1/token';

    print("🔍 DEBUG: [AuthService] 🚀 Connecting to: $url");
    print("🔍 DEBUG: [AuthService] 👤 Username sent: $username");

    try {
      final response = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'username': username, 'password': password})
      ).timeout(API_TIMEOUT);

      print("🔍 DEBUG: [AuthService] 📡 Status Code: ${response.statusCode}");
      print("🔍 DEBUG: [AuthService] 📄 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['token'];

        if (token != null) {
          print("🔍 DEBUG: [AuthService] ✅ Token found successfully: ${token.substring(0, 10)}..."); // طباعة جزء من التوكن للتأكد

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt_token', token); // حفظ التوكن باسمه القياسي
          // ملاحظة: الـ StoreAuthProvider سيقوم أيضاً بحفظه باسم store_jwt_token وهذا جيد (زيادة تأكيد)

          return token;
        } else {
          print("🔍 DEBUG: [AuthService] ❌ Response 200 OK but 'token' key is Missing in JSON!");
        }
      } else {
        print("🔍 DEBUG: [AuthService] ❌ Server Error. Status: ${response.statusCode}");
      }
      return null;
    } catch (e) {
      print("🔍 DEBUG: [AuthService] 💥 Exception: $e");
      return null;
    }
  }

  Future<void> registerDeviceToken() async {
    final prefs = await SharedPreferences.getInstance();
    // نحاول قراءة التوكن من المكانين المحتملين لضمان العثور عليه
    final token = prefs.getString('jwt_token') ?? prefs.getString('store_jwt_token');

    if (token == null) {
      print("🔍 DEBUG: [AuthService] Cannot register device. Token is null.");
      return;
    }

    String? fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken == null) return;

    print("🔍 DEBUG: [AuthService] Registering FCM Token...");

    try {
      await http.post(
        Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/register-device'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: json.encode({'token': fcmToken}),
      ).timeout(API_TIMEOUT);
      print("🔍 DEBUG: [AuthService] Device Registered Successfully.");
    } catch (e) {
      print("🔍 DEBUG: [AuthService] Error registering device token: $e");
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token') ?? prefs.getString('store_jwt_token');

    if (jwtToken != null) {
      try {
        await http.post(
          Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/unregister-device'),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $jwtToken'},
        ).timeout(API_TIMEOUT);
      } catch (e) { print("Failed to unregister device: $e"); }
    }
    await FirebaseMessaging.instance.deleteToken();
    final cacheService = CacheService();
    await cacheService.clearAllCache();

    // حذف جميع مفاتيح التوكن المحتملة
    await prefs.remove('jwt_token');
    await prefs.remove('store_jwt_token'); // مهم جداً
    await prefs.remove('store_user_role');

    await prefs.remove('selectedAreaId');
    await prefs.remove('selectedAreaName');

    print("🔍 DEBUG: [AuthService] Logout completed & Cache cleared.");
  }
}
// =======================================================================
// --- WIDGETS (Reusable UI Components) ---
// =======================================================================

class NetworkErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const NetworkErrorWidget({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            Text('حدث خطأ في الشبكة', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600), textAlign: TextAlign.center),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                textStyle: const TextStyle(fontSize: 16, fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// (الصق هذا بدلاً من FoodCard القديم)
// (الصق هذا بدلاً من FoodCard القديم)

// (الصق هذا بدلاً من FoodCard القديم)

class FoodCard extends StatelessWidget {
  final FoodItem food;
  const FoodCard({super.key, required this.food});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);

    // هذا السطر صحيح (يعتمد على المنطقة + حالة الفتح)
    final bool canOrder = food.isDeliverable;

    return GestureDetector(
      // ✨ --- [تم التعديل] ---
      // الآن النقر على البطاقة سينقلك دائماً إلى شاشة التفاصيل
      // حتى لو كان المنتج غير متاح
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DetailScreen(foodItem: food))),
        // --- نهاية التعديل ---
        child: Opacity(
            opacity: canOrder ? 1.0 : 0.5,
            child: Container(
                width: 180,
                margin: const EdgeInsets.only(left: 15),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Hero(
                        tag: 'food_image_${food.id}',
                        child: Stack(alignment: Alignment.center, children: [
                          ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: CachedNetworkImage(imageUrl: food.imageUrl, height: 140, width: double.infinity, fit: BoxFit.cover, placeholder: (context, url) => Shimmer.fromColors(baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!, child: Container(color: Colors.white)))),

                          // هذا الكود سيعرض "غير متوفر حالياً"
                          if (!canOrder)
                            Container(
                                height: 140,
                                width: double.infinity,
                                decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(20)),
                                child: const Center(
                                  // ✨ تم تغيير النص ليطابق صورتك
                                    child: Text('ليس متاح الآن', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))
                                )
                            )
                        ]),
                      ),
                      const SizedBox(height: 10),
                      Text(food.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const Spacer(),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(food.formattedPrice, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: IconButton(
                                icon: Icon(Icons.add_shopping_cart, color: canOrder ? Theme.of(context).primaryColor : Colors.grey),
                                // ✨ --- [تم التعديل] ---
                                // النقر على زر الإضافة (وهو مغلق) سينقلك أيضاً لشاشة التفاصيل
                                onPressed: canOrder
                                    ? () => cart.addToCart(food, context)
                                    : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DetailScreen(foodItem: food))),
                                // --- نهاية التعديل ---
                              ),
                            )
                          ]),
                      const SizedBox(height: 5),
                    ]))));
  }
}
class HorizontalRestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  const HorizontalRestaurantCard({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    // 1. Check if it's available (within region + open)
    final bool isDeliverable = restaurant.isDeliverable;
    final bool isOpen = restaurant.isOpen;
    final bool canOrder = isDeliverable && isOpen;

    return GestureDetector(
      // 2. Update onTap
        onTap: canOrder
            ? () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => MenuScreen(restaurant: restaurant)))
            : () => _showClosedDialog(context, restaurant), // <-- Show dialog
        child: Opacity(
            opacity: 1.0, // 3. Remove opacity dimming
            child: Container(
                width: 100,
                margin: const EdgeInsets.only(left: 15),
                child: Column(children: [
                  Stack(alignment: Alignment.center, children: [
                    CircleAvatar(
                        radius: 40,
                        backgroundImage:
                        CachedNetworkImageProvider(restaurant.imageUrl),
                        backgroundColor: Colors.grey[200]),
                    // 4. Update Overlay
                    if (!isDeliverable) // Out of region
                      Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle),
                          child: const Center(
                              child: Text('خارج\nالتوصيل',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12))))
                    else if (!isOpen) // Closed
                      Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle),
                          child: const Center(
                              child: Text('مغلق\nحالياً',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12))))
                  ]),
                  const SizedBox(height: 8),
                  Text(restaurant.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12))
                ]))));
  }

  // 5. Add helper function (copied from RestaurantCard)
  void _showClosedDialog(BuildContext context, Restaurant restaurant) {
    String title;
    String message;
    IconData icon;
    Color iconColor;

    if (!restaurant.isDeliverable) {
      // 1. Out of delivery zone
      title = "خارج منطقة التوصيل";
      message = "عذراً، هذا  لا يوصل إلى منطقتك المحددة حالياً.";
      icon = Icons.location_off_outlined;
      iconColor = Colors.orange.shade700;
    } else if (!restaurant.isOpen) {
      // 2. In zone but closed
      title = " مغلق حالياً";
      message = "لا يستقبل  طلبات الآن.\n\n"
          "يفتح تلقائياً في: ${restaurant.autoOpenTime}\n"
          "يغلق تلقائياً في: ${restaurant.autoCloseTime}";
      icon = Icons.store_mall_directory_outlined;
      iconColor = Colors.red.shade600;
    } else {
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 16, height: 1.5)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("حسناً",
                  style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}

// في ملف re.dart (داخل قسم WIDGETS)
// استبدل الكلاس RestaurantCard بالكامل (سطر 1301) بهذا:

// في ملف re.dart (داخل قسم WIDGETS)
// استبدل الكلاس RestaurantCard بالكامل (سطر 1301) بهذا:

// (الصق هذا بدلاً من RestaurantCard القديم)
class RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  const RestaurantCard({super.key, required this.restaurant});

  // ✨ NEW: Modern dialog
  void _showClosedDialog(BuildContext context, Restaurant restaurant) {
    String title;
    String message;
    IconData icon;
    Color iconColor;

    if (!restaurant.isDeliverable) {
      // 1. خارج منطقة التوصيل
      title = "خارج منطقة التوصيل";
      message = "عذراً، هذا  لا يوصل إلى منطقتك المحددة حالياً.";
      icon = Icons.location_off_outlined;
      iconColor = Colors.orange.shade700;
    } else if (!restaurant.isOpen) { // <-- ✨ تم التعديل هنا
      // 2. داخل المنطقة ولكنه مغلق
      title = " مغلق حالياً";
      message = "لا يستقبل  طلبات الآن.\n\n"
          "يفتح تلقائياً في: ${restaurant.autoOpenTime}\n"
          "يغلق تلقائياً في: ${restaurant.autoCloseTime}";
      icon = Icons.store_mall_directory_outlined;
      iconColor = Colors.red.shade600;
    } else {
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 16, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("حسناً", style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✨ التعديل: استخدام 'isOpen' بدلاً من 'isCurrentlyOpen'
    final bool canOrder = restaurant.isDeliverable && restaurant.isOpen;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        onTap: canOrder
            ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MenuScreen(restaurant: restaurant)))
            : () => _showClosedDialog(context, restaurant),
        child: Opacity(
          opacity: 1.0, // لا نستخدم التعتيم هنا، بل على الصورة فقط
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: restaurant.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Shimmer.fromColors(baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!, child: Container(color: Colors.white)),
                      errorWidget: (context, url, error) => const Icon(Icons.storefront, color: Colors.grey, size: 40),
                    ),

                    // --- ✨ تم التعديل هنا لاستخدام 'canOrder' ---
                    !restaurant.isDeliverable
                        ? Container( // خارج المنطقة
                      color: Colors.black.withOpacity(0.6),
                      child: const Center(child: Text('خارج\nمنطقتك', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                    )
                        : !canOrder // (داخل المنطقة ولكنه مغلق)
                        ? Container(
                      color: Colors.black.withOpacity(0.6),
                      child: const Center(child: Text('مغلق حالياً', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                    )
                        : const SizedBox.shrink() // متاح
                    // --- نهاية التعديل ---
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(restaurant.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      SizedBox(
                        height: 30,
                        child: ElevatedButton.icon(
                          // ✨ التعديل: استخدام 'canOrder'
                          onPressed: canOrder
                              ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MenuScreen(restaurant: restaurant)))
                              : () => _showClosedDialog(context, restaurant),
                          icon: const Icon(Icons.menu_book, size: 14),
                          label: const Text(' عرض ', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: canOrder ? Theme.of(context).primaryColor : Colors.grey, // تغيير اللون إذا كان مغلقاً
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class OrderCard extends StatefulWidget {
  final Order order;
  final VoidCallback onStatusChanged;
  final bool isCompleted;
  final String? pickupCode;

  const OrderCard({
    super.key,
    required this.order,
    required this.onStatusChanged,
    this.isCompleted = false,
    this.pickupCode,
  });

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  final ApiService _apiService = ApiService();
  bool _isUpdating = false;

  // 🔥 الحيلة الذكية: طلب تكسي + نقل الطلب للمكتملة فوراً
  Future<void> _acceptAndAutoRequestTaxi() async {
    setState(() => _isUpdating = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // 1. 👇 التعديل هنا: تغيير الحالة إلى 'completed' مباشرة لنقله للأرشيف
      // بدلاً من 'processing'
      final statusSuccess = await _apiService.updateOrderStatus(widget.order.id, 'completed');
      if (!statusSuccess) throw Exception("فشل تحديث حالة الطلب");

      // 2. تجهيز بيانات التوصيل (كما هي)
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('store_jwt_token');
      final rLat = prefs.getDouble('restaurant_lat');
      final rLng = prefs.getDouble('restaurant_lng');
      final rName = prefs.getString('restaurant_name') ?? 'المسواك';

      if (token != null && rLat != null && rLng != null) {

        // حساب السعر (ثابت 1000 أو حسب الطلب)
        String deliveryFee = "1000";
        if (widget.order.shippingTotal != "0" && widget.order.shippingTotal.isNotEmpty) {
          deliveryFee = widget.order.shippingTotal;
        }

        double destLat = 0.0;
        double destLng = 0.0;
        if (widget.order.destinationLat != null && widget.order.destinationLat!.isNotEmpty) {
          destLat = double.tryParse(widget.order.destinationLat!) ?? 0.0;
          destLng = double.tryParse(widget.order.destinationLng!) ?? 0.0;
        }

        String notes = "توصيل طلب مسواك #${widget.order.id}";
        if (destLat == 0) {
          notes += "\n⚠️ اعتمد على العنوان النصي.";
        }

        // 3. إرسال طلب التكسي
        await _apiService.createUnifiedDeliveryRequest(
          token: token,
          sourceType: 'market',
          sourceOrderId: widget.order.id.toString(),
          pickupName: rName,
          pickupLat: rLat,
          pickupLng: rLng,
          destinationAddress: widget.order.address,
          destinationLat: destLat,
          destinationLng: destLng,
          deliveryFee: deliveryFee,
          orderDescription: notes,
          endCustomerPhone: widget.order.phone,
        );

        // 4. إظهار رسالة النجاح والنقل
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.done_all, color: Colors.green, size: 60),
                  const SizedBox(height: 10),
                  const Text("تم النقل للأرشيف!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const Text(
                      "تم طلب المندوب بنجاح ✅\nوتم نقل الطلب لقائمة المكتملة.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.blueGrey)
                  ),
                ],
              ),
            ),
          );

          // تحديث القائمة لإخفاء الطلب
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted && Navigator.canPop(context)) Navigator.pop(context);
            widget.onStatusChanged(); // سيختفي الطلب لأنه أصبح completed
          });
        }
      } else {
        widget.onStatusChanged();
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('تم نقل الطلب للمكتملة (بدون تكسي لعدم توفر الموقع)'), backgroundColor: Colors.orange));
      }

    } catch (e) {
      if (mounted) scaffoldMessenger.showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) await launchUrl(launchUri);
  }

  Future<void> _launchMaps(String? lat, String? lng) async {
    if (lat == null || lat == "0") return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => InAppMapScreen(latitude: double.parse(lat), longitude: double.parse(lng!), title: 'موقع الزبون')));
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('yyyy-MM-dd – hh:mm a', 'ar');
    final formattedDate = formatter.format(widget.order.dateCreated.toLocal());

    Color statusColor = Colors.grey;
    if (widget.order.status == 'pending') statusColor = Colors.orange;
    if (widget.order.status == 'processing') statusColor = Colors.blue;
    if (widget.order.status == 'completed') statusColor = Colors.green;

    return Card(
      elevation: 4,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text("#${widget.order.id}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  backgroundColor: statusColor,
                ),
                Text(formattedDate, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const Divider(),
            _infoRow(Icons.person, widget.order.customerName),
            const SizedBox(height: 5),
            _infoRow(Icons.location_on, widget.order.address),

            if (widget.order.destinationLat != null && widget.order.destinationLat != "0" && widget.order.destinationLat != "0.0")
              TextButton.icon(
                onPressed: () => _launchMaps(widget.order.destinationLat, widget.order.destinationLng),
                icon: const Icon(Icons.map, size: 16),
                label: const Text("موقع الزبون على الخريطة"),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              )
            else
              const Padding(
                padding: EdgeInsets.only(top: 5),
                child: Text("⚠️ الموقع غير محدد (الاعتماد على العنوان)", style: TextStyle(fontSize: 11, color: Colors.orange)),
              ),

            const SizedBox(height: 5),
            _infoRow(Icons.phone, widget.order.phone),
            const Divider(),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${widget.order.total} د.ع", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                IconButton(
                  icon: const Icon(Icons.call, color: Colors.green),
                  onPressed: () => _makePhoneCall(widget.order.phone),
                )
              ],
            ),

            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.order.lineItems.map((item) =>
                    Text("• ${item.quantity} x ${item.name}", style: const TextStyle(fontSize: 14))
                ).toList(),
              ),
            ),

            // الأزرار (تظهر فقط إذا لم يكن مكتمل)
            if (!widget.isCompleted)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      // عند الضغط هنا، سيتم طلب التكسي + نقل الطلب للمكتملة
                      onPressed: _isUpdating ? null : _acceptAndAutoRequestTaxi,
                      label: const Text("قبول وتجهيز"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      onPressed: _isUpdating ? null : () async {
                        setState(() => _isUpdating = true);
                        await _apiService.updateOrderStatus(widget.order.id, 'cancelled');
                        widget.onStatusChanged();
                      },
                      child: const Text("رفض"),
                    ),
                  ),
                ],
              ),

            // إذا كان الطلب في الأرشيف (Completed)
            if (widget.isCompleted)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                color: Colors.green.shade50,
                child: const Center(child: Text("✅ طلب مكتمل / تم طلب المندوب", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
              )
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
      ],
    );
  }
}
// =======================================================================
// --- بطاقة سجل الطلبات الموحدة (للمسواك والمطاعم) ---
// =======================================================================
class OrderHistoryCard extends StatelessWidget {
  final Order order;
  const OrderHistoryCard({super.key, required this.order});

  // ✨ --- دالة فتح الخريطة الداخلية (مشتركة) ---
  Future<void> _launchMaps(BuildContext context, String? lat, String? lng) async {
    // 1. التحقق من صحة الإحداثيات
    if (lat == null || lng == null || lat.isEmpty || lng.isEmpty || lat == "0" || lng == "0") {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الإحداثيات غير متوفرة لهذا الطلب'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    try {
      // 2. تحويل النصوص إلى أرقام عشرية
      final double latitude = double.parse(lat);
      final double longitude = double.parse(lng);

      // 3. ✨ الانتقال إلى شاشة الخريطة الداخلية (InAppMapScreen)
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InAppMapScreen(
              latitude: latitude,
              longitude: longitude,
              title: 'موقع التوصيل - طلب #${order.id}', // عنوان ديناميكي
            ),
          ),
        );
      }
    } catch (e) {
      // 4. معالجة الأخطاء في حال كانت الإحداثيات غير صالحة
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
  // --- [نهاية دالة الخريطة] ---

  @override
  Widget build(BuildContext context) {
    // تنسيق التاريخ والوقت
    final formatter = DateFormat('yyyy-MM-dd – hh:mm a', 'ar');
    final formattedDate = formatter.format(order.dateCreated.toLocal());

    // تنسيق السعر الكلي
    final totalFormatted = NumberFormat('#,###', 'ar_IQ').format(double.tryParse(order.total) ?? 0);

    // معلومات الحالة (أيقونة + نص + لون)
    final statusInfo = order.statusDisplay;

    // التحقق من وجود إحداثيات صالحة للعرض على الخريطة
    final bool hasCoordinates = (
        order.destinationLat != null &&
            order.destinationLat!.isNotEmpty &&
            order.destinationLat != "0" &&
            order.destinationLng != null &&
            order.destinationLng!.isNotEmpty &&
            order.destinationLng != "0"
    );

    // التحقق مما إذا كان الطلب نشطاً (لإظهار زر التتبع)
    final bool isActive = !['completed', 'cancelled', 'refunded', 'failed', 'trash']
        .contains(order.status.toLowerCase());

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- رأس البطاقة: رقم الطلب + التاريخ ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'طلب #${order.id}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                Text(
                  formattedDate,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),

            const Divider(height: 24),

            // --- قائمة المنتجات ---
            ...order.lineItems.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${item.quantity}×',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )).toList(),

            const Divider(height: 24),

            // --- العنوان مع دعم الخريطة ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: hasCoordinates ? Theme.of(context).primaryColor : Colors.grey.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text('العنوان:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 5),
                Expanded(
                  child: hasCoordinates
                  // ✅ إذا وجدت إحداثيات: اعرض نصاً قابلاً للنقر لفتح الخريطة
                      ? InkWell(
                    onTap: () => _launchMaps(context, order.destinationLat, order.destinationLng),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        "تم تحديد الموقع 🗺️ (اضغط للعرض)",
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          decoration: TextDecoration.underline,
                          decorationColor: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                  // ❌ إذا لم توجد إحداثيات: اعرض العنوان النصي فقط
                      : Text(
                    order.address.isNotEmpty ? order.address : 'عنوان غير محدد',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // --- الإجمالي والسعر ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('الإجمالي', style: TextStyle(color: Colors.grey, fontSize: 16)),
                Text(
                  '$totalFormatted د.ع',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),

            const Divider(height: 24),

            // --- حالة الطلب ---
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusInfo['color'].withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    statusInfo['icon'],
                    color: statusInfo['color'],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('حالة الطلب:', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    Text(
                      statusInfo['text'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: statusInfo['color'],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // --- زر تتبع الطلب (يظهر فقط للطلبات النشطة) ---
            if (isActive) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderTrackingScreen(order: order),
                      ),
                    );
                  },
                  icon: const Icon(Icons.track_changes_outlined, size: 20),
                  label: const Text(
                    "تتبع الطلب الآن",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
class RatingDialog extends StatefulWidget {
  final int productId;
  const RatingDialog({super.key, required this.productId});
  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  final _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _reviewController = TextEditingController();
  double _rating = 3.0;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final success = await _apiService.submitReview(productId: widget.productId, rating: _rating, review: _reviewController.text, author: _nameController.text, email: _emailController.text);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? "شكراً لك، تم إرسال تقييمك بنجاح!" : "فشل إرسال التقييم."), backgroundColor: success ? Colors.green : Colors.red));
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("حدث خطأ: ${e.toString()}"), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("إضافة تقييم"),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'الاسم'), validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null),
            TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: 'البريد الإلكتروني'), keyboardType: TextInputType.emailAddress, validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null),
            TextFormField(controller: _reviewController, decoration: const InputDecoration(labelText: 'ملاحظاتك'), maxLines: 3),
            const SizedBox(height: 20),
            RatingBar.builder(initialRating: _rating, minRating: 1, direction: Axis.horizontal, allowHalfRating: false, itemCount: 5, itemPadding: const EdgeInsets.symmetric(horizontal: 4.0), itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber), onRatingUpdate: (rating) => setState(() => _rating = rating)),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("إلغاء")),
        ElevatedButton(onPressed: _isLoading ? null : _submitReview, child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text("إرسال")),
      ],
    );
  }
}

class ReviewCard extends StatelessWidget {
  final Review review;
  const ReviewCard({super.key, required this.review});
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Text(review.productName, style: const TextStyle(fontWeight: FontWeight.bold))),
            RatingBarIndicator(rating: review.rating.toDouble(), itemBuilder: (context, index) => const Icon(Icons.star, color: Colors.amber), itemCount: 5, itemSize: 16.0),
          ]),
          const Divider(),
          Text(review.content.isEmpty ? "لا يوجد تعليق." : review.content, style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 8),
          Align(alignment: Alignment.bottomLeft, child: Text("${review.author} - ${DateFormat('yyyy/MM/dd').format(review.date)}", style: const TextStyle(fontSize: 12, color: Colors.grey))),
        ]),
      ),
    );
  }
}


// (الصق هذا بدلاً من ShimmerHomeScreen القديم)
class ShimmerHorizontalRestaurantCard extends StatelessWidget {
  const ShimmerHorizontalRestaurantCard({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100, margin: const EdgeInsets.only(left: 15),
      child: Column(children: [const CircleAvatar(radius: 40, backgroundColor: Colors.white), const SizedBox(height: 8), Container(height: 10, width: 70, color: Colors.white)]),
    );
  }
}

class ShimmerRestaurantCard extends StatelessWidget {
  const ShimmerRestaurantCard({super.key});
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!,
      child: Card(
        clipBehavior: Clip.antiAlias, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(flex: 3, child: Container(color: Colors.white)),
          Expanded(flex: 2, child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.center, children: [
              Column(children: [Container(height: 12, width: 100, color: Colors.white), const SizedBox(height: 4), Container(height: 12, width: 70, color: Colors.white)]),
              Container(height: 30, width: 100, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
            ]),
          )),
        ]),
      ),
    );
  }
}


class ShimmerFoodCard extends StatelessWidget {
  const ShimmerFoodCard({super.key});
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!,
      child: Container(
        width: 180, margin: const EdgeInsets.only(left: 15),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(height: 140, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
          const SizedBox(height: 10),
          Container(height: 15, width: 120, color: Colors.white),
          const SizedBox(height: 10),
          Container(height: 15, width: 60, color: Colors.white),
          const Spacer(),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(height: 20, width: 70, color: Colors.white),
            Container(height: 40, width: 40, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
          ]),
          const SizedBox(height: 5),
        ]),
      ),
    );
  }
}

// =======================================================================
// --- MAIN APP ENTRY POINT & WRAPPERS ---
// =======================================================================
// --- MAIN APP ENTRY POINT & WRAPPERS (تم التعديل لإصلاح الشاشة البيضاء) ---
// =======================================================================
// =======================================================================
// --- MAIN APP ENTRY POINT & WRAPPERS ---
// =======================================================================

// =================================================================
// الخطوة 1: استبدل main و RestaurantModule بهذا الكود
// =================================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeDateFormatting('ar', null);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // كود تحويل الشاشة البيضاء إلى شاشة زرقاء تحتوي على الخطأ
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      child: Container(
        color: const Color(0xFF0D47A1), // أزرق غامق
        padding: const EdgeInsets.all(20),
        child: Center(
          child: SingleChildScrollView(
            child: Text(
              details.exception.toString(),
              style: const TextStyle(color: Colors.yellowAccent, fontFamily: 'monospace'),
            ),
          ),
        ),
      ),
    );
  };

  runApp(const MiswakModule());
}
class MiswakModule extends StatefulWidget {
  const MiswakModule({super.key});
  @override
  State<MiswakModule> createState() => _MiswakModuleState();
}

class _MiswakModuleState extends State<MiswakModule> {
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await NotificationService.initialize();

    // 1. الاستماع للإشعارات والرسائل القادمة (والتطبيق مفتوح في الواجهة)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {

      // 🛑 [الحل الجذري للمشكلة]: منع المسواك من تحويل المكالمة إلى إشعار عادي
      if (message.data['type'] == 'voip_call' || message.data['type'] == 'incoming_call') {
        return; // تجاهل الأمر تماماً واترك المهمة لملف main.dart ليظهر شاشة الرنين
      }

      // 🔥 ب: إشعار عادي (تحديث طلب، عرض الخصومات، إلخ)
      NotificationService.display(message);

      // تحديث الداشبورد تلقائياً إذا كان المدير فاتحاً للتطبيق
      if (mounted) {
        final auth = Provider.of<StoreAuthProvider>(context, listen: false);
        if (auth.isLoggedIn && auth.token != null) {
          Provider.of<MiswakDashboardProvider>(context, listen: false).triggerSmartRefresh(auth.token!);
        }
      }
    });
  }  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // المزودات المستقلة
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => StoreAuthProvider()),
        ChangeNotifierProvider(create: (_) => StoreCustomerProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => DeliveryProvider()),
        ChangeNotifierProvider(create: (_) => MiswakDeliveryConfigProvider()),


        // 1. داشبورد المسواك
        ChangeNotifierProxyProvider<StoreAuthProvider, MiswakDashboardProvider>(
          create: (_) => MiswakDashboardProvider(),
          update: (_, auth, dashboard) {
            if (auth.isLoggedIn && dashboard != null && auth.token != null) {
              dashboard.fetchDashboardData(auth.token!, silent: true);
            }
            return dashboard!;
          },
        ),

        // 2. إعدادات المسواك
        ChangeNotifierProxyProvider<StoreAuthProvider, MiswakSettingsProvider>(
          create: (_) => MiswakSettingsProvider(),
          update: (_, auth, settings) {
            if (settings != null && auth.isLoggedIn && auth.token != null) {
              settings.fetchSettings(auth.token);
            } else if (settings != null && !auth.isLoggedIn) {
              settings.clearData();
            }
            return settings!;
          },
        ),

        // 3. منتجات المسواك
        ChangeNotifierProxyProvider<StoreAuthProvider, MiswakProductsProvider>(
          create: (_) => MiswakProductsProvider(),
          update: (_, auth, products) {
            if (products != null && auth.isLoggedIn && auth.token != null) {
              products.fetchProducts(auth.token);
            } else if (products != null && !auth.isLoggedIn) {
              products.clearData();
            }
            return products!;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Beytei Miswak',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            primarySwatch: Colors.teal,
            scaffoldBackgroundColor: const Color(0xFFF5F5F5),
            fontFamily: 'Tajawal',
            appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                elevation: 0.5,
                iconTheme: IconThemeData(color: Colors.black),
                titleTextStyle: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')
            )
        ),
        home: const StoreAuthWrapper(),
      ),
    );
  }
}
class RestaurantSettingsScreen extends StatefulWidget {
  const RestaurantSettingsScreen({super.key});

  @override
  State<RestaurantSettingsScreen> createState() => _RestaurantSettingsScreenState();
}

class _RestaurantSettingsScreenState extends State<RestaurantSettingsScreen> {

  Future<void> _updateStatus(MiswakSettingsProvider provider, bool newValue) async {
    final token = Provider.of<StoreAuthProvider>(context, listen: false).token;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final success = await provider.updateOpenStatus(token, newValue);
    if(success) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text(newValue ? 'تم فتح المسواك بنجاح.' : 'تم إغلاق المسواك بنجاح.'), backgroundColor: Colors.green));
    } else {
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('فشل تحديث الحالة.'), backgroundColor: Colors.red));
    }
  }

  Future<void> _showTimePicker(BuildContext context, MiswakSettingsProvider provider, bool isOpeningTime) async {
    final initialTime = isOpeningTime
        ? TimeOfDay(hour: int.parse(provider.openTime.split(':')[0]), minute: int.parse(provider.openTime.split(':')[1]))
        : TimeOfDay(hour: int.parse(provider.closeTime.split(':')[0]), minute: int.parse(provider.closeTime.split(':')[1]));

    final TimeOfDay? newTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (newTime != null) {
      final hour24 = newTime.hour;
      final minute = newTime.minute;
      final formattedTime24 = '${hour24.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

      final token = Provider.of<StoreAuthProvider>(context, listen: false).token;
      final String newOpenTime = isOpeningTime ? formattedTime24 : provider.openTime;
      final String newCloseTime = isOpeningTime ? provider.closeTime : formattedTime24;

      final success = await provider.updateAutoTimes(token, newOpenTime, newCloseTime);
      if(mounted) {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        if(success) {
          scaffoldMessenger.showSnackBar(const SnackBar(content: Text('تم التحديث بنجاح.'), backgroundColor: Colors.green));
        } else {
          scaffoldMessenger.showSnackBar(const SnackBar(content: Text('فشل تحديث الأوقات.'), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ لاحظ هنا: استخدام MiswakSettingsProvider
    return Consumer<MiswakSettingsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () async {
            final token = Provider.of<StoreAuthProvider>(context, listen: false).token;
            await provider.fetchSettings(token);
          },
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Card(
                elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("التحكم اليدوي", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Divider(),
                      SwitchListTile(
                        title: Text(
                          provider.isRestaurantOpen ? 'المسواك متاح للطلبات' : 'المسواك مغلق حالياً',
                          style: TextStyle(fontWeight: FontWeight.bold, color: provider.isRestaurantOpen ? Colors.green : Colors.red),
                        ),
                        value: provider.isRestaurantOpen,
                        onChanged: (newValue) => _updateStatus(provider, newValue),
                        secondary: Icon(provider.isRestaurantOpen ? Icons.store_mall_directory : Icons.storefront_outlined),
                        activeColor: Colors.green,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("توقيت العمل التلقائي", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Divider(),
                      ListTile(
                        title: const Text('وقت الفتح'),
                        trailing: Text(provider.openTime, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        leading: const Icon(Icons.access_time),
                        onTap: () => _showTimePicker(context, provider, true),
                      ),
                      const Divider(),
                      ListTile(
                        title: const Text('وقت الإغلاق'),
                        trailing: Text(provider.closeTime, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        leading: const Icon(Icons.lock_clock),
                        onTap: () => _showTimePicker(context, provider, false),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});
  @override
  Widget build(BuildContext context) {
    // ✨ التغيير: دائماً نذهب للتحقق من الموقع ثم الصفحة الرئيسية
    // لم نعد نجبر المستخدم على دخول الداشبورد هنا
    return const StoreLocationCheckWrapper();
  }
}
class StoreLocationCheckWrapper extends StatelessWidget {
  const StoreLocationCheckWrapper({super.key});

  Future<int?> _checkLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final areaId = prefs.getInt('miswak_area_id');
    print("🔍 DEBUG: [Wrapper] CheckLocation found Area ID: $areaId"); // 9
    return areaId;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<StoreAuthProvider>(context);

    print("🔍 DEBUG: [Wrapper] Rebuild triggered."); // 10
    print("🔍 DEBUG: [Wrapper] Auth State -> IsLoggedIn: ${authProvider.isLoggedIn}, Token: ${authProvider.token}"); // 11

    // الأولوية 1: المدير
    if (authProvider.isLoggedIn && authProvider.token != null) {
      print("🔍 DEBUG: [Wrapper] DECISION -> GOING TO DASHBOARD (Manager Detected)"); // 12
      return const StoreDashboardScreen();
    }

    // الأولوية 2: الزبون
    return FutureBuilder<int?>(
      future: _checkLocation(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData && snapshot.data != null) {
          print("🔍 DEBUG: [Wrapper] DECISION -> GOING TO MAIN SCREEN (Customer Area Found)"); // 13
          return const MainScreen();
        }

        print("🔍 DEBUG: [Wrapper] DECISION -> GOING TO SELECT LOCATION (New User)"); // 14
        return const SelectLocationScreen(isCancellable: false);
      },
    );
  }
}



// --- SCREENS ---
// =======================================================================

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [ Theme.of(context).primaryColor, const Color(0xFF00897B) ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.food_bank_rounded, size: 120, color: Colors.white),
              SizedBox(height: 20),
              Text( "مطاعم بيتي", style: TextStyle( fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, ),),
              SizedBox(height: 10),
              Text( "أشهى المأكولات تصلك أينما كنت", style: TextStyle( fontSize: 16, color: Colors.white70, ),),
            ],
          ),
        ),
      ),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [ Theme.of(context).primaryColor, const Color(0xFF00897B) ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on_outlined, size: 120, color: Colors.white),
                const SizedBox(height: 20),
                const Text( "أهلاً بك في مسواك بيتي", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center, ),
                const SizedBox(height: 10),
                const Text( "لتصفح المسواك، الرجاء تحديد منطقة التوصيل أولاً", style: TextStyle(fontSize: 16, color: Colors.white70), textAlign: TextAlign.center, ),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  icon: const Icon(Icons.map_outlined),
                  label: const Text("حدد منطقة التوصيل"),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const SelectLocationScreen(),
                    ));
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor, backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Tajawal'),
                    shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(30), ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}
class _MainScreenState extends State<MainScreen> {
  // مفاتيح للحفاظ على حالة التصفح داخل كل تبويب
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>()
  ];

  // ✨✨✨ دالة إظهار نافذة الخروج العصرية ✨✨✨
  Future<bool> _showExitConfirmation() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // أيقونة متحركة
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    size: 48,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                // العنوان
                const Text(
                  'هل ترغب بالمغادرة؟',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                // الوصف
                Text(
                  'سيتم حفظ سلتك ويمكنك العودة لاحقاً',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // الأزرار
                Row(
                  children: [
                    // زر متابعة التسوق
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(
                            color: Theme.of(context).primaryColor,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          'متابعة التسوق',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // زر الخروج
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: Colors.red.shade500,
                          elevation: 8,
                          shadowColor: Colors.red.withOpacity(0.3),
                        ),
                        child: const Text(
                          'نعم، خروج',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    // نستخدم الـ Provider لمعرفة التبويب الحالي
    final navProvider = Provider.of<NavigationProvider>(context);

    return WillPopScope(
      onWillPop: () async {
        final currentNavigator = _navigatorKeys[navProvider.currentIndex].currentState;

        // إذا كان هناك صفحات داخل التبويب الحالي، نعود للصفحة السابقة
        if (currentNavigator != null && currentNavigator.canPop()) {
          currentNavigator.pop();
          return false;
        }

        // إذا لم نكن في التبويب الأول، نعود للرئيسية
        if (navProvider.currentIndex != 0) {
          navProvider.changeTab(0);
          return false;
        }

        // ✨✨✨ إظهار نافذة الخروج العصرية ✨✨✨
        return await _showExitConfirmation();
      },
      child: Scaffold(
        // عرض الصفحة الحالية بناءً على التبويب المختار
        body: IndexedStack(
          index: navProvider.currentIndex,
          children: <Widget>[
            _buildOffstageNavigator(0), // الرئيسية
            _buildOffstageNavigator(1), // المسواك (المطاعم)
            _buildOffstageNavigator(2), // طلباتي
            _buildOffstageNavigator(3), // السلة
          ],
        ),
        bottomNavigationBar: _buildCustomBottomNav(navProvider),
      ),
    );
  }

  Widget _buildOffstageNavigator(int index) {
    return Offstage(
      offstage: Provider.of<NavigationProvider>(context).currentIndex != index,
      child: Navigator(
        key: _navigatorKeys[index],
        onGenerateRoute: (settings) {
          Widget pageBuilder;
          switch (index) {
            case 0: pageBuilder = const MiswakStoreHomeScreen(); break; // الصفحة الرئيسية
            case 1: pageBuilder = const RestaurantsScreen(); break;     // صفحة المتاجر
            case 2: pageBuilder = const OrdersHistoryScreen(); break;   // صفحة الطلبات
            case 3: pageBuilder = const CartScreen(); break;            // صفحة السلة
            default: pageBuilder = const MiswakStoreHomeScreen();
          }
          return MaterialPageRoute(builder: (context) => pageBuilder, settings: settings);
        },
      ),
    );
  }

  Widget _buildCustomBottomNav(NavigationProvider navProvider) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Theme.of(context).primaryColor,
      unselectedItemColor: Colors.grey,
      items: <BottomNavigationBarItem>[
        const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'الرئيسية'),
        const BottomNavigationBarItem(icon: Icon(Icons.store_outlined), activeIcon: Icon(Icons.store), label: 'المسواك'),
        const BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history), label: 'طلباتي'),
        BottomNavigationBarItem(
          icon: Consumer<CartProvider>(
            builder: (context, cart, child) => Badge(
                isLabelVisible: cart.cartCount > 0,
                label: Text(cart.cartCount.toString()),
                child: const Icon(Icons.shopping_cart_outlined)
            ),
          ),
          activeIcon: const Icon(Icons.shopping_cart),
          label: 'السلة',
        ),
      ],
      currentIndex: navProvider.currentIndex,
      onTap: (index) {
        navProvider.changeTab(index);
      },
    );
  }
}
class MiswakStoreHomeScreen extends StatefulWidget {
  const MiswakStoreHomeScreen({super.key});
  @override
  State<MiswakStoreHomeScreen> createState() => _MiswakStoreHomeScreenState();
}

class _MiswakStoreHomeScreenState extends State<MiswakStoreHomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<String> bannerImages = [
    'https://beytei.com/wp-content/uploads/2023/05/banner1.jpg',
    'https://beytei.com/wp-content/uploads/2023/05/banner2.jpg',
    'https://beytei.com/wp-content/uploads/2023/05/banner3.jpg'
  ];

  int _currentBannerIndex = 0;
  int? _selectedAreaId;
  String? _selectedAreaName;

  @override
  void initState() {
    super.initState();

    // تنفيذ العمليات الأولية عند فتح الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
      _preFetchDeliveryData(); // 🔥 إضافة مهمة: تحميل بيانات التوصيل مبكراً
    });
  }

  // 🔥 دالة لتحميل ملف أسعار التوصيل JSON في الخلفية
  void _preFetchDeliveryData() {
    // نستخدم microtask لضمان عدم التأثير على سلاسة بناء الواجهة
    Future.microtask(() {
      try {
        final deliveryProvider = Provider.of<DeliveryProvider>(context, listen: false);
        // استدعاء دالة التحميل التي تتحقق من الكاش (7 أيام) أو تحمل من السيرفر
        deliveryProvider.init();
        print("🚀 [Delivery] Pre-fetching system initialized in background...");
      } catch (e) {
        print("⚠️ [Delivery] Pre-fetch error: $e");
      }
    });
  }

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    // ✅ قراءة المنطقة الخاصة بالمسواك
    _selectedAreaId = prefs.getInt('miswak_area_id');
    _selectedAreaName = prefs.getString('miswak_area_name');

    setState(() {}); // تحديث الواجهة لعرض الاسم

    if (_selectedAreaId != null) {
      // ✅ استدعاء الكاش أولاً (سيظهر البيانات فوراً بفضل الكود الجديد)
      Provider.of<StoreCustomerProvider>(context, listen: false)
          .fetchStoreHomeData(_selectedAreaId!, isRefresh: false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchSubmitted(String query) {
    if (query.isNotEmpty && _selectedAreaId != null) {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => SearchScreen(
              searchQuery: query, selectedAreaId: _selectedAreaId!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () async {
            final result = await Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const SelectLocationScreen(isCancellable: true)));

            if (result == true) {
              final prefs = await SharedPreferences.getInstance();
              _selectedAreaId = prefs.getInt('miswak_area_id');
              _selectedAreaName = prefs.getString('miswak_area_name');

              setState(() {});

              if (_selectedAreaId != null) {
                Provider.of<StoreCustomerProvider>(context, listen: false)
                    .fetchStoreHomeData(_selectedAreaId!, isRefresh: true);
              }
            }
          },
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(_selectedAreaName ?? "اختر منطقة",
                style: const TextStyle(fontSize: 16)),
            const Icon(Icons.keyboard_arrow_down, size: 20)
          ]),
        ),
        centerTitle: true,
        actions: [
          Consumer<StoreAuthProvider>(
            builder: (context, auth, child) {
              if (!auth.isLoggedIn) {
                return IconButton(
                  icon: const Icon(Icons.store, color: Colors.teal),
                  tooltip: "دخول مدير المسواك",
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const StoreLoginScreen())
                  ),
                );
              }
              else {
                return IconButton(
                  icon: const Icon(Icons.dashboard, color: Colors.teal, size: 28),
                  tooltip: "لوحة تحكم المسواك",
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const StoreDashboardScreen())
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Consumer<StoreCustomerProvider>(
        builder: (context, provider, child) {
          if (_selectedAreaId == null) {
            return const Center(child: Text("يرجى تحديد منطقة لعرض المسواك"));
          }

          if (provider.hasError && provider.homeData.isEmpty) {
            return NetworkErrorWidget(
                message: 'تحقق من اتصال الانترنيت .',
                onRetry: () => provider.fetchStoreHomeData(_selectedAreaId!,
                    isRefresh: true));
          }

          final stores = (provider.homeData['stores'] as List<dynamic>? ?? []).cast<Restaurant>();

          return RefreshIndicator(
            onRefresh: () =>
                provider.fetchStoreHomeData(_selectedAreaId!, isRefresh: true),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LoyaltyChallengeWidget(),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: _buildSearchBar()),
                _buildBannerSlider(),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 5),
                  child: Text("المسواك المتاح",
                      style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),

                Expanded(
                  child: () {
                    if (provider.isLoading && stores.isEmpty) {
                      return _buildRestaurantGridShimmer();
                    }
                    if (!provider.isLoading && stores.isEmpty) {
                      return Stack(
                        children: [
                          ListView(),
                          const Center(child: Text("لا توجد مسواك متاحة حالياً في هذه المنطقة")),
                        ],
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      physics: const BouncingScrollPhysics(),
                      itemCount: stores.length,
                      itemBuilder: (context, index) {
                        return RestaurantCard(restaurant: stores[index]);
                      },
                    );
                  }(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBannerSlider() {
    return Container(
      height: 150,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          CarouselSlider(
            items: bannerImages
                .map((imageUrl) => Builder(
                builder: (ctx) => Container(
                  width: MediaQuery.of(ctx).size.width,
                  margin: const EdgeInsets.symmetric(horizontal: 5.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                )))
                .toList(),
            options: CarouselOptions(
              height: 150.0,
              autoPlay: true,
              enlargeCenterPage: true,
              aspectRatio: 16 / 9,
              viewportFraction: 0.9,
              onPageChanged: (index, _) =>
                  setState(() => _currentBannerIndex = index),
            ),
          ),
          Positioned(
            bottom: 10,
            child: Row(
              children: bannerImages.map((url) {
                int index = bannerImages.indexOf(url);
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentBannerIndex == index
                        ? Theme.of(context).primaryColor
                        : Colors.white.withOpacity(0.7),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() => TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      onSubmitted: _onSearchSubmitted,
      decoration: InputDecoration(
          hintText: 'ابحث عن منتج...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: EdgeInsets.zero));

  Widget _buildRestaurantGridShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return const ShimmerRestaurantCard();
        },
      ),
    );
  }
}
































class MiswakDeliveryConfigProvider with ChangeNotifier {
  // 🔥 مفاتيح مستقلة تماماً لتجنب التعارض
  static const String KEY_CONFIG = "miswak_delivery_config_json";
  static const String KEY_VERSION = "miswak_delivery_config_version";
  static const String ENDPOINT = "https://re.beytei.com/wp-json/restaurant-app/v1/miswak-delivery-config";

  Map<String, dynamic>? _cachedConfig;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Map<String, dynamic>? get config => _cachedConfig;

  // 1. جلب الملف وحفظه في الكاش
  Future<void> fetchAndCacheConfig() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(Uri.parse(ENDPOINT)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _cachedConfig = data;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(KEY_CONFIG, jsonEncode(data));
        await prefs.setInt(KEY_VERSION, data['version'] ?? DateTime.now().millisecondsSinceEpoch);

        if (kDebugMode) print("✅ [MiswakConfig] تم تحديث ملف التسعير بنجاح.");
      }
    } catch (e) {
      if (kDebugMode) print("⚠️ [MiswakConfig] فشل الجلب، سيتم استخدام الكاش: $e");
      // محاولة تحميل الكاش عند الفشل
      await _loadFromCache();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 2. تحميل الكاش عند البدء
  Future<void> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(KEY_CONFIG);
    if (cached != null) {
      _cachedConfig = jsonDecode(cached);
    }
  }

  // 3. 🔥 دالة الحساب المحلي الذكي (المناطق أولاً، ثم المسافة)
  double calculateFee({
    required double userLat,
    required double userLng,
    required int storeId,
  }) {
    if (_cachedConfig == null) return 1000.0; // قيمة افتراضية آمنة

    final zones = _cachedConfig!['zones'] as List<dynamic>? ?? [];
    final pricing = _cachedConfig!['pricing'] as Map<String, dynamic>? ?? {};
    final locations = _cachedConfig!['locations'] as List<dynamic>? ?? [];

    final userPos = LatLng(userLat, userLng);

    // أ) فحص المناطق المرسومة
    for (var zone in zones) {
      final latlngs = zone['latlngs'] as List<dynamic>?;
      if (latlngs != null && _isPointInPolygon(userPos, latlngs)) {
        final price = double.tryParse(zone['price'].toString()) ?? 1000.0;
        return price;
      }
    }

    // ب) الحساب بالمسافة إذا لم يكن في منطقة
    final baseFee = double.tryParse(pricing['base_fee'].toString()) ?? 1000.0;
    final baseDist = double.tryParse(pricing['base_distance_km'].toString()) ?? 5.0;
    final extraFee = double.tryParse(pricing['extra_km_fee'].toString()) ?? 250.0;
    final maxFee = double.tryParse(pricing['max_fee'].toString()) ?? 5000.0;

    // إيجاد موقع المتجر
    final storeData = locations.firstWhere(
          (loc) => loc['id'] == storeId,
      orElse: () => {'lat': 0.0, 'lng': 0.0},
    );

    if (storeData['lat'] == 0.0) return baseFee; // لا يوجد إحداثيات

    final storePos = LatLng(
      double.tryParse(storeData['lat'].toString()) ?? 0.0,
      double.tryParse(storeData['lng'].toString()) ?? 0.0,
    );

    final distance = Geolocator.distanceBetween(
      userLat, userLng, storePos.latitude, storePos.longitude,
    ) / 1000; // بالمتر إلى كم

    double fee = baseFee;
    if (distance > baseDist) {
      fee += (distance - baseDist) * extraFee;
    }

    // التقريب والسقف
    fee = (fee / 250).ceil() * 250.0;
    if (fee > maxFee) fee = maxFee;
    if (fee < 1000) fee = 1000;

    return fee;
  }

  // خوارزمية فحص النقطة داخل المضلع
  bool _isPointInPolygon(LatLng point, List<dynamic> polygon) {
    bool inside = false;
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final p1 = polygon[i];
      final p2 = polygon[j];
      final xi = double.tryParse(p1['lat'].toString()) ?? 0.0;
      final yi = double.tryParse(p1['lng'].toString()) ?? 0.0;
      final xj = double.tryParse(p2['lat'].toString()) ?? 0.0;
      final yj = double.tryParse(p2['lng'].toString()) ?? 0.0;

      if (((yi > point.longitude) != (yj > point.longitude)) &&
          (point.latitude < (xj - xi) * (point.longitude - yi) / (yj - yi) + xi)) {
        inside = !inside;
      }
    }
    return inside;
  }
}








class SelectLocationScreen extends StatefulWidget {
  final bool isCancellable;
  const SelectLocationScreen({super.key, this.isCancellable = false});
  @override
  State<SelectLocationScreen> createState() => _SelectLocationScreenState();
}

class _SelectLocationScreenState extends State<SelectLocationScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<Area> _allAreas = [];
  List<Area> _filteredAreas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAreas();
    _searchController.addListener(_filterAreas);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAreas() async {

    try {
      final areas = await _apiService.getAreas();
      if (mounted) {
        setState(() {
          _allAreas = areas;
          _filteredAreas = areas;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterAreas() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredAreas = _allAreas.where((area) =>
          area.name.toLowerCase().contains(query)
      ).toList();
    });
  }

  Future<void> _saveSelection(int areaId, String areaName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('miswak_area_id', areaId);
    await prefs.setString('miswak_area_name', areaName);

    if (mounted) {
      if (widget.isCancellable) {
        Navigator.of(context).pop(true);
      } else {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainScreen()),
                (route) => false
        );
      }
    }
  }

  // ✨ ويدجت التحميل العصري (Shimmer)
  Widget _buildModernLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // تصفية المحافظات
    final governorates = _filteredAreas.where((a) => a.parentId == 0).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50], // خلفية فاتحة عصرية
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'تحديد الموقع',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // ✨ 1. الإشارة العصرية (Header) والبحث
          Container(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                // نص ترحيبي
                Row(
                  children: [
                    Icon(Icons.location_on, color: Theme.of(context).primaryColor, size: 28),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("أين تريد التوصيل؟", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text("اختر مدينتك ", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),

              ],
            ),
          ),

          // ✨ 2. المحتوى (قائمة أو تحميل)
          Expanded(
            child: _isLoading
                ? _buildModernLoading() // عرض التحميل العصري
                : governorates.isEmpty
                ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map_outlined, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 10),
                const Text("لا توجد مناطق مطابقة", style: TextStyle(color: Colors.grey)),
              ],
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: governorates.length,
              itemBuilder: (context, index) {
                final governorate = governorates[index];
                final cities = _filteredAreas.where((a) => a.parentId == governorate.id).toList();

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.location_city, color: Theme.of(context).primaryColor),
                      ),
                      title: Text(
                        governorate.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      childrenPadding: const EdgeInsets.only(bottom: 10),
                      children: cities.map((city) => ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                        title: Text(city.name),
                        leading: const Icon(Icons.subdirectory_arrow_right, size: 18, color: Colors.grey),
                        trailing: const Icon(Icons.check_circle_outline, color: Colors.grey),
                        onTap: () => _saveSelection(city.id, city.name),
                      )).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


class RestaurantsScreen extends StatefulWidget {
  const RestaurantsScreen({super.key});
  @override
  State<RestaurantsScreen> createState() => _RestaurantsScreenState();
}

class _RestaurantsScreenState extends State<RestaurantsScreen> {
  int? _selectedAreaId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
  }

  Future<void> _loadInitialData({bool isRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    // ✅ Fix: القراءة من المفتاح الصحيح المعتمد في المسواك
    _selectedAreaId = prefs.getInt('miswak_area_id');

    if (_selectedAreaId != null) {
      Provider.of<StoreCustomerProvider>(context, listen: false).fetchAllRestaurants(_selectedAreaId!, isRefresh: isRefresh);
    } else {
      // إذا لم يكن هناك منطقة محددة (أول دخول)، نترك الشاشة تعرض رسالة تحديد المنطقة.
      setState(() {});
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المسواك')),
      body: Consumer<StoreCustomerProvider>(
        builder: (context, provider, child) {
          if (_selectedAreaId == null) return const Center(child: Text("يرجى تحديد منطقة أولاً."));

          if (provider.isLoadingRestaurants && provider.allRestaurants.isEmpty) {
            return GridView.builder(padding: const EdgeInsets.all(15), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 0.7), itemCount: 6, itemBuilder: (context, index) => const ShimmerRestaurantCard());
          }
          if (provider.hasError && provider.allRestaurants.isEmpty) {
            return NetworkErrorWidget(message: 'فشل في جلب ', onRetry: () => _loadInitialData(isRefresh: true));
          }
          if (provider.allRestaurants.isEmpty) {
            return const Center(child: Text("لا توجد مسواك متاحة حالياً"));
          }

          return RefreshIndicator(
            onRefresh: () => _loadInitialData(isRefresh: true),
            child: GridView.builder(
              padding: const EdgeInsets.all(15),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 0.7),
              itemCount: provider.allRestaurants.length,
              itemBuilder: (context, index) {
                return RestaurantCard(restaurant: provider.allRestaurants[index]);
              },
            ),
          );
        },
      ),
    );
  }
}
// ✨ ألصق هذا الكود في ملف re.dart

class PermissionService {
  static Future<bool> handleLocationPermission(BuildContext context) async {
    bool serviceEnabled = await geolocator.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('خدمات الموقع معطلة. الرجاء تفعيل خدمات الموقع.'))
        );
      }
      return false;
    }

    geolocator.LocationPermission permission = await geolocator.Geolocator.checkPermission();
    if (permission == geolocator.LocationPermission.denied) {
      permission = await geolocator.Geolocator.requestPermission();
      if (permission == geolocator.LocationPermission.denied) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم رفض إذن الوصول للموقع.'))
          );
        }
        return false;
      }
    }

    if (permission == geolocator.LocationPermission.deniedForever) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم رفض إذن الموقع بشكل دائم، يرجى تفعيله من إعدادات التطبيق.'))
        );
      }
      return false;
    }

    return true;
  }
}
class MenuScreen extends StatefulWidget {
  final Restaurant restaurant;
  const MenuScreen({super.key, required this.restaurant});
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

// (الصق هذا الكلاس بالكامل بدلاً من الكلاس القديم)
class _MenuScreenState extends State<MenuScreen> {


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // هذا الكود صحيح وسيجلب الحالة الصحيحة (مغلق)
      Provider.of<StoreCustomerProvider>(context, listen: false).fetchMenuForRestaurant(widget.restaurant.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.restaurant.name)),
      body: Consumer<StoreCustomerProvider>(
        builder: (context, provider, child) {
          final menu = provider.menuItems[widget.restaurant.id] ?? [];

          if (provider.isLoadingMenu && menu.isEmpty) {
            return GridView.builder(padding: const EdgeInsets.all(15), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 0.75), itemCount: 8, itemBuilder: (context, index) => const ShimmerFoodCard());
          }
          if (provider.hasError && menu.isEmpty) {
            return NetworkErrorWidget(message: 'فشل في جلب قائمة ', onRetry: () => provider.fetchMenuForRestaurant(widget.restaurant.id, isRefresh: true));
          }
          if (menu.isEmpty) {
            // ✨ تعديل بسيط: إظهار رسالة إذا كان المطعم مغلقاً ولا توجد منتجات
            if (!widget.restaurant.isOpen) {
              return Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.door_sliding_outlined, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text("المطعم مغلق حالياً", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    "يفتح تلقائياً في: ${widget.restaurant.autoOpenTime}\nيغلق تلقائياً في: ${widget.restaurant.autoCloseTime}",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                  ),
                ],
              ));
            }
            return const Center(child: Text("لا توجد وجبات في هذا  حالياً"));
          }
          return RefreshIndicator(
            onRefresh: () => provider.fetchMenuForRestaurant(widget.restaurant.id, isRefresh: true),
            child: GridView.builder(
              padding: const EdgeInsets.all(15),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 0.75),
              itemCount: menu.length,
              itemBuilder: (context, index) {
                final item = menu[index];

                // ✨ --- [ هذا هو الإصلاح ] --- ✨
                //
                // تم حذف السطر الخاطئ: item.isDeliverable = true;
                //
                // الآن التطبيق سيستخدم الحالة التي جلبها من الخادم
                // (isDeliverable: false)
                // --- [ نهاية الإصلاح ] ---

                return FoodCard(food: item);
              },
            ),
          );
        },
      ),
    );
  }
}

class SearchScreen extends StatefulWidget {
  final String searchQuery;
  final int selectedAreaId;
  const SearchScreen({super.key, required this.searchQuery, required this.selectedAreaId});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late Future<List<FoodItem>> _searchFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadAndFilterSearch();
  }

  void _loadAndFilterSearch() {
    setState(() {
      // ✨ [الإصلاح]: حذفنا areaId من هنا
      _searchFuture = _apiService.searchProducts(query: widget.searchQuery).then((allResults) async {

        // (الكود التالي سليم ومهم للفلترة داخل التطبيق)
        final deliverableIds = await _apiService.getDeliverableRestaurantIds(widget.selectedAreaId);

        final provider = Provider.of<StoreCustomerProvider>(context, listen: false);        final statusMap = { for (var r in provider.allRestaurants) r.id : r.isOpen };

        // ✨ [الإصلاح الأهم]: الفلترة حسب المنطقة تتم هنا الآن
        return allResults.where((item) {
          final isDeliverable = deliverableIds.contains(item.categoryId);
          if (!isDeliverable) return false; // فلترة المنطقة

          item.isDeliverable = statusMap[item.categoryId] ?? false; // فلترة حالة الفتح
          return true;
        }).toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('نتائج البحث عن: "${widget.searchQuery}"')),
      body: FutureBuilder<List<FoodItem>>(
        future: _searchFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return GridView.builder(padding: const EdgeInsets.all(15), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 0.75), itemCount: 8, itemBuilder: (context, index) => const ShimmerFoodCard());
          if (snapshot.hasError) return NetworkErrorWidget(message: "فشل البحث", onRetry: _loadAndFilterSearch);
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("لم يتم العثور على نتائج لبحثك"));

          final results = snapshot.data!;
          return GridView.builder(padding: const EdgeInsets.all(15), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 0.75), itemCount: results.length, itemBuilder: (context, index) => FoodCard(food: results[index]));
        },
      ),
    );
  }
}

class DetailScreen extends StatefulWidget {
  final FoodItem foodItem;
  const DetailScreen({super.key, required this.foodItem});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  // الوزن المختار افتراضياً
  double _currentWeight = 1.0;

  // ✨✨✨ الترتيب الجديد: كيلو ونصف ← كيلو ← نصف ← ربع ✨✨✨
  final List<double> _quickWeights = [1.5, 1.0, 0.5, 0.25];

  // ✨ دالة مقارنة الأوزان بدقة (لتجنب مشاكل الفاصلة العشرية)
  bool _weightsAreEqual(double w1, double w2) {
    return (w1 - w2).abs() < 0.001;
  }

  // دالة لعرض نافذة إدخال وزن مخصص
  void _showCustomWeightDialog() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("أدخل الوزن (بالكيلو)", style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            hintText: "مثال: 5.5",
            suffixText: "كغم",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.scale),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val > 0) {
                setState(() {
                  _currentWeight = val;
                });
                Navigator.pop(ctx);
                HapticFeedback.lightImpact();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("تأكيد"),
          ),
        ],
      ),
    );
  }

  // دالة مساعدة لجلب النص المعروض للزر
  String _getWeightLabel(double w) {
    if (w == 0.25) return "ربع";
    if (w == 0.5) return "نصف";
    if (w == 1.0) return "1 كيلو";
    if (w == 1.5) return "كيلو ونصف";
    if (w % 1 == 0) return "${w.toInt()} كيلو";
    return "$w كيلو";
  }

  // ✨ دالة مساعدة لعرض الوزن بشكل كامل (للسعر والنافذة)
  String _getWeightDisplayText(double weight) {
    if (weight == 0.25) return "ربع كيلو (250غم)";
    if (weight == 0.5) return "نصف كيلو (500غم)";
    if (weight == 1.0) return "1 كيلو";
    if (weight == 1.5) return "كيلو ونصف (1.5 كغم)";
    if (weight % 1 == 0) return "${weight.toInt()} كيلو";
    return "$weight كيلو";
  }

  @override
  Widget build(BuildContext context) {
    // حساب السعر الفوري
    final double basePrice = widget.foodItem.salePrice ?? widget.foodItem.price;
    final double calculatedPrice = basePrice * _currentWeight;
    final String formattedPrice = NumberFormat('#,###', 'ar_IQ').format(calculatedPrice);

    final bool isDeliverable = widget.foodItem.isDeliverable;

    // جلب أوقات المطعم (لعرضها إذا كان مغلقاً)
    final provider = Provider.of<StoreCustomerProvider>(context, listen: false);
    Restaurant? restaurant;
    try {
      restaurant = provider.allRestaurants.firstWhere((r) => r.id == widget.foodItem.categoryId);
    } catch (_) {}

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // صورة المنتج مع تأثير تكبير
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'food_image_${widget.foodItem.id}',
                child: CachedNetworkImage(
                  imageUrl: widget.foodItem.imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (c, u, e) => Container(
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.fastfood, size: 80, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ),

          // محتوى التفاصيل
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // الاسم والسعر
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.foodItem.name,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "$formattedPrice د.ع",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          Text(
                            _currentWeight < 1
                                ? "${(_currentWeight * 1000).toInt()} غم"
                                : "$_currentWeight كغم",
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // ✨✨✨ قسم اختيار الوزن العصري المحسن ✨✨✨
                  const Text("اختر الوزن:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 16),

                  // الصف الأول: كيلو ونصف + كيلو
                  Row(
                    children: [
                      Expanded(
                        child: _buildWeightChip(
                          label: "كيلو ونصف",
                          subLabel: "1.5 كغم",
                          weight: 1.5,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildWeightChip(
                          label: "1 كيلو",
                          subLabel: "1000 غم",
                          weight: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // الصف الثاني: نصف + ربع
                  Row(
                    children: [
                      Expanded(
                        child: _buildWeightChip(
                          label: "نصف كيلو",
                          subLabel: "500 غم",
                          weight: 0.5,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildWeightChip(
                          label: "ربع كيلو",
                          subLabel: "250 غم",
                          weight: 0.25,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // زر الوزن المخصص
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _showCustomWeightDialog();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: !_quickWeights.any((w) => _weightsAreEqual(w, _currentWeight))
                            ? Theme.of(context).primaryColor
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: !_quickWeights.any((w) => _weightsAreEqual(w, _currentWeight))
                              ? Theme.of(context).primaryColor
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.edit_note_rounded,
                            color: !_quickWeights.any((w) => _weightsAreEqual(w, _currentWeight))
                                ? Colors.white
                                : Colors.grey.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "حدد وزن مخصص",
                            style: TextStyle(
                              color: !_quickWeights.any((w) => _weightsAreEqual(w, _currentWeight))
                                  ? Colors.white
                                  : Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                  const Divider(),
                  const SizedBox(height: 10),

                  const Text("الوصف", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(
                    widget.foodItem.description,
                    style: TextStyle(color: Colors.grey.shade700, height: 1.6, fontSize: 15),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),

      // الزر السفلي العائم
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: isDeliverable
            ? ElevatedButton(
          onPressed: () {
            // ✅ إضافة المنتج مع الوزن المختار للسلة
            Provider.of<CartProvider>(context, listen: false).addToCart(
              widget.foodItem,
              context,
              weight: _currentWeight,
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 8,
            shadowColor: Theme.of(context).primaryColor.withOpacity(0.3),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "إضافة للسلة",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    "$formattedPrice د.ع",
                    style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9)),
                  ),
                ],
              ),
            ],
          ),
        )
            : Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "غير متاح حالياً",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade700, fontSize: 16),
                  ),
                ],
              ),
              if (restaurant != null) ...[
                const SizedBox(height: 4),
                Text(
                  "يفتح ${restaurant.autoOpenTime}",
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ✨ دالة بناء زر الوزن المحسنة (تصميم شبكي عصري)
  Widget _buildWeightChip({
    required String label,
    required String subLabel,
    required double weight,
  }) {
    final bool isSelected = _weightsAreEqual(_currentWeight, weight);

    return GestureDetector(
      onTap: () {
        setState(() => _currentWeight = weight);
        HapticFeedback.lightImpact();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Theme.of(context).primaryColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ]
              : [],
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subLabel,
              style: TextStyle(
                color: isSelected ? Colors.white70 : Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 6),
              Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 18,
              ),
            ],
          ],
        ),
      ),
    );
  }
}


class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _apiService = ApiService();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _couponController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  // ✨ دالة مساعدة لعرض الوزن بشكل جميل
  String _getWeightDisplayText(double weight) {
    if (weight == 0.25) return "ربع كيلو (250غم)";
    if (weight == 0.5) return "نصف كيلو (500غم)";
    if (weight == 1.0) return "1 كيلو";
    if (weight == 1.5) return "كيلو ونصف (1.5 كغم)";
    if (weight % 1 == 0) return "${weight.toInt()} كيلو";
    return "$weight كيلو";
  }

  @override
  Widget build(BuildContext context) {
    final mainContext = context;

    return Scaffold(
      appBar: AppBar(
        title: const Text('سلتي'),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              if (cart.items.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'إفراغ السلة',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                            SizedBox(width: 10),
                            Text('تفريغ السلة؟', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        content: const Text('هل تريد حذف جميع العناصر من سلتك؟'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                          ElevatedButton(
                            onPressed: () {
                              cart.clearCart();
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('تم تفريغ السلة'), backgroundColor: Colors.green),
                              );
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            child: const Text('نعم، احذف'),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (ctx, cart, child) {
          if (cart.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 100, color: Colors.grey.shade400),
                  const SizedBox(height: 20),
                  const Text(
                    'سلّتك فارغة!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'ابدأ التسوق الآن لإضافة منتجاتك المفضلة',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: () {
                      Provider.of<NavigationProvider>(context, listen: false).changeTab(0);
                    },
                    icon: const Icon(Icons.storefront),
                    label: const Text('تصفح المسواك'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ],
              ),
            );
          }
          return Column(children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: cart.items.length,
                itemBuilder: (ctx, index) =>
                    _buildCartItemCard(mainContext, cart, cart.items[index]),
              ),
            ),
            _buildCheckoutSection(mainContext, cart),
          ]);
        },
      ),
    );
  }

  Widget _buildPriceSummary(CartProvider cart, double? deliveryFee,
      bool isCalculatingFee, String feeMessage) {
    final totalFormatted = NumberFormat('#,###', 'ar_IQ').format(cart.totalPrice);
    final discountFormatted = NumberFormat('#,###', 'ar_IQ').format(cart.totalDiscountAmount);
    final double finalTotal = (cart.discountedTotal) + (deliveryFee ?? 0);
    final finalTotalFormatted = NumberFormat('#,###', 'ar_IQ').format(finalTotal);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('سعر الطلبات', style: TextStyle(fontSize: 14)),
              Text('$totalFormatted د.ع',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          if (cart.totalDiscountAmount > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('الخصم',
                    style: TextStyle(fontSize: 14, color: Theme.of(context).primaryColor)),
                Text('- $discountFormatted د.ع',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor)),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.delivery_dining_outlined, size: 20, color: Colors.blue.shade700),
                  const SizedBox(width: 5),
                  const Text('خدمة التوصيل', style: TextStyle(fontSize: 14)),
                ],
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: isCalculatingFee
                    ? const SizedBox(
                    key: ValueKey('calc'),
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(
                  deliveryFee != null
                      ? '${NumberFormat('#,###', 'ar_IQ').format(deliveryFee)} د.ع'
                      : '---',
                  key: const ValueKey('fee'),
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: deliveryFee == null && !isCalculatingFee
                          ? Colors.red
                          : Colors.black),
                ),
              ),
            ],
          ),
          if (feeMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                feeMessage.replaceAll("Exception: ", ""),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.red.shade700),
              ),
            ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('الإجمالي المطلوب دفعه',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: isCalculatingFee || deliveryFee == null
                    ? const SizedBox.shrink()
                    : Text(
                  '$finalTotalFormatted د.ع',
                  key: ValueKey(finalTotalFormatted),
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCheckoutDialog(BuildContext context, CartProvider cart) {
    final BuildContext cartScreenContext = context;

    _nameController.clear();
    _phoneController.clear();
    _addressController.clear();
    _couponController.text = cart.appliedCoupon ?? '';
    bool isSubmitting = false;

    geolocator.Position? _capturedPosition;

    // 🔥 الحالة الأولية: جاري الحساب المحلي
    String _locationMessage = "جاري حساب التوصيل...";
    double _deliveryFee = 0.0;
    bool _isCalcFinished = false;

    showDialog(
      context: cartScreenContext,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(builder: (context, setDialogState) {

          // 🔥🔥 محرك الحساب المحلي الذكي
          if (!_isCalcFinished) {
            Future.delayed(Duration.zero, () async {
              try {
                // 1. جلب الموقع
                bool serviceEnabled = await geolocator.Geolocator.isLocationServiceEnabled();
                if (serviceEnabled) {
                  geolocator.LocationPermission permission = await geolocator.Geolocator.checkPermission();
                  if (permission == geolocator.LocationPermission.denied) {
                    permission = await geolocator.Geolocator.requestPermission();
                  }
                  if (permission == geolocator.LocationPermission.whileInUse ||
                      permission == geolocator.LocationPermission.always) {
                    _capturedPosition = await geolocator.Geolocator.getCurrentPosition(
                        desiredAccuracy: geolocator.LocationAccuracy.high,
                        timeLimit: const Duration(seconds: 5));
                  }
                }

                if (_capturedPosition != null && cart.items.isNotEmpty) {
                  // 2. استخدام البروفايدر المستقل للمسواك
                  final configProvider = Provider.of<MiswakDeliveryConfigProvider>(cartScreenContext, listen: false);

                  // ضمان وجود الملف (يحمّل من الكاش فوراً، أو يجلب من السيرفر إذا لم يوجد)
                  if (configProvider.config == null) {
                    await configProvider.fetchAndCacheConfig();
                  }

                  final int storeId = cart.items.first.categoryId;

                  // 3. الحساب المحلي الفوري
                  final fee = configProvider.calculateFee(
                    userLat: _capturedPosition!.latitude,
                    userLng: _capturedPosition!.longitude,
                    storeId: storeId,
                  );

                  if (context.mounted) {
                    setDialogState(() {
                      _deliveryFee = fee;
                      _locationMessage = "✅ تم حساب التوصيل: ${fee.toInt()} د.ع";
                      _isCalcFinished = true;
                    });
                  }
                } else {
                  // فشل جلب الموقع
                  setDialogState(() {
                    _deliveryFee = 1000.0; // سعر افتراضي آمن
                    _locationMessage = "⚠️ تعذر تحديد الموقع، تم تطبيق السعر الأساسي";
                    _isCalcFinished = true;
                  });
                }
              } catch (e) {
                // أي خطأ = شبكة أمان
                setDialogState(() {
                  _deliveryFee = 1000.0;
                  _locationMessage = "⚠️ حدث خطأ، تم تطبيق السعر الأساسي (1000 د.ع)";
                  _isCalcFinished = true;
                });
              }
            });
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.shopping_cart_checkout, color: Colors.teal, size: 28),
                SizedBox(width: 10),
                Text('إتمام الطلب', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'الاسم الكامل',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                      validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                      enabled: !isSubmitting,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'رقم الهاتف',
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                      enabled: !isSubmitting,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'العنوان بالتفصيل',
                        prefixIcon: Icon(Icons.location_on_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                      validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                      enabled: !isSubmitting,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),

                    // 📦 عرض السعر المحسوب محلياً
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            const Text("تكلفة التوصيل:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text("${NumberFormat('#,###').format(_deliveryFee)} د.ع",
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16)),
                          ]),
                          const SizedBox(height: 5),
                          Text(_locationMessage, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _couponController,
                      decoration: const InputDecoration(
                        labelText: 'كود الخصم (اختياري)',
                        prefixIcon: Icon(Icons.local_offer_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                    ),
                    const Divider(height: 30),
                    _buildPriceSummary(cart, _deliveryFee, !_isCalcFinished, ""),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.of(dialogContext).pop(),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                // منع الإرسال حتى يكتمل الحساب
                onPressed: (isSubmitting || !_isCalcFinished) ? null : () async {
                  if (!_formKey.currentState!.validate()) return;

                  setDialogState(() => isSubmitting = true);

                  try {
                    final prefs = await SharedPreferences.getInstance();
                    final int currentZoneId = prefs.getInt('miswak_area_id') ?? 0;
                    int? storeId = cart.items.isNotEmpty ? cart.items.first.categoryId : null;

                    if (currentZoneId == 0) throw Exception("يرجى تحديد المنطقة من الصفحة الرئيسية.");

                    // 🚀 إرسال الطلب مع السعر المحسوب محلياً
                    final createdOrder = await _apiService.submitOrder(
                      name: _nameController.text,
                      phone: _phoneController.text,
                      address: _addressController.text,
                      cartItems: cart.items,
                      couponCode: cart.appliedCoupon,
                      position: _capturedPosition,
                      deliveryFee: _deliveryFee, // ✅ السعر المحسوب محلياً
                      restaurantId: storeId,
                      regionId: currentZoneId,
                    );

                    if (!cartScreenContext.mounted) return;
                    if (createdOrder == null) throw Exception('فشل إنشاء الطلب.');

                    await cart._recordSuccessfulOrder();
                    Navigator.of(dialogContext).pop();
                    cart.clearCart();
                    Provider.of<NotificationProvider>(cartScreenContext, listen: false).triggerRefresh();

                    showDialog(
                      context: cartScreenContext,
                      barrierDismissible: false,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_circle, color: Colors.green, size: 60),
                            ),
                            const SizedBox(height: 20),
                            const Text("تم بنجاح! 🎉", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            const Text(
                              "تم استلام طلبك بنجاح.\nسيتم التواصل معك قريباً.",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                        actions: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              Provider.of<NavigationProvider>(cartScreenContext, listen: false).changeTab(2);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text("متابعة الطلب"),
                          )
                        ],
                      ),
                    );
                  } catch (e) {
                    if (cartScreenContext.mounted) {
                      ScaffoldMessenger.of(cartScreenContext).showSnackBar(
                        SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
                      );
                    }
                  } finally {
                    if (dialogContext.mounted) setDialogState(() => isSubmitting = false);
                  }
                },
                child: isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('تأكيد الطلب'),
              )
            ],
          );
        });
      },
    );
  }

  Widget _buildCartItemCard(BuildContext context, CartProvider cart, FoodItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: CachedNetworkImage(
                imageUrl: item.imageUrl,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                errorWidget: (c, u, e) => Container(
                  width: 90,
                  height: 90,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.fastfood, size: 40, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.scale_rounded,
                          size: 14,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getWeightDisplayText(item.selectedWeight),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.formattedPrice,
                    style: TextStyle(
                      fontSize: 17,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 20),
                        onPressed: () => cart.decrementQuantity(item),
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                      ),
                      Text(
                        item.quantity.toString(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 20),
                        onPressed: () => cart.incrementQuantity(item),
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 22),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: const Text('حذف المنتج؟', style: TextStyle(fontWeight: FontWeight.bold)),
                        content: Text('هل تريد حذف "${item.name}" من السلة؟'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('إلغاء'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              cart.decrementQuantity(item);
                              Navigator.pop(ctx);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('حذف'),
                          ),
                        ],
                      ),
                    );
                  },
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutSection(BuildContext context, CartProvider cart) {
    final totalFormatted = NumberFormat('#,###', 'ar_IQ').format(cart.totalPrice);
    final discountedTotalFormatted = NumberFormat('#,###', 'ar_IQ').format(cart.discountedTotal);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 5,
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('المجموع', style: TextStyle(fontSize: 18, color: Colors.grey)),
              Text(
                '$totalFormatted د.ع',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                  decoration: cart.appliedCoupon != null ? TextDecoration.lineThrough : TextDecoration.none,
                ),
              ),
            ],
          ),
          if (cart.appliedCoupon != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'الإجمالي بعد الخصم',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  Text(
                    '$discountedTotalFormatted د.ع',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showCheckoutDialog(context, cart),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                elevation: 8,
                shadowColor: Theme.of(context).primaryColor.withOpacity(0.3),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_checkout, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  const Text(
                    'إتمام الطلب',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OrdersHistoryScreen extends StatefulWidget {
  const OrdersHistoryScreen({super.key});
  @override
  State<OrdersHistoryScreen> createState() => _OrdersHistoryScreenState();
}

class _OrdersHistoryScreenState extends State<OrdersHistoryScreen> {
  late Future<List<Order>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    // ✅ Fix: تم حذف Listener لـ NotificationProvider الذي كان يسبب الخطأ
    _loadOrders();
    // يجب أن تكون OrdersHistoryScreen لا تستمع لـ NotificationProvider
    // لأنها شاشة العميل (سجل محلي)، وليست شاشة المدير (تحديثات فورية).
  }

  @override
  void dispose() {
    // 🛑 Fix: تأكد من حذف أي محاولة لإزالة Listener مفقود
    super.dispose();
  }

  void _loadOrders() => setState(() => _ordersFuture = OrderHistoryService().getOrders());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سجل طلباتي')),
      body: RefreshIndicator(
        onRefresh: () async => _loadOrders(),
        child: FutureBuilder<List<Order>>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('حدث خطأ: ${snapshot.error}'));
            }

            final orders = snapshot.data;

            // ✅ Fix: معالجة حالة القائمة الفارغة لعرض رسالة بدلاً من الشاشة البيضاء
            if (orders == null || orders.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  const Icon(Icons.history_toggle_off, size: 80, color: Colors.grey),
                  const SizedBox(height: 20),
                  const Center(
                      child: Text(
                          'لا يوجد لديك طلبات سابقة',
                          style: TextStyle(fontSize: 18, color: Colors.grey)
                      )
                  )
                ],
              );
            }

            // عرض القائمة
            return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: orders.length,
                itemBuilder: (context, index) => OrderHistoryCard(order: orders[index])
            );
          },
        ),
      ),
    );
  }
}
class StoreLoginScreen extends StatefulWidget {
  const StoreLoginScreen({super.key});

  @override
  State<StoreLoginScreen> createState() => _StoreLoginScreenState();
}

class _StoreLoginScreenState extends State<StoreLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  bool _isLoading = false;
  String _locationStatus = 'لم يتم تحديد موقع المتجر';

  final ApiService _apiService = ApiService();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  // دالة تحديد الموقع الحالي
  Future<void> _getCurrentLocation() async {
    setState(() => _locationStatus = 'جاري تحديد الموقع...');

    try {
      final hasPermission = await PermissionService.handleLocationPermission(context);

      if (!hasPermission) {
        setState(() => _locationStatus = 'لا توجد صلاحيات للموقع');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
      );

      if (!mounted) return;

      _latController.text = position.latitude.toString();
      _lngController.text = position.longitude.toString();

      setState(() {
        _locationStatus = 'تم التحديد بنجاح ✅';
      });

    } catch (e) {
      setState(() {
        _locationStatus = 'فشل تحديد الموقع: حاول مرة أخرى';
      });
    }
  }

  Future<void> _login() async {
    print("🔍 DEBUG: [LoginScreen] 1. Login Button Pressed");

    if (!_formKey.currentState!.validate()) return;

    if (_latController.text.isEmpty || _lngController.text.isEmpty) {
      print("🔍 DEBUG: [LoginScreen] Location is missing");
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء تحديد موقع المتجر أولاً.'))
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      print("🔍 DEBUG: [LoginScreen] 2. Calling AuthProvider...");
      final authProvider = Provider.of<StoreAuthProvider>(context, listen: false);

      final success = await authProvider.login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
        'owner',
        lat: _latController.text,
        lng: _lngController.text,
      );

      if (!mounted) {
        print("🔍 DEBUG: [LoginScreen] Widget unmounted during process");
        return;
      }

      print("🔍 DEBUG: [LoginScreen] 3. Login Result: $success");

      if (success) {
        // 🔥🔥 التعديل الحاسم: الانتظار قليلاً لضمان تحديث الـ Provider 🔥🔥
        print("🔍 DEBUG: [LoginScreen] 4. Success! Waiting 100ms...");
        await Future.delayed(const Duration(milliseconds: 100));

        if (mounted) {
          print("🔍 DEBUG: [LoginScreen] 5. Executing Navigation to Dashboard...");
          // استخدام pushAndRemoveUntil لمسح أي شاشة سابقة (بما فيها الرئيسية إذا فتحت بالخطأ)
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const StoreDashboardScreen()),
                (Route<dynamic> route) => false,
          );
        }
      } else {
        print("🔍 DEBUG: [LoginScreen] Login failed (Success = false)");
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('بيانات الدخول غير صحيحة'), backgroundColor: Colors.red)
        );
      }
    } catch (e) {
      print("🔍 DEBUG: [LoginScreen] Exception Caught: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('دخول مدير المسواك')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.storefront, size: 80, color: Colors.teal),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                        labelText: 'اسم المستخدم',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder()
                    ),
                    validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null,
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                        labelText: 'كلمة المرور',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder()
                    ),
                    obscureText: true,
                    validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null,
                  ),

                  const SizedBox(height: 30),

                  // زر تحديد الموقع
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10)
                    ),
                    child: Column(
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.location_on, color: Colors.red),
                          label: const Text('تحديد موقع المتجر (مطلوب)'),
                          onPressed: _getCurrentLocation,
                          style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 45)),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _locationStatus,
                          style: TextStyle(
                              color: _latController.text.isEmpty ? Colors.red : Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 12
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white
                      ),
                      child: const Text('تسجيل الدخول')
                  )
                ]),
          ),
        ),
      ),
    );
  }
}




















class InAppMapScreen extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String title;

  const InAppMapScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    this.title = 'موقع على الخريطة'
  });

  @override
  Widget build(BuildContext context) {
    // تحويل الإحداثيات إلى النوع الذي يتطلبه flutter_map
    final LatLng point = LatLng(latitude, longitude);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: point,
          initialZoom: 16.0,
          // إعدادات توفير الرصيد (هام جداً)
          maxZoom: 18.0,
          minZoom: 10.0,
          // لون الخلفية لتقليل الوميض الأبيض
          backgroundColor: const Color(0xFFE5E5E5),
        ),
        children: [
          // 1. طبقة خريطة Mapbox مع الكاش
          TileLayer(
            urlTemplate: 'https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token={accessToken}',

            // 🔥 تفعيل الكاش (هام جداً لعدم إعادة تحميل الصور)
            // استبدل السطر المسبب للمشكلة بهذا:
            tileProvider: NetworkTileProvider(),

            additionalOptions: const {
              'accessToken': 'pk.eyJ1IjoicmUtYmV5dGVpMzIxIiwiYSI6ImNtaTljbzM4eDBheHAyeHM0Y2Z0NmhzMWMifQ.ugV8uRN8pe9MmqPDcD5XcQ',
              'id': 'mapbox/streets-v12',
            },
            userAgentPackageName: 'com.beytei.restaurantmodule',

            // إعدادات السلاسة
            panBuffer: 2,
            keepBuffer: 5,
          ),
          // 2. طبقة الماركر (كما هي)
          MarkerLayer(
            markers: [
              Marker(
                point: point,
                width: 80,
                height: 80,
                child: Icon(
                  Icons.location_pin,
                  color: Colors.red.shade700,
                  size: 50,
                ),
              ),
            ],
          ),
        ],
      ),    );
  }
}







// =======================================================================
// --- Restaurant Dashboard Screen (Complete) ---
// =======================================================================


class StoreDashboardScreen extends StatefulWidget {
  const StoreDashboardScreen({super.key});
  @override
  State<StoreDashboardScreen> createState() => _StoreDashboardScreenState();
}

class _StoreDashboardScreenState extends State<StoreDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = Provider.of<StoreAuthProvider>(context, listen: false).token;
      if (token != null) {
        Provider.of<MiswakSettingsProvider>(context, listen: false).fetchSettings(token).then((_) {
          if (mounted) {
            Provider.of<MiswakDashboardProvider>(context, listen: false).startAutoRefresh(token);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    if (mounted) {
      try {
        Provider.of<MiswakDashboardProvider>(context, listen: false).stopAutoRefresh();
      } catch (_) {}
    }
    _tabController.dispose();
    super.dispose();
  }

  // --- نافذة طلب التوصيل الخاص (الزر العائم) ---
  void _showPrivateDeliveryRequestDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final pickupNameController = TextEditingController();
    final destAddressController = TextEditingController();
    final feeController = TextEditingController();
    final phoneController = TextEditingController();
    final notesController = TextEditingController();
    bool isSubmitting = false;

    SharedPreferences.getInstance().then((prefs) {
      pickupNameController.text = prefs.getString('restaurant_name') ?? '';
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('طلب توصيل خاص (مسواك)'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(controller: pickupNameController, decoration: const InputDecoration(labelText: 'اسم نقطة الاستلام'), validator: (v) => v!.isEmpty ? 'مطلوب' : null),
                      const SizedBox(height: 10),
                      TextFormField(controller: destAddressController, decoration: const InputDecoration(labelText: 'عنوان الزبون'), validator: (v) => v!.isEmpty ? 'مطلوب' : null),
                      const SizedBox(height: 10),
                      TextFormField(controller: phoneController, decoration: const InputDecoration(labelText: 'رقم هاتف الزبون'), keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'مطلوب' : null),
                      const SizedBox(height: 10),
                      TextFormField(controller: feeController, decoration: const InputDecoration(labelText: 'سعر التوصيل (د.ع)'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'مطلوب' : null),
                      const SizedBox(height: 10),
                      TextFormField(controller: notesController, decoration: const InputDecoration(labelText: 'ملاحظات'), maxLines: 2),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
                ElevatedButton(
                  onPressed: isSubmitting ? null : () async {
                    if (formKey.currentState!.validate()) {
                      setDialogState(() => isSubmitting = true);
                      try {
                        final prefs = await SharedPreferences.getInstance();
                        final token = prefs.getString('store_jwt_token'); // توكن المسواك
                        final lat = prefs.getDouble('restaurant_lat');
                        final lng = prefs.getDouble('restaurant_lng');

                        if (token == null || lat == null || lng == null) throw Exception("بيانات الموقع ناقصة");

                        await _apiService.createUnifiedDeliveryRequest(
                          token: token,
                          sourceType: 'market', // ✅ نوع المصدر مسواك
                          pickupName: pickupNameController.text,
                          pickupLat: lat,
                          pickupLng: lng,
                          destinationAddress: destAddressController.text,
                          deliveryFee: feeController.text,
                          orderDescription: notesController.text,
                          endCustomerPhone: phoneController.text,
                        );

                        if (mounted) {
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال الطلب بنجاح!'), backgroundColor: Colors.green));
                        }
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
                      } finally {
                        if (mounted) setDialogState(() => isSubmitting = false);
                      }
                    }
                  },
                  child: isSubmitting ? const CircularProgressIndicator() : const Text('إرسال'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<StoreAuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم المسواك'),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_active_outlined), onPressed: () async {
            await _apiService.testNotification();
          }, tooltip: 'اختبار'),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => auth.logout(context), tooltip: 'خروج')
        ],
        // ✅ عرض العدادات في التبويبات
        bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: [
              Tab(
                child: Consumer<MiswakDashboardProvider>(
                  builder: (_, dash, __) => Row(children: [
                    const Text('الطلبات'),
                    if (dash.orders['active']!.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(right: 5),
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: Text('${dash.orders['active']!.length}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                      )
                  ]),
                ),
              ),
              Tab(
                  child: Consumer<MiswakDashboardProvider>(
                    builder: (_, dash, __) => Text('المكتملة (${dash.orders['completed']?.length ?? 0})'),
                  )
              ),
              const Tab(icon: Icon(Icons.fastfood_outlined), text: 'المنتجات'),
              const Tab(icon: Icon(Icons.star_rate), text: 'التقييمات'),
              const Tab(icon: Icon(Icons.settings), text: 'الإعدادات'),
            ]
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          OrdersListScreen(status: 'active'),
          OrdersListScreen(status: 'completed'),
          const ProductManagementTab(),
          const RatingsDashboardScreen(),
          const RestaurantSettingsScreen(),
        ],
      ),
      // ✅ زر التوصيل الخاص العائم
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPrivateDeliveryRequestDialog(context),
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.motorcycle, color: Colors.white),
        label: const Text("توصيل خاص", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
class ProductManagementTab extends StatefulWidget {
  const ProductManagementTab({super.key});

  @override
  State<ProductManagementTab> createState() => _ProductManagementTabState();
}

class _ProductManagementTabState extends State<ProductManagementTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToAddScreen() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => AddProductScreen(
      // ✅ تمرير بروفايدر المسواك
      productProvider: Provider.of<MiswakProductsProvider>(context, listen: false),
      authProvider: Provider.of<StoreAuthProvider>(context, listen: false),
    )));
  }

  void _navigateToEditScreen(FoodItem product) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => EditProductScreen(
      product: product,
      // ✅ تمرير بروفايدر المسواك
      productProvider: Provider.of<MiswakProductsProvider>(context, listen: false),
      authProvider: Provider.of<StoreAuthProvider>(context, listen: false),
    )));
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<StoreAuthProvider>(context);

    // ✅ استخدام Consumer<MiswakProductsProvider>
    return Consumer<MiswakProductsProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          // زر إضافة منتج
          floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _navigateToAddScreen,
            label: const Text("إضافة منتج"),
            icon: const Icon(Icons.add),
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),

          appBar: AppBar(
            title: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'ابحث عن منتج...',
                prefixIcon: Icon(Icons.search),
                border: InputBorder.none,
              ),
              onChanged: (query) => provider.search(query),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1.0),
              child: provider.isLoading ? const LinearProgressIndicator() : const SizedBox.shrink(),
            ),
          ),

          body: RefreshIndicator(
            onRefresh: () => provider.fetchProducts(auth.token),
            child: () {
              // حالات العرض
              if (provider.isLoading && provider.products.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (provider.errorMessage != null && provider.products.isEmpty) {
                return Center(child: Text("خطأ: ${provider.errorMessage}"));
              }
              if (provider.products.isEmpty) {
                return const Center(child: Text("لا توجد منتجات حالياً."));
              }

              // قائمة المنتجات
              return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80), // مسافة للزر العائم
                  itemCount: provider.products.length,
                  itemBuilder: (ctx, i) {
                    final p = provider.products[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: p.imageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorWidget: (c, u, e) => Container(color: Colors.grey, child: const Icon(Icons.fastfood)),
                          ),
                        ),
                        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(p.formattedPrice, style: TextStyle(color: p.salePrice != null ? Colors.red : Colors.black)),
                        trailing: const Icon(Icons.edit_outlined, color: Colors.blue),
                        onTap: () => _navigateToEditScreen(p),
                      ),
                    );
                  }
              );
            }(),
          ),
        );
      },
    );
  }
}
// =======================================================================
// --- ✨ شاشة جديدة: تعديل المنتج ---
// =======================================================================
// استبدل كلاس EditProductScreen بهذا الكود

class EditProductScreen extends StatefulWidget {
  final FoodItem product;
  // ✅ التصحيح: تغيير النوع إلى MiswakProductsProvider
  final MiswakProductsProvider productProvider;
  final StoreAuthProvider authProvider;

  const EditProductScreen({
    super.key,
    required this.product,
    required this.productProvider,
    required this.authProvider,
  });

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _salePriceController;
  File? _selectedImage;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _priceController = TextEditingController(text: widget.product.price.toStringAsFixed(0));
    _salePriceController = TextEditingController(text: widget.product.salePrice?.toStringAsFixed(0) ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _salePriceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      // 🔥🔥🔥 الإعدادات الذهبية لضغط الصورة 🔥🔥🔥
      imageQuality: 60, // تقليل الجودة إلى 60% (غير ملحوظ للعين ولكن يقلل الحجم 80%)
      maxWidth: 800,    // أقصى عرض 800 بكسل (كافٍ جداً للموبايل)
      maxHeight: 800,   // أقصى ارتفاع 800 بكسل
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final success = await widget.productProvider.updateProduct(
      widget.authProvider.token!,
      widget.product.id,
      _nameController.text,
      _priceController.text,
      _salePriceController.text,
      imageFile: _selectedImage,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم التحديث بنجاح"), backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.productProvider.errorMessage ?? "فشل التحديث"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("تعديل: ${widget.product.name}")),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: _selectedImage != null
                              ? Image.file(_selectedImage!, height: 200, width: double.infinity, fit: BoxFit.cover)
                              : CachedNetworkImage(
                            imageUrl: widget.product.imageUrl,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorWidget: (c, u, e) => Container(color: Colors.grey[300], child: const Icon(Icons.fastfood, size: 80)),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.all(10),
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, color: Colors.blue),
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'اسم المنتج', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'السعر العادي (د.ع)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _salePriceController,
                  decoration: const InputDecoration(labelText: 'سعر الخصم (اختياري)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                  ),
                  child: const Text('حفظ التعديلات'),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(color: Colors.black.withOpacity(0.3), child: const Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }
}
class AddProductScreen extends StatefulWidget {
  // ✅ التصحيح: تغيير النوع إلى MiswakProductsProvider
  final MiswakProductsProvider productProvider;
  final StoreAuthProvider authProvider;

  const AddProductScreen({
    super.key,
    required this.productProvider,
    required this.authProvider,
  });

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _descController = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _salePriceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      // 🔥🔥🔥 الإعدادات الذهبية لضغط الصورة 🔥🔥🔥
      imageQuality: 60, // تقليل الجودة إلى 60% (غير ملحوظ للعين ولكن يقلل الحجم 80%)
      maxWidth: 800,    // أقصى عرض 800 بكسل (كافٍ جداً للموبايل)
      maxHeight: 800,   // أقصى ارتفاع 800 بكسل
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("الرجاء اختيار صورة للمنتج")));
      return;
    }
    setState(() => _isLoading = true);

    final success = await widget.productProvider.addProduct(
      widget.authProvider.token!,
      _nameController.text,
      _priceController.text,
      _salePriceController.text.isEmpty ? null : _salePriceController.text,
      _descController.text,
      _selectedImage,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم إضافة المنتج بنجاح"), backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.productProvider.errorMessage ?? "فشل إضافة المنتج"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("إضافة منتج جديد")),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.file(_selectedImage!, fit: BoxFit.cover),
                    )
                        : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                        SizedBox(height: 10),
                        Text("اضغط لإضافة صورة", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'اسم المنتج', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(labelText: 'السعر (د.ع)', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _salePriceController,
                        decoration: const InputDecoration(labelText: 'سعر الخصم (اختياري)', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: 'وصف المنتج', border: OutlineInputBorder()),
                  maxLines: 3,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                  ),
                  child: const Text('إضافة المنتج'),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(color: Colors.black.withOpacity(0.3), child: const Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }
}
class OrdersListScreen extends StatefulWidget {
  final String status;
  const OrdersListScreen({super.key, required this.status});
  @override
  State<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends State<OrdersListScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<StoreAuthProvider>(context);
    if (auth.token == null) return const Center(child: Text("خطأ: يرجى تسجيل الدخول"));

    // ✅ استخدام MiswakDashboardProvider
    return Consumer<MiswakDashboardProvider>(
      builder: (context, dashboard, child) {
        final orders = dashboard.orders[widget.status];

        if (dashboard.isLoading) return const Center(child: CircularProgressIndicator());
        if (dashboard.error != null) return Center(child: Text("خطأ: ${dashboard.error}"));
        if (orders == null || orders.isEmpty) {
          return Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.inbox, size: 60, color: Colors.grey),
              const SizedBox(height: 10),
              Text('القائمة فارغة (${widget.status})', style: const TextStyle(fontSize: 18, color: Colors.grey)),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: () => dashboard.fetchDashboardData(auth.token!), child: const Text("تحديث"))
            ]),
          );
        }

        return RefreshIndicator(
          onRefresh: () => dashboard.fetchDashboardData(auth.token!),
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return OrderCard(
                key: ValueKey(order.id),
                order: order,
                onStatusChanged: () => dashboard.fetchDashboardData(auth.token!),
                isCompleted: widget.status != 'active',
                pickupCode: dashboard.pickupCodes[order.id],
              );
            },
          ),
        );
      },
    );
  }
}
class RatingsDashboardScreen extends StatefulWidget {
  const RatingsDashboardScreen({super.key});
  @override
  State<RatingsDashboardScreen> createState() => _RatingsDashboardScreenState();
}



















class UnifiedDeliveryOrder {
  final int id;
  final String status;
  final String description;
  final double deliveryFee;
  final String pickupName;
  final String sourceType;
  final String destinationAddress;
  final String pickupLat;
  final String pickupLng;
  final String destLat;
  final String destLng;

  UnifiedDeliveryOrder({
    required this.id,
    required this.status,
    required this.description,
    required this.deliveryFee,
    required this.pickupName,
    required this.sourceType,
    required this.destinationAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.destLat,
    required this.destLng,
  });

  factory UnifiedDeliveryOrder.fromJson(Map<String, dynamic> json) {
    // دالة مساعدة لتحويل أي قيمة رقمية/نصية إلى نص آمن
    String safeString(dynamic val) => val?.toString() ?? '0';

    // دالة مساعدة لتحويل أي قيمة إلى رقم عشري
    double safeDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is double) return val;
      if (val is int) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return UnifiedDeliveryOrder(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      status: json['order_status']?.toString() ?? 'pending',
      description: json['order_description']?.toString() ?? '',
      deliveryFee: safeDouble(json['delivery_fee']),
      pickupName: json['pickup_location_name']?.toString() ?? 'غير محدد',
      sourceType: json['source_type']?.toString() ?? 'general',
      destinationAddress: json['destination_address']?.toString() ?? '',
      pickupLat: safeString(json['pickup_lat']),
      pickupLng: safeString(json['pickup_lng']),
      destLat: safeString(json['destination_lat']),
      destLng: safeString(json['destination_lng']),
    );
  }
}
class TeamLeaderLoginScreen extends StatefulWidget {
  const TeamLeaderLoginScreen({super.key});

  @override
  State<TeamLeaderLoginScreen> createState() => _TeamLeaderLoginScreenState();
}

class _TeamLeaderLoginScreenState extends State<TeamLeaderLoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("الرجاء ملء جميع الحقول")),
      );
      return;
    }

    setState(() => _isLoading = true);

    // استخدام البروفايدر لحفظ الجلسة والرتبة
    final authProvider = Provider.of<StoreAuthProvider>(context, listen: false);

    final success = await authProvider.login(
        _usernameController.text,
        _passwordController.text,
        'leader' // 👈 تحديد الرتبة كتيم ليدر
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      // ✅ نجاح الدخول: إغلاق الشاشة والعودة للصفحة الرئيسية
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("تم الدخول بنجاح! اضغط على أيقونة الداشبورد (البرتقالية) في الأعلى."),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("فشل الدخول: تأكد من اسم المستخدم وكلمة المرور وصلاحيات الحساب."),
            backgroundColor: Colors.red
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E3C72), // لون خلفية مميز للتيم ليدر (أزرق داكن)
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3C72),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.admin_panel_settings, size: 80, color: Colors.white),
              const SizedBox(height: 20),
              const Text(
                "دخول قائد الفريق (Team Leader)",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Tajawal'
                ),
              ),
              const SizedBox(height: 40),

              // حقل اسم المستخدم
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  hintText: "اسم المستخدم",
                  prefixIcon: const Icon(Icons.person),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 15),

              // حقل كلمة المرور
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "كلمة المرور",
                  prefixIcon: const Icon(Icons.lock),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 30),

              // زر تسجيل الدخول
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber, // لون مميز للزر
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text(
                      "تسجيل الدخول",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class TeamLeaderRegionSelectScreen extends StatelessWidget {
  final String token;
  const TeamLeaderRegionSelectScreen({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("حدد منطقة المراقبة")),
      body: FutureBuilder<List<Area>>(
        future: ApiService().getAreas(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData) return const Center(child: Text("فشل تحميل المناطق"));

          // فلترة المحافظات فقط أو عرض الكل حسب رغبتك
          final areas = snapshot.data!;

          return ListView.builder(
            itemCount: areas.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(areas[index].name, style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // ✅ الانتقال للوحة التحكم مع المنطقة المختارة
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RegionDashboardScreen(
                        token: token,
                        areaId: areas[index].id,
                        areaName: areas[index].name,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
class RegionDashboardScreen extends StatefulWidget {
  final String token;
  final int areaId;
  final String areaName;

  const RegionDashboardScreen({
    super.key,
    required this.token,
    required this.areaId,
    required this.areaName
  });

  @override
  State<RegionDashboardScreen> createState() => _RegionDashboardScreenState();
}

class _RegionDashboardScreenState extends State<RegionDashboardScreen> {
  final ApiService _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("لوحة المراقبة", style: TextStyle(fontSize: 16)),
            Text(widget.areaName, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
      body: FutureBuilder<List<UnifiedDeliveryOrder>>(
        future: _apiService.getOrdersByRegion(widget.areaId, widget.token),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("حدث خطأ: ${snapshot.error}"));
          }

          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return const Center(child: Text("لا توجد طلبات نشطة في هذه المنطقة حالياً"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final isMiswak = order.sourceType == 'store' || order.sourceType == 'pharmacy';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Chip(
                            avatar: Icon(isMiswak ? Icons.shopping_basket : Icons.restaurant, size: 16, color: Colors.white),
                            label: Text(isMiswak ? "مسواك/صيدلية" : "مطعم"),
                            backgroundColor: isMiswak ? Colors.purple : Colors.orange,
                            labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          Text(
                            "${NumberFormat('#,###').format(order.deliveryFee)} د.ع",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text("من: ${order.pickupName}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text("إلى: ${order.destinationAddress}", style: TextStyle(color: Colors.grey.shade700)),
                      const Divider(),
                      Text(order.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 10),
                      if (order.pickupLat != "0" && order.destLat != "0")
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.map),
                            label: const Text("عرض المسار على الخريطة"),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => InAppMapScreen(
                                    latitude: double.parse(order.pickupLat),
                                    longitude: double.parse(order.pickupLng),
                                    title: "موقع الاستلام",
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// أضف هذا الكلاس في ملف المسواك/المطعم
// =======================================================================
// --- 4. نقطة الدخول المعدلة (تحتوي Providers المسواك فقط) ---
// =======================================================================

class StoreAuthWrapper extends StatelessWidget {
  const StoreAuthWrapper({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<StoreAuthProvider>(
      builder: (context, auth, child) {
        if (auth.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // إذا المدير مسجل دخول -> لوحة التحكم
        if (auth.isLoggedIn) {
          return const StoreDashboardScreen();
        }

        // إذا زبون أو غير مسجل -> شاشة الموقع
        return const StoreLocationCheckWrapper();
      },
    );
  }
}

// ⚠️ هام: احذف كلاس _StoreAuthWrapperState إذا كان موجوداً أسفل هذا الكلاس، لأنه غير مستخدم ويسبب خطأ.
class _RatingsDashboardScreenState extends State<RatingsDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<StoreAuthProvider>(context, listen: false);

    return Consumer<MiswakDashboardProvider>(
        builder: (context, dashboard, child) {
          final data = dashboard.ratingsDashboard;

          // 1. منطق التحميل
          if (dashboard.isLoading && data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. منطق عرض الرسالة الفارغة أو الخطأ
          if (data == null) {
            return RefreshIndicator(
              onRefresh: () => dashboard.fetchDashboardData(authProvider.token),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  Icon(Icons.star_border, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 20),
                  Text(
                      dashboard.error ?? "لا توجد بيانات تقييم حتى الآن.", // ✅ عرض رسالة الخطأ إذا وجدت
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 18)
                  ),
                  const SizedBox(height: 20),
                  Center(child: ElevatedButton(onPressed: () => dashboard.fetchDashboardData(authProvider.token), child: const Text("تحديث البيانات")))
                ],
              ),
            );
          }

          // 3. عرض البيانات الرئيسية
          return RefreshIndicator(
            onRefresh: () => dashboard.fetchDashboardData(authProvider.token),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _buildRatingsSummaryCard(data),
                const SizedBox(height: 24),
                const Text("آخر التقييمات", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                if (data.recentReviews.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text("لا توجد تعليقات مكتوبة.", style: TextStyle(color: Colors.grey))))
                else
                  ...data.recentReviews.map((review) => ReviewCard(review: review)),
              ],
            ),
          );
        }
    );
  }

  Widget _buildRatingsSummaryCard(RestaurantRatingsDashboard data) {
    return Card(
      elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          Column(children: [
            Text(data.averageRating.toStringAsFixed(1), style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.amber)),
            RatingBarIndicator(rating: data.averageRating, itemBuilder: (context, index) => const Icon(Icons.star, color: Colors.amber), itemCount: 5, itemSize: 25.0),
            const SizedBox(height: 5),
            const Text("المعدل العام", style: TextStyle(color: Colors.grey)),
          ]),
          Column(children: [
            Text(data.totalReviews.toString(), style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
            const SizedBox(height: 10),
            const Text("إجمالي التقييمات", style: TextStyle(color: Colors.grey)),
          ]),
        ]),
      ),
    );
  }
}
class StoreDebugScreen extends StatefulWidget {
  const StoreDebugScreen({super.key});

  @override
  State<StoreDebugScreen> createState() => _StoreDebugScreenState();
}

class _StoreDebugScreenState extends State<StoreDebugScreen> {
  String _logs = "اضغط على الأزرار لبدء الفحص...\n";
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  void _addLog(String message) {
    setState(() {
      _logs += "\n$message";
    });
    print(message);
  }

  Future<void> _checkTokenAndAuth() async {
    setState(() => _isLoading = true);
    _addLog("--- 1. فحص المصادقة ---");

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('store_jwt_token');
    final role = prefs.getString('store_user_role');

    if (token != null) {
      _addLog("✅ التوكن موجود: ${token.substring(0, 10)}...");
      _addLog("👤 الرتبة المسجلة: $role");

      // فحص إعدادات المطعم/المسواك
      try {
        _addLog("🔄 جاري جلب إعدادات المتجر...");
        final settings = await _apiService.getRestaurantSettings(token);
        _addLog("✅ الاتصال نجح! بيانات المتجر: $settings");
      } catch (e) {
        _addLog("❌ فشل الاتصال بإعدادات المتجر: $e");
      }

    } else {
      _addLog("❌ التوكن غير موجود! (يجب تسجيل الدخول)");
    }
    setState(() => _isLoading = false);
  }

  Future<void> _testOrdersApi() async {
    setState(() => _isLoading = true);
    _addLog("\n--- 2. فحص طلبات المتجر (Orders) ---");

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('store_jwt_token');

    if (token == null) {
      _addLog("❌ لا يمكن الفحص بدون توكن.");
      setState(() => _isLoading = false);
      return;
    }

    try {
      _addLog("📡 جاري طلب البيانات من: /get-orders?status=active");
      final orders = await _apiService.getRestaurantOrders(status: 'active', token: token);

      if (orders.isEmpty) {
        _addLog("⚠️ القائمة فارغة (0 طلبات). هذا يعني أن الاتصال نجح لكن لا توجد طلبات.");
      } else {
        _addLog("✅ تم جلب ${orders.length} طلب بنجاح!");
        _addLog("أول طلب: ID=${orders[0].id}, Status=${orders[0].status}");
      }
    } catch (e) {
      _addLog("❌ خطأ أثناء جلب الطلبات: $e");
    }
    setState(() => _isLoading = false);
  }

  Future<void> _testProductsApi() async {
    setState(() => _isLoading = true);
    _addLog("\n--- 3. فحص المنتجات (Products) ---");

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('store_jwt_token');

    if (token == null) {
      _addLog("❌ لا يمكن الفحص بدون توكن.");
      setState(() => _isLoading = false);
      return;
    }

    try {
      _addLog("📡 جاري طلب المنتجات...");
      final products = await _apiService.getMyRestaurantProducts(token);

      if (products.isEmpty) {
        _addLog("⚠️ القائمة فارغة (0 منتجات).");
      } else {
        _addLog("✅ تم جلب ${products.length} منتج بنجاح!");
        _addLog("أول منتج: ${products[0].name}");
      }
    } catch (e) {
      _addLog("❌ خطأ أثناء جلب المنتجات: $e");
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🛠️ فحص نظام المسواك")),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.grey.shade200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(onPressed: _isLoading ? null : _checkTokenAndAuth, child: const Text("فحص الدخول")),
                ElevatedButton(onPressed: _isLoading ? null : _testOrdersApi, child: const Text("فحص الطلبات")),
                ElevatedButton(onPressed: _isLoading ? null : _testProductsApi, child: const Text("فحص المنتجات")),
              ],
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              color: Colors.black,
              child: SingleChildScrollView(
                child: Text(
                  _logs,
                  style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
