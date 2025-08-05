import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart'; // **مهم:** إضافة المكتبة الجديدة

// =============================================================================
//  -- وحدة المطاعم المتكاملة (Restaurant Module) --
//  -- نسخة نهائية: متوافقة مع GoRouter + إصلاح الإشعارات + إدارة التوكن --
// =============================================================================

// --- إعدادات وثوابت عامة للوحدة ---
const String BEYTEI_URL = 'https://re.beytei.com';
const String CONSUMER_KEY = 'ck_d22c789681c4610838f1d39a05dbedcb73a2c810';
const String CONSUMER_SECRET = 'cs_78b90e397bbc2a8f5f5092cca36dc86e55c01c07';

/// **مهم جداً:** هذه الدالة يجب أن تكون خارج أي كلاس (Top-level function).
/// هي المسؤولة عن التعامل مع الإشعارات عندما يكون التطبيق في الخلفية أو مغلق.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // يجب تهيئة Firebase هنا أيضاً لضمان عملها في الخلفية
  await Firebase.initializeApp();
  print("==== BACKGROUND NOTIFICATION RECEIVED ====");
  print("Title: ${message.notification?.title}");
  print("Body: ${message.notification?.body}");
  print("Data: ${message.data}");
  print("========================================");
}

// --- تعريف المسارات داخل الوحدة ---
Route<dynamic> _onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/main':
      return MaterialPageRoute(builder: (_) => MainScreen(key: MainScreen.navKey));
    case '/details':
      final foodItem = settings.arguments as FoodItem;
      return MaterialPageRoute(builder: (_) => DetailScreen(foodItem: foodItem));
    case '/menu':
      final restaurant = settings.arguments as Restaurant;
      return MaterialPageRoute(builder: (_) => MenuScreen(restaurant: restaurant));
    case '/search':
      final args = settings.arguments as Map<String, dynamic>;
      return MaterialPageRoute(
        builder: (_) => SearchScreen(
          searchQuery: args['query'],
          selectedAreaId: args['areaId'],
        ),
      );
    case '/login':
      return MaterialPageRoute(builder: (_) => const RestaurantLoginScreen());
    case '/dashboard':
      return MaterialPageRoute(builder: (_) => const RestaurantDashboardScreen());
    case '/':
    default:
      return MaterialPageRoute(builder: (_) => const SplashScreen());
  }
}

/// هذا هو الودجت الذي يجب استدعاؤه من "منصة بيتي" الرئيسية.
class RestaurantModule extends StatelessWidget {
  const RestaurantModule({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CartProvider(),
      // استخدام Navigator مستقل للوحدة لعزل الملاحة عن GoRouter
      child: Navigator(
        initialRoute: '/',
        onGenerateRoute: _onGenerateRoute,
      ),
    );
  }
}

// --- النماذج (Models) ---
class Area {
  final int id;
  final String name;
  final int parentId;
  Area({required this.id, required this.name, required this.parentId});
  factory Area.fromJson(Map<String, dynamic> json) {
    return Area(id: json['id'], name: json['name'], parentId: json['parent']);
  }
}

class Restaurant {
  final int id;
  final String name;
  final String imageUrl;
  bool isDeliverable;
  Restaurant({required this.id, required this.name, required this.imageUrl, this.isDeliverable = false});
  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(id: json['id'], name: json['name'], imageUrl: json['image'] != null && json['image']['src'] != false ? json['image']['src'] : 'https://via.placeholder.com/300');
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
  FoodItem({required this.id, required this.name, required this.description, required this.price, this.salePrice, required this.imageUrl, this.quantity = 1, required this.categoryId, this.isDeliverable = false});
  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(id: json['id'], name: json['name'], description: (json['short_description'] as String).replaceAll(RegExp(r'<[^>]*>'), ''), price: double.tryParse(json['regular_price']?.toString() ?? '0.0') ?? 0.0, salePrice: json['sale_price'] != '' && json['sale_price'] != null ? double.tryParse(json['sale_price'].toString()) : null, imageUrl: json['images'] != null && json['images'].isNotEmpty ? json['images'][0]['src'] : 'https://via.placeholder.com/150', categoryId: json['categories'] != null && json['categories'].isNotEmpty ? json['categories'][0]['id'] : 0);
  }
  double get displayPrice => salePrice ?? price;
  String get formattedPrice {
    final formatter = NumberFormat('#,###', 'ar_IQ');
    return '${formatter.format(displayPrice)} د.ع';
  }
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

  Order({
    required this.id,
    required this.status,
    required this.dateCreated,
    required this.total,
    required this.customerName,
    required this.address,
    required this.phone,
    required this.lineItems,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    var itemsFromJson = json['line_items'] as List;
    List<LineItem> lineItemsList = itemsFromJson.map((i) => LineItem.fromJson(i)).toList();

    return Order(
      id: json['id'],
      status: json['status'],
      dateCreated: DateTime.parse(json['date_created']),
      total: json['total'].toString(),
      customerName: json['customer_name'],
      address: json['address'],
      phone: json['phone'],
      lineItems: lineItemsList,
    );
  }
}

class LineItem {
  final String name;
  final int quantity;
  final String total;

  LineItem({required this.name, required this.quantity, required this.total});

  factory LineItem.fromJson(Map<String, dynamic> json) {
    return LineItem(
      name: json['name'],
      quantity: json['quantity'],
      total: json['total'].toString(),
    );
  }
}


// --- الخدمات (Services) ---
class CartProvider with ChangeNotifier {
  final List<FoodItem> _items = [];
  List<FoodItem> get items => _items;
  int get cartCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get totalPrice => _items.fold(0.0, (sum, item) => sum + (item.displayPrice * item.quantity));

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
    notifyListeners();
  }

  void _showAddToCartDialog(BuildContext context, FoodItem item) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("تمت الإضافة إلى السلة"), content: Text("تمت إضافة '${item.name}' بنجاح."), actions: [TextButton(child: const Text("مواصلة التسوق"), onPressed: () => Navigator.of(ctx).pop()), ElevatedButton(child: const Text("الذهاب للسلة"), onPressed: () {
      Navigator.of(ctx).pop();
      MainScreen.navKey.currentState?.onItemTapped(2);
    })]));
  }
}

class ApiService {
  final String _authString = 'Basic ${base64Encode(utf8.encode('$CONSUMER_KEY:$CONSUMER_SECRET'))}';

  Future<List<Area>> getAreas() async {
    final response = await http.get(Uri.parse('$BEYTEI_URL/wp-json/wp/v2/area?per_page=100'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Area.fromJson(json)).toList();
    } else {
      throw Exception('فشل في جلب المناطق');
    }
  }

  Future<List<Restaurant>> getAllRestaurants() async {
    final response = await http.get(Uri.parse('$BEYTEI_URL/wp-json/wc/v3/products/categories?parent=0&per_page=100'), headers: {'Authorization': _authString});
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.where((item) => item['count'] > 0).map((json) => Restaurant.fromJson(json)).toList();
    } else {
      throw Exception('فشل في جلب جميع المطاعم');
    }
  }

  Future<Set<int>> getDeliverableRestaurantIds(int areaId) async {
    final response = await http.get(Uri.parse('$BEYTEI_URL/wp-json/wc/v3/products/categories?parent=0&per_page=100&area=$areaId'), headers: {'Authorization': _authString});
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map<int>((item) => item['id']).toSet();
    } else {
      throw Exception('فشل في جلب المطاعم للمنطقة المحددة');
    }
  }

  Future<List<FoodItem>> getOnSaleItems() async {
    final response = await http.get(Uri.parse('$BEYTEI_URL/wp-json/wc/v3/products?on_sale=true&per_page=20'), headers: {'Authorization': _authString});
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => FoodItem.fromJson(json)).toList();
    } else {
      throw Exception('فشل في جلب العروض');
    }
  }

  Future<List<FoodItem>> getProductsByTag(String tagName) async {
    final tagsResponse = await http.get(Uri.parse('$BEYTEI_URL/wp-json/wc/v3/products/tags?search=$tagName'), headers: {'Authorization': _authString});
    if (tagsResponse.statusCode != 200) throw Exception('فشل في البحث عن الوسم: $tagName');
    final tags = json.decode(tagsResponse.body);
    if (tags.isEmpty) return [];
    final tagId = tags[0]['id'];
    final productsResponse = await http.get(Uri.parse('$BEYTEI_URL/wp-json/wc/v3/products?tag=$tagId&per_page=10'), headers: {'Authorization': _authString});
    if (productsResponse.statusCode == 200) {
      List<dynamic> data = json.decode(productsResponse.body);
      return data.map((json) => FoodItem.fromJson(json)).toList();
    } else {
      throw Exception('فشل في جلب المنتجات حسب الوسم');
    }
  }

  Future<List<FoodItem>> searchProducts(String query) async {
    final response = await http.get(Uri.parse('$BEYTEI_URL/wp-json/wc/v3/products?search=$query&per_page=20'), headers: {'Authorization': _authString});
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => FoodItem.fromJson(json)).toList();
    } else {
      throw Exception('فشل في البحث عن المنتجات');
    }
  }

  Future<List<FoodItem>> getMenuForRestaurant(int categoryId) async {
    final response = await http.get(Uri.parse('$BEYTEI_URL/wp-json/wc/v3/products?category=$categoryId&per_page=100'), headers: {'Authorization': _authString});
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => FoodItem.fromJson(json)).toList();
    } else {
      throw Exception('فشل في جلب قائمة الطعام');
    }
  }

  Future<void> submitOrder({required String name, required String phone, required String address, required List<FoodItem> cartItems}) async {
    final body = json.encode({
      "status": "processing",
      "payment_method": "cod",
      "payment_method_title": "الدفع عند الاستلام",
      "billing": {"first_name": name, "phone": phone},
      "shipping": {"address_1": address},
      "line_items": cartItems.map((item) => {"product_id": item.id, "quantity": item.quantity}).toList()
    });

    final response = await http.post(
        Uri.parse('$BEYTEI_URL/wp-json/wc/v3/orders'),
        headers: {
          'Authorization': _authString,
          'Content-Type': 'application/json'
        },
        body: body
    );

    if (response.statusCode != 201) {
      throw Exception('فشل إرسال الطلب: ${response.body}');
    }
  }

  Future<List<Order>> getRestaurantOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) {
      throw Exception('User not logged in');
    }

    final response = await http.get(
      Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/get-orders'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Order.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load orders: ${response.body}');
    }
  }

  // **جديد:** دالة لتحديث حالة الطلب
  Future<bool> updateOrderStatus(int orderId, String status) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) {
      throw Exception('User not logged in');
    }

    final response = await http.post(
      Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/update-order-status/$orderId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'status': status}),
    );

    return response.statusCode == 200;
  }
}

class AuthService {
  Future<String?> loginRestaurantOwner(String username, String password) async {
    try {
      final response = await http.post(Uri.parse('$BEYTEI_URL/wp-json/jwt-auth/v1/token'), headers: {'Content-Type': 'application/json'}, body: json.encode({'username': username, 'password': password}));
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
    } catch (e) {
      print("[AUTH_SERVICE] Login Error: $e");
      return null;
    }
  }

  Future<void> registerDeviceToken() async {
    print("[AUTH_SERVICE] ==> Attempting to register device token...");
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) {
      print("[AUTH_SERVICE] ==> JWT token is null. Aborting.");
      return;
    }

    String? fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken == null) {
      print("[AUTH_SERVICE] ==> FCM token is null. Aborting.");
      return;
    }
    print("[AUTH_SERVICE] ==> ✅ FCM Token found: $fcmToken");

    try {
      final response = await http.post(
        Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/register-device'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'token': fcmToken}),
      );
      print("[AUTH_SERVICE] ==> Register Device API Response Status: ${response.statusCode}");
      print("[AUTH_SERVICE] ==> Register Device API Response Body: ${response.body}");
      if (response.statusCode == 200) {
        print("[AUTH_SERVICE] ==> ✅ SUCCESS: Device token registered successfully!");
      } else {
        print("[AUTH_SERVICE] ==> ❌ FAILED: Failed to register device token.");
      }
    } catch (e) {
      print("[AUTH_SERVICE] ==> ❌ An error occurred while registering device token: $e");
    }
  }

  Future<void> logout() async {
    print("[AUTH_SERVICE] ==> Attempting to unregister device token on logout...");
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token');

    if (jwtToken != null) {
      try {
        final response = await http.post(
          Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/unregister-device'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $jwtToken',
          },
        );
        print("[AUTH_SERVICE] ==> Unregister Device API Response Status: ${response.statusCode}");
      } catch (e) {
        print("[AUTH_SERVICE] ==> ❌ Failed to unregister device on logout: $e");
      }
    }

    await FirebaseMessaging.instance.deleteToken();
    print("[AUTH_SERVICE] ==> Local FCM token deleted.");

    await prefs.remove('jwt_token');
    print("[AUTH_SERVICE] ==> Local JWT token removed. Logout complete.");
  }
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static final AudioPlayer _audioPlayer = AudioPlayer();

  static Future<void> initialize() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel('new_orders_channel', 'طلبات جديدة', description: 'إشعارات للطلبات الجديدة في المطعم.', importance: Importance.max, playSound: true, enableVibration: true, sound: RawResourceAndroidNotificationSound('woo_sound'));
    await _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);
  }

  static Future<void> display(RemoteMessage message) async {
    print("==== FOREGROUND NOTIFICATION WILL BE DISPLAYED ====");
    print("Title: ${message.notification?.title}");
    print("Body: ${message.notification?.body}");
    print("Data: ${message.data}");
    print("===============================================");

    try {
      await _audioPlayer.play(AssetSource('sounds/woo_sound.mp3'));
    } catch (e) {
      print("[NOTIFICATION_SERVICE] Error playing sound: $e");
    }

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _localNotifications.show(id, message.notification?.title ?? 'No Title', message.notification?.body ?? 'No Body', const NotificationDetails(android: AndroidNotificationDetails('new_orders_channel', 'طلبات جديدة', importance: Importance.max, priority: Priority.high), iOS: DarwinNotificationDetails(sound: 'woo_sound.caf', presentSound: true)), payload: message.data['order_id']);
  }
}

// --- الشاشات (Screens) ---
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/main');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              const Color(0xFF00897B),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.food_bank_rounded, size: 120, color: Colors.white),
              SizedBox(height: 20),
              Text(
                "مطاعم بيتي",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "أشهى المأكولات تصلك أينما كنت",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  static final GlobalKey<_MainScreenState> navKey = GlobalKey<_MainScreenState>();
  const MainScreen({required Key key}) : super(key: key);
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  int? _selectedAreaId;
  String _selectedAreaName = "";
  List<Widget> _widgetOptions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkLocationAndBuildScreens();
    _setupTokenRefreshListener();
  }

  void _setupTokenRefreshListener() {
    FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) {
      print("[TOKEN_REFRESH] ==> FCM Token was refreshed: $fcmToken");
      print("[TOKEN_REFRESH] ==> Re-registering the new token with the server...");
      AuthService().registerDeviceToken();
    }).onError((err) {
      print("[TOKEN_REFRESH] ==> Error listening to token refresh: $err");
    });
  }

  Future<void> _checkLocationAndBuildScreens() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedAreaId = prefs.getInt('selectedAreaId');
    _selectedAreaName = prefs.getString('selectedAreaName') ?? "";
    if (_selectedAreaId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showLocationDialog(isCancellable: false);
      });
    } else {
      _buildScreens();
    }
  }

  void _buildScreens() {
    if (_selectedAreaId == null) return;
    setState(() {
      _widgetOptions = <Widget>[
        HomeScreen(selectedAreaId: _selectedAreaId!, selectedAreaName: _selectedAreaName, onChangeLocation: () => _showLocationDialog(isCancellable: true)),
        RestaurantsScreen(selectedAreaId: _selectedAreaId!),
        const CartScreen()
      ];
      _isLoading = false;
    });
  }

  Future<void> _showLocationDialog({required bool isCancellable}) async {
    final result = await showDialog<bool>(context: context, barrierDismissible: isCancellable, builder: (context) => SelectLocationDialog(isCancellable: isCancellable));
    if (!mounted) return;
    if (result == true) {
      setState(() {
        _isLoading = true;
      });
      await _checkLocationAndBuildScreens();
    } else if (!isCancellable && _selectedAreaId == null) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  void onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: _isLoading ? null : _buildCustomBottomNav(),
    );
  }

  Widget _buildCustomBottomNav() {
    return Container(padding: const EdgeInsets.symmetric(vertical: 12.0), decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 10)]), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_buildNavItem(icon: Icons.other_houses_outlined, activeIcon: Icons.other_houses_rounded, label: 'الرئيسية', index: 0), _buildNavItem(icon: Icons.store_outlined, activeIcon: Icons.store, label: 'المطاعم', index: 1), _buildNavItem(icon: Icons.shopping_cart_outlined, activeIcon: Icons.shopping_cart, label: 'السلة', index: 2)]));
  }

  Widget _buildNavItem({required IconData icon, required IconData activeIcon, required String label, required int index}) {
    final bool isSelected = _selectedIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => onItemTapped(index),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (index == 2)
            Consumer<CartProvider>(builder: (context, cart, child) {
              return Stack(clipBehavior: Clip.none, children: [
                _buildIconContainer(isSelected, activeIcon, icon),
                if (cart.cartCount > 0)
                  Positioned(top: -4, right: -4, child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondary, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1)), child: Text(cart.cartCount.toString(), style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 10, fontWeight: FontWeight.bold))))
              ]);
            })
          else
            _buildIconContainer(isSelected, activeIcon, icon),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey))
        ]),
      ),
    );
  }

  Widget _buildIconContainer(bool isSelected, IconData activeIcon, IconData icon) {
    return Container(width: 40, height: 40, decoration: BoxDecoration(color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.transparent, shape: BoxShape.circle), child: Icon(isSelected ? activeIcon : icon, color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade600, size: 22));
  }
}

class RestaurantsScreen extends StatefulWidget {
  final int selectedAreaId;
  const RestaurantsScreen({super.key, required this.selectedAreaId});
  @override
  State<RestaurantsScreen> createState() => _RestaurantsScreenState();
}

class _RestaurantsScreenState extends State<RestaurantsScreen> {
  Future<List<Restaurant>>? _restaurantsFuture;
  final ApiService _apiService = ApiService();
  @override
  void initState() {
    super.initState();
    _loadAndClassifyRestaurants();
  }
  @override
  void didUpdateWidget(covariant RestaurantsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedAreaId != oldWidget.selectedAreaId) {
      _loadAndClassifyRestaurants();
    }
  }
  void _loadAndClassifyRestaurants() {
    setState(() {
      _restaurantsFuture = _fetchRestaurants();
    });
  }
  Future<List<Restaurant>> _fetchRestaurants() async {
    final deliverableIds = await _apiService.getDeliverableRestaurantIds(widget.selectedAreaId);
    final allRestaurants = await _apiService.getAllRestaurants();
    for (var restaurant in allRestaurants) {
      restaurant.isDeliverable = deliverableIds.contains(restaurant.id);
    }
    allRestaurants.sort((a, b) {
      if (a.isDeliverable && !b.isDeliverable) return -1;
      if (!a.isDeliverable && b.isDeliverable) return 1;
      return a.name.compareTo(b.name);
    });
    return allRestaurants;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المطاعم')),
      body: FutureBuilder<List<Restaurant>>(
        future: _restaurantsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return GridView.builder(padding: const EdgeInsets.all(15), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 0.9), itemCount: 6, itemBuilder: (context, index) => const ShimmerRestaurantCard());
          }
          if (snapshot.hasError) return Center(child: Text("خطأ: ${snapshot.error}"));
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("لا توجد مطاعم متاحة حالياً"));
          }
          final restaurants = snapshot.data!;
          return GridView.builder(padding: const EdgeInsets.all(15), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 0.9), itemCount: restaurants.length, itemBuilder: (context, index) => RestaurantCard(restaurant: restaurants[index]));
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
  late Future<List<FoodItem>> _menuFuture;
  final ApiService _apiService = ApiService();
  @override
  void initState() {
    super.initState();
    _menuFuture = _apiService.getMenuForRestaurant(widget.restaurant.id);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.restaurant.name)),
      body: FutureBuilder<List<FoodItem>>(
        future: _menuFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return GridView.builder(padding: const EdgeInsets.all(15), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 0.75), itemCount: 8, itemBuilder: (context, index) => const ShimmerFoodCard());
          }
          if (snapshot.hasError) return Center(child: Text("خطأ: ${snapshot.error}"));
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("لا توجد وجبات في هذا المطعم حالياً"));
          }
          final menu = snapshot.data!;
          // All items in a restaurant's menu are considered deliverable if the restaurant itself is.
          for (var item in menu) {
            item.isDeliverable = true;
          }
          return GridView.builder(padding: const EdgeInsets.all(15), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 0.75), itemCount: menu.length, itemBuilder: (context, index) => FoodCard(food: menu[index]));
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
    _searchFuture = _loadAndFilterSearch();
  }
  Future<List<FoodItem>> _loadAndFilterSearch() async {
    final deliverableIds = await _apiService.getDeliverableRestaurantIds(widget.selectedAreaId);
    final allResults = await _apiService.searchProducts(widget.searchQuery);
    final filteredResults = allResults.where((item) {
      final isDeliverable = deliverableIds.contains(item.categoryId);
      item.isDeliverable = isDeliverable;
      return isDeliverable;
    }).toList();
    return filteredResults;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('نتائج البحث عن: "${widget.searchQuery}"')),
      body: FutureBuilder<List<FoodItem>>(
        future: _searchFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return GridView.builder(padding: const EdgeInsets.all(15), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 0.75), itemCount: 8, itemBuilder: (context, index) => const ShimmerFoodCard());
          }
          if (snapshot.hasError) return Center(child: Text("خطأ: ${snapshot.error}"));
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("لم يتم العثور على نتائج لبحثك في منطقتك"));
          }
          final results = snapshot.data!;
          return GridView.builder(padding: const EdgeInsets.all(15), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 0.75), itemCount: results.length, itemBuilder: (context, index) => FoodCard(food: results[index]));
        },
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final int selectedAreaId;
  final String selectedAreaName;
  final VoidCallback onChangeLocation;
  const HomeScreen({super.key, required this.selectedAreaId, required this.selectedAreaName, required this.onChangeLocation});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  Future<Map<String, List<dynamic>>>? _pageData;
  final TextEditingController _searchController = TextEditingController();
  final List<String> bannerImages = ['https://beytei.com/wp-content/uploads/2023/05/banner1.jpg', 'https://beytei.com/wp-content/uploads/2023/05/banner2.jpg', 'https://beytei.com/wp-content/uploads/2023/05/banner3.jpg'];
  @override
  void initState() {
    super.initState();
    _loadAllData();
  }
  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedAreaId != oldWidget.selectedAreaId) {
      _loadAllData();
    }
  }
  void _loadAllData() {
    setState(() {
      _pageData = _fetchPageData();
    });
  }
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  Future<Map<String, List<dynamic>>> _fetchPageData() async {
    try {
      final deliverableRestaurantIds = await _apiService.getDeliverableRestaurantIds(widget.selectedAreaId);
      final results = await Future.wait([_apiService.getAllRestaurants(), _apiService.getProductsByTag("فطور"), _apiService.getProductsByTag("عائلي"), _apiService.getOnSaleItems()]);
      final List<Restaurant> allRestaurants = (results[0] as List<Restaurant>)..forEach((r) => r.isDeliverable = deliverableRestaurantIds.contains(r.id));
      final List<FoodItem> breakfast = (results[1] as List<FoodItem>)..forEach((i) => i.isDeliverable = deliverableRestaurantIds.contains(i.categoryId));
      final List<FoodItem> familyMeals = (results[2] as List<FoodItem>)..forEach((i) => i.isDeliverable = deliverableRestaurantIds.contains(i.categoryId));
      final List<FoodItem> onSale = (results[3] as List<FoodItem>)..forEach((i) => i.isDeliverable = deliverableRestaurantIds.contains(i.categoryId));
      return {"restaurants": allRestaurants, "breakfast": breakfast, "family_meals": familyMeals, "on_sale": onSale};
    } catch (e) {
      throw Exception('فشل في تحميل البيانات: $e');
    }
  }

  void _onSearchSubmitted(String query) {
    if (query.isNotEmpty) {
      Navigator.of(context).pushNamed(
        '/search',
        arguments: {'query': query, 'areaId': widget.selectedAreaId},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: InkWell(
              onTap: widget.onChangeLocation,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(widget.selectedAreaName, style: const TextStyle(fontSize: 16)),
                const Icon(Icons.keyboard_arrow_down, size: 20)
              ])),
          centerTitle: true,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: "العودة إلى المنصة الرئيسية",
              onPressed: () {
                Navigator.of(context).maybePop();
              }),
        ),
        body: RefreshIndicator(
            onRefresh: () async => _loadAllData(),
            child: FutureBuilder<Map<String, List<dynamic>>>(
                future: _pageData,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const ShimmerHomeScreen();
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('لا توجد بيانات'));
                  }
                  final restaurants = snapshot.data!['restaurants'] as List<Restaurant>;
                  final breakfastFoods = snapshot.data!['breakfast'] as List<FoodItem>;
                  final familyFoods = snapshot.data!['family_meals'] as List<FoodItem>;
                  final onSaleFoods = snapshot.data!['on_sale'] as List<FoodItem>;
                  return ListView(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      children: [
                        Padding(padding: const EdgeInsets.symmetric(horizontal: 20.0), child: _buildSearchBar()),
                        const SizedBox(height: 20),
                        _buildBannerSlider(),
                        const SizedBox(height: 20),
                        if (restaurants.isNotEmpty) ...[Padding(padding: const EdgeInsets.symmetric(horizontal: 20.0), child: _buildSectionTitle('المطاعم', () => MainScreen.navKey.currentState?.onItemTapped(1))), const SizedBox(height: 10), _buildRestaurantsList(restaurants), const SizedBox(height: 20)],
                        if (onSaleFoods.isNotEmpty) ...[Padding(padding: const EdgeInsets.symmetric(horizontal: 20.0), child: _buildSectionTitle('عروض وخصومات', () {})), const SizedBox(height: 10), _buildFoodsList(onSaleFoods), const SizedBox(height: 20)],
                        if (breakfastFoods.isNotEmpty) ...[Padding(padding: const EdgeInsets.symmetric(horizontal: 20.0), child: _buildSectionTitle('الفطور', () {})), const SizedBox(height: 10), _buildFoodsList(breakfastFoods), const SizedBox(height: 20)],
                        if (familyFoods.isNotEmpty) ...[Padding(padding: const EdgeInsets.symmetric(horizontal: 20.0), child: _buildSectionTitle('وجبات عائلية', () {})), const SizedBox(height: 10), _buildFoodsList(familyFoods), const SizedBox(height: 20)]
                      ]
                  );
                }
            )
        )
    );
  }
  Widget _buildBannerSlider() {
    return CarouselSlider(options: CarouselOptions(height: 150.0, autoPlay: true, enlargeCenterPage: true, aspectRatio: 16 / 9, viewportFraction: 0.9), items: bannerImages.map((i) {
      return Builder(builder: (BuildContext context) {
        return Container(width: MediaQuery.of(context).size.width, margin: const EdgeInsets.symmetric(horizontal: 5.0), decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), image: DecorationImage(image: CachedNetworkImageProvider(i), fit: BoxFit.cover)));
      });
    }).toList());
  }
  Widget _buildSearchBar() {
    return TextField(controller: _searchController, textInputAction: TextInputAction.search, onSubmitted: _onSearchSubmitted, decoration: const InputDecoration(hintText: 'ابحث عن وجبة أو مطعم...', prefixIcon: Icon(Icons.search, color: Colors.grey)));
  }
  Widget _buildSectionTitle(String title, VoidCallback onViewAll) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), TextButton(onPressed: onViewAll, child: Text('عرض الكل', style: TextStyle(color: Theme.of(context).colorScheme.primary)))]);
  }
  Widget _buildFoodsList(List<FoodItem> foods) {
    return SizedBox(height: 250, child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 15), itemCount: foods.length, itemBuilder: (context, index) => FoodCard(food: foods[index])));
  }
  Widget _buildRestaurantsList(List<Restaurant> restaurants) {
    return SizedBox(height: 130, child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 15), itemCount: restaurants.length > 5 ? 5 : restaurants.length, itemBuilder: (context, index) => RestaurantCard(restaurant: restaurants[index])));
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
            ? () => Navigator.of(context).pushNamed('/details', arguments: food)
            : null,
        child: Opacity(
            opacity: food.isDeliverable ? 1.0 : 0.5,
            child: Container(
                width: 180,
                margin: const EdgeInsets.only(left: 15),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(alignment: Alignment.center, children: [
                        ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: CachedNetworkImage(imageUrl: food.imageUrl, height: 140, width: double.infinity, fit: BoxFit.cover, placeholder: (context, url) => Shimmer.fromColors(baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!, child: Container(color: Colors.white)))),
                        if (!food.isDeliverable) Container(height: 140, width: double.infinity, decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(20)), child: const Center(child: Text('خارج التوصيل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))))
                      ]),
                      const SizedBox(height: 10),
                      Text(food.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 5),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(food.formattedPrice, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            IconButton(
                                icon: Icon(Icons.add_shopping_cart, color: food.isDeliverable ? Theme.of(context).colorScheme.primary : Colors.grey),
                                onPressed: food.isDeliverable ? () => cart.addToCart(food, context) : null)
                          ])
                    ]))));
  }
}

class RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  const RestaurantCard({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: restaurant.isDeliverable
            ? () => Navigator.of(context).pushNamed('/menu', arguments: restaurant)
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
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: const Text('سلة التسوق'),
            actions: [
              IconButton(
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                  tooltip: 'دخول مدير المطعم',
                  onPressed: () {
                    Navigator.of(context).pushNamed('/login');
                  })
            ]),
        body: Consumer<CartProvider>(
            builder: (context, cart, child) {
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
                        itemBuilder: (context, index) =>
                            _buildCartItemCard(context, cart, cart.items[index]))),
                _buildCheckoutSection(context, cart)
              ]);
            }
        ));
  }

  void _showCheckoutDialog(BuildContext context, CartProvider cart) {
    _nameController.clear();
    _phoneController.clear();
    _addressController.clear();
    bool isSubmitting = false;
    showDialog(context: context, barrierDismissible: !isSubmitting, builder: (BuildContext dialogContext) {
      return StatefulBuilder(builder: (context, setDialogState) {
        return AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), title: const Text('إتمام الطلب'), content: Form(key: _formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'الاسم الكامل'), validator: (value) => value!.isEmpty ? 'الرجاء إدخال الاسم' : null, enabled: !isSubmitting),
          const SizedBox(height: 15),
          TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: 'رقم الهاتف'), keyboardType: TextInputType.phone, validator: (value) => value!.isEmpty ? 'الرجاء إدخال رقم الهاتف' : null, enabled: !isSubmitting),
          const SizedBox(height: 15),
          TextFormField(controller: _addressController, decoration: const InputDecoration(labelText: 'العنوان بالتفصيل'), maxLines: 2, validator: (value) => value!.isEmpty ? 'الرجاء إدخال العنوان' : null, enabled: !isSubmitting)
        ]))), actions: <Widget>[
          TextButton(onPressed: isSubmitting ? null : () => Navigator.of(dialogContext).pop(), child: const Text('إلغاء')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white), onPressed: isSubmitting ? null : () async {
            if (!_formKey.currentState!.validate()) return;
            setDialogState(() => isSubmitting = true);
            try {
              await _apiService.submitOrder(name: _nameController.text, phone: _phoneController.text, address: _addressController.text, cartItems: cart.items);
              if (!mounted) return;
              Navigator.of(dialogContext).pop();
              cart.clearCart();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال طلبك بنجاح!')));
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في إرسال الطلب: ${e.toString()}')));
            } finally {
              if (mounted) {
                setDialogState(() => isSubmitting = false);
              }
            }
          }, child: isSubmitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0)) : const Text('تأكيد الطلب'))
        ]);
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
        Text(item.formattedPrice, style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold))
      ])),
      Row(children: [IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => cart.decrementQuantity(item)), Text(item.quantity.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => cart.incrementQuantity(item))])
    ])));
  }
  Widget _buildCheckoutSection(BuildContext context, CartProvider cart) {
    final totalFormatted = NumberFormat('#,###', 'ar_IQ').format(cart.totalPrice);
    return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10, spreadRadius: 5)]), child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('الإجمالي', style: TextStyle(fontSize: 18, color: Colors.grey)), Text('$totalFormatted د.ع', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))]),
      const SizedBox(height: 20),
      SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => _showCheckoutDialog(context, cart), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), child: const Text('إتمام الطلب', style: TextStyle(fontSize: 18, color: Colors.white))))
    ]));
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
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final token = await _authService.loginRestaurantOwner(
          _usernameController.text, _passwordController.text);
      if (!mounted) return;
      if (token != null) {
        await _authService.registerDeviceToken();
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (route) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('فشل تسجيل الدخول. الرجاء التأكد من البيانات.')));
      }
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
            child:
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.store_mall_directory,
                  size: 80, color: Colors.teal),
              const SizedBox(height: 20),
              TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                      labelText: 'اسم المستخدم أو البريد الإلكتروني'),
                  validator: (value) =>
                  value!.isEmpty ? 'الحقل مطلوب' : null),
              const SizedBox(height: 20),
              TextFormField(
                  controller: _passwordController,
                  decoration:
                  const InputDecoration(labelText: 'كلمة المرور'),
                  obscureText: true,
                  validator: (value) =>
                  value!.isEmpty ? 'الحقل مطلوب' : null),
              const SizedBox(height: 40),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      textStyle: const TextStyle(fontSize: 18)),
                  child: const Text('تسجيل الدخول'))
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
  State<RestaurantDashboardScreen> createState() =>
      _RestaurantDashboardScreenState();
}

class _RestaurantDashboardScreenState extends State<RestaurantDashboardScreen> {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  late Future<List<Order>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("==== FOREGROUND NOTIFICATION RECEIVED IN DASHBOARD ====");
      if (message.notification != null) {
        NotificationService.display(message);
        // تحديث قائمة الطلبات عند وصول إشعار جديد
        _refreshOrders();
      }
    });
  }

  void _loadOrders() {
    _ordersFuture = _apiService.getRestaurantOrders();
  }

  void _refreshOrders() {
    setState(() {
      _ordersFuture = _apiService.getRestaurantOrders();
    });
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم المطعم'),
        actions: [
          IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
              tooltip: 'تسجيل الخروج')
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshOrders();
        },
        child: FutureBuilder<List<Order>>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'حدث خطأ في جلب الطلبات: ${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: ListView( // Used ListView to allow scrolling for the refresh indicator
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                    const Icon(Icons.receipt_long, size: 100, color: Colors.grey),
                    const SizedBox(height: 20),
                    const Text('لا توجد طلبات حالياً',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 22, color: Colors.grey)),
                    const SizedBox(height: 10),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40.0),
                      child: Text(
                        'اسحب للأسفل لتحديث القائمة.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  ],
                ),
              );
            }

            final orders = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return OrderCard(
                  order: order,
                  onStatusChanged: _refreshOrders, // **جديد:** تمرير دالة التحديث
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// **تعديل:** بطاقة الطلب بتصميم جديد ووظائف تفاعلية
class OrderCard extends StatefulWidget {
  final Order order;
  final VoidCallback onStatusChanged; // **جديد:** لاستدعاء التحديث من الأب

  const OrderCard({
    super.key,
    required this.order,
    required this.onStatusChanged,
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تم تحديث حالة الطلب #${widget.order.id} بنجاح'), backgroundColor: Colors.green),
          );
          widget.onStatusChanged(); // **جديد:** إعلام الأب بضرورة التحديث
        } else {
          throw Exception('Failed to update status from API');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: لم يتم تحديث حالة الطلب. $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('لا يمكن إجراء الاتصال بالرقم: $phoneNumber'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('yyyy-MM-dd – hh:mm a');
    final formattedDate = formatter.format(widget.order.dateCreated.toLocal());
    final totalFormatted = NumberFormat('#,###', 'ar_IQ').format(double.parse(widget.order.total));

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                ...widget.order.lineItems.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Row(
                    children: [
                      Text('• ${item.quantity} ×', style: TextStyle(color: Colors.grey.shade700)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(item.name)),
                    ],
                  ),
                )).toList(),
                const Divider(height: 32),
                _buildTotalAndCall(context, totalFormatted),
              ],
            ),
          ),
          if (_isUpdating)
            const Padding(
              padding: EdgeInsets.only(bottom: 16.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildCardHeader(BuildContext context, String formattedDate) {
    return Container(
      color: Colors.teal.withOpacity(0.05),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'طلب #${widget.order.id}',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).primaryColor),
          ),
          Text(formattedDate, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 5),
        Expanded(child: Text(value, style: TextStyle(color: Colors.grey.shade800))),
      ],
    );
  }

  Widget _buildTotalAndCall(BuildContext context, String totalFormatted) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الإجمالي', style: TextStyle(color: Colors.grey.shade600)),
            Text('$totalFormatted د.ع', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _makePhoneCall(widget.order.phone),
          icon: const Icon(Icons.call, size: 20),
          label: const Text('اتصال بالزبون'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      color: Colors.grey.withOpacity(0.05),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextButton.icon(
              onPressed: () => _updateStatus('cancelled'),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('إلغاء الطلب'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _updateStatus('completed'),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('قبول الطلب'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class DetailScreen extends StatelessWidget {
  final FoodItem foodItem;
  const DetailScreen({super.key, required this.foodItem});
  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    return Scaffold(
      body: Column(children: [
        Expanded(child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildHeaderImage(context),
          Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(foodItem.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Text(foodItem.description, style: const TextStyle(color: Colors.black54, height: 1.5))
          ]))
        ]))),
        _buildBottomBar(context, cart)
      ]),
    );
  }
  Widget _buildHeaderImage(BuildContext context) {
    return Stack(children: [
      SizedBox(height: MediaQuery.of(context).size.height * 0.4, width: double.infinity, child: CachedNetworkImage(imageUrl: foodItem.imageUrl, fit: BoxFit.cover)),
      Positioned(top: 40, right: 15, child: CircleAvatar(backgroundColor: Colors.white, child: IconButton(icon: const Icon(Icons.arrow_forward, color: Colors.black), onPressed: () => Navigator.of(context).pop())))
    ]);
  }
  Widget _buildBottomBar(BuildContext context, CartProvider cart) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 2, blurRadius: 10)]), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(foodItem.formattedPrice, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ElevatedButton(onPressed: () => cart.addToCart(foodItem, context), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), child: const Text('أضف إلى السلة', style: TextStyle(fontSize: 16, color: Colors.white)))
    ]));
  }
}

class SelectLocationDialog extends StatefulWidget {
  final bool isCancellable;
  const SelectLocationDialog({super.key, this.isCancellable = false});
  @override
  _SelectLocationDialogState createState() => _SelectLocationDialogState();
}

class _SelectLocationDialogState extends State<SelectLocationDialog> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _error;
  List<Area> _areas = [];
  List<Area> _governorates = [];
  List<Area> _subAreas = [];
  Area? _selectedGovernorate;
  Area? _selectedArea;
  @override
  void initState() {
    super.initState();
    _fetchAreas();
  }
  Future<void> _fetchAreas() async {
    try {
      final allAreas = await _apiService.getAreas();
      if (!mounted) return;
      setState(() {
        _areas = allAreas;
        _governorates = _areas.where((area) => area.parentId == 0).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "فشل في تحميل المناطق. الرجاء المحاولة مرة أخرى.";
        _isLoading = false;
      });
    }
  }
  Future<void> _saveSelection() async {
    if (_selectedArea == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selectedAreaId', _selectedArea!.id);
    await prefs.setString('selectedAreaName', _selectedArea!.name);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }
  @override
  Widget build(BuildContext context) {
    return AlertDialog(title: const Text('اختر موقعك'), content: _isLoading ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())) : _error != null ? SizedBox(height: 100, child: Center(child: Text(_error!))) : SizedBox(height: 150, child: Column(mainAxisSize: MainAxisSize.min, children: [
      DropdownButtonFormField<Area>(value: _selectedGovernorate, hint: const Text('اختر المحافظة'), isExpanded: true, items: _governorates.map((Area area) => DropdownMenuItem<Area>(value: area, child: Text(area.name))).toList(), onChanged: (Area? newValue) {
        setState(() {
          _selectedGovernorate = newValue;
          _selectedArea = null;
          _subAreas = _areas.where((a) => a.parentId == newValue?.id).toList();
        });
      }),
      const SizedBox(height: 20),
      DropdownButtonFormField<Area>(value: _selectedArea, hint: const Text('اختر المنطقة'), isExpanded: true, items: _subAreas.map((Area area) => DropdownMenuItem<Area>(value: area, child: Text(area.name))).toList(), onChanged: _selectedGovernorate == null ? null : (Area? newValue) => setState(() => _selectedArea = newValue))
    ])), actions: [
      if (widget.isCancellable) TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('إلغاء')),
      ElevatedButton(onPressed: _selectedArea != null ? _saveSelection : null, child: const Text('تأكيد'))
    ]);
  }
}

class ShimmerHomeScreen extends StatelessWidget {
  const ShimmerHomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(physics: const NeverScrollableScrollPhysics(), padding: const EdgeInsets.symmetric(vertical: 20.0), child: Shimmer.fromColors(baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20.0), child: Container(width: 200, height: 30, color: Colors.white)),
      const SizedBox(height: 20),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20.0), child: Container(width: double.infinity, height: 50, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)))),
      const SizedBox(height: 20),
      Container(height: 150, width: double.infinity, margin: const EdgeInsets.symmetric(horizontal: 20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15))),
      const SizedBox(height: 30),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20.0), child: Container(width: 150, height: 24, color: Colors.white)),
      const SizedBox(height: 10),
      SizedBox(height: 250, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: 3, itemBuilder: (context, index) => const ShimmerFoodCard(isHorizontal: true)))
    ])));
  }
}

class ShimmerFoodCard extends StatelessWidget {
  final bool isHorizontal;
  const ShimmerFoodCard({super.key, this.isHorizontal = false});
  @override
  Widget build(BuildContext context) {
    return Container(width: isHorizontal ? 180 : null, margin: const EdgeInsets.only(left: 15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(flex: 3, child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)))),
      const SizedBox(height: 10),
      Expanded(flex: 1, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: double.infinity, height: 16, color: Colors.white), const SizedBox(height: 5), Container(width: 100, height: 16, color: Colors.white)]))
    ]));
  }
}

class ShimmerRestaurantCard extends StatelessWidget {
  const ShimmerRestaurantCard({super.key});
  @override
  Widget build(BuildContext context) {
    return Card(clipBehavior: Clip.antiAlias, elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), child: Shimmer.fromColors(baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Expanded(child: Container(color: Colors.white)),
      Padding(padding: const EdgeInsets.all(8.0), child: Container(height: 16, color: Colors.white))
    ])));
  }
}
