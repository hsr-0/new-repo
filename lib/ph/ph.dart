import 'dart:async';
import 'dart:convert';
import 'dart:io';

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

// =======================================================================
// --- GLOBAL NAVIGATOR KEY ---
// Used for navigating from notification taps when the app is closed.
// =======================================================================
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// =======================================================================
// --- API CONSTANTS ---
// =======================================================================
class ApiConstants {
  static const String YOUR_DOMAIN = 'https://ph.beytei.com'; //  استبدل بدومين موقعك
  static const String BASE_URL = '$YOUR_DOMAIN/wp-json';
  static const String PHARMACY_API_URL = '$BASE_URL/beytei-pharmacy/v1';
  static const String JWT_URL = '$BASE_URL/jwt-auth/v1/token';
  static const String BANNERS_URL = 'https://banner.beytei.com/images/banners.json'; // URL for banners
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
      logoUrl: json['logo_url'] ?? 'https://i.ibb.co/C0d2y7V/pharma-logo.png');
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
    imageUrl: json['imageUrl'] ?? 'https://i.ibb.co/pW1s4XF/panadol.png',
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
      pharmacyId: json['pharmacy_id'],
      pharmacyName: json['pharmacy_name'],
      products: (json['products'] as List).map((prod) => Product.fromJson(prod)).toList(),
    );
  }
}

class OrderItem {
  final String name;
  final int quantity;
  OrderItem({required this.name, required this.quantity});
  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(name: json['name'], quantity: json['quantity']);
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
  Order({required this.id, required this.customerName, required this.customerPhone, required this.customerArea, required this.total, required this.status, required this.date, required this.items, required this.customerFirebaseUid});
  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      customerName: json['customer_name'] ?? '',
      customerPhone: json['customer_phone'] ?? '',
      customerArea: json['customer_area'] ?? '',
      total: json['total']?.toString() ?? '0',
      status: json['status'] ?? '',
      date: DateTime.parse(json['date']),
      items: (json['items'] as List).map((item) => OrderItem.fromJson(item)).toList(),
      customerFirebaseUid: json['customer_firebase_uid'] ?? '',
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
      id: json['id'],
      name: json['name'] ?? 'اسم غير متوفر',
      phone: json['phone'] ?? 'رقم غير متوفر',
      illnessType: json['illness_type'] ?? 'غير محدد',
      date: DateTime.parse(json['date']),
    );
  }
}

// [MODIFIED] Conversation model to include unread count.
class Conversation {
  final String uid;
  final String name;
  final String fcmToken;
  final int unreadCount;
  final int lastMessageTime;

  Conversation({
    required this.uid,
    required this.name,
    required this.fcmToken,
    required this.unreadCount,
    required this.lastMessageTime,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      uid: json['uid'],
      name: json['name'],
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
  factory Area.fromJson(Map<String, dynamic> json) => Area(id: json['id'] ?? 0, name: json['name'] ?? 'منطقة غير مسماة', parentId: json['parent'] ?? 0);
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
        await prefs.setString('pharmacyToken', _token!);
        await fetchDashboardData();
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
      } catch (e) { print("Failed to save FCM token: $e"); }
    }
  }
  Future<void> fetchDashboardData() async {
    if (_token == null) return;
    final url = Uri.parse('${ApiConstants.PHARMACY_API_URL}/pharmacy/dashboard');
    try {
      final response = await http.get(url, headers: {'Authorization': 'Bearer $_token'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _pharmacyId = data['pharmacy_id'];
        _pharmacyName = data['pharmacy_name'];
      } else { await logout(); }
    } catch (e) { print("Failed to fetch dashboard data: $e"); }
  }
  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('pharmacyToken')) { return; }
    _token = prefs.getString('pharmacyToken');
    if (_token != null) { await fetchDashboardData(); }
    notifyListeners();
  }
  Future<void> logout() async {
    _token = null;
    _pharmacyId = null;
    _pharmacyName = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pharmacyToken');
    notifyListeners();
  }
}

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
      throw Exception('لا يمكنك إضافة منتجات من صيدليات مختلفة في نفس الطلب. الرجاء إفراغ السلة أولاً.');
    }
    _pharmacyId = product.pharmacyId;
    if (_items.containsKey(product.id)) {
      _items.update(product.id, (existingItem) => CartItem(product: existingItem.product, quantity: existingItem.quantity + 1));
    } else {
      _items.putIfAbsent(product.id, () => CartItem(product: product));
    }
    notifyListeners();
  }
  void removeSingleItem(int productId) {
    if (!_items.containsKey(productId)) return;
    if (_items[productId]!.quantity > 1) {
      _items.update(productId, (existingItem) => CartItem(product: existingItem.product, quantity: existingItem.quantity - 1));
    } else {
      _items.remove(productId);
    }
    if (_items.isEmpty) { _pharmacyId = null; }
    notifyListeners();
  }
  void clear() {
    _items = {};
    _pharmacyId = null;
    notifyListeners();
  }
}

class PharmacyProvider with ChangeNotifier {
  List<PharmacyProductGroup> _productsByPharmacy = [];
  List<Pharmacy> _allPharmacies = [];
  List<Pharmacy> _nearbyPharmacies = [];
  List<BannerItem> _banners = [];
  bool _isLoadingProducts = true;
  bool _isLoadingPharmacies = true;
  bool _isLoadingHome = true;
  bool get isLoadingBanners => _banners.isEmpty && _isLoadingHome;
  String? _error;
  List<PharmacyProductGroup> get productsByPharmacy => _productsByPharmacy;
  List<Pharmacy> get allPharmacies => _allPharmacies;
  List<Pharmacy> get nearbyPharmacies => _nearbyPharmacies;
  List<BannerItem> get banners => _banners;
  bool get isLoadingProducts => _isLoadingProducts;
  bool get isLoadingPharmacies => _isLoadingPharmacies;
  bool get isLoadingHome => _isLoadingHome;
  String? get error => _error;

  Future<void> fetchHomeData(int areaId) async {
    _isLoadingHome = true;
    _error = null;
    notifyListeners();
    try {
      final responses = await Future.wait([
        http.get(Uri.parse('${ApiConstants.PHARMACY_API_URL}/pharmacies?area_id=$areaId')),
        http.get(Uri.parse(ApiConstants.BANNERS_URL)),
      ]);

      if (responses[0].statusCode == 200) {
        final data = json.decode(responses[0].body) as List;
        _nearbyPharmacies = data.map((p) => Pharmacy.fromJson(p)).toList();
      } else {
        throw Exception('فشل تحميل بيانات المنطقة الرئيسية: ${responses[0].body}');
      }

      if (responses[1].statusCode == 200) {
        final jsonData = json.decode(responses[1].body);
        final bannerList = List<Map<String, dynamic>>.from(jsonData['banners'] ?? []);
        if (jsonData['showBanners'] ?? false) {
          _banners = bannerList.map((item) => BannerItem.fromJson(item)).toList();
        } else {
          _banners = [];
        }
      } else {
        print('Failed to load banners');
        _banners = [];
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingHome = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllProducts() async {
    _isLoadingProducts = true;
    _error = null;
    notifyListeners();
    try {
      final response = await http.get(Uri.parse('${ApiConstants.PHARMACY_API_URL}/products'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _productsByPharmacy = data.map((group) => PharmacyProductGroup.fromJson(group)).toList();
      } else {
        throw Exception('فشل في تحميل المنتجات: ${response.statusCode}');
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingProducts = false;
      notifyListeners();
    }
  }
  Future<void> fetchAllPharmacies() async {
    _isLoadingPharmacies = true;
    _error = null;
    notifyListeners();
    try {
      final response = await http.get(Uri.parse('${ApiConstants.PHARMACY_API_URL}/pharmacies'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _allPharmacies = data.map((p) => Pharmacy.fromJson(p)).toList();
      } else {
        throw Exception('فشل في تحميل الصيدليات: ${response.statusCode}');
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingPharmacies = false;
      notifyListeners();
    }
  }
}

// =======================================================================
// --- SERVICES ---
// =======================================================================
// [MODIFIED] Complete overhaul of NotificationService for robust handling.
class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Define the channel for Android
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
      'high_importance_channel', // This ID must match the one sent from the backend
      'إشعارات هامة',
      description: 'هذه القناة للإشعارات المهمة مثل الرسائل والطلبات الجديدة.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true);

  static Future<void> initialize() async {
    // Request permissions for iOS
    await _firebaseMessaging.requestPermission();

    // Create the Android channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Set foreground notification presentation options for iOS
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true, badge: true, sound: true);

    // Initialize the local notifications plugin
    await _localNotifications.initialize(
        const InitializationSettings(
            android: AndroidInitializationSettings('@mipmap/ic_launcher'),
            iOS: DarwinInitializationSettings()),
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (response.payload != null && response.payload!.isNotEmpty) {
            _handleNotificationTap(json.decode(response.payload!));
          }
        });

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });
  }

  // Helper function to display local notification
  static void _showLocalNotification(RemoteMessage message) {
    // Extract title and body from the data payload
    final String title = message.data['title'] ?? 'إشعار جديد';
    final String body = message.data['body'] ?? 'لديك رسالة جديدة.';

    _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000), // Unique ID
        title,
        body,
        NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              icon: '@mipmap/ic_launcher',
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: const DarwinNotificationDetails(presentSound: true)),
        payload: json.encode(message.data));
  }

  static Future<String?> getFCMToken() async {
    return await _firebaseMessaging.getToken();
  }

  // Centralized navigation logic for all notification taps
  static void _handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    if (type == 'new_message' || type == 'message_reply') {
      try {
        final authProvider = Provider.of<AuthProvider>(navigatorKey.currentContext!, listen: false);
        final isPharmacy = authProvider.isAuth;

        if (isPharmacy) {
          final customerUid = data['sender_uid'] as String?;
          final customerName = data['sender_name'] as String?;
          final pharmacyId = authProvider.pharmacyId;
          final pharmacyName = authProvider.pharmacyName;

          if (customerUid != null && customerName != null && pharmacyId != null && pharmacyName != null) {
            navigatorKey.currentState?.push(MaterialPageRoute(
              builder: (_) => ChatScreen(
                pharmacyId: pharmacyId,
                pharmacyName: pharmacyName,
                customerUid: customerUid,
                customerName: customerName,
              ),
            ));
          }
        } else {
          final pharmacyId = int.tryParse(data['pharmacy_id']?.toString() ?? '0');
          final pharmacyName = "صيدلية"; // The backend doesn't send this, might need an update

          if (pharmacyId != null && pharmacyId != 0) {
            navigatorKey.currentState?.push(MaterialPageRoute(
              builder: (_) => ChatScreen(
                pharmacyId: pharmacyId,
                pharmacyName: pharmacyName,
              ),
            ));
          }
        }
      } catch (e) {
        print("Error navigating from notification tap: $e");
      }
    }
  }
}


// =======================================================================
// --- WIDGETS ---
// =======================================================================
class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard({super.key, required this.product});
  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CachedNetworkImage(imageUrl: product.imageUrl, fit: BoxFit.contain, placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)), errorWidget: (c, u, e) => const Icon(Icons.medication, size: 60, color: Colors.grey)),
            ),
          ),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 12.0), child: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Padding(padding: const EdgeInsets.fromLTRB(12, 4, 12, 8), child: Text('${product.price} د.ع', style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_shopping_cart, size: 18),
              label: const Text('أضف للسلة'),
              onPressed: () {
                final cart = Provider.of<CartProvider>(context, listen: false);
                try {
                  cart.addItem(product);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تمت إضافة ${product.name} إلى السلة'), duration: const Duration(seconds: 2), backgroundColor: Colors.green));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red));
                }
              },
              style: ElevatedButton.styleFrom(visualDensity: VisualDensity.compact, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            ),
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
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: CachedNetworkImage(imageUrl: pharmacy.logoUrl, width: 60, height: 60, fit: BoxFit.cover, placeholder: (context, url) => Container(width: 60, height: 60, color: Colors.grey.shade200), errorWidget: (context, url, error) => const Icon(Icons.storefront, size: 60, color: Colors.grey)),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(pharmacy.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: const Text('دردشة'),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(pharmacyId: pharmacy.id, pharmacyName: pharmacy.name))),
              style: ElevatedButton.styleFrom(foregroundColor: Theme.of(context).primaryColor, backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1), elevation: 0),
            ),
          ],
        ),
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final Order order;
  final Function onStatusChanged;
  const OrderCard({super.key, required this.order, required this.onStatusChanged});
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    Future<void> updateStatus(String status) async {
      final url = Uri.parse('${ApiConstants.PHARMACY_API_URL}/pharmacy/update_order_status');
      try {
        final response = await http.post(url, headers: {'Authorization': 'Bearer ${authProvider.token}', 'Content-Type': 'application/json'}, body: json.encode({'order_id': order.id, 'status': status}));
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث حالة الطلب بنجاح')));
          onStatusChanged();
        } else {
          throw Exception('Failed to update status');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء تحديث الطلب')));
      }
    }
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('#${order.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text(DateFormat('yyyy-MM-dd').format(order.date), style: TextStyle(color: Colors.grey.shade600))]),
            const Divider(),
            Text('الزبون: ${order.customerName}'),
            Text('الهاتف: ${order.customerPhone}'),
            Text('المنطقة: ${order.customerArea}'),
            const SizedBox(height: 8),
            const Text('المنتجات:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...order.items.map((item) => Text('- ${item.name} (الكمية: ${item.quantity})')).toList(),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('الإجمالي: ${order.total} د.ع', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                if (order.status == 'processing')
                  Row(children: [TextButton(onPressed: () => updateStatus('cancelled'), child: const Text('إلغاء', style: TextStyle(color: Colors.red))), ElevatedButton(onPressed: () => updateStatus('completed'), child: const Text('إكمال'))])
              ],
            )
          ],
        ),
      ),
    );
  }
}

class SubscriptionCard extends StatelessWidget {
  final SubscriptionRequest subscription;
  const SubscriptionCard({super.key, required this.subscription});
  Future<void> _makePhoneCall(String phoneNumber, BuildContext context) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('لا يمكن إجراء الاتصال بالرقم $phoneNumber')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(subscription.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text(DateFormat('yyyy-MM-dd').format(subscription.date), style: TextStyle(color: Colors.grey.shade600))]),
            const Divider(),
            Text('الهاتف: ${subscription.phone}'),
            Text('نوع المرض: ${subscription.illnessType}'),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.phone_outlined, size: 18),
                label: const Text('اتصال'),
                onPressed: () => _makePhoneCall(subscription.phone, context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SubscriptionButtons extends StatelessWidget {
  final int areaId;
  const SubscriptionButtons({super.key, required this.areaId});
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => SubscriptionScreen(areaId: areaId)));
      },
      icon: const Icon(Icons.monitor_heart_outlined, size: 28),
      label: const Text('اشتراك الأمراض المزمنة', textAlign: TextAlign.center, style: TextStyle(fontSize: 15)),
      style: ElevatedButton.styleFrom(foregroundColor: Colors.black87, backgroundColor: Colors.white, elevation: 2, shadowColor: Colors.grey.withOpacity(0.2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20)),
    );
  }
}

class ConsultationCard extends StatelessWidget {
  final Pharmacy pharmacy;
  const ConsultationCard({super.key, required this.pharmacy});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(pharmacyId: pharmacy.id, pharmacyName: pharmacy.name))),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.chat_bubble_outline_rounded, color: Theme.of(context).primaryColor, size: 40),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('الحصول على استشارة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), SizedBox(height: 4), Text('تحدث مباشرة مع صيدلية منطقتك', style: TextStyle(fontSize: 14, color: Colors.grey))]),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

// =======================================================================
// --- SCREENS ---
// =======================================================================

// ---
// --- Screens: Auth & Location Flow ---
// ---
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
    _setupNotificationHandlers();
  }

  // [MODIFIED] Setup handlers for notifications that open the app
  Future<void> _setupNotificationHandlers() async {
    // For app opened from a terminated state
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      // Use a post-frame callback to ensure the navigator is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        NotificationService._handleNotificationTap(initialMessage.data);
      });
    }

    // For app opened from a background state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      NotificationService._handleNotificationTap(message.data);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _autoLoginFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return Consumer<AuthProvider>(
          builder: (ctx, authProvider, _) {
            if (authProvider.isAuth) {
              return const PharmacyDashboardScreen();
            } else {
              return StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(body: Center(child: CircularProgressIndicator()));
                  }
                  if (userSnapshot.hasData) {
                    return const LocationCheckWrapper();
                  }
                  return const CustomerLoginScreen();
                },
              );
            }
          },
        );
      },
    );
  }
}

// [MODIFIED] Fixed the "stuck spinner" issue by simplifying navigation.
class LocationCheckWrapper extends StatefulWidget {
  const LocationCheckWrapper({super.key});

  @override
  State<LocationCheckWrapper> createState() => _LocationCheckWrapperState();
}

class _LocationCheckWrapperState extends State<LocationCheckWrapper> {
  Future<int?> _checkLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('pharmacy_selectedAreaId');
  }
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int?>(
      future: _checkLocation(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData && snapshot.data != null) {
          return CustomerMainShell(areaId: snapshot.data!);
        } else {
          return const SelectLocationScreen();
        }
      },
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
  Future<List<Area>>? _areasFuture;
  int? _selectedGovernorateId;
  final String areasApiUrl = '${ApiConstants.BASE_URL}/wp/v2/area?per_page=100';
  @override
  void initState() {
    super.initState();
    _areasFuture = _getAreas();
  }
  Future<List<Area>> _getAreas() async {
    try {
      final response = await http.get(Uri.parse(areasApiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((areaJson) => Area.fromJson(areaJson)).toList();
      } else {
        throw Exception('فشل في جلب المناطق: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('فشل في جلب المناطق: $e');
    }
  }
  Future<void> _saveSelection(int areaId, String areaName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pharmacy_selectedAreaId', areaId);
    await prefs.setString('pharmacy_selectedAreaName', areaName);

    // [MODIFIED] Navigate directly to the main shell, which is the correct destination.
    // This fixes the stuck spinner issue.
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => CustomerMainShell(areaId: areaId)),
            (route) => false
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اختر منطقة الخدمة'), automaticallyImplyLeading: widget.isCancellable),
      body: FutureBuilder<List<Area>>(
        future: _areasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text('فشل في جلب المناطق.\n\n${snapshot.error}', textAlign: TextAlign.center)));
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("لم يتم العثور على مناطق."));
          final allAreas = snapshot.data!;
          final governorates = allAreas.where((a) => a.parentId == 0).toList();
          final cities = _selectedGovernorateId == null ? <Area>[] : allAreas.where((a) => a.parentId == _selectedGovernorateId).toList();
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'اختر المحافظة', border: OutlineInputBorder()),
                  value: _selectedGovernorateId,
                  items: governorates.map((g) => DropdownMenuItem<int>(value: g.id, child: Text(g.name))).toList(),
                  onChanged: (v) => setState(() => _selectedGovernorateId = v),
                ),
                const SizedBox(height: 20),
                if (_selectedGovernorateId != null)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cities.length,
                    itemBuilder: (ctx, i) => Card(
                      margin: const EdgeInsets.only(top: 8),
                      child: ListTile(
                        title: Text(cities[i].name),
                        onTap: () {
                          final govName = governorates.firstWhere((g) => g.id == _selectedGovernorateId).name;
                          _saveSelection(cities[i].id, "$govName - ${cities[i].name}");
                        },
                        trailing: const Icon(Icons.arrow_forward_ios),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class CustomerLoginScreen extends StatefulWidget {
  const CustomerLoginScreen({super.key});
  @override
  _CustomerLoginScreenState createState() => _CustomerLoginScreenState();
}
class _CustomerLoginScreenState extends State<CustomerLoginScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _registerAndLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      final user = userCredential.user;
      if (user != null) {
        await FirebaseFirestore.instance.collection('pharmacy_users').doc(user.uid).set({
          'name': _nameController.text,
          'phone': _phoneController.text,
          'createdAt': FieldValue.serverTimestamp()
        });
        // On success, AuthWrapper's StreamBuilder will handle navigation.
        // No need for manual navigation or setting state to false.
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: ${e.toString()}')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.local_pharmacy_outlined, size: 80, color: Theme.of(context).primaryColor),
                const SizedBox(height: 20),
                Text('مرحباً بك في صيدليات  منصة بيتي', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 32),
                TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'الاسم الكامل', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_outline)), validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null),
                const SizedBox(height: 16),
                TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: 'رقم الهاتف', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone_outlined)), keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null),
                const SizedBox(height: 24),
                _isLoading ? const Center(child: CircularProgressIndicator()) : ElevatedButton(style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), textStyle: const TextStyle(fontSize: 18, fontFamily: 'Cairo', fontWeight: FontWeight.bold)), onPressed: _registerAndLogin, child: const Text('دخول / إنشاء حساب')),
                const SizedBox(height: 20),
                TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PharmacyLoginScreen())), child: const Text('هل أنت صاحب صيدلية؟ تسجيل الدخول')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PharmacyLoginScreen extends StatefulWidget {
  const PharmacyLoginScreen({super.key});
  @override
  _PharmacyLoginScreenState createState() => _PharmacyLoginScreenState();
}
class _PharmacyLoginScreenState extends State<PharmacyLoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool success = await authProvider.login(_usernameController.text, _passwordController.text);
    if (mounted) {
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل تسجيل الدخول. تأكد من البيانات.')));
      }
      setState(() => _isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل دخول الصيدلية')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.storefront_outlined, size: 80, color: Theme.of(context).primaryColor),
                const SizedBox(height: 20),
                Text('   يمكنك اصافة صيدليتك بتواصل على رقم: 07854076931', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 32),
                TextFormField(controller: _usernameController, decoration: const InputDecoration(labelText: 'اسم المستخدم', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'مطلوب' : null),
                const SizedBox(height: 16),
                TextFormField(controller: _passwordController, decoration: const InputDecoration(labelText: 'كلمة المرور', border: OutlineInputBorder()), obscureText: true, validator: (v) => v!.isEmpty ? 'مطلوب' : null),
                const SizedBox(height: 24),
                _isLoading ? const Center(child: CircularProgressIndicator()) : ElevatedButton(style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), textStyle: const TextStyle(fontSize: 18, fontFamily: 'Cairo', fontWeight: FontWeight.bold)), onPressed: _login, child: const Text('دخول')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---
// --- Screens: Customer ---
// ---
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
      setState(() {
        _selectedAreaName = prefs.getString('pharmacy_selectedAreaName');
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SelectLocationScreen(isCancellable: true)));
          },
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
            await prefs.remove('pharmacy_selectedAreaId');
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
      Provider.of<PharmacyProvider>(context, listen: false).fetchHomeData(widget.areaId);
    });
  }

  void _onBannerTapped(BannerItem banner, BuildContext context) {
    if (banner.targetType == 'webview' && banner.targetUrl.isNotEmpty) {
      final uri = Uri.tryParse(banner.targetUrl);
      if (uri != null) {
        launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PharmacyProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingHome) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.error != null) {
          return Center(child: Text('حدث خطأ: ${provider.error}'));
        }
        final pharmacyInArea = provider.nearbyPharmacies.isNotEmpty ? provider.nearbyPharmacies.first : null;

        return RefreshIndicator(
          onRefresh: () => provider.fetchHomeData(widget.areaId),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (provider.banners.isNotEmpty) ...[
                CarouselSlider(
                  options: CarouselOptions(
                    height: 180.0,
                    autoPlay: true,
                    enlargeCenterPage: true,
                    aspectRatio: 16 / 9,
                    viewportFraction: 0.9,
                    autoPlayInterval: const Duration(seconds: 5),
                  ),
                  items: provider.banners.map((banner) {
                    return Builder(
                      builder: (BuildContext context) {
                        return GestureDetector(
                          onTap: () => _onBannerTapped(banner, context),
                          child: Container(
                            width: MediaQuery.of(context).size.width,
                            margin: const EdgeInsets.symmetric(horizontal: 5.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: CachedNetworkImage(
                                imageUrl: banner.imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(color: Colors.grey.shade200),
                                errorWidget: (context, url, error) => const Icon(Icons.error),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],
              SubscriptionButtons(areaId: widget.areaId),
              const SizedBox(height: 20),
              if (pharmacyInArea != null)
                ConsultationCard(pharmacy: pharmacyInArea)
              else
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text("لا توجد صيدلية تخدم هذه المنطقة حالياً للاستشارة."),
                  ),
                )
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
      Provider.of<PharmacyProvider>(context, listen: false).fetchAllProducts();
    });
  }
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PharmacyProvider>(context);
    return Scaffold(
      body: provider.isLoadingProducts
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
          ? Center(child: Text('خطأ: ${provider.error}'))
          : RefreshIndicator(
        onRefresh: () => provider.fetchAllProducts(),
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
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 10, mainAxisSpacing: 10),
                  itemBuilder: (ctx, i) => ProductCard(product: pharmacyGroup.products[i]),
                ),
              ],
            );
          },
        ),
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
    Provider.of<PharmacyProvider>(context, listen: false).fetchAllPharmacies();
  }
  @override
  Widget build(BuildContext context) {
    return Consumer<PharmacyProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingPharmacies) return const Center(child: CircularProgressIndicator());
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
                    _isLoading ? const Center(child: CircularProgressIndicator()) : ElevatedButton(onPressed: () => _submitOrder(cart), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)), child: const Text('تأكيد الطلب')),
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
      // [MODIFIED] Mark conversation as read when pharmacy opens it
      _markAsRead();
    } else {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        // This should not happen if the auth flow is correct
        Navigator.of(context).pop();
        return;
      }
      _chatUser = types.User(id: firebaseUser.uid);
      _conversationDocId = firebaseUser.uid;
      _initiateConversationIfNeeded(firebaseUser);
    }
    _loadMessages();
  }

  // [NEW] API call to mark messages as read for the pharmacy owner
  Future<void> _markAsRead() async {
    if (!_isPharmacyOwner) return;
    final url = Uri.parse('${ApiConstants.PHARMACY_API_URL}/chats/mark_as_read');
    try {
      await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${_authProvider.token}',
          'Content-Type': 'application/json'
        },
        body: json.encode({'user_uid': widget.customerUid}),
      );
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
        .collection('pharmacy_chats')
        .doc(_conversationDocId)
        .collection('conversations')
        .doc(widget.pharmacyId.toString())
        .collection('messages')
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
        } catch (e) {
          return null;
        }
      }).where((msg) => msg != null).cast<types.Message>().toList();
      setState(() => _messages = messages);
    });
  }
  Future<void> _handleAttachmentPressed() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
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
          if (querySnapshot.docs.isNotEmpty) {
            querySnapshot.docs.first.reference.update({'uri': fileUrl});
          }
        });
        final notificationText = mimeType.startsWith('image/') ? '📷 صورة' : '📎 ملف';
        if (_isPharmacyOwner) {
          _notifyUser(notificationText);
        } else {
          _notifyPharmacy(notificationText);
        }
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
    if (_isPharmacyOwner) {
      _notifyUser(message.text);
    } else {
      _notifyPharmacy(message.text);
    }
  }
  Future<void> _notifyPharmacy(String text) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userDoc = await FirebaseFirestore.instance.collection('pharmacy_users').doc(user.uid).get();
    final userName = userDoc.data()?['name'] ?? 'زبون';
    http.post(Uri.parse('${ApiConstants.PHARMACY_API_URL}/chats/notify_pharmacy'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({
      'pharmacy_id': widget.pharmacyId,
      'user_name': userName,
      'message_text': text,
      'firebase_uid': user.uid,
    }));
  }
  Future<void> _notifyUser(String text) async {
    http.post(Uri.parse('${ApiConstants.PHARMACY_API_URL}/pharmacy/notify_user'), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${_authProvider.token}'}, body: jsonEncode({
      'pharmacy_name': _authProvider.pharmacyName,
      'message_text': text,
      'user_firebase_uid': widget.customerUid,
    }));
  }
  @override
  Widget build(BuildContext context) {
    final chatTitle = _isPharmacyOwner ? 'محادثة مع ${widget.customerName}' : widget.pharmacyName;
    return Scaffold(
      appBar: AppBar(title: Text(chatTitle)),
      body: Chat(
        messages: _messages,
        onSendPressed: _handleSendPressed,
        onAttachmentPressed: _handleAttachmentPressed,
        user: _chatUser,
        theme: DefaultChatTheme(
          primaryColor: Theme.of(context).primaryColor,
          secondaryColor: const Color(0xFFE3F2FD),
          inputBackgroundColor: Colors.white,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          inputTextColor: Colors.black87,
          sentMessageBodyTextStyle: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Cairo'),
          receivedMessageBodyTextStyle: const TextStyle(color: Colors.black87, fontSize: 16, fontFamily: 'Cairo'),
        ),
        l10n: const ChatL10nEn(inputPlaceholder: 'اكتب استفسارك هنا...', fileButtonAccessibilityLabel: 'إرسال ملف', attachmentButtonAccessibilityLabel: ''),
        emptyState: const Center(child: Text('ابدأ محادثتك')),
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
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SubscriptionSuccessScreen()),
        );
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
            TextFormField(controller: _illnessController, decoration: const InputDecoration(labelText: 'نوع المرض (مثال: سكري، ضغط)', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null),
            const SizedBox(height: 30),
            _isLoading ? const Center(child: CircularProgressIndicator()) : ElevatedButton(onPressed: _submit, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), textStyle: const TextStyle(fontSize: 16, fontFamily: 'Cairo', fontWeight: FontWeight.bold)), child: const Text('إرسال الطلب')),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline_rounded,
                  color: Colors.green, size: 100),
              const SizedBox(height: 24),
              Text(
                'تم استلام طلبك بنجاح!',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'سوف يتم الاتصال بك قريباً من قبل الصيدلية المعتمدة في منطقتك للتمتع بخصومات وعروض خاصة.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                ),
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('العودة إلى الرئيسية'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ---
// --- Screens: Pharmacy Owner ---
// ---
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
      appBar: AppBar(title: Text(authProvider.pharmacyName ?? 'لوحة التحكم'), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => Provider.of<AuthProvider>(context, listen: false).logout())]),
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
  Map<String, List<Order>>? _orders;
  bool _isLoading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }
  Future<void> _fetchDashboardData() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _error = null; });
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuth) return;
    final url = Uri.parse('${ApiConstants.PHARMACY_API_URL}/pharmacy/dashboard');
    try {
      final response = await http.get(url, headers: {'Authorization': 'Bearer ${authProvider.token}'});
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final extractedData = json.decode(response.body) as Map<String, dynamic>;
        final ordersData = extractedData['orders'] as Map<String, dynamic>;
        final Map<String, List<Order>> loadedOrders = {};
        ordersData.forEach((status, ordersList) {
          loadedOrders[status] = (ordersList as List).map((orderData) => Order.fromJson(orderData)).toList();
        });
        if (mounted) setState(() => _orders = loadedOrders);
      } else {
        throw Exception('فشل في تحميل البيانات من الخادم. رمز الحالة: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          bottom: const TabBar(tabs: [Tab(text: 'جديدة'), Tab(text: 'مكتملة'), Tab(text: 'ملغية')]),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(child: Text('Error: $_error'))
            : TabBarView(
          children: [PharmacyOrdersList(orders: _orders?['processing'] ?? [], onRefresh: _fetchDashboardData), PharmacyOrdersList(orders: _orders?['completed'] ?? [], onRefresh: _fetchDashboardData), PharmacyOrdersList(orders: _orders?['cancelled'] ?? [], onRefresh: _fetchDashboardData)],
        ),
      ),
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
      return Center(child: Text('لا توجد طلبات في هذه الفئة حالياً.', style: TextStyle(color: Colors.grey.shade600)));
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
  List<SubscriptionRequest>? _subscriptions;
  bool _isLoading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }
  Future<void> _fetchDashboardData() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _error = null; });
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuth) return;
    final url = Uri.parse('${ApiConstants.PHARMACY_API_URL}/pharmacy/dashboard');
    try {
      final response = await http.get(url, headers: {'Authorization': 'Bearer ${authProvider.token}'});
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final extractedData = json.decode(response.body) as Map<String, dynamic>;
        final subscriptionsData = extractedData['subscriptions'] as List;
        if (mounted) {
          setState(() {
            _subscriptions = subscriptionsData.map((data) => SubscriptionRequest.fromJson(data)).toList();
          });
        }
      } else {
        throw Exception('فشل في تحميل البيانات من الخادم. رمز الحالة: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text('Error: $_error'))
          : RefreshIndicator(
        onRefresh: _fetchDashboardData,
        child: _subscriptions == null || _subscriptions!.isEmpty
            ? Center(child: Text('لا توجد طلبات اشتراك حالياً.', style: TextStyle(color: Colors.grey.shade600)))
            : ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          itemCount: _subscriptions!.length,
          itemBuilder: (ctx, i) => SubscriptionCard(subscription: _subscriptions![i]),
        ),
      ),
    );
  }
}

// [MODIFIED] Chat list page to show unread badges.
class PharmacyChatListPage extends StatefulWidget {
  const PharmacyChatListPage({super.key});
  @override
  _PharmacyChatListPageState createState() => _PharmacyChatListPageState();
}
class _PharmacyChatListPageState extends State<PharmacyChatListPage> {
  List<Conversation> _conversations = [];
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    _fetchConversations();
  }
  Future<void> _fetchConversations() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final url = Uri.parse('${ApiConstants.PHARMACY_API_URL}/pharmacy/conversations');
    try {
      final response = await http.get(url, headers: {'Authorization': 'Bearer ${authProvider.token}'});
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) setState(() => _conversations = data.map((c) => Conversation.fromJson(c)).toList());
      } else {
        throw Exception("Failed to fetch conversations");
      }
    } catch (e) {
      // Handle error
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
          : RefreshIndicator(
        onRefresh: _fetchConversations,
        child: _conversations.isEmpty
            ? Center(child: Text('لا توجد محادثات بعد.', style: TextStyle(color: Colors.grey.shade600)))
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
                        badges.Badge(
                          badgeContent: Text(convo.unreadCount.toString(), style: const TextStyle(color: Colors.white)),
                        ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_ios),
                    ],
                  ),
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(pharmacyId: authProvider.pharmacyId!, pharmacyName: authProvider.pharmacyName!, customerUid: convo.uid, customerName: convo.name)));
                    // Refresh the list to update the unread count after returning from chat
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
  // [MODIFIED] Show a local notification for background messages
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
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'الصيدليات ',
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
        ),
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
      ),
    );
  }
}
