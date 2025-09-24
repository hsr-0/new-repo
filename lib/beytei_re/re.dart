import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
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
const Duration API_TIMEOUT = Duration(seconds: 20);

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

  Future<bool> login(String username, String password) async {
    final authService = AuthService();
    _token = await authService.loginRestaurantOwner(username, password);
    if (_token != null) {
      await authService.registerDeviceToken();
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

// NEW: Provider for all customer-facing data (like PharmacyProvider)
class CustomerProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  Map<String, List<dynamic>> _homeData = {};
  List<Restaurant> _allRestaurants = [];
  Map<int, List<FoodItem>> _menuItems = {};

  bool _isLoadingHome = false;
  bool _isLoadingRestaurants = false;
  bool _isLoadingMenu = false;
  bool _hasError = false;

  Map<String, List<dynamic>> get homeData => _homeData;
  List<Restaurant> get allRestaurants => _allRestaurants;
  Map<int, List<FoodItem>> get menuItems => _menuItems;

  bool get isLoadingHome => _isLoadingHome;
  bool get isLoadingRestaurants => _isLoadingRestaurants;
  bool get isLoadingMenu => _isLoadingMenu;
  bool get hasError => _hasError;

  void clearData() {
    _homeData = {};
    _allRestaurants = [];
    _menuItems = {};
    notifyListeners();
  }

  Future<void> fetchHomeData(int areaId) async {
    _isLoadingHome = true;
    notifyListeners();
    try {
      final deliverableIds = await _apiService.getDeliverableRestaurantIds(areaId);
      final results = await Future.wait([
        _apiService.getAllRestaurants(),
        _apiService.getOnSaleItems(),
        _apiService.getProductsByTag("فطور"),
        _apiService.getProductsByTag("عائلي"),
      ]);

      _homeData['restaurants'] = _filterItems<Restaurant>(deliverableIds, results[0] as List<Restaurant>);
      _homeData['onSale'] = _filterItems<FoodItem>(deliverableIds, results[1] as List<FoodItem>);
      _homeData['breakfast'] = _filterItems<FoodItem>(deliverableIds, results[2] as List<FoodItem>);
      _homeData['family'] = _filterItems<FoodItem>(deliverableIds, results[3] as List<FoodItem>);

      _hasError = false;
    } catch (e) {
      _hasError = true;
    } finally {
      _isLoadingHome = false;
      notifyListeners();
    }
  }

  List<T> _filterItems<T>(Set<int> deliverableIds, List<T> items) {
    return items.where((item) {
      if (item is Restaurant) {
        item.isDeliverable = deliverableIds.contains(item.id);
        return item.isDeliverable;
      }
      if (item is FoodItem) {
        item.isDeliverable = deliverableIds.contains(item.categoryId);
        return item.isDeliverable;
      }
      return false;
    }).toList();
  }

  Future<void> fetchAllRestaurants(int areaId, {bool isRefresh = false}) async {
    if (isRefresh) _allRestaurants.clear();
    _isLoadingRestaurants = true;
    notifyListeners();
    try {
      final newRestaurants = await _apiService.getAllRestaurants(page: 1); // Simplified for now
      final deliverableIds = await _apiService.getDeliverableRestaurantIds(areaId);
      for (var r in newRestaurants) { r.isDeliverable = deliverableIds.contains(r.id); }
      _allRestaurants = newRestaurants;
      _hasError = false;
    } catch (e) {
      _hasError = true;
    } finally {
      _isLoadingRestaurants = false;
      notifyListeners();
    }
  }

  Future<void> fetchMenuForRestaurant(int restaurantId, {bool isRefresh = false}) async {
    if (isRefresh) _menuItems[restaurantId]?.clear();
    _isLoadingMenu = true;
    notifyListeners();
    try {
      final newItems = await _apiService.getMenuForRestaurant(restaurantId, page: 1); // Simplified
      _menuItems[restaurantId] = newItems;
      _hasError = false;
    } catch (e) {
      _hasError = true;
    } finally {
      _isLoadingMenu = false;
      notifyListeners();
    }
  }
}


class DashboardProvider with ChangeNotifier {
  Map<String, List<Order>> _orders = {};
  RestaurantRatingsDashboard? _ratingsDashboard;

  bool _isLoading = false;
  bool _hasNetworkError = false;
  String _errorMessage = '';

  Map<String, List<Order>> get orders => _orders;
  RestaurantRatingsDashboard? get ratingsDashboard => _ratingsDashboard;
  bool get isLoading => _isLoading;
  bool get hasNetworkError => _hasNetworkError;
  String get errorMessage => _errorMessage;

  void clearData() {
    _orders = {};
    _ratingsDashboard = null;
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

class Restaurant {
  final int id;
  final String name;
  final String imageUrl;
  bool isDeliverable;
  final double averageRating;
  final int ratingCount;

  Restaurant({required this.id, required this.name, required this.imageUrl, this.isDeliverable = false, this.averageRating = 0.0, this.ratingCount = 0});

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    double avgRating = 0.0;
    int rCount = 0;
    if (json['meta_data'] != null) {
      var ratingMeta = (json['meta_data'] as List).firstWhere((m) => m['key'] == '_wc_average_rating', orElse: () => null);
      if (ratingMeta != null) avgRating = double.tryParse(ratingMeta['value'].toString()) ?? 0.0;
      var countMeta = (json['meta_data'] as List).firstWhere((m) => m['key'] == '_wc_rating_count', orElse: () => null);
      if (countMeta != null) rCount = int.tryParse(countMeta['value'].toString()) ?? 0;
    }
    return Restaurant(
      id: json['id'], name: json['name'],
      imageUrl: json['image'] != null && json['image']['src'] != false ? json['image']['src'] : 'https://via.placeholder.com/300',
      averageRating: avgRating, ratingCount: rCount,
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

  FoodItem({required this.id, required this.name, required this.description, required this.price, this.salePrice, required this.imageUrl, this.quantity = 1, required this.categoryId, this.isDeliverable = false, this.averageRating = 0.0, this.ratingCount = 0});

  factory FoodItem.fromJson(Map<String, dynamic> json) => FoodItem(
    id: json['id'], name: json['name'],
    description: (json['short_description'] as String).replaceAll(RegExp(r'<[^>]*>'), ''),
    price: double.tryParse(json['regular_price']?.toString() ?? '0.0') ?? 0.0,
    salePrice: json['sale_price'] != '' && json['sale_price'] != null ? double.tryParse(json['sale_price'].toString()) : null,
    imageUrl: json['images'] != null && json['images'].isNotEmpty ? json['images'][0]['src'] : 'https://via.placeholder.com/150',
    categoryId: json['categories'] != null && json['categories'].isNotEmpty ? json['categories'][0]['id'] : 0,
    averageRating: double.tryParse(json['average_rating']?.toString() ?? '0.0') ?? 0.0,
    ratingCount: json['rating_count'] ?? 0,
  );

  double get displayPrice => salePrice ?? price;
  String get formattedPrice => '${NumberFormat('#,###', 'ar_IQ').format(displayPrice)} د.ع';
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

  Order({required this.id, required this.status, required this.dateCreated, required this.total, required this.customerName, required this.address, required this.phone, required this.lineItems});

  Map<String, dynamic> toJson() => {'id': id, 'status': status, 'date_created': dateCreated.toIso8601String(), 'total': total, 'customerName': customerName, 'address': address, 'phone': phone, 'line_items': lineItems.map((item) => item.toJson()).toList()};

  factory Order.fromJson(Map<String, dynamic> json) {
    final billing = json['billing'] as Map<String, dynamic>?;
    final shipping = json['shipping'] as Map<String, dynamic>?;
    return Order(
      id: json['id'], status: json['status'], dateCreated: DateTime.parse(json['date_created']), total: json['total'].toString(),
      customerName: json['customerName'] ?? '${billing?['first_name'] ?? ''} ${billing?['last_name'] ?? ''}'.trim(),
      address: json['address'] ?? shipping?['address_1'] ?? billing?['address_1'] ?? 'N/A',
      phone: json['phone'] ?? billing?['phone'] ?? 'N/A',
      lineItems: (json['line_items'] as List).map((i) => LineItem.fromJson(i)).toList(),
    );
  }

  Map<String, dynamic> get statusDisplay {
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

  Map<String, dynamic> toJson() => {'average_rating': averageRating, 'total_reviews': totalReviews, 'recent_reviews': recentReviews.map((r) => r.toJson()).toList()};

  factory RestaurantRatingsDashboard.fromJson(Map<String, dynamic> json) => RestaurantRatingsDashboard(
    averageRating: (json['average_rating'] as num).toDouble(),
    totalReviews: json['total_reviews'],
    recentReviews: (json['recent_reviews'] as List).map((i) => Review.fromJson(i)).toList(),
  );
}

class Review {
  final String productName;
  final String author;
  final int rating;
  final String content;
  final DateTime date;
  Review({required this.productName, required this.author, required this.rating, required this.content, required this.date});

  Map<String, dynamic> toJson() => {'product_name': productName, 'author': author, 'rating': rating, 'content': content, 'date': date.toIso8601String()};

  factory Review.fromJson(Map<String, dynamic> json) => Review(
    productName: json['product_name'], author: json['author'], rating: json['rating'], content: json['content'], date: DateTime.parse(json['date']),
  );
}

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

class CartProvider with ChangeNotifier {
  final List<FoodItem> _items = [];
  List<FoodItem> get items => _items;
  int get cartCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get totalPrice => _items.fold(0.0, (sum, item) => sum + (item.displayPrice * item.quantity));
  String? _appliedCoupon;
  double _discountPercentage = 0.0;
  double _discountAmount = 0.0;
  String _discountType = '';
  double get discountedTotal {
    if (_discountType == 'percent') return totalPrice * (1 - (_discountPercentage / 100));
    if (_discountType == 'fixed_cart') return (totalPrice - _discountAmount).clamp(0, double.infinity);
    return totalPrice;
  }
  String? get appliedCoupon => _appliedCoupon;

  Future<Map<String, dynamic>> applyCoupon(String code) async {
    final result = await ApiService().validateCoupon(code);
    if (result['valid'] == true) {
      _appliedCoupon = code.toUpperCase();
      _discountType = result['discount_type'];
      _discountAmount = double.tryParse(result['amount'].toString()) ?? 0.0;
      if (_discountType == 'percent') _discountPercentage = _discountAmount;
      notifyListeners();
    }
    return result;
  }

  void removeCoupon() {
    _appliedCoupon = null;
    _discountPercentage = 0.0;
    _discountAmount = 0.0;
    _discountType = '';
    notifyListeners();
  }

  void addToCart(FoodItem foodItem, BuildContext context) {
    final existingIndex = _items.indexWhere((item) => item.id == foodItem.id);
    if (existingIndex != -1) {
      _items[existingIndex].quantity++;
    } else {
      _items.add(FoodItem(id: foodItem.id, name: foodItem.name, description: foodItem.description, price: foodItem.price, salePrice: foodItem.salePrice, imageUrl: foodItem.imageUrl, quantity: 1, categoryId: foodItem.categoryId));
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

  Future<List<Restaurant>> getAllRestaurants({int page = 1}) async {
    const fields = 'id,name,image,count,meta_data';
    final url = '$BEYTEI_URL/wp-json/wc/v3/products/categories?parent=0&per_page=10&page=$page&_fields=$fields';
    final cacheKey = 'restaurants_page_$page';

    return _executeWithRetry(() async {
      final response = await http.get(Uri.parse(url), headers: {'Authorization': _authString});
      if (response.statusCode == 200) {
        await _cacheService.saveData(cacheKey, response.body);
        final data = json.decode(response.body) as List;
        return data.where((item) => item['count'] > 0).map((json) => Restaurant.fromJson(json)).toList();
      }
      throw Exception('Server error ${response.statusCode}');
    });
  }

  Future<Set<int>> getDeliverableRestaurantIds(int areaId) async {
    final url = '$BEYTEI_URL/wp-json/wc/v3/products/categories?parent=0&per_page=100&area=$areaId&_fields=id';
    return _executeWithRetry(() async {
      final response = await http.get(Uri.parse(url), headers: {'Authorization': _authString});
      if (response.statusCode == 200) {
        return (json.decode(response.body) as List).map<int>((item) => item['id']).toSet();
      }
      throw Exception('Failed to fetch deliverable restaurants');
    });
  }

  Future<List<FoodItem>> _getProducts(String params, String cacheKey) async {
    return _executeWithRetry(() async {
      const fields = 'id,name,regular_price,sale_price,images,categories,short_description,average_rating,rating_count';
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
  Future<List<FoodItem>> searchProducts(String query) => _getProducts('search=$query&per_page=20', 'search_$query');
  Future<List<FoodItem>> getMenuForRestaurant(int categoryId, {int page = 1}) => _getProducts('category=$categoryId&per_page=10&page=$page', 'menu_${categoryId}_page_$page');

  Future<List<FoodItem>> getProductsByTag(String tagName) async {
    return _executeWithRetry(() async {
      final tagsResponse = await http.get(Uri.parse('$BEYTEI_URL/wp-json/wc/v3/products/tags?search=$tagName&_fields=id'), headers: {'Authorization': _authString});
      if (tagsResponse.statusCode != 200) throw Exception('Failed to find tag');
      final tags = json.decode(tagsResponse.body);
      if (tags.isEmpty) return [];
      final tagId = tags[0]['id'];
      return _getProducts('tag=$tagId&per_page=10', 'tag_$tagId');
    });
  }

  Future<Order?> submitOrder({required String name, required String phone, required String address, required List<FoodItem> cartItems, String? couponCode}) async {
    List<Map<String, dynamic>> couponLines = couponCode != null && couponCode.isNotEmpty ? [{"code": couponCode}] : [];
    final body = json.encode({
      "payment_method": "cod", "payment_method_title": "الدفع عند الاستلام",
      "billing": {"first_name": name, "last_name":".", "phone": phone, "address_1": address, "country": "IQ", "city": "Default", "postcode":"10001", "email": "customer@example.com"},
      "shipping": {"first_name": name, "last_name":".", "address_1": address, "country": "IQ", "city": "Default", "postcode":"10001"},
      "line_items": cartItems.map((item) => {"product_id": item.id, "quantity": item.quantity}).toList(),
      "coupon_lines": couponLines,
    });

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

  Future<Map<String, dynamic>> createDeliveryRequest({
    required String token,
    required String pickupName,
    required String description,
    required double fee,
    required double lat,
    required double lng,
  }) async {
    return _executeWithRetry(() async {
      final response = await http.post(
        Uri.parse('$BEYTEI_URL/wp-json/taxi-app/v1/create-delivery-request'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'pickup_location_name': pickupName,
          'order_description': description,
          'delivery_fee': fee,
          'pickup_lat': lat,
          'pickup_lng': lng,
        }),
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 201) {
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

class FoodCard extends StatelessWidget {
  final FoodItem food;
  const FoodCard({super.key, required this.food});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    return GestureDetector(
        onTap: food.isDeliverable
            ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DetailScreen(foodItem: food)))
            : null,
        child: Opacity(
            opacity: food.isDeliverable ? 1.0 : 0.5,
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
                          if (!food.isDeliverable) Container(height: 140, width: double.infinity, decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(20)), child: const Center(child: Text('خارج التوصيل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))))
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
                                  icon: Icon(Icons.add_shopping_cart, color: food.isDeliverable ? Theme.of(context).primaryColor : Colors.grey),
                                  onPressed: food.isDeliverable ? () => cart.addToCart(food, context) : null),
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
    return GestureDetector(
        onTap: restaurant.isDeliverable
            ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MenuScreen(restaurant: restaurant)))
            : null,
        child: Opacity(
            opacity: restaurant.isDeliverable ? 1.0 : 0.5,
            child: Container(
                width: 100,
                margin: const EdgeInsets.only(left: 15),
                child: Column(children: [
                  Stack(alignment: Alignment.center, children: [
                    CircleAvatar(radius: 40, backgroundImage: CachedNetworkImageProvider(restaurant.imageUrl), backgroundColor: Colors.grey[200]),
                    if (!restaurant.isDeliverable) Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle), child: const Center(child: Text('خارج\nالتوصيل', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 12))))
                  ]),
                  const SizedBox(height: 8),
                  Text(restaurant.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))
                ]))));
  }
}

class RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  const RestaurantCard({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        onTap: restaurant.isDeliverable
            ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MenuScreen(restaurant: restaurant)))
            : null,
        child: Opacity(
          opacity: restaurant.isDeliverable ? 1.0 : 0.6,
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
                    if (!restaurant.isDeliverable)
                      Container(color: Colors.black.withOpacity(0.6), child: const Center(child: Text('خارج\nمنطقتك', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)))),
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
                          onPressed: restaurant.isDeliverable ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MenuScreen(restaurant: restaurant))) : null,
                          icon: const Icon(Icons.menu_book, size: 14),
                          label: const Text(' عرض المنيو', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white,
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
  const OrderCard({super.key, required this.order, required this.onStatusChanged, this.isCompleted = false});
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

  void _showDeliveryRequestDialog(BuildContext context, Order order) {
    final feeController = TextEditingController();
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final orderDetails = order.lineItems.map((item) => '${item.quantity} x ${item.name}').join('\n');
    notesController.text = 'توصيل طلب المطعم رقم #${order.id}\n'
        'المحتويات:\n$orderDetails\n'
        'الزبون: ${order.customerName}\n'
        'العنوان: ${order.address}';

    showDialog(
      context: context,
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
                    children: [
                      TextFormField(
                        controller: feeController,
                        enabled: !isSubmitting,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'أجرة التوصيل',
                          hintText: 'مثال: 3000',
                          suffixText: 'د.ع',
                        ),
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
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'وصف الطلب / ملاحظات للسائق',
                          border: OutlineInputBorder(),
                        ),
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
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      try {
                        // TODO: Replace with actual restaurant coordinates from user profile
                        const double restaurantLat = 32.5029; // Placeholder
                        const double restaurantLng = 45.8329; // Placeholder

                        // TODO: Replace with actual restaurant name from user profile
                        const restaurantName = "اسم المطعم/الصيدلية";

                        final result = await _apiService.createDeliveryRequest(
                          token: authProvider.token!,
                          pickupName: restaurantName,
                          description: notesController.text,
                          fee: double.parse(feeController.text),
                          lat: restaurantLat,
                          lng: restaurantLng,
                        );

                        if (mounted) {
                          await _updateStatus('out-for-delivery');
                          Navigator.of(dialogContext).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result['message'] ?? 'تم إرسال طلب التوصيل بنجاح!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('خطأ: ${e.toString()}'),
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
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
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
                const SizedBox(height: 12),
                _buildInfoRow(Icons.phone_outlined, 'الهاتف:', widget.order.phone),
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

class OrderHistoryCard extends StatelessWidget {
  final Order order;
  const OrderHistoryCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('yyyy-MM-dd – hh:mm a', 'ar');
    final formattedDate = formatter.format(order.dateCreated.toLocal());
    final totalFormatted = NumberFormat('#,###', 'ar_IQ').format(double.tryParse(order.total) ?? 0);
    final statusInfo = order.statusDisplay;

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
        Provider.of<DashboardProvider>(context, listen: false).fetchDashboardData(authProvider.token);
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
        ChangeNotifierProxyProvider<AuthProvider, DashboardProvider>(
          create: (_) => DashboardProvider(),
          update: (_, auth, dashboard) {
            if(auth.isLoggedIn && dashboard != null && dashboard.orders.isEmpty) {
              dashboard.fetchDashboardData(auth.token);
            }
            return dashboard!;
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
            return NetworkErrorWidget(message: 'فشل تحميل البيانات.', onRetry: () => provider.fetchHomeData(_selectedAreaId!));
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

class MenuScreen extends StatefulWidget {
  final Restaurant restaurant;
  const MenuScreen({super.key, required this.restaurant});
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
                item.isDeliverable = true;
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
      _searchFuture = _apiService.searchProducts(widget.searchQuery).then((allResults) async {
        final deliverableIds = await _apiService.getDeliverableRestaurantIds(widget.selectedAreaId);
        return allResults.where((item) {
          item.isDeliverable = deliverableIds.contains(item.categoryId);
          return item.isDeliverable;
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
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
          label: const Text("إضافة إلى السلة", style: TextStyle(color: Colors.white, fontSize: 18)),
          onPressed: () => Provider.of<CartProvider>(context, listen: false).addToCart(foodItem, context),
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), backgroundColor: Theme.of(context).primaryColor),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('سلة التسوق')),
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

  void _showCheckoutDialog(BuildContext context, CartProvider cart) {
    _nameController.clear();
    _phoneController.clear();
    _addressController.clear();
    _couponController.text = cart.appliedCoupon ?? '';
    bool isSubmitting = false;

    showDialog(context: context, barrierDismissible: !isSubmitting, builder: (dialogContext) {
      return StatefulBuilder(builder: (context, setDialogState) {
        return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: const Text('إتمام الطلب'),
            content: Form(key: _formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'الاسم الكامل'), validator: (v) => v!.isEmpty ? 'الرجاء إدخال الاسم' : null, enabled: !isSubmitting),
              const SizedBox(height: 15),
              TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: 'رقم الهاتف'), keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'الرجاء إدخال رقم الهاتف' : null, enabled: !isSubmitting),
              const SizedBox(height: 15),
              TextFormField(controller: _addressController, decoration: const InputDecoration(labelText: 'العنوان بالتفصيل'), maxLines: 2, validator: (v) => v!.isEmpty ? 'الرجاء إدخال العنوان' : null, enabled: !isSubmitting),
              const SizedBox(height: 15),
              TextFormField(controller: _couponController, decoration: InputDecoration(labelText: 'كود الخصم (إن وجد)', suffixIcon: TextButton(child: const Text("تطبيق"), onPressed: () async {
                final result = await cart.applyCoupon(_couponController.text);
                if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']), backgroundColor: result['valid'] ? Colors.green : Colors.red));
                setDialogState(() {});
              }))),
            ]))),
            actions: <Widget>[
              TextButton(onPressed: isSubmitting ? null : () => Navigator.of(dialogContext).pop(), child: const Text('إلغاء')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
                onPressed: isSubmitting ? null : () async {
                  if (!_formKey.currentState!.validate()) return;
                  setDialogState(() => isSubmitting = true);
                  try {
                    await _apiService.submitOrder(name: _nameController.text, phone: _phoneController.text, address: _addressController.text, cartItems: cart.items, couponCode: cart.appliedCoupon);
                    if (!mounted) return;
                    Navigator.of(dialogContext).pop();
                    cart.clearCart();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال طلبك إلى المطعم بنجاح، انتظر اتصال المندوب'), duration: Duration(seconds: 5)));
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في إرسال الطلب: ${e.toString()}')));
                  } finally {
                    if (mounted) setDialogState(() => isSubmitting = false);
                  }
                },
                child: isSubmitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0)) : const Text('تأكيد الطلب'),
              )
            ]
        );
      });
    });
  }

  Widget _buildCartItemCard(BuildContext context, CartProvider cart, FoodItem item) {
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

class _RestaurantLoginScreenState extends State<RestaurantLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(_usernameController.text, _passwordController.text);
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
              const SizedBox(height: 40),
              _isLoading ? const CircularProgressIndicator() : ElevatedButton( onPressed: _login, style: ElevatedButton.styleFrom( minimumSize: const Size(double.infinity, 50), textStyle: const TextStyle(fontSize: 18)), child: const Text('تسجيل الدخول'))
            ]),
          ),
        ),
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
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        bottom: TabBar(controller: _tabController, tabs: const [Tab(icon: Icon(Icons.list_alt), text: 'الطلبات'), Tab(icon: Icon(Icons.history), text: 'المكتملة'), Tab(icon: Icon(Icons.star_rate), text: 'التقييمات')]),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          OrdersListScreen(status: 'active'), OrdersListScreen(status: 'completed'), const RatingsDashboardScreen(),
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

        return RefreshIndicator(
          onRefresh: () => dashboard.fetchDashboardData(authProvider.token),
          child: orders.isEmpty
              ? Center(child: ListView(physics: const AlwaysScrollableScrollPhysics(), children: [SizedBox(height: MediaQuery.of(context).size.height * 0.2), Text('لا توجد طلبات في هذا القسم حالياً', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.grey.shade600)), const SizedBox(height: 10), const Icon(Icons.inbox_outlined, size: 50, color: Colors.grey)]))
              : ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: orders.length,
            itemBuilder: (context, index) => OrderCard(order: orders[index], onStatusChanged: () => dashboard.fetchDashboardData(authProvider.token), isCompleted: widget.status != 'active'),
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

