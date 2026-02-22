import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart' as geolocator;

// =============================================================================
// GLOBAL VARIABLES
// =============================================================================
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final ValueNotifier<bool> refreshTrigger = ValueNotifier(false);

// =============================================================================
// MAIN ENTRY POINT
// =============================================================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.initialize();
  runApp(const DeliveryApp());
}

class DeliveryApp extends StatelessWidget {
  const DeliveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'كابتن توصيل',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        fontFamily: 'Cairo',
        scaffoldBackgroundColor: Colors.grey[100],
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          color: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      home: const AuthGate(),
    );
  }
}

// =============================================================================
// SERVICES
// =============================================================================
// =============================================================================
// SERVICE: NOTIFICATIONS (HIGH PRIORITY & LOUD SOUND)
// =============================================================================
class NotificationService {
  static final FlutterLocalNotificationsPlugin _localParams = FlutterLocalNotificationsPlugin();

  // إعداد القناة عالية الأهمية (High Importance)
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel', // نفس الاسم المستخدم في PHP
    'طلبات التوصيل العاجلة',
    description: 'تنبيهات صوتية عالية للطلبات الجديدة',
    importance: Importance.max, // أقصى أهمية (يظهر فوق التطبيقات)
    playSound: true,
    sound: RawResourceAndroidNotificationSound('woo_sound'), // اسم ملف الصوت بدون الامتداد
    enableVibration: true,
  );

  static Future<void> initialize() async {
    // 1. طلب الأذونات
    await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: true, // مهم للآيفون ليقرأ الإشعار بصوت عالٍ
        criticalAlert: true // يسمح بتجاوز الوضع الصامت في بعض الحالات
    );

    // 2. إعدادات الأندرويد
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // 3. إعدادات iOS
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    await _localParams.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    // 4. إنشاء القناة في نظام الأندرويد
    await _localParams
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 5. الاستماع للإشعارات القادمة
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;

      // حتى لو لم يرسل السيرفر عنواناً، نضع نحن عنواناً افتراضياً
      String title = notification?.title ?? "🔔 طلب جديد!";
      String body = notification?.body ?? "يوجد طلب بالقرب منك، اضغط للفتح.";

      // إظهار الإشعار فوراً
      _localParams.show(
        notification.hashCode,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            icon: '@mipmap/ic_launcher',

            // 🔥 إعدادات القوة القصوى 🔥
            importance: Importance.max,
            priority: Priority.high,
            fullScreenIntent: true, // يجعل الإشعار يظهر كشاشة كاملة أو نافذة منبثقة
            playSound: true,
            sound: const RawResourceAndroidNotificationSound('woo_sound'),
            enableVibration: true,
            styleInformation: BigTextStyleInformation(body), // لضمان ظهور النص كاملاً
          ),
          iOS: const DarwinNotificationDetails(
            presentSound: true,
            sound: 'woo_sound.caf', // صيغة الصوت للآيفون
          ),
        ),
      );

      // تحديث القائمة في الخلفية
      refreshTrigger.value = !refreshTrigger.value;
    });
  }

  static Future<String?> getFcmToken() async => await FirebaseMessaging.instance.getToken();
}
class Helper {
  static double safeDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static Future<bool> handleLocationPermission(BuildContext context) async {
    bool serviceEnabled = await geolocator.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى تفعيل الموقع (GPS)')));
      return false;
    }
    var perm = await geolocator.Geolocator.checkPermission();
    if (perm == geolocator.LocationPermission.denied) {
      perm = await geolocator.Geolocator.requestPermission();
      if (perm == geolocator.LocationPermission.denied) return false;
    }
    return perm != geolocator.LocationPermission.deniedForever;
  }
}

class AuthResult {
  final String token, userId, displayName;
  final bool isDriver;
  final String? driverStatus;
  AuthResult({required this.token, required this.userId, required this.displayName, required this.isDriver, this.driverStatus});
  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
      token: json['token'],
      userId: json['user_id'].toString(),
      displayName: json['display_name'],
      isDriver: json['is_driver'] ?? false,
      driverStatus: json['driver_status']
  );
}

class ApiService {
  static const String baseUrl = 'https://banner.beytei.com/wp-json';
  static const _storage = FlutterSecureStorage();

  static Future<void> storeAuthData(AuthResult auth) async {
    await _storage.write(key: 'token', value: auth.token);
    await _storage.write(key: 'uid', value: auth.userId);
    await _storage.write(key: 'name', value: auth.displayName);
    await _storage.write(key: 'status', value: auth.driverStatus);
  }

  static Future<AuthResult?> getStoredAuthData() async {
    try {
      final t = await _storage.read(key: 'token');
      final u = await _storage.read(key: 'uid');
      final n = await _storage.read(key: 'name');
      final s = await _storage.read(key: 'status');
      if (t != null && u != null) return AuthResult(token: t, userId: u, displayName: n ?? '', isDriver: true, driverStatus: s);
    } catch (e) {
      await _storage.deleteAll();
    }
    return null;
  }

  static Future<void> logout() async { await _storage.deleteAll(); await fb_auth.FirebaseAuth.instance.signOut(); }

  static Future<Map<String, dynamic>> login(String phone, String password) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/taxi-auth/v1/login'), headers: {'Content-Type': 'application/json'}, body: json.encode({'phone_number': phone, 'password': password}));
      return json.decode(res.body);
    } catch (e) { return {'success': false, 'message': '$e'}; }
  }

  static Future<void> updateFcmToken(String t, String fcm) async {
    try { await http.post(Uri.parse('$baseUrl/taxi-auth/v1/update-fcm-token'), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $t'}, body: json.encode({'fcm_token': fcm})); } catch (_) {}
  }

  static Future<Map<String, dynamic>> registerDriverV3(Map<String, String> fields, Map<String, XFile> files) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/taxi-auth/v3/register/driver'));
      request.fields.addAll(fields);
      for (var entry in files.entries) {
        request.files.add(await http.MultipartFile.fromPath(entry.key, entry.value.path));
      }
      final streamedRes = await request.send();
      final res = await http.Response.fromStream(streamedRes);
      return json.decode(res.body);
    } catch (e) { return {'success': false, 'message': '$e'}; }
  }

  static Future<dynamic> getAvailableDeliveriesV3(String t) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/taxi/v3/delivery/available'), headers: {'Authorization': 'Bearer $t'});
      final d = json.decode(res.body);
      if (res.statusCode == 403) return {'success': false, 'error': 'low_balance', 'message': d['message']};
      if (res.statusCode == 200) return {'success': true, 'orders': d['orders']};
    } catch (_) {}
    return {'success': true, 'orders': []};
  }

  static Future<Map<String, dynamic>> acceptDeliveryV3(String t, String id) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/taxi/v3/delivery/accept'), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $t'}, body: json.encode({'order_id': id}));
      return json.decode(res.body);
    } catch (e) { return {'success': false, 'message': '$e'}; }
  }

  static Future<Map<String, dynamic>?> getMyActiveDelivery(String t) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/taxi/v2/driver/my-active-delivery'), headers: {'Authorization': 'Bearer $t'});
      if (res.statusCode == 200) {
        final d = json.decode(res.body);
        if (d['success'] == true) return d['delivery_order'];
      }
    } catch (_) {}
    return null;
  }

  static Future<http.Response> updateDeliveryStatus(String t, String id, String s) => http.post(Uri.parse('$baseUrl/taxi/v2/delivery/update-status'), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $t'}, body: json.encode({'order_id': id, 'status': s}));

  static Future<void> updateDriverLocation(String t, double lat, double lng) async {
    try { await http.post(Uri.parse('$baseUrl/taxi/v2/driver/update-location'), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $t'}, body: json.encode({'lat': lat, 'lng': lng})); } catch (_) {}
  }

  static Future<int> getPoints(String t) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/taxi/v2/driver/hub'), headers: {'Authorization': 'Bearer $t'});
      if (res.statusCode == 200) return (json.decode(res.body)['data']['wallet_balance'] ?? 0).toInt();
    } catch (_) {}
    return 0;
  }

  static Future<List<dynamic>> getHistoryV3(String t) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/taxi/v3/driver/history'), headers: {'Authorization': 'Bearer $t'});
      if (res.statusCode == 200) {
        final d = json.decode(res.body);
        return d['history'] ?? [];
      }
    } catch (_) {}
    return [];
  }
}

// =============================================================================
// AUTH GATE
// =============================================================================
class AuthGate extends StatefulWidget { const AuthGate({super.key}); @override State<AuthGate> createState() => _AuthGateState(); }
class _AuthGateState extends State<AuthGate> {
  AuthResult? _auth;
  bool _load = true;

  @override
  void initState() { super.initState(); _chk(); }

  Future<void> _chk() async {
    try {
      final a = await ApiService.getStoredAuthData();
      if (fb_auth.FirebaseAuth.instance.currentUser == null) {
        try { await fb_auth.FirebaseAuth.instance.signInAnonymously().timeout(const Duration(seconds: 5)); } catch (_) {}
      }
      if (a != null) {
        try {
          final fcm = await NotificationService.getFcmToken();
          if (fcm != null) ApiService.updateFcmToken(a.token, fcm);
        } catch (_) {}
      }
      if (mounted) setState(() { _auth = a; _load = false; });
    } catch (e) {
      if (mounted) setState(() { _auth = null; _load = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_load) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_auth == null) return const DriverAuthGate();
    if (_auth!.driverStatus != 'approved') return Scaffold(body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.access_time, size: 60, color: Colors.orange), const SizedBox(height: 20), const Text("الحساب قيد المراجعة"), const SizedBox(height: 20), TextButton(onPressed: () async { await ApiService.logout(); setState(() => _auth = null); }, child: const Text("خروج"))])));
    return MainDeliveryLayout(authResult: _auth!, onLogout: () async { await ApiService.logout(); setState(() => _auth = null); });
  }
}

// =============================================================================
// AUTH SYSTEM
// =============================================================================
class DriverAuthGate extends StatefulWidget { const DriverAuthGate({super.key}); @override State<DriverAuthGate> createState() => _DriverAuthGateState(); }
class _DriverAuthGateState extends State<DriverAuthGate> {
  bool _isLogin = true;
  void _toggle() => setState(() => _isLogin = !_isLogin);
  void _onSuccess(AuthResult a) {
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => MainDeliveryLayout(authResult: a, onLogout: () async { await ApiService.logout(); setState(() {}); })), (route) => false);
  }
  @override
  Widget build(BuildContext context) => _isLogin ? DriverLogin(onToggle: _toggle, onSuccess: _onSuccess) : DriverRegisterV3(onToggle: _toggle);
}

class DriverLogin extends StatefulWidget { final VoidCallback onToggle; final Function(AuthResult) onSuccess; const DriverLogin({super.key, required this.onToggle, required this.onSuccess}); @override State<DriverLogin> createState() => _DriverLoginState(); }
class _DriverLoginState extends State<DriverLogin> {
  final p = TextEditingController(), pass = TextEditingController();
  bool _load = false;

  Future<void> _go() async {
    setState(() => _load = true);
    final res = await ApiService.login(p.text, pass.text);
    setState(() => _load = false);
    if (res['success'] == true) {
      final a = AuthResult.fromJson(res);
      if (res['is_driver'] == true) {
        await ApiService.storeAuthData(a);
        final fcm = await NotificationService.getFcmToken();
        if (fcm != null) ApiService.updateFcmToken(a.token, fcm);
        widget.onSuccess(a);
      } else { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ليس حساب سائق'))); }
    } else { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'فشل'))); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.local_shipping, size: 80, color: Colors.indigo),
        const SizedBox(height: 30),
        TextField(controller: p, decoration: const InputDecoration(labelText: "رقم الهاتف", prefixIcon: Icon(Icons.phone)), keyboardType: TextInputType.phone),
        const SizedBox(height: 15),
        TextField(controller: pass, decoration: const InputDecoration(labelText: "كلمة المرور", prefixIcon: Icon(Icons.lock)), obscureText: true),
        const SizedBox(height: 30),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _load ? null : _go, child: _load ? const CircularProgressIndicator(color: Colors.white) : const Text("دخول"))),
        TextButton(onPressed: widget.onToggle, child: const Text("ليس لديك حساب؟ سجل الآن"))
      ])),
    );
  }
}

class DriverRegisterV3 extends StatefulWidget { final VoidCallback onToggle; const DriverRegisterV3({super.key, required this.onToggle}); @override State<DriverRegisterV3> createState() => _DriverRegisterV3State(); }
class _DriverRegisterV3State extends State<DriverRegisterV3> {
  final _formKey = GlobalKey<FormState>();
  final name = TextEditingController(), phone = TextEditingController(), pass = TextEditingController(), model = TextEditingController(), color = TextEditingController();
  String vType = 'Car';
  XFile? imgReg, imgId, imgSelfie, imgRes;
  bool _load = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pick(String type) async {
    final f = await _picker.pickImage(source: type == 'selfie' ? ImageSource.camera : ImageSource.gallery, imageQuality: 60);
    if (f != null) setState(() { if(type=='reg') imgReg=f; if(type=='id') imgId=f; if(type=='selfie') imgSelfie=f; if(type=='res') imgRes=f; });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (imgReg == null || imgId == null || imgSelfie == null || imgRes == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يجب رفع جميع الصور الأربعة'))); return;
    }
    setState(() => _load = true);
    final fields = {'name': name.text, 'phone': phone.text, 'password': pass.text, 'vehicle_type': vType, 'car_model': model.text, 'car_color': color.text};
    final files = {'vehicle_registration_image': imgReg!, 'personal_id_image': imgId!, 'selfie_image': imgSelfie!, 'residence_card_image': imgRes!};

    final res = await ApiService.registerDriverV3(fields, files);
    setState(() => _load = false);
    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم التسجيل بنجاح! انتظر الموافقة.'), backgroundColor: Colors.green));
      widget.onToggle();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'فشل'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("تسجيل سائق جديد (V3)")),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Form(key: _formKey, child: Column(children: [
        TextFormField(controller: name, decoration: const InputDecoration(labelText: "الاسم الكامل"), validator: (v) => v!.isEmpty ? "مطلوب" : null), const SizedBox(height: 10),
        TextFormField(controller: phone, decoration: const InputDecoration(labelText: "الهاتف"), keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? "مطلوب" : null), const SizedBox(height: 10),
        TextFormField(controller: pass, decoration: const InputDecoration(labelText: "كلمة المرور"), obscureText: true, validator: (v) => v!.length < 6 ? "قصيرة جداً" : null), const SizedBox(height: 10),
        DropdownButtonFormField(value: vType, items: const [DropdownMenuItem(value: 'Car', child: Text('سيارة')), DropdownMenuItem(value: 'Tuktuk', child: Text('تكتك'))], onChanged: (v) => setState(() => vType = v!)), const SizedBox(height: 10),
        TextFormField(controller: model, decoration: const InputDecoration(labelText: "موديل المركبة"), validator: (v) => v!.isEmpty ? "مطلوب" : null), const SizedBox(height: 10),
        TextFormField(controller: color, decoration: const InputDecoration(labelText: "اللون"), validator: (v) => v!.isEmpty ? "مطلوب" : null), const SizedBox(height: 20),

        const Text("المستمسكات المطلوبة", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 10),
        GridView.count(shrinkWrap: true, crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.5, physics: const NeverScrollableScrollPhysics(), children: [
          _imgBtn("السنوية", imgReg, () => _pick('reg')),
          _imgBtn("الهوية", imgId, () => _pick('id')),
          _imgBtn("السيلفي", imgSelfie, () => _pick('selfie')),
          _imgBtn("بطاقة السكن", imgRes, () => _pick('res')),
        ]),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _load ? null : _submit, child: _load ? const CircularProgressIndicator(color: Colors.white) : const Text("إرسال الطلب"))),
        TextButton(onPressed: widget.onToggle, child: const Text("لديك حساب؟ سجل دخول"))
      ]))),
    );
  }
  Widget _imgBtn(String t, XFile? f, VoidCallback tap) => InkWell(onTap: tap, child: Container(decoration: BoxDecoration(color: f != null ? Colors.green[100] : Colors.grey[200], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(f != null ? Icons.check_circle : Icons.camera_alt, color: f != null ? Colors.green : Colors.grey), Text(t)])));
}

// =============================================================================
// MAIN LAYOUT
// =============================================================================
class MainDeliveryLayout extends StatefulWidget { final AuthResult authResult; final VoidCallback onLogout; const MainDeliveryLayout({super.key, required this.authResult, required this.onLogout}); @override State<MainDeliveryLayout> createState() => _MainDeliveryLayoutState(); }
class _MainDeliveryLayoutState extends State<MainDeliveryLayout> {
  int _idx = 0;
  Map<String, dynamic>? _active;

  @override
  void initState() { super.initState(); refreshTrigger.addListener(_refresh); _chk(); }
  @override
  void dispose() { refreshTrigger.removeListener(_refresh); super.dispose(); }

  void _refresh() {
    debugPrint("🔔 Notification Received! Refreshing...");
    _chk();
  }

  Future<void> _chk() async {
    final o = await ApiService.getMyActiveDelivery(widget.authResult.token);
    if (mounted) setState(() => _active = o);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _active != null
          ? DriverCurrentDeliveryScreen(initialDelivery: _active!, authResult: widget.authResult, onDeliveryFinished: () => setState(() => _active = null), onDataChanged: _chk)
          : DriverAvailableDeliveriesV3Screen(authResult: widget.authResult, onDeliveryAccepted: (o) => setState(() => _active = o)),
      HistoryTabV3(token: widget.authResult.token),
      PointsTab(token: widget.authResult.token, onLogout: widget.onLogout),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(_idx==0?(_active!=null?"طلب جاري":"الطلبات"):(_idx==1?"السجل":"حسابي")), actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _chk)]),
      body: pages[_idx],
      bottomNavigationBar: BottomNavigationBar(currentIndex: _idx, onTap: (i) => setState(() => _idx = i), items: const [BottomNavigationBarItem(icon: Icon(Icons.home), label: "الرئيسية"), BottomNavigationBarItem(icon: Icon(Icons.history), label: "السجل"), BottomNavigationBarItem(icon: Icon(Icons.person), label: "حسابي")]),
    );
  }
}

// =============================================================================
// AVAILABLE (V3) - MODIFIED: Shows Time & Date
// =============================================================================
class DriverAvailableDeliveriesV3Screen extends StatefulWidget { final AuthResult authResult; final Function(Map<String, dynamic>) onDeliveryAccepted; const DriverAvailableDeliveriesV3Screen({super.key, required this.authResult, required this.onDeliveryAccepted}); @override State<DriverAvailableDeliveriesV3Screen> createState() => _DriverAvailableDeliveriesV3ScreenState(); }
class _DriverAvailableDeliveriesV3ScreenState extends State<DriverAvailableDeliveriesV3Screen> {
  Future<dynamic>? _fut;
  Timer? _t;
  bool _load = false;

  @override
  void initState() { super.initState(); _get(); refreshTrigger.addListener(_get); _t = Timer.periodic(const Duration(seconds: 30), (_) => _get()); }
  @override
  void dispose() { refreshTrigger.removeListener(_get); _t?.cancel(); super.dispose(); }
  void _get() { if (mounted) setState(() => _fut = ApiService.getAvailableDeliveriesV3(widget.authResult.token)); }

  Future<void> _accept(String id) async {
    setState(() => _load = true);
    final res = await ApiService.acceptDeliveryV3(widget.authResult.token, id);
    setState(() => _load = false);
    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم القبول'), backgroundColor: Colors.green));
      widget.onDeliveryAccepted(res['delivery_order']);
    } else { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'فشل'), backgroundColor: Colors.red)); _get(); }
  }

  void _show(Map<String, dynamic> o) {
    showDialog(context: context, builder: (_) => AlertDialog(title: const Text("التفاصيل"), content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("المصدر: ${o['pickup_location_name']}"),
      const Divider(),
      Text("المحتوى: ${o['items_description']}"),
      if(o['notes']!=null)Text("ملاحظات: ${o['notes']}"),
      const Divider(),
      Text("تاريخ الطلب: ${o['date_formatted'] ?? 'غير محدد'}", style: const TextStyle(fontSize: 12, color: Colors.grey)), // 🔥 التاريخ
      const Divider(),
      Text("الأجرة: ${o['delivery_fee']} نقطة", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
    ]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("إغلاق")), ElevatedButton(onPressed: () { Navigator.pop(context); _accept(o['id'].toString()); }, child: const Text("قبول"))]));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(future: _fut, builder: (c, s) {
      if (s.connectionState == ConnectionState.waiting && !_load) return const Center(child: CircularProgressIndicator());
      if (s.hasData && s.data['success'] == false) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.warning, color: Colors.red, size: 50), Text(s.data['message']), ElevatedButton(onPressed: () => launchUrl(Uri.parse("https://wa.me/+9647854076931"), mode: LaunchMode.externalApplication), child: const Text("شحن"))]));
      final list = s.data?['orders'];
      if (list == null || list.isEmpty) return const Center(child: Text("لا توجد طلبات"));
      return ListView.builder(padding: const EdgeInsets.all(10), itemCount: list.length, itemBuilder: (c, i) {
        final o = list[i];
        return Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell( // لجعل الكارد قابلاً للنقر لفتح التفاصيل أيضاً
            onTap: () => _show(o),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(o['pickup_location_name'] ?? 'متجر', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      // 🔥 عرض الوقت المنقضي
                      Text(o['time_ago'] ?? 'جديد', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(o['destination_address'] ?? 'غير محدد', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  // 🔥 عرض التاريخ الكامل
                  Text("🕒 وقت الطلب: ${o['date_formatted'] ?? '--'}", style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(onPressed: () => _accept(o['id'].toString()), child: const Text("قبول"))
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      });
    });
  }
}

// =============================================================================
// ACTIVE DELIVERY
// =============================================================================
class DriverCurrentDeliveryScreen extends StatefulWidget { final Map<String, dynamic> initialDelivery; final AuthResult authResult; final VoidCallback onDeliveryFinished; final VoidCallback onDataChanged; const DriverCurrentDeliveryScreen({super.key, required this.initialDelivery, required this.authResult, required this.onDeliveryFinished, required this.onDataChanged}); @override State<DriverCurrentDeliveryScreen> createState() => _DriverCurrentDeliveryScreenState(); }
class _DriverCurrentDeliveryScreenState extends State<DriverCurrentDeliveryScreen> {
  late Map<String, dynamic> _o;
  bool _isLoading = false;
  String _dStr = "...";
  StreamSubscription? _sub;

  @override
  void initState() { super.initState(); _o = widget.initialDelivery; _track(); }
  @override
  void dispose() { _sub?.cancel(); super.dispose(); }

  // 🔥 1. دالة الخريطة الذكية (حل مشكلة الإحداثيات)
  Future<void> _map() async {
    final status = _o['order_status'];
    double lat = 0.0, lng = 0.0;
    String txt = "";

    if (status == 'accepted' || status == 'at_store') {
      lat = Helper.safeDouble(_o['pickup_lat']); lng = Helper.safeDouble(_o['pickup_lng']); txt = _o['pickup_location_name']??"";
    } else {
      lat = Helper.safeDouble(_o['destination_lat']); lng = Helper.safeDouble(_o['destination_lng']); txt = _o['destination_address']??"";
    }

    if (lat != 0.0 && lng != 0.0) {
      final waze = Uri.parse("waze://?ll=$lat,$lng&navigate=yes");
      final google = Uri.parse("google.navigation:q=$lat,$lng");
      if (await canLaunchUrl(waze)) { await launchUrl(waze, mode: LaunchMode.externalApplication); } else { await launchUrl(google, mode: LaunchMode.externalApplication); }
    } else if (txt.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("جاري البحث بالعنوان..."), duration: Duration(seconds: 1)));
      final q = Uri.encodeComponent(txt);
      if (await canLaunchUrl(Uri.parse("waze://?q=$q"))) { await launchUrl(Uri.parse("waze://?q=$q")); }
      else { await launchUrl(Uri.parse("http://googleusercontent.com/maps.google.com/?q=$q")); }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("لا توجد بيانات موقع!")));
    }
  }

  Future<void> _track() async {
    if (!await Helper.handleLocationPermission(context)) return;
    _sub = geolocator.Geolocator.getPositionStream(locationSettings: const geolocator.LocationSettings(accuracy: geolocator.LocationAccuracy.high, distanceFilter: 30)).listen((p) {
      if (!mounted) return;
      ApiService.updateDriverLocation(widget.authResult.token, p.latitude, p.longitude);
      // حساب المسافة البسيط للعرض
      double lat = 0, lng = 0;
      if (_o['order_status'] == 'picked_up') { lat = Helper.safeDouble(_o['destination_lat']); lng = Helper.safeDouble(_o['destination_lng']); }
      else { lat = Helper.safeDouble(_o['pickup_lat']); lng = Helper.safeDouble(_o['pickup_lng']); }
      if (lat != 0) {
        final d = geolocator.Geolocator.distanceBetween(p.latitude, p.longitude, lat, lng);
        setState(() => _dStr = d < 1000 ? "${d.round()} م" : "${(d/1000).toStringAsFixed(1)} كم");
      }
    });
  }

  Future<void> _upd(String s) async {
    setState(() => _isLoading = true);
    final res = await ApiService.updateDeliveryStatus(widget.authResult.token, _o['id'].toString(), s);
    setState(() => _isLoading = false);
    final d = json.decode(res.body);
    if (d['success'] == true) {
      if (s == 'delivered' || s == 'cancelled') widget.onDeliveryFinished(); else { setState(() => _o = d['delivery_order']); widget.onDataChanged(); }
    }
  }

  // 🔥 2. حل مشكلة رقم الهاتف (اختيار الرقم الصحيح)
  void _call() {
    final phone = _o['end_customer_phone'] ?? _o['customer_phone'];
    if (phone != null && phone.toString().isNotEmpty) {
      launchUrl(Uri.parse("tel:$phone"));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("رقم الهاتف غير متوفر")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _o['order_status'];
    Color stColor = Colors.blue;
    String stText = "جارِ التوجه للمطعم";
    if (s == 'at_store') { stColor = Colors.orange; stText = "في المطعم"; }
    else if (s == 'picked_up') { stColor = Colors.purple; stText = "جارِ التوجه للزبون"; }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 1. بطاقة الحالة العصرية
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: [stColor.withOpacity(0.8), stColor]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: stColor.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5))]
            ),
            child: Row(
              children: [
                Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle), child: const Icon(Icons.motorcycle, color: Colors.white, size: 30)),
                const SizedBox(width: 15),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(stText, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text("المسافة: $_dStr", style: const TextStyle(color: Colors.white70, fontSize: 14)),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. بطاقة الزبون (مع زر الاتصال الكبير)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(backgroundColor: Colors.indigo, child: Icon(Icons.person, color: Colors.white)),
                    title: Text(_o['customer_name'] ?? 'زبون', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(_o['destination_address'] ?? 'العنوان غير محدد'),
                  ),
                  const Divider(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _call,
                      icon: const Icon(Icons.call),
                      label: const Text("اتصل بالزبون"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 3. بطاقة التفاصيل المالية (كما طلبت)
          Card(
            color: Colors.grey[50],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _priceRow("سعر التوصيل (لك):", "${_o['delivery_fee']} د.ع", Colors.green),
                  const Divider(),
                  Text("📦 التفاصيل: ${_o['items_description']}", style: const TextStyle(fontSize: 14), textAlign: TextAlign.center),
                  const Divider(),
                  // 🔥 إضافة وقت الطلب في التفاصيل
                  Text("🕒 وقت الطلب: ${_o['date_formatted'] ?? 'غير محدد'}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 4. أزرار التحكم
          Row(
            children: [
              Expanded(child: OutlinedButton.icon(onPressed: _map, icon: const Icon(Icons.map), label: const Text("الخريطة"), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)))),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton(onPressed: _isLoading ? null : () => _upd('cancelled'), style: ElevatedButton.styleFrom(backgroundColor: Colors.red[100], foregroundColor: Colors.red, elevation: 0), child: const Text("إلغاء"))),
            ],
          ),
          const SizedBox(height: 15),

          // زر الحالة المتغير
          if (s == 'accepted') _mainBtn("وصلت للمطعم", Colors.blue, 'at_store'),
          if (s == 'at_store') _mainBtn("استلمت الطلب (ابداء)", Colors.orange, 'picked_up'),
          if (s == 'picked_up') _mainBtn("تم التسليم (إنهاء)", Colors.green, 'delivered'),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, Color color) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
      Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
    ]);
  }

  Widget _mainBtn(String txt, Color col, String next) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: col, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
        onPressed: _isLoading ? null : () => _upd(next),
        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(txt, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// =============================================================================
// HISTORY V3
// =============================================================================
class HistoryTabV3 extends StatelessWidget {
  final String token;
  const HistoryTabV3({super.key, required this.token});

  String _mask(String? p) => (p == null || p.length < 8) ? "****" : "${p.substring(0, 4)}****${p.substring(p.length - 3)}";

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(length: 2, child: Column(children: [
      const TabBar(labelColor: Colors.indigo, tabs: [Tab(text: "نشطة"), Tab(text: "أرشيف")]),
      Expanded(child: FutureBuilder<List<dynamic>>(
          future: ApiService.getHistoryV3(token),
          builder: (c, s) {
            if (s.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            final all = s.data ?? [];
            final active = all.where((o) => ['accepted', 'at_store', 'picked_up'].contains(o['status'])).toList();
            final archive = all.where((o) => ['delivered', 'cancelled'].contains(o['status'])).toList();
            return TabBarView(children: [_list(active, false), _list(archive, true)]);
          }
      ))
    ]));
  }

  Widget _list(List<dynamic> list, bool isArchive) {
    if (list.isEmpty) return const Center(child: Text("لا توجد بيانات"));
    return ListView.builder(itemCount: list.length, itemBuilder: (c, i) {
      final o = list[i];
      final status = o['status'];
      final isDone = status == 'delivered';
      return Card(margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), child: ListTile(
        leading: Icon(isArchive ? (isDone ? Icons.check_circle : Icons.cancel) : Icons.motorcycle, color: isDone ? Colors.green : (status=='cancelled'?Colors.red:Colors.blue)),
        title: Text("طلب #${o['id']} - $status"),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("تاريخ: ${o['date']}"),
          Text("المصدر: ${o['pickup_location']}"),
          if(isArchive) Text("هاتف: ${_mask(o['customer_phone'])}"),
        ]),
        trailing: Text("${o['delivery_fee']} نقطة", style: const TextStyle(fontWeight: FontWeight.bold)),
      ));
    });
  }
}

// =============================================================================
// POINTS TAB
// =============================================================================
class PointsTab extends StatelessWidget { final String token; final VoidCallback onLogout; const PointsTab({super.key, required this.token, required this.onLogout});
@override
Widget build(BuildContext context) {
  return FutureBuilder<int>(
      future: ApiService.getPoints(token),
      builder: (c, s) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.stars, size: 80, color: (s.data ?? 0) <= 3 ? Colors.red : Colors.amber),
        Text("${s.data ?? 0}", style: const TextStyle(fontSize: 40)),
        const Text("نقطة"),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: () => launchUrl(Uri.parse("https://wa.me/+9647854076931"), mode: LaunchMode.externalApplication), child: const Text("شحن")),
        const SizedBox(height: 20),
        OutlinedButton(onPressed: onLogout, child: const Text("خروج"))
      ]))
  );
}
}
