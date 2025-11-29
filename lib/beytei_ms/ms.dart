
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:url_launcher/url_launcher.dart';


// =======================================================================
// --- (جديد) إعدادات وثوابت عامة للـ Admin Dashboard ---
// =======================================================================
// (تم تغيير الدومين إلى beytei.com ومسار API جديد)
const String STORE_BASE_URL = 'https://beytei.com';
const String STORE_APP_NAMESPACE = '/wp-json/store-app/v1'; // (هذا مسار مقترح للـ Backend)
const String STORE_APP_URL = '$STORE_BASE_URL$STORE_APP_NAMESPACE';

// (هذه الثوابت خاصة بـ WooCommerce API للزبون - من الكود الخاص بك)
const String CUSTOMER_CONSUMER_KEY = 'ck_86b62f6fe8a298a5f9d564d70d689db81b9255ed';
const String CUSTOMER_CONSUMER_SECRET = 'cs_b2de9b284f6245c8297caaf37976d899d6789ab2';

const Duration API_TIMEOUT = Duration(seconds: 30);


// =======================================================================
// --- (جديد) معالج رسائل الخلفية (للـ Admin) ---
// =======================================================================
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await AdminNotificationService.display(message);
}

// =======================================================================
// --- (جديد) PROVIDERS (للـ Admin) ---
// =======================================================================

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
    _token = prefs.getString('jwt_token_store_admin'); // (مفتاح جديد)
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String username, String password, {String? storeLat, String? storeLng}) async {
    final authService = AdminAuthService();
    _token = await authService.loginAdmin(username, password);

    if (_token != null) {
      await authService.registerDeviceToken();

      final prefs = await SharedPreferences.getInstance();
      if (storeLat != null && storeLng != null) {
        await prefs.setDouble('store_lat', double.tryParse(storeLat) ?? 0.0);
        await prefs.setDouble('store_lng', double.tryParse(storeLng) ?? 0.0);
        // (جديد) حفظ اسم المتجر (لطلبات الدليفري)
        await prefs.setString('saved_store_name', '');
      }

      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    final authService = AdminAuthService();
    await authService.logout();
    _token = null;
    // (يجب إضافة clearData() للـ providers الجدد)
    // Provider.of<DashboardProvider>(context, listen: false).clearData();
    notifyListeners();
  }
}

class DashboardProvider with ChangeNotifier {
  final AdminApiService _apiService = AdminApiService();
  Map<String, List<Order>> _orders = {};
  Map<int, String> _pickupCodes = {}; // كود استلام السائق

  bool _isLoading = false;
  bool _hasNetworkError = false;
  String _errorMessage = '';

  Map<String, List<Order>> get orders => _orders;
  Map<int, String> get pickupCodes => _pickupCodes;
  bool get isLoading => _isLoading;
  bool get hasNetworkError => _hasNetworkError;
  String get errorMessage => _errorMessage;

  void setPickupCode(int orderId, String code) {
    _pickupCodes[orderId] = code;
    notifyListeners(); // (تم الإصلاح: يجب التحديث فوراً)
  }

  void clearData() {
    _orders = {};
    _pickupCodes = {};
    notifyListeners();
  }

  Future<void> fetchDashboardData(String? token) async {
    if (token == null) return;

    // (يمكن إضافة نظام الكاش لاحقاً)
    _isLoading = true;
    _hasNetworkError = false;
    notifyListeners();

    try {
      // (يجب تعديل هذه الدوال في AdminApiService)
      final activeOrders = await _apiService.getStoreOrders(status: 'active', token: token);
      final completedOrders = await _apiService.getStoreOrders(status: 'completed', token: token);

      _orders['active'] = activeOrders;
      _orders['completed'] = completedOrders;
      _hasNetworkError = false;

    } catch (e) {
      if (_orders.isEmpty) {
        _hasNetworkError = true;
        _errorMessage = 'فشل في تحديث البيانات. يرجى التحقق من اتصالك بالإنترنت.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

class StoreSettingsProvider with ChangeNotifier {
  final AdminApiService _apiService = AdminApiService();
  bool _isStoreOpen = true;
  String _openTime = '09:00';
  String _closeTime = '22:00';
  bool _isLoading = false;

  bool get isStoreOpen => _isStoreOpen;
  String get openTime => _openTime;
  String get closeTime => _closeTime;
  bool get isLoading => _isLoading;

  Future<void> fetchSettings(String? token) async {
    if (token == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      final settings = await _apiService.getStoreSettings(token);
      _isStoreOpen = settings['is_open'] ?? true;
      _openTime = settings['auto_open_time'] ?? '09:00';
      _closeTime = settings['auto_close_time'] ?? '22:00';
    } catch (e) {
      // Handle error
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
      final success = await _apiService.updateStoreStatus(token, isOpen);
      if (success) _isStoreOpen = isOpen;
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
      final success = await _apiService.updateStoreAutoTimes(token, openTime, closeTime);
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
    _isStoreOpen = true;
    _openTime = '09:00';
    _closeTime = '22:00';
    notifyListeners();
  }
}

class StoreProductsProvider with ChangeNotifier {
  final AdminApiService _apiService = AdminApiService();
  List<Product> _allProducts = []; // (استخدام مودل المنتج من كود المسواك)
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Product> get products => _filteredProducts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchProducts(String? token) async {
    if (token == null) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allProducts = await _apiService.getMyStoreProducts(token);
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
      // (يجب تعديل هذه الدالة في AdminApiService)
      success = await _apiService.updateMyStoreProduct(token, productId, name, price, salePrice);
      if (success) {
        await fetchProducts(token); // تحديث القائمة
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
// --- (جديد) MODELS (للـ Admin) ---
// (هذه منسوخة من تطبيق المطعم)
// =======================================================================
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
  });

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
    );
  }
}

class LineItem {
  final String name;
  final int quantity;
  final String total;
  LineItem({required this.name, required this.quantity, required this.total});
  factory LineItem.fromJson(Map<String, dynamic> json) => LineItem(name: json['name'], quantity: json['quantity'], total: json['total'].toString());
}

// (مودل المنتج موجود في كود العميل بالأسفل)
// (مودل التقييمات يمكن إضافته لاحقاً)


// =======================================================================
// --- (جديد) SERVICES (للـ Admin) ---
// =======================================================================

class AdminNotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    await _localNotifications.initialize(initializationSettings);
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'new_store_orders_channel', // (قناة جديدة)
      'طلبات أسواق جديدة',
      description: 'إشعارات للطلبات الجديدة في الأسواق.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      sound: RawResourceAndroidNotificationSound('woo_sound'), // (يمكن استخدام نفس الصوت)
    );

    await _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);
  }

  static Future<void> display(RemoteMessage message) async {
    final String title = message.notification?.title ?? message.data['title'] ?? 'تحديث جديد!';
    final String body = message.notification?.body ?? message.data['body'] ?? 'لديك تحديث جديد.';
    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: AndroidNotificationDetails('new_store_orders_channel', 'طلبات أسواق جديدة', importance: Importance.max, priority: Priority.high),
      iOS: DarwinNotificationDetails(sound: 'woo_sound.caf', presentSound: true, presentAlert: true, presentBadge: true),
    );
    await _localNotifications.show(id, title, body, platformChannelSpecifics, payload: message.data['order_id']);
  }
}

class AdminAuthService {
  Future<String?> loginAdmin(String username, String password) async {
    try {
      final response = await http.post(
          Uri.parse('$STORE_BASE_URL/wp-json/jwt-auth/v1/token'), // (نفس مسار التوكن)
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'username': username, 'password': password})
      ).timeout(API_TIMEOUT);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['token'];
        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt_token_store_admin', token); // (مفتاح مميز)
          return token;
        }
      }
      return null;
    } catch (e) { return null; }
  }

  Future<void> registerDeviceToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token_store_admin');
    if (token == null) return;
    String? fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken == null) return;

    try {
      await http.post(
        Uri.parse('$STORE_APP_URL/register-device'), // (مسار جديد)
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: json.encode({'token': fcmToken}),
      ).timeout(API_TIMEOUT);
    } catch (e) { print("Error registering device token: $e"); }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token_store_admin');

    if (jwtToken != null) {
      try {
        await http.post(
          Uri.parse('$STORE_APP_URL/unregister-device'), // (مسار جديد)
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $jwtToken'},
        ).timeout(API_TIMEOUT);
      } catch (e) { print("Failed to unregister device: $e"); }
    }
    await FirebaseMessaging.instance.deleteToken();
    await prefs.remove('jwt_token_store_admin');
    await prefs.remove('store_lat');
    await prefs.remove('store_lng');
    await prefs.remove('saved_store_name');
  }
}

class AdminApiService {

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

  // (دالة تحديث موقع المدير)
  Future<bool> updateMyLocation(String token, String lat, String lng) async {
    return _executeWithRetry(() async {
      final response = await http.post(
        Uri.parse('$STORE_APP_URL/update-my-location'), // (مسار جديد)
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

  // (دالة جلب الطلبات للمدير)
  Future<List<Order>> getStoreOrders({required String status, required String token}) async {
    return _executeWithRetry(() async {
      final uri = Uri.parse('$STORE_APP_URL/get-orders?status=$status'); // (مسار جديد)
      final response = await http.get(uri, headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'});
      if (response.statusCode == 200) {
        return (json.decode(response.body) as List).map((json) => Order.fromJson(json)).toList();
      }
      throw Exception('Failed to load orders: ${response.body}');
    });
  }

  // (دالة تحديث حالة الطلب)
  Future<bool> updateOrderStatus(int orderId, String status) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token_store_admin');
    if (token == null) throw Exception('User not logged in');

    final response = await _executeWithRetry(() => http.post(
      Uri.parse('$STORE_APP_URL/update-order-status/$orderId'), // (مسار جديد)
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: json.encode({'status': status}),
    ));
    return response.statusCode == 200;
  }

  // (دالة إرسال طلب التوصيل - تستخدم نفس نظام التكسي)
  Future<Map<String, dynamic>> createUnifiedDeliveryRequest({
    required String token,
    required String sourceType, // 'store'
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
        // (نفس المسار - يفترض أن نظام التكسي موحد)
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

  // (دوال الإعدادات)
  Future<Map<String, dynamic>> getStoreSettings(String token) async {
    return _executeWithRetry(() async {
      final response = await http.get(
        Uri.parse('$STORE_APP_URL/get-settings'), // (مسار جديد)
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to load settings');
    });
  }
  Future<bool> updateStoreStatus(String token, bool isOpen) async {
    return _executeWithRetry(() async {
      final response = await http.post(
        Uri.parse('$STORE_APP_URL/update-status'), // (مسار جديد)
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: json.encode({'is_open': isOpen ? 1 : 0}),
      );
      return response.statusCode == 200;
    });
  }
  Future<bool> updateStoreAutoTimes(String token, String openTime, String closeTime) async {
    return _executeWithRetry(() async {
      final response = await http.post(
        Uri.parse('$STORE_APP_URL/update-auto-times'), // (مسار جديد)
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: json.encode({'open_time': openTime, 'close_time': closeTime}),
      );
      return response.statusCode == 200;
    });
  }

  // (دوال المنتجات)
  Future<List<Product>> getMyStoreProducts(String token) async {
    return _executeWithRetry(() async {
      final response = await http.get(
        Uri.parse('$STORE_APP_URL/my-products'), // (مسار جديد)
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        // (استخدام المودل الخاص بالمسواك)
        return data.map((json) => Product.fromJson(json)).toList();
      }
      throw Exception('Failed to load store products');
    });
  }
  Future<bool> updateMyStoreProduct(String token, int productId, String name, String price, String salePrice) async {
    return _executeWithRetry(() async {
      final response = await http.post(
        Uri.parse('$STORE_APP_URL/update-product'), // (مسار جديد)
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: json.encode({
          'product_id': productId,
          'name': name,
          'regular_price': price,
          'sale_price': salePrice, // (يجب أن يعالج الباكاند السعر الفارغ)
        }),
      );
      return response.statusCode == 200;
    });
  }

  // (دالة اختبار الإشعارات)
  Future<bool> testNotification() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token_store_admin');
    if (token == null) throw Exception('User not logged in');

    final response = await _executeWithRetry(() => http.post(
      Uri.parse('$STORE_APP_URL/test-notification'), // (مسار جديد)
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
    ));
    return response.statusCode == 200;
  }
}

// (خدمة الصلاحيات - منسوخة كما هي)
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


// =======================================================================
// --- (جديد) WIDGETS (للـ Admin) ---
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

// (بطاقة الطلب - منسوخة بالكامل من تطبيق المطعم ومعدلة)
class OrderCard extends StatefulWidget {
  final Order order;
  final VoidCallback onStatusChanged;
  final bool isCompleted;
  final String? pickupCode; // كود استلام السائق

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
  final AdminApiService _apiService = AdminApiService();
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الإحداثيات غير متوفرة لهذا الطلب')),
        );
      }
      return;
    }
    try {
      final double latitude = double.parse(lat);
      final double longitude = double.parse(lng);
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InAppMapScreen(
              latitude: latitude,
              longitude: longitude,
              title: 'موقع الزبون',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطأ في تنسيق الإحداثيات.')),
        );
      }
    }
  }

  void _showDeliveryRequestDialog(BuildContext cardContext, Order order) {
    final feeController = TextEditingController();
    final pickupNameController = TextEditingController();
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final destAddressController = TextEditingController(text: order.address);

    final orderDetails = order.lineItems.map((item) => '- ${item.quantity} x ${item.name}').join('\n');
    notesController.text = 'توصيل طلب مسواك رقم #${order.id}\n' // (تم التعديل)
        'المحتويات:\n$orderDetails';

    SharedPreferences.getInstance().then((prefs) {
      // (تم التعديل: استخدام المفتاح الصحيح)
      pickupNameController.text = prefs.getString('saved_store_name') ?? '';
    });

    showDialog(
      context: cardContext,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                        enabled: !isSubmitting,
                        decoration: const InputDecoration(labelText: 'اسم المتجر/الفرع'), // (تم التعديل)
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
                        enabled: !isSubmitting,
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
                        final prefs = await SharedPreferences.getInstance();
                        final storeToken = prefs.getString('jwt_token_store_admin'); // (تم التعديل)
                        if (storeToken == null) throw Exception("لم يتم العثور على جلسة دخول مدير المتجر. أعد تسجيل الدخول.");
                        final double? storeLat = prefs.getDouble('store_lat'); // (تم التعديل)
                        final double? storeLng = prefs.getDouble('store_lng'); // (تم التعديل)
                        if (storeLat == null || storeLng == null) throw Exception("إحداثيات المتجر غير محفوظة. أعد تسجيل الدخول.");
                        final double? customerLat = double.tryParse(order.destinationLat ?? '');
                        final double? customerLng = double.tryParse(order.destinationLng ?? '');

                        final result = await _apiService.createUnifiedDeliveryRequest(
                          token: storeToken,
                          sourceType: 'store', // (تم التعديل: المصدر هو "متجر")
                          sourceOrderId: order.id.toString(),
                          pickupName: pickupNameController.text,
                          pickupLat: storeLat,
                          pickupLng: storeLng,
                          destinationAddress: destAddressController.text,
                          destinationLat: customerLat,
                          destinationLng: customerLng,
                          deliveryFee: feeController.text,
                          orderDescription: notesController.text,
                          endCustomerPhone: order.phone,
                        );

                        if (mounted) {
                          final code = result['pickup_code']?.toString();
                          if (code != null) {
                            Provider.of<DashboardProvider>(cardContext, listen: false)
                                .setPickupCode(order.id, code);
                          }
                          await _updateStatus('out-for-delivery');
                          Navigator.of(dialogContext).pop();
                          ScaffoldMessenger.of(cardContext).showSnackBar(
                            SnackBar(
                              content: Text(result['message'] ?? 'تم إرسال طلب التوصيل بنجاح!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
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
                        onPressed: () => _launchMaps(context, widget.order.destinationLat, widget.order.destinationLng),
                      ),
                    ),
                  ),
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
      color: Colors.blue.withOpacity(0.05), // (تعديل اللون ليناسب المسواك)
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              Expanded(child: ElevatedButton(onPressed: () => _updateStatus('completed'), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), padding: const EdgeInsets.symmetric(vertical: 12)), child: const Text('إكمال الطلب'))), // (تعديل اللون)
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


// =======================================================================
// --- (جديد) SCREENS (للـ Admin) ---
// =======================================================================

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [ Theme.of(context).primaryColor, Colors.blue[800]! ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.store_mall_directory_outlined, size: 120, color: Colors.white),
              SizedBox(height: 20),
              Text( "مدير أسواق بيتي", style: TextStyle( fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, ),),
            ],
          ),
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
  final AdminApiService _apiService = AdminApiService();

  Future<void> _getCurrentLocation() async {
    setState(() => _locationStatus = 'جاري تحديد الموقع...');
    try {
      final hasPermission = await PermissionService.handleLocationPermission(context);
      if (!hasPermission) {
        throw Exception('صلاحية الوصول للموقع مرفوضة أو الخدمة معطلة.');
      }
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
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
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    if (_latController.text.isEmpty || _lngController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء تحديد موقع المتجر أولاً.')));
      return;
    }
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _usernameController.text,
      _passwordController.text,
      storeLat: _latController.text,
      storeLng: _lngController.text,
    );

    if (!mounted) return;
    if (success) {
      try {
        final token = authProvider.token!;
        final lat = _latController.text;
        final lng = _lngController.text;
        await _apiService.updateMyLocation(token, lat, lng);
        // (تم حذف الانتقال، AuthWrapper سيتولى الأمر)
      } catch (e) {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('تم تسجيل الدخول، لكن فشل حفظ الموقع على الخادم: $e'),
                backgroundColor: Colors.orange,
              )
          );
        }
        // (سيتم الانتقال على أي حال)
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل تسجيل الدخول. الرجاء التأكد من البيانات.')));
    }
    if(mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('دخول مدير المسواق')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.storefront_outlined, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              TextFormField( controller: _usernameController, decoration: const InputDecoration( labelText: 'اسم المستخدم أو البريد الإلكتروني'), validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null),
              const SizedBox(height: 20),
              TextFormField( controller: _passwordController, decoration: const InputDecoration(labelText: 'كلمة المرور'), obscureText: true, validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null),
              const SizedBox(height: 40),
              Text('تحديد موقع المتجر الحالي (لنقاط الانطلاق في التوصيل)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.location_on),
                label: const Text('تحديد موقع المتجر الآن'),
                onPressed: _getCurrentLocation,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _locationStatus,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _latController.text.isEmpty ? Colors.red : Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 40),
              _isLoading ? const CircularProgressIndicator() : ElevatedButton( onPressed: _login, style: ElevatedButton.styleFrom( minimumSize: const Size(double.infinity, 50), textStyle: const TextStyle(fontSize: 18)), child: const Text('تسجيل الدخول'))
            ]),
          ),
        ),
      ),
    );
  }
}

class StoreDashboardScreen extends StatefulWidget {
  const StoreDashboardScreen({super.key});
  @override
  State<StoreDashboardScreen> createState() => _StoreDashboardScreenState();
}

class _StoreDashboardScreenState extends State<StoreDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdminApiService _apiService = AdminApiService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // (تم التعديل إلى 4)
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // (دالة طلب التوصيل الخاص - منسوخة ومعدلة)
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

    SharedPreferences.getInstance().then((prefs) {
      final savedName = prefs.getString('saved_store_name') ?? '';
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
                      Text("سيتم إرسال الطلب من موقع متجرك المسجل.", style: Theme.of(context).textTheme.bodySmall),
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
                        final token = prefs.getString('jwt_token_store_admin');
                        final pickupLat = prefs.getDouble('store_lat');
                        final pickupLng = prefs.getDouble('store_lng');
                        if (token == null || pickupLat == null || pickupLng == null) {
                          throw Exception("بيانات المتجر غير كاملة. يرجى تسجيل الخروج والدخول مرة أخرى.");
                        }
                        final pickupName = _pickupNameController.text;
                        await prefs.setString('saved_store_name', pickupName);
                        final double? destLat = double.tryParse(_destLatController.text);
                        final double? destLng = double.tryParse(_destLngController.text);

                        final result = await _apiService.createUnifiedDeliveryRequest(
                          token: token,
                          sourceType: 'store', // (تم التعديل)
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
        title: const Text('لوحة تحكم المسواق'),
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
          IconButton(icon: const Icon(Icons.logout), onPressed: () => auth.logout(), tooltip: 'تسجيل الخروج')
        ],
        bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(icon: Icon(Icons.list_alt), text: 'الطلبات'),
              Tab(icon: Icon(Icons.history), text: 'المكتملة'),
              Tab(icon: Icon(Icons.fastfood_outlined), text: 'المنتجات'),
              Tab(icon: Icon(Icons.settings), text: 'الإعدادات'),
              // (يمكن إضافة التقييمات لاحقاً)
            ]
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          OrdersListScreen(status: 'active'),
          OrdersListScreen(status: 'completed'),
          StoreProductManagementTab(), // (شاشة جديدة)
          StoreSettingsScreen(), // (شاشة جديدة)
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

class OrdersListScreen extends StatefulWidget {
  final String status;
  const OrdersListScreen({super.key, required this.status});
  @override
  State<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends State<OrdersListScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Consumer<DashboardProvider>(
      builder: (context, dashboard, child) {
        if (dashboard.isLoading && (dashboard.orders[widget.status] == null || dashboard.orders[widget.status]!.isEmpty)) {
          return const Center(child: CircularProgressIndicator());
        }
        if (dashboard.hasNetworkError && (dashboard.orders[widget.status] == null || dashboard.orders[widget.status]!.isEmpty)) {
          return NetworkErrorWidget(message: dashboard.errorMessage, onRetry: () => dashboard.fetchDashboardData(authProvider.token));
        }
        final orders = dashboard.orders[widget.status] ?? [];
        final pickupCodes = dashboard.pickupCodes;

        return RefreshIndicator(
          onRefresh: () => dashboard.fetchDashboardData(authProvider.token),
          child: orders.isEmpty
              ? Center(child: ListView(physics: const AlwaysScrollableScrollPhysics(), children: [SizedBox(height: MediaQuery.of(context).size.height * 0.2), Text('لا توجد طلبات في هذا القسم حالياً', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.grey.shade600)), const SizedBox(height: 10), const Icon(Icons.inbox_outlined, size: 50, color: Colors.grey)]))
              : ListView.builder(
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

class StoreSettingsScreen extends StatefulWidget {
  const StoreSettingsScreen({super.key});
  @override
  State<StoreSettingsScreen> createState() => _StoreSettingsScreenState();
}

class _StoreSettingsScreenState extends State<StoreSettingsScreen> {

  Future<void> _updateStatus(StoreSettingsProvider provider, bool newValue) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final success = await provider.updateOpenStatus(token, newValue);
    if(success) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text(newValue ? 'تم فتح المتجر بنجاح.' : 'تم إغلاق المتجر بنجاح.'), backgroundColor: Colors.green));
    } else {
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('فشل تحديث الحالة.'), backgroundColor: Colors.red));
    }
  }

  Future<void> _showTimePicker(BuildContext context, StoreSettingsProvider provider, bool isOpeningTime) async {
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
      final token = Provider.of<AuthProvider>(context, listen: false).token;
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
    return Consumer<StoreSettingsProvider>(
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
                          provider.isStoreOpen ? 'المتجر متاح لاستقبال الطلبات' : 'المتجر غير متاح حالياً',
                          style: TextStyle(fontWeight: FontWeight.bold, color: provider.isStoreOpen ? Colors.green : Colors.red),
                        ),
                        value: provider.isStoreOpen,
                        onChanged: (newValue) => _updateStatus(provider, newValue),
                        secondary: Icon(provider.isStoreOpen ? Icons.store_mall_directory : Icons.storefront_outlined),
                        activeColor: Colors.green,
                      ),
                      const SizedBox(height: 10),
                      Text('عند إغلاق هذا الخيار، سيظهر للزبون "المتجر غير متوفر حالياً" وستختفي المنتجات.', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
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

class StoreProductManagementTab extends StatefulWidget {
  const StoreProductManagementTab({super.key});
  @override
  State<StoreProductManagementTab> createState() => _StoreProductManagementTabState();
}

class _StoreProductManagementTabState extends State<StoreProductManagementTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToEditScreen(Product product) async {
    final productProvider = Provider.of<StoreProductsProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final bool? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditStoreProductScreen(
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

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    return Consumer<StoreProductsProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
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
                return const Center(child: Text("لم يتم العثور على منتجات لهذا المتجر."));
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
                    subtitle: Text("السعر: ${product.formattedPrice}", style: const TextStyle(color: Colors.black)), // (لا يوجد سعر خصم في مودل المسواك)
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () => _navigateToEditScreen(product),
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

class EditStoreProductScreen extends StatefulWidget {
  final Product product;
  final StoreProductsProvider productProvider;
  final AuthProvider authProvider;

  const EditStoreProductScreen({
    super.key,
    required this.product,
    required this.productProvider,
    required this.authProvider,
  });

  @override
  State<EditStoreProductScreen> createState() => _EditStoreProductScreenState();
}

class _EditStoreProductScreenState extends State<EditStoreProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _salePriceController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _priceController = TextEditingController(text: widget.product.price.toStringAsFixed(0));
    _salePriceController = TextEditingController(text: ''); // (مودل المسواك لا يحتوي سعر خصم)
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
    final LatLng point = LatLng(latitude, longitude);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: point,
          initialZoom: 16.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.beytei.miswak', // (تم التعديل)
          ),
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


// =======================================================================
// --- (جديد) MAIN APP ENTRY POINT & WRAPPERS ---
// =======================================================================

// (هذا هو كود الزبون الأصلي - أصبح الآن جزءاً من التطبيق)
class CustomerApp extends StatelessWidget {
  const CustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مسواك بيتي',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Tajawal',
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      debugShowCheckedModeBanner: false,
      home: const LocationCheckWrapper(), // (يبدأ بشاشة المسواك)
    );
  }
}

// (هذا هو مدخل التطبيق المدمج الجديد)
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // (إعدادات Firebase للـ Admin)
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),

          ChangeNotifierProxyProvider<AuthProvider, DashboardProvider>(
            create: (_) => DashboardProvider(),
            update: (_, auth, dashboard) {
              if(auth.isLoggedIn && dashboard != null && auth.token != null) {
                dashboard.fetchDashboardData(auth.token);
              } else if (dashboard != null && !auth.isLoggedIn) {
                dashboard.clearData();
              }
              return dashboard!;
            },
          ),

          ChangeNotifierProxyProvider<AuthProvider, StoreSettingsProvider>(
            create: (_) => StoreSettingsProvider(),
            update: (_, auth, settings) {
              if(settings != null && auth.isLoggedIn && auth.token != null) {
                settings.fetchSettings(auth.token);
              } else if (settings != null && !auth.isLoggedIn) {
                settings.clearData();
              }
              return settings!;
            },
          ),

          ChangeNotifierProxyProvider<AuthProvider, StoreProductsProvider>(
            create: (_) => StoreProductsProvider(),
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
        child: const AuthWrapper(),
      )
  );
}

// (الـ Wrapper الذي يختار بين شاشة الزبون أو شاشة المدير)
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    // (تهيئة إشعارات المدير)
    await AdminNotificationService.initialize();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      AdminNotificationService.display(message);
      if (!mounted) return;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isLoggedIn) {
        Provider.of<DashboardProvider>(context, listen: false).fetchDashboardData(authProvider.token);
        Provider.of<StoreSettingsProvider>(context, listen: false).fetchSettings(authProvider.token);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        if (auth.isLoading) {
          return const MaterialApp(home: SplashScreen()); // (شاشة تحميل المدير)
        }

        if (auth.isLoggedIn) {
          // 1. إذا كان المدير مسجلاً، اذهب إلى لوحة التحكم
          return MaterialApp(
            title: 'مدير المسواق',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              fontFamily: 'Tajawal',
              scaffoldBackgroundColor: const Color(0xFFF5F5F5),
            ),
            debugShowCheckedModeBanner: false,
            home: const StoreDashboardScreen(),
          );
        }

        // 2. إذا لم يكن مسجلاً، اذهب إلى تطبيق الزبون (مسواك بيتي)
        // (نحن لا نظهر شاشة تسجيل الدخول هنا، الزبون يدخل للتطبيق مباشرة)
        // (للوصول لشاشة تسجيل دخول المدير، يجب إضافتها في مكان ما في تطبيق الزبون)
        return const CustomerApp();
      },
    );
  }
}
class LocationService {
  static const String BEYTEI_URL = 'https://beytei.com';

  Future<List<Area>> getAreas() async {
    try {
      final response = await http.get(Uri.parse('$BEYTEI_URL/wp-json/wp/v2/area?per_page=100'));
      if (response.statusCode == 200) {
        return (json.decode(response.body) as List).map((json) => Area.fromJson(json)).toList();
      }
      throw Exception('Server error');
    } catch (e) {
      throw Exception('Failed to load areas');
    }
  }
}




// 3. شاشة اختيار الموقع
class SelectLocationScreen extends StatefulWidget {
  final bool isCancellable;
  const SelectLocationScreen({super.key, this.isCancellable = false});
  @override
  State<SelectLocationScreen> createState() => _SelectLocationScreenState();
}

class _SelectLocationScreenState extends State<SelectLocationScreen> {
  final LocationService _locationService = LocationService();
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

  Future<void> _loadAreas() async {
    try {
      final areas = await _locationService.getAreas();
      if (mounted) setState(() { _allAreas = areas; _filteredAreas = areas; _isLoading = false; });
    } catch (e) {
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
    await prefs.setString('selectedAreaName', areaName); // حفظ الاسم للعرض

    if(mounted) {
      if (widget.isCancellable) {
        Navigator.of(context).pop(true);
      } else {
        // الانتقال للشاشة الرئيسية للمسواك
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MiswakStoreScreen()),
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
// هذا الكلاس هو نقطة الدخول لقسم المسواك
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
        // 1. أثناء التحميل (فحص الذاكرة)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. إذا كانت المنطقة موجودة في الذاكرة -> اذهب للمتجر
        if (snapshot.hasData && snapshot.data != null) {
          return const MiswakStoreScreen();
        }

        // 3. إذا لم تكن موجودة -> اذهب لشاشة اختيار المنطقة
        // (isCancellable: false) تعني أنه مجبر على الاختيار
        return const SelectLocationScreen(isCancellable: false);
      },
    );
  }
}









// =======================================================================
// --- (كود تطبيق الزبون - كما أرسلته) ---
// =======================================================================
class Area {
  final int id;
  final String name;
  final int parentId;
  Area({required this.id, required this.name, required this.parentId});
  factory Area.fromJson(Map<String, dynamic> json) => Area(id: json['id'], name: json['name'], parentId: json['parent']);
}
class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  int quantity;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    this.quantity = 1,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      price: double.tryParse(json['price'] ?? '0.0') ?? 0.0,
      imageUrl: json['images'] != null && json['images'].isNotEmpty
          ? json['images'][0]['src'].replaceAll('.jpg', '-300x300.jpg')
          : 'https://via.placeholder.com/150',
      category: json['categories'] != null && json['categories'].isNotEmpty
          ? json['categories'][0]['name']
          : 'عام',
    );
  }

  String get formattedPrice {
    final formatter = NumberFormat('#,###');
    // (تم تعديل السعر ليناسب الأسواق - بالدينار وليس "الف")
    return '${formatter.format(price)} د.ع';
  }
}

class MiswakStoreScreen extends StatefulWidget {
  const MiswakStoreScreen({Key? key}) : super(key: key);

  @override
  State<MiswakStoreScreen> createState() => _MiswakStoreScreenState();
}

class _MiswakStoreScreenState extends State<MiswakStoreScreen> {
  // متغيرات البيانات
  List<Product> products = [];
  List<Product> cartItems = [];
  List<dynamic> mainCategories = [];

  // متغيرات الحالة
  bool isLoading = true;
  bool showCart = false;
  bool showCheckout = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  double totalPrice = 0.0;
  int? _currentCategoryId;
  bool _isConnected = true;
  bool _isCategoriesVisible = true;

  // ✨ متغيرات المنطقة الجديدة
  int? _selectedAreaId;
  String? _selectedAreaName;

  // المتحكمات
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  bool _isSubmitting = false;

  // صور البانر
  List<String> bannerImages = [
    'https://beytei.com/wp-content/uploads/2023/05/banner1.jpg',
    'https://beytei.com/wp-content/uploads/2023/05/banner2.jpg',
    'https://beytei.com/wp-content/uploads/2023/05/banner3.jpg',
  ];
  int _currentBannerIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);

    // ✨ التعديل 1: بدلاً من فحص الاتصال مباشرة، نقوم بتحميل المنطقة أولاً
    _initializeWithLocation();
  }

  // ✨ دالة جديدة لتهيئة الموقع
  Future<void> _initializeWithLocation() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _selectedAreaId = prefs.getInt('selectedAreaId');
        _selectedAreaName = prefs.getString('selectedAreaName');
      });
    }
    // بعد تحميل المنطقة، نقوم بفحص الاتصال وجلب المنتجات
    _checkConnection();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchDebounce?.cancel();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkConnection() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    setState(() => _isConnected = connectivityResult != ConnectivityResult.none);

    if (_isConnected) {
      await Future.wait([
        _fetchProducts(),
        _fetchMainCategories(),
      ]);
    }
  }

  Future<void> _fetchProducts({String searchQuery = '', int? categoryId, bool loadMore = false}) async {
    if (_isLoadingMore) return;

    if (!loadMore) {
      _page = 1;
      _hasMore = true;
      if(mounted) setState(() => isLoading = true);
    } else {
      if (!_hasMore) return;
      _page++;
      if(mounted) setState(() => _isLoadingMore = true);
    }

    try {
      // ✨ التعديل 2: إضافة area_id للرابط
      String apiUrl = 'https://beytei.com/wp-json/wc/v3/products?page=$_page&per_page=10';

      // إرسال المنطقة للسيرفر إذا كانت محددة
      if (_selectedAreaId != null) {
        apiUrl += '&area_id=$_selectedAreaId';
      }

      if (searchQuery.isNotEmpty) apiUrl += '&search=$searchQuery';
      if (categoryId != null && categoryId != 0) apiUrl += '&category=$categoryId';

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$CUSTOMER_CONSUMER_KEY:$CUSTOMER_CONSUMER_SECRET'))}',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        final fetchedProducts = data.map((json) => Product.fromJson(json)).toList();

        if (mounted) {
          setState(() {
            if (loadMore) {
              products.addAll(fetchedProducts);
            } else {
              products = fetchedProducts;
            }
            _hasMore = fetchedProducts.length == 10;
            isLoading = false;
            _isLoadingMore = false;
            _currentCategoryId = categoryId;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          _isLoadingMore = false;
          _isConnected = false;
        });
        if (!loadMore) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('الاتصال بالإنترنت ضعيف، يرجى التحقق من اتصالك')),
          );
        }
      }
    }
  }

  Future<void> _fetchMainCategories() async {
    try {
      final response = await http.get(
        Uri.parse('https://beytei.com/wp-json/wc/v3/products/categories?parent=0&per_page=100'), // جلب كل التصنيفات
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$CUSTOMER_CONSUMER_KEY:$CUSTOMER_CONSUMER_SECRET'))}',
        },
      );

      if (response.statusCode == 200 && mounted) {
        setState(() => mainCategories = json.decode(response.body));
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  void _scrollListener() {
    final direction = _scrollController.position.userScrollDirection;

    if (direction == ScrollDirection.forward) {
      if (!_isCategoriesVisible) setState(() => _isCategoriesVisible = true);
    } else if (direction == ScrollDirection.reverse) {
      if (_isCategoriesVisible) setState(() => _isCategoriesVisible = false);
    }

    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9 && !_isLoadingMore) {
      _fetchProducts(
        searchQuery: _searchController.text,
        categoryId: _currentCategoryId,
        loadMore: true,
      );
    }
  }

  // --- دوال السلة والدفع (بقيت كما هي) ---
  void addToCart(Product product) {
    setState(() {
      final existingIndex = cartItems.indexWhere((item) => item.id == product.id);
      if (existingIndex >= 0) {
        cartItems[existingIndex].quantity++;
      } else {
        cartItems.add(Product(
          id: product.id,
          name: product.name,
          description: product.description,
          price: product.price,
          imageUrl: product.imageUrl,
          category: product.category,
          quantity: 1,
        ));
      }
      _calculateTotal();
      showCart = true;
    });
    _showAddToCartDialog(product);
  }

  void _showAddToCartDialog(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تمت الإضافة إلى السلة"),
        content: Text("${product.name} تمت إضافته إلى سلة التسوق"),
        actions: [
          TextButton(child: const Text("مواصلة التسوق"), onPressed: () => Navigator.of(context).pop()),
          ElevatedButton(
            child: const Text("إتمام الطلب"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[300]),
            onPressed: () {
              Navigator.of(context).pop();
              setState(() { showCart = true; showCheckout = true; });
            },
          ),
        ],
      ),
    );
  }

  void removeFromCart(Product product) {
    setState(() {
      cartItems.removeWhere((item) => item.id == product.id);
      _calculateTotal();
      if (cartItems.isEmpty) showCart = false;
    });
  }

  void updateQuantity(Product product, int newQuantity) {
    setState(() {
      final index = cartItems.indexWhere((item) => item.id == product.id);
      if (index >= 0) {
        if (newQuantity > 0) {
          cartItems[index].quantity = newQuantity;
        } else {
          cartItems.removeAt(index);
        }
        _calculateTotal();
      }
      if (cartItems.isEmpty) showCart = false;
    });
  }

  void _calculateTotal() {
    double productTotal = cartItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
    if (cartItems.isEmpty) {
      totalPrice = 0.0;
    } else {
      totalPrice = productTotal + 1000.0;
    }
  }

  void _showCheckoutForm() => setState(() => showCheckout = true);
  void _hideCheckoutForm() => setState(() => showCheckout = false);

  void _submitOrder() {
    if (_isSubmitting) return;
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty || _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء تعبئة جميع الحقول')));
      return;
    }
    setState(() => _isSubmitting = true);
    _sendOrderToWooCommerce();
  }

  Future<void> _sendOrderToWooCommerce() async {
    try {
      final response = await http.post(
        Uri.parse('https://beytei.com/wp-json/wc/v3/orders'),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$CUSTOMER_CONSUMER_KEY:$CUSTOMER_CONSUMER_SECRET'))}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "payment_method": "cod",
          "payment_method_title": "الدفع عند الاستلام",
          "customer_note": "طلب من تطبيق مسواك بيتي - المنطقة: ${_selectedAreaName ?? 'غير محدد'}",
          "billing": { "first_name": _nameController.text, "phone": _phoneController.text },
          "shipping": { "address_1": _addressController.text },
          "line_items": cartItems.map((product) => { "product_id": product.id, "quantity": product.quantity }).toList(),
          "fee_lines": [{ "name": "أجرة التوصيل", "total": "1000", "tax_status": "none" }],

          // إرسال المنطقة المختارة في الميتا داتا (اختياري)
          "meta_data": [
            if (_selectedAreaId != null) {"key": "_selected_area_id", "value": _selectedAreaId.toString()}
          ]
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تأكيد طلبك بنجاح انتظر اتصال المندوب !')));
        if (mounted) {
          setState(() {
            cartItems.clear(); totalPrice = 0.0; showCart = false; showCheckout = false;
            _nameController.clear(); _phoneController.clear(); _addressController.clear();
          });
        }
      } else {
        throw Exception('فشل إرسال الطلب: ${response.body}');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ في إرسال الطلب: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // --- Widgets ---

  void _showProductDetails(Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(product.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 10),
            Text('الفئة: ${product.category}', style: TextStyle(color: Colors.blue[800])),
            const SizedBox(height: 20),
            Center(child: CachedNetworkImage(imageUrl: product.imageUrl.replaceAll('-300x300', ''), height: 200, fit: BoxFit.contain, placeholder: (context, url) => Center(child: CircularProgressIndicator()), errorWidget: (context, url, error) => Icon(Icons.image_not_supported))),
            const SizedBox(height: 20),
            const Text('وصف المنتج:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(product.description.replaceAll(RegExp(r'<[^>]*>'), '')),
            const SizedBox(height: 20),
            const Text('السعر:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(product.formattedPrice, style: const TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () { Navigator.pop(context); addToCart(product); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], padding: const EdgeInsets.symmetric(vertical: 15)), child: const Text('أضف إلى السلة الآن'))),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // ... (نفس دالة _buildBannerSlider السابقة)
  Widget _buildBannerSlider() {
    return Container(
      height: 140,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          CarouselSlider(
            items: bannerImages.map((imageUrl) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(image: CachedNetworkImageProvider(imageUrl), fit: BoxFit.cover),
              ),
            )).toList(),
            options: CarouselOptions(height: 140, autoPlay: true, enlargeCenterPage: true, viewportFraction: 0.92, onPageChanged: (index, _) => setState(() => _currentBannerIndex = index)),
          ),
          Positioned(
            bottom: 10,
            child: Row(children: bannerImages.map((url) { int index = bannerImages.indexOf(url); return Container(width: 8, height: 8, margin: const EdgeInsets.symmetric(horizontal: 4), decoration: BoxDecoration(shape: BoxShape.circle, color: _currentBannerIndex == index ? Colors.blue[300] : Colors.white.withOpacity(0.7))); }).toList()),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCategories() {
    if (mainCategories.isEmpty || !_isCategoriesVisible) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 120,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: mainCategories.length + 1,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: InkWell(
                onTap: () { setState(() => _currentCategoryId = null); _fetchProducts(); },
                child: Column(children: [
                  Container(width: 80, height: 80, decoration: BoxDecoration(color: _currentCategoryId == null ? Colors.blue[100] : Colors.grey[200], borderRadius: BorderRadius.circular(40), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 1, blurRadius: 5, offset: const Offset(0, 2))]), child: const Icon(Icons.all_inclusive, color: Colors.blue)),
                  const SizedBox(height: 5),
                  Text('الكل', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _currentCategoryId == null ? Colors.blue[800] : Colors.black)),
                ]),
              ),
            );
          }
          var category = mainCategories[index - 1];
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: InkWell(
              onTap: () { setState(() => _currentCategoryId = category['id']); _fetchProducts(categoryId: category['id']); },
              child: Column(children: [
                Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(color: _currentCategoryId == category['id'] ? Colors.blue[100] : Colors.grey[200], borderRadius: BorderRadius.circular(40), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 1, blurRadius: 5, offset: const Offset(0, 2))]),
                    child: category['image'] != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(40), child: CachedNetworkImage(imageUrl: category['image']['src'], fit: BoxFit.cover, placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 1.5)), errorWidget: (context, url, error) => const Icon(Icons.category, color: Colors.blue)))
                        : const Icon(Icons.category, color: Colors.blue)
                ),
                const SizedBox(height: 5),
                Text(category['name'], style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _currentCategoryId == category['id'] ? Colors.blue[800] : Colors.black)),
              ]),
            ),
          );
        },
      ),
    );
  }

  // ... (ProductCard, CartItem, CartSummary, CheckoutForm, Shimmer, EmptyState, CartFab - نفس الكود السابق)
  // سأقوم باختصارهم هنا لتوفير المساحة، انسخهم كما هم من الكود السابق

  Widget _buildProductCard(Product product) {
    return Card(
      elevation: 2, margin: const EdgeInsets.all(5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showProductDetails(product), borderRadius: BorderRadius.circular(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(12)), child: CachedNetworkImage(imageUrl: product.imageUrl, height: 120, width: double.infinity, fit: BoxFit.cover, placeholder: (context, url) => Container(color: Colors.grey[100], child: const Center(child: CircularProgressIndicator(strokeWidth: 1.5))), errorWidget: (context, url, error) => Container(color: Colors.grey[200], child: const Icon(Icons.shopping_bag, size: 50, color: Colors.blue)))),
          Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 5),
            Text(product.category, style: TextStyle(fontSize: 12, color: Colors.blue[800])),
            const SizedBox(height: 5),
            Text(product.formattedPrice, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Align(alignment: Alignment.centerLeft, child: IconButton(icon: const Icon(Icons.add_shopping_cart, color: Colors.blue), onPressed: () => addToCart(product), style: IconButton.styleFrom(backgroundColor: Colors.blue[50], padding: const EdgeInsets.all(8)))),
          ])),
        ]),
      ),
    );
  }

  Widget _buildCartItem(Product product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 5, offset: const Offset(0, 2))]),
      child: Row(children: [
        InkWell(onTap: () => _showProductDetails(product), child: ClipRRect(borderRadius: BorderRadius.circular(8), child: CachedNetworkImage(imageUrl: product.imageUrl, width: 60, height: 60, fit: BoxFit.cover))),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis), Text(product.formattedPrice, style: const TextStyle(color: Colors.grey))])),
        const SizedBox(width: 10),
        Row(children: [IconButton(icon: const Icon(Icons.remove, size: 18), onPressed: () => updateQuantity(product, product.quantity - 1)), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(4)), child: Text(product.quantity.toString())), IconButton(icon: const Icon(Icons.add, size: 18), onPressed: () => updateQuantity(product, product.quantity + 1)), const SizedBox(width: 5), IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 18), onPressed: () => removeFromCart(product))]),
      ]),
    );
  }

  Widget _buildCartSummary() {
    final formatter = NumberFormat('#,###');
    double productTotal = cartItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
    return Container(
      padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(20)), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), spreadRadius: 2, blurRadius: 10, offset: const Offset(0, -3))]),
      child: Column(children: [
        const Text('ملخص السلة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ConstrainedBox(constraints: const BoxConstraints(maxHeight: 150), child: ListView.builder(shrinkWrap: true, itemCount: cartItems.length, itemBuilder: (context, index) => _buildCartItem(cartItems[index]))),
        const Divider(),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('مجموع المنتجات:'), Text('${formatter.format(productTotal)} د.ع')]),
        const SizedBox(height: 5),
        const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('أجرة التوصيل:'), Text('1,000 د.ع', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange))]),
        const Divider(),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('الإجمالي الكلي:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Text('${formatter.format(totalPrice)} د.ع', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green))]),
        const SizedBox(height: 15),
        Row(children: [Expanded(child: ElevatedButton(onPressed: _showCheckoutForm, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('إتمام الطلب', style: TextStyle(fontSize: 16)))), const SizedBox(width: 10), IconButton(onPressed: () => setState(() => showCart = false), icon: const Icon(Icons.close, color: Colors.red))]),
      ]),
    );
  }

  Widget _buildCheckoutForm() {
    final formatter = NumberFormat('#,###');
    double productTotal = cartItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
    return Container(
      width: MediaQuery.of(context).size.width * 0.9, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), spreadRadius: 3, blurRadius: 10)]),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('إتمام الطلب', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), IconButton(onPressed: _isSubmitting ? null : _hideCheckoutForm, icon: const Icon(Icons.close))]),
          const Divider(), const SizedBox(height: 15),
          const Align(alignment: Alignment.centerRight, child: Text('ملخص الطلب', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))), const SizedBox(height: 10),
          ...cartItems.map((product) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [Expanded(child: Text('${product.name} (${product.quantity})')), Text('${formatter.format(product.price * product.quantity)} د.ع', style: const TextStyle(fontWeight: FontWeight.bold))]))).toList(),
          const Divider(),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('المنتجات:', style: TextStyle(color: Colors.grey)), Text('${formatter.format(productTotal)} د.ع')]), const SizedBox(height: 5),
          const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('التوصيل:', style: TextStyle(color: Colors.grey)), Text('1,000 د.ع')]),
          const Divider(),
          Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [const Text('الإجمالي:', style: TextStyle(fontWeight: FontWeight.bold)), const Spacer(), Text('${formatter.format(totalPrice)} د.ع', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green))])),
          const SizedBox(height: 20),
          const Align(alignment: Alignment.centerRight, child: Text('معلومات العميل', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))), const SizedBox(height: 15),
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'الاسم الكامل', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)), enabled: !_isSubmitting), const SizedBox(height: 15),
          TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'رقم الهاتف', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)), keyboardType: TextInputType.phone, enabled: !_isSubmitting), const SizedBox(height: 15),
          TextField(controller: _addressController, decoration: const InputDecoration(labelText: 'عنوان التوصيل', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on)), maxLines: 2, enabled: !_isSubmitting), const SizedBox(height: 25),
          SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _isSubmitting ? null : _submitOrder, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('تأكيد الطلب', style: TextStyle(fontSize: 18)))), const SizedBox(height: 10),
        ]),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return GridView.builder(
        padding: const EdgeInsets.all(10), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 10, mainAxisSpacing: 10), itemCount: 6,
        itemBuilder: (context, index) {
          return Card(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Container(decoration: BoxDecoration(color: Colors.grey[200], borderRadius: const BorderRadius.vertical(top: Radius.circular(15))), child: const Center(child: CircularProgressIndicator(strokeWidth: 1.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.blue))))), Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(height: 16, width: double.infinity, color: Colors.grey[200]), const SizedBox(height: 8), Container(height: 12, width: 100, color: Colors.grey[200]), const SizedBox(height: 12), Container(height: 20, width: 80, color: Colors.grey[200])]))]));
        }
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(_isConnected ? Icons.search_off : Icons.wifi_off, size: 80, color: Colors.blue[200]), const SizedBox(height: 20), Text(_isConnected ? 'لم يتم العثور على منتجات' : 'لا يوجد اتصال بالإنترنت', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 10), Text(_isConnected ? 'حاول البحث باستخدام مصطلحات أخرى' : 'يرجى التحقق من اتصالك بالإنترنت', style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center), const SizedBox(height: 20), if (!_isConnected) ElevatedButton(onPressed: _checkConnection, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12)), child: const Text('إعادة المحاولة'))]));
  }

  Widget _buildCartFab() {
    return Stack(clipBehavior: Clip.none, children: [FloatingActionButton(onPressed: () => setState(() => showCart = true), backgroundColor: Colors.blue[800], elevation: 6, child: const Icon(Icons.shopping_cart)), if (cartItems.isNotEmpty) Positioned(top: -5, right: -5, child: Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: Text(cartItems.length.toString(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))))]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // ✨ التعديل 3: تحويل العنوان إلى زر لتغيير المنطقة
        title: InkWell(
          onTap: () async {
            // الانتقال لشاشة تغيير المنطقة (يجب التأكد من وجود SelectLocationScreen في المشروع)
            final result = await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SelectLocationScreen(isCancellable: true)),
            );

            // تحديث البيانات إذا تم تغيير المنطقة
            if (result == true) {
              final prefs = await SharedPreferences.getInstance();
              setState(() {
                _selectedAreaId = prefs.getInt('selectedAreaId');
                _selectedAreaName = prefs.getString('selectedAreaName');
                products.clear();
                _page = 1;
                isLoading = true;
              });
              _fetchProducts();
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('مسواك بيتي', style: TextStyle(color: Colors.white)),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 12, color: Colors.white70),
                  const SizedBox(width: 4),
                  // عرض اسم المنطقة المختارة
                  Text(_selectedAreaName ?? "اختر المنطقة", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  const Icon(Icons.keyboard_arrow_down, size: 12, color: Colors.white70),
                ],
              )
            ],
          ),
        ),

        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.blue[800]!, Colors.blue[600]!])),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'شنو محتاج اليوم ؟...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.close), onPressed: () { _searchController.clear(); _fetchProducts(); })
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (query) {
                if (_searchDebounce?.isActive ?? false) _searchDebounce?.cancel();
                _searchDebounce = Timer(const Duration(milliseconds: 500), () { _fetchProducts(searchQuery: query, categoryId: _currentCategoryId); });
              },
            ),
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.admin_panel_settings_outlined, color: Colors.white), tooltip: "دخول مدير المسواق", onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StoreLoginScreen()))),
          Stack(children: [IconButton(onPressed: () => setState(() => showCart = !showCart), icon: const Icon(Icons.shopping_cart, color: Colors.white)), if (cartItems.isNotEmpty) Positioned(right: 8, top: 8, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: Text(cartItems.length.toString(), style: const TextStyle(color: Colors.white, fontSize: 12))))]),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildBannerSlider(),
              AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: _buildMainCategories()),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async { await _fetchProducts(searchQuery: _searchController.text, categoryId: _currentCategoryId); },
                  child: isLoading
                      ? _buildShimmerLoading()
                      : products.isEmpty
                      ? _buildEmptyState()
                      : GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 8, mainAxisSpacing: 8),
                    physics: const BouncingScrollPhysics(),
                    itemCount: products.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == products.length) return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()));
                      return _buildProductCard(products[index]);
                    },
                  ),
                ),
              ),
            ],
          ),
          if (showCart && cartItems.isNotEmpty && !showCheckout) Positioned(bottom: 0, left: 0, right: 0, child: _buildCartSummary()),
          if (showCheckout) Positioned.fill(child: Container(color: Colors.black54, child: Center(child: _buildCheckoutForm()))),
        ],
      ),
      floatingActionButton: cartItems.isNotEmpty && !showCart ? _buildCartFab() : null,
    );
  }
}
