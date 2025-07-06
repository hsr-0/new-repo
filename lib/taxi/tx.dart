import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// =============================================================================
//  Entry Point & App Theme
// =============================================================================
void main() {
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
          titleTextStyle: const TextStyle(
            fontFamily: 'Cairo',
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.amber, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber[700],
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
  final String token;
  final String userId;
  final String displayName;
  final bool isDriver;
  final String? driverStatus;

  AuthResult({required this.token, required this.userId, required this.displayName, required this.isDriver, this.driverStatus});
}

class ApiService {
  static const String baseUrl = 'https://banner.beytei.com/wp-json';
  static final _storage = const FlutterSecureStorage();

  static Future<void> storeAuthData(AuthResult authResult) async {
    await _storage.write(key: 'auth_token', value: authResult.token);
    await _storage.write(key: 'user_id', value: authResult.userId);
    await _storage.write(key: 'display_name', value: authResult.displayName);
    await _storage.write(key: 'is_driver', value: authResult.isDriver.toString());
    if (authResult.driverStatus != null) {
      await _storage.write(key: 'driver_status', value: authResult.driverStatus);
    }
  }

  static Future<void> clearAuthData() async {
    await _storage.deleteAll();
  }

  static Future<AuthResult?> getStoredAuthData() async {
    final token = await _storage.read(key: 'auth_token');
    final userId = await _storage.read(key: 'user_id');
    final displayName = await _storage.read(key: 'display_name');
    final isDriverStr = await _storage.read(key: 'is_driver');
    final driverStatus = await _storage.read(key: 'driver_status');

    if (token != null && userId != null && displayName != null && isDriverStr != null) {
      return AuthResult(
        token: token,
        userId: userId,
        displayName: displayName,
        isDriver: isDriverStr.toLowerCase() == 'true',
        driverStatus: driverStatus,
      );
    }
    return null;
  }
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static void initialize() {
    const InitializationSettings initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings("@mipmap/ic_launcher"),
      iOS: DarwinInitializationSettings(),
    );
    _notificationsPlugin.initialize(initializationSettings);
  }

  static Future<void> showNotification(String title, String body) async {
    const NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        "taxi_app_channel",
        "Taxi App Notifications",
        importance: Importance.max,
        priority: Priority.high,
      ),
    );
    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.toSigned(31),
      title,
      body,
      notificationDetails,
    );
  }
}

// =============================================================================
//  Authentication Gate & Welcome Screen
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
    NotificationService.initialize();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final authData = await ApiService.getStoredAuthData();
    if (mounted) {
      setState(() {
        _authResult = authData;
        _authStatus = authData != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
      });
    }
  }

  void _onLoginSuccess(AuthResult authResult) {
    setState(() {
      _authResult = authResult;
      _authStatus = AuthStatus.authenticated;
    });
  }

  Future<void> _logout() async {
    await ApiService.clearAuthData();
    setState(() {
      _authResult = null;
      _authStatus = AuthStatus.unauthenticated;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_authStatus) {
      case AuthStatus.unknown:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.unauthenticated:
        return WelcomeScreen(onLoginSuccess: _onLoginSuccess);
      case AuthStatus.authenticated:
        if (_authResult!.isDriver) {
          if (_authResult!.driverStatus == 'approved') {
            return DriverMainScreen(authResult: _authResult!, onLogout: _logout);
          } else {
            return DriverPendingScreen(onLogout: _logout);
          }
        } else {
          return CustomerMainScreen(authResult: _authResult!, onLogout: _logout);
        }
    }
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

  Future<void> _submitCustomerLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; _errorMessage = null; });
      try {
        final response = await http.post(
          Uri.parse('${ApiService.baseUrl}/taxi-auth/v1/register/customer'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'name': _nameController.text,
            'phone_number': _phoneController.text
          }),
        );
        final data = json.decode(response.body);
        if (response.statusCode == 200 && data['success'] == true) {
          final authResult = AuthResult(
            token: data['token'],
            userId: data['user_id'].toString(),
            displayName: data['display_name'],
            isDriver: data['is_driver'] ?? false,
            driverStatus: data['driver_status'],
          );
          await ApiService.storeAuthData(authResult);
          widget.onLoginSuccess(authResult);
        } else {
          throw Exception(data['message'] ?? 'فشل تسجيل الدخول أو التسجيل');
        }
      } catch (e) {
        setState(() => _errorMessage = e.toString().replaceAll("Exception: ", ""));
      } finally {
        if(mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String logoSvg = '''
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200">
      <defs><linearGradient id="a" x1="50%" x2="50%" y1="0%" y2="100%"><stop offset="0%" stop-color="#FFD54F"/><stop offset="100%" stop-color="#FF8F00"/></linearGradient></defs>
      <path fill="url(#a)" d="M100 10a90 90 0 1 0 0 180 90 90 0 0 0 0-180zm0 170a80 80 0 1 1 0-160 80 80 0 0 1 0 160z"/>
      <path fill="#FFF" d="M149.5 115.8c-1.2-5.7-6.2-10-12.1-10H62.6c-5.9 0-10.9 4.3-12.1 10L40 140h120l-10.5-24.2zM67.3 85.2h65.4c2.8 0 5 2.2 5 5v10.6H62.3V90.2c0-2.8 2.2-5 5-5z"/>
      <circle cx="70" cy="135" r="10" fill="#212121"/>
      <circle cx="130" cy="135" r="10" fill="#212121"/>
    </svg>
    ''';

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.amber.shade100, Colors.amber.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
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
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(labelText: 'الاسم الكامل', prefixIcon: Icon(Icons.person_outline)),
                            validator: (v) => v!.isEmpty ? 'الرجاء إدخال الاسم' : null,
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(labelText: 'رقم الهاتف', prefixIcon: Icon(Icons.phone_outlined)),
                            keyboardType: TextInputType.phone,
                            validator: (v) => v!.isEmpty ? 'الرجاء إدخال رقم الهاتف' : null,
                          ),
                          const SizedBox(height: 20),
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                            ),
                          _isLoading
                              ? const CircularProgressIndicator()
                              : ElevatedButton(
                            onPressed: _submitCustomerLogin,
                            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                            child: const Text('دخول / تسجيل'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                TextButton.icon(
                  icon: const Icon(Icons.local_taxi),
                  label: const Text('هل أنت سائق؟ اضغط هنا'),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DriverAuthScreen(onLoginSuccess: widget.onLoginSuccess))),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey[800]),
                ),
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
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; _errorMessage = null; });
      try {
        final response = await http.post(
          Uri.parse('${ApiService.baseUrl}/taxi-auth/v1/login'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'phone_number': _phoneController.text}),
        );
        final data = json.decode(response.body);
        if (response.statusCode == 200 && data['success'] == true) {
          final authResult = AuthResult(
            token: data['token'],
            userId: data['user_id'].toString(),
            displayName: data['display_name'],
            isDriver: data['is_driver'] ?? false,
            driverStatus: data['driver_status'],
          );
          await ApiService.storeAuthData(authResult);
          widget.onLoginSuccess(authResult);
        } else {
          throw Exception(data['message'] ?? 'فشل تسجيل الدخول');
        }
      } catch (e) {
        setState(() => _errorMessage = e.toString().replaceAll("Exception: ", ""));
      } finally {
        if(mounted) setState(() => _isLoading = false);
      }
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
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'رقم الهاتف', prefixIcon: Icon(Icons.phone)),
              keyboardType: TextInputType.phone,
              validator: (v) => v!.isEmpty ? 'الرجاء إدخال رقم الهاتف' : null,
            ),
            const SizedBox(height: 30),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('دخول'),
              ),
            ),
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('بوابة السائقين'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'تسجيل دخول'),
              Tab(text: 'تسجيل جديد'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            LoginScreen(onLoginSuccess: onLoginSuccess),
            DriverRegistrationScreen(onLoginSuccess: onLoginSuccess),
          ],
        ),
      ),
    );
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
  String _vehicleType = 'Tuktuk';
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; _errorMessage = null; });
      try {
        final response = await http.post(
          Uri.parse('${ApiService.baseUrl}/taxi-auth/v1/register/driver'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'name': _nameController.text,
            'phone': _phoneController.text,
            'vehicle_type': _vehicleType,
            'car_model': _modelController.text,
            'car_color': _colorController.text,
          }),
        );
        final data = json.decode(response.body);
        if (response.statusCode == 201 && data['success'] == true) {
          if(mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message']), backgroundColor: Colors.green));
            Navigator.of(context).pop();
          }
        } else {
          throw Exception(data['message'] ?? 'فشل التسجيل');
        }
      } catch (e) {
        setState(() => _errorMessage = e.toString().replaceAll("Exception: ", ""));
      } finally {
        if(mounted) setState(() => _isLoading = false);
      }
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
            DropdownButtonFormField<String>(
              value: _vehicleType,
              decoration: const InputDecoration(labelText: 'نوع المركبة'),
              items: const [
                DropdownMenuItem(value: 'Tuktuk', child: Text('توك توك')),
                DropdownMenuItem(value: 'Car', child: Text('سيارة')),
              ],
              onChanged: (value) => setState(() => _vehicleType = value!),
            ),
            const SizedBox(height: 15),
            TextFormField(controller: _modelController, decoration: const InputDecoration(labelText: 'موديل المركبة'), validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null),
            const SizedBox(height: 15),
            TextFormField(controller: _colorController, decoration: const InputDecoration(labelText: 'لون المركبة'), validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null),
            const SizedBox(height: 30),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('تسجيل حساب جديد'),
              ),
            ),
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
  final AuthResult authResult;
  final VoidCallback onLogout;
  const CustomerMainScreen({super.key, required this.authResult, required this.onLogout});

  @override
  State<CustomerMainScreen> createState() => _CustomerMainScreenState();
}

class _CustomerMainScreenState extends State<CustomerMainScreen> {
  int _selectedIndex = 1; // Default to scheduled trips
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      QuickRideMapScreen(token: widget.authResult.token),
      TripListScreen(authResult: widget.authResult),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('مرحباً، ${widget.authResult.displayName}'),
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: widget.onLogout)],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'طلب سريع'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'رحلات مجدولة'),
        ],
      ),
    );
  }
}

// =============================================================================
//  Driver Screens
// =============================================================================

class DriverPendingScreen extends StatelessWidget {
  final VoidCallback onLogout;
  const DriverPendingScreen({super.key, required this.onLogout});

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
              Text('سيتم مراجعة طلبك من قبل الإدارة. يرجى المحاولة مرة أخرى لاحقاً.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 30),
              TextButton(onPressed: onLogout, child: const Text('تسجيل الخروج')),
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

class _DriverMainScreenState extends State<DriverMainScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DriverAvailableRidesScreen(authResult: widget.authResult, onLogout: widget.onLogout),
      DriverCreateTripScreen(authResult: widget.authResult),
      NotificationsScreen(token: widget.authResult.token),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'الطلبات المتاحة'),
          BottomNavigationBarItem(icon: Icon(Icons.add_road), label: 'إنشاء رحلة'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'الإشعارات'),
        ],
      ),
    );
  }
}

class DriverAvailableRidesScreen extends StatefulWidget {
  final AuthResult authResult;
  final VoidCallback onLogout;
  const DriverAvailableRidesScreen({super.key, required this.authResult, required this.onLogout});

  @override
  State<DriverAvailableRidesScreen> createState() => _DriverAvailableRidesScreenState();
}

class _DriverAvailableRidesScreenState extends State<DriverAvailableRidesScreen> {
  List<dynamic>? _availableRides;
  bool _isLoading = true;
  Timer? _ridesTimer;

  @override
  void initState() {
    super.initState();
    _fetchAvailableRides();
    _ridesTimer = Timer.periodic(const Duration(seconds: 30), (timer) => _fetchAvailableRides());
  }

  @override
  void dispose() {
    _ridesTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchAvailableRides() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/taxi/v1/driver/available-rides'),
        headers: {'Authorization': 'Bearer ${widget.authResult.token}'},
      );
      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        setState(() => _availableRides = data['rides']);
      }
    } catch (e) {
      // Handle error silently in background
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptRide(String rideId) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/taxi/v1/driver/accept-ride'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.authResult.token}'},
        body: json.encode({'ride_id': rideId}),
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        if(mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => DriverCurrentRideScreen(initialRide: data['ride'], authResult: widget.authResult, onLogout: widget.onLogout,)));
      } else {
        throw Exception(data['message'] ?? 'فشل قبول الطلب');
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      _fetchAvailableRides();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الطلبات المتاحة'),
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: widget.onLogout)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _availableRides == null || _availableRides!.isEmpty
          ? Center(child: Text('لا توجد طلبات متاحة حالياً', style: TextStyle(fontSize: 18, color: Colors.grey[600])))
          : RefreshIndicator(
        onRefresh: _fetchAvailableRides,
        child: ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: _availableRides!.length,
          itemBuilder: (context, index) {
            final ride = _availableRides![index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              child: ListTile(
                leading: const Icon(Icons.pin_drop_outlined, color: Colors.green),
                title: Text('طلب جديد بسعر: ${ride['price'] ?? 'N/A'} IQD'),
                subtitle: Text('تاريخ الطلب: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(ride['request_time']))}'),
                trailing: ElevatedButton(
                  child: const Text('قبول'),
                  onPressed: () => _acceptRide(ride['id'].toString()),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class DriverCurrentRideScreen extends StatefulWidget {
  final Map<String, dynamic> initialRide;
  final AuthResult authResult;
  final VoidCallback onLogout;
  const DriverCurrentRideScreen({super.key, required this.initialRide, required this.authResult, required this.onLogout});

  @override
  State<DriverCurrentRideScreen> createState() => _DriverCurrentRideScreenState();
}

class _DriverCurrentRideScreenState extends State<DriverCurrentRideScreen> {
  late Map<String, dynamic> _currentRide;
  bool _isLoading = false;

  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStream;
  LatLng? _driverLocation;
  List<LatLng> _routePoints = [];
  double _distanceToPickup = 0.0;

  final String _orsApiKey = 'YOUR_OPENROUTESERVICE_API_KEY';

  @override
  void initState() {
    super.initState();
    _currentRide = widget.initialRide;
    _startDriverLocationTracking();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  void _startDriverLocationTracking() {
    _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.bestForNavigation, distanceFilter: 10)
    ).listen((Position position) {
      if(mounted) {
        final newLocation = LatLng(position.latitude, position.longitude);
        final pickupPoint = LatLng(double.parse(_currentRide['pickup']['lat']), double.parse(_currentRide['pickup']['lng']));
        setState(() {
          _driverLocation = newLocation;
          _distanceToPickup = Geolocator.distanceBetween(newLocation.latitude, newLocation.longitude, pickupPoint.latitude, pickupPoint.longitude);
        });
      }
    });
  }

  Future<void> _getRoute(LatLng start, LatLng end) async {
    if (_orsApiKey == 'YOUR_OPENROUTESERVICE_API_KEY') {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("الرجاء إضافة مفتاح API الخاص بـ OpenRouteService"), backgroundColor: Colors.red,));
      return;
    }

    final url = 'https://api.openrouteservice.org/v2/directions/driving-car?api_key=$_orsApiKey&start=${start.longitude},${start.latitude}&end=${end.longitude},${end.latitude}';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final coordinates = data['features'][0]['geometry']['coordinates'] as List;
        if(mounted) {
          setState(() {
            _routePoints = coordinates.map((c) => LatLng(c[1], c[0])).toList();
          });
        }
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("فشل رسم المسار: ${e.toString()}"), backgroundColor: Colors.red));
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/taxi/v1/driver/update-ride-status'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.authResult.token}'},
        body: json.encode({'ride_id': _currentRide['id'], 'status': newStatus}),
      );
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
      } else {
        throw Exception(data['message'] ?? 'فشل تحديث الحالة');
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildActionButton() {
    String status = _currentRide['status'];

    if (status == 'accepted') {
      return SizedBox(width: double.infinity, child: ElevatedButton.icon(
        icon: const Icon(Icons.near_me),
        label: const Text('ابدأ التحرك نحو العميل'),
        onPressed: _isLoading || _driverLocation == null ? null : () {
          final pickup = LatLng(double.parse(_currentRide['pickup']['lat']), double.parse(_currentRide['pickup']['lng']));
          _getRoute(_driverLocation!, pickup);
          _updateStatus('arrived_pickup');
        },
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
      ));
    }

    if (status == 'arrived_pickup') {
      return SizedBox(width: double.infinity, child: ElevatedButton.icon(
        icon: const Icon(Icons.navigation),
        label: const Text('ابدأ الرحلة إلى الوجهة'),
        onPressed: _isLoading || _driverLocation == null ? null : () {
          if (_currentRide['destination']?['lat'] != null) {
            final destination = LatLng(double.parse(_currentRide['destination']['lat']), double.parse(_currentRide['destination']['lng']));
            _getRoute(_driverLocation!, destination);
          }
          _updateStatus('ongoing');
        },
        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
      ));
    }

    if (status == 'ongoing') {
      return SizedBox(width: double.infinity, child: ElevatedButton.icon(
        icon: const Icon(Icons.check_circle),
        label: const Text('إنهاء الرحلة'),
        onPressed: _isLoading ? null : () => _updateStatus('completed'),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
      ));
    }

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
            options: MapOptions(
              initialCenter: pickupPoint,
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
              if (_routePoints.isNotEmpty)
                PolylineLayer(polylines: [Polyline(points: _routePoints, color: Colors.blue, strokeWidth: 5)]),
              MarkerLayer(markers: [
                Marker(point: pickupPoint, child: const Icon(Icons.location_on, color: Colors.green, size: 40)),
                if(destinationPoint != null)
                  Marker(point: destinationPoint, child: const Icon(Icons.flag, color: Colors.red, size: 40)),
                if (_driverLocation != null)
                  Marker(point: _driverLocation!, child: const Icon(Icons.navigation, color: Colors.blue, size: 30)),
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
                    if(status == 'accepted')
                      Text("المسافة إلى العميل: ${(_distanceToPickup / 1000).toStringAsFixed(2)} كم"),
                    const Divider(),
                    const SizedBox(height: 15),
                    _buildActionButton(),
                    if(status == 'ongoing' || status == 'arrived_pickup')
                      TextButton.icon(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        label: const Text('إلغاء الرحلة', style: TextStyle(color: Colors.red)),
                        onPressed: _isLoading ? null : () => _updateStatus('cancelled'),
                      )
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
//  Customer-Facing Screens (QuickRide, TripList, Passengers)
// =============================================================================
class QuickRideMapScreen extends StatefulWidget {
  final String token;
  const QuickRideMapScreen({super.key, required this.token});

  @override
  State<QuickRideMapScreen> createState() => _QuickRideMapScreenState();
}

class _QuickRideMapScreenState extends State<QuickRideMapScreen> {
  final MapController _mapController = MapController();
  LatLng? _pickupLocation;
  LatLng? _destinationLocation;
  bool _isSelectingPickup = true;

  Map<String, dynamic>? _activeRide;
  bool _isLoading = true;
  Timer? _statusTimer;
  final _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkCurrentUserLocation();
    _checkForActiveRide();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _checkCurrentUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خدمات الموقع معطلة.')));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم رفض إذن الوصول للموقع.')));
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم رفض إذن الموقع بشكل دائم.')));
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.bestForNavigation);
      if (mounted) {
        setState(() {
          _pickupLocation = LatLng(position.latitude, position.longitude);
          _mapController.move(_pickupLocation!, 15.0);
        });
      }
    } catch(e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل تحديد الموقع بدقة.')));
    }
  }

  Future<void> _checkForActiveRide() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/taxi/v1/rides/my-request'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['ride'] != null) {
          final newStatus = data['ride']['status'];
          if(_activeRide != null && _activeRide!['status'] != newStatus) {
            NotificationService.showNotification("تحديث حالة الطلب", "حالة طلبك الآن هي: $newStatus");
          }
          setState(() => _activeRide = data['ride']);
          _startStatusTimer();
        } else {
          setState(() => _activeRide = null);
        }
      }
    } catch(e) {
      // Ignore errors in background check
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startStatusTimer() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (_activeRide != null && ['pending', 'accepted', 'arrived_pickup', 'ongoing'].contains(_activeRide!['status'])) {
        _checkForActiveRide();
      } else {
        timer.cancel();
      }
    });
  }

  void _handleTap(LatLng latlng) {
    if (_activeRide != null) return;
    setState(() {
      if (_isSelectingPickup) {
        _pickupLocation = latlng;
      } else {
        _destinationLocation = latlng;
      }
    });
  }

  Future<void> _requestRide() async {
    if (_pickupLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء تحديد نقطة الانطلاق على الخريطة.')));
      return;
    }
    if (_priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء تحديد سعر الكروة.')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/taxi/v1/rides/request'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'},
        body: json.encode({
          'pickup': {'lat': _pickupLocation!.latitude, 'lng': _pickupLocation!.longitude},
          'destination': _destinationLocation != null ? {'lat': _destinationLocation!.latitude, 'lng': _destinationLocation!.longitude} : {},
          'price': _priceController.text,
        }),
      );
      final data = json.decode(response.body);
      if (response.statusCode == 201 && data['success'] == true) {
        setState(() => _activeRide = data['ride']);
        _startStatusTimer();
      } else {
        throw Exception(data['message'] ?? 'فشل إرسال الطلب');
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelRide() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/taxi/v1/rides/cancel'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _activeRide = null;
          _destinationLocation = null;
        });
        _statusTimer?.cancel();
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message']), backgroundColor: Colors.green));
      } else {
        throw Exception(data['message'] ?? 'فشل إلغاء الطلب');
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(32.5, 45.8), // Kut, Iraq
              initialZoom: 13.0,
              onTap: (_, latlng) => _handleTap(latlng),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
              MarkerLayer(
                markers: [
                  if (_pickupLocation != null)
                    Marker(
                      width: 80.0, height: 80.0,
                      point: _pickupLocation!,
                      child: const Column(children: [Icon(Icons.location_on, color: Colors.green, size: 40), Text('انطلاق', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))]),
                    ),
                  if (_destinationLocation != null)
                    Marker(
                      width: 80.0, height: 80.0,
                      point: _destinationLocation!,
                      child: const Column(children: [Icon(Icons.location_on, color: Colors.red, size: 40), Text('وجهة', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))]),
                    ),
                ],
              ),
            ],
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          if (!_isLoading && _activeRide != null)
            Positioned(bottom: 0, left: 0, right: 0, child: ActiveRideInfoCard(ride: _activeRide!, onCancel: _cancelRide))
          else if (!_isLoading)
            Positioned(bottom: 20, left: 20, right: 20, child: RequestControlCard(
              isSelectingPickup: _isSelectingPickup,
              onToggleSelection: () => setState(() => _isSelectingPickup = !_isSelectingPickup),
              onRequest: _requestRide,
              hasPickup: _pickupLocation != null,
              priceController: _priceController,
            )),
        ],
      ),
    );
  }
}

class RequestControlCard extends StatelessWidget {
  final bool isSelectingPickup;
  final bool hasPickup;
  final VoidCallback onToggleSelection;
  final VoidCallback onRequest;
  final TextEditingController priceController;

  const RequestControlCard({super.key, required this.isSelectingPickup, required this.onToggleSelection, required this.onRequest, required this.hasPickup, required this.priceController});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('حدد موقعك على الخريطة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilterChip(
                  label: const Text('نقطة الانطلاق'),
                  selected: isSelectingPickup,
                  onSelected: (val) => onToggleSelection(),
                  selectedColor: Colors.green[100],
                ),
                const SizedBox(width: 10),
                FilterChip(
                  label: const Text('الوجهة (اختياري)'),
                  selected: !isSelectingPickup,
                  onSelected: (val) => onToggleSelection(),
                  selectedColor: Colors.red[100],
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'السعر المعروض (الكروة)',
                prefixIcon: Icon(Icons.money),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.hail),
                label: const Text('اطلب توك توك الآن'),
                onPressed: hasPickup ? onRequest : null,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ActiveRideInfoCard extends StatelessWidget {
  final Map<String, dynamic> ride;
  final VoidCallback onCancel;

  const ActiveRideInfoCard({super.key, required this.ride, required this.onCancel});

  String _getStatusText(String status) {
    switch (status) {
      case 'pending': return 'جاري البحث عن سائق...';
      case 'accepted': return 'تم قبول طلبك!';
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
                leading: CircleAvatar(
                  backgroundImage: driver['image'] != null && driver['image'].isNotEmpty ? NetworkImage(driver['image']) : null,
                  child: driver['image'] == null || driver['image'].isEmpty ? const Icon(Icons.person) : null,
                ),
                title: Text(driver['name'] ?? 'اسم السائق'),
                subtitle: Text('${driver['car_model'] ?? ''} - ${driver['phone'] ?? ''}'),
              )
            else
              const Text('بانتظار قبول السائق...'),
            const SizedBox(height: 10),
            if (status == 'pending')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.cancel),
                  label: const Text('إلغاء الطلب'),
                  onPressed: onCancel,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                ),
              )
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
  List<Map<String, dynamic>> trips = [];
  bool isLoading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    if (!mounted) return;
    setState(() { isLoading = true; error = ''; });
    try {
      final response = await http.get(Uri.parse('${ApiService.baseUrl}/taxi/v1/trips'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          if (mounted) setState(() => trips = List<Map<String, dynamic>>.from(data));
        }
      } else {
        throw Exception('فشل تحميل الرحلات');
      }
    } catch (e) {
      if (mounted) setState(() => error = 'فشل تحميل البيانات. تحقق من اتصالك.');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _bookTrip({ required String tripId, required String name, required String phone, required String address, required int quantity, }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/taxi/v1/book'),
        headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.authResult.token}', },
        body: json.encode({ 'trip_id': tripId, 'name': name, 'phone': phone, 'address': address, 'quantity': quantity, }),
      );
      final result = json.decode(response.body);
      if (response.statusCode == 200 && result['success'] == true) {
        _updateTripLocally(Map<String, dynamic>.from(result['trip']));
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم الحجز بنجاح لـ $quantity مقاعد!'), backgroundColor: Colors.green));
      } else {
        throw Exception(result['message'] ?? 'فشل الحجز');
      }
    }  catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في الحجز: ${e.toString()}'), backgroundColor: Colors.red));
    }
  }

  Future<void> _cancelBooking(String tripId, String passengerId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/taxi/v1/cancel'),
        headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.authResult.token}', },
        body: json.encode({ 'trip_id': tripId, 'passenger_id': passengerId, }),
      );
      final result = json.decode(response.body);
      if (response.statusCode == 200 && result['success'] == true) {
        _updateTripLocally(Map<String, dynamic>.from(result['trip']));
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إلغاء الحجز بنجاح!'), backgroundColor: Colors.green));
      } else {
        throw Exception(result['message'] ?? 'فشل الإلغاء');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في الإلغاء: ${e.toString().replaceFirst("Exception: ", "")}'), backgroundColor: Colors.red));
        _loadTrips();
      }
    }
  }

  void _updateTripLocally(Map<String, dynamic> updatedTrip) {
    setState(() {
      final index = trips.indexWhere((t) => t['id'].toString() == updatedTrip['id'].toString());
      if (index != -1) {
        trips[index] = updatedTrip;
      }
    });
  }

  void _showBookingDialog(Map<String, dynamic> trip) {
    final nameController = TextEditingController(text: widget.authResult.displayName);
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final availableSeats = (trip['available_seats'] ?? 0) as int;
    int selectedQuantity = availableSeats > 0 ? 1 : 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateSB) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('حجز مقعد', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                  const SizedBox(height: 16),
                  Text('${trip['from']} → ${trip['to']}', style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  Text('${_formatDate(trip['date'].toString())} - ${trip['time']}', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'الاسم الكامل', prefixIcon: Icon(Icons.person))),
                  const SizedBox(height: 12),
                  TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'رقم الهاتف', prefixIcon: Icon(Icons.phone)), keyboardType: TextInputType.phone),
                  const SizedBox(height: 12),
                  TextField(controller: addressController, decoration: const InputDecoration(labelText: 'عنوان الاستلام', prefixIcon: Icon(Icons.location_on))),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('عدد المقاعد:'),
                      IconButton(icon: const Icon(Icons.remove), onPressed: selectedQuantity > 1 ? () => setStateSB(() => selectedQuantity--) : null),
                      Text('$selectedQuantity'),
                      IconButton(icon: const Icon(Icons.add), onPressed: selectedQuantity < availableSeats ? () => setStateSB(() => selectedQuantity++) : null),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                      ElevatedButton(
                        onPressed: (selectedQuantity > 0 && nameController.text.isNotEmpty && phoneController.text.isNotEmpty && addressController.text.isNotEmpty)
                            ? () async { Navigator.pop(ctx); await _bookTrip(tripId: trip['id'].toString(), name: nameController.text, phone: phoneController.text, address: addressController.text, quantity: selectedQuantity); }
                            : null,
                        child: const Text('تأكيد الحجز'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showPassengersScreen(Map<String, dynamic> trip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PassengersScreen(
          trip: trip,
          currentUserId: widget.authResult.userId,
          onCancelBooking: (passengerId) async {
            await _cancelBooking(trip['id'].toString(), passengerId);
          },
        ),
      ),
    ).then((_) => _loadTrips());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
          ? Center(child: Text(error, style: const TextStyle(color: Colors.red)))
          : trips.isEmpty
          ? const Center(child: Text('لا توجد رحلات متاحة حالياً'))
          : RefreshIndicator(
        onRefresh: _loadTrips,
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

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.blue, width: 2)),
                        child: ClipOval(child: driver['image'] != null && driver['image'].toString().isNotEmpty
                            ? Image.network(driver['image'].toString(), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 30))
                            : const Icon(Icons.person, size: 30)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(driver['name']?.toString() ?? 'غير معروف', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('${driver['car_model'] ?? ''} - ${driver['car_color'] ?? ''}', style: const TextStyle(color: Colors.grey)),
                      ])),
                    ]),
                    const Divider(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Expanded(child: Text(trip['from'].toString(), style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                        const Icon(Icons.arrow_forward, color: Colors.blue),
                        Expanded(child: Text(trip['to'].toString(), style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      _buildInfoItem(Icons.calendar_today, _formatDate(trip['date'].toString()), Colors.blue),
                      _buildInfoItem(Icons.access_time, trip['time'].toString(), Colors.orange),
                      _buildInfoItem(Icons.event_seat, '$bookedSeatsCount/$totalSeats', availableSeats > 0 ? Colors.green : Colors.red),
                    ]),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: OutlinedButton.icon(
                          icon: const Icon(Icons.people, size: 18),
                          label: Text('عرض الركاب (${passengers.length})'),
                          onPressed: passengers.isNotEmpty ? () => _showPassengersScreen(trip) : null)),
                      const SizedBox(width: 12),
                      Expanded(child: userBookedSeats > 0
                          ? ElevatedButton.icon(
                          icon: const Icon(Icons.cancel_outlined, size: 18),
                          label: Text('إلغاء ($userBookedSeats)'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                          onPressed: () => _showPassengersScreen(trip))
                          : ElevatedButton.icon(
                          icon: const Icon(Icons.add_shopping_cart, size: 18),
                          label: const Text('حجز مقعد'),
                          style: ElevatedButton.styleFrom(backgroundColor: availableSeats > 0 ? Colors.blue : Colors.grey, foregroundColor: Colors.white),
                          onPressed: availableSeats > 0 ? () => _showBookingDialog(trip) : null)),
                    ]),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

class PassengersScreen extends StatelessWidget {
  final Map<String, dynamic> trip;
  final String currentUserId;
  final Future<void> Function(String) onCancelBooking;

  const PassengersScreen({ super.key, required this.trip, required this.currentUserId, required this.onCancelBooking, });

  String _formatDate(String dateString) {
    try {
      return DateFormat('yyyy/MM/dd', 'en_US').format(DateTime.parse(dateString));
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final passengers = (trip['passengers'] as List?)?.map((p) => Map<String, dynamic>.from(p)).toList() ?? [];
    final totalSeats = int.tryParse(trip['total_seats'].toString()) ?? 0;
    final currentUserBookings = passengers.where((p) => p['user_id']?.toString() == currentUserId).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('قائمة الركاب'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
              Text('${trip['from']} → ${trip['to']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('${_formatDate(trip['date'].toString())} - ${trip['time']}', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              Text('المقاعد: ${passengers.length}/$totalSeats (المتبقي: ${totalSeats - passengers.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
            ]))),
            const SizedBox(height: 16),
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
                  subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('الهاتف: ${passenger['phone']?.toString() ?? ''}'),
                    if (passenger['address'] != null) Text('العنوان: ${passenger['address'].toString()}', style: const TextStyle(fontSize: 12)),
                    Text('معرف الحجز: ${passenger['id']?.toString() ?? ''}', style: const TextStyle(fontSize: 10, color: Colors.blueGrey)),
                  ]),
                  trailing: IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('تأكيد الإلغاء'),
                        content: const Text('هل أنت متأكد من إلغاء هذا المقعد؟'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('لا')),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(dialogContext);
                              await onCancelBooking(passenger['id'].toString());
                              if(context.mounted) Navigator.pop(context);
                            },
                            child: const Text('نعم، إلغاء'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
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
                  subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('الهاتف: ${passenger['phone']?.toString() ?? ''}'),
                    if (passenger['address'] != null) Text('العنوان: ${passenger['address'].toString()}', style: const TextStyle(fontSize: 12)),
                  ]),
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
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _seatsController = TextEditingController();
  bool _isLoading = false;

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 30)));
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _selectTime() async {
    TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) {
      setState(() {
        _timeController.text = picked.format(context);
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final response = await http.post(
          Uri.parse('${ApiService.baseUrl}/taxi/v1/driver/create-trip'),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.authResult.token}'},
          body: json.encode({
            'from': _fromController.text,
            'to': _toController.text,
            'date': _dateController.text,
            'time': _timeController.text,
            'seats': _seatsController.text,
          }),
        );
        final data = json.decode(response.body);
        if (response.statusCode == 201 && data['success'] == true) {
          if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message']), backgroundColor: Colors.green));
          _formKey.currentState?.reset();
        } else {
          throw Exception(data['message'] ?? 'فشل إنشاء الرحلة');
        }
      } catch (e) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red));
      } finally {
        if(mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء رحلة مجدولة')),
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading ? const CircularProgressIndicator() : const Text('إنشاء الرحلة'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NotificationsScreen extends StatefulWidget {
  final String token;
  const NotificationsScreen({super.key, required this.token});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic>? _notifications;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/taxi/v1/driver/my-notifications'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if(response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        setState(() => _notifications = data['notifications']);
      }
    } catch(e) {
      //
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإشعارات')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications == null || _notifications!.isEmpty
          ? const Center(child: Text('لا توجد إشعارات جديدة.'))
          : RefreshIndicator(
        onRefresh: _fetchNotifications,
        child: ListView.builder(
          itemCount: _notifications!.length,
          itemBuilder: (context, index) {
            final notif = _notifications![index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading: const Icon(Icons.notifications_active, color: Colors.amber),
                title: Text(notif['title']),
                subtitle: Text(notif['content']),
                trailing: Text(DateFormat('yyyy-MM-dd').format(DateTime.parse(notif['date']))),
              ),
            );
          },
        ),
      ),
    );
  }
}

String _formatDate(String dateString) {
  try {
    return DateFormat('yyyy/MM/dd', 'en_US').format(DateTime.parse(dateString));
  } catch (e) {
    return dateString;
  }
}
