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
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

// --- إعدادات وثوابت عامة للوحدة ---
const String BEYTEI_URL = 'https://re.beytei.com'; // استبدل بالرابط الصحيح
const String CONSUMER_KEY = 'ck_d22c789681c4610838f1d39a05dbedcb73a2c810';
const String CONSUMER_SECRET = 'cs_78b90e397bbc2a8f5f5092cca36dc86e55c01c07';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("==== BACKGROUND NOTIFICATION RECEIVED ====");
}

// --- Providers for State Management ---
class NavigationProvider with ChangeNotifier {
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  void changeTab(int index) {
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

  Future<void> logout() async {
    final authService = AuthService();
    await authService.logout();
    _token = null;
    notifyListeners();
  }
}

/// الودجت الرئيسي الذي يتم استدعاؤه
class RestaurantModule extends StatelessWidget {
  const RestaurantModule({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CartProvider()),
        ChangeNotifierProvider(create: (context) => NavigationProvider()),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Beytei Restaurants',
        theme: ThemeData(
            primarySwatch: Colors.teal,
            scaffoldBackgroundColor: const Color(0xFFF5F5F5),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              elevation: 0.5,
              iconTheme: IconThemeData(color: Colors.black),
              titleTextStyle: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Tajawal'),
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(fontFamily: 'Tajawal'),
              bodyMedium: TextStyle(fontFamily: 'Tajawal'),
              displayLarge: TextStyle(fontFamily: 'Tajawal'),
              titleLarge: TextStyle(fontFamily: 'Tajawal'),
            )
        ),
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
      ),
    );
  }
}


/// الودجت الجذر الذي يقرر أي واجهة يعرضها
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        if (auth.isLoading) {
          return const SplashScreen();
        }
        if (auth.isLoggedIn) {
          return const RestaurantDashboardScreen();
        } else {
          return const LocationCheckWrapper();
        }
      },
    );
  }
}

/// ويدجت للتأكد من اختيار المنطقة قبل عرض الواجهة الرئيسية
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        if (snapshot.hasData && snapshot.data != null) {
          return const MainScreen();
        } else {
          return const SelectLocationScreen();
        }
      },
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

    final billing = json['billing'] as Map<String, dynamic>? ?? {};
    final shipping = json['shipping'] as Map<String, dynamic>? ?? {};

    return Order(
      id: json['id'],
      status: json['status'],
      dateCreated: DateTime.parse(json['date_created']),
      total: json['total'].toString(),
      customerName: '${billing['first_name'] ?? ''} ${billing['last_name'] ?? ''}'.trim(),
      address: shipping['address_1'] ?? billing['address_1'] ?? 'N/A',
      phone: billing['phone'] ?? 'N/A',
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("تمت الإضافة إلى السلة"),
        content: Text("تمت إضافة '${item.name}' بنجاح."),
        actions: [
          TextButton(
            child: const Text("مواصلة التسوق"),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            child: const Text("الذهاب للسلة"),
            onPressed: () {
              Navigator.of(ctx).pop();
              Provider.of<NavigationProvider>(context, listen: false).changeTab(2);
            },
          ),
        ],
      ),
    );
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
    const fields = 'id,name,image,count';
    final url = '$BEYTEI_URL/wp-json/wc/v3/products/categories?parent=0&per_page=100&_fields=$fields';
    final response = await http.get(Uri.parse(url), headers: {'Authorization': _authString});
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.where((item) => item['count'] > 0).map((json) => Restaurant.fromJson(json)).toList();
    } else {
      throw Exception('فشل في جلب جميع المطاعم');
    }
  }

  Future<Set<int>> getDeliverableRestaurantIds(int areaId) async {
    final url = '$BEYTEI_URL/wp-json/wc/v3/products/categories?parent=0&per_page=100&area=$areaId&_fields=id';
    final response = await http.get(Uri.parse(url), headers: {'Authorization': _authString});
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map<int>((item) => item['id']).toSet();
    } else {
      throw Exception('فشل في جلب المطاعم للمنطقة المحددة');
    }
  }

  Future<List<FoodItem>> _getProducts(String params) async {
    const fields = 'id,name,regular_price,sale_price,images,categories,short_description';
    final url = '$BEYTEI_URL/wp-json/wc/v3/products?$params&_fields=$fields';
    final response = await http.get(Uri.parse(url), headers: {'Authorization': _authString});
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => FoodItem.fromJson(json)).toList();
    } else {
      throw Exception('فشل في جلب المنتجات');
    }
  }

  Future<List<FoodItem>> getOnSaleItems() async {
    return _getProducts('on_sale=true&per_page=20');
  }

  Future<List<FoodItem>> getProductsByTag(String tagName) async {
    final tagsResponse = await http.get(Uri.parse('$BEYTEI_URL/wp-json/wc/v3/products/tags?search=$tagName&_fields=id'), headers: {'Authorization': _authString});
    if (tagsResponse.statusCode != 200) throw Exception('فشل في البحث عن الوسم: $tagName');
    final tags = json.decode(tagsResponse.body);
    if (tags.isEmpty) return [];
    final tagId = tags[0]['id'];
    return _getProducts('tag=$tagId&per_page=10');
  }

  Future<List<FoodItem>> searchProducts(String query) async {
    return _getProducts('search=$query&per_page=20');
  }

  Future<List<FoodItem>> getMenuForRestaurant(int categoryId) async {
    return _getProducts('category=$categoryId&per_page=100');
  }

  Future<void> submitOrder({required String name, required String phone, required String address, required List<FoodItem> cartItems}) async {
    final body = json.encode({
      "payment_method": "cod",
      "payment_method_title": "الدفع عند الاستلام",
      "billing": {"first_name": name, "last_name":".", "phone": phone, "address_1": address, "country": "IQ", "city": "Default", "postcode":"10001", "email": "customer@example.com"},
      "shipping": {"first_name": name, "last_name":".", "address_1": address, "country": "IQ", "city": "Default", "postcode":"10001"},
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

  Future<List<Order>> getRestaurantOrders({String status = 'active'}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) {
      throw Exception('User not logged in');
    }

    final uri = Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/get-orders?status=$status');

    final response = await http.get(
      uri,
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
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) return;

    String? fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken == null) return;

    try {
      await http.post(
        Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/register-device'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'token': fcmToken}),
      );
    } catch (e) {
      print("[AUTH_SERVICE] An error occurred while registering device token: $e");
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token');

    if (jwtToken != null) {
      try {
        await http.post(
          Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/unregister-device'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $jwtToken',
          },
        );
      } catch (e) {
        print("[AUTH_SERVICE] Failed to unregister device on logout: $e");
      }
    }

    await FirebaseMessaging.instance.deleteToken();
    await prefs.remove('jwt_token');
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

// [MODIFIED] MainScreen now handles the back button logic intelligently.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // A key for each tab's Navigator to control its stack
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  @override
  Widget build(BuildContext context) {
    final navProvider = Provider.of<NavigationProvider>(context);

    return WillPopScope(
      onWillPop: () async {
        final NavigatorState? currentNavigator = _navigatorKeys[navProvider.currentIndex].currentState;

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
          children: <Widget>[
            _buildOffstageNavigator(0),
            _buildOffstageNavigator(1),
            _buildOffstageNavigator(2),
          ],
        ),
        bottomNavigationBar: _buildCustomBottomNav(navProvider),
      ),
    );
  }

  // Helper method to build a navigator for each tab
  Widget _buildOffstageNavigator(int index) {
    return Offstage(
      offstage: Provider.of<NavigationProvider>(context).currentIndex != index,
      child: Navigator(
        key: _navigatorKeys[index],
        onGenerateRoute: (settings) {
          Widget pageBuilder;
          switch (index) {
            case 0:
              pageBuilder = const HomeScreen();
              break;
            case 1:
              pageBuilder = const RestaurantsScreen();
              break;
            case 2:
              pageBuilder = const CartScreen();
              break;
            default:
              pageBuilder = const HomeScreen();
          }
          return MaterialPageRoute(
            builder: (context) => pageBuilder,
            settings: settings,
          );
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
        BottomNavigationBarItem(
          icon: Consumer<CartProvider>(
            builder: (context, cart, child) => Badge(
              isLabelVisible: cart.cartCount > 0,
              label: Text(cart.cartCount.toString()),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
          ),
          activeIcon: Consumer<CartProvider>(
            builder: (context, cart, child) => Badge(
              isLabelVisible: cart.cartCount > 0,
              label: Text(cart.cartCount.toString()),
              child: const Icon(Icons.shopping_cart),
            ),
          ),
          label: 'السلة',
        ),
      ],
      currentIndex: navProvider.currentIndex,
      onTap: navProvider.changeTab,
    );
  }
}

// --- MODIFIED HOME SCREEN FOR BETTER PERFORMANCE ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final List<String> bannerImages = [
    'https://beytei.com/wp-content/uploads/2023/05/banner1.jpg',
    'https://beytei.com/wp-content/uploads/2023/05/banner2.jpg',
    'https://beytei.com/wp-content/uploads/2023/05/banner3.jpg'
  ];

  int? _selectedAreaId;
  String? _selectedAreaName;

  // Futures for each section to load independently
  Future<List<Restaurant>>? _restaurantsFuture;
  Future<List<FoodItem>>? _onSaleFuture;
  Future<List<FoodItem>>? _breakfastFuture;
  Future<List<FoodItem>>? _familyMealsFuture;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedAreaId = prefs.getInt('selectedAreaId');
    _selectedAreaName = prefs.getString('selectedAreaName');

    if (_selectedAreaId != null) {
      setState(() {
        final deliverableIdsFuture = _apiService.getDeliverableRestaurantIds(_selectedAreaId!);

        _restaurantsFuture = _filterAndBuildFuture<Restaurant>(
          deliverableIdsFuture,
          _apiService.getAllRestaurants(),
        );
        _onSaleFuture = _filterAndBuildFuture<FoodItem>(
          deliverableIdsFuture,
          _apiService.getOnSaleItems(),
        );
        _breakfastFuture = _filterAndBuildFuture<FoodItem>(
          deliverableIdsFuture,
          _apiService.getProductsByTag("فطور"),
        );
        _familyMealsFuture = _filterAndBuildFuture<FoodItem>(
          deliverableIdsFuture,
          _apiService.getProductsByTag("عائلي"),
        );
      });
    }
  }

  Future<List<T>> _filterAndBuildFuture<T>(
      Future<Set<int>> deliverableIdsFuture,
      Future<List<T>> itemsFuture,
      ) async {
    final deliverableIds = await deliverableIdsFuture;
    final items = await itemsFuture;

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

  void _onSearchSubmitted(String query) {
    if (query.isNotEmpty) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => SearchScreen(
          searchQuery: query,
          selectedAreaId: _selectedAreaId!,
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () async {
            await Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const SelectLocationScreen(isCancellable: true),
            ));
            _loadAllData();
          },
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(_selectedAreaName ?? "اختر منطقة", style: const TextStyle(fontSize: 16)),
            const Icon(Icons.keyboard_arrow_down, size: 20)
          ]),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.login),
            tooltip: "دخول مدير المطعم",
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RestaurantLoginScreen()));
            },
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAllData,
        child: _selectedAreaId == null
            ? const Center(child: Text("الرجاء تحديد منطقة أولاً"))
            : ListView(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          children: [
            Padding(padding: const EdgeInsets.symmetric(horizontal: 20.0), child: _buildSearchBar()),
            const SizedBox(height: 20),
            _buildBannerSlider(),
            const SizedBox(height: 20),

            _buildSection<Restaurant>(
              future: _restaurantsFuture,
              title: 'المطاعم',
              onViewAll: () => Provider.of<NavigationProvider>(context, listen: false).changeTab(1),
              listBuilder: (items) => _buildRestaurantsList(items),
              shimmerList: _buildShimmerRestaurantsList(),
            ),

            _buildSection<FoodItem>(
              future: _onSaleFuture,
              title: 'عروض وخصومات',
              onViewAll: () {},
              listBuilder: (items) => _buildFoodsList(items),
              shimmerList: _buildShimmerFoodsList(),
            ),

            _buildSection<FoodItem>(
              future: _breakfastFuture,
              title: 'الفطور',
              onViewAll: () {},
              listBuilder: (items) => _buildFoodsList(items),
              shimmerList: _buildShimmerFoodsList(),
            ),

            _buildSection<FoodItem>(
              future: _familyMealsFuture,
              title: 'وجبات عائلية',
              onViewAll: () {},
              listBuilder: (items) => _buildFoodsList(items),
              shimmerList: _buildShimmerFoodsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection<T>({
    required Future<List<T>>? future,
    required String title,
    required VoidCallback onViewAll,
    required Widget Function(List<T>) listBuilder,
    required Widget shimmerList,
  }) {
    return FutureBuilder<List<T>>(
      future: future,
      builder: (context, snapshot) {
        if (future == null) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: _buildSectionTitle(title, onViewAll),
              ),
              const SizedBox(height: 10),
              shimmerList,
              const SizedBox(height: 20),
            ],
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: _buildSectionTitle(title, onViewAll),
              ),
              const SizedBox(height: 10),
              shimmerList,
              const SizedBox(height: 20),
            ],
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final items = snapshot.data!;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildSectionTitle(title, onViewAll),
            ),
            const SizedBox(height: 10),
            listBuilder(items),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _buildBannerSlider() {
    return CarouselSlider(
        options: CarouselOptions(
            height: 150.0,
            autoPlay: true,
            enlargeCenterPage: true,
            aspectRatio: 16 / 9,
            viewportFraction: 0.9),
        items: bannerImages.map((i) {
          return Builder(builder: (BuildContext context) {
            return Container(
                width: MediaQuery.of(context).size.width,
                margin: const EdgeInsets.symmetric(horizontal: 5.0),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    image: DecorationImage(
                        image: CachedNetworkImageProvider(i),
                        fit: BoxFit.cover)));
          });
        }).toList());
  }

  Widget _buildSearchBar() {
    return TextField(
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
  }

  Widget _buildSectionTitle(String title, VoidCallback onViewAll) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style:
              const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          TextButton(
              onPressed: onViewAll,
              child: Text('عرض الكل',
                  style:
                  TextStyle(color: Theme.of(context).colorScheme.primary)))
        ]);
  }

  Widget _buildFoodsList(List<FoodItem> foods) {
    return SizedBox(
        height: 270,
        child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 5),
            itemCount: foods.length,
            itemBuilder: (context, index) => FoodCard(food: foods[index])));
  }

  Widget _buildShimmerFoodsList() {
    return SizedBox(
        height: 270,
        child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 5),
            itemCount: 3,
            itemBuilder: (context, index) => const ShimmerFoodCard()));
  }

  Widget _buildRestaurantsList(List<Restaurant> restaurants) {
    return SizedBox(
        height: 130,
        child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 5),
            itemCount: restaurants.length > 5 ? 5 : restaurants.length,
            itemBuilder: (context, index) =>
                HorizontalRestaurantCard(restaurant: restaurants[index])));
  }

  Widget _buildShimmerRestaurantsList() {
    return SizedBox(
        height: 130,
        child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 5),
            itemCount: 5,
            itemBuilder: (context, index) =>
            const ShimmerHorizontalRestaurantCard()));
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
  Future<List<Area>>? _areasFuture;
  int? _selectedGovernorateId;

  @override
  void initState() {
    super.initState();
    _areasFuture = _apiService.getAreas();
  }

  Future<void> _saveSelection(int areaId, String areaName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selectedAreaId', areaId);
    await prefs.setString('selectedAreaName', areaName);
    if(mounted) {
      if (widget.isCancellable) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LocationCheckWrapper()),
              (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختر منطقة التوصيل'),
        automaticallyImplyLeading: widget.isCancellable,
      ),
      body: FutureBuilder<List<Area>>(
        future: _areasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('فشل في جلب المناطق.'),
              const SizedBox(height: 10),
              ElevatedButton(onPressed: (){ setState(() { _areasFuture = _apiService.getAreas(); }); }, child: const Text('حاول مرة أخرى'))
            ],));
          }

          final allAreas = snapshot.data!;
          final governorates = allAreas.where((a) => a.parentId == 0).toList();
          final cities = _selectedGovernorateId == null
              ? <Area>[]
              : allAreas.where((a) => a.parentId == _selectedGovernorateId).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'اختر المحافظة', border: OutlineInputBorder()),
                  value: _selectedGovernorateId,
                  items: governorates.map((gov) {
                    return DropdownMenuItem<int>(
                      value: gov.id,
                      child: Text(gov.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedGovernorateId = value;
                    });
                  },
                ),
                const SizedBox(height: 20),
                if (_selectedGovernorateId != null) ...[
                  Text('اختر المدينة:', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const Divider(),
                  if (cities.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('لا توجد مدن متاحة في هذه المحافظة.'),
                    ),
                  ...cities.map((city) => ListTile(
                    title: Text(city.name),
                    onTap: (){
                      _saveSelection(city.id, city.name);
                    },
                  )),
                ]
              ],
            ),
          );
        },
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
  Future<List<Restaurant>>? _restaurantsFuture;
  final ApiService _apiService = ApiService();
  int? _selectedAreaId;


  @override
  void initState() {
    super.initState();
    _loadAndClassifyRestaurants();
  }

  Future<void> _loadAndClassifyRestaurants() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedAreaId = prefs.getInt('selectedAreaId');
    if (_selectedAreaId != null) {
      setState(() {
        _restaurantsFuture = _fetchRestaurants(_selectedAreaId!);
      });
    } else {
      setState(() {
        _restaurantsFuture = Future.value([]);
      });
    }
  }

  Future<List<Restaurant>> _fetchRestaurants(int areaId) async {
    final deliverableIds = await _apiService.getDeliverableRestaurantIds(areaId);
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
      body: RefreshIndicator(
        onRefresh: _loadAndClassifyRestaurants,
        child: FutureBuilder<List<Restaurant>>(
          future: _restaurantsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return GridView.builder(
                  padding: const EdgeInsets.all(15),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 0.7),
                  itemCount: 6,
                  itemBuilder: (context, index) => const ShimmerRestaurantCard());
            }
            if (snapshot.hasError) return Center(child: Text("خطأ: ${snapshot.error}"));
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("لا توجد مطاعم متاحة حالياً في منطقتك"));
            }
            final restaurants = snapshot.data!;
            return GridView.builder(
                padding: const EdgeInsets.all(15),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 0.7),
                itemCount: restaurants.length,
                itemBuilder: (context, index) => RestaurantCard(restaurant: restaurants[index]));
          },
        ),
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
    return allResults.where((item) {
      final isDeliverable = deliverableIds.contains(item.categoryId);
      item.isDeliverable = isDeliverable;
      return isDeliverable;
    }).toList();
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

class DetailScreen extends StatelessWidget {
  final FoodItem foodItem;

  const DetailScreen({super.key, required this.foodItem});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: Text(foodItem.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Hero(
              tag: 'food_image_${foodItem.id}',
              child: CachedNetworkImage(
                imageUrl: foodItem.imageUrl,
                fit: BoxFit.cover,
                height: 300,
                placeholder: (context, url) => Container(
                  height: 300,
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 300,
                  color: Colors.grey[200],
                  child: const Icon(Icons.error),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    foodItem.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    foodItem.formattedPrice,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    foodItem.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
          label: const Text("إضافة إلى السلة", style: TextStyle(color: Colors.white, fontSize: 18)),
          onPressed: () {
            cart.addToCart(foodItem, context);
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            backgroundColor: Theme.of(context).primaryColor,
          ),
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
        ),
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
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white), onPressed: isSubmitting ? null : () async {
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
        Text(item.formattedPrice, style: TextStyle(fontSize: 16, color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold))
      ])),
      Row(children: [IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => cart.decrementQuantity(item)), Text(item.quantity.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => cart.incrementQuantity(item))])
    ])));
  }
  Widget _buildCheckoutSection(BuildContext context, CartProvider cart) {
    final totalFormatted = NumberFormat('#,###', 'ar_IQ').format(cart.totalPrice);
    return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10, spreadRadius: 5)]), child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('الإجمالي', style: TextStyle(fontSize: 18, color: Colors.grey)), Text('$totalFormatted د.ع', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))]),
      const SizedBox(height: 20),
      SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => _showCheckoutDialog(context, cart), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white), child: const Text('إتمام الطلب', style: TextStyle(fontSize: 18))))
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
  bool _isLoading = false;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.login(
          _usernameController.text, _passwordController.text);

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop();
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
              const Icon(Icons.store_mall_directory, size: 80, color: Colors.teal),
              const SizedBox(height: 20),
              TextFormField( controller: _usernameController, decoration: const InputDecoration( labelText: 'اسم المستخدم أو البريد الإلكتروني'), validator: (value) => value!.isEmpty ? 'الحقل مطلوب' : null),
              const SizedBox(height: 20),
              TextFormField( controller: _passwordController, decoration: const InputDecoration(labelText: 'كلمة المرور'), obscureText: true, validator: (value) => value!.isEmpty ? 'الحقل مطلوب' : null),
              const SizedBox(height: 40),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton( onPressed: _login, style: ElevatedButton.styleFrom( minimumSize: const Size(double.infinity, 50), textStyle: const TextStyle(fontSize: 18)), child: const Text('تسجيل الدخول'))
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

  late Future<List<Order>> _activeOrdersFuture;
  late Future<List<Order>> _completedOrdersFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadOrders();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        NotificationService.display(message);
        _refreshOrders();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadOrders() {
    _activeOrdersFuture = _apiService.getRestaurantOrders(status: 'active');
    _completedOrdersFuture = _apiService.getRestaurantOrders(status: 'completed');
  }

  Future<void> _refreshOrders() async {
    setState(() {
      _loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم المطعم'),
        actions: [
          IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => Provider.of<AuthProvider>(context, listen: false).logout(),
              tooltip: 'تسجيل الخروج')
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'طلبات جديدة'),
            Tab(text: 'طلبات مكتملة'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrdersList(future: _activeOrdersFuture, onRefresh: _refreshOrders),
          _buildOrdersList(future: _completedOrdersFuture, onRefresh: _refreshOrders, isCompletedList: true),
        ],
      ),
    );
  }

  Widget _buildOrdersList({required Future<List<Order>> future, required Future<void> Function() onRefresh, bool isCompletedList = false}) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: FutureBuilder<List<Order>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                Text('لا توجد طلبات في هذا القسم حالياً', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                const SizedBox(height: 10),
                const Icon(Icons.inbox_outlined, size: 50, color: Colors.grey),
              ],
            ));
          }
          final orders = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              return OrderCard(
                order: orders[index],
                onStatusChanged: _refreshOrders,
                isCompleted: isCompletedList,
              );
            },
          );
        },
      ),
    );
  }
}

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  final String privacyPolicyUrl = 'https://re.beytei.com/privacy-policy/'; // <-- ضع رابط سياستك هنا

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            print('حدث خطأ أثناء تحميل الصفحة: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(privacyPolicyUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سياسة الخصوصية'),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

// --- الويدجتات (Widgets) ---

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

// --- NEW WIDGET FOR HORIZONTAL LISTS IN HOME SCREEN ---
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

// --- NEW, IMPROVED RESTAURANT CARD WIDGET ---
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
              // Image part
              Expanded(
                flex: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: restaurant.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(color: Colors.white),
                      ),
                      errorWidget: (context, url, error) => const Icon(Icons.storefront, color: Colors.grey, size: 40),
                    ),
                    if (!restaurant.isDeliverable)
                      Container(
                        color: Colors.black.withOpacity(0.6),
                        child: const Center(
                          child: Text(
                            'خارج\nمنطقتك',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Details and Button part
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        restaurant.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      // The new prominent button
                      SizedBox(
                        height: 30,
                        child: ElevatedButton.icon(
                          onPressed: restaurant.isDeliverable
                              ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MenuScreen(restaurant: restaurant)))
                              : null,
                          icon: const Icon(Icons.menu_book, size: 14),
                          label: const Text(' عرض المنيو', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
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

  const OrderCard({
    super.key,
    required this.order,
    required this.onStatusChanged,
    this.isCompleted = false,
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
          widget.onStatusChanged();
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
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('لا يمكن إجراء الاتصال بالرقم: $phoneNumber'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('yyyy-MM-dd – hh:mm a', 'ar');
    final formattedDate = formatter.format(widget.order.dateCreated.toLocal());
    final totalFormatted = NumberFormat('#,###', 'ar_IQ').format(double.tryParse(widget.order.total) ?? 0);

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
          else if (!widget.isCompleted)
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
      crossAxisAlignment: CrossAxisAlignment.center,
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
          label: const Text('اتصال'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _updateStatus('cancelled'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                side: BorderSide(color: Colors.red.shade200),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('إلغاء الطلب'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateStatus('completed'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('إكمال الطلب'),
            ),
          ),
        ],
      ),
    );
  }
}


class ShimmerHomeScreen extends StatelessWidget {
  const ShimmerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            height: 50,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(height: 20, width: 150, color: Colors.white),
                Container(height: 20, width: 70, color: Colors.white),
              ],
            ),
          ),
          SizedBox(
            height: 130,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 5),
              itemCount: 5,
              itemBuilder: (context, index) => const ShimmerHorizontalRestaurantCard(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            child: Container(height: 20, width: 200, color: Colors.white),
          ),
          SizedBox(
            height: 270,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 5),
              itemCount: 3,
              itemBuilder: (context, index) => const ShimmerFoodCard(),
            ),
          ),
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
      width: 100,
      margin: const EdgeInsets.only(left: 15),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
          ),
          const SizedBox(height: 8),
          Container(
            height: 10,
            width: 70,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}

// --- NEW, IMPROVED SHIMMER WIDGET ---
class ShimmerRestaurantCard extends StatelessWidget {
  const ShimmerRestaurantCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Container(color: Colors.white),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Container(height: 12, width: 100, color: Colors.white),
                        const SizedBox(height: 4),
                        Container(height: 12, width: 70, color: Colors.white),
                      ],
                    ),
                    Container(
                      height: 30,
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class ShimmerFoodCard extends StatelessWidget {
  const ShimmerFoodCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(left: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 15,
            width: 120,
            color: Colors.white,
          ),
          const SizedBox(height: 10),
          Container(
            height: 15,
            width: 60,
            color: Colors.white,
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(height: 20, width: 70, color: Colors.white),
              Container(height: 40, width: 40, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 5),
        ],
      ),
    );
  }
}