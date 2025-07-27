import 'dart:async';
import 'dart:async';
import 'dart:convert';

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
// [FIXED] - Aliased the geolocator import to resolve name conflicts.
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:url_launcher/url_launcher.dart';

// [CHAT INTEGRATION] - Importing Firebase and Chat UI packages
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth; // Using alias to avoid conflicts
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:uuid/uuid.dart';

// [NEW] - Importing packages for Onboarding feature
import 'package:shared_preferences/shared_preferences.dart';
import 'package:introduction_screen/introduction_screen.dart';


// =============================================================================
//  Global Navigator Key & Deep Link Notifier
// =============================================================================
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final ValueNotifier<Map<String, String>> deepLinkNotifier = ValueNotifier({});


// =============================================================================
//  NEW: Firebase Cloud Messaging API Handler
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

    deepLinkNotifier.value = {
      'userType': userType,
      'targetScreen': targetScreen,
    };
  }

  Future<void> initPushNotifications() async {
    FirebaseMessaging.instance.getInitialMessage().then(handleMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      final notificationType = message.data['notification_type'] ?? 'default';
      NotificationService.showNotification(
        notification.title ?? 'إشعار جديد',
        notification.body ?? '',
        payload: json.encode(message.data),
        type: notificationType,
      );
    });
  }
}


// =============================================================================
//  Helper Classes & Functions
// =============================================================================
class LatLngTween extends Tween<LatLng> {
  LatLngTween({required LatLng begin, required LatLng end}) : super(begin: begin, end: end);
  @override
  LatLng lerp(double t) => LatLng(begin!.latitude + (end!.latitude - begin!.latitude) * t, begin!.longitude + (end!.longitude - begin!.longitude) * t);
}

double calculateBearing(LatLng startPoint, LatLng endPoint) {
  if (startPoint.latitude == endPoint.latitude && startPoint.longitude == endPoint.longitude) return 0.0;
  final lat1 = startPoint.latitudeInRad; final lon1 = startPoint.longitudeInRad;
  final lat2 = endPoint.latitudeInRad; final lon2 = endPoint.longitudeInRad;
  final dLon = lon2 - lon1;
  final y = sin(dLon) * cos(lat2);
  final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
  final bearing = atan2(y, x);
  return (bearing * 180 / pi + 360) % 360;
}

// [FIXED] - Removed the 'return' keyword to resolve the lint error.
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
//  Permission Service
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
//  Entry Point & App Theme
// =============================================================================
void main() async {
  // Ensure widgets are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // [CHAT INTEGRATION] - Initialize Firebase for the whole app
  await Firebase.initializeApp();
  await NotificationService.initialize();

  // [NEW ONBOARDING] - Check if onboarding should be shown
  final prefs = await SharedPreferences.getInstance();
  final showOnboarding = prefs.getBool('showOnboarding') ?? true;

  runApp(MyApp(showOnboarding: showOnboarding));
}

class MyApp extends StatelessWidget {
  // [NEW ONBOARDING] - Pass the flag to the app widget
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
      // [NEW ONBOARDING] - Conditionally show OnboardingScreen or AuthGate
      home: showOnboarding ? const OnboardingScreen() : const AuthGate(),
    );
  }
}

// =============================================================================
// [NEW] - Onboarding Screen
// =============================================================================
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  void _onDone(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showOnboarding', false);
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthGate()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // [FIXED] - Added 'const' to resolve the error.
    const pageDecoration = PageDecoration(
      titleTextStyle: TextStyle(fontSize: 28.0, fontWeight: FontWeight.w700, fontFamily: 'Cairo'),
      bodyTextStyle: TextStyle(fontSize: 19.0, fontFamily: 'Cairo'),
      bodyPadding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      pageColor: Colors.white,
      imagePadding: EdgeInsets.zero,
    );

    return IntroductionScreen(
      key: GlobalKey<IntroductionScreenState>(),
      pages: [
        PageViewModel(
          title: "الطلبات السريعة",
          body: "للتنقل داخل المدينة. حدد مكانك على الخريطة، ثم حدد الوجهة والسعر، وانتظر قبول أقرب سائق لطلبك.",
          image: const Center(child: Icon(Icons.map_outlined, size: 170.0, color: Colors.amber)),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "الرحلات المجدولة",
          body: "الانتقال بين  المحافظات؟اذهب  الى  الرحلات المتاحة واحجز مقعدك بسهولة مع سائقين موثوقين.",
          image: const Center(child: Icon(Icons.event_note_outlined, size: 170.0, color: Colors.blue)),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "الطلبات الخصوصية",
          body: "طلب سيارة خصوصي ؟ أنشئ طلباً خاصاً بتفاصيل رحلتك والسعر المقترح، وسيقوم السائقون بالتواصل معك.",
          image: const Center(child: Icon(Icons.star_outline, size: 170.0, color: Colors.green)),
          decoration: pageDecoration,
        ),
      ],
      onDone: () => _onDone(context),
      showSkipButton: true,
      skip: const Text('تخطي', style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Cairo')),
      next: const Icon(Icons.arrow_forward),
      done: const Text('ابدأ الآن', style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Cairo')),
      dotsDecorator: DotsDecorator(
        size: const Size(10.0, 10.0),
        color: const Color(0xFFBDBDBD),
        activeSize: const Size(22.0, 10.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25.0),
        ),
      ),
    );
  }
}


// =============================================================================
//  Models & Services
// =============================================================================
class AuthResult {
  final String token; final String userId; final String displayName; final bool isDriver; final String? driverStatus;
  AuthResult({required this.token, required this.userId, required this.displayName, required this.isDriver, this.driverStatus});
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
  static Future<void> clearAuthData() async => await _storage.deleteAll();
  static Future<AuthResult?> getStoredAuthData() async {
    final token = await _storage.read(key: 'auth_token'); final userId = await _storage.read(key: 'user_id');
    final displayName = await _storage.read(key: 'display_name'); final isDriverStr = await _storage.read(key: 'is_driver');
    final driverStatus = await _storage.read(key: 'driver_status');
    if (token != null && userId != null && displayName != null && isDriverStr != null) {
      return AuthResult(token: token, userId: userId, displayName: displayName, isDriver: isDriverStr.toLowerCase() == 'true', driverStatus: driverStatus);
    }
    return null;
  }
  static Future<void> updateFcmToken(String authToken, String fcmToken) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/taxi-auth/v1/update-fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken'
        },
        body: json.encode({'fcm_token': fcmToken}),
      );
    } catch (e) {
      debugPrint("Failed to update FCM token: $e");
    }
  }
  static Future<void> setDriverActiveStatus(String token, bool isActive) async {
    try { await http.post(Uri.parse('$baseUrl/taxi/v1/driver/set-active-status'), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}, body: json.encode({'is_active': isActive})); } catch (e) { debugPrint("Failed to set driver active status: $e"); }
  }
  static Future<void> updateDriverLocation(String token, LatLng location) async {
    try { await http.post(Uri.parse('$baseUrl/taxi/v1/driver/update-location'), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}, body: json.encode({'lat': location.latitude, 'lng': location.longitude})); } catch (e) { debugPrint("Failed to update driver location: $e"); }
  }
  static Future<List<dynamic>> fetchActiveDrivers(String token) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/taxi/v1/customer/active-drivers'), headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['drivers'] is List) return data['drivers'];
      }
      return [];
    } on SocketException {
      debugPrint("Network error fetching active drivers.");
      return [];
    } catch (e) { debugPrint("Failed to fetch active drivers: $e"); return []; }
  }
  static Future<LatLng?> getRideDriverLocation(String token, String rideId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/taxi/v1/rides/driver-location?ride_id=$rideId'), headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['location'] != null) {
          return LatLng(double.parse(data['location']['lat']), double.parse(data['location']['lng']));
        }
      }
      return null;
    } on SocketException {
      debugPrint("Network error getting driver location for ride.");
      return null;
    } catch (e) { debugPrint("Failed to get driver location for ride: $e"); return null; }
  }
  static Future<http.Response> createPrivateRequest(String token, Map<String, dynamic> body) {
    return http.post(Uri.parse('$baseUrl/taxi/v1/private-requests/create'), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}, body: json.encode(body));
  }
  static Future<List<dynamic>> getAvailablePrivateRequests(String token) async {
    final response = await http.get(Uri.parse('$baseUrl/taxi/v1/private-requests/available'), headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load private requests');
    }
  }
  static Future<http.Response> acceptPrivateRequest(String token, String requestId) {
    return http.post(Uri.parse('$baseUrl/taxi/v1/private-requests/accept'), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}, body: json.encode({'request_id': requestId}));
  }
  static Future<http.Response> getMyActivePrivateRequest(String token) {
    return http.get(Uri.parse('$baseUrl/taxi/v1/private-requests/my-active'), headers: {'Authorization': 'Bearer $token'});
  }

  // [MODIFIED] - This function is now used by the customer to cancel their private request.
  static Future<http.Response> cancelMyPrivateRequest(String token, String requestId) {
    return http.post(Uri.parse('$baseUrl/taxi/v1/private-requests/cancel'), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}, body: json.encode({'request_id': requestId}));
  }
}

// =============================================================================
//  MODIFIED: NotificationService (with Channels)
// =============================================================================
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _highImportanceChannel = AndroidNotificationChannel(
    'high_importance_channel', 'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.max, playSound: true,
  );

  static const AndroidNotificationChannel _defaultImportanceChannel = AndroidNotificationChannel(
    'default_importance_channel', 'Default Importance Notifications',
    description: 'This channel is used for general notifications.',
    importance: Importance.defaultImportance, playSound: true, enableVibration: true,
  );


  static Future<void> initialize() async {
    const InitializationSettings initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings("@mipmap/ic_launcher"),
      iOS: DarwinInitializationSettings(),
    );

    await _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(_highImportanceChannel);
    await _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(_defaultImportanceChannel);

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
        if (notificationResponse.payload != null) {
          try {
            final Map<String, dynamic> payloadData = json.decode(notificationResponse.payload!);
            deepLinkNotifier.value = {
              'userType': payloadData['userType'] ?? '',
              'targetScreen': payloadData['targetScreen'] ?? '',
            };
          } catch (e) { debugPrint('Error parsing notification payload: $e'); }
        }
      },
    );

    final NotificationAppLaunchDetails? notificationAppLaunchDetails = await _notificationsPlugin.getNotificationAppLaunchDetails();
    if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
      if (notificationAppLaunchDetails!.notificationResponse?.payload != null) {
        try {
          final Map<String, dynamic> payloadData = json.decode(notificationAppLaunchDetails.notificationResponse!.payload!);
          deepLinkNotifier.value = { 'userType': payloadData['userType'] ?? '', 'targetScreen': payloadData['targetScreen'] ?? '' };
        } catch (e) { debugPrint('Error parsing launch notification payload: $e'); }
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
//  UI Enhancement Widgets
// =============================================================================
class EmptyStateWidget extends StatelessWidget { final String svgAsset; final String message; final String? buttonText; final VoidCallback? onButtonPressed; const EmptyStateWidget({ super.key, required this.svgAsset, required this.message, this.buttonText, this.onButtonPressed }); @override Widget build(BuildContext context) { return Center(child: Padding(padding: const EdgeInsets.all(32.0), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [SvgPicture.string(svgAsset, height: 150, colorFilter: ColorFilter.mode(Colors.grey[400]!, BlendMode.srcIn)), const SizedBox(height: 24), Text(message, style: TextStyle(fontSize: 18, color: Colors.grey[700]), textAlign: TextAlign.center), const SizedBox(height: 24), if (buttonText != null && onButtonPressed != null) ElevatedButton(onPressed: onButtonPressed, child: Text(buttonText!))]))); } }
class ShimmerListItem extends StatelessWidget { const ShimmerListItem({super.key}); @override Widget build(BuildContext context) { return Shimmer.fromColors(baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!, child: Padding(padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 60.0, height: 60.0, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[const SizedBox(height: 8), Container(width: double.infinity, height: 10.0, color: Colors.white), const SizedBox(height: 8), Container(width: 150, height: 10.0, color: Colors.white)]))]))); } }
class RotatingVehicleIcon extends StatelessWidget { final String vehicleType; final double bearing; const RotatingVehicleIcon({super.key, required this.vehicleType, required this.bearing}); @override Widget build(BuildContext context) { const String carSvg = '''<svg viewBox="0 0 80 160" xmlns="http://www.w3.org/2000/svg"><defs><filter id="shadow" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur in="SourceAlpha" stdDeviation="3"/><feOffset dx="2" dy="5" result="offsetblur"/><feComponentTransfer><feFuncA type="linear" slope="0.5"/></feComponentTransfer><feMerge><feMergeNode/><feMergeNode in="SourceGraphic"/></feMerge></filter></defs><g transform="translate(0, 0)" filter="url(#shadow)"><path d="M25,10 C15,10 10,20 10,30 L10,130 C10,140 15,150 25,150 L55,150 C65,150 70,140 70,130 L70,30 C70,20 65,10 55,10 L25,10 Z" fill="#BDBDBD"/><path d="M20,25 C15,25 15,30 15,35 L15,70 L65,70 L65,35 C65,30 65,25 60,25 L20,25 Z" fill="#212121" opacity="0.8"/><path d="M15,80 L15,120 C15,125 20,125 20,125 L60,125 C65,125 65,120 65,120 L65,80 L15,80 Z" fill="#424242" opacity="0.7"/></g></svg>'''; const String tuktukSvg = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor"><path d="M20 17.17V10c0-2.21-1.79-4-4-4h-2.1c-.83-2.32-3.07-4-5.9-4-3.31 0-6 2.69-6 6s2.69 6 6 6c.34 0 .67-.04 1-.09V17H2v2h18v-2h-2zm-8-2c-1.1 0-2-.9-2-2s.9-2 2-2 2 .9 2 2-.9 2-2 2zM5 8c0-2.21 1.79-4 4-4s4 1.79 4 4-1.79 4-4 4-4-1.79-4-4z"/></svg>'''; return Transform.rotate(angle: bearing * (pi / 180), child: SvgPicture.string(vehicleType.toLowerCase() == 'tuktuk' ? tuktukSvg : carSvg)); } }
class PulsingUserLocationMarker extends StatefulWidget { const PulsingUserLocationMarker({super.key}); @override State<PulsingUserLocationMarker> createState() => _PulsingUserLocationMarkerState(); }
class _PulsingUserLocationMarkerState extends State<PulsingUserLocationMarker> with SingleTickerProviderStateMixin { late final AnimationController _controller; @override void initState() { super.initState(); _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true); } @override void dispose() { _controller.dispose(); super.dispose(); } @override Widget build(BuildContext context) { return AnimatedBuilder(animation: _controller, builder: (context, child) { return Stack(alignment: Alignment.center, children: [Container(width: 15 + (15 * _controller.value), height: 15 + (15 * _controller.value), decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withOpacity(0.8 - (0.8 * _controller.value)))), Container(width: 15, height: 15, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue, border: Border.all(color: Colors.white, width: 2)))]); }); } }

// =============================================================================
//  Authentication Gate & Welcome Screen
// =============================================================================
enum AuthStatus { unknown, authenticated, unauthenticated }
class AuthGate extends StatefulWidget { const AuthGate({super.key}); @override State<AuthGate> createState() => _AuthGateState(); }
class _AuthGateState extends State<AuthGate> {
  AuthStatus _authStatus = AuthStatus.unknown; AuthResult? _authResult;
  @override
  void initState() {
    super.initState();
    _checkAuth();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if(mounted) PermissionService.handleLocationPermission(context);
    });
  }
  Future<void> _checkAuth() async {
    final authData = await ApiService.getStoredAuthData();
    if (mounted) {
      _updateAuthStatus(authData);
      if (authData != null) {
        // [CHAT INTEGRATION] - Ensure Firebase anonymous sign-in and update FCM token
        await _ensureFirebaseSignIn();
        await FirebaseApi().initNotifications();
        final fcmToken = await FirebaseApi().getFcmToken();
        if (fcmToken != null) {
          await ApiService.updateFcmToken(authData.token, fcmToken);
        }
      }
    }
  }

  // [CHAT INTEGRATION] - New function to handle Firebase sign-in
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
    if (authData != null && authData.isDriver) { await ApiService.setDriverActiveStatus(authData.token, false); }
    await ApiService.clearAuthData();
    // [CHAT INTEGRATION] - Also sign out from Firebase to ensure clean state
    await fb_auth.FirebaseAuth.instance.signOut();
    _updateAuthStatus(null);
  }
  @override
  Widget build(BuildContext context) {
    switch (_authStatus) {
      case AuthStatus.unknown: return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.unauthenticated: return WelcomeScreen(onLoginSuccess: _updateAuthStatus);
      case AuthStatus.authenticated:
        if (_authResult!.isDriver) {
          if (_authResult!.driverStatus == 'approved') { return DriverMainScreen(authResult: _authResult!, onLogout: _logout); }
          else { return DriverPendingScreen(onLogout: _logout, onCheckStatus: _updateAuthStatus, phone: _authResult!.displayName); }
        } else { return CustomerMainScreen(authResult: _authResult!, onLogout: _logout); }
    }
  }
}

class WelcomeScreen extends StatefulWidget { final Function(AuthResult) onLoginSuccess; const WelcomeScreen({super.key, required this.onLoginSuccess}); @override State<WelcomeScreen> createState() => _WelcomeScreenState(); }
class _WelcomeScreenState extends State<WelcomeScreen> {
  final _nameController = TextEditingController(); final _phoneController = TextEditingController(); final _formKey = GlobalKey<FormState>(); bool _isLoading = false; String? _errorMessage;
  Future<void> _submitCustomerLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final response = await http.post(Uri.parse('${ApiService.baseUrl}/taxi-auth/v1/register/customer'), headers: {'Content-Type': 'application/json'}, body: json.encode({'name': _nameController.text, 'phone_number': _phoneController.text}));
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final authResult = AuthResult(token: data['token'], userId: data['user_id'].toString(), displayName: data['display_name'], isDriver: data['is_driver'] ?? false, driverStatus: data['driver_status']);
        await ApiService.storeAuthData(authResult);
        // [CHAT INTEGRATION] - Ensure Firebase sign-in after WordPress login
        if (fb_auth.FirebaseAuth.instance.currentUser == null) {
          await fb_auth.FirebaseAuth.instance.signInAnonymously();
        }
        await FirebaseApi().initNotifications();
        final fcmToken = await FirebaseApi().getFcmToken();
        if (fcmToken != null) {
          await ApiService.updateFcmToken(authResult.token, fcmToken);
        }
        widget.onLoginSuccess(authResult);
      } else { throw Exception(data['message'] ?? 'فشل تسجيل الدخول أو التسجيل'); }
    } on SocketException {
      if (mounted) setState(() => _errorMessage = 'يرجى التحقق من اتصالك بالإنترنت');
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString().replaceAll("Exception: ", ""));
    } finally { if(mounted) setState(() => _isLoading = false); }
  }
  @override
  Widget build(BuildContext context) {
    final String logoSvg = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200"><defs><linearGradient id="a" x1="50%" x2="50%" y1="0%" y2="100%"><stop offset="0%" stop-color="#FFD54F"/><stop offset="100%" stop-color="#FF8F00"/></linearGradient></defs><path fill="url(#a)" d="M100 10a90 90 0 1 0 0 180 90 90 0 0 0 0-180zm0 170a80 80 0 1 1 0-160 80 80 0 0 1 0 160z"/><path fill="#FFF" d="M149.5 115.8c-1.2-5.7-6.2-10-12.1-10H62.6c-5.9 0-10.9 4.3-12.1 10L40 140h120l-10.5-24.2zM67.3 85.2h65.4c2.8 0 5 2.2 5 5v10.6H62.3V90.2c0-2.8 2.2-5 5-5z"/><circle cx="70" cy="135" r="10" fill="#212121"/><circle cx="130" cy="135" r="10" fill="#212121"/></svg>''';
    return Scaffold(
      body: Container(
        width: double.infinity, height: double.infinity,
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
                  elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                          const SizedBox(height: 20),
                          if (_errorMessage != null) Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(_errorMessage!, style: const TextStyle(color: Colors.red))),
                          _isLoading ? const CircularProgressIndicator() : ElevatedButton(onPressed: _submitCustomerLogin, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)), child: const Text('دخول / تسجيل')),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                TextButton.icon(icon: const Icon(Icons.local_taxi), label: const Text('هل أنت سائق؟ اضغط هنا'), onPressed: () { if(mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => DriverAuthScreen(onLoginSuccess: widget.onLoginSuccess)));}, style: TextButton.styleFrom(foregroundColor: Colors.grey[800])),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
//  Generic Login & Driver Registration Screens
// =============================================================================
class LoginScreen extends StatefulWidget { final Function(AuthResult) onLoginSuccess; const LoginScreen({super.key, required this.onLoginSuccess}); @override State<LoginScreen> createState() => _LoginScreenState(); }
class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController(); final _formKey = GlobalKey<FormState>(); bool _isLoading = false; String? _errorMessage;
  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final response = await http.post(Uri.parse('${ApiService.baseUrl}/taxi-auth/v1/login'), headers: {'Content-Type': 'application/json'}, body: json.encode({'phone_number': _phoneController.text}));
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final authResult = AuthResult(token: data['token'], userId: data['user_id'].toString(), displayName: data['display_name'], isDriver: data['is_driver'] ?? false, driverStatus: data['driver_status']);
        await ApiService.storeAuthData(authResult);
        if (mounted) {
          // [CHAT INTEGRATION] - Ensure Firebase sign-in after WordPress login
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
      } else { throw Exception(data['message'] ?? 'فشل تسجيل الدخول'); }
    } on SocketException {
      if (mounted) setState(() => _errorMessage = 'يرجى التحقق من اتصالك بالإنترنت');
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString().replaceAll("Exception: ", ""));
    } finally { if(mounted) setState(() => _isLoading = false); }
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

class DriverAuthScreen extends StatelessWidget { final Function(AuthResult) onLoginSuccess; const DriverAuthScreen({super.key, required this.onLoginSuccess}); @override Widget build(BuildContext context) { return DefaultTabController(length: 2, initialIndex: 1, child: Scaffold(appBar: AppBar(title: const Text('بوابة السائقين'), bottom: const TabBar(tabs: [Tab(text: 'تسجيل دخول'), Tab(text: 'تسجيل جديد')])), body: TabBarView(children: [LoginScreen(onLoginSuccess: onLoginSuccess), DriverRegistrationScreen(onLoginSuccess: onLoginSuccess)]))); } }
class DriverRegistrationScreen extends StatefulWidget { final Function(AuthResult) onLoginSuccess; const DriverRegistrationScreen({super.key, required this.onLoginSuccess}); @override State<DriverRegistrationScreen> createState() => _DriverRegistrationScreenState(); }
class _DriverRegistrationScreenState extends State<DriverRegistrationScreen> {
  final _formKey = GlobalKey<FormState>(); final _nameController = TextEditingController(); final _phoneController = TextEditingController(); final _modelController = TextEditingController(); final _colorController = TextEditingController(); String _vehicleType = 'Tuktuk'; bool _isLoading = false; String? _errorMessage; final ImagePicker _picker = ImagePicker(); XFile? _registrationImageFile;
  Future<void> _pickImage() async { final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery); if (pickedFile != null) setState(() => _registrationImageFile = pickedFile); }
  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_registrationImageFile == null) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء رفع صورة سنوية السيارة'), backgroundColor: Colors.red));
      return;
    }
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      var request = http.MultipartRequest('POST', Uri.parse('${ApiService.baseUrl}/taxi-auth/v1/register/driver'));
      request.fields.addAll({'name': _nameController.text, 'phone': _phoneController.text, 'vehicle_type': _vehicleType, 'car_model': _modelController.text, 'car_color': _colorController.text});
      request.files.add(await http.MultipartFile.fromPath('vehicle_registration', _registrationImageFile!.path));
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = json.decode(response.body);
      if (response.statusCode == 201 && data['success'] == true) {
        if(mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message']), backgroundColor: Colors.green)); Navigator.of(context).pop(); }
      } else { throw Exception(data['message'] ?? 'فشل التسجيل'); }
    } on SocketException {
      if (mounted) setState(() => _errorMessage = 'يرجى التحقق من اتصالك بالإنترنت');
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString().replaceAll("Exception: ", ""));
    } finally { if(mounted) setState(() => _isLoading = false); }
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
            TextFormField(controller: _modelController, decoration: const InputDecoration(labelText: 'رقم لوحة المركبة '), validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null),
            const SizedBox(height: 15),
            TextFormField(controller: _colorController, decoration: const InputDecoration(labelText: 'لون وموديل المركبة'), validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  if (_registrationImageFile != null) ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(_registrationImageFile!.path), height: 150, width: double.infinity, fit: BoxFit.cover)),
                  TextButton.icon(icon: const Icon(Icons.upload_file), label: Text(_registrationImageFile == null ? 'رفع صورة سنوية السيارة' : 'تغيير الصورة'), onPressed: _pickImage),
                ],
              ),
            ),
            const SizedBox(height: 30),
            if (_errorMessage != null) Padding(padding: const EdgeInsets.only(bottom: 15), child: Text(_errorMessage!, style: const TextStyle(color: Colors.red))),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _isLoading ? null : _submit, child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('تسجيل حساب جديد'))),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
//  Customer Main Screen
// =============================================================================
class CustomerMainScreen extends StatefulWidget {
  final AuthResult authResult; final VoidCallback onLogout;
  const CustomerMainScreen({super.key, required this.authResult, required this.onLogout});
  @override
  State<CustomerMainScreen> createState() => _CustomerMainScreenState();
}
class _CustomerMainScreenState extends State<CustomerMainScreen> {
  // ## MODIFICATION: Default tab changed to 1 (Trips) ##
  int _selectedIndex = 1;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      QuickRideMapScreen(token: widget.authResult.token, authResult: widget.authResult),
      TripListScreen(authResult: widget.authResult),
      PrivateRequestFormScreen(authResult: widget.authResult),
    ];
    deepLinkNotifier.addListener(_handleDeepLink);
  }

  @override
  void dispose() {
    deepLinkNotifier.removeListener(_handleDeepLink);
    super.dispose();
  }

  void _handleDeepLink() {
    final linkData = deepLinkNotifier.value;
    if (linkData['userType'] == 'customer' && linkData['targetScreen'] == 'trips') {
      setState(() { _selectedIndex = 1; });
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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'طلب سريع'),
          BottomNavigationBarItem(icon: Icon(Icons.event_note_outlined), label: 'الرحلات '),
          BottomNavigationBarItem(icon: Icon(Icons.star_outline), label: 'طلب خصوصي '),
        ],
      ),
    );
  }
}

// =============================================================================
//  Driver Screens
// =============================================================================
class DriverPendingScreen extends StatefulWidget { final VoidCallback onLogout; final Function(AuthResult?) onCheckStatus; final String phone; const DriverPendingScreen({super.key, required this.onLogout, required this.phone, required this.onCheckStatus}); @override State<DriverPendingScreen> createState() => _DriverPendingScreenState(); }
class _DriverPendingScreenState extends State<DriverPendingScreen> {
  bool _isChecking = false;
  Future<void> _checkStatus() async {
    setState(() => _isChecking = true);
    try {
      final response = await http.post(Uri.parse('${ApiService.baseUrl}/taxi-auth/v1/login'), headers: {'Content-Type': 'application/json'}, body: json.encode({'phone_number': widget.phone}));
      final data = json.decode(response.body);
      if (mounted) {
        if (response.statusCode == 200 && data['success'] == true) {
          final authResult = AuthResult(token: data['token'], userId: data['user_id'].toString(), displayName: data['display_name'], isDriver: data['is_driver'] ?? false, driverStatus: data['driver_status']);
          await ApiService.storeAuthData(authResult);
          if (authResult.driverStatus == 'approved') {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت الموافقة على حسابك!'), backgroundColor: Colors.green));
            widget.onCheckStatus(authResult);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الحساب لا يزال قيد المراجعة.'), backgroundColor: Colors.orange));
          }
        } else { throw Exception(data['message'] ?? 'فشل التحقق'); }
      }
    } on SocketException {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى التحقق من اتصالك بالإنترنت'), backgroundColor: Colors.orange));
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red));
    } finally { if(mounted) setState(() => _isChecking = false); }
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

class DriverMainScreen extends StatefulWidget { final AuthResult authResult; final VoidCallback onLogout; const DriverMainScreen({super.key, required this.authResult, required this.onLogout}); @override State<DriverMainScreen> createState() => _DriverMainScreenState(); }
class _DriverMainScreenState extends State<DriverMainScreen> {
  int _selectedIndex = 0; bool _isDriverActive = false; StreamSubscription<geolocator.Position>? _positionStream; Map<String, dynamic>? _currentQuickRide;
  void _onRideAccepted(Map<String, dynamic> ride) { setState(() { _currentQuickRide = ride; }); }
  void _onRideFinished() { setState(() { _currentQuickRide = null; }); }
  @override
  void initState() { super.initState(); _checkLocationPermission(); deepLinkNotifier.addListener(_handleDeepLink); }
  @override
  void dispose() { deepLinkNotifier.removeListener(_handleDeepLink); _positionStream?.cancel(); if (_isDriverActive) ApiService.setDriverActiveStatus(widget.authResult.token, false); super.dispose(); }
  void _handleDeepLink() { final linkData = deepLinkNotifier.value; if (linkData['userType'] == 'driver' && linkData['targetScreen'] == 'private_requests') { _changeTab(1); deepLinkNotifier.value = {}; } }
  void _changeTab(int index) { setState(() { _selectedIndex = index; }); }
  Future<void> _checkLocationPermission() async { if(mounted) await PermissionService.handleLocationPermission(context); }

  // ## MODIFICATION: Improved location accuracy ##
  void _toggleActiveStatus(bool isActive) {
    setState(() => _isDriverActive = isActive);
    ApiService.setDriverActiveStatus(widget.authResult.token, isActive);
    if (isActive) {
      // Use best accuracy for navigation and remove distance filter
      _positionStream = geolocator.Geolocator.getPositionStream(locationSettings: const geolocator.LocationSettings(
          accuracy: geolocator.LocationAccuracy.bestForNavigation,
          distanceFilter: 0 // Update location with every small change
      )).listen((geolocator.Position position) => ApiService.updateDriverLocation(widget.authResult.token, LatLng(position.latitude, position.longitude)));
    } else {
      _positionStream?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _currentQuickRide == null ? DriverAvailableRidesScreen(authResult: widget.authResult, onRideAccepted: _onRideAccepted) : DriverCurrentRideScreen(initialRide: _currentQuickRide!, authResult: widget.authResult, onRideFinished: _onRideFinished),
      DriverPrivateRequestsScreen(authResult: widget.authResult),
      DriverMyTripsScreen(authResult: widget.authResult, navigateToCreate: () => _changeTab(3)),
      DriverCreateTripScreen(authResult: widget.authResult),
      NotificationsScreen(token: widget.authResult.token),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('واجهة السائق'),
        actions: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0), child: Row(children: [const Text("استقبال الطلبات", style: TextStyle(fontSize: 12)), Switch(value: _isDriverActive, onChanged: _toggleActiveStatus, activeColor: Colors.green)])),
          IconButton(icon: const Icon(Icons.logout), onPressed: widget.onLogout)
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, currentIndex: _selectedIndex, onTap: _changeTab,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list_alt_outlined), label: 'الطلبات'), BottomNavigationBarItem(icon: Icon(Icons.star_border_purple500_outlined), label: 'طلبات الخصوصي '), BottomNavigationBarItem(icon: Icon(Icons.directions_car_outlined), label: 'رحلاتي'), BottomNavigationBarItem(icon: Icon(Icons.add_road_outlined), label: 'إنشاء رحلة'), BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), label: 'الإشعارات'),
        ],
      ),
    );
  }
}

// =============================================================================
//  NEW: Modern Info Dialog
// =============================================================================
class ModernInfoDialog extends StatelessWidget {
  const ModernInfoDialog({super.key});
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)), elevation: 5, backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20.0), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))]),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.two_wheeler, color: Colors.amber, size: 50), const SizedBox(height: 16),
            Text("تنبيهات قسم الطلبات", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const Divider(height: 30),
            _buildInfoRow(context, Icons.location_city, "هذا القسم مخصص للطلبات داخل المدينة."), const SizedBox(height: 15),
            _buildInfoRow(context, Icons.toggle_on, "يجب تفعيل 'استقبال الطلبات' من الأعلى لتظهر لك الرحلات."), const SizedBox(height: 15),
            _buildInfoRow(context, Icons.info_outline, "القسم مصمم بشكل أساسي لمركبات التكتك."), const SizedBox(height: 24),
            ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text("حسناً، فهمت")),
          ],
        ),
      ),
    );
  }
  Widget _buildInfoRow(BuildContext context, IconData icon, String text) { return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: Theme.of(context).primaryColor, size: 22), const SizedBox(width: 12), Expanded(child: Text(text, style: const TextStyle(fontSize: 15, height: 1.5)))]); }
}


// =============================================================================
//  MODIFIED: DriverAvailableRidesScreen (with Sliding Panel)
// =============================================================================
class DriverAvailableRidesScreen extends StatefulWidget { final AuthResult authResult; final Function(Map<String, dynamic>) onRideAccepted; const DriverAvailableRidesScreen({super.key, required this.authResult, required this.onRideAccepted}); @override State<DriverAvailableRidesScreen> createState() => _DriverAvailableRidesScreenState(); }
class _DriverAvailableRidesScreenState extends State<DriverAvailableRidesScreen> {
  List<dynamic>? _availableRides; bool _isLoading = true; Timer? _ridesTimer;
  final MapController _mapController = MapController(); LatLng? _driverLocation; StreamSubscription<geolocator.Position>? _locationStream;
  @override
  void initState() { super.initState(); _fetchAvailableRides(); _ridesTimer = Timer.periodic(const Duration(seconds: 15), (timer) => _fetchAvailableRides()); _setupInitialLocation(); WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) { showDialog(context: context, builder: (context) => const ModernInfoDialog()); } }); }
  @override
  void dispose() { _ridesTimer?.cancel(); _locationStream?.cancel(); super.dispose(); }
  Future<void> _setupInitialLocation() async {
    final hasPermission = await PermissionService.handleLocationPermission(context);
    if (!hasPermission || !mounted) return;
    try {
      geolocator.Position position = await geolocator.Geolocator.getCurrentPosition(desiredAccuracy: geolocator.LocationAccuracy.high);
      if (mounted) {
        final initialLocation = LatLng(position.latitude, position.longitude);
        setState(() => _driverLocation = initialLocation);
        _mapController.move(initialLocation, 15.0);
      }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل تحديد موقعك الحالي.'))); }
    _locationStream = geolocator.Geolocator.getPositionStream(locationSettings: const geolocator.LocationSettings(accuracy: geolocator.LocationAccuracy.high, distanceFilter: 10)).listen((geolocator.Position position) { if (mounted) { setState(() { _driverLocation = LatLng(position.latitude, position.longitude); }); } });
  }
  Future<void> _fetchAvailableRides() async {
    try {
      final response = await http.get(Uri.parse('${ApiService.baseUrl}/taxi/v1/driver/available-rides'), headers: {'Authorization': 'Bearer ${widget.authResult.token}'});
      if (response.statusCode == 200 && mounted) { final data = json.decode(response.body); setState(() => _availableRides = data['rides']); }
    } on SocketException { debugPrint("Network error fetching available rides."); } catch (e) { debugPrint("Failed to fetch available rides: $e"); } finally { if (mounted) setState(() => _isLoading = false); }
  }
  Future<void> _acceptRide(String rideId) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(Uri.parse('${ApiService.baseUrl}/taxi/v1/driver/accept-ride'), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.authResult.token}'}, body: json.encode({'ride_id': rideId}));
      final data = json.decode(response.body);
      if (mounted) {
        if (response.statusCode == 200 && data['success'] == true) { widget.onRideAccepted(data['ride']); } else { throw Exception(data['message'] ?? 'فشل قبول الطلب'); }
      }
    } on SocketException {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى التحقق من اتصالك بالإنترنت'), backgroundColor: Colors.orange));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red));
      _fetchAvailableRides();
    } finally { if (mounted) setState(() => _isLoading = false); }
  }
  List<Marker> _buildMarkers() {
    List<Marker> markers = [];
    if (_driverLocation != null) { markers.add(Marker(point: _driverLocation!, width: 80, height: 80, child: const PulsingUserLocationMarker())); }
    if (_availableRides != null) {
      for (var ride in _availableRides!) {
        try {
          final lat = double.parse(ride['pickup']['lat']); final lng = double.parse(ride['pickup']['lng']);
          markers.add(Marker(point: LatLng(lat, lng), width: 40, height: 40, child: const Icon(Icons.pin_drop, color: Colors.red, size: 40)));
        } catch (e) { debugPrint("Could not parse ride location: $e"); }
      }
    }
    return markers;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController, options: MapOptions(initialCenter: _driverLocation ?? const LatLng(32.5, 45.8), initialZoom: 14.0),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.beytei.taxi'),
              MarkerLayer(markers: _buildMarkers()),
              RichAttributionWidget(attributions: [TextSourceAttribution('© OpenStreetMap contributors', onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')))]),
            ],
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.25, minChildSize: 0.25, maxChildSize: 0.8,
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.only(topLeft: Radius.circular(24.0), topRight: Radius.circular(24.0)), boxShadow: [BoxShadow(blurRadius: 10.0, color: Colors.black.withOpacity(0.2))]),
                child: Column(
                  children: [
                    Container(width: 40, height: 5, margin: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12))),
                    Expanded(
                      child: _isLoading ? ListView.builder(itemCount: 3, itemBuilder: (context, index) => const ShimmerListItem()) : _availableRides == null || _availableRides!.isEmpty ? const EmptyStateWidget(svgAsset: '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-coffee"><path d="M18 8h1a4 4 0 0 1 0 8h-1"></path><path d="M2 8h16v9a4 4 0 0 1-4 4H6a4 4 0 0 1-4-4V8z"></path><line x1="6" y1="1" x2="6" y2="4"></line><line x1="10" y1="1" x2="10" y2="4"></line><line x1="14" y1="1" x2="14" y2="4"></line></svg>''', message: 'لا توجد طلبات متاحة حالياً.') : RefreshIndicator(
                        onRefresh: _fetchAvailableRides,
                        child: AnimationLimiter(
                          child: ListView.builder(
                            controller: scrollController, padding: const EdgeInsets.all(8), itemCount: _availableRides!.length,
                            itemBuilder: (context, index) {
                              final ride = _availableRides![index];
                              return AnimationConfiguration.staggeredList(
                                position: index, duration: const Duration(milliseconds: 375),
                                child: SlideAnimation(
                                  verticalOffset: 50.0,
                                  child: FadeInAnimation(
                                    child: Card(
                                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                      child: ListTile(
                                        leading: const Icon(Icons.pin_drop_outlined, color: Colors.green),
                                        title: Text('طلب جديد بسعر: ${ride['price'] ?? 'N/A'} IQD'),
                                        subtitle: Text('تاريخ الطلب: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(ride['request_time']))}'),
                                        trailing: ElevatedButton(child: const Text('قبول'), onPressed: () => _acceptRide(ride['id'].toString())),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// =============================================================================
//  MODIFIED: DriverCurrentRideScreen (with Chat Icon & Immediate Route Drawing)
// =============================================================================
class DriverCurrentRideScreen extends StatefulWidget { final Map<String, dynamic> initialRide; final AuthResult authResult; final VoidCallback onRideFinished; const DriverCurrentRideScreen({super.key, required this.initialRide, required this.authResult, required this.onRideFinished}); @override State<DriverCurrentRideScreen> createState() => _DriverCurrentRideScreenState(); }
class _DriverCurrentRideScreenState extends State<DriverCurrentRideScreen> {
  late Map<String, dynamic> _currentRide; bool _isLoading = false; final MapController _mapController = MapController(); StreamSubscription<geolocator.Position>? _positionStream; LatLng? _driverLocation; List<LatLng> _routePoints = []; double _distanceToPickup = 0.0; double _driverBearing = 0.0; double _previousDriverBearing = 0.0;

  // ## MODIFICATION: `initState` now calls the new initialization method ##
  @override
  void initState() {
    super.initState();
    _currentRide = widget.initialRide;
    _initializeRide();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  // ## MODIFICATION: New method to immediately get location and draw route ##
  Future<void> _initializeRide() async {
    // 1. Get customer's location from ride data
    final pickupPoint = LatLng(double.parse(_currentRide['pickup']['lat']), double.parse(_currentRide['pickup']['lng']));

    // 2. Get driver's current location immediately
    try {
      final hasPermission = await PermissionService.handleLocationPermission(context);
      if (!hasPermission || !mounted) return;

      geolocator.Position currentPosition = await geolocator.Geolocator.getCurrentPosition(desiredAccuracy: geolocator.LocationAccuracy.high);
      final driverNowLocation = LatLng(currentPosition.latitude, currentPosition.longitude);

      if (mounted) {
        setState(() {
          _driverLocation = driverNowLocation;
        });
        // 3. Draw the route immediately
        _getRoute(driverNowLocation, pickupPoint);
        _mapController.move(driverNowLocation, 15);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل تحديد موقعك لبدء رسم المسار')));
      }
    }

    // 4. Start continuous location tracking
    _startDriverLocationTracking();
  }

  // ## MODIFICATION: This method now only handles continuous updates ##
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
    // SECURITY WARNING: Hardcoding API keys is a security risk.
    // Use --dart-define for production apps.
    const String orsApiKey = 'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjVhMDU5ODAxNDA5Y2E5MzIyNDQwOTYxMWQxY2ZhYmQ5NGQ3YTA5ZmI1ZjQ5ZWRlNjcxNGRlMTUzIiwiaCI6Im11cm11cjY0In0=';
    if (orsApiKey.length < 50) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("الرجاء إضافة مفتاح API صحيح لرسم المسار"), backgroundColor: Colors.red)); return; }
    final url = 'https://api.openrouteservice.org/v2/directions/driving-car?api_key=$orsApiKey&start=${start.longitude},${start.latitude}&end=${end.longitude},${end.latitude}';
    try {
      final response = await http.get(Uri.parse(url));
      if (mounted) {
        if (response.statusCode == 200) {
          final data = json.decode(response.body); final coordinates = data['features'][0]['geometry']['coordinates'] as List;
          setState(() => _routePoints = coordinates.map((c) => LatLng(c[1], c[0])).toList());
        } else { if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("فشل رسم المسار: ${json.decode(response.body)['error']?['message'] ?? 'خطأ من الخادم'}"), backgroundColor: Colors.red)); }
      }
    } on SocketException { if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("فشل رسم المسار: تحقق من اتصالك بالإنترنت"), backgroundColor: Colors.orange)); } catch (e) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("فشل رسم المسار: ${e.toString().replaceAll("Exception: ", "")}"), backgroundColor: Colors.red)); }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(Uri.parse('${ApiService.baseUrl}/taxi/v1/driver/update-ride-status'), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.authResult.token}'}, body: json.encode({'ride_id': _currentRide['id'], 'status': newStatus}));
      final data = json.decode(response.body);
      if (mounted) {
        if (response.statusCode == 200 && data['success'] == true) {
          if (newStatus == 'completed' || newStatus == 'cancelled') { widget.onRideFinished(); } else {
            setState(() => _currentRide = data['ride']);
            if (newStatus == 'ongoing' && _driverLocation != null && _currentRide['destination']?['lat'] != null) {
              final destination = LatLng(double.parse(_currentRide['destination']['lat']), double.parse(_currentRide['destination']['lng']));
              _getRoute(_driverLocation!, destination);
            }
          }
        } else { throw Exception(data['message'] ?? 'فشل تحديث الحالة'); }
      }
    } on SocketException { if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى التحقق من اتصالك بالإنترنت'), backgroundColor: Colors.orange)); } catch (e) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red)); } finally { if(mounted) setState(() => _isLoading = false); }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('الرحلة الحالية'),
        actions: [
          // [MODIFIED] - Clearer Chat Button
          TextButton.icon(
            icon: ChatIconWithBadge(
              chatId: 'ride_${_currentRide['id']}',
              currentUserId: widget.authResult.userId,
              onPressed: () {}, // Action is handled by the parent button
            ),
            label: const Text("التحدث مع الزبون"),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ChatScreen(
                  chatId: 'ride_${_currentRide['id']}',
                  chatName: 'محادثة مع زبون',
                  authResult: widget.authResult,
                  participants: {
                    'customer': _currentRide['customer']?['id']?.toString(),
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
            mapController: _mapController, options: MapOptions(initialCenter: pickupPoint, initialZoom: 14.0),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.beytei.taxi'),
              if (_routePoints.isNotEmpty) PolylineLayer(polylines: [Polyline(points: _routePoints, color: Colors.blue, strokeWidth: 6)]),
              MarkerLayer(markers: [
                Marker(point: pickupPoint, child: const Icon(Icons.location_on, color: Colors.green, size: 40)),
                if (destinationPoint != null) Marker(point: destinationPoint, child: const Icon(Icons.flag, color: Colors.red, size: 40)),
                if (_driverLocation != null) Marker(point: _driverLocation!, width: 40, height: 40, child: TweenAnimationBuilder<double>(tween: Tween<double>(begin: _previousDriverBearing, end: _driverBearing), duration: const Duration(milliseconds: 800), builder: (context, value, child) { return RotatingVehicleIcon(vehicleType: _currentRide['driver']?['vehicle_type'] ?? 'Car', bearing: value); })),
              ]),
              RichAttributionWidget(attributions: [TextSourceAttribution('© OpenStreetMap contributors', onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')))]),
            ],
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Card(
              margin: const EdgeInsets.all(12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text('حالة الرحلة: $status', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    if(status == 'accepted') Text("المسافة إلى العميل: ${(_distanceToPickup / 1000).toStringAsFixed(2)} كم"),
                    const Divider(),
                    const SizedBox(height: 15),
                    _buildActionButton(),
                    if(status != 'completed' && status != 'cancelled') TextButton.icon(icon: const Icon(Icons.cancel, color: Colors.red), label: const Text('إلغاء الرحلة', style: TextStyle(color: Colors.red)), onPressed: _isLoading ? null : () => _updateStatus('cancelled'))
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
//  Customer Quick Ride Screen (Refactored)
// =============================================================================
enum BookingStage { selectingPickup, selectingDestination, confirmingRequest }
class QuickRideMapScreen extends StatefulWidget { final String token; final AuthResult authResult; const QuickRideMapScreen({super.key, required this.token, required this.authResult}); @override State<QuickRideMapScreen> createState() => _QuickRideMapScreenState(); }
class _QuickRideMapScreenState extends State<QuickRideMapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController(); Map<String, dynamic>? _activeRide; bool _isLoading = true; Timer? _statusTimer; final _priceController = TextEditingController(); Map<String, dynamic> _driversData = {}; Map<String, AnimationController> _animationControllers = {}; Map<String, Animation<LatLng>> _animations = {}; Map<String, ({LatLng begin, LatLng end})> _driverAnimationSegments = {}; Timer? _driversTimer; final Map<String, double> _lastBearings = {};
  BookingStage _bookingStage = BookingStage.selectingPickup; LatLng? _pickupLocation; LatLng? _destinationLocation; LatLng? _currentUserLocation; StreamSubscription<geolocator.Position>? _locationStream;
  LatLng? _assignedDriverLocation; Timer? _liveTrackingTimer; List<LatLng> _routeToCustomer = []; double _assignedDriverBearing = 0.0; double _previousAssignedDriverBearing = 0.0;
  @override
  void initState() { super.initState(); _setupInitialLocation(); _checkForActiveRide(); _driversTimer = Timer.periodic(const Duration(seconds: 5), (timer) { if (_activeRide == null) _fetchActiveDrivers(); }); }
  @override
  void dispose() { _statusTimer?.cancel(); _driversTimer?.cancel(); _liveTrackingTimer?.cancel(); _locationStream?.cancel(); _priceController.dispose(); for (var controller in _animationControllers.values) { controller.dispose(); } super.dispose(); }
  Future<void> _setupInitialLocation() async {
    final hasPermission = await PermissionService.handleLocationPermission(context);
    if (!hasPermission || !mounted) return;
    try {
      geolocator.Position position = await geolocator.Geolocator.getCurrentPosition(desiredAccuracy: geolocator.LocationAccuracy.bestForNavigation);
      if (mounted) {
        final initialLocation = LatLng(position.latitude, position.longitude);
        setState(() { _currentUserLocation = initialLocation; _pickupLocation = initialLocation; });
        _mapController.move(initialLocation, 16.0);
      }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل تحديد الموقع الأولي.'))); }
    _locationStream = geolocator.Geolocator.getPositionStream(locationSettings: const geolocator.LocationSettings(accuracy: geolocator.LocationAccuracy.high, distanceFilter: 10)).listen((geolocator.Position position) { if (mounted) { setState(() { _currentUserLocation = LatLng(position.latitude, position.longitude); }); } });
  }
  Future<void> _checkForActiveRide() async { setState(() => _isLoading = false); }
  void _startLiveTracking(String rideId) {
    _liveTrackingTimer?.cancel();
    _liveTrackingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_activeRide == null) { timer.cancel(); return; }
      final newDriverLocation = await ApiService.getRideDriverLocation(widget.token, rideId);
      if (mounted && newDriverLocation != null) {
        double newBearing = _assignedDriverBearing;
        if (_assignedDriverLocation != null) { newBearing = calculateBearing(_assignedDriverLocation!, newDriverLocation); }
        setState(() { _previousAssignedDriverBearing = _assignedDriverBearing; _assignedDriverLocation = newDriverLocation; _assignedDriverBearing = newBearing; });
        final pickupPoint = LatLng(double.parse(_activeRide!['pickup']['lat']), double.parse(_activeRide!['pickup']['lng']));
        _getRoute(_assignedDriverLocation!, pickupPoint);
      }
    });
  }
  void _stopLiveTracking() { _liveTrackingTimer?.cancel(); if (mounted) setState(() { _assignedDriverLocation = null; _routeToCustomer.clear(); }); }
  Future<void> _getRoute(LatLng start, LatLng end) async {
    // SECURITY WARNING: Hardcoding API keys is a security risk.
    // Use --dart-define for production apps.
    const String orsApiKey = 'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjVhMDU5ODAxNDA5Y2E5MzIyNDQwOTYxMWQxY2ZhYmQ5NGQ3YTA5ZmI1ZjQ5ZWRlNjcxNGRlMTUzIiwiaCI6Im11cm11cjY0In0=';
    if (orsApiKey.length < 50) { return; }
    final url = 'https://api.openrouteservice.org/v2/directions/driving-car?api_key=$orsApiKey&start=${start.longitude},${start.latitude}&end=${end.longitude},${end.latitude}';
    try {
      final response = await http.get(Uri.parse(url));
      if (mounted && response.statusCode == 200) {
        final data = json.decode(response.body); final coordinates = data['features'][0]['geometry']['coordinates'] as List;
        setState(() => _routeToCustomer = coordinates.map((c) => LatLng(c[1], c[0])).toList());
      }
    } catch (e) { debugPrint("ORS Exception: ${e.toString()}"); }
  }
  Future<void> _fetchActiveDrivers() async {
    if (!mounted || _activeRide != null) return;
    try {
      final driversList = await ApiService.fetchActiveDrivers(widget.token);
      if (!mounted) return;
      final newDriversData = {for (var d in driversList) d['driver_id'].toString(): d};
      for (var driverId in newDriversData.keys) {
        final oldDriver = _driversData[driverId]; final newDriver = newDriversData[driverId];
        final newPosition = LatLng(double.parse(newDriver['lat']), double.parse(newDriver['lng']));
        if (oldDriver != null) {
          final oldPosition = LatLng(double.parse(oldDriver['lat']), double.parse(oldDriver['lng']));
          if (oldPosition != newPosition) {
            final controller = AnimationController(duration: const Duration(seconds: 4), vsync: this);
            final animation = LatLngTween(begin: oldPosition, end: newPosition).animate(controller);
            _animationControllers[driverId] = controller; _animations[driverId] = animation;
            _driverAnimationSegments[driverId] = (begin: oldPosition, end: newPosition); controller.forward();
          }
        } else { _driverAnimationSegments[driverId] = (begin: newPosition, end: newPosition); }
      }
      setState(() => _driversData = newDriversData);
    } catch (e) { debugPrint("Error fetching drivers: $e"); }
  }
  void _startStatusTimer() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 5), (timer) async { if (!mounted || _activeRide == null) { timer.cancel(); return; } _fetchRideStatus(); });
  }
  Future<void> _fetchRideStatus() async {
    if (_activeRide == null) return;
    try {
      final response = await http.get(Uri.parse('${ApiService.baseUrl}/taxi/v1/rides/status?ride_id=${_activeRide!['id']}'), headers: {'Authorization': 'Bearer ${widget.token}'});
      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final updatedRide = data['ride'];
          final bool statusChanged = _activeRide?['status'] != updatedRide['status'];
          final bool driverAssigned = _activeRide?['driver'] == null && updatedRide['driver'] != null;
          if (statusChanged || driverAssigned) { setState(() { _activeRide = updatedRide; }); }
          if (updatedRide['status'] == 'accepted' && _assignedDriverLocation == null) { _stopLiveTracking(); _startLiveTracking(updatedRide['id'].toString()); } else if (['completed', 'cancelled'].contains(updatedRide['status'])) { _resetBookingState(); }
        }
      }
    } catch (e) { debugPrint("Failed to get ride status: $e"); }
  }
  Future<void> _requestRide() async {
    if (_pickupLocation == null) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء تحديد نقطة الانطلاق على الخريطة.'))); return; }
    if (_priceController.text.isEmpty) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء تحديد سعر الكروة.'))); return; }
    final bool? confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('تأكيد الطلب'), content: Text('هل أنت متأكد من طلب رحلة من الموقع المحدد إلى الوجهة المحددة بسعر ${_priceController.text} د.ع؟'), actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('تعديل')), ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('تأكيد وإرسال'))]));
    if (confirmed != true) return;
    setState(() => _isLoading = true);
    try {
      final response = await http.post(Uri.parse('${ApiService.baseUrl}/taxi/v1/rides/request'), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'}, body: json.encode({'pickup': {'lat': _pickupLocation!.latitude, 'lng': _pickupLocation!.longitude}, 'destination': _destinationLocation != null ? {'lat': _destinationLocation!.latitude, 'lng': _destinationLocation!.longitude} : {}, 'price': _priceController.text}));
      final data = json.decode(response.body);
      if (mounted) {
        if (response.statusCode == 201 && data['success'] == true) { setState(() => _activeRide = data['ride']); _startStatusTimer(); } else { throw Exception(data['message'] ?? 'فشل إرسال الطلب'); }
      }
    } on SocketException { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى التحقق من اتصالك بالإنترنت'), backgroundColor: Colors.orange)); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red)); } finally { if (mounted) setState(() => _isLoading = false); }
  }
  Future<void> _cancelRide() async {
    if (_activeRide == null) return;
    setState(() => _isLoading = true);
    try {
      final rideId = _activeRide!['id'];
      final response = await http.post(Uri.parse('${ApiService.baseUrl}/taxi/v1/rides/cancel'), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'}, body: json.encode({'ride_id': rideId}));
      final data = json.decode(response.body);
      if (mounted) {
        if(response.statusCode == 200 && data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إلغاء الطلب بنجاح'), backgroundColor: Colors.green));
          _resetBookingState();
        } else {
          final errorMessage = data['message'] ?? 'فشل الإلغاء';
          if (errorMessage.contains("لا يمكن إلغاء الطلب بعد قبوله")) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم قبول الطلب بواسطة سائق!'), backgroundColor: Colors.orange));
            await _fetchRideStatus();
          } else { throw Exception(errorMessage); }
        }
      }
    } on SocketException { if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى التحقق من اتصالك بالإنترنت'), backgroundColor: Colors.orange)); } catch (e) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red)); } finally { if(mounted) setState(() => _isLoading = false); }
  }
  void _resetBookingState() { _statusTimer?.cancel(); _stopLiveTracking(); setState(() { _activeRide = null; _bookingStage = BookingStage.selectingPickup; _destinationLocation = null; _priceController.clear(); _pickupLocation = _currentUserLocation; }); }
  List<Marker> _buildMarkers() {
    final List<Marker> markers = [];
    if (_currentUserLocation != null) { markers.add(Marker(width: 80, height: 80, point: _currentUserLocation!, child: const PulsingUserLocationMarker())); }
    if (_activeRide != null) {
      if (_assignedDriverLocation != null) { markers.add(Marker(width: 40, height: 40, point: _assignedDriverLocation!, child: TweenAnimationBuilder<double>(tween: Tween<double>(begin: _previousAssignedDriverBearing, end: _assignedDriverBearing), duration: const Duration(milliseconds: 800), builder: (context, value, child) { return RotatingVehicleIcon(vehicleType: _activeRide!['driver']?['vehicle_type'] ?? 'Car', bearing: value); }))); }
      final pickupLatLng = LatLng(double.parse(_activeRide!['pickup']['lat']), double.parse(_activeRide!['pickup']['lng']));
      markers.add(Marker(point: pickupLatLng, child: const Icon(Icons.location_on, color: Colors.green, size: 40)));
    } else {
      for (var driverId in _driversData.keys) {
        final driver = _driversData[driverId]; final animation = _animations[driverId]; final segment = _driverAnimationSegments[driverId];
        if (animation != null && segment != null) {
          final currentPosition = animation.value; final bearing = calculateBearing(segment.begin, segment.end); final previousBearing = _lastBearings[driverId] ?? bearing;
          _lastBearings[driverId] = bearing;
          markers.add(Marker(width: 40, height: 40, point: currentPosition, child: TweenAnimationBuilder<double>(tween: Tween<double>(begin: previousBearing, end: bearing), duration: const Duration(seconds: 1), builder: (context, value, child) { return RotatingVehicleIcon(vehicleType: driver['vehicle_type']?.toString() ?? 'Car', bearing: value); })));
        }
      }
      if (_bookingStage != BookingStage.selectingPickup && _pickupLocation != null) { markers.add(Marker(point: _pickupLocation!, width: 80, height: 80, child: const Icon(Icons.location_on, color: Colors.orange, size: 40))); }
      if (_bookingStage == BookingStage.confirmingRequest && _destinationLocation != null) { markers.add(Marker(point: _destinationLocation!, width: 80, height: 80, child: const Icon(Icons.flag, color: Colors.blue, size: 40))); }
    }
    return markers;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController, options: MapOptions(initialCenter: const LatLng(32.5, 45.8), initialZoom: 15.0, onPositionChanged: (position, hasGesture) { if (hasGesture && _activeRide == null) { if (_bookingStage == BookingStage.selectingPickup) { setState(() => _pickupLocation = position.center); } else if (_bookingStage == BookingStage.selectingDestination) { setState(() => _destinationLocation = position.center); } } }),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.beytei.taxi'),
              if (_routeToCustomer.isNotEmpty) PolylineLayer(polylines: [Polyline(points: _routeToCustomer, color: Colors.blue, strokeWidth: 6)]),
              MarkerLayer(markers: _buildMarkers()),
              RichAttributionWidget(attributions: [TextSourceAttribution('© OpenStreetMap contributors', onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')))]),
            ],
          ),
          if (_activeRide == null && (_bookingStage == BookingStage.selectingPickup || _bookingStage == BookingStage.selectingDestination)) Center(child: Padding(padding: const EdgeInsets.only(bottom: 40.0), child: Icon(Icons.location_pin, color: _bookingStage == BookingStage.selectingPickup ? Colors.orange : Colors.blue, size: 50))),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          if (!_isLoading && _activeRide != null) Positioned(bottom: 0, left: 0, right: 0, child: ActiveRideInfoCard(ride: _activeRide!, onCancel: _cancelRide, authResult: widget.authResult)) else if (!_isLoading) Positioned(bottom: 0, left: 0, right: 0, child: _buildRequestCard()),
          if (!_isLoading) Positioned(bottom: (_activeRide == null) ? 230 : 160, right: 20, child: FloatingActionButton(onPressed: () { if (_currentUserLocation != null) { _mapController.move(_currentUserLocation!, 16.0); } }, backgroundColor: Colors.white, child: const Icon(Icons.my_location, color: Colors.blue))),
        ],
      ),
    );
  }
  Widget _buildRequestCard() {
    return Card(
      margin: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_bookingStage == BookingStage.selectingPickup) ...[
              Text("حرك الخريطة لتحديد نقطة الانطلاق", style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => setState(() { _bookingStage = BookingStage.selectingDestination; _destinationLocation = _mapController.camera.center; }), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange), child: const Text('تأكيد نقطة الانطلاق'))),
            ],
            if (_bookingStage == BookingStage.selectingDestination) ...[
              Text("حرك الخريطة لتحديد الوجهة (اختياري)", style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => setState(() => _bookingStage = BookingStage.confirmingRequest), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue), child: const Text('تأكيد الوجهة'))),
              TextButton(onPressed: () => setState(() { _destinationLocation = null; _bookingStage = BookingStage.confirmingRequest; }), child: const Text("تخطي وتحديد السعر"))
            ],
            if (_bookingStage == BookingStage.confirmingRequest) ...[
              Row(children: [const Icon(Icons.my_location, color: Colors.orange), const SizedBox(width: 8), const Expanded(child: Text('نقطة الانطلاق', style: TextStyle(fontWeight: FontWeight.bold))), TextButton(onPressed: () => setState(() => _bookingStage = BookingStage.selectingPickup), child: const Text("تغيير"))]),
              const Divider(),
              Row(children: [const Icon(Icons.flag_outlined, color: Colors.blue), const SizedBox(width: 8), Expanded(child: Text(_destinationLocation != null ? 'الوجهة' : 'بدون وجهة', style: const TextStyle(fontWeight: FontWeight.bold))), TextButton(onPressed: () => setState(() => _bookingStage = BookingStage.selectingDestination), child: const Text("تغيير"))]),
              const SizedBox(height: 12),
              TextField(controller: _priceController, keyboardType: const TextInputType.numberWithOptions(decimal: false), decoration: const InputDecoration(labelText: 'السعر المعروض (الكروة)', prefixIcon: Icon(Icons.money))), const SizedBox(height: 15),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _requestRide, style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text('اطلب الآن'))),
            ],
          ],
        ),
      ),
    );
  }
}


class ActiveRideInfoCard extends StatelessWidget {
  final Map<String, dynamic> ride; final VoidCallback onCancel; final AuthResult authResult;
  const ActiveRideInfoCard({super.key, required this.ride, required this.onCancel, required this.authResult});
  String _getStatusText(String status) {
    switch (status) {
      case 'pending': return 'جاري البحث عن سائق...'; case 'accepted': return 'تم قبول طلبك! السائق في الطريق...'; case 'arrived_pickup': return 'السائق وصل لنقطة الانطلاق'; case 'ongoing': return 'الرحلة جارية...'; case 'completed': return 'اكتملت الرحلة'; case 'cancelled': return 'تم إلغاء الرحلة'; default: return 'حالة غير معروفة';
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
                    // [MODIFIED] - Clearer Chat Button
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ChatIconWithBadge(
                          chatId: 'ride_${ride['id']}',
                          currentUserId: authResult.userId,
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                chatId: 'ride_${ride['id']}',
                                chatName: 'محادثة مع ${driver['name'] ?? 'السائق'}',
                                authResult: authResult,
                                participants: {
                                  'customer': authResult.userId,
                                  'driver': driver['id']?.toString(),
                                },
                              ),
                            ));
                          },
                        ),
                        const Text("تحدث مع السائق", style: TextStyle(fontSize: 8)),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.call, color: Colors.green), onPressed: () => makePhoneCall(driver['phone'], context)),
                  ],
                ),
              )
            else
              const Text('بانتظار قبول السائق...'),
            const SizedBox(height: 10),
            if (status == 'pending')
              SizedBox(width: double.infinity, child: ElevatedButton.icon(icon: const Icon(Icons.cancel), label: const Text('إلغاء الطلب'), onPressed: onCancel, style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white))),
          ],
        ),
      ),
    );
  }
}

class TripListScreen extends StatefulWidget { final AuthResult authResult; const TripListScreen({super.key, required this.authResult}); @override State<TripListScreen> createState() => _TripListScreenState(); }
class _TripListScreenState extends State<TripListScreen> {
  List<Map<String, dynamic>> trips = []; bool isLoading = true; String error = '';
  @override
  void initState() { super.initState(); _loadTrips(); }
  Future<void> _loadTrips() async {
    if (!mounted) return;
    setState(() { isLoading = true; error = ''; });
    try {
      final response = await http.get(Uri.parse('${ApiService.baseUrl}/taxi/v1/trips'));
      if (mounted) {
        if (response.statusCode == 200) { final data = json.decode(response.body); if (data is List) setState(() => trips = List<Map<String, dynamic>>.from(data)); } else { throw Exception('فشل تحميل الرحلات'); }
      }
    } on SocketException { if (mounted) setState(() => error = 'يرجى التحقق من اتصالك بالإنترنت'); } catch (e) { if (mounted) setState(() => error = 'فشل تحميل البيانات. تحقق من اتصالك.'); } finally { if (mounted) setState(() => isLoading = false); }
  }
  Future<void> _bookTrip({ required String tripId, required String name, required String phone, required String address, required int quantity, }) async {
    try {
      final response = await http.post(Uri.parse('${ApiService.baseUrl}/taxi/v1/book'), headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.authResult.token}'}, body: json.encode({ 'trip_id': tripId, 'name': name, 'phone': phone, 'address': address, 'quantity': quantity }));
      final result = json.decode(response.body);
      if (mounted) {
        if (response.statusCode == 200 && result['success'] == true) { _updateTripLocally(Map<String, dynamic>.from(result['trip'])); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم الحجز بنجاح لـ $quantity مقاعد!'), backgroundColor: Colors.green)); } else { throw Exception(result['message'] ?? 'فشل الحجز'); }
      }
    } on SocketException { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خطأ في الحجز: يرجى التحقق من اتصالك بالإنترنت'), backgroundColor: Colors.red)); }  catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في الحجز: ${e.toString().replaceAll("Exception: ", "")}'), backgroundColor: Colors.red)); }
  }
  Future<void> _cancelBooking(String tripId, String passengerId) async {
    try {
      final response = await http.post(Uri.parse('${ApiService.baseUrl}/taxi/v1/cancel'), headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.authResult.token}'}, body: json.encode({ 'trip_id': tripId, 'passenger_id': passengerId }));
      final result = json.decode(response.body);
      if (mounted) {
        if (response.statusCode == 200 && result['success'] == true) { _updateTripLocally(Map<String, dynamic>.from(result['trip'])); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إلغاء الحجز بنجاح!'), backgroundColor: Colors.green)); } else { throw Exception(result['message'] ?? 'فشل الإلغاء'); }
      }
    } on SocketException { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خطأ في الإلغاء: يرجى التحقق من اتصالك بالإنترنت'), backgroundColor: Colors.red)); } catch (e) { if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في الإلغاء: ${e.toString().replaceFirst("Exception: ", "")}'), backgroundColor: Colors.red)); _loadTrips(); } }
  }
  void _updateTripLocally(Map<String, dynamic> updatedTrip) { setState(() { final index = trips.indexWhere((t) => t['id'].toString() == updatedTrip['id'].toString()); if (index != -1) trips[index] = updatedTrip; }); }
  void _showBookingDialog(Map<String, dynamic> trip) {
    final nameController = TextEditingController(text: widget.authResult.displayName); final phoneController = TextEditingController(); final addressController = TextEditingController(); final availableSeats = (trip['available_seats'] ?? 0) as int; int selectedQuantity = availableSeats > 0 ? 1 : 0; final formKey = GlobalKey<FormState>();
    final ValueNotifier<bool> isButtonEnabled = ValueNotifier(false);
    void validateFields() { isButtonEnabled.value = (formKey.currentState?.validate() ?? false) && selectedQuantity > 0; }
    nameController.addListener(validateFields); phoneController.addListener(validateFields); addressController.addListener(validateFields);
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (context, setStateSB) { void updateQuantityAndValidate(Function() updateFn) { setStateSB(updateFn); validateFields(); } WidgetsBinding.instance.addPostFrameCallback((_) => validateFields());
    return Dialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: Padding(padding: const EdgeInsets.all(16.0), child: Form(key: formKey, child: SingleChildScrollView(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('حجز مقعد', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)), const SizedBox(height: 16),
        Text('${trip['from']} → ${trip['to']}', style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center), Text('${_formatDate(trip['date'].toString())} - ${trip['time']}', style: const TextStyle(color: Colors.grey)), const SizedBox(height: 20),
        TextFormField(controller: nameController, decoration: const InputDecoration(labelText: 'الاسم الكامل', prefixIcon: Icon(Icons.person)), validator: (v) => v!.isEmpty ? 'الاسم مطلوب' : null), const SizedBox(height: 12),
        TextFormField(controller: phoneController, decoration: const InputDecoration(labelText: 'رقم الهاتف', prefixIcon: Icon(Icons.phone)), keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'رقم الهاتف مطلوب' : null), const SizedBox(height: 12),
        TextFormField(controller: addressController, decoration: const InputDecoration(labelText: 'عنوان الاستلام', prefixIcon: Icon(Icons.location_on)), validator: (v) => v!.isEmpty ? 'العنوان مطلوب' : null), const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('عدد المقاعد:'), IconButton(icon: const Icon(Icons.remove), onPressed: selectedQuantity > 1 ? () => updateQuantityAndValidate(() => selectedQuantity--) : null), Text('$selectedQuantity'), IconButton(icon: const Icon(Icons.add), onPressed: selectedQuantity < availableSeats ? () => updateQuantityAndValidate(() => selectedQuantity++) : null)]), const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')), ValueListenableBuilder<bool>(valueListenable: isButtonEnabled, builder: (context, isEnabled, child) { return ElevatedButton(onPressed: isEnabled ? () async { Navigator.pop(ctx); await _bookTrip(tripId: trip['id'].toString(), name: nameController.text, phone: phoneController.text, address: addressController.text, quantity: selectedQuantity); } : null, child: const Text('تأكيد الحجز')); })]),
      ]),
    ))));
    })).whenComplete(() { nameController.dispose(); phoneController.dispose(); addressController.dispose(); isButtonEnabled.dispose(); });
  }
  void _showPassengersScreen(Map<String, dynamic> trip) { if(mounted) { Navigator.push(context, MaterialPageRoute(builder: (context) => PassengersScreen(trip: trip, currentUserId: widget.authResult.userId, onCancelBooking: (passengerId) async => await _cancelBooking(trip['id'].toString(), passengerId), authResult: widget.authResult,))).then((_) => _loadTrips()); } }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading ? ListView.builder(itemCount: 3, itemBuilder: (context, index) => const ShimmerListItem()) : error.isNotEmpty ? Center(child: Text(error, style: const TextStyle(color: Colors.red))) : trips.isEmpty ? const EmptyStateWidget(svgAsset: '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect><line x1="16" y1="2" x2="16" y2="6"></line><line x1="8" y1="2" x2="8" y2="6"></line><line x1="3" y1="10" x2="21" y2="10"></line></svg>''', message: 'لا توجد رحلات مجدولة متاحة حالياً.') : RefreshIndicator(
        onRefresh: _loadTrips,
        child: AnimationLimiter(
          child: ListView.builder(
            padding: const EdgeInsets.all(12), itemCount: trips.length,
            itemBuilder: (context, index) {
              final trip = trips[index]; final passengers = (trip['passengers'] as List?) ?? []; final totalSeats = int.tryParse(trip['total_seats'].toString()) ?? 0; final bookedSeatsCount = passengers.length; final availableSeats = totalSeats - bookedSeatsCount; final userBookedSeats = passengers.where((p) => p['user_id']?.toString() == widget.authResult.userId).length; final driver = (trip['driver'] as Map?) ?? {};
              return AnimationConfiguration.staggeredList(
                position: index, duration: const Duration(milliseconds: 375),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [Container(width: 60, height: 60, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.blue, width: 2)), child: ClipOval(child: driver['image'] != null && driver['image'].toString().isNotEmpty ? Image.network(driver['image'].toString(), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 30)) : const Icon(Icons.person, size: 30))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(driver['name']?.toString() ?? 'غير معروف', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text('${driver['car_model'] ?? ''} - ${driver['car_color'] ?? ''}', style: const TextStyle(color: Colors.grey))]))]),
                            const Divider(height: 24),
                            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(trip['from'].toString(), style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)), const Icon(Icons.arrow_forward, color: Colors.blue), Expanded(child: Text(trip['to'].toString(), style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center))])),
                            const SizedBox(height: 16),
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_buildInfoItem(Icons.calendar_today, _formatDate(trip['date'].toString()), Colors.blue), _buildInfoItem(Icons.access_time, trip['time'].toString(), Colors.orange), _buildInfoItem(Icons.event_seat, '$bookedSeatsCount/$totalSeats', availableSeats > 0 ? Colors.green : Colors.red)]),
                            const SizedBox(height: 16),
                            Row(children: [Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.people, size: 18), label: Text('عرض الركاب (${passengers.length})'), onPressed: passengers.isNotEmpty ? () => _showPassengersScreen(trip) : null)), const SizedBox(width: 12), Expanded(child: userBookedSeats > 0 ? ElevatedButton.icon(icon: const Icon(Icons.cancel_outlined, size: 18), label: Text('إلغاء ($userBookedSeats)'), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), onPressed: () => _showPassengersScreen(trip)) : ElevatedButton.icon(icon: const Icon(Icons.add_shopping_cart, size: 18), label: const Text('حجز مقعد'), style: ElevatedButton.styleFrom(backgroundColor: availableSeats > 0 ? Colors.blue : Colors.grey, foregroundColor: Colors.white), onPressed: availableSeats > 0 ? () => _showBookingDialog(trip) : null))]),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
  Widget _buildInfoItem(IconData icon, String text, Color color) { return Row(children: [Icon(icon, size: 18, color: color), const SizedBox(width: 4), Text(text, style: TextStyle(fontWeight: FontWeight.bold, color: color))]); }
}

class PassengersScreen extends StatelessWidget {
  final Map<String, dynamic> trip; final String currentUserId; final Future<void> Function(String) onCancelBooking; final AuthResult authResult;
  const PassengersScreen({ super.key, required this.trip, required this.currentUserId, required this.onCancelBooking, required this.authResult });
  @override
  Widget build(BuildContext context) {
    final passengers = (trip['passengers'] as List?)?.map((p) => Map<String, dynamic>.from(p)).toList() ?? [];
    final totalSeats = int.tryParse(trip['total_seats'].toString()) ?? 0;
    final currentUserBookings = passengers.where((p) => p['user_id']?.toString() == currentUserId).toList();
    final isDriver = trip['driver']?['user_id']?.toString() == currentUserId;
    return Scaffold(
      appBar: AppBar(
        title: const Text('قائمة الركاب'), centerTitle: true,
        actions: [
          // [MODIFIED] - Clearer Group Chat Button
          TextButton.icon(
            icon: ChatIconWithBadge(
              chatId: 'trip_${trip['id']}',
              currentUserId: authResult.userId,
              onPressed: () {}, // The action is handled by the parent button
            ),
            label: const Text("محادثة الرحلة"),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ChatScreen(
                  chatId: 'trip_${trip['id']}',
                  chatName: 'مجموعة رحلة ${trip['from']} - ${trip['to']}',
                  authResult: authResult,
                  participants: {}, // For group chat, anyone with the trip ID can join.
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
            Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [Text('${trip['from']} → ${trip['to']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center), const SizedBox(height: 8), Text('${_formatDate(trip['date'].toString())} - ${trip['time']}', style: const TextStyle(color: Colors.grey)), const SizedBox(height: 8), Text('المقاعد: ${passengers.length}/$totalSeats (المتبقي: ${totalSeats - passengers.length})', style: const TextStyle(fontWeight: FontWeight.bold))]))),
            const SizedBox(height: 16),
            if (!isDriver) ...[
              const Text('حجوزاتي لهذه الرحلة:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 12),
              currentUserBookings.isEmpty ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: Text('لم تقم بأي حجز في هذه الرحلة.', style: TextStyle(color: Colors.grey)))) : ListView.separated(
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: currentUserBookings.length, separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final passenger = currentUserBookings[index];
                  return ListTile(
                    leading: CircleAvatar(backgroundColor: Colors.blue.withOpacity(0.2), child: Text('${index + 1}')),
                    title: Text(passenger['name']?.toString() ?? 'غير معروف'),
                    subtitle: Text('معرف الحجز: ${passenger['id']?.toString() ?? ''}', style: const TextStyle(fontSize: 10, color: Colors.blueGrey)),
                    trailing: IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () => showDialog(context: context, builder: (dialogContext) => AlertDialog(title: const Text('تأكيد الإلغاء'), content: const Text('هل أنت متأكد من إلغاء هذا المقعد؟'), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('لا')), TextButton(onPressed: () async { Navigator.pop(dialogContext); await onCancelBooking(passenger['id'].toString()); if(context.mounted) Navigator.pop(context); }, child: const Text('نعم، إلغاء'))]))),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
            const Text('جميع الركاب المسجلين في الرحلة:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 12),
            passengers.isEmpty ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: Text('لا يوجد ركاب مسجلين بعد', style: TextStyle(color: Colors.grey)))) : ListView.separated(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: passengers.length, separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final passenger = passengers[index];
                return ListTile(
                  leading: CircleAvatar(backgroundColor: Colors.grey.withOpacity(0.2), child: Text('${index + 1}')),
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

class DriverCreateTripScreen extends StatefulWidget { final AuthResult authResult; const DriverCreateTripScreen({super.key, required this.authResult}); @override State<DriverCreateTripScreen> createState() => _DriverCreateTripScreenState(); }
class _DriverCreateTripScreenState extends State<DriverCreateTripScreen> {
  final _formKey = GlobalKey<FormState>(); final _fromController = TextEditingController(); final _toController = TextEditingController(); final _dateController = TextEditingController(); final _timeController = TextEditingController(); final _seatsController = TextEditingController(); bool _isLoading = false;
  Future<void> _selectDate() async { DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 30))); if (picked != null) setState(() => _dateController.text = DateFormat('yyyy-MM-dd').format(picked)); }
  Future<void> _selectTime() async { TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now()); if (picked != null && mounted) setState(() => _timeController.text = picked.format(context)); }
  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    try {
      final response = await http.post(Uri.parse('${ApiService.baseUrl}/taxi/v1/driver/create-trip'), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.authResult.token}'}, body: json.encode({'from': _fromController.text, 'to': _toController.text, 'date': _dateController.text, 'time': _timeController.text, 'seats': _seatsController.text}));
      final data = json.decode(response.body);
      if (mounted) {
        if (response.statusCode == 201 && data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message']), backgroundColor: Colors.green));
          // This notification should ideally be sent from the backend to all customers.
          // Here, we simulate it for demonstration purposes.
          NotificationService.showNotification('رحلة جديدة متاحة!', 'تم إضافة رحلة من ${_fromController.text} إلى ${_toController.text}. اضغط للحجز.', payload: '{"userType": "customer", "targetScreen": "trips"}', type: 'default');
          _formKey.currentState?.reset(); _fromController.clear(); _toController.clear(); _dateController.clear(); _timeController.clear(); _seatsController.clear();
        } else { throw Exception(data['message'] ?? 'فشل إنشاء الرحلة'); }
      }
    } on SocketException { if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى التحقق من اتصالك بالإنترنت'), backgroundColor: Colors.orange)); } catch (e) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red)); } finally { if(mounted) setState(() => _isLoading = false); }
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
              TextFormField(controller: _fromController, decoration: const InputDecoration(labelText: 'من'), validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null), const SizedBox(height: 15),
              TextFormField(controller: _toController, decoration: const InputDecoration(labelText: 'إلى'), validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null), const SizedBox(height: 15),
              TextFormField(controller: _dateController, decoration: const InputDecoration(labelText: 'التاريخ', prefixIcon: Icon(Icons.calendar_today)), readOnly: true, onTap: _selectDate, validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null), const SizedBox(height: 15),
              TextFormField(controller: _timeController, decoration: const InputDecoration(labelText: 'الوقت', prefixIcon: Icon(Icons.access_time)), readOnly: true, onTap: _selectTime, validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null), const SizedBox(height: 15),
              TextFormField(controller: _seatsController, decoration: const InputDecoration(labelText: 'عدد المقاعد'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null), const SizedBox(height: 30),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _isLoading ? null : _submit, child: _isLoading ? const CircularProgressIndicator() : const Text('إنشاء الرحلة'))),
            ],
          ),
        ),
      ),
    );
  }
}

class NotificationsScreen extends StatefulWidget { final String token; const NotificationsScreen({super.key, required this.token}); @override State<NotificationsScreen> createState() => _NotificationsScreenState(); }
class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic>? _notifications; bool _isLoading = true;
  @override
  void initState() { super.initState(); _fetchNotifications(); }
  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('${ApiService.baseUrl}/taxi/v1/driver/my-notifications'), headers: {'Authorization': 'Bearer ${widget.token}'});
      if(response.statusCode == 200 && mounted) { final data = json.decode(response.body); setState(() => _notifications = data['notifications']); }
    } on SocketException { debugPrint("Network error fetching notifications."); } catch(e) { debugPrint("Failed to fetch notifications: $e"); } finally { if(mounted) setState(() => _isLoading = false); }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _fetchNotifications,
        child: _isLoading ? ListView.builder(itemCount: 5, itemBuilder: (context, index) => const ShimmerListItem()) : _notifications == null || _notifications!.isEmpty ? const EmptyStateWidget(svgAsset: '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"></path><path d="M13.73 21a2 2 0 0 1-3.46 0"></path></svg>''', message: 'لا توجد إشعارات جديدة.') : AnimationLimiter(
          child: ListView.builder(
            itemCount: _notifications!.length,
            itemBuilder: (context, index) {
              final notif = _notifications![index];
              return AnimationConfiguration.staggeredList(
                position: index, duration: const Duration(milliseconds: 375),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(leading: const Icon(Icons.notifications_active, color: Colors.amber), title: Text(notif['title']), subtitle: Text(notif['content']), trailing: Text(DateFormat('yyyy-MM-dd').format(DateTime.parse(notif['date'])))),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class DriverMyTripsScreen extends StatefulWidget { final AuthResult authResult; final VoidCallback navigateToCreate; const DriverMyTripsScreen({super.key, required this.authResult, required this.navigateToCreate}); @override State<DriverMyTripsScreen> createState() => _DriverMyTripsScreenState(); }
class _DriverMyTripsScreenState extends State<DriverMyTripsScreen> {
  List<dynamic>? _myTrips; bool _isLoading = true;
  @override
  void initState() { super.initState(); _fetchMyTrips(); }
  Future<void> _fetchMyTrips() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('${ApiService.baseUrl}/taxi/v1/driver/my-trips'), headers: {'Authorization': 'Bearer ${widget.authResult.token}'});
      if (response.statusCode == 200 && mounted) { final data = json.decode(response.body); setState(() => _myTrips = data['trips']); }
    } on SocketException { debugPrint("Network error fetching my trips."); } catch (e) { debugPrint("Failed to fetch my trips: $e"); } finally { if (mounted) setState(() => _isLoading = false); }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading ? ListView.builder(itemCount: 4, itemBuilder: (context, index) => const ShimmerListItem()) : _myTrips == null || _myTrips!.isEmpty ? EmptyStateWidget(svgAsset: '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline><line x1="16" y1="13" x2="8" y2="13"></line><line x1="16" y1="17" x2="8" y2="17"></line><polyline points="10 9 9 9 8 9"></polyline></svg>''', message: 'لم تقم بإنشاء أي رحلات بعد.', buttonText: 'إنشاء رحلة جديدة', onButtonPressed: widget.navigateToCreate) : RefreshIndicator(
        onRefresh: _fetchMyTrips,
        child: AnimationLimiter(
          child: ListView.builder(
            padding: const EdgeInsets.all(12), itemCount: _myTrips!.length,
            itemBuilder: (context, index) {
              final trip = _myTrips![index]; final passengers = (trip['passengers'] as List?) ?? [];
              return AnimationConfiguration.staggeredList(
                position: index, duration: const Duration(milliseconds: 375),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text('${trip['from']} → ${trip['to']}'),
                        subtitle: Text('${_formatDate(trip['date'])} - ${trip['time']}'),
                        trailing: Text('${passengers.length} / ${trip['total_seats']} مقاعد'),
                        onTap: () { if (mounted) { Navigator.push(context, MaterialPageRoute(builder: (_) => PassengersScreen(trip: trip, currentUserId: widget.authResult.userId, onCancelBooking: (_){ return Future.value(); }, authResult: widget.authResult))); } },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// =============================================================================
//  [MODIFIED] - Private Request Screens
// =============================================================================

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
      if (_activeRequest != null && _activeRequest!['status'] == 'pending') {
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
          setState(() {
            _activeRequest = data['request'];
          });
          _startStatusTimer();
        } else {
          setState(() {
            _activeRequest = null;
          });
        }
      }
    } catch (e) {
      debugPrint("Failed to fetch active private request: $e");
    }
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
      final body = {
        'from': _fromController.text,
        'to': _toController.text,
        'price': _priceController.text,
        'time': _timeController.text,
        'phone': _phoneController.text,
        'with_return': _withReturn
      };
      final response = await ApiService.createPrivateRequest(widget.authResult.token, body);
      final data = json.decode(response.body);
      if (mounted) {
        if (response.statusCode == 201 && data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message']), backgroundColor: Colors.green));
          // This notification should be sent from the backend to all drivers.
          NotificationService.showNotification('طلب خصوصي جديد!',
              'يوجد طلب من ${_fromController.text} إلى ${_toController.text}. اضغط للقبول.',
              payload: '{"userType": "driver", "targetScreen": "private_requests"}',
              type: 'high_priority');
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

  // [MODIFIED] - Customer can now cancel their request.
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

          // This notification should be sent from the backend to the accepted driver.
          // Simulating it here for demonstration.
          if (_activeRequest!['status'] == 'accepted') {
            NotificationService.showNotification(
              'إلغاء رحلة خاصة',
              'قام الزبون بإلغاء الرحلة الخاصة من ${_activeRequest!['from']} إلى ${_activeRequest!['to']}.',
              // The payload should contain the driver's FCM token, which the backend would have.
              // payload: '{"driver_fcm_token": "..."}'
              type: 'high_priority',
            );
          }

          setState(() {
            _activeRequest = null;
            _statusTimer?.cancel();
          });
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
          _activeRequest != null
              ? ActivePrivateRequestCard(request: _activeRequest!, onCancel: _cancelRequest, authResult: widget.authResult)
              : _buildRequestForm(),
          if (_isLoading) Container(
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
            Text('إنشاء طلب رحلة خصوصي', style: Theme.of(context).textTheme.headlineSmall),
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
                      icon: ChatIconWithBadge(chatId: 'private_${request['id']}', currentUserId: authResult.userId, onPressed: (){}),
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
                  Row(children: [
                    const CircularProgressIndicator(strokeWidth: 2),
                    const SizedBox(width: 16),
                    Text('جاري البحث عن سائق...', style: TextStyle(fontSize: 16, color: Colors.grey[700]))
                  ]),
                ],
                const SizedBox(height: 20),
                // [MODIFIED] - The cancel button is now always visible for the customer.
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
    return Row(children: [
      Icon(icon, color: Colors.grey[600], size: 20),
      const SizedBox(width: 12),
      Text(label, style: TextStyle(color: Colors.grey[800], fontSize: 16)),
      const SizedBox(width: 8),
      Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)))
    ]);
  }
}

// =============================================================================
//  Driver Private Request Screens (Updated)
// =============================================================================
class DriverPrivateRequestsScreen extends StatefulWidget { final AuthResult authResult; const DriverPrivateRequestsScreen({super.key, required this.authResult}); @override State<DriverPrivateRequestsScreen> createState() => _DriverPrivateRequestsScreenState(); }
class _DriverPrivateRequestsScreenState extends State<DriverPrivateRequestsScreen> {
  Future<List<dynamic>>? _privateRequestsFuture; Map<String, dynamic>? _acceptedRequest; bool _isLoading = false; Timer? _requestsTimer;
  @override
  void initState() { super.initState(); _loadRequests(); _requestsTimer = Timer.periodic(const Duration(seconds: 20), (timer) { if(_acceptedRequest == null) { _loadRequests(); } }); }
  @override
  void dispose() { _requestsTimer?.cancel(); super.dispose(); }
  void _loadRequests() { if(!mounted) return; setState(() { _acceptedRequest = null; _privateRequestsFuture = ApiService.getAvailablePrivateRequests(widget.authResult.token); }); }
  Future<void> _acceptRequest(Map<String, dynamic> request) async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.acceptPrivateRequest(widget.authResult.token, request['id'].toString());
      final data = json.decode(response.body);
      if (mounted) {
        if (response.statusCode == 200 && data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message']), backgroundColor: Colors.green));
          setState(() { _acceptedRequest = request; });
        } else { throw Exception(data['message'] ?? 'فشل قبول الطلب'); }
      }
    } on SocketException { if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى التحقق من اتصالك بالإنترنت'), backgroundColor: Colors.orange)); } } catch (e) { if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red)); _loadRequests(); } } finally { if (mounted) setState(() => _isLoading = false); }
  }
  void _endPrivateTrip(String status) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(status == 'completed' ? 'تم إنهاء الرحلة بنجاح' : 'تم إلغاء الرحلة'), backgroundColor: Colors.green));
      _loadRequests();
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _acceptedRequest != null ? _buildActiveTripCard(_acceptedRequest!) : RefreshIndicator(
            onRefresh: () async => _loadRequests(),
            child: FutureBuilder<List<dynamic>>(
              future: _privateRequestsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) { return ListView.builder(itemCount: 4, itemBuilder: (ctx, i) => const ShimmerListItem()); }
                if (snapshot.hasError) {
                  final error = snapshot.error; String errorMessage = 'خطأ في تحميل البيانات';
                  if (error is SocketException) { errorMessage = 'يرجى التحقق من اتصالك بالإنترنت'; } else if (error is Exception) { errorMessage = error.toString().replaceAll("Exception: ", ""); }
                  return Center(child: Text(errorMessage));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) { return const EmptyStateWidget(svgAsset: '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2L2 7l10 5 10-5-10-5z"></path><path d="M2 17l10 5 10-5"></path><path d="M2 12l10 5 10-5"></path></svg>''', message: 'لا توجد طلبات خصوصي  متاحة حالياً.'); }
                final requests = snapshot.data!;
                return AnimationLimiter(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12), itemCount: requests.length,
                    itemBuilder: (context, index) {
                      final request = requests[index];
                      return AnimationConfiguration.staggeredList(
                          position: index, duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(verticalOffset: 50.0, child: FadeInAnimation(child: PrivateRequestCard(request: request, onAccept: () => _acceptRequest(request)))));
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
                Text("الرحلة الخاصة الحالية", style: Theme.of(context).textTheme.headlineSmall), const Divider(height: 20),
                _buildInfoRow(Icons.person, "الزبون:", request['customer_name']), const SizedBox(height: 8),
                _buildInfoRow(Icons.pin_drop, "من:", request['from']), const SizedBox(height: 8),
                _buildInfoRow(Icons.flag, "إلى:", request['to']), const SizedBox(height: 8),
                _buildInfoRow(Icons.payments_outlined, "السعر:", "${request['price']} د.ع"), const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => makePhoneCall(request['phone'], context),
                    icon: const Icon(Icons.call), label: const Text("الاتصال بالزبون"), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                // [MODIFIED] - Clearer Chat Button for Driver
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: ChatIconWithBadge(
                      chatId: 'private_${request['id']}',
                      currentUserId: widget.authResult.userId,
                      onPressed: (){},
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
                    Expanded(child: OutlinedButton(onPressed: () => _endPrivateTrip('cancelled'), style: OutlinedButton.styleFrom(foregroundColor: Colors.red), child: const Text("إلغاء"))), const SizedBox(width: 12),
                    Expanded(child: ElevatedButton(onPressed: () => _endPrivateTrip('completed'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), child: const Text("إنهاء"))),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildInfoRow(IconData icon, String label, String value) { return Row(children: [Icon(icon, color: Colors.grey[600], size: 20), const SizedBox(width: 8), Text(label, style: TextStyle(color: Colors.grey[700])), const SizedBox(width: 4), Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)))]); }
}

class PrivateRequestCard extends StatelessWidget {
  final Map<String, dynamic> request; final VoidCallback onAccept;
  const PrivateRequestCard({super.key, required this.request, required this.onAccept});
  @override
  Widget build(BuildContext context) {
    final bool isAccepted = request['status'] == 'accepted';
    return Card(
      margin: const EdgeInsets.only(bottom: 16), elevation: 4, shadowColor: isAccepted ? Colors.grey.withOpacity(0.2) : Colors.amber.withOpacity(0.2),
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
            _buildInfoRow(Icons.person_outline, 'الزبون:', request['customer_name']), const SizedBox(height: 8),
            const Divider(height: 20),
            if (isAccepted) Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Text('تم قبول الطلب بواسطة سائق آخر', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)))) else SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: onAccept, icon: const Icon(Icons.check_circle_outline), label: const Text('قبول هذا الطلب'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green))),
          ],
        ),
      ),
    );
  }
  Widget _buildInfoChip(IconData icon, String text, Color color) { return Chip(avatar: Icon(icon, color: color, size: 18), label: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)), backgroundColor: color.withOpacity(0.1), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)); }
  Widget _buildInfoRow(IconData icon, String label, String value) { return Row(children: [Icon(icon, color: Colors.grey[600], size: 20), const SizedBox(width: 8), Text(label, style: TextStyle(color: Colors.grey[700])), const SizedBox(width: 4), Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)))]); }
}

String _formatDate(String dateString) { try { return DateFormat('yyyy/MM/dd', 'en_US').format(DateTime.parse(dateString)); } catch (e) { return dateString; } }


// =============================================================================
// [CHAT INTEGRATION] - NEW & IMPROVED WIDGETS
// =============================================================================

// [IMPROVEMENT] - A new widget to display a chat icon with an unread badge
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
          // The unread count is stored for the current user's ID
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
  // [IMPROVEMENT] - Pass all participants to manage unread/typing status
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
    // When leaving the screen, mark self as not typing
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
        // Find the other user's ID
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

    // Get the other user's ID to increment their unread count
    final recipientId = widget.participants.values.firstWhere(
          (id) => id != null && id != _user.id,
      orElse: () => null,
    );

    // Prepare the data for Firestore
    final messageData = {
      'author': message.author.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
      'text': message.text,
      'type': types.MessageType.text.name,
    };

    // Use a transaction to ensure atomicity
    FirebaseFirestore.instance.runTransaction((transaction) async {
      // 1. Add the new message
      transaction.set(chatDocRef.collection('messages').doc(), messageData);

      // 2. Update the chat metadata
      final updateData = {
        'lastMessage': {
          'text': message.text,
          'createdAt': FieldValue.serverTimestamp(),
          'authorId': _user.id,
        },
        'participants': widget.participants.values.where((id) => id != null).toList(),
      };

      if (recipientId != null) {
        // Atomically increment the recipient's unread count
        updateData['unreadCount.${recipientId}'] = FieldValue.increment(1);
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
        // [MODIFIED] - Updated chat theme and enabled user names.
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
        // [NOTE] If you still see an error here, please ensure your `flutter_chat_ui`
        // package is updated to the latest version in your `pubspec.yaml`.
      ),
    );
  }
}
