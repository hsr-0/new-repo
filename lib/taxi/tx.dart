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
import 'package:geolocator/geolocator.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:url_launcher/url_launcher.dart';

// =============================================================================
//  Helper Classes & Functions
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

Future<void> makePhoneCall(String? phoneNumber, BuildContext context) async {
  if (phoneNumber == null || phoneNumber.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رقم الهاتف غير متوفر')));
    return;
  }
  final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
  if (await canLaunchUrl(launchUri)) {
    await launchUrl(launchUri);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('لا يمكن إجراء الاتصال بالرقم $phoneNumber')));
  }
}

// =============================================================================
//  Permission Service
// =============================================================================
class PermissionService {
  static Future<bool> handleLocationPermission(BuildContext context) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خدمات الموقع معطلة. الرجاء تفعيل خدمات الموقع.')));
      return false;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم رفض إذن الوصول للموقع.')));
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم رفض إذن الموقع بشكل دائم. يرجى تفعيله من إعدادات التطبيق.')));
      return false;
    }
    return true;
  }
}

// =============================================================================
//  Entry Point & App Theme
// =============================================================================
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تكسي بيتي',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.amber,
        fontFamily: 'Cairo',
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[50],
          foregroundColor: Colors.black,
          elevation: 0.5,
          iconTheme: const IconThemeData(color: Colors.black),
          titleTextStyle: const TextStyle(fontFamily: 'Cairo', color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
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
//  Models & Services
// =============================================================================
class AuthResult {
  final String token; final String userId; final String displayName; final bool isDriver; final String? driverStatus;
  AuthResult({required this.token, required this.userId, required this.displayName, required this.isDriver, this.driverStatus});
}

class ApiService {
  static const String baseUrl = 'https://banner.beytei.com/wp-json'; // Make sure this is your correct URL
  static final _storage = const FlutterSecureStorage();
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
  static Future<void> setDriverActiveStatus(String token, bool isActive) async {
    try { await http.post(Uri.parse('$baseUrl/taxi/v1/driver/set-active-status'), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}, body: json.encode({'is_active': isActive})); } catch (e) {}
  }
  static Future<void> updateDriverLocation(String token, LatLng location) async {
    try { await http.post(Uri.parse('$baseUrl/taxi/v1/driver/update-location'), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}, body: json.encode({'lat': location.latitude, 'lng': location.longitude})); } catch (e) {}
  }
  static Future<List<dynamic>> fetchActiveDrivers(String token) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/taxi/v1/customer/active-drivers'), headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['drivers'] is List) return data['drivers'];
      }
      return [];
    } catch (e) { return []; }
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
    } catch (e) { return null; }
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
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static void initialize() {
    const InitializationSettings initializationSettings = InitializationSettings(android: AndroidInitializationSettings("@mipmap/ic_launcher"), iOS: DarwinInitializationSettings());
    _notificationsPlugin.initialize(initializationSettings);
  }
  static Future<void> showNotification(String title, String body) async {
    final NotificationDetails notificationDetails = NotificationDetails(android: AndroidNotificationDetails("taxi_app_channel", "Taxi App Notifications", importance: Importance.max, priority: Priority.high, styleInformation: BigTextStyleInformation(body)));
    await _notificationsPlugin.show(DateTime.now().millisecondsSinceEpoch.toSigned(31), title, body, notificationDetails);
  }
}

// =============================================================================
//  UI Enhancement Widgets
// =============================================================================
class EmptyStateWidget extends StatelessWidget { final String svgAsset; final String message; final String? buttonText; final VoidCallback? onButtonPressed; const EmptyStateWidget({ super.key, required this.svgAsset, required this.message, this.buttonText, this.onButtonPressed }); @override Widget build(BuildContext context) { return Center(child: Padding(padding: const EdgeInsets.all(32.0), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [SvgPicture.string(svgAsset, height: 150, colorFilter: ColorFilter.mode(Colors.grey[400]!, BlendMode.srcIn)), const SizedBox(height: 24), Text(message, style: TextStyle(fontSize: 18, color: Colors.grey[700]), textAlign: TextAlign.center), const SizedBox(height: 24), if (buttonText != null && onButtonPressed != null) ElevatedButton(onPressed: onButtonPressed, child: Text(buttonText!))]))); } }
class ShimmerListItem extends StatelessWidget { const ShimmerListItem({super.key}); @override Widget build(BuildContext context) { return Shimmer.fromColors(baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!, child: Padding(padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 60.0, height: 60.0, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[const SizedBox(height: 8), Container(width: double.infinity, height: 10.0, color: Colors.white), const SizedBox(height: 8), Container(width: 150, height: 10.0, color: Colors.white)]))]))); } }
class PinMarker extends StatelessWidget { final String label; final Color color; final IconData icon; const PinMarker({super.key, required this.label, required this.color, this.icon = Icons.location_on}); @override Widget build(BuildContext context) { return Column(mainAxisSize: MainAxisSize.min, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 5, offset: const Offset(0, 2))]), child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold))), Icon(icon, color: color, size: 40, shadows: [Shadow(color: Colors.black.withOpacity(0.4), blurRadius: 5, offset: const Offset(0, 2))])]); } }
class RotatingVehicleIcon extends StatelessWidget { final String vehicleType; final double bearing; const RotatingVehicleIcon({super.key, required this.vehicleType, required this.bearing}); @override Widget build(BuildContext context) { final String taxiSvg = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor"><path d="M18.92 6.01C18.72 5.42 18.16 5 17.5 5h-11C5.84 5 5.28 5.42 5.08 6.01L3 12v8c0 .55.45 1 1 1h1c.55 0 1-.45 1-1v-1h12v1c0 .55.45 1 1 1h1c.55 0 1-.45 1-1v-8l-2.08-5.99zM6.5 16c-.83 0-1.5-.67-1.5-1.5S5.67 13 6.5 13s1.5.67 1.5 1.5S7.33 16 6.5 16zm11 0c-.83 0-1.5-.67-1.5-1.5s.67-1.5 1.5-1.5 1.5.67 1.5 1.5-.67 1.5-1.5 1.5zM5 11l1.5-4.5h11L19 11H5z"/></svg>'''; final String tuktukSvg = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor"><path d="M20 17.17V10c0-2.21-1.79-4-4-4h-2.1c-.83-2.32-3.07-4-5.9-4-3.31 0-6 2.69-6 6s2.69 6 6 6c.34 0 .67-.04 1-.09V17H2v2h18v-2h-2zm-8-2c-1.1 0-2-.9-2-2s.9-2 2-2 2 .9 2 2-.9 2-2 2zM5 8c0-2.21 1.79-4 4-4s4 1.79 4 4-1.79 4-4 4-4-1.79-4-4z"/></svg>'''; return Transform.rotate(angle: bearing * (pi / 180), child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.black.withAlpha(178), shape: BoxShape.circle), child: SvgPicture.string(vehicleType.toLowerCase() == 'tuktuk' ? tuktukSvg : taxiSvg, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)))); } }

// =============================================================================
//  Authentication Gate & Welcome Screen
// =============================================================================
enum AuthStatus { unknown, authenticated, unauthenticated }
class AuthGate extends StatefulWidget { const AuthGate({super.key}); @override State<AuthGate> createState() => _AuthGateState(); }
class _AuthGateState extends State<AuthGate> {
  AuthStatus _authStatus = AuthStatus.unknown; AuthResult? _authResult;
  @override
  void initState() { super.initState(); NotificationService.initialize(); _checkAuth(); WidgetsBinding.instance.addPostFrameCallback((_) { PermissionService.handleLocationPermission(context); }); }
  Future<void> _checkAuth() async {
    final authData = await ApiService.getStoredAuthData();
    if (mounted) _updateAuthStatus(authData);
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
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; _errorMessage = null; });
      try {
        final response = await http.post(Uri.parse('${ApiService.baseUrl}/taxi-auth/v1/register/customer'), headers: {'Content-Type': 'application/json'}, body: json.encode({'name': _nameController.text, 'phone_number': _phoneController.text}));
        final data = json.decode(response.body);
        if (response.statusCode == 200 && data['success'] == true) {
          final authResult = AuthResult(token: data['token'], userId: data['user_id'].toString(), displayName: data['display_name'], isDriver: data['is_driver'] ?? false, driverStatus: data['driver_status']);
          await ApiService.storeAuthData(authResult);
          widget.onLoginSuccess(authResult);
        } else { throw Exception(data['message'] ?? 'فشل تسجيل الدخول أو التسجيل'); }
      } catch (e) { setState(() => _errorMessage = e.toString().replaceAll("Exception: ", ""));
      } finally { if(mounted) setState(() => _isLoading = false); }
    }
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
                TextButton.icon(icon: const Icon(Icons.local_taxi), label: const Text('هل أنت سائق؟ اضغط هنا'), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DriverAuthScreen(onLoginSuccess: widget.onLoginSuccess))), style: TextButton.styleFrom(foregroundColor: Colors.grey[800])),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
//  Generic Login & Driver Registration Screens
// =============================================================================
class LoginScreen extends StatefulWidget { final Function(AuthResult) onLoginSuccess; const LoginScreen({super.key, required this.onLoginSuccess}); @override State<LoginScreen> createState() => _LoginScreenState(); }
class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController(); final _formKey = GlobalKey<FormState>(); bool _isLoading = false; String? _errorMessage;
  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; _errorMessage = null; });
      try {
        final response = await http.post(Uri.parse('${ApiService.baseUrl}/taxi-auth/v1/login'), headers: {'Content-Type': 'application/json'}, body: json.encode({'phone_number': _phoneController.text}));
        final data = json.decode(response.body);
        if (response.statusCode == 200 && data['success'] == true) {
          final authResult = AuthResult(token: data['token'], userId: data['user_id'].toString(), displayName: data['display_name'], isDriver: data['is_driver'] ?? false, driverStatus: data['driver_status']);
          await ApiService.storeAuthData(authResult);
          if (mounted) {
            // This will pop all routes until the first one (AuthGate) and then AuthGate will handle navigation.
            Navigator.of(context).popUntil((route) => route.isFirst);
            widget.onLoginSuccess(authResult);
          }
        } else { throw Exception(data['message'] ?? 'فشل تسجيل الدخول'); }
      } catch (e) { setState(() => _errorMessage = e.toString().replaceAll("Exception: ", ""));
      } finally { if(mounted) setState(() => _isLoading = false); }
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

class DriverAuthScreen extends StatelessWidget { final Function(AuthResult) onLoginSuccess; const DriverAuthScreen({super.key, required this.onLoginSuccess}); @override Widget build(BuildContext context) { return DefaultTabController(length: 2, initialIndex: 1, child: Scaffold(appBar: AppBar(title: const Text('بوابة السائقين'), bottom: const TabBar(tabs: [Tab(text: 'تسجيل دخول'), Tab(text: 'تسجيل جديد')])), body: TabBarView(children: [LoginScreen(onLoginSuccess: onLoginSuccess), DriverRegistrationScreen(onLoginSuccess: onLoginSuccess)]))); } }
class DriverRegistrationScreen extends StatefulWidget { final Function(AuthResult) onLoginSuccess; const DriverRegistrationScreen({super.key, required this.onLoginSuccess}); @override State<DriverRegistrationScreen> createState() => _DriverRegistrationScreenState(); }
class _DriverRegistrationScreenState extends State<DriverRegistrationScreen> {
  final _formKey = GlobalKey<FormState>(); final _nameController = TextEditingController(); final _phoneController = TextEditingController(); final _modelController = TextEditingController(); final _colorController = TextEditingController(); String _vehicleType = 'Tuktuk'; bool _isLoading = false; String? _errorMessage; final ImagePicker _picker = ImagePicker(); XFile? _registrationImageFile;
  Future<void> _pickImage() async { final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery); if (pickedFile != null) setState(() => _registrationImageFile = pickedFile); }
  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_registrationImageFile == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء رفع صورة سنوية السيارة'), backgroundColor: Colors.red)); return; }
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
      } catch (e) { setState(() => _errorMessage = e.toString().replaceAll("Exception: ", ""));
      } finally { if(mounted) setState(() => _isLoading = false); }
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
            TextFormField(controller: _modelController, decoration: const InputDecoration(labelText: 'موديل المركبة'), validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null),
            const SizedBox(height: 15),
            TextFormField(controller: _colorController, decoration: const InputDecoration(labelText: 'لون المركبة'), validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null),
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
//  Customer Main Screen
// =============================================================================
class CustomerMainScreen extends StatefulWidget {
  final AuthResult authResult; final VoidCallback onLogout;
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
      QuickRideMapScreen(token: widget.authResult.token, authResult: widget.authResult),
      TripListScreen(authResult: widget.authResult),
      PrivateRequestFormScreen(authResult: widget.authResult),
    ];
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
          BottomNavigationBarItem(icon: Icon(Icons.event_note_outlined), label: 'رحلات مجدولة'),
          BottomNavigationBarItem(icon: Icon(Icons.star_outline), label: 'طلب خاص'),
        ],
      ),
    );
  }
}

// =============================================================================
//  Driver Screens
// =============================================================================
class DriverPendingScreen extends StatefulWidget { final VoidCallback onLogout; final Function(AuthResult?) onCheckStatus; final String phone; const DriverPendingScreen({super.key, required this.onLogout, required this.phone, required this.onCheckStatus}); @override State<DriverPendingScreen> createState() => _DriverPendingScreenState(); }
class _DriverPendingScreenState extends State<DriverPendingScreen> {
  bool _isChecking = false;
  Future<void> _checkStatus() async {
    setState(() => _isChecking = true);
    try {
      final response = await http.post(Uri.parse('${ApiService.baseUrl}/taxi-auth/v1/login'), headers: {'Content-Type': 'application/json'}, body: json.encode({'phone_number': widget.phone}));
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final authResult = AuthResult(token: data['token'], userId: data['user_id'].toString(), displayName: data['display_name'], isDriver: data['is_driver'] ?? false, driverStatus: data['driver_status']);
        await ApiService.storeAuthData(authResult);
        if (authResult.driverStatus == 'approved') {
          if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت الموافقة على حسابك!'), backgroundColor: Colors.green));
          widget.onCheckStatus(authResult);
        } else { if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الحساب لا يزال قيد المراجعة.'), backgroundColor: Colors.orange)); }
      } else { throw Exception(data['message'] ?? 'فشل التحقق'); }
    } catch (e) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red));
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
  int _selectedIndex = 0; late final List<Widget> _pages; bool _isDriverActive = false; StreamSubscription<Position>? _positionStream;
  @override
  void initState() {
    super.initState();
    _pages = [
      DriverAvailableRidesScreen(authResult: widget.authResult, onLogout: widget.onLogout),
      DriverPrivateRequestsScreen(authResult: widget.authResult),
      DriverMyTripsScreen(authResult: widget.authResult, navigateToCreate: () => _changeTab(3)),
      DriverCreateTripScreen(authResult: widget.authResult),
      NotificationsScreen(token: widget.authResult.token),
    ];
    _checkLocationPermission();
  }
  void _changeTab(int index) { setState(() { _selectedIndex = index; }); }
  Future<void> _checkLocationPermission() async => await PermissionService.handleLocationPermission(context);
  void _toggleActiveStatus(bool isActive) {
    setState(() => _isDriverActive = isActive);
    ApiService.setDriverActiveStatus(widget.authResult.token, isActive);
    if (isActive) {
      _positionStream = Geolocator.getPositionStream(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10))
          .listen((Position position) => ApiService.updateDriverLocation(widget.authResult.token, LatLng(position.latitude, position.longitude)));
    } else { _positionStream?.cancel(); }
  }
  @override
  void dispose() { _positionStream?.cancel(); if(_isDriverActive) ApiService.setDriverActiveStatus(widget.authResult.token, false); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('واجهة السائق'),
        actions: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0), child: Row(children: [const Text("استقبال الطلبات", style: TextStyle(fontSize: 12)), Switch(value: _isDriverActive, onChanged: _toggleActiveStatus, activeColor: Colors.green)])),
          IconButton(icon: const Icon(Icons.logout), onPressed: widget.onLogout)
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _changeTab,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list_alt_outlined), label: 'الطلبات'),
          BottomNavigationBarItem(icon: Icon(Icons.star_border_purple500_outlined), label: 'طلبات خاصة'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_car_outlined), label: 'رحلاتي'),
          BottomNavigationBarItem(icon: Icon(Icons.add_road_outlined), label: 'إنشاء رحلة'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), label: 'الإشعارات'),
        ],
      ),
    );
  }
}

class DriverAvailableRidesScreen extends StatefulWidget { final AuthResult authResult; final VoidCallback onLogout; const DriverAvailableRidesScreen({super.key, required this.authResult, required this.onLogout}); @override State<DriverAvailableRidesScreen> createState() => _DriverAvailableRidesScreenState(); }
class _DriverAvailableRidesScreenState extends State<DriverAvailableRidesScreen> {
  List<dynamic>? _availableRides; bool _isLoading = true; Timer? _ridesTimer;
  @override
  void initState() { super.initState(); _fetchAvailableRides(); _ridesTimer = Timer.periodic(const Duration(seconds: 15), (timer) => _fetchAvailableRides()); }
  @override
  void dispose() { _ridesTimer?.cancel(); super.dispose(); }
  Future<void> _fetchAvailableRides() async {
    try {
      final response = await http.get(Uri.parse('${ApiService.baseUrl}/taxi/v1/driver/available-rides'), headers: {'Authorization': 'Bearer ${widget.authResult.token}'});
      if (response.statusCode == 200 && mounted) { final data = json.decode(response.body); setState(() => _availableRides = data['rides']); }
    } catch (e) { /* Silent error */ } finally { if (mounted) setState(() => _isLoading = false); }
  }
  Future<void> _acceptRide(String rideId) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(Uri.parse('${ApiService.baseUrl}/taxi/v1/driver/accept-ride'), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.authResult.token}'}, body: json.encode({'ride_id': rideId}));
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        if(mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => DriverCurrentRideScreen(initialRide: data['ride'], authResult: widget.authResult, onLogout: widget.onLogout)));
      } else { throw Exception(data['message'] ?? 'فشل قبول الطلب'); }
    } catch (e) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red)); _fetchAvailableRides();
    } finally { if (mounted) setState(() => _isLoading = false); }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? ListView.builder(itemCount: 5, itemBuilder: (context, index) => const ShimmerListItem())
          : _availableRides == null || _availableRides!.isEmpty
          ? EmptyStateWidget(svgAsset: '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-coffee"><path d="M18 8h1a4 4 0 0 1 0 8h-1"></path><path d="M2 8h16v9a4 4 0 0 1-4 4H6a4 4 0 0 1-4-4V8z"></path><line x1="6" y1="1" x2="6" y2="4"></line><line x1="10" y1="1" x2="10" y2="4"></line><line x1="14" y1="1" x2="14" y2="4"></line></svg>''', message: 'لا توجد طلبات سريعة متاحة حالياً.')
          : RefreshIndicator(
        onRefresh: _fetchAvailableRides,
        child: AnimationLimiter(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _availableRides!.length,
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
    );
  }
}


class DriverCurrentRideScreen extends StatefulWidget { final Map<String, dynamic> initialRide; final AuthResult authResult; final VoidCallback onLogout; const DriverCurrentRideScreen({super.key, required this.initialRide, required this.authResult, required this.onLogout}); @override State<DriverCurrentRideScreen> createState() => _DriverCurrentRideScreenState(); }
class _DriverCurrentRideScreenState extends State<DriverCurrentRideScreen> {
  late Map<String, dynamic> _currentRide; bool _isLoading = false; final MapController _mapController = MapController(); StreamSubscription<Position>? _positionStream; LatLng? _driverLocation; List<LatLng> _routePoints = []; double _distanceToPickup = 0.0; final String _orsApiKey = '5b3ce3597851110001cf624817d713d471a543648dca6b3277f3c0e6'; // Replace with your key
  @override
  void initState() { super.initState(); _currentRide = widget.initialRide; _startDriverLocationTracking(); }
  @override
  void dispose() { _positionStream?.cancel(); super.dispose(); }
  void _startDriverLocationTracking() {
    _positionStream = Geolocator.getPositionStream(locationSettings: const LocationSettings(accuracy: LocationAccuracy.bestForNavigation, distanceFilter: 10))
        .listen((Position position) {
      if(mounted) {
        final newLocation = LatLng(position.latitude, position.longitude);
        final pickupPoint = LatLng(double.parse(_currentRide['pickup']['lat']), double.parse(_currentRide['pickup']['lng']));
        if(_driverLocation == null) { _getRoute(newLocation, pickupPoint); _mapController.move(newLocation, 15); }
        setState(() { _driverLocation = newLocation; _distanceToPickup = Geolocator.distanceBetween(newLocation.latitude, newLocation.longitude, pickupPoint.latitude, pickupPoint.longitude); });
      }
    });
  }
  Future<void> _getRoute(LatLng start, LatLng end) async {
    if (_orsApiKey.length < 50) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("الرجاء إضافة مفتاح API الخاص بـ OpenRouteService"), backgroundColor: Colors.red)); return; }
    final url = 'https://api.openrouteservice.org/v2/directions/driving-car?api_key=$_orsApiKey&start=${start.longitude},${start.latitude}&end=${end.longitude},${end.latitude}';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final coordinates = data['features'][0]['geometry']['coordinates'] as List;
        if(mounted) setState(() => _routePoints = coordinates.map((c) => LatLng(c[1], c[0])).toList());
      }
    } catch (e) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("فشل رسم المسار: ${e.toString()}"), backgroundColor: Colors.red)); }
  }
  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(Uri.parse('${ApiService.baseUrl}/taxi/v1/driver/update-ride-status'), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.authResult.token}'}, body: json.encode({'ride_id': _currentRide['id'], 'status': newStatus}));
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        if (newStatus == 'completed' || newStatus == 'cancelled') {
          if(mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => DriverMainScreen(authResult: widget.authResult, onLogout: widget.onLogout)));
        } else {
          setState(() => _currentRide = data['ride']);
          if (newStatus == 'ongoing' && _driverLocation != null && _currentRide['destination']?['lat'] != null) {
            final destination = LatLng(double.parse(_currentRide['destination']['lat']), double.parse(_currentRide['destination']['lng']));
            _getRoute(_driverLocation!, destination);
          }
        }
      } else { throw Exception(data['message'] ?? 'فشل تحديث الحالة'); }
    } catch (e) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally { if(mounted) setState(() => _isLoading = false); }
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
      appBar: AppBar(title: const Text('الرحلة الحالية')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: pickupPoint, initialZoom: 14.0),
            children: [
              TileLayer(urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png', subdomains: const ['a', 'b', 'c'], retinaMode: true),
              if (_routePoints.isNotEmpty) PolylineLayer(polylines: [Polyline(points: _routePoints, color: Colors.blue, strokeWidth: 5)]),
              MarkerLayer(markers: [
                Marker(point: pickupPoint, child: const Icon(Icons.location_on, color: Colors.green, size: 40)),
                if(destinationPoint != null) Marker(point: destinationPoint, child: const Icon(Icons.flag, color: Colors.red, size: 40)),
                if (_driverLocation != null) Marker(point: _driverLocation!, child: const Icon(Icons.local_taxi, color: Colors.blue, size: 30)),
              ])
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

class QuickRideMapScreen extends StatefulWidget { final String token; final AuthResult authResult; const QuickRideMapScreen({super.key, required this.token, required this.authResult}); @override State<QuickRideMapScreen> createState() => _QuickRideMapScreenState(); }
class _QuickRideMapScreenState extends State<QuickRideMapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController(); LatLng? _pickupLocation; LatLng? _destinationLocation; Map<String, dynamic>? _activeRide; bool _isLoading = true; Timer? _statusTimer; final _priceController = TextEditingController(); Map<String, dynamic> _driversData = {}; Map<String, AnimationController> _animationControllers = {}; Map<String, Animation<LatLng>> _animations = {}; Map<String, ({LatLng begin, LatLng end})> _driverAnimationSegments = {}; Timer? _driversTimer; LatLng? _assignedDriverLocation; Timer? _liveTrackingTimer; List<LatLng> _routeToCustomer = [];
  @override
  void initState() { super.initState(); _checkCurrentUserLocation(); _checkForActiveRide(); _driversTimer = Timer.periodic(const Duration(seconds: 5), (timer) { if(_activeRide == null) _fetchActiveDrivers(); }); }
  @override
  void dispose() { _statusTimer?.cancel(); _driversTimer?.cancel(); _liveTrackingTimer?.cancel(); _priceController.dispose(); for (var controller in _animationControllers.values) controller.dispose(); super.dispose(); }
  Future<void> _checkCurrentUserLocation() async {
    final hasPermission = await PermissionService.handleLocationPermission(context);
    if (!hasPermission || !mounted) return;
    try {
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.bestForNavigation);
      if (mounted) { setState(() => _pickupLocation = LatLng(position.latitude, position.longitude)); _mapController.move(_pickupLocation!, 15.0); }
    } catch(e) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل تحديد الموقع بدقة.'))); }
  }
  Future<void> _checkForActiveRide() async {
    try {
      final response = await http.get(Uri.parse('${ApiService.baseUrl}/taxi/v1/rides/my-request'), headers: {'Authorization': 'Bearer ${widget.token}'});
      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['ride'] != null) {
          final rideData = data['ride'];
          final newStatus = rideData['status'];
          if (_activeRide == null || _activeRide!['status'] != newStatus) {
            NotificationService.showNotification("تحديث حالة الطلب", "حالة طلبك الآن هي: $newStatus");
            if (['accepted', 'arrived_pickup', 'ongoing'].contains(newStatus)) { _startLiveTracking(rideData['id'].toString()); } else { _stopLiveTracking(); }
          }
          setState(() => _activeRide = rideData);
          _startStatusTimer();
        } else { setState(() => _activeRide = null); _stopLiveTracking(); }
      }
    } catch(e) { /* silent */ } finally { if (mounted) setState(() => _isLoading = false); }
  }
  void _startLiveTracking(String rideId) {
    _liveTrackingTimer?.cancel();
    _liveTrackingTimer = Timer.periodic(const Duration(seconds: 7), (timer) async {
      if (_activeRide == null) { timer.cancel(); return; }
      final driverLocation = await ApiService.getRideDriverLocation(widget.token, rideId);
      if (driverLocation != null && mounted) {
        setState(() => _assignedDriverLocation = driverLocation);
        if (_pickupLocation != null) _getRoute(_assignedDriverLocation!, _pickupLocation!);
      }
    });
  }
  void _stopLiveTracking() { _liveTrackingTimer?.cancel(); if (mounted) setState(() { _assignedDriverLocation = null; _routeToCustomer.clear(); }); }
  Future<void> _getRoute(LatLng start, LatLng end) async {
    const String orsApiKey = '5b3ce3597851110001cf624817d713d471a543648dca6b3277f3c0e6'; // Replace with your key
    if (orsApiKey.length < 50) return;
    final url = 'https://api.openrouteservice.org/v2/directions/driving-car?api_key=$orsApiKey&start=${start.longitude},${start.latitude}&end=${end.longitude},${end.latitude}';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final coordinates = data['features'][0]['geometry']['coordinates'] as List;
        if(mounted) setState(() => _routeToCustomer = coordinates.map((c) => LatLng(c[1], c[0])).toList());
      }
    } catch (e) { /* silent */ }
  }
  Future<void> _fetchActiveDrivers() async {
    final driversList = await ApiService.fetchActiveDrivers(widget.token);
    if (!mounted) return;
    for (var driver in driversList) {
      final driverId = driver['id'].toString();
      final newPosition = LatLng(double.tryParse(driver['lat']?.toString() ?? '0')!, double.tryParse(driver['lng']?.toString() ?? '0')!);
      if (_animationControllers[driverId] == null) {
        final controller = AnimationController(vsync: this, duration: const Duration(seconds: 4));
        _animationControllers[driverId] = controller;
        _animations[driverId] = LatLngTween(begin: newPosition, end: newPosition).animate(controller);
        _driverAnimationSegments[driverId] = (begin: newPosition, end: newPosition);
        controller.addListener(() => setState(() {}));
      }
      final oldPosition = _driverAnimationSegments[driverId]!.end;
      if (oldPosition.latitude != newPosition.latitude || oldPosition.longitude != newPosition.longitude) {
        final controller = _animationControllers[driverId]!;
        final newAnimation = LatLngTween(begin: oldPosition, end: newPosition).animate(CurvedAnimation(parent: controller, curve: Curves.linear));
        _animations[driverId] = newAnimation;
        _driverAnimationSegments[driverId] = (begin: oldPosition, end: newPosition);
        controller.forward(from: 0);
      }
      _driversData[driverId] = driver;
    }
    if (mounted) setState(() {});
  }
  void _startStatusTimer() { _statusTimer?.cancel(); _statusTimer = Timer.periodic(const Duration(seconds: 15), (timer) { if (_activeRide != null && ['pending', 'accepted', 'arrived_pickup', 'ongoing'].contains(_activeRide!['status'])) _checkForActiveRide(); else timer.cancel(); }); }
  void _handleTap(TapPosition _, LatLng latlng) { if (_activeRide != null) return; setState(() => _pickupLocation = latlng); }
  Future<void> _requestRide() async {
    if (_pickupLocation == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء تحديد نقطة الانطلاق على الخريطة.'))); return; }
    if (_priceController.text.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء تحديد سعر الكروة.'))); return; }
    setState(() => _isLoading = true);
    try {
      final response = await http.post(Uri.parse('${ApiService.baseUrl}/taxi/v1/rides/request'), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'}, body: json.encode({'pickup': {'lat': _pickupLocation!.latitude, 'lng': _pickupLocation!.longitude}, 'destination': _destinationLocation != null ? {'lat': _destinationLocation!.latitude, 'lng': _destinationLocation!.longitude} : {}, 'price': _priceController.text}));
      final data = json.decode(response.body);
      if (response.statusCode == 201 && data['success'] == true) { setState(() => _activeRide = data['ride']); _startStatusTimer(); }
      else { throw Exception(data['message'] ?? 'فشل إرسال الطلب'); }
    } catch (e) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red));
    } finally { setState(() => _isLoading = false); }
  }
  Future<void> _cancelRide() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(Uri.parse('${ApiService.baseUrl}/taxi/v1/rides/cancel'), headers: {'Authorization': 'Bearer ${widget.token}'});
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        setState(() { _activeRide = null; _destinationLocation = null; });
        _statusTimer?.cancel();
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message']), backgroundColor: Colors.green));
      } else { throw Exception(data['message'] ?? 'فشل إلغاء الطلب'); }
    } catch (e) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red));
    } finally { setState(() => _isLoading = false); }
  }
  List<Marker> _buildMarkers() {
    final List<Marker> markers = [];
    if (_activeRide != null && _assignedDriverLocation != null) {
      markers.add(Marker(width: 40, height: 40, point: _assignedDriverLocation!, child: RotatingVehicleIcon(vehicleType: _activeRide!['driver']?['vehicle_type'] ?? 'Car', bearing: 0)));
    } else {
      for (var driverId in _driversData.keys) {
        final driver = _driversData[driverId];
        final animation = _animations[driverId];
        final segment = _driverAnimationSegments[driverId];
        if (animation != null && segment != null) {
          final currentPosition = animation.value;
          final bearing = calculateBearing(segment.begin, segment.end);
          markers.add(Marker(width: 40, height: 40, point: currentPosition, child: RotatingVehicleIcon(vehicleType: driver['vehicle_type']?.toString() ?? 'Car', bearing: bearing)));
        }
      }
    }
    if (_pickupLocation != null) markers.add(Marker(width: 80.0, height: 80.0, point: _pickupLocation!, child: const PinMarker(label: 'الانطلاق', color: Colors.orange)));
    if (_destinationLocation != null) markers.add(Marker(width: 80.0, height: 80.0, point: _destinationLocation!, child: const PinMarker(label: 'الوصول', color: Colors.blue, icon: Icons.flag)));
    return markers;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: const LatLng(32.5, 45.8), initialZoom: 13.0, onTap: _activeRide == null ? _handleTap : null),
            children: [
              TileLayer(urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png', subdomains: const ['a', 'b', 'c'], retinaMode: true),
              if (_routeToCustomer.isNotEmpty) PolylineLayer(polylines: [Polyline(points: _routeToCustomer, color: Colors.blue, strokeWidth: 5)]),
              MarkerLayer(markers: _buildMarkers()),
            ],
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          if (!_isLoading && _activeRide != null) Positioned(bottom: 0, left: 0, right: 0, child: ActiveRideInfoCard(ride: _activeRide!, onCancel: _cancelRide, authResult: widget.authResult))
          else if (!_isLoading) Positioned(bottom: 0, left: 0, right: 0, child: RequestControlCard(pickupLocation: _pickupLocation, destinationLocation: _destinationLocation, onConfirm: _requestRide, priceController: _priceController)),
          if (!_isLoading) Positioned(bottom: (_activeRide == null) ? 220 : 140, right: 20, child: FloatingActionButton(onPressed: _checkCurrentUserLocation, backgroundColor: Colors.white, child: const Icon(Icons.my_location, color: Colors.blue))),
        ],
      ),
    );
  }
}

class RequestControlCard extends StatelessWidget { final LatLng? pickupLocation; final LatLng? destinationLocation; final VoidCallback onConfirm; final TextEditingController priceController; const RequestControlCard({super.key, this.pickupLocation, this.destinationLocation, required this.onConfirm, required this.priceController}); @override Widget build(BuildContext context) { return Card(margin: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 5, child: Padding(padding: const EdgeInsets.all(16.0), child: Column(mainAxisSize: MainAxisSize.min, children: [ _buildLocationRow('الانطلاق', 'حدد نقطة الانطلاق على الخريطة', pickupLocation, Colors.orange), const Divider(height: 20), _buildLocationRow('الوصول', 'حدد الوجهة (اختياري)', destinationLocation, Colors.blue), const SizedBox(height: 15), TextField(controller: priceController, keyboardType: const TextInputType.numberWithOptions(decimal: false), decoration: const InputDecoration(labelText: 'السعر المعروض (الكروة)', prefixIcon: Icon(Icons.money))), const SizedBox(height: 15), SizedBox(width: double.infinity, child: ElevatedButton(onPressed: pickupLocation != null ? onConfirm : null, style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text('اطلب الآن'))), ], ), ), ); } Widget _buildLocationRow(String title, String hint, LatLng? location, Color color) { return Row(children: [Icon(Icons.circle, color: color, size: 12), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text(location != null ? 'تم تحديد الموقع' : hint, style: TextStyle(color: Colors.grey[600], fontSize: 12))]))]); } }
class ActiveRideInfoCard extends StatelessWidget {
  final Map<String, dynamic> ride; final VoidCallback onCancel; final AuthResult authResult;
  const ActiveRideInfoCard({super.key, required this.ride, required this.onCancel, required this.authResult});
  String _getStatusText(String status) {
    switch (status) {
      case 'pending': return 'جاري البحث عن سائق...';
      case 'accepted': return 'تم قبول طلبك! السائق في الطريق...';
      case 'arrived_pickup': return 'السائق وصل لنقطة الانطلاق';
      case 'ongoing': return 'الرحلة جارية...';
      case 'completed': return 'اكتملت الرحلة';
      case 'cancelled': return 'تم إلغاء الرحلة';
      default: return 'حالة غير معروفة';
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
                trailing: IconButton(
                  icon: const Icon(Icons.call, color: Colors.green),
                  onPressed: () => makePhoneCall(driver['phone'], context),
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
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) if (mounted) setState(() => trips = List<Map<String, dynamic>>.from(data));
      } else { throw Exception('فشل تحميل الرحلات'); }
    } catch (e) { if (mounted) setState(() => error = 'فشل تحميل البيانات. تحقق من اتصالك.');
    } finally { if (mounted) setState(() => isLoading = false); }
  }
  Future<void> _bookTrip({ required String tripId, required String name, required String phone, required String address, required int quantity, }) async {
    try {
      final response = await http.post(Uri.parse('${ApiService.baseUrl}/taxi/v1/book'), headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.authResult.token}'}, body: json.encode({ 'trip_id': tripId, 'name': name, 'phone': phone, 'address': address, 'quantity': quantity }));
      final result = json.decode(response.body);
      if (response.statusCode == 200 && result['success'] == true) {
        _updateTripLocally(Map<String, dynamic>.from(result['trip']));
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم الحجز بنجاح لـ $quantity مقاعد!'), backgroundColor: Colors.green));
      } else { throw Exception(result['message'] ?? 'فشل الحجز'); }
    }  catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في الحجز: ${e.toString()}'), backgroundColor: Colors.red)); }
  }
  Future<void> _cancelBooking(String tripId, String passengerId) async {
    try {
      final response = await http.post(Uri.parse('${ApiService.baseUrl}/taxi/v1/cancel'), headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.authResult.token}'}, body: json.encode({ 'trip_id': tripId, 'passenger_id': passengerId }));
      final result = json.decode(response.body);
      if (response.statusCode == 200 && result['success'] == true) {
        _updateTripLocally(Map<String, dynamic>.from(result['trip']));
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إلغاء الحجز بنجاح!'), backgroundColor: Colors.green));
      } else { throw Exception(result['message'] ?? 'فشل الإلغاء'); }
    } catch (e) { if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في الإلغاء: ${e.toString().replaceFirst("Exception: ", "")}'), backgroundColor: Colors.red)); _loadTrips(); } }
  }
  void _updateTripLocally(Map<String, dynamic> updatedTrip) { setState(() { final index = trips.indexWhere((t) => t['id'].toString() == updatedTrip['id'].toString()); if (index != -1) trips[index] = updatedTrip; }); }
  void _showBookingDialog(Map<String, dynamic> trip) {
    final nameController = TextEditingController(text: widget.authResult.displayName); final phoneController = TextEditingController(); final addressController = TextEditingController(); final availableSeats = (trip['available_seats'] ?? 0) as int; int selectedQuantity = availableSeats > 0 ? 1 : 0;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (context, setStateSB) => Dialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: Padding(padding: const EdgeInsets.all(16.0), child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [ const Text('حجز مقعد', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)), const SizedBox(height: 16), Text('${trip['from']} → ${trip['to']}', style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center), Text('${_formatDate(trip['date'].toString())} - ${trip['time']}', style: const TextStyle(color: Colors.grey)), const SizedBox(height: 20), TextField(controller: nameController, decoration: const InputDecoration(labelText: 'الاسم الكامل', prefixIcon: Icon(Icons.person))), const SizedBox(height: 12), TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'رقم الهاتف', prefixIcon: Icon(Icons.phone)), keyboardType: TextInputType.phone), const SizedBox(height: 12), TextField(controller: addressController, decoration: const InputDecoration(labelText: 'عنوان الاستلام', prefixIcon: Icon(Icons.location_on))), const SizedBox(height: 20), Row(mainAxisAlignment: MainAxisAlignment.center, children: [ const Text('عدد المقاعد:'), IconButton(icon: const Icon(Icons.remove), onPressed: selectedQuantity > 1 ? () => setStateSB(() => selectedQuantity--) : null), Text('$selectedQuantity'), IconButton(icon: const Icon(Icons.add), onPressed: selectedQuantity < availableSeats ? () => setStateSB(() => selectedQuantity++) : null), ]), const SizedBox(height: 20), Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [ TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')), ElevatedButton(onPressed: (selectedQuantity > 0 && nameController.text.isNotEmpty && phoneController.text.isNotEmpty && addressController.text.isNotEmpty) ? () async { Navigator.pop(ctx); await _bookTrip(tripId: trip['id'].toString(), name: nameController.text, phone: phoneController.text, address: addressController.text, quantity: selectedQuantity); } : null, child: const Text('تأكيد الحجز')), ], ), ], ), ), ), ), ), );
  }
  void _showPassengersScreen(Map<String, dynamic> trip) { Navigator.push(context, MaterialPageRoute(builder: (context) => PassengersScreen(trip: trip, currentUserId: widget.authResult.userId, onCancelBooking: (passengerId) async => await _cancelBooking(trip['id'].toString(), passengerId)))).then((_) => _loadTrips()); }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? ListView.builder(itemCount: 3, itemBuilder: (context, index) => const ShimmerListItem())
          : error.isNotEmpty
          ? Center(child: Text(error, style: const TextStyle(color: Colors.red)))
          : trips.isEmpty
          ? EmptyStateWidget(svgAsset: '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect><line x1="16" y1="2" x2="16" y2="6"></line><line x1="8" y1="2" x2="8" y2="6"></line><line x1="3" y1="10" x2="21" y2="10"></line></svg>''', message: 'لا توجد رحلات مجدولة متاحة حالياً.')
          : RefreshIndicator(
        onRefresh: _loadTrips,
        child: AnimationLimiter(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: trips.length,
            itemBuilder: (context, index) {
              final trip = trips[index];
              final passengers = (trip['passengers'] as List?) ?? [];
              final totalSeats = int.tryParse(trip['total_seats'].toString()) ?? 0;
              final bookedSeatsCount = passengers.length;
              final availableSeats = totalSeats - bookedSeatsCount;
              final userBookedSeats = passengers.where((p) => p['user_id']?.toString() == widget.authResult.userId).length;
              final driver = (trip['driver'] as Map?) ?? {};
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
  final Map<String, dynamic> trip;
  final String currentUserId;
  final Future<void> Function(String) onCancelBooking;

  const PassengersScreen({ super.key, required this.trip, required this.currentUserId, required this.onCancelBooking });

  String _formatDate(String dateString) { try { return DateFormat('yyyy/MM/dd', 'en_US').format(DateTime.parse(dateString)); } catch (e) { return dateString; } }

  @override
  Widget build(BuildContext context) {
    final passengers = (trip['passengers'] as List?)?.map((p) => Map<String, dynamic>.from(p)).toList() ?? [];
    final totalSeats = int.tryParse(trip['total_seats'].toString()) ?? 0;
    final currentUserBookings = passengers.where((p) => p['user_id']?.toString() == currentUserId).toList();
    final bool isDriver = trip['driver']?['user_id']?.toString() == currentUserId;

    return Scaffold(
      appBar: AppBar(title: const Text('قائمة الركاب'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [Text('${trip['from']} → ${trip['to']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center), const SizedBox(height: 8), Text('${_formatDate(trip['date'].toString())} - ${trip['time']}', style: const TextStyle(color: Colors.grey)), const SizedBox(height: 8), Text('المقاعد: ${passengers.length}/$totalSeats (المتبقي: ${totalSeats - passengers.length})', style: const TextStyle(fontWeight: FontWeight.bold))]))),
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
                    leading: CircleAvatar(backgroundColor: Colors.blue.withOpacity(0.2), child: Text('${index + 1}')),
                    title: Text(passenger['name']?.toString() ?? 'غير معروف'),
                    subtitle: Text('معرف الحجز: ${passenger['id']?.toString() ?? ''}', style: const TextStyle(fontSize: 10, color: Colors.blueGrey)),
                    trailing: IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () => showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('تأكيد الإلغاء'),
                          content: const Text('هل أنت متأكد من إلغاء هذا المقعد؟'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('لا')),
                            TextButton(onPressed: () async { Navigator.pop(dialogContext); await onCancelBooking(passenger['id'].toString()); if(context.mounted) Navigator.pop(context); }, child: const Text('نعم، إلغاء')),
                          ],
                        ),
                      ),
                    ),
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
  Future<void> _selectTime() async { TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now()); if (picked != null) setState(() => _timeController.text = picked.format(context)); }
  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final response = await http.post(Uri.parse('${ApiService.baseUrl}/taxi/v1/driver/create-trip'), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.authResult.token}'}, body: json.encode({'from': _fromController.text, 'to': _toController.text, 'date': _dateController.text, 'time': _timeController.text, 'seats': _seatsController.text}));
        final data = json.decode(response.body);
        if (response.statusCode == 201 && data['success'] == true) {
          if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message']), backgroundColor: Colors.green));
          _formKey.currentState?.reset(); _fromController.clear(); _toController.clear(); _dateController.clear(); _timeController.clear(); _seatsController.clear();
        } else { throw Exception(data['message'] ?? 'فشل إنشاء الرحلة'); }
      } catch (e) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red));
      } finally { if(mounted) setState(() => _isLoading = false); }
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
              TextFormField(controller: _fromController, decoration: const InputDecoration(labelText: 'من'), validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null),
              const SizedBox(height: 15),
              TextFormField(controller: _toController, decoration: const InputDecoration(labelText: 'إلى'), validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null),
              const SizedBox(height: 15),
              TextFormField(controller: _dateController, decoration: const InputDecoration(labelText: 'التاريخ', prefixIcon: Icon(Icons.calendar_today)), readOnly: true, onTap: _selectDate, validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null),
              const SizedBox(height: 15),
              TextFormField(controller: _timeController, decoration: const InputDecoration(labelText: 'الوقت', prefixIcon: Icon(Icons.access_time)), readOnly: true, onTap: _selectTime, validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null),
              const SizedBox(height: 15),
              TextFormField(controller: _seatsController, decoration: const InputDecoration(labelText: 'عدد المقاعد'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null),
              const SizedBox(height: 30),
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
    } catch(e) { /* silent */ } finally { if(mounted) setState(() => _isLoading = false); }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _fetchNotifications,
        child: _isLoading
            ? ListView.builder(itemCount: 5, itemBuilder: (context, index) => const ShimmerListItem())
            : _notifications == null || _notifications!.isEmpty
            ? EmptyStateWidget(svgAsset: '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"></path><path d="M13.73 21a2 2 0 0 1-3.46 0"></path></svg>''', message: 'لا توجد إشعارات جديدة.')
            : AnimationLimiter(
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
                      child: ListTile(
                        leading: const Icon(Icons.notifications_active, color: Colors.amber),
                        title: Text(notif['title']),
                        subtitle: Text(notif['content']),
                        trailing: Text(DateFormat('yyyy-MM-dd').format(DateTime.parse(notif['date']))),
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
    } catch (e) { /* silent */ } finally { if (mounted) setState(() => _isLoading = false); }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? ListView.builder(itemCount: 4, itemBuilder: (context, index) => const ShimmerListItem())
          : _myTrips == null || _myTrips!.isEmpty
          ? EmptyStateWidget(svgAsset: '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline><line x1="16" y1="13" x2="8" y2="13"></line><line x1="16" y1="17" x2="8" y2="17"></line><polyline points="10 9 9 9 8 9"></polyline></svg>''', message: 'لم تقم بإنشاء أي رحلات بعد.', buttonText: 'إنشاء رحلة جديدة', onButtonPressed: widget.navigateToCreate)
          : RefreshIndicator(
        onRefresh: _fetchMyTrips,
        child: AnimationLimiter(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _myTrips!.length,
            itemBuilder: (context, index) {
              final trip = _myTrips![index];
              final passengers = (trip['passengers'] as List?) ?? [];
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
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PassengersScreen(trip: trip, currentUserId: widget.authResult.userId, onCancelBooking: (_){ return Future.value(); }))),
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

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null && mounted) {
      setState(() {
        _timeController.text = picked.format(context);
      });
    }
  }

  Future<void> _submitRequest() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final body = {
          'from': _fromController.text,
          'to': _toController.text,
          'price': _priceController.text,
          'time': _timeController.text,
          'phone': _phoneController.text,
          'with_return': _withReturn,
        };
        final response = await ApiService.createPrivateRequest(widget.authResult.token, body);
        final data = json.decode(response.body);

        if (response.statusCode == 201 && data['success'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message']), backgroundColor: Colors.green));
            _formKey.currentState?.reset();
            _fromController.clear();
            _toController.clear();
            _priceController.clear();
            _timeController.clear();
            _phoneController.clear();
            setState(() => _withReturn = false);
          }
        } else {
          throw Exception(data['message'] ?? 'فشل إرسال الطلب');
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('إنشاء طلب رحلة خاصة', style: Theme.of(context).textTheme.headlineSmall),
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
              SwitchListTile(
                title: const Text('هل الرحلة مع عودة؟'),
                value: _withReturn,
                onChanged: (val) => setState(() => _withReturn = val),
                secondary: Icon(_withReturn ? Icons.sync : Icons.sync_disabled),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitRequest,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('إرسال الطلب للسائقين'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DriverPrivateRequestsScreen extends StatefulWidget {
  final AuthResult authResult;
  const DriverPrivateRequestsScreen({super.key, required this.authResult});
  @override
  State<DriverPrivateRequestsScreen> createState() => _DriverPrivateRequestsScreenState();
}
class _DriverPrivateRequestsScreenState extends State<DriverPrivateRequestsScreen> {
  late Future<List<dynamic>> _privateRequestsFuture;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  void _loadRequests() {
    _privateRequestsFuture = ApiService.getAvailablePrivateRequests(widget.authResult.token);
  }

  Future<void> _acceptRequest(String requestId) async {
    try {
      final response = await ApiService.acceptPrivateRequest(widget.authResult.token, requestId);
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message']), backgroundColor: Colors.green));
          setState(() { _loadRequests(); }); // Refresh the list
        }
      } else {
        throw Exception(data['message'] ?? 'فشل قبول الطلب');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => setState(() => _loadRequests()),
        child: FutureBuilder<List<dynamic>>(
          future: _privateRequestsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListView.builder(itemCount: 4, itemBuilder: (ctx, i) => const ShimmerListItem());
            }
            if (snapshot.hasError) {
              return Center(child: Text('خطأ في تحميل البيانات: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return EmptyStateWidget(
                svgAsset: '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2L2 7l10 5 10-5-10-5z"></path><path d="M2 17l10 5 10-5"></path><path d="M2 12l10 5 10-5"></path></svg>''',
                message: 'لا توجد طلبات خاصة متاحة حالياً.',
              );
            }

            final requests = snapshot.data!;
            return AnimationLimiter(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final request = requests[index];
                  return PrivateRequestCard(
                    request: request,
                    currentDriverUserId: widget.authResult.userId,
                    onAccept: () => _acceptRequest(request['id'].toString()),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class PrivateRequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final String currentDriverUserId;
  final VoidCallback onAccept;

  const PrivateRequestCard({super.key, required this.request, required this.onAccept, required this.currentDriverUserId});

  @override
  Widget build(BuildContext context) {
    final bool isAccepted = request['status'] == 'accepted';
    final acceptedDriver = request['accepted_driver'];
    final bool isAcceptedByMe = isAccepted && acceptedDriver?['user_id']?.toString() == currentDriverUserId;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shadowColor: isAccepted ? Colors.green.withOpacity(0.2) : Colors.amber.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: isAccepted ? Colors.green : Colors.amber, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.directions, color: Colors.blueAccent),
                const SizedBox(width: 8),
                Expanded(child: Text('${request['from']} → ${request['to']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                if (request['with_return'] == true)
                  const Chip(label: Text('مع عودة'), avatar: Icon(Icons.sync, size: 16), padding: EdgeInsets.zero),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoChip(Icons.access_time, request['time'], Colors.orange),
                _buildInfoChip(Icons.payments, '${request['price']} د.ع', Colors.green),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.person_outline, 'الزبون:', request['customer_name']),
            const SizedBox(height: 8),
            const Divider(height: 20),
            if (isAccepted)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    isAcceptedByMe ? 'تم القبول بواسطتك' : 'تم القبول بواسطة: ${acceptedDriver?['name'] ?? 'سائق آخر'}',
                    style: TextStyle(color: isAcceptedByMe ? Colors.blue : Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onAccept,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('قبول هذا الطلب'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isAcceptedByMe ? () => makePhoneCall(request['phone'], context) : null,
                icon: const Icon(Icons.call_outlined),
                label: const Text('الاتصال بالزبون'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isAcceptedByMe ? Colors.blueAccent : Colors.grey,
                  side: BorderSide(color: isAcceptedByMe ? Colors.blueAccent : Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Chip(
      avatar: Icon(icon, color: color, size: 18),
      label: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: color.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.grey[700])),
        const SizedBox(width: 4),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold))),
      ],
    );
  }
}

String _formatDate(String dateString) { try { return DateFormat('yyyy/MM/dd', 'en_US').format(DateTime.parse(dateString)); } catch (e) { return dateString; } }