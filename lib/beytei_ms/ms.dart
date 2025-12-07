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
import '../taxi/cash.dart';

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
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
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





class StoreAuthProvider with ChangeNotifier {
  String? _token;
  String? _userRole;
  bool _isLoading = true;

  String? get token => _token;
  String? get userRole => _userRole;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _token != null;

  StoreAuthProvider() {
    print("🔍 DEBUG: [AuthProvider] Constructor Initialized");
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    print("🔍 DEBUG: [AuthProvider] Checking SharedPreferences for saved token...");
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('store_jwt_token');
    _userRole = prefs.getString('store_user_role');
    _isLoading = false;

    print("🔍 DEBUG: [AuthProvider] Initial Check Result -> Token found: ${_token != null}, Role: $_userRole");
    notifyListeners();
  }

  // ✅ دالة تسجيل الدخول مع تتبع الأخطاء
  Future<bool> login(String username, String password, String role, {String? lat, String? lng}) async {
    _isLoading = true;
    notifyListeners();

    print("🔍 DEBUG: [AuthProvider] 1. Starting Login Process for user: $username");

    final authService = AuthService();
    // محاولة الاتصال بالسيرفر
    final token = await authService.loginRestaurantOwner(username, password);

    print("🔍 DEBUG: [AuthProvider] 2. API Response Received. Token is: ${token != null ? 'VALID (Not Null)' : 'NULL'}");

    if (token != null) {
      _token = token;
      _userRole = role;

      // حفظ البيانات
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('store_jwt_token', token);
      await prefs.setString('store_user_role', role);

      print("🔍 DEBUG: [AuthProvider] 3. Token & Role saved to SharedPreferences successfully.");

      // تحديث الموقع إذا تم تمريره
      if (lat != null && lng != null) {
        print("🔍 DEBUG: [AuthProvider] 4. Updating Location...");
        final apiService = ApiService();
        await apiService.updateMyLocation(token, lat, lng);
      }

      // تسجيل التوكن للإشعارات
      await authService.registerDeviceToken();

      _isLoading = false;

      print("🔍 DEBUG: [AuthProvider] 5. Login Successful. Current State -> isLoggedIn: $isLoggedIn. Calling notifyListeners()...");
      // هذه اللحظة الحاسمة التي يجب أن يستجيب لها الـ Wrapper
      notifyListeners();
      return true;
    }

    print("🔍 DEBUG: [AuthProvider] X. Login Failed (Invalid Credentials or Server Error).");
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout(BuildContext context) async {
    print("🔍 DEBUG: [AuthProvider] Logging out...");
    final authService = AuthService();
    await authService.logout();

    _token = null;
    _userRole = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('store_jwt_token');
    await prefs.remove('store_user_role');

    if (context.mounted) {
      // تنظيف البيانات عند الخروج
      try {
        Provider.of<StoreCustomerProvider>(context, listen: false).clearData();
        Provider.of<DashboardProvider>(context, listen: false).stopAutoRefresh();
      } catch (e) {
        print("🔍 DEBUG: Error clearing data providers: $e");
      }
    }

    print("🔍 DEBUG: [AuthProvider] Logged out completely.");
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
class DashboardProvider with ChangeNotifier {
  Map<String, List<Order>> _orders = {
    'active': [],
    'completed': []
  };
  RestaurantRatingsDashboard? _ratingsDashboard;
  Map<int, String> _pickupCodes = {};

  bool _isLoading = false;
  String? _error; // لتخزين رسالة الخطأ وعرضها بدلاً من الشاشة البيضاء

  Map<String, List<Order>> get orders => _orders;
  RestaurantRatingsDashboard? get ratingsDashboard => _ratingsDashboard;
  Map<int, String> get pickupCodes => _pickupCodes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Timer? _timer;

  void startAutoRefresh(String token) {
    _timer?.cancel();
    fetchDashboardData(token, silent: false);
    // تحديث كل 30 ثانية
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      fetchDashboardData(token, silent: true);
    });
  }

  void stopAutoRefresh() {
    _timer?.cancel();
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

      // 1. جلب الطلبات النشطة والمكتملة
      final activeFromServer = await api.getRestaurantOrders(status: 'active', token: token);
      final completedFromServer = await api.getRestaurantOrders(status: 'completed', token: token);

      List<Order> allOrders = [...activeFromServer, ...completedFromServer];

      // إزالة التكرار
      final ids = <int>{};
      allOrders.retainWhere((x) => ids.add(x.id));

      List<Order> finalActive = [];
      List<Order> finalCompleted = [];

      // القائمة السوداء للحالات المؤرشفة
      final List<String> archiveStatuses = [
        'completed', 'cancelled', 'refunded', 'failed', 'trash'
      ];

      for (var order in allOrders) {
        if (!archiveStatuses.contains(order.status)) {
          finalActive.add(order);
        } else {
          finalCompleted.add(order);
        }
      }

      // ترتيب الطلبات (الأحدث أولاً)
      finalActive.sort((a, b) => b.dateCreated.compareTo(a.dateCreated));
      finalCompleted.sort((a, b) => b.dateCreated.compareTo(a.dateCreated));

      _orders['active'] = finalActive;
      _orders['completed'] = finalCompleted;

      // 2. جلب التقييمات
      try {
        final ratings = await api.getDashboardRatings(token);
        _ratingsDashboard = ratings;
      } catch (e) {
        print("Warning: Failed to fetch ratings, but orders loaded.");
      }

      _error = null; // نجاح
    } catch (e) {
      print("Error fetching dashboard: $e");
      _error = "فشل تحميل البيانات. تأكد من اتصالك بالإنترنت.";
      // لا نجعل القوائم فارغة إذا كان هناك بيانات قديمة، نحافظ عليها
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}class RestaurantSettingsProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isRestaurantOpen = true;
  String _openTime = '09:00';
  String _closeTime = '22:00';
  bool _isLoading = false;

  bool get isRestaurantOpen => _isRestaurantOpen;
  String get openTime => _openTime;
  String get closeTime => _closeTime;
  bool get isLoading => _isLoading;

  // عند تسجيل دخول المدير، يجب جلب هذه البيانات وحفظ الإحداثيات للأتمتة
  Future<void> fetchSettings(String? token) async {
    if (token == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      // جلب الإعدادات من السيرفر
      final settings = await _apiService.getRestaurantSettings(token);

      _isRestaurantOpen = settings['is_open'] ?? true;
      _openTime = settings['auto_open_time'] ?? '09:00';
      _closeTime = settings['auto_close_time'] ?? '22:00';

      // ✨✨✨ الإصلاح الحاسم للأتمتة ✨✨✨
      // حفظ اسم المطعم وإحداثياته في الذاكرة لكي تستخدمها الأتمتة
      if (settings['restaurant_info'] != null) {
        final prefs = await SharedPreferences.getInstance();
        final info = settings['restaurant_info'];

        if (info['latitude'] != null && info['longitude'] != null) {
          await prefs.setDouble('restaurant_lat', double.tryParse(info['latitude'].toString()) ?? 0.0);
          await prefs.setDouble('restaurant_lng', double.tryParse(info['longitude'].toString()) ?? 0.0);
          print("✅ تم تحديث موقع  في الذاكرة: ${info['latitude']}, ${info['longitude']}");
        }

        if (info['name'] != null) {
          await prefs.setString('restaurant_name', info['name'].toString());
        }
      }
      // ✨✨✨ نهاية الإصلاح ✨✨✨

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
      if (success) {
        _isRestaurantOpen = isOpen;
      }
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

  // ✨ [جديد] حقول لاستقبال موقع المطعم مع المنتج
  final double restaurantLat;
  final double restaurantLng;

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
    // ✨ تهيئة القيم
    this.restaurantLat = 0.0,
    this.restaurantLng = 0.0,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    // دالة مساعدة لقراءة الأرقام بأمان
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

    // ✨ استخراج الإحداثيات بدقة من الميتا داتا
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
      // ✨ تمرير الإحداثيات المستخرجة
      restaurantLat: rLat,
      restaurantLng: rLng,
    );
  }

  double get displayPrice => salePrice != null && salePrice! >= 0 ? salePrice! : price;

  String get formattedPrice {
    final format = NumberFormat('#,###', 'ar_IQ');
    return '${format.format(displayPrice)} د.ع';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'quantity': quantity,
    'categoryId': categoryId,
    // يمكنك إضافة الإحداثيات هنا إذا كنت تريد حفظ السلة محلياً
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
class DeliveryProvider with ChangeNotifier {
  // ✨ إعدادات ثابتة (لتجنب أخطاء الخادم)
  final DeliveryConfig _defaultConfig = DeliveryConfig(
    baseFee: 1000.0,       // السعر الأساسي
    feePerKm: 250.0,        // سعر الكيلومتر
    maxDistanceKm: 25.0,    // أقصى مسافة
  );

  DeliveryConfig? _config;

  bool get isLoading => false;
  bool get hasError => false;
  String? get errorMessage => null;

  DeliveryConfig? get config => _config;

  DeliveryProvider() {
    _config = _defaultConfig;
  }

  Future<bool> fetchConfig() async {
    _config = _defaultConfig;
    return true;
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
    sound: RawResourceAndroidNotificationSound('woo_sound'),
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

class OrderHistoryService {
  static const _key = 'order_history';
  Future<void> saveOrder(Order order) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Order> orders = await getOrders();
    orders.removeWhere((o) => o.id == order.id);
    orders.insert(0, order);
    final String encodedData = json.encode(orders.map<Map<String, dynamic>>((o) => o.toJson()).toList());
    await prefs.setString(_key, encodedData);
  }

  Future<List<Order>> getOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final String? ordersString = prefs.getString(_key);
    if (ordersString != null) {
      final List<dynamic> decodedData = json.decode(ordersString);
      return decodedData.map<Order>((item) => Order.fromJson(item)).toList();
    }
    return [];
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
  double get totalPrice => _items.fold(0.0, (sum, item) => sum + (item.displayPrice * item.quantity));
  String? _appliedCoupon;
  double _discountPercentage = 0.0;
  double _discountAmount = 0.0;
  String _discountType = '';

// ✨ NEW: تتبع حالة المروج والخصم
  String? _promoterCode;
  int _usageCount = 0; // عدد مرات الاستخدام المكتملة
  double _loyaltyDiscountPercentage = 0.0;

  String? get appliedCoupon => _appliedCoupon; // الحفاظ على Getter القديم
  String? get promoterCode => _promoterCode;
  int get usageCount => _usageCount;

// ✨ Getter معدل لحساب الخصم الكلي
  double get totalDiscountAmount {
    double couponDiscount = 0.0;
    // حساب خصم الكوبون العادي
    if (_discountType == 'fixed_cart') {
      couponDiscount = _discountAmount;
    } else if (_discountType == 'percent') {
      couponDiscount = totalPrice * (_discountPercentage / 100);
    }

    double loyaltyDiscount = totalPrice * (_loyaltyDiscountPercentage / 100);

    // نستخدم أكبر خصم متاح (إما خصم الكوبون أو خصم الولاء 50%)
    return max(couponDiscount, loyaltyDiscount);
  }

  double get discountedTotal {
    return (totalPrice - totalDiscountAmount).clamp(0, double.infinity);
  }

// ✨ وظيفة لقراءة عدد الاستخدامات من الذاكرة المحلية
  Future<int> _loadUsageCount(String code) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('promoter_usage_$code') ?? 0;
  }

// ✨ وظيفة لتسجيل الاستخدام بعد إتمام الطلب بنجاح (يجب استدعاؤها بعد إنشاء الطلب)
  Future<void> _recordSuccessfulOrder() async {
    final prefs = await SharedPreferences.getInstance();
    if (_promoterCode != null) {
      int currentCount = await _loadUsageCount(_promoterCode!);
      if (currentCount < 3) {
        // زيادة العدد بعد طلب ناجح
        await prefs.setInt('promoter_usage_$_promoterCode', currentCount + 1);
      } else {
        // إعادة تعيين العداد إلى 0 بعد استخدام خصم 50%
        await prefs.setInt('promoter_usage_$_promoterCode', 0);
      }
    }
  }

// ✨ دالة مساعدة لحساب رسالة التحدي الحالية (مطلوبة للـ Widget الجديد)
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


  Future<Map<String, dynamic>> applyCoupon(String code) async {
    final result = await ApiService().validateCoupon(code);

    if (result['is_promoter'] == true) {
      _promoterCode = code.toUpperCase();

      // جلب عدد الاستخدامات وحساب الخصم
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
      // منطق كوبون ووكومرس العادي
      _appliedCoupon = code.toUpperCase();
      _discountType = result['discount_type'];
      _discountAmount = double.tryParse(result['amount'].toString()) ?? 0.0;
      if (_discountType == 'percent') _discountPercentage = _discountAmount;

      // تصفير حقول الولاء عند استخدام كوبون عادي
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

    // تصفير حقول الولاء
    _promoterCode = null;
    _loyaltyDiscountPercentage = 0.0;

    notifyListeners();
  }

  // ✨ --- [ هذا هو الإصلاح ] --- ✨
  // (استبدل الدالة القديمة بهذه)
  void addToCart(FoodItem foodItem, BuildContext context) {
    // 1. التحقق من توفر المنتج
    if (!foodItem.isDeliverable) {
      _showItemUnavailableDialog(context, foodItem);
      return;
    }

    final existingIndex = _items.indexWhere((item) => item.id == foodItem.id);
    if (existingIndex != -1) {
      _items[existingIndex].quantity++;
    } else {
      // 2. إضافة المنتج للسلة مع نسخ الإحداثيات
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
        // ✅✅✅ هنا الإصلاح: نقل الإحداثيات من المنتج الأصلي إلى السلة ✅✅✅
        restaurantLat: foodItem.restaurantLat,
        restaurantLng: foodItem.restaurantLng,
      ));
    }
    notifyListeners();
    _showAddToCartDialog(context, foodItem);
  }
  // ✨ --- [ أضف هذه الدالة المساعدة الجديدة ] ---
  void _showItemUnavailableDialog(BuildContext context, FoodItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("عذراً، المنتج غير متاح"),
        content: Text("لا يمكن إضافة '${item.name}' إلى السلة لأن  الخاص به مغلق حالياً."),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("حسناً")),
        ],
      ),
    );
  }
  // --- [ نهاية الإضافة ] ---

  void incrementQuantity(FoodItem foodItem) {
    final itemIndex = _items.indexWhere((item) => item.id == foodItem.id);
    if (itemIndex != -1) {
      _items[itemIndex].quantity++;
      notifyListeners();
    }
  }

  void decrementQuantity(FoodItem foodItem) {
    final itemIndex = _items.indexWhere((item) => item.id == foodItem.id);
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

  void _showAddToCartDialog(BuildContext context, FoodItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("تمت الإضافة إلى السلة"),
        content: Text("تمت إضافة '${item.name}' بنجاح."),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("مواصلة التسوق")),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Provider.of<NavigationProvider>(context, listen: false).changeTab(3);
            },
            child: const Text("الذهاب للسلة"),
          ),
        ],
      ),
    );
  }
}
// =======================================================================
// --- API SERVICE (المعدل والنهائي) ---
// =======================================================================
class ApiService {
  final String _authString = 'Basic ${base64Encode(utf8.encode('$CONSUMER_KEY:$CONSUMER_SECRET'))}';
  final CacheService _cacheService = CacheService();

  // =================================================================
  // 1. Helper Methods (المساعدات)
  // =================================================================

  // 🔥 دالة التنفيذ الذكي (Exponential Backoff)
  Future<T> _executeWithRetry<T>(Future<T> Function() action) async {
    int attempts = 0;
    while (attempts < 3) {
      try {
        return await action().timeout(API_TIMEOUT);
      } catch (e) {
        attempts++;
        String errorString = e.toString();

        // 🛑 توقف فوراً في حالة الحظر
        if (errorString.contains('403') || errorString.contains('429')) {
          print("⛔ تم إيقاف المحاولات لتجنب الحظر: $errorString");
          rethrow;
        }

        if (attempts >= 3) rethrow;

        // ⏳ انتظار تصاعدي
        int delaySeconds = pow(2, attempts).toInt();
        print("⚠️ فشل الطلب (محاولة $attempts)، انتظار $delaySeconds ثواني...");
        await Future.delayed(Duration(seconds: delaySeconds));
      }
    }
    throw Exception('Failed after multiple retries');
  }

  // =================================================================
  // 2. Customer & Store Caching Methods (للتخزين الدائم)
  // =================================================================
  // هذه الدوال تعيد النص الخام (String) ليتم حفظه في الهاتف

  // أ) جلب القائمة (مطاعم أو مسواك)
  Future<String> getRawRestaurants(int areaId) async {
    const fields = 'id,name,image,count,meta_data';
    // per_page=100 لضمان جلب الكل وحفظه
    final url = '$BEYTEI_URL/wp-json/wc/v3/products/categories?parent=0&per_page=100&_fields=$fields&area_id=$areaId';

    return _executeWithRetry(() async {
      final response = await http.get(Uri.parse(url), headers: {'Authorization': _authString});
      if (response.statusCode == 200) return response.body;
      throw Exception('Failed to load raw restaurants');
    });
  }

  // ب) جلب IDs المتاحة للتوصيل
  Future<String> getRawDeliverableIds(int areaId) async {
    final url = '$BEYTEI_URL/wp-json/restaurant-app/v1/restaurants-by-area?area_id=$areaId';
    return _executeWithRetry(() async {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) return response.body;
      throw Exception('Failed to load raw deliverable IDs');
    });
  }

  // ج) جلب المنيو/المنتجات
  Future<String> getRawMenu(int parentId) async {
    const fields = 'id,name,regular_price,sale_price,images,categories,short_description,average_rating,rating_count,meta_data';
    final url = '$BEYTEI_URL/wp-json/wc/v3/products?category=$parentId&per_page=100&_fields=$fields';

    return _executeWithRetry(() async {
      final response = await http.get(Uri.parse(url), headers: {'Authorization': _authString});
      if (response.statusCode == 200) return response.body;
      throw Exception('Failed to load raw menu');
    });
  }

  // =================================================================
  // 3. General Getters (للاستخدام المباشر بدون كاش معقد)
  // =================================================================

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
    // نستخدم النسخة الخام ونحولها هنا للتوافق مع الأكواد القديمة
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

  // البحث (لا يحتاج كاش دائم)
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
  // 4. Manager / Owner Methods (دوال المدير)
  // =================================================================

  Future<bool> createProduct(String token, String name, String price, String? salePrice, String? description, File? imageFile) async {
    return _executeWithRetry(() async {
      String? imageBase64;
      if (imageFile != null) {
        List<int> imageBytes = await imageFile.readAsBytes();
        imageBase64 = base64Encode(imageBytes);
      }

      final response = await http.post(
        Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/create-product'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'regular_price': price,
          'sale_price': salePrice,
          'description': description,
          'image_base64': imageBase64,
        }),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    });
  }

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
      throw Exception('Failed to load restaurant products');
    });
  }

  Future<List<Order>> getRestaurantOrders({required String status, required String token}) async {
    return _executeWithRetry(() async {
      final uri = Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/get-orders?status=$status');
      final response = await http.get(uri, headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'});
      if (response.statusCode == 200) {
        return (json.decode(response.body) as List).map((json) => Order.fromJson(json)).toList();
      }
      throw Exception('Failed to load orders');
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
      throw Exception('Failed to load dashboard ratings');
    });
  }

  // إعدادات المطعم/المتجر
  Future<Map<String, dynamic>> getRestaurantSettings(String token) async {
    return _executeWithRetry(() async {
      final response = await http.get(
        Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/get-settings'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to load settings');
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
  // 5. Delivery & Order Submission (التوصيل والطلبات)
  // =================================================================

  Future<List<UnifiedDeliveryOrder>> getOrdersByRegion(int areaId, String token) async {
    final url = '$BEYTEI_URL/wp-json/taxi/v2/delivery/available';
    return _executeWithRetry(() async {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        var ordersList = data['orders'] ?? data['data'];
        if (data is List) ordersList = data;

        if (ordersList != null && ordersList is List) {
          return ordersList.map<UnifiedDeliveryOrder>((json) => UnifiedDeliveryOrder.fromJson(json)).toList();
        }
        return [];
      }
      throw Exception('Failed to load delivery orders');
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

  Future<Order?> submitOrder({
    required String name, required String phone, required String address,
    required List<FoodItem> cartItems, String? couponCode,
    geolocator.Position? position,
    double? deliveryFee,
  }) async {
    List<Map<String, dynamic>> couponLines = couponCode != null && couponCode.isNotEmpty ? [{"code": couponCode}] : [];
    List<Map<String, dynamic>> shippingLines = deliveryFee != null
        ? [{"method_id": "flat_rate", "method_title": "توصيل", "total": deliveryFee.toString()}]
        : [];

    String? fcmToken = await FirebaseMessaging.instance.getToken();

    Map<String, dynamic> bodyPayload = {
      "payment_method": "cod", "payment_method_title": "الدفع عند الاستلام",
      "billing": {"first_name": name, "last_name":".", "phone": phone, "address_1": address, "country": "IQ", "city": "Default", "postcode":"10001", "email": "customer@example.com"},
      "shipping": {"first_name": name, "last_name":".", "address_1": address, "country": "IQ", "city": "Default", "postcode":"10001"},
      "line_items": cartItems.map((item) => {"product_id": item.id, "quantity": item.quantity}).toList(),
      "coupon_lines": couponLines,
      "shipping_lines": shippingLines,
      "meta_data": [
        if (fcmToken != null) {"key": "_customer_fcm_token", "value": fcmToken},
        if (position != null) {"key": "_customer_destination_lat", "value": position.latitude.toString()},
        if (position != null) {"key": "_customer_destination_lng", "value": position.longitude.toString()}
      ],
    };

    final response = await _executeWithRetry(() => http.post(
        Uri.parse('$BEYTEI_URL/wp-json/wc/v3/orders'),
        headers: {'Authorization': _authString, 'Content-Type': 'application/json'},
        body: json.encode(bodyPayload)
    ));

    if (response.statusCode == 201) {
      final createdOrder = Order.fromJson(json.decode(response.body));
      await OrderHistoryService().saveOrder(createdOrder);
      return createdOrder;
    } else {
      throw Exception('Failed to submit order: ${response.body}');
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

  Future<void> _updateStatus(String status) async {
    setState(() => _isUpdating = true);
    try {
      final success = await _apiService.updateOrderStatus(widget.order.id, status);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم تحديث حالة الطلب #${widget.order.id} بنجاح'), backgroundColor: Colors.green));
          widget.onStatusChanged();
        } else {
          throw Exception('Failed to update status from API');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: لم يتم تحديث حالة الطلب. $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('لا يمكن إجراء الاتصال بالرقم: $phoneNumber'), backgroundColor: Colors.red));
    }
  }

  Future<void> _launchMaps(BuildContext context, String? lat, String? lng) async {
    if (lat == null || lng == null || lat.isEmpty || lng.isEmpty || lat == "0" || lng == "0") {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الإحداثيات غير متوفرة')));
      return;
    }
    try {
      final double latitude = double.parse(lat);
      final double longitude = double.parse(lng);
      if (context.mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => InAppMapScreen(latitude: latitude, longitude: longitude, title: 'موقع الزبون')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خطأ في الإحداثيات')));
    }
  }

  void _showDeliveryRequestDialog(BuildContext cardContext, Order order) {
    final feeController = TextEditingController();
    final pickupNameController = TextEditingController();
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final destAddressController = TextEditingController(text: order.address);

    final orderDetails = order.lineItems.map((item) => '- ${item.quantity} x ${item.name}').join('\n');
    notesController.text = 'توصيل طلب  رقم #${order.id}\nالمحتويات:\n$orderDetails';

    SharedPreferences.getInstance().then((prefs) {
      pickupNameController.text = prefs.getString('restaurant_name') ?? '';
    });

    showDialog(
      context: cardContext,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            bool isSubmitting = false;
            return AlertDialog(
              title: const Text('طلب توصيل (تكسي بيتي)'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("1. تفاصيل نقطة الاستلام:", style: TextStyle(fontWeight: FontWeight.bold)),
                      TextFormField(
                        controller: pickupNameController,
                        decoration: const InputDecoration(labelText: 'اسم /الفرع'),
                        validator: (value) => value == null || value.isEmpty ? 'الحقل مطلوب' : null,
                      ),
                      const SizedBox(height: 16),
                      const Text("2. تفاصيل نقطة التوصيل والسعر:", style: TextStyle(fontWeight: FontWeight.bold)),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                        child: Text("الزبون: ${order.customerName}", style: const TextStyle(color: Colors.black54)),
                      ),
                      TextFormField(
                        controller: destAddressController,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'عنوان توصيل الزبون'),
                        validator: (value) => value == null || value.isEmpty ? 'الحقل مطلوب' : null,
                      ),
                      if (order.destinationLat != null && order.destinationLat!.isNotEmpty)
                        TextButton.icon(
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('عرض موقع الزبون الأصلي (إن وجد)'),
                          onPressed: () => _launchMaps(cardContext, order.destinationLat, order.destinationLng),
                        ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: feeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'أجرة التوصيل', hintText: 'مثال: 3000', suffixText: 'د.ع'),
                        validator: (value) => (value == null || value.isEmpty) ? 'مطلوب' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: notesController,
                        maxLines: 4,
                        decoration: const InputDecoration(labelText: 'ملاحظات للسائق', border: OutlineInputBorder()),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      setDialogState(() => isSubmitting = true);
                      try {
                        final prefs = await SharedPreferences.getInstance();
                        final restaurantToken = prefs.getString('jwt_token');
                        final double? restaurantLat = prefs.getDouble('restaurant_lat');
                        final double? restaurantLng = prefs.getDouble('restaurant_lng');

                        if (restaurantToken == null || restaurantLat == null || restaurantLng == null) throw Exception("بيانات  ناقصة");

                        final result = await _apiService.createUnifiedDeliveryRequest(
                          token: restaurantToken,
                          sourceType: 'restaurant',
                          sourceOrderId: order.id.toString(),
                          pickupName: pickupNameController.text,
                          pickupLat: restaurantLat,
                          pickupLng: restaurantLng,
                          destinationAddress: destAddressController.text,
                          destinationLat: double.tryParse(order.destinationLat ?? ''),
                          destinationLng: double.tryParse(order.destinationLng ?? ''),
                          deliveryFee: feeController.text,
                          orderDescription: notesController.text,
                          endCustomerPhone: order.phone,
                        );

                        if (mounted) {
                          final code = result['pickup_code']?.toString();
                          if (code != null) {
                            Provider.of<DashboardProvider>(cardContext, listen: false).setPickupCode(order.id, code);
                          }
                          await _updateStatus('out-for-delivery');
                          Navigator.of(dialogContext).pop();
                          ScaffoldMessenger.of(cardContext).showSnackBar(SnackBar(content: Text(result['message'] ?? 'تم الطلب'), backgroundColor: Colors.green));
                        }
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(cardContext).showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
                      } finally {
                        if(mounted) setDialogState(() => isSubmitting = false);
                      }
                    }
                  },
                  child: isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('إرسال'),
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
    final formatter = DateFormat('yyyy-MM-dd – hh:mm a', 'ar');
    final formattedDate = formatter.format(widget.order.dateCreated.toLocal());
    final totalFormatted = NumberFormat('#,###', 'ar_IQ').format(double.tryParse(widget.order.total) ?? 0);
    final bool isDeliveryRequested = widget.order.status == 'out-for-delivery';

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          Container(
            color: Colors.teal.withOpacity(0.05),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('طلب #${widget.order.id}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).primaryColor)),
              Text(formattedDate, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(Icons.person, 'الزبون:', widget.order.customerName),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.location_on, 'العنوان:', widget.order.address),

                // ✨ زر الخريطة (الإصلاح)
                if (widget.order.destinationLat != null &&
                    widget.order.destinationLat!.isNotEmpty &&
                    widget.order.destinationLat != "0" &&
                    widget.order.destinationLat != "0.0")
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Center(
                      child: TextButton.icon(
                        icon: Icon(Icons.map_outlined, color: Theme.of(context).primaryColor),
                        label: Text(
                          'عرض موقع الزبون على الخريطة',
                          style: TextStyle(color: Theme.of(context).primaryColor, decoration: TextDecoration.underline),
                        ),
                        onPressed: () => _launchMaps(context, widget.order.destinationLat, widget.order.destinationLng),
                      ),
                    ),
                  ),

                const SizedBox(height: 8),
                _buildInfoRow(Icons.phone, 'الهاتف:', widget.order.phone),
                const Divider(height: 25),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$totalFormatted د.ع', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ElevatedButton.icon(
                      onPressed: () => _makePhoneCall(widget.order.phone),
                      icon: const Icon(Icons.call, size: 18),
                      label: const Text('اتصال بالزبون'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    ),
                  ],
                ),

                // ✨ الرسالة المطلوبة
                if (isDeliveryRequested) ...[
                  const SizedBox(height: 15),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.shade200)
                    ),
                    child: Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delivery_dining, color: Colors.blue),
                            SizedBox(width: 8),
                            Text("تم طلب المندوب وهو في الطريق إليك", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                          ],
                        ),
                        if(widget.pickupCode != null) ...[
                          const SizedBox(height: 5),
                          Text("رمز التسليم: ${widget.pickupCode}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 2)),
                        ]
                      ],
                    ),
                  ),
                ],

                if (!widget.isCompleted && !isDeliveryRequested) ...[
                  const Divider(height: 25),
                  Row(
                    children: [
                      Expanded(child: OutlinedButton(onPressed: () => _updateStatus('cancelled'), style: OutlinedButton.styleFrom(foregroundColor: Colors.red), child: const Text('رفض'))),
                      const SizedBox(width: 10),
                      Expanded(child: ElevatedButton(onPressed: () => _showDeliveryRequestDialog(context, widget.order), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white), child: const Text('طلب تكسي (يدوي)'))),
                    ],
                  )
                ],
                const SizedBox(height: 10),
                const Text('التفاصيل:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...widget.order.lineItems.map((item) => Text('- ${item.quantity} x ${item.name}')).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(children: [Icon(icon, size: 18, color: Colors.grey), const SizedBox(width: 5), Text(label, style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(width: 5), Expanded(child: Text(value))]);
  }
}
class OrderHistoryCard extends StatelessWidget {
  final Order order;
  const OrderHistoryCard({super.key, required this.order});

  // ✨ --- [ الدالة المحدثة التي تفتح الخريطة داخلياً ] ---
  Future<void> _launchMaps(BuildContext context, String? lat, String? lng) async {
    // 1. التحقق من أن الإحداثيات موجودة
    if (lat == null || lng == null || lat.isEmpty || lng.isEmpty || lat == "0" || lng == "0") {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الإحداثيات غير متوفرة لهذا الطلب')),
        );
      }
      return;
    }

    try {
      // 2. تحويل النصوص إلى أرقام
      final double latitude = double.parse(lat);
      final double longitude = double.parse(lng);

      // 3. ✨ الانتقال إلى شاشة الخريطة الداخلية
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InAppMapScreen(
              latitude: latitude,
              longitude: longitude,
              title: 'موقعي على الخريطة', // عنوان مخصص للشاشة
            ),
          ),
        );
      }
    } catch (e) {
      // 4. في حال كانت الإحداثيات غير صالحة
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطأ في تنسيق الإحداثيات.')),
        );
      }
    }
  }
  // --- [نهاية الدالة] ---


  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('yyyy-MM-dd – hh:mm a', 'ar');
    final formattedDate = formatter.format(order.dateCreated.toLocal());
    final totalFormatted = NumberFormat('#,###', 'ar_IQ').format(double.tryParse(order.total) ?? 0);
    final statusInfo = order.statusDisplay;

    // التحقق من وجود إحداثيات
    final bool hasCoordinates = (order.destinationLat != null && order.destinationLat!.isNotEmpty);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('طلب #${order.id}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).primaryColor)),
                Text(formattedDate, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
            const Divider(height: 24),
            ...order.lineItems.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(children: [
                Text('• ${item.quantity} ×', style: TextStyle(color: Colors.grey.shade700)),
                const SizedBox(width: 8),
                Expanded(child: Text(item.name)),
              ]),
            )).toList(),

            // ✨ --- [ هذا هو الجزء الذي تم تعديله ] ---
            const Divider(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_outlined, color: Colors.grey.shade600, size: 20),
                const SizedBox(width: 8),
                const Text('العنوان:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 5),
                Expanded(
                  child: hasCoordinates
                  // 1. إذا وجدت إحداثيات: اعرض زر (يستخدم الدالة الداخلية)
                      ? InkWell(
                    onTap: () => _launchMaps(context, order.destinationLat, order.destinationLng),
                    child: Text(
                      "تم تحديد الموقع (اضغط للعرض)", // النص الذي سيظهر للزبون
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                  // 2. إذا لم توجد إحداثيات: اعرض النص العادي
                      : Text(order.address, style: TextStyle(color: Colors.grey.shade800)),
                ),
              ],
            ),
            // --- [نهاية التعديل] ---

            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('الإجمالي', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                Text('$totalFormatted د.ع', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Icon(statusInfo['icon'], color: statusInfo['color'], size: 20),
                const SizedBox(width: 8),
                Text('الحالة:', style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    statusInfo['text'],
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: statusInfo['color']),
                  ),
                ),
              ],
            ),
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
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeDateFormatting('ar', null);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const RestaurantModule());
}

class RestaurantModule extends StatefulWidget {
  const RestaurantModule({super.key});
  @override
  State<RestaurantModule> createState() => _RestaurantModuleState();
}

class _RestaurantModuleState extends State<RestaurantModule> {
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await NotificationService.initialize();

    // 🔥 الاستماع للإشعارات القادمة والتطبيق مفتوح (Foreground) 🔥
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // 1. عرض التنبيه (صوت + إشعار منبثق)
      NotificationService.display(message);

      // 2. تحديث البيانات فوراً (بدلاً من انتظار المؤقت)
      if (mounted) {
        // نستخدم try-catch لتجنب الأخطاء إذا كان السياق غير جاهز
        try {
          final authProvider = Provider.of<StoreAuthProvider>(context, listen: false);

          if (authProvider.isLoggedIn && authProvider.token != null) {
            print("🔔 إشعار جديد وصل! جاري تحديث بيانات الفوراً...");

            // أ) تحديث قائمة الطلبات (النشطة والمكتملة)
            Provider.of<DashboardProvider>(context, listen: false)
                .fetchDashboardData(authProvider.token, silent: true);

            // ب) تحديث إعدادات المطعم (للاحتياط، في حال تغيرت الحالة)
            Provider.of<RestaurantSettingsProvider>(context, listen: false)
                .fetchSettings(authProvider.token);
          }
        } catch (e) {
          print("Ignored notification update error: $e");
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 1. المزودات الأساسية (تعمل دائماً)
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => StoreAuthProvider()),
        ChangeNotifierProvider(create: (_) => StoreCustomerProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),

        // 2. مزودات لوحة التحكم (تم تحويلها لمزودات عادية لإصلاح الشاشة البيضاء)
        // ✅ الآن سيتم إنشاؤها فوراً عند بدء التطبيق ولن يظهر خطأ Provider not found
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => RestaurantSettingsProvider()),
        ChangeNotifierProvider(create: (_) => RestaurantProductsProvider()),

        // 3. مزود التوصيل
        ChangeNotifierProvider(create: (_) => DeliveryProvider()),
      ],
      child: MaterialApp(
        title: 'Beytei Restaurants',
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
        debugShowCheckedModeBanner: false,
        // نقطة البداية تعتمد على الموجه الذكي
        home: const AuthWrapper(),
      ),
    );
  }
}
// ✨ NEW: Restaurant Settings Screen
class RestaurantSettingsScreen extends StatefulWidget {
  const RestaurantSettingsScreen({super.key});

  @override
  State<RestaurantSettingsScreen> createState() => _RestaurantSettingsScreenState();
}

class _RestaurantSettingsScreenState extends State<RestaurantSettingsScreen> {

  Future<void> _updateStatus(RestaurantSettingsProvider provider, bool newValue) async {
    final token = Provider.of<StoreAuthProvider>(context, listen: false).token;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final success = await provider.updateOpenStatus(token, newValue);
    if(success) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text(newValue ? 'تم فتح المطعم بنجاح.' : 'تم إغلاق المطعم بنجاح.'), backgroundColor: Colors.green));
    } else {
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('فشل تحديث الحالة.'), backgroundColor: Colors.red));
    }
  }

  Future<void> _showTimePicker(BuildContext context, RestaurantSettingsProvider provider, bool isOpeningTime) async {
    final initialTime = isOpeningTime
        ? TimeOfDay(hour: int.parse(provider.openTime.split(':')[0]), minute: int.parse(provider.openTime.split(':')[1]))
        : TimeOfDay(hour: int.parse(provider.closeTime.split(':')[0]), minute: int.parse(provider.closeTime.split(':')[1]));

    final TimeOfDay? newTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      // ✨ تم إزالة وسيط 'builder' الذي كان يسبب خطأ التعارض.
    );

    if (newTime != null) {
      // ✨ --- هذا هو التعديل --- ✨
      // فرض تحويل الوقت إلى صيغة 24 ساعة (HH:mm) قبل الإرسال
      final hour24 = newTime.hour; // newTime.hour يعطي دائماً صيغة 24 ساعة
      final minute = newTime.minute;
      final formattedTime24 = '${hour24.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
      // --- نهاية التعديل ---

      final token = Provider.of<StoreAuthProvider>(context, listen: false).token;

      // استخدام الوقت المحول formattedTime24
      final String newOpenTime = isOpeningTime ? formattedTime24 : provider.openTime;
      final String newCloseTime = isOpeningTime ? provider.closeTime : formattedTime24;

      final success = await provider.updateAutoTimes(token, newOpenTime, newCloseTime);
      if(mounted) {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        if(success) {
          scaffoldMessenger.showSnackBar(const SnackBar(content: Text('تم تحديث أوقات العمل التلقائية بنجاح.'), backgroundColor: Colors.green));
        } else {
          scaffoldMessenger.showSnackBar(const SnackBar(content: Text('فشل تحديث الأوقات.'), backgroundColor: Colors.red));
        }
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Consumer<RestaurantSettingsProvider>(
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
                      const Text("التحكم اليدوي باستقبال الطلبات", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Divider(),
                      SwitchListTile(
                        title: Text(
                          provider.isRestaurantOpen ? 'المطعم متاح لاستقبال الطلبات' : 'المطعم غير متاح حالياً',
                          style: TextStyle(fontWeight: FontWeight.bold, color: provider.isRestaurantOpen ? Colors.green : Colors.red),
                        ),
                        value: provider.isRestaurantOpen,
                        onChanged: (newValue) => _updateStatus(provider, newValue),
                        secondary: Icon(provider.isRestaurantOpen ? Icons.store_mall_directory : Icons.storefront_outlined),
                        activeColor: Colors.green,
                      ),
                      const SizedBox(height: 10),
                      Text('عند إغلاق هذا الخيار، سيظهر للزبون "المطعم غير متوفر حالياً" وستختفي المنتجات.', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
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
                      const Text("تحديد وقت التفعيل التلقائي", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Divider(),
                      ListTile(
                        title: const Text('وقت الفتح التلقائي'),
                        trailing: Text(provider.openTime, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        leading: const Icon(Icons.access_time),
                        onTap: () => _showTimePicker(context, provider, true),
                      ),
                      const Divider(),
                      ListTile(
                        title: const Text('وقت الإغلاق التلقائي'),
                        trailing: Text(provider.closeTime, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        leading: const Icon(Icons.lock_clock),
                        onTap: () => _showTimePicker(context, provider, false),
                      ),
                      const SizedBox(height: 10),
                      Text('سيتم تفعيل استقبال الطلبات تلقائياً ضمن هذا النطاق الزمني بشرط أن يكون الزر اليدوي أعلاه مفعلاً.', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
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

  @override
  Widget build(BuildContext context) {
    // نستخدم الـ Provider لمعرفة التبويب الحالي
    final navProvider = Provider.of<NavigationProvider>(context);

    return WillPopScope(
      onWillPop: () async {
        final currentNavigator = _navigatorKeys[navProvider.currentIndex].currentState;
        if (currentNavigator != null && currentNavigator.canPop()) {
          currentNavigator.pop();
          return false;
        }
        if (navProvider.currentIndex != 0) {
          navProvider.changeTab(0);
          return false;
        }
        return true;
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
  }

  // ✅ الدالة المعدلة للتحديث التلقائي المزدوج
// داخل MiswakStoreHomeScreenState

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

            if (result == true || true) {
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
                      // تم إضافة RefreshIndicator هنا أيضاً للسماح بالسحب حتى لو فارغة
                      return Stack(
                        children: [
                          ListView(), // يسمح بعملية السحب
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
      // يمكن إضافة رسالة خطأ هنا إذا أردت
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

    // ✅ الحفظ في مفاتيح المسواك الخاصة
    await prefs.setInt('miswak_area_id', areaId);
    await prefs.setString('miswak_area_name', areaName);

    if (mounted) {
      if (widget.isCancellable) {
        // إذا كنا نغير المنطقة من داخل التطبيق، نغلق الصفحة ونرسل 'true' لتحديث البيانات
        Navigator.of(context).pop(true);
      } else {
        // ✅ التعديل الحاسم:
        // التوجيه إلى MainScreen مباشرة لضمان ظهور الشريط السفلي (السلة، الطلبات..)
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainScreen()),
                (route) => false
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // تصفية المحافظات (التي ليس لها أب)
    final governorates = _filteredAreas.where((a) => a.parentId == 0).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('اختر منطقة التوصيل للمسواك'),
        automaticallyImplyLeading: widget.isCancellable,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                  hintText: 'ابحث عن مدينتك...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade200
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : governorates.isEmpty
                ? const Center(child: Text("لا توجد مناطق مطابقة للبحث"))
                : ListView.builder(
              itemCount: governorates.length,
              itemBuilder: (context, index) {
                final governorate = governorates[index];
                // جلب المدن التابعة لهذه المحافظة
                final cities = _filteredAreas.where((a) => a.parentId == governorate.id).toList();

                return ExpansionTile(
                  title: Text(
                      governorate.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)
                  ),
                  children: cities.map((city) => ListTile(
                      title: Text(city.name),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                      onTap: () => _saveSelection(city.id, city.name)
                  )).toList(),
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

class DetailScreen extends StatelessWidget {
  final FoodItem foodItem;
  const DetailScreen({super.key, required this.foodItem});

  @override
  Widget build(BuildContext context) {

    // ✨ --- [إضافة جديدة] ---
    // 1. جلب حالة المنتج
    final bool isDeliverable = foodItem.isDeliverable;

    // 2. جلب بيانات المطعم الأب (للحصول على الأوقات)
    final provider = Provider.of<StoreCustomerProvider>(context, listen: false);
    Restaurant? restaurant;

    // محاولة إيجاد المطعم في القائمة الشاملة
    try {
      restaurant = provider.allRestaurants.firstWhere((r) => r.id == foodItem.categoryId);
    } catch (e) {
      // إذا لم نجده (ربما من شاشة البحث)، ابحث في بيانات الصفحة الرئيسية
      try {
        restaurant = (provider.homeData['restaurants'] as List<dynamic>? ?? [])
            .cast<Restaurant>()
            .firstWhere((r) => r.id == foodItem.categoryId);
      } catch (e) {
        restaurant = null; // لم يتم العثور عليه
      }
    }

    // 3. تجهيز رسالة الأوقات
    final String openTime = restaurant?.autoOpenTime ?? "N/A";
    final String closeTime = restaurant?.autoCloseTime ?? "N/A";
    // --- [نهاية الإضافة] ---

    return Scaffold(
      appBar: AppBar(title: Text(foodItem.name)),
      body: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Hero(
            tag: 'food_image_${foodItem.id}',
            child: CachedNetworkImage(imageUrl: foodItem.imageUrl, fit: BoxFit.cover, height: 300, placeholder: (c, u) => Container(height: 300, color: Colors.grey[200], child: const Center(child: CircularProgressIndicator())), errorWidget: (c, u, e) => Container(height: 300, color: Colors.grey[200], child: const Icon(Icons.error))),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(foodItem.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(foodItem.formattedPrice, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text(foodItem.description, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700, height: 1.5)),
              const Divider(height: 30),
              const Text("التقييمات", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(children: [
                RatingBarIndicator(rating: foodItem.averageRating, itemBuilder: (context, index) => const Icon(Icons.star, color: Colors.amber), itemCount: 5, itemSize: 20.0, direction: Axis.horizontal),
                const SizedBox(width: 10),
                Text("(${foodItem.ratingCount} تقييم)", style: const TextStyle(color: Colors.grey)),
              ]),
              const SizedBox(height: 10),
              Center(child: OutlinedButton(child: const Text("أضف تقييمك"), onPressed: () => showDialog(context: context, builder: (context) => RatingDialog(productId: foodItem.id)))),
            ]),
          ),
        ]),
      ),

      // ✨ --- [تم تعديل هذا القسم بالكامل] ---
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isDeliverable
        // 1. في حال كان المنتج متاحاً (اعرض الزر)
            ? ElevatedButton.icon(
          icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
          label: const Text("إضافة إلى السلة", style: TextStyle(color: Colors.white, fontSize: 18)),
          onPressed: () => Provider.of<CartProvider>(context, listen: false).addToCart(foodItem, context),
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), backgroundColor: Theme.of(context).primaryColor),
        )
        // 2. في حال كان مغلقاً (اعرض الرسالة كما في صورتك)
            : Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "ليس متاح الآن",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (restaurant != null) // اعرض الأوقات فقط إذا وجدنا المطعم
                Text(
                  "سيكون متاحاً $openTime - $closeTime",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
        ),
      ),
      // --- [نهاية التعديل] ---
    );
  }
}
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

// (في ملف re.dart)
// (استبدل الكلاس القديم بالكامل بهذا الكلاس المحدث V18)

// --- ✨ [ الخطوة 2هـ: استبدال كلاس _CartScreenState بالكامل ] ---
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

  @override
  Widget build(BuildContext context) {
    // ✅ حفظ السياق الرئيسي للصفحة في متغير لاستخدامه لاحقاً بأمان
    final mainContext = context;

    return Scaffold(
        appBar: AppBar(title: const Text('سلتي')),
        body: Consumer<CartProvider>(
          // ✅ قمنا بتغيير اسم المتغير هنا إلى (ctx) لتجنب التضارب مع (context) الرئيسي
            builder: (ctx, cart, child) {
              if (cart.items.isEmpty) {
                return const Center(
                    child: Text('سلّتك فارغة!',
                        style: TextStyle(fontSize: 18, color: Colors.grey)));
              }
              return Column(children: [
                Expanded(
                    child: ListView.builder(
                        padding: const EdgeInsets.all(15),
                        itemCount: cart.items.length,
                        itemBuilder: (ctx, index) => _buildCartItemCard(
                            mainContext, cart, cart.items[index]))),
                // ✅ نمرر mainContext الثابت هنا بدلاً من ctx المتغير
                _buildCheckoutSection(mainContext, cart)
              ]);
            }));
  }

  // (دالة بناء ملخص السعر - كما هي)
  Widget _buildPriceSummary(CartProvider cart, double? deliveryFee,
      bool isCalculatingFee, String feeMessage) {
    final totalFormatted =
    NumberFormat('#,###', 'ar_IQ').format(cart.totalPrice);
    final discountFormatted =
    NumberFormat('#,###', 'ar_IQ').format(cart.totalDiscountAmount);

    final double finalTotal = (cart.discountedTotal) + (deliveryFee ?? 0);
    final finalTotalFormatted =
    NumberFormat('#,###', 'ar_IQ').format(finalTotal);

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
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          if (cart.totalDiscountAmount > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('الخصم',
                    style: TextStyle(
                        fontSize: 14, color: Theme.of(context).primaryColor)),
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
                  Icon(Icons.delivery_dining_outlined,
                      size: 20, color: Colors.blue.shade700),
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

    // 🛑 التعديل 1: إلغاء حالة "جاري الحساب" لأن السعر ثابت
    bool _isGettingLocation = false;

    // 🛑 التعديل 2: رسالة توضيحية للسعر الثابت
    String _locationMessage = "سعر توصيل ثابت لكل المناطق";

    // 🛑 التعديل 3: تثبيت السعر عند 1000 دينار
    double _deliveryFee = 1000.0;

    showDialog(
      context: cartScreenContext,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(builder: (context, setDialogState) {

          // --- دالة جلب الموقع فقط (بدون تغيير السعر) ---
          // سنحتفظ بجلب الموقع لأغراض توجيه السائق، لكن لن يؤثر على السعر
          Future<void> fetchLocationForDriver() async {
            try {
              bool serviceEnabled = await geolocator.Geolocator.isLocationServiceEnabled();
              if (!serviceEnabled) return;

              geolocator.LocationPermission permission = await geolocator.Geolocator.checkPermission();
              if (permission == geolocator.LocationPermission.denied) {
                permission = await geolocator.Geolocator.requestPermission();
              }

              if (permission == geolocator.LocationPermission.whileInUse || permission == geolocator.LocationPermission.always) {
                // نجلب الموقع بصمت لإرساله مع الطلب
                _capturedPosition = await geolocator.Geolocator.getCurrentPosition(
                    desiredAccuracy: geolocator.LocationAccuracy.medium,
                    timeLimit: const Duration(seconds: 5)
                );
                if(context.mounted) {
                  setDialogState(() => _locationMessage = "تم تحديد موقعك للسائق ✅");
                }
              }
            } catch (e) {
              // تجاهل الأخطاء، السعر ثابت ولا يتأثر
            }
          }

          // تشغيل جلب الموقع في الخلفية عند فتح النافذة
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if(_capturedPosition == null) fetchLocationForDriver();
          });

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: const Text('إتمام الطلب'),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'الاسم الكامل'), validator: (v) => v!.isEmpty ? 'الرجاء إدخال الاسم' : null, enabled: !isSubmitting),
                    const SizedBox(height: 15),
                    TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: 'رقم الهاتف'), keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'الرجاء إدخال رقم الهاتف' : null, enabled: !isSubmitting),
                    const SizedBox(height: 15),
                    TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(labelText: 'العنوان بالتفصيل (أقرب نقطة دالة)'),
                        maxLines: 2,
                        enabled: !isSubmitting,
                        validator: (v) => v!.isEmpty ? 'الرجاء إدخال العنوان بالتفصيل' : null
                    ),
                    const SizedBox(height: 20),

                    // عرض السعر والموقع بتصميم أنيق
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.teal.withOpacity(0.2)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("تكلفة التوصيل:", style: TextStyle(fontWeight: FontWeight.bold)),
                              // عرض السعر الثابت مباشرة
                              Text("${NumberFormat('#,###').format(_deliveryFee)} د.ع", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(Icons.info_outline, color: Colors.grey, size: 14),
                              const SizedBox(width: 5),
                              Expanded(child: Text(_locationMessage, style: const TextStyle(fontSize: 11, color: Colors.grey))),
                            ],
                          )
                        ],
                      ),
                    ),

                    const SizedBox(height: 15),
                    TextFormField(controller: _couponController, decoration: InputDecoration(labelText: 'كود الخصم (إن وجد)', suffixIcon: TextButton(child: const Text("تطبيق"), onPressed: () async {
                      final result = await cart.applyCoupon(_couponController.text);
                      if(cartScreenContext.mounted) ScaffoldMessenger.of(cartScreenContext).showSnackBar(SnackBar(content: Text(result['message']), backgroundColor: result['valid'] ? Colors.green : Colors.red));
                      setDialogState(() {});
                    }))),
                    const Divider(height: 30),
                    // تمرير false دائماً لأننا لا نحسب السعر
                    _buildPriceSummary(cart, _deliveryFee, false, ""),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(onPressed: isSubmitting ? null : () => Navigator.of(dialogContext).pop(), child: const Text('إلغاء')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
                onPressed: isSubmitting
                    ? null
                    : () async {
                  if (!_formKey.currentState!.validate()) return;

                  setDialogState(() => isSubmitting = true);
                  try {
                    final createdOrder = await _apiService.submitOrder(
                        name: _nameController.text,
                        phone: _phoneController.text,
                        address: _addressController.text,
                        cartItems: cart.items,
                        couponCode: cart.appliedCoupon,
                        position: _capturedPosition, // نرسل الموقع إذا تم جلبه بنجاح
                        deliveryFee: _deliveryFee // السعر الثابت (1000)
                    );

                    if (!cartScreenContext.mounted) return;
                    if (createdOrder == null) throw Exception('فشل إنشاء الطلب.');

                    await cart._recordSuccessfulOrder();
                    Navigator.of(dialogContext).pop();
                    cart.clearCart();
                    HapticFeedback.heavyImpact();

                    if (cartScreenContext.mounted) {
                      showDialog(
                        context: cartScreenContext,
                        barrierDismissible: false,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle, size: 70, color: Colors.teal),
                              const SizedBox(height: 15),
                              const Text("تم استلام طلبك!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 10),
                              const Text("جاري تحضير الطلب وإرسال المندوب.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                          actions: [
                            ElevatedButton(
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                  Provider.of<NavigationProvider>(cartScreenContext, listen: false).changeTab(2);
                                },
                                child: const Text("متابعة الطلب")
                            )
                          ],
                        ),
                      );
                    }
                  } catch (e) {
                    if (cartScreenContext.mounted) {
                      ScaffoldMessenger.of(cartScreenContext).showSnackBar(SnackBar(content: Text('خطأ: ${e.toString()}'), backgroundColor: Colors.red));
                    }
                  } finally {
                    if (dialogContext.mounted) setDialogState(() => isSubmitting = false);
                  }
                },
                child: isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0))
                    : const Text('تأكيد الطلب والدفع'),
              )
            ],
          );
        });
      },
    );
  } Widget _buildCartItemCard(
      BuildContext context, CartProvider cart, FoodItem item) {
    return Card(
        margin: const EdgeInsets.only(bottom: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(children: [
              ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                      imageUrl: item.imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover)),
              const SizedBox(width: 15),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        Text(item.formattedPrice,
                            style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold))
                      ])),
              Row(children: [
                IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => cart.decrementQuantity(item)),
                Text(item.quantity.toString(),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => cart.incrementQuantity(item))
              ])
            ])));
  }

  Widget _buildCheckoutSection(BuildContext context, CartProvider cart) {
    final totalFormatted =
    NumberFormat('#,###', 'ar_IQ').format(cart.totalPrice);
    final discountedTotalFormatted =
    NumberFormat('#,###', 'ar_IQ').format(cart.discountedTotal);
    return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30), topRight: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 5)
            ]),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('المجموع',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
            Text('$totalFormatted د.ع',
                style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                    decoration: cart.appliedCoupon != null
                        ? TextDecoration.lineThrough
                        : TextDecoration.none))
          ]),
          if (cart.appliedCoupon != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('الإجمالي بعد الخصم',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor)),
                    Text('$discountedTotalFormatted د.ع',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor))
                  ]),
            ),
          const SizedBox(height: 20),
          SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                  onPressed: () => _showCheckoutDialog(context, cart),
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white),
                  child: const Text('إتمام الطلب',
                      style: TextStyle(fontSize: 18))))
        ]));
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

// =======================================================================
// --- Store Dashboard Screen (Updated V19) ---
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
    // تهيئة 5 تبويبات (طلبات، مكتملة، منتجات، تقييمات، إعدادات)
    _tabController = TabController(length: 5, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ✅ استخدام StoreAuthProvider
      final token = Provider.of<StoreAuthProvider>(context, listen: false).token;

      if (token != null) {
        // 1. جلب الإعدادات أولاً (لحفظ الموقع في الذاكرة لاستخدامه في طلبات التوصيل)
        Provider.of<RestaurantSettingsProvider>(context, listen: false)
            .fetchSettings(token)
            .then((_) {

          // 2. ثم تفعيل التحديث التلقائي للداشبورد (للطلبات)
          if (mounted) {
            Provider.of<DashboardProvider>(context, listen: false).startAutoRefresh(token);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    // إيقاف التحديث التلقائي عند الخروج
    Provider.of<DashboardProvider>(context, listen: false).stopAutoRefresh();
    _tabController.dispose();
    super.dispose();
  }

  // --- نافذة طلب التوصيل الخاص (معدلة للمسواك) ---
  void _showPrivateDeliveryRequestDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final _pickupNameController = TextEditingController();
    final _destAddressController = TextEditingController();
    final _feeController = TextEditingController();
    final _phoneController = TextEditingController();
    final _notesController = TextEditingController();
    final _destLatController = TextEditingController();
    final _destLngController = TextEditingController();
    bool isSubmitting = false;

    // تحميل الاسم المحفوظ مسبقاً
    SharedPreferences.getInstance().then((prefs) {
      final savedName = prefs.getString('saved_restaurant_name') ?? ''; // نستخدم نفس المفتاح للتوافق
      _pickupNameController.text = savedName;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('إنشاء طلب توصيل خاص'),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("سيتم إرسال الطلب من موقع المتجر المسجل.", style: Theme.of(context).textTheme.bodySmall),
                      const Divider(height: 20),
                      TextFormField(
                        controller: _pickupNameController,
                        decoration: const InputDecoration(labelText: 'اسم المتجر/المصدر (الاستلام)'),
                        validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _destAddressController,
                        decoration: const InputDecoration(labelText: 'عنوان الزبون (الوجهة)'),
                        validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(labelText: 'رقم هاتف الزبون'),
                        keyboardType: TextInputType.phone,
                        validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _feeController,
                        decoration: const InputDecoration(labelText: 'أجرة التوصيل', suffixText: 'د.ع'),
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(labelText: 'ملاحظات (اسم الزبون، تفاصيل)'),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      Text("إحداثيات الوجهة (اختياري)", style: Theme.of(context).textTheme.bodySmall),
                      Row(
                        children: [
                          Expanded(child: TextFormField(controller: _destLatController, decoration: const InputDecoration(labelText: 'Lat'), keyboardType: TextInputType.number)),
                          const SizedBox(width: 8),
                          Expanded(child: TextFormField(controller: _destLngController, decoration: const InputDecoration(labelText: 'Lng'), keyboardType: TextInputType.number)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting ? null : () async {
                    if (_formKey.currentState!.validate()) {
                      setDialogState(() => isSubmitting = true);
                      try {
                        final prefs = await SharedPreferences.getInstance();

                        // ✅ هام: قراءة توكن المسواك المخزن بواسطة StoreAuthProvider
                        final token = prefs.getString('store_jwt_token');

                        // ملاحظة: RestaurantSettingsProvider يحفظ الموقع في restaurant_lat/lng
                        // لذلك نستخدم نفس المفاتيح هنا للتوافق
                        final pickupLat = prefs.getDouble('restaurant_lat');
                        final pickupLng = prefs.getDouble('restaurant_lng');

                        if (token == null || pickupLat == null || pickupLng == null) {
                          throw Exception("بيانات المتجر غير كاملة. يرجى الانتظار قليلاً أو إعادة تسجيل الدخول.");
                        }

                        final pickupName = _pickupNameController.text;
                        await prefs.setString('saved_restaurant_name', pickupName);

                        final double? destLat = double.tryParse(_destLatController.text);
                        final double? destLng = double.tryParse(_destLngController.text);

                        final result = await _apiService.createUnifiedDeliveryRequest(
                          token: token,
                          sourceType: 'store', // ✅ تحديد المصدر كمتجر
                          pickupName: pickupName,
                          pickupLat: pickupLat,
                          pickupLng: pickupLng,
                          destinationAddress: _destAddressController.text,
                          destinationLat: destLat,
                          destinationLng: destLng,
                          deliveryFee: _feeController.text,
                          orderDescription: _notesController.text,
                          endCustomerPhone: _phoneController.text,
                          sourceOrderId: 'private_store_${DateTime.now().millisecondsSinceEpoch}',
                        );

                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'تم إرسال الطلب بنجاح!'), backgroundColor: Colors.green));
                        }
                      } catch (e) {
                        if (dialogContext.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: ${e.toString().replaceAll("Exception: ", "")}'), backgroundColor: Colors.red));
                        }
                      } finally {
                        if (dialogContext.mounted) {
                          setDialogState(() => isSubmitting = false);
                        }
                      }
                    }
                  },
                  child: isSubmitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('إرسال الطلب'),
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
    // ✅ جلب مزود مصادقة المسواك
    final auth = Provider.of<StoreAuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم المسواك'),
        actions: [
          // 🔥 زر الفحص الجديد (Store Debugger)
          IconButton(
            icon: const Icon(Icons.bug_report, color: Colors.orange),
            tooltip: "فحص النظام",
            onPressed: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const StoreDebugScreen())
              );
            },
          ),

          IconButton(icon: const Icon(Icons.notifications_active_outlined), onPressed: () async {
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            try {
              final success = await _apiService.testNotification();
              if (success) scaffoldMessenger.showSnackBar(const SnackBar(content: Text("تم إرسال إشعار تجريبي بنجاح."), backgroundColor: Colors.green));
            } catch (e) {
              scaffoldMessenger.showSnackBar(SnackBar(content: Text("فشل إرسال الإشعار: ${e.toString()}"), backgroundColor: Colors.red));
            }
          }, tooltip: 'اختبار الإشعارات'),

          // ✅ زر تسجيل الخروج يستدعي دالة StoreAuthProvider
          IconButton(icon: const Icon(Icons.logout), onPressed: () => auth.logout(context), tooltip: 'تسجيل الخروج')
        ],
        bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(icon: Icon(Icons.list_alt), text: 'الطلبات'),
              Tab(icon: Icon(Icons.history), text: 'المكتملة'),
              Tab(icon: Icon(Icons.fastfood_outlined), text: 'المنتجات'),
              Tab(icon: Icon(Icons.star_rate), text: 'التقييمات'),
              Tab(icon: Icon(Icons.settings), text: 'الإعدادات'),
            ]
        ),
      ),

      body: TabBarView(
        controller: _tabController,
        children: [
          // يمكن استخدام نفس الشاشات لأنها تعتمد على DashboardProvider المشترك
          OrdersListScreen(status: 'active'),
          OrdersListScreen(status: 'completed'),
          const ProductManagementTab(),
          const RatingsDashboardScreen(),
          const RestaurantSettingsScreen(),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPrivateDeliveryRequestDialog(context),
        icon: const Icon(Icons.two_wheeler_outlined),
        label: const Text('طلب توصيل خاص'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
      ),
    );
  }
}
// =======================================================================
// --- ✨ شاشة جديدة: تبويب إدارة المنتجات ---
// =======================================================================
// استبدل كلاس ProductManagementTab بهذا الكود

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

  void _navigateToEditScreen(FoodItem product) async {
    final productProvider = Provider.of<RestaurantProductsProvider>(context, listen: false);
    final authProvider = Provider.of<StoreAuthProvider>(context, listen: false);

    final bool? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProductScreen(
          product: product,
          productProvider: productProvider,
          authProvider: authProvider,
        ),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم تحديث المنتج بنجاح"), backgroundColor: Colors.green),
      );
    }
  }

  // دالة الانتقال لشاشة الإضافة
  void _navigateToAddScreen() async {
    final productProvider = Provider.of<RestaurantProductsProvider>(context, listen: false);
    final authProvider = Provider.of<StoreAuthProvider>(context, listen: false);

    final bool? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddProductScreen( // شاشة جديدة سننشئها بالأسفل
          productProvider: productProvider,
          authProvider: authProvider,
        ),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم إضافة المنتج بنجاح"), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<StoreAuthProvider>(context, listen: false);

    return Consumer<RestaurantProductsProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          // ✅ تحديد موقع الزر العائم ليكون في اليسار
          floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,

          floatingActionButton: FloatingActionButton.extended(
            onPressed: _navigateToAddScreen,
            label: const Text("إضافة منتج"),
            icon: const Icon(Icons.add),
            backgroundColor: Theme.of(context).primaryColor,
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
              if (provider.isLoading && provider.products.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (provider.errorMessage != null && provider.products.isEmpty) {
                return NetworkErrorWidget(message: provider.errorMessage!, onRetry: () => provider.fetchProducts(auth.token));
              }
              if (provider.products.isEmpty) {
                return const Center(child: Text("لم يتم العثور على منتجات. أضف منتجك الأول!"));
              }

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 80), // مسافة للزر العائم
                itemCount: provider.products.length,
                itemBuilder: (context, index) {
                  final product = provider.products[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: product.imageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorWidget: (c, u, e) => Container(color: Colors.grey, child: const Icon(Icons.fastfood)),
                        ),
                      ),
                      title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("السعر: ${product.formattedPrice}", style: TextStyle(color: product.salePrice != null ? Colors.red : Colors.black)),
                      trailing: const Icon(Icons.edit_outlined, color: Colors.blue),
                      onTap: () => _navigateToEditScreen(product),
                    ),
                  );
                },
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
  final RestaurantProductsProvider productProvider;
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
  File? _selectedImage; // لتخزين الصورة الجديدة
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

  // دالة اختيار الصورة
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // نمرر الصورة الجديدة (_selectedImage) للدالة كمتغير مسمى
    final success = await widget.productProvider.updateProduct(
      widget.authProvider.token!,
      widget.product.id,
      _nameController.text,
      _priceController.text,
      _salePriceController.text,
      imageFile: _selectedImage, // ✅✅✅ التصحيح هنا: أضفنا imageFile:
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context, true);
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
                // منطقة الصورة
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
                const SizedBox(height: 10),
                const Text("اضغط على الصورة لتغييرها", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
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
// أضف هذا الكلاس الجديد في ملف re.dart

class AddProductScreen extends StatefulWidget {
  final RestaurantProductsProvider productProvider;
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
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // يفضل أن تكون الصورة إلزامية عند الإنشاء
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
                // اختيار الصورة
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
    // استخدام StoreAuthProvider لأننا في قسم المسواك
    final authProvider = Provider.of<StoreAuthProvider>(context, listen: false);

    return Consumer<DashboardProvider>(
      builder: (context, dashboard, child) {
        final orders = dashboard.orders[widget.status] ?? [];
        final pickupCodes = dashboard.pickupCodes;

        // 1. حالة التحميل
        if (dashboard.isLoading && orders.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        // 2. حالة وجود خطأ (Error State)
        if (dashboard.error != null && orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.red),
                const SizedBox(height: 10),
                Text(
                  "حدث خطأ في جلب البيانات",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(dashboard.error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () => dashboard.fetchDashboardData(authProvider.token),
                  child: const Text("إعادة المحاولة"),
                )
              ],
            ),
          );
        }

        // 3. حالة القائمة الفارغة (Empty State)
        if (orders.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => dashboard.fetchDashboardData(authProvider.token),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 20),
                const Center(child: Text("لا توجد طلبات هنا حالياً", style: TextStyle(fontSize: 18, color: Colors.grey))),
              ],
            ),
          );
        }

        // 4. عرض القائمة
        return RefreshIndicator(
          onRefresh: () => dashboard.fetchDashboardData(authProvider.token),
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final code = pickupCodes[order.id];
              return OrderCard(
                order: order,
                onStatusChanged: () => dashboard.fetchDashboardData(authProvider.token),
                isCompleted: widget.status != 'active',
                pickupCode: code,
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

class MiswakAppEntryPoint extends StatelessWidget {
  const MiswakAppEntryPoint({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 1. المزودات الأساسية (بأسماء المسواك الجديدة)
        ChangeNotifierProvider(create: (_) => CartProvider()), // السلة مشتركة أو منفصلة حسب رغبتك
        ChangeNotifierProvider(create: (_) => NavigationProvider()),

        // 👇 المزودات الجديدة التي أنشأناها بالأعلى
        ChangeNotifierProvider(create: (_) => StoreAuthProvider()),
        ChangeNotifierProvider(create: (_) => StoreCustomerProvider()),

        // (يمكنك إنشاء StoreSettingsProvider و StoreDashboardProvider بنفس نمط المطعم وتغيير الاسم)
      ],
      // 👇 هنا نضع MaterialApp فرعي لحل مشاكل التوجيه والرجوع
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.green, // لون مميز للمسواك
          fontFamily: 'Tajawal',
          scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        ),
        home: const StoreAuthWrapper(), // الموجه الخاص بالمسواك
      ),
    );
  }
}

// الموجه الخاص بالمسواك
class StoreAuthWrapper extends StatefulWidget {
  const StoreAuthWrapper({super.key});

  @override
  State<StoreAuthWrapper> createState() => _StoreAuthWrapperState();
}

class _StoreAuthWrapperState extends State<StoreAuthWrapper> {
  @override
  Widget build(BuildContext context) {
    // نستخدم StoreAuthProvider
    return Consumer<StoreAuthProvider>(
      builder: (context, auth, child) {
        if (auth.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // إذا المدير مسجل دخول -> لوحة التحكم
        // (يجب عليك تغيير اسم كلاس StoreDashboardScreen ليتعامل مع StoreApiService)
        if (auth.isLoggedIn) {
          return const StoreDashboardScreen();
        }

        // إذا زبون -> شاشة الموقع ثم الرئيسية
        return const StoreLocationCheckWrapper();
      },
    );
  }
}
class _RatingsDashboardScreenState extends State<RatingsDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<StoreAuthProvider>(context, listen: false);

    return Consumer<DashboardProvider>(
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