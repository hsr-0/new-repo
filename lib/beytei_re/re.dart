import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';



import 'dart:math'; // 👈 تأكد من وجود هذا السطر ضروري جداً
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/services.dart'; // مطلوب للاهتزاز
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:shimmer/shimmer.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:image_picker/image_picker.dart';
import '../main.dart';
import 'OrderTracking.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart'; // أضف هذه المكتبة في pubspec.yaml
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

// =======================================================================
// --- إعدادات وثوابت عامة للوحدة ---
// =======================================================================
const String BEYTEI_URL = 'https://re.beytei.com';
const String CONSUMER_KEY = 'ck_d22c789681c4610838f1d39a05dbedcb73a2c810';
const String CONSUMER_SECRET = 'cs_78b90e397bbc2a8f5f5092cca36dc86e55c01c07';
const Duration API_TIMEOUT = Duration(seconds: 30);
const String CACHE_HOME_DATA_KEY = 'cache_home_data_area_'; // سنضيف رقم المنطقة
const String CACHE_RESTAURANTS_KEY = 'cache_all_restaurants_area_';
const String MISWAK_URL = 'https://beytei.com';    // 🔥 سيرفر المسواك (جديد)
const String TAXI_URL = 'https://banner.beytei.com'; // 🚕 تكسي )
const int AD_PRODUCT_ID = 9999; // ⚠️ استبدل هذا الرقم بـ ID منتج "خدمة إعلان" من ووكومرس
const double AD_COST = 3000.0; // تكلفة الإعلان


class AppConstants {

  // مفاتيح الكاش (للزبون فقط)
  static const String CACHE_KEY_RESTAURANTS_PREFIX = 'cache_restaurants_area_';
  static const String CACHE_KEY_MENU_PREFIX = 'cache_menu_restaurant_';
  static const String CACHE_TIMESTAMP_PREFIX = 'cache_time_';
}
// 🔥 أضف هذا السطر في البداية لتعريف المفتاح عالمياً
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  final messageType = message.data['type'];

  // 📞 مكالمات VoIP
  if (messageType == 'voip_call') {
    final channelName = message.data['channel_name'];
    final driverName = message.data['driver_name'] ?? 'الكابتن';
    final orderId = message.data['order_id'];

    await SharedPreferences.getInstance().then((prefs) async {
      await prefs.setString('pending_call_channel', channelName ?? '');
      await prefs.setString('pending_call_driver', driverName);
      await prefs.setString('pending_call_order', orderId ?? '');
      await prefs.setBool('pending_call_available', true);
    });

    await NotificationService.display(message);
    return;
  }

  // 🔄 تحديث ملف التسعير
  if (messageType == 'refresh_delivery_config') {
    print("📡 [SilentPush] استلام إشارة تحديث ملف التسعير...");
    final configProvider = DeliveryConfigProvider();
    await configProvider.fetchAndCacheConfig();
    return;
  }

  // ❌ إشعار إلغاء الطلب من السائق (في الخلفية)
  if (messageType == 'driver_cancelled_order') {
    final orderId = message.data['order_id'] ?? 'غير معروف';
    print("🚨 [Background] تم إلغاء الطلب #$orderId من قبل السائق");

    // عرض إشعار محلي فوري للتيم ليدر
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'high_importance_channel',
        'إشعارات الطلبات العاجلة',
        channelDescription: 'تنبيه عند إلغاء طلب من السائق',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('woo_sound'),
        enableVibration: true,
      ),
    );

    await FlutterLocalNotificationsPlugin().show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '⚠️ إلغاء طلب!',
      'المندوب قام بإلغاء الطلب #$orderId. راجع لوحة تحكم الطلبات.',
      details,
      payload: orderId,
    );
    return;
  }

  // 📬 باقي الإشعارات العادية
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


class ZoneRide {
  final int id;
  final String pickupLocation;
  final String destination;
  final double amount;
  final int status;
  final String customerName;
  final String customerPhone;
  final String? driverName;
  final String? driverPhone;
  final String? createdAt; // 🔥 الحقل الجديد لوقت الرحلة

  // الإحداثيات
  final String? pickupLat;
  final String? pickupLng;
  final String? destLat;
  final String? destLng;

  ZoneRide({
    required this.id,
    required this.pickupLocation,
    required this.destination,
    required this.amount,
    required this.status,
    required this.customerName,
    required this.customerPhone,
    this.driverName,
    this.driverPhone,
    this.createdAt, // 🔥
    this.pickupLat,
    this.pickupLng,
    this.destLat,
    this.destLng,
  });

  factory ZoneRide.fromJson(Map<String, dynamic> json) {
    // قراءة بيانات الزبون
    final user = json['user'] ?? {};
    final customerName = "${user['firstname'] ?? ''} ${user['lastname'] ?? ''}".trim();

    // قراءة بيانات السائق (إن وجد)
    final driver = json['driver'];

    return ZoneRide(
      id: json['id'] ?? 0,
      pickupLocation: json['pickup_location'] ?? json['pickup_address'] ?? 'غير محدد',
      destination: json['destination'] ?? json['destination_address'] ?? 'غير محدد',
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      status: int.tryParse(json['status'].toString()) ?? 0,
      customerName: customerName.isNotEmpty ? customerName : 'زبون',
      customerPhone: user['mobile'] ?? 'لا يوجد رقم',
      driverName: driver != null ? "${driver['firstname'] ?? ''} ${driver['lastname'] ?? ''}".trim() : null,
      driverPhone: driver != null ? driver['mobile'] : null,

      // 🔥 قراءة وقت إنشاء الرحلة من السيرفر
      createdAt: json['created_at'],

      // قراءة الإحداثيات
      pickupLat: json['pickup_latitude']?.toString(),
      pickupLng: json['pickup_longitude']?.toString(),
      destLat: json['destination_latitude']?.toString(),
      destLng: json['destination_longitude']?.toString(),
    );
  }
}

class TeamLeaderZoneRidesScreen extends StatefulWidget {
  const TeamLeaderZoneRidesScreen({super.key});

  @override
  State<TeamLeaderZoneRidesScreen> createState() => _TeamLeaderZoneRidesScreenState();
}

class _TeamLeaderZoneRidesScreenState extends State<TeamLeaderZoneRidesScreen> {
  late Future<List<ZoneRide>> _ridesFuture;
  final ApiService _apiService = ApiService();
  String _zoneName = "منطقتي";

  @override
  void initState() {
    super.initState();
    // إعداد اللغة العربية لمكتبة timeago لمرة واحدة عند تشغيل الشاشة
    timeago.setLocaleMessages('ar', timeago.ArMessages());
    _loadData();
  }

  void _loadData() {
    setState(() {
      _ridesFuture = _fetchRides();
    });
  }

  // 🔥 دالة ذكية لتنسيق الوقت (منذ 5 دقائق + الساعة الفعلية)
  String _formatRideTime(String? createdAt) {
    if (createdAt == null || createdAt.isEmpty) return "وقت غير محدد";

    try {
      // تحويل النص إلى DateTime (السيرفر يرسل UTC عادةً لذا نحوله لـ Local)
      DateTime dateTime = DateTime.parse(createdAt).toLocal();

      // الحصول على صيغة "منذ..."
      String ago = timeago.format(dateTime, locale: 'ar');

      // الحصول على الساعة الفعلية
      String clock = DateFormat('hh:mm a', 'ar').format(dateTime);

      return "$ago ($clock)";
    } catch (e) {
      return "خطأ في الوقت";
    }
  }

  Future<List<ZoneRide>> _fetchRides() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('taxi_monitoring_token');
    final zoneId = prefs.getInt('leader_zone_id');
    final zName = prefs.getString('leader_zone_name');

    if (zName != null) {
      setState(() => _zoneName = zName);
    }

    if (token == null || zoneId == null) {
      throw Exception("بيانات الدخول غير مكتملة، يرجى تسجيل الدخول مجدداً.");
    }

    return await _apiService.getTeamLeaderZoneRides(token, zoneId);
  }

  Future<void> _makePhoneCall(String phone) async {
    if (phone.isEmpty || phone == 'لا يوجد رقم') return;
    final Uri launchUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _openMapRoute(String? pLat, String? pLng, String? dLat, String? dLng) async {
    if (pLat == null || pLng == null || dLat == null || dLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الإحداثيات غير متوفرة لهذه الرحلة.')),
      );
      return;
    }
    final String url = 'https://www.google.com/maps/dir/?api=1&origin=$pLat,$pLng&destination=$dLat,$dLng&travelmode=driving';
    final Uri launchUri = Uri.parse(url);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    }
  }

  void _notifyDriver(int rideId, String? driverName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم إرسال تنبيه للسائق $driverName (قيد الربط مع السيرفر)'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildStatusBadge(int status) {
    switch (status) {
      case 0: return _badge("معلقة", Colors.orange);
      case 1:
      case 2: return _badge("مقبولة", Colors.blue);
      case 9: return _badge("ملغاة", Colors.red);
      default: return _badge("مكتملة", Colors.green);
    }
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("مراقبة رحلات التكسي", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(_zoneName, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor: const Color(0xFF1E3C72),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: FutureBuilder<List<ZoneRide>>(
          future: _ridesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("خطأ: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
            }

            final rides = snapshot.data ?? [];
            if (rides.isEmpty) {
              return const Center(child: Text("لا توجد رحلات في منطقتك حالياً.", style: TextStyle(fontSize: 16)));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: rides.length,
              itemBuilder: (context, index) {
                final ride = rides[index];
                final hasDriver = ride.driverName != null;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // الرأس: الحالة والسعر + الوقت المنقضي
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("#${ride.id}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                                const SizedBox(height: 2),
                                // 🔥 عرض الوقت (منذ X دقيقة)
                                Text(
                                  _formatRideTime(ride.createdAt),
                                  style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            _buildStatusBadge(ride.status),
                            Text("${ride.amount} د.ع", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
                          ],
                        ),
                        const Divider(height: 20),

                        // معلومات الزبون
                        Row(
                          children: [
                            const Icon(Icons.person, color: Colors.blueGrey, size: 20),
                            const SizedBox(width: 8),
                            Expanded(child: Text("${ride.customerName} - ${ride.customerPhone}", style: const TextStyle(fontWeight: FontWeight.bold))),
                            IconButton(
                              icon: const Icon(Icons.call, color: Colors.green),
                              onPressed: () => _makePhoneCall(ride.customerPhone),
                            )
                          ],
                        ),

                        // معلومات السائق
                        Row(
                          children: [
                            const Icon(Icons.local_taxi, color: Colors.orange, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                hasDriver ? "الكابتن: ${ride.driverName} - ${ride.driverPhone}" : "لا يوجد سائق حتى الآن",
                                style: TextStyle(fontWeight: FontWeight.bold, color: hasDriver ? Colors.indigo : Colors.grey),
                              ),
                            ),
                            if (hasDriver && ride.driverPhone != null)
                              IconButton(
                                icon: const Icon(Icons.call, color: Colors.green),
                                onPressed: () => _makePhoneCall(ride.driverPhone!),
                              )
                          ],
                        ),
                        const Divider(height: 20),

                        // أزرار العمليات
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.map, size: 18),
                                label: const Text("المسار", style: TextStyle(fontSize: 12)),
                                onPressed: () => _openMapRoute(ride.pickupLat, ride.pickupLng, ride.destLat, ride.destLng),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.notifications_active, size: 18),
                                label: const Text("تنبيه الكابتن", style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                                onPressed: hasDriver ? () => _notifyDriver(ride.id, ride.driverName) : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}


class AuthProvider with ChangeNotifier {
  String? _token;       // توكن سيرفر المطاعم (re.beytei.com)
  String? _miswakToken; // 🔥 توكن سيرفر المسواك (beytei.com)
  String? _taxiToken;   // 🚕 توكن سيرفر التاكسي (banner.beytei.com)
  String? _userRole;    // 'owner' أو 'leader'
  bool _isLoading = true;

  // Getters
  String? get token => _token;
  String? get miswakToken => _miswakToken;
  String? get taxiToken => _taxiToken; // Getter جديد للتاكسي
  String? get userRole => _userRole;
  bool get isLoading => _isLoading;

  // يعتبر مسجل دخول إذا نجح الدخول للسيرفر الرئيسي (المطاعم) على الأقل
  bool get isLoggedIn => _token != null;

  AuthProvider() {
    _checkLoginStatus();
  }

  // استرجاع البيانات عند فتح التطبيق
  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token');
    _miswakToken = prefs.getString('miswak_jwt_token');
    _taxiToken = prefs.getString('taxi_jwt_token'); // 🔥 استرجاع توكن التاكسي
    _userRole = prefs.getString('user_role');
    _isLoading = false;
    notifyListeners();
  }

  // 🔥 دالة تسجيل الدخول الموحدة (المطورة)
// 🔥 دالة تسجيل الدخول الموحدة (مطاعم + مسواك + سائقين Banner)
  Future<bool> login(String username, String password, String role, {String? restaurantLat, String? restaurantLng}) async {
    final authService = AuthService();
    _token = await authService.loginToServer(BEYTEI_URL, username, password);

    if (role == 'leader') {
      try {
        _miswakToken = await authService.loginToServer(MISWAK_URL, username, password);
      } catch (e) {}

      // 🔥 تسجيل دخول Banner لكي تعمل شاشة "فريقي"
      try {
        _taxiToken = await authService.loginToTaxiServer(username, password);
      } catch (e) {}
    }

    if (_token != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', _token!);
      await prefs.setString('user_role', role);

      if (_miswakToken != null) await prefs.setString('miswak_jwt_token', _miswakToken!);
      if (_taxiToken != null) await prefs.setString('taxi_jwt_token', _taxiToken!); // هذا للـ Banner

      await authService.registerDeviceTokenTriple(_token, _miswakToken, _taxiToken);

      notifyListeners();
      return true;
    }
    return false;
  }
  // تسجيل الخروج
  Future<void> logout(BuildContext context) async {
    final authService = AuthService();

    // إرسال طلب الخروج للسيرفر
    await authService.logout();

    // تصفير المتغيرات
    _token = null;
    _miswakToken = null;
    _taxiToken = null; // تصفير التاكسي
    _userRole = null;

    // مسح البيانات من الذاكرة المحلية
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('miswak_jwt_token');
    await prefs.remove('taxi_jwt_token'); // 🔥 حذف توكن التاكسي من الذاكرة
    await prefs.remove('user_role');

    // تنظيف البيانات من البروفايدرات الأخرى إذا كان السياق متاحاً
    if (context.mounted) {
      // تنظيف بيانات المطاعم والزبائن (اختياري حسب هيكلة تطبيقك)
      try {
        Provider.of<CustomerProvider>(context, listen: false).clearData();
        Provider.of<RestaurantSettingsProvider>(context, listen: false).clearData();
      } catch (e) {
        print("Note: Could not clear other providers (safe to ignore on logout).");
      }
    }

    notifyListeners();
  }


// 🔥 دالة تسجيل الدخول المخصصة للتيم ليدر (مراقبة التكسي)
// 🔥 دالة مخصصة فقط لسيرفر المراقبة الحية (taxi.beytei.com)
// 🔥 دالة مخصصة فقط لسيرفر المراقبة الحية (taxi.beytei.com)
  Future<bool> loginTeamLeader(String username, String password) async {
    final url = 'https://taxi.beytei.com/team-leader-login';
    _isLoading = true;
    // نستخدم microtask لتجنب تضارب التحديث مع بناء الواجهة
    Future.microtask(() => notifyListeners());

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: json.encode({'username': username, 'password': password}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        print("📥 [رد السيرفر عند تسجيل الدخول]: ${response.body}");

        final data = json.decode(response.body);
        if (data['status'] == 'success' || data['token'] != null) {
          final prefs = await SharedPreferences.getInstance();

          await prefs.setString('taxi_monitoring_token', data['token']);

          // حماية آمنة لقراءة الـ zone_id سواء كان نص أو رقم
          int zoneId = 0;
          if (data['user'] != null && data['user']['zone_id'] != null) {
            zoneId = int.tryParse(data['user']['zone_id'].toString()) ?? 0;
          }
          await prefs.setInt('leader_zone_id', zoneId);

          String zoneName = data['user'] != null ? (data['user']['name'] ?? 'منطقتي') : 'منطقتي';
          await prefs.setString('leader_zone_name', zoneName);

          // 🔥🔥🔥 التعديل الجديد: الاشتراك في إشعارات المنطقة 🔥🔥🔥
          try {
            if (zoneId != 0) { // نتأكد أن المنطقة صحيحة وليست 0
              await FirebaseMessaging.instance.subscribeToTopic('taxi_zone_$zoneId');
              print("🔔 [FCM] تم الاشتراك بنجاح في إشعارات المنطقة: taxi_zone_$zoneId");
            }
          } catch (e) {
            print("⚠️ [FCM] فشل الاشتراك في الإشعارات: $e");
          }
          // 🔥🔥🔥 نهاية التعديل 🔥🔥🔥

          _isLoading = false;
          notifyListeners();
          return true;
        }
      }

      print("⚠️ فشل الدخول للسيرفر: ${response.body}");
      _isLoading = false;
      notifyListeners();
      return false;

    } catch (e) {
      print("❌ خطأ في الاتصال بسيرفر التكسي: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

}




class CustomerProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  Map<String, List<dynamic>> _homeData = {};
  List<Restaurant> _allRestaurants = [];
  Map<int, List<FoodItem>> _menuItems = {};

  // قائمة العروض النشطة
  List<Offer> _activeOffers = [];

  int _lastLoadedAreaId = -1;
  bool _isLoadingHome = false;
  bool _isLoadingMenu = false;
  bool _hasError = false;

  // --- Getters ---
  Map<String, List<dynamic>> get homeData => _homeData;
  List<Restaurant> get allRestaurants => _allRestaurants;
  Map<int, List<FoodItem>> get menuItems => _menuItems;
  List<Offer> get activeOffers => _activeOffers;

  bool get isLoadingHome => _isLoadingHome;
  bool get isLoadingRestaurants => _isLoadingHome;
  bool get isLoadingMenu => _isLoadingMenu;
  bool get hasError => _hasError;

  // --- Clear Data ---
  void clearData() {
    _homeData = {};
    _allRestaurants = [];
    _menuItems = {};
    _activeOffers = [];
    _lastLoadedAreaId = -1;
    _hasError = false;
    notifyListeners();
  }

  // ============================================================
  // 🔥 دالة جلب العروض (On Sale Items)
  // ============================================================
  Future<void> fetchOffers(int areaId) async {
    try {
      print("🔄 جاري جلب العروض وتصفيتها حسب المنطقة: $areaId...");

      final rawItems = await _apiService.getOnSaleItems();
      final Set<int> deliverableRestaurantIds = await _apiService.getDeliverableRestaurantIds(areaId);

      final filteredItems = rawItems.where((item) {
        final isAllowed = deliverableRestaurantIds.contains(item.categoryId);
        return isAllowed;
      }).toList();

      _activeOffers = filteredItems.map((item) {
        String cleanDesc = item.description.replaceAll(RegExp(r'<[^>]*>|&nbsp;'), '').trim();
        return Offer(
          id: item.id,
          restaurantId: item.categoryId,
          title: item.name,
          description: cleanDesc.isNotEmpty ? cleanDesc : '🔥 عرض مميز لفترة محدودة!',
          imageUrl: item.imageUrl,
          price: item.displayPrice,
        );
      }).toList();

      notifyListeners();
      print("✅ تم جلب وتصفية ${_activeOffers.length} عرض خاص بالمنطقة $areaId.");

    } catch (e) {
      print("⚠️ خطأ في جلب العروض: $e");
      _activeOffers = [];
      notifyListeners();
    }
  }

  // ============================================================
  // 1. جلب بيانات الصفحة الرئيسية (المطاعم) - 🔥 النظام الهجين الذكي
  // ============================================================
  Future<void> fetchHomeData(int areaId, {bool isRefresh = false}) async {
    _lastLoadedAreaId = areaId;
    _hasError = false;

    // 🔥 أ) محاولة العرض الفوري من الكاش (حتى لو كان قديماً)
    if (!isRefresh) {
      bool isCacheAvailable = await _isCacheValid('${AppConstants.CACHE_TIMESTAMP_PREFIX}home_$areaId', minutes: 2);

      if (isCacheAvailable) {
        await _loadHomeFromCache(areaId);

        if (_allRestaurants.isNotEmpty) {
          print("🚀 عرض فوري للبيانات من الكاش (مع فحص خلفي للحالة)");
          _isLoadingHome = false;
          notifyListeners();

          // 🔥 إطلاق الفحص الخلفي السريع (لتحديث حالة الفتح/الإغلاق)
          _updateStatusesInBackground();
          return;
        }
      }
    }

    if (_homeData.isEmpty) {
      _isLoadingHome = true;
      notifyListeners();
    }

    try {
      final results = await Future.wait([
        _apiService.getRawDeliverableIds(areaId),
        _apiService.getRawRestaurants(areaId),
      ]);

      final deliverableJson = results[0];
      final restaurantsJson = results[1];

      _processAndSetHomeData(deliverableJson, restaurantsJson);
      await _saveHomeToCache(areaId, deliverableJson, restaurantsJson);

    } catch (e) {
      print("⚠️ فشل تحديث المطاعم من الشبكة: $e");
      if (_homeData.isEmpty) _hasError = true;
    } finally {
      _isLoadingHome = false;
      notifyListeners();
    }
  }

  // ============================================================
  // 🔥🔥🔥 دالة الفحص الخلفي الذكية (تحديث الحالة دون إزعاج الزبون) 🔥🔥🔥
  // ============================================================
  Future<void> _updateStatusesInBackground() async {
    if (_allRestaurants.isEmpty) return;

    try {
      print("🕵️ [Background Check] فحص حالة المطاعم في الخلفية...");

      List<int> ids = _allRestaurants.map((r) => r.id).toList();
      final statuses = await _apiService.checkRestaurantsStatusLight(ids);

      bool somethingChanged = false;

      for (var status in statuses) {
        final int id = status['id'];
        final bool serverIsOpen = status['is_open'] == true;
        final String newAutoOpen = status['auto_open'] ?? '09:00';
        final String newAutoClose = status['auto_close'] ?? '22:00';

        final index = _allRestaurants.indexWhere((r) => r.id == id);

        if (index != -1) {
          if (_allRestaurants[index].isOpen != serverIsOpen) {
            print("🔄 تحديث حالة المطعم ${_allRestaurants[index].name}: من ${_allRestaurants[index].isOpen} إلى $serverIsOpen");

            _allRestaurants[index] = Restaurant(
              id: _allRestaurants[index].id,
              name: _allRestaurants[index].name,
              imageUrl: _allRestaurants[index].imageUrl,
              isDeliverable: _allRestaurants[index].isDeliverable,
              averageRating: _allRestaurants[index].averageRating,
              ratingCount: _allRestaurants[index].ratingCount,
              latitude: _allRestaurants[index].latitude,
              longitude: _allRestaurants[index].longitude,
              isOpen: serverIsOpen,
              autoOpenTime: newAutoOpen,
              autoCloseTime: newAutoClose,
              storeType: _allRestaurants[index].storeType, // تمرير النوع
            );

            somethingChanged = true;
          }
        }
      }

      if (somethingChanged) {
        _homeData['restaurants'] = _allRestaurants;
        notifyListeners();
      }

    } catch (e) {
      print("⚠️ فشل الفحص الخلفي (غير مؤثر على العرض): $e");
    }
  }

  // ============================================================
  // 🔥 [NEW] دالة تحديث حالة مطعم واحد (تستخدم للفحص الفوري)
  // ============================================================
  void updateSingleRestaurantStatus(int id, bool isOpen, String? autoOpen, String? autoClose) {
    final index = _allRestaurants.indexWhere((r) => r.id == id);

    if (index != -1) {
      _allRestaurants[index] = Restaurant(
        id: _allRestaurants[index].id,
        name: _allRestaurants[index].name,
        imageUrl: _allRestaurants[index].imageUrl,
        isDeliverable: _allRestaurants[index].isDeliverable,
        averageRating: _allRestaurants[index].averageRating,
        ratingCount: _allRestaurants[index].ratingCount,
        latitude: _allRestaurants[index].latitude,
        longitude: _allRestaurants[index].longitude,
        isOpen: isOpen,
        autoOpenTime: autoOpen ?? _allRestaurants[index].autoOpenTime,
        autoCloseTime: autoClose ?? _allRestaurants[index].autoCloseTime,
        storeType: _allRestaurants[index].storeType, // تمرير النوع
      );

      _homeData['restaurants'] = _allRestaurants;
      notifyListeners();
    }
  }

  // --- دالة لجلب كل المطاعم ---
  Future<void> fetchAllRestaurants(int areaId, {bool isRefresh = false}) async {
    await fetchHomeData(areaId, isRefresh: isRefresh);
  }

  // --- معالجة JSON المطاعم ---
  void _processAndSetHomeData(String deliverableJson, String restaurantsJson) {
    try {
      final deliverableList = json.decode(deliverableJson) as List;
      final Set<int> deliverableIds = deliverableList.map<int>((item) => item['id']).toSet();

      final restaurantsList = json.decode(restaurantsJson) as List;

      List<Restaurant> parsedRestaurants = restaurantsList.map((jsonObj) {
        // 🔥🔥🔥 سطر الفحص الذكي لمعرفة ما إذا كان الـ API يرسل البيانات بشكل صحيح 🔥🔥🔥
        print("🕵️ فحص المتجر: ${jsonObj['name']} | نوعه القادم من السيرفر: ${jsonObj['beytei_store_type']}");
        return Restaurant.fromJson(jsonObj);
      }).toList();

      for (var r in parsedRestaurants) {
        r.isDeliverable = deliverableIds.contains(r.id);
      }

      _allRestaurants = parsedRestaurants;
      _homeData['restaurants'] = parsedRestaurants;

    } catch (e) {
      print("Error parsing home data: $e");
      throw Exception('Data parsing error');
    }
  }

  // --- تحميل المطاعم من الكاش ---
  Future<void> _loadHomeFromCache(int areaId) async {
    final prefs = await SharedPreferences.getInstance();
    final deliverableJson = prefs.getString('${AppConstants.CACHE_KEY_RESTAURANTS_PREFIX}${areaId}_ids');
    final restaurantsJson = prefs.getString('${AppConstants.CACHE_KEY_RESTAURANTS_PREFIX}${areaId}_list');

    if (deliverableJson != null && restaurantsJson != null) {
      try {
        _processAndSetHomeData(deliverableJson, restaurantsJson);
        notifyListeners();
      } catch (e) {
        print("خطأ في قراءة كاش المطاعم: $e");
      }
    }
  }

  // --- حفظ المطاعم في الكاش ---
  Future<void> _saveHomeToCache(int areaId, String deliverableJson, String restaurantsJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${AppConstants.CACHE_KEY_RESTAURANTS_PREFIX}${areaId}_ids', deliverableJson);
    await prefs.setString('${AppConstants.CACHE_KEY_RESTAURANTS_PREFIX}${areaId}_list', restaurantsJson);
    await prefs.setInt('${AppConstants.CACHE_TIMESTAMP_PREFIX}home_$areaId', DateTime.now().millisecondsSinceEpoch);
  }

  // ============================================================
  // 2. جلب قائمة الطعام (المنيو)
  // ============================================================
  Future<void> fetchMenuForRestaurant(int restaurantId, {bool isRefresh = false}) async {
    _hasError = false;

    if (!isRefresh && !_menuItems.containsKey(restaurantId)) {
      await _loadMenuFromCache(restaurantId);
    }

    if (!_menuItems.containsKey(restaurantId)) {
      _isLoadingMenu = true;
      notifyListeners();
    }

    if (!isRefresh && _menuItems.containsKey(restaurantId) && await _isCacheValid('${AppConstants.CACHE_TIMESTAMP_PREFIX}menu_$restaurantId', minutes: 600)) {
      print("✅ استخدام الكاش للمنيو (البيانات حديثة)");
      _isLoadingMenu = false;
      notifyListeners();
      return;
    }

    try {
      final jsonStr = await _apiService.getRawMenu(restaurantId);
      _processAndSetMenu(restaurantId, jsonStr);
      await _saveMenuToCache(restaurantId, jsonStr);
    } catch (e) {
      print("⚠️ فشل تحديث المنيو من الشبكة: $e");
      if (!_menuItems.containsKey(restaurantId)) {
        _hasError = true;
        _menuItems[restaurantId] = [];
      }
    } finally {
      _isLoadingMenu = false;
      notifyListeners();
    }
  }

  void _processAndSetMenu(int restaurantId, String jsonStr) {
    try {
      final List<dynamic> decoded = json.decode(jsonStr);
      List<FoodItem> items = decoded.map((jsonObj) => FoodItem.fromJson(jsonObj)).toList();

      Restaurant? restaurant = _allRestaurants.firstWhere(
              (r) => r.id == restaurantId,
          orElse: () => Restaurant(id: 0, name: '', imageUrl: '', isOpen: false, autoOpenTime: '', autoCloseTime: '', latitude: 0, longitude: 0)
      );

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

  Future<void> _saveMenuToCache(int restaurantId, String jsonStr) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${AppConstants.CACHE_KEY_MENU_PREFIX}$restaurantId', jsonStr);
    await prefs.setInt('${AppConstants.CACHE_TIMESTAMP_PREFIX}menu_$restaurantId', DateTime.now().millisecondsSinceEpoch);
  }

  // ============================================================
  // 3. دوال مساعدة عامة
  // ============================================================
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
  Timer? _debounceTimer;

  Map<String, List<Order>> get orders => _orders;
  RestaurantRatingsDashboard? get ratingsDashboard => _ratingsDashboard;
  Map<int, String> get pickupCodes => _pickupCodes;
  bool get isLoading => _isLoading;

  void triggerSmartRefresh(String token) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(seconds: 3), () {
      fetchDashboardData(token, silent: true);
    });
  }

  void startAutoRefresh(String token) {
    _timer?.cancel();
    fetchDashboardData(token, silent: true);
  }

  void stopAutoRefresh() {
    _timer?.cancel();
    _debounceTimer?.cancel();
  }

  void setPickupCode(int orderId, String code) {
    _pickupCodes[orderId] = code;
    notifyListeners();
  }

  Future<void> fetchDashboardData(String? token, {bool silent = false}) async {
    if (token == null) return;
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }
    try {
      final ApiService api = ApiService();

      // 1. جلب الكل من سيرفر المطعم الأساسي
      final activeFromServer = await api.getRestaurantOrders(status: 'active', token: token);
      final completedFromServer = await api.getRestaurantOrders(status: 'completed', token: token);

      List<Order> allOrders = [...activeFromServer, ...completedFromServer];
      final ids = <int>{};
      allOrders.retainWhere((x) => ids.add(x.id));

      List<Order> finalActive = [];
      List<Order> finalCompleted = [];

      // 🔥 التعديل الجذري: هنا أضفنا حالات الاستلام والتوصيل لكي تنتقل للمكتملة وتختفي من النشطة 🔥
      final List<String> archiveStatuses = [
        'completed',
        'cancelled',
        'refunded',
        'failed',
        'trash',
        'picked_up',        // الكابتن استلم الطلب من المطعم
        'out-for-delivery', // في الطريق للزبون
        'delivered'         // تم التوصيل
      ];

      for (var order in allOrders) {
        if (!archiveStatuses.contains(order.status.toLowerCase())) {
          finalActive.add(order);
        } else {
          finalCompleted.add(order);
        }
      }

      // =================================================================
      // 🔥 الخدعة الذكية: جلب بيانات السائق من التكسي للطلبات النشطة 🔥
      // =================================================================
      List<Order> syncedActiveOrders = [];

      for (var order in finalActive) {
        try {
          // اتصال سريع ومفتوح بسيرفر التكسي لجلب الحالة الحية واسم السائق
          final response = await http.get(
              Uri.parse('https://banner.beytei.com/wp-json/taxi/v2/delivery/status-by-source/${order.id}')
          ).timeout(const Duration(seconds: 3));

          if (response.statusCode == 200) {
            final data = json.decode(response.body);

            // جلب الحالة من التكسي
            String currentStatus = data['status'] ?? order.status;

            // إنشاء نسخة جديدة من الطلب بالبيانات المدمجة
            Order syncedOrder = Order(
              id: order.id,
              status: currentStatus,
              dateCreated: order.dateCreated,
              total: order.total,
              customerName: order.customerName,
              address: order.address,
              phone: order.phone,
              lineItems: order.lineItems,
              destinationLat: order.destinationLat,
              destinationLng: order.destinationLng,
              shippingTotal: order.shippingTotal,
              driverName: data['driver_name'] ?? order.driverName,
              driverPhone: data['driver_phone'] ?? order.driverPhone,
            );

            // 🛑 فحص أخير: إذا أصبحت الحالة بعد جلبها من التكسي (تم الاستلام)، ننقلها للمكتملة
            if (archiveStatuses.contains(currentStatus.toLowerCase())) {
              finalCompleted.add(syncedOrder);
            } else {
              syncedActiveOrders.add(syncedOrder);
            }
            continue;
          }
        } catch (e) {
          print("⚠️ لم نتمكن من جلب بيانات التكسي للطلب ${order.id}");
        }

        // إذا فشل الاتصال بالتكسي، نعرض الطلب كما جاء من المطعم
        syncedActiveOrders.add(order);
      }
      // =================================================================

      finalCompleted.sort((a, b) => b.dateCreated.compareTo(a.dateCreated));
      syncedActiveOrders.sort((a, b) => b.dateCreated.compareTo(a.dateCreated));

      // استخدام القوائم المحدثة والمفلترة
      _orders['active'] = syncedActiveOrders;
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
    _debounceTimer?.cancel();
    super.dispose();
  }
}







class DeliveryConfigProvider with ChangeNotifier {
  Map<String, dynamic>? _cachedConfig;
  bool _isLoading = false;
  String _errorMessage = "";

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  Map<String, dynamic>? get cachedConfig => _cachedConfig;

  Future<void> fetchAndCacheConfig() async {
    _isLoading = true;
    _errorMessage = "";
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastVersion = prefs.getInt('delivery_config_version') ?? 0;

      print("🚀 [Config] جاري جلب ملف التسعير من السيرفر...");
      final response = await http.get(
        Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/delivery-config-geo'),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final serverVersion = data['version'] ?? 0;

        if (serverVersion > lastVersion || _cachedConfig == null) {
          _cachedConfig = data;
          await prefs.setString('delivery_config_json', json.encode(data));
          await prefs.setInt('delivery_config_version', serverVersion);
          print("✅ [Config] تم تحديث ملف التسعير بنجاح (نسخة: $serverVersion)");
        } else {
          print("⚡ [Config] الملف المحلي محدث مسبقاً (نسخة: $serverVersion)");
        }
      }
    } catch (e) {
      print("⚠️ [Config] فشل جلب الملف، سيتم استخدام الكاش: $e");
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('delivery_config_json');
      if (cached != null) _cachedConfig = json.decode(cached);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 🔥 الدالة الجديدة: تحسب السعر وتطبع كيف تم الحساب في الكونسول
  Map<String, dynamic> calculateFeeDetails({
    required double userLat,
    required double userLng,
    required int restaurantId,
    required int areaId,
    required String areaName,
  }) {
    print("==================================================");
    print("📍 [Calc Start] بدأ الحساب المحلي لتسعيرة التوصيل");
    print("📍 المطعم ID: $restaurantId");
    print("📍 المنطقة: $areaName (ID: $areaId)");
    print("📍 إحداثيات الزبون: Lat: $userLat, Lng: $userLng");

    // 1. تحديد المنطقة (الكوت 84 أو الصويرة 85)
    bool isKut = (areaId == 84);
    bool isSuwaira = (areaId == 85);
    double fallbackFee = isSuwaira ? 1500.0 : (isKut ? 1500.0 : 1000.0);

    print("📍 حالة المنطقة: هل هي الكوت؟ $isKut | هل هي الصويرة؟ $isSuwaira");

    // حماية: التأكد من وجود ملف التسعير
    if (_cachedConfig == null) {
      print("⚠️ [Calc Error] ملف التسعير غير موجود! سيتم تطبيق السعر الافتراضي: $fallbackFee");
      return {'fee': fallbackFee, 'message': '📌 تسعيرة ($areaName) الموحدة (أوفلاين)'};
    }

    // حماية: إذا كان الـ GPS مغلق أو لم يتم جلبه
    if (userLat == 0.0 || userLng == 0.0) {
      print("⚠️ [Calc Error] إحداثيات الزبون صفرية! سيتم تطبيق السعر الافتراضي: $fallbackFee");
      return {'fee': fallbackFee, 'message': '📌 تم تطبيق تسعيرة ($areaName) الموحدة'};
    }

    try {
      final zones = List<Map<String, dynamic>>.from(_cachedConfig!['geo_zones'] ?? []);
      final locations = List<Map<String, dynamic>>.from(_cachedConfig!['locations'] ?? []);

      // ========================================================
      // 2. فحص المناطق المرسومة (إذا لم تكن الكوت ولم تكن الصويرة)
      // ========================================================
      if (!isKut && !isSuwaira) {
        print("🗺️ [Calc Check] جاري فحص المناطق المرسومة...");
        for (var zone in zones) {
          List<Map<String, double>> parsedPoints = [];
          var rawPoints = zone['latlngs'];

          if (rawPoints is List && rawPoints.isNotEmpty) {
            List flatList = rawPoints;
            while (flatList.isNotEmpty && flatList.first is List) {
              flatList = flatList.first;
            }
            for (var pt in flatList) {
              if (pt is Map) {
                double plat = double.tryParse(pt['lat'].toString()) ?? 0.0;
                double plng = double.tryParse(pt['lng'].toString()) ?? 0.0;
                if (plat != 0 && plng != 0) parsedPoints.add({'lat': plat, 'lng': plng});
              }
            }
          }

          if (parsedPoints.isNotEmpty && _isPointInPolygon(userLat, userLng, parsedPoints)) {
            double zonePrice = double.tryParse(zone['price'].toString()) ?? fallbackFee;
            if (zonePrice < 1000.0) zonePrice = 1000.0;
            print("✅ [Calc Success] الزبون داخل منطقة مرسومة: ${zone['name']} | السعر: $zonePrice");
            return {'fee': zonePrice, 'message': '🎯 داخل المنطقة المرسومة: ${zone['name']}'};
          }
        }
        print("ℹ️ [Calc Info] الزبون خارج جميع المناطق المرسومة، سيتم حساب المسافة...");
      }

      // ========================================================
      // 3. حساب المسافة (للكوت والصويرة أو الطوارئ)
      // ========================================================
      final restLoc = locations.firstWhere((l) => l['id'] == restaurantId, orElse: () => {});
      if (restLoc.isEmpty) {
        print("⚠️ [Calc Error] لم يتم العثور على إحداثيات للمطعم! سيتم تطبيق السعر الافتراضي: $fallbackFee");
        return {'fee': fallbackFee, 'message': '📌 تسعيرة ($areaName) الموحدة'};
      }

      double restLat = double.tryParse(restLoc['lat'].toString()) ?? 0.0;
      double restLng = double.tryParse(restLoc['lng'].toString()) ?? 0.0;

      print("📍 إحداثيات المطعم: Lat: $restLat, Lng: $restLng");

      // حساب المسافة بخوارزمية هافيرسين مع ضربها بمعامل انحراف الطرق (1.3)
      double rawDistance = _haversineDistance(userLat, userLng, restLat, restLng);
      double distanceKm = rawDistance * 1.3;
      print("📏 المسافة الجوية: ${rawDistance.toStringAsFixed(2)} كم | المسافة بعد معامل الطرق (1.3): ${distanceKm.toStringAsFixed(2)} كم");

      double finalPrice = 1000.0;

      // ========================================================
      // 4. تطبيق شرائح الأسعار المطابقة للسيرفر 100%
      // ========================================================
      if (isKut) {
        print("🔢 [Calc Logic] تطبيق تسعيرة الكوت الذكية...");
        if (distanceKm <= 2.5) {
          finalPrice = 1500.0;
        } else if (distanceKm <= 4.0) {
          finalPrice = 2500.0;
        } else if (distanceKm <= 5.5) {
          finalPrice = 3000.0;
        } else if (distanceKm <= 7.0) {
          finalPrice = 3500.0;
        } else if (distanceKm <= 8.5) {
          finalPrice = 4000.0;
        } else if (distanceKm <= 15.0) {
          finalPrice = 5000.0;
        } else {
          finalPrice = 7000.0;
        }
        print("✅ [Calc Success] السعر النهائي للكوت: $finalPrice د.ع");
        print("==================================================");
        return {'fee': finalPrice, 'message': '📏 تسعيرة الكوت الذكية (مسافة: ${distanceKm.toStringAsFixed(2)} كم)'};

      } else if (isSuwaira) {
        print("🔢 [Calc Logic] تطبيق تسعيرة الصويرة...");
        if (distanceKm <= 2.5) {
          finalPrice = 1500.0;
        } else if (distanceKm <= 5.0) {
          finalPrice = 2000.0;
        } else {
          finalPrice = 2500.0;
        }
        print("✅ [Calc Success] السعر النهائي للصويرة: $finalPrice د.ع");
        print("==================================================");
        return {'fee': finalPrice, 'message': '📏 تسعيرة الصويرة (مسافة: ${distanceKm.toStringAsFixed(2)} كم)'};

      } else {
        print("🔢 [Calc Logic] تطبيق تسعيرة الطوارئ للمسافات (خارج المناطق المرسومة)...");
        finalPrice = 1000.0;
        if (distanceKm > 5.0) {
          finalPrice += (distanceKm - 5.0) * 250.0;
        }
        // تقريب لأقرب 250
        finalPrice = (finalPrice / 250.0).ceil() * 250.0;
        if (finalPrice > 7000.0) finalPrice = 7000.0;

        print("✅ [Calc Success] السعر النهائي للطوارئ: $finalPrice د.ع");
        print("==================================================");
        return {'fee': finalPrice < 1000 ? 1000.0 : finalPrice, 'message': '📏 تسعيرة المسافة الاحتياطية (${distanceKm.toStringAsFixed(2)} كم)'};
      }

    } catch (e) {
      print("❌ [Calc Fatal Error] حدث خطأ أثناء الحساب: $e");
      print("==================================================");
      return {'fee': fallbackFee, 'message': '⚠️ تم تطبيق السعر الافتراضي لـ ($areaName)'};
    }
  }

  // خوارزمية فحص النقطة داخل المضلع (Ray Casting)
  bool _isPointInPolygon(double lat, double lng, List<Map<String, double>> polygon) {
    if (polygon.isEmpty) return false;
    bool inside = false;
    int j = polygon.length - 1;
    for (int i = 0; i < polygon.length; i++) {
      double xi = polygon[i]['lng']!, yi = polygon[i]['lat']!;
      double xj = polygon[j]['lng']!, yj = polygon[j]['lat']!;
      bool intersect = ((yi > lat) != (yj > lat)) && (lng < (xj - xi) * (lat - yi) / (yj - yi) + xi);
      if (intersect) inside = !inside;
      j = i;
    }
    return inside;
  }

  // خوارزمية حساب المسافة (Haversine)
  double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371.0; // نصف قطر الأرض بالكيلومتر
    double dLat = _deg2rad(lat2 - lat1);
    double dLon = _deg2rad(lon2 - lon1);
    double a = sin(dLat / 2) * sin(dLat / 2) + cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _deg2rad(double deg) => deg * (3.141592653589793 / 180.0);
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


class Restaurant {
  final int id;
  final String name;
  final String imageUrl;
  bool isDeliverable;
  final double averageRating;
  final int ratingCount;
  final bool isOpen;
  final String autoOpenTime;
  final String autoCloseTime;
  final double latitude;
  final double longitude;
  final String storeType; // 🔥 [جديد] نوع المتجر (restaurant أو market)

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
    required this.latitude,
    required this.longitude,
    this.storeType = 'restaurant', // افتراضي مطعم
  });

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
      {'key': 'restaurant_latitude', 'value': latitude.toString()},
      {'key': 'restaurant_longitude', 'value': longitude.toString()},
      {'key': 'store_type', 'value': storeType}, // حفظ النوع
    ],
  };

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    double avgRating = 0.0;
    int rCount = 0;
    String openTime = '00:00';
    String closeTime = '23:59';
    bool finalIsOpenStatus = true;
    double lat = 0.0;
    double lng = 0.0;
    String sType = 'restaurant'; // افتراضي مطعم

    // 🔥 الجديد: قراءة الحقل المباشر إذا أرسله السيرفر كحقل مستقل
    if (json['beytei_store_type'] != null) {
      sType = json['beytei_store_type'].toString();
    }

    if (json['meta_data'] != null && json['meta_data'] is List) {
      final metaData = json['meta_data'] as List;

      var ratingMeta = metaData.firstWhere((m) => m is Map && m['key'] == '_wc_average_rating', orElse: () => null);
      if (ratingMeta != null) avgRating = double.tryParse(ratingMeta['value'].toString()) ?? 0.0;

      var countMeta = metaData.firstWhere((m) => m is Map && m['key'] == '_wc_rating_count', orElse: () => null);
      if (countMeta != null) rCount = int.tryParse(countMeta['value'].toString()) ?? 0;

      var isOpenMeta = metaData.firstWhere((m) => m is Map && m['key'] == '_restaurant_is_open', orElse: () => null);
      if (isOpenMeta != null) finalIsOpenStatus = isOpenMeta['value'].toString() == '1';

      var openMeta = metaData.firstWhere((m) => m is Map && m['key'] == '_restaurant_auto_open_time', orElse: () => null);
      if (openMeta != null) openTime = openMeta['value'].toString();

      var closeMeta = metaData.firstWhere((m) => m is Map && m['key'] == '_restaurant_auto_close_time', orElse: () => null);
      if (closeMeta != null) closeTime = closeMeta['value'].toString();

      var latMeta = metaData.firstWhere((m) => m is Map && m['key'] == 'restaurant_latitude', orElse: () => null);
      if (latMeta != null) lat = double.tryParse(latMeta['value'].toString()) ?? 0.0;

      var lngMeta = metaData.firstWhere((m) => m is Map && m['key'] == 'restaurant_longitude', orElse: () => null);
      if (lngMeta != null) lng = double.tryParse(lngMeta['value'].toString()) ?? 0.0;

      // 🔥 قراءة النوع من الميتا كاحتياط قوي (يبحث عن store_type أو _store_type)
      var typeMeta = metaData.firstWhere((m) => m is Map && (m['key'] == 'store_type' || m['key'] == '_store_type'), orElse: () => null);
      if (typeMeta != null && typeMeta['value'] != null && typeMeta['value'].toString().isNotEmpty) {
        sType = typeMeta['value'].toString();
      }
    }

    return Restaurant(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'اسم غير معروف',
      imageUrl: json['image'] != null && json['image']['src'] != false
          ? json['image']['src']
          : 'https://via.placeholder.com/300',
      averageRating: avgRating,
      ratingCount: rCount,
      isOpen: finalIsOpenStatus,
      autoOpenTime: openTime,
      autoCloseTime: closeTime,
      latitude: lat,
      longitude: lng,
      storeType: sType, // تعيين النوع بنجاح
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
  final List<int> allCategoryIds;
  bool isDeliverable;
  final double averageRating;
  final int ratingCount;
  final double restaurantLat;
  final double restaurantLng;

  // 🔥 الحقول الجديدة
  double selectedWeight;
  String customNote;
  final double platformMarkup; // 👈 إضافة حقل أرباح المنصة

  FoodItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.salePrice,
    required this.imageUrl,
    this.quantity = 1,
    required this.categoryId,
    required this.allCategoryIds,
    this.isDeliverable = false,
    this.averageRating = 0.0,
    this.ratingCount = 0,
    this.restaurantLat = 0.0,
    this.restaurantLng = 0.0,
    this.selectedWeight = 1.0,
    this.customNote = '',
    this.platformMarkup = 0.0, // 👈 القيمة الافتراضية
  });

  FoodItem copyWith({
    double? selectedWeight,
    String? customNote,
    int? quantity,
  }) {
    return FoodItem(
      id: id, name: name, description: description, price: price, salePrice: salePrice,
      imageUrl: imageUrl, categoryId: categoryId, allCategoryIds: allCategoryIds,
      isDeliverable: isDeliverable, averageRating: averageRating, ratingCount: ratingCount,
      restaurantLat: restaurantLat, restaurantLng: restaurantLng,
      selectedWeight: selectedWeight ?? this.selectedWeight,
      customNote: customNote ?? this.customNote,
      quantity: quantity ?? this.quantity,
      platformMarkup: platformMarkup, // 👈 تمرير الحقل
    );
  }

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
    List<int> catIds = [];
    if (json['categories'] != null && json['categories'] is List) {
      catIds = (json['categories'] as List).map((c) => c['id'] as int).toList();
    }

    return FoodItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'غير متوفر',
      description: json['short_description'] is String ? json['short_description'].replaceAll(RegExp(r'<[^>]*>|&nbsp;'), '').trim() : '',
      price: safeParseDouble(json['regular_price']),
      salePrice: (json['sale_price'] != '' && json['sale_price'] != null) ? safeParseDouble(json['sale_price'], -1.0) : null,
      imageUrl: extractImageUrl(json['images']),
      categoryId: extractRestaurantId(json),
      allCategoryIds: catIds,
      averageRating: safeParseDouble(json['average_rating']),
      ratingCount: safeParseInt(json['rating_count']),
      // 👈 قراءة أرباح المنصة من الـ API
      platformMarkup: safeParseDouble(json['platform_markup']),
    );
  }

  // 🔥 السر هنا: دمج السعر الأساسي مع أرباح المنصة لكي لا يلاحظ الزبون
  double get basePrice => (salePrice != null && salePrice! >= 0 ? salePrice! : price) + platformMarkup;

  double get finalPrice => basePrice * selectedWeight;
  String get formattedFinalPrice => '${NumberFormat('#,###', 'ar_IQ').format(finalPrice)} د.ع';

  double get displayPrice => finalPrice;
  String get formattedPrice => formattedFinalPrice;

  String get weightLabel {
    if (selectedWeight == 0.25) return "ربع كيلو (250غم)";
    if (selectedWeight == 0.5) return "نصف كيلو (500غم)";
    if (selectedWeight == 0.75) return "كيلو إلا ربع";
    if (selectedWeight == 1.0) return "1 كيلو";
    if (selectedWeight == 1.5) return "كيلو ونصف (1.5 كغم)";
    if (selectedWeight % 1 == 0) return "${selectedWeight.toInt()} كيلو";
    return "$selectedWeight كيلو";
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'quantity': quantity, 'categoryId': categoryId, 'selectedWeight': selectedWeight};
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
  final String shippingTotal;

  // 🔥 الحقول الجديدة للسائق
  final String? driverName;
  final String? driverPhone;

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
    required this.shippingTotal,
    // 🔥
    this.driverName,
    this.driverPhone,
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
      shippingTotal: json['shipping_total'] ?? '0',

      // 🔥 قراءة بيانات السائق من السيرفر
      driverName: json['driver_name'],
      driverPhone: json['driver_phone'],
    );
  }

  Map<String, dynamic> get statusDisplay {
    // (نفس الكود القديم هنا...)
    switch (status) {
      case 'processing': return {'text': 'جاري تحضير الطلب', 'icon': Icons.soup_kitchen_outlined, 'color': Colors.blue};
      case 'out-for-delivery': return {'text': 'المندوب قادم إليك 🛵', 'icon': Icons.delivery_dining, 'color': Colors.orange.shade700};
      case 'completed': return {'text': 'تم توصيل الطلب', 'icon': Icons.check_circle, 'color': Colors.green};
      case 'cancelled': return {'text': 'تم إلغاء الطلب', 'icon': Icons.cancel, 'color': Colors.red};
      case 'pending': default: return {'text': 'تم استلام الطلب', 'icon': Icons.receipt_long, 'color': Colors.grey.shade700};
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
// --- DELIVERY CONFIG & PROVIDER (Client-Side Calculation) ---
// =======================================================================

class DeliveryConfig {
  final double baseDistanceKm;     // مسافة البداية (أول 5 كم)
  final double baseFee;            // سعر البداية (1000 د.ع)
  final double costPerKmAfterBase; // سعر الكيلو الإضافي (500 د.ع)
  final double maxDeliveryFee;     // الحد الأقصى للسعر (اختياري)

  DeliveryConfig({
    required this.baseDistanceKm,
    required this.baseFee,
    required this.costPerKmAfterBase,
    this.maxDeliveryFee = 15000.0,
  });

  factory DeliveryConfig.fromJson(Map<String, dynamic> json) {
    return DeliveryConfig(
      // قراءة القيم من السيرفر، أو استخدام القيم الافتراضية في حال الفشل
      baseDistanceKm: (json['base_distance_km'] as num? ?? 5.0).toDouble(),
      baseFee: (json['base_fee'] as num? ?? 1000.0).toDouble(),
      costPerKmAfterBase: (json['cost_per_km_after_base'] as num? ?? 500.0).toDouble(),
      maxDeliveryFee: (json['max_delivery_fee'] as num? ?? 15000.0).toDouble(),
    );
  }
}

// =======================================================================
// --- DELIVERY SYSTEM (OFFLINE-FIRST) ---
// =======================================================================
// موديل بسيط لإحداثيات المطعم
class RestaurantLocation {
  final double lat;
  final double lng;
  RestaurantLocation(this.lat, this.lng);
}

// =======================================================================
// --- Delivery Provider (Server-Side Calculation) ---
// =======================================================================
class DeliveryProvider with ChangeNotifier {
  // المتغيرات التي ستظهر في الواجهة
  double _deliveryFee = 0.0;
  String _message = "";
  bool _isLoading = false;
  bool _hasError = false;

  // Getters
  double get deliveryFee => _deliveryFee;
  String get message => _message;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;

  // دالة التهيئة (لم نعد نحتاج لجلب ملف ضخم)
  Future<void> init() async {}

  /// 🔥 دالة حساب السعر (تتصل بالسيرفر فقط)
  Future<void> calculateDeliveryFee({
    required int restaurantId,
    required double userLat,
    required double userLng,
  }) async {
    _isLoading = true;
    _hasError = false;
    _message = "جاري حساب التكلفة...";
    notifyListeners();

    try {
      print("🚀 [Delivery] Asking Server for Price... RestID: $restaurantId");

      final response = await http.post(
        Uri.parse('https://re.beytei.com/wp-json/restaurant-app/v1/calculate-delivery-fee'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'restaurant_id': restaurantId,
          'lat': userLat,
          'lng': userLng
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // قراءة السعر
        _deliveryFee = (data['price'] as num).toDouble();

        // تحليل الرسالة حسب الطريقة
        String method = data['method'] ?? 'unknown';

        if (method == 'zone_fixed') {
          String zoneName = data['zone_name'] ?? 'منطقة محددة';
          _message = "✅ موقعك ضمن ($zoneName). أجرة ثابتة.";
        } else if (method == 'distance_calc') {
          var distance = data['distance'];
          if (_deliveryFee == 2000 && (distance is num && distance > 10)) {
            _message = "مسافة بعيدة ($distance كم) - تم تطبيق الحد الأقصى للسعر.";
          } else {
            _message = "📏 المسافة من المطعم: $distance كم.";
          }
        } else {
          _message = "تم تحديد التكلفة.";
        }

        print("✅ Success: $_deliveryFee IQD - $_message");

      } else {
        print("❌ Server Error: ${response.body}");
        _hasError = true;
        _deliveryFee = 0.0;
        _message = "تعذر حساب السعر (خطأ خادم).";
      }

    } catch (e) {
      print("❌ Connection Error: $e");
      _hasError = true;
      _deliveryFee = 0.0;
      _message = "تحقق من اتصال الإنترنت.";
    }

    _isLoading = false;
    notifyListeners();
  }

  void reset() {
    _deliveryFee = 0.0;
    _message = "";
    _hasError = false;
    notifyListeners();
  }
}





























class TeamOrdersScreen extends StatefulWidget {
  final String token;
  const TeamOrdersScreen({super.key, required this.token});

  @override
  State<TeamOrdersScreen> createState() => _TeamOrdersScreenState();
}

class _TeamOrdersScreenState extends State<TeamOrdersScreen> {
  late Future<List<UnifiedDeliveryOrder>> _ordersFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _ordersFuture = _fetchTeamOrders();
  }

  Future<List<UnifiedDeliveryOrder>> _fetchTeamOrders() async {
    try {
      // 🔥 الحل هنا: جلب توكن التاكسي المحفوظ محلياً بدلاً من استخدام توكن المطعم الممرر في widget.token
      final prefs = await SharedPreferences.getInstance();
      final taxiToken = prefs.getString('taxi_jwt_token');

      if (taxiToken == null || taxiToken.isEmpty) {
        throw Exception("لم يتم العثور على صلاحية دخول سيرفر التكسي (401)");
      }

      // 🔥 إرسال توكن التاكسي الصحيح للـ API
      final response = await _apiService.getTeamLeaderAssignedOrders(taxiToken);
      return response.map((json) => UnifiedDeliveryOrder.fromJson(json)).toList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("فشل تحميل الطلبات: ${e.toString()}")),
        );
      }
      return [];
    }
  }

  void _refreshOrders() {
    setState(() {
      _ordersFuture = _fetchTeamOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("طلبات فريقي", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshOrders,
          ),
        ],
      ),
      body: FutureBuilder<List<UnifiedDeliveryOrder>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text("حدث خطأ أثناء التحميل."));
          }
          final orders = snapshot.data!;
          if (orders.isEmpty) {
            return const Center(child: Text("لا توجد طلبات لفريقك حالياً 😴"));
          }
          return RefreshIndicator(
            onRefresh: () => _ordersFuture = _fetchTeamOrders(),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                return TeamLeaderOrderCard(
                  order: orders[index],
                  token: widget.token,
                  onActionComplete: _refreshOrders,
                );
              },
            ),
          );
        },
      ),
    );
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

class OrderHistoryService {
  static const _key = 'order_history';

  // 1. دالة حفظ طلب جديد (لأول مرة)
  Future<void> saveOrder(Order order) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Order> orders = await getOrders();
    // إزالة النسخة القديمة إن وجدت لتجنب التكرار
    orders.removeWhere((o) => o.id == order.id);
    orders.insert(0, order);
    final String encodedData = json.encode(orders.map<Map<String, dynamic>>((o) => o.toJson()).toList());
    await prefs.setString(_key, encodedData);
  }

  // 2. دالة جلب كل الطلبات المخزنة
  Future<List<Order>> getOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final String? ordersString = prefs.getString(_key);
    if (ordersString != null) {
      final List<dynamic> decodedData = json.decode(ordersString);
      return decodedData.map<Order>((item) => Order.fromJson(item)).toList();
    }
    return [];
  }

  // 3. 🔥 الدالة الجديدة: تحديث حالة طلب موجود مسبقاً
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
            break;
          }
        }

        // إذا تم التعديل، نحفظ القائمة الجديدة
        if (isUpdated) {
          await prefs.setString(_key, json.encode(decodedData));
          print("💾 تم تحديث حالة الطلب #$orderId محلياً بنجاح إلى: $newStatus");
        }
      }
    } catch (e) {
      print("⚠️ خطأ أثناء تحديث الطلب محلياً: $e");
    }
  }
}
// ==========================================
// 1. موديل العرض (Offer Model)
// ==========================================
class Offer {
  final int id;
  final int restaurantId;
  final String title;
  final String description;
  final String imageUrl;
  final double price;

  Offer({
    required this.id,
    required this.restaurantId,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.price,
  });

  // لتحويل البيانات القادمة من السيرفر (منتج ووكومرس مميز)
  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      id: json['id'],
      restaurantId: 0, // سيتم تحديده لاحقاً
      title: json['name'],
      description: json['short_description'] ?? '',
      imageUrl: (json['images'] != null && json['images'].isNotEmpty)
          ? json['images'][0]['src']
          : 'https://via.placeholder.com/300',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
    );
  }
}

// ==========================================
// ==========================================
// 2. ويدجت بطاقة العرض العصرية (Modern Offer Card) - النسخة المحسنة
// =======================================================================
// --- بطاقة الوجبة المخفضة (ModernOfferCard) - متوافقة مع الشبكة ---
// =======================================================================
// =======================================================================
// --- بطاقة الوجبة المخفضة (ModernOfferCard) - متوافقة ومضغوطة ---
// =======================================================================
class ModernOfferCard extends StatelessWidget {
  final Offer offer;
  final List<Restaurant> allStores;

  const ModernOfferCard({
    super.key,
    required this.offer,
    required this.allStores,
  });

  @override
  Widget build(BuildContext context) {
    String cleanDescription = offer.description.replaceAll(RegExp(r'<[^>]*>|&nbsp;'), '').trim();
    if (cleanDescription.isEmpty) cleanDescription = "عرض مميز لفترة محدودة 🔥";

    return GestureDetector(
      onTap: () {
        try {
          final restaurant = allStores.firstWhere((r) => r.id == offer.restaurantId);
          Navigator.push(context, MaterialPageRoute(builder: (_) => MenuScreen(restaurant: restaurant)));
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('المتجر غير متاح حالياً')));
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
          image: DecorationImage(
            image: CachedNetworkImageProvider(offer.imageUrl),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // التدرج اللوني للنص لحمايته وإبرازه
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.5), Colors.black.withOpacity(0.95)],
                  stops: const [0.2, 0.6, 1.0],
                ),
              ),
            ),

            // شارة "عرض نار" في الزاوية
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_fire_department, color: Colors.white, size: 10),
                    SizedBox(width: 2),
                    Text("عرض نار", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),

            // المحتوى السفلي (النصوص والأسعار)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offer.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    cleanDescription,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[300], fontSize: 9),
                  ),
                  const SizedBox(height: 6),

                  // السعر المربع الذهبي وزر الطلب
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.amber),
                        ),
                        child: Text(
                          NumberFormat('#,###').format(offer.price),
                          style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text("اطلب", style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold)),
                      )
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

















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

  // السعر الكلي للوجبات (شامل الأرباح)
  double get totalPrice => _items.fold(0.0, (sum, item) => sum + (item.finalPrice * item.quantity));

  // 🔥 حساب إجمالي أرباح المنصة لكل السلة لإرسالها للسيرفر
  double get totalPlatformMarkup => _items.fold(0.0, (sum, item) => sum + (item.platformMarkup * item.selectedWeight * item.quantity));

  String? _appliedCoupon;
  double _discountPercentage = 0.0;
  double _discountAmount = 0.0;
  String _discountType = '';

  String? _promoterCode;
  int _usageCount = 0;
  double _loyaltyDiscountPercentage = 0.0;

  String? get appliedCoupon => _appliedCoupon;
  String? get promoterCode => _promoterCode;
  int get usageCount => _usageCount;

  bool _weightsAreEqual(double w1, double w2) => (w1 - w2).abs() < 0.001;

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

  double get discountedTotal => (totalPrice - totalDiscountAmount).clamp(0, double.infinity);

  // 🔥 الدوال المفقودة التي سببت الأخطاء
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
      'message': 'أنت في مرحلة الطلب رقم (${_usageCount + 1}). تبقى لك $remaining طلب للحصول على خصم ٥٠٪!',
    };
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
        result['message'] = "تم تفعيل رمز المروج. تبقى $remaining طلب للحصول على خصم ٥٠٪!";
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

  // --- إدارة السلة ---
  void addToCart(FoodItem foodItem, BuildContext context, {int quantity = 1}) {
    if (!foodItem.isDeliverable) return;

    if (_items.isNotEmpty) {
      int currentRestaurantId = _items.first.categoryId;
      if (currentRestaurantId != foodItem.categoryId) {
        _showClearCartDialog(context, foodItem, quantity);
        return;
      }
    }
    _performAddToCart(foodItem, quantity, context);
  }

  void _showClearCartDialog(BuildContext context, FoodItem foodItem, int quantity) async {
    bool? clear = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("تفريغ السلة؟"),
        content: const Text("لا يمكنك الطلب من متجرين مختلفين بوقت واحد."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("إلغاء")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text("تفريغ السلة")),
        ],
      ),
    );
    if (clear == true) {
      clearCart();
      _performAddToCart(foodItem, quantity, context);
    }
  }

  void _performAddToCart(FoodItem foodItem, int quantity, BuildContext context) {
    final existingIndex = _items.indexWhere((item) =>
    item.id == foodItem.id &&
        _weightsAreEqual(item.selectedWeight, foodItem.selectedWeight) &&
        item.customNote.trim() == foodItem.customNote.trim()
    );

    if (existingIndex != -1) {
      _items[existingIndex].quantity += quantity;
    } else {
      foodItem.quantity = quantity;
      _items.add(foodItem);
    }
    notifyListeners();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تمت الإضافة للسلة 🛒"), backgroundColor: Colors.green, duration: Duration(seconds: 1)));
  }

  void incrementQuantity(FoodItem foodItem) {
    final itemIndex = _items.indexWhere((item) => item.id == foodItem.id && _weightsAreEqual(item.selectedWeight, foodItem.selectedWeight) && item.customNote == foodItem.customNote);
    if (itemIndex != -1) { _items[itemIndex].quantity++; notifyListeners(); }
  }

  void decrementQuantity(FoodItem foodItem) {
    final itemIndex = _items.indexWhere((item) => item.id == foodItem.id && _weightsAreEqual(item.selectedWeight, foodItem.selectedWeight) && item.customNote == foodItem.customNote);
    if (itemIndex != -1) {
      if (_items[itemIndex].quantity > 1) _items[itemIndex].quantity--;
      else _items.removeAt(itemIndex);
      notifyListeners();
    }
  }

  void clearCart() { _items.clear(); removeCoupon(); notifyListeners(); }
}
class FoodItemBottomSheet extends StatefulWidget {
  final FoodItem foodItem;
  final bool isMarket;
  const FoodItemBottomSheet({super.key, required this.foodItem, this.isMarket = false});

  @override
  State<FoodItemBottomSheet> createState() => _FoodItemBottomSheetState();
}

class _FoodItemBottomSheetState extends State<FoodItemBottomSheet> {
  int quantity = 1;
  double _currentWeight = 1.0;
  final TextEditingController _noteController = TextEditingController();

  final List<double> _quickWeights = [1.5, 1.0, 0.5, 0.25];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  bool _weightsAreEqual(double w1, double w2) => (w1 - w2).abs() < 0.001;

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
          decoration: const InputDecoration(hintText: "مثال: 5.5", suffixText: "كغم", border: OutlineInputBorder(), prefixIcon: Icon(Icons.scale)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء")),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val > 0) {
                setState(() => _currentWeight = val);
                Navigator.pop(ctx);
                HapticFeedback.lightImpact();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
            child: const Text("تأكيد", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double currentItemPrice = widget.foodItem.basePrice * _currentWeight;
    double totalPrice = currentItemPrice * quantity;

    return Container(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 20),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(borderRadius: BorderRadius.circular(15), child: CachedNetworkImage(imageUrl: widget.foodItem.imageUrl, width: 80, height: 80, fit: BoxFit.cover)),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.foodItem.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text("${NumberFormat('#,###', 'ar_IQ').format(currentItemPrice)} د.ع", style: TextStyle(fontSize: 16, color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 🔥 أزرار اختيار الوزن (للمسواك فقط) 🔥
            if (widget.isMarket) ...[
              const Text("اختر الوزن:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildWeightChip("كيلو ونصف", 1.5)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildWeightChip("1 كيلو", 1.0)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildWeightChip("نصف كيلو", 0.5)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildWeightChip("ربع كيلو", 0.25)),
                ],
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _showCustomWeightDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: !_quickWeights.any((w) => _weightsAreEqual(w, _currentWeight)) ? Theme.of(context).primaryColor : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: !_quickWeights.any((w) => _weightsAreEqual(w, _currentWeight)) ? Theme.of(context).primaryColor : Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit_note_rounded, color: !_quickWeights.any((w) => _weightsAreEqual(w, _currentWeight)) ? Colors.white : Colors.grey.shade600, size: 20),
                      const SizedBox(width: 8),
                      Text("وزن مخصص", style: TextStyle(color: !_quickWeights.any((w) => _weightsAreEqual(w, _currentWeight)) ? Colors.white : Colors.grey.shade600, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // 📝 حقل الملاحظات (للجميع)
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: widget.isMarket ? 'ملاحظات (مثال: طماطة قوية، موز أصفر...)' : 'ملاحظات إضافية (بدون بصل، صوص إضافي...)',
                prefixIcon: const Icon(Icons.edit_note, color: Colors.grey),
                filled: true, fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
            const Divider(height: 30),

            // التحكم بالعدد
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(onPressed: quantity > 1 ? () => setState(() => quantity--) : null, icon: const Icon(Icons.remove_circle_outline, size: 35), color: quantity > 1 ? Theme.of(context).primaryColor : Colors.grey),
                const SizedBox(width: 20),
                Text('$quantity', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(width: 20),
                IconButton(onPressed: () => setState(() => quantity++), icon: const Icon(Icons.add_circle_outline, size: 35), color: Theme.of(context).primaryColor),
              ],
            ),
            const SizedBox(height: 20),

            // زر الإضافة
            ElevatedButton(
              onPressed: () {
                FoodItem cartItem = widget.foodItem.copyWith(
                  selectedWeight: widget.isMarket ? _currentWeight : 1.0,
                  customNote: _noteController.text.trim(),
                );
                Provider.of<CartProvider>(context, listen: false).addToCart(cartItem, context, quantity: quantity);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), backgroundColor: Theme.of(context).primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("إضافة للسلة", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  Text("${NumberFormat('#,###', 'ar_IQ').format(totalPrice)} د.ع", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightChip(String label, double weight) {
    bool isSelected = _weightsAreEqual(_currentWeight, weight);
    return GestureDetector(
      onTap: () { setState(() => _currentWeight = weight); HapticFeedback.lightImpact(); },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300, width: 1.5),
        ),
        child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
class ApiService {
  final String _authString = 'Basic ${base64Encode(utf8.encode('$CONSUMER_KEY:$CONSUMER_SECRET'))}';
  final CacheService _cacheService = CacheService();

  Future<bool> createMarketingOrder({
    required String token,
    required String title,
    required String body,
    required String? imageUrl,
  }) async {
    return _executeWithRetry(() async {
      // 1. تجهيز بيانات الإعلان كـ Meta Data
      List<Map<String, dynamic>> metaData = [
        {"key": "_is_ad_request", "value": "true"},
        {"key": "ad_title", "value": title},
        {"key": "ad_content", "value": body},
        if (imageUrl != null && imageUrl.isNotEmpty)
          {"key": "ad_image", "value": imageUrl},
      ];

      // 2. إرسال الطلب إلى ووكومرس
      final response = await http.post(
        Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/create-ad-order'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'product_id': 9999, // تأكد من استبدال هذا الرقم بـ ID منتج الإعلان في ووكومرس
          'quantity': 1,
          'total_cost': 3000.0, // المبلغ المراد خصمه
          'meta_data': metaData,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        final body = json.decode(response.body);
        throw Exception(body['message'] ?? 'فشل إنشاء طلب الإعلان');
      }
    });
  }

  // 🔥 دوال نظام الكاش باك الذكي V2 (الجديد)
  Future<Map<String, dynamic>> getCashbackStatus(String token) async {
    return _executeWithRetry(() async {
      final response = await http.get(
        Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/cashback-status'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('فشل تحميل حالة الكاش باك');
    });
  }

  Future<Map<String, dynamic>> claimDiscountCoupon(String token) async {
    return _executeWithRetry(() async {
      final response = await http.post(
        Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/claim-discount'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data;
      }
      throw Exception(data['message'] ?? 'فشل إصدار الكوبون');
    });
  }

  Future<bool> notifyDriverOrderReady(int sourceOrderId) async {
    return _executeWithRetry(() async {
      final response = await http.post(
        Uri.parse('$TAXI_URL/wp-json/taxi/v3/delivery/notify-ready'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'source_order_id': sourceOrderId.toString(),
          'secret_key': 'BEYTEI_SECURE_2025'
        }),
      );
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return true;
      } else {
        throw Exception(data['message'] ?? ' فشل إرسال اتصل برقم الهاتف للسائق ');
      }
    });
  }

  Future<List<dynamic>> getTeamLeaderAssignedOrders(String token) async {
    final response = await http.get(
      Uri.parse('$TAXI_URL/wp-json/taxi/v3/leader/my-team-orders'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return jsonResponse['orders'] ?? [];
    } else {
      throw Exception('فشل تحميل طلبات الفريق: ${response.statusCode}');
    }
  }

  Future<List<dynamic>> checkRestaurantsStatusLight(List<int> ids) async {
    if (ids.isEmpty) return [];

    return _executeWithRetry(() async {
      final response = await http.post(
        Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/check-statuses-light'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({'ids': ids}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    });
  }

  Future<List<dynamic>> getSubcategories(int restaurantId) async {
    return _executeWithRetry(() async {
      final response = await http.get(
        Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/restaurant/$restaurantId/subcategories'),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    });
  }

  Future<bool> createSubcategory(String token, String name, String icon) async {
    return _executeWithRetry(() async {
      final response = await http.post(
        Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/create-subcategory'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'icon': icon,
          'display_order': 0
        }),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    });
  }

  Future<bool> createProductWithSubcategory(String token, String name, String price, String? salePrice, String description, File? imageFile, int subcategoryId) async {
    return _executeWithRetry(() async {
      String? imageBase64;
      if (imageFile != null) {
        List<int> imageBytes = await imageFile.readAsBytes();
        imageBase64 = base64Encode(imageBytes);
      }

      final response = await http.post(
        Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/create-product-with-category'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'price': price,
          'sale_price': salePrice,
          'description': description,
          'image_base64': imageBase64,
          'subcategory_id': subcategoryId,
        }),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    });
  }

  Future<T> _executeWithRetry<T>(Future<T> Function() action) async {
    int attempts = 0;
    while (attempts < 3) {
      try {
        return await action().timeout(API_TIMEOUT);
      } catch (e) {
        attempts++;
        String errorString = e.toString();

        if (errorString.contains('403') || errorString.contains('429')) {
          print("⛔ تم إيقاف المحاولات فوراً لتجنب الحظر: $errorString");
          rethrow;
        }

        if (attempts >= 3) rethrow;

        int delaySeconds = pow(2, attempts).toInt();
        print("⚠️ فشل الطلب (محاولة $attempts)، انتظار $delaySeconds ثواني لتهدئة السيرفر...");

        await Future.delayed(Duration(seconds: delaySeconds));
      }
    }
    throw Exception('Failed after multiple retries');
  }

  Future<List<UnifiedDeliveryOrder>> getMiswakOrdersByRegion(int areaId, String token) async {
    final url = '$MISWAK_URL/wp-json/restaurant-app/v1/region-orders?area_id=$areaId&status=active';
    print("🟡 [1] طلب المسواك جاري الإرسال إلى: $url");

    return _executeWithRetry(() async {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        try {
          final List<dynamic> data = json.decode(response.body);
          if (data.isEmpty) return [];

          List<UnifiedDeliveryOrder> parsedOrders = data.map<UnifiedDeliveryOrder>((jsonObj) {
            double safeDouble(dynamic val) => val == null ? 0.0 : (double.tryParse(val.toString()) ?? 0.0);

            return UnifiedDeliveryOrder(
              id: jsonObj['id'],
              status: jsonObj['delivery_status'] ?? jsonObj['status'] ?? 'unknown',
              description: "مسواك: ${jsonObj['store_name'] ?? ''}",
              deliveryFee: safeDouble(jsonObj['shipping_total']),
              orderTotal: safeDouble(jsonObj['total']),
              pickupName: jsonObj['store_name'] ?? 'متجر مسواك',
              sourceType: 'market',
              destinationAddress: jsonObj['billing']?['address_1'] ?? jsonObj['customer_address'] ?? '',
              pickupLat: "0",
              pickupLng: "0",
              destLat: jsonObj['destination_lat']?.toString() ?? "0",
              destLng: jsonObj['destination_lng']?.toString() ?? "0",
              itemsSummary: "${jsonObj['line_items']?.length ?? 0} منتجات",
              dateCreated: DateTime.parse(jsonObj['date_created']).millisecondsSinceEpoch ~/ 1000,
              customerPhone: jsonObj['billing']?['phone'] ?? '',
              lineItems: jsonObj['line_items'] is List ? jsonObj['line_items'] : [],
              driverName: jsonObj['driver_name'],
              driverPhone: jsonObj['driver_phone'],
            );
          }).toList();

          return parsedOrders;

        } catch (e) {
          print("❌ [خطأ تحليل بيانات المسواك]: $e");
          return [];
        }
      } else {
        return [];
      }
    });
  }

  Future<Map<String, dynamic>> getTeamLeaderRewards(String token) async {
    return _executeWithRetry(() async {
      final response = await http.get(
        Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/wallet'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('فشل تحميل بيانات المحفظة');
    });
  }

  Future<bool> respondToChallenge(String token, int challengeId, String action) async {
    return _executeWithRetry(() async {
      final response = await http.post(
        Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/challenge-respond'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: json.encode({
          'challenge_id': challengeId,
          'action': action
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print("فشل الاستجابة للتحدي: ${response.body}");
        return false;
      }
    });
  }

  Future<Map<String, dynamic>> getWalletData(String token) async {
    return _executeWithRetry(() async {
      final response = await http.get(
        Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/wallet'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to load wallet');
    });
  }

  Future<bool> buyNotification(String token, String text) async {
    return _executeWithRetry(() async {
      final response = await http.post(
        Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/buy-notification'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: json.encode({'text': text}),
      );
      if (response.statusCode == 200) return true;
      final body = json.decode(response.body);
      throw Exception(body['message'] ?? 'فشل العملية');
    });
  }

  Future<bool> updateRestaurantStatusFull(String token, String mode, bool isOpen) async {
    return _executeWithRetry(() async {
      final response = await http.post(
        Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/update-status'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: json.encode({
          'mode': mode,
          'is_open': isOpen ? 1 : 0
        }),
      );
      return response.statusCode == 200;
    });
  }

  // 🔥 1. التعديل الجذري هنا لإضافة beytei_store_type
  Future<String> getRawRestaurants(int areaId) async {
    const fields = 'id,name,image,count,meta_data,beytei_store_type'; // 👈 التعديل هنا
    final url = '$BEYTEI_URL/wp-json/wc/v3/products/categories?parent=0&per_page=100&_fields=$fields&area_id=$areaId';

    return _executeWithRetry(() async {
      final response = await http.get(Uri.parse(url), headers: {'Authorization': _authString});
      if (response.statusCode == 200) return response.body;
      throw Exception('Failed to load restaurants raw');
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

  Future<String> getRawMenu(int restaurantId) async {
    const fields = 'id,name,regular_price,sale_price,images,categories,short_description,average_rating,rating_count,meta_data';
    final url = '$BEYTEI_URL/wp-json/wc/v3/products?category=$restaurantId&per_page=100&_fields=$fields';

    return _executeWithRetry(() async {
      final response = await http.get(Uri.parse(url), headers: {'Authorization': _authString});
      if (response.statusCode == 200) return response.body;
      throw Exception('Failed to load menu raw');
    });
  }

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

  Future<List<UnifiedDeliveryOrder>> getOrdersByRegion(int areaId, String token) async {
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
        return data.map<UnifiedDeliveryOrder>((jsonObj) {
          return UnifiedDeliveryOrder.fromJson(jsonObj);
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
        return (json.decode(response.body) as List).map((jsonObj) => Area.fromJson(jsonObj)).toList();
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

  // 🔥 2. التعديل الجذري هنا لإضافة beytei_store_type
  Future<List<Restaurant>> getAllRestaurants({required int areaId}) async {
    const fields = 'id,name,image,count,meta_data,beytei_store_type'; // 👈 التعديل هنا
    final url = '$BEYTEI_URL/wp-json/wc/v3/products/categories?parent=0&per_page=100&page=1&_fields=$fields&area_id=$areaId';
    final cacheKey = 'restaurants_area_${areaId}_page_1_limit_100';

    return _executeWithRetry(() async {
      final response = await http.get(Uri.parse(url), headers: {'Authorization': _authString});
      if (response.statusCode == 200) {
        await _cacheService.saveData(cacheKey, response.body);
        final data = json.decode(response.body) as List;
        return data.map((jsonObj) => Restaurant.fromJson(jsonObj)).toList();
      }
      throw Exception('Server error ${response.statusCode}');
    });
  }

  // 🔥 3. التعديل الجذري هنا لإضافة beytei_store_type
  Future<Restaurant> getRestaurantById(int restaurantId) async {
    const fields = 'id,name,image,count,meta_data,beytei_store_type'; // 👈 التعديل هنا
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
        return data.map((jsonObj) => FoodItem.fromJson(jsonObj)).toList();
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
        return (json.decode(response.body) as List).map((jsonObj) => FoodItem.fromJson(jsonObj)).toList();
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
    required String name,
    required String phone,
    required String address,
    required List<FoodItem> cartItems,
    String? couponCode,
    geolocator.Position? position,
    double? deliveryFee,
    required int zoneId,
    int? restaurantId,
    int? regionId,
    bool useSmartWallet = false,
    double? platformMarkupTotal, // 👈 1. إضافة المتغير هنا
  }) async {
    List<Map<String, dynamic>> couponLines = couponCode != null && couponCode.isNotEmpty ? [{"code": couponCode}] : [];

    List<Map<String, dynamic>> shippingLines = deliveryFee != null
        ? [{"method_id": "flat_rate", "method_title": "توصيل", "total": deliveryFee.toString()}]
        : [];

    final prefs = await SharedPreferences.getInstance();

    await prefs.reload();

    String? deviceId = prefs.getString('unique_device_id');
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await prefs.setString('unique_device_id', deviceId);
    }

    String? fcmToken = prefs.getString('fcm_token');
    String? voipToken = prefs.getString('voip_token');

    if (fcmToken == null) {
      fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) await prefs.setString('fcm_token', fcmToken);
    }

    if (Platform.isIOS && (voipToken == null || voipToken.isEmpty)) {
      try {
        voipToken = await FlutterCallkitIncoming.getDevicePushTokenVoIP();
        if (voipToken != null && voipToken.isNotEmpty) {
          await prefs.setString('voip_token', voipToken);
        }
      } catch (e) {
        print("⚠️ [SubmitOrder] خطأ في جلب توكن الآيفون: $e");
      }
    }

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
      "line_items": cartItems.map((item) => {"product_id": item.id, "quantity": item.quantity}).toList(),
      "coupon_lines": couponLines,
      "shipping_lines": shippingLines,
      "meta_data": [
        {"key": "zone_id", "value": zoneId.toString()},
        {"key": "_customer_fcm_token", "value": fcmToken ?? ''},
        {"key": "fcm_token", "value": fcmToken ?? ''},
        {"key": "_device_id", "value": deviceId},

        if (useSmartWallet) {"key": "_use_smart_wallet", "value": "yes"},

        if (voipToken != null && voipToken.isNotEmpty)
          {"key": "voip_token", "value": voipToken},

        if (deliveryFee != null) {"key": "calculated_delivery_fee", "value": deliveryFee.toString()},

        // 👈 2. إرسال قيمة أرباح المنصة الكلية للسيرفر
        if (platformMarkupTotal != null && platformMarkupTotal > 0)
          {"key": "calculated_platform_markup", "value": platformMarkupTotal.toString()},

        if (position != null) {"key": "_shipping_lat", "value": position.latitude.toString()},
        if (position != null) {"key": "_shipping_lng", "value": position.longitude.toString()},
        if (restaurantId != null) {"key": "_restaurant_id", "value": restaurantId.toString()},
        if (regionId != null) {"key": "_region_id", "value": regionId.toString()},
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
        return (json.decode(response.body) as List).map((jsonObj) => Order.fromJson(jsonObj)).toList();
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

  Future<List<ZoneRide>> getTeamLeaderZoneRides(String token, int zoneId) async {
    final url = 'https://taxi.beytei.com/team-leader-rides?zone_id=$zoneId';

    print("🟡 [API - TeamLeader] جاري طلب الرحلات من: $url (Zone ID: $zoneId)");

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        List ridesData = [];

        if (data.containsKey('data') && data['data'] != null) {
          if (data['data']['data'] != null) {
            ridesData = data['data']['data'];
          }
        }

        return ridesData.map((jsonObj) => ZoneRide.fromJson(jsonObj)).toList();
      } else {
        print("❌ [Server Error ${response.statusCode}] محتوى الرد من السيرفر: ${response.body}");
        throw Exception("فشل جلب الرحلات: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("حدث خطأ في الاتصال: $e");
    }
  }
}
class AuthService {
  // 1. تسجيل الدخول للسيرفرات القياسية (مطاعم + مسواك)
  // يعتمد على إضافة JWT Auth القياسية
  Future<String?> loginToServer(String baseUrl, String username, String password) async {
    try {
      print("🔵 [Auth] محاولة الدخول إلى السيرفر: $baseUrl");
      final response = await http.post(
          Uri.parse('$baseUrl/wp-json/jwt-auth/v1/token'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'username': username,
            'password': password
          })
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("✅ [Auth] نجح الدخول إلى ($baseUrl)");
        return data['token'];
      }

      print("❌ [Auth] فشل الدخول ($baseUrl): كود ${response.statusCode} - ${response.body}");
      return null;
    } catch (e) {
      print("⚠️ [Auth] خطأ اتصال ($baseUrl): $e");
      return null;
    }
  }

  // 2. 🔥 [جديد] تسجيل الدخول لسيرفر التاكسي
  // يعتمد على Endpoint مخصص: /taxi-auth/v1/login
// 2. 🔥 [تحديث] تسجيل الدخول لسيرفر التاكسي بالرابط الجديد الناجح
// 2. 🔥 [تحديث] تسجيل الدخول لسيرفر التاكسي (Banner) لتبويب السائقين
  Future<String?> loginToTaxiServer(String username, String password) async {
    try {
      print("🚕 [Taxi Auth] محاولة الدخول لسيرفر التاكسي (Banner)...");

      final response = await http.post(
          Uri.parse('$TAXI_URL/wp-json/taxi-auth/v1/login'), // 👈 رجعناه للـ Banner
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'phone_number': username, // 👈 هنا يطلب رقم الهاتف وليس username
            'password': password
          })
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['token'] != null) {
          print("✅ [Taxi Auth] نجح دخول التاكسي (Banner)! Token received.");
          return data['token'];
        }
      }

      print("❌ [Taxi Auth] فشل الدخول: ${response.body}");
      return null;
    } catch (e) {
      print("⚠️ [Taxi Auth] خطأ اتصال: $e");
      return null;
    }
  }

  // 3. 🔥 [تحديث] تسجيل الجهاز في السيرفرات الثلاثة (Triple Registration)
  // هذه الدالة تضمن وصول الإشعارات من أي جهة (مطعم، مسواك، تكسي)
  Future<void> registerDeviceTokenTriple(String? restToken, String? miswakToken, String? taxiToken) async {
    try {
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) {
        print("⚠️ [FCM] لم يتم العثور على توكن الجهاز (FCM Token is null).");
        return;
      }

      print("🔔 [FCM] جاري تسجيل الجهاز... (Token: ${fcmToken.substring(0, 15)}...)");

      // الاشتراك في القنوات العامة
      await FirebaseMessaging.instance.subscribeToTopic('all_users');

      String platform = Platform.isAndroid ? 'android' : 'ios';
      Map<String, dynamic> standardBody = {'token': fcmToken, 'platform': platform};

      // أ) سيرفر المطاعم (BEYTEI_URL)
      if (restToken != null) {
        await _sendTokenRequest(
            BEYTEI_URL,
            '/wp-json/restaurant-app/v1/register-device',
            restToken,
            standardBody,
            "مطاعم"
        );
      }

      // ب) سيرفر المسواك (MISWAK_URL)
      if (miswakToken != null) {
        await _sendTokenRequest(
            MISWAK_URL,
            '/wp-json/restaurant-app/v1/register-device',
            miswakToken,
            standardBody,
            "مسواك"
        );
      }

      // ج) 🔥 سيرفر التاكسي (TAXI_URL)
      // ملاحظة: مسار التاكسي مختلف قليلاً ويطلب مفتاح 'fcm_token'
      if (taxiToken != null) {
        await _sendTokenRequest(
            TAXI_URL,
            '/wp-json/taxi-auth/v1/update-fcm-token',
            taxiToken,
            {'fcm_token': fcmToken}, // المفتاح في التاكسي هو fcm_token
            "تاكسي"
        );
      }

    } catch (e) {
      print("⚠️ [FCM] خطأ عام في عملية التسجيل: $e");
    }
  }

  // دالة مساعدة لإرسال الطلب (لتقليل تكرار الكود)
  Future<void> _sendTokenRequest(String baseUrl, String path, String token, Map body, String serverName) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$path'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: json.encode(body),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ [FCM] تم حفظ التوكن في سيرفر ($serverName)");
      } else {
        print("🔸 [FCM] رد غير متوقع من ($serverName): ${response.statusCode}");
      }
    } catch (e) {
      print("❌ [FCM] فشل الاتصال بسيرفر ($serverName): $e");
    }
  }

  // 4. تسجيل الخروج الكامل
  Future<void> logout() async {
    print("👋 [Auth] جاري تسجيل الخروج وتنظيف البيانات...");

    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token');

    // محاولة إخبار السيرفر الرئيسي بتسجيل الخروج (اختياري)
    if (jwtToken != null) {
      try {
        await http.post(
          Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/unregister-device'),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $jwtToken'},
        ).timeout(const Duration(seconds: 3));
      } catch (e) {
        print("⚠️ فشل إرسال طلب الخروج للسيرفر: $e");
      }
    }

    // حذف التوكن من الفايربيس (اختياري، يفضل تركه لعدم فقدان الإشعارات عند الدخول مرة أخرى بسرعة)
    // await FirebaseMessaging.instance.deleteToken();

    // تنظيف الكاش والبيانات المحلية
    final cacheService = CacheService();
    await cacheService.clearAllCache();

    await prefs.remove('jwt_token');       // مطاعم
    await prefs.remove('miswak_jwt_token'); // مسواك
    await prefs.remove('taxi_jwt_token');   // تكسي
    await prefs.remove('taxi_monitoring_token');
    await prefs.remove('leader_zone_id');
    await prefs.remove('leader_zone_name');

    await prefs.remove('user_role');
    await prefs.remove('user_role');
    await prefs.remove('selectedAreaId');
    await prefs.remove('selectedAreaName');

    print("✅ [Auth] تم تسجيل الخروج بنجاح.");
  }

  // --- دوال للتوافق مع الكود القديم (Legacy Support) ---

  Future<String?> loginRestaurantOwner(String username, String password) async {
    return loginToServer(BEYTEI_URL, username, password);
  }

  Future<void> registerDeviceToken({int? areaId}) async {
    // هذه الدالة تستخدمها شاشة اختيار المنطقة للزوار
    // سنقوم بتسجيل التوكن في سيرفر المطاعم فقط
    String? fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      Map<String, dynamic> body = {
        'token': fcmToken,
        'platform': Platform.isAndroid ? 'android' : 'ios',
        if (areaId != null) 'area_id': areaId
      };

      // نرسل الطلب بدون توكن (للزوار) أو نتركه كما هو في السيرفر
      try {
        await http.post(
          Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/register-device'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(body),
        );
      } catch (e) {
        print("Error registering guest token: $e");
      }
    }
  }
}


class TeamLeaderWallet {
  final double myBalance; // الرصيد المتاح
  final double liability; // الديون
  final double totalEarnings; // الأرباح الكلية (اختياري)

  TeamLeaderWallet({required this.myBalance, required this.liability, required this.totalEarnings});

  factory TeamLeaderWallet.fromJson(Map<String, dynamic> json) {
    // قراءة البيانات المسطحة القادمة من السيرفر
    return TeamLeaderWallet(
      myBalance: double.tryParse(json['wallet_balance'].toString()) ?? 0.0,
      liability: double.tryParse(json['liability'].toString()) ?? 0.0,
      totalEarnings: double.tryParse(json['total_earnings'].toString()) ?? 0.0,
    );
  }
}

class TeamLeaderChallenge {
  final int id;
  final String title;
  final String description;
  final String rewardAmount;
  final String type;
  final String iconUrl;

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
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
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
    if(!mounted) return;
    setState(() => _isLoading = true);
    try {
      // 1. جلب البيانات الحقيقية من السيرفر
      final data = await _apiService.getTeamLeaderRewards(widget.token);

      if (mounted) {
        setState(() {
          // 2. تعبئة المحفظة من البيانات المسطحة
          _wallet = TeamLeaderWallet.fromJson(data);

          // 3. تعبئة قائمة التحديات
          if (data['challenges'] != null) {
            final list = data['challenges'] as List;
            _challenges = list.map((e) => TeamLeaderChallenge.fromJson(e)).toList();
          } else {
            _challenges = [];
          }
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

  // فتح الواتساب (لطلب الشحن أو التسوية)
  void _openWhatsAppRecharge() async {
    const phone = '9647854076931'; // رقم الواتساب الموحد
    final url = Uri.parse("https://wa.me/$phone?text=${Uri.encodeComponent('مرحباً، أنا تيم ليدر وأرغب بتسوية الحسابات أو شحن الرصيد.')}");
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _handleChallengeAction(int id, String action) async {
    // تحديث الواجهة فوراً لإخفاء التحدي (Optimistic UI)
    final index = _challenges.indexWhere((c) => c.id == id);
    if (index == -1) return;

    final removedChallenge = _challenges[index];

    setState(() {
      _challenges.removeAt(index);
    });

    // إرسال الرد للسيرفر
    final success = await _apiService.respondToChallenge(widget.token, id, action);

    if (!success && mounted) {
      // في حال الفشل، نعيد التحدي للقائمة
      setState(() {
        _challenges.insert(index, removedChallenge);
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("فشل الاتصال، حاول مرة أخرى.")));
    } else {
      // في حال النجاح والقبول
      if(action == 'accept' && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم قبول التحدي! بالتوفيق 💪"), backgroundColor: Colors.green));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("مكافآتي والرصيد", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blueGrey),
            onPressed: _loadData,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // --- البطاقة الأولى: الرصيد المتاح (الأرباح) ---
            _buildWalletCard(
                title: "رصيدي (الأرباح)",
                amount: _wallet?.myBalance ?? 0.0,
                gradientColors: [const Color(0xFF1E3C72), const Color(0xFF2A5298)], // أزرق كحلي أنيق
                icon: Icons.account_balance_wallet,
                textColor: Colors.white,
                actionLabel: "سحب / شحن",
                onActionTap: _openWhatsAppRecharge
            ),

            const SizedBox(height: 15),

            // --- البطاقة الثانية: الديون (تظهر فقط إذا كانت > 0) ---
            if ((_wallet?.liability ?? 0) > 0)
              _buildWalletCard(
                  title: "في ذمتك (للمنصة)",
                  amount: _wallet?.liability ?? 0.0,
                  gradientColors: [Colors.orange.shade800, Colors.red.shade800], // برتقالي محمر للتحذير
                  icon: Icons.warning_amber_rounded,
                  textColor: Colors.white,
                  isLiability: true,
                  actionLabel: "تسديد الآن",
                  onActionTap: _openWhatsAppRecharge
              ),

            const SizedBox(height: 30),

            // --- قسم التحديات ---
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

            // --- عرض التحديات ---
            if (_challenges.isEmpty)
              _buildEmptyState()
            else
              ..._challenges.map((challenge) => _buildChallengeCard(challenge)).toList(),
          ],
        ),
      ),
    );
  }

  // --- Widget: بطاقة المحفظة العصرية ---
  Widget _buildWalletCard({
    required String title,
    required double amount,
    required List<Color> gradientColors,
    required IconData icon,
    required Color textColor,
    bool isLiability = false,
    String? actionLabel,
    VoidCallback? onActionTap,
  }) {
    final format = NumberFormat('#,###', 'ar_IQ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: gradientColors.last.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Stack(
        children: [
          // زخرفة خلفية خفيفة
          Positioned(
            right: -20, top: -20,
            child: Icon(icon, size: 100, color: Colors.white.withOpacity(0.1)),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: Colors.white70, size: 24),
                      const SizedBox(width: 10),
                      Text(title, style: TextStyle(color: textColor.withOpacity(0.9), fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),

                  // زر الإجراء الصغير (شحن/تسديد)
                  if (actionLabel != null)
                    InkWell(
                      onTap: onActionTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Text(actionLabel, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_ios, size: 10, color: Colors.white)
                          ],
                        ),
                      ),
                    )
                ],
              ),

              const SizedBox(height: 25),

              Text(
                "${format.format(amount)} د.ع",
                style: TextStyle(color: textColor, fontSize: 32, fontWeight: FontWeight.bold),
              ),

              if (isLiability)
                Padding(
                  padding: const EdgeInsets.only(top: 5.0),
                  child: const Text(
                    "يرجى تسويتهاعند الوصول الى 50 الف ",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Widget: بطاقة التحدي التفاعلية ---
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
                // أيقونة التحدي
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.emoji_events, color: Colors.amber, size: 30),
                ),
                const SizedBox(width: 15),

                // تفاصيل التحدي
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

          // أزرار التحكم (قبول / تجاهل)
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
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

  // --- Widget: حالة فارغة ---
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

class FoodCard extends StatelessWidget {
  final FoodItem food;
  const FoodCard({super.key, required this.food});

  @override
  Widget build(BuildContext context) {
    final bool canOrder = food.isDeliverable;

    return GestureDetector(
      onTap: () {
        if (canOrder) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => FoodItemBottomSheet(foodItem: food),
          );
        } else {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => DetailScreen(foodItem: food)));
        }
      },
      child: Opacity(
        opacity: canOrder ? 1.0 : 0.5,
        child: Directionality(
          textDirection: TextDirection.rtl, // 🔥 إجبار الواجهة على أن تكون عربية (يمين لليسار)
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 15),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1)), // خط سفلي فاصل
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. قسم النصوص (على اليمين)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10), // مسافة بين النص والصورة
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, // محاذاة لليمين
                      children: [
                        Text(
                          food.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (food.description.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            food.description,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 12),
                        Text(
                          food.formattedPrice,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. قسم الصورة وزر الإضافة (على اليسار)
                Stack(
                  alignment: Alignment.bottomRight, // 🔥 زر الإضافة في الزاوية
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10, right: 10), // مساحة لزر الزائد
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: food.imageUrl,
                          width: 110,
                          height: 110,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!,
                            child: Container(color: Colors.white, width: 110, height: 110),
                          ),
                        ),
                      ),
                    ),
                    if (!canOrder)
                      Positioned(
                        top: 0, bottom: 10, left: 0, right: 10,
                        child: Container(
                          decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(12)),
                          child: const Center(child: Text('غير متاح', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                        ),
                      ),

                    // ➕ زر الإضافة العائم فوق الصورة
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: InkWell(
                        onTap: canOrder
                            ? () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => FoodItemBottomSheet(foodItem: food))
                            : null,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)],
                          ),
                          child: Icon(Icons.add_circle, color: canOrder ? Theme.of(context).primaryColor : Colors.grey, size: 38),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
// =======================================================================
// --- بطاقة المتجر (مطعم / مسواك) الشبكية ---
// =======================================================================
class RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  const RestaurantCard({super.key, required this.restaurant});

  void _showClosedDialog(BuildContext context, Restaurant restaurant) {
    String title = "المتجر مغلق حالياً";
    String message = "لا يستقبل المتجر طلبات الآن.\n\nيفتح تلقائياً في: ${restaurant.autoOpenTime}\nيغلق تلقائياً في: ${restaurant.autoCloseTime}";
    IconData icon = Icons.store_mall_directory_outlined;
    Color iconColor = Colors.red.shade600;

    if (!restaurant.isDeliverable) {
      title = "خارج منطقة التوصيل";
      message = "عذراً، هذا المتجر لا يوصل إلى منطقتك المحددة حالياً.";
      icon = Icons.location_off_outlined;
      iconColor = Colors.orange.shade700;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 14, height: 1.5)),
        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("حسناً", style: TextStyle(fontWeight: FontWeight.bold)))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool canOrder = restaurant.isDeliverable && restaurant.isOpen;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        onTap: canOrder
            ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MenuScreen(restaurant: restaurant)))
            : () => _showClosedDialog(context, restaurant),
        child: Opacity(
          opacity: canOrder ? 1.0 : 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. الصورة
              Expanded(
                flex: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: restaurant.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey[200]),
                      errorWidget: (context, url, error) => const Icon(Icons.storefront, color: Colors.grey, size: 40),
                    ),
                    if (!canOrder)
                      Container(
                        color: Colors.black.withOpacity(0.6),
                        child: Center(
                            child: Text(
                                !restaurant.isDeliverable ? 'خارج\nمنطقتك' : 'مغلق حالياً',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)
                            )
                        ),
                      ),
                  ],
                ),
              ),
              // 2. اسم المطعم والتقييم
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                          restaurant.name,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          Text(" ${restaurant.averageRating.toStringAsFixed(1)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                        ],
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

// =======================================================================
// --- بطاقة الوجبة المخفضة (ModernOfferCard) - متوافقة مع الشبكة ---
// =======================================================================

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
  bool _isNotifyingDriver = false;

  // 🔥 دالة إشعار المندوب بتجهيز الطلب
  Future<void> _notifyDriverReady() async {
    setState(() => _isNotifyingDriver = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final apiService = ApiService();
      final success = await apiService.notifyDriverOrderReady(widget.order.id);

      if (success && mounted) {
        showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 10),
                  Text("تم إرسال الإشعار", style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              content: Text("تم إرسال إشعار للكابتن (${widget.order.driverName}) للتوجه إليك واستلام الطلب."),
              actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("حسناً"))],
            ));
      }
    } catch (e) {
      if (mounted) scaffoldMessenger.showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isNotifyingDriver = false);
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty || phoneNumber == 'N/A') return;
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) await launchUrl(launchUri);
  }

  // تصميم عصري لحالات الطلب
  Map<String, dynamic> _getStatusDetails(String status) {
    switch (status.toLowerCase()) {
      case 'processing':
      case 'pending':
        return {'text': 'جاري البحث عن مندوب ⏳', 'color': Colors.orange.shade700, 'icon': Icons.search, 'bgColor': Colors.orange.shade50};
      case 'driver-assigned':
      case 'accepted':
        return {'text': 'المندوب في الطريق إليك 🛵', 'color': Colors.blue.shade700, 'icon': Icons.check_circle_outline, 'bgColor': Colors.blue.shade50};
      case 'picked_up':
      case 'out-for-delivery':
        return {'text': 'تم استلام الطلب من المطعم 🚀', 'color': Colors.teal.shade700, 'icon': Icons.delivery_dining, 'bgColor': Colors.teal.shade50};
      case 'completed':
      case 'delivered':
        return {'text': 'تم التوصيل للزبون 🎉', 'color': Colors.green.shade700, 'icon': Icons.check_circle, 'bgColor': Colors.green.shade50};
      case 'cancelled':
      case 'failed':
      case 'trash':
        return {'text': 'تم إلغاء الطلب ❌', 'color': Colors.red.shade700, 'icon': Icons.cancel, 'bgColor': Colors.red.shade50};
      default:
        return {'text': status, 'color': Colors.grey.shade700, 'icon': Icons.info_outline, 'bgColor': Colors.grey.shade100};
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('yyyy-MM-dd – hh:mm a', 'ar');
    final formattedDate = formatter.format(widget.order.dateCreated.toLocal());

    bool isFinished = ['completed', 'cancelled', 'refunded', 'failed', 'trash', 'picked_up', 'out-for-delivery', 'delivered'].contains(widget.order.status.toLowerCase());
    bool hasDriver = widget.order.driverName != null && widget.order.driverName!.isNotEmpty;
    bool isCancelled = widget.order.status.toLowerCase() == 'cancelled';

    final statusDetails = _getStatusDetails(widget.order.status);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: isCancelled ? BorderSide(color: Colors.red.shade200, width: 1.5) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. الرأس (تاريخ ورقم الطلب)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: isCancelled ? Colors.grey.shade300 : Colors.teal.shade600,
                      borderRadius: BorderRadius.circular(8)
                  ),
                  child: Text("#${widget.order.id}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                Text(formattedDate, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const Divider(height: 25),

            // 2. تفاصيل الزبون (تم إخفاء رقم الهاتف)
            Row(
              children: [
                CircleAvatar(backgroundColor: isCancelled ? Colors.grey.shade300 : Colors.teal.shade50, child: Icon(Icons.person, color: isCancelled ? Colors.grey : Colors.teal)),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.order.customerName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, decoration: isCancelled ? TextDecoration.lineThrough : null)),
                      const SizedBox(height: 4),
                      Text("العنوان: ${widget.order.address}", style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // 3. محتويات الطلب
            Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: widget.order.lineItems.map((item) => Text("• ${item.quantity} x ${item.name}", style: const TextStyle(fontWeight: FontWeight.w500))).toList()
                )
            ),

            const SizedBox(height: 10),
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("المطلوب من المندوب:", style: TextStyle(color: Colors.grey, fontSize: 14)),
                  Text("${widget.order.total} د.ع", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isCancelled ? Colors.grey : Colors.green)),
                ]
            ),
            const SizedBox(height: 15),

            // 🔥🔥🔥 4. شريط الحالة والمندوب (تصميم سمائي عصري مع رقم الهاتف) 🔥🔥🔥
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: statusDetails['bgColor'],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusDetails['color'].withOpacity(0.3))
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // الجزء العلوي: حالة الطلب
                  Row(
                    children: [
                      Icon(statusDetails['icon'], color: statusDetails['color'], size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                            statusDetails['text'],
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: statusDetails['color'])
                        ),
                      ),

                      // زر الاتصال بالمندوب (دائري أخضر)
                      if (hasDriver && widget.order.driverPhone != null && widget.order.driverPhone!.isNotEmpty)
                        Container(
                          decoration: BoxDecoration(
                            color: isCancelled ? Colors.grey.shade300 : Colors.green.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(Icons.call, color: isCancelled ? Colors.grey : Colors.green.shade700),
                            tooltip: "اتصال بالمندوب",
                            onPressed: () => _makePhoneCall(widget.order.driverPhone!),
                          ),
                        ),
                    ],
                  ),

                  // الجزء السفلي: بطاقة المندوب السمائية 💎 (تظهر فقط إذا وافق السائق)
                  if (hasDriver)
                    Container(
                      margin: const EdgeInsets.only(top: 12.0),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isCancelled ? Colors.grey.shade200 : const Color(0xFFE3F2FD), // لون سمائي فاتح جداً
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isCancelled ? Colors.grey.shade300 : const Color(0xFF90CAF9)), // إطار سمائي
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isCancelled ? Colors.grey.shade300 : const Color(0xFFBBDEFB),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.two_wheeler, size: 20, color: isCancelled ? Colors.grey : const Color(0xFF1565C0)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "الكابتن: ${widget.order.driverName}",
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isCancelled ? Colors.grey : const Color(0xFF0D47A1), // أزرق كحلي
                                      decoration: isCancelled ? TextDecoration.lineThrough : null
                                  ),
                                ),
                                const SizedBox(height: 2),
                                // إضافة رقم الهاتف للسائق باحترافية
                                if (widget.order.driverPhone != null && widget.order.driverPhone!.isNotEmpty)
                                  Row(
                                    children: [
                                      Icon(Icons.phone_android, size: 12, color: isCancelled ? Colors.grey : const Color(0xFF1976D2)),
                                      const SizedBox(width: 4),
                                      Text(
                                        widget.order.driverPhone!,
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: isCancelled ? Colors.grey : const Color(0xFF1976D2),
                                            decoration: isCancelled ? TextDecoration.lineThrough : null
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // 🔥 5. زر (تم تجهيز الطلب) يظهر فقط للمطعم عندما يكون الطلب قيد التنفيذ ولم يستلمه السائق بعد 🔥
            if (!isFinished && hasDriver && !['picked_up', 'out-for-delivery', 'delivered'].contains(widget.order.status.toLowerCase())) ...[
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isNotifyingDriver ? null : _notifyDriverReady,
                  icon: _isNotifyingDriver
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.notifications_active, color: Colors.white),
                  label: Text(_isNotifyingDriver ? "جاري الإرسال..." : "تم تجهيز الطلب - إرسال تنبيه للمندوب"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                  ),
                ),
              )
            ],

            // كود التسليم (إن وجد)
            if (widget.pickupCode != null && !isFinished)
              Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber.shade200)),
                  child: Text("كود التسليم للمندوب: ${widget.pickupCode}", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900, letterSpacing: 1.5))
              ),
          ],
        ),
      ),
    );
  }
}

class DeepTokenDebuggerFAB extends StatefulWidget {
  const DeepTokenDebuggerFAB({super.key});

  @override
  State<DeepTokenDebuggerFAB> createState() => _DeepTokenDebuggerFABState();
}

class _DeepTokenDebuggerFABState extends State<DeepTokenDebuggerFAB> {
  static const platform = MethodChannel('beytei_deep_debugger');

  Future<void> _fetchLogs() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 15),
            Text("جاري سحب السجلات من جذور آبل..."),
          ],
        ),
      ),
    );

    if (!Platform.isIOS) {
      Navigator.pop(context);
      _showConsole("هذه الأداة مخصصة لمعرفة أخطاء الآيفون فقط.");
      return;
    }

    try {
      final Map<dynamic, dynamic> result = await platform.invokeMethod('getLogs');
      final String logs = result['logs'] ?? "لا توجد سجلات بعد.";
      final String token = result['token'] ?? "لم يتم استلام توكن.";

      if (mounted) {
        Navigator.pop(context); // إغلاق التحميل
        _showConsole("🔑 VoIP Token:\n$token\n\n\n📝 سجلات النظام (Log):\n\n$logs");
      }
    } on PlatformException catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showConsole("❌ خطأ في الاتصال بالكود الأصلي: ${e.message}");
      }
    }
  }

  void _showConsole(String logText) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E), // لون يشبه الكونسول
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: const Row(
          children: [
            Icon(Icons.terminal, color: Colors.greenAccent, size: 28),
            SizedBox(width: 10),
            Text("In-App Console", style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400, // ارتفاع الشاشة
          child: SingleChildScrollView(
            child: SelectableText(
              logText,
              style: const TextStyle(
                color: Colors.greenAccent,
                fontSize: 13,
                fontFamily: 'monospace',
                height: 1.5,
              ),
              textDirection: TextDirection.ltr,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: logText));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("تم نسخ السجلات")),
              );
            },
            child: const Text("نسخ الكل", style: TextStyle(color: Colors.blue)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("إغلاق", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: "console_debugger_btn",
      onPressed: _fetchLogs,
      backgroundColor: Colors.black87,
      icon: const Icon(Icons.terminal, color: Colors.greenAccent),
      label: const Text("Console", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
    );
  }
}





class OrderHistoryCard extends StatelessWidget {
  final Order order;
  const OrderHistoryCard({super.key, required this.order});

  // دالة فتح الخريطة
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
              title: 'موقع التوصيل',
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

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('yyyy-MM-dd – hh:mm a', 'ar');
    final formattedDate = formatter.format(order.dateCreated.toLocal());
    final totalFormatted = NumberFormat('#,###', 'ar_IQ').format(double.tryParse(order.total) ?? 0);
    final statusInfo = order.statusDisplay;

    final bool hasCoordinates = (order.destinationLat != null && order.destinationLat!.isNotEmpty);

    // 🔥 تحديد هل الطلب نشط أم منتهي
    final bool isActive = !['completed', 'cancelled', 'refunded', 'failed', 'trash'].contains(order.status.toLowerCase());

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10)
                  ),
                  child: Text('طلب #${order.id}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).primaryColor)),
                ),
                Text(formattedDate, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
            const Divider(height: 24),
            ...order.lineItems.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                  child: Text('${item.quantity}×', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w500))),
              ]),
            )).toList(),

            const Divider(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_outlined, color: Colors.grey.shade400, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: hasCoordinates
                      ? InkWell(
                    onTap: () => _launchMaps(context, order.destinationLat, order.destinationLng),
                    child: Text(
                      "تم تحديد الموقع (اضغط للعرض)",
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                      : Text(order.address, style: TextStyle(color: Colors.grey.shade700)),
                ),
              ],
            ),

            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('الإجمالي', style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
                Text('$totalFormatted د.ع', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),

            // 🔥🔥🔥 الزر الاحترافي للتتبع بدلاً من النص للطلبات النشطة 🔥🔥🔥
            if (isActive)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderTrackingScreen(order: order), // افتح شاشة التتبع
                      ),
                    );
                  },
                  icon: const Icon(Icons.track_changes, color: Colors.white),
                  label: Text(
                    "تتبع الطلب - ${statusInfo['text']}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600, // لون مميز للطلبات النشطة
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              )
            else
            // النص العادي للطلبات المنتهية (تم التوصيل/ملغى)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: statusInfo['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)
                ),
                child: Row(
                  children: [
                    Icon(statusInfo['icon'], color: statusInfo['color'], size: 22),
                    const SizedBox(width: 10),
                    Text('الحالة:', style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        statusInfo['text'],
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: statusInfo['color']),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
class TeamLeaderOrderCard extends StatefulWidget {
  final UnifiedDeliveryOrder order;
  final String token;
  final VoidCallback onActionComplete;

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

  // عرض التفاصيل (محدث ومحسن)
  void _showOrderDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (_, controller) => Container(
            padding: const EdgeInsets.all(20),
            child: ListView(
              controller: controller,
              children: [
                Center(child: Container(width: 50, height: 5, margin: const EdgeInsets.only(bottom: 15), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("تفاصيل الطلب #${widget.order.id}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(widget.order.sourceType == 'market' ? "🛒 مسواك" : "🍔 مطعم", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(height: 25),
                // قائمة المنتجات
                if (widget.order.lineItems.isNotEmpty)
                  ...widget.order.lineItems.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)), child: Text("${item['quantity']}x", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
                        const SizedBox(width: 12),
                        Expanded(child: Text(item['name'] ?? '', style: const TextStyle(fontSize: 16))),
                        Text("${NumberFormat('#,###').format(double.tryParse(item['total'].toString()) ?? 0)} د.ع", style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )).toList()
                else
                  Center(child: Text(widget.order.itemsSummary.isNotEmpty ? widget.order.itemsSummary : "لا توجد تفاصيل إضافية")),
                const Divider(height: 25),
                // الملخص المالي
                _buildSummaryRow("سعر الطلب:", widget.order.orderTotal),
                const SizedBox(height: 8),
                _buildSummaryRow("سعر التوصيل:", widget.order.deliveryFee),
                const Divider(height: 20),
                _buildSummaryRow("الإجمالي الكلي:", widget.order.orderTotal + widget.order.deliveryFee, isBold: true, color: Colors.green),
                const SizedBox(height: 20),

                // معلومات السائق في التفاصيل
                if (widget.order.driverName != null && widget.order.driverName!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        const Icon(Icons.delivery_dining, color: Colors.blue),
                        const SizedBox(width: 10),
                        Expanded(child: Text("المندوب: ${widget.order.driverName}", style: const TextStyle(fontWeight: FontWeight.bold))),
                        if (widget.order.driverPhone != null && widget.order.driverPhone!.isNotEmpty)
                          IconButton(icon: const Icon(Icons.phone, color: Colors.green), onPressed: () => _makePhoneCall(widget.order.driverPhone!)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(ctx), style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[200], foregroundColor: Colors.black), child: const Text("إغلاق"))),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isBold = false, Color? color}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      Text("${NumberFormat('#,###').format(amount)} د.ع", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color ?? Colors.black)),
    ]);
  }

  // 🔥 زر الطوارئ للتيم ليدر (إعادة الإرسال اليدوي)
  Future<void> _emergencyDispatch() async {
    setState(() => _isLoading = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final response = await http.post(
        Uri.parse('$BEYTEI_URL/wp-json/restaurant-app/v1/manual-dispatch-taxi'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json'
        },
        body: json.encode({'order_id': widget.order.id}),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          showDialog(context: context, builder: (ctx) => AlertDialog(
            title: const Text("تم الإرسال 👮‍♂️"),
            content: const Text("تم إرسال إشارة الطوارئ لسيرفر التكسي بنجاح."),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("حسناً"))],
          ));
          widget.onActionComplete();
        }
      } else {
        throw Exception("فشل الإرسال اليدوي");
      }
    } catch (e) {
      if (mounted) scaffoldMessenger.showSnackBar(SnackBar(content: Text("خطأ: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) return;
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) await launchUrl(launchUri);
  }

  // دالة مساعدة للحصول على تفاصيل الحالة بشكل عصري
  Map<String, dynamic> _getStatusDetails(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'processing':
        return {'text': 'جاري البحث عن سائق ⏳', 'color': Colors.orange.shade700, 'icon': Icons.search, 'bgColor': Colors.orange.shade50};
      case 'accepted':
      case 'driver-assigned':
        return {'text': 'تم القبول (في الطريق للمصدر)', 'color': Colors.blue.shade700, 'icon': Icons.check_circle_outline, 'bgColor': Colors.blue.shade50};
      case 'at_store':
        return {'text': 'الكابتن وصل للمصدر 📍', 'color': Colors.indigo.shade700, 'icon': Icons.storefront, 'bgColor': Colors.indigo.shade50};
      case 'picked_up':
      case 'out-for-delivery':
        return {'text': 'تم الاستلام (في الطريق للزبون) 🛵', 'color': Colors.teal.shade700, 'icon': Icons.delivery_dining, 'bgColor': Colors.teal.shade50};
      case 'completed':
      case 'delivered':
        return {'text': 'تم التوصيل بنجاح 🎉', 'color': Colors.green.shade700, 'icon': Icons.check_circle, 'bgColor': Colors.green.shade50};
      case 'cancelled':
      case 'failed':
      case 'refunded':
      case 'trash':
        return {'text': 'تم الإلغاء ❌', 'color': Colors.red.shade700, 'icon': Icons.cancel, 'bgColor': Colors.red.shade50};
      default:
        return {'text': status, 'color': Colors.grey.shade700, 'icon': Icons.info_outline, 'bgColor': Colors.grey.shade100};
    }
  }

  @override
  Widget build(BuildContext context) {
    Color sourceTypeColor = Colors.blue;
    IconData sourceTypeIcon = Icons.info;
    if (widget.order.sourceType == 'restaurant') { sourceTypeColor = Colors.orange; sourceTypeIcon = Icons.restaurant; }
    else if (widget.order.sourceType == 'market') { sourceTypeColor = Colors.purple; sourceTypeIcon = Icons.shopping_basket; }

    bool isActive = !['completed', 'delivered', 'cancelled', 'refunded', 'failed', 'trash'].contains(widget.order.status.toLowerCase());

    // جلب تفاصيل الحالة العصرية
    final statusDetails = _getStatusDetails(widget.order.status);
    final bool isCancelled = widget.order.status.toLowerCase() == 'cancelled';

    double grandTotal = widget.order.orderTotal + widget.order.deliveryFee;

    // تحويل التاريخ
    final DateTime date = DateTime.fromMillisecondsSinceEpoch(widget.order.dateCreated * 1000);
    final String formattedDate = DateFormat('yyyy-MM-dd', 'ar').format(date);
    final String formattedTime = DateFormat('hh:mm a', 'ar').format(date);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // 1. صف التاريخ والوقت
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(formattedDate, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(formattedTime, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 5),

            // 2. الرأس (الرقم والسعر)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  avatar: Icon(sourceTypeIcon, size: 16, color: Colors.white),
                  label: Text("#${widget.order.id}"),
                  backgroundColor: isCancelled ? Colors.grey : sourceTypeColor, // تبهيت اللون إذا ألغي
                  labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                        "${NumberFormat('#,###').format(grandTotal)} د.ع",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isCancelled ? Colors.grey : Colors.green,
                            decoration: isCancelled ? TextDecoration.lineThrough : null // شطب السعر إذا ألغي
                        )
                    ),
                    Text("توصيل: ${NumberFormat('#,###').format(widget.order.deliveryFee)}", style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
            const Divider(),

            // 3. العناوين
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text("من: ${widget.order.pickupName}", style: TextStyle(fontWeight: FontWeight.bold, color: isCancelled ? Colors.grey : Colors.black)),
              subtitle: Text("إلى: ${widget.order.destinationAddress}", maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: IconButton(icon: Icon(Icons.phone, color: isCancelled ? Colors.grey : Colors.green), onPressed: () => _makePhoneCall(widget.order.customerPhone)),
            ),

            // 🔥 4. عرض معلومات المندوب (احترافي ودائم الظهور إن وجد) 🔥
            if (widget.order.driverName != null && widget.order.driverName!.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                    color: isCancelled ? Colors.grey.shade100 : Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isCancelled ? Colors.grey.shade300 : Colors.amber.shade200)
                ),
                child: Row(
                  children: [
                    Icon(Icons.motorcycle, color: isCancelled ? Colors.grey : Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("الكابتن المستلم:", style: TextStyle(fontSize: 10, color: Colors.grey)),
                          Text(widget.order.driverName!, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isCancelled ? Colors.grey : Colors.black)),
                        ],
                      ),
                    ),
                    if (widget.order.driverPhone != null && widget.order.driverPhone!.isNotEmpty)
                      IconButton(
                        icon: Icon(Icons.call, color: isCancelled ? Colors.grey : Colors.green),
                        onPressed: () => _makePhoneCall(widget.order.driverPhone!),
                        tooltip: "اتصل بالسائق",
                      ),
                  ],
                ),
              ),

            const SizedBox(height: 10),

            // 🔥🔥🔥 5. منطقة التحكم الآلي والحالة العصرية 🔥🔥🔥
            Column(
              children: [
                // زر التفاصيل (دائماً موجود)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.list_alt, size: 18),
                    label: const Text("عرض التفاصيل"),
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey.shade300),
                        foregroundColor: Colors.black87
                    ),
                    onPressed: () => _showOrderDetails(context),
                  ),
                ),

                const SizedBox(height: 8),

                // شريط الحالة الآلي (العصري)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: statusDetails['bgColor'],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusDetails['color'].withOpacity(0.5))
                  ),
                  child: Row(
                    children: [
                      Icon(statusDetails['icon'], color: statusDetails['color']),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("الحالة الحالية:", style: TextStyle(fontSize: 10, color: Colors.grey)),
                            Text(
                                statusDetails['text'],
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: statusDetails['color']
                                )
                            ),
                          ],
                        ),
                      ),

                      // زر التدخل (طوارئ) - يظهر فقط إذا لم يكن هناك سائق والطلب ما زال معلقاً
                      if ((widget.order.driverName == null || widget.order.driverName!.isEmpty) && isActive && !isCancelled)
                        IconButton(
                          icon: _isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.refresh, color: Colors.orange),
                          tooltip: "إعادة إرسال الطلب (طوارئ)",
                          onPressed: _isLoading ? null : _emergencyDispatch,
                        )
                    ],
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
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _data;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;
    try {
      final data = await _apiService.getWalletData(token);
      if (mounted) setState(() { _data = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // فتح الواتساب للشحن
  void _openWhatsAppRecharge() async {
    const phone = '9647854076931'; // الرقم الدولي
    const message = 'مرحباً، أرغب بشحن رصيد محفظتي في منصة بيتي.';
    final url = Uri.parse("https://wa.me/$phone?text=${Uri.encodeComponent(message)}");
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  // شراء الإشعار
  void _showBuyNotificationDialog() {
    final TextEditingController _textController = TextEditingController();
    final balance = _data?['wallet_balance'] ?? 0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(children: [Icon(Icons.campaign, color: Colors.orange), SizedBox(width: 10), Text("إعلان للمنطقة")]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("أرسل إشعاراً لجميع المستخدمين في منطقتك لزيادة مبيعاتك! 🚀", style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("تلفة الخدمة:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const Text("5,000 د.ع", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: "اكتب نص العرض هنا... (مثال: خصم 20% اليوم فقط!)",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            if (balance < 5000)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Text("رصيدك الحالي ($balance د.ع) غير كافي.", style: const TextStyle(color: Colors.red, fontSize: 12)),
              )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء")),
          ElevatedButton(
            onPressed: balance < 5000 ? null : () async {
              Navigator.pop(ctx);
              _processPurchase(_textController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text("شراء وإرسال"),
          )
        ],
      ),
    );
  }

  Future<void> _processPurchase(String text) async {
    if(text.isEmpty) return;
    final token = Provider.of<AuthProvider>(context, listen: false).token!;
    // إظهار تحميل
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

    try {
      await _apiService.buyNotification(token, text);
      if(mounted) {
        Navigator.pop(context); // غلق التحميل
        _loadData(); // تحديث الرصيد
        showDialog(context: context, builder: (_) => AlertDialog(
          title: const Text("تم بنجاح! 🎉"),
          content: const Text("تم استلام طلبك وخصم المبلغ. سيتم إرسال الإشعار للمستخدمين بعد المراجعة السريعة."),
          actions: [TextButton(onPressed: ()=>Navigator.pop(context), child: const Text("تم"))],
        ));
      }
    } catch(e) {
      if(mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ: ${e.toString().replaceAll("Exception: ", "")}"), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = Provider.of<AuthProvider>(context).userRole; // owner or leader

    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final walletBalance = _data?['wallet_balance'] ?? 0;
    final totalEarnings = _data?['total_earnings'] ?? 0; // مبيعات المطعم
    final liability = _data?['liability'] ?? 0;
    final challenges = _data?['challenges'] as List? ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text("محفظتي والأرباح"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // بطاقة الأرباح (مبيعات المطعم)
            _buildCard(
              title: "إجمالي المبيعات (مكتملة)",
              amount: totalEarnings,
              color: Colors.green,
              icon: Icons.store,
              subtitle: "جميع الطلبات التي قمت بتجهيزها",
            ),
            const SizedBox(height: 15),

            // بطاقة الرصيد (القابل للشحن)
            _buildCard(
                title: "رصيدي الحالي",
                amount: walletBalance,
                color: const Color(0xFF1E3C72),
                icon: Icons.account_balance_wallet,
                subtitle: "رصيد الخدمات والمكافآت",
                action: ElevatedButton.icon(
                  onPressed: _openWhatsAppRecharge,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("شحن رصيد"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1E3C72),
                    elevation: 0,
                  ),
                )
            ),
            const SizedBox(height: 15),

            // بطاقة الديون (في الذمة)
            if (liability > 0)
              _buildCard(
                title: "مستحقات للمنصة (في ذمتك)",
                amount: liability,
                color: Colors.red.shade700,
                icon: Icons.warning_amber_rounded,
                subtitle: "يرجى تسديدها لتجنب إيقاف الحساب",
              ),

            const SizedBox(height: 25),

            // زر خدمة الإشعار المدفوع (للمطاعم)
            if (role == 'owner') ...[
              const Text("🚀 خدمات التسويق", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              InkWell(
                onTap: _showBuyNotificationDialog,
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.orange.shade400, Colors.deepOrange]),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                        child: const Icon(Icons.campaign, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 15),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("أرسل إشعار للمنطقة", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            Text("الوصول لجميع الزبائن بـ 5,000 د.ع", style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 25),
            ],

            // قسم التحديات
            const Align(alignment: Alignment.centerRight, child: Text("التحديات والعروض 🔥", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            const SizedBox(height: 10),
            if (challenges.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("لا توجد تحديات نشطة حالياً")))
            else
              ...challenges.map((c) => _buildChallengeCard(c)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required dynamic amount, required Color color, required IconData icon, String? subtitle, Widget? action}) {
    final format = NumberFormat('#,###', 'ar_IQ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.white70),
                  const SizedBox(width: 10),
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
              if (action != null) action,
            ],
          ),
          const SizedBox(height: 15),
          Text("${format.format(amount)} د.ع", style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          if (subtitle != null) ...[
            const SizedBox(height: 5),
            Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ]
        ],
      ),
    );
  }

  Widget _buildChallengeCard(dynamic challenge) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: const CircleAvatar(backgroundColor: Colors.amber, child: Icon(Icons.emoji_events, color: Colors.white)),
        title: Text(challenge['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(challenge['description'] ?? ''),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
          child: Text(challenge['reward_amount'] ?? '', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
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

    // 🔥 1. تشغيل مستمع المكالمات (للرد الفوري عبر CallKit)
  }


  Future<void> _initializeServices() async {
    // تهيئة خدمة الإشعارات المحلية الموجودة مسبقاً
    await NotificationService.initialize();

    // طلب صلاحيات الإشعارات
    await FirebaseMessaging.instance.requestPermission();


    // 🔥 4. الاستماع للإشعارات عند النقر عليها لفتح التطبيق (Background to Foreground)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    print("✅ Notification & Call Services Initialized");
  }

  // ==========================================================
  // دالة معالجة الإشعارات أثناء عمل التطبيق (Foreground)
  // ==========================================================

  // ==========================================================
  // دالة معالجة الإشعارات عند فتح التطبيق من الخلفية (Background)
  // ==========================================================
// ==========================================================
  // دالة معالجة الإشعارات عند فتح التطبيق من الخلفية (Background)
  // ==========================================================
  Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    // 1️⃣ معالجة مكالمات الصوت (VoIP)
    if (message.data['type'] == 'voip_call') {
      final channelName = message.data['channelName'] ?? message.data['channel_name'];
      final driverName = message.data['driverName'] ?? message.data['driver_name'] ?? 'الكابتن';

      // حفظ البيانات للتعامل معها بعد انتهاء رسم الواجهة الأساسية
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_call_channel', channelName ?? '');
      await prefs.setString('pending_call_driver', driverName);
      await prefs.setBool('has_pending_call', true);

      // ملاحظة: يمكنك إضافة منطق في شاشتك الرئيسية (MainScreen) لفحص 'has_pending_call'
      // وفتح صفحة المكالمة تلقائياً عند الدخول.

      // محاولة التوجيه المباشر إذا كان التطبيق قد بنى الواجهة
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            // الكود بعد التعديل
            builder: (context) => ActiveVoiceCallScreen(
              channelName: channelName,
              remoteName: driverName,
              // 👇 هذا هو السطر الذي سيحل المشكلة
              onCallEnded: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context); // إغلاق الشاشة عند انتهاء المكالمة
                }
              },
            ),
          ),
        );
      }
    }
    // 2️⃣ 🔥 التعديل الجديد: معالجة إشعارات الدردشة
    else if (message.data['type'] == 'chat_message') {
      final orderId = message.data['order_id'];
      final driverName = message.data['sender_name'] ?? 'المندوب';

      // الانتظار قليلاً لضمان بناء الواجهة الأساسية (مهم جداً لتجنب الشاشة السوداء)
      await Future.delayed(const Duration(milliseconds: 500));

      if (navigatorKey.currentState != null && orderId != null) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => CustomerChatPage(
              orderId: orderId.toString(),
              driverName: driverName,
              customerName: 'الزبون', // يمكن تبديلها باسم الزبون الحقيقي من الـ SharedPreferences لاحقاً إذا أردت
            ),
          ),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => RestaurantSettingsProvider()),
        ChangeNotifierProvider(create: (_) => DeliveryProvider()),
        ChangeNotifierProvider(create: (_) => DeliveryConfigProvider()),
        ChangeNotifierProvider(create: (_) => SmartWalletProvider()),
        ChangeNotifierProxyProvider<AuthProvider, DashboardProvider>(
          create: (_) => DashboardProvider(),
          update: (_, auth, dashboard) {
            if (auth.isLoggedIn && dashboard != null && auth.token != null) {
              dashboard.fetchDashboardData(auth.token!, silent: true);
            }
            return dashboard!;
          },
        ),

        ChangeNotifierProxyProvider<AuthProvider, RestaurantSettingsProvider>(
          create: (_) => RestaurantSettingsProvider(),
          update: (_, auth, settings) {
            if (settings != null && auth.isLoggedIn && auth.token != null) {
              settings.fetchSettings(auth.token);
            } else if (settings != null && !auth.isLoggedIn) {
              settings.clearData();
            }
            return settings!;
          },
        ),

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
        navigatorKey: navigatorKey, // 🔥 مهم جداً للتوجيه الفوري
        title: 'Beytei Restaurants',
        theme: ThemeData(
            primarySwatch: Colors.teal,
            scaffoldBackgroundColor: const Color(0xFFF5F5F5),
            fontFamily: 'Tajawal',
            appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                elevation: 0.5,
                iconTheme: IconThemeData(color: Colors.black),
                titleTextStyle: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal'
                )
            )
        ),
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
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
  Future<int?> _checkLocationAndSubscribe() async {
    final prefs = await SharedPreferences.getInstance();
    final int? areaId = prefs.getInt('selectedAreaId');

    // 🔥 التعديل الجوهري: إذا وجدنا منطقة محفوظة، نعيد الاشتراك فوراً
    if (areaId != null) {
      // لا ننتظر النتيجة (await) لكي لا نعطل فتح التطبيق، نتركها تعمل في الخلفية
      FirebaseMessaging.instance.subscribeToTopic('area_$areaId').then((_) {
        print("✅ [Auto-Subscribe] تم إعادة الاشتراك تلقائياً في: area_$areaId");
      }).catchError((e) {
        print("⚠️ [Auto-Subscribe] فشل الاشتراك: $e");
      });
    }

    return areaId;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int?>(
      future: _checkLocationAndSubscribe(), // نستخدم الدالة المعدلة
      builder: (context, snapshot) {
        // حالة الانتظار
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        // إذا وجدنا بيانات منطقة -> الصفحة الرئيسية
        if (snapshot.hasData && snapshot.data != null) {
          return const MainScreen();
        }

        // إذا لم نجد -> شاشة الترحيب واختيار المنطقة
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
          children: <Widget>[
            _buildOffstageNavigator(0),
            _buildOffstageNavigator(1),
            _buildOffstageNavigator(2),
            _buildOffstageNavigator(3)
          ],
        ),
        bottomNavigationBar: _buildCustomBottomNav(navProvider),
        // ✅ تمت إزالة زر الفحص العائم من هنا لتنظيف الواجهة
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
            case 1: pageBuilder = const CustomerWalletScreen(); break;
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
        const BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'محفظتي'
        ),
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


class CustomerWalletScreen extends StatefulWidget {
  const CustomerWalletScreen({super.key});

  @override
  State<CustomerWalletScreen> createState() => _CustomerWalletScreenState();
}

class _CustomerWalletScreenState extends State<CustomerWalletScreen> {
  int _areaId = 0;
  bool _isCheckingArea = true;

  @override
  void initState() {
    super.initState();
    _checkAreaAndLoadData();
  }

  Future<void> _checkAreaAndLoadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _areaId = prefs.getInt('selectedAreaId') ?? 0;
      _isCheckingArea = false;
    });

    // إذا كانت المنطقة الكوت (84)، نقوم بجلب البيانات
    if (_areaId == 84) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        if (auth.isLoggedIn && auth.token != null) {
          Provider.of<SmartWalletProvider>(context, listen: false).fetchWalletStatus(auth.token!);
        }
      });
    }
  }

  void _showCouponDialog(String code, double amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.celebration, color: Colors.amber, size: 60),
            SizedBox(height: 10),
            Text("مبروك! 🎉", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("لقد حصلت على خصم بقيمة ${NumberFormat('#,###').format(amount)} د.ع", textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border.all(color: Theme.of(context).primaryColor, width: 2),                borderRadius: BorderRadius.circular(10),
              ),
              child: SelectableText(
                code,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor, letterSpacing: 2),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),
            const Text("انسخ الكود واستخدمه في سلة المشتريات للطلب القادم.", style: TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم نسخ الكود بنجاح! 📋"), backgroundColor: Colors.green));
              },
              child: const Text("نسخ الكود وإغلاق", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingArea) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 🛑 حالة: الزبون في منطقة غير الكوت (84)
    if (_areaId != 84) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: const Text('كاش باك بيتي'), centerTitle: true, elevation: 0),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.network('https://cdn-icons-png.flaticon.com/512/7465/7465691.png', width: 150, color: Colors.grey.shade400),
                const SizedBox(height: 20),
                const Text("قريباً في منطقتك! 🚀", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(
                  "نظام الكاش باك الذكي متاح حالياً حصرياً في محافظة واسط (الكوت) فقط. نعمل على توسيع الخدمة لتشمل منطقتك قريباً.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade600, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // --- إذا كانت المنطقة 84 (الكوت) ---
    final auth = Provider.of<AuthProvider>(context);
    final wallet = Provider.of<SmartWalletProvider>(context);

    // 🛑 حالة: الزبون غير مسجل دخول
    if (!auth.isLoggedIn) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: const Text('كاش باك بيتي'), centerTitle: true, elevation: 0),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wallet_giftcard_rounded, size: 100, color: Colors.amber),
                const SizedBox(height: 20),
                const Text("سجل دخولك لتبدأ التجميع! 💰", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(
                  "اطلب 4 مرات من مطاعم بيتي في الكوت، واحصل على 10% كاش باك كود خصم لطلبك الخامس!",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade600, height: 1.5),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                  ),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerLoginScreen()));
                  },
                  child: const Text("تسجيل الدخول / إنشاء حساب", style: TextStyle(fontSize: 18, color: Colors.white)),
                )
              ],
            ),
          ),
        ),
      );
    }

    // 🟢 حالة: الزبون مسجل دخول وفي الكوت
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text('كاش باك بيتي 🎁', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: wallet.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () => wallet.fetchWalletStatus(auth.token!),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // --- 1. بطاقة الرصيد المتراكم العصرية ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [BoxShadow(color: const Color(0xFF2575FC).withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.savings_outlined, color: Colors.white70, size: 24),
                      SizedBox(width: 8),
                      Text("رصيد الكاش باك المتراكم", style: TextStyle(color: Colors.white70, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "${NumberFormat('#,###').format(wallet.accumulatedDiscount)} د.ع",
                    style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  const Text("يتم احتساب 10% من قيمة الوجبات لطلباتك المنجزة.", style: TextStyle(color: Colors.white60, fontSize: 12)),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- 2. شريط التقدم العصري ---
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("تقدمك الحالي", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(20)),
                        child: Text("${wallet.currentOrders} / ${wallet.targetOrders} طلبات", style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const SizedBox(height: 25),

                  // تصميم دوائر التقدم
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(wallet.targetOrders, (index) {
                      bool isCompleted = index < wallet.currentOrders;
                      return Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isCompleted ? Colors.green : Colors.grey.shade200,
                                shape: BoxShape.circle,
                                boxShadow: isCompleted ? [BoxShadow(color: Colors.green.withOpacity(0.4), blurRadius: 8)] : [],
                              ),
                              child: Center(
                                child: isCompleted
                                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                                    : Text("${index + 1}", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                            ),
                            if (index < wallet.targetOrders - 1)
                              Expanded(
                                child: Container(
                                  height: 4,
                                  color: isCompleted ? Colors.green : Colors.grey.shade200,
                                ),
                              )
                          ],
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 30),

                  // رسالة التحفيز
                  Center(
                    child: Text(
                      wallet.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: wallet.canClaim ? Colors.green.shade700 : Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // --- 3. زر المطالبة بالكوبون ---
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: (!wallet.canClaim || wallet.isClaiming) ? null : () async {
                        bool success = await wallet.claimDiscount(auth.token!, context);
                        if (success && wallet.lastCouponCode != null) {
                          _showCouponDialog(wallet.lastCouponCode!, wallet.accumulatedDiscount);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade600,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        elevation: wallet.canClaim ? 5 : 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: wallet.isClaiming
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("استخراج كود الخصم 🎁", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}









class CustomerLoginScreen extends StatefulWidget {
  const CustomerLoginScreen({super.key});

  @override
  State<CustomerLoginScreen> createState() => _CustomerLoginScreenState();
}

class _CustomerLoginScreenState extends State<CustomerLoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController(); // يستخدم فقط عند إنشاء حساب جديد

  bool _isLoading = false;
  bool _isNewUser = false; // للتبديل بين واجهة الدخول والتسجيل
  bool _obscurePassword = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // 🔥 دالة الدخول / التسجيل المدمجة
  // ===========================================================================
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    try {
      // 1. تحديد الرابط (الباك إند الخاص بك يقوم بتحويل التسجيل إلى دخول إذا كان الرقم موجوداً)
      // تأكد أن TAXI_URL معرف في ثوابت التطبيق الخاص بك
      final String apiUrl = 'https://banner.beytei.com/wp-json/taxi-auth/v1/register/customer';

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phone_number': phone,
          'password': password,
          'name': name.isEmpty ? 'زبون بيتي' : name, // اسم افتراضي إذا كان دخولا فقط
        }),
      ).timeout(const Duration(seconds: 15));

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // ✅ نجاح العملية (سواء دخول أو إنشاء حساب)
        final String token = data['token'];

        // حفظ التوكن في الجهاز
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
        await prefs.setString('user_role', 'customer');

        // تحديث الـ Provider
        if (mounted) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          await authProvider.login(phone, password, 'customer'); // تحديث حالة التطبيق الداخلية

          // تسجيل التوكن للإشعارات (FCM)
          AuthService().registerDeviceTokenTriple(token, null, null);

          Navigator.pop(context); // إغلاق شاشة الدخول
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("تم تسجيل الدخول بنجاح! مرحباً بك 🚀"),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        // ❌ خطأ في الدخول (مثلاً الباسورد خطأ أو الرقم محظور)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'تأكد من رقم الهاتف وكلمة المرور.'),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("تعذر الاتصال بالسيرفر، يرجى المحاولة لاحقاً."),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ===========================================================================
  // 🎨 بناء الواجهة العصرية
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- الهيدر (صورة وتحدي المحفظة) ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 80, bottom: 40, left: 20, right: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Theme.of(context).primaryColor, const Color(0xFF00897B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
                boxShadow: [BoxShadow(color: Theme.of(context).primaryColor.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: const Column(
                children: [
                  Icon(Icons.account_balance_wallet, size: 80, color: Colors.white),
                  SizedBox(height: 15),
                  Text("تحدي بيتي 🏆", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(height: 8),
                  Text("سجل دخولك، اطلب 5 طلبات، وخصم الباقي علينا!", textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Colors.white70)),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- الفورم ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // تبديل بين تسجيل الدخول وحساب جديد
                    Container(
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(15)),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _isNewUser = false);
                                _animationController.reverse();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: !_isNewUser ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: !_isNewUser ? [BoxShadow(color: Colors.grey.shade300, blurRadius: 5)] : [],
                                ),
                                child: Center(child: Text("تسجيل دخول", style: TextStyle(fontWeight: FontWeight.bold, color: !_isNewUser ? Theme.of(context).primaryColor : Colors.grey))),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _isNewUser = true);
                                _animationController.forward();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _isNewUser ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: _isNewUser ? [BoxShadow(color: Colors.grey.shade300, blurRadius: 5)] : [],
                                ),
                                child: Center(child: Text("حساب جديد", style: TextStyle(fontWeight: FontWeight.bold, color: _isNewUser ? Theme.of(context).primaryColor : Colors.grey))),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // حقل الاسم (يظهر فقط في حالة الحساب الجديد)
                    SizeTransition(
                      sizeFactor: _fadeAnimation,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'الاسم الكريم',
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                            ),
                            validator: (v) => _isNewUser && v!.isEmpty ? 'الرجاء إدخال اسمك' : null,
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),

                    // حقل الهاتف
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'رقم الهاتف',
                        prefixIcon: const Icon(Icons.phone_android),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                      validator: (v) => v!.isEmpty ? 'الرجاء إدخال رقم الهاتف' : null,
                    ),
                    const SizedBox(height: 20),

                    // حقل كلمة المرور
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                      validator: (v) {
                        if (v!.isEmpty) return 'الرجاء إدخال كلمة المرور';
                        if (_isNewUser && v.length < 6) return 'يجب أن لا تقل عن 6 رموز';
                        return null;
                      },
                    ),
                    const SizedBox(height: 40),

                    // زر الإرسال
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 3,
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 25, height: 25, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(
                          _isNewUser ? "إنشاء حساب وبدء التحدي" : "دخول",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
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






// =======================================================================
// --- البطاقات العصرية (Modern Cards) للمسواك والمطاعم ---
// =======================================================================

// 1. بطاقة العروض في قسم (المحلات الأكثر شيوعاً)
class ModernPromoCard extends StatelessWidget {
  final Offer offer;
  final List<Restaurant> allStores;

  const ModernPromoCard({super.key, required this.offer, required this.allStores});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        try {
          final restaurant = allStores.firstWhere((r) => r.id == offer.restaurantId);
          Navigator.push(context, MaterialPageRoute(builder: (_) => MenuScreen(restaurant: restaurant)));
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('المتجر غير متاح حالياً')));
        }
      },
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(left: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          image: DecorationImage(
            image: CachedNetworkImageProvider(offer.imageUrl),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              colors: [Colors.black.withOpacity(0.8), Colors.transparent],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
          padding: const EdgeInsets.all(12),
          alignment: Alignment.bottomRight,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                offer.title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4)
                ),
                child: const Text("عرض خاص", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// 2. بطاقة المطعم الأفقية (لقسم أفضل المطاعم)
// 2. بطاقة المطعم الأفقية (لقسم أفضل المطاعم)
class ModernHorizontalRestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  const ModernHorizontalRestaurantCard({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    bool canOrder = restaurant.isDeliverable && restaurant.isOpen;

    return GestureDetector(
      onTap: () {
        if (canOrder) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => MenuScreen(restaurant: restaurant)));
        } else {
          _showClosedDialog(context, restaurant);
        }
      },
      child: Opacity(
        opacity: canOrder ? 1.0 : 0.6,
        child: Container(
          width: 280,
          margin: const EdgeInsets.only(left: 12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: restaurant.imageUrl,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey[200]),
                  errorWidget: (context, url, error) => Container(color: Colors.grey[200], child: const Icon(Icons.store)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            restaurant.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(color: Colors.purple, borderRadius: BorderRadius.circular(4)),
                          child: const Text("Pro", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        Text(" ${restaurant.averageRating.toStringAsFixed(1)}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    if (!canOrder)
                      const Padding(
                        padding: EdgeInsets.only(top: 4.0),
                        child: Text("مغلق أو خارج التغطية", style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                      )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClosedDialog(BuildContext context, Restaurant restaurant) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("عذراً"),
        content: Text(!restaurant.isDeliverable ? "هذا المتجر لا يوصل لمنطقتك المحددة حالياً." : "المتجر مغلق حالياً. يفتح في: ${restaurant.autoOpenTime}"),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("حسناً"))],
      ),
    );
  }
}


// 3. بطاقة المتجر العمودية (للقائمة الرئيسية السفلية)
class ModernVerticalRestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  const ModernVerticalRestaurantCard({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    bool canOrder = restaurant.isDeliverable && restaurant.isOpen;

    return GestureDetector(
      onTap: () {
        if (canOrder) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => MenuScreen(restaurant: restaurant)));
        } else {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: const Text("عذراً"),
              content: Text(!restaurant.isDeliverable ? "هذا المتجر لا يوصل لمنطقتك المحددة حالياً." : "المتجر مغلق حالياً. يفتح في: ${restaurant.autoOpenTime}"),
              actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("حسناً"))],
            ),
          );
        }
      },
      child: Opacity(
        opacity: canOrder ? 1.0 : 0.6,
        child: Container(
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    child: CachedNetworkImage(
                      imageUrl: restaurant.imageUrl,
                      width: double.infinity,
                      height: 150,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey[200], height: 150),
                      errorWidget: (context, url, error) => Container(color: Colors.grey[200], height: 150, child: const Icon(Icons.store, size: 50)),
                    ),
                  ),
                  if (!canOrder)
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                      ),
                      child: Center(
                          child: Text(
                              !restaurant.isDeliverable ? 'خارج\nمنطقتك' : 'مغلق حالياً',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                          )
                      ),
                    ),
                  Positioned(
                    top: 10, right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(restaurant.averageRating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                  )
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(restaurant.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    if (restaurant.storeType == 'market')
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.shopping_basket, color: Colors.green, size: 20),
                      )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
// =======================================================================
// --- شاشة الزبون الرئيسية (HomeScreen) ---
// =======================================================================
// =======================================================================
// --- شاشة الزبون الرئيسية (HomeScreen) المحدثة مع Slivers ---
// =======================================================================
// =======================================================================
// --- شاشة الزبون الرئيسية (HomeScreen) المحدثة مع 6 أيقونات ---
// =======================================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  int? _selectedAreaId;
  String? _selectedAreaName;

  // فلاتر الواجهة
  String _activeMainCategory = 'all'; // all, restaurant, market, pastry, grocery, meat, offers

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

    Provider.of<DeliveryConfigProvider>(context, listen: false).fetchAndCacheConfig();

    if (_selectedAreaId != null) {
      final provider = Provider.of<CustomerProvider>(context, listen: false);
      provider.fetchHomeData(_selectedAreaId!, isRefresh: false);
      provider.fetchOffers(_selectedAreaId!);
    }
    setState(() {});
  }

  void _onSearchSubmitted(String query) {
    if (query.isNotEmpty && _selectedAreaId != null) {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => SearchScreen(searchQuery: query, selectedAreaId: _selectedAreaId!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: _buildProMaxAppBar(),
      body: Consumer<CustomerProvider>(
        builder: (context, provider, child) {
          if (_selectedAreaId == null) {
            return const Center(child: Text("يرجى تحديد منطقة لعرض المتاجر"));
          }

          if (provider.hasError && provider.homeData.isEmpty) {
            return NetworkErrorWidget(
                message: 'تحقق من اتصال الانترنيت.',
                onRetry: () => provider.fetchHomeData(_selectedAreaId!, isRefresh: true));
          }

          final allStores = (provider.homeData['restaurants'] as List<dynamic>? ?? []).cast<Restaurant>();

          // 🔥 فلترة ذكية حسب التصنيف
          List<Restaurant> filteredStores = allStores.where((store) {
            if (_activeMainCategory == 'all') return true;
            if (_activeMainCategory == 'offers') return false;
            return store.storeType == _activeMainCategory;
          }).toList();

          return RefreshIndicator(
            onRefresh: () async {
              provider.fetchHomeData(_selectedAreaId!, isRefresh: true);
              provider.fetchOffers(_selectedAreaId!);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // 1. شريط البحث
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 15),
                    child: _buildModernSearchBar(),
                  ),
                ),

                // 2. الأيقونات الرئيسية الستة (Sticky Header)
                SliverPersistentHeader(
                  pinned: true,
                  floating: false,
                  delegate: _StickyTopCategoriesDelegate(
                    child: Container(
                      color: const Color(0xFFF9F9F9),
                      padding: const EdgeInsets.only(bottom: 5, top: 5),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF9F9F9),
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xFF00BCD4),
                            width: 2.0,
                          ),
                        ),
                      ),
                      child: _buildTopCategories(), // 👈 الدالة المعدلة
                    ),
                    height: 95.0, // 🔥 تم تقليل الارتفاع ليتناسب مع الأيقونات الصغيرة
                  ),
                ),

                // 3. المحتوى المتغير (عروض ومطاعم)
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      if (_activeMainCategory == 'offers') ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
                          child: Text("جميع الوجبات المخفضة 🔥", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ),
                        if (provider.activeOffers.isEmpty)
                          const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("لا توجد عروض حالياً.")))
                        else
                          GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.70,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: provider.activeOffers.length,
                            itemBuilder: (ctx, i) => ModernOfferCard(
                              offer: provider.activeOffers[i],
                              allStores: allStores,
                            ),
                          ),
                        const SizedBox(height: 30),
                      ]
                      else ...[
                        if (provider.activeOffers.isNotEmpty && _activeMainCategory == 'all') ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text("عروض حصرية 🔥", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 360,
                            child: GridView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 0.65,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                              ),
                              itemCount: provider.activeOffers.length,
                              itemBuilder: (ctx, i) => ModernOfferCard(
                                offer: provider.activeOffers[i],
                                allStores: allStores,
                              ),
                            ),
                          ),
                          const SizedBox(height: 25),
                        ],

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5),
                          child: Text(
                              _getCategoryTitle(_activeMainCategory),
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
                          ),
                        ),

                        if (provider.isLoadingHome && filteredStores.isEmpty)
                          const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator()))
                        else if (filteredStores.isEmpty)
                          const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("لا توجد متاجر مطابقة في هذا القسم.")))
                        else
                          GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: filteredStores.length,
                            itemBuilder: (ctx, i) => RestaurantCard(restaurant: filteredStores[i]),
                          ),
                        const SizedBox(height: 30),
                      ]
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getCategoryTitle(String category) {
    switch (category) {
      case 'market': return "أسواق المسواك";
      case 'pastry': return "المعجنات والحلويات";
      case 'grocery': return "الماركت والبقالة";
      case 'meat': return "القصابة واللحوم";
      case 'restaurant': return "المطاعم المتاحة";
      default: return "أفضل المتاجر";
    }
  }

  AppBar _buildProMaxAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: SecretAdminButton(
        icon: Icons.admin_panel_settings,
        onUnlock: () {
          final auth = Provider.of<AuthProvider>(context, listen: false);
          if (!auth.isLoggedIn) {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TeamLeaderLoginScreen()));
          } else if (auth.userRole == 'leader') {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => RegionDashboardScreen(token: auth.token!, areaId: 0, areaName: "منطقتك")));
          }
        },
      ),
      title: InkWell(
        onTap: () async {
          final result = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SelectLocationScreen(isCancellable: true)));
          if (result == true) _loadInitialData();
        },
        child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_selectedAreaName ?? "اختر منطقة", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
              const Icon(Icons.keyboard_arrow_down, size: 20, color: Colors.black)
            ]
        ),
      ),
      centerTitle: true,
      actions: [
        SecretAdminButton(
          icon: Icons.store,
          onUnlock: () {
            final auth = Provider.of<AuthProvider>(context, listen: false);
            if (!auth.isLoggedIn) {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RestaurantLoginScreen()));
            } else if (auth.userRole == 'owner') {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RestaurantDashboardScreen()));
            }
          },
        ),
      ],
    );
  }

  Widget _buildModernSearchBar() {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onSubmitted: _onSearchSubmitted,
        decoration: const InputDecoration(
          hintText: 'ابحث عن وجبة، مطعم...',
          hintStyle: TextStyle(fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  // 🔥 بناء الأقسام: تم تصغير الأيقونات وتوزيعها بمسافات متساوية لظهور 6 أيقونات معاً
  Widget _buildTopCategories() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // 👈 يوزع الـ 6 أيقونات بمسافات متساوية
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildCategoryImage(
              title: "المطاعم",
              imagePath: 'assets/icon/restaurant_icon.png',
              isSelected: _activeMainCategory == 'restaurant',
              onTap: () => setState(() => _activeMainCategory = _activeMainCategory == 'restaurant' ? 'all' : 'restaurant'),
            ),
          ),
          Expanded(
            child: _buildCategoryImage(
              title: "مسواك",
              imagePath: 'assets/icon/market_icon.png',
              isSelected: _activeMainCategory == 'market',
              onTap: () => setState(() => _activeMainCategory = _activeMainCategory == 'market' ? 'all' : 'market'),
            ),
          ),



          Expanded(
            child: _buildCategoryImage(
              title: "عروض",
              imagePath: 'assets/icon/offer_icon.png',
              isSelected: _activeMainCategory == 'offers',
              onTap: () => setState(() => _activeMainCategory = _activeMainCategory == 'offers' ? 'all' : 'offers'),
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 دالة بناء الأيقونة تم تصغير الأبعاد فيها
  Widget _buildCategoryImage({required String title, required String imagePath, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52, // 👈 تم التصغير من 75 إلى 52 ليتسع لـ 6 أيقونات
            height: 52, // 👈 تم التصغير من 75 إلى 52
            decoration: BoxDecoration(
              color: isSelected ? Colors.cyan.shade50 : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: isSelected ? Border.all(color: const Color(0xFF00BCD4), width: 1.5) : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, color: Colors.grey, size: 24),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1, // سطر واحد فقط
            overflow: TextOverflow.visible,
            style: TextStyle(
                fontSize: 10, // 👈 تم التصغير ليتناسب مع الحجم الجديد
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: Colors.black87
            ),
          ),
        ],
      ),
    );
  }
}

// =======================================================================
// --- كلاس مساعد لتثبيت الأقسام في أعلى الشاشة (Sticky Header) ---
// =======================================================================
class _StickyTopCategoriesDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _StickyTopCategoriesDelegate({required this.child, required this.height});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
// =======================================================================
// --- كلاس مساعد لتثبيت الأقسام في أعلى الشاشة (Sticky Header) ---
// =======================================================================


// =======================================================================
// --- كلاس مساعد لتثبيت الأقسام في أعلى الشاشة (Sticky Header) ---
// =======================================================================


























// =======================================================================
// --- بطاقة المتجر (مطعم / مسواك) الشبكية ---
// =======================================================================

// =======================================================================
// --- بطاقة الوجبة المخفضة (ModernOfferCard) - متوافقة مع الشبكة ---
// =======================================================================

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
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final areas = await _apiService.getAreas();
      if (mounted) {
        setState(() {
          _allAreas = areas;
          _filteredAreas = areas;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterAreas() {
    final query = _searchController.text.toLowerCase();
    setState(() => _filteredAreas = _allAreas
        .where((area) => area.name.toLowerCase().contains(query))
        .toList());
  }

  // 🔥🔥🔥 الدالة المعدلة والمصححة 🔥🔥🔥
  Future<void> _saveSelection(int areaId, String areaName) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. ✅ خطوة هامة: جلب المنطقة القديمة *قبل* حفظ المنطقة الجديدة
    // لكي نتمكن من إلغاء الاشتراك منها
    int? oldAreaId = prefs.getInt('selectedAreaId');

    // 2. إلغاء الاشتراك من القناة القديمة (لتجنب استلام تحديثات منطقة لم تعد فيها)
    if (oldAreaId != null && oldAreaId != areaId) {
      await FirebaseMessaging.instance.unsubscribeFromTopic('area_$oldAreaId');
      print("🔕 تم إلغاء الاشتراك من area_$oldAreaId");
    }

    // 3. الاشتراك في القناة الجديدة (لاستلام تحديثات فتح/غلق المطاعم)
    await FirebaseMessaging.instance.subscribeToTopic('area_$areaId');
    print("🔔 تم الاشتراك في area_$areaId");

    // 4. حفظ البيانات الجديدة محلياً
    await prefs.setInt('selectedAreaId', areaId);
    await prefs.setString('selectedAreaName', areaName);

    // 5. تسجيل التوكن في الباك إند (Fire and Forget - لا ننتظره)
    AuthService().registerDeviceToken(areaId: areaId).then((_) {
      print("✅ تم تحديث المنطقة في السيرفر");
    }).catchError((e) {
      print("⚠️ تنبيه: فشل تحديث المنطقة في السيرفر (غير مؤثر): $e");
    });

    // 6. الانتقال للصفحة التالية فوراً
    if (mounted) {
      if (widget.isCancellable) {
        Navigator.of(context).pop(true);
      } else {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LocationCheckWrapper()),
                (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // تجميع المحافظات (الأب = 0)
    final governorates = _filteredAreas.where((a) => a.parentId == 0).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('اختر منطقة التوصيل'),
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
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade200,
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _hasError
                ? NetworkErrorWidget(
              message: "فشل تحميل المناطق",
              onRetry: _loadAreas,
            )
                : ListView.builder(
              itemCount: governorates.length,
              itemBuilder: (context, index) {
                final governorate = governorates[index];
                // جلب المدن التابعة لهذه المحافظة
                final cities = _filteredAreas
                    .where((a) => a.parentId == governorate.id)
                    .toList();

                return ExpansionTile(
                  title: Text(
                    governorate.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  children: cities
                      .map((city) => ListTile(
                    title: Text(city.name),
                    onTap: () => _saveSelection(city.id, city.name),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  ))
                      .toList(),
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

class _MenuScreenState extends State<MenuScreen> {
  int _selectedCategoryId = 0;
  List<dynamic> _subcategories = [];
  bool _isLoadingCats = true;
  bool _shouldClearCart = true;

  final ScrollController _scrollController = ScrollController();
  final ScrollController _categoryScrollController = ScrollController();
  final Map<int, GlobalKey> _categoryKeys = {};
  bool _isAutoScrolling = false;

  // 🔥 دالة ذكية لتحديد ما إذا كان المتجر يدعم نظام الأوزان (سوق، خضروات، قصابة)
  bool get _isMarketSystem {
    // إذا كان النوع ليس مطعماً، فهو نظام سوق (خضروات، ماركت، لحوم)
    return widget.restaurant.storeType != 'restaurant';
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initData();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _categoryScrollController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    final provider = Provider.of<CustomerProvider>(context, listen: false);
    await provider.fetchMenuForRestaurant(widget.restaurant.id);
    _checkRestaurantStatusNow();

    try {
      final cats = await ApiService().getSubcategories(widget.restaurant.id);
      if (mounted) {
        setState(() {
          _subcategories = cats;
          _isLoadingCats = false;
        });

        _categoryKeys[0] = GlobalKey();
        for (var cat in _subcategories) {
          _categoryKeys[cat['id']] = GlobalKey();
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingCats = false);
    }
  }

  void _onScroll() {
    if (_isAutoScrolling || _categoryKeys.isEmpty) return;

    int newActiveId = _selectedCategoryId;

    for (var cat in _subcategories.reversed) {
      final key = _categoryKeys[cat['id']];
      if (key != null && key.currentContext != null) {
        final renderBox = key.currentContext!.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final position = renderBox.localToGlobal(Offset.zero).dy;
          if (position > 0 && position <= 300) {
            newActiveId = cat['id'];
            break;
          } else if (position <= 0) {
            newActiveId = cat['id'];
            break;
          }
        }
      }
    }

    if (_scrollController.offset <= 50 && _categoryKeys[0] != null) {
      newActiveId = 0;
    }

    if (_selectedCategoryId != newActiveId) {
      setState(() => _selectedCategoryId = newActiveId);
      _scrollCategoryBarToActive(newActiveId);
    }
  }

  void _scrollToCategory(int id) async {
    setState(() {
      _selectedCategoryId = id;
      _isAutoScrolling = true;
    });

    _scrollCategoryBarToActive(id);

    final key = _categoryKeys[id];
    if (key != null && key.currentContext != null) {
      final RenderBox renderBox = key.currentContext!.findRenderObject() as RenderBox;
      final double yPosition = renderBox.localToGlobal(Offset.zero).dy;

      double targetOffset = _scrollController.offset + yPosition - 180.0;

      if (targetOffset < 0) targetOffset = 0;
      if (_scrollController.hasClients && targetOffset > _scrollController.position.maxScrollExtent) {
        targetOffset = _scrollController.position.maxScrollExtent;
      }

      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }

    await Future.delayed(const Duration(milliseconds: 600));
    _isAutoScrolling = false;
  }

  void _scrollCategoryBarToActive(int id) {
    if (!_categoryScrollController.hasClients) return;

    int index = 0;
    if (id != 0) {
      index = _subcategories.indexWhere((c) => c['id'] == id) + 1;
    }

    double offset = index * 100.0;
    _categoryScrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<bool> _onWillPop() async {
    if (!_shouldClearCart) return true;

    final cart = Provider.of<CartProvider>(context, listen: false);
    if (cart.cartCount > 0) {
      bool? exit = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text("تفريغ السلة", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text("سيتم تفريغ محتويات السلة، هل أنت متأكد؟", textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, minimumSize: const Size(100, 40)),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("نعم", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade200, minimumSize: const Size(100, 40)),
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("لا", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (exit == true) {
        cart.clearCart();
        return true;
      } else {
        return false;
      }
    }
    return true;
  }

  Future<void> _checkRestaurantStatusNow() async {
    final provider = Provider.of<CustomerProvider>(context, listen: false);
    try {
      final statusList = await ApiService().checkRestaurantsStatusLight([widget.restaurant.id]);
      if (statusList.isNotEmpty && mounted) {
        final status = statusList.first;
        if (status['is_open'] != true) {
          provider.updateSingleRestaurantStatus(widget.restaurant.id, false, status['auto_open'], status['auto_close']);
          if (mounted) {
            showDialog(
              context: context, barrierDismissible: false,
              builder: (ctx) => AlertDialog(
                title: const Text("تنبيه 🛑", style: TextStyle(fontWeight: FontWeight.bold)),
                content: const Text("عذراً، هذا المطعم أغلق للتو ولا يمكن استقبال طلبات جديدة حالياً."),
                actions: [TextButton(onPressed: () { Navigator.pop(ctx); Navigator.pop(context); }, child: const Text("حسناً"))],
              ),
            );
          }
        }
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              expandedHeight: 220.0,
              pinned: true,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                ),
                onPressed: () async {
                  if (await _onWillPop()) {
                    if (mounted) Navigator.pop(context);
                  }
                },
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(imageUrl: widget.restaurant.imageUrl, fit: BoxFit.cover),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.topCenter, end: Alignment.bottomCenter,
                            colors: [Colors.black.withOpacity(0.4), Colors.transparent, Colors.black.withOpacity(0.9)],
                            stops: const [0.0, 0.4, 1.0]
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 15, left: 15, right: 15,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.restaurant.name, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                                child: Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 16),
                                    const SizedBox(width: 4),
                                    Text("${widget.restaurant.averageRating} (${widget.restaurant.ratingCount}+)", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                                child: const Row(
                                  children: [
                                    Icon(Icons.delivery_dining, color: Colors.white, size: 16),
                                    SizedBox(width: 4),
                                    Text("توصيل بيتي", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                  ],
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyCategoryDelegate(
                child: Container(
                  color: Colors.white,
                  decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1))
                  ),
                  child: _isLoadingCats
                      ? const Center(child: CircularProgressIndicator())
                      : ListView(
                    controller: _categoryScrollController,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    children: [
                      _buildCategoryChipWithImage(0, "الكل", "🌐"),
                      ..._subcategories.map((cat) => _buildCategoryChipWithImage(
                        cat['id'] as int,
                        cat['name'] as String,
                        cat['icon'] as String? ?? "🍽️",
                      )),
                    ],
                  ),
                ),
              ),
            ),

            Consumer<CustomerProvider>(
              builder: (context, provider, child) {
                final menu = provider.menuItems[widget.restaurant.id] ?? [];

                if (provider.isLoadingMenu && menu.isEmpty) {
                  return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
                }

                if (menu.isEmpty) {
                  Restaurant currentRest = provider.allRestaurants.firstWhere((r) => r.id == widget.restaurant.id, orElse: () => widget.restaurant);
                  if (!currentRest.isOpen) {
                    return SliverFillRemaining(
                        child: Center(child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.door_sliding_outlined, size: 80, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            const Text("المطعم مغلق حالياً", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text("يفتح تلقائياً في: ${currentRest.autoOpenTime}", style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
                          ],
                        ))
                    );
                  }
                  return const SliverFillRemaining(child: Center(child: Text("المطعم لا يحتوي على وجبات حالياً")));
                }

                List<Widget> columnChildren = [];

                if (_subcategories.isEmpty) {
                  columnChildren.add(Container(key: _categoryKeys[0]));
                  for (var item in menu) {
                    // 🔥 تم تمرير _isMarketSystem هنا
                    columnChildren.add(_buildThemedFoodCard(item));
                  }
                } else {
                  columnChildren.add(Container(key: _categoryKeys[0]));

                  for (var cat in _subcategories) {
                    final catItems = menu.where((item) => item.allCategoryIds.contains(cat['id'])).toList();
                    if (catItems.isEmpty) continue;

                    columnChildren.add(
                      Container(
                        key: _categoryKeys[cat['id']],
                        width: double.infinity,
                        color: Colors.grey.shade50,
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                        child: Text(cat['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    );

                    for (var item in catItems) {
                      // 🔥 تم تمرير _isMarketSystem هنا
                      columnChildren.add(_buildThemedFoodCard(item));
                    }
                  }

                  final subcatIds = _subcategories.map((c) => c['id']).toList();
                  final uncategorized = menu.where((item) => !item.allCategoryIds.any((id) => subcatIds.contains(id))).toList();
                  if (uncategorized.isNotEmpty) {
                    columnChildren.add(
                      Container(
                        width: double.infinity,
                        color: Colors.grey.shade50,
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                        child: const Text("أخرى", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    );
                    for (var item in uncategorized) {
                      // 🔥 تم تمرير _isMarketSystem هنا
                      columnChildren.add(_buildThemedFoodCard(item));
                    }
                  }
                }

                columnChildren.add(const SizedBox(height: 90));

                return SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: columnChildren,
                  ),
                );
              },
            ),
          ],
        ),

        floatingActionButton: Consumer<CartProvider>(
          builder: (context, cart, child) {
            if (cart.cartCount == 0) return const SizedBox.shrink();
            return FloatingActionButton.extended(
              onPressed: () {
                _shouldClearCart = false;
                Navigator.pop(context);
                Provider.of<NavigationProvider>(context, listen: false).changeTab(3);
              },
              backgroundColor: Theme.of(context).primaryColor,
              label: Row(
                children: [
                  const Text("عرض السلة", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                    child: Text("${cart.cartCount}", style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
              icon: const Icon(Icons.shopping_cart),
            );
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  // 🔥 دالة مساعدة لبناء الـ FoodCard مع تمرير نوع النظام (سوق أم مطعم)
  Widget _buildThemedFoodCard(FoodItem item) {
    // نقوم بتغليف استدعاء الـ BottomSheet لضمان تمرير isMarket الصحيح
    return GestureDetector(
      onTap: () {
        if (item.isDeliverable) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => FoodItemBottomSheet(
              foodItem: item,
              isMarket: _isMarketSystem, // 👈 التعديل هنا: يمرر true إذا لم يكن مطعماً
            ),
          );
        } else {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => DetailScreen(foodItem: item)));
        }
      },
      child: FoodCard(food: item),
    );
  }

  Widget _buildCategoryChipWithImage(int id, String name, String emojiIcon) {
    final isSelected = _selectedCategoryId == id;

    return GestureDetector(
      onTap: () => _scrollToCategory(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.cyan.shade50 : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: isSelected ? Border.all(color: const Color(0xFF00BCD4), width: 2) : Border.all(color: Colors.transparent, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.grey.shade100,
                shape: BoxShape.circle,
                boxShadow: isSelected ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : null,
              ),
              child: Center(
                child: Text(
                  emojiIcon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.black87 : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StickyCategoryDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _StickyCategoryDelegate({required this.child});
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;
  @override
  double get maxExtent => 105.0;
  @override
  double get minExtent => 105.0;
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => true;
}

// ⚠️ تم زيادة الارتفاع (maxExtent و minExtent) ليتسع للصور والنصوص معاً





class MultiSliver extends StatelessWidget {
  final List<Widget> children;
  const MultiSliver({super.key, required this.children});
  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) => children[index],
        childCount: children.length,
      ),
    );
  }
}

// ✨ كلاس لجعل شريط الأقسام ثابتاً أثناء النزول
// ✨ كلاس مساعد لدمج الـ Slivers معاً (ضعه في أي مكان أسفل الملف)

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
    final mainContext = context;

    return Scaffold(
      appBar: AppBar(title: const Text('سلتي')),
      body: Consumer<CartProvider>(
        builder: (ctx, cart, child) {
          if (cart.items.isEmpty) {
            return const Center(child: Text('سلّتك فارغة!', style: TextStyle(fontSize: 18, color: Colors.grey)));
          }
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: cart.items.length,
                  itemBuilder: (ctx, index) => _buildCartItemCard(mainContext, cart, cart.items[index]),
                ),
              ),
              _buildCheckoutSection(mainContext, cart)
            ],
          );
        },
      ),
    );
  }

  Future<void> _checkActiveOrderAndCheckout(BuildContext context, CartProvider cart) async {
    try {
      final localOrders = await OrderHistoryService().getOrders();
      final activeStatuses = ['pending', 'processing', 'on-hold', 'driver-assigned', 'out-for-delivery', 'accepted', 'at_store', 'picked_up'];

      final activeOrders = localOrders.where((o) {
        bool isStatusActive = activeStatuses.contains(o.status.toLowerCase());
        int hoursPassed = DateTime.now().difference(o.dateCreated).inHours;
        return isStatusActive && hoursPassed < 4;
      }).toList();

      if (activeOrders.isNotEmpty) {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(children: [Icon(Icons.info_outline, color: Colors.blue), SizedBox(width: 10), Text("تنبيه", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
              content: const Text("يبدو أن لديك طلباً قيد التنفيذ حالياً.\nيمكنك متابعة طلبك الحالي أو المتابعة لإنشاء طلب جديد إضافي.", style: TextStyle(height: 1.5, fontSize: 16)),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => OrderTrackingScreen(order: activeOrders.first)));
                  },
                  child: const Text("تتبع طلبي الحالي", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showCheckoutDialog(context, cart);
                  },
                  child: const Text("طلب جديد", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        }
      } else {
        _showCheckoutDialog(context, cart);
      }
    } catch (e) {
      _showCheckoutDialog(context, cart);
    }
  }

  void _showCheckoutDialog(BuildContext context, CartProvider cart) {
    final BuildContext cartScreenContext = context;

    _nameController.clear();
    _phoneController.clear();
    _addressController.clear();
    _couponController.text = cart.appliedCoupon ?? '';

    bool isSubmitting = false;
    geolocator.Position? _capturedPosition;

    // قيم افتراضية ريثما يتم الحساب
    double _deliveryFee = 1000.0;
    String _locationMessage = "جاري الحساب...";
    bool _isCalcFinished = false;
    bool _hasStartedCalculation = false;

    showDialog(
      context: cartScreenContext,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(builder: (context, setDialogState) {

          // 🔥 الحساب الفوري السريع بدون نوافذ GPS مزعجة
          if (!_hasStartedCalculation) {
            _hasStartedCalculation = true;
            _calculateDeliveryFeeFast(
                cart: cart,
                cartScreenContext: cartScreenContext,
                onResult: (fee, message, position) {
                  if (dialogContext.mounted) {
                    setDialogState(() {
                      _deliveryFee = fee;
                      _locationMessage = message;
                      _capturedPosition = position;
                      _isCalcFinished = true;
                    });
                  }
                }
            );
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
                    TextFormField(
                        controller: _nameController, decoration: const InputDecoration(labelText: 'الاسم الكامل'),
                        validator: (v) => v!.isEmpty ? 'مطلوب' : null, enabled: !isSubmitting),
                    const SizedBox(height: 10),
                    TextFormField(
                        controller: _phoneController, decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                        keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'مطلوب' : null, enabled: !isSubmitting),
                    const SizedBox(height: 10),
                    TextFormField(
                        controller: _addressController, decoration: const InputDecoration(labelText: 'العنوان (أقرب نقطة دالة)'),
                        validator: (v) => v!.isEmpty ? 'مطلوب' : null, enabled: !isSubmitting),
                    const SizedBox(height: 20),

                    // صندوق السعر ورسالة التوضيح
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.blue.shade200)),
                      child: Column(
                        children: [
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("تكلفة التوصيل:", style: TextStyle(fontWeight: FontWeight.bold)),
                                _isCalcFinished
                                    ? Text("${NumberFormat('#,###').format(_deliveryFee)} د.ع", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16))
                                    : const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              ]),
                          const SizedBox(height: 5),
                          Row(children: [
                            const Icon(Icons.info_outline, color: Colors.blue, size: 14),
                            const SizedBox(width: 5),
                            Expanded(child: Text(_locationMessage, style: TextStyle(fontSize: 12, color: Colors.blue.shade800, fontWeight: FontWeight.bold))),
                          ])
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextFormField(controller: _couponController, decoration: const InputDecoration(labelText: 'كود الخصم (اختياري)')),
                    const Divider(height: 30),
                    _buildPriceSummary(cart, _deliveryFee, !_isCalcFinished, ""),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(onPressed: isSubmitting ? null : () => Navigator.of(dialogContext).pop(), child: const Text('إلغاء')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
                onPressed: (isSubmitting || !_isCalcFinished)
                    ? null
                    : () async {
                  if (!_formKey.currentState!.validate()) return;
                  setDialogState(() => isSubmitting = true);
                  try {
                    final prefs = await SharedPreferences.getInstance();
                    final int currentZoneId = prefs.getInt('selectedAreaId') ?? 0;
                    if (currentZoneId == 0) throw Exception("يرجى تحديد المنطقة من الصفحة الرئيسية.");

                    final int? firstRestaurantId = cart.items.isNotEmpty ? cart.items.first.categoryId : null;

                    final createdOrder = await _apiService.submitOrder(
                      name: _nameController.text, phone: _phoneController.text,
                      address: _addressController.text, cartItems: cart.items,
                      couponCode: cart.appliedCoupon, position: _capturedPosition,
                      deliveryFee: _deliveryFee, zoneId: currentZoneId,
                      restaurantId: firstRestaurantId, regionId: currentZoneId,
                      platformMarkupTotal: cart.totalPlatformMarkup, // 👈 1. تم إضافة إجمالي أرباح المنصة هنا
                    );

                    if (!cartScreenContext.mounted) return;
                    if (createdOrder == null) throw Exception('فشل إنشاء الطلب.');

                    await cart._recordSuccessfulOrder();
                    Navigator.of(dialogContext).pop();
                    cart.clearCart();

                    Provider.of<NotificationProvider>(cartScreenContext, listen: false).triggerRefresh();

                    if (cartScreenContext.mounted) {
                      showDialog(
                          context: cartScreenContext,
                          barrierDismissible: false,
                          builder: (ctx) => AlertDialog(
                            title: const Text("تم بنجاح! 🎉"),
                            content: const Text("تم استلام طلبك. يمكنك متابعة حالته الآن في صفحة طلباتي."),
                            actions: [
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  Provider.of<NavigationProvider>(cartScreenContext, listen: false).changeTab(2);
                                },
                                child: const Text("متابعة الطلب"),
                              )
                            ],
                          ));
                    }
                  } catch (e) {
                    if (cartScreenContext.mounted) ScaffoldMessenger.of(cartScreenContext).showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
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

  // 🔥 دالة الحساب السريعة (بدون إجبار الزبون)
  Future<void> _calculateDeliveryFeeFast({
    required CartProvider cart,
    required BuildContext cartScreenContext,
    required Function(double fee, String message, geolocator.Position? pos) onResult
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int currentZoneId = prefs.getInt('selectedAreaId') ?? 0;
      String areaName = prefs.getString('selectedAreaName') ?? "المنطقة المحددة";

      if (cart.items.isEmpty) {
        onResult(1000.0, "السلة فارغة", null);
        return;
      }

      int restaurantId = cart.items.first.categoryId;
      double uLat = 0.0, uLng = 0.0;
      geolocator.Position? capturedPos;

      // 1. جلب الموقع بدقة عالية وحل مشكلة الـ Null
      bool serviceEnabled = await geolocator.Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        geolocator.LocationPermission permission = await geolocator.Geolocator.checkPermission();
        if (permission == geolocator.LocationPermission.denied) {
          permission = await geolocator.Geolocator.requestPermission();
        }

        if (permission == geolocator.LocationPermission.whileInUse || permission == geolocator.LocationPermission.always) {
          try {
            // نطلب الموقع المباشر الآن مع مهلة 5 ثواني
            capturedPos = await geolocator.Geolocator.getCurrentPosition(
              desiredAccuracy: geolocator.LocationAccuracy.bestForNavigation,
              timeLimit: const Duration(seconds: 5),
            );
          } catch (e) {
            // إذا فشل (بسبب التواجد داخل مبنى)، نأخذ آخر موقع كخطة طوارئ
            capturedPos = await geolocator.Geolocator.getLastKnownPosition();
          }

          if (capturedPos != null) {
            uLat = capturedPos.latitude;
            uLng = capturedPos.longitude;
          }
        }
      }

      // 2. الحساب السريع المباشر (Client-Side) 100% بدون السيرفر
      final configProvider = Provider.of<DeliveryConfigProvider>(cartScreenContext, listen: false);
      if (configProvider.cachedConfig == null) await configProvider.fetchAndCacheConfig();

      Map<String, dynamic> result = configProvider.calculateFeeDetails(
          userLat: uLat,
          userLng: uLng,
          restaurantId: restaurantId,
          areaId: currentZoneId,
          areaName: areaName
      );

      onResult(result['fee'], result['message'], capturedPos);

    } catch (e) {
      onResult(1000.0, "تم تطبيق السعر الافتراضي بسبب خطأ داخلي.", null);
    }
  }

  Widget _buildCartItemCard(BuildContext context, CartProvider cart, FoodItem item) {
    return Card(
        margin: const EdgeInsets.only(bottom: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(children: [
              ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(imageUrl: item.imageUrl, width: 80, height: 80, fit: BoxFit.cover)),
              const SizedBox(width: 15),
              Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text(item.formattedPrice, style: TextStyle(fontSize: 16, color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold))
                  ])),
              Row(children: [
                IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => cart.decrementQuantity(item)),
                Text(item.quantity.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => cart.incrementQuantity(item))
              ])
            ])));
  }

  Widget _buildCheckoutSection(BuildContext context, CartProvider cart) {
    final totalFormatted = NumberFormat('#,###', 'ar_IQ').format(cart.totalPrice);
    final discountedTotalFormatted = NumberFormat('#,###', 'ar_IQ').format(cart.discountedTotal);

    return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10, spreadRadius: 5)]),
        child: Column(children: [

          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('المجموع', style: TextStyle(fontSize: 18, color: Colors.grey)),
            Text('$totalFormatted د.ع',
                style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                    decoration: (cart.appliedCoupon != null) ? TextDecoration.lineThrough : TextDecoration.none))
          ]),

          if (cart.appliedCoupon != null)
            Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('الإجمالي بعد الخصم', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                  Text('$discountedTotalFormatted د.ع', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor))
                ])),

          const SizedBox(height: 20),
          SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                  onPressed: () => _checkActiveOrderAndCheckout(context, cart),
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white),
                  child: const Text('إتمام الطلب', style: TextStyle(fontSize: 18))))
        ]));
  }

  Widget _buildPriceSummary(CartProvider cart, double? deliveryFee, bool isCalculatingFee, String feeMessage) {
    final double foodTotal = cart.totalPrice;

    double discountAmount = 0.0;
    if (cart.appliedCoupon != null) {
      discountAmount = cart.totalDiscountAmount;
    }

    final double finalFoodTotal = (foodTotal - discountAmount).clamp(0.0, double.infinity);
    final double finalTotal = finalFoodTotal + (deliveryFee ?? 0);

    final totalFormatted = NumberFormat('#,###', 'ar_IQ').format(foodTotal);
    final discountFormatted = NumberFormat('#,###', 'ar_IQ').format(discountAmount);
    final finalTotalFormatted = NumberFormat('#,###', 'ar_IQ').format(finalTotal);

    return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('سعر الطلبات', style: TextStyle(fontSize: 14)),
            Text('$totalFormatted د.ع', style: const TextStyle(fontWeight: FontWeight.bold))
          ]),

          if (discountAmount > 0) ...[
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('خصم الكوبون', style: TextStyle(fontSize: 14, color: Theme.of(context).primaryColor)),
              Text('- $discountFormatted د.ع', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor))
            ])
          ],

          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Icon(Icons.delivery_dining_outlined, size: 20, color: Colors.blue.shade700),
              const SizedBox(width: 5),
              const Text('خدمة التوصيل', style: TextStyle(fontSize: 14))
            ]),
            AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: isCalculatingFee
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(
                    deliveryFee != null ? '${NumberFormat('#,###', 'ar_IQ').format(deliveryFee)} د.ع' : '---',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: deliveryFee == null && !isCalculatingFee ? Colors.red : Colors.black)))
          ]),
          if (feeMessage.isNotEmpty)
            Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(feeMessage.replaceAll("Exception: ", ""),
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.red.shade700))),
          const Divider(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('الإجمالي المطلوب دفعه', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: isCalculatingFee || deliveryFee == null
                    ? const SizedBox.shrink()
                    : Text('$finalTotalFormatted د.ع', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)))
          ])
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
  bool _isSyncing = false; // حالة المزامنة الحالية

  @override
  void initState() {
    super.initState();
    _loadOrders();

    // 🔥 الاستماع لتنبيهات التحديث (من السلة أو الإشعارات)
    Provider.of<NotificationProvider>(context, listen: false).addListener(_refreshOrders);
  }

  @override
  void dispose() {
    try {
      Provider.of<NotificationProvider>(context, listen: false).removeListener(_refreshOrders);
    } catch (e) {
      // تجاهل الخطأ في حال كان الـ Provider غير متاح
    }
    super.dispose();
  }

  // دالة المساعدة لتحديث الواجهة
  void _refreshOrders() {
    if (mounted) {
      _loadOrders();
    }
  }

  // ============================================================
  // 🔥 دالة التحميل المحسنة: عرض فوري + مزامنة ذكية
  // ============================================================
  Future<void> _loadOrders() async {
    if (!mounted) return;

    // 1. ✅ العرض الفوري: جلب البيانات من الذاكرة المحلية فوراً
    setState(() {
      _ordersFuture = OrderHistoryService().getOrders();
    });

    // 2. 🔄 المزامنة الخلفية: تصحيح الطلبات النشطة من السيرفر
    // ننتظر قليلاً لضمان استقرار الواجهة ثم نبدأ المزامنة
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      await _syncActiveOrdersWithServer();
    }
  }

  // ============================================================
  // 🔥 دالة المزامنة مع سيرفر التاكسي (نفس منطق التتبع)
  // ============================================================
  Future<void> _syncActiveOrdersWithServer() async {
    try {
      // أ. جلب الطلبات المحلية
      final localOrders = await OrderHistoryService().getOrders();
      if (localOrders.isEmpty) return;

      // ب. فلترة الطلبات النشطة فقط (لحماية الأداء)
      final activeStatuses = ['pending', 'processing', 'on-hold', 'accepted', 'at_store', 'picked_up', 'out-for-delivery', 'driver-assigned'];
      final activeOrders = localOrders.where((o) => activeStatuses.contains(o.status.toLowerCase())).toList();

      if (activeOrders.isEmpty) return; // لا يوجد ما يزامن

      // ج. بدء المزامنة
      setState(() => _isSyncing = true);

      final auth = Provider.of<AuthProvider>(context, listen: false);
      final String? taxiToken = auth.taxiToken;
      bool hasChanges = false;

      // د. المرور على الطلبات النشطة وفحصها
      for (var order in activeOrders) {
        try {
          // استخدام النقطة المخصصة الموثوقة
          final response = await http.get(
            Uri.parse('https://banner.beytei.com/wp-json/taxi/v2/delivery/status-by-source/${order.id}'),
            headers: {
              'Content-Type': 'application/json',
              if (taxiToken != null) 'Authorization': 'Bearer $taxiToken',
            },
          ).timeout(const Duration(seconds: 5)); // مهلة قصيرة لعدم تعطيل التطبيق

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            String serverStatus = data['order_status']?.toString().toLowerCase() ?? order.status;
            String? driverName = data['driver_name'];

            // هل هناك تغيير؟
            if (serverStatus != order.status.toLowerCase()) {
              // تحديث الحالة في الكائن المحلي
              // ملاحظة: كلاس Order قد يكون immutable، لذا نحتاج لتحديثه عبر الخدمة
              await OrderHistoryService().updateOrderStatusLocally(order.id, serverStatus);

              // تحديث اسم السائق إذا وجد (اختياري حسب هيكلية الكلاس)
              if (driverName != null && driverName.isNotEmpty) {
                // إذا كان الكلاس يدعم التحديث الكامل، يمكن استدعاء دالة تحديث كاملة هنا
              }

              hasChanges = true;
              print("🔄 تم تحديث الطلب #${order.id}: ${order.status} -> $serverStatus");
            }
          }
        } catch (e) {
          // في حال فشل الاتصال، نتجاهل الخطأ ونعتمد على الكاش (لا نوقف التطبيق)
          print("⚠️ فشل مزامنة الطلب #${order.id}: $e");
        }
      }

      // هـ. إذا حدثت تغييرات، نعيد تحميل القائمة لتحديث الواجهة
      if (hasChanges && mounted) {
        setState(() {
          _ordersFuture = OrderHistoryService().getOrders();
        });
        // تحديث السلة أيضاً لضمان التزامن الشامل
        Provider.of<NotificationProvider>(context, listen: false).triggerRefresh();
      }

    } catch (e) {
      print("⚠️ خطأ عام في المزامنة: $e");
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل طلباتي'),
        centerTitle: true,
        actions: [
          // 🔥 مؤشر المزامنة الذكي
          if (_isSyncing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            ),
          // زر التحديث اليدوي
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isSyncing ? null : _loadOrders,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrders,
        child: FutureBuilder<List<Order>>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            // الحالة 1: الانتظار الأولي
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // الحالة 2: وجود خطأ
            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.4),
                  Center(child: Text('حدث خطأ: ${snapshot.error}')),
                ],
              );
            }

            final orders = snapshot.data;

            // الحالة 3: القائمة فارغة
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
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                ],
              );
            }

            // الحالة 4: عرض البيانات
            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: orders.length,
              itemBuilder: (context, index) => OrderHistoryCard(order: orders[index]),
            );
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
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    // 1. تهيئة التبويبات (5 تبويبات)
    _tabController = TabController(length: 5, vsync: this);

    // 2. المنطق التسلسلي (جلب الموقع + الأتمتة + الحيلة التسويقية)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = Provider.of<AuthProvider>(context, listen: false).token;

      if (token != null) {
        // أ) جلب إعدادات المطعم (الموقع) وتشغيل التحديث التلقائي
        Provider.of<RestaurantSettingsProvider>(context, listen: false)
            .fetchSettings(token)
            .then((_) {
          if (mounted) {
            Provider.of<DashboardProvider>(context, listen: false).startAutoRefresh(token);
          }
        });

        // 🔥 ب) الحيلة التسويقية: فحص الرصيد وعرض الإعلان (الترحيب)
        _checkWalletAndShowPromo(token);
      }
    });
  }

  // دالة الحيلة التسويقية (عند فتح التطبيق)
  Future<void> _checkWalletAndShowPromo(String token) async {
    try {
      final walletData = await _apiService.getWalletData(token);
      final dynamic rawBalance = walletData['wallet_balance'];
      double balance = 0.0;
      if (rawBalance is int) balance = rawBalance.toDouble();
      if (rawBalance is double) balance = rawBalance;
      if (rawBalance is String) balance = double.tryParse(rawBalance) ?? 0.0;

      // إذا كان الرصيد يسمح بإرسال إشعار
      if (balance >= 5000 && mounted) {
        // هنا يمكنك إظهار نافذة ترويجية إذا أردت، أو الاكتفاء بالزر العائم
      }
    } catch (e) {
      print("Promo check failed: $e");
    }
  }

  @override
  void dispose() {
    Provider.of<DashboardProvider>(context, listen: false).stopAutoRefresh();
    _tabController.dispose();
    super.dispose();
  }

  // =======================================================================
  // --- 1. نافذة إرسال عرض جديد (التصميم العصري + منطق الخصم) ---
  // =======================================================================
  void _showModernOfferDialog(BuildContext context) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    final imageController = TextEditingController(); // اختياري للصورة
    bool isSending = false;
    double currentBalance = 0.0;
    bool isLoadingBalance = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {

          // دالة داخلية لجلب الرصيد عند فتح النافذة
          if (isLoadingBalance) {
            final token = Provider.of<AuthProvider>(context, listen: false).token!;
            _apiService.getWalletData(token).then((data) {
              if (mounted) {
                setState(() {
                  currentBalance = double.tryParse(data['wallet_balance'].toString()) ?? 0.0;
                  isLoadingBalance = false;
                });
              }
            }).catchError((e) {
              if (mounted) setState(() => isLoadingBalance = false);
            });
            isLoadingBalance = false; // لمنع التكرار
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- رأس النافذة ---
                  Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.purple.shade50, shape: BoxShape.circle),
                        child: const Icon(Icons.campaign_rounded, color: Colors.purple, size: 30),
                      ),
                      const SizedBox(width: 15),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("إرسال إشعار ترويجي", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text("سيتم إنشاء طلب بالخدمة ليظهر لدى الإدارة", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 30),

                  // --- عرض التكلفة والرصيد ---
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: currentBalance >= AD_COST ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: currentBalance >= AD_COST ? Colors.green.shade200 : Colors.red.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("تكلفة الخدمة", style: TextStyle(fontSize: 12)),
                            Text("${NumberFormat('#,###').format(AD_COST)} د.ع", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        Container(height: 30, width: 1, color: Colors.grey.shade300),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text("رصيدك الحالي", style: TextStyle(fontSize: 12)),
                            Text("${NumberFormat('#,###').format(currentBalance)} د.ع",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: currentBalance >= AD_COST ? Colors.green : Colors.red)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // رسالة تنبيه إذا الرصيد غير كافي
                  if (currentBalance < AD_COST)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 16),
                          const SizedBox(width: 5),
                          const Text("رصيدك غير كافي. يرجى الشحن أولاً.", style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
                              },
                              child: const Text("شحن المحفظة")
                          )
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  // --- الحقول ---
                  const Text("عنوان العرض", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: "مثال: عرض الغداء المميز! 🔥",
                      filled: true, fillColor: Colors.grey[50],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    ),
                  ),

                  const SizedBox(height: 15),
                  const Text("تفاصيل العرض", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: bodyController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: "اكتب تفاصيل الخصم أو الوجبة الجديدة...",
                      filled: true, fillColor: Colors.grey[50],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // --- زر الإرسال ---
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: (isSending || currentBalance < AD_COST)
                          ? null
                          : () async {
                        if (titleController.text.isEmpty || bodyController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("الرجاء إدخال العنوان والتفاصيل")));
                          return;
                        }

                        setState(() => isSending = true);
                        try {
                          final token = Provider.of<AuthProvider>(context, listen: false).token!;

                          // 🔥 استدعاء الدالة التي تنشئ الطلب في ووكومرس
                          await _apiService.createMarketingOrder(
                            token: token,
                            title: titleController.text,
                            body: bodyController.text,
                            imageUrl: imageController.text,
                          );

                          if (mounted) {
                            Navigator.pop(ctx);
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                title: const Icon(Icons.check_circle_outline, color: Colors.green, size: 70),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text("تم الإرسال بنجاح!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 10),
                                    Text("تم إنشاء طلب خدمة بقيمة ${NumberFormat('#,###').format(AD_COST)} د.ع\nسيظهر الطلب لدى الإدارة والتيم ليدر للموافقة والنشر.",
                                        textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                                  ],
                                ),
                                actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("حسناً"))],
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ: ${e.toString().replaceAll('Exception:', '')}"), backgroundColor: Colors.red));
                            setState(() => isSending = false);
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: isSending
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text("دفع ${NumberFormat('#,###').format(AD_COST)} د.ع وإرسال", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // =======================================================================
  // --- 2. نافذة طلب التوصيل الخاص (كما هي) ---
  // =======================================================================
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
                      TextFormField(controller: _pickupNameController, decoration: const InputDecoration(labelText: 'اسم المطعم/المصدر (الاستلام)'), validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null),
                      const SizedBox(height: 12),
                      TextFormField(controller: _destAddressController, decoration: const InputDecoration(labelText: 'عنوان الزبون (الوجهة)'), validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null),
                      const SizedBox(height: 12),
                      TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: 'رقم هاتف الزبون'), keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null),
                      const SizedBox(height: 12),
                      TextFormField(controller: _feeController, decoration: const InputDecoration(labelText: 'أجرة التوصيل', suffixText: 'د.ع'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null),
                      const SizedBox(height: 12),
                      TextFormField(controller: _notesController, decoration: const InputDecoration(labelText: 'ملاحظات (اسم الزبون، تفاصيل)'), maxLines: 2),
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
                TextButton(onPressed: isSubmitting ? null : () => Navigator.of(dialogContext).pop(), child: const Text('إلغاء')),
                ElevatedButton(
                  onPressed: isSubmitting ? null : () async {
                    if (_formKey.currentState!.validate()) {
                      setDialogState(() => isSubmitting = true);
                      try {
                        final prefs = await SharedPreferences.getInstance();
                        final token = prefs.getString('jwt_token');
                        final pickupLat = prefs.getDouble('restaurant_lat');
                        final pickupLng = prefs.getDouble('restaurant_lng');

                        if (token == null || pickupLat == null || pickupLng == null) throw Exception("بيانات المطعم غير كاملة.");

                        final pickupName = _pickupNameController.text;
                        await prefs.setString('saved_restaurant_name', pickupName);

                        final double? destLat = double.tryParse(_destLatController.text);
                        final double? destLng = double.tryParse(_destLngController.text);

                        final result = await _apiService.createUnifiedDeliveryRequest(
                          token: token, sourceType: 'restaurant', pickupName: pickupName,
                          pickupLat: pickupLat, pickupLng: pickupLng,
                          destinationAddress: _destAddressController.text, destinationLat: destLat, destinationLng: destLng,
                          deliveryFee: _feeController.text, orderDescription: _notesController.text, endCustomerPhone: _phoneController.text,
                          sourceOrderId: 'private_${DateTime.now().millisecondsSinceEpoch}',
                        );

                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'تم إرسال الطلب بنجاح!'), backgroundColor: Colors.green));
                        }
                      } catch (e) {
                        if (dialogContext.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: ${e.toString()}'), backgroundColor: Colors.red));
                      } finally {
                        if (dialogContext.mounted) setDialogState(() => isSubmitting = false);
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
          IconButton(
            icon: const Icon(Icons.account_balance_wallet, color: Colors.green),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen())),
            tooltip: 'المحفظة والأرباح',
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
          OrdersListScreen(status: 'active'),
          OrdersListScreen(status: 'completed'),
          const ProductManagementTab(),
          const RatingsDashboardScreen(),
          const RestaurantSettingsScreen(),
        ],
      ),

      // =========================================================
      // 🔥🔥🔥 الزر العائم المزدوج (عروض + توصيل خاص) 🔥🔥🔥
      // =========================================================
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 1. زر إرسال العروض (الجديد - البنفسجي)
          FloatingActionButton.extended(
            heroTag: "btn_offer",
            onPressed: () => _showModernOfferDialog(context),
            icon: const Icon(Icons.campaign_rounded),
            label: const Text('إرسال عرض'),
            backgroundColor: Colors.purple.shade700,
            foregroundColor: Colors.white,
          ),

          const SizedBox(height: 12),

          // 2. زر طلب التوصيل الخاص (القديم - البرتقالي)
          FloatingActionButton.extended(
            heroTag: "btn_delivery",
            onPressed: () => _showPrivateDeliveryRequestDialog(context),
            icon: const Icon(Icons.two_wheeler_outlined),
            label: const Text('طلب توصيل خاص'),
            backgroundColor: Colors.orange.shade700,
            foregroundColor: Colors.white,
          ),
        ],
      ),
    );
  }
}

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
  bool _showOffersOnly = false;

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

  void _navigateToAddScreen() async {
    final productProvider = Provider.of<RestaurantProductsProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final bool? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddProductScreen(
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

  // 🔥 نافذة إضافة قسم جديد
  void _showAddCategoryDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final iconCtrl = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: const Row(
                children: [
                  Icon(Icons.create_new_folder, color: Colors.orange),
                  SizedBox(width: 8),
                  Text("إضافة قسم جديد"),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: "اسم القسم (مثال: بركر)", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: iconCtrl,
                    decoration: const InputDecoration(labelText: "أيقونة القسم (مثال: 🍔)", border: OutlineInputBorder()),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: isSubmitting ? null : () => Navigator.pop(ctx), child: const Text("إلغاء")),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700, foregroundColor: Colors.white),
                  onPressed: isSubmitting ? null : () async {
                    if (nameCtrl.text.isEmpty) return;
                    setState(() => isSubmitting = true);
                    final token = Provider.of<AuthProvider>(context, listen: false).token!;

                    final success = await ApiService().createSubcategory(token, nameCtrl.text, iconCtrl.text);

                    if (mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(success ? "تم إضافة القسم '${nameCtrl.text}' بنجاح" : "فشل إضافة القسم"),
                              backgroundColor: success ? Colors.green : Colors.red
                          )
                      );
                    }
                  },
                  child: isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("حفظ القسم"),
                )
              ],
            );
          }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return Consumer<RestaurantProductsProvider>(
      builder: (context, provider, child) {
        List<FoodItem> displayedProducts = provider.products;
        if (_showOffersOnly) {
          displayedProducts = provider.products.where((p) => p.salePrice != null && p.salePrice! > 0).toList();
        }

        return Scaffold(
          floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _navigateToAddScreen,
            label: const Text("إضافة وجبة"),
            icon: const Icon(Icons.fastfood),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'ابحث عن منتج...',
                prefixIcon: Icon(Icons.search),
                border: InputBorder.none,
              ),
              onChanged: (query) => provider.search(query),
            ),
            actions: [
              // 🔥 أيقونة إضافة القسم في الأعلى
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: IconButton(
                  icon: const Icon(Icons.create_new_folder, color: Colors.orange, size: 28),
                  tooltip: "إضافة قسم جديد",
                  onPressed: () => _showAddCategoryDialog(context),
                ),
              )
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60.0),
              child: Column(
                children: [
                  if (provider.isLoading) const LinearProgressIndicator(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      children: [
                        _buildFilterChip("الكل", !_showOffersOnly, () => setState(() => _showOffersOnly = false)),
                        const SizedBox(width: 10),
                        _buildFilterChip("العروض النشطة 🔥", _showOffersOnly, () => setState(() => _showOffersOnly = true)),
                      ],
                    ),
                  ),
                ],
              ),
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
              if (displayedProducts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_showOffersOnly ? Icons.local_fire_department_outlined : Icons.fastfood_outlined, size: 60, color: Colors.grey),
                      const SizedBox(height: 10),
                      Text(
                        _showOffersOnly ? "لا توجد عروض نشطة حالياً." : "لم يتم العثور على منتجات. أضف منتجك الأول!",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 80, top: 10),
                itemCount: displayedProducts.length,
                itemBuilder: (context, index) {
                  final product = displayedProducts[index];
                  final bool isOffer = product.salePrice != null && product.salePrice! > 0;

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    elevation: isOffer ? 3 : 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isOffer ? const BorderSide(color: Colors.amber, width: 1) : BorderSide.none,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: product.imageUrl,
                          width: 60, height: 60, fit: BoxFit.cover,
                          errorWidget: (c, u, e) => Container(color: Colors.grey[200], child: const Icon(Icons.fastfood, color: Colors.grey)),
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(child: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                          if (isOffer)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                              child: const Text("عرض", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            )
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          isOffer
                              ? Row(
                            children: [
                              Text("${NumberFormat('#,###').format(product.price)} د.ع", style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: 12)),
                              const SizedBox(width: 8),
                              Text("${NumberFormat('#,###').format(product.salePrice)} د.ع", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          )
                              : Text("السعر: ${NumberFormat('#,###').format(product.price)} د.ع", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      trailing: IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blue), onPressed: () => _navigateToEditScreen(product)),
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

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.amber.shade700 : Colors.transparent),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.black : Colors.grey[700], fontWeight: FontWeight.bold)),
      ),
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
























class SmartWalletProvider with ChangeNotifier {
  int _currentOrders = 0;
  int _targetOrders = 4;
  double _accumulatedDiscount = 0.0;
  bool _canClaim = false;
  String _message = '';
  bool _isLoading = false;
  bool _isClaiming = false;
  String? _lastCouponCode;

  int get currentOrders => _currentOrders;
  int get targetOrders => _targetOrders;
  double get accumulatedDiscount => _accumulatedDiscount;
  bool get canClaim => _canClaim;
  String get message => _message;
  bool get isLoading => _isLoading;
  bool get isClaiming => _isClaiming;
  String? get lastCouponCode => _lastCouponCode;

  final ApiService _apiService = ApiService();

  Future<void> fetchWalletStatus(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _apiService.getCashbackStatus(token);
      _currentOrders = data['current_orders'] ?? 0;
      _targetOrders = data['target_orders'] ?? 4;
      _accumulatedDiscount = double.tryParse(data['accumulated_discount'].toString()) ?? 0.0;
      _canClaim = data['can_claim'] ?? false;
      _message = data['message'] ?? '';
    } catch (e) {
      print("⚠️ خطأ في جلب بيانات الكاش باك: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> claimDiscount(String token, BuildContext context) async {
    _isClaiming = true;
    notifyListeners();

    try {
      final data = await _apiService.claimDiscountCoupon(token);
      _lastCouponCode = data['coupon_code'];

      // تحديث الحالة فوراً بعد النجاح (تصفير العداد)
      await fetchWalletStatus(token);
      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red),
      );
      return false;
    } finally {
      _isClaiming = false;
      notifyListeners();
    }
  }
}





class CustomerChatPage extends StatefulWidget {
  final String orderId;
  final String driverName;
  final String customerName;
  final String? driverFcmToken; // لم نعد نعتمد عليه للإرسال المباشر

  const CustomerChatPage({
    super.key,
    required this.orderId,
    required this.driverName,
    required this.customerName,
    this.driverFcmToken,
  });

  @override
  State<CustomerChatPage> createState() => _CustomerChatPageState();
}

class _CustomerChatPageState extends State<CustomerChatPage> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  String _customerId = '';
  bool _isAuthInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCustomerAuth();

    print("🔍 [CustomerChat] orderId: '${widget.orderId}'");
    print("🔍 [CustomerChat] orderId.trim: '${widget.orderId.trim()}'");
  }

  Future<void> _initializeCustomerAuth() async {
    try {
      print("🔐 [Auth] جاري تهيئة مصادقة الزبون...");
      final user = fb_auth.FirebaseAuth.instance.currentUser;

      if (user == null) {
        final credential = await fb_auth.FirebaseAuth.instance.signInAnonymously();
        print("✅ [Auth] تم تسجيل دخول الزبون مجهول الهوية");
      }

      setState(() {
        _customerId = fb_auth.FirebaseAuth.instance.currentUser?.uid ?? 'customer_${const Uuid().v4()}';
        _isAuthInitialized = true;
      });

      print("🆔 [CustomerChat] customerId النهائي: $_customerId");

    } catch (e) {
      print("❌ [Auth] فشل تهيئة المصادقة: $e");
      setState(() {
        _customerId = 'customer_${const Uuid().v4()}';
        _isAuthInitialized = true;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    if (!_isAuthInitialized) {
      await _initializeCustomerAuth();
      await Future.delayed(const Duration(milliseconds: 200));
    }

    setState(() => _isSending = true);

    final cleanOrderId = widget.orderId.trim().replaceAll(RegExp(r'\s+'), '');
    final chatDoc = FirebaseFirestore.instance.collection('OrdersChat').doc(cleanOrderId);

    final messageData = {
      'text': text,
      'senderId': _customerId,
      'senderName': widget.customerName,
      'senderType': 'customer',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'read': false,
    };

    try {
      // 1. حفظ الرسالة في فايربيس
      await chatDoc.set({
        'messages': FieldValue.arrayUnion([messageData]),
        'order_id': cleanOrderId,
        'last_message': text,
        'last_updated': FieldValue.serverTimestamp(),
        'participants': FieldValue.arrayUnion([_customerId]),
      }, SetOptions(merge: true));

      print("✅ [Send] تم إرسال الرسالة بنجاح!");

      _msgController.clear();
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0.0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }

      // 🔥 2. إرسال الإشعار للسائق عبر السيرفر (التوجيه الذكي)
      _sendNotificationToDriver(text, cleanOrderId);

    } catch (e, stackTrace) {
      print("❌ [Send] فشل الإرسال: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل الإرسال: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // 🔥 دالة التوجيه الذكي للسيرفر
  Future<void> _sendNotificationToDriver(String message, String orderId) async {
    try {
      final notifyUrl = 'https://re.beytei.com/wp-json/beytei-chat/v1/notify';

      final response = await http.post(
        Uri.parse(notifyUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'target': 'driver', // 👈 السر هنا: السيرفر سيبحث عن توكن السائق المرفق بالطلب
          'sender_name': widget.customerName,
          'message': message,
          'order_id': orderId,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        print("✅ [Notification] تم طلب إرسال الإشعار للسائق من السيرفر بنجاح");
      } else {
        print("⚠️ [Notification] فشل طلب الإشعار من السيرفر: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("❌ [Notification] خطأ في الاتصال بسيرفر الإشعارات: $e");
    }
  }

  Future<void> _testFirestoreConnection() async {
    try {
      print("🧪 [Test] جاري اختبار اتصال Firestore...");
      final testDoc = await FirebaseFirestore.instance.collection('OrdersChat').doc('test_connection').get();
      print("✅ [Test] قراءة ناجحة: ${testDoc.exists ? 'موجود' : 'غير موجود'}");

      await FirebaseFirestore.instance.collection('OrdersChat').doc('test_connection').set({
        'test': true,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));
      print("✅ [Test] كتابة ناجحة في Firestore!");

      await FirebaseFirestore.instance.collection('OrdersChat').doc('test_connection').delete();
    } catch (e) {
      print("❌ [Test] فشل اختبار Firestore: $e");
    }
  }

  String _formatTime(int? epoch) {
    if (epoch == null) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(epoch);
    return DateFormat('hh:mm a', 'ar').format(date);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text("جاري التحميل...")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white24,
              child: Icon(Icons.two_wheeler, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.driverName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Text("المندوب", style: TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report, color: Colors.white),
            onPressed: _testFirestoreConnection,
            tooltip: "اختبار الاتصال",
          ),
        ],
      ),
      body: Column(
        children: [
          // 📜 منطقة عرض الرسائل
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('OrdersChat')
                  .doc(widget.orderId.trim())
                  .snapshots()
                  .handleError((error) {
                print("❌ [Stream] خطأ في الاستماع: $error");
              }),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 50, color: Colors.red),
                          const SizedBox(height: 10),
                          Text('خطأ في قاعدة البيانات:\n${snapshot.error}', style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                          const SizedBox(height: 15),
                          ElevatedButton(onPressed: () => setState(() {}), child: const Text("إعادة المحاولة")),
                        ],
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 15),
                        const Text('ابدأ الدردشة مع المندوب الآن', style: TextStyle(color: Colors.grey, fontSize: 16)),
                        const SizedBox(height: 10),
                        Text("رقم الطلب: ${widget.orderId.trim()}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  );
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                List<dynamic> messages = data['messages'] ?? [];

                messages.sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));

                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index] as Map<String, dynamic>;
                    final isMe = msg['senderId'] == _customerId;
                    return _buildMessageBubble(msg, isMe);
                  },
                );
              },
            ),
          ),

          // ⌨️ منطقة إدخال النص
          Container(
            padding: const EdgeInsets.only(left: 10, right: 10, bottom: 20, top: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, -5))],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      decoration: InputDecoration(
                        hintText: 'اكتب رسالة للمندوب...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _isSending ? null : _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Theme.of(context).primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                      ),
                      child: _isSending
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? Theme.of(context).primaryColor : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 0 : 20),
            bottomRight: Radius.circular(isMe ? 20 : 0),
          ),
          boxShadow: [
            BoxShadow(
                color: isMe ? Theme.of(context).primaryColor.withOpacity(0.2) : Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3)
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Text(
              msg['text'] ?? '',
              style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 16, height: 1.3),
            ),
            const SizedBox(height: 6),
            Text(
              _formatTime(msg['timestamp'] as int?),
              style: TextStyle(color: isMe ? Colors.white70 : Colors.grey.shade500, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}












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

  // 🔥 المتغيرات الخاصة بالأقسام
  List<dynamic> _categories = [];
  int? _selectedCategoryId;
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  // 🔥 جلب الأقسام من السيرفر
  Future<void> _fetchCategories() async {
    try {
      // نعتمد على رقم المطعم الموجود في أول منتج تم جلبه مسبقاً
      if (widget.productProvider.products.isNotEmpty) {
        int restaurantId = widget.productProvider.products.first.categoryId;
        final cats = await ApiService().getSubcategories(restaurantId);
        if (mounted) {
          setState(() {
            _categories = cats;
            _isLoadingCategories = false;
          });
        }
      } else {
        setState(() => _isLoadingCategories = false);
      }
    } catch (e) {
      setState(() => _isLoadingCategories = false);
    }
  }

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

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("الرجاء اختيار صورة للوجبة")));
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("الرجاء اختيار القسم الخاص بالوجبة")));
      return;
    }

    setState(() => _isLoading = true);

    // 🔥 استدعاء دالة API الجديدة التي تربط الوجبة بالقسم
    final success = await ApiService().createProductWithSubcategory(
      widget.authProvider.token!,
      _nameController.text,
      _priceController.text,
      _salePriceController.text.isEmpty ? null : _salePriceController.text,
      _descController.text,
      _selectedImage,
      _selectedCategoryId!, // 👈 تمرير القسم
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        // تحديث قائمة المنتجات بعد الإضافة
        widget.productProvider.fetchProducts(widget.authProvider.token);
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("فشل إضافة الوجبة"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("إضافة وجبة جديدة")),
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
                  decoration: const InputDecoration(labelText: 'اسم الوجبة', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null,
                ),
                const SizedBox(height: 16),

                // 🔥 القائمة المنسدلة لاختيار القسم
                if (_isLoadingCategories)
                  const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
                else if (_categories.isNotEmpty)
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: 'اختر القسم (مطلوب)', border: OutlineInputBorder()),
                    value: _selectedCategoryId,
                    items: _categories.map<DropdownMenuItem<int>>((cat) {
                      return DropdownMenuItem<int>(
                        value: cat['id'],
                        child: Text("${cat['icon'] ?? ''} ${cat['name']}"),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedCategoryId = val),
                    validator: (v) => v == null ? 'يجب اختيار قسم' : null,
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                    child: const Text("يرجى إنشاء قسم أولاً من شاشة المنتجات لتتمكن من إضافة وجبات.", style: TextStyle(color: Colors.red)),
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
                  decoration: const InputDecoration(labelText: 'وصف الوجبة والمكونات', border: OutlineInputBorder()),
                  maxLines: 3,
                ),
                const SizedBox(height: 30),

                ElevatedButton(
                  onPressed: (_isLoading || _categories.isEmpty) ? null : _submit,
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                  ),
                  child: const Text('حفظ الوجبة'),
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
  final String status;
  final String description;
  final double deliveryFee;
  final double orderTotal;
  final String pickupName;
  final String sourceType;
  final String destinationAddress;
  final String pickupLat;
  final String pickupLng;
  final String destLat;
  final String destLng;
  final String itemsSummary;
  final int dateCreated;
  final String customerPhone;
  final List<dynamic> lineItems;

  final String? driverName;
  final String? driverPhone;

  UnifiedDeliveryOrder({
    required this.id,
    required this.status,
    required this.description,
    required this.deliveryFee,
    required this.orderTotal,
    required this.pickupName,
    required this.sourceType,
    required this.destinationAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.destLat,
    required this.destLng,
    required this.itemsSummary,
    required this.dateCreated,
    required this.customerPhone,
    required this.lineItems,
    this.driverName,
    this.driverPhone,
  });

  factory UnifiedDeliveryOrder.fromJson(Map<String, dynamic> json) {
    String safeString(dynamic val) => val == null ? '' : val.toString();
    double safeDouble(dynamic val) => val == null ? 0.0 : (double.tryParse(val.toString()) ?? 0.0);

    // 🔥 1. قراءة الحالة من جميع السيرفرات (المطعم يستخدم delivery_status والتكسي يستخدم order_status)
    String parsedStatus = json['delivery_status'] ?? json['order_status'] ?? json['status'] ?? 'pending';

    // 🔥 2. قراءة بيانات السائق (سواء كان كائن أو حقل مسطح)
    String? dName = json['driver_name'];
    String? dPhone = json['driver_phone'];

    if (json['driver'] != null && json['driver'] is Map) {
      dName = json['driver']['name'] ?? dName;
      dPhone = json['driver']['phone'] ?? dPhone;
    }

    return UnifiedDeliveryOrder(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      status: parsedStatus, // استخدام الحالة الذكية
      description: safeString(json['order_description'] ?? json['items_description']),
      deliveryFee: safeDouble(json['delivery_fee'] ?? json['shipping_total']),
      orderTotal: safeDouble(json['order_total'] ?? json['total_to_collect'] ?? json['total']),

      // مطابقة أسماء الأماكن من المطعم، التكسي، أو المسواك
      pickupName: safeString(json['restaurant_name'] ?? json['store_name'] ?? json['pickup_location_name'] ?? json['pickup_location']),
      sourceType: safeString(json['source_type'] ?? json['source'] ?? 'restaurant'),
      destinationAddress: safeString(json['destination_address'] ?? json['customer_address']),
      pickupLat: safeString(json['pickup_lat']),
      pickupLng: safeString(json['pickup_lng']),
      destLat: safeString(json['destination_lat']),
      destLng: safeString(json['destination_lng']),
      itemsSummary: safeString(json['items_summary'] ?? json['items_description']),

      dateCreated: json['date_created'] is int
          ? json['date_created']
          : (DateTime.tryParse(safeString(json['date_created']))?.millisecondsSinceEpoch ?? 0) ~/ 1000,

      customerPhone: safeString(json['end_customer_phone'] ?? json['customer_phone']),
      lineItems: json['line_items'] is List ? json['line_items'] : [],

      driverName: dName,
      driverPhone: dPhone,
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

    // 🔥 1. محاولة تسجيل الدخول الثلاثي الشامل (مطاعم + مسواك + تكسي)
    final success = await authProvider.login(
        _usernameController.text,
        _passwordController.text,
        'leader'
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context); // إغلاق شاشة الدخول

      if (authProvider.token != null) {
        // 🔥 2. الانتقال إلى الداشبورد الأساسي ذو الـ 4 تبويبات
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RegionDashboardScreen(
              token: authProvider.token!,
              areaId: 0,
              areaName: "لوحة القيادة",
            ),
          ),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم الدخول لجميع الأنظمة بنجاح!"), backgroundColor: Colors.green),
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

  // مؤقت لتنظيم التحديث (لحماية السيرفر من تكرار الطلبات)
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // الكل، مطاعم، مسواك، تكسي

    // 1. تحميل البيانات لأول مرة
    _loadData();

    // 2. الاستماع للإشعارات لتحديث القائمة تلقائياً
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (mounted) {
        print("🔔 تيم ليدر: إشعار جديد! جدولة التحديث...");
        _triggerSmartRefresh(); // استخدام التحديث الذكي
      }
    });
  }

  // دالة التحديث الذكي (تنتظر 25 ثانية لتجميع الإشعارات)
  void _triggerSmartRefresh() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    _debounceTimer = Timer(const Duration(seconds: 25), () {
      if (mounted) {
        print("🚀 تنفيذ التحديث الآن!");
        _loadData();
      }
    });
  }

  // دالة لتحميل البيانات وحفظها في المتغير
  void _loadData() {
    setState(() {
      // استخدام دالة الدمج الجديدة
      _ordersFuture = _fetchAllOrdersCombined();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel(); // إلغاء المؤقت عند الخروج
    _tabController.dispose();
    super.dispose();
  }

  // 🔥🔥🔥 الدالة الجوهرية: دمج طلبات المطاعم والمسواك فقط 🔥🔥🔥
  Future<List<UnifiedDeliveryOrder>> _fetchAllOrdersCombined() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    // 1. طلبات المطاعم (من سيرفر re.beytei.com)
    final restaurantFuture = _apiService.getOrdersByRegion(widget.areaId, widget.token);

    // 2. طلبات المسواك (من سيرفر beytei.com)
    Future<List<UnifiedDeliveryOrder>> miswakFuture = Future.value([]);
    if (auth.miswakToken != null) {
      miswakFuture = _apiService.getMiswakOrdersByRegion(widget.areaId, auth.miswakToken!);
    }

    try {
      // 3. انتظار الاثنين ودمجهم
      final results = await Future.wait([restaurantFuture, miswakFuture]);

      List<UnifiedDeliveryOrder> allOrders = [];
      allOrders.addAll(results[0]); // إضافة المطاعم
      allOrders.addAll(results[1]); // إضافة المسواك

      // 4. الترتيب حسب التاريخ (الأحدث أولاً)
      allOrders.sort((a, b) => b.dateCreated.compareTo(a.dateCreated));

      return allOrders;
    } catch (e) {
      print("Error merging orders: $e");
      return [];
    }
  }

  // 🔥 نافذة تسجيل دخول التكسي المستقلة (On-Demand)
  void _showTaxiLoginDialog(BuildContext context) {
    final usernameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    bool isLoading = false;
    String errorMessage = "";

    // ✅ الحل الأكيد: جلب الـ Provider هنا قبل الدخول في StatefulBuilder
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => StatefulBuilder(
            builder: (innerContext, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: const Row(
                  children: [
                    Icon(Icons.local_taxi, color: Colors.amber, size: 28),
                    SizedBox(width: 10),
                    Text("دخول مراقبة التكسي", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("يجب تسجيل الدخول لنظام التكسي للوصول لرحلات منطقتك الحية.", style: TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 15),
                    TextField(
                      controller: usernameCtrl,
                      decoration: InputDecoration(
                        labelText: "اسم المستخدم",
                        prefixIcon: const Icon(Icons.person),
                        filled: true, fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: passwordCtrl,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "كلمة المرور",
                        prefixIcon: const Icon(Icons.lock),
                        filled: true, fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                    ),
                    if (errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(errorMessage, style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    ]
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: isLoading ? null : () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      Navigator.pop(dialogCtx);
                    },
                    child: const Text("إلغاء", style: TextStyle(color: Colors.grey)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                    ),
                    onPressed: isLoading ? null : () async {
                      FocusManager.instance.primaryFocus?.unfocus();

                      if (usernameCtrl.text.isEmpty || passwordCtrl.text.isEmpty) {
                        setDialogState(() => errorMessage = "يرجى ملء جميع الحقول!");
                        return;
                      }

                      setDialogState(() {
                        isLoading = true;
                        errorMessage = "";
                      });

                      try {
                        bool success = await authProvider.loginTeamLeader(usernameCtrl.text, passwordCtrl.text);

                        if (success) {
                          if (innerContext.mounted) Navigator.pop(innerContext);
                          await Future.delayed(const Duration(milliseconds: 100));

                          if (mounted) Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TeamLeaderZoneRidesScreen()));
                        } else {
                          setDialogState(() => errorMessage = "البيانات غير صحيحة، تأكد من البيانات.");
                        }
                      } catch (e) {
                        setDialogState(() => errorMessage = "حدث خطأ: ${e.toString()}");
                      }
                      finally {
                        if (innerContext.mounted) {
                          setDialogState(() => isLoading = false);
                        }
                      }
                    },
                    child: isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                        : const Text("دخول", style: TextStyle(fontWeight: FontWeight.bold)),
                  )
                ],
              );
            }
        )
    );
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

        actions: [
          // 🔥 زر التكسي الذكي (يفحص الدخول أولاً)
          IconButton(
            icon: const Icon(Icons.local_taxi, color: Colors.white),
            tooltip: "مراقبة التكسي الحية",
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final monitoringToken = prefs.getString('taxi_monitoring_token');

              if (monitoringToken != null && monitoringToken.isNotEmpty) {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TeamLeaderZoneRidesScreen()));
              } else {
                _showTaxiLoginDialog(context);
              }
            },
          ),

          IconButton(
            icon: const Icon(Icons.account_balance_wallet, color: Colors.amber),
            tooltip: "المكافآت والرصيد",
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TeamLeaderRewardsScreen(token: widget.token),
                ),
              );
            },
          ),
        ],

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
            Tab(text: "👥 السائقين "),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFutureOrdersList(type: 'all'),
          _buildFutureOrdersList(type: 'restaurant'),
          _buildFutureOrdersList(type: 'market'),
          TeamOrdersScreen(token: widget.token),
        ],
      ),
    );
  }

  // دالة مساعدة لبناء القوائم (تم إصلاحها وإضافة onActionComplete)
  Widget _buildFutureOrdersList({required String type}) {
    return RefreshIndicator(
      onRefresh: () async {
        _loadData();
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

          List<UnifiedDeliveryOrder> orders = snapshot.data ?? [];

          if (type != 'all') {
            orders = orders.where((o) => o.sourceType == type).toList();
          }

          if (orders.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 200),
                Center(child: Text("لا توجد طلبات في هذا القسم حالياً 😴")),
              ],
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              return TeamLeaderOrderCard(
                order: orders[index],
                token: widget.token,
                onActionComplete: () => _loadData(), // ✅ تم الإصلاح هنا
              );
            },
          );
        },
      ),
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
// =======================================================================
// --- الزر السري لدخول الإدارة (شبه شفاف + ضغط 3 ثواني) ---
// =======================================================================


// =======================================================================
// --- الزر السري لدخول الإدارة (شبه شفاف + ضغط 3 ثواني) ---
// =======================================================================
class SecretAdminButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onUnlock;

  const SecretAdminButton({super.key, required this.icon, required this.onUnlock});

  @override
  State<SecretAdminButton> createState() => _SecretAdminButtonState();
}

class _SecretAdminButtonState extends State<SecretAdminButton> {
  Timer? _timer;

  void _startTimer() {
    // تفعيل المؤقت لمدة 3 ثواني
    _timer = Timer(const Duration(seconds: 3), () {
      // بعد 3 ثواني، اهتزاز خفيف للموبايل وتنفيذ الدخول
      HapticFeedback.heavyImpact();
      widget.onUnlock();
    });
  }

  void _cancelTimer() {
    _timer?.cancel(); // إذا رفع إصبعه قبل 3 ثواني يُلغى الأمر
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _startTimer(),
      onTapUp: (_) => _cancelTimer(),
      onTapCancel: () => _cancelTimer(),
      child: Opacity(
        opacity: 0.2, // شبه شفاف (مخفي تقريباً)
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Icon(widget.icon, color: Colors.black, size: 24),
        ),
      ),
    );
  }
}
