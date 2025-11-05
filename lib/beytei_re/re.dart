import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
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

// =======================================================================
// --- إعدادات وثوابت عامة للوحدة ---
// =======================================================================
const String BEYTEI_URL = 'https://re.beytei.com';
const String CONSUMER_KEY = 'ck_d22c789681c4610838f1d39a05dbedcb73a2c810';
const String CONSUMER_SECRET = 'cs_78b90e397bbc2a8f5f5092cca36dc86e55c01c07';
const Duration API_TIMEOUT = Duration(seconds: 30);
const String CACHE_HOME_DATA_KEY = 'cache_home_data_area_'; // سنضيف رقم المنطقة
const String CACHE_RESTAURANTS_KEY = 'cache_all_restaurants_area_';

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
  bool _isLoading = true;

  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _token != null;

  AuthProvider() {
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token');
    _isLoading = false;
    notifyListeners();
  }

  // ✨ تم تحديث دالة login لاستقبال إحداثيات المطعم
  Future<bool> login(String username, String password, {String? restaurantLat, String? restaurantLng}) async {
    final authService = AuthService();
    _token = await authService.loginRestaurantOwner(username, password);

    if (_token != null) {
      await authService.registerDeviceToken();

      // ✨ NEW: حفظ الإحداثيات المحددة في SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      if (restaurantLat != null && restaurantLng != null) {
        // نحول النصوص إلى أرقام عشرية قبل الحفظ لضمان الاستخدام الصحيح لاحقاً
        await prefs.setDouble('restaurant_lat', double.tryParse(restaurantLat) ?? 0.0);
        await prefs.setDouble('restaurant_lng', double.tryParse(restaurantLng) ?? 0.0);
      }
      // --- نهاية الإضافة ---

      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout(BuildContext context) async {
    final authService = AuthService();
    await authService.logout();
    _token = null;
    Provider.of<DashboardProvider>(context, listen: false).clearData();
    Provider.of<CustomerProvider>(context, listen: false).clearData();
    notifyListeners();
  }
}

// (الصق هذا بدلاً من CustomerProvider القديم)
class CustomerProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  Map<String, List<dynamic>> _homeData = {}; // Stores fetched data for home screen sections
  List<Restaurant> _allRestaurants = []; // Stores all restaurants for the "Restaurants" screen
  Map<int, List<FoodItem>> _menuItems = {}; // Map<restaurantId, List<FoodItem>> for individual menus

  bool _isLoadingHome = false;
  bool _isLoadingRestaurants = false;
  bool _isLoadingMenu = false;
  bool _hasError = false;

  // --- Getters ---
  Map<String, List<dynamic>> get homeData => _homeData;
  List<Restaurant> get allRestaurants => _allRestaurants;
  Map<int, List<FoodItem>> get menuItems => _menuItems;
  bool get isLoadingHome => _isLoadingHome;
  bool get isLoadingRestaurants => _isLoadingRestaurants;
  bool get isLoadingMenu => _isLoadingMenu;
  bool get hasError => _hasError;

  // --- Clear Data ---
  void clearData() {
    _homeData = {};
    _allRestaurants = [];
    _menuItems = {};
    _hasError = false;
    notifyListeners();
  }

  // ===================================================================
  // ✨ --- دوال التخزين المؤقت (Caching) الجديدة ---
  // ===================================================================

  Future<void> _loadHomeDataFromCache(int areaId) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedString = prefs.getString('$CACHE_HOME_DATA_KEY$areaId');
    if (cachedString != null) {
      try {
        final data = json.decode(cachedString);
        // التحميل من الكاش
        _homeData['restaurants'] = (data['restaurants'] as List).map((d) => Restaurant.fromJson(d)).toList();
        _homeData['onSale'] = (data['onSale'] as List).map((d) => FoodItem.fromJson(d)).toList();
        _homeData['breakfast'] = (data['breakfast'] as List).map((d) => FoodItem.fromJson(d)).toList();
        _homeData['family'] = (data['family'] as List).map((d) => FoodItem.fromJson(d)).toList();
        notifyListeners(); // <-- عرض البيانات القديمة فوراً
      } catch (e) {
        print("Failed to load home cache: $e");
      }
    }
  }

  Future<void> _saveHomeDataToCache(int areaId) async {
    if (_homeData.isEmpty || _homeData['restaurants'] == null) return;
    final prefs = await SharedPreferences.getInstance();
    try {
      final dataToCache = json.encode({
        'restaurants': _homeData['restaurants']?.map((r) => (r as Restaurant).toJson()).toList(),
        'onSale': _homeData['onSale']?.map((f) => (f as FoodItem).toJson()).toList(),
        'breakfast': _homeData['breakfast']?.map((f) => (f as FoodItem).toJson()).toList(),
        'family': _homeData['family']?.map((f) => (f as FoodItem).toJson()).toList(),
      });
      await prefs.setString('$CACHE_HOME_DATA_KEY$areaId', dataToCache);
    } catch (e) {
      print("Failed to save home cache: $e");
    }
  }

  Future<void> _loadRestaurantsFromCache(int areaId) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedString = prefs.getString('$CACHE_RESTAURANTS_KEY$areaId');
    if (cachedString != null) {
      try {
        final data = json.decode(cachedString) as List;
        _allRestaurants = data.map((d) => Restaurant.fromJson(d)).toList();
        notifyListeners(); // عرض المطاعم المخزنة
      } catch (e) {
        print("Failed to load restaurants cache: $e");
      }
    }
  }

  Future<void> _saveRestaurantsToCache(int areaId) async {
    if (_allRestaurants.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    try {
      final dataToCache = json.encode(_allRestaurants.map((r) => r.toJson()).toList());
      await prefs.setString('$CACHE_RESTAURANTS_KEY$areaId', dataToCache);
    } catch (e) {
      print("Failed to save restaurants cache: $e");
    }
  }

  // ===================================================================
  // ✨ --- الدوال الأساسية (معدلة لتستخدم الكاش) ---
  // ===================================================================

  // --- Fetch Home Screen Data (Modified with Caching) ---
  Future<void> fetchHomeData(int areaId) async {
    // 1. إذا كانت البيانات فارغة، أظهر شاشة التحميل (Shimmer)
    if (_homeData.isEmpty) {
      _isLoadingHome = true;
      _hasError = false;
      notifyListeners();
      // وحاول تحميل البيانات القديمة إن وجدت
      await _loadHomeDataFromCache(areaId);
    }

    // 2. إذا كانت البيانات موجودة (من الكاش)، لا تظهر شاشة التحميل
    _isLoadingHome = _homeData.isEmpty; // التحميل فقط إذا كان الكاش فارغاً
    _hasError = false;
    // 🚫 لا تقم بمسح البيانات القديمة هنا
    notifyListeners();

    // 3. تأكد من جلب قائمة المطاعم (ستستخدم الكاش الخاص بها إذا وجد)
    if (_allRestaurants.isEmpty) {
      // (isRefresh: false) ليستخدم الكاش الخاص به أولاً
      await fetchAllRestaurants(areaId, isRefresh: false);
    }

    try {
      // 4. جلب المنتجات (هذا من الكود الخاص بك)
      final allRestaurantsList = _allRestaurants;
      final restaurantStatusMap = {for (var r in allRestaurantsList) r.id: r.isOpen};

      final productResults = await Future.wait([
        _apiService.getOnSaleItems(areaId: areaId),
        _apiService.getProductsByTag(areaId: areaId, tagName: "فطور"),
        _apiService.getProductsByTag(areaId: areaId, tagName: "عائلي"),
      ]);

      // 5. تحديث البيانات الجديدة
      _homeData['restaurants'] = allRestaurantsList;
      _homeData['onSale'] = _filterFoodItemsByStatus(restaurantStatusMap, productResults[0]);
      _homeData['breakfast'] = _filterFoodItemsByStatus(restaurantStatusMap, productResults[1] as List<FoodItem>);
      _homeData['family'] = _filterFoodItemsByStatus(restaurantStatusMap, productResults[2] as List<FoodItem>);

      _hasError = false;
      await _saveHomeDataToCache(areaId); // 6. حفظ البيانات الجديدة في الكاش

    } catch (e) {
      print("Error fetching home data for area $areaId: $e");
      if (_homeData.isEmpty) { // أظهر الخطأ فقط إذا لم يكن لدينا بيانات قديمة
        _hasError = true;
      }
    } finally {
      _isLoadingHome = false;
      notifyListeners(); // تحديث الواجهة بالبيانات الجديدة
    }
  }

  // --- دالة الفلترة (كما هي من الكود الخاص بك) ---
  List<FoodItem> _filterFoodItemsByStatus(Map<int, bool> restaurantStatusMap, List<FoodItem> items) {
    return items.map((item) {
      bool isRestaurantOpen = restaurantStatusMap[item.categoryId] ?? false;
      item.isDeliverable = isRestaurantOpen;
      return item;
    }).toList();
  }

  // --- fetchAllRestaurants (Modified with Caching) ---
  Future<void> fetchAllRestaurants(int areaId, {bool isRefresh = false}) async {
    if (isRefresh) {
      _allRestaurants = [];
    }

    // 1. تحقق إذا كانت البيانات موجودة (ولا يوجد طلب تحديث)
    if (_allRestaurants.isNotEmpty && !isRefresh) return;

    // 2. إذا البيانات فارغة، أظهر التحميل وحاول جلب الكاش
    if (_allRestaurants.isEmpty) {
      _isLoadingRestaurants = true;
      _hasError = false;
      notifyListeners();
      await _loadRestaurantsFromCache(areaId); // جلب الكاش
    }

    // 3. التحميل فقط إذا كان الكاش فارغاً
    _isLoadingRestaurants = _allRestaurants.isEmpty;
    _hasError = false;
    notifyListeners();

    try {
      // 4. جلب البيانات من الشبكة
      final allRestaurantsList = await _apiService.getAllRestaurants(areaId: areaId);
      for (var r in allRestaurantsList) {
        r.isDeliverable = true; // (من الكود الخاص بك)
      }
      _allRestaurants = allRestaurantsList; // تحديث
      _hasError = false;
      await _saveRestaurantsToCache(areaId); // 5. حفظ في الكاش

    } catch (e) {
      print("Error fetching all restaurants for area $areaId: $e");
      if (_allRestaurants.isEmpty) { // إظهار الخطأ فقط إذا فشل الكاش
        _hasError = true;
      }
    } finally {
      _isLoadingRestaurants = false;
      notifyListeners();
    }
  }

  // --- fetchMenuForRestaurant (كما هي من الكود الخاص بك - قوية كفاية) ---
  Future<void> fetchMenuForRestaurant(int restaurantId, {bool isRefresh = false}) async {
    if (isRefresh) {
      _menuItems.remove(restaurantId);
    }
    if (_menuItems.containsKey(restaurantId) && !isRefresh) return;

    _isLoadingMenu = true;
    _hasError = false;
    notifyListeners();

    try {
      final newItems = await _apiService.getMenuForRestaurant(restaurantId);

      Restaurant? restaurant;
      try {
        restaurant = _allRestaurants.firstWhere((r) => r.id == restaurantId);
      } catch (e) {
        print("Restaurant not found in list, fetching by ID...");
        restaurant = await _apiService.getRestaurantById(restaurantId);
      }

      final bool isRestaurantReady = (restaurant.isDeliverable) && (restaurant.isOpen);

      for (var item in newItems) {
        item.isDeliverable = isRestaurantReady;
      }

      _menuItems[restaurantId] = newItems;
      _hasError = false;
    } catch (e) {
      print("Error fetching menu for restaurant $restaurantId: $e");
      _hasError = true;
      _menuItems[restaurantId] = [];
    } finally {
      _isLoadingMenu = false;
      notifyListeners();
    }
  }
}class DashboardProvider with ChangeNotifier {
  Map<String, List<Order>> _orders = {};
  RestaurantRatingsDashboard? _ratingsDashboard;

  // 1. الذاكرة المؤقتة للرموز
  Map<int, String> _pickupCodes = {};

  bool _isLoading = false;
  bool _hasNetworkError = false;
  String _errorMessage = '';

  Map<String, List<Order>> get orders => _orders;
  RestaurantRatingsDashboard? get ratingsDashboard => _ratingsDashboard;
  bool get isLoading => _isLoading;
  bool get hasNetworkError => _hasNetworkError;
  String get errorMessage => _errorMessage;

  // ✨ 2. Getter للوصول إلى الرموز (كان هذا ناقصاً)
  Map<int, String> get pickupCodes => _pickupCodes;

  // ✨ 3. دالة لحفظ الرمز الجديد (كان هذا ناقصاً)
  void setPickupCode(int orderId, String code) {
    _pickupCodes[orderId] = code;
    // لا نحتاج notifyListeners() هنا لأن fetchDashboardData سيقوم بذلك
  }

  // ✨ 4. تحديث دالة clearData (تمت إضافة _pickupCodes.clear())
  void clearData() {
    _orders = {};
    _ratingsDashboard = null;
    _pickupCodes = {}; // <-- الإضافة المهمة هنا
    notifyListeners();
  }

  Future<void> fetchDashboardData(String? token) async {
    if (token == null) return;
    _isLoading = true;
    _hasNetworkError = false;
    notifyListeners();

    await _loadDashboardFromCache();

    try {
      final apiService = ApiService();
      final results = await Future.wait([
        apiService.getRestaurantOrders(status: 'active', token: token),
        apiService.getRestaurantOrders(status: 'completed', token: token),
        apiService.getDashboardRatings(token),
      ]);

      _orders['active'] = results[0] as List<Order>;
      _orders['completed'] = results[1] as List<Order>;
      _ratingsDashboard = results[2] as RestaurantRatingsDashboard;

      await _saveDashboardToCache();

    } catch (e) {
      if (_orders.isEmpty && _ratingsDashboard == null) {
        _hasNetworkError = true;
        _errorMessage = 'فشل في تحديث البيانات. يرجى التحقق من اتصالك بالإنترنت.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveDashboardToCache() async {
    final prefs = await SharedPreferences.getInstance();
    final dataToCache = json.encode({
      'orders_active': _orders['active']?.map((o) => o.toJson()).toList(),
      'orders_completed': _orders['completed']?.map((o) => o.toJson()).toList(),
      'ratings': _ratingsDashboard?.toJson(),
    });
    await prefs.setString('cache_dashboard', dataToCache);
  }

  Future<void> _loadDashboardFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedString = prefs.getString('cache_dashboard');
    if (cachedString != null) {
      final data = json.decode(cachedString);
      if(data['orders_active'] != null) {
        _orders['active'] = (data['orders_active'] as List).map((d) => Order.fromJson(d)).toList();
      }
      if(data['orders_completed'] != null) {
        _orders['completed'] = (data['orders_completed'] as List).map((d) => Order.fromJson(d)).toList();
      }
      if(data['ratings'] != null) {
        _ratingsDashboard = RestaurantRatingsDashboard.fromJson(data['ratings']);
      }
      notifyListeners();
    }
  }
}// ✨ NEW: Restaurant Settings Provider
class RestaurantSettingsProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isRestaurantOpen = true;
  String _openTime = '09:00';
  String _closeTime = '22:00';
  bool _isLoading = false;

  bool get isRestaurantOpen => _isRestaurantOpen;
  String get openTime => _openTime;
  String get closeTime => _closeTime;
  bool get isLoading => _isLoading;

  // عند تسجيل دخول المدير، يجب جلب هذه البيانات
  Future<void> fetchSettings(String? token) async {
    if (token == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      // يجب إنشاء هذا الـ endpoint في الواجهة الخلفية (Backend)
      final settings = await _apiService.getRestaurantSettings(token);
      _isRestaurantOpen = settings['is_open'] ?? true;
      _openTime = settings['auto_open_time'] ?? '09:00';
      _closeTime = settings['auto_close_time'] ?? '22:00';
    } catch (e) {
      // يمكنك ترك القيم الافتراضية في حال الخطأ
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // تحديث حالة الفتح يدوياً
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

  // تحديث أوقات العمل التلقائية
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

  Future<bool> updateProduct(String token, int productId, String name, String price, String salePrice) async {
    _isLoading = true;
    notifyListeners();
    bool success = false;
    try {
      success = await _apiService.updateMyProduct(token, productId, name, price, salePrice);
      if (success) {
        // تحديث القائمة بعد النجاح
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
  int quantity; // Quantity in cart, mutable
  final int categoryId; // Represents the Restaurant (WooCommerce category ID)
  bool isDeliverable; // Flag: Can this item be ordered now? (Checks area AND restaurant open status)
  final double averageRating;
  final int ratingCount;

  // Constructor
  FoodItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.salePrice,
    required this.imageUrl,
    this.quantity = 1, // Default quantity when added to cart
    required this.categoryId,
    this.isDeliverable = false, // Default state, updated by CustomerProvider
    this.averageRating = 0.0,
    this.ratingCount = 0,
  });

  // Factory constructor to create a FoodItem from JSON data (API response)
  factory FoodItem.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse double values
    double safeParseDouble(dynamic value, [double defaultValue = 0.0]) {
      if (value == null) return defaultValue;
      return double.tryParse(value.toString()) ?? defaultValue;
    }

    // Helper function to safely parse int values
    int safeParseInt(dynamic value, [int defaultValue = 0]) {
      if (value == null) return defaultValue;
      return int.tryParse(value.toString()) ?? defaultValue;
    }

    // Extract image URL safely
    String extractImageUrl(dynamic images) {
      if (images is List &&
          images.isNotEmpty &&
          images[0] is Map &&
          images[0]['src'] != null &&
          images[0]['src'] != false) {
        return images[0]['src'];
      }
      return 'https://via.placeholder.com/150'; // Default placeholder
    }

    int extractRestaurantId(Map<String, dynamic> json) {
      // 1. Try reading the new field from meta_data (more accurate)
      if (json['meta_data'] != null && json['meta_data'] is List) {
        final metaData = json['meta_data'] as List;
        var parentIdMeta = metaData.firstWhere(
                (m) => m is Map && m['key'] == '_restaurant_parent_id',
            orElse: () => null);
        if (parentIdMeta != null && parentIdMeta['value'] != 0) {
          return int.tryParse(parentIdMeta['value'].toString()) ?? 0;
        }
      }

      // 2. If the first method fails, use the old method
      dynamic categories = json['categories'];
      if (categories is List &&
          categories.isNotEmpty &&
          categories[0] is Map &&
          categories[0]['id'] != null) {
        return categories[0]['id'];
      }
      return 0; // Default category ID if none found
    }

    // Clean up description (remove HTML tags)
    String cleanDescription(dynamic desc) {
      if (desc is String) {
        // Use RegExp to remove HTML tags
        return desc.replaceAll(RegExp(r'<[^>]*>|&nbsp;'), '').trim();
      }
      return ''; // Return empty string if description is not a string
    }

    return FoodItem(
      id: json['id'] ?? 0, // Default ID if null
      name: json['name'] ?? 'اسم غير متوفر', // Default name
      description: cleanDescription(json['short_description']),
      price: safeParseDouble(json['regular_price']),
      // Handle potential empty string or null for sale_price
      salePrice: (json['sale_price'] != '' && json['sale_price'] != null)
          ? safeParseDouble(
          json['sale_price'], -1.0) // Use -1 or another flag
          : null, // Explicitly null if empty or null
      imageUrl: extractImageUrl(json['images']),
      categoryId: extractRestaurantId(json),
      averageRating: safeParseDouble(json['average_rating']),
      ratingCount: safeParseInt(json['rating_count']),
      // 'isDeliverable' is set later by the CustomerProvider logic
      // 'quantity' defaults to 1 in the constructor
    );
  }

  // --- Getters ---

  // Returns the price to display (sale price if available, otherwise regular price)
  double get displayPrice => salePrice != null && salePrice! >= 0 ? salePrice! : price; // Check salePrice >= 0

  // Formats the display price for the UI (e.g., "3,375 د.ع")
  String get formattedPrice {
    // Use Iraqi Dinar format
    final format = NumberFormat('#,###', 'ar_IQ');
    return '${format.format(displayPrice)} د.ع';
  }

  // --- toJson() Method ---
  // Converts the FoodItem object back into a JSON map (useful for caching or sending data)
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'short_description': description, // Assumes description doesn't need HTML re-added
    'regular_price': price.toString(),
    'sale_price': salePrice?.toString() ?? '', // Convert null to empty string
    'images': [{'src': imageUrl}], // Matches fromJson structure
    'categories': [{'id': categoryId}], // Matches fromJson structure
    'average_rating': averageRating.toString(),
    'rating_count': ratingCount,
    // Note: 'quantity' and 'isDeliverable' are usually runtime states
    // and might not be needed when serializing back to basic product info.
  };

} // End of FoodItem class
class Order {
  final int id;
  final String status;
  final DateTime dateCreated;
  final String total;
  final String customerName;
  final String address;
  final String phone;
  final List<LineItem> lineItems;
  // --- ✨ الحقول الجديدة هنا ---
  final String? destinationLat;
  final String? destinationLng;

  Order({
    required this.id,
    required this.status,
    required this.dateCreated,
    required this.total,
    required this.customerName,
    required this.address,
    required this.phone,
    required this.lineItems,
    // --- ✨ أضفها إلى الكونستركتر ---
    this.destinationLat,
    this.destinationLng,
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
      // --- ✨ قراءة الحقول الجديدة من الـ JSON ---
      destinationLat: json['destination_lat'],
      destinationLng: json['destination_lng'],
    );
  }

  Map<String, dynamic> get statusDisplay {
    // ... (هذا الجزء يبقى كما هو)
    switch (status) {
      case 'processing':
        return {'text': 'جاري تحضير طلبك', 'icon': Icons.soup_kitchen_outlined, 'color': Colors.blue};
      case 'out-for-delivery':
        return {'text': 'طلبك في الطريق', 'icon': Icons.delivery_dining, 'color': Colors.orange.shade700};
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

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    await _localNotifications.initialize(initializationSettings);

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'new_orders_channel',
      'طلبات جديدة',
      description: 'إشعارات للطلبات الجديدة في المطعم.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      sound: RawResourceAndroidNotificationSound('woo_sound'),
    );

    await _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);
  }

  static Future<void> display(RemoteMessage message) async {
    final String title = message.notification?.title ?? message.data['title'] ?? 'تحديث جديد!';
    final String body = message.notification?.body ?? message.data['body'] ?? 'لديك تحديث جديد.';
    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: AndroidNotificationDetails('new_orders_channel', 'طلبات جديدة', importance: Importance.max, priority: Priority.high),
      iOS: DarwinNotificationDetails(sound: 'woo_sound.caf', presentSound: true, presentAlert: true, presentBadge: true),
    );
    await _localNotifications.show(id, title, body, platformChannelSpecifics, payload: message.data['order_id']);
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

  // ✨ --- استبدل الدالة القديمة بهذه --- ✨
  void addToCart(FoodItem foodItem, BuildContext context) {
    final existingIndex = _items.indexWhere((item) => item.id == foodItem.id);
    if (existingIndex != -1) {
      _items[existingIndex].quantity++;
    } else {
      _items.add(FoodItem(
          id: foodItem.id,
          name: foodItem.name,
          description: foodItem.description,
          price: foodItem.price,
          salePrice: foodItem.salePrice,
          imageUrl: foodItem.imageUrl,
          quantity: 1,
          categoryId: foodItem.categoryId,
          isDeliverable: foodItem.isDeliverable // <-- ✨ هذا هو التعديل المطلوب
      ));
    }
    notifyListeners();
    _showAddToCartDialog(context, foodItem);
  }

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

  Future<T> _executeWithRetry<T>(Future<T> Function() action) async {
    int attempts = 0;
    while (attempts < 3) {
      try {
        return await action().timeout(API_TIMEOUT);
      } catch (e) {
        attempts++;
        if (attempts >= 3) rethrow;
        await Future.delayed(Duration(seconds: attempts * 2));
      }
    }
    throw Exception('Failed after multiple retries');
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
  // ✨ --- [ تم تعديل هذه الدالة ] ---
  Future<List<Restaurant>> getAllRestaurants({required int areaId}) async {
    const fields = 'id,name,image,count,meta_data';
    // ✨ [الإصلاح 1]: تغيير per_page=10 إلى 100 لجلب كل المطاعم وحالاتها
    final url = '$BEYTEI_URL/wp-json/wc/v3/products/categories?parent=0&per_page=100&page=1&_fields=$fields&area_id=$areaId';
    // ✨ تم تعديل مفتاح الكاش ليشمل المنطقة (page 1 ثابت)
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
  // ✨ --- [ نهاية التعديل ] ---

  // ✨ --- [ دالة جديدة مضافة ] ---
  Future<Restaurant> getRestaurantById(int restaurantId) async {
    const fields = 'id,name,image,count,meta_data';
    // هذا الرابط يجلب مطعم واحد فقط
    final url = '$BEYTEI_URL/wp-json/wc/v3/products/categories/$restaurantId?_fields=$fields';

    return _executeWithRetry(() async {
      final response = await http.get(Uri.parse(url), headers: {'Authorization': _authString});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // (نفترض أن المطعم الذي يُطلب عن طريق الرابط هو صالح للتوصيل)
        final restaurant = Restaurant.fromJson(data);
        restaurant.isDeliverable = true;
        return restaurant;
      }
      throw Exception('Server error ${response.statusCode}');
    });
  }



  Future<List<FoodItem>> getMyRestaurantProducts(String token) async {
    return _executeWithRetry(() async {
      // (يجب إنشاء هذا المسار في الواجهة الخلفية)
      final response = await http.get(
        Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/my-products'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        // نستخدم نفس مودل FoodItem
        return data.map((json) => FoodItem.fromJson(json)).toList();
      }
      throw Exception('Failed to load restaurant products');
    });
  }

  // ✨ دالة لتحديث بيانات المنتج (للمدير)
  Future<bool> updateMyProduct(String token, int productId, String name, String price, String salePrice) async {
    return _executeWithRetry(() async {
      // (يجب إنشاء هذا المسار في الواجهة الخلفية)
      final response = await http.post(
        Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/update-product'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: json.encode({
          'product_id': productId,
          'name': name,
          'regular_price': price,
          'sale_price': salePrice,
        }),
      );
      return response.statusCode == 200;
    });
  }

// في ملف re.dart (تحت قسم SERVICES -> class ApiService)
// ✨ 1. أضف هذه الدالة الجديدة لجلب سعر التوصيل
  Future<Map<String, dynamic>> getDeliveryFee({
    required double restaurantLat,
    required double restaurantLng,
    required double customerLat,
    required double customerLng,
  }) async {
    return _executeWithRetry(() async {
      final response = await http.post(
        Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/get-delivery-fee'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'restaurant_lat': restaurantLat,
          'restaurant_lng': restaurantLng,
          'customer_lat': customerLat,
          'customer_lng': customerLng,
        }),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to get delivery fee');
    });
  }
// ✨ إضافة دالة جلب إعدادات المطعم للمدير
  Future<Map<String, dynamic>> getRestaurantSettings(String token) async {
    return _executeWithRetry(() async {
      final response = await http.get(
        // يجب إنشاء هذا المسار في الواجهة الخلفية!
        Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/get-settings'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to load settings');
    });
  }

// ✨ إضافة دالة تحديث حالة الفتح اليدوية للمدير
  Future<bool> updateRestaurantStatus(String token, bool isOpen) async {
    return _executeWithRetry(() async {
      final response = await http.post(
        // يجب إنشاء هذا المسار في الواجهة الخلفية!
        Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/update-status'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: json.encode({'is_open': isOpen ? 1 : 0}),
      );
      return response.statusCode == 200;
    });
  }

// ✨ إضافة دالة تحديث أوقات الفتح والإغلاق التلقائي للمدير
  Future<bool> updateRestaurantAutoTimes(String token, String openTime, String closeTime) async {
    return _executeWithRetry(() async {
      final response = await http.post(
        // يجب إنشاء هذا المسار في الواجهة الخلفية!
        Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/update-auto-times'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: json.encode({'open_time': openTime, 'close_time': closeTime}),
      );
      return response.statusCode == 200;
    });
  }

// ... بقية دوال ApiService
// (الصق هذا بدلاً من دالة getDeliverableRestaurantIds القديمة)

  Future<Set<int>> getDeliverableRestaurantIds(int areaId) async {
    // ✨ تم التعديل: توجيه الطلب إلى نقطة النهاية المخصصة الجديدة
    final url = '$BEYTEI_URL/wp-json/restaurant-app/v1/restaurants-by-area?area_id=$areaId';

    return _executeWithRetry(() async {
      // ✨ تم التعديل: إزالة 'Authorization' لأن نقطة النهاية الجديدة عامة ومتاحة للجميع
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // الاستجابة ستكون بالشكل التالي: [{id: 12}, {id: 15}]
        // هذا الكود سيقوم بتحويلها إلى Set<int> بشكل صحيح
        return (json.decode(response.body) as List).map<int>((item) => item['id']).toSet();
      }
      throw Exception('Failed to fetch deliverable restaurants (Custom Endpoint)');
    });
  }

  Future<List<FoodItem>> _getProducts(String params, String cacheKey, {required int areaId}) async {
    return _executeWithRetry(() async {
      const fields = 'id,name,regular_price,sale_price,images,categories,short_description,average_rating,rating_count';
      // ✨ لاحظ الإضافة: &area_id=$areaId (إلا إذا كانت 0)
      final areaParam = areaId == 0 ? '' : '&area_id=$areaId';
      final url = '$BEYTEI_URL/wp-json/wc/v3/products?$params&_fields=$fields$areaParam';

      final response = await http.get(Uri.parse(url), headers: {'Authorization': _authString});
      if (response.statusCode == 200) {
        await _cacheService.saveData(cacheKey, response.body);
        // لا نحتاج للفلترة هنا
        return (json.decode(response.body) as List).map((json) => FoodItem.fromJson(json)).toList();
      }
      throw Exception('Failed to fetch products');
    });
  }
  Future<List<FoodItem>> getOnSaleItems({required int areaId}) =>
      _getProducts('on_sale=true&per_page=20', 'onsale_items_area_$areaId', areaId: areaId);

  Future<List<FoodItem>> searchProducts({required int areaId, required String query}) =>
      _getProducts('search=$query&per_page=20', 'search_${query}_area_$areaId', areaId: areaId);

  // دالة جلب المنتجات بالتاغ
  Future<List<FoodItem>> getProductsByTag({required int areaId, required String tagName}) async {
    return _executeWithRetry(() async {
      final tagsResponse = await http.get(Uri.parse('$BEYTEI_URL/wp-json/wc/v3/products/tags?search=$tagName&_fields=id'), headers: {'Authorization': _authString});
      if (tagsResponse.statusCode != 200) throw Exception('Failed to find tag');
      final tags = json.decode(tagsResponse.body);
      if (tags.isEmpty) return [];
      final tagId = tags[0]['id'];

      // ✨ مرر areaId هنا
      return _getProducts('tag=$tagId&per_page=10', 'tag_${tagId}_area_$areaId', areaId: areaId);
    });
  }

  // ✨ --- [ تم تعديل هذه الدالة ] ---
  // تم تغيير per_page=10 إلى per_page=100 لجلب كل منتجات المنيو
  Future<List<FoodItem>> getMenuForRestaurant(int categoryId) =>
      _getProducts('category=$categoryId&per_page=100&page=1', 'menu_${categoryId}_page_1_limit_100', areaId: 0); // areaId: 0 هنا يعني "لا تفلتر حسب المنطقة"
  Future<Order?> submitOrder({
    required String name, required String phone, required String address,
    required List<FoodItem> cartItems, String? couponCode,
    geolocator.Position? position,
    double? deliveryFee, // <-- ✨ الإضافة الجديدة هنا
  }) async {

    List<Map<String, dynamic>> couponLines = couponCode != null && couponCode.isNotEmpty ? [{"code": couponCode}] : [];
// <-- ✨ الإضافة الجديدة هنا: تجهيز سطر الشحن
    List<Map<String, dynamic>> shippingLines = deliveryFee != null
        ? [{
      "method_id": "flat_rate",
      "method_title": "توصيل",
      "total": deliveryFee.toString()
    }]
        : [];
    // 1. جلب توكن FCM الحالي للزبون
    String? fcmToken = await FirebaseMessaging.instance.getToken();

    // 2. بناء الـ bodyPayload مع بيانات التوكن + الإحداثيات
    Map<String, dynamic> bodyPayload = {
      "payment_method": "cod", "payment_method_title": "الدفع عند الاستلام",
      "billing": {"first_name": name, "last_name":".", "phone": phone, "address_1": address, "country": "IQ", "city": "Default", "postcode":"10001", "email": "customer@example.com"},
      "shipping": {"first_name": name, "last_name":".", "address_1": address, "country": "IQ", "city": "Default", "postcode":"10001"},
      "line_items": cartItems.map((item) => {"product_id": item.id, "quantity": item.quantity}).toList(),
      "coupon_lines": couponLines,
      "shipping_lines": shippingLines, // <-- ✨ الإضافة الجديدة هنا
      // ✨ إرسال التوكن + الإحداثيات (هذا هو التعديل)
      "meta_data": [
        if (fcmToken != null)
          {"key": "_customer_fcm_token", "value": fcmToken},
        // --- ✨ الإضافة الجديدة هنا ---
        // (يجب أن يكون الـ Backend معداً لقراءة هذه الحقول)
        if (position != null)
          {"key": "_customer_destination_lat", "value": position.latitude.toString()},
        if (position != null)
          {"key": "_customer_destination_lng", "value": position.longitude.toString()}
        // --- نهاية الإضافة ---
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
  Future<Map<String, dynamic>> createUnifiedDeliveryRequest({
    required String token,
    required String sourceType, // 'restaurant', 'pharmacy', 'store', 'customer'
    required String pickupName,
    required double pickupLat,
    required double pickupLng,
    required String destinationAddress,
    // ملاحظة: إحداثيات الزبون قد لا تكون متوفرة دائماً من ووكومرس، لذا نجعلها اختيارية
    double? destinationLat,
    double? destinationLng,
    required String deliveryFee,
    required String orderDescription,
    required String endCustomerPhone,
    String? sourceOrderId, // اختياري: لربط الطلب برقم الطلب الأصلي
  }) async {
    return await _executeWithRetry(() async {
      final response = await http.post(
        // تأكد من أن هذا المسار يطابق الواجهة الخلفية تماماً
        // المسار الصحيح هو taxi/v2 وليس taxi-app/v1
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
          'destination_lat': destinationLat?.toString() ?? "0", // إرسال "0" إذا كانت غير متوفرة
          'destination_lng': destinationLng?.toString() ?? "0", // إرسال "0" إذا كانت غير متوفرة
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



  Future<void> registerDeviceToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) return;
    String? fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken == null) return;

    try {
      await http.post(
        Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/register-device'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: json.encode({'token': fcmToken}),
      ).timeout(API_TIMEOUT);
    } catch (e) { print("Error registering device token: $e"); }
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

  // ✨ --- الإضافة: أضف هذا المتغير هنا ---
  final String? pickupCode;
  // --- نهاية الإضافة ---

  const OrderCard({
    super.key,
    required this.order,
    required this.onStatusChanged,
    this.isCompleted = false,
    this.pickupCode, // <-- ✨ وأضفه هنا في الكونستركتر
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
              title: 'موقع الزبون', // عنوان مخصص للشاشة
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
  // =================================================================
  // --- ✨ تم تحديث هذه الدالة بالكامل بناءً على طلبك ✨ ---
  // (استخدام توكن التكسي + عنوان نصي إجباري + إحداثيات اختيارية)
  // =================================================================
  void _showDeliveryRequestDialog(BuildContext cardContext, Order order) { // 1. تم تغيير اسم المتغير إلى cardContext
    // controllers للحقول
    final feeController = TextEditingController();
    final pickupNameController = TextEditingController();
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    // --- ✨ جديد: متحكم لإدخال عنوان الزبون نصاً (قابل للتعديل) ---
    final destAddressController = TextEditingController(text: order.address);
    // --- نهاية الإضافة ---

    // --- منطق الملء التلقائي للبيانات ---
    final orderDetails = order.lineItems.map((item) => '- ${item.quantity} x ${item.name}').join('\n');
    notesController.text = 'توصيل طلب مطعم رقم #${order.id}\n'
        'المحتويات:\n$orderDetails';

    SharedPreferences.getInstance().then((prefs) {
      // ✨ تم تصحيح هذا السطر ليطابق الكود الذي أرسلته (كان restaurant_name)
      pickupNameController.text = prefs.getString('restaurant_name') ?? '';
    });
    // --- نهاية الملء التلقائي ---

    showDialog(
      context: cardContext, // 2. استخدم cardContext هنا لفتح النافذة
      barrierDismissible: false,
      builder: (dialogContext) { // هذا هو سياق النافذة المنبثقة (الخاطئ)
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (context, setDialogState) { // هذا 'context' هو نفسه 'dialogContext'
            return AlertDialog(
              title: const Text('طلب توصيل (تكسي بيتي)'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- 1. تفاصيل نقطة الاستلام ---
                      const Text("1. تفاصيل نقطة الاستلام:", style: TextStyle(fontWeight: FontWeight.bold)),
                      TextFormField(
                        controller: pickupNameController,
                        enabled: !isSubmitting,
                        decoration: const InputDecoration(labelText: 'اسم المطعم/الفرع'),
                        validator: (value) => value == null || value.isEmpty ? 'الحقل مطلوب' : null,
                      ),
                      const SizedBox(height: 16),

                      // --- 2. تفاصيل نقطة التوصيل والسعر ---
                      const Text("2. تفاصيل نقطة التوصيل والسعر:", style: TextStyle(fontWeight: FontWeight.bold)),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                        child: Text("الزبون: ${order.customerName}", style: const TextStyle(color: Colors.black54)),
                      ),

                      // --- ✨ حقل إدخال عنوان الزبون نصاً (قابل للتعديل) ---
                      TextFormField(
                        controller: destAddressController,
                        enabled: !isSubmitting,
                        maxLines: 2, // السماح بعدة أسطر للعنوان
                        decoration: const InputDecoration(labelText: 'عنوان توصيل الزبون'),
                        validator: (value) => value == null || value.isEmpty ? 'الحقل مطلوب' : null,
                      ),
                      // --- نهاية الإضافة ---

                      // زر عرض الخريطة (إذا كانت الإحداثيات الأصلية متوفرة)
                      if (order.destinationLat != null && order.destinationLat!.isNotEmpty)
                        TextButton.icon(
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('عرض موقع الزبون الأصلي (إن وجد)'),
                          onPressed: () => _launchMaps(cardContext, order.destinationLat, order.destinationLng),                        ),

                      const SizedBox(height: 10),
                      TextFormField(
                        controller: feeController,
                        enabled: !isSubmitting,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'أجرة التوصيل', hintText: 'مثال: 3000', suffixText: 'د.ع'),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'الرجاء إدخال أجرة التوصيل';
                          if (double.tryParse(value) == null) return 'الرجاء إدخال رقم صحيح';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // --- 3. حقل الملاحظات ---
                      TextFormField(
                        controller: notesController,
                        enabled: !isSubmitting,
                        maxLines: 4,
                        decoration: const InputDecoration(labelText: 'ملاحظات للسائق', border: OutlineInputBorder()),
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
                    if (formKey.currentState!.validate()) {
                      setDialogState(() => isSubmitting = true);
                      try {

                        // --- (هذا الجزء صحيح) ---
                        final prefs = await SharedPreferences.getInstance();
                        final restaurantToken = prefs.getString('jwt_token');
                        if (restaurantToken == null) throw Exception("لم يتم العثور على جلسة دخول مدير المطعم. أعد تسجيل الدخول.");
                        final double? restaurantLat = prefs.getDouble('restaurant_lat');
                        final double? restaurantLng = prefs.getDouble('restaurant_lng');
                        if (restaurantLat == null || restaurantLng == null) throw Exception("إحداثيات المطعم غير محفوظة. أعد تسجيل الدخول.");
                        final double? customerLat = double.tryParse(order.destinationLat ?? '');
                        final double? customerLng = double.tryParse(order.destinationLng ?? '');

                        // --- (إرسال الطلب - هذا الجزء صحيح) ---
                        final result = await _apiService.createUnifiedDeliveryRequest(
                          token: restaurantToken,
                          sourceType: 'restaurant',
                          sourceOrderId: order.id.toString(),
                          pickupName: pickupNameController.text,
                          pickupLat: restaurantLat,
                          pickupLng: restaurantLng,
                          destinationAddress: destAddressController.text,
                          destinationLat: customerLat,
                          destinationLng: customerLng,
                          deliveryFee: feeController.text,
                          orderDescription: notesController.text,
                          endCustomerPhone: order.phone,
                        );
                        // --- (نهاية جزء إرسال الطلب) ---

                        if (mounted) {
                          final code = result['pickup_code']?.toString();
                          if (code != null) {
                            // 3. ✨ --- [التصحيح الأهم] ---
                            // استخدم cardContext هنا بدلاً من context النافذة
                            Provider.of<DashboardProvider>(cardContext, listen: false)
                                .setPickupCode(order.id, code);
                          }
                          // --- [نهاية التصحيح] ---

                          await _updateStatus('out-for-delivery');
                          Navigator.of(dialogContext).pop(); // إغلاق النافذة (صحيح)

                          // 4. ✨ استخدم cardContext هنا لإظهار الـ SnackBar في المكان الصحيح
                          ScaffoldMessenger.of(cardContext).showSnackBar(
                            SnackBar(
                              content: Text(result['message'] ?? 'تم إرسال طلب التوصيل بنجاح!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          // 5. ✨ استخدم cardContext هنا
                          ScaffoldMessenger.of(cardContext).showSnackBar(
                            SnackBar(
                              content: Text('خطأ: ${e.toString().replaceAll("Exception: ", "")}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setDialogState(() => isSubmitting = false);
                        }
                      }
                    }
                  },
                  child: isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('إرسال الطلب للسائق'),
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

    return Card(
      clipBehavior: Clip.antiAlias, margin: const EdgeInsets.symmetric(vertical: 8), elevation: 4, shadowColor: Colors.black.withOpacity(0.1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          _buildCardHeader(context, formattedDate),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(Icons.person_outline, 'الزبون:', widget.order.customerName),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.location_on_outlined, 'العنوان:', widget.order.address),

                // --- ✨ الزر الجديد لعرض الخريطة ---
                if (widget.order.destinationLat != null && widget.order.destinationLat!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Center(
                      child: TextButton.icon(
                        icon: Icon(Icons.map_outlined, color: Theme.of(context).primaryColor),
                        label: Text(
                          'عرض موقع الزبون على الخريطة',
                          style: TextStyle(color: Theme.of(context).primaryColor),
                        ),
                        onPressed: () => _launchMaps(context, widget.order.destinationLat, widget.order.destinationLng),                      ),
                    ),
                  ),
                // --- نهاية الإضافة ---

                const SizedBox(height: 12),
                _buildInfoRow(Icons.phone_outlined, 'الهاتف:', widget.order.phone),

                const Divider(height: 32),
                if (widget.order.status == 'out-for-delivery' && widget.pickupCode != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.amber.shade600, width: 1.5)
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.key_outlined, color: Colors.amber.shade800),
                          const SizedBox(width: 10),
                          Text(
                              'رمز استلام السائق:',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade800)
                          ),
                          const SizedBox(width: 10),
                          Text(
                            widget.pickupCode!,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black, letterSpacing: 2),
                          ),
                        ],
                      ),
                    ),
                  ),
// --- نهاية الإضافة ---

                const Divider(height: 32),
                const Text('تفاصيل الطلب:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                ...widget.order.lineItems.map((item) => Padding(padding: const EdgeInsets.only(bottom: 6.0), child: Row(children: [Text('• ${item.quantity} ×', style: TextStyle(color: Colors.grey.shade700)), const SizedBox(width: 8), Expanded(child: Text(item.name))]))).toList(),
                const Divider(height: 32),
                _buildTotalAndCall(context, totalFormatted),
              ],
            ),
          ),
          if (_isUpdating) const Padding(padding: EdgeInsets.only(bottom: 16.0), child: Center(child: CircularProgressIndicator()))
          else if (!widget.isCompleted) ...[
            _buildActionButtons(context),
          ],
        ],
      ),
    );
  }

  Widget _buildCardHeader(BuildContext context, String formattedDate) {
    return Container(
      color: Colors.teal.withOpacity(0.05), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('طلب #${widget.order.id}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).primaryColor)),
        Text(formattedDate, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
      ]),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 20, color: Colors.grey.shade600),
      const SizedBox(width: 12),
      Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(width: 5),
      Expanded(child: Text(value, style: TextStyle(color: Colors.grey.shade800))),
    ]);
  }

  Widget _buildTotalAndCall(BuildContext context, String totalFormatted) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.center, children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('الإجمالي', style: TextStyle(color: Colors.grey.shade600)),
        Text('$totalFormatted د.ع', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ]),
      ElevatedButton.icon(
        onPressed: () => _makePhoneCall(widget.order.phone),
        icon: const Icon(Icons.call, size: 20),
        label: const Text('اتصال'),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade600, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
      ),
    ]);
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: () => _updateStatus('cancelled'), style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade700, side: BorderSide(color: Colors.red.shade200), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), padding: const EdgeInsets.symmetric(vertical: 12)), child: const Text('إلغاء الطلب'))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(onPressed: () => _updateStatus('completed'), style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), padding: const EdgeInsets.symmetric(vertical: 12)), child: const Text('إكمال الطلب'))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: ElevatedButton.icon(icon: const Icon(Icons.delivery_dining, color: Colors.white), label: const Text('إرسال للتوصيل', style: TextStyle(color: Colors.white, fontSize: 16)), onPressed: () => _updateStatus('out-for-delivery'), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade600, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), padding: const EdgeInsets.symmetric(vertical: 12)))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton.icon(icon: const Icon(Icons.two_wheeler, color: Colors.white), label: const Text('طلب تكسي بيتي', style: TextStyle(color: Colors.white, fontSize: 16)), onPressed: () => _showDeliveryRequestDialog(context, widget.order), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), padding: const EdgeInsets.symmetric(vertical: 12)))),
            ],
          ),
        ],
      ),
    );
  }
}
// (استبدل الكلاس القديم بهذا الكلاس المحدث)

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


class ShimmerHomeScreen extends StatelessWidget {
  const ShimmerHomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        children: [
          Container(margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), height: 50, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30))),
          Container(margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 10), height: 150, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Container(height: 20, width: 150, color: Colors.white), Container(height: 20, width: 70, color: Colors.white)]),
          ),
          SizedBox(height: 130, child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 5), itemCount: 5, itemBuilder: (context, index) => const ShimmerHorizontalRestaurantCard())),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            child: Container(height: 20, width: 200, color: Colors.white),
          ),
          SizedBox(height: 270, child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 5), itemCount: 3, itemBuilder: (context, index) => const ShimmerFoodCard())),
        ],
      ),
    );
  }
}

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
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      NotificationService.display(message);
      if (!mounted) return;

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.isLoggedIn) {
        // تحديث بيانات لوحة التحكم
        Provider.of<DashboardProvider>(context, listen: false).fetchDashboardData(authProvider.token);
        // ✨ NEW: تحديث إعدادات المطعم
        Provider.of<RestaurantSettingsProvider>(context, listen: false).fetchSettings(authProvider.token);
      }
      else {
        Provider.of<NotificationProvider>(context, listen: false).triggerRefresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()), // NEW
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        // ✨ NEW: إضافة RestaurantSettingsProvider
        ChangeNotifierProvider(create: (_) => RestaurantSettingsProvider()),

        ChangeNotifierProxyProvider<AuthProvider, DashboardProvider>(
          create: (_) => DashboardProvider(),
          update: (_, auth, dashboard) {
            if(auth.isLoggedIn && dashboard != null && auth.token != null) {
              // ضمان جلب البيانات بعد تسجيل الدخول مباشرة أو عند التحديث
              dashboard.fetchDashboardData(auth.token);
            }
            return dashboard!;
          },
        ),

        // ✨ NEW: ربط RestaurantSettingsProvider بـ AuthProvider
        ChangeNotifierProxyProvider<AuthProvider, RestaurantSettingsProvider>(
          create: (_) => RestaurantSettingsProvider(),
          update: (_, auth, settings) {
            if(settings != null && auth.isLoggedIn && auth.token != null) {
              // جلب الإعدادات عند تسجيل الدخول أو تحديث حالة الدخول
              settings.fetchSettings(auth.token);
            } else if (settings != null && !auth.isLoggedIn) {
              // مسح البيانات عند تسجيل الخروج
              settings.clearData();
            }
            return settings!;
          },
        ),

        // ✨ --- [ الإضافة الجديدة هنا ] ---
        // ربط Provider المنتجات الجديد بـ AuthProvider
        ChangeNotifierProxyProvider<AuthProvider, RestaurantProductsProvider>(
          create: (_) => RestaurantProductsProvider(),
          update: (_, auth, products) {
            if (products != null && auth.isLoggedIn && auth.token != null) {
              // جلب المنتجات عند تسجيل الدخول
              products.fetchProducts(auth.token);
            } else if (products != null && !auth.isLoggedIn) {
              // مسح البيانات عند تسجيل الخروج
              products.clearData();
            }
            return products!;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Beytei Restaurants',
        theme: ThemeData(primarySwatch: Colors.teal, scaffoldBackgroundColor: const Color(0xFFF5F5F5), fontFamily: 'Tajawal', appBarTheme: const AppBarTheme(backgroundColor: Colors.white, elevation: 0.5, iconTheme: IconThemeData(color: Colors.black), titleTextStyle: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Tajawal'))),
        debugShowCheckedModeBanner: false,
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
    final token = Provider.of<AuthProvider>(context, listen: false).token;
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

      final token = Provider.of<AuthProvider>(context, listen: false).token;

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
            final token = Provider.of<AuthProvider>(context, listen: false).token;
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
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        if (auth.isLoading) return const SplashScreen();
        if (auth.isLoggedIn) return const RestaurantDashboardScreen();
        return const LocationCheckWrapper();
      },
    );
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}


class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> bannerImages = ['https://beytei.com/wp-content/uploads/2023/05/banner1.jpg', 'https://beytei.com/wp-content/uploads/2023/05/banner2.jpg', 'https://beytei.com/wp-content/uploads/2023/05/banner3.jpg'];
  int? _selectedAreaId;
  String? _selectedAreaName;

  @override
  void initState() {
    super.initState();
    // تأكد من أننا نحمّل بيانات الولاء في CartProvider عند بدء التشغيل
    // (هذه الخطوة تتم ضمن دورة حياة Provider في MaterialApp)
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
  }

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    _selectedAreaId = prefs.getInt('selectedAreaId');
    _selectedAreaName = prefs.getString('selectedAreaName');
    if (_selectedAreaId != null) {
      Provider.of<CustomerProvider>(context, listen: false).fetchHomeData(_selectedAreaId!);
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
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => SearchScreen(searchQuery: query, selectedAreaId: _selectedAreaId!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () async {
            final result = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SelectLocationScreen(isCancellable: true)));
            if (result == true) _loadInitialData();
          },
          child: Row(mainAxisSize: MainAxisSize.min, children: [Text(_selectedAreaName ?? "اختر منطقة", style: const TextStyle(fontSize: 16)), const Icon(Icons.keyboard_arrow_down, size: 20)]),
        ),
        centerTitle: true,
        actions: [IconButton(icon: const Icon(Icons.login), tooltip: "دخول مدير المطعم", onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RestaurantLoginScreen())))],
      ),
      body: Consumer<CustomerProvider>(
        builder: (context, provider, child) {
          if (_selectedAreaId == null) {
            return const Center(child: Text("يرجى تحديد منطقة لعرض المطاعم"));
          }
          if (provider.isLoadingHome && provider.homeData.isEmpty) {
            return const ShimmerHomeScreen();
          }
          if (provider.hasError && provider.homeData.isEmpty) {
            return NetworkErrorWidget(message: 'تحقق من اتصال الانترنيت .', onRetry: () => provider.fetchHomeData(_selectedAreaId!));
          }

          final restaurants = (provider.homeData['restaurants'] as List<dynamic>? ?? []).cast<Restaurant>();
          final onSale = (provider.homeData['onSale'] as List<dynamic>? ?? []).cast<FoodItem>();
          final breakfast = (provider.homeData['breakfast'] as List<dynamic>? ?? []).cast<FoodItem>();
          final family = (provider.homeData['family'] as List<dynamic>? ?? []).cast<FoodItem>();

          return RefreshIndicator(
            onRefresh: () => provider.fetchHomeData(_selectedAreaId!),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              children: [

                // ✨ NEW: إضافة ويدجت التحدي والولاء
                const LoyaltyChallengeWidget(),

                Padding(padding: const EdgeInsets.symmetric(horizontal: 20.0), child: _buildSearchBar()),
                const SizedBox(height: 20),
                _buildBannerSlider(),
                _buildSection<Restaurant>(title: 'المطاعم', onViewAll: () => Provider.of<NavigationProvider>(context, listen: false).changeTab(1), items: restaurants, listBuilder: (items) => _buildRestaurantsList(items)),
                _buildSection<FoodItem>(title: 'عروض وخصومات', items: onSale, listBuilder: (items) => _buildFoodsList(items)),
                _buildSection<FoodItem>(title: 'الفطور', items: breakfast, listBuilder: (items) => _buildFoodsList(items)),
                _buildSection<FoodItem>(title: 'وجبات عائلية', items: family, listBuilder: (items) => _buildFoodsList(items)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection<T>({required String title, VoidCallback? onViewAll, required List<T> items, required Widget Function(List<T>) listBuilder}) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(children: [
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20.0), child: _buildSectionTitle(title, onViewAll)),
      const SizedBox(height: 10),
      listBuilder(items),
      const SizedBox(height: 20),
    ]);
  }

  Widget _buildBannerSlider() => CarouselSlider(options: CarouselOptions(height: 150.0, autoPlay: true, enlargeCenterPage: true, aspectRatio: 16/9, viewportFraction: 0.9), items: bannerImages.map((i) => Builder(builder: (ctx) => Container(width: MediaQuery.of(ctx).size.width, margin: const EdgeInsets.symmetric(horizontal: 5.0), decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), image: DecorationImage(image: CachedNetworkImageProvider(i), fit: BoxFit.cover))))).toList());
  Widget _buildSearchBar() => TextField(controller: _searchController, textInputAction: TextInputAction.search, onSubmitted: _onSearchSubmitted, decoration: InputDecoration(hintText: 'ابحث عن وجبة أو مطعم...', prefixIcon: const Icon(Icons.search, color: Colors.grey), border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none), filled: true, fillColor: Colors.grey.shade100, contentPadding: EdgeInsets.zero));
  Widget _buildSectionTitle(String title, VoidCallback? onViewAll) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), if(onViewAll != null) TextButton(onPressed: onViewAll, child: Text('عرض الكل', style: TextStyle(color: Theme.of(context).primaryColor)))]);
  Widget _buildFoodsList(List<FoodItem> foods) => SizedBox(height: 270, child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 5), itemCount: foods.length, itemBuilder: (context, index) => FoodCard(food: foods[index])));
  Widget _buildRestaurantsList(List<Restaurant> restaurants) => SizedBox(height: 130, child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 5), itemCount: restaurants.length > 5 ? 5 : restaurants.length, itemBuilder: (context, index) => HorizontalRestaurantCard(restaurant: restaurants[index])));
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

  Future<void> _saveSelection(int areaId, String areaName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selectedAreaId', areaId);
    await prefs.setString('selectedAreaName', areaName);
    if(mounted) {
      if (widget.isCancellable) {
        Navigator.of(context).pop(true);
      } else {
        Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LocationCheckWrapper()), (route) => false);
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
      // ✨ تم التعديل: الخادم يقوم بالفلترة، نحتاج فقط لجلب الحالات
      _searchFuture = _apiService.searchProducts(areaId: widget.selectedAreaId, query: widget.searchQuery).then((allResults) async {

        // نحتاج معرفة حالة المطاعم التي ظهرت في البحث
        final provider = Provider.of<CustomerProvider>(context, listen: false);
        // محاولة جلب الحالات من القوائم المحملة مسبقاً
        final statusMap = { for (var r in provider.allRestaurants) r.id : r.isOpen };
        // (يمكن تحسين هذا بجلب المطاعم التي لا نعرف حالتها، ولكنه جيد كنقطة بداية)

        return allResults.map((item) {
          // تطبيق الحالة
          item.isDeliverable = statusMap[item.categoryId] ?? false; // الافتراضي مغلق إذا لم نجد المطعم
          return item;
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

  Widget _buildPriceSummary(CartProvider cart, double? deliveryFee, bool isCalculatingFee) {
    final totalFormatted = NumberFormat('#,###', 'ar_IQ').format(cart.totalPrice);
    final discountFormatted = NumberFormat('#,###', 'ar_IQ').format(cart.totalDiscountAmount);

    // حساب الإجمالي النهائي
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
          // 1. سعر الطلبات
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('سعر الطلبات', style: TextStyle(fontSize: 14)),
              Text('$totalFormatted د.ع', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),

          // 2. الخصم (إن وجد)
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

          // 3. خدمة التوصيل (الجزء العصري)
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // --- هذا هو الجزء المقنع ---
              Row(
                children: [
                  Icon(Icons.delivery_dining_outlined, size: 20, color: Colors.blue.shade700),
                  const SizedBox(width: 5),
                  const Text('خدمة التوصيل', style: TextStyle(fontSize: 14)),
                ],
              ),
              // ---------------------------

              // --- هذا هو الجزء الديناميكي ---
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                child: isCalculatingFee
                    ? const SizedBox(key: ValueKey('calc'), width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(
                  deliveryFee != null ? '${NumberFormat('#,###', 'ar_IQ').format(deliveryFee)} د.ع' : '---',
                  key: const ValueKey('fee'),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              // ---------------------------
            ],
          ),

          const Divider(height: 20),

          // 4. الإجمالي النهائي
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('الإجمالي المطلوب دفعه', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: isCalculatingFee || deliveryFee == null
                    ? const SizedBox.shrink() // إخفاء الإجمالي حتى يكتمل الحساب
                    : Text(
                  '$finalTotalFormatted د.ع',
                  key: ValueKey(finalTotalFormatted), // مفتاح لضمان التحريك
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          if (!isCalculatingFee && deliveryFee != null)
            const Text(
              "سيتم توصيل طلبك طازجاً وساخناً إلى باب البيت .",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            )

        ],
      ),
    );
  }

  void _showCheckoutDialog(BuildContext context, CartProvider cart) {
    _nameController.clear();
    _phoneController.clear();
    _addressController.clear();
    _couponController.text = cart.appliedCoupon ?? '';
    bool isSubmitting = false;

    // --- ✨ متغيرات الحالة الجديدة للنافذة ---
    bool _shareLocation = true;
    geolocator.Position? _capturedPosition;
    bool _isGettingLocation = true;
    String _locationMessage = "جاري تحديد موقعك...";

    // --- ✨ متغيرات سعر التوصيل العصرية ---
    double? _deliveryFee;
    bool _isCalculatingFee = false;
    String _feeMessage = "جاري حساب كلفة التوصيل...";
    // ---

    showDialog(
      context: context,
      barrierDismissible: !isSubmitting,
      builder: (dialogContext) {
        return StatefulBuilder(builder: (context, setDialogState) {

          // --- ✨ دالة جلب الموقع (معدلة) ---
          Future<void> getCurrentLocation() async {
            setDialogState(() {
              _isGettingLocation = true;
              _locationMessage = "جاري تحديد موقعك...";
              _deliveryFee = null; // إعادة تعيين السعر
              _isCalculatingFee = true; // البدء بحساب السعر
              _feeMessage = "جاري حساب كلفة التوصيل...";
            });

            final hasPermission = await PermissionService.handleLocationPermission(context);
            if (!hasPermission) {
              setDialogState(() {
                _isGettingLocation = false;
                _locationMessage = "تم رفض إذن الموقع!";
                _isCalculatingFee = false;
                _feeMessage = "لا يمكن حساب السعر بدون موقع.";
                _shareLocation = false;
              });
              return;
            }

            try {
              // 1. التقاط موقع الزبون
              _capturedPosition = await geolocator.Geolocator.getCurrentPosition(
                  desiredAccuracy: geolocator.LocationAccuracy.high);

              setDialogState(() {
                _isGettingLocation = false;
                _locationMessage = "تم تحديد الموقع بنجاح!";
              });

              // 2. جلب إحداثيات المطعم (من الذاكرة)
              // (نحتاج AuthProvider لجلب إحداثيات المطعم المخزنة)
              // ملاحظة: هذا يتطلب أن تكون إحداثيات المطعم محفوظة!
              // هذا الكود يفترض أنك تستخدم `re.dart` الذي أرسلته سابقاً
              // وأن المطعم قام بتسجيل الدخول وحفظ إحداثياته

              // --- هذا الجزء يحتاج تعديل بناءً على منطق تطبيقك ---
              // كيف سنعرف إحداثيات المطعم الذي يطلب منه الزبون؟
              // الحل الأسهل: جلب إحداثيات *أول مطعم* في السلة
              // (نفترض أن السلة من مطعم واحد)

              if (cart.items.isEmpty) throw Exception("السلة فارغة!");
              final restaurantId = cart.items.first.categoryId;

              // (يجب تعديل ApiService لإضافة دالة جلب إحداثيات المطعم)
              // كحل مؤقت، سنستخدم إحداثيات ثابتة للاختبار
              // final restaurantLat = 32.5000; // مثال: إحداثيات مطعم ثابتة
              // final restaurantLng = 44.4000;

              // --- الحل الأفضل: جلب المطعم من CustomerProvider ---
              final restaurant = Provider.of<CustomerProvider>(context, listen: false)
                  .allRestaurants
                  .firstWhere((r) => r.id == restaurantId);

              // (هذا يتطلب أن نموذج Restaurant يحتوي على lat/lng)
              // إذا لم يكن موجوداً، يجب تعديل API جلب المطاعم

              // ----------------------------------------------------
              // --- ✨ سنفترض وجود الإحداثيات الآن للمتابعة ---
              // (استخدم إحداثيات اختبارية إذا لم تكن جاهزة)
              // ----------------------------------------------------
              final prefs = await SharedPreferences.getInstance();
              final double? restaurantLat = prefs.getDouble('restaurant_lat');
              final double? restaurantLng = prefs.getDouble('restaurant_lng');

              if (restaurantLat == null || restaurantLng == null) {
                throw Exception("إحداثيات المطعم غير معرفة. (يجب على المدير تسجيل الدخول وتحديدها)");
              }

              // 3. جلب سعر التوصيل من الخادم
              final feeResponse = await _apiService.getDeliveryFee(
                restaurantLat: restaurantLat,
                restaurantLng: restaurantLng,
                customerLat: _capturedPosition!.latitude,
                customerLng: _capturedPosition!.longitude,
              );

              setDialogState(() {
                _deliveryFee = (feeResponse['delivery_fee'] as num).toDouble();
                _isCalculatingFee = false;
                _feeMessage = "كلفة التوصيل: ${feeResponse['delivery_fee']} د.ع (مسافة ${feeResponse['distance_km']} كم)";
              });

            } catch (e) {
              setDialogState(() {
                _isGettingLocation = false;
                _isCalculatingFee = false;
                _locationMessage = "فشل تحديد الموقع.";
                _feeMessage = "خطأ: ${e.toString().replaceAll("Exception: ", "")}";
              });
            }
          }

          // --- استدعاء الدالة تلقائياً ---
          if (_isGettingLocation && !isSubmitting) {
            getCurrentLocation();
          }

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
                    TextFormField(controller: _addressController, decoration: const InputDecoration(labelText: 'العنوان بالتفصيل (اختياري)'), maxLines: 2, enabled: !isSubmitting),
                    const SizedBox(height: 15),

                    // --- ويدجت الموقع (كما هو) ---
                    SwitchListTile(
                      title: Text(_locationMessage, style: TextStyle(color: _locationMessage.contains('فشل') || _locationMessage.contains('رفض') ? Colors.red : Colors.black87)),
                      value: _shareLocation,
                      secondary: _isGettingLocation
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(Icons.my_location, color: Theme.of(context).primaryColor),
                      onChanged: isSubmitting ? null : (value) {
                        setDialogState(() => _shareLocation = value);
                        if (_shareLocation) getCurrentLocation();
                        else {
                          setDialogState(() {
                            _capturedPosition = null;
                            _locationMessage = "استخدام موقعي الحالي للتوصيل";
                            _deliveryFee = null;
                            _feeMessage = "يجب تحديد الموقع لحساب التوصيل";
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 15),
                    TextFormField(controller: _couponController, decoration: InputDecoration(labelText: 'كود الخصم (إن وجد)', suffixIcon: TextButton(child: const Text("تطبيق"), onPressed: () async {
                      final result = await cart.applyCoupon(_couponController.text);
                      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']), backgroundColor: result['valid'] ? Colors.green : Colors.red));
                      setDialogState(() {});
                    }))),

                    // --- ✨ العرض العصري والحديث للسعر ---
                    const Divider(height: 30),
                    _buildPriceSummary(cart, _deliveryFee, _isCalculatingFee),
                    // --- نهاية العرض العصري ---

                  ],
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(onPressed: isSubmitting ? null : () => Navigator.of(dialogContext).pop(), child: const Text('إلغاء')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),

                // --- ✨ تعطيل الزر حتى يتم حساب السعر ---
                onPressed: isSubmitting || _isCalculatingFee || _deliveryFee == null
                    ? null // <-- تعطيل الزر
                    : () async {
                  // ... (نفس منطق الإرسال)
                  if (!_formKey.currentState!.validate()) return;
                  if (_shareLocation && _capturedPosition == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء الانتظار حتى يتم تحديد موقعك.'), backgroundColor: Colors.orange));
                    return;
                  }

                  setDialogState(() => isSubmitting = true);
                  try {
                    final createdOrder = await _apiService.submitOrder(
                        name: _nameController.text,
                        phone: _phoneController.text,
                        address: _addressController.text.isNotEmpty ? _addressController.text : "تم تحديد الموقع على الخريطة",
                        cartItems: cart.items,
                        couponCode: cart.appliedCoupon,
                        position: _capturedPosition,
                        deliveryFee: _deliveryFee // <-- ✨ إرسال السعر
                    );

                    if (!mounted) return;
                    if (createdOrder == null) throw Exception('فشل إنشاء الطلب على السيرفر.');

                    Navigator.of(dialogContext).pop();
                    cart.clearCart();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ تم تأكيد وارسال طلبك الى مطعم  رقم #${createdOrder.id}!'), duration: const Duration(seconds: 5), action: SnackBarAction(label: 'سجل الطلبات', onPressed: () => Provider.of<NavigationProvider>(context, listen: false).changeTab(2))));
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في إرسال الطلب: ${e.toString()}')));
                  } finally {
                    if (mounted) setDialogState(() => isSubmitting = false);
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

  // دالة تحديد الموقع الحالي
  Future<void> _getCurrentLocation() async {
    setState(() => _locationStatus = 'جاري تحديد الموقع...');

    try {
      // 1. طلب الصلاحيات
      // تأكد من استيراد LocationPermission و Position من 'package:geolocator/geolocator.dart'
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('صلاحية الوصول للموقع مرفوضة.');
      }

      // 2. الحصول على الموقع
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
        _locationStatus = 'خطأ في تحديد الموقع: ${e.toString()}';
        _latController.clear();
        _lngController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('الرجاء تفعيل خدمة الموقع.')));
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

    // ✨ الاستدعاء الآن صحيح بعد تعديل دالة login في AuthProvider
    final success = await authProvider.login(
      _usernameController.text,
      _passwordController.text,
      restaurantLat: _latController.text,
      restaurantLng: _lngController.text,
    );

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل تسجيل الدخول. الرجاء التأكد من البيانات.')));
    }
    setState(() => _isLoading = false);
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
          initialZoom: 16.0, // تقريب عالي لرؤية الموقع بوضوح
        ),
        children: [
          // 1. طبقة الخريطة الأساسية (نفس المستخدمة في تطبيق التكسي)
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.beytei.restaurantmodule', // يمكنك تغيير هذا الاسم
          ),
          // 2. طبقة الماركر (لتحديد الموقع)
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
      ),
    );
  }
}







class RestaurantDashboardScreen extends StatefulWidget {
  const RestaurantDashboardScreen({super.key});
  @override
  State<RestaurantDashboardScreen> createState() => _RestaurantDashboardScreenState();
}

class _RestaurantDashboardScreenState extends State<RestaurantDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    // ✨ --- [ تم التعديل ] ---
    // تم تغيير طول الـ TabController إلى 5
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
// (داخل class _RestaurantDashboardScreenState)
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

    // ✨ [جديد]: تحميل الاسم المحفوظ مسبقاً
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
                        controller: _pickupNameController, // الحقل موجود
                        decoration: const InputDecoration(labelText: 'اسم المطعم/المصدر (الاستلام)'),
                        validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null,
                      ),
                      const SizedBox(height: 12),
                      // ... (بقية الحقول: عنوان الزبون، الهاتف، الأجرة... الخ)
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
                          throw Exception("بيانات المطعم غير كاملة. يرجى تسجيل الخروج والدخول مرة أخرى.");
                        }

                        final pickupName = _pickupNameController.text;

                        // ✨ [جديد]: حفظ الاسم المدخل لاستخدامه لاحقاً
                        await prefs.setString('saved_restaurant_name', pickupName);

                        final double? destLat = double.tryParse(_destLatController.text);
                        final double? destLng = double.tryParse(_destLngController.text);

                        final result = await _apiService.createUnifiedDeliveryRequest(
                          token: token,
                          sourceType: 'restaurant',
                          pickupName: pickupName, // استخدام الاسم من الحقل
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

        // ✨ --- [ تم التعديل هنا ] ---
        bottom: TabBar(
            controller: _tabController,
            isScrollable: true, // للسماح بعرض 5 تبويبات
            tabs: const [
              Tab(icon: Icon(Icons.list_alt), text: 'الطلبات'),
              Tab(icon: Icon(Icons.history), text: 'المكتملة'),
              Tab(icon: Icon(Icons.fastfood_outlined), text: 'المنتجات'), // ✨ التبويب الجديد
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
          const ProductManagementTab(), // ✨ الشاشة الجديدة
          const RatingsDashboardScreen(),
          const RestaurantSettingsScreen(),
        ],
      ),
      // --- [ نهاية التعديل ] ---

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

// (أضف هذين الكلاسين الجديدين في نهاية الملف)

// =======================================================================
// --- ✨ شاشة جديدة: تبويب إدارة المنتجات ---
// =======================================================================
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
    // (context) هنا هو سياق شاشة الإدارة
    final productProvider = Provider.of<RestaurantProductsProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final bool? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProductScreen(
          product: product,
          // تمرير الـ Providers إلى الشاشة التالية
          productProvider: productProvider,
          authProvider: authProvider,
        ),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم تحديث المنتج بنجاح"), backgroundColor: Colors.green),
      );
      // (لا نحتاج لعمل fetch هنا لأن الـ provider سيقوم بذلك)
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return Consumer<RestaurantProductsProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            // شريط البحث
            title: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ابحث عن منتج...',
                prefixIcon: const Icon(Icons.search),
                border: InputBorder.none,
                filled: false,
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
                return const Center(child: Text("لم يتم العثور على منتجات لهذا المطعم."));
              }

              return ListView.builder(
                itemCount: provider.products.length,
                itemBuilder: (context, index) {
                  final product = provider.products[index];
                  return ListTile(
                    leading: CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorWidget: (c, u, e) => const Icon(Icons.fastfood),
                    ),
                    title: Text(product.name),
                    subtitle: Text("السعر: ${product.formattedPrice}", style: TextStyle(color: product.salePrice != null ? Colors.red : Colors.black)),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () => _navigateToEditScreen(product),
                  );
                },
              );
            }(),
          ),
          // (يمكنك إضافة زر لإضافة منتج جديد هنا لاحقاً)
          // floatingActionButton: FloatingActionButton(
          //   onPressed: () { /* _navigateToAddScreen() */ },
          //   child: Icon(Icons.add),
          // ),
        );
      },
    );
  }
}

// =======================================================================
// --- ✨ شاشة جديدة: تعديل المنتج ---
// =======================================================================
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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _priceController = TextEditingController(text: widget.product.price.toStringAsFixed(0)); // السعر بدون كسور
    _salePriceController = TextEditingController(text: widget.product.salePrice?.toStringAsFixed(0) ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _salePriceController.dispose();
    super.dispose();
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
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context, true); // إرجاع "true" لإعلام الشاشة السابقة بالنجاح
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
      appBar: AppBar(
        title: Text("تعديل: ${widget.product.name}"),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                CachedNetworkImage(
                  imageUrl: widget.product.imageUrl,
                  height: 200,
                  fit: BoxFit.cover,
                  errorWidget: (c, u, e) => const Icon(Icons.fastfood, size: 100),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'اسم المنتج'),
                  validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'السعر العادي (د.ع)'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _salePriceController,
                  decoration: const InputDecoration(labelText: 'سعر الخصم (د.ع) - (اتركه فارغاً لإلغاء الخصم)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 18, fontFamily: 'Tajawal', fontWeight: FontWeight.bold)
                  ),
                  child: const Text('حفظ التعديلات'),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}class OrdersListScreen extends StatefulWidget {
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
        if (dashboard.hasNetworkError && (dashboard.orders[widget.status] == null || dashboard.orders[widget.status]!.isEmpty)) {
          return NetworkErrorWidget(message: dashboard.errorMessage, onRetry: () => dashboard.fetchDashboardData(authProvider.token));
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

class _RatingsDashboardScreenState extends State<RatingsDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return Consumer<DashboardProvider>(
        builder: (context, dashboard, child) {
          if (dashboard.isLoading && dashboard.ratingsDashboard == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (dashboard.hasNetworkError && dashboard.ratingsDashboard == null) {
            return NetworkErrorWidget(message: dashboard.errorMessage, onRetry: () => dashboard.fetchDashboardData(authProvider.token));
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

