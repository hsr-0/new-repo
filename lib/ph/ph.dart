import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:badges/badges.dart' as badges;
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:mime/mime.dart';
import 'package:qr_flutter/qr_flutter.dart';

// =======================================================================
// --- GLOBAL NAVIGATOR KEY ---
// =======================================================================
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// =======================================================================
// --- API & APP CONSTANTS ---
// =======================================================================
class ApiConstants {
  static const String YOUR_DOMAIN = 'https://ph.beytei.com';
  static const String BASE_URL = '$YOUR_DOMAIN/wp-json';
  static const String PHARMACY_API_URL = '$BASE_URL/beytei-pharmacy/v1';
  static const String JWT_URL = '$BASE_URL/jwt-auth/v1/token';
  static const String BANNERS_URL = 'https://banner.beytei.com/images/banners.json';
}

class AppConstants {
  static const String prefsKeyToken = 'pharmacyToken';
  static const String prefsKeyAreaId = 'pharmacy_selectedAreaId';
  static const String prefsKeyAreaName = 'pharmacy_selectedAreaName';

  // Cache Keys
  static const String cacheKeyHome = 'cache_home_data_';
  static const String cacheKeyProducts = 'cache_products_list';
  static const String cacheKeyPharmacies = 'cache_all_pharmacies';
  static const String cacheKeyDashboard = 'cache_pharmacy_dashboard';
}

// =======================================================================
// --- API SERVICE (Retry Logic) ---
// =======================================================================
class ApiService {
  static const Duration API_TIMEOUT = Duration(seconds: 20);

  Future<T> _executeWithRetry<T>(Future<T> Function() action) async {
    int attempts = 0;
    while (attempts < 3) {
      try {
        return await action().timeout(API_TIMEOUT);
      } catch (e) {
        attempts++;
        String error = e.toString();
        // Don't retry on auth errors or client errors
        if (error.contains('401') || error.contains('403')) rethrow;

        if (attempts >= 3) rethrow;
        int delay = pow(2, attempts).toInt();
        print("⚠️ فشل الاتصال، إعادة المحاولة بعد $delay ثواني...");
        await Future.delayed(Duration(seconds: delay));
      }
    }
    throw Exception('Failed after retries');
  }

  Future<String> getPharmaciesRaw(int areaId) async {
    return _executeWithRetry(() async {
      final response = await http.get(Uri.parse('${ApiConstants.PHARMACY_API_URL}/pharmacies?area_id=$areaId'));
      if (response.statusCode == 200) return response.body;
      throw Exception('Server Error: ${response.statusCode}');
    });
  }

  Future<String> getAllPharmaciesRaw() async {
    return _executeWithRetry(() async {
      final response = await http.get(Uri.parse('${ApiConstants.PHARMACY_API_URL}/pharmacies'));
      if (response.statusCode == 200) return response.body;
      throw Exception('Server Error: ${response.statusCode}');
    });
  }

  Future<String> getProductsRaw() async {
    return _executeWithRetry(() async {
      final response = await http.get(Uri.parse('${ApiConstants.PHARMACY_API_URL}/products'));
      if (response.statusCode == 200) return response.body;
      throw Exception('Server Error');
    });
  }

  Future<String> getDashboardRaw(String token) async {
    return _executeWithRetry(() async {
      final response = await http.get(
        Uri.parse('${ApiConstants.PHARMACY_API_URL}/pharmacy/dashboard'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) return response.body;
      throw Exception('Server Error');
    });
  }
}

// =======================================================================
// --- MODELS ---
// =======================================================================
class Pharmacy {
  final int id;
  final String name;
  final String logoUrl;
  Pharmacy({required this.id, required this.name, required this.logoUrl});
  factory Pharmacy.fromJson(Map<String, dynamic> json) => Pharmacy(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'صيدلية غير مسماة',
      logoUrl: json['logo_url'] ?? '');
}

class Product {
  final int id;
  final String name;
  final String imageUrl;
  final String price;
  final int pharmacyId;
  Product({required this.id, required this.name, required this.imageUrl, required this.price, required this.pharmacyId});
  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] ?? 0,
    name: json['name'] ?? 'منتج غير مسمى',
    imageUrl: json['imageUrl'] ?? '',
    price: json['price']?.toString() ?? '0',
    pharmacyId: json['pharmacyId'] ?? 0,
  );
}

class PharmacyProductGroup {
  final int pharmacyId;
  final String pharmacyName;
  final List<Product> products;
  PharmacyProductGroup({required this.pharmacyId, required this.pharmacyName, required this.products});
  factory PharmacyProductGroup.fromJson(Map<String, dynamic> json) {
    return PharmacyProductGroup(
      pharmacyId: json['pharmacy_id'] ?? 0,
      pharmacyName: json['pharmacy_name'] ?? 'صيدلية غير مسماة',
      products: (json['products'] as List? ?? []).map((prod) => Product.fromJson(prod)).toList(),
    );
  }
}

class OrderItem {
  final String name;
  final int quantity;
  OrderItem({required this.name, required this.quantity});
  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(name: json['name'] ?? '', quantity: json['quantity'] ?? 0);
}

class DriverInfo {
  final String name;
  final String phone;
  final String vehicleType;
  final String carModel;
  final String carColor;
  DriverInfo({required this.name, required this.phone, required this.vehicleType, required this.carModel, required this.carColor});
  factory DriverInfo.fromJson(Map<String, dynamic> json) {
    return DriverInfo(
      name: json['name'] ?? 'غير متوفر',
      phone: json['phone'] ?? 'غير متوفر',
      vehicleType: json['vehicle_type'] ?? '',
      carModel: json['car_model'] ?? '',
      carColor: json['car_color'] ?? '',
    );
  }
}

class Order {
  final int id;
  final String customerName;
  final String customerPhone;
  final String customerArea;
  final String total;
  final String status;
  final DateTime date;
  final List<OrderItem> items;
  final String customerFirebaseUid;
  final String? deliveryStatus;
  final String? deliveryQrCode;
  final DriverInfo? driverInfo;

  Order({
    required this.id, required this.customerName, required this.customerPhone,
    required this.customerArea, required this.total, required this.status,
    required this.date, required this.items, required this.customerFirebaseUid,
    this.deliveryStatus, this.deliveryQrCode, this.driverInfo,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? 0,
      customerName: json['customer_name'] ?? '',
      customerPhone: json['customer_phone'] ?? '',
      customerArea: json['customer_area'] ?? '',
      total: json['total']?.toString() ?? '0',
      status: json['status'] ?? '',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      items: (json['items'] as List? ?? []).map((item) => OrderItem.fromJson(item)).toList(),
      customerFirebaseUid: json['customer_firebase_uid'] ?? '',
      deliveryStatus: json['delivery_status'],
      deliveryQrCode: json['delivery_qr_code'],
      driverInfo: json['driver_info'] != null ? DriverInfo.fromJson(json['driver_info']) : null,
    );
  }
}

class SubscriptionRequest {
  final int id;
  final String name;
  final String phone;
  final String illnessType;
  final DateTime date;
  SubscriptionRequest({required this.id, required this.name, required this.phone, required this.illnessType, required this.date});
  factory SubscriptionRequest.fromJson(Map<String, dynamic> json) {
    return SubscriptionRequest(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      illnessType: json['illness_type'] ?? '',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
    );
  }
}

class Conversation {
  final String uid;
  final String name;
  final String fcmToken;
  final int unreadCount;
  final int lastMessageTime;
  Conversation({required this.uid, required this.name, required this.fcmToken, required this.unreadCount, required this.lastMessageTime});
  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      uid: json['uid'] ?? '',
      name: json['name'] ?? 'مستخدم',
      fcmToken: json['fcm_token'] ?? '',
      unreadCount: json['unread_count'] ?? 0,
      lastMessageTime: json['last_message_time'] ?? 0,
    );
  }
}

class Area {
  final int id;
  final String name;
  final int parentId;
  Area({required this.id, required this.name, required this.parentId});
  factory Area.fromJson(Map<String, dynamic> json) => Area(id: json['id'] ?? 0, name: json['name'] ?? 'منطقة', parentId: json['parent'] ?? 0);
}

class CartItem {
  final Product product;
  int quantity;
  CartItem({required this.product, this.quantity = 1});
}

class BannerItem {
  final String imageUrl;
  final String targetType;
  final String targetUrl;
  BannerItem({required this.imageUrl, required this.targetType, required this.targetUrl});
  factory BannerItem.fromJson(Map<String, dynamic> json) {
    return BannerItem(
      imageUrl: json['imageUrl'] ?? '',
      targetType: json['targetType'] ?? '',
      targetUrl: json['targetUrl'] ?? '',
    );
  }
}

// =======================================================================
// --- PROVIDERS ---
// =======================================================================

// 1. AuthProvider
class AuthProvider with ChangeNotifier {
  String? _token;
  int? _pharmacyId;
  String? _pharmacyName;
  bool get isAuth => _token != null;
  String? get token => _token;
  int? get pharmacyId => _pharmacyId;
  String? get pharmacyName => _pharmacyName;

  Future<bool> login(String username, String password) async {
    final url = Uri.parse(ApiConstants.JWT_URL);
    try {
      final response = await http.post(url, body: {'username': username, 'password': password});
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        _token = responseData['token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.prefsKeyToken, _token!);
        await fetchAndSetPharmacyInfo();
        await _saveFcmToken();
        notifyListeners();
        return true;
      }
    } catch (e) { print(e); }
    return false;
  }

  Future<void> _saveFcmToken() async {
    if (_token == null) return;
    String? fcmToken = await NotificationService.getFCMToken();
    if (fcmToken != null) {
      final url = Uri.parse('${ApiConstants.PHARMACY_API_URL}/pharmacy/save_fcm_token');
      try {
        await http.post(url, headers: {'Authorization': 'Bearer $_token', 'Content-Type': 'application/json'}, body: json.encode({'fcm_token': fcmToken}));
      } catch (_) {}
    }
  }

  Future<void> fetchAndSetPharmacyInfo() async {
    if (_token == null) return;
    final url = Uri.parse('${ApiConstants.PHARMACY_API_URL}/pharmacy/dashboard');
    try {
      final response = await http.get(url, headers: {'Authorization': 'Bearer $_token'});
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = json.decode(response.body);
        _pharmacyId = data['pharmacy_id'];
        _pharmacyName = data['pharmacy_name'];
      } else {
        await logout(navigatorKey.currentContext!);
      }
    } catch (_) {}
  }

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(AppConstants.prefsKeyToken)) return;
    _token = prefs.getString(AppConstants.prefsKeyToken);
    if (_token != null) await fetchAndSetPharmacyInfo();
    notifyListeners();
  }

  Future<void> logout(BuildContext context) async {
    Provider.of<DashboardProvider>(context, listen: false).clearData();
    _token = null;
    _pharmacyId = null;
    _pharmacyName = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefsKeyToken);
    notifyListeners();
  }
}

// 2. CartProvider
class CartProvider with ChangeNotifier {
  Map<int, CartItem> _items = {};
  int? _pharmacyId;
  Map<int, CartItem> get items => {..._items};
  int? get pharmacyId => _pharmacyId;
  int get itemCount => _items.values.fold(0, (sum, item) => sum + item.quantity);
  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += (double.tryParse(cartItem.product.price) ?? 0.0) * cartItem.quantity;
    });
    return total;
  }
  void addItem(Product product) {
    if (_pharmacyId != null && _pharmacyId != product.pharmacyId) {
      throw Exception('لا يمكنك إضافة منتجات من صيدليات مختلفة في نفس الطلب.');
    }
    _pharmacyId = product.pharmacyId;
    if (_items.containsKey(product.id)) {
      _items.update(product.id, (existing) => CartItem(product: existing.product, quantity: existing.quantity + 1));
    } else {
      _items.putIfAbsent(product.id, () => CartItem(product: product));
    }
    notifyListeners();
  }
  void removeSingleItem(int productId) {
    if (!_items.containsKey(productId)) return;
    if (_items[productId]!.quantity > 1) {
      _items.update(productId, (existing) => CartItem(product: existing.product, quantity: existing.quantity - 1));
    } else {
      _items.remove(productId);
    }
    if (_items.isEmpty) _pharmacyId = null;
    notifyListeners();
  }
  void clear() {
    _items = {};
    _pharmacyId = null;
    notifyListeners();
  }
}

// 3. PharmacyProvider (⭐ OFFLINE MODE RESTORED ⭐)
class PharmacyProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<PharmacyProductGroup> _productsByPharmacy = [];
  List<Pharmacy> _nearbyPharmacies = [];
  List<Pharmacy> _allPharmacies = [];
  List<BannerItem> _banners = [];

  bool _isLoadingHome = false;
  bool _isLoadingProducts = false;
  bool _isLoadingPharmacies = false;
  bool _hasNetworkError = false;
  String _errorMessage = '';

  List<PharmacyProductGroup> get productsByPharmacy => _productsByPharmacy;
  List<Pharmacy> get nearbyPharmacies => _nearbyPharmacies;
  List<Pharmacy> get allPharmacies => _allPharmacies;
  List<BannerItem> get banners => _banners;

  bool get isLoadingHome => _isLoadingHome;
  bool get isLoadingProducts => _isLoadingProducts;
  bool get isLoadingPharmacies => _isLoadingPharmacies;
  bool get hasNetworkError => _hasNetworkError;
  String get errorMessage => _errorMessage;

  // --- Home Data (Offline Support) ---
  Future<void> fetchHomeData(int areaId, {bool isRefresh = false}) async {
    _hasNetworkError = false;

    // 1. Try Load from Cache First (Offline Mode)
    if (!isRefresh && _nearbyPharmacies.isEmpty) {
      await _loadHomeFromCache(areaId);
    }

    if (_nearbyPharmacies.isEmpty) {
      _isLoadingHome = true;
      notifyListeners();
    }

    try {
      // 2. Fetch from Network
      final pharmaciesJson = await _apiService.getPharmaciesRaw(areaId);

      // Banners (Non-critical)
      String? bannersJson;
      try {
        final bRes = await http.get(Uri.parse(ApiConstants.BANNERS_URL)).timeout(const Duration(seconds: 5));
        if(bRes.statusCode == 200) bannersJson = bRes.body;
      } catch(_) {}

      // 3. Update State & Save to Cache
      _parseAndSetHomeData(pharmaciesJson, bannersJson);
      _saveHomeToCache(areaId, pharmaciesJson, bannersJson);

    } catch (e) {
      if (_nearbyPharmacies.isEmpty) {
        _hasNetworkError = true;
        _errorMessage = 'فشل تحميل البيانات. تأكد من الإنترنت.';
      }
      print("Network Error in Home: $e");
    } finally {
      _isLoadingHome = false;
      notifyListeners();
    }
  }

  void _parseAndSetHomeData(String pJson, String? bJson) {
    _nearbyPharmacies = (json.decode(pJson) as List).map((p) => Pharmacy.fromJson(p)).toList();
    if(bJson != null) {
      final bData = json.decode(bJson);
      if(bData['showBanners'] == true) {
        _banners = List<Map<String, dynamic>>.from(bData['banners']).map((e) => BannerItem.fromJson(e)).toList();
      }
    }
  }

  Future<void> _saveHomeToCache(int areaId, String pJson, String? bJson) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheData = json.encode({'pharmacies': pJson, 'banners': bJson});
    await prefs.setString('${AppConstants.cacheKeyHome}$areaId', cacheData);
  }

  Future<void> _loadHomeFromCache(int areaId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('${AppConstants.cacheKeyHome}$areaId');
    if (data != null) {
      final decoded = json.decode(data);
      _parseAndSetHomeData(decoded['pharmacies'], decoded['banners']);
      notifyListeners();
    }
  }

  // --- Products Data (Offline Support) ---
  Future<void> fetchAllProducts({bool isRefresh = false}) async {
    _hasNetworkError = false;

    if (!isRefresh && _productsByPharmacy.isEmpty) {
      await _loadProductsFromCache();
    }

    if (_productsByPharmacy.isEmpty) {
      _isLoadingProducts = true;
      notifyListeners();
    }

    try {
      final jsonStr = await _apiService.getProductsRaw();

      _productsByPharmacy = (json.decode(jsonStr) as List).map((g) => PharmacyProductGroup.fromJson(g)).toList();
      _saveProductsToCache(jsonStr); // Cache it

    } catch (e) {
      if (_productsByPharmacy.isEmpty) {
        _hasNetworkError = true;
        _errorMessage = 'فشل تحميل المنتجات.';
      }
    } finally {
      _isLoadingProducts = false;
      notifyListeners();
    }
  }

  Future<void> _saveProductsToCache(String jsonStr) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.cacheKeyProducts, jsonStr);
  }

  Future<void> _loadProductsFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(AppConstants.cacheKeyProducts);
    if (data != null) {
      _productsByPharmacy = (json.decode(data) as List).map((g) => PharmacyProductGroup.fromJson(g)).toList();
      notifyListeners();
    }
  }

  // --- All Pharmacies (Offline Support) ---
  Future<void> fetchAllPharmacies() async {
    _hasNetworkError = false;
    if(_allPharmacies.isEmpty) await _loadAllPharmaciesCache();

    if(_allPharmacies.isEmpty) {
      _isLoadingPharmacies = true;
      notifyListeners();
    }

    try {
      final jsonStr = await _apiService.getAllPharmaciesRaw();
      _allPharmacies = (json.decode(jsonStr) as List).map((p) => Pharmacy.fromJson(p)).toList();
      final prefs = await SharedPreferences.getInstance();
      prefs.setString(AppConstants.cacheKeyPharmacies, jsonStr);
    } catch (e) {
      if(_allPharmacies.isEmpty) {
        _hasNetworkError = true;
        _errorMessage = "فشل تحميل الصيدليات";
      }
    } finally {
      _isLoadingPharmacies = false;
      notifyListeners();
    }
  }

  Future<void> _loadAllPharmaciesCache() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(AppConstants.cacheKeyPharmacies);
    if(data != null) {
      _allPharmacies = (json.decode(data) as List).map((p) => Pharmacy.fromJson(p)).toList();
      notifyListeners();
    }
  }
}

// 4. DashboardProvider (⭐ OFFLINE MODE RESTORED ⭐)
class DashboardProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  Map<String, List<Order>> _orders = {};
  List<SubscriptionRequest> _subscriptions = [];

  bool _isLoading = false;
  bool _hasNetworkError = false;
  String _errorMessage = '';
  Timer? _debounceTimer;

  Map<String, List<Order>> get orders => _orders;
  List<SubscriptionRequest> get subscriptions => _subscriptions;
  bool get isLoading => _isLoading;
  bool get hasNetworkError => _hasNetworkError;
  String get errorMessage => _errorMessage;

  void clearData() {
    _orders.clear();
    _subscriptions.clear();
    _hasNetworkError = false;
    notifyListeners();
  }

  void triggerSmartRefresh(String token) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(seconds: 3), () {
      fetchDashboardData(token, silent: true);
    });
  }

  void startAutoRefresh(String token) {
    fetchDashboardData(token, silent: false);
  }

  Future<void> fetchDashboardData(String? token, {bool silent = false}) async {
    if (token == null) return;
    _hasNetworkError = false;

    // 1. Try Load Cache if empty (so user sees old orders immediately)
    if (_orders.isEmpty) {
      await _loadDashboardFromCache();
    }

    if (!silent && _orders.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      // 2. Fetch Network
      final jsonStr = await _apiService.getDashboardRaw(token);

      // 3. Parse and Cache
      _parseDashboard(jsonStr);
      _saveDashboardToCache(jsonStr);

    } catch (e) {
      if (_orders.isEmpty) {
        _hasNetworkError = true;
        _errorMessage = 'فشل الاتصال. يتم عرض البيانات المخزنة إن وجدت.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _parseDashboard(String jsonStr) {
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    final ordersData = data['orders'] as Map<String, dynamic>? ?? {};
    _orders.clear();
    ordersData.forEach((status, list) {
      _orders[status] = (list as List).map((d) => Order.fromJson(d)).toList();
    });
    final subsData = data['subscriptions'] as List? ?? [];
    _subscriptions = subsData.map((d) => SubscriptionRequest.fromJson(d)).toList();
  }

  Future<void> _saveDashboardToCache(String jsonStr) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.cacheKeyDashboard, jsonStr);
  }

  Future<void> _loadDashboardFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(AppConstants.cacheKeyDashboard);
    if (data != null) {
      try {
        _parseDashboard(data);
        notifyListeners();
      } catch (_) {}
    }
  }
}

// =======================================================================
// --- SERVICES ---
// =======================================================================
class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel('high_importance_channel', 'إشعارات هامة', importance: Importance.max, playSound: true, enableVibration: true);

  static Future<void> initialize() async {
    await _firebaseMessaging.requestPermission();
    await _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(_channel);
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);
    await _localNotifications.initialize(
        const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher'), iOS: DarwinInitializationSettings()),
        onDidReceiveNotificationResponse: (response) {
          if (response.payload != null && response.payload!.isNotEmpty) {
            _handleNotificationTap(json.decode(response.payload!));
          }
        });
  }

  static void _showLocalNotification(RemoteMessage message) {
    final title = message.data['title'] ?? 'إشعار جديد';
    final body = message.data['body'] ?? 'لديك رسالة جديدة.';
    _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000), title, body,
        NotificationDetails(android: AndroidNotificationDetails(_channel.id, _channel.name, icon: '@mipmap/ic_launcher', importance: Importance.max, priority: Priority.high), iOS: const DarwinNotificationDetails(presentSound: true)),
        payload: json.encode(message.data));
  }

  static Future<String?> getFCMToken() async => await _firebaseMessaging.getToken();

  static void _handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    if (type == 'new_message' || type == 'message_reply') {
      try {
        final authProvider = Provider.of<AuthProvider>(navigatorKey.currentContext!, listen: false);
        if (authProvider.isAuth) {
          final customerUid = data['sender_uid'] as String?;
          final customerName = data['sender_name'] as String?;
          if (customerUid != null && customerName != null && authProvider.pharmacyId != null) {
            navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => ChatScreen(pharmacyId: authProvider.pharmacyId!, pharmacyName: authProvider.pharmacyName!, customerUid: customerUid, customerName: customerName)));
          }
        } else {
          final pharmacyId = int.tryParse(data['pharmacy_id']?.toString() ?? '0');
          if (pharmacyId != 0) {
            navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => ChatScreen(pharmacyId: pharmacyId!, pharmacyName: "صيدلية")));
          }
        }
      } catch (e) { print("Error navigating: $e"); }
    }
  }
}

// =======================================================================
// --- WIDGETS ---
// =======================================================================
class OrderCard extends StatefulWidget {
  final Order order;
  final Function onStatusChanged;
  const OrderCard({super.key, required this.order, required this.onStatusChanged});
  @override
  State<OrderCard> createState() => _OrderCardState();
}
class _OrderCardState extends State<OrderCard> {
  bool _isLoading = false;

  void _showRequestDeliveryDialog() {
    final priceController = TextEditingController();
    final areaController = TextEditingController(text: widget.order.customerArea);
    final formKey = GlobalKey<FormState>();

    showDialog(context: context, builder: (ctx) => AlertDialog(
        title: const Text('طلب توصيل'),
        content: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(controller: areaController, decoration: const InputDecoration(labelText: 'المنطقة', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'مطلوب' : null),
          const SizedBox(height: 16),
          TextFormField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'أجرة التوصيل (د.ع)', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'مطلوب' : null),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () { if (formKey.currentState?.validate() ?? false) {
            final price = double.parse(priceController.text);
            final area = areaController.text;
            Navigator.of(ctx).pop();
            _requestDelivery(area, price);
          } }, child: const Text('تأكيد')),
        ]));
  }

  Future<void> _requestDelivery(String area, double fee) async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final response = await http.post(Uri.parse('${ApiConstants.PHARMACY_API_URL}/orders/${widget.order.id}/request-delivery-simple'),
          headers: {'Authorization': 'Bearer ${auth.token}', 'Content-Type': 'application/json'},
          body: json.encode({'delivery_fee': fee, 'destination_area': area}));
      final data = json.decode(response.body);
      if (response.statusCode == 201) {
        if(mounted) _showQrCodeDialog(data['qr_code_data']);
        widget.onStatusChanged();
      } else throw Exception(data['message']);
    } catch (e) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red)); }
    finally { if(mounted) setState(() => _isLoading = false); }
  }

  void _showQrCodeDialog(String qr) => showDialog(context: context, builder: (_) => QrCodeDisplayDialog(qrData: qr));

  Widget _buildActionButtons() {
    if (widget.order.status != 'processing') return const SizedBox.shrink();
    if (widget.order.deliveryStatus == null) return _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : ElevatedButton.icon(icon: const Icon(Icons.delivery_dining, size: 18), label: const Text('طلب توصيل'), onPressed: _showRequestDeliveryDialog);
    if (widget.order.deliveryStatus == 'awaiting_pickup') return ElevatedButton.icon(icon: const Icon(Icons.qr_code, size: 18), label: const Text('الرمز'), onPressed: () => _showQrCodeDialog(widget.order.deliveryQrCode!));
    return Chip(label: Text(widget.order.deliveryStatus ?? ''), backgroundColor: Colors.teal, labelStyle: const TextStyle(color: Colors.white));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('#${widget.order.id}', style: const TextStyle(fontWeight: FontWeight.bold)), Text(DateFormat('yyyy-MM-dd').format(widget.order.date))]),
        const Divider(),
        Text('الزبون: ${widget.order.customerName}'),
        Text('المنطقة: ${widget.order.customerArea}'),
        const SizedBox(height: 8),
        ...widget.order.items.map((i) => Text('- ${i.name} (الكمية: ${i.quantity})')),
        if(widget.order.driverInfo != null) Container(margin: const EdgeInsets.only(top: 8), padding: const EdgeInsets.all(8), color: Colors.blue.shade50, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('معلومات المندوب:', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('الاسم: ${widget.order.driverInfo!.name}'),
          Text('الهاتف: ${widget.order.driverInfo!.phone}'),
        ])),
        const Divider(),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('الإجمالي: ${widget.order.total} د.ع', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)), _buildActionButtons()])
      ])),
    );
  }
}

class QrCodeDisplayDialog extends StatelessWidget {
  final String qrData;
  const QrCodeDisplayDialog({super.key, required this.qrData});
  @override
  Widget build(BuildContext context) => AlertDialog(
      title: const Text('رمز تأكيد الاستلام', textAlign: TextAlign.center),
      content: SizedBox(width: 200, height: 200, child: QrImageView(data: qrData, size: 200, version: QrVersions.auto)),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق'))]
  );
}

class NetworkErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const NetworkErrorWidget({super.key, required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.wifi_off_rounded, size: 80, color: Colors.grey),
    const SizedBox(height: 10), Text(message), const SizedBox(height: 20),
    if(onRetry != null) ElevatedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('إعادة المحاولة'))
  ]));
}

class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard({super.key, required this.product});
  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: Padding(padding: const EdgeInsets.all(8.0), child: CachedNetworkImage(imageUrl: product.imageUrl, fit: BoxFit.contain, errorWidget: (_,__,___) => const Icon(Icons.medication, size: 50, color: Colors.grey)))),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0), child: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold))),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0), child: Text('${product.price} د.ع', style: TextStyle(color: Theme.of(context).primaryColor))),
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: ElevatedButton.icon(onPressed: () {
              try { Provider.of<CartProvider>(context, listen: false).addItem(product); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت الإضافة للسلة'), duration: Duration(milliseconds: 800))); }
              catch(e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")))); }
            }, icon: const Icon(Icons.add_shopping_cart, size: 16), label: const Text('أضف'), style: ElevatedButton.styleFrom(padding: EdgeInsets.zero)),
          )
        ],
      ),
    );
  }
}

class PharmacyListItemCard extends StatelessWidget {
  final Pharmacy pharmacy;
  const PharmacyListItemCard({super.key, required this.pharmacy});
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: CachedNetworkImage(imageUrl: pharmacy.logoUrl, width: 50, height: 50, fit: BoxFit.cover, errorWidget: (_,__,___) => const Icon(Icons.store, size: 50))),
        title: Text(pharmacy.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: ElevatedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(pharmacyId: pharmacy.id, pharmacyName: pharmacy.name))), icon: const Icon(Icons.chat_bubble_outline, size: 18), label: const Text('دردشة')),
      ),
    );
  }
}

class SubscriptionCard extends StatelessWidget {
  final SubscriptionRequest subscription;
  const SubscriptionCard({super.key, required this.subscription});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(subscription.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${subscription.illnessType}\n${subscription.phone}'),
        trailing: IconButton(icon: const Icon(Icons.phone, color: Colors.green), onPressed: () => launchUrl(Uri.parse('tel:${subscription.phone}'))),
      ),
    );
  }
}

class SubscriptionButtons extends StatelessWidget {
  final int areaId;
  const SubscriptionButtons({super.key, required this.areaId});
  @override
  Widget build(BuildContext context) => ElevatedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SubscriptionScreen(areaId: areaId))), icon: const Icon(Icons.monitor_heart_outlined), label: const Text('اشتراك الأمراض المزمنة'));
}

class ConsultationCard extends StatelessWidget {
  final Pharmacy pharmacy;
  const ConsultationCard({super.key, required this.pharmacy});
  @override
  Widget build(BuildContext context) => Card(child: ListTile(leading: Icon(Icons.chat_bubble_rounded, size: 40, color: Theme.of(context).primaryColor), title: const Text('استشارة صيدلانية'), subtitle: const Text('تحدث مباشرة مع الصيدلي'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(pharmacyId: pharmacy.id, pharmacyName: pharmacy.name)))));
}

// =======================================================================
// --- SCREENS ---
// =======================================================================
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});
  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}
class _AuthWrapperState extends State<AuthWrapper> {
  late Future<void> _autoLoginFuture;
  @override
  void initState() {
    super.initState();
    _autoLoginFuture = Provider.of<AuthProvider>(context, listen: false).tryAutoLogin();
    FirebaseMessaging.onMessage.listen((message) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.isAuth && (message.data['type'] == 'new_order' || message.data['type'] == 'delivery_status_update')) {
        Provider.of<DashboardProvider>(context, listen: false).triggerSmartRefresh(auth.token!);
      }
      NotificationService._showLocalNotification(message);
    });
    FirebaseMessaging.onMessageOpenedApp.listen((message) => NotificationService._handleNotificationTap(message.data));
  }
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(future: _autoLoginFuture, builder: (ctx, snap) {
      if (snap.connectionState == ConnectionState.waiting) return const Scaffold(body: Center(child: CircularProgressIndicator()));
      return Consumer<AuthProvider>(builder: (_, auth, __) {
        if (auth.isAuth) return const PharmacyDashboardScreen();
        return StreamBuilder<User?>(stream: FirebaseAuth.instance.authStateChanges(), builder: (_, snapUser) {
          if (snapUser.hasData) return const LocationCheckWrapper();
          return const CustomerLoginScreen();
        });
      });
    });
  }
}

class LocationCheckWrapper extends StatefulWidget {
  const LocationCheckWrapper({super.key});
  @override
  State<LocationCheckWrapper> createState() => _LocationCheckWrapperState();
}
class _LocationCheckWrapperState extends State<LocationCheckWrapper> {
  Future<int?> _check() async { final p = await SharedPreferences.getInstance(); return p.getInt(AppConstants.prefsKeyAreaId); }
  @override
  Widget build(BuildContext context) => FutureBuilder<int?>(future: _check(), builder: (_, snap) {
    if (snap.connectionState == ConnectionState.waiting) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (snap.data != null) return CustomerMainShell(areaId: snap.data!);
    return const SelectLocationScreen();
  });
}

class SelectLocationScreen extends StatefulWidget {
  final bool isCancellable;
  const SelectLocationScreen({super.key, this.isCancellable = false});
  @override
  State<SelectLocationScreen> createState() => _SelectLocationScreenState();
}
class _SelectLocationScreenState extends State<SelectLocationScreen> {
  Future<List<Area>>? _areas;
  int? _selGov;
  @override
  void initState() { super.initState(); _areas = _fetch(); }
  Future<List<Area>> _fetch() async {
    final r = await http.get(Uri.parse('${ApiConstants.BASE_URL}/wp/v2/area?per_page=100'));
    if (r.statusCode == 200) return (json.decode(r.body) as List).map((e) => Area.fromJson(e)).toList();
    throw Exception('خطأ في جلب المناطق');
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اختر المنطقة'), automaticallyImplyLeading: widget.isCancellable),
      body: FutureBuilder<List<Area>>(future: _areas, builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snap.hasData) return const Center(child: NetworkErrorWidget(message: 'لا يمكن جلب المناطق', onRetry:  null));

        final gov = snap.data!.where((a) => a.parentId == 0).toList();
        final cities = _selGov == null ? <Area>[] : snap.data!.where((a) => a.parentId == _selGov).toList();

        return ListView(padding: const EdgeInsets.all(16), children: [
          DropdownButtonFormField(
              decoration: const InputDecoration(labelText: 'المحافظة', border: OutlineInputBorder()),
              value: _selGov, items: gov.map((g) => DropdownMenuItem(value: g.id, child: Text(g.name))).toList(),
              onChanged: (v) => setState(() => _selGov = v as int?)
          ),
          const SizedBox(height: 20),
          ...cities.map((c) => Card(child: ListTile(title: Text(c.name), onTap: () async {
            final p = await SharedPreferences.getInstance();
            await p.setInt(AppConstants.prefsKeyAreaId, c.id);
            await p.setString(AppConstants.prefsKeyAreaName, c.name);
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => CustomerMainShell(areaId: c.id)), (r) => false);
          }, trailing: const Icon(Icons.arrow_forward_ios))))
        ]);
      }),
    );
  }
}

class CustomerLoginScreen extends StatelessWidget {
  const CustomerLoginScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final nameC = TextEditingController(); final phoneC = TextEditingController();
    return Scaffold(body: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.local_pharmacy_outlined, size: 80, color: Theme.of(context).primaryColor),
      const SizedBox(height: 20), const Text('أهلاً بك في صيدليات بيتي', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 30),
      TextField(controller: nameC, decoration: const InputDecoration(labelText: 'الاسم الكامل', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person))),
      const SizedBox(height: 10),
      TextField(controller: phoneC, decoration: const InputDecoration(labelText: 'رقم الهاتف', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)), keyboardType: TextInputType.phone),
      const SizedBox(height: 20),
      ElevatedButton(onPressed: () async {
        if(nameC.text.isNotEmpty && phoneC.text.isNotEmpty) {
          try {
            final cred = await FirebaseAuth.instance.signInAnonymously();
            FirebaseFirestore.instance.collection('pharmacy_users').doc(cred.user!.uid).set({'name': nameC.text, 'phone': phoneC.text});
          } catch(e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }
        }
      }, child: const Text('تسجيل الدخول')),
      TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PharmacyLoginScreen())), child: const Text('تسجيل دخول الصيدلية'))
    ]))));
  }
}

class PharmacyLoginScreen extends StatefulWidget {
  const PharmacyLoginScreen({super.key});
  @override
  _PharmacyLoginScreenState createState() => _PharmacyLoginScreenState();
}
class _PharmacyLoginScreenState extends State<PharmacyLoginScreen> {
  final uC = TextEditingController(); final pC = TextEditingController(); bool _loading = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('دخول الصيدلية')), body: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(children: [
      Icon(Icons.storefront, size: 80, color: Theme.of(context).primaryColor),
      const SizedBox(height: 30),
      TextField(controller: uC, decoration: const InputDecoration(labelText: 'اسم المستخدم', border: OutlineInputBorder())),
      const SizedBox(height: 10),
      TextField(controller: pC, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور', border: OutlineInputBorder())),
      const SizedBox(height: 20),
      _loading ? const CircularProgressIndicator() : ElevatedButton(onPressed: () async {
        setState(() => _loading = true);
        if(await Provider.of<AuthProvider>(context, listen: false).login(uC.text, pC.text)) Navigator.pop(context);
        else if(mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل الدخول'))); setState(() => _loading = false); }
      }, child: const Text('دخول'))
    ]))));
  }
}

class CustomerMainShell extends StatefulWidget {
  final int areaId;
  const CustomerMainShell({super.key, required this.areaId});
  @override
  _CustomerMainShellState createState() => _CustomerMainShellState();
}
class _CustomerMainShellState extends State<CustomerMainShell> {
  int _selectedIndex = 0;
  late final List<Widget> _screens;
  String? _selectedAreaName;
  @override
  void initState() {
    super.initState();
    _screens = [PharmacyHomeScreen(areaId: widget.areaId), const ProductListScreen(), const PharmaciesListScreen()];
    _loadAreaName();
  }
  Future<void> _loadAreaName() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _selectedAreaName = prefs.getString(AppConstants.prefsKeyAreaName));
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SelectLocationScreen(isCancellable: true))),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [Text(_selectedAreaName ?? 'اختر منطقة', style: const TextStyle(fontSize: 16)), const Icon(Icons.keyboard_arrow_down, size: 20)],
          ),
        ),
        actions: [
          Consumer<CartProvider>(
            builder: (_, cart, ch) => badges.Badge(
              position: badges.BadgePosition.topEnd(top: 0, end: 3),
              showBadge: cart.itemCount > 0,
              badgeContent: Text(cart.itemCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 10)),
              child: IconButton(icon: const Icon(Icons.shopping_cart_outlined), onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const CartScreen()))),
            ),
          ),
          IconButton(onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove(AppConstants.prefsKeyAreaId);
            await prefs.remove(AppConstants.prefsKeyAreaName);
            await FirebaseAuth.instance.signOut();
          }, icon: const Icon(Icons.logout_outlined)),
          const SizedBox(width: 10),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'الرئيسية'), BottomNavigationBarItem(icon: Icon(Icons.medication_outlined), activeIcon: Icon(Icons.medication), label: 'المنتجات'), BottomNavigationBarItem(icon: Icon(Icons.local_pharmacy_outlined), activeIcon: Icon(Icons.local_pharmacy), label: 'الصيدليات')],
      ),
    );
  }
}

class PharmacyHomeScreen extends StatefulWidget {
  final int areaId;
  const PharmacyHomeScreen({super.key, required this.areaId});
  @override
  _PharmacyHomeScreenState createState() => _PharmacyHomeScreenState();
}
class _PharmacyHomeScreenState extends State<PharmacyHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<PharmacyProvider>(context, listen: false);
      if(provider.nearbyPharmacies.isEmpty) provider.fetchHomeData(widget.areaId);
    });
  }

  void _onBannerTapped(BannerItem banner) {
    if (banner.targetType == 'webview' && banner.targetUrl.isNotEmpty) {
      final uri = Uri.tryParse(banner.targetUrl);
      if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PharmacyProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingHome && provider.nearbyPharmacies.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.hasNetworkError && provider.nearbyPharmacies.isEmpty) {
          return NetworkErrorWidget(message: provider.errorMessage, onRetry: () => provider.fetchHomeData(widget.areaId));
        }

        final pharmacyInArea = provider.nearbyPharmacies.isNotEmpty ? provider.nearbyPharmacies.first : null;

        return RefreshIndicator(
          onRefresh: () => provider.fetchHomeData(widget.areaId, isRefresh: true),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (provider.banners.isNotEmpty) ...[
                CarouselSlider.builder(
                  itemCount: provider.banners.length,
                  itemBuilder: (ctx, index, realIdx) {
                    final banner = provider.banners[index];
                    return GestureDetector(
                      onTap: () => _onBannerTapped(banner),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5.0),
                        child: ClipRRect(borderRadius: BorderRadius.circular(15), child: CachedNetworkImage(imageUrl: banner.imageUrl, fit: BoxFit.cover, placeholder: (c, u) => Container(color: Colors.grey.shade200), errorWidget: (c, u, e) => const Icon(Icons.error))),
                      ),
                    );
                  },
                  options: CarouselOptions(height: 180.0, autoPlay: true, enlargeCenterPage: true),
                ),
                const SizedBox(height: 20),
              ],
              SubscriptionButtons(areaId: widget.areaId),
              const SizedBox(height: 20),
              if (pharmacyInArea != null)
                ConsultationCard(pharmacy: pharmacyInArea)
              else
                const Card(child: Padding(padding: EdgeInsets.all(16.0), child: Text("لا توجد صيدلية تخدم هذه المنطقة حالياً."))),
            ],
          ),
        );
      },
    );
  }
}

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});
  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}
class _ProductListScreenState extends State<ProductListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<PharmacyProvider>(context, listen: false);
      if(provider.productsByPharmacy.isEmpty) provider.fetchAllProducts();
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<PharmacyProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingProducts && provider.productsByPharmacy.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.hasNetworkError && provider.productsByPharmacy.isEmpty) {
            return NetworkErrorWidget(message: provider.errorMessage, onRetry: () => provider.fetchAllProducts());
          }
          return RefreshIndicator(
            onRefresh: () => provider.fetchAllProducts(isRefresh: true),
            child: provider.productsByPharmacy.isEmpty
                ? const Center(child: Text('لا توجد منتجات متاحة حالياً.'))
                : ListView.builder(
              itemCount: provider.productsByPharmacy.length,
              itemBuilder: (ctx, index) {
                final pharmacyGroup = provider.productsByPharmacy[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(padding: const EdgeInsets.fromLTRB(16, 20, 16, 10), child: Text(pharmacyGroup.pharmacyName, style: Theme.of(context).textTheme.headlineSmall)),
                    GridView.builder(
                      padding: const EdgeInsets.all(10),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: pharmacyGroup.products.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.7, crossAxisSpacing: 10, mainAxisSpacing: 10),
                      itemBuilder: (ctx, i) => ProductCard(product: pharmacyGroup.products[i]),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class PharmaciesListScreen extends StatefulWidget {
  const PharmaciesListScreen({super.key});
  @override
  _PharmaciesListScreenState createState() => _PharmaciesListScreenState();
}
class _PharmaciesListScreenState extends State<PharmaciesListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<PharmacyProvider>(context, listen: false);
      if(provider.allPharmacies.isEmpty) provider.fetchAllPharmacies();
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<PharmacyProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingPharmacies && provider.allPharmacies.isEmpty) return const Center(child: CircularProgressIndicator());
          if (provider.hasNetworkError && provider.allPharmacies.isEmpty) return NetworkErrorWidget(message: provider.errorMessage, onRetry: () => provider.fetchAllPharmacies());
          if (provider.allPharmacies.isEmpty) return const Center(child: Text("لا توجد صيدليات متاحة حالياً."));

          return RefreshIndicator(
            onRefresh: () => provider.fetchAllPharmacies(),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: provider.allPharmacies.length,
              itemBuilder: (context, index) => PharmacyListItemCard(pharmacy: provider.allPharmacies[index]),
            ),
          );
        },
      ),
    );
  }
}

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  _CartScreenState createState() => _CartScreenState();
}
class _CartScreenState extends State<CartScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _areaController = TextEditingController();
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance.collection('pharmacy_users').doc(user.uid).get().then((doc) {
        if (doc.exists && mounted) {
          _nameController.text = doc.data()?['name'] ?? '';
          _phoneController.text = doc.data()?['phone'] ?? '';
        }
      });
    }
  }
  Future<void> _submitOrder(CartProvider cart) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يجب تسجيل الدخول أولاً')));
      setState(() => _isLoading = false);
      return;
    }
    final url = Uri.parse('${ApiConstants.PHARMACY_API_URL}/orders/create');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'pharmacy_id': cart.pharmacyId,
          'cart_items': cart.items.values.map((item) => {'product_id': item.product.id, 'quantity': item.quantity}).toList(),
          'customer_info': {'name': _nameController.text, 'phone': _phoneController.text, 'area': _areaController.text, 'firebase_uid': user.uid},
        }),
      );
      final responseBody = json.decode(response.body);
      if (response.statusCode == 201) {
        cart.clear();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال طلبك بنجاح!')));
      } else {
        throw Exception(responseBody['message'] ?? 'حدث خطأ غير معروف');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في الاتصال: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('سلة المشتريات'), actions: [if (cart.items.isNotEmpty) IconButton(onPressed: () => cart.clear(), icon: const Icon(Icons.delete_outline))]),
      body: cart.items.isEmpty
          ? const Center(child: Text('السلة فارغة!'))
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: cart.items.length,
              itemBuilder: (ctx, i) {
                final item = cart.items.values.toList()[i];
                return Dismissible(
                  key: ValueKey(item.product.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => Provider.of<CartProvider>(context, listen: false).removeSingleItem(item.product.id),
                  background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white, size: 30)),
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(backgroundImage: CachedNetworkImageProvider(item.product.imageUrl)),
                      title: Text(item.product.name),
                      subtitle: Text('الإجمالي: ${(double.tryParse(item.product.price) ?? 0) * item.quantity} د.ع'),
                      trailing: Text('${item.quantity} x'),
                    ),
                  ),
                );
              },
            ),
          ),
          Card(
            margin: const EdgeInsets.all(15),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('الإجمالي:', style: TextStyle(fontSize: 20)), Text('${cart.totalAmount.toStringAsFixed(0)} د.ع', style: Theme.of(context).textTheme.headlineSmall)]),
                    const SizedBox(height: 10),
                    TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'الاسم الكامل'), validator: (v) => v!.isEmpty ? 'مطلوب' : null),
                    TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: 'رقم الهاتف'), keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'مطلوب' : null),
                    TextFormField(controller: _areaController, decoration: const InputDecoration(labelText: 'المنطقة/العنوان'), validator: (v) => v!.isEmpty ? 'مطلوب' : null),
                    const SizedBox(height: 20),
                    _isLoading ? const Center(child: CircularProgressIndicator()) : ElevatedButton(onPressed: () => _submitOrder(cart), child: const Text('تأكيد الطلب')),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final int pharmacyId;
  final String pharmacyName;
  final String? customerUid;
  final String? customerName;
  const ChatScreen({super.key, required this.pharmacyId, required this.pharmacyName, this.customerUid, this.customerName});
  @override
  _ChatScreenState createState() => _ChatScreenState();
}
class _ChatScreenState extends State<ChatScreen> {
  List<types.Message> _messages = [];
  late final types.User _chatUser;
  late final String _conversationDocId;
  late final bool _isPharmacyOwner;
  late final AuthProvider _authProvider;
  @override
  void initState() {
    super.initState();
    _authProvider = Provider.of<AuthProvider>(context, listen: false);
    _isPharmacyOwner = _authProvider.isAuth;
    if (_isPharmacyOwner) {
      _chatUser = types.User(id: 'pharmacy_${widget.pharmacyId}');
      _conversationDocId = widget.customerUid!;
      _markAsRead();
    } else {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) { Navigator.of(context).pop(); return; }
      _chatUser = types.User(id: firebaseUser.uid);
      _conversationDocId = firebaseUser.uid;
      _initiateConversationIfNeeded(firebaseUser);
    }
    _loadMessages();
  }

  Future<void> _markAsRead() async {
    if (!_isPharmacyOwner) return;
    final url = Uri.parse('${ApiConstants.PHARMACY_API_URL}/chats/mark_as_read');
    try {
      await http.post(url, headers: {'Authorization': 'Bearer ${_authProvider.token}', 'Content-Type': 'application/json'}, body: json.encode({'user_uid': widget.customerUid}));
    } catch (e) {
      print("Failed to mark chat as read: $e");
    }
  }

  Future<void> _initiateConversationIfNeeded(User firebaseUser) async {
    final doc = await FirebaseFirestore.instance.collection('pharmacy_users').doc(firebaseUser.uid).get();
    final userName = doc.data()?['name'] ?? 'زبون';
    final fcmToken = await NotificationService.getFCMToken();
    final url = Uri.parse('${ApiConstants.PHARMACY_API_URL}/chats/initiate');
    http.post(url, headers: {'Content-Type': 'application/json'}, body: json.encode({'pharmacy_id': widget.pharmacyId, 'user_info': {'uid': firebaseUser.uid, 'name': userName, 'fcm_token': fcmToken}}));
  }
  void _loadMessages() {
    FirebaseFirestore.instance
        .collection('pharmacy_chats').doc(_conversationDocId).collection('conversations').doc(widget.pharmacyId.toString()).collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      final messages = snapshot.docs.map((doc) {
        final data = doc.data();
        if (data['createdAt'] == null) return null;
        data['createdAt'] = (data['createdAt'] as Timestamp).millisecondsSinceEpoch;
        data['author'] = {'id': data['authorId']};
        data['id'] = doc.id;
        try {
          switch (data['type']) {
            case 'image': return types.ImageMessage.fromJson(data);
            case 'file': return types.FileMessage.fromJson(data);
            default: return types.TextMessage.fromJson(data);
          }
        } catch (e) { return null; }
      }).where((msg) => msg != null).cast<types.Message>().toList();
      setState(() => _messages = messages);
    });
  }
  Future<void> _handleAttachmentPressed() async {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) {
        return SafeArea(
          child: SizedBox(
            height: 160,
            child: Column(
              children: <Widget>[
                const SizedBox(height: 10),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                ListTile(
                  leading: const Icon(Icons.image_rounded, color: Colors.purple),
                  title: const Text('إرسال صورة'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickFile(FileType.image);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.attach_file_rounded, color: Colors.blue),
                  title: const Text('إرسال ملف'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickFile(FileType.any);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickFile(FileType type) async {
    final result = await FilePicker.platform.pickFiles(type: type);
    if (result == null || result.files.single.path == null) return;

    final file = result.files.single;
    final bytes = await File(file.path!).readAsBytes();
    final mimeType = lookupMimeType(file.path!) ?? 'application/octet-stream';

    types.Message message;
    if (mimeType.startsWith('image/')) {
      final image = await decodeImageFromList(bytes);
      message = types.ImageMessage(author: _chatUser, id: const Uuid().v4(), createdAt: DateTime.now().millisecondsSinceEpoch, name: file.name, size: file.size, uri: file.path!, width: image.width.toDouble(), height: image.height.toDouble());
    } else {
      message = types.FileMessage(author: _chatUser, id: const Uuid().v4(), createdAt: DateTime.now().millisecondsSinceEpoch, name: file.name, size: file.size, uri: file.path!, mimeType: mimeType);
    }

    _addMessageToFirestore(message);
    try {
      final uploadUrl = Uri.parse('${ApiConstants.PHARMACY_API_URL}/chats/upload_file');
      var request = http.MultipartRequest('POST', uploadUrl)..files.add(await http.MultipartFile.fromPath('file', file.path!));
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final fileUrl = jsonDecode(responseData)['file_url'];
        FirebaseFirestore.instance.collection('pharmacy_chats').doc(_conversationDocId).collection('conversations').doc(widget.pharmacyId.toString()).collection('messages').where('uri', isEqualTo: file.path!).limit(1).get().then((querySnapshot) {
          if (querySnapshot.docs.isNotEmpty) querySnapshot.docs.first.reference.update({'uri': fileUrl});
        });
        final notificationText = mimeType.startsWith('image/') ? '📷 صورة' : '📎 ملف';
        if (_isPharmacyOwner) _notifyUser(notificationText);
        else _notifyPharmacy(notificationText);
      }
    } catch (e) { /* handle error */ }
  }

  void _addMessageToFirestore(types.Message message) {
    final messageData = message.toJson();
    messageData.remove('author');
    messageData.remove('id');
    messageData['authorId'] = message.author.id;
    messageData['createdAt'] = FieldValue.serverTimestamp();
    FirebaseFirestore.instance.collection('pharmacy_chats').doc(_conversationDocId).collection('conversations').doc(widget.pharmacyId.toString()).collection('messages').add(messageData);
  }
  Future<void> _handleSendPressed(types.PartialText message) async {
    final textMessage = types.TextMessage(author: _chatUser, createdAt: DateTime.now().millisecondsSinceEpoch, id: const Uuid().v4(), text: message.text);
    _addMessageToFirestore(textMessage);
    if (_isPharmacyOwner) _notifyUser(message.text);
    else _notifyPharmacy(message.text);
  }
  Future<void> _notifyPharmacy(String text) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userDoc = await FirebaseFirestore.instance.collection('pharmacy_users').doc(user.uid).get();
    final userName = userDoc.data()?['name'] ?? 'زبون';
    http.post(Uri.parse('${ApiConstants.PHARMACY_API_URL}/chats/notify_pharmacy'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'pharmacy_id': widget.pharmacyId, 'user_name': userName, 'message_text': text, 'firebase_uid': user.uid}));
  }
  Future<void> _notifyUser(String text) async {
    http.post(Uri.parse('${ApiConstants.PHARMACY_API_URL}/pharmacy/notify_user'), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${_authProvider.token}'}, body: jsonEncode({'pharmacy_name': _authProvider.pharmacyName, 'message_text': text, 'user_firebase_uid': widget.customerUid}));
  }
  @override
  Widget build(BuildContext context) {
    final chatTitle = _isPharmacyOwner ? 'محادثة مع ${widget.customerName}' : widget.pharmacyName;
    return Scaffold(
      appBar: AppBar(title: Text(chatTitle), backgroundColor: const Color(0xFFF7F7F7)),
      body: Chat(
        messages: _messages,
        onSendPressed: _handleSendPressed,
        onAttachmentPressed: _handleAttachmentPressed,
        user: _chatUser,
        theme: DefaultChatTheme(
          backgroundColor: const Color(0xFFF2F4F5),
          inputBackgroundColor: const Color(0xFF1F2937), inputTextColor: Colors.white,
          inputBorderRadius: const BorderRadius.all(Radius.circular(24)),
          inputPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          attachmentButtonIcon: const Icon(Icons.add_circle_outline, color: Colors.white70),
          sendButtonIcon: const Icon(Icons.send_rounded, color: Colors.blueAccent),
          primaryColor: Theme.of(context).primaryColor, secondaryColor: Colors.white,
          sentMessageBodyTextStyle: GoogleFonts.cairo(color: Colors.white, fontSize: 16),
          receivedMessageBodyTextStyle: GoogleFonts.cairo(color: Colors.black87, fontSize: 16),
        ),
        l10n: const ChatL10nEn(inputPlaceholder: 'اكتب رسالتك هنا...'),
      ),
    );
  }
}

class SubscriptionScreen extends StatefulWidget {
  final int areaId;
  const SubscriptionScreen({super.key, required this.areaId});
  @override
  _SubscriptionScreenState createState() => _SubscriptionScreenState();
}
class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _illnessController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final url = Uri.parse('${ApiConstants.PHARMACY_API_URL}/subscribe_chronic?area_id=${widget.areaId}');
      final response = await http.post(url, headers: {'Content-Type': 'application/json'}, body: json.encode({'full_name': _nameController.text, 'phone': _phoneController.text, 'illness_type': _illnessController.text}));
      if (response.statusCode == 200) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SubscriptionSuccessScreen()));
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'فشل في إرسال الطلب');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اشتراك الأمراض المزمنة')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Icon(Icons.favorite_border, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            const Text('برنامج الخصومات الخاص', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'الاسم الكامل', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: 'رقم الهاتف', border: OutlineInputBorder()), keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _illnessController, decoration: const InputDecoration(labelText: 'نوع المرض', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null),
            const SizedBox(height: 30),
            _isLoading ? const Center(child: CircularProgressIndicator()) : ElevatedButton(onPressed: _submit, child: const Text('إرسال الطلب')),
          ]),
        ),
      ),
    );
  }
}

class SubscriptionSuccessScreen extends StatelessWidget {
  const SubscriptionSuccessScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 100),
              const SizedBox(height: 24),
              Text('تم استلام طلبك بنجاح!', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text('سوف يتم الاتصال بك قريباً.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade700)),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('العودة إلى الرئيسية'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PharmacyDashboardScreen extends StatefulWidget {
  const PharmacyDashboardScreen({super.key});
  @override
  _PharmacyDashboardScreenState createState() => _PharmacyDashboardScreenState();
}
class _PharmacyDashboardScreenState extends State<PharmacyDashboardScreen> {
  int _selectedIndex = 0;
  final List<Widget> _ownerScreens = const [PharmacyOrdersPage(), PharmacySubscriptionsPage(), PharmacyChatListPage()];
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(title: Text(authProvider.pharmacyName ?? 'لوحة التحكم'), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => Provider.of<AuthProvider>(context, listen: false).logout(context))]),
      body: IndexedStack(index: _selectedIndex, children: _ownerScreens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: 'الطلبات'), BottomNavigationBarItem(icon: Icon(Icons.favorite_outline), label: 'الاشتراكات'), BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'المحادثات')],
      ),
    );
  }
}

class PharmacyOrdersPage extends StatefulWidget {
  const PharmacyOrdersPage({super.key});
  @override
  _PharmacyOrdersPageState createState() => _PharmacyOrdersPageState();
}
class _PharmacyOrdersPageState extends State<PharmacyOrdersPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboard, child) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        if (dashboard.isLoading && dashboard.orders.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (dashboard.hasNetworkError && dashboard.orders.isEmpty) {
          return NetworkErrorWidget(message: dashboard.errorMessage, onRetry: () => dashboard.fetchDashboardData(authProvider.token));
        }

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              toolbarHeight: 0,
              bottom: const TabBar(tabs: [Tab(text: 'جديدة'), Tab(text: 'مكتملة'), Tab(text: 'ملغية')]),
            ),
            body: TabBarView(
              children: [
                PharmacyOrdersList(orders: dashboard.orders['processing'] ?? [], onRefresh: () => dashboard.fetchDashboardData(authProvider.token)),
                PharmacyOrdersList(orders: dashboard.orders['completed'] ?? [], onRefresh: () => dashboard.fetchDashboardData(authProvider.token)),
                PharmacyOrdersList(orders: dashboard.orders['cancelled'] ?? [], onRefresh: () => dashboard.fetchDashboardData(authProvider.token))
              ],
            ),
          ),
        );
      },
    );
  }
}

class PharmacyOrdersList extends StatelessWidget {
  final List<Order> orders;
  final Future<void> Function() onRefresh;
  const PharmacyOrdersList({super.key, required this.orders, required this.onRefresh});
  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: Stack(
          children: [
            ListView(),
            Center(child: Text('لا توجد طلبات في هذه الفئة حالياً.', style: TextStyle(color: Colors.grey.shade600))),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        itemCount: orders.length,
        itemBuilder: (ctx, i) => OrderCard(order: orders[i], onStatusChanged: onRefresh),
      ),
    );
  }
}

class PharmacySubscriptionsPage extends StatefulWidget {
  const PharmacySubscriptionsPage({super.key});
  @override
  _PharmacySubscriptionsPageState createState() => _PharmacySubscriptionsPageState();
}
class _PharmacySubscriptionsPageState extends State<PharmacySubscriptionsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<DashboardProvider>(
        builder: (context, dashboard, child) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);

          if (dashboard.isLoading && dashboard.subscriptions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (dashboard.hasNetworkError && dashboard.subscriptions.isEmpty) {
            return NetworkErrorWidget(message: dashboard.errorMessage, onRetry: () => dashboard.fetchDashboardData(authProvider.token));
          }

          return RefreshIndicator(
            onRefresh: () => dashboard.fetchDashboardData(authProvider.token),
            child: dashboard.subscriptions.isEmpty
                ? Stack(children: [ListView(), Center(child: Text('لا توجد طلبات اشتراك حالياً.'))])
                : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              itemCount: dashboard.subscriptions.length,
              itemBuilder: (ctx, i) => SubscriptionCard(subscription: dashboard.subscriptions[i]),
            ),
          );
        },
      ),
    );
  }
}

class PharmacyChatListPage extends StatefulWidget {
  const PharmacyChatListPage({super.key});
  @override
  _PharmacyChatListPageState createState() => _PharmacyChatListPageState();
}
class _PharmacyChatListPageState extends State<PharmacyChatListPage> {
  List<Conversation> _conversations = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchConversations();
  }

  Future<void> _fetchConversations() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _error = null; });
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final url = Uri.parse('${ApiConstants.PHARMACY_API_URL}/pharmacy/conversations');
      final response = await http.get(url, headers: {'Authorization': 'Bearer ${authProvider.token}'});
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) setState(() => _conversations = data.map((c) => Conversation.fromJson(c)).toList());
      } else {
        throw Exception("Failed to fetch conversations");
      }
    } catch (e) {
      if (mounted) setState(() => _error = "فشل في جلب المحادثات");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? NetworkErrorWidget(message: _error!, onRetry: _fetchConversations)
          : RefreshIndicator(
        onRefresh: _fetchConversations,
        child: _conversations.isEmpty
            ? Stack(children: [ListView(), Center(child: Text('لا توجد محادثات بعد.'))])
            : ListView.builder(
          itemCount: _conversations.length,
          itemBuilder: (ctx, i) {
            final convo = _conversations[i];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                  leading: CircleAvatar(child: Text(convo.name.isNotEmpty ? convo.name.substring(0, 1) : "?")),
                  title: Text(convo.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (convo.unreadCount > 0)
                        badges.Badge(badgeContent: Text(convo.unreadCount.toString(), style: const TextStyle(color: Colors.white))),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_ios),
                    ],
                  ),
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(pharmacyId: authProvider.pharmacyId!, pharmacyName: authProvider.pharmacyName!, customerUid: convo.uid, customerName: convo.name)));
                    _fetchConversations();
                  }
              ),
            );
          },
        ),
      ),
    );
  }
}

// =======================================================================
// --- APP ENTRY POINT ---
// =======================================================================
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  NotificationService._showLocalNotification(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await NotificationService.initialize();
  runApp(const PharmacyApp());
}

class PharmacyApp extends StatelessWidget {
  const PharmacyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PharmacyProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProxyProvider<AuthProvider, DashboardProvider>(
          create: (_) => DashboardProvider(),
          update: (_, auth, dashboard) {
            if (auth.isAuth && dashboard != null && dashboard.orders.isEmpty) {
              // ✅ التحديث الذكي عند بدء التطبيق
              dashboard.startAutoRefresh(auth.token!);
            }
            return dashboard!;
          },
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'صيدليات بيتي',
        theme: ThemeData(
            textTheme: GoogleFonts.cairoTextTheme(Theme.of(context).textTheme),
            primaryColor: Colors.blue.shade700,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue.shade700),
            scaffoldBackgroundColor: const Color(0xFFF0F4F8),
            appBarTheme: AppBarTheme(
              backgroundColor: const Color(0xFFF0F4F8),
              elevation: 0,
              centerTitle: true,
              iconTheme: const IconThemeData(color: Colors.black87),
              titleTextStyle: GoogleFonts.cairo(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                )
            )
        ),
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
      ),
    );
  }
}
