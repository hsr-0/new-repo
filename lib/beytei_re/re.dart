import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:math'; // 👈 تأكد من وجود هذا السطر ضروري جداً
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/services.dart'; // مطلوب للاهتزاز
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
import 'package:image_picker/image_picker.dart';
import '../taxi/cash.dart';

// =======================================================================
// --- إعدادات وثوابت عامة للوحدة ---
// =======================================================================
const String BEYTEI_URL = 'https://re.beytei.com';
const String CONSUMER_KEY = 'ck_d22c789681c4610838f1d39a05dbedcb73a2c810';
const String CONSUMER_SECRET = 'cs_78b90e397bbc2a8f5f5092cca36dc86e55c01c07';
const Duration API_TIMEOUT = Duration(seconds: 30);
const String CACHE_HOME_DATA_KEY = 'cache_home_data_area_'; // سنضيف رقم المنطقة
const String CACHE_RESTAURANTS_KEY = 'cache_all_restaurants_area_';


class AppConstants {

  // مفاتيح الكاش (للزبون فقط)
  static const String CACHE_KEY_RESTAURANTS_PREFIX = 'cache_restaurants_area_';
  static const String CACHE_KEY_MENU_PREFIX = 'cache_menu_restaurant_';
  static const String CACHE_TIMESTAMP_PREFIX = 'cache_time_';
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





class AuthProvider with ChangeNotifier {
  String? _token;
  String? _userRole; // 'owner' أو 'leader'
  bool _isLoading = true;

  String? get token => _token;
  String? get userRole => _userRole;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _token != null;

  AuthProvider() {
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token');
    _userRole = prefs.getString('user_role'); // استرجاع الرتبة
    _isLoading = false;
    notifyListeners();
  }

  // دالة تسجيل دخول موحدة مع تحديد الرتبة
  Future<bool> login(String username, String password, String role, {String? restaurantLat, String? restaurantLng}) async {
    final authService = AuthService();
    _token = await authService.loginRestaurantOwner(username, password);

    if (_token != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', _token!);
      await prefs.setString('user_role', role); // حفظ الرتبة (owner/leader)
      _userRole = role;

      // تحديث FCM
      await authService.registerDeviceToken();

      if (restaurantLat != null && restaurantLng != null) {
        await prefs.setDouble('restaurant_lat', double.tryParse(restaurantLat) ?? 0.0);
        await prefs.setDouble('restaurant_lng', double.tryParse(restaurantLng) ?? 0.0);
      }

      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout(BuildContext context) async {
    final authService = AuthService();
    await authService.logout();
    _token = null;
    _userRole = null;

    // مسح البيانات من الذاكرة
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_role');

    if (context.mounted) {
      Provider.of<CustomerProvider>(context, listen: false).clearData();
      Provider.of<RestaurantSettingsProvider>(context, listen: false).clearData();
    }
    notifyListeners();
  }
}

class CustomerProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  Map<String, List<dynamic>> _homeData = {};
  List<Restaurant> _allRestaurants = [];
  Map<int, List<FoodItem>> _menuItems = {};

  int _lastLoadedAreaId = -1;
  bool _isLoadingHome = false;
  bool _isLoadingMenu = false;
  bool _hasError = false;

  // --- Getters ---
  Map<String, List<dynamic>> get homeData => _homeData;
  List<Restaurant> get allRestaurants => _allRestaurants;
  Map<int, List<FoodItem>> get menuItems => _menuItems;

  bool get isLoadingHome => _isLoadingHome;
  // ✅ (إصلاح): إضافة Getter ليتوافق مع واجهة المطاعم
  bool get isLoadingRestaurants => _isLoadingHome;

  bool get isLoadingMenu => _isLoadingMenu;
  bool get hasError => _hasError;

  // --- Clear Data ---
  void clearData() {
    _homeData = {};
    _allRestaurants = [];
    _menuItems = {};
    _lastLoadedAreaId = -1;
    _hasError = false;
    notifyListeners();
  }

  // ============================================================
  // 1. جلب بيانات الصفحة الرئيسية (المطاعم) - نظام الكاش الذكي
  // ============================================================
  Future<void> fetchHomeData(int areaId, {bool isRefresh = false}) async {
    _lastLoadedAreaId = areaId;
    _hasError = false;

    // أ) محاولة التحميل من الكاش أولاً (للعرض الفوري)
    if (!isRefresh && _homeData.isEmpty) {
      await _loadHomeFromCache(areaId);
    }

    // إذا كانت البيانات فارغة حتى بعد محاولة الكاش، نُظهر التحميل
    if (_homeData.isEmpty) {
      _isLoadingHome = true;
      notifyListeners();
    }

    // ب) التحقق من صلاحية الكاش (Time-based Caching)
    // إذا كانت البيانات موجودة ومر أقل من 5 دقائق، نكتفي بالكاش
    if (!isRefresh && await _isCacheValid('${AppConstants.CACHE_TIMESTAMP_PREFIX}home_$areaId', minutes: 1400)) {
      print("✅ استخدام الكاش للمطاعم (البيانات حديثة)");
      _isLoadingHome = false;
      notifyListeners();
      return;
    }

    // ج) طلب البيانات الحديثة من السيرفر (في الخلفية)
    try {
      final results = await Future.wait([
        _apiService.getRawDeliverableIds(areaId), // String JSON
        _apiService.getRawRestaurants(areaId),    // String JSON
      ]);

      final deliverableJson = results[0];
      final restaurantsJson = results[1];

      // 1. معالجة البيانات وتحديث الواجهة
      _processAndSetHomeData(deliverableJson, restaurantsJson);

      // 2. حفظ النسخة الجديدة في الكاش
      await _saveHomeToCache(areaId, deliverableJson, restaurantsJson);

    } catch (e) {
      print("⚠️ فشل تحديث المطاعم من الشبكة: $e");
      // إذا لم يكن لدينا بيانات قديمة (من الكاش)، نظهر رسالة خطأ
      if (_homeData.isEmpty) _hasError = true;
    } finally {
      _isLoadingHome = false;
      notifyListeners();
    }
  }

  // --- دالة لجلب كل المطاعم (تستخدم نفس منطق الرئيسية) ---
  Future<void> fetchAllRestaurants(int areaId, {bool isRefresh = false}) async {
    await fetchHomeData(areaId, isRefresh: isRefresh);
  }

  // --- دالة مساعدة: معالجة JSON المطاعم ---
  void _processAndSetHomeData(String deliverableJson, String restaurantsJson) {
    try {
      // 1. تحليل IDs المطاعم التي توصل للمنطقة
      final deliverableList = json.decode(deliverableJson) as List;
      final Set<int> deliverableIds = deliverableList.map<int>((item) => item['id']).toSet();

      // 2. تحليل قائمة المطاعم الكاملة
      final restaurantsList = json.decode(restaurantsJson) as List;
      List<Restaurant> parsedRestaurants = restaurantsList.map((json) => Restaurant.fromJson(json)).toList();

      // 3. ضبط حالة التوصيل (isDeliverable)
      for (var r in parsedRestaurants) {
        r.isDeliverable = deliverableIds.contains(r.id);
      }

      // 4. الحفظ في المتغيرات
      _allRestaurants = parsedRestaurants;
      _homeData['restaurants'] = parsedRestaurants;

    } catch (e) {
      print("Error parsing home data: $e");
      throw Exception('Data parsing error');
    }
  }

  // --- دالة مساعدة: تحميل المطاعم من الكاش ---
  Future<void> _loadHomeFromCache(int areaId) async {
    final prefs = await SharedPreferences.getInstance();
    final deliverableJson = prefs.getString('${AppConstants.CACHE_KEY_RESTAURANTS_PREFIX}${areaId}_ids');
    final restaurantsJson = prefs.getString('${AppConstants.CACHE_KEY_RESTAURANTS_PREFIX}${areaId}_list');

    if (deliverableJson != null && restaurantsJson != null) {
      try {
        _processAndSetHomeData(deliverableJson, restaurantsJson);
        notifyListeners(); // تحديث الواجهة فوراً بالبيانات القديمة
        print("📂 تم تحميل المطاعم من الذاكرة المحلية.");
      } catch (e) {
        print("خطأ في قراءة كاش المطاعم: $e");
      }
    }
  }

  // --- دالة مساعدة: حفظ المطاعم في الكاش ---
  Future<void> _saveHomeToCache(int areaId, String deliverableJson, String restaurantsJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${AppConstants.CACHE_KEY_RESTAURANTS_PREFIX}${areaId}_ids', deliverableJson);
    await prefs.setString('${AppConstants.CACHE_KEY_RESTAURANTS_PREFIX}${areaId}_list', restaurantsJson);
    // حفظ وقت التحديث الحالي
    await prefs.setInt('${AppConstants.CACHE_TIMESTAMP_PREFIX}home_$areaId', DateTime.now().millisecondsSinceEpoch);
  }


  // ============================================================
  // 2. جلب قائمة الطعام (المنيو) - نظام الكاش الذكي
  // ============================================================
  Future<void> fetchMenuForRestaurant(int restaurantId, {bool isRefresh = false}) async {
    _hasError = false;

    // أ) التحميل من الكاش أولاً
    if (!isRefresh && !_menuItems.containsKey(restaurantId)) {
      await _loadMenuFromCache(restaurantId);
    }

    if (!_menuItems.containsKey(restaurantId)) {
      _isLoadingMenu = true;
      notifyListeners();
    }

    // ب) التحقق من صلاحية الكاش (مثلاً 10 دقائق للمنيو)
    if (!isRefresh && _menuItems.containsKey(restaurantId) && await _isCacheValid('${AppConstants.CACHE_TIMESTAMP_PREFIX}menu_$restaurantId', minutes: 600)) {
      print("✅ استخدام الكاش للمنيو (البيانات حديثة)");
      _isLoadingMenu = false;
      notifyListeners();
      return;
    }

    // ج) طلب الشبكة
    try {
      final jsonStr = await _apiService.getRawMenu(restaurantId);

      // 1. معالجة وتحديث
      _processAndSetMenu(restaurantId, jsonStr);

      // 2. حفظ في الكاش
      await _saveMenuToCache(restaurantId, jsonStr);

    } catch (e) {
      print("⚠️ فشل تحديث المنيو من الشبكة: $e");
      // إذا لم تكن هناك بيانات، نظهر الخطأ
      if (!_menuItems.containsKey(restaurantId)) {
        _hasError = true;
        _menuItems[restaurantId] = [];
      }
    } finally {
      _isLoadingMenu = false;
      notifyListeners();
    }
  }

  // --- دالة مساعدة: معالجة JSON المنيو ---
  void _processAndSetMenu(int restaurantId, String jsonStr) {
    try {
      final List<dynamic> decoded = json.decode(jsonStr);
      List<FoodItem> items = decoded.map((json) => FoodItem.fromJson(json)).toList();

      // البحث عن المطعم الأب لتحديد حالته (مفتوح/مغلق) وتمريرها للمنتجات
      Restaurant? restaurant = _allRestaurants.firstWhere(
              (r) => r.id == restaurantId,
          orElse: () => Restaurant(id: 0, name: '', imageUrl: '', isOpen: false, autoOpenTime: '', autoCloseTime: '', latitude: 0, longitude: 0)
      );

      // المنتج متاح فقط إذا كان المطعم يوصل للمنطقة + المطعم مفتوح
      bool isAvailable = restaurant.isDeliverable && restaurant.isOpen;

      for (var item in items) {
        item.isDeliverable = isAvailable;
      }

      _menuItems[restaurantId] = items;
    } catch (e) {
      print("Error parsing menu: $e");
      throw Exception('Menu parsing error');
    }
  }

  // --- دالة مساعدة: تحميل المنيو من الكاش ---
  Future<void> _loadMenuFromCache(int restaurantId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('${AppConstants.CACHE_KEY_MENU_PREFIX}$restaurantId');
    if (jsonStr != null) {
      try {
        _processAndSetMenu(restaurantId, jsonStr);
        notifyListeners();
      } catch (e) {
        print("خطأ في كاش المنيو: $e");
      }
    }
  }

  // --- دالة مساعدة: حفظ المنيو في الكاش ---
  Future<void> _saveMenuToCache(int restaurantId, String jsonStr) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${AppConstants.CACHE_KEY_MENU_PREFIX}$restaurantId', jsonStr);
    await prefs.setInt('${AppConstants.CACHE_TIMESTAMP_PREFIX}menu_$restaurantId', DateTime.now().millisecondsSinceEpoch);
  }


  // ============================================================
  // 3. دوال مساعدة عامة
  // ============================================================

  // التحقق من صلاحية الكاش بناءً على الوقت (بديلة لـ _lastFetchTime)
  Future<bool> _isCacheValid(String key, {required int minutes}) async {
    final prefs = await SharedPreferences.getInstance();
    final lastTime = prefs.getInt(key);
    if (lastTime == null) return false;

    final diff = DateTime.now().millisecondsSinceEpoch - lastTime;
    final minutesDiff = diff / 1000 / 60;

    return minutesDiff < minutes;
  }
}
class DashboardProvider with ChangeNotifier {
  Map<String, List<Order>> _orders = {};
  RestaurantRatingsDashboard? _ratingsDashboard;
  Map<int, String> _pickupCodes = {};
  bool _isLoading = false;
  Timer? _timer;

  // ➕ 1. متغير جديد للتحكم في التحديث الذكي
  Timer? _debounceTimer;

  Map<String, List<Order>> get orders => _orders;
  RestaurantRatingsDashboard? get ratingsDashboard => _ratingsDashboard;
  Map<int, String> get pickupCodes => _pickupCodes;
  bool get isLoading => _isLoading;

  // ➕ 2. دالة التحديث الذكي (استخدم هذه عند وصول الإشعارات)
  void triggerSmartRefresh(String token) {
    // إذا وصل إشعار جديد وكان هناك مؤقت يعمل، قم بإلغائه (تصفير العداد)
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    print("⏳ وصل إشعار.. انتظار 3 ثواني قبل التحديث لتجميع الطلبات...");

    // انتظر 3 ثواني، ثم نفذ التحديث مرة واحدة فقط
    _debounceTimer = Timer(const Duration(seconds: 3), () {
      print("🚀 تنفيذ التحديث المجمع الآن!");
      fetchDashboardData(token, silent: true);
    });
  }

  void startAutoRefresh(String token) {
    _timer?.cancel();
    // نكتفي بطلب أولي، ثم نعتمد على الإشعارات والتحديث اليدوي لتخفيف الحمل
    fetchDashboardData(token, silent: true);
  }

  void stopAutoRefresh() {
    _timer?.cancel();
    _debounceTimer?.cancel(); // إيقاف المؤقت الذكي أيضاً
  }

  void setPickupCode(int orderId, String code) {
    _pickupCodes[orderId] = code;
    notifyListeners();
  }

  // إيقاف الأتمتة القديمة
  Future<void> checkAndAutoRequestDelivery(String token) async {
    // 🚫 Disabled
  }

  Future<void> fetchDashboardData(String? token, {bool silent = false}) async {
    if (token == null) return;
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }
    try {
      final ApiService api = ApiService();

      // جلب الكل
      final activeFromServer = await api.getRestaurantOrders(status: 'active', token: token);
      final completedFromServer = await api.getRestaurantOrders(status: 'completed', token: token);

      List<Order> allOrders = [...activeFromServer, ...completedFromServer];
      final ids = <int>{};
      allOrders.retainWhere((x) => ids.add(x.id));

      List<Order> finalActive = [];
      List<Order> finalCompleted = [];

      // ⛔ القائمة السوداء (الحالات المنتهية فقط)
      final List<String> archiveStatuses = [
        'completed', 'cancelled', 'refunded', 'failed', 'trash'
      ];

      for (var order in allOrders) {
        // ✅ إذا لم يكن منتهياً، اعرضه في النشط فوراً
        if (!archiveStatuses.contains(order.status)) {
          finalActive.add(order);
        } else {
          finalCompleted.add(order);
        }
      }

      finalCompleted.sort((a, b) => b.dateCreated.compareTo(a.dateCreated));
      finalActive.sort((a, b) => b.dateCreated.compareTo(a.dateCreated));

      _orders['active'] = finalActive;
      _orders['completed'] = finalCompleted;

      final ratings = await api.getDashboardRatings(token);
      _ratingsDashboard = ratings;

    } catch (e) {
      print("Error fetching dashboard: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _debounceTimer?.cancel(); // تنظيف الذاكرة
    super.dispose();
  }
}
class RestaurantSettingsProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isRestaurantOpen = true; // حالة الزر اليدوي
  String _operationMode = 'manual'; // الوضع: auto أو manual
  String _openTime = '09:00';
  String _closeTime = '22:00';
  bool _isLoading = false;

  bool get isRestaurantOpen => _isRestaurantOpen;
  String get operationMode => _operationMode; // Getter جديد
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
      _operationMode = settings['operation_mode'] ?? 'manual'; // استقبال الوضع من السيرفر
      _openTime = settings['auto_open_time'] ?? '09:00';
      _closeTime = settings['auto_close_time'] ?? '22:00';

      // (كود حفظ الإحداثيات يبقى كما هو...)
      if (settings['restaurant_info'] != null) {
        // ... نفس الكود السابق ...
      }

    } catch (e) {
      print("Error fetching settings: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // الدالة المحدثة: تقبل mode و isOpen
  Future<bool> updateRestaurantStatus(String? token, String mode, bool isOpen) async {
    if (token == null) return false;

    // تحديث الواجهة فوراً (Optimistic UI)
    String oldMode = _operationMode;
    bool oldStatus = _isRestaurantOpen;

    _operationMode = mode;
    _isRestaurantOpen = isOpen;
    notifyListeners();

    try {
      // استدعاء دالة API الجديدة
      final success = await _apiService.updateRestaurantStatusFull(token, mode, isOpen);
      if (!success) {
        // تراجع في حالة الفشل
        _operationMode = oldMode;
        _isRestaurantOpen = oldStatus;
        notifyListeners();
      }
      return success;
    } catch (e) {
      _operationMode = oldMode;
      _isRestaurantOpen = oldStatus;
      notifyListeners();
      return false;
    }
  }

  // ... (باقي الدوال: updateAutoTimes, clearData كما هي) ...
  Future<bool> updateAutoTimes(String? token, String openTime, String closeTime) async {
    // ... نفس الكود القديم ...
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
    _operationMode = 'manual';
    _openTime = '09:00';
    _closeTime = '22:00';
    notifyListeners();
  }
}
// استبدل كلاس RestaurantProductsProvider بهذا التحديث

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

  // تحديث المنتج (مع الصورة)
  Future<bool> updateProduct(String token, int productId, String name, String price, String salePrice, File? newImage) async {
    _isLoading = true;
    notifyListeners();
    bool success = false;
    try {
      // تم تحديث الدالة لتقبل الصورة
      success = await _apiService.updateMyProduct(token, productId, name, price, salePrice, newImage);
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

  // إضافة منتج جديد
  Future<bool> addProduct(String token, String name, String price, String? salePrice, String description, File? image) async {
    _isLoading = true;
    notifyListeners();
    bool success = false;
    try {
      success = await _apiService.createProduct(token, name, price, salePrice, description, image);
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
    description: 'هذه القناة مخصصة لتنبيه السائقين والمطاعم.',
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
        content: Text("لا يمكن إضافة '${item.name}' إلى السلة لأن المطعم الخاص به مغلق حالياً."),
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
class ApiService {
  final String _authString = 'Basic ${base64Encode(utf8.encode('$CONSUMER_KEY:$CONSUMER_SECRET'))}';
  final CacheService _cacheService = CacheService();

  // =================================================================
  // 🔥🔥🔥 دالة التنفيذ الذكي المعدلة (Exponential Backoff) 🔥🔥🔥
  // =================================================================
  Future<T> _executeWithRetry<T>(Future<T> Function() action) async {
    int attempts = 0;
    while (attempts < 3) {
      try {
        return await action().timeout(API_TIMEOUT);
      } catch (e) {
        attempts++;
        String errorString = e.toString();

        // 🛑 1. فحص الحظر: إذا كان الخطأ 403 (Forbidden) أو 429 (Too Many Requests)
        if (errorString.contains('403') || errorString.contains('429')) {
          print("⛔ تم إيقاف المحاولات فوراً لتجنب الحظر: $errorString");
          rethrow;
        }

        // إذا وصلنا للحد الأقصى، ارمِ الخطأ
        if (attempts >= 3) rethrow;

        // ⏳ 2. الانتظار التصاعدي
        int delaySeconds = pow(2, attempts).toInt();
        print("⚠️ فشل الطلب (محاولة $attempts)، انتظار $delaySeconds ثواني لتهدئة السيرفر...");

        await Future.delayed(Duration(seconds: delaySeconds));
      }
    }
    throw Exception('Failed after multiple retries');
  }






  // 1. جلب بيانات المحفظة والتحديات
  Future<Map<String, dynamic>> getTeamLeaderRewards(String token) async {
    // محاكاة الاتصال بالسيرفر (استبدل هذا برابط الـ API الحقيقي)
    // final response = await http.get(Uri.parse('$BEYTEI_URL/wp-json/leader/v1/rewards'), ...);

    // بيانات وهمية للتجربة (Mock Data)
    await Future.delayed(const Duration(seconds: 1));
    return {
      'wallet': {'my_balance': 150000, 'liability': 25000},
      'challenges': [
        {
          'id': 101,
          'title': 'بطل التوصيل السريع',
          'description': 'أكمل 10 طلبات توصيل في منطقتك خلال ساعتين.',
          'reward_amount': '10,000 د.ع',
          'type': 'urgent',
          'icon_url': 'https://cdn-icons-png.flaticon.com/512/2548/2548523.png'
        },
        {
          'id': 102,
          'title': 'تحدي المسواك',
          'description': 'تأكد من توصيل جميع طلبات المسواك المعلقة قبل الساعة 4 مساءً.',
          'reward_amount': '5,000 د.ع',
          'type': 'market',
          'icon_url': 'https://cdn-icons-png.flaticon.com/512/3081/3081559.png'
        }
      ]
    };
  }

  // 2. الاستجابة للتحدي (قبول أو تجاهل)
  Future<bool> respondToChallenge(String token, int challengeId, String action) async {
    // action = 'accept' or 'ignore'
    /*
    final response = await http.post(
      Uri.parse('$BEYTEI_URL/wp-json/leader/v1/challenge-respond'),
      headers: {'Authorization': 'Bearer $token'},
      body: {'challenge_id': challengeId, 'action': action}
    );
    return response.statusCode == 200;
    */
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }











  Future<bool> updateRestaurantStatusFull(String token, String mode, bool isOpen) async {
    return _executeWithRetry(() async {
      final response = await http.post(
        Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/update-status'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: json.encode({
          'mode': mode,       // auto أو manual
          'is_open': isOpen ? 1 : 0 // 1 أو 0
        }),
      );
      return response.statusCode == 200;
    });
  }




  // =================================================================

  // ✨✨✨ دوال جديدة للتخزين المؤقت (للزبون فقط) ✨✨✨
  // ترجع String (JSON) ليتم حفظها في SharedPreferences

  // 1. جلب قائمة المطاعم كنص خام
  Future<String> getRawRestaurants(int areaId) async {
    const fields = 'id,name,image,count,meta_data';
    // نطلب عدد كبير لضمان تخزين القائمة كاملة
    final url = '$BEYTEI_URL/wp-json/wc/v3/products/categories?parent=0&per_page=100&_fields=$fields&area_id=$areaId';

    return _executeWithRetry(() async {
      final response = await http.get(Uri.parse(url), headers: {'Authorization': _authString});
      if (response.statusCode == 200) return response.body;
      throw Exception('Failed to load restaurants raw');
    });
  }

  // 2. جلب أرقام المطاعم التي توصل للمنطقة (للفلترة) كنص خام
  Future<String> getRawDeliverableIds(int areaId) async {
    final url = '$BEYTEI_URL/wp-json/restaurant-app/v1/restaurants-by-area?area_id=$areaId';
    return _executeWithRetry(() async {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) return response.body;
      throw Exception('Failed to load deliverable IDs raw');
    });
  }

  // 3. جلب المنيو كنص خام
  Future<String> getRawMenu(int restaurantId) async {
    const fields = 'id,name,regular_price,sale_price,images,categories,short_description,average_rating,rating_count,meta_data';
    final url = '$BEYTEI_URL/wp-json/wc/v3/products?category=$restaurantId&per_page=100&_fields=$fields';

    return _executeWithRetry(() async {
      final response = await http.get(Uri.parse(url), headers: {'Authorization': _authString});
      if (response.statusCode == 200) return response.body;
      throw Exception('Failed to load menu raw');
    });
  }
  // ✨✨✨ نهاية الدوال الجديدة ✨✨✨


  // دالة إضافة منتج جديد
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

  // تحديث دالة تعديل المنتج لتقبل الصورة
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

  Future<List<UnifiedDeliveryOrder>> getOrdersByRegion(int areaId, String token) async {
    // ✅ الرابط الجديد الموحد
    final url = '$BEYTEI_URL/wp-json/restaurant-app/v1/region-orders?area_id=$areaId';
    print("🚀 [Team Leader] Fetching: $url");

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

  Future<bool> updateMyLocation(String token, String lat, String lng) async {
    return _executeWithRetry(() async {
      final response = await http.post(
        Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/update-my-location'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: json.encode({
          'lat': lat,
          'lng': lng,
        }),
      );
      return response.statusCode == 200;
    });
  }

  Future<List<Restaurant>> getAllRestaurants({required int areaId}) async {
    const fields = 'id,name,image,count,meta_data';
    final url = '$BEYTEI_URL/wp-json/wc/v3/products/categories?parent=0&per_page=100&page=1&_fields=$fields&area_id=$areaId';
    final cacheKey = 'restaurants_area_${areaId}_page_1_limit_100';

    return _executeWithRetry(() async {
      final response = await http.get(Uri.parse(url), headers: {'Authorization': _authString});
      if (response.statusCode == 200) {
        await _cacheService.saveData(cacheKey, response.body);
        final data = json.decode(response.body) as List;
        return data.map((json) => Restaurant.fromJson(json)).toList();
      }
      throw Exception('Server error ${response.statusCode}');
    });
  }

  Future<Restaurant> getRestaurantById(int restaurantId) async {
    const fields = 'id,name,image,count,meta_data';
    final url = '$BEYTEI_URL/wp-json/wc/v3/products/categories/$restaurantId?_fields=$fields';

    return _executeWithRetry(() async {
      final response = await http.get(Uri.parse(url), headers: {'Authorization': _authString});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final restaurant = Restaurant.fromJson(data);
        restaurant.isDeliverable = true;
        return restaurant;
      }
      throw Exception('Server error ${response.statusCode}');
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

  Future<Set<int>> getDeliverableRestaurantIds(int areaId) async {
    final url = '$BEYTEI_URL/wp-json/restaurant-app/v1/restaurants-by-area?area_id=$areaId';
    return _executeWithRetry(() async {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return (json.decode(response.body) as List).map<int>((item) => item['id']).toSet();
      }
      throw Exception('Failed to fetch deliverable restaurants');
    });
  }

  Future<List<FoodItem>> _getProducts(String params, String cacheKey) async {
    return _executeWithRetry(() async {
      const fields = 'id,name,regular_price,sale_price,images,categories,short_description,average_rating,rating_count,meta_data';
      final url = '$BEYTEI_URL/wp-json/wc/v3/products?$params&_fields=$fields';

      final response = await http.get(Uri.parse(url), headers: {'Authorization': _authString});
      if (response.statusCode == 200) {
        await _cacheService.saveData(cacheKey, response.body);
        return (json.decode(response.body) as List).map((json) => FoodItem.fromJson(json)).toList();
      }
      throw Exception('Failed to fetch products');
    });
  }

  Future<List<FoodItem>> getOnSaleItems() => _getProducts('on_sale=true&per_page=20', 'onsale_items');

  Future<List<FoodItem>> searchProducts({required String query}) => _getProducts('search=$query&per_page=20', 'search_$query');

  Future<List<FoodItem>> getProductsByTag({required String tagName}) async {
    return _executeWithRetry(() async {
      final tagsResponse = await http.get(Uri.parse('$BEYTEI_URL/wp-json/wc/v3/products/tags?search=$tagName&_fields=id'), headers: {'Authorization': _authString});
      if (tagsResponse.statusCode != 200) throw Exception('Failed to find tag');
      final tags = json.decode(tagsResponse.body);
      if (tags.isEmpty) return [];
      final tagId = tags[0]['id'];
      return _getProducts('tag=$tagId&per_page=10', 'tag_$tagId');
    });
  }

  Future<List<FoodItem>> getMenuForRestaurant(int categoryId) =>
      _getProducts('category=$categoryId&per_page=100&page=1', 'menu_${categoryId}_page_1_limit_100');

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

    final body = json.encode(bodyPayload);

    final response = await _executeWithRetry(() => http.post(
        Uri.parse('$BEYTEI_URL/wp-json/wc/v3/orders'),
        headers: {'Authorization': _authString, 'Content-Type': 'application/json'},
        body: body
    ));

    if (response.statusCode == 201) {
      final createdOrder = Order.fromJson(json.decode(response.body));
      await OrderHistoryService().saveOrder(createdOrder);
      return createdOrder;
    } else {
      throw Exception('Failed to submit order: ${response.body}');
    }
  }

  Future<List<Order>> getRestaurantOrders({required String status, required String token}) async {
    return _executeWithRetry(() async {
      final uri = Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/get-orders?status=$status');
      final response = await http.get(uri, headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'});
      if (response.statusCode == 200) {
        return (json.decode(response.body) as List).map((json) => Order.fromJson(json)).toList();
      }
      throw Exception('Failed to load orders: ${response.body}');
    });
  }

  Future<bool> updateOrderStatus(int orderId, String status) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) throw Exception('User not logged in');

    final response = await _executeWithRetry(() => http.post(
      Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/update-order-status/$orderId'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: json.encode({'status': status}),
    ));
    return response.statusCode == 200;
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

  Future<DeliveryConfig> getDeliveryConfig() async {
    return _executeWithRetry(() async {
      final response = await http.get(
        Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/get-delivery-config'),
      );
      if (response.statusCode == 200) {
        return DeliveryConfig.fromJson(json.decode(response.body));
      }
      throw Exception('Failed to load delivery config');
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
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
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
      } else {
        final message = responseBody['message'] ?? 'فشل إرسال طلب التوصيل.';
        throw Exception(message);
      }
    });
  }

  Future<bool> testNotification() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) throw Exception('User not logged in');

    final response = await _executeWithRetry(() => http.post(
      Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/test-notification'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
    ));
    return response.statusCode == 200;
  }
}

class AuthService {
  Future<String?> loginRestaurantOwner(String username, String password) async {
    try {
      final response = await http.post(
          Uri.parse('$BEYTEI_URL/wp-json/jwt-auth/v1/token'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'username': username, 'password': password})
      ).timeout(API_TIMEOUT);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['token'];
        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt_token', token);
          return token;
        }
      }
      return null;
    } catch (e) { return null; }
  }



// استبدل دالة registerDeviceToken القديمة بهذه الجديدة:

// استبدل الدالة القديمة بهذه:
  Future<void> registerDeviceToken({int? areaId}) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. جلب التوكن (إن وجد) والمنطقة
    final jwtToken = prefs.getString('jwt_token');

    // نستخدم المنطقة الممررة، أو نحاول جلبها من الذاكرة
    int? finalAreaId = areaId ?? prefs.getInt('selectedAreaId');

    // 2. جلب FCM Token
    String? fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken == null) return;

    // 3. ✅ الاشتراك في القنوات (Topics) للإرسال الجماعي
    // أ) الاشتراك في القناة العامة (لجميع المستخدمين)
    await FirebaseMessaging.instance.subscribeToTopic('all_users');

    // ب) الاشتراك في قناة المنطقة (إذا تم تحديدها)
    if (finalAreaId != null) {
      await FirebaseMessaging.instance.subscribeToTopic('area_$finalAreaId');
      print("✅ تم الاشتراك في إشعارات المنطقة: area_$finalAreaId");
    }

    // 4. إرسال البيانات للسيرفر (لحفظها في القاعدة للإحصائيات)
    try {
      Map<String, String> headers = {'Content-Type': 'application/json'};

      // إذا كان المستخدم مسجلاً، نرسل التوكن ليتم ربطه بحسابه
      if (jwtToken != null) {
        headers['Authorization'] = 'Bearer $jwtToken';
      }

      // تحديد نوع المنصة (أندرويد أو iOS)
      String platform = Platform.isAndroid ? 'android' : 'ios';

      Map<String, dynamic> body = {
        'token': fcmToken,
        'platform': platform, // 👈 التعديل الجديد: إرسال نوع الجهاز
      };

      // نرسل المنطقة للسيرفر أيضاً
      if (finalAreaId != null) {
        body['area_id'] = finalAreaId;
      }

      await http.post(
        Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/register-device'),
        headers: headers,
        body: json.encode(body),
      ).timeout(API_TIMEOUT);

      print("🚀 تم إرسال توكن الجهاز ($platform) والمنطقة للسيرفر بنجاح.");

    } catch (e) {
      print("Error registering device token: $e");
    }
  }
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token');

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
    await prefs.remove('jwt_token');
    await prefs.remove('selectedAreaId');
    await prefs.remove('selectedAreaName');
  }
}

class TeamLeaderWallet {
  final double myBalance; // رصيدي (لك)
  final double liability; // في ذمتك (عليك)

  TeamLeaderWallet({required this.myBalance, required this.liability});

  factory TeamLeaderWallet.fromJson(Map<String, dynamic> json) {
    return TeamLeaderWallet(
      myBalance: double.tryParse(json['my_balance'].toString()) ?? 0.0,
      liability: double.tryParse(json['liability'].toString()) ?? 0.0,
    );
  }
}

class TeamLeaderChallenge {
  final int id;
  final String title;
  final String description;
  final String rewardAmount; // مثلاً "5,000 د.ع" أو "نقطة"
  final String type; // 'delivery_count', 'urgent', etc.
  final String iconUrl; // رابط صورة الشعار (اختياري)

  TeamLeaderChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.rewardAmount,
    required this.type,
    required this.iconUrl,
  });

  factory TeamLeaderChallenge.fromJson(Map<String, dynamic> json) {
    return TeamLeaderChallenge(
      id: json['id'],
      title: json['title'] ?? 'تحدي جديد',
      description: json['description'] ?? '',
      rewardAmount: json['reward_amount'] ?? '',
      type: json['type'] ?? 'general',
      iconUrl: json['icon_url'] ?? '',
    );
  }
}













class TeamLeaderRewardsScreen extends StatefulWidget {
  final String token;

  const TeamLeaderRewardsScreen({super.key, required this.token});

  @override
  State<TeamLeaderRewardsScreen> createState() => _TeamLeaderRewardsScreenState();
}

class _TeamLeaderRewardsScreenState extends State<TeamLeaderRewardsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  TeamLeaderWallet? _wallet;
  List<TeamLeaderChallenge> _challenges = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getTeamLeaderRewards(widget.token);
      if (mounted) {
        setState(() {
          _wallet = TeamLeaderWallet.fromJson(data['wallet']);
          final list = data['challenges'] as List;
          _challenges = list.map((e) => TeamLeaderChallenge.fromJson(e)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("فشل تحميل البيانات: $e")));
      }
    }
  }

  Future<void> _handleChallengeAction(int id, String action) async {
    // حذف التحدي من القائمة فوراً لإعطاء شعور بالسرعة (Optimistic UI)
    final index = _challenges.indexWhere((c) => c.id == id);
    final removedChallenge = _challenges[index];

    setState(() {
      _challenges.removeAt(index);
    });

    final success = await _apiService.respondToChallenge(widget.token, id, action);

    if (!success && mounted) {
      // إرجاع التحدي في حال فشل الاتصال
      setState(() {
        _challenges.insert(index, removedChallenge);
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("فشل تنفيذ الأمر، حاول مرة أخرى.")));
    } else {
      if(action == 'accept') {
        // عرض تأثير احتفالي بسيط أو رسالة
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم قبول التحدي! بالتوفيق 💪"), backgroundColor: Colors.green));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // خلفية رمادية فاتحة جداً وعصرية
      appBar: AppBar(
        title: const Text("مكافآتي والرصيد", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // --- قسم المحفظات ---
            Row(
              children: [
                // 1. محفظة رصيدي
                Expanded(
                  child: _buildWalletCard(
                    title: "رصيدي",
                    amount: _wallet?.myBalance ?? 0.0,
                    gradientColors: [Colors.teal.shade400, Colors.teal.shade700],
                    icon: Icons.account_balance_wallet,
                    textColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 15),
                // 2. محفظة في ذمتك
                Expanded(
                  child: _buildWalletCard(
                    title: "في ذمتك",
                    amount: _wallet?.liability ?? 0.0,
                    gradientColors: [Colors.orange.shade700, Colors.red.shade800],
                    icon: Icons.warning_amber_rounded,
                    textColor: Colors.white,
                    isLiability: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // --- عنوان التحديات ---
            Row(
              children: [
                const Text(
                  "التحديات النشطة 🔥",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_challenges.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text("${_challenges.length} جديد", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  )
              ],
            ),
            const SizedBox(height: 15),

            // --- قائمة التحديات ---
            if (_challenges.isEmpty)
              _buildEmptyState()
            else
              ..._challenges.map((challenge) => _buildChallengeCard(challenge)).toList(),
          ],
        ),
      ),
    );
  }

  // --- تصميم بطاقة المحفظة ---
  Widget _buildWalletCard({
    required String title,
    required double amount,
    required List<Color> gradientColors,
    required IconData icon,
    required Color textColor,
    bool isLiability = false,
  }) {
    final format = NumberFormat('#,###', 'ar_IQ');
    return Container(
      height: 140,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: gradientColors.last.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Stack(
        children: [
          // زخرفة خلفية
          Positioned(right: -20, top: -20, child: Icon(icon, size: 100, color: Colors.white.withOpacity(0.1))),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, color: Colors.white70, size: 20),
                    const SizedBox(width: 8),
                    Text(title, style: TextStyle(color: textColor.withOpacity(0.9), fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${format.format(amount)} د.ع",
                      style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    if (isLiability)
                      const Text(
                        "يجب تسديدها للمنصة",
                        style: TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- تصميم بطاقة التحدي ---
  Widget _buildChallengeCard(TeamLeaderChallenge challenge) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // الشعار أو الأيقونة
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: challenge.iconUrl.isNotEmpty
                      ? Padding(padding: const EdgeInsets.all(8.0), child: CachedNetworkImage(imageUrl: challenge.iconUrl))
                      : const Icon(Icons.emoji_events, color: Colors.amber, size: 30),
                ),
                const SizedBox(width: 15),
                // النصوص
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(challenge.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text(challenge.description, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade100),
                        ),
                        child: Text(
                          "المكافأة: ${challenge.rewardAmount}",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // الأزرار (قبول / تجاهل)
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => _handleChallengeAction(challenge.id, 'ignore'),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), foregroundColor: Colors.grey),
                    child: const Text("تجاهل"),
                  ),
                ),
                Container(width: 1, height: 30, color: Colors.grey.shade300),
                Expanded(
                  child: TextButton(
                    onPressed: () => _handleChallengeAction(challenge.id, 'accept'),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), foregroundColor: const Color(0xFF1E3C72)),
                    child: const Text("قبول التحدي", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.check_circle_outline, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 15),
          Text("لا توجد تحديات حالياً", style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
          Text("أنت مسيطر على الوضع! 🦁", style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
        ],
      ),
    );
  }
}












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
      message = "عذراً، هذا المطعم لا يوصل إلى منطقتك المحددة حالياً.";
      icon = Icons.location_off_outlined;
      iconColor = Colors.orange.shade700;
    } else if (!restaurant.isOpen) {
      // 2. In zone but closed
      title = "المطعم مغلق حالياً";
      message = "لا يستقبل المطعم طلبات الآن.\n\n"
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
      message = "عذراً، هذا المطعم لا يوصل إلى منطقتك المحددة حالياً.";
      icon = Icons.location_off_outlined;
      iconColor = Colors.orange.shade700;
    } else if (!restaurant.isOpen) { // <-- ✨ تم التعديل هنا
      // 2. داخل المنطقة ولكنه مغلق
      title = "المطعم مغلق حالياً";
      message = "لا يستقبل المطعم طلبات الآن.\n\n"
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
                          label: const Text(' عرض المنيو', style: TextStyle(fontSize: 12)),
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

  // 🔥 الحيلة الذكية: قبول + نقل للمكتملة + طلب تكسي (مع ضمان الاسم)
  Future<void> _acceptAndAutoRequestTaxi() async {
    setState(() => _isUpdating = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // 1. نقل الطلب إلى "المكتملة" فوراً
      final statusSuccess = await _apiService.updateOrderStatus(widget.order.id, 'completed');
      if (!statusSuccess) throw Exception("فشل تحديث حالة الطلب");

      // 2. تجهيز البيانات
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final rLat = prefs.getDouble('restaurant_lat');
      final rLng = prefs.getDouble('restaurant_lng');

      // ✅ [تعديل هام]: جلب الاسم مع التحقق الصارم
      String rName = prefs.getString('restaurant_name') ?? '';

      // إذا فشل جلب الاسم لأي سبب، نضع العبارة المطلوبة بدلاً من اسم افتراضي
      if (rName.isEmpty || rName == 'null') {
        rName = '⚠️ غير معروف - تواصل مع الدعم';
      }

      if (token != null && rLat != null && rLng != null) {

        // تثبيت السعر عند 1000 أو حسب الفاتورة
        String deliveryFee = "1000";
        if (widget.order.shippingTotal != "0" && widget.order.shippingTotal.isNotEmpty) {
          deliveryFee = widget.order.shippingTotal;
        }

        // إحداثيات الزبون
        double destLat = 0.0;
        double destLng = 0.0;
        if (widget.order.destinationLat != null && widget.order.destinationLat!.isNotEmpty) {
          destLat = double.tryParse(widget.order.destinationLat!) ?? 0.0;
          destLng = double.tryParse(widget.order.destinationLng!) ?? 0.0;
        }

        // ملاحظات السائق
        String notes = "توصيل طلب مطعم #${widget.order.id}";
        if (destLat == 0) {
          notes += "\n⚠️ تنبيه: الموقع غير محدد، اعتمد على العنوان النصي.";
        }
        // إضافة تنبيه للسائق في الملاحظات أيضاً إذا كان الاسم مفقوداً
        if (rName.contains('تواصل مع الدعم')) {
          notes += "\n🚨 تنبيه هام: اسم المطعم غير ظاهر، يرجى الاتصال بالدعم أو المطعم.";
        }

        // 3. إرسال طلب التكسي
        await _apiService.createUnifiedDeliveryRequest(
          token: token,
          sourceType: 'restaurant',
          sourceOrderId: widget.order.id.toString(),
          pickupName: rName, // ✅ الاسم الصحيح أو رسالة الدعم
          pickupLat: rLat,
          pickupLng: rLng,
          destinationAddress: widget.order.address,
          destinationLat: destLat,
          destinationLng: destLng,
          deliveryFee: deliveryFee,
          orderDescription: notes,
          endCustomerPhone: widget.order.phone,
        );

        // 4. إظهار رسالة النجاح
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 60),
                  const SizedBox(height: 10),
                  const Text("تم القبول والنقل!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(
                      "تم طلب المندوب باسم:\n($rName)\nوتم نقل الطلب للأرشيف ✅",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15, color: Colors.blueGrey)
                  ),
                ],
              ),
            ),
          );

          Future.delayed(const Duration(seconds: 2), () {
            if (mounted && Navigator.canPop(context)) Navigator.pop(context);
            widget.onStatusChanged();
          });
        }
      } else {
        widget.onStatusChanged();
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('تم النقل للمكتملة (بيانات الموقع ناقصة لطلب التكسي)'), backgroundColor: Colors.orange));
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

            if (!widget.isCompleted && widget.order.status != 'out-for-delivery')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline, size: 18),
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

            if (widget.order.status == 'out-for-delivery' || (widget.isCompleted && widget.pickupCode != null))
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                color: Colors.green.shade50,
                child: const Center(child: Text("✅ الطلب مكتمل / تم إرسال المندوب", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
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

class TeamLeaderOrderCard extends StatefulWidget {
  final UnifiedDeliveryOrder order;
  final String token; // توكن التيم ليدر
  final VoidCallback onActionComplete; // لتحديث القائمة بعد التدخل

  const TeamLeaderOrderCard({
    super.key,
    required this.order,
    required this.token,
    required this.onActionComplete,
  });

  @override
  State<TeamLeaderOrderCard> createState() => _TeamLeaderOrderCardState();
}

class _TeamLeaderOrderCardState extends State<TeamLeaderOrderCard> {
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  // 🔥 وظيفة التدخل السريع (قبول نيابة عن المطعم)
  Future<void> _interveneAndRequestTaxi() async {
    setState(() => _isLoading = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // 1. تغيير حالة الطلب في ووكومرس إلى "مكتمل" (Completed)
      // ملاحظة: التيم ليدر يقوم بذلك بتوكينه الخاص (يجب أن يسمح السيرفر بذلك)
      final statusSuccess = await _apiService.updateOrderStatus(widget.order.id, 'completed');
      if (!statusSuccess) throw Exception("فشل تحديث حالة الطلب في النظام");

      // 2. إنشاء طلب التوصيل (التكسي) باستخدام بيانات الطلب الموجودة
      // نستخدم بيانات المطعم الموجودة في الـ Order نفسه
      await _apiService.createUnifiedDeliveryRequest(
        token: widget.token,
        sourceType: widget.order.sourceType, // نرسل نفس نوع المصدر (مطعم/مسواك)
        sourceOrderId: widget.order.id.toString(),
        pickupName: widget.order.pickupName, // اسم المطعم
        pickupLat: double.tryParse(widget.order.pickupLat) ?? 0.0,
        pickupLng: double.tryParse(widget.order.pickupLng) ?? 0.0,
        destinationAddress: widget.order.destinationAddress,
        destinationLat: double.tryParse(widget.order.destLat) ?? 0.0,
        destinationLng: double.tryParse(widget.order.destLng) ?? 0.0,
        deliveryFee: widget.order.deliveryFee.toStringAsFixed(0), // السعر الموجود
        orderDescription: "تم القبول بواسطة التيم ليدر 👮\n${widget.order.description}",
        endCustomerPhone: widget.order.customerPhone, // رقم الزبون
      );

      // 3. نجاح العملية
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("تم الإنقاذ بنجاح! 👮‍♂️"),
            content: const Text("تم قبول الطلب وطلب المندوب نيابة عن المطعم."),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("حسناً"))
            ],
          ),
        );
        widget.onActionComplete(); // تحديث القائمة لإخفاء الطلب
      }

    } catch (e) {
      if (mounted) scaffoldMessenger.showSnackBar(SnackBar(content: Text("خطأ: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) await launchUrl(launchUri);
  }

  @override
  Widget build(BuildContext context) {
    // تحديد نوع المصدر للتلوين
    Color color = Colors.blue;
    IconData icon = Icons.info;
    if (widget.order.sourceType == 'restaurant') { color = Colors.orange; icon = Icons.restaurant; }
    else if (widget.order.sourceType == 'market') { color = Colors.purple; icon = Icons.shopping_basket; }

    // التحقق هل الطلب يحتاج تدخل (نشط) أم منتهي
    bool isActive = !['completed', 'cancelled', 'refunded', 'failed', 'trash', 'out-for-delivery'].contains(widget.order.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // الرأس
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  avatar: Icon(icon, size: 16, color: Colors.white),
                  label: Text("#${widget.order.id}"),
                  backgroundColor: color,
                  labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Text(
                  "${NumberFormat('#,###').format(widget.order.deliveryFee)} د.ع",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                ),
              ],
            ),
            const Divider(),

            // التفاصيل
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text("من: ${widget.order.pickupName}", style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("إلى: ${widget.order.destinationAddress}"),
              trailing: IconButton(
                icon: const Icon(Icons.phone, color: Colors.green),
                onPressed: () => _makePhoneCall(widget.order.customerPhone),
              ),
            ),

            if(widget.order.itemsSummary.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                color: Colors.grey.shade100,
                child: Text(widget.order.itemsSummary, style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
              ),

            const SizedBox(height: 10),

            // 🔥 أزرار التحكم (تظهر فقط للطلبات المعلقة)
            if (isActive)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.flash_on, size: 18),
                      label: const Text("قبول وتجهيز (نيابة)"),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent.shade700,
                          foregroundColor: Colors.white,
                          elevation: 0
                      ),
                      onPressed: _isLoading ? null : _interveneAndRequestTaxi,
                    ),
                  ),
                ],
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(vertical: 5),
                width: double.infinity,
                color: Colors.green.shade50,
                child: const Text("✅ حالة الطلب مستقرة", textAlign: TextAlign.center, style: TextStyle(color: Colors.green)),
              )
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
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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

      // 2. تحديث البيانات باستخدام "التحديث الذكي"
      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        if (authProvider.isLoggedIn && authProvider.token != null) {
          print("🔔 إشعار جديد وصل! تفعيل التحديث الذكي (Smart Refresh)...");

          // ✨✨✨ التعديل الجوهري هنا ✨✨✨
          // استخدام triggerSmartRefresh لتجميع الطلبات المتتالية في طلب واحد للسيرفر
          Provider.of<DashboardProvider>(context, listen: false)
              .triggerSmartRefresh(authProvider.token!);

          // 💡 ملاحظة: تم إيقاف تحديث الإعدادات (Settings) مع كل إشعار لتخفيف الضغط،
          // لأن الإعدادات لا تتغير عادةً عند وصول طلب جديد.
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Providers الأساسية
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => RestaurantSettingsProvider()),
        ChangeNotifierProvider(create: (_) => DeliveryProvider()),

        // Providers المعتمدة على AuthProvider (Proxy)

        // 1. ربط DashboardProvider
        ChangeNotifierProxyProvider<AuthProvider, DashboardProvider>(
          create: (_) => DashboardProvider(),
          update: (_, auth, dashboard) {
            if(auth.isLoggedIn && dashboard != null && auth.token != null) {
              // عند بدء التطبيق، نعتمد على التحديث الذكي أو اليدوي
              // تم إيقاف startAutoRefresh الدورية لتخفيف الحمل
              dashboard.fetchDashboardData(auth.token!, silent: true);
            }
            return dashboard!;
          },
        ),

        // 2. ربط RestaurantSettingsProvider
        ChangeNotifierProxyProvider<AuthProvider, RestaurantSettingsProvider>(
          create: (_) => RestaurantSettingsProvider(),
          update: (_, auth, settings) {
            if(settings != null && auth.isLoggedIn && auth.token != null) {
              settings.fetchSettings(auth.token);
            } else if (settings != null && !auth.isLoggedIn) {
              settings.clearData();
            }
            return settings!;
          },
        ),

        // 3. ربط RestaurantProductsProvider
        ChangeNotifierProxyProvider<AuthProvider, RestaurantProductsProvider>(
          create: (_) => RestaurantProductsProvider(),
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
        home: const AuthWrapper(),
      ),
    );
  }
}// ✨ NEW: Restaurant Settings Screen
class RestaurantSettingsScreen extends StatefulWidget {
  const RestaurantSettingsScreen({super.key});

  @override
  State<RestaurantSettingsScreen> createState() => _RestaurantSettingsScreenState();
}

class _RestaurantSettingsScreenState extends State<RestaurantSettingsScreen> {

  // دالة لتحديث الوضع (Auto/Manual) والحالة (Open/Closed)
  Future<void> _updateSettings(RestaurantSettingsProvider provider, {required String mode, required bool isOpen}) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // ملاحظة: نحتاج لتحديث دالة updateOpenStatus في البروفايدر لتقبل mode أيضاً
    // سأكتب لك تحديث البروفايدر في الأسفل، هنا نفترض أنها تقبل المعاملات
    final success = await provider.updateRestaurantStatus(token, mode, isOpen);

    if (success) {
      String message = "";
      if (mode == 'auto') {
        message = "تم تفعيل الجدول التلقائي. سيفتح ويغلق حسب الوقت.";
      } else {
        message = isOpen ? "تم فتح المطعم يدوياً." : "تم إغلاق المطعم يدوياً.";
      }
      scaffoldMessenger.showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.green));
    } else {
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('فشل تحديث الإعدادات.'), backgroundColor: Colors.red));
    }
  }

  Future<void> _showTimePicker(BuildContext context, RestaurantSettingsProvider provider, bool isOpeningTime) async {
    // التأكد من تنسيق الوقت لتجنب الأخطاء
    TimeOfDay initialTime;
    try {
      final timeStr = isOpeningTime ? provider.openTime : provider.closeTime;
      final parts = timeStr.split(':');
      initialTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      initialTime = const TimeOfDay(hour: 9, minute: 0);
    }

    final TimeOfDay? newTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (newTime != null) {
      final hour24 = newTime.hour;
      final minute = newTime.minute;
      final formattedTime24 = '${hour24.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final String newOpenTime = isOpeningTime ? formattedTime24 : provider.openTime;
      final String newCloseTime = isOpeningTime ? provider.closeTime : formattedTime24;

      final success = await provider.updateAutoTimes(token, newOpenTime, newCloseTime);

      if (mounted) {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        if (success) {
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

        // تحديد حالة الأزرار بناءً على البيانات القادمة من السيرفر
        bool isAutoMode = provider.operationMode == 'auto';
        bool isManualOpen = provider.isRestaurantOpen; // هذه تمثل الزر اليدوي

        return RefreshIndicator(
          onRefresh: () async {
            final token = Provider.of<AuthProvider>(context, listen: false).token;
            await provider.fetchSettings(token);
          },
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // بطاقة نظام التشغيل
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("نظام التشغيل", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Divider(),

                      // 1. زر التبديل بين التلقائي واليدوي
                      SwitchListTile(
                        title: const Text("تفعيل الجدول التلقائي"),
                        subtitle: const Text("يفتح ويغلق تلقائياً حسب الأوقات المحددة بالأسفل."),
                        value: isAutoMode,
                        activeColor: Colors.blue,
                        onChanged: (val) {
                          // إذا فعلنا التلقائي -> نرسل auto ونحتفظ بالحالة الحالية
                          // إذا عطلنا التلقائي -> نرسل manual
                          String newMode = val ? 'auto' : 'manual';
                          _updateSettings(provider, mode: newMode, isOpen: isManualOpen);
                        },
                      ),

                      // 2. زر التحكم اليدوي (يظهر فقط إذا كان الوضع يدوي)
                      AnimatedCrossFade(
                        firstChild: Container(), // نخفيه في الوضع التلقائي
                        secondChild: Column(
                          children: [
                            const Divider(),
                            SwitchListTile(
                              title: Text(
                                isManualOpen ? 'المطعم: مفتوح الآن 🟢' : 'المطعم: مغلق الآن 🔴',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isManualOpen ? Colors.green : Colors.red
                                ),
                              ),
                              subtitle: const Text("تحكم يدوي كامل (تجاوز التوقيت)."),
                              value: isManualOpen,
                              activeColor: Colors.green,
                              inactiveThumbColor: Colors.red,
                              onChanged: (val) {
                                // هنا الوضع manual دائماً لأننا في هذا الجزء
                                _updateSettings(provider, mode: 'manual', isOpen: val);
                              },
                            ),
                          ],
                        ),
                        crossFadeState: isAutoMode ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                        duration: const Duration(milliseconds: 300),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // بطاقة تحديد الأوقات
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("إعدادات الجدول التلقائي", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text(
                        isAutoMode ? "النظام يعمل وفق هذه الأوقات حالياً." : "هذه الأوقات غير مفعلة لأن الوضع يدوي.",
                        style: TextStyle(fontSize: 12, color: isAutoMode ? Colors.green : Colors.grey),
                      ),
                      const Divider(),
                      ListTile(
                        title: const Text('وقت الفتح'),
                        trailing: Text(provider.openTime, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        leading: const Icon(Icons.wb_sunny_outlined),
                        onTap: () => _showTimePicker(context, provider, true),
                      ),
                      const Divider(),
                      ListTile(
                        title: const Text('وقت الإغلاق'),
                        trailing: Text(provider.closeTime, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        leading: const Icon(Icons.nightlight_round),
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
    return const LocationCheckWrapper();
  }
}
class LocationCheckWrapper extends StatefulWidget {
  const LocationCheckWrapper({super.key});
  @override
  State<LocationCheckWrapper> createState() => _LocationCheckWrapperState();
}

class _LocationCheckWrapperState extends State<LocationCheckWrapper> {
  Future<int?> _checkLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('selectedAreaId');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int?>(
      future: _checkLocation(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const SplashScreen();
        if (snapshot.hasData && snapshot.data != null) return const MainScreen();
        return const WelcomeScreen();
      },
    );
  }
}

// =======================================================================
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
                const Text( "أهلاً بك في مطاعم بيتي", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center, ),
                const SizedBox(height: 10),
                const Text( "لتصفح المطاعم، الرجاء تحديد منطقة التوصيل أولاً", style: TextStyle(fontSize: 16, color: Colors.white70), textAlign: TextAlign.center, ),
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
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [GlobalKey<NavigatorState>(), GlobalKey<NavigatorState>(), GlobalKey<NavigatorState>(), GlobalKey<NavigatorState>()];

  @override
  Widget build(BuildContext context) {
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
        body: IndexedStack(
          index: navProvider.currentIndex,
          children: <Widget>[_buildOffstageNavigator(0), _buildOffstageNavigator(1), _buildOffstageNavigator(2), _buildOffstageNavigator(3)],
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
            case 0: pageBuilder = const HomeScreen(); break;
            case 1: pageBuilder = const RestaurantsScreen(); break;
            case 2: pageBuilder = const OrdersHistoryScreen(); break;
            case 3: pageBuilder = const CartScreen(); break;
            default: pageBuilder = const HomeScreen();
          }
          return MaterialPageRoute(builder: (context) => pageBuilder, settings: settings);
        },
      ),
    );
  }

  Widget _buildCustomBottomNav(NavigationProvider navProvider) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      items: <BottomNavigationBarItem>[
        const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'الرئيسية'),
        const BottomNavigationBarItem(icon: Icon(Icons.store_outlined), activeIcon: Icon(Icons.store), label: 'المطاعم'),
        const BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history), label: 'طلباتي'),
        BottomNavigationBarItem(
          icon: Consumer<CartProvider>(builder: (context, cart, child) => Badge(isLabelVisible: cart.cartCount > 0, label: Text(cart.cartCount.toString()), child: const Icon(Icons.shopping_cart_outlined))),
          activeIcon: Consumer<CartProvider>(builder: (context, cart, child) => Badge(isLabelVisible: cart.cartCount > 0, label: Text(cart.cartCount.toString()), child: const Icon(Icons.shopping_cart))),
          label: 'السلة',
        ),
      ],
      currentIndex: navProvider.currentIndex,
      onTap: navProvider.changeTab,
    );
  }
}
// (في ملف re.dart)
// (في ملف re.dart)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  // صور البانر الإعلاني
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

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    _selectedAreaId = prefs.getInt('selectedAreaId');
    _selectedAreaName = prefs.getString('selectedAreaName');

    // جلب بيانات الصفحة الرئيسية بناءً على المنطقة
    if (_selectedAreaId != null) {
      Provider.of<CustomerProvider>(context, listen: false)
          .fetchHomeData(_selectedAreaId!, isRefresh: false);
    }
    setState(() {});
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

  // --- 🚀 بناء الواجهة ---
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
              _selectedAreaId = prefs.getInt('selectedAreaId');
              _selectedAreaName = prefs.getString('selectedAreaName');
              setState(() {});
              if (_selectedAreaId != null) {
                Provider.of<CustomerProvider>(context, listen: false)
                    .fetchHomeData(_selectedAreaId!, isRefresh: true);
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

        // ✨✨✨ المنطقة الذكية للأزرار (الحل الجذري) ✨✨✨
        actions: [
          Consumer<AuthProvider>(
            builder: (context, auth, child) {
              // الحالة 1: المستخدم غير مسجل دخول (زائر)
              if (!auth.isLoggedIn) {
                return Row(
                  children: [
                    // زر دخول التيم ليدر
                    IconButton(
                      icon: const Icon(Icons.admin_panel_settings_outlined, color: Colors.blueGrey),
                      tooltip: "دخول قائد الفريق",
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const TeamLeaderLoginScreen())
                      ),
                    ),
                    // زر دخول مدير المطعم
                    IconButton(
                      icon: const Icon(Icons.store, color: Colors.teal),
                      tooltip: "دخول مدير المطعم",
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const RestaurantLoginScreen())
                      ),
                    ),
                  ],
                );
              }

              // الحالة 2: مسجل دخول بصفة (Team Leader)
              else if (auth.userRole == 'leader') {
                return IconButton(
                  icon: const Icon(Icons.dashboard_customize, color: Colors.amber, size: 28),
                  tooltip: "لوحة المراقبة (Team Leader)",
                  onPressed: () {
                    // ✅ التعديل: الانتقال المباشر للوحة التحكم (بدون اختيار منطقة)
                    if (auth.token != null) {
                      Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => RegionDashboardScreen(
                            token: auth.token!,
                            areaId: 0, // نرسل صفر، والسيرفر يعرف المنطقة من حساب التيم ليدر
                            areaName: "منطقتك المسؤولة",
                          ))
                      );
                    }
                  },
                );
              }
              // الحالة 3: مسجل دخول بصفة (Restaurant Owner)
              else {
                return IconButton(
                  icon: const Icon(Icons.dashboard, color: Colors.teal, size: 28),
                  tooltip: "لوحة تحكم المطعم",
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RestaurantDashboardScreen())
                  ),
                );
              }
            },
          ),
        ],
      ),

      // --- جسم الصفحة (عرض المطاعم للجميع) ---
      body: Consumer<CustomerProvider>(
        builder: (context, provider, child) {
          if (_selectedAreaId == null) {
            return const Center(child: Text("يرجى تحديد منطقة لعرض المطاعم"));
          }

          if (provider.hasError && provider.homeData.isEmpty) {
            return NetworkErrorWidget(
                message: 'تحقق من اتصال الانترنيت .',
                onRetry: () => provider.fetchHomeData(_selectedAreaId!,
                    isRefresh: true));
          }

          // تجهيز البيانات
          final restaurants =
          (provider.homeData['restaurants'] as List<dynamic>? ?? [])
              .cast<Restaurant>();

          return RefreshIndicator(
            onRefresh: () =>
                provider.fetchHomeData(_selectedAreaId!, isRefresh: true),
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
                  child: Text("المطاعم المتاحة",
                      style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),

                Expanded(
                  child: () {
                    // حالة التحميل الأولي
                    if (provider.isLoadingHome && restaurants.isEmpty) {
                      return _buildRestaurantGridShimmer();
                    }
                    // حالة لا توجد بيانات
                    if (!provider.isLoadingHome && restaurants.isEmpty) {
                      return const Center(
                          child: Text("لا توجد مطاعم متاحة حالياً في هذه المنطقة"));
                    }

                    // عرض المطاعم
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
                      itemCount: restaurants.length,
                      itemBuilder: (context, index) {
                        return RestaurantCard(restaurant: restaurants[index]);
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

  // --- الدوال المساعدة (كما هي) ---

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
          hintText: 'ابحث عن وجبة أو مطعم...',
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
  bool _hasError = false;

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
    setState(() { _isLoading = true; _hasError = false; });
    try {
      final areas = await _apiService.getAreas();
      if (mounted) setState(() { _allAreas = areas; _filteredAreas = areas; });
    } catch (e) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterAreas() {
    final query = _searchController.text.toLowerCase();
    setState(() => _filteredAreas = _allAreas.where((area) => area.name.toLowerCase().contains(query)).toList());
  }

// داخل _SelectLocationScreenState

  Future<void> _saveSelection(int areaId, String areaName) async {
    // إظهار مؤشر تحميل بسيط فوق الزر أو منع النقر المتكرر (اختياري)
    // لكننا نريد الانتقال فوراً

    final prefs = await SharedPreferences.getInstance();

    // 1. حفظ البيانات محلياً (عملية سريعة جداً - أجزاء من الثانية)
    await prefs.setInt('selectedAreaId', areaId);
    await prefs.setString('selectedAreaName', areaName);

    // 2. 🔥 الحل السحري: تشغيل تسجيل الجهاز في الخلفية (بدون await)
    // لا ننتظر اكتمال هذه العملية للانتقال للصفحة التالية
    AuthService().registerDeviceToken(areaId: areaId).then((_) {
      print("✅ تم تسجيل الجهاز في الخلفية بنجاح");
    }).catchError((e) {
      print("⚠️ فشل تسجيل الجهاز في الخلفية (غير مؤثر على تجربة المستخدم): $e");
    });

    // إلغاء الاشتراك القديم أيضاً في الخلفية
    int? oldAreaId = prefs.getInt('selectedAreaId');
    if (oldAreaId != null && oldAreaId != areaId) {
      FirebaseMessaging.instance.unsubscribeFromTopic('area_$oldAreaId');
    }

    // 3. الانتقال فوراً للصفحة التالية
    if (mounted) {
      if (widget.isCancellable) {
        Navigator.of(context).pop(true);
      } else {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LocationCheckWrapper()),
                (route) => false
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final governorates = _filteredAreas.where((a) => a.parentId == 0).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('اختر منطقة التوصيل'), automaticallyImplyLeading: widget.isCancellable),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(controller: _searchController, decoration: InputDecoration(hintText: 'ابحث عن مدينتك...', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none), filled: true, fillColor: Colors.grey.shade200)),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _hasError
                ? NetworkErrorWidget(message: "فشل تحميل المناطق", onRetry: _loadAreas)
                : ListView.builder(
              itemCount: governorates.length,
              itemBuilder: (context, index) {
                final governorate = governorates[index];
                final cities = _filteredAreas.where((a) => a.parentId == governorate.id).toList();
                return ExpansionTile(
                  title: Text(governorate.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  children: cities.map((city) => ListTile(title: Text(city.name), onTap: () => _saveSelection(city.id, city.name))).toList(),
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
    _selectedAreaId = prefs.getInt('selectedAreaId');
    if (_selectedAreaId != null) {
      Provider.of<CustomerProvider>(context, listen: false).fetchAllRestaurants(_selectedAreaId!, isRefresh: isRefresh);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المطاعم')),
      body: Consumer<CustomerProvider>(
        builder: (context, provider, child) {
          if (_selectedAreaId == null) return const Center(child: Text("يرجى تحديد منطقة أولاً."));

          if (provider.isLoadingRestaurants && provider.allRestaurants.isEmpty) {
            return GridView.builder(padding: const EdgeInsets.all(15), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 0.7), itemCount: 6, itemBuilder: (context, index) => const ShimmerRestaurantCard());
          }
          if (provider.hasError && provider.allRestaurants.isEmpty) {
            return NetworkErrorWidget(message: 'فشل في جلب المطاعم', onRetry: () => _loadInitialData(isRefresh: true));
          }
          if (provider.allRestaurants.isEmpty) {
            return const Center(child: Text("لا توجد مطاعم متاحة حالياً"));
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
      Provider.of<CustomerProvider>(context, listen: false).fetchMenuForRestaurant(widget.restaurant.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.restaurant.name)),
      body: Consumer<CustomerProvider>(
        builder: (context, provider, child) {
          final menu = provider.menuItems[widget.restaurant.id] ?? [];

          if (provider.isLoadingMenu && menu.isEmpty) {
            return GridView.builder(padding: const EdgeInsets.all(15), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 0.75), itemCount: 8, itemBuilder: (context, index) => const ShimmerFoodCard());
          }
          if (provider.hasError && menu.isEmpty) {
            return NetworkErrorWidget(message: 'فشل في جلب قائمة الطعام', onRetry: () => provider.fetchMenuForRestaurant(widget.restaurant.id, isRefresh: true));
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
            return const Center(child: Text("لا توجد وجبات في هذا المطعم حالياً"));
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

        final provider = Provider.of<CustomerProvider>(context, listen: false);
        final statusMap = { for (var r in provider.allRestaurants) r.id : r.isOpen };

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
    final provider = Provider.of<CustomerProvider>(context, listen: false);
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
    return Scaffold(
        appBar: AppBar(title: const Text('سلتي')),
        body: Consumer<CartProvider>(
            builder: (context, cart, child) {
              if (cart.items.isEmpty) return const Center(child: Text('سلّتك فارغة!', style: TextStyle(fontSize: 18, color: Colors.grey)));
              return Column(children: [
                Expanded(child: ListView.builder(padding: const EdgeInsets.all(15), itemCount: cart.items.length, itemBuilder: (context, index) => _buildCartItemCard(context, cart, cart.items[index]))),
                _buildCheckoutSection(context, cart)
              ]);
            }
        )
    );
  }

  // (دالة بناء ملخص السعر - تم تعديلها)
  Widget _buildPriceSummary(CartProvider cart, double? deliveryFee, bool isCalculatingFee, String feeMessage) {
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
              Text('$totalFormatted د.ع', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          if (cart.totalDiscountAmount > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('الخصم', style: TextStyle(fontSize: 14, color: Theme.of(context).primaryColor)),
                Text('- $discountFormatted د.ع', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
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
                transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                child: isCalculatingFee
                    ? const SizedBox(key: ValueKey('calc'), width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(
                  deliveryFee != null ? '${NumberFormat('#,###', 'ar_IQ').format(deliveryFee)} د.ع' : '---',
                  key: const ValueKey('fee'),
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: deliveryFee == null && !isCalculatingFee ? Colors.red : Colors.black
                  ),
                ),
              ),
            ],
          ),
          // [الإصلاح] إظهار رسالة الخطأ أو "الرجاء تحديد الموقع"
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
              const Text('الإجمالي المطلوب دفعه', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: isCalculatingFee || deliveryFee == null
                    ? const SizedBox.shrink()
                    : Text(
                  '$finalTotalFormatted د.ع',
                  key: ValueKey(finalTotalFormatted),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),

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
  }  Widget _buildCartItemCard(BuildContext context, CartProvider cart, FoodItem item) {
    return Card(margin: const EdgeInsets.only(bottom: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), child: Padding(padding: const EdgeInsets.all(10.0), child: Row(children: [
      ClipRRect(borderRadius: BorderRadius.circular(10), child: CachedNetworkImage(imageUrl: item.imageUrl, width: 80, height: 80, fit: BoxFit.cover)),
      const SizedBox(width: 15),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(item.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text(item.formattedPrice, style: TextStyle(fontSize: 16, color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold))
      ])),
      Row(children: [IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => cart.decrementQuantity(item)), Text(item.quantity.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => cart.incrementQuantity(item))])
    ])));
  }

  Widget _buildCheckoutSection(BuildContext context, CartProvider cart) {
    final totalFormatted = NumberFormat('#,###', 'ar_IQ').format(cart.totalPrice);
    final discountedTotalFormatted = NumberFormat('#,###', 'ar_IQ').format(cart.discountedTotal);
    return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10, spreadRadius: 5)]),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('المجموع', style: TextStyle(fontSize: 18, color: Colors.grey)),
            Text('$totalFormatted د.ع', style: TextStyle(fontSize: 18, color: Colors.grey, decoration: cart.appliedCoupon != null ? TextDecoration.lineThrough : TextDecoration.none))
          ]),
          if (cart.appliedCoupon != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('الإجمالي بعد الخصم', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                Text('$discountedTotalFormatted د.ع', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor))
              ]),
            ),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => _showCheckoutDialog(context, cart), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white), child: const Text('إتمام الطلب', style: TextStyle(fontSize: 18))))
        ])
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
    _loadOrders();
    // Listen for notifications to refresh the list
    Provider.of<NotificationProvider>(context, listen: false).addListener(_refreshOrders);
  }

  @override
  void dispose() {
    Provider.of<NotificationProvider>(context, listen: false).removeListener(_refreshOrders);
    super.dispose();
  }

  void _refreshOrders() {
    // This will trigger the FutureBuilder to re-fetch
    setState(() {
      _loadOrders();
    });
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
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return Center(child: Text('حدث خطأ: ${snapshot.error}'));
            if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.history_toggle_off, size: 80, color: Colors.grey), SizedBox(height: 20), Text('لا يوجد لديك طلبات سابقة', style: TextStyle(fontSize: 18, color: Colors.grey))]));

            final orders = snapshot.data!;
            return ListView.builder(padding: const EdgeInsets.all(8), itemCount: orders.length, itemBuilder: (context, index) => OrderHistoryCard(order: orders[index]));
          },
        ),
      ),
    );
  }
}

class RestaurantLoginScreen extends StatefulWidget {
  const RestaurantLoginScreen({super.key});
  @override
  State<RestaurantLoginScreen> createState() => _RestaurantLoginScreenState();
}

// في ملف re.dart (تحت class _RestaurantLoginScreenState)


class _RestaurantLoginScreenState extends State<RestaurantLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  bool _isLoading = false;
  String _locationStatus = 'لم يتم تحديد موقع المطعم';
  final ApiService _apiService = ApiService();
  // دالة تحديد الموقع الحالي
  Future<void> _getCurrentLocation() async {
    setState(() => _locationStatus = 'جاري تحديد الموقع...');

    try {
      // 1. استخدام خدمة الصلاحيات الشاملة (التي تتحقق من تفعيل GPS ومن الإذن)
      // (تأكد من استيراد PermissionService إذا كان في ملف آخر)
      final hasPermission = await PermissionService.handleLocationPermission(context);

      if (!hasPermission) {
        // الرسالة ستظهر للزبون من داخل handleLocationPermission
        throw Exception('صلاحية الوصول للموقع مرفوضة أو الخدمة معطلة.');
      }
      // --- [ نهاية التصحيح ] ---

      // 2. الحصول على الموقع (الآن نحن متأكدون أن الخدمة تعمل)
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
      );

      // 3. حفظ الإحداثيات في المتحكمات
      _latController.text = position.latitude.toString();
      _lngController.text = position.longitude.toString();

      setState(() {
        _locationStatus = 'تم التحديد: (خط عرض: ${position.latitude.toStringAsFixed(4)}, خط طول: ${position.longitude.toStringAsFixed(4)})';
      });

    } catch (e) {
      setState(() {
        _locationStatus = 'خطأ في تحديد الموقع: ${e.toString().replaceAll("Exception: ", "")}';
        _latController.clear();
        _lngController.clear();
      });
      // لا داعي لإظهار SnackBar هنا، لأن PermissionService تقوم بذلك بالفعل
    }
  }
  // ------------------------------------------

  Future<void> _login() async {
    // تحقق من صحة الحقول العامة
    if (!_formKey.currentState!.validate()) return;

    // التحقق من تحديد الموقع
    if (_latController.text.isEmpty || _lngController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء تحديد موقع المطعم أولاً.')));
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // 1. محاولة تسجيل الدخول (كما كانت)
    final success = await authProvider.login(
      _usernameController.text,
      _passwordController.text,
      'owner', // 👈 [هام جداً] أضف هذا السطر هنا لتحديد الرتبة
      restaurantLat: _latController.text,
      restaurantLng: _lngController.text,
    );

    if (!mounted) return;

    // 2. إذا نجح تسجيل الدخول...
    if (success) {

      // ✨ --- [ هذا هو التعديل الأهم ] ---
      // 3. ...حاول إرسال الموقع إلى الخادم
      try {
        final token = authProvider.token!; // التوكن موجود لأن success = true
        final lat = _latController.text;
        final lng = _lngController.text;

        // استدعاء الدالة الجديدة التي أضفناها لـ ApiService
        await _apiService.updateMyLocation(token, lat, lng);

        // نجح كل شيء، انتقل للوحة التحكم
        Navigator.of(context).pop();

      } catch (e) {
        // (في حال فشل إرسال الموقع، ولكن تسجيل الدخول نجح)
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('تم تسجيل الدخول، لكن فشل حفظ الموقع على الخادم: $e'),
                backgroundColor: Colors.orange,
              )
          );
        }
        // انتقل للوحة التحكم على أي حال (لأن الدخول نجح)
        Navigator.of(context).pop();
      }
      // --- [ نهاية التعديل ] ---

    } else {
      // (إذا فشل تسجيل الدخول من الأساس)
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل تسجيل الدخول. الرجاء التأكد من البيانات.')));
    }

    if(mounted) {
      setState(() => _isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('دخول مدير المطعم')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.store_mall_directory, size: 80, color: Colors.teal),
              const SizedBox(height: 20),
              TextFormField( controller: _usernameController, decoration: const InputDecoration( labelText: 'اسم المستخدم أو البريد الإلكتروني'), validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null),
              const SizedBox(height: 20),
              TextFormField( controller: _passwordController, decoration: const InputDecoration(labelText: 'كلمة المرور'), obscureText: true, validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null),

              // -----------------------------------------
              // واجهة تحديد الموقع
              // -----------------------------------------
              const SizedBox(height: 40),
              Text('تحديد موقع المطعم الحالي (لنقاط الانطلاق في التوصيل)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
              const SizedBox(height: 10),

              OutlinedButton.icon(
                icon: const Icon(Icons.location_on),
                label: const Text('تحديد موقع المطعم الآن'),
                onPressed: _getCurrentLocation,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              const SizedBox(height: 10),

              // عرض حالة الموقع (تم تحديده أم لا)
              Text(
                _locationStatus,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _latController.text.isEmpty ? Colors.red : Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // -----------------------------------------

              const SizedBox(height: 40),
              _isLoading ? const CircularProgressIndicator() : ElevatedButton( onPressed: _login, style: ElevatedButton.styleFrom( minimumSize: const Size(double.infinity, 50), textStyle: const TextStyle(fontSize: 18)), child: const Text('تسجيل الدخول'))
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
            tileProvider: MapboxCachedTileProvider(),

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

class RestaurantDashboardScreen extends StatefulWidget {
  const RestaurantDashboardScreen({super.key});

  @override
  State<RestaurantDashboardScreen> createState() => _RestaurantDashboardScreenState();
}

class _RestaurantDashboardScreenState extends State<RestaurantDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService(); // لاستخدامه في نافذة الطلب الخاص

  @override
  void initState() {
    super.initState();
    // 1. تهيئة التبويبات (5 تبويبات)
    _tabController = TabController(length: 5, vsync: this);

    // 2. المنطق التسلسلي الصحيح (جلب الموقع ثم تشغيل الأتمتة)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token != null) {

        // أ) نطلب جلب الإعدادات أولاً (ليتم تخزين restaurant_lat في الهاتف)
        Provider.of<RestaurantSettingsProvider>(context, listen: false)
            .fetchSettings(token)
            .then((_) {

          // ب) بعد انتهاء جلب الإعدادات، نتأكد أننا ما زلنا في الشاشة
          if (mounted) {
            // ج) الآن نشغل الأتمتة (التي ستجد الموقع محفوظاً وتعمل بنجاح)
            Provider.of<DashboardProvider>(context, listen: false).startAutoRefresh(token);
          }

        });
      }
    });
  }

  @override
  void dispose() {
    // إيقاف التحديث عند الخروج لتوفير الموارد
    Provider.of<DashboardProvider>(context, listen: false).stopAutoRefresh();
    _tabController.dispose();
    super.dispose();
  }

  // --- نافذة طلب التوصيل الخاص (اليدوي) ---
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

    // تحميل الاسم المحفوظ مسبقاً لتسهيل الأمر على المدير
    SharedPreferences.getInstance().then((prefs) {
      final savedName = prefs.getString('saved_restaurant_name') ?? '';
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
                      Text("سيتم إرسال الطلب من موقع مطعمك المسجل.", style: Theme.of(context).textTheme.bodySmall),
                      const Divider(height: 20),
                      TextFormField(
                        controller: _pickupNameController,
                        decoration: const InputDecoration(labelText: 'اسم المطعم/المصدر (الاستلام)'),
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
                        final token = prefs.getString('jwt_token');
                        final pickupLat = prefs.getDouble('restaurant_lat');
                        final pickupLng = prefs.getDouble('restaurant_lng');

                        if (token == null || pickupLat == null || pickupLng == null) {
                          throw Exception("بيانات المطعم غير كاملة. يرجى الانتظار قليلاً أو إعادة تسجيل الدخول.");
                        }

                        final pickupName = _pickupNameController.text;
                        // حفظ الاسم للمرات القادمة
                        await prefs.setString('saved_restaurant_name', pickupName);

                        final double? destLat = double.tryParse(_destLatController.text);
                        final double? destLng = double.tryParse(_destLngController.text);

                        final result = await _apiService.createUnifiedDeliveryRequest(
                          token: token,
                          sourceType: 'restaurant',
                          pickupName: pickupName,
                          pickupLat: pickupLat,
                          pickupLng: pickupLng,
                          destinationAddress: _destAddressController.text,
                          destinationLat: destLat,
                          destinationLng: destLng,
                          deliveryFee: _feeController.text,
                          orderDescription: _notesController.text,
                          endCustomerPhone: _phoneController.text,
                          sourceOrderId: 'private_${DateTime.now().millisecondsSinceEpoch}',
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
    final auth = Provider.of<AuthProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم المطعم'),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_active_outlined), onPressed: () async {
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            try {
              final success = await _apiService.testNotification();
              if (success) scaffoldMessenger.showSnackBar(const SnackBar(content: Text("تم إرسال إشعار تجريبي بنجاح."), backgroundColor: Colors.green));
            } catch (e) {
              scaffoldMessenger.showSnackBar(SnackBar(content: Text("فشل إرسال الإشعار: ${e.toString()}"), backgroundColor: Colors.red));
            }
          }, tooltip: 'اختبار الإشعارات'),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => auth.logout(context), tooltip: 'تسجيل الخروج')
        ],
        bottom: TabBar(
            controller: _tabController,
            isScrollable: true, // للسماح بعرض 5 تبويبات
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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

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
    final auth = Provider.of<AuthProvider>(context, listen: false);

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
  final AuthProvider authProvider;

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
    // قمنا بإضافة maxWidth و maxHeight لتقليل حجم الصورة بشكل كبير
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60, // تقليل الجودة قليلاً
      maxWidth: 800,    // تحديد أقصى عرض
      maxHeight: 800,   // تحديد أقصى ارتفاع
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

    // نمرر الصورة الجديدة (_selectedImage) للدالة
    final success = await widget.productProvider.updateProduct(
      widget.authProvider.token!,
      widget.product.id,
      _nameController.text,
      _priceController.text,
      _salePriceController.text,
      _selectedImage,
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
  final AuthProvider authProvider;

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

// ملاحظة: تأكد من وجود الـ imports الضرورية في أعلى الملف
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// (بالإضافة إلى imports الموديلات والـ Widgets الأخرى)

class _OrdersListScreenState extends State<OrdersListScreen> {
  @override
  Widget build(BuildContext context) {
    // جلب الـ Provider الخاص بالمصادقة (لم يتغير)
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // استخدام Consumer للاستماع لتغيرات DashboardProvider
    return Consumer<DashboardProvider>(
      builder: (context, dashboard, child) {
        // --- قسم التحميل ومعالجة الأخطاء (لم يتغير) ---
        if (dashboard.isLoading && (dashboard.orders[widget.status] == null || dashboard.orders[widget.status]!.isEmpty)) {
          return const Center(child: CircularProgressIndicator());
        }

        // --- نهاية قسم التحميل ---

        // جلب قائمة الطلبات (لم يتغير)
        final orders = dashboard.orders[widget.status] ?? [];

        // ✨ --- الإضافة: جلب خريطة الرموز ---
        final pickupCodes = dashboard.pickupCodes;
        // --- نهاية الإضافة ---

        // بناء الواجهة الرئيسية
        return RefreshIndicator(
          onRefresh: () => dashboard.fetchDashboardData(authProvider.token), // تحديث البيانات عند السحب
          child: orders.isEmpty
          // --- حالة عدم وجود طلبات (لم يتغير) ---
              ? Center(child: ListView(physics: const AlwaysScrollableScrollPhysics(), children: [SizedBox(height: MediaQuery.of(context).size.height * 0.2), Text('لا توجد طلبات في هذا القسم حالياً', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.grey.shade600)), const SizedBox(height: 10), const Icon(Icons.inbox_outlined, size: 50, color: Colors.grey)]))
          // --- نهاية حالة عدم وجود طلبات ---

          // --- بناء قائمة الطلبات ---
              : ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              // ✨ --- التعديل: استخرج الطلب والرمز ---
              final order = orders[index];
              final code = pickupCodes[order.id]; // جلب الرمز الخاص بهذا الطلب
              // --- نهاية التعديل ---

              // بناء بطاقة الطلب مع تمرير الرمز
              return OrderCard(
                order: order,
                onStatusChanged: () => dashboard.fetchDashboardData(authProvider.token),
                isCompleted: widget.status != 'active',
                pickupCode: code, // <-- ✨ الإضافة: تمرير الرمز المستخرج للبطاقة
              );
            },
          ),
          // --- نهاية بناء القائمة ---
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
  final String status;      // حالة الطلب
  final String description; // وصف
  final double deliveryFee;
  final String pickupName;
  final String sourceType;  // 'restaurant', 'market', 'taxi'
  final String destinationAddress;
  final String pickupLat;
  final String pickupLng;
  final String destLat;
  final String destLng;
  final String itemsSummary; // ملخص الوجبات
  final int dateCreated;     // التوقيت
  final String customerPhone; // ✨ جديد: رقم هاتف الزبون

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
    required this.itemsSummary,
    required this.dateCreated,
    required this.customerPhone, // ✨
  });

  factory UnifiedDeliveryOrder.fromJson(Map<String, dynamic> json) {
    // دوال مساعدة لضمان الأمان
    String safeString(dynamic val) {
      if (val == null) return '';
      return val.toString();
    }

    double safeDouble(dynamic val) {
      if (val == null) return 0.0;
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return UnifiedDeliveryOrder(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      status: safeString(json['order_status']),
      description: safeString(json['order_description']),
      deliveryFee: safeDouble(json['delivery_fee']),
      pickupName: safeString(json['pickup_location_name']),
      sourceType: safeString(json['source_type']),
      destinationAddress: safeString(json['destination_address']),
      pickupLat: safeString(json['pickup_lat']),
      pickupLng: safeString(json['pickup_lng']),
      destLat: safeString(json['destination_lat']),
      destLng: safeString(json['destination_lng']),
      itemsSummary: safeString(json['items_summary']), // 👈 هنا كان الخطأ المحتمل
      dateCreated: json['date_created'] is int ? json['date_created'] : 0,
      customerPhone: safeString(json['customer_phone']),
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

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // 1. محاولة تسجيل الدخول
    final success = await authProvider.login(
        _usernameController.text,
        _passwordController.text,
        'leader'
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      // ✅ نجاح الدخول
      Navigator.pop(context); // إغلاق شاشة الدخول الحالية

      if (authProvider.token != null) {
        // 🔥 التغيير الجذري هنا:
        // الانتقال المباشر للوحة التحكم (تم تجاوز شاشة اختيار المنطقة)
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RegionDashboardScreen(
              token: authProvider.token!,
              areaId: 0, // نرسل 0، والسيرفر سيجلب المنطقة من بروفايل التيم ليدر
              areaName: "لوحة القيادة", // اسم افتراضي
            ),
          ),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم الدخول بنجاح!"), backgroundColor: Colors.green),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("فشل الدخول: تأكد من البيانات."), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E3C72), // لون الخلفية المميز
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
                    backgroundColor: Colors.amber,
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

class _RegionDashboardScreenState extends State<RegionDashboardScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;

  // متغير لتخزين البيانات لمنع إعادة التحميل مع كل بناء للشاشة
  late Future<List<UnifiedDeliveryOrder>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // الكل، مطاعم، مسواك، تكسي

    // تحميل البيانات لأول مرة
    _loadData();

    // الاستماع للإشعارات لتحديث القائمة تلقائياً عند الحاجة فقط
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (mounted) {
        print("🔔 تيم ليدر: إشعار جديد! جاري تحديث القائمة...");
        _loadData();
      }
    });
  }

  // دالة لتحميل البيانات وحفظها في المتغير
  void _loadData() {
    setState(() {
      _ordersFuture = _apiService.getOrdersByRegion(widget.areaId, widget.token);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // دالة مساعدة للاتصال
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("لا يمكن إجراء الاتصال")));
    }
  }

  // دالة مساعدة لفتح الخريطة
  void _openMap(String latStr, String lngStr, String title) {
    try {
      final double lat = double.parse(latStr);
      final double lng = double.parse(lngStr);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InAppMapScreen(latitude: lat, longitude: lng, title: title),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("الإحداثيات غير صالحة")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("غرفة عمليات المنطقة", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(widget.areaName, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor: const Color(0xFF1E3C72),
        foregroundColor: Colors.white,

        // ✨✨✨ هنا تمت إضافة زر المحفظة والمكافآت ✨✨✨
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet, color: Colors.amber),
            tooltip: "المكافآت والرصيد",
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  // تأكد أن كلاس TeamLeaderRewardsScreen موجود في المشروع
                  builder: (_) => TeamLeaderRewardsScreen(token: widget.token),
                ),
              );
            },
          ),
        ],
        // ✨✨✨ نهاية الإضافة ✨✨✨

        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          labelColor: Colors.amber,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(text: "الكل"),
            Tab(text: "🍔 مطاعم"),
            Tab(text: "🛒 مسواك"),
            Tab(text: "🚕 تكسي"),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadData(); // تحديث يدوي عند السحب
          await _ordersFuture;
        },
        child: FutureBuilder<List<UnifiedDeliveryOrder>>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 50, color: Colors.red),
                  const SizedBox(height: 10),
                  Text("حدث خطأ: ${snapshot.error}", textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  ElevatedButton(onPressed: _loadData, child: const Text("إعادة المحاولة"))
                ],
              ));
            }

            final allOrders = snapshot.data ?? [];
            if (allOrders.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 200),
                  Center(child: Text("المنطقة هادئة.. لا توجد طلبات نشطة حالياً 😴")),
                ],
              );
            }

            // الفلترة
            final restaurantOrders = allOrders.where((o) => o.sourceType == 'restaurant').toList();
            final marketOrders = allOrders.where((o) => o.sourceType == 'market').toList();
            final taxiOrders = allOrders.where((o) => o.sourceType == 'taxi').toList();

            return TabBarView(
              controller: _tabController,
              children: [
                _buildOrdersList(allOrders),
                _buildOrdersList(restaurantOrders),
                _buildOrdersList(marketOrders),
                _buildOrdersList(taxiOrders),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrdersList(List<UnifiedDeliveryOrder> orders) {
    if (orders.isEmpty) {
      return const Center(child: Text("لا توجد طلبات في هذا القسم"));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        // ✅ استخدام البطاقة الذكية الجديدة
        return TeamLeaderOrderCard(
          order: orders[index],
          token: widget.token,
          onActionComplete: () {
            // إعادة تحميل البيانات بعد التدخل الناجح
            _loadData();
          },
        );
      },
    );
  }

  Widget _buildTeamLeaderCard(UnifiedDeliveryOrder order) {
    Color color;
    IconData icon;
    String label;

    switch (order.sourceType) {
      case 'restaurant': color = Colors.orange; icon = Icons.restaurant; label = "مطعم"; break;
      case 'market': color = Colors.purple; icon = Icons.shopping_cart; label = "مسواك"; break;
      case 'taxi': color = Colors.amber.shade700; icon = Icons.local_taxi; label = "تكسي"; break;
      default: color = Colors.blue; icon = Icons.delivery_dining; label = "توصيل";
    }

    // تحديد الحالات المنتهية
    bool isCompleted = ['completed', 'cancelled', 'refunded', 'failed', 'trash'].contains(order.status);
    Color cardColor = isCompleted ? Colors.grey.shade50 : Colors.white;
    Color statusTextColor = isCompleted ? Colors.grey : Colors.green.shade700;

    // ترجمة الحالة للعرض
    String statusText = order.status;
    if(order.status == 'pending') statusText = 'بانتظار الدفع';
    if(order.status == 'processing') statusText = 'قيد التحضير';
    if(order.status == 'on-hold') statusText = 'قيد الانتظار';
    if(order.status == 'driver-assigned') statusText = 'تم تعيين سائق';
    if(order.status == 'out-for-delivery') statusText = 'جاري التوصيل';

    // تنسيق الوقت
    String timeStr = "";
    if (order.dateCreated > 0) {
      final dt = DateTime.fromMillisecondsSinceEpoch(order.dateCreated * 1000);
      timeStr = DateFormat('hh:mm a', 'en').format(dt);
    }

    return Card(
      elevation: isCompleted ? 1 : 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          children: [
            // رأس البطاقة
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: color, size: 20),
                      const SizedBox(width: 8),
                      Text("$label #${order.id}", style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15)),
                    ],
                  ),
                  Row(
                    children: [
                      Text(timeStr, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: statusTextColor.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusText.toUpperCase(),
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: statusTextColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(),

            // تفاصيل الطلب
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (order.itemsSummary.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                          order.itemsSummary,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis
                      ),
                    ),

                  _buildInfoRow(Icons.store, "من:", order.pickupName),
                  const SizedBox(height: 6),
                  _buildInfoRow(Icons.location_on, "إلى:", order.destinationAddress),

                  if (order.sourceType == 'taxi' && order.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      width: double.infinity,
                      decoration: BoxDecoration(color: Colors.yellow.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Text("📝 ${order.description}", style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
                    ),
                  ],
                ],
              ),
            ),

            const Divider(),

            // أزرار التحكم السفلية
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                children: [
                  Text(
                    "${NumberFormat('#,###').format(order.deliveryFee)} د.ع",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal),
                  ),
                  const Spacer(),

                  if(order.customerPhone.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.phone, color: Colors.green),
                      tooltip: "اتصال بالزبون",
                      onPressed: () => _makePhoneCall(order.customerPhone),
                    ),

                  if (order.pickupLat != "0" && order.pickupLat.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.map, color: Colors.blue),
                      tooltip: "موقع الاستلام",
                      onPressed: () => _openMap(order.pickupLat, order.pickupLng, "موقع الاستلام: ${order.pickupName}"),
                    ),

                  if (order.destLat != "0" && order.destLat.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.location_pin, color: Colors.red),
                      tooltip: "موقع الزبون",
                      onPressed: () => _openMap(order.destLat, order.destLng, "موقع الزبون"),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis
          ),
        ),
      ],
    );
  }
}

class _RatingsDashboardScreenState extends State<RatingsDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return Consumer<DashboardProvider>(
        builder: (context, dashboard, child) {
          if (dashboard.isLoading && dashboard.ratingsDashboard == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (dashboard.ratingsDashboard == null) {
            return Center(
              child: RefreshIndicator(
                onRefresh: () => dashboard.fetchDashboardData(authProvider.token),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                    const Text("لا توجد بيانات تقييم.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            );
          }

          final data = dashboard.ratingsDashboard!;
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
                if (data.recentReviews.isEmpty) const Center(child: Padding(padding: const EdgeInsets.all(20.0), child: Text("لا توجد تقييمات حديثة.", style: TextStyle(color: Colors.grey))))
                else ...data.recentReviews.map((review) => ReviewCard(review: review)),
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
