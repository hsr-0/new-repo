import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'de.dart';

final ValueNotifier<Map<String, dynamic>?> acceptedRideNotifier = ValueNotifier(null);

// =============================================================================
// Global Navigator Key & Deep Link Notifier
// =============================================================================
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final ValueNotifier<Map<String, String>> deepLinkNotifier = ValueNotifier({});

// =============================================================================
// Firebase Cloud Messaging API Handler
// =============================================================================
class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;

  Future<String?> getFcmToken() async {
    try {
      final fcmToken = await _firebaseMessaging.getToken();
      debugPrint('Firebase Token: $fcmToken');
      return fcmToken;
    } catch (e) {
      debugPrint("Failed to get FCM token: $e");
      return null;
    }
  }

  Future<void> initNotifications() async {
    await _firebaseMessaging.requestPermission();
    initPushNotifications();
  }

  void handleMessage(RemoteMessage? message) {
    if (message == null) return;
    final userType = message.data['userType'] ?? '';
    final targetScreen = message.data['targetScreen'] ?? '';
    deepLinkNotifier.value = {'userType': userType, 'targetScreen': targetScreen};
  }

  Future<void> initPushNotifications() async {
    FirebaseMessaging.instance.getInitialMessage().then(handleMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint("--- إشعار جديد وصل --- البيانات: ${message.data}");
      final notification = message.notification;
      if (notification == null) return;

      // --- المنطق الجديد والمبسط ---
      final status = message.data['status'] as String?;
      if (status == 'accepted' && message.data['ride_data'] != null) {
        // تم قبول الرحلة، مرر البيانات مباشرة
        final rideData = json.decode(message.data['ride_data']);
        acceptedRideNotifier.value = rideData;
      }  // الحالة 2: يوجد طلب توصيل جديد
      NotificationService.showNotification(
        notification.title ?? 'طلب توصيل جديد',
        notification.body ?? '',
        payload: json.encode(message.data),
        type: 'high_priority', // اجعل الإشعار بأولوية عالية
      );

    });
  }
}

// =============================================================================
// Helper Classes & Functions
// =============================================================================
class LatLngTween extends Tween<LatLng> {
  LatLngTween({required LatLng begin, required LatLng end}) : super(begin: begin, end: end);
  @override
  LatLng lerp(double t) => LatLng(begin!.latitude + (end!.latitude - begin!.latitude) * t, begin!.longitude + (end!.longitude - begin!.longitude) * t);
}

double calculateBearing(LatLng startPoint, LatLng endPoint) {
  if (startPoint.latitude == endPoint.latitude && startPoint.longitude == endPoint.longitude) return 0.0;
  final lat1 = startPoint.latitudeInRad;
  final lon1 = startPoint.longitudeInRad;
  final lat2 = endPoint.latitudeInRad;
  final lon2 = endPoint.longitudeInRad;
  final dLon = lon2 - lon1;
  final y = sin(dLon) * cos(lat2);
  final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
  final bearing = atan2(y, x);
  return (bearing * 180 / pi + 360) % 360;
}

Future<void> makePhoneCall(String? phoneNumber, BuildContext context) {
  if (phoneNumber == null || phoneNumber.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رقم الهاتف غير متوفر')));
    }
    return Future.value();
  }
  final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
  launchUrl(launchUri).catchError((_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('لا يمكن إجراء الاتصال بالرقم $phoneNumber')));
    }
  });
  return Future.value();
}

// =============================================================================
// Permission Service
// =============================================================================
class PermissionService {
  static Future<bool> handleLocationPermission(BuildContext context) async {
    bool serviceEnabled = await geolocator.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خدمات الموقع معطلة. الرجاء تفعيل خدمات الموقع.')));
      return false;
    }
    geolocator.LocationPermission permission = await geolocator.Geolocator.checkPermission();
    if (permission == geolocator.LocationPermission.denied) {
      permission = await geolocator.Geolocator.requestPermission();
      if (permission == geolocator.LocationPermission.denied) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم رفض إذن الوصول للموقع.')));
        return false;
      }
    }
    if (permission == geolocator.LocationPermission.deniedForever) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم رفض إذن الموقع بشكل دائم. يرجى تفعيله من إعدادات التطبيق.')));
      return false;
    }
    return true;
  }
}

// =============================================================================
// Entry Point & App Theme
// =============================================================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.initialize();
  final prefs = await SharedPreferences.getInstance();
  final showOnboarding = prefs.getBool('showOnboarding') ?? true;
  runApp(MyApp(showOnboarding: showOnboarding));
}

class MyApp extends StatelessWidget {
  final bool showOnboarding;
  const MyApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'تكسي بيتي',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.amber,
        fontFamily: 'Cairo',
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 250, 250, 250),
          foregroundColor: Colors.black,
          elevation: 0.5,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(fontFamily: 'Cairo', color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        cardTheme: CardThemeData(elevation: 1, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade400)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.amber, width: 2)),
          filled: true,
          fillColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber[700],
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            textStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

// =============================================================================
// Models & Services
// =============================================================================
class AuthResult {
  final String token;
  final String userId;
  final String displayName;
  final bool isDriver;
  final String? driverStatus;
  AuthResult({required this.token, required this.userId, required this.displayName, required this.isDriver, this.driverStatus});

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      token: json['token'],
      userId: json['user_id'].toString(),
      displayName: json['display_name'],
      isDriver: json['is_driver'] ?? false,
      driverStatus: json['driver_status'],
    );
  }
}

class ApiService {
  static const String baseUrl = 'https://banner.beytei.com/wp-json';
  static const _storage = FlutterSecureStorage();
  static Future<void> storeAuthData(AuthResult authResult) async {
    await _storage.write(key: 'auth_token', value: authResult.token);
    await _storage.write(key: 'user_id', value: authResult.userId);
    await _storage.write(key: 'display_name', value: authResult.displayName);
    await _storage.write(key: 'is_driver', value: authResult.isDriver.toString());
    if (authResult.driverStatus != null) await _storage.write(key: 'driver_status', value: authResult.driverStatus);
  }






  static Future<Map<String, dynamic>?> getRideDetails(String token, String rideId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/taxi/v2/rides/status?ride_id=$rideId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['ride'] != null) {
          return data['ride'];
        }
      }
      return null;
    } catch (e) {
      debugPrint("Failed to get ride details: $e");
      return null;
    }
  }








  static Future<void> clearAuthData() async => await _storage.deleteAll();
  static Future<AuthResult?> getStoredAuthData() async {
    final token = await _storage.read(key: 'auth_token');
    final userId = await _storage.read(key: 'user_id');
    final displayName = await _storage.read(key: 'display_name');
    final isDriverStr = await _storage.read(key: 'is_driver');
    final driverStatus = await _storage.read(key: 'driver_status');
    if (token != null && userId != null && displayName != null && isDriverStr != null) {
      return AuthResult(token: token, userId: userId, displayName: displayName, isDriver: isDriverStr.toLowerCase() == 'true', driverStatus: driverStatus);
    }
    return null;
  }

  static Future<http.Response> _post(String endpoint, String token, Map<String, dynamic> body) {
    return http.post(Uri.parse('$baseUrl$endpoint'), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}, body: json.encode(body));
  }





  static Future<http.Response> _get(String endpoint, String token) {
    return http.get(Uri.parse('$baseUrl$endpoint'), headers: {'Authorization': 'Bearer $token'});
  }

  static Future<http.Response> createUnifiedDelivery(String token, Map<String, dynamic> body) {
    return _post('/taxi/v2/delivery/create', token, body);
  }

  static Future<void> updateFcmToken(String authToken, String fcmToken) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/taxi-auth/v1/update-fcm-token'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $authToken'},
        body: json.encode({'fcm_token': fcmToken}),
      );
    } catch (e) {
      debugPrint("Failed to update FCM token: $e");
    }
  }




  static Future<http.Response> v2AcceptRide(String token, String rideId) {
    return _post('/taxi/v2/driver/accept-ride', token, {'ride_id': rideId});
  }

  static Future<void> setDriverActiveStatus(String token, bool isActive) async {
    try {
      await _post('/taxi/v2/driver/set-active-status', token, {'is_active': isActive});
    } catch (e) {
      debugPrint("Failed to set driver active status: $e");
    }
  }

  static Future<http.Response> driverCounterOffer(String token, String rideId, double price) {
    return _post('/taxi/v2/driver/rides/counter-offer', token, {
      'ride_id': rideId,
      'price': price,
    });
  }

  static Future<void> updateDriverLocation(String token, LatLng location) async {
    try {
      await _post('/taxi/v2/driver/update-location', token, {'lat': location.latitude, 'lng': location.longitude});
    } catch (e) {
      debugPrint("Failed to update driver location: $e");
    }
  }

  static Future<List<dynamic>> fetchActiveDrivers(String token) async {
    try {
      final response = await _get('/taxi/v2/customer/active-drivers', token);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['drivers'] is List) return data['drivers'];
      }
      return [];
    } catch (e) {
      debugPrint("Failed to fetch active drivers: $e");
      return [];
    }
  }
  static Future<List<dynamic>> getCustomerTripHistory(String token) async {
    final response = await _get('/taxi/v2/customer/trip-history', token);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true && data['history'] is List) {
        return data['history'];
      }
    }
    throw Exception('Failed to load trip history');
  }
  static Future<LatLng?> getRideDriverLocation(String token, String rideId) async {
    try {
      final response = await _get('/taxi/v2/rides/driver-location?ride_id=$rideId', token);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['location'] != null) {
          return LatLng(double.parse(data['location']['lat']), double.parse(data['location']['lng']));
        }
      }
      return null;
    } catch (e) {
      debugPrint("Failed to get driver location for ride: $e");
      return null;
    }
  }






  static Future<http.Response> createPrivateRequest(String token, Map<String, dynamic> body) {
    return _post('/taxi/v2/private-requests/create', token, body);
  }

  static Future<List<dynamic>> getAvailablePrivateRequests(String token) async {
    final response = await _get('/taxi/v2/private-requests/available', token);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load private requests');
    }
  }

  static Future<Map<String, dynamic>> getDriverHubData(String token) async {
    final response = await _get('/taxi/v2/driver/hub', token);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return data['data'];
      }
    }
    throw Exception('Failed to load driver hub data');
  }


  // للسائق: جلب طلبات التوصيل المتاحة
  static Future<List<dynamic>> getAvailableDeliveries(String token) async {
    try {
      final response = await _get('/taxi/v2/delivery/available', token);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['orders'] is List) {
          return data['orders'];
        }
      }
      return [];
    } catch (e) {
      debugPrint("Failed to fetch deliveries: $e");
      return [];
    }
  }

  /// للسائق: قبول طلب توصيل
  static Future<http.Response> acceptDelivery(String token, String orderId) {
    return _post('/taxi/v2/delivery/accept', token, {'order_id': orderId});
  }

  /// للسائق: تحديث حالة طلب التوصيل
  static Future<http.Response> updateDeliveryStatus(String token, String orderId, String newStatus) {
    return _post('/taxi/v2/delivery/update-status', token, {'order_id': orderId, 'status': newStatus});
  }

  static Future<http.Response> confirmPickupByCode(String token, String orderId, String pickupCode) {
    return _post('/taxi/v2/delivery/confirm-pickup', token, {
      'order_id': orderId,
      'pickup_code': pickupCode,
    });
  }


  static Future<http.Response> acceptPrivateRequest(String token, String requestId) {
    return _post('/taxi/v2/private-requests/accept', token, {'request_id': requestId});
  }

  static Future<http.Response> driverCompletePrivateRequest(String token, String requestId) {
    return _post('/taxi/v2/driver/private-requests/complete', token, {'request_id': requestId});
  }

  static Future<http.Response> getMyActivePrivateRequest(String token) {
    return _get('/taxi/v2/private-requests/my-active', token);
  }

  static Future<http.Response> cancelMyPrivateRequest(String token, String requestId) {
    return _post('/taxi/v2/private-requests/cancel', token, {'request_id': requestId});
  }

  static Future<Map<String, dynamic>> getDriverDashboard(String token) async {
    final response = await _get('/taxi/v2/driver/dashboard', token);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load driver dashboard');
    }
  }

  static Future<List<dynamic>> getOffers(String token) async {
    final response = await http.get(Uri.parse('$baseUrl/taxi/v2/offers'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load offers');
    }
  }

  static Future<http.Response> rateRide(String token, Map<String, dynamic> body) {
    return _post('/taxi/v2/rides/rate', token, body);
  }

  static Future<http.Response> customerRespondToOffer(String token, String rideId, String driverId, String action) {
    return _post('/taxi/v2/customer/rides/respond-offer', token, {
      'ride_id': rideId,
      'driver_id': driverId,
      'action': action,
    });
  }





// ========  الكود الجديد هنا ========
  // دوال جديدة خاصة بنظام خطوط الطلاب للسائق

  /// للسائق: إنشاء خط طلاب جديد
  static Future<http.Response> createStudentLine(String token, Map<String, dynamic> body) {
    return _post('/taxi/v2/student-lines/create', token, body);
  }

  /// للسائق: جلب الخطوط التي أنشأها
  static Future<List<dynamic>> getMyStudentLines(String token) async {
    // تم تعديل المسار هنا ليتوافق مع الواجهة الخلفية
    final response = await _get('/taxi/v2/student-lines/my-lines', token);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true && data['lines'] is List) {
        return data['lines'];
      }
    }
    throw Exception('Failed to load my student lines');
  }
  /// للسائق: تحديث حالة طالب (استلام/توصيل)
  static Future<http.Response> updateStudentStatus(String token, Map<String, dynamic> body) {
    return _post('/taxi/v2/student-lines/update-student-status', token, body);
  }
// ======== نهاية الكود الجديد ========





















  static Future<Map<String, dynamic>> getDriverLiveStats(String token) async {
    try {
      final response = await _get('/taxi/v2/driver/live-stats', token);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['stats'] != null) {
          return data['stats'];
        }
      }
      throw Exception('Failed to load live stats');
    } catch (e) {
      debugPrint("Failed to fetch live stats: $e");
      return {};
    }
  }
}
final ValueNotifier<String?> acceptedRideIdNotifier = ValueNotifier(null);

// =============================================================================
// NotificationService (with Channels)
// =============================================================================
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static const AndroidNotificationChannel _highImportanceChannel = AndroidNotificationChannel('high_importance_channel', 'High Importance Notifications', description: 'This channel is used for important notifications.', importance: Importance.max, playSound: true);
  static const AndroidNotificationChannel _defaultImportanceChannel = AndroidNotificationChannel('default_importance_channel', 'Default Importance Notifications', description: 'This channel is used for general notifications.', importance: Importance.defaultImportance, playSound: true, enableVibration: true);

  static Future<void> initialize() async {
    const InitializationSettings initializationSettings = InitializationSettings(android: AndroidInitializationSettings("@mipmap/ic_launcher"), iOS: DarwinInitializationSettings());
    await _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(_highImportanceChannel);
    await _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(_defaultImportanceChannel);
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
        if (notificationResponse.payload != null) {
          try {
            final Map<String, dynamic> payloadData = json.decode(notificationResponse.payload!);
            deepLinkNotifier.value = {'userType': payloadData['userType'] ?? '', 'targetScreen': payloadData['targetScreen'] ?? ''};
          } catch (e) {
            debugPrint('Error parsing notification payload: $e');
          }
        }
      },
    );
    final NotificationAppLaunchDetails? notificationAppLaunchDetails = await _notificationsPlugin.getNotificationAppLaunchDetails();
    if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
      if (notificationAppLaunchDetails!.notificationResponse?.payload != null) {
        try {
          final Map<String, dynamic> payloadData = json.decode(notificationAppLaunchDetails.notificationResponse!.payload!);
          deepLinkNotifier.value = {'userType': payloadData['userType'] ?? '', 'targetScreen': payloadData['targetScreen'] ?? ''};
        } catch (e) {
          debugPrint('Error parsing launch notification payload: $e');
        }
      }
    }
  }

  static Future<void> showNotification(String title, String body, {String? payload, String type = 'default'}) async {
    final NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        type == 'high_priority' ? _highImportanceChannel.id : _defaultImportanceChannel.id,
        type == 'high_priority' ? _highImportanceChannel.name : _defaultImportanceChannel.name,
        channelDescription: type == 'high_priority' ? _highImportanceChannel.description : _defaultImportanceChannel.description,
        importance: type == 'high_priority' ? Importance.max : Importance.defaultImportance,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(body),
      ),
    );
    await _notificationsPlugin.show(DateTime.now().millisecondsSinceEpoch.toSigned(31), title, body, notificationDetails, payload: payload);
  }
}

// =============================================================================
// UI Enhancement Widgets
// =============================================================================
class EmptyStateWidget extends StatelessWidget {
  final String svgAsset;
  final String message;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  const EmptyStateWidget({super.key, required this.svgAsset, required this.message, this.buttonText, this.onButtonPressed});
  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(padding: const EdgeInsets.all(32.0), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [SvgPicture.string(svgAsset, height: 150, colorFilter: ColorFilter.mode(Colors.grey[400]!, BlendMode.srcIn)), const SizedBox(height: 24), Text(message, style: TextStyle(fontSize: 18, color: Colors.grey[700]), textAlign: TextAlign.center), const SizedBox(height: 24), if (buttonText != null && onButtonPressed != null) ElevatedButton(onPressed: onButtonPressed, child: Text(buttonText!))])));
  }
}

class ShimmerListItem extends StatelessWidget {
  const ShimmerListItem({super.key});
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!, child: Padding(padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 60.0, height: 60.0, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[const SizedBox(height: 8), Container(width: double.infinity, height: 10.0, color: Colors.white), const SizedBox(height: 8), Container(width: 150, height: 10.0, color: Colors.white)]))])));
  }
}

class RotatingVehicleIcon extends StatelessWidget {
  final String vehicleType;
  final double bearing;
  const RotatingVehicleIcon({super.key, required this.vehicleType, required this.bearing});
  @override
  Widget build(BuildContext context) {
    const String carSvg = '''<svg viewBox="0 0 80 160" xmlns="http://www.w3.org/2000/svg"><defs><filter id="shadow" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur in="SourceAlpha" stdDeviation="3"/><feOffset dx="2" dy="5" result="offsetblur"/><feComponentTransfer><feFuncA type="linear" slope="0.5"/></feComponentTransfer><feMerge><feMergeNode/><feMergeNode in="SourceGraphic"/></feMerge></filter></defs><g transform="translate(0, 0)" filter="url(#shadow)"><path d="M25,10 C15,10 10,20 10,30 L10,130 C10,140 15,150 25,150 L55,150 C65,150 70,140 70,130 L70,30 C70,20 65,10 55,10 L25,10 Z" fill="#FFFFFF"/><path d="M20,25 C15,25 15,30 15,35 L15,70 L65,70 L65,35 C65,30 65,25 60,25 L20,25 Z" fill="#424242" opacity="0.8"/><path d="M15,80 L15,120 C15,125 20,125 20,125 L60,125 C65,125 65,120 65,120 L65,80 L15,80 Z" fill="#616161" opacity="0.7"/></g></svg>''';
    const String tuktukSvg = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor"><path d="M20 17.17V10c0-2.21-1.79-4-4-4h-2.1c-.83-2.32-3.07-4-5.9-4-3.31 0-6 2.69-6 6s2.69 6 6 6c.34 0 .67-.04 1-.09V17H2v2h18v-2h-2zm-8-2c-1.1 0-2-.9-2-2s.9-2 2-2 2 .9 2 2-.9 2-2 2zM5 8c0-2.21 1.79-4 4-4s4 1.79 4 4-1.79 4-4 4-4-1.79-4-4z"/></svg>''';
    return Transform.rotate(angle: bearing * (pi / 180), child: SvgPicture.string(vehicleType.toLowerCase() == 'tuktuk' ? tuktukSvg : carSvg));
  }
}

class PulsingUserLocationMarker extends StatefulWidget {
  const PulsingUserLocationMarker({super.key});
  @override
  State<PulsingUserLocationMarker> createState() => _PulsingUserLocationMarkerState();
}

class _PulsingUserLocationMarkerState extends State<PulsingUserLocationMarker> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 15 + (15 * _controller.value),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withOpacity(0.8 - (0.8 * _controller.value)),
              ),
            ),
            Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ],
        );
      },
    );
  }
}

// =============================================================================
// Authentication Gate & Welcome Screen
// =============================================================================
enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  AuthStatus _authStatus = AuthStatus.unknown;
  AuthResult? _authResult;
  @override
  void initState() {
    super.initState();
    _checkAuth();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) PermissionService.handleLocationPermission(context);
    });
  }

  Future<void> _checkAuth() async {
    final authData = await ApiService.getStoredAuthData();
    if (mounted) {
      _updateAuthStatus(authData);
      if (authData != null) {
        await _ensureFirebaseSignIn();
        await FirebaseApi().initNotifications();
        final fcmToken = await FirebaseApi().getFcmToken();
        if (fcmToken != null) {
          await ApiService.updateFcmToken(authData.token, fcmToken);
        }
      }
    }
  }

  Future<void> _ensureFirebaseSignIn() async {
    if (fb_auth.FirebaseAuth.instance.currentUser == null) {
      try {
        await fb_auth.FirebaseAuth.instance.signInAnonymously();
        debugPrint("Firebase anonymous sign-in successful.");
      } catch (e) {
        debugPrint("Firebase anonymous sign-in failed: $e");
      }
    }
  }

  void _updateAuthStatus(AuthResult? authResult) {
    setState(() {
      _authResult = authResult;
      _authStatus = authResult != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    });
  }

  Future<void> _logout() async {
    final authData = await ApiService.getStoredAuthData();
    if (authData != null && authData.isDriver) {
      await ApiService.setDriverActiveStatus(authData.token, false);
    }
    await ApiService.clearAuthData();
    await fb_auth.FirebaseAuth.instance.signOut();
    _updateAuthStatus(null);
  }

  @override
  Widget build(BuildContext context) {
    switch (_authStatus) {
      case AuthStatus.unknown:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.unauthenticated:
        return WelcomeScreen(onLoginSuccess: _updateAuthStatus);
      case AuthStatus.authenticated:
        if (_authResult!.isDriver) {
          if (_authResult!.driverStatus == 'approved') {
            return DriverMainScreen(authResult: _authResult!, onLogout: _logout);
          } else {
            return DriverPendingScreen(onLogout: _logout, onCheckStatus: _updateAuthStatus, phone: _authResult!.displayName);
          }
        } else {
          return CustomerMainScreen(authResult: _authResult!, onLogout: _logout);
        }
    }
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
  final String privacyPolicyUrl = 'https://beytei.com/privacy-policy/';

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Webview error: ${error.description}');
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('فشل تحميل الصفحة. يرجى التحقق من اتصالك بالإنترنت.')));
            }
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

class WelcomeScreen extends StatefulWidget {
  final Function(AuthResult) onLoginSuccess;
  const WelcomeScreen({super.key, required this.onLoginSuccess});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  bool _privacyPolicyAccepted = false;

  Future<void> _submitCustomerLogin() async {
    if (!_privacyPolicyAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('يجب الموافقة على سياسة الخصوصية للمتابعة'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await http.post(Uri.parse('${ApiService.baseUrl}/taxi-auth/v1/register/customer'), headers: {'Content-Type': 'application/json'}, body: json.encode({'name': _nameController.text, 'phone_number': _phoneController.text}));
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final authResult = AuthResult.fromJson(data);
        await ApiService.storeAuthData(authResult);
        if (fb_auth.FirebaseAuth.instance.currentUser == null) {
          await fb_auth.FirebaseAuth.instance.signInAnonymously();
        }
        await FirebaseApi().initNotifications();
        final fcmToken = await FirebaseApi().getFcmToken();
        if (fcmToken != null) {
          await ApiService.updateFcmToken(authResult.token, fcmToken);
        }
        widget.onLoginSuccess(authResult);
      } else {
        throw Exception(data['message'] ?? 'فشل تسجيل الدخول أو التسجيل');
      }
    } on SocketException {
      if (mounted) setState(() => _errorMessage = 'يرجى التحقق من اتصالك بالإنترنت');
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String logoSvg = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200"><defs><linearGradient id="a" x1="50%" x2="50%" y1="0%" y2="100%"><stop offset="0%" stop-color="#FFD54F"/><stop offset="100%" stop-color="#FF8F00"/></linearGradient></defs><path fill="url(#a)" d="M100 10a90 90 0 1 0 0 180 90 90 0 0 0 0-180zm0 170a80 80 0 1 1 0-160 80 80 0 0 1 0 160z"/><path fill="#FFF" d="M149.5 115.8c-1.2-5.7-6.2-10-12.1-10H62.6c-5.9 0-10.9 4.3-12.1 10L40 140h120l-10.5-24.2zM67.3 85.2h65.4c2.8 0 5 2.2 5 5v10.6H62.3V90.2c0-2.8 2.2-5 5-5z"/><circle cx="70" cy="135" r="10" fill="#212121"/><circle cx="130" cy="135" r="10" fill="#212121"/></svg>''';
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.amber.shade100, Colors.amber.shade400], begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 80.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.string(logoSvg, height: 120),
                const SizedBox(height: 20),
                Text('تكسي بيتي', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                const SizedBox(height: 10),
                Text('الأسرع في مدينتك', style: TextStyle(fontSize: 18, color: Colors.grey[700])),
                const SizedBox(height: 40),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Text("دخول أو تسجيل عميل", style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 20),
                          TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'الاسم الكامل', prefixIcon: Icon(Icons.person_outline)), validator: (v) => v!.isEmpty ? 'الرجاء إدخال الاسم' : null),
                          const SizedBox(height: 15),
                          TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: 'رقم الهاتف', prefixIcon: Icon(Icons.phone_outlined)), keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'الرجاء إدخال رقم الهاتف' : null),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              Checkbox(
                                value: _privacyPolicyAccepted,
                                onChanged: (value) {
                                  setState(() {
                                    _privacyPolicyAccepted = value ?? false;
                                  });
                                },
                              ),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black),
                                    children: [
                                      const TextSpan(text: 'أوافق على '),
                                      TextSpan(
                                        text: 'سياسة الخصوصية',
                                        style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () {
                                            Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()));
                                          },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (_errorMessage != null) Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(_errorMessage!, style: const TextStyle(color: Colors.red))),
                          _isLoading ? const CircularProgressIndicator() : ElevatedButton(onPressed: _submitCustomerLogin, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)), child: const Text('دخول / تسجيل')),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                TextButton.icon(icon: const Icon(Icons.local_taxi), label: const Text('هل أنت سائق؟ اضغط هنا'), onPressed: () {
                  if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => DriverAuthScreen(onLoginSuccess: widget.onLoginSuccess)));
                }, style: TextButton.styleFrom(foregroundColor: Colors.grey[800])),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// =============================================================================
// Driver Suspended Screen
// =============================================================================
class DriverSuspendedScreen extends StatelessWidget {
  final VoidCallback onLogout;
  const DriverSuspendedScreen({super.key, required this.onLogout});

  Future<void> _contactForRecharge(BuildContext context) async {
    const adminPhoneNumber = "+9647854076931"; // !! استبدل هذا برقم الواتساب الخاص بالمسؤول
    final message = "أرغب في شحن محفظتي لمتابعة العمل.";
    final uri = Uri.parse("https://wa.me/$adminPhoneNumber?text=${Uri.encodeComponent(message)}");
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if(context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("لا يمكن فتح واتساب. تأكد من تثبيته على جهازك.")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[50],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_balance_wallet_outlined, size: 80, color: Colors.red[700]),
              const SizedBox(height: 20),
              Text(
                'تم إيقاف حسابك مؤقتًا',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.red[900]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'لقد وصل رصيد محفظتك إلى الحد السالب المسموح به. يرجى شحن المحفظة لمتابعة استقبال الطلبات والرحلات.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black54),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () => _contactForRecharge(context),
                icon: const Icon(Icons.support_agent),
                label: const Text(' تواصل معنا عبر الرقم 07854076931'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(onPressed: onLogout, child: const Text('تسجيل الخروج')),
            ],
          ),
        ),
      ),
    );
  }
}





// =============================================================================
// Generic Login & Driver Registration Screens
// =============================================================================
class LoginScreen extends StatefulWidget {
  final Function(AuthResult) onLoginSuccess;
  const LoginScreen({super.key, required this.onLoginSuccess});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await http.post(Uri.parse('${ApiService.baseUrl}/taxi-auth/v1/login'), headers: {'Content-Type': 'application/json'}, body: json.encode({'phone_number': _phoneController.text}));
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final authResult = AuthResult.fromJson(data);
        await ApiService.storeAuthData(authResult);
        if (mounted) {
          if (fb_auth.FirebaseAuth.instance.currentUser == null) {
            await fb_auth.FirebaseAuth.instance.signInAnonymously();
          }
          await FirebaseApi().initNotifications();
          final fcmToken = await FirebaseApi().getFcmToken();
          if (fcmToken != null) {
            await ApiService.updateFcmToken(authResult.token, fcmToken);
          }
          Navigator.of(context).popUntil((route) => route.isFirst);
          widget.onLoginSuccess(authResult);
        }
      } else {
        throw Exception(data['message'] ?? 'فشل تسجيل الدخول');
      }
    } on SocketException {
      if (mounted) setState(() => _errorMessage = 'يرجى التحقق من اتصالك بالإنترنت');
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text('أدخل رقم هاتفك المسجل للمتابعة', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
            const SizedBox(height: 30),
            TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: 'رقم الهاتف', prefixIcon: Icon(Icons.phone)), keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'الرجاء إدخال رقم الهاتف' : null),
            const SizedBox(height: 30),
            if (_errorMessage != null) Padding(padding: const EdgeInsets.only(bottom: 15), child: Text(_errorMessage!, style: const TextStyle(color: Colors.red))),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _isLoading ? null : _submit, child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('دخول'))),
          ],
        ),
      ),
    );
  }
}

class DriverAuthScreen extends StatelessWidget {
  final Function(AuthResult) onLoginSuccess;
  const DriverAuthScreen({super.key, required this.onLoginSuccess});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(length: 2, initialIndex: 1, child: Scaffold(appBar: AppBar(title: const Text('بوابة السائقين'), bottom: const TabBar(tabs: [Tab(text: 'تسجيل دخول'), Tab(text: 'تسجيل جديد')])), body: TabBarView(children: [LoginScreen(onLoginSuccess: onLoginSuccess), DriverRegistrationScreen(onLoginSuccess: onLoginSuccess)])));
  }
}

class DriverRegistrationScreen extends StatefulWidget {
  final Function(AuthResult) onLoginSuccess;
  const DriverRegistrationScreen({super.key, required this.onLoginSuccess});
  @override
  State<DriverRegistrationScreen> createState() => _DriverRegistrationScreenState();
}


class _DriverRegistrationScreenState extends State<DriverRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _modelController = TextEditingController();
  final _colorController = TextEditingController();
  final _referralCodeController = TextEditingController(); // Controller for referral code

  String _vehicleType = 'Tuktuk';
  bool _isLoading = false;
  bool _isDeliveryDriver = false;
  String? _errorMessage;
  final ImagePicker _picker = ImagePicker();
  XFile? _registrationImageFile;
  XFile? _personalIdImageFile;

  bool _privacyPolicyAccepted = false;

  Future<void> _pickImage(ImageSource source, Function(XFile) onImagePicked) async {
    final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 70);
    if (pickedFile != null) {
      onImagePicked(pickedFile);
    }
  }

  Future<void> _submit() async {
    if (!_privacyPolicyAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يجب الموافقة على سياسة الخصوصية')));
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_registrationImageFile == null || _personalIdImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء رفع صورة السنوية والهوية الشخصية معًا'), backgroundColor: Colors.red));
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      var request = http.MultipartRequest('POST', Uri.parse('${ApiService.baseUrl}/taxi-auth/v1/register/driver'));

      request.fields.addAll({
        'name': _nameController.text,
        'phone': _phoneController.text,
        'vehicle_type': _vehicleType,
        'car_model': _modelController.text,
        'is_delivery': _isDeliveryDriver.toString(), // <--- أضف هذا السطر المهم

        'car_color': _colorController.text


      });

      if (_referralCodeController.text.isNotEmpty) {
        request.fields['referral_code'] = _referralCodeController.text;
      }

      // ** CORRECTED FILE KEYS TO MATCH THE BACKEND **
      request.files.add(await http.MultipartFile.fromPath('vehicle_registration_image', _registrationImageFile!.path));
      request.files.add(await http.MultipartFile.fromPath('personal_id_image', _personalIdImageFile!.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = json.decode(response.body);

      if (mounted) {
        if (response.statusCode == 201 && data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message']), backgroundColor: Colors.green));
          Navigator.of(context).pop();
        } else {
          throw Exception(data['message'] ?? 'فشل التسجيل');
        }
      }
    } on SocketException {
      if (mounted) setState(() => _errorMessage = 'يرجى التحقق من اتصالك بالإنترنت');
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'الاسم الكامل'), validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null),
            const SizedBox(height: 15),
            TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: 'رقم الهاتف'), keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(value: _vehicleType, decoration: const InputDecoration(labelText: 'نوع المركبة'), items: const [DropdownMenuItem(value: 'Tuktuk', child: Text('توك توك')), DropdownMenuItem(value: 'Car', child: Text('سيارة'))], onChanged: (value) => setState(() => _vehicleType = value!)),
            const SizedBox(height: 15),
            TextFormField(controller: _modelController, decoration: const InputDecoration(labelText: 'رقم لوحة المركبة'), validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null),
            const SizedBox(height: 15),
            TextFormField(controller: _colorController, decoration: const InputDecoration(labelText: 'لون وموديل المركبة'), validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null),
            const SizedBox(height: 15),
            TextFormField(
              controller: _referralCodeController,
              decoration: const InputDecoration(
                labelText: 'رمز الإحالة (اختياري)',
                prefixIcon: Icon(Icons.group),
              ),
            ),
            const SizedBox(height: 20),
            _buildImagePicker(
              title: 'صورة سنوية السيارة',
              icon: Icons.upload_file,
              file: _registrationImageFile,
              onPressed: () => _pickImage(ImageSource.gallery, (file) => setState(() => _registrationImageFile = file)),
            ),
            const SizedBox(height: 15),
            _buildImagePicker(
              title: 'صورة الهوية الشخصية',
              icon: Icons.badge_outlined,
              file: _personalIdImageFile,
              onPressed: () => _pickImage(ImageSource.gallery, (file) => setState(() => _personalIdImageFile = file)),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Checkbox(
                  value: _privacyPolicyAccepted,
                  onChanged: (value) {
                    setState(() { _privacyPolicyAccepted = value ?? false; });
                  },
                ),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black),
                      children: [
                        const TextSpan(text: 'أقر وأوافق على '),
                        TextSpan(
                          text: 'شروط الخدمة وسياسة الخصوصية',
                          style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                          recognizer: TapGestureRecognizer()..onTap = () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()));
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            if (_errorMessage != null) Padding(padding: const EdgeInsets.only(bottom: 15), child: Text(_errorMessage!, style: const TextStyle(color: Colors.red))),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _isLoading ? null : _submit, child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('تسجيل حساب جديد'))),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker({required String title, required IconData icon, required XFile? file, required VoidCallback onPressed}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          if (file != null)
            ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(file.path), height: 150, width: double.infinity, fit: BoxFit.cover)),
          TextButton.icon(
            icon: Icon(icon),
            label: Text(file == null ? 'رفع $title' : 'تغيير الصورة'),
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}


class DriverHubScreen extends StatefulWidget {
  final AuthResult authResult;
  const DriverHubScreen({super.key, required this.authResult});

  @override
  State<DriverHubScreen> createState() => _DriverHubScreenState();
}

class _DriverHubScreenState extends State<DriverHubScreen> {
  Future<Map<String, dynamic>>? _hubDataFuture;

  @override
  void initState() {
    super.initState();
    _loadHubData();
  }

  void _loadHubData() {
    setState(() {
      _hubDataFuture = ApiService.getDriverHubData(widget.authResult.token);
    });
  }

  // دالة لفتح واتساب لشحن الرصيد
  Future<void> _launchWhatsApp() async {
    const adminPhoneNumber = "+9647854076931"; // !! هام: استبدل هذا الرقم برقم الواتساب الخاص بك
    final message = "أرغب في شحن محفظتي. اسمي: ${widget.authResult.displayName}";
    final uri = Uri.parse("https://wa.me/$adminPhoneNumber?text=${Uri.encodeComponent(message)}");
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("لا يمكن فتح واتساب. تأكد من تثبيته على جهازك.")));
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => _loadHubData(),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _hubDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("خطأ في تحميل البيانات: ${snapshot.error}"));
            }
            if (!snapshot.hasData) {
              return const Center(child: Text("لا توجد بيانات"));
            }

            final hubData = snapshot.data!;
            final stats = hubData['stats'] as Map<String, dynamic>? ?? {};
            final walletBalance = hubData['wallet_balance'] ?? 0;
            // ▼▼▼ جلب بيانات الحوافز من الـ API ▼▼▼
            final incentives = List<Map<String, dynamic>>.from(hubData['incentives'] ?? []);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // قسم المحفظة
                  _WalletCard(balance: walletBalance, onRecharge: _launchWhatsApp),
                  const SizedBox(height: 24),

                  // قسم الإحصائيات
                  Text("أداء اليوم", style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  _StatsGrid(stats: stats),
                  const SizedBox(height: 24),

                  // ▼▼▼ القسم الجديد لعرض الحوافز ▼▼▼
                  if (incentives.isNotEmpty) ...[
                    Text("الحوافز المتاحة", style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    _IncentivesSection(incentives: incentives),
                    const SizedBox(height: 24),
                  ]
                  // ▲▲▲ نهاية القسم الجديد ▲▲▲
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _IncentivesSection extends StatelessWidget {
  final List<Map<String, dynamic>> incentives;

  const _IncentivesSection({required this.incentives});

  // --- دالة جديدة لفتح واتساب مع رسالة مخصصة ---
  Future<void> _launchWhatsAppForPrize(BuildContext context, String incentiveTitle) async {
    const adminPhoneNumber = "+9647854076931"; // !! استبدل هذا برقم الواتساب الخاص بالمسؤول
    final message = "مرحباً، لقد أكملت تحدي '$incentiveTitle' وأرغب في استلام جائزتي.";
    final uri = Uri.parse("https://wa.me/$adminPhoneNumber?text=${Uri.encodeComponent(message)}");
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if(context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("لا يمكن فتح واتساب. تأكد من تثبيته على جهازك.")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: incentives.length,
      itemBuilder: (context, index) {
        final incentive = incentives[index];
        final progress = (incentive['progress'] as num?)?.toDouble() ?? 0.0;
        final bool isCompleted = incentive['is_completed_by_user'] ?? false;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: isCompleted ? Colors.green[50] : null,
          child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(
              incentive['title'] ?? 'حافز جديد',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                incentive['description'] ?? '',
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),

              // --- عرض زر واتساب أو شريط التقدم بناءً على حالة الإكمال ---
              if (isCompleted)
          SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _launchWhatsAppForPrize(context, incentive['title'] ?? ''),
            icon: const Icon(Icons.message),
            label: const Text('تواصل لاستلام الجائزة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        )
        else
        Column(
        children: [
        ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: LinearProgressIndicator(
        value: progress,
        minHeight: 10,
        backgroundColor: Colors.grey[300],
        valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
        ),
        ),
        const SizedBox(height: 8),
        Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
        Text(
        'التقدم: ${incentive['completed_trips']}/${incentive['required_trips']} رحلة',
        style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
        'المكافأة: ${incentive['reward_amount']} د.ع',
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
        )
        ],
        )
        ],
        ),
                ],
              ),
          ),
        );
      },
    );
  }
}





// ويدجت لعرض بطاقة المحفظة
class _WalletCard extends StatelessWidget {
  final num balance;
  final VoidCallback onRecharge;

  const _WalletCard({required this.balance, required this.onRecharge});

  @override
  Widget build(BuildContext context) {
    final isNegative = balance < 0;
    return Card(
      elevation: 4,
      color: isNegative ? Colors.red[50] : Colors.green[50],
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: isNegative ? Colors.red.shade200 : Colors.green.shade200)
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text("رصيد المحفظة", style: TextStyle(color: Colors.grey[700], fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              "${NumberFormat.decimalPattern('ar').format(balance)} د.ع",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: isNegative ? Colors.red[800] : Colors.green[800],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRecharge,
              icon: const Icon(Icons.insert_comment_sharp),
              label: const Text("شحن الرصيد"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
            )
          ],
        ),
      ),
    );
  }
}


// ويدجت لعرض شبكة الإحصائيات
class _StatsGrid extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _StatsGrid({required this.stats});
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _StatItem(icon: Icons.attach_money, label: "أرباح اليوم", value: "${stats['today_earnings'] ?? 0} د.ع", color: Colors.green),
        _StatItem(icon: Icons.directions_car, label: "رحلات اليوم", value: (stats['today_rides'] ?? 0).toString(), color: Colors.blue),
        _StatItem(icon: Icons.star, label: "التقييم", value: (stats['average_rating'] ?? 0.0).toStringAsFixed(1), color: Colors.amber),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatItem({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}










// =============================================================================
// Customer Main Screen
// =============================================================================
class CustomerMainScreen extends StatefulWidget {
  final AuthResult authResult;
  final VoidCallback onLogout;
  const CustomerMainScreen({super.key, required this.authResult, required this.onLogout});
  @override
  State<CustomerMainScreen> createState() => _CustomerMainScreenState();
}

class _CustomerMainScreenState extends State<CustomerMainScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      QuickRideMapScreen(
        token: widget.authResult.token,
        authResult: widget.authResult,
        onChangeTab: _changeTab,
      ),
      TripListScreen(authResult: widget.authResult),
      PrivateRequestFormScreen(authResult: widget.authResult),
      OffersScreen(authResult: widget.authResult),
    ];
    deepLinkNotifier.addListener(_handleDeepLink);
  }

  @override
  void dispose() {
    deepLinkNotifier.removeListener(_handleDeepLink);
    super.dispose();
  }

  void _changeTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _handleDeepLink() {
    final linkData = deepLinkNotifier.value;
    if (linkData['userType'] == 'customer' && linkData['targetScreen'] == 'trips') {
      setState(() {
        _selectedIndex = 1;
      });
      deepLinkNotifier.value = {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('مرحباً، ${widget.authResult.displayName}'),
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: widget.onLogout)],
      ),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'طلب سريع'),
          BottomNavigationBarItem(icon: Icon(Icons.event_note_outlined), label: 'الرحلات'),
          BottomNavigationBarItem(icon: Icon(Icons.star_outline), label: 'طلب خصوصي'),
          BottomNavigationBarItem(icon: Icon(Icons.history_edu_outlined), label: 'عروض ورحلاتي'),
        ],
      ),
    );
  }
}

// =============================================================================
// Offers Screen for Customers
// =============================================================================
// =============================================================================
//  شاشة رحلاتي والعروض (بديل شاشة العروض القديمة)
// =============================================================================

class OffersScreen extends StatefulWidget {
  final AuthResult authResult;
  const OffersScreen({super.key, required this.authResult});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  // Future واحد لجلب البيانات من مصدرين مختلفين في نفس الوقت
  late Future<List<List<dynamic>>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  // دالة لجلب العروض وسجل الرحلات معًا
  void _loadAllData() {
    setState(() {
      _dataFuture = Future.wait([
        ApiService.getOffers(widget.authResult.token),
        ApiService.getCustomerTripHistory(widget.authResult.token),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('رحلاتي والعروض'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadAllData(),
        child: FutureBuilder<List<List<dynamic>>>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // عرض شاشة تحميل أولية
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('خطأ في تحميل البيانات: ${snapshot.error}'));
            }
            if (!snapshot.hasData) {
              return const Center(child: Text('لا توجد بيانات'));
            }

            // فصل البيانات: العروض في القائمة الأولى، والسجل في الثانية
            final offers = snapshot.data![0];
            final history = snapshot.data![1];

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // قسم العروض (أفقي)
                  if (offers.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Text('أحدث العروض', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ),
                    SizedBox(
                      height: 180, // ارتفاع محدد للشريط الأفقي
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: offers.length,
                        itemBuilder: (context, index) {
                          return _OfferCard(offer: offers[index]);
                        },
                      ),
                    ),
                  ],

                  // قسم سجل الرحلات (عمودي)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                    child: Text('سجل رحلاتي', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                  if (history.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text('لا يوجد رحلات في سجلك.')))
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        return _TripHistoryCard(trip: history[index]);
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ويدجت جديد لعرض بطاقة العرض بشكل أفقي
class _OfferCard extends StatelessWidget {
  final Map<String, dynamic> offer;
  const _OfferCard({required this.offer});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (offer['image_url'] != null && offer['image_url'].isNotEmpty)
              Image.network(
                offer['image_url'],
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(height: 100, child: Icon(Icons.local_offer)),
              )
            else
              const SizedBox(height: 100, child: Center(child: Icon(Icons.local_offer, size: 40, color: Colors.grey))),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(offer['title'] ?? 'عرض', style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(offer['description'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

// ويدجت جديد لعرض بطاقة سجل الرحلات مع التفاصيل والأزرار
class _TripHistoryCard extends StatelessWidget {
  final Map<String, dynamic> trip;
  const _TripHistoryCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final driverInfo = trip['driver_info'] as Map<String, dynamic>?;
    final driverPhone = driverInfo?['phone'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // السطر الأول: نوع الرحلة والتاريخ
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(trip['trip_type'] ?? 'رحلة', style: const TextStyle(fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.amber.withOpacity(0.2),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                Text('${trip['date']} - ${trip['start_time']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            const Divider(height: 16),
            // تفاصيل الرحلة
            Text('${trip['from_location']} ⬅️ ${trip['to_location']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if(driverInfo != null)
              Text('السائق: ${driverInfo['name'] ?? 'غير معروف'}', style: const TextStyle(fontSize: 14)),
            Text('السعر: ${trip['price'] ?? 'غير محدد'} د.ع', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            // أزرار الاتصال
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: driverPhone != null ? () => makePhoneCall(driverPhone, context) : null,
                    icon: const Icon(Icons.call_outlined, size: 18),
                    label: const Text('اتصل بالسائق'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 12, fontFamily: 'Cairo'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => makePhoneCall('07854076931', context), // رقم الدعم الفني
                    icon: const Icon(Icons.support_agent_outlined, size: 18),
                    label: const Text('اتصل بالدعم'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 12, fontFamily: 'Cairo'),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
// =============================================================================
// Driver Dashboard Screen
// =============================================================================
class DriverDashboardScreen extends StatefulWidget {
  final AuthResult authResult;
  const DriverDashboardScreen({super.key, required this.authResult});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  Future<Map<String, dynamic>>? _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }










  void _loadDashboard() {
    setState(() {
      _dashboardFuture = ApiService.getDriverDashboard(widget.authResult.token);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => _loadDashboard(),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _dashboardFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('خطأ في تحميل البيانات: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!['success'] != true) {
              return const Center(child: Text('لا توجد بيانات لعرضها.'));
            }

            final data = snapshot.data!['data'] ?? {};

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildStatCard(
                    context,
                    icon: Icons.attach_money,
                    title: 'الأرباح الكلية',
                    value: '${data['total_earnings'] ?? 0} د.ع',
                    color: Colors.green,
                  ),


                  const SizedBox(height: 16),
                  _buildStatCard(
                    context,
                    icon: Icons.star,
                    title: 'متوسط التقييم',
                    value: (data['average_rating'] ?? 0.0).toStringAsFixed(1),
                    color: Colors.amber,
                  ),
                  const SizedBox(height: 16),
                  _buildStatCard(
                    context,
                    icon: Icons.directions_car,
                    title: 'الرحلات المكتملة',
                    value: (data['completed_rides'] ?? 0).toString(),
                    color: Colors.blue,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, {required IconData icon, required String title, required String value, required Color color}) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: color, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Driver Screens
// =============================================================================
class DriverPendingScreen extends StatefulWidget {
  final VoidCallback onLogout;
  final Function(AuthResult?) onCheckStatus;
  final String phone;
  const DriverPendingScreen({super.key, required this.onLogout, required this.phone, required this.onCheckStatus});
  @override
  State<DriverPendingScreen> createState() => _DriverPendingScreenState();
}

class _DriverPendingScreenState extends State<DriverPendingScreen> {
  bool _isChecking = false;
  Future<void> _checkStatus() async {
    setState(() => _isChecking = true);
    try {
      final response = await http.post(Uri.parse('${ApiService.baseUrl}/taxi-auth/v1/login'), headers: {'Content-Type': 'application/json'}, body: json.encode({'phone_number': widget.phone}));
      final data = json.decode(response.body);
      if (mounted) {
        if (response.statusCode == 200 && data['success'] == true) {
          final authResult = AuthResult.fromJson(data);
          await ApiService.storeAuthData(authResult);
          if (authResult.driverStatus == 'approved') {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت الموافقة على حسابك!'), backgroundColor: Colors.green));
            widget.onCheckStatus(authResult);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الحساب لا يزال قيد المراجعة.'), backgroundColor: Colors.orange));
          }
        } else {
          throw Exception(data['message'] ?? 'فشل التحقق');
        }
      }
    } on SocketException {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى التحقق من اتصالك بالإنترنت'), backgroundColor: Colors.orange));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hourglass_top, size: 80, color: Colors.amber),
              const SizedBox(height: 20),
              Text('حسابك قيد المراجعة', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 10),
              Text('سيتم مراجعة طلبك من قبل الإدارة. يمكنك التحقق من حالة الحساب بالضغط على الزر أدناه.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 30),
              _isChecking ? const CircularProgressIndicator() : ElevatedButton(onPressed: _checkStatus, child: const Text('التحقق من حالة الحساب')),
              const SizedBox(height: 20),
              TextButton(onPressed: widget.onLogout, child: const Text('تسجيل الخروج')),
            ],
          ),
        ),
      ),
    );
  }
}

class DriverMainScreen extends StatefulWidget {
  final AuthResult authResult;
  final VoidCallback onLogout;
  const DriverMainScreen({super.key, required this.authResult, required this.onLogout});
  @override
  State<DriverMainScreen> createState() => _DriverMainScreenState();
}
// ============== ✂️✂️✂️  ابدأ النسخ من هنا ✂️✂️✂️ ==============

class _DriverMainScreenState extends State<DriverMainScreen> {
  int _selectedIndex = 0;
  bool _isDriverActive = true;
  StreamSubscription<geolocator.Position>? _positionStream;
  // State management for current jobs
  Map<String, dynamic>? _currentQuickRide;
  Map<String, dynamic>? _currentDelivery; // <-- تأكد من وجود هذا المتغير


  Map<String, dynamic>? _liveStats;
  Timer? _statsTimer;


  void _refreshAllLists() {
    // هذه الدالة ستعيد تحميل الطلبات في الشاشات الأخرى عند الحاجة
    // يمكنك تعديلها لتكون أكثر تحديداً إذا أردت
    setState(() {
      // إعادة تهيئة الـ Futures سيؤدي إلى إعادة تحميل البيانات
      // (هذا يعتمد على كيفية بنائك لشاشات عرض الطلبات)
    });
  }


  void _onRideAccepted(Map<String, dynamic> ride) {
    setState(() {
      _currentQuickRide = ride;
    });
  }


  // --- NEW: Handlers for delivery jobs ---
  void _onDeliveryAccepted(Map<String, dynamic> delivery) {
    setState(() {
      _currentDelivery = delivery;
      _selectedIndex = 1; // Switch to delivery tab
    });
  }
  void _onDeliveryFinished() => setState(() => _currentDelivery = null);
  // ---

  void _onRideFinished() {
    setState(() {
      _currentQuickRide = null;
    });
  }

  // --- الدالة التي تستجيب للإشعار وتستلم بيانات الرحلة مباشرة ---
  void _handleAcceptedRide() {
    final rideData = acceptedRideNotifier.value;
    if (rideData != null) {
      if (mounted) {
        // لا حاجة لطلب API جديد، البيانات موجودة بالفعل
        _onRideAccepted(rideData);
      }
      // إعادة تعيين المتغير لمنع التنفيذ مرة أخرى
      acceptedRideNotifier.value = null;
    }
  }






  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    deepLinkNotifier.addListener(_handleDeepLink);
    // *** ربط المستمع الجديد ***
    acceptedRideNotifier.addListener(_handleAcceptedRide);
    _fetchLiveStats();
    _statsTimer = Timer.periodic(const Duration(seconds: 45), (timer) {
      if (mounted) {
        _fetchLiveStats();
      }
    });
    _toggleActiveStatus(_isDriverActive);
  }

  @override
  void dispose() {
    deepLinkNotifier.removeListener(_handleDeepLink);
    // *** إزالة المستمع الجديد ***
    acceptedRideNotifier.removeListener(_handleAcceptedRide);
    _positionStream?.cancel();
    _statsTimer?.cancel();
    if (_isDriverActive) ApiService.setDriverActiveStatus(widget.authResult.token, false);
    super.dispose();
  }

  Future<void> _fetchLiveStats() async {
    try {
      final stats = await ApiService.getDriverLiveStats(widget.authResult.token);
      if (mounted) {
        setState(() {
          _liveStats = stats;
        });
      }
    } catch (e) {
      debugPrint("Failed to fetch live stats: $e");
    }
  }

  void _handleDeepLink() {
    final linkData = deepLinkNotifier.value;
    // التحقق من أن الإشعار موجه للسائق
    if (linkData['userType'] == 'driver') {
      // التحقق من الشاشة المستهدفة
      if (linkData['targetScreen'] == 'private_requests') {
        _changeTab(1); // انتقل إلى تبويب الطلبات الخاصة
      } else if (linkData['targetScreen'] == 'quick_rides') {
        _changeTab(0); // انتقل إلى تبويب الطلبات السريعة
      }
      // إعادة تعيين بيانات الإشعار بعد التعامل معها
      deepLinkNotifier.value = {};
    }
  }

  void _changeTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _checkLocationPermission() async {
    if (mounted) await PermissionService.handleLocationPermission(context);
  }

  void _toggleActiveStatus(bool isActive) {
    setState(() => _isDriverActive = isActive);
    ApiService.setDriverActiveStatus(widget.authResult.token, isActive);

    if (isActive) {
      // --- (التعديل هنا): طلب أعلى دقة ممكنة ---
      const locationSettings = geolocator.LocationSettings(
        accuracy: geolocator.LocationAccuracy.bestForNavigation,
        distanceFilter: 5, // تحديث كل 10 أمتار
      );
      _positionStream = geolocator.Geolocator.getPositionStream(locationSettings: locationSettings).listen((geolocator.Position position) {
        ApiService.updateDriverLocation(widget.authResult.token, LatLng(position.latitude, position.longitude));
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      // Tab 0: Quick Rides
      _currentQuickRide == null
          ? DriverAvailableRidesScreen(authResult: widget.authResult, onRideAccepted: _onRideAccepted)
          : DriverCurrentRideScreen(initialRide: _currentQuickRide!, authResult: widget.authResult, onRideFinished: _onRideFinished),

      // Tab 1: Deliveries (NEW)
      _currentDelivery == null
          ? DriverAvailableDeliveriesScreen(authResult: widget.authResult, onDeliveryAccepted: _onDeliveryAccepted)
          : DriverCurrentDeliveryScreen(
        initialDelivery: _currentDelivery!,
        authResult: widget.authResult,
        onDeliveryFinished: _onDeliveryFinished,
        onDataChanged: _refreshAllLists, //  <-- قم بإضافة هذا السطر الناقص هنا
      ),
      DriverPrivateRequestsScreen(authResult: widget.authResult),
      DriverMyTripsScreen(authResult: widget.authResult, navigateToCreate: () => setState(() => _selectedIndex = 3)),
      DriverCreateTripScreen(authResult: widget.authResult),
      DriverHubScreen(authResult: widget.authResult),

    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('واجهة السائق'),
        actions: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0), child: Row(children: [const Text("استقبال الطلبات", style: TextStyle(fontSize: 12)), Switch(value: _isDriverActive, onChanged: _toggleActiveStatus, activeColor: Colors.green)])),
          IconButton(icon: const Icon(Icons.logout), onPressed: widget.onLogout)
        ],
        bottom: _selectedIndex == 0
            ? PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: DriverStatsBar(stats: _liveStats),
        )
            : null,
      ),
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _changeTab,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list_alt_outlined), label: 'الطلبات'),
          BottomNavigationBarItem(icon: Icon(Icons.star_border_purple500_outlined), label: 'طلبات الخصوصي'),
          BottomNavigationBarItem(icon: Icon(Icons.delivery_dining), label: 'توصيل'), // <-- NEW TAB

          BottomNavigationBarItem(icon: Icon(Icons.directions_car_outlined), label: 'رحلاتي'),
          BottomNavigationBarItem(icon: Icon(Icons.add_road_outlined), label: 'إنشاء رحلة'),

          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'جوائز وهدايا'),
          BottomNavigationBarItem(icon: Icon(Icons.school_outlined), label: 'خطوط الطلاب'), // <-- أضف هذا التبويب الجديد

        ],
      ),
    );
  }
}
// =============================================================================
// NEW SCREEN: DriverAvailableDeliveriesScreen
// =============================================================================
class DriverAvailableDeliveriesScreen extends StatefulWidget {
  final AuthResult authResult;
  final Function(Map<String, dynamic>) onDeliveryAccepted;
  const DriverAvailableDeliveriesScreen({super.key, required this.authResult, required this.onDeliveryAccepted});

  @override
  State<DriverAvailableDeliveriesScreen> createState() => _DriverAvailableDeliveriesScreenState();
}

class _DriverAvailableDeliveriesScreenState extends State<DriverAvailableDeliveriesScreen> {
  Future<List<dynamic>>? _deliveriesFuture;
  Timer? _refreshTimer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDeliveries();
    _refreshTimer = Timer.periodic(const Duration(seconds: 25), (timer) {
      if (mounted) _loadDeliveries();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDeliveries() async {
    if (!mounted) return;
    setState(() {
      _deliveriesFuture = ApiService.getAvailableDeliveries(widget.authResult.token);
    });
  }

  Future<void> _acceptDelivery(String orderId) async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.acceptDelivery(widget.authResult.token, orderId);
      final data = json.decode(response.body);
      if (mounted && response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message']), backgroundColor: Colors.green));
        widget.onDeliveryAccepted(data['delivery_order']);
      } else if (mounted) {
        throw Exception(data['message'] ?? 'فشل قبول الطلب');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red));
        _loadDeliveries();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadDeliveries,
            child: FutureBuilder<List<dynamic>>(
              future: _deliveriesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !_isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("خطأ: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const EmptyStateWidget(
                    svgAsset: '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8zm-1-13h2v6h-2zm0 8h2v2h-2z"/></svg>''',
                    message: 'لا توجد طلبات توصيل متاحة حالياً في منطقتك.',
                  );
                }
                final orders = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // عرض اسم الصيدلية والمنطقة
                            Text("من: ${order['pickup_location_name']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text("إلى: ${order['destination_address']}", style: const TextStyle(fontSize: 16)),
                            const Divider(height: 16),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // عرض السعر
                                Chip(label: Text('${order['delivery_fee']} د.ع', style: const TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.green.withOpacity(0.1)),
                                ElevatedButton(
                                  onPressed: () => _acceptDelivery(order['id'].toString()),
                                  child: const Text('قبول'),
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
          if (_isLoading) Container(color: Colors.black.withOpacity(0.2), child: const Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }
}

// =============================================================================
// NEW SCREEN: DriverCurrentDeliveryScreen
// =============================================================================
class DriverCurrentDeliveryScreen extends StatefulWidget {
  final Map<String, dynamic> initialDelivery;
  final AuthResult authResult;
  final VoidCallback onDeliveryFinished;
  final VoidCallback onDataChanged; //  <-- أضف هذا السطر


  const DriverCurrentDeliveryScreen({
    super.key,
    required this.initialDelivery,
    required this.authResult,
    required this.onDeliveryFinished,
    required this.onDataChanged, //  <-- أضف هذا السطر

  });

  @override
  State<DriverCurrentDeliveryScreen> createState() => _DriverCurrentDeliveryScreenState();
}

class _DriverCurrentDeliveryScreenState extends State<DriverCurrentDeliveryScreen> {
  late Map<String, dynamic> _currentDelivery;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentDelivery = widget.initialDelivery;
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.updateDeliveryStatus(
        widget.authResult.token,
        _currentDelivery['id'].toString(),
        newStatus,
      );
      final data = json.decode(response.body);
      if (mounted && response.statusCode == 200 && data['success'] == true) {
        if (newStatus == 'delivered' || newStatus == 'cancelled') {
          widget.onDeliveryFinished();
        } else {
          setState(() => _currentDelivery = data['delivery_order']);
        }
      } else if (mounted) {
        throw Exception(data['message'] ?? 'فشل تحديث الحالة');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

// داخل class _DriverCurrentDeliveryScreenState

// استبدل الدالة القديمة بهذه الدالة الجديدة بالكامل
  Future<void> _showPickupCodeDialog() async {
    final codeController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final String? enteredCode = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تأكيد الاستلام'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: codeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'أدخل رمز الاستلام (4 أرقام)'),
              validator: (v) => v == null || v.isEmpty ? 'الرمز مطلوب' : null,
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop(codeController.text);
                }
              },
              child: const Text('تأكيد'),
            ),
          ],
        );
      },
    );

    if (enteredCode == null) return; // أغلق المستخدم النافذة

    setState(() => _isLoading = true);
    try {
      // استدعاء دالة API الجديدة
      final response = await ApiService.confirmPickupByCode(
          widget.authResult.token,
          _currentDelivery['id'].toString(),
          enteredCode
      );

      final data = json.decode(response.body);
      if (mounted) {
        if (response.statusCode == 200 && data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message']), backgroundColor: Colors.green));
          setState(() => _currentDelivery['order_status'] = 'picked_up');
          widget.onDataChanged(); // تحديث القوائم الأخرى
        } else {
          throw Exception(data['message'] ?? 'فشل تأكيد الاستلام');
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  Widget _buildActionButton() {
    final status = _currentDelivery['order_status'];
    switch (status) {
      case 'accepted':
        return SizedBox(width: double.infinity, child: ElevatedButton.icon(icon: const Icon(Icons.storefront), label: const Text('وصلت إلى المصدر'), onPressed: _isLoading ? null : () => _updateStatus('at_store'), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue)));
      case 'at_store':
      // ✨ التعديل هنا فقط ✨
        return SizedBox(width: double.infinity, child: ElevatedButton.icon(icon: const Icon(Icons.pin), label: const Text('أدخل رمز الاستلام'), onPressed: _isLoading ? null : _showPickupCodeDialog, style: ElevatedButton.styleFrom(backgroundColor: Colors.orange)));
      case 'picked_up':
        return SizedBox(width: double.infinity, child: ElevatedButton.icon(icon: const Icon(Icons.check_circle), label: const Text('إنهاء التوصيل'), onPressed: _isLoading ? null : () => _updateStatus('delivered'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green)));
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _currentDelivery['order_status'] ?? 'pending';

    return Scaffold(
      appBar: AppBar(title: const Text('مهمة التوصيل الحالية')),
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("حالة الطلب: $status", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Divider(height: 20),
                      _buildInfoRow(Icons.store, "استلام من:", _currentDelivery['pickup_location_name']),
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.description, "الوصف:", _currentDelivery['order_description']),
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.payments, "أجرة التوصيل:", "${_currentDelivery['delivery_fee']} د.ع"),
                      const SizedBox(height: 24),
                      _buildActionButton(),
                      const SizedBox(height: 12),
                      if (status != 'delivered' && status != 'cancelled')
                        TextButton(onPressed: _isLoading ? null : () => _updateStatus('cancelled'), child: const Text('إلغاء الطلب', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading) Container(color: Colors.black.withOpacity(0.2), child: const Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: Colors.grey[600], size: 20),
      const SizedBox(width: 8),
      Text(label, style: TextStyle(color: Colors.grey[700])),
      const SizedBox(width: 4),
      Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold))),
    ]);
  }
}

// =============================================================================
// NEW SCREEN: QR Code Scanner
// =============================================================================
class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isScanComplete = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('امسح رمز الاستلام')),
      body: MobileScanner(
        controller: _controller,
        onDetect: (capture) {
          if(!_isScanComplete) {
            final String? code = capture.barcodes.first.rawValue;
            if (code != null) {
              setState(() => _isScanComplete = true);
              Navigator.of(context).pop(code);
            }
          }
        },
      ),
    );
  }
}



// =============================================================================
// Modern Info Dialog & Driver Stats Bar
// =============================================================================
class ModernInfoDialog extends StatelessWidget {
  const ModernInfoDialog({super.key});
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      elevation: 5,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20.0), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))]),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.two_wheeler, color: Colors.amber, size: 50),
            const SizedBox(height: 16),
            Text("تنبيهات قسم الطلبات", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const Divider(height: 30),
            _buildInfoRow(context, Icons.location_on_outlined, "هذا القسم مخصص للطلبات القريبة (ضمن 1 كم)."),
            const SizedBox(height: 15),
            _buildInfoRow(context, Icons.toggle_on, "يجب تفعيل 'استقبال الطلبات' من الأعلى لتظهر لك الرحلات."),
            const SizedBox(height: 15),
            _buildInfoRow(context, Icons.info_outline, "القسم مصمم بشكل أساسي للطلبات السريعة داخل المدينة."),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text("حسناً، فهمت")),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: Theme.of(context).primaryColor, size: 22), const SizedBox(width: 12), Expanded(child: Text(text, style: const TextStyle(fontSize: 15, height: 1.5)))]);
  }
}

class DriverStatsBar extends StatelessWidget {
  final Map<String, dynamic>? stats;
  const DriverStatsBar({super.key, this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).appBarTheme.backgroundColor, // Match AppBar color
      child: stats == null
          ? const Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)))
          : Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.attach_money, "أرباح اليوم", "${stats?['today_earnings'] ?? 0} د.ع"),
          _buildStatItem(Icons.star_outline, "تقييمك", (stats?['average_rating'] ?? 0.0).toStringAsFixed(1)),
          _buildStatItem(Icons.directions_car_outlined, "رحلات اليوم", (stats?['today_rides'] ?? 0).toString()),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.amber, size: 24),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 10)),
        Text(value, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}

class DriverAvailableRidesScreen extends StatefulWidget {
  final AuthResult authResult;
  final Function(Map<String, dynamic>) onRideAccepted;
  const DriverAvailableRidesScreen({super.key, required this.authResult, required this.onRideAccepted});
  @override
  State<DriverAvailableRidesScreen> createState() => _DriverAvailableRidesScreenState();
}

class _DriverAvailableRidesScreenState extends State<DriverAvailableRidesScreen> {
  List<dynamic>? _availableRides;
  bool _isLoading = true;
  Timer? _ridesTimer;
  final MapController _mapController = MapController();
  LatLng? _driverLocation;
  StreamSubscription<geolocator.Position>? _locationStream;
  PageController? _pageController;
  int _currentPageIndex = 0;
  String _distanceToPickup = "...";

  // --- (جديد): لتتبع الطلب الذي تم إرسال عرض له ---
  String? _sentOfferRideId;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    _setupInitialLocationAndFetchRides();
    _ridesTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      if (!mounted) return;
      _fetchAvailableRides();
    });
  }

  @override
  void dispose() {
    _ridesTimer?.cancel();
    _locationStream?.cancel();
    _pageController?.dispose();
    super.dispose();
  }

  Future<void> _setupInitialLocationAndFetchRides() async {
    final hasPermission = await PermissionService.handleLocationPermission(context);
    if (!hasPermission || !mounted) return;
    try {
      geolocator.Position position = await geolocator.Geolocator.getCurrentPosition(desiredAccuracy: geolocator.LocationAccuracy.high);
      if (mounted) {
        final initialLocation = LatLng(position.latitude, position.longitude);
        setState(() => _driverLocation = initialLocation);
        _mapController.move(initialLocation, 14.0);
        await _fetchAvailableRides();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل تحديد موقعك الحالي.')));
    }
    _locationStream = geolocator.Geolocator.getPositionStream().listen((geolocator.Position position) {
      if (mounted) {
        setState(() => _driverLocation = LatLng(position.latitude, position.longitude));
        _updateDistanceInfo(_currentPageIndex);
      }
    });
  }

  void _updateDistanceInfo(int pageIndex) {
    if (_driverLocation == null || _availableRides == null || _availableRides!.isEmpty || pageIndex >= _availableRides!.length) {
      setState(() => _distanceToPickup = "...");
      return;
    }
    final ride = _availableRides![pageIndex];
    final rideLat = double.parse(ride['pickup']['lat']);
    final rideLng = double.parse(ride['pickup']['lng']);
    final distanceInMeters = geolocator.Geolocator.distanceBetween(_driverLocation!.latitude, _driverLocation!.longitude, rideLat, rideLng);
    setState(() {
      _distanceToPickup = distanceInMeters < 1000 ? "${distanceInMeters.round()} متر" : "${(distanceInMeters / 1000).toStringAsFixed(1)} كم";
      _currentPageIndex = pageIndex;
    });
  }

  Future<void> _fetchAvailableRides() async {
    if (!mounted) return;
    try {
      final response = await http.get(Uri.parse('${ApiService.baseUrl}/taxi/v2/driver/available-rides'), headers: {'Authorization': 'Bearer ${widget.authResult.token}'});
      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        setState(() {
          _availableRides = data['rides'];
          _isLoading = false;
          // إذا تم قبول العرض الذي أرسلته، قم بإلغاء حالة الانتظار
          if (_sentOfferRideId != null && (_availableRides?.every((ride) => ride['id'].toString() != _sentOfferRideId) ?? true)) {
            _sentOfferRideId = null;
          }
        });
        if (_availableRides != null && _availableRides!.isNotEmpty) {
          _updateDistanceInfo(_currentPageIndex);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Failed to fetch available rides: $e");
    }
  }

  Future<void> _acceptRide(String rideId) async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.v2AcceptRide(widget.authResult.token, rideId);
      final data = json.decode(response.body);
      if (mounted && response.statusCode == 200 && data['success'] == true) {
        widget.onRideAccepted(data['ride']);
      } else if (mounted) {
        throw Exception(data['message'] ?? 'فشل قبول الطلب');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red));
        _fetchAvailableRides();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showOfferSentDialog() {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 60),
          title: const Text('تم إرسال عرضك', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('سيتم إعلامك فور موافقة الزبون.', textAlign: TextAlign.center),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            ElevatedButton(
              child: const Text('حسناً'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showNegotiationDialog(Map<String, dynamic> ride) async {
    final priceController = TextEditingController();
    final initialPrice = double.tryParse(ride['customer_offer_price'].toString()) ?? 0.0;
    priceController.text = initialPrice.toStringAsFixed(0);

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          void updatePrice(double amount) {
            double currentPrice = double.tryParse(priceController.text) ?? initialPrice;
            setDialogState(() => priceController.text = (currentPrice + amount).toStringAsFixed(0));
          }
          return AlertDialog(
            title: const Text('تفاوض على السعر'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("عرض العميل: $initialPrice د.ع"),
                const SizedBox(height: 16),
                TextField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'سعرك الجديد (د.ع)')),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [ElevatedButton(onPressed: () => updatePrice(500), child: const Text('+500')), ElevatedButton(onPressed: () => updatePrice(1000), child: const Text('+1000'))])
              ],
            ),
            actions: <Widget>[
              TextButton(child: const Text('إلغاء'), onPressed: () => Navigator.of(context).pop()),
              ElevatedButton(
                child: const Text('إرسال العرض'),
                onPressed: () async {
                  if (priceController.text.isEmpty) return;
                  final rideId = ride['id'].toString();
                  final price = double.parse(priceController.text);
                  Navigator.of(context).pop();
                  setState(() => _isLoading = true);
                  try {
                    final response = await ApiService.driverCounterOffer(widget.authResult.token, rideId, price);
                    final data = json.decode(response.body);
                    if (mounted && response.statusCode == 200 && data['success'] == true) {
                      _showOfferSentDialog();
                      setState(() {
                        // --- (جديد): تحديث حالة الانتظار ---
                        _sentOfferRideId = rideId;
                      });
                    } else if (mounted) {
                      throw Exception(data['message'] ?? 'فشل إرسال العرض');
                    }
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red));
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
              ),
            ],
          );
        });
      },
    );
  }

  List<Marker> _buildMarkers() {
    List<Marker> markers = [];
    if (_driverLocation != null) {
      markers.add(Marker(point: _driverLocation!, width: 40, height: 40, child: const RotatingVehicleIcon(vehicleType: 'Car', bearing: 0)));
    }
    if (_availableRides != null && _availableRides!.isNotEmpty && _currentPageIndex < _availableRides!.length) {
      final ride = _availableRides![_currentPageIndex];
      final lat = double.parse(ride['pickup']['lat']);
      final lng = double.parse(ride['pickup']['lng']);
      markers.add(Marker(point: LatLng(lat, lng), width: 40, height: 40, child: const Icon(Icons.pin_drop, color: Colors.red, size: 40)));
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: _driverLocation ?? const LatLng(32.4741, 45.8336), initialZoom: 14.0),
            children: [TileLayer(urlTemplate: 'https://{s}.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png', subdomains: const ['a', 'b', 'c']), MarkerLayer(markers: _buildMarkers())],
          ),
          if (_availableRides != null && _availableRides!.isNotEmpty) Positioned(top: 40, left: 0, right: 0, child: Center(child: TopRideInfoBar(distance: _distanceToPickup))),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_availableRides == null || _availableRides!.isEmpty)
            const EmptyStateWidget(svgAsset: '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-coffee"><path d="M18 8h1a4 4 0 0 1 0 8h-1"></path><path d="M2 8h16v9a4 4 0 0 1-4 4H6a4 4 0 0 1-4-4V8z"></path><line x1="6" y1="1" x2="6" y2="4"></line><line x1="10" y1="1" x2="10" y2="4"></line><line x1="14" y1="1" x2="14" y2="4"></line></svg>''', message: 'لا توجد طلبات متاحة حالياً.')
          else
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              height: 220,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _availableRides!.length,
                onPageChanged: (index) {
                  final ride = _availableRides![index];
                  final rideLocation = LatLng(double.parse(ride['pickup']['lat']), double.parse(ride['pickup']['lng']));
                  _mapController.move(rideLocation, 15.0);
                  _updateDistanceInfo(index);
                },
                itemBuilder: (context, index) {
                  final ride = _availableRides![index];
                  return RideInfoCard(
                    ride: ride,
                    // --- (جديد): تمرير حالة الانتظار للبطاقة ---
                    isWaitingForApproval: _sentOfferRideId == ride['id'].toString(),
                    onAccept: () => _acceptRide(ride['id'].toString()),
                    onNegotiate: () => _showNegotiationDialog(ride),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}





// --- ويدجت جديد: شريط المعلومات العلوي ---
class TopRideInfoBar extends StatelessWidget {
  final String distance;
  const TopRideInfoBar({super.key, required this.distance});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        "المسافة حتى نقطة الأنطلاق: $distance",
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class RideInfoCard extends StatelessWidget {
  final Map<String, dynamic> ride;
  final bool isWaitingForApproval;
  final VoidCallback onAccept;
  final VoidCallback onNegotiate;

  const RideInfoCard({super.key, required this.ride, required this.onAccept, required this.onNegotiate, required this.isWaitingForApproval});

  @override
  Widget build(BuildContext context) {
    final destinationName = ride['destination']?['name'] ?? 'وجهة غير محددة';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Chip(label: Text("${ride['customer_offer_price'] ?? 0} د.ع", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)), backgroundColor: Theme.of(context).primaryColor)),
              const Divider(height: 20),
              _buildInfoRow(Icons.my_location, "نقطة الانطلاق:", "محدد على الخريطة"),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.flag, "نقطة الوصول:", destinationName),
              const Spacer(),
              // --- (التعديل هنا): عرض حالة الانتظار أو الأزرار ---
              if (isWaitingForApproval)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 12),
                      Text("في انتظار موافقة الزبون...", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    ],
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(child: ElevatedButton(onPressed: onNegotiate, style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey), child: const Text('تفاوض', style: TextStyle(color: Colors.white)))),
                    const SizedBox(width: 12),
                    Expanded(child: ElevatedButton(onPressed: onAccept, child: const Text('قبول الرحلة'))),
                  ],
                )
            ],
          ),
        ),
      ),
    );
  }




  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(children: [Icon(icon, color: Colors.grey, size: 20), const SizedBox(width: 8), Text(label, style: const TextStyle(color: Colors.grey)), const SizedBox(width: 4), Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis))]);
  }
}



// =============================================================================
// DriverCurrentRideScreen (with Auto Route Drawing)
// =============================================================================
class DriverCurrentRideScreen extends StatefulWidget {
  final Map<String, dynamic> initialRide;
  final AuthResult authResult;
  final VoidCallback onRideFinished;
  const DriverCurrentRideScreen({super.key, required this.initialRide, required this.authResult, required this.onRideFinished});
  @override
  State<DriverCurrentRideScreen> createState() => _DriverCurrentRideScreenState();
}


// ============== ✂️✂️✂️  ابدأ النسخ من هنا ✂️✂️✂️ ==============
class _DriverCurrentRideScreenState extends State<DriverCurrentRideScreen> {
  late Map<String, dynamic> _currentRide;
  bool _isLoading = false;
  final MapController _mapController = MapController();
  StreamSubscription<geolocator.Position>? _positionStream;
  LatLng? _driverLocation;
  List<LatLng> _routePoints = [];
  double _distanceToPickup = 0.0;
  double _driverBearing = 0.0;
  double _previousDriverBearing = 0.0;

  @override
  void initState() {
    super.initState();
    _currentRide = widget.initialRide;
    // استدعاء الدالة مباشرة بعد اكتمال بناء الويدجت لضمان الاستقرار
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeRide();
      }
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  // --- دالة معدلة وأكثر قوة لتهيئة الرحلة ورسم المسار تلقائيًا ---
  Future<void> _initializeRide() async {
    // التأكد من أن الويدجت لا يزال موجودًا قبل أي عملية
    if (!mounted) return;

    setState(() => _isLoading = true);

    final pickupPoint = LatLng(
      double.parse(_currentRide['pickup']['lat']),
      double.parse(_currentRide['pickup']['lng']),
    );

    try {
      // 1. طلب صلاحيات الموقع أولاً
      final hasPermission = await PermissionService.handleLocationPermission(context);
      if (!mounted || !hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('إذن الموقع مطلوب لبدء الرحلة.')));
        setState(() => _isLoading = false);
        return;
      }

      // 2. جلب موقع السائق الحالي بدقة عالية
      geolocator.Position currentPosition = await geolocator.Geolocator.getCurrentPosition(
          desiredAccuracy: geolocator.LocationAccuracy.high
      );

      if (!mounted) return;

      final driverNowLocation = LatLng(currentPosition.latitude, currentPosition.longitude);

      setState(() {
        _driverLocation = driverNowLocation;
      });

      // 3. تحريك الكاميرا إلى موقع السائق
      _mapController.move(driverNowLocation, 15);

      // 4. رسم المسار تلقائيًا من موقع السائق إلى موقع الزبون
      await _getRoute(driverNowLocation, pickupPoint);

      // 5. بدء التتبع المباشر لموقع السائق
      _startDriverLocationTracking();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل تهيئة الرحلة: ${e.toString()}'))
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _startDriverLocationTracking() {
    _positionStream = geolocator.Geolocator.getPositionStream(locationSettings: const geolocator.LocationSettings(accuracy: geolocator.LocationAccuracy.bestForNavigation, distanceFilter: 5)).listen((geolocator.Position position) {
      if (mounted) {
        final newLocation = LatLng(position.latitude, position.longitude);
        double newBearing = _driverBearing;
        if (_driverLocation != null && (newLocation.latitude != _driverLocation!.latitude || newLocation.longitude != _driverLocation!.longitude)) {
          newBearing = calculateBearing(_driverLocation!, newLocation);
        }
        setState(() {
          _previousDriverBearing = _driverBearing;
          _driverLocation = newLocation;
          _driverBearing = newBearing;
          _distanceToPickup = geolocator.Geolocator.distanceBetween(newLocation.latitude, newLocation.longitude, double.parse(_currentRide['pickup']['lat']), double.parse(_currentRide['pickup']['lng']));
        });
      }
    });
  }

  Future<void> _getRoute(LatLng start, LatLng end) async {
    const String orsApiKey = 'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjVhMDU5ODAxNDA5Y2E5MzIyNDQwOTYxMWQxY2ZhYmQ5NGQ3YTA5ZmI1ZjQ5ZWRlNjcxNGRlMTUzIiwiaCI6Im11cm11cjY0In0=';
    if (orsApiKey.length < 50) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("الرجاء إضافة مفتاح API صحيح لرسم المسار"), backgroundColor: Colors.red));
      return;
    }
    final url = 'https://api.openrouteservice.org/v2/directions/driving-car?api_key=$orsApiKey&start=${start.longitude},${start.latitude}&end=${end.longitude},${end.latitude}';
    try {
      final response = await http.get(Uri.parse(url));
      if (mounted) {
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final coordinates = data['features'][0]['geometry']['coordinates'] as List;
          setState(() => _routePoints = coordinates.map((c) => LatLng(c[1], c[0])).toList());
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("فشل رسم المسار: ${json.decode(response.body)['error']?['message'] ?? 'خطأ من الخادم'}"), backgroundColor: Colors.red));
        }
      }
    } on SocketException {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("فشل رسم المسار: تحقق من اتصالك بالإنترنت"), backgroundColor: Colors.orange));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("فشل رسم المسار: ${e.toString().replaceAll("Exception: ", "")}"), backgroundColor: Colors.red));
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(Uri.parse('${ApiService.baseUrl}/taxi/v2/driver/update-ride-status'), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.authResult.token}'}, body: json.encode({'ride_id': _currentRide['id'], 'status': newStatus}));
      final data = json.decode(response.body);
      if (mounted) {
        if (response.statusCode == 200 && data['success'] == true) {
          if (newStatus == 'completed' || newStatus == 'cancelled') {
            widget.onRideFinished();
          } else {
            setState(() => _currentRide = data['ride']);
            if (newStatus == 'ongoing' && _driverLocation != null && _currentRide['destination']?['lat'] != null) {
              final destination = LatLng(double.parse(_currentRide['destination']['lat']), double.parse(_currentRide['destination']['lng']));
              _getRoute(_driverLocation!, destination);
            }
          }
        } else {
          throw Exception(data['message'] ?? 'فشل تحديث الحالة');
        }
      }
    } on SocketException {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى التحقق من اتصالك بالإنترنت'), backgroundColor: Colors.orange));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildActionButton() {
    String status = _currentRide['status'];
    if (status == 'accepted') return SizedBox(width: double.infinity, child: ElevatedButton.icon(icon: const Icon(Icons.hail), label: const Text('وصلت إلى موقع العميل'), onPressed: _isLoading ? null : () => _updateStatus('arrived_pickup'), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white)));
    if (status == 'arrived_pickup') return SizedBox(width: double.infinity, child: ElevatedButton.icon(icon: const Icon(Icons.navigation), label: const Text('بدء الرحلة إلى الوجهة'), onPressed: _isLoading ? null : () => _updateStatus('ongoing'), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white)));
    if (status == 'ongoing') return SizedBox(width: double.infinity, child: ElevatedButton.icon(icon: const Icon(Icons.check_circle), label: const Text('إنهاء الرحلة'), onPressed: _isLoading ? null : () => _updateStatus('completed'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white)));
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    LatLng pickupPoint = LatLng(double.parse(_currentRide['pickup']['lat']), double.parse(_currentRide['pickup']['lng']));
    LatLng? destinationPoint = _currentRide['destination']?['lat'] != null ? LatLng(double.parse(_currentRide['destination']['lat']), double.parse(_currentRide['destination']['lng'])) : null;
    String status = _currentRide['status'];
    final customerPhone = _currentRide['customer_phone'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الرحلة الحالية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.call, color: Colors.green),
            onPressed: () => makePhoneCall(customerPhone, context),
            tooltip: 'الاتصال بالزبون',
          ),
          TextButton.icon(
            icon: ChatIconWithBadge(
              chatId: 'ride_${_currentRide['id']}',
              currentUserId: widget.authResult.userId,
              onPressed: () {},
            ),
            label: const Text("محادثة"),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ChatScreen(
                  chatId: 'ride_${_currentRide['id']}',
                  chatName: 'محادثة مع زبون',
                  authResult: widget.authResult,
                  participants: {
                    'customer': _currentRide['author']?.toString(),
                    'driver': widget.authResult.userId,
                  },
                ),
              ));
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: pickupPoint, initialZoom: 14.0),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.beytei.taxi',
              ),
              if (_routePoints.isNotEmpty) PolylineLayer(polylines: [Polyline(points: _routePoints, color: Colors.blue, strokeWidth: 6)]),
              MarkerLayer(markers: [
                Marker(point: pickupPoint, child: const Icon(Icons.location_on, color: Colors.green, size: 40)),
                if (destinationPoint != null) Marker(point: destinationPoint, child: const Icon(Icons.flag, color: Colors.red, size: 40)),
                if (_driverLocation != null) Marker(point: _driverLocation!, width: 40, height: 40, child: TweenAnimationBuilder<double>(tween: Tween<double>(begin: _previousDriverBearing, end: _driverBearing), duration: const Duration(milliseconds: 800), builder: (context, value, child) {
                  return RotatingVehicleIcon(vehicleType: _currentRide['driver']?['vehicle_type'] ?? 'Car', bearing: value);
                })),
              ]),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    '© OpenStreetMap France',
                    onTap: () => launchUrl(Uri.parse('https://www.openstreetmap.fr/')),
                  ),
                  TextSourceAttribution(
                    '© OpenStreetMap contributors',
                    onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Card(
              margin: const EdgeInsets.all(12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (_currentRide['pickup_region'] != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text("المنطقة: ${_currentRide['pickup_region']}", style: TextStyle(fontSize: 16, color: Colors.blueGrey)),
                      ),
                    Text('حالة الرحلة: $status', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    if (status == 'accepted') Text("المسافة إلى العميل: ${(_distanceToPickup / 1000).toStringAsFixed(2)} كم"),
                    const Divider(),
                    const SizedBox(height: 15),
                    _buildActionButton(),
                    if (status != 'completed' && status != 'cancelled') TextButton.icon(icon: const Icon(Icons.cancel, color: Colors.red), label: const Text('إلغاء الرحلة', style: TextStyle(color: Colors.red)), onPressed: _isLoading ? null : () => _updateStatus('cancelled'))
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
// =============================================================================
// Customer Quick Ride Screen (with Improved Location Selection)
// =============================================================================
enum BookingStage { selectingPickup, selectingDestination, confirmingRequest }
class QuickRideMapScreen extends StatefulWidget {
  final String token;
  final AuthResult authResult;
  final void Function(int) onChangeTab;

  const QuickRideMapScreen({
    super.key,
    required this.token,
    required this.authResult,
    required this.onChangeTab,
  });

  @override
  State<QuickRideMapScreen> createState() => _QuickRideMapScreenState();
}
class _QuickRideMapScreenState extends State<QuickRideMapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  Map<String, dynamic>? _activeRide;
  bool _isLoading = false;
  Timer? _statusTimer;
  final _priceController = TextEditingController();

  LatLng? _pickupLocation;
  Map<String, dynamic>? _destinationData;
  bool _isConfirmingRideDetails = false;
  List<dynamic> _pendingOffers = [];

  LatLng? _currentUserLocation;
  StreamSubscription<geolocator.Position>? _locationStream;

  LatLng? _assignedDriverLocation;
  Timer? _liveTrackingTimer;
  List<LatLng> _routeToCustomer = [];
  double _assignedDriverBearing = 0.0;
  double _previousAssignedDriverBearing = 0.0;

  Map<String, dynamic> _driversData = {};
  final Map<String, AnimationController> _animationControllers = {};
  final Map<String, Animation<LatLng>> _animations = {};
  final Map<String, ({LatLng begin, LatLng end})> _driverAnimationSegments = {};
  Timer? _driversTimer;
  final Map<String, double> _lastBearings = {};

  @override
  void initState() {
    super.initState();
    _setupInitialLocation();
    _driversTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_activeRide == null) _fetchActiveDrivers();
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _driversTimer?.cancel();
    _liveTrackingTimer?.cancel();
    _locationStream?.cancel();
    _priceController.dispose();
    for (var controller in _animationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _setupInitialLocation() async {
    setState(() => _isLoading = true);
    final hasPermission = await PermissionService.handleLocationPermission(context);
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يجب تفعيل إذن الموقع لاستخدام التطبيق')));
        setState(() => _isLoading = false);
      }
      return;
    }
    try {
      geolocator.Position position = await geolocator.Geolocator.getCurrentPosition(desiredAccuracy: geolocator.LocationAccuracy.bestForNavigation);
      if (mounted) {
        final initialLocation = LatLng(position.latitude, position.longitude);
        setState(() {
          _currentUserLocation = initialLocation;
          _pickupLocation = initialLocation;
          _isLoading = false;
        });
        _mapController.move(initialLocation, 16.0);
        _fetchActiveDrivers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل تحديد الموقع. يرجى تفعيل صلاحيات الموقع .')));
        setState(() => _isLoading = false);
      }
    }
    _locationStream = geolocator.Geolocator.getPositionStream().listen((geolocator.Position position) {
      if (mounted) {
        setState(() => _currentUserLocation = LatLng(position.latitude, position.longitude));
      }
    });
  }

  void _startLiveTracking(String rideId) {
    _liveTrackingTimer?.cancel();
    _liveTrackingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_activeRide == null) {
        timer.cancel();
        return;
      }
      final newDriverLocation = await ApiService.getRideDriverLocation(widget.token, rideId);
      if (mounted && newDriverLocation != null) {
        double newBearing = _assignedDriverBearing;
        if (_assignedDriverLocation != null) {
          newBearing = calculateBearing(_assignedDriverLocation!, newDriverLocation);
        }
        setState(() {
          _previousAssignedDriverBearing = _assignedDriverBearing;
          _assignedDriverLocation = newDriverLocation;
          _assignedDriverBearing = newBearing;
        });
        final pickupPoint = LatLng(double.parse(_activeRide!['pickup']['lat']), double.parse(_activeRide!['pickup']['lng']));
        _getRoute(_assignedDriverLocation!, pickupPoint);
      }
    });
  }

  void _stopLiveTracking() {
    _liveTrackingTimer?.cancel();
    if (mounted) {
      setState(() {
        _assignedDriverLocation = null;
        _routeToCustomer.clear();
      });
    }
  }

  Future<void> _getRoute(LatLng start, LatLng end) async {
    const String orsApiKey = 'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjVhMDU5ODAxNDA5Y2E5MzIyNDQwOTYxMWQxY2ZhYmQ5NGQ3YTA5ZmI1ZjQ5ZWRlNjcxNGRlMTUzIiwiaCI6Im11cm11cjY0In0=';
    if (orsApiKey.length < 50) return;
    final url = 'https://api.openrouteservice.org/v2/directions/driving-car?api_key=$orsApiKey&start=${start.longitude},${start.latitude}&end=${end.longitude},${end.latitude}';
    try {
      final response = await http.get(Uri.parse(url));
      if (mounted && response.statusCode == 200) {
        final data = json.decode(response.body);
        final coordinates = data['features'][0]['geometry']['coordinates'] as List;
        setState(() => _routeToCustomer = coordinates.map((c) => LatLng(c[1], c[0])).toList());
      }
    } catch (e) {
      debugPrint("ORS Exception: ${e.toString()}");
    }
  }

  Future<void> _fetchActiveDrivers() async {
    if (!mounted || _activeRide != null) return;
    try {
      final driversList = await ApiService.fetchActiveDrivers(widget.token);
      if (!mounted) return;
      final newDriversData = {for (var d in driversList) d['id'].toString(): d};
      for (var driverId in newDriversData.keys) {
        final oldDriver = _driversData[driverId];
        final newDriver = newDriversData[driverId];
        final newPosition = LatLng(double.parse(newDriver['lat']), double.parse(newDriver['lng']));
        if (oldDriver != null) {
          final oldPosition = LatLng(double.parse(oldDriver['lat']), double.parse(oldDriver['lng']));
          if (oldPosition != newPosition) {
            final controller = AnimationController(duration: const Duration(seconds: 4), vsync: this);
            final animation = LatLngTween(begin: oldPosition, end: newPosition).animate(controller);
            _animationControllers[driverId] = controller;
            _animations[driverId] = animation;
            _driverAnimationSegments[driverId] = (begin: oldPosition, end: newPosition);
            controller.forward();
          }
        } else {
          _driverAnimationSegments[driverId] = (begin: newPosition, end: newPosition);
        }
      }
      setState(() => _driversData = newDriversData);
    } catch (e) {
      debugPrint("Error fetching drivers: $e");
    }
  }

  void _startStatusTimer() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted || _activeRide == null) {
        timer.cancel();
        return;
      }
      _fetchRideStatus();
    });
  }

  Future<void> _fetchRideStatus() async {
    if (_activeRide == null) return;
    try {
      final response = await http.get(Uri.parse('${ApiService.baseUrl}/taxi/v2/rides/status?ride_id=${_activeRide!['id']}'), headers: {'Authorization': 'Bearer ${widget.token}'});
      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final updatedRide = data['ride'];
          final bool statusChanged = _activeRide?['status'] != updatedRide['status'];
          final bool driverAssigned = _activeRide?['driver'] == null && updatedRide['driver'] != null;

          if (statusChanged || driverAssigned) {
            setState(() {
              _activeRide = updatedRide;
            });
          }

          final List driverOffers = updatedRide['driver_offers'] ?? [];
          if (updatedRide['status'] == 'pending') {
            setState(() {
              _pendingOffers = driverOffers.where((o) => o['status'] == 'pending').toList();
            });
          } else {
            setState(() {
              _pendingOffers = [];
            });
          }

          if (updatedRide['status'] == 'accepted' && _assignedDriverLocation == null) {
            _stopLiveTracking();
            _startLiveTracking(updatedRide['id'].toString());
          } else if (['completed', 'cancelled'].contains(updatedRide['status'])) {
            if (updatedRide['status'] == 'completed' && updatedRide['is_rated'] == false) {
              _showRatingDialog(updatedRide['id'].toString(), 'quick_ride');
            }
            _resetBookingState();
          }
        }
      }
    } catch (e) {
      debugPrint("Failed to get ride status: $e");
    }
  }

  Future<void> _requestRide() async {
    if (_pickupLocation == null || _destinationData == null || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إكمال جميع الحقول')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/taxi/v2/rides/request'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'},
        body: json.encode({
          'pickup': {'lat': _pickupLocation!.latitude, 'lng': _pickupLocation!.longitude},
          'destination': {
            'lat': _destinationData!['lat'],
            'lng': _destinationData!['lng'],
            'name': _destinationData!['name']
          },
          'price': _priceController.text
        }),
      );
      final data = json.decode(response.body);
      if (mounted) {
        if (response.statusCode == 201 && data['success'] == true) {
          setState(() {
            _activeRide = data['ride'];
            _isConfirmingRideDetails = false;
          });
          _startStatusTimer();
        } else {
          throw Exception(data['message'] ?? 'فشل إرسال الطلب');
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelRide() async {
    if (_activeRide == null) return;
    setState(() => _isLoading = true);
    try {
      final rideId = _activeRide!['id'];
      final response = await http.post(Uri.parse('${ApiService.baseUrl}/taxi/v2/rides/cancel'), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'}, body: json.encode({'ride_id': rideId}));
      final data = json.decode(response.body);
      if (mounted) {
        if (response.statusCode == 200 && data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إلغاء الطلب بنجاح'), backgroundColor: Colors.green));
          _resetBookingState();
        } else {
          final errorMessage = data['message'] ?? 'فشل الإلغاء';
          if (errorMessage.contains("لا يمكن إلغاء الطلب بعد قبوله")) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم قبول الطلب بواسطة سائق!'), backgroundColor: Colors.orange));
            await _fetchRideStatus();
          } else {
            throw Exception(errorMessage);
          }
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _resetBookingState() {
    _statusTimer?.cancel();
    _stopLiveTracking();
    setState(() {
      _activeRide = null;
      _isConfirmingRideDetails = false;
      _destinationData = null;
      _priceController.clear();
      _pickupLocation = _currentUserLocation;
      _pendingOffers = [];
    });
  }

  List<Marker> _buildMarkers() {
    final List<Marker> markers = [];
    if (_currentUserLocation != null) {
      markers.add(Marker(width: 80, height: 80, point: _currentUserLocation!, child: const PulsingUserLocationMarker()));
    }
    if (_activeRide != null) {
      if (_assignedDriverLocation != null) {
        markers.add(Marker(width: 40, height: 40, point: _assignedDriverLocation!, child: TweenAnimationBuilder<double>(tween: Tween<double>(begin: _previousAssignedDriverBearing, end: _assignedDriverBearing), duration: const Duration(milliseconds: 800), builder: (context, value, child) {
          return RotatingVehicleIcon(vehicleType: _activeRide!['driver']?['vehicle_type'] ?? 'Car', bearing: value);
        })));
      }
      final pickupLatLng = LatLng(double.parse(_activeRide!['pickup']['lat']), double.parse(_activeRide!['pickup']['lng']));
      markers.add(Marker(point: pickupLatLng, child: const Icon(Icons.location_on, color: Colors.green, size: 40)));
    } else {
      _driversData.forEach((driverId, driver) {
        final animation = _animations[driverId];
        final segment = _driverAnimationSegments[driverId];
        if (animation != null && segment != null) {
          final currentPosition = animation.value;
          final bearing = calculateBearing(segment.begin, segment.end);
          final previousBearing = _lastBearings[driverId] ?? bearing;
          _lastBearings[driverId] = bearing;
          markers.add(Marker(width: 40, height: 40, point: currentPosition, child: TweenAnimationBuilder<double>(tween: Tween<double>(begin: previousBearing, end: bearing), duration: const Duration(seconds: 1), builder: (context, value, child) {
            return RotatingVehicleIcon(vehicleType: driver['vehicle_type']?.toString() ?? 'Car', bearing: value);
          })));
        }
      });
    }
    return markers;
  }

  void _showRatingDialog(String rideId, String rideType) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => RatingDialog(
        token: widget.authResult.token,
        rideId: rideId,
        rideType: rideType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentUserLocation ?? const LatLng(32.4741, 45.8336),
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(urlTemplate: 'https://{s}.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png', subdomains: const ['a', 'b', 'c'], userAgentPackageName: 'com.beytei.taxi'),
              if (_routeToCustomer.isNotEmpty) PolylineLayer(polylines: [Polyline(points: _routeToCustomer, color: Colors.blue, strokeWidth: 6)]),
              MarkerLayer(markers: _buildMarkers()),
            ],
          ),
          // ========  الكود المصحح هنا ========
          Positioned(
            top: 40,
            left: 15,
            right: 15,
            child: SafeArea(
              child: Column( // استخدام Column لترتيب الأزرار بشكل عمودي
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ProvinceTaxiButton(
                      onPressed: () => widget.onChangeTab(1),
                    ),
                  ),
                  const SizedBox(height: 12), // إضافة مسافة بين الزرين
                  SizedBox(
                    width: double.infinity,
                    child: StudentLinesButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => StudentLinesHubScreen(authResult: widget.authResult)),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ======== نهاية الكود المصحح ========
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _buildBottomCard(),
          ),
          if (_isLoading) Container(color: Colors.black.withOpacity(0.2), child: const Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }

  Widget _buildBottomCard() {
    if (_activeRide != null) {
      if (_pendingOffers.isNotEmpty) {
        return DriverOfferCard(
          offer: _pendingOffers.first,
          onAccept: () async {
            final offer = _pendingOffers.first;
            setState(() => _isLoading = true);
            try {
              final response = await ApiService.customerRespondToOffer(widget.token, _activeRide!['id'].toString(), offer['driver_id'].toString(), 'accepted');
              if (mounted && response.statusCode == 200) {
                _fetchRideStatus();
              } else if (mounted) {
                final data = json.decode(response.body);
                throw Exception(data['message'] ?? 'فشل قبول العرض');
              }
            } catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red));
            } finally {
              if (mounted) setState(() => _isLoading = false);
            }
          },
          onFindAnother: () async {
            final offer = _pendingOffers.first;
            setState(() {
              _isLoading = true;
              _pendingOffers.removeAt(0);
            });
            try {
              await ApiService.customerRespondToOffer(
                  widget.token,
                  _activeRide!['id'].toString(),
                  offer['driver_id'].toString(),
                  'rejected'
              );
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('فشل إرسال الرفض. حاول مرة أخرى.')));
              }
            } finally {
              if (mounted) {
                setState(() => _isLoading = false);
              }
            }
          },
        );
      } else {
        return ActiveRideInfoCard(
          ride: _activeRide!,
          onCancel: _cancelRide,
          authResult: widget.authResult,
        );
      }
    } else if (_isConfirmingRideDetails) {
      return _buildConfirmationSheet();
    } else {
      return _buildInitialRequestSheet();
    }
  }

  Widget _buildInitialRequestSheet() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: InkWell(
          onTap: () async {
            if (_pickupLocation == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("جاري تحديد موقعك الحالي...")));
              return;
            }
            final result = await Navigator.of(context).push<Map<String, dynamic>>(
              MaterialPageRoute(builder: (_) => DestinationSelectionScreen(initialPickup: _pickupLocation!)),
            );
            if (result != null && result['pickup'] != null && result['destination'] != null) {
              setState(() {
                _pickupLocation = result['pickup'];
                _destinationData = result['destination'];
                _isConfirmingRideDetails = true;
              });
            }
          },
          child: Card(
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.grey),
                  const SizedBox(width: 12),
                  Text("إلى أين تريد أن تذهب؟", style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmationSheet() {
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [const Icon(Icons.my_location, color: Colors.green), const SizedBox(width: 8), Expanded(child: Text(_pickupLocation != null ? "من: موقعك المحدد" : "من: ...", style: const TextStyle(fontWeight: FontWeight.bold)))]),
            const Divider(),
            Row(children: [const Icon(Icons.flag_outlined, color: Colors.red), const SizedBox(width: 8), Expanded(child: Text("إلى: ${_destinationData?['name'] ?? 'وجهة محددة'}", style: const TextStyle(fontWeight: FontWeight.bold)))]),
            const SizedBox(height: 12),
            TextField(controller: _priceController, keyboardType: const TextInputType.numberWithOptions(decimal: false), decoration: const InputDecoration(labelText: 'السعر المعروض (الكروة)', prefixIcon: Icon(Icons.money))),
            const SizedBox(height: 15),
            Row(
              children: [
                TextButton(onPressed: (){
                  setState(() {
                    _isConfirmingRideDetails = false;
                  });
                }, child: const Text("إلغاء")),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton(onPressed: _requestRide, child: const Text('اطلب الآن'))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
class ProvinceTaxiButton extends StatelessWidget {
  final VoidCallback onPressed;
  const ProvinceTaxiButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.local_taxi_outlined),
      label: const Text('تكسي المحافظات'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        textStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
/// زر مخصص للانتقال إلى شاشة خطوط الطلاب
// --- Button Widgets ---
class StudentLinesButton extends StatelessWidget {
  final VoidCallback onPressed;
  const StudentLinesButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.school_outlined, color: Colors.white),
      label: const Text('خطوط الطلاب'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        textStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// =============================================================================
// 2. الشاشة المحورية الجديدة للطلاب وأولياء الأمور
// =============================================================================
class StudentLinesHubScreen extends StatefulWidget {
  final AuthResult authResult;
  const StudentLinesHubScreen({super.key, required this.authResult});

  @override
  State<StudentLinesHubScreen> createState() => _StudentLinesHubScreenState();
}

class _StudentLinesHubScreenState extends State<StudentLinesHubScreen> {
  Future<List<dynamic>>? _linesFuture;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLines();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLines({String destination = ''}) async {
    final uri = Uri.parse('${ApiService.baseUrl}/taxi/v2/student-lines/available').replace(queryParameters: {
      'destination': destination
    });

    setState(() {
      _linesFuture = http.get(
          uri,
          headers: {'Authorization': 'Bearer ${widget.authResult.token}'}
      ).then((response) {
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true && data['lines'] is List) {
            return data['lines'];
          }
        }
        throw Exception('Failed to load student lines');
      });
    });
  }

  void _showBookingDialog(Map<String, dynamic> line) {
    final studentNameController = TextEditingController(text: widget.authResult.displayName);
    // ========  الكود الجديد هنا ========
    final studentPhoneController = TextEditingController(); // Controller جديد لهاتف الطالب
    // ======== نهاية الكود الجديد ========
    final parentPhoneController = TextEditingController();
    final pickupAddressController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('حجز مقعد في خط طلاب', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.deepPurple)),
                  const SizedBox(height: 16),
                  Text("إلى: ${line['destination_name']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextFormField(controller: studentNameController, decoration: const InputDecoration(labelText: 'اسم الطالب/الطالبة'), validator: (v) => v!.isEmpty ? 'الاسم مطلوب' : null),
                  const SizedBox(height: 12),
                  // ========  الكود الجديد هنا ========
                  // حقل إدخال جديد لهاتف الطالب
                  TextFormField(controller: studentPhoneController, decoration: const InputDecoration(labelText: 'رقم هاتف الطالب (للتواصل)'), keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'رقم هاتف الطالب مطلوب' : null),
                  const SizedBox(height: 12),
                  // ======== نهاية الكود الجديد ========
                  TextFormField(controller: parentPhoneController, decoration: const InputDecoration(labelText: 'رقم هاتف ولي الأمر (للتتبع)'), keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'رقم ولي الأمر مطلوب' : null),
                  const SizedBox(height: 12),
                  TextFormField(controller: pickupAddressController, decoration: const InputDecoration(labelText: 'عنوان الاستلام'), validator: (v) => v!.isEmpty ? 'العنوان مطلوب' : null),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState?.validate() ?? false) {
                        Navigator.pop(ctx);
                        try {
                          final response = await http.post(
                            Uri.parse('${ApiService.baseUrl}/taxi/v2/student-lines/book'),
                            headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.authResult.token}'},
                            // ========  الكود الجديد هنا ========
                            // إضافة الحقل الجديد إلى البيانات المرسلة
                            body: json.encode({
                              'line_id': line['id'],
                              'student_name': studentNameController.text,
                              'student_phone': studentPhoneController.text, // إرسال هاتف الطالب
                              'parent_phone': parentPhoneController.text,
                              'pickup_address': pickupAddressController.text,
                            }),
                            // ======== نهاية الكود الجديد ========
                          );
                          final data = json.decode(response.body);
                          if(mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(data['message']), backgroundColor: response.statusCode == 200 ? Colors.green : Colors.red)
                            );
                            if(response.statusCode == 200) _loadLines();
                          }
                        } catch (e) {
                          if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
                        }
                      }
                    },
                    child: const Text('تأكيد الحجز'),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('خطوط الطلاب')),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            color: Colors.blue[50],
            child: ListTile(
              leading: const Icon(Icons.shield_outlined, color: Colors.blue, size: 30),
              title: const Text('قسم أولياء الأمور', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('لتتبع رحلة ابنك/ابنتك بشكل مباشر'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentLoginScreen()));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                  labelText: 'ابحث عن وجهة (مثال: جامعة الكوت)',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _loadLines();
                    },
                  )
              ),
              onSubmitted: (value) => _loadLines(destination: value),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _linesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("خطأ: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('لا توجد خطوط طلاب تطابق بحثك.'));
                }
                final lines = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: lines.length,
                  itemBuilder: (context, index) {
                    final line = lines[index];
                    final isFull = line['available_seats'] <= 0;
                    return Card(
                      color: isFull ? Colors.grey[300] : Colors.white,
                      child: ListTile(
                        leading: CircleAvatar(child: Icon(isFull ? Icons.do_not_disturb_on : Icons.school)),
                        title: Text("إلى: ${line['destination_name']}"),
                        subtitle: Text("السائق: ${line['driver']?['name'] ?? 'N/A'} | المقاعد المتاحة: ${line['available_seats']}"),
                        trailing: ElevatedButton(
                          onPressed: isFull ? null : () => _showBookingDialog(line),
                          style: ElevatedButton.styleFrom(backgroundColor: isFull ? Colors.grey : Colors.deepPurple),
                          child: Text(isFull ? 'مكتمل' : 'حجز'),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 3. شاشات تتبع أولياء الأمور (جديدة)
// =============================================================================

class ParentLoginScreen extends StatefulWidget {
  const ParentLoginScreen({super.key});

  @override
  State<ParentLoginScreen> createState() => _ParentLoginScreenState();
}

class _ParentLoginScreenState extends State<ParentLoginScreen> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  void _trackTrip() async {
    if (_phoneController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/taxi/v2/student-lines/track-by-parent'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'phone_number': _phoneController.text}),
      );
      final data = json.decode(response.body);
      if (mounted) {
        if (response.statusCode == 200 && data['success'] == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ParentTrackingScreen(activeLineData: Map<String, dynamic>.from(data['active_line'])),
            ),
          );
        } else {
          throw Exception(data['message'] ?? 'فشل العثور على رحلات');
        }
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تتبع رحلة الأبناء')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shield_outlined, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            Text('أدخل رقم هاتفك المسجل عند الحجز لتتبع رحلة ابنك/ابنتك', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 20),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'رقم هاتف ولي الأمر'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 30),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: _trackTrip, child: const Text('تتبع الرحلة')),
          ],
        ),
      ),
    );
  }
}

class ParentTrackingScreen extends StatefulWidget {
  final Map<String, dynamic> activeLineData;
  const ParentTrackingScreen({super.key, required this.activeLineData});

  @override
  State<ParentTrackingScreen> createState() => _ParentTrackingScreenState();
}

class _ParentTrackingScreenState extends State<ParentTrackingScreen> {
  final MapController _mapController = MapController();
  LatLng? _driverLocation;
  Timer? _trackingTimer;

  @override
  void initState() {
    super.initState();
    // ========  الكود المصحح هنا ========
    // تم نقل التحكم بالخريطة إلى ما بعد أول إطار
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateLocation(widget.activeLineData['driver_location']);
      }
    });
    // ======== نهاية الكود المصحح ========
    _startTracking();
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
    super.dispose();
  }

  void _updateLocation(Map<String, dynamic>? locationData) {
    if (locationData != null) {
      final newLocation = LatLng(double.parse(locationData['lat']), double.parse(locationData['lng']));
      setState(() {
        _driverLocation = newLocation;
      });

    }
  }

  void _startTracking() {
    _trackingTimer = Timer.periodic(const Duration(seconds: 15), (timer) async {
      try {
        // البحث عن رقم هاتف ولي الأمر ضمن قائمة الطلاب
        final students = widget.activeLineData['line_info']?['students'] as List?;
        if (students == null || students.isEmpty) return;

        // نفترض أننا نبحث عن أول رقم هاتف متاح
        final parentPhone = students.firstWhere((s) => s['parent_phone'] != null, orElse: () => null)?['parent_phone'];
        if (parentPhone == null) return;

        final response = await http.post(
          Uri.parse('${ApiService.baseUrl}/taxi/v2/student-lines/track-by-parent'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'phone_number': parentPhone}),
        );
        if (mounted && response.statusCode == 200) {
          final data = json.decode(response.body);
          if(data['success'] == true) {
            _updateLocation(data['active_line']['driver_location']);
          }
        }
      } catch (e) {
        debugPrint("Tracking Error: $e");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lineInfo = widget.activeLineData['line_info'];
    return Scaffold(
      appBar: AppBar(title: Text("تتبع خط إلى ${lineInfo?['destination_name'] ?? ''}")),
      body: _driverLocation == null
          ? const Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text("موقع السائق غير متاح حالياً... يتم التحديث"),
        ],
      ))
          : FlutterMap(
        mapController: _mapController,
        options: MapOptions(initialCenter: _driverLocation!, initialZoom: 15.0),
        children: [
          TileLayer(urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png'),
          MarkerLayer(
            markers: [
              Marker(
                point: _driverLocation!,
                width: 80,
                height: 80,
                child: const Icon(Icons.directions_bus, color: Colors.blue, size: 50),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class ActiveRideInfoCard extends StatelessWidget {
  final Map<String, dynamic> ride;
  final VoidCallback onCancel;
  final AuthResult authResult;
  const ActiveRideInfoCard({super.key, required this.ride, required this.onCancel, required this.authResult});
  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'جاري البحث عن سائق...';
      case 'accepted':
        return 'تم قبول طلبك! السائق في الطريق...';
      case 'arrived_pickup':
        return 'السائق وصل لنقطة الانطلاق';
      case 'ongoing':
        return 'الرحلة جارية...';
      case 'completed':
        return 'اكتملت الرحلة';
      case 'cancelled':
        return 'تم إلغاء الرحلة';
      default:
        return 'حالة غير معروفة';
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ride['status'] ?? 'pending';
    final driver = ride['driver'];
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getStatusText(status), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber)),
            const Divider(),
            if (driver != null)
              ListTile(
                leading: CircleAvatar(backgroundImage: driver['image'] != null && driver['image'].isNotEmpty ? NetworkImage(driver['image']) : null, child: driver['image'] == null || driver['image'].isEmpty ? const Icon(Icons.person) : null),
                title: Text(driver['name'] ?? 'اسم السائق'),
                subtitle: Text('${driver['car_model'] ?? ''} - ${driver['phone'] ?? ''}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.call, color: Colors.green), tooltip: 'الاتصال بالسائق', onPressed: () => makePhoneCall(driver['phone'], context)),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            chatId: 'ride_${ride['id']}',
                            chatName: 'محادثة مع ${driver['name'] ?? 'السائق'}',
                            authResult: authResult,
                            participants: {
                              'customer': authResult.userId,
                              'driver': driver['user_id']?.toString(),
                            },
                          ),
                        ));
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ChatIconWithBadge(
                            chatId: 'ride_${ride['id']}',
                            currentUserId: authResult.userId,
                            onPressed: () {}, // Handled by parent InkWell
                          ),
                          const Text("محادثة", style: TextStyle(fontSize: 8)),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              const Text('بانتظار قبول السائق...'),
            const SizedBox(height: 10),
            if (status == 'pending') SizedBox(width: double.infinity, child: ElevatedButton.icon(icon: const Icon(Icons.cancel), label: const Text('إلغاء الطلب'), onPressed: onCancel, style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white))),
          ],
        ),
      ),
    );
  }
}

class TripListScreen extends StatefulWidget {
  final AuthResult authResult;
  const TripListScreen({super.key, required this.authResult});
  @override
  State<TripListScreen> createState() => _TripListScreenState();
}
class _TripListScreenState extends State<TripListScreen> {
  String? _searchFromProvince;
  String? _searchToProvince;
  Future<List<Map<String, dynamic>>>? _tripsFuture;

  final List<String> iraqiProvinces = [ 'بغداد', 'البصرة', 'نينوى (الموصل)', 'أربيل', 'السليمانية', 'دهوك', 'الأنبار', 'بابل', 'القادسية (الديوانية)', 'ديالى', 'ذي قار (الناصرية)', 'صلاح الدين', 'كركوك', 'كربلاء', 'المثنى (السماوة)', 'ميسان (العمارة)', 'النجف', 'واسط (الكوت)' ];

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  /// Fetches trips and performs client-side filtering.
  Future<List<Map<String, dynamic>>> _fetchTrips() async {
    final uri = Uri.parse('${ApiService.baseUrl}/taxi/v2/trips/search');

    try {
      final response = await http.get(uri, headers: {'Authorization': 'Bearer ${widget.authResult.token}'});
      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['trips'] is List) {
          List<Map<String, dynamic>> allTrips = List<Map<String, dynamic>>.from(data['trips']);

          // Client-side filtering logic
          if (_searchFromProvince != null && _searchFromProvince!.isNotEmpty) {
            allTrips = allTrips.where((trip) => trip['from_province']?.toString() == _searchFromProvince).toList();
          }
          if (_searchToProvince != null && _searchToProvince!.isNotEmpty) {
            allTrips = allTrips.where((trip) => trip['to_province']?.toString() == _searchToProvince).toList();
          }

          return allTrips;
        } else {
          throw Exception(data['message'] ?? 'Failed to parse trips from server');
        }
      } else {
        throw Exception('فشل تحميل الرحلات (Status Code: ${response.statusCode})');
      }
    } on SocketException {
      throw Exception('يرجى التحقق من اتصالك بالإنترنت');
    } catch (e) {
      throw Exception('حدث خطأ غير متوقع: ${e.toString()}');
    }
  }

  /// Triggers a reload of the trips.
  void _loadTrips() {
    setState(() {
      _tripsFuture = _fetchTrips();
    });
  }

  /// Books seats for a trip.
  Future<void> _bookTrip({required String tripId, required String name, required String phone, required String address, required int quantity}) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/taxi/v2/book'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.authResult.token}'},
        body: json.encode({'trip_id': tripId, 'name': name, 'phone': phone, 'address': address, 'quantity': quantity}),
      );
      final result = json.decode(response.body);
      if (mounted) {
        if (response.statusCode == 200 && result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم الحجز بنجاح لـ $quantity مقاعد!'), backgroundColor: Colors.green));
          _loadTrips(); // Refresh the list to show updated data
        } else {
          throw Exception(result['message'] ?? 'فشل الحجز');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في الحجز: ${e.toString().replaceAll("Exception: ", "")}'), backgroundColor: Colors.red));
      }
    }
  }

  /// Cancels a specific booking.
  Future<void> _cancelBooking(String tripId, String passengerId) async {
    try {
      final response = await http.post(
          Uri.parse('${ApiService.baseUrl}/taxi/v2/cancel'),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.authResult.token}'},
          body: json.encode({'trip_id': tripId, 'passenger_id': passengerId})
      );
      final result = json.decode(response.body);
      if (mounted) {
        if (response.statusCode == 200 && result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إلغاء الحجز بنجاح!'), backgroundColor: Colors.green));
          _loadTrips(); // Refresh the list
        } else {
          throw Exception(result['message'] ?? 'فشل الإلغاء');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في الإلغاء: ${e.toString().replaceFirst("Exception: ", "")}'), backgroundColor: Colors.red));
      }
    }
  }

  /// Shows the booking dialog with all required fields.
  void _showBookingDialog(Map<String, dynamic> trip) {
    final nameController = TextEditingController(text: widget.authResult.displayName);
    final phoneController = TextEditingController();
    final addressController = TextEditingController(); // Address field is back
    final pricePerSeat = double.tryParse(trip['price_per_seat']?.toString() ?? '0.0') ?? 0.0;
    final passengers = (trip['passengers'] is List) ? trip['passengers'] as List : [];
    final totalSeats = int.tryParse(trip['total_seats']?.toString() ?? '0') ?? 0;
    final bookedSeats = passengers.fold<int>(0, (sum, p) => sum + (int.tryParse(p['quantity']?.toString() ?? '1') ?? 1));
    final availableSeats = totalSeats - bookedSeats;

    int selectedQuantity = availableSeats > 0 ? 1 : 0;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final totalPrice = selectedQuantity * pricePerSeat;
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('حجز مقعد', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                      const SizedBox(height: 16),
                      Text('${trip['from']} ⬅️ ${trip['to']}', style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      TextFormField(controller: nameController, decoration: const InputDecoration(labelText: 'الاسم الكامل', prefixIcon: Icon(Icons.person)), validator: (v) => v!.isEmpty ? 'الاسم مطلوب' : null),
                      const SizedBox(height: 12),
                      TextFormField(controller: phoneController, decoration: const InputDecoration(labelText: 'رقم الهاتف', prefixIcon: Icon(Icons.phone)), keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'رقم الهاتف مطلوب' : null),
                      const SizedBox(height: 12),
                      TextFormField(controller: addressController, decoration: const InputDecoration(labelText: 'عنوان الاستلام', prefixIcon: Icon(Icons.location_on)), validator: (v) => v!.isEmpty ? 'العنوان مطلوب' : null),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('عدد المقاعد:'),
                          IconButton(icon: const Icon(Icons.remove_circle_outline), color: Colors.red, onPressed: selectedQuantity > 1 ? () => setDialogState(() => selectedQuantity--) : null),
                          Text('$selectedQuantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(icon: const Icon(Icons.add_circle_outline), color: Colors.green, onPressed: selectedQuantity < availableSeats ? () => setDialogState(() => selectedQuantity++) : null),
                        ],
                      ),
                      const Divider(height: 20),
                      Text("الإجمالي: ${NumberFormat.decimalPattern('ar').format(totalPrice)} د.ع", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                          ElevatedButton(
                            onPressed: () async {
                              if (formKey.currentState?.validate() ?? false) {
                                Navigator.pop(ctx);
                                await _bookTrip(tripId: trip['id'].toString(), name: nameController.text, phone: phoneController.text, address: addressController.text, quantity: selectedQuantity);
                              }
                            },
                            child: const Text('تأكيد الحجز'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Navigates to the passengers screen for a given trip.
  void _showPassengersScreen(Map<String, dynamic> trip) {
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PassengersScreen(
            trip: trip,
            currentUserId: widget.authResult.userId,
            onCancelBooking: (passengerId) async => await _cancelBooking(trip['id'].toString(), passengerId),
            authResult: widget.authResult,
          ),
        ),
      ).then((_) => _loadTrips()); // Refresh list when returning
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: DropdownButtonFormField<String>(value: _searchFromProvince, hint: const Text('من محافظة...'), items: iraqiProvinces.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(), onChanged: (val) => setState(() => _searchFromProvince = val), isExpanded: true)),
              const SizedBox(width: 10),
              Expanded(child: DropdownButtonFormField<String>(value: _searchToProvince, hint: const Text('إلى محافظة...'), items: iraqiProvinces.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(), onChanged: (val) => setState(() => _searchToProvince = val), isExpanded: true)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: ElevatedButton.icon(onPressed: _loadTrips, icon: const Icon(Icons.search), label: const Text('بحث'))),
              const SizedBox(width: 10),
              IconButton(icon: const Icon(Icons.clear, color: Colors.grey), onPressed: () { setState(() { _searchFromProvince = null; _searchToProvince = null; }); _loadTrips(); }, tooltip: 'مسح البحث'),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildContent() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _tripsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.builder(itemCount: 5, itemBuilder: (context, index) => const ShimmerListItem());
        }
        if (snapshot.hasError) {
          return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text('${snapshot.error}'.replaceAll("Exception: ", ""), style: const TextStyle(color: Colors.red, fontSize: 16), textAlign: TextAlign.center)));
        }
        final trips = snapshot.data;
        if (trips == null || trips.isEmpty) {
          return EmptyStateWidget(svgAsset: '', message: 'لا توجد رحلات متاحة تطابق بحثك حالياً.', buttonText: 'اطلب سيارة خصوصي', onButtonPressed: () { final customerMainScreenState = context.findAncestorStateOfType<_CustomerMainScreenState>(); customerMainScreenState?._changeTab(2); });
        }
        return RefreshIndicator(
          onRefresh: () async => _loadTrips(),
          child: AnimationLimiter(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: trips.length,
              itemBuilder: (context, index) {
                final trip = trips[index];
                final driver = (trip['driver'] is Map<String, dynamic>) ? trip['driver'] as Map<String, dynamic> : <String, dynamic>{};
                final fromText = "${trip['from_province'] ?? ''} - ${trip['from'] ?? ''}";
                final toText = "${trip['to_province'] ?? ''} - ${trip['to'] ?? ''}";
                final pricePerSeat = double.tryParse(trip['price_per_seat']?.toString() ?? '0.0') ?? 0.0;
                final passengers = (trip['passengers'] is List) ? trip['passengers'] as List : [];
                final totalSeats = int.tryParse(trip['total_seats']?.toString() ?? '0') ?? 0;
                final bookedSeatsCount = passengers.fold<int>(0, (sum, p) => sum + (int.tryParse(p['quantity']?.toString() ?? '1') ?? 1));
                final availableSeats = totalSeats - bookedSeatsCount;
                final userBookings = passengers.where((p) => p['user_id']?.toString() == widget.authResult.userId).toList();
                final userBookedSeats = userBookings.fold<int>(0, (sum, p) => sum + (int.tryParse(p['quantity']?.toString() ?? '1') ?? 1));

                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Container(width: 60, height: 60, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.blue, width: 2)), child: ClipOval(child: driver['image'] != null && driver['image'].toString().isNotEmpty ? Image.network(driver['image'].toString(), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 30)) : const Icon(Icons.person, size: 30))),
                                    const SizedBox(width: 12),
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(driver['name']?.toString() ?? 'غير معروف', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text('${driver['car_model'] ?? ''} - ${driver['car_color'] ?? ''}', style: const TextStyle(color: Colors.grey))])),
                                    IconButton(icon: const Icon(Icons.call, color: Colors.green, size: 30), onPressed: () => makePhoneCall(driver['phone'], context), tooltip: 'الاتصال بالسائق')
                                  ]),
                                  const Divider(height: 24),
                                  Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(fromText, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis)), const Icon(Icons.arrow_forward, color: Colors.blue), Expanded(child: Text(toText, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis))])),
                                  const SizedBox(height: 16),
                                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_buildInfoItem(Icons.calendar_today, _formatDate(trip['date'].toString()), Colors.blue), _buildInfoItem(Icons.access_time, trip['time'].toString(), Colors.orange), _buildInfoItem(Icons.event_seat, '$bookedSeatsCount/$totalSeats', availableSeats > 0 ? Colors.green : Colors.red)]),
                                  const SizedBox(height: 16),
                                  Row(children: [
                                    Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.people, size: 18), label: Text('عرض الركاب (${passengers.length})'), onPressed: userBookings.isNotEmpty ? () => _showPassengersScreen(trip) : null)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                        child: userBookedSeats > 0
                                            ? ElevatedButton.icon(icon: const Icon(Icons.cancel_outlined, size: 18), label: Text('إلغاء ($userBookedSeats)'), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), onPressed: () => _showPassengersScreen(trip))
                                            : ElevatedButton.icon(icon: const Icon(Icons.add_shopping_cart, size: 18), label: const Text('حجز مقعد'), style: ElevatedButton.styleFrom(backgroundColor: availableSeats > 0 ? Colors.blue : Colors.grey, foregroundColor: Colors.white), onPressed: availableSeats > 0 ? () => _showBookingDialog(trip) : null))
                                  ]),
                                ],
                              ),
                            ),
                            Positioned(
                              top: 0,
                              left: 0,
                              child: Chip(
                                label: Text("${NumberFormat.decimalPattern('ar').format(pricePerSeat)} د.ع", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                backgroundColor: Colors.green,
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(bottomRight: Radius.circular(12))),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoItem(IconData icon, String text, Color color) {
    return Row(children: [Icon(icon, size: 18, color: color), const SizedBox(width: 4), Text(text, style: TextStyle(fontWeight: FontWeight.bold, color: color))]);
  }
}


// =============================================================================
// PassengersScreen & RatingDialog (Required for TripListScreen)
// =============================================================================

class PassengersScreen extends StatelessWidget {
  final Map<String, dynamic> trip;
  final String currentUserId;
  final Future<void> Function(String) onCancelBooking;
  final AuthResult authResult;
  const PassengersScreen({super.key, required this.trip, required this.currentUserId, required this.onCancelBooking, required this.authResult});

  void _showRatingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => RatingDialog(
        token: authResult.token,
        rideId: trip['id'].toString(),
        rideType: 'trip',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final passengers = (trip['passengers'] as List?)?.map((p) => Map<String, dynamic>.from(p)).toList() ?? [];
    final totalSeats = int.tryParse(trip['total_seats'].toString()) ?? 0;
    final currentUserBookings = passengers.where((p) => p['user_id']?.toString() == currentUserId).toList();
    final isDriver = trip['driver']?['user_id']?.toString() == currentUserId;
    final isTripOver = DateTime.parse(trip['date']).isBefore(DateTime.now());
    final bool canRate = isTripOver && !isDriver && currentUserBookings.isNotEmpty;

    // <-- FIX: Collect all participant IDs for group chat.
    final Set<String> participantIds = {};
    if (trip['driver']?['user_id'] != null) {
      participantIds.add(trip['driver']['user_id'].toString());
    }
    for (var p in passengers) {
      if (p['user_id'] != null) {
        participantIds.add(p['user_id'].toString());
      }
    }
    final Map<String, String> participantsMap = { for (var id in participantIds) id : id };

    return Scaffold(
      appBar: AppBar(
        title: const Text('قائمة الركاب'),
        centerTitle: true,
        actions: [
          // <-- FIX: Chat button is now fully functional for group chat.
          TextButton.icon(
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text("محادثة الرحلة"),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ChatScreen(
                  chatId: 'trip_${trip['id']}',
                  chatName: 'مجموعة رحلة ${trip['from']} - ${trip['to']}',
                  authResult: authResult,
                  participants: participantsMap,
                ),
              ));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [Text('${trip['from']} → ${trip['to']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center), const SizedBox(height: 8), Text('${_formatDate(trip['date'].toString())} - ${trip['time']}', style: const TextStyle(color: Colors.grey)), const SizedBox(height: 8), Text('المقاعد: ${passengers.fold<int>(0, (sum, p) => sum + (int.tryParse(p['quantity']?.toString() ?? '1') ?? 1))}/$totalSeats', style: const TextStyle(fontWeight: FontWeight.bold))]))),
            if (canRate) ...[
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => _showRatingDialog(context), icon: const Icon(Icons.star), label: const Text('تقييم السائق'), style: ElevatedButton.styleFrom(backgroundColor: Colors.amber))),
            ],
            const SizedBox(height: 16),
            if (!isDriver) ...[
              const Text('حجوزاتي لهذه الرحلة:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              currentUserBookings.isEmpty
                  ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: Text('لم تقم بأي حجز في هذه الرحلة.', style: TextStyle(color: Colors.grey))))
                  : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: currentUserBookings.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final passenger = currentUserBookings[index];
                  return ListTile(
                    leading: CircleAvatar(backgroundColor: Colors.blue.withOpacity(0.2), child: Text('${passenger['quantity'] ?? 1}')),
                    title: Text(passenger['name']?.toString() ?? 'غير معروف'),
                    subtitle: Text('رقم الهاتف: ${passenger['phone']?.toString() ?? ''}', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                    trailing: IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () => showDialog(context: context, builder: (dialogContext) => AlertDialog(title: const Text('تأكيد الإلغاء'), content: const Text('هل أنت متأكد من إلغاء هذا الحجز؟'), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('لا')), TextButton(onPressed: () async { Navigator.pop(dialogContext); await onCancelBooking(passenger['id'].toString()); if (context.mounted) Navigator.pop(context); }, child: const Text('نعم، إلغاء'))]))),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
            const Text('جميع الركاب المسجلين في الرحلة:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            passengers.isEmpty
                ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: Text('لا يوجد ركاب مسجلين بعد', style: TextStyle(color: Colors.grey))))
                : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: passengers.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final passenger = passengers[index];
                return ListTile(
                  leading: CircleAvatar(backgroundColor: Colors.grey.withOpacity(0.2), child: Text('${passenger['quantity'] ?? 1}')),
                  title: Text(passenger['name']?.toString() ?? 'غير معروف'),
                  subtitle: isDriver ? Text('العنوان: ${passenger['address']?.toString() ?? 'غير محدد'}', style: const TextStyle(fontSize: 12)) : null,
                  trailing: isDriver ? IconButton(icon: const Icon(Icons.call, color: Colors.green), onPressed: () => makePhoneCall(passenger['phone'], context)) : null,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
class DriverCreateTripScreen extends StatefulWidget {
  final AuthResult authResult;
  const DriverCreateTripScreen({super.key, required this.authResult});
  @override
  State<DriverCreateTripScreen> createState() => _DriverCreateTripScreenState();
}


class _DriverCreateTripScreenState extends State<DriverCreateTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fromLocationController = TextEditingController();
  final _toLocationController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _seatsController = TextEditingController();
  final _priceController = TextEditingController();

  String? _fromProvince;
  String? _toProvince;

  bool _isLoading = false;

  final List<String> iraqiProvinces = [ 'بغداد', 'البصرة', 'نينوى (الموصل)', 'أربيل', 'السليمانية', 'دهوك', 'الأنبار', 'بابل', 'القادسية (الديوانية)', 'ديالى', 'ذي قار (الناصرية)', 'صلاح الدين', 'كركوك', 'كربلاء', 'المثنى (السماوة)', 'ميسان (العمارة)', 'النجف', 'واسط (الكوت)' ];

  @override
  void dispose() {
    _fromLocationController.dispose();
    _toLocationController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _seatsController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 30)));
    if (picked != null) setState(() => _dateController.text = DateFormat('yyyy-MM-dd').format(picked));
  }

  Future<void> _selectTime() async {
    TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null && mounted) setState(() => _timeController.text = picked.format(context));
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
          Uri.parse('${ApiService.baseUrl}/taxi/v2/driver/create-trip'),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.authResult.token}'},
          body: json.encode({
            'from_province': _fromProvince,
            'from': _fromLocationController.text,
            'to_province': _toProvince,
            'to': _toLocationController.text,
            'date': _dateController.text,
            'time': _timeController.text,
            'seats': _seatsController.text,
            'price_per_seat': _priceController.text
          })
      );
      final data = json.decode(response.body);
      if (mounted) {
        if (response.statusCode == 201 && data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message']), backgroundColor: Colors.green));

          _fromLocationController.clear();
          _toLocationController.clear();
          _dateController.clear();
          _timeController.clear();
          _seatsController.clear();
          _priceController.clear();
          setState(() {
            _fromProvince = null;
            _toProvince = null;
          });
          _formKey.currentState?.reset();

        } else {
          throw Exception(data['message'] ?? 'فشل إنشاء الرحلة');
        }
      }
    } on SocketException {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى التحقق من اتصالك بالإنترنت'), backgroundColor: Colors.orange));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _fromProvince,
                decoration: const InputDecoration(labelText: 'محافظة الانطلاق'),
                items: iraqiProvinces.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (val) => setState(() => _fromProvince = val),
                validator: (v) => v == null ? 'الحقل مطلوب' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(controller: _fromLocationController, decoration: const InputDecoration(labelText: 'من (المنطقة/العنوان)'), validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: _toProvince,
                decoration: const InputDecoration(labelText: 'محافظة الوصول'),
                items: iraqiProvinces.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (val) => setState(() => _toProvince = val),
                validator: (v) => v == null ? 'الحقل مطلوب' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(controller: _toLocationController, decoration: const InputDecoration(labelText: 'إلى (المنطقة/العنوان)'), validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null),
              const SizedBox(height: 15),
              TextFormField(controller: _dateController, decoration: const InputDecoration(labelText: 'التاريخ', prefixIcon: Icon(Icons.calendar_today)), readOnly: true, onTap: _selectDate, validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null),
              const SizedBox(height: 15),
              TextFormField(controller: _timeController, decoration: const InputDecoration(labelText: 'الوقت', prefixIcon: Icon(Icons.access_time)), readOnly: true, onTap: _selectTime, validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null),
              const SizedBox(height: 15),
              TextFormField(controller: _seatsController, decoration: const InputDecoration(labelText: 'عدد المقاعد'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null),
              const SizedBox(height: 15),
              TextFormField(controller: _priceController, decoration: const InputDecoration(labelText: 'سعر المقعد الواحد (دينار عراقي)'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null),
              const SizedBox(height: 30),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _isLoading ? null : _submit, child: _isLoading ? const CircularProgressIndicator() : const Text('إنشاء الرحلة'))),
            ],
          ),
        ),
      ),
    );
  }
}

class DriverMyTripsScreen extends StatefulWidget {
  final AuthResult authResult;
  final VoidCallback navigateToCreate;
  const DriverMyTripsScreen({super.key, required this.authResult, required this.navigateToCreate});
  @override
  State<DriverMyTripsScreen> createState() => _DriverMyTripsScreenState();
}
class _DriverMyTripsScreenState extends State<DriverMyTripsScreen> {
  Future<List<dynamic>>? _myTripsFuture;

  @override
  void initState() {
    super.initState();
    _fetchMyTrips();
  }

  Future<void> _fetchMyTrips() async {
    setState(() {
      _myTripsFuture = http.get(
          Uri.parse('${ApiService.baseUrl}/taxi/v2/driver/my-trips'),
          headers: {'Authorization': 'Bearer ${widget.authResult.token}'}
      ).then((response) {
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true && data['trips'] is List) {
            return data['trips'];
          }
        }
        throw Exception('Failed to load driver trips');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<dynamic>>(
          future: _myTripsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListView.builder(itemCount: 4, itemBuilder: (context, index) => const ShimmerListItem());
            }
            if (snapshot.hasError) {
              return Center(child: Text("خطأ: ${snapshot.error}"));
            }
            final myTrips = snapshot.data;
            if (myTrips == null || myTrips.isEmpty) {
              return Center(child: Text("لم تقم بإنشاء أي رحلات بعد."));
            }

            return RefreshIndicator(
              onRefresh: _fetchMyTrips,
              child: AnimationLimiter(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: myTrips.length,
                  itemBuilder: (context, index) {
                    final trip = myTrips[index];
                    final passengers = (trip['passengers'] as List?) ?? [];

                    // <-- FIX: Calculate total booked seats correctly by summing quantities.
                    final bookedSeatsCount = passengers.fold<int>(0, (sum, p) {
                      final quantity = int.tryParse(p['quantity']?.toString() ?? '1') ?? 1;
                      return sum + quantity;
                    });

                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 375),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text('${trip['from']} → ${trip['to']}'),
                              subtitle: Text('${_formatDate(trip['date'])} - ${trip['time']}'),
                              // <-- FIX: Display the correct booked seats count.
                              trailing: Text('$bookedSeatsCount / ${trip['total_seats']} مقاعد'),
                              onTap: () {
                                if (mounted) {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => PassengersScreen(
                                          trip: trip,
                                          currentUserId: widget.authResult.userId,
                                          onCancelBooking: (_) async {}, // Driver cannot cancel bookings
                                          authResult: widget.authResult
                                      ))
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          }
      ),
    );
  }
}

class PrivateRequestFormScreen extends StatefulWidget {
  final AuthResult authResult;
  const PrivateRequestFormScreen({super.key, required this.authResult});
  @override
  State<PrivateRequestFormScreen> createState() => _PrivateRequestFormScreenState();
}

class _PrivateRequestFormScreenState extends State<PrivateRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _priceController = TextEditingController();
  final _timeController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _withReturn = false;
  bool _isLoading = false;

  Map<String, dynamic>? _activeRequest;
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    _fetchMyActiveRequest();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _fromController.dispose();
    _toController.dispose();
    _priceController.dispose();
    _timeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _startStatusTimer() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_activeRequest != null && (_activeRequest!['status'] == 'pending' || _activeRequest!['status'] == 'accepted')) {
        _fetchMyActiveRequest();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _fetchMyActiveRequest() async {
    if (!mounted) return;
    try {
      final response = await ApiService.getMyActivePrivateRequest(widget.authResult.token);
      if (mounted && response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['request'] != null) {
          final currentStatus = _activeRequest?['status'];
          final newStatus = data['request']['status'];
          final isRated = data['request']['is_rated'] ?? false;

          setState(() {
            _activeRequest = data['request'];
          });

          if ((currentStatus == 'accepted' || currentStatus == 'pending') && newStatus == 'completed' && !isRated) {
            _showRatingDialog(_activeRequest!['id'].toString(), 'private_request');
            _resetForm(); // Reset after rating
          } else if (newStatus == 'completed' || newStatus == 'cancelled') {
            _resetForm();
          } else if (newStatus == 'pending' || newStatus == 'accepted') {
            _startStatusTimer();
          }
        } else {
          _resetForm();
        }
      }
    } catch (e) {
      debugPrint("Failed to fetch active private request: $e");
      _resetForm();
    }
  }

  void _resetForm() {
    setState(() {
      _activeRequest = null;
    });
  }

  void _showRatingDialog(String rideId, String rideType) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => RatingDialog(
        token: widget.authResult.token,
        rideId: rideId,
        rideType: rideType,
      ),
    );
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null && mounted) {
      setState(() {
        _timeController.text = picked.format(context);
      });
    }
  }

  Future<void> _submitRequest() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    try {
      final body = {'from': _fromController.text, 'to': _toController.text, 'price': _priceController.text, 'time': _timeController.text, 'phone': _phoneController.text, 'with_return': _withReturn};
      final response = await ApiService.createPrivateRequest(widget.authResult.token, body);
      final data = json.decode(response.body);
      if (mounted) {
        if (response.statusCode == 201 && data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message']), backgroundColor: Colors.green));
          NotificationService.showNotification('طلب خصوصي جديد!', 'يوجد طلب من ${_fromController.text} إلى ${_toController.text}. اضغط للقبول.', payload: '{"userType": "driver", "targetScreen": "private_requests"}', type: 'high_priority');
          _formKey.currentState?.reset();
          _fromController.clear();
          _toController.clear();
          _priceController.clear();
          _timeController.clear();
          _phoneController.clear();
          setState(() => _withReturn = false);
          _fetchMyActiveRequest();
        } else {
          throw Exception(data['message'] ?? 'فشل إرسال الطلب');
        }
      }
    } on SocketException {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى التحقق من اتصالك بالإنترنت'), backgroundColor: Colors.orange));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelRequest() async {
    if (_activeRequest == null) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الإلغاء'),
        content: const Text('هل أنت متأكد من إلغاء هذا الطلب؟'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('تراجع')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('نعم، إلغاء'), style: TextButton.styleFrom(foregroundColor: Colors.red)),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final response = await ApiService.cancelMyPrivateRequest(widget.authResult.token, _activeRequest!['id'].toString());
      final data = json.decode(response.body);
      if (mounted) {
        if (response.statusCode == 200 && data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message']), backgroundColor: Colors.green));
          if (_activeRequest!['status'] == 'accepted') {
            NotificationService.showNotification(
              'إلغاء رحلة خاصة',
              'قام الزبون بإلغاء الرحلة الخاصة من ${_activeRequest!['from']} إلى ${_activeRequest!['to']}.',
              type: 'high_priority',
            );
          }
          _resetForm();
          _statusTimer?.cancel();
        } else {
          throw Exception(data['message'] ?? 'فشل إلغاء الطلب');
        }
      }
    } on SocketException {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى التحقق من اتصالك بالإنترنت'), backgroundColor: Colors.orange));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _activeRequest != null ? ActivePrivateRequestCard(request: _activeRequest!, onCancel: _cancelRequest, authResult: widget.authResult) : _buildRequestForm(),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildRequestForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('طلب سيارة خصوصي ', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            TextFormField(controller: _fromController, decoration: const InputDecoration(labelText: 'مكان الانطلاق', prefixIcon: Icon(Icons.my_location)), validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _toController, decoration: const InputDecoration(labelText: 'الوجهة', prefixIcon: Icon(Icons.flag)), validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _priceController, decoration: const InputDecoration(labelText: 'السعر المقترح (دينار عراقي)', prefixIcon: Icon(Icons.price_change)), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _timeController, decoration: const InputDecoration(labelText: 'وقت الانطلاق', prefixIcon: Icon(Icons.access_time)), readOnly: true, onTap: _selectTime, validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: 'رقم الهاتف للتواصل', prefixIcon: Icon(Icons.phone)), keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null),
            const SizedBox(height: 16),
            SwitchListTile(title: const Text('هل الرحلة مع عودة؟'), value: _withReturn, onChanged: (val) => setState(() => _withReturn = val), secondary: Icon(_withReturn ? Icons.sync : Icons.sync_disabled)),
            const SizedBox(height: 32),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _isLoading ? null : _submitRequest, child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('إرسال الطلب للسائقين'))),
          ],
        ),
      ),
    );
  }
}

class ActivePrivateRequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onCancel;
  final AuthResult authResult;
  const ActivePrivateRequestCard({super.key, required this.request, required this.onCancel, required this.authResult});

  @override
  Widget build(BuildContext context) {
    final driver = request['accepted_driver'];
    final bool isAccepted = request['status'] == 'accepted' && driver != null;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('طلبك الحالي', style: Theme.of(context).textTheme.headlineSmall),
                const Divider(height: 24),
                _buildInfoRow(Icons.my_location, "من:", request['from']),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.flag, "إلى:", request['to']),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.payments, "السعر:", "${request['price']} د.ع"),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.access_time, "الوقت:", request['time']),
                const Divider(height: 24),
                if (isAccepted) ...[
                  Text('تم قبول طلبك!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[700])),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: CircleAvatar(backgroundImage: driver['image'] != null && driver['image'].isNotEmpty ? NetworkImage(driver['image']) : null, child: driver['image'] == null || driver['image'].isEmpty ? const Icon(Icons.person) : null),
                    title: Text(driver['name'] ?? 'اسم السائق'),
                    subtitle: Text(driver['car_model'] ?? 'بيانات السيارة'),
                    trailing: IconButton(icon: const Icon(Icons.call, color: Colors.green, size: 30), onPressed: () => makePhoneCall(driver['phone'], context)),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: ChatIconWithBadge(chatId: 'private_${request['id']}', currentUserId: authResult.userId, onPressed: () {}),
                      label: const Text("التحدث مع السائق"),
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            chatId: 'private_${request['id']}',
                            chatName: 'محادثة مع ${driver['name'] ?? 'السائق'}',
                            authResult: authResult,
                            participants: {
                              'customer': authResult.userId,
                              'driver': driver['id']?.toString(),
                            },
                          ),
                        ));
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                    ),
                  ),
                ] else ...[
                  Row(children: [const CircularProgressIndicator(strokeWidth: 2), const SizedBox(width: 16), Text('جاري البحث عن سائق...', style: TextStyle(fontSize: 16, color: Colors.grey[700]))]),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('إلغاء الطلب'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700], foregroundColor: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(children: [Icon(icon, color: Colors.grey[600], size: 20), const SizedBox(width: 12), Text(label, style: TextStyle(color: Colors.grey[800], fontSize: 16)), const SizedBox(width: 8), Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)))]);
  }
}

class DriverPrivateRequestsScreen extends StatefulWidget {
  final AuthResult authResult;
  const DriverPrivateRequestsScreen({super.key, required this.authResult});
  @override
  State<DriverPrivateRequestsScreen> createState() => _DriverPrivateRequestsScreenState();
}

class _DriverPrivateRequestsScreenState extends State<DriverPrivateRequestsScreen> {
  Future<List<dynamic>>? _privateRequestsFuture;
  Map<String, dynamic>? _acceptedRequest;
  bool _isLoading = false;
  Timer? _requestsTimer;

  @override
  void initState() {
    super.initState();
    _loadRequests();
    _requestsTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      if (_acceptedRequest == null) {
        _loadRequests();
      }
    });
  }

  @override
  void dispose() {
    _requestsTimer?.cancel();
    super.dispose();
  }

  void _loadRequests() {
    if (!mounted) return;
    setState(() {
      _acceptedRequest = null;
      _privateRequestsFuture = ApiService.getAvailablePrivateRequests(widget.authResult.token);
    });
  }

  Future<void> _acceptRequest(Map<String, dynamic> request) async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.acceptPrivateRequest(widget.authResult.token, request['id'].toString());
      final data = json.decode(response.body);
      if (mounted) {
        if (response.statusCode == 200 && data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message']), backgroundColor: Colors.green));
          final activeRequestResponse = await ApiService.getAvailablePrivateRequests(widget.authResult.token);
          if (activeRequestResponse.isNotEmpty) {
            final updatedRequest = (activeRequestResponse).firstWhere((r) => r['id'] == request['id'], orElse: () => null);
            if (updatedRequest != null) {
              setState(() {
                _acceptedRequest = updatedRequest;
              });
            } else {
              _loadRequests();
            }
          }
        } else {
          throw Exception(data['message'] ?? 'فشل قبول الطلب');
        }
      }
    } on SocketException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى التحقق من اتصالك بالإنترنت'), backgroundColor: Colors.orange));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red));
        _loadRequests();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _endPrivateTrip(String requestId) async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.driverCompletePrivateRequest(widget.authResult.token, requestId);
      final data = json.decode(response.body);
      if (mounted) {
        if (response.statusCode == 200 && data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message']), backgroundColor: Colors.green));
          _loadRequests();
        } else {
          throw Exception(data['message'] ?? 'فشل إنهاء الرحلة');
        }
      }
    } on SocketException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى التحقق من اتصالك بالإنترنت'), backgroundColor: Colors.orange));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _acceptedRequest != null
              ? _buildActiveTripCard(_acceptedRequest!)
              : RefreshIndicator(
            onRefresh: () async => _loadRequests(),
            child: FutureBuilder<List<dynamic>>(
              future: _privateRequestsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.builder(itemCount: 4, itemBuilder: (ctx, i) => const ShimmerListItem());
                }
                if (snapshot.hasError) {
                  final error = snapshot.error;
                  String errorMessage = 'خطأ في تحميل البيانات';
                  if (error is SocketException) {
                    errorMessage = 'يرجى التحقق من اتصالك بالإنترنت';
                  } else if (error is Exception) {
                    errorMessage = error.toString().replaceAll("Exception: ", "");
                  }
                  return Center(child: Text(errorMessage));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const EmptyStateWidget(svgAsset: '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2L2 7l10 5 10-5-10-5z"></path><path d="M2 17l10 5 10-5"></path><path d="M2 12l10 5 10-5"></path></svg>''', message: 'لا توجد طلبات خصوصي متاحة حالياً.');
                }
                final requests = snapshot.data!;
                return AnimationLimiter(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      final request = requests[index];
                      return AnimationConfiguration.staggeredList(position: index, duration: const Duration(milliseconds: 375), child: SlideAnimation(verticalOffset: 50.0, child: FadeInAnimation(child: PrivateRequestCard(request: request, onAccept: () => _acceptRequest(request)))));
                    },
                  ),
                );
              },
            ),
          ),
          if (_isLoading) Container(color: Colors.black.withOpacity(0.3), child: const Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }

  Widget _buildActiveTripCard(Map<String, dynamic> request) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("الرحلة الخاصة الحالية", style: Theme.of(context).textTheme.headlineSmall),
                const Divider(height: 20),
                _buildInfoRow(Icons.person, "الزبون:", request['customer_name']),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.pin_drop, "من:", request['from']),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.flag, "إلى:", request['to']),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.payments_outlined, "السعر:", "${request['price']} د.ع"),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => makePhoneCall(request['phone'], context),
                    icon: const Icon(Icons.call),
                    label: const Text("الاتصال بالزبون"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: ChatIconWithBadge(
                      chatId: 'private_${request['id']}',
                      currentUserId: widget.authResult.userId,
                      onPressed: () {},
                    ),
                    label: const Text("التحدث مع الزبون"),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          chatId: 'private_${request['id']}',
                          chatName: 'محادثة مع ${request['customer_name']}',
                          authResult: widget.authResult,
                          participants: {
                            'customer': request['customer_id']?.toString(),
                            'driver': widget.authResult.userId,
                          },
                        ),
                      ));
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: ElevatedButton(onPressed: () => _endPrivateTrip(request['id'].toString()), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), child: const Text("إنهاء"))),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(children: [Icon(icon, color: Colors.grey[600], size: 20), const SizedBox(width: 8), Text(label, style: TextStyle(color: Colors.grey[700])), const SizedBox(width: 4), Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)))]);
  }
}
class PrivateRequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onAccept;
  const PrivateRequestCard({super.key, required this.request, required this.onAccept});
  @override
  Widget build(BuildContext context) {
    final bool isAccepted = request['status'] == 'accepted';
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shadowColor: isAccepted ? Colors.grey.withOpacity(0.2) : Colors.amber.withOpacity(0.2),
      shape: RoundedRectangleBorder(side: BorderSide(color: isAccepted ? Colors.grey : Colors.amber, width: 1.5), borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [const Icon(Icons.directions, color: Colors.blueAccent), const SizedBox(width: 8), Expanded(child: Text('${request['from']} → ${request['to']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))), if (request['with_return'] == true) const Chip(label: Text('مع عودة'), avatar: Icon(Icons.sync, size: 16), padding: EdgeInsets.zero)]),
            const Divider(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_buildInfoChip(Icons.access_time, request['time'], Colors.orange), _buildInfoChip(Icons.payments, '${request['price']} د.ع', Colors.green)]),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.person_outline, 'الزبون:', request['customer_name']),
            const SizedBox(height: 8),
            const Divider(height: 20),
            if (isAccepted) Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Text('تم قبول الطلب بواسطة سائق آخر', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)))) else SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: onAccept, icon: const Icon(Icons.check_circle_outline), label: const Text('قبول هذا الطلب'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green))),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Chip(avatar: Icon(icon, color: color, size: 18), label: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)), backgroundColor: color.withOpacity(0.1), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4));
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(children: [Icon(icon, color: Colors.grey[600], size: 20), const SizedBox(width: 8), Text(label, style: TextStyle(color: Colors.grey[700])), const SizedBox(width: 4), Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)))]);
  }
}

String _formatDate(String dateString) {
  try {
    return DateFormat('yyyy/MM/dd', 'en_US').format(DateTime.parse(dateString));
  } catch (e) {
    return dateString;
  }
}

class ChatIconWithBadge extends StatelessWidget {
  final String chatId;
  final String currentUserId;
  final VoidCallback onPressed;

  const ChatIconWithBadge({
    super.key,
    required this.chatId,
    required this.currentUserId,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('chats').doc(chatId).snapshots(),
      builder: (context, snapshot) {
        int unreadCount = 0;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          unreadCount = data['unreadCount']?[currentUserId] ?? 0;
        }

        return InkWell(
          onTap: onPressed,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.chat_bubble_outline, color: Colors.blue, size: 30),
              if (unreadCount > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      unreadCount.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center,
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

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String chatName;
  final AuthResult authResult;
  final Map<String, String?> participants;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.chatName,
    required this.authResult,
    required this.participants,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<types.Message> _messages = [];
  late final types.User _user;
  bool _isOtherUserTyping = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _user = types.User(id: widget.authResult.userId, firstName: widget.authResult.displayName);
    _loadMessages();
    _resetUnreadCount();
    _listenForTypingStatus();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _updateTypingStatus(false);
    super.dispose();
  }

  void _listenForTypingStatus() {
    FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final typingStatuses = data['typingStatus'] as Map<String, dynamic>? ?? {};
        final otherUserId = widget.participants.values.firstWhere(
              (id) => id != null && id != _user.id,
          orElse: () => null,
        );
        if (otherUserId != null && mounted) {
          setState(() {
            _isOtherUserTyping = typingStatuses[otherUserId] ?? false;
          });
        }
      }
    });
  }

  void _resetUnreadCount() {
    FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .set({
      'unreadCount': {
        _user.id: 0,
      }
    }, SetOptions(merge: true));
  }

  void _loadMessages() {
    FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.docs.isNotEmpty) return;
      final messages = snapshot.docs.map((doc) {
        final data = doc.data();
        return types.TextMessage(
          author: types.User(
            id: data['author']['id'] ?? '',
            firstName: data['author']['firstName'] ?? '',
          ),
          createdAt: (data['createdAt'] as Timestamp?)?.millisecondsSinceEpoch,
          id: doc.id,
          text: data['text'] ?? '',
        );
      }).toList();
      if (mounted) {
        setState(() {
          _messages = messages;
        });
      }
    });
  }

  void _handleSendPressed(types.PartialText message) {
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: message.text,
    );
    _addMessage(textMessage);
  }

  Future<void> _updateTypingStatus(bool isTyping) async {
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .set({
      'typingStatus': {
        _user.id: isTyping,
      }
    }, SetOptions(merge: true));
  }

  void _onTextChanged(String text) {
    if (_typingTimer?.isActive ?? false) _typingTimer?.cancel();
    _updateTypingStatus(true);
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _updateTypingStatus(false);
    });
  }

  void _addMessage(types.TextMessage message) {
    setState(() {
      _messages.insert(0, message);
    });

    final chatDocRef = FirebaseFirestore.instance.collection('chats').doc(widget.chatId);
    final recipientId = widget.participants.values.firstWhere(
          (id) => id != null && id != _user.id,
      orElse: () => null,
    );
    final messageData = {
      'author': message.author.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
      'text': message.text,
      'type': types.MessageType.text.name,
    };

    FirebaseFirestore.instance.runTransaction((transaction) async {
      transaction.set(chatDocRef.collection('messages').doc(), messageData);
      final updateData = {
        'lastMessage': {
          'text': message.text,
          'createdAt': FieldValue.serverTimestamp(),
          'authorId': _user.id,
        },
        'participants': widget.participants.values.where((id) => id != null).toList(),
      };
      if (recipientId != null) {
        updateData['unreadCount.$recipientId'] = FieldValue.increment(1);
      }
      transaction.set(chatDocRef, updateData, SetOptions(merge: true));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatName),
      ),
      body: Chat(
        messages: _messages,
        onSendPressed: _handleSendPressed,
        user: _user,
        showUserNames: true,
        theme: DefaultChatTheme(
          primaryColor: Colors.amber[700]!,
          secondaryColor: Colors.grey[200]!,
          inputBackgroundColor: Colors.white,
          inputTextColor: Colors.black,
          messageInsetsHorizontal: 12,
          messageInsetsVertical: 12,
        ),
        l10n: const ChatL10nEn(
          inputPlaceholder: 'اكتب رسالتك...',
        ),
        typingIndicatorOptions: TypingIndicatorOptions(
          typingUsers: _isOtherUserTyping ? [types.User(id: 'other')] : [],
        ),
      ),
    );
  }
}

class RatingDialog extends StatefulWidget {
  final String token;
  final String rideId;
  final String rideType;

  const RatingDialog({
    super.key,
    required this.token,
    required this.rideId,
    required this.rideType,
  });

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء تحديد تقييم (نجمة واحدة على الأقل)')));
      return;
    }
    setState(() => _isLoading = true);

    try {
      final response = await ApiService.rateRide(widget.token, {
        'ride_id': widget.rideId,
        'ride_type': widget.rideType,
        'rating': _rating,
        'comment': _commentController.text,
      });

      if (mounted) {
        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('شكراً لتقييمك!'), backgroundColor: Colors.green));
          Navigator.of(context).pop();
        } else {
          final data = json.decode(response.body);
          throw Exception(data['message'] ?? 'فشل إرسال التقييم');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تقييم الرحلة'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('كيف كانت تجربتك مع السائق؟'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 36,
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'أضف تعليقاً (اختياري)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('لاحقاً'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitRating,
          child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('إرسال التقييم'),
        ),
      ],
    );
  }
}

// --- (NEW WIDGET): This card is shown to the customer when a driver sends a counter-offer ---
class DriverOfferCard extends StatelessWidget {
  final Map<String, dynamic> offer;
  final VoidCallback onAccept;
  final VoidCallback onFindAnother;

  const DriverOfferCard({
    super.key,
    required this.offer,
    required this.onAccept,
    required this.onFindAnother,
  });

  @override
  Widget build(BuildContext context) {
    final driverDetails = offer['driver_details'] as Map<String, dynamic>? ?? {};
    final price = offer['price'] ?? 0;

    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "عرض السائق سعر اعلى هل توافق على السعر ام نبحث لكل عن سائق اخر ${driverDetails['name'] ?? 'سائق'}!",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 20),
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundImage: driverDetails['image'] != null && driverDetails['image'].isNotEmpty
                      ? NetworkImage(driverDetails['image'])
                      : null,
                  child: driverDetails['image'] == null || driverDetails['image'].isEmpty
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(driverDetails['name'] ?? 'سائق', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          Text(" ${(double.tryParse(driverDetails['average_rating']?.toString() ?? '')?.toStringAsFixed(1)) ?? 'N/A'}"),
                          const SizedBox(width: 12),
                          Text(driverDetails['vehicle_type'] ?? ''),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  "$price د.ع",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onFindAnother,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      side: BorderSide(color: Colors.grey.shade400),
                    ),
                    child: const Text('البحث عن آخر'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    child: const Text('قبول العرض'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
// --- شاشة إدارة الخطوط للسائق ---
class DriverLinesManagementScreen extends StatefulWidget {
  final AuthResult authResult;
  const DriverLinesManagementScreen({super.key, required this.authResult});

  @override
  State<DriverLinesManagementScreen> createState() => _DriverLinesManagementScreenState();
}

class _DriverLinesManagementScreenState extends State<DriverLinesManagementScreen> {
  Future<List<dynamic>>? _myLinesFuture;

  @override
  void initState() {
    super.initState();
    _loadMyLines();
  }

  Future<void> _loadMyLines() async {
    setState(() {
      _myLinesFuture = ApiService.getMyStudentLines(widget.authResult.token);
    });
  }

  void _navigateAndRefresh() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => DriverCreateStudentLineScreen(authResult: widget.authResult)),
    );
    if (result == true && mounted) {
      _loadMyLines();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadMyLines,
        child: FutureBuilder<List<dynamic>>(
          future: _myLinesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("خطأ في تحميل البيانات: ${snapshot.error.toString()}"));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return EmptyStateWidget(
                svgAsset: '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8zm-1-13h2v6h-2zm0 8h2v2h-2z"/></svg>''',
                message: 'لم تقم بإنشاء أي خطوط بعد.',
                buttonText: 'إنشاء خط جديد الآن',
                onButtonPressed: _navigateAndRefresh,
              );
            }
            final lines = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: lines.length,
              itemBuilder: (context, index) {
                final line = lines[index];
                final students = line['students'] as List? ?? [];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: const Icon(Icons.school_outlined),
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    ),
                    title: Text("خط إلى: ${line['destination_name']}"),
                    subtitle: Text("المشتركون: ${students.length} / ${line['total_seats']}"),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    // ========  الكود المصحح هنا ========
                    // تم تفعيل الانتقال إلى شاشة التفاصيل الجديدة
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DriverLineDetailsScreen(
                            line: line,
                            authResult: widget.authResult,
                            onDataChanged: _loadMyLines, // تمرير دالة التحديث
                          ),
                        ),
                      );
                    },
                    // ======== نهاية الكود المصحح ========
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateAndRefresh,
        label: const Text('إنشاء خط جديد'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }
}
class DriverCreateStudentLineScreen extends StatefulWidget {
  final AuthResult authResult;
  const DriverCreateStudentLineScreen({super.key, required this.authResult});

  @override
  State<DriverCreateStudentLineScreen> createState() => _DriverCreateStudentLineScreenState();
}

class _DriverCreateStudentLineScreenState extends State<DriverCreateStudentLineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _destinationController = TextEditingController();
  final _timeController = TextEditingController();
  final _priceController = TextEditingController();
  final _seatsController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _destinationController.dispose();
    _timeController.dispose();
    _priceController.dispose();
    _seatsController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        _timeController.text = picked.format(context);
      });
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);

    try {
      final body = {
        'destination_name': _destinationController.text,
        'start_time': _timeController.text,
        'price_per_seat': _priceController.text,
        'total_seats': _seatsController.text,
      };

      final response = await ApiService.createStudentLine(widget.authResult.token, body);
      final data = json.decode(response.body);

      if (mounted) {
        if (response.statusCode == 201 && data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message']), backgroundColor: Colors.green),
          );
          Navigator.of(context).pop(true); // الرجوع مع نتيجة إيجابية لتحديث القائمة
        } else {
          throw Exception(data['message'] ?? 'فشل إنشاء الخط');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء خط طلاب جديد'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _destinationController,
                decoration: const InputDecoration(labelText: 'اسم الوجهة (مثال: جامعة الكوت)'),
                validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _timeController,
                decoration: const InputDecoration(labelText: 'وقت الانطلاق', prefixIcon: Icon(Icons.access_time)),
                readOnly: true,
                onTap: _selectTime,
                validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'سعر الاشتراك (دينار عراقي)'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _seatsController,
                decoration: const InputDecoration(labelText: 'إجمالي المقاعد المتاحة'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('تأكيد وإنشاء الخط'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// =============================================================================
// 5. شاشة جديدة: تفاصيل خط الطلاب (للسائق)
class DriverLineDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> line;
  final AuthResult authResult;
  final VoidCallback onDataChanged; // Callback لتحديث الشاشة السابقة

  const DriverLineDetailsScreen({
    super.key,
    required this.line,
    required this.authResult,
    required this.onDataChanged,
  });

  @override
  State<DriverLineDetailsScreen> createState() => _DriverLineDetailsScreenState();
}

class _DriverLineDetailsScreenState extends State<DriverLineDetailsScreen> {
  late List<dynamic> _students;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // نسخ قائمة الطلاب إلى متغير محلي للسماح بالتعديل الفوري في الواجهة
    _students = List<dynamic>.from(widget.line['students'] ?? []);
  }

  Future<void> _updateStudentStatus(int studentIndex, String newStatus) async {
    setState(() => _isLoading = true);
    try {
      final body = {
        'line_id': widget.line['id'],
        'student_row_index': studentIndex, // Backend يتوقع index يبدأ من 0
        'new_status': newStatus,
      };
      final response = await ApiService.updateStudentStatus(widget.authResult.token, body);
      final data = json.decode(response.body);

      if (mounted) {
        if (response.statusCode == 200 && data['success'] == true) {
          // تحديث الحالة محلياً في الواجهة فوراً
          setState(() {
            _students[studentIndex]['pickup_status'] = newStatus;
          });
          widget.onDataChanged(); // إعلام الشاشة السابقة بوجود تغيير
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message']), backgroundColor: Colors.green),
          );
        } else {
          throw Exception(data['message'] ?? 'فشل تحديث الحالة');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // بناء قائمة المشاركين في المحادثة
    final Set<String> participantIds = {widget.authResult.userId}; // إضافة السائق
    for (var student in _students) {
      if (student['booked_by_user_id'] != null) {
        participantIds.add(student['booked_by_user_id'].toString());
      }
    }
    final Map<String, String> participantsMap = { for (var id in participantIds) id : id };


    return Scaffold(
      appBar: AppBar(
        title: Text("تفاصيل خط: ${widget.line['destination_name']}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'محادثة الخط',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ChatScreen(
                  chatId: 'line_${widget.line['id']}',
                  chatName: 'مجموعة خط ${widget.line['destination_name']}',
                  authResult: widget.authResult,
                  participants: participantsMap,
                ),
              ));
            },
          )
        ],
      ),
      body: Stack(
        children: [
          _students.isEmpty
              ? const Center(child: Text('لا يوجد طلاب مشتركين في هذا الخط بعد.'))
              : ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: _students.length,
            itemBuilder: (context, index) {
              final student = _students[index];
              return _StudentStatusCard(
                student: student,
                onUpdateStatus: (newStatus) {
                  _updateStudentStatus(index, newStatus);
                },
              );
            },
          ),
          if (_isLoading) Container(color: Colors.black.withOpacity(0.2), child: const Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }
}

// ويدجت جديد لعرض بطاقة الطالب بشكل عصري
class _StudentStatusCard extends StatelessWidget {
  final Map<String, dynamic> student;
  final Function(String) onUpdateStatus;

  const _StudentStatusCard({required this.student, required this.onUpdateStatus});

  @override
  Widget build(BuildContext context) {
    final currentStatus = student['pickup_status'] ?? 'pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // اسم الطالب
            Text(
              student['student_name'] ?? 'اسم غير معروف',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple),
            ),
            const Divider(height: 20),

            // معلومات الاتصال
            _buildContactRow(
              context,
              icon: Icons.person_outline,
              label: "هاتف الطالب:",
              phone: student['student_phone'],
              color: Colors.blue,
            ),
            const SizedBox(height: 8),
            _buildContactRow(
              context,
              icon: Icons.shield_outlined,
              label: "ولي الأمر:",
              phone: student['parent_phone'],
              color: Colors.green,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.location_on_outlined, "العنوان:", student['pickup_address']),

            const Divider(height: 20),

            // أزرار تحديث الحالة
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusButton(
                  context: context,
                  label: 'تم الصعود',
                  icon: Icons.directions_bus,
                  status: 'picked_up',
                  currentStatus: currentStatus,
                  onPressed: () => onUpdateStatus('picked_up'),
                ),
                _buildStatusButton(
                  context: context,
                  label: 'وصلنا',
                  icon: Icons.school,
                  status: 'dropped_off',
                  currentStatus: currentStatus,
                  onPressed: () => onUpdateStatus('dropped_off'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String? value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.grey[700])),
        const SizedBox(width: 4),
        Expanded(child: Text(value ?? 'غير محدد', style: const TextStyle(fontWeight: FontWeight.bold))),
      ],
    );
  }

  Widget _buildContactRow(BuildContext context, {required IconData icon, required String label, required String? phone, required Color color}) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.grey[700])),
        const SizedBox(width: 4),
        Expanded(child: Text(phone ?? 'غير متوفر', style: const TextStyle(fontWeight: FontWeight.bold))),
        IconButton(
          icon: Icon(Icons.call, color: color),
          onPressed: phone != null ? () => makePhoneCall(phone, context) : null,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Widget _buildStatusButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required String status,
    required String currentStatus,
    required VoidCallback onPressed,
  }) {
    final bool isActive = currentStatus == status;
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? Colors.teal : Colors.grey[300],
        foregroundColor: isActive ? Colors.white : Colors.black54,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// =============================================================================
// 2. شاشة تسجيل دخول أولياء الأمور
// =============================================================================
// هذه الشاشة الآن تقوم بتسجيل دخول كامل وتحفظ الجلسة



// =============================================================================
// 3. لوحة تحكم أولياء الأمور
// =============================================================================
// هذه هي الشاشة الرئيسية لولي الأمر بعد تسجيل الدخول

class ParentDashboardScreen extends StatefulWidget {
  final AuthResult authResult;
  final VoidCallback onLogout;
  const ParentDashboardScreen({super.key, required this.authResult, required this.onLogout});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  Future<Map<String, dynamic>?>? _activeLineFuture;

  @override
  void initState() {
    super.initState();
    _loadActiveLine();
  }

  Future<void> _loadActiveLine() async {
    setState(() {
      _activeLineFuture = _fetchData();
    });
  }

  Future<Map<String, dynamic>?> _fetchData() async {
    try {
      final phone = await ApiService._storage.read(key: 'phone_number');
      if (phone == null) {
        debugPrint("Parent phone number not found in storage.");
        return null;
      }

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/taxi/v2/student-lines/track-by-parent'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'phone_number': phone}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['active_line'] != null) {
          return Map<String, dynamic>.from(data['active_line']);
        }
      }
      return null;
    } catch (e) {
      debugPrint("Failed to fetch active line: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('مرحباً ${widget.authResult.displayName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'تسجيل الخروج',
            onPressed: widget.onLogout,
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadActiveLine,
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _activeLineFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('حدث خطأ أثناء تحميل البيانات.'));
            }
            if (snapshot.data == null) {
              return EmptyStateWidget(
                svgAsset: '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8zm-1-13h2v6h-2zm0 8h2v2h-2z"/></svg>''',
                message: 'لا توجد رحلات نشطة لأبنائك حالياً.',
              );
            }
            return ParentTrackingScreen(activeLineData: snapshot.data!);
          },
        ),
      ),
    );
  }
}
